// A small calendar to pick a day with one click, as Google Calendar and Android offer: the month, ‹ › to turn it, the
// chosen day filled, today ringed. It lies over the window it is in; a press anywhere else closes it.
//   DatePick { id: datePick }      datePick.open(x, y, "2026-05-23", day => …)      x, y: where its corner goes
import QtQuick

Item {
    id: pick
    anchors.fill: parent
    visible: false
    z: 900
    property string value: ""                  // the chosen day, YYYY-MM-DD
    property int year: 2026
    property int month: 0                      // 0–11, the month shown
    property var run: null
    property real px: 0
    property real py: 0
    readonly property var monthNames: [QT_TR_NOOP("January"), QT_TR_NOOP("February"), QT_TR_NOOP("March"), QT_TR_NOOP("April"), QT_TR_NOOP("May"), QT_TR_NOOP("June"),
        QT_TR_NOOP("July"), QT_TR_NOOP("August"), QT_TR_NOOP("September"), QT_TR_NOOP("October"), QT_TR_NOOP("November"), QT_TR_NOOP("December")]
    readonly property var dayNames: [QT_TR_NOOP("Mo"), QT_TR_NOOP("Tu"), QT_TR_NOOP("We"), QT_TR_NOOP("Th"), QT_TR_NOOP("Fr"), QT_TR_NOOP("Sa"), QT_TR_NOOP("Su")]
    function pad(n) { return (n < 10 ? "0" : "") + n }
    function iso(d) { return d.getFullYear() + "-" + pad(d.getMonth() + 1) + "-" + pad(d.getDate()) }
    function open(x, y, day, done) {
        const ok = /^\d{4}-\d{2}-\d{2}$/.test(day || "")
        const d = ok ? new Date(+day.slice(0, 4), +day.slice(5, 7) - 1, +day.slice(8, 10), 12) : new Date()
        value = ok ? day : ""; year = d.getFullYear(); month = d.getMonth(); run = done
        px = Math.max(8, Math.min(x, pick.width - 300 - 8)); py = Math.max(8, Math.min(y, pick.height - 376 - 8))
        visible = true
    }
    function close() { visible = false; run = null }
    function turn(n) { const d = new Date(year, month + n, 1, 12); year = d.getFullYear(); month = d.getMonth() }

    MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; onPressed: pick.close(); onWheel: w => w.accepted = true }
    Rectangle {
        x: pick.px; y: pick.py; width: 300; height: 376; radius: 16
        color: Qt.rgba(Theme.card.r, Theme.card.g, Theme.card.b, 1); border.width: 1; border.color: Theme.line      // not see-through: a form lies under it
        Rectangle { anchors.fill: parent; anchors.margins: -1; radius: 17; z: -1; color: "transparent"; border.width: 6; border.color: Qt.rgba(0, 0, 0, 0.12) }
        MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }
        Text { x: 20; y: 16; height: 32; verticalAlignment: Text.AlignVCenter; text: I18n.tr(pick.monthNames[pick.month]) + " " + pick.year; color: Theme.cream; font.family: Theme.font; font.pixelSize: 16; font.weight: 700 }
        Repeater { model: [-1, 1]
            Rectangle { required property int modelData; x: 300 - 20 - 32 * (modelData > 0 ? 1 : 2) - (modelData > 0 ? 0 : 4); y: 16; width: 32; height: 32; radius: 16; color: arrow.containsMouse ? Theme.raised : "transparent"
                Text { anchors.centerIn: parent; text: Icons.of(parent.modelData < 0 ? "chevron-left" : "chevron-right"); font.family: Theme.icons; font.pixelSize: 18; color: Theme.cream }
                MouseArea { id: arrow; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: pick.turn(parent.modelData) } } }
        Row { x: 14; y: 58
            Repeater { model: pick.dayNames
                Text { required property string modelData; width: 38; horizontalAlignment: Text.AlignHCenter; text: I18n.tr(modelData); color: Theme.faint; font.family: Theme.font; font.pixelSize: 12 } } }
        Grid { x: 14; y: 84; columns: 7
            Repeater { model: 42
                Item { id: cell; required property int index
                    readonly property date day: new Date(pick.year, pick.month, 1 - (new Date(pick.year, pick.month, 1, 12).getDay() + 6) % 7 + index, 12)
                    readonly property bool inside: day.getMonth() === pick.month
                    readonly property bool chosen: pick.iso(day) === pick.value
                    readonly property bool today: pick.iso(day) === pick.iso(new Date())
                    width: 38; height: 40
                    Rectangle { anchors.centerIn: parent; width: 34; height: 34; radius: 17; color: cell.chosen ? Theme.gold : (hit.containsMouse ? Theme.raised : "transparent")
                                border.width: cell.today && !cell.chosen ? 1.5 : 0; border.color: Theme.gold }
                    Text { anchors.centerIn: parent; text: cell.day.getDate(); font.family: Theme.font; font.pixelSize: 14; font.weight: cell.chosen || cell.today ? 700 : 400
                           color: cell.chosen ? "#17110d" : (cell.inside ? Theme.cream : Theme.faint) }
                    MouseArea { id: hit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: { const f = pick.run, v = pick.iso(cell.day); pick.close(); if (f) f(v) } } } } }
        // today, in one click
        Text { x: 20; y: 340; text: I18n.tr("Today"); color: Theme.gold; font.family: Theme.font; font.pixelSize: 13; font.weight: 700
               MouseArea { anchors.fill: parent; anchors.margins: -8; cursorShape: Qt.PointingHandCursor; onClicked: { const f = pick.run, v = pick.iso(new Date()); pick.close(); if (f) f(v) } } }
    }
}
