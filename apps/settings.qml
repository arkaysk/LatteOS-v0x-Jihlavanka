// Settings: everything about the computer and the desktop that can be set, in one place, by areas, with a search.
// The areas and their pages are listed in settings/pages.json (LensGoo searches the same list: bin/latte-settings).
// A page that LatteOS does not have yet is listed all the same, and says where the thing is done meanwhile.
//   latte-app settings [PAGE]
//
// The side is a menu that unfolds: an area, and under it its pages. A dot says how far a page is: full when it
// works here, hollow when it is still to come. Typing in the header's field lists the pages that match.
import QtQuick
import QtQuick.Dialogs
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import "common"

ShellRoot {
    id: shell
    readonly property string share: Quickshell.env("LATTE_SHARE") || "/usr/share/latteos"
    readonly property string config: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/latteos"
    readonly property var words: (Quickshell.env("LATTE_APP_ARGS") || "").split("\n").filter(w => w !== "")

    // ── the areas and the pages ───────────────────────────────────────────────────────────────────────────
    property var areasAll: []
    FileView { path: shell.share + "/apps/settings/pages.json"; onLoaded: { try { shell.areasAll = JSON.parse(text()) } catch (e) {} if (shell.words[0]) shell.go(shell.words[0]) } }
    // basic, or everything beyond it: details and changes at the system's level (pages marked "expert" in pages.json, and
    // parts of pages); the choice is kept (~/.config/latteos/settings-mode) and switched at the window's foot
    Word { id: modeWord; name: "settings-mode" }
    readonly property bool expert: modeWord.value === "expert"
    // the pages of Drops (Goo): which drop each is about, and what that drop is, said on its page
    readonly property var dropOf: ({ bargoo: "bargoo", powergoo: "powergoo", launcher: "lensgoo", quickgoo: "quickgoo",
                                     clockgoo: "clockgoo", queengoo: "queengoo", camgoo: "camgoo", mediagoo: "mediagoo" })
    readonly property var dropAbout: ({
        bargoo: QT_TR_NOOP("The windows: its head shows how they are arranged, and where windows float they hang beside it as berries. Left: the arrangement, right: the desktop, the wheel: the next window."),
        powergoo: QT_TR_NOOP("The account and the power: sign out, sleep, restart, shut down, the battery and Settings. Right: the performance band."),
        quickgoo: QT_TR_NOOP("The apps you keep at hand, up to eight, on a strip that slides out of it. You add them in LensGoo with the right button."),
        queengoo: QT_TR_NOOP("The App Manager on the left button, the Device Manager on the right."),
        mediagoo: QT_TR_NOOP("On the desktop only while something plays: the cover, play and pause, the next one, the volume on the wheel.") })
    function setExpert(on) { modeWord.choose(on ? "expert" : "basic"); if (!on && here && here.expert) { page = ""; asked = "" } }
    readonly property var areas: areasAll.map(a => Object.assign({}, a, { pages: a.pages.filter(p => expert || !p.expert) })).filter(a => a.pages.length > 0)
    property string page: ""                   // "" is the front page
    property string unfolded: "look"           // the area whose pages show in the side
    property string asked: ""                  // what is searched for
    readonly property var all: { const l = []; for (const a of areas) for (const p of a.pages) l.push(Object.assign({ area: a }, p)); return l }
    readonly property var here: all.find(p => p.id === page) || null
    function go(id) {
        // a page of the expert mode asked for by name (LensGoo, a link): the mode comes on with it
        if (!all.find(q => q.id === id) && areasAll.some(a => a.pages.some(q => q.id === id && q.expert))) { setExpert(true); Qt.callLater(() => go(id)); return }
        const p = all.find(q => q.id === id); if (p) { page = id; unfolded = p.area.id; asked = "" }
    }
    // no accents, no case, y as i; as in bin/latte-settings, which LensGoo asks: a slip of a letter does not matter
    function plain(s) { return s.toLowerCase().normalize("NFD").replace(/[̀-ͯ]/g, "").replace(/y/g, "i") }
    function close(a, b) {
        if (Math.abs(a.length - b.length) > 1) return false
        if (a === b) return true
        let i = 0
        while (i < Math.min(a.length, b.length) && a[i] === b[i]) i++
        return a.slice(i + 1) === b.slice(i + 1) || a.slice(i) === b.slice(i + 1) || a.slice(i + 1) === b.slice(i)
            || (i + 1 < Math.min(a.length, b.length) && a[i] === b[i + 1] && a[i + 1] === b[i] && a.slice(i + 2) === b.slice(i + 2))
    }
    function near(word, hay) {
        if (hay.includes(word)) return true
        if (word.length < 4) return false
        for (const t of hay.split(" ")) for (const n of [word.length - 1, word.length, word.length + 1]) if (close(word, t.slice(0, n))) return true
        return false
    }
    readonly property var found: {
        const need = plain(asked).split(/\s+/).filter(w => w !== "").map(w => w.slice(0, 5))
        if (need.length === 0) return []
        return all.filter(p => { const hay = plain([p.name, I18n.tr(p.name), p.area.name, I18n.tr(p.area.name), p.words || "", I18n.tr(p.words || "")].join(" ")); return need.every(w => near(w, hay)) })
    }
    function elsewhere(p) { Quickshell.execDetached(["latte-app"].concat(p.elsewhere.split(" "))) }

    // ── what the pages read and write ─────────────────────────────────────────────────────────────────────
    component Word: FileView {                 // a choice kept as one word in a file of the user's
        property string name
        property string value: ""
        path: shell.config + "/" + name
        printErrors: false; watchChanges: true
        onFileChanged: reload()
        onLoaded: value = text().trim()
        function choose(word) { value = word; Quickshell.execDetached(["sh", "-c", "mkdir -p \"$1\" && printf '%s\\n' \"$3\" > \"$1/$2\"", "sh", shell.config, name, word]) }
    }
    Word { id: cup; name: "cup" }
    function cupOf(id) { return id === "wallpaper" ? (Theme.fromWallpaper || Theme.cups.espresso) : Theme.cups[id] }
    Word { id: glass; name: "glass" }
    Word { id: glassLevel; name: "glass-level" }
    Word { id: wallpaper; name: "wallpaper" }
    Word { id: icons; name: "desktop-icons" }
    Word { id: screensWord; name: "screens" }
    Word { id: nightWord; name: "nightlight" }
    // what the Goo scene keeps for itself: it takes a change up as soon as its file is written
    FileView {
        id: goo
        property var kept: ({})
        path: (Quickshell.env("XDG_DATA_HOME") || (Quickshell.env("HOME") + "/.local/share")) + "/pleamar/goo/settings.json"
        printErrors: false; watchChanges: true
        onFileChanged: reload()
        onLoaded: { try { kept = JSON.parse(text()) } catch (e) { kept = {} } }
        function set(key, value) { const k = Object.assign({}, kept); k[key] = value; kept = k; setText(JSON.stringify(k)) }
    }
    // the drops that can be switched off, as the Goo scene wrote them down when it started
    FileView {
        id: dropList
        property var list: []
        path: (Quickshell.env("XDG_DATA_HOME") || (Quickshell.env("HOME") + "/.local/share")) + "/pleamar/goo/switchable.json"
        printErrors: false; watchChanges: true
        onFileChanged: reload()
        onLoaded: { try { list = JSON.parse(text()) } catch (e) { list = [] } }
    }
    component Run: Process {
        id: r
        property var data: null
        property string buf: ""
        function ask(args) { running = false; command = args; running = true }
        stdout: StdioCollector { onStreamFinished: r.buf = this.text }
        onExited: { try { data = JSON.parse(buf) } catch (e) {} }
    }
    // when the session locks and the screens go dark: seconds, 0 for never (system/libexec/latte-idle reads the file)
    FileView {
        id: idle
        property int lock: 600
        property int screen: 900
        path: shell.config + "/idle"; printErrors: false
        onLoaded: { const l = text().match(/^lock=(\d+)$/m), s = text().match(/^screen=(\d+)$/m); if (l) lock = parseInt(l[1]); if (s) screen = parseInt(s[1]) }
        function choose(l, s) {
            lock = l; screen = s
            Quickshell.execDetached(["sh", "-c", "mkdir -p \"$1\" && printf 'lock=%s\\nscreen=%s\\n' \"$2\" \"$3\" > \"$1/idle\" && systemctl --user restart latte-idle.service", "sh", shell.config, String(l), String(s)])
        }
    }
    readonly property var waits: [{ s: 60, name: QT_TR_NOOP("1 minute") }, { s: 300, name: QT_TR_NOOP("5 minutes") }, { s: 600, name: QT_TR_NOOP("10 minutes") }, { s: 900, name: QT_TR_NOOP("15 minutes") },
                                  { s: 1800, name: QT_TR_NOOP("30 minutes") }, { s: 3600, name: QT_TR_NOOP("1 hour") }, { s: 0, name: QT_TR_NOOP("Never") }]
    property string profile: ""
    Process { id: profiles; command: ["powerprofilesctl", "get"]; stdout: StdioCollector { onStreamFinished: shell.profile = this.text.trim() } }
    Process { id: setProfile; onExited: profiles.running = true }
    // ── the lists of the launcher (LensGoo): each is a button in its row of filters ─────────────────────
    // goo/lib/lens.luau reads the same file. A list takes in the apps of some desktop categories (the first four do),
    // minus those the user took out, plus those the user chose by hand.
    readonly property var lensDefaults: [
        { id: "work", name: "Work", builtin: true, on: true, cats: ["Office", "Utility", "Network", "Education"] },
        { id: "media", name: "Media", builtin: true, on: true, cats: ["AudioVideo", "Audio", "Video", "Graphics"] },
        { id: "dev", name: "Develop", builtin: true, on: true, cats: ["Development"] },
        { id: "fun", name: "Fun", builtin: true, on: true, cats: ["Game"] }]
    FileView {
        id: lensFile
        property var lists: []
        property var ai: null                  // the services LensGoo's AI offers, by id; null: all there are
        path: (Quickshell.env("XDG_DATA_HOME") || (Quickshell.env("HOME") + "/.local/share")) + "/pleamar/goo/lens-lists.json"
        printErrors: false; watchChanges: true
        onFileChanged: reload()
        property var modesOff: []              // LensGoo's modes the user hid: 1 files, 2 web, 3 command (lib/lens.luau)
        onLoaded: { try { const d = JSON.parse(text()); lists = Array.isArray(d.lists) ? d.lists : []; ai = Array.isArray(d.ai) ? d.ai : null; modesOff = Array.isArray(d.modes_off) ? d.modes_off : [] } catch (e) { lists = []; ai = null; modesOff = [] } }
        onLoadFailed: { lists = []; ai = null; modesOff = [] }
        function write() { const d = { lists: lists, modes_off: modesOff }; if (ai !== null) d.ai = ai; setText(JSON.stringify(d)) }
        function mode(n, on) { modesOff = modesOff.filter(m => m !== n).concat(on ? [] : [n]); write() }
        function save(l) { lists = l; write() }
    }
    readonly property var lensLists: lensFile.lists.length > 0 ? lensFile.lists : lensDefaults
    function lensEdit(i, change) { const l = JSON.parse(JSON.stringify(lensLists)); change(l[i]); lensFile.save(l) }
    function lensAuto(l, e) { return (l.cats || []).some(c => e.categories.includes(c)) }
    function lensHas(l, e) { return (l.apps || []).includes(e.id) || (lensAuto(l, e) && !(l.off || []).includes(e.id)) }
    function lensFlip(i, e) {
        lensEdit(i, l => {
            const has = lensHas(l, e), auto = lensAuto(l, e)
            l.apps = (l.apps || []).filter(x => x !== e.id); l.off = (l.off || []).filter(x => x !== e.id)
            if (has && auto) l.off.push(e.id)
            else if (!has && !auto) l.apps.push(e.id)
        })
    }
    readonly property var entries: DesktopEntries.applications.values.filter(e => !e.noDisplay).sort((a, b) => a.name.localeCompare(b.name))
    property int lensOpen: -1                  // the list whose apps are shown for choosing
    // ── ClockGoo's world clocks: the scene reads the same file (goo/drops/clockgoo.luau); the first is home ─────
    readonly property var clockDefaults: [
        { zone: "Europe/Bratislava", name: "Bratislava", country: "Slovakia" }, { zone: "Europe/London", name: "London", country: "United Kingdom" },
        { zone: "Asia/Tokyo", name: "Tokyo", country: "Japan" }, { zone: "America/New_York", name: "New York", country: "USA (East)" },
        { zone: "America/Los_Angeles", name: "San Francisco", country: "USA (West)" }]
    FileView {
        id: zonesFile
        property var list: []
        path: (Quickshell.env("XDG_DATA_HOME") || (Quickshell.env("HOME") + "/.local/share")) + "/pleamar/goo/zones.json"
        printErrors: false; watchChanges: true
        onFileChanged: reload()
        onLoaded: { try { const d = JSON.parse(text()); list = Array.isArray(d) ? d : [] } catch (e) { list = [] } }
        onLoadFailed: list = []
        function save(l) { list = l; setText(JSON.stringify(l)) }
    }
    readonly property var worldClocks: zonesFile.list.length > 0 ? zonesFile.list : clockDefaults
    function clocksEdit(change) { const l = JSON.parse(JSON.stringify(worldClocks)); change(l); zonesFile.save(l) }
    Run { id: focusq }
    Run { id: weatherq }
    // ── CamGoo's webcams: the scene reads the same file (goo/drops/camgoo.luau) ───────────────────────────
    readonly property var camDefaults: [
        { name: "Innsbruck", url: "https://www.foto-webcam.eu/webcam/innsbruck/current/1200.jpg" },
        { name: "Zugspitze", url: "https://www.foto-webcam.eu/webcam/zugspitze/current/1200.jpg" },
        { name: "Salzburg", url: "https://www.foto-webcam.eu/webcam/salzburg/current/1200.jpg" },
        { name: "Vienna", url: "https://www.foto-webcam.eu/webcam/wien/current/1200.jpg" }]
    FileView {
        id: camsFile
        property var list: []
        path: (Quickshell.env("XDG_DATA_HOME") || (Quickshell.env("HOME") + "/.local/share")) + "/pleamar/goo/cams.json"
        printErrors: false; watchChanges: true
        onFileChanged: reload()
        onLoaded: { try { const d = JSON.parse(text()); list = Array.isArray(d) ? d : [] } catch (e) { list = [] } }
        onLoadFailed: list = []
        function save(l) { list = l; setText(JSON.stringify(l)) }
    }
    readonly property var webcams: camsFile.list.length > 0 ? camsFile.list : camDefaults
    function camsEdit(change) { const l = JSON.parse(JSON.stringify(webcams)); change(l); camsFile.save(l) }
    Run { id: guardq }
    Run { id: sound }
    Run { id: opens }
    Run { id: region }
    Run { id: clock }
    Run { id: keys }
    Run { id: binds }
    // a bind as it is pressed: "Win + Shift + ←"
    readonly property var keyNames: ({ "SUPER_L": "", "left": "←", "right": "→", "up": "↑", "down": "↓", "equal": "+", "minus": "−", "Escape": "Esc", "mouse:272": QT_TR_NOOP("left button"), "mouse:273": QT_TR_NOOP("right button") })
    function pressed(b) {
        const key = keyNames[b.key] !== undefined ? I18n.tr(keyNames[b.key]) : b.key
        return [b.modmask & 64 ? "Win" : "", b.modmask & 4 ? "Ctrl" : "", b.modmask & 8 ? "Alt" : "", b.modmask & 1 ? "Shift" : "", key].filter(k => k !== "").join(" + ")
    }
    // what a page shows is asked for when it opens, and again after anything on it was changed
    readonly property var asks: ({ "": [[machine, ["latte-devices", "list"]], [screens, ["hyprctl", "monitors", "-j"]], [disks, ["latte-settings", "storage"]], [who, ["latte-settings", "account"]]],
                                   "sound": [[sound, ["latte-settings", "sound"]]], "defaults": [[opens, ["latte-settings", "defaults"]]], "language": [[region, ["latte-settings", "region"]]],
                                   "time": [[clock, ["latte-settings", "time"]]], "keyboard": [[keys, ["latte-settings", "keyboard"]], [binds, ["hyprctl", "binds", "-j"]]], "displays": [[screens, ["hyprctl", "monitors", "-j"]]],
                                   "guarddog": [[guardq, ["latte-guarddog", "status"]]], "clockgoo": [[clock, ["latte-settings", "time"]], [logon, ["latte-settings", "loginscreen"]], [focusq, ["latte-focus", "today"]], [weatherq, ["latte-sky", "models"]]], "storage": [[disks, ["latte-settings", "storage"]], [held, ["latte-settings", "sizes"]]], "ai": [[helpers, ["latte-ai", "modules"]]],
                                   "me": [[who, ["latte-settings", "account"]], [pictures, ["latte-settings", "wallpapers"]]], "performance": [[machine, ["latte-devices", "list"]]], "loginscreen": [[logon, ["latte-settings", "loginscreen"]]] })
    function ask() { (asks[page] || []).forEach(a => a[0].ask(a[1])); force.reload(); crashed.reload(); if (page === "background") wall.ask(["latte-wall", "state"]) }
    Timer { id: later; interval: 900; onTriggered: shell.ask() }       // what was asked of the compositor takes a moment to be so
    Component.onCompleted: ask()               // the front page is open from the start: no change of page asks for it

    // a file of the user's own, from anywhere: for the background ("wallpaper") or for the account's picture ("face")
    FileDialog { id: chooser; property string what: ""
                 nameFilters: what === "face" ? [I18n.tr("Pictures") + " (*.png *.jpg *.jpeg *.webp)"] : [I18n.tr("Pictures and films") + " (*.png *.jpg *.jpeg *.webp *.mp4 *.webm *.mkv *.mov)"]
                 onAccepted: { const path = decodeURIComponent(String(selectedFile).replace(/^file:\/\//, ""))
                               if (what === "face") shell.account("SetIconFile", path)
                               else shell.bgSet(["picture", path]) } }
    Run { id: disks }
    Run { id: held }
    Run { id: helpers }
    Run { id: who }
    Run { id: logon }
    Run { id: iconsets }
    Run { id: online }
    Run { id: wall }                           // what latte-wall says: the screens and what is on each
    readonly property var bg: wall.data
    property string bgTarget: "*"              // the screen a choice goes to, or * for every screen
    property string bgSource: "picture"
    property string showFolder: ""
    property int showMinutes: 10
    property bool showShuffle: false
    function bgSet(what) { order(["latte-wall", "set", bgTarget].concat(what)) }
    FolderDialog { id: folders; onAccepted: shell.showFolder = decodeURIComponent(String(selectedFolder).replace(/^file:\/\//, "")) }
    property string fetching: ""               // the one being fetched
    Process { id: fetcher; stdout: StdioCollector { onStreamFinished: { const path = this.text.trim(); shell.fetching = ""
        if (path !== "") { shell.bgSet(["picture", path]); pictures.ask(["latte-settings", "wallpapers"]) } } } }
    Word { id: tier; name: "tier" }
    // the password: the new one goes to latte-settings on its input, the present one is asked for by the system
    property string passSaid: ""
    Process { id: passer; command: ["latte-settings", "password"]; stdinEnabled: true
              property string fresh: ""
              onStarted: { write(fresh + "\n"); fresh = ""; stdinEnabled = false }
              stdout: StdioCollector { onStreamFinished: { let r = {}; try { r = JSON.parse(this.text) } catch (e) {}
                  shell.passSaid = r.ok ? I18n.tr("The password is changed.") : (r.error === "refused" ? I18n.tr("Not changed: the present password was not given.") : I18n.tr("Not changed.")) } } }
    Word { id: ai; name: "ai" }
    // whatever else in the system is AI hears of the switch: skwd-wall's search model (bin/latte-wall)
    Timer { id: aiLater; interval: 700; onTriggered: Quickshell.execDetached(["latte-wall", "ai"]) }
    // what latte-boot decided for this start, and whether the next one was asked to be SAFE
    FileView { id: decided; path: "/run/latteos/mode.toml"; printErrors: false
               property string mode: ""; property string renderer: ""; property string tier: ""; property string reason: ""
               onLoaded: { const get = k => (text().match(new RegExp("^" + k + " = \"(.*)\"$", "m")) || ["", ""])[1]; decided.mode = get("mode"); decided.renderer = get("renderer"); decided.tier = get("tier"); decided.reason = get("reason") } }
    // the report latte-session wrote when the desktop last crashed; the login screen shows its head
    FileView { id: crashed; path: "/var/lib/latteos/login/last-crash.log"; printErrors: false; property string said: ""
               onLoaded: said = text().trim(); onLoadFailed: said = ""
               function refresh() { reload() } }
    FileView { id: force; path: "/var/lib/latteos/force-safe"; printErrors: false; property bool there: false; onLoaded: there = true; onLoadFailed: there = false }
    readonly property var tiers: [{ id: "", name: QT_TR_NOOP("As the hardware says"), hint: "", icon: "sparkles" },
                                  { id: "full", name: QT_TR_NOOP("Everything"), hint: QT_TR_NOOP("blur, shadows, glow, a turning border"), icon: "flame" },
                                  { id: "standard", name: QT_TR_NOOP("Standard"), hint: QT_TR_NOOP("blur and shadows"), icon: "activity" },
                                  { id: "eco", name: QT_TR_NOOP("Thrifty"), hint: QT_TR_NOOP("no blur, quicker movement"), icon: "leaf" },
                                  { id: "minimal", name: QT_TR_NOOP("Bare"), hint: QT_TR_NOOP("nothing moves"), icon: "minus" }]
    readonly property var folderNames: ({ "DOCUMENTS": QT_TR_NOOP("Documents"), "DOWNLOAD": QT_TR_NOOP("Downloads"), "PICTURES": QT_TR_NOOP("Pictures"), "VIDEOS": QT_TR_NOOP("Videos"),
                                          "MUSIC": QT_TR_NOOP("Music"), "DESKTOP": QT_TR_NOOP("Desktop") })
    property bool emptying: false          // the trash is emptied on the second press: what was in it does not come back
    function bytes(b) { return b >= 1e9 ? Number(b / 1e9).toLocaleString(Qt.locale(), "f", 1) + " GB" : Math.round(b / 1e6) + " MB" }
    function account(what, value) { order(["busctl", "call", "org.freedesktop.Accounts", "/org/freedesktop/Accounts/User" + who.data.uid, "org.freedesktop.Accounts.User", what, "s", value]) }

    // ── the screens: a change is tried, and stays only when the user says the picture is fine ───────────
    Run { id: screens }
    property string screenAt: ""
    property var screenBefore: null
    property int screenWait: 0
    readonly property var screenList: (screens.data || []).slice().sort((a, b) => a.x - b.x)
    readonly property var screenHere: screenList.find(m => m.name === screenAt) || screenList[0] || null
    readonly property string screenMain: { const m = screenList.find(m => m.x === 0 && m.y === 0) || screenList[0]; return m ? m.name : "" }
    function wide(m) { return Math.round((m.transform % 2 ? m.height : m.width) / m.scale) }
    function tall(m) { return Math.round((m.transform % 2 ? m.width : m.height) / m.scale) }
    function asIs(m) { return { name: m.name, mode: m.width + "x" + m.height + "@" + m.refreshRate.toFixed(3), position: m.x + "x" + m.y, scale: m.scale, turn: m.transform } }
    // side by side in this order, the main one at 0,0
    function laid(list, main) {
        let x = 0
        const at = list.map(m => { const here = x; x += wide(m); return here })
        const zero = at[Math.max(0, list.findIndex(m => m.name === main))]
        return list.map((m, i) => Object.assign(asIs(m), { position: (at[i] - zero) + "x0" }))
    }
    // where they stand now, moved so that the main one is at 0,0
    function placed(list, main) {
        const z = list.find(m => m.name === main) || list[0]
        return list.map(m => Object.assign(asIs(m), { position: (m.x - z.x) + "x" + (m.y - z.y) }))
    }
    // The guide lines: the main screen's four edges drawn on, across every other screen, wherever they fall on it.
    // A screen moved until the main one's top and bottom (or, above or below it, its left and right) meet its own
    // picture where they meet on the desk: a window that spans the two is then at one height on both.
    property bool guideShown: false
    readonly property var screenMainOne: screenList.find(m => m.name === screenMain) || null
    readonly property var guides: screenMainOne ? { "top": screenMainOne.y, "bottom": screenMainOne.y + tall(screenMainOne),
                                                    "left": screenMainOne.x, "right": screenMainOne.x + wide(screenMainOne) } : null
    Variants { model: shell.guideShown && shell.page === "displays" && shell.guides ? Quickshell.screens.filter(s => s.name !== shell.screenMain) : []
        PanelWindow { id: lines; required property var modelData
            screen: modelData
            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "latte-guide"
            mask: Region {}                       // the pointer goes through it
            // each line on the main screen's side of its edge: the top is its first row, the bottom its last
            Rectangle { readonly property real at: shell.guides.top - lines.modelData.y
                visible: at >= 0 && at < parent.height; y: at; width: parent.width; height: 3; color: Theme.red }
            Rectangle { readonly property real at: shell.guides.bottom - lines.modelData.y
                visible: at > 0 && at <= parent.height; y: at - 3; width: parent.width; height: 3; color: Theme.red }
            Rectangle { readonly property real at: shell.guides.left - lines.modelData.x
                visible: at >= 0 && at < parent.width; x: at; width: 3; height: parent.height; color: Theme.red }
            Rectangle { readonly property real at: shell.guides.right - lines.modelData.x
                visible: at > 0 && at <= parent.width; x: at - 3; width: 3; height: parent.height; color: Theme.red } } }
    function overlap(a, b) { return a.x < b.x + wide(b) && a.x + wide(a) > b.x && a.y < b.y + tall(b) && a.y + tall(a) > b.y }
    function crowded(list) { return list.some((a, i) => list.some((b, j) => j > i && overlap(a, b))) }
    function putScreens(shapes, keep) {
        order(["hyprctl", "eval", shapes.map(s => "latte.screen(" + [JSON.stringify(s.name), JSON.stringify(s.mode), JSON.stringify(s.position), s.scale, s.turn, keep].join(", ") + ")").join(" ")])
        later.restart()
    }
    function tryScreens(shapes) {
        if (!screenBefore) screenBefore = screenList.map(asIs)
        putScreens(shapes, false); screenWait = 15
    }
    // a screen that grew into its neighbour puts them all side by side again
    function changeScreen(name, what) {
        const list = screenList.map(m => m.name === name ? Object.assign({}, m, what) : m)
        tryScreens(crowded(list) ? laid(list, screenMain) : placed(list, screenMain))
    }
    function keepScreens() { putScreens(screenList.map(asIs), true); screenBefore = null; screenWait = 0 }
    function screensBack() { if (screenBefore) putScreens(screenBefore, false); screenBefore = null; screenWait = 0 }
    Timer { interval: 1000; repeat: true; running: shell.screenWait > 0; onTriggered: if (--shell.screenWait <= 0) shell.screensBack() }
    function modes(m) {                    // [{w, h, rates: [Hz…]}], the largest first
        const found = []
        for (const said of m.availableModes) {
            const p = /^(\d+)x(\d+)@([\d.]+)Hz$/.exec(said); if (!p) continue
            const w = parseInt(p[1]), h = parseInt(p[2]), hz = parseFloat(p[3])
            let size = found.find(s => s.w === w && s.h === h)
            if (!size) { size = { w: w, h: h, rates: [] }; found.push(size) }
            if (size.rates.indexOf(hz) < 0) size.rates.push(hz)
        }
        found.forEach(s => s.rates.sort((a, b) => b - a))
        found.sort((a, b) => b.w * b.h - a.w * a.h)
        // the largest it names is the one it is made for; below it the usual sizes, down to LatteOS's least, as a
        // mode of its own where the screen does not name them (a virtual one names only one)
        const top = found[0]
        if (top) {
            top.best = true
            for (const [w, h] of usualSizes)
                if (w <= top.w && h <= top.h && !found.some(s => s.w === w && s.h === h)) found.push({ w: w, h: h, rates: [60] })
        }
        return found.sort((a, b) => b.w * b.h - a.w * a.h)
    }
    readonly property var usualSizes: [[3840, 2160], [3440, 1440], [2560, 1440], [2560, 1080], [1920, 1200], [1920, 1080], [1680, 1050],
                                       [1600, 900], [1440, 900], [1366, 768], [1280, 1024], [1280, 800], [1280, 720], [1024, 768]]
    function screenNumber(name) { return screenList.findIndex(m => m.name === name) + 1 }
    // Identify, as on Windows: each screen's number, large on the screen itself, for a few seconds
    property bool identifying: false
    Timer { running: shell.identifying; interval: 3000; onTriggered: shell.identifying = false }
    Variants { model: shell.identifying ? Quickshell.screens : []
        PanelWindow { id: ident; required property var modelData
            screen: modelData
            anchors { bottom: true; left: true }
            margins { left: 48; bottom: 120 }
            implicitWidth: 220; implicitHeight: 220; color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "latte-identify"
            mask: Region {}
            Rectangle { anchors.fill: parent; radius: 28; color: Theme.raised; border.width: 2; border.color: Theme.gold
                Label { anchors.centerIn: parent; anchors.verticalCenterOffset: -14; text: shell.screenNumber(ident.modelData.name) || "–"; font.pixelSize: 120; font.weight: 700 }
                Label { anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: 18; text: ident.modelData.name; color: Theme.dim; font.pixelSize: 14 } } } }
    Process { id: tell; onExited: shell.ask() }
    function order(args) { tell.running = false; tell.command = args; tell.running = true }
    Timer { interval: 2500; repeat: true; running: shell.page === "sound"; onTriggered: if (!tell.running) shell.ask() }
    property date now: new Date()
    Timer { interval: 1000; repeat: true; running: shell.page === "time"; triggeredOnStart: true; onTriggered: shell.now = new Date() }
    function localeName(id) { const l = region.data ? region.data.locales.find(x => x.id === id) : null; return l ? l.name + (l.place ? " · " + l.place : "") : id }
    function layoutName(id) { const l = keys.data ? keys.data.layouts.find(x => x.id === id) : null; return l ? l.name : id }
    readonly property var kindNames: ({ "browser": QT_TR_NOOP("Web browser"), "mail": QT_TR_NOOP("Mail"), "files": QT_TR_NOOP("Files and folders"), "images": QT_TR_NOOP("Pictures"),
                                        "video": QT_TR_NOOP("Video"), "music": QT_TR_NOOP("Music"), "text": QT_TR_NOOP("Text"), "pdf": "PDF" })
    readonly property var kindIcons: ({ "browser": "world", "mail": "file-text", "files": "folder", "images": "photo", "video": "player-play", "music": "music", "text": "file-text", "pdf": "file-text" })
    Run { id: coffees }
    Run { id: pictures }
    Run { id: machine }
    Process { id: pour; onExited: { Quickshell.execDetached(["latte-say", "emit coffee_changed"]); coffees.ask(["latte-login", "coffees"]) } }
    // how LatteOS is developed: from GitHub (the repository is public), else what the install wrote (bin/latte-activity)
    Process { id: activity; property var data: ({ days: {}, commits: [], total: 0 }); command: ["latte-activity", "show"]
              stdout: StdioCollector { onStreamFinished: { try { const d = JSON.parse(this.text); if (d.commits) activity.data = d } catch (e) {} } } }
    Process { id: activityFetch; command: ["latte-activity", "fetch"]; onExited: { activity.running = false; activity.running = true } }
    property string openCommit: ""
    property var commitFiles: ({})             // a commit's files, asked for when it is opened (GitHub's list has none)
    Process { id: filesq; property string hash: ""
              stdout: StdioCollector { onStreamFinished: { try { const f = Object.assign({}, shell.commitFiles); f[filesq.hash] = JSON.parse(this.text); shell.commitFiles = f } catch (e) {} } } }
    function openOne(c) {
        openCommit = openCommit === c.hash ? "" : c.hash
        if (openCommit !== "" && !c.files && !commitFiles[c.hash]) { filesq.hash = c.hash; filesq.command = ["latte-activity", "files", c.hash]; filesq.running = true }
    }
    FileView { id: release; path: "/etc/os-release"; printErrors: false; property string pretty: ""
               onLoaded: pretty = (text().match(/^PRETTY_NAME="?([^"\n]*)/m) || ["", ""])[1] }
    onPageChanged: {
        if (page === "coffee") { coffees.ask(["latte-login", "coffees"]); iconsets.ask(["latte-settings", "icons"]) }
        if (page === "background") { pictures.ask(["latte-settings", "wallpapers"]); wall.ask(["latte-wall", "state"]) }
        if (page === "about") { machine.ask(["latte-devices", "list"]); activity.running = true; activityFetch.running = true }
        emptying = false
        if (page === "power") profiles.running = true
        ask()
    }
    readonly property var coffeeNames: ({ "espresso": "Espresso", "ristretto": "Ristretto", "lungo": "Lungo", "americano": "Americano", "macchiato": "Macchiato", "cortado": "Cortado",
                                          "flatwhite": "Flat white", "cappuccino": "Cappuccino", "latte": "Latte", "white-coffee": QT_TR_NOOP("White coffee") })
    // the colour the goo has with that much water and milk in it, as the scene mixes it
    function mixed(a, b, t) { return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1) }
    function brew(water, milk) { return mixed(mixed(Qt.color("#1c0f09"), Qt.color("#4a2410"), water), Qt.color("#c9a47a"), milk * milk) }

    // ── what pages are built of ───────────────────────────────────────────────────────────────────────────
    component Part: Column {                   // a part of a page: a heading, a word about it, and what is set
        property string title
        property string note
        property bool expertOnly: false        // shown in the expert mode only: marked so
        default property alias content: inside.data
        spacing: 10
        Row { spacing: 8
            Label { text: title; font.pixelSize: 18; font.weight: 700 }
            Rectangle { visible: expertOnly; height: 20; radius: 6; width: expTag.implicitWidth + 12; anchors.verticalCenter: parent.verticalCenter; color: Qt.rgba(Theme.gold.r, Theme.gold.g, Theme.gold.b, 0.18)
                Label { id: expTag; anchors.centerIn: parent; text: I18n.tr("Expert"); color: Theme.gold; font.pixelSize: 11; font.weight: 800 } } }
        Label { text: note; visible: text !== ""; color: Theme.dim; font.pixelSize: 13; width: parent.width; wrapMode: Text.WordWrap }
        Item { width: 1; height: 2 }
        Flow { id: inside; width: parent.width; spacing: 14 }
    }
    component Choice: Rectangle {              // one of several, with a picture of itself
        id: choice
        property string text
        property string hint
        property bool on: false
        default property alias picture: face.data
        signal pressed()
        width: 150; height: 150; radius: 20; color: Theme.card
        border.width: 2; border.color: on ? Theme.gold : (hit.containsMouse ? Theme.line : "transparent")
        scale: hit.pressed ? 0.97 : 1
        Behavior on scale { NumberAnimation { duration: 90 } }
        Item { id: face; x: 14; y: 14; width: parent.width - 28; height: parent.height - 66 }
        Label { x: 14; y: parent.height - 46; width: parent.width - 28; text: choice.text; font.weight: 700 }
        Label { x: 14; y: parent.height - 26; width: parent.width - 28; text: choice.hint; color: Theme.dim; font.pixelSize: 11 }
        Rectangle { visible: choice.on; width: 22; height: 22; radius: 11; color: Theme.gold; x: parent.width - 30; y: 8; Glyph { anchors.centerIn: parent; name: "check"; font.pixelSize: 13; color: Theme.inkOnGold } }
        MouseArea { id: hit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: choice.pressed() }
    }
    component Switch: Rectangle {              // yes or no, with what it is about beside it
        id: sw
        property string text
        property string hint
        property bool on: false
        signal pressed()
        width: parent.width; height: 64; radius: 16; color: Theme.card
        Column { x: 18; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 100; spacing: 3
            Label { text: sw.text; font.weight: 600; width: parent.width }
            Label { text: sw.hint; color: Theme.dim; font.pixelSize: 12; width: parent.width; visible: text !== "" } }
        Rectangle { width: 46; height: 26; radius: 13; color: sw.on ? Theme.gold : Theme.raised; anchors.right: parent.right; anchors.rightMargin: 18; anchors.verticalCenter: parent.verticalCenter
            Behavior on color { ColorAnimation { duration: 140 } }
            Rectangle { width: 20; height: 20; radius: 10; y: 3; x: sw.on ? 23 : 3; color: sw.on ? Theme.inkOnGold : Theme.dim; Behavior on x { NumberAnimation { duration: 140 } } } }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: sw.pressed() }
    }
    component Dot: Rectangle { property string status; width: 9; height: 9; radius: 5; color: status === "ready" ? Theme.gold : "transparent"; border.width: 1.5; border.color: status === "ready" ? Theme.gold : Theme.faint }
    component PageLine: Rectangle {            // a page, as the search and the front page list it
        id: pl
        property var what
        width: parent.width; height: 58; radius: 16; color: plHit.containsMouse ? Theme.raised : Theme.card
        Glyph { x: 18; name: pl.what.icon; font.pixelSize: 22; color: Theme.gold; anchors.verticalCenter: parent.verticalCenter }
        Column { x: 56; anchors.verticalCenter: parent.verticalCenter; spacing: 2
            Label { text: I18n.tr(pl.what.name); font.weight: 600 }
            Label { text: I18n.tr(pl.what.area.name); color: Theme.dim; font.pixelSize: 12 } }
        Dot { status: pl.what.status; anchors.right: parent.right; anchors.rightMargin: 20; anchors.verticalCenter: parent.verticalCenter }
        MouseArea { id: plHit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: shell.go(pl.what.id) }
    }

    AppWindow {
        id: win
        title: I18n.tr("Settings")
        heading: shell.asked !== "" ? I18n.tr("Results for “{what}”", { what: shell.asked }) : (shell.here ? I18n.tr(shell.here.name) : I18n.tr("Settings"))
        implicitWidth: 1200; implicitHeight: 780
        sideWidth: 270
        arrows: true; canGoBack: shell.page !== "" || shell.asked !== ""; onBack: { if (shell.asked !== "") { shell.asked = ""; searchText = "" } else shell.page = "" }
        searchHint: I18n.tr("Search settings…")
        onSearchTextChanged: shell.asked = searchText.trim()

        // ── the side: areas that unfold into their pages ──────────────────────────────────────────────────
        // the foot, as the sketch has it: what the system is, and the switch between the basic and the expert mode
        foot: [
            Label { x: 24; anchors.verticalCenter: parent.verticalCenter; color: "#e0c9b1"; font.pixelSize: 12; width: parent.width - 330; elide: Text.ElideRight
                    text: [release.pretty, "LatteOS GOO", Quickshell.env("LATTE_TIER") || ""].filter(x => x).join("  ·  ") },
            Rectangle { anchors.right: parent.right; anchors.rightMargin: 20; anchors.verticalCenter: parent.verticalCenter; height: 36; radius: 18; width: expRow.implicitWidth + 28
                color: shell.expert ? Theme.gold : Qt.rgba(0, 0, 0, 0.25); border.width: 1; border.color: Theme.gold
                Row { id: expRow; anchors.centerIn: parent; spacing: 10
                    Glyph { name: "tools"; font.pixelSize: 16; color: shell.expert ? Theme.inkOnGold : Theme.gold; anchors.verticalCenter: parent.verticalCenter }
                    Label { text: shell.expert ? I18n.tr("Expert mode is on") : I18n.tr("Switch to the expert mode"); color: shell.expert ? Theme.inkOnGold : Theme.inkOnCoffee; font.weight: 700; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
                    Rectangle { width: 36; height: 20; radius: 10; color: shell.expert ? Theme.inkOnGold : Qt.rgba(1, 1, 1, 0.2); anchors.verticalCenter: parent.verticalCenter
                        Rectangle { width: 14; height: 14; radius: 7; y: 3; x: shell.expert ? 19 : 3; color: shell.expert ? Theme.gold : "#ffffff"; Behavior on x { NumberAnimation { duration: 140 } } } } }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: shell.setExpert(!shell.expert) } }
        ]
        side: [
            // the account, at the foot of the side as the overview's sketch has it (inspo/latteOS settings priklad.png)
            Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: 14; height: 58; radius: 14
                color: meHit.containsMouse ? Theme.raised : Theme.card; border.width: 1; border.color: Theme.line
                ClippingRectangle { x: 10; width: 38; height: 38; radius: 19; anchors.verticalCenter: parent.verticalCenter; color: Theme.gold
                    Label { anchors.centerIn: parent; text: who.data ? (who.data.name || who.data.user || "?").charAt(0).toUpperCase() : ""; color: Theme.inkOnGold; font.weight: 800; font.pixelSize: 16 }
                    Image { anchors.fill: parent; fillMode: Image.PreserveAspectCrop; sourceSize.width: 76; cache: false; source: who.data && who.data.picture ? "file://" + who.data.picture : ""; visible: status === Image.Ready } }
                Column { x: 58; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 70; spacing: 1
                    Label { text: who.data ? (who.data.name || who.data.user) : ""; font.weight: 700; width: parent.width; elide: Text.ElideRight }
                    Label { text: who.data ? who.data.user + "@" + (machine.data ? machine.data.computer.host : "") : ""; color: Theme.dim; font.pixelSize: 11; width: parent.width; elide: Text.ElideRight } }
                MouseArea { id: meHit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: shell.go("me") } },
            Flickable { anchors.fill: parent; anchors.bottomMargin: 80; contentHeight: menu.height + 28; clip: true; boundsBehavior: Flickable.StopAtBounds
                Column { id: menu; x: 14; y: 14; spacing: 4; width: parent.width - 28
                    Row { x: 6; spacing: 10; height: 40
                        Glyph { name: "settings"; font.pixelSize: 24; color: Theme.gold; anchors.verticalCenter: parent.verticalCenter }
                        Label { text: I18n.tr("Settings"); font.pixelSize: 17; font.weight: 700; anchors.verticalCenter: parent.verticalCenter } }
                    Item { width: 1; height: 8 }
                    Nav { width: parent.width; text: I18n.tr("Home"); icon: "home-2"; on: shell.page === "" && shell.asked === ""; onPressed: { shell.page = ""; shell.asked = ""; win.searchText = "" } }
                    Repeater { model: shell.areas
                        Column { id: area; required property var modelData; width: parent.width; spacing: 2
                            readonly property bool open: shell.unfolded === modelData.id
                            Rectangle { width: parent.width; height: 40; radius: 12; color: areaHit.containsMouse ? Theme.card : "transparent"
                                Glyph { x: 14; name: area.modelData.icon; color: area.open ? Theme.gold : Theme.dim; anchors.verticalCenter: parent.verticalCenter }
                                Label { x: 44; text: I18n.tr(area.modelData.name).toUpperCase(); font.pixelSize: 12; font.weight: 700; font.letterSpacing: 0.6; color: area.open ? Theme.cream : Theme.dim; anchors.verticalCenter: parent.verticalCenter }
                                Glyph { name: "chevron-right"; font.pixelSize: 15; color: Theme.faint; anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter
                                        rotation: area.open ? 90 : 0; Behavior on rotation { NumberAnimation { duration: 160 } } }
                                MouseArea { id: areaHit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: shell.unfolded = area.open ? "" : area.modelData.id } }
                            Column { width: parent.width; spacing: 1; clip: true
                                height: area.open ? implicitHeight : 0; Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                Repeater { model: area.modelData.pages
                                    Rectangle { id: line; required property var modelData; width: parent.width; radius: 10
                                        // a page under another (Drops › Launcher) hangs below it, a step in, while that one or its own are open
                                        readonly property bool sub: modelData.under !== undefined
                                        visible: !sub || shell.page === modelData.under || (shell.here !== null && shell.here.under === modelData.under)
                                        height: sub ? 30 : 34
                                        readonly property bool on: shell.page === modelData.id && shell.asked === ""
                                        color: on ? Theme.raised : (lineHit.containsMouse ? Theme.card : "transparent")
                                        Rectangle { width: 3; height: 16; radius: 2; color: Theme.gold; visible: line.on; anchors.verticalCenter: parent.verticalCenter }
                                        Label { x: line.sub ? 62 : 44; width: parent.width - 70 - (line.sub ? 18 : 0); text: I18n.tr(line.modelData.name); font.pixelSize: line.sub ? 12 : 13; color: line.on ? Theme.cream : Theme.dim; anchors.verticalCenter: parent.verticalCenter }
                                        Dot { status: line.modelData.status; anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter }
                                        Glyph { visible: !!line.modelData.expert; name: "tools"; font.pixelSize: 12; color: Theme.gold; anchors.right: parent.right; anchors.rightMargin: 28; anchors.verticalCenter: parent.verticalCenter }
                                        MouseArea { id: lineHit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: shell.go(line.modelData.id) } } } } } } } }
        ]

        // ── what was searched for ─────────────────────────────────────────────────────────────────────────
        Scroll {
            id: results
            visible: shell.asked !== ""
            Label { visible: shell.found.length === 0; text: I18n.tr("Nothing found"); color: Theme.dim; topPadding: 60 }
            Column { width: results.room; spacing: 8
                Repeater { model: shell.found; PageLine { required property var modelData; what: modelData } } }
        }

        // ── the front page: the system at a glance and what is set most (inspo/latteOS settings priklad.png, 20. 10.;
        // the sketch is narrow, the window is not: two columns where there is room) ─────────────────────────────
        Scroll {
            id: front
            visible: shell.asked === "" && shell.page === ""
            readonly property bool two: room >= 900
            readonly property real col: two ? (room - 18) / 2 : room
            readonly property var pc: machine.data ? machine.data.computer : ({})
            readonly property var main: shell.screenList.find(m => m.name === shell.screenMain) || shell.screenList[0] || null
            readonly property var root: disks.data ? (disks.data.disks.find(d => d.mount === "/") || disks.data.disks[0]) : null
            component Card: Rectangle {
                property string title; property string note; property string icon
                default property alias content: cardBody.data
                width: front.col; height: cardBody.y + cardBody.implicitHeight + 20; radius: 20; color: Theme.card; border.width: 1; border.color: Theme.line
                Rectangle { x: 18; y: 18; width: 40; height: 40; radius: 12; color: Qt.rgba(Theme.gold.r, Theme.gold.g, Theme.gold.b, 0.14)
                    Glyph { anchors.centerIn: parent; name: parent.parent.icon; font.pixelSize: 21; color: Theme.gold } }
                Label { x: 70; y: 18; text: parent.title; font.pixelSize: 17; font.weight: 800; width: parent.width - 88; elide: Text.ElideRight }
                Label { x: 70; y: 42; text: parent.note; color: Theme.dim; font.pixelSize: 12; width: parent.width - 88; wrapMode: Text.WordWrap; visible: text !== "" }
                Column { id: cardBody; x: 18; y: 76 + (parent.note.length > 70 ? 14 : 0); width: parent.width - 36; spacing: 10 }
            }
            component Stat: Rectangle { property string head; property string big; property string small; width: (front.col - 36 - 20) / 3; height: 84; radius: 14; color: Theme.raised
                Column { x: 12; y: 10; width: parent.width - 24; spacing: 3
                    Label { text: parent.parent.head.toUpperCase(); color: Theme.faint; font.pixelSize: 10; font.weight: 700; font.letterSpacing: 0.6 }
                    Label { text: parent.parent.big; font.pixelSize: 17; font.weight: 800; width: parent.width; elide: Text.ElideRight }
                    Label { text: parent.parent.small; color: Theme.gold; font.pixelSize: 11; font.weight: 600; width: parent.width; elide: Text.ElideRight } } }

            // the head: where one is, and the system's own name for this page
            Item { width: front.room; height: 64
                Column { spacing: 2
                    Label { text: I18n.tr("Settings") + "  ›  " + I18n.tr("Overview"); color: Theme.gold; font.pixelSize: 12; font.weight: 700 }
                    Label { text: I18n.tr("System and overview"); font.pixelSize: 30; font.weight: 800 } }
                Pill { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; implicitHeight: 38; icon: "refresh"; text: I18n.tr("Check for updates"); onPressed: shell.go("updates") } }

            Flow { width: front.room; spacing: 18
                Column { width: front.col; spacing: 18
                    // this computer: a card of its own, as the sketch's
                    Rectangle { width: front.col; height: 200; radius: 22; border.width: 1; border.color: Theme.line
                        gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: Theme.raised } GradientStop { position: 1; color: Theme.card } }
                        Rectangle { x: 22; y: 24; width: 64; height: 64; radius: 16; color: Theme.ground; Glyph { anchors.centerIn: parent; name: "device-desktop"; font.pixelSize: 32; color: Theme.gold } }
                        Column { x: 104; y: 22; width: parent.width - 124; spacing: 6
                            Label { text: front.pc.model || front.pc.host || "LatteOS"; font.pixelSize: 22; font.weight: 800; width: parent.width; wrapMode: Text.WordWrap; maximumLineCount: 2 }
                            Rectangle { height: 22; radius: 11; width: profText.implicitWidth + 18; color: Qt.rgba(Theme.gold.r, Theme.gold.g, Theme.gold.b, 0.18)
                                Label { id: profText; anchors.centerIn: parent; text: "● " + I18n.tr("LatteOS GOO") + "  ·  " + (Quickshell.env("LATTE_TIER") || "standard"); color: Theme.gold; font.pixelSize: 11; font.weight: 800 } }
                            Label { width: parent.width; color: Theme.dim; font.pixelSize: 13; wrapMode: Text.WordWrap
                                    text: [front.pc.cpu ? front.pc.cpu + (front.pc.threads ? " (" + I18n.tr("{n} threads", { n: front.pc.threads }) + ")" : "") : "", front.pc.ram_gb ? front.pc.ram_gb + " GB RAM" : "",
                                           release.pretty, front.pc.kernel ? "Linux " + front.pc.kernel : ""].filter(x => x).join("  ·  ") } }
                        Pill { anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: 14; implicitHeight: 30; icon: "cpu"; text: I18n.tr("About this computer"); onPressed: shell.go("about") } }
                    // the look: dark, light, or from the wallpaper, each as a little window of itself
                    Card { title: I18n.tr("Interface mode"); note: I18n.tr("The colours of the windows and of the desktop."); icon: "moon"
                        Row { spacing: 10
                            Repeater { model: [{ id: "espresso", name: QT_TR_NOOP("Espresso"), hint: QT_TR_NOOP("dark"), ground: "#17110d", pill: "#2a1e17", dot: "#f7c873" },
                                               { id: "porcelain", name: QT_TR_NOOP("Porcelain"), hint: QT_TR_NOOP("light"), ground: "#f5eee2", pill: "#fffaf1", dot: "#b5651d" },
                                               { id: "wallpaper", name: QT_TR_NOOP("From the wallpaper"), hint: QT_TR_NOOP("its colours"), ground: "#3a2a20", pill: "#c98a55", dot: "#f3ebdd" }]
                                Rectangle { id: mode; required property var modelData; width: (front.col - 36 - 20) / 3; height: 118; radius: 14
                                    readonly property bool on: Theme.cup === modelData.id
                                    color: on ? Theme.raised : "transparent"; border.width: on ? 2 : 1; border.color: on ? Theme.gold : Theme.line
                                    Label { x: 12; y: 10; text: I18n.tr(mode.modelData.name); font.weight: 700; font.pixelSize: 13 }
                                    Glyph { visible: mode.on; anchors.right: parent.right; anchors.rightMargin: 10; y: 10; name: "circle-check"; font.pixelSize: 16; color: Theme.gold }
                                    Rectangle { x: 12; y: 38; width: parent.width - 24; height: 34; radius: 17; color: mode.modelData.ground; border.width: 1; border.color: Theme.line
                                        Rectangle { x: 6; width: parent.width * 0.5; height: 22; radius: 11; anchors.verticalCenter: parent.verticalCenter; color: mode.modelData.pill
                                            Rectangle { x: 6; width: 10; height: 10; radius: 5; anchors.verticalCenter: parent.verticalCenter; color: mode.modelData.dot } } }
                                    Label { x: 12; y: 84; text: I18n.tr(mode.modelData.hint); color: Theme.dim; font.pixelSize: 11 }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                                onClicked: { cup.choose(mode.modelData.id); Theme.cup = mode.modelData.id; Quickshell.execDetached(["hyprctl", "eval", "latte.cup(\"" + mode.modelData.id + "\")"]) } } } } } }
                    // how much is glass: one choice for all of LatteOS, as a slider of its five steps, True Glass the last
                    Card { title: I18n.tr("Glass"); note: I18n.tr("How much of LatteOS is glass: the side panels, the windows and the AI's pages."); icon: "droplet"
                        Item { width: parent.width; height: 44
                            Glyph { x: 0; anchors.verticalCenter: parent.verticalCenter; name: "circle"; color: Theme.dim; font.pixelSize: 16 }
                            Item { id: track; x: 30; width: parent.width - 130; height: 44
                                Rectangle { y: 19; width: parent.width; height: 6; radius: 3; color: Theme.raised }
                                Rectangle { y: 19; width: parent.width * Theme.glassLevel / 4; height: 6; radius: 3; color: Theme.gold }
                                Repeater { model: 5
                                    Rectangle { required property int index; x: track.width * index / 4 - width / 2; y: index === Theme.glassLevel ? 12 : 17; width: index === Theme.glassLevel ? 20 : 10; height: width; radius: width / 2
                                                color: index <= Theme.glassLevel ? Theme.gold : Theme.raised; border.width: index === Theme.glassLevel ? 3 : 0; border.color: Theme.ground } }
                                MouseArea { anchors.fill: parent; anchors.margins: -10; cursorShape: Qt.PointingHandCursor
                                    function put(x) { const n = Math.max(0, Math.min(4, Math.round(4 * x / track.width))); if (n !== Theme.glassLevel) { glassLevel.choose(String(n)); Theme.glassLevel = n; goo.set("glass", n) } }
                                    onPressed: m => put(m.x - 10); onPositionChanged: m => { if (pressed) put(m.x - 10) } } }
                            Glyph { x: parent.width - 92; anchors.verticalCenter: parent.verticalCenter; name: "droplet"; color: Theme.gold; font.pixelSize: 16 }
                            Rectangle { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; height: 26; radius: 13; width: 64; color: Qt.rgba(Theme.gold.r, Theme.gold.g, Theme.gold.b, 0.16)
                                Label { anchors.centerIn: parent; text: Theme.glassLevel === 4 ? "True" : Math.round(Theme.glassLevel * 100 / 3) + " %"; color: Theme.gold; font.weight: 800; font.pixelSize: 12 } } }
                        Label { text: I18n.tr([QT_TR_NOOP("None: everything is solid."), QT_TR_NOOP("A little"), QT_TR_NOOP("More"), QT_TR_NOOP("The most"), QT_TR_NOOP("True Glass: the windows are clear glass that bends the light; what is written keeps a plate under it.")][Theme.glassLevel]); color: Theme.dim; font.pixelSize: 12; width: parent.width; wrapMode: Text.WordWrap } }
                }
                Column { width: front.col; spacing: 18
                    // the coffee on the edge of the screen: lively, and of glass
                    Card { title: I18n.tr("The coffee and how it moves"); note: I18n.tr("The drops on the edge of the screen: what they are made of and whether they live."); icon: "coffee"
                        Switch { text: I18n.tr("Lively"); hint: I18n.tr("Left alone they fall asleep, the weather outside shows on the surface, playful ones play."); on: goo.kept.lively !== false; onPressed: goo.set("lively", !on) }
                        Switch { text: I18n.tr("Coffee in glass"); hint: I18n.tr("The drops are glass with coffee in it. With the graphics card drawing by the processor they stay plain coffee.")
                                 on: goo.kept.material === "glass" || Number(goo.kept.material) > 0.5; onPressed: goo.set("material", on ? 0 : 1) } }
                    // the screens: the main one's picture, how often it is drawn, how big things are
                    Card { title: I18n.tr("Displays"); note: front.main ? front.main.name + (front.main.description ? "  ·  " + front.main.description : "") : ""; icon: "device-desktop"
                        Row { spacing: 10
                            Stat { head: I18n.tr("Resolution"); big: front.main ? front.main.width + " × " + front.main.height : "—"; small: front.main ? (front.main.width / front.main.height >= 2.3 ? "21:9" : front.main.width / front.main.height >= 1.7 ? "16:9" : "") : "" }
                            Stat { head: I18n.tr("Refresh rate"); big: front.main ? Math.round(front.main.refreshRate) + " Hz" : "—"; small: front.main && front.main.vrr ? "VRR" : "" }
                            Stat { head: I18n.tr("Scale"); big: front.main ? Math.round(front.main.scale * 100) + " %" : "—"; small: I18n.tr("{n} screens", { n: shell.screenList.length }) } }
                        Pill { implicitHeight: 30; icon: "adjustments-horizontal"; text: I18n.tr("Displays"); onPressed: shell.go("displays") } }
                    // the disks: how full, and where to make room
                    Card { title: I18n.tr("Storage"); note: front.root ? I18n.tr("{free} free of {size}", { free: shell.bytes(front.root.size - front.root.used), size: shell.bytes(front.root.size) }) : ""; icon: "disc"
                        Repeater { model: disks.data ? disks.data.disks : []
                            Column { required property var modelData; width: parent.width; spacing: 5
                                readonly property real full: modelData.size > 0 ? modelData.used / modelData.size : 0
                                Row { width: parent.width
                                    Label { text: parent.parent.modelData.mount === "/" ? I18n.tr("This computer") : parent.parent.modelData.mount; font.weight: 700; font.pixelSize: 13; width: parent.width - pct.implicitWidth }
                                    Label { id: pct; text: Math.round(parent.parent.full * 100) + " %"; color: parent.parent.full > 0.9 ? Theme.red : Theme.dim; font.pixelSize: 12; font.weight: 700 } }
                                Rectangle { width: parent.width; height: 10; radius: 5; color: Theme.raised
                                    Rectangle { width: parent.width * parent.parent.full; height: 10; radius: 5; color: parent.parent.full > 0.9 ? Theme.red : Theme.gold } } } }
                        Row { spacing: 8
                            Pill { implicitHeight: 30; icon: "folder"; text: I18n.tr("Storage"); onPressed: shell.go("storage") }
                            Pill { implicitHeight: 30; icon: "disc"; text: I18n.tr("Manage partitions"); onPressed: Quickshell.execDetached(["latte-app", "files", "disks"]) } } }
                }
            }
            // every part of the settings, as before: a tile each
            Label { text: I18n.tr("ALL SETTINGS"); color: Theme.faint; font.pixelSize: 11; font.weight: 700; font.letterSpacing: 0.8 }
            Flow { width: front.room; spacing: 14
                Repeater { model: shell.areas
                    Rectangle { id: tile; required property var modelData
                        readonly property int each: Math.max(1, Math.floor(front.room / 260))
                        width: Math.floor((front.room - 14 * (each - 1)) / each); height: 110; radius: 20; color: tileHit.containsMouse ? Theme.raised : Theme.card
                        Behavior on color { ColorAnimation { duration: 140 } }
                        Rectangle { x: 18; y: 18; width: 44; height: 44; radius: 14; color: Theme.ground; Glyph { anchors.centerIn: parent; name: tile.modelData.icon; font.pixelSize: 24; color: Theme.gold } }
                        Label { x: 76; y: 18; text: I18n.tr(tile.modelData.name); font.pixelSize: 17; font.weight: 700 }
                        Label { x: 76; y: 42; width: parent.width - 92; color: Theme.dim; font.pixelSize: 12; wrapMode: Text.WordWrap; maximumLineCount: 3
                                text: tile.modelData.pages.map(p => I18n.tr(p.name)).join(" · ") }
                        MouseArea { id: tileHit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: { shell.unfolded = tile.modelData.id; shell.go((tile.modelData.pages.find(p => p.status === "ready") || tile.modelData.pages[0]).id) } } } } }
        }

        // ── a page ────────────────────────────────────────────────────────────────────────────────────────
        Scroll {
            id: view
            visible: shell.asked === "" && shell.here !== null

            // coffee and cup: what the goo is made of, and what the windows are
            Part { visible: shell.page === "coffee"; width: view.room; title: I18n.tr("What coffee would you like?"); note: I18n.tr("The coffee is what the drops on the edge of the screen are made of: more water makes it clearer, more milk lighter.")
                Repeater { model: coffees.data ? coffees.data.all : []
                    Choice { id: kind; required property var modelData; width: 132; height: 142
                        text: I18n.tr(shell.coffeeNames[modelData[0]] || modelData[0]); on: coffees.data.chosen === modelData[0] || (coffees.data.chosen === "" && modelData[0] === "espresso")
                        onPressed: { pour.running = false; pour.command = ["latte-login", "coffee", modelData[0]]; pour.running = true }
                        // a cup seen from above
                        Rectangle { anchors.centerIn: parent; width: 70; height: 70; radius: 35; color: Theme.light ? "#fffaf1" : "#e9dcc8"
                            Rectangle { anchors.centerIn: parent; width: 56; height: 56; radius: 28; color: shell.brew(kind.modelData[1], kind.modelData[2]) } } } } }
            Part { visible: shell.page === "coffee"; width: view.room; title: I18n.tr("And in what cup?"); note: I18n.tr("The cup is what the windows are made of.")
                Repeater { model: [{ id: "espresso", name: QT_TR_NOOP("Espresso cup"), hint: QT_TR_NOOP("dark") }, { id: "mocha", name: QT_TR_NOOP("Mocha cup"), hint: QT_TR_NOOP("warm brown") },
                                   { id: "porcelain", name: QT_TR_NOOP("Porcelain"), hint: QT_TR_NOOP("light") }]
                           .concat(Theme.fromWallpaper ? [{ id: "wallpaper", name: QT_TR_NOOP("From the wallpaper"), hint: QT_TR_NOOP("its colours, each time it changes") }] : [])
                    Choice { required property var modelData; width: 190; text: I18n.tr(modelData.name); hint: I18n.tr(modelData.hint); on: Theme.cup === modelData.id; onPressed: { cup.choose(modelData.id); Theme.cup = modelData.id; Quickshell.execDetached(["hyprctl", "eval", "latte.cup(\"" + modelData.id + "\")"]) }
                        // a small window made of that cup
                        Rectangle { anchors.fill: parent; radius: 10; color: shell.cupOf(parent.parent.modelData.id).ground; border.width: 1; border.color: shell.cupOf(parent.parent.modelData.id).line
                            Rectangle { width: parent.width * 0.3; height: parent.height; radius: 10; color: shell.cupOf(parent.parent.parent.modelData.id).surface }
                            Rectangle { x: parent.width * 0.38; y: 12; width: parent.width * 0.5; height: 8; radius: 4; color: shell.cupOf(parent.parent.parent.modelData.id).cream }
                            Rectangle { x: parent.width * 0.38; y: 28; width: parent.width * 0.36; height: 6; radius: 3; color: shell.cupOf(parent.parent.parent.modelData.id).dim }
                            Rectangle { x: parent.width * 0.38; y: 46; width: 40; height: 16; radius: 8; color: shell.cupOf(parent.parent.parent.modelData.id).gold } } } } }
            Part { visible: shell.page === "coffee"; width: view.room; title: I18n.tr("Icons"); note: I18n.tr("What files, folders and apps are shown with: on the desktop, in LatteOS's apps and in apps that follow the system.")
                Repeater { model: iconsets.data ? iconsets.data.sets : []
                    Choice { id: set; required property var modelData; width: 200; text: modelData.name; on: iconsets.data.chosen === modelData.id
                             onPressed: { tell.running = false; tell.command = ["latte-settings", "icons", modelData.id]; tell.running = true }
                             Row { anchors.centerIn: parent; spacing: 6
                                   Repeater { model: [set.modelData.folder, set.modelData.file, set.modelData.trash]
                                              Image { required property string modelData; width: 48; height: 48; source: modelData === "" ? "" : "file://" + modelData; sourceSize.width: 96; sourceSize.height: 96; asynchronous: true } } } } } }
            Part { visible: shell.page === "coffee"; width: view.room; title: I18n.tr("Glass")
                Switch { text: I18n.tr("Coffee in glass"); hint: I18n.tr("The drops are glass with coffee in it. With the graphics card drawing by the processor they stay plain coffee.")
                         on: goo.kept.material === "glass" || Number(goo.kept.material) > 0.5; onPressed: goo.set("material", on ? 0 : 1) }
                Switch { text: I18n.tr("Windows of glass"); hint: I18n.tr("The windows are glass too, where the graphics card can: that is the cup's own look, apart from the drops.")
                         on: goo.kept.windows === "glass"; onPressed: goo.set("windows", on ? "solid" : "glass") } }

            // The background, as Windows lays it out and a little further: the screens on top (press one to choose
            // for it alone), then where the picture comes from, then the choice itself. bin/latte-wall does it.
            Item { visible: shell.page === "background"; width: view.room; height: 250
                readonly property var list: shell.bg ? shell.bg.screens : []
                readonly property real x0: list.length ? Math.min(...list.map(m => m.x)) : 0
                readonly property real y0: list.length ? Math.min(...list.map(m => m.y)) : 0
                readonly property real wide: list.length ? Math.max(...list.map(m => m.x + m.w)) - x0 : 1920
                readonly property real high: list.length ? Math.max(...list.map(m => m.y + m.h)) - y0 : 1080
                readonly property real k: Math.min(Math.min(view.room, 900) / wide, 230 / high)
                id: stage
                Repeater { model: stage.list
                    ClippingRectangle { id: scr; required property var modelData
                        readonly property string file: shell.bg ? (shell.bg.shown[modelData.name] || shell.bg.shown["*"] || "") : ""
                        readonly property bool film: /\.(mp4|webm|mkv|mov)$/i.test(file)
                        x: (modelData.x - stage.x0) * stage.k; y: (modelData.y - stage.y0) * stage.k; width: modelData.w * stage.k - 8; height: modelData.h * stage.k - 8
                        radius: 14; color: Theme.card; border.width: 3
                        border.color: shell.bgTarget === "*" || shell.bgTarget === modelData.name ? Theme.gold : Theme.line
                        Image { anchors.fill: parent; anchors.margins: 3; visible: !scr.film; source: scr.film || scr.file === "" ? "" : "file://" + scr.file; fillMode: Image.PreserveAspectCrop; asynchronous: true; sourceSize.width: 960; cache: false }
                        Glyph { anchors.centerIn: parent; visible: scr.film; name: "player-play"; font.pixelSize: 44; color: Theme.gold }
                        Rectangle { x: 10; y: 10; width: tag.implicitWidth + 16; height: 24; radius: 12; color: Qt.rgba(0, 0, 0, 0.55)
                                    Label { id: tag; anchors.centerIn: parent; text: scr.modelData.name; color: "white"; font.pixelSize: 12; font.weight: 700 } }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: shell.bgTarget = scr.modelData.name } } } }
            Row { visible: shell.page === "background"; spacing: 10
                Pill { icon: "copy"; text: I18n.tr("The same on every screen"); strong: shell.bgTarget === "*"; onPressed: shell.bgTarget = "*" }
                Repeater { model: shell.bg && shell.bg.screens.length > 1 ? shell.bg.screens : []
                    Pill { required property var modelData; icon: "device-desktop"; text: I18n.tr("Only {screen}", { screen: modelData.name }); strong: shell.bgTarget === modelData.name; onPressed: shell.bgTarget = modelData.name } } }
            Part { visible: shell.page === "background"; width: view.room; title: I18n.tr("Background")
                   note: shell.bgTarget === "*" ? I18n.tr("What you choose goes on every screen.") : I18n.tr("What you choose goes on {screen} only; the others keep theirs.", { screen: shell.bgTarget })
                Repeater { model: [{ id: "picture", name: QT_TR_NOOP("Picture"), icon: "photo" }, { id: "color", name: QT_TR_NOOP("Solid colour"), icon: "palette" },
                                   { id: "slideshow", name: QT_TR_NOOP("Slideshow"), icon: "folder" }, { id: "motionbgs", name: "MotionBGS", icon: "player-play" },
                                   { id: "wallhaven", name: "Wallhaven", icon: "world" }, { id: "bing", name: "Bing", icon: "world" },
                                   { id: "skwd", name: "skwd-wall", icon: "sparkles" }, { id: "lens", name: QT_TR_NOOP("Describe it"), icon: "search" }]
                    Pill { required property var modelData; icon: modelData.icon; text: I18n.tr(modelData.name); strong: shell.bgSource === modelData.id
                           onPressed: { shell.bgSource = modelData.id
                                        if (["motionbgs", "wallhaven", "bing"].includes(modelData.id)) { online.data = null; online.ask(["latte-walls", modelData.id]) } } } } }

            // a picture or a film of the user's own
            Part { visible: shell.page === "background" && shell.bgSource === "picture"; width: view.room; title: I18n.tr("Choose a picture"); note: I18n.tr("LatteOS's own, and what is in your Pictures and Videos folders. A film moves behind the desktop, silently.")
                Repeater { model: pictures.data ? pictures.data : []
                    ClippingRectangle { id: pic; required property var modelData; width: 200; height: 114; radius: 14; color: Theme.card
                        border.width: 3; border.color: shell.bg && shell.bg.shown[shell.bgTarget] === modelData.path ? Theme.gold : "transparent"
                        Image { anchors.fill: parent; anchors.margins: 3; visible: !pic.modelData.live; source: pic.modelData.live ? "" : "file://" + pic.modelData.path; fillMode: Image.PreserveAspectCrop; asynchronous: true; sourceSize.width: 420 }
                        Glyph { anchors.centerIn: parent; visible: pic.modelData.live; name: "player-play"; font.pixelSize: 30; color: Theme.gold }
                        Rectangle { visible: pic.modelData.live; anchors.bottom: parent.bottom; width: parent.width; height: 26; color: Qt.rgba(0, 0, 0, 0.5)
                                    Label { x: 10; width: parent.width - 20; text: pic.modelData.path.split("/").pop(); color: "white"; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter } }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: shell.bgSet(["picture", pic.modelData.path]) } } }
                Item { width: view.room; height: 1 }
                Pill { icon: "folder"; text: I18n.tr("Browse…"); onPressed: { chooser.what = "wallpaper"; chooser.open() } } }
            Part { visible: shell.page === "background" && ["picture", "slideshow"].includes(shell.bgSource) && shell.bg !== null && shell.bg.engine === "plain"; width: view.room; title: I18n.tr("Choose a fit")
                Repeater { model: [{ id: "fill", name: QT_TR_NOOP("Fill") }, { id: "fit", name: QT_TR_NOOP("Fit") }, { id: "stretch", name: QT_TR_NOOP("Stretch") }, { id: "center", name: QT_TR_NOOP("Centre") }, { id: "tile", name: QT_TR_NOOP("Tile") }]
                    Pill { required property var modelData; text: I18n.tr(modelData.name); strong: shell.bg !== null && shell.bg.fit === modelData.id; onPressed: shell.order(["latte-wall", "fit", modelData.id]) } } }

            // one colour
            Part { visible: shell.page === "background" && shell.bgSource === "color"; width: view.room; title: I18n.tr("Choose a colour")
                Repeater { model: ["#1a1410", "#2a1f19", "#3b1d10", "#0f1b2d", "#12343b", "#1f3a2a", "#3a1f2b", "#2d2a4a", "#4a4a4a", "#8a5a3a", "#c98a55", "#f3ebdd"]
                    Rectangle { required property string modelData; width: 54; height: 54; radius: 14; color: modelData
                                border.width: 3; border.color: shell.bg && (shell.bg.screens_own[shell.bgTarget] || shell.bg.all).color === modelData ? Theme.gold : Theme.line
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: shell.bgSet(["color", parent.modelData]) } } }
                Item { width: view.room; height: 1 }
                Field { id: hexField; width: 180; icon: "palette"; hint: "#RRGGBB"; onAccepted: if (/^#?[0-9a-fA-F]{6}$/.test(text.trim())) shell.bgSet(["color", text.trim()]) }
                Pill { icon: "check"; text: I18n.tr("Use this colour"); onPressed: if (/^#?[0-9a-fA-F]{6}$/.test(hexField.text.trim())) shell.bgSet(["color", hexField.text.trim()]) } }

            // the pictures of a folder, one after another
            Part { visible: shell.page === "background" && shell.bgSource === "slideshow"; width: view.room; title: I18n.tr("Choose a folder for the slideshow")
                   note: shell.showFolder === "" ? I18n.tr("Every picture and film in it takes its turn.") : shell.showFolder
                Pill { icon: "folder"; text: I18n.tr("Browse…"); onPressed: folders.open() }
                Item { width: view.room; height: 1 }
                Label { text: I18n.tr("Change picture every"); color: Theme.dim; height: 36; verticalAlignment: Text.AlignVCenter }
                Repeater { model: [{ m: 1, name: QT_TR_NOOP("1 minute") }, { m: 10, name: QT_TR_NOOP("10 minutes") }, { m: 30, name: QT_TR_NOOP("30 minutes") }, { m: 60, name: QT_TR_NOOP("1 hour") }, { m: 360, name: QT_TR_NOOP("6 hours") }, { m: 1440, name: QT_TR_NOOP("1 day") }]
                    Pill { required property var modelData; text: I18n.tr(modelData.name); strong: shell.showMinutes === modelData.m; onPressed: shell.showMinutes = modelData.m } }
                Item { width: view.room; height: 1 }
                Pill { icon: "arrows-sort"; text: I18n.tr("Shuffle"); strong: shell.showShuffle; onPressed: shell.showShuffle = !shell.showShuffle }
                Pill { icon: "player-play"; strong: true; text: I18n.tr("Start the slideshow"); visible: shell.showFolder !== ""
                       onPressed: shell.bgSet(["slideshow", shell.showFolder, String(shell.showMinutes)].concat(shell.showShuffle ? ["shuffle"] : [])) }
                Pill { icon: "chevron-left"; text: I18n.tr("Previous"); onPressed: shell.order(["latte-wall", "prev"]) }
                Pill { icon: "chevron-right"; text: I18n.tr("Next"); onPressed: shell.order(["latte-wall", "next"]) } }

            // from the internet: a press fetches one into the library and puts it on
            Part { visible: shell.page === "background" && ["motionbgs", "wallhaven", "bing"].includes(shell.bgSource); width: view.room
                   title: shell.bgSource === "bing" ? I18n.tr("Bing's pictures of the last days") : (shell.bgSource === "wallhaven" ? I18n.tr("Pictures from Wallhaven") : I18n.tr("Live wallpapers from MotionBGS"))
                   note: I18n.tr("A press fetches one into your Pictures and puts it behind the desktop.")
                Field { id: netField; visible: shell.bgSource !== "bing"; width: 320; hint: I18n.tr("Search…")
                        onAccepted: { online.data = null; online.ask(["latte-walls", shell.bgSource].concat(netField.text.trim().split(/\s+/).filter(w => w !== ""))) } }
                Item { width: view.room; height: 1 }
                Waiting { visible: online.data === null }
                Repeater { model: online.data ? online.data.slice(0, 30) : []
                    ClippingRectangle { id: net; required property var modelData; width: 200; height: 114; radius: 14; color: Theme.card
                        border.width: 3; border.color: shell.fetching === modelData.id ? Theme.gold : "transparent"
                        Image { anchors.fill: parent; anchors.margins: 3; source: net.modelData.thumb; fillMode: Image.PreserveAspectCrop; asynchronous: true; sourceSize.width: 420 }
                        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 26; color: Qt.rgba(0, 0, 0, 0.55)
                            Glyph { x: 8; visible: net.modelData.film; name: "player-play"; font.pixelSize: 12; color: "white"; anchors.verticalCenter: parent.verticalCenter }
                            Label { x: net.modelData.film ? 26 : 10; width: parent.width - x - 10; text: net.modelData.title; color: "white"; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter } }
                        Waiting { anchors.centerIn: parent; visible: shell.fetching === net.modelData.id }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; enabled: shell.fetching === ""
                                    onClicked: { shell.fetching = net.modelData.id; fetcher.running = false; fetcher.command = ["latte-walls", "get", net.modelData.url, net.modelData.title]; fetcher.running = true } } } } }

            // skwd-wall's own picker, and looking for a wallpaper by what it shows
            Part { visible: shell.page === "background" && shell.bgSource === "skwd"; width: view.room; title: "skwd-wall"
                   note: shell.bg !== null && shell.bg.engine === "skwd" ? I18n.tr("Its own picker over the desktop: your library with transitions, scenes of Wallpaper Engine, its downloads and playlists. What you choose there is kept here too.")
                                                                         : I18n.tr("skwd-wall is not installed. With it wallpapers change with a transition and scenes can be shown.")
                Pill { visible: shell.bg !== null && shell.bg.engine === "skwd"; icon: "sparkles"; strong: true; text: I18n.tr("Open skwd-wall"); onPressed: Quickshell.execDetached(["latte-wall", "pick"]) }
                Pill { visible: shell.bg !== null && shell.bg.engine === "skwd"; icon: "player-pause"; text: I18n.tr("Pause"); onPressed: Quickshell.execDetached(["latte-wall", "pause"]) }
                Pill { visible: shell.bg !== null && shell.bg.engine === "skwd"; icon: "player-play"; text: I18n.tr("Play"); onPressed: Quickshell.execDetached(["latte-wall", "resume"]) } }
            Part { visible: shell.page === "background" && shell.bgSource === "lens"; width: view.room; title: I18n.tr("Describe the wallpaper you want")
                   note: shell.bg !== null && shell.bg.lens ? I18n.tr("A model on this computer looks through your library for pictures that show what you describe. Nothing leaves the computer.")
                                                            : I18n.tr("This needs skwd-wall with its search model, and AI turned on in the Settings.")
                Field { id: lensField; visible: shell.bg !== null && shell.bg.lens; width: 420; hint: I18n.tr("a foggy forest in the morning…")
                        onAccepted: Quickshell.execDetached(["latte-wall", "pick"].concat(lensField.text.trim().split(/\s+/).filter(w => w !== ""))) }
                Pill { visible: shell.bg !== null && shell.bg.lens; icon: "search"; strong: true; text: I18n.tr("Look for it")
                       onPressed: Quickshell.execDetached(["latte-wall", "pick"].concat(lensField.text.trim().split(/\s+/).filter(w => w !== ""))) } }

            Switch { visible: shell.page === "background"; width: view.room; text: I18n.tr("Icons on the desktop"); on: icons.value !== "off"
                     hint: I18n.tr("The Recycle Bin and what is in your Desktop folder, over the background.")
                     onPressed: { const next = on ? "off" : "on"; icons.value = next; Quickshell.execDetached(["latte-desktop", next]) } }

            // windows: how they are arranged, and the glass of the side panels
            Part { visible: shell.page === "windows"; width: view.room; title: I18n.tr("How windows are arranged")
                // in the order of ROADMAP 8A.06; `soon`: decided, not made yet
                Repeater { model: [{ id: "tape", name: QT_TR_NOOP("Tape"), hint: QT_TR_NOOP("an endless strip, nothing is put away"), icon: "layout-columns" },
                                   { id: "floating", name: QT_TR_NOOP("Floating windows"), hint: QT_TR_NOOP("as on Windows"), icon: "app-window" },
                                   { id: "tiles", name: QT_TR_NOOP("Tiles"), hint: QT_TR_NOOP("windows share the screen"), icon: "layout-grid" },
                                   { id: "glance", name: QT_TR_NOOP("Glance"), hint: QT_TR_NOOP("one in the middle, the others at the sides"), icon: "layout-distribute-vertical" },
                                   { id: "canvas", name: QT_TR_NOOP("Canvas"), hint: QT_TR_NOOP("free windows on a desk you zoom out of"), icon: "zoom-out-area", soon: true },
                                   { id: "trizone", name: QT_TR_NOOP("Three zones"), hint: QT_TR_NOOP("for wide screens: a middle and two columns"), icon: "columns-3", soon: true }]
                    Choice { required property var modelData; width: 200; text: I18n.tr(modelData.name); on: win.mode === modelData.id
                             hint: modelData.soon ? I18n.tr("coming") : I18n.tr(modelData.hint); opacity: modelData.soon ? 0.5 : 1
                             onPressed: if (!modelData.soon) Quickshell.execDetached(["hyprctl", "eval", "latte.mode.set(\"" + modelData.id + "\")"])
                             Glyph { anchors.centerIn: parent; name: parent.parent.modelData.icon; font.pixelSize: 54; color: parent.parent.on ? Theme.gold : Theme.dim } } } }
            // how much of LatteOS is glass: one choice for all of it; 0 makes everything solid (Theme.glassLevel)
            Part { visible: shell.page === "windows"; width: view.room; title: I18n.tr("Glass"); note: I18n.tr("How much of LatteOS is glass: the side panels, the windows and the AI's pages. None: everything is solid.")
                Repeater { model: [{ n: 0, name: QT_TR_NOOP("None") }, { n: 1, name: QT_TR_NOOP("A little") }, { n: 2, name: QT_TR_NOOP("More") }, { n: 3, name: QT_TR_NOOP("The most") }, { n: 4, name: "True Glass" }]
                    Choice { required property var modelData; width: 150; text: I18n.tr(modelData.name); on: Theme.glassLevel === modelData.n
                             onPressed: { glassLevel.choose(String(modelData.n)); Theme.glassLevel = modelData.n; goo.set("glass", modelData.n) } } } }
            Part { visible: shell.page === "windows" && Theme.glassLevel > 0 && shell.expert; expertOnly: true; width: view.room; title: I18n.tr("The glass of the side panels"); note: I18n.tr("What is behind a window shows through its side panel, blurred. Where the graphics card cannot blur, the panel is solid.")
                Repeater { model: [{ id: "frost", name: QT_TR_NOOP("Frosted") }, { id: "smoke", name: QT_TR_NOOP("Smoked") }, { id: "clear", name: QT_TR_NOOP("Clear") }, { id: "milk", name: QT_TR_NOOP("Milky") }]
                    Choice { id: pane; required property var modelData; width: 150; height: 130; text: I18n.tr(modelData.name); on: Theme.glass === modelData.id; onPressed: { glass.choose(modelData.id); Theme.glass = modelData.id }
                        ClippingRectangle { anchors.fill: parent; radius: 10; color: "transparent"
                            Image { anchors.fill: parent; source: "file://" + shell.share + "/wallpapers/latteos-2.jpg"; fillMode: Image.PreserveAspectCrop; sourceSize.width: 240 }
                            Rectangle { anchors.fill: parent; color: Theme.glasses[pane.modelData.id] } } } } }

            // the drops
            Part { visible: shell.page === "drops"; width: view.room; title: I18n.tr("How the drops behave")
                Switch { text: I18n.tr("Lively"); hint: I18n.tr("Left alone they fall asleep, the weather outside shows on the surface, playful ones play."); on: goo.kept.lively !== false; onPressed: goo.set("lively", !on) }
                Switch { text: I18n.tr("The surface bends"); hint: I18n.tr("Ripples lift the drops and the edge gives under them."); on: goo.kept.bends !== false; onPressed: goo.set("bends", !on) } }
            Part { visible: shell.page === "drops" && dropList.list.length > 0; width: view.room; title: I18n.tr("Drops on the desktop")
                Repeater { model: dropList.list
                    Switch { required property var modelData; text: modelData.name; on: (goo.kept.hidden || []).indexOf(modelData.id) < 0
                             onPressed: { const h = (goo.kept.hidden || []).filter(id => id !== modelData.id); if (on) h.push(modelData.id); goo.set("hidden", h) } } } }
            Part { visible: shell.page === "drops"; width: view.room; title: I18n.tr("Places")
                   note: I18n.tr("PowerGoo and LensGoo are always there. The coffee the drops are made of is under Coffee and cup.")
                Pill { icon: "arrow-back-up"; text: I18n.tr("Put every drop back in its place"); onPressed: Quickshell.execDetached(["latte-say", "emit reset_places"]) } }

            // every drop's own page begins with whether it is on the desktop; what it is, for those that have nothing more to set
            Part { id: dropPart; readonly property string drop: shell.dropOf[shell.page] || ""
                   readonly property bool optional: dropList.list.some(d => d.id === drop)
                   visible: drop !== ""; width: view.room; title: I18n.tr("On the desktop")
                   note: shell.dropAbout[shell.page] ? I18n.tr(shell.dropAbout[shell.page]) : ""
                Switch { visible: dropPart.optional; text: I18n.tr("Show it on the desktop")
                         on: (goo.kept.hidden || []).indexOf(dropPart.drop) < 0
                         onPressed: { const id = dropPart.drop; const h = (goo.kept.hidden || []).filter(x => x !== id); if (on) h.push(id); goo.set("hidden", h) } }
                Label { visible: !dropPart.optional; width: view.room; color: Theme.dim; font.pixelSize: 13; wrapMode: Text.WordWrap
                        text: I18n.tr("Always there: it belongs to the desktop itself.") } }
            // BarGoo: whether a press on it changes the arrangement (6A.05)
            Part { visible: shell.page === "bargoo"; width: view.room; title: I18n.tr("A press on BarGoo")
                Switch { text: I18n.tr("A press on BarGoo changes the arrangement"); hint: I18n.tr("Off: the arrangement chosen in Windows stays, and a press on BarGoo only shows the windows.")
                         on: goo.kept.bar_fixed !== true; onPressed: goo.set("bar_fixed", on) } }

            // ClockGoo: where the weather is, the world clocks, the screen time
            Part { visible: shell.page === "clockgoo"; width: view.room; title: I18n.tr("Where the weather is")
                   note: I18n.tr("A town or a village; the weather, the sunrise and the sunset are for it. The login screen shows its sky too.")
                Label { width: view.room; text: logon.data && logon.data.place ? logon.data.place : I18n.tr("No place yet"); font.weight: 700; font.pixelSize: 15 }
                Field { id: weatherPlace; width: Math.min(420, view.room); icon: "map-pin"; hint: I18n.tr("Type a town and press Enter…")
                        onAccepted: if (text.trim() !== "") { shell.order(["latte-settings", "loginscreen", "place", text.trim()]); text = "" } } }
            Part { visible: shell.page === "clockgoo" && shell.expert; expertOnly: true; width: view.room; title: I18n.tr("Forecast by")
                   note: I18n.tr("The weather services whose forecasts ClockGoo shows side by side, up to five. They often differ: together they tell what may come.")
                Repeater { model: shell.page === "clockgoo" && weatherq.data ? weatherq.data.models : []
                    Pill { required property var modelData
                           readonly property bool on: weatherq.data.chosen.indexOf(modelData.id) >= 0
                           text: modelData.name + " · " + modelData.by; icon: on ? "check" : ""; strong: on
                           onPressed: shell.order(["latte-sky", "choose", modelData.id, on ? "off" : "on"]) } } }
            Part { visible: shell.page === "clockgoo" && weatherq.data !== null && weatherq.data.links.length > 0; width: view.room; title: I18n.tr("More forecasts for your region")
                   note: I18n.tr("The services of the country of the place above, and some for anywhere. ClockGoo offers them under the days ahead.")
                Repeater { model: shell.page === "clockgoo" && weatherq.data ? weatherq.data.links : []
                    Rectangle { required property var modelData; width: view.room; height: 48; radius: 14; color: Theme.card
                        Glyph { x: 16; name: modelData.here ? "map-pin" : "world"; font.pixelSize: 16; color: Theme.gold; anchors.verticalCenter: parent.verticalCenter }
                        Label { x: 44; text: modelData.name; font.weight: 700; anchors.verticalCenter: parent.verticalCenter }
                        Label { x: 190; width: parent.width - 330; text: I18n.tr(modelData.what); color: Theme.dim; font.pixelSize: 12; elide: Text.ElideRight; anchors.verticalCenter: parent.verticalCenter }
                        Pill { anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter; text: I18n.tr("Open"); icon: "world-www"
                               onPressed: Qt.openUrlExternally(modelData.url) } } } }
            Part { id: worldPart; visible: shell.page === "clockgoo"; width: view.room; title: I18n.tr("World clocks")
                   note: I18n.tr("Up to five; the first is home. Find any city or part of the world below, and name it as you like.")
                Repeater { model: shell.page === "clockgoo" ? shell.worldClocks : []
                    Rectangle { id: wc; required property var modelData; required property int index; width: view.room; height: 56; radius: 16; color: Theme.card
                        border.width: index === 0 ? 1 : 0; border.color: Theme.gold
                        Glyph { x: 18; name: wc.index === 0 ? "home-2" : "world"; font.pixelSize: 18; color: wc.index === 0 ? Theme.gold : Theme.dim; anchors.verticalCenter: parent.verticalCenter }
                        Column { x: 50; width: parent.width - 50 - 260; anchors.verticalCenter: parent.verticalCenter; spacing: 1
                            TextInput { width: parent.width; text: I18n.tr(wc.modelData.name); color: Theme.cream; font.family: Theme.font; font.pixelSize: 14; font.weight: 700; selectByMouse: true; clip: true
                                        onEditingFinished: if (text.trim() !== "" && text.trim() !== I18n.tr(wc.modelData.name)) shell.clocksEdit(l => l[wc.index].name = text.trim()) }
                            Label { text: wc.modelData.zone.replace(/_/g, " "); color: Theme.dim; font.pixelSize: 12 } }
                        Row { anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter; spacing: 8
                            Pill { visible: wc.index > 0; text: I18n.tr("Make home"); icon: "home-2"; onPressed: shell.clocksEdit(l => l.unshift(l.splice(wc.index, 1)[0])) }
                            Pill { visible: shell.worldClocks.length > 1; icon: "x"; danger: true; onPressed: shell.clocksEdit(l => l.splice(wc.index, 1)) } } } }
                Field { id: cityField; width: Math.min(420, view.room); hint: I18n.tr("Find a city or a part of the world…") }
                Item { width: view.room; height: 1 }
                Repeater { model: shell.page === "clockgoo" && clock.data && cityField.text.trim().length > 1
                                  ? clock.data.zones.filter(z => shell.near(shell.plain(cityField.text.trim()).replace(/ /g, "_"), shell.plain(z).replace(/\//g, " "))).slice(0, 24) : []
                    Pill { required property string modelData; icon: "plus"; text: modelData.replace(/_/g, " ")
                           onPressed: if (shell.worldClocks.length < 5) { shell.clocksEdit(l => l.push({ zone: modelData, name: modelData.split("/").pop().replace(/_/g, " "), country: modelData.split("/")[0] })); cityField.text = "" } } } }
            Part { visible: shell.page === "clockgoo"; width: view.room; title: I18n.tr("Digital wellbeing")
                   note: I18n.tr("How long the screen was in front of you today, and in which apps. It is counted on this computer and never leaves it.")
                Switch { width: view.room; text: I18n.tr("Keep the screen time"); on: focusq.data !== null && focusq.data.log !== false
                         onPressed: { shell.order(["latte-focus", "set", "log", on ? "off" : "on"]) } }
                Label { text: I18n.tr("A goal for a day"); color: Theme.dim; width: view.room }
                Repeater { model: [2, 3, 4, 5, 6, 8, 10]
                    Pill { required property int modelData; text: modelData + " h"; strong: focusq.data !== null && focusq.data.goal === modelData; onPressed: shell.order(["latte-focus", "set", "goal", String(modelData)]) } }
                Item { width: view.room; height: 1 }
                Label { text: I18n.tr("Bedtime"); color: Theme.dim; width: view.room }
                Repeater { model: ["21:30", "22:00", "22:30", "23:00", "23:30", "00:00"]
                    Pill { required property string modelData; text: modelData; strong: focusq.data !== null && focusq.data.bedtime === modelData; onPressed: shell.order(["latte-focus", "set", "bedtime", modelData]) } } }

            // CamGoo: the webcams
            Part { visible: shell.page === "camgoo"; width: view.room; title: I18n.tr("Webcams")
                   note: I18n.tr("A camera that publishes its picture of now at a fixed address (a .jpg or .png). CamGoo fetches it every minute while its card is open. Up to six are shown.")
                Repeater { model: shell.page === "camgoo" ? shell.webcams : []
                    Rectangle { id: cm; required property var modelData; required property int index; width: view.room; height: 56; radius: 16; color: Theme.card
                        Glyph { x: 18; name: "camera"; font.pixelSize: 18; color: Theme.gold; anchors.verticalCenter: parent.verticalCenter }
                        Column { x: 50; width: parent.width - 50 - 160; anchors.verticalCenter: parent.verticalCenter; spacing: 1
                            TextInput { width: parent.width; text: I18n.tr(cm.modelData.name); color: Theme.cream; font.family: Theme.font; font.pixelSize: 14; font.weight: 700; selectByMouse: true; clip: true
                                        onEditingFinished: if (text.trim() !== "" && text.trim() !== I18n.tr(cm.modelData.name)) shell.camsEdit(l => l[cm.index].name = text.trim()) }
                            Label { text: cm.modelData.url; color: Theme.dim; font.pixelSize: 11; width: parent.width; elide: Text.ElideMiddle } }
                        Row { anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter; spacing: 8
                            Pill { visible: cm.index > 0; icon: "chevron-up"; onPressed: shell.camsEdit(l => l.splice(cm.index - 1, 0, l.splice(cm.index, 1)[0])) }
                            Pill { icon: "x"; danger: true; onPressed: shell.camsEdit(l => l.splice(cm.index, 1)) } } } }
                Row { spacing: 10
                    Field { id: camName; width: 200; icon: "camera"; hint: I18n.tr("Name") }
                    Field { id: camUrl; width: Math.min(420, view.room - 340); icon: "world-www"; hint: I18n.tr("https://…/picture.jpg"); onAccepted: camAdd.pressed() }
                    Pill { id: camAdd; text: I18n.tr("Add"); strong: true; icon: "plus"
                           onPressed: if (/^https?:\/\/\S+$/.test(camUrl.text.trim()) && camName.text.trim() !== "") { shell.camsEdit(l => l.push({ name: camName.text.trim(), url: camUrl.text.trim() })); camName.text = ""; camUrl.text = "" } } } }

            // the launcher's lists
            Part { visible: shell.page === "launcher"; width: view.room; title: I18n.tr("Lists of the launcher")
                   note: I18n.tr("Each list is a button in the row under the search of LensGoo. Choose which of your apps belong to it, or make a list of your own.")
                Repeater { model: shell.page === "launcher" ? shell.lensLists : []
                    Column { id: ls; required property var modelData; required property int index; width: view.room; spacing: 8
                        readonly property var members: shell.entries.filter(e => shell.lensHas(ls.modelData, e))
                        Rectangle { width: parent.width; height: 64; radius: 16; color: Theme.card
                            Rectangle { x: 14; width: 40; height: 40; radius: 13; color: Theme.ground; anchors.verticalCenter: parent.verticalCenter
                                Glyph { anchors.centerIn: parent; name: ls.modelData.builtin ? "star" : "list"; font.pixelSize: 20; color: Theme.gold } }
                            Column { x: 68; width: parent.width - 68 - 360; anchors.verticalCenter: parent.verticalCenter; spacing: 2
                                TextInput { id: lname; width: parent.width; color: Theme.cream; font.family: Theme.font; font.pixelSize: 15; font.weight: 700; clip: true; selectByMouse: true
                                            text: ls.modelData.builtin ? I18n.tr(ls.modelData.name) : ls.modelData.name; readOnly: ls.modelData.builtin
                                            onEditingFinished: if (!ls.modelData.builtin && text.trim() !== "") shell.lensEdit(ls.index, l => l.name = text.trim()) }
                                Label { text: I18n.tr("{n} apps", { n: ls.members.length }); color: Theme.dim; font.pixelSize: 12 } }
                            Row { anchors.right: parent.right; anchors.rightMargin: 14; anchors.verticalCenter: parent.verticalCenter; spacing: 8
                                Pill { text: I18n.tr("Shown"); icon: ls.modelData.on !== false ? "check" : ""; strong: ls.modelData.on !== false
                                       onPressed: shell.lensEdit(ls.index, l => l.on = !(l.on !== false)) }
                                Pill { text: I18n.tr("Choose apps"); icon: shell.lensOpen === ls.index ? "chevron-up" : "chevron-down"; onPressed: shell.lensOpen = shell.lensOpen === ls.index ? -1 : ls.index }
                                Pill { visible: !ls.modelData.builtin; icon: "x"; danger: true; onPressed: { const l = shell.lensLists.filter((x, k) => k !== ls.index); lensFile.save(l); shell.lensOpen = -1 } } } }
                        // the apps, to be ticked in and out: a line to find one by name, and a grid that makes only the
                        // cells that are on view (a few hundred apps are no weight)
                        Column { visible: shell.lensOpen === ls.index; width: parent.width; spacing: 8
                            Field { id: pick; width: 320; icon: "search"; hint: I18n.tr("Find an app…") }
                            GridView { id: grid; width: parent.width; clip: true; boundsBehavior: Flickable.StopAtBounds; cacheBuffer: 200
                                readonly property int cols: Math.max(1, Math.floor(width / 210))
                                cellWidth: width / cols; cellHeight: 52
                                height: Math.min(440, Math.ceil(count / cols) * 52)
                                model: ScriptModel { values: shell.lensOpen === ls.index ? shell.entries.filter(e => pick.text.trim() === "" || shell.near(shell.plain(pick.text.trim()), shell.plain(e.name))) : [] }
                                delegate: Rectangle { id: chip; required property var modelData; width: grid.cellWidth - 8; height: 44; radius: 12
                                    readonly property bool inside: shell.lensHas(ls.modelData, modelData)
                                    color: inside ? Qt.rgba(Theme.gold.r, Theme.gold.g, Theme.gold.b, 0.2) : Theme.card; border.width: 1; border.color: inside ? Theme.gold : "transparent"
                                    Image { x: 10; width: 26; height: 26; anchors.verticalCenter: parent.verticalCenter; source: Quickshell.iconPath(chip.modelData.icon, true); sourceSize.width: 52; asynchronous: true; fillMode: Image.PreserveAspectFit }
                                    Label { x: 46; width: parent.width - 80; text: chip.modelData.name; elide: Text.ElideRight; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
                                    Glyph { visible: chip.inside; anchors.right: parent.right; anchors.rightMargin: 10; name: "check"; font.pixelSize: 16; color: Theme.gold; anchors.verticalCenter: parent.verticalCenter }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: shell.lensFlip(ls.index, chip.modelData) } } } } } }
                Row { spacing: 10
                    Field { id: newList; width: 300; icon: "plus"; hint: I18n.tr("Name of a new list"); onAccepted: addList.pressed() }
                    Pill { id: addList; text: I18n.tr("Add list"); strong: true; icon: "plus"
                           onPressed: if (newList.text.trim() !== "") { const l = JSON.parse(JSON.stringify(shell.lensLists)); l.push({ id: "own" + Date.now(), name: newList.text.trim(), on: true, apps: [] })
                                                                       lensFile.save(l); newList.text = ""; shell.lensOpen = l.length - 1 } } } }

            // what LensGoo searches: a tab each, the apps always there; the AI tab is LensAI's (services, models, on and off)
            Part { visible: shell.page === "launcher"; width: view.room; title: I18n.tr("What LensGoo searches")
                   note: I18n.tr("Each one is a tab at the top of LensGoo. What you turn off here is not shown there.")
                Repeater { model: [{ n: 0, name: QT_TR_NOOP("Apps and settings"), hint: QT_TR_NOOP("Apps, the pages of Settings and what is inside them"), icon: "apps" },
                                   { n: 1, name: QT_TR_NOOP("Files and folders"), hint: QT_TR_NOOP("Your files by name, the folders of your home first"), icon: "folder" },
                                   { n: 2, name: QT_TR_NOOP("Web search"), hint: QT_TR_NOOP("What you type goes to your search engine in the browser"), icon: "world" },
                                   { n: 3, name: QT_TR_NOOP("Command"), hint: QT_TR_NOOP("A command of Linux, run in the background; a dangerous one asks first"), icon: "terminal-2" }]
                    Switch { required property var modelData; width: view.room; text: I18n.tr(modelData.name); hint: modelData.n === 0 ? I18n.tr(modelData.hint) + " · " + I18n.tr("always there") : I18n.tr(modelData.hint)
                             on: !lensFile.modesOff.includes(modelData.n); onPressed: if (modelData.n > 0) lensFile.mode(modelData.n, !on) } }
                Rectangle { width: view.room; height: 64; radius: 16; color: Theme.card
                    Glyph { x: 18; name: "sparkles"; font.pixelSize: 22; color: Theme.gold; anchors.verticalCenter: parent.verticalCenter }
                    Column { x: 56; width: parent.width - 56 - 200; anchors.verticalCenter: parent.verticalCenter; spacing: 3
                        Label { text: I18n.tr("AI"); font.weight: 700 }
                        Label { width: parent.width; text: I18n.tr("The AI tab of LensGoo belongs to LensAI: its services, models and turning it on."); color: Theme.dim; font.pixelSize: 12; elide: Text.ElideRight } }
                    Pill { anchors.right: parent.right; anchors.rightMargin: 14; anchors.verticalCenter: parent.verticalCenter; icon: "external-link"; text: I18n.tr("Open LensAI")
                           onPressed: Quickshell.execDetached(["latte-app", "aicenter"]) } } }

            // GuardDog: what is kept running, and what the user has told it to leave alone
            Pill { visible: shell.page === "guarddog"; icon: "shield-check"; text: I18n.tr("Open GuardDog: crashes and its log"); onPressed: Quickshell.execDetached(["latte-app", "guarddog"]) }
            Part { visible: shell.page === "guarddog"; width: view.room; title: I18n.tr("What GuardDog keeps running")
                   note: I18n.tr("It looks every few seconds, and starts again what has stopped. What you switch off here it leaves alone, and it stays so after an update. Switching off does not stop what is running now.")
                Repeater { model: shell.page === "guarddog" && guardq.data ? guardq.data : []
                    Rectangle { required property var modelData; width: view.room; height: 62; radius: 16; color: Theme.card
                        Rectangle { x: 16; width: 11; height: 11; radius: 6; anchors.verticalCenter: parent.verticalCenter
                                    color: parent.modelData.state === "up" ? Theme.ok : (parent.modelData.state === "off" ? Theme.faint : (parent.modelData.state === "restarted" ? Theme.gold : Theme.red)) }
                        Column { x: 42; width: parent.width - 42 - 120; anchors.verticalCenter: parent.verticalCenter; spacing: 2
                            Label { text: I18n.tr(parent.parent.modelData.name); font.weight: 600 }
                            Label { color: Theme.dim; font.pixelSize: 12
                                    text: parent.parent.modelData.off ? I18n.tr("left alone, as you chose") : (parent.parent.modelData.state === "up" ? I18n.tr("running") : (parent.parent.modelData.state === "restarted" ? I18n.tr("started again {n} times", { n: parent.parent.modelData.restarts }) : (parent.parent.modelData.state === "failed" ? I18n.tr("would not stay up") : I18n.tr("not running")))) } }
                        Rectangle { width: 46; height: 26; radius: 13; color: parent.modelData.off ? Theme.raised : Theme.gold; anchors.right: parent.right; anchors.rightMargin: 16; anchors.verticalCenter: parent.verticalCenter
                            Behavior on color { ColorAnimation { duration: 140 } }
                            Rectangle { width: 20; height: 20; radius: 10; y: 3; x: parent.parent.modelData.off ? 3 : 23; color: parent.parent.modelData.off ? Theme.dim : Theme.ground; Behavior on x { NumberAnimation { duration: 140 } } }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: { Quickshell.execDetached(["latte-guarddog", "set", parent.parent.modelData.id, parent.parent.modelData.off ? "on" : "off"]); later.restart() } } } } } }

            // sound: where it goes and where it comes from
            Repeater { model: shell.page === "sound" ? [{ key: "outputs", title: QT_TR_NOOP("Where the sound goes"), cmd: "sink", icon: "device-speaker" },
                                                        { key: "inputs", title: QT_TR_NOOP("Where it comes from"), cmd: "source", icon: "microphone" }] : []
                Column { id: way; required property var modelData; width: view.room; spacing: 8
                    readonly property var list: sound.data ? sound.data[modelData.key] : []
                    Label { text: I18n.tr(way.modelData.title); font.pixelSize: 18; font.weight: 700; bottomPadding: 4 }
                    Label { visible: way.list.length === 0; text: I18n.tr("Nothing is connected."); color: Theme.dim }
                    Repeater { model: ScriptModel { values: way.list.map(d => d.name) }
                        Rectangle { id: dev; required property string modelData; width: view.room; height: 70; radius: 16; color: Theme.card
                            readonly property var d: way.list.find(x => x.name === modelData) || { label: "", volume: 0, muted: false, "default": false }
                            border.width: 2; border.color: d["default"] ? Theme.gold : "transparent"
                            Rectangle { x: 14; width: 42; height: 42; radius: 14; color: Theme.ground; anchors.verticalCenter: parent.verticalCenter
                                Glyph { anchors.centerIn: parent; name: dev.d.muted ? "volume-off" : way.modelData.icon; font.pixelSize: 22; color: dev.d["default"] ? Theme.gold : Theme.dim }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: shell.order(["pactl", "set-" + way.modelData.cmd + "-mute", dev.modelData, "toggle"]) } }
                            Column { x: 70; width: parent.width - 70 - 330; anchors.verticalCenter: parent.verticalCenter; spacing: 3
                                Label { text: dev.d.label; font.weight: 600; width: parent.width }
                                Label { text: dev.d["default"] ? I18n.tr("in use") : I18n.tr("press to use"); color: dev.d["default"] ? Theme.gold : Theme.dim; font.pixelSize: 12 } }
                            MouseArea { x: 70; width: parent.width - 400; height: parent.height; cursorShape: Qt.PointingHandCursor; onClicked: shell.order(["pactl", "set-default-" + way.modelData.cmd, dev.modelData]) }
                            Slide { anchors.right: parent.right; anchors.rightMargin: 70; anchors.verticalCenter: parent.verticalCenter; width: 230; value: dev.d.volume; off: dev.d.muted
                                    onMoved: to => shell.order(["pactl", "set-" + way.modelData.cmd + "-volume", dev.modelData, Math.round(to * 100) + "%"]) }
                            Label { anchors.right: parent.right; anchors.rightMargin: 18; anchors.verticalCenter: parent.verticalCenter; text: Math.round(dev.d.volume * 100) + " %"; color: Theme.dim; font.pixelSize: 12 } } } } }

            // which app opens what
            Label { visible: shell.page === "defaults"; width: view.room; wrapMode: Text.WordWrap; color: Theme.dim; font.pixelSize: 13
                    text: I18n.tr("The app that opens a kind of thing when it is pressed in a folder, a mail or a web page. Press another to make it the one.") }
            Repeater { model: shell.page === "defaults" && opens.data ? opens.data : []
                Column { id: kindRow; required property var modelData; width: view.room; spacing: 8
                    Row { spacing: 10
                        Glyph { name: shell.kindIcons[kindRow.modelData.kind] || "apps"; color: Theme.gold; font.pixelSize: 20; anchors.verticalCenter: parent.verticalCenter }
                        Label { text: I18n.tr(shell.kindNames[kindRow.modelData.kind] || kindRow.modelData.kind); font.pixelSize: 16; font.weight: 700; anchors.verticalCenter: parent.verticalCenter } }
                    Label { visible: kindRow.modelData.apps.length === 0; text: I18n.tr("No app for it is installed."); color: Theme.dim; font.pixelSize: 12 }
                    Flow { width: parent.width; spacing: 8
                        Repeater { model: kindRow.modelData.apps
                            Rectangle { id: appChip; required property var modelData; height: 44; width: chipRow.implicitWidth + 28; radius: 14
                                readonly property bool on: kindRow.modelData.current === modelData.id
                                color: on ? Theme.raised : Theme.card; border.width: 2; border.color: on ? Theme.gold : "transparent"
                                Row { id: chipRow; anchors.centerIn: parent; spacing: 9
                                    Image { width: 26; height: 26; source: appChip.modelData.icon.startsWith("/") ? "file://" + appChip.modelData.icon : Quickshell.iconPath(appChip.modelData.icon, true); sourceSize.width: 64; sourceSize.height: 64; anchors.verticalCenter: parent.verticalCenter; visible: status === Image.Ready }
                                    Label { text: appChip.modelData.name; font.weight: appChip.on ? 700 : 400; anchors.verticalCenter: parent.verticalCenter } }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: shell.order(["latte-settings", "default", kindRow.modelData.kind, appChip.modelData.id]) } } } } } }

            // how much the desktop spends on looks
            Part { visible: shell.page === "performance"; width: view.room; title: I18n.tr("How much the desktop spends on looks")
                   note: I18n.tr("Blur, shadows and movement cost the graphics card. It changes when you sign in the next time.")
                Repeater { model: shell.tiers
                    Choice { required property var modelData; width: 158; text: I18n.tr(modelData.name); on: tier.value === modelData.id; onPressed: tier.choose(modelData.id)
                             hint: modelData.id === "" ? (I18n.tr((shell.tiers.find(t => t.id === decided.tier) || { name: decided.tier }).name)) : I18n.tr(modelData.hint)
                             Glyph { anchors.centerIn: parent; name: parent.parent.modelData.icon; font.pixelSize: 50; color: parent.parent.on ? Theme.gold : Theme.dim } } } }
            Label { visible: shell.page === "performance"; width: view.room; wrapMode: Text.WordWrap; color: Theme.dim; font.pixelSize: 13
                    text: ((machine.data ? machine.data.groups.find(g => g.id === "graphics") : null) || { devices: [] }).devices.map(d => d.name + (d.driver ? "  ·  " + d.driver : "")).join("\n") }
            Row { visible: shell.page === "performance"; spacing: 10
                Pill { icon: "activity"; text: I18n.tr("Open the Monitor"); onPressed: Quickshell.execDetached(["latte-app", "monitor"]) }
                Pill { icon: "shield-check"; text: I18n.tr("Start and safe mode"); onPressed: shell.go("startmode") } }

            // how this start went, and SAFE for the next one
            Rectangle { visible: shell.page === "startmode"; width: view.room; height: 120; radius: 26
                gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: Theme.raised } GradientStop { position: 1; color: Theme.card } }
                Glyph { x: 30; name: decided.mode === "safe" ? "shield-lock" : "shield-check"; font.pixelSize: 54; color: Theme.gold; anchors.verticalCenter: parent.verticalCenter }
                Column { x: 110; width: parent.width - 140; anchors.verticalCenter: parent.verticalCenter; spacing: 5
                    Label { text: decided.mode === "safe" ? I18n.tr("This start is SAFE") : (decided.renderer === "hw" ? I18n.tr("The full desktop, drawn by the graphics card") : I18n.tr("The full desktop, drawn by the processor")); font.pixelSize: 19; font.weight: 700 }
                    Label { text: decided.reason; visible: text !== ""; color: Theme.dim; font.pixelSize: 12; width: parent.width; wrapMode: Text.WordWrap; maximumLineCount: 3 } } }
            Switch { visible: shell.page === "startmode"; width: view.room; text: I18n.tr("Start in SAFE the next time"); on: force.there
                     hint: I18n.tr("A plain desktop that always starts, for when the full one does not. For one start.")
                     onPressed: shell.order(["latte-boot", on ? "reset" : "force-safe"]) }
            Label { visible: shell.page === "startmode"; width: view.room; wrapMode: Text.WordWrap; color: Theme.dim; font.pixelSize: 13
                    text: I18n.tr("SAFE can also be chosen on the login screen. Should the full desktop crash right after it starts, LatteOS goes to SAFE by itself.") }
            Part { visible: shell.page === "startmode"; width: view.room; title: I18n.tr("The last crash")
                   note: crashed.said === "" ? I18n.tr("No crash is recorded.") : I18n.tr("What LatteOS noted when the desktop last ended badly. Copy it to send it to whoever helps.")
                Label { visible: crashed.said !== ""; width: view.room; text: crashed.said.split("\n").slice(0, 30).join("\n"); wrapMode: Text.WrapAnywhere
                        font.family: "JetBrains Mono"; font.pixelSize: 12; color: Theme.dim; maximumLineCount: 30; elide: Text.ElideRight }
                Pill { visible: crashed.said !== ""; icon: "clipboard"; text: I18n.tr("Copy the report")
                       onPressed: Quickshell.execDetached(["latte-safe", "why", "copy"]) } }
            Pill { visible: shell.page === "startmode"; icon: "activity"; text: I18n.tr("Performance and graphics"); onPressed: shell.go("performance") }

            // what is on the disks
            Repeater { model: shell.page === "storage" && disks.data ? disks.data.disks : []
                Rectangle { id: disk; required property var modelData; width: view.room; height: 86; radius: 16; color: Theme.card
                    readonly property real full: modelData.size > 0 ? modelData.used / modelData.size : 0
                    Glyph { x: 20; y: 18; name: "disc"; font.pixelSize: 24; color: Theme.gold }
                    Label { x: 58; y: 16; text: disk.modelData.mount === "/" ? I18n.tr("This computer") : disk.modelData.mount; font.weight: 700 }
                    Label { x: 58; y: 36; color: Theme.dim; font.pixelSize: 12; text: I18n.tr("{free} free of {size}", { free: shell.bytes(disk.modelData.size - disk.modelData.used), size: shell.bytes(disk.modelData.size) }) + "  ·  " + disk.modelData.kind }
                    Rectangle { x: 20; y: 62; width: parent.width - 40; height: 8; radius: 4; color: Theme.raised
                        Rectangle { width: parent.width * disk.full; height: 8; radius: 4; color: disk.full > 0.9 ? Theme.red : Theme.gold } } } }
            Part { visible: shell.page === "storage"; width: view.room; title: I18n.tr("Your folders")
                Waiting { visible: held.data === null }
                Repeater { model: shell.page === "storage" && held.data ? held.data.folders : []
                    Rectangle { id: fold; required property var modelData; width: 250; height: 60; radius: 16; color: foldHit.containsMouse ? Theme.raised : Theme.card
                        Glyph { x: 16; name: "folder"; font.pixelSize: 22; color: Theme.gold; anchors.verticalCenter: parent.verticalCenter }
                        Label { x: 50; y: 11; text: I18n.tr(shell.folderNames[fold.modelData.id] || fold.modelData.id); font.weight: 600 }
                        Label { x: 50; y: 31; text: shell.bytes(fold.modelData.size); color: Theme.dim; font.pixelSize: 12 }
                        MouseArea { id: foldHit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Quickshell.execDetached(["xdg-open", fold.modelData.path]) } } } }
            Rectangle { visible: shell.page === "storage" && held.data !== null; width: view.room; height: 64; radius: 16; color: Theme.card
                Glyph { x: 18; name: "trash"; font.pixelSize: 22; color: Theme.dim; anchors.verticalCenter: parent.verticalCenter }
                Column { x: 54; anchors.verticalCenter: parent.verticalCenter; spacing: 3
                    Label { text: I18n.tr("Trash"); font.weight: 600 }
                    Label { text: held.data ? shell.bytes(held.data.trash) : ""; color: Theme.dim; font.pixelSize: 12 } }
                Pill { anchors.right: parent.right; anchors.rightMargin: 14; anchors.verticalCenter: parent.verticalCenter; visible: held.data !== null && held.data.trash > 0; danger: shell.emptying
                       icon: "trash"; text: shell.emptying ? I18n.tr("Really empty it? It does not come back.") : I18n.tr("Empty the trash")
                       onPressed: { if (shell.emptying) shell.order(["gio", "trash", "--empty"]); shell.emptying = !shell.emptying } } }
            Label { visible: shell.page === "storage" && held.data !== null; width: view.room; wrapMode: Text.WordWrap; color: Theme.dim; font.pixelSize: 13
                    text: held.data ? I18n.tr("What apps keep to be quicker takes {size}; they fill it again by themselves.", { size: shell.bytes(held.data.cache) }) : "" }
            Pill { visible: shell.page === "storage"; icon: "disc"; text: I18n.tr("Disks in the Device Manager"); onPressed: Quickshell.execDetached(["latte-app", "devices", "disks"]) }

            // the AI: one big switch for all of it, and whether LensAI's add-ons are downloaded — LensAI itself is part of
            // LatteOS, everything about the AI is set there
            Rectangle { visible: shell.page === "ai"; width: view.room; height: 132; radius: 24; color: Theme.card; border.width: 1; border.color: ai.value !== "off" ? Theme.gold : Theme.line
                Rectangle { x: 24; width: 72; height: 72; radius: 22; anchors.verticalCenter: parent.verticalCenter; color: Qt.rgba(Theme.gold.r, Theme.gold.g, Theme.gold.b, ai.value !== "off" ? 0.18 : 0.06)
                    Glyph { anchors.centerIn: parent; name: "sparkles"; font.pixelSize: 38; color: ai.value !== "off" ? Theme.gold : Theme.faint } }
                Column { x: 116; width: parent.width - 116 - 150; anchors.verticalCenter: parent.verticalCenter; spacing: 6
                    Label { text: I18n.tr("AI in LatteOS"); font.pixelSize: 22; font.weight: 800 }
                    Label { width: parent.width; wrapMode: Text.WordWrap; color: Theme.dim; font.pixelSize: 13
                            text: ai.value !== "off" ? I18n.tr("LensAI, the AI tab of LensGoo and the helpers are on. What they may do is set in LensAI.")
                                                     : I18n.tr("Turned off, nothing of LatteOS talks to an AI.") } }
                Rectangle { anchors.right: parent.right; anchors.rightMargin: 28; anchors.verticalCenter: parent.verticalCenter; width: 92; height: 50; radius: 25
                            color: ai.value !== "off" ? Theme.gold : Theme.raised
                    Rectangle { width: 40; height: 40; radius: 20; y: 5; x: ai.value !== "off" ? 47 : 5; color: ai.value !== "off" ? Theme.inkOnGold : Theme.dim
                                Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } } }
                    MouseArea { anchors.fill: parent; anchors.margins: -8; cursorShape: Qt.PointingHandCursor
                                onClicked: { ai.choose(ai.value !== "off" ? "off" : "on"); aiLater.restart(); helpers.ask(["latte-ai", "modules"]) } } } }
            Part { visible: shell.page === "ai"; width: view.room; title: I18n.tr("LensAI and its add-ons")
                   note: I18n.tr("LensAI is part of LatteOS. What it can download is installed in LensAI, each when you want it.")
                Repeater { model: shell.page === "ai" && helpers.data && helpers.data.services ? [
                        { icon: "sparkles", name: QT_TR_NOOP("LensAI"), there: true, what: I18n.tr("part of LatteOS"), page: "" },
                        { icon: "cloud", name: QT_TR_NOOP("The services' tools"), there: helpers.data.services.some(x => x.installed), page: "services",
                          what: helpers.data.services.some(x => x.installed) ? helpers.data.services.filter(x => x.installed).map(x => x.name).join(", ") : I18n.tr("none installed yet") },
                        { icon: "cpu", name: QT_TR_NOOP("The AI on this computer"), there: helpers.data.local.runtime && helpers.data.local.models > 0, page: "local",
                          what: !helpers.data.local.runtime ? I18n.tr("not installed") : I18n.tr("{n} models", { n: helpers.data.local.models }) },
                        { icon: "microphone", name: QT_TR_NOOP("Speech into text"), there: helpers.data.voice, page: "local", what: helpers.data.voice ? I18n.tr("installed") : I18n.tr("not installed") } ] : []
                    Rectangle { id: mod; required property var modelData; width: view.room; height: 62; radius: 16; color: Theme.card; opacity: ai.value === "off" ? 0.55 : 1
                        Glyph { x: 18; name: mod.modelData.icon; font.pixelSize: 22; color: Theme.gold; anchors.verticalCenter: parent.verticalCenter }
                        Column { x: 56; width: parent.width - 56 - 220; anchors.verticalCenter: parent.verticalCenter; spacing: 3
                            Label { text: I18n.tr(mod.modelData.name); font.weight: 700 }
                            Label { width: parent.width; text: mod.modelData.what; color: Theme.dim; font.pixelSize: 12; elide: Text.ElideRight } }
                        Row { anchors.right: parent.right; anchors.rightMargin: 14; anchors.verticalCenter: parent.verticalCenter; spacing: 8
                            Glyph { visible: mod.modelData.there; name: "circle-check"; font.pixelSize: 20; color: Theme.ok; anchors.verticalCenter: parent.verticalCenter }
                            Pill { visible: !mod.modelData.there; icon: "download"; strong: true; text: I18n.tr("Install in LensAI")
                                   onPressed: Quickshell.execDetached(["latte-app", "aicenter", mod.modelData.page]) } } } } }
            Pill { visible: shell.page === "ai"; implicitHeight: 48; icon: "external-link"; strong: true; text: I18n.tr("Open LensAI"); onPressed: Quickshell.execDetached(["latte-app", "aicenter"]) }

            // who the user is
            Rectangle { visible: shell.page === "me"; width: view.room; height: 150; radius: 26
                gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: Theme.raised } GradientStop { position: 1; color: Theme.card } }
                ClippingRectangle { id: face; x: 30; width: 96; height: 96; radius: 48; color: Theme.ground; anchors.verticalCenter: parent.verticalCenter
                    Glyph { anchors.centerIn: parent; name: "user"; font.pixelSize: 46; color: Theme.dim; visible: portrait.status !== Image.Ready }
                    Image { id: portrait; anchors.fill: parent; fillMode: Image.PreserveAspectCrop; sourceSize.width: 192; cache: false; source: who.data && who.data.picture ? "file://" + who.data.picture : "" } }
                Column { x: 150; anchors.verticalCenter: parent.verticalCenter; spacing: 5
                    Label { text: who.data ? who.data.name : ""; font.pixelSize: 28; font.weight: 800 }
                    Label { text: who.data ? who.data.user : ""; color: Theme.dim } } }
            Part { visible: shell.page === "me"; width: view.room; title: I18n.tr("Name"); note: I18n.tr("As the login screen and the apps call you. The name you sign in with stays.")
                Field { id: nameField; width: Math.min(360, view.room - 140); icon: "user"; hint: who.data ? who.data.name : ""; onAccepted: if (text.trim() !== "") { shell.account("SetRealName", text.trim()); text = "" } }
                Pill { strong: true; text: I18n.tr("Save"); visible: nameField.text.trim() !== ""; onPressed: { shell.account("SetRealName", nameField.text.trim()); nameField.text = "" } } }
            Part { visible: shell.page === "me"; width: view.room; title: I18n.tr("Picture"); note: I18n.tr("One of the pictures in your Pictures folder.")
                Label { visible: pictures.data !== null && pictures.data.filter(p => p.own && !p.live).length === 0; text: I18n.tr("There are no pictures in it."); color: Theme.dim }
                Repeater { model: shell.page === "me" && pictures.data ? pictures.data.filter(p => p.own && !p.live).slice(0, 24) : []
                    ClippingRectangle { id: pick; required property var modelData; width: 76; height: 76; radius: 38; color: Theme.card
                        border.width: 2; border.color: who.data && who.data.picture === modelData.path ? Theme.gold : "transparent"
                        Image { anchors.fill: parent; fillMode: Image.PreserveAspectCrop; sourceSize.width: 152; asynchronous: true; source: "file://" + pick.modelData.path }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: shell.account("SetIconFile", pick.modelData.path) } } } }
            Pill { visible: shell.page === "me"; icon: "folder"; text: I18n.tr("Another file…"); onPressed: { chooser.what = "face"; chooser.open() } }

            // the screens
            Rectangle { visible: shell.page === "displays" && shell.screenWait > 0; width: view.room; height: 64; radius: 16; color: Theme.raised; border.width: 2; border.color: Theme.gold
                Label { x: 18; text: I18n.tr("Is the picture fine? It goes back in {n} s.", { n: shell.screenWait }); font.weight: 600; anchors.verticalCenter: parent.verticalCenter }
                Row { anchors.right: parent.right; anchors.rightMargin: 14; anchors.verticalCenter: parent.verticalCenter; spacing: 8
                    Pill { text: I18n.tr("Put it back"); onPressed: shell.screensBack() }
                    Pill { strong: true; icon: "check"; text: I18n.tr("Keep it"); onPressed: shell.keepScreens() } } }
            // the pegboard: the screens as they stand, in their true sizes and gaps (the pointer crosses where two
            // edges touch); there with one screen too, as the wallpapers will have it
            // Its bottom edge is dragged to make it taller: room to put a screen above or below the main one.
            Item { id: desk; visible: shell.page === "displays"; width: view.room; height: 260; clip: true
                Rectangle { anchors.fill: parent; radius: 16; color: "transparent"; border.width: 2; border.color: Theme.line; z: 4 }
                Rectangle { z: 4; width: 48; height: 4; radius: 2; color: grow.containsMouse || grow.pressed ? Theme.gold : Theme.line
                    anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: 5 }
                MouseArea { id: grow; z: 5; anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; height: 14
                    hoverEnabled: true; preventStealing: true; cursorShape: Qt.SizeVerCursor
                    property real from: 0
                    onPressed: e => from = mapToItem(desk.parent, 0, e.y).y - desk.height
                    onPositionChanged: e => { if (pressed) desk.height = Math.max(190, Math.min(900, mapToItem(desk.parent, 0, e.y).y - from)) } }
                readonly property real x0: shell.screenList.length ? Math.min.apply(null, shell.screenList.map(m => m.x)) : 0
                readonly property real y0: shell.screenList.length ? Math.min.apply(null, shell.screenList.map(m => m.y)) : 0
                readonly property real x1: shell.screenList.length ? Math.max.apply(null, shell.screenList.map(m => m.x + shell.wide(m))) : 1
                readonly property real y1: shell.screenList.length ? Math.max.apply(null, shell.screenList.map(m => m.y + shell.tall(m))) : 1
                readonly property real room: 1.6          // space around, to drag a screen into
                // the scale of its first 260 px: made taller, it gains room, the screens stay as large
                property real zoom: 1                            // the wheel over it: closer for a finer move
                readonly property real k: zoom * Math.min(width / Math.max(1, (x1 - x0) * room), 260 / Math.max(1, (y1 - y0) * room))
                // over all of it, the wheel only: a press goes through to the screens below
                MouseArea { anchors.fill: parent; z: 6; acceptedButtons: Qt.NoButton
                    onWheel: e => desk.zoom = Math.max(0.25, Math.min(12, desk.zoom * (e.angleDelta.y > 0 ? 1.2 : 1 / 1.2))) }
                // the main screen's edges, where it is being dragged to while it is
                property bool mainAway: false
                property point mainG
                readonly property var edges: !shell.guides || !main ? shell.guides : !mainAway ? shell.guides
                    : { "top": mainG.y, "bottom": mainG.y + shell.tall(main), "left": mainG.x, "right": mainG.x + shell.wide(main) }
                readonly property real ox: (width - (x1 - x0) * k) / 2
                readonly property real oy: (height - (y1 - y0) * k) / 2
                readonly property var main: shell.screenList.find(m => m.name === shell.screenMain) || null
                // where a screen dragged to nx,ny lands: an edge near a neighbour's sticks to it
                function snap(m, nx, ny) {
                    let bx = nx, by = ny, dx = 14 / k, dy = 14 / k
                    for (const o of shell.screenList) {
                        if (o.name === m.name) continue
                        for (const c of [o.x - shell.wide(m), o.x + shell.wide(o), o.x, o.x + shell.wide(o) - shell.wide(m)])
                            if (Math.abs(c - nx) < dx) { dx = Math.abs(c - nx); bx = c }
                        for (const c of [o.y - shell.tall(m), o.y + shell.tall(o), o.y, o.y + shell.tall(o) - shell.tall(m)])
                            if (Math.abs(c - ny) < dy) { dy = Math.abs(c - ny); by = c }
                    }
                    return Qt.point(Math.round(bx), Math.round(by))
                }
                Repeater { model: ScriptModel { values: shell.screenList.map(m => m.name) }
                    Rectangle { id: scr; required property string modelData
                        readonly property var m: shell.screenList.find(x => x.name === modelData) || shell.screenList[0]
                        readonly property bool on: shell.screenHere !== null && shell.screenHere.name === modelData
                        property bool held: false
                        property bool landed: false                    // dropped: stays put until the compositor says where it is
                        property point g: Qt.point(0, 0)
                        readonly property bool free: !shell.screenList.some(o => o.name !== modelData && shell.overlap({ x: g.x, y: g.y, width: m.width, height: m.height, scale: m.scale, transform: m.transform }, o))
                        onMChanged: landed = false
                        readonly property bool away: held || landed
                        onAwayChanged: if (modelData === shell.screenMain) desk.mainAway = away
                        onGChanged: if (modelData === shell.screenMain) desk.mainG = g
                        x: desk.ox + ((held || landed ? g.x : m.x) - desk.x0) * desk.k + 3; y: desk.oy + ((held || landed ? g.y : m.y) - desk.y0) * desk.k + 3
                        z: held ? 2 : 0
                        width: shell.wide(m) * desk.k - 6; height: shell.tall(m) * desk.k - 6; radius: 14
                        color: on ? Theme.raised : Theme.card; border.width: 2; border.color: held && !free ? Theme.red : on ? Theme.gold : Theme.line
                        Behavior on x { enabled: !scr.held; NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                        Behavior on y { enabled: !scr.held; NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                        Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                        Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                        Column { anchors.centerIn: parent; spacing: 3
                            Glyph { name: shell.screenMain === scr.modelData ? "cup" : "device-desktop"; font.pixelSize: 26; color: scr.on ? Theme.gold : Theme.dim; anchors.horizontalCenter: parent.horizontalCenter }
                            Label { text: shell.screenNumber(scr.modelData) + "  ·  " + scr.modelData; font.weight: 700; anchors.horizontalCenter: parent.horizontalCenter }
                            Label { text: scr.m.width + " × " + scr.m.height; color: Theme.dim; font.pixelSize: 12; anchors.horizontalCenter: parent.horizontalCenter } }
                        MouseArea { anchors.fill: parent; cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                            property point from
                            onPressed: e => { shell.screenAt = scr.modelData; from = mapToItem(desk, e.x, e.y) }
                            onPositionChanged: e => {
                                const p = mapToItem(desk, e.x, e.y)
                                if (!scr.held && Math.abs(p.x - from.x) + Math.abs(p.y - from.y) < 6) return
                                scr.held = true
                                scr.g = desk.snap(scr.m, scr.m.x + (p.x - from.x) / desk.k, scr.m.y + (p.y - from.y) / desk.k)
                            }
                            onReleased: {
                                if (!scr.held) return
                                // a screen alone stands where it stands: it goes back
                                const moved = scr.free && shell.screenList.length > 1 && (scr.g.x !== scr.m.x || scr.g.y !== scr.m.y)
                                scr.landed = moved; scr.held = false
                                if (moved) shell.tryScreens(shell.placed(shell.screenList.map(o => o.name === scr.modelData ? Object.assign({}, o, { x: scr.g.x, y: scr.g.y }) : o), shell.screenMain))
                            } } } }
                // the main screen's edges drawn on, as on the screens themselves
                Repeater { model: desk.edges ? ["top", "bottom", "left", "right"] : []
                    Rectangle { required property string modelData
                        readonly property bool across: modelData === "top" || modelData === "bottom"
                        readonly property real at: across ? desk.oy + (desk.edges[modelData] - desk.y0) * desk.k : desk.ox + (desk.edges[modelData] - desk.x0) * desk.k
                        z: 1; color: Theme.red; opacity: 0.7
                        x: across ? 0 : at - 1; y: across ? at - 1 : 0
                        width: across ? desk.width : 2; height: across ? 2 : desk.height } } }
            Label { visible: shell.page === "displays" && shell.screenHere !== null; width: view.room; color: Theme.dim; font.pixelSize: 13
                    text: shell.screenHere ? [shell.screenHere.make, shell.screenHere.model, shell.screenHere.name].filter(s => s).join("  ·  ") + (shell.screenMain === shell.screenHere.name ? "  ·  " + I18n.tr("the main screen, where the drops are") : "") : "" }
            Part { visible: shell.page === "displays" && shell.screenHere !== null; width: view.room; title: I18n.tr("Resolution")
                Repeater { model: shell.screenHere && shell.page === "displays" ? shell.modes(shell.screenHere) : []
                    Pill { required property var modelData; text: modelData.w + " × " + modelData.h + (modelData.best ? "  " + I18n.tr("(recommended)") : ""); strong: shell.screenHere.width === modelData.w && shell.screenHere.height === modelData.h
                           onPressed: shell.changeScreen(shell.screenHere.name, { width: modelData.w, height: modelData.h, refreshRate: modelData.rates[0] }) } } }
            Part { visible: shell.page === "displays" && shell.screenHere !== null; width: view.room; title: I18n.tr("Pictures a second")
                Repeater { model: shell.screenHere && shell.page === "displays" ? (shell.modes(shell.screenHere).find(s => s.w === shell.screenHere.width && s.h === shell.screenHere.height) || { rates: [] }).rates : []
                    Pill { required property real modelData; text: Math.round(modelData) + " Hz"; strong: Math.abs(shell.screenHere.refreshRate - modelData) < 0.6
                           onPressed: shell.changeScreen(shell.screenHere.name, { refreshRate: modelData }) } } }
            Part { visible: shell.page === "displays" && shell.screenHere !== null; width: view.room; title: I18n.tr("How large things are"); note: I18n.tr("Texts, buttons and windows on this screen. A screen takes only the sizes its picture divides into.")
                Repeater { model: [1, 1.25, 1.5, 1.75, 2]
                    Pill { required property real modelData; text: Math.round(modelData * 100) + " %"; strong: shell.screenHere !== null && Math.abs(shell.screenHere.scale - modelData) < 0.07
                           onPressed: shell.changeScreen(shell.screenHere.name, { scale: modelData }) } } }
            Part { visible: shell.page === "displays" && shell.screenHere !== null; width: view.room; title: I18n.tr("Which way it is turned")
                Repeater { model: [{ t: 0, name: QT_TR_NOOP("Upright") }, { t: 1, name: QT_TR_NOOP("On its left side") }, { t: 2, name: QT_TR_NOOP("Upside down") }, { t: 3, name: QT_TR_NOOP("On its right side") }]
                    Pill { required property var modelData; text: I18n.tr(modelData.name); strong: shell.screenHere !== null && shell.screenHere.transform === modelData.t
                           onPressed: shell.changeScreen(shell.screenHere.name, { transform: modelData.t }) } } }
            Part { visible: shell.page === "displays" && (shell.screenList.length > 1 || screensWord.value === "duplicate"); width: view.room; title: I18n.tr("More than one screen")
                   note: I18n.tr("Extended, each screen is a desktop of its own. Duplicated, they all show the main one's picture.")
                Pill { icon: "layout-columns"; text: I18n.tr("Extend"); strong: screensWord.value !== "duplicate"
                       onPressed: { screensWord.value = "extend"; shell.order(["hyprctl", "eval", "latte.duplicate(false)"]) } }
                Pill { icon: "copy"; text: I18n.tr("Duplicate"); strong: screensWord.value === "duplicate"
                       onPressed: { screensWord.value = "duplicate"; shell.order(["hyprctl", "eval", "latte.duplicate(true)"]) } } }
            Part { visible: shell.page === "displays"; width: view.room; title: I18n.tr("Where it stands"); note: I18n.tr("Drag the screens in the picture above to where they stand on your desk; the pointer goes over where their edges touch. Scroll over it to zoom in for a finer move. The red lines are the main screen's edges: show them on the other screens and move a screen until they run on from the main one's edges. The main one carries the drops; every other has a window bar of its own.")
                Pill { icon: "device-desktop"; text: I18n.tr("Identify"); strong: shell.identifying; onPressed: shell.identifying = true }
                Pill { icon: shell.guideShown ? "eye-off" : "eye"; text: I18n.tr("Show the lines on the screens"); strong: shell.guideShown; onPressed: shell.guideShown = !shell.guideShown }
                Pill { icon: "cup"; text: I18n.tr("Make it the main screen"); visible: shell.screenHere !== null && shell.screenMain !== shell.screenHere.name; onPressed: shell.tryScreens(shell.placed(shell.screenList, shell.screenHere.name)) } }
            // night light: hyprsunset, through bin/latte-nightlight, which keeps the word
            Part { visible: shell.page === "displays"; width: view.room; title: I18n.tr("Night light")
                   note: I18n.tr("Warmer colours that keep the blue light down, easier on the eyes in the evening.")
                Switch { text: I18n.tr("Night light"); hint: nightWord.value === "" || nightWord.value === "off" ? I18n.tr("Off") : nightWord.value + " K"
                         on: /^\d+$/.test(nightWord.value); onPressed: shell.order(["latte-nightlight", on ? "off" : "on"]) }
                Repeater { model: [{ k: "5500", name: QT_TR_NOOP("Slight") }, { k: "4500", name: QT_TR_NOOP("Warm") }, { k: "3500", name: QT_TR_NOOP("Strong") }]
                    Pill { required property var modelData; icon: "moon"; text: I18n.tr(modelData.name); strong: nightWord.value === modelData.k
                           onPressed: shell.order(["latte-nightlight", modelData.k]) } } }

            // language, and whose dates and numbers
            Part { visible: shell.page === "language"; width: view.room; title: I18n.tr("Language"); note: I18n.tr("What the desktop and the apps speak. It changes when you sign in the next time.")
                Repeater { model: shell.page === "language" && region.data ? region.data.locales : []
                    Pill { required property var modelData; text: modelData.name + (modelData.place ? " · " + modelData.place : ""); strong: region.data.lang === modelData.id
                           onPressed: shell.order(["latte-settings", "locale", modelData.id].concat(region.data.formats ? [region.data.formats] : [])) } } }
            Part { visible: shell.page === "language"; width: view.room; title: I18n.tr("Dates, numbers and money"); note: I18n.tr("How a date, a number, a price and a sheet of paper are written, where that differs from the language.")
                Pill { text: I18n.tr("As the language"); strong: region.data !== null && region.data.formats === ""; onPressed: shell.order(["latte-settings", "locale", region.data.lang]) }
                Repeater { model: shell.page === "language" && region.data ? region.data.locales : []
                    Pill { required property var modelData; text: modelData.name + (modelData.place ? " · " + modelData.place : ""); strong: region.data.formats === modelData.id
                           onPressed: shell.order(["latte-settings", "locale", region.data.lang, modelData.id]) } } }
            Pill { visible: shell.page === "language"; icon: "keyboard"; text: I18n.tr("Keyboard layouts"); onPressed: shell.go("keyboard") }

            // the clock
            Rectangle { visible: shell.page === "time"; width: view.room; height: 150; radius: 26
                gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: Theme.raised } GradientStop { position: 1; color: Theme.card } }
                Column { x: 30; anchors.verticalCenter: parent.verticalCenter; spacing: 4
                    Label { text: shell.now.toLocaleTimeString(Qt.locale(), Locale.ShortFormat); font.pixelSize: 54; font.weight: 800 }
                    Label { text: shell.now.toLocaleDateString(Qt.locale(), Locale.LongFormat) + (clock.data ? "  ·  " + clock.data.zone.replace(/_/g, " ") : ""); color: Theme.dim } } }
            Switch { visible: shell.page === "time"; width: view.room; text: I18n.tr("Set the clock by itself"); hint: I18n.tr("From the internet. The administrator's password is asked for a change here."); on: clock.data !== null && clock.data.auto
                     onPressed: shell.order(["timedatectl", "set-ntp", on ? "false" : "true"]) }
            Part { id: zonePart; visible: shell.page === "time"; width: view.room; title: I18n.tr("Time zone"); note: I18n.tr("Type a city or a part of the world.")
                readonly property string asked: shell.plain(zoneField.text.trim()).replace(/ /g, "_")
                readonly property var shown: !clock.data ? [] : clock.data.zones.filter(z => asked !== "" ? shell.plain(z).indexOf(asked) >= 0 : z.split("/")[0] === clock.data.zone.split("/")[0]).slice(0, 80)
                Field { id: zoneField; width: Math.min(420, view.room); hint: I18n.tr("Search time zones…") }
                Item { width: view.room; height: 1 }
                Repeater { model: zonePart.shown
                    Pill { required property string modelData; text: modelData.replace(/_/g, " "); strong: clock.data.zone === modelData; onPressed: shell.order(["timedatectl", "set-timezone", modelData]) } } }

            // the keyboard
            Part { visible: shell.page === "keyboard"; width: view.room; title: I18n.tr("Keyboard layouts"); note: I18n.tr("The first is the one you type in. With more of them, Win+Space goes to the next.")
                Repeater { model: shell.page === "keyboard" && keys.data ? keys.data.current : []
                    Rectangle { id: lay; required property string modelData; required property int index; width: view.room; height: 56; radius: 16; color: Theme.card
                        border.width: 2; border.color: index === 0 ? Theme.gold : "transparent"
                        readonly property var others: keys.data.current.filter(i => i !== modelData)
                        Glyph { x: 18; name: "keyboard"; font.pixelSize: 22; color: lay.index === 0 ? Theme.gold : Theme.dim; anchors.verticalCenter: parent.verticalCenter }
                        Label { x: 54; text: shell.layoutName(lay.modelData); font.weight: 600; anchors.verticalCenter: parent.verticalCenter }
                        Row { anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter; spacing: 8
                            Pill { visible: lay.index > 0; text: I18n.tr("Make it the first"); onPressed: shell.order(["latte-settings", "keyboard", lay.modelData].concat(lay.others)) }
                            Pill { visible: lay.others.length > 0; icon: "x"; text: I18n.tr("Remove"); onPressed: shell.order(["latte-settings", "keyboard"].concat(lay.others)) } } } } }
            Part { id: layPart; visible: shell.page === "keyboard" && keys.data !== null && keys.data.current.length < 4; width: view.room; title: I18n.tr("Add a layout")
                readonly property string asked: shell.plain(layField.text.trim())
                readonly property var shown: !keys.data || asked.length < 2 ? [] : keys.data.layouts.filter(l => keys.data.current.indexOf(l.id) < 0 && shell.plain(l.name + " " + l.id).indexOf(asked) >= 0).slice(0, 40)
                Field { id: layField; width: Math.min(420, view.room); hint: I18n.tr("Search layouts: Slovak, US, Dvorak…") }
                Item { width: view.room; height: 1 }
                Repeater { model: layPart.shown
                    Pill { required property var modelData; icon: "plus"; text: modelData.name; onPressed: { const id = modelData.id; shell.order(["latte-settings", "keyboard"].concat(keys.data.current, [id])); layField.text = "" } } } }
            Part { visible: shell.page === "keyboard" && shell.expert; expertOnly: true; width: view.room; title: I18n.tr("Shortcuts"); note: I18n.tr("The mouse comes first in LatteOS: each of these is also a drop or a row of a card. Win is the Windows key.")
                Repeater { model: shell.page === "keyboard" && binds.data ? binds.data.filter(b => b.has_description) : []
                    Rectangle { id: bound; required property var modelData; width: Math.floor((view.room - 14) / 2); height: 44; radius: 12; color: Theme.card
                        Label { x: 16; width: parent.width - keyed.width - 40; text: I18n.tr(bound.modelData.description); anchors.verticalCenter: parent.verticalCenter }
                        Rectangle { id: keyed; anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter; width: keyedText.implicitWidth + 20; height: 28; radius: 8; color: Theme.ground
                            Label { id: keyedText; anchors.centerIn: parent; text: shell.pressed(bound.modelData); font.pixelSize: 12; font.weight: 700; color: Theme.gold } } } } }
            Label { visible: shell.page === "keyboard"; width: view.room; wrapMode: Text.WordWrap; color: Theme.dim; font.pixelSize: 13
                    text: I18n.tr("The login screen starts with the layouts of the whole system; there one is chosen with a click.") }

            // when it locks, when the screens go dark
            Part { visible: shell.page === "lock"; width: view.room; title: I18n.tr("Lock the session after"); note: I18n.tr("Left alone that long, the session locks; the password opens it again. A window that fills the screen keeps it awake.")
                Repeater { model: shell.waits
                    Pill { required property var modelData; text: I18n.tr(modelData.name); strong: idle.lock === modelData.s; onPressed: idle.choose(modelData.s, idle.screen) } } }
            Part { visible: shell.page === "lock"; width: view.room; title: I18n.tr("Turn the screens off after")
                Repeater { model: shell.waits
                    Pill { required property var modelData; text: I18n.tr(modelData.name); strong: idle.screen === modelData.s; onPressed: idle.choose(idle.lock, modelData.s) } } }
            Label { visible: shell.page === "lock"; width: view.room; wrapMode: Text.WordWrap; color: Theme.dim; font.pixelSize: 13
                    text: I18n.tr("The session also locks before the computer goes to sleep. Win+L locks it at once.") }

            // notifications: what a new one does. They wait in ClockGoo either way.
            Part { visible: shell.page === "notifications"; width: view.room; title: I18n.tr("When a notification comes"); note: I18n.tr("Every notification waits in ClockGoo until you have read it or cleared it.")
                Switch { width: view.room; text: I18n.tr("Do not disturb"); hint: I18n.tr("Nothing is shown and nothing sounds; notifications wait quietly."); on: goo.kept.quiet === true; onPressed: goo.set("quiet", !on) }
                Switch { width: view.room; text: I18n.tr("Show it in the corner"); hint: I18n.tr("A note for a few seconds above the right end of the bar. A press opens the notifications."); on: goo.kept.banners !== false; onPressed: goo.set("banners", !on) }
                Switch { width: view.room; text: I18n.tr("Play a sound"); hint: I18n.tr("A short, quiet tone."); on: goo.kept.notify_sound !== false; onPressed: goo.set("notify_sound", !on) } }
            Pill { visible: shell.page === "notifications"; icon: "bell"; text: I18n.tr("Try it"); onPressed: Quickshell.execDetached(["notify-send", "LatteOS", I18n.tr("This is how a notification looks.")]) }

            // the password
            Part { visible: shell.page === "password"; width: view.room; title: I18n.tr("Change your password"); note: I18n.tr("Type the new one twice. The system then asks for the present one in its own window.")
                Field { id: pass1; width: 320; icon: "lock"; secret: true; hint: I18n.tr("New password") }
                Field { id: pass2; width: 320; icon: "lock"; secret: true; hint: I18n.tr("New password again"); onAccepted: changer.pressed() }
                Item { width: view.room; height: 1 }
                Pill { id: changer; icon: "check"; strong: pass1.text !== "" && pass1.text === pass2.text; text: I18n.tr("Change password")
                       onPressed: { if (pass1.text === "" || pass1.text !== pass2.text) { shell.passSaid = I18n.tr("The two do not match."); return }
                                    shell.passSaid = ""; passer.running = false; passer.stdinEnabled = true; passer.fresh = pass1.text; passer.running = true; pass1.text = ""; pass2.text = "" } }
                Label { visible: shell.passSaid !== ""; text: shell.passSaid; color: Theme.gold; height: 36; verticalAlignment: Text.AlignVCenter } }
            Pill { visible: shell.page === "password"; icon: "lock"; text: I18n.tr("Lock and idle"); onPressed: shell.go("lock") }

            // the login screen: what it shows besides the login
            Part { visible: shell.page === "loginscreen"; width: view.room; title: I18n.tr("Under the surface"); note: I18n.tr("A crash is always shown first. Otherwise the headlines of the feeds below.")
                Pill { text: I18n.tr("News"); strong: logon.data !== null && logon.data.panel !== "none"; onPressed: shell.order(["latte-settings", "loginscreen", "panel", "news"]) }
                Pill { text: I18n.tr("Nothing"); strong: logon.data !== null && logon.data.panel === "none"; onPressed: shell.order(["latte-settings", "loginscreen", "panel", "none"]) } }
            Part { visible: shell.page === "loginscreen"; width: view.room; title: I18n.tr("News feeds"); note: I18n.tr("RSS or Atom addresses, separated by a space. Fetched at most every 15 minutes.")
                Field { id: feedField; width: Math.min(560, view.room); icon: "rss"; hint: I18n.tr("https://…"); text: logon.data ? logon.data.news_url : ""
                        onAccepted: shell.order(["latte-settings", "loginscreen", "news"].concat(feedField.text.trim().split(/\s+/).filter(u => u !== ""))) }
                Pill { icon: "check"; text: I18n.tr("Save"); onPressed: shell.order(["latte-settings", "loginscreen", "news"].concat(feedField.text.trim().split(/\s+/).filter(u => u !== ""))) } }
            Part { visible: shell.page === "loginscreen"; width: view.room; title: I18n.tr("Sky and weather"); note: logon.data && logon.data.place !== "" ? logon.data.place : I18n.tr("No place: the login screen shows no sky and no weather.")
                Field { id: placeField; width: Math.min(420, view.room); icon: "map-pin"; hint: I18n.tr("A city, e.g. Vienna"); onAccepted: shell.order(["latte-settings", "loginscreen", "place", placeField.text.trim()]) }
                Pill { icon: "search"; text: I18n.tr("Find"); onPressed: shell.order(["latte-settings", "loginscreen", "place", placeField.text.trim()]) }
                Pill { icon: "x"; text: I18n.tr("No weather"); onPressed: { placeField.text = ""; shell.order(["latte-settings", "loginscreen", "place"]) } } }
            Label { visible: shell.page === "loginscreen"; width: view.room; wrapMode: Text.WordWrap; color: Theme.dim; font.pixelSize: 13
                    text: I18n.tr("The language and the keyboard layout are chosen on the login screen itself, with a click.") }

            // power
            Part { visible: shell.page === "power"; width: view.room; title: I18n.tr("Power profile"); note: shell.profile === "" ? I18n.tr("This computer offers no power profiles.") : ""
                Repeater { model: shell.profile === "" ? [] : [{ id: "power-saver", name: QT_TR_NOOP("Power saver"), hint: QT_TR_NOOP("quiet and cool"), icon: "battery-1" },
                                   { id: "balanced", name: QT_TR_NOOP("Balanced"), hint: QT_TR_NOOP("for every day"), icon: "battery-3" },
                                   { id: "performance", name: QT_TR_NOOP("Performance"), hint: QT_TR_NOOP("everything it has"), icon: "activity" }]
                    Choice { required property var modelData; width: 190; text: I18n.tr(modelData.name); hint: I18n.tr(modelData.hint); on: shell.profile === modelData.id
                             onPressed: { setProfile.running = false; setProfile.command = ["powerprofilesctl", "set", modelData.id]; setProfile.running = true }
                             Glyph { anchors.centerIn: parent; name: parent.parent.modelData.icon; font.pixelSize: 50; color: parent.parent.on ? Theme.gold : Theme.dim } } } }
            Pill { visible: shell.page === "power"; icon: "lock"; text: I18n.tr("Lock and idle"); onPressed: shell.go("lock") }

            // about this computer
            Rectangle { visible: shell.page === "about"; width: view.room; height: 170; radius: 26
                gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: Theme.raised } GradientStop { position: 1; color: Theme.card } }
                readonly property var c: machine.data ? machine.data.computer : ({})
                readonly property string os: release.pretty
                Glyph { x: 30; name: "cup"; font.pixelSize: 70; color: Theme.gold; anchors.verticalCenter: parent.verticalCenter }
                Column { x: 130; anchors.verticalCenter: parent.verticalCenter; spacing: 5; width: parent.width - 160
                    Label { text: "LatteOS GOO"; font.pixelSize: 30; font.weight: 800 }
                    Label { text: (parent.parent.c.host || "") + (parent.parent.c.model ? "  ·  " + parent.parent.c.model : ""); color: Theme.dim; width: parent.width }
                    Label { color: Theme.dim; font.pixelSize: 13; width: parent.width
                            text: [parent.parent.os, parent.parent.c.kernel ? "Linux " + parent.parent.c.kernel : "", parent.parent.c.cpu || "", parent.parent.c.ram_gb ? parent.parent.c.ram_gb + " GB" : ""].filter(s => s !== "").join("  ·  ") } }
                // the whole of it, for whoever helps
                CopyButton { anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 20; font.pixelSize: 17
                             copy: ["LatteOS GOO", parent.c.host || "", parent.c.model || "", parent.os, parent.c.kernel ? "Linux " + parent.c.kernel : "", parent.c.cpu || "", parent.c.ram_gb ? parent.c.ram_gb + " GB" : ""].filter(s => s !== "").join("\n") } }
            Pill { visible: shell.page === "about"; icon: "cpu"; text: I18n.tr("Open the Device Manager"); onPressed: Quickshell.execDetached(["latte-app", "devices"]) }

            // how LatteOS is developed: a square for each day of the last year, as GitHub draws it, and what was changed lately
            Part { id: dev; visible: shell.page === "about" && activity.data.total > 0; width: view.room; title: I18n.tr("How LatteOS is developed")
                   readonly property var days: activity.data.days || ({})
                   readonly property int peak: Math.max(1, ...Object.values(days))
                   readonly property real cell: Math.max(8, Math.min(26, Math.floor((view.room - 96) / 53) - 3))
                   // the last 53 weeks, Monday first, from the week of today back: [{ w, d, key, n }] and where a month begins
                   readonly property var grid: {
                       const out = [], marks = [], today = new Date(); today.setHours(12, 0, 0, 0)
                       const monday = new Date(today); monday.setDate(today.getDate() - ((today.getDay() + 6) % 7))
                       const start = new Date(monday); start.setDate(monday.getDate() - 52 * 7)
                       let month = -1
                       for (let w = 0; w < 53; w++) {
                           const first = new Date(start); first.setDate(start.getDate() + w * 7)
                           if (first.getMonth() !== month) { month = first.getMonth(); marks.push({ w: w, name: Qt.formatDate(first, "MMM") }) }
                           for (let d = 0; d < 7; d++) {
                               const dt = new Date(start); dt.setDate(start.getDate() + w * 7 + d)
                               if (dt > today) continue
                               const key = Qt.formatDate(dt, "yyyy-MM-dd")
                               out.push({ w: w, d: d, key: key, n: days[key] || 0, at: dt })
                           }
                       }
                       return { cells: out, marks: marks }
                   }
                   readonly property int lastYear: Object.values(days).reduce((a, b) => a + b, 0)
                   property string hint: ""
                   function level(n) { return n <= 0 ? 0 : Math.ceil(4 * n / peak) }
                   function tone(l) { return l === 0 ? Theme.unlit : Theme.heat((l - 0.5) / 4) }      // the Monitor's colours, LatteOS's standard
                Rectangle { width: view.room; height: dev.cell * 7 + 6 * 3 + 96; radius: 18; color: Theme.card; border.width: 1; border.color: Theme.line
                    Label { x: 22; y: 16; font.pixelSize: 13; color: Theme.dim
                            text: dev.hint !== "" ? dev.hint : I18n.tr("{n} changes in all, {m} of them in the last year", { n: activity.data.total, m: dev.lastYear })
                                  + "  ·  " + (activity.data.from === "github" ? "GitHub · " + activity.data.branch : I18n.tr("as installed")) }
                    Item { x: 22; y: 44; width: parent.width - 44; height: dev.cell * 7 + 6 * 3 + 22
                        Repeater { model: dev.grid.marks
                            Label { required property var modelData; x: modelData.w * (dev.cell + 3); text: modelData.name; color: Theme.faint; font.pixelSize: 10; font.family: Theme.mono } }
                        Repeater { model: dev.grid.cells
                            Rectangle { id: sq; required property var modelData; x: modelData.w * (dev.cell + 3); y: 18 + modelData.d * (dev.cell + 3); width: dev.cell; height: dev.cell; radius: 3
                                color: dev.tone(dev.level(modelData.n)); border.width: sqHit.containsMouse ? 1 : 0; border.color: Theme.gold
                                MouseArea { id: sqHit; anchors.fill: parent; hoverEnabled: true
                                            onContainsMouseChanged: dev.hint = containsMouse ? I18n.tr("{n} changes", { n: sq.modelData.n }) + "  ·  " + Qt.formatDate(sq.modelData.at, "d. M. yyyy") : "" } } } }
                    Row { anchors.right: parent.right; anchors.rightMargin: 22; anchors.bottom: parent.bottom; anchors.bottomMargin: 14; spacing: 5
                        Label { text: I18n.tr("Less"); color: Theme.faint; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }
                        Repeater { model: 5; Rectangle { required property int index; width: 11; height: 11; radius: 3; color: dev.tone(index) } }
                        Label { text: I18n.tr("More"); color: Theme.faint; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter } } } }

            Part { visible: shell.page === "about" && (activity.data.commits || []).length > 0; width: view.room; title: I18n.tr("Latest changes")
                   note: I18n.tr("Press one to read it whole: what was changed and in which files.")
                Repeater { model: activity.data.commits || []
                    Rectangle { id: cm; required property var modelData; width: view.room; radius: 14; color: cmHit.containsMouse ? Theme.raised : Theme.card; clip: true
                        readonly property bool open: shell.openCommit === modelData.hash
                        height: cmCol.implicitHeight + 24; Behavior on height { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }
                        Column { id: cmCol; x: 16; y: 12; width: parent.width - 32; spacing: 10
                            Row { width: parent.width; spacing: 12; height: 22
                                Glyph { name: cm.open ? "chevron-down" : "chevron-right"; font.pixelSize: 14; color: Theme.dim; anchors.verticalCenter: parent.verticalCenter }
                                Label { text: cm.modelData.hash; color: Theme.gold; font.family: Theme.mono; font.pixelSize: 12; font.weight: 700; anchors.verticalCenter: parent.verticalCenter }
                                Label { width: parent.width - 220; text: cm.modelData.subject; font.weight: 600; elide: Text.ElideRight; anchors.verticalCenter: parent.verticalCenter }
                                Label { text: Qt.formatDateTime(new Date(cm.modelData.at), "d. M. hh:mm"); color: Theme.faint; font.family: Theme.mono; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter } }
                            Column { visible: cm.open; width: parent.width; spacing: 10
                                Label { text: cm.modelData.author + "  ·  " + Qt.formatDateTime(new Date(cm.modelData.at), "d. M. yyyy hh:mm"); color: Theme.dim; font.pixelSize: 12 }
                                // what its author wrote, whole
                                TextEdit { width: parent.width; readOnly: true; selectByMouse: true; wrapMode: Text.Wrap; color: Theme.cream; font.family: Theme.font; font.pixelSize: 13; selectionColor: Theme.coffee
                                           text: cm.modelData.subject + (cm.modelData.body ? "\n\n" + cm.modelData.body : "") }
                                Rectangle { width: parent.width; height: 1; color: Theme.line }
                                Repeater { model: cm.modelData.files || shell.commitFiles[cm.modelData.hash] || []
                                    Row { required property var modelData; width: cmCol.width; spacing: 10
                                        Label { width: parent.width - 120; text: parent.modelData.path; elide: Text.ElideMiddle; color: Theme.dim; font.family: Theme.mono; font.pixelSize: 12 }
                                        Label { width: 52; horizontalAlignment: Text.AlignRight; text: "+" + parent.modelData.added; color: Theme.ok; font.family: Theme.mono; font.pixelSize: 12 }
                                        Label { width: 52; horizontalAlignment: Text.AlignRight; text: "−" + parent.modelData.removed; color: Theme.red; font.family: Theme.mono; font.pixelSize: 12 } } }
                                Label { visible: cm.modelData.more > 0; text: I18n.tr("… and {n} more files", { n: cm.modelData.more }); color: Theme.faint; font.pixelSize: 12 } } }
                        MouseArea { id: cmHit; anchors.left: parent.left; anchors.right: parent.right; height: 46; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: shell.openOne(cm.modelData) } } } }

            // a page that is still to come
            Column { visible: shell.here !== null && shell.here.status !== "ready"; width: view.room; spacing: 14; topPadding: 40
                Glyph { name: shell.here ? shell.here.icon : ""; font.pixelSize: 60; color: Theme.faint }
                Label { text: I18n.tr("This page is not in LatteOS yet."); font.pixelSize: 18; font.weight: 700 }
                Label { visible: shell.here !== null && shell.here.elsewhere !== undefined; text: I18n.tr("Meanwhile it is done here:"); color: Theme.dim }
                Pill { visible: shell.here !== null && shell.here.elsewhere !== undefined; strong: true; icon: "external-link"; text: I18n.tr("Open"); onPressed: shell.elsewhere(shell.here) } }
        }
    }
}
