//! latte-props: what Properties shows of a file (ROADMAP 10L.01), and the few things it may change.
//!
//!   latte-props info PATH…          a JSON array, one object a path (see `info`)
//!   latte-props details PATH        everything the file says of itself (exiftool; a PDF's signatures by pdfsig):
//!                                   {"short": [{k, v}…] the few that matter for its kind, "groups": [{g, rows: [{k, v}…]}…]}
//!   latte-props versions PATH       the file in snapper's snapshots, newest first: [{n, date, what, path, size, modified,
//!                                   state: same | changed | absent}…] (root's config, which holds /home too)
//!   latte-props restore PATH N      the version of snapshot N back in its place; what is there now goes to the Trash
//!                                   by `latte-files trash`, so Ctrl+Z brings it back
//!   latte-props launcher PATH       a launcher's [Desktop Entry]: {name, exec, path, comment, icon, terminal}
//!   latte-props set PATH KEY VALUE  mode (octal) · group · hidden (0/1) · comment · tags · rating (0–10) ·
//!                                   origin (empty: forgotten) · opener (ID.desktop, for the file's kind) ·
//!                                   desktop.KEY (a launcher's Exec, Path, Comment, Icon, Terminal; Name by `latte-desktop name`) ·
//!                                   acl (KIND:NAME:rwx, KIND u or g) · acl- (KIND:NAME, taken out) · acl+ (NAME: a user, else a
//!                                   group, may read)
//!
//! Attributes kept beside the file are the ones other programs read: `user.xdg.comment`, `user.xdg.tags`,
//! `user.xdg.origin.url` (what browsers write), `user.baloo.rating` (Dolphin's 0–10). Hidden is the `.hidden`
//! file of the folder, as Nautilus and Dolphin read it. What a tool of the system knows better (the app that
//! opens a kind, the room on a disk) is asked of it.
use std::ffi::{c_char, c_void, CString};
use std::fs;
use std::os::unix::ffi::OsStrExt;
use std::os::unix::fs::{MetadataExt, PermissionsExt};
use std::path::{Path, PathBuf};
use std::process::Command;
use std::time::{Duration, Instant, UNIX_EPOCH};

extern "C" {
    fn getxattr(path: *const c_char, name: *const c_char, value: *mut c_void, size: usize) -> isize;
    fn setxattr(path: *const c_char, name: *const c_char, value: *const c_void, size: usize, flags: i32) -> i32;
    fn removexattr(path: *const c_char, name: *const c_char) -> i32;
}

fn cpath(p: &Path) -> CString { CString::new(p.as_os_str().as_bytes()).unwrap_or_default() }

fn xattr(p: &Path, name: &str) -> String {
    let (cp, cn) = (cpath(p), CString::new(name).unwrap());
    let mut buf = vec![0u8; 4096];
    let n = unsafe { getxattr(cp.as_ptr(), cn.as_ptr(), buf.as_mut_ptr() as *mut c_void, buf.len()) };
    if n <= 0 { return String::new(); }
    buf.truncate(n as usize);
    String::from_utf8_lossy(&buf).trim_end_matches('\0').to_string()
}

fn set_xattr(p: &Path, name: &str, value: &str) -> bool {
    let (cp, cn) = (cpath(p), CString::new(name).unwrap());
    if value.is_empty() { return unsafe { removexattr(cp.as_ptr(), cn.as_ptr()) } == 0 || xattr(p, name).is_empty(); }
    unsafe { setxattr(cp.as_ptr(), cn.as_ptr(), value.as_ptr() as *const c_void, value.len(), 0) == 0 }
}

/// A string as JSON writes it.
fn esc(s: &str) -> String {
    let mut o = String::with_capacity(s.len() + 2);
    o.push('"');
    for c in s.chars() {
        match c {
            '"' => o.push_str("\\\""),
            '\\' => o.push_str("\\\\"),
            '\n' => o.push_str("\\n"),
            '\t' => o.push_str("\\t"),
            c if (c as u32) < 0x20 => o.push_str(&format!("\\u{:04x}", c as u32)),
            c => o.push(c),
        }
    }
    o.push('"');
    o
}

