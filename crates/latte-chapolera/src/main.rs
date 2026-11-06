//! latte-chapolera: scan folders and manage Chapolera's display settings.
//!
//!   latte-chapolera scan FOLDER LIMIT OFFSET
//!   latte-chapolera settings
//!   latte-chapolera settings-set automatic|manual LIMIT
//!   latte-chapolera memory
//!   latte-chapolera classify-image IMAGE LABEL...
//!   latte-chapolera classify-folder FOLDER LABEL...
//!   latte-chapolera classify-folder-events FOLDER LABEL...

use candle_core::{DType, Device, IndexOp, Tensor};
use candle_nn::VarBuilder;
use candle_transformers::models::siglip;
use std::collections::HashSet;
use std::fs::{self, OpenOptions};
use std::io::Write;
use std::path::{Path, PathBuf};
use tokenizers::Tokenizer;

mod asset_store;

const DEFAULT_PREVIEW_LIMIT: usize = 24;
const MIN_PREVIEW_LIMIT: usize = 8;
const MAX_PREVIEW_LIMIT: usize = 96;
const PREVIEW_STEP: usize = 4;
const GIB: u64 = 1024 * 1024 * 1024;
const DEFAULT_SIGLIP_MODEL_DIR: &str = "/data/ai/models/chapolera/siglip2-base-patch16-224";
const SIGLIP_IMAGE_SIZE: u32 = 224;
const SIGLIP_TEXT_LENGTH: usize = 64;
const SIGLIP_IMAGE_BATCH_SIZE: usize = 8;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
struct Settings {
    automatic: bool,
    preview_limit: usize,
}

impl Default for Settings {
    fn default() -> Self {
        Self { automatic: true, preview_limit: DEFAULT_PREVIEW_LIMIT }
    }
}

#[derive(Debug)]
struct FileEntry {
    name: String,
    path: String,
    kind: &'static str,
}

#[derive(Debug, Default)]
struct Counts {
    total: usize,
    photos: usize,
    videos: usize,
    audio: usize,
    other: usize,
    subfolders: usize,
}

fn json_string(value: &str) -> String {
    let mut out = String::with_capacity(value.len() + 2);
    out.push('"');
    for ch in value.chars() {
        match ch {
            '"' => out.push_str("\\\""),
            '\\' => out.push_str("\\\\"),
            '\n' => out.push_str("\\n"),
            '\r' => out.push_str("\\r"),
            '\t' => out.push_str("\\t"),
            ch if (ch as u32) < 0x20 => out.push_str(&format!("\\u{:04x}", ch as u32)),
            ch => out.push(ch),
        }
    }
    out.push('"');
    out
}

fn kind(name: &str) -> &'static str {
    let extension = name.rsplit_once('.').map(|(_, ext)| ext.to_ascii_lowercase()).unwrap_or_default();
    match extension.as_str() {
        "jpg" | "jpeg" | "png" | "webp" | "gif" | "heic" | "bmp" | "tif" | "tiff" | "avif" | "raw" | "dng" => "photo",
        "mp4" | "mkv" | "webm" | "mov" | "avi" | "m4v" | "mpeg" | "mpg" => "video",
        "mp3" | "flac" | "ogg" | "opus" | "wav" | "m4a" | "aac" | "aiff" | "wma" => "audio",
        _ => "other",
    }
}

fn hidden_names(folder: &Path) -> Result<HashSet<String>, String> {
    let path = folder.join(".hidden");
    match fs::read_to_string(&path) {
        Ok(contents) => Ok(contents.lines().map(str::to_string).collect()),
        Err(error) if error.kind() == std::io::ErrorKind::NotFound => Ok(HashSet::new()),
        Err(error) => Err(format!("{}: {error}", path.display())),
    }
}

fn valid_preview_limit(limit: usize) -> bool {
    (MIN_PREVIEW_LIMIT..=MAX_PREVIEW_LIMIT).contains(&limit)
        && (limit - MIN_PREVIEW_LIMIT) % PREVIEW_STEP == 0
}

