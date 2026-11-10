//! Taxonomy planner and journaled, reversible organizer.
//! The plan is deterministic (no generative model needed); LensAI may later only rename/merge categories.
//! Nothing moves until `apply`; a move never overwrites (hard_link fails if the target exists), and `undo`
//! restores only files whose content still matches the recorded hash.
use super::{default_database_path, open_database};
use latte_index_core::sha256_file;
use rusqlite::{params, Connection, OptionalExtension};
use std::collections::{HashMap, HashSet};
use std::fs;
use std::os::unix::ffi::{OsStrExt, OsStringExt};
use std::path::{Path, PathBuf};
use std::time::{SystemTime, UNIX_EPOCH};

const MIN_CATEGORY_SHARE: f64 = 0.05;
const MIN_CATEGORY_FILES: usize = 3;

fn now() -> i64 {
    SystemTime::now().duration_since(UNIX_EPOCH).map(|d| d.as_secs() as i64).unwrap_or(0)
}

/// Folder-safe category name: no separators or control characters, bounded length.
fn folder_name(label: &str) -> Option<String> {
    let cleaned: String = label
        .chars()
        .map(|c| if c == '/' || c == '\\' || c.is_control() { ' ' } else { c })
        .collect();
    let cleaned = cleaned.split_whitespace().collect::<Vec<_>>().join(" ");
    let cleaned: String = cleaned.chars().take(64).collect();
    let cleaned = cleaned.trim_matches('.').trim().to_string();
    (!cleaned.is_empty()).then_some(cleaned)
}

struct Candidate {
    asset_id: i64,
    path: PathBuf,
    name: std::ffi::OsString, // the real on-disk name, possibly not UTF-8
    sha256: String,
    tags: Vec<(String, f64)>, // (display label, confidence), best first
}

fn load_candidates(connection: &Connection, root: &Path) -> Result<Vec<Candidate>, String> {
    let mut statement = connection
        .prepare(
            "SELECT assets.id, assets.path_key, assets.original_name, assets.sha256, tags.display_label, max(asset_tags.confidence)
             FROM assets
             JOIN roots ON roots.id = assets.root_id
             JOIN semantic_runs ON semantic_runs.asset_id = assets.id
                  AND semantic_runs.content_sha256 = assets.sha256 AND semantic_runs.status = 'success'
             JOIN asset_tags ON asset_tags.semantic_run_id = semantic_runs.id
             JOIN tags ON tags.id = asset_tags.tag_id
             WHERE assets.present = 1 AND roots.root_key = ?1
             GROUP BY assets.id, tags.id
             ORDER BY assets.id, max(asset_tags.confidence) DESC",
        )
        .map_err(|error| format!("could not prepare plan query: {error}"))?;
    let rows = statement
        .query_map([root.as_os_str().as_bytes()], |row| {
            Ok((row.get::<_, i64>(0)?, row.get::<_, Vec<u8>>(1)?, row.get::<_, Vec<u8>>(2)?, row.get::<_, String>(3)?, row.get::<_, String>(4)?, row.get::<_, f64>(5)?))
        })
        .map_err(|error| format!("could not read plan input: {error}"))?;
    let mut candidates: Vec<Candidate> = Vec::new();
    for row in rows {
        let (asset_id, path_key, name, sha256, label, confidence) = row.map_err(|error| error.to_string())?;
        if candidates.last().map(|c| c.asset_id) != Some(asset_id) {
            candidates.push(Candidate {
                asset_id,
                path: PathBuf::from(std::ffi::OsString::from_vec(path_key)),
                name: std::ffi::OsString::from_vec(name),
                sha256,
                tags: Vec::new(),
            });
        }
        candidates.last_mut().unwrap().tags.push((label, confidence));
    }
    Ok(candidates)
}

pub(crate) fn plan(folder: &Path) -> Result<String, String> {
    let root = fs::canonicalize(folder).map_err(|error| format!("{}: {error}", folder.display()))?;
    plan_with_database(&root, &default_database_path()?)
}

