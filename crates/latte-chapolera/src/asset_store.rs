use crate::{Counts, FileEntry};
use crate::extractors::{self, Run as ExtractorRun, ToolVersions};
use latte_index_core::{detect_signature, sha256_file, walk_visible_files, FileFingerprint};
use rusqlite::{params, Connection, OptionalExtension, Transaction, TransactionBehavior};
use std::collections::HashSet;
use std::ffi::OsStr;
use std::fs;
use std::os::unix::ffi::{OsStrExt, OsStringExt};
use std::path::{Path, PathBuf};
use std::time::{SystemTime, UNIX_EPOCH};

pub(crate) mod organize;

const SCHEMA_VERSION: i64 = 5;

/// `scan quick` leaves the slow extractors (ExifTool, ffprobe…) to `enrich`, so the folder shows up at once.
static QUICK_SCAN: std::sync::atomic::AtomicBool = std::sync::atomic::AtomicBool::new(false);

pub(crate) fn set_quick_scan(quick: bool) {
    QUICK_SCAN.store(quick, std::sync::atomic::Ordering::Relaxed);
}

const MAX_TAG_LABEL_LENGTH: usize = 256;
const MAX_SEMANTIC_ID_LENGTH: usize = 128;

#[derive(Debug)]
struct DiscoveredFile {
    path: PathBuf,
    path_key: Vec<u8>,
    name_key: Vec<u8>,
    name: String,
    path_display: String,
    metadata: FileFingerprint,
    scan_order: i64,
}

#[derive(Debug)]
struct ExistingAsset {
    id: i64,
    metadata: FileFingerprint,
    sha256: String,
    mime_type: String,
    media_family: String,
    was_present: bool,
}

#[derive(Debug)]
struct SemanticTag {
    label: String,
    normalized_label: String,
    confidence: f64,
    source: String,
}

/// Image features are kept by content hash, so a photo seen once is never run through the model again.
pub(crate) fn load_embedding(path: &Path, model_version: &str) -> Option<Vec<f32>> {
    load_embedding_with_database(path, model_version, &default_database_path().ok()?)
}

pub(crate) fn store_embedding(path: &Path, model_version: &str, vector: &[f32]) {
    if let Ok(database) = default_database_path() {
        let _ = store_embedding_with_database(path, model_version, vector, &database);
    }
}

fn load_embedding_with_database(path: &Path, model_version: &str, database_path: &Path) -> Option<Vec<f32>> {
    let connection = open_database(database_path).ok()?;
    let blob: Vec<u8> = connection
        .query_row(
            "SELECT e.vector FROM image_embeddings e JOIN assets a ON a.sha256 = e.content_sha256
             WHERE a.path_key = ?1 AND a.present = 1 AND e.model_version = ?2",
            params![path.as_os_str().as_bytes(), model_version],
            |row| row.get(0),
        )
        .optional()
        .ok()??;
    if blob.len() % 4 != 0 || blob.is_empty() {
        return None;
    }
    Some(blob.chunks_exact(4).map(|bytes| f32::from_le_bytes([bytes[0], bytes[1], bytes[2], bytes[3]])).collect())
}

fn store_embedding_with_database(path: &Path, model_version: &str, vector: &[f32], database_path: &Path) -> Result<(), String> {
    let connection = open_database(database_path)?;
    let blob: Vec<u8> = vector.iter().flat_map(|value| value.to_le_bytes()).collect();
    connection
        .execute(
            "INSERT OR REPLACE INTO image_embeddings (content_sha256, model_version, vector, created_at)
             SELECT sha256, ?2, ?3, ?4 FROM assets WHERE path_key = ?1 AND present = 1",
            params![path.as_os_str().as_bytes(), model_version, blob, unix_seconds()?],
        )
        .map(|_| ())
        .map_err(|error| format!("could not store image features: {error}"))
}

pub(super) fn enrich(folder: &Path) -> Result<String, String> {
    let canonical = fs::canonicalize(folder).map_err(|error| format!("{}: {error}", folder.display()))?;
    enrich_with_database(&canonical, &default_database_path()?)
}

