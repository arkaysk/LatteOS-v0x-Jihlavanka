#!/usr/bin/env python3
"""Prehľad stres testu: počty stavov podľa kategórie a priority (bughunt/STRESTEST.md)."""
import os, re, sys
from collections import Counter

path = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(os.path.abspath(__file__)), "STRESTEST.md")
STAVY = ["⬜", "✅", "⚠️", "❌", "🔁", "⏭️"]
row = re.compile(r"^\| (\d{3}) \|.*\| (P\d) \| ([^|]*?) \|")

kat, per_kat, per_p, chyby = None, {}, {}, []
for line in open(path, encoding="utf-8"):
    if line.startswith("## ") and "·" in line:
        kat = line[3:].split("*")[0].strip()
        continue
    m = row.match(line)
    if not m or not kat:
        continue
    num, p, st = m.group(1), m.group(2), m.group(3).strip() or "⬜"
    per_kat.setdefault(kat, Counter())[st] += 1
    per_p.setdefault(p, Counter())[st] += 1
    if st == "❌":
        chyby.append(f"{num} ({p})")

def riadok(meno, c):
    spolu = sum(c.values())
    hotovo = c["✅"] + c["⚠️"]
    stavy = "  ".join(f"{s} {c[s]:>3}" for s in STAVY)
    return f"{meno:<34} {stavy}   hotovo {hotovo}/{spolu}"

for k, c in per_kat.items():
    print(riadok(k, c))
print()
for p in sorted(per_p):
    print(riadok(p, per_p[p]))
p1 = per_p.get("P1", Counter())
otvorene = sum(p1.values()) - p1["✅"] - p1["⚠️"]
print("\nArabica: " + ("P1 hotové" if otvorene == 0 else f"ostáva {otvorene} testov P1"))
if chyby:
    print("Zlyhané: " + ", ".join(chyby))
