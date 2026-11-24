# Audit: LensGoo, LensShore, AppCloud, QuickGoo (24. 11. 2026)

Rozsah: spúšťače a všetko, čo z nich vychádza (`goo/drops/lensgoo.luau`, `goo/drops/quickgoo.luau`, `goo/lib/lens.luau`,
`cloud.luau`, `calc.luau`, `clipboard.luau`, `clips.luau`, `emoji.luau`, `find.luau`, `filesview.luau`, `open.luau`,
`skills.luau`, `goo/parts/cloud.plm`, `launch.plm`, `lensline.plm`, `rows.plm`, `bin/latte-clip`, `bin/latte-calc`,
`bin/latte-emoji`). Iba čítanie kódu; `pleamar --check goo/goo.plm` aj `goo/side.plm` je ok. Čísla riadkov podľa stavu
vetvy `v0.55` 24. 11. (s necommitnutými zmenami v `hyprctl`, `FILES`, `sk.plm`).

## Zhrnutie

- **Vloženie do okna (schránka, emoji, odpoveď AI) používateľovi nikdy nič nepovie.** `wm.paste` volá `hyprctl` bez
  spätného volania. Nová hláška „wtype is not installed“ ide iba do stderr a karta sa zavrie rovnako pri úspechu aj pri chybe.
- **LensShore spustí nebezpečný príkaz na prvé stlačenie** (riadok „Spustiť v termináli“ pod „Použiť … s…“). LensGoo sa pýta dvakrát.
- **Pre človeka z Windows 11 nie je jasné, ktorý spúšťač použiť.** V predvolenom vzhľade (Hravé = LensGoo) chýba „Všetky
  aplikácie“ a **Win+V nerobí nič**. AppCloud je vypnutý a jeho doska vyzerá ako hodiny. V LensShore ide Enter na meno
  aplikácie do AI.
- **Hľadanie bez diakritiky funguje iba v aplikáciách** (LensGoo, LensShore). V AppCloud, v súboroch ani v oknách nie.
  Súbory s veľkými písmenami s diakritikou LensShore dokonca vyradí.
- **Ticho pri chybách:** LensShore pri spadnutej AI nič neukáže, chybu AI ukáže ako bežnú odpoveď (aj ju ponúkne vložiť).
  Vypnutá AI odpovie anglicky. Aplikácia, ktorá sa nespustí, nepovie nič.
- **Mŕtve tlačidlá (pravidlá 8 a 23):** AppCloud nemá pravý klik na aplikácii. Pravý klik na čas a dátum na druhom
  monitore nerobí nič. Položka „Daj mu alias…“ v LensGoo nerobí nič. Pravý klik v QuickGoo hneď maže.
- **Výkon:** História schránky „Navždy“ sa pri každom otvorení načíta celá, s textom obrázkov. Prvé „time in tokyo“ bez
  siete pri každom klávese skúša 60-sekundové sťahovanie.
- **Do 0.6 stačí asi 12 malých opráv** (časť Návrh). Ostatné sú funkcie po 0.6.

---

## Dizajn

### Overené v kóde

**D1 — Tri spúšťače sa prekrývajú a človek z Windows 11 nevie, ktorý je „Štart“** — *vysoká*
- Rozdelenie dnes:
  - **LensGoo** je Štart: kvapka, karta s uchom, záložky hore, 600 px.
  - **LensShore** je PowerToys Run alebo Raycast: doska, páska siedmich režimov pri riadku, 684 px.
  - **AppCloud** je zásuvka telefónu cez celú obrazovku.
  - **QuickGoo** sú pripnuté aplikácie na lište.
- Win otvára LensGoo alebo LensShore, AppCloud nikdy (6N.05).
- **LensGoo nemá „Všetky aplikácie“.**
  - Čip „Všetky“ ukáže iba 3 riadky po 6: Najčastejšie, Obľúbené, Nové (`goo/lib/lens.luau:269-292`).
  - Filtrovaný zoznam má najviac 18 dlaždíc a nemá „Viac“ (`lens.luau:295`).
  - Aplikácia mimo týchto miest sa dá nájsť iba písaním.
  - Vo Windows 11 je „Všetky aplikácie“ v Štarte druhý najčastejší úkon.
- **AppCloud je predvolene vypnutý.**
  - Zapína ho iba vzhľad Minimal (`apps/settings.qml:1080`), Hravé ho nemá.
  - Jeho doska v ľavom dolnom rohu ukazuje iba čas a dátum. Ikona bola zrušená v 6N.07, popis je až v Nastaveniach
    (`goo/parts/cloud.plm:38-48`).
  - Človek z Windows tam hľadá Štart, no vidí hodiny. Tie má zvyknuté vpravo dole.
- Prečo na tom záleží: nováčik nenájde zoznam svojich aplikácií bez písania. Tri podoby tej istej veci pôsobia
  ako neporiadok, nie ako voľba.

**D2 — Win+V (história schránky ako vo Windows) vo vzhľade Hravé nerobí nič** — *vysoká*
- `system/pleamarwm/keys.conf:14` pošle `lens_clipboard`.
- `lens.luau:2347-2348` končí na `if not fact.lens_shore then return end`, bez vibrácie a bez hlásenia.
- Win+Shift+V (vkladať postupne, `lens.luau:2355`) pritom funguje aj s LensGoo: vloží naslepo, bez zoznamu.
- Prečo na tom záleží: Win+V je jedna z mála skratiek, ktoré ľudia z Windows naozaj poznajú. Schránka v TrayShore
  existuje, ale skratka na ňu nevedie.

**D3 — Enter v Hľadaní LensShore ide vždy do AI, aj pri presnom mene aplikácie** — *stredná, rozhodnutie používateľa*
- Riadok „Opýtať sa AI: …“ je predvybraný vždy, keď nie je výsledok kalkulačky (`lens.luau:2097`, `first = calc_shown == nil …`).
  Bolo to rozhodnutie 6B.12 a 6B.32.
- „firefox“ + Enter teda položí AI otázku „firefox“ a minie z limitu.
- Vo Windows 11 Štarte, v PowerToys Run aj v Raycaste Enter spustí najlepší výsledok a AI je Tab.
- Tu treba rozhodnutie, nie opravu (návrh v N-LS3).

**D4 — Pravý klik (pravidlá 8 a 23) chýba alebo robí niečo iné než inde** — *stredná*
- **AppCloud, dlaždica aplikácie:** iba `on press` (`cloud.plm:112-113`). Pravé tlačidlo nerobí nič, ani nezavibruje.
  V LensGoo a LensShore má tá istá aplikácia ponuku `app_menu` (`lens.luau:162-205`): Obľúbené, QuickGoo, Pripnúť
  ako kvapku, Odinštalovať.
