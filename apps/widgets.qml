// Widgets: the Chaldea collection (apps/widgets, bin/latte-widget). A press on a tile puts it on the desktop or takes
// it away; what is chosen comes back at the next login. The lockscreens are pictures to look at: they lock nothing.
import QtQuick
import Quickshell
import Quickshell.Io
import "common"

ShellRoot {
    id: shell
    property string family: ""
    property var showing: []
    property var all: []
    readonly property var families: [{ id: "", name: QT_TR_NOOP("All"), icon: "layout-grid" },
                                     { id: "Quick notes", name: QT_TR_NOOP("Quick notes"), icon: "file-text" },
                                     { id: "Player", name: QT_TR_NOOP("Players"), icon: "player-play" },
                                     { id: "Sliders", name: QT_TR_NOOP("Sliders"), icon: "adjustments-horizontal" },
                                     { id: "Glyphs", name: QT_TR_NOOP("Glyphs"), icon: "pencil" },
                                     { id: "Interactive art", name: QT_TR_NOOP("Moving pictures"), icon: "sparkles" },
                                     { id: "Lockscreens", name: QT_TR_NOOP("Lock screen looks"), icon: "lock" }]
    readonly property string folder: (Quickshell.env("LATTE_SHARE") || "/usr/share/latteos") + "/apps/widgets/"
    FileView { path: shell.folder + "catalog.json"; onLoaded: shell.all = JSON.parse(text()) }
    Process { id: asker; command: ["latte-widget", "running"]
              stdout: StdioCollector { onStreamFinished: shell.showing = this.text.split("\n").filter(l => l !== "") } }
    Timer { interval: 2000; repeat: true; running: true; triggeredOnStart: true; onTriggered: asker.running = true }
    Process { id: doer; onExited: asker.running = true }
    function toggle(id) { doer.command = ["latte-widget", "toggle", id]; doer.running = true }

    AppWindow {
        id: win
        heading: I18n.tr("Widgets")
        searchHint: I18n.tr("Search…")
        side: Column { x: 12; y: 16; width: win.sideWidth - 24; spacing: 2
            Repeater { model: shell.families
                Nav { required property var modelData; width: parent.width; height: 36; text: I18n.tr(modelData.name); icon: modelData.icon
                      on: shell.family === modelData.id; onPressed: shell.family = modelData.id } } }
        GridView {
            id: grid
            anchors.fill: parent; anchors.margins: 18; clip: true
            cellWidth: width / Math.max(1, Math.floor(width / 220)); cellHeight: 186
            boundsBehavior: Flickable.StopAtBounds
            model: shell.all.filter(w => (shell.family === "" || w.family === shell.family)
                                         && w.title.toLowerCase().includes(win.searchText.toLowerCase()))
            delegate: Item {
                required property var modelData
                readonly property bool on: shell.showing.includes(modelData.id)
                width: grid.cellWidth; height: grid.cellHeight
                Rectangle { anchors.fill: parent; anchors.margins: 6; radius: 14; color: hit.containsMouse ? Theme.raised : Theme.card
                            border.width: parent.on ? 2 : 1; border.color: parent.on ? Theme.gold : Theme.line
                    Image { x: 8; y: 8; width: parent.width - 16; height: parent.height - 50; fillMode: Image.PreserveAspectFit; asynchronous: true; smooth: true
                            sourceSize.width: 400; source: modelData.thumb ? "file://" + shell.folder + modelData.id + "/" + modelData.thumb : "" }
                    Label { x: 12; width: parent.width - 44; anchors.bottom: parent.bottom; anchors.bottomMargin: 12; text: modelData.title; font.weight: 600; elide: Text.ElideRight }
                    Glyph { anchors.right: parent.right; anchors.rightMargin: 12; anchors.bottom: parent.bottom; anchors.bottomMargin: 12; visible: parent.parent.on; name: "check"; font.pixelSize: 16; color: Theme.gold } }
                MouseArea { id: hit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: shell.toggle(parent.modelData.id) }
            }
        }
    }
}
