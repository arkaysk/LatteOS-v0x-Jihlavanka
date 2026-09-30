#!/usr/bin/env python3
# Spúšťač v kvapka.plm (1. 10. 2026): vzhľad podľa používateľa — moderný, minimalistický, vkusný (inšpirácia: hľadanie
# Windows 11, spúšťač Noctalie). Rozloženie a funkcie z náčrtu ostávajú; farby z témy LatteOS (šálka = farba okien),
# karta pri uchu TimeGoo prechádza do kávy (goo). Ikony Tabler (písmo Noctalie), písmo Inter.
# V goo tele (`body`) pleamar nedovolí `repeat` ani `for`, a merania (`measure`) nejdú v komponente, preto tento
# skript vypíše spúšťač medzi značky
#   // >>> spúšťač (spustac.py)   …   // <<< spúšťač
# a ikony (znaky písma Tabler) a poradie tém do ikony.luau pre logiku.
# Použitie: python3 session/kvapky/spustac.py
import ast, json, os, re, subprocess

HERE = os.path.dirname(os.path.abspath(__file__))
PLM = os.path.join(HERE, "kvapka.plm")
TABLER_TTF = "/usr/share/noctalia/assets/fonts/noctalia-tabler.ttf"
TABLER_JSON = "/usr/share/noctalia/assets/fonts/tabler.json"
UI = "Inter"
NB, NC, NH, NF, NR = 8, 7, 7, 12, 4          # bubliny, čipy, riadky, dlaždice obľúbených, nedávne

# ── ikony Tabler ──
tab = json.load(open(TABLER_JSON))
ICON = lambda n: chr(int(tab[n]["codepoint"][2:], 16))
try:
    ICONS = subprocess.run(["fc-query", "-f", "%{family}", TABLER_TTF], capture_output=True, text=True).stdout.split(",")[0].strip()
except OSError:
    ICONS = ""
ICONS = ICONS or "tabler-icons"
LOGIC_ICONS = ["sparkles", "search", "folder", "world", "terminal-2", "settings", "plus", "message-plus", "folder-open",
               "trash", "sun", "cloud", "sun-low", "cloud-rain", "cloud-snow", "cloud-storm", "cloud-fog", "sun-high",
               "map-pin", "check", "chevron-down", "chevron-right", "x",
               "layout-dashboard", "stopwatch", "hourglass", "alarm"]

# ── farby tém (session/themes/make-themes.py) ──
src = open(os.path.join(HERE, "..", "themes", "make-themes.py")).read()
THEMES = None
for node in ast.parse(src).body:
    if isinstance(node, ast.Assign) and getattr(node.targets[0], "id", "") == "THEMES":
        THEMES = ast.literal_eval(node.value)
LATTE = ("#E4B283", "#1E1712", "#1B1410", "#261D17", "#F3EBDD", "#CDBCA6", "#4A3B30", "#3A2D24")   # LatteTheme.qml
order = list(THEMES)
cols = {k: [] for k in ("acc", "onacc", "win", "var", "fg", "dim", "line", "hover")}
for tid in order:
    t = THEMES[tid]
    vals = [v or LATTE[i] for i, v in enumerate(t[6:14])]
    for key, v in zip(cols, vals):
        cols[key].append(v.lower())

def pickc(key):
    # pick() berie iba čísla a let s farbou iba farbu alebo mix() → téma cez mix(…, if(tema == i, 1, 0))
    v = cols[key]
    expr = v[0]
    for i in range(1, len(v)):
        expr = f"mix({expr}, {v[i]}, if(tema == {i}, 1, 0))"
    return expr

# materiál témy (make-themes.py kľúč „material“): textúra (kov), perleťové dúhové sklo, priehľadnosť karty
TEX = ["hlinik", "striebro", "zlato"]                     # session/kvapky/textury/<téma>_{v,h}.webp (textury.py)
mat = {tid: THEMES[tid][4] for tid in order}
idx = {tid: i for i, tid in enumerate(order)}
GLASS = {"sklo": 0.80, "fazety": 0.72, "mraz": 0.72, "jantar": 0.62, "kov": 0.45, "kamen": 0.35, "ziadny": 0.0}
glass_expr = "pick(tema, " + ", ".join(f"{GLASS.get(mat[t], 0.4):.2f}" for t in order) + ")"
pearl = [t for t in order if mat[t] in ("sklo", "fazety", "mraz", "jantar")]
pearl_expr = " or ".join(f"tema == {idx[t]}" for t in pearl) or "false"
TEX_DECL = "".join(f'    image tex.{t}.{o} = file "textury/{t}_{o}.webp", {640}, {560}\n' for t in TEX for o in ("v", "h"))
TEX_DRAW = "".join(f"            image tex.{t}.{o} {{ at: dc.x - dw / 2, dc.y - dh / 2; size: dw, dh; show: tema == {idx[t]} and {'vert' if o == 'h' else 'not vert'} }}\n"
                   for t in TEX for o in ("v", "h"))

