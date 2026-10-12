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
import goo

HERE = os.path.dirname(os.path.abspath(__file__))
PLM = os.path.join(HERE, "kvapka.plm")
NB = 6                                   # bobule (najnovšie upozornenia)
NY = 5                                   # žlté guľky počtu
UI = "Inter"
ICONS = "noctalia-tabler-icons"
import json as _json
_tab = _json.load(open("/usr/share/noctalia/assets/fonts/tabler.json"))
ICON = lambda n: chr(int(_tab[n]["codepoint"][2:], 16))
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
    event dn_drop ->
    event dn_cal
    event dn_clear_all ->
    event berry_open ->
    event berry_menu ->
    event berry_dismiss ->
    // karta DaNoGoo (pravý klik): kalendár s udalosťami a úlohami (spoločné s klasickým LatteOS) a počasie
    fact dc_open = false
    fact dc_hot = -1
    fact dc_empty = true                     // pole novej udalosti je prázdne (zástupný text)
    text dc_month = ""
    text dc_seltitle = ""
    text dc_new = ""
    text dc_hint = ""
    model days max 42 { d: text; inm: bool; today: bool; sel: bool; dot: bool }
    model evs max 5 { hm: text; title: text }
    model tds max 5 { title: text; done: bool }
    event dc_nav ->
    event dc_day ->
    event dc_todo ->
    event dc_ev_menu ->
    event dc_add ->
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
    follow dn.lift = if(dn_open or dc_open, 1, 0)
    prop dn.h = 0 ~lively
    prop dn.wob = 0 ~dnwobble
    // živý tvor: nakloní sa ku kurzoru, nad ňou sa nafúkne; pri otvorení vystrelí kolmo od okraja (pružina)
    let dn.out = 32 + 8 * dn.near + 2.5 * noise(time * 0.3 + 11.3) + 62 * dn.lift
    let dn.tx = dn.ax + dn.nx * dn.out + clamp(mx - dn.ax, -20, 20) * 0.28 * dn.near * abs(dn.px)
    let dn.ty = dn.ay + dn.ny * dn.out + clamp(my - dn.ay, -20, 20) * 0.28 * dn.near * abs(dn.py)
    prop dn.x = 0 ~lively
    prop dn.y = 0 ~lively
    // ťahanie: za kurzorom (cursor.x/y od Hyprlandu platí stále; pointer.x iba v pravidle a na tejto vrstve klame)
    follow dn.x = if(dn_drag and dn_moved, mx, dn.tx)
    follow dn.y = if(dn_drag and dn_moved, my, dn.ty)
    let dn.r = (31 + 3 * dn.h) * zd.p * so
    let dn.jit = 0.05 * sin(time * 9 + 3) * dn.h + dn.wob * 0.01
    // základňa na okraji: pri zdvihnutí (okno otvorené) sa stiahne — neostane ostrov; krk sa natiahne a zmizne
    let dn.neck = 16 * (1 - smooth(0.25, 0.8, dn.lift)) * if(dn.lift > 0.02, 1, 0) * so
    let dn.sheet = if(dn_drag and dn_moved, 0, 1) * so * (1 - smooth(0, 0.5, dn.lift))
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
    a(f"    let bre.{k} = clamp(dn.lift * 1.7 - brj.{k} * 0.12 - 0.2, 0, 1) * if({k} < berries.count and dn_open, 1, 0) * clamp(1 - abs(if(brk == {k} and brmoved, br.dx, 0)) / 260, 0, 1)\n")
