// The scroll bar of every LatteOS list, as Windows 11 has it: thin and quiet, wide under the pointer; its thumb as long
// as the share that shows; dragged, or the track pressed, the list goes straight there — a long one is crossed in one
// move (the user, 18. 11.). Put `ScrollGrip {}` inside any Flickable, ListView or GridView: it moves itself onto the view.
import QtQuick

Item {
    id: grip
    property Item flick: null
    // what is declared inside a view lands in its content, which scrolls: the grip stands on the view itself instead
    Component.onCompleted: { let p = parent; while (p && p.contentY === undefined) p = p.parent; if (p) { flick = p; parent = p } }
    readonly property real view: flick ? flick.height : 0
    readonly property real most: flick ? flick.contentHeight + flick.topMargin + flick.bottomMargin - view : 0
    readonly property real at: flick && most > 0 ? Math.max(0, Math.min(1, (flick.contentY - flick.originY + flick.topMargin) / most)) : 0
    readonly property bool wide: hit.containsMouse || hit.pressed
    visible: !!flick && most > 1
    x: flick ? flick.width - width - 2 : 0; y: 4; z: 1000
    width: 14; height: view - 8
    readonly property real thumb: Math.max(32, height * view / Math.max(view + most, 1))
    Rectangle { anchors.right: parent.right; anchors.rightMargin: 3; width: grip.wide ? 8 : 3; height: parent.height; radius: width / 2
                color: Theme.line; opacity: grip.wide ? 0.6 : 0
                Behavior on width { NumberAnimation { duration: 120 } }
                Behavior on opacity { NumberAnimation { duration: 120 } } }
    Rectangle { anchors.right: parent.right; anchors.rightMargin: 3; y: (grip.height - grip.thumb) * grip.at; width: grip.wide ? 8 : 3; height: grip.thumb; radius: width / 2
                color: hit.pressed ? Theme.gold : Theme.dim; opacity: grip.wide ? 1 : 0.55
                Behavior on width { NumberAnimation { duration: 120 } } }
    MouseArea {
        id: hit
        anchors.fill: parent; hoverEnabled: true; preventStealing: true; cursorShape: Qt.PointingHandCursor
        function go(y) { grip.flick.contentY = grip.flick.originY - grip.flick.topMargin + Math.max(0, Math.min(1, (y - grip.thumb / 2) / Math.max(1, grip.height - grip.thumb))) * grip.most }
        onPressed: ev => go(ev.y)
        onPositionChanged: ev => { if (pressed) go(ev.y) }
    }
}
