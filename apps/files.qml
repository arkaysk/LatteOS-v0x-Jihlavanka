// DualBrew: the files. One panel as on Windows, or two side by side as in a commander; bin/latte-files moves
// things, this window shows them.   latte-app files [FOLDER] [sizes]   (sizes: straight to what fills that folder)
//
// The side: the user's folders, the Trash, the disks. The header: up, a new folder, the View (Explorer's: extra large,
// large, medium and small icons, tiles, details; a folder shows the pictures it holds), one panel or two. The coffee at the foot says what is here and what is chosen, and with two
// panels it carries the commander's keys: F5 copy and F6 move to the other panel, F7 new folder, F8 delete.
// The mouse first: a press chooses, Ctrl adds, Shift takes all between, twice opens, the right button is the menu
// everywhere; the middle one opens a folder in the other panel; the mouse's back and forward buttons go back and
// forward; twice on the bare ground goes up; files are dragged to the other panel, onto a folder, or out to any
// app, and dropped in from anywhere (moved on the same disk, copied to another; Ctrl copies). The column heads
// sort. Copying and moving are jobs on the coffee: how far, pause, stop; several wait their turn.
// A box drawn from bare ground chooses; dragged with the right button, a menu asks Copy, Move or Link here; Ctrl+Z
// takes back the last thing done (latte-files undo).
// The side and This computer hold every drive: disks, USB sticks, memory cards, DVD drives and disc images (an .iso is
// mounted as one, as Daemon Tools does), network places and clouds (Google Drive, OneDrive, Dropbox, MEGA… through
// rclone); one not yet mounted is mounted when pressed, and ejected with its button. Files and folders carry a
// colour (Colour in their menu); archives are unpacked and packed (zip, 7z; rar is unpacked) as jobs on the coffee.
// Each drive in the side carries a line of how full it is and what is left. The heading Disks and devices opens their
// overview in the panel (disks:), as KDE's Partition Manager shows them: every disk as a band of its partitions as wide
// as each is, how full each really is, and room no partition takes; below, a line for each partition.
// The panel one works in stands above the coffee; the other lies under it.
// The keys: Enter opens, Backspace goes up, F2 renames, Delete trashes, Ctrl+C/X/V, Ctrl+A, Ctrl+H hidden
// files, Tab the other panel. Space with one file chosen shows it in the other panel. Space with nothing chosen measures the folder: how much each thing in it holds,
// as a figure and as a bar, and in the other panel a map of it, as DiskTree draws it; Esc or its Back puts it away.
//
// Where one can go: the user's world is their home, its folders and the disks, under "This computer"; the system's
// own folders (/usr, /etc, …) are not on the way, so nothing there is deleted by mistake. "The real structure"
// (the View menu, or the side) shows Linux as it is, from /, for whoever wants it.
import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import "common"

