Podklady: 

 docs/NAVRH-STARTU.md: rámec, režimy a štart systému (r. 14–164), doslovne.

 docs/OPTIMALIZACIA.md: pravidlá a merania zo sekcie O (r. 912–945), doslovne.

 docs/ARCHITECTURE.md: v časti „Ďalej“ sú odkazy na NAVRH-STARTU a OPTIMALIZACIA.

 inspo/LatteOS – technologický radar 2026.md : zdroj odkial čerpat a kam zapisovat najnovšie vyhladane zaujimavosti použitelne pre LatteOS.

 inspo/dalsie_inspiracie.md : ručne editovany subor kam vkladam ked najdem niečo zaujimave.


## Teraz — poradie práce

Schválené 12. 10. 2026. Pracuje sa **zhora nadol, neskáče sa**; nový nápad ide na koniec tohto zoznamu. Pri práci sa
číta iba táto sekcia, zvyšok roadmapy sa hľadá podľa prúdu (R2, R3·A…). Stav testov: `python3 bughunt/stav.py`.

1. [~] **Štart (R2).** Opravené a overené reštartom 12. 10.: čakanie na sieť (prihlasovanie 99 s → 36 s, celý štart
   3 min 37 s → 1 min 12 s), rohová lišta po prihlásení (+8 s, sama), žiadna zlyhaná služba. Test grafiky pri
   studenom štarte vyprší zámerne (pomalý disk, rozhodne ovládač) a prihlasovanie nezdržuje — nie je chyba; zvyšných
   ~25 s je disk a `gssproxy`. Pád Hyprlandu pri konci relácie `latte-session` rozpozná; pri reštarte 12. 10. nenastal.
   Overené pádmi 12. 10.: engine sa po páde sám obnoví (doplnené), Hyprland sa po páde spustí znova, druhý pád
   do 60 s prepne do SAFE, SAFE zvolený aj automatický funguje a čisto končí.
   **Ostáva:** klik na Reštartovať · Vypnúť v PowerGoo (test 036), zlé heslo a jazyk na prihlásení (541), prečo
   núdzové rozhranie po páde berie ~2 jadrá (010), okná sa po páde kompozitora nevrátia (006), testy 003–005, 007–008.
   *Hotovo, keď:* testy 001–012, 036, 541, 550 majú stav. Po každom štarte: `old/setup/test/start.sh` (predošlý: `-1`).
