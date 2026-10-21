// LensAI: every conversation with every AI in one list, and the services themselves — which are there,
// which one is signed in, signing in and out. bin/latte-ai keeps the conversations (the same ones LensGoo's AI
// tab writes) and knows the services; this window shows them.   latte-app aicenter [services | CHAT]
//
// latte-app aicenter compare QUESTION PROVIDER/MODEL… asks several at once.
// The side: all conversations or one service's, newest first, each marked with its service's colour; at the
// bottom the services. A conversation opens on the right and goes on there, with the service and model it had.
import QtQuick
import Quickshell
import Quickshell.Io
import "common"

ShellRoot {
    id: shell
    readonly property var words: (Quickshell.env("LATTE_APP_ARGS") || "").split("\n").filter(w => w !== "")
    property string page: "chats"              // chats · agents · compare · models · instructions · services
    // LatteOS's skill: the user's copy, made when it is first needed (latte-ai skill)
    FileView { id: skillFile; path: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/latteos/skills/latteos/SKILL.md"; printErrors: false
               onLoaded: skillText.text = text(); onLoadFailed: skillMake.running = true }
    Process { id: skillMake; command: ["latte-ai", "skill", "install"]; onExited: skillFile.reload() }
    Process { id: skillReset; command: ["latte-ai", "skill", "reset"]; onExited: skillFile.reload() }
    FileView { id: rules; path: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/latteos/ai-instructions.txt"; printErrors: false
               onLoaded: ruleText.text = text() }
    property var picks: []                     // what is compared: up to three { provider, model }
    property string asked: ""                  // the question they were all asked
    property int round: 0                      // counts up for each question compared: the columns start again
    property string only: ""                   // the side shows only this service's conversations; "" all
    property string open: ""                   // the conversation shown
    property string find: ""
    property var chats: []
    property var chat: null
    property var providers: []                 // what can answer now (latte-ai providers)
    property var services: []                  // every service known (latte-ai services)
    property bool waiting: false
    // each service has its colour, so that a conversation is known by it at a glance
    readonly property var colours: ({ "api-deepseek": "#4d6bfe", "api-anthropic": "#d97757", "api-openai": "#10a37f", "api-google": "#4285f4", "api-xai": "#a8a8a8", "api-mistral": "#fa520f", "claude": "#d97757", "gemini": "#4285f4", "chatgpt": "#10a37f", "grok": "#a8a8a8", "mistral": "#fa520f", "local": Theme.gold, "ollama": Theme.gold })
    function colour(id) { return colours[id] || Theme.gold }
    function nameOf(id) { const p = services.find(s => s.id === id) || providers.find(s => s.id === id) || keys.find(k => k.id === id); return p ? I18n.tr(p.name) : id }
    function modelName(pid, mid) { const p = providers.find(x => x.id === pid); const m = p ? p.models.find(x => x.id === mid) : null; return m ? m.name : mid }
    readonly property var shown: chats.filter(c => (only === "" || c.provider === only) && (find === "" || c.title.toLowerCase().includes(find.toLowerCase())))
    function when(iso) {
        const d = new Date(iso), now = new Date()
        return d.toDateString() === now.toDateString() ? Qt.formatTime(d, "HH:mm") : Qt.formatDate(d, "d. M.")
    }

    component Ask: Process {
        id: q
        property var data: null
        property string buf: ""
        signal done()
        function ask(args) { running = false; command = ["latte-ai"].concat(args); running = true }
        stdout: StdioCollector { onStreamFinished: q.buf = this.text }
        onExited: { try { q.data = JSON.parse(q.buf) } catch (e) { q.data = null } q.done() }
    }
    Ask { id: list; onDone: shell.chats = data || [] }
    // the agents panel (Omarchy's, MIT): what each service tells of the account, and what was used
    Ask { id: agentsq; onDone: shell.agents = data || ({ services: [], stats: {} }) }
    property var agents: ({ services: [], stats: {}, doers: [], ideas: [] })
    // "Do it for me": the task goes to an agent in a terminal, which plans first and changes nothing before a yes
    Process { id: doer }
    function doIt(task, who) { doer.command = ["latte-ai", "do", task].concat(who ? [who] : []); doer.running = true }
    Process { id: chooser; onExited: agentsq.ask(["agents"]) }
    Timer { interval: 180000; repeat: true; running: shell.page === "agents"; onTriggered: agentsq.ask(["agents"]) }
    function tokens(n) { return n >= 1e6 ? (n / 1e6).toFixed(1) + " M" : n >= 1e3 ? Math.round(n / 1e3) + " k" : String(n || 0) }
    function modelWord(id) { const m = /claude-(\w+)-(\d+)-(\d+)/.exec(id || ""); return m ? m[1].charAt(0).toUpperCase() + m[1].slice(1) + " " + m[2] + "." + m[3] : (id || "") }
    function left(t) {
        const s = t - Date.now() / 1000
        return s <= 0 ? "" : s < 3600 ? Math.ceil(s / 60) + " min" : s < 86400 ? Math.floor(s / 3600) + " h" : Math.floor(s / 86400) + " d"
    }
    Ask { id: one; onDone: shell.chat = data }
    Ask { id: who; onDone: shell.providers = data || [] }
    Ask { id: svc; onDone: shell.services = data || [] }
    Ask { id: keyq; onDone: shell.keys = data || [] }
    Ask { id: keyer; onDone: { keyq.ask(["keys"]); who.ask(["providers", "all"]) } }
    property var keys: []                      // the services one can bring a key to, and the user's own servers
    Ask { id: modelq; onDone: shell.models = data || [] }
    Ask { id: modeler; onDone: { modelq.ask(["models"]); who.ask(["providers", "all"]) } }
    property var models: []                    // every model of every service, with the user's word on each
    // a key goes to latte-ai on its standard input, never on its command line, where anyone could read it
    Process { id: keeper; property string id: ""; property string key: ""; stdinEnabled: true
              onStarted: { write(key + "\n"); key = ""; stdinEnabled = false }
              onExited: { stdinEnabled = true; keyq.ask(["keys"]); who.ask(["providers", "all"]) } }
    function keep(id, key) { if (key.trim() === "") return; keeper.key = key.trim(); keeper.command = ["latte-ai", "key", id]; keeper.running = true }
    // the answer comes in pieces ({"delta"}) and then whole; stopping it ends latte-ai, which keeps what came
    property string live: ""                   // the answer as far as it has come
    property bool editing: false               // the next send changes the last question instead of asking a new one
    Process { id: sender
        stdout: SplitParser { onRead: line => { let m = null; try { m = JSON.parse(line) } catch (e) { return }
            if (m.delta !== undefined) shell.live += m.delta
            else if (m.chat) shell.open = m.chat } }
        onExited: { shell.waiting = false; shell.live = ""; shell.reload() } }
    function ask(args) { live = ""; waiting = true; sender.command = ["latte-ai"].concat(args).concat(["--stream", "--markdown"]); sender.running = true }
    function stop() { if (sender.running) sender.running = false }
    // the last answer again, from whoever is chosen now
    function again() {
        if (waiting || !chat) return
        const m = chat.messages.slice()
        while (m.length && m[m.length - 1].role === "assistant") m.pop()
        chat = Object.assign({}, chat, { messages: m })
        ask(["again", open, useProvider, useModel].concat(effort ? ["--effort", effort] : []))
    }
    Ask { id: forget; onDone: { shell.open = ""; shell.chat = null; list.ask(["chats"]) } }
    function reload() { list.ask(["chats"]); if (open !== "") one.ask(["chat", open]) }
    function choose(id) { open = id; page = "chats"; chat = null; one.ask(["chat", id]) }
    // a command to sign in or out runs in a terminal: the tool asks there what it needs
    function inTerminal(argv) { Quickshell.execDetached(["foot", "-e", "sh", "-c", argv.map(a => "'" + a.replace(/'/g, "'\\''") + "'").join(" ") + "; echo; read -p '" + I18n.tr("Press Enter to close") + "' x"]) }
    Timer { id: later; interval: 2500; onTriggered: svc.ask(["services"]) }
    Component.onCompleted: {
        list.ask(["chats"]); who.ask(["providers", "all"]); svc.ask(["services"]); keyq.ask(["keys"])
        if (["services", "models", "agents", "instructions"].indexOf(words[0]) >= 0) page = words[0]
        if (page === "agents") agentsq.ask(["agents"])
        // latte-app aicenter compare QUESTION PROVIDER/MODEL…: the same question to each, side by side
        if (words[0] === "compare" && words.length > 2) {
            page = "compare"
            picks = words.slice(2, 5).map(w => ({ provider: w.split("/")[0], model: w.slice(w.indexOf("/") + 1) }))
            asked = words[1]
            Qt.callLater(() => round += 1)
        }
        if (page === "models") modelq.ask(["models"])
        else if (words[0] && page === "chats") choose(words[0])        // a conversation by its id
    }

    // what the conversation goes on with: its own service and model, or the first there is for a new one
    property string useProvider: chat ? chat.provider : (providers.length ? providers[0].id : "")
    property string useModel: chat ? chat.model : (providers.length ? providers[0].models[0].id : "")
    property string useEffort: ""              // how hard it may think, where its tool lets that be said
    property var files: []                     // attached to the next question
    readonly property var useP: providers.find(p => p.id === useProvider) || null
    readonly property var useM: useP ? (useP.models.find(m => m.id === useModel) || useP.models[0]) : null
    readonly property string effort: useP && (useP.efforts || []).indexOf(useEffort) >= 0 ? useEffort : ""
    // the field and the page in the look of the service that answers, as in LensGoo (goo/parts/ai.plm): a copy of
    // each service's own, so one knows at a glance whose it is (the user's pictures, 21. 10.)
    readonly property string style: useP ? useP.style : "own"
    readonly property var look: ({
        "claude": { page: "#faf9f5", bg: "#ffffff", rim: "#d9d6cf", ink: "#3d3929", text: "#1f1e1d", dim: "#8b8778", ubg: "#f0eee6", round: 18, send: "#c96442", sendEmpty: "transparent", sendInk: "#ffffff", sendInkEmpty: "#3d3929", tick: "#2c84db" },
        "gemini": { page: "#f8fafd", bg: "#ffffff", rim: "#e8eaed", ink: "#1f1f1f", text: "#1f1f1f", dim: "#5f6368", ubg: "#e9eef6", round: 32, send: "transparent", sendEmpty: "transparent", sendInk: "#1f1f1f", sendInkEmpty: "transparent", tick: "#1f1f1f" },
        "grok": { page: "#fafaf9", bg: "#ffffff", rim: "#e5e5e5", ink: "#0d0d0d", text: "#0d0d0d", dim: "#8a8a8a", ubg: "#f1f1f1", round: 24, send: "#1d9bf0", sendEmpty: "#1d9bf0", sendInk: "#ffffff", sendInkEmpty: "#ffffff", tick: "#0d0d0d", chipBg: "#ececec" },
        "chatgpt": { page: "#ffffff", bg: "#ffffff", rim: "#e6e6e6", ink: "#0d0d0d", text: "#0d0d0d", dim: "#8f8f8f", ubg: "#f4f4f4", round: 30, send: "#0d0d0d", sendEmpty: "#3b82f6", sendInk: "#ffffff", sendInkEmpty: "#ffffff", tick: "#0d0d0d" },
        "copilot": { page: "#ffffff", bg: "#ffffff", rim: "#0969da", ink: "#1f2328", text: "#1f2328", dim: "#8c959f", ubg: "#f6f8fa", round: 12, send: "transparent", sendEmpty: "transparent", sendInk: "#59636e", sendInkEmpty: "#59636e", tick: "#1f2328" },
        "mistral": { page: "#fafaf7", bg: "#ffffff", rim: "#ececec", ink: "#1a1a1a", text: "#1a1a1a", dim: "#9a9a9a", ubg: "#f2f2f2", round: 14, send: "#1a1a1a", sendEmpty: "#1a1a1a", sendInk: "#ffffff", sendInkEmpty: "#ffffff", tick: "#fa500f" },
        "deepseek": { page: "#ffffff", bg: "#ffffff", rim: "#e5e7eb", ink: "#262626", text: "#262626", dim: "#a3a3a3", ubg: "#eff6ff", round: 24, send: "#4d6bfe", sendEmpty: "#b5c8fb", sendInk: "#ffffff", sendInkEmpty: "#ffffff", tick: "#4d6bfe" },
        "own": { page: "transparent", bg: "#3d2c22", rim: "#5a463a", ink: "#f5e8d8", text: "#f5e8d8", dim: "#b8a491", ubg: Qt.rgba(0.97, 0.78, 0.45, 0.14), round: 14, send: Theme.gold, sendEmpty: Theme.gold, sendInk: "#2a1e17", sendInkEmpty: "#2a1e17", tick: Theme.gold, chipBg: "#4a372b" } })[style] || ({})
    readonly property var look_own: ({ menu: "#2a1e17", ink: "#f5e8d8", dim: "#b8a491" })
    // the service's page as glass, the wallpaper blurred behind it and lifted towards white so its dark words read,
    // as much as LatteOS is glass (Theme.glassLevel: 0 white as on the service's own page … 3); solid where nothing blurs
    readonly property bool glassy: page === "chats" && style !== "own" && Theme.glassLevel > 0 && Theme.blurred
    readonly property color webInk: style === "own" ? "#c3b1ff" : "#6b4fd8"   // what opens the service's page, the same for all
    readonly property var effortWords: ({ low: QT_TR_NOOP("low"), medium: QT_TR_NOOP("medium"), high: QT_TR_NOOP("high"), xhigh: QT_TR_NOOP("very high"), max: QT_TR_NOOP("highest"), think: QT_TR_NOOP("thinking") })
    function effortWord(e) { return e ? I18n.tr(effortWords[e] || e) : "" }
    readonly property bool deep: style === "deepseek" && !!useM && useM.id.indexOf("reasoner") >= 0
    // the field's own chip, as each service has it: how hard it may think where it has that, else its model
    readonly property string chipWord: !useM ? "" : style === "claude" ? useM.name + (effort ? "  " + effortWord(effort) : "")
        : style === "chatgpt" ? (effort ? effortWord(effort) : I18n.tr("Thinking")) : style === "deepseek" ? I18n.tr("Deep thinking")
        : style === "grok" ? "Auto" : style === "gemini" ? "Gemini " + useM.name : (effort ? effortWord(effort) : useM.name)
    readonly property string me: { const u = Quickshell.env("USER") || ""; return u ? u.charAt(0).toUpperCase() + u.slice(1) : "" }
    readonly property string greeting: {
        const h = new Date().getHours()
        return ({ claude: I18n.tr("Welcome, {n}", { n: me }), gemini: I18n.tr("Where shall we start?"), chatgpt: I18n.tr("We can start whenever you like."),
                  mistral: I18n.tr(h < 12 ? "Morning, what are we building?" : h < 18 ? "Afternoon, what are we building?" : "Evening, what are we building?"),
                  deepseek: I18n.tr("Hi, what can I do for you?"), copilot: I18n.tr("Copilot uses AI. Check for mistakes.") })[style] || ""
    }
    readonly property var hints: ({ claude: QT_TR_NOOP("How can I help you today?"), gemini: QT_TR_NOOP("Ask Gemini"), grok: QT_TR_NOOP("What do you want to know?"),
                                    chatgpt: QT_TR_NOOP("Ask ChatGPT"), copilot: QT_TR_NOOP("Ask Copilot"), mistral: QT_TR_NOOP("What do you want to build?"),
                                    deepseek: QT_TR_NOOP("Message DeepSeek"), own: QT_TR_NOOP("Ask anything…") })
    // a row of a menu, as latte-ai gives it: what is chosen is ticked, "@effort" says the effort
    function isOn(r) { const d = r["do"] || {}; return !!r.on || (d.model !== undefined && !!useM && d.model === useM.id && !d.provider) || (d.provider !== undefined && d.provider === useProvider) || (d.effort !== undefined && d.effort === effort) || (!!d.think && effort !== "") }
    function keyOf(r) { return r.key === "@effort" ? effortWord(effort) : (r.key ? I18n.tr(r.key) : "") }
    // a row pressed: what LatteOS can do it does; one with more opens a menu beside it; one of the service's page opens that
    property string menuAt: ""                 // "" none · "who" the services · "chip" · "plus"
    property var subRows: []
    property real subY: 0
    function act(r, y, sub) {
        const d = r["do"]
        if (r.note || (d && d.reset && line.text === "")) return
        if (d && d.sub && !sub) { subRows = d.sub; subY = y; return }
        menuAt = ""; subRows = []
        if (!d || d.sub) { if (useP && useP.web) Qt.openUrlExternally(useP.web); return }
        if (d.provider !== undefined) { useProvider = d.provider; useModel = d.model }
        else if (d.model !== undefined) useModel = d.model
        else if (d.effort !== undefined) useEffort = d.effort
        else if (d.think) useEffort = effort ? "" : "high"
        else if (d.reset) line.text = ""
        else if (d.attach !== undefined) { picker.command = ["latte-ai", d.attach === 1 ? "shot" : "pick"]; picker.running = true }
    }
    function openMenu(at) { subRows = []; menuAt = menuAt === at ? "" : at }
    Process { id: picker
        stdout: SplitParser { onRead: path => { if (path !== "" && shell.files.length < 8 && shell.files.indexOf(path) < 0) shell.files = shell.files.concat([path]) } } }
    // the microphone: what is said goes into the field, to be read and changed before it is sent
    property int listening: 0                  // 0 quiet · 1 listening · 2 writing down what was said
    Process { id: ear; property string said: ""
        stdout: StdioCollector { onStreamFinished: { try { ear.said = JSON.parse(this.text).text || "" } catch (e) { ear.said = "" } } }
        onExited: { if (shell.listening === 2) { if (ear.said !== "") line.text = (line.text !== "" ? line.text + " " : "") + ear.said; shell.listening = 0 } } }
    function listen() {
        if (listening === 2) return
        listening = listening === 0 ? 1 : 2
        ear.said = ""; ear.command = ["latte-ai", "listen", listening === 1 ? "start" : "stop"]; ear.running = true
    }
    function extra() { return (effort ? ["--effort", effort] : []).concat(files.reduce((a, f) => a.concat(["--attach", f]), [])) }
    function send(text) {
        if (text.trim() === "" || waiting || useProvider === "") return
        if (editing && chat) {
            const m = chat.messages.slice()
            while (m.length && m[m.length - 1].role === "assistant") m.pop()
            m.pop()
            chat = Object.assign({}, chat, { messages: m.concat([{ role: "user", content: text, provider: useProvider, model: useModel }]) })
            editing = false
            ask(["again", open, useProvider, useModel, "--text", text].concat(extra()))
            files = []
            return
        }
        if (chat) chat = Object.assign({}, chat, { messages: chat.messages.concat([{ role: "user", content: text, provider: useProvider, model: useModel }]) })
        ask(["send", open !== "" ? open : "new", useProvider, useModel, text].concat(extra()))
        files = []
    }

    AppWindow {
        title: I18n.tr("LensAI")
        heading: shell.page === "agents" ? I18n.tr("Agents") : shell.page === "instructions" ? I18n.tr("Instructions") : shell.page === "services" ? I18n.tr("Services") : shell.page === "models" ? I18n.tr("Models") : shell.page === "compare" ? I18n.tr("Compare") : (shell.chat ? shell.chat.title : I18n.tr("Conversations"))
        implicitWidth: 1120; implicitHeight: 760
        ground: shell.glassy ? "transparent" : Theme.ground
        searchHint: I18n.tr("Find a conversation…")
        onSearched: text => shell.find = text
        tools: [
            Pill { implicitHeight: 34; icon: "plus"; text: I18n.tr("New conversation"); strong: true
                   onPressed: { shell.page = "chats"; shell.open = ""; shell.chat = null } },
            Pill { implicitHeight: 34; icon: "trash"; danger: true; visible: shell.page === "chats" && shell.open !== ""; text: I18n.tr("Delete")
                   onPressed: forget.ask(["forget", shell.open]) }
        ]
        side: [
            Column { x: 14; y: 14; spacing: 4; width: 222
                Row { x: 6; spacing: 10; height: 40
                    Glyph { name: "sparkles"; font.pixelSize: 24; color: Theme.gold; anchors.verticalCenter: parent.verticalCenter }
                    Label { text: I18n.tr("LensAI"); font.pixelSize: 17; font.weight: 700; anchors.verticalCenter: parent.verticalCenter } }
                Item { width: 1; height: 6 }
                Nav { text: I18n.tr("All conversations"); icon: "messages"; on: shell.page === "chats" && shell.only === ""; badge: shell.chats.length
                      onPressed: { shell.page = "chats"; shell.only = "" } }
                Repeater { model: shell.services.filter(s => shell.chats.some(c => c.provider === s.id))
                    Nav { required property var modelData; text: I18n.tr(modelData.name); icon: "point-filled"; height: 34
                          on: shell.page === "chats" && shell.only === modelData.id; badge: shell.chats.filter(c => c.provider === modelData.id).length
                          onPressed: { shell.page = "chats"; shell.only = modelData.id }
                          Rectangle { x: 18; width: 10; height: 10; radius: 5; color: shell.colour(parent.modelData.id); anchors.verticalCenter: parent.verticalCenter } } }
                Item { width: 1; height: 10 }
                Label { x: 14; text: I18n.tr("CONVERSATIONS"); color: Theme.faint; font.pixelSize: 11; font.weight: 700; font.letterSpacing: 0.8 }
                Item { width: 1; height: 2 }
                ListView { id: rows; width: 222; height: Math.min(contentHeight, 380); clip: true; spacing: 4; model: shell.shown
                    boundsBehavior: Flickable.StopAtBounds
                    delegate: Rectangle { id: line; required property var modelData; width: 222; height: 52; radius: 12
                        color: shell.open === modelData.id && shell.page === "chats" ? Theme.raised : (hit.containsMouse ? Theme.card : "transparent")
                        Rectangle { x: 6; y: 10; width: 4; height: 32; radius: 2; color: shell.colour(line.modelData.provider) }
                        Column { x: 18; width: parent.width - 26; anchors.verticalCenter: parent.verticalCenter; spacing: 2
                            Label { text: line.modelData.title; width: parent.width; elide: Text.ElideRight; font.weight: 600; font.pixelSize: 13 }
                            Label { text: shell.nameOf(line.modelData.provider) + " · " + shell.modelName(line.modelData.provider, line.modelData.model) + " · " + shell.when(line.modelData.updated)
                                    width: parent.width; elide: Text.ElideRight; color: Theme.dim; font.pixelSize: 11 } }
                        MouseArea { id: hit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: shell.choose(line.modelData.id) } } }
                Label { visible: shell.chats.length === 0; x: 14; width: 200; wrapMode: Text.WordWrap; color: Theme.dim; font.pixelSize: 12
                        text: I18n.tr("No conversation yet. LensGoo's AI tab (Win+C) keeps its conversations here too.") }
                Item { width: 1; height: 10 }
                Nav { text: I18n.tr("Agents"); icon: "robot"; on: shell.page === "agents"; onPressed: { shell.page = "agents"; agentsq.ask(["agents"]) } }
                Nav { text: I18n.tr("Compare"); icon: "layout-columns"; on: shell.page === "compare"; onPressed: shell.page = "compare" }
                Nav { text: I18n.tr("Instructions"); icon: "file-text"; on: shell.page === "instructions"; onPressed: shell.page = "instructions" }
                Nav { text: I18n.tr("Models"); icon: "sparkles"; on: shell.page === "models"; onPressed: { shell.page = "models"; modelq.ask(["models"]) } }
                Nav { text: I18n.tr("Services"); icon: "plug-connected"; on: shell.page === "services"; onPressed: { shell.page = "services"; svc.ask(["services"]) } }
            }
        ]

        // ── a conversation: its messages, and the line to go on with it ─────────────────────────────────────
        Item {
            id: chatPane
            anchors.fill: parent
            visible: shell.page === "chats"
            Rectangle { anchors.fill: parent; anchors.margins: 8; radius: 16; color: shell.look.page; opacity: shell.glassy ? [1, 0.9, 0.8, 0.68][Theme.glassLevel] : 1 }
            ListView {
                id: talk
                anchors.fill: parent; anchors.bottomMargin: 130
                clip: true; spacing: 14; topMargin: 24; bottomMargin: 16
                model: shell.chat ? shell.chat.messages : []
                onCountChanged: Qt.callLater(positionViewAtEnd)
                delegate: Item { id: msg; required property var modelData; required property int index; width: talk.width; height: bubble.height + 22 + (acts.visible ? 30 : 0)
                    readonly property bool mine: modelData.role === "user"
                    readonly property bool last: index === talk.count - 1 || (mine && index === talk.count - 2)
                    Label { x: msg.mine ? talk.width - 28 - width : 28; text: msg.mine ? I18n.tr("You") : shell.nameOf(msg.modelData.provider) + " · " + shell.modelName(msg.modelData.provider, msg.modelData.model)
                            color: shell.style === "own" ? (msg.mine ? Theme.gold : shell.colour(msg.modelData.provider)) : shell.look.dim; font.pixelSize: 11; font.weight: 700 }
                    Rectangle { id: bubble; y: 20; x: msg.mine ? talk.width - 28 - width : 28; width: Math.min(talk.width * 0.78, said.implicitWidth + 28); height: said.implicitHeight + 22; radius: 16
                        color: msg.mine ? shell.look.ubg : (shell.style === "own" ? Theme.card : "transparent")
                        border.width: msg.mine || shell.style !== "own" ? 0 : 1; border.color: Qt.rgba(Qt.color(shell.colour(msg.modelData.provider)).r, Qt.color(shell.colour(msg.modelData.provider)).g, Qt.color(shell.colour(msg.modelData.provider)).b, 0.45)
                        TextEdit { id: said; x: 14; y: 11; width: Math.min(talk.width * 0.78 - 28, implicitWidth); readOnly: true; selectByMouse: true; wrapMode: Text.Wrap
                                   textFormat: msg.mine ? TextEdit.PlainText : TextEdit.MarkdownText
                                   text: msg.modelData.content + (msg.modelData.stopped ? "\n\n*" + I18n.tr("(stopped)") + "*" : ""); color: msg.modelData.ok === false ? Theme.red : shell.look.text
                                   font.family: Theme.font; font.pixelSize: 15; selectionColor: shell.style === "own" ? Theme.coffee : "#c9d7f0"
                                   Component.onCompleted: width = Math.min(talk.width * 0.78 - 28, implicitWidth) } }
                    // what can be done with it: copy an answer, ask the last one again, change the last question
                    Row { id: acts; spacing: 14; y: bubble.y + bubble.height + 8; x: msg.mine ? talk.width - 28 - width : 40
                          visible: !shell.waiting && (!msg.mine || msg.last)
                        component Act: Text { property string what; signal go(); text: what; color: hit.containsMouse ? Theme.gold : Theme.dim; font.family: Theme.font; font.pixelSize: 12; font.weight: 600
                                              MouseArea { id: hit; anchors.fill: parent; anchors.margins: -4; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: parent.go() } }
                        Act { visible: !msg.mine; what: I18n.tr("Copy"); onGo: Quickshell.clipboardText = msg.modelData.content }
                        Act { visible: !msg.mine && msg.index === talk.count - 1; what: I18n.tr("Again"); onGo: shell.again() }
                        Act { visible: msg.mine && msg.last; what: I18n.tr("Change"); onGo: { line.text = msg.modelData.content; shell.editing = true } } } }
                // the answer while it comes
                footer: Item { width: talk.width; height: shell.waiting ? liveBox.height + 30 : 0
                    Rectangle { id: liveBox; visible: shell.waiting; x: 28; y: 6; width: Math.min(talk.width * 0.78, liveText.implicitWidth + 28); height: liveText.implicitHeight + 22; radius: 16; color: shell.style === "own" ? Theme.card : "transparent"
                        TextEdit { id: liveText; x: 14; y: 11; width: Math.min(talk.width * 0.78 - 28, Math.max(implicitWidth, 80)); readOnly: true; wrapMode: Text.Wrap; textFormat: TextEdit.MarkdownText
                                   text: shell.live !== "" ? shell.live : "*" + I18n.tr("Thinking…") + "*"; color: shell.look.text; font.family: Theme.font; font.pixelSize: 15
                                   onTextChanged: Qt.callLater(talk.positionViewAtEnd) } } }
            }
            // an empty conversation: the service greets as on its own page; LatteOS's own says who answers
            Item { id: hello; visible: !shell.chat && shell.open === ""; anchors.left: parent.left; anchors.right: parent.right; y: Math.max(40, box.y - 210); height: 120
                readonly property string logo: ({ claude: "claude", grok: "grok", mistral: "mistral", deepseek: "deepseek", copilot: "githubcopilot" })[shell.style] || ""
                Row { anchors.horizontalCenter: shell.style === "mistral" ? undefined : parent.horizontalCenter; x: shell.style === "mistral" ? box.x : 0; spacing: 12
                      visible: shell.style !== "own" && shell.style !== "mistral" && shell.style !== "copilot"
                    Image { visible: hello.logo !== ""; source: hello.logo ? "file://" + I18n.share + "/goo/ai/" + hello.logo + ".svg" : ""; sourceSize: Qt.size(shell.style === "grok" ? 64 : 40, shell.style === "grok" ? 64 : 40); anchors.verticalCenter: parent.verticalCenter }
                    Text { visible: text !== ""; text: shell.greeting; color: shell.look.text; anchors.verticalCenter: parent.verticalCenter
                           font.family: shell.style === "claude" ? "Lora" : shell.style === "gemini" ? "Google Sans Flex" : Theme.font
                           font.pixelSize: shell.style === "claude" ? 36 : shell.style === "gemini" ? 32 : 26; font.weight: shell.style === "deepseek" ? 700 : (shell.style === "chatgpt" ? 500 : 400) } }
                // Mistral: its mark above a bold line, at the left; Copilot: its mark above a quiet line
                Column { visible: shell.style === "mistral"; x: box.x; spacing: 18
                    Image { source: "file://" + I18n.share + "/goo/ai/mistral.svg"; sourceSize: Qt.size(44, 44) }
                    Text { text: shell.greeting; color: shell.look.text; font.family: Theme.font; font.pixelSize: 30; font.weight: 600 } }
                Column { visible: shell.style === "copilot"; anchors.horizontalCenter: parent.horizontalCenter; spacing: 14
                    Image { anchors.horizontalCenter: parent.horizontalCenter; source: "file://" + I18n.share + "/goo/ai/githubcopilot.svg"; sourceSize: Qt.size(48, 48) }
                    Text { text: shell.greeting; color: shell.look.dim; font.family: Theme.font; font.pixelSize: 13 } }
                Column { visible: shell.style === "own"; anchors.horizontalCenter: parent.horizontalCenter; spacing: 10; width: 460
                    Glyph { name: "messages"; font.pixelSize: 48; color: Theme.gold; anchors.horizontalCenter: parent.horizontalCenter }
                    Label { text: I18n.tr("A new conversation"); font.pixelSize: 24; font.weight: 800; anchors.horizontalCenter: parent.horizontalCenter }
                    Label { width: parent.width; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap; color: Theme.dim
                            text: shell.providers.length ? I18n.tr("Write below. Choose who answers with the button above the line.") : I18n.tr("No AI is ready on this computer: see Services.") } } }

            // who answers: LatteOS's own switch, the one part that is the same for every service (LensGoo has it at its foot)
            Rectangle { id: whoPill; x: box.x; y: box.y - 42; height: 32; radius: 16; width: whoRow.implicitWidth + 28; visible: shell.providers.length > 0
                color: Qt.rgba(0.97, 0.78, 0.45, whoHit.containsMouse || shell.menuAt === "who" ? 0.3 : 0.18)
                Row { id: whoRow; x: 14; spacing: 8; anchors.verticalCenter: parent.verticalCenter
                    Text { text: shell.nameOf(shell.useProvider) + " · " + (shell.useM ? shell.useM.name : ""); color: shell.style === "own" ? Theme.gold : "#8a5a14"; font.family: Theme.font; font.pixelSize: 13; font.weight: Font.Bold }
                    Glyph { name: "chevron-down"; font.pixelSize: 14; color: shell.style === "own" ? Theme.gold : "#8a5a14"; anchors.verticalCenter: parent.verticalCenter } }
                MouseArea { id: whoHit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: shell.openMenu("who") } }

            // ── the field, a copy of the service's own: its colours, its shape, and what sits in it where it sits ──
            // + at the left (not Copilot, not DeepSeek: its paperclip is at the right); its chip at the right, or at the
            // left for Copilot and DeepSeek; the microphone (Mistral's is its black button); and the button that sends
            Rectangle {
                id: box
                readonly property bool oneLine: ["gemini", "chatgpt"].indexOf(shell.style) >= 0
                readonly property bool hasPlus: shell.style !== "copilot" && shell.style !== "deepseek"
                readonly property bool chipLeft: shell.style === "copilot" || shell.style === "deepseek"
                readonly property bool hasMic: ["claude", "gemini", "grok", "chatgpt", "own"].indexOf(shell.style) >= 0
                readonly property real cy: oneLine ? height / 2 : height - 26
                readonly property bool typed: line.text !== ""
                width: Math.min(parent.width - 44, 820); anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: 22
                height: oneLine ? 64 : (shell.style === "copilot" ? 112 : 100)
                radius: shell.look.round; color: shell.look.bg; border.width: shell.style === "copilot" ? 2 : 1; border.color: shell.look.rim
                // what is attached, one chip with a cross, over the field
                Rectangle { visible: shell.files.length > 0; y: -36 - (whoPill.visible ? 40 : 0); x: 0; height: 28; radius: 14; width: Math.min(filesText.implicitWidth + 50, 360); color: Qt.rgba(0.97, 0.78, 0.45, 0.3)
                    Text { id: filesText; x: 14; width: parent.width - 44; elide: Text.ElideMiddle; anchors.verticalCenter: parent.verticalCenter; text: shell.files.map(f => f.split("/").pop()).join(", "); color: shell.style === "own" ? Theme.cream : "#3d3929"; font.family: Theme.font; font.pixelSize: 13; font.weight: Font.DemiBold }
                    Glyph { x: parent.width - 24; anchors.verticalCenter: parent.verticalCenter; name: "x"; font.pixelSize: 14; color: filesText.color
                        MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; onClicked: shell.files = [] } } }
                TextInput { id: line; x: box.oneLine ? 58 : 20; y: box.oneLine ? (box.height - height) / 2 : 18; width: box.oneLine ? chip.x - x - 12 : box.width - 40
                            color: shell.look.ink; font.family: Theme.font; font.pixelSize: 16; clip: true; selectByMouse: true
                            selectionColor: shell.style === "own" ? Theme.coffee : "#c9d7f0"
                            onAccepted: { shell.send(text); text = "" } }
                Text { x: line.x; y: line.y; visible: !box.typed; text: I18n.tr(shell.hints[shell.style] || shell.hints.own); color: shell.look.dim; font.family: Theme.font; font.pixelSize: 16 }
                MouseArea { anchors.fill: parent; anchors.bottomMargin: box.oneLine ? 0 : 46; anchors.leftMargin: box.oneLine ? 52 : 0; anchors.rightMargin: box.oneLine ? box.width - chip.x : 0; cursorShape: Qt.IBeamCursor; onClicked: line.forceActiveFocus() }
                // + : something to attach (where the service has no menu for it, it attaches at once)
                Item { id: plus; visible: box.hasPlus; x: 22; y: box.cy - 16; width: 32; height: 32
                    Rectangle { anchors.fill: parent; radius: 16; color: shell.look.ink; opacity: plusHit.containsMouse || shell.menuAt === "plus" ? 0.08 : 0 }
                    Glyph { anchors.centerIn: parent; name: "plus"; font.pixelSize: 19; color: shell.look.ink }
                    MouseArea { id: plusHit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: { if (shell.useP && shell.useP.plus.length) shell.openMenu("plus"); else shell.act({ "do": { attach: 0 } }, 0) } } }
                // the service's own chip: a model or a way of thinking; DeepSeek's is a switch, lit while on
                Rectangle { id: chip; visible: !!shell.useP
                    readonly property bool lit: shell.style === "deepseek" ? shell.deep : false
                    readonly property bool hasIcon: ["chatgpt", "copilot", "mistral", "deepseek"].indexOf(shell.style) >= 0
                    readonly property bool hasChev: ["gemini", "grok", "copilot", "own"].indexOf(shell.style) >= 0
                    x: box.chipLeft ? 12 : (mic.visible ? mic.x : send.x) - width - 8; y: box.cy - 16; height: 32; radius: 16
                    width: chipRow.implicitWidth + 28
                    readonly property color inkC: Qt.color(shell.look.ink || "#000000")
                    color: shell.style === "deepseek" ? (lit ? "#edf3fe" : "#ffffff") : (shell.look.chipBg || Qt.rgba(inkC.r, inkC.g, inkC.b, chipHit.containsMouse || shell.menuAt === "chip" ? 0.06 : 0))
                    border.width: shell.style === "deepseek" ? 1 : 0; border.color: lit ? "#c9dbfb" : "#e5e7eb"
                    Row { id: chipRow; x: 14; spacing: 7; anchors.verticalCenter: parent.verticalCenter
                        Glyph { visible: chip.hasIcon; name: ({ chatgpt: "bulb", copilot: "git-fork", mistral: "cube", deepseek: "atom" })[shell.style] || "sparkles"; font.pixelSize: 15; color: chipText.color; anchors.verticalCenter: parent.verticalCenter }
                        Text { id: chipText; text: shell.chipWord; color: shell.style === "deepseek" ? (chip.lit ? "#4d6bfe" : "#262626") : (shell.style === "chatgpt" ? "#5d5d5d" : shell.look.ink); font.family: Theme.font; font.pixelSize: 14; font.weight: Font.DemiBold }
                        Glyph { visible: chip.hasChev; name: "chevron-down"; font.pixelSize: 14; color: chipText.color; anchors.verticalCenter: parent.verticalCenter } }
                    MouseArea { id: chipHit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (shell.style !== "deepseek") { shell.openMenu("chip"); return }
                            const other = shell.useP.models.find(m => (m.id.indexOf("reasoner") >= 0) !== shell.deep)
                            if (other) shell.useModel = other.id
                        } } }
                // DeepSeek's second chip, smart search: its page's, so in the colour of what opens a page
                Rectangle { visible: shell.style === "deepseek"; x: chip.x + chip.width + 10; y: chip.y; height: 32; radius: 16; width: searchRow.implicitWidth + 28
                    color: searchHit.containsMouse ? "#f4f1ff" : "#ffffff"; border.width: 1; border.color: "#e5e7eb"
                    Row { id: searchRow; x: 14; spacing: 7; anchors.verticalCenter: parent.verticalCenter
                        Glyph { name: "world"; font.pixelSize: 15; color: shell.webInk; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: I18n.tr("Smart search"); color: shell.webInk; font.family: Theme.font; font.pixelSize: 14; font.weight: Font.DemiBold } }
                    MouseArea { id: searchHit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if (shell.useP && shell.useP.web) Qt.openUrlExternally(shell.useP.web) } }
                // DeepSeek's paperclip, where the others have the microphone
                Item { visible: shell.style === "deepseek"; x: send.x - 44; y: box.cy - 16; width: 32; height: 32
                    Glyph { anchors.centerIn: parent; name: "paperclip"; font.pixelSize: 18; color: shell.look.ink }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: shell.act({ "do": { attach: 0 } }, 0) } }
                // the microphone: red while it listens, blinking while it writes
                Item { id: mic; visible: box.hasMic; x: send.x - 42; y: box.cy - 16; width: 32; height: 32
                    Rectangle { anchors.fill: parent; radius: 16; color: shell.listening === 1 ? "#e5484d" : shell.look.ink; opacity: shell.listening === 1 ? 0.85 : (micHit.containsMouse ? 0.08 : 0) }
                    Glyph { anchors.centerIn: parent; name: shell.listening === 2 ? "loader-2" : "microphone"; font.pixelSize: 18; color: shell.listening === 1 ? "#ffffff" : shell.look.ink }
                    MouseArea { id: micHit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: shell.listen() } }
                // send, as each of them draws it; while an answer comes, the same button stops it. Empty, Claude and ChatGPT
                // show the voice wave, Mistral its microphone (its button listens), Copilot a plane
                Rectangle { id: send; x: box.width - 16 - 34; y: box.cy - 17; width: 34; height: 34; radius: shell.style === "claude" || shell.style === "mistral" ? 9 : 17
                    readonly property bool full: box.typed || shell.waiting
                    color: full ? shell.look.send : shell.look.sendEmpty
                    visible: !(shell.style === "gemini" && !full)
                    Glyph { anchors.centerIn: parent; font.pixelSize: 17; color: send.full ? shell.look.sendInk : shell.look.sendInkEmpty
                            name: shell.waiting ? "player-stop" : shell.editing ? "check" : shell.style === "copilot" ? "send"
                                  : box.typed ? "arrow-up" : shell.style === "mistral" ? (shell.listening === 2 ? "loader-2" : "microphone") : (shell.style === "claude" || shell.style === "chatgpt") ? "wave-sine" : "arrow-up" }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: { if (shell.waiting) shell.stop(); else if (!box.typed && shell.style === "mistral") shell.listen(); else { shell.send(line.text); line.text = "" } } } } }

            // ── the menus: over the switch the services (LatteOS's own); over the field the service's + or chip, as the
            // service draws it (its ground, ink, ticks; what opens its page in one colour for all); a row with more opens
            // another beside it. A press beside them puts them away
            MouseArea { anchors.fill: parent; visible: shell.menuAt !== ""; onPressed: { shell.menuAt = ""; shell.subRows = [] } }
            component Sheet: Rectangle {
                id: sheet
                property var rows: []
                property bool own: false               // LatteOS's own look (the services)
                property bool sub: false
                readonly property var lk: own ? shell.look_own : shell.look
                readonly property int rowH: ({ claude: 30, gemini: 34, chatgpt: 30, mistral: 36 })[own ? "own" : shell.style] || 32
                readonly property bool tickLeft: !own && shell.style === "gemini" && shell.menuAt === "chip"
                readonly property bool radio: !own && shell.style === "mistral" && shell.menuAt === "chip"
                property real hintX: 0
                height: col.implicitHeight + 12
                radius: own ? 14 : ({ claude: 12, gemini: 20, chatgpt: 16, grok: 16 })[shell.style] || 12
                color: lk.menu || "#ffffff"; border.width: 1; border.color: Qt.rgba(Qt.color(lk.ink).r, Qt.color(lk.ink).g, Qt.color(lk.ink).b, 0.1)
                Rectangle { anchors.fill: parent; anchors.margins: -1; radius: parent.radius + 1; z: -1; color: "transparent"; border.width: 6; border.color: Qt.rgba(0, 0, 0, sheet.own ? 0 : 0.06) }
                MouseArea { anchors.fill: parent }
                Column { id: col; x: 6; y: 6; width: parent.width - 12
                    Repeater { model: sheet.rows
                        Item { id: r; required property var modelData
                            readonly property var d: modelData["do"] || null
                            readonly property bool web: !d && !modelData.note
                            readonly property bool on: shell.isOn(modelData)
                            readonly property bool off: !!modelData.note || (!!d && !!d.reset && line.text === "")
                            readonly property real gap: modelData.sep ? 9 : 0
                            readonly property real mid: gap + (modelData.desc ? 17 : sheet.rowH / 2)
                            readonly property real nx: modelData.glyph || sheet.tickLeft ? 44 : 14
                            readonly property color ink: off ? sheet.lk.dim : (web ? shell.webInk : (on && sheet.own ? Theme.gold : sheet.lk.ink))
                            width: col.width; height: gap + (modelData.note ? 40 : sheet.rowH + (modelData.desc ? 17 : 0))
                            Rectangle { visible: !!r.modelData.sep; x: 8; y: 4; width: parent.width - 16; height: 1; color: sheet.lk.ink; opacity: 0.1 }
                            Rectangle { x: 0; y: r.gap + 1; width: parent.width; height: parent.height - r.gap - 2; radius: 8; color: sheet.lk.ink; opacity: !r.off && rowHit.containsMouse ? 0.06 : 0 }
                            Glyph { visible: !!r.modelData.glyph; x: 22 - width / 2; y: r.mid - height / 2; name: r.modelData.glyph || ""; font.pixelSize: 16; color: r.web ? shell.webInk : sheet.lk.ink }
                            Glyph { visible: r.on && sheet.tickLeft; x: 22 - width / 2; y: r.mid - height / 2; name: "check"; font.pixelSize: 15; color: shell.look.tick }
                            Text { visible: !r.modelData.note; x: r.nx; y: r.mid - height / 2; width: (sheet.hintX > 0 ? sheet.hintX : r.width - 34 - (keyText.text ? keyText.implicitWidth + 8 : 0)) - r.nx - 8; elide: Text.ElideRight
                                   text: I18n.tr(r.modelData.name); color: r.ink; font.family: Theme.font; font.pixelSize: 14; font.weight: Font.Medium }
                            Text { visible: !!r.modelData.desc; x: r.nx; y: r.gap + 35 - height / 2; width: r.width - r.nx - 40; elide: Text.ElideRight; text: r.modelData.desc ? I18n.tr(r.modelData.desc) : ""; color: sheet.lk.dim; font.family: Theme.font; font.pixelSize: 12 }
                            Text { visible: !!r.modelData.note; x: 14; y: r.gap + 6; width: r.width - 28; wrapMode: Text.WordWrap; maximumLineCount: 2; text: I18n.tr(r.modelData.name); color: sheet.lk.dim; font.family: Theme.font; font.pixelSize: 12 }
                            Text { visible: sheet.hintX > 0 && !!r.modelData.hint; x: sheet.hintX; y: r.mid - height / 2; width: r.width - sheet.hintX - 30; elide: Text.ElideRight; text: r.modelData.hint ? I18n.tr(r.modelData.hint) : ""; color: sheet.lk.dim; font.family: Theme.font; font.pixelSize: 12 }
                            Text { id: keyText; anchors.right: parent.right; anchors.rightMargin: r.modelData.more || r.on || r.web ? 34 : 14; y: r.mid - height / 2; text: shell.keyOf(r.modelData); color: r.web ? shell.webInk : sheet.lk.dim; font.family: Theme.font; font.pixelSize: 12 }
                            Glyph { x: r.width - 18 - width / 2; y: r.mid - height / 2; visible: !!r.modelData.more; name: "chevron-right"; font.pixelSize: 14; color: r.web ? shell.webInk : sheet.lk.dim }
                            Glyph { x: r.width - 18 - width / 2; y: r.mid - height / 2; visible: r.web && !r.modelData.more; name: "external-link"; font.pixelSize: 12; color: shell.webInk }
                            Glyph { x: r.width - 18 - width / 2; y: r.mid - height / 2; visible: r.on && !sheet.tickLeft && !sheet.radio; name: "check"; font.pixelSize: 15; color: sheet.own ? Theme.gold : shell.look.tick }
                            Rectangle { visible: sheet.radio && !r.web; x: r.width - 25; y: r.mid - 7; width: 14; height: 14; radius: 7; color: "transparent"; border.width: r.on ? 4 : 1; border.color: r.on ? "#fa500f" : "#c8c8c8" }
                            MouseArea { id: rowHit; anchors.fill: parent; anchors.topMargin: r.gap; hoverEnabled: true; enabled: !r.off; cursorShape: Qt.PointingHandCursor
                                        onClicked: shell.act(r.modelData, r.y, sheet.sub) } } } } }
            Sheet { id: menu; visible: shell.menuAt !== ""; own: shell.menuAt === "who"
                rows: shell.menuAt === "who" ? shell.providers.map(p => ({ name: p.name, key: p.id === shell.useProvider && shell.useM ? shell.useM.name : p.models[0].name, "do": { provider: p.id, model: p.id === shell.useProvider && shell.useM ? shell.useM.id : p.models[0].id } }))
                      : shell.useP ? (shell.menuAt === "plus" ? shell.useP.plus : shell.useP.menu) : []
                width: shell.menuAt === "who" ? 300 : shell.menuAt === "plus" ? (({ claude: 260, gemini: 280, chatgpt: 470, grok: 250, mistral: 280 })[shell.style] || 250) : (({ claude: 380, gemini: 230, chatgpt: 300, grok: 320, mistral: 270 })[shell.style] || 300)
                hintX: shell.menuAt === "plus" && shell.style === "chatgpt" ? 196 : 0
                x: shell.menuAt === "who" ? whoPill.x : shell.menuAt === "plus" ? box.x + 8 : Math.max(box.x, Math.min(box.x + chip.x + chip.width - width, box.x + box.width - width))
                y: (shell.menuAt === "who" ? whoPill.y : box.y) - height - 6 }
            Sheet { visible: menu.visible && shell.subRows.length > 0; sub: true; own: menu.own; rows: shell.subRows
                width: shell.style === "gemini" ? 280 : shell.style === "claude" ? 190 : 220
                x: menu.x + menu.width + 4 + width <= parent.width - 8 ? menu.x + menu.width + 4 : Math.max(8, menu.x - width - 4)
                y: Math.min(menu.y + shell.subY, box.y - height - 6) }
        }

        // ── the agents: every subscription on one page, limits first (Omarchy's agents panel, MIT) ──────────────
        Flickable {
            anchors.fill: parent
            visible: shell.page === "agents"
            contentHeight: agentCol.implicitHeight + 48; clip: true; boundsBehavior: Flickable.StopAtBounds
            Column { id: agentCol; x: 28; y: 24; width: Math.min(parent.width - 56, 760); spacing: 14
                // what the counts add up to, one line at a time, as Omarchy's hero has it
                Rectangle { width: parent.width; height: 96; radius: 16; color: Theme.card; border.width: 1; border.color: Theme.line
                    property int turn: 0
                    Timer { interval: 4000; repeat: true; running: shell.page === "agents"; onTriggered: parent.turn += 1 }
                    readonly property var lines: { const st = shell.agents.stats || {}; return [
                        I18n.tr("{n} tokens this week", { n: shell.tokens(st.week) }), I18n.tr("{n} tokens today", { n: shell.tokens(st.today) }),
                        I18n.tr("Most used: {n}", { n: shell.modelWord(st.model) || "—" }), I18n.tr("Busiest day: {n}", { n: st.busiest ? Qt.formatDate(new Date(st.busiest), "d. M.") : "—" }),
                        I18n.tr("{n} questions today", { n: st.prompts || 0 }) ] }
                    Glyph { x: 22; anchors.verticalCenter: parent.verticalCenter; name: "robot"; font.pixelSize: 40; color: Theme.gold }
                    Column { x: 80; anchors.verticalCenter: parent.verticalCenter; spacing: 4; width: parent.width - 140
                        Label { text: parent.parent.lines[parent.parent.turn % parent.parent.lines.length]; font.pixelSize: 20; font.weight: 800 }
                        Label { text: I18n.tr("Counted from Claude Code's own records on this computer, LensAI's questions included."); color: Theme.dim; font.pixelSize: 12; width: parent.width; wrapMode: Text.WordWrap } }
                    Pill { anchors.right: parent.right; anchors.rightMargin: 16; anchors.verticalCenter: parent.verticalCenter; implicitHeight: 34; icon: "refresh"; text: ""
                           busy: agentsq.running; onPressed: agentsq.ask(["agents"]) } }
                // "Do it for me": what the agent should do, which agent, and tasks to start from
                Rectangle { width: parent.width; height: doCol.implicitHeight + 32; radius: 16; color: Theme.card; border.width: 1; border.color: Theme.line
                    visible: (shell.agents.doers || []).length > 0
                    Column { id: doCol; x: 18; y: 16; width: parent.width - 36; spacing: 12
                        Label { text: I18n.tr("Do it for me"); font.pixelSize: 16; font.weight: 800 }
                        Label { width: parent.width; wrapMode: Text.WordWrap; color: Theme.dim; font.pixelSize: 13
                                text: I18n.tr("The agent opens in a terminal, looks around, makes a plan and asks you before it changes anything. It knows LatteOS from its skill (Instructions).") }
                        Row { spacing: 10; width: parent.width
                            Rectangle { width: parent.width - doGo.width - 10; height: 40; radius: 12; color: Theme.raised; border.width: 1; border.color: doTask.activeFocus ? Theme.gold : Theme.line
                                TextInput { id: doTask; x: 14; width: parent.width - 28; anchors.verticalCenter: parent.verticalCenter; color: Theme.cream; font.family: Theme.font; font.pixelSize: 14; clip: true; selectByMouse: true
                                            onAccepted: { if (text.trim() !== "") { shell.doIt(text, ""); text = "" } } }
                                Label { x: 14; anchors.verticalCenter: parent.verticalCenter; visible: doTask.text === ""; color: Theme.faint; text: I18n.tr("What should it do? For example: my disk is full, make room") } }
                            Pill { id: doGo; implicitHeight: 40; icon: "robot"; strong: true; text: I18n.tr("Do it"); onPressed: { if (doTask.text.trim() !== "") { shell.doIt(doTask.text, ""); doTask.text = "" } } } }
                        // which agent: the chosen one first (latte-ai doer)
                        Flow { width: parent.width; spacing: 8
                            Repeater { model: shell.agents.doers || []
                                Pill { required property var modelData; required property int index; implicitHeight: 30; text: modelData.name; strong: index === 0; icon: index === 0 ? "check" : ""
                                       onPressed: { chooser.command = ["latte-ai", "doer", modelData.id]; chooser.running = true } } } }
                        Flow { width: parent.width; spacing: 8
                            Repeater { model: shell.agents.ideas || []
                                Pill { required property var modelData; implicitHeight: 30; icon: "sparkles"; text: I18n.tr(modelData); onPressed: shell.doIt(I18n.tr(modelData), "") } } } } }
                // one section per service: its mark, name and plan, then a line per limit window
                Repeater { model: shell.agents.services || []
                    Rectangle { id: sec; required property var modelData; width: agentCol.width; height: secCol.implicitHeight + 32; radius: 16; color: Theme.card; border.width: 1; border.color: Theme.line
                        readonly property string mark: ({ claude: "claude", gemini: "gemini", chatgpt: "openai", grok: "grok", mistral: "mistral", copilot: "githubcopilot" })[modelData.id] || ""
                        Column { id: secCol; x: 18; y: 16; width: parent.width - 36; spacing: 10
                            Row { spacing: 12; height: 32
                                Rectangle { width: 32; height: 32; radius: 9; color: "#f5f1ea"; anchors.verticalCenter: parent.verticalCenter
                                    Image { anchors.centerIn: parent; visible: sec.mark !== ""; source: sec.mark ? "file://" + I18n.share + "/goo/ai/" + sec.mark + ".svg" : ""; sourceSize: Qt.size(22, 22) } }
                                Label { text: I18n.tr(sec.modelData.name); font.pixelSize: 16; font.weight: 800; anchors.verticalCenter: parent.verticalCenter }
                                Rectangle { visible: sec.modelData.plan !== ""; height: 22; radius: 11; width: planText.implicitWidth + 18; color: Qt.rgba(Theme.gold.r, Theme.gold.g, Theme.gold.b, 0.16); anchors.verticalCenter: parent.verticalCenter
                                    Label { id: planText; anchors.centerIn: parent; text: sec.modelData.plan.toUpperCase(); color: Theme.gold; font.pixelSize: 11; font.weight: 800 } }
                                // a lapsed sign-in: signing in again, in a terminal, where the tool asks what it needs
                                Text { visible: sec.modelData.signed === false; text: I18n.tr("Sign-in required"); color: Theme.gold; font.family: Theme.font; font.pixelSize: 13; font.weight: Font.DemiBold; font.underline: true; anchors.verticalCenter: parent.verticalCenter
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { shell.inTerminal(sec.modelData.login); later.start() } } } }
                            Repeater { model: sec.modelData.limits
                                Item { required property var modelData; width: secCol.width; height: 22
                                    Label { width: 170; text: I18n.tr(modelData.label); color: Theme.dim; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter; elide: Text.ElideRight }
                                    DotBar { x: 180; width: parent.width - 180 - 130; height: 10; segments: 24; value: modelData.used; anchors.verticalCenter: parent.verticalCenter }
                                    Label { anchors.right: parent.right; width: 120; horizontalAlignment: Text.AlignRight; anchors.verticalCenter: parent.verticalCenter; font.pixelSize: 13; font.weight: 700
                                            text: Math.round(modelData.used * 100) + " %" + (shell.left(modelData.resets) ? "  ·  " + shell.left(modelData.resets) : "") } } }
                            // a service that tells no figures: what LatteOS counts itself, said as that
                            Label { visible: sec.modelData.limits.length === 0; width: secCol.width; wrapMode: Text.WordWrap; color: Theme.dim; font.pixelSize: 13
                                    text: I18n.tr("{n} questions through Lens this month", { n: sec.modelData.asked }) + "  ·  " + I18n.tr("The account's quota is not told here; the service's own page shows it.") } } } }
                Label { visible: (shell.agents.services || []).length === 0 && !agentsq.running; width: parent.width; wrapMode: Text.WordWrap; color: Theme.dim
                        text: I18n.tr("No AI service is installed: see Services.") } } }

        // ── one question to several AIs at once, the answers side by side ──────────────────────────────────
        Item {
            id: cmp
            anchors.fill: parent
            visible: shell.page === "compare"
            Column { id: cmpTop; x: 28; y: 22; width: parent.width - 56; spacing: 12
                Label { width: parent.width; wrapMode: Text.WordWrap; color: Theme.dim
                        text: I18n.tr("Choose up to three, ask once, and read them side by side. Each answer is kept as a conversation of its own, to go on with.") }
                Flow { width: parent.width; spacing: 8
                    Repeater { model: { const all = []; shell.providers.forEach(p => p.models.forEach(m => all.push({ provider: p.id, model: m.id, name: I18n.tr(p.name) + " · " + m.name }))); return all }
                        Pill { required property var modelData; implicitHeight: 32; text: modelData.name
                               readonly property bool chosen: shell.picks.some(x => x.provider === modelData.provider && x.model === modelData.model)
                               strong: chosen; icon: chosen ? "check" : ""
                               onPressed: shell.picks = chosen ? shell.picks.filter(x => !(x.provider === modelData.provider && x.model === modelData.model))
                                                               : shell.picks.concat([{ provider: modelData.provider, model: modelData.model }]).slice(-3) } } }
                Row { spacing: 10
                    Field { id: cmpLine; width: cmpTop.width - 140; icon: "sparkles"; hint: I18n.tr("Ask them all…")
                            onAccepted: cmpGo.pressed() }
                    Pill { id: cmpGo; icon: "arrow-up"; strong: true; text: I18n.tr("Ask"); implicitHeight: 40
                           onPressed: if (cmpLine.text.trim() !== "" && shell.picks.length > 0) { shell.asked = cmpLine.text.trim(); shell.round += 1; cmpLine.text = "" } } } }
            Row {
                anchors.top: cmpTop.bottom; anchors.topMargin: 16; anchors.bottom: parent.bottom; anchors.bottomMargin: 22; x: 28
                spacing: 12
                Repeater { model: shell.picks
                    Rectangle { id: col; required property var modelData; required property int index
                        width: (cmp.width - 56 - 12 * (shell.picks.length - 1)) / shell.picks.length; height: parent.height; radius: 18; color: Theme.card
                        border.width: 1; border.color: Qt.rgba(Qt.color(shell.colour(modelData.provider)).r, Qt.color(shell.colour(modelData.provider)).g, Qt.color(shell.colour(modelData.provider)).b, 0.5)
                        property string said: ""
                        property bool busy: false
                        property real took: 0
                        property double began: 0
                        // each column asks on its own, so the quickest is read first
                        Process { id: asker
                            stdout: SplitParser { onRead: line => { let m = null; try { m = JSON.parse(line) } catch (e) { return }
                                if (m.delta !== undefined) col.said += m.delta
                                else if (m.chat) col.said = m.answer } }
                            onExited: { col.busy = false; col.took = (Date.now() - col.began) / 1000; list.ask(["chats"]) } }
                        Connections { target: shell
                            function onRoundChanged() {
                                col.said = ""; col.busy = true; col.began = Date.now()
                                asker.command = ["latte-ai", "send", "new", col.modelData.provider, col.modelData.model, shell.asked, "--stream", "--markdown"]; asker.running = true } }
                        Label { x: 16; y: 14; text: shell.nameOf(col.modelData.provider) + " · " + shell.modelName(col.modelData.provider, col.modelData.model)
                                color: shell.colour(col.modelData.provider); font.weight: 700 }
                        Label { anchors.right: parent.right; anchors.rightMargin: 16; y: 14; color: Theme.dim; font.pixelSize: 12
                                text: col.busy ? I18n.tr("Thinking…") : (col.took > 0 ? col.took.toFixed(1) + " s" : "") }
                        Flickable { x: 16; y: 44; width: parent.width - 32; height: parent.height - 58; clip: true; contentHeight: colText.implicitHeight; boundsBehavior: Flickable.StopAtBounds
                            TextEdit { id: colText; width: parent.width; readOnly: true; selectByMouse: true; wrapMode: Text.Wrap; textFormat: TextEdit.MarkdownText
                                       text: col.said; color: Theme.cream; font.family: Theme.font; font.pixelSize: 14; selectionColor: Theme.coffee } } } }
            }
            Label { visible: shell.picks.length === 0; anchors.centerIn: parent; color: Theme.dim; text: I18n.tr("Choose who to compare above.") }
        }

        // ── what every AI is told first: who the user is, how they want to be answered ─────────────────────
        Scroll {
            id: rulePage
            visible: shell.page === "instructions"
            Label { width: rulePage.room; wrapMode: Text.WordWrap; color: Theme.dim
                    text: I18n.tr("What you write here goes with every question, to every AI, in LensGoo too: who you are, what you know, how you want to be answered. For example: “I am new to Linux, explain simply. Answer in Slovak.”") }
            Rectangle { width: rulePage.room; height: 260; radius: 16; color: Theme.card; border.width: 1; border.color: ruleText.activeFocus ? Theme.gold : Theme.line
                Flickable { anchors.fill: parent; anchors.margins: 14; clip: true; contentHeight: ruleText.implicitHeight; boundsBehavior: Flickable.StopAtBounds
                    TextEdit { id: ruleText; width: parent.width; wrapMode: Text.Wrap; color: Theme.cream; font.family: Theme.font; font.pixelSize: 14; selectByMouse: true; selectionColor: Theme.coffee } } }
            Row { spacing: 10
                Pill { icon: "check"; strong: true; text: rulePage.saved ? I18n.tr("Kept") : I18n.tr("Keep"); onPressed: { rules.setText(ruleText.text.trim() + "\n"); rulePage.saved = true; keptAgain.restart() } }
                Label { text: I18n.tr("{n} of 4000 characters", { n: ruleText.text.length }); color: ruleText.text.length > 4000 ? Theme.red : Theme.dim; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter } }
            property bool saved: false
            Timer { id: keptAgain; interval: 1800; onTriggered: rulePage.saved = false }

            // LatteOS's skill for the agents (as Omarchy's): the user's own copy, which their agents read; Restore
            // brings back LatteOS's own (the user's kept beside it)
            Item { width: 1; height: 12 }
            Label { text: I18n.tr("LatteOS skill for the agents"); font.pixelSize: 17; font.weight: 800 }
            Label { width: rulePage.room; wrapMode: Text.WordWrap; color: Theme.dim
                    text: I18n.tr("What Claude Code, Codex and Gemini know about LatteOS when you ask them for help with this computer: how it is built, what may be changed and how, and that they plan first and ask. Add your own rules at the end.") }
            Rectangle { width: rulePage.room; height: 360; radius: 16; color: Theme.card; border.width: 1; border.color: skillText.activeFocus ? Theme.gold : Theme.line
                Flickable { id: skillView; anchors.fill: parent; anchors.margins: 14; clip: true; contentHeight: skillText.implicitHeight; boundsBehavior: Flickable.StopAtBounds
                    TextEdit { id: skillText; width: parent.width; wrapMode: Text.Wrap; color: Theme.cream; font.family: "monospace"; font.pixelSize: 13; selectByMouse: true; selectionColor: Theme.coffee } } }
            Row { spacing: 10
                Pill { icon: "check"; strong: true; text: rulePage.skillSaved ? I18n.tr("Kept") : I18n.tr("Keep"); onPressed: { skillFile.setText(skillText.text); rulePage.skillSaved = true; skillKept.restart() } }
                Pill { icon: "arrow-back-up"; text: I18n.tr("Restore LatteOS's own"); onPressed: skillReset.running = true } }
            property bool skillSaved: false
            Timer { id: skillKept; interval: 1800; onTriggered: rulePage.skillSaved = false }
        }

        // ── the models: which show in LensGoo, and which one answers first ───────────────────────────────────
        Scroll {
            id: modelPage
            visible: shell.page === "models"
            Label { width: modelPage.room; wrapMode: Text.WordWrap; color: Theme.dim
                    text: I18n.tr("Every model your services and keys offer. Those that are on show in LensGoo's choice; the star marks the one a new conversation begins with.") }
            Waiting { visible: shell.models.length === 0 && modelq.running; text: I18n.tr("Asking the services…"); width: modelPage.room }
            Repeater { model: shell.models
                Column { id: mg; required property var modelData; width: modelPage.room; spacing: 6
                    Row { spacing: 10; height: 30
                        Rectangle { width: 10; height: 10; radius: 5; color: shell.colour(mg.modelData.id); anchors.verticalCenter: parent.verticalCenter }
                        Label { text: I18n.tr(mg.modelData.name); font.pixelSize: 16; font.weight: 700; anchors.verticalCenter: parent.verticalCenter } }
                    Repeater { model: mg.modelData.models
                        Rectangle { id: mr; required property var modelData; width: modelPage.room; height: 48; radius: 14; color: Theme.card
                            Glyph { x: 16; name: "star"; font.pixelSize: 18; color: mr.modelData.default ? Theme.gold : Theme.faint; anchors.verticalCenter: parent.verticalCenter
                                MouseArea { anchors.fill: parent; anchors.margins: -8; cursorShape: Qt.PointingHandCursor; onClicked: modeler.ask(["model", "default", mg.modelData.id, mr.modelData.id]) } }
                            Row { x: 48; spacing: 12; anchors.verticalCenter: parent.verticalCenter
                                Label { text: mr.modelData.name; font.weight: 600; opacity: mr.modelData.hidden ? 0.5 : 1 }
                                Label { visible: mr.modelData.default; text: I18n.tr("default"); color: Theme.gold; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter } }
                            Rectangle { width: 46; height: 26; radius: 13; color: mr.modelData.hidden ? Theme.raised : Theme.gold; anchors.right: parent.right; anchors.rightMargin: 16; anchors.verticalCenter: parent.verticalCenter
                                Rectangle { width: 20; height: 20; radius: 10; y: 3; x: mr.modelData.hidden ? 3 : 23; color: mr.modelData.hidden ? Theme.dim : Theme.inkOnGold }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: modeler.ask(["model", mr.modelData.hidden ? "show" : "hide", mg.modelData.id, mr.modelData.id]) } } } } } }
        }

        // ── the services: which are there, which is signed in; signing in and out ────────────────────────────
        Scroll {
            id: svcPage
            visible: shell.page === "services"
            Label { text: I18n.tr("ACCOUNTS"); color: Theme.faint; font.pixelSize: 11; font.weight: 700; font.letterSpacing: 0.8 }
            Waiting { visible: shell.services.length === 0 && svc.running; text: I18n.tr("Asking the services…"); width: svcPage.room }
            Label { width: svcPage.room; wrapMode: Text.WordWrap; color: Theme.dim
                    text: I18n.tr("With an account, the service's official tool answers, signed in once in the terminal. Which of them LensGoo offers is set in Settings › Launcher.") }
            Repeater { model: shell.services
                Rectangle { id: card; required property var modelData; width: svcPage.room; height: 84; radius: 20; color: Theme.card
                    Rectangle { x: 18; width: 48; height: 48; radius: 14; color: shell.colour(card.modelData.id); opacity: card.modelData.installed ? 1 : 0.35; anchors.verticalCenter: parent.verticalCenter
                        Glyph { anchors.centerIn: parent; name: card.modelData.local ? "device-desktop" : "cloud"; font.pixelSize: 22; color: "#ffffff" } }
                    Column { x: 82; width: parent.width - 82 - 300; anchors.verticalCenter: parent.verticalCenter; spacing: 4
                        Label { text: I18n.tr(card.modelData.name); font.pixelSize: 16; font.weight: 700 }
                        Label { width: parent.width; elide: Text.ElideRight; color: Theme.dim; font.pixelSize: 12
                                text: !card.modelData.installed ? I18n.tr("Not installed: its tool {tool} is missing.", { tool: card.modelData.tool })
                                    : card.modelData.local ? I18n.tr("Answers on this computer; nothing leaves it.")
                                    : card.modelData.signed === true ? I18n.tr("Signed in") + (card.modelData.account ? " · " + card.modelData.account : "")
                                    : card.modelData.signed === false ? I18n.tr("Not signed in") : I18n.tr("Installed; sign in once in the terminal.") } }
                    Row { anchors.right: parent.right; anchors.rightMargin: 18; anchors.verticalCenter: parent.verticalCenter; spacing: 8
                        Rectangle { visible: card.modelData.installed && card.modelData.signed === true; width: 10; height: 10; radius: 5; color: Theme.ok; anchors.verticalCenter: parent.verticalCenter }
                        Pill { visible: card.modelData.installed && card.modelData.login.length > 0 && card.modelData.signed !== true; icon: "login"; strong: true; text: I18n.tr("Sign in")
                               onPressed: { shell.inTerminal(card.modelData.login); later.restart() } }
                        Pill { visible: card.modelData.installed && card.modelData.logout.length > 0 && card.modelData.signed === true; icon: "logout"; text: I18n.tr("Sign out")
                               onPressed: { shell.inTerminal(card.modelData.logout); later.restart() } } } } }

            // a key of one's own, as in VS Code: the service's API answers directly, a conversation and no tools
            Label { text: I18n.tr("KEYS OF YOUR OWN"); color: Theme.faint; font.pixelSize: 11; font.weight: 700; font.letterSpacing: 0.8 }
            Label { width: svcPage.room; wrapMode: Text.WordWrap; color: Theme.dim
                    text: I18n.tr("With a key from the service's own site, its API answers directly: you pay it for what you use. The key is kept in the system's keyring, never in a file.") }
            Repeater { model: shell.keys.filter(k => !k.server)
                Rectangle { id: kc; required property var modelData; width: svcPage.room; height: 64; radius: 18; color: Theme.card
                    Rectangle { x: 16; width: 10; height: 10; radius: 5; color: shell.colour(kc.modelData.id); anchors.verticalCenter: parent.verticalCenter }
                    Column { x: 38; width: 260; anchors.verticalCenter: parent.verticalCenter; spacing: 2
                        Label { text: kc.modelData.name; font.weight: 700 }
                        Label { text: kc.modelData.has ? I18n.tr("A key is kept") : I18n.tr("No key"); color: kc.modelData.has ? Theme.ok : Theme.dim; font.pixelSize: 12 } }
                    Row { anchors.right: parent.right; anchors.rightMargin: 14; anchors.verticalCenter: parent.verticalCenter; spacing: 8
                        Field { id: kf; visible: !kc.modelData.has; width: Math.min(360, svcPage.room - 520); icon: "key"; secret: true; hint: I18n.tr("Paste the key…")
                                onAccepted: { shell.keep(kc.modelData.id, text); text = "" } }
                        Pill { visible: !kc.modelData.has; icon: "check"; strong: true; text: I18n.tr("Keep"); onPressed: { shell.keep(kc.modelData.id, kf.text); kf.text = "" } }
                        Pill { visible: kc.modelData.has; icon: "trash"; danger: true; text: I18n.tr("Remove the key"); onPressed: keyer.ask(["forget-key", kc.modelData.id]) } } } }

            // servers of one's own: anything that speaks the OpenAI API — llama-server, Ollama, a computer at home
            Label { text: I18n.tr("SERVERS OF YOUR OWN"); color: Theme.faint; font.pixelSize: 11; font.weight: 700; font.letterSpacing: 0.8 }
            Repeater { model: shell.keys.filter(k => k.server)
                Rectangle { id: sc; required property var modelData; width: svcPage.room; height: 58; radius: 18; color: Theme.card
                    Glyph { x: 18; name: "server"; color: Theme.gold; anchors.verticalCenter: parent.verticalCenter }
                    Column { x: 48; width: parent.width - 200; anchors.verticalCenter: parent.verticalCenter; spacing: 2
                        Label { text: sc.modelData.name; font.weight: 700 }
                        Label { text: sc.modelData.url; color: Theme.dim; font.pixelSize: 12; width: parent.width; elide: Text.ElideRight } }
                    Pill { anchors.right: parent.right; anchors.rightMargin: 14; anchors.verticalCenter: parent.verticalCenter; icon: "trash"; danger: true; text: I18n.tr("Remove")
                           onPressed: keyer.ask(["server", "remove", sc.modelData.id]) } } }
            Row { spacing: 10
                Field { id: srvName; width: 220; icon: "server"; hint: I18n.tr("Name") }
                Field { id: srvUrl; width: Math.min(380, svcPage.room - 380); icon: "world-www"; hint: "http://192.168.1.10:8080/v1" }
                Pill { icon: "plus"; strong: true; text: I18n.tr("Add")
                       onPressed: if (/^https?:\/\/\S+$/.test(srvUrl.text.trim()) && srvName.text.trim() !== "") { keyer.ask(["server", "add", srvName.text.trim(), srvUrl.text.trim()]); srvName.text = ""; srvUrl.text = "" } } }
        }
    }
}