pub(super) fn plan_with_database(root: &Path, database_path: &Path) -> Result<String, String> {
    let mut connection = open_database(database_path)?;
    let root_id: i64 = connection
        .query_row("SELECT id FROM roots WHERE root_key = ?1", [root.as_os_str().as_bytes()], |row| row.get(0))
        .optional()
        .map_err(|error| error.to_string())?
        .ok_or_else(|| format!("{} is not in the Chapolera index; scan it first", root.display()))?;
    // Only loose files directly in the root are moved; what the user already put in subfolders stays.
    let candidates: Vec<Candidate> = load_candidates(&connection, root)?
        .into_iter()
        .filter(|c| c.path.parent() == Some(root))
        .collect();
    if candidates.is_empty() {
        return Err("no tagged files directly in this folder; tag the photos first".to_string());
    }
    // A category is the best tag of enough files; the rest of a file's tags are tried in order, else it stays.
    let mut primary: HashMap<String, usize> = HashMap::new();
    for c in &candidates {
        *primary.entry(c.tags[0].0.clone()).or_default() += 1;
    }
    let min_files = ((candidates.len() as f64 * MIN_CATEGORY_SHARE).ceil() as usize).max(MIN_CATEGORY_FILES);
    let eligible: HashSet<&String> = primary.iter().filter(|(_, n)| **n >= min_files).map(|(l, _)| l).collect();

    // Existing subfolders are reused (case-insensitive), never duplicated.
    let mut existing: HashMap<String, String> = HashMap::new();
    if let Ok(entries) = fs::read_dir(root) {
        for entry in entries.flatten() {
            if entry.file_type().map(|t| t.is_dir()).unwrap_or(false) {
                if let Some(name) = entry.file_name().to_str() {
                    existing.insert(name.to_lowercase(), name.to_string());
                }
            }
        }
    }

    let transaction = connection.transaction().map_err(|error| error.to_string())?;
    transaction
        .execute("INSERT INTO plans (root_id, created_at, status) VALUES (?1, ?2, 'proposed')", params![root_id, now()])
        .map_err(|error| error.to_string())?;
    let plan_id = transaction.last_insert_rowid();
    let mut per_category: HashMap<String, Vec<String>> = HashMap::new();
    let (mut review, mut conflicts) = (0usize, 0usize);
    for c in &candidates {
        let Some((label, confidence)) = c.tags.iter().find(|(l, _)| eligible.contains(l)).map(|(l, f)| (l.clone(), *f)) else {
            review += 1;
            continue;
        };
        let Some(wanted) = folder_name(&label) else { review += 1; continue };
        let dir = existing.get(&wanted.to_lowercase()).cloned().unwrap_or(wanted);
        let target = root.join(&dir).join(&c.name);
        // A symlink named like the category would carry files out of the root; an existing target is never replaced.
        let dir_is_link = root.join(&dir).symlink_metadata().map(|m| m.file_type().is_symlink()).unwrap_or(false);
        let status = if dir_is_link || target.symlink_metadata().is_ok() { conflicts += 1; "conflict" } else { "pending" };
        transaction
            .execute(
                "INSERT INTO plan_moves (plan_id, asset_id, from_path, to_path, category, confidence, status, sha256)
                 VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8)",
                params![plan_id, c.asset_id, c.path.as_os_str().as_bytes(), target.as_os_str().as_bytes(), dir, confidence, status, c.sha256],
            )
            .map_err(|error| error.to_string())?;
        per_category.entry(dir).or_default().push(c.name.to_string_lossy().into_owned());
    }
    transaction.commit().map_err(|error| error.to_string())?;
    let mut categories: Vec<_> = per_category.into_iter().collect();
    categories.sort_by(|a, b| b.1.len().cmp(&a.1.len()).then(a.0.cmp(&b.0)));
    // Where each file is going, so the window can fly its tile into the right folder (capped: only a page of tiles shows).
    let mut assignments = serde_json::Map::new();
    for (index, (_, files)) in categories.iter().enumerate() {
        for name in files {
            if assignments.len() < 400 {
                assignments.insert(name.clone(), serde_json::json!(index));
            }
        }
    }
    Ok(serde_json::json!({
        "assignments": assignments,
        "plan_id": plan_id,
        "files": candidates.len(),
        "review": review,
        "conflicts": conflicts,
        "min_files": min_files,
        "categories": categories.iter().map(|(name, files)| serde_json::json!({
            "name": name, "count": files.len(), "samples": files.iter().take(12).collect::<Vec<_>>()
        })).collect::<Vec<_>>(),
    })
    .to_string())
}