L = []
a = L.append
a(f'''    // >>> spúšťač (spustac.py)
    // Vzhľad (1. 10., používateľ: „moderné ikony, fonty, trošku minimalizmu; chytrosti, vkusnosti a užitočnosti“):
    // farby z témy LatteOS (fact tema = poradie v make-themes.py), karta od ucha prechádza z kávy do farby okien.
    let l.acc = {pickc("acc")}
    let l.onacc = {pickc("onacc")}
    let l.win = {pickc("win")}
    let l.var = {pickc("var")}
    let l.fg = {pickc("fg")}
    let l.dim = {pickc("dim")}
    let l.line = {pickc("line")}
    let l.hover = {pickc("hover")}
    // priehľadnosť (sklo karty) a perleťové dúhové okraje pri sklenených témach; kov má textúru
    let l.glass = {glass_expr}
    let l.pearl = if({pearl_expr}, 1, 0)
{TEX_DECL}    let dw = 640
    let dh = 560
    // ucho (roh okna) je presne nad Hodinami (na bočnom okraji presne vedľa): kvapka vystúpi kolmo od okraja a späť
    // padne rovno ako pod ťarchou. Okno rastie od ucha doprava (dolu), ak je tam miesto, inak doľava (hore).
    let d.rise = 74
    let dk.x = if(vert, cxs + away.x * d.rise, cxs)
    let dk.y = if(vert, cys, cys + away.y * d.rise)
    let d.sx = if(vert, 0, if(cxs + dw + 12 <= W, 1, -1))
    let d.sy = if(vert, if(cys + dh + 12 <= H, 1, -1), 0)
    let dt.x = if(vert, dk.x + away.x * dw / 2, dk.x + d.sx * dw / 2)
    let dt.y = if(vert, dk.y + d.sy * dh / 2, dk.y + away.y * dh / 2)
    // kvapka Hodín sa odlepí od lišty, pružne dopláva do rohu karty najbližšieho Hodinám a karta z nej vyrastie;
    // kým je okno otvorené, ostane v rohu ako trčiace „ucho“ s časom (ako v Marei — je poznať, odkiaľ okno je).
    // Pri zatvorení sa karta najprv zloží do ucha a až potom ucho pružne odkvapne domov na okraj.
    let d.grow = smooth(0.35, 1, dsh) * smooth(0.75, 0.97, dsw)
    let db.x = cxs + (dk.x - cxs) * dsw
    let db.y = cys + (dk.y - cys) * dsw
    // vlákno od Hodín k letiacej kvapke (sliz): čím ďalej, tým tenšie; pri 58 px praskne, pod 24 px sa zlepí
    let e.d = length(db.x - cxs, db.y - cys)
    let e.ux = (db.x - cxs) / max(e.d, 1)
    let e.uy = (db.y - cys) / max(e.d, 1)
    let e.k = if(esnap or dsw < 0.02, 0, 1) * clamp(1 - (e.d - 70) / 160, 0.35, 1)
    let dc.x = dk.x + (dt.x - dk.x) * d.grow
    let dc.y = dk.y + (dt.y - dk.y) * d.grow
    let d0.x = dt.x - dw / 2 + 28              // obsah: ľavý horný roh
    let d0.y = dt.y - dh / 2 + 24
    let cw = dw - 56                           // šírka obsahu
    let dshow = clamp(dsh * 2 - 1, 0, 1)
    // prechod farby: ďaleko od ucha farba okien, pri uchu káva
    let g.ax = away.x * dw / 2 * if(vert, 1, 0)
    let g.ay = away.y * dh / 2 * if(vert, 0, 1)
    body {{
        gradient: dc.x + g.ax, dc.y + g.ay to dc.x - g.ax, dc.y - g.ay, l.win, l.win, l.win, mix(l.win, coffee, 0.35), coffee
        glass: 100% * l.glass
        lens: l.pearl > 0.5
        shine: pointer
        refraction: 120% * l.pearl
        dispersion: 260% * l.pearl
        light: 6%, dc.y - dh / 2, 60
        rim: 18%
        shadow: 0, 12, 34, 38% * dsh
        opacity: if(dsw > 0.02 or dsh > 0.01, 1, 0) * so
        box {{ at: dc.x, dc.y; size: (60 + (dw - 60) * d.grow) * if(d.grow > 0.01, 1, 0), (60 + (dh - 60) * d.grow) * if(d.grow > 0.01, 1, 0); corner: 30 - 6 * d.grow }}
        // vlákno k Hodinám (kým nepraskne) a po prasknutí pahýle na oboch koncoch, ktoré sa stiahnu
        // kým sú spojené, vlákno je pri koreni (lišta) hrubé a k uchu sa zužuje (1. 10., používateľ); ďalej tenšie
        ellipse {{ at: cxs, cys; radius: 18 * e.k; blend: 14 }}
        line {{ from: cxs, cys; to: cxs + (db.x - cxs) * 0.4, cys + (db.y - cys) * 0.4; width: 26 * e.k; blend: 12 * e.k }}
        line {{ from: cxs + (db.x - cxs) * 0.35, cys + (db.y - cys) * 0.35; to: cxs + (db.x - cxs) * 0.75, cys + (db.y - cys) * 0.75; width: 16 * e.k; blend: 12 * e.k }}
        line {{ from: cxs + (db.x - cxs) * 0.7, cys + (db.y - cys) * 0.7; to: db.x, db.y; width: 9 * e.k; blend: 12 * e.k }}
        line {{ from: db.x, db.y; to: db.x - e.ux * 22 * estub, db.y - e.uy * 22 * estub; width: 6 * estub; blend: 8 * clamp(estub * 3, 0, 1) }}
        line {{ from: cxs, cys; to: cxs + e.ux * 22 * estub, cys + e.uy * 22 * estub; width: 6 * estub; blend: 8 * clamp(estub * 3, 0, 1) }}
        // ucho = kvapka Hodín (trčí z rohu, zliata s kartou)
        ellipse {{ at: db.x, db.y; radius: 33 * clamp(dsw * 4, 0, 1); scale: 1 + swob * 0.01, 1 - swob * 0.01; blend: 18 * d.grow }}
    }}
    text now.time {{ at: db.x, db.y - 1; anchor: center; size: 13; weight: 800; color: ink; opacity: so * clamp(dsw * 3 - 0.5, 0, 1); show: dsw > 0.1 }}
    // textúra materiálu témy (brúsený hliník, striebro, tepané zlato) na časti karty ďaleko od ucha; k uchu sa vytratí
    group {{
        opacity: dshow
        show: dsh > 0.5 and d.grow > 0.98
        clip box {{ at: dc.x, dc.y; size: dw, dh; corner: 24 }}
        group {{
            pivot: dc.x, dc.y
            rotate: if(vert, if(away.x > 0, 0, 180), if(away.y < 0, 0, 180)) * 1deg
{TEX_DRAW}        }}
    }}
    // obsah: y0 = horný okraj obsahu pod poľom; riadok režimu a počasia sú pri spodku karty
    let y0 = d0.y + 64
    let yc = d0.y + 494                        // riadok režimu (čipy) — úplne dole (počasie je v DaNoGoo, 1. 10.)
    let show_chat = tview == 0 and smode == 0 and not wx_detail
    let show_favs = tview == 0 and smode == 1 and not typing and not wx_detail
    let show_hits = tview == 0 and smode > 0 and not wx_detail and not show_favs
    prop mo = 0 ~springy
    follow mo = if(mode_open and dash, 1, 0)
    prop aiw = 0 ~lively
    follow aiw = if(ai_wait, 1, 0)
    fact chst = 0
    spring glide = 220, 30
    prop chs = 0 ~glide
    follow chs = chst
''')
# rozhovor: merania a polohy bublín
for k in range(NB): a(f"    measure ch.{k}\n")
a("    let cy.0 = y0 + 8 + 50 * aiw - chs\n")
for k in range(1, NB):
    a(f"    let cy.{k} = cy.{k-1} + if({k-1} < chat.count, ch.{k-1}.height + 34, 0)\n")
a(f"    let chh = cy.{NB-1} + if({NB-1} < chat.count, ch.{NB-1}.height + 34, 0) - cy.0 + 50 * aiw\n")
for k in range(NB):
    a(f"    let bx.{k} = if(chat.{k}.me, d0.x + 4, d0.x + cw - ch.{k}.width - 32)\n")
    a(f"    let bv.{k} = if({k} < chat.count and show_chat, 1, 0)\n")