/// Runs the extractors the quick scan skipped, several files at once (they are separate processes or
/// independent decodes), and stores everything in one transaction.
fn enrich_with_database(root: &Path, database_path: &Path) -> Result<String, String> {
    use std::sync::atomic::{AtomicUsize, Ordering};
    use std::sync::Mutex;
    let mut connection = open_database(database_path)?;
    let assets: Vec<(i64, Vec<u8>, String, String, String, String)> = {
        let mut statement = connection
            .prepare(
                "SELECT assets.id, assets.path_key, assets.name, assets.sha256, assets.mime_type, assets.media_family
                 FROM assets JOIN roots ON roots.id = assets.root_id
                 WHERE assets.present = 1 AND roots.root_key = ?1 ORDER BY assets.scan_order",
            )
            .map_err(|error| format!("could not prepare enrichment query: {error}"))?;
        let rows = statement
            .query_map([root.as_os_str().as_bytes()], |row| {
                Ok((row.get(0)?, row.get(1)?, row.get(2)?, row.get(3)?, row.get(4)?, row.get(5)?))
            })
            .map_err(|error| format!("could not read assets: {error}"))?;
        rows.collect::<Result<Vec<_>, _>>().map_err(|error| format!("could not read assets: {error}"))?
    };
    let mut tools = ToolVersions::default();
    // (asset index, extractor, version)
    let mut jobs: Vec<(usize, &'static str, String)> = Vec::new();
    let mut unavailable: Vec<(usize, ExtractorRun)> = Vec::new();
    {
        let probe = connection.transaction().map_err(|error| error.to_string())?;
        for (index, (asset_id, _, _, sha256, mime_type, family)) in assets.iter().enumerate() {
            for extractor_id in extractors::applicable(family, mime_type) {
                match extractors::current_version(extractor_id, &mut tools) {
                    Ok(version) if extractor_run_is_current(&probe, *asset_id, extractor_id, &version, sha256)? => {}
                    Ok(version) => jobs.push((index, extractor_id, version)),
                    Err(error) => unavailable.push((
                        index,
                        ExtractorRun { id: extractor_id, version: "unavailable".to_string(), status: "failed", error: Some(error), facts: Vec::new() },
                    )),
                }
            }
        }
    }
    let next = AtomicUsize::new(0);
    let finished: Mutex<Vec<(usize, ExtractorRun)>> = Mutex::new(Vec::new());
    let workers = std::thread::available_parallelism().map(|n| n.get()).unwrap_or(4).clamp(1, 8);
    std::thread::scope(|scope| {
        for _ in 0..workers {
            scope.spawn(|| loop {
                let at = next.fetch_add(1, Ordering::Relaxed);
                let Some((index, extractor_id, version)) = jobs.get(at) else { break };
                let (_, path_key, _, _, _, family) = &assets[*index];
                let path = PathBuf::from(std::ffi::OsString::from_vec(path_key.clone()));
                let run = extractors::run(extractor_id, version, &path, family);
                finished.lock().unwrap().push((*index, run));
            });
        }
    });
    let mut runs = finished.into_inner().unwrap_or_default();
    runs.extend(unavailable);
    let now = unix_seconds()?;
    let transaction = connection
        .transaction_with_behavior(TransactionBehavior::Immediate)
        .map_err(|error| format!("could not begin enrichment: {error}"))?;
    let count = runs.len();
    for (index, run) in &runs {
        let (asset_id, _, name, sha256, _, _) = &assets[*index];
        store_run_with_facts(&transaction, *asset_id, sha256, run, name, now)?;
    }
    transaction.commit().map_err(|error| format!("could not save enrichment: {error}"))?;
    Ok(serde_json::json!({ "assets": assets.len(), "extractor_runs": count }).to_string())
}

pub(super) fn scan(
    folder: &Path,
    limit: usize,
    offset: usize,
) -> Result<(Counts, Vec<FileEntry>), String> {
    let database_path = default_database_path()?;
    scan_with_database(folder, limit, offset, &database_path)
}

pub(super) fn scan_with_database(
    folder: &Path,
    limit: usize,
    offset: usize,
    database_path: &Path,
) -> Result<(Counts, Vec<FileEntry>), String> {
    if !crate::valid_preview_limit(limit) {
        return Err(format!(
            "preview limit must be {}–{} in steps of {}",
            crate::MIN_PREVIEW_LIMIT,
            crate::MAX_PREVIEW_LIMIT,
            crate::PREVIEW_STEP
        ));
    }

    let root = fs::canonicalize(folder).map_err(|error| format!("{}: {error}", folder.display()))?;
    if !root.is_dir() {
        return Err(format!("{}: not a folder", root.display()));
    }
    let mut connection = open_database(database_path)?;
    let transaction = connection
        .transaction_with_behavior(TransactionBehavior::Immediate)
        .map_err(|error| format!("could not begin Chapolera scan: {error}"))?;

    let root_key = root.as_os_str().as_bytes();
    transaction
        .execute(
            "INSERT OR IGNORE INTO roots (root_key, root_path) VALUES (?1, ?2)",
            params![root_key, root.to_string_lossy()],
        )
        .map_err(|error| format!("could not register Chapolera root: {error}"))?;
    let root_id: i64 = transaction
        .query_row("SELECT id FROM roots WHERE root_key = ?1", [root_key], |row| row.get(0))
        .map_err(|error| format!("could not read Chapolera root: {error}"))?;
    transaction
        .execute_batch("CREATE TEMP TABLE previous_assets (asset_id INTEGER PRIMARY KEY);")
        .map_err(|error| format!("could not prepare Chapolera reconciliation: {error}"))?;
    transaction
        .execute(
            "INSERT INTO previous_assets (asset_id) SELECT id FROM assets WHERE root_id = ?1 AND present = 1",
            [root_id],
        )
        .map_err(|error| format!("could not snapshot previous Chapolera assets: {error}"))?;
    transaction
        .execute("UPDATE assets SET present = 0 WHERE root_id = ?1", [root_id])
        .map_err(|error| format!("could not begin asset reconciliation: {error}"))?;

    let now = unix_seconds()?;
    let mut counts = Counts::default();
    let mut tool_versions = ToolVersions::default();
    counts.subfolders = visit_files(&root, &mut |file| {
        counts.total += 1;
        let previous = load_asset_at_path(&transaction, root_id, &file.path_key)?;
        let unchanged = previous
            .as_ref()
            .filter(|asset| asset.was_present && asset.metadata == file.metadata);

        if let Some(asset) = unchanged {
            transaction
                .execute(
                    "UPDATE assets SET present = 1, scan_order = ?1, last_seen_at = ?2 WHERE id = ?3",
                    params![file.scan_order, now, asset.id],
                )
                .map_err(|error| format!("could not refresh {}: {error}", file.path.display()))?;
            add_family_count(&mut counts, &asset.media_family);
            persist_extractions(
                &transaction,
                asset.id,
                &file.path,
                &asset.sha256,
                &asset.mime_type,
                &asset.media_family,
                &file.name,
                &mut tool_versions,
                now,
            )?;
            return Ok(());
        }

        let sha256 = sha256_file(&file.path)?;
        let (mime_type, format, media_family) = detect_type(&file.path, &file.name)?;
        let verified = fs::symlink_metadata(&file.path)
            .map_err(|error| format!("{}: {error}", file.path.display()))?;
        if !verified.is_file() || FileFingerprint::from_metadata(&verified, &file.path)? != file.metadata {
            return Err(format!("{}: file changed while indexing; run the scan again", file.path.display()));
        }

        let existing_id = if let Some(asset) = previous.as_ref() {
            Some(asset.id)
        } else {
            reusable_asset_id(&transaction, root_id, &file.path, &sha256)?
        };
        let asset_id = if let Some(asset_id) = existing_id {
            update_asset(
                &transaction,
                asset_id,
                root_id,
                &file,
                &mime_type,
                &format,
                &media_family,
                &sha256,
                now,
            )?;
            asset_id
        } else {
            transaction
                .execute(
                    "INSERT INTO assets (
                        root_id, path_key, path, original_name, name, size_bytes,
                        modified_seconds, modified_nanoseconds, changed_seconds,
                        changed_nanoseconds, device, inode, mime_type, format,
                        media_family, sha256, present, scan_order, first_seen_at, last_seen_at
                     ) VALUES (
                        ?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11,
                        ?12, ?13, ?14, ?15, ?16, 1, ?17, ?18, ?18
                     )",
                    params![
                        root_id,
                        file.path_key,
                        file.path_display,
                        file.name_key,
                        file.name,
                        file.metadata.size,
                        file.metadata.modified_seconds,
                        file.metadata.modified_nanoseconds,
                        file.metadata.changed_seconds,
                        file.metadata.changed_nanoseconds,
                        file.metadata.device,
                        file.metadata.inode,
                        mime_type,
                        format,
                        media_family,
                        sha256,
                        file.scan_order,
                        now,
                    ],
                )
                .map_err(|error| format!("could not index {}: {error}", file.path.display()))?;
            transaction.last_insert_rowid()
        };
        let mime_type = previous.as_ref()
            .filter(|asset| Some(asset.id) == existing_id)
            .map(|asset| asset.mime_type.as_str())
            .unwrap_or(&mime_type);
        let verified = fs::symlink_metadata(&file.path)
            .map_err(|error| format!("{}: {error}", file.path.display()))?;
        if !verified.is_file() || FileFingerprint::from_metadata(&verified, &file.path)? != file.metadata {
            return Err(format!("{}: file changed while indexing; run the scan again", file.path.display()));
        }
        persist_extractions(
            &transaction,
            asset_id,
            &file.path,
            &sha256,
            &mime_type,
            &media_family,
            &file.name,
            &mut tool_versions,
            now,
        )?;
        add_family_count(&mut counts, &media_family);
        Ok(())
    })?;

    transaction
        .execute(
            "UPDATE roots SET last_scanned_at = ?1 WHERE id = ?2",
            params![now, root_id],
        )
        .map_err(|error| format!("could not finish Chapolera scan: {error}"))?;
    let preview_limit = i64::try_from(limit).map_err(|_| "preview limit is out of range".to_string())?;
    let preview_offset = i64::try_from(offset).map_err(|_| "preview offset is out of range".to_string())?;
    let previews = load_previews(&transaction, root_id, preview_limit, preview_offset)?;
    transaction.commit().map_err(|error| format!("could not save Chapolera scan: {error}"))?;
    Ok((counts, previews))
}

pub(super) fn duplicates(folder: &Path) -> Result<String, String> {
    let canonical = fs::canonicalize(folder).map_err(|error| format!("{}: {error}", folder.display()))?;
    duplicates_with_database(&canonical, &default_database_path()?)
}

/// Groups present, non-empty assets under `folder` with identical content. Report only: nothing is deleted or moved.
fn duplicates_with_database(folder: &Path, database_path: &Path) -> Result<String, String> {
    let connection = open_database(database_path)?;
    let mut prefix = folder.as_os_str().as_bytes().to_vec();
    if prefix.last() != Some(&b'/') {
        prefix.push(b'/');
    }
    let mut statement = connection
        .prepare(
            "SELECT sha256, size_bytes, path FROM assets
             WHERE present = 1 AND size_bytes > 0 AND substr(path_key, 1, ?1) = ?2
               AND sha256 IN (
                   SELECT sha256 FROM assets
                   WHERE present = 1 AND size_bytes > 0 AND substr(path_key, 1, ?1) = ?2
                   GROUP BY sha256 HAVING count(*) > 1)
             ORDER BY sha256, path",
        )
        .map_err(|error| format!("could not prepare duplicate query: {error}"))?;
    let rows = statement
        .query_map(params![prefix.len() as i64, prefix], |row| {
            Ok((row.get::<_, String>(0)?, row.get::<_, i64>(1)?, row.get::<_, String>(2)?))
        })
        .map_err(|error| format!("could not read duplicates: {error}"))?;
    let mut groups: Vec<serde_json::Value> = Vec::new();
    let mut last = String::new();
    for row in rows {
        let (sha256, size, path) = row.map_err(|error| format!("could not read duplicate row: {error}"))?;
        if sha256 != last {
            groups.push(serde_json::json!({ "sha256": sha256, "size_bytes": size, "paths": [] }));
            last = sha256;
        }
        groups.last_mut().unwrap()["paths"].as_array_mut().unwrap().push(path.into());
    }
    groups.sort_by(|a, b| b["size_bytes"].as_i64().cmp(&a["size_bytes"].as_i64()));
    Ok(serde_json::json!({ "groups": groups }).to_string())
}

pub(super) fn profile(path: &Path) -> Result<String, String> {
    let canonical_path = fs::canonicalize(path).map_err(|error| format!("{}: {error}", path.display()))?;
    let database_path = default_database_path()?;
    profile_with_database(&canonical_path, &database_path)
}

pub(super) fn store_semantic_tags(
    path: &Path,
    analyzer_id: &str,
    model_id: &str,
    model_version: &str,
    task_version: &str,
    locality: &str,
    tags_json: &str,
) -> Result<String, String> {
    let canonical_path =
        fs::canonicalize(path).map_err(|error| format!("{}: {error}", path.display()))?;
    let database_path = default_database_path()?;
    store_semantic_tags_with_database(
        &canonical_path,
        analyzer_id,
        model_id,
        model_version,
        task_version,
        locality,
        tags_json,
        &database_path,
    )
}

