// DualBrew: the files. One panel as on Windows, or two side by side as in a commander; bin/latte-files moves
// things, this window shows them.   latte-app files [FOLDER]
//
// The side: the user's folders, the Trash, the disks. The header: up, a new folder, the view (details or icons),
// hidden files, one panel or two. The coffee at the foot says what is here and what is chosen, and with two
// panels it carries the commander's keys: F5 copy and F6 move to the other panel, F7 new folder, F8 delete.
// The mouse first: a press chooses, Ctrl adds, Shift takes all between, twice opens, the right button is the menu
// everywhere; the middle one opens a folder in the other panel; the mouse's back and forward buttons go back and
// forward; twice on the bare ground goes up; files are dragged to the other panel, onto a folder, or out to any
// app, and dropped in from anywhere (moved on the same disk, copied to another; Ctrl copies). The column heads
// sort. Copying and moving are jobs on the coffee: how far, pause, stop; several wait their turn.
// The panel one works in stands above the coffee; the other lies under it.
// The keys: Enter opens, Backspace goes up, F2 renames, Delete trashes, Ctrl+C/X/V, Ctrl+A, Ctrl+H hidden
// files, Tab the other panel. Space with one file chosen shows it in the other panel. Space with nothing chosen measures the folder: how much each thing in it holds,
// as a figure and as a bar, and in the other panel the same sorted from the largest; Esc or its Back puts it away.
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
    property string view: "details"            // or "icons"
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
    function hideSizes() { const to = left.source ? left : right; if (to.source) { to.source.measured = false; to.source.sizes = ({}) } to.source = null; dual = wasDual; active = to === left ? 1 : 0; if (!dual) active = 0 }
    // the roots of the user's world: home and every disk; a path is shown from the root it is under
    function rootOf(p) {
        let best = null
        for (const pl of places) if ((pl.kind === "home" || (pl.kind === "disk" && pl.path !== "/")) && (p === pl.path || p.startsWith(pl.path + "/")) && (!best || pl.path.length > best.path.length)) best = pl
        return best
    }
    property var places: []
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
    // ── a look at one file in the other panel (Space), as the sizes are ──────────────────────────────────────
    readonly property bool peeking: left.peek !== "" || right.peek !== ""
    function showPeek(path) { if (peeking) return hidePeek(); wasDual = dual; dual = true; other.peek = path }
    function hidePeek() { const to = left.peek !== "" ? left : right; to.peek = ""; dual = wasDual; active = to === left ? 1 : 0; if (!dual) active = 0 }
    readonly property var here: active === 0 ? left : right
    readonly property var other: active === 0 ? right : left
    // what is asked of the user in the foot: a name for something new, or another name
    property string asking: ""                 // "" | "folder" | "file" | "rename"
    property string askingFor: ""

    readonly property var placeNames: ({ "home": QT_TR_NOOP("Home"), "desktop": QT_TR_NOOP("Desktop"), "documents": QT_TR_NOOP("Documents"), "download": QT_TR_NOOP("Downloads"),
                                         "pictures": QT_TR_NOOP("Pictures"), "music": QT_TR_NOOP("Music"), "videos": QT_TR_NOOP("Videos"), "trash": QT_TR_NOOP("Recycle Bin"), "disk": QT_TR_NOOP("This computer") })
    readonly property var placeIcons: ({ "home": "home", "desktop": "device-desktop", "documents": "file-text", "download": "download", "pictures": "photo", "music": "music",
                                         "videos": "player-play", "trash": "trash", "disk": "disc" })
    Process { running: true; command: ["latte-files", "places"]
              stdout: StdioCollector { onStreamFinished: shell.places = this.text.split("\n").filter(l => l !== "").map(l => { const p = l.split("\t"); return { kind: p[0], path: p[1], name: p[2] || "" } }) } }

    Process { id: doer; onExited: { left.again(); right.again() } }
    function act(args) { doer.running = false; doer.command = ["latte-files"].concat(args); doer.running = true }
    function bytes(b) { const u = ["B", "KB", "MB", "GB", "TB"]; let v = b || 0, i = 0; while (v >= 1024 && i < 4) { v /= 1024; i++ } return v.toFixed(i ? 1 : 0) + " " + u[i] }
    function open(path, isDir) { if (isDir) here.go(path); else Quickshell.execDetached(path.endsWith(".desktop") ? ["gio", "launch", path] : ["gio", "open", path]) }
    function ask(what, path) { asking = what; askingFor = path || ""; answer.text = what === "rename" ? path.split("/").pop() : (what === "folder" ? I18n.tr("New folder") : I18n.tr("New Text Document") + ".txt")
                               Qt.callLater(() => { answer.focusIt(); }) }
    function answered(text) {
        const t = text.trim(), what = asking, target = askingFor
        asking = ""
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
            { line: true },
            { icon: "cut", text: I18n.tr("Cut"), hint: "Ctrl+X", run: () => shell.act(["clip", "cut"].concat(picked)) },
            { icon: "copy", text: I18n.tr("Copy"), hint: "Ctrl+C", run: () => shell.act(["clip", "copy"].concat(picked)) },
            { icon: "clipboard", text: I18n.tr("Copy as path"), run: () => Quickshell.execDetached(["wl-copy", "--", picked.join("\n")]) },
            { line: true }]
        if (!many) rows.push({ icon: "pencil", text: I18n.tr("Rename"), hint: "F2", run: () => shell.ask("rename", path) })
        if (!inTrash) rows.push({ icon: "trash", text: I18n.tr("Delete"), hint: "Del", danger: true, run: () => shell.act(["trash"].concat(picked)) })
        menu.open(x, y, rows)
    }
    function groundMenu(x, y) {
        if (!here.path.startsWith("/")) return menu.open(x, y, [{ text: I18n.tr("The real structure"), checked: real, run: () => real = !real }])
        const inTrash = here.path.indexOf("/.local/share/Trash/files") >= 0
        menu.open(x, y, inTrash ? [{ icon: "trash", text: I18n.tr("Empty Recycle Bin"), danger: true, run: () => shell.act(["empty"]) }] : [
            { icon: "layout-grid", text: I18n.tr("View"), more: [{ text: I18n.tr("Details"), checked: shell.view === "details", run: () => shell.view = "details" },
                                                                  { text: I18n.tr("Icons"), checked: shell.view === "icons", run: () => shell.view = "icons" },
                                                                  { line: true }, { text: I18n.tr("Hidden files"), checked: shell.hidden, hint: "Ctrl+H", run: () => shell.hidden = !shell.hidden },
                                                                  { text: I18n.tr("The real structure"), checked: shell.real, run: () => shell.real = !shell.real }] },
            { icon: "refresh", text: I18n.tr("Refresh"), hint: "F5", run: () => here.again() },
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
        property real iconSize: 52             // Ctrl and the wheel make the icons bigger or smaller
        readonly property bool isActive: shell.active === index
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
            const root = shell.real ? null : shell.rootOf(path)
            if (root && root.path === path) return go("computer:")
            if (path !== "/") go(path.replace(/\/[^/]+\/?$/, "") || "/")
        }
        // the way to here, as pieces one can press: from / in the real structure, else from This computer
        readonly property var way: {
            if (path === "computer:") return [{ name: I18n.tr("This computer"), path: "computer:" }]
            const root = shell.real ? null : shell.rootOf(path)
            const base = root ? root.path : "", parts = path.slice(base.length).split("/").filter(x => x !== ""), out = []
            if (root) out.push({ name: I18n.tr("This computer"), path: "computer:" }, { name: root.kind === "home" ? I18n.tr("Home") : (root.name.split(" · ")[0] || root.path), path: root.path })
            else out.push({ name: "/", path: "/" })
            let at = base
            for (const x of parts) { at += "/" + x; out.push({ name: x, path: at }) }
            return out
        }
        function again() { const f = files.folder; files.folder = ""; files.folder = f }
        function picked() { return Object.keys(chosen) }
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
        // How much each thing here holds, folders too: measured when asked (Space), a line at a time as du gets
        // through them, so a big folder fills in while one watches.
        property var sizes: ({})
        property bool measured: false
        readonly property real largest: { let m = 1; for (const k in sizes) if (sizes[k] > m) m = sizes[k]; return m }
        readonly property real total: { let t = 0; for (const k in sizes) t += sizes[k]; return t }
        readonly property bool measuring: meter.running
        function measure() { if (measured) { measured = false; meter.running = false; sizes = ({}); return }
                             sizes = ({}); measured = true; meter.running = false; meter.command = ["latte-files", "sizes", path]; meter.running = true }
        onPathChanged: { measured = false; meter.running = false; sizes = ({}) }
        Process { id: meter; stdout: SplitParser { onRead: line => { const at = line.indexOf("\t"); if (at < 1) return
                                                                    const s = Object.assign({}, panel.sizes); s[line.slice(at + 1)] = parseInt(line.slice(0, at)); panel.sizes = s } } }
        FolderListModel { id: files; folder: panel.path.startsWith("/") ? "file://" + panel.path : ""; showDirsFirst: true; showDotAndDotDot: false; showHidden: shell.hidden
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
                    Label { text: panel.source ? I18n.tr("What fills {folder}", { folder: panel.source.path.split("/").pop() || "/" }) : ""; font.weight: 700; anchors.verticalCenter: parent.verticalCenter } } } }
        Item { x: 12; y: 50; width: parent.width - 24; height: parent.height - 62; clip: true
            MouseArea { anchors.fill: parent; acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.BackButton | Qt.ForwardButton
                        onPressed: (m) => { shell.active = panel.index; keys.forceActiveFocus(); if (panel.extra(m)) return; if (m.button === Qt.LeftButton) panel.chosen = ({}) }
                        onClicked: (m) => { if (m.button === Qt.RightButton) { const q = mapToItem(overlay, m.x, m.y); shell.groundMenu(q.x, q.y) } }
                        onDoubleClicked: (m) => { if (m.button === Qt.LeftButton && !panel.source && panel.peek === "") panel.up() }
                        onWheel: (w) => { if (w.modifiers & Qt.ControlModifier) { panel.iconSize = Math.max(32, Math.min(160, panel.iconSize + (w.angleDelta.y > 0 ? 12 : -12))); shell.view = "icons" } else w.accepted = false } }
            // files dropped here, from the other panel or from any app: into this folder
            DropArea { anchors.fill: parent; keys: ["text/uri-list"]; enabled: panel.path.startsWith("/") && !panel.source && panel.peek === ""
                onDropped: (d) => shell.dropInto(d, panel.path) }
            Label { anchors.centerIn: parent; visible: panel.path.startsWith("/") && !panel.source && files.count === 0 && files.status === FolderListModel.Ready; text: I18n.tr("This folder is empty."); color: Theme.faint }
            // This computer: the user's folders and the disks, as tiles
            Flow { visible: panel.path === "computer:" && !panel.source; anchors.fill: parent; anchors.margins: 6; spacing: 12
                Repeater { model: shell.places.filter(p => p.kind !== "trash" && (p.path !== "/" || shell.real))
                    Rectangle { required property var modelData; width: 220; height: 76; radius: 16; color: tileHit.containsMouse ? Theme.raised : Theme.card
                        Glyph { x: 18; name: shell.placeIcons[parent.modelData.kind]; font.pixelSize: 26; color: Theme.gold; anchors.verticalCenter: parent.verticalCenter }
                        Column { x: 58; width: parent.width - 70; anchors.verticalCenter: parent.verticalCenter; spacing: 2
                            Label { width: parent.width; font.weight: 700; text: parent.parent.modelData.kind === "disk" ? (parent.parent.modelData.name.split(" · ")[0] || parent.parent.modelData.path) : I18n.tr(shell.placeNames[parent.parent.modelData.kind]) }
                            Label { width: parent.width; color: Theme.dim; font.pixelSize: 12; text: parent.parent.modelData.kind === "disk" ? (parent.parent.modelData.name.split(" · ")[1] || "") : "" } }
                        MouseArea { id: tileHit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { shell.active = panel.index; panel.go(parent.modelData.path) } } } } }
            // how much each thing in the other panel's folder holds, the largest first
            ListView { id: sized; visible: panel.source !== null; anchors.fill: parent; clip: true; boundsBehavior: Flickable.StopAtBounds
                model: { if (!panel.source) return []; const s = panel.source.sizes; return Object.keys(s).sort((a, b) => s[b] - s[a]).map(k => ({ path: k, size: s[k] })) }
                header: Label { width: sized.width; height: 30; color: Theme.dim; font.pixelSize: 12
                                text: panel.source ? (panel.source.measuring ? I18n.tr("measuring… {size} so far", { size: shell.bytes(panel.source.total) }) : I18n.tr("{size} in all", { size: shell.bytes(panel.source.total) })) : "" }
                delegate: Rectangle { id: big; required property var modelData; width: sized.width; height: 34; radius: 9; color: bigHit.containsMouse ? Theme.card : "transparent"
                    Rectangle { x: 4; y: 4; height: parent.height - 8; radius: 6; color: Theme.coffee; opacity: 0.5; width: (parent.width - 8) * big.modelData.size / Math.max(1, panel.source ? panel.source.largest : 1) }
                    Label { x: 12; width: parent.width - 120; text: big.modelData.path.split("/").pop(); anchors.verticalCenter: parent.verticalCenter; font.weight: 600 }
                    Label { anchors.right: parent.right; anchors.rightMargin: 12; text: shell.bytes(big.modelData.size); anchors.verticalCenter: parent.verticalCenter }
                    MouseArea { id: bigHit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onDoubleClicked: { const src = panel.source; shell.hideSizes(); src.go(big.modelData.path) } } } }
            // the column heads: a press sorts by that, again the other way
            Row { id: heads; visible: list.visible; width: parent.width; height: 26
                Repeater { model: [{ by: "name", name: QT_TR_NOOP("Name"), w: -250 }, { by: "size", name: QT_TR_NOOP("Size"), w: 100 }, { by: "date", name: QT_TR_NOOP("Date modified"), w: 150 }]
                    Rectangle { required property var modelData; width: modelData.w < 0 ? heads.width + modelData.w : modelData.w; height: 26; radius: 7; color: headHit.containsMouse ? Theme.card : "transparent"
                        Label { x: parent.modelData.by === "name" ? 42 : 0; width: parent.width - (parent.modelData.by === "name" ? 42 : 10); horizontalAlignment: parent.modelData.by === "size" ? Text.AlignRight : Text.AlignLeft
                                text: I18n.tr(parent.modelData.name) + (panel.sortBy === parent.modelData.by ? (panel.sortDown ? "  ↓" : "  ↑") : ""); color: panel.sortBy === parent.modelData.by ? Theme.gold : Theme.faint
                                font.pixelSize: 12; font.weight: 600; anchors.verticalCenter: parent.verticalCenter }
                        MouseArea { id: headHit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: panel.sort(parent.modelData.by) } } } }
            ListView { id: list; visible: shell.view === "details" && panel.path.startsWith("/") && !panel.source && panel.peek === ""; y: 28; width: parent.width; height: parent.height - 28; model: files; clip: true; boundsBehavior: Flickable.StopAtBounds
                delegate: Rectangle { id: row; required property string fileName
                    required property string filePath
                    required property bool fileIsDir
                    required property var fileSize
                    required property date fileModified
                    required property int index
                    width: list.width; height: 34; radius: 9
                    color: panel.chosen[filePath] ? Qt.rgba(Theme.gold.r, Theme.gold.g, Theme.gold.b, 0.24) : (rowHit.containsMouse ? Theme.card : "transparent")
                    // measured: its share of the largest thing here, as a bar behind the row
                    Rectangle { visible: panel.measured && panel.sizes[row.filePath] !== undefined; x: 4; y: 4; height: parent.height - 8; radius: 6; color: Theme.coffee; opacity: 0.38
                                width: (parent.width - 8) * (panel.sizes[row.filePath] || 0) / panel.largest; Behavior on width { NumberAnimation { duration: 220 } } }
                    Image { x: 10; width: 22; height: 22; anchors.verticalCenter: parent.verticalCenter; source: FileIcons.of(row.fileName, row.filePath, row.fileIsDir); sourceSize.width: 44; sourceSize.height: 44; asynchronous: true }
                    Label { x: 42; width: parent.width - 42 - 250; text: row.fileName; anchors.verticalCenter: parent.verticalCenter; elide: Text.ElideMiddle }
                    Label { x: parent.width - 240; width: 90; horizontalAlignment: Text.AlignRight; text: panel.sizes[row.filePath] !== undefined ? shell.bytes(panel.sizes[row.filePath]) : (row.fileIsDir ? (panel.measured ? "…" : "") : shell.bytes(row.fileSize))
                            color: panel.measured ? Theme.cream : Theme.dim; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                    Label { x: parent.width - 140; width: 130; text: Qt.formatDateTime(row.fileModified, "d. M. yyyy  hh:mm"); color: Theme.dim; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                    Rectangle { anchors.fill: parent; radius: 9; color: "transparent"; border.width: 2; border.color: Theme.gold; visible: rowDrop.containsDrag }
                    DropArea { id: rowDrop; anchors.fill: parent; keys: ["text/uri-list"]; enabled: row.fileIsDir; onDropped: (d) => shell.dropInto(d, row.filePath) }
                    MouseArea { id: rowHit; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton | Qt.BackButton | Qt.ForwardButton
                        property point from
                        onPressed: (m) => { keys.forceActiveFocus(); shell.active = panel.index; from = Qt.point(m.x, m.y); if (panel.extra(m) || m.button === Qt.MiddleButton) return
                                            if (m.button === Qt.LeftButton || !panel.chosen[row.filePath]) panel.press(row.filePath, row.index, m.button === Qt.LeftButton ? m.modifiers : 0) }
                        onPositionChanged: (m) => { if ((m.buttons & Qt.LeftButton) && Math.abs(m.x - from.x) + Math.abs(m.y - from.y) > 10) shell.drag(panel.carried(row.filePath)) }
                        onClicked: (m) => { if (m.button === Qt.RightButton) { const q = mapToItem(overlay, m.x, m.y); shell.itemMenu(row.filePath, row.fileIsDir, q.x, q.y) }
                                            else if (m.button === Qt.MiddleButton && row.fileIsDir) { shell.dual = true; shell.other.go(row.filePath) } }
                        onDoubleClicked: (m) => { if (m.button === Qt.LeftButton) shell.open(row.filePath, row.fileIsDir) } } } }
            GridView { id: grid; visible: shell.view === "icons" && panel.path.startsWith("/") && !panel.source && panel.peek === ""; anchors.fill: parent; model: files; clip: true
                cellWidth: panel.iconSize + 60; cellHeight: panel.iconSize + 56; boundsBehavior: Flickable.StopAtBounds
                delegate: Item { id: cell; required property string fileName
                    required property string filePath
                    required property bool fileIsDir
                    required property int index
                    width: grid.cellWidth; height: grid.cellHeight
                    Rectangle { anchors.fill: parent; anchors.margins: 3; radius: 10; border.width: cellDrop.containsDrag ? 2 : 0; border.color: Theme.gold; color: panel.chosen[cell.filePath] ? Qt.rgba(Theme.gold.r, Theme.gold.g, Theme.gold.b, 0.24) : (cellHit.containsMouse ? Theme.card : "transparent") }
                    Image { y: 10; width: panel.iconSize; height: panel.iconSize; anchors.horizontalCenter: parent.horizontalCenter; source: FileIcons.of(cell.fileName, cell.filePath, cell.fileIsDir); sourceSize.width: 256; sourceSize.height: 256; fillMode: Image.PreserveAspectFit; asynchronous: true }
                    Label { y: panel.iconSize + 14; width: parent.width - 12; anchors.horizontalCenter: parent.horizontalCenter; horizontalAlignment: Text.AlignHCenter; text: cell.fileName; font.pixelSize: 12; wrapMode: Text.WrapAnywhere; maximumLineCount: 2 }
                    DropArea { id: cellDrop; anchors.fill: parent; keys: ["text/uri-list"]; enabled: cell.fileIsDir; onDropped: (d) => shell.dropInto(d, cell.filePath) }
                    MouseArea { id: cellHit; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton | Qt.BackButton | Qt.ForwardButton
                        property point from
                        onPressed: (m) => { keys.forceActiveFocus(); shell.active = panel.index; from = Qt.point(m.x, m.y); if (panel.extra(m) || m.button === Qt.MiddleButton) return
                                            if (m.button === Qt.LeftButton || !panel.chosen[cell.filePath]) panel.press(cell.filePath, cell.index, m.button === Qt.LeftButton ? m.modifiers : 0) }
                        onPositionChanged: (m) => { if ((m.buttons & Qt.LeftButton) && Math.abs(m.x - from.x) + Math.abs(m.y - from.y) > 10) shell.drag(panel.carried(cell.filePath)) }
                        onClicked: (m) => { if (m.button === Qt.RightButton) { const q = mapToItem(overlay, m.x, m.y); shell.itemMenu(cell.filePath, cell.fileIsDir, q.x, q.y) }
                                            else if (m.button === Qt.MiddleButton && cell.fileIsDir) { shell.dual = true; shell.other.go(cell.filePath) } }
                        onDoubleClicked: (m) => { if (m.button === Qt.LeftButton) shell.open(cell.filePath, cell.fileIsDir) } } } }
            // a look at one file: a picture as it is, the beginning of a text, else what it is
            Item { id: look; visible: panel.peek !== ""; anchors.fill: parent
                readonly property string name: panel.peek.split("/").pop()
                readonly property string kind: FileIcons.ending(name)
                readonly property bool picture: FileIcons.pictures.includes(kind) || ["svg", "bmp"].includes(kind)
                readonly property bool texty: ["txt", "md", "log", "json", "toml", "ini", "conf", "sh", "py", "lua", "luau", "qml", "js", "c", "h", "cpp", "rs", "csv", "xml", "html", "css", "yaml", "yml", "desktop", "plm"].includes(kind)
                Image { visible: look.picture; anchors.fill: parent; anchors.margins: 8; anchors.bottomMargin: 70; source: look.picture ? "file://" + panel.peek : ""; fillMode: Image.PreserveAspectFit; asynchronous: true; sourceSize.width: 1600 }
                // only its beginning: a log of gigabytes is looked at as fast as a note
                Process { id: lookText; command: ["head", "-c", "20000", "--", panel.peek]; running: look.texty && panel.peek !== ""
                          stdout: StdioCollector { onStreamFinished: lookBody.text = this.text } }
                onNameChanged: { lookBody.text = ""; if (look.texty) { lookText.running = false; lookText.running = true } }
                Flickable { visible: look.texty; anchors.fill: parent; anchors.margins: 8; anchors.bottomMargin: 70; contentHeight: lookBody.implicitHeight; clip: true
                    Text { id: lookBody; width: parent.width; wrapMode: Text.WrapAnywhere; color: Theme.cream; font.family: "JetBrains Mono"; font.pixelSize: 12 } }
                Column { visible: !look.picture && !look.texty; anchors.centerIn: parent; spacing: 12
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
        heading: here.source ? I18n.tr("Sizes") : (here.path === "computer:" ? I18n.tr("This computer") : (here.path === shell.home ? I18n.tr("Home") : (here.path.split("/").pop() || "/")))
        implicitWidth: 1180; implicitHeight: 760
        arrows: true; canGoBack: here.before.length > 0; onBack: here.back(); canGoForward: here.ahead.length > 0; onForward: here.forward()
        tools: [
            Pill { implicitHeight: 34; icon: "arrow-up"; text: I18n.tr("Up"); onPressed: here.up() },
            Pill { implicitHeight: 34; icon: "folder-plus"; text: I18n.tr("New folder"); onPressed: shell.ask("folder") },
            Pill { implicitHeight: 34; icon: shell.view === "details" ? "layout-grid" : "list"; text: shell.view === "details" ? I18n.tr("Icons") : I18n.tr("Details"); onPressed: shell.view = shell.view === "details" ? "icons" : "details" },
            Pill { implicitHeight: 34; icon: "layout-columns"; text: I18n.tr("Two panels"); strong: shell.dual; onPressed: { shell.dual = !shell.dual; if (!shell.dual) shell.active = 0 } }
        ]
        side: [
            Column { x: 14; y: 14; spacing: 4
                Row { x: 6; spacing: 10; height: 40
                    Glyph { name: "folders"; color: Theme.gold; font.pixelSize: 22; anchors.verticalCenter: parent.verticalCenter }
                    Label { text: "DualBrew"; font.pixelSize: 17; font.weight: 800; anchors.verticalCenter: parent.verticalCenter } }
                Item { width: 1; height: 6 }
                Nav { text: I18n.tr("This computer"); icon: "device-desktop"; on: here.path === "computer:"; onPressed: here.go("computer:") }
                Repeater { model: shell.places.filter(p => p.kind !== "disk")
                    Nav { required property var modelData; text: I18n.tr(shell.placeNames[modelData.kind]); icon: shell.placeIcons[modelData.kind]; on: here.path === modelData.path; onPressed: here.go(modelData.path) } }
                Label { x: 8; height: 30; verticalAlignment: Text.AlignBottom; text: I18n.tr("DISKS"); color: Theme.faint; font.pixelSize: 11; font.weight: 700; font.letterSpacing: 0.8 }
                Repeater { model: shell.places.filter(p => p.kind === "disk" && (p.path !== "/" || shell.real))
                    Nav { required property var modelData; text: modelData.path === "/" ? I18n.tr("The whole system (/)") : modelData.name; icon: "disc"; on: here.path === modelData.path; onPressed: here.go(modelData.path) } }
                Item { width: 1; height: 10 }
                Nav { text: I18n.tr("The real structure"); icon: shell.real ? "eye" : "eye-off"; on: shell.real; onPressed: shell.real = !shell.real } }
        ]
        foot: [
            // what is here and what is chosen
            Label { x: 24; anchors.verticalCenter: parent.verticalCenter; color: Theme.inkOnCoffee; visible: shell.asking === ""
                    text: !here.path.startsWith("/") ? I18n.tr("Your folders and the disks")
                          : (here.picked().length ? I18n.tr("{n} chosen", { n: here.picked().length }) : I18n.tr("{n} items", { n: here.count }))
                            + (here.measured ? "   ·   " + (here.measuring ? I18n.tr("measuring… {size} so far", { size: shell.bytes(here.total) }) : I18n.tr("{size} in all", { size: shell.bytes(here.total) }))
                                             : (here.picked().length ? "" : "   ·   " + I18n.tr("Space: how much each folder holds"))) },
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
                Label { text: shell.asking === "rename" ? I18n.tr("New name:") : I18n.tr("Name:"); color: Theme.inkOnCoffee; anchors.verticalCenter: parent.verticalCenter }
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
                if (ev.key === Qt.Key_Space && shell.peeking) shell.hidePeek()
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
                else if (ev.key === Qt.Key_Escape) { here.chosen = ({}); menu.close() }
                else ev.accepted = false
            }
            Panel { id: left; index: 0; width: shell.dual ? parent.width / 2 : parent.width; height: parent.height; path: shell.words[0] && shell.words[0].startsWith("/") ? shell.words[0] : shell.home }
            Panel { id: right; index: 1; visible: shell.dual; x: parent.width / 2; width: parent.width / 2; height: parent.height }
            Item { id: overlay; anchors.fill: parent; Menu { id: menu } }
            // what a drag of files is, in the window's own scene: the system takes it from there
            Item { id: carrier; Drag.dragType: Drag.Automatic; Drag.supportedActions: Qt.CopyAction | Qt.MoveAction | Qt.LinkAction; Drag.keys: ["text/uri-list"] }
        }
    }
    // ── dragging: a drag of the system, so other apps take the files too; dropped here they become a job ─────
    property bool dragging: false
    function drag(paths) {
        if (dragging || !paths.length) return
        dragging = true
        carrier.Drag.mimeData = { "text/uri-list": paths.map(p => "file://" + encodeURI(p)).join("\r\n") + "\r\n" }
        carrier.Drag.active = true                 // a drag has to be on before it can be handed to the system
        carrier.Drag.startDrag()
        carrier.Drag.active = false
        dragging = false
    }
    function dropInto(d, to) {
        if (!d.hasUrls) return
        const paths = d.urls.map(u => decodeURIComponent(String(u).replace(/^file:\/\//, ""))).filter(p => p.startsWith("/") && p !== to && p.slice(0, p.lastIndexOf("/")) !== to)
        if (!paths.length) return
        enqueue((d.modifiers & Qt.ControlModifier) ? "copy" : "auto", to, paths)
        d.accept(Qt.CopyAction)
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
