// The window every LatteOS app lives in.
//
//   ┌────────────┬──────────────────────────────────────────────┐
//   │            │ ‹ ›   Heading          tools   search  NET  ✕ │   the header: what the app can do; it carries the window
//   │   side     ├──────────────────────────────────────────────┤
//   │  (glass,   │                                              │
//   │  top to    │   what the app shows                         │
//   │  bottom)   │                                              │
//   │            │ ~~~~~~~~~~~~~ the coffee ~~~~~~~~~~~~~~~~~~~ │   `foot`: what stands in it, when the app has a lower part
//   └────────────┴──────────────────────────────────────────────┘
//
// The side is a pane of glass from the top of the window to its bottom: the pages of the app, its places, what it
// keeps at hand. Right of it everything is solid. The coffee is the line between the app's upper and lower part
// when it has a lower one (`foot`); when it has none the coffee only moves quietly behind what the app shows.
// Minimise and maximise are there only where windows float: on the tape and in tiles they would do nothing.
//
//   AppWindow { heading: "…"; side: [ … ]; tools: [ … ]; foot: [ … ]; searchHint: "…"; onSearched: text => …
//               arrows: true; canGoBack: …; onBack: …        … what the app shows … }
import QtQuick
import Quickshell
import Quickshell.Io

FloatingWindow {
    id: win
    property string heading
    property real sideWidth: 250
    property alias side: sidePane.data
    property alias tools: toolRow.data
    property alias foot: sea.content
    default property alias content: body.data
    property real footDepth: 58
    property color ground: Theme.ground        // what the app stands on; "transparent" lets a glass page of its own through
    readonly property bool hasFoot: sea.content.length > 0

    property bool arrows: false                // the app has pages one goes back from
    property bool canGoBack: false
    property bool canGoForward: false
    signal back()
    signal forward()
    property string searchHint: ""             // with a hint the header has a field to search in
    property alias searchText: field.text
    signal searched(string text)

    color: "transparent"
    onClosed: Qt.quit()

    // how windows are arranged now, as the compositor keeps it for whoever asks
    property string mode: "tape"
    // "on" or "off" while this app can be cut off the internet (bin/latte-net), "" when nothing here does that
    property string net: ""
    Process { id: net; command: ["latte-net", "status", String(Quickshell.processId)]; running: true
              stdout: StdioCollector { onStreamFinished: { const said = this.text.trim(); win.net = said === "on" || said === "off" ? said : "" } } }
    // the mode of every screen on the first line, a screen's own after it ("DP-1 tiles"): this window's screen's
    FileView {
        id: modeFile
        path: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/latteos/window-mode"
        printErrors: false; watchChanges: true
        onFileChanged: reload()
        onLoaded: win.readMode()
    }
    onScreenChanged: readMode()
    function readMode() {
        const lines = modeFile.text().split("\n"), own = lines.slice(1).map(l => l.trim().split(/\s+/)).find(w => w.length === 2 && win.screen && w[0] === win.screen.name)
        win.mode = own ? own[1] : ((lines[0] || "").trim() || "tape")
    }
    function ask(what) { Quickshell.execDetached(["hyprctl", "eval", "latte.win." + what + "()"]) }
    // the window's menu in a Goo card, where the pointer is, as the right button on any title bar gives it (system/hypr/latte/bars.lua)
    function menu() {
        Quickshell.execDetached(["sh", "-c", "a=$(hyprctl -j activewindow | sed -n 's/.*\"address\": *\"\\(0x[0-9a-f]*\\)\".*/\\1/p'); set -- $(hyprctl cursorpos | tr -d ,); "
                                 + "latte-say \"fact tap.x $1\" \"fact tap.y $2\" \"text win_asked $a\" \"emit win_menu\""])
    }

    component HeadButton: Rectangle {
        property string icon
        property bool off: false
        property color lit: Theme.raised
        signal pressed()
        width: 34; height: 34; radius: 10
        color: hit.containsMouse && !off ? lit : "transparent"
        opacity: off ? 0.35 : 1
        Behavior on color { ColorAnimation { duration: 100 } }
        Glyph { anchors.centerIn: parent; name: parent.icon; font.pixelSize: 17 }
        MouseArea { id: hit; anchors.fill: parent; hoverEnabled: true; enabled: !parent.off; cursorShape: Qt.PointingHandCursor; onClicked: parent.pressed() }
    }

    // ── the side: glass, from the top to the bottom ───────────────────────────────────────────────────────
    Rectangle {
        id: glass
        width: win.sideWidth; height: parent.height
        color: Theme.pane
        // the header's height of it carries the window too
        MouseArea { width: parent.width; height: 56; onPressed: win.startSystemMove() }
        Item { id: sidePane; anchors.fill: parent }
        Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: Theme.cream; opacity: 0.07 }
    }

    // ── right of it: the header, what the app shows, the coffee ───────────────────────────────────────────
    Rectangle {
        id: solid
        anchors.left: glass.right; anchors.right: parent.right; height: parent.height
        color: win.ground

        // the coffee: behind everything when the app has no lower part, the line above it when it has
        Surface {
            id: sea
            anchors.bottom: parent.bottom; width: parent.width
            depth: win.hasFoot ? win.footDepth : 30
            opacity: win.hasFoot ? 1 : 0.55
        }

        Item {
            id: head
            width: parent.width; height: 56
            MouseArea { anchors.fill: parent; acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onPressed: mouse => {
                            if (mouse.button !== Qt.RightButton) return win.startSystemMove()
                            const at = mapToItem(win.contentItem, mouse.x, mouse.y)          // on the search field its own menu instead
                            if (!win.fieldAt(win.contentItem, at.x, at.y)) win.menu() }
                        onDoubleClicked: mouse => { if (mouse.button === Qt.LeftButton && win.mode === "floating") win.ask("maximize_active") } }
            Row { id: left; x: 12; spacing: 2; anchors.verticalCenter: parent.verticalCenter; visible: win.arrows
                HeadButton { icon: "chevron-left"; off: !win.canGoBack; onPressed: win.back() }
                HeadButton { icon: "chevron-right"; off: !win.canGoForward; onPressed: win.forward() } }
            Label { text: win.heading; font.pixelSize: 15; font.weight: 700; anchors.verticalCenter: parent.verticalCenter
                    x: win.arrows ? left.x + left.width + 12 : 20; width: Math.max(0, right.x - x - 12) }
            Row { id: right; anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter; spacing: 8
                Row { id: toolRow; spacing: 6; anchors.verticalCenter: parent.verticalCenter }
                Rectangle { visible: win.searchHint !== ""; width: 250; height: 36; radius: 12; color: Theme.card; border.width: 1; border.color: field.activeFocus ? Theme.gold : "transparent"; anchors.verticalCenter: parent.verticalCenter
                    Glyph { x: 11; name: "search"; font.pixelSize: 15; color: Theme.dim; anchors.verticalCenter: parent.verticalCenter }
                    TextInput { id: field; x: 34; width: parent.width - 44; anchors.verticalCenter: parent.verticalCenter; color: Theme.cream; font.family: Theme.font; font.pixelSize: 14; clip: true; selectByMouse: true
                                selectionColor: Theme.coffee; onAccepted: if (text.trim() !== "") win.searched(text.trim()) }
                    Label { x: 34; text: win.searchHint; color: Theme.faint; visible: field.text === "" && !field.activeFocus; anchors.verticalCenter: parent.verticalCenter } }
                Row { spacing: 0; anchors.verticalCenter: parent.verticalCenter
                    HeadButton { icon: win.net === "off" ? "world-off" : "world"; visible: win.net !== ""; lit: Theme.raised; opacity: win.net === "off" ? 1 : 0.7
                                 onPressed: { net.command = ["latte-net", "toggle", String(Quickshell.processId)]; net.running = true } }
                    HeadButton { icon: "minus"; visible: win.mode === "floating"; onPressed: win.ask("minimize_active") }
                    HeadButton { icon: "rectangle"; visible: win.mode === "floating"; onPressed: win.ask("maximize_active") }
                    HeadButton { icon: "x"; lit: Theme.red; onPressed: Qt.quit() } } }
            // the line under the header: coffee, running out towards the end
            Rectangle { y: parent.height - 2; width: parent.width; height: 2
                gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: Theme.coffee } GradientStop { position: 0.7; color: Theme.coffee } GradientStop { position: 1; color: "transparent" } } }
        }
        Item { id: body; y: head.height; width: parent.width; height: parent.height - head.height - (win.hasFoot ? win.footDepth : 0); clip: true }
    }

    // The keyboard goes where the mouse presses, as everywhere: a text field pressed takes it. Qt alone misses it on
    // the press that also brings the window up (from the desktop, from another window): the field stayed without
    // the cursor until a second press. Above everything, it only watches the press and lets it through.
    Item {
        id: catcher
        anchors.fill: parent; z: 10000
        PointHandler {
            acceptedButtons: Qt.LeftButton
            onActiveChanged: if (active) {
                const f = win.fieldAt(win.contentItem, point.position.x, point.position.y)
                if (f && !f.readOnly) { f.forceActiveFocus(); win.pressedField = f; refocus.restart() }
            }
        }
        // the right button on any text field: cut, copy, paste, as on every field (6B.11); Ctrl+X, C, V work by themselves
        PointHandler {
            acceptedButtons: Qt.RightButton
            onActiveChanged: if (active) {
                const x = point.position.x, y = point.position.y
                const f = win.fieldAt(win.contentItem, x, y)
                if (!f) return
                f.forceActiveFocus()
                const hidden = f.echoMode !== undefined && f.echoMode !== TextInput.Normal     // a password is never copied out
                const some = f.selectedText !== ""
                const take = { icon: "select-all", text: I18n.tr("Select all"), hint: "Ctrl+A", enabled: f.text !== "", run: () => f.selectAll() }
                editMenu.open(x, y, f.readOnly              // text only read (an AI answer): copy alone (6B.11)
                    ? [{ icon: "copy", text: I18n.tr("Copy"), hint: "Ctrl+C", enabled: some, run: () => f.copy() },
                       { line: true }, take]
                    : [{ icon: "cut", text: I18n.tr("Cut"), hint: "Ctrl+X", enabled: some && !hidden, run: () => f.cut() },
                       { icon: "copy", text: I18n.tr("Copy"), hint: "Ctrl+C", enabled: some && !hidden, run: () => f.copy() },
                       { icon: "clipboard", text: I18n.tr("Paste"), hint: "Ctrl+V", enabled: f.canPaste, run: () => f.paste() },
                       { line: true }, take])
            }
        }
    }
    Menu { id: editMenu; z: 10001 }
    // the text field the press lands on: the topmost visible thing there, and inside it the same, down to the end
    function fieldAt(item, x, y) {
        const kids = item.children
        for (let i = kids.length - 1; i >= 0; i--) {
            const c = kids[i]
            if (c === catcher || !c.visible || !c.enabled) continue
            const at = c.mapFromItem(item, x, y)
            if (at.x < 0 || at.y < 0 || at.x > c.width || at.y > c.height) continue
            if (c.cursorPosition !== undefined && (c.readOnly === false || c.selectByMouse === true)) return c
            const deeper = fieldAt(c, at.x, at.y)
            if (deeper) return deeper
        }
        return null
    }
    property Item pressedField: null
    Timer { id: refocus; interval: 150; onTriggered: if (win.pressedField) { win.pressedField.forceActiveFocus(); win.pressedField = null } }
}
