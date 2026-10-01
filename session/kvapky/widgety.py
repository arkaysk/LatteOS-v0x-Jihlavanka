#!/usr/bin/env python3
# Kvapky widgetov v kvapka.plm (30. 9. 2026): widgety Noctalie ako kvapky na okrajoch obrazovky. V goo tele (`body`)
# pleamar nedovolí `repeat` ani `for`, preto tento skript vypíše N kvapiek medzi značky
#   // >>> kvapky widgetov (widgety.py)   …   // <<< kvapky widgetov
# Použitie: python3 session/kvapky/widgety.py [N]   (predvolene 12; logika: WMAX v kvapka.luau)
import os, re, sys
import goo

path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "kvapka.plm")
N = int(sys.argv[1]) if len(sys.argv) > 1 else 12
s = open(path).read()
A, B = "    // >>> kvapky widgetov (widgety.py)\n", "    // <<< kvapky widgetov\n"

out = [A, f'''    // Každá kvapka visí z okraja (side 0 dole, 1 hore, 2 vľavo, 3 vpravo; pos 0..1 pozdĺž neho) na hladine s krkom,
    // ku kurzoru sa nakloní a nad ňou sa nafúkne (živý tvor). Chytiť a pustiť pri inom okraji = prilepí sa tam;
    // pustiť ďaleko od okrajov = steká preč (odstráni sa, späť cez spúšťač). Kliky podľa Noctalie (logika).
    model wdg max {N} {{ icon: image 22, 22; val: text; hasval: bool; mono: bool; side: number; pos: number; right: bool; wheel: bool; on: bool }}
    fact wdrag = -1
    fact wmoved = false
    fact wd.x = 0
    fact wd.y = 0
    fact wd.w = 1920
    fact wd.h = 1080
    event w_click ->
    event w_right ->
    event w_wheel ->
    event w_drop ->
    spring splashy = 420, 13
''']
for k in range(N):
    out.append(f'''    let wa.x.{k} = pick(wdg.{k}.side, W * wdg.{k}.pos, W * wdg.{k}.pos, 0, W)
    let wa.y.{k} = pick(wdg.{k}.side, H, 0, H * wdg.{k}.pos, H * wdg.{k}.pos)
    let wn.x.{k} = pick(wdg.{k}.side, 0, 0, 1, -1)
    let wn.y.{k} = pick(wdg.{k}.side, -1, 1, 0, 0)
    let wnear.{k} = 1 - smooth(0, 170, length(mx - wa.x.{k}, my - wa.y.{k}))
    let wout.{k} = 24 + 9 * wnear.{k} + 2.5 * noise(time * 0.3 + {k * 1.7:.1f})
    let wt.x.{k} = wa.x.{k} + wn.x.{k} * wout.{k} + clamp(mx - wa.x.{k}, -18, 18) * 0.28 * wnear.{k} * (1 - abs(wn.x.{k}))
    let wt.y.{k} = wa.y.{k} + wn.y.{k} * wout.{k} + clamp(my - wa.y.{k}, -18, 18) * 0.28 * wnear.{k} * (1 - abs(wn.y.{k}))
    prop wp.x.{k} = 0 ~lively
    prop wp.y.{k} = 0 ~lively
    follow wp.x.{k} = if(wdrag == {k} and wmoved, mx, wt.x.{k})
    follow wp.y.{k} = if(wdrag == {k} and wmoved, my, wt.y.{k})
    prop wb.{k} = 0 ~lively
    follow wb.{k} = if({k} < wdg.count, 1, 0)
    prop wh.{k} = 0 ~lively
    prop wwob.{k} = 0 ~splashy
    let wr.{k} = (21 + 3 * wh.{k}) * wb.{k}
    let wjit.{k} = 0.05 * sin(time * 9 + {k}) * wh.{k} + wwob.{k} * 0.01
    let wsheet.{k} = wb.{k} * if(wdrag == {k} and wmoved, 0, 1)
''')
# telá kvapiek sú v tele lišty (goo.py): zlievajú sa s ostatnými kvapkami a majú to isté svetlo
for k in range(N):
    out.append(f'''    // symbolické ikony widgetov v farbe textu; farebné ikony programov (systémová lišta) ako sú
    image wdg.{k}.icon {{ at: wp.x.{k} - 11, wp.y.{k} - 11 - if(wdg.{k}.hasval, 5, 0); size: 22, 22; tint: ink; opacity: wb.{k} * if(wdg.{k}.on, 100%, 55%); show: {k} < wdg.count and wdg.{k}.mono }}
    image wdg.{k}.icon {{ at: wp.x.{k} - 12, wp.y.{k} - 12; size: 24, 24; opacity: wb.{k} * if(wdg.{k}.on, 100%, 55%); show: {k} < wdg.count and not wdg.{k}.mono }}
    text wdg.{k}.val {{ at: wp.x.{k}, wp.y.{k} + 11; anchor: center; size: 9; weight: 700; color: ink; opacity: 85% * wb.{k}; show: {k} < wdg.count }}
    zone ellipse w_hit.{k} {{ at: wp.x.{k}, wp.y.{k}; radius: if(wdrag == {k}, 4000, 24); cursor: pointer; active: {k} < wdg.count and not dash }}
    on press w_hit.{k} {{ wdrag = {k}; wmoved = false; wd.w = W; wd.h = H }}
    on drag w_hit.{k} while wdrag == {k} and abs(drag.dx) + abs(drag.dy) > 6 {{ wmoved = true }}
    on release w_hit.{k} while wdrag == {k} and wmoved {{ wd.x = mx; wd.y = my; impulse wwob.{k} 300; emit w_drop({k}); wmoved = false; wdrag = -1 }}
    on release w_hit.{k} while wdrag == {k} and not wmoved {{ wdrag = -1; impulse wwob.{k} 120; emit w_click({k}) }}
    on press right w_hit.{k} while wdg.{k}.right {{ impulse wwob.{k} 120; ctx.x = mx; ctx.y = my; ctx_up = my > H / 2; emit w_right({k}) }}
    on scroll w_hit.{k} while wdg.{k}.wheel {{ emit w_wheel({k} * 2 + if(wheel > 0, 1, 0)) }}
    on enter w_hit.{k} {{ wh.{k}: 1 }}
    on leave w_hit.{k} {{ wh.{k}: 0 }}
''')
out.append(B)
block = "".join(out)
if A in s:
    i = s.index(A); j = s.index(B, i) + len(B)
    s = s[:i] + block + s[j:]
else:
    # prvý raz: pred ponuku Vypnúť
    anchor = "    // ── ponuka Vypnúť (vyteká z kvapky vypínača smerom od okraja) ──\n"
    s = s.replace(anchor, block + "\n" + anchor, 1)
tvary, odlesky = [], []
for k in range(N):
    v = f"wb.{k} > 0.05 and solo"
    tvary += goo.kvapka(v, f"wp.x.{k}", f"wp.y.{k}", f"wr.{k} * so", f"wa.x.{k}", f"wa.y.{k}", f"wn.x.{k}", f"wn.y.{k}", f"wsheet.{k} * so", jit=f"wjit.{k}")
    odlesky += goo.odlesk(v, f"wp.x.{k}", f"wp.y.{k}", f"wr.{k}")
s = goo.vloz(s, "kvapky widgetov", tvary, odlesky)
open(path, "w").write(s)
print(f"kvapka.plm: {N} kvapiek widgetov")
