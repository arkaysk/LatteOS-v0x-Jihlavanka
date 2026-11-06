use crate::{Counts, FileEntry};
use rusqlite::{params, Connection, OptionalExtension, Transaction, TransactionBehavior};
use sha2::{Digest, Sha256};
use std::collections::HashSet;
use std::ffi::OsStr;
use std::fs::{self, Metadata};
use std::io::Read;
use std::os::unix::ffi::OsStrExt;
use std::os::unix::fs::MetadataExt;
use std::path::{Path, PathBuf};
use std::time::{SystemTime, UNIX_EPOCH};

const SCHEMA_VERSION: i64 = 1;
const HASH_BUFFER_SIZE: usize = 1024 * 1024;

#[derive(Debug, PartialEq, Eq)]
struct FileMetadata {
    size: i64,
    modified_seconds: i64,
    modified_nanoseconds: i64,
    changed_seconds: i64,
    changed_nanoseconds: i64,
    device: i64,
    inode: i64,
}

#[derive(Debug)]
struct DiscoveredFile {
    path: PathBuf,
    path_key: Vec<u8>,
    name_key: Vec<u8>,
    name: String,
    path_display: String,
    metadata: FileMetadata,
    scan_order: i64,
}

#[derive(Debug)]
struct ExistingAsset {
    id: i64,
    metadata: FileMetadata,
    media_family: String,
    was_present: bool,
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
            return Ok(());
        }

        let sha256 = hash_file(&file.path)?;
        let (mime_type, format, media_family) = detect_type(&file.path, &file.name)?;
        let verified = fs::symlink_metadata(&file.path)
            .map_err(|error| format!("{}: {error}", file.path.display()))?;
        if !verified.is_file() || file_metadata(&verified, &file.path)? != file.metadata {
            return Err(format!("{}: file changed while indexing; run the scan again", file.path.display()));
        }

        let existing_id = if let Some(asset) = previous {
            Some(asset.id)
        } else {
            reusable_asset_id(&transaction, root_id, &file.path, &sha256)?
        };
        if let Some(asset_id) = existing_id {
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
        }
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
    let version: i64 = connection
        .query_row("PRAGMA user_version", [], |row| row.get(0))
        .map_err(|error| format!("{}: {error}", path.display()))?;
    if version == SCHEMA_VERSION {
        return Ok(());
    }
    if version != 0 {
        return Err(format!("{}: unsupported Chapolera schema version {version}", path.display()));
    }
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
        .map_err(|error| format!("could not initialize Chapolera database {}: {error}", path.display()))
}

fn load_asset_at_path(
    transaction: &Transaction<'_>,
    root_id: i64,
    path_key: &[u8],
) -> Result<Option<ExistingAsset>, String> {
    transaction
        .query_row(
            "SELECT assets.id, size_bytes, modified_seconds, modified_nanoseconds,
                    changed_seconds, changed_nanoseconds, device, inode, media_family,
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
                    metadata: FileMetadata {
                        size: row.get(1)?,
                        modified_seconds: row.get(2)?,
                        modified_nanoseconds: row.get(3)?,
                        changed_seconds: row.get(4)?,
                        changed_nanoseconds: row.get(5)?,
                        device: row.get(6)?,
                        inode: row.get(7)?,
                    },
                    media_family: row.get(8)?,
                    was_present: row.get(9)?,
                })
            },
        )
        .optional()
        .map_err(|error| format!("could not inspect Chapolera asset: {error}"))
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
    let mut subfolders = 0;
    let mut scan_order = 0_i64;
    let mut pending = vec![root.to_path_buf()];

    while let Some(directory) = pending.pop() {
        let hidden = hidden_names(&directory)?;
        let mut entries = fs::read_dir(&directory)
            .map_err(|error| format!("{}: {error}", directory.display()))?
            .collect::<Result<Vec<_>, _>>()
            .map_err(|error| format!("{}: {error}", directory.display()))?;
        entries.sort_by_key(|entry| entry.file_name());
        let mut child_directories = Vec::new();

        for entry in entries {
            let name_key = entry.file_name();
            let name = name_key.to_string_lossy().into_owned();
            if name.starts_with('.') || hidden.contains(&name) {
                continue;
            }
            let path = entry.path();
            let file_type = entry.file_type().map_err(|error| format!("{}: {error}", path.display()))?;
            if file_type.is_dir() {
                subfolders += 1;
                child_directories.push(path);
            } else if file_type.is_file() {
                let metadata = fs::symlink_metadata(&path).map_err(|error| format!("{}: {error}", path.display()))?;
                if metadata.is_file() {
                    visitor(DiscoveredFile {
                        path_key: path.as_os_str().as_bytes().to_vec(),
                        name_key: name_key.as_bytes().to_vec(),
                        name,
                        path_display: path.to_string_lossy().into_owned(),
                        metadata: file_metadata(&metadata, &path)?,
                        path,
                        scan_order,
                    })?;
                    scan_order = scan_order.checked_add(1).ok_or("too many files to index")?;
                }
            }
        }
        pending.extend(child_directories.into_iter().rev());
    }
    Ok(subfolders)
}

fn hidden_names(directory: &Path) -> Result<HashSet<String>, String> {
    let path = directory.join(".hidden");
    match fs::read_to_string(&path) {
        Ok(contents) => Ok(contents.lines().map(str::to_string).collect()),
        Err(error) if error.kind() == std::io::ErrorKind::NotFound => Ok(HashSet::new()),
        Err(error) => Err(format!("{}: {error}", path.display())),
    }
}

fn file_metadata(metadata: &Metadata, path: &Path) -> Result<FileMetadata, String> {
    Ok(FileMetadata {
        size: i64::try_from(metadata.len()).map_err(|_| format!("{}: file is too large to index", path.display()))?,
        modified_seconds: metadata.mtime(),
        modified_nanoseconds: metadata.mtime_nsec(),
        changed_seconds: metadata.ctime(),
        changed_nanoseconds: metadata.ctime_nsec(),
        device: i64::try_from(metadata.dev()).map_err(|_| format!("{}: device ID is out of range", path.display()))?,
        inode: i64::try_from(metadata.ino()).map_err(|_| format!("{}: inode is out of range", path.display()))?,
    })
}

fn hash_file(path: &Path) -> Result<String, String> {
    let mut file = fs::File::open(path).map_err(|error| format!("{}: {error}", path.display()))?;
    let mut hasher = Sha256::new();
    let mut buffer = [0; HASH_BUFFER_SIZE];
    loop {
        let read = file.read(&mut buffer).map_err(|error| format!("{}: {error}", path.display()))?;
        if read == 0 {
            break;
        }
        hasher.update(&buffer[..read]);
    }
    Ok(format!("{:x}", hasher.finalize()))
}

fn detect_type(path: &Path, name: &str) -> Result<(String, String, String), String> {
    let detected = infer::get_from_path(path)
        .map_err(|error| format!("could not detect file format for {}: {error}", path.display()))?;
    let (mime_type, format) = detected
        .map(|kind| (kind.mime_type().to_string(), kind.extension().to_ascii_uppercase()))
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
}
