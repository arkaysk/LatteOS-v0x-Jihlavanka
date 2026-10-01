#!/usr/bin/env python3
"""gen.py — engine Goo: rozpíše to, čo jazyk pleamar 0.2 nedovolí v cykle, a zoznam modulov kvapiek.

  1. telo goo.plm (medzi // >>> telo (gen.py) a // <<< telo): pre každé miesto k kvapka a jej krk
     (`repeat` vnútri `body` jazyk zatiaľ nemá — keď ho pleamar dostane, tento krok odpadne)
  2. kvapky/zoznam.luau: mená všetkých modulov v kvapky/*.luau (Luau nevie čítať priečinok; `require` potrebuje meno)

Spúšťa sa po pridaní kvapky programátora (nový súbor v kvapky/) alebo po zmene počtu miest (N; v goo.plm prepíše `max N` aj `repeat k in 0..N`).
"""
import glob, os, re

HERE = os.path.dirname(os.path.abspath(__file__))
N = 64      # počet miest (v scéne max N a repeat 0..N nastaví tento skript)


def pick(fmt):
    """jedna hodnota z miesta `nk` (ťahaná kvapka): pick(nk, …0, …1, …) — jazyk nemá index na menách"""
    return "pick(nk, " + ", ".join(fmt.format(k=k) for k in range(N)) + ")"


def body():
    out = []
    for k in range(N):
        # stopka k lište (sedí na nej, pri nadnesení sa natiahne a stenčí), potom kvapka; susedné sa zlievajú
        # o niečo viac, keď sú nadnesené (ako hrozno pri kurzore). Prázdne miesto má nulovú veľkosť:
        # so záplatou pleamar-prazdne-tvary nestojí nič, bez nej leží pod obrazovkou.
        out.append(f"        line {{ from: x.{k}, floor + 6; to: x.{k}, y.{k}; width: rr.{k} * 2 * stalk.{k}; blend: 16 }}\n")
        out.append(f"        ellipse {{ at: x.{k}, y.{k}; radius: rr.{k}; scale: 1 + fxw.{k}, 1 - fxw.{k}; "
                   f"blend: 12 + 10 * near.{k} + 8 * lifted.{k} }}\n")
    # krk lepkavej kvapky: ťahá sa naraz iba jedna, preto jeden tvar pre všetky (miesto nk)
    out.append("        line { from: " + pick("goo.{k}.hx * W") + ", " + pick("floor - goo.{k}.hy") + "; to: "
               + pick("x.{k}") + ", " + pick("y.{k}") + "; width: if(nk >= 0, " + pick("rr.{k} * 0.7 * neck.{k}")
               + ", 0); blend: 22 }\n")
    return "".join(out)


def put(path, a, b, block):
    s = open(path).read()
    i, j = s.index(a) + len(a), s.index(b)
    s = s[:i] + block + s[j:]
    open(path, "w").write(s)


p = os.path.join(HERE, "goo.plm")
put(p, "        // >>> telo (gen.py)\n", "        // <<< telo", body() + "        ")
s = open(p).read()
s = re.sub(r"model goo max \d+", f"model goo max {N}", s)
s = re.sub(r"repeat k in 0\.\.\d+", f"repeat k in 0..{N}", s)
open(p, "w").write(s)

mods = sorted(os.path.basename(f)[:-5] for f in glob.glob(os.path.join(HERE, "kvapky", "*.luau"))
              if not f.endswith("zoznam.luau"))
with open(os.path.join(HERE, "kvapky", "zoznam.luau"), "w") as f:
    f.write("-- vygeneroval gen.py: moduly kvapiek programátorov (kvapky/*.luau), v tomto poradí sa zaregistrujú\n")
    f.write("return {\n" + "".join(f'    "{m}",\n' for m in mods) + "}\n")
print(f"telo: {N} miest · moduly: {', '.join(mods) or '—'}")
