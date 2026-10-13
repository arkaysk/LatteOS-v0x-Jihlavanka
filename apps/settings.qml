// Settings: everything about the computer and the desktop that can be set, in one place, by areas, with a search.
// The areas and their pages are listed in settings/pages.json (LensGoo searches the same list: bin/latte-settings).
// A page that LatteOS does not have yet is listed all the same, and says where the thing is done meanwhile.
//   latte-app settings [PAGE]
//
// The side is a menu that unfolds: an area, and under it its pages. A dot says how far a page is: full when it
// works here, hollow when it is still to come. Typing in the header's field lists the pages that match.
import QtQuick
import QtQuick.Dialogs
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import "common"

ShellRoot {
    id: shell
    readonly property string share: Quickshell.env("LATTE_SHARE") || "/usr/share/latteos"
    readonly property string config: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/latteos"
    readonly property var words: (Quickshell.env("LATTE_APP_ARGS") || "").split("\n").filter(w => w !== "")

    // ── the areas and the pages ───────────────────────────────────────────────────────────────────────────
    property var areas: []
    FileView { path: shell.share + "/apps/settings/pages.json"; onLoaded: { try { shell.areas = JSON.parse(text()) } catch (e) {} if (shell.words[0]) shell.go(shell.words[0]) } }
    property string page: ""                   // "" is the front page
    property string unfolded: "look"           // the area whose pages show in the side
    property string asked: ""                  // what is searched for
    readonly property var all: { const l = []; for (const a of areas) for (const p of a.pages) l.push(Object.assign({ area: a }, p)); return l }
    readonly property var here: all.find(p => p.id === page) || null
    function go(id) { const p = all.find(q => q.id === id); if (p) { page = id; unfolded = p.area.id; asked = "" } }
    function plain(s) { return s.toLowerCase().normalize("NFD").replace(/[̀-ͯ]/g, "") }
    readonly property var found: {
        const need = plain(asked).split(/\s+/).filter(w => w !== "")
        if (need.length === 0) return []
        return all.filter(p => { const hay = plain([p.name, I18n.tr(p.name), p.area.name, I18n.tr(p.area.name), p.words || "", I18n.tr(p.words || "")].join(" ")); return need.every(w => hay.includes(w)) })
    }
    function elsewhere(p) { Quickshell.execDetached(["latte-app"].concat(p.elsewhere.split(" "))) }

    // ── what the pages read and write ─────────────────────────────────────────────────────────────────────
    component Word: FileView {                 // a choice kept as one word in a file of the user's
        property string name
        property string value: ""
        path: shell.config + "/" + name
        printErrors: false; watchChanges: true
        onFileChanged: reload()
        onLoaded: value = text().trim()
        function choose(word) { value = word; Quickshell.execDetached(["sh", "-c", "mkdir -p \"$1\" && printf '%s\\n' \"$3\" > \"$1/$2\"", "sh", shell.config, name, word]) }
    }
    Word { id: cup; name: "cup" }
    function cupOf(id) { return id === "wallpaper" ? (Theme.fromWallpaper || Theme.cups.espresso) : Theme.cups[id] }
    Word { id: glass; name: "glass" }
    Word { id: wallpaper; name: "wallpaper" }
    Word { id: icons; name: "desktop-icons" }
    Word { id: screensWord; name: "screens" }
    // what the Goo scene keeps for itself: it takes a change up as soon as its file is written
    FileView {
        id: goo
        property var kept: ({})
        path: (Quickshell.env("XDG_DATA_HOME") || (Quickshell.env("HOME") + "/.local/share")) + "/pleamar/goo/settings.json"
        printErrors: false; watchChanges: true
        onFileChanged: reload()
        onLoaded: { try { kept = JSON.parse(text()) } catch (e) { kept = {} } }
        function set(key, value) { const k = Object.assign({}, kept); k[key] = value; kept = k; setText(JSON.stringify(k)) }
    }
    component Run: Process {
        id: r
        property var data: null
        property string buf: ""
        function ask(args) { running = false; command = args; running = true }
        stdout: StdioCollector { onStreamFinished: r.buf = this.text }
        onExited: { try { data = JSON.parse(buf) } catch (e) {} }
    }
    // when the session locks and the screens go dark: seconds, 0 for never (system/libexec/latte-idle reads the file)
    FileView {
        id: idle
        property int lock: 600
        property int screen: 900
        path: shell.config + "/idle"; printErrors: false
        onLoaded: { const l = text().match(/^lock=(\d+)$/m), s = text().match(/^screen=(\d+)$/m); if (l) lock = parseInt(l[1]); if (s) screen = parseInt(s[1]) }
        function choose(l, s) {
            lock = l; screen = s
            Quickshell.execDetached(["sh", "-c", "mkdir -p \"$1\" && printf 'lock=%s\\nscreen=%s\\n' \"$2\" \"$3\" > \"$1/idle\" && systemctl --user restart latte-idle.service", "sh", shell.config, String(l), String(s)])
        }
    }
    readonly property var waits: [{ s: 60, name: QT_TR_NOOP("1 minute") }, { s: 300, name: QT_TR_NOOP("5 minutes") }, { s: 600, name: QT_TR_NOOP("10 minutes") }, { s: 900, name: QT_TR_NOOP("15 minutes") },
                                  { s: 1800, name: QT_TR_NOOP("30 minutes") }, { s: 3600, name: QT_TR_NOOP("1 hour") }, { s: 0, name: QT_TR_NOOP("Never") }]
    property string profile: ""
    Process { id: profiles; command: ["powerprofilesctl", "get"]; stdout: StdioCollector { onStreamFinished: shell.profile = this.text.trim() } }
    Process { id: setProfile; onExited: profiles.running = true }
    Run { id: sound }
    Run { id: opens }
    Run { id: region }
    Run { id: clock }
    Run { id: keys }
    Run { id: binds }
    // a bind as it is pressed: "Win + Shift + ←"
    readonly property var keyNames: ({ "SUPER_L": "", "left": "←", "right": "→", "up": "↑", "down": "↓", "equal": "+", "minus": "−", "Escape": "Esc", "mouse:272": QT_TR_NOOP("left button"), "mouse:273": QT_TR_NOOP("right button") })
    function pressed(b) {
        const key = keyNames[b.key] !== undefined ? I18n.tr(keyNames[b.key]) : b.key
        return [b.modmask & 64 ? "Win" : "", b.modmask & 4 ? "Ctrl" : "", b.modmask & 8 ? "Alt" : "", b.modmask & 1 ? "Shift" : "", key].filter(k => k !== "").join(" + ")
    }
    // what a page shows is asked for when it opens, and again after anything on it was changed
    readonly property var asks: ({ "sound": [[sound, ["latte-settings", "sound"]]], "defaults": [[opens, ["latte-settings", "defaults"]]], "language": [[region, ["latte-settings", "region"]]],
                                   "time": [[clock, ["latte-settings", "time"]]], "keyboard": [[keys, ["latte-settings", "keyboard"]], [binds, ["hyprctl", "binds", "-j"]]], "displays": [[screens, ["hyprctl", "monitors", "-j"]]],
                                   "storage": [[disks, ["latte-settings", "storage"]], [held, ["latte-settings", "sizes"]]], "ai": [[helpers, ["latte-ai", "providers", "all"]]],
                                   "me": [[who, ["latte-settings", "account"]], [pictures, ["latte-settings", "wallpapers"]]], "performance": [[machine, ["latte-devices", "list"]]], "loginscreen": [[logon, ["latte-settings", "loginscreen"]]] })
    function ask() { (asks[page] || []).forEach(a => a[0].ask(a[1])); force.reload(); crashed.reload(); if (page === "background") wall.ask(["latte-wall", "state"]) }
    Timer { id: later; interval: 900; onTriggered: shell.ask() }       // what was asked of the compositor takes a moment to be so

    // a file of the user's own, from anywhere: for the background ("wallpaper") or for the account's picture ("face")
    FileDialog { id: chooser; property string what: ""
                 nameFilters: what === "face" ? [I18n.tr("Pictures") + " (*.png *.jpg *.jpeg *.webp)"] : [I18n.tr("Pictures and films") + " (*.png *.jpg *.jpeg *.webp *.mp4 *.webm *.mkv *.mov)"]
                 onAccepted: { const path = decodeURIComponent(String(selectedFile).replace(/^file:\/\//, ""))
                               if (what === "face") shell.account("SetIconFile", path)
                               else shell.bgSet(["picture", path]) } }
    Run { id: disks }
    Run { id: held }
    Run { id: helpers }
    Run { id: who }
    Run { id: logon }
    Run { id: iconsets }
    Run { id: online }
    Run { id: wall }                           // what latte-wall says: the screens and what is on each
    readonly property var bg: wall.data
    property string bgTarget: "*"              // the screen a choice goes to, or * for every screen
    property string bgSource: "picture"
    property string showFolder: ""
    property int showMinutes: 10
    property bool showShuffle: false
    function bgSet(what) { order(["latte-wall", "set", bgTarget].concat(what)) }
    FolderDialog { id: folders; onAccepted: shell.showFolder = decodeURIComponent(String(selectedFolder).replace(/^file:\/\//, "")) }
    property string fetching: ""               // the one being fetched
    Process { id: fetcher; stdout: StdioCollector { onStreamFinished: { const path = this.text.trim(); shell.fetching = ""
        if (path !== "") { shell.bgSet(["picture", path]); pictures.ask(["latte-settings", "wallpapers"]) } } } }
    Word { id: tier; name: "tier" }
    // the password: the new one goes to latte-settings on its input, the present one is asked for by the system
    property string passSaid: ""
    Process { id: passer; command: ["latte-settings", "password"]; stdinEnabled: true
              property string fresh: ""
              onStarted: { write(fresh + "\n"); fresh = ""; stdinEnabled = false }
              stdout: StdioCollector { onStreamFinished: { let r = {}; try { r = JSON.parse(this.text) } catch (e) {}
                  shell.passSaid = r.ok ? I18n.tr("The password is changed.") : (r.error === "refused" ? I18n.tr("Not changed: the present password was not given.") : I18n.tr("Not changed.")) } } }
    Word { id: ai; name: "ai" }
    // whatever else in the system is AI hears of the switch: skwd-wall's search model (bin/latte-wall)
    Timer { id: aiLater; interval: 700; onTriggered: Quickshell.execDetached(["latte-wall", "ai"]) }
    // what latte-boot decided for this start, and whether the next one was asked to be SAFE
    FileView { id: decided; path: "/run/latteos/mode.toml"; printErrors: false
               property string mode: ""; property string renderer: ""; property string tier: ""; property string reason: ""
               onLoaded: { const get = k => (text().match(new RegExp("^" + k + " = \"(.*)\"$", "m")) || ["", ""])[1]; decided.mode = get("mode"); decided.renderer = get("renderer"); decided.tier = get("tier"); decided.reason = get("reason") } }
    // the report latte-session wrote when the desktop last crashed; the login screen shows its head
    FileView { id: crashed; path: "/var/lib/latteos/login/last-crash.log"; printErrors: false; property string said: ""
               onLoaded: said = text().trim(); onLoadFailed: said = ""
               function refresh() { reload() } }
    FileView { id: force; path: "/var/lib/latteos/force-safe"; printErrors: false; property bool there: false; onLoaded: there = true; onLoadFailed: there = false }
    readonly property var tiers: [{ id: "", name: QT_TR_NOOP("As the hardware says"), hint: "", icon: "sparkles" },
                                  { id: "full", name: QT_TR_NOOP("Everything"), hint: QT_TR_NOOP("blur, shadows, glow, a turning border"), icon: "flame" },
                                  { id: "standard", name: QT_TR_NOOP("Standard"), hint: QT_TR_NOOP("blur and shadows"), icon: "activity" },
                                  { id: "eco", name: QT_TR_NOOP("Thrifty"), hint: QT_TR_NOOP("no blur, quicker movement"), icon: "leaf" },
                                  { id: "minimal", name: QT_TR_NOOP("Bare"), hint: QT_TR_NOOP("nothing moves"), icon: "minus" }]
    readonly property var folderNames: ({ "DOCUMENTS": QT_TR_NOOP("Documents"), "DOWNLOAD": QT_TR_NOOP("Downloads"), "PICTURES": QT_TR_NOOP("Pictures"), "VIDEOS": QT_TR_NOOP("Videos"),
                                          "MUSIC": QT_TR_NOOP("Music"), "DESKTOP": QT_TR_NOOP("Desktop") })
    property bool emptying: false          // the trash is emptied on the second press: what was in it does not come back
    function bytes(b) { return b >= 1e9 ? Number(b / 1e9).toLocaleString(Qt.locale(), "f", 1) + " GB" : Math.round(b / 1e6) + " MB" }
    function account(what, value) { order(["busctl", "call", "org.freedesktop.Accounts", "/org/freedesktop/Accounts/User" + who.data.uid, "org.freedesktop.Accounts.User", what, "s", value]) }

    // ── the screens: a change is tried, and stays only when the user says the picture is fine ───────────
    Run { id: screens }
    property string screenAt: ""
    property var screenBefore: null
    property int screenWait: 0
    readonly property var screenList: (screens.data || []).slice().sort((a, b) => a.x - b.x)
    readonly property var screenHere: screenList.find(m => m.name === screenAt) || screenList[0] || null
    readonly property string screenMain: { const m = screenList.find(m => m.x === 0 && m.y === 0) || screenList[0]; return m ? m.name : "" }
    function wide(m) { return Math.round((m.transform % 2 ? m.height : m.width) / m.scale) }
    function tall(m) { return Math.round((m.transform % 2 ? m.width : m.height) / m.scale) }
    function asIs(m) { return { name: m.name, mode: m.width + "x" + m.height + "@" + m.refreshRate.toFixed(3), position: m.x + "x" + m.y, scale: m.scale, turn: m.transform } }
    // ponytail: side by side only, the main one at 0,0; screens above one another are for ~/.config/latteos/hyprland.lua
    function laid(list, main) {
        let x = 0
        const at = list.map(m => { const here = x; x += wide(m); return here })
        const zero = at[Math.max(0, list.findIndex(m => m.name === main))]
        return list.map((m, i) => Object.assign(asIs(m), { position: (at[i] - zero) + "x0" }))
    }
    function putScreens(shapes, keep) {
        order(["hyprctl", "eval", shapes.map(s => "latte.screen(" + [JSON.stringify(s.name), JSON.stringify(s.mode), JSON.stringify(s.position), s.scale, s.turn, keep].join(", ") + ")").join(" ")])
        later.restart()
    }
    function tryScreens(list, main) {
        if (!screenBefore) screenBefore = screenList.map(asIs)
        putScreens(laid(list, main), false); screenWait = 15
    }
    function changeScreen(name, what) { tryScreens(screenList.map(m => m.name === name ? Object.assign({}, m, what) : m), screenMain) }
    function moveScreen(name, by) {
        const list = screenList.slice(), i = list.findIndex(m => m.name === name), j = i + by
        if (i < 0 || j < 0 || j >= list.length) return
        const m = list[i]; list[i] = list[j]; list[j] = m
        tryScreens(list, screenMain)
    }
    function keepScreens() { putScreens(screenList.map(asIs), true); screenBefore = null; screenWait = 0 }
    function screensBack() { if (screenBefore) putScreens(screenBefore, false); screenBefore = null; screenWait = 0 }
    Timer { interval: 1000; repeat: true; running: shell.screenWait > 0; onTriggered: if (--shell.screenWait <= 0) shell.screensBack() }
    function modes(m) {                    // [{w, h, rates: [Hz…]}], the largest first
        const found = []
        for (const said of m.availableModes) {
            const p = /^(\d+)x(\d+)@([\d.]+)Hz$/.exec(said); if (!p) continue
            const w = parseInt(p[1]), h = parseInt(p[2]), hz = parseFloat(p[3])
            let size = found.find(s => s.w === w && s.h === h)
            if (!size) { size = { w: w, h: h, rates: [] }; found.push(size) }
            if (size.rates.indexOf(hz) < 0) size.rates.push(hz)
        }
        found.forEach(s => s.rates.sort((a, b) => b - a))
        return found.sort((a, b) => b.w * b.h - a.w * a.h)
    }
    Process { id: tell; onExited: shell.ask() }
    function order(args) { tell.running = false; tell.command = args; tell.running = true }
    Timer { interval: 2500; repeat: true; running: shell.page === "sound"; onTriggered: if (!tell.running) shell.ask() }
    property date now: new Date()
    Timer { interval: 1000; repeat: true; running: shell.page === "time"; triggeredOnStart: true; onTriggered: shell.now = new Date() }
    function localeName(id) { const l = region.data ? region.data.locales.find(x => x.id === id) : null; return l ? l.name + (l.place ? " · " + l.place : "") : id }
    function layoutName(id) { const l = keys.data ? keys.data.layouts.find(x => x.id === id) : null; return l ? l.name : id }
    readonly property var kindNames: ({ "browser": QT_TR_NOOP("Web browser"), "mail": QT_TR_NOOP("Mail"), "files": QT_TR_NOOP("Files and folders"), "images": QT_TR_NOOP("Pictures"),
                                        "video": QT_TR_NOOP("Video"), "music": QT_TR_NOOP("Music"), "text": QT_TR_NOOP("Text"), "pdf": "PDF" })
    readonly property var kindIcons: ({ "browser": "world", "mail": "file-text", "files": "folder", "images": "photo", "video": "player-play", "music": "music", "text": "file-text", "pdf": "file-text" })
    Run { id: coffees }
    Run { id: pictures }
    Run { id: machine }
    Process { id: pour; onExited: { Quickshell.execDetached(["latte-say", "emit coffee_changed"]); coffees.ask(["latte-login", "coffees"]) } }
    FileView { id: release; path: "/etc/os-release"; printErrors: false; property string pretty: ""
               onLoaded: pretty = (text().match(/^PRETTY_NAME="?([^"\n]*)/m) || ["", ""])[1] }
    onPageChanged: {
        if (page === "coffee") { coffees.ask(["latte-login", "coffees"]); iconsets.ask(["latte-settings", "icons"]) }
        if (page === "background") { pictures.ask(["latte-settings", "wallpapers"]); wall.ask(["latte-wall", "state"]) }
        if (page === "about") machine.ask(["latte-devices", "list"])
        emptying = false
        if (page === "power") profiles.running = true
        ask()
    }
    readonly property var coffeeNames: ({ "espresso": "Espresso", "ristretto": "Ristretto", "lungo": "Lungo", "americano": "Americano", "macchiato": "Macchiato", "cortado": "Cortado",
                                          "flatwhite": "Flat white", "cappuccino": "Cappuccino", "latte": "Latte", "white-coffee": QT_TR_NOOP("White coffee") })
    // the colour the goo has with that much water and milk in it, as the scene mixes it
    function mixed(a, b, t) { return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1) }
    function brew(water, milk) { return mixed(mixed(Qt.color("#1c0f09"), Qt.color("#4a2410"), water), Qt.color("#c9a47a"), milk * milk) }

    // ── what pages are built of ───────────────────────────────────────────────────────────────────────────
    component Part: Column {                   // a part of a page: a heading, a word about it, and what is set
        property string title
        property string note
        default property alias content: inside.data
        spacing: 10
        Label { text: title; font.pixelSize: 18; font.weight: 700 }
        Label { text: note; visible: text !== ""; color: Theme.dim; font.pixelSize: 13; width: parent.width; wrapMode: Text.WordWrap }
        Item { width: 1; height: 2 }
        Flow { id: inside; width: parent.width; spacing: 14 }
    }
    component Choice: Rectangle {              // one of several, with a picture of itself
        id: choice
        property string text
        property string hint
        property bool on: false
        default property alias picture: face.data
        signal pressed()
        width: 150; height: 150; radius: 20; color: Theme.card
        border.width: 2; border.color: on ? Theme.gold : (hit.containsMouse ? Theme.line : "transparent")
        scale: hit.pressed ? 0.97 : 1
        Behavior on scale { NumberAnimation { duration: 90 } }
        Item { id: face; x: 14; y: 14; width: parent.width - 28; height: parent.height - 66 }
        Label { x: 14; y: parent.height - 46; width: parent.width - 28; text: choice.text; font.weight: 700 }
        Label { x: 14; y: parent.height - 26; width: parent.width - 28; text: choice.hint; color: Theme.dim; font.pixelSize: 11 }
        Rectangle { visible: choice.on; width: 22; height: 22; radius: 11; color: Theme.gold; x: parent.width - 30; y: 8; Glyph { anchors.centerIn: parent; name: "check"; font.pixelSize: 13; color: Theme.inkOnGold } }
        MouseArea { id: hit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: choice.pressed() }
    }
    component Switch: Rectangle {              // yes or no, with what it is about beside it
        id: sw
        property string text
        property string hint
        property bool on: false
        signal pressed()
        width: parent.width; height: 64; radius: 16; color: Theme.card
        Column { x: 18; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 100; spacing: 3
            Label { text: sw.text; font.weight: 600; width: parent.width }
            Label { text: sw.hint; color: Theme.dim; font.pixelSize: 12; width: parent.width; visible: text !== "" } }
        Rectangle { width: 46; height: 26; radius: 13; color: sw.on ? Theme.gold : Theme.raised; anchors.right: parent.right; anchors.rightMargin: 18; anchors.verticalCenter: parent.verticalCenter
            Behavior on color { ColorAnimation { duration: 140 } }
            Rectangle { width: 20; height: 20; radius: 10; y: 3; x: sw.on ? 23 : 3; color: sw.on ? Theme.inkOnGold : Theme.dim; Behavior on x { NumberAnimation { duration: 140 } } } }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: sw.pressed() }
    }
    component Dot: Rectangle { property string status; width: 9; height: 9; radius: 5; color: status === "ready" ? Theme.gold : "transparent"; border.width: 1.5; border.color: status === "ready" ? Theme.gold : Theme.faint }
    component PageLine: Rectangle {            // a page, as the search and the front page list it
        id: pl
        property var what
        width: parent.width; height: 58; radius: 16; color: plHit.containsMouse ? Theme.raised : Theme.card
        Glyph { x: 18; name: pl.what.icon; font.pixelSize: 22; color: Theme.gold; anchors.verticalCenter: parent.verticalCenter }
        Column { x: 56; anchors.verticalCenter: parent.verticalCenter; spacing: 2
            Label { text: I18n.tr(pl.what.name); font.weight: 600 }
            Label { text: I18n.tr(pl.what.area.name); color: Theme.dim; font.pixelSize: 12 } }
        Dot { status: pl.what.status; anchors.right: parent.right; anchors.rightMargin: 20; anchors.verticalCenter: parent.verticalCenter }
        MouseArea { id: plHit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: shell.go(pl.what.id) }
    }

    AppWindow {
        id: win
        title: I18n.tr("Settings")
        heading: shell.asked !== "" ? I18n.tr("Results for “{what}”", { what: shell.asked }) : (shell.here ? I18n.tr(shell.here.name) : I18n.tr("Settings"))
        implicitWidth: 1200; implicitHeight: 780
        sideWidth: 270
        arrows: true; canGoBack: shell.page !== "" || shell.asked !== ""; onBack: { if (shell.asked !== "") { shell.asked = ""; searchText = "" } else shell.page = "" }
        searchHint: I18n.tr("Search settings…")
        onSearchTextChanged: shell.asked = searchText.trim()

        // ── the side: areas that unfold into their pages ──────────────────────────────────────────────────
        side: [
            Flickable { anchors.fill: parent; contentHeight: menu.height + 28; clip: true; boundsBehavior: Flickable.StopAtBounds
                Column { id: menu; x: 14; y: 14; spacing: 4; width: parent.width - 28
                    Row { x: 6; spacing: 10; height: 40
                        Glyph { name: "settings"; font.pixelSize: 24; color: Theme.gold; anchors.verticalCenter: parent.verticalCenter }
                        Label { text: I18n.tr("Settings"); font.pixelSize: 17; font.weight: 700; anchors.verticalCenter: parent.verticalCenter } }
                    Item { width: 1; height: 8 }
                    Nav { width: parent.width; text: I18n.tr("Home"); icon: "home-2"; on: shell.page === "" && shell.asked === ""; onPressed: { shell.page = ""; shell.asked = ""; win.searchText = "" } }
                    Repeater { model: shell.areas
                        Column { id: area; required property var modelData; width: parent.width; spacing: 2
                            readonly property bool open: shell.unfolded === modelData.id
                            Rectangle { width: parent.width; height: 40; radius: 12; color: areaHit.containsMouse ? Theme.card : "transparent"
                                Glyph { x: 14; name: area.modelData.icon; color: area.open ? Theme.gold : Theme.dim; anchors.verticalCenter: parent.verticalCenter }
                                Label { x: 44; text: I18n.tr(area.modelData.name).toUpperCase(); font.pixelSize: 12; font.weight: 700; font.letterSpacing: 0.6; color: area.open ? Theme.cream : Theme.dim; anchors.verticalCenter: parent.verticalCenter }
                                Glyph { name: "chevron-right"; font.pixelSize: 15; color: Theme.faint; anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter
                                        rotation: area.open ? 90 : 0; Behavior on rotation { NumberAnimation { duration: 160 } } }
                                MouseArea { id: areaHit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: shell.unfolded = area.open ? "" : area.modelData.id } }
                            Column { width: parent.width; spacing: 1; clip: true
                                height: area.open ? implicitHeight : 0; Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                Repeater { model: area.modelData.pages
                                    Rectangle { id: line; required property var modelData; width: parent.width; height: 34; radius: 10
                                        readonly property bool on: shell.page === modelData.id && shell.asked === ""
                                        color: on ? Theme.raised : (lineHit.containsMouse ? Theme.card : "transparent")
                                        Rectangle { width: 3; height: 16; radius: 2; color: Theme.gold; visible: line.on; anchors.verticalCenter: parent.verticalCenter }
                                        Label { x: 44; width: parent.width - 70; text: I18n.tr(line.modelData.name); font.pixelSize: 13; color: line.on ? Theme.cream : Theme.dim; anchors.verticalCenter: parent.verticalCenter }
                                        Dot { status: line.modelData.status; anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter }
                                        MouseArea { id: lineHit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: shell.go(line.modelData.id) } } } } } } } }
        ]

        // ── what was searched for ─────────────────────────────────────────────────────────────────────────
        Scroll {
            id: results
            visible: shell.asked !== ""
            Label { visible: shell.found.length === 0; text: I18n.tr("Nothing found"); color: Theme.dim; topPadding: 60 }
            Column { width: results.room; spacing: 8
                Repeater { model: shell.found; PageLine { required property var modelData; what: modelData } } }
        }

        // ── the front page ────────────────────────────────────────────────────────────────────────────────
        Scroll {
            id: front
            visible: shell.asked === "" && shell.page === ""
            Flow { width: front.room; spacing: 14
                Repeater { model: shell.areas
                    Rectangle { id: tile; required property var modelData
                        readonly property int each: Math.max(1, Math.floor(front.room / 260))
                        width: Math.floor((front.room - 14 * (each - 1)) / each); height: 124; radius: 20; color: tileHit.containsMouse ? Theme.raised : Theme.card
                        Behavior on color { ColorAnimation { duration: 140 } }
                        Rectangle { x: 18; y: 18; width: 44; height: 44; radius: 14; color: Theme.ground; Glyph { anchors.centerIn: parent; name: tile.modelData.icon; font.pixelSize: 24; color: Theme.gold } }
                        Label { x: 76; y: 18; text: I18n.tr(tile.modelData.name); font.pixelSize: 17; font.weight: 700 }
                        Label { x: 76; y: 42; width: parent.width - 92; color: Theme.dim; font.pixelSize: 12; wrapMode: Text.WordWrap; maximumLineCount: 4
                                text: tile.modelData.pages.map(p => I18n.tr(p.name)).join(" · ") }
                        MouseArea { id: tileHit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: { shell.unfolded = tile.modelData.id; shell.go((tile.modelData.pages.find(p => p.status === "ready") || tile.modelData.pages[0]).id) } } } } }
            Column { width: front.room; spacing: 8
                Label { text: I18n.tr("WHAT CAN BE SET HERE NOW"); color: Theme.faint; font.pixelSize: 11; font.weight: 700; font.letterSpacing: 0.8 }
                Repeater { model: shell.all.filter(p => p.status === "ready"); PageLine { required property var modelData; what: modelData } } }
        }

        // ── a page ────────────────────────────────────────────────────────────────────────────────────────
        Scroll {
            id: view
            visible: shell.asked === "" && shell.here !== null

            // coffee and cup: what the goo is made of, and what the windows are
            Part { visible: shell.page === "coffee"; width: view.room; title: I18n.tr("What coffee would you like?"); note: I18n.tr("The coffee is what the drops on the edge of the screen are made of: more water makes it clearer, more milk lighter.")
                Repeater { model: coffees.data ? coffees.data.all : []
                    Choice { id: kind; required property var modelData; width: 132; height: 142
                        text: I18n.tr(shell.coffeeNames[modelData[0]] || modelData[0]); on: coffees.data.chosen === modelData[0] || (coffees.data.chosen === "" && modelData[0] === "espresso")
                        onPressed: { pour.running = false; pour.command = ["latte-login", "coffee", modelData[0]]; pour.running = true }
                        // a cup seen from above
                        Rectangle { anchors.centerIn: parent; width: 70; height: 70; radius: 35; color: Theme.light ? "#fffaf1" : "#e9dcc8"
                            Rectangle { anchors.centerIn: parent; width: 56; height: 56; radius: 28; color: shell.brew(kind.modelData[1], kind.modelData[2]) } } } } }
            Part { visible: shell.page === "coffee"; width: view.room; title: I18n.tr("And in what cup?"); note: I18n.tr("The cup is what the windows are made of.")
                Repeater { model: [{ id: "espresso", name: QT_TR_NOOP("Espresso cup"), hint: QT_TR_NOOP("dark") }, { id: "mocha", name: QT_TR_NOOP("Mocha cup"), hint: QT_TR_NOOP("warm brown") },
                                   { id: "porcelain", name: QT_TR_NOOP("Porcelain"), hint: QT_TR_NOOP("light") }]
                           .concat(Theme.fromWallpaper ? [{ id: "wallpaper", name: QT_TR_NOOP("From the wallpaper"), hint: QT_TR_NOOP("its colours, each time it changes") }] : [])
                    Choice { required property var modelData; width: 190; text: I18n.tr(modelData.name); hint: I18n.tr(modelData.hint); on: Theme.cup === modelData.id; onPressed: { cup.choose(modelData.id); Theme.cup = modelData.id; Quickshell.execDetached(["hyprctl", "eval", "latte.cup(\"" + modelData.id + "\")"]) }
                        // a small window made of that cup
                        Rectangle { anchors.fill: parent; radius: 10; color: shell.cupOf(parent.parent.modelData.id).ground; border.width: 1; border.color: shell.cupOf(parent.parent.modelData.id).line
                            Rectangle { width: parent.width * 0.3; height: parent.height; radius: 10; color: shell.cupOf(parent.parent.parent.modelData.id).surface }
                            Rectangle { x: parent.width * 0.38; y: 12; width: parent.width * 0.5; height: 8; radius: 4; color: shell.cupOf(parent.parent.parent.modelData.id).cream }
                            Rectangle { x: parent.width * 0.38; y: 28; width: parent.width * 0.36; height: 6; radius: 3; color: shell.cupOf(parent.parent.parent.modelData.id).dim }
                            Rectangle { x: parent.width * 0.38; y: 46; width: 40; height: 16; radius: 8; color: shell.cupOf(parent.parent.parent.modelData.id).gold } } } } }
            Part { visible: shell.page === "coffee"; width: view.room; title: I18n.tr("Icons"); note: I18n.tr("What files, folders and apps are shown with: on the desktop, in LatteOS's apps and in apps that follow the system.")
                Repeater { model: iconsets.data ? iconsets.data.sets : []
                    Choice { id: set; required property var modelData; width: 200; text: modelData.name; on: iconsets.data.chosen === modelData.id
                             onPressed: { tell.running = false; tell.command = ["latte-settings", "icons", modelData.id]; tell.running = true }
                             Row { anchors.centerIn: parent; spacing: 6
                                   Repeater { model: [set.modelData.folder, set.modelData.file, set.modelData.trash]
                                              Image { required property string modelData; width: 48; height: 48; source: modelData === "" ? "" : "file://" + modelData; sourceSize.width: 96; sourceSize.height: 96; asynchronous: true } } } } } }
            Part { visible: shell.page === "coffee"; width: view.room; title: I18n.tr("Glass")
                Switch { text: I18n.tr("Coffee in glass"); hint: I18n.tr("The drops are glass with coffee in it. With the graphics card drawing by the processor they stay plain coffee.")
                         on: goo.kept.material === "glass" || Number(goo.kept.material) > 0.5; onPressed: goo.set("material", on ? 0 : 1) }
                Switch { text: I18n.tr("Windows of glass"); hint: I18n.tr("The windows are glass too, where the graphics card can: that is the cup's own look, apart from the drops.")
                         on: goo.kept.windows === "glass"; onPressed: goo.set("windows", on ? "solid" : "glass") } }

            // The background, as Windows lays it out and a little further: the screens on top (press one to choose
            // for it alone), then where the picture comes from, then the choice itself. bin/latte-wall does it.
            Item { visible: shell.page === "background"; width: view.room; height: 250
                readonly property var list: shell.bg ? shell.bg.screens : []
                readonly property real x0: list.length ? Math.min(...list.map(m => m.x)) : 0
                readonly property real y0: list.length ? Math.min(...list.map(m => m.y)) : 0
                readonly property real wide: list.length ? Math.max(...list.map(m => m.x + m.w)) - x0 : 1920
                readonly property real high: list.length ? Math.max(...list.map(m => m.y + m.h)) - y0 : 1080
                readonly property real k: Math.min(Math.min(view.room, 900) / wide, 230 / high)
                id: stage
                Repeater { model: stage.list
                    ClippingRectangle { id: scr; required property var modelData
                        readonly property string file: shell.bg ? (shell.bg.shown[modelData.name] || shell.bg.shown["*"] || "") : ""
                        readonly property bool film: /\.(mp4|webm|mkv|mov)$/i.test(file)
                        x: (modelData.x - stage.x0) * stage.k; y: (modelData.y - stage.y0) * stage.k; width: modelData.w * stage.k - 8; height: modelData.h * stage.k - 8
                        radius: 14; color: Theme.card; border.width: 3
                        border.color: shell.bgTarget === "*" || shell.bgTarget === modelData.name ? Theme.gold : Theme.line
                        Image { anchors.fill: parent; anchors.margins: 3; visible: !scr.film; source: scr.film || scr.file === "" ? "" : "file://" + scr.file; fillMode: Image.PreserveAspectCrop; asynchronous: true; sourceSize.width: 960; cache: false }
                        Glyph { anchors.centerIn: parent; visible: scr.film; name: "player-play"; font.pixelSize: 44; color: Theme.gold }
                        Rectangle { x: 10; y: 10; width: tag.implicitWidth + 16; height: 24; radius: 12; color: Qt.rgba(0, 0, 0, 0.55)
                                    Label { id: tag; anchors.centerIn: parent; text: scr.modelData.name; color: "white"; font.pixelSize: 12; font.weight: 700 } }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: shell.bgTarget = scr.modelData.name } } } }
            Row { visible: shell.page === "background"; spacing: 10
                Pill { icon: "copy"; text: I18n.tr("The same on every screen"); strong: shell.bgTarget === "*"; onPressed: shell.bgTarget = "*" }
                Repeater { model: shell.bg && shell.bg.screens.length > 1 ? shell.bg.screens : []
                    Pill { required property var modelData; icon: "device-desktop"; text: I18n.tr("Only {screen}", { screen: modelData.name }); strong: shell.bgTarget === modelData.name; onPressed: shell.bgTarget = modelData.name } } }
            Part { visible: shell.page === "background"; width: view.room; title: I18n.tr("Background")
                   note: shell.bgTarget === "*" ? I18n.tr("What you choose goes on every screen.") : I18n.tr("What you choose goes on {screen} only; the others keep theirs.", { screen: shell.bgTarget })
                Repeater { model: [{ id: "picture", name: QT_TR_NOOP("Picture"), icon: "photo" }, { id: "color", name: QT_TR_NOOP("Solid colour"), icon: "palette" },
                                   { id: "slideshow", name: QT_TR_NOOP("Slideshow"), icon: "folder" }, { id: "motionbgs", name: "MotionBGS", icon: "player-play" },
                                   { id: "wallhaven", name: "Wallhaven", icon: "world" }, { id: "bing", name: "Bing", icon: "world" },
                                   { id: "skwd", name: "skwd-wall", icon: "sparkles" }, { id: "lens", name: QT_TR_NOOP("Describe it"), icon: "search" }]
                    Pill { required property var modelData; icon: modelData.icon; text: I18n.tr(modelData.name); strong: shell.bgSource === modelData.id
                           onPressed: { shell.bgSource = modelData.id
                                        if (["motionbgs", "wallhaven", "bing"].includes(modelData.id)) { online.data = null; online.ask(["latte-walls", modelData.id]) } } } } }

            // a picture or a film of the user's own
            Part { visible: shell.page === "background" && shell.bgSource === "picture"; width: view.room; title: I18n.tr("Choose a picture"); note: I18n.tr("LatteOS's own, and what is in your Pictures and Videos folders. A film moves behind the desktop, silently.")
                Repeater { model: pictures.data ? pictures.data : []
                    ClippingRectangle { id: pic; required property var modelData; width: 200; height: 114; radius: 14; color: Theme.card
                        border.width: 3; border.color: shell.bg && shell.bg.shown[shell.bgTarget] === modelData.path ? Theme.gold : "transparent"
                        Image { anchors.fill: parent; anchors.margins: 3; visible: !pic.modelData.live; source: pic.modelData.live ? "" : "file://" + pic.modelData.path; fillMode: Image.PreserveAspectCrop; asynchronous: true; sourceSize.width: 420 }
                        Glyph { anchors.centerIn: parent; visible: pic.modelData.live; name: "player-play"; font.pixelSize: 30; color: Theme.gold }
                        Rectangle { visible: pic.modelData.live; anchors.bottom: parent.bottom; width: parent.width; height: 26; color: Qt.rgba(0, 0, 0, 0.5)
                                    Label { x: 10; width: parent.width - 20; text: pic.modelData.path.split("/").pop(); color: "white"; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter } }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: shell.bgSet(["picture", pic.modelData.path]) } } }
                Item { width: view.room; height: 1 }
                Pill { icon: "folder"; text: I18n.tr("Browse…"); onPressed: { chooser.what = "wallpaper"; chooser.open() } } }
            Part { visible: shell.page === "background" && ["picture", "slideshow"].includes(shell.bgSource) && shell.bg !== null && shell.bg.engine === "plain"; width: view.room; title: I18n.tr("Choose a fit")
                Repeater { model: [{ id: "fill", name: QT_TR_NOOP("Fill") }, { id: "fit", name: QT_TR_NOOP("Fit") }, { id: "stretch", name: QT_TR_NOOP("Stretch") }, { id: "center", name: QT_TR_NOOP("Centre") }, { id: "tile", name: QT_TR_NOOP("Tile") }]
                    Pill { required property var modelData; text: I18n.tr(modelData.name); strong: shell.bg !== null && shell.bg.fit === modelData.id; onPressed: shell.order(["latte-wall", "fit", modelData.id]) } } }

            // one colour
            Part { visible: shell.page === "background" && shell.bgSource === "color"; width: view.room; title: I18n.tr("Choose a colour")
                Repeater { model: ["#1a1410", "#2a1f19", "#3b1d10", "#0f1b2d", "#12343b", "#1f3a2a", "#3a1f2b", "#2d2a4a", "#4a4a4a", "#8a5a3a", "#c98a55", "#f3ebdd"]
                    Rectangle { required property string modelData; width: 54; height: 54; radius: 14; color: modelData
                                border.width: 3; border.color: shell.bg && (shell.bg.screens_own[shell.bgTarget] || shell.bg.all).color === modelData ? Theme.gold : Theme.line
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: shell.bgSet(["color", parent.modelData]) } } }
                Item { width: view.room; height: 1 }
                Field { id: hexField; width: 180; icon: "palette"; hint: "#RRGGBB"; onAccepted: if (/^#?[0-9a-fA-F]{6}$/.test(text.trim())) shell.bgSet(["color", text.trim()]) }
                Pill { icon: "check"; text: I18n.tr("Use this colour"); onPressed: if (/^#?[0-9a-fA-F]{6}$/.test(hexField.text.trim())) shell.bgSet(["color", hexField.text.trim()]) } }

            // the pictures of a folder, one after another
            Part { visible: shell.page === "background" && shell.bgSource === "slideshow"; width: view.room; title: I18n.tr("Choose a folder for the slideshow")
                   note: shell.showFolder === "" ? I18n.tr("Every picture and film in it takes its turn.") : shell.showFolder
                Pill { icon: "folder"; text: I18n.tr("Browse…"); onPressed: folders.open() }
                Item { width: view.room; height: 1 }
                Label { text: I18n.tr("Change picture every"); color: Theme.dim; height: 36; verticalAlignment: Text.AlignVCenter }
                Repeater { model: [{ m: 1, name: QT_TR_NOOP("1 minute") }, { m: 10, name: QT_TR_NOOP("10 minutes") }, { m: 30, name: QT_TR_NOOP("30 minutes") }, { m: 60, name: QT_TR_NOOP("1 hour") }, { m: 360, name: QT_TR_NOOP("6 hours") }, { m: 1440, name: QT_TR_NOOP("1 day") }]
                    Pill { required property var modelData; text: I18n.tr(modelData.name); strong: shell.showMinutes === modelData.m; onPressed: shell.showMinutes = modelData.m } }
                Item { width: view.room; height: 1 }
                Pill { icon: "arrows-sort"; text: I18n.tr("Shuffle"); strong: shell.showShuffle; onPressed: shell.showShuffle = !shell.showShuffle }
                Pill { icon: "player-play"; strong: true; text: I18n.tr("Start the slideshow"); visible: shell.showFolder !== ""
                       onPressed: shell.bgSet(["slideshow", shell.showFolder, String(shell.showMinutes)].concat(shell.showShuffle ? ["shuffle"] : [])) }
                Pill { icon: "chevron-left"; text: I18n.tr("Previous"); onPressed: shell.order(["latte-wall", "prev"]) }
                Pill { icon: "chevron-right"; text: I18n.tr("Next"); onPressed: shell.order(["latte-wall", "next"]) } }

            // from the internet: a press fetches one into the library and puts it on
            Part { visible: shell.page === "background" && ["motionbgs", "wallhaven", "bing"].includes(shell.bgSource); width: view.room
                   title: shell.bgSource === "bing" ? I18n.tr("Bing's pictures of the last days") : (shell.bgSource === "wallhaven" ? I18n.tr("Pictures from Wallhaven") : I18n.tr("Live wallpapers from MotionBGS"))
                   note: I18n.tr("A press fetches one into your Pictures and puts it behind the desktop.")
                Field { id: netField; visible: shell.bgSource !== "bing"; width: 320; hint: I18n.tr("Search…")
                        onAccepted: { online.data = null; online.ask(["latte-walls", shell.bgSource].concat(netField.text.trim().split(/\s+/).filter(w => w !== ""))) } }
                Item { width: view.room; height: 1 }
                Waiting { visible: online.data === null }
                Repeater { model: online.data ? online.data.slice(0, 30) : []
                    ClippingRectangle { id: net; required property var modelData; width: 200; height: 114; radius: 14; color: Theme.card
                        border.width: 3; border.color: shell.fetching === modelData.id ? Theme.gold : "transparent"
                        Image { anchors.fill: parent; anchors.margins: 3; source: net.modelData.thumb; fillMode: Image.PreserveAspectCrop; asynchronous: true; sourceSize.width: 420 }
                        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 26; color: Qt.rgba(0, 0, 0, 0.55)
                            Glyph { x: 8; visible: net.modelData.film; name: "player-play"; font.pixelSize: 12; color: "white"; anchors.verticalCenter: parent.verticalCenter }
                            Label { x: net.modelData.film ? 26 : 10; width: parent.width - x - 10; text: net.modelData.title; color: "white"; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter } }
                        Waiting { anchors.centerIn: parent; visible: shell.fetching === net.modelData.id }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; enabled: shell.fetching === ""
                                    onClicked: { shell.fetching = net.modelData.id; fetcher.running = false; fetcher.command = ["latte-walls", "get", net.modelData.url, net.modelData.title]; fetcher.running = true } } } } }

            // skwd-wall's own picker, and looking for a wallpaper by what it shows
            Part { visible: shell.page === "background" && shell.bgSource === "skwd"; width: view.room; title: "skwd-wall"
                   note: shell.bg !== null && shell.bg.engine === "skwd" ? I18n.tr("Its own picker over the desktop: your library with transitions, scenes of Wallpaper Engine, its downloads and playlists. What you choose there is kept here too.")
                                                                         : I18n.tr("skwd-wall is not installed. With it wallpapers change with a transition and scenes can be shown.")
                Pill { visible: shell.bg !== null && shell.bg.engine === "skwd"; icon: "sparkles"; strong: true; text: I18n.tr("Open skwd-wall"); onPressed: Quickshell.execDetached(["latte-wall", "pick"]) }
                Pill { visible: shell.bg !== null && shell.bg.engine === "skwd"; icon: "player-pause"; text: I18n.tr("Pause"); onPressed: Quickshell.execDetached(["latte-wall", "pause"]) }
                Pill { visible: shell.bg !== null && shell.bg.engine === "skwd"; icon: "player-play"; text: I18n.tr("Play"); onPressed: Quickshell.execDetached(["latte-wall", "resume"]) } }
            Part { visible: shell.page === "background" && shell.bgSource === "lens"; width: view.room; title: I18n.tr("Describe the wallpaper you want")
                   note: shell.bg !== null && shell.bg.lens ? I18n.tr("A model on this computer looks through your library for pictures that show what you describe. Nothing leaves the computer.")
                                                            : I18n.tr("This needs skwd-wall with its search model, and AI turned on in the Settings.")
                Field { id: lensField; visible: shell.bg !== null && shell.bg.lens; width: 420; hint: I18n.tr("a foggy forest in the morning…")
                        onAccepted: Quickshell.execDetached(["latte-wall", "pick"].concat(lensField.text.trim().split(/\s+/).filter(w => w !== ""))) }
                Pill { visible: shell.bg !== null && shell.bg.lens; icon: "search"; strong: true; text: I18n.tr("Look for it")
                       onPressed: Quickshell.execDetached(["latte-wall", "pick"].concat(lensField.text.trim().split(/\s+/).filter(w => w !== ""))) } }

            Switch { visible: shell.page === "background"; width: view.room; text: I18n.tr("Icons on the desktop"); on: icons.value !== "off"
                     hint: I18n.tr("The Recycle Bin and what is in your Desktop folder, over the background.")
                     onPressed: { const next = on ? "off" : "on"; icons.value = next; Quickshell.execDetached(["latte-desktop", next]) } }

            // windows: how they are arranged, and the glass of the side panels
            Part { visible: shell.page === "windows"; width: view.room; title: I18n.tr("How windows are arranged")
                Repeater { model: [{ id: "tape", name: QT_TR_NOOP("Tape"), hint: QT_TR_NOOP("an endless strip, nothing is put away"), icon: "layout-columns" },
                                   { id: "tiles", name: QT_TR_NOOP("Tiles"), hint: QT_TR_NOOP("windows share the screen"), icon: "layout-grid" },
                                   { id: "floating", name: QT_TR_NOOP("Floating windows"), hint: QT_TR_NOOP("as on Windows"), icon: "app-window" },
                                   { id: "glance", name: QT_TR_NOOP("Glance"), hint: QT_TR_NOOP("one in the middle, the others at the sides"), icon: "layout-distribute-vertical" }]
                    Choice { required property var modelData; width: 200; text: I18n.tr(modelData.name); hint: I18n.tr(modelData.hint); on: win.mode === modelData.id
                             onPressed: Quickshell.execDetached(["hyprctl", "eval", "latte.mode.set(\"" + modelData.id + "\")"])
                             Glyph { anchors.centerIn: parent; name: parent.parent.modelData.icon; font.pixelSize: 54; color: parent.parent.on ? Theme.gold : Theme.dim } } } }
            Part { visible: shell.page === "windows"; width: view.room; title: I18n.tr("The glass of the side panels"); note: I18n.tr("What is behind a window shows through its side panel, blurred. Where the graphics card cannot blur, the panel is solid.")
                Repeater { model: [{ id: "frost", name: QT_TR_NOOP("Frosted") }, { id: "smoke", name: QT_TR_NOOP("Smoked") }, { id: "clear", name: QT_TR_NOOP("Clear") }, { id: "milk", name: QT_TR_NOOP("Milky") }]
                    Choice { id: pane; required property var modelData; width: 150; height: 130; text: I18n.tr(modelData.name); on: Theme.glass === modelData.id; onPressed: { glass.choose(modelData.id); Theme.glass = modelData.id }
                        ClippingRectangle { anchors.fill: parent; radius: 10; color: "transparent"
                            Image { anchors.fill: parent; source: "file://" + shell.share + "/wallpapers/latteos-2.jpg"; fillMode: Image.PreserveAspectCrop; sourceSize.width: 240 }
                            Rectangle { anchors.fill: parent; color: Theme.glasses[pane.modelData.id] } } } } }

            // the drops
            Part { visible: shell.page === "drops"; width: view.room; title: I18n.tr("How the drops behave")
                Switch { text: I18n.tr("Lively"); hint: I18n.tr("Left alone they fall asleep, the weather outside shows on the surface, playful ones play."); on: goo.kept.lively !== false; onPressed: goo.set("lively", !on) }
                Switch { text: I18n.tr("The surface bends"); hint: I18n.tr("Ripples lift the drops and the edge gives under them."); on: goo.kept.bends !== false; onPressed: goo.set("bends", !on) } }
            Label { visible: shell.page === "drops"; width: view.room; wrapMode: Text.WordWrap; color: Theme.dim; font.pixelSize: 13
                    text: I18n.tr("Which drops are on the desktop, and putting them back in their places, is in PowerGoo › Settings on the desktop itself. The coffee they are made of is under Coffee and cup.") }

            // sound: where it goes and where it comes from
            Repeater { model: shell.page === "sound" ? [{ key: "outputs", title: QT_TR_NOOP("Where the sound goes"), cmd: "sink", icon: "device-speaker" },
                                                        { key: "inputs", title: QT_TR_NOOP("Where it comes from"), cmd: "source", icon: "microphone" }] : []
                Column { id: way; required property var modelData; width: view.room; spacing: 8
                    readonly property var list: sound.data ? sound.data[modelData.key] : []
                    Label { text: I18n.tr(way.modelData.title); font.pixelSize: 18; font.weight: 700; bottomPadding: 4 }
                    Label { visible: way.list.length === 0; text: I18n.tr("Nothing is connected."); color: Theme.dim }
                    Repeater { model: ScriptModel { values: way.list.map(d => d.name) }
                        Rectangle { id: dev; required property string modelData; width: view.room; height: 70; radius: 16; color: Theme.card
                            readonly property var d: way.list.find(x => x.name === modelData) || { label: "", volume: 0, muted: false, "default": false }
                            border.width: 2; border.color: d["default"] ? Theme.gold : "transparent"
                            Rectangle { x: 14; width: 42; height: 42; radius: 14; color: Theme.ground; anchors.verticalCenter: parent.verticalCenter
                                Glyph { anchors.centerIn: parent; name: dev.d.muted ? "volume-off" : way.modelData.icon; font.pixelSize: 22; color: dev.d["default"] ? Theme.gold : Theme.dim }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: shell.order(["pactl", "set-" + way.modelData.cmd + "-mute", dev.modelData, "toggle"]) } }
                            Column { x: 70; width: parent.width - 70 - 330; anchors.verticalCenter: parent.verticalCenter; spacing: 3
                                Label { text: dev.d.label; font.weight: 600; width: parent.width }
                                Label { text: dev.d["default"] ? I18n.tr("in use") : I18n.tr("press to use"); color: dev.d["default"] ? Theme.gold : Theme.dim; font.pixelSize: 12 } }
                            MouseArea { x: 70; width: parent.width - 400; height: parent.height; cursorShape: Qt.PointingHandCursor; onClicked: shell.order(["pactl", "set-default-" + way.modelData.cmd, dev.modelData]) }
                            Slide { anchors.right: parent.right; anchors.rightMargin: 70; anchors.verticalCenter: parent.verticalCenter; width: 230; value: dev.d.volume; off: dev.d.muted
                                    onMoved: to => shell.order(["pactl", "set-" + way.modelData.cmd + "-volume", dev.modelData, Math.round(to * 100) + "%"]) }
                            Label { anchors.right: parent.right; anchors.rightMargin: 18; anchors.verticalCenter: parent.verticalCenter; text: Math.round(dev.d.volume * 100) + " %"; color: Theme.dim; font.pixelSize: 12 } } } } }

            // which app opens what
            Label { visible: shell.page === "defaults"; width: view.room; wrapMode: Text.WordWrap; color: Theme.dim; font.pixelSize: 13
                    text: I18n.tr("The app that opens a kind of thing when it is pressed in a folder, a mail or a web page. Press another to make it the one.") }
            Repeater { model: shell.page === "defaults" && opens.data ? opens.data : []
                Column { id: kindRow; required property var modelData; width: view.room; spacing: 8
                    Row { spacing: 10
                        Glyph { name: shell.kindIcons[kindRow.modelData.kind] || "apps"; color: Theme.gold; font.pixelSize: 20; anchors.verticalCenter: parent.verticalCenter }
                        Label { text: I18n.tr(shell.kindNames[kindRow.modelData.kind] || kindRow.modelData.kind); font.pixelSize: 16; font.weight: 700; anchors.verticalCenter: parent.verticalCenter } }
                    Label { visible: kindRow.modelData.apps.length === 0; text: I18n.tr("No app for it is installed."); color: Theme.dim; font.pixelSize: 12 }
                    Flow { width: parent.width; spacing: 8
                        Repeater { model: kindRow.modelData.apps
                            Rectangle { id: appChip; required property var modelData; height: 44; width: chipRow.implicitWidth + 28; radius: 14
                                readonly property bool on: kindRow.modelData.current === modelData.id
                                color: on ? Theme.raised : Theme.card; border.width: 2; border.color: on ? Theme.gold : "transparent"
                                Row { id: chipRow; anchors.centerIn: parent; spacing: 9
                                    Image { width: 26; height: 26; source: appChip.modelData.icon.startsWith("/") ? "file://" + appChip.modelData.icon : Quickshell.iconPath(appChip.modelData.icon, true); sourceSize.width: 64; sourceSize.height: 64; anchors.verticalCenter: parent.verticalCenter; visible: status === Image.Ready }
                                    Label { text: appChip.modelData.name; font.weight: appChip.on ? 700 : 400; anchors.verticalCenter: parent.verticalCenter } }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: shell.order(["latte-settings", "default", kindRow.modelData.kind, appChip.modelData.id]) } } } } } }

            // how much the desktop spends on looks
            Part { visible: shell.page === "performance"; width: view.room; title: I18n.tr("How much the desktop spends on looks")
                   note: I18n.tr("Blur, shadows and movement cost the graphics card. It changes when you sign in the next time.")
                Repeater { model: shell.tiers
                    Choice { required property var modelData; width: 158; text: I18n.tr(modelData.name); on: tier.value === modelData.id; onPressed: tier.choose(modelData.id)
                             hint: modelData.id === "" ? (I18n.tr((shell.tiers.find(t => t.id === decided.tier) || { name: decided.tier }).name)) : I18n.tr(modelData.hint)
                             Glyph { anchors.centerIn: parent; name: parent.parent.modelData.icon; font.pixelSize: 50; color: parent.parent.on ? Theme.gold : Theme.dim } } } }
            Label { visible: shell.page === "performance"; width: view.room; wrapMode: Text.WordWrap; color: Theme.dim; font.pixelSize: 13
                    text: ((machine.data ? machine.data.groups.find(g => g.id === "graphics") : null) || { devices: [] }).devices.map(d => d.name + (d.driver ? "  ·  " + d.driver : "")).join("\n") }
            Row { visible: shell.page === "performance"; spacing: 10
                Pill { icon: "activity"; text: I18n.tr("Open the Monitor"); onPressed: Quickshell.execDetached(["latte-app", "monitor"]) }
                Pill { icon: "shield-check"; text: I18n.tr("Start and safe mode"); onPressed: shell.go("startmode") } }

            // how this start went, and SAFE for the next one
            Rectangle { visible: shell.page === "startmode"; width: view.room; height: 120; radius: 26
                gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: Theme.raised } GradientStop { position: 1; color: Theme.card } }
                Glyph { x: 30; name: decided.mode === "safe" ? "shield-lock" : "shield-check"; font.pixelSize: 54; color: Theme.gold; anchors.verticalCenter: parent.verticalCenter }
                Column { x: 110; width: parent.width - 140; anchors.verticalCenter: parent.verticalCenter; spacing: 5
                    Label { text: decided.mode === "safe" ? I18n.tr("This start is SAFE") : (decided.renderer === "hw" ? I18n.tr("The full desktop, drawn by the graphics card") : I18n.tr("The full desktop, drawn by the processor")); font.pixelSize: 19; font.weight: 700 }
                    Label { text: decided.reason; visible: text !== ""; color: Theme.dim; font.pixelSize: 12; width: parent.width; wrapMode: Text.WordWrap; maximumLineCount: 3 } } }
            Switch { visible: shell.page === "startmode"; width: view.room; text: I18n.tr("Start in SAFE the next time"); on: force.there
                     hint: I18n.tr("A plain desktop that always starts, for when the full one does not. For one start.")
                     onPressed: shell.order(["latte-boot", on ? "reset" : "force-safe"]) }
            Label { visible: shell.page === "startmode"; width: view.room; wrapMode: Text.WordWrap; color: Theme.dim; font.pixelSize: 13
                    text: I18n.tr("SAFE can also be chosen on the login screen. Should the full desktop crash right after it starts, LatteOS goes to SAFE by itself.") }
            Part { visible: shell.page === "startmode"; width: view.room; title: I18n.tr("The last crash")
                   note: crashed.said === "" ? I18n.tr("No crash is recorded.") : I18n.tr("What LatteOS noted when the desktop last ended badly. Copy it to send it to whoever helps.")
                Label { visible: crashed.said !== ""; width: view.room; text: crashed.said.split("\n").slice(0, 30).join("\n"); wrapMode: Text.WrapAnywhere
                        font.family: "JetBrains Mono"; font.pixelSize: 12; color: Theme.dim; maximumLineCount: 30; elide: Text.ElideRight }
                Pill { visible: crashed.said !== ""; icon: "clipboard"; text: I18n.tr("Copy the report")
                       onPressed: Quickshell.execDetached(["latte-safe", "why", "copy"]) } }
            Pill { visible: shell.page === "startmode"; icon: "activity"; text: I18n.tr("Performance and graphics"); onPressed: shell.go("performance") }

            // what is on the disks
            Repeater { model: shell.page === "storage" && disks.data ? disks.data.disks : []
                Rectangle { id: disk; required property var modelData; width: view.room; height: 86; radius: 16; color: Theme.card
                    readonly property real full: modelData.size > 0 ? modelData.used / modelData.size : 0
                    Glyph { x: 20; y: 18; name: "disc"; font.pixelSize: 24; color: Theme.gold }
                    Label { x: 58; y: 16; text: disk.modelData.mount === "/" ? I18n.tr("This computer") : disk.modelData.mount; font.weight: 700 }
                    Label { x: 58; y: 36; color: Theme.dim; font.pixelSize: 12; text: I18n.tr("{free} free of {size}", { free: shell.bytes(disk.modelData.size - disk.modelData.used), size: shell.bytes(disk.modelData.size) }) + "  ·  " + disk.modelData.kind }
                    Rectangle { x: 20; y: 62; width: parent.width - 40; height: 8; radius: 4; color: Theme.raised
                        Rectangle { width: parent.width * disk.full; height: 8; radius: 4; color: disk.full > 0.9 ? Theme.red : Theme.gold } } } }
            Part { visible: shell.page === "storage"; width: view.room; title: I18n.tr("Your folders")
                Waiting { visible: held.data === null }
                Repeater { model: shell.page === "storage" && held.data ? held.data.folders : []
                    Rectangle { id: fold; required property var modelData; width: 250; height: 60; radius: 16; color: foldHit.containsMouse ? Theme.raised : Theme.card
                        Glyph { x: 16; name: "folder"; font.pixelSize: 22; color: Theme.gold; anchors.verticalCenter: parent.verticalCenter }
                        Label { x: 50; y: 11; text: I18n.tr(shell.folderNames[fold.modelData.id] || fold.modelData.id); font.weight: 600 }
                        Label { x: 50; y: 31; text: shell.bytes(fold.modelData.size); color: Theme.dim; font.pixelSize: 12 }
                        MouseArea { id: foldHit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Quickshell.execDetached(["xdg-open", fold.modelData.path]) } } } }
            Rectangle { visible: shell.page === "storage" && held.data !== null; width: view.room; height: 64; radius: 16; color: Theme.card
                Glyph { x: 18; name: "trash"; font.pixelSize: 22; color: Theme.dim; anchors.verticalCenter: parent.verticalCenter }
                Column { x: 54; anchors.verticalCenter: parent.verticalCenter; spacing: 3
                    Label { text: I18n.tr("Trash"); font.weight: 600 }
                    Label { text: held.data ? shell.bytes(held.data.trash) : ""; color: Theme.dim; font.pixelSize: 12 } }
                Pill { anchors.right: parent.right; anchors.rightMargin: 14; anchors.verticalCenter: parent.verticalCenter; visible: held.data !== null && held.data.trash > 0; danger: shell.emptying
                       icon: "trash"; text: shell.emptying ? I18n.tr("Really empty it? It does not come back.") : I18n.tr("Empty the trash")
                       onPressed: { if (shell.emptying) shell.order(["gio", "trash", "--empty"]); shell.emptying = !shell.emptying } } }
            Label { visible: shell.page === "storage" && held.data !== null; width: view.room; wrapMode: Text.WordWrap; color: Theme.dim; font.pixelSize: 13
                    text: held.data ? I18n.tr("What apps keep to be quicker takes {size}; they fill it again by themselves.", { size: shell.bytes(held.data.cache) }) : "" }
            Pill { visible: shell.page === "storage"; icon: "disc"; text: I18n.tr("Disks in the Device Manager"); onPressed: Quickshell.execDetached(["latte-app", "devices", "disks"]) }

            // the AI
            Switch { visible: shell.page === "ai"; width: view.room; text: I18n.tr("AI in LatteOS"); on: ai.value !== "off"; onPressed: { ai.choose(on ? "off" : "on"); aiLater.restart() }
                     hint: I18n.tr("The AI mode of LensGoo, Win+C. Turned off, nothing of LatteOS talks to an AI.") }
            Part { visible: shell.page === "ai"; width: view.room; title: I18n.tr("Who answers"); note: I18n.tr("The official tool of a service answers, with the account you are signed in to it with. LatteOS keeps no key and no password of yours.")
                Label { visible: helpers.data !== null && helpers.data.length === 0; text: I18n.tr("No AI tool is installed on this computer."); color: Theme.dim }
                Repeater { model: shell.page === "ai" && helpers.data ? helpers.data : []
                    Rectangle { id: helper; required property var modelData; width: 300; height: 64; radius: 16; color: Theme.card; opacity: ai.value === "off" ? 0.5 : 1
                        Glyph { x: 18; name: "sparkles"; font.pixelSize: 24; color: Theme.gold; anchors.verticalCenter: parent.verticalCenter }
                        Column { x: 56; anchors.verticalCenter: parent.verticalCenter; spacing: 3
                            Label { text: helper.modelData.name; font.weight: 700 }
                            Label { text: helper.modelData.local ? I18n.tr("answers on this computer") : I18n.tr("a service on the internet"); color: Theme.dim; font.pixelSize: 12 } } } } }
            Label { visible: shell.page === "ai"; width: view.room; wrapMode: Text.WordWrap; color: Theme.dim; font.pixelSize: 13
                    text: I18n.tr("LensGoo takes a change here up when you sign in the next time.") }

            // who the user is
            Rectangle { visible: shell.page === "me"; width: view.room; height: 150; radius: 26
                gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: Theme.raised } GradientStop { position: 1; color: Theme.card } }
                ClippingRectangle { id: face; x: 30; width: 96; height: 96; radius: 48; color: Theme.ground; anchors.verticalCenter: parent.verticalCenter
                    Glyph { anchors.centerIn: parent; name: "user"; font.pixelSize: 46; color: Theme.dim; visible: portrait.status !== Image.Ready }
                    Image { id: portrait; anchors.fill: parent; fillMode: Image.PreserveAspectCrop; sourceSize.width: 192; cache: false; source: who.data && who.data.picture ? "file://" + who.data.picture : "" } }
                Column { x: 150; anchors.verticalCenter: parent.verticalCenter; spacing: 5
                    Label { text: who.data ? who.data.name : ""; font.pixelSize: 28; font.weight: 800 }
                    Label { text: who.data ? who.data.user : ""; color: Theme.dim } } }
            Part { visible: shell.page === "me"; width: view.room; title: I18n.tr("Name"); note: I18n.tr("As the login screen and the apps call you. The name you sign in with stays.")
                Field { id: nameField; width: Math.min(360, view.room - 140); icon: "user"; hint: who.data ? who.data.name : ""; onAccepted: if (text.trim() !== "") { shell.account("SetRealName", text.trim()); text = "" } }
                Pill { strong: true; text: I18n.tr("Save"); visible: nameField.text.trim() !== ""; onPressed: { shell.account("SetRealName", nameField.text.trim()); nameField.text = "" } } }
            Part { visible: shell.page === "me"; width: view.room; title: I18n.tr("Picture"); note: I18n.tr("One of the pictures in your Pictures folder.")
                Label { visible: pictures.data !== null && pictures.data.filter(p => p.own && !p.live).length === 0; text: I18n.tr("There are no pictures in it."); color: Theme.dim }
                Repeater { model: shell.page === "me" && pictures.data ? pictures.data.filter(p => p.own && !p.live).slice(0, 24) : []
                    ClippingRectangle { id: pick; required property var modelData; width: 76; height: 76; radius: 38; color: Theme.card
                        border.width: 2; border.color: who.data && who.data.picture === modelData.path ? Theme.gold : "transparent"
                        Image { anchors.fill: parent; fillMode: Image.PreserveAspectCrop; sourceSize.width: 152; asynchronous: true; source: "file://" + pick.modelData.path }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: shell.account("SetIconFile", pick.modelData.path) } } } }
            Pill { visible: shell.page === "me"; icon: "folder"; text: I18n.tr("Another file…"); onPressed: { chooser.what = "face"; chooser.open() } }

            // the screens
            Rectangle { visible: shell.page === "displays" && shell.screenWait > 0; width: view.room; height: 64; radius: 16; color: Theme.raised; border.width: 2; border.color: Theme.gold
                Label { x: 18; text: I18n.tr("Is the picture fine? It goes back in {n} s.", { n: shell.screenWait }); font.weight: 600; anchors.verticalCenter: parent.verticalCenter }
                Row { anchors.right: parent.right; anchors.rightMargin: 14; anchors.verticalCenter: parent.verticalCenter; spacing: 8
                    Pill { text: I18n.tr("Put it back"); onPressed: shell.screensBack() }
                    Pill { strong: true; icon: "check"; text: I18n.tr("Keep it"); onPressed: shell.keepScreens() } } }
            Item { id: desk; visible: shell.page === "displays"; width: view.room; height: 190
                readonly property real x0: shell.screenList.length ? Math.min.apply(null, shell.screenList.map(m => m.x)) : 0
                readonly property real y0: shell.screenList.length ? Math.min.apply(null, shell.screenList.map(m => m.y)) : 0
                readonly property real x1: shell.screenList.length ? Math.max.apply(null, shell.screenList.map(m => m.x + shell.wide(m))) : 1
                readonly property real y1: shell.screenList.length ? Math.max.apply(null, shell.screenList.map(m => m.y + shell.tall(m))) : 1
                readonly property real k: Math.min(width / Math.max(1, x1 - x0), height / Math.max(1, y1 - y0))
                Repeater { model: ScriptModel { values: shell.screenList.map(m => m.name) }
                    Rectangle { id: scr; required property string modelData
                        readonly property var m: shell.screenList.find(x => x.name === modelData) || shell.screenList[0]
                        readonly property bool on: shell.screenHere !== null && shell.screenHere.name === modelData
                        x: (desk.width - (desk.x1 - desk.x0) * desk.k) / 2 + (m.x - desk.x0) * desk.k + 3; y: (m.y - desk.y0) * desk.k + 3
                        width: shell.wide(m) * desk.k - 6; height: shell.tall(m) * desk.k - 6; radius: 14
                        color: on ? Theme.raised : Theme.card; border.width: 2; border.color: on ? Theme.gold : Theme.line
                        Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                        Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                        Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                        Column { anchors.centerIn: parent; spacing: 3
                            Glyph { name: shell.screenMain === scr.modelData ? "cup" : "device-desktop"; font.pixelSize: 26; color: scr.on ? Theme.gold : Theme.dim; anchors.horizontalCenter: parent.horizontalCenter }
                            Label { text: scr.modelData; font.weight: 700; anchors.horizontalCenter: parent.horizontalCenter }
                            Label { text: scr.m.width + " × " + scr.m.height; color: Theme.dim; font.pixelSize: 12; anchors.horizontalCenter: parent.horizontalCenter } }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: shell.screenAt = scr.modelData } } } }
            Label { visible: shell.page === "displays" && shell.screenHere !== null; width: view.room; color: Theme.dim; font.pixelSize: 13
                    text: shell.screenHere ? [shell.screenHere.make, shell.screenHere.model, shell.screenHere.name].filter(s => s).join("  ·  ") + (shell.screenMain === shell.screenHere.name ? "  ·  " + I18n.tr("the main screen, where the drops are") : "") : "" }
            Part { visible: shell.page === "displays" && shell.screenHere !== null; width: view.room; title: I18n.tr("Resolution")
                Repeater { model: shell.screenHere && shell.page === "displays" ? shell.modes(shell.screenHere) : []
                    Pill { required property var modelData; text: modelData.w + " × " + modelData.h; strong: shell.screenHere.width === modelData.w && shell.screenHere.height === modelData.h
                           onPressed: shell.changeScreen(shell.screenHere.name, { width: modelData.w, height: modelData.h, refreshRate: modelData.rates[0] }) } } }
            Part { visible: shell.page === "displays" && shell.screenHere !== null; width: view.room; title: I18n.tr("Pictures a second")
                Repeater { model: shell.screenHere && shell.page === "displays" ? (shell.modes(shell.screenHere).find(s => s.w === shell.screenHere.width && s.h === shell.screenHere.height) || { rates: [] }).rates : []
                    Pill { required property real modelData; text: Math.round(modelData) + " Hz"; strong: Math.abs(shell.screenHere.refreshRate - modelData) < 0.6
                           onPressed: shell.changeScreen(shell.screenHere.name, { refreshRate: modelData }) } } }
            Part { visible: shell.page === "displays" && shell.screenHere !== null; width: view.room; title: I18n.tr("How large things are"); note: I18n.tr("Texts, buttons and windows on this screen. A screen takes only the sizes its picture divides into.")
                Repeater { model: [1, 1.25, 1.5, 1.75, 2]
                    Pill { required property real modelData; text: Math.round(modelData * 100) + " %"; strong: shell.screenHere !== null && Math.abs(shell.screenHere.scale - modelData) < 0.07
                           onPressed: shell.changeScreen(shell.screenHere.name, { scale: modelData }) } } }
            Part { visible: shell.page === "displays" && shell.screenHere !== null; width: view.room; title: I18n.tr("Which way it is turned")
                Repeater { model: [{ t: 0, name: QT_TR_NOOP("Upright") }, { t: 1, name: QT_TR_NOOP("On its left side") }, { t: 2, name: QT_TR_NOOP("Upside down") }, { t: 3, name: QT_TR_NOOP("On its right side") }]
                    Pill { required property var modelData; text: I18n.tr(modelData.name); strong: shell.screenHere !== null && shell.screenHere.transform === modelData.t
                           onPressed: shell.changeScreen(shell.screenHere.name, { transform: modelData.t }) } } }
            Part { visible: shell.page === "displays" && (shell.screenList.length > 1 || screensWord.value === "duplicate"); width: view.room; title: I18n.tr("More than one screen")
                   note: I18n.tr("Extended, each screen is a desktop of its own. Duplicated, they all show the main one's picture.")
                Pill { icon: "layout-columns"; text: I18n.tr("Extend"); strong: screensWord.value !== "duplicate"
                       onPressed: { screensWord.value = "extend"; shell.order(["hyprctl", "eval", "latte.duplicate(false)"]) } }
                Pill { icon: "copy"; text: I18n.tr("Duplicate"); strong: screensWord.value === "duplicate"
                       onPressed: { screensWord.value = "duplicate"; shell.order(["hyprctl", "eval", "latte.duplicate(true)"]) } } }
            Part { visible: shell.page === "displays" && shell.screenList.length > 1; width: view.room; title: I18n.tr("Where it stands"); note: I18n.tr("The screens stand side by side as in the picture above. The main one carries the drops; every other has a window bar of its own.")
                Pill { icon: "chevron-left"; text: I18n.tr("Further left"); onPressed: shell.moveScreen(shell.screenHere.name, -1) }
                Pill { icon: "chevron-right"; text: I18n.tr("Further right"); onPressed: shell.moveScreen(shell.screenHere.name, 1) }
                Pill { icon: "cup"; text: I18n.tr("Make it the main screen"); visible: shell.screenHere !== null && shell.screenMain !== shell.screenHere.name; onPressed: shell.tryScreens(shell.screenList, shell.screenHere.name) } }

            // language, and whose dates and numbers
            Part { visible: shell.page === "language"; width: view.room; title: I18n.tr("Language"); note: I18n.tr("What the desktop and the apps speak. It changes when you sign in the next time.")
                Repeater { model: shell.page === "language" && region.data ? region.data.locales : []
                    Pill { required property var modelData; text: modelData.name + (modelData.place ? " · " + modelData.place : ""); strong: region.data.lang === modelData.id
                           onPressed: shell.order(["latte-settings", "locale", modelData.id].concat(region.data.formats ? [region.data.formats] : [])) } } }
            Part { visible: shell.page === "language"; width: view.room; title: I18n.tr("Dates, numbers and money"); note: I18n.tr("How a date, a number, a price and a sheet of paper are written, where that differs from the language.")
                Pill { text: I18n.tr("As the language"); strong: region.data !== null && region.data.formats === ""; onPressed: shell.order(["latte-settings", "locale", region.data.lang]) }
                Repeater { model: shell.page === "language" && region.data ? region.data.locales : []
                    Pill { required property var modelData; text: modelData.name + (modelData.place ? " · " + modelData.place : ""); strong: region.data.formats === modelData.id
                           onPressed: shell.order(["latte-settings", "locale", region.data.lang, modelData.id]) } } }
            Pill { visible: shell.page === "language"; icon: "keyboard"; text: I18n.tr("Keyboard layouts"); onPressed: shell.go("keyboard") }

            // the clock
            Rectangle { visible: shell.page === "time"; width: view.room; height: 150; radius: 26
                gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: Theme.raised } GradientStop { position: 1; color: Theme.card } }
                Column { x: 30; anchors.verticalCenter: parent.verticalCenter; spacing: 4
                    Label { text: shell.now.toLocaleTimeString(Qt.locale(), Locale.ShortFormat); font.pixelSize: 54; font.weight: 800 }
                    Label { text: shell.now.toLocaleDateString(Qt.locale(), Locale.LongFormat) + (clock.data ? "  ·  " + clock.data.zone.replace(/_/g, " ") : ""); color: Theme.dim } } }
            Switch { visible: shell.page === "time"; width: view.room; text: I18n.tr("Set the clock by itself"); hint: I18n.tr("From the internet. The administrator's password is asked for a change here."); on: clock.data !== null && clock.data.auto
                     onPressed: shell.order(["timedatectl", "set-ntp", on ? "false" : "true"]) }
            Part { id: zonePart; visible: shell.page === "time"; width: view.room; title: I18n.tr("Time zone"); note: I18n.tr("Type a city or a part of the world.")
                readonly property string asked: shell.plain(zoneField.text.trim()).replace(/ /g, "_")
                readonly property var shown: !clock.data ? [] : clock.data.zones.filter(z => asked !== "" ? shell.plain(z).indexOf(asked) >= 0 : z.split("/")[0] === clock.data.zone.split("/")[0]).slice(0, 80)
                Field { id: zoneField; width: Math.min(420, view.room); hint: I18n.tr("Search time zones…") }
                Item { width: view.room; height: 1 }
                Repeater { model: zonePart.shown
                    Pill { required property string modelData; text: modelData.replace(/_/g, " "); strong: clock.data.zone === modelData; onPressed: shell.order(["timedatectl", "set-timezone", modelData]) } } }

            // the keyboard
            Part { visible: shell.page === "keyboard"; width: view.room; title: I18n.tr("Keyboard layouts"); note: I18n.tr("The first is the one you type in. With more of them, Win+Space goes to the next.")
                Repeater { model: shell.page === "keyboard" && keys.data ? keys.data.current : []
                    Rectangle { id: lay; required property string modelData; required property int index; width: view.room; height: 56; radius: 16; color: Theme.card
                        border.width: 2; border.color: index === 0 ? Theme.gold : "transparent"
                        readonly property var others: keys.data.current.filter(i => i !== modelData)
                        Glyph { x: 18; name: "keyboard"; font.pixelSize: 22; color: lay.index === 0 ? Theme.gold : Theme.dim; anchors.verticalCenter: parent.verticalCenter }
                        Label { x: 54; text: shell.layoutName(lay.modelData); font.weight: 600; anchors.verticalCenter: parent.verticalCenter }
                        Row { anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter; spacing: 8
                            Pill { visible: lay.index > 0; text: I18n.tr("Make it the first"); onPressed: shell.order(["latte-settings", "keyboard", lay.modelData].concat(lay.others)) }
                            Pill { visible: lay.others.length > 0; icon: "x"; text: I18n.tr("Remove"); onPressed: shell.order(["latte-settings", "keyboard"].concat(lay.others)) } } } } }
            Part { id: layPart; visible: shell.page === "keyboard" && keys.data !== null && keys.data.current.length < 4; width: view.room; title: I18n.tr("Add a layout")
                readonly property string asked: shell.plain(layField.text.trim())
                readonly property var shown: !keys.data || asked.length < 2 ? [] : keys.data.layouts.filter(l => keys.data.current.indexOf(l.id) < 0 && shell.plain(l.name + " " + l.id).indexOf(asked) >= 0).slice(0, 40)
                Field { id: layField; width: Math.min(420, view.room); hint: I18n.tr("Search layouts: Slovak, US, Dvorak…") }
                Item { width: view.room; height: 1 }
                Repeater { model: layPart.shown
                    Pill { required property var modelData; icon: "plus"; text: modelData.name; onPressed: { layField.text = ""; shell.order(["latte-settings", "keyboard"].concat(keys.data.current, [modelData.id])) } } } }
            Part { visible: shell.page === "keyboard"; width: view.room; title: I18n.tr("Shortcuts"); note: I18n.tr("The mouse comes first in LatteOS: each of these is also a drop or a row of a card. Win is the Windows key.")
                Repeater { model: shell.page === "keyboard" && binds.data ? binds.data.filter(b => b.has_description) : []
                    Rectangle { id: bound; required property var modelData; width: Math.floor((view.room - 14) / 2); height: 44; radius: 12; color: Theme.card
                        Label { x: 16; width: parent.width - keyed.width - 40; text: I18n.tr(bound.modelData.description); anchors.verticalCenter: parent.verticalCenter }
                        Rectangle { id: keyed; anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter; width: keyedText.implicitWidth + 20; height: 28; radius: 8; color: Theme.ground
                            Label { id: keyedText; anchors.centerIn: parent; text: shell.pressed(bound.modelData); font.pixelSize: 12; font.weight: 700; color: Theme.gold } } } } }
            Label { visible: shell.page === "keyboard"; width: view.room; wrapMode: Text.WordWrap; color: Theme.dim; font.pixelSize: 13
                    text: I18n.tr("The login screen starts with the layouts of the whole system; there one is chosen with a click.") }

            // when it locks, when the screens go dark
            Part { visible: shell.page === "lock"; width: view.room; title: I18n.tr("Lock the session after"); note: I18n.tr("Left alone that long, the session locks; the password opens it again. A window that fills the screen keeps it awake.")
                Repeater { model: shell.waits
                    Pill { required property var modelData; text: I18n.tr(modelData.name); strong: idle.lock === modelData.s; onPressed: idle.choose(modelData.s, idle.screen) } } }
            Part { visible: shell.page === "lock"; width: view.room; title: I18n.tr("Turn the screens off after")
                Repeater { model: shell.waits
                    Pill { required property var modelData; text: I18n.tr(modelData.name); strong: idle.screen === modelData.s; onPressed: idle.choose(idle.lock, modelData.s) } } }
            Label { visible: shell.page === "lock"; width: view.room; wrapMode: Text.WordWrap; color: Theme.dim; font.pixelSize: 13
                    text: I18n.tr("The session also locks before the computer goes to sleep. Win+L locks it at once.") }

            // notifications: what a new one does. They wait in ClockGoo either way.
            Part { visible: shell.page === "notifications"; width: view.room; title: I18n.tr("When a notification comes"); note: I18n.tr("Every notification waits in ClockGoo until you have read it or cleared it.")
                Switch { width: view.room; text: I18n.tr("Do not disturb"); hint: I18n.tr("Nothing is shown and nothing sounds; notifications wait quietly."); on: goo.kept.quiet === true; onPressed: goo.set("quiet", !on) }
                Switch { width: view.room; text: I18n.tr("Show it in the corner"); hint: I18n.tr("A note for a few seconds above the right end of the bar. A press opens the notifications."); on: goo.kept.banners !== false; onPressed: goo.set("banners", !on) }
                Switch { width: view.room; text: I18n.tr("Play a sound"); hint: I18n.tr("A short, quiet tone."); on: goo.kept.notify_sound !== false; onPressed: goo.set("notify_sound", !on) } }
            Pill { visible: shell.page === "notifications"; icon: "bell"; text: I18n.tr("Try it"); onPressed: Quickshell.execDetached(["notify-send", "LatteOS", I18n.tr("This is how a notification looks.")]) }

            // the password
            Part { visible: shell.page === "password"; width: view.room; title: I18n.tr("Change your password"); note: I18n.tr("Type the new one twice. The system then asks for the present one in its own window.")
                Field { id: pass1; width: 320; icon: "lock"; secret: true; hint: I18n.tr("New password") }
                Field { id: pass2; width: 320; icon: "lock"; secret: true; hint: I18n.tr("New password again"); onAccepted: changer.pressed() }
                Item { width: view.room; height: 1 }
                Pill { id: changer; icon: "check"; strong: pass1.text !== "" && pass1.text === pass2.text; text: I18n.tr("Change password")
                       onPressed: { if (pass1.text === "" || pass1.text !== pass2.text) { shell.passSaid = I18n.tr("The two do not match."); return }
                                    shell.passSaid = ""; passer.running = false; passer.stdinEnabled = true; passer.fresh = pass1.text; passer.running = true; pass1.text = ""; pass2.text = "" } }
                Label { visible: shell.passSaid !== ""; text: shell.passSaid; color: Theme.gold; height: 36; verticalAlignment: Text.AlignVCenter } }
            Pill { visible: shell.page === "password"; icon: "lock"; text: I18n.tr("Lock and idle"); onPressed: shell.go("lock") }

            // the login screen: what it shows besides the login
            Part { visible: shell.page === "loginscreen"; width: view.room; title: I18n.tr("Under the surface"); note: I18n.tr("A crash is always shown first. Otherwise the headlines of the feeds below.")
                Pill { text: I18n.tr("News"); strong: logon.data !== null && logon.data.panel !== "none"; onPressed: shell.order(["latte-settings", "loginscreen", "panel", "news"]) }
                Pill { text: I18n.tr("Nothing"); strong: logon.data !== null && logon.data.panel === "none"; onPressed: shell.order(["latte-settings", "loginscreen", "panel", "none"]) } }
            Part { visible: shell.page === "loginscreen"; width: view.room; title: I18n.tr("News feeds"); note: I18n.tr("RSS or Atom addresses, separated by a space. Fetched at most every 15 minutes.")
                Field { id: feedField; width: Math.min(560, view.room); icon: "rss"; hint: I18n.tr("https://…"); text: logon.data ? logon.data.news_url : ""
                        onAccepted: shell.order(["latte-settings", "loginscreen", "news"].concat(feedField.text.trim().split(/\s+/).filter(u => u !== ""))) }
                Pill { icon: "check"; text: I18n.tr("Save"); onPressed: shell.order(["latte-settings", "loginscreen", "news"].concat(feedField.text.trim().split(/\s+/).filter(u => u !== ""))) } }
            Part { visible: shell.page === "loginscreen"; width: view.room; title: I18n.tr("Sky and weather"); note: logon.data && logon.data.place !== "" ? logon.data.place : I18n.tr("No place: the login screen shows no sky and no weather.")
                Field { id: placeField; width: Math.min(420, view.room); icon: "map-pin"; hint: I18n.tr("A city, e.g. Vienna"); onAccepted: shell.order(["latte-settings", "loginscreen", "place", placeField.text.trim()]) }
                Pill { icon: "search"; text: I18n.tr("Find"); onPressed: shell.order(["latte-settings", "loginscreen", "place", placeField.text.trim()]) }
                Pill { icon: "x"; text: I18n.tr("No weather"); onPressed: { placeField.text = ""; shell.order(["latte-settings", "loginscreen", "place"]) } } }
            Label { visible: shell.page === "loginscreen"; width: view.room; wrapMode: Text.WordWrap; color: Theme.dim; font.pixelSize: 13
                    text: I18n.tr("The language and the keyboard layout are chosen on the login screen itself, with a click.") }

            // power
            Part { visible: shell.page === "power"; width: view.room; title: I18n.tr("Power profile"); note: shell.profile === "" ? I18n.tr("This computer offers no power profiles.") : ""
                Repeater { model: shell.profile === "" ? [] : [{ id: "power-saver", name: QT_TR_NOOP("Power saver"), hint: QT_TR_NOOP("quiet and cool"), icon: "battery-1" },
                                   { id: "balanced", name: QT_TR_NOOP("Balanced"), hint: QT_TR_NOOP("for every day"), icon: "battery-3" },
                                   { id: "performance", name: QT_TR_NOOP("Performance"), hint: QT_TR_NOOP("everything it has"), icon: "activity" }]
                    Choice { required property var modelData; width: 190; text: I18n.tr(modelData.name); hint: I18n.tr(modelData.hint); on: shell.profile === modelData.id
                             onPressed: { setProfile.running = false; setProfile.command = ["powerprofilesctl", "set", modelData.id]; setProfile.running = true }
                             Glyph { anchors.centerIn: parent; name: parent.parent.modelData.icon; font.pixelSize: 50; color: parent.parent.on ? Theme.gold : Theme.dim } } } }
            Pill { visible: shell.page === "power"; icon: "lock"; text: I18n.tr("Lock and idle"); onPressed: shell.go("lock") }

            // about this computer
            Rectangle { visible: shell.page === "about"; width: view.room; height: 170; radius: 26
                gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: Theme.raised } GradientStop { position: 1; color: Theme.card } }
                readonly property var c: machine.data ? machine.data.computer : ({})
                readonly property string os: release.pretty
                Glyph { x: 30; name: "cup"; font.pixelSize: 70; color: Theme.gold; anchors.verticalCenter: parent.verticalCenter }
                Column { x: 130; anchors.verticalCenter: parent.verticalCenter; spacing: 5; width: parent.width - 160
                    Label { text: "LatteOS GOO"; font.pixelSize: 30; font.weight: 800 }
                    Label { text: (parent.parent.c.host || "") + (parent.parent.c.model ? "  ·  " + parent.parent.c.model : ""); color: Theme.dim; width: parent.width }
                    Label { color: Theme.dim; font.pixelSize: 13; width: parent.width
                            text: [parent.parent.os, parent.parent.c.kernel ? "Linux " + parent.parent.c.kernel : "", parent.parent.c.cpu || "", parent.parent.c.ram_gb ? parent.parent.c.ram_gb + " GB" : ""].filter(s => s !== "").join("  ·  ") } } }
            Pill { visible: shell.page === "about"; icon: "cpu"; text: I18n.tr("Open the Device Manager"); onPressed: Quickshell.execDetached(["latte-app", "devices"]) }

            // a page that is still to come
            Column { visible: shell.here !== null && shell.here.status !== "ready"; width: view.room; spacing: 14; topPadding: 40
                Glyph { name: shell.here ? shell.here.icon : ""; font.pixelSize: 60; color: Theme.faint }
                Label { text: I18n.tr("This page is not in LatteOS yet."); font.pixelSize: 18; font.weight: 700 }
                Label { visible: shell.here !== null && shell.here.elsewhere !== undefined; text: I18n.tr("Meanwhile it is done here:"); color: Theme.dim }
                Pill { visible: shell.here !== null && shell.here.elsewhere !== undefined; strong: true; icon: "external-link"; text: I18n.tr("Open"); onPressed: shell.elsewhere(shell.here) } }
        }
    }
}