fn out(cmd: &str, args: &[&str]) -> String {
    Command::new(cmd).args(args).output().ok().filter(|o| o.status.success())
        .map(|o| String::from_utf8_lossy(&o.stdout).trim().to_string()).unwrap_or_default()
}

fn lang() -> String {
    let l = ["LC_ALL", "LC_MESSAGES", "LANG"].iter().filter_map(|k| std::env::var(k).ok()).find(|v| !v.is_empty()).unwrap_or_default();
    l.split(['_', '.', '@']).next().unwrap_or("").to_string()
}

/// What shared-mime-info calls a kind, in the user's language when it has it.
fn kind_name(mime: &str) -> String {
    let dirs = std::env::var("XDG_DATA_DIRS").unwrap_or_else(|_| "/usr/local/share:/usr/share".into());
    let tag = format!("<comment xml:lang=\"{}\">", lang());
    // the user's language from any folder that has it, before the plain one: a folder early in the list may lack it
    let files: Vec<String> = dirs.split(':').filter_map(|d| fs::read_to_string(format!("{d}/mime/{mime}.xml")).ok()).collect();
    let pick = |x: &str, open: &str| x.find(open).map(|i| &x[i + open.len()..]).and_then(|r| r.split("</comment>").next()).map(str::to_string);
    files.iter().find_map(|x| pick(x, &tag)).or_else(|| files.iter().find_map(|x| pick(x, "<comment>"))).unwrap_or_else(|| mime.to_string())
}

/// The name a .desktop file gives its app, in the user's language when it has it.
fn app_name(id: &str) -> String {
    let home = std::env::var("HOME").unwrap_or_default();
    let mut dirs = vec![std::env::var("XDG_DATA_HOME").unwrap_or_else(|_| format!("{home}/.local/share"))];
    dirs.extend(std::env::var("XDG_DATA_DIRS").unwrap_or_else(|_| "/usr/local/share:/usr/share".into()).split(':').map(str::to_string));
    dirs.push("/var/lib/flatpak/exports/share".into());
    let local = format!("Name[{}]=", lang());
    for d in dirs {
        if let Ok(x) = fs::read_to_string(format!("{d}/applications/{id}")) {
            let line = |k: &str| x.lines().find(|l| l.starts_with(k)).map(|l| l[k.len()..].to_string());
            return line(&local).or_else(|| line("Name=")).unwrap_or_else(|| id.to_string());
        }
    }
    id.trim_end_matches(".desktop").to_string()
}

fn names(file: &str) -> Vec<(u32, String)> {
    fs::read_to_string(file).unwrap_or_default().lines()
        .filter_map(|l| { let f: Vec<&str> = l.split(':').collect(); Some((f.get(2)?.parse().ok()?, f[0].to_string())) }).collect()
}
fn name_of(list: &[(u32, String)], id: u32) -> String { list.iter().find(|(i, _)| *i == id).map(|(_, n)| n.clone()).unwrap_or(id.to_string()) }

fn secs(t: std::io::Result<std::time::SystemTime>) -> u64 { t.ok().and_then(|t| t.duration_since(UNIX_EPOCH).ok()).map_or(0, |d| d.as_secs()) }

/// A folder's contents: bytes, bytes on disk, files and folders; a huge one is cut off after two seconds.
fn walk(dir: &Path) -> (u64, u64, u64, u64, bool) {
    let (mut bytes, mut disk, mut files, mut dirs) = (0, 0, 0, 0);
    let start = Instant::now();
    let mut todo = vec![dir.to_path_buf()];
    while let Some(d) = todo.pop() {
        if start.elapsed() > Duration::from_secs(2) { return (bytes, disk, files, dirs, true); }
        let Ok(rd) = fs::read_dir(&d) else { continue };
        for e in rd.flatten() {
            let Ok(m) = e.metadata() else { continue };          // not followed: a link counts as itself
            disk += m.blocks() * 512;
            if m.is_dir() { dirs += 1; todo.push(e.path()); } else { files += 1; bytes += m.len(); }
        }
    }
    (bytes, disk, files, dirs, false)
}

