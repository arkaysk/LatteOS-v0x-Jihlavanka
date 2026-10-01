#!/usr/bin/env python3
# Voľné Hodiny (TimeGoo) a vypínač (PowerGoo) v kvapka.plm (1. 10. 2026, LATTEOS-GOO.md pravidlo 16: všetky kvapky
# sú drag & drop). Pri lište sú ako doteraz (prelievanie v trojici vypínač – Hodiny – lišta); chytené a potiahnuté
# (pohyb po stlačení) idú za kurzorom; pustené ďaleko od lišty sa prilepia k najbližšiemu okraju ako samostatná
# kvapka, pustené pri svojom mieste v lište sa vrátia do nej. Klik bez pohybu = spúšťač / ponuka (ako doteraz).
# Spúšťač, časové menu a ponuka vypínača vyrastú z kvapky, kde práve je (orientácia t.* / p.* podľa jej okraja).
# Vypíše bloky medzi značky  // >>> voľné Hodiny a vypínač (volne.py) … // <<< voľné  a … zóny; upraví (raz)
# miesta v lište, ktoré od nich závisia.
# Použitie: python3 session/kvapky/volne.py
import os
import goo

HERE = os.path.dirname(os.path.abspath(__file__))
PLM = os.path.join(HERE, "kvapka.plm")
DOCK = 110                       # pustená bližšie k svojmu miestu v lište = vráti sa do lišty

def drop(n, seed, dock_x, dock_y, radius):
    return f'''    fact {n}_free = false
    fact {n}.side = 0
    fact {n}.pos = 0.3
    fact {n}_press = false
    fact {n}_moved = false
    fact {n}d.x = 0
    fact {n}d.y = 0
    fact {n}d.dd = 999                       // vzdialenosť od miesta v lište pri pustení
    event {n}_drop ->
    let {n}.dkx = {dock_x}                   // miesto v lište (obrazovka)
    let {n}.dky = {dock_y}
    let {n}.ax = pick({n}.side, W * {n}.pos, W * {n}.pos, 0, W)
    let {n}.ay = pick({n}.side, H, 0, H * {n}.pos, H * {n}.pos)
    let {n}.nx = pick({n}.side, 0, 0, 1, -1)
    let {n}.ny = pick({n}.side, -1, 1, 0, 0)
    let {n}.near = 1 - smooth(0, 190, length(mx - {n}.ax, my - {n}.ay))
    let {n}.out = {radius - 4} + 8 * {n}.near + 2.5 * noise(time * 0.3 + {seed})
    let {n}.tx = {n}.ax + {n}.nx * {n}.out + clamp(mx - {n}.ax, -20, 20) * 0.28 * {n}.near * abs({n}.ny)
    let {n}.ty = {n}.ay + {n}.ny * {n}.out + clamp(my - {n}.ay, -20, 20) * 0.28 * {n}.near * abs({n}.nx)
    prop {n}.fx = 0 ~lively
    prop {n}.fy = 0 ~lively
    follow {n}.fx = if({n}_moved, mx, if({n}_free, {n}.tx, {n}.dkx))
    follow {n}.fy = if({n}_moved, my, if({n}_free, {n}.ty, {n}.dky))
    let {n}.sheet = if({n}_free and not {n}_moved, 1, 0) * so
'''

draw = ('''    // >>> voľné Hodiny a vypínač (volne.py)
    // Hodiny a vypínač ťahaním kamkoľvek (pravidlo 16): pri lište ako doteraz, inak samostatná kvapka pri okraji
'''
 + drop("tg", "31.7", "pick(side, sx, W - sx, edge - s.y, W - edge + s.y)", "pick(side, s.y + H - edge, edge - s.y, sx, H - sx)", 33)
 + drop("pg", "37.3", "pick(side, px, W - px, edge - p.y, W - edge + p.y)", "pick(side, p.y + H - edge, edge - p.y, px, H - px)", 22)
 + '''    // <<< voľné
''')

