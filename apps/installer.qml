// LatteOS's installer: the window `get` opens full screen (in cage) on a Fedora 45 Server just installed
// (docs/instalator/PLAN.md, ROADMAP 2.06). It runs on the Quickshell Fedora has, from the source in /opt/latteos/src.
// The side is every step of an install of its own; Fedora's (language, disks, network, account) stand grey with a
// tick: they were done by Fedora's installer, and will be this one's when LatteOS is one image (PLAN part 6).
// Nothing changes before "Install"; then ./install --go --progress, its parts as a list and its percent as the bar.
//   LATTE_SRC=/opt/latteos/src qs -n -p apps/installer.qml
import QtQuick
import Quickshell
import Quickshell.Io
import "common"

ShellRoot {
    id: shell
    readonly property string src: Quickshell.env("LATTE_SRC") || Quickshell.env("LATTE_SHARE") || "/opt/latteos/src"      // FILES and ./install
    // the steps; fedora: done by Fedora's installer, only shown
    readonly property var steps: [
        { id: "welcome", name: QT_TR_NOOP("Welcome"), icon: "mood-smile" },
        { id: "language", name: QT_TR_NOOP("Language and keyboard"), icon: "keyboard", fedora: true },
        { id: "disks", name: QT_TR_NOOP("Disks"), icon: "disc", fedora: true },
        { id: "network", name: QT_TR_NOOP("Network"), icon: "wifi", fedora: true },
        { id: "account", name: QT_TR_NOOP("Account"), icon: "user", fedora: true },
        { id: "check", name: QT_TR_NOOP("This computer"), icon: "cpu" },
        { id: "ai", name: QT_TR_NOOP("AI"), icon: "sparkles" },
        { id: "parts", name: QT_TR_NOOP("Components"), icon: "package" },
        { id: "summary", name: QT_TR_NOOP("Summary"), icon: "list" },
        { id: "install", name: QT_TR_NOOP("Installing"), icon: "download" },
        { id: "done", name: QT_TR_NOOP("Done"), icon: "circle-check" } ]
    readonly property var active: steps.filter(s => !s.fedora)
    property int at: 0                          // in `active`
    readonly property string page: active[at].id
    function next() { if (at < active.length - 1) at += 1 }
    // a picture of one page without a mouse (tests): LATTE_INSTALLER_PAGE=parts; nothing is run from it
    Component.onCompleted: { const p = active.findIndex(s => s.id === Quickshell.env("LATTE_INSTALLER_PAGE")); if (p >= 0) at = p }
    function back() { if (at > 0 && page !== "install" && page !== "done") at -= 1 }

    // ── what the computer is: asked once, shown on "This computer" ──────────────────────────────────────
    property var facts: ({})
    Process { running: true
        command: ["sh", "-c", "printf 'gpu=%s\\n' \"$(lspci 2>/dev/null | grep -Ei 'vga|3d|display' | sed 's/^[^:]*: //' | head -2 | paste -sd ';')\";"
                 + "printf 'ram=%s\\n' \"$(awk '/MemTotal/ {printf \"%.0f\", $2/1048576}' /proc/meminfo)\";"
                 + "printf 'free=%s\\n' \"$(df -h --output=avail / | tail -1 | tr -d ' ')\";"
                 + "printf 'sb=%s\\n' \"$(mokutil --sb-state 2>/dev/null | head -1)\";"
                 + "printf 'kernel=%s\\n' \"$(uname -r)\";"
                 + "printf 'disks=%s\\n' \"$(lsblk -rno NAME,SIZE,MOUNTPOINTS | awk '$3 ~ /^\\// {print $3\" \"$2}' | paste -sd ',')\";"
                 + "printf 'users=%s\\n' \"$(getent passwd | awk -F: '$3 >= 1000 && $3 < 60000 {print $1}' | paste -sd ',')\";"
                 + "printf 'lang=%s\\n' \"$(localectl status 2>/dev/null | sed -n 's/.*LANG=//p' | head -1)\""]
        stdout: StdioCollector { onStreamFinished: { const f = {}; this.text.split("\n").forEach(l => { const k = l.indexOf("="); if (k > 0) f[l.slice(0, k)] = l.slice(k + 1).trim() }); shell.facts = f } } }
    // GFX6 to GFX8 (an RX 640 is one) need Linux 7.3 and Mesa 26.3 (PLAN 3.4)
    readonly property bool oldAmd: /\b(Polaris|Lexa|Baffin|Ellesmere|Tonga|Fiji|Hawaii|Bonaire|Tahiti|Pitcairn|Oland|Cape Verde|Hainan|Iceland|Topaz|Carrizo|Stoney)\b/i.test(facts.gpu || "")

    // ── the components: the optional lines of FILES, each with what it is for ──────────────────────────
    property bool ai: true
    property var groups: []                     // [{ packages: [...], note, chosen }]
    FileView { path: shell.src + "/FILES"; printErrors: false
        onLoaded: {
            const g = []
            let inNeeds = false
            for (const raw of text().split("\n")) {
                if (raw.startsWith("[")) { inNeeds = raw.trim() === "[needs]"; continue }
                const m = inNeeds && raw.match(/^optional:\s*([^#]+?)\s*(?:#\s*(.*))?$/)
                if (m) g.push({ packages: m[1].split(/\s+/), note: (m[2] || "").trim(), chosen: true })
            }
            shell.groups = g
        } }
    readonly property var aiWords: ["mise", "pipewire-utils", "gnome-keyring"]      // the AI services' tools: only with AI
    readonly property var chosenPackages: groups.filter(g => g.chosen && (ai || !g.packages.some(p => aiWords.indexOf(p) >= 0)))
                                                .reduce((all, g) => all.concat(g.packages), [])

    // ── installing: ./install's own lines, read as they come ────────────────────────────────────────────
    property var parts: []                      // [{ name, state: "done" | "now" }]
    property int percent: 0
    property string log: ""
    property real started: 0
    property string failed: ""
    Process { id: run
        command: ["sh", "-c", "cd \"$1\" && ./install --go --progress $3 --with \"$2\" 2>&1", "sh", shell.src, shell.chosenPackages.join(" "), shell.oldAmd ? "--old-amd" : ""]
        stdout: SplitParser { onRead: line => {
            if (line.startsWith("@step ")) {
                const name = line.replace(/^@step \d+\/\d+ /, "")
                shell.parts = shell.parts.map(p => ({ name: p.name, state: "done" })).concat([{ name: name, state: "now" }])
            } else if (line.startsWith("@percent ")) shell.percent = parseInt(line.slice(9))
            else shell.log = (shell.log + line + "\n").slice(-20000)
        } }
        onExited: code => { if (code === 0) { shell.parts = shell.parts.map(p => ({ name: p.name, state: "done" })); shell.percent = 100; shell.next() }
                            else shell.failed = I18n.tr("The install stopped. What it said last is below.") } }
    function install() { parts = []; percent = 0; log = ""; failed = ""; started = Date.now(); next(); run.running = true }
    // what is left, from how fast it has gone so far
    readonly property string left: { percent; if (percent < 3 || percent >= 100) return ""
        const m = Math.round((Date.now() - started) / 60000 * (100 - percent) / percent)
        return m < 1 ? I18n.tr("less than a minute left") : I18n.tr("about {n} min left", { n: m }) }

    // LatteOS shown while it installs, a part at a time
    readonly property var slides: [
        { icon: "droplet", title: QT_TR_NOOP("Goo and its drops"), text: QT_TR_NOOP("The desktop is alive: drops for the clock, power, search and your apps, each a card when you press it.") },
        { icon: "sparkles", title: QT_TR_NOOP("LensAI"), text: QT_TR_NOOP("Every AI in one place: the services' own pages in tabs, what is left of their limits, AI on this computer.") },
        { icon: "brand-windows", title: QT_TR_NOOP("Barista"), text: QT_TR_NOOP("Windows programs, each in a folder and a fence of its own.") },
        { icon: "folders", title: QT_TR_NOOP("DualBrew"), text: QT_TR_NOOP("Files in two panes, archives opened as folders.") },
        { icon: "device-gamepad-2", title: QT_TR_NOOP("The game session"), text: QT_TR_NOOP("Steam Big Picture in one press, and back to the desktop.") },
        { icon: "layout-columns", title: QT_TR_NOOP("Windows your way"), text: QT_TR_NOOP("A tape, tiles or free windows, on each screen its own.") },
        { icon: "lifebuoy", title: QT_TR_NOOP("SAFE and GuardDog"), text: QT_TR_NOOP("When something breaks, a safe session that still works, and a guard that tells you why.") } ]
    property int slide: 0
    Timer { interval: 12000; repeat: true; running: shell.page === "install"; onTriggered: shell.slide = (shell.slide + 1) % shell.slides.length }

    component Switch: Rectangle {              // yes or no, with what it is about beside it (as in Settings)
        id: sw
        property string text
        property string hint
        property bool on: false
        signal pressed()
        width: parent.width; height: 64; radius: 16; color: Theme.card
        Column { x: 18; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 100; spacing: 3
            Label { text: sw.text; font.weight: 600; width: parent.width; elide: Text.ElideRight }
            Label { text: sw.hint; color: Theme.dim; font.pixelSize: 12; width: parent.width; visible: text !== ""; elide: Text.ElideRight } }
        Rectangle { width: 46; height: 26; radius: 13; color: sw.on ? Theme.gold : Theme.raised; anchors.right: parent.right; anchors.rightMargin: 18; anchors.verticalCenter: parent.verticalCenter
            Rectangle { width: 20; height: 20; radius: 10; y: 3; x: sw.on ? 23 : 3; color: sw.on ? Theme.inkOnGold : Theme.dim; Behavior on x { NumberAnimation { duration: 140 } } } }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: sw.pressed() }
    }
    component Text2: Label { width: parent.width; wrapMode: Text.WordWrap; color: Theme.dim }

    AppWindow {
        title: "LatteOS"
        implicitWidth: 1280; implicitHeight: 820          // in cage it is the whole screen anyway
        heading: I18n.tr(shell.active[shell.at].name)
        arrows: true
        canGoBack: shell.at > 0 && shell.page !== "install" && shell.page !== "done"
        onBack: shell.back()
        // every step of an install of its own; Fedora's grey with a tick
        side: [
            Column { x: 14; y: 14; spacing: 4; width: 222
                Row { x: 6; spacing: 10; height: 40
                    Glyph { name: "coffee"; font.pixelSize: 24; color: Theme.gold; anchors.verticalCenter: parent.verticalCenter }
                    Label { text: "LatteOS"; font.pixelSize: 17; font.weight: 700; anchors.verticalCenter: parent.verticalCenter } }
                Item { width: 1; height: 8 }
                Repeater { model: shell.steps
                    Row { required property var modelData; spacing: 10; height: 34; x: 8
                        readonly property int k: shell.active.findIndex(s => s.id === modelData.id)       // (a copy reaches the delegate: by its id)
                        readonly property bool done: modelData.fedora || k < shell.at
                        opacity: modelData.fedora ? 0.45 : (k <= shell.at ? 1 : 0.6)
                        Glyph { name: parent.done ? "check" : parent.modelData.icon; font.pixelSize: 16; anchors.verticalCenter: parent.verticalCenter
                                color: parent.k === shell.at ? Theme.gold : (parent.done ? Theme.ok : Theme.dim) }
                        Column { anchors.verticalCenter: parent.verticalCenter
                            Label { text: I18n.tr(parent.parent.modelData.name); font.weight: parent.parent.k === shell.at ? 700 : 500 }
                            Label { visible: !!parent.parent.modelData.fedora; text: I18n.tr("done by Fedora"); color: Theme.faint; font.pixelSize: 11 } } } } } ]
        foot: [
            Row { anchors.right: parent.right; anchors.rightMargin: 20; anchors.verticalCenter: parent.verticalCenter; spacing: 10
                visible: shell.page !== "install" && shell.page !== "done"
                Pill { icon: "arrow-right"; strong: true; text: shell.page === "summary" ? I18n.tr("Install") : I18n.tr("Next")
                       onPressed: shell.page === "summary" ? shell.install() : shell.next() } } ]

        Flickable { anchors.fill: parent; contentHeight: pageCol.implicitHeight + 60; clip: true; boundsBehavior: Flickable.StopAtBounds
            Column { id: pageCol; x: 40; y: 30; width: Math.min(parent.width - 80, 820); spacing: 16

                // ── Welcome ──
                Column { visible: shell.page === "welcome"; width: parent.width; spacing: 14
                    Label { text: I18n.tr("Welcome to LatteOS"); font.pixelSize: 30; font.weight: 800 }
                    Text2 { text: I18n.tr("A desktop for people who know Windows, on Fedora. Everything works with the mouse.") }
                    Text2 { text: I18n.tr("This is an early version (alpha): things can break. Install it on a computer you can try things on.") }
                    Text2 { text: I18n.tr("Fedora has already done the language, the disks, the network and your account (grey on the left). This window adds LatteOS; nothing changes until you press Install.") } }

                // ── This computer ──
                Column { visible: shell.page === "check"; width: parent.width; spacing: 10
                    Repeater { model: [
                            { k: QT_TR_NOOP("Graphics"), v: shell.facts.gpu || "…" },
                            { k: QT_TR_NOOP("Memory"), v: shell.facts.ram ? shell.facts.ram + " GB" : "…" },
                            { k: QT_TR_NOOP("Free on the system disk"), v: shell.facts.free || "…" },
                            { k: QT_TR_NOOP("Disks (done by Fedora)"), v: shell.facts.disks || "…" },
                            { k: QT_TR_NOOP("Users (done by Fedora)"), v: shell.facts.users || "…" },
                            { k: QT_TR_NOOP("Secure Boot"), v: shell.facts.sb || I18n.tr("unknown") },
                            { k: QT_TR_NOOP("Linux"), v: shell.facts.kernel || "…" } ]
                        Rectangle { required property var modelData; width: pageCol.width; height: 52; radius: 14; color: Theme.card
                            Label { x: 18; width: 220; text: I18n.tr(parent.modelData.k); color: Theme.dim; anchors.verticalCenter: parent.verticalCenter }
                            Label { x: 240; width: parent.width - 260; text: parent.modelData.v; elide: Text.ElideRight; anchors.verticalCenter: parent.verticalCenter } } }
                    Text2 { visible: shell.oldAmd; color: Theme.gold
                            text: I18n.tr("This graphics card needs Linux 7.3 and Mesa 26.3, which LatteOS brings until Fedora has them. That Linux is not signed: with Secure Boot on it will not start.") } }

                // ── AI ──
                Column { visible: shell.page === "ai"; width: parent.width; spacing: 12
                    Text2 { text: I18n.tr("Generative AI is a choice. Without it, nothing of it is shown and nothing of it is installed; searching your files by their content still works.") }
                    Switch { text: I18n.tr("AI in LatteOS"); hint: I18n.tr("LensAI, the AI services' tools, AI on this computer"); on: shell.ai; onPressed: shell.ai = !shell.ai } }

                // ── Components ──
                Column { visible: shell.page === "parts"; width: parent.width; spacing: 10
                    Text2 { text: I18n.tr("What else to install with LatteOS. Under each, the packages it brings.") }
                    Repeater { model: shell.groups.length
                        Switch { required property int index; width: pageCol.width
                                 readonly property var g: shell.groups[index]
                                 visible: shell.ai || !g.packages.some(p => shell.aiWords.indexOf(p) >= 0)
                                 // what it is for, said for a person: FILES's note without its pointers into the source
                                 text: g.note.replace(/\s*\([^)]*[\/.][a-z][^)]*\)/g, "").replace(/^./, c => c.toUpperCase()) || g.packages.join(" ")
                                 hint: g.packages.join(" "); on: g.chosen
                                 onPressed: { const l = shell.groups.slice(); l[index] = Object.assign({}, g, { chosen: !g.chosen }); shell.groups = l } } } }

                // ── Summary ──
                Column { visible: shell.page === "summary"; width: parent.width; spacing: 10
                    Text2 { text: I18n.tr("LatteOS, pleamar and pleamar-wm (built here with LatteOS's patches), and these from Fedora:") }
                    Rectangle { width: parent.width; height: chosenText.implicitHeight + 28; radius: 14; color: Theme.card
                        Label { id: chosenText; x: 16; y: 14; width: parent.width - 32; wrapMode: Text.WordWrap; text: shell.chosenPackages.join("  ·  ") || "—" } }
                    Text2 { text: I18n.tr("It takes about half an hour, most of it building. The computer can be left alone meanwhile.") } }

                // ── Installing: the parts on the left, LatteOS shown on the right, the bar under them ──
                Item { visible: shell.page === "install"; width: parent.width; height: 360
                    Column { width: parent.width * 0.45; spacing: 8
                        Repeater { model: shell.parts
                            Row { required property var modelData; spacing: 10
                                Glyph { name: modelData.state === "done" ? "check" : "loader-2"; color: modelData.state === "done" ? Theme.ok : Theme.gold; font.pixelSize: 16 }
                                Label { text: I18n.tr(modelData.name); font.weight: modelData.state === "now" ? 700 : 500 } } }
                        Label { visible: shell.parts.length === 0; text: I18n.tr("Starting…"); color: Theme.dim } }
                    Rectangle { x: parent.width * 0.5; width: parent.width * 0.5; height: 220; radius: 18; color: Theme.card
                        readonly property var s: shell.slides[shell.slide]
                        Glyph { x: 22; y: 22; name: parent.s.icon; font.pixelSize: 40; color: Theme.gold }
                        Label { x: 22; y: 82; text: I18n.tr(parent.s.title); font.pixelSize: 20; font.weight: 800 }
                        Label { x: 22; y: 116; width: parent.width - 44; wrapMode: Text.WordWrap; color: Theme.dim; text: I18n.tr(parent.s.text) } }
                    Column { y: 250; width: parent.width; spacing: 8
                        DotBar { width: parent.width; height: 12; segments: 40; value: shell.percent / 100; tint: shell.failed ? Theme.red : Theme.gold }
                        Row { spacing: 16
                            Label { text: shell.percent + " %"; font.weight: 800; color: Theme.gold }
                            Label { text: shell.left; color: Theme.dim } }
                        Label { visible: shell.failed !== ""; text: shell.failed; color: Theme.red }
                        Pill { visible: shell.failed !== ""; icon: "refresh"; text: I18n.tr("Try again"); onPressed: { shell.at -= 1; shell.install() } } } }

                // ── Done ──
                Column { visible: shell.page === "done"; width: parent.width; spacing: 14
                    Label { text: I18n.tr("LatteOS is installed"); font.pixelSize: 30; font.weight: 800 }
                    Text2 { text: I18n.tr("It starts with the next boot.") }
                    Pill { icon: "refresh"; strong: true; text: I18n.tr("Restart now"); onPressed: Quickshell.execDetached(["systemctl", "reboot"]) } }

                // what ./install said, for when it goes wrong
                Rectangle { visible: shell.page === "install" && shell.log !== ""; width: parent.width; height: 160; radius: 14; color: Theme.card; clip: true
                    Flickable { anchors.fill: parent; anchors.margins: 12; contentHeight: logText.implicitHeight; contentY: Math.max(0, contentHeight - height)
                        Text { id: logText; width: parent.width; text: shell.log; color: Theme.dim; font.family: "monospace"; font.pixelSize: 11; wrapMode: Text.WrapAnywhere } } }
            }
        }
    }
}