# čipy: šírka podľa textu, ikonky a šípky
for k in range(NC): a(f"    measure cm.{k}\n")
for k in range(NC):
    a(f"    let cwd.{k} = 26 + if(chips.{k}.hasg, 18, 0) + if(chips.{k}.label_on, cm.{k}.width + if(chips.{k}.hasg, 4, 0), -4) + if(chips.{k}.drop, 16, 0)\n")
a("    let chx.0 = d0.x\n")
for k in range(1, NC):
    a(f"    let chx.{k} = chx.{k-1} + if({k-1} < chips.count, cwd.{k-1} + 8, 0)\n")
a(f'''    let fav_rows = clamp(floor((favs.count + 5) / 6), 1, 2)
    let ry0 = y0 + 46 + fav_rows * 90          // nadpis „Nedávne“
    group {{
        opacity: dshow
        show: dsh > 0.5 and tview == 0
        // pole: ikona režimu (klik = výber) + text; tenký akcentový okraj
        box {{ at: d0.x + cw / 2, d0.y + 24; size: cw, 48; corner: 14; color: l.acc; opacity: if(renaming, 100%, 75%) }}
        box {{ at: d0.x + cw / 2, d0.y + 24; size: cw - 3, 45; corner: 12.5; color: l.var }}
        box {{ at: d0.x + 30, d0.y + 24; size: 48, 34; corner: 10; color: l.acc; opacity: if(mode_open, 26%, 12%) }}
        repeat k in 0..5 {{
            text modes.$k.glyph {{ at: d0.x + 22, d0.y + 24; anchor: center; size: 18; color: l.acc; show: smode == k; family: "{ICONS}" }}
        }}
        text "{ICON("chevron-down")}" {{ at: d0.x + 41, d0.y + 25; anchor: center; size: 11; color: l.acc; family: "{ICONS}" }}
        text hint {{ at: d0.x + 66, d0.y + 24; anchor: left center; width: cw - 80; lines: 1; size: 15; color: l.dim; opacity: 80%; show: not typing and not renaming; family: "{UI}" }}
        input query {{ at: d0.x + 66, d0.y + 24; width: cw - 80; size: 15; color: l.fg; selection: l.hover; family: "{UI}" }}
    }}
    group {{
        opacity: dshow
        show: dsh > 0.5
        // riadky: aplikácie, súbory, vyhľadávače, príkazy — karta s ikonou, názvom a popisom pod ním
        repeat k in 0..{NH} {{
            box {{ at: d0.x + cw / 2, y0 + 22 + k * 48; size: cw, 44; corner: 12; color: if(hits.$k.warn, #e07a5f, if(k == sel and typing, l.acc, if(hit_hot == k, l.hover, l.var))); opacity: if(hits.$k.warn, 35%, if(k == sel and typing, 100%, if(hit_hot == k, 100%, 60%))); show: show_hits and k < hits.count }}
            image hits.$k.icon {{ at: d0.x + 14, y0 + 8 + k * 48; size: 28, 28; show: show_hits and k < hits.count }}
            text hits.$k.name {{ at: d0.x + 54, y0 + 14 + k * 48; anchor: left center; width: cw - 70; lines: 1; size: 14; weight: 500; color: if(k == sel and typing and not hits.$k.warn, l.onacc, l.fg); show: show_hits and k < hits.count; family: "{UI}" }}
            text hits.$k.sub {{ at: d0.x + 54, y0 + 31 + k * 48; anchor: left center; width: cw - 70; lines: 1; size: 11.5; color: if(k == sel and typing and not hits.$k.warn, l.onacc, l.dim); opacity: 90%; show: show_hits and k < hits.count; family: "{UI}" }}
        }}
        // aplikácie bez textu: obľúbené zvolenej záložky ako dlaždice (6 × 2) a nedávne (2 × 2)
        text fav_title {{ at: d0.x + 2, y0 + 10; anchor: left center; size: 12.5; weight: 600; color: l.dim; show: show_favs; family: "{UI}" }}
        repeat k in 0..{NF} {{
            box {{ at: d0.x + 44 + (k - 6 * floor(k / 6)) * 96, y0 + 67 + floor(k / 6) * 90; size: 88, 82; corner: 12; color: if(fav_hot == k, l.hover, l.var); opacity: if(fav_hot == k, 100%, 55%); show: show_favs and k < favs.count }}
            image favs.$k.icon {{ at: d0.x + 26 + (k - 6 * floor(k / 6)) * 96, y0 + 41 + floor(k / 6) * 90; size: 36, 36; show: show_favs and k < favs.count }}
            text favs.$k.name {{ at: d0.x + 44 + (k - 6 * floor(k / 6)) * 96, y0 + 91 + floor(k / 6) * 90; anchor: center; width: 80; lines: 1; size: 11.5; color: l.fg; show: show_favs and k < favs.count; family: "{UI}" }}
        }}
        text "Recent" {{ at: d0.x + 2, ry0; anchor: left center; size: 12.5; weight: 600; color: l.dim; show: show_favs and recent.count > 0; family: "{UI}" }}
        repeat k in 0..{NR} {{
            box {{ at: d0.x + 144 + (k - 2 * floor(k / 2)) * 296, ry0 + 34 + floor(k / 2) * 46; size: 288, 40; corner: 10; color: if(rec_hot == k, l.hover, l.var); opacity: if(rec_hot == k, 100%, 55%); show: show_favs and k < recent.count }}
            image recent.$k.icon {{ at: d0.x + 12 + (k - 2 * floor(k / 2)) * 296, ry0 + 22 + floor(k / 2) * 46; size: 24, 24; show: show_favs and k < recent.count }}
            text recent.$k.name {{ at: d0.x + 46 + (k - 2 * floor(k / 2)) * 296, ry0 + 34 + floor(k / 2) * 46; anchor: left center; width: 230; lines: 1; size: 13.5; color: l.fg; show: show_favs and k < recent.count; family: "{UI}" }}
        }}
        // prázdny obsah: nápoveda podľa režimu
        text note {{ at: d0.x + 2, y0 + 20; anchor: left center; width: cw - 8; lines: 3; size: 13; color: l.dim; show: not wx_detail and ((show_chat and chat.count < 1 and not ai_wait) or (show_hits and hits.count < 1) or (show_favs and favs.count < 1)); family: "{UI}" }}
    }}
    // rozhovor: bubliny používateľa (akcent, vľavo) a AI (vpravo), goo s kvapôčkou-chvostíkom k poľu
    group {{
        opacity: dshow
        show: dsh > 0.5 and show_chat
        clip box {{ at: d0.x + cw / 2, y0 + 182; size: cw + 20, 364 }}
        body {{
            color: l.var
            rim: 12%
            light: 5%, 0, 30
            ellipse {{ at: d0.x + cw - 24, cy.0 - 50 * aiw + 22; radius: 20 * aiw; scale: 1.5 + 0.08 * sin(time * 6), 1; blend: 8 * aiw }}
''')
for k in range(NB):
    a(f"            box {{ from: bx.{k}, cy.{k}; size: (ch.{k}.width + 28) * bv.{k} * if(chat.{k}.me, 0, 1), ch.{k}.height + 22; corner: 16 }}\n")
    a(f"            ellipse {{ at: bx.{k} + ch.{k}.width + 26, cy.{k} + 2; radius: 5 * bv.{k} * if(chat.{k}.me, 0, 1); blend: 7 * bv.{k} * if(chat.{k}.me, 0, 1) }}\n")
