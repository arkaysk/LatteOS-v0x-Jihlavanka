// an icon by its name: Phosphor's duotone (two glyphs: the fill behind at 20 %, the line before) where it has one,
// else the icon font's (Tabler)
import QtQuick

Text {
    id: g
    property string name
    readonly property var duo: name ? Icons.duo(name) : null
    text: duo ? duo[1] : Icons.of(name)
    font.family: duo ? Icons.duoFamily : Theme.icons
    font.pixelSize: 18
    color: Theme.cream
    Text {
        visible: g.duo !== null
        text: g.duo ? g.duo[0] : ""
        font: g.font
        color: g.color
        opacity: 0.2
    }
}
