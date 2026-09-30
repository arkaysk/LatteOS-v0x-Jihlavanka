#!/usr/bin/env python3
# Sliz v kvapka.plm (1. 10. 2026, LATTEOS-GOO.md 3): nezávislá mechanika Goo — keď sa kvapka zdvihne (TimeGoo ucho,
# PowerGoo ucho, DaNoGoo, QueenGoo), ťahá lepkavé vlákna k okraju pod sebou a ku kvapkám, ktoré sú práve blízko a
# ležia pri okraji (Hodiny, vypínač, hlava lišty, DaNoGoo, kráľovná). Používateľ si kvapky rozloží, ako chce —
# tvar slizu vznikne vždy z okolia: sila zväzku podľa vzdialenosti, vlákna pri koncoch hrubé a zliate, v strede tenké,
# každé sa kýve po svojom. Goo telo nedovolí `repeat`, preto tento skript vypíše blok medzi značky
#   // >>> sliz (sliz.py) … // <<< sliz
# Použitie: python3 session/kvapky/sliz.py
import os

HERE = os.path.dirname(os.path.abspath(__file__))
PLM = os.path.join(HERE, "kvapka.plm")
R_FAR, R_NEAR = 300, 110          # zväzok k susedovi: od 300 px slabne, pod 110 px plný

# zdroje: meno, poloha, ako veľmi je zdvihnutý (0..1), koreň na okraji pod ním, smer pozdĺž okraja
SRC = [
    ("tg", "db.x", "db.y", "if(esnap, 0, 1) * smooth(0.05, 0.45, dsw)", "pick(side, cxs, cxs, 0, W)", "pick(side, H, 0, cys, cys)", "abs(away.y)", "abs(away.x)"),
    ("pg", "pb.x", "pb.y", "smooth(0.05, 0.45, p.swim)", "pick(side, pxs, pxs, 0, W)", "pick(side, H, 0, pys, pys)", "abs(away.y)", "abs(away.x)"),
    ("dn", "dn.x", "dn.y", "smooth(0.08, 0.6, dn.lift)", "dn.ax", "dn.ay", "abs(dn.ny)", "abs(dn.nx)"),
    ("qg", "qg.x", "qg.y", "smooth(0.08, 0.6, qg.lift)", "qg.ax", "qg.ay", "abs(qg.ny)", "abs(qg.nx)"),
]
# kotvy: kvapky ležiace pri okraji; (meno, poloha, ako veľmi leží — 0 ak sa sama zdvihla, zdroj, ktorý je ňou)
ANC = [
    ("tg", "cxs", "cys", "1 - smooth(0, 0.3, dsw)"),
    ("pg", "pxs", "pys", "1 - smooth(0, 0.3, pm)"),
    ("hd", "pick(side, hx, W - hx, edge - mid, W - edge + mid)", "pick(side, mid + H - edge, edge - mid, hx, H - hx)", "1"),
    ("dn", "dn.x", "dn.y", "1 - dn.lift"),
    ("qg", "qg.x", "qg.y", "1 - qg.lift"),
]
FAN = [(-58, 7), (-24, 9), (18, 8), (52, 7)]      # vejár k okraju: päta pozdĺž okraja, hrúbka pri konci

