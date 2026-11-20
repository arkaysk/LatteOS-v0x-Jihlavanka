// The icons by name, from the one table the Goo scenes use (goo/lib/icons.luau): glyphs of the icon font.
//   Text { text: Icons.of("search"); font.family: Theme.icons }
// The font itself is loaded from its file, not looked up by name: a font of the same family that the system
// happens to have (an older set of the same icons) would show other pictures for some of the names.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    readonly property string share: Quickshell.env("LATTE_SHARE") || "/usr/share/latteos"
    property var table: ({})
    readonly property string family: face.name
    FontLoader { id: face; source: "file://" + root.share + "/../fonts/latteos/tabler-icons.ttf" }

    FileView {
        path: root.share + "/goo/lib/icons.luau"
        printErrors: false
        onLoaded: {
            const found = {}
            const line = /\["([\w-]+)"\] = "\\u\{([0-9A-Fa-f]+)\}"/g
            for (let m = line.exec(text()); m; m = line.exec(text())) found[m[1]] = String.fromCodePoint(parseInt(m[2], 16))
            root.table = found
        }
    }

    function of(name) { return root.table[name] || "" }

    // Phosphor's duotone icons (the user, 20. 11.: LatteOS's icons): [behind at 20 %, before] by a Phosphor name or one
    // of ours (goo/lib/phosphor.luau), or null; Glyph draws them, Tabler's stay for the names Phosphor has no icon for
    property var duoTable: ({})
    readonly property string duoFamily: duoFace.name
    FontLoader { id: duoFace; source: "file://" + root.share + "/../fonts/latteos/Phosphor-Duotone.ttf" }
    FileView {
        path: root.share + "/goo/lib/phosphor.luau"
        printErrors: false
        onLoaded: {
            const found = {}, cp = h => h ? String.fromCodePoint(parseInt(h, 16)) : ""
            const line = /\["([\w-]+)"\] = \{ "(?:\\u\{([0-9A-Fa-f]+)\})?", "(?:\\u\{([0-9A-Fa-f]+)\})?" \}/g
            const t = text()
            for (let m = line.exec(t); m; m = line.exec(t)) found[m[1]] = [cp(m[2]), cp(m[3])]
            root.duoTable = found
        }
    }
    function duo(name) { return root.duoTable[name] || null }
}