pub(crate) fn apply(plan_id: i64) -> Result<String, String> {
    apply_with_database(plan_id, &default_database_path()?)
}

pub(super) fn apply_with_database(plan_id: i64, database_path: &Path) -> Result<String, String> {
    let connection = open_database(database_path)?;
    let status: String = connection
        .query_row("SELECT status FROM plans WHERE id = ?1", [plan_id], |row| row.get(0))
        .optional()
        .map_err(|error| error.to_string())?
        .ok_or_else(|| format!("plan {plan_id} does not exist"))?;
    if status != "proposed" && status != "applying" {
        return Err(format!("plan {plan_id} is {status}; only a proposed plan can be applied"));
    }
    connection.execute("UPDATE plans SET status = 'applying' WHERE id = ?1", [plan_id]).map_err(|e| e.to_string())?;
    let moves = pending_moves(&connection, plan_id, &["pending", "moving"])?;
    let (mut done, mut failed) = (0, 0);
    for (asset_id, from, to, sha256) in moves {
        // Only the file that was analysed is moved; one edited since then stays put (its tags would be wrong).
        if from.exists() && sha256_file(&from).map(|hash| hash != sha256).unwrap_or(true) {
            set_move(&connection, plan_id, asset_id, "failed", Some("file changed since it was analysed, not moved"))?;
            failed += 1;
            continue;
        }
        // Journal first: after a crash a 'moving' row is re-checked below instead of guessed.
        set_move(&connection, plan_id, asset_id, "moving", None)?;
        match move_no_clobber(&from, &to, &sha256) {
            Ok(()) => {
                connection
                    .execute(
                        "UPDATE assets SET path_key = ?1, path = ?2 WHERE id = ?3",
                        params![to.as_os_str().as_bytes(), to.to_string_lossy(), asset_id],
                    )
                    .map_err(|e| e.to_string())?;
                set_move(&connection, plan_id, asset_id, "done", None)?;
                done += 1;
            }
            Err(error) => {
                set_move(&connection, plan_id, asset_id, "failed", Some(&error))?;
                failed += 1;
            }
        }
    }
    connection.execute("UPDATE plans SET status = 'applied', applied_at = ?2 WHERE id = ?1", params![plan_id, now()]).map_err(|e| e.to_string())?;
    Ok(serde_json::json!({ "plan_id": plan_id, "moved": done, "failed": failed }).to_string())
}

pub(crate) fn undo(plan_id: i64) -> Result<String, String> {
    undo_with_database(plan_id, &default_database_path()?)
}

pub(super) fn undo_with_database(plan_id: i64, database_path: &Path) -> Result<String, String> {
    let connection = open_database(database_path)?;
    let status: String = connection
        .query_row("SELECT status FROM plans WHERE id = ?1", [plan_id], |row| row.get(0))
        .optional()
        .map_err(|error| error.to_string())?
        .ok_or_else(|| format!("plan {plan_id} does not exist"))?;
    if status != "applied" && status != "applying" {
        return Err(format!("plan {plan_id} is {status}; nothing to undo"));
    }
    let (mut restored, mut skipped) = (0, 0);
    for (asset_id, from, to, expected) in pending_moves(&connection, plan_id, &["done", "moving"])? {
        // Only restore a file that is still the one we moved; a changed or missing file is left alone.
        let verified = sha256_file(&to).map(|hash| hash == expected).unwrap_or(false);
        if !verified {
            set_move(&connection, plan_id, asset_id, "failed", Some("file changed or missing, not restored"))?;
            skipped += 1;
            continue;
        }
        match move_no_clobber(&to, &from, &expected) {
            Ok(()) => {
                connection
                    .execute(
                        "UPDATE assets SET path_key = ?1, path = ?2 WHERE id = ?3",
                        params![from.as_os_str().as_bytes(), from.to_string_lossy(), asset_id],
                    )
                    .map_err(|e| e.to_string())?;
                set_move(&connection, plan_id, asset_id, "undone", None)?;
                if let Some(dir) = to.parent() {
                    let _ = fs::remove_dir(dir); // only succeeds when empty
                }
                restored += 1;
            }
            Err(error) => {
                set_move(&connection, plan_id, asset_id, "failed", Some(&error))?;
                skipped += 1;
            }
        }
    }
    connection.execute("UPDATE plans SET status = 'undone' WHERE id = ?1", [plan_id]).map_err(|e| e.to_string())?;
    Ok(serde_json::json!({ "plan_id": plan_id, "restored": restored, "skipped": skipped }).to_string())
}

