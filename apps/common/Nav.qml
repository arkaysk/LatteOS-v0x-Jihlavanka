// a line of the side: a page, a category
import QtQuick
import QtQuick.Controls as QQC      // the tooltip only

Rectangle {
    id: nav
    property string text
    property string icon
    property bool on: false
    property int badge: 0
    property bool off: false               // announced, not there yet: faint, and a press does nothing
    property string tail: ""               // a small button at the end (a drive's eject), its icon
    signal pressed()
    signal tailPressed()
    readonly property bool slim: width < 100        // a side folded to its icons: the icon alone, a count as a dot
    width: 222; height: 38; radius: 12
    color: on ? Theme.raised : (navHit.containsMouse ? Theme.card : "transparent")
    Behavior on color { ColorAnimation { duration: 110 } }
    Rectangle { width: 3; height: 18; radius: 2; color: Theme.gold; visible: nav.on; anchors.verticalCenter: parent.verticalCenter }
    Glyph { x: nav.slim ? (nav.width - width) / 2 : 14; name: nav.icon; color: nav.off ? Theme.faint : nav.on ? Theme.gold : Theme.dim; anchors.verticalCenter: parent.verticalCenter }
    Roll { visible: !nav.slim; x: 44; text: nav.text; width: parent.width - 44 - (nav.badge > 0 || nav.tail !== "" ? 40 : 10); rolling: nav.on || navHit.containsMouse; color: nav.off ? Theme.faint : nav.on ? Theme.cream : Theme.dim; font.weight: nav.on ? 600 : 400; font.pixelSize: nav.off ? 12 : 14; anchors.verticalCenter: parent.verticalCenter }
    Rectangle { visible: nav.badge > 0 && !nav.slim; width: Math.max(22, mark.implicitWidth + 12); height: 20; radius: 10; color: Theme.gold; anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter
        Label { id: mark; text: nav.badge; anchors.centerIn: parent; color: Theme.inkOnGold; font.pixelSize: 12; font.weight: 700 } }
    Rectangle { visible: nav.badge > 0 && nav.slim; width: 8; height: 8; radius: 4; color: Theme.gold; x: nav.width - 12; y: 6 }
    // folded to its icon, its name under the pointer
    QQC.ToolTip.visible: nav.slim && navHit.containsMouse; QQC.ToolTip.delay: 300; QQC.ToolTip.text: nav.text
    MouseArea { id: navHit; anchors.fill: parent; enabled: !nav.off; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: nav.pressed() }
    Rectangle { visible: nav.tail !== ""; width: 28; height: 28; radius: 8; anchors.right: parent.right; anchors.rightMargin: 6; anchors.verticalCenter: parent.verticalCenter
                color: tailHit.containsMouse ? Theme.line : "transparent"
        Glyph { anchors.centerIn: parent; name: nav.tail; color: tailHit.containsMouse ? Theme.cream : Theme.faint; font.pixelSize: 15 }
        MouseArea { id: tailHit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: nav.tailPressed() } }
}
