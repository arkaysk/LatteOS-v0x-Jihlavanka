use rusqlite::{params, Connection, OptionalExtension, Transaction, TransactionBehavior};
use sha2::{Digest, Sha256};
use std::ffi::OsStr;
use std::fs::{self, File};
use std::io::Read;
use std::os::unix::ffi::OsStrExt;
use std::os::unix::fs::MetadataExt;
use std::path::{Path, PathBuf};
use std::process::Command;
use std::time::{SystemTime, UNIX_EPOCH};

const SCHEMA_VERSION: i64 = 1;
const HASH_BUFFER_SIZE: usize = 1024 * 1024;

#[derive(Debug, Default, PartialEq, Eq)]
pub struct IndexSummary {
    pub scanned: u64,
    pub added: u64,
    pub updated: u64,
    pub unchanged: u64,
    pub missing: u64,
}

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

pub fn default_database_path() -> Result<PathBuf, String> {
    let state_home = match std::env::var_os("XDG_STATE_HOME") {
        Some(path) if !path.is_empty() => PathBuf::from(path),
        _ => PathBuf::from(std::env::var_os("HOME").ok_or("HOME is not set")?).join(".local/state"),
    };
    Ok(state_home.join("latteos").join("index.sqlite3"))
}

pub fn index_root(root: &Path, database_path: &Path) -> Result<IndexSummary, String> {
    let canonical_root = fs::canonicalize(root).map_err(|error| format!("{}: {error}", root.display()))?;
    if !canonical_root.is_dir() {
        return Err(format!("{}: not a folder", canonical_root.display()));
    }

    let mut connection = open_database(database_path)?;
    let transaction = connection
        .transaction_with_behavior(TransactionBehavior::Immediate)
        .map_err(|error| format!("{}: {error}", database_path.display()))?;
    let root_path = canonical_root.to_string_lossy().into_owned();
    let root_key = canonical_root.as_os_str().as_bytes();
    transaction
        .execute(
            "INSERT OR IGNORE INTO roots (root_key, root_path) VALUES (?1, ?2)",
            params![root_key, root_path],
        )
        .map_err(|error| format!("could not register index root: {error}"))?;
    let root_id: i64 = transaction
        .query_row("SELECT id FROM roots WHERE root_key = ?1", [root_key], |row| row.get(0))
        .map_err(|error| format!("could not read index root: {error}"))?;
    transaction
        .execute("UPDATE assets SET present = 0 WHERE root_id = ?1", [root_id])
        .map_err(|error| format!("could not begin index reconciliation: {error}"))?;

    let mut summary = IndexSummary::default();
    visit_visible_files(&canonical_root, &mut |path| {
        index_file(&transaction, root_id, path, &mut summary)
    })?;
    summary.missing = transaction
        .query_row(
            "SELECT count(*) FROM assets WHERE root_id = ?1 AND present = 0",
            [root_id],
            |row| row.get::<_, i64>(0),
        )
        .map_err(|error| format!("could not count missing assets: {error}"))?
        .try_into()
        .map_err(|_| "missing asset count is out of range".to_string())?;
    let indexed_at = unix_seconds()?;
    transaction
        .execute("UPDATE roots SET last_indexed_at = ?1 WHERE id = ?2", params![indexed_at, root_id])
        .map_err(|error| format!("could not finish index reconciliation: {error}"))?;
    transaction.commit().map_err(|error| format!("could not save index: {error}"))?;
    Ok(summary)
}

pub fn database_status(database_path: &Path) -> Result<serde_json::Value, String> {
    let connection = open_database(database_path)?;
    let roots: i64 = connection
        .query_row("SELECT count(*) FROM roots", [], |row| row.get(0))
        .map_err(|error| format!("could not count index roots: {error}"))?;
    let assets: i64 = connection
        .query_row("SELECT count(*) FROM assets WHERE present = 1", [], |row| row.get(0))
        .map_err(|error| format!("could not count indexed assets: {error}"))?;
    let missing: i64 = connection
        .query_row("SELECT count(*) FROM assets WHERE present = 0", [], |row| row.get(0))
        .map_err(|error| format!("could not count missing assets: {error}"))?;
    Ok(serde_json::json!({
        "database": database_path,
        "roots": roots,
        "assets": assets,
        "missing": missing,
    }))
}