fn store_semantic_tags_with_database(
    path: &Path,
    analyzer_id: &str,
    model_id: &str,
    model_version: &str,
    task_version: &str,
    locality: &str,
    tags_json: &str,
    database_path: &Path,
) -> Result<String, String> {
    let analyzer_id = validate_semantic_id(analyzer_id, "analyzer ID")?;
    let model_id = validate_semantic_id(model_id, "model ID")?;
    let model_version = validate_semantic_id(model_version, "model version")?;
    let task_version = validate_semantic_id(task_version, "task version")?;
    if !matches!(locality, "local" | "cloud") {
        return Err("semantic analysis locality must be 'local' or 'cloud'".to_string());
    }
    let tags = parse_semantic_tags(tags_json)?;
    let content_sha256 = sha256_file(path)?;
    let mut connection = open_database(database_path)?;
    let transaction = connection
        .transaction_with_behavior(TransactionBehavior::Immediate)
        .map_err(|error| format!("could not begin Chapolera tag update: {error}"))?;
    let asset: Option<(i64, String)> = transaction
        .query_row(
            "SELECT id, sha256 FROM assets WHERE path_key = ?1 AND present = 1",
            [path.as_os_str().as_bytes()],
            |row| Ok((row.get(0)?, row.get(1)?)),
        )
        .optional()
        .map_err(|error| format!("could not find Chapolera asset for tags: {error}"))?;
    let (asset_id, indexed_sha256) =
        asset.ok_or_else(|| format!("{} is not present in the Chapolera index", path.display()))?;
    if content_sha256 != indexed_sha256 {
        return Err(format!(
            "{} changed since it was indexed; scan it again before storing semantic tags",
            path.display()
        ));
    }
    let now = unix_seconds()?;
    transaction
        .execute(
            "INSERT INTO semantic_runs (
                asset_id, analyzer_id, model_id, model_version, task_version,
                locality, content_sha256, status, error_message, updated_at
             ) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, 'success', NULL, ?8)
             ON CONFLICT (
                asset_id, analyzer_id, model_id, model_version, task_version,
                locality, content_sha256
             ) DO UPDATE SET status = 'success', error_message = NULL, updated_at = excluded.updated_at",
            params![
                asset_id,
                analyzer_id,
                model_id,
                model_version,
                task_version,
                locality,
                content_sha256,
                now,
            ],
        )
        .map_err(|error| format!("could not save Chapolera semantic run: {error}"))?;
    let run_id: i64 = transaction
        .query_row(
            "SELECT id FROM semantic_runs
             WHERE asset_id = ?1 AND analyzer_id = ?2 AND model_id = ?3
               AND model_version = ?4 AND task_version = ?5 AND locality = ?6
               AND content_sha256 = ?7",
            params![
                asset_id,
                analyzer_id,
                model_id,
                model_version,
                task_version,
                locality,
                content_sha256,
            ],
            |row| row.get(0),
        )
        .map_err(|error| format!("could not read Chapolera semantic run: {error}"))?;
    transaction
        .execute("DELETE FROM asset_tags WHERE semantic_run_id = ?1", [run_id])
        .map_err(|error| format!("could not replace Chapolera semantic tags: {error}"))?;
    for tag in &tags {
        transaction
            .execute(
                "INSERT INTO tags (normalized_label, display_label) VALUES (?1, ?2)
                 ON CONFLICT(normalized_label) DO NOTHING",
                params![tag.normalized_label, tag.label],
            )
            .map_err(|error| format!("could not register Chapolera tag: {error}"))?;
        let tag_id: i64 = transaction
            .query_row(
                "SELECT id FROM tags WHERE normalized_label = ?1",
                [&tag.normalized_label],
                |row| row.get(0),
            )
            .map_err(|error| format!("could not read Chapolera tag: {error}"))?;
        transaction
            .execute(
                "INSERT INTO asset_tags (semantic_run_id, tag_id, confidence, source, created_at)
                 VALUES (?1, ?2, ?3, ?4, ?5)",
                params![run_id, tag_id, tag.confidence, tag.source, now],
            )
            .map_err(|error| format!("could not attach Chapolera tag {}: {error}", tag.label))?;
    }
    transaction
        .commit()
        .map_err(|error| format!("could not commit Chapolera semantic tags: {error}"))?;
    serde_json::to_string(&serde_json::json!({
        "asset_id": asset_id,
        "content_sha256": content_sha256,
        "stored": tags.len(),
        "analyzer": analyzer_id,
        "model": model_id,
        "model_version": model_version,
        "task_version": task_version,
        "locality": locality,
    }))
    .map_err(|error| format!("could not serialize Chapolera tag result: {error}"))
}

pub(super) fn semantic_tag_cache(
    path: &Path,
    analyzer_id: &str,
    model_id: &str,
    model_version: &str,
    task_version: &str,
    locality: &str,
) -> Result<String, String> {
    let canonical_path =
        fs::canonicalize(path).map_err(|error| format!("{}: {error}", path.display()))?;
    let database_path = default_database_path()?;
    semantic_tag_cache_with_database(
        &canonical_path,
        analyzer_id,
        model_id,
        model_version,
        task_version,
        locality,
        &database_path,
    )
}

pub(super) fn semantic_tag_cache_after_scan(
    path: &Path,
    analyzer_id: &str,
    model_id: &str,
    model_version: &str,
    task_version: &str,
    locality: &str,
) -> Result<String, String> {
    let canonical_path =
        fs::canonicalize(path).map_err(|error| format!("{}: {error}", path.display()))?;
    let database_path = default_database_path()?;
    semantic_tag_cache_after_scan_with_database(
        &canonical_path,
        analyzer_id,
        model_id,
        model_version,
        task_version,
        locality,
        &database_path,
    )
}

fn semantic_tag_cache_after_scan_with_database(
    path: &Path,
    analyzer_id: &str,
    model_id: &str,
    model_version: &str,
    task_version: &str,
    locality: &str,
    database_path: &Path,
) -> Result<String, String> {
    let analyzer_id = validate_semantic_id(analyzer_id, "analyzer ID")?;
    let model_id = validate_semantic_id(model_id, "model ID")?;
    let model_version = validate_semantic_id(model_version, "model version")?;
    let task_version = validate_semantic_id(task_version, "task version")?;
    if !matches!(locality, "local" | "cloud") {
        return Err("semantic analysis locality must be 'local' or 'cloud'".to_string());
    }
    let metadata =
        fs::symlink_metadata(path).map_err(|error| format!("{}: {error}", path.display()))?;
    if !metadata.is_file() {
        return Err(format!("{} is no longer a regular file; scan the folder again", path.display()));
    }
    let current_metadata = FileFingerprint::from_metadata(&metadata, path)?;
    let connection = open_database(database_path)?;
    let asset: Option<(i64, String, FileFingerprint)> = connection
        .query_row(
            "SELECT id, sha256, size_bytes, modified_seconds, modified_nanoseconds,
                    changed_seconds, changed_nanoseconds, device, inode
             FROM assets WHERE path_key = ?1 AND present = 1",
            [path.as_os_str().as_bytes()],
            |row| {
                Ok((
                    row.get(0)?,
                    row.get(1)?,
                    FileFingerprint {
                        size: row.get(2)?,
                        modified_seconds: row.get(3)?,
                        modified_nanoseconds: row.get(4)?,
                        changed_seconds: row.get(5)?,
                        changed_nanoseconds: row.get(6)?,
                        device: row.get(7)?,
                        inode: row.get(8)?,
                    },
                ))
            },
        )
        .optional()
        .map_err(|error| format!("could not find Chapolera asset for tag cache: {error}"))?;
    let (asset_id, content_sha256, indexed_metadata) = asset
        .ok_or_else(|| format!("{} is not present in the Chapolera index", path.display()))?;
    if current_metadata != indexed_metadata {
        return Err(format!(
            "{} changed since it was scanned; scan the folder again before checking semantic tag cache",
            path.display()
        ));
    }
    let run_id: Option<i64> = connection
        .query_row(
            "SELECT id FROM semantic_runs
             WHERE asset_id = ?1 AND analyzer_id = ?2 AND model_id = ?3
               AND model_version = ?4 AND task_version = ?5 AND locality = ?6
               AND content_sha256 = ?7 AND status = 'success'",
            params![
                asset_id,
                analyzer_id,
                model_id,
                model_version,
                task_version,
                locality,
                content_sha256,
            ],
            |row| row.get(0),
        )
        .optional()
        .map_err(|error| format!("could not check Chapolera semantic cache: {error}"))?;
    let tags = if let Some(run_id) = run_id {
        load_semantic_tags(&connection, run_id)?
    } else {
        Vec::new()
    };
    serde_json::to_string(&serde_json::json!({
        "cached": run_id.is_some(),
        "tags": tags,
    }))
    .map_err(|error| format!("could not serialize Chapolera tag cache: {error}"))
}