fn hidden(p: &Path) -> bool {
    let name = p.file_name().map(|n| n.to_string_lossy().to_string()).unwrap_or_default();
    name.starts_with('.') || p.parent().and_then(|d| fs::read_to_string(d.join(".hidden")).ok())
        .is_some_and(|h| h.lines().any(|l| l == name))
}

fn info(p: &Path, users: &[(u32, String)], groups: &[(u32, String)]) -> String {
    let Ok(m) = fs::symlink_metadata(p) else { return format!("{{\"path\":{},\"missing\":true}}", esc(&p.to_string_lossy())) };
    let link = m.file_type().is_symlink();
    let m = fs::metadata(p).unwrap_or(m);
    let dir = m.is_dir();
    let mime = if dir { "inode/directory".to_string() } else { mime_of(p) };
    let opener = if dir { String::new() } else { out("xdg-mime", &["query", "default", &mime]) };
    let openers: Vec<String> = out("gio", &["mime", &mime]).lines().filter_map(|l| l.split_whitespace().find(|w| w.ends_with(".desktop")))
        .map(str::to_string).fold(Vec::new(), |mut v, id| { if !v.contains(&id) { v.push(id) } v });
    let mode = m.permissions().mode() & 0o7777;
    let mut o = vec![
        format!("\"path\":{}", esc(&p.to_string_lossy())),
        format!("\"name\":{}", esc(&p.file_name().map(|n| n.to_string_lossy().to_string()).unwrap_or("/".into()))),
        format!("\"where\":{}", esc(&p.parent().map(|d| d.to_string_lossy().to_string()).unwrap_or_default())),
        format!("\"dir\":{dir}"), format!("\"link\":{link}"),
        format!("\"target\":{}", esc(&if link { fs::read_link(p).map(|t| t.to_string_lossy().to_string()).unwrap_or_default() } else { String::new() })),
        format!("\"mime\":{}", esc(&mime)), format!("\"kind\":{}", esc(&kind_name(&mime))), format!("\"icon\":{}", esc(&icon_of(p, &mime, dir))),
        format!("\"opener\":{}", esc(&opener)), format!("\"opener_name\":{}", esc(&if opener.is_empty() { String::new() } else { app_name(&opener) })),
        format!("\"openers\":[{}]", openers.iter().map(|id| format!("{{\"id\":{},\"name\":{}}}", esc(id), esc(&app_name(id)))).collect::<Vec<_>>().join(",")),
        format!("\"created\":{}", secs(m.created())), format!("\"modified\":{}", secs(m.modified())), format!("\"accessed\":{}", secs(m.accessed())),
        format!("\"mode\":\"{:o}\"", mode), format!("\"owner\":{}", esc(&name_of(users, m.uid()))), format!("\"group\":{}", esc(&name_of(groups, m.gid()))),
        format!("\"mine\":{}", m.uid() == unsafe_uid()),
        format!("\"readonly\":{}", mode & 0o200 == 0), format!("\"hidden\":{}", hidden(p)), format!("\"exec\":{}", !dir && mode & 0o111 != 0),
        format!("\"comment\":{}", esc(&xattr(p, "user.xdg.comment"))), format!("\"tags\":{}", esc(&xattr(p, "user.xdg.tags"))),
        format!("\"rating\":{}", xattr(p, "user.baloo.rating").parse::<u32>().unwrap_or(0)),
        format!("\"origin\":{}", esc(&xattr(p, "user.xdg.origin.url"))), format!("\"selinux\":{}", esc(&xattr(p, "security.selinux"))),
        format!("\"acl\":[{}]", acl_of(p).iter().map(|(k, w, r)| format!("{{\"kind\":\"{k}\",\"who\":{},\"perm\":{}}}", esc(w), esc(r))).collect::<Vec<_>>().join(",")),
    ];
    if dir {
        let (bytes, disk, files, dirs, cut) = walk(p);
        o.extend([format!("\"size\":{bytes}"), format!("\"disk\":{disk}"), format!("\"files\":{files}"), format!("\"dirs\":{dirs}"), format!("\"partial\":{cut}")]);
        let df = out("df", &["-B1", "--output=used,size,target", &p.to_string_lossy()]);
        if let Some(l) = df.lines().nth(1) {
            let f: Vec<&str> = l.split_whitespace().collect();
            if f.len() >= 3 { o.extend([format!("\"fs_used\":{}", f[0]), format!("\"fs_size\":{}", f[1]), format!("\"fs_at\":{}", esc(f[2]))]); }
        }
    } else {
        o.extend([format!("\"size\":{}", m.len()), format!("\"disk\":{}", m.blocks() * 512)]);
    }
    format!("{{{}}}", o.join(","))
}

