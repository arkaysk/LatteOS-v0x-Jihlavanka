//@ pragma AppId latteos-aicenter
//@ pragma EnableQtWebEngineQuick
// LensAI: every conversation with every AI in one list, and the services themselves — which are there,
// which one is signed in, signing in and out. bin/latte-ai keeps the conversations (the same ones LensGoo's AI
// tab writes) and knows the services; this window shows them.   latte-app aicenter [lensai | local | tab SERVICE | CHAT]
//
// An AI is reached in one of three ways, each with its mark after a name (the colours of the graphs, Theme.heat): green
// its own page in a tab (web), gold its official tool in a terminal (CLI), red a key of one's own (API). Settings has a
// part for each, and what every AI is told first; the models on this computer have a page of their own (Local LLMs).
// The rings under the overview are the services' own pages, as tabs (apps/aicenter/WebTabs.qml; the pragma above is
// what the Quickshell of bin/latte-app's LATTE_WEB needs for them, the plain one only warns of it).
import QtQuick
import Quickshell
import Quickshell.Io
import "common"

ShellRoot {
    id: shell
    readonly property var words: (Quickshell.env("LATTE_APP_ARGS") || "").split("\n").filter(w => w !== "")
    property string page: "home"               // home (the dashboard) · all (every conversation, by service) · chats (one) · web · agents (the helpers too) · local · lensai (settings)
    property string section: "web"             // the part of the settings open: web · cli · api · instructions
    function openSection(id) {
        page = "lensai"; section = id
        if (id === "cli") { svc.ask(["services"]); mcpq.running = true }
        if (id === "api") keyq.ask(["keys"])
        if (id !== "instructions") { modelq.ask(["models"]); agentsq.ask(["agents"]) }
    }
    // how an AI is reached: the mark after its name
    // the graphs' green, gold and red (Theme.heat), the gold fixed: a theme made from the wallpaper may have a red one
    readonly property var kinds: ({ web: Theme.ok, cli: "#f2b63c", api: Theme.red })
    function kindOf(id) { return /^(api-|server-)/.test(id) ? "api" : id === "local" || id === "ollama" ? "" : providers.some(p => p.id === id) || services.some(x => x.id === id) ? "cli" : tabbed.some(t => t.id === id) ? "web" : "cli" }
    component Kind: Rectangle { property string kind; visible: shell.kinds[kind] !== undefined; width: 10; height: 10; radius: 3; color: visible ? shell.kinds[kind] : "transparent" }
    component Toggle: Rectangle { id: tg; property bool on; signal flipped(); width: 46; height: 26; radius: 13; color: on ? Theme.gold : Theme.raised
        Rectangle { width: 20; height: 20; radius: 10; y: 3; x: tg.on ? 23 : 3; color: tg.on ? Theme.inkOnGold : Theme.dim }
        MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; onClicked: tg.flipped() } }
    // LatteOS's skill: the user's copy, made when it is first needed (latte-ai skill)
    FileView { id: skillFile; path: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/latteos/skills/latteos/SKILL.md"; printErrors: false
               onLoaded: skillText.text = text(); onLoadFailed: skillMake.running = true }
    Process { id: skillMake; command: ["latte-ai", "skill", "install"]; onExited: skillFile.reload() }
    Process { id: skillReset; command: ["latte-ai", "skill", "reset"]; onExited: skillFile.reload() }
    FileView { id: rules; path: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/latteos/ai-instructions.txt"; printErrors: false
               onLoaded: ruleText.text = text() }
    property string only: ""                   // the side shows only this service's conversations; "" all
    property string open: ""                   // the conversation shown
    property string find: ""
    property var chats: []
    property var chat: null
    property var providers: []                 // what can answer now (latte-ai providers)
    property var services: []                  // every service known (latte-ai services)
    property bool waiting: false
    // each service has its colour, so that a conversation is known by it at a glance
    readonly property var colours: ({ "api-deepseek": "#4d6bfe", "api-anthropic": "#d97757", "api-openai": "#10a37f", "api-google": "#4285f4", "api-xai": "#a8a8a8", "api-mistral": "#fa520f", "claude": "#d97757", "gemini": "#4285f4", "chatgpt": "#10a37f", "grok": "#a8a8a8", "mistral": "#fa520f", "deepseek": "#4d6bfe", "suno": "#f7c873", "local": Theme.gold, "ollama": Theme.gold })
    function colour(id) { return colours[id] || Theme.gold }
    function nameOf(id) { const p = services.find(s => s.id === id) || providers.find(s => s.id === id) || keys.find(k => k.id === id); return p ? I18n.tr(p.name) : id }
    function modelName(pid, mid) { const p = providers.find(x => x.id === pid); const m = p ? p.models.find(x => x.id === mid) : null; return m ? m.name : mid }
    readonly property var mine: chats.filter(c => !c.machine)          // not what a program asked for its own work (latte-ai MACHINE)
    readonly property var shown: mine.filter(c => (only === "" || c.provider === only) && (find === "" || c.title.toLowerCase().includes(find.toLowerCase())))
    readonly property var groups: { const g = {}; shown.forEach(c => (g[c.provider] = g[c.provider] || []).push(c)); return Object.keys(g).map(p => ({ id: p, chats: g[p] })) }
    readonly property var places: ({ lensai: "LensAI", lensgoo: "LensGoo", lensshore: "LensShore" })      // where a conversation began ("from")
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
    // the dashboard (docs/lensai/POZIADAVKY.md): the agents of pleamar-wm's terminals too, read only (`pleamar-wm agents`)
    Process { id: wmAgents; property var list: []
              command: ["pleamar-wm", "agents", "--json"]
              stdout: StdioCollector { onStreamFinished: wmAgents.list = this.text.split("\n").filter(l => l.trim() !== "")
                                                             .map(l => { try { return JSON.parse(l) } catch (e) { return null } }).filter(x => x) } }
    function lookAround() { agentsq.ask(["agents"]); localModels.ask(["models"]); if (!wmAgents.running) wmAgents.running = true }
    // (the rings' dots want it on every page too)
    Timer { interval: 5000; repeat: true; running: true; triggeredOnStart: true; onTriggered: if (!wmAgents.running) wmAgents.running = true }
    // a service whose own tool works in a terminal, or waits for the person there: the gold dot on its ring
    readonly property var cliOf: ({ claude: "claude", codex: "chatgpt", gemini: "gemini", copilot: "copilot" })
    function busy(id) { return wmAgents.list.some(a => cliOf[a.agent] === id && (a.state === "working" || a.state === "asking")) }
    // what Claude Code's records add up to, a line at a time (Omarchy's hero): on the overview and over the agents
    property int turn: 0
    Timer { interval: 4000; repeat: true; running: shell.page === "agents" || shell.page === "home"; onTriggered: shell.turn += 1 }
    readonly property var statLines: { const st = agents.stats || {}; return [
        I18n.tr("{n} tokens this week", { n: tokens(st.week) }), I18n.tr("{n} tokens today", { n: tokens(st.today) }),
        I18n.tr("Most used: {n}", { n: modelWord(st.model) || "—" }), I18n.tr("Busiest day: {n}", { n: st.busiest ? Qt.formatDate(new Date(st.busiest), "d. M.") : "—" }),
        I18n.tr("{n} questions today", { n: st.prompts || 0 }) ] }
    // the services' own pages as tabs (ROADMAP 10B.35): the one shown, and whether this Quickshell can hold a page at all
    property string tab: ""
    property string tabBeside: ""              // a second tab beside it, half and half ("" none)
    readonly property bool web: Quickshell.env("LATTE_WEB") === "1"
    // whether its tool is installed or not (latte-ai): the user signs in on the page itself. The user's own list is kept
    // in ~/.config/latteos/lensai-tabs.json (LensAI › Settings); these until there is one. A tab: id (its profile), name,
    // web; and the person's own: account (a note: LensAI reads nothing from a page), icon (a picture chosen), usage (the
    // tool whose limits its ring shows: its own id unless said, "" none); fav, favUrl (the page's icon, kept)
    property var tabbed: defaultTabs
    readonly property var defaultTabs: [
        { id: "claude", name: "Claude", web: "https://claude.ai/new" },
        { id: "gemini", name: "Gemini", web: "https://gemini.google.com/app" },
        { id: "chatgpt", name: "ChatGPT", web: "https://chatgpt.com/" },
        { id: "mistral", name: "Mistral", web: "https://chat.mistral.ai/chat" },
        { id: "deepseek", name: "DeepSeek", web: "https://chat.deepseek.com/" },
        { id: "grok", name: "Grok", web: "https://grok.com/" },
        { id: "suno", name: "Suno", web: "https://suno.com/create" } ]
    FileView {
        id: tabsFile
        path: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/latteos/lensai-tabs.json"
        printErrors: false; watchChanges: true
        onFileChanged: reload()
        onLoaded: { try { const t = JSON.parse(text()); if (Array.isArray(t)) shell.tabbed = t.filter(x => x && x.id && /^https?:\/\//.test(x.web || "")) } catch (e) {} }
    }
    function keepTabs(list) {
        tabbed = list
        Quickshell.execDetached(["sh", "-c", "mkdir -p \"$(dirname \"$1\")\" && printf '%s\\n' \"$2\" > \"$1\"", "sh", tabsFile.path, JSON.stringify(list, null, 1)])
    }
    // a page by its address; its name, or its host without one. False when it is not an address or is there already
    function addTab(name, address) {
        let web = address.trim()
        if (!/^https?:\/\//.test(web)) web = "https://" + web
        const host = web.replace(/^https?:\/\//, "").split(/[\/?#:]/)[0].toLowerCase()
        if (!/^[a-z0-9-]+(\.[a-z0-9-]+)+$/.test(host)) return false
        // the same service a second time (another account) is another tab with a profile of its own
        const base = host.replace(/^www\./, ""); let id = base, n = 2
        while (tabbed.some(t => t.id === id)) id = base + "-" + n++
        keepTabs(tabbed.concat([{ id: id, name: name.trim() || base, web: web, usage: "" }]))
        return true
    }
    function setTab(id, what) { keepTabs(tabbed.map(t => t.id === id ? Object.assign({}, t, what) : t)) }
    function usageOf(t) { return t.usage !== undefined ? t.usage : t.id }
    // a tab's picture: the one the person chose, else its page's own icon as it was last seen, else LatteOS's mark
    function iconOf(t) { return t.icon ? "file://" + t.icon : t.fav ? "file://" + t.fav : marks[t.id] ? "file://" + I18n.share + "/goo/ai/" + marks[t.id] + ".svg" : "" }
    // a page's icon is kept as a file when its tab first shows it (and again when the page changes it), so the ring has
    // it before the tab is opened the next time
    readonly property string favDir: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/latteos/lensai-icons"
    property var favQueue: []
    Process { id: favGet; property var job: null
              onExited: code => { const j = job; job = null; if (code === 0 && j) shell.setTab(j.id, { fav: j.path, favUrl: j.url }); shell.favNext() } }
    function favNext() {
        if (favGet.running || favQueue.length === 0) return
        favGet.job = favQueue[0]; favQueue = favQueue.slice(1)
        favGet.command = ["sh", "-c", "mkdir -p \"$1\" && curl -fsSL --max-time 20 --max-filesize 2000000 -o \"$2.new\" \"$3\" && mv \"$2.new\" \"$2\"", "sh", favDir, favGet.job.path, favGet.job.url]
        favGet.running = true
    }
    function favSeen(id, icon) {
        const url = String(icon).replace(/^image:\/\/favicon\//, ""), t = tabbed.find(x => x.id === id)
        if (!t || !/^https?:\/\//.test(url) || t.favUrl === url || favQueue.some(j => j.id === id) || (favGet.job && favGet.job.id === id)) return
        favQueue = favQueue.concat([{ id: id, url: url, path: favDir + "/" + id + "-" + Qt.md5(url).slice(0, 8) }]); favNext()
    }
    // a picture of the person's own for a tab
    Process { id: iconPick; property string id: ""; command: ["latte-ai", "pick"]
              stdout: StdioCollector { onStreamFinished: { const f = this.text.split("\n")[0].trim(); if (f !== "") shell.setTab(iconPick.id, { icon: f }) } } }
    function removeTab(id) { keepTabs(tabbed.filter(t => t.id !== id)); if (tabBeside === id) tabBeside = ""; if (tab === id && page === "web") page = "lensai" }
    readonly property var marks: ({ claude: "claude", gemini: "gemini", chatgpt: "openai", grok: "grok", mistral: "mistral", copilot: "githubcopilot", deepseek: "deepseek", suno: "suno",
                                    "api-anthropic": "claude", "api-openai": "openai", "api-google": "gemini", "api-xai": "grok", "api-mistral": "mistral", "api-deepseek": "deepseek" })
    // a service's own mark on a light disc, as the rings have it; `glyph` where LatteOS has no mark of it
    component Mark: Rectangle { id: mk; property string of; property string glyph: "cloud"; property real size: 40
        width: size; height: size; radius: size / 2; color: "#f5f1ea"
        Image { anchors.centerIn: parent; visible: !!shell.marks[mk.of]; width: mk.size * 0.6; height: width; sourceSize: Qt.size(48, 48); fillMode: Image.PreserveAspectFit
                source: shell.marks[mk.of] ? "file://" + I18n.share + "/goo/ai/" + shell.marks[mk.of] + ".svg" : "" }
        Glyph { anchors.centerIn: parent; visible: !shell.marks[mk.of]; name: mk.glyph; font.pixelSize: mk.size * 0.5; color: "#2a1e17" } }
    // how much of a service's limit is used, 0…1, -1 where it says none: the ring closes as it is spent. The first
    // limit it tells: Claude's 5 hours, or the week on a plan without them (the user, 10. 11.)
    function used(id) {
        const s = (agents.services || []).find(x => x.id === id), l = s ? s.limits || [] : []
        return l.length ? Math.min(1, l[0].used || 0) : -1
    }
    // the agents panel (Omarchy's, MIT): what each service tells of the account, and what was used
    Ask { id: agentsq; onDone: shell.agents = data || ({ services: [], stats: {} }) }
    property var agents: ({ services: [], stats: {}, doers: [], ideas: [] })
    // the helpers (Omarchy's toggles and Setup › Defaults): who does the work, and what can be turned off
    Ask { id: helpersq; onDone: shell.helpers = data || shell.helpers }
    property var helpers: ({ ai: true, agent: "", agents: [], helper: "local", local: "", haiku: [], switches: [], muted: [] })
    Process { id: helperSet; onExited: helpersq.ask(["helpers"]) }
    function setHelper(argv) { helperSet.command = argv; helperSet.running = true }
    // the AI on this computer, as LM Studio offers it: what it can carry, LatteOS's recommended models, any other found
    // on Hugging Face with how each file would fit, the downloads (latte-ai local)
    component LocalAsk: Process {
        id: lq
        property var data: null
        property string buf: ""
        function ask(args) { running = false; command = ["latte-ai", "local"].concat(args); running = true }
        stdout: StdioCollector { onStreamFinished: lq.buf = this.text }
        onExited: { try { lq.data = JSON.parse(lq.buf) } catch (e) { lq.data = null } }
    }
    LocalAsk { id: localq }
    LocalAsk { id: localModels }
    LocalAsk { id: hfFound }
    LocalAsk { id: hfFiles }
    property string hfRepo: ""                 // the model on Hugging Face whose files are open
    property var getting: null                 // the download now: { file, got, total, speed (bytes a second) }
    property real gotAt: 0                     // when the speed was last counted, and how much had come by then
    property real gotWas: 0
    property string dropping: ""               // the download being ended is dropped, not paused: its file
    LocalAsk { id: dlq }                       // the downloads paused or broken off (latte-ai local downloads)
    LocalAsk { id: estq }                      // what a model would take loaded as the open settings say
    Process { id: dropper; onExited: dlq.ask(["downloads"]) }
    function drop(what) { dropper.command = ["latte-ai", "local", "cancel", what]; dropper.running = true }
    Process { id: getter
        stdout: SplitParser { onRead: line => { let m = null; try { m = JSON.parse(line) } catch (e) { return }
            if (!m.total) return
            const now = Date.now(); let speed = shell.getting ? shell.getting.speed || 0 : 0
            if (shell.gotAt === 0 || m.got < shell.gotWas) { shell.gotAt = now; shell.gotWas = m.got }       // the first word, or the next part of a model in parts
            else if (now - shell.gotAt >= 1500) { speed = (m.got - shell.gotWas) * 1000 / (now - shell.gotAt); shell.gotAt = now; shell.gotWas = m.got }
            shell.getting = Object.assign({}, shell.getting, { got: m.got, total: m.total, speed: speed }) } }
        // ended by itself it is done; ended by the person it is paused (its part stays, `get` goes on with it) or dropped
        onExited: { const was = shell.getting; shell.getting = null
                    if (shell.dropping !== "") { shell.drop(shell.dropping); shell.dropping = "" } else dlq.ask(["downloads"])
                    localq.ask(["recommend"]); localModels.ask(["models", "measured"]); if (shell.hfRepo) hfFiles.ask(["files", shell.hfRepo]); who.ask(["providers", "all"]); modelq.ask(["models"]) } }
    function fetch(args, file) { if (getter.running) return; gotAt = 0; gotWas = 0; getting = { file: file, got: 0, total: 0, speed: 0 }; getter.command = ["latte-ai", "local"].concat(args); getter.running = true }
    function size(n) { return n < 1e9 ? Math.round(n / 1e6) + " MB" : gb(n) }
    function openLocal() { page = "local"; localq.ask(["recommend"]); localModels.ask(["models", "measured"]); dlq.ask(["downloads"]); modelq.ask(["models"]) }
    Process { id: localSet; onExited: { localq.ask(["recommend"]); localModels.ask(["models", "measured"]); modelq.ask(["models"]) } }
    function gb(n) { return (n / 1e9).toFixed(n >= 1e10 ? 0 : 1) + " GB" }
    readonly property var fits: ({ gpu: { word: QT_TR_NOOP("Full GPU offload"), color: "#4cc38a" }, partial: { word: QT_TR_NOOP("Partial GPU offload"), color: "#f7c873" },
                                   cpu: { word: QT_TR_NOOP("On the processor"), color: "#7aa7ff" }, "too-big": { word: QT_TR_NOOP("Likely too large for this computer"), color: "#e5484d" } })
    // "Do it for me": the task goes to an agent in a terminal, which plans first and changes nothing before a yes
    Process { id: doer }
    function doIt(task, who) { doer.command = ["latte-ai", "do", task].concat(who ? [who] : []); doer.running = true }
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
    // LatteOS as an MCP server in the agents' own tools (bin/latte-mcp): which of them have it
    property var mcp: ({ agents: [] })
    Process { id: mcpq; command: ["latte-mcp", "status"]
              stdout: StdioCollector { onStreamFinished: { try { shell.mcp = JSON.parse(this.text) } catch (e) {} } } }
    Process { id: mcpSet; onExited: mcpq.running = true }
    readonly property bool mcpOn: shell.mcp.agents.some(a => a.has)
    // what an AI asked to change on this computer and waits for the person's word on (bin/latte-skill): the counter
    property var asks: []
    Process { id: asksq; command: ["latte-skill", "asks"]
              stdout: StdioCollector { onStreamFinished: { try { shell.asks = JSON.parse(this.text) } catch (e) { shell.asks = [] } } } }
    Timer { interval: 1500; repeat: true; running: true; triggeredOnStart: true; onTriggered: if (!asksq.running) asksq.running = true }
    Process { id: asksSay; onExited: asksq.running = true }
    function answer(req, word) { asksSay.command = ["latte-skill", "answer", req, word]; asksSay.running = true; asks = asks.filter(a => a.req !== req) }
    Ask { id: keyq; onDone: shell.keys = data || [] }
    Ask { id: keyer; onDone: { shell.keyError = { id: "", error: "" }; keyq.ask(["keys"]); who.ask(["providers", "all"]); modelq.ask(["models"]) } }
    property var keys: []                      // the services one can bring a key to, and the user's own servers
    Ask { id: modelq; onDone: shell.models = data || [] }
    Ask { id: modeler; onDone: { modelq.ask(["models"]); who.ask(["providers", "all"]) } }
    property var models: []                    // every model of every service, with the user's word on each
    // a key goes to latte-ai on its standard input, never on its command line, where anyone could read it
    property var keyError: ({ id: "", error: "" })      // the key that was not taken, and why: locked (the keyring) · refused
    Process { id: keeper; property string id: ""; property string key: ""; property string said: ""; stdinEnabled: true
              stdout: StdioCollector { onStreamFinished: keeper.said = this.text }
              onStarted: { write(key + "\n"); key = ""; stdinEnabled = false }
              onExited: code => { stdinEnabled = true
                                  let why = ""; if (code !== 0) { try { why = JSON.parse(said).error || "refused" } catch (e) { why = "refused" } }
                                  shell.keyError = { id: why ? id : "", error: why }
                                  keyq.ask(["keys"]); who.ask(["providers", "all"]); modelq.ask(["models"]) } }
    function keep(id, key) { if (key.trim() === "" || keeper.running) return; keeper.id = id; keeper.said = ""; keeper.key = key.trim(); keeper.command = ["latte-ai", "key", id]; keeper.running = true }
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
    function reload() { list.ask(["chats"]); if (open !== "") one.ask(["chat", open]) }
    Ask { id: forget; onDone: { shell.open = ""; shell.chat = null; shell.page = "all"; list.ask(["chats"]) } }
    function choose(id) { open = id; page = "chats"; chat = null; one.ask(["chat", id]) }
    // a command to sign in or out runs in a terminal: the tool asks there what it needs
    function inTerminal(argv) { Quickshell.execDetached(["foot", "-e", "sh", "-c", argv.map(a => "'" + a.replace(/'/g, "'\\''") + "'").join(" ") + "; echo; read -p '" + I18n.tr("Press Enter to close") + "' x"]) }
    Timer { id: later; interval: 2500; onTriggered: svc.ask(["services"]) }
    // an install in its terminal takes a while: the services are asked again while their page is open
    Timer { interval: 10000; repeat: true; running: shell.page === "lensai" && shell.section === "cli"; onTriggered: if (!svc.running) svc.ask(["services"]) }
    Component.onCompleted: {
        list.ask(["chats"]); who.ask(["providers", "all"]); svc.ask(["services"]); keyq.ask(["keys"]); helpersq.ask(["helpers"])      // helpers: whether the AI is on
        if (["all", "chats", "agents", "helpers", "local", "lensai"].indexOf(words[0]) >= 0) page = words[0] === "helpers" ? "agents" : words[0]      // helpers: a part of the agents' page now
        const part = ({ services: "cli", models: "cli", keys: "api", instructions: "instructions", lensai: words[1] || "web" })[words[0]]      // what were pages of their own are parts of the settings
        if (part) openSection(part)
        if (words[0] === "tab" && words[1]) { page = "web"; tab = words[1]; tabBeside = words[2] || "" }      // latte-app aicenter tab claude [chatgpt]: its own page, another beside
        if (page !== "home") agentsq.ask(["agents"])             // the rings of the tabs show what is left
        if (page === "home") lookAround()
        if (page === "local") openLocal()
        if (words[0] && (page === "chats" || (page === "home" && words[0] !== "home"))) choose(words[0])        // a conversation by its id
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
    // as much as LatteOS is glass (Theme.glassLevel: 0 white as on the service's own page … 4); solid where nothing blurs
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
        ask(["send", open !== "" ? open : "new", useProvider, useModel, text, "--from", "lensai"].concat(extra()))
        files = []
    }

    AppWindow {
        title: I18n.tr("LensAI")
        heading: shell.page === "lensai" ? I18n.tr("Settings") : shell.page === "web" ? (shell.tabbed.find(t => t.id === shell.tab) || { name: "" }).name : shell.page === "home" ? I18n.tr("Overview") : shell.page === "all" ? I18n.tr("All conversations") : shell.page === "agents" ? I18n.tr("Agents") : shell.page === "local" ? I18n.tr("Local LLMs") : (shell.chat ? shell.chat.title : I18n.tr("Conversations"))
        implicitWidth: 1120; implicitHeight: 760
        ground: shell.glassy ? "transparent" : Theme.ground
        searchHint: I18n.tr("Find a conversation…")
        onSearched: text => { shell.find = text; if (text !== "" && shell.page !== "all") shell.page = "all" }
        tools: [
            Pill { implicitHeight: 34; icon: "plus"; text: I18n.tr("New conversation"); strong: true; visible: shell.page !== "web" && shell.page !== "lensai"
                   onPressed: { shell.page = "chats"; shell.open = ""; shell.chat = null } },
            // another service's page beside this one, half and half, or this one alone again
            Pill { implicitHeight: 34; icon: "layout-columns"; visible: shell.page === "web" && shell.web; text: I18n.tr("Beside")
                   strong: shell.tabBeside !== ""
                   onPressed: { const p = mapToItem(besideMenu, 0, 0)
                                besideMenu.open(Math.max(8, p.x), 8, shell.tabbed.filter(t => t.id !== shell.tab).map(t => ({ text: t.name, checked: t.id === shell.tabBeside, run: () => shell.tabBeside = t.id }))
                                    .concat([{ line: true }, { text: I18n.tr("This one alone"), icon: "rectangle", enabled: shell.tabBeside !== "", run: () => shell.tabBeside = "" }])) } },
            Pill { implicitHeight: 34; icon: "trash"; danger: true; visible: shell.page === "chats" && shell.open !== ""; text: I18n.tr("Delete")
                   onPressed: forget.ask(["forget", shell.open]) }
        ]
        side: [
            Column { x: 14; y: 14; spacing: 4; width: 222
                Row { x: 6; spacing: 10; height: 40
                    Glyph { name: "sparkles"; font.pixelSize: 24; color: Theme.gold; anchors.verticalCenter: parent.verticalCenter }
                    Label { text: I18n.tr("LensAI"); font.pixelSize: 17; font.weight: 700; anchors.verticalCenter: parent.verticalCenter } }
                Item { width: 1; height: 6 }
                Nav { text: I18n.tr("Overview"); icon: "layout-dashboard"; on: shell.page === "home"; onPressed: { shell.page = "home"; shell.lookAround() } }
                // the services' own pages: a ring each, what is used of its limit round its mark (whole: spent); pressed, its tab
                Flow { x: 6; width: 216; spacing: 6; visible: shell.tabbed.length > 0; topPadding: 4; bottomPadding: 4
                    Repeater { model: shell.tabbed
                        Item { id: ring; required property var modelData; width: 48; height: 48
                            readonly property string tool: shell.usageOf(modelData)       // whose limits and whose work it shows
                            readonly property real share: shell.used(tool)
                            readonly property bool on: shell.page === "web" && shell.tab === modelData.id
                            onShareChanged: arc.requestPaint()
                            // the one whose page is open: a gold disc under it and a gold rim round its picture, seen at a glance
                            Rectangle { anchors.fill: parent; radius: 24; color: ring.on ? Qt.rgba(Theme.gold.r, Theme.gold.g, Theme.gold.b, 0.38) : (ringHit.containsMouse ? Theme.card : "transparent") }
                            Canvas { id: arc; anchors.fill: parent
                                onPaint: { const g = getContext("2d"); g.reset(); g.lineWidth = 3.5; g.lineCap = "round"
                                           g.strokeStyle = Qt.rgba(1, 1, 1, 0.1); g.beginPath(); g.arc(24, 24, 21, 0, 2 * Math.PI); g.stroke()
                                           if (ring.share <= 0) return
                                           g.strokeStyle = shell.colour(ring.tool); g.beginPath(); g.arc(24, 24, 21, -Math.PI / 2, -Math.PI / 2 + 2 * Math.PI * Math.max(0.001, ring.share)); g.stroke() } }
                            Rectangle { anchors.centerIn: parent; width: 30; height: 30; radius: 15; color: "#f5f1ea"; border.width: ring.on ? 2 : 0; border.color: Theme.gold
                                // its picture (shell.iconOf): the page's own icon is there from the last time, before the tab is opened
                                readonly property string own: shell.iconOf(ring.modelData)
                                Image { anchors.centerIn: parent; visible: parent.own !== ""; sourceSize: Qt.size(36, 36)
                                        width: 18; height: 18; fillMode: Image.PreserveAspectFit; source: parent.own }
                                Label { anchors.centerIn: parent; visible: parent.own === ""; text: I18n.tr(ring.modelData.name).charAt(0).toUpperCase(); color: "#2a1e17"; font.weight: 800 } }
                            // gold: its tool in a terminal works or asks; mint: its tab, out of sight, has something new
                            Rectangle { x: 34; y: 4; width: 11; height: 11; radius: 6; border.width: 2; border.color: Theme.pane
                                        readonly property bool fresh: !!(webTabs.item && webTabs.item.news[ring.modelData.id])
                                        visible: shell.busy(ring.tool) || fresh
                                        color: shell.busy(ring.tool) ? Theme.gold : Theme.ok }
                            MouseArea { id: ringHit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: { shell.page = "web"; shell.tab = ring.modelData.id } } } }
                    // another page: LensAI's settings, where the list is
                    Rectangle { width: 48; height: 48; radius: 24; color: tabPlusHit.containsMouse || shell.page === "lensai" ? Theme.card : "transparent"
                                border.width: 1; border.color: Theme.line
                        Glyph { anchors.centerIn: parent; name: "plus"; font.pixelSize: 18; color: Theme.dim }
                        MouseArea { id: tabPlusHit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: shell.openSection("web") } } }
                Nav { text: I18n.tr("All conversations"); icon: "messages"; on: shell.page === "all" || shell.page === "chats"; badge: shell.mine.length
                      onPressed: { shell.page = "all"; list.ask(["chats"]) } }
                Item { width: 1; height: 10 }
                Nav { text: I18n.tr("Agents"); icon: "robot"; on: shell.page === "agents"; onPressed: { shell.page = "agents"; agentsq.ask(["agents"]); helpersq.ask(["helpers"]) } }
                Nav { text: I18n.tr("Local LLMs"); icon: "cpu"; on: shell.page === "local"; onPressed: shell.openLocal() }
                Nav { text: I18n.tr("Settings"); icon: "settings"; on: shell.page === "lensai"; onPressed: shell.openSection(shell.section) }
            }
        ]

        // ── a service's own page, in its tab (ROADMAP 10B.35) ───────────────────────────────────────────────
                Nav { text: I18n.tr("AI Cursor (coming in 2027)"); icon: "pointer"; off: true }      // ROADMAP 10B.34
        Loader { id: webTabs; anchors.fill: parent; active: shell.web; visible: shell.page === "web"
                 source: "aicenter/WebTabs.qml"
                 Binding { target: webTabs.item; property: "current"; value: shell.page === "web" ? shell.tab : ""; when: webTabs.item !== null }
                 Binding { target: webTabs.item; property: "services"; value: shell.tabbed; when: webTabs.item !== null }
                 Binding { target: webTabs.item; property: "beside"; value: shell.page === "web" ? shell.tabBeside : ""; when: webTabs.item !== null } }
        Connections { target: webTabs.item; function onIconsChanged() { for (const id in webTabs.item.icons) shell.favSeen(id, webTabs.item.icons[id]) } }
        Menu { id: besideMenu }
        // without a web engine in this Quickshell: the page in the browser
        Column { anchors.centerIn: parent; spacing: 12; width: 420; visible: shell.page === "web" && !shell.web
            Glyph { name: "world"; font.pixelSize: 44; color: Theme.gold; anchors.horizontalCenter: parent.horizontalCenter }
            Label { width: parent.width; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap; color: Theme.dim
                    text: I18n.tr("The services' pages open here only in LensAI's own Quickshell, which this system has not got.") }
            Pill { anchors.horizontalCenter: parent.horizontalCenter; icon: "external-link"; text: I18n.tr("Open in the browser"); strong: true
                   onPressed: { const p = shell.tabbed.find(x => x.id === shell.tab); if (p) Qt.openUrlExternally(p.web) } } }

        // ── the counter: a change an AI asks for, over whatever page is open; nothing is done before the person's yes ──
        Column { z: 40; anchors.top: parent.top; anchors.topMargin: 12; anchors.horizontalCenter: parent.horizontalCenter; spacing: 8; width: Math.min(parent.width - 48, 620)
            Repeater { model: shell.asks
                Rectangle { id: ak; required property var modelData; width: parent.width; height: akCol.implicitHeight + 28; radius: 18; color: Theme.raised; border.width: 2; border.color: Theme.gold
                    MouseArea { anchors.fill: parent }
                    Column { id: akCol; x: 18; y: 14; width: parent.width - 36 - akBtns.width - 12; spacing: 4
                        Label { text: I18n.tr("{who} asks to change this computer", { who: ak.modelData.by }); color: Theme.gold; font.pixelSize: 12; font.weight: 700 }
                        Label { width: parent.width; wrapMode: Text.WordWrap; text: ak.modelData.label; font.pixelSize: 16; font.weight: 800 }
                        Label { width: parent.width; wrapMode: Text.WordWrap; color: Theme.dim; font.pixelSize: 13
                                text: ak.modelData.what + ": " + (ak.modelData.from ? ak.modelData.from + " → " : "") + ak.modelData.to } }
                    Row { id: akBtns; anchors.right: parent.right; anchors.rightMargin: 14; anchors.verticalCenter: parent.verticalCenter; spacing: 8
                        Pill { implicitHeight: 36; icon: "x"; text: I18n.tr("Refuse"); onPressed: shell.answer(ak.modelData.req, "no") }
                        Pill { implicitHeight: 36; icon: "check"; strong: true; text: I18n.tr("Allow"); onPressed: shell.answer(ak.modelData.req, "yes") } } } } }

        // ── the AI turned off (Settings › AI): LensAI asks nobody, and says so over whatever page it is on ─────
        Rectangle { anchors.fill: parent; z: 50; visible: !shell.helpers.ai; color: Theme.ground
            MouseArea { anchors.fill: parent; hoverEnabled: true }
            Column { anchors.centerIn: parent; spacing: 12; width: 440
                Glyph { name: "sparkles"; font.pixelSize: 44; color: Theme.dim; anchors.horizontalCenter: parent.horizontalCenter }
                Label { text: I18n.tr("The AI of LatteOS is turned off"); font.pixelSize: 22; font.weight: 800; anchors.horizontalCenter: parent.horizontalCenter }
                Label { width: parent.width; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap; color: Theme.dim
                        text: I18n.tr("LensAI asks no AI and nothing leaves this computer until it is turned on in Settings › AI.") }
                Pill { anchors.horizontalCenter: parent.horizontalCenter; icon: "settings"; strong: true; text: I18n.tr("Open Settings › AI")
                       onPressed: Quickshell.execDetached(["latte-app", "settings", "ai"]) } } }

        // ── every conversation, LensGoo's and LensShore's too, under the service that answered (the user, 10. 11.) ──
        Scroll {
            id: allPage
            visible: shell.page === "all"
            Label { visible: shell.shown.length === 0; width: allPage.room; wrapMode: Text.WordWrap; color: Theme.dim
                    text: I18n.tr("No conversation yet. LensGoo's AI tab (Win+C) keeps its conversations here too.") }
            Repeater { model: shell.groups
                Column { id: grp; required property var modelData; width: allPage.room; spacing: 6
                    Row { spacing: 10; height: 30
                        Rectangle { width: 10; height: 10; radius: 5; color: shell.colour(grp.modelData.id); anchors.verticalCenter: parent.verticalCenter }
                        Label { text: shell.nameOf(grp.modelData.id); font.pixelSize: 16; font.weight: 700; anchors.verticalCenter: parent.verticalCenter }
                        Kind { kind: shell.kindOf(grp.modelData.id); anchors.verticalCenter: parent.verticalCenter }
                        Label { text: grp.modelData.chats.length; color: Theme.dim; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter } }
                    Repeater { model: grp.modelData.chats
                        Rectangle { id: cr; required property var modelData; width: allPage.room; height: 48; radius: 14; color: crHit.containsMouse ? Theme.raised : Theme.card
                            Label { x: 16; width: parent.width - 340; anchors.verticalCenter: parent.verticalCenter; text: cr.modelData.title; elide: Text.ElideRight; font.weight: 600 }
                            Label { anchors.right: parent.right; anchors.rightMargin: 16; width: 300; horizontalAlignment: Text.AlignRight; elide: Text.ElideLeft; anchors.verticalCenter: parent.verticalCenter; color: Theme.dim; font.pixelSize: 12
                                    text: [shell.places[cr.modelData.from] || cr.modelData.from || "", shell.modelName(cr.modelData.provider, cr.modelData.model), shell.when(cr.modelData.updated)].filter(x => x !== "").join("  ·  ") }
                            MouseArea { id: crHit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: shell.choose(cr.modelData.id) } } } } }
        }

        // ── a conversation: its messages, and the line to go on with it ─────────────────────────────────────
        Item {
            id: chatPane
            anchors.fill: parent
            visible: shell.page === "chats"
            Rectangle { anchors.fill: parent; anchors.margins: 8; radius: 16; color: shell.look.page; opacity: shell.glassy ? [1, 0.9, 0.8, 0.68, 0.55][Theme.glassLevel] : 1 }
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
                            text: shell.providers.length ? I18n.tr("Write below. Choose who answers with the button above the line.") : I18n.tr("No AI is ready on this computer: see Settings.") } } }

            // who answers: LatteOS's own switch, the one part that is the same for every service (LensGoo has it at its foot)
            Rectangle { id: whoPill; x: box.x; y: box.y - 42; height: 32; radius: 16; width: whoRow.implicitWidth + 28; visible: shell.providers.length > 0
                color: Qt.rgba(0.97, 0.78, 0.45, whoHit.containsMouse || shell.menuAt === "who" ? 0.3 : 0.18)
                Row { id: whoRow; x: 14; spacing: 8; anchors.verticalCenter: parent.verticalCenter
                    Text { text: shell.nameOf(shell.useProvider) + " · " + (shell.useM ? shell.useM.name : ""); color: shell.style === "own" ? Theme.gold : "#8a5a14"; font.family: Theme.font; font.pixelSize: 13; font.weight: Font.Bold }
                    Kind { kind: shell.kindOf(shell.useProvider); anchors.verticalCenter: parent.verticalCenter }
                    Glyph { name: "chevron-down"; font.pixelSize: 14; color: shell.style === "own" ? Theme.gold : "#8a5a14"; anchors.verticalCenter: parent.verticalCenter } }
                MouseArea { id: whoHit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: shell.openMenu("who") } }
            // where the question goes: it stays here, or it leaves the computer for the service (ROADMAP 10B.29)
            Row { x: whoPill.x + whoPill.width + 12; y: whoPill.y; height: whoPill.height; spacing: 6; visible: whoPill.visible && !!shell.useP
                readonly property bool here: !!shell.useP && shell.useP.local === true
                readonly property color ink: shell.style === "own" ? Theme.dim : shell.look.dim || "#8b8778"
                Glyph { name: parent.here ? "device-desktop" : "cloud"; font.pixelSize: 15; color: parent.ink; anchors.verticalCenter: parent.verticalCenter }
                Text { text: parent.here ? I18n.tr("Stays on this computer") : I18n.tr("The question and what is attached go to {n}", { n: shell.nameOf(shell.useProvider) })
                       color: parent.ink; font.family: Theme.font; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter } }

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
                            Kind { kind: r.modelData.kind || ""; x: nameText.x + Math.min(nameText.contentWidth, nameText.width) + 8; y: r.mid - 5 }
                            Text { id: nameText; visible: !r.modelData.note; x: r.nx; y: r.mid - height / 2; width: (sheet.hintX > 0 ? sheet.hintX : r.width - 34 - (keyText.text ? keyText.implicitWidth + 8 : 0)) - r.nx - 8; elide: Text.ElideRight
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
                rows: shell.menuAt === "who" ? shell.providers.map(p => ({ name: p.name, kind: shell.kindOf(p.id), key: p.id === shell.useProvider && shell.useM ? shell.useM.name : p.models[0].name, "do": { provider: p.id, model: p.id === shell.useProvider && shell.useM ? shell.useM.id : p.models[0].id } }))
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

        // ── the dashboard: a lens in the middle with the Cafe in it, what LensAI knows around it (ROADMAP 10B.42) ──────
        Flickable {
            id: home
            anchors.fill: parent
            visible: shell.page === "home"
            contentHeight: homeCol.implicitHeight + 40; clip: true; boundsBehavior: Flickable.StopAtBounds
            readonly property real side: Math.max(220, (width - 56 - 340 - 32) / 2)
            // the stage's clock, as dioramas' scenes breathe: the lens floats a little and its light drifts; still where the
            // card has no power to spare (the lower tiers)
            property real t: 0
            NumberAnimation on t { from: 0; to: 6.2832; duration: 14000; loops: Animation.Infinite; running: home.visible && Theme.blurred }
            component Card: Rectangle {
                property string title
                property string icon
                default property alias inner: body.data
                width: home.side; height: body.implicitHeight + 52; radius: 16; color: Qt.rgba(Theme.card.r, Theme.card.g, Theme.card.b, 0.72)
                border.width: 1; border.color: Qt.rgba(Theme.gold.r, Theme.gold.g, Theme.gold.b, 0.18)
                Row { x: 16; y: 14; spacing: 8
                    Glyph { name: parent.parent.icon; font.pixelSize: 15; color: Theme.gold; anchors.verticalCenter: parent.verticalCenter }
                    Label { text: parent.parent.title; font.weight: 700; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter } }
                Column { id: body; x: 16; y: 40; width: parent.width - 32; spacing: 8 }
            }
            // how much of a service's limit is used, as a ring: whole when it is spent
            component Ring: Item {
                property real rest: 0                  // 0…1, the share used
                property color tint: Theme.gold
                width: 46; height: 46
                onRestChanged: arc.requestPaint()
                Canvas { id: arc; anchors.fill: parent
                    onPaint: { const g = getContext("2d"); g.reset(); g.lineWidth = 5; g.lineCap = "round"
                               g.strokeStyle = Qt.rgba(1, 1, 1, 0.08); g.beginPath(); g.arc(23, 23, 19, 0, 2 * Math.PI); g.stroke()
                               if (parent.rest <= 0) return
                               g.strokeStyle = parent.tint; g.beginPath(); g.arc(23, 23, 19, -Math.PI / 2, -Math.PI / 2 + 2 * Math.PI * parent.rest); g.stroke() } }
                Label { anchors.centerIn: parent; text: Math.round(parent.rest * 100); font.pixelSize: 11; font.weight: 800 } }
            // the stage: a cone of warm light onto the lens, a glow round it, its soft shadow, the edges dark, a fine grain
            ShaderEffect {
                width: home.width; height: Math.max(home.height, homeCol.implicitHeight + 40); visible: GraphicsInfo.api !== GraphicsInfo.Software
                property point spot: Qt.point((lensBox.x + homeCol.x + lensBox.width / 2) / width, (lensBox.y + homeCol.y + lensBox.height / 2) / height)
                property real ratio: width / Math.max(1, height)
                property real time: home.t * 2.2
                property color warm: Theme.gold
                property point ground: Qt.point(spot.x, (lensBox.y + homeCol.y + lensBox.height * 0.96) / height)
                property point groundSize: Qt.point(lensBox.width * 0.42 / width, lensBox.height * 0.07 / height)
                fragmentShader: Qt.resolvedUrl("common/shaders/stage.frag.qsb")
            }
            Column { id: homeCol; x: 28; y: 20; width: home.width - 56; spacing: 16
                Row { spacing: 16
                    Column { spacing: 16
                        Card { title: I18n.tr("Used"); icon: "gauge"
                            Flow { width: parent.width; spacing: 12
                                Repeater { model: (shell.agents.services || []).filter(s => (s.limits || []).length > 0)
                                    Column { required property var modelData; spacing: 4; width: 62
                                        readonly property var lim: modelData.limits[0]         // as the rings of the tabs: Claude's 5 hours, else the week
                                        Ring { rest: Math.min(1, parent.lim.used || 0); tint: shell.colour(parent.modelData.id); anchors.horizontalCenter: parent.horizontalCenter }
                                        Label { text: I18n.tr(parent.modelData.name); font.pixelSize: 11; width: parent.width; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight }
                                        Label { text: I18n.tr(parent.lim.label || ""); color: Theme.dim; font.pixelSize: 10; width: parent.width; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight } } } }
                            Label { visible: !(shell.agents.services || []).some(s => (s.limits || []).length > 0); text: I18n.tr("No service says its limits."); color: Theme.dim; font.pixelSize: 12 } }
                        Card { title: I18n.tr("Local LLMs"); icon: "cpu"
                            Label { text: I18n.tr("{n} models on this computer", { n: (localModels.data || []).length }); color: Theme.dim; font.pixelSize: 12 }
                            Pill { text: I18n.tr("Open"); icon: "chevron-right"; onPressed: shell.openLocal() } } }
                    // the lens: a GIF of the user's own in it, LatteOS's coffee until then; a press shows the agents
                    Item { id: lensBox; width: 340; height: 340
                        Lens { anchors.fill: parent; anchors.margins: 6; anchors.topMargin: 6 - 5 * Math.sin(home.t); anchors.bottomMargin: 6 + 5 * Math.sin(home.t)
                               zoom: 1.25; turn: 0.35 * Math.sin(home.t * 0.5)
                               source: "file://" + Quickshell.env("HOME") + "/.local/share/latteos/cafe.gif"
                               fallback: "file://" + (Quickshell.env("LATTE_SHARE") || "/usr/share/latteos") + "/lensai/cafe.jpg" }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { shell.page = "agents"; helpersq.ask(["helpers"]) } } }
                    Column { spacing: 16
                        Card { title: I18n.tr("Agents"); icon: "robot"
                            Repeater { model: wmAgents.list
                                Row { required property var modelData; spacing: 8; width: parent.width
                                    Rectangle { width: 9; height: 9; radius: 5; anchors.verticalCenter: parent.verticalCenter
                                                color: modelData.state === "asking" ? Theme.gold : modelData.state === "working" ? Theme.ok : Theme.faint }
                                    Label { text: (modelData.agent || "") + " · " + String(modelData.folder || "").replace(Quickshell.env("HOME"), "~"); width: parent.width - 20; elide: Text.ElideRight; font.pixelSize: 12 } } }
                            Label { visible: wmAgents.list.length === 0; width: parent.width; wrapMode: Text.WordWrap; text: I18n.tr("No agent at work in a terminal."); color: Theme.dim; font.pixelSize: 12 } }
                        Card { title: I18n.tr("Tokens"); icon: "robot"
                            Label { width: parent.width; wrapMode: Text.WordWrap; text: shell.statLines[shell.turn % shell.statLines.length]; font.pixelSize: 17; font.weight: 800 }
                            Label { width: parent.width; wrapMode: Text.WordWrap; color: Theme.dim; font.pixelSize: 11
                                    text: I18n.tr("Counted from Claude Code's own records on this computer, LensAI's questions included.") } } } }
                // "Do it for me" (latte-ai do): a task for the agent, in a terminal, a plan first
                Rectangle { width: parent.width; height: 58; radius: 16; color: Theme.card; border.width: 1; border.color: Theme.line
                    Glyph { x: 18; name: "sparkles"; font.pixelSize: 18; color: Theme.gold; anchors.verticalCenter: parent.verticalCenter }
                    TextInput { id: task; x: 48; width: parent.width - 200; anchors.verticalCenter: parent.verticalCenter; color: Theme.cream; font.family: Theme.font; font.pixelSize: 14; clip: true
                                onAccepted: if (text.trim() !== "") { shell.doIt(text.trim(), ""); text = "" } }
                    Label { x: 48; visible: task.text === ""; text: I18n.tr("Do it for me: what should the agent do?"); color: Theme.faint; anchors.verticalCenter: parent.verticalCenter }
                    Pill { anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter; strong: task.text.trim() !== ""; icon: "player-play"; text: I18n.tr("Start")
                           onPressed: if (task.text.trim() !== "") { shell.doIt(task.text.trim(), ""); task.text = "" } } }
                Flow { width: parent.width; spacing: 8
                    Repeater { model: shell.agents.ideas || []
                        Pill { required property var modelData; implicitHeight: 30; icon: "sparkles"; text: I18n.tr(modelData); onPressed: shell.doIt(I18n.tr(modelData), "") } } } }
        }

        // ── the agents: every subscription on one page, limits first (Omarchy's agents panel, MIT) ──────────────
        Flickable {
            anchors.fill: parent
            visible: shell.page === "agents"
            contentHeight: agentCol.implicitHeight + 48; clip: true; boundsBehavior: Flickable.StopAtBounds
            Column { id: agentCol; x: 28; y: 24; width: Math.min(parent.width - 56, 760); spacing: 14
                // what the counts add up to, one line at a time, as Omarchy's hero has it
                Rectangle { width: parent.width; height: 96; radius: 16; color: Theme.card; border.width: 1; border.color: Theme.line
                    Glyph { x: 22; anchors.verticalCenter: parent.verticalCenter; name: "robot"; font.pixelSize: 40; color: Theme.gold }
                    Column { x: 80; anchors.verticalCenter: parent.verticalCenter; spacing: 4; width: parent.width - 140
                        Label { text: shell.statLines[shell.turn % shell.statLines.length]; font.pixelSize: 20; font.weight: 800 }
                        Label { text: I18n.tr("Counted from Claude Code's own records on this computer, LensAI's questions included."); color: Theme.dim; font.pixelSize: 12; width: parent.width; wrapMode: Text.WordWrap } }
                    Pill { anchors.right: parent.right; anchors.rightMargin: 16; anchors.verticalCenter: parent.verticalCenter; implicitHeight: 34; icon: "refresh"; text: ""
                           busy: agentsq.running; onPressed: agentsq.ask(["agents"]) } }
                // the agent: crashes and "Do it for me" go to it; LatteOS picks none for the user (Omarchy's default agent)
                Rectangle { width: agentCol.width; height: agentBox.implicitHeight + 32; radius: 16; color: Theme.card; border.width: 1; border.color: Theme.line
                    Column { id: agentBox; x: 18; y: 16; width: parent.width - 36; spacing: 10
                        Row { spacing: 10
                            Glyph { name: "robot"; color: Theme.gold; font.pixelSize: 20; anchors.verticalCenter: parent.verticalCenter }
                            Label { text: I18n.tr("Your agent"); font.pixelSize: 16; font.weight: 800; anchors.verticalCenter: parent.verticalCenter } }
                        Label { width: parent.width; wrapMode: Text.WordWrap; color: Theme.dim; font.pixelSize: 13
                                text: shell.helpers.agent === "" ? I18n.tr("None is chosen: LatteOS does not choose for you. Crashes and “Do it for me” go to the one you choose.")
                                                                 : I18n.tr("Crashes and “Do it for me” go to it. It plans first and changes nothing before your yes.") }
                        Flow { width: parent.width; spacing: 8
                            Repeater { model: shell.helpers.agents
                                Pill { required property var modelData; implicitHeight: 32; text: modelData.installed ? modelData.name : I18n.tr("{n} (not installed)", { n: modelData.name })
                                       strong: modelData.id === shell.helpers.agent; icon: modelData.id === shell.helpers.agent ? "check" : (modelData.installed ? "" : "download"); opacity: modelData.installed ? 1 : 0.6
                                       onPressed: { if (modelData.installed) shell.setHelper(["latte-ai", "doer", modelData.id]); else shell.openSection("cli") } } } } } }
                // "Do it for me": what the agent should do, and tasks to start from
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
                        Flow { width: parent.width; spacing: 8
                            Repeater { model: shell.agents.ideas || []
                                Pill { required property var modelData; implicitHeight: 30; icon: "sparkles"; text: I18n.tr(modelData); onPressed: shell.doIt(I18n.tr(modelData), "") } } } } }
                // one section per service: its mark, name and plan, then a line per limit window
                Repeater { model: shell.agents.services || []
                    Rectangle { id: sec; required property var modelData; width: agentCol.width; height: secCol.implicitHeight + 32; radius: 16; color: Theme.card; border.width: 1; border.color: Theme.line
                        readonly property string mark: ({ claude: "claude", gemini: "gemini", chatgpt: "openai", grok: "grok", mistral: "mistral", copilot: "githubcopilot" })[modelData.id] || ""
                // the agents in this session's terminals, as pleamar-wm tells it (`pleamar-wm agents`), read only
                Label { text: I18n.tr("IN THE TERMINALS"); color: Theme.faint; font.pixelSize: 11; font.weight: 700; font.letterSpacing: 0.8 }
                Repeater { model: wmAgents.list
                    Rectangle { id: ag; required property var modelData; width: agentCol.width; height: 58; radius: 18; color: Theme.card
                        Rectangle { x: 18; width: 12; height: 12; radius: 6; anchors.verticalCenter: parent.verticalCenter
                                    color: ag.modelData.state === "asking" ? Theme.gold : ag.modelData.state === "working" ? Theme.ok : Theme.faint }
                        Column { x: 44; width: parent.width - 220; anchors.verticalCenter: parent.verticalCenter; spacing: 2
                            Label { text: ag.modelData.agent || ""; font.weight: 700 }
                            Label { text: String(ag.modelData.folder || "").replace(Quickshell.env("HOME"), "~"); color: Theme.dim; font.pixelSize: 12; width: parent.width; elide: Text.ElideMiddle } }
                        Label { anchors.right: parent.right; anchors.rightMargin: 18; anchors.verticalCenter: parent.verticalCenter; font.pixelSize: 13; font.weight: 700
                                color: ag.modelData.state === "asking" ? Theme.gold : Theme.dim
                                text: ag.modelData.state === "asking" ? I18n.tr("waits for you") : ag.modelData.state === "working" ? I18n.tr("works") : I18n.tr("ready") } } }
                Label { visible: wmAgents.list.length === 0; text: I18n.tr("No agent at work in a terminal."); color: Theme.dim }
                        Column { id: secCol; x: 18; y: 16; width: parent.width - 36; spacing: 10
                            Row { spacing: 12; height: 32
                                Rectangle { width: 32; height: 32; radius: 9; color: "#f5f1ea"; anchors.verticalCenter: parent.verticalCenter
                                    Image { anchors.centerIn: parent; visible: sec.mark !== ""; source: sec.mark ? "file://" + I18n.share + "/goo/ai/" + sec.mark + ".svg" : ""; sourceSize: Qt.size(22, 22) } }
                                Label { text: I18n.tr(sec.modelData.name); font.pixelSize: 16; font.weight: 800; anchors.verticalCenter: parent.verticalCenter }
                                Kind { kind: "cli"; anchors.verticalCenter: parent.verticalCenter }
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
                        text: I18n.tr("No AI service is installed: see Settings.") }
                // the helpers (Omarchy's toggles, manual 13 and 17, MIT): who reads a sentence, and each helper as a switch;
                // off, only the offer goes, the thing itself stays at hand
                // who reads a sentence: this computer, unless the user chooses Haiku (Omarchy's Defaults, a backend to pick)
                Rectangle { width: agentCol.width; height: whoBox.implicitHeight + 32; radius: 16; color: Theme.card; border.width: 1; border.color: Theme.line
                    Column { id: whoBox; x: 18; y: 16; width: parent.width - 36; spacing: 12
                        Row { spacing: 10
                            Glyph { name: "bolt"; color: Theme.gold; font.pixelSize: 20; anchors.verticalCenter: parent.verticalCenter }
                            Label { text: I18n.tr("Small tasks"); font.pixelSize: 16; font.weight: 800; anchors.verticalCenter: parent.verticalCenter } }
                        Label { width: parent.width; wrapMode: Text.WordWrap; color: Theme.dim; font.pixelSize: 13
                                text: I18n.tr("A sentence to read, a date to find: what the rules of LatteOS do not manage. What it read is always shown before anything is done.") }
                        Row { spacing: 12; width: parent.width
                            Repeater { model: [
                                    { id: "local", name: QT_TR_NOOP("On this computer"), glyph: "device-desktop", can: shell.helpers.local !== "",
                                      how: shell.helpers.local !== "" ? shell.helpers.local : QT_TR_NOOP("No model yet: choose one in Local LLMs"), note: QT_TR_NOOP("Nothing leaves this computer.") },
                                    { id: "haiku", name: "Claude Haiku", glyph: "cloud", can: shell.helpers.haiku.length > 0,
                                      how: shell.helpers.haiku.indexOf("key") >= 0 ? QT_TR_NOOP("With your key: a second or two") : shell.helpers.haiku.indexOf("claude") >= 0 ? QT_TR_NOOP("Through Claude Code: some ten seconds") : QT_TR_NOOP("Needs Claude Code or a key (Settings)"),
                                      note: QT_TR_NOOP("Faster and surer; the sentence goes to Anthropic.") } ]
                                Rectangle { id: tile; required property var modelData; width: (whoBox.width - 12) / 2; height: 96; radius: 14
                                    readonly property bool picked: shell.helpers.helper === modelData.id
                                    color: picked ? Qt.rgba(Theme.gold.r, Theme.gold.g, Theme.gold.b, 0.12) : (tileHit.containsMouse ? Theme.raised : "transparent")
                                    border.width: picked ? 2 : 1; border.color: picked ? Theme.gold : Theme.line; opacity: modelData.can || picked ? 1 : 0.55
                                    Glyph { x: 14; y: 14; name: tile.modelData.glyph; color: tile.picked ? Theme.gold : Theme.dim; font.pixelSize: 20 }
                                    Glyph { anchors.right: parent.right; anchors.rightMargin: 14; y: 14; visible: tile.picked; name: "circle-check"; color: Theme.gold; font.pixelSize: 18 }
                                    Column { x: 44; y: 12; width: parent.width - 80; spacing: 3
                                        Label { text: I18n.tr(tile.modelData.name); font.weight: 800 }
                                        Label { width: parent.width; elide: Text.ElideRight; color: Theme.dim; font.pixelSize: 12; text: I18n.tr(tile.modelData.how) }
                                        Label { width: parent.width; wrapMode: Text.WordWrap; color: tile.modelData.id === "haiku" ? Theme.gold : Theme.ok; font.pixelSize: 12; text: I18n.tr(tile.modelData.note) } }
                                    MouseArea { id: tileHit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: { if (tile.modelData.can) shell.setHelper(["latte-ai", "helper", tile.modelData.id])
                                                     else if (tile.modelData.id === "local") shell.openLocal()
                                                     else shell.openSection("cli") } } } } } } }
                Label { text: I18n.tr("WHAT HELPS"); color: Theme.faint; font.pixelSize: 11; font.weight: 700; font.letterSpacing: 0.8 }
                Label { width: parent.width; wrapMode: Text.WordWrap; color: Theme.dim
                        text: I18n.tr("Small agents that help LatteOS. Each one can be turned off: then it stops offering itself, and what it did can still be asked for by hand.") }
                Repeater { model: shell.helpers.switches
                    Rectangle { id: sw; required property var modelData; width: agentCol.width; height: swCol.implicitHeight + 32; radius: 16; color: Theme.card; border.width: 1; border.color: Theme.line
                        Glyph { x: 18; y: 18; name: sw.modelData.glyph; color: sw.modelData.on ? Theme.gold : Theme.faint; font.pixelSize: 20 }
                        Column { id: swCol; x: 52; y: 16; width: parent.width - 52 - 90; spacing: 6
                            Label { text: I18n.tr(sw.modelData.name); font.pixelSize: 15; font.weight: 800 }
                            Label { width: parent.width; wrapMode: Text.WordWrap; color: Theme.dim; font.pixelSize: 13; text: I18n.tr(sw.modelData.desc) }
                            Label { visible: sw.modelData.id === "crash-capture" && sw.modelData.on && shell.helpers.agent === ""; width: parent.width; wrapMode: Text.WordWrap; color: Theme.gold; font.pixelSize: 12
                                    text: I18n.tr("It waits for your agent: choose one above.") }
                            // a crash: the programs it is not told for (GuardCorgi's “Not about this program”), each back with a press
                            Flow { visible: sw.modelData.id === "crash-capture" && shell.helpers.muted.length > 0; width: parent.width; spacing: 8
                                Label { text: I18n.tr("Not told for:"); color: Theme.dim; font.pixelSize: 12; height: 28; verticalAlignment: Text.AlignVCenter }
                                Repeater { model: sw.modelData.id === "crash-capture" ? shell.helpers.muted : []
                                    Pill { required property var modelData; implicitHeight: 28; icon: "x"; text: modelData
                                           onPressed: shell.setHelper(["latte-guardcorgi", "quiet", modelData, "off"]) } } } }
                        Rectangle { width: 46; height: 26; radius: 13; color: sw.modelData.on ? Theme.gold : Theme.raised; anchors.right: parent.right; anchors.rightMargin: 18; y: 18
                            Rectangle { width: 20; height: 20; radius: 10; y: 3; x: sw.modelData.on ? 23 : 3; color: sw.modelData.on ? Theme.inkOnGold : Theme.dim }
                            MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor
                                        onClicked: shell.setHelper(["latte-ai", "toggle", sw.modelData.id, sw.modelData.on ? "off" : "on"]) } } } } } }

        // ── the models on this computer, as LM Studio has them: Discover (a search, its results on the left and the chosen
        // model on the right with its download options and its card), My Models (the downloads too, and how each model
        // is loaded and what memory that takes), Runtime ─────
        Item {
            id: localPage
            anchors.fill: parent
            visible: shell.page === "local"
            property string tab: shell.words[0] === "local" && ["mine", "runtime"].indexOf(shell.words[1]) >= 0 ? shell.words[1] : "discover"      // discover · mine · runtime
            property string sort: "best"
            property string query: ""
            property var picked: null                  // the model open on the right
            property string variant: ""                // its file chosen to download
            readonly property var rec: localq.data || ({ hardware: { gpus: [] }, models: [] })
            readonly property var picks: (rec.models || []).map(m => ({ repo: m.repo, name: m.name, author: m.repo.split("/")[0], params: (/(\d+(?:\.\d+)?)B/.exec(m.name) || ["", ""])[1] ? (/(\d+(?:\.\d+)?)B/.exec(m.name)[1] + "B") : "",
                                                        good: m.good, pick: true, best: m.id === rec.best, fast: m.id === rec.fast }))
            readonly property var listed: query === "" ? picks : (hfFound.data || []).map(m => Object.assign({ pick: picks.some(p => p.repo === m.repo) }, m))
            function open(m) { picked = m; variant = ""; hfFiles.data = null; hfFiles.ask(["files", m.repo]); readmeq.ask(["readme", m.repo]) }
            function search() { query = searchField.text.trim(); picked = null; if (query !== "") hfFound.ask(["search", query, sort]) }
            readonly property var chosen: (hfFiles.data || []).find(f => f.file === variant) || (hfFiles.data || []).find(f => f.recommended) || null
            function ago(d) { if (!d) return ""; const days = Math.floor((Date.now() - new Date(d)) / 86400000); return days < 1 ? I18n.tr("today") : days < 31 ? I18n.tr("{n} days ago", { n: days }) : days < 365 ? I18n.tr("{n} months ago", { n: Math.floor(days / 30) }) : I18n.tr("{n} years ago", { n: Math.floor(days / 365) }) }
            function count(n) { return n >= 1e6 ? (n / 1e6).toFixed(1) + "M" : n >= 1e3 ? Math.round(n / 1e3) + "k" : String(n || 0) }
            LocalAsk { id: readmeq }

            component FitChip: Rectangle { property string fit; height: 22; radius: 11; width: fitRow.implicitWidth + 16
                readonly property var f: shell.fits[fit] || shell.fits.cpu
                color: Qt.rgba(Qt.color(f.color).r, Qt.color(f.color).g, Qt.color(f.color).b, 0.14)
                Row { id: fitRow; anchors.centerIn: parent; spacing: 5
                    Glyph { name: parent.parent.fit === "gpu" ? "rocket" : parent.parent.fit === "too-big" ? "alert-triangle" : parent.parent.fit === "partial" ? "bolt" : "cpu"; font.pixelSize: 12; color: parent.parent.f.color; anchors.verticalCenter: parent.verticalCenter }
                    Label { text: I18n.tr(parent.parent.f.word); color: parent.parent.f.color; font.pixelSize: 11; font.weight: 700 } } }
            component Tag: Rectangle { property string word; property color tint: Theme.dim; visible: word !== ""; height: 20; radius: 6; width: tagText.implicitWidth + 12; color: Qt.rgba(Qt.color(tint).r, Qt.color(tint).g, Qt.color(tint).b, 0.14)
                Label { id: tagText; anchors.centerIn: parent; text: parent.word; color: parent.tint; font.pixelSize: 11; font.weight: 700 } }

            // the tabs, as LM Studio's left rail has them
            Row { id: localTabs; x: 22; y: 16; spacing: 8
                Repeater { model: [{ id: "discover", name: QT_TR_NOOP("Discover"), icon: "search" }, { id: "mine", name: QT_TR_NOOP("My Models"), icon: "folder" }, { id: "runtime", name: QT_TR_NOOP("Runtime"), icon: "cpu" }]
                    Pill { required property var modelData; implicitHeight: 34; icon: modelData.icon; strong: localPage.tab === modelData.id; onPressed: localPage.tab = modelData.id
                           text: I18n.tr(modelData.name) + (modelData.id === "mine" && (shell.getting || (dlq.data || []).length) ? "  ↓" : "") } } }

            // ── Discover ──
            Item {
                visible: localPage.tab === "discover"
                anchors.fill: parent; anchors.topMargin: 62
                Row { x: 22; spacing: 10
                    Field { id: searchField; width: Math.min(460, localPage.width * 0.42); icon: "search"; hint: I18n.tr("Search models on Hugging Face…"); onAccepted: localPage.search() }
                    Repeater { model: [{ id: "best", name: QT_TR_NOOP("Best match") }, { id: "downloads", name: QT_TR_NOOP("Most downloads") }, { id: "updated", name: QT_TR_NOOP("Recently updated") }, { id: "likes", name: QT_TR_NOOP("Most liked") }]
                        Pill { required property var modelData; implicitHeight: 32; text: I18n.tr(modelData.name); strong: localPage.sort === modelData.id; anchors.verticalCenter: parent.verticalCenter
                               onPressed: { localPage.sort = modelData.id; if (localPage.query !== "") hfFound.ask(["search", localPage.query, modelData.id]) } } } }
                // the list: LatteOS's picks while nothing is searched (LM Studio's Staff Picks), else what was found
                Label { id: listHead; x: 22; y: 50; text: localPage.query === "" ? I18n.tr("LatteOS picks for this computer") : I18n.tr("{n} models", { n: localPage.listed.length }); color: Theme.dim; font.pixelSize: 12; font.weight: 700 }
                ListView {
                    id: found
                    x: 16; y: 72; width: Math.min(440, parent.width * 0.42); height: parent.height - 80; clip: true; spacing: 6
                    model: localPage.listed
                    boundsBehavior: Flickable.StopAtBounds
                    delegate: Rectangle { id: card; required property var modelData; width: found.width; height: 74; radius: 12
                        readonly property bool on: !!localPage.picked && localPage.picked.repo === modelData.repo
                        color: on ? Theme.raised : (cardHit.containsMouse ? Theme.card : "transparent"); border.width: on ? 1 : 0; border.color: Theme.gold
                        Rectangle { x: 12; y: 12; width: 34; height: 34; radius: 17; color: Qt.hsla((card.modelData.author.charCodeAt(0) * 37 % 360) / 360, 0.45, 0.45, 1)
                            Label { anchors.centerIn: parent; text: card.modelData.author.charAt(0).toUpperCase(); font.weight: 800; color: "#ffffff" } }
                        Column { x: 56; y: 11; width: parent.width - 68; spacing: 4
                            Row { spacing: 6; width: parent.width
                                Label { text: card.modelData.name; font.weight: 800; font.pixelSize: 14; elide: Text.ElideRight; width: Math.min(implicitWidth, parent.width - 150) }
                                Tag { word: card.modelData.params || ""; tint: Theme.cream }
                                Tag { word: card.modelData.pick ? "LatteOS" : ""; tint: Theme.gold }
                                Glyph { visible: !!card.modelData.vision; name: "eye"; font.pixelSize: 13; color: Theme.dim; anchors.verticalCenter: parent.verticalCenter } }
                            Label { width: parent.width; elide: Text.ElideRight; color: Theme.dim; font.pixelSize: 12
                                    text: card.modelData.good ? I18n.tr(card.modelData.good) : (card.modelData.author + "  ·  ↓ " + localPage.count(card.modelData.downloads) + "  ·  ♥ " + localPage.count(card.modelData.likes) + "  ·  " + localPage.ago(card.modelData.updated)) } }
                        MouseArea { id: cardHit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: localPage.open(card.modelData) } }
                    Waiting { anchors.centerIn: parent; visible: hfFound.running; text: I18n.tr("Searching…") }
                }
                // the chosen model: its head, its download options, its card
                Rectangle { x: found.x + found.width + 14; y: 50; width: parent.width - x - 22; height: parent.height - 58; radius: 16; color: Theme.card; border.width: 1; border.color: Theme.line
                    Label { visible: !localPage.picked; anchors.centerIn: parent; color: Theme.faint; text: I18n.tr("Choose a model on the left") }
                    Flickable { visible: !!localPage.picked; anchors.fill: parent; anchors.margins: 20; clip: true; contentHeight: detail.implicitHeight; boundsBehavior: Flickable.StopAtBounds
                        Column { id: detail; width: parent.width; spacing: 12
                            Row { spacing: 12
                                Rectangle { width: 46; height: 46; radius: 23; color: localPage.picked ? Qt.hsla((localPage.picked.author.charCodeAt(0) * 37 % 360) / 360, 0.45, 0.45, 1) : "transparent"
                                    Label { anchors.centerIn: parent; text: localPage.picked ? localPage.picked.author.charAt(0).toUpperCase() : ""; font.weight: 800; font.pixelSize: 20; color: "#ffffff" } }
                                Column { spacing: 3; anchors.verticalCenter: parent.verticalCenter
                                    Label { text: localPage.picked ? localPage.picked.name : ""; font.pixelSize: 22; font.weight: 800 }
                                    Label { color: Theme.dim; font.pixelSize: 12; text: localPage.picked ? localPage.picked.repo + (localPage.picked.downloads !== undefined ? "  ·  ↓ " + localPage.count(localPage.picked.downloads) + "  ·  ♥ " + localPage.count(localPage.picked.likes) + "  ·  " + localPage.ago(localPage.picked.updated) : "") : "" } } }
                            Flow { width: parent.width; spacing: 6
                                Tag { word: localPage.picked && localPage.picked.params ? localPage.picked.params : ""; tint: Theme.cream }
                                Tag { word: localPage.picked && localPage.picked.base ? I18n.tr("based on {n}", { n: localPage.picked.base }) : ""; tint: Theme.dim }
                                Tag { word: localPage.picked && localPage.picked.license ? localPage.picked.license : ""; tint: Theme.dim }
                                Tag { word: localPage.picked && localPage.picked.vision ? I18n.tr("sees pictures") : ""; tint: "#7aa7ff" }
                                Tag { word: localPage.picked && localPage.picked.best ? I18n.tr("Best for you") : ""; tint: Theme.gold }
                                Text { text: I18n.tr("Open on Hugging Face"); color: Theme.gold; font.family: Theme.font; font.pixelSize: 12; font.underline: true
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Qt.openUrlExternally("https://huggingface.co/" + localPage.picked.repo) } } }
                            Label { visible: !!(localPage.picked && localPage.picked.good); width: parent.width; wrapMode: Text.WordWrap; color: Theme.cream; text: localPage.picked && localPage.picked.good ? I18n.tr(localPage.picked.good) : "" }
                            // the download options, as LM Studio lists them: one chosen (the recommended one at first)
                            Label { text: I18n.tr("Download options"); font.pixelSize: 15; font.weight: 800 }
                            Waiting { visible: hfFiles.running; text: I18n.tr("Asking Hugging Face…"); width: parent.width }
                            Repeater { model: hfFiles.data || []
                                Rectangle { id: opt; required property var modelData; width: detail.width; height: 44; radius: 10
                                    readonly property bool sel: !!localPage.chosen && localPage.chosen.file === modelData.file
                                    color: sel ? Theme.raised : (optHit.containsMouse ? Qt.alpha(Theme.raised, 0.5) : "transparent"); border.width: sel ? 1 : 0; border.color: Theme.gold
                                    Rectangle { x: 12; width: 16; height: 16; radius: 8; anchors.verticalCenter: parent.verticalCenter; color: "transparent"; border.width: opt.sel ? 5 : 1; border.color: opt.sel ? Theme.gold : Theme.dim }
                                    Row { x: 40; anchors.verticalCenter: parent.verticalCenter; spacing: 12
                                        Label { width: 86; text: opt.modelData.quant || "—"; font.weight: 800; anchors.verticalCenter: parent.verticalCenter }
                                        Label { width: 70; text: shell.gb(opt.modelData.size); color: Theme.dim; anchors.verticalCenter: parent.verticalCenter }
                                        FitChip { fit: opt.modelData.fit; anchors.verticalCenter: parent.verticalCenter }
                                        Label { visible: !!opt.modelData.recommended; text: "★ " + I18n.tr("Recommended"); color: Theme.gold; font.pixelSize: 12; font.weight: 700; anchors.verticalCenter: parent.verticalCenter }
                                        Label { visible: !!opt.modelData.have; text: "✓ " + I18n.tr("Downloaded"); color: Theme.ok; font.pixelSize: 12; font.weight: 700; anchors.verticalCenter: parent.verticalCenter } }
                                    MouseArea { id: optHit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: localPage.variant = opt.modelData.file } } }
                            Pill { visible: !!localPage.chosen; implicitHeight: 40; strong: !(localPage.chosen && localPage.chosen.have); icon: localPage.chosen && localPage.chosen.have ? "check" : "download"
                                   busy: !!shell.getting && !!localPage.chosen && shell.getting.file === localPage.chosen.file
                                   text: !localPage.chosen ? "" : localPage.chosen.have ? I18n.tr("Downloaded") : I18n.tr("Download {n}", { n: (localPage.chosen.quant || "") + " · " + shell.gb(localPage.chosen.size) })
                                   onPressed: if (localPage.chosen && !localPage.chosen.have && !shell.getting) { shell.fetch(["get", localPage.picked.repo, localPage.chosen.file], localPage.chosen.file); localPage.tab = "mine" } }
                            // the model's card
                            Rectangle { width: parent.width; height: 1; color: Theme.line }
                            TextEdit { width: parent.width; readOnly: true; selectByMouse: true; wrapMode: Text.Wrap; textFormat: TextEdit.MarkdownText; color: Theme.cream; font.family: Theme.font; font.pixelSize: 13
                                       text: readmeq.data && readmeq.data.text ? readmeq.data.text : "" } } } }
            }

            // ── My Models: what is on this computer, and what is on its way ──
            Scroll {
                id: minePage
                visible: localPage.tab === "mine"
                anchors.topMargin: 62
                property string openModel: ""          // the model whose settings are open
                Label { text: I18n.tr("{n} models on this computer", { n: (localModels.data || []).length }) + "  ·  " + (localPage.rec.hardware.dir || ""); color: Theme.dim; font.pixelSize: 12 }
                // a download: how far, how much is left, how fast; paused it keeps what came and goes on from there
                component Download: Rectangle { id: dl
                    property string file; property real got; property real total; property real speed; property bool live
                    signal toggled(); signal dropped()
                    width: minePage.room; height: 66; radius: 10; color: Theme.card; border.width: 1; border.color: live ? Theme.gold : Theme.line
                    Glyph { x: 14; y: 12; name: "download"; color: dl.live ? Theme.gold : Theme.dim }
                    Label { x: 44; y: 10; width: parent.width - 60 - dlBtns.width; elide: Text.ElideMiddle; text: dl.file.split("/").pop(); font.weight: 600 }
                    DotBar { x: 44; y: 40; width: Math.max(80, parent.width - 76 - dlBtns.width - dlSays.width); height: 8; segments: 40; tint: Theme.gold; value: dl.total ? dl.got / dl.total : 0 }
                    Label { id: dlSays; anchors.right: dlBtns.left; anchors.rightMargin: 16; y: 34; font.pixelSize: 12; color: Theme.dim
                            text: !dl.total ? I18n.tr("Starting…")
                                : Math.floor(100 * dl.got / dl.total) + " %  ·  " + I18n.tr("{a} of {b}", { a: shell.size(dl.got), b: shell.size(dl.total) }) + "  ·  " + I18n.tr("{n} left", { n: shell.size(dl.total - dl.got) })
                                  + (dl.live ? (dl.speed > 0 ? "  ·  " + (dl.speed / 1e6).toFixed(1) + " MB/s" : "") : "  ·  " + I18n.tr("paused")) }
                    Row { id: dlBtns; anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter; spacing: 6
                        Pill { implicitHeight: 30; visible: dl.file !== "llama.cpp"; icon: dl.live ? "player-pause" : "player-play"; text: dl.live ? I18n.tr("Pause") : I18n.tr("Go on"); onPressed: dl.toggled() }
                        Pill { implicitHeight: 30; icon: "x"; danger: true; text: I18n.tr("Cancel"); onPressed: dl.dropped() } } }
                Download { visible: !!shell.getting; live: true
                           file: shell.getting ? shell.getting.file : ""; got: shell.getting ? shell.getting.got : 0; total: shell.getting ? shell.getting.total : 0; speed: shell.getting ? shell.getting.speed || 0 : 0
                           onToggled: getter.running = false
                           onDropped: { shell.dropping = file; getter.running = false } }
                Repeater { model: (dlq.data || []).filter(d => !shell.getting || d.file !== shell.getting.file)
                    Download { required property var modelData; file: modelData.file; got: modelData.got; total: modelData.total
                               onToggled: shell.fetch(["get", modelData.repo, modelData.file], modelData.file)
                               onDropped: shell.drop(modelData.name) } }

                component Cap: Rectangle { property string icon; property string word; property color tint: Theme.dim; height: 20; radius: 6; width: capRow.implicitWidth + 12
                    color: Qt.rgba(tint.r, tint.g, tint.b, 0.14)
                    Row { id: capRow; anchors.centerIn: parent; spacing: 4
                        Glyph { name: parent.parent.icon; font.pixelSize: 12; color: parent.parent.tint; anchors.verticalCenter: parent.verticalCenter }
                        Label { text: parent.parent.word; color: parent.parent.tint; font.pixelSize: 11; font.weight: 700 } } }
                component Knob: Item { id: kn
                    property string name; property string says; property real value; signal moved(real to)
                    width: parent ? parent.width : 0; height: 30
                    Label { width: 210; text: kn.name; anchors.verticalCenter: parent.verticalCenter; elide: Text.ElideRight }
                    Slide { x: 220; width: parent.width - 220 - 190; value: kn.value; anchors.verticalCenter: parent.verticalCenter; onMoved: to => kn.moved(to) }
                    Label { anchors.right: parent.right; width: 176; horizontalAlignment: Text.AlignRight; text: kn.says; font.weight: 700; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter; elide: Text.ElideLeft } }
                // how a model is loaded (LM Studio's load settings), and what memory that takes on this computer, counted by
                // llama.cpp itself as the sliders move
                component Loading: Column { id: ld
                    property var model                 // a row of `latte-ai local models`
                    property var draft: Object.assign({}, model.settings)
                    readonly property var mem: estq.data && estFor === model.id ? estq.data : model.memory
                    property string estFor: ""
                    readonly property bool changed: Object.keys(draft).some(k => draft[k] !== model.settings[k])
                    readonly property int maxCtx: Math.max(2048, model.memory.context || 32768)
                    function put(k, v) { const d = Object.assign({}, draft); d[k] = v; draft = d; if (k === "ctx" || k === "ngl") again.restart() }
                    Timer { id: again; interval: 350; onTriggered: { ld.estFor = ld.model.id; estq.ask(["estimate", ld.model.id, String(ld.draft.ctx), String(ld.draft.ngl)]) } }
                    spacing: 10
                    Rectangle { width: parent.width; height: 1; color: Theme.line }
                    // the context on a scale of doublings, from 1024 tokens to what the model was made for
                    Knob { name: I18n.tr("Context length"); says: I18n.tr("{n} of {m} tokens", { n: ld.draft.ctx, m: ld.maxCtx })
                           value: Math.log(ld.draft.ctx / 1024) / Math.log(ld.maxCtx / 1024)
                           onMoved: to => ld.put("ctx", Math.min(ld.maxCtx, Math.round(1024 * Math.pow(ld.maxCtx / 1024, to) / 256) * 256)) }
                    Knob { name: I18n.tr("Layers on the graphics card"); says: I18n.tr("{n} of {m}", { n: Math.min(ld.draft.ngl, ld.model.memory.layers), m: ld.model.memory.layers })
                           value: Math.min(1, ld.draft.ngl / ld.model.memory.layers); onMoved: to => ld.put("ngl", Math.round(to * ld.model.memory.layers)) }
                    Knob { name: I18n.tr("Processor threads"); says: I18n.tr("{n} of {m}", { n: ld.draft.threads, m: localPage.rec.hardware.cores || 1 })
                           value: (ld.draft.threads - 1) / Math.max(1, (localPage.rec.hardware.cores || 2) - 1); onMoved: to => ld.put("threads", 1 + Math.round(to * ((localPage.rec.hardware.cores || 2) - 1))) }
                    Knob { name: I18n.tr("Evaluation batch size"); says: String(ld.draft.batch); value: Math.log(ld.draft.batch / 64) / Math.log(64); onMoved: to => ld.put("batch", Math.round(64 * Math.pow(64, to) / 64) * 64) }
                    Knob { name: I18n.tr("Physical batch size"); says: String(ld.draft.ubatch); value: Math.log(ld.draft.ubatch / 64) / Math.log(32); onMoved: to => ld.put("ubatch", Math.round(64 * Math.pow(32, to) / 64) * 64) }
                    Knob { name: I18n.tr("Answers at the same time"); says: String(ld.draft.parallel); value: (ld.draft.parallel - 1) / 7; onMoved: to => ld.put("parallel", 1 + Math.round(to * 7)) }
                    Row { spacing: 24; height: 30
                        Row { spacing: 10; anchors.verticalCenter: parent.verticalCenter
                            Toggle { on: ld.draft.mlock === 1; onFlipped: ld.put("mlock", ld.draft.mlock === 1 ? 0 : 1) }
                            Label { text: I18n.tr("Keep the model in memory"); anchors.verticalCenter: parent.verticalCenter } }
                        Row { spacing: 10; anchors.verticalCenter: parent.verticalCenter
                            Toggle { on: ld.draft.mmap === 1; onFlipped: ld.put("mmap", ld.draft.mmap === 1 ? 0 : 1) }
                            Label { text: I18n.tr("Read the file as it is needed (mmap)"); anchors.verticalCenter: parent.verticalCenter } } }
                    // the estimate, beside what this computer has
                    Rectangle { width: parent.width; height: memCol.implicitHeight + 24; radius: 12; color: Theme.raised
                        Column { id: memCol; x: 14; y: 12; width: parent.width - 28; spacing: 8
                            Row { spacing: 10
                                Label { text: I18n.tr("Estimated memory"); font.weight: 800; anchors.verticalCenter: parent.verticalCenter }
                                FitChip { fit: ld.mem.fit; anchors.verticalCenter: parent.verticalCenter }
                                Label { visible: estq.running; text: I18n.tr("Counting…"); color: Theme.dim; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter } }
                            Item { width: parent.width; height: 22
                                Label { width: 150; text: I18n.tr("Graphics card"); color: Theme.dim; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
                                DotBar { x: 160; width: parent.width - 160 - 250; height: 10; segments: 30; value: ld.mem.vram ? Math.min(1, ld.mem.gpu / ld.mem.vram) : 0; anchors.verticalCenter: parent.verticalCenter }
                                Label { anchors.right: parent.right; width: 240; horizontalAlignment: Text.AlignRight; font.pixelSize: 13; font.weight: 700; anchors.verticalCenter: parent.verticalCenter
                                        text: I18n.tr("{a} of {b}", { a: shell.gb(ld.mem.gpu), b: shell.gb(ld.mem.vram) }) + (ld.mem.free ? "  ·  " + I18n.tr("{n} free now", { n: shell.gb(ld.mem.free) }) : "") } }
                            Item { width: parent.width; height: 22
                                Label { width: 150; text: I18n.tr("Memory"); color: Theme.dim; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
                                DotBar { x: 160; width: parent.width - 160 - 250; height: 10; segments: 30; value: Math.min(1, (ld.mem.total - ld.mem.gpu) / Math.max(1, ld.mem.ram)); anchors.verticalCenter: parent.verticalCenter }
                                Label { anchors.right: parent.right; width: 240; horizontalAlignment: Text.AlignRight; font.pixelSize: 13; font.weight: 700; anchors.verticalCenter: parent.verticalCenter
                                        text: I18n.tr("{a} of {b}", { a: shell.gb(ld.mem.total - ld.mem.gpu), b: shell.gb(ld.mem.ram) }) } }
                            Label { width: parent.width; wrapMode: Text.WordWrap; color: Theme.dim; font.pixelSize: 12
                                    text: I18n.tr("In all {n}.", { n: shell.gb(ld.mem.total) }) + " " + (ld.mem.measured ? I18n.tr("Counted by llama.cpp for these settings, without loading the model.") : I18n.tr("A rough count from the file; llama.cpp counts it exactly once it is downloaded (Runtime).")) } } }
                    Row { spacing: 10
                        Pill { implicitHeight: 34; icon: "check"; strong: ld.changed; text: I18n.tr("Apply")
                               onPressed: if (ld.changed) { localSet.command = ["latte-ai", "local", "set", ld.model.id].concat(Object.keys(ld.draft).reduce((a, k) => a.concat([k, String(ld.draft[k])]), [])); localSet.running = true } }
                        Pill { implicitHeight: 34; icon: "arrow-back-up"; text: I18n.tr("LatteOS's own"); visible: ld.model.own.length > 0
                               onPressed: { localSet.command = ["latte-ai", "local", "set", ld.model.id].concat(ld.model.own.reduce((a, k) => a.concat([k, "auto"]), [])); localSet.running = true } }
                        Label { text: I18n.tr("The model is loaded anew at the next question."); color: Theme.dim; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter } } }

                Repeater { model: localModels.data || []
                    Rectangle { id: lm; required property var modelData; width: minePage.room; height: lmCol.implicitHeight + 20; radius: 10; color: Theme.card
                        readonly property bool open: minePage.openModel === modelData.id
                        readonly property var inChat: ((shell.models.find(p => p.id === "local") || { models: [] }).models.find(m => m.id === modelData.id)) || null
                        border.width: open ? 1 : 0; border.color: Theme.gold
                        Column { id: lmCol; x: 14; y: 10; width: parent.width - 28; spacing: 12
                            Item { width: parent.width; height: 46
                                Glyph { anchors.verticalCenter: parent.verticalCenter; name: "cube"; color: Theme.gold }
                                Column { x: 32; width: parent.width - 32 - lmBtns.width - 12; anchors.verticalCenter: parent.verticalCenter; spacing: 5
                                    Row { spacing: 8; width: parent.width
                                        Label { text: lm.modelData.name; font.weight: 600; elide: Text.ElideRight; width: Math.min(implicitWidth, parent.width - 250) }
                                        // what it can do: its file says it (the vision file beside it, its chat template)
                                        Cap { visible: lm.modelData.vision; icon: "eye"; word: I18n.tr("sees pictures"); tint: "#7aa7ff" }
                                        Cap { visible: lm.modelData.tools; icon: "tool"; word: I18n.tr("tools"); tint: Theme.gold }
                                        Cap { visible: lm.modelData.reasoning; icon: "bulb"; word: I18n.tr("reasoning"); tint: Theme.ok } }
                                    Row { spacing: 10
                                        Label { text: shell.gb(lm.modelData.size) + "  ·  " + I18n.tr("needs {n}", { n: shell.gb(lm.modelData.memory.total) })
                                                      + (lm.modelData.memory.gpu > 0 ? "  ·  " + I18n.tr("{n} of it on the card", { n: shell.gb(lm.modelData.memory.gpu) }) : ""); color: Theme.dim; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                                        FitChip { fit: lm.modelData.memory.fit; anchors.verticalCenter: parent.verticalCenter } } }
                                Row { id: lmBtns; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; spacing: 8
                                    Label { visible: !!lm.inChat; text: I18n.tr("In LensGoo's chat"); color: Theme.dim; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                                    Toggle { visible: !!lm.inChat; on: !!lm.inChat && !lm.inChat.hidden; anchors.verticalCenter: parent.verticalCenter
                                             onFlipped: modeler.ask(["model", lm.inChat.hidden ? "show" : "hide", "local", lm.modelData.id]) }
                                    Pill { implicitHeight: 30; icon: "settings"; text: ""; strong: lm.open; onPressed: { estq.data = null; minePage.openModel = lm.open ? "" : lm.modelData.id } }
                                    Pill { implicitHeight: 30; icon: "trash"; danger: true; text: ""
                                           onPressed: { localSet.command = ["latte-ai", "local", "remove", lm.modelData.id]; localSet.running = true } } } }
                            Loader { width: parent.width; active: lm.open; visible: active; sourceComponent: Loading { width: lmCol.width; model: lm.modelData } } } } }
            }

            // ── Runtime: the computer, llama.cpp, the graphics card ──
            Scroll {
                id: runPage
                visible: localPage.tab === "runtime"
                anchors.topMargin: 62
                Rectangle { width: runPage.room; height: hwCol.implicitHeight + 32; radius: 16; color: Theme.card; border.width: 1; border.color: Theme.line
                    Column { id: hwCol; x: 18; y: 16; width: parent.width - 36; spacing: 8
                        Label { text: I18n.tr("Your computer"); font.pixelSize: 16; font.weight: 800 }
                        Label { width: parent.width; wrapMode: Text.WordWrap; color: Theme.dim; font.pixelSize: 13
                                text: (localPage.rec.hardware.cpu || "…") + "  ·  " + I18n.tr("{n} cores", { n: localPage.rec.hardware.cores || 0 }) + (localPage.rec.hardware.avx2 === false ? "  ·  " + I18n.tr("without AVX2: small models are quicker") : "")
                                      + "\n" + I18n.tr("Memory {n}", { n: shell.gb(localPage.rec.hardware.ram || 0) }) + "  ·  " + (localPage.rec.hardware.gpus || []).map(g => g.name + (g.vram ? " (" + shell.gb(g.vram) + ")" : "")).join(", ")
                                      + "\n" + I18n.tr("Models go to {n}, {m} free", { n: localPage.rec.hardware.dir || "", m: shell.gb(localPage.rec.hardware.free || 0) }) } } }
                Row { spacing: 10
                    Label { anchors.verticalCenter: parent.verticalCenter; color: localPage.rec.runtime ? Theme.ok : Theme.gold; font.pixelSize: 13
                            text: localPage.rec.runtime ? I18n.tr("llama.cpp is ready") : I18n.tr("llama.cpp, which runs the models, is not here yet") }
                    Pill { implicitHeight: 32; icon: "download"; text: localPage.rec.runtime ? I18n.tr("Update llama.cpp") : I18n.tr("Download llama.cpp")
                           busy: !!shell.getting && shell.getting.file === "llama.cpp"; onPressed: shell.fetch(["runtime", "get"], "llama.cpp") } }
                Pill { implicitHeight: 32; icon: localPage.rec.gpu === true ? "check" : "cpu"; strong: localPage.rec.gpu === true; text: I18n.tr("Use the graphics card")
                       onPressed: { localSet.command = ["latte-ai", "local", "gpu", localPage.rec.gpu === true ? "off" : "on"]; localSet.running = true } }
            }

        }

        // ── LensAI's settings, a part for each way an AI is reached: its own page in a tab (web), its official tool in a
        // terminal (CLI), a key of one's own (API); under each that can answer, which of its models LensGoo's and
        // LensShore's chat offers. And what every AI is told first ──────────────────────────────────────────────────
        Item {
            id: setPage
            anchors.fill: parent
            visible: shell.page === "lensai"
            Row { x: 22; y: 16; spacing: 8
                Repeater { model: [{ id: "web", name: QT_TR_NOOP("Web"), icon: "world" }, { id: "cli", name: QT_TR_NOOP("CLI"), icon: "terminal-2" }, { id: "api", name: QT_TR_NOOP("API"), icon: "key" },
                                   { id: "instructions", name: QT_TR_NOOP("Instructions"), icon: "file-text" }]
                    Pill { required property var modelData; implicitHeight: 34; icon: modelData.icon; text: I18n.tr(modelData.name) + (shell.kinds[modelData.id] !== undefined ? "     " : ""); strong: shell.section === modelData.id
                           onPressed: shell.openSection(modelData.id)
                           Kind { kind: parent.modelData.id; anchors.right: parent.right; anchors.rightMargin: 14; anchors.verticalCenter: parent.verticalCenter; border.width: 1; border.color: Qt.rgba(0, 0, 0, 0.25) } } } }

            // the models of one that can answer: which the chat of LensGoo and LensShore offers, and the star on the one a
            // new conversation begins with
            component ModelRows: Column { id: mrs
                property string pid
                readonly property var rows: (shell.models.find(p => p.id === pid) || { models: [] }).models
                visible: rows.length > 0; spacing: 2
                Rectangle { width: parent.width; height: 1; color: Theme.line }
                Item { width: parent.width; height: 26
                    Label { text: I18n.tr("MODELS"); color: Theme.faint; font.pixelSize: 11; font.weight: 700; font.letterSpacing: 0.8; anchors.verticalCenter: parent.verticalCenter }
                    Label { anchors.right: parent.right; text: I18n.tr("In LensGoo's chat"); color: Theme.faint; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter } }
                Repeater { model: mrs.rows
                    Item { id: mr; required property var modelData; width: mrs.width; height: 34
                        Glyph { name: "star"; font.pixelSize: 16; color: mr.modelData.default ? Theme.gold : Theme.faint; anchors.verticalCenter: parent.verticalCenter
                            MouseArea { anchors.fill: parent; anchors.margins: -8; cursorShape: Qt.PointingHandCursor; onClicked: modeler.ask(["model", "default", mrs.pid, mr.modelData.id]) } }
                        Label { x: 28; width: parent.width - 28 - 150; elide: Text.ElideRight; text: mr.modelData.name; opacity: mr.modelData.hidden ? 0.5 : 1; anchors.verticalCenter: parent.verticalCenter }
                        Label { anchors.right: mrTg.left; anchors.rightMargin: 12; visible: mr.modelData.default; text: I18n.tr("default"); color: Theme.gold; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                        Toggle { id: mrTg; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; scale: 0.85; on: !mr.modelData.hidden
                                 onFlipped: modeler.ask(["model", mr.modelData.hidden ? "show" : "hide", mrs.pid, mr.modelData.id]) } } } }

            // ── web: the services' own pages in tabs, which, in what order, under what name and picture ──
            Scroll {
                id: webSet
                visible: shell.section === "web"
                anchors.topMargin: 62
                Label { width: webSet.room; wrapMode: Text.WordWrap; color: Theme.dim
                        text: I18n.tr("Each one is the service's own page, with its own sign-in, as in a browser: the same service twice is two accounts side by side. LensAI reads nothing from a page, so the account is your own note, to tell them apart. The ring shows what is used of the limit that the service's tool tells.") }
                Repeater { model: shell.tabbed
                    Rectangle { id: tr; required property var modelData; required property int index; width: webSet.room; height: 104; radius: 18; color: Theme.card
                        readonly property string pic: shell.iconOf(modelData)
                        readonly property string tool: shell.usageOf(modelData)
                        readonly property bool changed: nameF.text.trim() !== modelData.name || accF.text.trim() !== (modelData.account || "")
                        function keep() { if (changed) shell.setTab(modelData.id, { name: nameF.text.trim() || modelData.name, account: accF.text.trim() }) }
                        // its picture; pressed: the page's own again, or one of the person's
                        Rectangle { x: 14; y: 12; width: 40; height: 40; radius: 20; color: "#f5f1ea"; border.width: picHit.containsMouse ? 2 : 0; border.color: Theme.gold
                            Image { anchors.centerIn: parent; visible: tr.pic !== ""; sourceSize: Qt.size(48, 48); width: 24; height: 24; fillMode: Image.PreserveAspectFit; source: tr.pic }
                            Label { anchors.centerIn: parent; visible: tr.pic === ""; text: tr.modelData.name.charAt(0).toUpperCase(); color: "#2a1e17"; font.weight: 800 }
                            MouseArea { id: picHit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: { const p = mapToItem(besideMenu, 0, height + 4)
                                             besideMenu.open(p.x, p.y, [{ text: I18n.tr("The page's own icon (default)"), icon: "world", checked: !tr.modelData.icon, run: () => shell.setTab(tr.modelData.id, { icon: "" }) },
                                                                        { text: I18n.tr("Browse…"), icon: "folder", checked: !!tr.modelData.icon, run: () => { iconPick.id = tr.modelData.id; iconPick.running = true } }]) } } }
                        Field { id: nameF; x: 66; y: 12; width: 230; icon: "tag"; hint: I18n.tr("Name"); text: tr.modelData.name; onAccepted: tr.keep() }
                        Field { id: accF; x: 306; y: 12; width: parent.width - 306 - 14 - (keepP.visible ? keepP.width + 8 : 0); icon: "user"; hint: I18n.tr("Account: name, e-mail (your note)"); text: tr.modelData.account || ""; onAccepted: tr.keep() }
                        Pill { id: keepP; visible: tr.changed; anchors.right: parent.right; anchors.rightMargin: 14; y: 14; icon: "check"; strong: true; text: I18n.tr("Keep"); onPressed: tr.keep() }
                        Row { x: 66; y: 64; spacing: 8; height: 30
                            Kind { kind: "web"; anchors.verticalCenter: parent.verticalCenter }
                            Label { text: tr.modelData.web; color: Theme.dim; font.pixelSize: 12; width: Math.min(implicitWidth, tr.width - 66 - trBtns.width - 50); elide: Text.ElideRight; anchors.verticalCenter: parent.verticalCenter } }
                        Row { id: trBtns; anchors.right: parent.right; anchors.rightMargin: 14; y: 62; spacing: 6
                            // whose limits its ring shows: a tool's that is signed in with the same account, or none
                            Pill { implicitHeight: 32; icon: "gauge"; text: tr.tool !== "" && (shell.agents.services || []).some(x => x.id === tr.tool) ? I18n.tr("Limits: {n}", { n: shell.nameOf(tr.tool) }) : I18n.tr("No limits shown")
                                   onPressed: { const p = mapToItem(besideMenu, 0, height + 4)
                                                besideMenu.open(Math.min(p.x, besideMenu.width - 280), p.y, (shell.agents.services || []).map(x => ({ text: I18n.tr(x.name), checked: tr.tool === x.id,
                                                        hint: ((shell.services.find(y => y.id === x.id) || {}).account || "").split(" · ")[0], run: () => shell.setTab(tr.modelData.id, { usage: x.id }) }))
                                                    .concat([{ line: true }, { text: I18n.tr("None"), checked: tr.tool === "" || !(shell.agents.services || []).some(x => x.id === tr.tool), run: () => shell.setTab(tr.modelData.id, { usage: "" }) }])) } }
                            Pill { implicitHeight: 32; icon: "chevron-up"; text: ""; visible: tr.index > 0
                                   onPressed: { const l = shell.tabbed.slice(); l.splice(tr.index - 1, 0, l.splice(tr.index, 1)[0]); shell.keepTabs(l) } }
                            Pill { implicitHeight: 32; icon: "chevron-down"; text: ""; visible: tr.index < shell.tabbed.length - 1
                                   onPressed: { const l = shell.tabbed.slice(); l.splice(tr.index + 1, 0, l.splice(tr.index, 1)[0]); shell.keepTabs(l) } }
                            Pill { implicitHeight: 32; icon: "trash"; danger: true; text: I18n.tr("Remove"); onPressed: shell.removeTab(tr.modelData.id) } } } }
                Label { text: I18n.tr("ANOTHER PAGE"); color: Theme.faint; font.pixelSize: 11; font.weight: 700; font.letterSpacing: 0.8 }
                Row { spacing: 10
                    Field { id: tabName; width: 220; icon: "tag"; hint: I18n.tr("Name") }
                    Field { id: tabWeb; width: Math.min(380, webSet.room - 380); icon: "world-www"; hint: "https://perplexity.ai"; onAccepted: tabAdd.pressed() }
                    Pill { id: tabAdd; icon: "plus"; strong: true; text: I18n.tr("Add")
                           onPressed: if (shell.addTab(tabName.text, tabWeb.text)) { tabName.text = ""; tabWeb.text = ""; tabBad.visible = false } else tabBad.visible = tabWeb.text.trim() !== "" } }
                Label { id: tabBad; visible: false; color: Theme.red; font.pixelSize: 12; text: I18n.tr("That is not a web address.") }
                Pill { icon: "arrow-back-up"; text: I18n.tr("Back to LatteOS's list"); onPressed: shell.keepTabs(shell.defaultTabs) }
            }

            // ── CLI: the services' official tools, signed in once in a terminal ──
            Scroll {
                id: cliSet
                visible: shell.section === "cli"
                anchors.topMargin: 62
                Waiting { visible: shell.services.length === 0 && svc.running; text: I18n.tr("Asking the services…"); width: cliSet.room }
                Label { width: cliSet.room; wrapMode: Text.WordWrap; color: Theme.dim
                        text: I18n.tr("With an account, the service's official tool answers, signed in once in the terminal: it is what LensGoo's chat, the agents and the limits go through.") }
                Repeater { model: shell.services.filter(x => x.id !== "local")
                    Rectangle { id: card; required property var modelData; width: cliSet.room; height: cardCol.implicitHeight + 28; radius: 20; color: Theme.card
                        Column { id: cardCol; x: 18; y: 14; width: parent.width - 36; spacing: 10
                            Item { width: parent.width; height: 52
                                Mark { of: card.modelData.id; glyph: "terminal-2"; size: 48; opacity: card.modelData.installed ? 1 : 0.4; anchors.verticalCenter: parent.verticalCenter }
                                Column { x: 64; width: parent.width - 64 - cardBtns.width - 12; anchors.verticalCenter: parent.verticalCenter; spacing: 4
                                    Row { spacing: 8
                                        Label { text: I18n.tr(card.modelData.name); font.pixelSize: 16; font.weight: 700 }
                                        Kind { kind: shell.kindOf(card.modelData.id); anchors.verticalCenter: parent.verticalCenter } }
                                    Label { width: parent.width; elide: Text.ElideRight; color: Theme.dim; font.pixelSize: 12
                                            text: !card.modelData.installed ? I18n.tr("Not installed yet: Install puts its official tool {tool} on this computer.", { tool: card.modelData.tool })
                                                : card.modelData.local ? I18n.tr("Answers on this computer; nothing leaves it.")
                                                : card.modelData.signed === true ? I18n.tr("Signed in") + (card.modelData.account ? " · " + card.modelData.account : "")
                                                : card.modelData.signed === false ? I18n.tr("Not signed in") : I18n.tr("Installed; sign in once in the terminal.") } }
                                Row { id: cardBtns; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; spacing: 8
                                    Rectangle { visible: card.modelData.installed && card.modelData.signed === true; width: 10; height: 10; radius: 5; color: Theme.ok; anchors.verticalCenter: parent.verticalCenter }
                                    // the service's official tool, installed for this user in a terminal (latte-ai services › install)
                                    Pill { visible: !card.modelData.installed && (card.modelData.install || "") !== ""; icon: "download"; strong: true; text: I18n.tr("Install")
                                           onPressed: { shell.inTerminal(["sh", "-c", card.modelData.install]); later.restart() } }
                                    Pill { visible: card.modelData.installed && card.modelData.login.length > 0 && card.modelData.signed !== true; icon: "login"; strong: true; text: I18n.tr("Sign in")
                                           onPressed: { shell.inTerminal(card.modelData.login); later.restart() } }
                                    Pill { visible: card.modelData.installed && card.modelData.logout.length > 0 && card.modelData.signed === true; icon: "logout"; text: I18n.tr("Sign out")
                                           onPressed: { shell.inTerminal(card.modelData.logout); later.restart() } } } }
                            ModelRows { width: parent.width; pid: card.modelData.id } } } }

                // LatteOS for the agents: one MCP server, written into each agent's own tool (ROADMAP 10B.43)
                Label { text: I18n.tr("LATTEOS FOR YOUR AGENTS"); color: Theme.faint; font.pixelSize: 11; font.weight: 700; font.letterSpacing: 0.8 }
                Rectangle { width: cliSet.room; height: mcpCol.implicitHeight + 32; radius: 18; color: Theme.card
                    Column { id: mcpCol; x: 18; y: 16; width: parent.width - 36 - 80; spacing: 6
                        Label { text: I18n.tr("Let the agents see LatteOS"); font.weight: 700 }
                        Label { width: parent.width; wrapMode: Text.WordWrap; color: Theme.dim; font.pixelSize: 12
                                text: I18n.tr("Claude Code, Codex and Gemini can then read your conversations kept here, what is left of the limits, and the agents at work, and ask to change small things (the volume, the Wi-Fi…). Nothing is changed before you allow it here.") }
                        Label { width: parent.width; wrapMode: Text.WordWrap; color: Theme.dim; font.pixelSize: 12; visible: shell.mcp.agents.length > 0
                                text: shell.mcp.agents.filter(a => a.installed).map(a => a.name + (a.has ? " ✓" : " –")).join("   ") } }
                    Toggle { on: shell.mcpOn; anchors.right: parent.right; anchors.rightMargin: 18; y: 18; opacity: mcpSet.running ? 0.5 : 1
                             onFlipped: if (!mcpSet.running) { mcpSet.command = ["latte-mcp", shell.mcpOn ? "remove" : "install"]; mcpSet.running = true } } }
            }

            // ── API: a key of one's own, as in VS Code: the service's API answers directly, a conversation and no tools ──
            Scroll {
                id: apiSet
                visible: shell.section === "api"
                anchors.topMargin: 62
                Label { width: apiSet.room; wrapMode: Text.WordWrap; color: Theme.dim
                        text: I18n.tr("With a key from the service's own site, its API answers directly: you pay it for what you use. The key is kept in the system's keyring, never in a file.") }
                // the keyring did not open at sign-in: nothing can be kept in it or read from it
                Rectangle { visible: shell.keys.length > 0 && shell.keys[0].locked === true; width: apiSet.room; height: lockCol.implicitHeight + 28; radius: 16
                            color: Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.12); border.width: 1; border.color: Theme.red
                    Glyph { x: 16; y: 16; name: "lock"; color: Theme.red }
                    Column { id: lockCol; x: 48; y: 14; width: parent.width - 64; spacing: 4
                        Label { text: I18n.tr("The system's keyring is locked"); font.weight: 800 }
                        Label { width: parent.width; wrapMode: Text.WordWrap; color: Theme.dim; font.pixelSize: 13
                                text: I18n.tr("It did not open when you signed in, so the keys kept in it cannot be read. Keeping a key asks for the keyring's own password, which is the one it was made with and need not be your account's.") } } }
                Repeater { model: shell.keys.filter(k => !k.server)
                    Rectangle { id: kc; required property var modelData; width: apiSet.room; height: kcCol.implicitHeight + 24; radius: 18; color: Theme.card
                        property bool swap: false          // a kept key is being replaced
                        readonly property bool failed: shell.keyError.id === modelData.id
                        Column { id: kcCol; x: 16; y: 12; width: parent.width - 32; spacing: 8
                            Item { width: parent.width; height: 44
                                Mark { of: kc.modelData.id; glyph: "key"; size: 36; anchors.verticalCenter: parent.verticalCenter }
                                Column { x: 48; width: 230; anchors.verticalCenter: parent.verticalCenter; spacing: 2
                                    Row { spacing: 8
                                        Label { text: kc.modelData.name; font.weight: 700 }
                                        Kind { kind: "api"; anchors.verticalCenter: parent.verticalCenter } }
                                    Label { color: kc.modelData.has ? Theme.ok : Theme.dim; font.pixelSize: 12
                                            text: kc.modelData.has ? I18n.tr("A key is kept") + (kc.modelData.tail ? "  ·  …" + kc.modelData.tail : "") : I18n.tr("No key") } }
                                Row { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; spacing: 8
                                    Field { id: kf; visible: !kc.modelData.has || kc.swap; width: Math.max(160, Math.min(320, apiSet.room - 620)); icon: "key"; secret: true; hint: I18n.tr("Paste the key…")
                                            onAccepted: { shell.keep(kc.modelData.id, text); text = ""; kc.swap = false } }
                                    Pill { visible: kf.visible; icon: "check"; strong: true; busy: keeper.running && keeper.id === kc.modelData.id; text: I18n.tr("Keep"); onPressed: { shell.keep(kc.modelData.id, kf.text); kf.text = ""; kc.swap = false } }
                                    Pill { visible: kc.modelData.has && !kc.swap; icon: "refresh"; text: I18n.tr("Replace"); onPressed: kc.swap = true }
                                    Pill { visible: kc.modelData.has; icon: "trash"; danger: true; text: I18n.tr("Remove"); onPressed: keyer.ask(["forget-key", kc.modelData.id]) }
                                    // where the service makes keys
                                    Pill { visible: !kc.modelData.has && !!kc.modelData.page; icon: "external-link"; text: I18n.tr("Get a key"); onPressed: Qt.openUrlExternally(kc.modelData.page) } } }
                            Label { visible: kc.failed; width: parent.width; wrapMode: Text.WordWrap; color: Theme.red; font.pixelSize: 12
                                    text: shell.keyError.error === "locked" ? I18n.tr("The key was not kept: the system's keyring is locked and did not open.") : I18n.tr("The key was not kept: the system's keyring did not take it.") }
                            ModelRows { width: parent.width; pid: kc.modelData.id } } } }

                // servers of one's own: anything that speaks the OpenAI API — llama-server, Ollama, a computer at home
                Label { text: I18n.tr("SERVERS OF YOUR OWN"); color: Theme.faint; font.pixelSize: 11; font.weight: 700; font.letterSpacing: 0.8 }
                Repeater { model: shell.keys.filter(k => k.server)
                    Rectangle { id: sc; required property var modelData; width: apiSet.room; height: scCol.implicitHeight + 24; radius: 18; color: Theme.card
                        Column { id: scCol; x: 16; y: 12; width: parent.width - 32; spacing: 8
                            Item { width: parent.width; height: 40
                                Glyph { name: "server"; color: Theme.gold; anchors.verticalCenter: parent.verticalCenter }
                                Column { x: 32; width: parent.width - 180; anchors.verticalCenter: parent.verticalCenter; spacing: 2
                                    Row { spacing: 8
                                        Label { text: sc.modelData.name; font.weight: 700 }
                                        Kind { kind: "api"; anchors.verticalCenter: parent.verticalCenter } }
                                    Label { text: sc.modelData.url; color: Theme.dim; font.pixelSize: 12; width: parent.width; elide: Text.ElideRight } }
                                Pill { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; icon: "trash"; danger: true; text: I18n.tr("Remove")
                                       onPressed: keyer.ask(["server", "remove", sc.modelData.id]) } }
                            ModelRows { width: parent.width; pid: sc.modelData.id } } } }
                Row { spacing: 10
                    Field { id: srvName; width: 220; icon: "server"; hint: I18n.tr("Name") }
                    Field { id: srvUrl; width: Math.min(380, apiSet.room - 380); icon: "world-www"; hint: "http://192.168.1.10:8080/v1" }
                    Pill { icon: "plus"; strong: true; text: I18n.tr("Add")
                           onPressed: if (/^https?:\/\/\S+$/.test(srvUrl.text.trim()) && srvName.text.trim() !== "") { keyer.ask(["server", "add", srvName.text.trim(), srvUrl.text.trim()]); srvName.text = ""; srvUrl.text = "" } } }
            }

            // ── what every AI is told first: who the user is, how they want to be answered ─────────────────────
            Scroll {
                id: rulePage
                visible: shell.section === "instructions"
                anchors.topMargin: 62
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
        }
    }
}