a('''        }
        body {
            color: l.acc
            rim: 12%
            light: 6%, 0, 30
''')
for k in range(NB):
    a(f"            box {{ from: bx.{k}, cy.{k}; size: (ch.{k}.width + 28) * bv.{k} * if(chat.{k}.me, 1, 0), ch.{k}.height + 22; corner: 16 }}\n")
    a(f"            ellipse {{ at: bx.{k} + 2, cy.{k} + 2; radius: 5 * bv.{k} * if(chat.{k}.me, 1, 0); blend: 7 * bv.{k} * if(chat.{k}.me, 1, 0) }}\n")
a(f'''        }}
        text "• • •" {{ at: d0.x + cw - 24, cy.0 - 50 * aiw + 22; anchor: center; size: 12; weight: 800; color: l.fg; opacity: aiw * (0.5 + 0.5 * sin(time * 6)); family: "{UI}" }}
        repeat k in 0..{NB} {{
            text chat.$k.txt {{ at: bx.$k + 14, cy.$k + 11 + ch.$k.height / 2; anchor: left center; size: 13.5; line_height: 1.35; color: if(chat.$k.me, l.onacc, l.fg); measure: ch.$k; show: k < chat.count; family: "{UI}" }}
        }}
    }}
    group {{
        opacity: dshow
        show: dsh > 0.5
        // riadok režimu: čipy (záložky obľúbených + „+“, služba a model AI, vyhľadávač…): ikonka, text, šípka ponuky
        repeat k in 0..{NC} {{
            box {{ at: chx.$k + cwd.$k / 2, yc; size: cwd.$k, 32; corner: 16; color: if(chips.$k.on, l.acc, if(chip_hot == k, l.hover, l.var)); opacity: if(chips.$k.on or chip_hot == k, 100%, 85%); show: k < chips.count }}
            text chips.$k.glyph {{ at: chx.$k + 13, yc; anchor: left center; size: 15; color: if(chips.$k.on, l.onacc, l.fg); show: k < chips.count and chips.$k.hasg; family: "{ICONS}" }}
            text chips.$k.label {{ at: chx.$k + 13 + if(chips.$k.hasg, 22, 0), yc; anchor: left center; size: 12.5; weight: 500; color: if(chips.$k.on, l.onacc, l.fg); measure: cm.$k; show: k < chips.count and chips.$k.label_on; family: "{UI}" }}
            text "{ICON("chevron-down")}" {{ at: chx.$k + cwd.$k - 13, yc + 1; anchor: right center; size: 12; color: if(chips.$k.on, l.onacc, l.dim); show: k < chips.count and chips.$k.drop; family: "{ICONS}" }}
        }}
    }}
''')
a(f'''    // ── časové menu TimeGoo (pravý klik): tá istá karta z ucha, obsah Prehľad · Stopky · Minútka · Budíky ──
    let tv = tview == 1 and not wx_detail
    let tcx = d0.x + cw / 2
    group {{
        opacity: dshow
        show: dsh > 0.5 and tview == 1
        // hlavička: čas veľkým písmom, dátum a týždeň vpravo
        text now.time {{ at: d0.x + 2, d0.y + 24; anchor: left center; size: 40; weight: 300; color: l.fg; family: "{UI}" }}
        text t_date {{ at: d0.x + cw - 2, d0.y + 14; anchor: right center; size: 14; weight: 500; color: l.fg; family: "{UI}" }}
        text t_week {{ at: d0.x + cw - 2, d0.y + 36; anchor: right center; size: 12; color: l.dim; family: "{UI}" }}
    }}
    group {{
        opacity: dshow
        show: dsh > 0.5 and tv and ttab == 0
        // prehľad: digitálna pohoda (klik = podrobnosti v Monitore), svetové hodiny, najbližší budík / minútka
        box {{ at: tcx, y0 + 74; size: cw, 140; corner: 14; color: if(t_hot == 70, l.hover, l.var); opacity: if(t_hot == 70, 100%, 55%) }}
        text "{ICON("leaf")}" {{ at: d0.x + 16, y0 + 24; anchor: left center; size: 15; color: l.acc; family: "{ICONS}" }}
        text "Digital wellbeing today" {{ at: d0.x + 38, y0 + 24; anchor: left center; size: 12.5; weight: 600; color: l.dim; family: "{UI}" }}
        text wb_total {{ at: d0.x + cw - 16, y0 + 24; anchor: right center; size: 13; weight: 600; color: l.fg; family: "{UI}" }}
        repeat k in 0..3 {{
            text wbl.$k.name {{ at: d0.x + 16, y0 + 56 + k * 30; anchor: left center; width: 170; lines: 1; size: 13; color: l.fg; show: k < wbl.count; family: "{UI}" }}
            box {{ from: d0.x + 196, y0 + 53 + k * 30; size: cw - 290, 6; corner: 3; color: l.line; opacity: 60%; show: k < wbl.count }}
            box {{ from: d0.x + 196, y0 + 53 + k * 30; size: (cw - 290) * wbl.$k.frac, 6; corner: 3; color: l.acc; show: k < wbl.count }}
            text wbl.$k.dur {{ at: d0.x + cw - 16, y0 + 56 + k * 30; anchor: right center; size: 12; color: l.dim; show: k < wbl.count; family: "{UI}" }}
        }}
        text "Nothing yet today" {{ at: d0.x + 16, y0 + 56; anchor: left center; size: 13; color: l.dim; show: wbl.count < 1; family: "{UI}" }}
        text "{ICON("world")}" {{ at: d0.x + 2, y0 + 170; anchor: left center; size: 15; color: l.dim; family: "{ICONS}" }}
        text "World clocks" {{ at: d0.x + 24, y0 + 170; anchor: left center; size: 12.5; weight: 600; color: l.dim; family: "{UI}" }}
        repeat k in 0..4 {{
            box {{ at: d0.x + 144 + (k - 2 * floor(k / 2)) * 296, y0 + 204 + floor(k / 2) * 46; size: 288, 40; corner: 10; color: l.var; opacity: 55%; show: k < zones.count }}
            text zones.$k.city {{ at: d0.x + 14 + (k - 2 * floor(k / 2)) * 296, y0 + 204 + floor(k / 2) * 46; anchor: left center; width: 150; lines: 1; size: 13.5; color: l.fg; show: k < zones.count; family: "{UI}" }}
            text zones.$k.diff {{ at: d0.x + 214 + (k - 2 * floor(k / 2)) * 296, y0 + 204 + floor(k / 2) * 46; anchor: right center; size: 11.5; color: l.dim; show: k < zones.count; family: "{UI}" }}
            text zones.$k.hm {{ at: d0.x + 274 + (k - 2 * floor(k / 2)) * 296, y0 + 204 + floor(k / 2) * 46; anchor: right center; size: 16; weight: 500; color: l.fg; show: k < zones.count; family: "{UI}" }}
        }}
        text "Add cities in Settings › Date, time and location." {{ at: d0.x + 2, y0 + 204; anchor: left center; size: 13; color: l.dim; show: zones.count < 1; family: "{UI}" }}
        text "{ICON("alarm")}" {{ at: d0.x + 2, y0 + 340; anchor: left center; size: 15; color: l.acc; show: t_has_next; family: "{ICONS}" }}
        text t_next {{ at: d0.x + 24, y0 + 340; anchor: left center; width: cw - 30; lines: 1; size: 13; color: l.fg; show: t_has_next; family: "{UI}" }}
    }}
    group {{
        opacity: dshow
        show: dsh > 0.5 and tv and ttab == 1
        // stopky: veľké číslice, tlačidlá štart/pauza (akcent), medzičas, vynulovať; medzičasy pod nimi
        text t_sw {{ at: tcx, y0 + 76; anchor: center; size: 60; weight: 300; color: l.fg; family: "{UI}" }}
        ellipse {{ at: tcx, y0 + 168; radius: 32; color: if(t_hot == 1, mix(l.acc, l.fg, 0.15), l.acc) }}
        text pick(if(sw_run, 1, 0), "{ICON("player-play")}", "{ICON("player-pause")}") {{ at: tcx, y0 + 169; anchor: center; size: 24; color: l.onacc; family: "{ICONS}" }}
        ellipse {{ at: tcx - 90, y0 + 168; radius: 24; color: if(t_hot == 2, l.hover, l.var); opacity: if(sw_run, 100%, 45%) }}
        text "{ICON("flag")}" {{ at: tcx - 90, y0 + 169; anchor: center; size: 18; color: l.fg; opacity: if(sw_run, 100%, 45%); family: "{ICONS}" }}
        ellipse {{ at: tcx + 90, y0 + 168; radius: 24; color: if(t_hot == 3, l.hover, l.var) }}
        text "{ICON("refresh")}" {{ at: tcx + 90, y0 + 169; anchor: center; size: 18; color: l.fg; family: "{ICONS}" }}
        repeat k in 0..5 {{
            box {{ at: tcx, y0 + 236 + k * 26; size: 320, 24; corner: 8; color: l.var; opacity: if(k == 0, 55%, 0); show: k < laps.count }}
            text laps.$k.label {{ at: tcx - 146, y0 + 236 + k * 26; anchor: left center; size: 12.5; color: l.dim; show: k < laps.count; family: "{UI}" }}
            text laps.$k.time {{ at: tcx + 146, y0 + 236 + k * 26; anchor: right center; size: 13.5; weight: 500; color: l.fg; show: k < laps.count; family: "{UI}" }}
        }}
    }}
    group {{
        opacity: dshow
        show: dsh > 0.5 and tv and ttab == 2
        // minútka: kruh (koliesko nad ním mení minúty, klik spustí / pozastaví), predvoľby, zrušiť
        arc {{ at: tcx, y0 + 122; radius: 86; span: 360deg; width: 8; color: l.line; opacity: 60% }}
        arc {{ at: tcx, y0 + 122; radius: 86; span: t_frac * 360deg; rotate: t_frac * 180deg; width: 8; color: l.acc }}
        text t_timer {{ at: tcx, y0 + 116; anchor: center; size: 40; weight: 300; color: l.fg; family: "{UI}" }}
        text pick(if(t_run, 1, 0), "Scroll to set · click to start", "Click to pause") {{ at: tcx, y0 + 152; anchor: center; size: 11.5; color: l.dim; family: "{UI}" }}
''' + "".join(f'''        box {{ at: tcx + ({k} - 2.5) * 80, y0 + 256; size: 72, 32; corner: 16; color: if(t_hot == {30 + k}, l.hover, l.var); opacity: if(t_hot == {30 + k}, 100%, 80%) }}
        text "{m} min" {{ at: tcx + ({k} - 2.5) * 80, y0 + 256; anchor: center; size: 12.5; weight: 500; color: l.fg; family: "{UI}" }}
''' for k, m in enumerate([1, 5, 10, 15, 25, 45])) + f'''        box {{ at: tcx, y0 + 312; size: 120, 32; corner: 16; color: if(t_hot == 21, l.hover, l.var); opacity: if(t_hot == 21, 100%, 80%); show: t_active }}
        text "Cancel" {{ at: tcx, y0 + 312; anchor: center; size: 12.5; weight: 500; color: l.fg; show: t_active; family: "{UI}" }}
    }}
    group {{
        opacity: dshow
        show: dsh > 0.5 and tv and ttab == 3
        // budíky: zoznam s prepínačom a odstránením; nový budík myšou (koliesko nad hodinou a minútou, Pridať)
        repeat k in 0..5 {{
            box {{ at: tcx, y0 + 22 + k * 50; size: cw, 44; corner: 12; color: l.var; opacity: 60%; show: k < alarms.count }}
            text alarms.$k.hm {{ at: d0.x + 16, y0 + 22 + k * 50; anchor: left center; size: 20; weight: 500; color: if(alarms.$k.on, l.fg, l.dim); show: k < alarms.count; family: "{UI}" }}
            text alarms.$k.label {{ at: d0.x + 92, y0 + 22 + k * 50; anchor: left center; width: cw - 200; lines: 1; size: 12.5; color: l.dim; show: k < alarms.count; family: "{UI}" }}
            box {{ at: d0.x + cw - 76, y0 + 22 + k * 50; size: 42, 24; corner: 12; color: if(alarms.$k.on, l.acc, l.line); show: k < alarms.count }}
            ellipse {{ at: d0.x + cw - 76 + if(alarms.$k.on, 9, -9), y0 + 22 + k * 50; radius: 9; color: if(alarms.$k.on, l.onacc, l.var); show: k < alarms.count }}
            text "{ICON("x")}" {{ at: d0.x + cw - 24, y0 + 23 + k * 50; anchor: center; size: 15; color: if(t_hot == 60 + k, l.acc, l.dim); show: k < alarms.count; family: "{ICONS}" }}
        }}
        text "No alarms. They ring even when this menu is closed." {{ at: d0.x + 2, y0 + 22; anchor: left center; size: 13; color: l.dim; show: alarms.count < 1; family: "{UI}" }}
        text "New alarm" {{ at: d0.x + 2, y0 + 300; anchor: left center; size: 12.5; weight: 600; color: l.dim; family: "{UI}" }}
        box {{ at: tcx - 34, y0 + 300; size: 60, 44; corner: 12; color: if(t_hot == 81, l.hover, l.var) }}
        box {{ at: tcx + 34, y0 + 300; size: 60, 44; corner: 12; color: if(t_hot == 82, l.hover, l.var) }}
        text t_alh {{ at: tcx - 34, y0 + 300; anchor: center; size: 22; weight: 500; color: l.fg; family: "{UI}" }}
        text ":" {{ at: tcx, y0 + 298; anchor: center; size: 22; color: l.dim; family: "{UI}" }}
        text t_alm {{ at: tcx + 34, y0 + 300; anchor: center; size: 22; weight: 500; color: l.fg; family: "{UI}" }}
        text "Scroll to set" {{ at: tcx, y0 + 334; anchor: center; size: 11; color: l.dim; family: "{UI}" }}
        box {{ at: d0.x + cw - 60, y0 + 300; size: 116, 36; corner: 18; color: l.acc; opacity: if(t_hot == 40, 85%, 100%) }}
        text "{ICON("alarm-plus")}" {{ at: d0.x + cw - 104, y0 + 300; anchor: left center; size: 15; color: l.onacc; family: "{ICONS}" }}
        text "Add" {{ at: d0.x + cw - 82, y0 + 300; anchor: left center; size: 13; weight: 600; color: l.onacc; family: "{UI}" }}
    }}
''')
a(f'''    // výber režimu: vyteká z ikony v poli (goo), riadky s ikonou a názvom, zvolený zvýraznený
    body {{
        color: l.var
        rim: 14%
        shadow: 0, 10, 24, 30% * mo
        opacity: dshow * clamp(mo * 4, 0, 1)
        ellipse {{ at: d0.x + 30, d0.y + 58; radius: 8 * clamp(mo * 3, 0, 1) }}
        box {{ at: d0.x + 110, d0.y + 64 + 104 * mo; size: 220 * clamp(mo * 1.4, 0, 1), 208 * mo; corner: 14; blend: 14 }}
    }}
    group {{
        opacity: dshow * clamp(mo * 2 - 1, 0, 1)
        show: dsh > 0.5 and mo > 0.5
        repeat k in 0..5 {{
            box {{ at: d0.x + 110, d0.y + 84 + k * 40; size: 208, 36; corner: 10; color: if(smode == k, l.acc, l.hover); opacity: if(smode == k, 22%, if(mode_hot == k, 100%, 0)) }}
            text modes.$k.glyph {{ at: d0.x + 18, d0.y + 84 + k * 40; anchor: left center; size: 17; color: if(smode == k, l.acc, l.fg); family: "{ICONS}" }}
            text modes.$k.name {{ at: d0.x + 46, d0.y + 84 + k * 40; anchor: left center; size: 13.5; weight: 500; color: l.fg; family: "{UI}" }}
        }}
    }}
    // kontextová ponuka (pravý klik, rozbaľovacie čipy)
    let cx0 = clamp(ctx.x, 12, W - 252)
    // pri čipoch dole sa ponuka otvára nahor (ctx_up), inak nadol od kurzora
    fact ctx_up = false
    let cy0 = clamp(if(ctx_up, ctx.y - 10 - ctx.count * 36, ctx.y), 12, H - 12 - ctx.count * 36)
    body {{
        color: l.var
        rim: 14%
        shadow: 0, 10, 26, 35%
        opacity: if(ctx_open, 1, 0)
        box {{ at: cx0 + 120, cy0 + ctx.count * 18; size: 240, ctx.count * 36 + 12; corner: 14 }}
    }}
    group {{
        show: ctx_open
        repeat k in 0..10 {{
            box {{ at: cx0 + 120, cy0 + 18 + k * 36; size: 228, 32; corner: 9; color: l.hover; opacity: if(ctx_hot == k, 100%, 0); show: k < ctx.count }}
            text "{ICON("check")}" {{ at: cx0 + 22, cy0 + 18 + k * 36; anchor: center; size: 14; color: l.acc; show: k < ctx.count and ctx.$k.on == 1; family: "{ICONS}" }}
            text ctx.$k.label {{ at: cx0 + 40, cy0 + 18 + k * 36; anchor: left center; width: 190; lines: 1; size: 13; color: l.fg; opacity: if(ctx.$k.off, 45%, 100%); show: k < ctx.count; family: "{UI}" }}
        }}
    }}
    // spúšťač: klikateľné miesta (navrchu)
    zone box dash_card {{ at: dt.x, dt.y; size: dw, dh; active: dash }}
    zone box mode_btn {{ at: d0.x + 30, d0.y + 24; size: 50, 36; cursor: pointer; active: dash and tview == 0 }}
    repeat k in 0..{NH} {{
        zone box hit_row.$k {{ at: d0.x + cw / 2, y0 + 22 + k * 48; size: cw, 44; cursor: pointer; active: dash and show_hits and k < hits.count and not mode_open }}
    }}
    repeat k in 0..{NF} {{
        zone box fav_hit.$k {{ at: d0.x + 44 + (k - 6 * floor(k / 6)) * 96, y0 + 67 + floor(k / 6) * 90; size: 88, 82; cursor: pointer; active: dash and show_favs and k < favs.count and not mode_open }}
    }}
    repeat k in 0..{NR} {{
        zone box rec_hit.$k {{ at: d0.x + 144 + (k - 2 * floor(k / 2)) * 296, ry0 + 34 + floor(k / 2) * 46; size: 288, 40; cursor: pointer; active: dash and show_favs and k < recent.count and not mode_open }}
    }}
    zone ellipse ai_stop {{ at: d0.x + cw - 24, cy.0 - 50 * aiw + 22; radius: 26; cursor: pointer; active: dash and show_chat and ai_wait }}
    zone box chat_zone {{ at: d0.x + cw / 2, y0 + 182; size: cw, 364; active: dash and show_chat and not mode_open }}
    repeat k in 0..{NB} {{
        zone box bub_hit.$k {{ at: bx.$k + (ch.$k.width + 28) / 2, cy.$k + (ch.$k.height + 22) / 2; size: ch.$k.width + 28, ch.$k.height + 22; active: dash and show_chat and k < chat.count and cy.$k > y0 - 10 and cy.$k < y0 + 350 and not mode_open }}
    }}
    repeat k in 0..{NC} {{
        zone box chip_hit.$k {{ at: chx.$k + cwd.$k / 2, yc; size: cwd.$k, 32; cursor: pointer; active: dash and k < chips.count }}
    }}
    // časové menu: klikateľné miesta (kód tlačidla v t_do, koliesko v t_wheel)
    zone box t_wb {{ at: tcx, y0 + 74; size: cw, 140; cursor: pointer; active: dash and tv and ttab == 0 }}
    zone ellipse t_sw_go {{ at: tcx, y0 + 168; radius: 32; cursor: pointer; active: dash and tv and ttab == 1 }}
    zone ellipse t_sw_lap {{ at: tcx - 90, y0 + 168; radius: 24; cursor: pointer; active: dash and tv and ttab == 1 and sw_run }}
    zone ellipse t_sw_reset {{ at: tcx + 90, y0 + 168; radius: 24; cursor: pointer; active: dash and tv and ttab == 1 }}
    zone ellipse t_ring {{ at: tcx, y0 + 122; radius: 92; cursor: pointer; active: dash and tv and ttab == 2 }}
    repeat k in 0..6 {{
        zone box t_pre.$k {{ at: tcx + (k - 2.5) * 80, y0 + 256; size: 72, 32; cursor: pointer; active: dash and tv and ttab == 2 }}
    }}
    zone box t_cancel {{ at: tcx, y0 + 312; size: 120, 32; cursor: pointer; active: dash and tv and ttab == 2 and t_active }}
    repeat k in 0..5 {{
        zone box t_al_on.$k {{ at: d0.x + cw - 76, y0 + 22 + k * 50; size: 46, 30; cursor: pointer; active: dash and tv and ttab == 3 and k < alarms.count }}
        zone ellipse t_al_del.$k {{ at: d0.x + cw - 24, y0 + 22 + k * 50; radius: 14; cursor: pointer; active: dash and tv and ttab == 3 and k < alarms.count }}
    }}
    zone box t_al_h {{ at: tcx - 34, y0 + 300; size: 60, 44; cursor: pointer; active: dash and tv and ttab == 3 }}
    zone box t_al_m {{ at: tcx + 34, y0 + 300; size: 60, 44; cursor: pointer; active: dash and tv and ttab == 3 }}
    zone box t_al_add {{ at: d0.x + cw - 60, y0 + 300; size: 116, 36; cursor: pointer; active: dash and tv and ttab == 3 }}
    // rozbalený výber režimu: klik mimo neho ho zavrie (pod jeho riadkami)
    zone box mode_away {{ at: W / 2, H / 2; size: W, H; active: dash and mode_open }}
    repeat k in 0..5 {{
        zone box mode_row.$k {{ at: d0.x + 110, d0.y + 84 + k * 40; size: 208, 38; cursor: pointer; active: dash and mode_open }}
    }}
    // otvorená ponuka: klik mimo nej ju zavrie (pod jej riadkami)
    zone box ctx_away {{ at: W / 2, H / 2; size: W, H; active: ctx_open }}
    repeat k in 0..10 {{
        zone box ctx_row.$k {{ at: cx0 + 120, cy0 + 18 + k * 36; size: 228, 34; cursor: pointer; active: ctx_open and k < ctx.count }}
    }}
    // <<< spúšťač
''')
block = "".join(L)

