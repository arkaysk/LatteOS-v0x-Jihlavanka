// Monitor: what the computer is doing, what runs on it, what starts by itself and why, and what its sensors say.
// The whole machine is latte-stats's to tell (processor, memory, graphics, once a second); the programs, the
// network and the disks latte-monitor's (every two seconds).   latte-app monitor [processes | startup | sensors]
//
// The pages: the overview (four live pictures and the most demanding programs) · processes (the programs with a
// window, then the rest; one can be ended) · startup (everything that starts by itself, with what it is, where
// it comes from and how long it took; the user's own can be switched off, and on again) · sensors.
import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import "common"

ShellRoot {
    id: shell
    readonly property var words: (Quickshell.env("LATTE_APP_ARGS") || "").split("\n").filter(w => w !== "")
    property string page: "overview"
    readonly property var pages: [{ id: "overview", name: QT_TR_NOOP("Overview"), icon: "compass" }, { id: "processes", name: QT_TR_NOOP("Processes"), icon: "apps" },
                                  { id: "startup", name: QT_TR_NOOP("Startup"), icon: "rocket" }, { id: "sensors", name: QT_TR_NOOP("Sensors"), icon: "activity" }]

    // ── what is known, and the last minute of it ──────────────────────────────────────────────────────────
    property var now: ({})                     // latte-stats's last line
    property var run: null                     // latte-monitor's last line
    property var past: ({ cpu: [], ram: [], gpu: [], down: [], up: [] })
    function keep(name, value) { const l = past[name].concat([value]); return l.length > 60 ? l.slice(l.length - 60) : l }
    Process {
        running: true; command: ["latte-stats", "1"]
        stdout: SplitParser { onRead: line => { try {
            const s = JSON.parse(line)
            shell.now = s
            shell.past = { cpu: shell.keep("cpu", s.cpu / 100), ram: shell.keep("ram", s.ram / Math.max(1, s.ram_total)), gpu: shell.keep("gpu", (s.gpu || 0) / 100), down: shell.past.down, up: shell.past.up }
        } catch (e) {} } }
    }
    Process {
        running: true; command: ["latte-monitor", "watch", "2"]
        stdout: SplitParser { onRead: line => { try {
            const r = JSON.parse(line)
            shell.run = r
            shell.past = { cpu: shell.past.cpu, ram: shell.past.ram, gpu: shell.past.gpu, down: shell.keep("down", r.net.down), up: shell.keep("up", r.net.up) }
        } catch (e) {} } }
    }
    component Ask: Process {
        id: q
        property var data: null
        property string buf: ""
        function ask(args) { running = false; command = ["latte-monitor"].concat(args); running = true }
        stdout: StdioCollector { onStreamFinished: q.buf = this.text }
        onExited: { try { data = JSON.parse(buf) } catch (e) {} }
    }
    Ask { id: starts }
    Ask { id: sense }
    Process { id: doer; onExited: starts.ask(["startup"]) }
    function act(args) { doer.running = false; doer.command = ["latte-monitor"].concat(args); doer.running = true }
    // the user's programs GuardDog keeps running (bin/latte-guarddog keep): asked for while the processes are shown
    property var kept: []
    Process { id: keptq; command: ["latte-guarddog", "keep"]
              stdout: StdioCollector { onStreamFinished: { try { shell.kept = JSON.parse(this.text).map(k => k.name) } catch (e) {} } } }
    Timer { interval: 5000; repeat: true; running: shell.page === "processes"; triggeredOnStart: true; onTriggered: keptq.running = true }
    Process { id: keeper; onExited: keptq.running = true }
    // the right button on a program, as the Task Manager has it
    function lineMenu(what, canEnd, x, y) {
        const keep = shell.kept.includes(what.name)
        const rows = []
        if (what.owner === "user")
            rows.push({ icon: "shield-check", text: I18n.tr("Keep running (GuardDog)"), checked: keep,
                        run: () => { keeper.command = ["latte-guarddog", "keep"].concat(keep ? [what.name, "off"] : [String(what.pids[0])]); keeper.running = true } })
        if (canEnd) rows.push({ icon: "x", text: I18n.tr("End"), danger: true, run: () => shell.act(["end"].concat(what.pids.map(String))) })
        if (rows.length) menu.open(x, y, rows)
    }
    Timer { interval: 3000; repeat: true; running: shell.page === "sensors"; triggeredOnStart: true; onTriggered: sense.ask(["sensors"]) }
    onPageChanged: if (page === "startup" && !starts.data) starts.ask(["startup"])
    Component.onCompleted: if (pages.some(p => p.id === words[0])) page = words[0]

    function bytes(n) { return n >= 1073741824 ? (n / 1073741824).toFixed(1) + " GB" : (n >= 1048576 ? Math.round(n / 1048576) + " MB" : Math.round(n / 1024) + " kB") }
    function rate(n) { return bytes(n) + "/s" }
    property string find: ""                   // what the processes are searched for
    property string order: "cpu"
    property string owner: "all"               // whose: all · latteos · linux · user (GuardDog says, bin/latte-guarddog)
    readonly property var owners: [{ id: "all", name: QT_TR_NOOP("All") }, { id: "latteos", name: QT_TR_NOOP("LatteOS") },
                                   { id: "linux", name: QT_TR_NOOP("Linux") }, { id: "user", name: QT_TR_NOOP("Your apps") }]
    function listed(list) {
        const f = find.toLowerCase()
        return (list || []).filter(p => (f === "" || p.name.toLowerCase().includes(f)) && (owner === "all" || p.owner === owner)).slice().sort((a, b) => order === "cpu" ? (b.cpu - a.cpu) || (b.mem - a.mem) : b.mem - a.mem)
    }

    // one of the overview's four pictures
    component Meter: Rectangle {
        id: meter
        property string title
        property string icon
        property string figure
        property string note
        property var values: []
        property color tint: Theme.gold
        property bool heat: true               // load goes green → red; the network is one colour
        default property alias more: extra.data
        height: 196; radius: 22; color: Theme.card; clip: true
        DotGraph { anchors.bottom: parent.bottom; anchors.bottomMargin: 12; x: 14; width: parent.width - 28; height: 76; values: meter.values; heat: meter.heat; tint: meter.tint }
        Row { x: 20; y: 16; spacing: 9
            Glyph { name: meter.icon; color: meter.tint; font.pixelSize: 19; anchors.verticalCenter: parent.verticalCenter }
            Label { text: meter.title; color: Theme.dim; font.weight: 600; anchors.verticalCenter: parent.verticalCenter } }
        Label { x: 20; y: 44; text: meter.figure; font.pixelSize: 36; font.weight: 800 }
        Label { x: 20; y: 90; text: meter.note; color: Theme.dim; font.pixelSize: 12 }
        Item { id: extra; anchors.right: parent.right; anchors.rightMargin: 18; y: 18; width: 150; height: 70 }
    }
    component Line: Rectangle {
        id: line
        property var what
        property bool canEnd: true
        height: 46; radius: 12; color: lineHit.hovered ? Qt.alpha(Theme.card, 0.5) : "transparent"
        HoverHandler { id: lineHit }
        MouseArea { anchors.fill: parent; acceptedButtons: Qt.RightButton
                    onClicked: (m) => { const q = mapToItem(overlay, m.x, m.y); shell.lineMenu(line.what, line.canEnd, q.x, q.y) } }
        Row { x: 14; width: parent.width - 330; spacing: 8; anchors.verticalCenter: parent.verticalCenter
            Glyph { visible: shell.kept.includes(line.what.name) && line.what.owner === "user"; name: "shield-check"; color: Theme.gold; font.pixelSize: 15; anchors.verticalCenter: parent.verticalCenter }
            Label { id: lname; text: line.what.name + (line.what.pids.length > 1 ? "  (" + line.what.pids.length + ")" : ""); font.weight: 600; elide: Text.ElideRight
                    width: Math.min(implicitWidth, parent.width - opill.width - 8); anchors.verticalCenter: parent.verticalCenter }
            Rectangle { id: opill; visible: line.what.owner !== undefined && line.what.owner !== "user"; width: otext.implicitWidth + 12; height: 18; radius: 9; anchors.verticalCenter: parent.verticalCenter
                        color: line.what.owner === "latteos" ? Qt.rgba(Theme.gold.r, Theme.gold.g, Theme.gold.b, 0.22) : Theme.raised
                        Label { id: otext; anchors.centerIn: parent; font.pixelSize: 10; font.weight: 700; color: line.what.owner === "latteos" ? Theme.gold : Theme.dim
                                text: line.what.owner === "latteos" ? "LatteOS" : "Linux" } } }
        Label { anchors.right: parent.right; anchors.rightMargin: 226; text: line.what.cpu.toFixed(1) + " %"; color: line.what.cpu >= 25 ? Theme.gold : Theme.dim; anchors.verticalCenter: parent.verticalCenter }
        DotBar { anchors.right: parent.right; anchors.rightMargin: 226; y: parent.height - 9; width: 70; height: 4; segments: 14; value: line.what.cpu / 100 }
        Label { anchors.right: parent.right; anchors.rightMargin: 120; text: shell.bytes(line.what.mem); color: Theme.dim; anchors.verticalCenter: parent.verticalCenter }
        Pill { visible: lineHit.hovered && line.canEnd; anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter; implicitHeight: 30; danger: true; icon: "x"; text: I18n.tr("End")
               onPressed: shell.act(["end"].concat(line.what.pids.map(String))) }
    }

    AppWindow {
        title: I18n.tr("Monitor")
        heading: I18n.tr((shell.pages.find(p => p.id === shell.page) || shell.pages[0]).name)
        implicitWidth: 1180; implicitHeight: 780
        searchHint: shell.page === "processes" ? I18n.tr("Find a process…") : ""
        onSearchTextChanged: shell.find = searchText.trim()
        side: [
            Column { x: 14; y: 14; spacing: 4
                Row { x: 6; spacing: 10; height: 40
                    Glyph { name: "activity"; font.pixelSize: 24; color: Theme.gold; anchors.verticalCenter: parent.verticalCenter }
                    Label { text: I18n.tr("Monitor"); font.pixelSize: 17; font.weight: 700; anchors.verticalCenter: parent.verticalCenter } }
                Item { width: 1; height: 8 }
                Repeater { model: shell.pages
                    Nav { required property var modelData; text: I18n.tr(modelData.name); icon: modelData.icon; on: shell.page === modelData.id; onPressed: shell.page = modelData.id } }
            },
            // the machine at a glance, whatever page is open
            Column { x: 20; spacing: 10; anchors.bottom: parent.bottom; anchors.bottomMargin: 20; width: 210
                Repeater { model: [{ n: QT_TR_NOOP("Processor"), v: (shell.now.cpu || 0) / 100, t: (shell.now.cpu || 0) + " %" },
                                   { n: QT_TR_NOOP("Memory"), v: (shell.now.ram || 0) / Math.max(1, shell.now.ram_total || 1), t: shell.bytes(shell.now.ram || 0) }]
                    Column { required property var modelData; width: parent.width; spacing: 4
                        Row { width: parent.width
                            Label { text: I18n.tr(modelData.n); color: Theme.dim; font.pixelSize: 12; width: parent.width - fig.implicitWidth }
                            Label { id: fig; text: modelData.t; font.pixelSize: 12; font.weight: 700 } }
                        DotBar { width: parent.width; height: 6; segments: 24; value: modelData.v } } }
            }
        ]

        // ── the overview ──────────────────────────────────────────────────────────────────────────────────
        Scroll {
            id: over
            visible: shell.page === "overview"
            Grid { columns: over.room > 760 ? 2 : 1; spacing: 16
                readonly property real each: (over.room - (columns - 1) * 16) / columns
                Meter { width: parent.each; title: I18n.tr("Processor"); icon: "cpu"; values: shell.past.cpu
                        figure: (shell.now.cpu || 0) + " %"; note: shell.now.cpu_temp ? shell.now.cpu_temp + " °C" : ""
                        // every core as a row of segments
                        Column { anchors.right: parent.right; anchors.top: parent.top; anchors.topMargin: -6; spacing: 2
                            Repeater { model: shell.run ? shell.run.cores.slice(0, 8) : []
                                Row { required property int modelData; required property int index; spacing: 8; height: 7
                                    Label { text: "c" + index; color: Theme.dim; font.pixelSize: 9; width: 18; anchors.verticalCenter: parent.verticalCenter }
                                    DotBar { width: 92; height: 5; segments: 14; value: modelData / 100; anchors.verticalCenter: parent.verticalCenter } } } } }
                Meter { width: parent.each; title: I18n.tr("Memory"); icon: "cpu-2"; values: shell.past.ram; tint: Theme.coffee
                        figure: shell.bytes(shell.now.ram || 0); note: I18n.tr("of {n}", { n: shell.bytes(shell.now.ram_total || 0) }) + (shell.run && shell.run.swap > 0 ? "  ·  " + I18n.tr("swap") + " " + shell.bytes(shell.run.swap) : "") }
                Meter { width: parent.each; visible: shell.now.gpu !== undefined; title: I18n.tr("Graphics"); icon: "device-desktop"; values: shell.past.gpu; tint: "#9ed6bd"
                        figure: (shell.now.gpu || 0) + " %"
                        note: I18n.tr("Video memory") + " " + shell.bytes(shell.now.vram || 0) + " / " + shell.bytes(shell.now.vram_total || 0) + (shell.now.gpu_temp ? "  ·  " + shell.now.gpu_temp + " °C" : "") }
                Meter { width: parent.each; title: I18n.tr("Network and disks"); icon: "network"; tint: "#8fb6e8"; heat: false
                        values: { const top = Math.max(65536, ...shell.past.down, ...shell.past.up); return shell.past.down.map(v => v / top) }
                        figure: shell.run ? "↓ " + shell.rate(shell.run.net.down) : "—"
                        note: shell.run ? "↑ " + shell.rate(shell.run.net.up) + "  ·  " + I18n.tr("disk") + " " + shell.rate(shell.run.disk.read + shell.run.disk.write) : "" }
            }
            Column { width: over.room; spacing: 4
                Label { text: I18n.tr("MOST DEMANDING NOW"); color: Theme.faint; font.pixelSize: 11; font.weight: 700; font.letterSpacing: 0.8; bottomPadding: 6 }
                Repeater { model: shell.run ? shell.run.apps.concat(shell.run.background).sort((a, b) => (b.cpu - a.cpu) || (b.mem - a.mem)).slice(0, 5) : []
                    Line { required property var modelData; width: over.room; canEnd: false; what: modelData } }
            }
        }

        // ── processes ─────────────────────────────────────────────────────────────────────────────────────
        Scroll {
            id: procs
            visible: shell.page === "processes"
            // what GuardDog watches over, and whether each stands
            Column { width: procs.room; spacing: 6; visible: shell.run !== null && (shell.run.guard || []).length > 0
                Label { text: I18n.tr("WATCHED BY GUARDDOG"); color: Theme.faint; font.pixelSize: 11; font.weight: 700; font.letterSpacing: 0.8 }
                Flow { width: parent.width; spacing: 8
                    Repeater { model: shell.run ? (shell.run.guard || []) : []
                        Rectangle { required property var modelData; height: 30; radius: 15; width: gl.implicitWidth + 34; color: Theme.card
                            Rectangle { x: 11; width: 9; height: 9; radius: 5; anchors.verticalCenter: parent.verticalCenter
                                        color: parent.modelData.state === "up" ? Theme.ok : (parent.modelData.state === "off" ? Theme.faint : (parent.modelData.state === "restarted" ? Theme.gold : Theme.red)) }
                            Label { id: gl; x: 26; anchors.verticalCenter: parent.verticalCenter; font.pixelSize: 12; color: Theme.dim
                                    text: I18n.tr(parent.modelData.name) + (parent.modelData.restarts > 0 ? "  ↻" + parent.modelData.restarts : "") } } } } }
            Row { spacing: 8
                Label { text: I18n.tr("Belonging to"); color: Theme.dim; anchors.verticalCenter: parent.verticalCenter }
                Repeater { model: shell.owners
                    Pill { required property var modelData; text: I18n.tr(modelData.name); strong: shell.owner === modelData.id; implicitHeight: 32; onPressed: shell.owner = modelData.id } } }
            Row { spacing: 8
                Label { text: I18n.tr("Sort by"); color: Theme.dim; anchors.verticalCenter: parent.verticalCenter }
                Pill { text: I18n.tr("Processor"); strong: shell.order === "cpu"; implicitHeight: 32; onPressed: shell.order = "cpu" }
                Pill { text: I18n.tr("Memory"); strong: shell.order === "mem"; implicitHeight: 32; onPressed: shell.order = "mem" } }
            Repeater { model: [{ title: QT_TR_NOOP("APPS"), key: "apps" }, { title: QT_TR_NOOP("IN THE BACKGROUND"), key: "background" }]
                Column { id: part; required property var modelData; width: procs.room; spacing: 2
                    readonly property var rows: shell.listed(shell.run ? shell.run[modelData.key] : [])
                    visible: rows.length > 0
                    Label { text: I18n.tr(part.modelData.title) + "  " + part.rows.length; color: Theme.faint; font.pixelSize: 11; font.weight: 700; font.letterSpacing: 0.8; bottomPadding: 6 }
                    // a line stays the same line while its program runs: only its figures change
                    Repeater { model: ScriptModel { values: part.rows.map(p => p.name + "\n" + p.pids[0]) }
                        Line { required property string modelData; width: procs.room
                               what: part.rows.find(p => p.name + "\n" + p.pids[0] === modelData) || { name: "", pids: [], cpu: 0, mem: 0 } } } } }
        }

        // ── what starts by itself ─────────────────────────────────────────────────────────────────────────
        Scroll {
            id: start
            visible: shell.page === "startup"
            Waiting { visible: !starts.data; text: I18n.tr("Looking…"); width: start.room; topPadding: 160 }
            Repeater { model: [{ kind: "app", title: QT_TR_NOOP("WHEN YOU LOG IN"), note: QT_TR_NOOP("Programs that open with your desktop. Switching one off only stops it from starting by itself.") },
                               { kind: "user", title: QT_TR_NOOP("YOUR SERVICES"), note: QT_TR_NOOP("Run in the background for you alone. They can be switched off here and on again.") },
                               { kind: "system", title: QT_TR_NOOP("SERVICES OF THE SYSTEM"), note: QT_TR_NOOP("Belong to the whole computer. They are shown, not switched: that takes the administrator.") }]
                Column { id: group; required property var modelData; width: start.room; spacing: 6
                    readonly property var rows: (starts.data || []).filter(s => s.kind === modelData.kind)
                    visible: rows.length > 0
                    Label { text: I18n.tr(group.modelData.title) + "  " + group.rows.length; color: Theme.faint; font.pixelSize: 11; font.weight: 700; font.letterSpacing: 0.8 }
                    Label { text: I18n.tr(group.modelData.note); color: Theme.dim; font.pixelSize: 12; width: parent.width; wrapMode: Text.WordWrap; bottomPadding: 4 }
                    Repeater { model: group.rows
                        Rectangle { id: item; required property var modelData; width: start.room; height: 64; radius: 16; color: Theme.card; opacity: modelData.on ? 1 : 0.6
                            Rectangle { x: 16; width: 10; height: 10; radius: 5; anchors.verticalCenter: parent.verticalCenter; color: !item.modelData.on ? Theme.faint : (item.modelData.running || item.modelData.kind === "app" ? Theme.ok : Theme.gold) }
                            Column { x: 40; width: parent.width - 40 - tail.width - 30; anchors.verticalCenter: parent.verticalCenter; spacing: 3
                                Label { text: item.modelData.name; font.weight: 600; width: parent.width }
                                Label { text: item.modelData.what; color: Theme.dim; font.pixelSize: 12; width: parent.width; visible: text !== "" } }
                            Row { id: tail; anchors.right: parent.right; anchors.rightMargin: 14; anchors.verticalCenter: parent.verticalCenter; spacing: 10
                                Label { visible: item.modelData.took >= 100; text: (item.modelData.took / 1000).toFixed(1) + " s"; color: item.modelData.took >= 2000 ? Theme.gold : Theme.faint; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                                Rectangle { width: from.implicitWidth + 16; height: 22; radius: 11; color: Theme.raised; anchors.verticalCenter: parent.verticalCenter
                                    Label { id: from; anchors.centerIn: parent; font.pixelSize: 11; color: Theme.dim
                                            text: item.modelData.origin === "yours" ? I18n.tr("yours") : (item.modelData.origin === "system" ? I18n.tr("the system's") : item.modelData.origin) } }
                                // the switch: only on what is the user's own
                                Rectangle { visible: item.modelData.mine; width: 46; height: 26; radius: 13; color: item.modelData.on ? Theme.gold : Theme.raised; anchors.verticalCenter: parent.verticalCenter
                                    Behavior on color { ColorAnimation { duration: 140 } }
                                    Rectangle { width: 20; height: 20; radius: 10; y: 3; x: item.modelData.on ? 23 : 3; color: item.modelData.on ? Theme.ground : Theme.dim; Behavior on x { NumberAnimation { duration: 140 } } }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: shell.act(["startup-set", item.modelData.id, item.modelData.on ? "off" : "on"]) } } } } } } }
        }

        // ── what the sensors say ──────────────────────────────────────────────────────────────────────────
        Scroll {
            id: sensors
            visible: shell.page === "sensors"
            readonly property var chips: { const seen = []; for (const s of (sense.data || [])) if (!seen.includes(s.chip)) seen.push(s.chip); return seen }
            Repeater { model: sensors.chips
                Column { id: chip; required property string modelData; width: sensors.room; spacing: 10
                    Label { text: chip.modelData.toUpperCase(); color: Theme.faint; font.pixelSize: 11; font.weight: 700; font.letterSpacing: 0.8 }
                    Flow { width: parent.width; spacing: 12
                        Repeater { model: (sense.data || []).filter(s => s.chip === chip.modelData)
                            Rectangle { required property var modelData; width: 176; height: 78; radius: 16; color: Theme.card
                                readonly property bool hot: modelData.unit === "°C" && modelData.value >= 85
                                border.width: 1; border.color: hot ? Theme.red : "transparent"
                                Label { x: 14; y: 12; width: parent.width - 28; text: parent.modelData.name; color: Theme.dim; font.pixelSize: 12 }
                                Label { x: 14; y: 32; text: parent.modelData.value + " " + parent.modelData.unit; font.pixelSize: 24; font.weight: 800; color: parent.hot ? Theme.red : Theme.cream } } } } } }
        }
        Item { id: overlay; anchors.fill: parent; Menu { id: menu } }
    }
}
