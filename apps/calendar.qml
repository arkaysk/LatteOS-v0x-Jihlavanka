//@ pragma AppId latteos-calendar
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
    property string view: ["day", "month", "work"].includes(words[0]) ? words[0] : "week"     // day · week · month · work (the working days)
    property date anchor: /^\d{4}-\d{2}-\d{2}$/.test(words[0] || "") ? shell.parse(words[0]) : new Date()
    property var events: []
    property var calendars: []
    property var cfg: ({ week_start: 0, namedays: [], workdays: [0, 1, 2, 3, 4], hours: 8 })      // latte-cal settings (the settings window writes them)
    readonly property int ws: cfg.week_start || 0                                                // the week begins on: 0 Monday, 6 Sunday, 5 Saturday
    property var load: ({})                    // day → hours of events, for the year's heat
    property var sky: []                       // latte-sky's days, today first
    property var picked: null                  // the event open on the right
    property var draft: null                   // the event being written: { …, isNew }
    property var scopeAsk: null                // of a repeating event: which of them? { options, run }
    property bool undoable: false              // an event was just taken out: "Undo" for a while
    property bool asking: false                // "Really take it out?"
    readonly property real hourH: 52

    // ── dates ─────────────────────────────────────────────────────────────────────────────────────────────────
    function pad(n) { return (n < 10 ? "0" : "") + n }
    function iso(d) { return d.getFullYear() + "-" + pad(d.getMonth() + 1) + "-" + pad(d.getDate()) }
    function parse(s) { const p = s.split("-"); return new Date(+p[0], +p[1] - 1, +p[2], 12) }
    function plus(d, n) { const x = new Date(d.getFullYear(), d.getMonth(), d.getDate(), 12); x.setDate(x.getDate() + n); return x }
    function monday(d) { return plus(d, -(((d.getDay() + 6) % 7 - ws + 7) % 7)) }          // the first day of the week, as the settings say
    function week(d) { const t = plus(d, 3 - (d.getDay() + 6) % 7); const y = new Date(t.getFullYear(), 0, 4, 12); return 1 + Math.round(((t - y) / 864e5 - 3 + (y.getDay() + 6) % 7) / 7) }
    function minutes(hm) { const p = (hm || "").split(":"); return p.length === 2 ? +p[0] * 60 + +p[1] : -1 }
    function hm(m) { return pad(Math.floor(m / 60) % 24) + ":" + pad(m % 60) }
    readonly property var monthNames: [QT_TR_NOOP("January"), QT_TR_NOOP("February"), QT_TR_NOOP("March"), QT_TR_NOOP("April"), QT_TR_NOOP("May"), QT_TR_NOOP("June"),
                                       QT_TR_NOOP("July"), QT_TR_NOOP("August"), QT_TR_NOOP("September"), QT_TR_NOOP("October"), QT_TR_NOOP("November"), QT_TR_NOOP("December")]
    readonly property var weekNames: dayNames.slice(ws).concat(dayNames.slice(0, ws))          // the names, from the day the week begins on
    readonly property var dayNames: [QT_TR_NOOP("Mo"), QT_TR_NOOP("Tu"), QT_TR_NOOP("We"), QT_TR_NOOP("Th"), QT_TR_NOOP("Fr"), QT_TR_NOOP("Sa"), QT_TR_NOOP("Su")]
    readonly property var days: { const first = view === "week" ? monday(anchor) : anchor; const out = []; for (let i = 0; i < (view === "week" ? 7 : 1); i++) out.push(plus(first, i)); return out }
    readonly property var range: view === "month" ? [new Date(anchor.getFullYear(), anchor.getMonth(), 1, 12), new Date(anchor.getFullYear(), anchor.getMonth() + 1, 0, 12)] : [days[0], days[days.length - 1]]
    readonly property string title: view === "work" ? I18n.tr("Work calendar") + " " + anchor.getFullYear()
                                   : view === "month" ? I18n.tr(monthNames[anchor.getMonth()]) + " " + anchor.getFullYear()
                                   : view === "day" ? days[0].getDate() + ". " + (days[0].getMonth() + 1) + ". " + days[0].getFullYear()
                                   : days[0].getDate() + ". " + (days[0].getMonth() === days[6].getMonth() ? "" : (days[0].getMonth() + 1) + ". ") + "– " + days[6].getDate() + ". " + I18n.tr(monthNames[days[6].getMonth()]).toLowerCase()
    function step(n) { anchor = view === "work" ? new Date(anchor.getFullYear() + n, 0, 1, 12) : view === "month" ? new Date(anchor.getFullYear(), anchor.getMonth() + n, 1, 12) : plus(anchor, n * (view === "week" ? 7 : 1)) }

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

    function at(item) { return item.mapToItem(overlay, 0, item.height + 4) }      // under a field, in the window the pickers lie over
    // a field that is pressed, not typed into: it opens the calendar or the clock of the day or the time it shows
    component PickField: Rectangle {
        id: pf
        property string icon: "calendar"
        property string text: ""
        property string hint: ""
        signal opened(var item)
        implicitWidth: 144; height: 40; radius: 12; color: Theme.card; border.width: 1; border.color: pfHit.containsMouse ? Theme.gold : Theme.line
        Glyph { x: 12; name: pf.icon; font.pixelSize: 16; color: Theme.dim; anchors.verticalCenter: parent.verticalCenter }
        Label { x: 38; width: parent.width - 46; elide: Text.ElideRight; anchors.verticalCenter: parent.verticalCenter; text: pf.text !== "" ? pf.text : pf.hint; color: pf.text !== "" ? Theme.cream : Theme.faint; font.pixelSize: 14 }
        MouseArea { id: pfHit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: pf.opened(pf) }
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
    // ── the work calendar: the working days of the year by month, and two small calculators (latte-cal workdays) ──
    property var workData: []
    property string rangeFrom: iso(new Date(new Date().getFullYear(), new Date().getMonth(), 1, 12))
    property string rangeTo: iso(new Date(new Date().getFullYear(), new Date().getMonth() + 1, 0, 12))
    property var rangeData: null
    property string addFrom: iso(new Date())
    property int addN: 10
    property string addResult: ""
    function loadWork() { if (view === "work") workq.ask(["latte-cal", "workdays-year", "" + anchor.getFullYear()]) }
    function calcRange() { if (rangeFrom <= rangeTo) rangeq.ask(["latte-cal", "workdays", rangeFrom, rangeTo]); else rangeData = null }
    function calcAdd() { addq.ask(["latte-cal", "workdays-add", addFrom, "" + addN]) }
    Ask { id: workq; onDone: shell.workData = data || [] }
    Ask { id: rangeq; onDone: shell.rangeData = data }
    Ask { id: addq; onDone: shell.addResult = data && data.date ? data.date : "" }
    onViewChanged: { loadWork(); if (view === "work") { calcRange(); calcAdd() } }
    onAnchorChanged: loadWork()
    onRangeFromChanged: calcRange()
    onRangeToChanged: calcRange()
    onAddFromChanged: calcAdd()
    onAddNChanged: calcAdd()
    function dayText(day) { return /^\d{4}-\d{2}-\d{2}$/.test(day || "") ? parse(day).getDate() + ". " + (parse(day).getMonth() + 1) + ". " + parse(day).getFullYear() : "" }
    Ask { id: calq; onDone: shell.calendars = data || [] }
    // the settings window writes them; what changed is read in a few seconds, and the events with it (name days)
    Ask { id: cfgq; onDone: if (data && data.week_start !== undefined && JSON.stringify(data) !== JSON.stringify(shell.cfg)) { shell.cfg = data; shell.reload(); shell.loadWork(); if (shell.view === "work") { shell.calcRange(); shell.calcAdd() } } }
    Timer { interval: 6000; repeat: true; running: true; onTriggered: cfgq.ask(["latte-cal", "settings"]) }
    Ask { id: yearq; onDone: { const l = {}; for (const e of data || []) if (e.kind === "event") l[e.date] = (l[e.date] || 0) + (e.time ? Math.max(0.5, (shell.minutes(e.end) - shell.minutes(e.time)) / 60) : 2); shell.load = l } }
    Ask { id: skyq; onDone: shell.sky = data && data.days ? data.days : [] }
    Ask { id: writer; onDone: shell.reload() }
    function reload() {
        evq.ask(["latte-cal", "events", "--from", iso(plus(range[0], -7)), "--to", iso(plus(range[1], 7))])
        yearq.ask(["latte-cal", "events", "--from", iso(plus(monday(new Date()), -84)), "--to", iso(plus(monday(new Date()), 98))])
    }
    onRangeChanged: evq.ask(["latte-cal", "events", "--from", iso(plus(range[0], -7)), "--to", iso(plus(range[1], 7))])
    Component.onCompleted: {
        calq.ask(["latte-cal", "calendars"]); cfgq.ask(["latte-cal", "settings"]); skyq.ask(["latte-sky"]); reload()
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

    // ── repeating: an RRULE as the form holds it, and back ─────────────────────────────────────────────────────────
    readonly property var rcodes: ["MO", "TU", "WE", "TH", "FR", "SA", "SU"]
    function noRepeat() { return { freq: "", interval: 1, days: [], monthly: "day", end: "never", until: "", count: 10, dirty: false } }
    function parseRule(r) {
        const o = noRepeat(); if (!r) return o
        const kv = {}; r.split(";").forEach(x => { const i = x.indexOf("="); if (i > 0) kv[x.slice(0, i)] = x.slice(i + 1) })
        o.freq = ({ DAILY: "d", WEEKLY: "w", MONTHLY: "m", YEARLY: "y" })[kv.FREQ] || ""
        o.interval = +kv.INTERVAL || 1
        if (kv.BYDAY) { o.days = kv.BYDAY.split(",").map(x => x.replace(/^[-+\d]+/, "")); if (/\d/.test(kv.BYDAY) && o.freq === "m") o.monthly = "nth" }
        if (kv.COUNT) { o.end = "count"; o.count = +kv.COUNT }
        else if (kv.UNTIL) {
            o.end = "date"
            const u = kv.UNTIL, d = u.endsWith("Z") ? new Date(Date.UTC(+u.slice(0, 4), +u.slice(4, 6) - 1, +u.slice(6, 8), +u.slice(9, 11), +u.slice(11, 13))) : new Date(+u.slice(0, 4), +u.slice(4, 6) - 1, +u.slice(6, 8))
            o.until = iso(d)
        }
        return o
    }
    function buildRule(o, day) {
        if (!o.freq) return ""
        const d = parse(day), code = rcodes[(d.getDay() + 6) % 7], nth = Math.ceil(d.getDate() / 7)
        let r = "FREQ=" + ({ d: "DAILY", w: "WEEKLY", m: "MONTHLY", y: "YEARLY" })[o.freq]
        if (o.interval > 1) r += ";INTERVAL=" + o.interval
        if (o.freq === "w") r += ";BYDAY=" + (o.days.length ? o.days : [code]).join(",")
        if (o.freq === "m") r += o.monthly === "nth" ? ";BYDAY=" + (nth > 4 ? "-1" : nth) + code : ";BYMONTHDAY=" + d.getDate()
        if (o.end === "count") r += ";COUNT=" + Math.max(1, o.count)
        else if (o.end === "date" && /^\d{4}-\d{2}-\d{2}$/.test(o.until)) r += ";UNTIL=" + o.until
        return r
    }
    function ruleText(r) {          // "Weekly", "Every 2 weeks" … for the open event
        const o = parseRule(r), names = { d: QT_TR_NOOP("Daily"), w: QT_TR_NOOP("Weekly"), m: QT_TR_NOOP("Monthly"), y: QT_TR_NOOP("Yearly") }
        const units = { d: QT_TR_NOOP("days"), w: QT_TR_NOOP("weeks"), m: QT_TR_NOOP("months"), y: QT_TR_NOOP("years") }
        return o.freq === "" ? "" : (o.interval > 1 ? I18n.tr("Every {n} {unit}", { n: o.interval, unit: I18n.tr(units[o.freq]) }) : I18n.tr(names[o.freq]))
            + (o.end === "count" ? " · " + I18n.tr("{n} times", { n: o.count }) : o.end === "date" ? " · " + I18n.tr("until {day}", { day: o.until }) : "")
    }
    // ── reminders: minutes before the start, as Google offers them ─────────────────────────────────────────────
    readonly property var alarmSteps: [[0, QT_TR_NOOP("At the start")], [5, QT_TR_NOOP("5 minutes before")], [10, QT_TR_NOOP("10 minutes before")], [15, QT_TR_NOOP("15 minutes before")],
        [30, QT_TR_NOOP("30 minutes before")], [60, QT_TR_NOOP("1 hour before")], [120, QT_TR_NOOP("2 hours before")], [1440, QT_TR_NOOP("1 day before")],
        [2880, QT_TR_NOOP("2 days before")], [10080, QT_TR_NOOP("1 week before")]]
    function alarmText(m) { const k = alarmSteps.find(x => x[0] === m); return k ? I18n.tr(k[1]) : I18n.tr("{n} minutes before", { n: m }) }
    function askScope(options, run) { scopeAsk = { options: options, run: run } }

    // ── writing: a new event, a changed one, one moved by the mouse ───────────────────────────────────────────
    function begin(day, from, to) {
        picked = null; asking = false
        draft = { isNew: true, alarms: from < 0 ? [] : [10], alarmsDirty: false, rep: noRepeat(), recurring: false, rid: "", orig: "", title: "", day: iso(day), endDay: iso(day), free: false, private: false, url: "", origin: "", from: from < 0 ? "" : hm(from), to: from < 0 ? "" : hm(to), allday: from < 0, location: "", notes: "", color: "",
                  source: writable.length ? (writable.find(c => c.backend !== "local") || writable[0]).uid : "" }
    }
    function edit(e) { asking = false; draft = { isNew: false, alarms: e.alarms || [], alarmsDirty: false, rep: parseRule(e.repeat), recurring: !!e.repeat, rid: e.rid || "", orig: e.start, title: e.title, day: e.start.slice(0, 10), endDay: e.allday ? iso(plus(parse(e.finish), -1)) : e.finish.slice(0, 10), free: e.free === true, private: e.private === true, url: e.url || "", origin: e.source, from: e.time, to: e.end, allday: e.allday, location: e.location, notes: e.notes || "", color: e.own_color || "", source: e.source, uid: e.uid } }
    function label(e) { return (e.kind === "task" ? (e.done ? "☑ " : "☐ ") : "") + e.title }          // a task of a list, with its box
    function span(d) {
        const last = /^\d{4}-\d{2}-\d{2}$/.test(d.endDay || "") && d.endDay > d.day ? d.endDay : d.day      // several days: the last one
        if (d.allday) return [d.day, iso(plus(parse(last), 1))]
        const a = minutes(d.from) < 0 ? 540 : minutes(d.from), b = minutes(d.to) > a || last !== d.day ? minutes(d.to) : a + 60
        const f = b < 0 ? a + 60 : b
        return [d.day + "T" + hm(a), f >= 1440 ? iso(plus(parse(last), 1)) + "T" + hm(f - 1440) : last + "T" + hm(f)]
    }
    function save() {
        const d = draft
        if (d.title.trim() === "" || !/^\d{4}-\d{2}-\d{2}$/.test(d.day) || d.source === "") return
        // of a repeating event it is asked which of them (a new rule cannot be given to one occurrence alone)
        if (!d.isNew && d.recurring) askScope(d.rep.dirty ? ["future", "all"] : ["this", "future", "all"], sc => commit(sc))
        else commit("all")
    }
    function commit(scope) {
        const d = draft, s = span(d)
        const extra = { notes: d.notes, color: d.color, url: d.url, free: d.free, private: d.private }
        if (d.rep.dirty || d.isNew) extra.repeat = buildRule(d.rep, d.day)
        if (d.alarmsDirty || d.isNew) extra.alarms = d.alarms
        if (d.isNew) writer.ask(["sh", "-c", 'u=$(latte-cal add "$1" "$2" "$3" "$4" "$5" | sed -n \'s/.*"uid": "\\([^"]*\\)".*/\\1/p\'); [ -n "$u" ] && latte-cal update "$1" "$u" "$6"; true',
                                 "sh", d.source, d.title.trim(), s[0], s[1], d.location, JSON.stringify(extra)])
        else {
            if (d.recurring) Object.assign(extra, { scope: scope, rid: d.rid, orig: d.orig })
            writer.ask(["sh", "-c", 'latte-cal update "$1" "$2" "$3" && { [ "$1" = "$4" ] || latte-cal move "$1" "$2" "$4"; }; true',
                        "sh", d.origin, d.uid, JSON.stringify(Object.assign({ title: d.title.trim(), start: s[0], end: s[1], location: d.location }, extra)), d.source])
        }
        draft = null; picked = null; scopeAsk = null
    }
    function take(e) {
        if (e.repeat) { askScope(["this", "future", "all"], sc => doTake(e, sc)); return }
        doTake(e, "all")
    }
    function doTake(e, scope) {
        writer.ask(["latte-cal", "remove", e.source, e.uid].concat(scope === "all" ? [] : [scope, e.rid])); picked = null; asking = false; scopeAsk = null; undoable = true; undoTimer.restart()
    }
    function copy(e) { writer.ask(["latte-cal", "duplicate", e.source, e.uid]) }
    Timer { id: undoTimer; interval: 10000; onTriggered: shell.undoable = false }
    function menuFor(e, x, y) {      // the right button on an event: edit, colour, duplicate, delete
        if (e.kind !== "event" || !e.writable) { picked = e; return }
        picked = e; draft = null; asking = false
        const paint = c => writer.ask(["latte-cal", "update", e.source, e.uid, JSON.stringify({ color: c })])
        const mine = (calendars.find(c => c.uid === e.source) || {}).color || ""
        const names = [QT_TR_NOOP("The colour of its calendar"), QT_TR_NOOP("Blue"), QT_TR_NOOP("Violet"), QT_TR_NOOP("Orange"), QT_TR_NOOP("Green"), QT_TR_NOOP("Cyan"), QT_TR_NOOP("Gold"), QT_TR_NOOP("Red")]
        menu.open(x, y, [{ text: I18n.tr("Edit"), icon: "pencil", run: () => edit(e) },
                         { text: I18n.tr("Duplicate"), icon: "copy", run: () => copy(e) },
                         { text: I18n.tr("Colour"), icon: "droplet", more: swatches.map((c, i) => ({ text: I18n.tr(names[i]), tint: c === "" ? mine : c, checked: (e.own_color || "") === c, run: () => paint(c) })) },
                         { line: true }, { text: I18n.tr("Delete"), icon: "trash", danger: true, run: () => take(e) }])
    }
    function move(e, dayShift, minShift, longer) {
        if (!e.writable || e.kind !== "event" || e.time === "") return
        const s0 = minutes(e.time), f0 = e.end ? minutes(e.end) : s0 + 60
        const s = Math.max(0, Math.min(1425, s0 + (longer ? 0 : minShift))), f = Math.max(s + 15, (f0 > s0 ? f0 : s0 + 60) + minShift)
        const day = iso(plus(parse(e.start.slice(0, 10)), dayShift))
        const change = { start: day + "T" + hm(s), end: f >= 1440 ? iso(plus(parse(day), 1)) + "T" + hm(f - 1440) : day + "T" + hm(f) }
        const send = sc => { scopeAsk = null; writer.ask(["latte-cal", "update", e.source, e.uid, JSON.stringify(e.repeat ? Object.assign(change, { scope: sc, rid: e.rid, orig: e.start }) : change)]) }
        if (e.repeat) askScope(["this", "future", "all"], send); else send("all")
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
            Label { visible: shell.view !== "month" && shell.view !== "work"; text: I18n.tr("week {n}", { n: shell.week(shell.days[0]) }); color: Theme.dim; font.family: Theme.mono; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter },
            Rectangle { height: 38; radius: 14; color: Theme.ground; width: seg.implicitWidth + 8; anchors.verticalCenter: parent.verticalCenter
                Row { id: seg; x: 4; y: 4; spacing: 4
                    Repeater { model: [{ id: "day", name: QT_TR_NOOP("Day") }, { id: "week", name: QT_TR_NOOP("Week") }, { id: "month", name: QT_TR_NOOP("Month") }, { id: "work", name: QT_TR_NOOP("Work") }]
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
                        Repeater { model: shell.weekNames
                            Label { required property string modelData; width: 234 / 7; height: 20; horizontalAlignment: Text.AlignHCenter; text: I18n.tr(modelData).charAt(0).toUpperCase(); color: Theme.faint; font.family: Theme.mono; font.pixelSize: 10 } }
                        Repeater { model: { const f = new Date(shell.anchor.getFullYear(), shell.anchor.getMonth(), 1, 12), lead = ((f.getDay() + 6) % 7 - shell.ws + 7) % 7, n = new Date(f.getFullYear(), f.getMonth() + 1, 0).getDate(); const out = []; for (let i = 0; i < lead + n; i++) out.push(i < lead ? null : new Date(f.getFullYear(), f.getMonth(), i - lead + 1, 12)); return out }
                            Rectangle { required property var modelData; width: 234 / 7; height: 26; radius: 7
                                readonly property bool today: modelData !== null && shell.iso(modelData) === shell.iso(shell.now)
                                readonly property bool inside: modelData !== null && shell.days.some(d => shell.iso(d) === shell.iso(modelData))
                                color: today ? Theme.gold : (inside && shell.view !== "month" ? Theme.raised : "transparent")
                                Label { anchors.centerIn: parent; text: parent.modelData ? parent.modelData.getDate() : ""; font.family: Theme.mono; font.pixelSize: 11; color: parent.today ? Theme.inkOnGold : Theme.cream; font.weight: parent.today ? 800 : 400 }
                                MouseArea { anchors.fill: parent; enabled: parent.modelData !== null; cursorShape: Qt.PointingHandCursor; onClicked: shell.anchor = parent.modelData } } } } }
                // the calendars: a tick shows or hides one; holidays are LatteOS's own
                Column { width: parent.width; spacing: 8
                    Label { text: I18n.tr("MY CALENDARS"); color: Theme.faint; font.family: Theme.mono; font.pixelSize: 11; font.weight: 700 }
                    Repeater { model: shell.calendars.filter(c => c.enabled).concat([{ uid: "holidays", name: QT_TR_NOOP("Holidays"), account: "LatteOS", color: "#ff6b6b" }]).concat((shell.cfg.namedays || []).map(c => ({ uid: "nameday-" + c, name: I18n.tr("Name days") + " " + c.toUpperCase(), account: "LatteOS", color: "#b79bff" })))
                        Item { required property var modelData; width: 234; height: 24
                            readonly property bool on: !hiddenFile.list.includes(modelData.uid)
                            Rectangle { width: 16; height: 16; radius: 5; anchors.verticalCenter: parent.verticalCenter; color: parent.on ? parent.modelData.color : "transparent"; border.width: 2; border.color: parent.modelData.color
                                Glyph { anchors.centerIn: parent; visible: parent.parent.on; name: "check"; font.pixelSize: 12; color: "#17110d" } }
                            Label { x: 26; width: 150; text: I18n.tr(parent.modelData.name); font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
                            Label { anchors.right: parent.right; text: parent.modelData.account || ""; width: 60; horizontalAlignment: Text.AlignRight; color: Theme.faint; font.family: Theme.mono; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: hiddenFile.flip(parent.modelData.uid) } } }
                    Text { text: I18n.tr("Linked calendars…"); color: Theme.gold; font.family: Theme.font; font.pixelSize: 13; font.underline: true
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Quickshell.execDetached(["latte-linked"]) } }
                    Text { text: I18n.tr("Calendar settings…"); color: Theme.gold; font.family: Theme.font; font.pixelSize: 13; font.underline: true
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Quickshell.execDetached(["latte-calsettings"]) } } }
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
            visible: shell.view !== "month" && shell.view !== "work"
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
                                Label { x: 8; width: parent.width - 12; anchors.verticalCenter: parent.verticalCenter; text: shell.label(parent.modelData); font.pixelSize: 12; font.weight: 600 }
                                TapHandler { acceptedButtons: Qt.RightButton; onTapped: pt => { const q = parent.mapToItem(menu, pt.position.x, pt.position.y); shell.menuFor(parent.modelData, q.x, q.y) } }
                                TapHandler { acceptedButtons: Qt.LeftButton; onDoubleTapped: if (parent.modelData.writable && parent.modelData.kind === "event") shell.edit(parent.modelData) }
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
                                    TapHandler { acceptedButtons: Qt.RightButton; onTapped: pt => { const q = parent.mapToItem(menu, pt.position.x, pt.position.y); shell.menuFor(blk.e, q.x, q.y) } }
                                    TapHandler { acceptedButtons: Qt.LeftButton; onDoubleTapped: if (blk.e.writable && blk.e.kind === "event") shell.edit(blk.e) }
                                    MouseArea { id: stretcher; visible: blk.e.writable; anchors.bottom: parent.bottom; width: parent.width; height: 6; cursorShape: Qt.SizeVerCursor
                                        property real at: 0
                                        onPressed: m => at = mapToItem(col, 0, m.y).y
                                        onPositionChanged: m => { if (pressed) blk.grow = Math.round((mapToItem(col, 0, m.y).y - at) / shell.hourH * 4) * shell.hourH / 4 }
                                        onReleased: { const mins = Math.round(blk.grow / shell.hourH * 60); blk.grow = 0; if (mins !== 0) shell.move(blk.e, 0, mins, true) } } } }
                            // now: a red line across today
                            Rectangle { visible: col.key === shell.iso(shell.now); y: (shell.now.getHours() * 60 + shell.now.getMinutes()) / 60 * shell.hourH; width: parent.width; height: 2; color: "#ff6b6b"; z: 6
                                Rectangle { x: -6; y: -5; width: 12; height: 12; radius: 6; color: "#ff6b6b" } } } } } }
        }

        // ── the work calendar: working days by month, and what can be counted with them ────────────────────────────
        Item {
            id: workView
            visible: shell.view === "work"
            anchors.fill: parent; anchors.margins: 22; anchors.rightMargin: side.width + 22
            // the year, month by month: days worked, hours, holidays that fall on a working day, bridges
            Column { id: wtable; width: Math.min(parent.width * 0.6, 620); spacing: 3
                Row { height: 28
                    Repeater { model: [[QT_TR_NOOP("MONTH"), 150], [QT_TR_NOOP("WORKING DAYS"), 120], [QT_TR_NOOP("HOURS"), 90], [QT_TR_NOOP("HOLIDAYS"), 90], [QT_TR_NOOP("BRIDGES"), 90]]
                        Label { required property var modelData; width: modelData[1]; height: 28; verticalAlignment: Text.AlignVCenter; text: I18n.tr(modelData[0]); color: Theme.faint; font.family: Theme.mono; font.pixelSize: 11; font.weight: 700 } } }
                Repeater { model: shell.workData
                    Rectangle { required property var modelData; width: wtable.width; height: 33; radius: 9
                        readonly property bool now: modelData.month === new Date().getMonth() + 1 && shell.anchor.getFullYear() === new Date().getFullYear()
                        color: now ? Theme.raised : "transparent"
                        Row { anchors.verticalCenter: parent.verticalCenter; leftPadding: 0
                            Label { width: 150; leftPadding: 10; text: I18n.tr(shell.monthNames[parent.parent.modelData.month - 1]); font.pixelSize: 14; font.weight: parent.parent.now ? 800 : 500 }
                            Label { width: 120; text: parent.parent.modelData.days; font.family: Theme.mono; font.pixelSize: 14; font.weight: 800 }
                            Label { width: 90; text: parent.parent.modelData.hours + " h"; font.family: Theme.mono; font.pixelSize: 13; color: Theme.dim }
                            Label { width: 90; text: parent.parent.modelData.holidays_on_workdays.length; font.family: Theme.mono; font.pixelSize: 13; color: Theme.dim }
                            Label { width: 90; text: parent.parent.modelData.bridges.length; font.family: Theme.mono; font.pixelSize: 13; color: Theme.dim } }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { shell.rangeFrom = shell.iso(new Date(shell.anchor.getFullYear(), parent.modelData.month - 1, 1, 12)); shell.rangeTo = shell.iso(new Date(shell.anchor.getFullYear(), parent.modelData.month, 0, 12)) } } } }
                Rectangle { width: wtable.width; height: 1; color: Theme.line }
                Row { height: 36
                    Label { width: 150; leftPadding: 10; height: 36; verticalAlignment: Text.AlignVCenter; text: I18n.tr("Year"); font.pixelSize: 14; font.weight: 800 }
                    Label { width: 120; height: 36; verticalAlignment: Text.AlignVCenter; text: shell.workData.reduce((a, m) => a + m.days, 0); font.family: Theme.mono; font.pixelSize: 15; font.weight: 800; color: Theme.gold }
                    Label { width: 90; height: 36; verticalAlignment: Text.AlignVCenter; text: shell.workData.reduce((a, m) => a + m.hours, 0) + " h"; font.family: Theme.mono; font.pixelSize: 13; color: Theme.dim }
                    Label { width: 90; height: 36; verticalAlignment: Text.AlignVCenter; text: shell.workData.reduce((a, m) => a + m.holidays_on_workdays.length, 0); font.family: Theme.mono; font.pixelSize: 13; color: Theme.dim }
                    Label { width: 90; height: 36; verticalAlignment: Text.AlignVCenter; text: shell.workData.reduce((a, m) => a + m.bridges.length, 0); font.family: Theme.mono; font.pixelSize: 13; color: Theme.dim } }
                Label { width: wtable.width; wrapMode: Text.WordWrap; color: Theme.faint; font.pixelSize: 12
                        text: I18n.tr("Counted from the working days and the hours a day in the calendar settings, without the holidays that are days off. A bridge is a working day between a holiday and a day off.") } }
            // what can be counted: the working days between two days, and the day that is some working days away
            Column { x: wtable.width + 28; width: parent.width - x; spacing: 14
                Rectangle { width: parent.width; height: rangeCol.height + 36; radius: 14; color: Theme.card; border.width: 1; border.color: Theme.line
                    Column { id: rangeCol; x: 18; y: 18; width: parent.width - 36; spacing: 10
                        Label { text: I18n.tr("WORKING DAYS BETWEEN"); color: Theme.faint; font.family: Theme.mono; font.pixelSize: 11; font.weight: 700 }
                        Row { spacing: 8
                            PickField { width: (rangeCol.width - 8) / 2; icon: "calendar"; text: shell.dayText(shell.rangeFrom); hint: I18n.tr("From"); onOpened: it => datePick.open(shell.at(it).x, shell.at(it).y, shell.rangeFrom, v => shell.rangeFrom = v) }
                            PickField { width: (rangeCol.width - 8) / 2; icon: "arrow-right"; text: shell.dayText(shell.rangeTo); hint: I18n.tr("To"); onOpened: it => datePick.open(shell.at(it).x, shell.at(it).y, shell.rangeTo, v => shell.rangeTo = v) } }
                        Label { visible: shell.rangeData !== null; text: shell.rangeData ? I18n.tr("{n} working days", { n: shell.rangeData.days }) : ""; font.pixelSize: 24; font.weight: 800; color: Theme.gold }
                        Label { visible: shell.rangeData !== null; color: Theme.dim; font.pixelSize: 13; width: parent.width; wrapMode: Text.WordWrap
                                text: shell.rangeData ? I18n.tr("{h} hours · {c} days in all · {o} days off", { h: shell.rangeData.hours, c: shell.rangeData.calendar_days, o: shell.rangeData.days_off }) : "" }
                        Label { visible: shell.rangeData !== null && shell.rangeData.holidays_on_workdays.length > 0; width: parent.width; wrapMode: Text.WordWrap; color: Theme.dim; font.pixelSize: 12
                                text: shell.rangeData ? I18n.tr("Holidays on a working day:") + "\n" + shell.rangeData.holidays_on_workdays.map(h => shell.dayText(h.date) + " " + h.name).join("\n") : "" }
                        Label { visible: shell.rangeData !== null && shell.rangeData.bridges.length > 0; width: parent.width; wrapMode: Text.WordWrap; color: Theme.dim; font.pixelSize: 12
                                text: shell.rangeData ? I18n.tr("Bridges:") + " " + shell.rangeData.bridges.map(d => shell.dayText(d)).join(", ") : "" } } }
                Rectangle { width: parent.width; height: addCol.height + 36; radius: 14; color: Theme.card; border.width: 1; border.color: Theme.line
                    Column { id: addCol; x: 18; y: 18; width: parent.width - 36; spacing: 10
                        Label { text: I18n.tr("A DAY SOME WORKING DAYS AWAY"); color: Theme.faint; font.family: Theme.mono; font.pixelSize: 11; font.weight: 700 }
                        Row { spacing: 8
                            PickField { width: addCol.width - 3 * 8 - 40 - 46 - 40; icon: "calendar"; text: shell.dayText(shell.addFrom); hint: I18n.tr("From"); onOpened: it => datePick.open(shell.at(it).x, shell.at(it).y, shell.addFrom, v => shell.addFrom = v) }
                            Pill { implicitHeight: 40; text: "−"; onPressed: shell.addN = shell.addN - 1 }
                            Label { height: 40; verticalAlignment: Text.AlignVCenter; width: 46; horizontalAlignment: Text.AlignHCenter; text: (shell.addN > 0 ? "+" : "") + shell.addN; font.family: Theme.mono; font.pixelSize: 16; font.weight: 800 }
                            Pill { implicitHeight: 40; text: "+"; onPressed: shell.addN = shell.addN + 1 } }
                        Label { text: shell.dayText(shell.addResult); visible: shell.addResult !== ""; font.pixelSize: 24; font.weight: 800; color: Theme.gold }
                        Label { text: shell.addN >= 0 ? I18n.tr("working days after the day chosen") : I18n.tr("working days before the day chosen"); color: Theme.dim; font.pixelSize: 13 } } } }
        }

        // ── a month: its own days only, as ClockGoo's card; a press on a day shows it ─────────────────────────
        Item {
            visible: shell.view === "month"
            anchors.fill: parent; anchors.margins: 18; anchors.rightMargin: side.width + 18
            readonly property var first: new Date(shell.anchor.getFullYear(), shell.anchor.getMonth(), 1, 12)
            readonly property int lead: ((first.getDay() + 6) % 7 - shell.ws + 7) % 7
            readonly property int length: new Date(first.getFullYear(), first.getMonth() + 1, 0).getDate()
            readonly property int rows: Math.ceil((lead + length) / 7)
            Row { id: mhead
                Repeater { model: shell.weekNames
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
                                    Label { x: 6; width: parent.width - 8; anchors.verticalCenter: parent.verticalCenter; text: (parent.modelData.time ? parent.modelData.time + " " : "") + shell.label(parent.modelData); font.pixelSize: 11 }
                                    TapHandler { acceptedButtons: Qt.RightButton; onTapped: pt => { const q = parent.mapToItem(menu, pt.position.x, pt.position.y); shell.menuFor(parent.modelData, q.x, q.y) } }
                                    TapHandler { acceptedButtons: Qt.LeftButton; onDoubleTapped: if (parent.modelData.writable && parent.modelData.kind === "event") shell.edit(parent.modelData) }
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
                Row { visible: (parent.e.repeat || "") !== ""; spacing: 8
                    Glyph { name: "repeat"; color: Theme.dim; font.pixelSize: 15 }
                    Label { text: shell.ruleText(parent.parent.e.repeat || ""); color: Theme.dim; width: 270; wrapMode: Text.WordWrap } }
                Row { visible: (parent.e.alarms || []).length > 0 && parent.e.kind === "event"; spacing: 8
                    Glyph { name: "bell"; color: Theme.dim; font.pixelSize: 15 }
                    Label { text: (parent.parent.e.alarms || []).map(a => shell.alarmText(a)).join(" · "); color: Theme.dim; width: 270; wrapMode: Text.WordWrap } }
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
                           onPressed: { if (shell.asking) shell.take(shell.picked); else shell.asking = true } } }
                Row { spacing: 8
                    Pill { visible: shell.picked !== null && shell.picked.kind === "event" && shell.picked.writable; icon: "copy"; text: I18n.tr("Duplicate"); onPressed: shell.copy(shell.picked) }
                    Pill { icon: "x"; text: I18n.tr("Close"); onPressed: { shell.picked = null; shell.asking = false } } }
            }
            // the event being written: what, when, where, a note, its colour, and for a new one its calendar
            Flickable {
                visible: shell.draft !== null
                anchors.fill: parent; anchors.leftMargin: 1; contentHeight: form.height + 40; clip: true; boundsBehavior: Flickable.StopAtBounds
                Column {
                    id: form; x: 21; y: 22; width: 296; spacing: 12
                    readonly property var d: shell.draft || ({ rep: shell.noRepeat() })
                    function set(k, v) { const n = Object.assign({}, shell.draft); n[k] = v; shell.draft = n }
                    readonly property var dayOf: shell.parse(d.day || shell.iso(new Date()))
                    readonly property string dayCode: shell.rcodes[(dayOf.getDay() + 6) % 7]
                    readonly property var chosenDays: d.rep && d.rep.days.length ? d.rep.days : [dayCode]
                    function show(day) { return /^\d{4}-\d{2}-\d{2}$/.test(day || "") ? shell.parse(day).getDate() + ". " + (shell.parse(day).getMonth() + 1) + ". " + shell.parse(day).getFullYear() : "" }
                    // the first day moved: the last one moves with it, so that a long event stays as long
                    function setDay(v) {
                        const n = Object.assign({}, shell.draft), days = /^\d{4}-\d{2}-\d{2}$/.test(n.endDay || "") && /^\d{4}-\d{2}-\d{2}$/.test(n.day || "") ? Math.max(0, Math.round((shell.parse(n.endDay) - shell.parse(n.day)) / 864e5)) : 0
                        n.day = v; n.endDay = shell.iso(shell.plus(shell.parse(v), days)); shell.draft = n
                    }
                    function setEndDay(v) { const n = Object.assign({}, shell.draft); n.endDay = v < n.day ? n.day : v; shell.draft = n }
                    // the start moved: the end moves with it (never past midnight), as Google does
                    function setFrom(v) {
                        const n = Object.assign({}, shell.draft), a = shell.minutes(n.from), b = shell.minutes(n.to), now = shell.minutes(v)
                        n.from = v
                        if (a >= 0 && b > a) n.to = shell.hm(Math.min(1439, now + (b - a)))
                        else if (b < 0 || b <= now) n.to = shell.hm(Math.min(1439, now + 60))
                        shell.draft = n
                    }
                    function setRep(k, v) { const r = Object.assign({}, shell.draft.rep); r[k] = v; r.dirty = true; set("rep", r) }
                    Label { text: form.d.isNew ? I18n.tr("New event") : I18n.tr("Edit the event"); font.pixelSize: 18; font.weight: 800 }
                    Field { width: parent.width; icon: "pencil"; hint: I18n.tr("What"); text: form.d.title || ""; onTextChanged: if (shell.draft && text !== shell.draft.title) form.set("title", text); onAccepted: shell.save() }
                    Row { spacing: 8
                        PickField { icon: "calendar"; text: form.show(form.d.day); hint: I18n.tr("Day"); onOpened: it => datePick.open(shell.at(it).x, shell.at(it).y, form.d.day, v => form.setDay(v)) }
                        PickField { icon: "arrow-right"; text: form.show(form.d.endDay); hint: I18n.tr("The last day"); onOpened: it => datePick.open(shell.at(it).x, shell.at(it).y, form.d.endDay || form.d.day, v => form.setEndDay(v)) } }
                    Row { spacing: 8
                        Pill { implicitHeight: 32; text: I18n.tr("All day"); icon: form.d.allday ? "check" : ""; strong: form.d.allday === true; onPressed: form.set("allday", !form.d.allday) } }
                    Row { spacing: 8; visible: !form.d.allday
                        PickField { icon: "clock"; text: form.d.from || ""; hint: "09:00"; onOpened: it => timePick.open(shell.at(it).x, shell.at(it).y, form.d.from || "09:00", v => form.setFrom(v)) }
                        PickField { icon: "clock"; text: form.d.to || ""; hint: "10:00"; onOpened: it => timePick.open(shell.at(it).x, shell.at(it).y, form.d.to || form.d.from || "10:00", v => form.set("to", v)) } }
                    // repeating, as Google's "Does not repeat" and "Custom…" in one place
                    Label { text: I18n.tr("REPEAT"); color: Theme.faint; font.family: Theme.mono; font.pixelSize: 11; font.weight: 700 }
                    Flow { width: parent.width; spacing: 6
                        Repeater { model: [["", QT_TR_NOOP("Does not repeat")], ["d", QT_TR_NOOP("Daily")], ["w", QT_TR_NOOP("Weekly")], ["m", QT_TR_NOOP("Monthly")], ["y", QT_TR_NOOP("Yearly")]]
                            Pill { required property var modelData; implicitHeight: 30; text: I18n.tr(modelData[1]); strong: form.d.rep.freq === modelData[0]; onPressed: form.setRep("freq", modelData[0]) } } }
                    Row { visible: form.d.rep.freq !== ""; spacing: 8
                        Label { anchors.verticalCenter: parent.verticalCenter; text: I18n.tr("Every") }
                        Field { width: 70; icon: "repeat"; hint: "1"; text: "" + form.d.rep.interval; onTextChanged: { const n = parseInt(text); if (shell.draft && n > 0 && n !== shell.draft.rep.interval) form.setRep("interval", n) } }
                        Label { anchors.verticalCenter: parent.verticalCenter; text: I18n.tr(({ d: QT_TR_NOOP("days"), w: QT_TR_NOOP("weeks"), m: QT_TR_NOOP("months"), y: QT_TR_NOOP("years") })[form.d.rep.freq] || "") } }
                    Row { visible: form.d.rep.freq === "w"; spacing: 4
                        Repeater { model: shell.rcodes
                            Rectangle { required property string modelData; required property int index
                                readonly property bool on: form.chosenDays.includes(modelData)
                                width: 38; height: 32; radius: 16; color: on ? Theme.gold : Theme.card; border.width: 1; border.color: on ? Theme.gold : Theme.line
                                Label { anchors.centerIn: parent; text: I18n.tr(shell.dayNames[parent.index]); color: parent.on ? "#17110d" : Theme.cream; font.pixelSize: 12; font.weight: 700 }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: { const m = parent.modelData, next = form.chosenDays.includes(m) ? form.chosenDays.filter(c => c !== m) : form.chosenDays.concat([m])
                                                 if (next.length) form.setRep("days", shell.rcodes.filter(c => next.includes(c))) } } } } }
                    Flow { visible: form.d.rep.freq === "m"; width: parent.width; spacing: 6
                        Pill { implicitHeight: 30; strong: form.d.rep.monthly === "day"; text: I18n.tr("On day {n}", { n: form.dayOf.getDate() }); onPressed: form.setRep("monthly", "day") }
                        Pill { implicitHeight: 30; strong: form.d.rep.monthly === "nth"; onPressed: form.setRep("monthly", "nth")
                               text: I18n.tr("{n}. {day} of the month", { n: Math.ceil(form.dayOf.getDate() / 7) > 4 ? I18n.tr("last") : Math.ceil(form.dayOf.getDate() / 7), day: I18n.tr(shell.dayNames[(form.dayOf.getDay() + 6) % 7]) }) } }
                    Flow { visible: form.d.rep.freq !== ""; width: parent.width; spacing: 6
                        Pill { implicitHeight: 30; strong: form.d.rep.end === "never"; text: I18n.tr("Never ends"); onPressed: form.setRep("end", "never") }
                        Pill { implicitHeight: 30; strong: form.d.rep.end === "date"; text: I18n.tr("Ends on a day"); onPressed: form.setRep("end", "date") }
                        Pill { implicitHeight: 30; strong: form.d.rep.end === "count"; text: I18n.tr("Ends after some times"); onPressed: form.setRep("end", "count") } }
                    PickField { visible: form.d.rep.freq !== "" && form.d.rep.end === "date"; width: 170; icon: "calendar"; hint: I18n.tr("Day"); text: form.show(form.d.rep.until)
                                onOpened: it => datePick.open(shell.at(it).x, shell.at(it).y, form.d.rep.until || form.d.day, v => form.setRep("until", v)) }
                    Row { visible: form.d.rep.freq !== "" && form.d.rep.end === "count"; spacing: 8
                        Field { width: 90; icon: "repeat"; hint: "10"; text: "" + form.d.rep.count; onTextChanged: { const n = parseInt(text); if (shell.draft && n > 0 && n !== shell.draft.rep.count) form.setRep("count", n) } }
                        Label { anchors.verticalCenter: parent.verticalCenter; text: I18n.tr("times") } }
                    Label { text: I18n.tr("REMINDERS"); color: Theme.faint; font.family: Theme.mono; font.pixelSize: 11; font.weight: 700 }
                    Flow { width: parent.width; spacing: 6
                        Repeater { model: { const m = shell.alarmSteps.map(x => x[0]); return shell.alarmSteps.map(x => x[0]).concat((form.d.alarms || []).filter(a => !m.includes(a))).sort((a, b) => a - b) }
                            Pill { required property int modelData; implicitHeight: 30; text: shell.alarmText(modelData); icon: (form.d.alarms || []).includes(modelData) ? "bell" : ""; strong: (form.d.alarms || []).includes(modelData)
                                   onPressed: { const a = form.d.alarms || []; form.set("alarms", a.includes(modelData) ? a.filter(x => x !== modelData) : a.concat([modelData])); form.set("alarmsDirty", true) } } } }
                    Field { width: parent.width; icon: "map-pin"; hint: I18n.tr("Where"); text: form.d.location || ""; onTextChanged: if (shell.draft && text !== shell.draft.location) form.set("location", text) }
                    Field { width: parent.width; icon: "video"; hint: I18n.tr("Video call address"); text: form.d.url || ""; onTextChanged: if (shell.draft && text !== shell.draft.url) form.set("url", text) }
                    Row { spacing: 8
                        Pill { implicitHeight: 32; icon: form.d.free ? "" : "check"; strong: !form.d.free; text: I18n.tr("Busy"); onPressed: form.set("free", false) }
                        Pill { implicitHeight: 32; icon: form.d.free ? "check" : ""; strong: form.d.free === true; text: I18n.tr("Free"); onPressed: form.set("free", true) }
                    }
                    Row { spacing: 8
                        Pill { implicitHeight: 32; icon: "lock"; strong: form.d.private === true; text: I18n.tr("Private"); onPressed: form.set("private", !form.d.private) } }
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
                    Column { width: parent.width; spacing: 6
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
        Item { id: overlay; anchors.fill: parent; z: 50
            Menu { id: menu }
            DatePick { id: datePick }
            TimePick { id: timePick }
            Rectangle { visible: shell.scopeAsk !== null; anchors.fill: parent; color: Qt.rgba(0, 0, 0, 0.35); z: 5
                MouseArea { anchors.fill: parent; onClicked: shell.scopeAsk = null }
                Rectangle { anchors.centerIn: parent; width: 320; height: scopeCol.height + 36; radius: 16; color: Theme.card; border.width: 1; border.color: Theme.line
                    MouseArea { anchors.fill: parent }
                    Column { id: scopeCol; x: 18; y: 18; width: parent.width - 36; spacing: 8
                        Label { text: I18n.tr("A repeating event"); font.pixelSize: 16; font.weight: 800 }
                        Repeater { model: shell.scopeAsk ? shell.scopeAsk.options : []
                            Pill { required property string modelData; width: scopeCol.width; text: I18n.tr(({ this: QT_TR_NOOP("This event"), future: QT_TR_NOOP("This and following events"), all: QT_TR_NOOP("All events") })[modelData]); strong: modelData === "all"
                                   onPressed: shell.scopeAsk.run(modelData) } }
                        Pill { width: scopeCol.width; icon: "x"; text: I18n.tr("Cancel"); onPressed: shell.scopeAsk = null } } } }
            Rectangle { visible: shell.undoable; anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: 24
                width: undoRow.width + 28; height: 44; radius: 14; color: Theme.card; border.width: 1; border.color: Theme.line
                Row { id: undoRow; anchors.centerIn: parent; spacing: 12
                    Label { anchors.verticalCenter: parent.verticalCenter; text: I18n.tr("The event was taken out") }
                    Pill { implicitHeight: 30; strong: true; icon: "arrow-back-up"; text: I18n.tr("Undo"); onPressed: { writer.ask(["latte-cal", "undo"]); shell.undoable = false } } } } }
    }
}