fn semantic_tag_cache_with_database(
    path: &Path,
    analyzer_id: &str,
    model_id: &str,
    model_version: &str,
    task_version: &str,
    locality: &str,
    database_path: &Path,
) -> Result<String, String> {
    let analyzer_id = validate_semantic_id(analyzer_id, "analyzer ID")?;
    let model_id = validate_semantic_id(model_id, "model ID")?;
    let model_version = validate_semantic_id(model_version, "model version")?;
    let task_version = validate_semantic_id(task_version, "task version")?;
    if !matches!(locality, "local" | "cloud") {
        return Err("semantic analysis locality must be 'local' or 'cloud'".to_string());
    }
    let connection = open_database(database_path)?;
    let asset: Option<(i64, String)> = connection
        .query_row(
            "SELECT id, sha256 FROM assets WHERE path_key = ?1 AND present = 1",
            [path.as_os_str().as_bytes()],
            |row| Ok((row.get(0)?, row.get(1)?)),
        )
        .optional()
        .map_err(|error| format!("could not find Chapolera asset for tag cache: {error}"))?;
    let (asset_id, content_sha256) =
        asset.ok_or_else(|| format!("{} is not present in the Chapolera index", path.display()))?;
    if sha256_file(path)? != content_sha256 {
        return Err(format!(
            "{} changed since it was indexed; scan it again before checking semantic tag cache",
            path.display()
        ));
    }
    let run_id: Option<i64> = connection
        .query_row(
            "SELECT id FROM semantic_runs
             WHERE asset_id = ?1 AND analyzer_id = ?2 AND model_id = ?3
               AND model_version = ?4 AND task_version = ?5 AND locality = ?6
               AND content_sha256 = ?7 AND status = 'success'",
            params![
                asset_id,
                analyzer_id,
                model_id,
                model_version,
                task_version,
                locality,
                content_sha256,
            ],
            |row| row.get(0),
        )
        .optional()
        .map_err(|error| format!("could not check Chapolera semantic cache: {error}"))?;
    let tags = if let Some(run_id) = run_id {
        load_semantic_tags(&connection, run_id)?
    } else {
        Vec::new()
    };
    serde_json::to_string(&serde_json::json!({
        "cached": run_id.is_some(),
        "tags": tags,
    }))
    .map_err(|error| format!("could not serialize Chapolera tag cache: {error}"))
}

fn parse_semantic_tags(json: &str) -> Result<Vec<SemanticTag>, String> {
    let value: serde_json::Value =
        serde_json::from_str(json).map_err(|error| format!("invalid semantic tags JSON: {error}"))?;
    let values = value
        .as_array()
        .ok_or("semantic tags must be a JSON array")?;
    let mut labels = HashSet::new();
    let mut tags = Vec::with_capacity(values.len());
    for value in values {
        let object = value
            .as_object()
            .ok_or("each semantic tag must be a JSON object")?;
        let label = object
            .get("label")
            .and_then(serde_json::Value::as_str)
            .ok_or("each semantic tag needs a string label")?
            .trim();
        if label.is_empty() || label.chars().count() > MAX_TAG_LABEL_LENGTH {
            return Err(format!(
                "semantic tag labels must contain 1–{MAX_TAG_LABEL_LENGTH} characters"
            ));
        }
        if label.chars().any(char::is_control) {
            return Err("semantic tag labels must not contain control characters".to_string());
        }
        let normalized_label = label.split_whitespace().collect::<Vec<_>>().join(" ").to_lowercase();
        if !labels.insert(normalized_label.clone()) {
            return Err(format!("duplicate semantic tag: {label}"));
        }
        let confidence = object
            .get("confidence")
            .and_then(serde_json::Value::as_f64)
            .ok_or_else(|| format!("semantic tag {label:?} needs a numeric confidence"))?;
        if !confidence.is_finite() || !(0.0..=1.0).contains(&confidence) {
            return Err(format!("semantic tag {label:?} confidence must be between 0 and 1"));
        }
        let source = object
            .get("source")
            .and_then(serde_json::Value::as_str)
            .ok_or_else(|| format!("semantic tag {label:?} needs a string source"))?;
        let source = validate_semantic_id(source, "tag source")?;
        tags.push(SemanticTag {
            label: label.to_string(),
            normalized_label,
            confidence,
            source,
        });
    }
    Ok(tags)
}

fn validate_semantic_id(value: &str, description: &str) -> Result<String, String> {
    let value = value.trim();
    if value.is_empty()
        || value.chars().count() > MAX_SEMANTIC_ID_LENGTH
        || value.chars().any(char::is_control)
    {
        return Err(format!(
            "{description} must contain 1–{MAX_SEMANTIC_ID_LENGTH} non-control characters"
        ));
    }
    Ok(value.to_string())
}

fn load_semantic_tags(
    connection: &Connection,
    run_id: i64,
) -> Result<Vec<serde_json::Value>, String> {
    let mut statement = connection
        .prepare(
            "SELECT tags.normalized_label, tags.display_label, asset_tags.confidence,
                    asset_tags.source, semantic_runs.analyzer_id, semantic_runs.model_id,
                    semantic_runs.model_version, semantic_runs.task_version,
                    semantic_runs.locality, semantic_runs.content_sha256,
                    asset_tags.created_at
             FROM asset_tags
             JOIN tags ON tags.id = asset_tags.tag_id
             JOIN semantic_runs ON semantic_runs.id = asset_tags.semantic_run_id
             WHERE semantic_runs.id = ?1
             ORDER BY tags.normalized_label",
        )
        .map_err(|error| format!("could not prepare Chapolera tag query: {error}"))?;
    let rows = statement
        .query_map([run_id], |row| {
            Ok(serde_json::json!({
                "normalized_label": row.get::<_, String>(0)?,
                "label": row.get::<_, String>(1)?,
                "confidence": row.get::<_, f64>(2)?,
                "source": row.get::<_, String>(3)?,
                "provenance": {
                    "analyzer": row.get::<_, String>(4)?,
                    "model": row.get::<_, String>(5)?,
                    "model_version": row.get::<_, String>(6)?,
                    "task_version": row.get::<_, String>(7)?,
                    "locality": row.get::<_, String>(8)?,
                    "content_sha256": row.get::<_, String>(9)?,
                    "created_at": row.get::<_, i64>(10)?,
                }
            }))
        })
        .map_err(|error| format!("could not query Chapolera tags: {error}"))?;
    rows.collect::<Result<Vec<_>, _>>()
        .map_err(|error| format!("could not read Chapolera tags: {error}"))
}

fn profile_with_database(path: &Path, database_path: &Path) -> Result<String, String> {
    let connection = open_database(database_path)?;
    let asset: (i64, String, String, i64, String, String, String, String) = connection
        .query_row(
            "SELECT id, path, name, size_bytes, mime_type, format, media_family, sha256
             FROM assets WHERE path_key = ?1 AND present = 1",
            [path.as_os_str().as_bytes()],
            |row| {
                Ok((
                    row.get(0)?,
                    row.get(1)?,
                    row.get(2)?,
                    row.get(3)?,
                    row.get(4)?,
                    row.get(5)?,
                    row.get(6)?,
                    row.get(7)?,
                ))
            },
        )
        .optional()
        .map_err(|error| format!("could not read Chapolera asset profile: {error}"))?
        .ok_or_else(|| format!("{} is not present in the Chapolera index", path.display()))?;
    let (asset_id, path, name, size, mime_type, format, media_family, content_sha256) = asset;
    let tags = load_asset_semantic_tags(&connection, asset_id, &content_sha256)?;

    let mut fact_statement = connection
        .prepare(
            "SELECT fact_key, value_json, extractor_id, extractor_version, extracted_at
             FROM asset_facts AS facts
             WHERE asset_id = ?1 AND content_sha256 = ?2
               AND EXISTS (
                   SELECT 1 FROM extractor_runs AS runs
                   WHERE runs.asset_id = facts.asset_id
                     AND runs.extractor_id = facts.extractor_id
                     AND runs.extractor_version = facts.extractor_version
                     AND runs.content_sha256 = facts.content_sha256
                     AND runs.status = 'success'
               )
             ORDER BY fact_key, extractor_id",
        )
        .map_err(|error| format!("could not prepare Chapolera fact query: {error}"))?;
    let fact_rows = fact_statement
        .query_map(params![asset_id, content_sha256], |row| {
            Ok((
                row.get::<_, String>(0)?,
                row.get::<_, String>(1)?,
                row.get::<_, String>(2)?,
                row.get::<_, String>(3)?,
                row.get::<_, i64>(4)?,
            ))
        })
        .map_err(|error| format!("could not query Chapolera facts: {error}"))?;
    let mut facts = Vec::new();
    for row in fact_rows {
        let (key, value, extractor, version, extracted_at) =
            row.map_err(|error| format!("could not read Chapolera fact: {error}"))?;
        facts.push(serde_json::json!({
            "key": key,
            "value": serde_json::from_str::<serde_json::Value>(&value)
                .map_err(|error| format!("stored fact {key} is invalid JSON: {error}"))?,
            "provenance": {
                "extractor": extractor,
                "version": version,
                "content_sha256": content_sha256,
                "extracted_at": extracted_at,
            }
        }));
    }

    let mut run_statement = connection
        .prepare(
            "SELECT extractor_id, extractor_version, status, error_message, updated_at
             FROM extractor_runs WHERE asset_id = ?1 ORDER BY extractor_id",
        )
        .map_err(|error| format!("could not prepare Chapolera extractor query: {error}"))?;
    let runs = run_statement
        .query_map([asset_id], |row| {
            Ok(serde_json::json!({
                "extractor": row.get::<_, String>(0)?,
                "version": row.get::<_, String>(1)?,
                "status": row.get::<_, String>(2)?,
                "error": row.get::<_, Option<String>>(3)?,
                "updated_at": row.get::<_, i64>(4)?,
            }))
        })
        .map_err(|error| format!("could not query Chapolera extractor results: {error}"))?
        .collect::<Result<Vec<_>, _>>()
        .map_err(|error| format!("could not read Chapolera extractor results: {error}"))?;
    serde_json::to_string(&serde_json::json!({
        "schema_version": 2,
        "asset_id": asset_id,
        "path": path,
        "name": name,
        "size_bytes": size,
        "mime_type": mime_type,
        "format": format,
        "media_family": media_family,
        "sha256": content_sha256,
        "facts": facts,
        "tags": tags,
        "extractors": runs,
    }))
    .map_err(|error| format!("could not serialize Chapolera asset profile: {error}"))
}

