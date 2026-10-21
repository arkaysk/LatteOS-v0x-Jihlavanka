import QtQuick

Text {
    color: Theme.cream
    font.family: Theme.font
    font.pixelSize: 14
    elide: Text.ElideRight
    // on True Glass the writing that lies on the glass itself gets a soft shadow, so it reads over any picture
    style: Theme.trueGlass ? Text.Raised : Text.Normal
    styleColor: Theme.light ? Qt.rgba(1, 1, 1, 0.55) : Qt.rgba(0, 0, 0, 0.55)
}