pub(crate) fn cancel(plan_id: i64) -> Result<String, String> {
    let connection = open_database(&default_database_path()?)?;
    let changed = connection
        .execute("UPDATE plans SET status = 'cancelled' WHERE id = ?1 AND status = 'proposed'", [plan_id])
        .map_err(|e| e.to_string())?;
    if changed == 0 {
        return Err(format!("plan {plan_id} is not a proposed plan"));
    }
    Ok(serde_json::json!({ "plan_id": plan_id, "cancelled": true }).to_string())
}

type Move = (i64, PathBuf, PathBuf, String);

fn pending_moves(connection: &Connection, plan_id: i64, statuses: &[&str]) -> Result<Vec<Move>, String> {
    let mut statement = connection
        .prepare("SELECT asset_id, from_path, to_path, status, sha256 FROM plan_moves WHERE plan_id = ?1 ORDER BY asset_id")
        .map_err(|e| e.to_string())?;
    let rows = statement
        .query_map([plan_id], |row| {
            Ok((row.get::<_, i64>(0)?, row.get::<_, Vec<u8>>(1)?, row.get::<_, Vec<u8>>(2)?, row.get::<_, String>(3)?, row.get::<_, String>(4)?))
        })
        .map_err(|e| e.to_string())?;
    let mut moves = Vec::new();
    for row in rows {
        let (id, from, to, status, sha256) = row.map_err(|e| e.to_string())?;
        if statuses.contains(&status.as_str()) {
            moves.push((id, PathBuf::from(std::ffi::OsString::from_vec(from)), PathBuf::from(std::ffi::OsString::from_vec(to)), sha256));
        }
    }
    Ok(moves)
}

fn set_move(connection: &Connection, plan_id: i64, asset_id: i64, status: &str, error: Option<&str>) -> Result<(), String> {
    connection
        .execute(
            "UPDATE plan_moves SET status = ?3, error_message = ?4 WHERE plan_id = ?1 AND asset_id = ?2",
            params![plan_id, asset_id, status, error],
        )
        .map(|_| ())
        .map_err(|e| e.to_string())
}

/// Atomic, never overwrites: link at the target fails if it exists; then the source name is removed.
/// Also finishes a move interrupted between link and unlink (target already is the same file).
fn move_no_clobber(from: &Path, to: &Path, sha256: &str) -> Result<(), String> {
    if let Some(dir) = to.parent() {
        fs::create_dir_all(dir).map_err(|e| format!("{}: {e}", dir.display()))?;
    }
    match fs::hard_link(from, to) {
        Ok(()) => fs::remove_file(from).map_err(|e| format!("{}: {e}", from.display())),
        Err(e) if e.kind() == std::io::ErrorKind::AlreadyExists => {
            use std::os::unix::fs::MetadataExt;
            match (fs::metadata(from), fs::metadata(to)) {
                (Ok(a), Ok(b)) if a.ino() == b.ino() && a.dev() == b.dev() => {
                    fs::remove_file(from).map_err(|e| format!("{}: {e}", from.display()))
                }
                // source already gone, target is the very content we moved: interrupted earlier
                (Err(e), Ok(_)) if e.kind() == std::io::ErrorKind::NotFound && sha256_file(to).map(|h| h == sha256).unwrap_or(false) => Ok(()),
                _ => Err(format!("{} already exists", to.display())),
            }
        }
        Err(e) => Err(format!("{}: {e}", from.display())),
    }
}

