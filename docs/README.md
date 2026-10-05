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
- [Engine Goo — stav, záplaty, merania](goo/ENGINE-REPORT.md)
- [Inštalácia a testy na latte-lab](../setup/lab/README.md)
- [Roadmapa](../ROADMAP.md)

### 🤖 Claude Code (po resete)
- [**Cloud session — záznam**](../cloud_session_1.md) — čo sa urobilo v cloude
- [**Engine report**](goo/ENGINE-REPORT.md) — stav a merania

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
- [Cloud session — záznam](../cloud_session_1.md)
- [Engine report — stav](goo/ENGINE-REPORT.md)

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
    ├── ROZHRANIE.md              ← Jednotlivé kvapky (Nová architektúra)
    └── ENGINE-REPORT.md          ← Stav enginu, záplaty, merania

session/goo/README.md             ← API enginu pre programátorov
cloud_session_1.md (koreň)        ← Záznam cloudovej session

setup/
├── lab/README.md                 ← Inštalácia na PC
└── ...

LATTEOS-GOO.md (koreň)            ← Záväzný dokument: pravidlá, správanie, architektúra
```

---

## Licencie a povolenia

- **pleamar** a **Marea** — BSD-3-Clause, od k4ditano
- **LatteOS** — vlastný obsah autormi
- Pred vydaním sa požiada povolenie všetkých strán

---

## Ako prispievať

1. Prečítaj [ARCHITECTURE.md](ARCHITECTURE.md)
2. Zaciluj vrstvu, ktorú potrebuješ zmeniť
3. Predtým, ako meniškvapky: [Pravidlá](goo/PRAVIDLA.md)
4. Rozhodnutia zapisuj do [LATTEOS-GOO.md](../LATTEOS-GOO.md), stav enginu do [ENGINE-REPORT.md](goo/ENGINE-REPORT.md)
5. Commit a `git push -u origin gamerdistro`