fn load_asset_semantic_tags(
    connection: &Connection,
    asset_id: i64,
    content_sha256: &str,
) -> Result<Vec<serde_json::Value>, String> {
    let run_ids = {
        let mut statement = connection
            .prepare(
                "SELECT id FROM semantic_runs
                 WHERE asset_id = ?1 AND content_sha256 = ?2 AND status = 'success'
                 ORDER BY analyzer_id, model_id, model_version, task_version, locality",
            )
            .map_err(|error| format!("could not prepare Chapolera semantic run query: {error}"))?;
        let rows = statement
            .query_map(params![asset_id, content_sha256], |row| row.get::<_, i64>(0))
            .map_err(|error| format!("could not query Chapolera semantic runs: {error}"))?;
        rows.collect::<Result<Vec<_>, _>>()
            .map_err(|error| format!("could not read Chapolera semantic runs: {error}"))?
    };
    let mut tags = Vec::new();
    for run_id in run_ids {
        tags.extend(load_semantic_tags(connection, run_id)?);
    }
    Ok(tags)
}

fn default_database_path() -> Result<PathBuf, String> {
    let data_home = match std::env::var_os("XDG_DATA_HOME") {
        Some(path) if !path.is_empty() => PathBuf::from(path),
        _ => PathBuf::from(std::env::var_os("HOME").ok_or("HOME is not set")?).join(".local/share"),
    };
    Ok(data_home.join("latteos").join("chapolera").join("assets.sqlite3"))
}

fn open_database(path: &Path) -> Result<Connection, String> {
    let parent = path.parent().filter(|parent| !parent.as_os_str().is_empty()).unwrap_or(Path::new("."));
    fs::create_dir_all(parent).map_err(|error| format!("{}: {error}", parent.display()))?;
    let connection = Connection::open(path).map_err(|error| format!("{}: {error}", path.display()))?;
    connection
        .busy_timeout(std::time::Duration::from_secs(5))
        .map_err(|error| format!("{}: {error}", path.display()))?;
    connection
        .execute_batch("PRAGMA foreign_keys = ON; PRAGMA journal_mode = WAL;")
        .map_err(|error| format!("{}: {error}", path.display()))?;
    initialize_schema(&connection, path)?;
    Ok(connection)
}

fn initialize_schema(connection: &Connection, path: &Path) -> Result<(), String> {
    let mut version: i64 = connection
        .query_row("PRAGMA user_version", [], |row| row.get(0))
        .map_err(|error| format!("{}: {error}", path.display()))?;
    if version == SCHEMA_VERSION {
        return Ok(());
    }
    if version < 0 || version > SCHEMA_VERSION {
        return Err(format!("{}: unsupported Chapolera schema version {version}", path.display()));
    }
    if version == 0 {
        connection
            .execute_batch(
            "BEGIN IMMEDIATE;
             CREATE TABLE roots (
                 id INTEGER PRIMARY KEY,
                 root_key BLOB NOT NULL UNIQUE,
                 root_path TEXT NOT NULL,
                 last_scanned_at INTEGER
             );
             CREATE TABLE assets (
                 id INTEGER PRIMARY KEY,
                 root_id INTEGER NOT NULL REFERENCES roots(id) ON DELETE CASCADE,
                 path_key BLOB NOT NULL,
                 path TEXT NOT NULL,
                 original_name BLOB NOT NULL,
                 name TEXT NOT NULL,
                 size_bytes INTEGER NOT NULL,
                 modified_seconds INTEGER NOT NULL,
                 modified_nanoseconds INTEGER NOT NULL,
                 changed_seconds INTEGER NOT NULL,
                 changed_nanoseconds INTEGER NOT NULL,
                 device INTEGER NOT NULL,
                 inode INTEGER NOT NULL,
                 mime_type TEXT NOT NULL,
                 format TEXT NOT NULL,
                 media_family TEXT NOT NULL,
                 sha256 TEXT NOT NULL,
                 present INTEGER NOT NULL CHECK (present IN (0, 1)),
                 scan_order INTEGER NOT NULL,
                 first_seen_at INTEGER NOT NULL,
                 last_seen_at INTEGER NOT NULL
             );
             CREATE UNIQUE INDEX assets_root_active_path
                 ON assets(root_id, path_key) WHERE present = 1;
             CREATE INDEX assets_root_present ON assets(root_id, present);
             CREATE INDEX assets_sha256 ON assets(sha256);
             PRAGMA user_version = 1;
             COMMIT;",
            )
            .map_err(|error| format!("could not initialize Chapolera database {}: {error}", path.display()))?;
        version = 1;
    }
    if version == 1 {
        connection
            .execute_batch(
                "BEGIN IMMEDIATE;
                 CREATE TABLE asset_facts (
                     asset_id INTEGER NOT NULL REFERENCES assets(id) ON DELETE CASCADE,
                     fact_key TEXT NOT NULL,
                     value_json TEXT NOT NULL,
                     extractor_id TEXT NOT NULL,
                     extractor_version TEXT NOT NULL,
                     content_sha256 TEXT NOT NULL,
                     extracted_at INTEGER NOT NULL,
                     PRIMARY KEY (asset_id, fact_key, extractor_id, extractor_version, content_sha256)
                 );
                 CREATE INDEX asset_facts_current ON asset_facts(asset_id, content_sha256);
                 CREATE TABLE extractor_runs (
                     asset_id INTEGER NOT NULL REFERENCES assets(id) ON DELETE CASCADE,
                     extractor_id TEXT NOT NULL,
                     extractor_version TEXT NOT NULL,
                     content_sha256 TEXT NOT NULL,
                     status TEXT NOT NULL CHECK (status IN ('success', 'failed')),
                     error_message TEXT,
                     updated_at INTEGER NOT NULL,
                     PRIMARY KEY (asset_id, extractor_id)
                 );
                 PRAGMA user_version = 2;
                 COMMIT;",
            )
            .map_err(|error| format!("could not upgrade Chapolera database {}: {error}", path.display()))?;
        version = 2;
    }
    if version == 2 {
        connection
            .execute_batch(
                "BEGIN IMMEDIATE;
                 CREATE TABLE tags (
                     id INTEGER PRIMARY KEY,
                     normalized_label TEXT NOT NULL UNIQUE,
                     display_label TEXT NOT NULL
                 );
                 CREATE TABLE semantic_runs (
                     id INTEGER PRIMARY KEY,
                     asset_id INTEGER NOT NULL REFERENCES assets(id) ON DELETE CASCADE,
                     analyzer_id TEXT NOT NULL,
                     model_id TEXT NOT NULL,
                     model_version TEXT NOT NULL,
                     task_version TEXT NOT NULL,
                     locality TEXT NOT NULL CHECK (locality IN ('local', 'cloud')),
                     content_sha256 TEXT NOT NULL,
                     status TEXT NOT NULL CHECK (status IN ('success', 'failed')),
                     error_message TEXT,
                     updated_at INTEGER NOT NULL,
                     UNIQUE (
                         asset_id, analyzer_id, model_id, model_version,
                         task_version, locality, content_sha256
                     )
                 );
                 CREATE INDEX semantic_runs_current ON semantic_runs(asset_id, content_sha256);
                 CREATE TABLE asset_tags (
                     semantic_run_id INTEGER NOT NULL REFERENCES semantic_runs(id) ON DELETE CASCADE,
                     tag_id INTEGER NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
                     confidence REAL NOT NULL CHECK (confidence >= 0 AND confidence <= 1),
                     source TEXT NOT NULL,
                     created_at INTEGER NOT NULL,
                     PRIMARY KEY (semantic_run_id, tag_id, source)
                 );
                 CREATE INDEX asset_tags_tag ON asset_tags(tag_id);
                 PRAGMA user_version = 3;
                 COMMIT;",
            )
            .map_err(|error| format!("could not add Chapolera semantic tags to {}: {error}", path.display()))?;
        version = 3;
    }
    if version == 3 {
        connection
            .execute_batch(
                "BEGIN IMMEDIATE;
                 CREATE TABLE plans (
                     id INTEGER PRIMARY KEY,
                     root_id INTEGER NOT NULL REFERENCES roots(id) ON DELETE CASCADE,
                     created_at INTEGER NOT NULL,
                     applied_at INTEGER,
                     status TEXT NOT NULL CHECK (status IN ('proposed', 'applying', 'applied', 'undone', 'cancelled'))
                 );
                 CREATE TABLE plan_moves (
                     plan_id INTEGER NOT NULL REFERENCES plans(id) ON DELETE CASCADE,
                     asset_id INTEGER NOT NULL REFERENCES assets(id) ON DELETE CASCADE,
                     from_path BLOB NOT NULL,
                     to_path BLOB NOT NULL,
                     category TEXT NOT NULL,
                     confidence REAL NOT NULL,
                     sha256 TEXT NOT NULL,
                     status TEXT NOT NULL CHECK (status IN ('pending', 'moving', 'done', 'failed', 'undone', 'conflict')),
                     error_message TEXT,
                     PRIMARY KEY (plan_id, asset_id)
                 );
                 PRAGMA user_version = 4;
                 COMMIT;",
            )
            .map_err(|error| format!("could not add Chapolera plans to {}: {error}", path.display()))?;
        version = 4;
    }
    if version == 4 {
        connection
            .execute_batch(
                "BEGIN IMMEDIATE;
                 CREATE TABLE image_embeddings (
                     content_sha256 TEXT NOT NULL,
                     model_version TEXT NOT NULL,
                     vector BLOB NOT NULL,
                     created_at INTEGER NOT NULL,
                     PRIMARY KEY (content_sha256, model_version)
                 );
                 PRAGMA user_version = 5;
                 COMMIT;",
            )
            .map_err(|error| format!("could not add Chapolera embeddings to {}: {error}", path.display()))?;
    }
    Ok(())
}

