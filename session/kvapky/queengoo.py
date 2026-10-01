#!/usr/bin/env python3
# QueenGoo v kvapka.plm (1. 10. 2026, LATTEOS-GOO.md 4.4b): kvapka s korunkou (tvar ostáva kvapka — tvar koruny je
# k4ditanov). Ľavý klik = App Manager (inštalácia programov), pravý = Správca zariadení. Sú to riadne okná, nie
# vyskakovacie: kráľovná ostane na mieste a VYPĽUJE bublinu, ktorá sa nafúkne na okno (bublina.py, pravidlo 14).
# Ťahaním k inému okraju (ako DaNoGoo). Guľky: červená = hardvér (latte-devices), zelená = sieť (výpadok), modrá =
# softvér (latte-apps updates); klik otvorí okno rovno na tom, čo hlási (Aktualizácie, Siete).
# Vypíše dva bloky: kreslenie (za DaNoGoo) a zóny + pravidlá (na konci scény).
# Použitie: python3 session/kvapky/queengoo.py
import json, os
import goo

HERE = os.path.dirname(os.path.abspath(__file__))
PLM = os.path.join(HERE, "kvapka.plm")
UI, ICONS = "Inter", "noctalia-tabler-icons"
tab = json.load(open("/usr/share/noctalia/assets/fonts/tabler.json"))
ICON = lambda n: chr(int(tab[n]["codepoint"][2:], 16))
GOLD = "#e8b84a"

draw = f'''    // >>> QueenGoo (queengoo.py)
    // QueenGoo: kvapka s korunkou — App Manager (ľavý klik) a Správca zariadení (pravý); presúva sa ťahaním
    fact qg.side = 0
    fact qg.pos = 0.70
    fact qg_drag = false
    fact qg_moved = false
    fact qgd.x = 0
    fact qgd.y = 0
    fact qg_up = false                       // jej okno je otvorené (logika)
    fact qg_upd = 0                          // softvér: čakajúce aktualizácie (modrá guľka)
    fact qg_hw = 0                           // hardvér: zariadenia, ktoré potrebujú pozornosť (červená guľka)
    fact qg_net = 0                          // sieť: výpadok (zelená guľka)
    event qg_open ->
    event qg_drop ->
    let qg.ax = pick(qg.side, W * qg.pos, W * qg.pos, 0, W)
    let qg.ay = pick(qg.side, H, 0, H * qg.pos, H * qg.pos)
    let qg.nx = pick(qg.side, 0, 0, 1, -1)
    let qg.ny = pick(qg.side, -1, 1, 0, 0)
    let qg.px = 0 - qg.ny
    let qg.py = qg.nx
    let qg.near = 1 - smooth(0, 190, length(mx - qg.ax, my - qg.ay))
    prop qg.h = 0 ~lively
    prop qg.wob = 0 ~dnwobble
    let qg.out = 32 + 8 * qg.near + 2.5 * noise(time * 0.3 + 21.7)
    let qg.tx = qg.ax + qg.nx * qg.out + clamp(mx - qg.ax, -20, 20) * 0.28 * qg.near * abs(qg.px)
    let qg.ty = qg.ay + qg.ny * qg.out + clamp(my - qg.ay, -20, 20) * 0.28 * qg.near * abs(qg.py)
    prop qg.x = 0 ~lively
    prop qg.y = 0 ~lively
    // ťahanie: za kurzorom (cursor.x/y od Hyprlandu)
    follow qg.x = if(qg_drag and qg_moved, mx, qg.tx)
    follow qg.y = if(qg_drag and qg_moved, my, qg.ty)
    let qg.r = (30 + 3 * qg.h) * so
    let qg.jit = 0.05 * sin(time * 9 + 5) * qg.h + qg.wob * 0.01
    // základňa na okraji (pri ťahaní sa stiahne)
    let qg.sheet = if(qg_drag and qg_moved, 0, 1) * so
    // korunka na vonkajšej strane kvapky, natočená podľa okraja
    let qg.rot = pick(qg.side, 0, 180, 90, -90)
    // telo kráľovnej je v tele lišty (goo.py) — zlieva sa s ostatnými kvapkami a má to isté svetlo
    // guľky upozornení (pravidlo 1. 10.): červená = hardvér, zelená = sieť, modrá = softvér (aktualizácie); s počtom
    body {{
        color: #e5484d
        rim: 30%
        light: 18%, 0, 16
        opacity: if(solo and qg_hw > 0, 1, 0)
        ellipse {{ at: qg.x + (qg.nx * cos(-58) + qg.px * sin(-58)) * (qg.r + 2), qg.y + (qg.ny * cos(-58) + qg.py * sin(-58)) * (qg.r + 2); radius: 9.5 * so }}
    }}
    body {{
        color: #46a758
        rim: 30%
        light: 18%, 0, 16
        opacity: if(solo and qg_net > 0, 1, 0)
        ellipse {{ at: qg.x + (qg.nx * cos(-108) + qg.px * sin(-108)) * (qg.r + 2), qg.y + (qg.ny * cos(-108) + qg.py * sin(-108)) * (qg.r + 2); radius: 9.5 * so }}
    }}
    body {{
        color: #0090ff
        rim: 30%
        light: 18%, 0, 16
        opacity: if(solo and qg_upd > 0, 1, 0)
        ellipse {{ at: qg.x + (qg.nx * cos(58) + qg.px * sin(58)) * (qg.r + 2), qg.y + (qg.ny * cos(58) + qg.py * sin(58)) * (qg.r + 2); radius: 9.5 * so }}
    }}
    // <<< QueenGoo
'''
texts = f'''    // >>> QueenGoo texty (queengoo.py)
    group {{
        pivot: qg.x, qg.y
        rotate: qg.rot * 1deg
        show: solo
        text "{ICON('crown')}" {{ at: qg.x, qg.y - qg.r - 4; anchor: center; size: 22; color: {GOLD}; outline: 1.5, #3a2410; family: "{ICONS}" }}
    }}
    text "{ICON('apps')}" {{ at: qg.x, qg.y + 1; anchor: center; size: 18; color: ink; opacity: 80% * so; show: solo; family: "{ICONS}" }}
    text "{{qg_upd}}" {{ at: qg.x + (qg.nx * cos(58) + qg.px * sin(58)) * (qg.r + 2), qg.y + (qg.ny * cos(58) + qg.py * sin(58)) * (qg.r + 2); anchor: center; size: 9.5; weight: 800; color: #ffffff; show: solo and qg_upd > 0; family: "{UI}" }}
    text "{{qg_hw}}" {{ at: qg.x + (qg.nx * cos(-58) + qg.px * sin(-58)) * (qg.r + 2), qg.y + (qg.ny * cos(-58) + qg.py * sin(-58)) * (qg.r + 2); anchor: center; size: 9.5; weight: 800; color: #ffffff; show: solo and qg_hw > 0; family: "{UI}" }}
    text "{{qg_net}}" {{ at: qg.x + (qg.nx * cos(-108) + qg.px * sin(-108)) * (qg.r + 2), qg.y + (qg.ny * cos(-108) + qg.py * sin(-108)) * (qg.r + 2); anchor: center; size: 9.5; weight: 800; color: #ffffff; show: solo and qg_net > 0; family: "{UI}" }}
    // <<< QueenGoo texty
'''
zones = '''    // >>> QueenGoo zóny (queengoo.py)
    zone ellipse qg_hit { at: qg.x, qg.y; radius: if(qg_drag, 4000, 34); cursor: pointer; active: solo }
    on press qg_hit { qg_drag = true; qg_moved = false; wd.w = W; wd.h = H }
    on press right qg_hit { impulse qg.wob 140; emit qg_open(1) }
    on drag qg_hit while qg_drag and abs(drag.dx) + abs(drag.dy) > 6 { qg_moved = true }
    on release qg_hit while qg_drag and qg_moved { qgd.x = mx; qgd.y = my; impulse qg.wob 300; emit qg_drop; qg_moved = false; qg_drag = false }
    on release qg_hit while qg_drag and not qg_moved { qg_drag = false; impulse qg.wob 160; emit qg_open(0) }
    on enter qg_hit { qg.h: 1 }
    on leave qg_hit { qg.h: 0 }
    // <<< QueenGoo zóny
'''

