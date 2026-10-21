// Lens AI centre: every conversation with every AI in one list, and the services themselves — which are there,
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
    property string page: "chats"              // chats · compare · models · instructions · services
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
    readonly property var colours: ({ "api-anthropic": "#d97757", "api-openai": "#10a37f", "api-google": "#4285f4", "api-xai": "#a8a8a8", "api-mistral": "#fa520f", "claude": "#d97757", "gemini": "#4285f4", "chatgpt": "#10a37f", "grok": "#a8a8a8", "mistral": "#fa520f", "local": Theme.gold, "ollama": Theme.gold })
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
        ask(["again", open, useProvider, useModel])
    }
    Ask { id: forget; onDone: { shell.open = ""; shell.chat = null; list.ask(["chats"]) } }
    function reload() { list.ask(["chats"]); if (open !== "") one.ask(["chat", open]) }
    function choose(id) { open = id; page = "chats"; chat = null; one.ask(["chat", id]) }
    // a command to sign in or out runs in a terminal: the tool asks there what it needs
    function inTerminal(argv) { Quickshell.execDetached(["foot", "-e", "sh", "-c", argv.map(a => "'" + a.replace(/'/g, "'\\''") + "'").join(" ") + "; echo; read -p '" + I18n.tr("Press Enter to close") + "' x"]) }
    Timer { id: later; interval: 2500; onTriggered: svc.ask(["services"]) }
    Component.onCompleted: {
        list.ask(["chats"]); who.ask(["providers", "all"]); svc.ask(["services"]); keyq.ask(["keys"])
        if (words[0] === "services" || words[0] === "models") page = words[0]
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
    function send(text) {
        if (text.trim() === "" || waiting || useProvider === "") return
        if (editing && chat) {
            const m = chat.messages.slice()
            while (m.length && m[m.length - 1].role === "assistant") m.pop()
            m.pop()
            chat = Object.assign({}, chat, { messages: m.concat([{ role: "user", content: text, provider: useProvider, model: useModel }]) })
            editing = false
            ask(["again", open, useProvider, useModel, "--text", text])
            return
        }
        if (chat) chat = Object.assign({}, chat, { messages: chat.messages.concat([{ role: "user", content: text, provider: useProvider, model: useModel }]) })
        ask(["send", open !== "" ? open : "new", useProvider, useModel, text])
    }

    AppWindow {
        title: I18n.tr("Lens AI centre")
        heading: shell.page === "instructions" ? I18n.tr("Instructions") : shell.page === "services" ? I18n.tr("Services") : shell.page === "models" ? I18n.tr("Models") : shell.page === "compare" ? I18n.tr("Compare") : (shell.chat ? shell.chat.title : I18n.tr("Conversations"))
        implicitWidth: 1120; implicitHeight: 760
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
                    Label { text: I18n.tr("Lens AI centre"); font.pixelSize: 17; font.weight: 700; anchors.verticalCenter: parent.verticalCenter } }
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
                Nav { text: I18n.tr("Compare"); icon: "layout-columns"; on: shell.page === "compare"; onPressed: shell.page = "compare" }
                Nav { text: I18n.tr("Instructions"); icon: "file-text"; on: shell.page === "instructions"; onPressed: shell.page = "instructions" }
                Nav { text: I18n.tr("Models"); icon: "sparkles"; on: shell.page === "models"; onPressed: { shell.page = "models"; modelq.ask(["models"]) } }
                Nav { text: I18n.tr("Services"); icon: "plug-connected"; on: shell.page === "services"; onPressed: { shell.page = "services"; svc.ask(["services"]) } }
            }
        ]

        // ── a conversation: its messages, and the line to go on with it ─────────────────────────────────────
        Item {
            anchors.fill: parent
            visible: shell.page === "chats"
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
                            color: msg.mine ? Theme.gold : shell.colour(msg.modelData.provider); font.pixelSize: 11; font.weight: 700 }
                    Rectangle { id: bubble; y: 20; x: msg.mine ? talk.width - 28 - width : 28; width: Math.min(talk.width * 0.78, said.implicitWidth + 28); height: said.implicitHeight + 22; radius: 16
                        color: msg.mine ? Qt.rgba(Theme.gold.r, Theme.gold.g, Theme.gold.b, 0.14) : Theme.card
                        border.width: msg.mine ? 0 : 1; border.color: Qt.rgba(Qt.color(shell.colour(msg.modelData.provider)).r, Qt.color(shell.colour(msg.modelData.provider)).g, Qt.color(shell.colour(msg.modelData.provider)).b, 0.45)
                        TextEdit { id: said; x: 14; y: 11; width: Math.min(talk.width * 0.78 - 28, implicitWidth); readOnly: true; selectByMouse: true; wrapMode: Text.Wrap
                                   textFormat: msg.mine ? TextEdit.PlainText : TextEdit.MarkdownText
                                   text: msg.modelData.content + (msg.modelData.stopped ? "\n\n*" + I18n.tr("(stopped)") + "*" : ""); color: msg.modelData.ok === false ? Theme.red : Theme.cream
                                   font.family: Theme.font; font.pixelSize: 15; selectionColor: Theme.coffee
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
                    Rectangle { id: liveBox; visible: shell.waiting; x: 28; y: 6; width: Math.min(talk.width * 0.78, liveText.implicitWidth + 28); height: liveText.implicitHeight + 22; radius: 16; color: Theme.card
                        TextEdit { id: liveText; x: 14; y: 11; width: Math.min(talk.width * 0.78 - 28, Math.max(implicitWidth, 80)); readOnly: true; wrapMode: Text.Wrap; textFormat: TextEdit.MarkdownText
                                   text: shell.live !== "" ? shell.live : "*" + I18n.tr("Thinking…") + "*"; color: Theme.cream; font.family: Theme.font; font.pixelSize: 15
                                   onTextChanged: Qt.callLater(talk.positionViewAtEnd) } } }
            }
            Column { visible: !shell.chat && shell.open === ""; anchors.centerIn: parent; anchors.verticalCenterOffset: -50; spacing: 10; width: 460
                Glyph { name: "messages"; font.pixelSize: 48; color: Theme.gold; anchors.horizontalCenter: parent.horizontalCenter }
                Label { text: I18n.tr("A new conversation"); font.pixelSize: 24; font.weight: 800; anchors.horizontalCenter: parent.horizontalCenter }
                Label { width: parent.width; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap; color: Theme.dim
                        text: shell.providers.length ? I18n.tr("Write below. Choose who answers with the button beside the line.") : I18n.tr("No AI is ready on this computer: see Services.") } }
            // the field to write in, in the look of the service that answers (as in LensGoo's AI): Claude's, Gemini's,
            // Grok's, ChatGPT's, or LatteOS's own for a model on this computer or a server of one's own
            Rectangle {
                id: box
                readonly property string style: (shell.providers.find(p => p.id === shell.useProvider) || { style: "own" }).style
                readonly property var look: ({
                    "claude": { bg: "#faf9f5", rim: "#ddd9ce", ink: "#3d3929", dim: "#8a8578", round: 18, send: "#c96442", sendInk: "#ffffff", hint: QT_TR_NOOP("How can I help you today?") },
                    "gemini": { bg: "#f0f4f9", rim: "#f0f4f9", ink: "#1f1f1f", dim: "#5f6368", round: 28, send: "#0b57d0", sendInk: "#ffffff", hint: QT_TR_NOOP("Ask Gemini") },
                    "grok": { bg: "#ffffff", rim: "#e1e1e1", ink: "#0d0d0d", dim: "#8a8a8a", round: 26, send: "#0d0d0d", sendInk: "#ffffff", hint: QT_TR_NOOP("What do you want to know?") },
                    "chatgpt": { bg: "#ffffff", rim: "#e3e3e3", ink: "#0d0d0d", dim: "#8f8f8f", round: 28, send: "#2f7bf5", sendInk: "#ffffff", hint: QT_TR_NOOP("Ask ChatGPT") },
                    "own": { bg: "#3d2c22", rim: "#5a463a", ink: "#f5e8d8", dim: "#b8a491", round: 14, send: Theme.gold, sendInk: "#2a1e17", hint: QT_TR_NOOP("Ask anything…") } })[style] || ({})
                anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: 22; height: 96
                radius: look.round; color: look.bg; border.width: 1; border.color: look.rim
                TextInput { id: line; x: 20; y: 16; width: parent.width - 40; color: box.look.ink; font.family: Theme.font; font.pixelSize: 15; clip: true; selectByMouse: true
                            selectionColor: box.style === "own" ? Theme.coffee : "#c9d7f0"
                            onAccepted: { shell.send(text); text = "" } }
                Text { x: 20; y: 16; visible: line.text === ""; text: I18n.tr(box.look.hint || ""); color: box.look.dim; font.family: Theme.font; font.pixelSize: 15 }
                MouseArea { anchors.fill: parent; anchors.bottomMargin: 44; cursorShape: Qt.IBeamCursor; onClicked: line.forceActiveFocus() }
                // who answers: the one part that is the same for every service; a press goes round them and their models
                Rectangle { id: whoPill; x: 12; anchors.bottom: parent.bottom; anchors.bottomMargin: 10; height: 30; radius: 15; width: whoRow.implicitWidth + 24
                    visible: shell.providers.length > 0; color: box.style === "own" ? "#4a372b" : Qt.darker(box.look.bg, 1.05); border.width: 1; border.color: box.look.rim
                    Row { id: whoRow; x: 12; spacing: 6; anchors.verticalCenter: parent.verticalCenter
                        Text { text: shell.nameOf(shell.useProvider) + " · " + shell.modelName(shell.useProvider, shell.useModel); color: box.look.ink; font.family: Theme.font; font.pixelSize: 13; font.weight: Font.DemiBold }
                        Glyph { name: "chevron-down"; font.pixelSize: 14; color: box.look.dim; anchors.verticalCenter: parent.verticalCenter } }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            const all = []
                            shell.providers.forEach(p => p.models.forEach(m => all.push([p.id, m.id])))
                            const at = all.findIndex(x => x[0] === shell.useProvider && x[1] === shell.useModel)
                            const next = all[(at + 1) % all.length]
                            shell.useProvider = next[0]; shell.useModel = next[1]
                        } } }
                // send, or stop while an answer comes; with an edited question it changes it
                Rectangle { id: send; anchors.right: parent.right; anchors.rightMargin: 12; anchors.bottom: parent.bottom; anchors.bottomMargin: 8; width: 34; height: 34; radius: 17
                    color: box.look.send; opacity: line.text !== "" || shell.waiting ? 1 : 0.4
                    Glyph { anchors.centerIn: parent; name: shell.waiting ? "player-stop" : (shell.editing ? "check" : "arrow-up"); font.pixelSize: 18; color: box.look.sendInk }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: { if (shell.waiting) shell.stop(); else { shell.send(line.text); line.text = "" } } } } }
        }

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
