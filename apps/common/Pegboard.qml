// The pegboard: the screens as they stand, in their true sizes and gaps, the same wherever they are shown
// (Settings › Displays, where they are moved; Background and Windows, where they stand). There with one screen too.
// What a page puts on it is placed in the screens' own points: px(x), py(y), and k for a length; at(item, x, y)
// is the point under a place in an item.
//   Pegboard { screens: [{ x, y, w, h }…]; … what the page draws on it … }
// Its bottom edge is dragged to make it taller (room above or below the screens), the wheel over it zooms in.
import QtQuick

Item {
    id: board
    property var screens: []                   // each with x, y, w, h: its points as Hyprland lays them out
    property bool still: false                 // a small picture of it: no wheel, no edge to drag
    property real room: 1.6                    // space around the screens, to drag something into
    property real base: 260                    // the scale of its first so many pixels: made taller, it gains room, the screens stay as large
    property real zoom: 1
    clip: true
    readonly property real x0: screens.length ? Math.min.apply(null, screens.map(m => m.x)) : 0
    readonly property real y0: screens.length ? Math.min.apply(null, screens.map(m => m.y)) : 0
    readonly property real x1: screens.length ? Math.max.apply(null, screens.map(m => m.x + m.w)) : 1
    readonly property real y1: screens.length ? Math.max.apply(null, screens.map(m => m.y + m.h)) : 1
    readonly property real k: zoom * Math.min(width / Math.max(1, (x1 - x0) * room), base / Math.max(1, (y1 - y0) * room))
    readonly property real ox: (width - (x1 - x0) * k) / 2
    readonly property real oy: (height - (y1 - y0) * k) / 2
    function px(x) { return ox + (x - x0) * k }
    function py(y) { return oy + (y - y0) * k }
    function at(item, x, y) { const p = item.mapToItem(board, x, y); return Qt.point(x0 + (p.x - ox) / k, y0 + (p.y - oy) / k) }
    function inside(item, x, y) { const p = item.mapToItem(board, x, y); return p.x >= 0 && p.y >= 0 && p.x <= width && p.y <= height }
    function screenAt(p) { return screens.find(m => p.x >= m.x && p.x <= m.x + m.w && p.y >= m.y && p.y <= m.y + m.h) || null }

    Rectangle { anchors.fill: parent; radius: board.still ? 6 : 16; color: "transparent"; border.width: board.still ? 0 : 2; border.color: Theme.line; z: 4 }
    Rectangle { z: 4; visible: !board.still; width: 48; height: 4; radius: 2; color: grow.containsMouse || grow.pressed ? Theme.gold : Theme.line
        anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: 5 }
    MouseArea { id: grow; z: 5; enabled: !board.still; anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; height: 14
        hoverEnabled: true; preventStealing: true; cursorShape: Qt.SizeVerCursor
        property real from: 0
        onPressed: e => from = mapToItem(board.parent, 0, e.y).y - board.height
        onPositionChanged: e => { if (pressed) board.height = Math.max(190, Math.min(900, mapToItem(board.parent, 0, e.y).y - from)) } }
    // over all of it, the wheel only: a press goes through to what lies below
    MouseArea { anchors.fill: parent; z: 6; enabled: !board.still; acceptedButtons: Qt.NoButton
        onWheel: e => board.zoom = Math.max(0.25, Math.min(12, board.zoom * (e.angleDelta.y > 0 ? 1.2 : 1 / 1.2))) }
}
