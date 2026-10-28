// Settings › Background: the layers on the pegboard (ROADMAP 7A.07, 7A.08), drawn by bin/latte-wall.
// A picture, a film, a slideshow or a colour dragged from the library onto the pegboard is a layer; its handles make
// it larger, across screens too, and each screen shows what lies on its place on top. The right button brings a
// layer forward, sends it back or takes it off. A scheme is the whole pegboard kept under a name. The library is
// laid out as Windows lays out its background: the recent ones, and a button that opens the system's own chooser.
//   Wallpapers { open: …; overlay: …; menu: … }
import QtQuick
import QtQuick.Dialogs
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import "../common"

Column {
    id: page
    property bool open: false                  // the page is shown: what it shows is asked anew
    property Item overlay                      // over the whole window: what is carried, and the menus
    property var menu
    spacing: 22
    onOpenChanged: if (open) ask()

    component Ask: Process {
        id: r
        property var data: null
        property string buf: ""
        function ask(args) { running = false; command = args; running = true }
        stdout: StdioCollector { onStreamFinished: r.buf = this.text }
        onExited: { try { data = JSON.parse(buf) } catch (e) {} }
    }
    Ask { id: wall }
    Ask { id: pictures }
    Ask { id: online }
    Process { id: sender; onExited: wall.ask(["latte-wall", "state"]) }
    Process { id: doer; onExited: page.ask() }
    property string fetching: ""               // the address being fetched from the internet
    Process { id: fetcher; property var then: null
              stdout: StdioCollector { onStreamFinished: { const path = this.text.trim(), f = fetcher.then; fetcher.then = null; page.fetching = ""; if (path !== "" && f) f(path) } } }
    function ask() { wall.ask(["latte-wall", "state"]); pictures.ask(["latte-settings", "wallpapers"]) }
    function act(args) { doer.running = false; doer.command = args; doer.running = true }
    // latte-wall is busy cutting a film for its screens: it is asked again till it is done
    Timer { interval: 3000; repeat: true; running: page.open && page.st !== null && page.st.cutting && !sender.running; onTriggered: wall.ask(["latte-wall", "state"]) }

    // ── the layers ──────────────────────────────────────────────────────────────────────────────────────────
    readonly property var st: wall.data
    onStChanged: take()
    readonly property var screens: st ? st.screens : []
    property var layers: []                    // bottom first, as latte-wall keeps them
    property int rev: 0                        // a layer changed in place: what shows it looks again
    property int sel: -1
    property bool busy: false                  // a layer is being moved: what latte-wall says meanwhile waits
    function take() { if (!st || busy) return; layers = st.layers; if (sel >= layers.length) sel = -1; rev++ }
    function send() { sender.running = false; sender.command = ["latte-wall", "layers", JSON.stringify(layers)]; sender.running = true }
    function base(p) { return String(p || "").replace(/\/+$/, "").split("/").pop() }
    function nameOf(l) { return l.name || (l.kind === "color" ? l.color : base(l.path || l.folder)) }
    function kindOf(l) { return { picture: I18n.tr("picture"), film: I18n.tr("film"), slideshow: I18n.tr("slideshow"), color: I18n.tr("colour") }[l.kind] || "" }
    function look(l) {                         // what a layer is shown by on the pegboard
        if (!l) return ""
        if (l.kind === "picture") return "file://" + l.path
        if (l.kind === "film") return st && st.thumbs[l.path] ? "file://" + st.thumbs[l.path] : ""
        if (l.kind === "slideshow") { const a = st ? st.albums.find(a => a.folder === l.folder) : null; return a && a.pictures.length ? "file://" + a.pictures[0] : "" }
        return ""
    }
    function over(l, m) { return Math.max(0, Math.min(l.x + l.w, m.x + m.w) - Math.max(l.x, m.x)) * Math.max(0, Math.min(l.y + l.h, m.y + m.h) - Math.max(l.y, m.y)) / (m.w * m.h) }
    function topAt(p) { for (let i = layers.length - 1; i >= 0; i--) { const l = layers[i]; if (p.x >= l.x && p.x <= l.x + l.w && p.y >= l.y && p.y <= l.y + l.h) return i } return -1 }
    function onTop(i, m) { for (let j = layers.length - 1; j >= 0; j--) if (over(layers[j], m) > 0) return j === i; return false }
    // an edge near a screen's edge sticks to it
    function edge(v, axis) { let best = v, d = 10 / board.k; for (const m of screens) for (const e of axis === "x" ? [m.x, m.x + m.w] : [m.y, m.y + m.h]) if (Math.abs(e - v) < d) { d = Math.abs(e - v); best = e } return best }
    function slide(v, len, axis) { const a = edge(v, axis), b = edge(v + len, axis) - len; return Math.abs(a - v) <= Math.abs(b - v) ? a : b }
    function resize(was, h, p) {
        const l = layers[sel], corner = h[0] !== 0.5 && h[1] !== 0.5, keep = was.kind === "picture" || was.kind === "film"
        let x = was.x, y = was.y, w = was.w, hh = was.h
        if (h[0] === 0) { x = edge(p.x, "x"); w = was.x + was.w - x } else if (h[0] === 1) w = edge(p.x, "x") - was.x
        if (h[1] === 0) { y = edge(p.y, "y"); hh = was.y + was.h - y } else if (h[1] === 1) hh = edge(p.y, "y") - was.y
        if (keep && corner) {                  // a corner keeps the picture's proportions; an edge stretches it
            const a = was.w / was.h
            if (w / hh > a) { const nh = w / a; if (h[1] === 0) y = was.y + was.h - nh; hh = nh } else { const nw = hh * a; if (h[0] === 0) x = was.x + was.w - nw; w = nw }
        }
        if (w < 100 || hh < 60) return
        l.x = x; l.y = y; l.w = w; l.h = hh; rev++
    }
    function move(i, by) { const ls = layers.slice(), l = ls.splice(i, 1)[0]; ls.splice(i + by, 0, l); layers = ls; sel = i + by; send() }
    function remove(i) { const ls = layers.slice(); ls.splice(i, 1); layers = ls; sel = -1; send() }
    function layerMenu(i, item, x, y) {
        const p = item.mapToItem(overlay, x, y)
        menu.open(p.x, p.y, [{ text: I18n.tr("Bring forward"), icon: "chevron-up", enabled: i < layers.length - 1, run: () => page.move(i, 1) },
                             { text: I18n.tr("Send backward"), icon: "chevron-down", enabled: i > 0, run: () => page.move(i, -1) }, { line: true },
                             { text: I18n.tr("Remove from the pegboard"), icon: "trash", danger: true, run: () => page.remove(i) }])
    }
    // the whole of the screens a layer lies on, filled by it
    function across(i) {
        const l = layers[i], ms = screens.filter(m => over(l, m) > 0)
        if (!ms.length) return
        const x0 = Math.min(...ms.map(m => m.x)), x1 = Math.max(...ms.map(m => m.x + m.w)), y0 = Math.min(...ms.map(m => m.y)), y1 = Math.max(...ms.map(m => m.y + m.h))
        if (l.kind === "picture" || l.kind === "film") { const a = l.w / l.h, w = Math.max(x1 - x0, (y1 - y0) * a); Object.assign(l, { w: w, h: w / a, x: x0 + (x1 - x0 - w) / 2, y: y0 + (y1 - y0 - w / a) / 2 }) }
        else Object.assign(l, { x: x0, y: y0, w: x1 - x0, h: y1 - y0 })
        rev++; send()
    }

    // ── what the library holds, and how it comes onto the pegboard ─────────────────────────────────────────
    property string tab: "pictures"
    readonly property var hidden: st ? st.hidden : []
    function mine(films) { return (pictures.data || []).filter(w => w.live === films && !hidden.includes(w.path)).map(w => ({ kind: films ? "film" : "picture", path: w.path, thumb: films ? "" : w.path, name: base(w.path) })) }
    readonly property var albums: st ? st.albums.map(a => ({ kind: "slideshow", folder: a.folder, name: a.name, count: a.count, thumb: a.pictures[0] || "" })) : []
    // the colours Windows offers for its background, in its order
    readonly property var colours: ["#ff8c00", "#e81123", "#d13438", "#c30052", "#bf0077", "#9a0089", "#881798", "#744da9", "#10893e", "#107c10", "#018574", "#2d7d9a",
                                    "#0063b1", "#6b69d6", "#8e8cd8", "#8764b8", "#038387", "#486860", "#525e54", "#7e735f", "#4c4a48", "#515c6b", "#4a5459", "#000000"]
    readonly property var found: (online.data || []).slice(0, 30).map(o => ({ kind: "online", url: o.url, name: o.title, thumb: o.thumb, film: o.film }))
    function mainScreen() { return screens.find(m => m.x === 0 && m.y === 0) || screens[0] || null }
    function fetch(it, then) { fetcher.then = then; page.fetching = it.url; fetcher.running = false; fetcher.command = ["latte-walls", "get", it.url, it.name || "wallpaper"]; fetcher.running = true }
    function fetched(path) { return { kind: /\.(mp4|webm|mkv|mov)$/i.test(path) ? "film" : "picture", path: path } }
    function place(it, m, p) {
        if (it.kind === "online") { fetch(it, path => { page.place(page.fetched(path), m, p); pictures.ask(["latte-settings", "wallpapers"]) }); return }
        const l = Object.assign({ kind: it.kind }, m ? { x: m.x, y: m.y, w: m.w, h: m.h } : { x: p.x - 960, y: p.y - 540, w: 1920, h: 1080 })
        if (it.kind === "picture" || it.kind === "film") Object.assign(l, { path: it.path, lay: true })
        else if (it.kind === "slideshow") Object.assign(l, { folder: it.folder, minutes: 10, shuffle: true })
        else l.color = it.color
        layers = layers.concat([l]); sel = layers.length - 1; send()
    }
    // a press instead of a drag, as on Windows: into the chosen layer when it is of the same kind, else onto the main screen
    function use(it) {
        if (it.kind === "online") { fetch(it, path => { page.use(page.fetched(path)); pictures.ask(["latte-settings", "wallpapers"]) }); return }
        const l = sel >= 0 ? layers[sel] : null, still = k => k === "picture" || k === "film"
        if (l && (l.kind === it.kind || (still(l.kind) && still(it.kind)))) {
            if (still(it.kind)) Object.assign(l, { kind: it.kind, path: it.path, lay: true, res: undefined, name: undefined })
            else if (it.kind === "slideshow") l.folder = it.folder
            else l.color = it.color
            layers = layers.slice(); send(); return
        }
        place(it, mainScreen(), null)
    }
    function itemMenu(it, item, x, y) {
        const p = item.mapToItem(overlay, x, y), file = it.path || it.folder || ""
        menu.open(p.x, p.y, [{ text: I18n.tr("Remove from the list"), icon: "x", enabled: file !== "", run: () => page.act(["latte-wall", "forget", file]) },
                             { text: I18n.tr("Duplicate"), icon: "copy", enabled: it.kind === "picture" || it.kind === "film", run: () => page.act(["latte-wall", "duplicate", file]) },
                             { text: I18n.tr("Open file location"), icon: "folder", enabled: file !== "", run: () => Quickshell.execDetached(["latte-app", "files", it.folder || file.replace(/\/[^/]*$/, "")]) },
                             { text: I18n.tr("Copy"), icon: "clipboard", run: () => Quickshell.execDetached(it.kind === "color" || it.kind === "online" ? ["sh", "-c", "printf %s \"$1\" | wl-copy", "sh", it.color || it.url] : ["latte-wall", "copy", file]) }])
    }
    // carried with the mouse from the library: a picture of it under the pointer, the screen below lit
    property var hover: null
    function carry(item, x, y, it) {
        const p = item.mapToItem(overlay, x, y)
        ghost.it = it; ghost.x = p.x - ghost.width / 2; ghost.y = p.y - ghost.height / 2; ghost.visible = true
        hover = board.inside(item, x, y) ? (board.screenAt(board.at(item, x, y)) || "board") : null
    }
    function putDown(item, x, y, it) {
        ghost.visible = false; hover = null
        if (!board.inside(item, x, y)) return
        const p = board.at(item, x, y)
        place(it, board.screenAt(p), p)
    }
    Item { id: ghost; parent: page.overlay; z: 2000; visible: false; width: 128; height: 72
        property var it: null
        ClippingRectangle { anchors.fill: parent; radius: 10; opacity: 0.9; color: ghost.it && ghost.it.kind === "color" ? ghost.it.color : Theme.raised
            Image { anchors.fill: parent; source: ghost.it && ghost.it.thumb ? (/^https?:/.test(ghost.it.thumb) ? ghost.it.thumb : "file://" + ghost.it.thumb) : ""; fillMode: Image.PreserveAspectCrop; sourceSize.width: 260 }
            Glyph { anchors.centerIn: parent; visible: ghost.it !== null && (ghost.it.kind === "film" || ghost.it.film === true); name: "player-play"; font.pixelSize: 26; color: "white" } } }

    // ── the schemes ─────────────────────────────────────────────────────────────────────────────────────────
    readonly property var schemes: st ? st.schemes : []
    property bool naming: false
    function keepSchemes(list) { act(["latte-wall", "schemes", JSON.stringify(list)]) }
    function schemeMenu(i, item, x, y) {
        const p = item.mapToItem(overlay, x, y), c = schemes[i]
        menu.open(p.x, p.y, [{ text: I18n.tr("Remove from the list"), icon: "x", run: () => page.keepSchemes(page.schemes.filter((s, j) => j !== i)) },
                             { text: I18n.tr("Duplicate"), icon: "copy", run: () => { const l = page.schemes.slice(); l.splice(i + 1, 0, { name: I18n.tr("{name} (copy)", { name: c.name }), layers: c.layers }); page.keepSchemes(l) } },
                             { text: I18n.tr("Open file location"), icon: "folder", run: () => Quickshell.execDetached(["latte-app", "files", (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/latteos"]) },
                             { text: I18n.tr("Copy"), icon: "clipboard", run: () => Quickshell.execDetached(["latte-wall", "copy-scheme", String(i)]) }])
    }

    FileDialog { id: chooser; property string kind: "picture"; property int into: -1
                 nameFilters: kind === "film" ? [I18n.tr("Films") + " (*.mp4 *.webm *.mkv *.mov)"] : [I18n.tr("Pictures") + " (*.png *.jpg *.jpeg *.webp)"]
                 onAccepted: page.use(page.fetched(decodeURIComponent(String(selectedFile).replace(/^file:\/\//, "")))) }
    FolderDialog { id: folders; property int into: -1
                   onAccepted: { const f = decodeURIComponent(String(selectedFolder).replace(/^file:\/\//, ""))
                                 if (into >= 0 && page.layers[into]) { page.layers[into].folder = f; page.layers = page.layers.slice(); page.send() }
                                 else page.place({ kind: "slideshow", folder: f }, page.mainScreen(), null) } }
    ColorDialog { id: colourer; property int into: -1
                  onAccepted: { const c = String(selectedColor).slice(0, 7)
                                if (into >= 0 && page.layers[into]) { page.layers[into].color = c; page.layers = page.layers.slice(); page.send() } else page.use({ kind: "color", color: c }) } }

    // ── what the page is built of ──────────────────────────────────────────────────────────────────────────
    component Look: Item {                     // a layer as it looks: its picture, or its colour
        id: lk
        property var shows: null
        property string src: ""
        Rectangle { anchors.fill: parent; visible: lk.shows !== null && lk.shows.kind === "color"; color: lk.shows && lk.shows.color ? lk.shows.color : "black" }
        Image { anchors.fill: parent; visible: lk.shows !== null && lk.shows.kind !== "color"; source: lk.src; asynchronous: true; sourceSize.width: 1280
                fillMode: lk.shows && lk.shows.kind === "slideshow" ? Image.PreserveAspectCrop : Image.Stretch }
        Glyph { anchors.centerIn: parent; visible: lk.shows !== null && lk.shows.kind !== "color" && lk.src === "" && lk.width > 40; name: lk.shows && lk.shows.kind === "slideshow" ? "slideshow" : "movie"; font.pixelSize: 22; color: Theme.dim }
    }
    component Screens: Repeater {              // the screens on a board, each showing what lies on its place
        id: sr
        property Pegboard board
        property var layers: []
        property int rev: 0
        property bool big: true
        model: board ? board.screens : []
        ClippingRectangle { id: scr; required property var modelData; required property int index
            readonly property real inset: sr.big ? 2 : 1
            x: sr.board.px(modelData.x) + inset; y: sr.board.py(modelData.y) + inset; width: modelData.w * sr.board.k - 2 * inset; height: modelData.h * sr.board.k - 2 * inset
            radius: sr.big ? 10 : 3; color: "black"
            Repeater { model: sr.layers.length
                Look { required property int index; readonly property var l: (sr.rev, sr.layers[index]); shows: l; src: page.look(l)
                       x: sr.board.px(l.x) - scr.x; y: sr.board.py(l.y) - scr.y; width: l.w * sr.board.k; height: l.h * sr.board.k } }
            Rectangle { visible: sr.big; anchors.fill: parent; radius: 10; color: "transparent"; border.width: 2
                        border.color: page.hover === scr.modelData || (page.sel >= 0 && page.layers[page.sel] && page.over(page.layers[page.sel], scr.modelData) > 0) ? Theme.gold : Theme.line }
            Rectangle { visible: sr.big; x: 6; y: 6; width: tag.implicitWidth + 14; height: 20; radius: 10; color: Qt.rgba(0, 0, 0, 0.55)
                        Label { id: tag; anchors.centerIn: parent; text: (scr.index + 1) + " · " + scr.modelData.name; color: "white"; font.pixelSize: 11; font.weight: 700 } } }
    }
    component Thumb: ClippingRectangle {       // one in the library: dragged onto the pegboard, or pressed
        id: t
        property var it: ({})
        width: it.kind === "color" ? 44 : 120; height: it.kind === "color" ? 44 : 76; radius: it.kind === "color" ? 6 : 10
        color: it.kind === "color" ? it.color : Theme.raised
        border.width: page.fetching !== "" && page.fetching === it.url ? 2 : 0; border.color: Theme.gold
        Image { anchors.fill: parent; visible: t.it.kind !== "color"; source: t.it.thumb ? (/^https?:/.test(t.it.thumb) ? t.it.thumb : "file://" + t.it.thumb) : ""; fillMode: Image.PreserveAspectCrop; asynchronous: true; sourceSize.width: 260 }
        Glyph { anchors.centerIn: parent; visible: t.it.kind === "film" || t.it.film === true || (t.it.kind === "slideshow" && !t.it.thumb); name: t.it.kind === "slideshow" ? "folder" : "player-play"; font.pixelSize: 24; color: "white" }
        Rectangle { visible: t.it.kind !== "color"; anchors.bottom: parent.bottom; width: parent.width; height: 22; color: Qt.rgba(0, 0, 0, 0.55)
            Label { x: 7; width: parent.width - 14; text: t.it.kind === "slideshow" ? t.it.name + "  ·  " + t.it.count : (t.it.name || ""); color: "white"; font.pixelSize: 11; elide: Text.ElideMiddle; anchors.verticalCenter: parent.verticalCenter } }
        Waiting { anchors.centerIn: parent; visible: page.fetching !== "" && page.fetching === t.it.url }
        MouseArea { anchors.fill: parent; acceptedButtons: Qt.LeftButton | Qt.RightButton; preventStealing: true; cursorShape: carrying ? Qt.ClosedHandCursor : Qt.PointingHandCursor
            property point from
            property bool carrying: false
            onPressed: e => { carrying = false; from = Qt.point(e.x, e.y); if (e.button === Qt.RightButton) page.itemMenu(t.it, t, e.x, e.y) }
            onPositionChanged: e => { if (!(pressedButtons & Qt.LeftButton)) return
                                      if (!carrying && Math.abs(e.x - from.x) + Math.abs(e.y - from.y) < 6) return
                                      carrying = true; page.carry(t, e.x, e.y, t.it) }
            onReleased: e => { if (e.button !== Qt.LeftButton) return; if (carrying) page.putDown(t, e.x, e.y, t.it); else page.use(t.it); carrying = false } }
    }
    component WinRow: Item {                   // a line of the library, as Windows has them: what it does, and its button
        property string text
        property string button
        signal pressed()
        width: parent.width; height: 50
        Rectangle { width: parent.width; height: 1; color: Theme.line }
        Label { text: parent.text; anchors.verticalCenter: parent.verticalCenter }
        Pill { text: parent.button; implicitHeight: 32; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; onPressed: parent.pressed() }
    }
    component Sub: Label { font.weight: 600; visible: text !== "" }
    component Choose: Row {                    // a value of the chosen layer, chosen from a menu as from Windows's drop-down
        id: ch
        property string text
        property var options: []               // [{ name, value }]
        property var value
        signal picked(var value)
        width: parent.width; spacing: 8
        Label { width: parent.width - pick.width - 8; text: ch.text; wrapMode: Text.WordWrap; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
        Pill { id: pick; implicitHeight: 32; icon: "chevron-down"; text: { const o = ch.options.find(o => o.value === ch.value); return o ? I18n.tr(o.name) : "" }
               onPressed: { const p = pick.mapToItem(page.overlay, 0, pick.height + 4)
                            page.menu.open(p.x, p.y, ch.options.map(o => ({ text: I18n.tr(o.name), checked: o.value === ch.value, run: () => ch.picked(o.value) }))) } }
    }

    // ── the page ───────────────────────────────────────────────────────────────────────────────────────────
    Label { width: page.width; color: Theme.dim; font.pixelSize: 13; wrapMode: Text.WordWrap
            text: I18n.tr("Drag a picture, a film, a slideshow or a colour from the library onto the pegboard: it becomes a layer, which its handles make larger, across screens too. Each screen shows what lies on its place on top; the right button brings a layer forward or sends it back.") }
    Row { spacing: 18
        Pegboard { id: board; width: page.width - 268; height: 260; screens: page.screens; focus: true
            Keys.onPressed: e => {
                if (page.sel < 0) return
                if (e.key === Qt.Key_Delete) { page.remove(page.sel); e.accepted = true }
                else if ((e.modifiers & Qt.ControlModifier) && e.key === Qt.Key_BracketRight && page.sel < page.layers.length - 1) { page.move(page.sel, 1); e.accepted = true }
                else if ((e.modifiers & Qt.ControlModifier) && e.key === Qt.Key_BracketLeft && page.sel > 0) { page.move(page.sel, -1); e.accepted = true } }
            Rectangle { anchors.fill: parent; radius: 16; color: "transparent"; border.width: 2; border.color: Theme.gold; visible: page.hover === "board"; z: 4 }
            // what lies beyond the screens, faint
            Repeater { model: page.layers.length
                Look { required property int index; readonly property var l: (page.rev, page.layers[index]); shows: l; src: page.look(l); opacity: 0.3
                       x: board.px(l.x); y: board.py(l.y); width: l.w * board.k; height: l.h * board.k } }
            Screens { board: board; layers: page.layers; rev: page.rev }
            // a press picks the layer on top there and moves it; the right button gives its menu
            MouseArea { id: hand; anchors.fill: parent; z: 2; acceptedButtons: Qt.LeftButton | Qt.RightButton; preventStealing: true
                property point from
                property var was: null
                property bool moved: false
                onPressed: e => {
                    board.forceActiveFocus()
                    const p = board.at(hand, e.x, e.y), i = page.topAt(p)
                    page.sel = i
                    if (i < 0) return
                    if (e.button === Qt.RightButton) { page.layerMenu(i, hand, e.x, e.y); return }
                    from = p; was = Object.assign({}, page.layers[i]); moved = false; page.busy = true }
                onPositionChanged: e => {
                    if (!was || page.sel < 0) return
                    const p = board.at(hand, e.x, e.y)
                    if (!moved && Math.abs(p.x - from.x) * board.k + Math.abs(p.y - from.y) * board.k < 4) return
                    moved = true
                    const l = page.layers[page.sel]
                    l.x = page.slide(was.x + p.x - from.x, l.w, "x"); l.y = page.slide(was.y + p.y - from.y, l.h, "y"); page.rev++ }
                onReleased: { page.busy = false; if (was && moved) page.send(); was = null } }
            // the chosen layer: its frame, and the handles that size it
            Item { id: frame; z: 3
                readonly property var l: (page.rev, page.sel >= 0 ? page.layers[page.sel] : null)
                visible: l !== null && l !== undefined
                x: l ? board.px(l.x) : 0; y: l ? board.py(l.y) : 0; width: l ? l.w * board.k : 0; height: l ? l.h * board.k : 0
                Rectangle { anchors.fill: parent; color: "transparent"; border.width: 2; border.color: Theme.gold }
                Repeater { model: [[0, 0], [0.5, 0], [1, 0], [1, 0.5], [1, 1], [0.5, 1], [0, 1], [0, 0.5]]
                    Rectangle { id: hd; required property var modelData; width: 12; height: 12; radius: 3; color: Theme.gold; border.width: 2; border.color: Theme.inkOnGold
                        x: modelData[0] * frame.width - 6; y: modelData[1] * frame.height - 6
                        MouseArea { id: hm; anchors.fill: parent; anchors.margins: -4; preventStealing: true
                            cursorShape: hd.modelData[0] === 0.5 ? Qt.SizeVerCursor : hd.modelData[1] === 0.5 ? Qt.SizeHorCursor : hd.modelData[0] === hd.modelData[1] ? Qt.SizeFDiagCursor : Qt.SizeBDiagCursor
                            property var was: null
                            onPressed: { was = Object.assign({}, frame.l); page.busy = true }
                            onPositionChanged: e => { if (was) page.resize(was, hd.modelData, board.at(hm, e.x, e.y)) }
                            onReleased: { page.busy = false; if (was) page.send(); was = null } } } } } }
        // the layers, the top one first, as Photoshop lists them
        Rectangle { width: 250; height: board.height; radius: 16; color: Theme.card; border.width: 1; border.color: Theme.line
            Label { x: 14; y: 12; text: I18n.tr("Layers"); font.weight: 700 }
            Label { x: 14; y: 40; width: parent.width - 28; visible: page.layers.length === 0; text: I18n.tr("The pegboard is empty. Drag something here from the library."); color: Theme.faint; font.pixelSize: 12; wrapMode: Text.WordWrap }
            Flickable { x: 8; y: 38; width: parent.width - 16; height: parent.height - 46; clip: true; contentHeight: list.height; boundsBehavior: Flickable.StopAtBounds
                Column { id: list; width: parent.width; spacing: 2
                    Repeater { model: page.layers.length
                        Rectangle { id: row; required property int index
                            readonly property int i: page.layers.length - 1 - index
                            readonly property var l: (page.rev, page.layers[i])
                            width: list.width; height: 42; radius: 10; color: page.sel === i ? Theme.raised : (rowHit.containsMouse ? Qt.rgba(Theme.raised.r, Theme.raised.g, Theme.raised.b, 0.5) : "transparent")
                            border.width: page.sel === i ? 1 : 0; border.color: Theme.gold
                            ClippingRectangle { x: 6; width: 44; height: 26; radius: 5; color: "black"; anchors.verticalCenter: parent.verticalCenter
                                Look { anchors.fill: parent; shows: row.l; src: page.look(row.l) } }
                            Column { x: 60; width: parent.width - 66; anchors.verticalCenter: parent.verticalCenter
                                Label { width: parent.width; text: row.l ? page.nameOf(row.l) : ""; font.pixelSize: 12; font.weight: 600; elide: Text.ElideMiddle }
                                Label { width: parent.width; color: Theme.dim; font.pixelSize: 11; elide: Text.ElideRight
                                        text: row.l ? page.kindOf(row.l) + "  ·  " + (page.screens.map((m, n) => page.over(row.l, m) > 0 ? n + 1 : 0).filter(n => n).join(", ") || I18n.tr("off the screens")) : "" } }
                            MouseArea { id: rowHit; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.LeftButton | Qt.RightButton; cursorShape: Qt.PointingHandCursor
                                onPressed: e => { page.sel = row.i; board.forceActiveFocus(); if (e.button === Qt.RightButton) page.layerMenu(row.i, rowHit, e.x, e.y) } } } } } } } }

    // the schemes: the whole pegboard kept under a name, and put back with a press
    Column { width: page.width; spacing: 10
        Item { width: parent.width; height: 36
            Label { text: I18n.tr("Schemes"); font.pixelSize: 18; font.weight: 700; anchors.verticalCenter: parent.verticalCenter }
            Row { anchors.right: parent.right; spacing: 8
                Pill { visible: !page.naming; icon: "plus"; text: I18n.tr("Save scheme…"); enabled: page.layers.length > 0; opacity: enabled ? 1 : 0.5
                       onPressed: { page.naming = true; schemeName.text = I18n.tr("My layout {n}", { n: page.schemes.length + 1 }) } }
                Field { id: schemeName; visible: page.naming; width: 220; icon: "pencil"; hint: I18n.tr("Name of the scheme")
                        onAccepted: saveScheme.pressed() }
                Pill { id: saveScheme; visible: page.naming; strong: true; text: I18n.tr("Save")
                       onPressed: { page.keepSchemes(page.schemes.concat([{ name: schemeName.text.trim() || I18n.tr("Scheme"), layers: page.layers }])); page.naming = false } }
                Pill { visible: page.naming; text: I18n.tr("Cancel"); onPressed: page.naming = false } } }
        Label { visible: page.schemes.length === 0; width: parent.width; color: Theme.faint; font.pixelSize: 13; wrapMode: Text.WordWrap
                text: I18n.tr("No scheme yet. Lay the screens out as you like and keep it with Save scheme.") }
        Flow { width: parent.width; spacing: 12
            Repeater { model: page.schemes
                Rectangle { id: card; required property var modelData; required property int index
                    width: 180; height: 112; radius: 14; color: Theme.card; border.width: 1; border.color: cardHit.containsMouse ? Theme.gold : Theme.line
                    Pegboard { id: mini; x: 6; y: 6; width: parent.width - 12; height: 62; base: 62; room: 1.08; still: true; screens: page.screens
                        Screens { board: mini; layers: card.modelData.layers; big: false } }
                    Label { x: 12; y: 74; width: parent.width - 24; text: card.modelData.name; font.pixelSize: 13; font.weight: 600; elide: Text.ElideRight }
                    Label { x: 12; y: 92; text: I18n.tr("{n} layers", { n: card.modelData.layers.length }); color: Theme.dim; font.pixelSize: 11 }
                    MouseArea { id: cardHit; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.LeftButton | Qt.RightButton; cursorShape: Qt.PointingHandCursor
                        onClicked: e => { if (e.button === Qt.RightButton) page.schemeMenu(card.index, cardHit, e.x, e.y)
                                          else { page.layers = JSON.parse(JSON.stringify(card.modelData.layers)); page.sel = -1; page.send() } } } } } } }

    Row { spacing: 18
        // the library
        Rectangle { width: page.width - 308; height: lib.implicitHeight + 28; radius: 16; color: Theme.card; border.width: 1; border.color: Theme.line
            Column { id: lib; x: 14; y: 14; width: parent.width - 28; spacing: 12
                Label { text: I18n.tr("Library"); font.weight: 700 }
                Flow { width: parent.width; spacing: 6
                    Repeater { model: [{ id: "pictures", name: QT_TR_NOOP("My pictures") }, { id: "films", name: QT_TR_NOOP("Films") }, { id: "slideshows", name: QT_TR_NOOP("Slideshows") },
                                       { id: "colours", name: QT_TR_NOOP("Colour") }, { id: "wallhaven", name: "Wallhaven" }, { id: "motionbgs", name: "MotionBGS" }, { id: "bing", name: "Bing" },
                                       { id: "lens", name: QT_TR_NOOP("Describe it") }]
                        Pill { required property var modelData; implicitHeight: 30; text: I18n.tr(modelData.name); strong: page.tab === modelData.id
                               onPressed: { page.tab = modelData.id; if (["wallhaven", "motionbgs", "bing"].includes(modelData.id)) { online.data = null; online.ask(["latte-walls", modelData.id]) } } } } }
                // my pictures, my films: the recent ones, and the system's own chooser
                Sub { text: page.tab === "pictures" ? I18n.tr("Recent pictures") : page.tab === "films" ? I18n.tr("Recent films") : page.tab === "slideshows" ? I18n.tr("Recent slideshows") : page.tab === "colours" ? I18n.tr("Choose your background colour") : "" }
                Flow { visible: ["pictures", "films", "slideshows"].includes(page.tab); width: parent.width; spacing: 10
                    Repeater { model: page.tab === "pictures" ? page.mine(false) : page.tab === "films" ? page.mine(true) : page.tab === "slideshows" ? page.albums : []
                        Thumb { required property var modelData; it: modelData } } }
                Label { visible: page.tab === "slideshows" && page.albums.length === 0; text: I18n.tr("No slideshow yet."); color: Theme.faint; font.pixelSize: 13 }
                Flow { visible: page.tab === "colours"; width: parent.width; spacing: 6
                    Repeater { model: page.tab === "colours" ? page.colours : []
                        Thumb { required property string modelData; it: ({ kind: "color", color: modelData }) } } }
                WinRow { visible: page.tab === "pictures"; text: I18n.tr("Choose a photo"); button: I18n.tr("Browse photos"); onPressed: { chooser.kind = "picture"; chooser.open() } }
                WinRow { visible: page.tab === "films"; text: I18n.tr("Choose a film"); button: I18n.tr("Browse films"); onPressed: { chooser.kind = "film"; chooser.open() } }
                WinRow { visible: page.tab === "slideshows"; text: I18n.tr("Choose an album of pictures for a slideshow"); button: I18n.tr("Browse"); onPressed: { folders.into = -1; folders.open() } }
                WinRow { visible: page.tab === "colours"; text: I18n.tr("Custom colours"); button: I18n.tr("Show colours"); onPressed: { colourer.into = -1; colourer.open() } }
                // from the internet: a press or a drag fetches one into your Pictures first
                Row { visible: ["wallhaven", "motionbgs"].includes(page.tab); spacing: 8; width: parent.width
                    Field { id: netField; width: parent.width - 100; hint: page.tab === "wallhaven" ? I18n.tr("Search wallhaven.cc or paste an address") : I18n.tr("Search motionbgs.com or paste an address")
                            onAccepted: netGo.pressed() }
                    Pill { id: netGo; strong: true; text: I18n.tr("Search")
                           onPressed: { const q = netField.text.trim()
                                        if (/^https?:\/\//.test(q)) page.use({ kind: "online", url: q, name: q.split("/").pop() })
                                        else { online.data = null; online.ask(["latte-walls", page.tab].concat(q.split(/\s+/).filter(w => w !== ""))) } } } }
                Label { visible: ["wallhaven", "motionbgs", "bing"].includes(page.tab); width: parent.width; color: Theme.dim; font.pixelSize: 12; wrapMode: Text.WordWrap
                        text: page.tab === "bing" ? I18n.tr("Bing's pictures of the last days. A press or a drag fetches one into your Pictures.") : I18n.tr("A press or a drag fetches one into your Pictures and puts it on.") }
                Label { visible: page.tab === "wallhaven" && page.sel >= 0 && page.layers[page.sel] !== undefined && page.screens.filter(m => page.over(page.layers[page.sel], m) > 0).length > 1
                        color: Theme.gold; font.pixelSize: 12; width: parent.width; wrapMode: Text.WordWrap
                        text: { const l = page.sel >= 0 ? page.layers[page.sel] : null; if (!l) return ""; const ms = page.screens.filter(m => page.over(l, m) > 0); if (!ms.length) return ""
                                return I18n.tr("For the chosen layer look for at least {w} × {h}, so that it is not grainy across the screens.", { w: Math.max(...ms.map(m => m.x + m.w)) - Math.min(...ms.map(m => m.x)), h: Math.max(...ms.map(m => m.y + m.h)) - Math.min(...ms.map(m => m.y)) }) } }
                Waiting { visible: ["wallhaven", "motionbgs", "bing"].includes(page.tab) && online.running }
                Flow { visible: ["wallhaven", "motionbgs", "bing"].includes(page.tab); width: parent.width; spacing: 10
                    Repeater { model: ["wallhaven", "motionbgs", "bing"].includes(page.tab) ? page.found : []
                        Thumb { required property var modelData; it: modelData } } }
                // looking for a wallpaper by what it shows: skwd-lens has no way in but skwd-wall's own window (ROADMAP 7A.09)
                Label { visible: page.tab === "lens"; width: parent.width; color: Theme.dim; font.pixelSize: 13; wrapMode: Text.WordWrap
                        text: I18n.tr("Looking through your pictures by what they show, and making a new one from a description, are coming.") } } }

        // the chosen layer
        Rectangle { width: 290; height: insp.implicitHeight + 28; radius: 16; color: Theme.card; border.width: 1; border.color: Theme.line
            Column { id: insp; x: 14; y: 14; width: parent.width - 28; spacing: 10
                readonly property var l: (page.rev, page.sel >= 0 ? page.layers[page.sel] || null : null)
                readonly property real grain: l && (l.kind === "picture" || l.kind === "film") && l.res ? l.w / l.res[0] : 0
                Label { text: insp.l ? I18n.tr("Layer") + "  ·  " + page.kindOf(insp.l) : I18n.tr("Nothing chosen"); color: Theme.dim; font.pixelSize: 12; font.weight: 700 }
                Label { visible: insp.l !== null; width: parent.width; text: insp.l ? page.nameOf(insp.l) : ""; font.pixelSize: 15; font.weight: 700; elide: Text.ElideMiddle }
                Label { visible: insp.l === null; width: parent.width; color: Theme.dim; font.pixelSize: 13; wrapMode: Text.WordWrap
                        text: I18n.tr("Press a layer on the pegboard or in the list of layers. A screen with no layer on it is black.") }
                Repeater { model: insp.l ? page.screens : []
                    Label { required property var modelData; required property int index
                            readonly property real part: page.over(insp.l, modelData)
                            readonly property bool first: page.onTop(page.sel, modelData)
                            visible: part > 0; width: insp.width; font.pixelSize: 12; wrapMode: Text.WordWrap; color: part < 0.999 || !first ? Theme.coffee : Theme.cream
                            text: I18n.tr("Screen {n}: {part}", { n: index + 1, part: part >= 0.999 ? I18n.tr("whole") : Math.round(part * 100) + " %" }) + (first ? "" : ", " + I18n.tr("a higher layer covers it")) } }
                Pill { visible: insp.l !== null; implicitHeight: 32; icon: "arrows-maximize"; text: I18n.tr("Exactly across these screens"); onPressed: page.across(page.sel) }
                Label { visible: insp.grain > 1.5; width: parent.width; color: Theme.coffee; font.pixelSize: 12; wrapMode: Text.WordWrap
                        text: insp.l && insp.l.res ? I18n.tr("The source has {w} × {h} pixels and this layer is {lw} × {lh}: {x}× larger. It will look grainy on the screens.", { w: insp.l.res[0], h: insp.l.res[1], lw: Math.round(insp.l.w), lh: Math.round(insp.l.h), x: insp.grain.toFixed(1) }) : "" }
                Label { visible: insp.l !== null && insp.l.kind === "film" && page.st !== null && page.st.cutting; width: parent.width; color: Theme.dim; font.pixelSize: 12; wrapMode: Text.WordWrap
                        text: I18n.tr("The film is being cut for each screen. Until then each shows it whole.") }
                // a slideshow: its album, how often, in which order (as Windows asks)
                Row { visible: insp.l !== null && insp.l.kind === "slideshow"; width: parent.width; spacing: 8
                    Glyph { name: "folder"; font.pixelSize: 18; color: Theme.gold; anchors.verticalCenter: parent.verticalCenter }
                    Label { width: parent.width - 26 - albumPick.width - 8; text: insp.l ? page.base(insp.l.folder) : ""; elide: Text.ElideMiddle; anchors.verticalCenter: parent.verticalCenter }
                    Pill { id: albumPick; implicitHeight: 32; text: I18n.tr("Browse"); onPressed: { folders.into = page.sel; folders.open() } } }
                Choose { visible: insp.l !== null && insp.l.kind === "slideshow"; text: I18n.tr("Change picture every"); value: insp.l ? insp.l.minutes : 10
                         options: [{ value: 1, name: QT_TR_NOOP("1 minute") }, { value: 10, name: QT_TR_NOOP("10 minutes") }, { value: 30, name: QT_TR_NOOP("30 minutes") },
                                   { value: 60, name: QT_TR_NOOP("1 hour") }, { value: 360, name: QT_TR_NOOP("6 hours") }, { value: 1440, name: QT_TR_NOOP("1 day") }]
                         onPicked: v => { page.layers[page.sel].minutes = v; page.rev++; page.send() } }
                Choose { visible: insp.l !== null && insp.l.kind === "slideshow"; text: I18n.tr("Shuffle the pictures"); value: insp.l ? insp.l.shuffle === true : true
                         options: [{ value: true, name: QT_TR_NOOP("On") }, { value: false, name: QT_TR_NOOP("Off") }]
                         onPicked: v => { page.layers[page.sel].shuffle = v; page.rev++; page.send() } }
                Pill { visible: insp.l !== null && insp.l.kind === "color"; implicitHeight: 32; icon: "palette"; text: I18n.tr("Show colours"); onPressed: { colourer.into = page.sel; colourer.open() } }
                // how a picture lies on a screen it does not match: swaybg's, where skwd-wall does not draw
                Choose { visible: insp.l !== null && page.st !== null && page.st.engine === "plain" && insp.l.kind === "slideshow"; text: I18n.tr("Choose a fit"); value: page.st ? page.st.fit : "fill"
                         options: [{ value: "fill", name: QT_TR_NOOP("Fill") }, { value: "fit", name: QT_TR_NOOP("Fit") }, { value: "stretch", name: QT_TR_NOOP("Stretch") }, { value: "center", name: QT_TR_NOOP("Centre") }, { value: "tile", name: QT_TR_NOOP("Tile") }]
                         onPicked: v => page.act(["latte-wall", "fit", v]) } } } }
}
