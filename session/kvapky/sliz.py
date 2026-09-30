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
    """vlákno z A do B: pri koncoch hrubé (zliate), v strede tenké, prehnuté a kývajúce sa kolmo na smer.
    Bez `let` — výpočty sú v tvaroch skrytého tela, takže v pokoji (nič zdvihnuté) nestoja nič."""
    ax, ay, bx, by = f"({ax})", f"({ay})", f"({bx})", f"({by})"
    # neaktívne vlákno (slabšie ako 0,25 px) sa zbalí do bodu objektu — inak by pleamar kreslil tenký okraj čiary
    gate = f"if(({w}) > 0.25, 1, 0)"
    bx, by = f"({ax} + ({bx} - {ax}) * {gate})", f"({ay} + ({by} - {ay}) * {gate})"
    d = f"max(length({bx} - {ax}, {by} - {ay}), 1)"
    sw = f"((8 * noise(time * 0.45 + {sway_seed:.1f}) + 3 * sin(time * 1.3 + {sway_seed * 0.7:.1f})) * min({d} / 120, 1.4) / {d})"
    px, py = f"(0 - ({by} - {ay}))", f"({bx} - {ax})"          # kolmica (nenormovaná; delí sa v sw)
    def pt(t, k):
        return (f"{ax} + ({bx} - {ax}) * {t} + {px} * {sw} * {k}", f"{ay} + ({by} - {ay}) * {t} + {py} * {sw} * {k}")
    q, m, r = pt(0.28, 0.6), pt(0.5, 1), pt(0.72, 0.6)
    ww = f"({w})"
    shapes.append(f"""        ellipse {{ at: {ax}, {ay}; radius: {ww} * 0.8; blend: 8 * clamp({ww}, 0, 1) }}
        line {{ from: {ax}, {ay}; to: {q[0]}, {q[1]}; width: {ww}; blend: 7 * clamp({ww}, 0, 1) }}
        line {{ from: {q[0]}, {q[1]}; to: {m[0]}, {m[1]}; width: {ww} * 0.5; blend: 4 * clamp({ww}, 0, 1) }}
        line {{ from: {m[0]}, {m[1]}; to: {r[0]}, {r[1]}; width: {ww} * 0.5; blend: 4 * clamp({ww}, 0, 1) }}
        line {{ from: {r[0]}, {r[1]}; to: {bx}, {by}; width: {ww} * 0.9; blend: 8 * clamp({ww}, 0, 1) }}
""")

seed = 0.0
# jeden aktívny zdroj naraz (zdvíha sa prakticky vždy iba jedna kvapka): ktorý, jeho poloha, koreň a os okraja
names = [n for n, *_ in SRC]
def chain(vals, default):
    out = default
    for k in range(len(SRC) - 1, -1, -1):
        out = f"if(sl.src == {k}, {vals[k]}, {out})"
    return out
a("".join(f"    let sl.{n} = {act}\n" for n, _, _, act, *_ in SRC))
src_expr = "-1"
for k in range(len(SRC) - 1, -1, -1):
    src_expr = f"if(sl.{names[k]} > 0.02, {k}, {src_expr})"
a(f"    let sl.src = {src_expr}\n")
a(f"    let sl.a = max({', '.join(f'sl.{n}' for n in names)})\n" if len(names) == 2 else "    let sl.a = " + chain([f"sl.{n}" for n in names], "0") + "\n")
for key, idx in (("x", 1), ("y", 2), ("rx", 4), ("ry", 5), ("ex", 6), ("ey", 7)):
    a(f"    let sl.{key} = " + chain([t[idx] for t in SRC], "0") + "\n")
# počet vláken podľa objektu a vzdialenosti (1. 10., používateľ): ku každému objektu do 130 px 3 vlákna, do 200 px 2,
# do 300 px 1, ďalej žiadne. Okraj pod kvapkou je tiež objekt (vzdialenosť = výška zdvihnutia).
TIERS = [(300, 0, 9), (200, 1, 7), (130, 2, 6)]           # (do vzdialenosti, poradie vlákna, hrúbka)
SPREAD = [(0, 0), (-10, -5), (10, 6)]                     # rozostup vláken pri objekte a pri kvapke
objs = [("okraj", "sl.rx", "sl.ry", "1")] + [(n, x, y, rest) for n, x, y, rest in ANC]
for oname, ox, oy, rest in objs:
    dist = f"length(sl.x - ({ox}), sl.y - ({oy}))"
    for lim, k, w in TIERS:
        seed += 1.3
        o1, o2 = SPREAD[k]
        wexpr = f"{w} * sl.a * ({rest}) * if({dist} < {lim}, 1, 0) * smooth({lim}, {lim - 40}, {dist})"
        strand(f"sl.{oname}.{k}", f"({ox}) + sl.ex * {o1}", f"({oy}) + sl.ey * {o1}", f"sl.x + sl.ex * {o2}", f"sl.y + sl.ey * {o2}", wexpr, seed)
a("".join(lets))
a('''    body {
        show: sl.src >= 0
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