s = open(PLM).read()
def put(block, A, B, anchor, before=True):
    global s
    if A in s:
        i = s.index(A); j = s.index(B, i) + len(B)
        s = s[:i] + block + s[j:]
    else:
        i = s.index(anchor)
        if not before:
            i += len(anchor)
        s = s[:i] + block + s[i:]
put(draw, "    // >>> QueenGoo (queengoo.py)\n", "    // <<< QueenGoo\n", "    // <<< DaNoGoo\n", before=False)
put(texts, "    // >>> QueenGoo texty (queengoo.py)\n", "    // <<< QueenGoo texty\n", "    // <<< DaNoGoo texty\n", before=False)
put(zones, "    // >>> QueenGoo zóny (queengoo.py)\n", "    // <<< QueenGoo zóny\n", "    // <<< DaNoGoo zóny\n", before=False)
if '"latte-apps"' not in s:
    s = s.replace('"paplay" }', '"paplay", "latte-apps" }', 1)
if '"latte-devices"' not in s:
    s = s.replace('"latte-apps" }', '"latte-apps", "latte-devices" }', 1)
s = goo.vloz(s, "QueenGoo", goo.kvapka("solo", "qg.x", "qg.y", "qg.r", "qg.ax", "qg.ay", "qg.nx", "qg.ny", "qg.sheet", jit="qg.jit"),
             goo.odlesk("solo", "qg.x", "qg.y", "qg.r"))
open(PLM, "w").write(s)
print("kvapka.plm: QueenGoo")