zones = f'''    // >>> voľné zóny (volne.py)
    // Hodiny a vypínač: klikateľné miesta v súradniciach obrazovky (v lište aj voľne); počas ťahania cez celú
    // obrazovku (Hyprland posiela myš iba v zónach)
    zone ellipse start_hit {{ at: cxs, cys; radius: if(tg_press, 4000, 34 * zt.p); cursor: pointer; active: solo }}
    zone ellipse power_hit {{ at: pxs, pys; radius: if(pg_press, 4000, 22 * zp.p); cursor: pointer; active: solo }}
    on scroll start_hit {{ emit goo_wheel(0 * 2 + if(wheel > 0, 1, 0)) }}
    on scroll power_hit {{ emit goo_wheel(1 * 2 + if(wheel > 0, 1, 0)) }}
    on press start_hit {{ tg_press = true; tg_moved = false; wd.w = W; wd.h = H }}
    on drag start_hit while tg_press and abs(drag.dx) + abs(drag.dy) > 8 {{ tg_moved = true; dash = false; pmenu = false }}
    on release start_hit while tg_press and tg_moved {{ tgd.x = mx; tgd.y = my; tgd.dd = length(mx - tg.dkx, my - tg.dky); tg_moved = false; tg_press = false; impulse swob 300; emit tg_drop }}
    on release start_hit while tg_press and not tg_moved {{ tg_press = false; dash = not (dash and tview == 0); tview = 0; pmenu = false }}
    on press power_hit {{ pg_press = true; pg_moved = false; wd.w = W; wd.h = H }}
    on drag power_hit while pg_press and abs(drag.dx) + abs(drag.dy) > 8 {{ pg_moved = true; pmenu = false; dash = false }}
    on release power_hit while pg_press and pg_moved {{ pgd.x = mx; pgd.y = my; pgd.dd = length(mx - pg.dkx, my - pg.dky); pg_moved = false; pg_press = false; emit pg_drop }}
    on release power_hit while pg_press and not pg_moved {{ pg_press = false; toggle pmenu; dash = false }}
    // <<< voľné zóny
'''

s = open(PLM).read()
def put(block, A, B, anchor, before=False):
    global s
    if A in s:
        i = s.index(A); j = s.index(B, i) + len(B)
        s = s[:i] + block + s[j:]
    else:
        i = s.index(anchor)
        if not before:
            i += len(anchor)
        s = s[:i] + block + s[i:]
put(draw, "    // >>> voľné Hodiny a vypínač (volne.py)\n", "    // <<< voľné\n", "    // <<< QueenGoo\n")
put(zones, "    // >>> voľné zóny (volne.py)\n", "    // <<< voľné zóny\n", "    // <<< QueenGoo zóny\n")

def once(old, new):
    global s
    if old in s and (not new or new not in s):
        s = s.replace(old, new, 1)
TF, PF = "(tg_free or tg_moved)", "(pg_free or pg_moved)"
# Pozor: `show:` na tvare v `body` iba násobí priehľadnosť — tvar sa do siluety zleje aj tak a s nulovým polomerom
# / šírkou ostane bodka či vlásočnica. Skryté tvary lišty preto odchádzajú do stredu hlavy (hx, mid - 8), kde ich nevidno.
HIDE = lambda cond, x, y: f"if({cond}, hx, {x}), if({cond}, mid - 8, {y})"
BAR = [
    f"            box {{ from: {HIDE(TF + ' and ' + PF, f'if({PF}, sx, px) - 34 - 14 * flow2 * stir', 'edge')}; size: (if({TF}, px, sx) - if({PF}, sx, px) + 68 + 28 * flow2 * stir) * so * if({TF} and {PF}, 0, 1), if({TF} and {PF}, 0, 70) }}\n",
    f"            ellipse {{ at: {HIDE(TF, 'sx', 's.y')}; radius: (33 + 3 * hs) * zt.p * so * (1 - smooth(0, 0.08, dsw)) * if({TF}, 0, 1); scale: 1 + squish.s * 0.08 + jit.s + swob * 0.01, 1 - squish.s * 0.12 - jit.s - swob * 0.01; blend: link * so }}\n",
    f"            ellipse {{ at: {HIDE(PF, 'px', 'p.y')}; radius: (19 + 4 * hp) * zp.p * so * (1 - smooth(0, 0.12, pm)) * if({PF}, 0, 1); scale: 1 + squish.p * 0.08 + jit.p, 1 - squish.p * 0.12 - jit.p; blend: link * so }}\n",
    f"            line {{ from: {HIDE(TF + ' or ' + PF, 'px', 'p.y - 4')}; to: {HIDE(TF + ' or ' + PF, 'sx', 's.y - 6')}; width: thread.ps * (1 - max(dsh, pm)) * if({TF} or {PF}, 0, 1); blend: 12 * clamp(thread.ps * (1 - max(dsh, pm)) / 3, 0, 1) }}\n",
    f"            line {{ from: {HIDE(TF, 'sx + 8', 's.y - 12')}; to: {HIDE(TF, 'bl + 18', 'bottom - 14')}; width: thread.sb * ap * (1 - dsh) * if({TF}, 0, 1); blend: 14 * clamp(thread.sb * ap * (1 - dsh) / 3, 0, 1) }}\n",
    f"            ellipse {{ at: {HIDE(f'(seg and {TF}) or (not seg and ({TF} or {PF}))', 'drip.x', 'drip.y')}; radius: drip.r * so; blend: 8 }}\n",
]
# lišta: kvapky, voda a vlákna Hodín a vypínača iba keď sú v nej (6 riadkov za komentárom „Štart a vypínač“)
k = s.index("            // Štart a vypínač: vlastná")
k = s.index("\n", k) + 1
e = k
for _ in range(6):
    e = s.index("\n", e) + 1
