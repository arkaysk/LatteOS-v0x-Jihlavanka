// A level as a row of small segments, lit from the left: green, then yellow, then red. Not lit: a faint segment.
//   DotBar { width: 120; value: 0.48 }
import QtQuick

Canvas {
    id: bar
    property real value: 0                     // 0…1
    property int segments: 20
    implicitWidth: 120; implicitHeight: 8
    property real shown: value
    Behavior on shown { NumberAnimation { duration: 400 } }
    onShownChanged: requestPaint()
    onWidthChanged: requestPaint()
    Connections { target: Theme; function onCupChanged() { bar.requestPaint() } }
    onPaint: {
        const g = getContext("2d")
        g.clearRect(0, 0, width, height)
        const step = width / segments, on = Math.round(Math.min(1, Math.max(0, shown)) * segments)
        for (let i = 0; i < segments; i++) {
            const t = (i + 0.5) / segments
            g.globalAlpha = i < on ? 1 : 0.1
            g.fillStyle = i < on ? Theme.heat(t) : Theme.cream
            g.beginPath(); g.roundedRect ? g.roundedRect(i * step, 0, step - 1.5, height, 1.5, 1.5) : g.rect(i * step, 0, step - 1.5, height); g.fill()
        }
    }
}
