#!/usr/bin/env python3
"""gen.py — engine Goo: rozpíše to, čo jazyk pleamar 0.2 nedovolí v cykle, a zoznam modulov kvapiek.

  1. telo goo.plm (medzi // >>> telo (gen.py) a // <<< telo): pre každé miesto k kvapka a jej krk
     (`repeat` vnútri `body` jazyk zatiaľ nemá — keď ho pleamar dostane, tento krok odpadne)
  2. kvapky/zoznam.luau: mená všetkých modulov v kvapky/*.luau (Luau nevie čítať priečinok; `require` potrebuje meno)

Spúšťa sa po pridaní kvapky programátora (nový súbor v kvapky/) alebo po zmene počtu miest (N, aj v goo.plm: max 16).
"""
import glob, os, re

HERE = os.path.dirname(os.path.abspath(__file__))
N = 16
def body():
    out = []
    for k in range(N):
        out.append(f"        ellipse {{ at: x.{k}, y.{k}; radius: rr.{k}; scale: 1 + fxw.{k}, 1 - fxw.{k}; blend: 12 + 14 * near.{k} }}\n")
        out.append(f"        line {{ from: goo.{k}.hx * W, floor - goo.{k}.hy; to: x.{k}, y.{k}; width: rr.{k} * 0.7 * neck.{k}; "
                   f"blend: 22 * neck.{k}; show: neck.{k} > 0.02 }}\n")
    return "".join(out)


def put(path, a, b, block):
    s = open(path).read()
    i, j = s.index(a) + len(a), s.index(b)
    s = s[:i] + block + s[j:]
    open(path, "w").write(s)


put(os.path.join(HERE, "goo.plm"), "        // >>> telo (gen.py)\n", "        // <<< telo", body() + "        ")

mods = sorted(os.path.basename(f)[:-5] for f in glob.glob(os.path.join(HERE, "kvapky", "*.luau"))
              if not f.endswith("zoznam.luau"))
with open(os.path.join(HERE, "kvapky", "zoznam.luau"), "w") as f:
    f.write("-- vygeneroval gen.py: moduly kvapiek programátorov (kvapky/*.luau), v tomto poradí sa zaregistrujú\n")
    f.write("return {\n" + "".join(f'    "{m}",\n' for m in mods) + "}\n")
print(f"telo: {N} miest · moduly: {', '.join(mods) or '—'}")
