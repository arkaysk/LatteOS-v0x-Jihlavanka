#!/usr/bin/env python3
# PowerGoo v kvapka.plm (1. 10. 2026, LATTEOS-GOO.md 4.4): ponuka vypínača ako okno Goo (pravidlá 9–11) — pripojené
# ROHOM ku kvapke (vystúpi, okno z nej vyrastie tam, kde je miesto), navrchu Nastavenia a Monitor, pod čiarou
# Zamknúť / Odhlásiť / Uspať / Reštartovať / Vypnúť; na notebooku batéria v hlavičke a minibublinky na kvapke
# (zelené 3 / žlté 2 / červená 1, pod 10 % netrpezlivo pulzuje, pri nabíjaní stúpajú).
# Vypíše blok medzi značky  // >>> PowerGoo (powergoo.py) … // <<< PowerGoo
# Použitie: python3 session/kvapky/powergoo.py
import json, os

HERE = os.path.dirname(os.path.abspath(__file__))
PLM = os.path.join(HERE, "kvapka.plm")
UI, ICONS = "Inter", "noctalia-tabler-icons"
tab = json.load(open("/usr/share/noctalia/assets/fonts/tabler.json"))
ICON = lambda n: chr(int(tab[n]["codepoint"][2:], 16))
# riadky: (ikona, text, oddeľovač pred riadkom); kód riadku = poradie (power_do v logike)
ROWS = [("settings", "Settings", False), ("device-desktop-analytics", "Monitor", False),
        ("lock", "Lock", True), ("logout", "Sign out", False), ("moon", "Sleep", False),
        ("refresh", "Restart", False), ("power", "Shut down", False)]