fn open_database(path: &Path) -> Result<Connection, String> {
    let parent = path.parent().filter(|parent| !parent.as_os_str().is_empty()).unwrap_or(Path::new("."));
    fs::create_dir_all(parent).map_err(|error| format!("{}: {error}", parent.display()))?;
    let connection = Connection::open(path).map_err(|error| format!("{}: {error}", path.display()))?;
    connection.busy_timeout(std::time::Duration::from_secs(5))
        .map_err(|error| format!("{}: {error}", path.display()))?;
    connection.execute_batch("PRAGMA foreign_keys = ON; PRAGMA journal_mode = WAL;")
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
        return Err(format!("{}: unsupported LatteIndex schema version {version}", path.display()));
    }
    connection.execute_batch(
        "BEGIN IMMEDIATE;
         CREATE TABLE roots (
             id INTEGER PRIMARY KEY,
             root_key BLOB NOT NULL UNIQUE,
             root_path TEXT NOT NULL,
             last_indexed_at INTEGER
         );
         CREATE TABLE assets (
             id INTEGER PRIMARY KEY,
             root_id INTEGER NOT NULL REFERENCES roots(id) ON DELETE CASCADE,
             path_key BLOB NOT NULL,
             path TEXT NOT NULL,
             original_name TEXT NOT NULL,
             size_bytes INTEGER NOT NULL,
             modified_seconds INTEGER NOT NULL,
             modified_nanoseconds INTEGER NOT NULL,
             changed_seconds INTEGER NOT NULL,
             changed_nanoseconds INTEGER NOT NULL,
             device INTEGER NOT NULL,
             inode INTEGER NOT NULL,
             mime_type TEXT NOT NULL,
             media_family TEXT NOT NULL,
             sha256 TEXT NOT NULL,
             present INTEGER NOT NULL CHECK (present IN (0, 1)),
             first_seen_at INTEGER NOT NULL,
             last_seen_at INTEGER NOT NULL,
             UNIQUE (root_id, path_key)
         );
         CREATE INDEX assets_root_present ON assets(root_id, present);
         CREATE INDEX assets_sha256 ON assets(sha256);
         CREATE TABLE facts (
             asset_id INTEGER NOT NULL REFERENCES assets(id) ON DELETE CASCADE,
             fact_key TEXT NOT NULL,
             value_json TEXT NOT NULL,
             source TEXT NOT NULL,
             confidence REAL,
             extractor_id TEXT NOT NULL,
             extractor_version TEXT NOT NULL,
             content_sha256 TEXT NOT NULL,
             created_at INTEGER NOT NULL,
             PRIMARY KEY (asset_id, fact_key, source, extractor_id, extractor_version, content_sha256)
         );
         PRAGMA user_version = 1;
         COMMIT;",
    )
    .map_err(|error| format!("could not initialize LatteIndex database {}: {error}", path.display()))
}

fn visit_visible_files(root: &Path, visitor: &mut impl FnMut(&Path) -> Result<(), String>) -> Result<(), String> {
    let mut pending = vec![root.to_path_buf()];
    while let Some(directory) = pending.pop() {
        let hidden = hidden_names(&directory)?;
        let mut entries = fs::read_dir(&directory)
            .map_err(|error| format!("{}: {error}", directory.display()))?
            .collect::<Result<Vec<_>, _>>()
            .map_err(|error| format!("{}: {error}", directory.display()))?;
        entries.sort_by_key(|entry| entry.file_name());
        let mut subfolders = Vec::new();

        for entry in entries {
            let name = entry.file_name();
            if name.to_string_lossy().starts_with('.') || hidden.contains(&name.to_string_lossy().into_owned()) {
                continue;
            }
            let path = entry.path();
            let file_type = entry.file_type().map_err(|error| format!("{}: {error}", path.display()))?;
            if file_type.is_dir() {
                subfolders.push(path);
            } else if file_type.is_file() {
                visitor(&path)?;
            }
        }
        pending.extend(subfolders.into_iter().rev());
    }
    Ok(())
}

fn hidden_names(directory: &Path) -> Result<std::collections::HashSet<String>, String> {
    let path = directory.join(".hidden");
    match fs::read_to_string(&path) {
        Ok(contents) => Ok(contents.lines().map(str::to_string).collect()),
        Err(error) if error.kind() == std::io::ErrorKind::NotFound => Ok(Default::default()),
        Err(error) => Err(format!("{}: {error}", path.display())),
    }
}

