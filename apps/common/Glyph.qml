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
    // a bare mark (plus, cross, tick, grip…) has a square for its fill in Phosphor's duotone: a box round a "+" that reads as a
    // button in a button (the user, 21. 11.); those keep the line alone
    readonly property bool bare: ["plus", "x", "minus", "check", "grip-vertical", "download-simple", "dots", "chevron-right",
                                  "chevron-left", "chevron-up", "chevron-down", "arrow-up", "arrow-down", "arrow-back-up", "arrow-forward-up"].indexOf(name) >= 0
    Text {
        visible: g.duo !== null && !g.bare
        text: g.duo ? g.duo[0] : ""
        font: g.font
        color: g.color
        opacity: 0.2
    }
}