fn load_asset_at_path(
    transaction: &Transaction<'_>,
    root_id: i64,
    path_key: &[u8],
) -> Result<Option<ExistingAsset>, String> {
    transaction
        .query_row(
            "SELECT assets.id, size_bytes, modified_seconds, modified_nanoseconds,
                    changed_seconds, changed_nanoseconds, device, inode, sha256, mime_type,
                    media_family,
                    EXISTS (SELECT 1 FROM previous_assets WHERE asset_id = assets.id)
             FROM assets
             WHERE root_id = ?1 AND path_key = ?2
             ORDER BY EXISTS (SELECT 1 FROM previous_assets WHERE asset_id = assets.id) DESC,
                      last_seen_at DESC, id DESC
             LIMIT 1",
            params![root_id, path_key],
            |row| {
                Ok(ExistingAsset {
                    id: row.get(0)?,
                    metadata: FileFingerprint {
                        size: row.get(1)?,
                        modified_seconds: row.get(2)?,
                        modified_nanoseconds: row.get(3)?,
                        changed_seconds: row.get(4)?,
                        changed_nanoseconds: row.get(5)?,
                        device: row.get(6)?,
                        inode: row.get(7)?,
                    },
                    sha256: row.get(8)?,
                    mime_type: row.get(9)?,
                    media_family: row.get(10)?,
                    was_present: row.get(11)?,
                })
            },
        )
        .optional()
        .map_err(|error| format!("could not inspect Chapolera asset: {error}"))
}

fn persist_extractions(
    transaction: &Transaction<'_>,
    asset_id: i64,
    path: &Path,
    content_sha256: &str,
    mime_type: &str,
    media_family: &str,
    file_name: &str,
    tools: &mut ToolVersions,
    now: i64,
) -> Result<(), String> {
    if QUICK_SCAN.load(std::sync::atomic::Ordering::Relaxed) {
        return Ok(());
    }
    for extractor_id in extractors::applicable(media_family, mime_type) {
        let version = extractors::current_version(extractor_id, tools);
        let (version_name, run) = match version {
            Ok(version) if extractor_run_is_current(transaction, asset_id, extractor_id, &version, content_sha256)? => {
                continue;
            }
            Ok(version) => {
                let run = extractors::run(extractor_id, &version, path, media_family);
                (version, run)
            }
            Err(error) => {
                let version = "unavailable".to_string();
                let run = ExtractorRun {
                    id: extractor_id,
                    version: version.clone(),
                    status: "failed",
                    error: Some(error),
                    facts: Vec::new(),
                };
                (version, run)
            }
        };
        let run = if run.version == version_name {
            run
        } else {
            ExtractorRun {
                id: extractor_id,
                version: version_name,
                status: "failed",
                error: Some(format!("could not determine {extractor_id} version")),
                facts: Vec::new(),
            }
        };
        store_run_with_facts(transaction, asset_id, content_sha256, &run, file_name, now)?;
    }
    Ok(())
}

fn store_run_with_facts(
    transaction: &Transaction<'_>,
    asset_id: i64,
    content_sha256: &str,
    run: &ExtractorRun,
    file_name: &str,
    now: i64,
) -> Result<(), String> {
        store_extractor_run(transaction, asset_id, content_sha256, run, now)?;
        for fact in &run.facts {
            let value = serde_json::to_string(&fact.value)
                .map_err(|error| format!("could not serialize {} fact: {error}", fact.key))?;
            transaction
                .execute(
                    "INSERT INTO asset_facts (
                        asset_id, fact_key, value_json, extractor_id,
                        extractor_version, content_sha256, extracted_at
                     ) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7)
                     ON CONFLICT(asset_id, fact_key, extractor_id, extractor_version, content_sha256)
                     DO UPDATE SET value_json = excluded.value_json, extracted_at = excluded.extracted_at",
                    params![asset_id, fact.key, value, run.id, run.version, content_sha256, now],
                )
                .map_err(|error| format!("could not save {} fact for {}: {error}", fact.key, file_name))?;
        }
    Ok(())
}

fn extractor_run_is_current(
    transaction: &Transaction<'_>,
    asset_id: i64,
    extractor_id: &str,
    extractor_version: &str,
    content_sha256: &str,
) -> Result<bool, String> {
    transaction
        .query_row(
            "SELECT EXISTS (
                SELECT 1 FROM extractor_runs
                WHERE asset_id = ?1 AND extractor_id = ?2
                    AND extractor_version = ?3 AND content_sha256 = ?4
             )",
            params![asset_id, extractor_id, extractor_version, content_sha256],
            |row| row.get(0),
        )
        .map_err(|error| format!("could not check cached {extractor_id} result: {error}"))
}

fn store_extractor_run(
    transaction: &Transaction<'_>,
    asset_id: i64,
    content_sha256: &str,
    run: &ExtractorRun,
    now: i64,
) -> Result<(), String> {
    transaction
        .execute(
            "INSERT INTO extractor_runs (
                asset_id, extractor_id, extractor_version, content_sha256,
                status, error_message, updated_at
             ) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7)
             ON CONFLICT(asset_id, extractor_id) DO UPDATE SET
                extractor_version = excluded.extractor_version,
                content_sha256 = excluded.content_sha256,
                status = excluded.status,
                error_message = excluded.error_message,
                updated_at = excluded.updated_at",
            params![
                asset_id,
                run.id,
                run.version,
                content_sha256,
                run.status,
                run.error,
                now,
            ],
        )
        .map_err(|error| format!("could not save {} extractor result: {error}", run.id))?;
    Ok(())
}

fn update_asset(
    transaction: &Transaction<'_>,
    asset_id: i64,
    root_id: i64,
    file: &DiscoveredFile,
    mime_type: &str,
    format: &str,
    media_family: &str,
    sha256: &str,
    now: i64,
) -> Result<(), String> {
    transaction
        .execute(
            "UPDATE assets SET
                root_id = ?1, path_key = ?2, path = ?3, original_name = ?4, name = ?5,
                size_bytes = ?6, modified_seconds = ?7, modified_nanoseconds = ?8,
                changed_seconds = ?9, changed_nanoseconds = ?10, device = ?11, inode = ?12,
                mime_type = ?13, format = ?14, media_family = ?15, sha256 = ?16,
                present = 1, scan_order = ?17, last_seen_at = ?18
             WHERE id = ?19",
            params![
                root_id,
                file.path_key,
                file.path_display,
                file.name_key,
                file.name,
                file.metadata.size,
                file.metadata.modified_seconds,
                file.metadata.modified_nanoseconds,
                file.metadata.changed_seconds,
                file.metadata.changed_nanoseconds,
                file.metadata.device,
                file.metadata.inode,
                mime_type,
                format,
                media_family,
                sha256,
                file.scan_order,
                now,
                asset_id,
            ],
        )
        .map_err(|error| format!("could not update Chapolera asset {asset_id}: {error}"))?;
    Ok(())
}

