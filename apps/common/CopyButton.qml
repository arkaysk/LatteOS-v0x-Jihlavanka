// copy, as beside the AI's messages (6B.09): quiet beside its text, lit under the pointer, a tick for a moment once done
import QtQuick
import Quickshell

Glyph {
    id: button
    property string copy                       // what goes to the clipboard
    property bool done: false
    property int reach: 8                      // how far past the glyph it can be pressed: 0 in lines lying close together
    name: done ? "check" : "copy"
    font.pixelSize: 15
    color: done ? Theme.gold : Theme.cream
    opacity: done || hit.containsMouse ? 1 : 0.45
    Accessible.role: Accessible.Button
    Accessible.name: I18n.tr("Copy")
    MouseArea { id: hit; anchors.fill: parent; anchors.margins: -reach; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: { Quickshell.clipboardText = button.copy; button.done = true; back.restart() } }
    Timer { id: back; interval: 1200; onTriggered: button.done = false }
}
