// The icons by name, from the one table the Goo scenes use (goo/lib/icons.luau): glyphs of the icon font.
//   Text { text: Icons.of("search"); font.family: Theme.icons }
// Qt draws only parts of a few of the font's outlines ("world", "arrow-left"): an app uses another of the
// kind ("world-www", "chevron-left") and looks at each icon it adds.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    readonly property string share: Quickshell.env("LATTE_SHARE") || "/usr/share/latteos"
    property var table: ({})

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
}