fn index_file(
    transaction: &Transaction<'_>,
    root_id: i64,
    path: &Path,
    summary: &mut IndexSummary,
) -> Result<(), String> {
    let metadata = fs::symlink_metadata(path).map_err(|error| format!("{}: {error}", path.display()))?;
    if !metadata.is_file() {
        return Ok(());
    }
    let observed = file_metadata(&metadata, path)?;
    let path_key = path.as_os_str().as_bytes();
    let path_display = path.to_string_lossy().into_owned();
    let now = unix_seconds()?;
    let previous: Option<(i64, i64, i64, i64, i64, i64, i64, i64)> = transaction
        .query_row(
            "SELECT id, size_bytes, modified_seconds, modified_nanoseconds,
                    changed_seconds, changed_nanoseconds, device, inode
             FROM assets WHERE root_id = ?1 AND path_key = ?2",
            params![root_id, path_key],
            |row| Ok((
                row.get(0)?,
                row.get(1)?,
                row.get(2)?,
                row.get(3)?,
                row.get(4)?,
                row.get(5)?,
                row.get(6)?,
                row.get(7)?,
            )),
        )
        .optional()
        .map_err(|error| format!("could not inspect indexed file {}: {error}", path.display()))?;

    summary.scanned += 1;
    if let Some((asset_id, size, seconds, nanoseconds, changed_seconds, changed_nanoseconds, device, inode)) = previous {
        if size == observed.size
            && seconds == observed.modified_seconds
            && nanoseconds == observed.modified_nanoseconds
            && changed_seconds == observed.changed_seconds
            && changed_nanoseconds == observed.changed_nanoseconds
            && device == observed.device
            && inode == observed.inode
        {
            transaction
                .execute(
                    "UPDATE assets SET present = 1, last_seen_at = ?1 WHERE id = ?2",
                    params![now, asset_id],
                )
                .map_err(|error| format!("could not refresh indexed file {}: {error}", path.display()))?;
            summary.unchanged += 1;
            return Ok(());
        }
    }

    let sha256 = hash_file(path)?;
    let mime_type = detect_mime(path)?;
    let verified = fs::symlink_metadata(path).map_err(|error| format!("{}: {error}", path.display()))?;
    if !verified.is_file() || file_metadata(&verified, path)? != observed {
        return Err(format!("{}: file changed while indexing; run the scan again", path.display()));
    }
    let media_family = media_family(&mime_type);
    let original_name = path.file_name().unwrap_or_default().to_string_lossy().into_owned();
    let existing_id = match previous {
        Some((asset_id, ..)) => Some(asset_id),
        None => reusable_asset_id(transaction, root_id, path, &sha256)?,
    };
    if previous.is_none() {
        if let Some(asset_id) = existing_id {
            update_asset(
                transaction, asset_id, root_id, path_key, &path_display, &original_name,
                &observed, &mime_type, media_family, &sha256, now,
            )?;
            summary.updated += 1;
            return Ok(());
        }
    }
    if let Some((asset_id, ..)) = previous {
        update_asset(
            transaction, asset_id, root_id, path_key, &path_display, &original_name,
            &observed, &mime_type, media_family, &sha256, now,
        )?;
        summary.updated += 1;
    } else {
        transaction
            .execute(
                "INSERT INTO assets (
                    root_id, path_key, path, original_name, size_bytes, modified_seconds,
                    modified_nanoseconds, changed_seconds, changed_nanoseconds, device, inode,
                    mime_type, media_family, sha256, present, first_seen_at, last_seen_at
                 ) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11, ?12, ?13, ?14, 1, ?15, ?15)",
                params![
                    root_id, path_key, path_display, original_name, observed.size,
                    observed.modified_seconds, observed.modified_nanoseconds,
                    observed.changed_seconds, observed.changed_nanoseconds,
                    observed.device, observed.inode, mime_type, media_family, sha256, now,
                ],
            )
            .map_err(|error| format!("could not index {}: {error}", path.display()))?;
        summary.added += 1;
    }
    Ok(())
}

fn update_asset(
    transaction: &Transaction<'_>,
    asset_id: i64,
    root_id: i64,
    path_key: &[u8],
    path: &str,
    original_name: &str,
    metadata: &FileMetadata,
    mime_type: &str,
    family: &str,
    sha256: &str,
    now: i64,
) -> Result<(), String> {
    transaction
        .execute(
            "UPDATE assets SET
                root_id = ?1, path_key = ?2, path = ?3, original_name = ?4, size_bytes = ?5,
                modified_seconds = ?6, modified_nanoseconds = ?7, changed_seconds = ?8,
                changed_nanoseconds = ?9, device = ?10, inode = ?11, mime_type = ?12,
                media_family = ?13, sha256 = ?14, present = 1, last_seen_at = ?15
             WHERE id = ?16",
            params![
                root_id, path_key, path, original_name, metadata.size, metadata.modified_seconds,
                metadata.modified_nanoseconds, metadata.changed_seconds, metadata.changed_nanoseconds,
                metadata.device, metadata.inode, mime_type, family, sha256, now, asset_id,
            ],
        )
        .map_err(|error| format!("could not update indexed asset {asset_id}: {error}"))?;
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
        .map_err(|error| format!("could not find renamed assets: {error}"))?;
    let candidates = statement
        .query_map(params![root_id, sha256], |row| Ok((row.get::<_, i64>(0)?, row.get::<_, Vec<u8>>(1)?)))
        .map_err(|error| format!("could not query renamed assets: {error}"))?
        .collect::<Result<Vec<_>, _>>()
        .map_err(|error| format!("could not read renamed assets: {error}"))?;
    let new_path_key = new_path.as_os_str().as_bytes();
    let mut reusable = candidates.into_iter().filter(|(_, old_path_key)| {
        old_path_key.as_slice() != new_path_key && !PathBuf::from(OsStr::from_bytes(old_path_key)).exists()
    });
    let candidate = reusable.next().map(|(asset_id, _)| asset_id);
    if reusable.next().is_some() {
        return Ok(None);
    }
    Ok(candidate)
}

