// The surface of the coffee at the foot of an app's window. It laps a little all the time, and when the window
// is carried about it swings as coffee in a carried cup does: it piles up against the side the window came
// from, swings back, and settles. What moves it is how fast the window changes its speed (window-place says
// where the window is). Put it at the bottom of a window, as wide as the window; what stands in the coffee goes
// inside it.
//   Surface { anchors.bottom: parent.bottom; width: parent.width; depth: 54 }
import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io

Item {
    id: sea
    property real depth: 54                    // how deep the coffee stands at rest
    property color coffee: "#3b1d10"
    property color crema: "#a8683c"            // the line of the surface
    property bool lively: (Quickshell.env("LATTE_TIER") || "") !== "software"
    height: depth + 40                         // room above the surface for it to swing into
    default property alias content: floor.data

    // the swing: the tilt of the whole surface, a second wave across it, and the level going up and down
    property real tilt: 0
    property real tiltSpeed: 0
    property real bow: 0
    property real bowSpeed: 0
    property real bob: 0
    property real bobSpeed: 0
    property real clock: 0
    readonly property real energy: Math.abs(tilt) * width + Math.abs(tiltSpeed) * width * 0.2 + Math.abs(bow) + Math.abs(bob)

    // the window's own movement, as window-place tells it
    property var last: null                    // { x, y, t, vx, vy }
    function carried(x, y) {
        const now = Date.now() / 1000
        // the first word after a rest comes late (window-place asks slowly while nothing moves): until then it stood still
        if (!last || now - last.t >= 0.4) last = { x: last ? last.x : x, y: last ? last.y : y, t: now - 0.2, vx: 0, vy: 0 }
        const dt = Math.max(now - last.t, 0.012)
        const vx = (x - last.x) / dt, vy = (y - last.y) / dt
        // a change of speed is a push: to the right, and the coffee climbs the left side
        tiltSpeed += Math.max(-1, Math.min(1, (vx - last.vx) / 2000)) * 0.75
        bowSpeed += Math.min(1, Math.abs(vx - last.vx) / 2000) * 40
        bobSpeed += Math.max(-1, Math.min(1, (vy - last.vy) / 2000)) * 70
        last = { x: x, y: y, t: now, vx: vx, vy: vy }
    }
    Process {
        running: sea.lively
        command: [(Quickshell.env("LATTE_SHARE") || "/usr/share/latteos") + "/apps/common/window-place"]
        stdout: SplitParser { onRead: line => { const p = line.split(" "); if (p.length === 2) sea.carried(parseInt(p[0]), parseInt(p[1])) } }
    }
    // when nothing has told of the window for a moment it has stopped: that is a change of speed too
    Timer { interval: 120; repeat: true; running: sea.last !== null && (sea.last.vx !== 0 || sea.last.vy !== 0)
            onTriggered: if (Date.now() / 1000 - sea.last.t > 0.1) sea.carried(sea.last.x, sea.last.y) }

    Timer {
        interval: sea.energy > 0.6 ? 16 : 40   // at rest it only laps: a slower beat is enough
        repeat: true; running: sea.lively && sea.visible
        onTriggered: {
            const dt = interval / 1000, w = 5.6, w2 = 11.5
            sea.tiltSpeed += (-w * w * sea.tilt - 2 * 0.11 * w * sea.tiltSpeed) * dt
            sea.tilt = Math.max(-0.09, Math.min(0.09, sea.tilt + sea.tiltSpeed * dt))
            sea.bowSpeed += (-w2 * w2 * sea.bow - 2 * 0.16 * w2 * sea.bowSpeed) * dt
            sea.bow = Math.max(-14, Math.min(14, sea.bow + sea.bowSpeed * dt))
            sea.bobSpeed += (-64 * sea.bob - 6 * sea.bobSpeed) * dt
            sea.bob = Math.max(-12, Math.min(12, sea.bob + sea.bobSpeed * dt))
            sea.clock += dt
        }
    }

    // how high the surface stands at x, from the bottom
    function level(x) {
        const lap = lively ? 1.6 * Math.sin(x * 0.018 - clock * 1.1) + 1.1 * Math.sin(x * 0.041 + clock * 0.7) : 0
        return Math.max(6, depth + (width / 2 - x) * tilt * (width > 0 ? Math.min(1, 900 / width) : 1) - bow * Math.cos(2 * Math.PI * x / Math.max(width, 1)) - bob + lap)
    }
    readonly property var line: {
        clock; tilt; bow; bob                  // drawn again whenever any of them changes
        const pts = [Qt.point(0, height)]
        const n = Math.max(12, Math.round(width / 28))
        for (let i = 0; i <= n; i++) { const x = width * i / n; pts.push(Qt.point(x, height - level(x))) }
        pts.push(Qt.point(width, height))
        return pts
    }
    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: sea.crema; strokeWidth: 1.6
            fillGradient: LinearGradient { x1: 0; y1: sea.height - sea.depth - 20; x2: 0; y2: sea.height
                GradientStop { position: 0; color: Qt.lighter(sea.coffee, 1.25) } GradientStop { position: 1; color: sea.coffee } }
            PathPolyline { path: sea.line }
        }
    }
    // what stands in the coffee: it goes up and down with it a little
    Item { id: floor; width: parent.width; height: sea.depth; y: sea.height - sea.depth + sea.bob * 0.5 }
}
