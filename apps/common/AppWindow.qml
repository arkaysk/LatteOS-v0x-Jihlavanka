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
// when it has a lower one (`foot`); when it has none the coffee only moves quietly under the end of the page. What the
// app shows never goes under the coffee: it ends above it and runs out into the ground (`reserve`, `fade`).
// Minimise and maximise are there only where windows float: on the tape and in tiles they would do nothing.
//
//   AppWindow { heading: "…"; side: [ … ]; tools: [ … ]; foot: [ … ]; searchHint: "…"; onSearched: text => …
//               arrows: true; canGoBack: …; onBack: …        … what the app shows … }
import QtQuick
import QtQuick.Effects
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
    // What the app shows never goes under the coffee: it ends above it and runs out into the ground over `fade` (a real
    // see-through end, so the coffee and its glow stay as they are). With a foot the coffee begins where the page ends;
    // without one, 44 px are kept for it (30 deep and the glow above its surface). What stands in the coffee is `foot`.
    readonly property real reserve: hasFoot ? footDepth : 44
    property real fade: 36

    property bool arrows: false                // the app has pages one goes back from
    property bool canGoBack: false
    property bool canGoForward: false
    signal back()
    // Undo and Redo of what was done in this window, and in no other (the user, 11. 11.): the name of the app's own
    // history (bin/latte-files, LATTE_UNDO). The app does its changes with `undoEnv` in the command's environment,
    // calls undoLook() after one, and hears undone() when something was taken back or done again. A press held
    // lists the last ones; `undoWord` turns what one was called into words
    property string undoName: ""
    readonly property var undoEnv: ({ LATTE_UNDO: undoName })
    property var undoWord: (label) => label
    property var undoList: []
    property var redoList: []
    signal undone()
    function undoLook() { if (undoName !== "" && !undoAsk.running) undoAsk.running = true }
    function undoDo(way, times) { if (undoRun.running) return; undoRun.command = ["sh", "-c", "i=0; while [ $i -lt \"$2\" ]; do latte-files \"$1\" || break; i=$((i + 1)); done", "sh", way, String(times)]; undoRun.running = true }
    Process { id: undoAsk; command: ["latte-files", "history"]; environment: win.undoEnv
              stdout: StdioCollector { onStreamFinished: { const u = [], r = []
                  for (const l of this.text.split("\n")) { const at = l.indexOf("\t"); if (at > 0) (l.slice(0, at) === "undo" ? u : r).push(l.slice(at + 1)) }
                  win.undoList = u; win.redoList = r } } }
    Process { id: undoRun; environment: win.undoEnv; onExited: { win.undoLook(); win.undone() } }
    onUndoNameChanged: undoLook()
    signal forward()
    property string searchHint: ""             // with a hint the header has a field to search in
    property real searchWidth: 250             // how wide that field is (an app with many tools in the header makes it narrower)
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
    // what shows the windows (Settings › Drops › Window management, ROADMAP 6.41): with "none" there is nowhere to minimise to
    property bool canMinimize: true
    FileView {
        id: gooSettings
        path: (Quickshell.env("XDG_DATA_HOME") || (Quickshell.env("HOME") + "/.local/share")) + "/pleamar/goo/settings.json"
        printErrors: false; watchChanges: true
        onFileChanged: reload()
        onLoaded: { try { const t = JSON.parse(gooSettings.text()); win.canMinimize = !((t.hidden || []).indexOf("bargoo") >= 0 && t.taskbar === "none") } catch (e) { win.canMinimize = true } }
    }
    onScreenChanged: readMode()
    function readMode() {
        const lines = modeFile.text().split("\n"), own = lines.slice(1).map(l => l.trim().split(/\s+/)).find(w => w.length === 2 && win.screen && w[0] === win.screen.name)
        win.mode = own ? own[1] : ((lines[0] || "").trim() || "tape")
    }
    // taking (nearly) the whole screen: maximized. pleamar-wm does not tell a window it is (no xdg maximized state)
    // ponytail: a window made that big by hand shows "restore" too; upgrade when the window manager says it
    readonly property bool maxed: mode === "floating" && !!screen && width >= screen.width * 0.9 && height >= screen.height * 0.8
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

        // (the coffee carries the window too: the catcher above everything does it, 1D.29 and 1D.44)
        // the coffee: in front of what the app shows (it swings as the window is carried and its crest rises over the end of the page,
        // which is cut off and runs out above it); only what is put in the coffee (`foot`: a button, an information) stands in it
        Surface {
            id: sea
            z: 5
            anchors.bottom: parent.bottom; width: parent.width
            depth: win.hasFoot ? win.footDepth : 30
            // as dark as DualBrew's, with a foot or without (the user 5. 11.: it was never meant to be paler)
        }

        Item {
            id: head
            width: parent.width; height: 56
            MouseArea { anchors.fill: parent; acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onPressed: mouse => {
                            if (mouse.button !== Qt.RightButton) return win.startSystemMove()
                            const at = mapToItem(win.contentItem, mouse.x, mouse.y)          // on the search field its own menu instead
                            if (!win.fieldAt(win.contentItem, at.x, at.y)) win.menu() } }
            // (a double click on it is the window manager's: the move it asks for presses its title, which maximizes and back)
            Row { id: left; x: 12; spacing: 2; anchors.verticalCenter: parent.verticalCenter; visible: win.arrows
                HeadButton { icon: "chevron-left"; off: !win.canGoBack; onPressed: win.back() }
                HeadButton { icon: "chevron-right"; off: !win.canGoForward; onPressed: win.forward() } }
            Row { id: undos; x: win.arrows ? left.x + left.width + 6 : 12; spacing: 2; anchors.verticalCenter: parent.verticalCenter; visible: win.undoName !== ""
                component UndoButton: HeadButton { id: ub
                    property string way; property var list: []
                    off: list.length === 0
                    onPressed: win.undoDo(way, 1)
                    // held, or the right button: the last ones, nearest first; choosing one takes back all down to it
                    function listed() { const p = mapToItem(win.contentItem, 0, height + 4)
                        editMenu.open(p.x, p.y, list.slice(0, 12).map((l, i) => ({ text: win.undoWord(l), icon: icon, run: () => win.undoDo(way, i + 1) }))) }
                    MouseArea { anchors.fill: parent; enabled: !ub.off; acceptedButtons: Qt.LeftButton | Qt.RightButton; cursorShape: Qt.PointingHandCursor
                                property bool held: false
                                onPressed: m => { held = false; if (m.button === Qt.RightButton) { held = true; ub.listed() } }
                                onPressAndHold: { held = true; ub.listed() }
                                onClicked: if (!held) ub.pressed() } }
                UndoButton { icon: "arrow-back-up"; way: "undo"; list: win.undoList }
                UndoButton { icon: "arrow-forward-up"; way: "redo"; list: win.redoList } }
            Label { text: win.heading; font.pixelSize: 15; font.weight: 700; anchors.verticalCenter: parent.verticalCenter
                    x: win.undoName !== "" ? undos.x + undos.width + 12 : win.arrows ? left.x + left.width + 12 : 20; width: Math.max(0, right.x - x - 12) }
            Row { id: right; anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter; spacing: 8
                Row { id: toolRow; spacing: 6; anchors.verticalCenter: parent.verticalCenter }
                Rectangle { visible: win.searchHint !== ""; width: win.searchWidth; height: 36; radius: 12; color: Theme.card; border.width: 1; border.color: field.activeFocus ? Theme.gold : "transparent"; anchors.verticalCenter: parent.verticalCenter
                    Glyph { x: 11; name: "search"; font.pixelSize: 15; color: Theme.dim; anchors.verticalCenter: parent.verticalCenter }
                    TextInput { id: field; x: 34; width: parent.width - 44; anchors.verticalCenter: parent.verticalCenter; color: Theme.cream; font.family: Theme.font; font.pixelSize: 14; clip: true; selectByMouse: true
                                selectionColor: Theme.coffee; onAccepted: if (text.trim() !== "") win.searched(text.trim()) }
                    Label { x: 34; text: win.searchHint; color: Theme.faint; visible: field.text === "" && !field.activeFocus; anchors.verticalCenter: parent.verticalCenter } }
                Row { spacing: 0; anchors.verticalCenter: parent.verticalCenter
                    HeadButton { icon: win.net === "off" ? "world-off" : "world"; visible: win.net !== ""; lit: Theme.raised; opacity: win.net === "off" ? 1 : 0.7
                                 onPressed: { net.command = ["latte-net", "toggle", String(Quickshell.processId)]; net.running = true } }
                    HeadButton { icon: "minus"; visible: win.mode === "floating" && win.canMinimize; onPressed: win.ask("minimize_active") }
                    HeadButton { icon: win.maxed ? "copy" : "rectangle"; visible: win.mode === "floating"; onPressed: win.ask("maximize_active") }
                    HeadButton { icon: "x"; lit: Theme.red; onPressed: Qt.quit() } } }
            // the line under the header: coffee, running out towards the end
            Rectangle { y: parent.height - 2; width: parent.width; height: 2
                gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: Theme.coffee } GradientStop { position: 0.7; color: Theme.coffee } GradientStop { position: 1; color: "transparent" } } }
        }
        Item { id: body; y: head.height; width: parent.width; height: parent.height - head.height - win.reserve; clip: true
               layer.enabled: true
               layer.effect: MultiEffect { maskEnabled: true; maskSource: bodyMask } }
        Item { id: bodyMask; visible: false; layer.enabled: true; y: head.height; width: body.width; height: body.height
               Rectangle { anchors.fill: parent; gradient: Gradient { GradientStop { position: 0; color: "white" } GradientStop { position: Math.max(0, 1 - win.fade / Math.max(1, body.height)); color: "white" } GradientStop { position: 1; color: "transparent" } } } }
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
                const x = point.position.x, y = point.position.y
                const f = win.fieldAt(win.contentItem, x, y)
                if (f && !f.readOnly) { f.forceActiveFocus(); win.pressedField = f; refocus.restart() }
                // The coffee at the foot carries the window, even where a page reaches over it (a list that scrolls,
                // LensAI's pages), as long as no button or field is there to be pressed (1D.29, 1D.44)
                else if (!f && y > win.height - sea.depth && x > glass.width && !win.pressableAt(win.contentItem, x, y)) win.startSystemMove()
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
    // something to press at that point: a button or a row (a MouseArea of its own size, not a ground that catches
    // everything) or a field; a list that scrolls is not one
    function pressableAt(item, x, y) {
        const kids = item.children
        for (let i = kids.length - 1; i >= 0; i--) {
            const c = kids[i]
            if (c === catcher || !c.visible || !c.enabled) continue
            const at = c.mapFromItem(item, x, y)
            if (at.x < 0 || at.y < 0 || at.x > c.width || at.y > c.height) continue
            if (c.cursorPosition !== undefined) return true
            if (c instanceof MouseArea && c.height < sea.depth * 3) return true
            if (win.pressableAt(c, at.x, at.y)) return true
        }
        return false
    }
    property Item pressedField: null
    Timer { id: refocus; interval: 150; onTriggered: if (win.pressedField) { win.pressedField.forceActiveFocus(); win.pressedField = null } }
}
