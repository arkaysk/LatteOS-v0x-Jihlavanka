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
    FileView {
        path: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/latteos/window-mode"
        printErrors: false; watchChanges: true
        onFileChanged: reload()
        onLoaded: win.mode = text().trim() || "tape"
    }
    function ask(what) { Quickshell.execDetached(["hyprctl", "eval", "latte.win." + what + "()"]) }

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
        color: Theme.ground

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
            MouseArea { anchors.fill: parent; onPressed: win.startSystemMove(); onDoubleClicked: if (win.mode === "floating") win.ask("maximize_active") }
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
}
