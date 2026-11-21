// The services' own pages in LensAI, each in a tab of its own with a profile of its own (its sign-in, its cookies), as
// a browser keeps them (ROADMAP 10B.35). Nothing is put into the pages and nothing is read out of them: the user signs
// in and uses the service as on its site. Loaded only in the Quickshell that holds a web engine (bin/latte-app,
// LATTE_WEB): in the plain one the first page would take LensAI down.
//   WebTabs { current: "claude"; services: [{ id: "claude", web: "https://claude.ai/new" }, …] }
import QtQuick
import QtWebEngine
import Quickshell
import Quickshell.Io
import "../common"

Item {
    id: tabs
    // agentgram in LatteOS's colours, not its own pale blue (the user, 21. 11.): its design tokens (packages/ui tokens.css) set
    // anew over its light and its dark, a grain under its ground and soft changes on what is pressed. Only in LensAI's tab:
    // the fork itself stays as agentes-chat draws it, so an unforked one is the same
    function rgba(c) { return "rgba(" + Math.round(c.r * 255) + "," + Math.round(c.g * 255) + "," + Math.round(c.b * 255) + "," + c.a.toFixed(3) + ")" }
    function mix(a, b, t) { return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1) }
    function skin(view) {
        const m = Theme.made, ink = Qt.color(m.cream), gold = Qt.color(m.gold), ground = Qt.color(m.ground), card = Qt.color(m.card), raised = Qt.color(m.raised)
        const v = { "--bg": ground, "--raised": card, "--sunken": mix(ground, ink, 0.04), "--side": mix(ground, gold, 0.05), "--pane": card,
                    "--glass": Qt.rgba(card.r, card.g, card.b, 0.9), "--glass-solid": card, "--line": Qt.rgba(ink.r, ink.g, ink.b, 0.09),
                    "--line-strong": Qt.color(m.faint), "--ink": ink, "--muted": Qt.color(m.dim), "--faint": Qt.color(m.faint),
                    "--agent": gold, "--agent-soft": mix(card, gold, 0.16), "--on-agent": Qt.color(Theme.inkOnGold),
                    "--chosen-bg": mix(raised, gold, 0.10), "--ok": Qt.color(Theme.ok), "--danger": Qt.color(Theme.red) }
        let vars = ""
        for (const k in v) vars += k + ":" + tabs.rgba(v[k]) + " !important;"
        const grain = "url(\"data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='160' height='160'><filter id='n'><feTurbulence type='fractalNoise' baseFrequency='.9' numOctaves='2' stitchTiles='stitch'/><feColorMatrix values='0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 .045 0'/></filter><rect width='100%' height='100%' filter='url(%23n)'/></svg>\")"
        const css = ":root,[data-theme],[data-theme='light'],[data-theme='dark']{" + vars + "}"
                  + "body{background-image:" + grain + " !important;background-attachment:fixed}"
                  + "a,button,[role='button'],[role='menuitem'],[role='tab'],input,textarea,select{transition:background-color .16s ease,color .16s ease,border-color .16s ease,box-shadow .2s ease,transform .12s ease}"
                  + "button:active:not(:disabled),[role='button']:active{transform:scale(.97)}"
                  + "@keyframes latte-in{from{opacity:0;transform:translateY(4px)}to{opacity:1;transform:none}}"
                  + "[role='dialog'],[role='menu'],[role='listbox']{animation:latte-in .16s ease-out}"
                  + "@media (prefers-reduced-motion:reduce){*{transition:none !important;animation:none !important}}"
        const s = WebEngine.script()
        s.name = "latteos-skin"
        s.injectionPoint = WebEngineScript.DocumentReady
        s.worldId = WebEngineScript.ApplicationWorld
        s.runsOnSubFrames = false
        s.sourceCode = "(function(){var e=document.createElement('style');e.id='latteos-skin';e.textContent=" + JSON.stringify(css) + ";document.documentElement.appendChild(e)})()"
        view.userScripts.insert(s)
    }
    property string current: ""
    // a second one beside it, right of it, the window shared half and half ("" alone)
    property string beside: ""
    property var services: []
    // a tab opened once stays loaded, as in a browser: going back to it finds the conversation where it was (a model,
    // not an array: a new array would make every tab again, and each would load its page anew)
    ListModel { id: opened }
    function has(id) { for (let i = 0; i < opened.count; i++) if (opened.get(i).service === id) return i; return -1 }
    // a page of its service in a tab already open (agentgram's code to confirm); a tab not open yet starts at its web
    // F5 / Ctrl+R: the page shown loaded again, as in any browser (a web app that was updated, a page that hangs)
    Shortcut { sequences: [StandardKey.Refresh, "Ctrl+R"]; enabled: tabs.visible && tabs.current !== ""
               onActivated: { for (let i = 0; i < views.count; i++) { const v = views.itemAt(i); if (v && v.modelData === tabs.current) v.reload() } } }
    function load(id, url) { for (let i = 0; i < views.count; i++) { const v = views.itemAt(i); if (v && v.modelData === id) { v.url = url; return } } }
    // each open tab's own icon, as its page gives it (its favicon): { claude: "image://favicon/…" }
    property var icons: ({})
    // a tab out of sight whose page has something new: it changed its title or its icon (a reply finished, a message
    // came), the only things a page says out loud; what it shows is never read. Gone when the tab is looked at
    property var news: ({})
    function mark(id, on) { if (!!news[id] === on) return; const n = Object.assign({}, news); n[id] = on; news = n }
    // (only once its address is known: LensAI may be asked for a tab before it knows the services)
    function open() {
        for (let i = opened.count - 1; i >= 0; i--) if (!services.some(s => s.id === opened.get(i).service)) opened.remove(i)      // taken off the list
        for (const id of [current, beside]) if (id !== "" && has(id) < 0 && services.some(s => s.id === id)) opened.append({ service: id })
    }
    onCurrentChanged: open()
    onBesideChanged: open()
    readonly property bool split: beside !== "" && beside !== current && current !== ""
    onServicesChanged: open()
    // pages to make ready behind before they are asked for, one every second and a half (all at once would make the window
    // wait); a page loaded out of sight shows at once when its tab is chosen
    property var warm: []
    Timer { interval: 1500; repeat: true; running: tabs.warm.some(id => tabs.has(id) < 0 && tabs.services.some(s => s.id === id))
            onTriggered: { const id = tabs.warm.find(x => tabs.has(x) < 0 && tabs.services.some(s => s.id === x)); if (id) opened.append({ service: id }) } }
    // ── sleep (ROADMAP 10B.65, approved 17. 11.): Qt WebEngine's lifecycle in two steps, as its lifecycle example does it,
    // with the rule of Vivaldi's Memory Saver and Ferdium's hibernation — the less a service is used, the sooner it sleeps.
    // The two used most this week stay awake (their news still comes); another, out of sight 5 min, is frozen (its
    // scripts stop, it comes back at once), after 15 min discarded (its memory goes back; it loads again when it is
    // chosen, its last picture shown meanwhile)
    // the times are the user's (LensAI › Settings › Web, ~/.config/latteos/lensai-web.json; 0 = never), and a tab marked
    // "awake" never sleeps
    property var sleep: ({ keep: 2, freeze: 5, discard: 15 })
    FileView { printErrors: false; watchChanges: true; onFileChanged: reload()
               path: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/latteos/lensai-web.json"
               onLoaded: { try { tabs.sleep = Object.assign({ keep: 2, freeze: 5, discard: 15 }, JSON.parse(text())) } catch (e) {} } }
    readonly property int keepAwake: sleep.keep
    readonly property int freezeAfter: sleep.freeze > 0 ? sleep.freeze * 60000 : 1e12
    readonly property int discardAfter: sleep.discard > 0 ? sleep.discard * 60000 : 1e12
    // when each service was opened, the last seven days: { claude: [ms, …] }, kept for the next time
    property var use: ({})
    FileView { id: useFile; printErrors: false; blockLoading: true
               path: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/latteos/ai/tabs-use.json"
               onLoaded: { try { tabs.use = JSON.parse(text()) } catch (e) { tabs.use = ({}) } } }
    function used(id) {
        const week = Date.now() - 7 * 86400000, u = Object.assign({}, use)
        u[id] = (u[id] || []).filter(t => t > week).concat([Date.now()]).slice(-200)
        use = u; useFile.setText(JSON.stringify(u))
    }
    function awake() {         // the services that never sleep: the most opened this week, the latest first on a tie
        const week = Date.now() - 7 * 86400000, n = id => (use[id] || []).filter(t => t > week).length,
              last = id => (use[id] || []).slice(-1)[0] || 0
        return services.map(x => x.id).sort((a, b) => n(b) - n(a) || last(b) - last(a)).slice(0, keepAwake)
                       .concat(services.filter(x => x.awake).map(x => x.id))
    }
    property var pictures: ({})       // the last picture of each discarded page, shown while it loads again
    Timer { interval: 30000; repeat: true; running: opened.count > 0
            onTriggered: { const keep = tabs.awake(), now = Date.now()
                           for (let i = 0; i < views.count; i++) { const v = views.itemAt(i); if (v) v.rest(keep, now) } } }
    // the small window a page asks for, until the page in it closes it (or the person does)
    Component {
        id: popup
        FloatingWindow {
            id: win
            property alias view: page
            property alias profile: page.profile
            implicitWidth: 520; implicitHeight: 700
            title: page.title
            color: "white"
            onClosed: win.destroy()
            WebEngineView { id: page; anchors.fill: parent; onWindowCloseRequested: win.destroy() }
        }
    }
    Repeater {
        id: views
        model: opened
        WebEngineView {
            id: view
            required property string service
            readonly property string modelData: service
            readonly property bool second: tabs.split && tabs.beside === modelData
            x: second ? tabs.width / 2 + 1 : 0
            width: tabs.split ? tabs.width / 2 - 1 : tabs.width
            height: tabs.height
            backgroundColor: Theme.card              // until a page (or one woken from sleep) paints: the app's own, not a white or black flash
            visible: tabs.current === modelData || second
            // one profile per service, on disk: its sign-in is there the next time LensAI is opened, session cookies too,
            // as a browser that goes on where it was left
            WebEngineProfilePrototype { id: own; storageName: "lensai-" + view.modelData; persistentCookiesPolicy: WebEngineProfile.ForcePersistentCookies }
            // the profile only once the prototype stands: asked for in a binding (profile: own.instance()) it comes before
            // the prototype knows its name, and is one that keeps nothing (offTheRecord) — every sign-in was lost on closing.
            // Then where the tab began, once: what the user goes to afterwards is the tab's own
            Component.onCompleted: { profile = own.instance(); if (modelData.startsWith("agentgram")) tabs.skin(view)
                                     url = (tabs.services.find(s => s.id === modelData) || {}).web || "about:blank" }
            // a page that asks for a small window of its own (a sign-in with Google, Apple…) gets one, with the tab's
            // profile, and the page that asked still knows it (the sign-in finishes there); a link to a new window or
            // tab (a source in an answer) goes to the browser, as in any app of web pages
            onNewWindowRequested: request => {
                const u = String(request.requestedUrl)
                // LatteOS's own links only from agentgram's own tab: another page cannot pair this computer or open folders
                // (security audit 21. 11., S3); ponytail: no confirmation yet when agentgram itself asks to pair
                const mine = view.modelData.startsWith("agentgram")
                if (!mine && /^(latteos|agenteschat):/.test(u)) return
                // agentgram's "Open folder" (latteos://agentgram/folder?path=…): the project's folder in Files (latte-ai keeps
                // it to ~/LensAI/agentgram, whatever the page asks)
                if (u.startsWith("latteos://agentgram/folder?")) {
                    const m = u.match(/[?&]path=([^&]+)/)
                    if (m) Quickshell.execDetached(["latte-ai", "agentgram", "folder", decodeURIComponent(m[1])])
                    return
                }
                // agentgram's "Connect this computer" (its desktop app's link, agenteschat://pair?server=&link=): LatteOS
                // connects this computer itself, with the AIs it is signed in to; the page then asks to let it join
                if (u.startsWith("agenteschat://pair?")) {
                    const m = u.match(/[?&]link=([A-Za-z0-9-]{4,40})/)
                    if (m) Quickshell.execDetached(["latte-ai", "agentgram", "pair", "--link", m[1]])
                    return
                }
                if (request.destination === WebEngineNewWindowRequest.InNewDialog) {
                    const w = popup.createObject(tabs, { profile: view.profile })
                    request.openIn(w.view)
                } else Quickshell.execDetached(["latte-open", String(request.requestedUrl)])
            }
            onIconChanged: { const i = Object.assign({}, tabs.icons); i[modelData] = String(icon); tabs.icons = i; heard() }
            onTitleChanged: heard()
            // what a page does while it loads and finds its feet is not news: only after it has stood a while
            property bool settled: false
            Timer { id: settle; interval: 4000; onTriggered: view.settled = true }
            onLoadingChanged: r => { if (r.status === WebEngineView.LoadSucceededStatus) settle.restart(); else view.settled = false
                                     if (r.status === WebEngineView.LoadSucceededStatus || r.status === WebEngineView.LoadFailedStatus) tabs.show(view.modelData) }
            function heard() { if (settled && !visible) tabs.mark(modelData, true) }
            onLoadProgressChanged: if (loadProgress >= 80) tabs.show(modelData)
            onVisibleChanged: { hidden = visible ? 0 : Date.now()
                                if (visible) { tabs.used(modelData); lifecycleState = WebEngineView.LifecycleState.Active
                                               tabs.mark(modelData, false); tabs.progress = Qt.binding(() => view.loadProgress) } }
            property real hidden: Date.now()          // since when it is out of sight (0: seen now)
            // its picture, taken while it is seen (one out of sight draws nothing): what stands in its place if it is discarded
            Timer { interval: 20000; repeat: true; running: view.visible && view.settled; triggeredOnStart: true
                    onTriggered: view.grabToImage(r => { const p = Object.assign({}, tabs.pictures); p[view.modelData] = r.url; tabs.pictures = p }) }
            function rest(keep, now) {
                if (visible || hidden === 0 || keep.indexOf(modelData) >= 0) return
                if (now - hidden > tabs.discardAfter && lifecycleState !== WebEngineView.LifecycleState.Discarded) {
                    const n = Object.assign({}, tabs.shown); delete n[modelData]; tabs.shown = n      // the cover again until it is back
                    lifecycleState = WebEngineView.LifecycleState.Discarded
                } else if (now - hidden > tabs.freezeAfter && lifecycleState === WebEngineView.LifecycleState.Active)
                    lifecycleState = WebEngineView.LifecycleState.Frozen
            }
        }
    }
    // until a tab's page first shows something, the tab says what it is doing: a first visit takes seconds (over the
    // pages, not in them: what a web view holds is not drawn above its page)
    property var shown: ({})
    property real progress: 0
    function show(id) { if (shown[id]) return; const n = Object.assign({}, shown); n[id] = true; shown = n }
    Rectangle { width: tabs.split ? tabs.width / 2 - 1 : tabs.width; height: tabs.height; z: 1; color: Theme.card
        visible: tabs.current !== "" && !tabs.shown[tabs.current]
        Image { anchors.fill: parent; source: tabs.pictures[tabs.current] || ""; visible: source != ""; opacity: 0.55; fillMode: Image.PreserveAspectCrop }
        Waiting { anchors.centerIn: parent; text: I18n.tr("Opening {n}…", { n: (tabs.services.find(s => s.id === tabs.current) || {}).name || tabs.current }) }
        DotBar { anchors.horizontalCenter: parent.horizontalCenter; y: parent.height / 2 + 64; width: 220; height: 8; segments: 24; tint: Theme.gold; value: tabs.progress / 100 } }
}
