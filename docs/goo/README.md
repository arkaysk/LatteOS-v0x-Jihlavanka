# LatteOS Goo — Začni tu

**LatteOS GOO** (jediná edícia LatteOS; Classic je od 5. 10. 2026 zrušený) je plocha s tekutými kávovými kvapkami na spodnom okraji obrazovky. Je inšpirovaná Windows 11 a fyzikanou tekutiny.

## Čo to je v 30 sekundách

- **Lišta:** skupiny kvapiek na okraji (Goobar s oknami, hodiny, vypínač, upozornenia)
- **Fyzika:** pružia sa, lepia na okraj, spájajú sa navzájom, reagujú na kurzor
- **Vstupy:** myš (všetko sa dá ovládať: klik, pravý, koliesko, ťahanie)
- **Efekty:** vietor, vlnky pri minimalizácii, rozjasnenie pri nečinnosti

## Čo s tým robím

### Iba chcem používať
→ [Setup/inštalácia](../../setup/lab/README.md)

### Chcem porozumieť pravidlám
→ [22 pravidiel plochy](PRAVIDLA.md) — všetko, čo sa smie a čo nie

### Chcem zmeniť alebo pridať kvapku
→ Najprv: [Pravidlá](PRAVIDLA.md) (§2 a §3)
→ Potom: [Engine API](../../session/goo/README.md)

### Som programátor a resetla sa session
→ [Cloud session — záznam](../../cloud_session_1.md)
→ [Engine report s meraniami](ENGINE-REPORT.md)

---

## Prehľad

| Dokument | Čo v ňom je |
|----------|------------|
| [PRAVIDLA.md](PRAVIDLA.md) | 22 zásad správania kvapiek, fyzika, nečinnosť |
| [ROZHRANIE.md](ROZHRANIE.md) | Jednotlivé kvapky (Goobar, TimeGoo, PowerGoo…) |
| [session/goo/README.md](../../session/goo/README.md) | Ako programovať: API, háčiky, príklady |
| [ENGINE-REPORT.md](ENGINE-REPORT.md) | Technický report: záplaty, merania, otvorené úlohy |
| [cloud_session_1.md](../../cloud_session_1.md) | História zmien, rozhodnutí a testov z cloudu |

---

## Rýchly start

**Prvý deň:**
1. Prečítaj [Pravidlá](PRAVIDLA.md) — stránka 1 (§1–2)
2. Pozri sa na [Rozhranie](ROZHRANIE.md) — ako vyzerajú jednotlivé kvapky

**Keď chceš zmeniť kvapku:**
1. Skontroluj, či zmena porušuje [Pravidlá](PRAVIDLA.md) §2
2. Pozri sa na [API enginu](../../session/goo/README.md) — ako sa to programuje
3. Zmeniť kvapku `moja-kvapka.json`:
   ```bash
   latte-goo novy "Moja kvapka"  # vytvorí súbor
   # [uprav súbor]
   latte-goo skontroluj          # skontroluj
   ```

**Keď padne session:**
1. Prečítaj [ENGINE-REPORT.md](ENGINE-REPORT.md) — čo je hotové a čo chýba
2. Zafixuj to, čo treba opraviť
3. Zapíš stav do [ENGINE-REPORT.md](ENGINE-REPORT.md) + commit

---

## Architektúra

```
session/goo/
├── goo.plm                 ← Scéna (fyzika, kresba, vstupy)
├── goo.luau                ← Vstupný bod (init)
├── gen.py                  ← Generátor (rozpíše cykly)
│
├── lib/
│   ├── engine.luau         ← API: register, pravidlá, nečinnosť
│   ├── goobar.luau         ← Okná a ich správa
│   ├── pouzivatel.luau     ← JSON kvapky
│   └── ...
│
├── kvapky/
│   ├── goobar.luau         ← Goobar (hlava + okná)
│   ├── timegoo.luau        ← Hodiny, spúšťač
│   ├── powergoo.luau       ← Vypínač, nastavenia
│   ├── queengoo.luau       ← Kráľovná (App Manager, Device Manager)
│   ├── danogoo.luau        ← Dátum, upozornenia
│   └── príklady (počítadlo…)
│
├── priklady/
│   ├── kalkulacka.json     ← Príklad: JSON kvapka
│   └── system.json         ← Príklad: monitoring
│
└── README.md               ← Technické detaily
```

---

## Licencie

- **pleamar** (scéna, kresba) — BSD-3-Clause, od k4ditano (Marea)
- **LatteOS Goo** — vlastný obsah
- **Hyprland** — LGPL

Pred vydaním sa požiada povolenie všetkých strán.

---

## Prvé kroky

```bash
# Klonovať repo
git clone https://github.com/arkaysk/jihlavanka001
cd jihlavanka001
git checkout gamerdistro

# Inštalácia
sudo setup/f0-install.sh        # VM: balíky
setup/f1/install-session.sh     # relácie

# Po zmene
git add .
git commit -m "goo: zmena"
git push -u origin gamerdistro

# Aktualizovať dokumentáciu
# stav enginu: docs/goo/ENGINE-REPORT.md, rozhodnutia: LATTEOS-GOO.md
```

---

**Ďalej:** [Pravidlá plochy](PRAVIDLA.md)
