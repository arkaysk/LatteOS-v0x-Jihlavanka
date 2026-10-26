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
import QtQml.Models
import Quickshell
import Quickshell.Io
import "common"

ShellRoot {
    id: shell
    readonly property string home: Quickshell.env("HOME") || "/"
    readonly property var words: (Quickshell.env("LATTE_APP_ARGS") || "").split("\n").filter(w => w !== "")
    property bool dual: false
    // the side's quick filter of types (inspo/latteOS dualbrew.png): only files of these kinds show, folders always
    property string typeFilter: ""
    readonly property var types: ({ pictures: { name: QT_TR_NOOP("Pictures"), globs: ["*.png", "*.jpg", "*.jpeg", "*.webp", "*.gif", "*.svg", "*.heic"] },
                                    documents: { name: QT_TR_NOOP("Documents"), globs: ["*.pdf", "*.odt", "*.doc", "*.docx", "*.txt", "*.md", "*.ods", "*.xls", "*.xlsx"] },
                                    music: { name: QT_TR_NOOP("Music"), globs: ["*.mp3", "*.flac", "*.ogg", "*.opus", "*.wav", "*.m4a"] },
                                    video: { name: QT_TR_NOOP("Video"), globs: ["*.mp4", "*.mkv", "*.webm", "*.mov", "*.avi"] },
                                    archives: { name: QT_TR_NOOP("Archives"), globs: ["*.zip", "*.7z", "*.rar", "*.tar", "*.gz", "*.xz", "*.zst", "*.iso"] },
                                    code: { name: QT_TR_NOOP("Code"), globs: ["*.py", "*.js", "*.ts", "*.qml", "*.rs", "*.c", "*.h", "*.cpp", "*.sh", "*.json", "*.toml", "*.yaml", "*.yml", "*.lua", "*.luau", "*.plm"] } })
    // ── DualBrew's own settings (~/.config/latteos/dualbrew.json): what the side shows, and how it starts — the
    // view, hidden files, the real structure, one panel or two are kept as they were left ──────────────────
    FileView { id: prefs
        path: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/latteos/dualbrew.json"
        printErrors: false
        property var kept: ({})
        property bool ready: false
        onLoaded: { try { kept = JSON.parse(text()) } catch (e) { kept = {} }
                    if (kept.view) shell.view = kept.view
                    if (kept.iconSize) left.iconSize = right.iconSize = kept.iconSize
                    shell.hidden = !!kept.hidden; shell.real = !!kept.real; shell.info = !!kept.info
                    if (Array.isArray(kept.columns)) shell.columns = kept.columns
                    if (!shell.words.includes("sizes")) shell.dual = !!kept.dual
                    ready = true }
        onLoadFailed: ready = true
        function set(key, value) { if (!ready) return; const k = Object.assign({}, kept); k[key] = value; kept = k; setText(JSON.stringify(k, null, 1)) }
    }
    onViewChanged: prefs.set("view", view)
    onHiddenChanged: prefs.set("hidden", hidden)
    onInfoChanged: prefs.set("info", info)
    onRealChanged: { prefs.set("real", real); tree = [{ path: real ? "/" : home, name: "", depth: 0, open: false }] }
    onDualChanged: if (!sizing && !peeking) prefs.set("dual", dual)
    function shows(part) { return prefs.kept["side_" + part] !== false }
    function settingsMenu() {
        const side = (part, name) => ({ text: I18n.tr(name), checked: shows(part), run: () => prefs.set("side_" + part, !shows(part)) })
        return [{ icon: "layout-sidebar", text: I18n.tr("Show in the side"), more: [side("places", "Your folders"), side("favourites", "Favourites"), side("drives", "Drives"),
                                                                                  side("network", "Network and cloud"), side("types", "Quick filter of types"),
                                                                                  { text: I18n.tr("Folder tree"), checked: prefs.kept.side_tree === true, run: () => prefs.set("side_tree", prefs.kept.side_tree !== true) }] },
                { icon: "layout-grid", text: I18n.tr("View"), more: views() },
                { icon: "layout-columns", text: I18n.tr("Columns in Details"), more: allColumns.map(c => ({ text: I18n.tr(c.name), checked: columns.includes(c.by), run: () => columnFlip(c.by) })) },
                { line: true },
                { text: I18n.tr("Hidden files"), checked: hidden, hint: "Ctrl+H", run: () => hidden = !hidden },
                { text: I18n.tr("Information pane"), checked: info, hint: "F11", run: () => info = !info },
                { text: I18n.tr("The real structure"), checked: real, run: () => real = !real },
                { text: I18n.tr("Check every copy (read it back)"), checked: !!prefs.kept.verify, run: () => prefs.set("verify", !prefs.kept.verify) },
                { text: I18n.tr("Buttons of my actions above the panels"), checked: prefs.kept.buttons === true, run: () => prefs.set("buttons", prefs.kept.buttons !== true) },
                { text: I18n.tr("Commander keys in one panel too"), checked: !!prefs.kept.keys, run: () => prefs.set("keys", !prefs.kept.keys) },
                { text: I18n.tr("Twice on bare ground goes up"), checked: prefs.kept.upOnDouble !== false, run: () => prefs.set("upOnDouble", prefs.kept.upOnDouble === false) },
                { line: true },
                { icon: "settings", text: I18n.tr("All settings…"), run: () => settingsOpen = true }]
    }
    // the same, as a page of its own: each further menu a part, the rest under Behaviour
    property bool settingsOpen: false
    readonly property var settingsParts: { const rows = settingsMenu().filter(r => !r.line && r.text !== I18n.tr("All settings…"))
                                           return rows.filter(r => r.more).map(r => ({ title: r.text, rows: r.more.filter(x => !x.line) }))
                                                      .concat([{ title: I18n.tr("Behaviour"), rows: rows.filter(r => !r.more) }]) }
    // ── the folder tree in the side (Dolphin's F7, off unless chosen): rows in order, a folder's own below it once
    // it is opened; each opening reads that folder's folders ────────────────────────────────────────────────
    property var tree: [{ path: home, name: "", depth: 0, open: false }]
    function treeToggle(i) {
        const n = tree[i], t = tree.slice()
        if (n.open) { let j = i + 1; while (j < t.length && t[j].depth > n.depth) j++; t.splice(i + 1, j - i - 1); t[i] = Object.assign({}, n, { open: false }); tree = t; return }
        t[i] = Object.assign({}, n, { open: true }); tree = t
        treeLister.at = n.path; treeLister.running = false
        treeLister.command = ["find", n.path, "-mindepth", "1", "-maxdepth", "1", "-type", "d", "-not", "-name", ".*", "-printf", "%f\n"]; treeLister.running = true
    }
    Process { id: treeLister; property string at: ""
        stdout: StdioCollector { onStreamFinished: { const i = shell.tree.findIndex(n => n.path === treeLister.at && n.open); if (i < 0) return
            const d = shell.tree[i].depth + 1, kids = this.text.split("\n").filter(x => x !== "").sort((a, b) => a.localeCompare(b))
                                              .map(x => ({ path: (treeLister.at === "/" ? "" : treeLister.at) + "/" + x, name: x, depth: d, open: false }))
            const t = shell.tree.slice(); t.splice(i + 1, 0, ...kids); shell.tree = t } } }
    // the line under the panels: "command", "find" or "ai"; what Find narrows the folders to as one writes
    property string lineMode: "command"
    property string findText: ""
    // Find's narrowing, for Enter: bigger than (MB), changed within (days), the name as a regular expression
    property var findOpts: ({ bigger: 0, days: 0, regex: false })
    function findOpt(k, v) { const o = Object.assign({}, findOpts); o[k] = o[k] === v ? (typeof v === "boolean" ? false : 0) : v; findOpts = o }
    function findMenu(x, y) {
        const big = mb => ({ text: I18n.tr("Bigger than {n}", { n: mb >= 1024 ? mb / 1024 + " GB" : mb + " MB" }), checked: findOpts.bigger === mb, run: () => findOpt("bigger", mb) })
        const age = (d, name) => ({ text: I18n.tr(name), checked: findOpts.days === d, run: () => findOpt("days", d) })
        menu.open(x, y, [big(10), big(100), big(1024), { line: true },
                         age(1, "Changed today"), age(7, "Changed this week"), age(31, "Changed this month"), age(365, "Changed this year"), { line: true },
                         { text: I18n.tr("The name as a regular expression"), checked: findOpts.regex, run: () => findOpt("regex", true) }, { line: true },
                         { icon: "copy", text: I18n.tr("Find the same files here"), run: () => here.findDups() }])
    }
    function lineTo(mode) { if (lineMode === "find" && mode !== "find") { findText = ""; left.found = null; right.found = null }
                            lineMode = mode; termLine.text = mode === "find" ? findText : ""; termLine.forceActiveFocus() }
    // the commands run before, the newest last, kept between runs; ↑ and ↓ go through them
    property int historyAt: -1
    function history() { return Array.isArray(prefs.kept.history) ? prefs.kept.history : [] }
    function historyStep(d) { const h = history(); if (!h.length) return
                              historyAt = historyAt < 0 ? (d < 0 ? h.length - 1 : -1) : historyAt + d
                              if (historyAt >= h.length) historyAt = -1
                              historyAt = Math.max(-1, historyAt); termLine.text = historyAt < 0 ? "" : h[historyAt] }
    // the chosen ones' names into the line (Ctrl+Enter), or their whole paths (Ctrl+P), as the commander does
    function lineInsert(whole) { const q = here.picked().map(p => "'" + (whole ? p : p.split("/").pop()).replace(/'/g, "'\\''") + "'")
                                 if (!q.length) return; termLine.insert(termLine.cursorPosition, (termLine.text && !termLine.text.endsWith(" ") ? " " : "") + q.join(" ") + " "); termLine.forceActiveFocus() }
    function lineDone(text) {
        const t = text.trim()
        if (lineMode === "find" && here.path.startsWith("/") && (t !== "" || findOpts.bigger || findOpts.days)) return here.find(t)
        if (t === "" || !here.path.startsWith("/")) return
        if (lineMode === "ai") {
            const picked = here.picked().map(p => p.split("/").pop())
            Quickshell.execDetached(["latte-ai", "do", t + (picked.length ? "\n\n" + I18n.tr("Chosen here: {n}", { n: picked.join(", ") }) : ""), "--in", here.path])
        } else { Quickshell.execDetached(["foot", "--working-directory", here.path, "--", "sh", "-c", 'eval "$1"; echo; printf "%s" "$2"; read x', "sh", text, I18n.tr("Press Enter to close")])
                 prefs.set("history", history().filter(h => h !== t).concat([t]).slice(-50)); historyAt = -1 }
        termLine.text = ""; keys.forceActiveFocus()
    }
    // what shows of a folder: the quick filter of types, narrowed to the names that hold what Find has
    readonly property var nameFilters: { const t = findText.replace(/[\[\]*?]/g, ""), g = typeFilter !== "" ? types[typeFilter].globs : ["*"]
                                         return t === "" ? g : g.map(x => "*" + t + "*" + x.slice(1)) }
    property int active: 0                     // which panel has the keys
    property string view: "details"            // or "icons" (here.iconSize big), "small", "tiles": Explorer's views; "photos", the viewer
    property bool hidden: false
    property bool info: false                  // the pane of the one chosen, as Dolphin's (F11)
    // the columns of Details beside the name, in this order, each as wide as it says; which show is the user's
    readonly property var allColumns: [{ by: "type", name: QT_TR_NOOP("Type"), w: 110 }, { by: "size", name: QT_TR_NOOP("Size"), w: 100 },
                                       { by: "date", name: QT_TR_NOOP("Modified"), w: 140 }, { by: "attr", name: QT_TR_NOOP("Attributes"), w: 120 }]
    property var columns: ["size", "date", "attr"]
    readonly property var shownColumns: allColumns.filter(c => columns.includes(c.by))
    readonly property real columnsWidth: shownColumns.reduce((t, c) => t + c.w, 0)
    function columnAt(by) { let r = 0, found = false; for (const c of shownColumns) { if (c.by === by) found = true; if (found) r += c.w } return r }   // from the right edge
    function columnFlip(by) { columns = columns.includes(by) ? columns.filter(x => x !== by) : columns.concat([by]); prefs.set("columns", columns) }
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
        const ar = archiveOf(p); if (ar) p = ar.file
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
    readonly property var drives: ["disk", "usb", "card", "optical", "image", "phone", "network", "cloud"]
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
    // the drive button's menu: This computer, then every drive with what is left on it; one not mounted is mounted
    function driveMenu(p) {
        const at = (pl) => !!p.root && p.root.path === pl.path
        return [{ icon: "device-desktop", text: I18n.tr("This computer"), checked: p.path === "computer:", run: () => p.go("computer:") }, { line: true }]
            .concat(places.filter(pl => pl.kind === "home" || (drives.includes(pl.kind) && (pl.path !== "/" || real)))
                .map(pl => ({ icon: placeIcons[pl.kind] || "disc", checked: at(pl), text: pl.kind === "home" ? I18n.tr("Home") : driveName(pl),
                              hint: pl.total > 0 ? I18n.tr("{n} free", { n: bytes(pl.total - pl.used) }) : (pl.path === "" ? I18n.tr("not connected") : ""),
                              run: () => { active = p.index; reach(pl) } })))
            .concat([{ line: true }, { icon: "disc", text: "/", hint: I18n.tr("The real structure"), run: () => { real = true; p.go("/") } }])
    }
    function canEject(pl) { return pl.path !== "" && (["usb", "card", "optical", "image", "phone", "network"].includes(pl.kind) || (pl.kind === "cloud" && pl.device !== "")) }
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
    function enqueue(how, to, files, policy) {
        if (!files.length || !(to.startsWith("/") || how === "split" || how === "join")) return
        // a name already there is asked about first, as the commander does: nothing is decided for the user in silence
        if (policy === undefined && ["copy", "move", "auto"].includes(how)) {
            clasher.pending = { how: how, to: to, files: files }; clasher.running = false
            clasher.command = ["latte-files", "clashes", to].concat(files); clasher.running = true; return
        }
        const title = (files.length === 1 ? files[0].split("/").pop() : I18n.tr("{n} items", { n: files.length })) + (how === "split" || how === "join" ? "" : "  →  " + (to.split("/").pop() || "/"))
        jobs = jobs.concat([{ how: how, to: to, files: files, title: title, policy: policy || "both" }])
        if (!job) nextJob()
    }
    function nextJob() {
        if (!jobs.length) { job = null; left.again(); right.again(); return }
        const j = jobs[0]; jobs = jobs.slice(1)
        job = { title: j.title, how: j.how, total: 0, done: 0, name: "", paused: false }
        jobber.command = ["env", "LATTE_CONFLICT=" + j.policy, "LATTE_VERIFY=" + (prefs.kept.verify ? 1 : 0), "latte-files", "job", j.how, j.to].concat(j.files); jobber.running = true
    }
    Process { id: jobber
        stdout: SplitParser { onRead: line => { if (!shell.job) return
            const sp = line.indexOf(" "), k = line.slice(0, sp), v = line.slice(sp + 1), j = Object.assign({}, shell.job)
            if (k === "total") j.total = parseInt(v); else if (k === "done") j.done = parseInt(v); else if (k === "file") j.name = v
            else if (k === "failed") shell.failed = shell.failed.concat([v])
            shell.job = j } }
        onExited: { left.again(); right.again()
                    if (shell.failed.length) { shell.say(I18n.tr("Not done: {n}", { n: shell.failed.join(", ") })); shell.failed = [] }
                    shell.nextJob() } }
    property var failed: []                    // what the job under way could not do, said when it ends
    // what is asked when names are taken: { how, to, files, names }
    property var clash: null
    Process { id: clasher; property var pending: null
        stdout: StdioCollector { onStreamFinished: { const p = clasher.pending, names = this.text.split("\n").filter(n => n !== "")
            if (!p) return
            if (names.length) shell.clash = Object.assign({ names: names }, p); else shell.enqueue(p.how, p.to, p.files, "both") } } }
    function clashed(policy) { const c = clash; clash = null; keys.forceActiveFocus(); if (c && policy !== "") enqueue(c.how, c.to, c.files, policy) }
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
    // the details view draws its files as the sketch does: an outline icon of the kind, in the theme's colours
    readonly property var typeGlyphs: ({ pictures: "photo", documents: "file-text", music: "music", video: "movie", archives: "file-zip", code: "code" })
    function glyphOf(name, isDir) {
        if (isDir) return "folder"
        const n = name.toLowerCase()
        for (const t in types) if (types[t].globs.some(g => n.endsWith(g.slice(1)))) return typeGlyphs[t]
        return "file"
    }
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
                                         "image": "disc", "phone": "device-mobile", "network": "network", "cloud": "cloud" })
    readonly property var driveKinds: ({ "disk": QT_TR_NOOP("Local disk"), "usb": QT_TR_NOOP("USB drive"), "card": QT_TR_NOOP("Memory card"), "optical": QT_TR_NOOP("DVD drive"),
                                         "image": QT_TR_NOOP("Disc image"), "phone": QT_TR_NOOP("Phone"), "network": QT_TR_NOOP("Network place"), "cloud": QT_TR_NOOP("Cloud") })
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
    // a moment as the lists say it: today with the hour, else the day
    function when(t) { const d = new Date(t * 1000); return d.toDateString() === new Date().toDateString() ? I18n.tr("Today") + " " + Qt.formatTime(d, "hh:mm") : Qt.formatDateTime(d, "d. M. yyyy  hh:mm") }
    function bytes(b) { const u = ["B", "KB", "MB", "GB", "TB"]; let v = b || 0, i = 0; while (v >= 1024 && i < 4) { v /= 1024; i++ } return v.toFixed(i ? 1 : 0) + " " + u[i] }
    // an archive is gone into as a folder, only to read (latte-files archive); its own app still opens it from the menu
    readonly property var archiveKinds: ["zip", "7z", "rar", "tar", "tgz", "gz", "xz", "bz2", "zst", "cab", "jar"]
    property var archives: ({})                // where each is mounted: mount → the archive
    function archiveOf(p) { for (const m in archives) if (p === m || p.startsWith(m + "/")) return { mount: m, file: archives[m] }; return null }
    Process { id: archiver; property string file: ""
        // not mountable (a password, a kind libarchive does not read): its own app opens it
        onExited: (code) => { if (code !== 0) Quickshell.execDetached(["gio", "open", archiver.file]) }
        stdout: StdioCollector { onStreamFinished: { const at = this.text.trim(); if (!at.startsWith("/")) return
            const a = Object.assign({}, shell.archives); a[at] = archiver.file; shell.archives = a; shell.here.go(at) } } }
    function openArchive(path) { archiver.file = path; archiver.running = false; archiver.command = ["latte-files", "archive", path]; archiver.running = true }
    function open(path, isDir) { if (!isDir && archiveKinds.includes(FileIcons.ending(path))) return openArchive(path)
                                 if (isDir) here.go(path); else Quickshell.execDetached(path.endsWith(".desktop") ? ["gio", "launch", path] : ["gio", "open", path]) }
    function ask(what, path) { asking = what; askingFor = path || ""; answer.text = what === "rename" ? path.split("/").pop() : (what === "folder" ? I18n.tr("New folder") : (what === "server" ? "smb://" : (what === "select" || what === "unselect" ? "*.jpg" : what === "split" ? "4000" : I18n.tr("New Text Document") + ".txt")))
                               Qt.callLater(() => { answer.focusIt(); }) }
    function answered(text) {
        const t = text.trim(), what = asking, target = askingFor
        asking = ""
        // a network place: gio mounts it in a terminal, where it can ask for a name and a password
        if (what === "server") { if (t.indexOf("://") > 0) Quickshell.execDetached(["foot", "-e", "sh", "-c", "gio mount \"$1\" && echo OK || read x", "sh", t]); return }
        if (what === "select" || what === "unselect") return here.choosePattern(t, what === "select")
        if (what === "split") { if (parseInt(t) > 0) enqueue("split", String(parseInt(t)), [target]); return }
        if (t === "" || t.indexOf("/") >= 0) return
        if (what === "rename") act(["rename", target, t]); else act([what, here.path, t])
    }

    // ── Properties: what a file or folder is, its times, who it is and what may be done with it, the app that opens
    // that kind, its SHA-256 (latte-files props, chmod, default, sum) ─────────────────────────────────────────
    property string propsFor: ""
    property var props: ({})
    property var propsApps: []
    property string propsSum: ""
    property var propsAll: []                  // with more than one chosen: all of them (the sheet speaks of the first)
    property real propsTotal: -1
    function properties(paths) { if (typeof paths === "string") paths = [paths]; const path = paths[0]
                                propsFor = path; propsAll = paths; props = ({}); propsSum = ""; propsApps = []; propsTotal = -1; propser.command = ["latte-files", "props", path]; propser.running = true
                                if (paths.length > 1) { totaller.command = ["latte-files", "size"].concat(paths); totaller.running = true }
                                if (!path.endsWith("/")) { propsOpeners.command = ["latte-desktop", "openers", path]; propsOpeners.running = true } }
    Process { id: propser; stdout: StdioCollector { onStreamFinished: { const a = {}; for (const l of this.text.split("\n")) { const i = l.indexOf("\t"); if (i > 0) a[l.slice(0, i)] = l.slice(i + 1) } shell.props = a } } }
    Process { id: propsOpeners; stdout: StdioCollector { onStreamFinished: shell.propsApps = this.text.split("\n").filter(l => l.indexOf("\t") > 0).map(l => ({ id: l.split("\t")[0], name: l.split("\t")[1] })) } }
    Process { id: summer; stdout: StdioCollector { onStreamFinished: shell.propsSum = this.text.trim() || "—" } }
    Process { id: totaller; stdout: StdioCollector { onStreamFinished: shell.propsTotal = parseFloat(this.text) || 0 } }
    Process { id: propsDoer; onExited: shell.properties(shell.propsAll) }
    function propsDo(args) { propsDoer.running = false; propsDoer.command = ["latte-files"].concat(args); propsDoer.running = true }
    // one of the nine: whose (0 owner, 1 group, 2 others) and what (4 read, 2 write, 1 run)
    function modeHas(who, bit) { const m = props.mode || "000"; return (parseInt(m[m.length - 3 + who], 8) & bit) !== 0 }
    // as chmod's letters (u+x), so with many chosen only that one switch changes on each of them
    function modeFlip(who, bit) { propsDo(["chmod", "ugo"[who] + (modeHas(who, bit) ? "-" : "+") + ({ 4: "r", 2: "w", 1: "x" })[bit]].concat(propsAll)) }
    // ── many renamed at once (F2 with more than one chosen): a pattern of pieces — [N] the name, [C] a counter,
    // [D] [T] the day and time it was taken (EXIF) or last changed, [E] the ending — then find and replace;
    // every new name is seen before anything is done, and one Ctrl+Z takes them all back ─────────────────────
    property var renaming: []
    property var renDates: ({})
    function renameMany(paths) { renaming = paths.slice().sort((a, b) => a.localeCompare(b)); renDates = ({})
                                 dater.command = ["latte-files", "dates"].concat(renaming); dater.running = true
                                 Qt.callLater(() => renPattern.focusIt()) }
    Process { id: dater; stdout: StdioCollector { onStreamFinished: { const d = {}; for (const l of this.text.split("\n")) { const p = l.split("\t"); if (p.length === 3) d[p[0]] = { day: p[1], time: p[2] } } shell.renDates = d } } }
    function newName(path, i) {
        const name = path.split("/").pop(), dot = name.lastIndexOf("."), base = dot > 0 ? name.slice(0, dot) : name, ext = dot > 0 ? name.slice(dot + 1) : ""
        const digits = String(renaming.length + renStart.value - 1).length, d = renDates[path] || { day: "", time: "" }
        let out = (renPattern.text || "[N]").split("[N]").join(base).split("[C]").join(String(renStart.value + i).padStart(digits, "0"))
                                            .split("[D]").join(d.day).split("[T]").join(d.time)
        out = out.indexOf("[E]") >= 0 ? out.split("[E]").join(ext) : out + (ext ? "." + ext : "")
        if (renFind.text !== "") out = out.split(renFind.text).join(renWith.text)
        return out
    }
    // each one's new name, and what is wrong with it: a slash, empty, twice, or taken by something staying here
    readonly property var renPlan: {
        if (!renaming.length) return []
        renPattern.text; renFind.text; renWith.text; renStart.value; renDates
        const plan = renaming.map((p, i) => ({ path: p, from: p.split("/").pop(), to: newName(p, i) }))
        const staying = here.rows.filter(p => !renaming.includes(p)).map(p => p.split("/").pop())
        return plan.map(r => Object.assign(r, { bad: r.to === "" || r.to.indexOf("/") >= 0 || staying.includes(r.to) || plan.filter(o => o.to === r.to).length > 1 }))
    }
    function renameDo() { if (renPlan.some(r => r.bad)) return
                          act(["renames"].concat(...renPlan.filter(r => r.to !== r.from).map(r => [r.path, r.to]))); renaming = []; keys.forceActiveFocus() }
    // ── the user's own actions in a file's menu (Dolphin's service menus): scripts in ~/.config/latteos/dualbrew/
    // actions, each saying its name and which files it is for; LatteOS's recipes do nothing until one is added ──
    property var actions: []
    property var recipes: []
    function readActions() { actioner.running = false; actioner.running = true; reciper.running = false; reciper.running = true }
    function parseActions(text) { return text.split("\n").filter(l => l.indexOf("\t") > 0).map(l => { const p = l.split("\t")
        return { path: p[0], name: p[1] || p[0].split("/").pop(), res: (p[2] || "*").split(/\s+/).filter(x => x !== "").map(g => new RegExp("^" + g.replace(/[.+^${}()|[\]\\]/g, "\\$&").replace(/\*/g, ".*").replace(/\?/g, ".") + "$", "i")) } }) }
    Process { id: actioner; running: true; command: ["latte-files", "actions"]; stdout: StdioCollector { onStreamFinished: shell.actions = shell.parseActions(this.text) } }
    Process { id: reciper; running: true; command: ["latte-files", "recipes"]; stdout: StdioCollector { onStreamFinished: shell.recipes = shell.parseActions(this.text) } }
    Process { id: actionDoer; onExited: { left.again(); right.again(); shell.readActions() } }
    function actionRows(picked) {
        const fits = a => picked.every(p => a.res.some(r => r.test(p.split("/").pop())))
        const mine = actions.filter(fits).map(a => ({ text: I18n.tr(a.name), run: () => { actionDoer.running = false; actionDoer.command = ["sh", a.path].concat(picked); actionDoer.running = true } }))
        const owned = actions.map(a => a.path.split("/").pop())
        const more = recipes.filter(r => !owned.includes(r.path.split("/").pop()))
                            .map(r => ({ icon: "plus", text: I18n.tr("Add: {n}", { n: I18n.tr(r.name) }), run: () => { actionDoer.running = false; actionDoer.command = ["latte-files", "action-add", r.path]; actionDoer.running = true } }))
        const folder = (Quickshell.env("XDG_CONFIG_HOME") || home + "/.config") + "/latteos/dualbrew/actions"
        return mine.concat(mine.length && more.length ? [{ line: true }] : [], more, [{ line: true }, { icon: "folder", text: I18n.tr("The actions folder"),
                    run: () => { actionDoer.running = false; actionDoer.command = ["mkdir", "-p", folder]; actionDoer.running = true; here.go(folder) } }])
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
            ...(many ? [{ icon: "list", text: I18n.tr("Copy the names"), run: () => Quickshell.execDetached(["wl-copy", "--", picked.map(p => p.split("/").pop()).join("\n")]) }] : []),
            { line: true }]
        // archives: out here, or to the other panel; anything: into a zip or a 7z
        const packed = ["zip", "7z", "rar", "tar", "gz", "tgz", "xz", "bz2", "zst"]
        if (picked.every(p => packed.includes(FileIcons.ending(p.split("/").pop()))))
            rows.push({ icon: "file-zip", text: I18n.tr("Extract here"), run: () => shell.enqueue("extract", here.path, picked) },
                      ...(!many ? [{ icon: "check", text: I18n.tr("Test the archive"), run: () => Quickshell.execDetached(["foot", "--", "sh", "-c", '7z t -- "$1"; echo; printf "%s" "$2"; read x', "sh", path, I18n.tr("Press Enter to close")]) }] : []),
                      ...(dual && other.path.startsWith("/") ? [{ icon: "file-zip", text: I18n.tr("Extract to the other panel"), run: () => shell.enqueue("extract", other.path, picked) }] : []))
        rows.push({ icon: "package", text: I18n.tr("Compress"), more: [{ text: I18n.tr("To a ZIP file"), run: () => shell.enqueue("zip", here.path, picked) },
                                                                        { text: I18n.tr("To a 7z file"), run: () => shell.enqueue("7z", here.path, picked) }] })
        // a big file in pieces (for a FAT32 stick: under 4 GB each), and the pieces back into one
        if (!many && !isDir && FileIcons.ending(path) === "000") rows.push({ icon: "link", text: I18n.tr("Join the pieces"), run: () => shell.enqueue("join", "-", [path]) })
        else if (!many && !isDir) rows.push({ icon: "cut", text: I18n.tr("Split into pieces…"), run: () => shell.ask("split", path) })
        if (!many && FileIcons.ending(path) === "iso") rows.push({ icon: "disc", text: I18n.tr("Mount as a DVD drive"), run: () => { mounter.running = false; mounter.command = ["latte-files", "iso", path]; mounter.running = true } })
        rows.push({ icon: "bolt", text: I18n.tr("Actions"), more: shell.actionRows(picked) })
        // checksums, as the commander's: a .sha256 made of the chosen files beside them, or one checked (in a terminal)
        const sums = ["sha256", "sha512", "sha1", "md5"], sumOf = FileIcons.ending(path)
        if (!many && sums.includes(sumOf)) rows.push({ icon: "check", text: I18n.tr("Check the checksums"), run: () => Quickshell.execDetached(["foot", "--working-directory", here.path, "--", "sh", "-c", sumOf + 'sum -c -- "$1"; echo; printf "%s" "$2"; read x', "sh", path, I18n.tr("Press Enter to close")]) })
        else if (!isDir) rows.push({ icon: "shield-check", text: I18n.tr("Make a checksum file (SHA-256)"), run: () => shell.act(["sums"].concat(picked)) })
        rows.push({ icon: "tag", text: I18n.tr("Colour"), more: shell.colours.map(c => ({ tint: c.color, text: I18n.tr(c.name), run: () => { shell.act(["tag", c.id].concat(picked)) } }))
                                                                     .concat([{ line: true }, { text: I18n.tr("No colour"), run: () => shell.act(["tag", ""].concat(picked)) }]) })
        rows.push({ line: true })
        // the system's own files: changed as the administrator, in a terminal that asks for the password (sudoedit keeps
        // the editor itself the user's); a folder gets a terminal there as the administrator. Never the whole window.
        if (!many && !path.startsWith(home + "/") && path !== home)
            rows.push(isDir ? { icon: "shield-lock", text: I18n.tr("Terminal here as the administrator…"), danger: true,
                                run: () => Quickshell.execDetached(["foot", "--working-directory", path, "--", "sudo", "-s"]) }
                            : { icon: "shield-lock", text: I18n.tr("Edit as the administrator…"), danger: true,
                                run: () => Quickshell.execDetached(["foot", "--", "sh", "-c", 'printf "%s\n\n" "$2"; SUDO_EDITOR="${EDITOR:-nano}" sudoedit -- "$1"', "sh", path, I18n.tr("A system file: what you change here changes the system. The password is the administrator's.")]) })
        rows.push(many ? { icon: "pencil", text: I18n.tr("Rename all…"), hint: "F2", run: () => shell.renameMany(picked) }
                       : { icon: "pencil", text: I18n.tr("Rename"), hint: "F2", run: () => shell.ask("rename", path) })
        if (!inTrash) rows.push({ icon: "trash", text: I18n.tr("Delete"), hint: "Del", danger: true, run: () => shell.act(["trash"].concat(picked)) })
        rows.push({ line: true }, { icon: "info-circle", text: I18n.tr("Properties"), hint: "Alt+Enter", run: () => shell.properties(many ? picked : path) })
        menu.open(x, y, rows)
    }
    // the views of Windows' Explorer, by the same names; Ctrl and the wheel go between the icon sizes
    function views() {
        const icons = (size, name) => ({ text: I18n.tr(name), checked: view === "icons" && here.iconSize === size, run: () => { here.iconSize = size; view = "icons"; prefs.set("iconSize", size) } })
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
            { icon: "check", text: I18n.tr("Choose"), more: [{ text: I18n.tr("All"), hint: "Ctrl+A", run: () => here.all() },
                                                            { text: I18n.tr("By a pattern…"), hint: "Num +", run: () => shell.ask("select") },
                                                            { text: I18n.tr("Let go by a pattern…"), hint: "Num −", run: () => shell.ask("unselect") },
                                                            { text: I18n.tr("Invert"), hint: "Num *", run: () => here.invert() }, { line: true },
                                                            { text: I18n.tr("Keep this choice"), enabled: here.picked().length > 0, run: () => prefs.set("choice", here.picked().map(p => p.split("/").pop())) },
                                                            { text: I18n.tr("Bring back the kept choice"), enabled: Array.isArray(prefs.kept.choice), run: () => here.chooseNames(prefs.kept.choice) }] },
            { icon: "arrow-back-up", text: I18n.tr("Undo"), hint: "Ctrl+Z", run: () => shell.act(["undo"]) },
            { icon: "history", text: I18n.tr("Where this panel was"), hint: "Alt+↓", run: () => shell.historyMenu() },
            ...(shell.dual ? [{ icon: "arrows-exchange", text: I18n.tr("Swap the panels"), hint: "Ctrl+U", run: () => { const a = left.path; left.go(right.path); right.go(a) } }] : []),
            { icon: "list", text: I18n.tr("Every file below, in one list"), hint: "Ctrl+B", run: () => here.flat() },
            { icon: "disc", text: I18n.tr("How much each folder holds"), checked: shell.sizing, hint: I18n.tr("Space"), run: () => shell.showSizes() },
            { line: true },
            { icon: "clipboard", text: I18n.tr("Paste"), hint: "Ctrl+V", run: () => shell.act(["paste", here.path]) },
            { icon: "plus", text: I18n.tr("New"), more: [{ icon: "folder-plus", text: I18n.tr("Folder"), run: () => shell.ask("folder") }, { icon: "file-text", text: I18n.tr("Text Document"), run: () => shell.ask("file") }] },
            { line: true },
            { icon: "terminal-2", text: I18n.tr("Open in Terminal"), run: () => Quickshell.execDetached(["sh", "-c", "cd \"$1\" && exec foot", "sh", here.path]) }])
    }

    // what Find's filter of folders reads of each row
    component RoleData: QtObject { property string fileName; property bool fileIsDir }
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
        // what Find found below this folder, by name and inside files: [{ path, how }], null when not looking
        property var found: null
        property string looked: ""
        onFoundChanged: if (found === null) finder.running = false
        function find(t) { looked = t; found = []; finder.running = false
                           const o = shell.findOpts
                           finder.command = ["latte-files", "find", path, t].concat(o.bigger ? ["--bigger", String(o.bigger)] : [], o.days ? ["--days", String(o.days)] : [], o.regex ? ["--regex"] : [])
                           finder.running = true }
        function flat() { if (!path.startsWith("/")) return; looked = I18n.tr("every file below"); found = []; finder.running = false; finder.command = ["latte-files", "flat", path]; finder.running = true }
        function findDups() { looked = I18n.tr("the same files"); found = []; finder.running = false; finder.command = ["latte-files", "dups", path]; finder.running = true }
        Process { id: finder; stdout: SplitParser { onRead: line => { const i = line.indexOf("\t"); if (i <= 0 || !panel.found) return
            const rest = line.slice(i + 1), j = rest.indexOf("\t")
            panel.found = panel.found.concat([panel.path === "recent:" ? { how: "recent", path: line.slice(0, i), when: parseInt(rest) }
                                            : line.slice(0, i) === "dup" ? { how: "dup", group: parseInt(rest.slice(0, j)), path: rest.slice(j + 1) }
                                            : { how: line.slice(0, i), path: rest }]) } } }
        readonly property bool isActive: shell.active === index
        onChosenChanged: if (isActive) shell.learn()
        function go(to) { if (to === path || to === "") return; before = before.concat([path]); ahead = []; path = to; chosen = ({}); last = "" }
        function back() { if (!before.length) return; const b = before.slice(); ahead = ahead.concat([path]); path = b.pop(); before = b; chosen = ({}) }
        function forward() { if (!ahead.length) return; const a = ahead.slice(); before = before.concat([path]); path = a.pop(); ahead = a; chosen = ({}) }
        function sort(by) { if (sortBy === by) sortDown = !sortDown; else { sortBy = by; sortDown = by !== "name" && by !== "type" } }
        // what a drag carries: everything chosen when the one held is chosen, else that one
        function carried(filePath) { return chosen[filePath] ? picked() : [filePath] }
        // the mouse's own buttons, wherever they are pressed in the panel
        function extra(m) { if (m.button === Qt.BackButton) { back(); return true } if (m.button === Qt.ForwardButton) { forward(); return true } return false }
        function up() {
            if (path === "computer:") return
            if (path === "disks:" || path === "recent:") return go("computer:")
            const ar = shell.archiveOf(path)
            if (ar && ar.mount === path) return go(ar.file.slice(0, ar.file.lastIndexOf("/")) || "/")
            const root = shell.real ? null : shell.rootOf(path)
            if (root && root.path === path) return go("computer:")
            if (path !== "/") go(path.replace(/\/[^/]+\/?$/, "") || "/")
        }
        // the way to here, as pieces one can press: from / in the real structure, else from This computer
        readonly property var way: { shell.archives; return wayOf(path) }
        function wayOf(p) {
            if (p === "computer:") return []
            if (p === "disks:") return [{ name: I18n.tr("Disks and devices"), path: "disks:" }]
            // inside an archive: the way to the archive, the archive itself, then what is inside it
            const ar = shell.archiveOf(p)
            if (ar) { const out = wayOf(ar.file.slice(0, ar.file.lastIndexOf("/")) || "/").concat([{ name: ar.file.split("/").pop(), path: ar.mount }])
                      let at = ar.mount
                      for (const x of p.slice(ar.mount.length).split("/").filter(x => x !== "")) { at += "/" + x; out.push({ name: x, path: at }) }
                      return out }
            const root = shell.real ? null : shell.rootOf(p)
            const base = root ? root.path : "", parts = p.slice(base.length).split("/").filter(x => x !== ""), out = []
            // This computer and the drive itself are the button before the way
            let at = base
            for (const x of parts) { at += "/" + x; out.push({ name: x, path: at }) }
            return out
        }
        // read the folder anew: its binding goes empty and back, and stays a binding (an assignment would cut it off)
        property bool fresh: true
        function again() { fresh = false; fresh = true; readTags() }
        // the colours of what is here
        property var tags: ({})
        // in a Git repository: what is changed, new or ignored, by name (latte-files git)
        property var gits: ({})
        Process { id: gitReader; stdout: StdioCollector { onStreamFinished: { const g = {}
            for (const l of this.text.split("\n")) { const i = l.indexOf("\t"); if (i > 0) g[panel.path + "/" + l.slice(0, i)] = l.slice(i + 1) }
            panel.gits = g } } }
        // launchers (.desktop) here show their own name and picture, as on the desktop
        property var launchers: ({})
        Process { id: launcherReader; stdout: StdioCollector { onStreamFinished: { const out = {}
            for (const l of this.text.split("\n")) { const p = l.split("\t"); if (p.length === 3) out[panel.path + "/" + p[0]] = { name: p[1], icon: p[2] } }
            panel.launchers = out } } }
        function launcherIcon(p) { const a = launchers[p]; return a && a.icon ? (a.icon.startsWith("/") ? "file://" + a.icon : Quickshell.iconPath(a.icon, true)) : "" }
        function readTags() { if (!path.startsWith("/")) { tags = ({}); modes = ({}); launchers = ({}); gits = ({}); return } tagger.running = false; tagger.command = ["latte-files", "tags", path]; tagger.running = true
                              launcherReader.running = false; launcherReader.command = ["latte-desktop", "entries", path]; launcherReader.running = true
                              gitReader.running = false; gitReader.command = ["latte-files", "git", path]; gitReader.running = true
                              moder.running = false; moder.command = ["find", path, "-mindepth", "1", "-maxdepth", "1", "-printf", "%M\t%p\n"]; moder.running = true }
        // what each may be done with, as `ls -l` writes it: the commander's Attributes column, read once for the folder
        property var modes: ({})
        Process { id: moder; stdout: StdioCollector { onStreamFinished: { const m = {}; for (const l of this.text.split("\n")) { const i = l.indexOf("\t"); if (i > 0) m[l.slice(i + 1)] = l.slice(0, i) } panel.modes = m } } }
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
            for (let i = 0; i < rows.length; i++) {
                const cx = icons ? (i % cols) * grid.cellWidth : 0, cy = icons ? Math.floor(i / cols) * grid.cellHeight - grid.contentY : list.y + i * 34 - list.contentY
                if (cx < x + w && cx + (icons ? grid.cellWidth : list.width) > x && cy < y + h && cy + (icons ? grid.cellHeight : 34) > y) s[files.get(i, "filePath")] = true
            }
            chosen = s
        }
        function all() { const s = {}; for (const p of rows) s[p] = true; chosen = s }
        // as the commander's Num + and Num −: what matches the pattern (*.jpg, IMG_*; ; between several) is added or let go
        function choosePattern(t, add) {
            const res = t.split(";").map(x => x.trim()).filter(x => x !== "").map(x => new RegExp("^" + x.replace(/[.+^${}()|[\]\\]/g, "\\$&").replace(/\*/g, ".*").replace(/\?/g, ".") + "$", "i"))
            const s = Object.assign({}, chosen)
            for (const p of rows) if (res.some(r => r.test(p.split("/").pop()))) { if (add) s[p] = true; else delete s[p] }
            chosen = s
        }
        // letters typed in the list go to the first name that starts so, as in Explorer; a pause starts anew
        property string typed: ""
        Timer { id: typedOut; interval: 1000; onTriggered: panel.typed = "" }
        function jump(ch) {
            typed += ch.toLowerCase(); typedOut.restart()
            const name = p => (launchers[p] ? launchers[p].name : p.split("/").pop()).toLowerCase()
            const i = rows.findIndex(p => name(p).startsWith(typed))
            if (i < 0) return
            const c = {}; c[rows[i]] = true; chosen = c; last = rows[i]
            list.positionViewAtIndex(i, ListView.Contain); grid.positionViewAtIndex(i, GridView.Contain)
        }
        // a kept choice brought back, by the names, in whatever folder this is
        function chooseNames(names) { const s = {}; for (const p of rows) if (names.includes(p.split("/").pop())) s[p] = true; chosen = s }
        function invert() { const s = {}; for (const p of rows) if (!chosen[p]) s[p] = true; chosen = s }
        function press(filePath, at, mods) {
            shell.active = index
            if (mods & Qt.ControlModifier) { const s = Object.assign({}, chosen); if (s[filePath]) delete s[filePath]; else s[filePath] = true; chosen = s }
            else if ((mods & Qt.ShiftModifier) && last !== "") {
                let from = -1
                from = rows.indexOf(last)
                const s = {}
                for (let i = Math.min(from, at); i <= Math.max(from, at); i++) if (i >= 0) s[rows[i]] = true
                chosen = s; return
            } else { const s = {}; s[filePath] = true; chosen = s }
            last = filePath
            if (shell.peeking && shell.other.peek !== "") shell.other.peek = filePath      // the look follows the choice
        }
        // what the views show, in their order: the folder, its folders narrowed by Find too (the files are, by the name filters)
        readonly property var rows: { fresh; shell.findText; const out = [], t = shell.findText.toLowerCase()
                                      for (let i = 0; i < files.count; i++) if (t === "" || !files.get(i, "fileIsDir") || files.get(i, "fileName").toLowerCase().indexOf(t) >= 0) out.push(files.get(i, "filePath"))
                                      return out }
        readonly property int count: rows.length
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
        onPathChanged: { measured = false; forget(); readTags(); found = null; finder.running = false
                         if (path === "recent:") { found = []; finder.command = ["latte-files", "recent"]; finder.running = true } }
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
                          nameFilters: shell.nameFilters; caseSensitive: false
                          onCountChanged: shown.invalidate()
                          sortField: panel.sortBy === "size" ? FolderListModel.Size : (panel.sortBy === "date" ? FolderListModel.Time : (panel.sortBy === "type" ? FolderListModel.Type : FolderListModel.Name)); sortReversed: panel.sortDown }
        // the name filters leave folders alone: Find narrows them here
        SortFilterProxyModel { id: shown; model: files
            filters: [FunctionFilter { enabled: shell.findText !== ""
                function filter(data: RoleData): bool { return !data.fileIsDir || data.fileName.toLowerCase().indexOf(shell.findText.toLowerCase()) >= 0 } }] }
        Connections { target: shell; function onFindTextChanged() { shown.invalidate() } }

        Rectangle { anchors.fill: parent; anchors.margins: 6; radius: 18; color: Qt.darker(Theme.card, 1.18)
                    border.width: 1; border.color: shell.dual && panel.isActive ? Qt.rgba(Theme.gold.r, Theme.gold.g, Theme.gold.b, 0.7) : Theme.line }
        readonly property var root: shell.rootOf(panel.path)
        Label { id: freeText; anchors.right: parent.right; anchors.rightMargin: 18; y: 18; color: Theme.dim; font.family: Theme.mono; font.pixelSize: 12
                text: panel.root && panel.root.total > 0 ? I18n.tr("{n} free", { n: shell.bytes(panel.root.total - panel.root.used) }) : "" }
        // what is here and what is chosen, at the panel's own foot
        Label { x: 18; y: parent.height - 28; width: parent.width - 36; elide: Text.ElideRight; color: Theme.dim; font.family: Theme.mono; font.pixelSize: 11; visible: panel.path.startsWith("/")
                text: (panel.picked().length ? I18n.tr("{n} chosen", { n: panel.picked().length }) + "  ·  " : "") + I18n.tr("{n} items", { n: panel.count })
                      + (shell.typeFilter !== "" ? "  ·  " + I18n.tr("only {n}", { n: I18n.tr(shell.types[shell.typeFilter].name) }) : "")
                      + (shell.findText !== "" ? "  ·  " + I18n.tr("names with “{t}”", { t: shell.findText }) : "")
                      + (panel.root && panel.root.total > 0 ? "  ·  " + I18n.tr("{n} free", { n: shell.bytes(panel.root.total - panel.root.used) }) : "") }
        // where it is: first the drive (as C: or D: in Explorer; a press lists every drive), then every folder on
        // the way, each can be pressed
        // the address written out (Ctrl+L, or a press beside the way): a folder (~ is home), a file (its folder, it chosen),
        // a place under this folder, or smb://, sftp://… mounted as a network place
        property bool typing: false
        onTypingChanged: if (typing) { address.text = path.startsWith("/") ? path.replace(new RegExp("^" + shell.home + "(?=/|$)"), "~") : ""; Qt.callLater(() => { address.selectAll(); address.forceActiveFocus() }) }
        function reachAddress(t) {
            typing = false; keys.forceActiveFocus()
            t = t.trim(); if (t === "") return
            if (/^[a-z]+:\/\//.test(t)) { shell.asking = "server"; return shell.answered(t) }
            const full = t.startsWith("~") ? shell.home + t.slice(1) : (t.startsWith("/") ? t : (path.startsWith("/") ? path + "/" : shell.home + "/") + t)
            addressCheck.running = false
            addressCheck.command = ["sh", "-c", 'if [ -d "$1" ]; then printf "d\t%s" "$(cd -- "$1" && pwd)"; elif [ -e "$1" ]; then printf "f\t%s" "$1"; fi', "sh", full]
            addressCheck.running = true
        }
        // a folder: there; a file: its folder, with it chosen; nothing there: nothing happens
        Process { id: addressCheck
            stdout: StdioCollector { onStreamFinished: { const t = this.text, at = t.slice(2); if (at === "") return
                shell.active = panel.index
                if (t[0] === "d") return panel.go(at)
                panel.go(at.slice(0, at.lastIndexOf("/")) || "/"); const c = {}; c[at] = true; panel.chosen = c; panel.last = at } } }
        Rectangle { visible: panel.typing; x: 14; y: 10; width: crumbs.width + 8; height: 34; radius: 10; color: Theme.card; border.width: 1; border.color: Theme.gold
            Glyph { x: 10; name: "folder"; font.pixelSize: 15; color: Theme.gold; anchors.verticalCenter: parent.verticalCenter }
            TextInput { id: address; x: 34; width: parent.width - 44; anchors.verticalCenter: parent.verticalCenter; color: Theme.cream; font.family: Theme.mono; font.pixelSize: 13; clip: true; selectByMouse: true
                        selectionColor: Theme.coffee
                        onAccepted: panel.reachAddress(text)
                        Keys.onEscapePressed: { panel.typing = false; keys.forceActiveFocus() }
                        onActiveFocusChanged: if (!activeFocus) panel.typing = false } }
        Flickable { id: crumbs; x: 18; y: 12; width: parent.width - 36 - freeText.implicitWidth - 12; height: 32; contentWidth: Math.max(way.width, width); clip: true; boundsBehavior: Flickable.StopAtBounds
            visible: !panel.typing
            onContentWidthChanged: contentX = Math.max(0, contentWidth - width)
            // the bare room beside the way: a press there writes the address
            MouseArea { x: way.width; width: Math.max(0, crumbs.contentWidth - way.width); height: parent.height; cursorShape: Qt.IBeamCursor
                        enabled: panel.path.startsWith("/") && !panel.source && panel.peek === "" && panel.found === null; onClicked: { shell.active = panel.index; panel.typing = true } }
            Row { id: way; spacing: 2
                Rectangle { id: driveButton; visible: !panel.source && panel.peek === "" && panel.found === null; height: 28; radius: 9; width: driveRow.implicitWidth + 20; anchors.verticalCenter: parent.verticalCenter
                    readonly property var at: panel.path === "computer:" || panel.path === "disks:" ? null : (shell.real ? null : panel.root)
                    color: driveHit.containsMouse ? Theme.raised : Theme.card; border.width: 1; border.color: Theme.line
                    Row { id: driveRow; anchors.centerIn: parent; spacing: 6
                        Glyph { name: driveButton.at ? (shell.placeIcons[driveButton.at.kind] || "disc") : (panel.path.startsWith("/") ? "disc" : "device-desktop"); font.pixelSize: 14; color: Theme.gold; anchors.verticalCenter: parent.verticalCenter }
                        Label { text: driveButton.at ? (driveButton.at.kind === "home" ? I18n.tr("Home") : shell.driveName(driveButton.at)) : (panel.path.startsWith("/") ? "/" : I18n.tr("This computer"))
                                font.family: Theme.mono; font.pixelSize: 13; font.weight: 700; anchors.verticalCenter: parent.verticalCenter }
                        Glyph { name: "chevron-down"; font.pixelSize: 13; color: Theme.dim; anchors.verticalCenter: parent.verticalCenter } }
                    MouseArea { id: driveHit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: { shell.active = panel.index; const q = driveButton.mapToItem(overlay, 0, driveButton.height + 4); menu.open(q.x, q.y, shell.driveMenu(panel)) } } }
                Repeater { model: panel.source || panel.peek !== "" || panel.found !== null ? [] : panel.way
                    Row { required property var modelData; required property int index; spacing: 2
                        Glyph { name: "chevron-right"; font.pixelSize: 13; color: Theme.faint; anchors.verticalCenter: parent.verticalCenter }
                        Rectangle { readonly property bool last: parent.index === panel.way.length - 1
                            height: 28; width: crumb.implicitWidth + 18; radius: 9; anchors.verticalCenter: parent.verticalCenter
                            color: last ? Qt.rgba(Theme.gold.r, Theme.gold.g, Theme.gold.b, 0.16) : (crumbHit.containsMouse ? Theme.raised : "transparent"); border.width: last ? 1 : 0; border.color: Qt.rgba(Theme.gold.r, Theme.gold.g, Theme.gold.b, 0.4)
                            Label { id: crumb; anchors.centerIn: parent; text: parent.parent.modelData.name; color: parent.last ? Theme.gold : Theme.dim; font.family: Theme.mono; font.pixelSize: 13; font.weight: parent.last ? 700 : 500 }
                            MouseArea { id: crumbHit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: { shell.active = panel.index; panel.go(parent.parent.modelData.path) } } } } }
                Row { visible: panel.found !== null && panel.peek === "" && !panel.source; spacing: 10
                    Pill { implicitHeight: 30; icon: "chevron-left"; text: I18n.tr("Back"); onPressed: { if (panel.path === "recent:") panel.back(); else panel.found = null } }
                    Label { text: panel.path === "recent:" ? I18n.tr("Recent") : I18n.tr("Found for “{t}”: {n}", { t: panel.looked, n: panel.found ? panel.found.length : 0 }); font.weight: 700; anchors.verticalCenter: parent.verticalCenter } }
                Row { visible: panel.peek !== ""; spacing: 10
                    Pill { implicitHeight: 30; icon: "chevron-left"; text: I18n.tr("Back"); onPressed: shell.hidePeek() }
                    Label { text: I18n.tr("A look"); font.weight: 700; anchors.verticalCenter: parent.verticalCenter } }
                // the sizes: what is measured and the way out
                Row { visible: panel.source !== null; spacing: 10
                    Pill { implicitHeight: 30; icon: "chevron-left"; text: I18n.tr("Back"); onPressed: shell.hideSizes() }
                    Pill { implicitHeight: 30; icon: "arrow-up"; text: I18n.tr("Up"); visible: panel.source !== null && (shell.real ? panel.source.path !== "/" : (shell.rootOf(panel.source.path) || {}).path !== panel.source.path)
                           onPressed: { const s = panel.source; s.up(); if (s.path.startsWith("/")) s.measure() } }
                    Label { text: panel.source ? I18n.tr("What fills {folder}", { folder: panel.source.path.split("/").pop() || "/" }) : ""; font.weight: 700; anchors.verticalCenter: parent.verticalCenter } } } }
        Item { id: ground; x: 12; y: 50; width: parent.width - 24; height: parent.height - 50 - 32; clip: true
            MouseArea { anchors.fill: parent; acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.BackButton | Qt.ForwardButton
                        onPressed: (m) => panel.groundPressed(m, Qt.point(m.x, m.y))
                        onPositionChanged: (m) => panel.bandMove(Qt.point(m.x, m.y))
                        onReleased: panel.banding = false
                        onClicked: (m) => { if (m.button === Qt.RightButton) { const q = mapToItem(overlay, m.x, m.y); shell.groundMenu(q.x, q.y) } }
                        onDoubleClicked: (m) => { if (m.button === Qt.LeftButton && !panel.source && panel.peek === "" && prefs.kept.upOnDouble !== false) panel.up() }
                        onWheel: (w) => { if (w.modifiers & Qt.ControlModifier) { panel.iconSize = Math.max(32, Math.min(256, panel.iconSize + (w.angleDelta.y > 0 ? 16 : -16))); shell.view = "icons"; prefs.set("iconSize", panel.iconSize) } else w.accepted = false } }
            // files dropped here, from the other panel or from any app: into this folder
            DropArea { id: groundDrop; anchors.fill: parent; keys: ["text/uri-list"]; enabled: panel.path.startsWith("/") && !panel.source && panel.peek === ""
                onDropped: (d) => shell.dropInto(d, panel.path, groundDrop) }
            Label { anchors.centerIn: parent; visible: panel.path.startsWith("/") && !panel.source && panel.count === 0 && files.status === FolderListModel.Ready; text: I18n.tr("This folder is empty."); color: Theme.faint }
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
                            text: I18n.tr("Unused room is part of a disk no partition takes: nothing can be kept there until it gets one.") }
                    // partitions are changed by a tool made for it; these two are the ones we suggest
                    Label { width: diskCol.width; wrapMode: Text.WordWrap; color: Theme.dim; font.pixelSize: 12
                            text: I18n.tr("To make, grow or move partitions we suggest KDE Partition Manager or GParted. They need the administrator's password and are installed as packages of the system, not from Flathub.") }
                    Row { spacing: 10
                        Pill { icon: "world-www"; text: "KDE Partition Manager"; onPressed: Quickshell.execDetached(["xdg-open", "https://apps.kde.org/sk/partitionmanager/"]) }
                        Pill { icon: "world-www"; text: "GParted"; onPressed: Quickshell.execDetached(["xdg-open", "https://gparted.org/"]) } } } }
            // This computer, as GNOME Files has it: the folders, the system, the other drives, the network; each with a quiet heading
            Flickable { visible: panel.path === "computer:" && !panel.source; anchors.fill: parent; anchors.margins: 6; contentHeight: sections.height; clip: true; boundsBehavior: Flickable.StopAtBounds
                Column { id: sections; width: parent.width; spacing: 10
                    Repeater { model: [{ head: QT_TR_NOOP("Preferred folders"), kinds: ["home", "desktop", "documents", "download", "pictures", "music", "videos"], root: false },
                                       { head: QT_TR_NOOP("System"), kinds: ["disk"], root: true },
                                       { head: QT_TR_NOOP("On this computer"), kinds: ["disk", "usb", "card", "optical", "image", "phone"], root: false },
                                       { head: QT_TR_NOOP("Network"), kinds: ["network", "cloud"], root: false }]
                        Column { id: section; required property var modelData; width: sections.width; spacing: 8
                            readonly property var items: shell.places.filter(p => section.modelData.kinds.includes(p.kind) && (section.modelData.root ? p.path === "/" && shell.real : p.path !== "/"))
                            visible: items.length > 0
                            Label { text: I18n.tr(section.modelData.head); font.weight: 700; font.pixelSize: 13; color: Theme.faint; leftPadding: 4; topPadding: 6 }
                            Flow { width: parent.width; spacing: 12
                                Repeater { model: section.items
                                    Rectangle { required property var modelData; width: 220; height: 76; radius: 16; color: tileHit.containsMouse ? Theme.raised : Theme.card
                        Glyph { x: 18; name: shell.placeIcons[parent.modelData.kind]; font.pixelSize: 26; color: Theme.gold; anchors.verticalCenter: parent.verticalCenter }
                        Column { x: 58; width: parent.width - 70; anchors.verticalCenter: parent.verticalCenter; spacing: 2
                            Label { width: parent.width; font.weight: 700; elide: Text.ElideRight; text: shell.drives.includes(parent.parent.modelData.kind) ? shell.driveName(parent.parent.modelData) : I18n.tr(shell.placeNames[parent.parent.modelData.kind]) }
                            Label { width: parent.width; color: Theme.dim; font.pixelSize: 12; elide: Text.ElideRight
                                    text: shell.drives.includes(parent.parent.modelData.kind) ? I18n.tr(shell.driveKinds[parent.parent.modelData.kind]) + (parent.parent.modelData.name.split(" · ")[1] ? " · " + parent.parent.modelData.name.split(" · ")[1] : "")
                                                                                                  + (parent.parent.modelData.path === "" ? " · " + I18n.tr("not connected") : "") : "" } }
                        // how full the drive is, as the graphs have it (green, gold, red)
                        Rectangle { visible: parent.modelData.total > 0; x: 58; y: parent.height - 12; width: parent.width - 70; height: 4; radius: 2; color: Theme.line
                            Rectangle { width: parent.width * parent.parent.modelData.used / parent.parent.modelData.total; height: parent.height; radius: 2; color: Theme.heat(parent.parent.modelData.used / parent.parent.modelData.total) } }
                        MouseArea { id: tileHit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { shell.active = panel.index; shell.reach(parent.modelData) } } } } } } } } }
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
                Repeater { model: [{ by: "name", name: QT_TR_NOOP("File name"), w: -shell.columnsWidth }].concat(shell.shownColumns)
                    Rectangle { required property var modelData; width: modelData.w < 0 ? heads.width + modelData.w : modelData.w; height: 26; radius: 7; color: headHit.containsMouse ? Theme.card : "transparent"
                        Label { x: parent.modelData.by === "name" ? 42 : 0; width: parent.width - (parent.modelData.by === "name" ? 42 : 8); horizontalAlignment: parent.modelData.by === "name" ? Text.AlignLeft : Text.AlignRight
                                text: I18n.tr(parent.modelData.name).toUpperCase() + (panel.sortBy === parent.modelData.by ? (panel.sortDown ? " ↓" : " ↑") : ""); color: panel.sortBy === parent.modelData.by ? Theme.gold : Theme.faint
                                font.family: Theme.mono; font.pixelSize: 11; font.weight: 700; font.letterSpacing: 0.8; anchors.verticalCenter: parent.verticalCenter }
                        MouseArea { id: headHit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; enabled: parent.modelData.by !== "attr"; onClicked: panel.sort(parent.modelData.by) } } }
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.line } }
            ListView { id: list; visible: shell.view === "details" && panel.path.startsWith("/") && !panel.source && panel.peek === ""; y: 28; width: parent.width; height: parent.height - 28; model: shown; clip: true; boundsBehavior: Flickable.StopAtBounds
                MouseArea { z: -1; width: list.width; height: Math.max(list.height, list.contentHeight); preventStealing: true; acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.BackButton | Qt.ForwardButton
                    onPressed: (m) => panel.groundPressed(m, mapToItem(ground, m.x, m.y))
                    onPositionChanged: (m) => panel.bandMove(mapToItem(ground, m.x, m.y))
                    onReleased: panel.banding = false
                    onClicked: (m) => { if (m.button === Qt.RightButton) { const q = mapToItem(overlay, m.x, m.y); shell.groundMenu(q.x, q.y) } }
                    onDoubleClicked: (m) => { if (m.button === Qt.LeftButton && prefs.kept.upOnDouble !== false) panel.up() } }
                delegate: Rectangle { id: row; required property string fileName
                    required property string filePath
                    required property bool fileIsDir
                    required property var fileSize
                    required property date fileModified
                    required property int index
                    width: list.width; height: 38; radius: 0
                    readonly property color tint: shell.colourOf(panel.tags[filePath])     // its colour, if it has one: the row takes it on
                    readonly property bool picked: !!panel.chosen[filePath]
                    // chosen: the commander's lit row, coffee towards gold, a gold line above and below
                    // its own rectangle, shown and hidden: a gradient set back to null left the row tinted after it was let go
                    Rectangle { anchors.fill: parent; visible: row.picked
                        gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: Qt.rgba(Theme.coffee.r, Theme.coffee.g, Theme.coffee.b, 0.55) } GradientStop { position: 1; color: Qt.rgba(Theme.coffee.r, Theme.coffee.g, Theme.coffee.b, 0.22) } } }
                    color: rowHover.hovered ? Qt.rgba(Theme.cream.r, Theme.cream.g, Theme.cream.b, 0.05) : (panel.tags[filePath] ? Qt.rgba(tint.r, tint.g, tint.b, 0.16) : "transparent")
                    Rectangle { visible: row.picked; width: parent.width; height: 1; color: Theme.gold; opacity: 0.8 }
                    Rectangle { visible: row.picked; y: parent.height - 1; width: parent.width; height: 1; color: Theme.gold; opacity: 0.8 }
                    Rectangle { visible: !row.picked; y: parent.height - 1; x: 8; width: parent.width - 16; height: 1; color: Theme.line; opacity: 0.45 }
                    // measured: its share of the largest thing here, as a bar behind the row
                    Rectangle { visible: panel.measured && panel.sizes[row.filePath] !== undefined; x: 4; y: 4; height: parent.height - 8; radius: 6; color: Theme.coffee; opacity: 0.38
                                width: (parent.width - 8) * (panel.sizes[row.filePath] || 0) / panel.largest; Behavior on width { NumberAnimation { duration: 220 } } }
                    Rectangle { visible: !!panel.tags[row.filePath]; x: 2; y: 7; width: 4; height: parent.height - 14; radius: 2; color: shell.colourOf(panel.tags[row.filePath]) }
                    Image { visible: !!panel.launchers[row.filePath]; x: 12; width: 20; height: 20; anchors.verticalCenter: parent.verticalCenter; sourceSize.width: 40; sourceSize.height: 40
                            source: panel.launchers[row.filePath] ? panel.launcherIcon(row.filePath) : ""; fillMode: Image.PreserveAspectFit; asynchronous: true }
                    Glyph { visible: !panel.launchers[row.filePath]; x: 12; width: 20; anchors.verticalCenter: parent.verticalCenter; name: shell.glyphOf(row.fileName, row.fileIsDir); font.pixelSize: 18
                            color: row.picked ? Theme.gold : (row.fileIsDir ? Qt.lighter(Theme.coffee, 1.35) : Theme.gold); opacity: row.fileIsDir || row.picked ? 1 : 0.8 }
                    // a folder ends in /, in the colour of coffee, as the sketch has it; the figures are monospace, aligned
                    Label { id: rowName; x: 42; width: parent.width - 42 - shell.columnsWidth - 10; opacity: panel.gits[row.filePath] === "ignored" ? 0.55 : 1
                            text: panel.launchers[row.filePath] ? panel.launchers[row.filePath].name : row.fileName + (row.fileIsDir ? "/" : ""); anchors.verticalCenter: parent.verticalCenter; elide: Text.ElideMiddle
                            font.family: Theme.mono; font.pixelSize: 13; font.weight: row.picked ? 700 : 500; color: row.picked ? Theme.gold : (row.fileIsDir ? Qt.lighter(Theme.coffee, 1.35) : Theme.cream) }
                    // its state in Git: changed, new; an ignored one is quieter
                    Label { visible: !!panel.gits[row.filePath] && panel.gits[row.filePath] !== "ignored"; x: 42 + Math.min(rowName.contentWidth, rowName.width) + 8; anchors.verticalCenter: parent.verticalCenter
                            text: panel.gits[row.filePath] === "new" ? I18n.tr("new") : I18n.tr("changed"); font.pixelSize: 10; font.weight: 700
                            color: panel.gits[row.filePath] === "new" ? Theme.ok : Theme.gold }
                    Label { visible: shell.columns.includes("type"); x: parent.width - shell.columnAt("type"); width: 102; horizontalAlignment: Text.AlignRight; font.family: Theme.mono; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter
                            text: row.fileIsDir ? I18n.tr("Folder") : (FileIcons.ending(row.fileName).toUpperCase() || "—"); color: row.picked ? Theme.cream : Theme.dim }
                    Label { visible: shell.columns.includes("size"); x: parent.width - shell.columnAt("size"); width: 92; horizontalAlignment: Text.AlignRight; font.family: Theme.mono; anchors.verticalCenter: parent.verticalCenter
                            text: panel.sizes[row.filePath] !== undefined ? shell.bytes(panel.sizes[row.filePath]) : (row.fileIsDir ? (panel.measured ? "…" : "<DIR>") : shell.bytes(row.fileSize))
                            color: row.picked ? Theme.gold : (panel.measured ? Theme.cream : Theme.dim); font.pixelSize: 12; font.weight: row.picked ? 700 : 400 }
                    Label { visible: shell.columns.includes("date"); x: parent.width - shell.columnAt("date"); width: 130; horizontalAlignment: Text.AlignRight; font.family: Theme.mono; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter; color: row.picked ? Theme.cream : Theme.dim
                            text: new Date(row.fileModified).toDateString() === new Date().toDateString() ? I18n.tr("Today") + " " + Qt.formatTime(row.fileModified, "hh:mm") : Qt.formatDateTime(row.fileModified, "dd.MM. hh:mm") }
                    Label { visible: shell.columns.includes("attr"); x: parent.width - shell.columnAt("attr"); width: 112; horizontalAlignment: Text.AlignRight; font.family: Theme.mono; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter
                            text: panel.modes[row.filePath] || ""; color: row.picked ? Theme.cream : Theme.faint }
                    Rectangle { anchors.fill: parent; radius: 9; color: "transparent"; border.width: 2; border.color: Theme.gold; visible: rowDrop.containsDrag }
                    DropArea { id: rowDrop; anchors.fill: parent; keys: ["text/uri-list"]; enabled: row.fileIsDir; onDropped: (d) => shell.dropInto(d, row.filePath, rowDrop) }
                    HoverHandler { id: rowHover }   // not MouseArea.containsMouse: it stays lit when a refresh moves the rows
                    MouseArea { id: rowHit; anchors.fill: parent; preventStealing: true; acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton | Qt.BackButton | Qt.ForwardButton
                        property point from
                        property bool bare: false
                        onPressed: (m) => { bare = m.button === Qt.LeftButton && m.x > 42 + Math.min(rowName.width, rowName.contentWidth) + 24 && m.x < parent.width - shell.columnsWidth - 10
                                            if (bare) return panel.groundPressed(m, mapToItem(ground, m.x, m.y))
                                            keys.forceActiveFocus(); shell.active = panel.index; from = Qt.point(m.x, m.y); if (panel.extra(m) || m.button === Qt.MiddleButton) return
                                            if (m.button === Qt.LeftButton || !panel.chosen[row.filePath]) panel.press(row.filePath, row.index, m.button === Qt.LeftButton ? m.modifiers : 0) }
                        onReleased: panel.banding = false
                        onPositionChanged: (m) => { if (panel.banding) return panel.bandMove(mapToItem(ground, m.x, m.y))
                                                    if ((m.buttons & (Qt.LeftButton | Qt.RightButton)) && Math.abs(m.x - from.x) + Math.abs(m.y - from.y) > 10) shell.drag(panel.carried(row.filePath), !!(m.buttons & Qt.RightButton)) }
                        onClicked: (m) => { if (m.button === Qt.RightButton) { const q = mapToItem(overlay, m.x, m.y); shell.itemMenu(row.filePath, row.fileIsDir, q.x, q.y) }
                                            else if (m.button === Qt.MiddleButton && row.fileIsDir) { shell.dual = true; shell.other.go(row.filePath) } }
                        onDoubleClicked: (m) => { if (m.button === Qt.LeftButton && !bare) shell.open(row.filePath, row.fileIsDir) } } } }
            GridView { id: grid; visible: shell.view !== "details" && shell.view !== "photos" && panel.path.startsWith("/") && !panel.source && panel.peek === ""; anchors.fill: parent; model: shown; clip: true
                readonly property bool wide: shell.view === "small" || shell.view === "tiles"     // the icon left, the name beside it
                readonly property real icon: shell.view === "small" ? 20 : (shell.view === "tiles" ? 48 : panel.iconSize)
                cellWidth: shell.view === "small" ? 250 : (shell.view === "tiles" ? 300 : panel.iconSize + 60)
                cellHeight: shell.view === "small" ? 32 : (shell.view === "tiles" ? 72 : panel.iconSize + 56); boundsBehavior: Flickable.StopAtBounds
                MouseArea { z: -1; width: grid.width; height: Math.max(grid.height, grid.contentHeight); preventStealing: true; acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.BackButton | Qt.ForwardButton
                    onPressed: (m) => panel.groundPressed(m, mapToItem(ground, m.x, m.y))
                    onPositionChanged: (m) => panel.bandMove(mapToItem(ground, m.x, m.y))
                    onReleased: panel.banding = false
                    onClicked: (m) => { if (m.button === Qt.RightButton) { const q = mapToItem(overlay, m.x, m.y); shell.groundMenu(q.x, q.y) } }
                    onDoubleClicked: (m) => { if (m.button === Qt.LeftButton && prefs.kept.upOnDouble !== false) panel.up() } }
                delegate: Item { id: cell; required property string fileName
                    required property string filePath
                    required property bool fileIsDir
                    required property var fileSize
                    required property int index
                    readonly property bool roomy: !grid.wide && panel.iconSize >= 96
                    width: grid.cellWidth; height: grid.cellHeight
                    Rectangle { anchors.fill: parent; anchors.margins: 3; radius: 10; border.width: cellDrop.containsDrag ? 2 : 0; border.color: Theme.gold; color: panel.chosen[cell.filePath] ? Qt.rgba(Theme.gold.r, Theme.gold.g, Theme.gold.b, 0.24) : (cellHover.hovered ? Theme.card
                                      : (panel.tags[cell.filePath] ? Qt.rgba(Qt.color(shell.colourOf(panel.tags[cell.filePath])).r, Qt.color(shell.colourOf(panel.tags[cell.filePath])).g, Qt.color(shell.colourOf(panel.tags[cell.filePath])).b, 0.16) : "transparent")) }
                    Image { id: cellIcon; x: grid.wide ? 10 : (parent.width - width) / 2; y: grid.wide ? (parent.height - height) / 2 : 10; width: grid.icon; height: grid.icon
                            source: cell.thumb || panel.launcherIcon(cell.filePath) || FileIcons.of(cell.fileName, cell.filePath, cell.fileIsDir); sourceSize.width: Math.max(64, grid.icon * 2); sourceSize.height: Math.max(64, grid.icon * 2); fillMode: Image.PreserveAspectFit; asynchronous: true }
                    // its state in Git, at the icon's top corner: gold changed, green new; an ignored one is quieter
                    Rectangle { visible: !!panel.gits[cell.filePath] && panel.gits[cell.filePath] !== "ignored"; z: 2; width: Math.max(9, grid.icon * 0.13); height: width; radius: width / 2
                                x: cellIcon.x + cellIcon.width - width * 0.8; y: cellIcon.y - height * 0.1; color: panel.gits[cell.filePath] === "new" ? Theme.ok : Theme.gold }
                    Rectangle { visible: !!panel.tags[cell.filePath]; z: 2; width: Math.max(10, grid.icon * 0.16); height: width; radius: width / 2; border.width: 2; border.color: Theme.surface
                                x: cellIcon.x + cellIcon.width - width * 0.8; y: cellIcon.y + cellIcon.height - height * 0.9; color: shell.colourOf(panel.tags[cell.filePath]) }
                    // a PDF shows its first page and a video a frame of it, once the icons are big enough to see them
                    readonly property bool paged: !fileIsDir && grid.icon >= 48 && ["pdf", "mp4", "mkv", "webm", "avi", "mov", "m4v", "wmv", "mpg", "mpeg"].includes(FileIcons.ending(fileName))
                    property string thumb: ""
                    Process { running: cell.paged; command: ["latte-files", "thumb", cell.filePath]
                              stdout: StdioCollector { onStreamFinished: { const t = this.text.trim(); cell.thumb = t ? "file://" + t : "" } } }
                    // a folder shows the pictures it holds, as Explorer's do, once the icons are big enough to see them
                    FolderListModel { id: inside; folder: cell.fileIsDir && cell.roomy ? "file://" + cell.filePath : ""; showDirs: false; sortField: FolderListModel.Time
                                      nameFilters: FileIcons.pictures.map(e => "*." + e).concat(FileIcons.pictures.map(e => "*." + e.toUpperCase())) }
                    Repeater { model: cell.roomy ? Math.min(2, inside.count) : 0
                        Image { required property int index; asynchronous: true; fillMode: Image.PreserveAspectCrop; sourceSize.width: 256
                                source: "file://" + inside.get(index, "filePath"); width: cellIcon.width * 0.46; height: cellIcon.height * 0.52
                                x: cellIcon.x + cellIcon.width * (0.18 + 0.26 * index); y: cellIcon.y + cellIcon.height * (0.30 - 0.04 * index); rotation: index ? 6 : -4
                                Rectangle { anchors.fill: parent; color: "transparent"; border.width: 2; border.color: "#f3ebdd" } } }
                    Column { id: cellText; x: grid.wide ? cellIcon.width + 20 : 6; y: grid.wide ? (parent.height - height) / 2 : grid.icon + 14; width: grid.wide ? parent.width - cellIcon.width - 28 : parent.width - 12; spacing: 2
                        Label { id: cellName; width: parent.width; horizontalAlignment: grid.wide ? Text.AlignLeft : Text.AlignHCenter; text: panel.launchers[cell.filePath] ? panel.launchers[cell.filePath].name : cell.fileName; opacity: panel.gits[cell.filePath] === "ignored" ? 0.55 : 1; font.pixelSize: grid.wide ? 13 : 12
                                wrapMode: grid.wide ? Text.NoWrap : Text.WrapAnywhere; elide: grid.wide ? Text.ElideMiddle : Text.ElideNone; maximumLineCount: grid.wide ? 1 : 2 }
                        Label { visible: shell.view === "tiles"; width: parent.width; elide: Text.ElideRight; color: Theme.dim; font.pixelSize: 11
                                text: cell.fileIsDir ? I18n.tr("File folder") : I18n.tr("{ext} file", { ext: FileIcons.ending(cell.fileName).toUpperCase() || "—" }) }
                        Label { visible: shell.view === "tiles" && !cell.fileIsDir; width: parent.width; color: Theme.faint; font.pixelSize: 11; text: shell.bytes(cell.fileSize) } }
                    DropArea { id: cellDrop; anchors.fill: parent; keys: ["text/uri-list"]; enabled: cell.fileIsDir; onDropped: (d) => shell.dropInto(d, cell.filePath, cellDrop) }
                    HoverHandler { id: cellHover }
                    MouseArea { id: cellHit; anchors.fill: parent; preventStealing: true; acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton | Qt.BackButton | Qt.ForwardButton
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
            // what Find found below this folder: by name first, then inside files; a press goes to it, twice opens it
            Rectangle { visible: panel.found !== null; anchors.fill: parent; color: Qt.darker(Theme.card, 1.18); radius: 12
                MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }
                Label { anchors.centerIn: parent; visible: panel.found !== null && panel.found.length === 0; color: Theme.faint
                        text: finder.running ? I18n.tr("Looking…") : I18n.tr("Nothing found.") }
                ListView { id: foundList; anchors.fill: parent; anchors.margins: 4; clip: true; boundsBehavior: Flickable.StopAtBounds; model: panel.found || []
                    delegate: Rectangle { id: hit; required property var modelData; width: foundList.width; height: 40; radius: 8
                        readonly property string name: modelData.path.split("/").pop()
                        color: hitHover.hovered ? Qt.rgba(Theme.cream.r, Theme.cream.g, Theme.cream.b, 0.05) : "transparent"
                        HoverHandler { id: hitHover }
                        Glyph { x: 12; width: 20; anchors.verticalCenter: parent.verticalCenter; name: shell.glyphOf(hit.name, false); font.pixelSize: 17; color: Theme.gold }
                        Column { x: 42; width: parent.width - 42 - howText.width - 20; anchors.verticalCenter: parent.verticalCenter
                            Label { width: parent.width; elide: Text.ElideMiddle; text: hit.name; font.family: Theme.mono; font.pixelSize: 13; font.weight: 600 }
                            Label { width: parent.width; elide: Text.ElideMiddle; text: panel.path.startsWith("/") ? (hit.modelData.path.slice(panel.path.length + 1, -hit.name.length - 1) || ".")
                                                                                    : (hit.modelData.path.slice(0, -hit.name.length - 1).replace(shell.home, "~") || "/"); color: Theme.faint; font.family: Theme.mono; font.pixelSize: 11 } }
                        Label { id: howText; anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter; color: Theme.dim; font.pixelSize: 11
                                text: hit.modelData.how === "text" ? I18n.tr("in the text") : hit.modelData.how === "dup" ? I18n.tr("same as group {n}", { n: hit.modelData.group })
                                                                    : (hit.modelData.when ? shell.when(hit.modelData.when) : "") }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: { const at = hit.modelData.path, up = at.slice(0, at.lastIndexOf("/")) || "/"; shell.active = panel.index; panel.go(up); const c = {}; c[at] = true; panel.chosen = c; panel.last = at }
                            onDoubleClicked: shell.enter(hit.modelData.path) } } } }
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
        heading: here.source ? I18n.tr("Sizes") : here.path === "recent:" ? I18n.tr("Recent") : here.path === "disks:" ? I18n.tr("Disks and devices") : (here.path === "computer:" ? I18n.tr("This computer") : (here.path === shell.home ? I18n.tr("Home") : (here.path.split("/").pop() || "/")))
        implicitWidth: 1180; implicitHeight: 760
        arrows: true; canGoBack: here.before.length > 0; onBack: here.back(); canGoForward: here.ahead.length > 0; onForward: here.forward()
        // in a narrow window the buttons keep only their icons, so none falls off the edge
        readonly property bool narrow: width < 1060
        tools: [
            Pill { implicitHeight: 34; icon: "arrow-up"; text: win.narrow ? "" : I18n.tr("Up"); onPressed: here.up() },
            Pill { id: viewPill; implicitHeight: 34; icon: shell.view === "details" ? "list" : "layout-grid"; text: win.narrow ? "" : I18n.tr("View")
                   onPressed: { const q = viewPill.mapToItem(overlay, 0, viewPill.height + 4); menu.open(q.x, Math.max(0, q.y), shell.views()) } },
            // one panel as Explorer, or two as a commander: one switch, gold with two
            Pill { implicitHeight: 34; icon: shell.dual ? "layout-columns" : "square-rounded"; text: win.narrow ? "" : (shell.dual ? I18n.tr("Two panels") : I18n.tr("One panel")); strong: shell.dual
                   onPressed: { shell.dual = !shell.dual; if (!shell.dual) shell.active = 0 } },
            Pill { id: setPill; implicitHeight: 34; icon: "settings"; onPressed: { const q = setPill.mapToItem(overlay, 0, setPill.height + 4); menu.open(q.x, Math.max(0, q.y), shell.settingsMenu()) } }
        ]
        side: [
            // the side scrolls when it holds more than the window is tall (the tree, many drives)
            Flickable { anchors.fill: parent; contentHeight: sideCol.height + 28; clip: true; boundsBehavior: Flickable.StopAtBounds
            Column { id: sideCol; x: 14; y: 14; spacing: 4
                Row { x: 6; spacing: 10; height: 40
                    Glyph { name: "folders"; color: Theme.gold; font.pixelSize: 22; anchors.verticalCenter: parent.verticalCenter }
                    Label { text: "DualBrew"; font.pixelSize: 17; font.weight: 800; anchors.verticalCenter: parent.verticalCenter } }
                Item { width: 1; height: 6 }
                Nav { text: I18n.tr("This computer"); icon: "device-desktop"; on: here.path === "computer:"; onPressed: here.go("computer:") }
                Nav { text: I18n.tr("Recent"); icon: "history"; on: here.path === "recent:"; onPressed: here.go("recent:") }
                Column { spacing: 4; visible: shell.shows("places")
                    Repeater { model: shell.places.filter(p => !shell.drives.includes(p.kind) && p.kind !== "favourite")
                        Nav { required property var modelData; text: I18n.tr(shell.placeNames[modelData.kind]); icon: shell.placeIcons[modelData.kind]; on: here.path === modelData.path; onPressed: here.go(modelData.path) } } }
                // the folder tree: a press on the arrow opens a folder, on the name goes there
                Column { visible: prefs.kept.side_tree === true; spacing: 0
                    Label { x: 8; height: 30; verticalAlignment: Text.AlignBottom; text: I18n.tr("FOLDERS"); color: Theme.faint; font.pixelSize: 11; font.weight: 700; font.letterSpacing: 0.8 }
                    Flickable { width: 222; height: Math.min(treeCol.height, 300); contentHeight: treeCol.height; clip: true; boundsBehavior: Flickable.StopAtBounds
                        Column { id: treeCol; width: 222
                            Repeater { model: shell.tree
                                Rectangle { id: tn; required property var modelData; required property int index; width: 222; height: 28; radius: 8
                                    readonly property bool on: here.path === modelData.path
                                    color: on ? Theme.raised : (tnHit.containsMouse ? Theme.card : "transparent")
                                    Glyph { id: tnArrow; x: 6 + tn.modelData.depth * 14; width: 16; anchors.verticalCenter: parent.verticalCenter; font.pixelSize: 13; color: Theme.faint
                                            name: tn.modelData.open ? "chevron-down" : "chevron-right"
                                        MouseArea { anchors.fill: parent; anchors.margins: -5; cursorShape: Qt.PointingHandCursor; onClicked: shell.treeToggle(tn.index) } }
                                    Glyph { id: tnIcon; x: tnArrow.x + 18; anchors.verticalCenter: parent.verticalCenter; font.pixelSize: 15; color: tn.on ? Theme.gold : Theme.dim
                                            name: tn.modelData.depth === 0 ? (shell.real ? "disc" : "home") : "folder" }
                                    Label { x: tnIcon.x + 22; width: parent.width - x - 6; anchors.verticalCenter: parent.verticalCenter; elide: Text.ElideRight; font.pixelSize: 13
                                            text: tn.modelData.depth === 0 ? (shell.real ? "/" : I18n.tr("Home")) : tn.modelData.name; color: tn.on ? Theme.cream : Theme.dim }
                                    MouseArea { id: tnHit; x: tnIcon.x - 2; width: parent.width - x; height: parent.height; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                onClicked: here.go(tn.modelData.path); onDoubleClicked: shell.treeToggle(tn.index) } } } } } }
                Column { spacing: 4; visible: shell.shows("favourites")
                    Label { x: 8; height: 30; verticalAlignment: Text.AlignBottom; text: I18n.tr("FAVOURITES"); color: Theme.faint; font.pixelSize: 11; font.weight: 700; font.letterSpacing: 0.8 }
                    Repeater { model: shell.places.filter(p => p.kind === "favourite")
                        Nav { required property var modelData; text: modelData.name; icon: "star"; on: here.path === modelData.path; onPressed: here.go(modelData.path)
                              tail: "x"; onTailPressed: shell.pin(modelData.path, false) } }
                    Nav { text: I18n.tr("Add a favourite folder"); icon: "star"; opacity: 0.75; visible: here.path.startsWith("/") && !shell.places.some(p => p.kind === "favourite" && p.path === here.path)
                          onPressed: shell.pin(here.path, true) } }
                Column { spacing: 4; visible: shell.shows("drives")
                    // the heading opens the overview of every disk, its partitions and how full each is
                    Rectangle { width: 222; height: 30; radius: 8; color: drivesHit.containsMouse || here.path === "disks:" ? Theme.card : "transparent"
                        Label { x: 8; anchors.bottom: parent.bottom; anchors.bottomMargin: 4; text: I18n.tr("DRIVES"); color: here.path === "disks:" ? Theme.gold : (drivesHit.containsMouse ? Theme.cream : Theme.faint); font.pixelSize: 11; font.weight: 700; font.letterSpacing: 0.8 }
                        Glyph { anchors.right: parent.right; anchors.rightMargin: 8; anchors.bottom: parent.bottom; anchors.bottomMargin: 3; name: "chart-pie"; font.pixelSize: 14; color: drivesHit.containsMouse || here.path === "disks:" ? Theme.gold : Theme.faint }
                        MouseArea { id: drivesHit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: here.go("disks:") } }
                    // each drive as a card of its own (inspo/latteOS dualbrew.png): its name, its size, how full, what is used
                    Repeater { model: shell.places.filter(p => ["disk", "usb", "card", "optical", "image", "phone"].includes(p.kind) && (p.path !== "/" || shell.real))
                        Rectangle { id: drv; required property var modelData; width: 222; radius: 12; height: drv.modelData.total > 0 ? 62 : 40
                            readonly property bool on: modelData.path !== "" && here.path === modelData.path
                            readonly property real f: modelData.total > 0 ? modelData.used / modelData.total : 0
                            color: on ? Theme.raised : (drvHit.containsMouse ? Theme.card : "transparent"); border.width: on ? 1 : 0; border.color: Theme.line
                            opacity: modelData.path === "" ? 0.6 : 1
                            Glyph { x: 10; y: 11; name: shell.placeIcons[drv.modelData.kind]; font.pixelSize: 16; color: drv.on ? Theme.gold : Theme.dim }
                            Label { x: 34; y: 9; width: parent.width - 34 - sizeText.implicitWidth - (ejectHit.visible ? 30 : 12); elide: Text.ElideRight; font.weight: 700; font.pixelSize: 13
                                    text: shell.driveName(drv.modelData); color: drv.on ? Theme.gold : Theme.cream }
                            Label { id: sizeText; anchors.right: parent.right; anchors.rightMargin: ejectHit.visible ? 30 : 10; y: 11; font.family: Theme.mono; font.pixelSize: 11; font.weight: 700; color: Theme.dim
                                    text: drv.modelData.total > 0 ? shell.bytes(drv.modelData.total) : "" }
                            Rectangle { visible: drv.modelData.total > 0; x: 10; y: 32; width: parent.width - 20; height: 5; radius: 3; color: Theme.line
                                Rectangle { width: parent.width * drv.f; height: 5; radius: 3; color: shell.fullness(drv.f) } }
                            Label { visible: drv.modelData.total > 0; x: 10; y: 42; font.family: Theme.mono; font.pixelSize: 10; color: Theme.faint; text: I18n.tr("Used: {n}", { n: shell.bytes(drv.modelData.used) }) }
                            Label { visible: drv.modelData.total > 0; anchors.right: parent.right; anchors.rightMargin: 10; y: 42; font.family: Theme.mono; font.pixelSize: 10; color: Theme.faint; text: Math.round(drv.f * 100) + " %" }
                            MouseArea { id: drvHit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: shell.reach(drv.modelData) }
                            Glyph { id: ejectHit; visible: shell.canEject(drv.modelData); anchors.right: parent.right; anchors.rightMargin: 8; y: 10; name: "player-eject"; font.pixelSize: 15; color: Theme.dim
                                MouseArea { anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor; onClicked: shell.eject(drv.modelData) } } } } }
                Column { spacing: 4; visible: shell.shows("network")
                    Label { x: 8; height: 30; verticalAlignment: Text.AlignBottom; text: I18n.tr("NETWORK AND CLOUD"); color: Theme.faint; font.pixelSize: 11; font.weight: 700; font.letterSpacing: 0.8 }
                    Repeater { model: shell.places.filter(p => p.kind === "network" || p.kind === "cloud")
                        Nav { required property var modelData; text: shell.driveName(modelData); icon: shell.placeIcons[modelData.kind]
                              opacity: modelData.path === "" ? 0.6 : 1; on: modelData.path !== "" && here.path === modelData.path; onPressed: shell.reach(modelData)
                              tail: shell.canEject(modelData) ? "player-eject" : ""; onTailPressed: shell.eject(modelData) } }
                    Nav { id: cloudNav; text: I18n.tr("Add a cloud or a place…"); icon: "cloud-plus"; onPressed: { const q = cloudNav.mapToItem(overlay, 40, cloudNav.height); shell.addCloud(q.x, q.y) } } }
                Column { spacing: 4; visible: shell.shows("types")
                    // the quick filter of types: only such files show in the panels, folders always (inspo/latteOS dualbrew.png)
                    Label { x: 8; height: 30; verticalAlignment: Text.AlignBottom; text: I18n.tr("QUICK FILTER OF TYPES"); color: Theme.faint; font.pixelSize: 11; font.weight: 700; font.letterSpacing: 0.8 }
                    Flow { x: 8; width: 210; spacing: 6
                        Repeater { model: ["pictures", "documents", "music", "video", "archives", "code"]
                            Rectangle { required property string modelData; height: 24; radius: 8; width: typeText.implicitWidth + 16
                                readonly property bool on: shell.typeFilter === modelData
                                color: on ? Theme.gold : (typeHit.containsMouse ? Theme.raised : Theme.card)
                                Label { id: typeText; anchors.centerIn: parent; text: I18n.tr(shell.types[parent.modelData].name); color: parent.on ? Theme.inkOnGold : Theme.dim; font.pixelSize: 11; font.weight: 700 }
                                MouseArea { id: typeHit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: shell.typeFilter = parent.on ? "" : parent.modelData } } } } }
                Item { width: 1; height: 10 }
                Nav { text: I18n.tr("The real structure"); icon: shell.real ? "eye" : "eye-off"; on: shell.real; onPressed: shell.real = !shell.real } } }
        ]
        foot: [
            // what is here and what is chosen
            Label { x: 24; anchors.verticalCenter: parent.verticalCenter; color: Theme.inkOnCoffee; visible: shell.asking === "" && (shell.said !== "" || !(shell.aboutFor !== "" && here.picked().length === 1))
                    text: shell.said !== "" ? shell.said : !here.path.startsWith("/") ? I18n.tr("Your folders and the disks")
                          : (here.picked().length ? I18n.tr("{n} chosen", { n: here.picked().length }) : I18n.tr("{n} items", { n: here.count }))
                            + (here.measured ? "   ·   " + (here.measuring ? I18n.tr("measuring… {size} so far", { size: shell.bytes(here.total) }) : I18n.tr("{size} in all", { size: shell.bytes(here.total) }))
                                             : (here.picked().length ? "" : "   ·   " + I18n.tr("Space: how much each folder holds"))) },
            // the one chosen: what it is (a picture's size and camera, a folder's items and size)
            Row { x: 24; anchors.verticalCenter: parent.verticalCenter; spacing: 10; visible: shell.asking === "" && shell.said === "" && shell.aboutFor !== "" && here.picked().length === 1
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
            Row { anchors.right: parent.right; anchors.rightMargin: 20; anchors.verticalCenter: parent.verticalCenter; spacing: 8; visible: (shell.dual || !!prefs.kept.keys) && shell.asking === "" && shell.job === null
                Repeater { model: [{ key: "F3", name: QT_TR_NOOP("View"), what: "view" }, { key: "F4", name: QT_TR_NOOP("Edit"), what: "edit" }, { key: "F5", name: QT_TR_NOOP("Copy"), what: "copy" }, { key: "F6", name: QT_TR_NOOP("Move"), what: "move" }, { key: "F7", name: QT_TR_NOOP("New folder"), what: "folder" }, { key: "F8", name: QT_TR_NOOP("Delete"), what: "trash" }, { key: "F10", name: QT_TR_NOOP("Quit"), what: "quit" }]
                    Rectangle { required property var modelData; height: 30; radius: 8; width: fRow.implicitWidth + 18; color: fHit.containsMouse ? Qt.rgba(0, 0, 0, 0.45) : Qt.rgba(0, 0, 0, 0.3); border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.06)
                        Row { id: fRow; anchors.centerIn: parent; spacing: 6
                            Label { text: parent.parent.modelData.key; color: Theme.gold; font.family: Theme.mono; font.pixelSize: 12; font.weight: 800 }
                            Label { text: I18n.tr(parent.parent.modelData.name); color: Theme.inkOnCoffee; font.family: Theme.mono; font.pixelSize: 12; font.weight: 600 } }
                        MouseArea { id: fHit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: shell.command(parent.modelData.what) } } } },
            // a name is asked for here
            Row { x: 24; anchors.verticalCenter: parent.verticalCenter; spacing: 10; visible: shell.asking !== ""
                Label { text: shell.asking === "rename" ? I18n.tr("New name:") : (shell.asking === "server" ? I18n.tr("Address:") : (shell.asking === "split" ? I18n.tr("Pieces of (MB):") : shell.asking === "select" ? I18n.tr("Choose what matches:") : (shell.asking === "unselect" ? I18n.tr("Let go of what matches:") : I18n.tr("Name:")))); color: Theme.inkOnCoffee; anchors.verticalCenter: parent.verticalCenter }
                Field { id: answer; width: 360; icon: "pencil"; function focusIt() { children[1].forceActiveFocus(); children[1].selectAll() }
                        onAccepted: { shell.answered(text); keys.forceActiveFocus() } }
                Pill { implicitHeight: 34; icon: "check"; strong: true; text: I18n.tr("OK"); onPressed: { shell.answered(answer.text); keys.forceActiveFocus() } }
                Pill { implicitHeight: 34; icon: "x"; text: I18n.tr("Cancel"); onPressed: { shell.asking = ""; keys.forceActiveFocus() } } }
        ]

        Item { id: keys; anchors.fill: parent; focus: true
            readonly property real room: width - (shell.info ? 300 : 0)      // what the panels have, beside the info pane
            readonly property real bar: prefs.kept.buttons === true && shell.actions.length ? 40 : 0     // the bar of the user's own buttons
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
                else if (shell.propsFor !== "" && ev.key === Qt.Key_Escape) shell.propsFor = ""
                else if ((ev.key === Qt.Key_Return || ev.key === Qt.Key_Enter) && (ev.modifiers & Qt.AltModifier) && picked.length) shell.properties(picked)
                else if ((ev.key === Qt.Key_Return || ev.key === Qt.Key_Enter || ev.key === Qt.Key_P) && ctrl && picked.length) shell.lineInsert(ev.key === Qt.Key_P)
                else if ((ev.key === Qt.Key_Return || ev.key === Qt.Key_Enter) && one) shell.enter(one)
                else if (shell.settingsOpen && ev.key === Qt.Key_Escape) shell.settingsOpen = false
                else if (shell.listerFor !== "" && (ev.key === Qt.Key_Escape || ev.key === Qt.Key_F3 || ev.key === Qt.Key_F10)) shell.listerFor = ""
                else if (shell.listerFor !== "" && ev.key === Qt.Key_F && ctrl) listerFindField.focusIt()
                else if (shell.clash !== null && ev.key === Qt.Key_Escape) shell.clashed("")
                else if (shell.renaming.length && ev.key === Qt.Key_Escape) { shell.renaming = []; keys.forceActiveFocus() }
                else if (ev.key === Qt.Key_F2 && (ev.modifiers & Qt.ShiftModifier) && shell.dual) shell.compare()
                else if (ev.key === Qt.Key_F2 && one) shell.ask("rename", one)
                else if (ev.key === Qt.Key_F2 && picked.length > 1) shell.renameMany(picked)
                else if (ev.key === Qt.Key_Delete || ev.key === Qt.Key_F8) shell.command("trash")
                else if (ev.key === Qt.Key_F5 && shell.dual) shell.command("copy")
                else if (ev.key === Qt.Key_F5) here.again()
                else if (ev.key === Qt.Key_F6 && shell.dual) shell.command("move")
                else if (ev.key === Qt.Key_F7) shell.ask("folder")
                else if (ev.key === Qt.Key_F3) shell.command("view")
                else if (ev.key === Qt.Key_F4) shell.command("edit")
                else if (ev.key === Qt.Key_F10) shell.command("quit")
                else if (ev.key === Qt.Key_F11) shell.info = !shell.info
                else if (ev.key === Qt.Key_F1 && (ev.modifiers & Qt.AltModifier)) shell.lineTo("command")
                else if (ev.key === Qt.Key_F && ctrl) shell.lineTo("find")
                else if (ev.key === Qt.Key_L && ctrl) here.typing = true
                else if (ev.key === Qt.Key_U && ctrl && shell.dual) { const a = left.path; left.go(right.path); right.go(a) }
                else if (ev.key === Qt.Key_Down && (ev.modifiers & Qt.AltModifier)) shell.historyMenu()
                else if (ev.key === Qt.Key_B && ctrl) { if (here.found !== null) here.found = null; else here.flat() }
                else if (ev.key === Qt.Key_Escape && here.found !== null) here.found = null
                else if (ev.key === Qt.Key_A && ctrl) here.all()
                else if (ev.key === Qt.Key_Plus && (ev.modifiers & Qt.KeypadModifier)) shell.ask("select")
                else if (ev.key === Qt.Key_Minus && (ev.modifiers & Qt.KeypadModifier)) shell.ask("unselect")
                else if (ev.key === Qt.Key_Asterisk && (ev.modifiers & Qt.KeypadModifier)) here.invert()
                else if (ev.key === Qt.Key_C && ctrl && picked.length) shell.act(["clip", "copy"].concat(picked))
                else if (ev.key === Qt.Key_X && ctrl && picked.length) shell.act(["clip", "cut"].concat(picked))
                else if (ev.key === Qt.Key_V && ctrl) shell.act(["paste", here.path])
                else if (ev.key === Qt.Key_H && ctrl) shell.hidden = !shell.hidden
                else if (ev.key === Qt.Key_Z && ctrl) shell.act(["undo"])
                else if (ev.key === Qt.Key_Escape) { here.chosen = ({}); menu.close() }
                else if (ev.text.length === 1 && ev.text > " " && !ctrl && !(ev.modifiers & Qt.AltModifier) && here.path.startsWith("/")) here.jump(ev.text)
                else ev.accepted = false
            }
            Panel { id: left; index: 0; y: keys.bar; width: shell.dual ? (keys.room - 52) / 2 : keys.room; height: parent.height - 48 - keys.bar; path: shell.words[0] && (shell.words[0].startsWith("/") || shell.words[0] === "disks:" || shell.words[0] === "computer:") ? shell.words[0] : shell.home }
            Panel { id: right; index: 1; visible: shell.dual; x: (keys.room + 52) / 2; y: keys.bar; width: (keys.room - 52) / 2; height: parent.height - 48 - keys.bar }
            // the user's own buttons, as the commander's button bar: each of their actions, for what is chosen
            Row { visible: keys.bar > 0; x: 8; y: 6; height: 30; spacing: 6
                Repeater { model: shell.actions
                    Pill { required property var modelData; implicitHeight: 30; icon: "bolt"; text: I18n.tr(modelData.name)
                           readonly property var picked: here.picked()
                           opacity: picked.length && picked.every(p => modelData.res.some(r => r.test(p.split("/").pop()))) ? 1 : 0.4
                           onPressed: if (opacity === 1) { actionDoer.running = false; actionDoer.command = ["sh", modelData.path].concat(picked); actionDoer.running = true } } } }
            // the information pane (F11): the one chosen, bigger, and what there is to know of it; nothing chosen, the folder
            Rectangle { id: infoPane; visible: shell.info; x: keys.room + 6; y: 6 + keys.bar; width: 288; height: parent.height - 60 - keys.bar; radius: 18
                        color: Qt.darker(Theme.card, 1.18); border.width: 1; border.color: Theme.line
                readonly property string at: shell.aboutFor
                readonly property string name: at.split("/").pop()
                readonly property string kind: FileIcons.ending(name)
                readonly property bool dir: shell.about.items !== undefined
                readonly property bool picture: FileIcons.pictures.includes(kind) || ["svg", "bmp"].includes(kind)
                property string thumb: ""
                // the kind from `at` itself: the bindings made of it may not have followed it yet when this runs
                onAtChanged: { thumb = ""; if (at !== "" && ["pdf", "mp4", "mkv", "webm", "avi", "mov", "m4v", "wmv", "mpg", "mpeg"].includes(FileIcons.ending(at.split("/").pop()))) { infoThumb.running = false; infoThumb.command = ["latte-files", "thumb", at]; infoThumb.running = true } }
                Process { id: infoThumb; stdout: StdioCollector { onStreamFinished: { const t = this.text.trim(); infoPane.thumb = t ? "file://" + t : "" } } }
                Column { x: 16; y: 16; width: parent.width - 32; spacing: 12
                    Item { width: parent.width; height: 200
                        Image { anchors.fill: parent; fillMode: Image.PreserveAspectFit; asynchronous: true; sourceSize.width: 512; sourceSize.height: 400
                                visible: status === Image.Ready
                                source: infoPane.at === "" ? "" : infoPane.picture ? "file://" + infoPane.at : (infoPane.thumb || here.launcherIcon(infoPane.at) || "") }
                        Glyph { anchors.centerIn: parent; visible: infoPane.at === "" || (!infoPane.picture && infoPane.thumb === "" && here.launcherIcon(infoPane.at) === "")
                                name: infoPane.at === "" ? "folder" : shell.glyphOf(infoPane.name, infoPane.dir); font.pixelSize: 96; color: Theme.gold; opacity: 0.85 } }
                    Label { width: parent.width; wrapMode: Text.WrapAnywhere; font.pixelSize: 15; font.weight: 700; horizontalAlignment: Text.AlignHCenter
                            text: infoPane.at !== "" ? (here.launchers[infoPane.at] ? here.launchers[infoPane.at].name : infoPane.name)
                                                     : (here.picked().length > 1 ? I18n.tr("{n} chosen", { n: here.picked().length }) : here.path.startsWith("/") ? (here.path.split("/").pop() || "/") : win.heading) }
                    Rectangle { width: parent.width; height: 1; color: Theme.line }
                    Repeater { model: infoPane.at !== "" ? shell.aboutText().split("   ·   ").slice(1) : [I18n.tr("{n} items", { n: here.found ? here.found.length : here.count })]
                        Label { required property string modelData; width: parent.width; text: modelData; color: Theme.dim; font.pixelSize: 13; wrapMode: Text.Wrap } } } }
            // between the panels, as a commander has them: to the other panel, there too, the same folder there, again
            Rectangle { visible: shell.dual; x: (keys.room - 48) / 2; y: keys.bar + (parent.height - 48 - keys.bar - height) / 2; width: 48; height: midCol.height + 20; radius: 24; color: Qt.darker(Theme.card, 1.18); border.width: 1; border.color: Theme.line }
            Column { id: midCol; visible: shell.dual; x: (keys.room - 40) / 2; y: keys.bar + (parent.height - 48 - keys.bar - height) / 2; spacing: 8
                Repeater { model: [{ icon: shell.active === 0 ? "arrow-right" : "arrow-left", what: "copy", tip: QT_TR_NOOP("Copy to the other panel (F5)") },
                                   { icon: "arrows-exchange", what: "move", tip: QT_TR_NOOP("Move to the other panel (F6)") },
                                   { icon: "copy", what: "same", tip: QT_TR_NOOP("The same folder in the other panel") },
                                   { icon: "scale", what: "compare", tip: QT_TR_NOOP("Compare (Shift+F2)") },
                                   { icon: "refresh", what: "again", tip: QT_TR_NOOP("Read both panels again") }]
                    Rectangle { required property var modelData; width: 40; height: 40; radius: 20; color: midHit.containsMouse ? Theme.raised : "transparent"
                        Glyph { anchors.centerIn: parent; name: parent.modelData.icon; font.pixelSize: 18; color: Theme.gold }
                        MouseArea { id: midHit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: { const w = parent.modelData.what; if (w === "compare") shell.compare(); else if (w === "same") shell.other.go(here.path); else if (w === "again") { left.again(); right.again() } else shell.command(w) } } } } }
            // the line under the panels, in one panel and in two: what it does is chosen by the three at its start, and
            // each has its colour: $ a command run in a terminal here (Alt+F1); Find: what is here is narrowed as one
            // writes, Enter looks through every folder below too (Ctrl+F); AI: a task for the user's agent, in this folder
            Rectangle { id: lineBox; x: 6; y: parent.height - 44; width: parent.width - 12; height: 38; radius: 19; border.width: 1; border.color: termLine.activeFocus ? Theme.gold : Theme.line
                color: shell.lineMode === "find" ? Qt.tint(Qt.darker(Theme.card, 1.18), Qt.rgba(Theme.gold.r, Theme.gold.g, Theme.gold.b, 0.22))
                     : shell.lineMode === "ai" ? Qt.tint(Theme.raised, Qt.rgba(Theme.cream.r, Theme.cream.g, Theme.cream.b, 0.16)) : Qt.darker(Theme.card, 1.18)
                Behavior on color { ColorAnimation { duration: 160 } }
                Row { id: lineModes; x: 5; spacing: 2; anchors.verticalCenter: parent.verticalCenter
                    Repeater { model: [{ id: "command", icon: "terminal-2" }, { id: "find", icon: "search" }, { id: "ai", icon: "sparkles" }]
                        Rectangle { required property var modelData; width: 30; height: 28; radius: 14
                            readonly property bool on: shell.lineMode === modelData.id
                            color: on ? Theme.gold : (modeHit.containsMouse ? Theme.raised : "transparent")
                            Glyph { anchors.centerIn: parent; name: parent.modelData.icon; font.pixelSize: 15; color: parent.on ? Theme.inkOnGold : Theme.dim }
                            MouseArea { id: modeHit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: shell.lineTo(parent.modelData.id) } } } }
                TextInput { id: termLine; x: lineModes.x + lineModes.width + 12; width: parent.width - x - lineKey.width - 20 - (findOptsPill.visible ? 36 : 0); anchors.verticalCenter: parent.verticalCenter; color: Theme.cream; font.family: Theme.mono; font.pixelSize: 13; clip: true; selectByMouse: true
                            onTextChanged: if (shell.lineMode === "find") shell.findText = text
                            Keys.onUpPressed: if (shell.lineMode === "command") shell.historyStep(-1)
                            Keys.onDownPressed: if (shell.lineMode === "command") shell.historyStep(1)
                            Keys.onPressed: (ev) => { if ((ev.modifiers & Qt.ControlModifier) && (ev.key === Qt.Key_Return || ev.key === Qt.Key_Enter || ev.key === Qt.Key_P)) {
                                                          shell.lineInsert(ev.key === Qt.Key_P); ev.accepted = true } }
                            Keys.onEscapePressed: { if (shell.lineMode === "find") { text = ""; here.found = null } keys.forceActiveFocus() }
                            onAccepted: shell.lineDone(text) }
                Label { x: termLine.x; anchors.verticalCenter: parent.verticalCenter; visible: termLine.text === "" && !termLine.activeFocus; color: Theme.faint; font.family: Theme.mono; font.pixelSize: 13
                        width: termLine.width; elide: Text.ElideRight
                        text: { const n = here.path.startsWith("/") ? here.path.replace(shell.home, "~") : "~"
                                return shell.lineMode === "find" ? I18n.tr("Find in {n}: names here as you write, Enter also below and inside files", { n: n })
                                     : shell.lineMode === "ai" ? I18n.tr("A task for your agent in {n}, e.g. rename the photos here by the date taken", { n: n })
                                     : I18n.tr("A command, run in {n}…", { n: n }) } }
                Rectangle { id: findOptsPill; visible: shell.lineMode === "find"; anchors.right: lineKey.left; anchors.rightMargin: 6; anchors.verticalCenter: parent.verticalCenter; width: 30; height: 28; radius: 14
                    readonly property bool on: shell.findOpts.bigger > 0 || shell.findOpts.days > 0 || shell.findOpts.regex
                    color: on ? Theme.gold : (optsHit.containsMouse ? Theme.raised : "transparent")
                    Glyph { anchors.centerIn: parent; name: "adjustments-horizontal"; font.pixelSize: 15; color: parent.on ? Theme.inkOnGold : Theme.dim }
                    MouseArea { id: optsHit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: { const q = findOptsPill.mapToItem(overlay, 0, 0); shell.findMenu(q.x - 200, q.y - 330) } } }
                Rectangle { id: lineKey; anchors.right: parent.right; anchors.rightMargin: 7; anchors.verticalCenter: parent.verticalCenter; height: 26; radius: 13; width: altText.implicitWidth + 18; color: Theme.gold
                    Label { id: altText; anchors.centerIn: parent; text: shell.lineMode === "find" ? "Ctrl+F" : (shell.lineMode === "ai" ? "Enter" : "Alt+F1"); color: Theme.inkOnGold; font.family: Theme.mono; font.pixelSize: 11; font.weight: 800 } } }
            // DualBrew's settings as a page: every switch the menu has, in parts, each a press to change
            Rectangle { anchors.fill: parent; anchors.bottomMargin: 48; visible: shell.settingsOpen; z: 890; radius: 18; color: Qt.darker(Theme.card, 1.18); border.width: 1; border.color: Theme.line
                MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; onPressed: keys.forceActiveFocus() }
                Row { x: 20; y: 14; spacing: 12
                    Glyph { name: "settings"; font.pixelSize: 20; color: Theme.gold; anchors.verticalCenter: parent.verticalCenter }
                    Label { text: I18n.tr("DualBrew settings"); font.pixelSize: 17; font.weight: 700; anchors.verticalCenter: parent.verticalCenter } }
                Pill { anchors.right: parent.right; anchors.rightMargin: 14; y: 10; implicitHeight: 32; icon: "x"; onPressed: { shell.settingsOpen = false; keys.forceActiveFocus() } }
                Flickable { x: 20; y: 56; width: parent.width - 40; height: parent.height - 70; contentHeight: partsFlow.height; clip: true; boundsBehavior: Flickable.StopAtBounds
                    Flow { id: partsFlow; width: parent.width; spacing: 18
                        Repeater { model: shell.settingsOpen ? shell.settingsParts : []
                            Column { required property var modelData; width: Math.max(280, (partsFlow.width - 36) / 3); spacing: 4
                                Label { text: modelData.title.toUpperCase(); color: Theme.faint; font.pixelSize: 11; font.weight: 700; font.letterSpacing: 0.8; bottomPadding: 4 }
                                Repeater { model: parent.modelData.rows
                                    Rectangle { required property var modelData; width: parent.width; height: 34; radius: 9; color: setHit.containsMouse ? Theme.card : "transparent"
                                        Rectangle { x: 8; width: 18; height: 18; radius: 5; anchors.verticalCenter: parent.verticalCenter; color: parent.modelData.checked ? Theme.gold : "transparent"; border.width: 1; border.color: parent.modelData.checked ? Theme.gold : Theme.line
                                            Glyph { anchors.centerIn: parent; visible: parent.parent.modelData.checked === true; name: "check"; font.pixelSize: 13; color: Theme.inkOnGold } }
                                        Label { x: 36; width: parent.width - 36 - hintText.implicitWidth - 12; text: parent.modelData.text; elide: Text.ElideRight; anchors.verticalCenter: parent.verticalCenter; font.pixelSize: 13 }
                                        Label { id: hintText; anchors.right: parent.right; anchors.rightMargin: 8; text: parent.modelData.hint || ""; color: Theme.faint; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
                                        MouseArea { id: setHit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if (parent.modelData.run) parent.modelData.run() } } } } } } } }
            // the Lister: the whole of the panels, the file read here; Esc, F3 or the cross puts it away
            Rectangle { anchors.fill: parent; anchors.bottomMargin: 48; visible: shell.listerFor !== ""; z: 880; radius: 18; color: Qt.darker(Theme.card, 1.18); border.width: 1; border.color: Theme.line
                readonly property string kind: FileIcons.ending(shell.listerFor.split("/").pop())
                readonly property bool picture: FileIcons.pictures.includes(kind) || ["svg", "bmp"].includes(kind)
                MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; onPressed: keys.forceActiveFocus() }
                Row { x: 16; y: 12; spacing: 10; width: parent.width - 32
                    Glyph { name: shell.glyphOf(shell.listerFor.split("/").pop(), false); font.pixelSize: 18; color: Theme.gold; anchors.verticalCenter: parent.verticalCenter }
                    Label { text: shell.listerFor.split("/").pop(); font.weight: 700; width: Math.min(implicitWidth, 380); elide: Text.ElideMiddle; anchors.verticalCenter: parent.verticalCenter }
                    Pill { visible: !parent.parent.picture; implicitHeight: 30; text: I18n.tr("Text"); strong: !shell.listerHex; onPressed: { shell.listerHex = false; shell.listerRead() } }
                    Pill { visible: !parent.parent.picture; implicitHeight: 30; text: "Hex"; strong: shell.listerHex; onPressed: { shell.listerHex = true; shell.listerRead() } }
                    Field { id: listerFindField; visible: !parent.parent.picture; width: 240; height: 30; hint: I18n.tr("Find in the text"); function focusIt() { children[1].forceActiveFocus(); children[1].selectAll() }
                            onAccepted: shell.listerFind(text, listerText.selectionEnd) }
                    Pill { implicitHeight: 30; icon: "external-link"; text: I18n.tr("Open"); onPressed: shell.open(shell.listerFor, false) }
                    Pill { implicitHeight: 30; icon: "x"; onPressed: { shell.listerFor = ""; keys.forceActiveFocus() } } }
                Image { visible: parent.picture; anchors.fill: parent; anchors.margins: 16; anchors.topMargin: 56; fillMode: Image.PreserveAspectFit; asynchronous: true
                        source: parent.picture && shell.listerFor !== "" ? "file://" + shell.listerFor : "" }
                Flickable { id: listerFlick; visible: !parent.picture; x: 16; y: 56; width: parent.width - 32; height: parent.height - 72; contentHeight: listerText.implicitHeight; contentWidth: width; clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    TextEdit { id: listerText; width: parent.width; readOnly: true; selectByMouse: true; wrapMode: shell.listerHex ? TextEdit.NoWrap : TextEdit.WrapAnywhere
                               color: Theme.cream; selectionColor: Theme.coffee; font.family: Theme.mono; font.pixelSize: 12 } } }
            // names already there: keep both, replace (the old ones to the Trash), replace only older ones, skip them
            Item { anchors.fill: parent; visible: shell.clash !== null; z: 950
                Rectangle { anchors.fill: parent; color: Qt.rgba(0, 0, 0, 0.35)
                    MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; onPressed: shell.clashed("") } }
                Rectangle { width: Math.min(560, parent.width - 40); height: clashCol.implicitHeight + 40; anchors.centerIn: parent; radius: 18
                            color: Theme.card; border.width: 1; border.color: Theme.line
                    MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }
                    Column { id: clashCol; x: 22; y: 20; width: parent.width - 44; spacing: 12
                        Label { width: parent.width; wrapMode: Text.Wrap; font.pixelSize: 16; font.weight: 700
                                text: shell.clash ? I18n.tr("{n} of these are already in {folder}", { n: shell.clash.names.length, folder: shell.clash.to.split("/").pop() || "/" }) : "" }
                        Repeater { model: shell.clash ? shell.clash.names.slice(0, 6) : []
                            Label { required property string modelData; width: clashCol.width; text: modelData; elide: Text.ElideMiddle; color: Theme.dim; font.family: Theme.mono; font.pixelSize: 12 } }
                        Label { visible: !!shell.clash && shell.clash.names.length > 6; text: shell.clash ? I18n.tr("and {n} more", { n: shell.clash.names.length - 6 }) : ""; color: Theme.faint; font.pixelSize: 12 }
                        Flow { width: parent.width; spacing: 8
                            Pill { icon: "copy"; strong: true; text: I18n.tr("Keep both"); onPressed: shell.clashed("both") }
                            Pill { icon: "arrows-exchange"; text: I18n.tr("Replace"); onPressed: shell.clashed("replace") }
                            Pill { icon: "clock"; text: I18n.tr("Replace older ones"); onPressed: shell.clashed("older") }
                            Pill { icon: "player-skip-forward"; text: I18n.tr("Skip these"); onPressed: shell.clashed("skip") }
                            Pill { icon: "x"; text: I18n.tr("Cancel"); onPressed: shell.clashed("") } }
                        Label { width: parent.width; wrapMode: Text.Wrap; color: Theme.faint; font.pixelSize: 12
                                text: I18n.tr("What is replaced goes to the Recycle Bin; Ctrl+Z brings it back.") } } } }
            // many renamed at once: the pattern and its pieces, find and replace, and every new name before it is done
            Item { anchors.fill: parent; visible: shell.renaming.length > 0; z: 900
                Rectangle { anchors.fill: parent; color: Qt.rgba(0, 0, 0, 0.35)
                    MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; onPressed: { shell.renaming = []; keys.forceActiveFocus() } } }
                Rectangle { width: Math.min(720, parent.width - 40); height: renCol.implicitHeight + 40; anchors.centerIn: parent; radius: 18
                            color: Theme.card; border.width: 1; border.color: Theme.line
                    MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }
                    Column { id: renCol; x: 22; y: 20; width: parent.width - 44; spacing: 12
                        Label { text: I18n.tr("Rename {n} items", { n: shell.renaming.length }); font.pixelSize: 16; font.weight: 700 }
                        Flow { width: parent.width; spacing: 10
                            Field { id: renPattern; width: 300; icon: "pencil"; text: "[N]"; function focusIt() { children[1].forceActiveFocus(); children[1].selectAll() }
                                    onAccepted: shell.renameDo() }
                            Repeater { model: [{ t: "[N]", n: QT_TR_NOOP("Name") }, { t: "[C]", n: QT_TR_NOOP("Number") }, { t: "[D]", n: QT_TR_NOOP("Date") }, { t: "[T]", n: QT_TR_NOOP("Time") }, { t: "[E]", n: QT_TR_NOOP("Ending") }]
                                Pill { required property var modelData; implicitHeight: 40; text: I18n.tr(modelData.n)
                                       onPressed: { const f = renPattern.children[1]; f.insert(f.cursorPosition, modelData.t); f.forceActiveFocus() } } } }
                        Row { spacing: 10
                            Field { id: renFind; width: 220; icon: "search"; hint: I18n.tr("Find"); onAccepted: shell.renameDo() }
                            Field { id: renWith; width: 220; icon: "arrows-exchange"; hint: I18n.tr("Replace with"); onAccepted: shell.renameDo() }
                            Label { text: I18n.tr("Numbers from"); color: Theme.dim; anchors.verticalCenter: parent.verticalCenter }
                            Rectangle { id: renStart; property int value: 1; width: 90; height: 40; radius: 12; color: Theme.card; border.width: 1; border.color: Theme.line
                                Glyph { x: 8; name: "minus"; font.pixelSize: 15; anchors.verticalCenter: parent.verticalCenter
                                    MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; onClicked: renStart.value = Math.max(0, renStart.value - 1) } }
                                Label { anchors.centerIn: parent; text: renStart.value; font.family: Theme.mono }
                                Glyph { anchors.right: parent.right; anchors.rightMargin: 8; name: "plus"; font.pixelSize: 15; anchors.verticalCenter: parent.verticalCenter
                                    MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; onClicked: renStart.value++ } } } }
                        Rectangle { width: parent.width; height: 1; color: Theme.line }
                        Flickable { width: parent.width; height: Math.min(planCol.height, 300); contentHeight: planCol.height; clip: true; boundsBehavior: Flickable.StopAtBounds
                            Column { id: planCol; width: parent.width; spacing: 2
                                Repeater { model: shell.renPlan
                                    Row { required property var modelData; spacing: 10; width: planCol.width
                                        Label { width: (planCol.width - 40) / 2; text: modelData.from; elide: Text.ElideMiddle; color: Theme.dim; font.family: Theme.mono; font.pixelSize: 12 }
                                        Glyph { width: 20; name: "arrow-right"; font.pixelSize: 13; color: Theme.faint }
                                        Label { width: (planCol.width - 40) / 2; text: modelData.to || "—"; elide: Text.ElideMiddle; font.family: Theme.mono; font.pixelSize: 12
                                                color: modelData.bad ? Theme.red : (modelData.to === modelData.from ? Theme.dim : Theme.gold) } } } } }
                        Row { spacing: 10
                            Pill { icon: "check"; strong: true; text: I18n.tr("Rename"); opacity: shell.renPlan.some(r => r.bad) ? 0.5 : 1; onPressed: shell.renameDo() }
                            Pill { icon: "x"; text: I18n.tr("Cancel"); onPressed: { shell.renaming = []; keys.forceActiveFocus() } }
                            Label { visible: shell.renPlan.some(r => r.bad); text: I18n.tr("Red names are empty, twice or already here"); color: Theme.red; anchors.verticalCenter: parent.verticalCenter } } } } }
            // Properties, over the panels; a press beside it or Esc puts it away
            Item { anchors.fill: parent; visible: shell.propsFor !== ""; z: 900
                Rectangle { anchors.fill: parent; color: Qt.rgba(0, 0, 0, 0.35)
                    MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; onPressed: shell.propsFor = "" } }
                Rectangle { id: sheet; width: Math.min(560, parent.width - 40); height: sheetCol.implicitHeight + 40; anchors.centerIn: parent; radius: 18
                            color: Theme.card; border.width: 1; border.color: Theme.line
                    MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }
                    readonly property var p: shell.props
                    readonly property bool dir: p.items !== undefined
                    readonly property bool many: shell.propsAll.length > 1
                    readonly property string name: many ? I18n.tr("{n} items", { n: shell.propsAll.length }) : shell.propsFor.split("/").pop()
                    function when(t) { return t && +t > 0 ? Qt.formatDateTime(new Date(parseInt(t) * 1000), "d. M. yyyy  hh:mm") : "—" }
                    Column { id: sheetCol; x: 22; y: 20; width: parent.width - 44; spacing: 14
                        Row { spacing: 14; width: parent.width
                            Glyph { width: 48; height: 48; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; name: sheet.many ? "stack-2" : shell.glyphOf(sheet.name, sheet.dir); font.pixelSize: 40; color: Theme.gold }
                            Column { width: parent.width - 62 - 40; spacing: 3; anchors.verticalCenter: parent.verticalCenter
                                Label { width: parent.width; text: sheet.name; font.pixelSize: 16; font.weight: 700; elide: Text.ElideMiddle }
                                Label { width: parent.width; text: sheet.many ? "" : sheet.dir ? I18n.tr("Folder") : (sheet.p.mime || ""); color: Theme.dim; font.pixelSize: 12 } }
                            Glyph { name: "x"; font.pixelSize: 18; color: Theme.dim; anchors.verticalCenter: parent.verticalCenter
                                MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; onClicked: shell.propsFor = "" } } }
                        Rectangle { width: parent.width; height: 1; color: Theme.line }
                        Grid { columns: 2; columnSpacing: 18; rowSpacing: 7
                            Repeater { model: [
                                    [QT_TR_NOOP("Where"), shell.propsFor.slice(0, shell.propsFor.lastIndexOf("/")).replace(shell.home, "~") || "/"],
                                    [QT_TR_NOOP("Size"), sheet.many ? (shell.propsTotal < 0 ? "…" : shell.bytes(shell.propsTotal) + "  (" + shell.propsTotal.toLocaleString(Qt.locale(), "f", 0) + " B)") : sheet.p.size !== undefined || sheet.p.bytes !== undefined ? shell.bytes(parseFloat(sheet.p.bytes !== undefined ? sheet.p.bytes : sheet.p.size)) + "  (" + Number(sheet.p.bytes !== undefined ? sheet.p.bytes : sheet.p.size).toLocaleString(Qt.locale(), "f", 0) + " B)" : "…"],
                                    [QT_TR_NOOP("Items"), sheet.dir && !sheet.many ? String(sheet.p.items) : ""],
                                    [QT_TR_NOOP("Modified"), sheet.many ? "" : sheet.when(sheet.p.when)],
                                    [QT_TR_NOOP("Opened"), sheet.many ? "" : sheet.when(sheet.p.read)],
                                    [QT_TR_NOOP("Created"), sheet.many ? "" : sheet.when(sheet.p.born)],
                                    [QT_TR_NOOP("Owner"), (sheet.p.owner || "") + (sheet.p.group && sheet.p.group !== sheet.p.owner ? " · " + sheet.p.group : "")]].filter(r => r[1] !== "")
                                                    .reduce((out, r) => out.concat([{ text: I18n.tr(r[0]), head: true }, { text: r[1], head: false }]), [])
                                Label { required property var modelData; text: modelData.text; color: modelData.head ? Theme.dim : Theme.cream
                                        font.pixelSize: 13; width: modelData.head ? 110 : sheetCol.width - 128; elide: Text.ElideMiddle } } }
                        Rectangle { width: parent.width; height: 1; color: Theme.line }
                        // what may be done with it, by whom: nine switches, as chmod has them; only the owner may change them
                        Label { text: I18n.tr("Permissions") + (sheet.p.mine === "1" ? "" : "  ·  " + I18n.tr("only its owner may change them")) + (sheet.many ? "  ·  " + I18n.tr("as the first has them; a switch changes it on all") : ""); color: Theme.dim; font.pixelSize: 12; font.weight: 700 }
                        Grid { columns: 4; columnSpacing: 14; rowSpacing: 6
                            Repeater { model: 16
                                Item { required property int index; readonly property int r: Math.floor(index / 4); readonly property int c: index % 4
                                    width: c === 0 ? 110 : 96; height: 26
                                    Label { visible: parent.r === 0 && parent.c > 0; anchors.verticalCenter: parent.verticalCenter; color: Theme.faint; font.pixelSize: 12
                                            text: [I18n.tr("Read"), I18n.tr("Write"), sheet.dir ? I18n.tr("Enter") : I18n.tr("Run")][parent.c - 1] || "" }
                                    Label { visible: parent.r > 0 && parent.c === 0; anchors.verticalCenter: parent.verticalCenter; font.pixelSize: 13
                                            text: [I18n.tr("Owner"), I18n.tr("Group"), I18n.tr("Others")][parent.r - 1] || "" }
                                    Rectangle { id: sw; visible: parent.r > 0 && parent.c > 0; width: 22; height: 22; radius: 6; anchors.verticalCenter: parent.verticalCenter
                                        readonly property int bit: [4, 2, 1][parent.c - 1] || 0
                                        readonly property bool on: visible && shell.modeHas(parent.r - 1, bit)
                                        color: on ? Theme.gold : "transparent"; border.width: 1; border.color: on ? Theme.gold : Theme.line; opacity: sheet.p.mine === "1" ? 1 : 0.5
                                        Glyph { anchors.centerIn: parent; visible: sw.on; name: "check"; font.pixelSize: 14; color: Theme.inkOnGold }
                                        MouseArea { anchors.fill: parent; enabled: sheet.p.mine === "1"; cursorShape: Qt.PointingHandCursor; onClicked: shell.modeFlip(parent.parent.r - 1, sw.bit) } } } } }
                        // when it was changed, set by hand for all the chosen (as the commander's Change attributes): now, or a moment
                        Row { visible: sheet.p.mine === "1"; spacing: 10
                            Label { width: 110; text: I18n.tr("Change the date"); color: Theme.dim; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
                            Field { id: touchAt; width: 190; height: 32; icon: "calendar"; hint: "2026-10-23 14:30"; onAccepted: if (text.trim() !== "") shell.propsDo(["touch", text.trim()].concat(shell.propsAll)) }
                            Pill { implicitHeight: 32; text: I18n.tr("Set"); onPressed: if (touchAt.text.trim() !== "") shell.propsDo(["touch", touchAt.text.trim()].concat(shell.propsAll)) }
                            Pill { implicitHeight: 32; icon: "clock"; text: I18n.tr("Now"); onPressed: shell.propsDo(["touch", "now"].concat(shell.propsAll)) } }
                        // the app that opens this kind of file, always
                        Row { visible: !sheet.dir && !sheet.many && shell.propsApps.length > 0; spacing: 12
                            Label { width: 110; text: I18n.tr("Opens with"); color: Theme.dim; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
                            Pill { id: openerPill; implicitHeight: 32; icon: "apps"
                                   text: (shell.propsApps.find(a => a.id === sheet.p.opener) || { name: I18n.tr("Choose…") }).name
                                   onPressed: { const q = openerPill.mapToItem(overlay, 0, openerPill.height + 4)
                                                menu.open(q.x, q.y, shell.propsApps.map(a => ({ text: a.name, checked: a.id === sheet.p.opener, run: () => shell.propsDo(["default", a.id, sheet.p.mime]) }))) } } }
                        // its SHA-256, counted when asked: a big file takes a while
                        Row { visible: !sheet.dir && !sheet.many; spacing: 12; width: parent.width
                            Label { width: 110; text: "SHA-256"; color: Theme.dim; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
                            Pill { visible: shell.propsSum === "" && !summer.running; implicitHeight: 32; icon: "calculator"; text: I18n.tr("Count")
                                   onPressed: { summer.command = ["latte-files", "sum", shell.propsFor]; summer.running = true } }
                            Label { visible: summer.running; text: I18n.tr("Counting…"); color: Theme.dim; anchors.verticalCenter: parent.verticalCenter }
                            TextInput { visible: shell.propsSum !== ""; width: parent.width - 130; text: shell.propsSum; readOnly: true; selectByMouse: true; wrapMode: TextInput.WrapAnywhere
                                        color: Theme.cream; font.family: Theme.mono; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter } } } } }
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
    // ── the Lister (F3), as the commander's: a file read in the window itself — as text (2 MB of it), as bytes (hex),
    // a picture as it is; Ctrl+F or the field finds in the text, Enter the next one ──────────────────────────
    property string listerFor: ""
    property bool listerHex: false
    function lister(path) { listerFor = path; listerHex = false; listerRead() }
    function listerRead() { listerText.text = ""; listerReader.running = false
                            listerReader.command = listerHex ? ["sh", "-c", 'head -c 262144 -- "$1" | xxd -g1', "sh", listerFor] : ["head", "-c", "2097152", "--", listerFor]
                            listerReader.running = true }
    Process { id: listerReader; stdout: StdioCollector { onStreamFinished: listerText.text = this.text } }
    function listerFind(q, from) { const t = listerText.text.toLowerCase(), i = t.indexOf(q.toLowerCase(), from); const at = i >= 0 ? i : t.indexOf(q.toLowerCase())
                                   if (q === "" || at < 0) return; listerText.select(at, at + q.length); listerFlick.contentY = Math.max(0, Math.min(listerText.positionToRectangle(at).y - 80, listerFlick.contentHeight - listerFlick.height)) }
    // where this panel was before, as a list to go back to (Alt+↓; also the right button on the back arrow's place)
    function historyMenu() {
        const seen = [], rows = []
        for (const p of here.before.slice().reverse()) if (!seen.includes(p) && p !== here.path) { seen.push(p); rows.push({ icon: p.startsWith("/") ? "folder" : "device-desktop", text: p.startsWith("/") ? (p.replace(home, "~") || "/") : I18n.tr("This computer"), run: () => here.go(p) }) }
        if (rows.length) { const q = here.mapToItem(overlay, 20, 50); menu.open(q.x, q.y, rows.slice(0, 20)) }
    }
    // a short word in the coffee at the foot, for a few seconds
    property string said: ""
    function say(t) { said = t; unsay.restart() }
    Timer { id: unsay; interval: 6000; onTriggered: shell.said = "" }
    // the commander's Compare (Shift+F2): one file chosen in each panel, the two side by side line by line; otherwise
    // the folders, and in each panel what the other lacks or has older is chosen, for F5
    Process { id: comparer
        stdout: StdioCollector { onStreamFinished: { const l = {}, r = {}; let same = 0
            for (const line of this.text.split("\n")) { const i = line.indexOf("\t"); if (i < 0) continue
                const k = line.slice(0, i), v = line.slice(i + 1)
                if (k === "left") l[v] = true; else if (k === "right") r[v] = true; else if (k === "same") same = parseInt(v) }
            left.chosen = l; right.chosen = r
            shell.say(I18n.tr("Left {l} and right {r} newer or missing on the other side, {s} the same; F5 copies what is chosen",
                              { l: Object.keys(l).length, r: Object.keys(r).length, s: same })) } } }
    function compare() {
        if (!dual || !left.path.startsWith("/") || !right.path.startsWith("/")) return
        const a = left.picked(), b = right.picked()
        if (a.length === 1 && b.length === 1) return Quickshell.execDetached(["foot", "--", "sh", "-c", 'diff -u --color=always -- "$1" "$2" | less -R', "sh", a[0], b[0]])
        comparer.running = false; comparer.command = ["latte-files", "compare", left.path, right.path]; comparer.running = true
    }
    function command(what) {
        const picked = here.picked()
        if (what === "folder") return ask("folder")
        if (what === "quit") return Qt.quit()
        // F3 shows a file as its app does; F4 opens it in the text editor the user has, in a terminal
        if (what === "view") { if (picked.length === 1) lister(picked[0]); return }
        if (what === "edit") { if (picked.length === 1) Quickshell.execDetached(["foot", "--", "sh", "-c", 'exec ${EDITOR:-nano} "$1"', "sh", picked[0]]); return }
        if (!picked.length) return
        if (what === "trash") act(["trash"].concat(picked))
        else if (dual && other.path !== here.path) enqueue(what, other.path, picked)
        here.chosen = ({})
    }
}
