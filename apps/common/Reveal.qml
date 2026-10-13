// One picture giving way to the next (shaders/reveal.frag): `progress` 0 is all the old one, 1 all the new.
// Where Qt draws without a graphics card there are no shaders: the new one fades in over the old.
import QtQuick

Item {
    id: reveal
    property url from
    property url to
    property real progress: 1
    property int kind: 0
    readonly property bool plain: GraphicsInfo.api === GraphicsInfo.Software
    Image { id: old; anchors.fill: parent; source: reveal.from; fillMode: Image.PreserveAspectCrop; asynchronous: true; clip: true
            layer.enabled: !reveal.plain; visible: reveal.plain }
    Image { id: next; anchors.fill: parent; source: reveal.to; fillMode: Image.PreserveAspectCrop; asynchronous: true; clip: true
            layer.enabled: !reveal.plain; visible: reveal.plain; opacity: reveal.plain ? reveal.progress : 1 }
    ShaderEffect {
        anchors.fill: parent; visible: !reveal.plain
        property var from: old
        property var to: next
        property real progress: reveal.progress
        property real kind: reveal.kind
        property real ratio: width / Math.max(1, height)
        fragmentShader: Qt.resolvedUrl("shaders/reveal.frag.qsb")
    }
}
