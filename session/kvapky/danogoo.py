#!/usr/bin/env python3
# DaNoGoo v kvapka.plm (1. 10. 2026, LATTEOS-GOO.md 4.2b): samostatná kvapka s dátumom a počasím, guľky počtu
# upozornení (žlté bežné, červeno-kávová systémová s číslom), ľavý klik = kvapka vystrelí ako pružina a za sebou
# nechá hrozno upozornení na lepkavom vlákne (bobule vo farbe ikony aplikácie, najnovšia najďalej); zatvorí klik na
# DaNoGoo, Esc alebo klik mimo. Ťahanie = presun k inému okraju (ako kvapky widgetov). Pravý klik = kalendár.
# Goo telo nedovolí `repeat`, preto tento skript vypíše dva bloky:
#   // >>> DaNoGoo (danogoo.py) … // <<< DaNoGoo            kreslenie (nad lištou, pod spúšťačom)
#   // >>> DaNoGoo zóny (danogoo.py) … // <<< DaNoGoo zóny  klikateľné miesta a pravidlá (na konci scény, navrchu)
# Použitie: python3 session/kvapky/danogoo.py
import os

HERE = os.path.dirname(os.path.abspath(__file__))
PLM = os.path.join(HERE, "kvapka.plm")
NB = 6                                   # bobule (najnovšie upozornenia)
NY = 5                                   # žlté guľky počtu
UI = "Inter"
# paleta farieb ikon (latte-kvapky farba): 0 červená … 13 ružová, 14 svetlosivá, 15 tmavosivá; 16 systémová výstraha
PAL = ["#e5484d", "#f76b15", "#ffb224", "#f5d90a", "#99d52a", "#46a758", "#12a594", "#05a2c2", "#0090ff",
       "#3e63dd", "#6e56cf", "#8e4ec6", "#ab4aba", "#d6409f", "#c8cbd0", "#5b5f66", "#a8452f"]
pal = lambda e: "pick(" + e + ", " + ", ".join(PAL) + ")"

L = []
a = L.append
a('''    // >>> DaNoGoo (danogoo.py)
    // DaNoGoo: dátum + počasie + upozornenia (LATTEOS-GOO.md 4.2b). Poloha na okraji (dn.side, dn.pos) z logiky.
    fact dn.side = 0                         // 0 dole, 1 hore, 2 vľavo, 3 vpravo
    fact dn.pos = 0.78                       // 0..1 pozdĺž okraja
    fact dn_open = false                     // hrozno upozornení vonku
    fact dn_drag = false
    fact dn_moved = false
    fact dnd.x = 0
    fact dnd.y = 0
    text dn_date = ""
    text dn_wx = ""
    text dn_temp = ""
    text dn_clear = ""                       // „Vymazať všetko (9)“
    fact dn_crit = 0                         // systémové výstrahy (kritické)
    fact dn_norm = 0                         // ostatné upozornenia
    model berries max 6 { app: text; title: text; body: text; icon: image 24, 24; pal: number; dark: bool; acts: bool }
    fact berry_hot = -1
    fact brk = -1                            // ťahaná bobuľa
    fact brmoved = false
    fact br.dx = 0
    fact br.dy = 0
    event dn_drop
    event dn_cal
    event dn_clear_all
    event berry_open ->
    event berry_menu ->
    event berry_dismiss ->
    spring dnspring = 230, 11
    spring dnwobble = 420, 13
    let dn.ax = pick(dn.side, W * dn.pos, W * dn.pos, 0, W)
    let dn.ay = pick(dn.side, H, 0, H * dn.pos, H * dn.pos)
    let dn.nx = pick(dn.side, 0, 0, 1, -1)
    let dn.ny = pick(dn.side, -1, 1, 0, 0)
    let dn.px = 0 - dn.ny                    // pozdĺž okraja
    let dn.py = dn.nx
    let dn.vert = abs(dn.nx)
    let dn.near = 1 - smooth(0, 190, length(mx - dn.ax, my - dn.ay))
    prop dn.lift = 0 ~dnspring
    follow dn.lift = if(dn_open, 1, 0)
    prop dn.h = 0 ~lively
    prop dn.wob = 0 ~dnwobble
    // živý tvor: nakloní sa ku kurzoru, nad ňou sa nafúkne; pri otvorení vystrelí kolmo od okraja (pružina)
    let dn.out = 32 + 8 * dn.near + 2.5 * noise(time * 0.3 + 11.3) + 62 * dn.lift
    let dn.tx = dn.ax + dn.nx * dn.out + clamp(mx - dn.ax, -20, 20) * 0.28 * dn.near * abs(dn.px)
    let dn.ty = dn.ay + dn.ny * dn.out + clamp(my - dn.ay, -20, 20) * 0.28 * dn.near * abs(dn.py)
    prop dn.x = 0 ~lively
    prop dn.y = 0 ~lively
    follow dn.x = if(dn_drag and dn_moved, pointer.x, dn.tx)
    follow dn.y = if(dn_drag and dn_moved, pointer.y, dn.ty)
    let dn.r = (31 + 3 * dn.h) * so
    let dn.jit = 0.05 * sin(time * 9 + 3) * dn.h + dn.wob * 0.01
    let dn.sheet = if(dn_drag and dn_moved, 0, 1) * so
    // guľky počtu na vonkajšom oblúku (žlté bežné, červeno-kávová systémová vľavo)
''')
for k in range(NY):
    ang = (k - 2) * 25
    a(f"    let dny.x.{k} = dn.x + (dn.nx * cos({ang}) + dn.px * sin({ang})) * (dn.r + 2)\n")
    a(f"    let dny.y.{k} = dn.y + (dn.ny * cos({ang}) + dn.py * sin({ang})) * (dn.r + 2)\n")
