prihlasovaci režim. v verzii 0.4 je trošku graficky primitivnejši než povodny. Moja predstava vzhladu prihlaovacieho systemu. - už boot odhali či vykreslovanie bude SW alebo HW. v pripade SW, bude hladina kavy staticka. v pripade HW bude vlniaca sa ako ozajstne more. každopadne hladina samotna je cca v spodnych 2/3 obrazovky. na samom dne možu byt premenlive piesočne tvary- neurčite, ako tiene, kavova sedlina-soc.  mechanika prihlasenia. najprv je z bootovania obrazok šalky, z nej vyskoči guločka-kvapka kavy a dopadne na hladinu. v pripade HW vykreslovania vytvori zvlnenie. nasledne sa vynory, trošku vytiahne vyššie a vyjde z nej lišta kde bude meno a heslo. vedla samostatne sa objavy a roztiahne ine menšie goo do vyberu (latteOs Goo, latteOS safe, SteamOS-pripadne ine predinstalovane GUI). capslock a num lock ak je aktivny sa ukaže ako čisty text vznašajuci sa nad menu kde sa zadava heslo.  dole pod hladinou je posledny log z padu. ak system nespadol. ukazuje sa tam ako je traz, vypis aktualit z vybraneho RSS zdroja. pristup k lokalitam musi byt aj zvnutra systemu. nastavenie zdroja je v settigs. pristup k logu tiež musi byt niekde. aj v safe aj v normal. hore nad hladinou. v lavom rohu je počasie-lokalitu si samozrejme človek voli v nastaveniach. vpravo je čas. kurzor sa spravne chova ako zdroj svetla. ale. tiež zlava doprava ako slnko, vychadza a zapada na pravo. a tiež mesiac. ked vyjde nad obzor, ukaže sa nalavo. presne ako realne v nastavenej lokalite počasia. 
zapojenie 4 režimu okien bude kedy?
powerGoo ked sa otvori. vydim problem. power goo ma na pravom kliku roztiahnutie na kartu s udajmy. ale ked sa vtedy klikne lavym na powerGoo, ucho popup okna je podivne male. a tiež vyditelne. powergooo ostava na lište-rozdielne chovanie než ked nie je zapnuta lišta s udajma. navrhujem. ked je zapnuta lišta s udajma aby sa popup okno vynorilo z celeho komplexu goo + bar. aby vyzualne tvorily jeden kus.
kontextove menu. klikanie na plochu a inde ako v windows 11, v verzii 0.3 to bolo v 0.4 už to zase nie je.
## 5. 11. 2026 — otváranie kariet Goo „sekané“, svetlé štvorce okolo karty (nahlásil používateľ)

Používateľ: karty Goo sa otvárajú sekane, okolo sa ukazujú štvorce; zatváranie LensShore bliká štvorcami; sklenené rámiky ClockGoo
majú „niekoľko obdĺžnikov postupne tmavších v sebe“. **Nespravené, čaká na rozhodnutie.** Čo som zistil (nástroj: `bughunt/zachyt-otvarania-karty.sh`,
~30 snímok za sekundu z `grim`, iba oblasť karty):

- **Je to skutočné v obraze kompozitora**, nie iba v streame: PowerGoo sa pri otváraní ~100 ms ukáže ako svetlý hranatý obdĺžnik širší než karta
  (sklo bez tmavého krytia), vpravo od tmavého obsahu karty je svetlý pás; až potom sa karta ustáli (v pokoji je čistá, tmavá, so zaoblenými rohmi).
- **Neurobila to** moja úprava Kalendára ani AppWindow (iba apps). Scéna karty (`goo/parts/card.plm`) sa pri tom nemenila od 3. 11.
- Skúšané (každé s vlastným pleamarom v kópii `build/alt`, potom zrušené): oslabiť `glass`, `frost`, `smoke`, `tint`, `refraction` a vypnúť `lens` počas rastu
  karty — pás ostal; pleamar **bez celej** záplaty `pleamar-speed-edges-wheel` — dvakrát čisté otváranie, ale Goo potom zaťažuje grafiku ~79 % (so
  záplatou ~6 %); pásy (`body-speed`) iba pre telá ≥ 700 px, bez „prázdnych tvarov“ a bez `sharp-edges` samostatne — pás ostal. Záver: samotná záplata
  ho nevysvetľuje; pozadie je video (Galaxy Eyes.mp4), svetlosť pásu závisí od toho, čo je práve za kartou.