fn automatic_preview_limit(available_bytes: u64) -> usize {
    if available_bytes < GIB {
        8
    } else if available_bytes < 2 * GIB {
        12
    } else if available_bytes < 4 * GIB {
        24
    } else {
        48
    }
}

fn scan(folder: &Path, limit: usize, offset: usize) -> Result<(Counts, Vec<FileEntry>), String> {
    asset_store::scan(folder, limit, offset)
}

fn output(folder: &Path, counts: &Counts, files: &[FileEntry], limit: usize, offset: usize) -> String {
    let items = files.iter().map(|file| {
        format!(
            "{{\"name\":{},\"path\":{},\"kind\":{}}}",
            json_string(&file.name),
            json_string(&file.path),
            json_string(file.kind),
        )
    }).collect::<Vec<_>>().join(",");
    let end = offset.saturating_add(files.len());
    format!(
        "{{\"folder\":{},\"counts\":{{\"total\":{},\"photos\":{},\"videos\":{},\"audio\":{},\"other\":{},\"subfolders\":{}}},\"start\":{},\"preview_limit\":{},\"has_more\":{},\"files\":[{}]}}",
        json_string(&folder.to_string_lossy()), counts.total, counts.photos, counts.videos, counts.audio,
        counts.other, counts.subfolders, offset, limit, end < counts.total, items
    )
}

fn settings_path() -> Result<PathBuf, String> {
    let config_home = match std::env::var_os("XDG_CONFIG_HOME") {
        Some(path) if !path.is_empty() => PathBuf::from(path),
        _ => PathBuf::from(std::env::var_os("HOME").ok_or("HOME is not set")?).join(".config"),
    };
    Ok(config_home.join("latteos").join("chapolera.json"))
}

fn parse_settings(raw: &str) -> Result<Settings, String> {
    let value: serde_json::Value = serde_json::from_str(raw).map_err(|error| format!("invalid settings JSON: {error}"))?;
    let automatic = value.get("automatic").and_then(serde_json::Value::as_bool)
        .ok_or("settings field 'automatic' must be a boolean")?;
    let limit = value.get("preview_limit").and_then(serde_json::Value::as_u64)
        .and_then(|value| usize::try_from(value).ok())
        .ok_or("settings field 'preview_limit' must be a positive integer")?;
    if !valid_preview_limit(limit) {
        return Err(format!("settings preview_limit must be {MIN_PREVIEW_LIMIT}–{MAX_PREVIEW_LIMIT} in steps of {PREVIEW_STEP}"));
    }
    Ok(Settings { automatic, preview_limit: limit })
}

fn settings_json(settings: Settings) -> String {
    serde_json::json!({
        "automatic": settings.automatic,
        "preview_limit": settings.preview_limit,
    }).to_string()
}

fn write_settings(path: &Path, settings: Settings) -> Result<(), String> {
    let parent = path.parent().ok_or("settings path has no parent directory")?;
    fs::create_dir_all(parent).map_err(|error| format!("{}: {error}", parent.display()))?;
    let mut temp = None;
    for suffix in 0..10 {
        let candidate = parent.join(format!(".chapolera-{}-{suffix}.tmp", std::process::id()));
        match OpenOptions::new().write(true).create_new(true).open(&candidate) {
            Ok(file) => {
                temp = Some((candidate, file));
                break;
            }
            Err(error) if error.kind() == std::io::ErrorKind::AlreadyExists => {}
            Err(error) => return Err(format!("{}: {error}", candidate.display())),
        }
    }
    let (temp_path, mut file) = temp.ok_or("could not create a temporary settings file")?;
    let result = (|| {
        file.write_all(settings_json(settings).as_bytes()).map_err(|error| format!("{}: {error}", temp_path.display()))?;
        file.sync_all().map_err(|error| format!("{}: {error}", temp_path.display()))?;
        fs::rename(&temp_path, path).map_err(|error| format!("{}: {error}", path.display()))
    })();
    if result.is_err() {
        let _ = fs::remove_file(&temp_path);
    }
    result
}

