# Barista — návrh (8. 10. 2026)

Barista je sprievodca LatteOS. Má viac režimov: **inštalácia LatteOS** (prvý mód, existuje ako prvý štart) a **inštalácia aplikácie**
(popísaná nižšie). Tento dokument je návrh; implementácia sa robí po fázach (pozri „Fázy“).

## Vstupy a spúšťanie

- App Manager → „Bude to fungovať?“ a pravý klik v Súboroch na súbor/priečinok spustia Barista v režime **inštalácia aplikácie**
  s cestou zdroja.
- Zdroj sa nikdy nekopíruje ani nemení: ISO sa pripojí len na čítanie, priečinok sa číta na mieste.

## Režim „inštalácia aplikácie“ — kroky

**1. Identifikácia zdroja** (typ určí spôsob prístupu k súboru/priečinku)

| zdroj | prístup | ďalší krok |
|---|---|---|
| `.apk` (Android) | súbor | Waydroid |
| archív so setupom (`.zip .rar .7z`, viacdielny `.part1.rar`) | rozbaliť do dočasného priečinka | analýza obsahu |
| samorozbaľovací `.exe` | spustiť len v analýze | analýza obsahu |
| `.iso` / CD / DVD | pripojiť na čítanie (loop mount / mechanika) | analýza obsahu (viac diskov: CD1, CD2…) |
| priečinok (aj externý disk, sieť) | čítať na mieste | analýza obsahu |
| samostatný `.exe` (bez inštalátora) | čítať na mieste | portable spustenie |
| `.msi` | čítať na mieste | Wine inštalácia |
| `.AppImage` | čítať na mieste | natívne (nastaviť spustiteľný, záznam v menu) |
| `.rpm`, `.flatpakref`, `.flatpak` | čítať na mieste | dnf / Flatpak |
| `.sh` (makeself a pod.) | čítať na mieste | spustiť v sandboxe |
| `.jar`, DOS hra, URL webovej aplikácie | — | samostatné podtypy (neskôr) |

Pri každom zdroji sa vypočíta **SHA-256** a uloží sa do registra (kvôli overeniu neskôr).

**2. Analýza** (interná, bez spustenia inštalátora)
- typ inštalátora (InstallShield, Wise, Inno, NSIS, vlastný; detekcia podľa podpisov v súboroch),
- požiadavky (`DirectX/`, `vcredist`, `GameSpy/`, verzia Windows, 16-bit),
- ochrany (CD check, SafeDisc — zistiť z podpisov, nie spúšťaním),
- návrh cieľa a **verdikt**: *pôjde* / *pôjde s úpravou* / *nepôjde* — s dôvodmi, každý dôvod viditeľný.

**3. Cieľ a bezpečnostný profil**
- **Úroveň dôvery:** *známy zdroj* (vlastné médium, podpísaný balík) alebo *neznámy*. Neznámy zdroj = prísnejší profil.
- **Sieť:** pri neznámom zdroji **vypnutá** počas inštalácie; pri LAN hrách (GameSpy) zapnutie povoliť samostatne a viditeľne.
- **Miesto:** `~/Hry/<id>/` (mimo repa), kontrola voľného miesta.

**4. Inštalácia** (podľa podtypu, pozri nižšie): priebeh, log, zrušenie, obnovenie; chybové hlásenia v Baristovi, nie surový výstup.

**5. Register a záver:** zápis `manifest.json`, položky v menu, skúšobné spustenie, sprievodca odinštalovaním.

## Podtypy inštalácie

- **Portable `.exe` / Wine bez inštalátora:** `~/Hry/<id>/prefix` + spustenie v bwrap profile.
- **Wine inštalátor** (`Setup.exe` na médiu/priečinku): nový prefix, inštalátor v bwrap profile, potom nájsť výsledný `.exe`.
- **Android APK:** Waydroid (samostatný krok: Waydroid musí byť nainštalovaný a spustený), inštalácia APK do Waydroid.
- **Natívne balíky:** `.rpm` cez dnf (vyžaduje oprávnenie cez polkit), `.flatpak*` cez Flatpak, `.AppImage` cez záznam v menu.
- **Skripty `.sh`:** spustenie v bwrap profile, bez siete, po potvrdení.

## Štruktúra inštalácie (Wine podtypy)

```
~/Hry/<id>/
├── manifest.json     ← register: zdroj, SHA-256, verzia, položky v menu, profil sandboxu, cesta k logom
├── prefix/           ← Wine prefix = C:\ (Program Files, users/<user>/Documents, registre system.reg/user.reg)
├── logs/             ← log inštalácie a spustení
└── (zdroj nie je v priečinku — pripája sa na čítanie)
```

