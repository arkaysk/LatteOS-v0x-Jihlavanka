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
    // a tab opened once stays loaded, as in a browser: going back to it finds the conversation where it was
    property var opened: []
    // each open tab's own icon, as its page gives it (its favicon): { claude: "image://favicon/…" }
    property var icons: ({})
    // (only once its address is known: LensAI may be asked for a tab before it knows the services)
    function open() {
        if (opened.some(o => !services.some(s => s.id === o))) opened = opened.filter(o => services.some(s => s.id === o))      // taken off the list
        if (current !== "" && opened.indexOf(current) < 0 && services.some(s => s.id === current)) opened = opened.concat([current])
    }
    onCurrentChanged: open()
    onServicesChanged: open()
    Repeater {
        model: tabs.opened
        WebEngineView {
            id: view
            required property string modelData
            anchors.fill: parent
            visible: tabs.current === modelData
            profile: WebEngineProfile { storageName: "lensai-" + view.modelData; offTheRecord: false }
            // where it began, once: what the user goes to afterwards is the tab's own
            Component.onCompleted: url = (tabs.services.find(s => s.id === modelData) || {}).web || "about:blank"
            // a page that opens a window of its own (a sign-in with Google): in the tab itself
            // ponytail: a sign-in that needs its opener window may not finish here; then the system browser (10B.35)
            onNewWindowRequested: request => request.openIn(view)
            onIconChanged: { const i = Object.assign({}, tabs.icons); i[modelData] = String(icon); tabs.icons = i }
        }
    }
}