fn read_settings(path: &Path) -> Result<Settings, String> {
    match fs::read_to_string(path) {
        Ok(raw) => parse_settings(&raw).map_err(|error| format!("{}: {error}", path.display())),
        Err(error) if error.kind() == std::io::ErrorKind::NotFound => {
            let settings = Settings::default();
            write_settings(path, settings)?;
            Ok(settings)
        }
        Err(error) => Err(format!("{}: {error}", path.display())),
    }
}

fn available_memory_bytes(meminfo: &str) -> Result<u64, String> {
    let line = meminfo.lines().find(|line| line.starts_with("MemAvailable:"))
        .ok_or("/proc/meminfo has no MemAvailable entry")?;
    let mut fields = line.split_whitespace();
    let _ = fields.next();
    let value = fields.next().ok_or("MemAvailable has no value")?.parse::<u64>()
        .map_err(|error| format!("invalid MemAvailable value: {error}"))?;
    match fields.next() {
        Some("kB") => value.checked_mul(1024).ok_or_else(|| "MemAvailable value is too large".to_string()),
        _ => Err("MemAvailable is not reported in kB".to_string()),
    }
}

fn siglip_model_dir() -> PathBuf {
    std::env::var_os("LATTE_CHAPOLERA_MODEL_DIR")
        .map(PathBuf::from)
        .unwrap_or_else(|| PathBuf::from(DEFAULT_SIGLIP_MODEL_DIR))
}

fn image_tensor(path: &Path) -> Result<Tensor, String> {
    let image = image::open(path)
        .map_err(|error| format!("{}: {error}", path.display()))?
        .to_rgb8();
    let image = image::imageops::resize(
        &image,
        SIGLIP_IMAGE_SIZE,
        SIGLIP_IMAGE_SIZE,
        image::imageops::FilterType::CatmullRom,
    );
    let plane = (SIGLIP_IMAGE_SIZE * SIGLIP_IMAGE_SIZE) as usize;
    let mut pixels = vec![0f32; plane * 3];
    for (x, y, pixel) in image.enumerate_pixels() {
        let index = y as usize * SIGLIP_IMAGE_SIZE as usize + x as usize;
        for channel in 0..3 {
            pixels[channel * plane + index] = pixel[channel] as f32 / 127.5 - 1.0;
        }
    }
    Tensor::from_vec(
        pixels,
        (1, 3, SIGLIP_IMAGE_SIZE as usize, SIGLIP_IMAGE_SIZE as usize),
        &Device::Cpu,
    )
    .map_err(|error| format!("could not prepare {}: {error}", path.display()))
}

fn photo_paths(folder: &Path) -> Result<Vec<PathBuf>, String> {
    let root = fs::canonicalize(folder).map_err(|error| format!("{}: {error}", folder.display()))?;
    if !root.is_dir() {
        return Err(format!("{}: not a folder", root.display()));
    }

    let mut photos = Vec::new();
    let mut pending = vec![root];
    while let Some(directory) = pending.pop() {
        let hidden = hidden_names(&directory)?;
        let mut entries = fs::read_dir(&directory)
            .map_err(|error| format!("{}: {error}", directory.display()))?
            .collect::<Result<Vec<_>, _>>()
            .map_err(|error| format!("{}: {error}", directory.display()))?;
        entries.sort_by_key(|entry| entry.file_name());
        let mut subfolders = Vec::new();

        for entry in entries {
            let file_name = entry.file_name();
            let name = file_name.to_string_lossy().into_owned();
            if name.starts_with('.') || hidden.contains(&name) {
                continue;
            }
            let path = entry.path();
            let file_type = entry.file_type().map_err(|error| format!("{}: {error}", path.display()))?;
            if file_type.is_dir() {
                subfolders.push(path);
            } else if file_type.is_file() && kind(&name) == "photo" {
                photos.push(path);
            }
        }
        pending.extend(subfolders.into_iter().rev());
    }
    Ok(photos)
}

struct SiglipClassifier {
    model: siglip::Model,
    tokenizer: Tokenizer,
    device: Device,
}