s = s[:k] + "".join(BAR) + s[e:]
once("            ellipse { at: sx, edge; radius: 30 * if(sag.s > 0.3, 1, 0)",
     f"            ellipse {{ at: {HIDE(TF, 'sx', 'edge')}; radius: 30 * if(sag.s > 0.3, 1, 0)")
once("    let px0 = lx - 158                       // kvapka vypínač\n",
     "    let px0 = if(tg_free, lx - 92, lx - 158) // kvapka vypínač (na mieste Hodín, keď sú Hodiny voľné)\n")
# staré zóny v rámci lišty preč (nahradili ich zóny v súradniciach obrazovky)
once("        zone ellipse start_hit { at: sx, s.y; radius: 34; cursor: pointer; active: solo }\n", "")
once("        zone ellipse power_hit { at: px, p.y; radius: 19; cursor: pointer; active: solo }\n", "")
# poloha Hodín na obrazovke a orientácia spúšťača podľa ich okraja
once("    let cxs = pick(side, sx, W - sx, edge - s.y, W - edge + s.y)\n    let cys = pick(side, s.y + H - edge, edge - s.y, sx, H - sx)\n",
     "    let cxs = if(tg_free or tg_moved, tg.fx, pick(side, sx, W - sx, edge - s.y, W - edge + s.y))\n    let cys = if(tg_free or tg_moved, tg.fy, pick(side, s.y + H - edge, edge - s.y, sx, H - sx))\n")
once("    let away.y = pick(side, -1, 1, 0, 0)\n",
     "    let away.y = pick(side, -1, 1, 0, 0)\n    // Hodiny môžu byť voľné (1. 10.): spúšťač a časové menu rastú podľa okraja, pri ktorom Hodiny práve sú\n    let t.vert = if(tg_free, if(tg.side >= 2, 1, 0), vert)\n    let t.ax = if(tg_free, pick(tg.side, 0, 0, 1, -1), away.x)\n    let t.ay = if(tg_free, pick(tg.side, -1, 1, 0, 0), away.y)\n")
# pravidlá: klik až pri pustení bez pohybu (vyššie v zónach); staré „na stlačenie“ preč
once("    on press start_hit { dash = not (dash and tview == 0); tview = 0; pmenu = false }\n", "")
once("    on press power_hit { toggle pmenu; dash = false; squish.p: 1; squish.s: 0.5 after 70ms; squish: 0.3 after 140ms }\n",
     "    on press power_hit { squish.p: 1; squish.s: 0.5 after 70ms; squish: 0.3 after 140ms }\n")
once("    image power_icon { at: pick(side, px, W - px, edge - p.y, W - edge + p.y) - 8, pick(side, p.y + H - edge, edge - p.y, px, H - px) - 8;",
     "    image power_icon { at: pxs - 8, pys - 8;")
# odlesk Hodín a prehnutie hladiny pod nimi iba v lište
once("    let sag.s = 16 * 4 * clamp(dsw, 0, 1) * (1 - clamp(dsw, 0, 1)) * so\n",
     "    let sag.s = 16 * 4 * clamp(dsw, 0, 1) * (1 - clamp(dsw, 0, 1)) * so * if(tg_free or tg_moved, 0, 1)\n")
once("radius: 4.5 * so * (1 - smooth(0, 0.12, dsh)) * (1 - smooth(60, 420, length(cu - sx, cv - s.y))); color: #ffe4bd }",
     "radius: 4.5 * so * (1 - smooth(0, 0.12, dsh)) * (1 - smooth(60, 420, length(cu - sx, cv - s.y))) * if(tg_free or tg_moved, 0, 1); color: #ffe4bd }")
# voľné kvapky: telo v tele lišty (goo.py) — zlievajú sa s lištou a ostatnými kvapkami, to isté svetlo
TGV, PGV = "(tg_free or tg_moved) and solo and dsw < 0.07", "(pg_free or pg_moved) and solo and pm < 0.11"
TGR, PGR = "(33 + 3 * hs) * zt.p * so * (1 - smooth(0, 0.08, dsw))", "(19 + 4 * hp) * zp.p * so * (1 - smooth(0, 0.12, pm))"
s = goo.vloz(s, "voľné Hodiny", goo.kvapka(TGV, "tg.fx", "tg.fy", TGR, "tg.ax", "tg.ay", "tg.nx", "tg.ny", "tg.sheet", jit="jit.s"),
             goo.odlesk(TGV, "tg.fx", "tg.fy", TGR))
s = goo.vloz(s, "voľný vypínač", goo.kvapka(PGV, "pg.fx", "pg.fy", PGR, "pg.ax", "pg.ay", "pg.nx", "pg.ny", "pg.sheet", jit="jit.p"),
             goo.odlesk(PGV, "pg.fx", "pg.fy", PGR))
open(PLM, "w").write(s)
print("kvapka.plm: voľné Hodiny a vypínač")
