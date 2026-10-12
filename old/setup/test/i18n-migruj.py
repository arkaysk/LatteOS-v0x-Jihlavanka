#!/usr/bin/env python3
"""i18n-migruj.py — pomôcka na prechod aplikácií LatteOS (QML) z textov natvrdo po slovensky na i18n.tr().

  i18n-migruj.py zoznam SÚBOR.qml            vypíše texty, ktoré sú ešte natvrdo (JSON: text → ""), na doplnenie angličtiny
  i18n-migruj.py pouzi SÚBOR.qml MAPA.json   "slovensky" → i18n.tr("English") v súbore a English → slovensky do sk.json
  i18n-migruj.py stav                        koľko textov natvrdo ostáva v každej aplikácii

MAPA.json je objekt { "slovenský text presne ako v zdrojáku": "English text" }; prázdna hodnota = nechať tak.
Zamieňajú sa iba celé reťazce v úvodzovkách; texty skladané z častí ("Plocha " + i) treba upraviť ručne na
i18n.tr("Desktop {n}", { n: i }). Titulky okien („… — LatteOS“) sa neprekladajú: podľa nich sa okná rozpoznávajú.
Súbor musí mať v dosahu `I18n { id: i18n }` (vlastný, alebo z okna, v ktorom je komponent vložený).
"""
import collections, json, os, re, sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
APPS = os.path.join(REPO, "session", "apps")
SK = os.path.join(REPO, "session", "i18n", "sk.json")
LIT = re.compile(r'"((?:[^"\\\n]|\\.)*)"')
DIA = re.compile(r"[áäčďéíĺľňóôŕšťúýžÁÄČĎÉÍĹĽŇÓÔŔŠŤÚÝŽ]")


def hard(text):
    """slovenské reťazce natvrdo: (riadok, text); bez komentárov, bez už preložených a bez titulkov okien"""
    out = []
    for no, line in enumerate(text.splitlines(), 1):
        code = re.sub(r"^\s*//.*$", "", line)
        for m in LIT.finditer(code):
            s = m.group(1)
            if not DIA.search(s) or "— LatteOS" in s:
                continue
            if code[:m.start()].rstrip().endswith("i18n.tr(") or re.search(r"//[^\"]*$", code[:m.start()]):
                continue
            out.append((no, s))
    return out


def cmd_zoznam(path):
    seen = collections.OrderedDict()
    for _, s in hard(open(path, encoding="utf-8").read()):
        seen.setdefault(s, "")
    print(json.dumps(seen, ensure_ascii=False, indent=1))


def cmd_pouzi(path, mapa):
    m = {k: v for k, v in json.load(open(mapa, encoding="utf-8")).items() if v}
    text = open(path, encoding="utf-8").read()
    sk = json.load(open(SK, encoding="utf-8"), object_pairs_hook=collections.OrderedDict)
    n = 0
    lines = text.split("\n")
    for i, line in enumerate(lines):
        if re.match(r"^\s*//", line):
            continue

        def rep(mm):
            nonlocal n
            s = mm.group(1)
            before = line[:mm.start()]
            if s not in m or before.rstrip().endswith("i18n.tr(") or re.search(r"//[^\"]*$", before):
                return mm.group(0)
            en = m[s]
            old = sk.get(en)
            if old is not None and old != s:
                sys.exit("!! „%s“ má už v sk.json iný preklad: „%s“ ≠ „%s“ — zvoľ iný anglický text" % (en, old, s))
            sk[en] = s
            n += 1
            return 'i18n.tr("%s")' % en.replace("\\", "\\\\").replace('"', '\\"')
        lines[i] = LIT.sub(rep, line)
    open(path, "w", encoding="utf-8").write("\n".join(lines))
    json.dump(sk, open(SK, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    open(SK, "a").write("\n")
    left = hard("\n".join(lines))
    print("%s: zamenených %d, natvrdo ostáva %d" % (os.path.relpath(path, REPO), n, len(left)))
    for no, s in left:
        print("   %4d  %s" % (no, s[:110]))


def cmd_stav():
    total = 0
    rows = []
    for d, _, files in os.walk(APPS):
        for f in files:
            if f.endswith(".qml"):
                p = os.path.join(d, f)
                k = len(hard(open(p, encoding="utf-8").read()))
                total += k
                if k:
                    rows.append((k, os.path.relpath(p, APPS)))
    for k, p in sorted(rows, reverse=True):
        print("%5d  %s" % (k, p))
    print("%5d  spolu" % total)


def main(a):
    if a[:1] == ["zoznam"] and len(a) == 2:
        return cmd_zoznam(a[1])
    if a[:1] == ["pouzi"] and len(a) == 3:
        return cmd_pouzi(a[1], a[2])
    if a[:1] == ["stav"]:
        return cmd_stav()
    print(__doc__, file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
