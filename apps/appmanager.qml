// App Manager: the shop, what is installed, what can be updated, and Barista, who installs what no shop has.
// bin/latte-apps knows and does everything; this window shows it. Where it begins is told in words
// (bin/latte-app):   latte-app appmanager [updates | mine | barista [SOURCE…] | app ID]
//
// The pages: discover (banners and shelves) · category · search · app (one in full) · mine · updates · barista.
// One thing is installed, removed or updated at a time; the rest wait in a queue, shown at the bottom of the side.
import QtQuick
import QtQuick.Dialogs
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import "common"

ShellRoot {
    id: shell
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
    // ── Barista: the wizard's state. bin/latte-barista knows and does; docs/barista/POSTUP.md says in what order.
    property int bStep: 1                      // 1 what · 2 will it work · 3 where and how · 4 installing, then trying · 5 done
    property var bSources: []
    property var bInfo: null                   // what analyze said
    property var bOnline: null                 // what the internet said, once the user allowed asking
    property bool bNetwork: false
    property var bProgress: null
    property string bError: ""
    property bool bInstalled: false
    property var bFound: null                  // what the last run's log says, after "it did not work"
    property var bConsole: []                  // every command the installation ran and what it said
    property bool bConsoleOut: false           // …shown when asked for
    property var bPlace: null                  // info of the installed one: folder, logs
    function bReset() { bStep = 1; bSources = []; bInfo = null; bOnline = null; bProgress = null; bError = ""; bInstalled = false; bFound = null; bPlace = null }
    function bTake(paths) { if (!paths.length) return; bSources = paths; bInfo = null; bOnline = null; bStep = 2; bAnalyze.running = false; bAnalyze.command = ["latte-barista", "analyze"].concat(paths); bAnalyze.running = true }
    function bBytes(n) { return n >= 1073741824 ? (n / 1073741824).toFixed(1) + " GB" : Math.round(n / 1048576) + " MB" }
    readonly property var bSteps: ({ "reading": QT_TR_NOOP("Reading {what}"), "windows": QT_TR_NOOP("Preparing a Windows of its own"), "unpacking": QT_TR_NOOP("Unpacking {what}"),
                                     "copying": QT_TR_NOOP("Copying files"), "writing": QT_TR_NOOP("Writing it down") })
    readonly property var bWhy: ({ "missing-dll": QT_TR_NOOP("A library is missing: {detail}. It can be added to this program's Windows."), "direct3d": QT_TR_NOOP("The graphics failed. Another way of drawing can be tried."),
                                   "wants-disc": QT_TR_NOOP("It asks for its disc. The disc image can be put in as a drive."), "crashed": QT_TR_NOOP("The program crashed."),
                                   "nothing": QT_TR_NOOP("Its log names no cause I know.") })
    Process { id: bAnalyze; stdout: StdioCollector { onStreamFinished: { try { shell.bInfo = JSON.parse(this.text); shell.bNetwork = shell.bInfo.network === true } catch (e) { shell.bInfo = { verdict: "no", reasons: [], sources: [] } } } } }
    Process { id: bAsk; stdout: StdioCollector { onStreamFinished: { try { shell.bOnline = JSON.parse(this.text) } catch (e) { shell.bOnline = { ok: false, lutris: [] } } } } }
    Process { id: bInstall
        stdout: SplitParser { onRead: line => { let m = null; try { m = JSON.parse(line) } catch (e) { return }
            if (m.console !== undefined) { const c = shell.bConsole.slice(-400); c.push(m.console); shell.bConsole = c }
            else if (m.step) shell.bProgress = m
            else if (m.ok) { shell.bInstalled = true; bInfoOf.running = false; bInfoOf.command = ["latte-barista", "info", m.id]; bInfoOf.running = true }
            else shell.bError = m.error || "?" } } }
    Process { id: bInfoOf; stdout: StdioCollector { onStreamFinished: { try { shell.bPlace = JSON.parse(this.text) } catch (e) {} } } }
    Process { id: bWorked; stdout: StdioCollector { onStreamFinished: { try { const r = JSON.parse(this.text); if (r.found) shell.bFound = r.found; else shell.bStep = 5 } catch (e) {} } } }
    FileDialog { id: bFiles; fileMode: FileDialog.OpenFiles; onAccepted: shell.bTake(selectedFiles.map(u => decodeURIComponent(String(u).replace(/^file:\/\//, "")))) }
    FolderDialog { id: bFolder; onAccepted: shell.bTake([decodeURIComponent(String(selectedFolder).replace(/^file:\/\//, ""))]) }
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
            shell.lastError = code === 0 ? "" : I18n.tr("{name}: it did not work", { name: shell.job ? shell.job.name : "" }) + (shell.job && shell.job.line ? " — " + shell.job.line : "")
            shell.job = null
            shell.reload()
            if (shell.page === "app") detail.ask(["store", "app", shell.arg])
            shell.next()
        }
    }

    Component.onCompleted: {
        front.ask(["store", "home"])
        reload()
        if (words[0] === "updates" || words[0] === "mine" || words[0] === "barista") shell.go(words[0], "", true)
        if (words[0] === "barista" && words.length > 1) shell.bTake(words.slice(1))      // latte-app appmanager barista SOURCE…
        else if (words[0] === "app" && words[1]) shell.go("app", words[1], true)
    }

    readonly property var categories: [
        { id: "game", name: QT_TR_NOOP("Games"), icon: "device-gamepad-2" }, { id: "audiovideo", name: QT_TR_NOOP("Music and video"), icon: "music" },
        { id: "graphics", name: QT_TR_NOOP("Graphics and photos"), icon: "palette" }, { id: "office", name: QT_TR_NOOP("Office"), icon: "file-text" },
        { id: "network", name: QT_TR_NOOP("Internet"), icon: "world" }, { id: "development", name: QT_TR_NOOP("Development"), icon: "code" },
        { id: "education", name: QT_TR_NOOP("Education"), icon: "school" }, { id: "science", name: QT_TR_NOOP("Science"), icon: "flask" },
        { id: "system", name: QT_TR_NOOP("System"), icon: "settings" }, { id: "utility", name: QT_TR_NOOP("Tools"), icon: "tool" },
        { id: "healthfitness", name: QT_TR_NOOP("Health"), icon: "heart" }]
    readonly property var sources: ({ "flatpak": "Flatpak", "flatpak-system": "Flatpak", "rpm": "Fedora", "local": "Local" })
    function count(n) { return n >= 1000000 ? (n / 1000000).toFixed(1) + " M" : (n >= 1000 ? Math.round(n / 1000) + " k" : String(n)) }
    function megabytes(bytes) { return bytes >= 1073741824 ? (bytes / 1073741824).toFixed(1) + " GB" : Math.max(1, Math.round(bytes / 1048576)) + " MB" }
    function picture(icon) { return !icon ? "" : (icon.startsWith("http") ? icon : (icon.startsWith("/") ? "file://" + icon : Quickshell.iconPath(icon, true))) }

    // an app's icon, or a box where it has none (or is still on its way)
    component AppIcon: Item {
        property string icon
        property real side: 56
        width: side; height: side
        Rectangle { anchors.fill: parent; radius: side * 0.24; color: Theme.raised; visible: face.status !== Image.Ready
            Glyph { anchors.centerIn: parent; name: "package"; font.pixelSize: parent.width * 0.5; color: Theme.faint } }
        Image { id: face; anchors.fill: parent; source: shell.picture(icon); sourceSize.width: side * 2; sourceSize.height: side * 2
                fillMode: Image.PreserveAspectFit; asynchronous: true; smooth: true }
    }
    // what is to be done with an app: install it, or it is there
    component Act: Pill {
        property var app
        readonly property bool there: shell.has(app.id) || app.installed === true
        busy: shell.doing(app.id)
        strong: !there
        icon: busy ? "refresh" : (there ? "circle-check" : "download")
        text: busy ? I18n.tr("Working…") : (there ? I18n.tr("Installed") : I18n.tr("Install"))
        onPressed: there ? shell.go("app", app.id) : shell.work("install", app.id, app.name)
    }
    // An app as a poster: its icon on a tile of a colour of its own, its name under it. The colour is told from
    // the app's id, so that an app has the same one wherever it shows.
    readonly property var tints: ["#3a2a20", "#2c3833", "#3a2c38", "#2b3440", "#40352a", "#33302a", "#2f2a3a", "#39302b"]
    function tint(id) { let h = 0; for (let i = 0; i < id.length; i++) h = (h * 31 + id.charCodeAt(i)) % 9973; return tints[h % tints.length] }
    component Poster: Column {
        id: poster
        property var app
        property real side: 150
        width: side; spacing: 8
        Rectangle { width: poster.side; height: poster.side; radius: 22; color: shell.tint(poster.app.id)
            border.width: 1; border.color: over.containsMouse ? Qt.rgba(0.97, 0.78, 0.45, 0.6) : "transparent"
            scale: over.containsMouse ? 1.04 : 1
            Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
            AppIcon { anchors.centerIn: parent; icon: poster.app.icon; side: poster.side * 0.64 }
            Rectangle { visible: shell.has(poster.app.id); width: 24; height: 24; radius: 12; color: Theme.ok; x: parent.width - 32; y: 8
                Glyph { anchors.centerIn: parent; name: "check"; font.pixelSize: 14; color: Theme.ground } }
            MouseArea { id: over; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: shell.go("app", poster.app.id) } }
        Label { text: poster.app.name; font.weight: 700; width: parent.width }
        Row { spacing: 5; width: parent.width
            Label { text: poster.app.developer || "Flathub"; color: Theme.faint; font.pixelSize: 12; width: Math.min(implicitWidth, poster.side - 62) }
            Label { text: "•"; color: Theme.faint; font.pixelSize: 12; visible: (poster.app.installs || 0) > 0 }
            Glyph { name: "download"; font.pixelSize: 12; color: Theme.gold; anchors.verticalCenter: parent.verticalCenter; visible: (poster.app.installs || 0) > 0 }
            Label { text: shell.count(poster.app.installs || 0); font.pixelSize: 12; font.weight: 700; visible: (poster.app.installs || 0) > 0 } }
    }
    // a row of posters, as many as fit across, the rest below
    component Posters: Flow {
        property var apps: []
        property real room: 800
        readonly property int across: Math.max(2, Math.floor((room + 18) / 168))
        width: room; spacing: 18
        Repeater { model: apps; Poster { required property var modelData; app: modelData; side: Math.floor((room - 18 * (across - 1)) / across) } }
    }
    // a word on a picture
    component Tag: Rectangle { property string text; visible: text !== ""; height: 28; width: tagText.implicitWidth + 22; radius: 14; color: "#99241a14"; border.color: "#33f3ebdd"
        Label { id: tagText; anchors.centerIn: parent; text: parent.text; font.pixelSize: 12 } }
    // one of the rows to choose from
    component Choice: Rectangle { id: choice; property string text; property bool on: false; signal pressed()
        height: 40; width: choiceText.implicitWidth + 34; radius: 20
        color: on ? Theme.cream : (choiceHit.containsMouse ? Theme.raised : Theme.card)
        Behavior on color { ColorAnimation { duration: 120 } }
        Label { id: choiceText; anchors.centerIn: parent; text: choice.text; color: choice.on ? Theme.ground : Theme.cream; font.weight: choice.on ? 700 : 400 }
        MouseArea { id: choiceHit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: choice.pressed() } }

    // one thing known about an app, as a chip
    component Fact: Rectangle { property string icon; property string text; visible: text !== ""; height: 34; width: factRow.implicitWidth + 26; radius: 17; color: Theme.card
        Row { id: factRow; anchors.centerIn: parent; spacing: 7
            Glyph { name: icon; font.pixelSize: 15; color: Theme.gold; anchors.verticalCenter: parent.verticalCenter }
            Label { text: parent.parent.text; font.pixelSize: 13; color: Theme.dim; anchors.verticalCenter: parent.verticalCenter } } }

    readonly property string where: page === "discover" ? I18n.tr("Discover") : page === "mine" ? I18n.tr("My apps") : page === "updates" ? I18n.tr("Updates")
        : page === "barista" ? "Barista" : page === "search" ? I18n.tr("Results for “{what}”", { what: arg })
        : page === "category" ? I18n.tr((categories.find(c => c.id === arg) || { name: "" }).name) : (detail.data && detail.data.name ? detail.data.name : "")

    AppWindow {
        id: win
        title: I18n.tr("App Manager")
        heading: shell.where
        implicitWidth: 1240; implicitHeight: 800
        arrows: true; canGoBack: shell.trail.length > 0 || shell.page !== "discover"; onBack: shell.back()
        searchHint: I18n.tr("Search apps…"); onSearched: text => shell.go("search", text)

        // ── the side ──────────────────────────────────────────────────────────────────────────────────────
        side: [
            Column {
                x: 14; y: 14; spacing: 4
                Row { x: 6; spacing: 10; height: 40
                    Glyph { name: "cup"; font.pixelSize: 24; color: Theme.gold; anchors.verticalCenter: parent.verticalCenter }
                    Label { text: I18n.tr("App Manager"); font.pixelSize: 17; font.weight: 700; anchors.verticalCenter: parent.verticalCenter } }
                Item { width: 1; height: 8 }
                Nav { text: I18n.tr("Discover"); icon: "compass"; on: shell.page === "discover"; onPressed: shell.go("discover") }
                Nav { text: I18n.tr("My apps"); icon: "apps"; on: shell.page === "mine"; onPressed: shell.go("mine") }
                Nav { text: I18n.tr("Updates"); icon: "refresh"; on: shell.page === "updates"; badge: shell.waiting; onPressed: shell.go("updates") }
                Item { width: 1; height: 10 }
                Label { x: 14; text: I18n.tr("CATEGORIES"); color: Theme.faint; font.pixelSize: 11; font.weight: 700; font.letterSpacing: 0.8 }
                Item { width: 1; height: 2 }
                Repeater { model: shell.categories
                    Nav { required property var modelData; text: I18n.tr(modelData.name); icon: modelData.icon; height: 34
                          on: shell.page === "category" && shell.arg === modelData.id; onPressed: shell.go("category", modelData.id) } }
            }
        ]

        // ── in the coffee: Barista, and what is being done right now ─────────────────────────────────────
        foot: [
            Item { x: 24; width: baristaRow.implicitWidth; height: 44; anchors.verticalCenter: parent.verticalCenter
                Row { id: baristaRow; spacing: 12; anchors.verticalCenter: parent.verticalCenter
                    Glyph { name: "disc"; font.pixelSize: 24; color: Theme.gold; anchors.verticalCenter: parent.verticalCenter }
                    Label { text: "Barista"; color: Theme.inkOnCoffee; font.weight: 800; font.pixelSize: 15; anchors.verticalCenter: parent.verticalCenter }
                    Label { text: I18n.tr("Install from a file, a folder or a disc"); color: "#e0c9b1"; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter } }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: shell.go("barista") } },
            Row { visible: shell.job !== null; anchors.right: parent.right; anchors.rightMargin: 24; anchors.verticalCenter: parent.verticalCenter; spacing: 10
                Glyph { id: spin; name: "refresh"; color: Theme.gold; font.pixelSize: 16; anchors.verticalCenter: parent.verticalCenter
                        NumberAnimation on rotation { running: shell.job !== null; from: 0; to: 360; duration: 1100; loops: Animation.Infinite } }
                Label { text: shell.job ? shell.job.name + (shell.queue.length > 0 ? "  +" + shell.queue.length : "") : ""; color: Theme.inkOnCoffee; font.weight: 700; anchors.verticalCenter: parent.verticalCenter }
                Label { text: shell.job ? shell.job.line : ""; color: "#e0c9b1"; font.pixelSize: 12; width: Math.min(implicitWidth, 420); anchors.verticalCenter: parent.verticalCenter } }
        ]

        // ── the pages ─────────────────────────────────────────────────────────────────────────────────────
            // what went wrong last, until it is pressed away
            Rectangle {
                z: 5; visible: shell.lastError !== ""
                anchors.horizontalCenter: parent.horizontalCenter; y: 12
                width: Math.min(parent.width - 56, oops.implicitWidth + 60); height: 38; radius: 19; color: "#4a1f20"; border.color: Theme.red
                Label { id: oops; x: 18; width: parent.width - 50; text: shell.lastError; anchors.verticalCenter: parent.verticalCenter }
                Glyph { name: "x"; font.pixelSize: 14; anchors.right: parent.right; anchors.rightMargin: 14; anchors.verticalCenter: parent.verticalCenter }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: shell.lastError = "" }
            }

            // discover, as a streaming menu: one big banner with the next looking in, rows to choose from, posters
            Scroll {
                id: discover
                property string row: "trending"
                visible: shell.page === "discover"
                Waiting { visible: front.busy && !front.data; text: I18n.tr("Looking what is new…"); width: discover.room; topPadding: 180 }
                Label { visible: front.data && front.data.offline === true; text: I18n.tr("The shop cannot be reached. What is installed and what is to update works without it."); color: Theme.dim; width: discover.room; wrapMode: Text.WordWrap; topPadding: 120; horizontalAlignment: Text.AlignHCenter }
                Item {
                    id: hero
                    readonly property var all: front.data ? front.data.banners : []
                    readonly property real each: width - 130
                    // the banner in front, the one it came from, and how far the picture has changed (0…1)
                    property int at: 0
                    property int was: 0
                    property real changed: 1
                    readonly property var now: all[at] || null
                    function show(n) { if (n === at || all.length === 0) return; was = at; at = n; change.restart() }
                    function turn() { show((at + 1) % Math.max(1, all.length)) }
                    function shot(n) { const b = all[((n % all.length) + all.length) % all.length]; return b ? b.shot : "" }
                    NumberAnimation { id: change; target: hero; property: "changed"; from: 0; to: 1; duration: 1100; easing.type: Easing.InOutSine }
                    width: discover.room; height: all.length > 0 ? 300 : 0; clip: true
                    visible: all.length > 0
                    Timer { interval: 7000; repeat: true; running: hero.visible && shell.page === "discover" && !heroHover.hovered; onTriggered: hero.turn() }
                    HoverHandler { id: heroHover }
                    // every banner's picture is fetched before its turn comes, or it would pop in half way through
                    Repeater { model: hero.all; Image { required property var modelData; width: 1; height: 1; opacity: 0; asynchronous: true; source: modelData.shot } }
                    // the one looking in from the right: the next
                    ClippingRectangle {
                        x: hero.each + 16; y: 22; width: hero.each; height: 256; radius: 24; color: Theme.card
                        Reveal { anchors.fill: parent; from: hero.shot(hero.was + 1); to: hero.shot(hero.at + 1); progress: hero.changed; kind: (hero.at + 1) % 3 }
                        Rectangle { anchors.fill: parent; color: Theme.ground; opacity: 0.5 }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: hero.turn() }
                    }
                    ClippingRectangle {
                        id: banner
                        readonly property var b: hero.now || ({ id: "", name: "", summary: "", developer: "", verified: false, installs: 0 })
                        // what is written on it goes out with the old picture and comes in with the new
                        readonly property real said: Math.min(1, Math.abs(hero.changed - 0.5) * 2.4)
                        width: hero.each; height: 300; radius: 24; color: Theme.card
                        Reveal { anchors.fill: parent; from: hero.shot(hero.was); to: hero.shot(hero.at); progress: hero.changed; kind: hero.at % 3
                                 scale: bannerHit.containsMouse ? 1.04 : 1; Behavior on scale { NumberAnimation { duration: 900; easing.type: Easing.OutCubic } } }
                        Rectangle { anchors.fill: parent; gradient: Gradient {
                            GradientStop { position: 0.0; color: "#5517110d" } GradientStop { position: 0.5; color: "#2217110d" } GradientStop { position: 1.0; color: "#f017110d" } } }
                        MouseArea { id: bannerHit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: shell.go("app", banner.b.id) }
                        Row { x: 18; y: 18; spacing: 8; opacity: banner.said
                            Tag { text: banner.b.developer }
                            Tag { text: banner.b.verified ? I18n.tr("Verified") : "" }
                            Tag { text: banner.b.installs > 0 ? I18n.tr("{n} a month", { n: shell.count(banner.b.installs) }) : "" } }
                        // the round button: the thing to do with it
                        Rectangle { id: go; x: 22; y: parent.height - 74; width: 52; height: 52; radius: 26
                            readonly property bool there: shell.has(banner.b.id)
                            color: goHit.containsMouse ? Theme.gold : Theme.cream
                            scale: goHit.pressed ? 0.94 : 1
                            Glyph { anchors.centerIn: parent; name: shell.doing(banner.b.id) ? "refresh" : (go.there ? "player-play" : "download"); color: Theme.ground; font.pixelSize: 22
                                    NumberAnimation on rotation { running: shell.doing(banner.b.id); from: 0; to: 360; duration: 1100; loops: Animation.Infinite } }
                            MouseArea { id: goHit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: go.there ? Quickshell.execDetached(["flatpak", "run", banner.b.id]) : shell.work("install", banner.b.id, banner.b.name) } }
                        Column { x: 88; y: parent.height - 76; width: parent.width - 120; spacing: 3; opacity: banner.said
                            // the words change when the picture is half way
                            readonly property var b: hero.changed < 0.5 ? (hero.all[hero.was] || banner.b) : banner.b
                            Label { text: parent.b.name; font.pixelSize: 25; font.weight: 800; width: parent.width }
                            Label { text: (shell.has(parent.b.id) ? I18n.tr("Open") : I18n.tr("Install")) + "  ·  " + parent.b.summary; color: "#e6dccf"; font.pixelSize: 13; width: parent.width } }
                    }
                    Row { anchors.right: parent.right; anchors.rightMargin: 4; y: 4; spacing: 6
                        Repeater { model: hero.all.length
                            Rectangle { required property int index; width: index === hero.at ? 18 : 6; height: 6; radius: 3; color: index === hero.at ? Theme.cream : "#55f3ebdd"
                                        Behavior on width { NumberAnimation { duration: 200 } }
                                        MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; onClicked: hero.show(parent.index) } } } }
                }
                Flow { width: discover.room; spacing: 10; visible: front.data && !front.data.offline
                    Choice { text: I18n.tr("Trending now"); on: discover.row === "trending"; onPressed: discover.row = "trending" }
                    Choice { text: I18n.tr("New arrivals"); on: discover.row === "new"; onPressed: discover.row = "new" }
                    Choice { text: I18n.tr("Most used"); on: discover.row === "popular"; onPressed: discover.row = "popular" }
                    Repeater { model: shell.categories.slice(0, 4)
                        Choice { required property var modelData; text: I18n.tr(modelData.name); onPressed: shell.go("category", modelData.id) } } }
                Posters { apps: front.data ? (front.data[discover.row] || []) : []; room: discover.room }
            }

            // a category, or what was searched for
            Scroll {
                id: listing
                readonly property var from: shell.page === "search" ? found : category
                visible: shell.page === "category" || shell.page === "search"
                Waiting { visible: listing.from.busy; text: I18n.tr("Looking…"); width: listing.room; topPadding: 120 }
                Label { visible: !listing.from.busy && listing.from.data && listing.from.data.length === 0; text: I18n.tr("Nothing found"); color: Theme.dim; width: listing.room; horizontalAlignment: Text.AlignHCenter; topPadding: 100 }
                Posters { apps: listing.from.busy ? [] : (listing.from.data || []); room: listing.room; visible: !listing.from.busy }
            }

            // one app in full
            Scroll {
                id: about
                readonly property var app: detail.data
                visible: shell.page === "app"
                Waiting { visible: !about.app; text: I18n.tr("Looking…"); width: about.room; topPadding: 120 }
                Label { visible: about.app && about.app.missing === true; text: I18n.tr("The shop does not have this app."); color: Theme.dim }
                Item {
                    visible: about.app && !about.app.missing
                    width: about.room; height: 110
                    AppIcon { id: bigIcon; icon: about.app ? about.app.icon : ""; side: 104 }
                    Column { anchors.left: bigIcon.right; anchors.leftMargin: 22; anchors.right: acts.left; anchors.rightMargin: 16; anchors.verticalCenter: parent.verticalCenter; spacing: 5
                        Label { text: about.app ? about.app.name : ""; font.pixelSize: 30; font.weight: 800; width: parent.width }
                        Label { text: about.app ? about.app.summary : ""; color: Theme.dim; font.pixelSize: 15; width: parent.width; wrapMode: Text.WordWrap; maximumLineCount: 2 }
                        Label { text: about.app ? about.app.developer : ""; color: Theme.coffee; font.pixelSize: 13; width: parent.width } }
                    Row { id: acts; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; spacing: 10
                        readonly property bool there: about.app ? (shell.has(about.app.id) || about.app.installed === true) : false
                        readonly property bool busy: about.app ? shell.doing(about.app.id) : false
                        Pill { visible: acts.there && !acts.busy; icon: "player-play"; text: I18n.tr("Open"); strong: true; onPressed: Quickshell.execDetached(["flatpak", "run", about.app.id]) }
                        Pill { visible: acts.there && !acts.busy; icon: "trash"; text: I18n.tr("Remove"); danger: true; onPressed: shell.work("remove", about.app.id, about.app.name) }
                        Pill { visible: !acts.there || acts.busy; busy: acts.busy; icon: acts.busy ? "refresh" : "download"; strong: true; implicitHeight: 44
                               text: acts.busy ? I18n.tr("Working…") : I18n.tr("Install"); onPressed: shell.work("install", about.app.id, about.app.name) } }
                }
                // what is being done to it, as the tool says it
                Rectangle {
                    visible: about.app && shell.job && shell.job.id === about.app.id
                    width: about.room; height: 46; radius: 14; color: Theme.card
                    Rectangle { height: 3; radius: 2; color: Theme.gold; y: parent.height - 3; width: parent.width * 0.3
                                SequentialAnimation on x { loops: Animation.Infinite; NumberAnimation { from: 0; to: about.room * 0.7; duration: 1200; easing.type: Easing.InOutQuad } NumberAnimation { from: about.room * 0.7; to: 0; duration: 1200; easing.type: Easing.InOutQuad } } }
                    Label { x: 16; width: parent.width - 32; text: shell.job ? shell.job.line : ""; color: Theme.dim; anchors.verticalCenter: parent.verticalCenter }
                }
                Flow { visible: about.app && !about.app.missing; width: about.room; spacing: 10
                    Fact { icon: "download"; text: about.app && about.app.installs > 0 ? I18n.tr("{n} a month", { n: shell.count(about.app.installs) }) : "" }
                    Fact { icon: "package"; text: about.app && about.app.size > 0 ? shell.megabytes(about.app.size) : "" }
                    Fact { icon: "sparkles"; text: about.app && about.app.version ? about.app.version : "" }
                    Fact { icon: "shield-check"; text: about.app && about.app.license ? about.app.license : "" }
                    Fact { icon: "world"; text: about.app && about.app.homepage ? about.app.homepage.replace(/^https?:\/\//, "").replace(/\/$/, "") : ""
                           MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Quickshell.execDetached(["xdg-open", about.app.homepage]) } }
                }
                ListView {
                    visible: about.app && (about.app.screenshots || []).length > 0
                    width: about.room; height: 300; orientation: ListView.Horizontal; spacing: 14; clip: true
                    model: about.app ? (about.app.screenshots || []) : []
                    boundsBehavior: Flickable.StopAtBounds
                    delegate: ClippingRectangle { required property string modelData; width: 520; height: 300; radius: 18; color: Theme.card
                        id: shot
                        Image { anchors.fill: parent; source: shot.modelData; fillMode: Image.PreserveAspectFit; asynchronous: true } }
                }
                Label { visible: about.app && !about.app.missing; text: about.app ? about.app.description : ""; width: Math.min(about.room, 820); wrapMode: Text.WordWrap; elide: Text.ElideNone; color: Theme.cream; opacity: 0.92; lineHeight: 1.4; font.pixelSize: 15 }
            }

            // what is installed
            Scroll {
                id: owned
                property string only: ""               // one source, or all of them
                readonly property var apps: (mine.data || []).filter(a => only === "" || shell.sources[a.source] === only)
                visible: shell.page === "mine"
                Row { spacing: 12
                    Label { text: I18n.tr("My apps"); font.pixelSize: 26; font.weight: 800; anchors.verticalCenter: parent.verticalCenter }
                    Label { text: owned.apps.length; color: Theme.faint; font.pixelSize: 18; anchors.verticalCenter: parent.verticalCenter } }
                Row { spacing: 8
                    Repeater { model: ["", "Flatpak", "Fedora", "Local"]
                        Pill { required property string modelData; text: modelData === "" ? I18n.tr("All") : modelData; strong: owned.only === modelData; onPressed: owned.only = modelData } } }
                Column { width: owned.room; spacing: 6
                    Repeater { model: owned.apps
                        Rectangle { id: line; required property var modelData; width: owned.room; height: 62; radius: 14; color: lineHit.hovered ? Theme.card : "transparent"
                            HoverHandler { id: lineHit }
                            AppIcon { id: lineIcon; x: 12; icon: line.modelData.icon; side: 40; anchors.verticalCenter: parent.verticalCenter }
                            Column { anchors.left: lineIcon.right; anchors.leftMargin: 14; anchors.right: lineEnd.left; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter; spacing: 2
                                Label { text: line.modelData.name; font.weight: 600; width: parent.width }
                                Label { text: line.modelData.summary; color: Theme.dim; font.pixelSize: 12; width: parent.width; visible: text !== "" } }
                            Row { id: lineEnd; anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter; spacing: 12
                                Label { text: line.modelData.size; color: Theme.faint; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                                Rectangle { width: tag.implicitWidth + 16; height: 22; radius: 11; color: Theme.raised; anchors.verticalCenter: parent.verticalCenter
                                    Label { id: tag; text: shell.sources[line.modelData.source] || line.modelData.source; font.pixelSize: 11; color: Theme.dim; anchors.centerIn: parent } }
                                Pill { visible: line.modelData.removable; busy: shell.doing(line.modelData.id); icon: busy ? "refresh" : "trash"; text: I18n.tr("Remove"); danger: true; implicitHeight: 32
                                       onPressed: shell.work("remove", line.modelData.id, line.modelData.name) } } } } }
            }

            // what can be updated
            Scroll {
                id: news
                readonly property var apps: fresh.data ? fresh.data.apps : []
                readonly property int system: fresh.data ? fresh.data.system : 0
                visible: shell.page === "updates"
                Row { spacing: 14
                    Label { text: I18n.tr("Updates"); font.pixelSize: 26; font.weight: 800; anchors.verticalCenter: parent.verticalCenter }
                    Pill { visible: news.apps.length > 0; strong: true; icon: "download"; text: I18n.tr("Update all apps"); busy: shell.doing("", "update"); onPressed: shell.work("update", "", I18n.tr("All apps")) }
                    Pill { icon: "refresh"; text: I18n.tr("Look again"); busy: fresh.busy; onPressed: fresh.ask(["updates"]) } }
                Waiting { visible: fresh.busy && !fresh.data; text: I18n.tr("Looking what is new…"); width: news.room; topPadding: 100 }
                Column { visible: fresh.data && news.apps.length === 0 && news.system === 0; width: news.room; spacing: 10; topPadding: 90
                    Glyph { name: "circle-check"; font.pixelSize: 54; color: Theme.ok; anchors.horizontalCenter: parent.horizontalCenter }
                    Label { text: I18n.tr("Everything is up to date"); font.pixelSize: 18; font.weight: 600; anchors.horizontalCenter: parent.horizontalCenter } }
                Rectangle { visible: news.system > 0; width: news.room; height: 72; radius: 16; color: Theme.card
                    Glyph { x: 18; name: "settings"; font.pixelSize: 26; color: Theme.gold; anchors.verticalCenter: parent.verticalCenter }
                    Column { x: 60; anchors.verticalCenter: parent.verticalCenter; spacing: 2
                        Label { text: I18n.tr("The system (Fedora)"); font.weight: 600 }
                        Label { text: I18n.tr("{n} packages", { n: news.system }); color: Theme.dim; font.pixelSize: 12 } }
                    Pill { anchors.right: parent.right; anchors.rightMargin: 16; anchors.verticalCenter: parent.verticalCenter; icon: busy ? "refresh" : "download"; text: I18n.tr("Update"); busy: shell.doing("", "update-system")
                           onPressed: shell.work("update-system", "", I18n.tr("The system (Fedora)")) } }
                Column { width: news.room; spacing: 6
                    Repeater { model: news.apps
                        Rectangle { id: upd; required property var modelData; width: news.room; height: 62; radius: 14; color: Theme.card
                            AppIcon { id: updIcon; x: 12; icon: upd.modelData.icon; side: 40; anchors.verticalCenter: parent.verticalCenter }
                            Column { anchors.left: updIcon.right; anchors.leftMargin: 14; anchors.verticalCenter: parent.verticalCenter; spacing: 2
                                Label { text: upd.modelData.name; font.weight: 600 }
                                Label { text: upd.modelData.version; color: Theme.dim; font.pixelSize: 12; visible: text !== "" } }
                            Pill { anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter; icon: busy ? "refresh" : "download"; text: I18n.tr("Update"); busy: shell.doing(upd.modelData.id); implicitHeight: 32
                                   onPressed: shell.work("update", upd.modelData.id, upd.modelData.name) } } } }
            }

            // Barista: what no shop has
            Scroll {
                id: bar
                visible: shell.page === "barista"
                Rectangle {
                    visible: shell.bStep === 1         // what Barista is, until something was handed to him
                    width: bar.room; height: 190; radius: 26
                    gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: "#6b4526" } GradientStop { position: 1; color: "#2a1e17" } }
                    Glyph { x: 34; name: "disc"; font.pixelSize: 84; color: Theme.gold; anchors.verticalCenter: parent.verticalCenter }
                    Column { x: 150; width: parent.width - 190; anchors.verticalCenter: parent.verticalCenter; spacing: 8
                        Label { text: "Barista"; font.pixelSize: 32; font.weight: 800 }
                        Label { text: I18n.tr("Installs what no shop has: a game on discs, a Windows installer, a folder that only needs to be run, an Android app. He looks at what it is first and says whether it will work, and why."); width: parent.width; wrapMode: Text.WordWrap; color: Theme.cream; opacity: 0.9; lineHeight: 1.3 } }
                }
                Label { visible: shell.bStep === 1; text: I18n.tr("WHAT HE WILL TAKE"); color: Theme.faint; font.pixelSize: 11; font.weight: 700; font.letterSpacing: 0.8 }
                Flow { visible: shell.bStep === 1; width: bar.room; spacing: 14
                    Repeater { model: [
                            { icon: "disc", name: QT_TR_NOOP("A CD or DVD, or its image"), hint: QT_TR_NOOP(".iso, several discs") }, { icon: "brand-windows", name: QT_TR_NOOP("A Windows installer or program"), hint: QT_TR_NOOP("setup.exe, .msi, .exe") },
                            { icon: "file-zip", name: QT_TR_NOOP("An archive"), hint: QT_TR_NOOP(".zip, .rar, .7z, in parts too") }, { icon: "folder", name: QT_TR_NOOP("A folder with a game or an app"), hint: QT_TR_NOOP("also on another disk") },
                            { icon: "brand-android", name: QT_TR_NOOP("An Android app"), hint: QT_TR_NOOP(".apk, .xapk") }, { icon: "package", name: QT_TR_NOOP("A Linux package"), hint: QT_TR_NOOP(".rpm, .flatpak, .AppImage") }]
                        Rectangle { required property var modelData; width: Math.floor((bar.room - 28) / 3); height: 84; radius: 18; color: Theme.card
                            Glyph { x: 18; name: parent.modelData.icon; font.pixelSize: 28; color: Theme.coffee; anchors.verticalCenter: parent.verticalCenter }
                            Column { x: 62; width: parent.width - 76; anchors.verticalCenter: parent.verticalCenter; spacing: 3
                                Label { text: I18n.tr(parent.parent.modelData.name); font.weight: 600; width: parent.width; wrapMode: Text.WordWrap; maximumLineCount: 2 }
                                Label { text: I18n.tr(parent.parent.modelData.hint); color: Theme.dim; font.pixelSize: 12; width: parent.width } } } } }
                // ── the wizard: five steps, one after another ──────────────────────────────────────────────────
                Row { spacing: 8
                    Repeater { model: [QT_TR_NOOP("What"), QT_TR_NOOP("Will it work"), QT_TR_NOOP("Where and how"), QT_TR_NOOP("Installing"), QT_TR_NOOP("Done")]
                        Rectangle { required property string modelData; required property int index; height: 30; width: stepName.implicitWidth + 44; radius: 15
                            color: shell.bStep === index + 1 ? Theme.gold : Theme.card
                            Label { x: 12; text: String(parent.index + 1); font.weight: 800; color: shell.bStep === parent.index + 1 ? Theme.inkOnGold : Theme.faint; anchors.verticalCenter: parent.verticalCenter }
                            Label { id: stepName; x: 30; text: I18n.tr(parent.modelData); font.weight: 600; color: shell.bStep === parent.index + 1 ? Theme.inkOnGold : Theme.dim; anchors.verticalCenter: parent.verticalCenter } } } }

                // 1 · what
                Column { visible: shell.bStep === 1; width: bar.room; spacing: 12
                    Label { text: I18n.tr("What are we installing?"); font.pixelSize: 22; font.weight: 800 }
                    Label { text: I18n.tr("Show me the disc images, the installer or the folder. Nothing of it is changed."); color: Theme.dim }
                    Row { spacing: 12
                        Pill { icon: "file"; strong: true; text: I18n.tr("A file or files"); onPressed: bFiles.open() }
                        Pill { icon: "folder"; text: I18n.tr("A folder"); onPressed: bFolder.open() } } }

                // 2 · will it work: all that was found out, in plain words
                Column { visible: shell.bStep === 2; width: bar.room; spacing: 12
                    Waiting { visible: shell.bInfo === null }
                    Label { visible: shell.bInfo === null; text: I18n.tr("Looking at what it is…"); color: Theme.dim }
                    Rectangle { visible: shell.bInfo !== null; width: parent.width; height: 74; radius: 18
                        color: shell.bInfo && shell.bInfo.verdict === "works" ? Qt.rgba(Theme.ok.r, Theme.ok.g, Theme.ok.b, 0.16) : (shell.bInfo && shell.bInfo.verdict === "may" ? Theme.raised : Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.16))
                        Glyph { x: 20; font.pixelSize: 32; anchors.verticalCenter: parent.verticalCenter; name: shell.bInfo && shell.bInfo.verdict === "no" ? "circle-x" : "circle-check"
                                color: shell.bInfo && shell.bInfo.verdict === "works" ? Theme.ok : (shell.bInfo && shell.bInfo.verdict === "may" ? Theme.gold : Theme.red) }
                        Column { x: 68; width: parent.width - 88; anchors.verticalCenter: parent.verticalCenter; spacing: 3
                            Label { font.pixelSize: 19; font.weight: 800; text: !shell.bInfo ? "" : shell.bInfo.verdict === "works" ? I18n.tr("It will work") : shell.bInfo.verdict === "may" ? I18n.tr("It should work") : I18n.tr("It will not work") }
                            Label { width: parent.width; color: Theme.dim; font.pixelSize: 12; elide: Text.ElideRight
                                    text: !shell.bInfo ? "" : shell.bInfo.verdict === "works" ? I18n.tr("Somebody has installed and started it this way before.")
                                        : shell.bInfo.verdict === "may" ? I18n.tr("There is a way written down, but nobody has tried it yet.")
                                        : (shell.bInfo.missing && shell.bInfo.missing.length ? I18n.tr("A disc is missing: nothing here has {file}. Choose all the discs together.", { file: shell.bInfo.missing.join(", ") })
                                        : (shell.bInfo.installed ? I18n.tr("It is installed already.") : I18n.tr("I do not know this program yet, and installing without a recipe is still to come."))) } } }
                    Repeater { model: !shell.bInfo || !shell.bInfo.recipe ? [] : [
                            [ "disc", I18n.tr("What it is"), shell.bInfo.name + (shell.bInfo.year ? " · " + shell.bInfo.year : "") + (shell.bInfo.publisher ? " · " + shell.bInfo.publisher : "") ],
                            [ "file", I18n.tr("From what"), shell.bInfo.sources.map(x => x.path.split("/").pop()).join(" + ") + " · " + shell.bBytes(shell.bInfo.size) ],
                            [ "package", I18n.tr("How it is packed"), (shell.bInfo.packaging === "installshield" ? I18n.tr("An InstallShield installer.") : shell.bInfo.packaging === "msi" ? I18n.tr("A Windows Installer package.") : I18n.tr("No installer I know."))
                                + " " + (shell.bInfo.skips_setup ? I18n.tr("I will not run it: its archives are read directly, which is where old installers fail.") : "") ],
                            [ "brand-windows", I18n.tr("What it will run in"), (shell.bInfo.runner === "proton" ? "Proton" : "Wine") + " · Windows " + ({ "winxp": "XP", "win7": "7", "win98": "98", "win10": "10" }[shell.bInfo.winver] || shell.bInfo.winver)
                                + (shell.bInfo.year ? " · " + I18n.tr("the program is from {year}", { year: shell.bInfo.year }) : "") ],
                            [ "disc", I18n.tr("Room on the disk"), I18n.tr("{free} free; it needs about {need}", { free: shell.bBytes(shell.bInfo.free), need: shell.bBytes(shell.bInfo.size * 2.8) }) ],
                            [ "info-circle", I18n.tr("Notes"), shell.bInfo.notes ] ]
                        Rectangle { required property var modelData; width: bar.room; height: Math.max(52, said.implicitHeight + 24); radius: 16; color: Theme.card
                            Glyph { x: 18; y: 15; name: parent.modelData[0]; color: Theme.gold }
                            Label { x: 52; y: 16; width: 170; text: parent.modelData[1]; color: Theme.dim; font.pixelSize: 13 }
                            Label { id: said; x: 230; y: 14; width: parent.width - 250; text: parent.modelData[2]; wrapMode: Text.WordWrap; elide: Text.ElideNone } } }
                    // more from the internet: only when the user says so
                    Rectangle { visible: shell.bInfo !== null && shell.bInfo.recipe !== ""; width: parent.width; height: netCol.implicitHeight + 28; radius: 16; color: Theme.card; border.color: Theme.line
                        Column { id: netCol; x: 18; y: 14; width: parent.width - 36; spacing: 8
                            Label { width: parent.width; wrapMode: Text.WordWrap; elide: Text.ElideNone
                                    text: shell.bOnline === null ? I18n.tr("May I look on the internet for more about it? Only its name is sent, to Lutris's catalogue. Without that I go on with what is on this computer.")
                                        : (!shell.bOnline.ok ? I18n.tr("The internet did not answer.") : (shell.bOnline.lutris.length ? I18n.tr("Lutris knows it: others run it on Linux.") : I18n.tr("Lutris does not know it."))) }
                            Repeater { model: shell.bOnline && shell.bOnline.ok ? shell.bOnline.lutris.slice(0, 3) : []
                                Label { required property var modelData; text: "• " + modelData.name + (modelData.year ? " (" + modelData.year + ")" : "") + "  " + modelData.url; color: Theme.dim; font.pixelSize: 12 } }
                            Row { spacing: 10; visible: shell.bOnline === null
                                Pill { icon: "world"; text: I18n.tr("Find out more on the internet"); busy: bAsk.running; onPressed: { bAsk.command = ["latte-barista", "online"].concat(shell.bInfo.name.split(" ")); bAsk.running = true } } } } }
                    Row { spacing: 10; visible: shell.bInfo !== null
                        Pill { icon: "chevron-left"; text: I18n.tr("Back"); onPressed: shell.bReset() }
                        Pill { icon: "chevron-right"; strong: true; visible: shell.bInfo !== null && shell.bInfo.verdict !== "no"; text: shell.bOnline === null ? I18n.tr("Go on offline") : I18n.tr("Go on"); onPressed: shell.bStep = 3 } } }

                // 3 · where and how
                Column { visible: shell.bStep === 3; width: bar.room; spacing: 12
                    Label { text: I18n.tr("Where and how"); font.pixelSize: 22; font.weight: 800 }
                    Rectangle { width: parent.width; height: 60; radius: 16; color: Theme.card
                        Glyph { x: 18; name: "folder"; color: Theme.gold; anchors.verticalCenter: parent.verticalCenter }
                        Column { x: 52; anchors.verticalCenter: parent.verticalCenter; spacing: 3
                            Label { text: "~/Games/" + (shell.bInfo ? shell.bInfo.recipe : ""); font.weight: 600 }
                            Label { text: I18n.tr("A folder of its own: its Windows, its saves and what it says. Removing it removes all of it."); color: Theme.dim; font.pixelSize: 12 } } }
                    Rectangle { width: parent.width; height: 60; radius: 16; color: Theme.card
                        Glyph { x: 18; name: "shield-lock"; color: Theme.gold; anchors.verticalCenter: parent.verticalCenter }
                        Column { x: 52; width: parent.width - 70; anchors.verticalCenter: parent.verticalCenter; spacing: 3
                            Label { text: I18n.tr("Fenced in"); font.weight: 600 }
                            Label { width: parent.width; text: I18n.tr("It sees the system read-only and, of your home, only its own folder."); color: Theme.dim; font.pixelSize: 12 } } }
                    Rectangle { width: parent.width; height: 60; radius: 16; color: Theme.card
                        Glyph { x: 18; name: shell.bNetwork ? "world" : "world-off"; color: Theme.gold; anchors.verticalCenter: parent.verticalCenter }
                        Column { x: 52; width: parent.width - 260; anchors.verticalCenter: parent.verticalCenter; spacing: 3
                            Label { text: shell.bNetwork ? I18n.tr("With the network") : I18n.tr("Without the network"); font.weight: 600 }
                            Label { width: parent.width; text: I18n.tr("Off unless you play over the network."); color: Theme.dim; font.pixelSize: 12 } }
                        Pill { anchors.right: parent.right; anchors.rightMargin: 14; anchors.verticalCenter: parent.verticalCenter; text: shell.bNetwork ? I18n.tr("Turn off") : I18n.tr("Turn on"); onPressed: shell.bNetwork = !shell.bNetwork } }
                    Row { spacing: 10
                        Pill { icon: "chevron-left"; text: I18n.tr("Back"); onPressed: shell.bStep = 2 }
                        Pill { icon: "download"; strong: true; text: I18n.tr("Install")
                               onPressed: { shell.bStep = 4; shell.bError = ""; shell.bProgress = null; shell.bInstalled = false; shell.bFound = null; shell.bConsole = []
                                            bInstall.command = ["latte-barista", "install"].concat(shell.bNetwork ? ["--network"] : []).concat(shell.bSources); bInstall.running = true } } } }

                // 4 · installing; then the user tries it
                Column { visible: shell.bStep === 4; width: bar.room; spacing: 12
                    Label { font.pixelSize: 22; font.weight: 800; text: shell.bError !== "" ? I18n.tr("It did not install") : (shell.bInstalled ? I18n.tr("Installed. Try it.") : I18n.tr("Installing…")) }
                    Rectangle { visible: !shell.bInstalled && shell.bError === ""; width: parent.width; height: 70; radius: 16; color: Theme.card
                        Label { x: 20; y: 14; text: shell.bProgress ? I18n.tr(shell.bSteps[shell.bProgress.step] || shell.bProgress.step, { what: shell.bProgress.what }) : I18n.tr("Starting…") }
                        Rectangle { x: 20; y: 46; width: parent.width - 40; height: 8; radius: 4; color: Theme.raised
                            Rectangle { height: 8; radius: 4; color: Theme.gold; width: parent.width * (shell.bProgress ? (shell.bProgress.at - 0.5) / shell.bProgress.of : 0.02); Behavior on width { NumberAnimation { duration: 300 } } } } }
                    Label { visible: shell.bError !== ""; text: shell.bError; color: Theme.red }
                    // the console: what is being run, for whoever likes to see it
                    Pill { icon: "terminal-2"; text: shell.bConsoleOut ? I18n.tr("Hide the console") : I18n.tr("Show the console"); strong: shell.bConsoleOut; onPressed: shell.bConsoleOut = !shell.bConsoleOut }
                    Rectangle { visible: shell.bConsoleOut; width: parent.width; height: 300; radius: 14; color: "#0d0907"; border.color: Theme.line; clip: true
                        ListView { id: lines; anchors.fill: parent; anchors.margins: 12; model: shell.bConsole; clip: true
                            onCountChanged: positionViewAtEnd()
                            delegate: Text { required property string modelData; width: lines.width; text: modelData; elide: Text.ElideRight; font.family: "JetBrains Mono"; font.pixelSize: 12
                                             color: modelData.startsWith("$ ") ? Theme.gold : (modelData.startsWith("# ") ? "#9ed6bd" : "#cdbfae") } } }
                    Label { visible: shell.bInstalled; width: parent.width; wrapMode: Text.WordWrap; elide: Text.ElideNone; color: Theme.dim
                            text: I18n.tr("Start it and see whether it works: the menu, a moment of play, the sound. Then tell me how it went.") }
                    Row { spacing: 10; visible: shell.bInstalled && shell.bPlace !== null
                        Pill { icon: "folder"; text: I18n.tr("Open its folder"); onPressed: Quickshell.execDetached(["xdg-open", shell.bPlace.folder]) }
                        Pill { icon: "file-text"; text: I18n.tr("Show the installation log"); onPressed: Quickshell.execDetached(["xdg-open", shell.bPlace.install_log]) }
                        Pill { icon: "player-play"; strong: true; text: I18n.tr("Start it to try"); onPressed: Quickshell.execDetached(["latte-barista", "run", shell.bPlace.id]) } }
                    Row { spacing: 10; visible: shell.bInstalled && shell.bPlace !== null
                        Label { text: I18n.tr("Did it work?"); height: 36; verticalAlignment: Text.AlignVCenter }
                        Pill { icon: "check"; text: I18n.tr("Yes"); onPressed: { bWorked.command = ["latte-barista", "worked", shell.bPlace.id, "yes"]; bWorked.running = true } }
                        Pill { icon: "x"; text: I18n.tr("No"); onPressed: { bWorked.command = ["latte-barista", "worked", shell.bPlace.id, "no"]; bWorked.running = true } } }
                    Repeater { model: shell.bFound || []
                        Rectangle { required property var modelData; width: bar.room; height: 52; radius: 16; color: Theme.card; border.color: Theme.line
                            Glyph { x: 16; name: "alert-triangle"; color: Theme.gold; anchors.verticalCenter: parent.verticalCenter }
                            Label { x: 46; width: parent.width - 60; text: I18n.tr(shell.bWhy[parent.modelData.what] || parent.modelData.what, { detail: parent.modelData.detail }); anchors.verticalCenter: parent.verticalCenter } } }
                    Row { spacing: 10; visible: shell.bFound !== null
                        Pill { icon: "file-text"; text: I18n.tr("Show what it said"); onPressed: Quickshell.execDetached(["xdg-open", shell.bPlace.run_log]) }
                        Pill { icon: "trash"; danger: true; text: I18n.tr("Uninstall"); onPressed: { Quickshell.execDetached(["latte-barista", "remove", shell.bPlace.id]); shell.bReset() } } }
                    Pill { visible: shell.bError !== ""; icon: "chevron-left"; text: I18n.tr("Back"); onPressed: shell.bStep = 3 } }

                // 5 · done
                Column { visible: shell.bStep === 5; width: bar.room; spacing: 12
                    Label { text: I18n.tr("Done"); font.pixelSize: 22; font.weight: 800 }
                    Label { width: parent.width; wrapMode: Text.WordWrap; elide: Text.ElideNone; color: Theme.dim; text: I18n.tr("{name} is among your apps: in the launcher, like any other.", { name: shell.bPlace ? shell.bPlace.name : "" }) }
                    Row { spacing: 10
                        Pill { icon: "player-play"; strong: true; text: I18n.tr("Start"); onPressed: Quickshell.execDetached(["latte-barista", "run", shell.bPlace.id]) }
                        Pill { icon: "folder"; text: I18n.tr("Open its folder"); onPressed: Quickshell.execDetached(["xdg-open", shell.bPlace.folder]) }
                        Pill { icon: "plus"; text: I18n.tr("Install another"); onPressed: shell.bReset() } } }
            }
    }
}
