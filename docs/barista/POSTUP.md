# Barista — postup inštalácie hry z Windowsu, krok za krokom

Tento dokument má dve časti. Prvá je presný záznam toho, ako sa 14. 10. 2026 na latte-lab nainštaloval
Aliens versus Predator 2 — čo sa zisťovalo, čo sa rozhodlo a prečo. Druhá z toho robí všeobecný postup:
rad otázok a rozhodnutí, ktorými Barista prejde **sám, bez AI**, a kde sa pýta človeka.

Návrh celku je v [NAVRH.md](NAVRH.md). Kód: `bin/latte-barista`, recepty `recipes/*.json`.

## 1. Záznam: AVP2 z dvoch ISO

Každý krok má tri riadky: **čo sa zisťovalo**, **čo vyšlo**, **čo z toho plynie**. Príkazy sú tie, ktoré
sa naozaj spustili.

### 1.1 Čo je zdroj

- Zisťovalo sa: obsah oboch obrazov bez pripojenia — `7z l AVP2CD1.iso`, `7z l AVP2CD2.iso`.
- Vyšlo: CD1 má `Setup.exe`, `setup.inx`, `data1.cab`, `data1.hdr`, `data2.cab`, `ikernel.ex_`, `layout.bin`
  a voľne ležiace `AVP2.exe`, `ALIEN.REZ`, `MARINE.REZ`, `PREDATOR.REZ`, `MULTI.REZ`. CD2 má `data3.cab`,
  priečinok `DirectX` a `GameSpy`.
- Plynie: `data1.hdr` + `dataN.cab` + `ikernel.ex_` + `setup.inx` = **InstallShield 6**, kabinet rozdelený
  na tri časti cez dva disky. Treba oba disky naraz.

### 1.2 Dá sa obísť inštalátor?

- Zisťovalo sa: či kabinety prečíta `unshield` — `unshield l data1.cab` (so všetkými časťami v jednom
  priečinku).
- Vyšlo: 55 súborov v skupinách `Program Files` (hra, 32 MB), `Resources` (`AVP2.REZ`, `SOUNDS.REZ`, 695 MB),
  `English`, a skupiny `[New DCOM95 …]`, `<Engine>`, `<Support>` (samotný inštalátor a DCOM95).
- Plynie: **áno**. Inštalátor chce DCOM95 a 16-bitové jadro InstallShieldu — to je najčastejšie miesto,
  kde staré inštalátory vo Wine padnú. Jeho kabinety sa dajú prečítať priamo, takže sa nespúšťa vôbec.
  Skupiny `DCOM95`, `Engine`, `Support` sa neberú.

### 1.3 Čo ešte hra potrebuje okrem kabinetov

- Zisťovalo sa: čo leží na CD1 voľne a v kabinete nie je.
- Vyšlo: štyri súbory `.REZ` (ALIEN, MARINE, MULTI, PREDATOR) — inštalátor ich kopíruje z disku.
- Plynie: skopírovať ich vedľa hry. DirectX z CD2 **netreba** (Wine ho má), GameSpy Arcade **netreba**
  (služba už neexistuje).

### 1.4 V čom to pobeží

- Zisťovalo sa: rok a druh programu — `AVP2.exe` je 32-bitový, 2001, engine LithTech (Direct3D 7/8).
- Plynie podľa pravidiel z NAVRH.md: stará hra do 2007 → **Wine**, nie Proton; Windows **XP**.

### 1.5 Vlastný Windows pre hru

- Urobilo sa: `WINEPREFIX=~/Games/avp2/prefix wineboot -i` (58 s), `winecfg -v winxp`, zmazanie
  `dosdevices/z:` (hra nemá vidieť zvyšok počítača).
- Do `drive_c/Games/AVP2` išlo: `Program_Files/*`, `Resources/*`, `English/*` z kabinetu a štyri `.REZ`.

### 1.6 Ako sa spúšťa

- Zisťovalo sa: `AVP2.exe` je iba spúšťač s oknom volieb; hru spúšťa `lithtech.exe` so zoznamom zdrojov.
- Urobilo sa: `wine lithtech.exe -rez AVP2.REZ -rez SOUNDS.REZ -rez ALIEN.REZ -rez MARINE.REZ
  -rez PREDATOR.REZ -rez MULTI.REZ -rez AVP2DLL.REZ -rez AVP2L.REZ`.
