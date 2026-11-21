# LatteOS — Architektúra

Princípy a vrstvy systému LatteOS (vetva `v0.55`, Fedora 45).

## Základné princípy

1. **Linux first** — pleamar-wm, Wayland, štandardné protokoly (GSettings, XDG, portály)
2. **Myš prvá** — Všetko sa dá ovládať myšou (ľavé, pravé, koliesko); klávesy sú doplnok
3. **Preberať, nevymýšľať** — Existujúce riešenia (pleamar, pleamar-wm, Marea, ToolHive…) sa integrujú, nie vytvárajú znova
4. **Jedno miesto pravdy** — Každá vlastnosť má jeden zdroj (režim štartu `/run/latteos/mode.toml`, farby šálok `system/cups.json`, preklady `goo/lang/sk.plm`, čo ide do systému `FILES`…)

## Vrstvy architektúry

### Vrstva 1: Boot a detekcia HW

```
crates/latte-boot
├── detekcia grafiky (GPU, renderer)
└── výber režimu (NORMAL / SAFE), počítadlo pádov

crates/latte-hw
├── CPU (x86-64 generácia, takty, cache)
├── RAM, swap, disky (vrátane LVM/LUKS)
└── GPU, UEFI, Secure Boot
```

**Proces:**
1. GRUB zavedie kernel; služba `latte-boot.service` (pred greetd) spustí `latte-boot select`
2. `latte-boot` zistí grafiku (ovládač, EGL, GLES 3) a počítadlo pádov
3. Vyberie režim a zapíše `/run/latteos/mode.toml`:
   - **NORMAL** — OpenGL ES 3 funguje → pleamar-wm + efekty podľa stupňa (renderer `hw`, bez karty `sw-gl`)
   - **SAFE** — grafika nefunguje alebo relácia 2× za sebou spadla → labwc + pixman bez efektov + záchrana

### Vrstva 2: Prihlásenie a relácia

```
bin/latte-greeter      ← greetd ho spúšťa; scéna prihlásenia pleamaru (goo/login.plm) v labwc
bin/latte-session      ← strážca relácie: GOO (pleamar-wm), safe (labwc), game (Steam v gamescope)
system/sessions/       ← položky prihlásenia: LatteOS GOO, LatteOS SAFE, LatteOS Game
system/systemd/        ← používateľské jednotky (latte-session.target, latte-goo, latte-idle, latte-mcp…)
```

**Konfigurácie:**
- `system/pleamarwm/` — pleamar-wm: scéna správcu okien `wm/session.plm` (rozdiely LatteOS), `keys.conf`,
  `session.conf`, `autostart`, náhrada `bin/hyprctl` (Goo a aplikácie ňou ovládajú okná)
- `system/labwc/` — relácia SAFE a prihlásenie
- `system/greetd/`, `system/boot.toml` — prihlasovanie a voľby štartu

### Vrstva 3: Shell — LatteOS Goo

```
engine Goo (pleamar; scéna goo/goo.plm + logika Luau, fyzika crates/goo-phys cez latte-goo)
├── Tekuté kvapky: BarGoo (okná), LensGoo (spúšťač), PowerGoo, QuickGoo, QueenGoo, ClockGoo, MediaGoo, CamGoo; vlastné
├── Shore: TrayShore (oznamovacia oblasť), LensShore, DockShore
├── Vstupy: myš (všetky tlačidlá, koliesko, ťahanie)
└── pleamar-wm (okná aplikácií)
```

**Goo v detaile:**
- Scéna: `goo/goo.plm`, časti `goo/parts/*.plm` (telo, karta, kvapky, hladina…)
- Logika: `goo/lib/engine.luau` (API, register, pravidlá; v hlavičke ako sa píše kvapka), `lib/card.luau`, `lib/ctx.luau`…
- Kvapky: `goo/drops/*.luau`
- Ďalšie scény: prihlásenie `login.plm`, zámok `lockscreen.plm`, SAFE `safe.plm`, polkit, ďalšie monitory `side.plm`
- Generátor: `goo/gen.py` (rozpíše telo goo, ktoré jazyk nemá v cykloch)
- Preklady: `goo/lang/sk.plm` (scény Goo aj aplikácie QML)

### Vrstva 4: Aplikácie

```
apps/
├── appmanager.qml   App Manager (programy, Flatpak + RPM, aktualizácie)
├── settings.qml     Nastavenia (vzhľad, HW, sieť, AI, Kvapky…)
├── aicenter.qml     LensAI (AI, agentgram, ToolHive pre MCP)
├── files.qml        DualBrew (súbory)
├── monitor.qml      Monitor (procesy, senzory, autorun, výkon)
├── devices.qml      Správca zariadení
├── guardcorgi.qml, chapolera.qml, calendar.qml, installer.qml
└── common/          spoločné prvky (AppWindow.qml, I18n.qml, Theme.qml…)
```

**Technológia:**
- Quickshell (QML) — GUI, spúšťa `latte-app <meno>`
- Pomocníci `bin/latte-*` a nástroje v Ruste (`crates/`)
- D-Bus, systemd — komunikácia so systémom, služby na pozadí

## Ako všetko komunikuje

```
pleamar-wm (kompozitor a správca okien, scéna wm/session.plm)
    ↓ (Wayland)
 engine Goo  ↔  pleamar-wm  ↔  Aplikácie (Quickshell, Flatpak…)
    ↓                ↑
 latte-say, náhrada hyprctl (system/pleamarwm/bin/hyprctl)
    ↓
 bin/latte-* , systemd user, D-Bus
```

## Súborová štruktúra

```
.
├── bin/                 ← Pomocníci a úkony (latte-session, latte-files, latte-ai…)
├── goo/                 ← Engine Goo (scény, časti, logika, kvapky, preklady, shadery)
├── apps/                ← Aplikácie (Quickshell, QML)
├── crates/              ← Rust: latte-hw, latte-boot, latte-goo, goo-phys, latte-index, latte-chapolera…
├── system/              ← Súbory do systému: pleamarwm, labwc, greetd, systemd, sessions, cups.json…
├── templates/           ← Šablóny okien (docs/okna/SABLONY.md)
├── patches/             ← Naše záplaty pleamaru a pleamar-wm
├── install, get         ← Inštalácia (get stiahne repo a otvorí inštalátor)
├── tests/               ← Kontroly (check.sh), skúšky scén (screen.sh)
├── docs/                ← Táto dokumentácia
└── FILES                ← Čo LatteOS dáva do systému (cieľ ← zdroj)
```

## Režimy a varianty

### Relácia (`latte-session [safe|game]`)
```
bez argumentu   → LatteOS GOO: pleamar-wm s enginom Goo (iba v režime NORMAL)
safe            → LatteOS SAFE: labwc so softvérovým kreslením a lištou SAFE (goo/safe.plm)
game            → LatteOS Game: Steam Big Picture v gamescope; prepína sa s GOO v tom istom prihlásení (latte-game)
```
SAFE príde aj sám (pády, GRUB › LatteOS SAFE).

### Štart (`latte-boot select` → `/run/latteos/mode.toml`)
```
mode = normal   renderer hw (grafická karta) · sw-gl (llvmpipe)   pleamar-wm + efekty podľa stupňa
mode = safe     renderer pixman                                   labwc bez efektov + záchrana
```

---

## Ďalej

- [Východiskový návrh: rámec, režimy, štart](NAVRH-STARTU.md)
- [Optimalizácia — pravidlá a merania](OPTIMALIZACIA.md)
- [LatteOS Goo — Pravidlá](goo/PRAVIDLA.md)
- [Plán vývoja](../ROADMAP.md)
