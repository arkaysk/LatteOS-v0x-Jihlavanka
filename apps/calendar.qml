// Calendar: every calendar of the user's accounts in one window (the design approved 21. 10.:
// claude.ai/artifact/JZr5fi8uL3b6FavXCKUcbU, the week). On the side a new event, the month in small, the calendars to
// show and the year's load in the standard heat; in the middle a day, a week or a month — the hours with the weather
// of each day, a line where now is, and the mouse: drag on an empty place for a new event, drag an event to move it,
// its lower edge to make it longer; on the right the event open, to change (its colour too) or take out.
// bin/latte-cal reads and writes the calendars (Evolution Data Server).   latte-app calendar [day|month | YYYY-MM-DD [SOURCE UID]]
import QtQuick
import Quickshell
import Quickshell.Io
import "common"

ShellRoot {
    id: shell
    readonly property var words: (Quickshell.env("LATTE_APP_ARGS") || "").split("\n").filter(w => w !== "")
    property string view: ["day", "month"].includes(words[0]) ? words[0] : "week"     // day · week · month
    property date anchor: /^\d{4}-\d{2}-\d{2}$/.test(words[0] || "") ? shell.parse(words[0]) : new Date()
    property var events: []
    property var calendars: []
    property var load: ({})                    // day → hours of events, for the year's heat
    property var sky: []                       // latte-sky's days, today first
    property var picked: null                  // the event open on the right
    property var draft: null                   // the event being written: { …, isNew }
    property bool asking: false                // "Really take it out?"
    readonly property real hourH: 52

    // ── dates ─────────────────────────────────────────────────────────────────────────────────────────────────
    function pad(n) { return (n < 10 ? "0" : "") + n }
    function iso(d) { return d.getFullYear() + "-" + pad(d.getMonth() + 1) + "-" + pad(d.getDate()) }
    function parse(s) { const p = s.split("-"); return new Date(+p[0], +p[1] - 1, +p[2], 12) }
    function plus(d, n) { const x = new Date(d.getFullYear(), d.getMonth(), d.getDate(), 12); x.setDate(x.getDate() + n); return x }
    function monday(d) { return plus(d, -((d.getDay() + 6) % 7)) }
    function week(d) { const t = plus(d, 3 - (d.getDay() + 6) % 7); const y = new Date(t.getFullYear(), 0, 4, 12); return 1 + Math.round(((t - y) / 864e5 - 3 + (y.getDay() + 6) % 7) / 7) }
    function minutes(hm) { const p = (hm || "").split(":"); return p.length === 2 ? +p[0] * 60 + +p[1] : -1 }
    function hm(m) { return pad(Math.floor(m / 60) % 24) + ":" + pad(m % 60) }
    readonly property var monthNames: [QT_TR_NOOP("January"), QT_TR_NOOP("February"), QT_TR_NOOP("March"), QT_TR_NOOP("April"), QT_TR_NOOP("May"), QT_TR_NOOP("June"),
                                       QT_TR_NOOP("July"), QT_TR_NOOP("August"), QT_TR_NOOP("September"), QT_TR_NOOP("October"), QT_TR_NOOP("November"), QT_TR_NOOP("December")]
    readonly property var dayNames: [QT_TR_NOOP("Mo"), QT_TR_NOOP("Tu"), QT_TR_NOOP("We"), QT_TR_NOOP("Th"), QT_TR_NOOP("Fr"), QT_TR_NOOP("Sa"), QT_TR_NOOP("Su")]
    readonly property var days: { const first = view === "week" ? monday(anchor) : anchor; const out = []; for (let i = 0; i < (view === "week" ? 7 : 1); i++) out.push(plus(first, i)); return out }
    readonly property var range: view === "month" ? [new Date(anchor.getFullYear(), anchor.getMonth(), 1, 12), new Date(anchor.getFullYear(), anchor.getMonth() + 1, 0, 12)] : [days[0], days[days.length - 1]]
    readonly property string title: view === "month" ? I18n.tr(monthNames[anchor.getMonth()]) + " " + anchor.getFullYear()
                                   : view === "day" ? days[0].getDate() + ". " + (days[0].getMonth() + 1) + ". " + days[0].getFullYear()
                                   : days[0].getDate() + ". " + (days[0].getMonth() === days[6].getMonth() ? "" : (days[0].getMonth() + 1) + ". ") + "– " + days[6].getDate() + ". " + I18n.tr(monthNames[days[6].getMonth()]).toLowerCase()
    function step(n) { anchor = view === "month" ? new Date(anchor.getFullYear(), anchor.getMonth() + n, 1, 12) : plus(anchor, n * (view === "week" ? 7 : 1)) }

    // ── what is shown: the calendars the user did not hide ────────────────────────────────────────────────────
    FileView {
        id: hiddenFile
        path: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/latteos/calendar-hidden"
        printErrors: false
        property var list: []
        onLoaded: { try { list = JSON.parse(text()) } catch (e) { list = [] } }
        function flip(id) { list = list.includes(id) ? list.filter(x => x !== id) : list.concat([id]); setText(JSON.stringify(list)) }
    }
    function shownOn(key) { return events.filter(e => e.date === key && !hiddenFile.list.includes(e.kind === "holiday" ? "holidays" : e.source)) }
    function timed(key) { return shownOn(key).filter(e => e.time !== "") }
    function whole(key) { return shownOn(key).filter(e => e.time === "") }
    // events of one day side by side where they overlap: each gets a lane and the count of lanes beside it
    function lanes(list) {
        const sorted = list.slice().sort((a, b) => minutes(a.time) - minutes(b.time)), ends = [], out = []
        for (const e of sorted) {
            const s = minutes(e.time), f = Math.max(s + 15, e.end ? (minutes(e.end) > s ? minutes(e.end) : 1440) : s + 60)
            let k = ends.findIndex(x => x <= s); if (k < 0) { k = ends.length; ends.push(f) } else ends[k] = f
            out.push({ e: e, s: s, f: f, lane: k })
        }
        for (const o of out) o.of = Math.max(...out.filter(p => p.s < o.f && p.f > o.s).map(p => p.lane)) + 1
        return out
    }

    component Ask: Process {
        id: q
        property var data: null
        property string buf: ""
        signal done()
        function ask(args) { running = false; command = args; running = true }
        stdout: StdioCollector { onStreamFinished: q.buf = this.text }
        onExited: { try { q.data = JSON.parse(q.buf) } catch (e) { q.data = null } q.done() }
    }
    Ask { id: evq; onDone: { shell.events = data || []; if (shell.picked) shell.picked = shell.events.find(e => e.uid === shell.picked.uid && e.date === shell.picked.date) || null } }
    Ask { id: calq; onDone: shell.calendars = data || [] }
    Ask { id: yearq; onDone: { const l = {}; for (const e of data || []) if (e.kind === "event") l[e.date] = (l[e.date] || 0) + (e.time ? Math.max(0.5, (shell.minutes(e.end) - shell.minutes(e.time)) / 60) : 2); shell.load = l } }
    Ask { id: skyq; onDone: shell.sky = data && data.days ? data.days : [] }
    Ask { id: writer; onDone: shell.reload() }
    function reload() {
        evq.ask(["latte-cal", "events", "--from", iso(plus(range[0], -7)), "--to", iso(plus(range[1], 7))])
        yearq.ask(["latte-cal", "events", "--from", iso(plus(monday(new Date()), -84)), "--to", iso(plus(monday(new Date()), 98))])
    }
    onRangeChanged: evq.ask(["latte-cal", "events", "--from", iso(plus(range[0], -7)), "--to", iso(plus(range[1], 7))])
    Component.onCompleted: {
        calq.ask(["latte-cal", "calendars"]); skyq.ask(["latte-sky"]); reload()
        // latte-app calendar DAY SOURCE UID: that event open, as ClockGoo's calendar asks for it
        if (words.length >= 3) openAfter.restart()
    }
    Timer { id: openAfter; interval: 1500; onTriggered: { const e = shell.events.find(x => x.source === shell.words[1] && x.uid === shell.words[2]); if (e) shell.picked = e } }
    Timer { interval: 600000; repeat: true; running: true; onTriggered: shell.reload() }
    property date now: new Date()
    Timer { interval: 30000; repeat: true; running: true; onTriggered: shell.now = new Date() }

    function skyOf(d) { const i = Math.round((parse(iso(d)) - parse(iso(new Date()))) / 864e5); return i >= 0 && i < sky.length ? sky[i] : null }
    function skyGlyph(c) { return c <= 1 ? "sun" : c <= 3 ? "cloud" : c <= 48 ? "mist" : c >= 95 ? "cloud-storm" : (c >= 71 && c <= 77) || c === 85 || c === 86 ? "snowflake" : "cloud-rain" }
    readonly property var writable: calendars.filter(c => c.writable && c.enabled)
    readonly property var swatches: ["", "#6aa6ff", "#b79bff", "#ff9f6b", "#4cc38a", "#5fd0e0", "#f7c873", "#ff6b6b"]

    // ── writing: a new event, a changed one, one moved by the mouse ───────────────────────────────────────────
    function begin(day, from, to) {
        picked = null; asking = false
        draft = { isNew: true, title: "", day: iso(day), from: from < 0 ? "" : hm(from), to: from < 0 ? "" : hm(to), allday: from < 0, location: "", notes: "", color: "",
                  source: writable.length ? (writable.find(c => c.backend !== "local") || writable[0]).uid : "" }
    }
    function edit(e) { asking = false; draft = { isNew: false, title: e.title, day: e.start.slice(0, 10), from: e.time, to: e.end, allday: e.allday, location: e.location, notes: e.notes || "", color: e.own_color || "", source: e.source, uid: e.uid } }
    function span(d) {
        if (d.allday) return [d.day, iso(plus(parse(d.day), 1))]
        const a = minutes(d.from) < 0 ? 540 : minutes(d.from), b = minutes(d.to) > a ? minutes(d.to) : a + 60
        return [d.day + "T" + hm(a), b >= 1440 ? iso(plus(parse(d.day), 1)) + "T" + hm(b - 1440) : d.day + "T" + hm(b)]
    }
    function save() {
        const d = draft, s = span(d)
        if (d.title.trim() === "" || !/^\d{4}-\d{2}-\d{2}$/.test(d.day) || d.source === "") return
        if (d.isNew) writer.ask(["sh", "-c", 'u=$(latte-cal add "$1" "$2" "$3" "$4" "$5" | sed -n \'s/.*"uid": "\\([^"]*\\)".*/\\1/p\'); [ -n "$6$7$8" ] && [ -n "$u" ] && latte-cal update "$1" "$u" "$9"; true',
                                 "sh", d.source, d.title.trim(), s[0], s[1], d.location, d.notes, d.color, "x", JSON.stringify({ notes: d.notes, color: d.color })])
        else writer.ask(["latte-cal", "update", d.source, d.uid, JSON.stringify({ title: d.title.trim(), start: s[0], end: s[1], location: d.location, notes: d.notes, color: d.color })])
        draft = null; picked = null
    }
    function move(e, dayShift, minShift, longer) {
        if (!e.writable || e.kind !== "event" || e.time === "") return
        const s0 = minutes(e.time), f0 = e.end ? minutes(e.end) : s0 + 60
        const s = Math.max(0, Math.min(1425, s0 + (longer ? 0 : minShift))), f = Math.max(s + 15, (f0 > s0 ? f0 : s0 + 60) + minShift)
        const day = iso(plus(parse(e.start.slice(0, 10)), dayShift))
        writer.ask(["latte-cal", "update", e.source, e.uid, JSON.stringify({ start: day + "T" + hm(s), end: f >= 1440 ? iso(plus(parse(day), 1)) + "T" + hm(f - 1440) : day + "T" + hm(f) })])
    }

    AppWindow {
        id: win
        title: I18n.tr("Calendar")
        heading: shell.title
        implicitWidth: 1440; implicitHeight: 860
        arrows: true; canGoBack: true; canGoForward: true
        onBack: shell.step(-1)
        onForward: shell.step(1)
        sideWidth: 270
        tools: [
            Pill { implicitHeight: 32; text: I18n.tr("Today"); onPressed: shell.anchor = new Date() },
            Label { visible: shell.view !== "month"; text: I18n.tr("week {n}", { n: shell.week(shell.days[0]) }); color: Theme.dim; font.family: Theme.mono; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter },
            Rectangle { height: 38; radius: 14; color: Theme.ground; width: seg.implicitWidth + 8; anchors.verticalCenter: parent.verticalCenter
                Row { id: seg; x: 4; y: 4; spacing: 4
                    Repeater { model: [{ id: "day", name: QT_TR_NOOP("Day") }, { id: "week", name: QT_TR_NOOP("Week") }, { id: "month", name: QT_TR_NOOP("Month") }]
                        Rectangle { required property var modelData; height: 30; radius: 10; width: segText.implicitWidth + 28; color: shell.view === modelData.id ? Theme.raised : "transparent"
                            Label { id: segText; anchors.centerIn: parent; text: I18n.tr(parent.modelData.name); font.pixelSize: 13; color: shell.view === parent.modelData.id ? Theme.gold : Theme.dim; font.weight: shell.view === parent.modelData.id ? 600 : 400 }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: shell.view = parent.modelData.id } } } } }
        ]
        side: [
            Column { x: 18; y: 18; width: 234; spacing: 18
                Row { spacing: 10; height: 30
                    Glyph { name: "calendar"; font.pixelSize: 24; color: Theme.gold; anchors.verticalCenter: parent.verticalCenter }
                    Label { text: I18n.tr("Calendar"); font.pixelSize: 18; font.weight: 800; anchors.verticalCenter: parent.verticalCenter } }
                Pill { width: parent.width; implicitHeight: 40; strong: true; icon: "plus"; text: I18n.tr("New event"); onPressed: shell.begin(shell.days[0], 540, 600) }
                // the month in small: a press shows that day
                Column { width: parent.width; spacing: 4
                    Label { text: I18n.tr(shell.monthNames[shell.anchor.getMonth()]) + " " + shell.anchor.getFullYear(); font.weight: 700; font.pixelSize: 13 }
                    Grid { columns: 7; width: parent.width
                        Repeater { model: shell.dayNames
                            Label { required property string modelData; width: 234 / 7; height: 20; horizontalAlignment: Text.AlignHCenter; text: I18n.tr(modelData).charAt(0).toUpperCase(); color: Theme.faint; font.family: Theme.mono; font.pixelSize: 10 } }
                        Repeater { model: { const f = new Date(shell.anchor.getFullYear(), shell.anchor.getMonth(), 1, 12), lead = (f.getDay() + 6) % 7, n = new Date(f.getFullYear(), f.getMonth() + 1, 0).getDate(); const out = []; for (let i = 0; i < lead + n; i++) out.push(i < lead ? null : new Date(f.getFullYear(), f.getMonth(), i - lead + 1, 12)); return out }
                            Rectangle { required property var modelData; width: 234 / 7; height: 26; radius: 7
                                readonly property bool today: modelData !== null && shell.iso(modelData) === shell.iso(shell.now)
                                readonly property bool inside: modelData !== null && shell.days.some(d => shell.iso(d) === shell.iso(modelData))
                                color: today ? Theme.gold : (inside && shell.view !== "month" ? Theme.raised : "transparent")
                                Label { anchors.centerIn: parent; text: parent.modelData ? parent.modelData.getDate() : ""; font.family: Theme.mono; font.pixelSize: 11; color: parent.today ? Theme.inkOnGold : Theme.cream; font.weight: parent.today ? 800 : 400 }
                                MouseArea { anchors.fill: parent; enabled: parent.modelData !== null; cursorShape: Qt.PointingHandCursor; onClicked: shell.anchor = parent.modelData } } } } }
                // the calendars: a tick shows or hides one; holidays are LatteOS's own
                Column { width: parent.width; spacing: 8
                    Label { text: I18n.tr("MY CALENDARS"); color: Theme.faint; font.family: Theme.mono; font.pixelSize: 11; font.weight: 700 }
                    Repeater { model: shell.calendars.filter(c => c.enabled).concat([{ uid: "holidays", name: QT_TR_NOOP("Holidays"), account: "LatteOS", color: "#ff6b6b" }])
                        Item { required property var modelData; width: 234; height: 24
                            readonly property bool on: !hiddenFile.list.includes(modelData.uid)
                            Rectangle { width: 16; height: 16; radius: 5; anchors.verticalCenter: parent.verticalCenter; color: parent.on ? parent.modelData.color : "transparent"; border.width: 2; border.color: parent.modelData.color
                                Glyph { anchors.centerIn: parent; visible: parent.parent.on; name: "check"; font.pixelSize: 12; color: "#17110d" } }
                            Label { x: 26; width: 150; text: I18n.tr(parent.modelData.name); font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
                            Label { anchors.right: parent.right; text: parent.modelData.account || ""; width: 60; horizontalAlignment: Text.AlignRight; color: Theme.faint; font.family: Theme.mono; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: hiddenFile.flip(parent.modelData.uid) } } }
                    Text { text: I18n.tr("Linked calendars…"); color: Theme.gold; font.family: Theme.font; font.pixelSize: 13; font.underline: true
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Quickshell.execDetached(["latte-cal", "accounts"]) } } }
                // the year's load, in the standard heat: six months around this week
                Column { width: parent.width; spacing: 6
                    Label { text: I18n.tr("LOAD OF THE YEAR"); color: Theme.faint; font.family: Theme.mono; font.pixelSize: 11; font.weight: 700 }
                    Grid { columns: 26; columnSpacing: 2; rowSpacing: 2; flow: Grid.TopToBottom; rows: 7
                        Repeater { model: 182
                            Rectangle { required property int index; width: (234 - 50) / 26; height: width; radius: 2
                                readonly property string key: shell.iso(shell.plus(shell.monday(shell.now), index - 84))
                                readonly property real hours: shell.load[key] || 0
                                color: hours > 0 ? Theme.heat(Math.min(1, hours / 8)) : Theme.unlit
                                border.width: key === shell.iso(shell.now) ? 1 : 0; border.color: Theme.cream
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { shell.anchor = shell.parse(parent.key); shell.view = "day" } } } } }
                    Label { width: parent.width; wrapMode: Text.WordWrap; text: I18n.tr("The colours of the Monitor: green free, gold full, red too full."); color: Theme.faint; font.pixelSize: 11 } } }
        ]

        // ── a day or a week: the whole days on top, the hours below ───────────────────────────────────────────
        Item {
            id: grid
            visible: shell.view !== "month"
            anchors.fill: parent; anchors.rightMargin: side.width
            readonly property real colW: (width - 64) / shell.days.length
            // the heads: the day, its number (gold today) and its weather
            Row { id: heads; x: 64; y: 10
                Repeater { model: shell.days
                    Column { required property var modelData; width: grid.colW; spacing: 2
                        readonly property bool today: shell.iso(modelData) === shell.iso(shell.now)
                        readonly property var w: shell.skyOf(modelData)
                        Label { anchors.horizontalCenter: parent.horizontalCenter; text: I18n.tr(shell.dayNames[(parent.modelData.getDay() + 6) % 7]).toUpperCase(); color: Theme.faint; font.family: Theme.mono; font.pixelSize: 11; font.weight: 700 }
                        Rectangle { anchors.horizontalCenter: parent.horizontalCenter; height: 30; radius: 15; width: Math.max(30, num.implicitWidth + 20); color: parent.today ? Theme.gold : "transparent"
                            Label { id: num; anchors.centerIn: parent; text: parent.parent.modelData.getDate(); font.pixelSize: 20; font.weight: 800; color: parent.parent.today ? Theme.inkOnGold : ((parent.parent.modelData.getDay() + 6) % 7 > 4 ? Theme.dim : Theme.cream) } }
                        Row { anchors.horizontalCenter: parent.horizontalCenter; spacing: 4; height: 16; visible: parent.w !== null
                            Glyph { name: parent.parent.w ? shell.skyGlyph(parent.parent.w.code) : "sun"; font.pixelSize: 12; color: Theme.dim; anchors.verticalCenter: parent.verticalCenter }
                            Label { text: parent.parent.w ? Math.round(parent.parent.w.max) + "°" : ""; color: Theme.dim; font.family: Theme.mono; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter } } } } }
            // whole days and holidays
            Row { id: wholes; x: 64; y: heads.y + heads.height + 8
                Repeater { model: shell.days
                    Column { id: wd; required property var modelData; width: grid.colW; spacing: 3
                        Repeater { model: shell.whole(shell.iso(wd.modelData))
                            Rectangle { required property var modelData; width: grid.colW - 6; x: 3; height: 22; radius: 6; color: Qt.alpha(modelData.color, 0.22); border.width: shell.picked && shell.picked.uid === modelData.uid ? 1 : 0; border.color: modelData.color
                                Label { x: 8; width: parent.width - 12; anchors.verticalCenter: parent.verticalCenter; text: parent.modelData.title; font.pixelSize: 12; font.weight: 600 }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { shell.draft = null; shell.asking = false; shell.picked = parent.modelData } } } } } } }
            Rectangle { y: wholes.y + wholes.height + 8; width: parent.width; height: 1; color: Theme.line }
            Flickable {
                id: hours
                y: wholes.y + wholes.height + 9; width: parent.width; height: parent.height - y
                contentHeight: 24 * shell.hourH + 8; clip: true; boundsBehavior: Flickable.StopAtBounds
                Component.onCompleted: contentY = 7 * shell.hourH
                Repeater { model: 24
                    Item { required property int index; y: 4 + index * shell.hourH; width: hours.width; height: shell.hourH
                        Rectangle { x: 56; width: parent.width - 56; height: 1; color: Theme.line; opacity: 0.6 }
                        Label { x: 12; y: -7; text: shell.pad(parent.index) + ":00"; color: Theme.faint; font.family: Theme.mono; font.pixelSize: 10; visible: parent.index > 0 } } }
                Row { x: 64; y: 4
                    Repeater { model: shell.days
                        Item { id: col; required property var modelData; width: grid.colW; height: 24 * shell.hourH
                            readonly property string key: shell.iso(modelData)
                            Rectangle { width: 1; height: parent.height; color: Theme.line; opacity: 0.5 }
                            // an empty place: a press and a drag make a new event, from where it began to where it ends
                            MouseArea {
                                id: maker; anchors.fill: parent; cursorShape: Qt.CrossCursor
                                property real from: -1
                                property real to: -1
                                function at(y) { return Math.max(0, Math.min(1440, Math.round(y / shell.hourH * 4) * 15)) }
                                onPressed: m => { from = at(m.y); to = from + 30 }
                                onPositionChanged: m => { if (pressed) to = Math.max(from + 15, at(m.y)) }
                                onReleased: { shell.begin(col.modelData, from, Math.max(to, from + 30)); from = -1 } }
                            Rectangle { visible: maker.from >= 0; x: 3; width: parent.width - 6; y: maker.from / 60 * shell.hourH; height: (maker.to - maker.from) / 60 * shell.hourH; radius: 10; color: "transparent"; border.width: 1.5; border.color: Theme.gold
                                Label { x: 8; y: 4; text: I18n.tr("New event") + "  " + shell.hm(maker.from) + " – " + shell.hm(maker.to); color: Theme.gold; font.pixelSize: 11 } }
                            // the events, side by side where they overlap; each can be dragged, its lower edge makes it longer
                            Repeater { model: shell.lanes(shell.timed(col.key))
                                Rectangle {
                                    id: blk; required property var modelData
                                    readonly property var e: modelData.e
                                    property real dy: 0
                                    property real dx: 0
                                    property real grow: 0
                                    x: 3 + modelData.lane * (col.width - 6) / modelData.of + dx; width: (col.width - 6) / modelData.of - 2
                                    y: modelData.s / 60 * shell.hourH + 1 + dy; height: Math.max(18, (modelData.f - modelData.s) / 60 * shell.hourH - 2 + grow)
                                    radius: 9; color: Qt.alpha(e.color, shell.picked && shell.picked.uid === e.uid ? 0.38 : 0.22); clip: true; z: mover.pressed || stretcher.pressed ? 5 : 1
                                    Rectangle { width: 3; height: parent.height; color: blk.e.color }
                                    Column { x: 9; y: 4; width: parent.width - 12; spacing: 1
                                        Label { width: parent.width; text: blk.e.title; font.pixelSize: 12; font.weight: 700 }
                                        Label { width: parent.width; text: blk.e.time + (blk.e.end ? " – " + blk.e.end : "") + (blk.e.location ? " · " + blk.e.location : ""); color: Theme.dim; font.family: Theme.mono; font.pixelSize: 10 } }
                                    MouseArea { id: mover; anchors.fill: parent; anchors.bottomMargin: 6; cursorShape: blk.e.writable ? Qt.OpenHandCursor : Qt.PointingHandCursor
                                        property point at
                                        onPressed: m => at = mapToItem(col.parent, m.x, m.y)
                                        onPositionChanged: m => { if (!pressed || !blk.e.writable) return; const p = mapToItem(col.parent, m.x, m.y); blk.dy = Math.round((p.y - at.y) / shell.hourH * 4) * shell.hourH / 4; blk.dx = Math.round((p.x - at.x) / grid.colW) * grid.colW }
                                        onReleased: { const days = Math.round(blk.dx / grid.colW), mins = Math.round(blk.dy / shell.hourH * 60); blk.dx = 0; blk.dy = 0
                                                      if (days !== 0 || mins !== 0) shell.move(blk.e, days, mins, false); else { shell.draft = null; shell.asking = false; shell.picked = blk.e } } }
                                    MouseArea { id: stretcher; visible: blk.e.writable; anchors.bottom: parent.bottom; width: parent.width; height: 6; cursorShape: Qt.SizeVerCursor
                                        property real at: 0
                                        onPressed: m => at = mapToItem(col, 0, m.y).y
                                        onPositionChanged: m => { if (pressed) blk.grow = Math.round((mapToItem(col, 0, m.y).y - at) / shell.hourH * 4) * shell.hourH / 4 }
                                        onReleased: { const mins = Math.round(blk.grow / shell.hourH * 60); blk.grow = 0; if (mins !== 0) shell.move(blk.e, 0, mins, true) } } } }
                            // now: a red line across today
                            Rectangle { visible: col.key === shell.iso(shell.now); y: (shell.now.getHours() * 60 + shell.now.getMinutes()) / 60 * shell.hourH; width: parent.width; height: 2; color: "#ff6b6b"; z: 6
                                Rectangle { x: -6; y: -5; width: 12; height: 12; radius: 6; color: "#ff6b6b" } } } } } }
        }

        // ── a month: its own days only, as ClockGoo's card; a press on a day shows it ─────────────────────────
        Item {
            visible: shell.view === "month"
            anchors.fill: parent; anchors.margins: 18; anchors.rightMargin: side.width + 18
            readonly property var first: new Date(shell.anchor.getFullYear(), shell.anchor.getMonth(), 1, 12)
            readonly property int lead: (first.getDay() + 6) % 7
            readonly property int length: new Date(first.getFullYear(), first.getMonth() + 1, 0).getDate()
            readonly property int rows: Math.ceil((lead + length) / 7)
            Row { id: mhead
                Repeater { model: shell.dayNames
                    Label { required property string modelData; width: (parent.parent.width) / 7; text: I18n.tr(modelData).toUpperCase(); color: Theme.faint; font.family: Theme.mono; font.pixelSize: 11; font.weight: 700 } } }
            Grid { id: mgrid; y: mhead.height + 8; columns: 7; spacing: 6
                Repeater { model: parent.parent.rows * 7
                    Rectangle {
                        required property int index
                        readonly property int n: index - mgrid.parent.lead + 1
                        readonly property bool mine: n >= 1 && n <= mgrid.parent.length
                        readonly property var day: new Date(mgrid.parent.first.getFullYear(), mgrid.parent.first.getMonth(), n, 12)
                        readonly property bool today: mine && shell.iso(day) === shell.iso(shell.now)
                        width: (mgrid.parent.width - 36) / 7; height: (mgrid.parent.height - mgrid.y - 6 * (mgrid.parent.rows - 1)) / mgrid.parent.rows
                        radius: 12; color: mine ? Theme.card : "transparent"; border.width: today ? 2 : (mine ? 1 : 0); border.color: today ? Theme.gold : Theme.line
                        Label { visible: parent.mine; x: 10; y: 8; text: parent.n; font.family: Theme.mono; font.weight: 700; color: parent.today ? Theme.gold : Theme.cream }
                        Column { visible: parent.mine; x: 6; y: 30; width: parent.width - 12; spacing: 3
                            Repeater { model: parent.parent.mine ? shell.shownOn(shell.iso(parent.parent.day)).slice(0, Math.max(1, Math.floor((parent.parent.height - 36) / 21))) : []
                                Rectangle { required property var modelData; width: parent.width; height: 18; radius: 5; color: Qt.alpha(modelData.color, 0.22)
                                    Label { x: 6; width: parent.width - 8; anchors.verticalCenter: parent.verticalCenter; text: (parent.modelData.time ? parent.modelData.time + " " : "") + parent.modelData.title; font.pixelSize: 11 }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { shell.draft = null; shell.picked = parent.modelData } } } } }
                        MouseArea { anchors.fill: parent; z: -1; enabled: parent.mine; cursorShape: Qt.PointingHandCursor; onClicked: { shell.anchor = parent.day; shell.view = "day" } } } } }
        }

        // ── on the right: the event open, or being written ────────────────────────────────────────────────────
        Rectangle {
            id: side
            anchors.right: parent.right; width: shell.picked || shell.draft ? 340 : 0; height: parent.height; color: Theme.surface; clip: true
            Behavior on width { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
            Rectangle { width: 1; height: parent.height; color: Theme.line }
            // the event, as it is
            Column {
                visible: shell.picked !== null && shell.draft === null
                x: 22; y: 22; width: 296; spacing: 14
                readonly property var e: shell.picked || ({})
                Row { spacing: 8
                    Rectangle { width: 10; height: 10; radius: 5; color: parent.parent.e.color || Theme.gold; anchors.verticalCenter: parent.verticalCenter }
                    Label { text: parent.parent.e.kind === "holiday" ? I18n.tr("Holiday") : parent.parent.e.calendar || ""; color: Theme.dim; font.pixelSize: 12 } }
                Label { width: parent.width; wrapMode: Text.WordWrap; text: parent.e.title || ""; font.pixelSize: 22; font.weight: 800 }
                Label { text: parent.e.date ? (shell.parse(parent.e.date).getDate() + ". " + (shell.parse(parent.e.date).getMonth() + 1) + ". · " + (parent.e.time ? parent.e.time + (parent.e.end ? " – " + parent.e.end : "") : I18n.tr("all day"))) : ""; font.family: Theme.mono; font.pixelSize: 13 }
                Row { visible: (parent.e.location || "") !== ""; spacing: 8
                    Glyph { name: "map-pin"; color: Theme.dim; font.pixelSize: 15 }
                    Label { text: parent.parent.e.location || ""; color: Theme.dim; width: 270; wrapMode: Text.WordWrap } }
                Label { visible: (parent.e.notes || "") !== ""; width: parent.width; wrapMode: Text.WordWrap; text: parent.e.notes || ""; color: Theme.dim; font.pixelSize: 13; maximumLineCount: 8; elide: Text.ElideRight }
                Pill { visible: (parent.e.link || "") !== ""; strong: true; icon: "video"; text: I18n.tr("Join"); onPressed: Qt.openUrlExternally(shell.picked.link) }
                Label { visible: shell.picked !== null && shell.picked.kind === "event" && !shell.picked.writable; width: parent.width; wrapMode: Text.WordWrap; color: Theme.faint; font.pixelSize: 12
                        text: I18n.tr("This calendar can only be read: change it where it comes from.") }
                Row { spacing: 8; visible: shell.picked !== null && shell.picked.kind === "event" && shell.picked.writable
                    Pill { icon: "pencil"; text: I18n.tr("Edit"); onPressed: shell.edit(shell.picked) }
                    Pill { icon: "trash"; danger: true; text: shell.asking ? I18n.tr("Really take it out?") : I18n.tr("Delete")
                           onPressed: { if (shell.asking) { writer.ask(["latte-cal", "remove", shell.picked.source, shell.picked.uid]); shell.picked = null; shell.asking = false } else shell.asking = true } } }
                Pill { icon: "x"; text: I18n.tr("Close"); onPressed: { shell.picked = null; shell.asking = false } }
            }
            // the event being written: what, when, where, a note, its colour, and for a new one its calendar
            Flickable {
                visible: shell.draft !== null
                anchors.fill: parent; anchors.leftMargin: 1; contentHeight: form.height + 40; clip: true; boundsBehavior: Flickable.StopAtBounds
                Column {
                    id: form; x: 21; y: 22; width: 296; spacing: 12
                    readonly property var d: shell.draft || ({})
                    function set(k, v) { const n = Object.assign({}, shell.draft); n[k] = v; shell.draft = n }
                    Label { text: form.d.isNew ? I18n.tr("New event") : I18n.tr("Edit the event"); font.pixelSize: 18; font.weight: 800 }
                    Field { width: parent.width; icon: "pencil"; hint: I18n.tr("What"); text: form.d.title || ""; onTextChanged: if (shell.draft && text !== shell.draft.title) form.set("title", text); onAccepted: shell.save() }
                    Field { width: parent.width; icon: "calendar"; hint: "2026-10-23"; text: form.d.day || ""; onTextChanged: if (shell.draft && text !== shell.draft.day) form.set("day", text) }
                    Row { spacing: 8
                        Pill { implicitHeight: 32; text: I18n.tr("All day"); icon: form.d.allday ? "check" : ""; strong: form.d.allday === true; onPressed: form.set("allday", !form.d.allday) } }
                    Row { spacing: 8; visible: !form.d.allday
                        Field { width: 144; icon: "clock"; hint: "09:00"; text: form.d.from || ""; onTextChanged: if (shell.draft && text !== shell.draft.from) form.set("from", text) }
                        Field { width: 144; icon: "clock"; hint: "10:00"; text: form.d.to || ""; onTextChanged: if (shell.draft && text !== shell.draft.to) form.set("to", text) } }
                    Field { width: parent.width; icon: "map-pin"; hint: I18n.tr("Where"); text: form.d.location || ""; onTextChanged: if (shell.draft && text !== shell.draft.location) form.set("location", text) }
                    Rectangle { width: parent.width; height: 96; radius: 12; color: Theme.card; border.width: 1; border.color: notes.activeFocus ? Theme.gold : Theme.line
                        TextEdit { id: notes; x: 12; y: 10; width: parent.width - 24; height: parent.height - 20; wrapMode: Text.Wrap; color: Theme.cream; font.family: Theme.font; font.pixelSize: 13; selectByMouse: true; clip: true
                                   text: form.d.notes || ""; onTextChanged: if (shell.draft && text !== shell.draft.notes) form.set("notes", text) }
                        Label { x: 12; y: 10; visible: notes.text === ""; text: I18n.tr("A note"); color: Theme.faint } }
                    Label { text: I18n.tr("COLOUR"); color: Theme.faint; font.family: Theme.mono; font.pixelSize: 11; font.weight: 700 }
                    Flow { width: parent.width; spacing: 8
                        Repeater { model: shell.swatches
                            Rectangle { required property string modelData; width: 30; height: 30; radius: 15
                                readonly property color shown: modelData !== "" ? modelData : ((shell.calendars.find(c => c.uid === form.d.source) || {}).color || Theme.gold)
                                color: shown; border.width: (form.d.color || "") === modelData ? 3 : 0; border.color: Theme.cream
                                Glyph { anchors.centerIn: parent; visible: parent.modelData === ""; name: "calendar"; font.pixelSize: 14; color: "#17110d" }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: form.set("color", parent.modelData) } } } }
                    Label { text: I18n.tr("The first is the colour of its calendar."); color: Theme.faint; font.pixelSize: 11 }
                    Column { visible: form.d.isNew === true; width: parent.width; spacing: 6
                        Label { text: I18n.tr("CALENDAR"); color: Theme.faint; font.family: Theme.mono; font.pixelSize: 11; font.weight: 700 }
                        Flow { width: parent.width; spacing: 6
                            Repeater { model: shell.writable
                                Pill { required property var modelData; implicitHeight: 30; text: (modelData.account && modelData.backend !== "local" ? modelData.account + " · " : "") + modelData.name
                                       strong: form.d.source === modelData.uid; onPressed: form.set("source", modelData.uid) } } }
                        Label { visible: shell.writable.length === 0; width: parent.width; wrapMode: Text.WordWrap; color: Theme.red; font.pixelSize: 12; text: I18n.tr("no calendar to write to") } }
                    Row { spacing: 8
                        Pill { icon: "check"; strong: true; text: I18n.tr("Save"); onPressed: shell.save() }
                        Pill { icon: "x"; text: I18n.tr("Cancel"); onPressed: shell.draft = null } }
                }
            }
        }
    }
}
