// The island's shape: a body with round corners and two inverted corners that melt it into the screen's edge.
// From K4 by k4ditano (https://github.com/k4ditano/k4, core/SiluetaIsla.qml, MIT; TRETIE-STRANY.md), cut down to the
// top and the bottom edge, which are all LensShore lives on.
//
// Mind small sizes: the path needs 2 · (wing + radius) along the edge to close, so both radii are bounded by the
// length as well as by the depth.
import QtQuick
import QtQuick.Shapes

Shape {
    id: shape
    property real ala: 16                      // how far each inverted corner bites inwards
    property real cuerpoRadio: 22              // the roundness of the two corners away from the edge
    property color relleno: "black"
    property bool reflejada: false             // on the bottom edge: drawn upside down

    // CurveRenderer is smoother but drops the inverted corners, so MSAA it is
    antialiasing: true
    layer.enabled: true
    layer.samples: 8
    layer.smooth: true

    ShapePath {
        id: path
        fillColor: shape.relleno
        strokeWidth: 0
        strokeColor: "transparent"

        readonly property real w: shape.width
        readonly property real h: shape.height
        readonly property real g: Math.max(0, Math.min(shape.ala, path.h / 2, path.w / 6))
        readonly property real r: Math.max(0, Math.min(shape.cuerpoRadio, path.h / 2, path.w / 3 - path.g))
        // (u along the edge, v into the screen) to the item's box; the mirror turns the arcs round too
        function py(v) { return shape.reflejada ? path.h - v : v }
        readonly property int inward: shape.reflejada ? PathArc.Counterclockwise : PathArc.Clockwise
        readonly property int outward: shape.reflejada ? PathArc.Clockwise : PathArc.Counterclockwise

        startX: 0; startY: path.py(0)
        PathArc { x: path.g; y: path.py(path.g); radiusX: path.g; radiusY: path.g; direction: path.inward }
        PathLine { x: path.g; y: path.py(path.h - path.r) }
        PathArc { x: path.g + path.r; y: path.py(path.h); radiusX: path.r; radiusY: path.r; direction: path.outward }
        PathLine { x: path.w - path.g - path.r; y: path.py(path.h) }
        PathArc { x: path.w - path.g; y: path.py(path.h - path.r); radiusX: path.r; radiusY: path.r; direction: path.outward }
        PathLine { x: path.w - path.g; y: path.py(path.g) }
        PathArc { x: path.w; y: path.py(0); radiusX: path.g; radiusY: path.g; direction: path.inward }
        PathLine { x: 0; y: path.py(0) }
    }
}