a('''    let dnc.x = dn.x + (dn.nx * cos(-72) + dn.px * sin(-72)) * (dn.r + 3)
    let dnc.y = dn.y + (dn.ny * cos(-72) + dn.py * sin(-72)) * (dn.r + 3)
    // hrozno: bobule nad sebou smerom od okraja (pri bočnom okraji vedľa kvapky), najnovšia najďalej
''')
for k in range(NB):
    j = f"(berries.count - 1 - {k})"
    a(f"    let brj.{k} = {j}\n")
    a(f"    let brx.{k} = if(dn.vert > 0.5, dn.x + dn.nx * (dn.r + 196), clamp(dn.x, 200, W - 200)) + if(brk == {k} and brmoved, br.dx, 0)\n")
    a(f"    let bry.{k} = if(dn.vert > 0.5, dn.y + (brj.{k} - (berries.count - 1) / 2) * 60, dn.y + dn.ny * (dn.r + 46 + brj.{k} * 60)) + if(brk == {k} and brmoved, br.dy, 0)\n")
    a(f"    let bre.{k} = clamp(dn.lift * 1.7 - brj.{k} * 0.12 - 0.2, 0, 1) * if({k} < berries.count, 1, 0) * clamp(1 - abs(if(brk == {k} and brmoved, br.dx, 0)) / 260, 0, 1)\n")
a('''    let clx = if(dn.vert > 0.5, dn.x + dn.nx * (dn.r + 196), clamp(dn.x, 200, W - 200))
    let cly = if(dn.vert > 0.5, dn.y + ((berries.count - 1) / 2 + 1) * 60, dn.y + dn.ny * (dn.r + 46 + berries.count * 60))
    let cle = clamp(dn.lift * 1.7 - berries.count * 0.12 - 0.2, 0, 1) * if(berries.count > 0, 1, 0)
    let brend.x = if(berries.count > 0, clx, dn.x)
    let brend.y = if(berries.count > 0, cly, dn.y)
    body {
        color: coffee
        rim: 30%
        light: 14%, 0, 30
        glass: 100% * clamp(v * 1.3, 0, 1) * (1 - m)
        shine: pointer
        opacity: if(solo, 1, 0)
        box { at: dn.ax, dn.ay; size: 70 * abs(dn.ny) + 20 * abs(dn.nx), 20 * abs(dn.ny) + 70 * abs(dn.nx); corner: 10 }
        ellipse { at: dn.ax, dn.ay; radius: 24 * dn.sheet; blend: 16 }
        ellipse { at: dn.x, dn.y; radius: dn.r; scale: 1 + dn.jit, 1 - dn.jit; blend: 18 * dn.sheet + 2 }
        // lepkavé vlákno od kvapky cez hrozno (tenšie, čím ďalej)
        line { from: dn.x, dn.y; to: dn.x + (brend.x - dn.x) * clamp(dn.lift * 1.4, 0, 1), dn.y + (brend.y - dn.y) * clamp(dn.lift * 1.4, 0, 1); width: 7 * clamp(dn.lift * 3, 0, 1); blend: 10 * clamp(dn.lift * 3, 0, 1) }
''')
for k in range(NB):
    a(f"        ellipse {{ at: brx.{k} - 176 * bre.{k}, bry.{k}; radius: 9 * bre.{k}; blend: 8 * bre.{k} }}\n")
