// The desktop: the Trash and what is in the user's Desktop folder, as icons over the wallpaper, used the way a
// desktop is on Windows. bin/latte-desktop starts and stops it.   latte-app desktop
//
// The mouse: a press chooses, Ctrl adds, a drag over the bare desktop chooses with a rectangle, twice opens.
//   An icon is dragged to another place (kept), onto a folder (moved there) or onto the Trash; over a window it
//   becomes a drag the app under it takes. A file dropped here from an app is copied to the Desktop folder.
// The keys, once the desktop was pressed: Enter opens, F2 renames, Delete trashes, Ctrl+A, Ctrl+C/X/V, F5.
// The right button: on the bare desktop View, Sort by, Refresh, Paste, New, Display settings, Personalize, Open
//   in Terminal; on an icon Open, Cut, Copy, Copy as path, Rename, Delete, Properties.
//
// It draws nothing behind the icons: the wallpaper is whoever's it is, a picture or a film. Its colours are the
// theme's (common/Theme.qml). The files themselves are moved by gio, which knows the Trash and name clashes.
// What the user chose (size of the icons, order, where each one lies) is kept in ~/.config/latteos/desktop.json.
import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "common"

ShellRoot {
    id: desk
    readonly property string home: Quickshell.env("HOME") || "/"
    readonly property string config: (Quickshell.env("XDG_CONFIG_HOME") || (home + "/.config")) + "/latteos"
    property string folder: ""                 // the Desktop folder, once xdg-user-dir has said where it is
    readonly property string trash: home + "/.local/share/Trash/files"
    property var chosen: ({})                  // path → true
    property string renaming: ""               // the icon whose name is being typed
    property var facts: null                   // what Properties shows

    // ── what the user chose ────────────────────────────────────────────────────────────────────────────────
    property var prefs: ({ size: "medium", auto: false, sort: "name", reversed: false, at: {} })
    FileView { id: kept; path: desk.config + "/desktop.json"; printErrors: false
               onLoaded: { try { desk.prefs = Object.assign({}, desk.prefs, JSON.parse(text())) } catch (e) {} } }
    function set(key, value) { const p = Object.assign({}, prefs); p[key] = value; prefs = p; keep.restart() }
    Timer { id: keep; interval: 400; onTriggered: Quickshell.execDetached(["sh", "-c", "mkdir -p \"$1\" && printf '%s' \"$2\" > \"$1/desktop.json\"", "sh", desk.config, JSON.stringify(desk.prefs)]) }
    // a cell's width and height, and the picture in it
    readonly property var sizes: ({ small: [84, 78, 36], medium: [104, 98, 52], large: [136, 128, 76] })
    readonly property var size: sizes[prefs.size] || sizes.medium
    readonly property int cellW: size[0]
    readonly property int cellH: size[1]

    // turned off in the Settings: it leaves
    FileView { path: desk.config + "/desktop-icons"; printErrors: false; watchChanges: true; onFileChanged: reload()
               onLoaded: if (text().trim() === "off") Qt.quit() }
    Process { running: true; command: ["sh", "-c", "d=$(xdg-user-dir DESKTOP 2>/dev/null); [ -n \"$d\" ] && [ \"$d\" != \"$HOME\" ] || d=\"$HOME/Desktop\"; mkdir -p \"$d\" \"$HOME/.local/share/Trash/files\"; printf '%s' \"$d\""]
              stdout: StdioCollector { onStreamFinished: desk.folder = this.text.trim() } }

    // ── doing things to files ──────────────────────────────────────────────────────────────────────────────
    Process { id: doer; onExited: files.again() }
    function sh(script, args) { doer.running = false; doer.command = ["sh", "-c", script, "sh"].concat(args || []); doer.running = true }
    function open(path) {
        if (path === trash) Quickshell.execDetached(["gio", "open", "trash:///"])
        else Quickshell.execDetached(path.endsWith(".desktop") ? ["gio", "launch", path] : ["gio", "open", path])
    }
    function picked() { return Object.keys(chosen).filter(p => p !== trash) }
    function toTrash(paths) { if (paths.length) { sh('gio trash -- "$@"', paths); chosen = {} } }
    // the clipboard as file managers keep it, so that what is cut or copied here can be pasted in one
    function clip(cut) {
        const l = picked()
        if (l.length) sh('m="$1"; shift; { echo "$m"; for f in "$@"; do printf "file://%s\\n" "$f"; done; } | wl-copy -t x-special/gnome-copied-files', [cut ? "cut" : "copy"].concat(l))
    }
    function paste() {
        sh('d="$1"; c=$(wl-paste -t x-special/gnome-copied-files 2>/dev/null) || c=$(wl-paste -t text/uri-list 2>/dev/null) || exit 0; '
           + 'm=$(printf "%s\\n" "$c" | head -1); printf "%s\\n" "$c" | grep "^file://" | while IFS= read -r u; do '
           + 'if [ "$m" = cut ]; then gio move -- "$u" "$d/"; else gio copy --backup -- "$u" "$d/"; fi; done', [folder])
    }
    function rename(path, name) {
        renaming = ""
        name = name.trim()
        const old = path.split("/").pop()
        if (name === "" || name.indexOf("/") >= 0 || name === old) return
        const at = Object.assign({}, prefs.at)
        if (at[old]) { at[name] = at[old]; delete at[old]; set("at", at) }
        sh('[ -e "$2" ] || mv -n -- "$1" "$2"', [path, folder + "/" + name])
    }
    // a name nothing has yet: "New folder", "New folder (2)"…
    function create(name, ending, isFolder) {
        sh('d="$1"; n="$2"; e="$3"; t="$d/$n$e"; i=2; while [ -e "$t" ]; do t="$d/$n ($i)$e"; i=$((i+1)); done; if [ "$4" = 1 ]; then mkdir -- "$t"; else : > "$t"; fi',
           [folder, name, ending, isFolder ? "1" : "0"])
    }
    // to a folder: moved on the same disk and copied from another, as a hand expects; `how` says otherwise
    function into(how, paths, dir) {
        if (how === "copy") sh('d="$1"; shift; for f in "$@"; do gio copy --backup -- "$f" "$d/"; done', [dir].concat(paths))
        else if (how === "link") sh('d="$1"; shift; for f in "$@"; do ln -s -- "$f" "$d/" 2>/dev/null; done', [dir].concat(paths))
        else if (how === "move") sh('d="$1"; shift; for f in "$@"; do gio move -- "$f" "$d/"; done', [dir].concat(paths))
        else sh('d="$1"; shift; on=$(stat -c %d "$d"); for f in "$@"; do if [ "$(stat -c %d "$f" 2>/dev/null)" = "$on" ]; then gio move -- "$f" "$d/"; else gio copy --backup -- "$f" "$d/"; fi; done', [dir].concat(paths))
        chosen = {}
    }
    Process { id: asker; stdout: StdioCollector { onStreamFinished: { try { desk.facts = JSON.parse(this.text) } catch (e) { desk.facts = null } } } }
    function properties(path) {
        asker.running = false
        asker.command = ["sh", "-c", "p=\"$1\"; s=$(du -sb -- \"$p\" 2>/dev/null | cut -f1); "
            + "stat -c '{\"size\": '\"${s:-0}\"', \"owner\": \"%U\", \"rights\": \"%A\", \"changed\": \"%y\", \"kind\": \"%F\"}' -- \"$p\"", "sh", path]
        facts = null; factsOf = path; asker.running = true
    }
    property string factsOf: ""
    function bytes(b) { const u = ["B", "KB", "MB", "GB", "TB"]; let v = b || 0, i = 0; while (v >= 1024 && i < 4) { v /= 1024; i++ } return v.toFixed(i ? 1 : 0) + " " + u[i] }

    // ── the files and where each lies ──────────────────────────────────────────────────────────────────────
    FolderListModel {
        id: files
        folder: desk.folder === "" ? "" : "file://" + desk.folder
        showDirsFirst: true; showDotAndDotDot: false; showHidden: false
        sortField: ({ name: FolderListModel.Name, size: FolderListModel.Size, kind: FolderListModel.Type, date: FolderListModel.Time })[desk.prefs.sort] || FolderListModel.Name
        sortReversed: desk.prefs.reversed
        function again() { const f = folder; folder = ""; folder = f }
    }
    FolderListModel { id: trashed; folder: "file://" + desk.trash; showDirs: true; showHidden: true; showDotAndDotDot: false }
    property int rows: 1
    property var places: ({})                  // path → [column, row]
    // The Trash first, then the files: where the user put them, or the next free cell down the columns.
    function arrange() {
        const used = {}, out = {}, list = [trash]
        for (let i = 0; i < files.count; i++) list.push(files.get(i, "filePath"))
        const free = () => { for (let c = 0; ; c++) for (let r = 0; r < rows; r++) if (!used[c + ":" + r]) return [c, r] }
        if (!prefs.auto) for (const p of list) {
            const s = prefs.at[key(p)] || (p === trash ? [0, 0] : null)
            if (s && s[1] < rows && !used[s[0] + ":" + s[1]]) { out[p] = s; used[s[0] + ":" + s[1]] = true }
        }
        for (const p of list) if (!out[p]) { const c = free(); out[p] = c; used[c[0] + ":" + c[1]] = true }
        places = out
    }
    Connections { target: files; function onCountChanged() { soon.restart() } }
    onRowsChanged: soon.restart()
    onPrefsChanged: soon.restart()
    Timer { id: soon; interval: 30; onTriggered: desk.arrange() }
    function key(p) { return p === trash ? "::trash" : p.split("/").pop() }
    function iconAt(x, y) {
        const c = Math.floor((x - 12) / cellW), r = Math.floor((y - 12) / cellH)
        for (const p in places) if (places[p][0] === c && places[p][1] === r) return p
        return ""
    }
    function isFolder(p) { for (let i = 0; i < files.count; i++) if (files.get(i, "filePath") === p) return files.get(i, "fileIsDir"); return false }
    // icons dragged to other cells: all of them by the same step, each to the nearest cell that is free
    function carry(paths, dc, dr) {
        const at = Object.assign({}, prefs.at), taken = {}
        for (const p in places) if (paths.indexOf(p) < 0) taken[places[p][0] + ":" + places[p][1]] = true
        for (const p of paths) {
            const l = places[p]
            if (!l) continue
            let c = Math.max(0, l[0] + dc), r = Math.max(0, Math.min(rows - 1, l[1] + dr))
            while (taken[c + ":" + r]) { r++; if (r >= rows) { r = 0; c++ } }
            taken[c + ":" + r] = true
            at[key(p)] = [c, r]
        }
        const p2 = Object.assign({}, prefs); p2.at = at; p2.auto = false; prefs = p2; keep.restart()
    }
    // the picture of a file: itself if it is a picture, else its kind's icon from the system's set
    readonly property var kinds: ({ "image-x-generic": ["svg", "bmp", "ico", "tiff", "xcf"], "audio-x-generic": ["mp3", "flac", "ogg", "wav", "m4a", "opus"],
        "video-x-generic": ["mp4", "mkv", "webm", "mov", "avi"], "package-x-generic": ["zip", "gz", "xz", "tar", "7z", "rar", "bz2", "zst"],
        "application-pdf": ["pdf"], "x-office-document": ["odt", "doc", "docx", "rtf"], "x-office-spreadsheet": ["ods", "xls", "xlsx", "csv"],
        "x-office-presentation": ["odp", "ppt", "pptx"], "text-x-script": ["sh", "py", "lua", "js", "rs", "c", "cpp", "h", "json", "toml", "qml"],
        "application-x-executable": ["appimage", "exe", "run", "bin"], "text-html": ["html", "htm"] })
    readonly property var pictures: ["png", "jpg", "jpeg", "webp", "gif"]
    function ending(name) { const i = name.lastIndexOf("."); return i > 0 ? name.slice(i + 1).toLowerCase() : "" }
    function pictureOf(name, path, isDir) {
        if (isDir) return Quickshell.iconPath("folder", true)
        const e = ending(name)
        if (pictures.includes(e)) return "file://" + path
        for (const k in kinds) if (kinds[k].includes(e)) return Quickshell.iconPath(k, true)
        return Quickshell.iconPath("text-x-generic", true)
    }

    // ── the menus ──────────────────────────────────────────────────────────────────────────────────────────
    function desktopMenu(x, y) {
        const p = prefs
        const big = (id, text) => ({ text: text, checked: p.size === id, run: () => desk.set("size", id) })
        const by = (id, text) => ({ text: text, checked: p.sort === id, run: () => { const q = Object.assign({}, desk.prefs); q.sort = id; q.auto = true; desk.prefs = q; keep.restart() } })
        menu.open(x, y, [
            { icon: "layout-grid", text: I18n.tr("View"), more: [big("large", I18n.tr("Large icons")), big("medium", I18n.tr("Medium icons")), big("small", I18n.tr("Small icons")), { line: true },
                { text: I18n.tr("Auto arrange icons"), checked: p.auto, run: () => desk.set("auto", !p.auto) },
                { text: I18n.tr("Show desktop icons"), checked: true, run: () => Quickshell.execDetached(["latte-desktop", "off"]) }] },
            { icon: "arrows-sort", text: I18n.tr("Sort by"), more: [by("name", I18n.tr("Name")), by("size", I18n.tr("Size")), by("kind", I18n.tr("Item type")), by("date", I18n.tr("Date modified")), { line: true },
                { text: I18n.tr("Descending"), checked: p.reversed, run: () => desk.set("reversed", !p.reversed) }] },
            { icon: "refresh", text: I18n.tr("Refresh"), hint: "F5", run: () => files.again() },
            { line: true },
            { icon: "clipboard", text: I18n.tr("Paste"), hint: "Ctrl+V", run: () => desk.paste() },
            { icon: "plus", text: I18n.tr("New"), more: [
                { icon: "folder-plus", text: I18n.tr("Folder"), run: () => desk.create(I18n.tr("New folder"), "", true) },
                { icon: "file-text", text: I18n.tr("Text Document"), run: () => desk.create(I18n.tr("New Text Document"), ".txt", false) }] },
            { line: true },
            { icon: "device-desktop", text: I18n.tr("Display settings"), run: () => Quickshell.execDetached(["latte-app", "settings", "displays"]) },
            { icon: "palette", text: I18n.tr("Personalize"), run: () => Quickshell.execDetached(["latte-app", "settings", "background"]) },
            { line: true },
            { icon: "terminal-2", text: I18n.tr("Open in Terminal"), run: () => Quickshell.execDetached(["sh", "-c", "cd \"$1\" && exec foot", "sh", desk.folder]) }])
    }
    function iconMenu(path, x, y) {
        if (path === trash) {
            return menu.open(x, y, [{ icon: "external-link", text: I18n.tr("Open"), bold: true, run: () => desk.open(trash) },
                                    { icon: "trash", text: I18n.tr("Empty Recycle Bin"), danger: true, enabled: trashed.count > 0, run: () => desk.sh("gio trash --empty") }])
        }
        if (!chosen[path]) { const s = {}; s[path] = true; chosen = s }
        const many = picked().length > 1
        const rows = [{ icon: "external-link", text: I18n.tr("Open"), bold: true, hint: "Enter", run: () => { for (const p of desk.picked()) desk.open(p) } },
            { line: true },
            { icon: "cut", text: I18n.tr("Cut"), hint: "Ctrl+X", run: () => desk.clip(true) },
            { icon: "copy", text: I18n.tr("Copy"), hint: "Ctrl+C", run: () => desk.clip(false) },
            { icon: "clipboard", text: I18n.tr("Copy as path"), run: () => Quickshell.execDetached(["wl-copy", "--", desk.picked().join("\n")]) },
            { line: true }]
        if (!many) rows.push({ icon: "pencil", text: I18n.tr("Rename"), hint: "F2", run: () => desk.renaming = path })
        rows.push({ icon: "trash", text: I18n.tr("Delete"), hint: "Del", danger: true, run: () => desk.toTrash(desk.picked()) })
        if (!many) rows.push({ line: true }, { icon: "info-circle", text: I18n.tr("Properties"), hint: "Alt+Enter", run: () => desk.properties(path) })
        menu.open(x, y, rows)
    }
    // let go with the right button: asked what to do, as on Windows
    function dropMenu(paths, dir, x, y) {
        menu.open(x, y, dir === trash
            ? [{ icon: "trash", text: I18n.tr("Move to Recycle Bin"), bold: true, run: () => desk.toTrash(paths) }, { line: true }, { icon: "x", text: I18n.tr("Cancel") }]
            : [{ icon: "copy", text: I18n.tr("Copy here"), run: () => desk.into("copy", paths, dir) },
               { icon: "external-link", text: I18n.tr("Move here"), bold: true, run: () => desk.into("move", paths, dir) },
               { icon: "link", text: I18n.tr("Create shortcuts here"), run: () => desk.into("link", paths, dir) },
               { line: true }, { icon: "x", text: I18n.tr("Cancel") }])
    }

    // ── dragging ───────────────────────────────────────────────────────────────────────────────────────────
    property string dragged: ""
    property real dragX: 0
    property real dragY: 0
    property string target: ""                 // the folder or the Trash under what is dragged
    property int dragButton: Qt.LeftButton
    property bool wasDragged: false            // the press that ends a drag opens no menu
    property var windows: []                   // where the windows are, asked when a drag starts
    Process { id: where; command: ["sh", "-c", "hyprctl clients -j; echo; hyprctl activeworkspace -j"]
        stdout: StdioCollector { onStreamFinished: {
            try { const t = this.text, i = t.lastIndexOf("\n{"), all = JSON.parse(t.substring(0, i)), ws = JSON.parse(t.substring(i + 1))
                  desk.windows = all.filter(c => c.mapped && !c.hidden && c.workspace.id === ws.id).map(c => ({ x: c.at[0] - win.screen.x, y: c.at[1] - win.screen.y, w: c.size[0], h: c.size[1] })) }
            catch (e) { desk.windows = [] } } } }
    function overWindow(x, y) { return windows.some(r => x >= r.x && y >= r.y && x < r.x + r.w && y < r.y + r.h) }
    Item { id: out; Drag.dragType: Drag.Automatic; Drag.supportedActions: Qt.CopyAction | Qt.MoveAction | Qt.LinkAction; Drag.keys: ["text/uri-list"] }
    function dropped(d, dir) {
        if (!d.hasUrls) return
        const l = d.urls.map(u => decodeURIComponent(String(u).replace(/^file:\/\//, ""))).filter(p => p.startsWith("/"))
        if (!l.length) return
        const m = d.modifiers || 0
        into(m & Qt.ControlModifier ? "copy" : (m & Qt.AltModifier ? "link" : ((d.supportedActions & Qt.MoveAction) ? "auto" : "copy")), l, dir)
        d.accept(Qt.CopyAction)
    }

    PanelWindow {
        id: win
        // on the monitor the Goo's main scene is on
        screen: Quickshell.screens.find(s => s.name === Quickshell.env("LATTE_GOO_SCREEN")) || Quickshell.screens[0]
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Normal        // the bar's band stays the bar's: no icon under it
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.namespace: "latte-desktop"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand     // the keys only once the desktop was pressed
        color: "transparent"
        onHeightChanged: desk.rows = Math.max(1, Math.floor((height - 24) / desk.cellH))
        Connections { target: desk; function onCellHChanged() { desk.rows = Math.max(1, Math.floor((win.height - 24) / desk.cellH)) } }

        Item {
            id: root
            anchors.fill: parent
            focus: true
            Keys.onPressed: (ev) => {
                if (desk.renaming !== "") return
                const ctrl = ev.modifiers & Qt.ControlModifier, one = desk.picked().length === 1 ? desk.picked()[0] : ""
                ev.accepted = true
                if (ev.key === Qt.Key_F2 && one) desk.renaming = one
                else if (ev.key === Qt.Key_Delete) desk.toTrash(desk.picked())
                else if ((ev.key === Qt.Key_Return || ev.key === Qt.Key_Enter) && (ev.modifiers & Qt.AltModifier) && one) desk.properties(one)
                else if (ev.key === Qt.Key_Return || ev.key === Qt.Key_Enter) { for (const p of Object.keys(desk.chosen)) desk.open(p) }
                else if (ev.key === Qt.Key_A && ctrl) { const s = {}; for (const p in desk.places) if (p !== desk.trash) s[p] = true; desk.chosen = s }
                else if (ev.key === Qt.Key_C && ctrl) desk.clip(false)
                else if (ev.key === Qt.Key_X && ctrl) desk.clip(true)
                else if (ev.key === Qt.Key_V && ctrl) desk.paste()
                else if (ev.key === Qt.Key_F5) files.again()
                else if (ev.key === Qt.Key_Escape) { desk.chosen = {}; desk.facts = null; menu.close() }
                else ev.accepted = false
            }

            // the bare desktop: the right button is its menu, the left one lets go of what was chosen, a drag chooses
            MouseArea {
                id: bare
                anchors.fill: parent; acceptedButtons: Qt.LeftButton | Qt.RightButton
                property point from
                property bool band: false
                onPressed: (m) => { root.forceActiveFocus(); from = Qt.point(m.x, m.y); band = false; desk.facts = null
                                    if (m.button === Qt.LeftButton && !(m.modifiers & Qt.ControlModifier)) desk.chosen = {} }
                onPositionChanged: (m) => {
                    if (!(m.buttons & Qt.LeftButton)) return
                    band = Math.abs(m.x - from.x) + Math.abs(m.y - from.y) > 6
                    if (!band) return
                    const x0 = Math.min(from.x, m.x), x1 = Math.max(from.x, m.x), y0 = Math.min(from.y, m.y), y1 = Math.max(from.y, m.y)
                    rubber.x = x0; rubber.y = y0; rubber.width = x1 - x0; rubber.height = y1 - y0
                    const s = {}
                    for (const p in desk.places) { const l = desk.places[p], ix = 12 + l[0] * desk.cellW, iy = 12 + l[1] * desk.cellH
                        if (ix < x1 && ix + desk.cellW > x0 && iy < y1 && iy + desk.cellH > y0) s[p] = true }
                    desk.chosen = s
                }
                onReleased: band = false
                onClicked: (m) => { if (m.button === Qt.RightButton) desk.desktopMenu(m.x, m.y) }
            }
            Rectangle { id: rubber; visible: bare.band; color: Qt.rgba(Theme.gold.r, Theme.gold.g, Theme.gold.b, 0.18); border.color: Theme.gold; border.width: 1 }
            DropArea { anchors.fill: parent; keys: ["text/uri-list"]; onDropped: (d) => desk.dropped(d, desk.folder) }

            component Icon: Item {
                id: ic
                property string path
                property string name
                property bool isDir: false
                property string picture: ""
                property string glyph: "file"
                property string badge: ""
                readonly property bool picked: desk.chosen[path] === true
                readonly property var cell: desk.places[path] || [0, 0]
                property bool dragging: false
                property real dx: 0
                property real dy: 0
                // dragged together: everything chosen moves with the one that is held
                readonly property bool along: desk.dragged !== "" && picked && desk.dragged !== path
                x: 12 + cell[0] * desk.cellW + (dragging ? dx : (along ? desk.dragX : 0))
                y: 12 + cell[1] * desk.cellH + (dragging ? dy : (along ? desk.dragY : 0))
                z: dragging || along ? 10 : 0
                width: desk.cellW - 4; height: desk.cellH - 4
                opacity: dragging || along ? 0.8 : 1
                Behavior on x { enabled: !ic.dragging && !ic.along; NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                Behavior on y { enabled: !ic.dragging && !ic.along; NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                Rectangle { anchors.fill: parent; radius: 8
                    color: ic.picked ? Qt.rgba(Theme.gold.r, Theme.gold.g, Theme.gold.b, 0.30) : (hit.containsMouse || desk.target === ic.path || onto.containsDrag ? Qt.rgba(1, 1, 1, 0.13) : "transparent")
                    border.width: 1; border.color: ic.picked || desk.target === ic.path || onto.containsDrag ? Qt.rgba(Theme.gold.r, Theme.gold.g, Theme.gold.b, 0.7) : "transparent" }
                Item { id: tile; width: desk.size[2]; height: desk.size[2]; anchors.horizontalCenter: parent.horizontalCenter; y: 6
                    Image { id: shown; anchors.fill: parent; source: ic.picture; sourceSize.width: 160; sourceSize.height: 160; fillMode: Image.PreserveAspectFit; asynchronous: true; smooth: true }
                    Glyph { anchors.centerIn: parent; visible: shown.status !== Image.Ready; name: ic.glyph; font.pixelSize: parent.width * 0.7; color: "white"
                            style: Text.Outline; styleColor: Qt.rgba(0, 0, 0, 0.4) }
                    Rectangle { visible: ic.badge !== ""; anchors.right: parent.right; anchors.top: parent.top; anchors.rightMargin: -6; anchors.topMargin: -4
                                width: Math.max(20, count.implicitWidth + 10); height: 20; radius: 10; color: Theme.gold
                                Label { id: count; anchors.centerIn: parent; text: ic.badge; color: Theme.inkOnGold; font.pixelSize: 11; font.weight: 700 } } }
                Text { visible: desk.renaming !== ic.path; anchors.top: tile.bottom; anchors.topMargin: 3; anchors.horizontalCenter: parent.horizontalCenter
                       width: parent.width - 6; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WrapAnywhere; maximumLineCount: 2; elide: Text.ElideRight
                       text: ic.name; color: "white"; style: Text.Outline; styleColor: Qt.rgba(0, 0, 0, 0.6)
                       font.family: Theme.font; font.pixelSize: desk.prefs.size === "small" ? 11 : 12; font.weight: 600 }
                // the name typed under the icon: the part before the ending is chosen, Enter or a press elsewhere keeps it
                Rectangle { visible: desk.renaming === ic.path; z: 20; anchors.top: tile.bottom; anchors.topMargin: 2; anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width + 24; height: 24; radius: 6; color: Theme.card; border.color: Theme.gold; border.width: 1
                    TextInput { id: typed; anchors.fill: parent; anchors.leftMargin: 6; anchors.rightMargin: 6; verticalAlignment: TextInput.AlignVCenter; horizontalAlignment: TextInput.AlignHCenter
                        clip: true; color: Theme.cream; selectionColor: Theme.gold; selectedTextColor: Theme.inkOnGold; selectByMouse: true; font.family: Theme.font; font.pixelSize: 12
                        onVisibleChanged: if (visible) { text = ic.path.split("/").pop(); Qt.callLater(() => { forceActiveFocus(); const dot = text.lastIndexOf("."); select(0, dot > 0 && !ic.isDir ? dot : text.length) }) }
                        Keys.onReturnPressed: (ev) => { ev.accepted = true; desk.rename(ic.path, text); root.forceActiveFocus() }
                        Keys.onEnterPressed: (ev) => { ev.accepted = true; desk.rename(ic.path, text); root.forceActiveFocus() }
                        Keys.onEscapePressed: (ev) => { ev.accepted = true; desk.renaming = ""; root.forceActiveFocus() }
                        onActiveFocusChanged: if (!activeFocus && desk.renaming === ic.path) desk.rename(ic.path, text) } }
                MouseArea {
                    id: hit; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.LeftButton | Qt.RightButton
                    property point from
                    onPressed: (m) => {
                        root.forceActiveFocus(); from = mapToItem(root, m.x, m.y); desk.dragButton = m.button; desk.wasDragged = false; desk.facts = null
                        if (ic.path !== desk.trash) where.running = true
                        if (m.button !== Qt.LeftButton) return
                        if (m.modifiers & Qt.ControlModifier) { const s = Object.assign({}, desk.chosen); if (s[ic.path]) delete s[ic.path]; else s[ic.path] = true; desk.chosen = s }
                        else if (!ic.picked) { const s = {}; s[ic.path] = true; desk.chosen = s }
                    }
                    onPositionChanged: (m) => {
                        if (!(m.buttons & (Qt.LeftButton | Qt.RightButton))) return
                        const q = mapToItem(root, m.x, m.y), ddx = q.x - from.x, ddy = q.y - from.y
                        if (!ic.dragging && Math.abs(ddx) + Math.abs(ddy) < 8) return
                        if (ic.path !== desk.trash && desk.overWindow(q.x, q.y)) {       // over a window: the app under it takes the files
                            const paths = desk.chosen[ic.path] ? desk.picked() : [ic.path]
                            ic.dragging = false; ic.dx = 0; ic.dy = 0; desk.dragged = ""; desk.dragX = 0; desk.dragY = 0; desk.target = ""; desk.windows = []; desk.wasDragged = true
                            out.Drag.mimeData = { "text/uri-list": paths.map(p => "file://" + encodeURI(p)).join("\r\n") + "\r\n" }
                            out.Drag.startDrag()
                            return
                        }
                        ic.dragging = true; ic.dx = ddx; ic.dy = ddy
                        desk.dragged = ic.path; desk.dragX = ddx; desk.dragY = ddy
                        const t = desk.iconAt(q.x, q.y)
                        desk.target = t !== "" && !desk.chosen[t] && t !== ic.path && (t === desk.trash || desk.isFolder(t)) ? t : ""
                    }
                    onReleased: (m) => {
                        if (!ic.dragging) return
                        desk.wasDragged = true
                        const paths = desk.chosen[ic.path] ? Object.keys(desk.chosen) : [ic.path], to = desk.target
                        const dc = Math.round(ic.dx / desk.cellW), dr = Math.round(ic.dy / desk.cellH), q = mapToItem(root, m.x, m.y)
                        ic.dragging = false; ic.dx = 0; ic.dy = 0; desk.dragged = ""; desk.dragX = 0; desk.dragY = 0; desk.target = ""
                        const movable = paths.filter(p => p !== desk.trash)
                        if (to !== "" && desk.dragButton !== Qt.LeftButton) desk.dropMenu(movable, to, q.x, q.y)
                        else if (to === desk.trash) desk.toTrash(movable)
                        else if (to !== "") desk.into(m.modifiers & Qt.ControlModifier ? "copy" : (m.modifiers & Qt.AltModifier ? "link" : "move"), movable, to)
                        else if (dc !== 0 || dr !== 0) desk.carry(paths, dc, dr)
                    }
                    onClicked: (m) => { if (desk.wasDragged) { desk.wasDragged = false; return }
                                        if (m.button === Qt.RightButton) { const q = mapToItem(root, m.x, m.y); desk.iconMenu(ic.path, q.x, q.y) } }
                    onDoubleClicked: (m) => { if (m.button === Qt.LeftButton) desk.open(ic.path) }
                }
                // the Trash and folders take a file dragged in from an app
                DropArea { id: onto; anchors.fill: parent; keys: ["text/uri-list"]; enabled: ic.path === desk.trash || ic.isDir
                    onDropped: (d) => {
                        if (!d.hasUrls) return
                        if (ic.path === desk.trash) { desk.toTrash(d.urls.map(u => decodeURIComponent(String(u).replace(/^file:\/\//, "")))); d.accept(Qt.MoveAction) }
                        else desk.dropped(d, ic.path)
                    } }
            }
            Icon { path: desk.trash; name: I18n.tr("Recycle Bin"); glyph: "trash"; badge: trashed.count > 0 ? String(trashed.count) : ""
                   picture: Quickshell.iconPath(trashed.count > 0 ? "user-trash-full" : "user-trash", true) }
            Repeater { model: files
                Icon { required property string fileName
                       required property string filePath
                       required property bool fileIsDir
                       readonly property var app: fileName.endsWith(".desktop") ? DesktopEntries.byId(fileName.slice(0, -8)) : null
                       path: filePath; name: app ? app.name : fileName; isDir: fileIsDir; glyph: fileIsDir ? "folder" : "file"
                       picture: app && app.icon ? Quickshell.iconPath(app.icon, true) : desk.pictureOf(fileName, filePath, fileIsDir) } }

            // Properties: what a file is, in a small card where the eye is
            Rectangle { visible: desk.facts !== null; z: 50; anchors.centerIn: parent; width: 420; height: about.implicitHeight + 36; radius: 16
                color: Theme.card; border.color: Theme.line; border.width: 1
                MouseArea { anchors.fill: parent }
                Column { id: about; x: 18; y: 18; width: parent.width - 36; spacing: 8
                    Item { width: parent.width; height: 26
                        Label { width: parent.width - 34; text: desk.factsOf.split("/").pop(); font.pixelSize: 17; font.weight: 700; elide: Text.ElideMiddle; anchors.verticalCenter: parent.verticalCenter }
                        Glyph { anchors.right: parent.right; name: "x"; color: Theme.dim; anchors.verticalCenter: parent.verticalCenter
                                MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; onClicked: desk.facts = null } } }
                    Repeater { model: desk.facts ? [[I18n.tr("Type"), desk.facts.kind], [I18n.tr("Location"), desk.factsOf.substring(0, desk.factsOf.lastIndexOf("/"))],
                                                    [I18n.tr("Size"), desk.bytes(desk.facts.size)], [I18n.tr("Owner"), desk.facts.owner], [I18n.tr("Rights"), desk.facts.rights],
                                                    [I18n.tr("Modified"), String(desk.facts.changed).slice(0, 19)]] : []
                        Row { required property var modelData; spacing: 10; width: about.width
                              Label { width: 110; text: modelData[0]; color: Theme.dim; font.pixelSize: 13 }
                              Label { width: parent.width - 120; text: modelData[1]; wrapMode: Text.WrapAnywhere; elide: Text.ElideNone; font.pixelSize: 13 } } } } }
            Menu { id: menu }
        }
    }
}
