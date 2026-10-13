// an icon of the icon font, by its name
import QtQuick

Text {
    property string name
    text: Icons.of(name)
    font.family: Theme.icons
    font.pixelSize: 18
    color: Theme.cream
}
