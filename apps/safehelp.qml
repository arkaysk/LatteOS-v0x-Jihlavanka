//@ pragma AppId latteos-safehelp
// AI help in SAFE (ROADMAP order of work, C; the user 21. 11.): LensAI's smallest window, for when the desktop did not
// start. It asks through the AI services this computer is already signed in to (their CLI or a key, `latte-ai send`), so
// nobody signs in again; the conversation is kept as LensAI's ("from": safe) and can be gone on with there later.
// One column: who answers, what was said, the field. No web pages, no glass: SAFE draws on the processor.
import QtQuick
import Quickshell
import Quickshell.Io
import "common"

ShellRoot {
    id: shell
    property var providers: []
    property string provider: ""
    property string model: ""
    property string chat: "new"
    property var said: []                      // [{ mine, text }]
    property bool waiting: false
    readonly property var useP: providers.find(p => p.id === provider) || null

    // what the person should be helped with is said first: SAFE, and how to reach the person's own desktop again
    readonly property string first: I18n.tr("I am in LatteOS's SAFE mode (the plain desktop that starts when the normal one does not). Help me find out what went wrong and how to get my desktop back; give commands one at a time and say what each does.") + "\n\n"

    Process { id: whoq; command: ["latte-ai", "providers"]; running: true
        stdout: StdioCollector { onStreamFinished: { try { shell.providers = JSON.parse(this.text) } catch (e) { shell.providers = [] }
                                                     if (!shell.useP && shell.providers.length) { shell.provider = shell.providers[0].id; shell.model = shell.providers[0].models[0].id } } } }
    Process { id: asker
        stdout: StdioCollector { onStreamFinished: {
            let r = null
            try { r = JSON.parse(this.text.trim().split("\n").pop()) } catch (e) { }
            shell.said = shell.said.concat([{ mine: false, text: r ? (r.answer || I18n.tr("No answer came.")) : I18n.tr("No answer came.") }])
            if (r && r.chat) shell.chat = r.chat
            shell.waiting = false } } }
    function ask(text) {
        text = text.trim()
        if (text === "" || waiting || provider === "") return
        said = said.concat([{ mine: true, text: text }])
        waiting = true
        asker.command = ["latte-ai", "send", chat, provider, model, (chat === "new" ? first : "") + text, "--markdown", "--from", "safe"]
        asker.running = true
    }

    AppWindow {
        title: "LatteOS SAFE · AI"
        heading: I18n.tr("Ask the AI for help")
        sideWidth: 0
        implicitWidth: 760; implicitHeight: 620
        tools: [
            // who answers: the services signed in on this computer, as LensAI lists them
            Pill { implicitHeight: 32; icon: "sparkles"; text: shell.useP ? shell.useP.name : I18n.tr("No AI service is installed: see Settings.")
                   onPressed: { const i = shell.providers.findIndex(p => p.id === shell.provider); const n = shell.providers[(i + 1) % Math.max(1, shell.providers.length)]
                                if (n) { shell.provider = n.id; shell.model = n.models[0].id; shell.chat = "new"; shell.said = [] } } }
        ]
        Item {
            anchors.fill: parent
            ListView { id: talk
                x: 20; y: 16; width: parent.width - 40; height: parent.height - field.height - 48; clip: true; spacing: 10
                model: shell.said
                onCountChanged: positionViewAtEnd()
                delegate: Rectangle { required property var modelData
                    width: Math.min(talk.width * (modelData.mine ? 0.8 : 1), msg.implicitWidth + 28); height: msg.implicitHeight + 20; radius: 14
                    x: modelData.mine ? talk.width - width : 0
                    color: modelData.mine ? Theme.raised : Theme.card
                    TextEdit { id: msg; x: 14; y: 10; width: Math.min(talk.width * 0.8 - 28, Math.max(implicitWidth, 40)); readOnly: true; selectByMouse: true
                               wrapMode: Text.Wrap; textFormat: parent.modelData.mine ? TextEdit.PlainText : TextEdit.MarkdownText
                               text: parent.modelData.text; color: Theme.cream; font.family: Theme.font; font.pixelSize: 14 } }
                Label { visible: shell.said.length === 0; anchors.centerIn: parent; width: parent.width * 0.8; wrapMode: Text.WordWrap; horizontalAlignment: Text.AlignHCenter
                        color: Theme.dim; text: I18n.tr("The AI you are already signed in to answers here, without signing in again. Say what went wrong.") }
            }
            Waiting { visible: shell.waiting; x: 20; y: talk.y + talk.height - 30; text: I18n.tr("Waiting for the answer…") }
            Field { id: field; x: 20; width: parent.width - 40; anchors.bottom: parent.bottom; anchors.bottomMargin: 16; icon: "sparkles"
                    hint: I18n.tr("Ask, or say what should be done"); onAccepted: { shell.ask(text); text = "" } }
        }
    }
}