s = open(PLM).read()
A, B = "    // >>> spúšťač (spustac.py)\n", "    // <<< spúšťač\n"
if A in s:
    i = s.index(A); j = s.index(B, i) + len(B)
else:  # prvý raz: od premenných vzhľadu po kvapky widgetov
    i = s.index("    // vzhľad spúšťača (1. 10.")
    j = s.index("\n    // >>> kvapky widgetov (widgety.py)", i) + 1
s = s[:i] + block + s[j:]

# deklarácie (raz): ikony režimov a čipov sú znaky písma Tabler, téma, nedávne aplikácie
def once(old, new):
    global s
    if old in s:
        s = s.replace(old, new, 1)
once("    model modes max 5 { name: text; icon: image 20, 20 }\n",
     "    model modes max 5 { name: text; glyph: text }\n")
once("    model hits max 10 { name: text; sub: text; icon: image 24, 24; warn: bool }\n",
     f"    model hits max {NH} {{ name: text; sub: text; icon: image 28, 28; warn: bool }}\n")
once("    model favs max 18 { name: text; icon: image 40, 40 }\n",
     f"    model favs max {NF} {{ name: text; icon: image 36, 36 }}\n"
     f"    text fav_title = \"\"                      // názov zvolenej záložky nad dlaždicami\n"
     f"    // nedávno spustené aplikácie (pod obľúbenými, 2 × 2)\n"
     f"    model recent max {NR} {{ name: text; icon: image 24, 24 }}\n"
     f"    fact rec_hot = -1\n"
     f"    event rec_open ->\n"
     f"    event rec_menu ->\n"
     f"    fact tema = 0                            // téma LatteOS (poradie v session/themes/make-themes.py, logika)\n")