ShellRoot {
    id: shell
    readonly property string home: Quickshell.env("HOME") || "/"
    readonly property var words: (Quickshell.env("LATTE_APP_ARGS") || "").split("\n").filter(w => w !== "")
    property bool dual: false
    property int active: 0                     // which panel has the keys
    property string view: "details"            // or "icons" (here.iconSize big), "small", "tiles": Explorer's views; "photos", the viewer
    property bool hidden: false
    property bool real: false                  // the real structure of Linux, from /; otherwise the user's world
    property bool wasDual: false               // before the sizes took the other panel
    readonly property bool sizing: left.source !== null || right.source !== null
    function showSizes() {
        if (sizing) return hideSizes()
        const from = here, to = other
        wasDual = dual; dual = true
        if (!from.measured) from.measure()
        to.source = from
    }
    function hideSizes() { const to = left.source ? left : right; if (to.source) { to.source.measured = false; to.source.forget() } to.source = null; dual = wasDual; active = to === left ? 1 : 0; if (!dual) active = 0 }
    // the roots of the user's world: home and every disk; a path is shown from the root it is under
    function rootOf(p) {
        let best = null
        for (const pl of places) if ((pl.kind === "home" || (drives.includes(pl.kind) && pl.path !== "/" && pl.path !== "")) && (p === pl.path || p.startsWith(pl.path + "/")) && (!best || pl.path.length > best.path.length)) best = pl
        return best
    }
    property var places: []
    // every drive: the disks, USB sticks and cards, DVD drives real and of an image, network places, clouds
    // the colours a file or a folder can carry (user.xdg.tags next to it), as Dolphin and macOS have them
    readonly property var colours: [{ id: "red", name: QT_TR_NOOP("Red"), color: "#e5484d" }, { id: "orange", name: QT_TR_NOOP("Orange"), color: "#f08c3a" },
        { id: "yellow", name: QT_TR_NOOP("Yellow"), color: "#f2c94c" }, { id: "green", name: QT_TR_NOOP("Green"), color: "#4cc38a" },
        { id: "blue", name: QT_TR_NOOP("Blue"), color: "#5b8def" }, { id: "purple", name: QT_TR_NOOP("Purple"), color: "#9b7bd6" }, { id: "grey", name: QT_TR_NOOP("Grey"), color: "#8a7f76" }]
    function colourOf(id) { const c = colours.find(x => x.id === id); return c ? c.color : "transparent" }
    readonly property var drives: ["disk", "usb", "card", "optical", "image", "network", "cloud"]
    function driveName(pl) { return pl.path === "/" ? I18n.tr("The whole system (/)") : (pl.name.split(" · ")[0] || pl.path) }
    function pin(path, on) { act([on ? "pin" : "unpin", path]); pinned.restart() }
    Timer { id: pinned; interval: 300; onTriggered: { shell.placesText = ""; shell.reloadPlaces() } }
    function reloadPlaces() { if (!placer.running) placer.running = true }
    Timer { interval: 4000; repeat: true; running: true; onTriggered: shell.reloadPlaces() }   // a stick put in shows up
    // a drive not yet mounted is mounted when it is pressed, and the panel goes there
    Process { id: mounter; property var then: null
              stdout: StdioCollector { onStreamFinished: { const at = this.text.trim(); shell.reloadPlaces(); if (at.startsWith("/")) shell.here.go(at) } } }
    function reach(pl) {
        if (pl.path !== "") return here.go(pl.path)
        mounter.running = false; mounter.command = ["latte-files", "mount", pl.device]; mounter.running = true
    }
    function eject(pl) { act(["eject", pl.path, pl.device]); if (here.path.startsWith(pl.path)) here.go("computer:"); ejected.restart() }
    Timer { id: ejected; interval: 1500; onTriggered: shell.reloadPlaces() }
    function canEject(pl) { return pl.path !== "" && (["usb", "card", "optical", "image", "network"].includes(pl.kind) || (pl.kind === "cloud" && pl.device !== "")) }
    function addCloud(x, y) {
        const add = (kind, name) => ({ icon: "cloud", text: name, run: () => { mounter.running = false; mounter.command = ["latte-files", "cloud", "add", kind, name.replace(/ /g, "")]; mounter.running = true } })
        menu.open(x, y, [add("google", "Google Drive"), add("onedrive", "OneDrive"), add("dropbox", "Dropbox"), { line: true },
                         { icon: "terminal-2", text: I18n.tr("MEGA and others (rclone)…"), run: () => Quickshell.execDetached(["foot", "-e", "rclone", "config"]) },
                         { icon: "network", text: I18n.tr("A network place (SMB, SFTP, FTP, WebDAV)…"), run: () => shell.ask("server") }])
    }
    Component.onCompleted: if (words.includes("sizes")) Qt.callLater(showSizes)
    // ── jobs: copying and moving, one at a time, the rest waiting ────────────────────────────────────────────
    property var jobs: []                      // { how, to, files, title }
    property var job: null                     // the one under way: { title, total, done, name, paused }
    function enqueue(how, to, files) {
        if (!files.length || !to.startsWith("/")) return
        const title = (files.length === 1 ? files[0].split("/").pop() : I18n.tr("{n} items", { n: files.length })) + "  →  " + (to.split("/").pop() || "/")
        jobs = jobs.concat([{ how: how, to: to, files: files, title: title }])
        if (!job) nextJob()
    }
    function nextJob() {
        if (!jobs.length) { job = null; left.again(); right.again(); return }
        const j = jobs[0]; jobs = jobs.slice(1)
        job = { title: j.title, how: j.how, total: 0, done: 0, name: "", paused: false }
        jobber.command = ["latte-files", "job", j.how, j.to].concat(j.files); jobber.running = true
    }
    Process { id: jobber
        stdout: SplitParser { onRead: line => { if (!shell.job) return
            const sp = line.indexOf(" "), k = line.slice(0, sp), v = line.slice(sp + 1), j = Object.assign({}, shell.job)
            if (k === "total") j.total = parseInt(v); else if (k === "done") j.done = parseInt(v); else if (k === "file") j.name = v
            shell.job = j } }
        onExited: { left.again(); right.again(); shell.nextJob() } }
    function pauseJob() { if (!job || !jobber.running) return
        const stop = !job.paused, pid = String(jobber.processId)
        Quickshell.execDetached(["sh", "-c", "pkill -" + (stop ? "STOP" : "CONT") + " -P \"$1\"; kill -" + (stop ? "STOP" : "CONT") + " \"$1\"", "sh", pid])
        const j = Object.assign({}, job); j.paused = stop; job = j }
    function stopJob() { if (!jobber.running) return; const pid = String(jobber.processId); jobs = []
        Quickshell.execDetached(["sh", "-c", "pkill -CONT -P \"$1\"; pkill -P \"$1\"; kill -CONT \"$1\"; kill \"$1\"", "sh", pid]) }
    // ── the map of what fills a folder, as DiskTree draws it: a rectangle for everything, as big as what it
    // holds, its colour the kind of thing it is ──────────────────────────────────────────────────────────────
    readonly property var kinds: [
        { id: "code", name: QT_TR_NOOP("Code"), color: "#5b8def", ext: ["c", "h", "cc", "cpp", "hpp", "rs", "py", "js", "ts", "qml", "lua", "luau", "plm", "go", "java", "kt", "sh", "json", "toml", "yaml", "yml", "wgsl", "html", "css"] },
        { id: "media", name: QT_TR_NOOP("Pictures, music, video"), color: "#c96bd0", ext: ["jpg", "jpeg", "png", "gif", "webp", "avif", "heic", "svg", "raw", "cr2", "nef", "mp4", "mkv", "webm", "avi", "mov", "mp3", "flac", "ogg", "opus", "wav", "m4a"] },
        { id: "docs", name: QT_TR_NOOP("Documents"), color: "#4cc38a", ext: ["pdf", "doc", "docx", "odt", "rtf", "txt", "md", "xls", "xlsx", "ods", "csv", "ppt", "pptx", "odp", "epub"] },
        { id: "archive", name: QT_TR_NOOP("Archives and disk images"), color: "#4fb3c4", ext: ["zip", "tar", "gz", "xz", "zst", "bz2", "7z", "rar", "deb", "rpm", "iso", "img", "qcow2", "appimage", "flatpak"] },
        { id: "tools", name: QT_TR_NOOP("Programs and games"), color: "#9b7bd6", ext: ["exe", "msi", "dll", "so", "pak", "bin"],
          names: [".cargo", ".rustup", ".var", ".steam", ".wine", ".local", ".npm-global", "go", "Games", "Hry", "Steam", "flatpak", ".mozilla", ".zen"] },
        { id: "git", name: QT_TR_NOOP("Git"), color: "#e5484d", names: [".git"] },
        // what can go without losing anything: it comes back by itself, or it has already been thrown away
        { id: "cache", name: QT_TR_NOOP("Caches and leftovers"), color: "#d9a441", names: [".cache", "cache", "Cache", "node_modules", "__pycache__", "target", ".gradle", ".npm", ".pnpm-store", "Trash", ".thumbnails"] },
        { id: "other", name: QT_TR_NOOP("Other"), color: "#8a7f76" }]
    function kindOf(p) {
        const n = p.split("/").pop(), dot = n.lastIndexOf("."), ext = dot > 0 ? n.slice(dot + 1).toLowerCase() : ""
        const pl = places.find(x => x.path === p)
        if (pl && (pl.kind === "pictures" || pl.kind === "music" || pl.kind === "videos")) return "media"
        if (pl && pl.kind === "documents") return "docs"
        for (const k of kinds) if ((k.names && k.names.includes(n)) || (ext && k.ext && k.ext.includes(ext))) return k.id
        return ""
    }
    function kindColor(id) { const k = kinds.find(x => x.id === id); return k ? k.color : kinds[kinds.length - 1].color }
    // squarified treemap (Bruls, Huizing, van Wijk): rows along the shorter side, each kept as square as it goes.
    // `whole` is what the box stands for, so things too small to see leave honest empty ground, not a stretch.
    function squarify(items, x, y, w, h, whole) {
        const out = [], scale = w * h / Math.max(1, whole)
        let rest = items.filter(i => i.size * scale >= 24), row = []
        const worst = (r, side) => { let s = 0, mx = 0, mn = Infinity; for (const i of r) { const a = i.size * scale; s += a; mx = Math.max(mx, a); mn = Math.min(mn, a) }
                                     return Math.max(side * side * mx / (s * s), s * s / (side * side * mn)) }
        while (rest.length && w > 2 && h > 2) {
            const side = Math.min(w, h)
            if (!row.length || worst(row.concat([rest[0]]), side) <= worst(row, side)) { row.push(rest.shift()); if (rest.length) continue }
            const thick = row.reduce((t, i) => t + i.size * scale, 0) / side
            let at = 0
            for (const i of row) { const len = i.size * scale / thick
                out.push(w >= h ? { item: i, x: x, y: y + at, w: thick, h: len } : { item: i, x: x + at, y: y, w: len, h: thick }); at += len }
            if (w >= h) { x += thick; w -= thick } else { y += thick; h -= thick }
            row = []
        }
        return out
    }

    // ── a look at one file in the other panel (Space), as the sizes are ──────────────────────────────────────
    readonly property bool peeking: left.peek !== "" || right.peek !== ""
    function showPeek(path) { if (peeking) return hidePeek(); wasDual = dual; dual = true; other.peek = path }
    function hidePeek() { const to = left.peek !== "" ? left : right; to.peek = ""; dual = wasDual; active = to === left ? 1 : 0; if (!dual) active = 0 }
    // what there is to know of the one thing chosen, for the coffee at the foot: a folder's items and size, a
    // picture's size and camera, a video's length (latte-files about)
    property string aboutFor: ""
    property var about: ({})
    function learn() { const p = here.picked(), one = p.length === 1 ? p[0] : ""; if (one === aboutFor) return
                       aboutFor = one; about = ({}); abouter.running = false; if (one !== "") asking_about.restart() }
    Timer { id: asking_about; interval: 120; onTriggered: { abouter.command = ["latte-files", "about", shell.aboutFor]; abouter.running = true } }
    Process { id: abouter; stdout: StdioCollector { onStreamFinished: { const a = {}; for (const l of this.text.split("\n")) { const i = l.indexOf("\t"); if (i > 0) a[l.slice(0, i)] = l.slice(i + 1) } shell.about = a } } }
    onActiveChanged: learn()
    function aboutText() {
        const a = about, name = aboutFor.split("/").pop(), out = [name]
        if (a.items !== undefined) out.push(I18n.tr("Folder"), I18n.tr("{n} items", { n: a.items }))
        if (a.pixels) out.push(a.pixels)
        if (a.length) out.push(a.length)
        if (a.Model) out.push(a.Model)
        if (a.DateTimeOriginal) { const t = a.DateTimeOriginal.match(/^(\d+):(\d+):(\d+) (\d+):(\d+)/); if (t) out.push(I18n.tr("taken {date}", { date: (+t[3]) + ". " + (+t[2]) + ". " + t[1] + "  " + t[4] + ":" + t[5] })) }
        for (const k of ["FNumber", "ExposureTime"]) if (a[k]) out.push(a[k])
        if (a.ISOSpeedRatings) out.push("ISO " + a.ISOSpeedRatings)
        if (a.bytes !== undefined || a.size !== undefined) out.push(bytes(parseFloat(a.bytes !== undefined ? a.bytes : a.size)))
        if (a.when) out.push(I18n.tr("modified {date}", { date: Qt.formatDateTime(new Date(parseInt(a.when) * 1000), "d. M. yyyy  hh:mm") }))
        return out.join("   ·   ")
    }
    readonly property var here: active === 0 ? left : right
    readonly property var other: active === 0 ? right : left
    // what is asked of the user in the foot: a name for something new, or another name
    property string asking: ""                 // "" | "folder" | "file" | "rename"
    property string askingFor: ""

    readonly property var placeNames: ({ "home": QT_TR_NOOP("Home"), "desktop": QT_TR_NOOP("Desktop"), "documents": QT_TR_NOOP("Documents"), "download": QT_TR_NOOP("Downloads"),
                                         "pictures": QT_TR_NOOP("Pictures"), "music": QT_TR_NOOP("Music"), "videos": QT_TR_NOOP("Videos"), "trash": QT_TR_NOOP("Recycle Bin"), "disk": QT_TR_NOOP("This computer") })
    readonly property var placeIcons: ({ "home": "home", "desktop": "device-desktop", "documents": "file-text", "download": "download", "pictures": "photo", "music": "music",
                                         "videos": "player-play", "trash": "trash", "disk": "disc", "usb": "usb", "card": "device-sd-card", "optical": "disc",
                                         "image": "disc", "network": "network", "cloud": "cloud" })
    readonly property var driveKinds: ({ "disk": QT_TR_NOOP("Local disk"), "usb": QT_TR_NOOP("USB drive"), "card": QT_TR_NOOP("Memory card"), "optical": QT_TR_NOOP("DVD drive"),
                                         "image": QT_TR_NOOP("Disc image"), "network": QT_TR_NOOP("Network place"), "cloud": QT_TR_NOOP("Cloud") })
    Process { id: placer; running: true; command: ["latte-files", "places"]
              stdout: StdioCollector { onStreamFinished: { const t = this.text; if (t === shell.placesText) return; shell.placesText = t
                  shell.places = t.split("\n").filter(l => l !== "").map(l => { const p = l.split("\t"); return { kind: p[0], path: p[1], name: p[2] || "", device: p[3] || "", used: Number(p[4] || 0), total: Number(p[5] || 0) } }) } } }
    // every disk with its partitions and how full each is, for the overview of Disks and devices (disks:)
    property var disks: []
    Process { id: disker; command: ["latte-files", "disks"]
              stdout: StdioCollector { onStreamFinished: { try { shell.disks = JSON.parse(this.text) } catch (e) { shell.disks = [] } } } }
    // how full a drive is, as a colour: calm, then gold, then red when little is left
    function fullness(f) { return f > 0.9 ? Theme.red : (f > 0.75 ? Theme.gold : Theme.ok) }
    readonly property var fsColours: ({ "vfat": "#c9a227", "ext4": "#5f9fb8", "btrfs": "#7d9be0", "xfs": "#6fb39a", "ntfs": "#a58be0", "exfat": "#d6895f", "swap": "#c4677a" })
    property string placesText: ""

    Process { id: doer; onExited: { left.again(); right.again() } }
    function act(args) { doer.running = false; doer.command = ["latte-files"].concat(args); doer.running = true }
    function bytes(b) { const u = ["B", "KB", "MB", "GB", "TB"]; let v = b || 0, i = 0; while (v >= 1024 && i < 4) { v /= 1024; i++ } return v.toFixed(i ? 1 : 0) + " " + u[i] }
    function open(path, isDir) { if (isDir) here.go(path); else Quickshell.execDetached(path.endsWith(".desktop") ? ["gio", "launch", path] : ["gio", "open", path]) }
    function ask(what, path) { asking = what; askingFor = path || ""; answer.text = what === "rename" ? path.split("/").pop() : (what === "folder" ? I18n.tr("New folder") : (what === "server" ? "smb://" : I18n.tr("New Text Document") + ".txt"))
                               Qt.callLater(() => { answer.focusIt(); }) }
    function answered(text) {
        const t = text.trim(), what = asking, target = askingFor
        asking = ""
        // a network place: gio mounts it in a terminal, where it can ask for a name and a password
        if (what === "server") { if (t.indexOf("://") > 0) Quickshell.execDetached(["foot", "-e", "sh", "-c", "gio mount \"$1\" && echo OK || read x", "sh", t]); return }
        if (t === "" || t.indexOf("/") >= 0) return
        if (what === "rename") act(["rename", target, t]); else act([what, here.path, t])
    }

    // "Open with": asked before an item's menu comes up
    property var waiting: null
    Process { id: openers; stdout: StdioCollector { onStreamFinished: {
        const apps = this.text.split("\n").filter(l => l.indexOf("\t") > 0).map(l => ({ id: l.split("\t")[0], name: l.split("\t")[1] }))
        const w = shell.waiting; shell.waiting = null
        if (w) shell.itemMenu(w.path, w.isDir, w.x, w.y, apps.slice(0, 8)) } } }
    function itemMenu(path, isDir, x, y, apps) {
        if (apps === undefined && !isDir) { waiting = { path: path, isDir: isDir, x: x, y: y }; openers.running = false; openers.command = ["latte-desktop", "openers", path]; openers.running = true; return }
        const picked = here.picked(), many = picked.length > 1, inTrash = here.path.indexOf("/.local/share/Trash/files") >= 0
        const rows = [{ icon: "external-link", text: I18n.tr("Open"), bold: true, hint: "Enter", run: () => shell.open(path, isDir) },
            ...(apps && apps.length && !many ? [{ icon: "apps", text: I18n.tr("Open with"), more: apps.map(a => ({ text: a.name, run: () => Quickshell.execDetached(["gtk-launch", a.id, path]) })) }] : []),
            ...(isDir && !many ? [{ icon: "layout-columns", text: I18n.tr("Open in the other panel"), run: () => { shell.dual = true; shell.other.go(path) } }] : []),
            ...(isDir && !many ? [places.some(p => p.kind === "favourite" && p.path === path) ? { icon: "star", text: I18n.tr("Remove from favourites"), run: () => shell.pin(path, false) }
                                                                                             : { icon: "star", text: I18n.tr("Add to favourites"), run: () => shell.pin(path, true) }] : []),
            ...(!isDir && !many ? [{ icon: "eye", text: I18n.tr("A look"), hint: I18n.tr("Space"), run: () => shell.showPeek(path) }] : []),
            { line: true },
            { icon: "cut", text: I18n.tr("Cut"), hint: "Ctrl+X", run: () => shell.act(["clip", "cut"].concat(picked)) },
            { icon: "copy", text: I18n.tr("Copy"), hint: "Ctrl+C", run: () => shell.act(["clip", "copy"].concat(picked)) },
            { icon: "clipboard", text: I18n.tr("Copy as path"), run: () => Quickshell.execDetached(["wl-copy", "--", picked.join("\n")]) },
            { line: true }]
        // archives: out here, or to the other panel; anything: into a zip or a 7z
        const packed = ["zip", "7z", "rar", "tar", "gz", "tgz", "xz", "bz2", "zst"]
        if (picked.every(p => packed.includes(FileIcons.ending(p.split("/").pop()))))
            rows.push({ icon: "file-zip", text: I18n.tr("Extract here"), run: () => shell.enqueue("extract", here.path, picked) },
                      ...(dual && other.path.startsWith("/") ? [{ icon: "file-zip", text: I18n.tr("Extract to the other panel"), run: () => shell.enqueue("extract", other.path, picked) }] : []))
        rows.push({ icon: "package", text: I18n.tr("Compress"), more: [{ text: I18n.tr("To a ZIP file"), run: () => shell.enqueue("zip", here.path, picked) },
                                                                        { text: I18n.tr("To a 7z file"), run: () => shell.enqueue("7z", here.path, picked) }] })
        if (!many && FileIcons.ending(path) === "iso") rows.push({ icon: "disc", text: I18n.tr("Mount as a DVD drive"), run: () => { mounter.running = false; mounter.command = ["latte-files", "iso", path]; mounter.running = true } })
        rows.push({ icon: "tag", text: I18n.tr("Colour"), more: shell.colours.map(c => ({ tint: c.color, text: I18n.tr(c.name), run: () => { shell.act(["tag", c.id].concat(picked)) } }))
                                                                     .concat([{ line: true }, { text: I18n.tr("No colour"), run: () => shell.act(["tag", ""].concat(picked)) }]) })
        rows.push({ line: true })
        if (!many) rows.push({ icon: "pencil", text: I18n.tr("Rename"), hint: "F2", run: () => shell.ask("rename", path) })
        if (!inTrash) rows.push({ icon: "trash", text: I18n.tr("Delete"), hint: "Del", danger: true, run: () => shell.act(["trash"].concat(picked)) })
        menu.open(x, y, rows)
    }
    // the views of Windows' Explorer, by the same names; Ctrl and the wheel go between the icon sizes
    function views() {
        const icons = (size, name) => ({ text: I18n.tr(name), checked: view === "icons" && here.iconSize === size, run: () => { here.iconSize = size; view = "icons" } })
        return [icons(256, "Extra large icons"), icons(128, "Large icons"), icons(64, "Medium icons"),
                { text: I18n.tr("Small icons"), checked: view === "small", run: () => view = "small" },
                { line: true },
                { text: I18n.tr("Tiles"), checked: view === "tiles", run: () => view = "tiles" },
                { text: I18n.tr("Photo viewer"), checked: view === "photos", run: () => view = "photos" },
                { text: I18n.tr("Details"), checked: view === "details", run: () => view = "details" }]
    }
    function groundMenu(x, y) {
        if (!here.path.startsWith("/")) return menu.open(x, y, [{ text: I18n.tr("The real structure"), checked: real, run: () => real = !real }])
        const inTrash = here.path.indexOf("/.local/share/Trash/files") >= 0
        menu.open(x, y, inTrash ? [{ icon: "trash", text: I18n.tr("Empty Recycle Bin"), danger: true, run: () => shell.act(["empty"]) }] : [
            { icon: "layout-grid", text: I18n.tr("View"), more: shell.views().concat([{ line: true }, { text: I18n.tr("Hidden files"), checked: shell.hidden, hint: "Ctrl+H", run: () => shell.hidden = !shell.hidden },
                                                                  { text: I18n.tr("The real structure"), checked: shell.real, run: () => shell.real = !shell.real }]) },
            { icon: "refresh", text: I18n.tr("Refresh"), hint: "F5", run: () => here.again() },
            { icon: "arrow-back-up", text: I18n.tr("Undo"), hint: "Ctrl+Z", run: () => shell.act(["undo"]) },
            { icon: "disc", text: I18n.tr("How much each folder holds"), checked: shell.sizing, hint: I18n.tr("Space"), run: () => shell.showSizes() },
            { line: true },
            { icon: "clipboard", text: I18n.tr("Paste"), hint: "Ctrl+V", run: () => shell.act(["paste", here.path]) },
            { icon: "plus", text: I18n.tr("New"), more: [{ icon: "folder-plus", text: I18n.tr("Folder"), run: () => shell.ask("folder") }, { icon: "file-text", text: I18n.tr("Text Document"), run: () => shell.ask("file") }] },
            { line: true },
            { icon: "terminal-2", text: I18n.tr("Open in Terminal"), run: () => Quickshell.execDetached(["sh", "-c", "cd \"$1\" && exec foot", "sh", here.path]) }])
    }

    // ── a panel: where it is, what is chosen, and its files ───────────────────────────────────────────────
    component Panel: Item {
        id: panel
        property int index: 0
        property string path: shell.home
        property var chosen: ({})
        property string last: ""               // the one pressed last, where Shift starts from
        property var before: []                // the way back
        property var source: null              // showing how much each thing in that panel holds, instead of a folder
        property string peek: ""               // showing one file of the other panel, instead of a folder
        property var ahead: []                 // the way forward, after going back
        property string sortBy: "name"         // name, size, date
        property bool sortDown: false
        property real iconSize: 64             // Ctrl and the wheel make the icons bigger or smaller
        readonly property bool isActive: shell.active === index
        onChosenChanged: if (isActive) shell.learn()
        function go(to) { if (to === path || to === "") return; before = before.concat([path]); ahead = []; path = to; chosen = ({}); last = "" }
        function back() { if (!before.length) return; const b = before.slice(); ahead = ahead.concat([path]); path = b.pop(); before = b; chosen = ({}) }
        function forward() { if (!ahead.length) return; const a = ahead.slice(); before = before.concat([path]); path = a.pop(); ahead = a; chosen = ({}) }
        function sort(by) { if (sortBy === by) sortDown = !sortDown; else { sortBy = by; sortDown = by !== "name" } }
        // what a drag carries: everything chosen when the one held is chosen, else that one
        function carried(filePath) { return chosen[filePath] ? picked() : [filePath] }
        // the mouse's own buttons, wherever they are pressed in the panel
        function extra(m) { if (m.button === Qt.BackButton) { back(); return true } if (m.button === Qt.ForwardButton) { forward(); return true } return false }
        function up() {
            if (path === "computer:") return
            if (path === "disks:") return go("computer:")
            const root = shell.real ? null : shell.rootOf(path)
            if (root && root.path === path) return go("computer:")
            if (path !== "/") go(path.replace(/\/[^/]+\/?$/, "") || "/")
        }
        // the way to here, as pieces one can press: from / in the real structure, else from This computer
        readonly property var way: {
            if (path === "computer:") return [{ name: I18n.tr("This computer"), path: "computer:" }]
            if (path === "disks:") return [{ name: I18n.tr("This computer"), path: "computer:" }, { name: I18n.tr("Disks and devices"), path: "disks:" }]
            const root = shell.real ? null : shell.rootOf(path)
            const base = root ? root.path : "", parts = path.slice(base.length).split("/").filter(x => x !== ""), out = []
            if (root) out.push({ name: I18n.tr("This computer"), path: "computer:" }, { name: root.kind === "home" ? I18n.tr("Home") : (root.name.split(" · ")[0] || root.path), path: root.path })
            else out.push({ name: "/", path: "/" })
            let at = base
            for (const x of parts) { at += "/" + x; out.push({ name: x, path: at }) }
            return out
        }
        // read the folder anew: its binding goes empty and back, and stays a binding (an assignment would cut it off)
        property bool fresh: true
        function again() { fresh = false; fresh = true; readTags() }
        // the colours of what is here
        property var tags: ({})
        function readTags() { if (!path.startsWith("/")) { tags = ({}); return } tagger.running = false; tagger.command = ["latte-files", "tags", path]; tagger.running = true }
        Process { id: tagger; stdout: StdioCollector { onStreamFinished: { const t = {}; for (const l of this.text.split("\n")) { const i = l.lastIndexOf("\t"); if (i > 0) t[l.slice(0, i)] = l.slice(i + 1) } panel.tags = t } } }
        function picked() { return Object.keys(chosen) }
        function photoStep(d) { photos.step(d) }
        // a box drawn with the mouse from bare ground chooses everything it touches, as on Windows; Ctrl adds
        property bool banding: false
        property point bandFrom
        property rect band
        property var bandBase: ({})
        function groundPressed(m, p) { shell.active = index; keys.forceActiveFocus(); if (extra(m)) return
                                       if (m.button !== Qt.LeftButton) return
                                       banding = true; bandFrom = p; band = Qt.rect(p.x, p.y, 0, 0)
                                       bandBase = (m.modifiers & Qt.ControlModifier) ? Object.assign({}, chosen) : ({}); chosen = Object.assign({}, bandBase) }
        function bandMove(p) {
            if (!banding) return
            const x = Math.min(p.x, bandFrom.x), y = Math.min(p.y, bandFrom.y), w = Math.abs(p.x - bandFrom.x), h = Math.abs(p.y - bandFrom.y)
            band = Qt.rect(x, y, w, h)
            const s = Object.assign({}, bandBase), icons = shell.view !== "details", cols = Math.max(1, Math.floor(grid.width / grid.cellWidth))
            for (let i = 0; i < files.count; i++) {
                const cx = icons ? (i % cols) * grid.cellWidth : 0, cy = icons ? Math.floor(i / cols) * grid.cellHeight - grid.contentY : list.y + i * 34 - list.contentY
                if (cx < x + w && cx + (icons ? grid.cellWidth : list.width) > x && cy < y + h && cy + (icons ? grid.cellHeight : 34) > y) s[files.get(i, "filePath")] = true
            }
            chosen = s
        }
        function all() { const s = {}; for (let i = 0; i < files.count; i++) s[files.get(i, "filePath")] = true; chosen = s }
        function press(filePath, at, mods) {
            shell.active = index
            if (mods & Qt.ControlModifier) { const s = Object.assign({}, chosen); if (s[filePath]) delete s[filePath]; else s[filePath] = true; chosen = s }
            else if ((mods & Qt.ShiftModifier) && last !== "") {
                let from = -1
                for (let i = 0; i < files.count; i++) if (files.get(i, "filePath") === last) from = i
                const s = {}
                for (let i = Math.min(from, at); i <= Math.max(from, at); i++) if (i >= 0) s[files.get(i, "filePath")] = true
                chosen = s; return
            } else { const s = {}; s[filePath] = true; chosen = s }
            last = filePath
            if (shell.peeking && shell.other.peek !== "") shell.other.peek = filePath      // the look follows the choice
        }
        readonly property int count: files.count
        // How much each thing here holds, folders too: measured when asked (Space), three levels deep, as du gets
        // through them, so a big folder fills in while one watches. `sizes` is what is right here, `inner` what is
        // inside each folder below; the map in the other panel is drawn from both.
        property var sizes: ({})
        property var inner: ({})               // folder -> [{ path, size }]
        property var dirs: ({})                // which of them are folders
        property real whole: 0                 // the folder itself, once du is through
        property var disk: null                // { size, free }
        property bool measured: false
        readonly property real largest: { let m = 1; for (const k in sizes) if (sizes[k] > m) m = sizes[k]; return m }
        readonly property real total: { if (whole > 0) return whole; let t = 0; for (const k in sizes) t += sizes[k]; return t }
        readonly property bool measuring: meter.running
        property var rawSizes: ({})
        property var rawInner: ({})
        function forget() { meter.running = false; sizes = ({}); inner = ({}); dirs = ({}); rawSizes = ({}); rawInner = ({}); whole = 0; disk = null }
        function measure() { if (measured) { measured = false; forget(); return }
                             forget(); measured = true; meter.command = ["latte-files", "tree", path]; meter.running = true }
        function settle() { sizes = Object.assign({}, rawSizes); inner = Object.assign({}, rawInner) }
        onPathChanged: { measured = false; forget(); readTags() }
        Component.onCompleted: readTags()
        // the lines come by the thousand: they are gathered quietly and shown a few times a second
        Timer { running: meter.running; interval: 300; repeat: true; onTriggered: panel.settle() }
        Process { id: meter; onExited: panel.settle()
            stdout: SplitParser { onRead: line => { const p = line.split("\t")
                if (p[0] === "disk") { panel.disk = { size: parseFloat(p[1]), free: parseFloat(p[2]) }; return }
                if (p[0] === "dir") { panel.dirs[p.slice(1).join("\t")] = true; return }
                if (p.length < 2) return
                const size = parseFloat(p[0]), at = p.slice(1).join("\t"), base = panel.path === "/" ? "/" : panel.path + "/"
                if (at === panel.path) { panel.whole = size; return }
                if (!at.startsWith(base)) return
                const up = at.slice(0, at.lastIndexOf("/")) || "/"
                if (up === panel.path) { panel.rawSizes[at] = size; return }
                (panel.rawInner[up] = panel.rawInner[up] || []).push({ path: at, size: size }) } } }
        FolderListModel { id: files; folder: panel.fresh && panel.path.startsWith("/") ? "file://" + panel.path : ""; showDirsFirst: true; showDotAndDotDot: false; showHidden: shell.hidden
                          sortField: panel.sortBy === "size" ? FolderListModel.Size : (panel.sortBy === "date" ? FolderListModel.Time : FolderListModel.Name); sortReversed: panel.sortDown }

        Rectangle { anchors.fill: parent; anchors.margins: 6; radius: 14; color: panel.isActive || !shell.dual ? Theme.surface : Theme.ground
                    border.width: shell.dual ? 2 : 0; border.color: panel.isActive ? Theme.gold : "transparent" }
        // where it is: every folder on the way can be pressed
        Flickable { id: crumbs; x: 18; y: 12; width: parent.width - 36; height: 32; contentWidth: way.width; clip: true; boundsBehavior: Flickable.StopAtBounds
            onContentWidthChanged: contentX = Math.max(0, contentWidth - width)
            Row { id: way; spacing: 2
                Repeater { model: panel.source || panel.peek !== "" ? [] : panel.way
                    Row { required property var modelData; required property int index; spacing: 2
                        Glyph { visible: parent.index > 0; name: "chevron-right"; font.pixelSize: 13; color: Theme.faint; anchors.verticalCenter: parent.verticalCenter }
                        Rectangle { height: 30; width: crumb.implicitWidth + 18; radius: 9; color: crumbHit.containsMouse ? Theme.raised : "transparent"
                            Label { id: crumb; anchors.centerIn: parent; text: parent.parent.modelData.name; color: Theme.dim; font.weight: 600 }
                            MouseArea { id: crumbHit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: { shell.active = panel.index; panel.go(parent.parent.modelData.path) } } } } }
                Row { visible: panel.peek !== ""; spacing: 10
                    Pill { implicitHeight: 30; icon: "chevron-left"; text: I18n.tr("Back"); onPressed: shell.hidePeek() }
                    Label { text: I18n.tr("A look"); font.weight: 700; anchors.verticalCenter: parent.verticalCenter } }
                // the sizes: what is measured and the way out
                Row { visible: panel.source !== null; spacing: 10
                    Pill { implicitHeight: 30; icon: "chevron-left"; text: I18n.tr("Back"); onPressed: shell.hideSizes() }
                    Pill { implicitHeight: 30; icon: "arrow-up"; text: I18n.tr("Up"); visible: panel.source !== null && (shell.real ? panel.source.path !== "/" : (shell.rootOf(panel.source.path) || {}).path !== panel.source.path)
                           onPressed: { const s = panel.source; s.up(); if (s.path.startsWith("/")) s.measure() } }
                    Label { text: panel.source ? I18n.tr("What fills {folder}", { folder: panel.source.path.split("/").pop() || "/" }) : ""; font.weight: 700; anchors.verticalCenter: parent.verticalCenter } } } }
        Item { id: ground; x: 12; y: 50; width: parent.width - 24; height: parent.height - 62; clip: true
            MouseArea { anchors.fill: parent; acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.BackButton | Qt.ForwardButton
                        onPressed: (m) => panel.groundPressed(m, Qt.point(m.x, m.y))
                        onPositionChanged: (m) => panel.bandMove(Qt.point(m.x, m.y))
                        onReleased: panel.banding = false
                        onClicked: (m) => { if (m.button === Qt.RightButton) { const q = mapToItem(overlay, m.x, m.y); shell.groundMenu(q.x, q.y) } }
                        onDoubleClicked: (m) => { if (m.button === Qt.LeftButton && !panel.source && panel.peek === "") panel.up() }
                        onWheel: (w) => { if (w.modifiers & Qt.ControlModifier) { panel.iconSize = Math.max(32, Math.min(256, panel.iconSize + (w.angleDelta.y > 0 ? 16 : -16))); shell.view = "icons" } else w.accepted = false } }
            // files dropped here, from the other panel or from any app: into this folder
            DropArea { id: groundDrop; anchors.fill: parent; keys: ["text/uri-list"]; enabled: panel.path.startsWith("/") && !panel.source && panel.peek === ""
                onDropped: (d) => shell.dropInto(d, panel.path, groundDrop) }
            Label { anchors.centerIn: parent; visible: panel.path.startsWith("/") && !panel.source && files.count === 0 && files.status === FolderListModel.Ready; text: I18n.tr("This folder is empty."); color: Theme.faint }
            // Disks and devices: every disk as KDE's Partition Manager shows it — a band of its partitions as wide as each
            // is, room no partition takes, and below a line for each with how full its file system really is
            Flickable { visible: panel.path === "disks:" && !panel.source; anchors.fill: parent; anchors.margins: 10; clip: true
                        contentHeight: diskCol.height + 20; boundsBehavior: Flickable.StopAtBounds
                onVisibleChanged: if (visible) disker.running = true
                Component.onCompleted: if (visible) disker.running = true
                Column { id: diskCol; width: parent.width; spacing: 22
                    Repeater { model: shell.disks
                        Column { id: dk; required property var modelData; width: diskCol.width; spacing: 10
                            readonly property var bands: modelData.parts.map(p => ({ part: p, start: p.start, size: p.size })).concat(modelData.free.map(f => ({ part: null, start: f.start, size: f.size }))).sort((a, b) => a.start - b.start)
                            Row { spacing: 12
                                Glyph { name: dk.modelData.removable || dk.modelData.tran === "usb" ? "usb" : "disc"; font.pixelSize: 26; color: Theme.gold; anchors.verticalCenter: parent.verticalCenter }
                                Column { spacing: 2
                                    Label { text: (dk.modelData.model || dk.modelData.name) + "  ·  " + shell.bytes(dk.modelData.size); font.pixelSize: 16; font.weight: 700 }
                                    Label { text: dk.modelData.path + (dk.modelData.tran ? "  ·  " + dk.modelData.tran.toUpperCase() : "") + (dk.modelData.table ? "  ·  " + dk.modelData.table.toUpperCase() : ""); color: Theme.dim; font.pixelSize: 12 } } }
                            // the band: each partition as wide as it is, how full it is darker inside; empty room hatched
                            Row { width: dk.width; height: 46; spacing: 3
                                Repeater { model: dk.bands
                                    Rectangle { required property var modelData; height: 46; radius: 8; clip: true
                                        width: Math.max(10, (dk.width - 3 * (dk.bands.length - 1)) * modelData.size / dk.modelData.size)
                                        color: modelData.part ? Qt.darker(shell.fsColours[modelData.part.fstype.split(" ")[0]] || Theme.dim, 1.6) : "transparent"
                                        border.width: modelData.part ? 0 : 1; border.color: Theme.line
                                        Rectangle { visible: modelData.part !== null && modelData.part.total > 0; height: parent.height; color: shell.fsColours[modelData.part ? modelData.part.fstype.split(" ")[0] : ""] || Theme.dim
                                                    width: modelData.part && modelData.part.total > 0 ? parent.width * modelData.part.used / modelData.part.total : 0 }
                                        Label { anchors.centerIn: parent; width: parent.width - 8; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; font.pixelSize: 11; font.weight: 600
                                                text: modelData.part ? (modelData.part.mount || modelData.part.name) : I18n.tr("unused") + " " + shell.bytes(modelData.size)
                                                color: modelData.part ? "#ffffff" : Theme.dim } } } }
                            // a line for each: name, file system, where it is, label, size, and how much of it is used
                            Repeater { model: dk.modelData.parts.concat(dk.modelData.free.map(f => ({ name: "", path: "", fstype: "", label: "", mount: "", start: f.start, size: f.size, used: 0, total: 0, unused: true })))
                                Rectangle { id: pr; required property var modelData; width: dk.width; height: 40; radius: 10; color: Theme.card
                                    readonly property real f: modelData.total > 0 ? modelData.used / modelData.total : 0
                                    Rectangle { x: 12; width: 10; height: 10; radius: 3; anchors.verticalCenter: parent.verticalCenter; color: pr.modelData.unused ? "transparent" : (shell.fsColours[pr.modelData.fstype.split(" ")[0]] || Theme.dim); border.width: pr.modelData.unused ? 1 : 0; border.color: Theme.dim }
                                    Label { x: 32; width: 110; anchors.verticalCenter: parent.verticalCenter; elide: Text.ElideRight; text: pr.modelData.unused ? I18n.tr("Unused room") : pr.modelData.path; font.weight: 600; font.pixelSize: 13 }
                                    Label { x: 148; width: 110; anchors.verticalCenter: parent.verticalCenter; elide: Text.ElideRight; color: Theme.dim; font.pixelSize: 12; text: pr.modelData.fstype }
                                    Label { x: 264; width: 110; anchors.verticalCenter: parent.verticalCenter; elide: Text.ElideRight; font.pixelSize: 12; text: pr.modelData.mount || (pr.modelData.locked ? I18n.tr("locked") : "") }
                                    Label { x: 380; width: 120; anchors.verticalCenter: parent.verticalCenter; elide: Text.ElideRight; color: Theme.dim; font.pixelSize: 12; text: pr.modelData.label }
                                    Label { x: 506; width: 70; anchors.verticalCenter: parent.verticalCenter; font.pixelSize: 12; text: shell.bytes(pr.modelData.size) }
                                    Rectangle { visible: pr.modelData.total > 0; x: 580; width: Math.max(60, parent.width - 580 - 130); height: 6; radius: 3; anchors.verticalCenter: parent.verticalCenter; color: Theme.line
                                        Rectangle { width: parent.width * pr.f; height: 6; radius: 3; color: shell.fullness(pr.f) } }
                                    Label { visible: pr.modelData.total > 0; anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter; font.pixelSize: 12
                                            text: I18n.tr("{used} of {all}", { used: shell.bytes(pr.modelData.used), all: shell.bytes(pr.modelData.total) }) } } } } }
                    Label { visible: shell.disks.length === 0; text: I18n.tr("Looking…"); color: Theme.dim }
                    Label { width: diskCol.width; wrapMode: Text.WordWrap; color: Theme.dim; font.pixelSize: 12
                            text: I18n.tr("Unused room is part of a disk no partition takes: nothing can be kept there until it gets one.") } } }
            // This computer: the user's folders and the disks, as tiles
            Flow { visible: panel.path === "computer:" && !panel.source; anchors.fill: parent; anchors.margins: 6; spacing: 12
                Repeater { model: shell.places.filter(p => p.kind !== "trash" && p.kind !== "favourite" && (p.path !== "/" || shell.real))
                    Rectangle { required property var modelData; width: 220; height: 76; radius: 16; color: tileHit.containsMouse ? Theme.raised : Theme.card
                        Glyph { x: 18; name: shell.placeIcons[parent.modelData.kind]; font.pixelSize: 26; color: Theme.gold; anchors.verticalCenter: parent.verticalCenter }
                        Column { x: 58; width: parent.width - 70; anchors.verticalCenter: parent.verticalCenter; spacing: 2
                            Label { width: parent.width; font.weight: 700; elide: Text.ElideRight; text: shell.drives.includes(parent.parent.modelData.kind) ? shell.driveName(parent.parent.modelData) : I18n.tr(shell.placeNames[parent.parent.modelData.kind]) }
                            Label { width: parent.width; color: Theme.dim; font.pixelSize: 12; elide: Text.ElideRight
                                    text: shell.drives.includes(parent.parent.modelData.kind) ? I18n.tr(shell.driveKinds[parent.parent.modelData.kind]) + (parent.parent.modelData.name.split(" · ")[1] ? " · " + parent.parent.modelData.name.split(" · ")[1] : "")
                                                                                                  + (parent.parent.modelData.path === "" ? " · " + I18n.tr("not connected") : "") : "" } }
                        MouseArea { id: tileHit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { shell.active = panel.index; shell.reach(parent.modelData) } } } } }
            // what fills the other panel's folder, as a map: a rectangle for each thing in it, as big as what it holds,
            // and inside each folder what it is made of. A press tells what it is; twice goes inside and measures there.
            Item { id: sized; visible: panel.source !== null; anchors.fill: parent
                readonly property var src: panel.source
                property string picked: ""
                property string hovered: ""
                readonly property string shown: hovered || picked
                onSrcChanged: { picked = ""; hovered = "" }
                function sizeOf(p) { if (!src) return 0; if (src.sizes[p] !== undefined) return src.sizes[p]; const up = p.replace(/\/[^/]+$/, "") || "/"; const f = (src.inner[up] || []).find(i => i.path === p); return f ? f.size : 0 }
                // what the measured folder itself is, from the nearest folder above that says (flatpak under .local)
                readonly property string rootKind: { if (!src) return "other"; let p = src.path
                    while (p.length > 1) { const k = shell.kindOf(p); if (k) return k; p = p.replace(/\/[^/]+$/, "") || "/" } return "other" }
                function kindIn(p) { const own = shell.kindOf(p); if (own || !src) return own
                                     if (rootKind !== "other") return rootKind
                                     const kids = (src.inner[p] || []).slice().sort((x, y) => y.size - x.size); return kids.length ? (shell.kindOf(kids[0].path) || "other") : "other" }
                function zoom(p) { const s = src; s.go(p); s.measure() }
                function gone(p) { shell.act(["trash", p]); const s = src; delete s.rawSizes[p]; const up = p.replace(/\/[^/]+$/, "")
                                   if (s.rawInner[up]) s.rawInner[up] = s.rawInner[up].filter(i => i.path !== p); if (s.whole > 0) s.whole -= sizeOf(p); s.settle(); picked = "" }
                // the head: how much in all, and how full the disk is
                Label { id: sum; y: 2; width: parent.width - diskBar.width - 12; elide: Text.ElideRight; color: Theme.dim; font.pixelSize: 12
                        text: sized.src ? (sized.src.measuring ? I18n.tr("measuring… {size} so far", { size: shell.bytes(sized.src.total) }) : I18n.tr("{size} in all", { size: shell.bytes(sized.src.total) })) : "" }
                Item { id: diskBar; anchors.right: parent.right; width: Math.min(260, parent.width * 0.45); height: 20; visible: sized.src && sized.src.disk !== null
                    readonly property var d: sized.src && sized.src.disk ? sized.src.disk : { size: 1, free: 0 }
                    Rectangle { y: 6; width: parent.width; height: 8; radius: 4; color: Theme.raised
                        Rectangle { height: parent.height; radius: 4; color: diskBar.d.free / diskBar.d.size < 0.1 ? Theme.red : Theme.coffee; width: parent.width * (1 - diskBar.d.free / diskBar.d.size) } }
                    Label { y: 16; anchors.right: parent.right; font.pixelSize: 11; color: Theme.faint; text: I18n.tr("{free} free of {size}", { free: shell.bytes(diskBar.d.free), size: shell.bytes(diskBar.d.size) }) } }
                // what the colours mean: only the kinds that are here
                Flow { id: legend; y: 36; width: parent.width; spacing: 12
                    Repeater { model: { if (!sized.src) return []; const seen = {}; for (const r of map.rects) seen[r.kind] = true; return shell.kinds.filter(k => seen[k.id]) }
                        Row { required property var modelData; spacing: 5
                            Rectangle { width: 10; height: 10; radius: 3; color: parent.modelData.color; anchors.verticalCenter: parent.verticalCenter }
                            Label { text: I18n.tr(parent.modelData.name); font.pixelSize: 11; color: Theme.dim } } } }
                Item { id: map; y: legend.y + legend.height + 8; width: parent.width; height: parent.height - y - foot.height - 8
                    // the rectangles: what is here first, then what each folder is made of, inside it
                    readonly property var rects: {
                        const s = sized.src; if (!s || width < 20 || height < 20) return []
                        const top = Object.keys(s.sizes).map(k => ({ path: k, size: s.sizes[k] })).sort((x, y) => y.size - x.size)
                        const whole = Math.max(s.total, top.reduce((t, i) => t + i.size, 0)), out = []
                        // a folder gets a head with its name when there is room, and inside it what it is made of
                        const lay = (items, x, y, w, h, of, level, kindUp) => {
                            for (const r of shell.squarify(items, x, y, w, h, of)) {
                                const kids = (s.inner[r.item.path] || []).slice().sort((p, q) => q.size - p.size)
                                const kind = level === 1 ? sized.kindIn(r.item.path) : (shell.kindOf(r.item.path) || (s.dirs[r.item.path] ? kindUp : "other"))
                                const deeper = kids.length && r.w > 30 && r.h > 34, head = deeper && r.h > 44 && r.w > 60 ? 18 : 0
                                out.push({ path: r.item.path, size: r.item.size, kind: kind, x: r.x, y: r.y, w: r.w, h: r.h, level: level, dir: !!s.dirs[r.item.path], head: head, full: !deeper })
                                if (deeper) lay(kids, r.x + 3, r.y + 3 + head, r.w - 6, r.h - 6 - head, r.item.size, level + 1, kind)
                            }
                        }
                        lay(top, 0, 0, width, height, whole, 1, sized.rootKind)
                        return out
                    }
                    Label { anchors.centerIn: parent; visible: map.rects.length === 0; color: Theme.faint; text: sized.src && sized.src.measuring ? I18n.tr("Measuring…") : I18n.tr("This folder is empty.") }
                    Repeater { model: map.rects
                        Rectangle { id: tile; required property var modelData
                            x: modelData.x + 1; y: modelData.y + 1; width: Math.max(1, modelData.w - 2); height: Math.max(1, modelData.h - 2); radius: modelData.level === 1 ? 7 : 4
                            readonly property color tint: shell.kindColor(modelData.kind)
                            color: modelData.full ? Qt.rgba(tint.r, tint.g, tint.b, tileHit.containsMouse ? 0.95 : 0.72) : Qt.rgba(tint.r, tint.g, tint.b, 0.20)
                            border.width: sized.picked === modelData.path ? 3 : 1; border.color: sized.picked === modelData.path ? Theme.gold : Qt.rgba(0, 0, 0, 0.35)
                            Behavior on x { NumberAnimation { duration: 180 } }
                            Behavior on y { NumberAnimation { duration: 180 } }
                            Behavior on width { NumberAnimation { duration: 180 } }
                            Behavior on height { NumberAnimation { duration: 180 } }
                            // what it is, when there is room to say it: the folder's name on its head, a thing's in its middle
                            Label { visible: tile.width > 54 && tile.height > 16 && (tile.modelData.head > 0 || tile.modelData.full); x: 6; y: tile.modelData.head > 0 ? 2 : 4; width: tile.width - 12; elide: Text.ElideMiddle
                                    text: tile.modelData.path.split("/").pop() + (tile.width > 140 ? "  " + shell.bytes(tile.modelData.size) : "")
                                    font.pixelSize: tile.modelData.level === 1 ? 12 : 11; font.weight: tile.modelData.level === 1 ? 700 : 500
                                    color: tile.modelData.full ? "#ffffff" : Theme.cream; style: Text.Raised; styleColor: Qt.rgba(0, 0, 0, 0.4) }
                            MouseArea { id: tileHit; anchors.fill: parent; hoverEnabled: true; cursorShape: tile.modelData.dir ? Qt.PointingHandCursor : Qt.ArrowCursor
                                        acceptedButtons: Qt.LeftButton | Qt.BackButton
                                        onEntered: sized.hovered = tile.modelData.path
                                        onExited: if (sized.hovered === tile.modelData.path) sized.hovered = ""
                                        onPressed: (m) => { shell.active = panel.index; if (m.button === Qt.BackButton) { shell.hideSizes(); return } sized.picked = tile.modelData.path }
                                        onDoubleClicked: if (tile.modelData.dir) sized.zoom(tile.modelData.path) } } } }
                // the foot: what is pointed at or chosen, and what can be done with it; with nothing, what is worth a look
                Rectangle { id: foot; anchors.bottom: parent.bottom; width: parent.width; height: 62; radius: 12; color: Theme.card
                    readonly property string p: sized.shown
                    readonly property real share: sized.src && sized.src.total > 0 ? sized.sizeOf(p) / sized.src.total : 0
                    Row { visible: foot.p !== ""; x: 12; spacing: 10; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 24
                        Rectangle { width: 14; height: 14; radius: 4; color: shell.kindColor(sized.kindIn(foot.p)); anchors.verticalCenter: parent.verticalCenter }
                        Column { width: parent.width - 24 - acts.width - 20; anchors.verticalCenter: parent.verticalCenter
                            Label { width: parent.width; elide: Text.ElideMiddle; font.weight: 700; text: foot.p.split("/").pop() }
                            Label { width: parent.width; elide: Text.ElideRight; font.pixelSize: 12; color: Theme.dim
                                    text: shell.bytes(sized.sizeOf(foot.p)) + "  ·  " + (foot.share * 100).toFixed(1) + " %  ·  " + I18n.tr((shell.kinds.find(k => k.id === sized.kindIn(foot.p)) || shell.kinds[shell.kinds.length - 1]).name) } }
                        Row { id: acts; spacing: 6; visible: sized.picked !== "" && foot.p === sized.picked; anchors.verticalCenter: parent.verticalCenter
                            Pill { implicitHeight: 30; icon: "chevron-right"; text: I18n.tr("Inside"); visible: sized.src && !!sized.src.dirs[sized.picked]; onPressed: sized.zoom(sized.picked) }
                            Pill { implicitHeight: 30; icon: "external-link"; text: I18n.tr("Open"); onPressed: { const p = sized.picked, s = sized.src
                                                                                                                  if (s.dirs[p]) { shell.hideSizes(); s.go(p) } else shell.open(p, false) } }
                            Pill { implicitHeight: 30; icon: "trash"; text: I18n.tr("Delete"); danger: true; onPressed: sized.gone(sized.picked) } } }
                    Column { visible: foot.p === ""; x: 12; width: parent.width - 24; anchors.verticalCenter: parent.verticalCenter; spacing: 4
                        readonly property var worth: { const s = sized.src; if (!s) return []; const all = []
                            for (const k in s.sizes) all.push({ path: k, size: s.sizes[k] })
                            for (const k in s.inner) for (const i of s.inner[k]) all.push(i)
                            return all.filter(i => i.size > 50 * 1048576 && shell.kindOf(i.path) === "cache").sort((x, y) => y.size - x.size).slice(0, 4) }
                        Label { font.pixelSize: 12; color: Theme.faint; text: parent.worth.length ? I18n.tr("Worth a look: these come back by themselves, or are already thrown away") : I18n.tr("Point at a rectangle to see what it is; twice on a folder goes inside.") }
                        Row { spacing: 6
                            Repeater { model: parent.parent.worth
                                Pill { required property var modelData; implicitHeight: 26; text: modelData.path.split("/").pop() + "  " + shell.bytes(modelData.size); onPressed: sized.picked = modelData.path } } } } } }
            // the column heads: a press sorts by that, again the other way
            Row { id: heads; visible: list.visible; width: parent.width; height: 26
                Repeater { model: [{ by: "name", name: QT_TR_NOOP("Name"), w: -250 }, { by: "size", name: QT_TR_NOOP("Size"), w: 100 }, { by: "date", name: QT_TR_NOOP("Date modified"), w: 150 }]
                    Rectangle { required property var modelData; width: modelData.w < 0 ? heads.width + modelData.w : modelData.w; height: 26; radius: 7; color: headHit.containsMouse ? Theme.card : "transparent"
                        Label { x: parent.modelData.by === "name" ? 42 : 0; width: parent.width - (parent.modelData.by === "name" ? 42 : 10); horizontalAlignment: parent.modelData.by === "size" ? Text.AlignRight : Text.AlignLeft
                                text: I18n.tr(parent.modelData.name) + (panel.sortBy === parent.modelData.by ? (panel.sortDown ? "  ↓" : "  ↑") : ""); color: panel.sortBy === parent.modelData.by ? Theme.gold : Theme.faint
                                font.pixelSize: 12; font.weight: 600; anchors.verticalCenter: parent.verticalCenter }
                        MouseArea { id: headHit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: panel.sort(parent.modelData.by) } } } }
            ListView { id: list; visible: shell.view === "details" && panel.path.startsWith("/") && !panel.source && panel.peek === ""; y: 28; width: parent.width; height: parent.height - 28; model: files; clip: true; boundsBehavior: Flickable.StopAtBounds
                MouseArea { z: -1; width: list.width; height: Math.max(list.height, list.contentHeight); preventStealing: true; acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.BackButton | Qt.ForwardButton
                    onPressed: (m) => panel.groundPressed(m, mapToItem(ground, m.x, m.y))
                    onPositionChanged: (m) => panel.bandMove(mapToItem(ground, m.x, m.y))
                    onReleased: panel.banding = false
                    onClicked: (m) => { if (m.button === Qt.RightButton) { const q = mapToItem(overlay, m.x, m.y); shell.groundMenu(q.x, q.y) } }
                    onDoubleClicked: (m) => { if (m.button === Qt.LeftButton) panel.up() } }
                delegate: Rectangle { id: row; required property string fileName
                    required property string filePath
                    required property bool fileIsDir
                    required property var fileSize
                    required property date fileModified
                    required property int index
                    width: list.width; height: 34; radius: 9
                    readonly property color tint: shell.colourOf(panel.tags[filePath])     // its colour, if it has one: the row takes it on
                    color: panel.chosen[filePath] ? Qt.rgba(Theme.gold.r, Theme.gold.g, Theme.gold.b, 0.24) : (rowHit.containsMouse ? Theme.card : (panel.tags[filePath] ? Qt.rgba(tint.r, tint.g, tint.b, 0.16) : "transparent"))
                    // measured: its share of the largest thing here, as a bar behind the row
                    Rectangle { visible: panel.measured && panel.sizes[row.filePath] !== undefined; x: 4; y: 4; height: parent.height - 8; radius: 6; color: Theme.coffee; opacity: 0.38
                                width: (parent.width - 8) * (panel.sizes[row.filePath] || 0) / panel.largest; Behavior on width { NumberAnimation { duration: 220 } } }
                    Rectangle { visible: !!panel.tags[row.filePath]; x: 2; y: 7; width: 4; height: parent.height - 14; radius: 2; color: shell.colourOf(panel.tags[row.filePath]) }
                    Image { x: 10; width: 22; height: 22; anchors.verticalCenter: parent.verticalCenter; source: FileIcons.of(row.fileName, row.filePath, row.fileIsDir); sourceSize.width: 44; sourceSize.height: 44; asynchronous: true }
                    Label { id: rowName; x: 42; width: parent.width - 42 - 250; text: row.fileName; anchors.verticalCenter: parent.verticalCenter; elide: Text.ElideMiddle }
                    Label { x: parent.width - 240; width: 90; horizontalAlignment: Text.AlignRight; text: panel.sizes[row.filePath] !== undefined ? shell.bytes(panel.sizes[row.filePath]) : (row.fileIsDir ? (panel.measured ? "…" : "") : shell.bytes(row.fileSize))
                            color: panel.measured ? Theme.cream : Theme.dim; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                    Label { x: parent.width - 140; width: 130; text: Qt.formatDateTime(row.fileModified, "d. M. yyyy  hh:mm"); color: Theme.dim; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                    Rectangle { anchors.fill: parent; radius: 9; color: "transparent"; border.width: 2; border.color: Theme.gold; visible: rowDrop.containsDrag }
                    DropArea { id: rowDrop; anchors.fill: parent; keys: ["text/uri-list"]; enabled: row.fileIsDir; onDropped: (d) => shell.dropInto(d, row.filePath, rowDrop) }
                    MouseArea { id: rowHit; anchors.fill: parent; hoverEnabled: true; preventStealing: true; acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton | Qt.BackButton | Qt.ForwardButton
                        property point from
                        property bool bare: false
                        onPressed: (m) => { bare = m.button === Qt.LeftButton && m.x > 42 + Math.min(rowName.width, rowName.contentWidth) + 24 && m.x < parent.width - 250
                                            if (bare) return panel.groundPressed(m, mapToItem(ground, m.x, m.y))
                                            keys.forceActiveFocus(); shell.active = panel.index; from = Qt.point(m.x, m.y); if (panel.extra(m) || m.button === Qt.MiddleButton) return
                                            if (m.button === Qt.LeftButton || !panel.chosen[row.filePath]) panel.press(row.filePath, row.index, m.button === Qt.LeftButton ? m.modifiers : 0) }
                        onReleased: panel.banding = false
                        onPositionChanged: (m) => { if (panel.banding) return panel.bandMove(mapToItem(ground, m.x, m.y))
                                                    if ((m.buttons & (Qt.LeftButton | Qt.RightButton)) && Math.abs(m.x - from.x) + Math.abs(m.y - from.y) > 10) shell.drag(panel.carried(row.filePath), !!(m.buttons & Qt.RightButton)) }
                        onClicked: (m) => { if (m.button === Qt.RightButton) { const q = mapToItem(overlay, m.x, m.y); shell.itemMenu(row.filePath, row.fileIsDir, q.x, q.y) }
                                            else if (m.button === Qt.MiddleButton && row.fileIsDir) { shell.dual = true; shell.other.go(row.filePath) } }
                        onDoubleClicked: (m) => { if (m.button === Qt.LeftButton && !bare) shell.open(row.filePath, row.fileIsDir) } } } }
            GridView { id: grid; visible: shell.view !== "details" && shell.view !== "photos" && panel.path.startsWith("/") && !panel.source && panel.peek === ""; anchors.fill: parent; model: files; clip: true
                readonly property bool wide: shell.view === "small" || shell.view === "tiles"     // the icon left, the name beside it
                readonly property real icon: shell.view === "small" ? 20 : (shell.view === "tiles" ? 48 : panel.iconSize)
                cellWidth: shell.view === "small" ? 250 : (shell.view === "tiles" ? 300 : panel.iconSize + 60)
                cellHeight: shell.view === "small" ? 32 : (shell.view === "tiles" ? 72 : panel.iconSize + 56); boundsBehavior: Flickable.StopAtBounds
                MouseArea { z: -1; width: grid.width; height: Math.max(grid.height, grid.contentHeight); preventStealing: true; acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.BackButton | Qt.ForwardButton
                    onPressed: (m) => panel.groundPressed(m, mapToItem(ground, m.x, m.y))
                    onPositionChanged: (m) => panel.bandMove(mapToItem(ground, m.x, m.y))
                    onReleased: panel.banding = false
                    onClicked: (m) => { if (m.button === Qt.RightButton) { const q = mapToItem(overlay, m.x, m.y); shell.groundMenu(q.x, q.y) } }
                    onDoubleClicked: (m) => { if (m.button === Qt.LeftButton) panel.up() } }
                delegate: Item { id: cell; required property string fileName
                    required property string filePath
                    required property bool fileIsDir
                    required property var fileSize
                    required property int index
                    readonly property bool roomy: !grid.wide && panel.iconSize >= 96
                    width: grid.cellWidth; height: grid.cellHeight
                    Rectangle { anchors.fill: parent; anchors.margins: 3; radius: 10; border.width: cellDrop.containsDrag ? 2 : 0; border.color: Theme.gold; color: panel.chosen[cell.filePath] ? Qt.rgba(Theme.gold.r, Theme.gold.g, Theme.gold.b, 0.24) : (cellHit.containsMouse ? Theme.card
                                      : (panel.tags[cell.filePath] ? Qt.rgba(Qt.color(shell.colourOf(panel.tags[cell.filePath])).r, Qt.color(shell.colourOf(panel.tags[cell.filePath])).g, Qt.color(shell.colourOf(panel.tags[cell.filePath])).b, 0.16) : "transparent")) }
                    Image { id: cellIcon; x: grid.wide ? 10 : (parent.width - width) / 2; y: grid.wide ? (parent.height - height) / 2 : 10; width: grid.icon; height: grid.icon
                            source: FileIcons.of(cell.fileName, cell.filePath, cell.fileIsDir); sourceSize.width: Math.max(64, grid.icon * 2); sourceSize.height: Math.max(64, grid.icon * 2); fillMode: Image.PreserveAspectFit; asynchronous: true }
                    Rectangle { visible: !!panel.tags[cell.filePath]; z: 2; width: Math.max(10, grid.icon * 0.16); height: width; radius: width / 2; border.width: 2; border.color: Theme.surface
                                x: cellIcon.x + cellIcon.width - width * 0.8; y: cellIcon.y + cellIcon.height - height * 0.9; color: shell.colourOf(panel.tags[cell.filePath]) }
                    // a folder shows the pictures it holds, as Explorer's do, once the icons are big enough to see them
                    FolderListModel { id: inside; folder: cell.fileIsDir && cell.roomy ? "file://" + cell.filePath : ""; showDirs: false; sortField: FolderListModel.Time
                                      nameFilters: FileIcons.pictures.map(e => "*." + e).concat(FileIcons.pictures.map(e => "*." + e.toUpperCase())) }
                    Repeater { model: cell.roomy ? Math.min(2, inside.count) : 0
                        Image { required property int index; asynchronous: true; fillMode: Image.PreserveAspectCrop; sourceSize.width: 256
                                source: "file://" + inside.get(index, "filePath"); width: cellIcon.width * 0.46; height: cellIcon.height * 0.52
                                x: cellIcon.x + cellIcon.width * (0.18 + 0.26 * index); y: cellIcon.y + cellIcon.height * (0.30 - 0.04 * index); rotation: index ? 6 : -4
                                Rectangle { anchors.fill: parent; color: "transparent"; border.width: 2; border.color: "#f3ebdd" } } }
                    Column { id: cellText; x: grid.wide ? cellIcon.width + 20 : 6; y: grid.wide ? (parent.height - height) / 2 : grid.icon + 14; width: grid.wide ? parent.width - cellIcon.width - 28 : parent.width - 12; spacing: 2
                        Label { id: cellName; width: parent.width; horizontalAlignment: grid.wide ? Text.AlignLeft : Text.AlignHCenter; text: cell.fileName; font.pixelSize: grid.wide ? 13 : 12
                                wrapMode: grid.wide ? Text.NoWrap : Text.WrapAnywhere; elide: grid.wide ? Text.ElideMiddle : Text.ElideNone; maximumLineCount: grid.wide ? 1 : 2 }
                        Label { visible: shell.view === "tiles"; width: parent.width; elide: Text.ElideRight; color: Theme.dim; font.pixelSize: 11
                                text: cell.fileIsDir ? I18n.tr("File folder") : I18n.tr("{ext} file", { ext: FileIcons.ending(cell.fileName).toUpperCase() || "—" }) }
                        Label { visible: shell.view === "tiles" && !cell.fileIsDir; width: parent.width; color: Theme.faint; font.pixelSize: 11; text: shell.bytes(cell.fileSize) } }
                    DropArea { id: cellDrop; anchors.fill: parent; keys: ["text/uri-list"]; enabled: cell.fileIsDir; onDropped: (d) => shell.dropInto(d, cell.filePath, cellDrop) }
                    MouseArea { id: cellHit; anchors.fill: parent; hoverEnabled: true; preventStealing: true; acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton | Qt.BackButton | Qt.ForwardButton
                        property point from
                        property bool bare: false
                        onPressed: (m) => { bare = m.button === Qt.LeftButton && (grid.wide ? m.x > cellText.x + Math.min(cellText.width, cellName.contentWidth) + 10
                                                                                       : Math.abs(m.x - width / 2) > Math.max(grid.icon, cellName.contentWidth) / 2 + 6)
                                            if (bare) return panel.groundPressed(m, mapToItem(ground, m.x, m.y))
                                            keys.forceActiveFocus(); shell.active = panel.index; from = Qt.point(m.x, m.y); if (panel.extra(m) || m.button === Qt.MiddleButton) return
                                            if (m.button === Qt.LeftButton || !panel.chosen[cell.filePath]) panel.press(cell.filePath, cell.index, m.button === Qt.LeftButton ? m.modifiers : 0) }
                        onReleased: panel.banding = false
                        onPositionChanged: (m) => { if (panel.banding) return panel.bandMove(mapToItem(ground, m.x, m.y))
                                                    if ((m.buttons & (Qt.LeftButton | Qt.RightButton)) && Math.abs(m.x - from.x) + Math.abs(m.y - from.y) > 10) shell.drag(panel.carried(cell.filePath), !!(m.buttons & Qt.RightButton)) }
                        onClicked: (m) => { if (m.button === Qt.RightButton) { const q = mapToItem(overlay, m.x, m.y); shell.itemMenu(cell.filePath, cell.fileIsDir, q.x, q.y) }
                                            else if (m.button === Qt.MiddleButton && cell.fileIsDir) { shell.dual = true; shell.other.go(cell.filePath) } }
                        onDoubleClicked: (m) => { if (m.button === Qt.LeftButton && !bare) shell.open(cell.filePath, cell.fileIsDir) } } } }
            // the photo viewer, as the old ACDSee had it: one picture big, the folder's pictures along the bottom; the
            // wheel and the arrows go through them, twice on the picture hides the strip, a slideshow if one wants
            Item { id: photos; visible: shell.view === "photos" && panel.path.startsWith("/") && !panel.source && panel.peek === ""; anchors.fill: parent
                property int at: 0
                property bool bare: false
                readonly property string current: pics.count > 0 ? pics.get(Math.min(at, pics.count - 1), "filePath") : ""
                function step(d) { if (!pics.count) return; at = (at + d + pics.count) % pics.count; strip.positionViewAtIndex(at, ListView.Contain)
                                   const s = {}; s[current] = true; panel.chosen = s }
                Connections { target: panel; function onPathChanged() { photos.at = 0 } }
                // the picture shown is the one chosen, so the coffee at the foot tells what it is
                onVisibleChanged: if (visible) Qt.callLater(() => photos.step(0))
                Connections { target: pics; function onCountChanged() { if (photos.visible && pics.count > 0) Qt.callLater(() => photos.step(0)) } }
                FolderListModel { id: pics; folder: photos.visible ? "file://" + panel.path : ""; showDirs: false; showHidden: shell.hidden
                                  nameFilters: FileIcons.pictures.concat(["bmp", "svg"]).map(e => "*." + e).concat(FileIcons.pictures.map(e => "*." + e.toUpperCase())) }
                Rectangle { id: stage; width: parent.width; height: photos.bare ? parent.height : parent.height - strip.height - info.height - 16; radius: 12; color: Qt.rgba(0, 0, 0, 0.35)
                    Image { id: big; anchors.fill: parent; anchors.margins: 6; source: photos.current !== "" ? "file://" + photos.current : ""; fillMode: Image.PreserveAspectFit
                            asynchronous: true; autoTransform: true; smooth: true; mipmap: true }
                    Label { anchors.centerIn: parent; visible: pics.count === 0; color: Theme.faint; text: I18n.tr("No pictures in this folder.") }
                    MouseArea { anchors.fill: parent; acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.BackButton | Qt.ForwardButton
                        onPressed: (m) => { shell.active = panel.index; keys.forceActiveFocus(); if (m.button === Qt.BackButton) photos.step(-1); else if (m.button === Qt.ForwardButton) photos.step(1) }
                        onClicked: (m) => { if (m.button === Qt.RightButton && photos.current !== "") { const q = mapToItem(overlay, m.x, m.y); const s = {}; s[photos.current] = true; panel.chosen = s; shell.itemMenu(photos.current, false, q.x, q.y) } }
                        onDoubleClicked: photos.bare = !photos.bare
                        onWheel: (w) => photos.step(w.angleDelta.y > 0 ? -1 : 1) }
                    // the way back and on, on the sides of the picture
                    Repeater { model: [-1, 1]
                        Rectangle { required property var modelData; visible: pics.count > 1; width: 44; height: 64; radius: 12; anchors.verticalCenter: parent.verticalCenter
                                    x: modelData < 0 ? 10 : parent.width - width - 10; color: arrowHit.containsMouse ? Qt.rgba(0, 0, 0, 0.55) : Qt.rgba(0, 0, 0, 0.25)
                            Glyph { anchors.centerIn: parent; name: parent.modelData < 0 ? "chevron-left" : "chevron-right"; font.pixelSize: 24; color: "#f3ebdd" }
                            MouseArea { id: arrowHit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: photos.step(parent.modelData) } } } }
                Row { id: info; visible: !photos.bare; y: stage.height + 8; width: parent.width; height: 32; spacing: 10
                    Pill { implicitHeight: 30; icon: slides.running ? "player-pause" : "slideshow"; text: slides.running ? I18n.tr("Pause") : I18n.tr("Slideshow"); onPressed: slides.running = !slides.running }
                    // what the picture is, the coffee at the foot says
                    Label { anchors.verticalCenter: parent.verticalCenter; color: Theme.dim; font.pixelSize: 12; text: pics.count === 0 ? "" : (photos.at + 1) + " / " + pics.count } }
                Timer { id: slides; interval: 4000; repeat: true; running: false; onTriggered: photos.step(1) }
                ListView { id: strip; visible: !photos.bare; anchors.bottom: parent.bottom; width: parent.width; height: 96; orientation: ListView.Horizontal; spacing: 6; clip: true
                           model: pics; boundsBehavior: Flickable.StopAtBounds
                    delegate: Rectangle { id: thumb; required property string filePath; required property int index
                        width: 120; height: 92; radius: 8; color: Theme.card; border.width: photos.at === index ? 3 : 0; border.color: Theme.gold
                        Image { anchors.fill: parent; anchors.margins: 4; source: "file://" + thumb.filePath; fillMode: Image.PreserveAspectCrop; asynchronous: true; sourceSize.width: 240; autoTransform: true }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { photos.at = thumb.index; photos.step(0) }
                                    onDoubleClicked: shell.open(thumb.filePath, false) } } } }
            Rectangle { visible: panel.banding && panel.band.width + panel.band.height > 4; z: 5; x: panel.band.x; y: panel.band.y; width: panel.band.width; height: panel.band.height
                        radius: 4; color: Qt.rgba(Theme.gold.r, Theme.gold.g, Theme.gold.b, 0.14); border.width: 1; border.color: Theme.gold }
            // a look at one file: a picture as it is, the beginning of a text, else what it is
            Item { id: look; visible: panel.peek !== ""; anchors.fill: parent
                readonly property string name: panel.peek.split("/").pop()
                readonly property string kind: FileIcons.ending(name)
                readonly property bool picture: FileIcons.pictures.includes(kind) || ["svg", "bmp"].includes(kind)
                readonly property bool paged: ["pdf", "mp4", "mkv", "webm", "avi", "mov", "m4v", "wmv", "flv", "mpg", "mpeg"].includes(kind)
                readonly property string still: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/dualbrew-look-" + panel.index + ".png"
                property int took: 0
                // started by hand with the file named then: a bound command may still name the one before
                Process { id: lookStill
                          onExited: (code) => { if (code === 0) look.took++ } }
                readonly property bool texty: ["txt", "md", "log", "json", "toml", "ini", "conf", "sh", "py", "lua", "luau", "qml", "js", "c", "h", "cpp", "rs", "csv", "xml", "html", "css", "yaml", "yml", "desktop", "plm"].includes(kind)
                Image { visible: look.picture; anchors.fill: parent; anchors.margins: 8; anchors.bottomMargin: 70; source: look.picture ? "file://" + panel.peek : ""; fillMode: Image.PreserveAspectFit; asynchronous: true; sourceSize.width: 1600 }
                // only its beginning: a log of gigabytes is looked at as fast as a note
                Process { id: lookText; command: ["head", "-c", "20000", "--", panel.peek]; running: look.texty && panel.peek !== ""
                          stdout: StdioCollector { onStreamFinished: lookBody.text = this.text } }
                onNameChanged: { lookBody.text = ""; if (look.texty) { lookText.running = false; lookText.running = true }
                                 look.took = 0
                                 if (look.paged && panel.peek !== "") { lookStill.running = false; lookStill.command = ["latte-files", "look", panel.peek, look.still]; lookStill.running = true } }
                Image { visible: look.paged && look.took > 0; anchors.fill: parent; anchors.margins: 8; anchors.bottomMargin: 70; fillMode: Image.PreserveAspectFit; asynchronous: true; cache: false
                        source: look.paged && look.took > 0 ? "file://" + look.still : "" }
                Flickable { visible: look.texty; anchors.fill: parent; anchors.margins: 8; anchors.bottomMargin: 70; contentHeight: lookBody.implicitHeight; clip: true
                    Text { id: lookBody; width: parent.width; wrapMode: Text.WrapAnywhere; color: Theme.cream; font.family: "JetBrains Mono"; font.pixelSize: 12 } }
                Column { visible: !look.picture && !look.texty && !(look.paged && look.took > 0); anchors.centerIn: parent; spacing: 12
                    Image { width: 128; height: 128; anchors.horizontalCenter: parent.horizontalCenter; source: panel.peek !== "" ? FileIcons.of(look.name, panel.peek, false) : ""; sourceSize.width: 256; sourceSize.height: 256 }
                    Label { anchors.horizontalCenter: parent.horizontalCenter; text: I18n.tr("No look inside this kind of file."); color: Theme.dim } }
                Row { anchors.bottom: parent.bottom; anchors.bottomMargin: 14; x: 8; spacing: 10
                    Pill { icon: "external-link"; strong: true; text: I18n.tr("Open"); onPressed: shell.open(panel.peek, false) }
                    Label { text: look.name; font.weight: 700; width: Math.max(0, look.width - 160); anchors.verticalCenter: parent.verticalCenter; elide: Text.ElideMiddle } } }
        }
        // The panel one is not working in lies under the coffee: a veil of it, darker towards the bottom, with the
        // line of its surface along the top. It takes no press: a press there brings the panel up.
        Item { anchors.fill: parent; anchors.margins: 6; visible: shell.dual; opacity: panel.isActive ? 0 : 1
            Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
            Rectangle { anchors.fill: parent; radius: 14
                gradient: Gradient { GradientStop { position: 0; color: Qt.rgba(Theme.coffee.r, Theme.coffee.g, Theme.coffee.b, 0.10) } GradientStop { position: 1; color: Qt.rgba(Theme.coffee.r * 0.5, Theme.coffee.g * 0.4, Theme.coffee.b * 0.3, 0.55) } } }
            Rectangle { x: 14; y: 2; width: parent.width - 28; height: 2; radius: 1; color: Theme.coffee; opacity: 0.8 } }
    }

    AppWindow {
        id: win
        title: "DualBrew"
        heading: here.source ? I18n.tr("Sizes") : here.path === "disks:" ? I18n.tr("Disks and devices") : (here.path === "computer:" ? I18n.tr("This computer") : (here.path === shell.home ? I18n.tr("Home") : (here.path.split("/").pop() || "/")))
        implicitWidth: 1180; implicitHeight: 760
        arrows: true; canGoBack: here.before.length > 0; onBack: here.back(); canGoForward: here.ahead.length > 0; onForward: here.forward()
        tools: [
            Pill { implicitHeight: 34; icon: "arrow-up"; text: I18n.tr("Up"); onPressed: here.up() },
            Pill { implicitHeight: 34; icon: "folder-plus"; text: I18n.tr("New folder"); onPressed: shell.ask("folder") },
            Pill { id: viewPill; implicitHeight: 34; icon: shell.view === "details" ? "list" : "layout-grid"; text: I18n.tr("View")
                   onPressed: { const q = viewPill.mapToItem(overlay, 0, viewPill.height + 4); menu.open(q.x, Math.max(0, q.y), shell.views()) } },
            Pill { implicitHeight: 34; icon: "layout-columns"; text: I18n.tr("Two panels"); strong: shell.dual; onPressed: { shell.dual = !shell.dual; if (!shell.dual) shell.active = 0 } }
        ]
        side: [
            Column { x: 14; y: 14; spacing: 4
                Row { x: 6; spacing: 10; height: 40
                    Glyph { name: "folders"; color: Theme.gold; font.pixelSize: 22; anchors.verticalCenter: parent.verticalCenter }
                    Label { text: "DualBrew"; font.pixelSize: 17; font.weight: 800; anchors.verticalCenter: parent.verticalCenter } }
                Item { width: 1; height: 6 }
                Nav { text: I18n.tr("This computer"); icon: "device-desktop"; on: here.path === "computer:"; onPressed: here.go("computer:") }
                Repeater { model: shell.places.filter(p => !shell.drives.includes(p.kind) && p.kind !== "favourite")
                    Nav { required property var modelData; text: I18n.tr(shell.placeNames[modelData.kind]); icon: shell.placeIcons[modelData.kind]; on: here.path === modelData.path; onPressed: here.go(modelData.path) } }
                Label { x: 8; height: 30; verticalAlignment: Text.AlignBottom; text: I18n.tr("FAVOURITES"); color: Theme.faint; font.pixelSize: 11; font.weight: 700; font.letterSpacing: 0.8 }
                Repeater { model: shell.places.filter(p => p.kind === "favourite")
                    Nav { required property var modelData; text: modelData.name; icon: "star"; on: here.path === modelData.path; onPressed: here.go(modelData.path)
                          tail: "x"; onTailPressed: shell.pin(modelData.path, false) } }
                Nav { text: I18n.tr("Add a favourite folder"); icon: "star"; opacity: 0.75; visible: here.path.startsWith("/") && !shell.places.some(p => p.kind === "favourite" && p.path === here.path)
                      onPressed: shell.pin(here.path, true) }
                // the heading opens the overview of every disk, its partitions and how full each is
                Rectangle { width: 222; height: 30; radius: 8; color: drivesHit.containsMouse || here.path === "disks:" ? Theme.card : "transparent"
                    Label { x: 8; anchors.bottom: parent.bottom; anchors.bottomMargin: 4; text: I18n.tr("DRIVES"); color: here.path === "disks:" ? Theme.gold : (drivesHit.containsMouse ? Theme.cream : Theme.faint); font.pixelSize: 11; font.weight: 700; font.letterSpacing: 0.8 }
                    Glyph { anchors.right: parent.right; anchors.rightMargin: 8; anchors.bottom: parent.bottom; anchors.bottomMargin: 3; name: "chart-pie"; font.pixelSize: 14; color: drivesHit.containsMouse || here.path === "disks:" ? Theme.gold : Theme.faint }
                    MouseArea { id: drivesHit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: here.go("disks:") } }
                Repeater { model: shell.places.filter(p => ["disk", "usb", "card", "optical", "image"].includes(p.kind) && (p.path !== "/" || shell.real))
                    Column { id: drv; required property var modelData; spacing: 0
                        Nav { text: shell.driveName(parent.modelData) + (parent.modelData.name.split(" · ")[1] ? " · " + parent.modelData.name.split(" · ")[1] : ""); icon: shell.placeIcons[parent.modelData.kind]
                              opacity: parent.modelData.path === "" ? 0.6 : 1; on: parent.modelData.path !== "" && here.path === parent.modelData.path; onPressed: shell.reach(parent.modelData)
                              tail: shell.canEject(parent.modelData) ? "player-eject" : ""; onTailPressed: shell.eject(parent.modelData) }
                        // how full it is: a line under its name, and what is left
                        Item { visible: drv.modelData.total > 0; width: 222; height: 18
                            readonly property real f: drv.modelData.total > 0 ? drv.modelData.used / drv.modelData.total : 0
                            Rectangle { x: 44; y: 2; width: 80; height: 5; radius: 3; color: Theme.line
                                Rectangle { width: parent.width * parent.parent.f; height: 5; radius: 3; color: shell.fullness(parent.parent.f) } }
                            Label { x: 130; y: -3; width: 90; elide: Text.ElideRight; text: I18n.tr("{n} free", { n: shell.bytes(drv.modelData.total - drv.modelData.used) }); color: Theme.faint; font.pixelSize: 10 } } } }
                Label { x: 8; height: 30; verticalAlignment: Text.AlignBottom; text: I18n.tr("NETWORK AND CLOUD"); color: Theme.faint; font.pixelSize: 11; font.weight: 700; font.letterSpacing: 0.8 }
                Repeater { model: shell.places.filter(p => p.kind === "network" || p.kind === "cloud")
                    Nav { required property var modelData; text: shell.driveName(modelData); icon: shell.placeIcons[modelData.kind]
                          opacity: modelData.path === "" ? 0.6 : 1; on: modelData.path !== "" && here.path === modelData.path; onPressed: shell.reach(modelData)
                          tail: shell.canEject(modelData) ? "player-eject" : ""; onTailPressed: shell.eject(modelData) } }
                Nav { id: cloudNav; text: I18n.tr("Add a cloud or a place…"); icon: "cloud-plus"; onPressed: { const q = cloudNav.mapToItem(overlay, 40, cloudNav.height); shell.addCloud(q.x, q.y) } }
                Item { width: 1; height: 10 }
                Nav { text: I18n.tr("The real structure"); icon: shell.real ? "eye" : "eye-off"; on: shell.real; onPressed: shell.real = !shell.real } }
        ]
        foot: [
            // what is here and what is chosen
            Label { x: 24; anchors.verticalCenter: parent.verticalCenter; color: Theme.inkOnCoffee; visible: shell.asking === "" && !(shell.aboutFor !== "" && here.picked().length === 1)
                    text: !here.path.startsWith("/") ? I18n.tr("Your folders and the disks")
                          : (here.picked().length ? I18n.tr("{n} chosen", { n: here.picked().length }) : I18n.tr("{n} items", { n: here.count }))
                            + (here.measured ? "   ·   " + (here.measuring ? I18n.tr("measuring… {size} so far", { size: shell.bytes(here.total) }) : I18n.tr("{size} in all", { size: shell.bytes(here.total) }))
                                             : (here.picked().length ? "" : "   ·   " + I18n.tr("Space: how much each folder holds"))) },
            // the one chosen: what it is (a picture's size and camera, a folder's items and size)
            Row { x: 24; anchors.verticalCenter: parent.verticalCenter; spacing: 10; visible: shell.asking === "" && shell.aboutFor !== "" && here.picked().length === 1
                Image { width: 22; height: 22; anchors.verticalCenter: parent.verticalCenter; sourceSize.width: 44; sourceSize.height: 44; asynchronous: true
                        source: shell.aboutFor !== "" ? FileIcons.of(shell.aboutFor.split("/").pop(), shell.aboutFor, shell.about.items !== undefined) : "" }
                Label { anchors.verticalCenter: parent.verticalCenter; color: Theme.inkOnCoffee; elide: Text.ElideMiddle; text: shell.aboutText()
                        width: Math.min(implicitWidth, win.width - 300 - (shell.job ? 660 : (shell.dual ? 580 : 0))) } },
            // a job under way: what, how far, pause, stop; how many wait
            Row { anchors.right: parent.right; anchors.rightMargin: 20; anchors.verticalCenter: parent.verticalCenter; spacing: 10; visible: shell.job !== null && shell.asking === ""
                Column { width: 360; spacing: 5; anchors.verticalCenter: parent.verticalCenter
                    Label { width: parent.width; color: Theme.inkOnCoffee; font.pixelSize: 12; elide: Text.ElideMiddle
                            text: shell.job ? ((shell.job.paused ? I18n.tr("Paused") + " · " : "") + shell.job.title + (shell.jobs.length ? "   (+" + shell.jobs.length + ")" : "")) : "" }
                    Rectangle { width: parent.width; height: 6; radius: 3; color: Qt.rgba(0, 0, 0, 0.3)
                        Rectangle { height: 6; radius: 3; color: Theme.gold; width: parent.width * (shell.job && shell.job.total > 0 ? Math.min(1, shell.job.done / shell.job.total) : 0); Behavior on width { NumberAnimation { duration: 380 } } } } }
                Label { color: Theme.inkOnCoffee; font.weight: 700; anchors.verticalCenter: parent.verticalCenter; text: shell.job && shell.job.total > 0 ? Math.round(100 * Math.min(1, shell.job.done / shell.job.total)) + " %" : "" }
                Pill { implicitHeight: 32; icon: shell.job && shell.job.paused ? "player-play" : "player-pause"; text: shell.job && shell.job.paused ? I18n.tr("Go on") : I18n.tr("Pause"); onPressed: shell.pauseJob() }
                Pill { implicitHeight: 32; icon: "x"; danger: true; text: I18n.tr("Stop"); onPressed: shell.stopJob() } },
            // the commander's keys, with two panels
            Row { anchors.right: parent.right; anchors.rightMargin: 20; anchors.verticalCenter: parent.verticalCenter; spacing: 8; visible: shell.dual && shell.asking === "" && shell.job === null
                Repeater { model: [{ key: "F5", name: QT_TR_NOOP("Copy"), what: "copy" }, { key: "F6", name: QT_TR_NOOP("Move"), what: "move" }, { key: "F7", name: QT_TR_NOOP("New folder"), what: "folder" }, { key: "F8", name: QT_TR_NOOP("Delete"), what: "trash" }]
                    Pill { required property var modelData; implicitHeight: 32; text: modelData.key + "  " + I18n.tr(modelData.name); onPressed: shell.command(modelData.what) } } },
            // a name is asked for here
            Row { x: 24; anchors.verticalCenter: parent.verticalCenter; spacing: 10; visible: shell.asking !== ""
                Label { text: shell.asking === "rename" ? I18n.tr("New name:") : (shell.asking === "server" ? I18n.tr("Address:") : I18n.tr("Name:")); color: Theme.inkOnCoffee; anchors.verticalCenter: parent.verticalCenter }
                Field { id: answer; width: 360; icon: "pencil"; function focusIt() { children[1].forceActiveFocus(); children[1].selectAll() }
                        onAccepted: { shell.answered(text); keys.forceActiveFocus() } }
                Pill { implicitHeight: 34; icon: "check"; strong: true; text: I18n.tr("OK"); onPressed: { shell.answered(answer.text); keys.forceActiveFocus() } }
                Pill { implicitHeight: 34; icon: "x"; text: I18n.tr("Cancel"); onPressed: { shell.asking = ""; keys.forceActiveFocus() } } }
        ]

        Item { id: keys; anchors.fill: parent; focus: true
            Keys.onPressed: (ev) => {
                if (shell.asking !== "") { if (ev.key === Qt.Key_Escape) { shell.asking = ""; ev.accepted = true } return }
                const ctrl = ev.modifiers & Qt.ControlModifier, picked = here.picked(), one = picked.length === 1 ? picked[0] : ""
                ev.accepted = true
                if (shell.view === "photos" && [Qt.Key_Right, Qt.Key_PageDown, Qt.Key_Left, Qt.Key_PageUp].includes(ev.key)) here.photoStep([Qt.Key_Right, Qt.Key_PageDown].includes(ev.key) ? 1 : -1)
                else if (ev.key === Qt.Key_Space && shell.peeking) shell.hidePeek()
                else if (ev.key === Qt.Key_Space && one !== "" && here.path.startsWith("/")) shell.showPeek(one)
                else if (ev.key === Qt.Key_Space && picked.length === 0 && here.path.startsWith("/")) shell.showSizes()
                else if (ev.key === Qt.Key_Escape && shell.peeking) shell.hidePeek()
                else if (ev.key === Qt.Key_Escape && shell.sizing) shell.hideSizes()
                else if (ev.key === Qt.Key_Backspace) here.up()
                else if (ev.key === Qt.Key_Tab && shell.dual) shell.active = 1 - shell.active
                else if ((ev.key === Qt.Key_Return || ev.key === Qt.Key_Enter) && one) shell.enter(one)
                else if (ev.key === Qt.Key_F2 && one) shell.ask("rename", one)
                else if (ev.key === Qt.Key_Delete || ev.key === Qt.Key_F8) shell.command("trash")
                else if (ev.key === Qt.Key_F5 && shell.dual) shell.command("copy")
                else if (ev.key === Qt.Key_F5) here.again()
                else if (ev.key === Qt.Key_F6 && shell.dual) shell.command("move")
                else if (ev.key === Qt.Key_F7) shell.ask("folder")
                else if (ev.key === Qt.Key_A && ctrl) here.all()
                else if (ev.key === Qt.Key_C && ctrl && picked.length) shell.act(["clip", "copy"].concat(picked))
                else if (ev.key === Qt.Key_X && ctrl && picked.length) shell.act(["clip", "cut"].concat(picked))
                else if (ev.key === Qt.Key_V && ctrl) shell.act(["paste", here.path])
                else if (ev.key === Qt.Key_H && ctrl) shell.hidden = !shell.hidden
                else if (ev.key === Qt.Key_Z && ctrl) shell.act(["undo"])
                else if (ev.key === Qt.Key_Escape) { here.chosen = ({}); menu.close() }
                else ev.accepted = false
            }
            Panel { id: left; index: 0; width: shell.dual ? parent.width / 2 : parent.width; height: parent.height; path: shell.words[0] && (shell.words[0].startsWith("/") || shell.words[0] === "disks:" || shell.words[0] === "computer:") ? shell.words[0] : shell.home }
            Panel { id: right; index: 1; visible: shell.dual; x: parent.width / 2; width: parent.width / 2; height: parent.height }
            Item { id: overlay; anchors.fill: parent; Menu { id: menu } }
            // what a drag of files is, in the window's own scene: the system takes it from there
            Item { id: carrier; Drag.dragType: Drag.Automatic; Drag.supportedActions: Qt.CopyAction | Qt.MoveAction | Qt.LinkAction; Drag.keys: ["text/uri-list"] }
        }
    }
    // ── dragging: a drag of the system, so other apps take the files too; dropped here they become a job ─────
    property bool dragging: false
    property bool rightDrag: false             // dragged with the right button: where it lands, a menu asks what to do
    function drag(paths, right) {
        if (dragging || !paths.length) return
        dragging = true; rightDrag = !!right
        carrier.Drag.mimeData = { "text/uri-list": paths.map(p => "file://" + encodeURI(p)).join("\r\n") + "\r\n" }
        carrier.Drag.active = true                 // a drag has to be on before it can be handed to the system
        carrier.Drag.startDrag()
        carrier.Drag.active = false
        dragging = false; rightDrag = false
    }
    function dropInto(d, to, area) {
        if (!d.hasUrls) return
        const paths = d.urls.map(u => decodeURIComponent(String(u).replace(/^file:\/\//, ""))).filter(p => p.startsWith("/") && p !== to && p.slice(0, p.lastIndexOf("/")) !== to)
        if (!paths.length) return
        d.accept(Qt.CopyAction)
        if (!rightDrag) return enqueue((d.modifiers & Qt.ControlModifier) ? "copy" : "auto", to, paths)
        const q = area.mapToItem(overlay, d.x, d.y)
        menu.open(q.x, q.y, [{ icon: "copy", text: I18n.tr("Copy here"), run: () => shell.enqueue("copy", to, paths) },
                             { icon: "arrow-right", text: I18n.tr("Move here"), bold: true, run: () => shell.enqueue("move", to, paths) },
                             { icon: "link", text: I18n.tr("Create shortcuts here"), run: () => shell.act(["link", to].concat(paths)) },
                             { line: true }, { icon: "x", text: I18n.tr("Cancel"), run: () => {} }])
    }
    // Enter on the one chosen: into it if it is a folder (a link to one counts), else it is opened
    Process { id: probe; property string path: ""; onExited: (code) => { if (code === 0) here.go(path); else shell.open(path, false) } }
    function enter(p) { probe.path = p; probe.running = false; probe.command = ["test", "-d", p]; probe.running = true }
    // the commander's four: to the other panel, a new folder, to the Trash
    function command(what) {
        const picked = here.picked()
        if (what === "folder") return ask("folder")
        if (!picked.length) return
        if (what === "trash") act(["trash"].concat(picked))
        else if (dual && other.path !== here.path) enqueue(what, other.path, picked)
        here.chosen = ({})
    }
}
