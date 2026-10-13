// The colours and the letters of LatteOS's apps: the coffee the desktop is made of. One for every file: Theme.gold
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    readonly property color ground: "#17110d"      // espresso: what a window stands on
    readonly property color surface: "#1f1611"
    readonly property color card: "#2a1e17"
    readonly property color raised: "#3a2a20"
    readonly property color line: "#4a372b"
    readonly property color cream: "#f3ebdd"        // writing
    readonly property color dim: "#b8a491"
    readonly property color faint: "#8a7666"
    readonly property color gold: "#f7c873"         // what is chosen, what is pressed
    readonly property color coffee: "#c98a55"
    readonly property color ok: "#4cc38a"
    readonly property color red: "#e5484d"
    // The glass an app's side panel is made of: what is behind the window shows through it, blurred by the
    // compositor. Which glass is the user's choice (a word in ~/.config/latteos/glass); where the compositor
    // does not blur (the lower tiers) the panel is solid, or nothing on it could be read.
    readonly property var glasses: ({ "frost": Qt.rgba(0.13, 0.09, 0.07, 0.62), "smoke": Qt.rgba(0.07, 0.05, 0.04, 0.80),
                                      "clear": Qt.rgba(0.13, 0.09, 0.07, 0.36), "milk": Qt.rgba(0.36, 0.29, 0.24, 0.50) })
    property string glass: "frost"
    readonly property bool blurred: ["full", "standard"].includes(Quickshell.env("LATTE_TIER") || "")
    readonly property color pane: blurred ? (glasses[glass] || glasses.frost) : surface
    readonly property string font: "Inter Variable"
    readonly property string icons: Icons.family

    FileView {
        path: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/latteos/glass"
        printErrors: false; watchChanges: true
        onFileChanged: reload()
        onLoaded: { const word = text().trim(); if (glasses[word]) glass = word }
    }
}