once("    model chips max 7 { label: text; on: bool; drop: bool }\n",
     f"    model chips max {NC} {{ label: text; label_on: bool; glyph: text; hasg: bool; on: bool; drop: bool }}\n")
if "text wx_icon = " not in s: once("    text wx_sum = \"\"\n", "    text wx_sum = \"\"\n    text wx_icon = \"\"\n")
# pravidlá (raz): riadky 0..NH, dlaždice 0..NF, nedávne
once("    repeat k in 0..10 {\n        on press hit_row.$k", f"    repeat k in 0..{NH} {{\n        on press hit_row.$k")
once("    repeat k in 0..18 {\n        on press fav_hit.$k", f"    repeat k in 0..{NF} {{\n        on press fav_hit.$k")
if "on press rec_hit" not in s: once("    // rozhovor: koliesko roluje, pravý klik na bublinu = kopírovať\n",
     f"    // nedávne: ľavý klik spustí, pravý = ponuka (odobrať)\n"
     f"    repeat k in 0..{NR} {{\n"
     f"        on press rec_hit.$k {{ emit rec_open(k) }}\n"
     f"        on press right rec_hit.$k {{ ctx_up = false; ctx.x = mx; ctx.y = my; emit rec_menu(k) }}\n"
     f"        on enter rec_hit.$k {{ rec_hot = k }}\n"
     f"        on leave rec_hit.$k {{ rec_hot = -1 }}\n"
     f"    }}\n"
     "    // rozhovor: koliesko roluje, pravý klik na bublinu = kopírovať\n")
