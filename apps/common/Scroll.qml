// a page that scrolls, with room around what it holds
import QtQuick

Flickable {
    default property alias content: inner.data
    readonly property real room: width - 56
    anchors.fill: parent
    contentWidth: width; contentHeight: inner.height + 56
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    Column { id: inner; x: 28; y: 24; width: parent.width - 56; spacing: 26 }
}
