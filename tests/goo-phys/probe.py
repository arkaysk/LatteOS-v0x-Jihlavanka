#!/usr/bin/env python3
"""tests/goo-phys/probe.py: writes probe.plm, the smallest scene that lives on latte-goo's physics.

A `body` knows no `repeat` and a fact is born from a plain number, so the drops and the level's columns are
written out here (as goo/gen.py does for the desktop). Run it after changing it; probe.plm is kept in git.
"""
import os

DROPS, COLUMNS, H = 6, 48, 420
out = ['''// tests/goo-phys/probe.plm: written by probe.py, do not edit.
// The smallest scene that lives on latte-goo's physics (docs/goo/GOOENGINE-2.md §4): six drops along the bottom
// edge, the level between them and the cursor as a drop, all one body with one outline. Nothing here moves by
// itself: no `time`, no spring. What moves is written by goo-phys once a frame, and when its world is still
// the scene rests (PLEAMAR_TIMING=1 then names nothing that keeps it alive).
//   latte-goo --scene tests/goo-phys/probe.plm
language 0.4

scene GooProbe {
    surface { size: full, %d; anchor: bottom; level: top; reserve: -1; rate: 60 }

    let W = screen.width
    let H = %d
    fact stir = 0
    fact tier = 2
    fact gale = 0
    fact cur.x = 0
    fact cur.y = 0
    fact cur.st = 0
    fact cur.rot = 0
    fact cur.wob = 0
    fact cur.tailx = 0
    fact cur.taily = 0
    fact ev.landed = 0
''' % (H, H)]
for k in range(DROPS):
    r = 20 + 3 * k
    out.append(f"    fact g.hx.{k} = {260 + 240 * k}\n    fact g.hy.{k} = {H - r * 0.6:g}\n    fact g.hr.{k} = {r}\n")
    for n in "held jump jvx jvy x y r st rot sq tip tipa".split():
        out.append(f"    fact g.{n}.{k} = 0\n")
    for n in "on w ax ay bx by".split():
        out.append(f"    fact j.{n}.{k} = 0\n")
out += [f"    fact h.{i} = 0\n" for i in range(COLUMNS)]
out.append('''
    body {
        color: #5a3a26
        border: 1.25, #f3e3cf
        box { from: 0, H - 10; size: W, 12 }
''')
for i in range(COLUMNS):
    out.append(f"        ellipse {{ at: {i + 0.5} * W / {COLUMNS}, H - 6 - h.{i}; radius: 8; scale: W / {COLUMNS} / 8, 1; blend: 24 }}\n")
for k in range(DROPS):
    g = lambda n: f"g.{n}.{k}"
    out.append(f'''        // drop {k}: longer the way it goes, flatter where it met something (the area kept), a tip to the cursor, its thread
        ellipse {{ at: {g('x')}, {g('y')}; radius: {g('r')}; scale: (1 + {g('st')}) * (1 + {g('sq')} * 0.6), (1 - {g('sq')} * 0.6) / (1 + {g('st')}); rotate: if({g('st')} > 0.02, {g('rot')}, 0); blend: 18 }}
        ellipse {{ at: {g('x')} + cos({g('tipa')}) * ({g('r')} * 0.7 + {g('tip')}), {g('y')} + sin({g('tipa')}) * ({g('r')} * 0.7 + {g('tip')}); radius: {g('r')} * 0.3 * ({g('tip')} > 0.5); blend: 22 }}
        line {{ from: j.ax.{k}, j.ay.{k}; to: j.bx.{k}, j.by.{k}; width: j.w.{k} * j.on.{k}; blend: 14 }}
''')
out.append('''        // the cursor as a drop: its tip where the pointer is, its belly behind
        ellipse { at: cur.x, cur.y; radius: 5; blend: 8 }
        ellipse { at: cur.x + cur.tailx + 6, cur.y + cur.taily + 8; radius: 8; scale: (1 + cur.st) * (1 + cur.wob * 0.3), 1 / (1 + cur.st); rotate: cur.rot; blend: 12 }
    }

    // a press on a drop throws it up and to the right
''')
for k in range(DROPS):
    out.append(f'''    zone ellipse hit.{k} {{ at: g.x.{k}, g.y.{k}; radius: g.r.{k} + 6; cursor: pointer; label: "Drop {k}"; role: button }}
    on press hit.{k} {{ g.jvx.{k} = 500; g.jvy.{k} = -900; g.jump.{k} = g.jump.{k} + 1 }}
''')
out.append("}\n")
open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "probe.plm"), "w").write("".join(out))
