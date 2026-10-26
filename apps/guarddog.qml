// GuardDog: what keeps the desktop up, as a window. bin/latte-guarddog is the guard; this shows what it watches,
// the programs that crashed (with "Ask the AI", which hands the facts to an agent that explains and changes nothing)
// and a console of what it did, newest at the bottom.   latte-app guarddog [status | crashes | log]
import QtQuick
import Quickshell
import Quickshell.Io
import "common"

ShellRoot {
    id: shell
    readonly property var words: (Quickshell.env("LATTE_APP_ARGS") || "").split("\n").filter(w => w !== "")
    property string page: "overview"
    readonly property var pages: [{ id: "overview", name: QT_TR_NOOP("Overview"), icon: "layout-dashboard" },
                                  { id: "status", name: QT_TR_NOOP("What it keeps running"), icon: "shield-check" },
                                  { id: "crashes", name: QT_TR_NOOP("Crashes"), icon: "alert-triangle" },
                                  { id: "log", name: QT_TR_NOOP("Log"), icon: "terminal" }]
    Component.onCompleted: if (pages.some(p => p.id === words[0])) page = words[0]

    component Ask: Process {
        id: q
        property var data: []
        property string buf: ""
        function ask(args) { if (running) return; command = ["latte-guarddog"].concat(args); running = true }
        stdout: StdioCollector { onStreamFinished: q.buf = this.text }
        onExited: { try { data = JSON.parse(buf) } catch (e) {} }
    }
    Ask { id: state }
    Ask { id: crashq }
    Ask { id: logq }
    Ask { id: sumq; data: ({}) }
    // what it watches and what it did, often; the crashes less often (systemd-coredump is asked)
    Timer { interval: 2000; repeat: true; running: true; triggeredOnStart: true
            onTriggered: { state.ask(["status"]); logq.ask(["log", "300"]); sumq.ask(["summary"]) } }
    Timer { interval: 15000; repeat: true; running: true; triggeredOnStart: true; onTriggered: crashq.ask(["crashes"]) }
    Process { id: doer; onExited: { state.ask(["status"]); crashq.ask(["crashes"]) } }
    function act(argv) { doer.command = argv; doer.running = true }

    readonly property var what: ({ start: QT_TR_NOOP("started"), down: QT_TR_NOOP("not running"), restart: QT_TR_NOOP("started again"),
                                   failed: QT_TR_NOOP("would not stay up"), crash: QT_TR_NOOP("crashed"), back: QT_TR_NOOP("up again"), thaw: QT_TR_NOOP("let go on"), fell: QT_TR_NOOP("fell, came back"), impostor: QT_TR_NOOP("look-alike"), changed: QT_TR_NOOP("changed"), doghouse: "DogHouse" })
    function tint(w) { return w === "crash" || w === "failed" || w === "impostor" || w === "doghouse" ? Theme.red : w === "down" || w === "restart" || w === "thaw" || w === "fell" || w === "changed" ? Theme.gold : w === "back" ? Theme.ok : Theme.dim }
    function when(t) { const d = new Date(t * 1000); return d.toDateString() === new Date().toDateString() ? Qt.formatTime(d, "HH:mm:ss") : Qt.formatDateTime(d, "d. M. HH:mm") }

    AppWindow {
        title: "GuardDog"
        heading: I18n.tr((shell.pages.find(p => p.id === shell.page) || shell.pages[0]).name)
        implicitWidth: 1040; implicitHeight: 720
        side: [
            Column { x: 14; y: 14; spacing: 4
                Row { x: 6; spacing: 10; height: 40
                    Glyph { name: "shield-check"; font.pixelSize: 24; color: Theme.gold; anchors.verticalCenter: parent.verticalCenter }
                    Label { text: "GuardDog"; font.pixelSize: 17; font.weight: 700; anchors.verticalCenter: parent.verticalCenter } }
                Item { width: 1; height: 8 }
                Repeater { model: shell.pages
                    Nav { required property var modelData; text: I18n.tr(modelData.name); icon: modelData.icon; on: shell.page === modelData.id
                          badge: modelData.id === "crashes" ? shell.crashCount : 0; onPressed: shell.page = modelData.id } } }
        ]

        // ── the overview: how things stand, the days since the last problem, the last 30 days, what goes wrong most ──
        Scroll {
            id: overview
            visible: shell.page === "overview"
            readonly property var s: sumq.data
            readonly property bool whole: s.watching !== undefined && (s.down || []).length === 0
            readonly property int clean: s.last ? Math.floor((Date.now() / 1000 - s.last) / 86400) : (s.since ? Math.floor((Date.now() / 1000 - s.since) / 86400) : 0)
            Label { visible: state.data.length === 0; width: overview.room; wrapMode: Text.WordWrap; color: Theme.red
                    text: I18n.tr("GuardDog is not running: the desktop is not being watched.") }
            Row { width: overview.room; spacing: 14; height: 150
                Rectangle { width: (parent.width - 14) * 0.58; height: parent.height; radius: 20; color: Theme.card
                    Rectangle { x: 26; y: 30; width: 52; height: 52; radius: 26; color: Qt.rgba(tone.r, tone.g, tone.b, 0.18)
                        readonly property color tone: overview.whole ? Theme.ok : Theme.red
                        Glyph { anchors.centerIn: parent; name: overview.whole ? "shield-check" : "alert-triangle"; font.pixelSize: 26; color: parent.tone } }
                    Column { x: 96; y: 30; width: parent.width - 96 - 24; spacing: 6
                        Label { width: parent.width; wrapMode: Text.WordWrap; font.pixelSize: 22; font.weight: 700
                                text: overview.whole ? I18n.tr("Everything is running") : I18n.tr("{n} not running", { n: (overview.s.down || []).length }) }
                        Label { width: parent.width; wrapMode: Text.WordWrap; color: Theme.dim
                                text: overview.whole ? I18n.tr("GuardDog watches {n} parts of the desktop and starts again what stops.", { n: overview.s.watching || 0 })
                                                     : (overview.s.down || []).map(n => I18n.tr(n)).join(", ") } } }
                Rectangle { width: (parent.width - 14) * 0.42; height: parent.height; radius: 20; color: Theme.card
                    Column { x: 26; y: 22; width: parent.width - 52; spacing: 2
                        Label { text: String(overview.clean); font.pixelSize: 56; font.weight: 800; color: overview.s.last && overview.clean === 0 ? Theme.gold : Theme.ok }
                        Label { text: I18n.tr("days without a problem"); font.weight: 600 }
                        Label { width: parent.width; elide: Text.ElideRight; color: Theme.dim; font.pixelSize: 12
                                text: overview.s.last ? I18n.tr("Last one: {t}", { t: shell.when(overview.s.last) })
                                                      : overview.s.since ? I18n.tr("Watching since {t}", { t: shell.when(overview.s.since) }) : "" } } } }
            // the last 30 days, a square a day, in the Monitor's colours; before the guard's history begins, unlit
            Rectangle { width: overview.room; height: 112; radius: 20; color: Theme.card
                Label { x: 24; y: 18; text: I18n.tr("THE LAST 30 DAYS"); color: Theme.faint; font.family: Theme.mono; font.pixelSize: 11; font.weight: 700 }
                Row { id: strip; x: 24; y: 44; spacing: 4
                    readonly property real cell: (overview.room - 48 - 29 * 4) / 30
                    Repeater { model: overview.s.days || []
                        Rectangle { required property int index; required property int modelData; width: strip.cell; height: 28; radius: 5
                            color: modelData < 0 ? Theme.unlit : Theme.heat(Math.min(1, modelData / 4))
                            Label { anchors.centerIn: parent; visible: parent.modelData > 0; text: parent.modelData; font.pixelSize: 11; font.weight: 700; color: Theme.ground } } } }
                Label { x: 24; y: 80; text: I18n.tr("30 days ago"); color: Theme.faint; font.pixelSize: 11 }
                Label { anchors.right: parent.right; anchors.rightMargin: 24; y: 80; text: I18n.tr("today"); color: Theme.faint; font.pixelSize: 11 } }
            Label { text: I18n.tr("MOST FREQUENT PROBLEMS"); color: Theme.faint; font.family: Theme.mono; font.pixelSize: 11; font.weight: 700 }
            Label { visible: (overview.s.top || []).length === 0; color: Theme.ok; text: I18n.tr("Nothing in the last 30 days.") }
            Repeater { model: overview.s.top || []
                Rectangle { id: pr; required property var modelData; width: overview.room; height: 58; radius: 16; color: Theme.card
                    Rectangle { x: 16; width: 44; height: 26; radius: 13; anchors.verticalCenter: parent.verticalCenter; color: Qt.rgba(tint.r, tint.g, tint.b, 0.2)
                        readonly property color tint: shell.tint(pr.modelData.what)
                        Label { anchors.centerIn: parent; text: pr.modelData.count + "×"; font.weight: 800; color: parent.tint } }
                    Column { x: 76; width: parent.width - 76 - 20; anchors.verticalCenter: parent.verticalCenter; spacing: 2
                        Label { text: I18n.tr(pr.modelData.name); font.weight: 600; width: parent.width; elide: Text.ElideRight }
                        Label { color: Theme.dim; font.pixelSize: 12
                                text: I18n.tr(shell.what[pr.modelData.what] || pr.modelData.what) + "  ·  " + I18n.tr("last {t}", { t: shell.when(pr.modelData.last) }) } }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: shell.page = pr.modelData.what === "crash" ? "crashes" : "log" } } }
        }

        // ── what it keeps running; a component switched off is left alone, and stays so after an update ─────────
        Scroll {
            id: statusPage
            visible: shell.page === "status"
            Label { width: statusPage.room; wrapMode: Text.WordWrap; color: Theme.dim
                    text: I18n.tr("It looks every few seconds, and starts again what has stopped. What you switch off here it leaves alone, and it stays so after an update. Switching off does not stop what is running now.") }
            Label { visible: state.data.length === 0; width: statusPage.room; wrapMode: Text.WordWrap; color: Theme.red
                    text: I18n.tr("GuardDog is not running: the desktop is not being watched.") }
            Repeater { model: state.data
                Rectangle { required property var modelData; width: statusPage.room; height: 62; radius: 16; color: Theme.card
                    Rectangle { x: 16; width: 11; height: 11; radius: 6; anchors.verticalCenter: parent.verticalCenter
                                color: parent.modelData.state === "up" ? Theme.ok : (parent.modelData.state === "off" ? Theme.faint : (parent.modelData.state === "restarted" ? Theme.gold : Theme.red)) }
                    Column { x: 42; width: parent.width - 42 - 120; anchors.verticalCenter: parent.verticalCenter; spacing: 2
                        Label { text: I18n.tr(parent.parent.modelData.name); font.weight: 600 }
                        Label { color: Theme.dim; font.pixelSize: 12
                                text: parent.parent.modelData.off ? I18n.tr("left alone, as you chose") : (parent.parent.modelData.state === "up" ? I18n.tr("running") : (parent.parent.modelData.state === "restarted" ? I18n.tr("started again {n} times", { n: parent.parent.modelData.restarts }) : (parent.parent.modelData.state === "failed" ? I18n.tr("would not stay up") : I18n.tr("not running")))) } }
                    Rectangle { width: 46; height: 26; radius: 13; color: parent.modelData.off ? Theme.raised : Theme.gold; anchors.right: parent.right; anchors.rightMargin: 16; anchors.verticalCenter: parent.verticalCenter
                        Rectangle { width: 20; height: 20; radius: 10; y: 3; x: parent.parent.modelData.off ? 3 : 23; color: parent.parent.modelData.off ? Theme.dim : Theme.ground }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: shell.act(["latte-guarddog", "set", parent.parent.modelData.id, parent.parent.modelData.off ? "on" : "off"]) } } } }
        }

        // ── the programs that crashed this week, newest first ─────────────────────────────────────────────────
        Scroll {
            id: crashPage
            visible: shell.page === "crashes"
            Label { width: crashPage.room; wrapMode: Text.WordWrap; color: Theme.dim
                    text: I18n.tr("Programs that crashed in the last week. The AI can find out what happened and explain it; it changes nothing. A program you mute crashes without a notice, but it stays here.") }
            Label { visible: crashq.data.length === 0; text: I18n.tr("Nothing crashed this week."); color: Theme.ok }
            Repeater { model: crashq.data
                Rectangle { id: cr; required property var modelData; width: crashPage.room; height: 64; radius: 16; color: Theme.card
                    Glyph { x: 18; anchors.verticalCenter: parent.verticalCenter; name: "alert-triangle"; font.pixelSize: 20; color: cr.modelData.quiet ? Theme.faint : Theme.red }
                    Column { x: 52; width: parent.width - 52 - 330; anchors.verticalCenter: parent.verticalCenter; spacing: 2
                        Row { spacing: 8
                            Label { text: cr.modelData.name; font.weight: 700 }
                            Rectangle { width: own.implicitWidth + 12; height: 18; radius: 9; anchors.verticalCenter: parent.verticalCenter
                                        color: cr.modelData.owner === "latteos" ? Qt.rgba(Theme.gold.r, Theme.gold.g, Theme.gold.b, 0.22) : Theme.raised
                                Label { id: own; anchors.centerIn: parent; font.pixelSize: 10; font.weight: 700; color: cr.modelData.owner === "latteos" ? Theme.gold : Theme.dim
                                        text: cr.modelData.owner === "latteos" ? "LatteOS" : cr.modelData.owner === "linux" ? "Linux" : I18n.tr("Your apps") } } }
                        Label { color: Theme.dim; font.pixelSize: 12; width: parent.width; elide: Text.ElideMiddle
                                text: shell.when(cr.modelData.at) + "  ·  " + I18n.tr("signal {n}", { n: cr.modelData.sig }) + "  ·  " + cr.modelData.exe } }
                    Row { anchors.right: parent.right; anchors.rightMargin: 14; anchors.verticalCenter: parent.verticalCenter; spacing: 8
                        Pill { implicitHeight: 32; icon: "robot"; strong: true; text: I18n.tr("Ask the AI"); onPressed: shell.act(["latte-ai", "crash", String(cr.modelData.pid)]) }
                        Pill { implicitHeight: 32; icon: cr.modelData.quiet ? "bell" : "bell-off"; text: cr.modelData.quiet ? I18n.tr("Notify") : I18n.tr("Mute")
                               onPressed: shell.act(["latte-guarddog", "quiet", cr.modelData.name, cr.modelData.quiet ? "off" : "on"]) } } } }
        }

        // ── the console: what the guard did, newest at the bottom ──────────────────────────────────────────────
        Rectangle {
            visible: shell.page === "log"
            anchors.fill: parent; anchors.margins: 22; radius: 14; color: "#120d0a"; border.width: 1; border.color: Theme.line
            ListView {
                id: lines
                anchors.fill: parent; anchors.margins: 14; clip: true; spacing: 2
                model: logq.data
                boundsBehavior: Flickable.StopAtBounds
                onCountChanged: Qt.callLater(positionViewAtEnd)
                delegate: Row { required property var modelData; spacing: 12; width: lines.width
                    Text { text: shell.when(modelData.at); color: Theme.faint; font.family: "monospace"; font.pixelSize: 13 }
                    Text { width: 120; text: I18n.tr(shell.what[modelData.what] || modelData.what); color: shell.tint(modelData.what); font.family: "monospace"; font.pixelSize: 13; font.bold: true; elide: Text.ElideRight }
                    Text { width: 130; text: modelData.id; color: Theme.cream; font.family: "monospace"; font.pixelSize: 13; elide: Text.ElideRight }
                    Text { width: lines.width - 400; text: modelData.text; color: Theme.dim; font.family: "monospace"; font.pixelSize: 13; elide: Text.ElideRight } } }
            Label { visible: logq.data.length === 0; anchors.centerIn: parent; color: Theme.faint; text: I18n.tr("Nothing yet: the guard writes here what it does.") }
        }
    }
    readonly property int crashCount: crashq.data.filter(c => Date.now() / 1000 - c.at < 86400).length
}
