// App Manager: the shop, what is installed, what can be updated, and Barista, who installs what no shop has.
// bin/latte-apps knows and does everything; this window shows it. Where it begins is told in words
// (bin/latte-app):   latte-app appmanager [updates | mine | barista | app ID]
//
// The pages: discover (banners and shelves) · category · search · app (one in full) · mine · updates · barista.
// One thing is installed, removed or updated at a time; the rest wait in a queue, shown at the bottom of the side.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import "common"

ShellRoot {
    id: shell
    Theme { id: theme }
    I18n { id: i18n }
    Icons { id: icons }

    readonly property var words: (Quickshell.env("LATTE_APP_ARGS") || "").split("\n").filter(w => w !== "")
    // ── where one is ──────────────────────────────────────────────────────────────────────────────────────
    property string page: "discover"
    property string arg: ""                    // the category, the app's id or what is searched for
    property var trail: []                     // the pages before this one, for the way back
    function go(to, what, keep) {
        if (!keep) trail = trail.concat([{ page: page, arg: arg }])
        page = to; arg = what || ""
        if (to === "category") category.ask(["store", "category", arg])
        if (to === "search") found.ask(["store", "search", arg])
        if (to === "app") { detail.data = null; detail.ask(["store", "app", arg]) }
    }
    function back() {
        if (trail.length === 0) return go("discover", "", true)
        const last = trail[trail.length - 1]
        trail = trail.slice(0, -1)
        go(last.page, last.arg, true)
    }

    // ── what latte-apps says ──────────────────────────────────────────────────────────────────────────────
    component Ask: Process {
        id: q
        property var data: null
        property bool busy: false
        property string buf: ""
        function ask(args) { busy = true; running = false; command = ["latte-apps"].concat(args); running = true }
        stdout: StdioCollector { onStreamFinished: q.buf = this.text }
        onExited: { busy = false; try { data = JSON.parse(buf) } catch (e) { data = null } }
    }
    Ask { id: front }
    Ask { id: category }
    Ask { id: found }
    Ask { id: detail }
    Ask { id: mine }
    Ask { id: fresh }
    function reload() { mine.ask(["installed"]); fresh.ask(["updates"]) }
    readonly property int waiting: fresh.data ? fresh.data.apps.length + (fresh.data.system > 0 ? 1 : 0) : 0
    function has(id) { return (mine.data || []).some(a => a.id === id) }

    // ── the work: one job at a time ───────────────────────────────────────────────────────────────────────
    property var queue: []                     // { verb, id, name }
    property var job: null                     // the one running, with `line` and `log`
    property string lastError: ""
    function work(verb, id, name) {
        if ((job && job.verb === verb && job.id === id) || queue.some(j => j.verb === verb && j.id === id)) return
        queue = queue.concat([{ verb: verb, id: id, name: name }])
        next()
    }
    function next() {
        if (job || queue.length === 0) return
        const j = queue[0]
        queue = queue.slice(1)
        job = { verb: j.verb, id: j.id, name: j.name, line: "", log: "" }
        worker.command = ["latte-apps", j.verb].concat(j.id ? [j.id] : [])
        worker.running = true
    }
    function doing(id, verb) { return [job].concat(queue).some(j => j && j.id === id && (!verb || j.verb === verb)) }
    Process {
        id: worker
        stdout: SplitParser {
            onRead: line => {
                if (!shell.job) return
                const j = shell.job
                shell.job = { verb: j.verb, id: j.id, name: j.name, line: line.trim() || j.line, log: (j.log + line + "\n").slice(-6000) }
            }
        }
        onExited: code => {
            shell.lastError = code === 0 ? "" : i18n.tr("{name}: it did not work", { name: shell.job ? shell.job.name : "" }) + (shell.job && shell.job.line ? " — " + shell.job.line : "")
            shell.job = null
            shell.reload()
            if (shell.page === "app") detail.ask(["store", "app", shell.arg])
            shell.next()
        }
    }

    Component.onCompleted: {
        front.ask(["store", "home"])
        reload()
        if (words[0] === "updates" || words[0] === "mine" || words[0] === "barista") go(words[0], "", true)
        else if (words[0] === "app" && words[1]) go("app", words[1], true)
    }

    readonly property var categories: [
        { id: "game", name: QT_TR_NOOP("Games"), icon: "device-gamepad-2" }, { id: "audiovideo", name: QT_TR_NOOP("Music and video"), icon: "music" },
        { id: "graphics", name: QT_TR_NOOP("Graphics and photos"), icon: "palette" }, { id: "office", name: QT_TR_NOOP("Office"), icon: "file-text" },
        { id: "network", name: QT_TR_NOOP("Internet"), icon: "world-www" }, { id: "development", name: QT_TR_NOOP("Development"), icon: "code" },
        { id: "education", name: QT_TR_NOOP("Education"), icon: "school" }, { id: "science", name: QT_TR_NOOP("Science"), icon: "flask" },
        { id: "system", name: QT_TR_NOOP("System"), icon: "settings" }, { id: "utility", name: QT_TR_NOOP("Tools"), icon: "tool" },
        { id: "healthfitness", name: QT_TR_NOOP("Health"), icon: "heart" }]
    readonly property var sources: ({ "flatpak": "Flatpak", "flatpak-system": "Flatpak", "rpm": "Fedora", "local": "Local" })
    function count(n) { return n >= 1000000 ? (n / 1000000).toFixed(1) + " M" : (n >= 1000 ? Math.round(n / 1000) + " k" : String(n)) }
    function megabytes(bytes) { return bytes >= 1073741824 ? (bytes / 1073741824).toFixed(1) + " GB" : Math.max(1, Math.round(bytes / 1048576)) + " MB" }
    function picture(icon) { return !icon ? "" : (icon.startsWith("http") ? icon : (icon.startsWith("/") ? "file://" + icon : Quickshell.iconPath(icon, true))) }

    // ── small things used everywhere ──────────────────────────────────────────────────────────────────────
    component Glyph: Text {
        property string name
        text: icons.of(name)
        font.family: theme.icons
        font.pixelSize: 18
        color: theme.cream
        renderType: Text.NativeRendering       // Qt's own way of drawing letters loses parts of some of these outlines
    }
    component Label: Text {
        color: theme.cream
        font.family: theme.font
        font.pixelSize: 14
        elide: Text.ElideRight
    }
    // an app's icon, or a box where it has none (or is still on its way)
    component AppIcon: Item {
        property string icon
        property real side: 56
        width: side; height: side
        Rectangle { anchors.fill: parent; radius: side * 0.24; color: theme.raised; visible: face.status !== Image.Ready
            Glyph { anchors.centerIn: parent; name: "package"; font.pixelSize: parent.width * 0.5; color: theme.faint } }
        Image { id: face; anchors.fill: parent; source: shell.picture(icon); sourceSize.width: side * 2; sourceSize.height: side * 2
                fillMode: Image.PreserveAspectFit; asynchronous: true; smooth: true }
    }
    // a button: gold when it is the thing to do, quiet otherwise
    component Pill: Rectangle {
        id: pill
        property string text
        property string icon
        property bool strong: false
        property bool danger: false
        property bool busy: false
        signal pressed()
        property real turn: 0                  // the icon turns while it works, and stands straight again after
        NumberAnimation on turn { running: pill.busy; from: 0; to: 360; duration: 1100; loops: Animation.Infinite }
        implicitWidth: row.implicitWidth + 30; implicitHeight: 36
        radius: height / 2
        color: busy ? theme.raised : (strong ? theme.gold : (hit.containsMouse ? theme.raised : theme.card))
        border.color: danger ? theme.red : (strong ? "transparent" : theme.line); border.width: strong ? 0 : 1
        scale: hit.pressed ? 0.96 : 1
        Behavior on scale { NumberAnimation { duration: 90 } }
        Behavior on color { ColorAnimation { duration: 120 } }
        Row { id: row; anchors.centerIn: parent; spacing: 7
            Glyph { name: pill.icon; visible: pill.icon !== ""; font.pixelSize: 16; anchors.verticalCenter: parent.verticalCenter
                    color: pill.busy ? theme.dim : (pill.strong ? theme.ground : (pill.danger ? theme.red : theme.cream))
                    rotation: pill.busy ? pill.turn : 0 }
            Label { text: pill.text; font.weight: 600; color: pill.busy ? theme.dim : (pill.strong ? theme.ground : (pill.danger ? theme.red : theme.cream)); anchors.verticalCenter: parent.verticalCenter } }
        MouseArea { id: hit; anchors.fill: parent; hoverEnabled: true; enabled: !pill.busy; cursorShape: Qt.PointingHandCursor; onClicked: pill.pressed() }
    }
    // what is to be done with an app: install it, or it is there
    component Act: Pill {
        property var app
        readonly property bool there: shell.has(app.id) || app.installed === true
        busy: shell.doing(app.id)
        strong: !there
        icon: busy ? "refresh" : (there ? "circle-check" : "download")
        text: busy ? i18n.tr("Working…") : (there ? i18n.tr("Installed") : i18n.tr("Install"))
        onPressed: there ? shell.go("app", app.id) : shell.work("install", app.id, app.name)
    }
    // an app as a card on a shelf
    component AppCard: Rectangle {
        id: tile
        property var app
        width: 268; height: 108
        radius: 18
        color: over.containsMouse ? theme.raised : theme.card
        border.color: over.containsMouse ? Qt.rgba(0.97, 0.78, 0.45, 0.45) : "transparent"; border.width: 1
        scale: over.containsMouse ? 1.025 : 1
        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: 140 } }
        MouseArea { id: over; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: shell.go("app", tile.app.id) }
        AppIcon { id: pic; x: 16; anchors.verticalCenter: parent.verticalCenter; icon: tile.app.icon; side: 60 }
        Column { anchors.left: pic.right; anchors.leftMargin: 14; anchors.right: parent.right; anchors.rightMargin: 14; anchors.verticalCenter: parent.verticalCenter; spacing: 3
            Row { spacing: 5; width: parent.width
                Label { text: tile.app.name; font.pixelSize: 15; font.weight: 700; width: Math.min(implicitWidth, parent.width - (seal.visible ? 22 : 0)) }
                Glyph { id: seal; name: "rosette-discount-check"; visible: tile.app.verified === true; font.pixelSize: 15; color: theme.gold; anchors.verticalCenter: parent.verticalCenter } }
            Label { text: tile.app.summary; color: theme.dim; font.pixelSize: 13; width: parent.width; wrapMode: Text.WordWrap; maximumLineCount: 2; lineHeight: 1.15 }
            Row { spacing: 5; visible: (tile.app.installs || 0) > 0 || shell.has(tile.app.id)
                Glyph { name: shell.has(tile.app.id) ? "circle-check" : "download"; font.pixelSize: 12; color: shell.has(tile.app.id) ? theme.ok : theme.faint; anchors.verticalCenter: parent.verticalCenter }
                Label { text: shell.has(tile.app.id) ? i18n.tr("Installed") : i18n.tr("{n} a month", { n: shell.count(tile.app.installs || 0) }); color: shell.has(tile.app.id) ? theme.ok : theme.faint; font.pixelSize: 12 } } }
    }
    // a shelf: a heading and the cards under it, as many in a row as fit
    component Shelf: Column {
        property string title
        property string icon
        property var apps: []
        property real room: 800
        spacing: 12
        visible: apps.length > 0
        Row { spacing: 9
            Glyph { name: icon; color: theme.gold; font.pixelSize: 19; anchors.verticalCenter: parent.verticalCenter }
            Label { text: title; font.pixelSize: 19; font.weight: 700 } }
        Flow { width: room; spacing: 14
            Repeater { model: apps; AppCard { required property var modelData; app: modelData; width: Math.floor((room - 14 * (Math.max(1, Math.floor(room / 270)) - 1)) / Math.max(1, Math.floor(room / 270))) } } }
    }
    // a page that scrolls, with room around what it holds
    component Scroll: Flickable {
        default property alias content: inner.data
        readonly property real room: width - 56
        anchors.fill: parent
        contentWidth: width; contentHeight: inner.height + 56
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        Column { id: inner; x: 28; y: 24; width: parent.width - 56; spacing: 26 }
    }
    component Waiting: Column {
        property string text
        spacing: 12
        Glyph { name: "cup"; font.pixelSize: 44; color: theme.coffee; anchors.horizontalCenter: parent.horizontalCenter
                SequentialAnimation on opacity { loops: Animation.Infinite; NumberAnimation { to: 0.35; duration: 700 } NumberAnimation { to: 1; duration: 700 } } }
        Label { text: parent.text; color: theme.dim; anchors.horizontalCenter: parent.horizontalCenter }
    }

    // a line of the side: a page, a category
    component Nav: Rectangle {
        id: nav
        property string text
        property string icon
        property bool on: false
        property int badge: 0
        signal pressed()
        width: 222; height: 38; radius: 12
        color: on ? theme.raised : (navHit.containsMouse ? theme.card : "transparent")
        Behavior on color { ColorAnimation { duration: 110 } }
        Rectangle { width: 3; height: 18; radius: 2; color: theme.gold; visible: nav.on; anchors.verticalCenter: parent.verticalCenter }
        Glyph { x: 14; name: nav.icon; color: nav.on ? theme.gold : theme.dim; anchors.verticalCenter: parent.verticalCenter }
        Label { x: 44; text: nav.text; width: parent.width - 44 - (nav.badge > 0 ? 40 : 10); color: nav.on ? theme.cream : theme.dim; font.weight: nav.on ? 600 : 400; anchors.verticalCenter: parent.verticalCenter }
        Rectangle { visible: nav.badge > 0; width: Math.max(22, mark.implicitWidth + 12); height: 20; radius: 10; color: theme.gold; anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter
            Label { id: mark; text: nav.badge; anchors.centerIn: parent; color: theme.ground; font.pixelSize: 12; font.weight: 700 } }
        MouseArea { id: navHit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: nav.pressed() }
    }
    // one thing known about an app, as a chip
    component Fact: Rectangle { property string icon; property string text; visible: text !== ""; height: 34; width: factRow.implicitWidth + 26; radius: 17; color: theme.card
        Row { id: factRow; anchors.centerIn: parent; spacing: 7
            Glyph { name: icon; font.pixelSize: 15; color: theme.gold; anchors.verticalCenter: parent.verticalCenter }
            Label { text: parent.parent.text; font.pixelSize: 13; color: theme.dim; anchors.verticalCenter: parent.verticalCenter } } }

    FloatingWindow {
        id: win
        title: i18n.tr("App Manager")
        implicitWidth: 1240; implicitHeight: 800
        color: theme.ground
        onClosed: Qt.quit()

        // ── the side ──────────────────────────────────────────────────────────────────────────────────────
        Rectangle {
            id: side
            width: 250; height: parent.height
            color: theme.surface
            Column {
                x: 14; y: 18; spacing: 4
                Row { x: 6; spacing: 10; height: 40
                    Glyph { name: "cup"; font.pixelSize: 24; color: theme.gold; anchors.verticalCenter: parent.verticalCenter }
                    Label { text: i18n.tr("App Manager"); font.pixelSize: 17; font.weight: 700; anchors.verticalCenter: parent.verticalCenter } }
                Item { width: 1; height: 6 }
                Rectangle {
                    width: 222; height: 40; radius: 20; color: theme.ground; border.color: field.activeFocus ? theme.gold : theme.line; border.width: 1
                    Glyph { x: 13; name: "search"; font.pixelSize: 16; color: theme.dim; anchors.verticalCenter: parent.verticalCenter }
                    TextInput { id: field; x: 38; width: parent.width - 50; anchors.verticalCenter: parent.verticalCenter; color: theme.cream; font.family: theme.font; font.pixelSize: 14; clip: true; selectByMouse: true
                                selectionColor: theme.coffee
                                onAccepted: if (text.trim() !== "") shell.go("search", text.trim()) }
                    Label { x: 38; text: i18n.tr("Search apps…"); color: theme.faint; visible: field.text === "" && !field.activeFocus; anchors.verticalCenter: parent.verticalCenter }
                }
                Item { width: 1; height: 8 }
                Nav { text: i18n.tr("Discover"); icon: "compass"; on: shell.page === "discover"; onPressed: shell.go("discover") }
                Nav { text: i18n.tr("My apps"); icon: "apps"; on: shell.page === "mine"; onPressed: shell.go("mine") }
                Nav { text: i18n.tr("Updates"); icon: "refresh"; on: shell.page === "updates"; badge: shell.waiting; onPressed: shell.go("updates") }
                Item { width: 1; height: 10 }
                Label { x: 14; text: i18n.tr("CATEGORIES"); color: theme.faint; font.pixelSize: 11; font.weight: 700; font.letterSpacing: 0.8 }
                Item { width: 1; height: 2 }
                Repeater { model: shell.categories
                    Nav { required property var modelData; text: i18n.tr(modelData.name); icon: modelData.icon; height: 34
                          on: shell.page === "category" && shell.arg === modelData.id; onPressed: shell.go("category", modelData.id) } }
            }
            // Barista, and under him what is being done right now
            Column {
                x: 14; width: 222; spacing: 10
                anchors.bottom: parent.bottom; anchors.bottomMargin: 14
                Rectangle {
                    visible: shell.job !== null
                    width: 222; height: 58; radius: 14; color: theme.card
                    Glyph { x: 12; y: 11; name: "refresh"; color: theme.gold; font.pixelSize: 16
                            RotationAnimation on rotation { running: shell.job !== null; from: 0; to: 360; duration: 1100; loops: Animation.Infinite } }
                    Label { x: 38; y: 9; width: 174; text: shell.job ? shell.job.name + (shell.queue.length > 0 ? "  +" + shell.queue.length : "") : ""; font.weight: 600; font.pixelSize: 13 }
                    Label { x: 12; y: 32; width: 200; text: shell.job ? shell.job.line : ""; color: theme.dim; font.pixelSize: 12 }
                }
                Rectangle {
                    id: barista
                    width: 222; height: 78; radius: 18
                    gradient: Gradient { orientation: Gradient.Horizontal
                        GradientStop { position: 0; color: shell.page === "barista" ? "#6b4526" : "#4a3020" }
                        GradientStop { position: 1; color: shell.page === "barista" ? "#3d2c22" : "#2a1e17" } }
                    border.color: baristaHit.containsMouse || shell.page === "barista" ? theme.gold : "transparent"; border.width: 1
                    Glyph { x: 14; name: "disc"; font.pixelSize: 26; color: theme.gold; anchors.verticalCenter: parent.verticalCenter }
                    Column { x: 52; width: 160; anchors.verticalCenter: parent.verticalCenter; spacing: 2
                        Label { text: "Barista"; font.weight: 700; font.pixelSize: 15 }
                        Label { text: i18n.tr("Install from a file, a folder or a disc"); color: theme.dim; font.pixelSize: 12; width: parent.width; wrapMode: Text.WordWrap; maximumLineCount: 2 } }
                    MouseArea { id: baristaHit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: shell.go("barista") }
                }
            }
        }

        // ── the pages ─────────────────────────────────────────────────────────────────────────────────────
        Item {
            id: stage
            anchors.left: side.right; anchors.right: parent.right; height: parent.height

            // what went wrong last, until it is pressed away
            Rectangle {
                z: 5; visible: shell.lastError !== ""
                anchors.horizontalCenter: parent.horizontalCenter; y: 12
                width: Math.min(parent.width - 56, oops.implicitWidth + 60); height: 38; radius: 19; color: "#4a1f20"; border.color: theme.red
                Label { id: oops; x: 18; width: parent.width - 50; text: shell.lastError; anchors.verticalCenter: parent.verticalCenter }
                Glyph { name: "x"; font.pixelSize: 14; anchors.right: parent.right; anchors.rightMargin: 14; anchors.verticalCenter: parent.verticalCenter }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: shell.lastError = "" }
            }

            // discover: banners, then the shelves
            Scroll {
                id: discover
                visible: shell.page === "discover"
                Waiting { visible: front.busy && !front.data; text: i18n.tr("Looking what is new…"); width: discover.room; topPadding: 180 }
                Label { visible: front.data && front.data.offline === true; text: i18n.tr("The shop cannot be reached. What is installed and what is to update works without it."); color: theme.dim; width: discover.room; wrapMode: Text.WordWrap; topPadding: 120; horizontalAlignment: Text.AlignHCenter }
                // the banners: two side by side where there is room, turning by themselves
                Item {
                    id: hero
                    readonly property var all: front.data ? front.data.banners : []
                    readonly property int shown: discover.room > 900 ? 2 : 1
                    property int at: 0
                    width: discover.room; height: all.length > 0 ? 300 : 0
                    visible: all.length > 0
                    Timer { interval: 6500; repeat: true; running: hero.visible && shell.page === "discover" && !heroHover.hovered; onTriggered: hero.at = (hero.at + 1) % Math.max(1, hero.all.length) }
                    HoverHandler { id: heroHover }
                    Repeater {
                        model: hero.all
                        ClippingRectangle {
                            id: banner
                            required property var modelData
                            required property int index
                            readonly property int place: (index - hero.at + hero.all.length) % hero.all.length
                            readonly property real each: (hero.width - 16 * (hero.shown - 1)) / hero.shown
                            width: each; height: 280; radius: 26
                            color: theme.card
                            x: place * (each + 16)
                            opacity: place < hero.shown ? 1 : 0
                            visible: opacity > 0.01
                            Behavior on x { NumberAnimation { duration: 520; easing.type: Easing.OutCubic } }
                            Behavior on opacity { NumberAnimation { duration: 380 } }
                            Image { anchors.fill: parent; source: banner.modelData.shot; fillMode: Image.PreserveAspectCrop; asynchronous: true
                                    scale: bannerHit.containsMouse ? 1.05 : 1; Behavior on scale { NumberAnimation { duration: 900; easing.type: Easing.OutCubic } } }
                            Rectangle { anchors.fill: parent; gradient: Gradient {
                                GradientStop { position: 0.0; color: "#0017110d" } GradientStop { position: 0.45; color: "#6617110d" } GradientStop { position: 1.0; color: "#f217110d" } } }
                            MouseArea { id: bannerHit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: shell.go("app", banner.modelData.id) }
                            AppIcon { id: bannerIcon; x: 24; anchors.bottom: parent.bottom; anchors.bottomMargin: 22; icon: banner.modelData.icon; side: 72 }
                            Column { anchors.left: bannerIcon.right; anchors.leftMargin: 16; anchors.right: bannerAct.left; anchors.rightMargin: 12; anchors.bottom: parent.bottom; anchors.bottomMargin: 24; spacing: 3
                                Label { text: banner.modelData.name; font.pixelSize: 24; font.weight: 800; width: parent.width }
                                Label { text: banner.modelData.summary; color: theme.cream; opacity: 0.85; width: parent.width; maximumLineCount: 2; wrapMode: Text.WordWrap } }
                            Act { id: bannerAct; app: banner.modelData; anchors.right: parent.right; anchors.rightMargin: 22; anchors.bottom: parent.bottom; anchors.bottomMargin: 30 }
                        }
                    }
                    Row { anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; spacing: 7
                        Repeater { model: hero.all.length
                            Rectangle { required property int index; width: index === hero.at ? 22 : 7; height: 7; radius: 4; color: index === hero.at ? theme.gold : theme.line
                                        Behavior on width { NumberAnimation { duration: 200 } }
                                        MouseArea { anchors.fill: parent; anchors.margins: -5; cursorShape: Qt.PointingHandCursor; onClicked: hero.at = parent.index } } } }
                }
                Shelf { title: i18n.tr("Trending now"); icon: "flame"; apps: front.data ? front.data.trending : []; room: discover.room }
                Shelf { title: i18n.tr("New arrivals"); icon: "sparkles"; apps: front.data ? front.data["new"] : []; room: discover.room }
                Shelf { title: i18n.tr("Most used"); icon: "star"; apps: front.data ? front.data.popular : []; room: discover.room }
            }

            // a category, or what was searched for
            Scroll {
                id: listing
                readonly property bool searching: shell.page === "search"
                readonly property var from: searching ? found : category
                visible: shell.page === "category" || shell.page === "search"
                Row { spacing: 12
                    Pill { icon: "chevron-left"; text: i18n.tr("Back"); onPressed: shell.back() }
                    Label { anchors.verticalCenter: parent.verticalCenter; font.pixelSize: 22; font.weight: 700
                            text: listing.searching ? i18n.tr("Results for “{what}”", { what: shell.arg }) : i18n.tr((shell.categories.find(c => c.id === shell.arg) || { name: "" }).name) } }
                Waiting { visible: listing.from.busy; text: i18n.tr("Looking…"); width: listing.room; topPadding: 120 }
                Label { visible: !listing.from.busy && listing.from.data && listing.from.data.length === 0; text: i18n.tr("Nothing found"); color: theme.dim; width: listing.room; horizontalAlignment: Text.AlignHCenter; topPadding: 100 }
                Flow { width: listing.room; spacing: 14; visible: !listing.from.busy
                    Repeater { model: listing.from.busy ? [] : (listing.from.data || []); AppCard { required property var modelData; app: modelData } } }
            }

            // one app in full
            Scroll {
                id: about
                readonly property var app: detail.data
                visible: shell.page === "app"
                Pill { icon: "chevron-left"; text: i18n.tr("Back"); onPressed: shell.back() }
                Waiting { visible: !about.app; text: i18n.tr("Looking…"); width: about.room; topPadding: 120 }
                Label { visible: about.app && about.app.missing === true; text: i18n.tr("The shop does not have this app."); color: theme.dim }
                Item {
                    visible: about.app && !about.app.missing
                    width: about.room; height: 110
                    AppIcon { id: bigIcon; icon: about.app ? about.app.icon : ""; side: 104 }
                    Column { anchors.left: bigIcon.right; anchors.leftMargin: 22; anchors.right: acts.left; anchors.rightMargin: 16; anchors.verticalCenter: parent.verticalCenter; spacing: 5
                        Label { text: about.app ? about.app.name : ""; font.pixelSize: 30; font.weight: 800; width: parent.width }
                        Label { text: about.app ? about.app.summary : ""; color: theme.dim; font.pixelSize: 15; width: parent.width; wrapMode: Text.WordWrap; maximumLineCount: 2 }
                        Label { text: about.app ? about.app.developer : ""; color: theme.coffee; font.pixelSize: 13; width: parent.width } }
                    Row { id: acts; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; spacing: 10
                        readonly property bool there: about.app ? (shell.has(about.app.id) || about.app.installed === true) : false
                        readonly property bool busy: about.app ? shell.doing(about.app.id) : false
                        Pill { visible: acts.there && !acts.busy; icon: "player-play"; text: i18n.tr("Open"); strong: true; onPressed: Quickshell.execDetached(["flatpak", "run", about.app.id]) }
                        Pill { visible: acts.there && !acts.busy; icon: "trash"; text: i18n.tr("Remove"); danger: true; onPressed: shell.work("remove", about.app.id, about.app.name) }
                        Pill { visible: !acts.there || acts.busy; busy: acts.busy; icon: acts.busy ? "refresh" : "download"; strong: true; implicitHeight: 44
                               text: acts.busy ? i18n.tr("Working…") : i18n.tr("Install"); onPressed: shell.work("install", about.app.id, about.app.name) } }
                }
                // what is being done to it, as the tool says it
                Rectangle {
                    visible: about.app && shell.job && shell.job.id === about.app.id
                    width: about.room; height: 46; radius: 14; color: theme.card
                    Rectangle { height: 3; radius: 2; color: theme.gold; y: parent.height - 3; width: parent.width * 0.3
                                SequentialAnimation on x { loops: Animation.Infinite; NumberAnimation { from: 0; to: about.room * 0.7; duration: 1200; easing.type: Easing.InOutQuad } NumberAnimation { from: about.room * 0.7; to: 0; duration: 1200; easing.type: Easing.InOutQuad } } }
                    Label { x: 16; width: parent.width - 32; text: shell.job ? shell.job.line : ""; color: theme.dim; anchors.verticalCenter: parent.verticalCenter }
                }
                Flow { visible: about.app && !about.app.missing; width: about.room; spacing: 10
                    Fact { icon: "download"; text: about.app && about.app.installs > 0 ? i18n.tr("{n} a month", { n: shell.count(about.app.installs) }) : "" }
                    Fact { icon: "package"; text: about.app && about.app.size > 0 ? shell.megabytes(about.app.size) : "" }
                    Fact { icon: "sparkles"; text: about.app && about.app.version ? about.app.version : "" }
                    Fact { icon: "shield-check"; text: about.app && about.app.license ? about.app.license : "" }
                    Fact { icon: "world-www"; text: about.app && about.app.homepage ? about.app.homepage.replace(/^https?:\/\//, "").replace(/\/$/, "") : ""
                           MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Quickshell.execDetached(["xdg-open", about.app.homepage]) } }
                }
                ListView {
                    visible: about.app && (about.app.screenshots || []).length > 0
                    width: about.room; height: 300; orientation: ListView.Horizontal; spacing: 14; clip: true
                    model: about.app ? (about.app.screenshots || []) : []
                    boundsBehavior: Flickable.StopAtBounds
                    delegate: ClippingRectangle { required property string modelData; width: 520; height: 300; radius: 18; color: theme.card
                        id: shot
                        Image { anchors.fill: parent; source: shot.modelData; fillMode: Image.PreserveAspectFit; asynchronous: true } }
                }
                Label { visible: about.app && !about.app.missing; text: about.app ? about.app.description : ""; width: Math.min(about.room, 820); wrapMode: Text.WordWrap; elide: Text.ElideNone; color: theme.cream; opacity: 0.92; lineHeight: 1.4; font.pixelSize: 15 }
            }

            // what is installed
            Scroll {
                id: owned
                property string only: ""               // one source, or all of them
                readonly property var apps: (mine.data || []).filter(a => only === "" || shell.sources[a.source] === only)
                visible: shell.page === "mine"
                Row { spacing: 12
                    Label { text: i18n.tr("My apps"); font.pixelSize: 26; font.weight: 800; anchors.verticalCenter: parent.verticalCenter }
                    Label { text: owned.apps.length; color: theme.faint; font.pixelSize: 18; anchors.verticalCenter: parent.verticalCenter } }
                Row { spacing: 8
                    Repeater { model: ["", "Flatpak", "Fedora", "Local"]
                        Pill { required property string modelData; text: modelData === "" ? i18n.tr("All") : modelData; strong: owned.only === modelData; onPressed: owned.only = modelData } } }
                Column { width: owned.room; spacing: 6
                    Repeater { model: owned.apps
                        Rectangle { id: line; required property var modelData; width: owned.room; height: 62; radius: 14; color: lineHit.hovered ? theme.card : "transparent"
                            HoverHandler { id: lineHit }
                            AppIcon { id: lineIcon; x: 12; icon: line.modelData.icon; side: 40; anchors.verticalCenter: parent.verticalCenter }
                            Column { anchors.left: lineIcon.right; anchors.leftMargin: 14; anchors.right: lineEnd.left; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter; spacing: 2
                                Label { text: line.modelData.name; font.weight: 600; width: parent.width }
                                Label { text: line.modelData.summary; color: theme.dim; font.pixelSize: 12; width: parent.width; visible: text !== "" } }
                            Row { id: lineEnd; anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter; spacing: 12
                                Label { text: line.modelData.size; color: theme.faint; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                                Rectangle { width: tag.implicitWidth + 16; height: 22; radius: 11; color: theme.raised; anchors.verticalCenter: parent.verticalCenter
                                    Label { id: tag; text: shell.sources[line.modelData.source] || line.modelData.source; font.pixelSize: 11; color: theme.dim; anchors.centerIn: parent } }
                                Pill { visible: line.modelData.removable; busy: shell.doing(line.modelData.id); icon: busy ? "refresh" : "trash"; text: i18n.tr("Remove"); danger: true; implicitHeight: 32
                                       onPressed: shell.work("remove", line.modelData.id, line.modelData.name) } } } } }
            }

            // what can be updated
            Scroll {
                id: news
                readonly property var apps: fresh.data ? fresh.data.apps : []
                readonly property int system: fresh.data ? fresh.data.system : 0
                visible: shell.page === "updates"
                Row { spacing: 14
                    Label { text: i18n.tr("Updates"); font.pixelSize: 26; font.weight: 800; anchors.verticalCenter: parent.verticalCenter }
                    Pill { visible: news.apps.length > 0; strong: true; icon: "download"; text: i18n.tr("Update all apps"); busy: shell.doing("", "update"); onPressed: shell.work("update", "", i18n.tr("All apps")) }
                    Pill { icon: "refresh"; text: i18n.tr("Look again"); busy: fresh.busy; onPressed: fresh.ask(["updates"]) } }
                Waiting { visible: fresh.busy && !fresh.data; text: i18n.tr("Looking what is new…"); width: news.room; topPadding: 100 }
                Column { visible: fresh.data && news.apps.length === 0 && news.system === 0; width: news.room; spacing: 10; topPadding: 90
                    Glyph { name: "circle-check"; font.pixelSize: 54; color: theme.ok; anchors.horizontalCenter: parent.horizontalCenter }
                    Label { text: i18n.tr("Everything is up to date"); font.pixelSize: 18; font.weight: 600; anchors.horizontalCenter: parent.horizontalCenter } }
                Rectangle { visible: news.system > 0; width: news.room; height: 72; radius: 16; color: theme.card
                    Glyph { x: 18; name: "settings"; font.pixelSize: 26; color: theme.gold; anchors.verticalCenter: parent.verticalCenter }
                    Column { x: 60; anchors.verticalCenter: parent.verticalCenter; spacing: 2
                        Label { text: i18n.tr("The system (Fedora)"); font.weight: 600 }
                        Label { text: i18n.tr("{n} packages", { n: news.system }); color: theme.dim; font.pixelSize: 12 } }
                    Pill { anchors.right: parent.right; anchors.rightMargin: 16; anchors.verticalCenter: parent.verticalCenter; icon: busy ? "refresh" : "download"; text: i18n.tr("Update"); busy: shell.doing("", "update-system")
                           onPressed: shell.work("update-system", "", i18n.tr("The system (Fedora)")) } }
                Column { width: news.room; spacing: 6
                    Repeater { model: news.apps
                        Rectangle { id: upd; required property var modelData; width: news.room; height: 62; radius: 14; color: theme.card
                            AppIcon { id: updIcon; x: 12; icon: upd.modelData.icon; side: 40; anchors.verticalCenter: parent.verticalCenter }
                            Column { anchors.left: updIcon.right; anchors.leftMargin: 14; anchors.verticalCenter: parent.verticalCenter; spacing: 2
                                Label { text: upd.modelData.name; font.weight: 600 }
                                Label { text: upd.modelData.version; color: theme.dim; font.pixelSize: 12; visible: text !== "" } }
                            Pill { anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter; icon: busy ? "refresh" : "download"; text: i18n.tr("Update"); busy: shell.doing(upd.modelData.id); implicitHeight: 32
                                   onPressed: shell.work("update", upd.modelData.id, upd.modelData.name) } } } }
            }

            // Barista: what no shop has
            Scroll {
                id: bar
                visible: shell.page === "barista"
                Rectangle {
                    width: bar.room; height: 190; radius: 26
                    gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: "#6b4526" } GradientStop { position: 1; color: "#2a1e17" } }
                    Glyph { x: 34; name: "disc"; font.pixelSize: 84; color: theme.gold; anchors.verticalCenter: parent.verticalCenter }
                    Column { x: 150; width: parent.width - 190; anchors.verticalCenter: parent.verticalCenter; spacing: 8
                        Label { text: "Barista"; font.pixelSize: 32; font.weight: 800 }
                        Label { text: i18n.tr("Installs what no shop has: a game on discs, a Windows installer, a folder that only needs to be run, an Android app. He looks at what it is first and says whether it will work, and why."); width: parent.width; wrapMode: Text.WordWrap; color: theme.cream; opacity: 0.9; lineHeight: 1.3 } }
                }
                Label { text: i18n.tr("WHAT HE WILL TAKE"); color: theme.faint; font.pixelSize: 11; font.weight: 700; font.letterSpacing: 0.8 }
                Flow { width: bar.room; spacing: 14
                    Repeater { model: [
                            { icon: "disc", name: QT_TR_NOOP("A CD or DVD, or its image"), hint: QT_TR_NOOP(".iso, several discs") }, { icon: "brand-windows", name: QT_TR_NOOP("A Windows installer or program"), hint: QT_TR_NOOP("setup.exe, .msi, .exe") },
                            { icon: "file-zip", name: QT_TR_NOOP("An archive"), hint: QT_TR_NOOP(".zip, .rar, .7z, in parts too") }, { icon: "folder", name: QT_TR_NOOP("A folder with a game or an app"), hint: QT_TR_NOOP("also on another disk") },
                            { icon: "brand-android", name: QT_TR_NOOP("An Android app"), hint: QT_TR_NOOP(".apk, .xapk") }, { icon: "package", name: QT_TR_NOOP("A Linux package"), hint: QT_TR_NOOP(".rpm, .flatpak, .AppImage") }]
                        Rectangle { required property var modelData; width: Math.floor((bar.room - 28) / 3); height: 84; radius: 18; color: theme.card
                            Glyph { x: 18; name: parent.modelData.icon; font.pixelSize: 28; color: theme.coffee; anchors.verticalCenter: parent.verticalCenter }
                            Column { x: 62; width: parent.width - 76; anchors.verticalCenter: parent.verticalCenter; spacing: 3
                                Label { text: i18n.tr(parent.parent.modelData.name); font.weight: 600; width: parent.width; wrapMode: Text.WordWrap; maximumLineCount: 2 }
                                Label { text: i18n.tr(parent.parent.modelData.hint); color: theme.dim; font.pixelSize: 12; width: parent.width } } } } }
                Rectangle { width: bar.room; height: 52; radius: 16; color: theme.card; border.color: theme.line
                    Glyph { x: 16; name: "clock-hour-4"; color: theme.gold; anchors.verticalCenter: parent.verticalCenter }
                    Label { x: 46; width: parent.width - 60; text: i18n.tr("Barista is being prepared: he is not behind the bar yet."); color: theme.dim; anchors.verticalCenter: parent.verticalCenter } }
            }
        }
    }
}
