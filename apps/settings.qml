// Settings: everything about the computer and the desktop that can be set, in one place, by areas, with a search.
// The areas and their pages are listed in settings/pages.json (LensGoo searches the same list: bin/latte-settings).
// A page that LatteOS does not have yet is listed all the same, and says where the thing is done meanwhile.
//   latte-app settings [PAGE]
//
// The side is a menu that unfolds: an area, and under it its pages. A dot says how far a page is: full when it
// works here, hollow when it is still to come. Typing in the header's field lists the pages that match.
import QtQuick
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
    Word { id: glass; name: "glass" }
    Word { id: wallpaper; name: "wallpaper" }
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
    Process { id: tell; onExited: { if (shell.page === "sound") sound.ask(["latte-settings", "sound"]); if (shell.page === "defaults") opens.ask(["latte-settings", "defaults"]) } }
    function order(args) { tell.running = false; tell.command = args; tell.running = true }
    Timer { interval: 2500; repeat: true; running: shell.page === "sound"; onTriggered: if (!tell.running) sound.ask(["latte-settings", "sound"]) }
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
        if (page === "coffee") coffees.ask(["latte-login", "coffees"])
        if (page === "background") pictures.ask(["latte-settings", "wallpapers"])
        if (page === "about") machine.ask(["latte-devices", "list"])
        if (page === "power") profiles.running = true
        if (page === "sound") sound.ask(["latte-settings", "sound"])
        if (page === "defaults") opens.ask(["latte-settings", "defaults"])
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
                    Choice { required property var modelData; width: 190; text: I18n.tr(modelData.name); hint: I18n.tr(modelData.hint); on: Theme.cup === modelData.id; onPressed: { cup.choose(modelData.id); Theme.cup = modelData.id }
                        // a small window made of that cup
                        Rectangle { anchors.fill: parent; radius: 10; color: Theme.cups[parent.parent.modelData.id].ground; border.width: 1; border.color: Theme.cups[parent.parent.modelData.id].line
                            Rectangle { width: parent.width * 0.3; height: parent.height; radius: 10; color: Theme.cups[parent.parent.parent.modelData.id].surface }
                            Rectangle { x: parent.width * 0.38; y: 12; width: parent.width * 0.5; height: 8; radius: 4; color: Theme.cups[parent.parent.parent.modelData.id].cream }
                            Rectangle { x: parent.width * 0.38; y: 28; width: parent.width * 0.36; height: 6; radius: 3; color: Theme.cups[parent.parent.parent.modelData.id].dim }
                            Rectangle { x: parent.width * 0.38; y: 46; width: 40; height: 16; radius: 8; color: Theme.cups[parent.parent.parent.modelData.id].gold } } } } }
            Part { visible: shell.page === "coffee"; width: view.room; title: I18n.tr("Glass")
                Switch { text: I18n.tr("Coffee in glass"); hint: I18n.tr("The drops are glass with coffee in it, and where the graphics card can, the windows are glass too.")
                         on: goo.kept.material === "glass"; onPressed: goo.set("material", on ? "coffee" : "glass") } }

            // the background: pictures, and films that move
            Part { visible: shell.page === "background"; width: view.room; title: I18n.tr("Pictures"); note: I18n.tr("LatteOS's own, and what is in your Pictures folder.")
                Repeater { model: pictures.data ? pictures.data.filter(p => !p.live) : []
                    ClippingRectangle { id: pic; required property var modelData; width: 232; height: 132; radius: 16; color: Theme.card
                        border.width: 3; border.color: wallpaper.value === modelData.path ? Theme.gold : "transparent"
                        Image { anchors.fill: parent; anchors.margins: 3; source: "file://" + pic.modelData.path; fillMode: Image.PreserveAspectCrop; asynchronous: true; sourceSize.width: 480 }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: { wallpaper.value = pic.modelData.path; Quickshell.execDetached(["hyprctl", "eval", "latte.wallpaper(" + JSON.stringify(pic.modelData.path) + ")"]) } } } } }
            Part { visible: shell.page === "background"; width: view.room; title: I18n.tr("Live backgrounds")
                   note: pictures.data && pictures.data.some(p => p.live) ? I18n.tr("Films from your Videos folder, played silently behind the desktop.") : I18n.tr("Put a film (.mp4, .webm, .mkv) in your Videos folder, or in a folder Wallpapers in it, and it shows here.")
                Repeater { model: pictures.data ? pictures.data.filter(p => p.live) : []
                    Rectangle { required property var modelData; width: 232; height: 60; radius: 16; color: Theme.card; border.width: 2; border.color: wallpaper.value === modelData.path ? Theme.gold : "transparent"
                        Glyph { x: 16; name: "player-play"; color: Theme.gold; anchors.verticalCenter: parent.verticalCenter }
                        Label { x: 46; width: parent.width - 60; text: parent.modelData.path.split("/").pop(); anchors.verticalCenter: parent.verticalCenter }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: { wallpaper.value = parent.modelData.path; Quickshell.execDetached(["hyprctl", "eval", "latte.wallpaper(" + JSON.stringify(parent.modelData.path) + ")"]) } } } } }

            // windows: how they are arranged, and the glass of the side panels
            Part { visible: shell.page === "windows"; width: view.room; title: I18n.tr("How windows are arranged")
                Repeater { model: [{ id: "tape", name: QT_TR_NOOP("Tape"), hint: QT_TR_NOOP("an endless strip, nothing is put away"), icon: "layout-columns" },
                                   { id: "tiles", name: QT_TR_NOOP("Tiles"), hint: QT_TR_NOOP("windows share the screen"), icon: "layout-grid" },
                                   { id: "floating", name: QT_TR_NOOP("Floating windows"), hint: QT_TR_NOOP("as on Windows"), icon: "app-window" }]
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

            // when it locks, when the screens go dark
            Part { visible: shell.page === "lock"; width: view.room; title: I18n.tr("Lock the session after"); note: I18n.tr("Left alone that long, the session locks; the password opens it again. A window that fills the screen keeps it awake.")
                Repeater { model: shell.waits
                    Pill { required property var modelData; text: I18n.tr(modelData.name); strong: idle.lock === modelData.s; onPressed: idle.choose(modelData.s, idle.screen) } } }
            Part { visible: shell.page === "lock"; width: view.room; title: I18n.tr("Turn the screens off after")
                Repeater { model: shell.waits
                    Pill { required property var modelData; text: I18n.tr(modelData.name); strong: idle.screen === modelData.s; onPressed: idle.choose(idle.lock, modelData.s) } } }
            Label { visible: shell.page === "lock"; width: view.room; wrapMode: Text.WordWrap; color: Theme.dim; font.pixelSize: 13
                    text: I18n.tr("The session also locks before the computer goes to sleep. Win+L locks it at once.") }

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
