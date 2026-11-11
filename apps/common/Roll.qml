// A line of text in a room that may be too narrow for it: cut with "…", and while `rolling` (the mouse over its
// line, or the line chosen) it slides to its end and back, so all of it is read. Text that fits never moves.
import QtQuick

Item {
    id: roll
    property alias text: word.text
    property alias color: word.color
    property alias font: word.font
    property bool rolling: false
    readonly property real over: Math.max(0, Math.ceil(word.implicitWidth - width))
    implicitHeight: word.implicitHeight
    clip: true
    Label { id: word; anchors.verticalCenter: parent.verticalCenter
            width: move.running ? implicitWidth : roll.width; elide: move.running ? Text.ElideNone : Text.ElideRight }
    SequentialAnimation { id: move; running: roll.rolling && roll.over > 0; loops: Animation.Infinite
        onRunningChanged: if (!running) word.x = 0
        PauseAnimation { duration: 500 }
        NumberAnimation { target: word; property: "x"; to: -roll.over; duration: roll.over * 25 }      // 40 px a second
        PauseAnimation { duration: 900 }
        NumberAnimation { target: word; property: "x"; to: 0; duration: roll.over * 25 }
    }
}
