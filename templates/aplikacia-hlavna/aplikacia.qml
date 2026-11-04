//@ pragma AppId latteos-aplikacia
// TEMPLATE — a main LatteOS app (docs/okna/SABLONY.md), as GuardCorgi, LensAI and DualBrew are made: the frame is
// apps/common/AppWindow.qml — the side of glass on the left (the app's pages), the header (its heading, tools, search,
// NET, ✕; it carries the window), what the app shows, and the coffee at the foot that moves and carries the window too.
// Copy this file into apps/ as NAME.qml, change the AppId (latteos-NAME, and a launcher system/applications/
// latteos-NAME.desktop with Exec=latte-app NAME), the pages and what each shows; FILES for every file, the texts in
// goo/lang/sk.plm (I18n.tr). Run it with `latte-app NAME [page]`.
import QtQuick
import Quickshell
import "common"

ShellRoot {
    id: shell
    readonly property var words: (Quickshell.env("LATTE_APP_ARGS") || "").split("\n").filter(w => w !== "")
    property string page: "overview"
    readonly property var pages: [{ id: "overview", name: QT_TR_NOOP("Overview"), icon: "layout-dashboard" },
                                  { id: "settings", name: QT_TR_NOOP("Settings"), icon: "settings" }]
    Component.onCompleted: if (pages.some(p => p.id === words[0])) page = words[0]

    AppWindow {
        title: "Aplikácia"
        heading: I18n.tr((shell.pages.find(p => p.id === shell.page) || shell.pages[0]).name)
        implicitWidth: 1040; implicitHeight: 720
        // the side: the app's name and its pages
        side: [
            Column { x: 14; y: 14; spacing: 4
                Row { x: 6; spacing: 10; height: 40
                    Glyph { name: "coffee"; font.pixelSize: 24; color: Theme.gold; anchors.verticalCenter: parent.verticalCenter }
                    Label { text: "Aplikácia"; font.pixelSize: 17; font.weight: 700; anchors.verticalCenter: parent.verticalCenter } }
                Item { width: 1; height: 8 }
                Repeater { model: shell.pages
                    Nav { required property var modelData; text: I18n.tr(modelData.name); icon: modelData.icon; on: shell.page === modelData.id
                          onPressed: shell.page = modelData.id } } }
        ]
        // what a page shows: cards on the ground, scrolled when long
        Scroll {
            visible: shell.page === "overview"
            Rectangle { width: parent.width; height: 120; radius: 20; color: Theme.card
                Label { x: 24; y: 24; text: I18n.tr("Overview"); font.pixelSize: 18; font.weight: 700 } }
        }
        Scroll {
            visible: shell.page === "settings"
            // the app's own settings that are many or seldom: a secondary window (templates/okno-vedlajsie) instead
            Label { text: I18n.tr("Settings") }
        }
        // `foot`: what stands in the coffee at the bottom, when the app has a lower part (DualBrew's line, its status)
        // foot: [ Label { x: 24; text: "…"; anchors.verticalCenter: parent.verticalCenter } ]
    }
}
