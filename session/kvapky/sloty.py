#!/usr/bin/env python3
# Počet guľôčok okien v lište Kvapky (sloty). Guľôčky v goo tele (`body`) musia byť vypísané jedna po druhej —
# pleamar v tele nedovolí `repeat` ani `for` —, preto ich tento skript prepíše na N kusov, spolu s `max`
# modelov wins/lay a `repeat k in 0..N`. Použitie: python3 session/kvapky/sloty.py 48
# Cena prázdneho slotu (latte-lab, RX 640, 30. 9. 2026): ~0,15 % jadra — 20 slotov 12,5 %, 48 → 16,7 %, 96 → 19,4 %.
# Počet v logike (SLOTS v kvapka.luau) musí sedieť; nad ním posledná guľôčka otvorí prehľad všetkých okien.
import os, re, sys

path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "kvapka.plm")
N = int(sys.argv[1])
s = open(path).read()
old = int(re.search(r"model wins max (\d+) ", s).group(1))
s = re.sub(r"model (wins|lay) max \d+ ", lambda m: f"model {m.group(1)} max {N} ", s)
s = s.replace(f"repeat k in 0..{old} {{", f"repeat k in 0..{N} {{")
lines = s.split("\n")

def P(k):
    return (f"lx + ux.{k} + 2 * noise({0.7*k:.1f}, time * 0.35) + if(bdrag == {k}, bdx, 0), "
            f"mid + uy.{k} + 2.5 * noise({5+1.3*k:.1f}, time * 0.3) + if(bdrag == {k}, bdy, 0)")

def regen(pat, make):
    idx = [i for i, l in enumerate(lines) if re.search(pat, l)]
    assert len(idx) == old and idx == list(range(idx[0], idx[0] + old)), (pat, len(idx), old)
    ind = lines[idx[0]][:len(lines[idx[0]]) - len(lines[idx[0]].lstrip())]
    lines[idx[0]:idx[0] + old] = [ind + make(k) for k in range(N)]

regen(r"^\s*ellipse \{ at: lx \+ ux\.\d+ \+ 2 \* noise",
      lambda k: f"ellipse {{ at: {P(k)}; radius: ur.{k} * b.{k} * (1 + 0.035 * noise({2.1*k:.1f}, time * 0.5) + 0.12 * act.{k})"
                f" {'+' if k % 2 == 0 else '-'} wob * 0.04; blend: 13 }}")
regen(r"^\s*line \{ from: lx \+ ux\.\d+ \+ 2 \* noise",
      lambda k: f"line {{ from: {P(k)}; to: lx + kx.{k}, if(uy.{k} > -3, edge + 14, mid + ky.{k}); width: ur.{k} * b.{k} * 0.3"
                f" * if(bdrag == {k}, clamp(1 - (abs(bdx) + abs(bdy)) / 520, 0.22, 1), 1) * (1 - o.pull) * ap; blend: 9 }}")
open(path, "w").write("\n".join(lines))
print(f"kvapka.plm: {old} → {N} slotov")