L = []
a = L.append
a('''    // >>> sliz (sliz.py)
    // Sliz: zdvihnutá kvapka ťahá lepkavé vlákna k okraju a ku kvapkám v okolí (tvar z rozloženia používateľa).
''')
lets, shapes = [], []
def strand(name, ax, ay, bx, by, w, sway_seed):
    """vlákno z A do B: pri koncoch hrubé (zliate), v strede tenké, prehnuté a kývajúce sa kolmo na smer"""
    lets.append(f"""    let {name}.d = max(length({bx} - {ax}, {by} - {ay}), 1)
    let {name}.px = 0 - ({by} - {ay}) / {name}.d
    let {name}.py = ({bx} - {ax}) / {name}.d
    let {name}.sw = (8 * noise(time * 0.45 + {sway_seed:.1f}) + 3 * sin(time * 1.3 + {sway_seed * 0.7:.1f})) * min({name}.d / 120, 1.4)
    let {name}.qx = ({ax}) * 0.72 + ({bx}) * 0.28 + {name}.px * {name}.sw * 0.6
    let {name}.qy = ({ay}) * 0.72 + ({by}) * 0.28 + {name}.py * {name}.sw * 0.6
    let {name}.mx = ({ax}) * 0.5 + ({bx}) * 0.5 + {name}.px * {name}.sw
    let {name}.my = ({ay}) * 0.5 + ({by}) * 0.5 + {name}.py * {name}.sw
    let {name}.rx = ({ax}) * 0.28 + ({bx}) * 0.72 + {name}.px * {name}.sw * 0.6
    let {name}.ry = ({ay}) * 0.28 + ({by}) * 0.72 + {name}.py * {name}.sw * 0.6
""")
    shapes.append(f"""        ellipse {{ at: {ax}, {ay}; radius: {w} * 0.8; blend: 8 * clamp({w}, 0, 1) }}
        line {{ from: {ax}, {ay}; to: {name}.qx, {name}.qy; width: {w}; blend: 7 * clamp({w}, 0, 1) }}
        line {{ from: {name}.qx, {name}.qy; to: {name}.mx, {name}.my; width: {w} * 0.5; blend: 4 * clamp({w}, 0, 1) }}
        line {{ from: {name}.mx, {name}.my; to: {name}.rx, {name}.ry; width: {w} * 0.5; blend: 4 * clamp({w}, 0, 1) }}
        line {{ from: {name}.rx, {name}.ry; to: {bx}, {by}; width: {w} * 0.9; blend: 8 * clamp({w}, 0, 1) }}
""")

seed = 0.0
for sname, sx, sy, act, rx, ry, ex, ey in SRC:
    a(f"    let sl.{sname} = {act}\n")
    # vejár k okraju pod zdrojom
    for i, (off, w) in enumerate(FAN):
        seed += 1.7
        strand(f"slf.{sname}.{i}", f"({rx} + {ex} * {off})", f"({ry} + {ey} * {off})", f"({sx} + {ex} * {off * 0.28:.1f})", f"({sy} + {ey} * {off * 0.28:.1f})", f"{w} * sl.{sname}", seed)
    # zväzky ku kvapkám v okolí, ktoré ležia pri okraji
    for aname, axx, ayy, rest in ANC:
        if aname == sname:
            continue
        for j, (o1, o2, w) in enumerate([(-9, -6, 8), (10, 7, 6)]):
            seed += 1.3
            k = f"slp.{sname}.{aname}.{j}"
            wexpr = f"{w} * sl.{sname} * ({rest}) * smooth({R_FAR}, {R_NEAR}, length({sx} - {axx}, {sy} - {ayy}))"
            strand(k, f"({axx} + {ex} * {o1})", f"({ayy} + {ey} * {o1})", f"({sx} + {ex} * {o2})", f"({sy} + {ey} * {o2})", wexpr, seed)
a("".join(lets))
a('''    body {
        color: coffee
        rim: 30%
        light: 14%, 0, 30
        glass: 100% * clamp(v * 1.3, 0, 1) * (1 - m)
        shine: pointer
        opacity: if(solo, 1, 0) * so
''')
a("".join(shapes))
a('''    }
    // <<< sliz
''')
block = "".join(L)

s = open(PLM).read()
A, B = "    // >>> sliz (sliz.py)\n", "    // <<< sliz\n"
if A in s:
    i = s.index(A); j = s.index(B, i) + len(B)
    s = s[:i] + block + s[j:]
else:
    i = s.index("    // <<< PowerGoo\n") + len("    // <<< PowerGoo\n")
    s = s[:i] + block + s[i:]
open(PLM, "w").write(s)
print(f"kvapka.plm: sliz · {len(SRC)} zdroje, {len(ANC)} kotvy")
