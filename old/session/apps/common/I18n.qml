// LatteOS — prekladová vrstva aplikácií (Quickshell/QML), podľa DankMaterialShell (MIT): texty sa píšu po anglicky
// a `i18n.tr("Next")` vráti preklad z /usr/share/latteos/i18n/<jazyk>.json (plochý JSON „anglicky“ → „preklad“).
// Chýbajúci preklad = pôvodný anglický text. Jazyk: LATTE_LANG, inak LANG (latte-session ho berie z Nastavení ›
// Jazyk a región, ~/.config/latteos/locale): „sk_SK.UTF-8“ → „sk“. Bez .qm a bez prekladača Qt, preklad sa dá
// doplniť úpravou JSON. Doplnenie vlastného jazyka: skopírovať sk.json, preložiť, uložiť ako <kód>.json.
//   I18n { id: i18n }
//   Text { text: i18n.tr("Hello, {name}", { name: user }) }
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    visible: false

    readonly property string lang: {
        const l = Quickshell.env("LATTE_LANG") || Quickshell.env("LC_MESSAGES") || Quickshell.env("LANG") || "en";
        return (l.split(/[_.@]/)[0] || "en").toLowerCase();
    }
    property var table: ({})

    FileView {
        path: root.lang === "en" ? "" : "/usr/share/latteos/i18n/" + root.lang + ".json"
        printErrors: false
        onLoaded: { try { root.table = JSON.parse(text()); } catch (e) { root.table = {}; } }
    }

    // preklad s dosadením {mien}: tr("{n} apps", { n: 3 })
    // množné číslo: trn("{n} device", "{n} devices", n). Jazyk s vlastným tvarom pre 2–4 (slovenčina: 2 zariadenia,
    // 5 zariadení) ho má v preklade pod kľúčom „<many> [2-4]“; angličtina ten kľúč nemá a použije <many>.
    function trn(one, many, n, args) {
        const a = Object.assign({ n: n }, args || {});
        if (n === 1) return tr(one, a);
        const few = many + " [2-4]";
        return tr(n >= 2 && n <= 4 && root.table && root.table[few] ? few : many, a);
    }
    function tr(s, args) {
        let out = (root.table && root.table[s]) || s;
        if (args) for (const k in args) out = out.split("{" + k + "}").join(String(args[k]));
        return out;
    }
}