/// What to show for it: a picture is its own preview, a launcher has its icon, anything else the icon of its kind
/// as the icon theme names it (gio's first name, the most precise one).
fn icon_of(p: &Path, mime: &str, dir: bool) -> String {
    if dir { return "folder".into(); }
    if matches!(mime, "image/png" | "image/jpeg" | "image/webp" | "image/gif") { return p.to_string_lossy().to_string(); }
    if mime == "application/x-desktop" {
        if let Some(i) = fs::read_to_string(p).ok().and_then(|x| x.lines().find_map(|l| l.strip_prefix("Icon=").map(str::to_string))) { return i; }
    }
    let g = out("gio", &["info", "-a", "standard::icon", "--", &p.to_string_lossy()]);
    g.lines().find_map(|l| l.trim().strip_prefix("standard::icon: ")).and_then(|l| l.split(", ").next()).map(str::to_string)
        .unwrap_or_else(|| "text-x-generic".into())
}

/// The kind as the desktop knows it (by name and content, as the file managers do), or by content alone.
fn mime_of(p: &Path) -> String {
    let g = out("gio", &["info", "-a", "standard::content-type", "--", &p.to_string_lossy()]);
    g.lines().find_map(|l| l.trim().strip_prefix("standard::content-type: ")).map(str::to_string)
        .unwrap_or_else(|| out("file", &["-b", "-L", "--mime-type", "--", &p.to_string_lossy()]))
}

/// What matters most of a file, whatever its kind, in this order: the short Details (ROADMAP 10L.06). Exiftool's names.
const SHORT: &[&str] = &[
    // a picture
    "ImageSize", "Make", "Model", "LensModel", "FNumber", "ExposureTime", "ISO", "FocalLength", "Flash", "DateTimeOriginal",
    "GPSPosition", "Artist", "Copyright", "Software", "Rating",
    // a song
    "Title", "Album", "Year", "Genre", "Track", "AudioBitrate", "SampleRate", "ChannelMode", "AudioChannels", "Popularimeter",
    // a film
    "Duration", "VideoFrameRate", "CompressorID", "VideoCodec", "AudioFormat", "AvgBitrate", "HandlerDescription",
    // a document
    "Author", "Creator", "Subject", "Keywords", "Producer", "PageCount", "Pages", "Words", "LastModifiedBy", "CreateDate", "ModifyDate",
];

/// Exiftool's lines `[Group] Name : value`, as (group, name, value).
fn tags(lines: &str) -> Vec<(String, String, String)> {
    lines.lines().filter_map(|l| {
        let l = l.strip_prefix('[')?;
        let (g, rest) = l.split_once(']')?;
        let (k, v) = rest.split_once(" : ")?;
        Some((g.trim().to_string(), k.trim().to_string(), v.trim().to_string()))
    }).collect()
}

