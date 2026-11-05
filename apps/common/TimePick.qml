// A clock face to set a time with two clicks, as Android does: first the hour (outer ring 1–12, inner ring 13–00), then the
// minute; the minute chosen sets it. The two numbers above can be pressed to go back to the other. It lies over the
// window it is in; a press anywhere else closes it.
//   TimePick { id: timePick }      timePick.open(x, y, "09:30", hm => …)
import QtQuick

Item {
    id: pick
    anchors.fill: parent
    visible: false
    z: 900
    property int hour: 9
    property int minute: 0
    property bool minutes: false               // the minute is being chosen
    property var run: null
    property real px: 0
    property real py: 0
    readonly property real cx: 150             // the centre of the face inside the card
    readonly property real cy: 222
    readonly property real outer: 104          // radius of the ring of 1–12 (and of the minutes)
    readonly property real inner: 68           // radius of the ring of 13–00
    function pad(n) { return (n < 10 ? "0" : "") + n }
    function open(x, y, hm, done) {
        const m = /^(\d{1,2}):(\d{2})$/.exec(hm || "")
        hour = m ? Math.min(23, +m[1]) : 9; minute = m ? Math.min(59, +m[2]) : 0; minutes = false; run = done
        px = Math.max(8, Math.min(x, pick.width - 300 - 8)); py = Math.max(8, Math.min(y, pick.height - 400 - 8))
        visible = true
    }
    function close() { visible = false; run = null }
    // where a press on the face lands: angle clockwise from the top, and the ring
    function choose(mx, my, last) {
        const dx = mx - cx, dy = my - cy
        let a = Math.atan2(dx, -dy) * 180 / Math.PI; if (a < 0) a += 360
        if (!minutes) {
            const k = Math.round(a / 30) % 12, innerRing = Math.hypot(dx, dy) < (outer + inner) / 2
            hour = innerRing ? (k === 0 ? 0 : 12 + k) : (k === 0 ? 12 : k)
            if (last) minutes = true
        } else {
            let m = Math.round(a / 6) % 60
            const five = Math.round(m / 5) * 5; if (Math.abs(m - five) <= 1) m = five % 60     // the numbers are easy to hit
            minute = m
            if (last) { const f = run, v = pad(hour) + ":" + pad(minute); close(); if (f) f(v) }
        }
    }
    // the hand: its angle and its length
    readonly property real handAngle: minutes ? minute * 6 : (hour % 12) * 30
    readonly property real handLength: minutes ? outer : ((hour === 0 || hour > 12) ? inner : outer)

    MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; onPressed: pick.close(); onWheel: w => w.accepted = true }
    Rectangle {
        x: pick.px; y: pick.py; width: 300; height: 400; radius: 16
        color: Qt.rgba(Theme.card.r, Theme.card.g, Theme.card.b, 1); border.width: 1; border.color: Theme.line      // not see-through: a form lies under it
        Rectangle { anchors.fill: parent; anchors.margins: -1; radius: 17; z: -1; color: "transparent"; border.width: 6; border.color: Qt.rgba(0, 0, 0, 0.12) }
        MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }
        // the time as it is now: the part being chosen is filled
        Row { x: 0; y: 18; width: parent.width; height: 64; spacing: 4; leftPadding: (parent.width - 2 * 88 - 20 - 8) / 2
            Rectangle { width: 88; height: 64; radius: 12; color: !pick.minutes ? Theme.gold : Theme.raised
                Text { anchors.centerIn: parent; text: pick.pad(pick.hour); font.family: Theme.font; font.pixelSize: 40; font.weight: 700; color: !pick.minutes ? "#17110d" : Theme.cream }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: pick.minutes = false } }
            Text { width: 20; height: 64; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; text: ":"; font.pixelSize: 40; font.weight: 700; color: Theme.cream }
            Rectangle { width: 88; height: 64; radius: 12; color: pick.minutes ? Theme.gold : Theme.raised
                Text { anchors.centerIn: parent; text: pick.pad(pick.minute); font.family: Theme.font; font.pixelSize: 40; font.weight: 700; color: pick.minutes ? "#17110d" : Theme.cream }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: pick.minutes = true } } }
        Text { x: 0; y: 86; width: parent.width; horizontalAlignment: Text.AlignHCenter; text: pick.minutes ? I18n.tr("Minute") : I18n.tr("Hour"); color: Theme.faint; font.family: Theme.font; font.pixelSize: 12 }
        // the face
        Rectangle { x: pick.cx - 120; y: pick.cy - 120; width: 240; height: 240; radius: 120; color: Theme.raised }
        Rectangle { x: pick.cx - 3; y: pick.cy - 3; width: 6; height: 6; radius: 3; color: Theme.gold }
        Item { x: pick.cx; y: pick.cy; rotation: pick.handAngle
            Rectangle { x: -1; y: -pick.handLength; width: 2; height: pick.handLength; color: Theme.gold }
            Rectangle { x: -18; y: -pick.handLength - 18; width: 36; height: 36; radius: 18; color: Theme.gold } }
        // the numbers: hours outside 1–12 and inside 13–00, or the minutes by five
        Repeater { model: pick.minutes ? 12 : 24
            Text { id: num; required property int index
                readonly property int value: pick.minutes ? index * 5 : (index < 12 ? (index === 0 ? 12 : index) : (index === 12 ? 0 : index))
                readonly property real turn: (pick.minutes ? index * 30 : (index % 12) * 30) * Math.PI / 180
                readonly property real r: pick.minutes || index < 12 ? pick.outer : pick.inner
                readonly property bool picked: pick.minutes ? pick.minute === value : pick.hour === value
                x: pick.cx + r * Math.sin(turn) - width / 2; y: pick.cy - r * Math.cos(turn) - height / 2; width: 36; height: 36
                horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                text: pick.pad(value); font.family: Theme.font; font.pixelSize: pick.minutes || index < 12 ? 15 : 13
                color: picked ? "#17110d" : (pick.minutes || index < 12 ? Theme.cream : Theme.dim) } }
        // the minute between the numbers is shown by the hand's end
        Text { visible: pick.minutes && pick.minute % 5 !== 0; x: pick.cx + pick.outer * Math.sin(pick.handAngle * Math.PI / 180) - 18; y: pick.cy - pick.outer * Math.cos(pick.handAngle * Math.PI / 180) - 18
               width: 36; height: 36; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; text: pick.pad(pick.minute); font.family: Theme.font; font.pixelSize: 15; color: "#17110d" }
        MouseArea { x: pick.cx - 125; y: pick.cy - 125; width: 250; height: 250; cursorShape: Qt.PointingHandCursor
                    onPressed: m => pick.choose(m.x + pick.cx - 125, m.y + pick.cy - 125, false)
                    onPositionChanged: m => { if (pressed) pick.choose(m.x + pick.cx - 125, m.y + pick.cy - 125, false) }
                    onReleased: m => pick.choose(m.x + pick.cx - 125, m.y + pick.cy - 125, true) }
    }
}
