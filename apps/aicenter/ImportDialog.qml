// LensAI's Import…: the conversations and the memory of ChatGPT, Claude or Gemini brought into LensAI (latte-ai import,
// import-memory; ROADMAP 10B.73). A side window's shape inside LensAI's own (docs/okna/SABLONY.md: a heading with ✕,
// tabs, the buttons at the bottom): which assistant, how its export is made in its own settings, the file chosen with
// Browse… (never a line for a path), or what it remembers pasted, with the question that asks it for that.
//   ImportDialog { id: importer; onImported: list.ask(["chats"]) }   importer.show("chats" | "memory")
import QtQuick
import Quickshell
import Quickshell.Io
import "../common"

Rectangle {
    id: dlg
    signal imported()
    property string tab: "chats"
    property string kind: "chatgpt"
    property string file: ""
    property var result: null                  // what latte-ai said of the last import
    function show(t) { tab = t; file = ""; result = null; visible = true }
    visible: false
    anchors.fill: parent; z: 60
    color: Qt.rgba(0, 0, 0, 0.45)
    MouseArea { anchors.fill: parent; hoverEnabled: true; onClicked: if (!work.running) dlg.visible = false }

    readonly property var names: ({ chatgpt: "ChatGPT", claude: "Claude", gemini: "Gemini" })
    // where each one makes its export, in its own settings (as they are in November 2026)
    readonly property var steps: ({
        chatgpt: [QT_TR_NOOP("In ChatGPT: your name › Settings › Data controls › Export data › Export."),
                  QT_TR_NOOP("An email comes with a download link (it holds for 24 hours): download the .zip."),
                  QT_TR_NOOP("Choose that .zip here. Your saved memories are not in it: paste them on the Memory tab.")],
        claude: [QT_TR_NOOP("On claude.ai: Settings › Privacy › Export data."),
                 QT_TR_NOOP("An email comes with a download link: download the .zip."),
                 QT_TR_NOOP("Choose that .zip here: its conversations and what Claude remembers about you come in together.")],
        gemini: [QT_TR_NOOP("On takeout.google.com: Deselect all, then tick My Activity and in it only Gemini Apps."),
                 QT_TR_NOOP("Under Multiple formats choose JSON for the activity records, then Next step › Create export."),
                 QT_TR_NOOP("Download the .zip from the email and choose it here. Gemini keeps no conversations in it: each day's questions become one.")] })
    readonly property var memorySteps: ({
        chatgpt: QT_TR_NOOP("Ask ChatGPT this in a new conversation (Settings › Personalization › Memory shows what it keeps), copy its answer and paste it below."),
        claude: QT_TR_NOOP("Claude's export brings its memory with the conversations. Or ask Claude this, copy its answer and paste it below."),
        gemini: QT_TR_NOOP("Ask Gemini this (Settings › Saved info shows what it keeps), copy its answer and paste it below.") })
    // the question Claude's own importer gives for another assistant (Anthropic's import-memory): said to that AI, in
    // English as it is written, not shown to be read
    readonly property string prompt: "Export all of my stored memories and any context you've learned about me from past conversations. Preserve my words verbatim where possible, especially for instructions and preferences.\n\n## Categories (output in this order):\n\n1. **Instructions**: Rules I've explicitly asked you to follow going forward — tone, format, style, \"always do X\", \"never do Y\", and corrections to your behavior. Only include rules from stored memories, not from conversations.\n\n2. **Identity**: Name, age, location, education, family, relationships, languages, and personal interests.\n\n3. **Career**: Current and past roles, companies, and general skill areas.\n\n4. **Projects**: Projects I meaningfully built or committed to. Ideally ONE entry per project. Include what it does, current status, and any key decisions. Use the project name or a short descriptor as the first words of the entry.\n\n5. **Preferences**: Opinions, tastes, and working-style preferences that apply broadly.\n\n## Format:\n\nUse section headers for each category. Within each category, list one entry per line, sorted by oldest date first. Format each line as:\n\n[YYYY-MM-DD] - Entry content here.\n\nIf no date is known, use [unknown] instead.\n\n## Output:\n- Wrap the entire export in a single code block for easy copying.\n- After the code block, state whether this is the complete set or if more remain."
    readonly property var errors: ({
        anonymous: QT_TR_NOOP("Not here: an anonymous project of agentgram keeps everything to itself."),
        unknown: QT_TR_NOOP("This is not an export of ChatGPT, Claude or Gemini."),
        "gemini-html": QT_TR_NOOP("Takeout made this export in HTML: make it again with JSON chosen for the activity records."),
        unreadable: QT_TR_NOOP("The file could not be read."),
        "memory-off": QT_TR_NOOP("The memory is off: choose one in Settings › Memory first."),
        "memory-everos": QT_TR_NOOP("Importing into EverOS is not ready yet: choose Basic Memory in Settings › Memory.") })
    function resultLine(r) {
        if (!r) return ""
        if (r.error) return I18n.tr(errors[r.error] || errors.unreadable)
        const said = []
        if (r.new !== undefined) said.push(I18n.tr("{n} conversations imported", { n: r.new + r.updated }))
        if (r.same) said.push(I18n.tr("{n} were here already", { n: r.same }))
        said.push(I18n.tr("{n} notes added to the memory", { n: r.notes || 0 }))
        if (r.memory_error) said.push(I18n.tr(errors[r.memory_error] || errors.unreadable))
        if (r.cut) said.push(I18n.tr("the rest past 64 KB was left out"))
        return said.join(" · ")
    }

    Process { id: picker; command: ["latte-ai", "pick"]
              stdout: StdioCollector { onStreamFinished: { const f = this.text.split("\n")[0].trim(); if (f !== "") { dlg.file = f; dlg.result = null } } } }
    // the pasted text goes by stdin ("-"), never as a word that could be read as a file's path
    Process { id: work; property string buf: ""; property string feed: ""; stdinEnabled: true
              stdout: StdioCollector { onStreamFinished: work.buf = this.text }
              onStarted: { if (feed !== "") write(feed); feed = ""; stdinEnabled = false }
              onExited: { stdinEnabled = true
                          try { dlg.result = JSON.parse(work.buf) } catch (e) { dlg.result = { error: "unreadable" } }
                          if (!dlg.result.error) dlg.imported() } }
    function go() {
        result = null; work.buf = ""
        work.feed = tab === "chats" ? "" : pasted.text.slice(0, 65536)
        work.command = tab === "chats" ? ["latte-ai", "import", file] : ["latte-ai", "import-memory", "-", "--from", kind]
        work.running = true
    }

    Rectangle {
        id: box
        width: Math.min(parent.width - 48, 640); height: Math.min(parent.height - 48, col.implicitHeight + 48)
        anchors.centerIn: parent; radius: 18; color: Theme.ground; border.width: 1; border.color: Theme.line
        MouseArea { anchors.fill: parent }    // a click inside does not close it
        Flickable { ScrollGrip {} anchors.fill: parent; anchors.margins: 24; contentHeight: col.implicitHeight; clip: true; boundsBehavior: Flickable.StopAtBounds
        Column {
            id: col; width: parent.width; spacing: 18
            // the heading, with ✕
            Item { width: parent.width; height: 32
                Row { spacing: 10; anchors.verticalCenter: parent.verticalCenter
                    Glyph { name: "download"; font.pixelSize: 22; color: Theme.gold; anchors.verticalCenter: parent.verticalCenter }
                    Label { text: I18n.tr("Import from another assistant"); font.pixelSize: 18; font.weight: 800; anchors.verticalCenter: parent.verticalCenter } }
                Glyph { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; name: "x"; font.pixelSize: 20; color: Theme.dim
                        Accessible.role: Accessible.Button; Accessible.name: I18n.tr("Close")
                        MouseArea { anchors.fill: parent; anchors.margins: -8; cursorShape: Qt.PointingHandCursor; enabled: !work.running; onClicked: dlg.visible = false } } }
            // the tabs, then which assistant
            Row { spacing: 8
                Pill { implicitHeight: 32; icon: "messages"; text: I18n.tr("Conversations"); strong: dlg.tab === "chats"; onPressed: { dlg.tab = "chats"; dlg.result = null } }
                Pill { implicitHeight: 32; icon: "brain"; text: I18n.tr("Memory"); strong: dlg.tab === "memory"; onPressed: { dlg.tab = "memory"; dlg.result = null } } }
            Rectangle { width: parent.width; height: 1; color: Theme.line }
            Row { spacing: 8
                Repeater { model: ["chatgpt", "claude", "gemini"]
                    Pill { id: who; required property string modelData; implicitHeight: 34; text: dlg.names[who.modelData]; icon: dlg.kind === who.modelData ? "check" : ""
                           strong: dlg.kind === who.modelData; onPressed: { dlg.kind = who.modelData; dlg.result = null } } } }

            // ── conversations: the export's file ──
            Column { visible: dlg.tab === "chats"; width: parent.width; spacing: 10
                Repeater { model: dlg.steps[dlg.kind]
                    Row { id: st; required property string modelData; required property int index; width: parent.width; spacing: 10
                        Rectangle { width: 22; height: 22; radius: 11; color: Theme.raised
                            Label { anchors.centerIn: parent; text: st.index + 1; font.pixelSize: 12; font.weight: 700; color: Theme.gold } }
                        Label { width: parent.width - 32; wrapMode: Text.WordWrap; color: Theme.dim; font.pixelSize: 13; text: I18n.tr(st.modelData) } } }
                Row { spacing: 10; topPadding: 6
                    Pill { implicitHeight: 34; icon: "folder"; text: I18n.tr("Browse…"); enabled: !work.running; onPressed: picker.running = true }
                    Label { width: Math.min(implicitWidth, col.width - 150); elide: Text.ElideMiddle; anchors.verticalCenter: parent.verticalCenter; font.pixelSize: 13
                            color: dlg.file ? Theme.cream : Theme.faint; text: dlg.file ? dlg.file.split("/").pop() : I18n.tr("No file chosen") } } }

            // ── memory: what it remembers, pasted ──
            Column { visible: dlg.tab === "memory"; width: parent.width; spacing: 10
                Label { width: parent.width; wrapMode: Text.WordWrap; color: Theme.dim; font.pixelSize: 13; text: I18n.tr(dlg.memorySteps[dlg.kind]) }
                Rectangle { width: parent.width; height: 110; radius: 14; color: Theme.card; border.width: 1; border.color: Theme.line
                    Flickable { ScrollGrip {} anchors.fill: parent; anchors.margins: 12; anchors.rightMargin: 40; clip: true; contentHeight: promptText.implicitHeight; boundsBehavior: Flickable.StopAtBounds
                        TextEdit { id: promptText; width: parent.width; readOnly: true; selectByMouse: true; wrapMode: Text.Wrap; text: dlg.prompt
                                   color: Theme.dim; font.family: Theme.mono; font.pixelSize: 12; selectionColor: Theme.coffee } }
                    CopyButton { anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 12; copy: dlg.prompt } }
                Rectangle { width: parent.width; height: 170; radius: 14; color: Theme.card; border.width: 1; border.color: pasted.activeFocus ? Theme.gold : Theme.line
                    Flickable { ScrollGrip {} anchors.fill: parent; anchors.margins: 12; clip: true; contentHeight: pasted.implicitHeight; boundsBehavior: Flickable.StopAtBounds
                        TextEdit { id: pasted; width: parent.width; wrapMode: Text.Wrap; color: Theme.cream; font.family: Theme.font; font.pixelSize: 14; selectByMouse: true; selectionColor: Theme.coffee } }
                    Label { x: 12; y: 12; visible: pasted.text === ""; color: Theme.faint; font.pixelSize: 14; text: I18n.tr("Paste {n}'s answer here", { n: dlg.names[dlg.kind] }) } }
                Label { visible: pasted.text.length > 65536; color: Theme.red; font.pixelSize: 12; text: I18n.tr("Over 64 KB: only the first 64 KB are imported.") } }

            // what came of it, and the buttons
            Row { visible: work.running || dlg.result !== null; width: parent.width; spacing: 8
                Glyph { name: work.running ? "history" : dlg.result && dlg.result.error ? "alert-triangle" : "check"; font.pixelSize: 16; anchors.verticalCenter: parent.verticalCenter
                        color: work.running ? Theme.dim : dlg.result && dlg.result.error ? Theme.red : Theme.ok }
                Label { width: parent.width - 30; wrapMode: Text.WordWrap; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter
                        color: dlg.result && dlg.result.error ? Theme.red : Theme.cream
                        text: work.running ? I18n.tr("Importing…") : dlg.resultLine(dlg.result) } }
            Item { width: parent.width; height: 36
                Row { anchors.right: parent.right; spacing: 10
                    Pill { implicitHeight: 36; text: I18n.tr("Close"); enabled: !work.running; onPressed: dlg.visible = false }
                    Pill { implicitHeight: 36; icon: "download"; strong: true; busy: work.running; text: I18n.tr("Import")
                           opacity: (dlg.tab === "chats" ? dlg.file !== "" : pasted.text.trim() !== "") ? 1 : 0.5
                           onPressed: if (dlg.tab === "chats" ? dlg.file !== "" : pasted.text.trim() !== "") dlg.go() } } }
        } }
    }
}