2. [~] **v0.4 Fresh — čistý strom** (schválené 12. 10.; vetva `v0.4-fresh`, predloha pod značkou `v0.3-archive`).
   Nahrádza body „Upratanie Classicu“, „Premenovanie kvapiek“ a „Čistá inštalácia verejného stromu“. Cieľ: čistá
   Fedora → prihlasovanie Goo + dve relácie, **LatteOS SAFE** (samostatné GUI) a **LatteOS GOO** (engine Goo so všetkými
   kvapkami), k nim zatiaľ ostáva herná relácia **LatteOS Game** (Steam + gamescope; rozhodnuté 12. 10.), bez Noctalie a bez zrušených vecí. Pravidlá pre každý kus, ktorý do Fresh vstúpi: kód, mená príkazov,
   súborov a komentáre po anglicky (komentár iba „prečo“, bez odkazov na staré verzie); text na obrazovke iba cez
   preklady (scény: vstavané `translations` pleamaru 0.3 s faktom `locale`, prepnutie za behu, logika `tr()`; aplikácie
   QML `i18n.tr()`); žiadny kus nemenuje inú aplikáciu priamo (kto čo otvára, vie jedno miesto); scény podľa skillu
   `pleamar` (logika nekreslí a nepozná súradnice), po každej úprave `pleamar --check`. Strata funkcie je prípustná,
   obnoví sa testovaním; zmazané sa vytiahne cez `git show v0.3-archive:cesta`.
   - a. [x] značka `v0.3-archive`, vetva `v0.4-fresh` (12. 10.).
   - b. [x] **Starý kód do `old/`** (12. 10.): celý strom v0.3 (`session`, `setup`, `crates`, `resources`, `Cargo.*`,
     `docs_zaloha`) je v `old/` bez zmeny obsahu a dá sa z neho ďalej inštalovať (`old/setup/f1/install-session.sh`) —
     na latte-lab ostáva starý LatteOS na porovnanie. Pôvodný `old/` (Classic v GTK) je zmazaný, ostáva pod značkou.
     V koreni ostáva: `docs`, `bughunt`, `inspo`, `ROADMAP.md`, `LATTEOS-GOO.md`, `README.md`, `ZMENY.md`,
     `TRETIE-STRANY.md`, `LICENSE`, `CLAUDE.md`. `old/` je predloha: nemení sa a do Fresh sa z neho nekopíruje, píše sa
     podľa neho nanovo.
   - c. [x] **pleamar 0.3.2** (12. 10.): záplaty prenesené a uložené v `patches/` (päť súborov podľa témy, každý sedí
     na čistý `v0.3.2` samostatne; popis v `patches/README.md`). Farby 8 bitov má už autor sám, tá časť odpadla.
     Preložené v `~/src/pleamar-0.3.2`, nainštalované ako `/usr/bin/pleamar` (jazyk 0.4); pôvodný je
     `/usr/bin/pleamar-0.2.29`. Overené: nové aj staré scény prejdú `--check`, nové prihlásenie aj starý engine sa
     na neviditeľnej obrazovke kreslia rovnako ako na 0.2.29 (rozdiel do 9 z 255). **Neoverené:** starý engine
     v skutočnej relácii Hyprlandu na novom pleamare (záťaž, sklo, zoznam okien).
   - d. [~] **Písať načisto, po kusoch** — so skillom `pleamar`, podľa `old/`, ale lepšie. Poradie (používateľ 12. 10.):
     1. [x] **štart po prihlásenie** (12. 10.): `crates/latte-hw`, `crates/latte-boot`, `system/` (služba, greetd, labwc
        prihlasovača, položky SAFE v GRUB-e, Plymouth), `bin/latte-greeter`, `bin/latte-login`, `bin/latte-sky`,
        `goo/login.plm` + `login.luau`, preklady `goo/lang/sk.plm`, vlastné písmo ikon. Oproti starému: úvod riadi
        scéna (logika iba povie „začni“), heslo ide na vstup príkazu (nie cez súbor), čas zo služby `clock`, rozloženie
        klávesnice zo systému, bez Noctalie. Odpadlo: prihlasovač v QML a Noctalie (bez grafickej karty je zatiaľ
        textové prihlásenie `tuigreet`), `vm-3d`, zápis `hyprland.conf`. Overené: `tests/check.sh`, scéna na
        neviditeľnej obrazovke (snímky, záznam priebehu, zlé a dobré heslo naskúšku). **Neoverené:** skutočné
        prihlásenie cez greetd — až po nasadení na latte-lab.
     2. [x] **SAFE a relácie** (12. 10.): `goo/safe.plm` + `safe.luau` (lišta: záťaž, ponuka napájania, terminál, riadok
        na písanie s režimami aplikácie a príkaz, okná, sieť, batéria; pozadie s časom), `bin/latte-safe` (záchranná
        ponuka; texty z toho istého `goo/lang/sk.plm`), `bin/latte-session` (GOO · SAFE · Game, strážca pádov),
        `bin/latte-game`, `crates/latte-stats`, labwc pre SAFE, tri položky relácií, statické prihlásenie
        `goo/login-safe.plm` pre softvérové kreslenie (VM, SAFE) so spoločnou logikou `goo/lib/login.luau`.
        Overené: `tests/check.sh` (aj strážca relácie s napodobenými programami), snímky na neviditeľnej obrazovke.
        **Zatiaľ chýba** (vráti sa s príslušným programom): zámok obrazovky, hľadanie súborov a AI v riadku, tlačidlá
        App Manager a Správca zariadení, profily prostredí (`latte-profil`), profil účtu (`latte-gooconfig`).
        Voľba GOO pri prihlásení skončí v SAFE s dôvodom „plná plocha nie je nainštalovaná“, kým nie je bod 3.
     3. [~] **GooEngine** — engine a jadro kvapiek, potom náhrada Noctalie (rohová lišta: tray, sieť, hlasitosť,
        ovládacie centrum; Nerušiť, akcie relácie, prehľad okien, účty kalendára — služby pleamaru `tray`, `network`,
        `audio`, `bluetooth`, `brightness`, `session`, `polkit` a stránky z Marey, BSD-3), aplikácie a príkazy, iba tie,
        ktoré GOO a SAFE potrebujú. Platí z 12. 10.: znak NET do GOO, náhľad okna nad ikrou, Kapsa a maskoti sa
        neprenášajú; kvapky sa premenovali (GooBar → BarGoo, GooPower → PowerGoo).
        - [x] **engine** (12. 10.): `goo/goo.plm` + `goo/parts/`, `goo/gen.py` (tvary tela — jazyk 0.4 cyklus v tele
          stále nevie), `goo/lib/engine.luau`, karta `goo/lib/card.luau`. Oproti starému: karta sa skladá rozložením
          scény, signály idú cez záznam kvapky, stav a nastavenia sú v priečinku scény, jedna scéna s 32 miestami.
        - [x] **Hyprland pre GOO** (12. 10.): `system/hypr/` (režimy okien, minimalizovanie, rozloženia, plochy, skratky
          ako vo Windows, stupne výkonu), `system/systemd/latte-goo.service`.
        - [x] **jadro kvapiek, prvá časť** (12. 10.): BarGoo (hlava, ikry okien, ponuka okna), LensGoo (Aplikácie,
          Príkaz, rýchly zoznam), PowerGoo (karta: účet, odhlásenie, batéria, profil napájania, uspať · reštartovať ·
          vypnúť). Čo je a čo chýba: LATTEOS-GOO.md §8.
        - [x] pás výkonu PowerGoo (12. 10.; `latte-stats` hlási aj teplotu procesora a karty).
        - [x] zámok obrazovky (12. 10.): Win+L a PowerGoo › Zamknúť; overené zlé aj dobré heslo a zamknutie po páde
          scény. Pri nečinnosti (13. 10., hypridle, `system/hypr/hypridle.conf`): zamknutie po 10 min, zhasnutie
          obrazoviek po 15 min, zamknutie pred uspaním; okno na celú obrazovku tomu bráni. Samo sa
          neuspáva. Časy sa menia v Nastaveniach › Uzamknutie a nečinnosť (`~/.config/latteos/idle`).
        - [x] ovládanie Goo z klávesnice (12. 10., Win+T).
        - [x] pád minimalizovaného okna do lišty, kvapka uhne titulku okna (12. 10.).
        - [x] viac monitorov, prvá časť (12. 10.): scéna je iba na hlavnom monitore (Hyprland jej povie ktorý,
          pri zmene monitorov ju presunie), okná z iných monitorov sú v lište, ale neuhýba sa im.
        - [x] BarGoo na ďalších monitoroch (13. 10.): vlastná scéna `goo/side.plm` na každom ďalšom monitore
          (`latte-goo-side@.service`), lišta ukazuje iba okná svojho monitora, pás pri okraji má každý monitor
          svoj; `latte-say` povie niečo všetkým scénam Goo. Overené s dvoma a troma monitormi bez obrazovky.
          Chýba prenášanie ikier medzi monitormi; každá ďalšia scéna stojí toľko čo hlavná (bod 5).
        - [ ] **jadro kvapiek, zvyšok:** okno z bubliny príde s QueenGoo (rodia sa z nej riadne okná).
        - [x] ClockGoo (12. 10.): upozornenia (pleamar je server upozornení) a kalendár, karta času so stopkami,
          minútkou, budíkmi a počasím; karta vie dva stĺpce a mesiac.
        - [x] náhrada rohovej lišty (13. 10.): **Pobrežie** — tvrdý roh vpravo dole s programami na pozadí, sieťou,
          hlasitosťou a batériou; šípka vysunie panel po horný okraj (rýchle nastavenia, schránka cez `cliphist`);
          kvapky sa k nemu nelepia a odrazia sa. Okno s heslom pre polkit (12. 10.).
        - [x] **QuickGoo** = rýchle spúšťanie (13. 10.): páska s ikonami aplikácií poruke.
        - [x] vlastné kvapky (13. 10.): `goo/lib/own.luau`, zoznam `drops.json` v priečinku scény — aplikácia
          alebo ikona s príkazmi a textom z príkazu; LensGoo › pravý klik na aplikáciu › Pripnúť ako kvapku, pravý
          klik na kvapku › Odstrániť. Tvorca Goo (formulár v Nastaveniach) príde s aplikáciou Nastavenia.
        - [x] hra pri nečinnosti (13. 10.): po 6 min sa hravé kvapky (`"nature": "playful"`) hrajú — výskok,
          plíženie, veľký oblúk, naháňačka; skok je hod s gravitáciou scény, po prebudení je všetko na mieste.
        - [x] MediaGoo (13. 10.): čo hrá, predošlá · pauza · ďalšia, hlasitosť; je na ploche, iba kým beží prehrávač.
        - [x] prepojené kalendáre (13. 10.): adresy .ics v karte ClockGoo, číta `bin/latte-cal` (opakované udalosti,
          časové pásma); iba na čítanie, bez účtov. **ChatGoo** čaká na Beeper
          (na latte-lab nie je nainštalovaný, nedá sa overiť).
        - [x] **App Manager** (13. 10., na pokyn mimo poradia): `apps/appmanager.qml` + `bin/latte-apps` + `bin/latte-app`;
          obchod Flathub (bannery, police, kategórie, hľadanie, stránka aplikácie), moje aplikácie, aktualizácie,
          miesto pre Baristu. Inštalácia a odstránenie overené naostro. Chýba: LATTEOS-GOO.md §6.3.
        - [x] **QueenGoo** (13. 10.): korunka, guľky (zariadenie, sieť, aktualizácie), ľavý klik = App Manager,
          pravý = Správca zariadení. Okno z bubliny neskôr.
        - [x] **Správca zariadení** (13. 10.): `apps/devices.qml` + `bin/latte-devices` — prehľad počítača, skupiny
          zariadení, ovládač a stav každého, správa na skopírovanie. Iba číta; čo chýba oproti v0.3: LATTEOS-GOO.md §4.4.
        - [x] **Okno aplikácií LatteOS** (rozhodnuté 13. 10. podľa používateľovho V2 a ForkLiftu): `apps/common/AppWindow.qml`
          — bočný panel zo skla od vrchu po spodok, hore lišta s funkciami (šípky, názov, nástroje aplikácie, hľadanie),
          úplne vpravo okenné tlačidlá; kávová hladina je rozhraním k spodnej časti okna, alebo iba tichým pozadím.
          App Manager je v ňom ako streamovacie menu (banner s ďalším nakúkajúcim, rad volieb, plagáty).
        - [ ] **NET v hlavičke okna** — odstaviť aplikáciu od internetu hneď (služba s právami správcu a nftables ako
          v0.3 `latte-net`/`latte-netd`); miesto v hlavičke je, tlačidlo sa ukáže, až bude mať čo robiť.
        - [ ] **Prechody bannerov** v App Manageri v duchu skwd-wall (používateľ, 13. 10.). skwd-wall je Rust a Vulkan
          pod GPL-3.0, jeho shadery sa do okna v QML nedajú vložiť; podobné prechody treba napísať vlastné
          (QML `ShaderEffect`, `qsb` je v systéme). Dnes sa bannery posúvajú.
        - **Poradie od používateľa z rána 13. 10.** (ide sa zhora, Barista zatiaľ stojí):
          1. [x] okná ako vo Windows (13. 10.): od okrajov sa mení veľkosť (Hyprland), kúsok za okrajom v prázdne
             (do 36 px) sa okno ťahá celé (plugin `latte-events`), a pustené okno sa vráti tak, aby jeho vrch
             s hlavičkou ostal na obrazovke a dalo sa chytiť. Platí pre plávajúce okná.
          2. [x] **Monitor** (13. 10.): `apps/monitor.qml` + `bin/latte-monitor` (a `latte-stats`). Prehľad (procesor
             s jadrami, pamäť, grafika, sieť a disky — živé obrázky poslednej minúty, najnáročnejšie programy),
             Procesy (aplikácie s oknom, potom pozadie; hľadanie, zoradenie, Ukončiť), Po štarte (čo sa spúšťa samo:
             čo to je, odkiaľ je, koľko pridalo k štartu; vlastné veci sa dajú vypnúť a zasa zapnúť — návrh podľa
             BetterWindowsServices), Senzory. PowerGoo › Monitor, Ctrl+Shift+Esc. Oproti v0.3 chýba: všetky služby
             so štartom a zastavením, detail procesu (priorita, pauza, súbory, spojenia), hardvér ako CPU-Z, test
             výkonu, Digitálna pohoda, strom disku, dlhodobá telemetria („kto žerie“ po dňoch).
          3. [x] Správca zariadení má dve časti (13. 10.): **Zariadenia** a **Sieť** — Pripojenie (adresa, router,
             DNS, rýchlosť, zapamätané pripojenia) a **Inšpektor siete** (`bin/latte-network`): polkruhový radar,
             dole tento počítač nad routerom, na vnútornom oblúku zariadenia pripojené teraz, na vonkajšom videné
             predtým; nové zariadenie zlato; zariadeniu sa dá dať meno a druh, alebo ho zabudnúť. Inteligentná
             domácnosť sa pozná pasívne z ohlásení Matter a Thread. Chýba: zoznam namiesto radaru, „Moja sieť“
             a upozornenie na nové zariadenie, pripájanie a VPN (to prvé je v paneli Pobrežia), AirPlay.
          4. [~] **Nastavenia** (13. 10.): `apps/settings.qml`, zoznam stránok `apps/settings/pages.json`, Win+I.
             Rozkladací bočný panel po oblastiach (Softvér · Dáta · Hardvér · Účet · Prostredie · Systém, 29 stránok)
             s bodkou stavu; hľadanie v hlavičke; **LensGoo hľadá aj v nastaveniach** (pod čiarou, `bin/latte-settings`).
             Hotové stránky: **Káva a šálka** (druh kávy = farba goo; šálka = z čoho sú okná: espresso, mokka,
             porcelán — svetlá; sklenená káva), **Pozadie** (obrázky LatteOS a z priečinka Obrázky; živé pozadia
             = filmy z priečinka Videá cez mpvpaper), **Okná** (režim; sklo bočných panelov), **Kvapky**, **O počítači**,
             **Uzamknutie a nečinnosť** (kedy sa zamkne a kedy zhasnú obrazovky), **Napájanie** (profil).
             Ostatných 22 stránok je vypísaných ako „ešte nie je“ s odkazom, kde sa to robí zatiaľ. Chýba: šálka
             v kartách Goo a v okrajoch Hyprlandu, výber vlastného súboru tapety, všetky stránky Hardvér/Účet/Systém.
        - [ ] **Barista** v App Manageri (stránka je pripravená, sprievodca podľa `docs/barista/NAVRH.md` nie).
        - [x] tapeta (swaybg, `assets/wallpapers`) a okenné tlačidlá (hyprbars so záplatou `patches/hyprbars-latte.patch`;
          postup v `patches/README.md`) (12. 10.).
        - [x] LensGoo: režimy Súbory a Web, kalkulačka (12. 10.).
        - [x] nastavenia Goo ako karta (12. 10.): kvapky, materiál, živé správanie, káva, tapeta, režim okien.
        - [x] režim AI v LensGoo (13. 10.): `bin/latte-ai` (zatiaľ iba Claude cez `claude -p`), rozhovor v karte, Win+C.
        - [x] prichytenie ťahaním (13. 10.): plugin `plugins/latte-events` (udalosť „okno pustené“) a zóny
          v `system/hypr/latte/windows.lua`; skúša sa myšou kompozitora `tests/pointer.py`.
        - [x] BarGoo: ikry iba v režime plávajúce (rozhodnuté a urobené 13. 10.) — v páske a dlaždiciach počet okien
          na hlave, ikry po postáti myši na hlave. Zvuk a žiadosť o pozornosť ukazuje okno samo pulzujúcim
          okrajom; hlava sa vlní iba za okno, ktoré nie je na očiach.
        - [x] sklo okien (13. 10.): plugin Hyprglass, zapína sa s materiálom Sklenená káva (`system/hypr/latte/glass.lua`).
        Overené 12. 10. v `tests/screen.sh` (Hyprland bez obrazovky na RX 640, snímky, falošná myš): štart, pokoj
        a nadnesenie, ťahanie k okraju a pád, karty všetkých troch kvapiek, spustenie aplikácie, príkaz s varovaním,
        prepnutie režimu okien, minimalizovanie klikom na ikru, ponuka okna, odhlásenie s otázkou, lišta pri ľavom
        okraji s pásom, sklenená káva a zmena nastavení za behu. Záťaž v pokoji: scéna 17 % jadra, Hyprland 4 %.
        Overené 13. 10. tým istým spôsobom: nečinnosť (skrátené časy), dva a tri monitory, vlastné kvapky a ich hra,
        MediaGoo s napodobeným prehrávačom, kalendár zo súboru .ics, odpoveď AI od Clauda, prichytenie ťahaním
        (myš kompozitora `tests/pointer.py`), sklo okien. **Neoverené z 13. 10.:** jednotky systemd
        (`latte-idle`, `latte-goo-side@`) v skutočnej relácii, zamknutie pred uspaním, skutočný prehrávač, kalendár
        z internetu, ťahanie okna za titulok skutočnou myšou.
        **Neoverené:** skutočné prihlásenie (greetd → `latte-session` → Hyprland na obrazovke) — až po nasadení na
        latte-lab (bod f); batéria (latte-lab ju nemá); viac monitorov; uspanie, reštart a vypnutie (v skúške sa
        nestláčali naostro).
   - e. [~] **Zoznam súborov (`FILES`)** od prvého kusu (založený 12. 10., stráži ho `tests/check.sh`): každý súbor, ktorý LatteOS pridá do systému, má riadok
     „cieľ v systéme ← zdroj v repe“. Inštalátor aj odinštalovanie sa neskôr napíšu nad týmto zoznamom; dovtedy
     sa podľa neho inštaluje ručne. Čo LatteOS v systéme mení (nie pridáva — `/etc/os-release`, greetd), má vlastný oddiel.
   - f. [ ] **Inštalátor a odinštalovanie** (neskôr): výmena na latte-lab bez preinštalovania Fedory (snímka snapper
     pred ňou, nastavenia používateľa do zálohy) a čistá Fedora vo VM s voliteľným vzdialeným prístupom
     (dnes `old/setup/lab/vzdialene.sh`). Až tu sa dokončia zvyšné testy bodu 1.
   - g. [ ] Fresh → `main`, verzia 0.4.0; verejné vydanie iba na pokyn.
   - Rozloženie Fresh (schválené 12. 10.): `goo/` engine, kvapky, prihlásenie, zámok, SAFE a `lang/` s prekladmi ·
     `apps/` aplikácie QML · `bin/` príkazy · `system/` Hyprland, labwc, greetd, systemd, plymouth · `assets/` tapety,
     písma, textúry · `crates/` Rust · `patches/` záplaty pleamaru · `tests/` kontroly (`tests/check.sh` pred každým commitom) · `FILES`.