fn reusable_asset_id(
    transaction: &Transaction<'_>,
    root_id: i64,
    new_path: &Path,
    sha256: &str,
) -> Result<Option<i64>, String> {
    let mut statement = transaction
        .prepare("SELECT id, path_key FROM assets WHERE root_id = ?1 AND sha256 = ?2 AND present = 0")
        .map_err(|error| format!("could not prepare Chapolera rename lookup: {error}"))?;
    let rows = statement
        .query_map(params![root_id, sha256], |row| Ok((row.get::<_, i64>(0)?, row.get::<_, Vec<u8>>(1)?)))
        .map_err(|error| format!("could not query Chapolera rename candidates: {error}"))?;
    let mut candidate = None;
    for row in rows {
        let (asset_id, path_key) = row.map_err(|error| format!("could not read Chapolera rename candidate: {error}"))?;
        let old_path = PathBuf::from(OsStr::from_bytes(&path_key));
        if old_path == new_path || old_path.exists() {
            continue;
        }
        if candidate.replace(asset_id).is_some() {
            return Ok(None);
        }
    }
    Ok(candidate)
}

fn visit_files(
    root: &Path,
    visitor: &mut impl FnMut(DiscoveredFile) -> Result<(), String>,
) -> Result<usize, String> {
    let mut scan_order = 0_i64;
    walk_visible_files(root, &mut |path| {
        let metadata = fs::symlink_metadata(path).map_err(|error| format!("{}: {error}", path.display()))?;
        if !metadata.is_file() {
            return Ok(());
        }
        let name_key = path.file_name().unwrap_or_default();
        let name = name_key.to_string_lossy().into_owned();
        visitor(DiscoveredFile {
            path_key: path.as_os_str().as_bytes().to_vec(),
            name_key: name_key.as_bytes().to_vec(),
            name,
            path_display: path.to_string_lossy().into_owned(),
            metadata: FileFingerprint::from_metadata(&metadata, path)?,
            path: path.to_path_buf(),
            scan_order,
        })?;
        scan_order = scan_order.checked_add(1).ok_or("too many files to index")?;
        Ok(())
    })
}

fn detect_type(path: &Path, name: &str) -> Result<(String, String, String), String> {
    let detected = detect_signature(path)?;
    let (mime_type, format) = detected
        .map(|kind| (kind.mime_type, kind.extension))
        .unwrap_or_else(|| ("application/octet-stream".to_string(), String::new()));
    let media_family = match mime_type.split('/').next() {
        Some("image") => "photo",
        Some("video") => "video",
        Some("audio") => "audio",
        _ if mime_type == "application/octet-stream" => crate::kind(name),
        _ => "other",
    };
    Ok((mime_type, format, media_family.to_string()))
}

fn add_family_count(counts: &mut Counts, family: &str) {
    match family {
        "photo" => counts.photos += 1,
        "video" => counts.videos += 1,
        "audio" => counts.audio += 1,
        _ => counts.other += 1,
    }
}

fn load_previews(
    transaction: &Transaction<'_>,
    root_id: i64,
    limit: i64,
    offset: i64,
) -> Result<Vec<FileEntry>, String> {
    let mut statement = transaction
        .prepare(
            "SELECT name, path, media_family FROM assets
             WHERE root_id = ?1 AND present = 1
             ORDER BY scan_order LIMIT ?2 OFFSET ?3",
        )
        .map_err(|error| format!("could not prepare Chapolera preview query: {error}"))?;
    let rows = statement
        .query_map(params![root_id, limit, offset], |row| {
            Ok(FileEntry {
                name: row.get(0)?,
                path: row.get(1)?,
                kind: match row.get::<_, String>(2)?.as_str() {
                    "photo" => "photo",
                    "video" => "video",
                    "audio" => "audio",
                    _ => "other",
                },
            })
        })
        .map_err(|error| format!("could not query Chapolera previews: {error}"))?;
    rows.collect::<Result<Vec<_>, _>>()
        .map_err(|error| format!("could not read Chapolera previews: {error}"))
}

