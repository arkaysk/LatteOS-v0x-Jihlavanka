use sha2::{Digest, Sha256};
use std::collections::HashSet;
use std::fs::{self, File, Metadata};
use std::io::Read;
use std::os::unix::fs::MetadataExt;
use std::path::Path;

const HASH_BUFFER_SIZE: usize = 1024 * 1024;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct FileFingerprint {
    pub size: i64,
    pub modified_seconds: i64,
    pub modified_nanoseconds: i64,
    pub changed_seconds: i64,
    pub changed_nanoseconds: i64,
    pub device: i64,
    pub inode: i64,
}

impl FileFingerprint {
    pub fn from_metadata(metadata: &Metadata, path: &Path) -> Result<Self, String> {
        Ok(Self {
            size: i64::try_from(metadata.len())
                .map_err(|_| format!("{}: file is too large to index", path.display()))?,
            modified_seconds: metadata.mtime(),
            modified_nanoseconds: metadata.mtime_nsec(),
            changed_seconds: metadata.ctime(),
            changed_nanoseconds: metadata.ctime_nsec(),
            device: i64::try_from(metadata.dev())
                .map_err(|_| format!("{}: device ID is out of range", path.display()))?,
            inode: i64::try_from(metadata.ino())
                .map_err(|_| format!("{}: inode is out of range", path.display()))?,
        })
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct DetectedType {
    pub mime_type: String,
    pub extension: String,
}

pub fn sha256_file(path: &Path) -> Result<String, String> {
    let mut file = File::open(path).map_err(|error| format!("{}: {error}", path.display()))?;
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

pub fn detect_signature(path: &Path) -> Result<Option<DetectedType>, String> {
    infer::get_from_path(path)
        .map(|detected| {
            detected.map(|kind| DetectedType {
                mime_type: kind.mime_type().to_string(),
                extension: kind.extension().to_ascii_uppercase(),
            })
        })
        .map_err(|error| format!("could not read file signature for {}: {error}", path.display()))
}

pub fn walk_visible_files(
    root: &Path,
    visitor: &mut impl FnMut(&Path) -> Result<(), String>,
) -> Result<usize, String> {
    let mut subfolders = 0;
    let mut pending = vec![root.to_path_buf()];
    while let Some(directory) = pending.pop() {
        let hidden = hidden_names(&directory)?;
        let mut entries = fs::read_dir(&directory)
            .map_err(|error| format!("{}: {error}", directory.display()))?
            .collect::<Result<Vec<_>, _>>()
            .map_err(|error| format!("{}: {error}", directory.display()))?;
        entries.sort_by_key(|entry| entry.file_name());
        let mut subdirectories = Vec::new();

        for entry in entries {
            let name = entry.file_name();
            let display_name = name.to_string_lossy();
            if display_name.starts_with('.') || hidden.contains(display_name.as_ref()) {
                continue;
            }
            let path = entry.path();
            let file_type = entry
                .file_type()
                .map_err(|error| format!("{}: {error}", path.display()))?;
            if file_type.is_dir() {
                subfolders += 1;
                subdirectories.push(path);
            } else if file_type.is_file() {
                visitor(&path)?;
            }
        }
        pending.extend(subdirectories.into_iter().rev());
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

#[cfg(test)]
mod tests {
    use super::*;
    use std::path::PathBuf;
    use std::sync::atomic::{AtomicU64, Ordering};

    static NEXT_TEMP_ID: AtomicU64 = AtomicU64::new(0);

    fn temp_dir() -> PathBuf {
        let id = NEXT_TEMP_ID.fetch_add(1, Ordering::Relaxed);
        std::env::temp_dir().join(format!("latte-index-core-{}-{id}", std::process::id()))
    }

    #[test]
    fn hashes_files_incrementally() {
        let directory = temp_dir();
        fs::create_dir_all(&directory).unwrap();
        let path = directory.join("sample.txt");
        fs::write(&path, "hello").unwrap();

        assert_eq!(
            sha256_file(&path).unwrap(),
            "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824"
        );

        fs::remove_dir_all(directory).unwrap();
    }

    #[test]
    fn walks_visible_files_in_sorted_depth_first_order() {
        let directory = temp_dir();
        fs::create_dir_all(directory.join("visible")).unwrap();
        fs::create_dir_all(directory.join(".private")).unwrap();
        fs::write(directory.join(".hidden"), "secret.txt\n").unwrap();
        fs::write(directory.join("secret.txt"), "hidden by config").unwrap();
        fs::write(directory.join(".private/hidden.txt"), "hidden by name").unwrap();
        fs::write(directory.join("visible/a.txt"), "visible").unwrap();

        let mut paths = Vec::new();
        let subfolders = walk_visible_files(&directory, &mut |path| {
            paths.push(path.strip_prefix(&directory).unwrap().to_path_buf());
            Ok(())
        })
        .unwrap();

        assert_eq!(subfolders, 1);
        assert_eq!(paths, [PathBuf::from("visible/a.txt")]);
        fs::remove_dir_all(directory).unwrap();
    }
}