fn details(p: &Path) -> String {
    let path = p.to_string_lossy();
    let names = tags(&out("exiftool", &["-G1", "-a", "-s", "--", &path]));
    let l = lang();
    // the same lines with what each is called in the user's language, where exiftool has it
    let said = if l.is_empty() || l == "en" { names.clone() } else { tags(&out("exiftool", &["-G1", "-a", "-lang", &l, "--", &path])) };
    let said = if said.len() == names.len() { said } else { names.clone() };
    let row = |k: &str, v: &str| format!("{{\"k\":{},\"v\":{}}}", esc(k), esc(v));
    let mut short = Vec::new();
    for want in SHORT {
        if let Some(i) = names.iter().position(|(_, n, v)| n == want && !v.starts_with("(Binary data")) {
            short.push(row(&said[i].1, &said[i].2));
        }
    }
    let mut groups: Vec<(String, Vec<String>)> = Vec::new();
    for (i, (g, _, v)) in names.iter().enumerate() {
        if g == "ExifTool" || g == "System" || v.starts_with("(Binary data") { continue; }
        match groups.iter_mut().find(|(name, _)| name == g) {
            Some((_, rows)) => rows.push(row(&said[i].1, &said[i].2)),
            None => groups.push((g.clone(), vec![row(&said[i].1, &said[i].2)])),
        }
    }
    // a PDF's signatures: who signed, when, and whether it still holds (poppler's pdfsig)
    if mime_of(p) == "application/pdf" {
        let sig = Command::new("pdfsig").arg("--").arg(p).output().map(|o| String::from_utf8_lossy(&o.stdout).to_string()).unwrap_or_default();
        let rows: Vec<String> = sig.lines().filter_map(|l| l.trim().strip_prefix("- ")).filter_map(|l| l.split_once(": ")).map(|(k, v)| row(k, v)).collect();
        if !rows.is_empty() { groups.push(("Signatures".into(), rows)); }
    }
    format!("{{\"short\":[{}],\"groups\":[{}]}}", short.join(","),
        groups.iter().map(|(g, rows)| format!("{{\"g\":{},\"rows\":[{}]}}", esc(g), rows.join(","))).collect::<Vec<_>>().join(","))
}

/// A field of snapper's JSON object that starts at `o`: `"key": "text"` or `"key": 12`. Only what `versions` reads.
fn field(o: &str, key: &str) -> String {
    let Some(i) = o.find(&format!("\"{key}\":")) else { return String::new() };
    let v = o[i + key.len() + 3..].trim_start();
    if let Some(r) = v.strip_prefix('"') {
        let mut out = String::new();
        let mut esc_ = false;
        for c in r.chars() {
            if esc_ { out.push(c); esc_ = false } else if c == '\\' { esc_ = true } else if c == '"' { break } else { out.push(c) }
        }
        out
    } else {
        v.chars().take_while(|c| c.is_ascii_digit()).collect()
    }
}

fn versions(p: &Path) -> String {
    let list = out("snapper", &["-c", "root", "--jsonout", "list"]);
    let now = fs::symlink_metadata(p).ok();
    let mut rows = Vec::new();
    for o in list.split('{').skip(1) {
        let n = field(o, "number");
        if n.is_empty() || n == "0" { continue; }
        let old = PathBuf::from(format!("/.snapshots/{n}/snapshot")).join(p.strip_prefix("/").unwrap_or(p));
        let (size, modified, state) = match fs::symlink_metadata(&old) {
            Err(_) => (0, 0, "absent"),
            Ok(m) => {
                let same = now.as_ref().is_some_and(|c| c.len() == m.len() && secs(c.modified()) == secs(m.modified()));
                (m.len(), secs(m.modified()), if same { "same" } else { "changed" })
            }
        };
        rows.push(format!("{{\"n\":{n},\"date\":{},\"what\":{},\"path\":{},\"size\":{size},\"modified\":{modified},\"state\":\"{state}\"}}",
            esc(&field(o, "date")), esc(&field(o, "description")), esc(&old.to_string_lossy())));
    }
    rows.reverse();
    format!("[{}]", rows.join(","))
}

fn restore(p: &Path, n: &str) -> Result<(), String> {
    if n.is_empty() || !n.chars().all(|c| c.is_ascii_digit()) { return Err("restore: a snapshot's number".into()); }
    let old = PathBuf::from(format!("/.snapshots/{n}/snapshot")).join(p.strip_prefix("/").unwrap_or(p));
    if fs::symlink_metadata(&old).is_err() { return Err(format!("restore: not in snapshot {n}")); }
    if fs::symlink_metadata(p).is_ok() && !Command::new("latte-files").arg("trash").arg(p).status().is_ok_and(|s| s.success()) {
        return Err("restore: what is there now could not go to the Trash".into());
    }
    if Command::new("cp").args(["-a", "--"]).arg(&old).arg(p).status().is_ok_and(|s| s.success()) { Ok(()) } else { Err("restore: not copied".into()) }
}