- **Odinštalovanie** = zmazanie `~/Hry/<id>` a odstránenie položiek z menu podľa `manifest.json`. Voľba „zmazať aj uloženia“ je oddelená.
- **Záloha** = `tar` priečinka (vrátane uložení a registrov).
- **Z: mapovanie** (Linux ako Z:) sa v prefixe zruší.

## Sandbox (bwrap) — jeden profil pre všetky

- Systém len na čítanie (`/usr`, `/etc`), domov a zdieľania nie sú pripojené (overené testom 8. 10.).
- Zapisovateľný je len `~/Hry/<id>` (vo vnútri ako `/hra`).
- Zdroj inštalátora len na čítanie.
- Zobrazenie (Wayland/Xwayland) a zvuk (PipeWire) — potrebné, a teda je to cena za grafiku.
- Sieť: podľa profilu (vypnutá / zapnutá).
- **Hranice:** nie je to VM. Podozrivé hry sa overujú vo VM (latteOSdev vo VirtualBoxe).

## Údaje manifestu (návrh)

```json
{
  "id": "avp2",
  "nazov": "Alien vs. Predator 2",
  "vydavatel": "Fox Interactive",
  "verzia": "1.0",
  "typ": "wine-installer",
  "zdroj": {"typ": "iso", "cesta": "/…/AVP2CD1.iso", "sha256": "…", "disky": ["AVP2CD1.iso", "AVP2CD2.iso"]},
  "prefix": "~/Hry/avp2/prefix",
  "spustitelny": "drive_c/Program Files/…/AVP2.exe",
  "menu": ["~/.local/share/applications/latteos-avp2.desktop"],
  "profil": {"doverie": "znamy", "siet": false, "dalsie_mounty": []},
  "nainstalovane": "2026-10-08T…",
  "log": "~/Hry/avp2/logs/install.log"
}
```

## Obrazovky sprievodcu (jeden súvislý tok)

1. **Čo inštalujeme?** (zdroj: názov, typ, zmena zdroja — ľubovoľný priečinok, externý disk, DVD, sieť)
2. **Analýza:** verdikt, dôvody, zoznam požiadaviek (s možnosťou prečítať si podrobnosti)
3. **Kam a ako:** cieľ (`~/Hry/<id>`), voľné miesto, úroveň dôvery, sieť (predvolene podľa dôvery)
4. **Inštalácia:** priebeh, log, zrušiť
5. **Hotovo:** spustiť, pridať do menu, zobraziť register; odinštalovanie je vždy dostupné

## Rozhodovanie: Wine alebo Proton, bez AI (rozhodnutie 8. 10.)

Zásady: Barista musí všetko zvládnuť **sám**, bez pomoci používateľa, ktorý sa v Linuxe nevyzná, a **bez AI** (AI je voliteľný pomocník
pre tých, čo majú model, nikdy nie nutnosť). Hry mimo Steamu (nekúpené tam) riešime kombináciou všetkého dostupného.

**Zdroje receptov (poradie dôvery):**
1. **Vlastné overené recepty** — `session/recepty/*.json` (inštalácia `/usr/share/latteos/recepty`, používateľské `~/.local/share/latteos/recepty`).
   Recept hovorí: zhoda (súbory na médiu, označenie disku), runner, Windows verzia, závislosti, prepisy DLL, sieť, poznámky, overený/neoverený.
2. **Komunitné databázy — preberáme všetko užitočné:** inštalačné skripty Lutris, databáza opráv umu (`umu-database`/`protonfixes`),
   „verby“ winetricks, poznámky Wine AppDB a ProtonDB. Sťahujú sa s kontrolným súčtom do lokálnej medzipamäte a mapujú sa do nášho formátu.
3. **Pravidlá z údajov o programe** (keď recept chýba): rok z PE hlavičky, architektúra (16/32/64-bit), grafické API z importov.
4. **Učenie z výsledkov:** výsledok skúšobného spustenia sa uloží lokálne a môže vytvoriť vlastný recept.
5. **AI** len voliteľne (ak používateľ platí model): vysvetlenie chyby, návrh úpravy receptu.

**Pravidlá pre Wine/Proton (z `latte-instalator`, neoverené, upravujú sa podľa receptov):**

| situácia | runner |
|---|---|
| 16-bit alebo DOS | DOSBox |
| stará hra (do 2007) alebo ddraw, Direct3D 8, OpenGL, Glide | **Wine** (citlivejší na staré programy) |
| Direct3D 9 po 2007 | Proton (DXVK) |
| Direct3D 10/11, Vulkan, alebo 64-bit po 2012 | **Proton** (DXVK) |
| Direct3D 12 | **Proton** (vkd3d) |
| nič neurčené | Wine |

