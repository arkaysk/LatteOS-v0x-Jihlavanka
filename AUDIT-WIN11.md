# LatteOS a Noctalia — audit podľa Windows 11, prieskum a návrh rozhrania

29. 9. 2026 · latte-lab (Fedora 44, Hyprland 0.56 + Noctalia 5.2) · súkromné (neide do arkaysk/latteos)

## Východiská

- **Pre koho:** používatelia Windowsu. Východiskom pre správanie je **Windows 11**.
- **Myš je hlavný ovládač.** Všetko musí byť spraviteľné myšou; klávesnica iba zrýchľuje (skratky sa ukazujú v ponukách vedľa položiek, ako vo Windows).
- **Štandardy freedesktop platia** (MIME a „Otvoriť pomocou“, `.desktop`, portály, StatusNotifier/DBusMenu, témy ikon a zvukov, preklady podľa `LANG`).
- **Cesta 2:** LatteOS je samostatné prostredie (Hyprland + Noctalia + aplikácie LatteOS) nad obrazom ublue `base-main` + `akmods`, všetko pripnuté.
- **Preberať, nevymýšľať:** najprv hotové (Noctalia, Hyprland pluginy, Qt, freedesktop), vlastné iba spojivo a identita LatteOS.

Metóda: všetkých 70+ klávesových skratiek (`session/hypr/latte/skratky.lua`, profily Windows / GNOME-KDE / macOS)
porovnané s tým, čo spúšťajú prvky ovládané myšou (lišta, ponuky, plocha, aplikácie); potom prvky Windows 11,
ktoré v skratkách nie sú (panel úloh, oblasť oznámení, Štart). Stav overený v kóde, nie z pamäti.

Legenda: ✅ ide myšou · ⚠️ ide, ale inak ako Windows 11 / neúplne · ❌ iba klávesnicou alebo vôbec

## A. Vrstva prostredia (robíme my; Noctalia kde má hotové)

| Windows 11 | Myšou vo Win11 | LatteOS dnes | Stav | Riešenie (odkiaľ) |
|---|---|---|---|---|
| Ponuka Štart | klik na Štart: pripnuté, odporúčané, všetky, hľadanie, účet, napájanie | dlaždica aplikácií → spúšťač: pripnuté, často používané, hľadanie, oblasť oznámení | ⚠️ | doplniť napájanie a účet do spúšťača |
| Pravý klik na Štart (Win+X) | ponuka pre pokročilých | pravý klik na dlaždicu aplikácií → ponuka Win+X | ✅ | — |
| Panel úloh: bežiace aplikácie | klik = prepni, prejdenie = náhľad, pravý klik = ponuka | zobrazovač okien (latte-okna): klik, náhľad, pravý klik, stredné = nové okno | ✅ | — |
| Panel úloh: **pripnuté aplikácie** | pripnúť cez pravý klik | zámerne nie (radar: „na lište nie sú pripnuté ikony“) | ⚠️ | **rozhodnúť**: pre Windows používateľa je to základ |
| **Oblasť oznámení** (Steam, Discord…) | šípka ^ pri hodinách, pravý klik na ikonu | ikony sú vnútri spúšťača („odsunuté“) | ⚠️ | ikona ^ pri hodinách; Noctalia má hotový tray a ponuky DBusMenu |
| Rýchle nastavenia (sieť, zvuk, batéria) | klik na ikony pri hodinách | ostrov Zariadenia → latte-rychle | ✅ | — |
| Hodiny, kalendár, oznámenia | klik na dátum / zvonček | ostrov Čas: hodiny, zvonček, dátum | ✅ | — |
| **Zobraziť plochu** | úzky pásik v pravom rohu | iba ponuka Win+X a Win+D | ❌ | pásik na konci lišty (radar ho aj popisuje) |
| **Task View a virtuálne plochy** | tlačidlo na paneli: plochy, +Nová, pravý klik zavrieť, ťahanie okien | prehľad pásky iba Win+Tab; Nová plocha vo Win+X; prepínanie a zatváranie iba klávesnicou | ❌ | tlačidlo Task View na lište + pás plôch v prehľade |
| Snap Layouts | prejdenie nad □, ťahanie k okraju | ponuka rozložení nad □, prichytenie ťahaním (latte-okna) | ✅ | Win11 ju ukáže už pri prejdení, overiť |
| Titulok okna: – □ ✕, dvojklik, pravý klik | áno | hyprbars: – □ ✕, pravý klik = ponuka okna; minimalizácia z CSD aplikácií (Steam) od 29. 9. | ✅ | — |
| Presun okna na iný monitor | ťahanie | ťahanie (natívne v Hyprlande) + ponuka okna | ✅ | overiť s 2 monitormi |
| Pravý klik na plochu | Nový, Zobraziť, Zoradiť, Prispôsobiť, Obrazovka | plocha.qml má ponuku | ✅ | porovnať položky s Win11 |
| Zamknúť, odhlásiť, vypnúť | Štart › napájanie | šálka (systémová ponuka), Win+X | ✅ | — |
| Správca úloh | pravý klik na panel úloh | Win+X › Správca úloh, šálka › Monitor | ✅ | — |
| **Snímka obrazovky** | Nástroj na vystrihovanie (aplikácia v Štarte) | iba Print a Win+Shift+S | ❌ | položka v spúšťači a v rýchlych nastaveniach (Noctalia 5.2 má panel snímok) |
| **Nahrávanie obrazovky** | Nástroj na vystrihovanie › Záznam | iba Win+Alt+R | ❌ | to isté ako snímka |
| **Herný panel** (Xbox Game Bar) | Win+G, ale aj tlačidlo v Štarte | Herňa iba Super+G, **herný režim iba Super+Shift+G** | ❌ | herný blok v rýchlych nastaveniach (radar ho plánuje) |
| Emoji | Win+. (aj dotyková klávesnica) | iba Win+. | ⚠️ | položka „Emoji“ v ponuke úprav textu |
| Lupa | Nastavenia › Prístupnosť, rýchle nastavenia | Nastavenia › Prístupnosť › Lupa | ✅ | — |
| Premietanie (Win+P) | rýchle nastavenia › Premietanie | ponuka Premietanie (Win+X) | ✅ | pridať aj do rýchlych nastavení |
| Prepínanie okien (Alt+Tab) | panel úloh | zobrazovač okien, prehľad | ✅ | — |

