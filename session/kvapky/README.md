# Kvapky — tekutá lišta LatteOS (prototyp)

Koncept: [AUDIT-WIN11.md › Koncept „Kvapky“](../../AUDIT-WIN11.md) (súkromné repo), maketa D na plátne dizajnu.
Beží na [pleamar](https://github.com/k4ditano/pleamar) (BSD-3, Rust + wgpu, SDF, pružiny) **vedľa** Noctalie,
ako samostatná vrstva (layer-shell) nad jej lištou.

## Čo prototyp vie (29. 9. 2026)
- veľká kvapka dole v strede; každé otvorené okno ju roztiahne a pridá ikonu (zoznam okien priamo zo služby `window`)
- konce sa prelievajú (šum v čase), kvapka dýcha, dole visí kvapôčka; oči sledujú kurzor
- klik na telo: `latte.windows.cycle()` (plávajúce → dlaždice → páska), tvar podľa režimu
- koliesko nad očami: páska = posun, plávajúce = ďalšie okno (Alt+Tab), dlaždice = nič
- klik na ikonu: okno dostane fokus

## Spustenie (latte-lab)
```
resources/fetch.sh pleamar && (cd resources/upstream/pleamar && cargo build --release)
PLEAMAR_GENERIC=1 resources/upstream/pleamar/target/release/pleamar --scene session/kvapky/kvapka.plm --no-hud
```
`PLEAMAR_GENERIC=1`: na Hyprlande pleamar pre `window` inak použije IPC Hyprlandu, ktoré hlási iba aktívne okno
(bez zoznamu); všeobecné protokoly (wlr-foreign-toplevel) dajú všetky okná. Podnet pre upstream.
Kontrola bez spustenia: `pleamar --check session/kvapky/kvapka.plm`.

## Namerané (latte-lab, RX 640, 2560×1080 @ 144 Hz, stupeň Plný, video tapeta)
| | pleamar | Hyprland | GPU | RAM |
|---|---|---|---|---|
| bez kvapky | — | 37 % | ~42 % | — |
| kvapka 144 Hz | 12 % jadra | 38 % | ~37 % | 63 MB |
| kvapka `rate: 60` (predvolené) | 6 % jadra | 38 % | ~41 % | 63 MB |
Prvá snímka ~90 ms od štartu, priemerná snímka 7,3 ms.

## Ďalej
Štart (zrnko) a vypínač vľavo, sada kvapiek v rohu (hodiny, rýchle nastavenia, Kapsa, Súbory, Hardvér) s panelmi,
ktoré z kvapky vytečú; náhľad okna pri prejdení myšou; farba čierna káva ↔ latte; maskoti Homebrew a drak;
vlastné `app_id` pre aplikácie LatteOS (dnes všetky `org.quickshell` → rovnaká ikona).
