// DualBrew: the files. One panel as on Windows, or two side by side as in a commander; bin/latte-files moves
// things, this window shows them.   latte-app files [FOLDER]
//
// The side: the user's folders, the Trash, the disks. The header: up, a new folder, the view (details or icons),
// hidden files, one panel or two. The coffee at the foot says what is here and what is chosen, and with two
// panels it carries the commander's keys: F5 copy and F6 move to the other panel, F7 new folder, F8 delete.
// The mouse: a press chooses, Ctrl adds, Shift takes all between, twice opens, the right button is the menu.
// The keys: Enter opens, Backspace goes up, F2 renames, Delete trashes, Ctrl+C/X/V, Ctrl+A, Ctrl+H hidden
// files, Tab the other panel.
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
    property var places: []
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
        const inTrash = here.path.indexOf("/.local/share/Trash/files") >= 0
        menu.open(x, y, inTrash ? [{ icon: "trash", text: I18n.tr("Empty Recycle Bin"), danger: true, run: () => shell.act(["empty"]) }] : [
            { icon: "layout-grid", text: I18n.tr("View"), more: [{ text: I18n.tr("Details"), checked: shell.view === "details", run: () => shell.view = "details" },
                                                                  { text: I18n.tr("Icons"), checked: shell.view === "icons", run: () => shell.view = "icons" },
                                                                  { line: true }, { text: I18n.tr("Hidden files"), checked: shell.hidden, hint: "Ctrl+H", run: () => shell.hidden = !shell.hidden }] },
            { icon: "refresh", text: I18n.tr("Refresh"), hint: "F5", run: () => here.again() },
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
        readonly property bool isActive: shell.active === index
        function go(to) { if (to === path || to === "") return; before = before.concat([path]); path = to; chosen = ({}); last = "" }
        function back() { if (!before.length) return; const b = before.slice(); path = b.pop(); before = b; chosen = ({}) }
        function up() { if (path !== "/") go(path.replace(/\/[^/]+\/?$/, "") || "/") }
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
        }
        readonly property int count: files.count
        FolderListModel { id: files; folder: "file://" + panel.path; showDirsFirst: true; showDotAndDotDot: false; showHidden: shell.hidden; sortField: FolderListModel.Name }

        Rectangle { anchors.fill: parent; anchors.margins: 6; radius: 14; color: Theme.surface; border.width: shell.dual ? 2 : 0; border.color: panel.isActive ? Theme.gold : "transparent" }
        // where it is: every folder on the way can be pressed
        Flickable { id: crumbs; x: 18; y: 12; width: parent.width - 36; height: 32; contentWidth: way.width; clip: true; boundsBehavior: Flickable.StopAtBounds
            onContentWidthChanged: contentX = Math.max(0, contentWidth - width)
            Row { id: way; spacing: 2
                Repeater { model: ["/"].concat(panel.path.split("/").filter(p => p !== ""))
                    Rectangle { required property string modelData; required property int index; height: 30; width: crumb.implicitWidth + 18; radius: 9; color: crumbHit.containsMouse ? Theme.raised : "transparent"
                        Label { id: crumb; anchors.centerIn: parent; text: parent.index === 0 ? "/" : parent.modelData; color: Theme.dim; font.weight: 600 }
                        MouseArea { id: crumbHit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: { shell.active = panel.index; panel.go("/" + panel.path.split("/").filter(p => p !== "").slice(0, parent.index).join("/")) } } } } } }
        Item { x: 12; y: 50; width: parent.width - 24; height: parent.height - 62; clip: true
            MouseArea { anchors.fill: parent; acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onPressed: (m) => { shell.active = panel.index; keys.forceActiveFocus(); if (m.button === Qt.LeftButton) panel.chosen = ({}) }
                        onClicked: (m) => { if (m.button === Qt.RightButton) { const q = mapToItem(overlay, m.x, m.y); shell.groundMenu(q.x, q.y) } } }
            Label { anchors.centerIn: parent; visible: files.count === 0 && files.status === FolderListModel.Ready; text: I18n.tr("This folder is empty."); color: Theme.faint }
            ListView { id: list; visible: shell.view === "details"; anchors.fill: parent; model: files; clip: true; boundsBehavior: Flickable.StopAtBounds
                delegate: Rectangle { id: row; required property string fileName
                    required property string filePath
                    required property bool fileIsDir
                    required property var fileSize
                    required property date fileModified
                    required property int index
                    width: list.width; height: 34; radius: 9
                    color: panel.chosen[filePath] ? Qt.rgba(Theme.gold.r, Theme.gold.g, Theme.gold.b, 0.24) : (rowHit.containsMouse ? Theme.card : "transparent")
                    Image { x: 10; width: 22; height: 22; anchors.verticalCenter: parent.verticalCenter; source: FileIcons.of(row.fileName, row.filePath, row.fileIsDir); sourceSize.width: 44; sourceSize.height: 44; asynchronous: true }
                    Label { x: 42; width: parent.width - 42 - 250; text: row.fileName; anchors.verticalCenter: parent.verticalCenter; elide: Text.ElideMiddle }
                    Label { x: parent.width - 240; width: 90; horizontalAlignment: Text.AlignRight; text: row.fileIsDir ? "" : shell.bytes(row.fileSize); color: Theme.dim; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                    Label { x: parent.width - 140; width: 130; text: Qt.formatDateTime(row.fileModified, "d. M. yyyy  hh:mm"); color: Theme.dim; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                    MouseArea { id: rowHit; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onPressed: (m) => { keys.forceActiveFocus(); if (m.button === Qt.LeftButton || !panel.chosen[row.filePath]) panel.press(row.filePath, row.index, m.button === Qt.LeftButton ? m.modifiers : 0); shell.active = panel.index }
                        onClicked: (m) => { if (m.button === Qt.RightButton) { const q = mapToItem(overlay, m.x, m.y); shell.itemMenu(row.filePath, row.fileIsDir, q.x, q.y) } }
                        onDoubleClicked: (m) => { if (m.button === Qt.LeftButton) shell.open(row.filePath, row.fileIsDir) } } } }
            GridView { id: grid; visible: shell.view === "icons"; anchors.fill: parent; model: files; clip: true; cellWidth: 112; cellHeight: 108; boundsBehavior: Flickable.StopAtBounds
                delegate: Item { id: cell; required property string fileName
                    required property string filePath
                    required property bool fileIsDir
                    required property int index
                    width: 112; height: 108
                    Rectangle { anchors.fill: parent; anchors.margins: 3; radius: 10; color: panel.chosen[cell.filePath] ? Qt.rgba(Theme.gold.r, Theme.gold.g, Theme.gold.b, 0.24) : (cellHit.containsMouse ? Theme.card : "transparent") }
                    Image { y: 10; width: 52; height: 52; anchors.horizontalCenter: parent.horizontalCenter; source: FileIcons.of(cell.fileName, cell.filePath, cell.fileIsDir); sourceSize.width: 128; sourceSize.height: 128; fillMode: Image.PreserveAspectFit; asynchronous: true }
                    Label { y: 66; width: parent.width - 12; anchors.horizontalCenter: parent.horizontalCenter; horizontalAlignment: Text.AlignHCenter; text: cell.fileName; font.pixelSize: 12; wrapMode: Text.WrapAnywhere; maximumLineCount: 2 }
                    MouseArea { id: cellHit; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onPressed: (m) => { keys.forceActiveFocus(); if (m.button === Qt.LeftButton || !panel.chosen[cell.filePath]) panel.press(cell.filePath, cell.index, m.button === Qt.LeftButton ? m.modifiers : 0); shell.active = panel.index }
                        onClicked: (m) => { if (m.button === Qt.RightButton) { const q = mapToItem(overlay, m.x, m.y); shell.itemMenu(cell.filePath, cell.fileIsDir, q.x, q.y) } }
                        onDoubleClicked: (m) => { if (m.button === Qt.LeftButton) shell.open(cell.filePath, cell.fileIsDir) } } } }
        }
    }

    AppWindow {
        id: win
        title: "DualBrew"
        heading: here.path === shell.home ? I18n.tr("Home") : (here.path.split("/").pop() || "/")
        implicitWidth: 1180; implicitHeight: 760
        arrows: true; canGoBack: here.before.length > 0; onBack: here.back()
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
                Repeater { model: shell.places.filter(p => p.kind !== "disk")
                    Nav { required property var modelData; text: I18n.tr(shell.placeNames[modelData.kind]); icon: shell.placeIcons[modelData.kind]; on: here.path === modelData.path; onPressed: here.go(modelData.path) } }
                Label { x: 8; height: 30; verticalAlignment: Text.AlignBottom; text: I18n.tr("DISKS"); color: Theme.faint; font.pixelSize: 11; font.weight: 700; font.letterSpacing: 0.8 }
                Repeater { model: shell.places.filter(p => p.kind === "disk")
                    Nav { required property var modelData; text: modelData.name !== "" ? modelData.name : I18n.tr("This computer"); icon: "disc"; on: here.path === modelData.path; onPressed: here.go(modelData.path) } } }
        ]
        foot: [
            // what is here and what is chosen
            Label { x: 24; anchors.verticalCenter: parent.verticalCenter; color: Theme.inkOnCoffee; visible: shell.asking === ""
                    text: here.picked().length ? I18n.tr("{n} chosen", { n: here.picked().length }) : I18n.tr("{n} items", { n: here.count }) },
            // the commander's keys, with two panels
            Row { anchors.right: parent.right; anchors.rightMargin: 20; anchors.verticalCenter: parent.verticalCenter; spacing: 8; visible: shell.dual && shell.asking === ""
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
                if (ev.key === Qt.Key_Backspace) here.up()
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
        }
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
        else if (dual && other.path !== here.path) act([what, other.path].concat(picked))
        here.chosen = ({})
    }
}