3. [ ] **STRESTEST P1 — Boot a GOO** (001–045, 541–554). Strojovo overiteľné robí Claude, klikanie autor.
   *Hotovo, keď:* každý z týchto testov má stav a zlyhané majú úlohu.
4. [ ] **SafeGoo** — dokončiť podľa toho, čo ukáže bod 1 (ovládanie okien na labwc, diagnostika pádu).
   - **Diagnostika pádu podľa whyd** (schválené 13. 10.; [whyd](https://github.com/vmaltarello/whyd), Go, GPL-3.0,
     samostatný program): dnešný `last-crash.log` z `latte-session` zachytí iba pád Hyprlandu v tej istej relácii.
     whyd z žurnálu predošlého štartu rozpozná aj zamrznutie s tvrdým vypnutím, OOM, chyby GPU, zlyhané služby
     a prehriatie (pravidlá v TOML, správa so skrytými údajmi). Postup: (a) vyskúšať ručne na latte-lab
     (`whyd` po štartoch z bodu 1); (b) vlastné pravidlá pre `latte-session`, Hyprland, engine Goo a prepnutie do SAFE;
     (c) v SAFE položka „Prečo sa skončila minulá relácia“ — súhrn z `last-crash.log` a z whyd, správa na skopírovanie;
     (d) whyd ako voliteľná závislosť (balík rpm z vydaní, riadok vo `FILES` a v `TRETIE-STRANY.md`), bez neho ostane
     dnešný výpis. *Overiť:* či whyd vie aj aktuálny štart od času pádu (pád relácie bez reštartu), inak to ostáva na
     `latte-session`.
5. [ ] **GooEngine:** záťaž v pokoji (12. 10.: 44 % jadra, 6. 10.: 17 %), hĺbková kontrola LensGoo, monitor
   pripojený za behu, 1024 × 768.
   Fresh, merané 12. 10. v `tests/screen.sh` (RX 640, 60 snímok/s, `PLEAMAR_TIMING=1`): scéna s 32 miestami 24 % jadra
   (pravidlá a pružiny 1,5 ms, skladanie 1,2 ms, kreslenie 0,7 ms na snímku), so 16 miestami 17 %; každých 16 miest
   stojí ~7 %, aj prázdnych. Zatvorená karta a prázdne miesta sa už nekreslia (27 → 24 %). Čo by pomohlo najviac:
   `rate:` podľa podmienky (záplata pleamaru — 30 snímok/s, kým kurzor nie je pri kvapkách; `rate` je dnes iba číslo),
   prípadne menej miest.
6. [ ] **Aplikácie podľa Priority UX** — prvý Barista s AVP2 (`docs/barista/NAVRH.md`).
7. [ ] **Režim okien Glance** (rozhodnuté 13. 10., podľa [Glance](https://github.com/scottjenson/Glance) Scotta
   Jensona, MIT) — štvrtý režim vedľa pásky, dlaždíc a plávajúcich, ponúka sa **iba na širokom monitore**. V strede
   **Main** a vedľa neho **Stash**: skutočné okná v skutočnej veľkosti. Pri okraji **Parking**: náhľady odstavených
   okien, kreslí ich engine Goo, klik okno vráti. Minimalizácia v Glance = odstavenie do Parkingu.
   *Pripravené:* či a ako BarGoo okná ukazuje, určuje jedno miesto (`berries_out()` v `goo/lib/bar.luau`) — Parking
   bude ďalšia podoba toho istého zoznamu okien. *Na premyslenie pred prácou:* náhľady okien v engine (pleamar má
   službu `thumbnails`; miesto kvapky dnes nesie ikonu 30 × 30, náhľad potrebuje väčší obrázok a obdĺžnikový tvar),
   odkiaľ je monitor „široký“, čo robí Stash v Hyprlande (pravidlá okien alebo vlastné rozloženie). Náhľady sa
   dovtedy nerobia.
8. [ ] **Fyzikálne prostredie kvapiek** (rozhodnuté 13. 10.: neskôr, **až po zmeraní a otestovaní Fresh na hardvéri
   latte-lab**). Dnes majú kvapky jedny pravidlá a spoločné prostredie (gravitácia, hladina, vietor, pružiny), ale
   nepôsobia na seba silami: neprekrývanie počíta logika, gravitácia platí iba pri páde a skoku, okná nie sú súčasťou
   prostredia. Cieľ: hmotnosť, zotrvačnosť, vzájomné odpudzovanie a zrážky ako pravidlá scény, rovnaké pre každú
   kvapku (vzor fwm, R3·A). Znamená prepísať pohybovú časť `goo/parts/drops.plm` a presunúť neprekrývanie z
   `goo/lib/engine.luau` do scény; najprv zmerať cenu na snímku (dnešné pružiny: 24 % jadra pri 32 miestach).

## ROADMAP2 — LatteOS od nápadu po hotový produkt

**Pridané 9. 10. 2026.** Pôvodná roadmapa je od 9. 10. v snímke
[docs_zaloha/2026-10-09-roadmap-pred-ciscenim.md](docs_zaloha/2026-10-09-roadmap-pred-ciscenim.md) („vyššie“ a
„pôvodné fázy“ v ďalšom texte znamenajú ju) a zachováva doterajší plán aj záznam práce. Táto časť pridáva produktovú postupnosť: LatteOS nie je iba grafické rozhranie Goo,
ale integrovaný systém nad Linuxom — od štartu a relácie cez kompozitor, shell, aplikácie a služby
po hardvérovú podporu, inštaláciu, obnovu a vydanie.

ROADMAP2 zároveň zachytáva **stav a pôvod práce pri prechode z Classicu na GOO** a skladá ho do
postupnosti až po hotový produkt. Je to pracovný podklad na porovnanie so starou roadmapou; nejde
zatiaľ o rozhodnutie, že sa staré položky majú vymazať alebo presunúť. Podrobné pôvodné znenie,
merania a históriu naďalej uchováva roadmapa vyššie; ROADMAP2 ich zhŕňa podľa súčasného produktu.

### Pravidlá práce s ROADMAP2

- Vývojový postup je **po etapách produktu**, ale pracovné prúdy v implementačnej etape môžu napredovať
  paralelne, ak nemajú vzájomnú závislosť.
- Každá nová funkcia prejde primerane veľkým cyklom: **nápad a používateľský problém → rozhodnutie →
  technický návrh a riziká → prototyp → implementácia → integrácia → overenie → vydanie a údržba**.
  Pri malej zmene sa kroky môžu spojiť; pri zmene štartu, bezpečnosti alebo formátu dát sa nevynecháva
  návrh, obnova ani test.
- Nápad v `inspo/` nie je automaticky schválená úloha. Do aktívnej práce sa dostane po pomenovaní
  prínosu pre LatteOS, porovnaní s tým, čo už existuje, a rozhodnutí o prijatí.
- **Rozlíšiť pôvod aj platnosť.** Úlohy zo zrušenej Classic vetvy sú história alebo kandidáti na
  opätovné použitie, nie automaticky úlohy LatteOS GOO. Práca na spoločnej linuxovej platforme a
  aplikáciách sa prenáša, ak je stále súčasťou produktu. Funkcie vytvorené po prechode sa označia
  ako GOO.
- **Detail ostáva pri svojom technickom zdroji, stav patrí aj sem.** ROADMAP2 uvádza, čo je
  dokončené, rozhodnuté a otvorené, ale podrobné kroky, merania a históriu necháva vo fázach
  vyššie alebo v dokumentácii. Tak sa pri porovnaní v pondelok **12. 10. 2026** dá určiť, čo premiestniť, zlúčiť,
  ponechať ako históriu alebo zrušiť.
- Značky `[x]`, `[~]`, `[ ]` zachovávajú význam používaný v pôvodnej časti roadmapy: hotové, čiastočné /
  rozpracované, otvorené. **Otvorená otázka alebo nápad bez rozhodnutia nie je schválená implementačná
  úloha.**
- Pri každom významnom míľniku sa uvedie výsledok, závislosti a dôkaz overenia (test, meranie, skúška
  na zariadení alebo používateľský scenár). Funkcia je hotová až vtedy, keď je súčasťou použiteľného
  systému, nie iba prototypu alebo samostatného programu.
- Záväzné pravidlá plochy sú v [LATTEOS-GOO.md](LATTEOS-GOO.md), záznam používateľských rozhodnutí
  v [docs/goo/ROZHODNUTIA.md](docs/goo/ROZHODNUTIA.md), technické detaily v dokumentácii príslušného
  subsystému.

### Stav vývoja pri prechode na GOO

Toto je orientačný súpis k 9. 10. 2026 podľa stavu a dátumov v pôvodnej roadmap. Značky hovoria
o **pôvode a platnosti**, nie o technickom stave:

- **HISTÓRIA / CLASSIC** — vzniklo pre zrušený Classic; už sa to nevyvíja ako samostatná plocha.
- **ZÁKLAD** — vzniklo pred GOO alebo popri ňom, ale stále slúži celej LatteOS a prenáša sa.
- **GOO** — rozhodnutie alebo práca po prechode na jedinú edíciu LatteOS GOO.
- Stav práce je zvlášť označený `[x]` hotové, `[~]` čiastočne/rozpracované, `[ ]` otvorené.

#### A. Pôvodná vetva LatteOS Classic — história, nie cieľová edícia

- [x] Classic bol 5. 10. 2026 zrušený; samostatná klasická plocha, jej lišta, panely a spúšťač
  už nie sú cieľom ďalšieho vývoja.
- [x] V tejto vetve vznikli alebo sa rozpracovali rozhrania a aplikácie LatteOS (Noctalia/Quickshell,
  Nastavenia, Súbory, Monitor, App Manager, Barista, Heidelberg, AI/Text Bar, témy a živá tapeta).
  Ich jednotlivé funkcie majú v pôvodných fázach rôzny stav — dokončené, prototypové aj otvorené;
  tento súhrn ich **neoznačuje hromadne za hotové**.
- [ ] Pri porovnaní v pondelok 12. 10. rozdeliť položky tejto vetvy na: (1) iba Classic — archivovať,
  (2) spoločný backend alebo aplikácia — ponechať ako základ, (3) GUI/funkcia stále potrebná v GOO —
  preniesť do správneho pracovného prúdu, (4) zastarané alebo duplicitné — uzavrieť.
- [~] (súpis 12. 10. je v „Teraz“, bod 2) Ako Classic-only preveriť najmä pôvodnú klasickú lištu/panely/spúšťač a starú plochu
  `session/kvapky`; GOO používa engine `session/goo`, nie pôvodnú scénu Kvapky.

#### B. Prenesený základ systému — platný aj pre GOO

- [x] **F0–F2 / ZÁKLAD:** Fedora VM a balíkový základ; softvérové vykresľovanie; NORMAL/SAFE,
  `latte-boot`, počítanie pádov a návrat do SAFE; Hyprland Lua vrstva, režimy okien, skratky,
  viacstupňový výkon a herný režim. Tieto práce vznikli pred plným prechodom na GOO, no sú
  základom súčasného produktu.
- [x] **ZÁKLAD / systémové rozhrania:** greetd a prihlasovanie, systemd relácia, profily
  prostredí, portály, PipeWire, D-Bus a pomocné služby sú zavedené v rozsahu opísanom vo F1–F4.
- [x] **ZÁKLAD / bezpečnosť:** oddelené profily dôvery, D-Bus filter, NET pre Flatpak aj natívne
  aplikácie a Setup Plan sú implementované podľa F6.
- [~] **ZÁKLAD / aplikácie:** Súbory, Monitor, Správca zariadení, App Manager, Barista, záloha,
  cloud a synchronizácia majú použiteľné časti; nejde však automaticky o finálnu integráciu
  ani úplné pokrytie. Otvorené pokračovania sú rozdelené podľa produktu v časti D; zoznam zložiek je v časti E.
- [~] **ZÁKLAD / AI:** `latte-ai` už pripája lokálne, domáce a cloudové modely aj vybrané
  poskytovateľské CLI. Používateľské AI v LensGoo má samostatne známu kvalitatívnu medzeru.
- [ ] Reálny hardvér NVIDIA, širšia kompatibilita zariadení, testy čistej inštalácie a dlhodobá
  stabilita ešte nie sú uzavreté brány produktu.

#### C. Aktuálna produktová vetva LatteOS GOO — od 5. 10. 2026

- [x] **Rozhodnutie:** jediná edícia je LatteOS GOO; nasadzuje sa engine Goo (`session/goo`),
  pôvodná plocha Kvapky sa nenasadzuje. Pravidlá produktu sú v
  [LATTEOS-GOO.md](LATTEOS-GOO.md).
- [x] **Rozhodnutia o správaní GOO:** myš je prvá, klávesnica doplnok; cieľom sú návyky Windows 11;
  kvapky sú káva, Goo má vlastný vzhľad a karty vyrastajú z kvapiek. Podrobné záväzné pravidlá sú
  v [LATTEOS-GOO.md](LATTEOS-GOO.md), nie v historických Classic návrhoch.
- [x] **Rozhodnutie o SAFE:** plné SDF Goo je pri softvérovom kreslení príliš pomalé; SAFE preto
  používa jednoduché statické kvapky. Ide o stanovený smer, nie dôvod pokúšať sa nasadiť plný
  dynamický engine v pixman režime.
- [x] **Rozhodnutie o poradí práce:** najprv dokončiť použiteľné GOO a systémový zážitok; nápady
  z inšpirácie alebo nové externé projekty sa nepridávajú automaticky ako závislosti.
- [~] **GOO / engine a plocha:** jadro pravidiel kvapiek, BarGoo a správa okien, LensGoo, PowerGoo,
  QueenGoo, ClockGoo, karty, upozornenia, sklo a používateľské kvapky sú implementované v rôznom
  rozsahu a priebežne overované. Samotný engine ešte nie je hotový produkt; SafeGoo a ďalšie
  otvorené overenia sú uvedené nižšie. Detailný stav ostáva v F3·G.
- [x] **GOO / integrácia:** GOO je predvolená relácia; Noctalia poskytuje rohovú lištu a systémové
  funkcie. BarGoo pre viac monitorov, profil používateľa, nastavenia kvapiek, Tvorca Goo, skratky,
  obnovenie relácie, webové aplikácie, Zoxide a DiskTree majú implementované časti opísané vo F3·G.
- [x] **GOO / verejné vydanie:** príprava a vydanie 0.3.0 „Jihlavanka“ sú zaznamenané ako hotové.
  [ ] Čistú inštaláciu vydaného verejného stromu treba ešte overiť.
- [~] **GOO / SAFE:** existuje skúšobný SafeGoo so statickými kvapkami a nízkou spotrebou v
  softvérovom režime. Chýba dokončenie ovládania okien a potrebných kvapiek/diagnostiky a jeho
  zapojenie ako predvoleného SAFE shellu.
- [~] **GOO / LensGoo a AI:** základ spúšťača, hľadania a AI existuje; hĺbková kontrola podľa
  používateľa má zamerať predovšetkým kvalitu AI rozhovoru, odpovedí, výberov a chybových stavov.
- [~] **GOO / aplikácie a integrácia:** viacero funkcií je hotových, ale ostávajú reálne testy
  telefónu/tlačiarne/skenera, verejnej inštalácie, skutočného Beepera, výkonnostné a prekladové
  medzery a dokončenie App Managera/Baristu. Podrobnosti sú v F3·G a F4–F8.
- [ ] **GOO / ďalšie rozhodnutia:** nové návrhy z `inspo/` (napr. reakcia kvapiek na hudbu,
  vizuálne prechody, ďalšie cloudové či bezpečnostné nástroje) sú prieskum, kým sa výslovne
  neprijmú; existujúce návrhy a verdikty sú v [inspo/dalsie_inspiracie.md](inspo/dalsie_inspiracie.md).

#### D. Otvorené pokračovania podľa pracovného prúdu

Toto sú hlavné zostávajúce celky, nie úplný výpis každého nezaškrtnutého políčka. Presný rozsah sa
pri porovnaní v pondelok 12. 10. potvrdí oproti pôvodnej roadmap.

- [ ] **LatteOS štart a relácia:** dokončiť tok čistej inštalácie → boot → prihlásenie → GOO/SAFE →
  obnova po zlyhaní; odlíšiť hotový F1 boot základ od nedokončeného SafeGoo a koncových testov.
- [ ] **GooEngine:** uzavrieť zdieľanie jednej logiky a dvoch vzhľadov NORMAL/SAFE; doplniť chýbajúce
  ovládanie okien v labwc, SafeGoo, beh monitorov pripojených za chodu, pokoj pri nečinnosti a
  meranie výkonu po rozšírení funkcií.
- [ ] **Goo kvapky:** dokončiť konkrétne otvorené úlohy BarGoou, LensGoo, PowerGoo, ClockGoo,
  QueenGoo a ChatGoo. Ďalšie kvapky a vizuálne efekty posudzovať samostatne podľa prínosu a výkonu.
- [ ] **Súbory:** nadviazať na hotové dvojpanely, prenosy, archívy, vyhľadávanie, sieť a cloud;
  uzavrieť otvorené rozšírenia/UX, odolnosť pri chybách a potrebné overenie hardvéru.
- [ ] **Monitor:** nadviazať na existujúce procesy, služby, autoruns a senzory; dokončiť stálu
  telemetriu a pohľad na spotrebu podľa aplikácie v čase, bez nepresných alebo skrytých zberov.
- [ ] **Správca zariadení a HW:** dokončiť overenie kompatibility a reálneho HW, ovládačov,
  tlače/skenerov/telefónov a bezpečnej obnovy po zmene.
- [ ] **App Manager a Barista:** dokončiť stav úloh, históriu a používateľský tok inštalácie;
  Barista pokračuje podľa fáz v `docs/barista/NAVRH.md`, prvý plný prípad je AVP2.
- [ ] **AI:** zlepšiť AI v LensGoo; poskytovateľov, limity, súkromie a systémové nástroje dopĺňať
  explicitne a iba s potvrdením používateľa.
- [ ] **Integrácia, kvalita a vydanie:** dotiahnuť jednotné GUI, preklady a prístupnosť po ustálení
  funkcií; testovať VM aj reálny AMD/NVIDIA HW, čistú inštaláciu, aktualizáciu, obnovu, výkon a
  regresie pred ďalším vydaním.
- [ ] **Neskôr:** Fedora Atomic/bootc, rollback, prenos účtu a ďalšie veľké rozšírenia až po
  uzavretí požadovanej stability a hardvérovej matice.

### E. Zložky LatteOS — mapa produktu

Doplnené 9. 10. 2026 z autorovej prezentácie `LatteOS.pdf` — **ako má vyzerať hotová LatteOS 1.0 „Arabica“**
(ciele a marketing, nie opis dnešného stavu), skontrolovanej proti
[LATTEOS-GOO.md](LATTEOS-GOO.md) a pôvodnej roadmape. Je to **jediný zoznam „čo LatteOS obsahuje“**:
každá zložka má prúd R3 (kde sa vyvíja) a zdroj podrobností (kde je detail a história). Stav `[x]` `[~]` `[ ]`
ako inde; „návrh“ = nápad bez rozhodnutia, nie úloha.

| Zložka | Čo je | Stav | Prúd | Zdroj podrobností |
|---|---|---|---|---|
| **Základ systému** | Fedora Server 44 (dnf); neskôr obraz Atomic/bootc „ako Bazzite“ | [x] / návrh | R2, R7 | úvod, F0, A (riadok 949) |
| **Hyprland 0.56 (Lua)** | okná, režimy (páska, dlaždice, plávajúce), sklo, herný režim | [x] | R3·B | F2 |
| **Noctalia 5** | v GOO iba rohová lišta (widgety, doplnky), ovládacie centrum, OSD, zámok | [~] | R3·B | F3·G, LATTEOS-GOO §4.8 |
| **GooEngine** | plocha z kvapiek kávy na pleamar (`session/goo`) | [~] | R3·A | F3·G, session/goo/README.md |
| ├ **BarGoo** | lišta okien: hlava = režim okien (ľavý klik), pravý = ukázať plochu; ikry = okná | [~] | R3·A | LATTEOS-GOO §4.1 |
| ├ **LensGoo** | spúšťač: aplikácie, súbory, web, terminál, AI | [~] | R3·A, R3·G | §4.3 |
| ├ **QueenGoo** | ľavý klik App Manager, pravý Správca zariadení (voliteľná) | [~] | R3·A | §4.4 |
| ├ **PowerGoo** | ľavý: účet, napájanie, Nastavenia, Monitor; pravý: pás CPU/RAM/GPU/VRAM | [~] | R3·A | §4.2 |
| ├ **ClockGoo** | čas, upozornenia, kalendár, pohoda (voliteľná) | [~] | R3·A | §4.5 |
| ├ **ChatGoo** | doplnok pre Beeper (voliteľná) | [~] | R3·A | §4.6 |
| └ **Vlastné kvapky, Tvorca Goo** | kvapka bez programovania; návrhy ClipGoo, MediaGoo, PassGoo, CastGoo | [~] / návrh | R3·A | §4.7, §4.11 |
| └ **LaunchGoo** | rýchly spúšťač skupín ikon (hry, práca), voliteľne odkazy na ploche | návrh | R3·A | Tvorca Goo (§4.7) |
| **Prihlasovanie (LoginGoo)** | šálka → LoginGoo (riadok na hladine), po prihlásení odovzdaná na miesto PowerGoo; výber relácie (GOO, Marea, Noctalia, Serpantinum) | [~] scéna je, ostáva overenie | R2 | §6.2, F1 |
| **SafeGoo (SAFE)** | minimálna záchranná relácia bez GPU s diagnostikou pádu | [~] | R2, R3·A | F3·G (SafeGoo) |
| **Nervboot** | vlastná ponuka štartu pred systemd-boot s dualbootom | návrh | R7 | riadok 714 |
| **Nastavenia** | kategórie, Kvapky, Vzhľad, výkon, jazyk, tapety (skwd-wall integrovaný v našej podobe) | [~] | R3·J | F3, F3·G |
| **Súbory = DualBrew** (názov vybraný 9. 10.) | vlastný dvojpanelový správca obohatený o funkcie iných autorov, siete, cloud, archívy | [~] | R3·C | F4 |
| **Heidelberg** | editor dokumentov (Markdown, docx, odt, PDF) | [~] | R3·C | F4 (riadky 789–792) |
| **Monitor** | Správca úloh + Autoruns + HWiNFO/CPU-Z; (návrh: BetterWindowsServices) | [~] | R3·D | F4 (Monitor 1–7) |
| **Správca zariadení** | HW, ovládače, tlačiarne, skenery, telefóny, kompatibilita | [~] | R3·E | F4, H |
| ├ **Netmanager / Sieť** | siete, vzdialené pripojenia (NetworkManager) | [~] | R3·E | F4, LATTEOS-GOO §5 |
| └ **Inšpektor siete** | radar okolitých sieťových spojení (ARP, mDNS, SSDP) | [x] základ | R3·E, R3·D | F4 (riadok 750) |
| **App Manager** | obchod, inštalácia (Flatpak, RPM), aktualizácie, firmvér; komunitné obchody | [~] | R3·F | F4, §6.3 |
| └ **Barista** | sprievodca inštaláciou nelinuxových aplikácií a hier (Wine/Proton, DOS, obrazy diskov) | [~] fázy F1–F5 | R3·F, R3·I | docs/barista/NAVRH.md |
| **Bezpečnosť** | Flatpak/bubblewrap, tlačidlo NET, D-Bus filter, záloha | [x] základ | R3·H | F6 |
| **AI (`latte-ai`)** | lokálne, domáce a cloudové modely, voliteľná; tokeny a limity | [~] | R3·G | F7 |
| **Hry** | Steam/Proton/umu, herná relácia | [~] | R3·I | F8, H |

#### Rozdiely medzi cieľom Arabica (prezentácia) a dnešným stavom

Prezentácia je cieľ, nie stav: čo z nej ešte neplatí, je zámer Arabicy a treba to v README oddeliť od toho, čo
systém robí dnes. Otvorené body (rozhodnuté sú `[x]`):

- [x] **Názvoslovie kvapiek (rozhodnuté 9. 10.):** predpona/prípona **„Goo“ je pripona a nesú ju iba kvapky v
  GooEngine**: BarGoo (dnes v kóde GooBar), PowerGoo (dnes GooPower), LensGoo, QueenGoo, ClockGoo, ChatGoo,
  LaunchGoo, LoginGoo. Neplatí pre samotný engine a plochu (GooEngine, LatteOS GOO) ani pre relácie (SafeGoo).
  V tejto roadmape ROADMAP2 sa už používajú nové názvy; **kód, dokumentácia a nastavenia sa zatiaľ nemenia**.
  Úloha na neskôr: premenovať v ~60 súboroch naraz s kontrolou `kvapky.json` používateľov (staré názvy čítať ešte
  jedno obdobie), potom prepísať README.
- [ ] **LaunchGoo (nápad autora, návrh):** rýchly spúšťač — do kvapky sa vložia ikony, napr. obľúbených hier, a
  neprekážajú na ploche; ďalšia kvapka môže niesť pracovné aplikácie, plocha ostane voľná. Odkazy môžu byť aj priamo
  na ploche („možnosti sú také aj onaké“). Základy už sú: Tvorca Goo (rýchle spúšťanie = skupina aplikácií, klik
  ukáže kartu s dlaždicami) a rýchly zoznam LensGoo. Treba rozhodnúť: viac skupín ako samostatné kvapky, ikony na
  ploche, PlayGoo (správca hier, alebo prehrávač hudby) je len nápad — ignorovať.

- [x] **Noctalia (rozhodnuté 9. 10.):** zostáva. Slúži ako **úložisko widgetov Noctalie** a minimalistické prostredie
  pre veci, ktoré v Goo nechceme. Zatiaľ sa nevyraďuje; autor iba zvažuje, či je potrebná v takom rozsahu a či ju
  nenahradiť optimalizovanejším riešením. Úloha v R3·B: **porovnanie** (čo z nej systém naozaj používa, jej cena v
  pamäti a CPU, kandidáti na náhradu) — bez rozhodnutia o odstránení.
- [x] **Barista (rozhodnuté 9. 10.; cieľ Arabicy):** zámer je „od malých vecí po veľké“. Dnes **Windows a Android**; výhľad
  ďalšie platformy a emulácie (konzoly, retro, neskôr aj nové) podľa toho, čo bude technicky a právne možné —
  autor sleduje vývoj v komunite (tvrdenia z diskusií, napr. o spätnom inžinierstve PlayStation, sú zatiaľ
  neoverené). Každá nová platforma = samostatný rozhodovací bod (R3·I). README opíše rozsah „dnes + výhľad“.
- [x] **AI — voľba na začiatku (rozhodnuté 9. 10.):** používatelia sa delia na priaznivcov a odporcov AI, preto
  **úvod inštalácie LatteOS ponúkne výslovnú voľbu AI zapnúť / vypnúť** (ide o sľub, nie iba nastavenie).
  Kedykoľvek ju možno zmeniť v Nastaveniach. Pri vypnutí AI sa neinštalujú a nespúšťajú AI nástroje, LensGoo nemá
  AI režim a nič neodchádza na AI služby. Úlohy sú v R2 a R3·G.
- [x] **skwd-wall (rozhodnuté 9. 10.):** využijeme a integrujeme **v našej podobe** — výber tapiet, živé tapety a
  prechody (aj ako prechody pri prepínaní okien, programov a priečinkov) v Nastaveniach, so spoločnými
  pravidlami GooEngine a obmedzením pre stupeň Softvér a SAFE. Nejde o doslovné prevzatie; licenciu a čo sa preberá
  určí R1 (R3·J).
- [ ] **Pás PowerGoo:** „veličiny sa menia v Nastaveniach“ — dokumentované sú pevné bunky CPU · RAM · GPU · VRAM;
  výber veličín overiť, inak z opisu vypustiť.
- [ ] **LensGoo:** prepínanie funkcií kolieskom — dokumentované sú Tab / Shift+Tab (kolieskom sa mení veľkosť
  kvapky); overiť, či koliesko ide aj v karte.
- [ ] **Nastavenia › Vzhľad:** nastavenia jednotlivých Goo sú dnes v Nastaveniach › **Kvapky**, nie vo Vzhľade.
- [ ] **Prihlasovanie:** výber relácie (SAFE, iné shelly) je v scéne iba „vývojárska verzia“; v README
  opísať ako dostupný iba po overení.
- [ ] Pravopis v opise: Flatpak, bubblewrap, „softvér“; „sf“ = softvér; „blue“ = Fedora Atomic / Universal Blue.

#### Kandidáti na vyčistenie (nič sa zatiaľ nemaže)

Tvrdenia, ktoré už neplatia a ostávajú len ako história, na posúdenie pri porovnaní v pondelok 12. 10.:

- [ ] [LATTEOS-GOO.md](LATTEOS-GOO.md) (úvod): „verejná kópia je zastaraná, po dokončení sa zverejní 0.2“ — vydané je
  0.3.0 (6. 10.); „predvolené prihlásenie bude engine Goo, ešte sa prerobí“ — podľa §6.2 je hotové.
- [ ] Pôvodná roadmapa: položky o Classic lište a spúšťači (F3, F3·G — napr. riadky 323–336, 378), „SAFE používa Noctaliu
  s dizajnom Classic“ (riadok 336; nahradené rozhodnutím o SafeGoo, riadok 384), plocha Kvapky (`session/kvapky`).
- [ ] Číslovanie §6.2 v LATTEOS-GOO.md (8, 10, 11, 9) a hlavička „Zmena smeru“ v ROADMAP.md po zmazaní starých dát.
- [ ] Značky `[x]` pri funkciách iba pre Classic označiť `[-]` (zrušené), nie `[x]`.

#### Trvalé priority a pravidlá, ktoré nepatria jednému prúdu

- [ ] **Priorita UX (od 7. 10. 2026):** najprv softvér zo zoznamu záujmov a zvyky z Windowsu; prístupnosť až v Arabice.
- [ ] **STRESTEST + optimalizácia + stabilita (O, F5) = jedna dráha k 1.0:** [bughunt/STRESTEST.md](bughunt/STRESTEST.md) je
  dôležitý súbor, ktorý sa **realizuje postupne, ako sa vývoj blíži k 1.0**, spolu s optimalizáciou (najprv merať,
  potom meniť, potom znova merať) a stabilitou. Výsledky meraní a prejdené testy patria do R5.

### F. Prenos zo starej roadmapy pred jej zmazaním

Súpis z 9. 10. 2026: stará časť má 112 otvorených (`[ ]`, `[~]`) položiek. Prúdy R3 ich pokrývajú **všeobecne**;
tu sú konkrétne položky, ktoré by sa po zmazaní stratili (číslo = riadok v starej časti, platí do jej zmazania).
Položka je **úloha**, kým nie je označená „návrh“.

**Hotové pred zmazaním (9. 10.):** snímka starej časti je v
[docs_zaloha/2026-10-09-roadmap-pred-ciscenim.md](docs_zaloha/2026-10-09-roadmap-pred-ciscenim.md); rámec, režimy a štart
(r. 14–164) sú v [docs/NAVRH-STARTU.md](docs/NAVRH-STARTU.md); sekcia O s meraniami (r. 912–945) v
[docs/OPTIMALIZACIA.md](docs/OPTIMALIZACIA.md); obe sú odkázané z [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md). Hotové
fázy F0–F2 a merania VM sú v [docs_zaloha/](docs_zaloha/README.md), ostatné `[x]` sú história. Otvorené otázky a „Zadanie 24. 9.“
(r. 955–1015): DMS/Caelestia a COPR sú vyriešené, zvyšok je prenesený nižšie. **Starú časť maže autor sám, keď bude s ROADMAP2 spokojný.** Zmazaná 9. 10.; overené 12. 10.: číslo „r. N“ v tejto roadmape = riadok **N + 3** v snímke.

**R2 — základ a štart:** distribúcia balíkov, COPR (r. 201); grafická SAFE s `nomodeset`, systemd user relácia (r. 202);
Sunshine pred prihlásením, virtuálny monitor `[~]` (r. 318); prihlásenie — čierna sekunda, voľba prihlasovača v
Nastaveniach (r. 468); greenboot + Automatic Boot Assessment (r. 952); test „zaplniť RAM vo VM“ (r. 807).

**R3·A — GooEngine a kvapky:** overiť skrytie voliteľnej kvapky (r. 432); živé bytosti — obmedzenie snímok pri nečinnosti (r. 433);
profil — programy čítajú dokument priamo (r. 466); overiť Odhlásiť a ClockGoo na 1024 × 768 (r. 470); pokrývky hlavy QueenGoo (r. 471);
BarGoo `reversed` a monitor pripojený za behu (r. 480); CPU enginu — meranie 6. 10. (r. 482); formulár vlastných kvapiek (r. 493);
kalendár ClockGoo — synchronizácia, názov budíka (r. 494), **prepracovanie podľa regiónu** (r. 618), indikátor Nerušiť (r. 623);
LensGoo — zvyšok (r. 498), **hĺbková kontrola** (r. 626), indexovanie častých priečinkov (r. 554); ChatGoo — Beeper, vtečenie okna, odznak (r. 645);
goo telo pod rohovou lištou (r. 501); deň a noc na hladine (r. 610), nočné svetlo `[~]` (r. 608); sady ikon (r. 669);
prístupnosť — zvyšok (r. 506).

**R3·A — návrhy kvapiek a efektov (nie úlohy, kým ich autor neprijme):** hovor cez podržanie LensGoo, whisper.cpp (r. 529);
nepoužívaná kvapka sa zmenšuje (r. 531); odkladacia kvapka na súbory (r. 532); zvuková identita Goo (r. 533);
tekuté zóny okien (r. 548); nájdi kurzor zatrasením (r. 552); stavy hladiny (r. 555); AirDrop kvapky cez LocalSend (r. 557);
ikra hrajúca zvuk vibruje (r. 572); ekvalizér Goo (r. 716); bublina odchádzajúceho spojenia v modeli NET (r. 616);
režim sústredenia (r. 541); gamepad (r. 545); prechod z Windowsu — import profilov, prehľad skratiek (r. 540);
komunitné doplnky Noctalie ako kvapky (r. 647); ClipGoo, MediaGoo, PassGoo, CastGoo (r. 520); PlayGoo (správca hier alebo prehrávač hudby).
Z `inspo/` 13. 10.: plocha bez klasickej lišty — zóny Main, Stash a Parking na širokom monitore (Glance, prednáška
Scotta Jensona pre KDE, 2026) — **rozhodnuté 13. 10. ako štvrtý režim okien, „Teraz“ bod 7**; pevné pravidlá fyziky kvapiek a okien — hmotnosť, zotrvačnosť, vzájomné odpudzovanie,
kvapalina tečúca okolo okien (fwm); vzhľad prehrávača a zámku obrazovky (widgety Chaldea, 0BSD).

**R3·B — shell a vzhľad:** téma Latte a Úsporná, farby z tapety (r. 274); prvky stupňa Plný, varianty bez shaderov (r. 275–276, 290);
materiál na oknách pri kovových témach (r. 521); Noctalia prekreslí celý povrch pri zmene widgetu (r. 939); animácie panelov na GPU (r. 968);
ovládacie centrum Noctalie — overiť (r. 630); dialóg Otvoriť/Uložiť cez portál v jednotnom vzhľade (r. 590);
vlastné `app_id` a preložiteľné spúšťače (r. 654); slovenský preklad Noctalie a záplaty pleamaru autorom (r. 656, 658); preklady odložené nakoniec (r. 725);
živá tapeta a shaderové prechody (r. 1013–1014; skwd-wall rozhodnutý, R3·J).

**R3·C — Súbory (DualBrew) a Heidelberg:** prostredie nad pôvodným súborovým systémom (r. 565); **plná funkčnosť Total Commandera** (r. 979:
vlastné stĺpce r. 985, skratky a menu r. 1008, pluginy r. 1012); Data Manager v Ruste (r. 782); Flea ako možný základ — odložené (r. 614);
hľadanie v obsahu PDF/DOCX (r. 849); Heidelberg verné docx (r. 792); Strata ako vzor — stĺpcové zobrazenie (Miller), ovládanie klávesnicou, približné hľadanie mien (inspo 13. 10.).

**R3·D — Monitor:** „kto žerie“ energiu, dáta, RAM, disk po aplikáciách (r. 574); `latte-sysmond`, eBPF (r. 775, 778);
bezpečnostná kontrola balíkov bumblebee (r. 603); Python nástroje — čas štartu (r. 940).

**R3·E — zariadenia a siete:** skúška s reálnou tlačiarňou, skenerom a telefónom (r. 515); KDE Connect `[~]` (r. 534);
zvuk do DLNA (r. 753); Inšpektor — nové zariadenie, slabé heslo routera (r. 756); Inšpektor — **zariadenia Matter a Thread pasívne** (schválené 13. 10.):
skupina „Inteligentná domácnosť“ z ohlásení mDNS (`_matter._tcp`, `_matterc._udp`, hraničné smerovače `_meshcop._udp`),
výrobca a typ, ak ich zariadenie ohlási, upozornenie na nové zariadenie; bez párovania. Podrobnosti cez párovací kód
(batéria, firmvér, topológia Thread) sú iba návrh, nie úloha (inspo 13. 10., podľa UniFi Network 11); `latte-boot compat` v inštalátore (r. 765);
Device Manager v Ruste (r. 767).

**R3·F — App Manager a Barista:** úlohy na pozadí viditeľné (r. 409); obchod — zvyšok (r. 510), Bazaar a ZimaOS (r. 560);
Barista ako pomocník z kontextovej ponuky okna (r. 596); ProtonDB, Waydroid, OARS detské účty, história úloh (r. 787, 868);
„Vrátiť včerajší systém“ (r. 951).

**R3·G — AI:** `latte-mcp` a zručnosť pre AI (r. 546, 559, 595); limity predplatných v LensGoo (r. 598); Newelle ako jadro (r. 599);
streamovanie odpovede (r. 872); viac poskytovateľov a prihlásenie výberom (r. 873); Ollama na CPU (r. 879); Qwen3-14B-sk (r. 906).

**R3·H — bezpečnosť:** profily pre Windows aplikácie (r. 812); NET pre jednotlivé hry v Steame a skripty (r. 818).

**R3·I — hry:** Steam, umu, Proton 11 (r. 883); NVIDIA akmod (r. 892); gamescope, MangoHud, HDR/VRR — čaká na skúšku (r. 898);
Lepton, F-Droid 2 (r. 906–907); SAFE pri zlom ovládači NVIDIA (r. 910).

**R5 — optimalizácia:** pamäť — zlúčenie démonov, zatiaľ nie (r. 920); sledovanie poškodenia v kompozitore (r. 935); štart `systemd-analyze` (r. 942).

**R7 — neskôr:** obraz bootc/rpm-ostree (r. 950), Nervboot (r. 714), prenosná relácia a LatteApp (r. 947), distribúcia balíkov (r. 201).

**Na archiváciu (Classic alebo zrušené):** tvar L panela s lištou (r. 964); Pet Circus a maskoti (r. 974 — mazlíci sú zrušení, r. 471).

### Etapy produktu a brány pripravenosti

Nasledujúce etapy opisujú postup od zámeru po vydanie. Sú to brány a výsledky pre celý produkt;
aktuálne hotové, rozhodnuté a otvorené pracovné celky sú zhrnuté v častiach A–D vyššie a ich
technický rozpis ostáva v pôvodných fázach.

#### R0 — Zámer, používatelia a rozsah

**Výsledok:** je jasné, pre koho LatteOS je, aký problém rieši, čo je jeho jediná edícia a čo do
produktu nepatrí. Zaznamenajú sa používateľské scenáre, obmedzenia VM a podporovaného hardvéru,
zásady ovládania a priority.

- [x] Smer LatteOS GOO, zrušenie Classicu, zásady Goo a základný cieľ používateľského zážitku sú
  zachytené v existujúcich dokumentoch.
- [ ] Pri nových väčších funkciách doplniť konkrétny scenár a dôvod: čo chce používateľ dosiahnuť,
  ako to dnes urobí a ako spozná, že LatteOS to vyriešil lepšie.
- [ ] Udržiavať jednu aktuálnu hranicu produktu: čo je súčasť systému, čo voliteľná aplikácia /
  integrácia a čo iba externý alebo vývojársky nástroj.

#### R1 — Prieskum, rozhodnutie a technický návrh

**Výsledok:** pred implementáciou je známe, či sa riešenie preberá, integruje alebo píše; sú určené
rozhrania s ostatnými časťami systému, licencia, oprávnenia, náklady, riziká a cesta bez GPU.

- [ ] Každý prijatý nápad z inšpiračných zoznamov porovnať s existujúcimi funkciami a plánom; zamietnuté
  alebo odložené návrhy označiť ako také, nie ako otvorenú prácu.
- [ ] Pri systémových častiach určiť vlastníctvo dát a API, používateľa procesu, životnosť služby,
  spôsob aktivácie, zlyhanie a obnovu.
- [ ] Pri GUI určiť prístup cez myš aj klávesnicu, správanie pri malom rozlíšení a slabom výkone,
  preklady a súlad s vizuálnymi pravidlami GOO.
- [ ] Pri sieťových/cloudových/AI integráciách určiť, aké údaje odchádzajú, komu, s akým súhlasom
  a či existuje lokálna alebo odpojená cesta.

#### R2 — Základ platformy LatteOS

**Výsledok:** čistá Fedora inštalácia vie bezpečne naštartovať do použiteľnej relácie a má spoľahlivý
základ, na ktorý sa dajú integrovať ostatné pracovné prúdy.

- [x] F0–F2: základ VM, grafický stack, režimy NORMAL/SAFE a základ Lua vrstvy Hyprlandu sú
  hotové. Boot NORMAL/SAFE bol overený; starý SAFE používa Noctaliu, preto jeho náhrada SafeGoo
  patrí medzi otvorené práce nižšie.
- [ ] Overiť celý aktuálny tok po prechode na GOO: čistá inštalácia → boot → GOO prihlasovanie →
  predvolená Goo relácia → SAFE po zlyhaní → návrat do NORMAL; osobitne potvrdiť, že verejný
  vydaný strom obsahuje a spúšťa správne relácie.
- [ ] Dokončiť SafeGoo ako použiteľnú záchrannú reláciu s potrebnými základnými ovládacími prvkami,
  diagnostikou a funkčným ovládaním okien na labwc; zachovať pixman/bez-GPU obmedzenia.
- [ ] Overiť čistú inštaláciu, prvé spustenie, aktualizáciu a obnovu po neúspešnom štarte.
- [ ] Zabezpečiť, aby systémové služby štartovali až vtedy, keď sú potrebné, a aby ich pád nezhodil
  celú používateľskú reláciu.
- [ ] Inštalátor: úvodná obrazovka s voľbou AI zapnúť / vypnúť (R3·G). Prihlasovanie: prepnutie do SAFE alebo
  iného nainštalovaného shellu (KDE, GNOME, čistá Noctalia…); SAFE nesie sadu nástrojov na zistenie, čo sa pokazilo.

#### R3 — Vývoj pracovných prúdov systému

Pracovné prúdy nižšie môžu ísť súbežne, ale každá väčšia funkcia v nich postupuje cez R0/R1, prototyp,
implementáciu, integráciu a overenie. Podnadpisy sú súčasťou jednej produktovej roadmapy, nie oddelené
projekty bez spoločného cieľa.

##### R3·A — Plocha a GooEngine

**Cieľ:** dokončiť predvolenú plochu LatteOS GOO ako súdržný engine a používateľský shell. Platné
pravidlá sú v [LATTEOS-GOO.md](LATTEOS-GOO.md), API a stav enginu v
[session/goo/README.md](session/goo/README.md), používateľské rozhodnutia v
[docs/goo/ROZHODNUTIA.md](docs/goo/ROZHODNUTIA.md).

- [ ] **Jadro GooEngine:** jedna spoločná logika a API kvapiek, jasné hranice medzi enginom,
  scénou, pomocníkmi, kompozitorom a vzhľadom NORMAL/SAFE; zachovať kompatibilitu existujúcich
  kvapiek a nastavení.
- [ ] **BarGoo a okná:** dokončiť chýbajúce správanie lišty, ovládanie okien v NORMAL aj SAFE,
  pripájanie monitorov za behu a nastavenia viacerých obrazoviek.
- [ ] **LensGoo:** samostatne overiť vyhľadávanie a spúšťanie aplikácií/súborov a kvalitu AI
  rozhovoru; dotiahnuť poskytovateľov, vstupy a chybové stavy bez duplikovania všeobecnej práce
  na `latte-ai`.
- [ ] **PowerGoo a SafeGoo:** systémové akcie a indikátory v bežnej ploche; v SAFE zobrazenie
  príčiny, logov, diagnostiky a bezpečných možností obnovy.
- [ ] **Názvoslovie kvapiek:** rozhodnúť a jednotne premenovať (pozri E, rozdiely).
- [ ] **PowerGoo — pás výkonu:** výber zobrazených veličín (CPU, GPU, RAM…) v nastaveniach tohto Goo (z opisu autora;
  dnes pevné bunky CPU · RAM · GPU · VRAM). **QueenGoo:** pokrývka hlavy je voliteľná, preferovane korunka.
- [ ] **ClockGoo, QueenGoo a ChatGoo:** dotiahnuť nedokončené karty, upozornenia, kalendár,
  zariadenia a overenie so skutočnými aplikáciami/službami, ktoré kvapky zastupujú.
- [ ] **Vlastné a ďalšie kvapky:** overiť a doplniť napojenie existujúceho Tvorcu Goo na engine;
  návrhy ClipGoo, MediaGoo, PassGoo a CastGoo prijímať po jednom podľa používateľského prínosu.
  Každá kvapka používa spoločné pravidlá enginu, nastavení a ovládania.
- [ ] **Pohyb, zvuk a vizuálne efekty:** zmerať cenu fyziky, skla, dažďa a reakcie na hudbu; efekty
  musia byť vypnuteľné a nesmú zhoršiť čitateľnosť, SAFE ani stupeň Softvér.
- [ ] **Brána dokončenia Goo:** všetky základné úkony idú myšou; rozlíšenie najmenej 1024 × 768;
  funkčné okná/relácie na podporovaných monitoroch; overený výkon a bezchybný návrat po páde enginu.

##### R3·B — Kompozitor, Noctalia a používateľské rozhranie

**Cieľ:** Hyprland, Lua integrácia, Noctalia a Goo spolu tvoria jednu plochu bez konkurenčných
nastavení, duplicitných panelov alebo nekonzistentného správania.

- [x] Základná integrácia Hyprlandu (okná, režimy, skratky, herný režim) a Noctalie (rohová lišta,
  systémové funkcie) s GOO existuje; pozri F2 a F3·G.
- [ ] Overiť zostávajúce okraje integrácie: ovládacie centrum Noctalie, SAFE bez GPU, dynamicky
  pripojené monitory a čisté nastavenia medzi GOO a ostatnými reláciami.
- [ ] Dokončiť konkrétne otvorené GUI a interakcie pri malom rozlíšení, vrátane stavov
  načítania/chyby a návratu rizikovej zmeny; hotové základy tém a nastavení neopakovať.
- [ ] Preklady a prístupnosť dokončiť podľa schváleného rozsahu po ustálení funkcií; pripraviť
  testy pre čitateľnosť, kontrast, obmedzenie pohybu a klávesnicové ovládanie.
- [ ] Tapety, materiály, dážď, sklo a animované prechody zavádzať ako voliteľnú vrstvu vzhľadu,
  nie ako požiadavku pre funkčnosť desktopu.
- [ ] **Noctalia (úložisko widgetov a minimálne prostredie):** porovnať jej skutočné použitie a cenu s
  optimalizovanejšou náhradou; zatiaľ sa neodstraňuje (E).

##### R3·C — Súbory (File Manager) a používateľské dáta

**Cieľ:** Súbory bezpečne a zrozumiteľne spravujú pôvodný Linuxový súborový systém, pripojené
zariadenia, sieťové miesta a cloud bez uzamknutia dát do LatteOS.

- [x] Základ správcu súborov zahŕňa dva panely, karty, operácie F5/F6 s radom úloh, archívy,
  hľadanie, synchronizáciu, sieťové umiestnenia a cloud; presný rozsah je v F4.
- [ ] **Názov správcu súborov (rozhodnúť):** ak ostane vlastný a obohatený o nápady iných autorov, potrebuje meno.
  Kandidáti autora: Espresso Commander, Tamper, DualBrew. **Vybraný DualBrew (9. 10.)**; pred zavedením skontrolovať kolízie
  s existujúcimi projektmi.
- [ ] **Heidelberg:** verné formátovanie docx (tabuľky, štýly, hlavičky) a ďalšie otvorené položky z F4 (riadok 792).
- [ ] Doriešiť otvorené rozšírenia (vlastné stĺpce/pluginy, klávesové skratky a menu) a ergonomické
  medzery podľa používateľských scenárov.
- [ ] Dokončiť integráciu úložiska, USB, SMB/GVFS, telefónov a cloudových miest; pri odpájaní,
  prerušení siete a nedostatku miesta jasne oznámiť stav a zachovať dáta.
- [ ] Overiť bezpečné správanie pri prerušení kopírovania/synchronizácie, chybe zariadenia a
  obnove; zachovať už implementované plány synchronizácie, priebeh a zrušenie operácií.
- [ ] Overiť veľké súbory, archívy, oprávnenia, symlinky, odpojené disky, obmedzený priestor a
  bezpečné správanie pri chybe; zachovať prístup k súborom aj bez LatteOS UI.
Nové cloudové služby sa najprv posudzujú ako návrhy; cloud nesmie byť podmienkou lokálnej práce.

##### R3·D — Monitor, systémové služby a diagnostika

**Cieľ:** používateľ vie zistiť, čo sa deje so systémom a aplikáciami, a bezpečne konať bez
nepriehľadných privilegovaných služieb.

- [x] Základ Monitora už zahŕňa procesy, služby, autoruns, senzory, zariadenia a používateľské
  položky po štarte.
- [ ] Dokončiť stály zber telemetrie (`latte-sysmond`) a dlhodobý pohľad na CPU, RAM, GPU, energiu,
  sieť a disk; odlíšiť živý stav od historického odhadu a primerane uchovávať údaje s možnosťou
  vypnutia zberu.
- [ ] Nové akcie pre služby musia zachovať vysvetlenie pôvodu, oprávnení a vratnosť.
- [ ] Monitor spája Správcu úloh Windows 11, Autoruns, HWiNFO a CPU-Z; BetterWindowsServices je inšpirácia na
  prieskum (správa služieb), nie prijatá úloha.
- [ ] Rozhodnúť, ktoré inventárne alebo bezpečnostné schopnosti poskytne existujúci `latte-hw`,
  Monitor, Inšpektor siete a Barista. Nástroje typu osquery, Velociraptor, Zeek či Suricata
  nepridávať ako základné služby bez preukázanej potreby a výslovného modelu súhlasu.
- [ ] Zjednotiť diagnostické záznamy a export podpory tak, aby používateľ vedel skontrolovať,
  čo export obsahuje; citlivé údaje neodosielať automaticky.

##### R3·E — Správca zariadení a hardvér

**Cieľ:** LatteOS sa nainštaluje a funguje na jasne opísanom rozsahu PC, vrátane GPU, zvuku, siete,
obrazoviek, napájania, periférií a obnovy pri probléme s ovládačom.

- [x] Základ detekcie kompatibility HW (`latte-hw`, `latte-boot compat`) a stránka informácií
  o hardvéri v Správcovi zariadení existujú.
- [ ] Doplniť kompatibilitu do inštalátora a overiť hranice odporúčaní na rôznych CPU/GPU,
  Secure Boot, notebookoch a starších PC.
- [ ] Overiť na fyzickom hardvéri AMD aj NVIDIA grafický stack, Hyprland, Goo, hry, SAFE režim,
  aktualizáciu ovládača a návrat po zlyhaní.
- [ ] Doriešiť ovládače/zariadenia cez štandardné linuxové služby (udisks2, NetworkManager,
  PipeWire, fwupd a pod.) a zrozumiteľne oddeliť informáciu, odporúčanie a akciu vyžadujúcu
  oprávnenie.
- [ ] Telefóny: overiť KDE Connect a USB; scrcpy prípadne ponúknuť ako vedomý voliteľný nástroj,
  nie ako náhradu párovania, prenosu súborov alebo Waydroidu.
- [ ] Rozsah Správcu zariadení z opisu: identifikovať a rozbehnúť všetok pripojený HW (aj ovládače od Steamu);
  Netmanager spolu s ním spravuje všetky siete, sieťové zariadenia a vzdialené pripojenia — TV, sieťové rádio,
  telefóny cez Bluetooth, Wi-Fi, USB alebo na diaľku. Inšpektor siete (hotový základ, podľa ESET Network Inspector).
- [ ] Všetky rizikové zmeny ovládačov, obrazovky a napájania musia mať potvrdenie, časový limit
  alebo obnovovaciu cestu.

##### R3·F — App Manager, Barista a inštalácia softvéru

**Cieľ:** inštalácia, aktualizácia a odstránenie aplikácií je jednotná, kontrolovateľná a
obnoviteľná naprieč Fedora/RPM, Flatpak, webovými aplikáciami, hrami a podporovanými cudzími balíkmi.

- [x] App Manager má základ obchodov/zdrojov, komunitné obchody, oprávnenia a NET, hodnotenia,
  aktualizácie a viditeľné úlohy pre jeho vlastné operácie.
- [ ] Doplniť spoločný prehľad úloh aj pre systémové príkazy (dnf, Flatpak, cargo, Waydroid,
  umu), vrátane stavu, logu a výsledku po reštarte.
- [~] Barista: analýza a plán bez AI sú hotové; pokračovať inštaláciou a skúškou aplikácie,
  registrom, odinštalovaním a zálohou podľa fáz v `docs/barista/NAVRH.md`.
- [ ] Overiť, že úlohy možno bezpečne prerušiť, logy sú dostupné používateľovi a stav po reštarte
  nezostane falošne „úspešný“.
- [ ] App Manager je obchod, bazár a inštalátor Linuxových aplikácií (Flatpak) a aktualizátor všetkého softvéru
  aj ovládačov HW; Barista je jeho súčasť. Barista po zacielení na súbor alebo priečinok rozpozná typ (jeden či
  viac obrazov CD/DVD, delené archívy, portable priečinok, rozbalený inštalátor, XAPK, DOS) podľa internej
  databázy, ktorú treba vybudovať; spolupracuje s Protonom, experimentmi v tejto oblasti, F-Droid 2 a Lepton.
  Zámer: od malých vecí po veľké — dnes Windows a Android (E).
- [ ] Predvolené katalógy a recepty musia mať overiteľný zdroj, licenciu a kontrolu integrity;
  katalógy, ktoré spúšťajú skripty, sa nesmú považovať za dôveryhodné iba podľa vzhľadu.

##### R3·G — AI a vývojové nástroje

**Cieľ:** AI je voliteľná schopnosť systému s jasne oddeleným lokálnym/cloudovým spracovaním a
bez nečakaného prístupu k systémovým akciám.

- [ ] Dokončiť `latte-ai` a UX v LensGoo/Nastaveniach: poskytovatelia, prihlasovanie, modely,
  streamovanie, prílohy, hlas, spotreba a limity podľa toho, čo daná služba skutočne poskytuje.
- [ ] **Voľba AI na začiatku inštalácie (rozhodnuté 9. 10.):** úvod inštalátora ponúkne výslovné zapnutie alebo
  vypnutie AI; vypnutie znamená, že sa AI nástroje neinštalujú ani nespúšťajú a LensGoo nemá AI režim.
  Kedykoľvek zmeniteľné v Nastaveniach; text voľby je preložiteľný a bez nátlaku na jednu stranu.
- [ ] LensGoo: podpora všetkých spôsobov pripojenia AI — oficiálne nástroje účtov, integrovaný Instruct model a
  lokálny server (napr. LM Studio); prehľad spotrebovaných a zostávajúcich tokenov.
- [ ] Zviditeľniť, kam odchádza požiadavka, čo sa posiela a či je odpoveď lokálna alebo cloudová;
  pri cloudových poskytovateľoch rešpektovať súhlas a podmienky služby.
- [ ] Ak AI dostane nástroje na správu LatteOS, použiť obmedzené rozhranie, náhľad plánovanej
  zmeny, výslovné potvrdenie a auditovateľný výsledok; online webový chat nedostáva systémové
  oprávnenia.
- [ ] Vývojová AI farma a MCP sú vývojárske nástroje, nie predvolená súčasť používateľskej plochy;
  ich úlohy, tajomstvá a prístup k repozitáru držať oddelene od runtime AI LatteOS.

##### R3·H — Bezpečnosť, súkromie a obnova dát

**Cieľ:** bezpečnosť je vlastnosťou každej etapy a každej oblasti, nie samostatný doplnok na konci.

- [x] Profily dôvery, D-Bus filter, NET pre Flatpak/natívne aplikácie a odpojenie existujúcich
  spojení sú implementované podľa F6.
- [ ] Doplniť sieťové profily pre Wine/Proton scenáre a podporované skripty; overiť izoláciu
  každej novej cesty spúšťania.
- [ ] Pri integráciách kontrolovať licenciu, pôvod, oprávnenia, aktualizácie, sieťový prístup a
  spôsob uloženia tajomstiev pred ich prijatím do systému.
- [x] Záloha domovského priečinka a vrátenie späť pri zmene nastavení sú implementované.
- [ ] Overiť obnovu používateľských dát a profilov v ďalších scenároch; pred ničivou akciou
  ukázať rozsah a cieľ.
- [ ] Voliteľné skeny či bezpečnostné nástroje nesmú sľubovať úplnú ochranu; zobrazovať limity,
  možné falošné poplachy a vyžadovať súhlas so zberom/analýzou dát.

##### R3·I — Hry a externé prostredia

**Cieľ:** herná relácia a cudzie aplikácie sú integrované bez oslabenia bežného desktopu alebo SAFE.

- [ ] Dokončiť Steam/Proton/umu a Barista herné scenáre na podporovanom skutočnom GPU; vo VM
  zachovať iba primerané smoke testy.
- [ ] Overiť prechod Desktop ↔ Hra, návrat profilu výkonu, zvuku, okien a nastavení po skončení hry.
- [ ] Lepton/Android hry, gvisor, scrcpy a ďalšie externé technológie zostávajú samostatnými
  rozhodovacími bodmi; do produktu prejdú iba po teste prínosu, kompatibility, bezpečnosti a údržby.

##### R3·J — Nastavenia, vzhľad a tapety

**Cieľ:** jedno miesto pre nastavenia LatteOS (Goo, výkon, jazyk, účty, AI, tapety) bez konkurenčných
nastavení Noctalie a ostatných prostredí.

- [x] Základ Nastavení LatteOS, stránka Kvapky (Goo), profil používateľa a nastavenia podľa prostredia existujú; pozri F3 a F3·G.
- [ ] Selektívne zlúčiť vybrané nastavenia Noctalie (návrh v LATTEOS-GOO §4.10) a tapety na jedno miesto.
- [ ] Integrovať skwd-wall v našej podobe (rozhodnuté 9. 10.): výber tapiet, živé tapety, prechody; voliteľná vrstva, v SAFE vypnuté (R3·B).
- [ ] Jazyky a preklady, efekty a výkon: dokončiť podľa R3·B; AI a limity podľa R3·G.

#### R4 — Integrácia do jednej LatteOS

**Výsledok:** pracovné prúdy spolu fungujú ako jeden systém, nie iba ako samostatné aplikácie.

- [ ] Overiť celý tok: inštalácia → boot → SAFE/NORMAL → prihlásenie → načítanie profilu →
  Goo/Noctalia/Hyprland → aplikácie a zariadenia → odhlásenie → ďalší štart.
- [ ] Zjednotiť prenos stavov medzi shellom, systémovými službami a aplikáciami: úlohy, oznámenia,
  nastavenia, témy, profily, povolenia a diagnostika majú jedno miesto pravdy.
- [ ] Otestovať pády komponentov jednotlivo: engine, shell, kompozitor, služba, aplikácia, úložisko,
  sieť a aktualizácia. Zlyhanie jednej časti nesmie bezdôvodne znefunkčniť celý systém.
- [ ] Doplniť medzery medzi UI a backendom: každá akcia má viditeľný priebeh, výsledok alebo chybu;
  žiadne tiché zlyhanie ani úspech bez vykonanej operácie.

#### R5 — Overenie a pripravenosť produktu

**Výsledok:** LatteOS je opakovateľne inštalovateľný a použiteľný v deklarovanom rozsahu.

- [ ] Udržiavať testovaciu maticu: VM bez GPU (NORMAL aj SAFE), fyzický AMD, fyzický NVIDIA,
  viac monitorov, malé rozlíšenie, pomalší/starší hardvér, Secure Boot, odpojená sieť a slabé
  úložisko.
- [ ] Každý pracovný prúd má funkčné testy svojho backendu a používateľské scenáre; integrované
  scenáre kontrolujú spoluprácu medzi systémom, shellom a aplikáciami.
- [ ] Opakovať merania CPU/RAM, štartu, odozvy a grafických efektov po zmenách; stanoviť limity
  pre NORMAL a SAFE a regresné porovnanie.
- [ ] Vykonať bughunt a ergonomickú skúšku s myšou aj klávesnicou; skontrolovať preklady, kontrast,
  stavové hlásenia, poškodenie/obnovu dát a aktualizáciu.
- [ ] Overiť čistú inštaláciu z presne toho stromu/obrazu, ktorý sa bude vydávať; vývojová VM
  sama osebe nie je dôkazom pripravenosti vydania.

#### R6 — Vydanie, podpora a údržba

**Výsledok:** vydaná verzia má reprodukovateľný obsah, známe obmedzenia, dokumentáciu a bezpečnú
cestu k aktualizácii alebo návratu.

- [ ] **Definícia LatteOS 1.0 „Arabica“:** ciele z prezentácie (E) a testy z [bughunt/STRESTEST.md](bughunt/STRESTEST.md)
  spojiť do jedného zoznamu brán (STRESTEST sa plní postupne podľa blízkosti k 1.0); prístupnosť patrí do Arabicy. Marketingové tvrdenia (Barista „čokoľvek“, AI voľba
  v inštalátore, Nervboot) sa nepíšu ako hotové, kým ich brána neoveri.
- [ ] Pred vydaním uzavrieť rozsah, verziu, zmeny, licencie/tretie strany, inštalačný zdroj,
  kontrolné súčty a skúšku obnovy.
- [~] Nový dvojjazyčný README (EN/SK) z autorovho opisu je v `setup/verejne/README.md` (9. 10.; zverejní ho `zverejnit.sh` na pokyn). Po premenovaní kvapiek (E) prepísať názvy GooBar → BarGoo, GooPower → PowerGoo; AI voľbu pri inštalácii nesľubovať ako hotovú.
- [ ] Zaznamenať podporovaný hardvér, známe problémy a postup diagnostiky bez zverejnenia
  súkromných údajov alebo tajomstiev.
- [ ] Po vydaní triediť hlásenia podľa závažnosti, reprodukovať ich, opraviť a overiť regresiu;
  bezpečnostné aktualizácie a obnova majú prednosť pred novými efektmi.
- [ ] Prenos účtu/relácie a cloudová služba sa rozvíjajú až po stabilnom lokálnom produkte;
  používateľ musí vedieť fungovať bez nich.

#### R7 — Neskorší systémový smer

- [ ] Fedora Atomic/bootc a systémový rollback zaradiť až po splnení požiadaviek pôvodnej fázy A:
  stabilné pracovné prúdy, reálny HW, inštalácia, aktualizácia, obnova a testovací proces.
- [ ] Vlastný bootloader podľa nervboot, mobilná LatteApp, pokročilá bezpečnostná analytika a
  ďalšie veľké rozšírenia zostávajú návrhmi, kým neprejdú R0–R1 a nedostanú miesto v etape.
- [ ] Každé neskoršie rozšírenie zachová základné pravidlo: LatteOS musí zostať použiteľný vo VM
  bez GPU; akcelerácia pridáva efekty, nie nevyhnutnú funkčnosť.