# časové menu TimeGoo (raz): deklarácie, kliky na TimeGoo, pravidlá tlačidiel
if "fact tview = 0" not in s: once("    event time_menu ->                       // pravý klik na Hodiny: časové menu\n",
     """    event time_menu ->                       // pravý klik na Hodiny: časové menu
    // časové menu TimeGoo (1. 10.): tá istá karta z ucha; logika plní a stráži minútku a budíky (v Goo nie je
    // widget hodín Noctalie, ktorý to robí v klasickom LatteOS)
    fact tview = 0                           // 0 spúšťač, 1 časové menu
    fact ttab = 0                            // 0 prehľad, 1 stopky, 2 minútka, 3 budíky
    text t_date = ""
    text t_week = ""
    text t_sw = "00:00,0"
    text t_timer = "05:00"
    text t_next = ""
    text t_alh = "07"
    text t_alm = "00"
    text wb_total = ""
    fact t_frac = 0                          // minútka: zostáva / celkom (kruh)
    fact t_run = false                       // minútka beží
    fact t_active = false                    // minútka beží alebo je pozastavená
    fact sw_run = false
    fact t_has_next = false
    fact t_hot = -1
    model wbl max 3 { name: text; dur: text; frac: number }
    model zones max 4 { city: text; hm: text; diff: text }
    model laps max 5 { label: text; time: text }
    model alarms max 5 { hm: text; label: text; on: bool }
    event t_do ->
    event t_wheel ->
""")
once("    on press start_hit { toggle dash; pmenu = false }\n    on press right start_hit { dash = false; pmenu = false; emit time_menu }\n",
     "    on press start_hit { dash = not (dash and tview == 0); tview = 0; pmenu = false }\n    on press right start_hit { dash = not (dash and tview == 1); tview = 1; ttab = 0; wx_detail = false; pmenu = false; emit time_menu }\n")
