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
    // "wallpaper" is the fourth: the colours skwd-wall works out of the wallpaper, taken anew each time it changes
    property var fromWallpaper: null
    readonly property var made: (cup === "wallpaper" && fromWallpaper) || cups[cup] || cups.espresso
    readonly property bool light: cup === "porcelain"
    function mix(a, b, t) { const x = Qt.color(a), y = Qt.color(b); return Qt.rgba(x.r + (y.r - x.r) * t, x.g + (y.g - x.g) * t, x.b + (y.b - x.b) * t, 1).toString() }
    // LatteOS's one colour of a level in every graph (the Monitor's, DotGraph and DotBar, the development graph):
    // green low, the theme's gold in the middle, red high; what is not lit is the cream at a tenth
    function heat(t) { return t < 0.55 ? mix(ok, gold, t / 0.55) : mix(gold, red, (t - 0.55) / 0.45) }
    readonly property color unlit: Qt.rgba(cream.r, cream.g, cream.b, 0.1)
    FileView {
        id: palette
        path: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/skwd-wall-v2/colors.json"
        printErrors: false; watchChanges: true
        onFileChanged: reload()
        onLoaded: { try { const c = JSON.parse(text())
            fromWallpaper = { ground: c.background, surface: c.surface, card: c.surfaceVariant, raised: c.surfaceContainer, line: mix(c.surfaceContainer, c.outline, 0.35),
                              cream: c.surfaceText, dim: mix(c.surfaceText, c.outline, 0.6), faint: c.outline, gold: c.primary, coffee: c.tertiary } } catch (e) {} }
    }
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
    // how much of LatteOS is glass, one choice for all of it (~/.config/latteos/glass-level): 0 none, everything solid;
    // 1 a little, 2 more, 3 the most. The side panels, the windows and the AI's pages of a service follow it
    property int glassLevel: 1
    readonly property bool blurred: ["full", "standard"].includes(Quickshell.env("LATTE_TIER") || "")
    readonly property color paneGlass: glasses[glass] || glasses.frost
    readonly property color pane: blurred && glassLevel > 0 ? Qt.rgba(paneGlass.r, paneGlass.g, paneGlass.b, Math.min(0.95, Math.max(0.2, paneGlass.a + [0, 0.15, 0, -0.15][glassLevel]))) : surface
    readonly property string font: "Inter Variable"
    readonly property string mono: "JetBrains Mono"          // figures, paths, keys: what is read as data
    readonly property string icons: Icons.family

    FileView {
        id: glassWord
        path: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/latteos/glass"
        printErrors: false; watchChanges: true
        onFileChanged: reload()
        onLoaded: { const word = text().trim(); if (glasses[word]) glass = word }
    }
    FileView {
        id: levelWord
        path: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/latteos/glass-level"
        printErrors: false; watchChanges: true
        onFileChanged: reload()
        onLoaded: { const n = parseInt(text().trim()); if (n >= 0 && n <= 3) glassLevel = n }
    }
    FileView {
        id: cupWord
        path: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/latteos/cup"
        printErrors: false; watchChanges: true
        onFileChanged: reload()
        onLoaded: { const word = text().trim(); if (cups[word] || word === "wallpaper") cup = word }
    }
    // A choice that has never been made has no file yet, and a file that is not there cannot be watched: it is
    // looked for now and then, so that every open window takes the choice up when it is first made.
    Timer { interval: 2500; repeat: true; running: true; onTriggered: { if (!cupWord.loaded) cupWord.reload(); if (!glassWord.loaded) glassWord.reload(); if (!levelWord.loaded) levelWord.reload() } }
}