## B. Štandardy freedesktop (iba zapojiť)

| Čo | Stav | Poznámka |
|---|---|---|
| MIME, predvolené aplikácie, „Otvoriť pomocou“ | ✅ | xdg-mime, `.desktop` |
| „Nájsť v aplikácii Softvér“ (GTK) | ❌ | `bughunt/bug001.png`: volá `gnome-software`, ktorý tu nie je → presmerovať na App Manager |
| Portály (súbory, snímky, zdieľanie obrazovky) | ✅ | hyprland + gtk |
| Vzhľad GTK/GNOME aplikácií | ✅ | šablóny Noctalie gtk3/gtk4, adw-gtk3, `color-scheme` |
| Vzhľad **Qt/KDE** aplikácií | ❌ | zapnúť šablóny Noctalie `qt` + `kde`, qt6ct |
| Oblasť oznámení (StatusNotifier, DBusMenu) | ✅ | Noctalia |
| Notifikácie, zvukové témy | ✅ | Noctalia (zvuky od 5.2) |
| Žiadosť okna o minimalizáciu | ✅ | latte-okna 0.2 (29. 9.) |
| **Preklady** podľa `LANG` | ❌ | UI má slovenčinu natvrdo; Noctalia: `noctalia.tr` (27 jazykov, **bez sk** → prispieť), QML: I18n z DMS (MIT), skripty: gettext |
| Automatické spúšťanie (XDG autostart) | overiť | — |

## C. Naše aplikácie (QML)

| Čo | Stav | Poznámka |
|---|---|---|
| Ponuka úprav v textových poliach (Vystrihnúť, Kopírovať, Prilepiť) | ❌ | 23 polí; `LTextInput` pripravený (správanie z Qt, vzhľad Latte), čaká na preklady |
| Skratky zobrazené v ponukách | ✅ | ContextMenu `hint` |
| Pravý klik v zoznamoch a paneloch | ⚠️ | Súbory, plocha, spúšťač áno; na lište chýba pri šálke a Zariadeniach |
| Náhrady hotovými aplikáciami | návrh | Súbory → Double Commander, Monitor → Mission Center, obchod → Bazaar + Setup Plan LatteOS |