- Vyšlo: okno „Aliens versus Predator 2“, prehrali sa logá Fox a Sierra, zvuk ide.

### 1.7 Ohrada

- Urobilo sa: to isté cez bubblewrap — systém len na čítanie, z domova iba `~/Games/avp2`, bez siete.
- Vyšlo: beží rovnako.

### 1.8 Čo sa neoverilo a čo nefunguje

- Neoverené: menu, samotná hra, ukladanie, sieťová hra (treba človeka pri obrazovke).
- Nefunguje: obraz je 640 × 480 v rohu obrazovky, nie roztiahnutý.
- Kontrola CD: neprejavila sa pri úvode; či sa ozve pri štarte hry, nevieme.

### 1.9 Výsledok ako recept

Všetko vyššie je zapísané v `recipes/avp2.json`: podľa čoho sa hra spozná (`match`), čo musí byť na
ďalšom disku (`needs`), kroky (`unshield` so skupinami, `copy`), runner, verzia Windows, ako sa spúšťa.
Druhá inštalácia tej istej hry už nič nezisťuje: `latte-barista install AVP2CD1.iso` — 1 min 37 s.

## 2. Všeobecný postup: otázky a rozhodnutia

Barista ide zhora nadol. Pri každej otázke je napísané, **kto odpovedá**: stroj (pravidlo, bez AI) alebo
človek (obrazovka sprievodcu). Človek sa pýta iba tam, kde to stroj vedieť nemôže.

### Obrazovka 1 — Čo inštalujeme?

| # | otázka | odpovedá | ako |
|---|---|---|---|
| 1.1 | Čo je zdroj? | človek | dve tlačidlá: *Súbor alebo súbory* · *Priečinok* |
| 1.2 | Akého je typu? | stroj | prípona a začiatok súboru: iso · priečinok · archív · exe · msi · apk · AppImage · rpm · flatpak |
| 1.3 | Sú tu ďalšie disky? | stroj | iné obrazy v tom istom priečinku; ak recept žiada súbor, ktorý nikde nie je → 1.4 |
| 1.4 | Kde je disk 2? | človek | „Chýba druhý disk (hľadám data3.cab). Ukáž mi ho.“ |

### Obrazovka 2 — Pôjde to?

| # | otázka | odpovedá | ako |
|---|---|---|---|
| 2.1 | Poznáme tento program? | stroj | recept, ktorého `match` sedí na súbory zdroja → **A**; inak → **B** |
| 2.2 | Aký je to inštalátor? | stroj | podpisy: `data1.hdr`+`ikernel` InstallShield · `Inno Setup` v exe · `Nullsoft` NSIS · `.msi` · nič (hra leží rozbalená) |
| 2.3 | V čom pobeží? | stroj | tabuľka rok + grafika + 16/32/64-bit → DOSBox · Wine · Proton (NAVRH.md) |
| 2.4 | Čo potrebuje? | stroj | priečinky a súbory na médiu (`DirectX`, `vcredist*`, `dotnet*`), importy programu |
| 2.5 | Je chránená proti kopírovaniu? | stroj | podpisy SafeDisc, SecuROM, StarForce v súboroch |
| 2.6 | Stačí tento počítač? | stroj | miesto na disku, grafická karta, pamäť |

Verdikt, ktorý človek vidí: **pôjde** (recept, ktorý už niekto vyskúšal) · **asi pôjde** (iba pravidlá) ·
**nepôjde** (s dôvodom). Dôvody sú vždy vypísané.

**Vetva A — recept existuje.** Kroky sú dané, človek iba potvrdí.

**Vetva B — recept neexistuje.** Stroj si ho zloží z odpovedí 2.2–2.5:

