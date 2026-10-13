// ── small things used everywhere ──────────────────────────────────────────────────────────────────────
import QtQuick

Text {
    property string name
    text: Icons.of(name)
    font.family: Theme.icons
    font.pixelSize: 18
    color: Theme.cream
    renderType: Text.NativeRendering       // Qt's own way of drawing letters loses parts of some of these outlines
}
