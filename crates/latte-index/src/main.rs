use std::path::{Path, PathBuf};

fn database_arg(args: &[String]) -> Result<(PathBuf, usize), String> {
    match args {
        [_, ..] if args.len() >= 3 && args[args.len() - 2] == "--database" => {
            Ok((PathBuf::from(&args[args.len() - 1]), args.len() - 2))
        }
        _ => Ok((latte_index::default_database_path()?, args.len())),
    }
}

fn execute(args: &[String]) -> Result<String, String> {
    let (database, command_len) = database_arg(args)?;
    match args {
        [command, root, ..] if command == "index" && command_len == 2 => {
            let summary = latte_index::index_root(Path::new(root), &database)?;
            Ok(serde_json::json!({
                "root": std::fs::canonicalize(root)
                    .map_err(|error| format!("{}: {error}", root))?,
                "scanned": summary.scanned,
                "added": summary.added,
                "updated": summary.updated,
                "unchanged": summary.unchanged,
                "missing": summary.missing,
            }).to_string())
        }
        [command, ..] if command == "status" && command_len == 1 => {
            Ok(latte_index::database_status(&database)?.to_string())
        }
        _ => Err("usage: latte-index index ROOT [--database PATH] | status [--database PATH]".to_string()),
    }
}

fn main() {
    let args: Vec<String> = std::env::args().skip(1).collect();
    match execute(&args) {
        Ok(output) => println!("{output}"),
        Err(error) => {
            eprintln!("latte-index: {error}");
            std::process::exit(2);
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_database_override_at_end_of_command() {
        let args = vec![
            "index".to_string(),
            "/tmp/root".to_string(),
            "--database".to_string(),
            "/tmp/index.sqlite3".to_string(),
        ];
        let (path, command_len) = database_arg(&args).unwrap();
        assert_eq!(path, PathBuf::from("/tmp/index.sqlite3"));
        assert_eq!(command_len, 2);
    }
}