- **Grafika je zaťažená**: `sunshine` (streamovanie hry, v logu relácia od 7:29, HEVC 46 Mb/s) berie 26–45 % grafiky stále, `pleamar-wm` 17–30 %. Ak sleduješ
  plochu cez Moonlight, „obdĺžniky postupne tmavšie“ môžu byť aj pásy kompresie videa (banding) — porovnať so snímkou z `grim`.
- Ďalší krok: porovnať s pôvodným vzhľadom (snímka z čias, keď to bolo v poriadku), vyskúšať bez Sunshine, a vyskúšať pleamar-wm bez blur pod oknami.

**Doplnenie 5. 11. (používateľ):** artefakty sa začali **po prechode z Hyprlandu na pleamar-wm**. Plochu sleduje **stále cez Sunshine/Moonlight**, lebo latte-lab nemá vlastný monitor
(aj za čias Hyprlandu). Sunshine má `capture = kms` (číta DRM roviny priamo), pleamar robí sklo zo snímok kompozitora (`wlr-screencopy`, podľa `--docs reference`), a moje snímky z
`grim` (tiež screencopy) mali svetlý obdĺžnik tiež — takže nie je to len kódovanie videa. Podozrivé: (1) KMS zachytávanie rovín, ktoré pleamar-wm používa (priame zobrazenie / viac rovín,
`pleamar-wm-scanout-layouts.patch`); (2) čas snímky pre sklo (pleamar berie pozadie po prezentovaní a sklo ukáže staré). Skúšky na poobedie: Sunshine s `capture = wlr` namiesto `kms`;
Nastavenia › Sklo vypnúť úplne (kvapky bez skla) a pozrieť, či pás zmizne; pleamar-wm bez záplaty scanout-layouts; návrh autorovi pleamaru do `patches/issues/`.

**Zistené 5. 11. neskôr (hľadanie príčiny, snímky z `zachyt-otvarania-karty.sh`):**
- **Svetlý pás vpravo pri otváraní PowerGoo** = odskok pružiny: telo karty (`card.cw`) na chvíľu presiahne konečnú šírku, ale káva (shader `velvet` v `rows.plm`) bola vždy v konečnej šírke `card.w`, takže vpravo ostala farba panela (pri Sklo 0 plná krémová). **Opravené:** káva sleduje telo (`card.bl`…`card.br`). Moje predošlé hypotézy (záplata `speed-edges-wheel`, sklo, lens, Sunshine) to nevysvetľovali.
- **Sklo 0 nič nemenilo:** v `engine.luau` bolo `fact.panes = 1` bez ohľadu na `glass` (úroveň skla); teraz úroveň 0 vypne sklo kariet aj ich panelov. Pri plne nepriehľadnom paneli (`pane.a` ≥ 0,98) sa karta už neposiela cez sklo a lens (`card.opaque`).
- **ClockGoo pri otváraní zabliká:** karta je krémová, na ~2 snímky (66 ms) celá zpriesvitnie (aj tmavé bloky) a vráti sa. Nie je to sklo ani `reveal`, nenašiel som príčinu (možno súvisí s `fill_calendar` hneď po otvorení). Ostáva.

## 5. 11. 2026 — oprava záznamu (používateľ upravil závery)