fn file_metadata(metadata: &fs::Metadata, path: &Path) -> Result<FileMetadata, String> {
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
    let mut file = File::open(path).map_err(|error| format!("{}: {error}", path.display()))?;
    let mut hasher = Sha256::new();
    let mut buffer = vec![0u8; HASH_BUFFER_SIZE];
    loop {
        let read = file.read(&mut buffer).map_err(|error| format!("{}: {error}", path.display()))?;
        if read == 0 {
            break;
        }
        hasher.update(&buffer[..read]);
    }
    Ok(format!("{:x}", hasher.finalize()))
}

fn detect_mime(path: &Path) -> Result<String, String> {
    if let Some(kind) = infer::get_from_path(path)
        .map_err(|error| format!("{}: could not read file signature: {error}", path.display()))?
    {
        return Ok(kind.mime_type().to_string());
    }
    let output = Command::new("file")
        .args(["-b", "--mime-type", "--"])
        .arg(path)
        .output()
        .map_err(|error| format!("{}: could not run MIME fallback 'file': {error}", path.display()))?;
    if !output.status.success() {
        return Err(format!(
            "{}: MIME fallback 'file' failed: {}",
            path.display(),
            String::from_utf8_lossy(&output.stderr).trim()
        ));
    }
    let mime = String::from_utf8(output.stdout)
        .map_err(|error| format!("{}: MIME detector returned invalid UTF-8: {error}", path.display()))?
        .trim()
        .to_string();
    if mime.is_empty() {
        return Err(format!("{}: MIME detector returned an empty type", path.display()));
    }
    Ok(mime)
}

fn media_family(mime: &str) -> &'static str {
    if mime.starts_with("image/") {
        "image"
    } else if mime.starts_with("video/") {
        "video"
    } else if mime.starts_with("audio/") {
        "audio"
    } else if matches!(
        mime,
        "application/javascript"
            | "application/x-shellscript"
            | "text/javascript"
            | "text/x-c"
            | "text/x-c++"
            | "text/x-go"
            | "text/x-java-source"
            | "text/x-perl"
            | "text/x-python"
            | "text/x-rust"
    ) {
        "code"
    } else if mime == "application/epub+zip" || mime == "application/x-mobipocket-ebook" {
        "ebook"
    } else if mime == "application/zip"
        || mime == "application/x-tar"
        || mime == "application/gzip"
        || mime == "application/x-bzip2"
        || mime == "application/x-7z-compressed"
        || mime == "application/x-xz"
        || mime == "application/zstd"
        || mime == "application/vnd.rar"
    {
        "archive"
    } else if mime == "application/pdf"
        || mime.starts_with("text/")
        || mime.starts_with("application/vnd.openxmlformats-officedocument.")
        || mime.starts_with("application/vnd.oasis.opendocument.")
    {
        "document"
    } else {
        "other"
    }
}