a('''    }
    // guľky počtu upozornení (goo: prilepené na kvapke)
    body {
        color: #f2c14e
        rim: 30%
        light: 16%, 0, 20
        opacity: if(solo, 1, 0) * (1 - dn.lift)
''')
for k in range(NY):
    a(f"        ellipse {{ at: dny.x.{k}, dny.y.{k}; radius: 6.2 * if({k} < dn_norm, 1, 0) * so; blend: 5 * if({k} < dn_norm, 1, 0) }}\n")
a(f'''    }}
    body {{
        color: #a8452f
        rim: 30%
        light: 16%, 0, 20
        opacity: if(solo, 1, 0) * (1 - dn.lift)
        ellipse {{ at: dnc.x, dnc.y; radius: 9.5 * if(dn_crit > 0, 1, 0) * so }}
    }}
    text "{{dn_crit}}" {{ at: dnc.x, dnc.y; anchor: center; size: 9.5; weight: 800; color: #ffffff; opacity: 1 - dn.lift; show: solo and dn_crit > 1; family: "{UI}" }}
    // bobule hrozna: kapsula vo farbe ikony aplikácie (ikona, aplikácia, nadpis, text)
''')
for k in range(NB):
    a(f'''    box {{ at: brx.{k}, bry.{k}; size: 360 * bre.{k}, 52 * bre.{k}; corner: 26; color: {pal(f"berries.{k}.pal")}; opacity: if(berry_hot == {k}, 100%, 94%); show: solo and bre.{k} > 0.01 }}
    ellipse {{ at: brx.{k} - 152 * bre.{k}, bry.{k}; radius: 18 * bre.{k}; color: #ffffff; opacity: 92%; show: solo and bre.{k} > 0.01 }}
    image berries.{k}.icon {{ at: brx.{k} - 164, bry.{k} - 12; size: 24, 24; opacity: clamp(bre.{k} * 2 - 1, 0, 1); show: solo and bre.{k} > 0.5 }}
    text "{{berries.{k}.app}} · {{berries.{k}.title}}" {{ at: brx.{k} - 124, bry.{k} - 9; anchor: left center; width: 290; lines: 1; size: 12.5; weight: 600; color: if(berries.{k}.dark, #1b1b1b, #ffffff); opacity: clamp(bre.{k} * 2 - 1, 0, 1); show: solo and bre.{k} > 0.5; family: "{UI}" }}
    text berries.{k}.body {{ at: brx.{k} - 124, bry.{k} + 10; anchor: left center; width: 290; lines: 1; size: 11.5; color: if(berries.{k}.dark, #1b1b1b, #ffffff); opacity: 80% * clamp(bre.{k} * 2 - 1, 0, 1); show: solo and bre.{k} > 0.5; family: "{UI}" }}
''')
a(f'''    box {{ at: clx, cly; size: 190 * cle, 34 * cle; corner: 17; color: mix(coffee, #f3ebdd, 0.12); opacity: 95%; show: solo and cle > 0.01 }}
    text dn_clear {{ at: clx, cly; anchor: center; size: 12; weight: 600; color: ink; opacity: clamp(cle * 2 - 1, 0, 1); show: solo and cle > 0.5; family: "{UI}" }}
    // <<< DaNoGoo
''')
draw = "".join(L)
drop_texts = """    // >>> DaNoGoo texty (danogoo.py)
""" + '    // obsah kvapky: dátum a počasie (bez tváre)\n    text dn_date {{ at: dn.x, dn.y - 7; anchor: center; size: 11; weight: 700; color: ink; opacity: so; show: solo; family: "{UI}" }}\n    text dn_wx {{ at: dn.x - 1, dn.y + 9; anchor: right center; size: 12; color: ink; opacity: 85% * so; show: solo; family: "noctalia-tabler-icons" }}\n    text dn_temp {{ at: dn.x + 1, dn.y + 9; anchor: left center; size: 10.5; weight: 600; color: ink; opacity: 85% * so; show: solo; family: "{UI}" }}\n' + """    // <<< DaNoGoo texty
"""

