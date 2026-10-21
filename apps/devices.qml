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
    Component.onCompleted: { asker.ask(); if (words[0]) page = words[0]; asList = words[1] === "list" }       // latte-app devices inspector list

    // ── the network: how this computer is connected, and who else is on its network ───────────────────────
    component Net: Process {
        id: n
        property var data: null
        property string buf: ""
        function ask(args) { running = false; command = ["latte-network"].concat(args); running = true }
        stdout: StdioCollector { onStreamFinished: n.buf = this.text }
        onExited: { try { data = JSON.parse(buf) } catch (e) {} }
    }
    Net { id: link }
    Net { id: dnsq }                           // which name servers the connections use
    Net { id: dnsSet; onExited: { dnsq.ask(["dns"]); link.ask(["status"]) } }
    readonly property var dnsModes: [{ id: "auto", name: QT_TR_NOOP("From the router"), note: QT_TR_NOOP("As it came; nothing is filtered.") },
        { id: "cloudflare", name: "Cloudflare", note: QT_TR_NOOP("Quick, and keeps no record of what you look up.") },
        { id: "quad9", name: "Quad9", note: QT_TR_NOOP("Blocks addresses known to spread malware.") },
        { id: "adguard", name: "AdGuard", note: QT_TR_NOOP("Blocks ads and trackers too, for every app at once.") },
        { id: "google", name: "Google", note: QT_TR_NOOP("Quick; Google sees what you look up.") }]
    Net { id: lan }                            // the last look, then a new one
    Net { id: note; onExited: lan.ask(["last"]) }
    property string chosen: ""                 // the device picked on the radar, by its key
    property bool asList: false                // the devices as a list, which holds many better than the radar
    property string capFilter: ""              // the list shows only what can do this; "" all
    readonly property var picked: lan.data ? (lan.data.devices.find(d => d.key === chosen) || null) : null
    onPageChanged: {
        if (page === "connection") { link.ask(["status"]); dnsq.ask(["dns"]) }
        if (page === "inspector") { if (!lan.data) lan.ask(["last"]); look.restart() }
    }
    Timer { id: look; interval: 400; onTriggered: lan.ask(["scan"]) }
    readonly property var kinds: [{ id: "pc", name: QT_TR_NOOP("Computer"), icon: "device-desktop" }, { id: "phone", name: QT_TR_NOOP("Phone or tablet"), icon: "device-mobile" },
        { id: "tv", name: QT_TR_NOOP("Television"), icon: "device-tv" }, { id: "audio", name: QT_TR_NOOP("Speaker"), icon: "device-speaker" },
        { id: "printer", name: QT_TR_NOOP("Printer"), icon: "printer" }, { id: "nas", name: QT_TR_NOOP("Storage"), icon: "server" },
        { id: "home", name: QT_TR_NOOP("Smart home"), icon: "bulb" }, { id: "camera", name: QT_TR_NOOP("Camera"), icon: "camera" }, { id: "router", name: QT_TR_NOOP("Router"), icon: "router" },
        { id: "device", name: QT_TR_NOOP("Other device"), icon: "devices" }]
    function kind(id) { return kinds.find(k => k.id === id) || kinds[kinds.length - 1] }
    // what a device can do, as the closer look found it (latte-network inspect)
    readonly property var caps: ({ "cast": { name: QT_TR_NOOP("Cast to it"), icon: "cast" }, "airplay": { name: QT_TR_NOOP("AirPlay"), icon: "cast" },
        "play-to": { name: QT_TR_NOOP("Play music and video on it"), icon: "player-play" }, "media": { name: QT_TR_NOOP("Shares music and video"), icon: "movie" },
        "camera": { name: QT_TR_NOOP("Camera picture"), icon: "camera" }, "print": { name: QT_TR_NOOP("Prints"), icon: "printer" },
        "files": { name: QT_TR_NOOP("Shared files"), icon: "folder" }, "remote": { name: QT_TR_NOOP("Remote access"), icon: "terminal-2" },
        "smart-home": { name: QT_TR_NOOP("Smart home"), icon: "bulb" }, "web": { name: QT_TR_NOOP("Settings page"), icon: "world-www" } })
    readonly property var levels: ({ "high": Theme.red, "medium": Theme.gold, "low": Theme.dim, "info": Theme.dim })
    function called(d) { return d.name || d.vendor || I18n.tr(kind(d.kind).name) }
    function ago(t) {
        const s = Date.now() / 1000 - t
        return s < 600 ? I18n.tr("now") : s < 86400 ? I18n.tr("today") : I18n.tr("{n} days ago", { n: Math.round(s / 86400) })
    }

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

    AppWindow {
        title: I18n.tr("Device Manager")
        heading: shell.here ? I18n.tr(shell.here.name) : (shell.page === "connection" ? I18n.tr("Connection") : (shell.page === "inspector" ? I18n.tr("Network inspector") : I18n.tr("Device Manager")))
        implicitWidth: 1120; implicitHeight: 760
        arrows: true; canGoBack: shell.page !== ""; onBack: shell.page = ""
        tools: [
            Pill { id: copy; property bool done: false; implicitHeight: 34; icon: done ? "check" : "copy"; text: done ? I18n.tr("Copied") : I18n.tr("Copy a report")
                   onPressed: { Quickshell.clipboardText = shell.report(); done = true; again.restart() }
                   Timer { id: again; interval: 1800; onTriggered: copy.done = false } },
            Pill { implicitHeight: 34; icon: "shield-check"; visible: shell.page === "inspector"; text: I18n.tr("Check closely"); busy: lan.running && lan.command[1] === "inspect"
                   onPressed: lan.ask(["inspect"]) },
            Pill { implicitHeight: 34; icon: "refresh"; text: I18n.tr("Look again"); busy: asker.running || lan.running
                   onPressed: shell.page === "inspector" ? lan.ask(["scan"]) : (shell.page === "connection" ? link.ask(["status"]) : asker.ask()) }
        ]
        side: [
            Column { x: 14; y: 14; spacing: 4
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
                Item { width: 1; height: 10 }
                Label { x: 14; text: I18n.tr("NETWORK"); color: Theme.faint; font.pixelSize: 11; font.weight: 700; font.letterSpacing: 0.8 }
                Item { width: 1; height: 2 }
                Nav { text: I18n.tr("Connection"); icon: "network"; height: 36; on: shell.page === "connection"; onPressed: shell.page = "connection" }
                Nav { text: I18n.tr("Network inspector"); icon: "radar-2"; height: 36; on: shell.page === "inspector"; onPressed: shell.page = "inspector"
                      badge: lan.data ? lan.data.devices.filter(d => d.fresh).length : 0 }
            }
        ]

            // ── the overview ──────────────────────────────────────────────────────────────────────────────
            Scroll {
                id: over
                visible: shell.page === "" || (!shell.here && shell.page !== "connection" && shell.page !== "inspector")
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

            // ── how this computer is connected ────────────────────────────────────────────────────────────
            Scroll {
                id: conn
                visible: shell.page === "connection"
                Waiting { visible: !link.data; text: I18n.tr("Looking…"); width: conn.room; topPadding: 160 }
                Label { visible: link.data && link.data.connections.length === 0; text: I18n.tr("This computer is not connected to any network."); color: Theme.dim; topPadding: 60 }
                Repeater { model: link.data ? link.data.connections : []
                    Rectangle { id: c; required property var modelData; width: conn.room; height: 190; radius: 24
                        gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: "#33402e" } GradientStop { position: 1; color: Theme.card } }
                        Rectangle { x: 26; y: 26; width: 56; height: 56; radius: 18; color: Theme.ground
                            Glyph { anchors.centerIn: parent; name: c.modelData.type === "wifi" ? "wifi" : "network"; font.pixelSize: 30; color: Theme.ok } }
                        Label { x: 98; y: 26; text: c.modelData.name; font.pixelSize: 24; font.weight: 800; width: parent.width - 130 }
                        Label { x: 98; y: 58; color: Theme.dim; text: (c.modelData.type === "wifi" ? "Wi-Fi" : I18n.tr("Wired network")) + (c.modelData.speed > 0 ? "  ·  " + c.modelData.speed + " Mb/s" : "") + "  ·  " + c.modelData.device }
                        Flow { x: 26; y: 110; width: parent.width - 52; spacing: 10
                            Chip { icon: "device-desktop"; text: I18n.tr("Address") + "  " + c.modelData.ip + "/" + c.modelData.prefix; color: Theme.ground }
                            Chip { icon: "router"; text: I18n.tr("Router") + "  " + c.modelData.gateway; color: Theme.ground }
                            Chip { icon: "world"; text: c.modelData.dns.length ? "DNS  " + c.modelData.dns.join(", ") : ""; color: Theme.ground }
                            Chip { icon: "cpu"; text: c.modelData.mac; color: Theme.ground } } } }
                Column { visible: link.data && link.data.saved.length > 0; width: conn.room; spacing: 8
                    Label { text: I18n.tr("REMEMBERED CONNECTIONS"); color: Theme.faint; font.pixelSize: 11; font.weight: 700; font.letterSpacing: 0.8 }
                    Flow { width: parent.width; spacing: 8
                        Repeater { model: link.data ? link.data.saved : []; Chip { required property string modelData; icon: "network"; text: modelData } } } }
                // who answers the computer's questions for addresses: one choice that protects every app at once
                Column { visible: link.data !== null && link.data.connections.length > 0; width: conn.room; spacing: 8
                    Label { text: I18n.tr("PROTECTION (NAME SERVERS)"); color: Theme.faint; font.pixelSize: 11; font.weight: 700; font.letterSpacing: 0.8 }
                    Flow { width: parent.width; spacing: 10
                        Repeater { model: shell.dnsModes
                            Rectangle { id: dm; required property var modelData; width: (conn.room - 40) / 5; height: 116; radius: 18
                                readonly property bool on: dnsq.data && dnsq.data.mode === modelData.id
                                color: on ? Qt.rgba(Theme.gold.r, Theme.gold.g, Theme.gold.b, 0.18) : Theme.card; border.width: on ? 1 : 0; border.color: Theme.gold
                                Column { x: 14; y: 12; width: parent.width - 28; spacing: 4
                                    Row { spacing: 6
                                        Glyph { name: dm.on ? "circle-check" : "shield"; font.pixelSize: 16; color: dm.on ? Theme.gold : Theme.dim }
                                        Label { text: I18n.tr(dm.modelData.name); font.weight: 700 } }
                                    Label { width: parent.width; wrapMode: Text.WordWrap; color: Theme.dim; font.pixelSize: 12; text: I18n.tr(dm.modelData.note) } }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; enabled: !dm.on && !dnsSet.running; onClicked: dnsSet.ask(["dns", dm.modelData.id]) } } } }
                    Label { width: conn.room; wrapMode: Text.WordWrap; color: Theme.dim; font.pixelSize: 12
                            text: dnsSet.running ? I18n.tr("Changing… the network is away for a moment.") : I18n.tr("It applies to this computer only; for every device at home, the same can be set in the router.") } }
                Label { text: I18n.tr("Wi-Fi, Bluetooth and the networks in range are in the panel of the screen's corner (Win+A)."); color: Theme.dim; font.pixelSize: 12; width: conn.room; wrapMode: Text.WordWrap }
            }

            // ── who else is on the network: a radar ───────────────────────────────────────────────────────
            Item {
                id: radar
                anchors.fill: parent
                visible: shell.page === "inspector"
                readonly property var all: lan.data ? lan.data.devices.filter(d => !d.router) : []
                readonly property var near: all.filter(d => d.online)
                readonly property var gone: all.filter(d => !d.online)
                property real cx: (width - (shell.picked ? 300 : 0)) / 2
                readonly property real cy: height - 120
                readonly property real r1: Math.min(cx - 90, cy - 70) * 0.55
                readonly property real r2: Math.min(cx - 90, cy - 70)
                Behavior on cx { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                Row { x: 28; y: 20; spacing: 10; z: 3
                    Label { anchors.verticalCenter: parent.verticalCenter; color: Theme.dim
                            text: lan.data ? I18n.tr("{n} here now", { n: radar.near.length }) + (radar.gone.length ? "  ·  " + I18n.tr("{n} seen before", { n: radar.gone.length }) : "") : "" }
                    Pill { implicitHeight: 30; icon: "radar-2"; text: I18n.tr("Radar"); strong: !shell.asList; onPressed: shell.asList = false }
                    Pill { implicitHeight: 30; icon: "list"; text: I18n.tr("List"); strong: shell.asList; onPressed: shell.asList = true } }
                // how safe the network is, after a closer look: a score, and what to do, the worst first
                Rectangle {
                    id: safety
                    readonly property var h: lan.data && lan.data.health ? lan.data.health : null
                    visible: h !== null; z: 3
                    x: 28; y: 56; width: Math.min(420, radar.width * 0.4); height: safeCol.implicitHeight + 28; radius: 20; color: Theme.card
                    Column { id: safeCol; x: 18; y: 14; width: parent.width - 36; spacing: 8
                        Row { spacing: 12
                            Label { text: safety.h ? String(safety.h.score) : ""; font.pixelSize: 34; font.weight: 800
                                    color: !safety.h ? Theme.cream : safety.h.score >= 90 ? Theme.ok : safety.h.score >= 60 ? Theme.gold : Theme.red }
                            Column { anchors.verticalCenter: parent.verticalCenter; spacing: 2
                                Label { text: I18n.tr("Network safety"); font.weight: 700 }
                                Label { text: safety.h && safety.h.findings.filter(f => f.level !== "info").length === 0 ? I18n.tr("Nothing weak was found.") : I18n.tr("of 100; what to do is below"); color: Theme.dim; font.pixelSize: 12 } } }
                        Repeater { model: safety.h ? safety.h.findings.slice(0, 5) : []
                            Row { required property var modelData; spacing: 8; width: safeCol.width
                                Rectangle { width: 8; height: 8; radius: 4; y: 6; color: shell.levels[parent.modelData.level] || Theme.dim }
                                Column { width: parent.width - 16; spacing: 2
                                    Label { width: parent.width; wrapMode: Text.WordWrap; font.pixelSize: 13; font.weight: 600; text: parent.parent.modelData.device + ": " + I18n.tr(parent.parent.modelData.what) }
                                    Label { width: parent.width; wrapMode: Text.WordWrap; font.pixelSize: 12; color: Theme.dim; text: I18n.tr(parent.parent.modelData.fix) } } } } }
                }
                // the two arcs: who is here now, and who was
                Repeater { model: [radar.r1, radar.r2]
                    Rectangle { required property real modelData; required property int index; visible: !shell.asList; x: radar.cx - modelData; y: radar.cy - modelData; width: modelData * 2; height: modelData * 2; radius: modelData
                                color: "transparent"; border.width: 1; border.color: index === 0 ? Theme.coffee : Theme.line; opacity: index === 0 ? 0.7 : 0.6 } }
                // the sweep, while it looks
                Rectangle { visible: lan.running && lan.command[1] === "scan"; x: radar.cx; y: radar.cy - 1; width: radar.r2; height: 2; transformOrigin: Item.Left
                            gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: Theme.gold } GradientStop { position: 1; color: "transparent" } }
                            NumberAnimation on rotation { running: lan.running; from: -180; to: 0; duration: 1600; loops: Animation.Infinite } }
                // what is below the middle line is not part of the picture
                Rectangle { x: 0; y: radar.cy + 2; width: parent.width; height: parent.height; color: Theme.ground }
                // this computer, and under it the router
                component Spot: Column {
                    id: spot
                    property var device: null
                    property string icon
                    property string text
                    property string under
                    property bool faded: false
                    property bool fresh: false
                    property bool on: false
                    signal pressed()
                    spacing: 5; width: 120
                    Rectangle { width: 54; height: 54; radius: 27; anchors.horizontalCenter: parent.horizontalCenter
                        color: spot.on ? Theme.raised : Theme.card; opacity: spot.faded ? 0.5 : 1
                        border.width: spot.fresh || spot.on ? 2 : 1; border.color: spot.fresh ? Theme.gold : (spot.on ? Theme.cream : Theme.line)
                        scale: spotHit.containsMouse ? 1.12 : 1; Behavior on scale { NumberAnimation { duration: 140 } }
                        Glyph { anchors.centerIn: parent; name: spot.icon; font.pixelSize: 26; color: spot.fresh ? Theme.gold : Theme.cream }
                        MouseArea { id: spotHit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: spot.pressed() } }
                    Label { text: spot.text; font.pixelSize: 12; font.weight: 600; width: parent.width; horizontalAlignment: Text.AlignHCenter; opacity: spot.faded ? 0.6 : 1 }
                    Label { text: spot.under; font.pixelSize: 11; color: Theme.faint; width: parent.width; horizontalAlignment: Text.AlignHCenter; visible: text !== "" }
                }
                Spot { x: radar.cx - 60; y: radar.cy - 92; icon: "device-desktop"; text: lan.data && lan.data.me ? lan.data.me.name : ""; under: lan.data && lan.data.me ? lan.data.me.ip : "" }
                Spot { x: radar.cx - 60; y: radar.cy + 24; icon: "router"; text: I18n.tr("Router"); under: lan.data ? lan.data.gateway : ""
                       readonly property var dev: lan.data ? lan.data.devices.find(d => d.router) : null
                       on: dev && shell.chosen === dev.key; onPressed: if (dev) shell.chosen = dev.key }
                Repeater { model: [{ list: radar.near, r: radar.r1 }, { list: radar.gone, r: radar.r2 }]
                    Item { id: ring; required property var modelData; required property int index
                        Repeater { model: ring.modelData.list
                            Spot { required property var modelData; required property int index
                                readonly property real angle: Math.PI * (1 + (index + 1) / (ring.modelData.list.length + 1))
                                x: radar.cx + Math.cos(angle) * ring.modelData.r - 60; y: radar.cy + Math.sin(angle) * ring.modelData.r - 27
                                icon: shell.kind(modelData.kind).icon; text: shell.called(modelData); under: modelData.ip
                                faded: ring.index === 1; fresh: modelData.fresh; on: shell.chosen === modelData.key
                                onPressed: shell.chosen = shell.chosen === modelData.key ? "" : modelData.key } } } }
                // ── the same devices as a list, with what each can do, to be narrowed to one ability ──────────
                Rectangle {
                    visible: shell.asList; z: 2
                    x: 0; y: safety.visible ? safety.y + safety.height + 14 : 56
                    width: radar.width - (shell.picked ? 310 : 0); height: radar.height - y; color: Theme.ground
                    readonly property var everyone: lan.data ? lan.data.devices : []
                    readonly property var abilities: Object.keys(shell.caps).filter(c => everyone.some(d => (d.caps || []).indexOf(c) >= 0))
                    Flow { id: capRow2; x: 28; y: 0; width: parent.width - 56; spacing: 8
                        Pill { implicitHeight: 30; text: I18n.tr("All"); strong: shell.capFilter === ""; onPressed: shell.capFilter = "" }
                        Repeater { model: parent.parent.abilities
                            Pill { required property string modelData; implicitHeight: 30; icon: shell.caps[modelData].icon; text: I18n.tr(shell.caps[modelData].name)
                                   strong: shell.capFilter === modelData; onPressed: shell.capFilter = shell.capFilter === modelData ? "" : modelData } } }
                    ListView {
                        x: 28; y: capRow2.height + 12; width: parent.width - 56; height: parent.height - y - 16; clip: true; spacing: 6
                        model: parent.everyone.filter(d => shell.capFilter === "" || (d.caps || []).indexOf(shell.capFilter) >= 0)
                        delegate: Rectangle { id: row; required property var modelData; width: ListView.view.width; height: 58; radius: 14
                            color: shell.chosen === modelData.key ? Theme.raised : (rowHit.containsMouse ? Theme.card : "transparent")
                            readonly property int weak: lan.data && lan.data.health ? lan.data.health.findings.filter(f => f.ip === modelData.ip && f.level !== "info").length : 0
                            Glyph { x: 14; name: shell.kind(row.modelData.kind).icon; font.pixelSize: 24; color: row.modelData.fresh ? Theme.gold : Theme.cream; opacity: row.modelData.online ? 1 : 0.5; anchors.verticalCenter: parent.verticalCenter }
                            Column { x: 52; width: 260; anchors.verticalCenter: parent.verticalCenter; spacing: 2
                                Label { text: shell.called(row.modelData); font.weight: 600; width: parent.width; elide: Text.ElideRight; opacity: row.modelData.online ? 1 : 0.6 }
                                Label { text: row.modelData.ip + (row.modelData.vendor ? "  ·  " + row.modelData.vendor : ""); color: Theme.dim; font.pixelSize: 12; width: parent.width; elide: Text.ElideRight } }
                            Row { x: 330; spacing: 6; anchors.verticalCenter: parent.verticalCenter
                                Repeater { model: (row.modelData.caps || []).slice(0, 5)
                                    Glyph { required property string modelData; name: (shell.caps[modelData] || {}).icon || "point"; font.pixelSize: 16; color: Theme.gold } } }
                            Label { visible: row.weak > 0; anchors.right: parent.right; anchors.rightMargin: 16; anchors.verticalCenter: parent.verticalCenter; color: Theme.red; font.pixelSize: 12; font.weight: 700
                                    text: I18n.tr("{n} to fix", { n: row.weak }) }
                            MouseArea { id: rowHit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: shell.chosen = shell.chosen === row.modelData.key ? "" : row.modelData.key } } }
                }
                Label { visible: lan.data && lan.data.offline === true; anchors.centerIn: parent; text: I18n.tr("This computer is not connected to any network."); color: Theme.dim }
                // the device that was picked: what is known of it, and what the user calls it
                Rectangle {
                    visible: shell.picked !== null
                    anchors.right: parent.right; anchors.rightMargin: 20; y: 20; width: 290; height: parent.height - 40; radius: 22; color: Theme.card
                    Column { x: 20; y: 20; width: parent.width - 40; spacing: 10
                        Row { spacing: 12
                            Glyph { name: shell.picked ? shell.kind(shell.picked.kind).icon : ""; font.pixelSize: 30; color: Theme.gold }
                            Label { text: shell.picked ? shell.called(shell.picked) : ""; font.pixelSize: 18; font.weight: 800; width: 200; wrapMode: Text.WordWrap; maximumLineCount: 2 } }
                        Label { color: Theme.dim; font.pixelSize: 12; width: parent.width; wrapMode: Text.WordWrap; lineHeight: 1.4
                                text: shell.picked ? shell.picked.ip + "\n" + shell.picked.mac + (shell.picked.vendor ? "\n" + shell.picked.vendor : "")
                                      + "\n" + (shell.picked.online ? I18n.tr("here now") : I18n.tr("last seen") + " " + shell.ago(shell.picked.last))
                                      + "  ·  " + I18n.tr("first seen") + " " + shell.ago(shell.picked.first) : "" }
                        Rectangle { width: parent.width; height: 38; radius: 12; color: Theme.ground; border.width: 1; border.color: rename.activeFocus ? Theme.gold : "transparent"
                            TextInput { id: rename; x: 12; width: parent.width - 24; anchors.verticalCenter: parent.verticalCenter; color: Theme.cream; font.family: Theme.font; font.pixelSize: 14; clip: true
                                        text: shell.picked ? shell.picked.given : ""; onAccepted: if (shell.picked) note.ask(["name", shell.picked.key, text.trim(), shell.picked.kind]) }
                            Label { x: 12; text: I18n.tr("Give it a name…"); color: Theme.faint; visible: rename.text === "" && !rename.activeFocus; anchors.verticalCenter: parent.verticalCenter } }
                        Label { text: I18n.tr("WHAT IT IS"); color: Theme.faint; font.pixelSize: 11; font.weight: 700; font.letterSpacing: 0.8 }
                        Flow { width: parent.width; spacing: 6
                            Repeater { model: shell.kinds.filter(k => k.id !== "router")
                                Rectangle { required property var modelData; width: 38; height: 38; radius: 12
                                    color: shell.picked && shell.picked.kind === modelData.id ? Theme.gold : Theme.ground
                                    Glyph { anchors.centerIn: parent; name: parent.modelData.icon; font.pixelSize: 20; color: shell.picked && shell.picked.kind === parent.modelData.id ? Theme.ground : Theme.cream }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: note.ask(["name", shell.picked.key, shell.picked.given, parent.modelData.id]) } } } }
                        Label { visible: shell.picked !== null && shell.picked.caps.length > 0; text: I18n.tr("WHAT IT CAN DO"); color: Theme.faint; font.pixelSize: 11; font.weight: 700; font.letterSpacing: 0.8 }
                        Flow { width: parent.width; spacing: 6; visible: shell.picked !== null && shell.picked.caps.length > 0
                            Repeater { model: shell.picked ? shell.picked.caps : []
                                Rectangle { required property string modelData; height: 28; width: capRow.implicitWidth + 20; radius: 14; color: Theme.ground
                                    Row { id: capRow; x: 10; spacing: 6; anchors.verticalCenter: parent.verticalCenter
                                        Glyph { name: (shell.caps[parent.parent.modelData] || {}).icon || "point"; font.pixelSize: 14; color: Theme.gold }
                                        Label { text: I18n.tr((shell.caps[parent.parent.modelData] || { name: parent.parent.modelData }).name); font.pixelSize: 12 } } } } }
                        Label { visible: shell.picked !== null && shell.picked.services.length > 0; width: parent.width; wrapMode: Text.WordWrap; color: Theme.dim; font.pixelSize: 12
                                text: shell.picked ? I18n.tr("Answers on: {list}", { list: shell.picked.services.join(", ") }) : "" }
                        Repeater { model: shell.picked && lan.data && lan.data.health ? lan.data.health.findings.filter(f => f.ip === shell.picked.ip) : []
                            Label { required property var modelData; width: parent.width; wrapMode: Text.WordWrap; font.pixelSize: 12; color: shell.levels[modelData.level] || Theme.dim
                                    text: "• " + I18n.tr(modelData.what) + " — " + I18n.tr(modelData.fix) } }
                        // what can be done with what it can do
                        Pill { visible: shell.picked !== null && shell.picked.caps.indexOf("web") >= 0 && shell.picked.online; icon: "world-www"; text: I18n.tr("Open its settings page")
                               onPressed: { const p = shell.picked.ports; const https = p.indexOf(443) >= 0 ? "" : (p.indexOf(8443) >= 0 ? ":8443" : null)
                                            Quickshell.execDetached(["xdg-open", https !== null ? "https://" + shell.picked.ip + https : "http://" + shell.picked.ip + (p.indexOf(80) >= 0 ? "" : ":8080")]) } }
                        Item { width: 1; height: 4 }
                        Pill { icon: "trash"; danger: true; text: I18n.tr("Forget this device"); onPressed: { note.ask(["forget", shell.picked.key]); shell.chosen = "" } }
                    }
                }
            }
    }
}