impl SiglipClassifier {
    fn load() -> Result<Self, String> {
        let model_dir = siglip_model_dir();
        let config_path = model_dir.join("config.json");
        let tokenizer_path = model_dir.join("tokenizer.json");
        let weights_path = model_dir.join("model.safetensors");
        let config_raw =
            fs::read(&config_path).map_err(|error| format!("{}: {error}", config_path.display()))?;
        let config: siglip::Config = serde_json::from_slice(&config_raw)
            .map_err(|error| format!("{}: {error}", config_path.display()))?;
        let mut tokenizer = Tokenizer::from_file(&tokenizer_path)
            .map_err(|error| format!("{}: {error}", tokenizer_path.display()))?;
        tokenizer
            .with_truncation(Some(tokenizers::TruncationParams {
                max_length: SIGLIP_TEXT_LENGTH,
                ..Default::default()
            }))
            .map_err(|error| format!("could not configure SigLIP tokenizer: {error}"))?;

        let device = Device::Cpu;
        // Keep the memory-mapped checkpoint immutable for the model's lifetime.
        let variables = unsafe {
            VarBuilder::from_mmaped_safetensors(&[weights_path.as_path()], DType::F32, &device)
        }
        .map_err(|error| format!("{}: {error}", weights_path.display()))?;
        let model = siglip::Model::new(&config, variables)
            .map_err(|error| format!("could not load SigLIP 2 model: {error}"))?;
        Ok(Self { model, tokenizer, device })
    }

    fn classify_batch(&self, images: &[PathBuf], labels: &[String]) -> Result<Vec<serde_json::Value>, String> {
        let text_inputs = labels
            .iter()
            .map(|label| {
                self.tokenizer
                    .encode(format!("a photo of {label}"), true)
                    .map_err(|error| format!("could not tokenize label {label:?}: {error}"))
            })
            .collect::<Result<Vec<_>, _>>()?;
        if text_inputs
            .iter()
            .any(|input| input.get_ids().len() != SIGLIP_TEXT_LENGTH)
        {
            return Err(format!("SigLIP tokenizer must pad each prompt to {SIGLIP_TEXT_LENGTH} tokens"));
        }
        let token_ids = text_inputs
            .iter()
            .flat_map(|input| input.get_ids().iter().copied())
            .collect::<Vec<_>>();
        let input_ids = Tensor::from_vec(token_ids, (labels.len(), SIGLIP_TEXT_LENGTH), &self.device)
            .map_err(|error| format!("could not prepare text prompts: {error}"))?;
        let image_tensors = images
            .iter()
            .map(|path| image_tensor(path))
            .collect::<Result<Vec<_>, _>>()?;
        let image_refs = image_tensors.iter().collect::<Vec<_>>();
        let pixel_values = Tensor::cat(&image_refs, 0)
            .map_err(|error| format!("could not combine image batch: {error}"))?;
        let (_, logits_per_image) = self.model.forward(&pixel_values, &input_ids)
            .map_err(|error| format!("SigLIP 2 inference failed: {error}"))?;

        images
            .iter()
            .enumerate()
            .map(|(image_index, image_path)| {
                let mut scores: Vec<(&String, f32)> = labels
                    .iter()
                    .enumerate()
                    .map(|(label_index, label)| {
                        let score = logits_per_image
                            .i((image_index, label_index))
                            .and_then(|tensor| tensor.to_scalar::<f32>())
                            .map_err(|error| format!("could not read score for {label:?}: {error}"))?;
                        Ok((label, score))
                    })
                    .collect::<Result<Vec<_>, String>>()?;
                scores.sort_by(|left, right| right.1.total_cmp(&left.1));
                Ok(serde_json::json!({
                    "image": image_path.to_string_lossy(),
                    "scores": scores.into_iter().map(|(label, score)| serde_json::json!({
                        "label": label,
                        "score": score,
                    })).collect::<Vec<_>>(),
                }))
            })
            .collect()
    }
}

fn classify_image(image_path: &Path, labels: &[String]) -> Result<String, String> {
    if labels.is_empty() {
        return Err("classify-image requires at least one label".to_string());
    }
    let classifier = SiglipClassifier::load()?;
    let image = image_path.to_path_buf();
    let mut results = classifier.classify_batch(&[image], labels)?;
    let mut result = results.remove(0);
    result["model"] = serde_json::json!("google/siglip2-base-patch16-224");
    serde_json::to_string(&result)
        .map_err(|error| format!("could not serialize SigLIP result: {error}"))
}

