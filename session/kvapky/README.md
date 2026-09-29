# Kvapky — tekutá lišta LatteOS (prototyp)

Koncept: [AUDIT-WIN11.md › Koncept „Kvapky“](../../AUDIT-WIN11.md) (súkromné repo), maketa D na plátne dizajnu.
Beží na [pleamar](https://github.com/k4ditano/pleamar) (BSD-3, Rust + wgpu, SDF, pružiny) **vedľa** Noctalie,
ako samostatná vrstva (layer-shell) nad jej lištou.

## Čo prototyp vie (29. 9. 2026)
- zámerne nesúmerná: hlava s očami je vždy na **ľavom** konci, kvapka rastie doprava s každým oknom (ikona + hrbolček)
- **stopka**: v pokoji je kvapka vpitá do spodného okraja obrazovky (zlieva sa s ním skoro do roviny); keď k nej
  príde myš, vytiahne sa, spojenie sa stenčí na stopku pod hlavou a pretrhne sa (a naopak). Okraj je „voda“ pod
  obrazovkou roztavená s telom ako v Marei; stopka je stĺpik roztavený s oboma koncami, ktorý sa zužuje do nuly
- **latte art** na povrchu: skupinový shader [latte.wgsl](latte.wgsl) nad telom kvapky — vrstvené srdce, rozeta,
  tulipán, mramor; striedajú sa každých 16 s, pena sa vlní, kurzor ju mieša
- **oči**: „goo“ (World of Goo: dve veľké biele rôznej veľkosti, zreničky sa trasú každá po svojom, žmurkanie)
  alebo **robot** (tmavá obrazovka, dve svietiace oválne oči) — prepína pravý klik na oči
- klik na telo: `latte.windows.cycle()` (plávajúce → dlaždice → páska), tvar podľa režimu
- koliesko nad očami: páska = posun, plávajúce = ďalšie okno (Alt+Tab), dlaždice = nič
- klik na ikonu: okno dostane fokus
- texty po anglicky + `translations sk` (jazyk podľa `LANG`, prepína sa za behu)

## Spustenie (latte-lab)
```
resources/fetch.sh pleamar && (cd resources/upstream/pleamar && cargo build --release)
PLEAMAR_GENERIC=1 resources/upstream/pleamar/target/release/pleamar --scene session/kvapky/kvapka.plm --no-hud
```
`PLEAMAR_GENERIC=1`: na Hyprlande pleamar pre `window` inak použije IPC Hyprlandu, ktoré hlási iba aktívne okno
(bez zoznamu); všeobecné protokoly (wlr-foreign-toplevel) dajú všetky okná. Podnet pre upstream.
Kontrola bez spustenia: `pleamar --check session/kvapky/kvapka.plm`. Stopka na skúšku bez myši:
`pleamar --say kvapka "fact probe 75"` (0 = späť na myš), oči: `pleamar --say kvapka "fact robot true"`.
`reserve: -1`: inak by Hyprland plochu posunul nad vyhradený pás lišty Noctalie a „okraj“ by visel 68 px nad
skutočným okrajom.

**Chyba pleamaru (podnet pre upstream):** skupinový shader dostane z `inside()` farbu v sRGB, no výsledok sa do sRGB
kóduje ešte raz — aj `return c;` kvapku zosvetlí (#1c0f09 → #5c4333). latte.wgsl to obchádza (`to_linear` na výstupe).

## Namerané (latte-lab, RX 640, 2560×1080 @ 144 Hz, stupeň Plný, video tapeta)
| | pleamar | Hyprland | GPU | RAM |
|---|---|---|---|---|
| bez kvapky | — | 37 % | ~42 % | — |
| kvapka 144 Hz | 12 % jadra | 38 % | ~37 % | 63 MB |
| kvapka `rate: 60` (predvolené) | 6 % jadra | 38 % | ~41 % | 63 MB |
| + latte art, stopka, nové oči | 7,6 % jadra | — | — | 80 MB |
Prvá snímka ~90 ms od štartu, priemerná snímka 7,3 ms.

## Ďalej
Štart (zrnko) a vypínač vľavo, sada kvapiek v rohu (hodiny, rýchle nastavenia, Kapsa, Súbory, Hardvér) s panelmi,
ktoré z kvapky vytečú; náhľad okna pri prejdení myšou; farba čierna káva ↔ latte; maskoti Homebrew a drak;
vlastné `app_id` pre aplikácie LatteOS (dnes všetky `org.quickshell` → rovnaká ikona).