fn unix_seconds() -> Result<i64, String> {
    let seconds = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map_err(|error| format!("system clock is before Unix epoch: {error}"))?
        .as_secs();
    i64::try_from(seconds).map_err(|_| "system time is out of range".to_string())
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::fs::{create_dir_all, remove_dir_all, write};

    fn test_paths(label: &str) -> (PathBuf, PathBuf) {
        let base = std::env::temp_dir().join(format!("latte-index-{label}-{}", std::process::id()));
        let _ = remove_dir_all(&base);
        create_dir_all(&base).unwrap();
        (base.join("root"), base.join("index.sqlite3"))
    }

    fn asset(connection: &Connection, path: &Path) -> (i64, String, String, i64) {
        connection
            .query_row(
                "SELECT id, mime_type, sha256, present FROM assets WHERE path = ?1",
                [path.to_string_lossy().as_ref()],
                |row| Ok((row.get(0)?, row.get(1)?, row.get(2)?, row.get(3)?)),
            )
            .unwrap()
    }

    #[test]
    fn indexes_magic_type_and_skips_unchanged_content() {
        let (root, database) = test_paths("incremental");
        create_dir_all(&root).unwrap();
        let image = root.join("misleading.txt");
        let mut png = b"\x89PNG\r\n\x1a\n".to_vec();
        png.extend_from_slice(b"synthetic image content");
        write(&image, png).unwrap();

        let first = index_root(&root, &database).unwrap();
        assert_eq!((first.scanned, first.added, first.updated, first.unchanged), (1, 1, 0, 0));
        let connection = open_database(&database).unwrap();
        let (id, mime, hash, present) = asset(&connection, &image);
        assert_eq!(mime, "image/png");
        assert_eq!(hash, hash_file(&image).unwrap());
        assert_eq!(present, 1);

        let second = index_root(&root, &database).unwrap();
        assert_eq!((second.scanned, second.added, second.updated, second.unchanged), (1, 0, 0, 1));
        assert_eq!(asset(&connection, &image).0, id);
        assert_eq!(
            connection.query_row("PRAGMA integrity_check", [], |row| row.get::<_, String>(0)).unwrap(),
            "ok"
        );
        remove_dir_all(database.parent().unwrap()).unwrap();
    }

    #[test]
    fn changed_and_missing_files_are_reconciled_without_deleting_asset_rows() {
        let (root, database) = test_paths("changed");
        create_dir_all(&root).unwrap();
        let file = root.join("notes.txt");
        write(&file, b"first version\n").unwrap();
        index_root(&root, &database).unwrap();
        write(&file, b"second version\n").unwrap();
        let changed = index_root(&root, &database).unwrap();
        assert_eq!((changed.added, changed.updated, changed.unchanged), (0, 1, 0));
        fs::remove_file(&file).unwrap();
        let removed = index_root(&root, &database).unwrap();
        assert_eq!(removed.missing, 1);
        assert_eq!(database_status(&database).unwrap()["missing"], 1);
        remove_dir_all(database.parent().unwrap()).unwrap();
    }

    #[test]
    fn rename_keeps_asset_identity_and_identical_copy_is_a_separate_asset() {
        let (root, database) = test_paths("identity");
        create_dir_all(&root).unwrap();
        let original = root.join("original.txt");
        write(&original, b"same content\n").unwrap();
        index_root(&root, &database).unwrap();
        let connection = open_database(&database).unwrap();
        let original_id = asset(&connection, &original).0;
        let renamed = root.join("renamed.txt");
        fs::rename(&original, &renamed).unwrap();
        let renamed_summary = index_root(&root, &database).unwrap();
        assert_eq!(renamed_summary.updated, 1);
        assert_eq!(asset(&connection, &renamed).0, original_id);

        let copy = root.join("copy.txt");
        write(&copy, b"same content\n").unwrap();
        index_root(&root, &database).unwrap();
        let duplicate_count: i64 = connection
            .query_row("SELECT count(*) FROM assets WHERE sha256 = ?1", [asset(&connection, &copy).2], |row| row.get(0))
            .unwrap();
        assert_eq!(duplicate_count, 2);
        remove_dir_all(database.parent().unwrap()).unwrap();
    }

    #[test]
    fn failed_reconciliation_does_not_mark_previous_assets_missing() {
        let (root, database) = test_paths("rollback");
        create_dir_all(&root).unwrap();
        let file = root.join("kept.txt");
        write(&file, b"still here\n").unwrap();
        index_root(&root, &database).unwrap();

        let connection = open_database(&database).unwrap();
        connection.execute_batch(
            "CREATE TRIGGER reject_asset BEFORE INSERT ON assets
             BEGIN SELECT RAISE(ABORT, 'fixture failure'); END;",
        ).unwrap();
        write(root.join("new.txt"), b"new file\n").unwrap();
        assert!(index_root(&root, &database).is_err());
        assert_eq!(
            connection.query_row("SELECT count(*) FROM assets WHERE present = 1", [], |row| row.get::<_, i64>(0)).unwrap(),
            1
        );
        assert_eq!(
            connection.query_row("SELECT count(*) FROM assets WHERE present = 0", [], |row| row.get::<_, i64>(0)).unwrap(),
            0
        );
        drop(connection);
        remove_dir_all(database.parent().unwrap()).unwrap();
    }
}
