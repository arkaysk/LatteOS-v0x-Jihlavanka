# LatteOS — Architekúra

Princípy a vrstvy systému LatteOS.

## Základné princípy

1. **Linux first** — Hyprland, Wayland, štandardné protokoly (GSettings, XDG, portály)
2. **Myš prvá** — Všetko sa dá ovládať myšou (ľavé, pravé, koliesko); klávesy sú doplnok
3. **Preberať, nevymýšľať** — Existujúce riešenia (Noctalia, pleamar) sa integrujú, nie vytvárajú znova
4. **Jedno miesto pravdy** — Každá vlastnosť má jeden zdroj (appearance.toml, `latte-appearance`…)

## Vrstvy architektúry

### Vrstva 1: Boot a detekcia HW

```
crates/latte-boot
├── detekcia grafiky (GPU, renderer)
└── výber režimu (NORMAL / SAFE)

crates/latte-hw
├── CPU (x86-64 generácia, takty, cache)
├── RAM, swap, disky (vrátane LVM/LUKS)
└── GPU, UEFI, Secure Boot
```

**Proces:**
1. GRUB zavedie kernel s `latte-boot`
2. `latte-boot` zistí grafiku
3. Vyberie režim:
   - **NORMAL** — OpenGL ES 3 funguje → Hyprland + efekty
   - **SAFE** — grafika nefunguje → labwc bez efektov + záchrana

### Vrstva 2: Relácia (Session)

```
session/bin/latte-session
├── výber relácie (LatteOS GOO; pokusy: Marea, Noctalia čistá; Classic je zrušený)
├── profily prostredí (oddelené konfigurácie)
└── systemd user jednotky

session/bin/latte-greeter
└── prihlasovacia obrazovka s výberom
```

**Konfigurácie:**
- `session/hypr/` — Hyprland (režimy okien, animácie)
- `session/noctalia/` — Noctalia (corner bar, widgets)
- `session/wayland-sessions/` — .desktop súbory

### Vrstva 3: Shell (Rozhranie)

#### LatteOS Classic (zrušený 5. 10. 2026 — kód ostáva, kým ho GOO nenahradí)
```
Noctalia (panel Noctalie) + Hyprland
├── Lišta dole so widgetmi
├── Control center a panely
├── OSD a notifikácie
└── Aplikácie v Quickshell (GTK4)
```

#### LatteOS Goo
```
pleamar engine (scéna goo.plm + logika Luau)
├── Tekuté kvapky (128 miest)
├── Fyzika: kurzor, nadnesenie, súsedia, vietor, vlnky
├── Vstupy: myš (všetky tlačidlá, koliesko, ťahanie)
├── Kvapky: Goobar (okná), TimeGoo, PowerGoo, QueenGoo, DaNoGoo, ChatGoo, vlastné
├── Noctalia (rohová lišta s widgetmi)
└── Hyprland (okná aplikácií)
```

**Goo v detaile:**
- Scéna: `session/goo/goo.plm` (~1740 riadkov, fyzika, vstupy, kresba)
- Logika: `session/goo/lib/engine.luau` (API, register, pravidlá)
- Kvapky: `session/goo/kvapky/*.luau` (TimeGoo, PowerGoo…)
- Generátor: `session/goo/gen.py` (rozpíše telo goo, ktoré jazyk nemá v cykloch)
- CLI: `session/bin/latte-goo` (správa kvapiek)

### Vrstva 4: Aplikácie

```
session/apps/
├── App Manager (inštalácia programov, Flatpak + RPM)
├── Nastavenia (vzhľad, HW, sieť, AI…)
├── Monitor (procesy, senzory, autorun, výkon)
├── Device Manager (diskové priestory, sieť, updaty)
├── Súbory (s archívmi ako priečinkami)
└── iné (čas, zámok…)
```

**Technológia:**
- GTK4 + Quickshell (QML) — GUI
- D-Bus — komunikácia so systémom
- systemd — služby, úlohy na pozadí

## Ako všetko komunikuje

```
Hyprland (WM)
    ↓ (Wayland)
 pleamar engine ↔ Hyprland ↔ Aplikácie (Hyprland okná)
    ↓                           ↓
  Goo                    Noctalia control center
  (kvapky, vstupy)       (panely, widgets)
    ↓
 latte-kvapky, latte-goo (CLI)
    ↓
 systemd user, D-Bus, skript
```

## Súborová štruktúra

```
.
├── crates/              ← Rust: hw detekcia, boot
├── session/             ← Relácie a shell
│   ├── bin/             ← Úkony (latte-session, latte-goo…)
│   ├── hypr/            ← Hyprland config (Lua)
│   ├── goo/             ← Engine Goo (scéna + logika)
│   ├── kvapky/          ← Pôvodná plocha Kvapky (backup)
│   ├── apps/            ← Aplikácie (Quickshell)
│   ├── noctalia/        ← Noctalia integrácia
│   └── wayland-sessions/← .desktop súbory
├── setup/               ← Inštalácia
│   ├── f0-install.sh    ← VM, balíky
│   ├── f1/              ← Relácie, testy
│   └── lab/             ← Reálny PC
├── resources/           ← Upstream zdroje
│   ├── patches/         ← Naše záplaty
│   └── fetch.sh         ← Sťahovanie
├── docs/                ← Táto dokumentácia
├── old/                 ← Predchádzajúca verzia (len čítanie)
└── docs_zaloha/         ← Staré verzie dokumentov
```

## Režimy a varianty

### Štart
```
LATTE_VARIANT=classic       → LatteOS Classic (zrušený, na odstránenie)
LATTE_VARIANT=kvapky        → LatteOS Goo (Kvapky)
LATTE_VARIANT=goo_engine    → Goo engine test (oddelene)
```

### Bezpečosť
```
latte-boot NORMAL   → Plné efekty (GPU / llvmpipe)
latte-boot SAFE     → labwc bez efektov (keď grafika padla)
latte-boot FALLBACK → Bez HW akcelerácie (núdzový režim)
```

## Čas vývoja

| Fáza | Popis | Stav |
|------|-------|------|
| F0 | VM bez GPU, softvérové vykresľovanie | ✅ |
| F1 | Reálny PC s AMD GPU | 🔸 |
| F2 | Fedora Atomic (rpm-ostree) | ⬜ |
| H | Hardvérový report, NVIDIA, testy | 🔸 |
| C | Fork Hyprlandu (fluidná animácia) | ⬜ |
| U | Shell (panel, launcher, menu) | 🔸 |

---

## Ďalej

- [LatteOS Goo — Pravidlá](goo/PRAVIDLA.md)
- [Engine Goo — API](../session/goo/README.md)
- [Setup — Inštalácia](../setup/lab/README.md)