fn classify_folder(folder: &Path, labels: &[String]) -> Result<String, String> {
    if labels.is_empty() {
        return Err("classify-folder requires at least one label".to_string());
    }
    let root = fs::canonicalize(folder).map_err(|error| format!("{}: {error}", folder.display()))?;
    let photos = photo_paths(&root)?;
    if photos.is_empty() {
        return serde_json::to_string(&serde_json::json!({
            "model": "google/siglip2-base-patch16-224",
            "folder": root.to_string_lossy(),
            "classified": 0,
            "images": [],
        }))
        .map_err(|error| format!("could not serialize SigLIP results: {error}"));
    }
    let classifier = SiglipClassifier::load()?;
    let mut results = Vec::with_capacity(photos.len());
    for batch in photos.chunks(SIGLIP_IMAGE_BATCH_SIZE) {
        results.extend(classifier.classify_batch(batch, labels)?);
    }
    serde_json::to_string(&serde_json::json!({
        "model": "google/siglip2-base-patch16-224",
        "folder": root.to_string_lossy(),
        "classified": results.len(),
        "images": results,
    }))
    .map_err(|error| format!("could not serialize SigLIP results: {error}"))
}

fn write_event(event: &serde_json::Value) -> Result<(), String> {
    let stdout = std::io::stdout();
    let mut output = stdout.lock();
    serde_json::to_writer(&mut output, event)
        .map_err(|error| format!("could not encode classifier event: {error}"))?;
    output
        .write_all(b"\n")
        .and_then(|_| output.flush())
        .map_err(|error| format!("could not write classifier event: {error}"))
}

fn classify_folder_events(folder: &Path, labels: &[String]) -> Result<String, String> {
    if labels.is_empty() {
        return Err("classify-folder-events requires at least one label".to_string());
    }
    let root = fs::canonicalize(folder).map_err(|error| format!("{}: {error}", folder.display()))?;
    let photos = photo_paths(&root)?;
    write_event(&serde_json::json!({
        "event": "start",
        "total": photos.len(),
    }))?;
    if photos.is_empty() {
        write_event(&serde_json::json!({
            "event": "complete",
            "classified": 0,
        }))?;
        return Ok(String::new());
    }

    let classifier = SiglipClassifier::load()?;
    for batch in photos.chunks(SIGLIP_IMAGE_BATCH_SIZE) {
        for result in classifier.classify_batch(batch, labels)? {
            let mut event = result;
            event["event"] = serde_json::json!("image");
            write_event(&event)?;
        }
    }
    write_event(&serde_json::json!({
        "event": "complete",
        "classified": photos.len(),
    }))?;
    Ok(String::new())
}

fn execute(args: &[String]) -> Result<String, String> {
    match args {
        [command, image, labels @ ..] if command == "classify-image" => {
            classify_image(Path::new(image), labels)
        }
        [command, folder, labels @ ..] if command == "classify-folder-events" => {
            classify_folder_events(Path::new(folder), labels)
        }
        [command, folder, labels @ ..] if command == "classify-folder" => {
            classify_folder(Path::new(folder), labels)
        }
        [command, folder, limit, offset] if command == "scan" => {
            let limit = limit.parse::<usize>().map_err(|error| format!("invalid preview limit: {error}"))?;
            let offset = offset.parse::<usize>().map_err(|error| format!("invalid preview offset: {error}"))?;
            let path = Path::new(folder);
            let (counts, files) = scan(path, limit, offset)?;
            Ok(output(path, &counts, &files, limit, offset))
        }
        [command] if command == "settings" => {
            let settings = read_settings(&settings_path()?)?;
            Ok(settings_json(settings))
        }
        [command, mode, limit] if command == "settings-set" => {
            let automatic = match mode.as_str() {
                "automatic" => true,
                "manual" => false,
                _ => return Err("mode must be 'automatic' or 'manual'".to_string()),
            };
            let limit = limit.parse::<usize>().map_err(|error| format!("invalid preview limit: {error}"))?;
            if !valid_preview_limit(limit) {
                return Err(format!("preview limit must be {MIN_PREVIEW_LIMIT}–{MAX_PREVIEW_LIMIT} in steps of {PREVIEW_STEP}"));
            }
            let settings = Settings { automatic, preview_limit: limit };
            write_settings(&settings_path()?, settings)?;
            Ok(settings_json(settings))
        }
        [command] if command == "memory" => {
            let meminfo = fs::read_to_string("/proc/meminfo").map_err(|error| format!("/proc/meminfo: {error}"))?;
            let available_bytes = available_memory_bytes(&meminfo)?;
            Ok(serde_json::json!({
                "available_bytes": available_bytes,
                "preview_limit": automatic_preview_limit(available_bytes),
            }).to_string())
        }
        _ => Err("usage: latte-chapolera scan FOLDER LIMIT OFFSET | settings | settings-set automatic|manual LIMIT | memory | classify-image IMAGE LABEL... | classify-folder FOLDER LABEL... | classify-folder-events FOLDER LABEL...".to_string()),
    }
}