- **Sunshine/Moonlight nie je príčina:** používateľ ho používa s rovnakým nastavením už mesiac; artefakty sa začali až po odstránení Hyprlandu tento týždeň. Vyššie napísané hypotézy o Sunshine (`capture = kms`) sa **zrušujú**; podozrenie ostáva pri prechode na pleamar-wm (kompozitor, jeho snímky pre sklo, výstup bez monitora).
- **Vrátené, nepomohlo (používateľ to na obraze nevidel):** úprava vzhľadu skla kariet (`glass`, `lens`, `frost`, `tint`), plne nepriehľadný panel bez skla (z priesvitnej sa stala béžová), káva v šírke tela (`rows.plm`), `panes` podľa úrovne skla (`engine.luau`). Kód je znova v stave z `7ebf61b` okrem farby ucha. Pozor: Nastavenia › Sklo na 0 teda **stále nemení** karty Goo (v `engine.luau` je `fact.panes = 1`), čo ostáva chybou.
- **Pomohlo (používateľ potvrdil):** farba ucha — telo karty je pri kvapke káva a farba panela sa prelieva dnu pri otváraní (`card.plm`: `card.pc`, krátky farebný prechod od ucha).
- **Zatváranie karty (zmerané `pleamar --record card.p`):** `p` 0,95 → −0,40 → +0,16 → −0,06 → +0,03; počas `p > 0,02` sa telo ukáže ako kapsula ~0,15 s, pod ním zmizne — blikanie pri zatváraní. Otváranie: 0,09 → 1,40 → 0,84 → 1,06 → 1,0 za ~1 s (to je žiadaná pružina). Na výber: skryť odraz po zavretí / kritický útlm / odraz presunúť na kvapku.

**Príčina nájdená (5. 11. neskôr, meranie `closetest.sh`: Goo spustené ručne so skriptovanou myšou, oblasť karty `grim` 30 fps; počet snímok, v ktorých sa už zavretá karta ukáže celá znova):**
- bez zmeny: 3, 4, 7, 1 · `PLEAMAR_FULL_REPAINT=1`: 4 · `PLEAMAR_WHOLE_CAPTURE=1`: 1 · `PLEAMAR_FIFO=1`: 0, 3, 1 · **`PLEAMAR_NO_LENS=1` (bez skla): 0, 0, 0**.
- Scéna pritom po zavretí karty hlási skrytú (`card_alive` = 0): staré snímky nie sú zo scény. **Zdroj je sklo (lens), ktoré číta snímky obrazovky** (pleamar berie pozadie pre sklo po prezentovaní, `--docs reference`), a pleamar-wm ich vracia zastarané; za Hyprlandu to bolo inak. Súhlasí to s tým, že artefakty začali po prechode na pleamar-wm.
- **Prečo Sklo 0 nič nezmenilo:** `engine.luau` nastaví `fact.panes = 1` bez ohľadu na úroveň a `lens` v `card.plm` je zapnutý pre `card.pn` aj pri úrovni 0. Oprava: úroveň skla 0 vypne `lens` (a `panes`); ešte nespravená (pokus pred vrátením mal iba `panes`, nie `lens`).
- Test pre používateľa: `~/.config/systemd/user/latte-goo.service.d/test-bez-skla.conf` (`PLEAMAR_NO_LENS=1`).

## 17. 11. 2026 — hľadanie chýb pred inštaláciou na hlavné PC a pred zverejnením (Claude, 6 pomocníkov)

Prečítané a vyskúšané v pieskovisku: inštalácia, štart a SAFE, nástroje `bin/`, Goo (Luau), aplikácie QML, Rust. Testy: `cargo test`
(9 crate), `tests/test_session.sh`, `tests/test_bin.py`, `tests/check.sh` — všetko prešlo; QML aplikácie sa načítali bez chýb.
V gite nie je heslo ani `.claude-local`. Značky: **[x]** opravené a nasadené na latte-lab 17. 11., **[ ]** otvorené.

**Opravené (overené v pieskovisku alebo testom):**
- [x] DualBrew › Rozbaliť prepísal súbor s rovnakým menom a Ctrl+Z ho potom zmazal natrvalo (`latte-files`, overené: PRECIOUS → NEW).
  Teraz do skrytého priečinka a von pod voľným menom.
