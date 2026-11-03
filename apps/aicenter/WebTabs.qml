// The services' own pages in LensAI, each in a tab of its own with a profile of its own (its sign-in, its cookies), as
// a browser keeps them (ROADMAP 10B.35). Nothing is put into the pages and nothing is read out of them: the user signs
// in and uses the service as on its site. Loaded only in the Quickshell that holds a web engine (bin/latte-app,
// LATTE_WEB): in the plain one the first page would take LensAI down.
//   WebTabs { current: "claude"; services: [{ id: "claude", web: "https://claude.ai/new" }, …] }
import QtQuick
import QtWebEngine

Item {
    id: tabs
    property string current: ""
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
        if (current !== "" && has(current) < 0 && services.some(s => s.id === current)) opened.append({ service: current })
    }
    onCurrentChanged: open()
    onServicesChanged: open()
    Repeater {
        model: opened
        WebEngineView {
            id: view
            required property string service
            readonly property string modelData: service
            anchors.fill: parent
            visible: tabs.current === modelData
            // one profile per service, on disk from the start (made at once with its name, not renamed afterwards)
            WebEngineProfilePrototype { id: own; storageName: "lensai-" + view.modelData }
            profile: own.instance()
            // where it began, once: what the user goes to afterwards is the tab's own
            Component.onCompleted: url = (tabs.services.find(s => s.id === modelData) || {}).web || "about:blank"
            // a page that opens a window of its own (a sign-in with Google): in the tab itself
            // ponytail: a sign-in that needs its opener window may not finish here; then the system browser (10B.35)
            onNewWindowRequested: request => request.openIn(view)
            onIconChanged: { const i = Object.assign({}, tabs.icons); i[modelData] = String(icon); tabs.icons = i; heard() }
            onTitleChanged: heard()
            onVisibleChanged: if (visible) tabs.mark(modelData, false)
            // what a page does while it loads and finds its feet is not news: only after it has stood a while
            property bool settled: false
            Timer { id: settle; interval: 4000; onTriggered: view.settled = true }
            onLoadingChanged: r => { if (r.status === WebEngineView.LoadSucceededStatus) settle.restart(); else view.settled = false }
            function heard() { if (settled && !visible) tabs.mark(modelData, true) }
        }
    }
}