Windows verzia podľa roka: do 1999 win98, do 2008 winxp, do 2014 win7, potom win10.

**Reťaz pokusov bez človeka:** plán A (recept alebo pravidlá) → skúšobné spustenie → ak zlyhá, plán B (iný runner, iné prepisy DLL)
→ návrat prefixu (snímka pred pokusom) → … Používateľ nedostane technickú chybu, iba stav „skúšam inú cestu“ a na konci výsledok
alebo „nepodarilo sa“ s dôvodom a uloženým logom.

## Základ v systéme od začiatku (rozhodnutie 8. 10.)

Všetko, čo Barista potrebuje na cudzie programy, je súčasť čistej inštalácie LatteOS (nie doinštalovanie na požiadanie):
- balíky z Fedory v `setup/f0-install.sh` (pole `HRY`): `wine`, `winetricks`, `cabextract`, `innoextract`, `bubblewrap`, `7zip`, `icoutils`, `dosbox-staging`, `waydroid`, `glibc-langpack-en`, `samba`;
- `setup/f1/hry.sh`: **umu-launcher** (oficiálny RPM, kontrola SHA-256) a **GE-Proton** (kontrola sha512) v `/opt/latteos/proton` (kontajner Steam Linux Runtime
  nevidí `/usr/share`, ale `/opt` áno); umu pri prvom použití stiahne runtime (~660 MB);
- **Android:** `waydroid init` s obrazom VANILLA (OTA `ota.waydro.id`); aplikácie len pre ARM potrebujú prekladač ARM→x86 (zatiaľ nie je);
- `latte-instalator` a recepty (`/usr/share/latteos/recepty/*.json`) cez `setup/f1/install-session.sh`.
Overené na latte-lab 8. 10.: `umu-run cmd /c ver` s GE-Proton11-7 vráti „Microsoft Windows 10.0.19045“ (bez displeja). Steam nie je potrebný.

## Fázy implementácie

- **F1 (hotové 8. 10.):** `session/bin/latte-instalator analyze <cesta> [--json]` → typ, SHA-256, druh inštalátora, požiadavky, ochrany, ďalšie disky, verdikt a dôvody (bez spustenia inštalátora). Overené na AVP2 CD1/CD2 (InstallShield, 32-bit, DirectX a GameSpy na CD2) a na samorozbaľovacích exe.
- **F1b (hotové 8. 10.):** `latte-instalator analyze` dopĺňa **plán** (runner Wine/Proton/DOSBox, Windows verzia, závislosti, dôvody) z receptu alebo pravidiel; prvý recept `session/recepty/avp2.json`.
- **F2:** portable `.exe` v bwrap profile + manifest + položka v menu.
- **F3:** Wine inštalátor (Setup.exe) v novom prefixe, sprievodca 1–5, AVP2 ako prvý prípad.
- **F4:** odinštalovanie a záloha, zmazanie podľa manifestu.
- **F5:** APK (Waydroid), natívne balíky (rpm, flatpak, AppImage).

## Otvorené otázky

- ~~Má Barista sťahovať chýbajúce knižnice?~~ **Rozhodnuté (8. 10.):** áno. Barista sám zabezpečí všetko, čo program potrebuje (DirectX, vcredist, .NET…), z média alebo stiahnutím s overením kontrolného súčtu.
- Ktoré prehrávače a inštalátory sa majú rozpoznávať ako „známe zdroje“ (dôvera)?
- Preklady sprievodcu (sk, cz, en) — všetky texty cez `i18n.tr`.
- Prístupnosť sprievodcu: zatiaľ odložená (podľa poradia v ROADMAP), ale nech je to v zozname.

## Doplnenia po prvej prezentácii (8. 10.)

- **Krok 1:** dve tlačidlá — *Súbor alebo súbory* (archív aj delený, jeden či dva obrazy CD/DVD, .apk, .xapk, .exe…) a *Priečinok* (nadradený priečinok s aplikáciou/hrou).
- **Krok 2 (analýza):** aj **zhodnotenie hardvéru**. Barista sa spýta, či má na internete vyhľadať nároky/skóre a porovnať ich s týmto PC (CPU, RAM, GPU, VRAM, ovládač).
- **Krok 3:** miesto inštalácie a **štítok** (Hry, Práca, Hudba, vlastný) sú voliteľné; každá aplikácia má vlastný priečinok, aby sa nemiešali.
- **Krok 4:** **konzola** je prístupná a aktivovateľná pre pokročilých (zobrazí log inštalácie).
- **Vzhľad:** sprievodca preberá farby z vybraného vzhľadu systému.
