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