Z = []
z = Z.append
z('''    // >>> DaNoGoo zóny (danogoo.py)
    // hrozno: klik mimo neho ho zavrie (pod bobuľami)
    zone box dn_away { at: W / 2, H / 2; size: W, H; active: dn_open }
    zone ellipse dn_hit { at: dn.x, dn.y; radius: 34; cursor: pointer; active: solo }
''')
for k in range(NB):
    z(f"    zone box br_hit.{k} {{ at: brx.{k}, bry.{k}; size: 360, 52; cursor: pointer; active: dn_open and {k} < berries.count and bre.{k} > 0.9 }}\n")
z('''    zone box dn_clr { at: clx, cly; size: 190, 34; cursor: pointer; active: dn_open and berries.count > 0 and cle > 0.9 }
    // DaNoGoo: ľavý klik = hrozno (znova klik, Esc alebo klik mimo = späť), ťahanie = iný okraj, pravý = kalendár
    on press dn_hit { dn_drag = true; dn_moved = false; wd.w = W; wd.h = H }
    on drag dn_hit while dn_drag and abs(drag.dx) + abs(drag.dy) > 6 { dn_moved = true; dn_open = false }
    on release dn_hit while dn_drag and dn_moved { dnd.x = pointer.x; dnd.y = pointer.y; impulse dn.wob 300; emit dn_drop; dn_moved = false; dn_drag = false }
    on release dn_hit while dn_drag and not dn_moved { dn_drag = false; toggle dn_open; impulse dn.wob 160; dash = false; pmenu = false }
    on press right dn_hit { impulse dn.wob 120; dn_open = false; emit dn_cal }
    on enter dn_hit { dn.h: 1 }
    on leave dn_hit { dn.h: 0 }
    on press dn_away { dn_open = false }
    on press right dn_away { dn_open = false }
    on key Escape while dn_open { dn_open = false }
    on change dn_open while dn_open { toast.p: 0 }
    on press dn_clr { dn_open = false; emit dn_clear_all }
    // bobule: ľavý klik = otvoriť, pravý = akcie upozornenia (iba ak nejaké má), odhodenie nabok = zahodiť
''')
for k in range(NB):
    z(f'''    on press br_hit.{k} {{ brk = {k}; brmoved = false; br.dx = 0; br.dy = 0 }}
    on drag br_hit.{k} while brk == {k} {{ br.dx = drag.dx; br.dy = drag.dy * 0.2 }}
    on drag br_hit.{k} while brk == {k} and abs(drag.dx) > 10 {{ brmoved = true }}
    on release br_hit.{k} while brk == {k} and brmoved and abs(br.dx) > 140 {{ brk = -1; brmoved = false; br.dx = 0; br.dy = 0; emit berry_dismiss({k}) }}
    on release br_hit.{k} while brk == {k} and brmoved {{ brk = -1; brmoved = false; br.dx = 0; br.dy = 0 }}
    on release br_hit.{k} while brk == {k} and not brmoved {{ brk = -1; emit berry_open({k}) }}
    on press right br_hit.{k} while berries.{k}.acts {{ ctx_up = false; ctx.x = mx; ctx.y = my; emit berry_menu({k}) }}
    on enter br_hit.{k} {{ berry_hot = {k} }}
    on leave br_hit.{k} {{ berry_hot = -1 }}
''')
z('''    // <<< DaNoGoo zóny
''')
zones = "".join(Z)

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
put(draw, "    // >>> DaNoGoo (danogoo.py)\n", "    // <<< DaNoGoo\n", "    // Hodiny: čas a dátum stoja rovno v kvapke (bod rámca → obrazovka)\n")
drop_texts = drop_texts.replace("{{", "{").replace("}}", "}").replace('"{UI}"', f'"{UI}"')
put(drop_texts, "    // >>> DaNoGoo texty (danogoo.py)\n", "    // <<< DaNoGoo texty\n", "    // ── spúšťač (vyteká z hodiniek smerom od okraja; v obrazovke, text rovno) ──\n")
put(zones, "    // >>> DaNoGoo zóny (danogoo.py)\n", "    // <<< DaNoGoo zóny\n", "    // <<< kvapky widgetov\n", before=False)

