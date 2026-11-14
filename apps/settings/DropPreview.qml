// Settings › Drops: a small live picture of what a choice puts on the screen (ROADMAP 6.40): a miniature screen, the
// goo's coffee along its bottom edge, and on it the drops or the Shore plates the choice makes. Drawn as the window
// modes' preview on the Windows page is: shapes in the cup's colours, one slow clock (t) moves them all.
//   DropPreview { width: 192; kind: "look-pro"; calm: false }
// kinds: look-playful look-pro look-minimal · lens-goo lens-shore app-cloud · bargoo dockshore none ·
//        intro carry secure (the tour's)
import QtQuick
import Quickshell.Widgets
import "../common"

ClippingRectangle {
    id: root
    property string kind: "look-pro"
    property bool calm: false                  // no movement: the picture rests where it shows most
    property real t: 0.7                       // 0…1 round, the one clock
    readonly property real u: width / 192      // a unit: the picture is drawn in 192 × 108
    readonly property real lvl: ["look-playful", "intro", "lens-goo", "bargoo"].includes(kind) ? 6 * u : 0
    readonly property bool wins: ["bargoo", "dockshore", "none"].includes(kind)
    height: width * 9 / 16; radius: 10 * u + 2; color: Theme.ground; border.width: 1; border.color: Theme.line

    NumberAnimation on t { running: !root.calm && root.visible; from: 0; to: 1; duration: 7000; loops: Animation.Infinite }
    function ramp(a, b) { const x = Math.max(0, Math.min(1, (t - a) / (b - a))); return x * x * (3 - 2 * x) }
    function wave(ph, k) { return Math.sin((t * (k || 2) + ph) * 2 * Math.PI) }
    readonly property color plate: Theme.coffee
    readonly property color edge: Qt.rgba(Theme.gold.r, Theme.gold.g, Theme.gold.b, 0.4)

    // a drop that melts into the level
    component Blob: Item {
        property real cx; property real d; property real rise; property real ph: 0
        readonly property real k: 1 + 0.07 * root.wave(ph, 1)
        Rectangle { x: cx - d * 0.2 * root.u; width: d * 0.4 * root.u; y: root.height - root.lvl - rise * root.u - d * 0.3 * root.u; height: rise * root.u + d * 0.3 * root.u + root.lvl; color: root.plate }
        Rectangle { width: d * k * root.u; height: width; radius: width / 2; color: root.plate; x: cx - width / 2; y: root.height - root.lvl - rise * root.u - width / 2
            Rectangle { x: parent.width * 0.22; y: parent.height * 0.2; width: parent.width * 0.26; height: width; radius: width / 2; color: Theme.cream; opacity: 0.22 } } }
    // a flat plate sitting on the bottom edge
    component Plate: Rectangle {
        property real px; property real pw; property real ph: 12
        x: px * root.u; width: pw * root.u; height: ph * root.u + 2; y: root.height - ph * root.u
        radius: 4 * root.u + 1; color: root.plate; border.width: 1; border.color: root.edge }
    component Square: Rectangle { property int n: 0
        width: 7 * root.u; height: width; radius: 2 * root.u; color: [Theme.gold, Theme.cream, Theme.dim, Theme.ok][n % 4]; opacity: 0.85 }
    component Bar: Rectangle { color: Theme.cream; opacity: 0.35; height: 2 * root.u + 0.5; radius: height / 2 }
    component Tag: Text { color: Theme.cream; font.family: Theme.font; font.weight: 700; font.pixelSize: Math.max(6, 7 * root.u) }

    // two windows behind (for window management)
    Repeater { model: root.wins ? [[10, 8, 86, 58], [88, 20, 92, 56]] : []
        Rectangle { required property var modelData; required property int index
            x: modelData[0] * root.u; y: modelData[1] * root.u; width: modelData[2] * root.u; height: modelData[3] * root.u; radius: 5 * root.u
            color: Theme.card; border.width: 1; border.color: Theme.line
            Rectangle { width: parent.width; height: 9 * root.u; radius: parent.radius; color: Theme.raised
                Tag { visible: root.kind === "none"; anchors.right: parent.right; anchors.rightMargin: 4 * root.u; anchors.verticalCenter: parent.verticalCenter; text: "□  ✕"; color: Theme.dim } }
            Bar { x: 6 * root.u; y: 15 * root.u; width: parent.width * 0.5 }
            Bar { x: 6 * root.u; y: 21 * root.u; width: parent.width * 0.35 } } }

    // the level, the goo's coffee
    Rectangle { visible: root.lvl > 0; width: parent.width; height: root.lvl; y: parent.height - height; color: root.plate }

    // ── Playful, and the first of the tour: drops
    Item { anchors.fill: parent; visible: ["look-playful", "intro"].includes(root.kind)
        Blob { cx: (root.kind === "intro" ? 22 : 18) * root.u; d: 8; rise: 9; ph: 0 }
        Blob { cx: (root.kind === "intro" ? 40 : 32) * root.u; d: 10; rise: 11; ph: 0.3 }
        Blob { cx: (root.kind === "intro" ? 58 : 46) * root.u; d: 8; rise: 9; ph: 0.6 }
        Blob { visible: root.kind === "look-playful"; cx: 96 * root.u; d: 18; rise: 14; ph: 0.2 }
        Blob { visible: root.kind === "look-playful"; cx: 146 * root.u; d: 14; rise: 11; ph: 0.5 }
        Blob { visible: root.kind === "look-playful"; cx: 176 * root.u; d: 10; rise: 8; ph: 0.8 } }

    // ── Pro: the Shore plates; Minimal and the dock: the same dock plate
    Item { anchors.fill: parent; visible: ["look-pro", "look-minimal", "dockshore", "intro", "carry"].includes(root.kind)
        Plate { px: 20; pw: 62; ph: 10; visible: root.kind === "look-pro"
            Rectangle { x: 5 * root.u; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 10 * root.u; height: 3.4 * root.u; radius: height / 2; color: Theme.raised } }
        Plate { px: 0; pw: 46; ph: 14; visible: root.kind === "look-minimal"; radius: 0
            Tag { anchors.centerIn: parent; text: "12:30"; font.family: Theme.mono; color: Theme.inkOnCoffee } }
        Plate { px: root.kind === "intro" ? 120 : root.kind === "carry" ? 90 : 70; pw: root.kind === "carry" ? 56 : 52; ph: 16; visible: root.kind !== "dockshore"
            Row { anchors.centerIn: parent; spacing: 4 * root.u
                Repeater { model: 4; Square { required property int index; n: index; y: -2 * root.u * Math.max(0, root.wave(-index * 0.12, 1)) } } } }
        Plate { px: 70; pw: 52; ph: 16; visible: root.kind === "dockshore"
            Row { anchors.centerIn: parent; spacing: 4 * root.u
                Repeater { model: 4; Square { required property int index; n: index; y: -2 * root.u * Math.max(0, root.wave(-index * 0.12, 1)) } } } }
        Plate { px: 148; pw: 44; ph: 12; visible: root.kind === "look-pro"; radius: 4 * root.u + 1
            Row { anchors.centerIn: parent; spacing: 4 * root.u
                Repeater { model: 3; Rectangle { required property int index; width: 4 * root.u; height: width; radius: width / 2; color: index === 0 ? Theme.gold : Theme.cream; opacity: 0.7 } } } }
    }

    // ── the tour: a plate carried with Alt along the edge, joined to the other
    Item { anchors.fill: parent; visible: root.kind === "carry"
        readonly property real go: root.ramp(0.15, 0.6)
        Plate { px: 8 + 40 * parent.go; pw: 36; ph: 10
            Row { anchors.centerIn: parent; spacing: 4 * root.u
                Repeater { model: 3; Rectangle { required property int index; width: 4 * root.u; height: width; radius: width / 2; color: Theme.cream; opacity: 0.7 } } } }
        Rectangle { x: 44 * root.u; width: 46 * root.u; y: root.height - 11 * root.u; height: 9 * root.u; color: root.plate; opacity: root.ramp(0.55, 0.7) }   // the goo flows over the gap
        Rectangle { x: (8 + 40 * parent.go) * root.u + 14 * root.u; y: root.height - 36 * root.u; width: altRow.width + 12 * root.u; height: 14 * root.u; radius: 5 * root.u; color: Theme.raised; border.width: 1; border.color: Theme.line
            opacity: 1 - root.ramp(0.65, 0.75)
            Row { id: altRow; anchors.centerIn: parent; spacing: 3 * root.u
                Glyph { text: Icons.of("hand-grab"); font.pixelSize: 9 * root.u; color: Theme.gold }
                Tag { text: "Alt"; color: Theme.gold } } } }

    // ── Launchers
    Item { anchors.fill: parent; visible: root.kind === "lens-goo"
        readonly property real open: root.calm ? 1 : root.ramp(0.2, 0.4) - root.ramp(0.8, 0.95)
        Blob { cx: 96 * root.u; d: 16; rise: 10; ph: 0 }
        Glyph { x: 96 * root.u - width / 2; y: root.height - root.lvl - 10 * root.u - height / 2; text: Icons.of("search"); font.pixelSize: 9 * root.u; color: Theme.inkOnCoffee; opacity: 1 - parent.open * 0.5 }
        Rectangle { width: 112 * root.u; height: 54 * root.u; radius: 8 * root.u; color: Theme.card; border.width: 1; border.color: root.edge
            x: 96 * root.u - width / 2; y: root.height - root.lvl - 28 * root.u - height
            transformOrigin: Item.Bottom; scale: parent.open; opacity: parent.open
            Rectangle { x: 6 * root.u; y: 6 * root.u; width: parent.width - 12 * root.u; height: 12 * root.u; radius: height / 2; color: Theme.raised
                Glyph { x: 5 * root.u; anchors.verticalCenter: parent.verticalCenter; text: Icons.of("search"); font.pixelSize: 8 * root.u; color: Theme.gold } }
            Repeater { model: 3; Bar { required property int index; x: 8 * root.u; y: (24 + index * 8) * root.u; width: (70 - index * 14) * root.u } } } }
    Item { anchors.fill: parent; visible: root.kind === "lens-shore"
        readonly property real open: root.calm ? 1 : root.ramp(0.2, 0.4) - root.ramp(0.8, 0.95)
        Plate { px: 30; pw: 132; ph: 11
            Rectangle { x: 6 * root.u; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 12 * root.u; height: 4 * root.u; radius: height / 2; color: Theme.raised } }
        Rectangle { width: 112 * root.u; height: 56 * root.u; radius: 8 * root.u; color: Theme.card; border.width: 1; border.color: root.edge
            x: 96 * root.u - width / 2; y: root.height - 9 * root.u - 4 * root.u - height + (1 - parent.open) * 26 * root.u; opacity: parent.open
            Repeater { model: 4; Rectangle { required property int index; x: 8 * root.u; y: (8 + index * 11) * root.u; width: parent.width - 16 * root.u; height: 8 * root.u; radius: 3 * root.u
                color: index === 0 ? Theme.raised : "transparent"; Bar { x: 4 * root.u; anchors.verticalCenter: parent.verticalCenter; width: (60 - index * 8) * root.u } } } } }
    Item { anchors.fill: parent; visible: root.kind === "app-cloud"
        readonly property real open: root.calm ? 1 : root.ramp(0.2, 0.4) - root.ramp(0.8, 0.95)
        Rectangle { anchors.fill: parent; color: Theme.ground; opacity: 0.6 * parent.open }
        Grid { columns: 5; spacing: 8 * root.u; x: (root.width - width) / 2; y: 14 * root.u + (1 - parent.open) * 6 * root.u; opacity: parent.open
            Repeater { model: 15; Square { required property int index; n: index; width: 12 * root.u } } }
        Plate { px: 0; pw: 46; ph: 14; radius: 0
            Tag { anchors.centerIn: parent; text: "12:30"; font.family: Theme.mono; color: Theme.inkOnCoffee } } }

    // ── the tour's Ctrl+Alt+Del menu: the screen dims, a list on the left, power at the bottom right
    Item { anchors.fill: parent; visible: root.kind === "secure"
        readonly property real show: root.calm ? 1 : root.ramp(0.0, 0.12)
        Rectangle { anchors.fill: parent; color: "black"; opacity: 0.55 * parent.show }
        Column { x: 12 * root.u; y: 14 * root.u; spacing: 4 * root.u; opacity: parent.show
            Repeater { model: 6; Rectangle { required property int index; width: 70 * root.u; height: 10 * root.u; radius: 3 * root.u
                color: index === Math.floor(root.t * 6) % 6 && !root.calm ? Theme.raised : Theme.card; border.width: index === 5 ? 1 : 0; border.color: Theme.line
                Bar { x: 5 * root.u; anchors.verticalCenter: parent.verticalCenter; width: (36 - (index % 3) * 6) * root.u } } } }
        Row { anchors.right: parent.right; anchors.rightMargin: 10 * root.u; anchors.bottom: parent.bottom; anchors.bottomMargin: 8 * root.u; spacing: 5 * root.u; opacity: parent.show
            Repeater { model: ["wifi", "user", "power"]; Rectangle { required property string modelData; width: 14 * root.u; height: width; radius: width / 2; color: Theme.card
                Glyph { anchors.centerIn: parent; text: Icons.of(modelData); font.pixelSize: 8 * root.u; color: Theme.dim } } } }
        Row { x: 100 * root.u; y: 14 * root.u; spacing: 3 * root.u; opacity: parent.show
            Repeater { model: ["Ctrl", "Alt", "Del"]; Rectangle { required property string modelData; width: kt.width + 8 * root.u; height: 12 * root.u; radius: 4 * root.u; color: Theme.raised; border.width: 1; border.color: Theme.line
                Tag { id: kt; anchors.centerIn: parent; text: modelData; color: Theme.gold } } } } }
}