fn unix_seconds() -> Result<i64, String> {
    let duration = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map_err(|error| format!("system clock is before UNIX epoch: {error}"))?;
    i64::try_from(duration.as_secs()).map_err(|_| "system time is out of range".to_string())
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::fs::{create_dir_all, remove_file, write};
    use std::io::Cursor;

    fn test_paths(label: &str) -> (PathBuf, PathBuf) {
        let suffix = format!("{label}-{}", std::process::id());
        let root = std::env::temp_dir().join(format!("chapolera-store-{suffix}"));
        let database = std::env::temp_dir().join(format!("chapolera-store-{suffix}.sqlite3"));
        let _ = fs::remove_dir_all(&root);
        let _ = remove_file(&database);
        let _ = remove_file(database.with_extension("sqlite3-wal"));
        let _ = remove_file(database.with_extension("sqlite3-shm"));
        create_dir_all(&root).unwrap();
        (root, database)
    }

    fn png_bytes(payload: &[u8]) -> Vec<u8> {
        [b"\x89PNG\r\n\x1a\n".as_slice(), payload].concat()
    }

    fn valid_png_bytes(width: u32, height: u32) -> Vec<u8> {
        let image = image::DynamicImage::ImageRgba8(image::RgbaImage::new(width, height));
        let mut output = Cursor::new(Vec::new());
        image.write_to(&mut output, image::ImageFormat::Png).unwrap();
        output.into_inner()
    }

    fn read_asset(database: &Path, root: &Path) -> (i64, String, String, bool) {
        let connection = open_database(database).unwrap();
        connection
            .query_row(
                "SELECT assets.id, sha256, path, present FROM assets
                 JOIN roots ON roots.id = assets.root_id WHERE roots.root_key = ?1",
                [root.as_os_str().as_bytes()],
                |row| Ok((row.get(0)?, row.get(1)?, row.get(2)?, row.get(3)?)),
            )
            .unwrap()
    }

    fn cleanup(root: &Path, database: &Path) {
        fs::remove_dir_all(root).unwrap();
        let _ = remove_file(database);
        let _ = remove_file(database.with_extension("sqlite3-wal"));
        let _ = remove_file(database.with_extension("sqlite3-shm"));
    }

    #[test]
    fn reuses_unchanged_assets_and_paginates_in_scan_order() {
        let (root, database) = test_paths("pages");
        for index in 0..10 {
            write(root.join(format!("image-{index}.png")), png_bytes(&[index])).unwrap();
        }

        let (counts, first) = scan_with_database(&root, 8, 0, &database).unwrap();
        let (_, second) = scan_with_database(&root, 8, 8, &database).unwrap();
        assert_eq!(counts.total, 10);
        assert_eq!(first.len(), 8);
        assert_eq!(second.len(), 2);
        let connection = open_database(&database).unwrap();
        let assets: i64 = connection.query_row("SELECT count(*) FROM assets", [], |row| row.get(0)).unwrap();
        let present: i64 = connection.query_row("SELECT count(*) FROM assets WHERE present = 1", [], |row| row.get(0)).unwrap();
        assert_eq!((assets, present), (10, 10));
        drop(connection);
        cleanup(&root, &database);
    }

    #[test]
    fn detects_image_signature_and_keeps_identity_after_rename() {
        let (root, database) = test_paths("rename");
        let original = root.join("first.bin");
        write(&original, png_bytes(b"photo")).unwrap();
        let (counts, files) = scan_with_database(&root, 8, 0, &database).unwrap();
        assert_eq!(counts.photos, 1);
        assert_eq!(files[0].kind, "photo");
        let before = read_asset(&database, &root);

        let renamed = root.join("renamed.dat");
        fs::rename(&original, &renamed).unwrap();
        scan_with_database(&root, 8, 0, &database).unwrap();
        let after = read_asset(&database, &root);
        assert_eq!(before.0, after.0);
        assert_eq!(before.1, after.1);
        assert_eq!(after.2, renamed.to_string_lossy());
        assert!(after.3);
        cleanup(&root, &database);
    }

    #[test]
    fn marks_missing_assets_without_deleting_them() {
        let (root, database) = test_paths("missing");
        let path = root.join("photo.png");
        write(&path, png_bytes(b"photo")).unwrap();
        scan_with_database(&root, 8, 0, &database).unwrap();
        fs::remove_file(path).unwrap();

        let (counts, files) = scan_with_database(&root, 8, 0, &database).unwrap();
        assert_eq!(counts.total, 0);
        assert!(files.is_empty());
        let asset = read_asset(&database, &root);
        assert!(!asset.3);
        let connection = open_database(&database).unwrap();
        let assets: i64 = connection.query_row("SELECT count(*) FROM assets", [], |row| row.get(0)).unwrap();
        assert_eq!(assets, 1);
        drop(connection);
        cleanup(&root, &database);
    }

    #[test]
    fn updates_hash_when_file_content_changes() {
        let (root, database) = test_paths("changed");
        let path = root.join("photo.png");
        write(&path, png_bytes(b"old")).unwrap();
        scan_with_database(&root, 8, 0, &database).unwrap();
        let before = read_asset(&database, &root);
        write(&path, png_bytes(b"new content")).unwrap();
        scan_with_database(&root, 8, 0, &database).unwrap();
        let after = read_asset(&database, &root);
        assert_eq!(before.0, after.0);
        assert_ne!(before.1, after.1);
        cleanup(&root, &database);
    }

    #[test]
    fn stores_typed_image_facts_with_content_provenance() {
        let (root, database) = test_paths("facts");
        let path = root.join("image.bin");
        write(&path, valid_png_bytes(2, 3)).unwrap();
        scan_with_database(&root, 8, 0, &database).unwrap();

        let profile: serde_json::Value =
            serde_json::from_str(&profile_with_database(&path, &database).unwrap()).unwrap();
        assert_eq!(profile["mime_type"], "image/png");
        assert!(profile["facts"].as_array().unwrap().iter().any(|fact| {
            fact["key"] == "image.width"
                && fact["provenance"]["extractor"] == "image-header"
                && fact["value"] == 2
                && fact["provenance"]["content_sha256"] == profile["sha256"]
        }));
        assert!(profile["facts"].as_array().unwrap().iter().any(|fact| {
            fact["key"] == "image.height"
                && fact["provenance"]["extractor"] == "image-header"
                && fact["value"] == 3
        }));
        assert!(profile["extractors"].as_array().unwrap().iter().any(|run| {
            run["extractor"] == "image-header" && run["status"] == "success"
        }));
        cleanup(&root, &database);
    }

    #[test]
    fn stores_semantic_tags_with_provenance_and_invalidates_cache_after_content_change() {
        let (root, database) = test_paths("semantic-tags");
        let path = root.join("image.bin");
        write(&path, valid_png_bytes(2, 3)).unwrap();
        scan_with_database(&root, 8, 0, &database).unwrap();
        let tags = r#"[{"label":"  Family   gathering ","confidence":0.93,"source":"vision"},
                       {"label":"outdoors","confidence":0.81,"source":"vision"}]"#;

        let stored = store_semantic_tags_with_database(
            &path,
            "chapolera-vision",
            "siglip2-base",
            "1",
            "photo-tags-v1",
            "local",
            tags,
            &database,
        )
        .unwrap();
        let stored: serde_json::Value = serde_json::from_str(&stored).unwrap();
        assert_eq!(stored["stored"], 2);

        let cache: serde_json::Value = serde_json::from_str(
            &semantic_tag_cache_with_database(
                &path,
                "chapolera-vision",
                "siglip2-base",
                "1",
                "photo-tags-v1",
                "local",
                &database,
            )
            .unwrap(),
        )
        .unwrap();
        assert_eq!(cache["cached"], true);
        assert_eq!(cache["tags"].as_array().unwrap().len(), 2);
        assert_eq!(cache["tags"][0]["normalized_label"], "family gathering");
        assert_eq!(cache["tags"][0]["provenance"]["content_sha256"], stored["content_sha256"]);
        assert_eq!(cache["tags"][0]["provenance"]["locality"], "local");
        let fast_cache: serde_json::Value = serde_json::from_str(
            &semantic_tag_cache_after_scan_with_database(
                &path,
                "chapolera-vision",
                "siglip2-base",
                "1",
                "photo-tags-v1",
                "local",
                &database,
            )
            .unwrap(),
        )
        .unwrap();
        assert_eq!(fast_cache["cached"], true);

        let profile: serde_json::Value =
            serde_json::from_str(&profile_with_database(&path, &database).unwrap()).unwrap();
        assert_eq!(profile["schema_version"], 2);
        assert_eq!(profile["tags"].as_array().unwrap().len(), 2);

        write(&path, valid_png_bytes(4, 5)).unwrap();
        assert!(semantic_tag_cache_after_scan_with_database(
            &path,
            "chapolera-vision",
            "siglip2-base",
            "1",
            "photo-tags-v1",
            "local",
            &database,
        )
        .unwrap_err()
        .contains("changed since it was scanned"));
        assert!(store_semantic_tags_with_database(
            &path,
            "chapolera-vision",
            "siglip2-base",
            "1",
            "photo-tags-v1",
            "local",
            tags,
            &database,
        )
        .unwrap_err()
        .contains("scan it again"));
        scan_with_database(&root, 8, 0, &database).unwrap();
        let cache: serde_json::Value = serde_json::from_str(
            &semantic_tag_cache_with_database(
                &path,
                "chapolera-vision",
                "siglip2-base",
                "1",
                "photo-tags-v1",
                "local",
                &database,
            )
            .unwrap(),
        )
        .unwrap();
        assert_eq!(cache["cached"], false);
        let profile: serde_json::Value =
            serde_json::from_str(&profile_with_database(&path, &database).unwrap()).unwrap();
        assert!(profile["tags"].as_array().unwrap().is_empty());
        cleanup(&root, &database);
    }

    #[test]
    fn rejects_invalid_semantic_tags_and_locality() {
        assert!(parse_semantic_tags(r#"[{"label":" ","confidence":0.5,"source":"vision"}]"#).is_err());
        assert!(parse_semantic_tags(r#"[{"label":"person","confidence":1.1,"source":"vision"}]"#).is_err());
        assert!(parse_semantic_tags(
            r#"[{"label":"Person","confidence":0.8,"source":"vision"},
                {"label":" person ","confidence":0.7,"source":"vision"}]"#
        )
        .is_err());
        let (root, database) = test_paths("bad-locality");
        let path = root.join("image.bin");
        write(&path, valid_png_bytes(2, 3)).unwrap();
        scan_with_database(&root, 8, 0, &database).unwrap();
        assert!(store_semantic_tags_with_database(
            &path,
            "chapolera-vision",
            "siglip2-base",
            "1",
            "photo-tags-v1",
            "remote",
            "[]",
            &database,
        )
        .unwrap_err()
        .contains("local' or 'cloud"));
        cleanup(&root, &database);
    }

    #[test]
    fn upgrades_existing_asset_database_to_fact_schema() {
        let (root, database) = test_paths("migration");
        let connection = Connection::open(&database).unwrap();
        connection
            .execute_batch(
                "CREATE TABLE roots (id INTEGER PRIMARY KEY);
                 CREATE TABLE assets (id INTEGER PRIMARY KEY);
                 PRAGMA user_version = 1;",
            )
            .unwrap();
        drop(connection);

        let connection = open_database(&database).unwrap();
        let version: i64 = connection.query_row("PRAGMA user_version", [], |row| row.get(0)).unwrap();
        let facts_table: i64 = connection
            .query_row(
                "SELECT count(*) FROM sqlite_master WHERE type = 'table' AND name = 'asset_facts'",
                [],
                |row| row.get(0),
            )
            .unwrap();
        let tags_table: i64 = connection
            .query_row(
                "SELECT count(*) FROM sqlite_master WHERE type = 'table' AND name = 'tags'",
                [],
                |row| row.get(0),
            )
            .unwrap();
        let run_table: i64 = connection
            .query_row(
                "SELECT count(*) FROM sqlite_master WHERE type = 'table' AND name = 'semantic_runs'",
                [],
                |row| row.get(0),
            )
            .unwrap();
        let asset_tags_table: i64 = connection
            .query_row(
                "SELECT count(*) FROM sqlite_master WHERE type = 'table' AND name = 'asset_tags'",
                [],
                |row| row.get(0),
            )
            .unwrap();
        assert_eq!(version, SCHEMA_VERSION);
        assert_eq!(facts_table, 1);
        assert_eq!(tags_table, 1);
        assert_eq!(run_table, 1);
        assert_eq!(asset_tags_table, 1);
        drop(connection);
        cleanup(&root, &database);
    }

    #[test]
    fn duplicates_group_identical_content_only() {
        let (root, database) = test_paths("dupes");
        write(root.join("a.png"), png_bytes(&[1])).unwrap();
        write(root.join("b.png"), png_bytes(&[1])).unwrap();
        write(root.join("c.png"), png_bytes(&[2])).unwrap();
        write(root.join("empty1.png"), []).unwrap();
        write(root.join("empty2.png"), []).unwrap();
        scan_with_database(&root, 8, 0, &database).unwrap();
        let report: serde_json::Value =
            serde_json::from_str(&duplicates_with_database(&root, &database).unwrap()).unwrap();
        let groups = report["groups"].as_array().unwrap();
        assert_eq!(groups.len(), 1);
        assert_eq!(groups[0]["paths"].as_array().unwrap().len(), 2);
        cleanup(&root, &database);
    }

    #[test]
    fn image_features_are_kept_by_content_and_survive_a_rename() {
        let (root, database) = test_paths("embeddings");
        write(root.join("a.png"), png_bytes(&[9])).unwrap();
        scan_with_database(&root, 8, 0, &database).unwrap();
        let path = root.join("a.png");
        assert!(load_embedding_with_database(&path, "m1", &database).is_none());
        store_embedding_with_database(&path, "m1", &[0.5, -1.25, 3.0], &database).unwrap();
        assert_eq!(load_embedding_with_database(&path, "m1", &database).unwrap(), vec![0.5, -1.25, 3.0]);
        assert!(load_embedding_with_database(&path, "m2", &database).is_none(), "another model does not reuse them");
        fs::rename(&path, root.join("b.png")).unwrap();
        scan_with_database(&root, 8, 0, &database).unwrap();
        assert_eq!(load_embedding_with_database(&root.join("b.png"), "m1", &database).unwrap().len(), 3);
        cleanup(&root, &database);
    }
}
