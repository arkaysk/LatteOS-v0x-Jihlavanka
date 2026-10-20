// Lens AI centre: every conversation with every AI in one list, and the services themselves — which are there,
// which one is signed in, signing in and out. bin/latte-ai keeps the conversations (the same ones LensGoo's AI
// tab writes) and knows the services; this window shows them.   latte-app aicenter [services | CHAT]
//
// The side: all conversations or one service's, newest first, each marked with its service's colour; at the
// bottom the services. A conversation opens on the right and goes on there, with the service and model it had.
import QtQuick
import Quickshell
import Quickshell.Io
import "common"

ShellRoot {
    id: shell
    readonly property var words: (Quickshell.env("LATTE_APP_ARGS") || "").split("\n").filter(w => w !== "")
    property string page: "chats"              // chats · services
    property string only: ""                   // the side shows only this service's conversations; "" all
    property string open: ""                   // the conversation shown
    property string find: ""
    property var chats: []
    property var chat: null
    property var providers: []                 // what can answer now (latte-ai providers)
    property var services: []                  // every service known (latte-ai services)
    property bool waiting: false
    // each service has its colour, so that a conversation is known by it at a glance
    readonly property var colours: ({ "claude": "#d97757", "gemini": "#4285f4", "chatgpt": "#10a37f", "grok": "#a8a8a8", "ollama": Theme.gold })
    function colour(id) { return colours[id] || Theme.gold }
    function nameOf(id) { const p = services.find(s => s.id === id); return p ? p.name : id }
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
    Ask { id: sender; onDone: { shell.waiting = false; if (data && data.chat) shell.open = data.chat; shell.reload() } }
    Ask { id: forget; onDone: { shell.open = ""; shell.chat = null; list.ask(["chats"]) } }
    function reload() { list.ask(["chats"]); if (open !== "") one.ask(["chat", open]) }
    function choose(id) { open = id; page = "chats"; chat = null; one.ask(["chat", id]) }
    // a command to sign in or out runs in a terminal: the tool asks there what it needs
    function inTerminal(argv) { Quickshell.execDetached(["foot", "-e", "sh", "-c", argv.map(a => "'" + a.replace(/'/g, "'\\''") + "'").join(" ") + "; echo; read -p '" + I18n.tr("Press Enter to close") + "' x"]) }
    Timer { id: later; interval: 2500; onTriggered: svc.ask(["services"]) }
    Component.onCompleted: {
        list.ask(["chats"]); who.ask(["providers", "all"]); svc.ask(["services"])
        if (words[0] === "services") page = "services"
        else if (words[0]) choose(words[0])
    }

    // what the conversation goes on with: its own service and model, or the first there is for a new one
    property string useProvider: chat ? chat.provider : (providers.length ? providers[0].id : "")
    property string useModel: chat ? chat.model : (providers.length ? providers[0].models[0].id : "")
    function send(text) {
        if (text.trim() === "" || waiting || useProvider === "") return
        waiting = true
        if (chat) chat = Object.assign({}, chat, { messages: chat.messages.concat([{ role: "user", content: text, provider: useProvider, model: useModel }]) })
        sender.ask(["send", open !== "" ? open : "new", useProvider, useModel, text])
    }

    AppWindow {
        title: I18n.tr("Lens AI centre")
        heading: shell.page === "services" ? I18n.tr("Services") : (shell.chat ? shell.chat.title : I18n.tr("Conversations"))
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
                    Nav { required property var modelData; text: modelData.name; icon: "point-filled"; height: 34
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
                Nav { text: I18n.tr("Services"); icon: "plug-connected"; on: shell.page === "services"; onPressed: { shell.page = "services"; svc.ask(["services"]) } }
            }
        ]

        // ── a conversation: its messages, and the line to go on with it ─────────────────────────────────────
        Item {
            anchors.fill: parent
            visible: shell.page === "chats"
            ListView {
                id: talk
                anchors.fill: parent; anchors.bottomMargin: 92
                clip: true; spacing: 14; topMargin: 24; bottomMargin: 16
                model: shell.chat ? shell.chat.messages : []
                onCountChanged: Qt.callLater(positionViewAtEnd)
                delegate: Item { id: msg; required property var modelData; width: talk.width; height: bubble.height + 22
                    readonly property bool mine: modelData.role === "user"
                    Label { x: msg.mine ? talk.width - 28 - width : 28; text: msg.mine ? I18n.tr("You") : shell.nameOf(msg.modelData.provider) + " · " + shell.modelName(msg.modelData.provider, msg.modelData.model)
                            color: msg.mine ? Theme.gold : shell.colour(msg.modelData.provider); font.pixelSize: 11; font.weight: 700 }
                    Rectangle { id: bubble; y: 20; x: msg.mine ? talk.width - 28 - width : 28; width: Math.min(talk.width * 0.78, said.implicitWidth + 28); height: said.implicitHeight + 22; radius: 16
                        color: msg.mine ? Qt.rgba(Theme.gold.r, Theme.gold.g, Theme.gold.b, 0.14) : Theme.card
                        border.width: msg.mine ? 0 : 1; border.color: Qt.rgba(Qt.color(shell.colour(msg.modelData.provider)).r, Qt.color(shell.colour(msg.modelData.provider)).g, Qt.color(shell.colour(msg.modelData.provider)).b, 0.45)
                        TextEdit { id: said; x: 14; y: 11; width: Math.min(talk.width * 0.78 - 28, implicitWidth); readOnly: true; selectByMouse: true; wrapMode: Text.Wrap
                                   text: msg.modelData.content; color: msg.modelData.ok === false ? Theme.red : Theme.cream; font.family: Theme.font; font.pixelSize: 15; selectionColor: Theme.coffee
                                   Component.onCompleted: width = Math.min(talk.width * 0.78 - 28, implicitWidth) } } }
                footer: Item { width: talk.width; height: shell.waiting ? 40 : 0
                    Label { x: 28; visible: shell.waiting; text: I18n.tr("Thinking…"); color: Theme.dim } }
            }
            Column { visible: !shell.chat && shell.open === ""; anchors.centerIn: parent; anchors.verticalCenterOffset: -50; spacing: 10; width: 460
                Glyph { name: "messages"; font.pixelSize: 48; color: Theme.gold; anchors.horizontalCenter: parent.horizontalCenter }
                Label { text: I18n.tr("A new conversation"); font.pixelSize: 24; font.weight: 800; anchors.horizontalCenter: parent.horizontalCenter }
                Label { width: parent.width; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap; color: Theme.dim
                        text: shell.providers.length ? I18n.tr("Write below. Choose who answers with the button beside the line.") : I18n.tr("No AI is ready on this computer: see Services.") } }
            // the line to write in, with who answers on a button that goes round the services and their models
            Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: 22; height: 54; radius: 18; color: Theme.card
                border.width: 1; border.color: Qt.rgba(Qt.color(shell.colour(shell.useProvider)).r, Qt.color(shell.colour(shell.useProvider)).g, Qt.color(shell.colour(shell.useProvider)).b, 0.5)
                Field { id: line; x: 8; width: parent.width - 230; anchors.verticalCenter: parent.verticalCenter; icon: "sparkles"; hint: I18n.tr("Write a message…")
                        onAccepted: { shell.send(text); text = "" } }
                Pill { id: whoPill; anchors.right: send.left; anchors.rightMargin: 8; anchors.verticalCenter: parent.verticalCenter; implicitHeight: 34
                       visible: shell.providers.length > 0; icon: "chevron-down"; text: shell.nameOf(shell.useProvider) + " · " + shell.modelName(shell.useProvider, shell.useModel)
                       onPressed: {
                           const all = []
                           shell.providers.forEach(p => p.models.forEach(m => all.push([p.id, m.id])))
                           const at = all.findIndex(x => x[0] === shell.useProvider && x[1] === shell.useModel)
                           const next = all[(at + 1) % all.length]
                           shell.useProvider = next[0]; shell.useModel = next[1]
                       } }
                Pill { id: send; anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter; implicitHeight: 34
                       icon: "arrow-up"; strong: true; busy: shell.waiting; text: I18n.tr("Send"); onPressed: { shell.send(line.text); line.text = "" } } }
        }

        // ── the services: which are there, which is signed in; signing in and out ────────────────────────────
        Scroll {
            id: svcPage
            visible: shell.page === "services"
            Label { width: svcPage.room; wrapMode: Text.WordWrap; color: Theme.dim
                    text: I18n.tr("The official tool of a service answers, with the account you sign in to it with. LatteOS keeps no key and no password of yours. Which of them LensGoo offers is set in Settings › Launcher.") }
            Repeater { model: shell.services
                Rectangle { id: card; required property var modelData; width: svcPage.room; height: 84; radius: 20; color: Theme.card
                    Rectangle { x: 18; width: 48; height: 48; radius: 14; color: shell.colour(card.modelData.id); opacity: card.modelData.installed ? 1 : 0.35; anchors.verticalCenter: parent.verticalCenter
                        Glyph { anchors.centerIn: parent; name: card.modelData.local ? "device-desktop" : "cloud"; font.pixelSize: 22; color: "#ffffff" } }
                    Column { x: 82; width: parent.width - 82 - 300; anchors.verticalCenter: parent.verticalCenter; spacing: 4
                        Label { text: card.modelData.name; font.pixelSize: 16; font.weight: 700 }
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
        }
    }
}
