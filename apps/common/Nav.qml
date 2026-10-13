// a line of the side: a page, a category
import QtQuick

Rectangle {
    id: nav
    property string text
    property string icon
    property bool on: false
    property int badge: 0
    signal pressed()
    width: 222; height: 38; radius: 12
    color: on ? Theme.raised : (navHit.containsMouse ? Theme.card : "transparent")
    Behavior on color { ColorAnimation { duration: 110 } }
    Rectangle { width: 3; height: 18; radius: 2; color: Theme.gold; visible: nav.on; anchors.verticalCenter: parent.verticalCenter }
    Glyph { x: 14; name: nav.icon; color: nav.on ? Theme.gold : Theme.dim; anchors.verticalCenter: parent.verticalCenter }
    Label { x: 44; text: nav.text; width: parent.width - 44 - (nav.badge > 0 ? 40 : 10); color: nav.on ? Theme.cream : Theme.dim; font.weight: nav.on ? 600 : 400; anchors.verticalCenter: parent.verticalCenter }
    Rectangle { visible: nav.badge > 0; width: Math.max(22, mark.implicitWidth + 12); height: 20; radius: 10; color: Theme.gold; anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter
        Label { id: mark; text: nav.badge; anchors.centerIn: parent; color: Theme.inkOnGold; font.pixelSize: 12; font.weight: 700 } }
    MouseArea { id: navHit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: nav.pressed() }
}