- **AppCloud na druhom monitore, pravý klik na čas a dátum:** `cloud.plm:50-51` pošle `cloud_time` a `cloud_calendar`.
  Počúva ich iba `goo/drops/clockgoo.luau:840-841`, ktorá v `side.luau` nebeží. Tlačidlo je mŕtve.
- **QuickGoo:**
  - Pravý klik na ikonu ju **hneď odoberie** z pásky, bez ponuky a bez Späť (`goo/parts/launch.plm:34`,
    `goo/drops/quickgoo.luau:106-109`). Všade inde pravý klik otvára ponuku; tu je to ničiaci úkon na jedno stlačenie.
  - Na ikone, ktorá je na páske iba „namiesto“ (naposledy spustené), pravý klik nerobí nič.
- **LensGoo, ponuka aplikácie:** položka „Daj mu alias…“ sa ukazuje, ale v LensGoo hneď skončí
  (`lens.luau:178-179`, `if not fact.lens_shore then return end`). Tlačidlo bez funkcie.

**D5 — Páska QuickGoo sa nezatvára ako ostatné karty** — *nízka*
- Zasunie sa iba po výbere ikony alebo po druhom kliku na kvapku (`quickgoo.luau:52-66, 112`).
- `launch_on` nikto iný nečíta, takže Esc, klik mimo ani čas ju nezavrú.
- Karty Goo sa pritom zatvárajú Esc aj klikom mimo (`goo/parts/rows.plm:23`).

**D6 — Prázdne stavy: väčšina je dobrá, niektoré mlčia** — *stredná (súhrn)*
- Dobré:
  - Obľúbené s návodom „Pravým klikom na aplikáciu…“ (`lens.luau:283`), „Nič nové nenainštalované“.
  - Schránka „Ešte sa nič neskopírovalo“ a „Nič také sa neskopírovalo“ (`clipboard.luau:188`).
  - Okná „Nie je otvorené žiadne okno“, AppCloud „Nič sa nenašlo“, Agenti „Žiadny agent nepracuje“.
- Mlčia alebo mätú:
  - **Emoji bez balíkov** (`unicode-emoji` je voliteľný vo `FILES`): `emoji.luau:43-57` dá `all = {}`, potom
    „Zatiaľ tu nič nie je“ (`emoji.luau:320`). Nepovie, že chýba balík a kde sa zapína.
  - **Text z obrázka a QR kód:** keď sa nič nenájde, nestane sa nič; karta sa už zavrela (`clipboard.luau:94-97`).
  - **Plné QuickGoo** (8 aplikácií): „Mať poruke v QuickGoo“ nerobí nič (`quickgoo.luau:72`). Rovnako 13. obľúbená
    aplikácia (`lens.luau:168`). Používateľ nevie prečo.
  - **Odinštalovaná aplikácia v QuickGoo** ostane v `quick.json` a zaberá miesto. Neukáže sa, ale počíta sa do limitu 8
    (`quickgoo.luau:33-37`, 72).
  - **QuickGoo pri prvom spustení:** bez histórie dá na pásku prvých 5 aplikácií zo služby `apps` (`quickgoo.luau:38-41`),
    teda ľubovoľné. Lepšie je ukázať iba kvapku s bublinou „Pravým klikom na aplikáciu v LensGoo ju pridáš“.
  - **Pravý klik na LensGoo pri prvom spustení:** karta má iba „Hľadať…“ (`lens.luau:1152-1165`). Spec §4.3 chce aj
    obľúbené a App Manager.

**D7 — Chybové hlásenia** — *stredná*
- Vloženie do okna: pozri F1.
- AI v LensShore: pozri F3. Chyba AI sa ukáže ako bežná odpoveď a vypnutá AI odpovie anglicky
  (`bin/latte-ai:3972` bez `N()`), čo je proti pravidlu 4.
- `open.app` je `pcall(sys.call, "apps.launch", …)` (`goo/lib/open.luau:23`). Aplikácia s pokazeným `.desktop` sa
  nespustí a nič to nepovie, karta je už zavretá.
- Dobrý vzor už v kóde je: `skills.luau:56` pri neúspechu pošle upozornenie „Nepodarilo sa“. Ten istý vzor treba
  vloženiu, spúšťaniu aj OCR.

**D8 — Klávesnica a prístupnosť** — *nízka až stredná*
- LensGoo a LensShore sa dajú ovládať klávesmi celé: šípky, Enter, Esc, Tab a Shift+Tab, PageUp a PageDown,
  Ctrl+K, Ctrl+Enter (`rows.plm:23-43`, `lensline.plm:27-41, 183-186`).
- **AppCloud:**
  - Šípky, Enter a Esc fungujú, ale záložky kategórií sa z klávesnice prepnúť nedajú (žiadny Tab, `cloud.plm:129-134`).
  - ← a → nefungujú, kým je niečo napísané.
  - Pole hľadania nemá viditeľnú nápovedu, iba ikonu lupy (`cloud.plm:120-123`; `label` slúži len prístupnosti).
- **QuickGoo** ikony na páske nevyberie klávesnicou nič (iba režim Win+T po kvapkách).
- **Veľkosti cieľov sú v poriadku:**
  - riadok 44 px, s druhým riadkom 54 px (`goo/lib/card.luau:131-139`);
  - dlaždica 84 px, bunka emoji 46 px;
  - AppCloud bunka približne 130 × 134 px, ikona QuickGoo 44 px.
- **Dlhé mená** sú v dlaždiciach na jeden riadok (12,5 px) a skrátené („Beyond All R…“, `rows.plm:434`). Dlaždica
  LensGoo celé meno nikde neukáže, QuickGoo ho ukáže v bubline.
- Chýba **Win+.** (emoji ako vo Windows 11). Emoji sú len v LensShore (`keys.conf` ho nemá) — funkcia po 0.6.

**D9 — Vizuálna jednota troch spúšťačov** — *nízka*
- Prepínač režimov je v LensGoo hore ako záložky, v LensShore dole ako páska pri riadku.
- Mená sa líšia:
  - LensGoo „Príkaz“ oproti LensShore „Spustiť v termináli“;
  - Okná, Schránka, Emoji a Agenti sú iba v LensShore;
  - Web je v LensGoo režim, v LensShore záložný riadok.