fn main() {
    let args: Vec<String> = std::env::args().skip(1).collect();
    match execute(&args) {
        Ok(output) if !output.is_empty() => println!("{output}"),
        Ok(_) => {}
        Err(error) => {
            eprintln!("latte-chapolera: {error}");
            std::process::exit(2);
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::fs::{create_dir, create_dir_all, remove_dir_all, write};

    fn test_folder(label: &str) -> std::path::PathBuf {
        let path = std::env::temp_dir().join(format!("latte-chapolera-{label}-{}", std::process::id()));
        let _ = remove_dir_all(&path);
        create_dir_all(&path).unwrap();
        path
    }

    fn test_database(folder: &Path) -> PathBuf {
        let name = folder.file_name().unwrap().to_string_lossy();
        std::env::temp_dir().join(format!("{name}.sqlite3"))
    }

    fn scan_for_test(folder: &Path, limit: usize, offset: usize) -> Result<(Counts, Vec<FileEntry>), String> {
        asset_store::scan_with_database(folder, limit, offset, &test_database(folder))
    }

    fn cleanup_test_database(folder: &Path) {
        let database = test_database(folder);
        let _ = remove_dir_all(folder);
        let _ = std::fs::remove_file(&database);
        let _ = std::fs::remove_file(database.with_extension("sqlite3-wal"));
        let _ = std::fs::remove_file(database.with_extension("sqlite3-shm"));
    }

    #[test]
    fn scans_visible_files_and_counts_media() {
        let folder = test_folder("scan");
        write(folder.join("portrait.JPG"), b"image").unwrap();
        write(folder.join("clip.mp4"), b"video").unwrap();
        write(folder.join("voice.ogg"), b"audio").unwrap();
        write(folder.join("notes.txt"), b"text").unwrap();
        write(folder.join(".hidden.jpg"), b"hidden").unwrap();
        let nested = folder.join("nested");
        create_dir(&nested).unwrap();
        write(nested.join("nested-photo.png"), b"image").unwrap();
        let deeper = nested.join("deeper");
        create_dir(&deeper).unwrap();
        write(deeper.join("nested-audio.mp3"), b"audio").unwrap();
        write(folder.join(".hidden"), b"hidden.txt\n").unwrap();
        write(folder.join("hidden.txt"), b"hidden").unwrap();

        let (counts, files) = scan_for_test(&folder, 8, 0).unwrap();
        assert_eq!((counts.total, counts.photos, counts.videos, counts.audio, counts.other, counts.subfolders), (6, 2, 1, 2, 1, 2));
        assert_eq!(files.len(), 6);
        assert!(files.iter().any(|file| file.name == "portrait.JPG" && file.kind == "photo"));
        assert!(files.iter().any(|file| file.path.ends_with("nested-photo.png")));
        assert!(!files.iter().any(|file| file.name.starts_with('.')));
        assert!(!files.iter().any(|file| file.name == "hidden.txt"));
        cleanup_test_database(&folder);
    }

    #[test]
    fn photo_paths_include_visible_nested_images_only() {
        let folder = test_folder("photos");
        write(folder.join("portrait.JPG"), b"image").unwrap();
        write(folder.join("notes.txt"), b"text").unwrap();
        write(folder.join(".hidden.jpg"), b"hidden").unwrap();
        write(folder.join(".hidden"), b"excluded.png\n").unwrap();
        write(folder.join("excluded.png"), b"hidden").unwrap();
        let nested = folder.join("nested");
        create_dir(&nested).unwrap();
        write(nested.join("nested-photo.webp"), b"image").unwrap();

        let paths = photo_paths(&folder).unwrap();
        assert_eq!(paths.len(), 2);
        assert!(paths[0].ends_with("portrait.JPG"));
        assert!(paths[1].ends_with("nested-photo.webp"));
        remove_dir_all(folder).unwrap();
    }

    #[test]
    fn classify_folder_without_photos_does_not_load_model() {
        let folder = test_folder("empty-photos");
        let labels = vec!["landscape".to_string()];
        let result: serde_json::Value =
            serde_json::from_str(&classify_folder(&folder, &labels).unwrap()).unwrap();
        assert_eq!(result["classified"], 0);
        assert_eq!(result["images"].as_array().unwrap().len(), 0);
        remove_dir_all(folder).unwrap();
    }

    #[test]
    fn preview_pages_cover_every_file_without_a_total_cap() {
        let folder = test_folder("limit");
        for index in 0..21 {
            write(folder.join(format!("image-{index}.png")), b"image").unwrap();
        }
        let (counts, first) = scan_for_test(&folder, 8, 0).unwrap();
        let (_, second) = scan_for_test(&folder, 8, 8).unwrap();
        let (_, third) = scan_for_test(&folder, 8, 16).unwrap();
        assert_eq!(counts.total, 21);
        assert_eq!(first.len(), 8);
        assert_eq!(second.len(), 8);
        assert_eq!(third.len(), 5);
        assert!(first[0].name < second[0].name);
        assert!(second[0].name < third[0].name);
        cleanup_test_database(&folder);
    }

    #[test]
    fn json_strings_escape_special_characters() {
        assert_eq!(json_string("a\"b\\c\nd"), "\"a\\\"b\\\\c\\nd\"");
    }

    #[test]
    fn scan_rejects_a_file_instead_of_a_folder() {
        let folder = test_folder("not-a-folder");
        let file = folder.join("plain.txt");
        write(&file, b"text").unwrap();
        assert!(scan_for_test(&file, 8, 0).unwrap_err().contains("not a folder"));
        remove_dir_all(folder).unwrap();
    }

    #[test]
    fn validates_preview_limit_steps() {
        assert!(valid_preview_limit(8));
        assert!(valid_preview_limit(96));
        assert!(!valid_preview_limit(7));
        assert!(!valid_preview_limit(10));
        assert!(!valid_preview_limit(100));
    }

    #[test]
    fn automatic_limit_uses_available_memory_thresholds() {
        assert_eq!(automatic_preview_limit(GIB - 1), 8);
        assert_eq!(automatic_preview_limit(GIB), 12);
        assert_eq!(automatic_preview_limit(2 * GIB), 24);
        assert_eq!(automatic_preview_limit(4 * GIB), 48);
    }

    #[test]
    fn parses_and_persists_settings() {
        let folder = test_folder("settings");
        let path = folder.join("chapolera.json");
        assert_eq!(read_settings(&path).unwrap(), Settings::default());
        let settings = Settings { automatic: false, preview_limit: 64 };
        write_settings(&path, settings).unwrap();
        assert_eq!(read_settings(&path).unwrap(), settings);
        assert!(parse_settings(r#"{"automatic":false,"preview_limit":10}"#).is_err());
        remove_dir_all(folder).unwrap();
    }

    #[test]
    fn reads_available_memory_in_bytes() {
        assert_eq!(available_memory_bytes("MemTotal: 16000 kB\nMemAvailable:  12000 kB\n").unwrap(), 12_288_000);
        assert!(available_memory_bytes("MemTotal: 16000 kB\n").is_err());
    }
}