| inštalátor | čo Barista spraví | záloha, keď to zlyhá |
|---|---|---|
| InstallShield (kabinety) | `unshield`, skupiny s programom a dátami; voľné súbory z disku | spustiť `Setup.exe` vo Wine |
| Inno Setup | `innoextract` | spustiť inštalátor s `/VERYSILENT` |
| NSIS | `7z x` | spustiť inštalátor s `/S` |
| MSI | `wine msiexec /i … /qn` | to isté s oknom |
| archív (zip, rar, 7z) | rozbaliť, hľadať znova od 2.2 | — |
| hra leží rozbalená | skopírovať | — |
| neznámy `Setup.exe` | spustiť vo Wine s oknom, človek ho prekliká | — |

Hlavný program stroj hľadá sám: najväčší `.exe`, ktorý nie je `unins*`, `setup*`, `*serv*`, `*up*`.
Ak ich ostane viac → otázka človeku na obrazovke 5: „Ktorým sa hra spúšťa?“ so zoznamom.

### Obrazovka 3 — Kam a ako

| # | otázka | odpovedá | predvolené |
|---|---|---|---|
| 3.1 | Kam? | človek | `~/Games/<názov>` |
| 3.2 | Veríš zdroju? | človek | vlastné médium = áno; stiahnuté odkiaľsi = nie |
| 3.3 | Sieť? | stroj, človek môže zmeniť | vypnutá; zapnúť pre hru po sieti |
| 3.4 | Štítok | človek | Hry |

Neznámy zdroj: sieť ostáva vypnutá aj počas inštalácie a nedá sa zapnúť bez výslovného potvrdenia.

### Obrazovka 4 — Inštalácia

Stroj robí kroky a hovorí ľudsky, čo práve robí („Čítam disk 2“, „Pripravujem Windows pre hru“,
„Rozbaľujem“). Technický výpis je v logu a ukáže sa iba na požiadanie.

Po inštalácii **skúšobné spustenie** — stroj, bez človeka: spustí hru na 30 s a pozrie, či (a) proces
žije, (b) otvoril okno, (c) v logu nie je `err:module` (chýbajúca knižnica) ani pád.

| čo skúška ukáže | čo Barista spraví sám |
|---|---|
| chýba `d3dx9_*.dll`, `msvcp*.dll`, `mfc*.dll`, `mscoree.dll` | `winetricks` s príslušným verbom (d3dx9, vcrun…, dotnet…) do prefixu hry, skúsi znova |
| pád pri Direct3D | prepne DXVK ↔ vstavané wined3d, skúsi znova |
| nič nepomohlo vo Wine | pred pokusom si odložil prefix; vráti ho a skúsi Proton (umu-run) |
| pýta si CD | pripojí obraz disku ako mechaniku prefixu, skúsi znova |
| nič z toho | „Nepodarilo sa“ + dôvod + kde je log; nič po sebe nenechá |

Každý pokus sa zapíše. Poradie pokusov je pevné, takže dva počítače dôjdu k tomu istému.

### Obrazovka 5 — Hotovo

| # | otázka | odpovedá |
|---|---|---|
| 5.1 | Spustiť teraz? | človek |
| 5.2 | Fungovalo to? (po prvom hraní) | človek: *Áno* · *Nie, …* |

Odpoveď „Áno“ urobí z toho, čo stroj zistil, **recept** v `~/.local/share/latteos/recipes/` — tak ako
vznikol recept AVP2. Nabudúce (a u každého, komu sa recept pošle) je to vetva A.

## 3. Čo je dnes hotové a čo nie

| | stav |
|---|---|
| vetva A (recept): analyze, install, run v ohrade, list, remove | hotové, overené na AVP2 |
| kroky receptu `unshield`, `copy` | hotové |
| obrazovky sprievodcu 1–5 | nie sú; Barista je zatiaľ príkaz |
| vetva B (bez receptu): rozpoznanie inštalátora, výber runnera | pravidlá sú vo v0.3 (`old/session/bin/latte-instalator`), do 0.4 neprenesené |
| ďalšie typy zdrojov (archív, exe, msi, apk…) | nie |
| skúšobné spustenie a reťaz pokusov | nie |
| závislosti cez winetricks | nie |
| pripojenie disku pre kontrolu CD | nie |
| recept z úspešnej inštalácie | nie (recept AVP2 je písaný ručne) |
