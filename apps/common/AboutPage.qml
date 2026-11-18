// An app's About page, laid out as GNOME's AdwAboutDialog and KDE's KAboutData show it (name, version, what is new,
// help, credits, licence, source): only the order of the parts is taken, no code. The app gives the words, already
// translated; `tipsAgain` is the app's own "show the tips once more".
import QtQuick
import QtQuick.Controls as QQC

Scroll {
    id: about
    property string name
    property string version
    property string icon: "info-circle"
    property string blurb
    property var notes: []          // what is new in this version: a line each
    property var thanks: []         // [{ name, what, license, url }]: whose work and ideas the app stands on
    property string license
    property string source          // where its code is
    property bool hasTips: false
    signal tipsAgain()
    property bool tipsBack: false

    component Head: Label { color: Theme.faint; font.pixelSize: 11; font.weight: 700; font.letterSpacing: 0.8 }

    // its name and version, and what it is for
    Row { spacing: 18
        Rectangle { width: 72; height: 72; radius: 20; color: Theme.card
            Glyph { anchors.centerIn: parent; name: about.icon; font.pixelSize: 38; color: Theme.gold } }
        Column { spacing: 6; anchors.verticalCenter: parent.verticalCenter; width: about.room - 90
            Row { spacing: 10
                Label { text: about.name; font.pixelSize: 26; font.weight: 800; anchors.verticalCenter: parent.verticalCenter }
                Rectangle { height: 24; width: ver.implicitWidth + 16; radius: 12; color: Theme.card; border.width: 1; border.color: Theme.line; anchors.verticalCenter: parent.verticalCenter
                    Label { id: ver; anchors.centerIn: parent; text: "v" + about.version; font.pixelSize: 12; font.weight: 700; color: Theme.gold } } }
            Label { width: parent.width; wrapMode: Text.WordWrap; color: Theme.dim; text: about.blurb } } }

    Column { width: about.room; spacing: 8; visible: about.notes.length > 0
        Head { text: I18n.tr("NEW IN V{v}", { v: about.version }) }
        Rectangle { width: parent.width; height: notesCol.implicitHeight + 28; radius: 16; color: Theme.card
            Column { id: notesCol; x: 18; y: 14; width: parent.width - 36; spacing: 8
                Repeater { model: about.notes
                    Row { required property var modelData; spacing: 10; width: notesCol.width
                        Glyph { name: "point-filled"; font.pixelSize: 12; color: Theme.gold; y: 3 }
                        Label { width: parent.width - 22; wrapMode: Text.WordWrap; text: modelData } } } } } }

    Column { width: about.room; spacing: 8; visible: about.hasTips
        Head { text: I18n.tr("HELP") }
        Rectangle { width: parent.width; height: 64; radius: 16; color: Theme.card
            Glyph { x: 18; name: "bulb"; font.pixelSize: 20; color: Theme.gold; anchors.verticalCenter: parent.verticalCenter }
            Label { x: 52; width: parent.width - 52 - tipsPill.width - 34; wrapMode: Text.WordWrap; color: Theme.dim; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter
                    text: about.tipsBack ? I18n.tr("The tips are back where they were.") : I18n.tr("Tips you put away with their cross can be shown again.") }
            Pill { id: tipsPill; anchors.right: parent.right; anchors.rightMargin: 16; anchors.verticalCenter: parent.verticalCenter; implicitHeight: 32
                   icon: "refresh"; text: I18n.tr("Show the tips again"); onPressed: { about.tipsBack = true; about.tipsAgain() } } } }

    Column { width: about.room; spacing: 8; visible: about.thanks.length > 0
        Head { text: I18n.tr("THANKS TO") }
        Label { width: parent.width; wrapMode: Text.WordWrap; color: Theme.dim; font.pixelSize: 13
                text: I18n.tr("{n} stands on the work and ideas of these projects. Thank you.", { n: about.name }) }
        Repeater { model: about.thanks
            Rectangle { id: th; required property var modelData; width: about.room; height: 52; radius: 12; color: thHit.containsMouse ? Theme.raised : Theme.card
                QQC.ToolTip.visible: thHit.containsMouse && !!th.modelData.url; QQC.ToolTip.delay: 500; QQC.ToolTip.text: th.modelData.url || ""
                Label { id: thName; x: 18; width: Math.min(implicitWidth, 200); elide: Text.ElideRight; text: th.modelData.name; font.weight: 700; anchors.verticalCenter: parent.verticalCenter }
                Label { x: thName.x + 210; width: parent.width - x - thLic.width - 34; elide: Text.ElideRight; color: Theme.dim; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter; text: th.modelData.what }
                Label { id: thLic; anchors.right: parent.right; anchors.rightMargin: 18; color: Theme.faint; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter; text: th.modelData.license }
                MouseArea { id: thHit; anchors.fill: parent; hoverEnabled: true; enabled: !!th.modelData.url; cursorShape: Qt.PointingHandCursor
                            onClicked: Qt.openUrlExternally(th.modelData.url) } } } }

    Column { width: about.room; spacing: 8
        Head { text: I18n.tr("LICENCE") }
        Row { spacing: 12
            Label { text: about.license; color: Theme.dim; anchors.verticalCenter: parent.verticalCenter }
            Pill { visible: about.source !== ""; implicitHeight: 32; icon: "brand-github"; text: I18n.tr("Source code"); onPressed: Qt.openUrlExternally(about.source) } } }
}
