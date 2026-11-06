use serde_json::{Map, Value};
use std::collections::HashMap;
use std::path::Path;
use std::io::Read;
use std::process::{Command, Output, Stdio};
use std::time::{Duration, Instant};
use std::{io, thread};

const COMMAND_TIMEOUT: Duration = Duration::from_secs(30);
const IMAGE_EXTRACTOR: &str = "image-header";
const EXIFTOOL_EXTRACTOR: &str = "exiftool";
const FFPROBE_EXTRACTOR: &str = "ffprobe";
const PDFINFO_EXTRACTOR: &str = "pdfinfo";
const IMAGE_TAGS: &[(&str, &str)] = &[
    ("ImageWidth", "image.width"),
    ("ImageHeight", "image.height"),
    ("Orientation", "image.orientation"),
    ("DateTimeOriginal", "image.datetime_original"),
    ("CreateDate", "image.create_date"),
    ("Make", "image.camera.make"),
    ("Model", "image.camera.model"),
    ("LensModel", "image.lens.model"),
    ("FNumber", "image.aperture_f_number"),
    ("ExposureTime", "image.exposure_seconds"),
    ("ISO", "image.iso"),
    ("FocalLength", "image.focal_length_mm"),
];
const DOCUMENT_TAGS: &[(&str, &str)] = &[
    ("Title", "document.title"),
    ("Author", "document.author"),
    ("Subject", "document.subject"),
    ("Keywords", "document.keywords"),
    ("Creator", "document.creator"),
    ("Producer", "document.producer"),
    ("PageCount", "document.page_count"),
    ("CreateDate", "document.create_date"),
    ("ModifyDate", "document.modified_date"),
];

#[derive(Debug)]
pub(super) struct Fact {
    pub key: String,
    pub value: Value,
}

#[derive(Debug)]
pub(super) struct Run {
    pub id: &'static str,
    pub version: String,
    pub status: &'static str,
    pub error: Option<String>,
    pub facts: Vec<Fact>,
}

#[derive(Default)]
pub(super) struct ToolVersions {
    versions: HashMap<&'static str, Result<String, String>>,
}

impl ToolVersions {
    fn get(&mut self, tool: &'static str) -> Result<String, String> {
        if let Some(version) = self.versions.get(tool) {
            return version.clone();
        }
        let version = tool_version(tool);
        self.versions.insert(tool, version.clone());
        version
    }
}

pub(super) fn applicable(media_family: &str, mime_type: &str) -> Vec<&'static str> {
    match media_family {
        "photo" => vec![IMAGE_EXTRACTOR, EXIFTOOL_EXTRACTOR],
        "video" | "audio" => vec![FFPROBE_EXTRACTOR],
        _ if mime_type == "application/pdf" => vec![EXIFTOOL_EXTRACTOR, PDFINFO_EXTRACTOR],
        _ => Vec::new(),
    }
}

pub(super) fn current_version(
    extractor_id: &str,
    tools: &mut ToolVersions,
) -> Result<String, String> {
    match extractor_id {
        IMAGE_EXTRACTOR => Ok("1".to_string()),
        EXIFTOOL_EXTRACTOR => tools.get(EXIFTOOL_EXTRACTOR),
        FFPROBE_EXTRACTOR => tools.get(FFPROBE_EXTRACTOR),
        PDFINFO_EXTRACTOR => tools.get(PDFINFO_EXTRACTOR),
        _ => Err(format!("unknown extractor: {extractor_id}")),
    }
}

pub(super) fn run(
    extractor_id: &'static str,
    version: &str,
    path: &Path,
    media_family: &str,
) -> Run {
    let result = match extractor_id {
        IMAGE_EXTRACTOR => image_header(path),
        EXIFTOOL_EXTRACTOR => exiftool(path, media_family),
        FFPROBE_EXTRACTOR => ffprobe(path),
        PDFINFO_EXTRACTOR => pdfinfo(path),
        _ => Err(format!("unknown extractor: {extractor_id}")),
    };
    match result {
        Ok(facts) => Run {
            id: extractor_id,
            version: version.to_string(),
            status: "success",
            error: None,
            facts,
        },
        Err(error) => Run {
            id: extractor_id,
            version: version.to_string(),
            status: "failed",
            error: Some(error),
            facts: Vec::new(),
        },
    }
}

