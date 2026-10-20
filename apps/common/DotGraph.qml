// The last minute as columns of dots, lit from the bottom up: green low, yellow in the middle, red high (or one
// colour, with `heat: false`). What is not lit stays a faint dot, so the whole picture is always there.
//   DotGraph { width: 300; height: 96; values: [0.2, 0.5, …] }       // 0…1, the newest last
import QtQuick

Canvas {
    id: graph
    property var values: []
    property bool heat: true
    property color tint: Theme.gold
    property int columns: 60                   // as many as seconds in the picture; the newest is at the right
    property real dot: 4
    onValuesChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onTintChanged: requestPaint()
    Connections { target: Theme; function onCupChanged() { graph.requestPaint() } }

    function lit(t) {                          // the colour of a dot at height t (0 bottom … 1 top)
        if (!heat) return tint
        return t < 0.55 ? Theme.mix(Theme.ok, Theme.gold, t / 0.55) : Theme.mix(Theme.gold, Theme.red, (t - 0.55) / 0.45)
    }
    onPaint: {
        const g = getContext("2d")
        g.clearRect(0, 0, width, height)
        const rows = Math.max(1, Math.floor(height / (dot + 1.5))), step = width / columns, d = Math.min(dot, step - 1.2)
        const gap = height / rows, off = columns - values.length
        for (let c = 0; c < columns; c++) {
            const v = c >= off ? Math.min(1, Math.max(0, values[c - off])) : -1
            const on = v < 0 ? 0 : Math.max(1, Math.round(v * rows))
            for (let r = 0; r < rows; r++) {
                g.globalAlpha = r < on ? 1 : 0.1
                g.fillStyle = r < on ? lit((r + 0.5) / rows) : Theme.cream
                g.beginPath(); g.arc(c * step + step / 2, height - r * gap - gap / 2, d / 2, 0, 2 * Math.PI); g.fill()
            }
        }
    }
}
