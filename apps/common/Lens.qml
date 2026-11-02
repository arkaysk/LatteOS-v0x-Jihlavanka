// A magnifying glass with no frame (shaders/lens.frag): the picture under it, bigger in the middle. A GIF plays. Where
// the picture cannot be read, `fallback` is shown instead. Where Qt draws without a graphics card there are no shaders:
// the picture as it is.
import QtQuick

Item {
    id: lens
    property url source
    property url fallback
    property real zoom: 1.7
    property real light: 1
    property real turn: 0                      // where the light comes from, turned (radians)
    readonly property bool plain: GraphicsInfo.api === GraphicsInfo.Software
    property bool missing: false
    readonly property url shown: missing ? fallback : source
    readonly property bool moving: String(shown).toLowerCase().endsWith(".gif")
    // a GIF plays; anything else is a still picture (AnimatedImage reads only animated formats)
    AnimatedImage { id: anim; anchors.fill: parent; source: lens.moving ? lens.shown : ""; fillMode: Image.PreserveAspectCrop
                    asynchronous: true; playing: lens.visible; layer.enabled: !lens.plain; visible: lens.plain && lens.moving
                    onStatusChanged: if (status === Image.Error && !lens.missing) lens.missing = true }
    Image { id: still; anchors.fill: parent; source: lens.moving ? "" : lens.shown; fillMode: Image.PreserveAspectCrop
            asynchronous: true; layer.enabled: !lens.plain; visible: lens.plain && !lens.moving
            onStatusChanged: if (status === Image.Error && !lens.missing) lens.missing = true }
    ShaderEffect {
        anchors.fill: parent; visible: !lens.plain
        property var source: lens.moving ? anim : still
        property real zoom: lens.zoom
        property real light: lens.light
        property real turn: lens.turn
        fragmentShader: Qt.resolvedUrl("shaders/lens.frag.qsb")
    }
}
