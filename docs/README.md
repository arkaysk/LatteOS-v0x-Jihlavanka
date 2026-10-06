# LatteOS — Dokumentácia

## Rýchla orientácia

**Čo hľadáš?**

### 👤 Používateľ
- [Ako nainštalovať?](../setup/lab/README.md) — inštalácia na VM a skutočný PC
- [Čo je LatteOS GOO?](../README.md) — jediná edícia (Classic je zrušený, 5. 10. 2026)

### 🎨 Projektant / Designer
- [Architektúra](ARCHITECTURE.md) — celková mapa systému
- **LatteOS GOO** — tekuté kvapky
  - [Čo je Goo?](goo/README.md)
  - [22 pravidiel](goo/PRAVIDLA.md)
  - [Jednotlivé kvapky](goo/ROZHRANIE.md)

### 💻 Programátor
- [Engine Goo — API](../session/goo/README.md) — ako pridať alebo upraviť kvapku
- [Denník rozhodnutí](goo/ROZHODNUTIA.md) — kedy a prečo sa čo rozhodlo, čo bolo zamietnuté
- [Inštalácia a testy na latte-lab](../setup/lab/README.md)
- [Roadmapa](../ROADMAP.md)

### 🤖 Claude Code (po resete)
- [**LATTEOS-GOO.md**](../LATTEOS-GOO.md) — čo platí (prečítať ako prvé), [ROADMAP.md](../ROADMAP.md) F3·G — čo ostáva
- [**Archív**](../docs_zaloha/README.md) — staré reporty a merania (napr. odovzdávka enginu k 5. 10., záznam z cloudu)

---

## Edícia

LatteOS má **jedinú edíciu: LatteOS GOO** (doterajšie „gamerdistro“). **LatteOS Classic bol 5. 10. 2026 zrušený**;
jeho kód zatiaľ v `session/` ostáva, kým ho GOO nenahradí aj ako predvolená a núdzová relácia.

| Časť | Čo | Kde |
|------|-----|-----|
| **Engine Goo** | jedny pravidlá pre všetky kvapky (pleamar), vo vývoji | `session/goo/` |
| **Plocha Kvapky** | pôvodná scéna, kým ju engine nenahradí | `session/kvapky/` |
| Hyprland, relácie, štart | kompozitor, `latte-session`, greeter, SAFE | `session/` |

---

## Poradie čítania

### Prvý deň
1. [Architektúra](ARCHITECTURE.md) — čo ako funguje
2. [Pravidlá](goo/PRAVIDLA.md) — 22 zásad kvapiek
3. [Setup](../setup/lab/README.md) — ako to rozbežať

### Pred prácou na kvapkách
- [LatteOS Goo — Pravidlá](goo/PRAVIDLA.md) (§2 a §3)
- [Engine API](../session/goo/README.md) — ako sa dá programovať

### Keď je session resetnutá
- [LATTEOS-GOO.md](../LATTEOS-GOO.md), [ROZHRANIE.md](goo/ROZHRANIE.md) (stav kvapiek), [ROADMAP.md](../ROADMAP.md) F3·G
- história: [docs_zaloha/](../docs_zaloha/README.md)

---

## Štruktúra dokumentácie

```
docs/
├── README.md                     ← Tu si
├── ARCHITECTURE.md               ← Celková mapa
│
└── goo/                          ← LatteOS GOO
    ├── README.md                 ← Vstup pre Goo
    ├── PRAVIDLA.md               ← 22 pravidiel kvapiek
    ├── ROZHRANIE.md              ← Jednotlivé kvapky, ich kliky a stav v engine
    └── ROZHODNUTIA.md            ← Denník rozhodnutí s dátumami, zamietnuté nápady

session/goo/README.md             ← API enginu, pasce jazyka, testovanie
docs_zaloha/ (koreň)              ← Archív: staré dokumenty, reporty a merania s dátumom (obsah sa nemení)

setup/
├── lab/README.md                 ← Inštalácia na PC
└── ...

LATTEOS-GOO.md (koreň)            ← Záväzný dokument: čo platí — pravidlá, správanie, kvapky
```

---

## Licencie a povolenia

- **LatteOS** — MIT ([LICENSE](../LICENSE))
- **pleamar** a **Marea** — BSD-3-Clause, od k4ditano; ostatné cudzie súčasti a ich licencie sú
  v [TRETIE-STRANY.md](../TRETIE-STRANY.md)

---

## Ako prispievať

1. Prečítaj [ARCHITECTURE.md](ARCHITECTURE.md)
2. Zaciluj vrstvu, ktorú potrebuješ zmeniť
3. Predtým, ako meníš kvapky: [Pravidlá](goo/PRAVIDLA.md)
4. Platné znenie oprav v [LATTEOS-GOO.md](../LATTEOS-GOO.md) (a [ROZHRANIE.md](goo/ROZHRANIE.md)), rozhodnutie s dátumom
   zapíš do [ROZHODNUTIA.md](goo/ROZHODNUTIA.md), plán do [ROADMAP.md](../ROADMAP.md); starý dokument pred zmazaním
   alebo závažnou zmenou ulož s dátumom do [docs_zaloha/](../docs_zaloha/README.md)
5. Commit a `git push origin main` (jediná vetva); verejné vydanie robí `setup/verejne/zverejnit.sh`