fn tool_version(tool: &str) -> Result<String, String> {
    let (args, version_from_stderr) = match tool {
        EXIFTOOL_EXTRACTOR => (vec!["-ver"], false),
        FFPROBE_EXTRACTOR => (vec!["-version"], false),
        PDFINFO_EXTRACTOR => (vec!["-v"], true),
        _ => return Err(format!("unknown metadata tool: {tool}")),
    };
    let output = run_command(Command::new(tool).args(args))
        .map_err(|error| format!("{tool} is unavailable or failed: {error}"))?;
    if !output.status.success() {
        return Err(format!("{tool} version check failed: {}", output_text(&output, version_from_stderr)));
    }
    let text = output_text(&output, version_from_stderr);
    text.lines()
        .map(str::trim)
        .find(|line| !line.is_empty())
        .map(str::to_string)
        .ok_or_else(|| format!("{tool} returned an empty version"))
}

fn output_text(output: &Output, from_stderr: bool) -> String {
    let bytes = if from_stderr { &output.stderr } else { &output.stdout };
    String::from_utf8_lossy(bytes).trim().to_string()
}

fn image_header(path: &Path) -> Result<Vec<Fact>, String> {
    let reader = image::ImageReader::open(path)
        .map_err(|error| format!("{}: {error}", path.display()))?
        .with_guessed_format()
        .map_err(|error| format!("{}: {error}", path.display()))?;
    let (width, height) = reader
        .into_dimensions()
        .map_err(|error| format!("{}: {error}", path.display()))?;
    Ok(vec![
        fact("image.width", Value::from(width)),
        fact("image.height", Value::from(height)),
    ])
}

fn exiftool(path: &Path, media_family: &str) -> Result<Vec<Fact>, String> {
    let mut command = Command::new(EXIFTOOL_EXTRACTOR);
    command.args(["-json", "-n", "-s"]);
    match media_family {
        "photo" => command.args(IMAGE_TAGS.iter().map(|(tag, _)| format!("-{tag}"))),
        _ => command.args(DOCUMENT_TAGS.iter().map(|(tag, _)| format!("-{tag}"))),
    };
    let output = run_command(command.arg("--").arg(path))
        .map_err(|error| format!("exiftool is unavailable or failed: {error}"))?;
    if !output.status.success() {
        return Err(format!("exiftool failed: {}", output_text(&output, true)));
    }
    let documents: Value = serde_json::from_slice(&output.stdout)
        .map_err(|error| format!("exiftool returned invalid JSON: {error}"))?;
    let document = documents
        .as_array()
        .and_then(|items| items.first())
        .and_then(Value::as_object)
        .ok_or("exiftool returned no metadata object")?;
    let mut facts = Vec::new();
    let fields = if media_family == "photo" {
        IMAGE_TAGS
    } else {
        DOCUMENT_TAGS
    };
    for (tag, key) in fields {
        if let Some(value) = find_tag(document, tag) {
            facts.push(fact(key, value.clone()));
        }
    }
    Ok(facts)
}

fn find_tag<'a>(document: &'a Map<String, Value>, tag: &str) -> Option<&'a Value> {
    document.get(tag).or_else(|| {
        document
            .iter()
            .find_map(|(key, value)| key.rsplit_once(':').filter(|(_, name)| *name == tag).map(|_| value))
    })
}

