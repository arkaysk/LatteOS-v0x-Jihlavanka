# Kvapky — tekutá lišta LatteOS (prototyp)

Koncept: [AUDIT-WIN11.md › Koncept „Kvapky“](../../AUDIT-WIN11.md) (súkromné repo), maketa D na plátne dizajnu.
Beží na [pleamar](https://github.com/k4ditano/pleamar) (BSD-3, Rust + wgpu, SDF, pružiny) **vedľa** Noctalie,
ako samostatná vrstva (layer-shell) nad jej lištou.

## Čo prototyp vie (29. 9. 2026)
- zámerne nesúmerná: hlava s očami je vždy na **ľavom** konci, kvapka rastie doprava s každým oknom (ikona + hrbolček)
- v pokoji vpitá do spodného okraja obrazovky (zlieva sa s ním skoro do roviny)
- **priblíženie**: od štvrtiny výšky obrazovky od nej sa začne vysúvať; kým k nej myš dôjde, je napoly vonku na hrubej
  stopke pod hlavou. Myš sa číta kdekoľvek (`cursor.x/y` z Hyprlandu), žiadna neviditeľná zóna nekradne kliky oknám
- **odtrhnutie len klikom alebo ťahaním**: klik na telo ju odtrhne (stopka sa stenčí a pretrhne), ďalší klik vráti;
  ťahanie nahor ťahá stopku (nad 0,8 sa pretrhne), nadol ju vráti
- stopka: okraj je „voda“ pod obrazovkou roztavená s telom ako v Marei, pod hlavou stĺpik roztavený s oboma koncami
- **objem** bez textúry: svetlo zhora, lem, tieň (keď je vonku) z pleamaru + mäkký odlesk pozdĺž hornej hrany a lesklá
  bodka na hlave. (Latte art shader sme skúsili a vyradili – v histórii: 3bddc26.)
- **oči**: „goo“ (World of Goo: dve veľké biele rôznej veľkosti, zreničky sa trasú, žmurkanie) alebo **robot**
  (tmavá obrazovka, svietiace oválne oči) — pravý klik na oči; sledujú myš kdekoľvek
- **klik na hlavu**: `latte.windows.cycle()` (plávajúce → dlaždice → páska), tvar podľa režimu
- koliesko nad očami: páska = posun, plávajúce = ďalšie okno (Alt+Tab), dlaždice = nič
- klik na ikonu: okno dostane fokus
- texty po anglicky + `translations sk` (jazyk podľa `LANG`, prepína sa za behu)

## Spustenie (latte-lab)
```
resources/fetch.sh pleamar && (cd resources/upstream/pleamar && git apply ../../patches/pleamar-hyprland-okna-8bit.patch && cargo build --release)
PLEAMAR_GENERIC=window resources/upstream/pleamar/target/release/pleamar --scene session/kvapky/kvapka.plm --no-hud
```
Potrebuje pleamar so záplatou [pleamar-hyprland-okna-8bit.patch](../../resources/patches/pleamar-hyprland-okna-8bit.patch):
`PLEAMAR_GENERIC=window` berie zoznam okien z wlr-foreign-toplevel (socket Hyprlandu hlási iba aktívne okno), kurzor
ostáva z Hyprlandu; a 8-bitová plocha, inak Hyprland všetky tmavé farby zosvetlí.
Kontrola bez spustenia: `pleamar --check session/kvapky/kvapka.plm`. Stopka na skúšku bez myši:
`pleamar --say kvapka "fact probe 75"` (0 = späť na myš), odtrhnutie: `"fact detached true"`, oči: `pleamar --say kvapka "fact robot true"`.
`reserve: -1`: inak by Hyprland plochu posunul nad vyhradený pás lišty Noctalie a „okraj“ by visel 68 px nad
skutočným okrajom.

## Namerané (latte-lab, RX 640, 2560×1080 @ 144 Hz, stupeň Plný, video tapeta)
| | pleamar | Hyprland | GPU | RAM |
|---|---|---|---|---|
| bez kvapky | — | 37 % | ~42 % | — |
| kvapka 144 Hz | 12 % jadra | 38 % | ~37 % | 63 MB |
| kvapka `rate: 60` (predvolené) | 6 % jadra | 38 % | ~41 % | 63 MB |
| + stopka, nové oči, latte art (vyradený) | 7,6 % jadra | — | — | 80 MB |
| bez textúry, kurzor z Hyprlandu (30×/s), 8-bit plocha | 8,8 % jadra | — | — | 65 MB |
Prvá snímka ~90 ms od štartu, priemerná snímka 7,3 ms.

## Ďalej
Štart (zrnko) a vypínač vľavo, sada kvapiek v rohu (hodiny, rýchle nastavenia, Kapsa, Súbory, Hardvér) s panelmi,
ktoré z kvapky vytečú; náhľad okna pri prejdení myšou; farba čierna káva ↔ latte; maskoti Homebrew a drak;
vlastné `app_id` pre aplikácie LatteOS (dnes všetky `org.quickshell` → rovnaká ikona).
