# LatteOS Goo — Začni tu

**LatteOS GOO** (jediná edícia LatteOS) je plocha s tekutými kávovými kvapkami pri okraji obrazovky (predvolene dole), nad správcom okien pleamar-wm. Je inšpirovaná Windows 11 a fyzikou tekutiny.

## Čo to je v 30 sekundách

- **Lišta:** kvapky na okraji — BarGoo s oknami, LensGoo (spúšťač), PowerGoo (vypínač a účet), QuickGoo (rýchle
  spúšťanie), ClockGoo (čas, upozornenia a kalendár), QueenGoo (App Manager a Správca zariadení), MediaGoo, CamGoo;
  vpravo dole TrayShore
- **Fyzika:** pružia sa, lepia na okraj, spájajú sa navzájom, reagujú na kurzor
- **Vstupy:** myš (všetko sa dá ovládať: klik, pravý, koliesko, ťahanie); každá kvapka má funkciu na ľavom aj
  pravom tlačidle, koliesko mení veľkosť (LATTEOS-GOO.md §4)
- **Efekty:** vietor, vlnky na hladine (aj pri minimalizácii okna), živá hladina a dýchanie kvapiek

## Čo s tým robím

### Iba chcem používať
→ [Inštalácia](../../README.md#installing)

### Chcem porozumieť pravidlám
→ [22 pravidiel plochy](PRAVIDLA.md) — všetko, čo sa smie a čo nie

### Chcem zmeniť alebo pridať kvapku
→ Najprv: [Pravidlá](PRAVIDLA.md) (§2 a §3)
→ Potom: hlavička [goo/lib/engine.luau](../../goo/lib/engine.luau) — ako sa píše kvapka

### Som programátor a resetla sa session
→ [LATTEOS-GOO.md](../../LATTEOS-GOO.md) (čo platí), [denník rozhodnutí](ROZHODNUTIA.md), plán v [ROADMAP.md](../../ROADMAP.md) („Poradie práce“)

---

## Prehľad

| Dokument | Čo v ňom je |
|----------|------------|
| [PRAVIDLA.md](PRAVIDLA.md) | 22 zásad správania kvapiek, fyzika, nečinnosť |
| [ROZHRANIE.md](ROZHRANIE.md) | Jednotlivé kvapky a ich kliky |
| [GOOENGINE-2.md](GOOENGINE-2.md) | GooEngine 2 — živá hladina, fyzika v Ruste |
| [goo/lib/engine.luau](../../goo/lib/engine.luau) | Ako programovať: API v hlavičke súboru |
| [ROZHODNUTIA.md](ROZHODNUTIA.md) | Denník rozhodnutí s dátumami a zamietnuté nápady |

---

## Rýchly start

**Prvý deň:**
1. Prečítaj [Pravidlá](PRAVIDLA.md) — stránka 1 (§1–2)
2. Pozri sa na [Rozhranie](ROZHRANIE.md) — ako vyzerajú jednotlivé kvapky

**Keď chceš zmeniť kvapku:**
1. Skontroluj, či zmena porušuje [Pravidlá](PRAVIDLA.md) §2
2. Pozri sa do hlavičky [goo/lib/engine.luau](../../goo/lib/engine.luau) — ako sa to programuje
3. Vlastnú kvapku bez programovania pridá používateľ v LensGoo › pravý klik na aplikáciu › Pripnúť ako kvapku
   (zoznam `drops.json` v `~/.local/share/pleamar/goo/`, `goo/lib/own.luau`)
4. Pred commitom `pleamar --check` a `tests/check.sh`

**Keď padne session:**
1. Prečítaj [LATTEOS-GOO.md](../../LATTEOS-GOO.md) §8 (čo je hotové a čo chýba) a ROADMAP
2. Zafixuj to, čo treba opraviť
3. Oprav platný stav (LATTEOS-GOO.md), rozhodnutie zapíš do [ROZHODNUTIA.md](ROZHODNUTIA.md)

---

## Architektúra

```
goo/
├── goo.plm                 ← Scéna plochy (fyzika, kresba, vstupy)
├── goo.luau                ← Vstupný bod (spustí engine a kvapky)
├── gen.py                  ← Generátor (rozpíše cykly: parts/shapes.plm, parts/picks.plm)
├── parts/                  ← Časti scény (body, card, drops, faces, shore…)
├── lib/
│   ├── engine.luau         ← API: register, pravidlá, karta Goo, nečinnosť
│   ├── bar.luau            ← Okná v BarGoo
│   ├── lens.luau           ← Spúšťač LensGoo
│   ├── card.luau, ctx.luau ← Karta Goo, ponuka
│   ├── shore.luau          ← TrayShore
│   └── own.luau            ← Vlastné kvapky (drops.json)
├── drops/                  ← bargoo, powergoo, lensgoo, quickgoo, queengoo, clockgoo, mediagoo, camgoo
├── lang/sk.plm             ← Preklady
└── login.plm, lockscreen.plm, safe.plm, side.plm… ← Ďalšie scény
```

Fyziku hmoty počíta `crates/goo-phys` vo vnútri `latte-goo` (pleamar s fyzikou Goo, [GOOENGINE-2.md](GOOENGINE-2.md) §4).

---

## Licencie

- **pleamar** (scéna, kresba) a **pleamar-wm** — BSD-3-Clause, od k4ditano
- **LatteOS Goo** — GNU GPL 3.0 alebo novšia, ako celý LatteOS; `goo/shaders/sea.wgsl` je CC BY-NC-SA 3.0
- ostatné cudzie súčasti: [TRETIE-STRANY.md](../../TRETIE-STRANY.md)

---

## Prvé kroky

```bash
# Klonovať repo
git clone https://github.com/arkaysk/LatteOS-v0x-Jihlavanka.git
cd LatteOS-v0x-Jihlavanka          # predvolená vetva v0.55

# Inštalácia (README › Installing)
./install                          # povie, čo by urobil; nič nemení
sudo ./install --go

# Po zmene
tests/check.sh                     # pred commitom; commit a push iba na pokyn

# Aktualizovať dokumentáciu
# platné: LATTEOS-GOO.md · rozhodnutia: docs/goo/ROZHODNUTIA.md · plán: ROADMAP.md
```

---

**Ďalej:** [Pravidlá plochy](PRAVIDLA.md)