fn ffprobe(path: &Path) -> Result<Vec<Fact>, String> {
    let output = run_command(Command::new(FFPROBE_EXTRACTOR)
        .args([
            "-v",
            "error",
            "-show_entries",
            "format=format_name,duration,size,bit_rate:stream=index,codec_type,codec_name,width,height,avg_frame_rate,sample_rate,channels,channel_layout,duration,bit_rate:format_tags=title,artist,album,genre,date:stream_tags=language,title",
            "-of",
            "json",
            "-i",
        ])
        .arg(path)
    )
    .map_err(|error| format!("ffprobe is unavailable or failed: {error}"))?;
    if !output.status.success() {
        return Err(format!("ffprobe failed: {}", output_text(&output, true)));
    }
    let document: Value = serde_json::from_slice(&output.stdout)
        .map_err(|error| format!("ffprobe returned invalid JSON: {error}"))?;
    parse_ffprobe(&document)
}

fn parse_ffprobe(document: &Value) -> Result<Vec<Fact>, String> {
    let mut facts = Vec::new();
    if let Some(format) = document.get("format").and_then(Value::as_object) {
        push_selected(
            &mut facts,
            format,
            &[
                ("format_name", "media.format"),
                ("duration", "media.duration_seconds"),
                ("size", "media.container_size_bytes"),
                ("bit_rate", "media.bit_rate"),
            ],
        );
        if let Some(tags) = format.get("tags").and_then(Value::as_object) {
            push_selected(
                &mut facts,
                tags,
                &[
                    ("title", "media.title"),
                    ("artist", "audio.artist"),
                    ("album", "audio.album"),
                    ("genre", "audio.genre"),
                    ("date", "media.date"),
                ],
            );
        }
    }
    if let Some(streams) = document.get("streams").and_then(Value::as_array) {
        let selected = streams
            .iter()
            .filter_map(Value::as_object)
            .map(|stream| {
                let mut selected = Map::new();
                for key in [
                    "index",
                    "codec_type",
                    "codec_name",
                    "width",
                    "height",
                    "avg_frame_rate",
                    "sample_rate",
                    "channels",
                    "channel_layout",
                    "duration",
                    "bit_rate",
                ] {
                    if let Some(value) = stream.get(key) {
                        selected.insert(key.to_string(), value.clone());
                    }
                }
                if let Some(tags) = stream.get("tags").and_then(Value::as_object) {
                    for key in ["language", "title"] {
                        if let Some(value) = tags.get(key) {
                            selected.insert(format!("tag_{key}"), value.clone());
                        }
                    }
                }
                Value::Object(selected)
            })
            .collect::<Vec<_>>();
        facts.push(fact("media.streams", Value::Array(selected)));
    }
    Ok(facts)
}

fn push_selected(facts: &mut Vec<Fact>, source: &Map<String, Value>, fields: &[(&str, &str)]) {
    for (name, key) in fields {
        if let Some(value) = source.get(*name) {
            facts.push(fact(key, value.clone()));
        }
    }
}

fn pdfinfo(path: &Path) -> Result<Vec<Fact>, String> {
    let output = run_command(Command::new(PDFINFO_EXTRACTOR)
        .args(["-isodates", "-enc", "UTF-8"])
        .arg(path)
    )
    .map_err(|error| format!("pdfinfo is unavailable or failed: {error}"))?;
    if !output.status.success() {
        return Err(format!("pdfinfo failed: {}", output_text(&output, true)));
    }
    let mut facts = Vec::new();
    for line in output_text(&output, false).lines() {
        let Some((key, value)) = line.split_once(':') else {
            continue;
        };
        let key = key.trim();
        let value = value.trim();
        if value.is_empty() {
            continue;
        }
        match key {
            "Pages" => {
                if let Ok(pages) = value.parse::<u64>() {
                    facts.push(fact("document.page_count", Value::from(pages)));
                }
            }
            "Page size" => facts.push(fact("document.page_size", Value::from(value))),
            "Encrypted" => facts.push(fact("document.encrypted", Value::from(value.starts_with("yes")))),
            _ => {}
        }
    }
    Ok(facts)
}

fn fact(key: &str, value: Value) -> Fact {
    Fact { key: key.to_string(), value }
}