- [x] Rozdeliť (`split`) prepísal existujúce `SÚBOR.000` → `SÚBOR (2).000`. Odobrať obľúbený priečinok s `.` v mene odobral aj iné.
- [x] Ctrl+Z nevrátil súbor zmazaný na inom disku (kôš `.Trash-UID` na 2 TB disku) — teraz hľadá aj tam.
- [x] Prihlasovacia obrazovka: labwc s predvolenými skratkami → Super+Enter otvoril terminál bez hesla (`system/greeter/labwc/rc.xml`).
- [x] Štart s NVIDIA: `latte-boot` čakal iba na prvú `/dev/dri/card*` (simpledrm) → celá relácia softvérovo. Teraz čaká na skutočný ovládač (do 10 s).
- [x] SAFE › „Skúsiť plnú plochu“ nefungovalo do reštartu (session.env patrí rootovi) → jednorazový príznak `~/.local/state/latteos/try-normal`.
- [x] `install`: zlyhaný krok (`systemctl enable greetd`, SAFE položky…) sa stratil a sprievodca ohlásil „hotovo“ → teraz chyba so zoznamom krokov;
  `semanage` opakovateľné, `snapper` voliteľný (`- ` na začiatku riadku v `[steps]`). Firmvér (`--gpu`) sa odstráni pred zákazom v dnf.
- [x] Goo: `settings.json` sa mohol prepísať takmer prázdnym, keď ho Nastavenia práve zapisovali (`engine.luau`); AppCloud `tabs = 0` (`cloud.luau`);
  minútka a stopky po uspatí meškali o čas spánku (`timers.luau`); ISO týždeň 31. 12. 2024 = 53 (`clockgoo.luau`); posunuté mestá svetového času
  pri neplatnej zóne; −03:30 zle; „UTC+5“ namiesto „UTC+5:30“; „zajtra“ cez +86400 pri zmene času; kalkulačka `-2^2` = 4.

**Otvorené — vysoká priorita:**
- [x] (17. 11.: `folder_of`/`drive_c_path` odmietnu `../`, remove maže overené meno) `latte-barista` (`remove`, `install`): `id` a `folder` z receptu sa nekontrolujú — recept s `../` zmaže priečinok mimo hier (overené pomocníkom).
- [x] (17. 11.: wine pri inštalácii v plote; plot: vlastné /tmp, z /run/user iba Wayland/PipeWire/Pulse, iné disky skryté; Proton cez umu v plote neoverený) `latte-barista` install: `wineboot`, `msiexec` a inštalátor bežia mimo bubblewrap (prístup k celému domovu a k 2 TB disku); `fence` púšťa celé `/run/user/UID`.
- [x] (17. 11.: súhlas v LensAI, `latte-skill allow`) `latte-mcp`: `conversation(s)`, `windows`, `ask` bez súhlasu používateľa — agent s prompt injection prečíta konverzácie a pošle ich inej AI. **Rozhodnúť.**
- [x] (17. 11.: nečitateľné sa preskočí a spočíta v `skipped`, iba jeden disk; ukladanie po dávkach nie) `latte-index`: jeden nečitateľný súbor (práva, `.hidden` mimo UTF-8, súbor sa mení, chýba `file`) zahodí celé indexovanie; prechádza aj cez iné
  disky a sieťové pripojenia bez obmedzenia.
- [x] (17. 11.: po 20 s bez monitora sa pýta jadra — nič pripojené = vypnutý, čaká; pripojený a bez obrazu = SAFE) Žiadny monitor (NVIDIA GBM/modeset zlyhá): `latte-screens --watch` čaká navždy → čierna obrazovka bez SAFE (`latte-session` 162–168).
- [x] (17. 11.: SIGTERM od systemd = odhlásenie/vypnutie, počet pádov sa vynuluje) Reštart do 60 s po prihlásení sa počíta ako pád → po dvoch rýchlych reštartoch (bežné po čistej inštalácii) štart do SAFE.

**Otvorené — stredná:**
- [x] (17. 11.: hypridle a Super+L priamo `latte-lock`: scéna → jej spustenie → zámok Goo; skutočné zamknutie neskúšané) Zamknutie (nečinnosť, uspatie, Super+L) ide iba cez Goo — keď Goo padá alebo sa reštartuje, PC sa uspí nezamknuté.
- [x] (17. 11.: koniec do 5 s = pád; headless s pauzou) pleamar-wm skončí s kódom 0 hneď po štarte → slučka prihlasovania bez SAFE; v `headless` slučka bez pauzy.
- [x] (17. 11.: `--require latte-goo`) Zdravie relácie `--require pleamar` prejde aj vtedy, keď Goo padá (iné scény sa volajú tiež `pleamar`).
- [x] (17. 11.: dočasné meno s PID všade, zámok v latte-clip; overené 3×300 súbežných zápisov bez chyby) Stavové JSON (`latte-clip`, `latte-guardcorgi`, `latte-skill`, `latte-wall`, `latte-cal`) zapisujú cez pevné meno `.new`/`.tmp` → súbežné behy padajú
  alebo zapíšu polovicu (overené: 2 výnimky a 1 poškodené čítanie z 3 súbežných).