/// A launcher's own keys, from its [Desktop Entry] (the name in the user's language, as the desktop shows it).
fn launcher(p: &Path) -> String {
    let x = fs::read_to_string(p).unwrap_or_default();
    let entry: Vec<&str> = x.lines().skip_while(|l| l.trim() != "[Desktop Entry]").skip(1).take_while(|l| !l.starts_with('[')).collect();
    let key = |k: &str| entry.iter().find_map(|l| l.strip_prefix(&format!("{k}="))).unwrap_or("").to_string();
    let local = entry.iter().find_map(|l| l.strip_prefix(&format!("Name[{}]=", lang()))).map(str::to_string);
    format!("{{\"name\":{},\"exec\":{},\"path\":{},\"comment\":{},\"icon\":{},\"terminal\":{}}}",
        esc(&local.unwrap_or_else(|| key("Name"))), esc(&key("Exec")), esc(&key("Path")), esc(&key("Comment")), esc(&key("Icon")),
        key("Terminal") == "true")
}

/// One key of a launcher's [Desktop Entry] set (or taken out, empty), the rest of the file as it was.
fn set_desktop_key(p: &Path, k: &str, v: &str) -> Result<(), String> {
    if !matches!(k, "Exec" | "Path" | "Comment" | "Icon" | "Terminal") { return Err(format!("desktop.{k}: not one Properties changes")); }
    let x = fs::read_to_string(p).map_err(|e| e.to_string())?;
    let (mut out, mut entry, mut done) = (Vec::new(), false, false);
    for l in x.lines() {
        if l.starts_with('[') {
            if entry && !done && !v.is_empty() { out.push(format!("{k}={v}")); done = true; }
            entry = l.trim() == "[Desktop Entry]";
        } else if entry && l.starts_with(&format!("{k}=")) {
            if !v.is_empty() { out.push(format!("{k}={v}")); }
            done = true;
            continue;
        }
        out.push(l.to_string());
    }
    if entry && !done && !v.is_empty() { out.push(format!("{k}={v}")); }
    let tmp = p.with_extension("desktop.latte-props");
    fs::write(&tmp, out.join("\n") + "\n").map_err(|e| e.to_string())?;
    if let Ok(m) = fs::metadata(p) { let _ = fs::set_permissions(&tmp, m.permissions()); }
    fs::rename(&tmp, p).map_err(|e| e.to_string())
}

/// The users and groups an ACL names, beside owner, group and others: (u or g, name, rwx).
fn acl_of(p: &Path) -> Vec<(char, String, String)> {
    out("getfacl", &["-c", "-p", "--", &p.to_string_lossy()]).lines().filter_map(|l| {
        let l = l.split('#').next()?.trim();
        let mut f = l.splitn(3, ':');
        let (kind, who, perm) = (f.next()?, f.next()?, f.next()?);
        if who.is_empty() { return None; }
        match kind { "user" => Some(('u', who.into(), perm.into())), "group" => Some(('g', who.into(), perm.into())), _ => None }
    }).collect()
}

fn setfacl(args: &[&str], p: &Path) -> Result<(), String> {
    if Command::new("setfacl").args(args).arg("--").arg(p).status().is_ok_and(|s| s.success()) { Ok(()) } else { Err("acl: setfacl refused".into()) }
}

fn unsafe_uid() -> u32 { fs::metadata("/proc/self").map(|m| m.uid()).unwrap_or(u32::MAX) }

