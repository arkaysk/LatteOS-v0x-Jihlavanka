import QtQuick

Column {
    property string text
    spacing: 12
    Glyph { name: "cup"; font.pixelSize: 44; color: Theme.coffee; anchors.horizontalCenter: parent.horizontalCenter
            SequentialAnimation on opacity { loops: Animation.Infinite; NumberAnimation { to: 0.35; duration: 700 } NumberAnimation { to: 1; duration: 700 } } }
    Label { text: parent.text; color: Theme.dim; anchors.horizontalCenter: parent.horizontalCenter }
}