- [x] (17. 11.: rad úkonov, chyba v päte) DualBrew: všetky úkony jeden `Process` — nový úkon zabije bežiaci (napr. mazanie 300 súborov v polovici); chyby sa neukážu.
- [x] (17. 11.: zápisy v rade) Kalendár: zápisy zdieľajú jeden proces — nová udalosť bez poznámok/pripomienok, keď medzitým príde iný zápis.
- [x] (17. 11.: po zlyhaní ponúkne Späť) Chapolera: zlyhané `plan-apply` sa tvári ako nespustené a ponúkne Použiť znova (časť súborov už presunutá, bez Späť).
- [x] (17. 11.: Aarambh `uninstall.sh --purge` v [undo]; neskúšané naostro) `install --remove` nevráti ponuku štartu (Aarambh, BootOrder, `latte-bootmenu-safe.service`).
- [x] (17. 11.) `get`: pri opakovanom behu po zlyhanom `dnf` číta starý kód návratu 0; `old-amd.sh`: prerušené sťahovanie sa už nikdy nezopakuje.
- [x] (17. 11.: voľné meno; tabulátor/nový riadok v mene sa do Späť nezapíše) `latte-walls`: tapeta s rovnakým názvom prepíše existujúci súbor. `latte-files`: meno súboru s tabulátorom rozbije záznam Späť.

**Otvorené — nízka (výber):** latte-hw: Surface/„microsoft“ v DMI = VM → softvérové kreslenie; Intel Arc „minimal“; Ice/Jasper Lake chýbajú;
btrfs: varovanie HDD nikdy; `df -B1G` zaokrúhľuje nahor. `latte-ai invite` ostáva bežať po odhlásení (3 procesy). SAFE sa nedá zamknúť.
Budík vynechá, keď Goo stojí práve v tú minútu. `latte-apps` berie `--all` ako balík. lockscreen sťahuje správy každú minútu aj odomknutý.

## 20. 11. 2026 — ArtCraft (WordCraft, PhotoCraft, PdfCraft, ArtCraft Launcher): rozbitý obraz (nahlásil používateľ)

Tá istá chyba ako ROADMAP **1D.49** (flatpak s vlastnou Mesou 26.2 + Wayland v pleamar-wm na RX 640 → rozsypaný obraz). **Obídené
20. 11.** pre všetky štyri aplikácie `ai.storyteller.*`: `flatpak override --user --nosocket=wayland --socket=x11 <id>` (bežia cez
XWayland). Overené snímkou: WordCraft čistý. Daň: kreslia na CPU (llvmpipe), teda pomalšie. Vrátiť: `flatpak override --user --reset <id>`.
Skutočné riešenie ostáva v 1D.49 (lineárne rozloženie pre GFX6–8 v pleamar-wm, alebo Mesa hostiteľa pre flatpaky).

## 21. 11. 2026 — Kôš na ploche otvoril kitty „Open URL error: trash:///“ (nahlásil používateľ)

`latte-desktop open` otváral Kôš cez `gio open trash:///`; na latte-lab nemá `x-scheme-handler/trash` žiadnu aplikáciu, gio
tak siahlo po `kitty-open.desktop`. Oprava: Kôš otvára DualBrew priamo v `~/.local/share/Trash/files` (`latte-app files`), ako
ho DualBrew pozná (Vyprázdniť Kôš). Nasadené.

## 22. 11. 2026 — prvá inštalácia na hlavné PC (Fedora 45 Server, RTX 3060, dva monitory, Secure Boot zapnutý)