fn set(p: &Path, key: &str, value: &str) -> Result<(), String> {
    let ok = |b: bool| if b { Ok(()) } else { Err(format!("{key}: not changed")) };
    match key {
        "mode" => {
            let m = u32::from_str_radix(value, 8).map_err(|_| "mode: octal, as 644".to_string())?;
            fs::set_permissions(p, fs::Permissions::from_mode(m & 0o7777)).map_err(|e| e.to_string())
        }
        "group" => ok(Command::new("chgrp").args(["--", value]).arg(p).status().is_ok_and(|s| s.success())),
        "comment" => ok(set_xattr(p, "user.xdg.comment", value)),
        "tags" => ok(set_xattr(p, "user.xdg.tags", value)),
        "origin" => ok(set_xattr(p, "user.xdg.origin.url", value)),
        "rating" => {
            let r: u32 = value.parse().map_err(|_| "rating: 0 to 10".to_string())?;
            ok(set_xattr(p, "user.baloo.rating", &if r == 0 { String::new() } else { r.min(10).to_string() }))
        }
        "opener" => {
            let mime = mime_of(p);
            ok(Command::new("xdg-mime").args(["default", value, &mime]).status().is_ok_and(|s| s.success()))
        }
        "hidden" => {
            // the folder's .hidden, as Nautilus and Dolphin read it; a name with a dot is hidden whatever this says
            let (Some(dir), Some(name)) = (p.parent(), p.file_name()) else { return Err("hidden: no folder".into()) };
            let name = name.to_string_lossy().to_string();
            let list = dir.join(".hidden");
            let mut lines: Vec<String> = fs::read_to_string(&list).unwrap_or_default().lines().filter(|l| *l != name && !l.is_empty()).map(str::to_string).collect();
            if value == "1" { lines.push(name); }
            if lines.is_empty() { let _ = fs::remove_file(&list); Ok(()) } else { fs::write(&list, lines.join("\n") + "\n").map_err(|e| e.to_string()) }
        }
        k if k.starts_with("desktop.") => set_desktop_key(p, &k[8..], value),
        "acl" => {
            let ok = value.splitn(3, ':').count() == 3 && (value.starts_with("u:") || value.starts_with("g:")) && value.rsplit(':').next().is_some_and(|r| r.len() == 3 && r.chars().all(|c| "rwx-".contains(c)));
            if !ok { return Err("acl: u:NAME:rwx or g:NAME:rwx".into()); }
            setfacl(&["-m", value], p)
        }
        "acl-" => setfacl(&["-x", value], p),
        "acl+" => {
            let kind = if names("/etc/passwd").iter().any(|(_, n)| n == value) { "u" } else if names("/etc/group").iter().any(|(_, n)| n == value) { "g" } else { return Err(format!("acl+: no user or group {value}")) };
            setfacl(&["-m", &format!("{kind}:{value}:r--")], p)
        }
        _ => Err(format!("unknown: {key}")),
    }
}

