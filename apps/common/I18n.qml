// What an app says, in the user's language: texts are written in English and tr() looks them up in the table
// the Goo scenes use (goo/lang/<language>.plm), so a word is translated once for the whole desktop.
//   Text { text: I18n.tr("{n} a month", { n: 12 }) }
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    readonly property string share: Quickshell.env("LATTE_SHARE") || "/usr/share/latteos"
    readonly property string lang: ((Quickshell.env("LC_ALL") || Quickshell.env("LC_MESSAGES") || Quickshell.env("LANG") || "en").split(/[_.@]/)[0] || "en").toLowerCase()
    property var table: ({})

    FileView {
        path: root.lang === "en" ? "" : root.share + "/goo/lang/" + root.lang + ".plm"
        printErrors: false
        onLoaded: {
            const found = {}
            const line = /^\s*"((?:[^"\\]|\\.)*)"\s*=\s*"((?:[^"\\]|\\.)*)"\s*$/gm
            for (let m = line.exec(text()); m; m = line.exec(text())) found[m[1]] = m[2]
            root.table = found
        }
    }

    function tr(s, args) {
        let out = root.table[s] || s
        if (args) for (const k in args) out = out.split("{" + k + "}").join(String(args[k]))
        return out
    }
}
