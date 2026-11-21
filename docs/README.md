# LatteOS — Dokumentácia

## Rýchla orientácia

**Čo hľadáš?**

### 👤 Používateľ
- [Ako nainštalovať?](../README.md#installing) — Fedora 45 Server a jeden príkaz (`get`), potom inštalátor myšou
- [Čo je LatteOS GOO?](../README.md) — jediná edícia, plocha z kávových kvapiek nad pleamar-wm

### 🎨 Projektant / Designer
- [Architektúra](ARCHITECTURE.md) — celková mapa systému
- [Šablóny okien](okna/SABLONY.md) — hlavná aplikácia a vedľajšie okno
- **LatteOS GOO** — tekuté kvapky
  - [Čo je Goo?](goo/README.md)
  - [22 pravidiel](goo/PRAVIDLA.md)
  - [Jednotlivé kvapky](goo/ROZHRANIE.md)
  - [GooEngine 2 — živá hladina](goo/GOOENGINE-2.md)

### 💻 Programátor
- [Vývoj](README-vyvoj.md) — štruktúra repozitára, vetvy, vydania
- [LatteIndex — systémový index súborov](latte-index/PLAN.md) — spoločná lokálna databáza a prírastkové indexovanie
- [Chapolera — sémantická vrstva nad súbormi](chapolera/PLAN.md) — extrakcia, tagy, taxonómia a vratné organizovanie
- [LPnP + DisplayKit — zariadenia a obrazovky](devices/LPNP-DISPLAYKIT.md) — plán na verziu 0.6 (ROADMAP 10E.14–19, 8B.09–12)
- [LensAI](lensai/POZIADAVKY.md) — požiadavky, [analýza](lensai/ANALYZA.md), [MCP](lensai/NAVRH-MCP.md)
- [Barista](barista/NAVRH.md) — programy a hry z Windowsu ([postup](barista/POSTUP.md))
- [Inštalátor](instalator/PLAN.md)
- [Engine Goo — ako sa píše kvapka](../goo/lib/engine.luau) (hlavička súboru)
- [Denník rozhodnutí](goo/ROZHODNUTIA.md) — kedy a prečo sa čo rozhodlo, čo bolo zamietnuté
- [Ručné kroky](manual-inst.md) — čo musí spustiť používateľ sám
- [Roadmapa](../ROADMAP.md)

### 🤖 Claude Code (po resete)
- [**LATTEOS-GOO.md**](../LATTEOS-GOO.md) — čo platí (prečítať ako prvé), [ROADMAP.md](../ROADMAP.md) „Poradie práce“ — čo ostáva

---

## Edícia

LatteOS má **jedinú edíciu: LatteOS GOO**. Beží na **pleamar-wm** (Hyprland odinštalovaný 2. 11. 2026), plochu
tvorí engine Goo; Noctalia sa už nepoužíva. Do verzie 0.6 sa robia iba opravy (21. 11. 2026).

| Časť | Čo | Kde |
|------|-----|-----|
| **Engine Goo** | kvapky, karty Goo, prihlásenie, zámok (pleamar) | `goo/` |
| **Správca okien** | pleamar-wm a jeho scéna s rozdielmi LatteOS | `system/pleamarwm/` |
| Relácie, štart | `latte-session`, `latte-boot`, greetd, SAFE (labwc) | `bin/`, `crates/`, `system/` |
| Aplikácie | Nastavenia, LensAI, DualBrew, Monitor… (Quickshell, QML) | `apps/` |

---

## Poradie čítania

### Prvý deň
1. [Architektúra](ARCHITECTURE.md) — čo ako funguje
2. [Pravidlá](goo/PRAVIDLA.md) — 22 zásad kvapiek
3. [Inštalácia](../README.md#installing) — ako to rozbežať

### Pred prácou na kvapkách
- [LatteOS Goo — Pravidlá](goo/PRAVIDLA.md) (§2 a §3)
- hlavička [goo/lib/engine.luau](../goo/lib/engine.luau) — ako sa programuje kvapka

### Keď je session resetnutá
- [LATTEOS-GOO.md](../LATTEOS-GOO.md), [ROZHODNUTIA.md](goo/ROZHODNUTIA.md), [ROADMAP.md](../ROADMAP.md) „Poradie práce“

---

## Štruktúra dokumentácie

```
docs/
├── README.md                     ← Tu si
├── ARCHITECTURE.md               ← Celková mapa
├── README-vyvoj.md               ← Vývoj: repozitár, vetvy, vydania
├── NAVRH-STARTU.md               ← Štart a boot (NORMAL / SAFE)
├── OPTIMALIZACIA.md              ← Výkon: pravidlá a merania
├── manual-inst.md                ← Ručné kroky používateľa
├── goo/                          ← LatteOS GOO
│   ├── README.md                 ← Vstup pre Goo
│   ├── PRAVIDLA.md               ← 22 pravidiel kvapiek
│   ├── ROZHRANIE.md              ← Jednotlivé kvapky a ich kliky
│   ├── GOOENGINE-2.md            ← Živá hladina
│   └── ROZHODNUTIA.md            ← Denník rozhodnutí s dátumami, zamietnuté nápady
├── lensai/, barista/, instalator/, devices/, latte-index/, chapolera/, lensshore/, okna/
└── audit/                        ← Audity s dátumom

LATTEOS-GOO.md (koreň)            ← Záväzný dokument: čo platí — pravidlá, správanie, kvapky
FILES, TRETIE-STRANY.md, ZMENY.md ← čo LatteOS dáva do systému, cudzí kód, zmeny po verziách
```

---

## Licencie a povolenia

- **LatteOS** — GNU GPL 3.0 alebo novšia ([LICENSE](../LICENSE), rozhodnuté 16. 11. 2026); `goo/shaders/sea.wgsl`
  je CC BY-NC-SA 3.0 (nekomerčné)
- **pleamar**, **pleamar-wm** a **Marea** — BSD-3-Clause, od k4ditano; ostatné cudzie súčasti a ich licencie sú
  v [TRETIE-STRANY.md](../TRETIE-STRANY.md)

---

## Ako prispievať

1. Prečítaj [ARCHITECTURE.md](ARCHITECTURE.md)
2. Zaciluj vrstvu, ktorú potrebuješ zmeniť
3. Predtým, ako meníš kvapky: [Pravidlá](goo/PRAVIDLA.md)
4. Platné znenie oprav v [LATTEOS-GOO.md](../LATTEOS-GOO.md), rozhodnutie s dátumom zapíš do
   [ROZHODNUTIA.md](goo/ROZHODNUTIA.md), plán do [ROADMAP.md](../ROADMAP.md)
5. Pred commitom `tests/check.sh`; vetva `v0.55` (predvolená), push iba na pokyn