fn run_command(command: &mut Command) -> io::Result<Output> {
    let mut child = command.stdout(Stdio::piped()).stderr(Stdio::piped()).spawn()?;
    let mut stdout = child.stdout.take().ok_or_else(|| io::Error::other("stdout pipe unavailable"))?;
    let mut stderr = child.stderr.take().ok_or_else(|| io::Error::other("stderr pipe unavailable"))?;
    let stdout_reader = thread::spawn(move || {
        let mut bytes = Vec::new();
        stdout.read_to_end(&mut bytes).map(|_| bytes)
    });
    let stderr_reader = thread::spawn(move || {
        let mut bytes = Vec::new();
        stderr.read_to_end(&mut bytes).map(|_| bytes)
    });
    let deadline = Instant::now() + COMMAND_TIMEOUT;
    loop {
        match child.try_wait() {
            Ok(Some(status)) => {
                let stdout = stdout_reader
                    .join()
                    .map_err(|_| io::Error::other("stdout reader panicked"))??;
                let stderr = stderr_reader
                    .join()
                    .map_err(|_| io::Error::other("stderr reader panicked"))??;
                return Ok(Output { status, stdout, stderr });
            }
            Ok(None) => {}
            Err(error) => {
                let _ = child.kill();
                let _ = child.wait();
                let _ = stdout_reader.join();
                let _ = stderr_reader.join();
                return Err(error);
            }
        }
        if Instant::now() >= deadline {
            let _ = child.kill();
            let _ = child.wait();
            let _ = stdout_reader.join();
            let _ = stderr_reader.join();
            return Err(io::Error::new(io::ErrorKind::TimedOut, "metadata command timed out"));
        }
        thread::sleep(Duration::from_millis(25));
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn only_sensitive_metadata_is_excluded_from_image_field_list() {
        let document = serde_json::from_value(serde_json::json!({
            "ImageWidth": 640,
            "GPSLatitude": 50.1,
            "SerialNumber": "camera-id",
            "Model": "Camera"
        }))
        .unwrap();
        assert_eq!(find_tag(&document, "ImageWidth"), Some(&Value::from(640)));
        assert!(find_tag(&document, "GPSLatitude").is_some());
        assert!(!IMAGE_TAGS.iter().any(|(tag, _)| *tag == "GPSLatitude"));
        assert!(!IMAGE_TAGS.iter().any(|(tag, _)| *tag == "SerialNumber"));
    }

    #[test]
    fn media_facts_select_only_expected_extractor_families() {
        assert_eq!(applicable("photo", "image/jpeg"), vec![IMAGE_EXTRACTOR, EXIFTOOL_EXTRACTOR]);
        assert_eq!(applicable("video", "video/mp4"), vec![FFPROBE_EXTRACTOR]);
        assert_eq!(applicable("audio", "audio/flac"), vec![FFPROBE_EXTRACTOR]);
        assert_eq!(applicable("other", "application/pdf"), vec![EXIFTOOL_EXTRACTOR, PDFINFO_EXTRACTOR]);
        assert!(applicable("other", "application/octet-stream").is_empty());
    }

    #[test]
    fn ffprobe_facts_keep_stream_properties_but_not_unrequested_tags() {
        let document = serde_json::json!({
            "format": {
                "format_name": "mov,mp4",
                "duration": "12.5",
                "tags": {"title": "clip", "artist": "Artist", "location": "private"}
            },
            "streams": [{
                "index": 0,
                "codec_type": "video",
                "codec_name": "h264",
                "width": 1920,
                "height": 1080,
                "tags": {"language": "eng", "location": "private"}
            }]
        });
        let facts = parse_ffprobe(&document).unwrap();
        let streams = facts.iter().find(|fact| fact.key == "media.streams").unwrap();
        assert_eq!(streams.value[0]["codec_name"], "h264");
        assert_eq!(streams.value[0]["width"], 1920);
        assert!(streams.value[0].get("location").is_none());
        assert!(facts.iter().any(|fact| fact.key == "audio.artist"));
        assert!(!facts.iter().any(|fact| fact.key.contains("location")));
    }
}