RH = 40                                   # výška riadku
PW = 250
rows_y, y = [], 0
for _, _, sep in ROWS:
    y += 12 if sep else 0
    rows_y.append(y + RH // 2)
    y += RH
PH_ROWS = y

L = []
a = L.append
a(f'''    // >>> PowerGoo (powergoo.py)
    // ── PowerGoo: ponuka ako okno Goo, pripojené rohom ku kvapke vypínača (1. 10.) ──
    fact bat_present = false
    fact bat_pct = 100
    fact bat_chg = false
    // vypínač môže byť voľný (ťahaním na iný okraj, 1. 10.): poloha a orientácia podľa jeho vlastného okraja
    let pxs = if(pg_free or pg_moved, pg.fx, pick(side, px, W - px, edge - p.y, W - edge + p.y))
    let pys = if(pg_free or pg_moved, pg.fy, pick(side, p.y + H - edge, edge - p.y, px, H - px))
    let p.vert = if(pg_free, if(pg.side >= 2, 1, 0), vert)
    let p.ax = if(pg_free, pick(pg.side, 0, 0, 1, -1), away.x)
    let p.ay = if(pg_free, pick(pg.side, -1, 1, 0, 0), away.y)
    let pw = {PW}
    let ph = {PH_ROWS} + 28 + if(bat_present, 44, 0)
    // ucho: kvapka vypínača vystúpi kolmo od okraja; okno rastie od nej tam, kde je miesto (ktorýkoľvek zo 4 rohov)
    let pk.x = if(p.vert, pxs + p.ax * 58, pxs)
    let pk.y = if(p.vert, pys, pys + p.ay * 58)
    let p.sx = if(p.vert, 0, if(pk.x + pw + 12 <= W, 1, -1))
    let p.sy = if(p.vert, if(pk.y + ph + 12 <= H, 1, -1), 0)
    let pt.x = if(p.vert, pk.x + p.ax * (pw / 2 - 12), pk.x + p.sx * (pw / 2 - 12))
    let pt.y = if(p.vert, pk.y + p.sy * (ph / 2 - 12), pk.y + p.ay * (ph / 2 - 12))
    let p.swim = smooth(0, 0.45, pm)
    let p.grow = smooth(0.3, 1, pm)
    let pb.x = pxs + (pk.x - pxs) * p.swim
    let pb.y = pys + (pk.y - pys) * p.swim
    let pc.x = pk.x + (pt.x - pk.x) * p.grow
    let pc.y = pk.y + (pt.y - pk.y) * p.grow
    let p0.x = pt.x - pw / 2 + 12
    let p0.y = pt.y - ph / 2 + 14 + if(bat_present, 44, 0)
    let p.gx = p.ax * pw / 2 * p.vert
    let p.gy = p.ay * ph / 2 * (1 - p.vert)
    body {{
        gradient: pc.x + p.gx, pc.y + p.gy to pc.x - p.gx, pc.y - p.gy, l.win, l.win, mix(l.win, coffee, 0.4), coffee
        glass: 100% * l.glass
        lens: l.pearl > 0.5
        shine: pointer
        refraction: 120% * l.pearl
        dispersion: 260% * l.pearl
        rim: 18%
        light: 6%, pc.y - ph / 2, 40
        shadow: 0, 10, 26, 38% * pm
        opacity: if(pm > 0.01, 1, 0) * so
        box {{ at: if(p.grow > 0.02, pc.x, pb.x), if(p.grow > 0.02, pc.y, pb.y); size: 44 + (pw - 44) * p.grow, 44 + (ph - 44) * p.grow; corner: 22 - 6 * p.grow }}
        // ucho = kvapka vypínača v rohu okna (zliata s ním)
        ellipse {{ at: pb.x, pb.y; radius: 24 * clamp(pm * 4, 0, 1); blend: 16 * p.grow }}
    }}
    text "{ICON('power')}" {{ at: pb.x, pb.y; anchor: center; size: 16; color: ink; opacity: so * clamp(pm * 3 - 0.5, 0, 1); show: pm > 0.1; family: "{ICONS}" }}
    group {{
        opacity: clamp(pm * 2 - 1, 0, 1)
        show: pm > 0.5
        // batéria (notebook): percento, nabíjanie
        text pick(if(bat_chg, 1, 0), "{ICON('battery-2')}", "{ICON('battery-charging')}") {{ at: p0.x + 8, p0.y - 30; anchor: left center; size: 18; color: if(bat_pct < 15 and not bat_chg, #e5484d, l.fg); show: bat_present; family: "{ICONS}" }}
        text "{{bat_pct}} %" {{ at: p0.x + 36, p0.y - 30; anchor: left center; size: 15; weight: 600; color: l.fg; show: bat_present; family: "{UI}" }}
        text pick(if(bat_chg, 1, 0), "On battery", "Charging") {{ at: p0.x + pw - 32, p0.y - 30; anchor: right center; size: 12; color: l.dim; show: bat_present; family: "{UI}" }}
        box {{ at: pt.x, p0.y - 8; size: pw - 40, 1; color: l.line; show: bat_present }}
''')
for k, (icon, label, sep) in enumerate(ROWS):
    yy = rows_y[k]
    red = k == len(ROWS) - 1
    if sep:
        a(f"        box {{ at: pt.x, p0.y + {yy - RH // 2 - 6}; size: pw - 40, 1; color: l.line }}\n")
    a(f"        box {{ at: pt.x, p0.y + {yy}; size: pw - 24, {RH - 4}; corner: 10; color: l.hover; opacity: if(pm_hot == {k}, 100%, 0) }}\n")
    a(f"        text \"{ICON(icon)}\" {{ at: p0.x + 16, p0.y + {yy}; anchor: left center; size: 17; color: {'#e5484d' if red else 'l.fg'}; family: \"{ICONS}\" }}\n")
    a(f"        text \"{label}\" {{ at: p0.x + 44, p0.y + {yy}; anchor: left center; size: 13.5; weight: 500; color: {'#e5484d' if red else 'l.fg'}; family: \"{UI}\" }}\n")
a('''    }
''')
for k in range(len(ROWS)):
    a(f"    zone box pm_hit.{k} {{ at: pt.x, p0.y + {rows_y[k]}; size: pw - 20, {RH - 2}; cursor: pointer; active: pmenu }}\n")
# minibublinky batérie na kvapke vypínača
a('''    // batéria na kvapke vypínača: minibublinky (3 zelené ≥ 60 %, 2 žlté ≥ 30 %, 1 červená), pod 10 % pulzuje,
    // pri nabíjaní stúpajú a klesajú; na stolnom PC žiadne
    let bat_n = if(bat_pct >= 60, 3, if(bat_pct >= 30, 2, 1))
    let bat_pulse = if(bat_pct < 10 and not bat_chg, 1 + 0.25 * sin(time * 8), 1)
    body {
        color: pick(bat_n - 1, #e5484d, #f5c542, #46a758)
        rim: 30%
        light: 18%, 0, 16
        opacity: if(bat_present and solo, 1, 0) * (1 - pm)
''')
for k in range(3):
    ang = (k - 1) * 32
    a(f"        ellipse {{ at: pxs + (p.ax * cos({ang}) - p.ay * sin({ang})) * (27 + 3 * sin(time * 3 + {k * 2}) * if(bat_chg, 1, 0)), pys + (p.ay * cos({ang}) + p.ax * sin({ang})) * (27 + 3 * sin(time * 3 + {k * 2}) * if(bat_chg, 1, 0)); radius: 4.5 * if({k} < bat_n, 1, 0) * bat_pulse * so; blend: 4 }}\n")
a('''    }
    // <<< PowerGoo
''')
block = "".join(L)

s = open(PLM).read()
A, B = "    // >>> PowerGoo (powergoo.py)\n", "    // <<< PowerGoo\n"
if A in s:
    i = s.index(A); j = s.index(B, i) + len(B)
else:
    i = s.index("    // ── ponuka Vypnúť (vyteká z kvapky vypínača smerom od okraja) ──\n")
    j = s.index("    image power_icon {", i)
s = s[:i] + block + s[j:]
# pravidlá riadkov: 7 riadkov
if "    repeat k in 0..5 {\n        on press pm_hit.$k { emit power_do(k) }" in s:
    s = s.replace("    repeat k in 0..5 {\n        on press pm_hit.$k { emit power_do(k) }",
                  f"    repeat k in 0..{len(ROWS)} {{\n        on press pm_hit.$k {{ emit power_do(k) }}", 1)
TR = {"Monitor": "Monitor", "On battery": "Na batérii", "Charging": "Nabíja sa"}
i = s.index("    translations sk {\n") + len("    translations sk {\n")
s = s[:i] + "".join(f'        "{k}" = "{v}"\n' for k, v in TR.items() if f'        "{k}" =' not in s) + s[i:]
open(PLM, "w").write(s)
print(f"kvapka.plm: PowerGoo · {len(ROWS)} riadkov")