once("    on dash_toggle { toggle dash; pmenu = false }\n", "    on dash_toggle { dash = not (dash and tview == 0); tview = 0; pmenu = false }\n")
once("    on change dash while dash { focus query }\n", "    on change dash while dash and tview == 0 { focus query }\n    on change tview while dash and tview == 0 { focus query }\n")
if "on press t_sw_go" not in s:
    rules = """    // časové menu: tlačidlá (kód do logiky), koliesko nad minútkou a nad hodinou / minútou nového budíka
    on press t_wb { emit t_do(70) }
    on press t_sw_go { emit t_do(1) }
    on press t_sw_lap { emit t_do(2) }
    on press t_sw_reset { emit t_do(3) }
    on press t_ring { emit t_do(20) }
    on scroll t_ring { emit t_wheel(if(wheel > 0, 1, 0)) }
    on press t_cancel { emit t_do(21) }
    on press t_al_add { emit t_do(40) }
    on scroll t_al_h { emit t_wheel(if(wheel > 0, 3, 2)) }
    on scroll t_al_m { emit t_wheel(if(wheel > 0, 5, 4)) }
    on press t_al_h { emit t_wheel(3) }
    on press t_al_m { emit t_wheel(5) }
    on enter t_wb { t_hot = 70 }
    on leave t_wb { t_hot = -1 }
    on enter t_sw_go { t_hot = 1 }
    on leave t_sw_go { t_hot = -1 }
    on enter t_sw_lap { t_hot = 2 }
    on leave t_sw_lap { t_hot = -1 }
    on enter t_sw_reset { t_hot = 3 }
    on leave t_sw_reset { t_hot = -1 }
    on enter t_cancel { t_hot = 21 }
    on leave t_cancel { t_hot = -1 }
    on enter t_al_add { t_hot = 40 }
    on leave t_al_add { t_hot = -1 }
    on enter t_al_h { t_hot = 81 }
    on leave t_al_h { t_hot = -1 }
    on enter t_al_m { t_hot = 82 }
    on leave t_al_m { t_hot = -1 }
    repeat k in 0..6 {
        on press t_pre.$k { emit t_do(30 + k) }
        on enter t_pre.$k { t_hot = 30 + k }
        on leave t_pre.$k { t_hot = -1 }
    }
    repeat k in 0..5 {
        on press t_al_on.$k { emit t_do(50 + k) }
        on press t_al_del.$k { emit t_do(60 + k) }
        on enter t_al_del.$k { t_hot = 60 + k }
        on leave t_al_del.$k { t_hot = -1 }
    }
"""
    once("    on press wxd_hit { toggle wx_detail; mode_open = false }\n", "    on press wxd_hit { toggle wx_detail; mode_open = false }\n" + rules)
# oprávnenia časového menu (raz): čas s milisekundami, svetové hodiny, zvonenie
once('"latte-ai", "latte-terminal" }', '"latte-ai", "latte-terminal", "date", "sh", "notify-send", "paplay" }')
# preklady (raz)
once("    on change dsw > 0.72 while dsw > 0.72 and dash and not esnap { esnap = true;",
     "    on change dsw > 0.72 while dsw > 0.72 and dash and not esnap and e.d > 150 { esnap = true;")
TR = {"Alarm {t}": "Budík {t}", "Timer {t}": "Minútka {t}", "Lap {n}": "Medzičas {n}", "Week {w} · day {d} of the year": "Týždeň {w} · {d}. deň v roku",
      "{t} on screen": "{t} pred obrazovkou", "Overview": "Prehľad", "Stopwatch": "Stopky", "Timer": "Minútka", "Alarms": "Budíky",
      "Time is up ({t})": "Čas vypršal ({t})", "LatteOS alarm": "Budík LatteOS",
      "1 min": "1 min", "5 min": "5 min", "10 min": "10 min", "15 min": "15 min", "25 min": "25 min", "45 min": "45 min",
      "Digital wellbeing today": "Digitálna pohoda dnes", "Nothing yet today": "Dnes zatiaľ nič",
      "World clocks": "Svetové hodiny", "Add cities in Settings › Date, time and location.": "Mestá pridáš v Nastaveniach › Dátum, čas a poloha.",
      "Scroll to set · click to start": "Kolieskom nastav · klikom spusti", "Click to pause": "Klikom pozastav", "Cancel": "Zrušiť",
      "No alarms. They ring even when this menu is closed.": "Žiadny budík. Zvonia aj pri zatvorenom menu.",
      "New alarm": "Nový budík", "Scroll to set": "Kolieskom nastav", "Add": "Pridať",
      "Recent": "Nedávne", "Forecast · {wx_place}": "Predpoveď · {wx_place}", "Details": "Detaily", "Close": "Zavrieť",
      "Remove from recent": "Odobrať z nedávnych"}
i = s.index("    translations sk {\n") + len("    translations sk {\n")
add = "".join(f'        "{k}" = "{v}"\n' for k, v in TR.items() if f'        "{k}" =' not in s)
s = s[:i] + add + s[i:]
open(PLM, "w").write(s)

# ikony a témy pre logiku
with open(os.path.join(HERE, "ikony.luau"), "w") as f:
    f.write("-- vygeneroval spustac.py: znaky ikon Tabler (písmo Noctalie) a poradie tém LatteOS (fact tema)\n")
    f.write("return {\n    glyph = {\n")
    for n in LOGIC_ICONS:
        f.write(f'        ["{n}"] = "\\u{{{ord(ICON(n)):X}}}",\n')
    f.write("    },\n    temy = { " + ", ".join(f'"{t}"' for t in order) + " },\n}\n")
print(f"kvapka.plm: spúšťač · ikony {ICONS} · {len(order)} tém")
