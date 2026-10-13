// Device Manager: what this computer is made of, and whether every part of it works.
// bin/latte-devices knows; this window shows it. It changes nothing: the network, the sound and Bluetooth are
// set from the shore's panel on the desktop.   latte-app devices [GROUP]
//
// The pages: the overview (the computer, its screens, every group as a tile, what latte-boot found) and one
// group (its devices, each with its driver and whether it works).
import QtQuick
import Quickshell
import Quickshell.Io
import "common"

ShellRoot {
    id: shell
    readonly property var words: (Quickshell.env("LATTE_APP_ARGS") || "").split("\n").filter(w => w !== "")
    property string page: ""                   // a group's id; "" is the overview
    property var all: null                     // what latte-devices said
    readonly property var groups: all ? all.groups : []
    readonly property var here: groups.find(g => g.id === page) || null
    function faults(group) { return group.devices.filter(d => d.state !== "ok").length }
    // the three ways a device can be, as words and a colour
    readonly property var states: ({ "ok": { text: QT_TR_NOOP("Works"), color: Theme.ok, icon: "circle-check" },
                                     "no-driver": { text: QT_TR_NOOP("No driver"), color: Theme.red, icon: "circle-x" },
                                     "firmware": { text: QT_TR_NOOP("Firmware missing"), color: Theme.gold, icon: "alert-triangle" } })

    Process {
        id: asker
        property string buf: ""
        function ask() { running = false; command = ["latte-devices", "list"]; running = true }
        stdout: StdioCollector { onStreamFinished: asker.buf = this.text }
        onExited: { try { shell.all = JSON.parse(buf) } catch (e) { shell.all = null } }
    }
    Component.onCompleted: { asker.ask(); if (words[0]) page = words[0] }

    // the whole of it as text, for whoever is asked "what do you have?"
    function report() {
        if (!all) return ""
        const c = all.computer
        let out = [c.host + " — " + c.model, c.cpu + " · " + c.threads + " × · " + c.ram_gb + " GB · Linux " + c.kernel, ""]
        for (const g of groups) {
            out.push(g.name)
            for (const d of g.devices) out.push("  " + d.name + (d.detail ? " (" + d.detail + ")" : "") + (d.driver ? " [" + d.driver + "]" : "") + (d.state !== "ok" ? "  !! " + d.state : ""))
        }
        return out.join("\n")
    }

    component Chip: Rectangle {
        property string icon
        property string text
        property color tint: Theme.gold
        visible: text !== ""
        height: 32; width: chipRow.implicitWidth + 24; radius: 16; color: Theme.card
        Row { id: chipRow; anchors.centerIn: parent; spacing: 7
            Glyph { name: icon; font.pixelSize: 15; color: tint; anchors.verticalCenter: parent.verticalCenter }
            Label { text: parent.parent.text; font.pixelSize: 13; color: Theme.dim; anchors.verticalCenter: parent.verticalCenter } }
    }

    FloatingWindow {
        title: I18n.tr("Device Manager")
        implicitWidth: 1120; implicitHeight: 760
        color: Theme.ground
        onClosed: Qt.quit()

        Rectangle {
            id: side
            width: 250; height: parent.height; color: Theme.surface
            Column { x: 14; y: 18; spacing: 4
                Row { x: 6; spacing: 10; height: 40
                    Glyph { name: "cpu"; font.pixelSize: 24; color: Theme.gold; anchors.verticalCenter: parent.verticalCenter }
                    Label { text: I18n.tr("Device Manager"); font.pixelSize: 17; font.weight: 700; anchors.verticalCenter: parent.verticalCenter } }
                Item { width: 1; height: 8 }
                Nav { text: I18n.tr("Overview"); icon: "compass"; on: shell.page === ""; onPressed: shell.page = "" }
                Item { width: 1; height: 10 }
                Label { x: 14; text: I18n.tr("DEVICES"); color: Theme.faint; font.pixelSize: 11; font.weight: 700; font.letterSpacing: 0.8 }
                Item { width: 1; height: 2 }
                Repeater { model: shell.groups
                    Nav { required property var modelData; text: I18n.tr(modelData.name); icon: modelData.icon; height: 36
                          on: shell.page === modelData.id; badge: shell.faults(modelData); onPressed: shell.page = modelData.id } }
            }
            Column { x: 14; spacing: 8; anchors.bottom: parent.bottom; anchors.bottomMargin: 14
                Pill { id: copy; property bool done: false; width: 222; icon: done ? "check" : "copy"; text: done ? I18n.tr("Copied") : I18n.tr("Copy a report")
                       onPressed: { Quickshell.clipboardText = shell.report(); done = true; back.restart() }
                       Timer { id: back; interval: 1800; onTriggered: copy.done = false } }
                Pill { width: 222; icon: "refresh"; text: I18n.tr("Look again"); busy: asker.running; onPressed: asker.ask() }
            }
        }

        Item {
            anchors.left: side.right; anchors.right: parent.right; height: parent.height

            // ── the overview ──────────────────────────────────────────────────────────────────────────────
            Scroll {
                id: over
                visible: shell.page === "" || !shell.here
                Waiting { visible: !shell.all; text: I18n.tr("Looking…"); width: over.room; topPadding: 200 }
                // the computer itself, and beside it whether all of it works
                Rectangle {
                    id: hero
                    visible: shell.all !== null
                    width: over.room; height: 176; radius: 26
                    gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: "#4a3020" } GradientStop { position: 1; color: "#2a1e17" } }
                    readonly property var c: shell.all ? shell.all.computer : ({})
                    readonly property int wrong: shell.all ? shell.all.faults : 0
                    Column { x: 28; width: parent.width - 260; anchors.verticalCenter: parent.verticalCenter; spacing: 6
                        Label { text: hero.c.host || ""; font.pixelSize: 32; font.weight: 800; width: parent.width }
                        Label { text: hero.c.model || ""; color: Theme.dim; font.pixelSize: 15; width: parent.width }
                        Item { width: 1; height: 4 }
                        Flow { width: parent.width; spacing: 8
                            Chip { icon: "cpu"; text: hero.c.cpu ? hero.c.cpu + " · " + hero.c.threads + " ×" : "" }
                            Chip { icon: "cpu-2"; text: hero.c.ram_gb ? hero.c.ram_gb + " GB" : "" }
                            Chip { icon: "settings"; text: hero.c.kernel ? "Linux " + hero.c.kernel.split("-")[0] : "" } } }
                    // a ring that closes, green when nothing is wrong
                    Item { width: 120; height: 120; anchors.right: parent.right; anchors.rightMargin: 44; anchors.verticalCenter: parent.verticalCenter
                        Rectangle { anchors.fill: parent; radius: 60; color: "transparent"; border.width: 8
                                    border.color: hero.wrong > 0 ? Theme.red : Theme.ok; opacity: 0.9
                                    SequentialAnimation on scale { loops: Animation.Infinite; running: hero.wrong > 0
                                        NumberAnimation { to: 1.06; duration: 700; easing.type: Easing.InOutQuad } NumberAnimation { to: 1; duration: 700; easing.type: Easing.InOutQuad } } }
                        Glyph { anchors.centerIn: parent; visible: hero.wrong === 0; name: "check"; font.pixelSize: 54; color: Theme.ok }
                        Label { anchors.centerIn: parent; visible: hero.wrong > 0; text: hero.wrong; font.pixelSize: 46; font.weight: 800; color: Theme.red } }
                    Label { anchors.right: parent.right; anchors.rightMargin: 24; anchors.bottom: parent.bottom; anchors.bottomMargin: 8; width: 160; horizontalAlignment: Text.AlignHCenter; font.pixelSize: 12
                            color: Theme.dim; text: hero.wrong > 0 ? I18n.tr("need attention") : I18n.tr("Everything works") }
                }
                // every group as a tile
                Flow { width: over.room; spacing: 14
                    Repeater { model: shell.groups
                        Rectangle {
                            id: tile
                            required property var modelData
                            readonly property int wrong: shell.faults(modelData)
                            readonly property int each: Math.max(1, Math.floor(over.room / 250))
                            width: Math.floor((over.room - 14 * (each - 1)) / each); height: 132; radius: 20
                            color: tileHit.containsMouse ? Theme.raised : Theme.card
                            border.width: 1; border.color: wrong > 0 ? Theme.red : (tileHit.containsMouse ? Qt.rgba(0.97, 0.78, 0.45, 0.45) : "transparent")
                            scale: tileHit.containsMouse ? 1.025 : 1
                            Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: 140 } }
                            MouseArea { id: tileHit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: shell.page = tile.modelData.id }
                            Rectangle { x: 18; y: 18; width: 44; height: 44; radius: 14; color: Theme.ground
                                Glyph { anchors.centerIn: parent; name: tile.modelData.icon; font.pixelSize: 24; color: tile.wrong > 0 ? Theme.red : Theme.gold } }
                            Label { x: 74; y: 20; width: parent.width - 120; text: I18n.tr(tile.modelData.name); font.weight: 700; font.pixelSize: 15; wrapMode: Text.WordWrap; maximumLineCount: 2 }
                            Label { anchors.right: parent.right; anchors.rightMargin: 18; y: 18; text: tile.modelData.devices.length; font.pixelSize: 26; font.weight: 800; color: Theme.faint }
                            Column { x: 18; y: 76; width: parent.width - 36; spacing: 2
                                Repeater { model: tile.modelData.devices.slice(0, 2)
                                    Label { required property var modelData; text: modelData.name; color: modelData.state === "ok" ? Theme.dim : Theme.red; font.pixelSize: 12; width: parent.width } } }
                        } } }
                // what latte-boot found about the computer as a whole
                Column { width: over.room; spacing: 8; visible: shell.all && shell.all.findings.length > 0
                    Label { text: I18n.tr("GOOD TO KNOW"); color: Theme.faint; font.pixelSize: 11; font.weight: 700; font.letterSpacing: 0.8 }
                    Repeater { model: shell.all ? shell.all.findings : []
                        Rectangle { required property var modelData; width: over.room; height: note.implicitHeight + 28; radius: 16; color: Theme.card
                            Glyph { x: 16; y: 14; name: parent.modelData.level === "info" ? "info-circle" : "alert-triangle"; color: parent.modelData.level === "info" ? Theme.coffee : Theme.gold }
                            Column { id: note; x: 48; y: 14; width: parent.width - 64; spacing: 3
                                Label { text: parent.parent.modelData.text; width: parent.width; wrapMode: Text.WordWrap }
                                Label { text: parent.parent.modelData.fix; visible: text !== ""; color: Theme.dim; font.pixelSize: 12; width: parent.width; wrapMode: Text.WordWrap } } } } }
            }

            // ── one group ─────────────────────────────────────────────────────────────────────────────────
            Scroll {
                id: group
                visible: shell.here !== null
                Row { spacing: 14
                    Pill { icon: "chevron-left"; text: I18n.tr("Overview"); onPressed: shell.page = "" }
                    Glyph { name: shell.here ? shell.here.icon : ""; font.pixelSize: 26; color: Theme.gold; anchors.verticalCenter: parent.verticalCenter }
                    Label { text: shell.here ? I18n.tr(shell.here.name) : ""; font.pixelSize: 26; font.weight: 800; anchors.verticalCenter: parent.verticalCenter } }
                // screens are drawn as they are shaped, side by side
                Row { visible: shell.page === "displays"; spacing: 18; height: 150
                    Repeater { model: shell.page === "displays" && shell.here ? shell.here.devices : []
                        Rectangle { required property var modelData
                            readonly property real ratio: modelData.size && modelData.size.length === 2 && modelData.size[1] > 0 ? modelData.size[0] / modelData.size[1] : 16 / 9
                            height: 130; width: height * ratio; radius: 10; color: Theme.ground; border.width: 3; border.color: Theme.coffee; anchors.bottom: parent.bottom
                            Rectangle { width: parent.width * 0.3; height: 8; radius: 4; color: Theme.coffee; anchors.horizontalCenter: parent.horizontalCenter; anchors.top: parent.bottom; anchors.topMargin: 4 }
                            Label { anchors.centerIn: parent; text: parent.modelData.name; font.weight: 700; width: parent.width - 16; horizontalAlignment: Text.AlignHCenter } } } }
                Column { width: group.room; spacing: 10
                    Repeater { model: shell.here ? shell.here.devices : []
                        Rectangle { id: dev; required property var modelData
                            readonly property var how: shell.states[modelData.state] || shell.states.ok
                            width: group.room; height: 76; radius: 18; color: Theme.card; border.width: 1; border.color: modelData.state === "ok" ? "transparent" : how.color
                            Rectangle { x: 16; width: 44; height: 44; radius: 14; color: Theme.ground; anchors.verticalCenter: parent.verticalCenter
                                Glyph { anchors.centerIn: parent; name: shell.here ? shell.here.icon : ""; font.pixelSize: 22; color: dev.how.color } }
                            Column { x: 76; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 76 - ends.width - 28; spacing: 3
                                Label { text: dev.modelData.name; font.weight: 600; font.pixelSize: 15; width: parent.width }
                                Label { text: dev.modelData.detail; visible: text !== ""; color: Theme.dim; font.pixelSize: 12; width: parent.width } }
                            Row { id: ends; anchors.right: parent.right; anchors.rightMargin: 16; anchors.verticalCenter: parent.verticalCenter; spacing: 8
                                Chip { icon: "settings"; text: dev.modelData.driver; color: Theme.ground }
                                Chip { icon: dev.how.icon; tint: dev.how.color; text: I18n.tr(dev.how.text); color: Theme.ground } } } } }
            }
        }
    }
}