- [x] **Pád na 0 % pri Secure Boot + OpenRazer:** `install` volal `dnf()` (kľúč pre DKMS) skôr, než bola funkcia definovaná →
  `UnboundLocalError`. **Opravené** v `6b3c52e` (definícia `dnf()` presunutá nad blok OpenRazer).
- [ ] **Inštalátor roztiahnutý cez oba monitory:** `cage` predvolene spája výstupy. Návrh: v `get` `cage -s -m last` alebo zrkadlenie
  (duplikovať) — používateľ chce duplikovanie.
- [ ] **Návrat v inštalátore:** po chybe sa nedá vrátiť na predošlé kroky (Súčasti…). Má ísť kliknutím na krok vľavo aj šípkami hore/späť.
- [ ] **Konzola (log) inštalátora:** pevná výška 160 px (`apps/installer.qml`, r. 288). Má zaberať premenlivé miesto podľa rozlíšenia — ak to
  rozlíšenie dovolí, až po hladinu kávy.
- [ ] **Farebné riadky v logu** ako pri štarte Fedory: chyby a problémy červené (`error`, `Traceback`, `install: … could not`), varovania
  žlté, OK/hotovo zelené, ostatné bežné.
- [ ] **NumLock vždy zapnutý vopred** (inštalátor, prihlasovanie, relácia).
- [ ] **Jazyk inštalátora** sa má brať z jazyka, ktorý sa nastavil v inštalátore Fedory (`/etc/locale.conf`, `LANG`). Preklad zatiaľ iba sk;
  ostatné jazyky predvolene angličtina.
- [ ] **Zamrznutie počas buildu pleamar/pleamar-wm** (pri `Compiling wayland-protocols`, 29 %): kurzor nereagoval. Podozrenie: `cargo` berie
  všetky jadrá s bežnou prioritou a okno inštalátora (cage + pohyblivá káva) nedostane čas. Návrh: build cez `nice -n 10` (a `ionice`),
  prípadne `-j` = jadrá − 2; počas buildu stíšiť animáciu kávy.
- [x] **Zamrznutie okna počas buildu:** `install` teraz spúšťa build cez `nice -n 19` + `ionice` a s `CARGO_BUILD_JOBS` = jadrá − 2 (min. 1).
- [ ] **Návrh (používateľ 22. 11.):** v ľavom menu inštalátora ukazovateľ aktuálneho zaťaženia (CPU, RAM, GPU, teplota) ako v LatteMonitor/PowerGoo strip.

### 22. 11. 2026 — prvá živá relácia na hlavnom PC (dva monitory, RTX 3060)
- Nastavenia ťahajú iba `hyprctl eval latte.screen(…)` → náhrada `system/pleamarwm/bin/hyprctl` → `pleamar-wm output NAME at X,Y`. V ROADMAP 1D.xx je to „ostáva overiť v ostrej relácii s dvoma monitormi“. Používateľ: pegboard nejde prehodiť (nová chyba/neoverené).
- Tapeta sa nezobrazuje (skontrolovať `latte-wall`, `journalctl --user -b | grep -i wall`).
- Nastavenia sa pri niektorých kliknutiach zavrú (treba stderr: `latte-app settings 2>&1 | tee /tmp/settings.log`).
- `latte-app` musí používať `/usr/lib64/latteos/qs-web` (Fedorin `qs` nepozná `pragma AppId`) — opravené c3cd94d.
- `latte-settings` bez argumentov má otvoriť GUI.
- Goo panel je iba na hlavnom monitore, ľavý nemá nič (latte-goo-side@NAME sa nespustil?).
- Oznam o softvérovom renderi pri SAFE relácii.
- `~/.config/latteos` patrilo rootovi (kroky inštalácie bežia ako root s HOME používateľa) → latte-wall `PermissionError` (tapeta sa neuloží/nezobrazí), Nastavenia nemôžu zapisovať (pády), `monitors` sa neuloží. Oprava: `install` po krokoch vráti vlastníctvo (chown) priečinkov LatteOS v domovskom adresári. Ručne: `sudo chown -R $USER: ~/.config/latteos`.
- `journalctl` na Fedora Server nie je v PATH používateľa v relácii? (bash: jornalctl1 bola preklep používateľa, nie chyba).
