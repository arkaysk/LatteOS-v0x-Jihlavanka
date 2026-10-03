# LatteOS — Dokumentácia

## Rýchla orientácia

**Čo hľadáš?**

### 👤 Používateľ
- [Ako nainštalovať?](../setup/lab/README.md) — inštalácia na VM a skutočný PC
- [Ktorú verziu zvoliť?](#verzie) — Classic vs. Goo

### 🎨 Projektant / Designer
- [Architektúra](ARCHITECTURE.md) — celková mapa systému
- **LatteOS Classic** — tradičný shell
  - [Dizajn a rozhranie](classic/DESIGN.md)
  - [Lišta a prvky](classic/SHELL.md)
- **LatteOS Goo** — tekuté kvapky
  - [Čo je Goo?](goo/README.md)
  - [22 pravidiel](goo/PRAVIDLA.md)
  - [Jednotlivé kvapky](goo/ROZHRANIE.md)

### 💻 Programátor
- [Engine Goo — API](goo/ENGINE.md) — ako pridať alebo upraviť kvapku
- [Hyprland — konfigurácia](../SESSIONS.md)
- [Hardware — detekcia](../HARDWARE.md)
- [Ako buildiť a testovať](../DEVELOPMENT.md)

### 🤖 Claude Code (po resete)
- [**Cloud session checkpoint**](goo/cloud_session_1.md) — čo sa urobilo (s indexom)
- [**Engine report**](goo/ENGINE-REPORT.md) — stav a merania

---

## Verzie LatteOS

| Verzia | Zastavovač | Zavádzač | Kde |
|--------|-----------|----------|-----|
| **Classic** | labwc/Hyprland | Tradičný panel | `session/` |
| **Goo** | pleamar engine | Tekuté kvapky | `session/goo/` + `session/kvapky/` |

---

## Poradie čítania

### Prvý deň
1. [Architektúra](ARCHITECTURE.md) — čo ako funguje
2. Pre Goo: [Pravidlá](goo/PRAVIDLA.md) — 22 zásad kvapiek
3. [Setup](../setup/lab/README.md) — ako to rozbežať

### Pred prácou na kvapkách
- [LatteOS Goo — Pravidlá](goo/PRAVIDLA.md) (§2 a §3)
- [Engine API](goo/ENGINE.md) — ako sa dá programovať

### Keď je session resetnutá
- [Cloud session — checkpoint](goo/cloud_session_1.md) (s indexom hore)
- [Engine report — stav](goo/ENGINE-REPORT.md)

---

## Štruktúra dokumentácie

```
docs/
├── README.md                     ← Tu si
├── ARCHITECTURE.md               ← Celková mapa
│
├── classic/                      ← LatteOS Classic
│   ├── README.md
│   ├── DESIGN.md
│   └── SHELL.md
│
└── goo/                          ← LatteOS Goo
    ├── README.md                 ← Vstup pre Goo
    ├── PRAVIDLA.md               ← 22 pravidiel kvapiek
    ├── ROZHRANIE.md              ← Jednotlivé kvapky
    ├── ENGINE.md                 ← API pre programátorov
    ├── ENGINE-REPORT.md          ← Report s meraniami
    └── cloud_session_1.md        ← Checkpoint (s indexom)

setup/
├── lab/README.md                 ← Inštalácia na PC
└── ...

LATTEOS-GOO.md (koreň)            ← Presmeruje na docs/goo/
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
4. Po každej zmene: aktualizuj [cloud_session_1.md](goo/cloud_session_1.md)
5. Commit a `git push -u origin gamerdistro`
