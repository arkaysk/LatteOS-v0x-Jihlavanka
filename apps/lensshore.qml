// LensShore: the launcher built around the AI, instead of the drop LensGoo when Settings › Drops › Launcher says so
// (ROADMAP 6B.12), after the island of K4 (https://github.com/k4ditano/k4, MIT). At rest it is goo: a capsule the Goo
// scene draws at the top or the bottom edge (goo/drops/lensbase.luau), one body with the other drops; this draws on it
// the line to type into. Typed into, an island grows out of the capsule away from the edge, as wide as it, its foot
// never leaving the edge, and shows nearest the line first what can be done at once, then the apps, the files and
// folders, the web. A click opens one; Enter or the send button ask the AI, whose answer comes in the island, with
// what it suggests doing as buttons. Around the line: the conversations (left), where the text would go (this computer
// or a service), the microphone and send (right). What the AI may see shows as chips: the selected text, the clipboard,
// the window in front, files dropped on the island. The right button on the field: cut, copy, paste, unlock the place.
// The Goo starts it (goo/lib/lens.luau) and passes it the Windows key (qs ipc … call lens toggle); it ends itself when
// the Settings turn it off.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "common"

ShellRoot {
    id: shell
    readonly property string data: (Quickshell.env("XDG_DATA_HOME") || (Quickshell.env("HOME") + "/.local/share")) + "/pleamar/goo"
    readonly property string state: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/latteos/ai/chats"
    readonly property string home: Quickshell.env("HOME") || ""

    // ── what the Goo keeps: on or off, the edge and the place along it ────────────────────────────────────
    property var kept: ({})
    readonly property bool top: kept.lens_top !== false
    readonly property real along: typeof kept.lens_x === "number" ? kept.lens_x : 0.5
    FileView {
        id: settings
        path: shell.data + "/settings.json"
        printErrors: false; watchChanges: true
        onFileChanged: reload()
        onLoaded: { try { shell.kept = JSON.parse(text()) } catch (e) { shell.kept = {} } if (shell.kept.lens !== "shore") Qt.quit() }
        onLoadFailed: Qt.quit()
        function put(changes) { const k = Object.assign({}, shell.kept, changes); shell.kept = k; setText(JSON.stringify(k)) }
    }

    // the goo's own colour, from the user's coffee (as goo/parts/drops.plm mixes it), dark enough under cream writing
    property real water: 0
    property real milk: 0
    Process { command: ["latte-login", "coffee"]; running: true
              stdout: StdioCollector { onStreamFinished: { try { const c = JSON.parse(this.text); shell.water = c[0]; shell.milk = c[1] } catch (e) {} } } }
    function mix(a, b, t) { return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1) }
    function smooth(e0, e1, x) { const t = Math.max(0, Math.min(1, (x - e0) / (e1 - e0))); return t * t * (3 - 2 * t) }
    readonly property color coffee: mix(mix(Qt.color("#1c0f09"), Qt.color("#4a2410"), water), Qt.color("#c9a47a"), Math.pow(milk, 2))
    readonly property color goo: mix(coffee, Qt.color("#2a1a12"), smooth(0.45, 0.8, milk) * 0.85)
    readonly property color rim: mix(goo, Qt.color("#f3ebdd"), 0.14)
    readonly property color ink: Theme.inkOnCoffee
    readonly property color soft: Qt.rgba(ink.r, ink.g, ink.b, 0.55)
    readonly property color lit: Qt.rgba(ink.r, ink.g, ink.b, 0.1)

    // ── where it lies: the Goo is told, its capsule lies there and the drops keep off ─────────────────────
    readonly property int wide: 620            // folded or grown, always this wide, always here
    readonly property int lineH: 46            // the capsule's thickness (23 × 2)
    readonly property int gap: 6               // from the screen's edge to the capsule: the goo's surface (goo/parts/drops.plm, LEVEL)
    function tell() {
        const a = Math.round(island.restX)
        Quickshell.execDetached(["latte-say", "fact lens_edge " + (top ? 2 : 0), "fact lens_a " + a, "fact lens_b " + (a + wide)])
    }
    Timer { id: telling; interval: 300; onTriggered: shell.tell() }
    onTopChanged: telling.restart()
    onAlongChanged: telling.restart()

    // ── what is typed, and what was found for it ───────────────────────────────────────────────────────────
    property string q: ""
    property bool open: false
    property bool locked: true
    property string view: "find"               // find · talk (the conversation) · chats (the history)
    property bool moreApps: false
    property bool moreFiles: false
    readonly property string t: q.trim()
    onQChanged: { moreApps = false; moreFiles = false; if (q !== "") { view = "find"; open = true } pause.restart() }

    readonly property var apps: {
        const want = t.toLowerCase()
        if (want === "") return []
        const starts = [], within = []
        for (const e of DesktopEntries.applications.values.filter(e => !e.noDisplay)) {
            const n = (e.name || "").toLowerCase(), g = (e.genericName || "").toLowerCase()
            if (n.startsWith(want)) starts.push(e)
            else if (n.includes(want) || g.includes(want) || (e.id || "").toLowerCase().includes(want)) within.push(e)
        }
        return starts.concat(within).slice(0, 18)
    }
    property var files: []
    property bool looking: false
    Process {
        id: fd
        stdout: StdioCollector { onStreamFinished: {
            const want = shell.t.toLowerCase(), a = [], b = []
            for (const p of this.text.split("\n").filter(l => l !== "")) {
                const name = p.replace(/\/$/, "").split("/").pop().toLowerCase()
                ;(name.startsWith(want) ? a : b).push(p)
            }
            shell.files = a.concat(b); shell.looking = false
        } }
    }
    // a sum or an amount: Qalculate, as LensGoo does
    property string worked: ""
    Process { id: qalc; stdout: StdioCollector { onStreamFinished: { const r = this.text.split("\n")[0].trim(); shell.worked = (r && !/error|warning/i.test(r) && r !== shell.t) ? r : "" } } }
    Timer { id: pause; interval: 160
            onTriggered: {
                shell.files = []; shell.worked = ""
                if (shell.t === "") return
                shell.looking = true
                fd.running = false; fd.command = ["fd", "--max-results", "14", "--absolute-path", "--ignore-case", "--", shell.t, shell.home]; fd.running = true
                if ((/^[\d\s.,+\-*/^()%]+$/.test(shell.t) && /\d/.test(shell.t)) || /\d.* (to|na|v|in) /.test(shell.t)) {
                    qalc.running = false; qalc.command = ["qalc", "-t", shell.t]; qalc.running = true
                }
            } }

    // What can be done at once, with no AI and nothing leaving the computer: a few sentences as the user would say them.
    // The words are the English ones and the user's own (the translation table), so each language says them its way.
    function say(en) { return [en, I18n.tr(en).toLowerCase()].map(x => x.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")).join("|") }
    readonly property var quick: {
        const s = t.toLowerCase(), out = []
        let m
        if (worked !== "") out.push({ glyph: "calculator", label: worked, copy: worked })
        if ((m = s.match(new RegExp("^(" + say("brightness") + ")\\s+(\\d{1,3})\\s*%?$"))))
            out.push({ glyph: "sun", label: I18n.tr("Set the brightness to {n} %", { n: m[2] }), cmd: ["brightnessctl", "set", m[2] + "%"] })
        if ((m = s.match(new RegExp("^(" + say("volume") + ")\\s+(\\d{1,3})\\s*%?$"))))
            out.push({ glyph: "volume", label: I18n.tr("Set the volume to {n} %", { n: m[2] }), cmd: ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", String(Number(m[2]) / 100)] })
        if (new RegExp("^(" + say("turn on wifi") + ")$").test(s)) out.push({ glyph: "wifi", label: I18n.tr("Turn the Wi-Fi on"), cmd: ["nmcli", "radio", "wifi", "on"] })
        if (new RegExp("^(" + say("turn off wifi") + ")$").test(s)) out.push({ glyph: "wifi-off", label: I18n.tr("Turn the Wi-Fi off"), cmd: ["nmcli", "radio", "wifi", "off"] })
        if ((m = s.match(new RegExp("^(" + say("timer") + ")\\s+(\\d{1,3})\\s*(min)?$"))))
            out.push({ glyph: "clock", label: I18n.tr("A timer for {n} min", { n: m[2] }),
                       cmd: ["sh", "-c", "sleep " + Number(m[2]) * 60 + " && notify-send -a LatteOS \"" + I18n.tr("Timer") + "\" \"" + I18n.tr("{n} min are up", { n: m[2] }) + "\""] })
        if (new RegExp("^(" + say("do not disturb") + ")$").test(s)) out.push({ glyph: "bell-off", label: I18n.tr("Do not disturb"), set: { quiet: !shell.kept.quiet } })
        return out
    }

    // the user's search engine, as LensGoo keeps it; LensGoo's choice of AI too
    property string engine: "duckduckgo"
    readonly property var engines: ({ duckduckgo: ["DuckDuckGo", "https://duckduckgo.com/?q=%s"], google: ["Google", "https://www.google.com/search?q=%s"],
                                     bing: ["Bing", "https://www.bing.com/search?q=%s"], startpage: ["Startpage", "https://www.startpage.com/do/search?q=%s"],
                                     ecosia: ["Ecosia", "https://www.ecosia.org/search?q=%s"], brave: ["Brave Search", "https://search.brave.com/search?q=%s"] })
    property var lensKept: ({})
    FileView { path: shell.data + "/lens.json"; printErrors: false
               onLoaded: { try { shell.lensKept = JSON.parse(text()); shell.engine = shell.lensKept.engine || "duckduckgo" } catch (e) {} } }

    function go(cmd) { Quickshell.execDetached(cmd); close(true) }
    function close(clear) { open = false; if (clear) { q = ""; attached = [] } }

    // ── what the AI may see: chips the user switches on (nothing goes that is not shown on one) ──────────────
    property string picked: ""                 // the text selected anywhere (the primary selection)
    property string clip: ""
    property string front: ""                  // the window in front: its title and program
    property var useCtx: ({ picked: false, clip: false, front: false })
    property var attached: []                  // files dropped on the island
    Process { id: readPicked; command: ["wl-paste", "--primary", "--no-newline"]; stdout: StdioCollector { onStreamFinished: shell.picked = this.text.slice(0, 4000) } }
    Process { id: readClip; command: ["wl-paste", "--no-newline"]; stdout: StdioCollector { onStreamFinished: shell.clip = this.text.slice(0, 4000) } }
    Process { id: readFront; command: ["hyprctl", "-j", "activewindow"]
              stdout: StdioCollector { onStreamFinished: { try { const w = JSON.parse(this.text); shell.front = w.title ? (w.title + " (" + w.class + ")") : "" } catch (e) { shell.front = "" } } } }
    onOpenChanged: if (open) { readPicked.running = true; readClip.running = true; readFront.running = true }
    function context() {
        const parts = []
        if (useCtx.picked && picked) parts.push(I18n.tr("Selected text") + ":\n" + picked)
        if (useCtx.clip && clip) parts.push(I18n.tr("Clipboard") + ":\n" + clip)
        if (useCtx.front && front) parts.push(I18n.tr("The window in front") + ": " + front)
        return parts.length ? parts.join("\n\n") + "\n\n" : ""
    }
    function flip(key) { const c = Object.assign({}, useCtx); c[key] = !c[key]; useCtx = c }

    // ── the AI: the user's default (LensGoo's, or the one chosen here); the answer comes in pieces ──────────
    property var providers: []
    property var provider: null
    property string modelId: ""
    property string chat: "new"
    property var talk: []                      // [{ mine, text }]
    property string live: ""
    property bool fresh: false                 // an answer came while the island was shut: a dot on it
    Process { command: ["latte-ai", "providers"]; running: true
              stdout: StdioCollector { onStreamFinished: {
                  try { shell.providers = JSON.parse(this.text) } catch (e) { shell.providers = [] }
                  const want = shell.kept.lens_ai || (shell.lensKept.ai || {}).provider
                  shell.choose(shell.providers.find(p => p.id === want) || shell.providers[0] || null)
              } } }
    function choose(p) {
        provider = p
        modelId = p ? (((p.models || []).find(m => m.id === (lensKept.ai || {}).model) || (p.models || [])[0] || { id: "" }).id) : ""
    }
    Process {
        id: ask
        stdout: SplitParser { onRead: line => {
            let m = null
            try { m = JSON.parse(line) } catch (e) { return }
            if (m.delta) shell.live += m.delta
            else if (m.chat) { shell.chat = m.chat; shell.talk = shell.talk.concat([{ mine: false, text: m.answer || "" }]); shell.live = "" }
        } }
        onExited: { if (shell.live !== "") { shell.talk = shell.talk.concat([{ mine: false, text: shell.live }]); shell.live = "" } if (!shell.open) shell.fresh = true }
    }
    // Enter or the send button: always the AI (6B.12); with the AI off, the first thing found is opened
    function send() {
        if (t === "") return
        if (!provider) { if (quick.length) run(quick[0]); else if (apps.length) { apps[0].execute(); close(true) } else if (files.length) go(["xdg-open", files[0].replace(/\/$/, "")]); return }
        const asked = context() + t
        talk = talk.concat([{ mine: true, text: t }]); live = ""; view = "talk"; open = true
        const cmd = ["latte-ai", "send", chat, provider.id, modelId, asked, "--stream"]
        for (const f of attached) cmd.push("--attach", f)
        ask.running = false; ask.command = cmd; ask.running = true
        q = ""; attached = []; useCtx = ({ picked: false, clip: false, front: false })
    }
    function run(a) {
        if (a.cmd) go(a.cmd)
        else if (a.set) { settings.put(a.set); close(true) }
        else if (a.copy) { Quickshell.clipboardText = a.copy; close(true) }
    }
    // what an answer suggests doing: the commands in it, the addresses in it
    function suggested(text) {
        const out = []
        const code = /```(?:sh|bash|shell|zsh)?\n([\s\S]*?)```/g
        let m
        while ((m = code.exec(text)) && out.length < 3) out.push({ kind: "cmd", value: m[1].trim() })
        const urls = text.match(/https?:\/\/[^\s)>\]]+/g) || []
        for (const u of urls.slice(0, 2)) out.push({ kind: "url", value: u })
        return out
    }

    // the conversations kept (latte-ai chats), and one of them opened to go on with it
    property var chats: []
    Process { id: readChats; command: ["latte-ai", "chats"]; stdout: StdioCollector { onStreamFinished: { try { shell.chats = JSON.parse(this.text).slice(0, 8) } catch (e) { shell.chats = [] } } } }
    FileView { id: chatFile; printErrors: false
               onLoaded: { try { const c = JSON.parse(text()); shell.chat = c.id; shell.talk = (c.messages || []).map(m => ({ mine: m.role === "user", text: m.content })); shell.view = "talk" } catch (e) {} } }
    function showChats() { readChats.running = true; view = "chats"; open = true; fresh = false }
    function openChat(id) { chatFile.path = ""; chatFile.path = state + "/" + id + ".json" }

    // the microphone: latte-ai listens on this computer and writes what was said into the line
    property bool listening: false
    Process { id: listen; stdout: StdioCollector { onStreamFinished: { try { const r = JSON.parse(this.text); if (r.text) shell.q = (shell.q ? shell.q + " " : "") + r.text } catch (e) {} } } }
    function mic() {
        listen.running = false
        listen.command = ["latte-ai", "listen", listening ? "stop" : "start"]
        listening = !listening
        listen.running = true
    }

    IpcHandler {
        target: "lens"
        function toggle(): void { if (shell.open) shell.close(false); else { shell.open = true; field.forceActiveFocus() } }
    }

    // ── the island ─────────────────────────────────────────────────────────────────────────────────────────
    PanelWindow {
        id: win
        // The whole screen, anchored at the top whichever edge the island is at: a surface cannot change its edge while
        // it lives, the island moves inside it. Only the island (and the catcher while open) takes the pointer.
        WlrLayershell.namespace: "latte-lensshore"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: shell.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.OnDemand
        anchors { left: true; right: true; top: true }
        implicitHeight: screen ? screen.height : 1080
        exclusiveZone: 0                       // the goo keeps its own band at every edge
        color: "transparent"
        mask: Region { item: island
                       Region { item: shell.open ? catcher : null; intersection: Intersection.Combine }
                       Region { item: menu.visible ? menu : null; intersection: Intersection.Combine } }

        // a press anywhere else lets it sink back into the capsule, as Esc does; what was typed stays
        MouseArea { id: catcher; anchors.fill: parent; enabled: shell.open; onPressed: shell.close(false) }

        Item {
            id: island
            readonly property real grown: shell.open ? Math.min(body.implicitHeight + 24, win.height - shell.lineH - 80) : 0
            readonly property real restX: Math.max(12, Math.min(parent.width - shell.wide - 12, shell.along * parent.width - shell.wide / 2))
            onRestXChanged: telling.restart()
            // dragged, it follows the pointer; let go, it settles at the nearer edge where it was let go
            property bool dragging: false
            property bool settling: false
            property real dragX: 0
            property real dragY: 0
            width: shell.wide
            height: shell.gap + shell.lineH + growth
            // the growth springs; the foot never leaves the edge, so the island's place follows its height at once
            property real growth: grown
            Behavior on growth { NumberAnimation { duration: 460; easing.type: Easing.OutBack; easing.overshoot: 0.5 } }
            x: dragging ? dragX : restX
            y: dragging ? dragY : (shell.top ? 0 : parent.height - height)
            Behavior on x { enabled: island.settling; NumberAnimation { duration: 380; easing.type: Easing.OutBack } }
            Behavior on y { enabled: island.settling; NumberAnimation { duration: 380; easing.type: Easing.OutBack } }
            Timer { id: settled; interval: 420; onTriggered: island.settling = false }

            // files dropped on it: for the AI to read (only those, never the rest of the computer)
            DropArea {
                anchors.fill: parent
                onDropped: drop => { const add = (drop.urls || []).map(u => decodeURIComponent(String(u).replace(/^file:\/\//, ""))); shell.attached = shell.attached.concat(add); shell.open = true; field.forceActiveFocus() }
            }

            // the island itself, grown out of the capsule: as wide, its foot on it; at rest the goo's own capsule shows
            Rectangle {
                x: 0; width: parent.width
                y: shell.top ? shell.gap : 0
                height: shell.lineH + island.growth
                radius: shell.lineH / 2
                color: shell.goo
                border.width: 1.5; border.color: shell.rim
                opacity: island.growth > 2 || island.dragging ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 120 } }
            }

            // ── the line, on the capsule ──
            Item {
                id: line
                width: parent.width; height: shell.lineH
                y: shell.top ? shell.gap : parent.height - shell.gap - height
                // left: the conversations; a dot when an answer came meanwhile, a pulse while the AI is still at it
                Rectangle {
                    x: 6; width: 36; height: 36; radius: 18; anchors.verticalCenter: parent.verticalCenter
                    color: talkHit.containsMouse ? shell.lit : "transparent"
                    Glyph { anchors.centerIn: parent; name: "messages"; font.pixelSize: 18; color: shell.ink; opacity: 0.85 }
                    Rectangle { visible: shell.fresh; width: 8; height: 8; radius: 4; color: Theme.gold; x: 25; y: 5 }
                    SequentialAnimation on opacity { running: ask.running && !shell.open; loops: Animation.Infinite
                        NumberAnimation { to: 0.45; duration: 600 } NumberAnimation { to: 1; duration: 600 } }
                    MouseArea { id: talkHit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (shell.open && shell.view !== "find") return shell.close(false)
                                    if (shell.talk.length) { shell.view = "talk"; shell.open = true; shell.fresh = false } else shell.showChats()
                                } }
                }
                // the field: the only place to type, lit so it reads as one
                Rectangle {
                    x: 46; width: parent.width - 46 - 118; height: 34; radius: 17; anchors.verticalCenter: parent.verticalCenter
                    color: Qt.rgba(0, 0, 0, field.activeFocus ? 0.28 : 0.18)
                    border.width: 1; border.color: field.activeFocus ? Qt.rgba(Theme.gold.r, Theme.gold.g, Theme.gold.b, 0.5) : "transparent"
                    Glyph { x: 11; name: "search"; font.pixelSize: 15; color: shell.soft; anchors.verticalCenter: parent.verticalCenter }
                    TextInput {
                        id: field
                        x: 34; width: parent.width - 44; anchors.verticalCenter: parent.verticalCenter
                        color: shell.ink; font.family: Theme.font; font.pixelSize: 15; clip: true; selectByMouse: true
                        selectionColor: Qt.rgba(1, 1, 1, 0.2)
                        text: shell.q; onTextEdited: shell.q = text
                        onAccepted: shell.send()
                        Keys.onEscapePressed: shell.close(false)
                        Label { text: shell.attached.length ? I18n.tr("Ask about what you dropped…") : I18n.tr("Search or ask…"); color: shell.soft; visible: field.text === ""; font.pixelSize: 15; anchors.verticalCenter: parent.verticalCenter }
                    }
                    // the right button here: cut, copy, paste, and the place
                    MouseArea { anchors.fill: parent; acceptedButtons: Qt.RightButton
                                onPressed: mouse => { field.forceActiveFocus(); const at = mapToItem(menu, mouse.x, mouse.y); menu.popupAt(at.x, shell.top ? at.y : at.y - 200) } }
                }
                // where the text would go: this computer or a service; a press chooses who answers
                Rectangle {
                    x: parent.width - 112; width: 32; height: 32; radius: 16; anchors.verticalCenter: parent.verticalCenter; visible: shell.provider !== null
                    color: whoHit.containsMouse ? shell.lit : "transparent"
                    Glyph { anchors.centerIn: parent; name: shell.provider && shell.provider.local ? "home" : "cloud"; font.pixelSize: 16; color: shell.soft }
                    MouseArea { id: whoHit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: { const at = mapToItem(menu, 0, 0); menu.chooseAt(at.x, shell.top ? at.y + 36 : at.y - 40 - 32 * shell.providers.length) } }
                }
                // the microphone
                Rectangle {
                    x: parent.width - 78; width: 32; height: 32; radius: 16; anchors.verticalCenter: parent.verticalCenter
                    color: shell.listening ? Theme.red : (micHit.containsMouse ? shell.lit : "transparent")
                    Glyph { anchors.centerIn: parent; name: shell.listening ? "player-stop" : "microphone"; font.pixelSize: 16; color: shell.listening ? "white" : shell.soft }
                    MouseArea { id: micHit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: shell.mic() }
                }
                // send: lit when there is something to send
                Rectangle {
                    x: parent.width - 42; width: 32; height: 32; radius: 16; anchors.verticalCenter: parent.verticalCenter
                    color: shell.t !== "" ? Theme.gold : (sendHit.containsMouse ? shell.lit : "transparent")
                    Glyph { anchors.centerIn: parent; name: "arrow-up"; font.pixelSize: 16; color: shell.t !== "" ? "#2a170c" : shell.soft }
                    MouseArea { id: sendHit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: shell.send() }
                }
                // unlocked, it is dragged anywhere and settles at the nearer of the top and the bottom edge, where it was let go
                MouseArea {
                    anchors.fill: parent; enabled: !shell.locked; cursorShape: island.dragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                    property point grab
                    onPressed: mouse => { grab = Qt.point(mouse.x, mouse.y + line.y); island.dragX = island.x; island.dragY = island.y; island.dragging = true }
                    onPositionChanged: mouse => { if (!island.dragging) return; const at = mapToItem(win.contentItem, mouse.x, mouse.y); island.dragX = at.x - grab.x; island.dragY = at.y - grab.y }
                    onReleased: mouse => {
                        const at = mapToItem(win.contentItem, mouse.x, mouse.y)
                        settings.put({ lens_top: at.y < win.contentItem.height / 2, lens_x: Math.max(0, Math.min(1, (island.dragX + shell.wide / 2) / win.contentItem.width)) })
                        island.settling = true; settled.restart(); island.dragging = false
                    }
                }
            }

            // ── what grows out: nearest the line what is looked for most ──
            Flickable {
                id: scroll
                x: 18; width: parent.width - 36
                y: shell.top ? shell.gap + shell.lineH + 8 : 16
                height: Math.max(0, island.growth - 24)
                contentHeight: body.implicitHeight; clip: true
                opacity: shell.open ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 180 } }
                contentY: shell.top ? 0 : Math.max(0, contentHeight - height)
                Column {
                    id: body
                    width: scroll.width
                    spacing: 14
                    Repeater {
                        model: {
                            const parts = shell.view === "talk" ? ["talk", "context"] : shell.view === "chats" ? ["chats"] : ["context", "quick", "apps", "files", "web", "hint"]
                            return shell.top ? parts : parts.slice().reverse()
                        }
                        // a part with nothing to show takes no room
                        Loader { required property string modelData; width: body.width; visible: item !== null && item.shown !== false
                                 sourceComponent: ({ context: contextPart, quick: quickPart, apps: appsPart, files: filesPart, web: webPart, hint: hintPart, talk: talkPart, chats: chatsPart })[modelData] }
                    }
                }
            }

            Component { id: hintPart
                Label { property bool shown: shell.t === ""; leftPadding: 6; color: shell.soft; wrapMode: Text.Wrap
                        text: shell.provider ? I18n.tr("Type to search; Enter asks the AI") : I18n.tr("Type to search") } }

            // the chips: what the AI may see, switched on by a press
            Component { id: contextPart
                Flow { spacing: 6; property bool shown: shell.picked !== "" || shell.clip !== "" || shell.front !== "" || shell.attached.length > 0
                    Chip { visible: shell.picked !== ""; glyph: "cursor-text"; label: I18n.tr("Selected text"); on: shell.useCtx.picked; onPressed: shell.flip("picked") }
                    Chip { visible: shell.clip !== "" && shell.clip !== shell.picked; glyph: "clipboard"; label: I18n.tr("Clipboard"); on: shell.useCtx.clip; onPressed: shell.flip("clip") }
                    Chip { visible: shell.front !== ""; glyph: "app-window"; label: shell.front.split(" (")[0].slice(0, 32); on: shell.useCtx.front; onPressed: shell.flip("front") }
                    Repeater { model: shell.attached
                        Chip { required property string modelData; glyph: "paperclip"; label: modelData.split("/").pop(); on: true
                               onPressed: shell.attached = shell.attached.filter(f => f !== modelData) } } } }

            Component { id: quickPart
                Column { spacing: 2; property bool shown: shell.quick.length > 0
                    Section { text: I18n.tr("Do it now") }
                    Repeater { model: shell.quick
                        Row_ { required property var modelData; glyph: modelData.glyph; label: modelData.label; hint: modelData.copy ? I18n.tr("click copies") : ""; onRun: shell.run(modelData) } } } }

            Component { id: appsPart
                Column { spacing: 6; property bool shown: shell.apps.length > 0
                    Section { text: I18n.tr("Applications") }
                    Flow { width: parent.width; spacing: 4
                        Repeater { model: shell.apps.slice(0, shell.moreApps ? 18 : 5)
                            Rectangle { required property var modelData
                                width: 96; height: 84; radius: 14; color: tileHit.containsMouse ? shell.lit : "transparent"
                                Image { width: 40; height: 40; anchors.horizontalCenter: parent.horizontalCenter; y: 10; sourceSize: Qt.size(80, 80)
                                        source: Quickshell.iconPath(parent.modelData.icon, "application-x-executable") }
                                Label { width: parent.width - 8; anchors.horizontalCenter: parent.horizontalCenter; y: 58; horizontalAlignment: Text.AlignHCenter
                                        text: parent.modelData.name; color: shell.ink; font.pixelSize: 12 }
                                MouseArea { id: tileHit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                            onClicked: { parent.modelData.execute(); shell.close(true) } } } }
                        Rectangle { visible: shell.apps.length > 5 && !shell.moreApps; width: 96; height: 84; radius: 14; color: moreHit.containsMouse ? shell.lit : "transparent"
                            Glyph { anchors.horizontalCenter: parent.horizontalCenter; y: 18; name: "dots"; font.pixelSize: 26; color: shell.soft }
                            Label { width: parent.width; y: 58; horizontalAlignment: Text.AlignHCenter; text: I18n.tr("More"); color: shell.soft; font.pixelSize: 12 }
                            MouseArea { id: moreHit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: shell.moreApps = true } } } } }

            Component { id: filesPart
                Column { spacing: 2; property bool shown: shell.t !== ""
                    Section { text: I18n.tr("Files and folders") }
                    Label { visible: shell.files.length === 0; leftPadding: 6; color: shell.soft; text: shell.looking ? I18n.tr("Searching…") : I18n.tr("Nothing found") }
                    Repeater { model: shell.files.slice(0, shell.moreFiles ? 12 : 4)
                        Row_ { required property string modelData
                               readonly property string clean: modelData.replace(/\/$/, "")
                               glyph: modelData.endsWith("/") ? "folder" : "file"; label: clean.split("/").pop()
                               hint: clean.substring(0, clean.lastIndexOf("/")).replace(shell.home, "~")
                               onRun: shell.go(["xdg-open", clean]) } }
                    Row_ { visible: shell.files.length > 4 && !shell.moreFiles; glyph: "dots"; label: I18n.tr("More files"); onRun: shell.moreFiles = true } } }

            Component { id: webPart
                Column { spacing: 2; property bool shown: shell.t !== ""
                    Section { text: I18n.tr("Internet") }
                    Row_ { glyph: "world"; label: I18n.tr("Search for “{what}” on {engine}", { what: shell.t, engine: (shell.engines[shell.engine] || shell.engines.duckduckgo)[0] })
                           onRun: shell.go(["xdg-open", (shell.engines[shell.engine] || shell.engines.duckduckgo)[1].replace("%s", encodeURIComponent(shell.t))]) } } }

            // the conversation: the question on the right, the answer on the left, and what it suggests doing as buttons
            Component { id: talkPart
                Column { id: talkCol; spacing: 10
                    Repeater { model: shell.talk.slice(-8)
                        Column { id: said; required property var modelData; width: talkCol.width; spacing: 6
                            Rectangle { width: Math.min(talkCol.width * 0.85, words.implicitWidth + 24); height: words.implicitHeight + 16; radius: 14
                                        x: said.modelData.mine ? talkCol.width - width : 0
                                        color: said.modelData.mine ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
                                TextEdit { id: words; x: 12; y: 8; width: Math.min(talkCol.width * 0.85 - 24, implicitWidth); readOnly: true; selectByMouse: true; wrapMode: Text.Wrap
                                           text: said.modelData.text; color: shell.ink; font.family: Theme.font; font.pixelSize: 14 } }
                            Flow { spacing: 6; visible: !said.modelData.mine
                                Repeater { model: said.modelData.mine ? [] : shell.suggested(said.modelData.text)
                                    Chip { required property var modelData; property bool sure: false
                                           glyph: modelData.kind === "cmd" ? "terminal-2" : "world"
                                           label: modelData.kind === "url" ? I18n.tr("Open the link") : (sure ? I18n.tr("Really run it?") : I18n.tr("Run in a terminal"))
                                           on: sure
                                           onPressed: { if (modelData.kind === "url") shell.go(["xdg-open", modelData.value])
                                                        else if (!sure) sure = true
                                                        else shell.go(["foot", "-e", "sh", "-c", modelData.value + "; exec bash"]) } } } }
                            CopyButton { visible: !said.modelData.mine; copy: said.modelData.text; color: shell.ink } } }
                    Label { visible: shell.live !== "" || ask.running; width: talkCol.width; wrapMode: Text.Wrap; leftPadding: 12
                            text: shell.live !== "" ? shell.live : I18n.tr("Thinking…"); color: shell.live !== "" ? shell.ink : shell.soft }
                    Flow { spacing: 6
                        Chip { glyph: "plus"; label: I18n.tr("New conversation"); onPressed: { shell.chat = "new"; shell.talk = []; shell.live = ""; field.forceActiveFocus() } }
                        Chip { glyph: "history"; label: I18n.tr("Conversations"); onPressed: shell.showChats() }
                        Chip { visible: shell.chat !== "new"; glyph: "external-link"; label: I18n.tr("Open in LensAI"); onPressed: shell.go(["latte-app", "aicenter", shell.chat]) } } } }

            // the conversations kept: one pressed goes on where it ended
            Component { id: chatsPart
                Column { spacing: 2
                    Section { text: I18n.tr("Conversations") }
                    Label { visible: shell.chats.length === 0; leftPadding: 6; color: shell.soft; text: I18n.tr("No conversation yet") }
                    Repeater { model: shell.chats
                        Row_ { required property var modelData; glyph: "messages"; label: modelData.title || "…"; hint: (modelData.updated || "").replace("T", " ").slice(0, 16)
                               onRun: shell.openChat(modelData.id) } }
                    Row_ { glyph: "plus"; label: I18n.tr("New conversation"); onRun: { shell.chat = "new"; shell.talk = []; shell.view = "find"; field.forceActiveFocus() } } } }
        }

        // the right button's menu, and the choice of who answers
        Menu { id: menu
               function popupAt(x, y) {
                   open(x, y, [{ icon: "cut", text: I18n.tr("Cut"), hint: "Ctrl+X", enabled: field.selectedText !== "", run: () => field.cut() },
                               { icon: "copy", text: I18n.tr("Copy"), hint: "Ctrl+C", enabled: field.selectedText !== "", run: () => field.copy() },
                               { icon: "clipboard", text: I18n.tr("Paste"), hint: "Ctrl+V", enabled: field.canPaste, run: () => field.paste() },
                               { line: true },
                               { icon: shell.locked ? "lock-open" : "lock", text: shell.locked ? I18n.tr("Unlock position") : I18n.tr("Lock position"), run: () => shell.locked = !shell.locked }])
               }
               function chooseAt(x, y) {
                   open(x, y, shell.providers.map(p => ({ icon: p.local ? "home" : "cloud", text: p.name, checked: shell.provider && p.id === shell.provider.id,
                                                          hint: p.local ? I18n.tr("this computer") : "", run: () => { shell.choose(p); settings.put({ lens_ai: p.id }) } })))
               } }
    }

    component Section: Label { color: shell.soft; font.pixelSize: 12; font.weight: 700; leftPadding: 6; font.capitalization: Font.AllUppercase; bottomPadding: 2 }
    component Row_: Rectangle {
        id: row
        property string glyph
        property string label
        property string hint
        signal run()
        width: parent ? parent.width : 0; height: 36; radius: 10
        color: rowHit.containsMouse ? shell.lit : "transparent"
        Glyph { x: 12; name: row.glyph; font.pixelSize: 17; color: shell.soft; anchors.verticalCenter: parent.verticalCenter }
        Label { x: 42; width: parent.width - 54 - hintText.width; text: row.label; color: shell.ink; anchors.verticalCenter: parent.verticalCenter }
        Label { id: hintText; anchors.right: parent.right; anchors.rightMargin: 12; text: row.hint; color: shell.soft; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth, row.width * 0.45) }
        MouseArea { id: rowHit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: row.run() }
    }
    component Chip: Rectangle {
        id: chip
        property string glyph
        property string label
        property bool on: false
        signal pressed()
        height: 30; width: chipRow.implicitWidth + 22; radius: 15
        color: on ? Qt.rgba(Theme.gold.r, Theme.gold.g, Theme.gold.b, 0.85) : (chipHit.containsMouse ? shell.lit : Qt.rgba(0, 0, 0, 0.18))
        Row { id: chipRow; anchors.centerIn: parent; spacing: 6
            Glyph { name: chip.glyph; font.pixelSize: 14; color: chip.on ? "#2a170c" : shell.ink; anchors.verticalCenter: parent.verticalCenter }
            Label { text: chip.label; font.pixelSize: 13; color: chip.on ? "#2a170c" : shell.ink; anchors.verticalCenter: parent.verticalCenter } }
        MouseArea { id: chipHit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: chip.pressed() }
    }
}
