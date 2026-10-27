// LensShore: the launcher built around the AI, instead of the drop LensGoo when Settings › Drops › Launcher says so
// (ROADMAP 6B.12). The island of K4 (https://github.com/k4ditano/k4, MIT): at rest a small piece of goo at the top
// or the bottom edge with a line to type into; typed into, it grows away from the edge, the line staying where it is,
// and shows what was found nearest the line first: the apps as icons in a row, the files and folders whose name
// begins with what is typed, then the web. A click opens one; Enter or the send button ask the default AI, whose
// answer comes in the island. The right button: unlock the place, then drag it to the other edge.
// It ends itself when the Settings turn it off; the Goo scene starts it (goo/lib/lens.luau) and passes it the
// Windows key (qs ipc … call lens toggle).
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "common"
import "lensshore"

ShellRoot {
    id: shell
    readonly property string data: (Quickshell.env("XDG_DATA_HOME") || (Quickshell.env("HOME") + "/.local/share")) + "/pleamar/goo"
    readonly property string home: Quickshell.env("HOME") || ""

    // ── what the Goo keeps: on or off, and the edge ────────────────────────────────────────────────────────
    property var kept: ({})
    readonly property bool top: kept.lens_top !== false          // the top unless the user dragged it down
    FileView {
        path: shell.data + "/settings.json"
        printErrors: false; watchChanges: true
        onFileChanged: reload()
        onLoaded: { try { shell.kept = JSON.parse(text()) } catch (e) { shell.kept = {} } if (shell.kept.lens !== "shore") Qt.quit() }
        onLoadFailed: Qt.quit()
        function put(key, value) { const k = Object.assign({}, shell.kept); k[key] = value; shell.kept = k; setText(JSON.stringify(k)) }
        id: settings
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
    readonly property color ink: Theme.inkOnCoffee
    readonly property color soft: Qt.rgba(ink.r, ink.g, ink.b, 0.55)
    readonly property color lit: Qt.rgba(ink.r, ink.g, ink.b, 0.1)

    // ── what is typed, and what was found for it ───────────────────────────────────────────────────────────
    property string q: ""
    property bool open: false
    property bool locked: true
    property bool more: false                  // "More" in the apps: every match, not a row of six
    property bool moreFiles: false
    property bool asking: false                // the island shows the conversation with the AI
    readonly property var apps: {
        const want = q.trim().toLowerCase()
        if (want === "") return []
        const all = DesktopEntries.applications.values.filter(e => !e.noDisplay)
        const starts = [], within = []
        for (const e of all) {
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
            const want = shell.q.trim().toLowerCase(), a = [], b = []
            for (const p of this.text.split("\n").filter(l => l !== "")) {
                const name = p.replace(/\/$/, "").split("/").pop().toLowerCase()
                ;(name.startsWith(want) ? a : b).push(p)
            }
            shell.files = a.concat(b); shell.looking = false
        } }
    }
    Timer { id: pause; interval: 160
            onTriggered: { const t = shell.q.trim(); shell.files = []; if (t === "") return; shell.looking = true
                           fd.running = false; fd.command = ["fd", "--max-results", "14", "--absolute-path", "--ignore-case", "--", t, shell.home]; fd.running = true } }
    onQChanged: { more = false; moreFiles = false; if (q !== "") { asking = false; open = true } pause.restart() }

    // the user's search engine, as LensGoo keeps it
    property string engine: "duckduckgo"
    readonly property var engines: ({ duckduckgo: ["DuckDuckGo", "https://duckduckgo.com/?q=%s"], google: ["Google", "https://www.google.com/search?q=%s"],
                                     bing: ["Bing", "https://www.bing.com/search?q=%s"], startpage: ["Startpage", "https://www.startpage.com/do/search?q=%s"],
                                     ecosia: ["Ecosia", "https://www.ecosia.org/search?q=%s"], brave: ["Brave Search", "https://search.brave.com/search?q=%s"] })
    property var lensKept: ({})
    FileView { path: shell.data + "/lens.json"; printErrors: false
               onLoaded: { try { shell.lensKept = JSON.parse(text()); shell.engine = shell.lensKept.engine || "duckduckgo" } catch (e) {} } }

    function go(cmd) { Quickshell.execDetached(cmd); close(true) }
    function close(clear) { open = false; asking = false; if (clear) q = "" }

    // ── the AI: the user's default, as LensGoo chooses it; the answer comes in pieces ───────────────────────
    property var provider: null
    property string modelId: ""
    property string chat: "new"
    property var talk: []                      // [{ mine, text }]
    property string live: ""
    Process { command: ["latte-ai", "providers"]; running: true
              stdout: StdioCollector { onStreamFinished: {
                  let list = []
                  try { list = JSON.parse(this.text) } catch (e) {}
                  const want = (shell.lensKept.ai || {})
                  shell.provider = list.find(p => p.id === want.provider) || list[0] || null
                  if (shell.provider) shell.modelId = ((shell.provider.models || []).find(m => m.id === want.model) || (shell.provider.models || [])[0] || { id: "" }).id
              } } }
    Process {
        id: ask
        stdout: SplitParser { onRead: line => {
            let m = null
            try { m = JSON.parse(line) } catch (e) { return }
            if (m.delta) shell.live += m.delta
            else if (m.chat) { shell.chat = m.chat; shell.talk = shell.talk.concat([{ mine: false, text: m.answer || "" }]); shell.live = "" }
        } }
        onExited: if (shell.live !== "") { shell.talk = shell.talk.concat([{ mine: false, text: shell.live }]); shell.live = "" }
    }
    // Enter or the send button: always the AI (6B.12); with the AI off, the first thing found is opened
    function send() {
        const t = q.trim()
        if (t === "") return
        if (!provider) { if (apps.length) { apps[0].execute(); close(true) } else if (files.length) go(["xdg-open", files[0].replace(/\/$/, "")]); return }
        talk = talk.concat([{ mine: true, text: t }]); live = ""; asking = true; open = true
        ask.running = false
        ask.command = ["latte-ai", "send", chat, provider.id, modelId, t, "--stream"]
        ask.running = true
        q = ""; asking = true
    }

    IpcHandler {
        target: "lens"
        function toggle(): void { if (shell.open) shell.close(false); else { shell.open = true; field.forceActiveFocus() } }
    }

    // ── the island ─────────────────────────────────────────────────────────────────────────────────────────
    readonly property int lineH: 46
    readonly property int restW: 520
    readonly property int openW: 720

    PanelWindow {
        id: win
        WlrLayershell.namespace: "latte-lensshore"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: shell.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.OnDemand
        anchors { left: true; right: true; top: shell.top; bottom: !shell.top }
        implicitHeight: 700
        exclusiveZone: shell.top ? shell.lineH : 0     // at the top windows leave it its strip; at the bottom the goo has its own
        color: "transparent"
        mask: Region { item: island
                       Region { item: shell.open ? catcher : null; intersection: Intersection.Combine }
                       Region { item: menu.visible ? menu : null; intersection: Intersection.Combine } }

        // a press anywhere else lets it shrink back, as Esc does; what was typed stays
        MouseArea { id: catcher; anchors.fill: parent; enabled: shell.open; onPressed: shell.close(false) }

        Item {
            id: island
            readonly property real contentH: shell.open ? Math.min(body.implicitHeight + 20, win.height - shell.lineH - 40) : 0
            width: shell.open ? shell.openW : shell.restW
            height: shell.lineH + contentH
            x: (parent.width - width) / 2
            y: shell.top ? 0 : parent.height - height
            Behavior on width { NumberAnimation { duration: 380; easing.type: Easing.OutBack; easing.overshoot: 0.42 } }
            Behavior on height { NumberAnimation { duration: 420; easing.type: Easing.OutBack; easing.overshoot: 0.32 } }
            Keys.onEscapePressed: shell.close(false)

            SiluetaIsla { x: -16; width: parent.width + 32; height: parent.height; relleno: shell.goo; reflejada: !shell.top }

            // ── the line, at the edge side ──
            Item {
                id: line
                width: parent.width; height: shell.lineH
                y: shell.top ? 0 : parent.height - height
                Glyph { x: 18; name: "search"; font.pixelSize: 18; color: shell.soft; anchors.verticalCenter: parent.verticalCenter }
                TextInput {
                    id: field
                    x: 48; width: parent.width - 48 - 52; anchors.verticalCenter: parent.verticalCenter
                    color: shell.ink; font.family: Theme.font; font.pixelSize: 15; clip: true; selectByMouse: true
                    selectionColor: Qt.rgba(1, 1, 1, 0.2)
                    text: shell.q; onTextEdited: shell.q = text
                    onAccepted: shell.send()
                    Keys.onEscapePressed: shell.close(false)
                    Label { text: I18n.tr("Search or ask…"); color: shell.soft; visible: field.text === ""; font.pixelSize: 15; anchors.verticalCenter: parent.verticalCenter }
                }
                // send: lit when there is something to send
                Rectangle {
                    width: 30; height: 30; radius: 15; anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter
                    color: shell.q.trim() !== "" ? Theme.gold : (sendHit.containsMouse ? shell.lit : "transparent")
                    Glyph { anchors.centerIn: parent; name: "arrow-up"; font.pixelSize: 16; color: shell.q.trim() !== "" ? "#2a170c" : shell.soft }
                    MouseArea { id: sendHit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: shell.send() }
                }
                // the right button: the place, and what every field has
                MouseArea {
                    anchors.fill: parent; acceptedButtons: Qt.RightButton
                    property real fromY: 0
                    onPressed: mouse => { const at = mapToItem(menu, mouse.x, mouse.y); menu.popupAt(at.x, shell.top ? at.y : at.y - 190) }
                }
                // unlocked, it is dragged to the other edge
                MouseArea {
                    anchors.fill: parent; enabled: !shell.locked; cursorShape: Qt.SizeVerCursor
                    property real fromY: 0
                    onPressed: mouse => fromY = mapToGlobal(mouse.x, mouse.y).y
                    onReleased: mouse => {
                        const moved = mapToGlobal(mouse.x, mouse.y).y - fromY
                        if ((shell.top && moved > 120) || (!shell.top && moved < -120)) settings.put("lens_top", !shell.top)
                    }
                }
            }

            // ── what was found, away from the edge; nearest the line what is looked for most ──
            Flickable {
                id: scroll
                x: 16; width: parent.width - 32
                y: shell.top ? shell.lineH + 6 : 14
                height: Math.max(0, island.contentH - 20)
                contentHeight: body.implicitHeight; clip: true
                opacity: shell.open ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 200 } }
                // at the bottom the list stands on the line: it begins at its foot
                contentY: shell.top ? 0 : Math.max(0, contentHeight - height)

                Column {
                    id: body
                    width: scroll.width
                    spacing: 14
                    // the sections: nearest the line what is looked for most, at the top and at the bottom alike
                    Repeater {
                        model: shell.top ? ["apps", "files", "web", "ai", "hint"] : ["hint", "ai", "web", "files", "apps"]
                        Loader { required property string modelData; width: body.width
                                 sourceComponent: ({ apps: appsPart, files: filesPart, web: webPart, ai: aiPart, hint: hintPart })[modelData] }
                    }
                }
            }
            Component { id: hintPart
                        Column { width: parent ? parent.width : 0; visible: !shell.asking && shell.q.trim() === ""
                            Label { text: shell.provider ? I18n.tr("Type to search; Enter asks the AI") : I18n.tr("Type to search"); color: shell.soft; leftPadding: 6 } } }
            Component { id: aiPart
                        Column { id: aiCol; width: parent ? parent.width : 0; spacing: 10; visible: shell.asking
                            Repeater { model: shell.talk.slice(-6)
                                Rectangle { required property var modelData
                                    width: Math.min(parent.width * 0.85, said.implicitWidth + 24); height: said.implicitHeight + 16; radius: 14
                                    x: modelData.mine ? parent.width - width : 0
                                    color: modelData.mine ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
                                    TextEdit { id: said; x: 12; y: 8; width: Math.min(aiCol.width * 0.85 - 24, implicitWidth); readOnly: true; selectByMouse: true; wrapMode: Text.Wrap
                                               text: parent.modelData.text; color: shell.ink; font.family: Theme.font; font.pixelSize: 14 } } }
                            Label { visible: shell.live !== "" || ask.running; width: parent.width; wrapMode: Text.Wrap; leftPadding: 12
                                    text: shell.live !== "" ? shell.live : I18n.tr("Thinking…"); color: shell.live !== "" ? shell.ink : shell.soft }
                            Row { spacing: 8
                                Pill { text: I18n.tr("New conversation"); icon: "plus"; onPressed: { shell.chat = "new"; shell.talk = []; shell.live = ""; field.forceActiveFocus() } } }
                        } }
            Component { id: webPart
                        Column { width: parent ? parent.width : 0; spacing: 4; visible: !shell.asking && shell.q.trim() !== ""
                            Section { text: I18n.tr("Internet") }
                            Row_ { glyph: "world"; label: I18n.tr("Search for “{what}” on {engine}", { what: shell.q.trim(), engine: (shell.engines[shell.engine] || shell.engines.duckduckgo)[0] })
                                   onRun: shell.go(["xdg-open", (shell.engines[shell.engine] || shell.engines.duckduckgo)[1].replace("%s", encodeURIComponent(shell.q.trim()))]) } } }
            Component { id: filesPart
                        Column { width: parent ? parent.width : 0; spacing: 4; visible: !shell.asking && shell.q.trim() !== ""
                            Section { text: I18n.tr("Files and folders") }
                            Label { visible: shell.files.length === 0; leftPadding: 6; color: shell.soft; text: shell.looking ? I18n.tr("Searching…") : I18n.tr("Nothing found") }
                            Repeater { model: shell.files.slice(0, shell.moreFiles ? 12 : 4)
                                Row_ { required property string modelData
                                       readonly property string clean: modelData.replace(/\/$/, "")
                                       glyph: modelData.endsWith("/") ? "folder" : "file"; label: clean.split("/").pop()
                                       hint: clean.substring(0, clean.lastIndexOf("/")).replace(shell.home, "~")
                                       onRun: shell.go(["xdg-open", clean]) } }
                            Row_ { visible: shell.files.length > 4 && !shell.moreFiles; glyph: "dots"; label: I18n.tr("More files"); onRun: shell.moreFiles = true } } }
            Component { id: appsPart
                        Column { width: parent ? parent.width : 0; spacing: 6; visible: !shell.asking && shell.apps.length > 0
                            Section { text: I18n.tr("Applications") }
                            Flow { width: parent.width; spacing: 6
                                Repeater { model: shell.apps.slice(0, shell.more ? 18 : 6)
                                    Rectangle { required property var modelData
                                        width: 104; height: 86; radius: 14; color: tileHit.containsMouse ? shell.lit : "transparent"
                                        Image { width: 40; height: 40; anchors.horizontalCenter: parent.horizontalCenter; y: 10; sourceSize: Qt.size(80, 80)
                                                source: Quickshell.iconPath(parent.modelData.icon, "application-x-executable") }
                                        Label { width: parent.width - 8; anchors.horizontalCenter: parent.horizontalCenter; y: 58; horizontalAlignment: Text.AlignHCenter
                                                text: parent.modelData.name; color: shell.ink; font.pixelSize: 12 }
                                        MouseArea { id: tileHit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                    onClicked: { parent.modelData.execute(); shell.close(true) } } } }
                                Rectangle { visible: shell.apps.length > 6 && !shell.more; width: 104; height: 86; radius: 14; color: moreHit.containsMouse ? shell.lit : "transparent"
                                    Glyph { anchors.horizontalCenter: parent.horizontalCenter; y: 18; name: "dots"; font.pixelSize: 26; color: shell.soft }
                                    Label { width: parent.width; y: 58; horizontalAlignment: Text.AlignHCenter; text: I18n.tr("More"); color: shell.soft; font.pixelSize: 12 }
                                    MouseArea { id: moreHit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: shell.more = true } } } } }
        }
        // the right button's menu, over the island
        Menu { id: menu
               function popupAt(x, y) {
                   open(x, y, [{ icon: shell.locked ? "lock-open" : "lock", text: shell.locked ? I18n.tr("Unlock position") : I18n.tr("Lock position"), run: () => shell.locked = !shell.locked },
                           { line: true },
                           { icon: "cut", text: I18n.tr("Cut"), hint: "Ctrl+X", enabled: field.selectedText !== "", run: () => field.cut() },
                           { icon: "copy", text: I18n.tr("Copy"), hint: "Ctrl+C", enabled: field.selectedText !== "", run: () => field.copy() },
                           { icon: "clipboard", text: I18n.tr("Paste"), hint: "Ctrl+V", enabled: field.canPaste, run: () => field.paste() }])
               } }
    }

    component Section: Label { color: shell.soft; font.pixelSize: 12; font.weight: 700; leftPadding: 6; font.capitalization: Font.AllUppercase }
    component Row_: Rectangle {
        id: row
        property string glyph
        property string label
        property string hint
        signal run()
        width: parent ? parent.width : 0; height: 38; radius: 10
        color: rowHit.containsMouse ? shell.lit : "transparent"
        Glyph { x: 12; name: row.glyph; font.pixelSize: 17; color: shell.soft; anchors.verticalCenter: parent.verticalCenter }
        Label { x: 42; width: parent.width - 54 - hintText.implicitWidth; text: row.label; color: shell.ink; anchors.verticalCenter: parent.verticalCenter }
        Label { id: hintText; anchors.right: parent.right; anchors.rightMargin: 12; text: row.hint; color: shell.soft; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth, parent.width * 0.45) }
        MouseArea { id: rowHit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: row.run() }
    }
}
