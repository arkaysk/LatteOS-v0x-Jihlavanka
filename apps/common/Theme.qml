// The colours and the letters of LatteOS's apps: the coffee the desktop is made of. One for every file: Theme.gold
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    // The cup: what the windows are made of. The user's choice (a word in ~/.config/latteos/cup), as the coffee is
    // what the goo is made of: "espresso" is the dark cup, "mocha" a warmer brown one, "porcelain" the light one.
    readonly property var cups: ({
        "espresso":  { ground: "#17110d", surface: "#1f1611", card: "#2a1e17", raised: "#3a2a20", line: "#4a372b", cream: "#f3ebdd", dim: "#b8a491", faint: "#8a7666", gold: "#f7c873", coffee: "#c98a55" },
        "mocha":     { ground: "#2a1f19", surface: "#32261f", card: "#3e3027", raised: "#4f3d31", line: "#624c3e", cream: "#f6eee2", dim: "#c9b5a2", faint: "#9d8775", gold: "#f7c873", coffee: "#d59a66" },
        "porcelain": { ground: "#f5eee2", surface: "#ebe2d2", card: "#fffaf1", raised: "#e6d9c5", line: "#d5c4ad", cream: "#2a170c", dim: "#6b5444", faint: "#9a8672", gold: "#b5651d", coffee: "#8a4b22" } })
    property string cup: "espresso"
    readonly property var made: cups[cup] || cups.espresso
    readonly property bool light: cup === "porcelain"
    readonly property color ground: made.ground          // what a window stands on
    readonly property color surface: made.surface
    readonly property color card: made.card
    readonly property color raised: made.raised
    readonly property color line: made.line
    readonly property color cream: made.cream            // writing
    readonly property color dim: made.dim
    readonly property color faint: made.faint
    readonly property color gold: made.gold              // what is chosen, what is pressed
    readonly property color coffee: made.coffee
    readonly property color inkOnGold: light ? "#fffaf1" : "#17110d"      // writing on what is gold
    readonly property color inkOnCoffee: "#f3ebdd"          // writing on the coffee itself, whatever the cup
    readonly property color ok: light ? "#1f8a55" : "#4cc38a"
    readonly property color red: light ? "#c8323a" : "#e5484d"
    // The glass an app's side panel is made of: what is behind the window shows through it, blurred by the
    // compositor. Which glass is the user's choice (a word in ~/.config/latteos/glass); where the compositor
    // does not blur (the lower tiers) the panel is solid, or nothing on it could be read.
    readonly property var glasses: light
        ? ({ "frost": Qt.rgba(0.96, 0.93, 0.87, 0.62), "smoke": Qt.rgba(0.90, 0.86, 0.79, 0.82), "clear": Qt.rgba(0.96, 0.93, 0.87, 0.36), "milk": Qt.rgba(1, 1, 1, 0.55) })
        : ({ "frost": Qt.rgba(0.13, 0.09, 0.07, 0.62), "smoke": Qt.rgba(0.07, 0.05, 0.04, 0.80), "clear": Qt.rgba(0.13, 0.09, 0.07, 0.36), "milk": Qt.rgba(0.36, 0.29, 0.24, 0.50) })
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
    FileView {
        path: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/latteos/cup"
        printErrors: false; watchChanges: true
        onFileChanged: reload()
        onLoaded: { const word = text().trim(); if (cups[word]) cup = word }
    }
}
