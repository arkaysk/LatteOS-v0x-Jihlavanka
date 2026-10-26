// a button: gold when it is the thing to do, quiet otherwise
import QtQuick

Rectangle {
    id: pill
    property string text
    property string icon
    property bool strong: false
    property bool danger: false
    property bool busy: false
    signal pressed()
    property real turn: 0                  // the icon turns while it works, and stands straight again after
    NumberAnimation on turn { running: pill.busy; from: 0; to: 360; duration: 1100; loops: Animation.Infinite }
    implicitWidth: pill.text === "" ? implicitHeight : row.implicitWidth + 30; implicitHeight: 36
    radius: height / 2
    color: busy ? Theme.raised : (strong ? Theme.gold : (hit.containsMouse ? Theme.raised : Theme.card))
    border.color: danger ? Theme.red : (strong ? "transparent" : Theme.line); border.width: strong ? 0 : 1
    scale: hit.pressed ? 0.96 : 1
    Behavior on scale { NumberAnimation { duration: 90 } }
    Behavior on color { ColorAnimation { duration: 120 } }
    Row { id: row; anchors.centerIn: parent; spacing: 7
        Glyph { name: pill.icon; visible: pill.icon !== ""; font.pixelSize: 16; anchors.verticalCenter: parent.verticalCenter
                color: pill.busy ? Theme.dim : (pill.strong ? Theme.inkOnGold : (pill.danger ? Theme.red : Theme.cream))
                rotation: pill.busy ? pill.turn : 0 }
        Label { text: pill.text; visible: pill.text !== ""; font.weight: 600; color: pill.busy ? Theme.dim : (pill.strong ? Theme.inkOnGold : (pill.danger ? Theme.red : Theme.cream)); anchors.verticalCenter: parent.verticalCenter } }
    MouseArea { id: hit; anchors.fill: parent; hoverEnabled: true; enabled: !pill.busy; cursorShape: Qt.PointingHandCursor; onClicked: pill.pressed() }
}
