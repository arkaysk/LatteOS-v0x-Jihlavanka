#!/usr/bin/env python3
# Okno z bubliny (1. 10. 2026, LATTEOS-GOO.md pravidlo 14): kvapka, ktorá otvára riadne okno (nie vyskakovacie),
# ostane na mieste a VYPĽUJE malú bublinu — tá sa z nej vytlačí (kým je pri nej, zlieva sa s ňou: je v tele lišty),
# odtrhne sa, preletí po oblúku na miesto budúceho okna a nafúkne sa na jeho obdĺžnik (z kávy do materiálu okien).
# Hyprland potom otvorí skutočné okno presne tam, bez vlastnej animácie (latte-kvapky okno → latte/windows.lua);
# keď sa okno objaví, bublina zmizne. Dnes pľuje kráľovná (App Manager, Správca zariadení).
# Logika nastaví cieľ (bub.x, bub.y stred, bub.w, bub.h) a pošle `bub_go`; keď okno naskočí, `bub_done`.
# Vypíše blok  // >>> bublina okna (bublina.py) … // <<< bublina okna  a kvapôčku do tela lišty (goo.py).
# Použitie: python3 session/kvapky/bublina.py
import os
import goo

HERE = os.path.dirname(os.path.abspath(__file__))
PLM = os.path.join(HERE, "kvapka.plm")
CORNER = 14                               # zaoblenie okien Hyprlandu (decoration.rounding)

block = f'''    // >>> bublina okna (bublina.py)
    // okno z bubliny (pravidlo 14): vytlačenie (s1), let po oblúku (s2), nafúknutie na okno (s3)
    fact bub_on = false
    fact bub.x = 960                         // cieľ: stred a rozmer okna (logika)
    fact bub.y = 540
    fact bub.w = 800
    fact bub.h = 600
    event bub_go
    event bub_done
    prop bub.t = 0 ~900ms
    prop bub.a = 0 ~160ms
    let b.s1 = smooth(0, 0.3, bub.t)
    let b.s2 = smooth(0.25, 0.65, bub.t)
    let b.s3 = smooth(0.6, 1, bub.t)
    // odkiaľ: kvapka kráľovnej, smerom od jej okraja
    let b.p1x = qg.x + qg.nx * (qg.r + 16) * b.s1
    let b.p1y = qg.y + qg.ny * (qg.r + 16) * b.s1
    let b.cx = b.p1x + qg.nx * 160
    let b.cy = b.p1y + qg.ny * 160
    let b.x = (1 - b.s2) * (1 - b.s2) * b.p1x + 2 * (1 - b.s2) * b.s2 * b.cx + b.s2 * b.s2 * bub.x
    let b.y = (1 - b.s2) * (1 - b.s2) * b.p1y + 2 * (1 - b.s2) * b.s2 * b.cy + b.s2 * b.s2 * bub.y
    let b.r = 8 + 8 * b.s1 + 6 * b.s2
    // blana sa pri nafukovaní trochu chveje, potom sa ustáli
    let b.wob = 1 + 0.035 * sin(b.s3 * 9.4) * (1 - b.s3)
    let b.w = (2 * b.r + (bub.w - 2 * b.r) * b.s3) * b.wob
    let b.h = (2 * b.r + (bub.h - 2 * b.r) * b.s3) * (2 - b.wob)
    // farba: blízko kráľovnej káva, ďalej materiál okien (pravidlo 11)
    let b.gx = qg.nx * b.w / 2
    let b.gy = qg.ny * b.h / 2
    body {{
        gradient: b.x + b.gx, b.y + b.gy to b.x - b.gx, b.y - b.gy, mix(coffee, l.win, b.s3), mix(coffee, l.win, b.s3 * 0.55)
        glass: 100% * max(l.glass, 0.7 * (1 - b.s3))
        lens: l.pearl > 0.5
        shine: pointer
        refraction: 120% * max(l.pearl, 1 - b.s3)
        dispersion: 260% * max(l.pearl, 1 - b.s3)
        rim: 24%
        light: 6%, b.y - b.h / 2, 40
        shadow: 0, 10, 26, 38% * b.s3
        opacity: bub.a * if(bub.t > 0.27, 1, 0)
        box {{ at: b.x, b.y; size: b.w, b.h; corner: b.r + ({CORNER} - b.r) * b.s3 }}
    }}
    on bub_go {{ bub_on = true; bub.t: 0 ~0ms; bub.a: 1 ~0ms; bub.t: 1 ~900ms after 16ms; impulse qg.wob 300 }}
    on bub_done {{ bub.a: 0 ~180ms }}
    // <<< bublina okna
'''

s = open(PLM).read()
A, B = "    // >>> bublina okna (bublina.py)\n", "    // <<< bublina okna\n"
if A in s:
    i = s.index(A); j = s.index(B, i) + len(B)
    s = s[:i] + block + s[j:]
else:
    i = s.index("    // <<< QueenGoo\n") + len("    // <<< QueenGoo\n")
    s = s[:i] + block + s[i:]
# vytláčaná kvapôčka v tele lišty: kým je pri kráľovnej, zlieva sa s ňou (potom ju prevezme bublina)
v = "bub_on and bub.a > 0.5 and bub.t > 0.01 and bub.t < 0.3"
s = goo.vloz(s, "bublina okna", [f"ellipse {{ at: {goo.at(v, 'b.x', 'b.y')}; radius: if({v}, b.r, 1); blend: 16 }}"], [])
open(PLM, "w").write(s)
print("kvapka.plm: bublina okna")
