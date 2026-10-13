// a slider: how much of something, from none to all; `moved` says where it was dragged or pressed to
import QtQuick

Item {
    id: slide
    property real value: 0                     // 0…1
    property bool off: false                   // shown, but as something that does not count now
    signal moved(real to)
    implicitWidth: 240; height: 26
    Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 6; radius: 3; color: Theme.raised }
    Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width * Math.min(1, Math.max(0, slide.value)); height: 6; radius: 3; color: slide.off ? Theme.faint : Theme.gold }
    Rectangle { x: (parent.width - width) * Math.min(1, Math.max(0, slide.value)); anchors.verticalCenter: parent.verticalCenter; width: 18; height: 18; radius: 9
                color: slide.off ? Theme.dim : Theme.gold; scale: hit.pressed ? 1.2 : 1; Behavior on scale { NumberAnimation { duration: 90 } } }
    MouseArea { id: hit; anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor
                function at(x) { slide.moved(Math.min(1, Math.max(0, (x - 6) / Math.max(1, slide.width)))) }
                onPressed: mouse => at(mouse.x); onPositionChanged: mouse => { if (pressed) at(mouse.x) } }
}