a('''    let clx = if(dn.vert > 0.5, dn.x + dn.nx * (dn.r + 196), clamp(dn.x, 200, W - 200))
    let cly = if(dn.vert > 0.5, dn.y + ((berries.count - 1) / 2 + 1) * 60, dn.y + dn.ny * (dn.r + 46 + berries.count * 60))
    let cle = clamp(dn.lift * 1.7 - berries.count * 0.12 - 0.2, 0, 1) * if(berries.count > 0 and dn_open, 1, 0)
    let brend.x = if(berries.count > 0, clx, dn.x)
    let brend.y = if(berries.count > 0, cly, dn.y)
''')
a('''    // guľky počtu upozornení (goo: prilepené na kvapke)
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

# karta DaNoGoo (pravý klik): kalendár s udalosťami a úlohami, počasie — vyrastie z kvapky (pravidlo 9)
DW, DH = 600, 560
C = []
c = C.append
c(f"""    // karta DaNoGoo: vyrastie z kvapky smerom od okraja, vzhľad ako spúšťač (farby témy → káva pri kvapke)
    prop dcg = 0 ~dnspring
    follow dcg = if(dc_open, 1, 0)
    // okno sa ku kvapke pripája ROHOM (1. 10.): kvapka vystúpi a okno z nej vyrastie tak, aby bolo celé vidieť —
    // pozdĺž okraja tam, kde je miesto (pri dolnom a hornom okraji vpravo, inak vľavo; pri bočnom dole, inak hore).
    // Kvapky sa dajú presúvať, preto prichádzajú do úvahy všetky štyri rohy okna.
    let kc.sx = if(dn.vert > 0.5, 0, if(dn.x + {DW} + 12 <= W, 1, -1))
    let kc.sy = if(dn.vert > 0.5, if(dn.y + {DH} + 12 <= H, 1, -1), 0)
    let kc.tx = if(dn.vert > 0.5, dn.x + dn.nx * ({DW} / 2 - 10), dn.x + kc.sx * ({DW} / 2 - 10))
    let kc.ty = if(dn.vert > 0.5, dn.y + kc.sy * ({DH} / 2 - 10), dn.y + dn.ny * ({DH} / 2 - 10))
    let kc.x = dn.x + (kc.tx - dn.x) * clamp(dcg, 0, 1.05)
    let kc.y = dn.y + (kc.ty - dn.y) * clamp(dcg, 0, 1.05)
    let kc.gx = dn.nx * {DW} / 2 * dn.vert
    let kc.gy = dn.ny * {DH} / 2 * (1 - dn.vert)
    let dcs = clamp(dcg * 2 - 1, 0, 1)
    let c0.x = kc.tx - {DW} / 2 + 24
    let c0.y = kc.ty - {DH} / 2 + 20
    body {{
        gradient: kc.x + kc.gx, kc.y + kc.gy to kc.x - kc.gx, kc.y - kc.gy, l.win, l.win, l.win, mix(l.win, coffee, 0.35), coffee
        glass: 100% * l.glass
        lens: l.pearl > 0.5
        shine: pointer
        refraction: 120% * l.pearl
        dispersion: 260% * l.pearl
        light: 6%, kc.y - {DH} / 2, 60
        rim: 18%
        shadow: 0, 12, 34, 38% * dcg
        opacity: if(dcg > 0.01, 1, 0) * so
        box {{ at: kc.x, kc.y; size: (60 + {DW - 60} * dcg), (60 + {DH - 60} * dcg); corner: 30 - 6 * dcg }}
        // kvapka DaNoGoo trčí z rohu karty ako ucho (zliata s ňou)
        ellipse {{ at: dn.x, dn.y; radius: dn.r * clamp(dcg * 4, 0, 1); blend: 18 * dcg }}
    }}
    group {{
        opacity: dcs
        show: dcg > 0.5 and solo
        // hlavička: mesiac, šípky, Dnes
        text dc_month {{ at: c0.x + 2, c0.y + 18; anchor: left center; size: 20; weight: 600; color: l.fg; family: "{UI}" }}
        ellipse {{ at: c0.x + {DW - 48} - 124, c0.y + 18; radius: 15; color: if(dc_hot == 100, l.hover, l.var) }}
        text "{ICON('chevron-left')}" {{ at: c0.x + {DW - 48} - 124, c0.y + 19; anchor: center; size: 15; color: l.fg; family: "{ICONS}" }}
        ellipse {{ at: c0.x + {DW - 48} - 88, c0.y + 18; radius: 15; color: if(dc_hot == 101, l.hover, l.var) }}
        text "{ICON('chevron-right')}" {{ at: c0.x + {DW - 48} - 88, c0.y + 19; anchor: center; size: 15; color: l.fg; family: "{ICONS}" }}
        box {{ at: c0.x + {DW - 48} - 30, c0.y + 18; size: 58, 30; corner: 15; color: if(dc_hot == 102, l.hover, l.var) }}
        text "Today" {{ at: c0.x + {DW - 48} - 30, c0.y + 18; anchor: center; size: 12; weight: 500; color: l.fg; family: "{UI}" }}
""")
for i, wd in enumerate(["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]):
    c(f'        text "{wd}" {{ at: c0.x + {i} * 42 + 21, c0.y + 56; anchor: center; size: 11; weight: 600; color: l.dim; family: "{UI}" }}\n')
c(f"""        repeat k in 0..42 {{
            ellipse {{ at: c0.x + (k - 7 * floor(k / 7)) * 42 + 21, c0.y + 84 + floor(k / 7) * 38; radius: 16; color: if(days.$k.today, l.acc, l.hover); opacity: if(days.$k.today, 100%, if(days.$k.sel or dc_hot == k, 100%, 0)); show: k < days.count }}
            text days.$k.d {{ at: c0.x + (k - 7 * floor(k / 7)) * 42 + 21, c0.y + 83 + floor(k / 7) * 38; anchor: center; size: 13; weight: 500; color: if(days.$k.today, l.onacc, if(days.$k.inm, l.fg, l.dim)); opacity: if(days.$k.inm, 100%, 45%); show: k < days.count; family: "{UI}" }}
            ellipse {{ at: c0.x + (k - 7 * floor(k / 7)) * 42 + 21, c0.y + 96 + floor(k / 7) * 38; radius: 2.2; color: if(days.$k.today, l.onacc, l.acc); show: k < days.count and days.$k.dot }}
        }}
        // vybraný deň: udalosti a úlohy, nová udalosť
        box {{ at: c0.x + 435, c0.y + 170; size: 234, 300; corner: 14; color: l.var; opacity: 45% }}
        text dc_seltitle {{ at: c0.x + 332, c0.y + 40; anchor: left center; width: 206; lines: 1; size: 13.5; weight: 600; color: l.fg; family: "{UI}" }}
        repeat k in 0..5 {{
            text evs.$k.hm {{ at: c0.x + 332, c0.y + 66 + k * 28; anchor: left center; size: 11.5; weight: 600; color: l.acc; show: k < evs.count; family: "{UI}" }}
            text evs.$k.title {{ at: c0.x + 400, c0.y + 66 + k * 28; anchor: left center; width: 138; lines: 1; size: 12.5; color: l.fg; show: k < evs.count; family: "{UI}" }}
        }}
        text "No events" {{ at: c0.x + 332, c0.y + 66; anchor: left center; size: 12.5; color: l.dim; show: evs.count < 1; family: "{UI}" }}
        text "Tasks" {{ at: c0.x + 332, c0.y + 212; anchor: left center; size: 12; weight: 600; color: l.dim; family: "{UI}" }}
        repeat k in 0..5 {{
            text pick(if(tds.$k.done, 1, 0), "{ICON('square')}", "{ICON('square-check')}") {{ at: c0.x + 332, c0.y + 238 + k * 26; anchor: left center; size: 15; color: if(tds.$k.done, l.dim, l.acc); show: k < tds.count; family: "{ICONS}" }}
            text tds.$k.title {{ at: c0.x + 356, c0.y + 238 + k * 26; anchor: left center; width: 184; lines: 1; size: 12.5; color: if(tds.$k.done, l.dim, l.fg); show: k < tds.count; family: "{UI}" }}
        }}
        text "No tasks" {{ at: c0.x + 332, c0.y + 238; anchor: left center; size: 12.5; color: l.dim; show: tds.count < 1; family: "{UI}" }}
        box {{ at: c0.x + 435, c0.y + 298; size: 234, 36; corner: 12; color: l.acc; opacity: 75% }}
        box {{ at: c0.x + 435, c0.y + 298; size: 231, 33; corner: 10.5; color: l.var }}
        text dc_hint {{ at: c0.x + 330, c0.y + 298; anchor: left center; width: 210; lines: 1; size: 12.5; color: l.dim; show: dc_empty; family: "{UI}" }}
        input dc_new {{ at: c0.x + 330, c0.y + 298; width: 210; size: 12.5; color: l.fg; selection: l.hover; family: "{UI}" }}
        // počasie (presunuté z TimeGoo, 1. 10.): miesto, Dnes / Zajtra / Týždeň, súhrn, predpoveď
        text "{ICON('map-pin')}" {{ at: c0.x + 2, c0.y + 350; anchor: left center; size: 14; color: l.dim; family: "{ICONS}" }}
        text wx_place {{ at: c0.x + 22, c0.y + 350; anchor: left center; width: 150; lines: 1; size: 13; weight: 600; color: l.fg; family: "{UI}" }}
        repeat k in 0..3 {{
            box {{ at: c0.x + 214 + k * 64, c0.y + 350; size: 60, 26; corner: 13; color: if(wx_view == k, l.acc, l.hover); opacity: if(wx_view == k, 100%, if(wx_hot == k, 100%, 0)) }}
        }}
        text "Today" {{ at: c0.x + 214, c0.y + 350; anchor: center; size: 12; weight: 500; color: if(wx_view == 0, l.onacc, l.dim); family: "{UI}" }}
        text "Tomorrow" {{ at: c0.x + 278, c0.y + 350; anchor: center; size: 12; weight: 500; color: if(wx_view == 1, l.onacc, l.dim); family: "{UI}" }}
        text "Week" {{ at: c0.x + 342, c0.y + 350; anchor: center; size: 12; weight: 500; color: if(wx_view == 2, l.onacc, l.dim); family: "{UI}" }}
        text wx_icon {{ at: c0.x + 392, c0.y + 350; anchor: left center; size: 15; color: l.fg; family: "{ICONS}" }}
        text wx_sum {{ at: c0.x + 414, c0.y + 350; anchor: left center; width: 138; lines: 1; size: 12; color: l.fg; family: "{UI}" }}
        repeat k in 0..8 {{
            box {{ at: c0.x + k * 69 + 34, c0.y + 440; size: 62, 124; corner: 14; color: l.var; opacity: 60%; show: k < wx.count }}
            text wx.$k.label {{ at: c0.x + k * 69 + 34, c0.y + 398; anchor: center; size: 11.5; color: l.dim; show: k < wx.count; family: "{UI}" }}
            text wx.$k.glyph {{ at: c0.x + k * 69 + 34, c0.y + 438; anchor: center; size: 24; color: l.fg; show: k < wx.count; family: "{ICONS}" }}
            text wx.$k.temp {{ at: c0.x + k * 69 + 34, c0.y + 480; anchor: center; size: 12; weight: 600; color: l.fg; show: k < wx.count; family: "{UI}" }}
        }}
    }}
    // karta: klik mimo zavrie (pod ňou), karta sama kliky pohltí
    zone box dc_away {{ at: W / 2, H / 2; size: W, H; active: dc_open }}
    zone box dc_card {{ at: kc.tx, kc.ty; size: {DW}, {DH}; active: dc_open }}
    zone ellipse dc_prev {{ at: c0.x + {DW - 48} - 124, c0.y + 18; radius: 16; cursor: pointer; active: dc_open }}
    zone ellipse dc_next {{ at: c0.x + {DW - 48} - 88, c0.y + 18; radius: 16; cursor: pointer; active: dc_open }}
    zone box dc_today {{ at: c0.x + {DW - 48} - 30, c0.y + 18; size: 58, 30; cursor: pointer; active: dc_open }}
    repeat k in 0..42 {{
        zone ellipse dc_d.$k {{ at: c0.x + (k - 7 * floor(k / 7)) * 42 + 21, c0.y + 84 + floor(k / 7) * 38; radius: 18; cursor: pointer; active: dc_open and k < days.count }}
    }}
    repeat k in 0..5 {{
        zone box dc_ev.$k {{ at: c0.x + 435, c0.y + 66 + k * 28; size: 220, 26; active: dc_open and k < evs.count }}
        zone box dc_td.$k {{ at: c0.x + 435, c0.y + 238 + k * 26; size: 220, 24; cursor: pointer; active: dc_open and k < tds.count }}
    }}
    repeat k in 0..3 {{
        zone box wxs_hit.$k {{ at: c0.x + 214 + k * 64, c0.y + 350; size: 62, 28; cursor: pointer; active: dc_open }}
    }}
    zone box wxd_hit {{ at: 0, 0; size: 1, 1; active: false }}
    on press dc_away {{ dc_open = false }}
    on press right dc_away {{ dc_open = false }}
    on key Escape while dc_open {{ dc_open = false }}
    on change dc_open while dc_open {{ focus dc_new }}
    on submit dc_new {{ emit dc_add }}
    on press dc_prev {{ emit dc_nav(-1) }}
    on press dc_next {{ emit dc_nav(1) }}
    on press dc_today {{ emit dc_nav(0) }}
    on scroll dc_card {{ emit dc_nav(if(wheel > 0, -1, 1)) }}
    on enter dc_prev {{ dc_hot = 100 }}
    on leave dc_prev {{ dc_hot = -1 }}
    on enter dc_next {{ dc_hot = 101 }}
    on leave dc_next {{ dc_hot = -1 }}
    on enter dc_today {{ dc_hot = 102 }}
    on leave dc_today {{ dc_hot = -1 }}
    repeat k in 0..42 {{
        on press dc_d.$k {{ emit dc_day(k) }}
        on enter dc_d.$k {{ dc_hot = k }}
        on leave dc_d.$k {{ dc_hot = -1 }}
    }}
    repeat k in 0..5 {{
        on press dc_td.$k {{ emit dc_todo(k) }}
        on press right dc_ev.$k {{ ctx_up = false; ctx.x = mx; ctx.y = my; emit dc_ev_menu(k) }}
    }}
""")
card_block = "".join(C)
drop_texts = """    // >>> DaNoGoo texty (danogoo.py)
""" + '    // obsah kvapky: dátum a počasie (bez tváre)\n    text dn_date {{ at: dn.x, dn.y - 7 * zd.p; anchor: center; size: 11 * zd.p; weight: 700; color: ink; opacity: so; show: solo; family: "{UI}" }}\n    text dn_wx {{ at: dn.x - 1, dn.y + 9 * zd.p; anchor: right center; size: 12 * zd.p; color: ink; opacity: 85% * so; show: solo; family: "noctalia-tabler-icons" }}\n    text dn_temp {{ at: dn.x + 1, dn.y + 9 * zd.p; anchor: left center; size: 10.5 * zd.p; weight: 600; color: ink; opacity: 85% * so; show: solo; family: "{UI}" }}\n' + """    // <<< DaNoGoo texty
"""

Z = []
z = Z.append
z('''    // >>> DaNoGoo zóny (danogoo.py)
    // hrozno: klik mimo neho ho zavrie (pod bobuľami)
    zone box dn_away { at: W / 2, H / 2; size: W, H; active: dn_open }
    // počas ťahania zóna cez celú obrazovku: Hyprland posiela myš iba v zónach a odchod z nej by ťahanie ukončil
    zone ellipse dn_hit { at: dn.x, dn.y; radius: if(dn_drag, 4000, 34 * zd.p); cursor: pointer; active: solo }
''')
for k in range(NB):
    z(f"    zone box br_hit.{k} {{ at: brx.{k}, bry.{k}; size: 360, 52; cursor: pointer; active: dn_open and {k} < berries.count and bre.{k} > 0.9 }}\n")
z('''    zone box dn_clr { at: clx, cly; size: 190, 34; cursor: pointer; active: dn_open and berries.count > 0 and cle > 0.9 }
    // DaNoGoo: ľavý klik = hrozno (znova klik, Esc alebo klik mimo = späť), ťahanie = iný okraj, pravý = kalendár
    on scroll dn_hit { emit goo_wheel(2 * 2 + if(wheel > 0, 1, 0)) }
    on press dn_hit { dn_drag = true; dn_moved = false; wd.w = W; wd.h = H }
    on drag dn_hit while dn_drag and abs(drag.dx) + abs(drag.dy) > 6 { dn_moved = true; dn_open = false; dc_open = false }
    on release dn_hit while dn_drag and dn_moved { dnd.x = mx; dnd.y = my; impulse dn.wob 300; emit dn_drop; dn_moved = false; dn_drag = false }
    on release dn_hit while dn_drag and not dn_moved { dn_drag = false; toggle dn_open; dc_open = false; impulse dn.wob 160; dash = false; pmenu = false }
    on press right dn_hit { impulse dn.wob 120; dn_open = false; toggle dc_open; dash = false; pmenu = false; emit dn_cal }
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
zones = "".join(Z).replace("    // <<< DaNoGoo zóny\n", card_block + "    // <<< DaNoGoo zóny\n")

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
     "        keyboard: on_demand while dash or dn_open or dc_open   // hľadanie v spúšťači, Esc pri hrozne, udalosť v kalendári\n")
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
TR = {"Clear all ({n})": "Vymazať všetko ({n})", "Clear all": "Vymazať všetko", "No events": "Žiadne udalosti",
      "Tasks": "Úlohy", "No tasks": "Žiadne úlohy", "All day": "Celý deň", "Delete event": "Zmazať udalosť",
      "New event… 10:30 Meeting · ! task": "Nová udalosť… 10:30 Porada · ! úloha",
      "January": "január", "February": "február", "March": "marec", "April": "apríl", "May": "máj", "June": "jún",
      "July": "júl", "August": "august", "September": "september", "October": "október", "November": "november",
      "December": "december", "Mo": "po", "Tu": "ut", "We": "st", "Th": "št", "Fr": "pi", "Sa": "so", "Su": "ne"}
