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
    readonly property bool plain: GraphicsInfo.api === GraphicsInfo.Software
    property bool missing: false
    AnimatedImage { id: pic; anchors.fill: parent; source: lens.missing ? lens.fallback : lens.source; fillMode: Image.PreserveAspectCrop
                    asynchronous: true; playing: lens.visible; layer.enabled: !lens.plain; visible: lens.plain
                    onStatusChanged: if (status === Image.Error && !lens.missing) lens.missing = true }
    ShaderEffect {
        anchors.fill: parent; visible: !lens.plain
        property var source: pic
        property real zoom: lens.zoom
        property real light: lens.light
        fragmentShader: Qt.resolvedUrl("shaders/lens.frag.qsb")
    }
}
