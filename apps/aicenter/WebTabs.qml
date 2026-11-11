// The services' own pages in LensAI, each in a tab of its own with a profile of its own (its sign-in, its cookies), as
// a browser keeps them (ROADMAP 10B.35). Nothing is put into the pages and nothing is read out of them: the user signs
// in and uses the service as on its site. Loaded only in the Quickshell that holds a web engine (bin/latte-app,
// LATTE_WEB): in the plain one the first page would take LensAI down.
//   WebTabs { current: "claude"; services: [{ id: "claude", web: "https://claude.ai/new" }, …] }
import QtQuick
import QtWebEngine
import Quickshell
import "../common"

Item {
    id: tabs
    property string current: ""
    // a second one beside it, right of it, the window shared half and half ("" alone)
    property string beside: ""
    property var services: []
    // a tab opened once stays loaded, as in a browser: going back to it finds the conversation where it was (a model,
    // not an array: a new array would make every tab again, and each would load its page anew)
    ListModel { id: opened }
    function has(id) { for (let i = 0; i < opened.count; i++) if (opened.get(i).service === id) return i; return -1 }
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
        model: opened
        WebEngineView {
            id: view
            required property string service
            readonly property string modelData: service
            readonly property bool second: tabs.split && tabs.beside === modelData
            x: second ? tabs.width / 2 + 1 : 0
            width: tabs.split ? tabs.width / 2 - 1 : tabs.width
            height: tabs.height
            visible: tabs.current === modelData || second
            // one profile per service, on disk: its sign-in is there the next time LensAI is opened, session cookies too,
            // as a browser that goes on where it was left
            WebEngineProfilePrototype { id: own; storageName: "lensai-" + view.modelData; persistentCookiesPolicy: WebEngineProfile.ForcePersistentCookies }
            // the profile only once the prototype stands: asked for in a binding (profile: own.instance()) it comes before
            // the prototype knows its name, and is one that keeps nothing (offTheRecord) — every sign-in was lost on closing.
            // Then where the tab began, once: what the user goes to afterwards is the tab's own
            Component.onCompleted: { profile = own.instance(); url = (tabs.services.find(s => s.id === modelData) || {}).web || "about:blank" }
            // a page that asks for a small window of its own (a sign-in with Google, Apple…) gets one, with the tab's
            // profile, and the page that asked still knows it (the sign-in finishes there); a link to a new window or
            // tab (a source in an answer) goes to the browser, as in any app of web pages
            onNewWindowRequested: request => {
                if (request.destination === WebEngineNewWindowRequest.InNewDialog) {
                    const w = popup.createObject(tabs, { profile: view.profile })
                    request.openIn(w.view)
                } else Qt.openUrlExternally(request.requestedUrl)
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
            onVisibleChanged: if (visible) { tabs.mark(modelData, false); tabs.progress = Qt.binding(() => view.loadProgress) }
        }
    }
    // until a tab's page first shows something, the tab says what it is doing: a first visit takes seconds (over the
    // pages, not in them: what a web view holds is not drawn above its page)
    property var shown: ({})
    property real progress: 0
    function show(id) { if (shown[id]) return; const n = Object.assign({}, shown); n[id] = true; shown = n }
    Rectangle { width: tabs.split ? tabs.width / 2 - 1 : tabs.width; height: tabs.height; z: 1; color: Theme.card
        visible: tabs.current !== "" && !tabs.shown[tabs.current]
        Waiting { anchors.centerIn: parent; text: I18n.tr("Opening {n}…", { n: (tabs.services.find(s => s.id === tabs.current) || {}).name || tabs.current }) }
        DotBar { anchors.horizontalCenter: parent.horizontalCenter; y: parent.height / 2 + 64; width: 220; height: 8; segments: 24; tint: Theme.gold; value: tabs.progress / 100 } }
}