## D. Noctalia 5.2 (základ, z ktorého vychádzame)

Metóda: všetkých ~120 akcií Noctalie (`noctalia msg …`, dokumentácia `docs/user/ipc`) porovnaných s tým, čo ponúka
jej vlastné rozhranie na myš: widgety lišty, dlaždice riadiaceho centra, spúšťač, nastavenia (zdroj 9287a78).

**Silné stránky — Noctalia je pre myš postavená dobre:**
- Takmer každá akcia má **widget na lište** (35 typov: panel úloh, oblasť oznámení, snímka, hlasitosť, jas, sieť, Bluetooth,
  pracovné plochy, relácia, nastavenia, počasie, médiá…) alebo **dlaždicu v riadiacom centre** (Wi-Fi, Bluetooth, nočné svetlo,
  Nerušiť, tmavý režim, kofeín, zvuk, mikrofón, profil výkonu, médiá, **nahrávanie obrazovky**, tapeta, relácia, schránka,
  rozloženie klávesnice). Pravý klik na dlaždicu otvorí príslušnú kartu.
- **Akcie lišty:** ľubovoľný widget vie na ľavý / pravý / stredný klik, tlačidlá späť a dopredu a koliesko spustiť ľubovoľnú
  akciu — **iba konfiguráciou, bez kódu**. Každú akciu, ktorá je dnes iba na klávesnici, sa dá dať na myš.
- Snímka obrazovky: widget, pravý klik = celá obrazovka / oblasť; oblasť sa vyberá ťahaním.
- Oblasť oznámení: ponuky aplikácií (DBusMenu), **Pripnúť / Odopnúť pravým klikom**.
- Spúšťač: pravý klik na aplikáciu = ďalšie možnosti, **Pripnúť do doku**, preusporiadanie ťahaním.
- **Lišta sa upravuje ťahaním** v Nastaveniach (presun, skupiny, pridanie, odobranie); widgety na ploche majú režim úprav ťahaním.
- Nastavenia majú GUI pre všetko, čo je v TOML.

| Windows 11 | Noctalia | Stav | Poznámka |
|---|---|---|---|
| Pravý klik na ikonu v paneli úloh: Pripnúť, nové okno, nedávne súbory, Zavrieť | iba **Zavrieť / Zavrieť všetko** | ⚠️ | chýba Pripnúť/Odopnúť, Nové okno, nedávne súbory (LatteOS latte-okna má nové okno stredným klikom) |
| Pripnúť na panel úloh | iba v Nastaveniach (`pinned`); do doku zo spúšťača | ⚠️ | Windows: pravý klik v Štarte aj na paneli úloh |
| Pravý klik na prázdnu lištu → Nastavenia panela úloh | neoverené | ? | overiť; inak cez akcie lišty |
| Plocha: ikony, pravý klik | nemá (iba widgety) | ❌ | LatteOS `plocha.qml` to pokrýva |
| Task View, vytvoriť a zavrieť plochu | widget plôch = prepínanie klikom; vytvoriť/zavrieť nie | ⚠️ | Hyprland plochy vznikajú samy; chýba „+“ a zavrieť |
| Alt+Tab | prepínač okien iba klávesnicou (5.2: karusel náhľadov) | ✅ | myšou cez panel úloh, rovnako ako Windows |
| Úprava widgetov na ploche | Nastavenia › Plocha › Editor | ⚠️ | Windows: pravý klik na plochu |
| Jazyk | 27 jazykov, **bez slovenčiny** | ❌ | prispieť `sk.json` |

**Dôsledok pre LatteOS:** časť ❌ z tabuľky A **nie je treba programovať** — Noctalia ich má a LatteOS ich zatiaľ nepoužíva
alebo ich nahradil vlastnými pluginmi: oblasť oznámení na lište, widget snímky, dlaždica nahrávania, panel úloh
s pripnutými aplikáciami, akcie lišty pre herný režim a Zobraziť plochu. Vlastné ostáva iba to, čo Noctalii chýba
(ponuka panela úloh s Pripnúť, Task View s „+“, plocha s ikonami) — ideálne ako príspevok do Noctalie, nie fork.

## Prieskum (od posledného radaru 21. 9.)