#[cfg(test)]
mod tests {
    use super::super::{scan_with_database, store_semantic_tags_with_database};
    use super::*;

    fn tagged_root(label: &str) -> (PathBuf, PathBuf) {
        let root = std::env::temp_dir().join(format!("chapolera-org-{label}-{}", std::process::id()));
        let database = root.with_extension("sqlite3");
        let _ = fs::remove_dir_all(&root);
        fs::create_dir_all(&root).unwrap();
        for i in 0..6u8 {
            let mut bytes = b"\x89PNG\r\n\x1a\n".to_vec();
            bytes.push(i);
            fs::write(root.join(format!("p{i}.png")), bytes).unwrap();
        }
        scan_with_database(&root, 8, 0, &database).unwrap();
        for i in 0..6u8 {
            let label = if i < 4 { "landscape" } else { "lonely" };
            let tags = format!(r#"[{{"label":"{label}","confidence":0.9,"source":"t"}}]"#);
            store_semantic_tags_with_database(&root.join(format!("p{i}.png")), "a", "m", "1", "1", "local", &tags, &database).unwrap();
        }
        (root, database)
    }

    #[test]
    fn plan_apply_undo_round_trip_moves_only_big_categories() {
        let (root, database) = tagged_root("round");
        let plan: serde_json::Value = serde_json::from_str(&plan_with_database(&root, &database).unwrap()).unwrap();
        assert_eq!(plan["categories"].as_array().unwrap().len(), 1);
        assert_eq!(plan["review"], 2);
        let id = plan["plan_id"].as_i64().unwrap();
        assert!(root.join("p0.png").exists(), "planning moves nothing");
        apply_with_database(id, &database).unwrap();
        assert!(!root.join("p0.png").exists() && root.join("landscape/p0.png").exists());
        assert!(root.join("p5.png").exists(), "small group stays for review");
        assert!(apply_with_database(id, &database).is_err(), "cannot apply twice");
        undo_with_database(id, &database).unwrap();
        assert!(root.join("p0.png").exists() && !root.join("landscape").exists());
        let _ = fs::remove_dir_all(&root);
    }

    #[test]
    fn existing_target_is_never_overwritten_and_changed_files_are_not_restored() {
        let (root, database) = tagged_root("clobber");
        fs::create_dir(root.join("landscape")).unwrap();
        fs::write(root.join("landscape/p0.png"), b"mine").unwrap();
        let plan: serde_json::Value = serde_json::from_str(&plan_with_database(&root, &database).unwrap()).unwrap();
        assert_eq!(plan["conflicts"], 1);
        let id = plan["plan_id"].as_i64().unwrap();
        apply_with_database(id, &database).unwrap();
        assert_eq!(fs::read(root.join("landscape/p0.png")).unwrap(), b"mine");
        assert!(root.join("p0.png").exists());
        fs::write(root.join("landscape/p1.png"), b"edited").unwrap();
        let undo: serde_json::Value = serde_json::from_str(&undo_with_database(id, &database).unwrap()).unwrap();
        assert_eq!(undo["skipped"], 1);
        assert_eq!(fs::read(root.join("landscape/p1.png")).unwrap(), b"edited");
        let _ = fs::remove_dir_all(&root);
    }

    #[test]
    fn a_file_edited_after_planning_is_not_moved() {
        let (root, database) = tagged_root("edited");
        let plan: serde_json::Value = serde_json::from_str(&plan_with_database(&root, &database).unwrap()).unwrap();
        fs::write(root.join("p0.png"), b"edited after the analysis").unwrap();
        let done: serde_json::Value =
            serde_json::from_str(&apply_with_database(plan["plan_id"].as_i64().unwrap(), &database).unwrap()).unwrap();
        assert_eq!(done["failed"], 1);
        assert_eq!(fs::read(root.join("p0.png")).unwrap(), b"edited after the analysis");
        assert!(root.join("landscape/p1.png").exists());
        let _ = fs::remove_dir_all(&root);
    }
}