def once(old, new):
    global s
    if old in s:
        s = s.replace(old, new, 1)
# klávesnica aj pri hrozne (Esc), upozornenia už nie na Hodinách, bublina nového upozornenia z DaNoGoo
once("        keyboard: on_demand while dash   // hľadanie v dashboarde\n",
     "        keyboard: on_demand while dash or dn_open   // hľadanie v spúšťači, Esc pri hrozne DaNoGoo\n")
for line in ("            // upozornenia: kvapôčky prilepené hore vľavo na Hodinách (najviac tri) a jedna, ktorá práve padá\n",
             "            ellipse { at: sx - 25, s.y - 23; radius: 6.5 * so * (1 - dsh) * if(notes.count > 0, 1, 0); blend: 8 }\n",
             "            ellipse { at: sx - 10, s.y - 34; radius: 5.5 * so * (1 - dsh) * if(notes.count > 1, 1, 0); blend: 8 }\n",
             "            ellipse { at: sx + 6, s.y - 37; radius: 4.8 * so * (1 - dsh) * if(notes.count > 2, 1, 0); blend: 8 }\n",
             "            ellipse { at: sx + 4, s.y - 110 + 72 * nfall; radius: 6 * so * if(nfall > 0.02 and nfall < 0.97, 1, 0); scale: 0.85, 1.25; blend: 10 }\n",
             "        // farba upozornení podľa naliehavosti (nízka mätová, bežná jantárová, kritická červená)\n",
             "        ellipse { at: sx - 25, s.y - 23; radius: 3.8 * so * (1 - dsh) * if(notes.count > 0, 1, 0); color: pick(notes.0.urgency, #9ed6bd, #e4b283, #e07a5f) }\n",
             "        ellipse { at: sx - 10, s.y - 34; radius: 3.2 * so * (1 - dsh) * if(notes.count > 1, 1, 0); color: pick(notes.1.urgency, #9ed6bd, #e4b283, #e07a5f) }\n",
             "        ellipse { at: sx + 6, s.y - 37; radius: 2.8 * so * (1 - dsh) * if(notes.count > 2, 1, 0); color: pick(notes.2.urgency, #9ed6bd, #e4b283, #e07a5f) }\n"):
    once(line, "")
once("    // bublina nového upozornenia: vyleje sa z Hodín smerom od okraja (v obrazovke, text rovno), 6 s\n",
     "    // bublina nového upozornenia: vyleje sa z DaNoGoo smerom od okraja (v obrazovke, text rovno), 6 s\n")
once("    let tst.x = cxs + if(vert, away.x * (40 + 170 * toast.p), 170 * toast.p)\n    let tst.y = cys + if(vert, 0, away.y * (58 * toast.p))\n",
     "    let tst.x = dn.x + if(dn.vert > 0.5, dn.nx * (40 + 170 * toast.p), 170 * toast.p * if(dn.x > W - 420, -1, 1))\n    let tst.y = dn.y + if(dn.vert > 0.5, 0, dn.ny * (58 * toast.p))\n")
once("        ellipse { at: cxs, cys; radius: 33 }\n        box { at: tst.x, tst.y; size: 40 + 300 * toast.p",
     "        ellipse { at: dn.x, dn.y; radius: dn.r }\n        box { at: tst.x, tst.y; size: 40 + 300 * toast.p")
once("    on new_note { nfall: 0 ~0ms; nfall: 1 after 20ms; toast.p: 1 after 500ms; toast.p: 0 after 6500ms }\n",
     "    on new_note { impulse dn.wob 260; toast.p: 1 after 200ms; toast.p: 0 after 6500ms }\n")
TR = {"Clear all ({n})": "Vymazať všetko ({n})", "Clear all": "Vymazať všetko"}
i = s.index("    translations sk {\n") + len("    translations sk {\n")
s = s[:i] + "".join(f'        "{k}" = "{v}"\n' for k, v in TR.items() if f'        "{k}" =' not in s) + s[i:]
open(PLM, "w").write(s)
print(f"kvapka.plm: DaNoGoo · {NB} bobúľ")