**Novinky**
- **Noctalia 5.2** (10. 9.): prepínač okien s karuselom náhľadov, anotácia snímok, pripomienky z kalendára (CalDAV, Google),
  zvukové témy freedesktop, spúšťač otvára aj panely (aj riadiace centrum), dialóg nastavenia monitorov, japončina
  ([linuxiac](https://linuxiac.com/noctalia-5-2-wayland-shell-released-with-new-window-switcher/)).
- GNOME 51 (16. 9.), KDE Plasma 6.8 v októbri, **Konveyor** (posuvné dlaždice pre KDE), COSMIC 1.9 (klávesnica na obrazovke),
  **Fedora 45 Beta** (Linux 7.2, GNOME 51), Steam testuje kodek Pyrowave, Valve Lepton
  ([týždeň 39](https://linuxiac.com/linuxiac-weekly-wrap-up-week-39-2026-september-21-27/)).

**Obľúbené rice** ([porovnanie](https://www.musabase.com/p/best-hyprland-dotfiles-for-linux.html))

| Projekt | Čo si vziať | Čomu sa vyhnúť |
|---|---|---|
| **ML4W** | nastavenia GUI, „klikni a otvor“, ľahké, najbližšie Windows používateľom | málo tém |
| **HyDE** | 70+ tém prepínaných naraz, sklo | na starom HW sa sekajú animácie |
| **End-4** (★16k) | Quickshell, živé náhľady, AI, „usability-first“ | ťažké, pôsobí ako Android |
| **Caelestia** (★12k) | panel s výkonom, morfujúce panely | 1,5 GB RAM v pokoji |
| **Omarchy** | inštalácia za 10 min | **ovládanie klávesnicou** — opak LatteOS |

**Nové moduly na GitHube (sklo)**

| Projekt | Čo robí | Poznámka |
|---|---|---|
| [**hyprliquid**](https://github.com/Neuron-Group/hyprliquid) | **Mica, Mica Alt, Acrylic, Acrylic Thin** (materiály Windows 11), Aero, Liquid Glass pre okná aj panely; sleduje farebný režim z portálu | BSD-3, **konfigurácia v Lua** (sedí na naše hyprland.lua); mladý (★1) → prototyp a meranie |
| [fasi96/hyprglass](https://github.com/fasi96/hyprglass) | Liquid Glass + svetlo podľa kurzora, náklon, žiara po kliknutí | presne nápady z radaru („svetlo podľa myši“, „náklon ±2°“); BSD-3, aktívny |
| [TimaDub/hyprglass](https://github.com/TimaDub/hyprglass) | lom, šošovka, difrakcia na priehľadných oknách | BSD-3 |

## Návrh rozhrania: „rozloženie Windows 11, materiál LatteOS“

1. **Lišta s oblasťami Windows 11, tvar ostrovov LatteOS** (zľava doprava, voľba „na stred“ ako Win11):
   Štart (dlaždica aplikácií) · Hľadanie (Text Bar) · **Task View** · pripnuté + bežiace aplikácie ·
   … · **^ oblasť oznámení** · rýchle nastavenia (sieť, zvuk, batéria) · čas, dátum, zvonček · **pásik Zobraziť plochu**.
   Šálka, Kapsa a maskot ostávajú ako identita LatteOS.
2. **Materiály ako Windows 11, ale teplé:** okná **Mica** (tapeta rozmazaná pod titulkom, farba Latte), ponuky a panely
   **Acrylic**, **Liquid Glass** iba v stupni Plný; Úsporný = Mica bez rozmazania (plná farba z tapety). Zdroj: hyprliquid.
3. **Task View:** prehľad pásky + pás virtuálnych plôch hore (+ Nová, pravý klik Zavrieť, ťahanie okna na plochu) —
   zatvorí všetky ❌ pri plochách.
4. **Herný blok v rýchlych nastaveniach** (ako Xbox Game Bar): Herný režim, Herňa, Snímka, Nahrávanie, FPS (MangoHud),
   profil výkonu — zatvorí ❌ pri hrách, snímkach a nahrávaní.
5. **Jednotná kontextová ponuka ako Win11:** hore rad ikon (Vystrihnúť, Kopírovať, Premenovať, Zdieľať, Odstrániť),
   pod ním položky, dole „Zobraziť viac možností“. Rovnaká v Súboroch, na ploche aj v textových poliach.
6. **Snap Layouts pri prejdení nad □** (nielen pravým klikom).
7. **Pohyb:** krátke pružné animácie 200–300 ms (radar), v hre vypnuté; svetlo podľa kurzora (hyprglass) iba Plný.

## Betatest návrhu: čo používatelia naozaj používajú (29. 9.)

Microsoft telemetriu jednotlivých funkcií (Task View, Snap, Game Bar) verejne nezverejňuje — kde nie sú tvrdé čísla,
je uvedená sila dôkazu. Zdroje:
[J] Jeuris a kol., *The Hidden Cost of Window Management* (arXiv 1810.04673; 6 ľudí, Windows 7, laboratórium) ·
[G] GNOME Shell user research 2020 (Red Hat, 7 rozhovorov) ·
[W7] Engineering Windows 7 · [S] Show Desktop vo Win11 build 22631.3155 → .3810 ·
[C] kontextová ponuka Win11 · [L] Apple Liquid Glass (iOS/macOS 26 → 27) · [H] najneobľúbenejšie funkcie Win11 2025–26.

| Prvok návrhu | Čo hovoria dáta | Ako často | Sila | Verdikt |
|---|---|---|---|---|
| Panel úloh s bežiacimi oknami | prepínanie cez panel úloh **84–99 %**, Alt+Tab 0–16 % aj u expertov [J] | desiatky krát za hodinu | stredná (malá vzorka, ale jednoznačná) | **ponechať, hlavný ovládač** |
| **Pripnuté aplikácie** na lište | používatelia Windowsu spúšťajú najčastejšie z panela úloh [J, anekdoticky] | denne, viackrát | stredná | **zmeniť rozhodnutie radaru: pripnuté áno** |
| Štart / spúšťač | spúšťa sa hlavne **hľadaním**, mriežka aplikácií takmer nepoužívaná [G]; „Odporúčané“ v Štarte patrí medzi najnenávidenejšie [H], Microsoft ho dovolil skryť | niekoľkokrát denne | stredná | **hľadanie + pripnuté + všetky aplikácie; žiadne „odporúčané“** |
| Task View a virtuálne plochy | **63 % ľudí používa jedinú plochu** (a to GNOME ich tlačí) [G] | menšina, zato intenzívne | stredná | **ponechať, ale nie ako výrazné tlačidlo**; cesta myšou cez prehľad; tlačidlo voliteľné (Win11 ho dovolí skryť) |
| Pásik Zobraziť plochu | keď ho Microsoft pri Copilote skryl, po sťažnostiach ho **vrátil ako predvolený** [S] | občas, ale ľudia si ho bránia | stredná | **ponechať** |
| Oblasť oznámení pri hodinách | konvencia; Steam, Discord, VPN žijú tam | denne pri hráčoch | slabá (bez čísel) | **ponechať pri hodinách** |
| Lišta na stred / vľavo | iba ankety; veľa návodov „ako vrátiť vľavo“ | — | slabá | **voľba pri prvom štarte (Barista)** |
| Materiál **Mica** (okná) | rozmaže tapetu raz, nie každú snímku → lacný; transparentnosť sa vypína kvôli čitateľnosti a výkonu | stále na očiach | stredná | **ponechať ako predvolený** |
| **Acrylic / Liquid Glass** | Apple: rok sťažností na čitateľnosť → prepínač Clear/Tinted a v 27 **posuvník**; obe skupiny nespokojné s jedným nastavením [L]; ~30 % relácií Win7 si menilo farbu skla [W7] | stále na očiach | silná | **Acrylic iba ponuky; Liquid Glass iba voliteľne v Plnom; posuvník „sklo ↔ čitateľnosť“ od prvého dňa** |
| Ponuka Win11 s radom ikon a „Zobraziť viac možností“ | jedna z najkritizovanejších zmien Win11, bežne sa vracia klasická [C] | pri každom pravom kliku | silná | **zmeniť: celá ponuka hneď (klasický zoznam s ikonami), žiadne „Zobraziť viac“** |
| Snap Layouts pri prejdení nad □ | bez čísel; predvolené vo Win11 | — | slabá | ponechať s oneskorením, dať vypnúť (už je v Nastaveniach) |
| Herný blok (ako Game Bar) | Microsoft čísla Game Baru nezverejňuje | pri hraní | slabá | ponechať **malý**: jedna dlaždica, nie panel plný funkcií |
| Widgety, všadeprítomné AI | medzi najnenávidenejšími funkciami Win11; Microsoft ich v 2026 obmedzuje [H] | — | silná | **nerobiť predvolene**; AI iba na požiadanie (ako radar) |
| Alt+Tab, skratky | 0–16 % prepnutí [J] | — | stredná | potvrdzuje zásadu: **myš hlavná, klávesnica zrýchľuje** |

**Závery betatestu**
1. Najviac sa používa **panel úloh** — musí byť najlepšia časť LatteOS; pripnuté aplikácie patria doň.
2. **Hľadanie** je hlavná cesta k aplikáciám; Štart bez reklám a „odporúčaní“.
3. Virtuálne plochy, herný blok a Snap pri prejdení sú pre menšinu — dostupné myšou, ale nie na očiach.
4. **Sklo áno, ale s posuvníkom a čitateľným predvoleným nastavením** (Mica), inak zopakujeme chybu Apple.
5. **Kontextová ponuka Win11 je zlý vzor** — vziať rozloženie Win11, ale ponuku celú, ako Win10.

## Používateľ P1 (Arkay, 29. 9.) — priame údaje, majú prednosť pred odhadmi z internetu

Fotka pracovného PC (Windows): panel úloh = **bežiace okná ako samostatné tlačidlá s ikonou a názvom okna, nezlúčené**
(SAP Logon, QM zmena štatusu, …), bez rýchleho spúšťania; vpravo ^ oblasť oznámení, zvuk, sieť. Na ploche ikony.

| Téma | P1 hovorí | Rozhodnutie |
|---|---|---|
| Spúšťanie aplikácií | „väčšina sú ikony/odkazy na ploche zoradené do skupín + Štart“; hľadanie iba občas, keď začne písať názov | **plocha s ikonami v skupinách + Štart sú hlavná cesta**, hľadanie doplnok (opravuje betatest bod 2) |
| Panel úloh | zrušil rýchle spúšťanie; panel úloh = zapnuté okná | **bežiace okná s názvom, nezlúčené** (Noctalia `taskbar` + `show_window_title = true` — iba konfigurácia); pripnuté aplikácie **nie predvolene**, iba voľba |
| Alt+Tab | hlavne v hrách: dostať sa na plochu / k inému oknu **bez vypnutia hry** | Alt+Tab musí spoľahlivo fungovať z hry na celej obrazovke (Hyprland aj herná relácia) — **overiť na latte-lab** |
| Schránka | Ctrl+C/Ctrl+V klasicky, aj cez kontextovú ponuku; **navyše „Prilepiť ďalšie…“ ako schránka v Androide (Gboard)** | ponuka úprav: Prilepiť (posledné) + **Prilepiť ďalšie ›** (história z Kapsy); v cudzích aplikáciách: klik na položku Kapsy **vloží** do okna, kde bol kurzor (ako Win+V), dnes ju iba skopíruje |
| Virtuálne plochy | nikdy nepoužil | tlačidlo Task View **nie**; plochy iba v prehľade a Nastaveniach, nízka priorita |

Upresnenie P1: „skupiny“ = neporiadne zhluky (hry vpravo hore, priečinky v strede, programy vľavo) — nie Fences.

### Rozhodnutie 29. 9.: plocha LatteOS nie je plocha Windowsu

**Prečo:** vo Windows vedú k aplikácii 4 cesty (plocha, Štart, rýchle spúšťanie, hľadanie) — priveľa; ikony na ploche
sa menia na neporiadok; so živou (video) tapetou pôsobia rušivo. macOS dok a jeho varianty tiež nie.
**Dáta (Windows, nie GNOME):** anketa PC Gamer (máj 2026, hráči): **84 % má plochu prázdnu alebo udržiavanú, 16 % zaplnenú**
([PC Gamer](https://www.pcgamer.com/software/operating-systems/84-percent-of-you-rightly-practice-good-desktop-icon-hygiene-but-it-turns-out-16-percent-of-pc-gamer-readers-are-just-plain-monsters/));
telemetria Windows 7: **67 % hľadaní v Štarte slúži na spustenie programu**
([Building Windows 8](https://www.windowsobserver.com/2011/10/03/building-windows-8-the-start-menu/));
Microsoft vo Windows 7 zrušil rýchle spúšťanie v prospech pripínania na panel úloh a vo Windows 8 tlačidlo Štart, lebo ho
používalo málo ľudí ([Taskbar](https://en.wikipedia.org/wiki/Taskbar)) — rozhodnutie sa neskôr vrátilo.
(Hodnotu „−11,2 % používania Štartu“ sa nepodarilo overiť, necituje sa.)

**Cesty k aplikácii v LatteOS (dve, obe myšou):**
1. **Štart v rohu** (dlaždica aplikácií → App Manager / spúšťač) — pripnuté, všetky aplikácie, hľadanie písaním.
2. **Písanie** kedykoľvek (Text Bar) — skratka, nie podmienka.
Bežiace okná: panel úloh s názvami (nie spúšťač).

**Plocha = tapeta + widgety** (Noctalia desktop widgets, režim úprav ťahaním myšou — hotové):
- Kto chce ikony na ploche, **pripne si ich cez widget**: widget „Skratky“ (skupina skutočných ikon aplikácií, voliteľný
  názov, napr. „Hry“) ako plugin Noctalie `[[desktop_widget]]`; **Pripnúť na plochu** pravým klikom v Štarte a App Manageri.
  (Vstavaný widget `button` vie iba ikonu Tabler + príkaz — na jednotlivé tlačidlá stačí, na skupinu ikon aplikácií nie.)
- Predvolene prázdna plocha (tapeta + prípadne hodiny); ďalšie widgety z galérie Noctalie (kalendár, počasie, médiá, výkon).
- `plocha.qml` (ikony súborov z ~/Plocha ako Windows) → nahradiť. **Kôš: v Súboroch** (rozhodnuté 29. 9.).
- **App Manager zatiaľ odložený** (spolu s myšlienkou oprávnení/capabilities na zariadenia) — návrh prostredia bez neho.

### Štart = spúšťač Noctalie (hotový, iba nastaviť)
Jedno tlačidlo → panel: pole na písanie hore; pred písaním **pripnuté** (`pinned`, poradie ťahaním) a **často používané**
(`sort_by_usage`, filter „Nedávno použité“); **kategórie** (Internet, Hry, Kancelária, Systém…); mriežka ikon s názvom
(`app_grid`); počas písania fuzzy hľadanie v názve, kľúčových slovách a kategóriách, častejšie používané vyššie;
kalkulačka priamo v hľadaní; pravý klik na aplikáciu = ďalšie možnosti (akcie `.desktop`, pripnúť).
Predpony `/emo`, `/win`, `/pan`, `/session`, `/wall` a vlastné poskytovatelia z pluginov (`[[launcher_provider]]`).
Po skopírovaní (emoji, výsledok) vie **sám vložiť** (`auto_paste`); história schránky Noctalie po kliknutí **vkladá**
(`clipboard_auto_paste`) — to je „klik v Kapse vloží“ bez vlastného kódu.
LatteOS má dnes vlastný spúšťač (`spustac.qml`) a vlastný Text Bar (4 režimy) — z veľkej časti duplikát; režimy Web, AI,
Linux príkaz a Súbory sa dajú pridať ako poskytovatelia pluginu do spúšťača Noctalie.

## Poradie krokov

1. Rýchle ❌ na lište **konfiguráciou Noctalie** (bez kódu): widget oblasti oznámení, widget snímky, dlaždica nahrávania,
   akcie lišty pre herný režim a Zobraziť plochu; až potom vlastné (Task View s „+“, Pripnúť v ponuke panela úloh — ako PR do Noctalie).
2. Základ i18n (I18n z DMS, `noctalia.tr`, gettext; sk do Noctalie) → potom `LTextInput` a ponuka úprav všade.
3. Qt/KDE vzhľad (šablóny Noctalie), „Nájsť v Softvéri“ → App Manager.
4. Prototyp materiálov (hyprliquid Mica/Acrylic) na latte-lab, meranie na RX 640 (vykon.sh).
5. Klikateľné makety lišty, Task View a ponúk na odsúhlasenie → implementácia.
6. ~~Rozhodnúť: pripnuté aplikácie na lište áno/nie~~ → P1: panel úloh = bežiace okná s názvom; pripnuté iba ako voľba.
