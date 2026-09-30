#!/usr/bin/env python3
# QueenGoo v kvapka.plm (1. 10. 2026, LATTEOS-GOO.md 4.4b): kvapka s korunkou (tvar ostáva kvapka — tvar koruny je
# k4ditanov). Ľavý klik = premení sa na App Manager (inštalácia programov), pravý = Správca zariadení. Okno sa
# otvorí ROHOM pri jej uchu (latte-kvapky miesto → Hyprland), kým je otvorené, kráľovná ostane vystúpená ako ucho.
# Ťahaním k inému okraju (ako DaNoGoo). Guľky: červená = hardvér (latte-devices), zelená = sieť (výpadok), modrá =
# softvér (latte-apps updates); klik otvorí okno rovno na tom, čo hlási (Aktualizácie, Siete).
# Vypíše dva bloky: kreslenie (za DaNoGoo) a zóny + pravidlá (na konci scény).
# Použitie: python3 session/kvapky/queengoo.py
import json, os

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
    fact qgp.x = 0
    fact qgp.y = 0
    fact qgq.x = 0
    fact qgq.y = 0
    fact qg_up = false                       // jej okno je otvorené: ostane vystúpená ako ucho v rohu okna
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
    prop qg.lift = 0 ~dnspring
    follow qg.lift = if(qg_up, 1, 0)
    prop qg.h = 0 ~lively
    prop qg.wob = 0 ~dnwobble
    let qg.out = 32 + 8 * qg.near + 2.5 * noise(time * 0.3 + 21.7) + 70 * qg.lift
    let qg.tx = qg.ax + qg.nx * qg.out + clamp(mx - qg.ax, -20, 20) * 0.28 * qg.near * abs(qg.px)
    let qg.ty = qg.ay + qg.ny * qg.out + clamp(my - qg.ay, -20, 20) * 0.28 * qg.near * abs(qg.py)
    prop qg.x = 0 ~lively
    prop qg.y = 0 ~lively
    follow qg.x = if(qg_drag and qg_moved, qgp.x + qgq.x, qg.tx)
    follow qg.y = if(qg_drag and qg_moved, qgp.y + qgq.y, qg.ty)
    let qg.r = (30 + 3 * qg.h) * so
    let qg.jit = 0.05 * sin(time * 9 + 5) * qg.h + qg.wob * 0.01
    let qg.sheet = if(qg_drag and qg_moved, 0, 1) * so
    // korunka na vonkajšej strane kvapky, natočená podľa okraja
    let qg.rot = pick(qg.side, 0, 180, 90, -90)
    body {{
        color: coffee
        rim: 30%
        light: 14%, 0, 30
        glass: 100% * clamp(v * 1.3, 0, 1) * (1 - m)
        shine: pointer
        opacity: if(solo, 1, 0)
        box {{ at: qg.ax, qg.ay; size: 70 * abs(qg.ny) + 20 * abs(qg.nx), 20 * abs(qg.ny) + 70 * abs(qg.nx); corner: 10 }}
        ellipse {{ at: qg.ax, qg.ay; radius: 24 * qg.sheet; blend: 16 }}
        ellipse {{ at: qg.x, qg.y; radius: qg.r; scale: 1 + qg.jit, 1 - qg.jit; blend: 18 * qg.sheet + 2 }}
    }}
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
    zone ellipse qg_hit { at: qg.x, qg.y; radius: 34; cursor: pointer; active: solo }
    on press qg_hit { qg_drag = true; qg_moved = false; wd.w = W; wd.h = H; qgp.x = pointer.x; qgp.y = pointer.y; qgq.x = 0; qgq.y = 0 }
    on drag qg_hit while qg_drag { qgq.x = drag.dx; qgq.y = drag.dy }
    on press right qg_hit { impulse qg.wob 140; emit qg_open(1) }
    on drag qg_hit while qg_drag and abs(drag.dx) + abs(drag.dy) > 6 { qg_moved = true }
    on release qg_hit while qg_drag and qg_moved { qgd.x = pointer.x; qgd.y = pointer.y; impulse qg.wob 300; emit qg_drop; qg_moved = false; qg_drag = false }
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
open(PLM, "w").write(s)
print("kvapka.plm: QueenGoo")
