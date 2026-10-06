#!/usr/bin/env python3
"""gen.py — engine Goo: rozpíše to, čo jazyk pleamar 0.2 nedovolí v cykle, a zoznam modulov kvapiek.

  1. telo goo.plm (medzi // >>> telo (gen.py) a // <<< telo): pre každé miesto k kvapka a jej krk
     (`repeat` vnútri `body` jazyk zatiaľ nemá — keď ho pleamar dostane, tento krok odpadne); a poloha kvapky, ktorá
     nesie pás výkonu (// >>> pás výkonu): jazyk nemá index na menách, preto pick() cez všetky miesta
  2. kvapky/zoznam.luau: mená všetkých modulov v kvapky/*.luau (Luau nevie čítať priečinok; `require` potrebuje meno)

Spúšťa sa po pridaní kvapky programátora (nový súbor v kvapky/) alebo po zmene počtu miest (N; v goo.plm prepíše `max N` aj `repeat k in 0..N`).
"""
import glob, os, re

HERE = os.path.dirname(os.path.abspath(__file__))
N = 128     # počet miest (v scéne max N a repeat 0..N nastaví tento skript)


def pick(fmt):
    """jedna hodnota z miesta `nk` (ťahaná kvapka): pick(nk, …0, …1, …) — jazyk nemá index na menách"""
    return "pick(nk, " + ", ".join(fmt.format(k=k) for k in range(N)) + ")"


def slot(k):
    """tvary miesta k; prázdne miesto má nulovú veľkosť (so záplatou pleamar-prazdne-tvary nič nestojí)"""
    return [
        # mláka pri okraji pod kvapkou (širšia pozdĺž okraja), stopka od okraja ku kvapke
        f"        ellipse {{ at: bx.{k}, by.{k}; radius: rr.{k} * 0.5 * base.{k}; scale: bsx.{k}, 2.1 - bsx.{k}; blend: 14 }}\n",
        f"        line {{ from: bx.{k}, by.{k}; to: x.{k}, y.{k}; width: rr.{k} * 2 * stalk.{k}; blend: 14 }}\n",
        # voda leží POD hladinou (ako „voda pod okrajom“ v Kvapkách): nad ňu sa dvíha iba zliatím, pod vláknom ostane oko
        f"        line {{ from: wax.{k}, way.{k}; to: wbx.{k}, wby.{k}; width: wa.{k} * 2; blend: 16 }}\n",
        f"        ellipse {{ at: x.{k}, y.{k}; radius: rr.{k}; scale: 1 + fxw.{k}, 1 - fxw.{k}; blend: lk.{k} + 6 * near.{k} }}\n",
        f"        line {{ from: t0x.{k}, t0y.{k}; to: thx.{k}, thy.{k}; width: th.{k}; blend: thb.{k} }}\n",
        # kapsula: rovná časť POZDĹŽ okraja kvapky (dole a hore vodorovne, na bokoch zvisle); kd = smer, ktorým rastie
        # (0 na obe strany — bobuľa hrozna, −1 a +1 iba na jednu — pás výkonu GooPower), dĺžka kwa sa mení pružinou
        # (kvapka sa do kapsuly natiahne); guľatá kvapka ju má nulovú
        f"        line {{ from: x.{k} + {along('x', k)} * kwa.{k} * (goo.{k}.kd - 1), y.{k} + {along('y', k)} * kwa.{k} * (goo.{k}.kd - 1); "
        f"to: x.{k} + {along('x', k)} * kwa.{k} * (goo.{k}.kd + 1), y.{k} + {along('y', k)} * kwa.{k} * (goo.{k}.kd + 1); "
        f"width: rr.{k} * 2 * if(kwa.{k} > 0.5, 1, 0); blend: lk.{k} }}\n",
    ]


def along(axis, k):
    """smer pozdĺž okraja kvapky k: dole a hore os x, na bokoch os y (telo nevidí let z repeat, iba model)"""
    side = f"goo.{k}.ed == 1 or goo.{k}.ed == 3"
    return f"if({side}, 0, 1)" if axis == "x" else f"if({side}, 1, 0)"


def monitor():
    """pás výkonu GooPower: poloha a polomer kvapky, ktorá ho nesie (mon_k), pre bunky mimo repeat"""
    return ("    let mpx = " + pick_k("mon_k", "x.{k}") + "\n"
            "    let mpy = " + pick_k("mon_k", "y.{k}") + "\n"
            "    let mpr = " + pick_k("mon_k", "rr.{k}") + "\n"
            "    let mkw = " + pick_k("mon_k", "kwa.{k}") + "\n")


def pick_k(var, fmt):
    return f"pick(max({var}, 0), " + ", ".join(fmt.format(k=k) for k in range(N)) + ")"


def body():
    out = []
    for k in range(N):
        # mláka pri okraji, stopka pri nadnesení, voda k susedovi vpravo, kvapka so zliatím lk (mení sa s tokom a
        # nadnesením), goo vlákno k susedovi vpravo. Prázdne/nepoužité tvary majú nulovú veľkosť: so záplatou
        # pleamar-prazdne-tvary nestoja nič.
        out += slot(k)
    # vlnky na hladine: kameň = dva hrebene, ktoré sa rozbiehajú od miesta dopadu a slabnú; vibrácia = chvejúci sa hrb
    for i in range(4):
        for sgn in (-1, 1):
            out.append(f"        ellipse {{ at: rpx.{i} {'-' if sgn < 0 else '+'} rpg.{i} * 420, floor + rpa.{i} * 1.2; radius: rpa.{i} * 2.2 * (1 - rpg.{i}) * if(rpk.{i} > 0.5, 0, 1); "
                       f"scale: 2.2, 1; blend: 14 }}\n")
        out.append(f"        ellipse {{ at: rpx.{i}, floor + 4; radius: rpa.{i} * (1.2 + 0.6 * sin(time * 1900)) * (1 - rpg.{i}) * if(rpk.{i} > 0.5, 1, 0); "
                   f"scale: 2.6, 1; blend: 12 }}\n")
    # krk lepkavej kvapky: ťahá sa naraz iba jedna, preto jeden tvar pre všetky (miesto nk)
    # bublina okna, kým sa vytláča z kvapky (zlieva sa s ňou), a kvapka z minimalizovaného okna, ktorá padá k hladine
    out.append("        ellipse { at: b.p1x, b.p1y; radius: (8 + 8 * b.s1) * if(bub.a > 0.01 and bub.t < 0.3, 1, 0); blend: 14 }\n")
    out.append("        ellipse { at: mf.x, mf.y; radius: 16 * if(mf.k >= 1, mf.on, 0) * clamp((mf.T + 0.45 - mf.e) / 0.3, 0, 1); scale: 1 - 0.12 * clamp(mf.e, 0, 1), 1 + 0.2 * clamp(mf.e, 0, 1); blend: 16 }\n")
    # lepkavé vlákno hrozna upozornení: od okraja ku kvapke, kapsuly sa s ním zlievajú
    out.append("        line { from: vlx, vly0; to: vlx + 3 * noise(time * 0.3), vly1; width: vlw; blend: 14 }\n")
    out.append("        line { from: " + pick("hmx.{k}") + ", " + pick("hmy.{k}") + "; to: "
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
put(p, "    // >>> pás výkonu (gen.py)\n", "    // <<< pás výkonu", monitor())
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