i = s.index("    translations sk {\n") + len("    translations sk {\n")
s = s[:i] + "".join(f'        "{k}" = "{v}"\n' for k, v in TR.items() if f'        "{k}" =' not in s) + s[i:]
# telo kvapky a strapec hrozna: do tela lišty (jedny pravidlá pre všetky kvapky, goo.py)
tvary = goo.kvapka("solo", "dn.x", "dn.y", "dn.r", "dn.ax", "dn.ay", "dn.nx", "dn.ny", "dn.sheet", jit="dn.jit", neck="dn.neck")
gv = "solo and dn_open and dn.lift > 0.05"
gx, gy = goo.L("dn.x + (brend.x - dn.x) * clamp(dn.lift * 1.4, 0, 1)", "dn.y + (brend.y - dn.y) * clamp(dn.lift * 1.4, 0, 1)")
tvary.append(f"line {{ from: {goo.at(gv, 'dn.x', 'dn.y')}; to: if({gv}, {gx}, hx), if({gv}, {gy}, mid - 8); width: 7 * clamp(dn.lift * 3, 0, 1); blend: 10 * clamp(dn.lift * 3, 0, 1) }}")
for k in range(NB):
    tvary.append(f"ellipse {{ at: {goo.at(f'bre.{k} > 0.02', f'brx.{k} - 176 * bre.{k}', f'bry.{k}')}; radius: 9 * bre.{k}; blend: 8 * bre.{k} }}")
s = goo.vloz(s, "DaNoGoo", tvary, goo.odlesk("solo", "dn.x", "dn.y", "dn.r"))
open(PLM, "w").write(s)
print(f"kvapka.plm: DaNoGoo · {NB} bobúľ")
