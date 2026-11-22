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
- Presnejšie: root-ový krok vytvoril aj samotný `~/.config` (používateľ sa ešte nikdy nepríhlásil), takže `latteos` v ňom nešlo vytvoriť. `install` teraz po krokoch vráti root-ovým `~/.config`, `~/.local`, `~/.local/share`, `~/.local/state`, `~/.cache` používateľa (len ich samých) a rekurzívne priečinky LatteOS.
- [ ] **Monitor nezobrazuje GPU (22. 11.):** hlavný PC má GeForce RTX 3060 (ovládač `nvidia`). `crates/latte-stats/src/main.rs` `gpu()` číta iba `gpu_busy_percent` /
  `mem_info_vram_*` zo sysfs, ktoré dáva len `amdgpu` → polia `gpu`/`vram`/`gpu_temp` sa vynechajú a dlaždica Graphics v `apps/monitor.qml` (r. 186, `visible: now.gpu !== undefined`) sa skryje.
  `nvidia-smi` ani `libnvidia-ml` na systéme nie sú. Návrh: pre NVIDIA zbierať z `nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu`
  (alebo NVML), inštalátor má zabezpečiť `xorg-x11-drv-nvidia-cuda`; bez nástroja dlaždicu ďalej skryť. Rovnaké pre `bin/latte-monitor` (sekcia graphics) a návrh ukazovateľa zaťaženia v inštalátore.

### 22. 11. 2026 (večer) — DockShore, druhý monitor, agentgram, ToolHive
- **DockShore dvojitý (ráno/poobede):** na DP-1 bola doska docku vidieť ako dva tvary cez seba (svetlejší s obrysom + tmavohnedý s vlastnými rohmi o ~30 px nižšie; zmizli spolu pri vypnutí vrstvy `goo.plm` top, teda oba kreslí Goo). Po neskoršej kontrole používateľ píše, že sa to **samo upravilo** (príčina neznáma). Podozrenie používateľa: väčšina chýb tejto relácie bola z **nesprávnych práv zápisu po inštalácii** (vlastníctvo `~/.config/latteos` a pod., opravené 012769da4 / 9805e55a2). Monitory sa už podarilo prehodiť.
- [ ] **Druhý monitor (HDMI-A-1): prázdne miesta.** Kde má byť AppCloud je prázdne miesto a je tam aj **prázdny tvar** na mieste druhého DockShore (každý monitor má mať vlastný DockShore). Overiť `side.plm` (vrstvy 11/13 na monitore 1), `Plates` (dock/cloud boxy na side scéne) a `session.plm` `dockshore` pre `s != 0`.
- [ ] **Agentgram nefunguje.** Nerobí sa dnes; pozri `latte-mcp`/agentgram službu, `systemctl --user status`, `journalctl --user -b`.
- [ ] **ToolHive (`thv`) nefunguje.** Súvisí s agentgramom (skupiny MCP = konektory agentgramu cez `latte-mcp /mcp/SKUPINA`). Nerobí sa dnes.
- Nástroje pre pozeranie plochy z Claude Code: `~/.claude.json` má `pleamar-desktop` cez `flatpak-spawn --host pleamar-wm agent mcp` (záloha `~/.claude.json.bak-pleamar`); `~/.config/pleamar/session.conf` = `agent on`.
- [ ] **Ponuka štartu (aarambh): Windows 11 má kávovú šálku** (používateľ 22. 11., po prvom štarte): dlaždica/pozadie Windows má byť **logo Windows 11**, nie naša šálka (`patches/aarambh/make-assets.py` r. 76–77, ROADMAP 3.11).
- [x] **Po reštarte rovnaká tapeta na oboch monitoroch (22. 11.):** `background.json` bol správny (DP-1 video, HDMI-A-1 obrázok), ale `bin/latte-wall` `draw()` dával `-o MONITOR` swaybg **za** `-i` a `-m`. Podľa manuálu swaybg sa prepínače bez `-o` pred nimi týkajú všetkých výstupov, takže obrázok pre HDMI-A-1 sa kreslil na oboch a ako novší prekryl video mpvpaper na DP-1 (po reštarte vznikne swaybg po mpvpaperi; predtým to bolo naopak). **Opravené v kóde** (`-o` prvé); nasadí sa pri ďalšej inštalácii (`/usr/share/latteos` som neupravoval). Na živej ploche som opravil iba bežiaci swaybg (`swaybg -o HDMI-A-1 -i … -m fill`, `WAYLAND_DISPLAY=pleamar-1`). Neoverené: test pre `draw()` neexistuje (v `tests/` nie je swaybg).