- Šírka LensShore je `WIDE / 1.2` = 517 px (`lens.luau:2208`), LensGoo 600 px. Výška LensShore je 684 px
  (`lens.luau:1172`), ROADMAP 6B.28 ešte píše 540.
- Snímka `docs/screenshots/lensshore.png` je z 30. 10.:
  - ukazuje sekciu „HNEĎ“, ktorú nahradil pegboard (`skills.suggestions`, `goo/lib/skills.luau:64`, je teraz mŕtvy kód);
  - nemá režim Súbory ani pätu s Akciami Ctrl+K.

**D10 — Sklo, pohyb a pokoj** — *nízka*
- Kvapky sa nijako neodchyľujú od pravidiel:
  - LensGoo `nature = "calm"`, veľkosť 30; QuickGoo `curious`, veľkosť 24;
  - koliesko mení veľkosť (engine), páska QuickGoo je `stretch` kvapky;
  - AppCloud vychádza pružinou `spring(420, 30)` a roluje pružinou `cl.off`.
- AppCloud prekrytie má `glass: cl.glass * 100%`, kde `cl.glass = if(true_glass, 1, material)` (`cloud.plm:59, 76-82`).
  Pri **Sklo 0** sa vypne iba `lens`. Mráz a sklo ostávajú podľa materiálu kvapiek, nie podľa voľby skla — overiť naživo (L7).

### Podozrenie, treba naživo

- **DP1:** Páska LensShore má 7 režimov v šírke 517 px. „AI rozhovor“ a „Schránka“ sa môžu orezať, na snímke so 6
  režimami je už plná. Pri 1024 × 768 (pravidlo 11) treba overiť aj výšku 684 px plus doska: vrch karty sa nesmie
  dostať nad obrazovku (6B.51 ho drží 24 px od vrchu).
- **DP2:** Kontrast textu kariet nad svetlou tapetou. Dátum na doske AppCloud má 12 px a nepriehľadnosť 72 %
  (`cloud.plm:41`). Nadpisy v kartách sú malé kapitálky. Pri 6.46 (duchovia kurzora) presvitajú ikony plochy.
- **DP3:** Ctrl+X, Ctrl+E a Ctrl+P v kartách patria `card_combo` (`rows.plm:34, 40-41`), ak je karta otvorená. Ak ich
  pleamar zje skôr než pole, nedá sa v poli LensGoo vystrihnúť, napríklad Ctrl+X. V Schránke je výnimka iba pri
  napísanom texte (`lens.luau` `combo`).
- **DP4:** Ikona súboru alebo priečinka v QuickGoo je glyf vo farbe `ink` (`launch.plm:30`). Na tmavej káve môže
  byť nečitateľná.

---

## Funkcie

### F1 — Vloženie zo schránky a emoji: čo povie UI, keď sa nevloží (otázka dňa)

**Odpoveď: nič. Overené v kóde.**
- Cesta:
  1. `paste(put)` (`lens.luau:1487-1490`): `put` dá text do schránky (`wl-copy`).
  2. Po 350 ms `wm.paste(address, terminal)`.
  3. `wm.paste` volá `eval` (`goo/lib/wm.luau:76-78`) a ten `run("hyprctl", args)` **bez spätného volania**
     (`wm.luau:6-7`). Návratový kód aj stderr sa zahodia.
- Náhrada `system/pleamarwm/bin/hyprctl:404-414` bez `wtype` vypíše „wtype is not installed, nothing pasted (it is on
  the clipboard)“ do stderr a skončí s kódom 0. Návratový kód `wtype` nekontroluje.
- Tú vetu nikto neuvidí. Riadok sa volal „Vložiť do Firefox“, karta sa zavrela, v okne nič nie je.
- Používateľ si nemusí domyslieť, že text je v schránke. Pri emoji je navyše **prepísaná jeho pôvodná schránka**
  (`put_text`, `lens.luau:1542`).
- Rovnako mlčí aj **Vložiť** pod odpoveďou AI (`lens.luau:2020`) a Win+Shift+V (`clipboard.luau:240-256`).
- Chybu `wl-copy` (`clipboard.luau:53-56`, `put_text`) tiež nikto nečíta.
- **Jeden prípad sa nedá zistiť vôbec:** wtype je nainštalovaný, ale záplata `pleamar-wm-zzz-virtual-keyboard.patch`
  ešte nie je nasadená. wtype vtedy skončí s 0 a píše na seat agenta. Samotné „hlásiť chybu“ preto nestačí. Používateľ
  potrebuje vždy krátku pravdivú vetu, napríklad „Vložené do Firefox · je aj v schránke“. Keď sa nevloží, vie, kde to je.
- Komentár `wm.luau:74-75` („Not wtype: Hyprland reads…“) je po dnešku nepravdivý: na pleamar-wm vkladá práve wtype.
- *vysoká* (funkcia sa nikdy nedala použiť a ani dnes nepovie, keď zlyhá)

### Overené v kóde

**F2 — LensShore: nebezpečný príkaz bez druhého stlačenia** — *vysoká*
- Záložný riadok „Spustiť v termináli“ (`lens.luau:2173`) volá `run_command(q)` priamo.
- LensGoo ten istý príkaz púšťa cez `confirmed()` (`lens.luau:529, 535`; `lib/dangerous`).
- Príkazy z odpovede AI chcú druhé stlačenie (`lens.luau:2027-2028`, S10).
- Takže `rm -rf ~` napísané do LensShore, šípka na tento riadok a Enter spustí príkaz hneď.

**F3 — LensShore: AI pri chybe mlčí alebo klame** — *vysoká*
- Koniec `ask()` (`lens.luau:1283-1288`):
  - `latte-ai` skončí bez záverečného JSON (pád, zabitie, chýbajúci program) a nič neprišlo → nepridá sa nič.
    Otázka visí bez odpovede, „Premýšľam…“ zmizne.
  - LensGoo má pre ten istý prípad „Neprišla žiadna odpoveď.“ (`lens.luau:859`).
- `final.ok == false` sa nečíta: chybová veta sa uloží ako bežná odpoveď. Riadok pod ňou ponúkne „Vložiť do {app}“ a
  Enter vloží chybovú hlášku do aplikácie používateľa (`lens.luau:2018-2021`).
- **Vypnutá AI za behu:**
  - `latte-ai providers` sa pýta **iba raz pri štarte** (`lens.luau:2526-2535`). `MODES[4]` ostane a LensShore ďalej
    ponúka „Opýtať sa AI“ ako prvý riadok.
  - Odpoveď príde anglicky („latte-ai: the AI is turned off (Settings › AI)“, `bin/latte-ai:3972`).
  - `shore.chat` sa nastaví na `""`.
