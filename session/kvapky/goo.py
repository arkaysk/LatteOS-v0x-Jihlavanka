# Jedny pravidlá pre všetky kvapky (1. 10. 2026, LATTEOS-GOO.md §3): každá kvapka — DaNoGoo, QueenGoo, voľné Hodiny
# a vypínač, widgety — kreslí svoje telo DO TELA LIŠTY (jedno `body`), nie do vlastného. Iba tak sa s ostatnými
# zlieva (blend funguje len vo vnútri jedného tela), má to isté svetlo kurzora (radiálny prechod tela), sklo, lem a
# tieň. Telo lišty je v otočenej skupine (súradnice lišty), preto sa body z obrazovky prepočítajú (`L`).
# Skrytý tvar (nulový polomer / šírka) by v tele nechal bodku či vlásočnicu — `show:` v tele neskryje —, preto
# odchádza do stredu hlavy lišty (`hx, mid - 8`), kde ho nevidno.
# Použitie z generátorov: import goo; s = goo.vloz(s, "DaNoGoo", tvary, odlesky)

HEAD = ("hx", "mid - 8")


def L(x, y):
    """Bod z obrazovky do súradníc tela lišty (inverzia pick(side, …) z kvapka.plm)."""
    return (f"pick(side, {x}, W - ({x}), {y}, H - ({y}))",
            f"pick(side, ({y}) - H + edge, edge - ({y}), edge - ({x}), ({x}) - W + edge)")


def at(vis, x, y):
    """`at:` v tele lišty; neviditeľné do stredu hlavy."""
    lx, ly = L(x, y)
    return f"if({vis}, {lx}, {HEAD[0]}), if({vis}, {ly}, {HEAD[1]})"


def size(w, h):
    """Rozmer obdĺžnika z obrazovky: pri bočnej lište (otočená o 90°) sa vymení šírka a výška."""
    return f"if(side >= 2, {h}, {w}), if(side >= 2, {w}, {h})"


def kvapka(vis, x, y, r, ax, ay, nx, ny, sheet, jit="0", neck=None, blend="20"):
    """Kvapka visiaca z okraja: základňa (pás + guľa na okraji), voliteľne krk, a samotná kvapka.
    vis: kedy je kvapka vôbec (inak sa skryje do hlavy); sheet: základňa (0 = ťahaná / zdvihnutá)."""
    base = f"({vis}) and {sheet} > 0.02"
    out = [
        f"box {{ at: {at(base, ax, ay)}; size: {size(f'(70 * abs({ny}) + 20 * abs({nx})) * {sheet}', f'(20 * abs({ny}) + 70 * abs({nx})) * {sheet}')}; corner: 10 }}",
        f"ellipse {{ at: {at(base, ax, ay)}; radius: 24 * {sheet}; blend: 16 * {sheet} }}",
    ]
    if neck:
        nv = f"({vis}) and {neck} > 0.5"
        tx, ty = L(x, y)
        out.append(f"line {{ from: {at(nv, ax, ay)}; to: if({nv}, {tx}, {HEAD[0]}), if({nv}, {ty}, {HEAD[1]}); width: {neck}; blend: 12 }}")
    out.append(f"ellipse {{ at: {at(vis, x, y)}; radius: {r}; scale: 1 + {jit}, 1 - {jit}; blend: {blend} }}")
    return out


def odlesk(vis, x, y, r):
    """To isté svetlo ako guľôčky lišty: pasívny odlesk hore vľavo a aktívny na strane ku kurzoru (cu, cv)."""
    lx, ly = L(x, y)
    d = f"length(cu - {lx}, cv - {ly})"
    return [
        f"ellipse {{ at: if({vis}, {lx}, {HEAD[0]}) - ({r}) * 0.4, if({vis}, {ly}, {HEAD[1]}) - ({r}) * 0.52; radius: 0.11 * ({r}) * if({vis}, 1, 0); scale: 1.5, 0.8; rotate: -30deg; color: #fff6ea }}",
        f"ellipse {{ at: {lx} + (cu - {lx}) / max({d}, 1) * ({r}) * 0.55, {ly} + (cv - {ly}) / max({d}, 1) * ({r}) * 0.55; radius: 0.13 * ({r}) * if({vis}, 1, 0) * (1 - smooth(50, 360, {d})); color: #ffe4bd }}",
    ]


BODY_END = "            // ── koniec kvapiek v tele lišty (goo.py)\n"
GLINT_END = "            // ── koniec odleskov kvapiek (goo.py)\n"


def _kotvy(s):
    """Raz: kotvy na konci tela lišty a skupina odleskov kvapiek za odleskami lišty."""
    if BODY_END not in s:
        i = s.index("            // hladina: prehnutie pod Hodinami")
        j = s.index("\n        }\n", i) + 1          # koniec tela lišty
        s = s[:j] + BODY_END + s[j:]
    if GLINT_END not in s:
        i = s.index("            // hlava a Hodiny: to isté\n")
        j = s.index("\n        }\n", i) + len("\n        }\n")   # koniec skupiny odleskov lišty
        s = (s[:j] + "        // odlesky kvapiek (goo.py): ako guľôčky lišty, ale viditeľné aj keď sa lišta presúva (ap)\n"
             "        group {\n            blur: 1.5\n            opacity: 70% * so\n" + GLINT_END + "        }\n" + s[j:])
    return s


def vloz(s, meno, tvary, odlesky):
    """Vloží (alebo nahradí) tvary kvapky `meno` do tela lišty a jej odlesky do skupiny odleskov."""
    s = _kotvy(s)
    for koniec, riadky, kde in ((BODY_END, tvary, "telo"), (GLINT_END, odlesky, "odlesk")):
        A = f"            // >>> {meno} ({kde}, goo.py)\n"
        B = f"            // <<< {meno} ({kde})\n"
        blok = A + "".join(f"            {r}\n" for r in riadky) + B
        if A in s:
            i = s.index(A); j = s.index(B, i) + len(B)
            s = s[:i] + blok + s[j:]
        else:
            i = s.index(koniec)
            s = s[:i] + blok + s[i:]
    return s