fn main() {
    let args: Vec<String> = std::env::args().skip(1).collect();
    match args.first().map(String::as_str) {
        Some("info") if args.len() > 1 => {
            let (users, groups) = (names("/etc/passwd"), names("/etc/group"));
            let all: Vec<String> = args[1..].iter().map(|a| info(&PathBuf::from(a), &users, &groups)).collect();
            println!("[{}]", all.join(","));
        }
        Some("details") if args.len() == 2 => println!("{}", details(Path::new(&args[1]))),
        Some("versions") if args.len() == 2 => println!("{}", versions(Path::new(&args[1]))),
        Some("launcher") if args.len() == 2 => println!("{}", launcher(Path::new(&args[1]))),
        Some("restore") if args.len() == 3 => {
            if let Err(e) = restore(Path::new(&args[1]), &args[2]) { eprintln!("latte-props: {e}"); std::process::exit(1); }
        }
        Some("set") if args.len() == 4 => {
            if let Err(e) = set(Path::new(&args[1]), &args[2], &args[3]) { eprintln!("latte-props: {e}"); std::process::exit(1); }
        }
        _ => {
            eprintln!("latte-props info PATH…  |  latte-props details PATH  |  latte-props set PATH mode|group|hidden|comment|tags|rating|origin|opener VALUE");
            std::process::exit(2);
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn exiftool_lines_are_read() {
        let t = tags("[EXIF]          Make                            : Google\n[ID3v2_3]       Title  : a : b\nnoise\n");
        assert_eq!(t, vec![("EXIF".into(), "Make".into(), "Google".into()), ("ID3v2_3".into(), "Title".into(), "a : b".into())]);
    }

    #[test]
    fn a_launcher_is_read_and_changed() {
        let d = std::env::temp_dir().join(format!("latte-props-l-{}", std::process::id()));
        fs::create_dir_all(&d).unwrap();
        let f = d.join("a.desktop");
        fs::write(&f, "[Desktop Entry]\nName=A\nExec=a\nTerminal=false\n[Desktop Action x]\nExec=keep\n").unwrap();
        set_desktop_key(&f, "Exec", "b --x").unwrap();
        set_desktop_key(&f, "Path", "/tmp").unwrap();
        set_desktop_key(&f, "Terminal", "").unwrap();
        assert_eq!(fs::read_to_string(&f).unwrap(), "[Desktop Entry]\nName=A\nExec=b --x\nPath=/tmp\n[Desktop Action x]\nExec=keep\n");
        assert!(launcher(&f).contains("\"exec\":\"b --x\"") && set_desktop_key(&f, "Name", "x").is_err());
        fs::remove_dir_all(&d).unwrap();
    }

    #[test]
    fn snapper_fields_are_read() {
        let o = r#""number": 215, "date": "2026-10-31 11:35:47", "description": "pred \"Fedora\" 45","#;
        assert_eq!((field(o, "number"), field(o, "date"), field(o, "description")), ("215".into(), "2026-10-31 11:35:47".into(), "pred \"Fedora\" 45".into()));
    }

    #[test]
    fn json_strings_are_escaped() {
        assert_eq!(esc("a\"b\\c\nd\u{1}"), "\"a\\\"b\\\\c\\nd\\u0001\"");
    }

    #[test]
    fn a_file_is_told_and_changed() {
        let d = std::env::temp_dir().join(format!("latte-props-{}", std::process::id()));
        fs::create_dir_all(&d).unwrap();
        let f = d.join("a b.txt");
        fs::write(&f, "hello").unwrap();
        let (u, g) = (names("/etc/passwd"), names("/etc/group"));
        let j = info(&f, &u, &g);
        assert!(j.contains("\"name\":\"a b.txt\"") && j.contains("\"size\":5") && j.contains("\"dir\":false"), "{j}");
        set(&f, "mode", "600").unwrap();
        assert!(info(&f, &u, &g).contains("\"mode\":\"600\"") && info(&f, &u, &g).contains("\"readonly\":false"));
        set(&f, "hidden", "1").unwrap();
        assert!(hidden(&f) && fs::read_to_string(d.join(".hidden")).unwrap() == "a b.txt\n");
        set(&f, "hidden", "0").unwrap();
        assert!(!hidden(&f) && !d.join(".hidden").exists());
        // the user's own attributes: tmpfs may refuse them, then there is nothing to check
        if set(&f, "acl+", "root").is_ok() {
            assert!(info(&f, &u, &g).contains("{\"kind\":\"u\",\"who\":\"root\",\"perm\":\"r--\"}"));
            set(&f, "acl", "u:root:rw-").unwrap();
            assert!(info(&f, &u, &g).contains("\"perm\":\"rw-\""));
            set(&f, "acl-", "u:root").unwrap();
            assert!(info(&f, &u, &g).contains("\"acl\":[]"));
        }
        assert!(set(&f, "acl", "x;rm -rf").is_err() && set(&f, "acl+", "nobody-like-this").is_err());
        if set(&f, "comment", "note").is_ok() {
            assert!(info(&f, &u, &g).contains("\"comment\":\"note\""));
            set(&f, "rating", "8").unwrap();
            assert!(info(&f, &u, &g).contains("\"rating\":8"));
        }
        let j = info(&d, &u, &g);
        assert!(j.contains("\"dir\":true") && j.contains("\"files\":1"), "{j}");
        fs::remove_dir_all(&d).unwrap();
    }
}