- **Zapnutá AI alebo nová služba za behu:** záložka AI v LensGoo a režim AI v LensShore sa objavia až po reštarte Goo.
- **Win+C bez AI:** `M.open(4)` nastaví `ai.pending` (`lens.luau:1140`) a nič sa neotvorí, navždy.

**F4 — Diakritika a veľké písmená mimo hľadania aplikácií** — *stredná*
- `find.luau` (aplikácie) používa `fold`: „kalkulacka“ nájde „Kalkulačka“. Inde nie:
  - **AppCloud:** `string.lower` a hľadanie podreťazca (`goo/lib/cloud.luau:61, 66`). „subory“ nenájde „Súbory“.
    Luau `lower` nezmenší ani „Š“ či „Č“.
  - **Okná v LensShore:** `(w.title .. " " .. name):lower():find(want, 1, true)` (`lens.luau:1456`).
  - **Súbory v LensShore** (`goo/lib/filesview.luau:118-145`):
    - fd má `--ignore-case`, ale Unicode diakritiku nezloží;
    - potom sa každý nájdený riadok filtruje `path:lower():find(w)`. Súbor „ÚČET.pdf“ fd nájde na „účet“, no Luau z neho
      urobí „ÚČet“ a **vyradí ho**.
    - Skóre (`filesview.luau:80-94`) má ten istý problém.
  - **Súbory v LensGoo a Hľadanie v LensShore:** `look_for_files` (`lens.luau:470-480`) posiela text do `fd` **ako
    regulárny výraz** (bez `--fixed-strings`). „c++“, „a[“ alebo „(1)“ skončí chybou fd a ukáže sa „Nič sa nenašlo“.
- `fold` (`goo/lib/fold.luau`) pozná iba slovenčinu, češtinu a nemčinu. Pre poľské a maďarské mená (ł, ő) nič
  nezlyhá, len sa nezložia. Stačí ako je.

**F5 — Dve rôzne minútky** — *stredná*
- „timer 10“ v LensShore je `after(n * 60000, …)` vnútri scény (`lens.luau:1206-1208`).
- Nie je v `goo/lib/timers.luau`, preto ju neukáže ClockGoo ani doska AppCloud (6D.13, 6N.04).
- Nezvoní tónom ako minútka ClockGoo, len pošle upozornenie.
- **Stratí sa pri reštarte scény** (nasadenie, pád, zmena monitora).

**F6 — História schránky „Navždy“ a výkon** — *stredná*
- `latte-clip list` vráti **celú** históriu: všetky položky, OCR text každého obrázka do 2000 znakov a až 80 náhľadov
  (`bin/latte-clip:211-229`).
- Robí to pri každom otvorení Schránky a pri každom Win+Shift+V, pod výhradným zámkom.
- Luau potom pri každom písmene skladá (`fold`) všetky položky (`clipboard.luau:145-149`). Pripnuté porovnáva
  s každou položkou, teda O(n·m) (`clipboard.luau:172-175`).
- Predvolené je „Navždy“ a `-max-items 1000000` (6B.51). Po mesiacoch to bude pomalé pri každom otvorení.
- Nikde sa neukazuje počet položiek ani miesto na disku (6B.51 „Chýba“).

**F7 — „Zmazať všetko“ v Schránke nezmaže všetko** — *stredná (súkromie)*
- `cliphist wipe` sa volá priamo (`clipboard.luau:125`, aj `clips.luau:22` v TrayShore), mimo `latte-clip`.
- Ostanú `~/.local/state/latteos/clipboard-text/*.txt` (text prečítaný z obrázkov) a `~/.cache/latteos/clips/*.png`
  (náhľady obrázkov). `latte-clip list` potom upratá iba `clipboard.json`, nie tieto súbory (`bin/latte-clip:128-150`).
- Kto zmaže históriu kvôli citlivému snímku, má ho dál na disku aj s textom.

**F8 — Kľúč pripnutia obrázka je jeho popis od cliphist** — *nízka*
- Pripnutie a odopnutie hľadá podľa `c.text` (`clipboard.luau:65, 78, 87, 174`). Pri obrázku je to
  „[[ binary data 812 KiB png 1920x1080 ]]“.
- Dva snímky obrazovky s rovnakým rozmerom a podobnou veľkosťou majú rovnaký kľúč. Odopne sa iný, alebo sa druhý
  skryje zo zoznamu „SCHRÁNKA“.

**F9 — Prvé použitie miest v kalkulačke bez siete** — *stredná*
- „time in tokyo“ a „diff Paris“ majú fungovať bez siete (6B.48).
- Súbor miest sa však stiahne až pri prvej takej otázke, **synchrónne v `latte-calc`, s časovým limitom 60 s**
  (`bin/latte-calc:107-135`).
- Každé ďalšie písmeno spustí ďalší `latte-calc` a ten sťahuje znova. Zámok nie je a všetky píšu do toho istého
  `places.tsv.new`.
- Bez siete sa súbor nikdy nevytvorí a každý úder skúša sťahovať.
- Panel nič neukáže, ani „Hľadám…“.
- Treba ho stiahnuť raz na pozadí (pri inštalácii alebo po prihlásení) a pri písaní ho iba čítať.

**F10 — Najčastejšie spúšťané počíta iba LensGoo a LensShore** — *nízka*
- `kept.counts`, `recent` a `visits` píše iba `launch()` (`lens.luau:116-126`).
- AppCloud (`cloud.luau:101-105`), QuickGoo (`quickgoo.luau:104`), DockShore a ikony plochy spúšťajú mimo neho.
- Kto spúšťa najmä z AppCloud, má „Najčastejšie spúšťané“ prázdne alebo zlé. QuickGoo v predvolenom stave berie práve tento zoznam.

**F11 — „Nové aplikácie“ nemajú vekovú hranicu** — *nízka*
- `learn_born` berie čas zrodu `.desktop` (`lens.luau:1037-1050`) a sekcia ukáže 6 najnovších bez ohľadu na vek
  (`lens.luau:285-291`).
- Po `dnf upgrade` sa `.desktop` súbory prepíšu (nový inode, nový čas zrodu). „NOVO NAINŠTALOVANÉ“ potom ukáže
  aktualizované aplikácie.
- Treba hranicu (napríklad 14 dní) a porovnanie so starým zoznamom ID.
- ID sa zhodujú: v `lens.json` sú bez `.desktop`, kontrolované.

**F12 — Režimy cez klávesy v LensShore** — *nízka*
- Super+C a Super+R volajú `M.open(m)` (`lens.luau:1138-1146`, `keys.conf:21, 23`). Ten v LensShore iba nastaví
  `kept.mode` a vykreslí doterajší `shore.view`.
- Win+C teda neotvorí AI rozhovor, Win+R neotvorí nič terminálové.

**F13 — Rozdiely spec ↔ kód**
- §4.3: v režime Aplikácie „prvé tri nájdené súbory“. `rows_apps` súbory nemá, iba odkaz „Hľadať súbory: …“
  (`lens.luau:323`). *nízka*
- §4.3: rýchly zoznam (pravý klik) má mať naposledy spustené **aj obľúbené**, Hľadať… **a App Manager**. Kód má iba
  naposledy spustené a Hľadať… (`lens.luau:1152-1165`). ROZHRANIE.md píše iba „naposledy spustené“, dokumenty si
  odporujú. *nízka*
- §4.3 a §8: „akcie aplikácie na pravý klik“ (Desktop Actions z `.desktop`, napríklad „Nové okno“) stále chýbajú.
  Po 0.6.
- 6N.05 a komentár `cloud.plm:34` („also when the Windows key opened it: lib/lens.luau sets cloud_grid“): `lens.luau`
  už `cloud_grid` nenastavuje, komentár je zastaraný.
- 6B.49: ROADMAP píše, že kontakt do User-Agent „čaká na používateľa“. V `bin/latte-calc:357` už je (od 17. 11.).
  Opraviť text v ROADMAP.
- 6B.28: „540 px“ oproti `SHORE_H = 684`.

**F14 — Mŕtvy kód a skratky (`ponytail:`)**
- `lens.luau:2530-2531` `ponytail:` → rozhodnuté 10B.52: všetky služby majú vzhľad `own`.
  - Mŕtve sú vetvy podľa služby v `fill_ai` (`lens.luau:620-760`: `HINTS`, `ROW_H`, `PLUS_W`, `CHIP_W`, uvítania
    Claude, Gemini, Mistral…) a väčšina `goo/parts/ai.plm` (418 riadkov).
  - Upratať pred 0.6. Je to len mazanie a scéna má 11 tis. vlastností (kategória 17).
- `lens.luau:1525` `ponytail:` → obrázok kaviarne (6B.35). **Kaviareň je zrušená** (Poradie práce, 21. 11.).
  - V Agentoch ostáva neaktívne tlačidlo „Vstúpiť do kaviarne“ (`lens.luau:2057-2058`).
  - Kvôli nemu sa každé 3 s spúšťa `cat` celého PNG (`lens.luau:1532`). Zmazať.
- `goo/lib/filesview.luau:192` `ponytail:` → nedávna cesta bez prípony = priečinok. Môže ostať do indexu (6B.50).
- `system/pleamarwm/bin/hyprctl:422` `ponytail:` → prichytávanie, plochy a sklo čakajú na 1D.06–1D.09. Mimo rozsahu,
  ale „Rozložiť“ v ponuke okna LensShore (`lens.luau:1408-1449`) na tom závisí (L9).
- `rows_ai()` vracia `{}` (`lens.luau:1078`). Je to len zástupca, aby MODES[4] mal `rows`.
- `skills.suggestions` (`skills.luau:64`) nikto nevolá (sekciu HNEĎ nahradil pegboard, 6B.38). `skills.refresh(again)` pri
  každom otvorení LensShore (`lens.luau:2258`) pritom stále prekresľuje kartu kvôli nej.
- `cloud_hit` v `cloud.plm:42, 46` je úplne prekrytý `cloud_time_hit` a `cloud_date_hit`.

**F15 — Výkon a procesy na pozadí** — *nízka až stredná*
- **LensGoo pri každom písmene bez oneskorenia** spustí `latte-settings find`, prípadne `latte-calc` a `qalc`
  (`lens.luau:1124`). LensShore čaká 140 ms (`lens.luau:2291-2299`).
- **Predošlé hľadania sa nerušia** (`run` bez zabitia). Pri rýchlom písaní beží naraz niekoľko `fd` cez celý domov a
  `latte-files grep` (ripgrep až 6 s, `filesview.luau:102-114`).
- **`every(5000)` `latte-ai running`** beží stále, kým je zvolený LensShore, aj so zavretou kartou (`lens.luau:2327-2344`).
  Na notebooku to zbytočne budí CPU. Stačí sa pýtať, kým beží nejaký agent, alebo redšie.
- AppCloud: `capp max 120` a `repeat k in 0..120` (`cloud.plm:25, 102`), ale `win = cols * (riadky + 1)`
  (`cloud.luau:53`). Pri 12 stĺpcoch a výške nad ~1520 px (4K pri 100 %, 2560 × 1600) je `win` 132–180. Spodné riadky
  sa pri rolovaní môžu nevykresliť (L8).

**F16 — Ostatné okrajové prípady (overené)**
- **Aplikácia nainštalovaná za behu:** všetky štyri čítajú `sys.watch("apps")`, takže sa objaví hneď. `learn_born` sa
  pri každej zmene spustí znova. V poriadku.
- **0 výsledkov:**
  - LensGoo má vždy „Hľadať súbory: …“ a „Hľadať na webe: …“;
  - LensShore má vždy „Použiť „…“ s…“;
  - AppCloud ukáže „Nič sa nenašlo“ a Enter nerobí nič (správne podľa 6N.05).
- **Sieť:** web, počasie a spoje zlyhajú ticho, panel kalkulačky sa jednoducho neukáže. Spoje majú „Spoj sa nenašiel“
  s odkazom na cp.sk (dobré).
- **Dva monitory:**
  - LensGoo, LensShore a QuickGoo sú iba na hlavnom monitore;
  - Win otvorí spúšťač na hlavnom monitore aj vtedy, keď sa pracuje na druhom;
  - AppCloud na druhom monitore má mriežku, ale bez minútky a bez pravého kliku (D4).
- **Mazanie:** `Uninstall…` ide cez App Manager (`lens.luau:190-191`), teda v poriadku. „Presunúť do koša“ v ponuke súboru
  (`lens.luau:216-217`) sa nepýta a nehlási výsledok. Kôš je však vratný, nízka.

### Podozrenie, treba naživo

- **FP1:** wtype `-M ctrl … -k v` bez `-m ctrl` (`hyprctl:414`). Či pleamar-wm pri zániku virtuálnej klávesnice uvoľní
  Ctrl. Inak môže Ctrl „visieť“ (ďalší kláves ako Ctrl+kláves).
- **FP2:** Okno vpredu pri otvorenej karte LensShore. `front_window()` berie `activewindow`. Či pleamar-wm hlási
  aplikáciu, ktorá mala klávesnicu pred kartou, a nie nič. Inak riadok povie „Kopírovať“ namiesto „Vložiť do …“.
  Overené len v headless s foot.
- **FP3:** Aplikácia spustená z AppCloud na druhom monitore. Na ktorom monitore sa otvorí (podľa ukazovateľa, alebo
  vždy na hlavnom)?
- **FP4:** LensShore Súbory s tisíckami výsledkov a sieťovým diskom v `lens_files_roots`. Ripgrep 6 s a viac procesov fd
  naraz pri písaní.

---

## Návrh dokončenia

Poradie podľa „Poradia práce“: **do 0.6 iba opravy**. Čo nie je oprava, má značku *po 0.6 (funkcia)*.

### Spoločné (všetky spúšťače)

| # | Čo | Súbory | Kedy |
|---|---|---|---|
| N1 | **Vloženie hlási výsledok.** `hyprctl` pri `send_shortcut` skončí s nenulovým kódom, keď wtype chýba alebo zlyhá. `wm.paste(address, terminal, done)` dostane spätné volanie (`run` s `cb(out, code)`). LensShore po vložení vždy pošle krátke upozornenie: „Vložené do {app} · je aj v schránke“. Pri chybe „Nevložilo sa: {dôvod}. Je to v schránke, Ctrl+V“ (vzor `skills.luau:56`). Pri emoji to isté. Komentár `wm.luau:74-75` opraviť. | `system/pleamarwm/bin/hyprctl`, `goo/lib/wm.luau`, `goo/lib/lens.luau` (`paste`), `goo/lang/sk.plm` | pred 0.6 |
| N2 | **wtype nie je voliteľný.** Bez neho nefunguje vloženie z LensShore ani Win+Shift+V. Presunúť z `optional:` medzi povinné, alebo ho viazať na LensShore. Nasadiť záplatu virtuálnej klávesnice (bughunt 24. 11.). | `FILES`, `patches/` | pred 0.6 |
| N3 | **Spustenie aplikácie, ktoré zlyhá, sa ohlási.** `open.app` vráti výsledok `apps.launch`; pri chybe upozornenie „{app} sa nespustila“. | `goo/lib/open.luau`, volajúci v `lens.luau`, `cloud.luau`, `quickgoo.luau` | pred 0.6 |
| N4 | **Hľadanie s `fold` všade.** AppCloud `fill()` (`cloud.luau:61-68`), okná (`lens.luau:1456`), súbory (`filesview.luau:118-145`, `score`): porovnávať `fold(...)`, nie `:lower()`. `look_for_files` doplniť o `--fixed-strings` (`lens.luau:475`). fd nevie skladať diakritiku. Pri slove s háčikmi alebo bez nich doplniť druhé hľadanie s `fold` nad výstupom bez `--ignore-case` filtra, alebo `-g` vzor. Najmenší krok: filtrovať výstup fd až po `fold`. | `cloud.luau`, `lens.luau`, `filesview.luau` | pred 0.6 |
| N5 | **Počítadlá spustení spoločné.** `launch()` vytiahnuť do `lib/open.luau` alebo malého `lib/visits.luau` a volať aj z AppCloud a QuickGoo. | `lens.luau`, `cloud.luau`, `quickgoo.luau` | pred 0.6 (oprava personalizácie), nízka priorita |

### LensShore

| # | Čo | Súbory | Kedy |
|---|---|---|---|
| N-LS1 | **Nebezpečný príkaz dvakrát.** Riadok „Spustiť v termináli“ pod „Použiť … s…“ cez `confirmed(q)` ako LensGoo. Pri prvom stlačení riadok zmení text na „Nebezpečný príkaz: stlač znova“. | `lens.luau:2173` | pred 0.6 |
| N-LS2 | **AI pri chybe:** v `ask()` doplniť `else` „Neprišla žiadna odpoveď.“ ako v LensGoo. Pri `final.ok == false` riadok `failed` (červený), bez riadku „Vložiť do …“. Chybový text z `latte-ai` prekladať. Pri `send` s vypnutou AI dať `N(...)`, preložiť v `sk.plm` a ukázať cez `tr()`. `shore.chat` neprepisovať prázdnym. | `lens.luau:1283-1288, 2016-2021`, `bin/latte-ai:3972`, `goo/lang/sk.plm` | pred 0.6 |
| N-LS3 | **Enter na presné meno aplikácie.** Rozhodnutie používateľa (6B.12 a 6B.32 hovoria „vždy AI“). Návrh na rozhodnutie: ak je zhoda úrovne 1–2 (alias alebo presné meno, `find.luau:114-119`), predvybrať aplikáciu a riadok AI nechať druhý. Tab ostáva Quick AI. Prípadne voľba v Nastaveniach › LensShore „Enter: AI · najlepší výsledok“. | `lens.luau:2097`, `find.luau` (vrátiť `tier`) | rozhodnúť; oprava je malá |
| N-LS4 | **AI za behu:** `latte-ai providers` pýtať znova pri zmene `settings.json` alebo pri otvorení karty, ak je zoznam starší ako 60 s. `MODES[4]` pridať aj odobrať. Win+C bez AI: upozornenie „AI je vypnutá alebo nie je prihlásená služba · Nastavenia › AI“ namiesto `ai.pending` navždy. | `lens.luau:1140, 2526-2535` | pred 0.6 |
| N-LS5 | **Minútka cez `timers.luau`**, nie `after()`: „timer 10“ spustí minútku ClockGoo. Uvidí ju aj doska AppCloud a prežije reštart scény, ak ju `timers` ukladá. | `lens.luau:1206-1208`, `goo/lib/timers.luau` | pred 0.6 |
| N-LS6 | **Win+C a Win+R v LensShore:** `M.open(m)` pri `fact.lens_shore` mapuje 4 → `go_mode("ai")`, 3 → riadok s napísaným príkazom, 1 → `go_mode("files")`. | `lens.luau:1138-1146` | pred 0.6 |
| N-LS7 | **Upratať:** kaviareň (`lens.luau:1525-1536, 2056-2059`), `skills.suggestions` a jeho `refresh(again)` pri otvorení, vetvy štýlov AI (10B.52). | `lens.luau`, `skills.luau`, `goo/parts/ai.plm` | pred 0.6 (mazanie, kategória 17) |
| N-LS8 | **Poll agentov** `every(5000)` iba vtedy, keď posledná odpoveď mala aspoň jedného agenta, inak raz za 30 s. | `lens.luau:2327` | pred 0.6 (výkon), nízka |
| N-LS9 | Nová snímka `docs/screenshots/lensshore.png` (pegboard, Súbory, päta s Ctrl+K). | `docs/` | pred 0.6 (dokumentácia) |
| N-LS10 | Ctrl+R, Shift+Ctrl+R, kontext `@`, „Spýtaj sa schránky“, úryvky (6B.47 krok 5), Win+. pre emoji, `:` v poliach. | — | po 0.6 (funkcia) |

### Schránka (LensShore, TrayShore) a `latte-clip`

| # | Čo | Súbory | Kedy |
|---|---|---|---|
| N-CB1 | **„Zmazať všetko“ cez `latte-clip wipe`.** Nový príkaz pod zámkom: `cliphist wipe`, potom zmazať `clipboard-text/`, `clips/*.png` a `clipboard.json`. Volať ho z `clipboard.luau:125` aj `clips.luau:22`. | `bin/latte-clip`, `goo/lib/clipboard.luau`, `goo/lib/clips.luau` | pred 0.6 (súkromie) |
| N-CB2 | **`latte-clip list --limit N --offset K`** a hľadanie v Pythone (`--query`, s `fold` ako `latte-calc`). LensShore si pýta stranu po 6, nie celú históriu. `list` bez zámku pri čítaní (zámok iba pri zápise času). | `bin/latte-clip:200-230`, `clipboard.luau:22-28, 152-217` | pred 0.6 (výkon pri predvolenom „Navždy“) |
| N-CB3 | **Prázdny výsledok OCR a QR** povie „V obrázku nie je text / QR kód“ (upozornenie alebo riadok). | `clipboard.luau:94-97` | pred 0.6 |
| N-CB4 | **Kľúč pripnutia obrázka = `id`** (pripnutý obrázok sa aj tak kopíruje do `clipboard-pins/ID.png`), nie popis. | `clipboard.luau:63-81, 174` | pred 0.6, nízka |
| N-CB5 | Počet položiek a miesto na disku v Nastaveniach (6B.51). | `apps/settings.qml`, `bin/latte-clip` | po 0.6 |

### LensGoo

| # | Čo | Súbory | Kedy |
|---|---|---|---|
| N-LG1 | **Win+V s LensGoo:** v Hravé otvoriť históriu schránky (panel TrayShore so schránkou, alebo kartu LensGoo s riadkami `clipboard.sections`). Najmenší krok: ak `not fact.lens_shore`, emitovať otvorenie panelu TrayShore na schránke. Aspoň zavibrovať a ukázať bublinu „Schránka je v TrayShore“. | `lens.luau:2347-2353`, `goo/lib/shore.luau` | pred 0.6 |
| N-LG2 | **„Všetky aplikácie ›“**: posledný riadok prehľadu (pri „Prispôsobiť túto stránku“) otvorí mriežku AppCloud (`fact.cloud_grid = true`). Mriežka funguje aj bez dosky, pretože `cloud.plm` ju kreslí podľa `cl.p`. Filtre nad 18 dlaždíc dostanú „Viac ›“. | `lens.luau:262-300`, `cloud.luau` | **rozhodnúť s používateľom**; technicky malé (iba prepojenie) |
| N-LG3 | **„Daj mu alias…“ skryť v LensGoo** (`lens.luau:178`): položku pridávať iba pri `fact.lens_shore`. „Skryť z výsledkov“: v LensGoo ukázať, kde sa to vracia (Nastavenia › Spúšťač). | `lens.luau:162-205` | pred 0.6 |
| N-LG4 | **Plné limity:** „Mať poruke v QuickGoo“ pri 8 a „Pridať do obľúbených“ pri 12 ako `off` riadok s vysvetlením („QuickGoo je plné, 8“), nie tichý klik. | `lens.luau:168-172`, `quickgoo.luau:71-76` | pred 0.6 |
| N-LG5 | **Rýchly zoznam podľa §4.3:** pridať obľúbené a App Manager (alebo opraviť §4.3 a ROZHRANIE, ak sa rozhodne inak). Prázdny stav pri prvom spustení: „Tu budú naposledy spustené aplikácie“. | `lens.luau:1152-1165`, `LATTEOS-GOO.md`, `docs/goo/ROZHRANIE.md` | pred 0.6 |
| N-LG6 | **„Nové aplikácie“ s hranicou 14 dní** a bez aktualizovaných balíkov (porovnať s ID videnými pri minulom štarte, uložiť do `lens.json`). | `lens.luau:285-291, 1037-1050` | pred 0.6, nízka |
| N-LG7 | **Oneskorenie 140 ms** pre `change` poľa ako v LensShore, a zabitie predošlého `fd` (`spawn` a `kill`). | `lens.luau:1117-1126, 470-480` | pred 0.6 (výkon), nízka |
| N-LG8 | Desktop Actions na pravý klik, súbory v režime Aplikácie (§4.3), Clipboard, Emoji a Okná ako režimy LensGoo. | — | po 0.6 (funkcia) |

### AppCloud

| # | Čo | Súbory | Kedy |
|---|---|---|---|
| N-AC1 | **Pravý klik na dlaždicu** → `on press right capp_hit.$k { emit cloud_menu(k) }`. `cloud.luau` otvorí tú istú ponuku ako LensGoo (`app_menu` vytiahnuť z `lens.luau` do zdieľaného modulu, napríklad `lib/appmenu.luau`). | `cloud.plm:112-113`, `cloud.luau`, `lens.luau:162-205` | pred 0.6 (pravidlo 23) |
| N-AC2 | **Druhý monitor:** pravý klik na čas a dátum v `side` buď zavibruje, alebo pošle `latte-say` hlavnej scéne (`emit cloud_time`). Karta ClockGoo sa vtedy otvorí na hlavnom monitore. Najmenší krok: `active: not side` pre `cloud_time_hit` a `cloud_date_hit` a vibrácia. | `cloud.plm:43-51`, `goo/side.luau` | pred 0.6 |
| N-AC3 | **`fold` vo filtri** (N4) a nápoveda v poli „Hľadať aplikácie…“ (text v `cloud.plm` ako hint, preklad v `sk.plm`). | `cloud.luau:61-68`, `cloud.plm:120-123` | pred 0.6 |
| N-AC4 | **Model nad 120:** `capp max 180` a `repeat k in 0..180`, alebo `win = min(win, 120)` a riadky nad tým dopĺňať pri rolovaní. Najprv overiť L8. | `cloud.plm:25, 102`, `cloud.luau:53` | pred 0.6, ak L8 potvrdí |
| N-AC5 | **Záložky z klávesnice** (Tab a Shift+Tab, `cloud_pick`), Home a End. | `cloud.plm:129-134` | pred 0.6, nízka |
| N-AC6 | **Doska prezradí, čo robí:** bublina pri prechode myšou „Všetky aplikácie · pravý klik: čas / kalendár“ (pravidlo 24, vrstva 1). Ikonu na dosku nevracať (6N.07). Opraviť komentár `cloud.plm:34`. | `cloud.plm:38-51` | pred 0.6, nízka |

### QuickGoo

| # | Čo | Súbory | Kedy |
|---|---|---|---|
| N-QG1 | **Pravý klik na ikonu = ponuka** (Otvoriť · Posunúť vľavo / vpravo · Odobrať z QuickGoo · Pripnúť ako kvapku), nie okamžité odobratie. Na ikone „namiesto“ ponuka „Mať poruke“. | `launch.plm:34`, `quickgoo.luau:106-109` | pred 0.6 (pravidlá 8 a 23) |
| N-QG2 | **Zasunúť pásku** pri Esc, kliku mimo (zóna cez plochu, kým je `launch_on`) a po ~8 s bez myši nad ňou. | `launch.plm`, `quickgoo.luau` | pred 0.6 |
| N-QG3 | **Odinštalované a zmazané** položky vyradiť z `kept` pri `sys.watch("apps")`. Súbor alebo priečinok overiť `test -e` pri `fill()`, chýbajúci ukázať stlmený. | `quickgoo.luau:31-46, 96-100` | pred 0.6 |
| N-QG4 | **Prvé spustenie:** namiesto 5 náhodných aplikácií iba naposledy spustené. Pri žiadnych zavibrovať a ukázať bublinu „Pravým klikom na aplikáciu v LensGoo ju pridáš sem“. | `quickgoo.luau:38-41, 61` | pred 0.6, nízka |
| N-QG5 | Poradie ťahaním, skupiny aplikácií (Tvorca Goo, §4.7). | — | po 0.6 (funkcia) |

### Kalkulačka a spoje (`latte-calc`)

| # | Čo | Súbory | Kedy |
|---|---|---|---|
| N-CA1 | **Údaje miest vopred a raz:** `latte-calc fetch` pri inštalácii alebo prvom prihlásení na pozadí. Pri písaní nikdy nesťahovať, iba čítať; bez súboru dať `{}`. Zámok pri sťahovaní (`fcntl` ako `latte-clip`) a `.new` s PID. | `bin/latte-calc:107-135`, inštalátor alebo `latte-session` | pred 0.6 |
| N-CA2 | Opraviť ROADMAP 6B.49 (kontakt už je) a 6B.28 (výška 684). | `ROADMAP.md` | pred 0.6 (dokumentácia) |

---

## Na overenie naživo

Agent nemôže stláčať plochu Goo (bughunt 24. 11.), preto toto overí používateľ. Pri každom bode je, čo urobiť a čo má
nastať.

1. **L1 — Vloženie po nasadení wtype a záplaty:**
   1. Schránka (Win+V v LensShore) → položka → Enter do gedit, foot a Firefoxu.
   2. Emoji → klik.
   3. Odpoveď AI → Enter.
   4. Win+Shift+V trikrát.
   - Potom napísať obyčajné „a“. Ak vznikne Ctrl+A, Ctrl ostal visieť (FP1).
2. **L2 — Vloženie bez wtype** (dočasne premenovať): čo uvidí používateľ? Dnes nič (F1). Po N1 má prísť upozornenie.
3. **L3 — Okno vpredu:** otvoriť LensShore nad oknom Firefoxu. Pätička má ukázať „Vložiť do Firefox“, nie „Kopírovať“ (FP2).
4. **L4 — Win+V vo vzhľade Hravé:** potvrdiť, že sa nestane nič (D2).
5. **L5 — Diakritika:**
   - AppCloud: „subory“ a „kalkulacka“;
   - LensShore Súbory: „ucet“ pri súbore „ÚČET.pdf“;
   - LensGoo Súbory: „c++“ a „(1)“.
6. **L6 — 1024 × 768** (pravidlo 11; `wlr-randr` alebo `pleamar-wm headless`):
   - LensShore 684 px plus doska, páska so 7 režimami (orezanie mien, DP1);
   - mriežka AppCloud (4 stĺpce), 8 záložiek AppCloud;
   - karta LensGoo s 6 dlaždicami v rade.
7. **L7 — Sklo 0:** AppCloud otvorený. Je prekrytie bez skla a mrazu, alebo ostáva mrazené podľa materiálu kvapiek (D10)?
8. **L8 — Veľké rozlíšenie** (2560 × 1600 alebo 4K pri 100 %, `headless`): AppCloud so 150 a viac aplikáciami, rolovať
   na koniec. Sú spodné riadky vykreslené (F15)?
9. **L9 — LensShore › Okná › pravý klik › Rozložiť › Ľavá polovica na pleamar-wm:** robí to niečo (`hyprctl:422`
   `ponytail:` hovorí, že prichytávanie čaká)?
10. **L10 — AppCloud na druhom monitore:** klik na aplikáciu. Kde sa otvorí okno? Pravý klik na dátum nerobí nič (D4).
11. **L11 — AI:**
    - vypnúť AI v Nastaveniach pri otvorenej relácii, potom v LensShore „ahoj“ + Enter (F3: anglická veta);
    - odpojiť sieť a opýtať sa (čo ukáže LensShore, čo LensGoo);
    - zabiť `latte-ai` počas odpovede.
12. **L12 — Ctrl+X a Ctrl+E v poli LensGoo** s napísaným textom: vystrihne a presunie kurzor, alebo nič (DP3)?
13. **L13 — Kontrast:** karta LensShore a doska AppCloud nad svetlou tapetou (DP2). Ikona súboru v QuickGoo na tmavej
    káve (DP4).
14. **L14 — Prvé „time in tokyo“ bez súboru `~/.cache/latteos/places.tsv`,** raz so sieťou a raz bez nej: koľko procesov
    `latte-calc` beží pri písaní (F9).