### 22. 11. 2026 (noc) — reinštalácia od čistej Fedory (nástroj na testovanie inštalátora)
- **Nový nástroj `tools/latte-reset` + `tools/latte-reset-first`** (nie sú vo FILES, nie sú súčasť inštalácie): vráti `/` zo snímky `root-pred-lateos` (Fedora 45 po aktualizácii, 22. 11. 2026 12:14:46, overené `btrfs subvolume show`), starý koreň nechá ako `root-lateos-old-DATUM`, mimo koreňa upratá aarambh (EFI záznam, priečinok v ESP a kľúč jeho `uninstall.sh --purge`), `*-lattesafe*.conf` v `/boot/loader/entries` a blok nouveau z príkazového riadku jadra, prenesie vybrané veci domova a `/etc/pki/akmods` (rovnaký kľúč MOK, nové heslo netreba) cez reflink, dá zdroj do `/opt/latteos/src` a jednorazovú službu, ktorá po reštarte spustí inštaláciu (gui = `get`, console = `./install --go`). **Suchý chod je predvolený**, skutočná výmena iba s `sudo … --go` a napísaním RESET.
- **Overené:** syntax, suchý chod bez root na hostiteľovi (kontroly a kroky 2–4 sa vypíšu). **Neoverené (zistí až prvý skutočný beh):** premenovanie bežiaceho `root`, `dracut` v chroote, prvý štart po výmene (sieť, `get` ako služba bez kmscon), opätovná inštalácia aarambh, SELinux štítky po `cp -a`.
- Aarambh **nie je celý v koreni**: jeho zavádzač je v ESP (`/boot/efi/EFI/aarambh`) a záznam `Boot0005` vo firmvéri; v koreni sú len háky (`/etc/kernel/install.d`, `/usr/local`, `/var/lib/aarambh`). Preto ho `latte-reset` pred výmenou odinštaluje.
- Chyba, ktorú som si zapísal omylom ako otvorenú: závislosti ponuky štartu (`gnu-efi-devel` atď.) **inštalátor má** (FILES r. 413 `optional:`); padlo to preto, že `setup-latteos.sh` bol spustený priamo, nie cez `install --go --with`. Nie je to chyba inštalátora.
- **Spresnenie po rozhovore (22. 11. noc):** `tools/latte-reset` **predvolene mení iba `/`** (EFI, `/boot`, aarambh ostávajú). Upratanie mimo koreňa je voliteľné `--clean-boot`, prebudovanie initramfs `--initramfs`. Test, či aarambh znesie opätovnú inštaláciu cez existujúci `EFI/aarambh`, je jedným z cieľov prvého skutočného behu. Kľúč `/etc/pki/akmods` sa prenáša, takže už podpísaný `aarambh.efi` ostáva platný.
- [x] **Práva v domove po inštalácii (opravené všeobecne, 22. 11.):** predošlá oprava (012769da4, 9805e55a2) vracala používateľovi len pevný zoznam priečinkov, ale root-ové kroky bežia s `HOME` používateľa, takže zoznam by bol vždy neúplný (napr. `~/.config/pleamar`). `install` teraz po krokoch prejde celý domov každého používateľa (`give_back_home`: nenasleduje odkazy, neopúšťa súborový systém) a vráti každú vec vlastnenú rootom; priečinky LatteOS sa menia celé ako predtým. **Neoverené na čistej inštalácii** (root-ové súbory sa tu vytvoriť nedajú); funkcia sa spustila na dočasnom priečinku bez chyby.
- **Agentgram a ToolHive nefungujú — príčina nájdená (22. 11. noc), nie je to chyba za behu, ale chýbajúca inštalácia:** oba boli na latte-lab nainštalované ručne a inštalátor ich nikdy neposkytol. Na tomto PC chýba: `thv` (ToolHive; `~/.local/bin` neexistuje), `~/.toolhive`, `~/.local/share/latteos/toolhive-registry`, `podman.socket` je neaktívny, `bun` nie je (ani `~/.bun`), zdroj agentgramu `~/src/agentes-chat` (vetva `agent-chats` nášho repozitára; `bun install` ~2,2 GB), jednotka `agentgram.service` ani `agentgram-runner`; nič nepočúva na 5173. `latte-ai agentgram` hlási `on: true, mode: local, paired: false`, takže LensAI čaká na server, ktorý nikdy nevznikol. `latte-mcp.service` tiež nebeží. V FILES je z celej oblasti iba `latte-mcp`, `latte-toolhive-catalog` (+ timer) a `registry.yaml`. ROADMAP 10B.86 to priznáva: „Ďalej: ToolHive a PostgreSQL do inštalátora LatteOS“. **Úloha:** súčasť inštalátora „Agentgram a ToolHive“ (voliteľná, AI nie je vypnutá): pinnuté verzie so súčtami (thv 0.67.0, Registry Server 1.5.4, ToolHive Studio 0.41.0 .rpm), podman, bun, zdroj agentgramu a jeho zostavenie, jednotky pre používateľa, zapnutie `latte-mcp`. Najprv ručne na tomto PC, kroky zapísať, až potom skript.
- [~] **Agentgram: doinštalovaný na tomto PC a zabudovaný do inštalátora (22. 11. noc).** Beží (`agentgram.service`, 127.0.0.1:5173, health ok, `TELEMETRY=off`), `latte-ai agentgram` ho vidí. Inštalátor: `patches/ai-stack.sh`, súčasť `postgresql-server` vo FILES (iba s AI), krok „Agentgram and ToolHive“. **ToolHive ostáva na root:** `sudo dnf install ~/.cache/latteos/downloads/ToolHive-0.41.0-1.x86_64.rpm postgresql-server`, potom raz otvoriť ToolHive Studio (vytvorí `~/.toolhive/bin/thv`) a spustiť `latte-toolhive-catalog`; `thv-registry-api` 1.5.4, `bun` 1.4.5 a `podman.socket` sú už nainštalované. Neoverený beh cez `install` ako root.
