vytvorene 22.10.2026
naposledy upravene 27.10.2026
# LatteOS:0.4 Jihlavanka Build

Idea LatteOS je neziskový linux ktory nevyžaduje po uživatelovy znalost klavesovych skratiek, nevyžaduje po uživatelovy použivanie konzoly, a umožnuje mu fungovat s návikmy z Windows, MacOS ale aj linux. Je to OS ktory umožnuje totalne deaktivovat Ai služby vnutry, ale aj ich naopak, intenzivne využivat na urovni pomocnika OS. 
Idea pre tvorbu:
-Ked už inečo existuje, prezentovat to a ak je to dobré a schvalene, použit to. 
 Ked niečo už existuje, je funkčné, obľúbené a správne (napr. klon Total Commandera s úplnou kópiou schopností pod otvorenou
 licenciou), netreba písať tisíce riadkov kódu: aplikáciu prevziať, prispôsobiť, rozšíriť a autora uviesť v credits
 (`TRETIE-STRANY.md`). Podmienka: licencia to dovoľuje.
-Realizaciu dotahovat do konca. nespokojit sa s funkčnostou len naoko.
-Novinky. inšpirovat sa novinkamy. intenzivne patrat po nových trendoch.
-Moderne krasne pritažlive prostredie. 3E. Esteticke, Efektivne, Ergonomické
-Lepši a bezpečnejši než Win11. Lepší a praktickejši než Linux. 
-Pre hračov a použivatelov nezvyklych na linux.

Nasleduju kategorie. a ich opis. Jednotlive doplnkove napady sa budu doplnat ako bod pod kategorie (napr 1.01. [x] doplnkova idea k Kernel). Podkategorie budu zase čislene (1A) [x]` `[~]` `[ ] značky na hotovo, čiastočne, nezačate. 
Samotne latteOS sa značkuje:
LatteOS:0.x Jihlavanka
LatteOS:1.x Arabica
LatteOS:2.x xxx


---

# Ako s týmto súborom pracovať

- Adresa úlohy je jej ID (napr. 6F.03, 10A.01). Úloha je riadok s ID a všetko pod ním po ďalšie ID. Vyznač jeden riadok s textom pod ním
  (alebo celú kategóriu) a daj ho novému oknu. Claude pracuje z výberu a celý súbor nečíta; kontext kategórie nájde cez
  `grep -n '^##* 6F\. ' ROADMAP.md` (hlavička s opisom a zdrojmi).
- Hotové veci sú zhrnuté v jednom riadku. Plné znenie pôvodnej roadmapy: `git show b375aa2:ROADMAP.md` (r. N–M pri položke sú riadky tam).
  Rozpracované a otvorené veci, aj všetko neoverené, sú tu doslovne.
- Nový nápad: nové ID na koniec príslušnej kategórie. Značky: [x] hotové · [~] rozpracované · [ ] otvorené · (pozn.) poznámka.
- Poradie vývoja: kategórie 1–15, potom 17 Optimalizácia, nakoniec 18 STRESTEST.
- Stav testov: `python3 bughunt/stav.py`. Pravidlá plochy: `LATTEOS-GOO.md`. Denník rozhodnutí: `docs/goo/ROZHODNUTIA.md`.

---

# Poradie práce

Určené 22. 10. 2026 (nahrádza bývalé „Teraz“ z 12. 10.). Ide sa zhora, neskáče sa; nový nápad na koniec svojej kategórie, nie sem.
Poradie drží tri pravidlá: **čo blokuje overovanie ostatného ide prvé** (štart, SAFE, obrazovky), **plocha pred aplikáciami**,
**aplikácie podľa Priority UX** (zvyky z Windowsu, softvér zo zoznamu záujmov), a nakoniec Optimalizácia a STRESTEST.
Číslo v zátvorke je ID kategórie; podrobnosti sú pri nej.

Hotové body sa z poradia vyškrtávajú (ostávajú zapísané pri svojej kategórii); čísla ostatných sa nemenia, odkazuje sa na ne.

**Fáza 2 — Plocha Goo**
  5. [~] Dokončenie kvapiek: BarGoo, LensGoo (vzhľad), PowerGoo, ClockGoo, QueenGoo, QuickGoo, TrayShore (Pobrežie), LensShore — (6A–6E, 6G, 6H)
  6. [~] Režimy okien: Glance (náhľady v Parkingu), hyprtrizone pre ultrawide — (8A)
  7. [~] Plocha: ponuka plochy (Späť, „Tento počítač“), tapety a skwd-wall, hladina na spodku okna — (7A, 7B, 8D)

**Fáza 3 — Vzhľad a Nastavenia**
  8. [~] Vzhľad a témy: Keramika, Hliník, Onyx, Steam, dlaždicové rozloženie podľa Vitreusu — (9A)
  9. [~] Nastavenia: 11 chýbajúcich stránok (Zálohovanie, Cloud, Bluetooth, Tlačiarne, Heslo, Oznámenia…) — (9)

**Fáza 4 — Aplikácie (Priorita UX)**
 10. [~] Barista s AVP2 a sprievodca — (10I)
 11. [~] AppManager: úlohy a história — (10H)
 12. [~] DualBrew — (10A)
 13. [~] LatteMonitor — (10D)
 14. [~] DeviceManager — (10E)
 15. [~] NetManager: pokročilý detektor siete — (10G); hneď po ňom CamGoo (domáce kamery) — (6F)
 16. [~] **Kalendár: všetky funkcie Google Kalendára, dizajn ostáva** — (10J)
 17. [~] LensAI: lokálne modely, asistent v textových poliach, hľadanie podľa významu — (10B)
 18. [ ] Heidelberg — (10C)
 19. [ ] Hry — (10K)
 20. [~] Bezpečnosť a Úložisko: záloha dát, zaplnenie diskov, oddiely — (11, 2C)

**Fáza 5 — Núdzová relácia, inštalácia a vydanie**
 21. [ ] SafeGoo a Relácie: ovládanie okien na labwc, diagnostika pádu, okná po páde kompozitora — (5, 5A); vyvíja sa až tu, tesne pred inštalátorom
 22. [ ] Boot ako súčasť inštalátora: GRUB/SAFE položky, `latte-boot`, Plymouth — (3)
 23. [ ] Inštalátor, voľba AI, prvé spustenie (kvapky sa predstavia) — (2, 2A, 2B)
 24. [~] Build a vydania: Fresh → `main` 0.4.0, README, brány Arabica — (14)
 25. [ ] Preklady: záverečná kontrola úplnosti — (12)
 26. [ ] Fyzikálne prostredie kvapiek — až po zmeraní Fresh na hardvéri — (6)

**Fáza 6 — Záver**
 27. [ ] **Optimalizácia** — zrýchlenie načítania, zmenšenie na úložisku, nižšia náročnosť na hardvér, bez obmedzenia výsledku — (17)
 28. [ ] **STRESTEST** — úplne posledný — (18)

**Čaká a nie je v poradí:** ChatGoo — Beeper nie je na latte-lab, nedá sa overiť (6I) · Návrhy kvapiek, kým ich autor neprijme (6L) ·
Prístupnosť až v Arabice 1+ (13) · Atomic/bootc, Nervboot, LatteApp (1C, 3, 19).

---

# Kategórie

---

## 1. [~] kernel a zakladny jazyk
aktualne linux fedora 44 server. hyprland a pleamar.
po dokončeny latteOS gui bude na rovnakom zaklade vytvoreny atomic ako Bazzite. Možnost neskorej. Vytvorit api rozhranie, ktore ponukne funkčnost LatteOS nad akýmkolvek kernelom.

### 1A. [x] Hyprland
Kompozitor Hyprland 0.56 s Lua vrstvou: okná, režimy, skratky, stupne výkonu, herný režim.

**1A.01** [x] (Okná) Hyprland pre GOO · r. 76–77

### 1B. [x] Pleamar
Jazyk a engine pleamar, naše záplaty (`patches/`), skill `pleamar`, `pleamar --check`.
Zdroje: `patches/`, skill `pleamar`

**1B.01** [x] (Pleamar) Fresh c) pleamar 0.3.2 · r. 44–49

**1B.02** [x] **pleamar 0.3.2** (12. 10.): záplaty prenesené a uložené v `patches/` (päť súborov podľa témy, každý sedí
  na čistý `v0.3.2` samostatne; popis v `patches/README.md`). Farby 8 bitov má už autor sám, tá časť odpadla.
  Preložené v `~/src/pleamar-0.3.2`, nainštalované ako `/usr/bin/pleamar` (jazyk 0.4); pôvodný je
  `/usr/bin/pleamar-0.2.29`. Overené: nové aj staré scény prejdú `--check`, nové prihlásenie aj starý engine sa
  na neviditeľnej obrazovke kreslia rovnako ako na 0.2.29 (rozdiel do 9 z 255). **Neoverené:** starý engine
  v skutočnej relácii Hyprlandu na novom pleamare (záťaž, sklo, zoznam okien).

### 1C. [ ] Atomic / bootc
Neskôr: obraz ako Bazzite, rollback.

**1C.01** [ ] (Neskôr) R7 — Atomic/bootc a rollback · r. 1181–1182

**1C.02** [ ] Fedora Atomic/bootc a systémový rollback zaradiť až po splnení požiadaviek pôvodnej fázy A:
  stabilné pracovné prúdy, reálny HW, inštalácia, aktualizácia, obnova a testovací proces.

---

## 2. [~] Instalator OS
Zdroje: `fresh-install`, `install`, `migrate-v03`, `docs/NAVRH-STARTU.md`
ak bude možnost. latteOS bude dostupne ako LiveUSB system, pripadne presne ako https://github.com/omacom/try-omarchy-windows . čiže try-latteos-windows
instalator samotny bude barista(easy instalation) ktory prevedie uživatelma krokmy, pre pohodlnu inštalaciu bez nutnosti poznat linuxove terminy, diskove struktury. samozrejme pre pokročilych uživatelov su možnost zadat udaje ručne(advanced instalation). 
Barista instalator OS je prva prezentacia baristu ktory bude mat v hotovom systeme vlastnu ulohu (viď sekciu nativne app)  

**2.01** [ ] je nutnost ponuknut aj možnost instalacie ako dualboot. 

**2.02** [ ] preverit možnost instalacie na obsadeny disk (ntfs) bez straty povodnych dat.

**2.03** [ ] (Inštalátor a prvé spustenie) Inštalátor so sprievodcom · r. 293–307
[ ] **Inštalátor so sprievodcom (provizórny, rozhodnuté 13. 10.)** — grafické UI s Baristom, kroky ako pri inštalácii
   Fedory: jazyk a klávesnica, disk (automaticky a pár predvolieb; /boot, /, /data, formát, veľkosti), účet, AI áno/nie
   (bez nej sa prvky AI nezobrazia; s ňou model podľa GPU a RAM sa sťahuje počas inštalácie), káva a šálka (odtieň kvapiek
   a okien), výber súčastí od autorov.   
   **Úložisko (používateľ, 21. 10.):** inštalátor neurobí iba `/boot`, `/` a `/data`, ale ponúkne aj **domovské
   priečinky** — kde budú (na `/data`, vlastný oddiel `/home`, alebo priečinky Dokumenty, Obrázky, Hry… presmerované
   na `/data`) a koľko miesta ktorý oddiel dostane. To isté musí vedieť aj **Nastavenia › Úložisko** neskôr, lebo
   používateľ sa často preráta: zväčšiť oddiel do nerozdeleného miesta, presmerovať domovské priečinky (xdg-user-dirs),
   ukázať, čo kde zaberá. Prečo `/data` zvlášť: systém (`/`) sa dá preinštalovať alebo sformátovať bez straty
   dát; snímky systému (snapper) nedržia osobné súbory; dáta môžu mať iné nastavenia (bez snímok, iný formát). **Provizórny:** kroky Fedory sú vypísané, ale neaktívne (Fedora Server na latte-lab
   už je); aktívne je to, čo je LatteOS. Beží priamo na latte-lab (cez ssh, nie vo VM), nad `./install` a `FILES`;
   starý v0.3 sa z latte-lab odoberie a nainštaluje sa 0.4 Fresh. Live USB: režim GOO alebo SAFE rozhoduje už dnešné
   `latte-boot` (predštartová identifikácia), obraz ju musí niesť; ostáva ju posilniť a skúsiť. Základ Fedora/Atomic: zatiaľ jedno.
   *Pred odobratím v0.3:* snímka snapper, záloha nastavení používateľa, kroky sa zapíšu a overia suchým `./install`.

**2.04** [ ] (Inštalátor a prvé spustenie) R2 — inštalátor a prihlasovanie · r. 927–930

**2.05** [ ] Inštalátor: úvodná obrazovka s voľbou AI zapnúť / vypnúť (R3·G). Prihlasovanie: prepnutie do SAFE alebo
  iného nainštalovaného shellu (KDE, GNOME, čistá Noctalia…); SAFE nesie sadu nástrojov na zistenie, čo sa pokazilo.

### 2A. [ ] Prvé spustenie
Po prvom prihlásení sa kvapky predstavia.

**2A.01** [ ] (Inštalátor a prvé spustenie) Prvé spustenie — kvapky sa predstavia · r. 375–379
[ ] **Prvé spustenie — kvapky sa predstavia** (používateľ, 20. 10., z /plan-ceo-review). Po prvom prihlásení
    sa kvapky postupne nadvihnú a každá krátko povie, čo je a čo robí ľavý a pravý klik; preskočiteľné, dá sa
    pustiť znova (Nastavenia). Poradie: **QueenGoo → PowerGoo → LensGoo → BarGoo**, potom ostatné na ploche.
    Na konci jedna veta, že každú kvapku možno ťahaním presunúť inam. Texty cez preklady, ide myšou aj
    klávesnicou. Hodí sa pred prezentáciou na Reddite (prví cudzí používatelia).

### 2B. [~] Voľba AI
Úvod inštalácie ponúkne výslovne AI zapnúť alebo vypnúť (sľub, nie iba nastavenie).
**Spresnené 27. 10.:** vypínač sa týka **generatívnej AI** (odpovede, texty, obrázky, rozhovor, konanie za používateľa),
proti ktorej časť ľudí protestuje. Negeneratívne miestne rozpoznávanie (hľadanie podľa obsahu — DigUp 10B.32,
triedenie fotiek, čítanie textu zo snímok) pod neho nespadá; text voľby preto hovorí o generatívnej AI.

**2B.01** [x] (Inštalátor a prvé spustenie) E. AI — voľba na začiatku · r. 770–773
- [x] **AI — voľba na začiatku (rozhodnuté 9. 10.):** používatelia sa delia na priaznivcov a odporcov AI, preto
  **úvod inštalácie LatteOS ponúkne výslovnú voľbu AI zapnúť / vypnúť** (ide o sľub, nie iba nastavenie).
  Kedykoľvek ju možno zmeniť v Nastaveniach. Pri vypnutí AI sa neinštalujú a nespúšťajú AI nástroje, LensGoo nemá
  AI režim a nič neodchádza na AI služby. Úlohy sú v R2 a R3·G.

**2B.02** [ ] (Inštalátor a prvé spustenie) R3·G — voľba AI na začiatku inštalácie · r. 1074–1076
- [ ] **Voľba AI na začiatku inštalácie (rozhodnuté 9. 10.):** úvod inštalátora ponúkne výslovné zapnutie alebo
  vypnutie AI; vypnutie znamená, že sa AI nástroje neinštalujú ani nespúšťajú a LensGoo nemá AI režim.
  Kedykoľvek zmeniteľné v Nastaveniach; text voľby je preložiteľný a bez nátlaku na jednu stranu.

### 2C. [~] Úložisko a oddiely
`/`, `/boot`, `/data`, domovské priečinky, zaplnenie diskov, zväčšenie oddielu.

**2C.01** [~] (Úložisko) Zaplnenie diskov na očiach · r. 380–383
[~] **Zaplnenie diskov na očiach** (používateľ, 20. 10., po zistení, že na `/` latte-lab ostalo 5,5 GB z 120 GB).
    DualBrew v bočnom paneli pri každom disku a oddiele pás zaplnenia (použité / voľné, farba pri nedostatku),
    Správca zariadení pri diskoch to isté grafom aj s nerozdeleným miestom na disku; upozornenie, keď voľné
    miesto klesne pod hranicu. latte-lab: za `/data` je ~132 GB nerozdelených.

---

## 3. [~] Boot
Rozhodnuté 22. 10.: Boot sa vyvíja ako súčasť inštalátora (poradie krok 22), nie samostatne.
Zdroje: `crates/latte-boot`, `crates/latte-hw`, `system/` (boot.toml, plymouth, kernel-install), `docs/NAVRH-STARTU.md`
https://codeberg.org/GuillotineMelody/nervboot Bootloader UEFI v Ruste so štylizovanou ponukou štartu (MAGI z Evangelionu); nenahrádza
    systemd-boot, iba pred neho predradí vlastnú ponuku a jadro nechá naň (počítanie štartov, TPM ostávajú), inšpirácia na vlastnú ponuku štartu v štýle LatteOS pre dualboot do windows. 

**3.01** [~] (Boot a štart) Štart · r. 19–27
[~] **Štart (R2).** Opravené a overené reštartom 12. 10.: čakanie na sieť (prihlasovanie 99 s → 36 s, celý štart
   3 min 37 s → 1 min 12 s), rohová lišta po prihlásení (+8 s, sama), žiadna zlyhaná služba. Test grafiky pri
   studenom štarte vyprší zámerne (pomalý disk, rozhodne ovládač) a prihlasovanie nezdržuje — nie je chyba; zvyšných
   ~25 s je disk a `gssproxy`. Pád Hyprlandu pri konci relácie `latte-session` rozpozná; pri reštarte 12. 10. nenastal.
   Overené pádmi 12. 10.: engine sa po páde sám obnoví (doplnené), Hyprland sa po páde spustí znova, druhý pád
   do 60 s prepne do SAFE, SAFE zvolený aj automatický funguje a čisto končí.
   **Ostáva:** klik na Reštartovať · Vypnúť v PowerGoo (test 036), zlé heslo a jazyk na prihlásení (541), prečo
   núdzové rozhranie po páde berie ~2 jadrá (010), okná sa po páde kompozitora nevrátia (006), testy 003–005, 007–008.
   *Hotovo, keď:* testy 001–012, 036, 541, 550 majú stav. Po každom štarte: `old/setup/test/start.sh` (predošlý: `-1`).

**3.02** [x] (Boot a štart) Fresh d1) štart po prihlásenie · r. 51–58
[x] **štart po prihlásenie** (12. 10.): `crates/latte-hw`, `crates/latte-boot`, `system/` (služba, greetd, labwc
   prihlasovača, položky SAFE v GRUB-e, Plymouth), `bin/latte-greeter`, `bin/latte-login`, `bin/latte-sky`,
   `goo/login.plm` + `login.luau`, preklady `goo/lang/sk.plm`, vlastné písmo ikon. Oproti starému: úvod riadi
   scéna (logika iba povie „začni“), heslo ide na vstup príkazu (nie cez súbor), čas zo služby `clock`, rozloženie
   klávesnice zo systému, bez Noctalie. Odpadlo: prihlasovač v QML a Noctalie (bez grafickej karty je zatiaľ
   textové prihlásenie `tuigreet`), `vm-3d`, zápis `hyprland.conf`. Overené: `tests/check.sh`, scéna na
   neviditeľnej obrazovke (snímky, záznam priebehu, zlé a dobré heslo naskúšku). **Neoverené:** skutočné
   prihlásenie cez greetd — až po nasadení na latte-lab.

**3.03** [x] (Boot a štart) B. F0–F2 základ · r. 629–632

**3.04** [ ] (Boot a štart) D. štart a relácia · r. 684–685
- [ ] **LatteOS štart a relácia:** dokončiť tok čistej inštalácie → boot → prihlásenie → GOO/SAFE →
  obnova po zlyhaní; odlíšiť hotový F1 boot základ od nedokončeného SafeGoo a koncových testov.

**3.05** [~] (Boot a štart) F. R2 — základ a štart · r. 818–821
**R2 — základ a štart:** distribúcia balíkov, COPR (r. 201); grafická SAFE s `nomodeset`, systemd user relácia (r. 202);
Sunshine pred prihlásením, virtuálny monitor `[~]` (r. 318); prihlásenie — čierna sekunda, voľba prihlasovača v
Nastaveniach (r. 468); greenboot + Automatic Boot Assessment (r. 952); test „zaplniť RAM vo VM“ (r. 807).

**3.06** (pozn.) (Boot a štart) R2 — základ platformy · r. 913–915
**Výsledok:** čistá Fedora inštalácia vie bezpečne naštartovať do použiteľnej relácie a má spoľahlivý
základ, na ktorý sa dajú integrovať ostatné pracovné prúdy.

**3.07** [x] (Boot a štart) R2 — F0–F2 · r. 916–918

**3.08** [ ] (Boot a štart) R2 — overiť tok po prechode na GOO · r. 919–921
- [ ] Overiť celý aktuálny tok po prechode na GOO: čistá inštalácia → boot → GOO prihlasovanie →
  predvolená Goo relácia → SAFE po zlyhaní → návrat do NORMAL; osobitne potvrdiť, že verejný
  vydaný strom obsahuje a spúšťa správne relácie.

**3.09** [ ] (Boot a štart) R2 — čistá inštalácia a obnova · r. 924–924
- [ ] Overiť čistú inštaláciu, prvé spustenie, aktualizáciu a obnovu po neúspešnom štarte.

---

## 4. [~] Greeter a prihlásenie (LoginGoo)
Zdroje: `goo/login.plm`, `goo/login.luau`, `goo/login-safe.plm`, `goo/lockscreen.*`, `bin/latte-greeter`, `bin/latte-login`, `bin/latte-lock`, `system/greetd`, `system/greeter`, `goo/shaders/water.wgsl`; LATTEOS-GOO §6.2
zavedenie systemu a prihlasovacia obrazovka dizajnovo takmer finalna verzia. 

**4.01** [x] (Greeter a prihlásenie (LoginGoo)) zámok obrazovky · r. 82–85

**4.02** [ ] (Greeter a prihlásenie (LoginGoo)) E. prihlasovanie · r. 783–784
- [ ] **Prihlasovanie:** výber relácie (SAFE, iné shelly) je v scéne iba „vývojárska verzia“; v README
  opísať ako dostupný iba po overení.

**4.03** [x] (Greeter a prihlásenie (LoginGoo)) Prihlasovacia obrazovka podľa predstavy (skutočné prihlásenie, zlé heslo, jazyk a klávesnica overil používateľ 26. 10.) · r. 1188–1225
[ ] **Prihlasovacia obrazovka podľa predstavy používateľa** (13. 10., `bughunt/najdene-chyby.md`; test 541 ukázal,
    že voľba jazyka a klávesnice na prihlásení **nie je**: rozloženie sa prepína iba naslepo Alt+Shift, jazyk vôbec).
    (a) [~] **Jazyk a rozloženie klávesnice klikom** na prihlásení (aj v SAFE), s ukazovateľom aktuálneho rozloženia
    — urobené 13. 10.: dve chipy vľavo od vypínacej kvapky (jazyk sa prepína za behu faktom `locale`; rozloženie
    cez nový štart prihlasovača, lebo labwc sa zvonka prepnúť nedá: `latte-login layout` → `latte-greeter`, Alt+Shift
    na prihlásení odpadol, aby ukazovateľ nikdy nklamal). Overené: dry run (kliky, snímka) a slučka
    `latte-greeter` s napodobeným labwc. **Neoverené:** skutočné prihlásenie po `sudo ./install --go`. Jazyk platí
    iba pre prihlasovaciu obrazovku, relácia berie systémový (Nastavenia › Jazyk a región);
    (b) Caps Lock / Num Lock ako text vznášajúci sa nad poľom hesla; (c) hladina v spodných 2/3, na dne
    premenlivé tiene (kávová usadenina); softvérové kreslenie = statická hladina; (d) kvapka z šálky Plymouthu
    dopadne a vlní hladinu; (e) pod hladinou posledný log z pádu, inak aktuality z RSS (zdroj v Nastaveniach;
    prístup k logu aj zvnútra systému, v SAFE aj NORMAL); (f) hore vľavo počasie, vpravo čas; (g) kurzor ako
    zdroj svetla, slnko a mesiac podľa skutočnej polohy; (h) výber relácií: LatteOS GOO, SAFE, SteamOS a iné GUI.
    **Urobené 13. 10.:** (b) Caps Lock a Num Lock z diód klávesnice (`latte-login locks`, kontrola po 0,7 s) ako
    vznášajúci sa text nad heslom; zdroj RSS, panel a miesto počasia v **Nastaveniach › Prihlasovacia obrazovka**
    (`latte-settings loginscreen`, miesto sa hľadá podľa mena cez open-meteo); (f), (g) a (h) už boli.
    Tiež (c) sedlina na dne (päť tmavých plochých tvarov, ktoré sa pomaly posúvajú), (d) dve vlny sa rozbehnú po
    hladine od miesta, kde kvapka vojde do kávy, a (e) **Nastavenia › Štart a režim SAFE › Posledný pád** (správa
    na skopírovanie; v SAFE je to položka 1 v ponuke). Bod 11 je tým hotový, ostáva overiť na skutočnom prihlásení.
    **Realnejšia hladina (13. 10., návrh používateľa; FlowLab = SPH, osgw = Gerstnerove vlny, OceanFFT = FFT oceán,
    všetko MIT, ale 3D/zhora, nie bokom):** urobené iba svetlo pod hladinou — vlastný shader
    `goo/shaders/water.wgsl` (lúče zo slnka alebo mesiaca šikmo podľa polohy, sieť kaustík pri hladine, slabšie
    v daždi, v softvérovom režime nič). Nevzali sme simuláciu (SPH, FFT): hladina je bokom čiara, ktorú tvorí telo
    goo, a FFT by bol predražený. **Možný ďalší krok:** profil hladiny ako súčet 3–5 Gerstnerových vĺn (trochoida
    je presne rez takou vlnou) namiesto dnešných siedmich „hrbov“, a lom lúčov podľa toho istého profilu.
    **Urobené 13. 10.:** hladina je súčet štyroch Gerstnerových vĺn (`WAVES` v `goo/gen.py` → `parts/waves.plm`,
    `parts/surface.plm`: 32 úsečiek v tele goo); shader `water.wgsl` ohýba lúče podľa sklonu tej istej hladiny,
    vypuklý hrebeň ich zbiera, šachty a kaustiky sú šum (nie pravidelný vzor — používateľ: „priveľmi symetrické“),
    a na dne sú vlnové vrásky piesku (nahradili päť tmavých elíps). SedFoam (OpenFOAM, CFD) a wavesed (pyReef,
    pobrežné sedimenty) sú simulácie na iný účel; zo sedimentu sa vzal iba obraz: rovnobežné vrásky, ktoré
    pomaly putujú smerom vĺn.
    **Počasie na hladine (13. 10.):** vietor z `latte-sky` (fakt `wind`, km/h → `gale`) dvíha a zostruje vlny
    a pridáva krátku piatu vlnu; pri daždi dopadajú kvapky na 9 miest hladiny (krúžok dvoch hrebeňov; pri snehu
    nie). Svetlo je jeden lom na tej istej hladine (jas = ako blízko sa zbehli susedné lúče), farba klesá od
    jantárovej k tmavočervenej (hustá kvapalina), na dne tmavé tvary sedliny a pod nimi vrásky piesku.
    Merané na RX 640: skladanie 1,0 ms, kreslenie 0,7 ms, 60 snímok/s. Výška vĺn je zámerne obmedzená, aby
    víchrica nezaliala riadok s heslom. (Neskôr 13. 10. na pokyn zrušené: vo víchrici sa vlna cez riadok preleje
    a odtečie; svetlo o polovicu slabšie.)

---

## 5. [~] SAFE latteOS
Rozhodnuté 22. 10.: núdzová varianta; vyvíja sa až tesne pred inštalátorom (poradie krok 21).
Zdroje: `goo/safe.plm`, `goo/safe.luau`, `bin/latte-safe`, `system/labwc`
je nudzovy system nenaročny, umožnujuci udržbu systemu. teoreticky použitelny ako primarny režim na velmi stary hardware. 

**5.01** [x] (SafeGoo) Fresh d2) SAFE a relácie · r. 59–67
[x] **SAFE a relácie** (12. 10.): `goo/safe.plm` + `safe.luau` (lišta: záťaž, ponuka napájania, terminál, riadok
   na písanie s režimami aplikácie a príkaz, okná, sieť, batéria; pozadie s časom), `bin/latte-safe` (záchranná
   ponuka; texty z toho istého `goo/lang/sk.plm`), `bin/latte-session` (GOO · SAFE · Game, strážca pádov),
   `bin/latte-game`, `crates/latte-stats`, labwc pre SAFE, tri položky relácií, statické prihlásenie
   `goo/login-safe.plm` pre softvérové kreslenie (VM, SAFE) so spoločnou logikou `goo/lib/login.luau`.
   Overené: `tests/check.sh` (aj strážca relácie s napodobenými programami), snímky na neviditeľnej obrazovke.
   **Zatiaľ chýba** (vráti sa s príslušným programom): zámok obrazovky, hľadanie súborov a AI v riadku, tlačidlá
   App Manager a Správca zariadení, profily prostredí (`latte-profil`), profil účtu (`latte-gooconfig`).
   Voľba GOO pri prihlásení skončí v SAFE s dôvodom „plná plocha nie je nainštalovaná“, kým nie je bod 3.

**5.02** [ ] (SafeGoo) SafeGoo · r. 236–255
[ ] **SafeGoo** — dokončiť podľa toho, čo ukáže bod 1 (ovládanie okien na labwc, diagnostika pádu).
   - **Diagnostika pádu podľa whyd** (schválené 13. 10.; [whyd](https://github.com/vmaltarello/whyd), Go, GPL-3.0,
     samostatný program): dnešný `last-crash.log` z `latte-session` zachytí iba pád Hyprlandu v tej istej relácii.
     whyd z žurnálu predošlého štartu rozpozná aj zamrznutie s tvrdým vypnutím, OOM, chyby GPU, zlyhané služby
     a prehriatie (pravidlá v TOML, správa so skrytými údajmi). Postup: (a) vyskúšať ručne na latte-lab
     (`whyd` po štartoch z bodu 1); (b) vlastné pravidlá pre `latte-session`, Hyprland, engine Goo a prepnutie do SAFE;
     (c) v SAFE položka „Prečo sa skončila minulá relácia“ — súhrn z `last-crash.log` a z whyd, správa na skopírovanie;
     (d) whyd ako voliteľná závislosť (balík rpm z vydaní, riadok vo `FILES` a v `TRETIE-STRANY.md`), bez neho ostane
     dnešný výpis. *Overiť:* či whyd vie aj aktuálny štart od času pádu (pád relácie bez reštartu), inak to ostáva na
     `latte-session`.
   **Urobené 13. 10.:** (a) whyd 0.1.1 vyskúšaný na latte-lab z balíka vydania (bez inštalácie): číta tento
   štart (`-b 0`) aj predošlé, takže pád relácie bez reštartu vidí tiež; (b) vlastné pravidlá
   `system/whyd/latteos.toml` (prechod do SAFE a prečo, pád a nový štart Hyprlandu, pád enginu Goo, rozhodnutie
   `latte-boot`) — `whyd rules test` prejde; `latte-session` píše to, čo ukončilo reláciu, aj do žurnálu
   (predtým iba do `session.log`, ktorý whyd nevidí); (c) `latte-safe why` a v ponuke SAFE položky **w** (prečo
   sa skončila minulá relácia: zápis LatteOS + whyd pre tento a predošlý štart) a **c** (to isté ako správa do
   schránky); to isté tlačidlo v Nastaveniach › Štart a režim SAFE; (d) whyd je voliteľný (`FILES`,
   `TRETIE-STRANY.md`), bez neho ostane zápis LatteOS. **Neoverené:** pravidlá SAFE a pádu na skutočnom páde
   (iba ich príklady); položky v ponuke SAFE naostro. whyd ukazuje začiatok relácie o 2 h posunutý (jeho chyba
   s časovým pásmom, nahlásiť autorovi). **Ostáva z bodu 4:** ovládanie okien na labwc — čo presne, ukáže bod 1.

**5.03** [x] (SafeGoo) C. rozhodnutie o SAFE · r. 653–655
- [x] **Rozhodnutie o SAFE:** plné SDF Goo je pri softvérovom kreslení príliš pomalé; SAFE preto
  používa jednoduché statické kvapky. Ide o stanovený smer, nie dôvod pokúšať sa nasadiť plný
  dynamický engine v pixman režime.

**5.04** [~] (SafeGoo) C. GOO / SAFE · r. 667–669
- [~] **GOO / SAFE:** existuje skúšobný SafeGoo so statickými kvapkami a nízkou spotrebou v
  softvérovom režime. Chýba dokončenie ovládania okien a potrebných kvapiek/diagnostiky a jeho
  zapojenie ako predvoleného SAFE shellu.

**5.05** [ ] (SafeGoo) R2 — dokončiť SafeGoo · r. 922–923
- [ ] Dokončiť SafeGoo ako použiteľnú záchrannú reláciu s potrebnými základnými ovládacími prvkami,
  diagnostikou a funkčným ovládaním okien na labwc; zachovať pixman/bez-GPU obmedzenia.

**5.06** [ ] (SafeGoo) R3·A — PowerGoo a SafeGoo · r. 951–952
- [ ] **PowerGoo a SafeGoo:** systémové akcie a indikátory v bežnej ploche; v SAFE zobrazenie
  príčiny, logov, diagnostiky a bezpečných možností obnovy.

### 5A. [~] Relácie
Relácia = to, čo sa spustí po prihlásení: GOO (plocha), SAFE (núdzová), Game (Steam + gamescope). Spúšťa ich `latte-session`, ten po páde obnoví reláciu alebo prepne do SAFE.
Zdroje: `bin/latte-session`, `bin/latte-guarddog`, `apps/guarddog.qml`, `system/systemd`, `system/whyd`, `system/oom`, `system/sessions`

**5A.01** [x] (Relácie a GuardDog) B. systémové rozhrania · r. 633–634

**5A.02** [ ] (Relácie a GuardDog) R2 — služby a pád relácie · r. 925–926
- [ ] Zabezpečiť, aby systémové služby štartovali až vtedy, keď sú potrebné, a aby ich pád nezhodil
  celú používateľskú reláciu.

---

## 6. [~] GooEngine
Zdroje: `goo/goo.plm`, `goo/parts/`, `goo/lib/`, `goo/gen.py`; LATTEOS-GOO §3–4, `docs/goo/`
je primarne HW vykreslovatelny engine simulujuci pravidla pre GooProstredie. gravitaciu, pohyb, efekty...zakladne univerzalne efektove prostredie nad ktorym cele GooProstredie funguje. 

**6.01** [ ] overit použitelnost pri čisto SW vykreslovanie GooEngine a ake score vykonu pc je nutne na chod pre sw, hw, alebo len safe latteOS. score počitania vykonu-zistit bežne metody. 

**6.02** [~] (GooEngine) Fresh d3) GooEngine — úvod · r. 68–72
[~] **GooEngine** — engine a jadro kvapiek, potom náhrada Noctalie (rohová lišta: tray, sieť, hlasitosť,
   ovládacie centrum; Nerušiť, akcie relácie, prehľad okien, účty kalendára — služby pleamaru `tray`, `network`,
   `audio`, `bluetooth`, `brightness`, `session`, `polkit` a stránky z Marey, BSD-3), aplikácie a príkazy, iba tie,
   ktoré GOO a SAFE potrebujú. Platí z 12. 10.: znak NET do GOO, náhľad okna nad ikrou, Kapsa a maskoti sa
   neprenášajú; kvapky sa premenovali (GooBar → BarGoo, GooPower → PowerGoo).

**6.03** [x] (GooEngine) engine · r. 73–75

**6.04** [x] (GooEngine) jadro kvapiek, prvá časť · r. 78–80
- [x] **jadro kvapiek, prvá časť** (12. 10.): BarGoo (hlava, ikry okien, ponuka okna), LensGoo (Aplikácie,
  Príkaz, rýchly zoznam), PowerGoo (karta: účet, odhlásenie, batéria, profil napájania, uspať · reštartovať ·
  vypnúť). Čo je a čo chýba: LATTEOS-GOO.md §8.

**6.05** [x] (GooEngine) ovládanie z klávesnice · r. 86–86

**6.06** [x] (GooEngine) Okno z bubliny (26. 10.): okno otvorené do 5 s po kliku na kvapku či riadok jej karty vyletí z nej ako bublina, nafúkne sa naň a praskne; zatvorené okno praskne (`goo/parts/bubble.plm`, `goo/lib/born.luau`, `latte/windows.lua` — pravidlo `latte-born` ho dovtedy drží neviditeľné). Overené snímkami na latte-lab (QueenGoo › App Manager).

**6.07** [x] (GooEngine) hra pri nečinnosti · r. 104–105

**6.08** (pozn.) (GooEngine) overenia 12.–13. 10. · r. 196–207
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

**6.09** [ ] (GooEngine) Fyzikálne prostredie kvapiek · r. 286–292
[ ] **Fyzikálne prostredie kvapiek** (rozhodnuté 13. 10.: neskôr, **až po zmeraní a otestovaní Fresh na hardvéri
   latte-lab**). Dnes majú kvapky jedny pravidlá a spoločné prostredie (gravitácia, hladina, vietor, pružiny), ale
   nepôsobia na seba silami: neprekrývanie počíta logika, gravitácia platí iba pri páde a skoku, okná nie sú súčasťou
   prostredia. Cieľ: hmotnosť, zotrvačnosť, vzájomné odpudzovanie a zrážky ako pravidlá scény, rovnaké pre každú
   kvapku (vzor fwm, R3·A). Znamená prepísať pohybovú časť `goo/parts/drops.plm` a presunúť neprekrývanie z
   `goo/lib/engine.luau` do scény; najprv zmerať cenu na snímku (dnešné pružiny: 24 % jadra pri 32 miestach).

**6.10** [x] (GooEngine) C. rozhodnutie o edícii · r. 647–649
- [x] **Rozhodnutie:** jediná edícia je LatteOS GOO; nasadzuje sa engine Goo (`session/goo`),
  pôvodná plocha Kvapky sa nenasadzuje. Pravidlá produktu sú v
  [LATTEOS-GOO.md](LATTEOS-GOO.md).

**6.11** [x] (GooEngine) C. rozhodnutia o správaní · r. 650–652
- [x] **Rozhodnutia o správaní GOO:** myš je prvá, klávesnica doplnok; cieľom sú návyky Windows 11;
  kvapky sú káva, Goo má vlastný vzhľad a karty vyrastajú z kvapiek. Podrobné záväzné pravidlá sú
  v [LATTEOS-GOO.md](LATTEOS-GOO.md), nie v historických Classic návrhoch.

**6.12** [~] (GooEngine) C. GOO / engine a plocha · r. 658–661
- [~] **GOO / engine a plocha:** jadro pravidiel kvapiek, BarGoo a správa okien, LensGoo, PowerGoo,
  QueenGoo, ClockGoo, karty, upozornenia, sklo a používateľské kvapky sú implementované v rôznom
  rozsahu a priebežne overované. Samotný engine ešte nie je hotový produkt; SafeGoo a ďalšie
  otvorené overenia sú uvedené nižšie. Detailný stav ostáva v F3·G.

**6.13** [x] (GooEngine) C. GOO / integrácia · r. 662–664

**6.14** [ ] (GooEngine) D. GooEngine · r. 686–688
- [ ] **GooEngine:** uzavrieť zdieľanie jednej logiky a dvoch vzhľadov NORMAL/SAFE; doplniť chýbajúce
  ovládanie okien v labwc, SafeGoo, beh monitorov pripojených za chodu, pokoj pri nečinnosti a
  meranie výkonu po rozšírení funkcií.

**6.15** [ ] (GooEngine) D. Goo kvapky · r. 689–690
- [ ] **Goo kvapky:** dokončiť konkrétne otvorené úlohy BarGoou, LensGoo, PowerGoo, ClockGoo,
  QueenGoo a ChatGoo. Ďalšie kvapky a vizuálne efekty posudzovať samostatne podľa prínosu a výkonu.

**6.16** [x] (GooEngine) E. názvoslovie kvapiek · r. 750–755
- [x] **Názvoslovie kvapiek (rozhodnuté 9. 10.):** predpona/prípona **„Goo“ je pripona a nesú ju iba kvapky v
  GooEngine**: BarGoo (dnes v kóde GooBar), PowerGoo (dnes GooPower), LensGoo, QueenGoo, ClockGoo, ChatGoo,
  LaunchGoo, LoginGoo. Neplatí pre samotný engine a plochu (GooEngine, LatteOS GOO) ani pre relácie (SafeGoo).
  V tejto roadmape ROADMAP2 sa už používajú nové názvy; **kód, dokumentácia a nastavenia sa zatiaľ nemenia**.
  Úloha na neskôr: premenovať v ~60 súboroch naraz s kontrolou `kvapky.json` používateľov (staré názvy čítať ešte
  jedno obdobie), potom prepísať README.

**6.17** [~] (GooEngine) F. R3·A — GooEngine a kvapky · r. 822–829
**R3·A — GooEngine a kvapky:** overiť skrytie voliteľnej kvapky (r. 432); živé bytosti — obmedzenie snímok pri nečinnosti (r. 433);
profil — programy čítajú dokument priamo (r. 466); overiť Odhlásiť a ClockGoo na 1024 × 768 (r. 470); pokrývky hlavy QueenGoo (r. 471);
BarGoo `reversed` a monitor pripojený za behu (r. 480); CPU enginu — meranie 6. 10. (r. 482); formulár vlastných kvapiek (r. 493);
kalendár ClockGoo — synchronizácia, názov budíka (r. 494), **prepracovanie podľa regiónu** (r. 618), indikátor Nerušiť (r. 623);
LensGoo — zvyšok (r. 498), **hĺbková kontrola** (r. 626), indexovanie častých priečinkov (r. 554); ChatGoo — Beeper, vtečenie okna, odznak (r. 645);
goo telo pod rohovou lištou (r. 501); deň a noc na hladine (r. 610), nočné svetlo `[~]` (r. 608); sady ikon (r. 669);
prístupnosť — zvyšok (r. 506).

**6.18** (pozn.) (GooEngine) R3·A — cieľ · r. 937–942
**Cieľ:** dokončiť predvolenú plochu LatteOS GOO ako súdržný engine a používateľský shell. Platné
pravidlá sú v [LATTEOS-GOO.md](LATTEOS-GOO.md), API a stav enginu v
[session/goo/README.md](session/goo/README.md), používateľské rozhodnutia v
[docs/goo/ROZHODNUTIA.md](docs/goo/ROZHODNUTIA.md).

**6.19** [ ] (GooEngine) R3·A — jadro GooEngine · r. 943–945
- [ ] **Jadro GooEngine:** jedna spoločná logika a API kvapiek, jasné hranice medzi enginom,
  scénou, pomocníkmi, kompozitorom a vzhľadom NORMAL/SAFE; zachovať kompatibilitu existujúcich
  kvapiek a nastavení.

**6.20** [ ] (GooEngine) R3·A — názvoslovie kvapiek · r. 953–953
- [ ] **Názvoslovie kvapiek:** rozhodnúť a jednotne premenovať (pozri E, rozdiely).

**6.21** [ ] (GooEngine) R3·A — pohyb, zvuk a efekty · r. 961–962
- [ ] **Pohyb, zvuk a vizuálne efekty:** zmerať cenu fyziky, skla, dažďa a reakcie na hudbu; efekty
  musia byť vypnuteľné a nesmú zhoršiť čitateľnosť, SAFE ani stupeň Softvér.

**6.22** [ ] (GooEngine) R3·A — brána dokončenia Goo · r. 963–966
- [ ] **Brána dokončenia Goo:** všetky základné úkony idú myšou; rozlíšenie najmenej 1024 × 768;
  funkčné okná/relácie na podporovaných monitoroch; overený výkon a bezchybný návrat po páde enginu.

**6.23** (pozn.) (GooEngine) vlnenie hladiny na ploche · r. 1226–1230
**Vlnenie hladiny na ploche (13. 10.):** v engine je hladina tesne pod spodným okrajom; kým ju niečo rozvíri
(dopad kvapky, dážď a poryvy pri nečinnosti — všetko cez `E.ripple`), zdvihne `swell` osem hrebeňov, ktoré
bežia popri okraji, a potom zasa zapadnú. Súčet Gerstnerových vĺn z prihlásenia sa neprevzal: stál 0,5 ms
na snímku aj v pokoji (skladanie 1,4 → 1,9 ms); hrebene ako ploché elipsy nestoja nič merateľné (1,4 ms).
Svetlo a sedlina na ploche nie sú — nie je tam hĺbka.

**6.24** [ ] **Výskum: knižnica efektov `shaders`** (používateľ 27. 10.) — https://github.com/shader-effects-inc/shaders
(MIT engine aj komponenty; editor a predvoľby na shaders.com majú vlastné podmienky). 200+ efektov: prechody farieb,
šum, sklo, kov, svetlo, deformácie, prechody, rozmazanie, efekty za kurzorom. Je to **WebGPU a WGSL** — rovnaký jazyk,
v akom už píšeme `goo/shaders/water.wgsl` pre pleamar, takže efekty sa dajú preniesť bez prekladu do GLSL (pre
Qt/QML a Hyprland cez `naga`). Kandidáti: sklo a kov pre témy (9A Keramika, Hliník, Onyx), prechody pri prepnutí
plochy, svetlo na hladine. Mladý projekt (41 hviezd, 10 commitov). Každý efekt zmerať na snímku a mať variant bez
shadera pre nižšie stupne výkonu. Pri prevzatí zápis do `TRETIE-STRANY.md`.

**6.25** [ ] **Audit hustoty informácií** (používateľ 27. 10.; pravidlo 24): spísať 20 najčastejších úkonov (stlmiť
zvuk, nájsť súbor, prepnúť okno, pripojiť USB, Wi-Fi, vypnúť, …), pri každom spočítať kliky a čas. Časté a dlhšie ako
dva kliky → o vrstvu vyššie; zriedkavé vo vrstve 0 → nižšie. Zaradiť každý prvok kariet kvapiek (najmä LensGoo,
ktorá hustne) do vrstvy 0/1/2. Päťsekundový test s človekom, ktorý LatteOS nepozná. Výstup: tabuľka na schválenie.

### 6A. [~] BarGoo
Zdroje: `goo/lib/bar.luau`, `goo/side.plm`; LATTEOS-GOO §4.1

**6A.01** [x] (BarGoo) pád minimalizovaného okna · r. 87–87

**6A.02** [x] (BarGoo) BarGoo na ďalších monitoroch · r. 90–93
- [x] BarGoo na ďalších monitoroch (13. 10.): vlastná scéna `goo/side.plm` na každom ďalšom monitore
  (`latte-goo-side@.service`), lišta ukazuje iba okná svojho monitora, pás pri okraji má každý monitor
  svoj; `latte-say` povie niečo všetkým scénam Goo. Overené s dvoma a troma monitormi bez obrazovky.
  Chýba prenášanie ikier medzi monitormi; každá ďalšia scéna stojí toľko čo hlavná (bod 5).

**6A.03** [x] (BarGoo) BarGoo: ikry iba v plávajúcom režime · r. 192–194
- [x] BarGoo: ikry iba v režime plávajúce (rozhodnuté a urobené 13. 10.) — v páske a dlaždiciach počet okien
  na hlave, ikry po postáti myši na hlave. Zvuk a žiadosť o pozornosť ukazuje okno samo pulzujúcim
  okrajom; hlava sa vlní iba za okno, ktoré nie je na očiach.

**6A.04** [ ] (BarGoo) R3·A — BarGoo a okná · r. 946–947 — **čaká, kým bude na latte-lab pripojených viac skutočných monitorov**
- [ ] **BarGoo a okná:** dokončiť chýbajúce správanie lišty, ovládanie okien v NORMAL aj SAFE,
  pripájanie monitorov za behu a nastavenia viacerých obrazoviek. Pripájanie za behu (`monitor.added/removed` →
  `latte-screens`) a Nastavenia › Obrazovky › Rozšíriť / Duplikovať už sú; overiť na skutočných monitoroch.
  Ovládanie okien v SAFE patrí do bodu 21 (5A). Samostatné kusy: 6A.06, 6A.07.

**6A.05** [ ] **BarGoo voliteľný, druhy plochy** (používateľ 27. 10.): BarGoo nemusí byť stále zapnutý. Používateľ
si vyberie jeden z hotových druhov plochy (napr. Goo — všetky kvapky, Minimal — iba spodný okraj s LensShore
a TrayShore, Focus) a BarGoo môže vypnúť. Podmienka: bez BarGoo nesmie zmiznúť prepínanie okien — LensShore nájde
aj otvorené okná, ostáva Glance a Alt+Tab. Druh plochy určí aj to, či beží LensGoo alebo LensShore (6B.12).

**6A.06** [x] (BarGoo) presun okna na inú obrazovku (27. 10.): ponuka okna › Presunúť na obrazovku › Obrazovka 1, 2… (zľava doprava, iba pri viacerých); `latte.win.to_screen`, plávajúce ostane na dosah; overené bez obrazovky s dvoma monitormi

**6A.07** [ ] (BarGoo) prenášanie ikry ťahaním na BarGoo iného monitora — scény sú oddelené procesy, odovzdanie cez `latte-say`; po 6A.04 (skutočné monitory)

**6A.08** [ ] **Prehľad úloh z BarGoo** (používateľ 27. 10.): ľavý klik na hlavu urobí to, čo Win+Tab vo Windows 11
(predloha: snímka používateľa — okná ako náhľady s ikonou a titulkom nad rozmazanou plochou, vybrané orámované), a to
**cez všetky obrazovky naraz**: každý monitor ukáže svoje okná, pekne rozložené, a pri ňom tlačidlá režimu (8A.06) —
klik prepne režim tomu monitoru (tým je splnená aj 8A.13 mimo Nastavení). Klik na náhľad okno prinesie. Náhľady podľa
8A.10. Pravý klik ostáva: ukázať plochu.

### 6B. [~] LensGoo
Zdroje: LATTEOS-GOO §4.3

**6B.01** [x] (LensGoo) LensGoo: Súbory, Web, kalkulačka · r. 187–187

**6B.02** [x] (LensGoo) LensGoo · r. 501–503

**6B.03** [ ] (LensGoo) E. LensGoo — koliesko · r. 780–781
- [ ] **LensGoo:** prepínanie funkcií kolieskom — dokumentované sú Tab / Shift+Tab (kolieskom sa mení veľkosť
  kvapky); overiť, či koliesko ide aj v karte.

**6B.04** [ ] (LensGoo) R3·A — LensGoo · r. 948–950
- [ ] **LensGoo:** samostatne overiť vyhľadávanie a spúšťanie aplikácií/súborov a kvalitu AI
  rozhovoru; dotiahnuť poskytovateľov, vstupy a chybové stavy bez duplikovania všeobecnej práce
  na `latte-ai`.

**6B.05** [x] (23. 10. potvrdené používateľom) Klávesnica po spustení z LensGoo (používateľ 23. 10.: DualBrew spustený cez LensGoo nedostal klávesnicu, „klávesnica má byť vždy tam, kam klikne kurzor“). Príčina podľa kódu: pole hľadača drží klávesnicu ešte 300 ms po zatvorení karty (grace v pleamare), aplikácia sa spúšťala po 80 ms — okno sa otvorilo, kým klávesnica patrila Goo. Opravené: `LET_GO = 350` v `goo/lib/lens.luau`. Druhá časť (používateľ 23. 10.: klik na plochu, potom do poľa DualBrew — písať nejde, až po kliknutí inam v okne a znova do poľa): `AppWindow` pri každom stlačení ľavým tlačidlom dá klávesnicu textovému poľu pod kurzorom (aj o 150 ms neskôr, keď sa okno práve aktivuje) — platí pre všetky aplikácie LatteOS. V bezobrazovkovom sedení sa ani jedna časť nedala spoľahlivo vyvolať (falošná myš a klávesnica strácajú prvú udalosť) — čaká na potvrdenie na skutočnej obrazovke.
  **23. 10. príčina nájdená a opravená** (zdroj Hyprlandu 0.56, `InputManager.cpp`): vrstva ikon na ploche (`latte-desktop`)
  chcela klávesnicu „on demand“ stále. Hyprland takej vrstve dá klávesnicu už pri prechode myšou (`rawSurfaceFocus`), a
  kliknutie do okna ju vráti len vtedy, keď sa mení okno (`focusState()->window() != w`) — po prechode cez plochu a kliknutí
  späť do toho istého okna išli klávesy ploche. Teraz plocha chce klávesy iba po kliknutí na ňu (na chvíľu výlučne, potom
  on demand) a kým je nad ňou myš; myš odíde → None → klávesy späť oknu. Overené v sedení bez obrazovky: stará plocha
  dostala „abcd“ napísané po kliknutí do DualBrew, nová ich nechá DualBrew; prechod myšou nad plochou už nič nevezme;
  písmená po kliknutí na plochu idú ploche. Podobné hlásenie: ashell #1010 (vrstva Bottom, follow_mouse = 2).

**6B.06** [x] pisanie do riadku na vyhladavanie v forme výpočtu, zobrazi vysledok s možnostou ho skopirovat do schranky. 
tiež je sučastou aj prevodnik jednotiek a mien pričom nemosi byt použiti presny formatat a dokaže s apracovat s vágnym zadaním.
   **Urobené 26. 10.:** výpočty ako doteraz (`lib/calc.luau`); jednotky a meny počíta **Qalculate** (`qalc`, balík
   `qalculate`, kurzy ECB raz denne), voľný zápis v jazyku používateľa preloží `goo/lib/amount.luau` so slovami
   z `goo/lang/sk-amount.json` (ďalší jazyk = ďalší súbor): „100 eur na doláre“ →
   111,88 $, „5 km v míľach“, „20 stupňov celzia na fahrenheit“, „1000 korún na eurá“ → 41,04 € (meny na centy), „15 % z 80“.
   Výsledok klikom do schránky. Názov aplikácie s číslom („2048 game“) sa nepočíta. Test v `tests/test_bin.py`.

**6B.07** [x] bola najdena chyba. ked sa skrolujekolieskom, na ai založke sa skrolovanie zastavy a už nejde ani spatky. — **Opravené 26. 10.:** karta pri každom obnovení (každý kúsok písanej odpovede, limity, ponuka) stiahla rozhovor na koniec a prebila koliesko. Teraz ide na koniec iba nová správa; písanú odpoveď rozhovor nasleduje, len keď je človek dole (`ai_new`, `ai_gen` v `goo/parts/ai.plm`). Overené s lokálnou AI: počas 143 obnovení ostal rozhovor hore, kde sa čítalo; dole nasledoval odpoveď. **Aj 26. 10.:** koliesko nad pásom záložiek (Aplikácie … AI) ich prepína na každej záložke, aj na AI, kde sa predtým zastavilo; koliesko robí to, nad čím je kurzor (záložky, rozhovor, riadky).

**6B.08** [x] pridat kontexctove menu v ploche ai vnutri popupu LensGoo. mosi byt možnost skopirovat spravu, a tiež kd sa klikne do tej plochy, musi tam byt nastavenie priehladnosti. 
ta biela plocha je prisilna a potrebuje mat volitelnu hodnotu priehladnosti.
   **Urobené a overené 26. 10.:** pravý klik na správu → Kopírovať (Ctrl+C), Kopírovať celý rozhovor; vedľa správ → celý
   rozhovor; pri službách s vlastnou stránkou (Claude, Gemini…) aj **Priehľadnosť plochy** (Ako LatteOS · Nepriehľadná ·
   Trochu · Priehľadnejšia · Najpriehľadnejšia · Sklo: biela plocha ubúda 100 → 18 %, nie zahmlievaním (to ju iba
   zošedilo, výhrada používateľa); pri dvoch najpriehľadnejších sa text, bubliny a pole prepnú na farby LatteOS; voľba
   `ai_glass` v `settings.json`, „Ako LatteOS“ najviac stupeň 2). V poli otázky Vystrihnúť · Kopírovať · Prilepiť so skratkami vpravo, ako ponuka vo Windowse (ponuka Goo
   vie odteraz ukázať skratku: `keys`). Pri každej správe ikona **Kopírovať** jedným klikom (nápad používateľa). Ctrl+C
   na vyznačenom texte a Ctrl+V v poli fungovali už predtým.


**6B.10** [x] Záložka Aplikácie sa vždy otvorí na filtri **Všetky** (používateľ 26. 10.); iný filter platí, kým je LensGoo otvorený.

**6B.11** [~] **Každé pole na písanie: Ctrl+C, Ctrl+V a pravý klik Vystrihnúť · Kopírovať · Prilepiť** (používateľ 26. 10.:
„samozrejmosťou“). Hotové v Goo: pole karty (riadok hľadania LensGoo a každá karta s poľom; `card_field_menu` v
`lib/card.luau`) a pole otázky AI; ponuka Goo ukazuje skratky. Ostáva: polia v aplikáciách LatteOS (Quickshell), overiť
a doplniť rovnakú ponuku.

**6B.09** [ ] **Ikona Kopírovať pri každom texte LatteOS, ktorý sa dá kopírovať** (používateľ 26. 10.): ako pri správach AI
(6B.08) — príkazy, chybové hlásenia, správy na skopírovanie (Posledný pád), adresy, výsledok kalkulačky; v Goo aj
v aplikáciách LatteOS. Tlmená pri texte, rozsvieti sa pod kurzorom, klik skopíruje celý text.

**6B.12** [ ] **LensShore — AI-centrická náhrada LensGoo** (používateľ 27. 10.): LensGoo ostáva ako klasická voľba;
**LensShore** je plnohodnotná náhrada postavená okolo AI. Je to riadok **stále otvorený na spodnom okraji** (vedľa
TrayShore), nie kvapka. Pri písaní sa **od spodného okraja vysunie ostrovček ako v Marei** a rastie s obsahom:
čipy so zámerom → výsledky → rozhovor s AI (strop ~60 % výšky, potom posúvanie; leží nad oknami, nič neodtláča).
Esc alebo klik mimo ho ponorí, rozhovor ostane a pri ďalšom kliku sa vynorí, kde sa skončilo.
**Kontextový odhad zámeru** z písaného textu, najprv rýchlymi miestnymi pravidlami, nie AI: zhoda s aplikáciou → jej
ikona prvá („photoshop“); „ako…“, „návod“ → web; dlhá veta alebo otázka → AI prompt; cesta → súbor; príkaz →
terminál; výraz → Qalculate (6B.06); názov otvoreného okna → prepnúť naň. Enter = najlepší odhad, Tab prepína čipy.
Písaný text **neodchádza** na web ani online AI, kým to človek nezvolí. **Pri vypnutej AI** (2B) ostáva plnohodnotným
hľadaním, iba bez čipu AI. Jedno jadro s LensGoo (`goo/lib/lens.luau`), líšia sa iba vzhľadom.
**Rozhodnuté 27. 10.:** vždy beží **iba jedno** — LensGoo alebo LensShore; prepínač je v **Nastaveniach › Goo**.

**6B.13** [ ] **Výskum: Tinycast ako zoznam funkcií** (používateľ 27. 10.: „vyzerá ako naše LensGoo“) —
https://github.com/abue-ammar/tinycast (macOS, Swift, AGPL-3.0 → kód nepreberať, iba nápady). Čo LensGoo/LensShore
nemá: bežiace aplikácie s Ukončiť (jednu/všetky), skratka na konkrétnu aplikáciu (prepnúť/skryť), história schránky
v spúšťači (text aj obrázky, vloženie späť do predošlej aplikácie), úryvky a rýchle odkazy, slovník, výber emoji,
akcie okien (34), poznámky v Markdowne, záloha a import nastavení. Spúšťa **rozšírenia Raycastu** — preveriť Linuxový
spúšťač kompatibilný s Raycastom (Vicinae) ako zdroj rozšírení. Výstup: zoznam „prevziať / nie“ na schválenie.

**6B.14** [ ] **Koliesko iba v prísnych zónach** (používateľ 27. 10.; pravidlo 25): dnes koliesko kdekoľvek na karte,
kde sa nič neposúva, prepína záložky (`card_spin` v `goo/lib/card.luau`, 30 ms čakanie na riadok) — kurzor kúsok vedľa
zoznamu tak prepne záložku omylom. Zmena: zrušiť `card_spin` (záložky iba nad pásom záložiek), **prilepenie
posúvania** (~300 ms patrí koliesko zoznamu, ktorý sa začal posúvať, aj keď kurzor vyjde von) a **bez prelievania**
(zoznam na konci sa zastaví, otáčanie neprejde na kartu ani záložky). Nároky na hardvér: skôr menšie (ubudne
časovač). Platí pre všetky karty Goo aj aplikácie LatteOS.

### 6C. [~] PowerGoo
Zdroje: LATTEOS-GOO §4.2, `crates/latte-stats`

**6C.01** [x] (PowerGoo) pás výkonu · r. 81–81

**6C.02** [x] (PowerGoo) PowerGoo · r. 499–500

**6C.03** [ ] (PowerGoo) E. pás PowerGoo · r. 778–779
- [ ] **Pás PowerGoo:** „veličiny sa menia v Nastaveniach“ — dokumentované sú pevné bunky CPU · RAM · GPU · VRAM;
  výber veličín overiť, inak z opisu vypustiť.

**6C.04** [ ] (PowerGoo) R3·A — pás výkonu a QueenGoo · r. 954–955
- [ ] **PowerGoo — pás výkonu:** výber zobrazených veličín (CPU, GPU, RAM…) v nastaveniach tohto Goo (z opisu autora;
  dnes pevné bunky CPU · RAM · GPU · VRAM). **QueenGoo:** pokrývka hlavy je voliteľná, preferovane korunka.

**6C.05** [x] (PowerGoo) PowerGoo s lištou údajov · r. 1231–1232
[x] **PowerGoo s lištou údajov** (13. 10.: karta rastie z celej kapsuly — `card_strip`, `cap.len` v `goo/parts/card.plm`; začína širokou ako lišta, otvára sa smerom, ktorým lišta leží, a drží ju v sebe; overené snímkou pri spodnom okraji, pri bočnom nie)**:** kartu vysunúť z celého celku Goo + lišta, aby tvorili vizuálne jeden kus
    (dnes je ucho karty pri ľavom kliku malé a lišta ostáva vedľa). Režimy okien (4.) sú bod 7 (Glance).

### 6D. [~] ClockGoo
Zdroje: `goo/parts/calendar.plm`, `bin/latte-cal`, `bin/latte-sky`; LATTEOS-GOO §4.5

**6D.01** [x] (ClockGoo) ClockGoo · r. 95–96

**6D.02** [x] (ClockGoo) prepojené kalendáre · r. 107–109
- [x] prepojené kalendáre (13. 10.): adresy .ics v karte ClockGoo, číta `bin/latte-cal` (opakované udalosti,
  časové pásma); iba na čítanie, bez účtov. **ChatGoo** čaká na Beeper
  (na latte-lab nie je nainštalovaný, nedá sa overiť).

**6D.03** [x] (ClockGoo) ClockGoo · r. 504–506
- e. [x] **ClockGoo** (`ClockGoo popup time frosted glass.png`; hotové, potvrdil používateľ 21. 10.: karta počasia sa zámerne mení podľa dňa a noci, v noci je tmavá — nie je to rozdiel od návrhu; nemeniť): záložky Prehľad · Časovače a budíky · Počasie,
  veľký čas so sekundami, dátum, týždeň, meniny, počasie s východom a západom slnka, svetové hodiny,
  digitálna pohoda (čas pri obrazovke podľa aplikácií), päta Režim spánku · Nerušiť.

**6D.04** [ ] (ClockGoo) R3·A — ClockGoo, QueenGoo, ChatGoo · r. 956–957
- [ ] **ClockGoo, QueenGoo a ChatGoo:** dotiahnuť nedokončené karty, upozornenia, kalendár,
  zariadenia a overenie so skutočnými aplikáciami/službami, ktoré kvapky zastupujú.

**6D.05** [ ] (ClockGoo) Presunut upozornenia z clockGoo do ShoreGoo· r. 1338–1340
- **Upozornenia:** nové upozornenie sa ukáže ako lístok vpravo dole nad Pobrežím (6,5 s, klik otvorí ClockGoo,
  neberie klávesnicu) a zaznie tón; Nastavenia › Oznámenia: Nerušiť · Ukázať v rohu · Prehrať zvuk · Vyskúšať.
  Nerušiť sa presunulo z `clock.json` do nastavení Goo (`settings.json`, kľúč `quiet`).

**6D.06** [ ] (ClockGoo) Karta ClockGoo (ľavý klik) ostáva rýchly prehľad dňa; plná správa udalostí je v aplikácii Kalendár (10J), kam karta odkazuje tlačidlom „V okne“.

**6D.07** [ ] Kalendar-kliknutie na poličko dna zvyrazni ten den a nasledny zapis do riadku bude mat pred sebou predvyplneny ten datum. zapis sa týka evidentne toho dna

**6D.08** [ ] kalendar-jeho funkčnost musi byt minimalne identicka s funkčnostou google Kalendaru!

### 6E. [x] QueenGoo
Zdroje: LATTEOS-GOO §4.4

**6E.01** [x] (QueenGoo) QueenGoo · r. 113–114

**6E.02** [ ] **Continuity** (používateľ 27. 10.; nadväzuje na „obnovenie relácie: áno“ z ROZHODNUTÍ 6. 10.): po postáti
myši nad QueenGoo sa okolo nej ukážu farebné ikonky uložených pracovných stavov a **+**. **+** vytvorí nový model
Continuity z aktuálnej relácie; klik na ikonku ju obnoví jedným klikom na naposledy uložených pozíciách. Uloženie
a vypnutie modelu uloží jeho stav znova.
Príklady používateľa: *práca* — SAP so 4 oknami GUI (každé iná funkcia), firemný program, prehliadač s tromi
firemnými webapp, tabuľka v Exceli; *písanie* — editor s kurzorom na poslednej strane, referenčné dokumenty
a priečinky, monitory v teplej farbe ako predtým, predtým nastavená relaxačná hudba.
**Princíp:** Continuity si ukladá *kde čo bolo*, nie dáta — otvorí tie isté súbory a adresy, takže údaje sú vždy
aktuálne. Heslá neukladá nikdy (prihlásenia ostávajú v prehliadači a kľúčenke). Tri vrstvy:
(1) **okná** — aplikácie, súbory, URL, pozície, monitory, plochy, režim okien (Hyprland: `hyprctl clients`, pravidlá
pri obnove); (2) **stav systému** — nočné svetlo (`latte-nightlight`), hlasitosť a výstup, hudba aj so skladbou
a pozíciou (MPRIS), Kofeín, tichý režim; (3) **vnútro aplikácií** cez adaptéry: LibreOffice si posledné miesto pamätá,
prehliadač karty, SAP GUI má súbory skratiek s transakciou; kde adaptér nie je (napr. Word cez Wine), Continuity to
pri ikone poctivo označí. Neskôr prenos modelu na iný LatteOS (Session Manager, LatteApp).
Preveriť hotové: obnova relácie v KDE a GNOME, hyprland-session a podobné nástroje, MPRIS.

### 6F. [~] CamGoo
Zdroje: `bin/latte-cam`; Nastavenia › Kvapky › Webkamery

**6F.01** [~] (CamGoo) CamGoo · r. 359–365
[~] **CamGoo — webkamery** (20. 10., na pokyn používateľa). Hotové: karta s obrázkom kamery, prepínanie, zoznam
    v Nastaveniach › Kvapky › Webkamery. **Ďalej (nápady používateľa 20. 10.):** zobrazenia — pod sebou, dlaždice,
    zväčšenie jednej a prepínanie, samé rolujúca páska; **domáce IP kamery** (používateľ má Tapo: RTSP
    `rtsp://účet:heslo@IP:554/stream1`, snímka cez ffmpeg; heslo do kľúčenky, nie do súboru); **nájdenie kamier
    v sieti** (ONVIF WS-Discovery, porty 554 a 2020; to isté vie inšpektor siete v Správcovi zariadení);
    **návrh kamier podľa miesta** (miesto počasia → verejné kamery okolo, zdroj s API, napr. Windy Webcams — kľúč);
    **ISS** (NASA vysiela video, nie obrázok: snímka z prúdu cez ffmpeg, alebo mapa polohy ISS ako „kamera“).

**6F.02** [ ] (CamGoo) živý obraz v CamGoo · r. 371–371
- **Živý obraz v CamGoo** postupom Vitreusu (ffmpeg → súbor → `cam_path?N`), aj pre Tapo cez RTSP.

### 6G. [x] QuickGoo

**6G.01** [x] (Vlastné kvapky a návrhy kvapiek) QuickGoo · r. 100–100

### 6H. [~] TrayShore (Pobrežie)
Výnimka: patrí medzi Goo a stojí na rovnakom mieste, interaguje s Goo, ale nie je to Goo — nedá sa s ním manipulovať, správa sa inak a má iné pravidlá.
**Názov rozhodnutý 27. 10.: TrayShore** (doterajšie Pobrežie/Shore; ShoreGoo zamietnuté). Je to oznamovacia oblasť
(vo Windowse „notification area“, ľudovo system tray): hlasitosť, sieť, aplikácie na pozadí — a k tomu upozornenia
a dashboard. Vedľa neho na spodnom okraji žije **LensShore** (6B.12). V kóde a textoch premenovať pri najbližšej práci
na kategórii (6H.08).
Zdroje: `apps/desktop.qml`, `bin/latte-desktop`, `goo/lib/desk.luau`; LATTEOS-GOO §4.8

**6H.01** [x] (Plocha a Pobrežie) náhrada rohovej lišty (Pobrežie) · r. 97–99

**6H.02** [ ] Upozornenia ako sučast popupmenu shore

**6H.03** [ ] **Rozbalené Pobrežie** (používateľ 26. 10.): lišta dole sa rozbalí až po vrch obrazovky — hornú časť zaberajú
upozornenia (6H.02), spodnú dashboard (rýchle prepínače a stav, ako Rýchle nastavenia vo Windows 11 a GNOME).

**6H.04** [ ] **Kofeín** (používateľ 26. 10.): prepínač v dashboarde rozbaleného Pobrežia (6H.03), ktorý zabráni
zamknutiu, zhasnutiu obrazovky a uspaniu, kým je zapnutý (ako Caffeine v GNOME a PowerToys Awake vo Windows). Najprv
preveriť hotové: hypridle rešpektuje zámky `systemd-inhibit --what=idle` a D-Bus ScreenSaver; voľba na čas (1 h, do
vypnutia). Zapnutý kofeín musí byť vidieť (ikona na lište), inak naň človek zabudne.

**6H.05** [ ] **TrayShore = upozornenia + dashboard s widgetmi ako v Androide** (používateľ 27. 10.): rozbalený TrayShore
(6H.03) je zóna upozornení a dashboard pre multimédiá a ďalšie. Dashboard sa skladá z **widgetov, ktoré sa pridávajú,
odoberajú, presúvajú a menia veľkosť ako na ploche Androidu** (mriežka, dlaždice 1×1, 2×1, 2×2…, podržať/ťahať,
„+ Pridať widget“ so zoznamom). Prvé widgety: prehrávač (MPRIS), hlasitosť a výstup zvuku, rýchle prepínače
(sieť, Bluetooth, Kofeín 6H.04, nočné svetlo), počasie, kalendár. Preveriť hotové: widgety a komunitné doplnky
Noctalie (§4.8), ako Android rieši mriežku a veľkosti. Ovládanie myšou aj dotykom (pravidlo 23).

**6H.06** [ ] **Príboj o TrayShore** (používateľ 27. 10.): vlny hladiny Goo sa o TrayShore rozbíjajú ako o skaliská.
Naviazať na nerozhodnuté stavy hladiny (ROZHODNUTIA 6. 10.): **kľud** = pri nečinnosti nič, nestojí výkon;
**príboj** = udalosť (upozornenie, dokončené sťahovanie, pripojené zariadenie) a vlna sa rozbije o ikonu, ktorej sa
týka; **búrka** = iba kritické systémové varovanie, nikdy záťaž CPU (pri záťaži sa efekty nepridávajú). Vietor
z `latte-sky` už vlny dvíha (6.23). Zmerať cenu na snímku.

**6H.07** [ ] **Dvojfarebné vlny aj na prihlásení a ploche** (používateľ 27. 10.): okná majú dvojfarebnú kávovú hladinu
(`apps/common/Surface.qml`), prihlásenie a plocha nie (`goo/parts/waves.plm`, `surface.plm`). Skúsiť na latte-lab ako
prepínač A/B, poslať snímky; sledovať kontrast kvapiek nad hladinou a cenu na snímku (scéna v pokoji 17 % jadra).
Ak sa osvedčí: jeden vzhľad hladiny pre prihlásenie, plochu aj okná.

**6H.08** [ ] Premenovať Pobrežie → TrayShore v kóde, prekladoch, Nastaveniach a dokumentoch (LATTEOS-GOO §4.8, §8).


### 6I. ChatGoo
Doplnok pre Beeper (voliteľná kvapka).
Zdroje: LATTEOS-GOO §4.6

### 6J. [x] MediaGoo
Čo hrá, ovládanie prehrávača; je na ploche iba kým beží prehrávač.

**6J.01** [x] (Vlastné kvapky a návrhy kvapiek) MediaGoo · r. 106–106

### 6K. [~] Vlastné kvapky (Tvorca Goo)
Kvapka bez programovania: aplikácia alebo ikona s príkazmi a textom.

**6K.01** [x] (Vlastné kvapky a návrhy kvapiek) vlastné kvapky · r. 101–103

**6K.02** [ ] (Vlastné kvapky a návrhy kvapiek) R3·A — vlastné a ďalšie kvapky · r. 958–960
- [ ] **Vlastné a ďalšie kvapky:** overiť a doplniť napojenie existujúceho Tvorcu Goo na engine;
  návrhy ClipGoo, MediaGoo, PassGoo a CastGoo prijímať po jednom podľa používateľského prínosu.
  Každá kvapka používa spoločné pravidlá enginu, nastavení a ovládania.

### 6L. [ ] Návrhy kvapiek
Nápady bez rozhodnutia: LaunchGoo, ClipGoo, PassGoo, CastGoo a ďalšie.
Zdroje: `goo/lib/own.luau`, `drops.json`; LATTEOS-GOO §4.7, §4.11

**6L.01** [ ] (Vlastné kvapky a návrhy kvapiek) E. LaunchGoo · r. 756–761
- [ ] **LaunchGoo (nápad autora, návrh):** rýchly spúšťač — do kvapky sa vložia ikony, napr. obľúbených hier, a
  neprekážajú na ploche; ďalšia kvapka môže niesť pracovné aplikácie, plocha ostane voľná. Odkazy môžu byť aj priamo
  na ploche („možnosti sú také aj onaké“). Základy už sú: Tvorca Goo (rýchle spúšťanie = skupina aplikácií, klik
  ukáže kartu s dlaždicami) a rýchly zoznam LensGoo. Treba rozhodnúť: viac skupín ako samostatné kvapky, ikony na
  ploche, PlayGoo (správca hier, alebo prehrávač hudby) je len nápad — ignorovať.

**6L.02** (pozn.) (Vlastné kvapky a návrhy kvapiek) F. R3·A — návrhy kvapiek a efektov · r. 830–839
**R3·A — návrhy kvapiek a efektov (nie úlohy, kým ich autor neprijme):** hovor cez podržanie LensGoo, whisper.cpp (r. 529);
nepoužívaná kvapka sa zmenšuje (r. 531); odkladacia kvapka na súbory (r. 532); zvuková identita Goo (r. 533);
tekuté zóny okien (r. 548); nájdi kurzor zatrasením (r. 552); stavy hladiny (r. 555); AirDrop kvapky cez LocalSend (r. 557);
ikra hrajúca zvuk vibruje (r. 572); ekvalizér Goo (r. 716); bublina odchádzajúceho spojenia v modeli NET (r. 616);
režim sústredenia (r. 541); gamepad (r. 545); prechod z Windowsu — import profilov, prehľad skratiek (r. 540);
komunitné doplnky Noctalie ako kvapky (r. 647); ClipGoo, MediaGoo, PassGoo, CastGoo (r. 520); PlayGoo (správca hier alebo prehrávač hudby).
Z `inspo/` 13. 10.: plocha bez klasickej lišty — zóny Main, Stash a Parking na širokom monitore (Glance, prednáška
Scotta Jensona pre KDE, 2026) — **rozhodnuté 13. 10. ako štvrtý režim okien, „Teraz“ bod 7**; pevné pravidlá fyziky kvapiek a okien — hmotnosť, zotrvačnosť, vzájomné odpudzovanie,
kvapalina tečúca okolo okien (fwm); vzhľad prehrávača a zámku obrazovky (widgety Chaldea, 0BSD).

---

## 7. [~] Desktop
ikonky na ploche pred wallpaperom a kontextove menu pravym klikom ako v win11

### 7A. [~] Tapety
Obrázky, živé tapety, skwd-wall, prezentácia, tapety z internetu.

**7A.01** [x] (Vzhľad, témy a tapety) tapeta a okenné tlačidlá · r. 185–186

**7A.02** [x] (Vzhľad, témy a tapety) E. skwd-wall · r. 774–777
- [x] **skwd-wall (rozhodnuté 9. 10.):** využijeme a integrujeme **v našej podobe** — výber tapiet, živé tapety a
  prechody (aj ako prechody pri prepínaní okien, programov a priečinkov) v Nastaveniach, so spoločnými
  pravidlami GooEngine a obmedzením pre stupeň Softvér a SAFE. Nejde o doslovné prevzatie; licenciu a čo sa preberá
  určí R1 (R3·J).

**7A.03** [ ] (Vzhľad, témy a tapety) R3·J — skwd-wall · r. 1120–1120
- [ ] Integrovať skwd-wall v našej podobe (rozhodnuté 9. 10.): výber tapiet, živé tapety, prechody; voliteľná vrstva, v SAFE vypnuté (R3·B).

**7A.04** [~] (Vzhľad, témy a tapety) skwd-wall · r. 1265–1302
[~] **skwd-wall — urobené 13. 10. v noci:** nainštalovaný z COPR `piixini/skwd-wall-v2` (1.0.0 beta 24) a zapojený
    cez `bin/latte-wall`: kde je, kreslí tapetu on (`skwd-walld` + `skwd-paper`: obrázky, filmy, scény Wallpaper
    Engine, prechody), `latte-wall pick` otvorí jeho výber (Nastavenia › Pozadie › Výber tapety; ponuka plochy ›
    Zmeniť tapetu), jeho udalosti (`skwd-helm watch`) zapíšu voľbu do `~/.config/latteos/wallpaper`. Bez neho
    ostáva swaybg a mpvpaper. Z jeho palety (`~/.cache/skwd-wall-v2/colors.json`) je **téma „Podľa tapety“**
    (štvrtá šálka: `Theme.qml` pre aplikácie a plochu, `latte/bars.lua` pre titulky okien) — mení sa sama pri
    každej zmene tapety, aj v otvorenom okne. Tapety LatteOS sa do jeho knižnice (`Obrázky/Wallpapers`) kopírujú.
    Overené naostro: kreslenie, výber, paleta z modrej tapety prefarbila Nastavenia. **Rozhodnuté (používateľ,
    13. 10.): kvapky Goo ostávajú vo farbách kávy**, téma z tapety sa ich netýka. **Chýba:** okraj aktívneho okna
    podľa témy (pevné farby v `hyprland.lua`); klávesová skratka na výber;
    nastavenie `skwd-walld` pri inštalácii (dnes ho spustí prvé `latte-wall show`); `skwd-lens` s modelom
    570 MB sa nainštaloval podľa návodu autora a nie je nutný. **Doplnené 13. 10. pred polnocou (používateľ: z `latte-tapety` v0.3 chce knižnicu, ďalšiu/predošlú, pauzu a
    katalógy z internetu):** `latte-wall next | prev | pause | resume` (cez skwd-wall, bez neho po priečinku
    `Obrázky/Wallpapers`), v Nastaveniach › Pozadie tlačidlá Predošlá · Ďalšia · Pozastaviť · Prehrať a časť
    **Z internetu** (`bin/latte-walls`): **Bing** (fotografie posledných dní) a **MotionBGS** (filmy, s hľadaním);
    klik stiahne do knižnice a nastaví. Wallhaven má skwd-wall vo vlastnom výbere. Overené naostro: film
    z MotionBGS (9 MB) stiahnutý a hrá ako tapeta, ~14 % jedného jadra. **skwd-lens** (hľadanie tapiet podľa
    významu: model SigLIP 2, 598 MB, beží na procesore; latte-lab i7-4820K: 60 obrázkov za 15,5 s ≈ 4 za
    sekundu na 4 vláknach) smie ostať, **iba keď je AI v LatteOS zapnutá** — väzba na vypínač AI ešte nie je
    (skwd má nastavenie `semantic.enabled`). Rozšírenie na hľadanie obrázkov v celom počítači: binárka vie
    stavať vlastný index a pýtať sa, ale iba cez nedokumentované rozhranie (JSON na vstupe) a pri ručnom
    spustení mi zamrzla — bez podpory autora to nestaviam. **Počasie na ploche** (dážď, sneh podľa predpovede)
    engine Goo už má: pri nečinnosti a zapnutých „Živých kvapkách“; pohyblivé scény z v0.3 sa nevracajú.
    **Stránka Pozadie podľa zadania používateľa (13. 10. pred polnocou; vzor: Pozadie vo Windows, rozšírené):**
    hore náhľad obrazoviek v ich rozložení (klik = voľba len pre ňu; „Rovnaké na každej obrazovke“), pod ním
    zdroj — Obrázok · Plná farba · Prezentácia (priečinok, interval, náhodné poradie) · MotionBGS · Wallhaven ·
    Bing · skwd-wall · Opísať slovami (skwd-lens, iba so zapnutou AI) — a pod ním samotný výber; „Prispôsobiť
    obrázok“ iba keď kreslí swaybg. `bin/latte-wall` je prepísaný (Python): stav pre každú obrazovku
    v `~/.config/latteos/background.json`, `set TARGET picture|color|slideshow`, `fit`, `restore`, `state`;
    farba je obrázok jednej farby (vie ho každý kresliaci program), prezentácia vlastná slučka. Čo sa vyberie
    v okne skwd-wall, zapíše sa sem (`latte-wall follow`). Overené naostro: farba, prezentácia a Ďalšia,
    vlastná tapeta jednej obrazovky, návrat na všetky. **Neoverené:** dve obrazovky naraz (latte-lab mala jednu),
    výber priečinka systémovým oknom, sťahovanie z Wallhavenu klikom, „Opísať slovami“ v okne skwd.
    Pôvodný zápis: **skwd-wall ako výber tapety** (používateľ, 13. 10.: „trvám na live wallpaper ako v 0.3 a samozrejme aj
    skwd wall“). Živé tapety 0.4 má (mpvpaper, Nastavenia › Pozadie). skwd-wall (Rust, Vulkan, GPL-3.0) je
    samostatný program: zistiť, čo presne z neho (výber s prechodmi, alebo aj kreslenie tapety), a ako voliteľnú
    závislosť ho zapojiť vedľa mpvpaper.

**7A.05** (pozn.) (Vzhľad, témy a tapety) AI vypínač a skwd-lens · r. 1332–1334
- **AI vypínač a skwd-lens:** `latte-wall ai` zapíše `semantic.enabled` do nastavení skwd-wall a reštartuje
  jeho službu; volá ho vypínač v Nastaveniach › AI aj štart relácie. Overené: pri vypnutej AI sa nový obrázok
  neindexuje.

**7A.06** [ ] (Vzhľad, témy a tapety) skwd-wall . samotne menu aplikacie skwd sa odoberie. nebudeme použivat kompletnu aplikaciu v tomto pripade.
zachovat nutne je prechodove efekty, a sustredit prepinanie wallpaperov dovnutra centralnych nastaveni.
Je nutne urobit nanovo prehladne kategorie, pre všetky druhy tapiet, vratane odkazu na externe zdroje.


**7A.07** [ ] (Tapety) **Pegboard v tapetách** (používateľ 26. 10.): ten istý pegboard obrazoviek ako v Nastaveniach ›
Obrazovky (8B.04) — obrazovky v skutočnom pomere, rozlíšení a rozostupoch, nezávisle od toho, či je obrazovka jedna
alebo dvadsať (pri jednej nemá ťahanie zmysel, ale pegboard tam je). Zdieľaný kus kódu pre obe miesta, nie kópia.

**7A.08** [ ] (Tapety) **Schémy tapiet ťahané na pegboard** (používateľ 26. 10.; nadväzuje na 7A.07). Predstava:
- Obrázok alebo videotapetu (napr. „galaxy eyes“) potiahnem **na pegboard, nie na monitor**. Na pegboarde jej nastavím
  veľkosť a polohu (úchyty ako pri zmene veľkosti obrázka v Skicári či Photoshope) a tým, čo prekrýva, určím, pod ktorými
  monitormi je. Presne tak sa potom skutočne ukáže: jeden obraz roztiahnutý cez tie 3 monitory, so skutočnými
  rozostupmi medzi nimi.
- Monitor 4 stojí ďalej od ostatných a má mať prezentáciu: tlačidlo **Prezentácia** → zvoliť priečinok (Prehľadávať…),
  interval zmeny a poradie obrázkov → **Vytvoriť schému**. Schém môže byť viac; sú v ponuke pod pegboardom.
- Schému z ponuky potiahnem nad monitor 4 a pustím: monitor ju prevezme. Schémy sa teda pripravujú vopred a na pegboard
  sa z nich presúvajú časti (obraz cez viac monitorov, prezentácia na jednom, video…).
- Vykonáva `latte-wall` (dnes `set NAME|* picture|video PATH`): pribudne obraz cez viac monitorov (výrez podľa polohy
  monitora v rozložení) a prezentácia na monitore. Schémy uložené v `~/.config/latteos/`.
### 7B. [~] Ponuka plochy
Pravý klik na plochu a ikony na ploche ako vo Windows 11.

**7B.01** [~] (Plocha a Pobrežie) Ponuka plochy na pravý klik · r. 1233–1264
[~] **Ponuka plochy na pravý klik** (13. 10., `bughunt/najdene-chyby.md`: „ako vo Windows 11, v 0.3 to bolo“).
    Urobené 13. 10.: vrstva `desk` pod oknami (`goo/parts/desk.plm`) počúva pravý klik na holú plochu a
    `goo/lib/desk.luau` otvorí kartu tam, kde sa kliklo: Súbory, Otvoriť v termináli · Nastavenia obrazovky,
    Tapeta, Prispôsobiť, Kvapky · Monitor, Všetky nastavenia. Aj na ďalších monitoroch (`side.plm`). Nasadené
    a overené na latte-lab v bežiacej relácii. **Chýba oproti v0.3:** ikony na ploche (Kôš, súbory z ~/Plocha)
    a s nimi Zobraziť, Zoradiť podľa, Nový, Prilepiť — plocha s ikonami bola v0.3 samostatná aplikácia
    (`old/session/apps/plocha.qml`); či sa vráti, rozhodne používateľ.
    **Rozhodnuté a urobené 13. 10. večer: ikony kreslí hotový program, `pcmanfm-qt --desktop` (LXQt, Fedora 2.4.1)** —
    `bin/latte-desktop` ho spúšťa ako vlastný profil `latteos` s priehľadnou plochou (tapeta ostáva naša: obrázok
    aj film cez mpvpaper), s písmom a ponukami vo farbách zvolenej šálky (paleta cez qt6ct z `Theme.qml`; štýl
    cez `-stylesheet` pcmanfm-qt zhodí) a s ikonami breeze. Vypínač: Nastavenia › Pozadie › Ikony na ploche
    (`~/.config/latteos/desktop-icons`). S ikonami patrí holá plocha im aj s ich ponukou (Vytvoriť nový, Prilepiť,
    Zoradiť…), vrstva `desk` enginu sa vtedy zavrie; bez nich ostáva kávová ponuka. Overené naostro po
    prihlásení cez greetd: Kôš, domov a priečinok z ~/Plocha, ponuka pri kurzore. (Bez obrazovky v skúške
    vyskočí ponuka v rohu — vec neviditeľného monitora, nie programu.) **Chýba:** položky LatteOS v ponuke
    pcmanfm-qt (Nastavenia obrazovky, Tapeta, Prispôsobiť) — dajú sa pridať ako „vlastné akcie“ libfm-qt;
    jeho vlastné „Nastavenia pracovnej plochy“ vedia nastaviť tapetu, ktorá by prekryla našu (pri ďalšom štarte
    sa vráti priehľadná); skúška so živou tapetou. pcmanfm-qt by mohol byť aj **Súbory** pre 0.4 (v kávových
    farbách vyzerá dobre) — na rozhodnutie.
    **Zmenené 13. 10. v noci (používateľ: „išlo mi len o ikonky a ponuku pravého kliku“, cieľ sú ľudia z Windowsu):**
    pcmanfm-qt odobratý aj s tým, čo priniesol (terminál, lxqt-sudo, vlastné nastavenia tapety). Plocha je vlastná:
    `apps/desktop.qml` (+ spoločná ponuka `apps/common/Menu.qml`), spúšťa ju `bin/latte-desktop`. Ponuky podľa
    Windows 11 — na ploche Zobraziť › (veľké · stredné · malé ikony, automaticky usporiadať, zobraziť ikony),
    Zoradiť podľa ›, Obnoviť, Prilepiť, Nový › (priečinok, textový dokument), Nastavenia obrazovky, Prispôsobiť,
    Otvoriť v termináli; na ikone Otvoriť, Vystrihnúť, Kopírovať, Kopírovať ako cestu, Premenovať, Odstrániť,
    Vlastnosti; Kôš: Otvoriť, Vysypať. Ťahanie ako vo Windows (na priečinok, do Koša, pravým s otázkou, von do
    aplikácie), výber obdĺžnikom, F2 · Del · Ctrl+C/X/V · F5. Súbory hýbe `gio` (Kôš, kolízie mien), obrázky sú
    samy sebe náhľadom, ostatné berú ikonu zo sady ikon systému (`QS_ICON_THEME` v `latte-app`). Farby sú témy
    (`Theme.qml`). Overené naostro v relácii: ikony, výber, obe ponuky s podponukou. **Neoverené:** ťahanie,
    premenovanie, Prilepiť, Vlastnosti, viac monitorov (ikony sú na hlavnom). **Chýba:** Otvoriť v programe…,
    Späť (Ctrl+Z), „Tento počítač“. **Čaká na používateľa:** ktorá sada ikon (poslaný prehľad: breeze, Papirus,
    elementary, Yaru, Mint-Y, Fluent).

**7B.02** (pozn.) (Plocha a Pobrežie) Plocha: Otvoriť v programe · r. 1344–1344
- **Plocha: Otvoriť v programe** (`latte-desktop openers`, spúšťa `gtk-launch`).

**7B.03** [ ] **Pravý klik všade podľa pravidla 23** (používateľ 27. 10.): prejsť plochu, kvapky, TrayShore, LensShore,
okná a aplikácie LatteOS — každý objekt má kontextovú ponuku s pevným poradím; rad ikon najčastejších úkonov hore;
každá položka ide aj dlhým stlačením na dotyku, dvoma prstami na touchpade, klávesom Menu / Shift+F10 a tlačidlom
ovládača. Kde chýba, doplniť.

---

## 8. [~] Okna
okná a ich vzhlad. zakladny dizajn okien je navrhnuty v inspo/forklift-vzhlad.png
priehladnost až glass režim bočneho panelu. 
ikonky vypnutia okna , minimalizacie a NET tlačidla, schopnosti a vzhlad.

**8.01** [x] (Bezpečnosť, súkromie a záloha) NET — odstaviť aplikáciu od internetu · r. 121–128
- [x] **NET — odstaviť aplikáciu od internetu hneď** (13. 10.): `bin/latte-net` (používateľ, bez hesla) presunie
  bežiacu aplikáciu do vlastnej cgroup a zapíše ju do `$XDG_RUNTIME_DIR/latteos/net-off`; služba
  `latte-netd` (root, `system/libexec/latte-netd`) jej v tabuľke nftables `inet latteos_net` zahodí
  prevádzku a zavrie otvorené spojenia. Ovláda sa z ponuky okna (pravý klik na titulok alebo ikru:
  „Odstaviť od internetu“) a z hlavičky aplikácií LatteOS (glóbus). Odstavené okno má oceľovosivý okraj.
  Overené naostro so službou spustenou ručne (spojenie padne do sekundy, po zapnutí ide znova).
  Platí pre aplikáciu, kým beží; trvalý zákaz je oprávnenie aplikácie a príde s Baristom.
  Neoverené: jednotka systemd (zapnutá až inštalátorom), tlačidlo na titulkoch hyprbars nie je.

### 8A. [~] Režimy okien
Páska, dlaždice, plávajúce, Glance, hyprtrizone; prichytenie ťahaním.
Zdroje: `system/hypr/`, `plugins/latte-events`, `patches/`; LATTEOS-GOO §4.9

**8A.01** [x] (Okná) okná ako vo Windows · r. 135–138

**8A.02** [x] (Okná) prichytenie ťahaním · r. 190–191

**8A.03** [~] (Okná) Režim okien Glance · r. 267–285
[~] **Režim okien Glance** — **urobené 13. 10. večer (prvá verzia, na pokyn „pre rôzne rozlíšenia“):** štvrtý režim
   `glance` v `system/hypr/latte/windows.lua`, na každom monitore, nie iba širokom. Okno, v ktorom sa pracuje,
   vyplní stred; ostatné majú veľkosť stredu a vykúkajú zo strán pásom, ktorý obrazovka nechá (titulok hore, viac
   okien na strane si delí výšku). Stred je široký podľa výšky (1,45 ×), najmenej pol obrazovky a najviac toľko,
   aby po stranách ostalo aspoň 96 px: 2560 × 1080 → stred 1415 a po 560 px, 1920 × 1080 → po 240 px,
   1024 × 768 → po 106 px. Klik na okno zboku ho prinesie do stredu; Win+←/→ pošle okno nabok, Win+↓ ho
   odstaví (ikra BarGoo = Parking), Win+↑ na celú plochu; pustenie ťahaného okna v páse ho tam nechá. BarGoo,
   karta nastavení Goo aj Nastavenia › Okná režim ponúkajú. Overené bez obrazovky na troch rozlíšeniach
   (poradie, strany, odstavenie, zavretie). **Chýba oproti predlohe:** zmenšené živé okná (Hyprland okno
   nezmenší), náhľady v Parkingu (dnes ikony), útržky textu (clips), Meta+dvojklik, mapa pri Alt+Tab.
   Pôvodný zápis: **Režim okien Glance** (rozhodnuté 13. 10., podľa [Glance](https://github.com/scottjenson/Glance) Scotta
   Jensona, MIT) — štvrtý režim vedľa pásky, dlaždíc a plávajúcich, ponúka sa **iba na širokom monitore**. V strede
   **Main** a vedľa neho **Stash**: skutočné okná v skutočnej veľkosti. Pri okraji **Parking**: náhľady odstavených
   okien, kreslí ich engine Goo, klik okno vráti. Minimalizácia v Glance = odstavenie do Parkingu.
   *Pripravené:* či a ako BarGoo okná ukazuje, určuje jedno miesto (`berries_out()` v `goo/lib/bar.luau`) — Parking
   bude ďalšia podoba toho istého zoznamu okien. *Na premyslenie pred prácou:* náhľady okien v engine (pleamar má
   službu `thumbnails`; miesto kvapky dnes nesie ikonu 30 × 30, náhľad potrebuje väčší obrázok a obdĺžnikový tvar),
   odkiaľ je monitor „široký“, čo robí Stash v Hyprlande (pravidlá okien alebo vlastné rozloženie). Náhľady sa
   dovtedy nerobia.

**8A.04** [ ] (Okná) hyprtrizone · r. 543–547
[ ] **hyprtrizone pre ultrawide monitory** (používateľ, 21. 10.; [github.com/nyrda/hyprtrizone](https://github.com/nyrda/hyprtrizone),
    MIT, doplnok Hyprlandu): tri zóny — hlavné okno v strede, po stranách samostatné posúvateľné stĺpce, párovanie
    okien, ťahanie myšou, lišty nad bočnými stĺpcami. Ako ďalší režim v Nastavenia › Okná („Tri zóny“), ponúknutý
    pri monitore 21:9 a širšom (latte-lab DP-3 2560 × 1080). Zostaviť pre nainštalovaný Hyprland ako hyprbars
    (`optional /usr/lib64/latteos/…` vo FILES), autor v TRETIE-STRANY.md.

**8A.05** [x] (Okná) R3·B — základná integrácia · r. 971–972

**8A.06** [ ] **Režimy okien 1–9** (používateľ 27. 10.): 1 Páska · 2 Plávajúce · 3 Dlaždice · 4 Glance · 5 Canvas · 6 Tri zóny
(hyprtrizone, 8A.04); 7–9 voľné na neskôr. Každý monitor má **svoj režim** (8A.13). Režim sa volí v karte BarGoo (6A.08)
alebo napevno v Nastavenia › Okná › Ako sú okná usporiadané; s pevným režimom sa dá BarGoo aj vypnúť (6A.05).

**8A.07** [ ] **Páska presne ako niri**: prečítať kód niri (`src/layout/scrolling.rs`, GPL-3.0) a správanie preniesť na
Hyprland `scrolling` — vie už `explicit_column_widths` + `colresize ±conf` (1/3 · 1/2 · 2/3 · celá), `consume`/`expel`
(okná pod sebou v stĺpci), `swapcol`, `fit`, `focus_fit_method` 0 = stred. Chýba: nové okno vpravo od aktívneho, stĺpec
ako záložky, plávajúca vrstva nad páskou (okno ostáva súčasťou pásky), posúvanie ťahaním za prázdno a gestom, prehľad
(8A.10). Všetko myšou (ponuka okna, titulok). Kód z niri smie byť prevzatý; potom LatteOS prejde z MIT na GPL-3.0 (používateľ 27. 10.).

**8A.08** [ ] **Plávajúce ako Windows 11**: jediný režim s ikrami; náhľad cieľa pri prichytení, Snap Layouts (ponuka
rozložení po podržaní nad □), skupiny prichytených okien, vlastné rozloženia zón (ako FancyZones / dlaždice Plasmy).

**8A.09** [ ] **Dlaždice: dwindle s hlavným oknom** (používateľ 27. 10.): pravý klik na titulok › „Nastaviť ako hlavné“
urobí z okna master a plochu prepne z `dwindle` na `master`; „Zrušiť hlavné“ vráti `dwindle`. Popis režimu (karta BarGoo,
Nastavenia) to vysvetlí.

**8A.10** [ ] **Kreslenie okna v mierke** — spoločný kus pre prehľad Pásky, Glance aj Canvas, robí sa pred nimi. Predlohy
(Hyprland pluginy, BSD-3): [hyprland-scroll-overview](https://github.com/yayuuu/hyprland-scroll-overview) (prehľad ako
niri), [Phantomat](https://github.com/kaolti/phantomat) (z neho vychádza). Overiť, či kreslia okná živé.

**8A.11** [ ] **Glance: živé zmenšené náhľady v Parkingu** (video v prehliadači či VLC, na pohľad vidieť, či Claude Code
pracuje alebo čaká); keď to technicky nepôjde, obnovované miniatúry (služba `thumbnails` pleamaru). Podľa 8A.10.

**8A.12** [ ] **Canvas** — Phantomat skúsiť (používateľ 27. 10.) (používateľ 27. 10.): voľné okná na nekonečnej ploche ako plátno v ComfyUI — odzoomovať a vidieť
desiatky rozložených okien, klikom priblížiť. Prevziať [Phantomat](https://github.com/kaolti/phantomat) (BSD-3, Hyprland
0.56 s Lua, aktívny; zoom cez Ctrl+koliesko, ťahanie plochy, hľadanie okna, mapa); náhrada
[hypr-canvas](https://github.com/aaronsb/hypr-canvas) (MIT, „super alpha“). Samostatné kompozitory (driftwm, Infinidesk,
mary) nie — LatteOS ostáva na Hyprlande. Overiť: Phantomat ruší plochy (workspaces) — dá sa zapnúť iba pre jeden monitor
a vypnúť pri inom režime bez reštartu?

**8A.13** [ ] **Režim pre každý monitor** (používateľ 27. 10.): v Nastavenia › Okná rovnaká mapa monitorov ako v Nastavenia ›
Obrazovky a pri snímke obrazovky; tu sa monitormi nehýbe, klik na monitor mu prepne režim. Hyprland vie rozloženie podľa
plochy (pravidlá plôch).

### 8B. [~] Obrazovky
Rozpoznanie a rozloženie monitorov, virtuálny monitor, rozšíriť/duplikovať.
Zdroje: `bin/latte-screens`, `system/hypr/hyprland.lua`, Nastavenia › Obrazovky

**8B.01** [x] (Obrazovky) viac monitorov, prvá časť · r. 88–89

**8B.02** [x] (Obrazovky) Rozpoznanie obrazoviek · r. 308–320 — (a)–(d) hotové 13. a 26. 10.; (e) patrí k inštalátoru (2), skúška so skutočným monitorom do STRESTEST 017
[x] **Rozpoznanie pripojených obrazoviek** (13. 10., z prvého behu Fresh na latte-lab). latte-lab beží väčšinou iba
   cez Moonlight na virtuálnej DP-1 (EDID LATTE-VIRT); skutočný monitor DP-3 býva pripojený len občas. Prvý štart Fresh
   so skutočným monitorom dal hlavnú scénu Goo na virtuálnu obrazovku, ktorú nikto nevidí, lebo `main_monitor()`
   v `system/hypr/hyprland.lua` hľadal monitor presne na 0,0 a pri `position = "auto"` tam žiadny nebol. Treba:
   (a) hlavný monitor = skutočný (nie LATTE-VIRT), ináč ten najviac vľavo; (b) virtuálny sa pri skutočnom zrkadlí
   na hlavný (Hyprland `mirror`; overené 13. 10., zrkadlo aj škáluje), bez neho je hlavný on; (c) zmena pri
   pripojení a odpojení za behu (scéna Goo sa presunie, dnes ju presúva `place_shell`); (d) voľba „Duplikovať“
   v Nastaveniach › Obrazovky; (e) inštalátor to pri viacerých obrazovkách nastaví sám. Overiť so Sunshine (KMS).
   **Urobené 13. 10.: (a), (b), (c)** — `main_monitor()` berie skutočný monitor pred virtuálnym a z nich ten najviac
   vľavo; virtuálny sa pri skutočnom zrkadlí a po jeho odchode je zasa sám sebou; ktoré scény bežia, rieši
   `bin/latte-screens` podľa toho, čo naozaj beží (predtým si to pamätal Hyprland a po `hyprctl reload` to stratil).
   Overené bez obrazovky s napodobeným virtuálnym monitorom a v `tests/test_screens.sh`. **Neoverené:** na latte-lab
   so skutočným monitorom a s Moonlight. Ostáva (d), (e).
   **26. 10.:** (c) a (d) overené na živej relácii latte-lab s hlavičkovými výstupmi Hyprlandu (`hyprctl output
   create headless`) popri virtuálnom DP-1: pripojenie, odpojenie, Duplikovať, Rozšíriť, odpojenie hlavného pri
   duplikovaní. Opravené tri chyby v `system/hypr/hyprland.lua`: (1) nový monitor má pri `monitor.added` ešte
   x = −1, takže dostal hlavnú scénu, hoci bol vpravo (teraz sa čaká 600 ms, kým Hyprland monitory rozmiestni);
   (2) po Rozšíriť chýbala lišta okien na monitore, ktorý predtým zrkadlil, lebo `hl.get_monitors()` zrkadlené
   monitory nevracia a vrátený monitor nijaká udalosť neohlási (ak sa zrkadlenie zruší, `place_shell` sa po 600 ms
   spustí znova); (3) keď odíde monitor, ktorý iný zrkadlí, Hyprland zrkadlenie zruší a virtuálny ostal samostatný
   bez lišty (monitor v zozname sa zrkadlí znova). Skutočný DP-3 a Sunshine: záverečné testy (STRESTEST 017). (e) patrí
   k inštalátoru (2).

**8B.03** (pozn.) (Obrazovky) Rozšíriť / Duplikovať · r. 1341–1343
- **Obrazovky: Rozšíriť / Duplikovať** (`latte.duplicate`, `~/.config/latteos/screens`); overené bez
  obrazovky s dvoma monitormi oboma smermi. Opravené pritom: návrat zo zrkadlenia musí `mirror` zrušiť výslovne
  (týkalo sa aj virtuálneho monitora po odpojení skutočného).

**8B.04** [x] (Obrazovky) Hlavná obrazovka a rozloženie myšou — **pegboard** (je tam vždy, aj pri jednej obrazovke; ohraničený, spodným okrajom sa ťahá vyšší, aby sa obrazovka dala dať nad či pod hlavnú — obrazovky pri tom ostávajú rovnako veľké; koliesko nad ním približuje a odďaľuje na jemný posun; ťahať sa dá každá obrazovka aj hlavná a čiary okrajov ju pri tom nasledujú; tlačidlá Viac vľavo/vpravo a Trochu vyššie/nižšie zrušené) (používateľ 26. 10.: „kde má plynulo prejsť kurzor
z jednej obrazovky na druhú“, okno cez dve obrazovky v rovnakej výške): v Nastaveniach › Obrazovky sa obrazovky v obrázku
ťahajú myšou (skutočný pomer a rozlíšenie, aj medzery; okraj blízko suseda sa k nemu prichytí, na inú obrazovku sa pustiť
nedá); **štyri okraje hlavnej obrazovky** ako červené čiary predĺžené v obrázku aj **na ostatných skutočných obrazovkách**
(na hlavnej nie; vodorovné horný a spodný, zvislé ľavý a pravý pre obrazovku nad či pod hlavnou; vrstva cez všetko, myš
ňou prejde — návrh používateľa) a obrazovka sa posúva po 4 px „Trochu vyššie/nižšie“, kým čiary nenadväzujú na okraje hlavnej. Hlavná = tá na 0,0 (Nastavenia aj `main_monitor()` teraz rovnako; predtým Hyprland bral tú
najviac vľavo a „Urobiť hlavnou“ pre pravú nefungovalo). Overené naživo s dvoma hlavičkovými výstupmi: ťahanie, návrat po 15 s,
odmietnutie prekrytia, čiary na 3000 × 2000 vyššie vedľa hlavnej (horná a spodná) a na obrazovke pod ňou (zvislá). Skutočný DP-3: `docs/manual-inst.md`.

**8B.05** [x] (Obrazovky) Ako Windows › Obrazovka (používateľ 26. 10., podľa snímok Windows 11): **rozlíšenia** — k tým, čo monitor
hlási, bežné rozlíšenia až po jeho najväčšie (najmenej 1024 × 768), najväčšie „(odporúča sa)“; virtuálny monitor ich berie
ako vlastný režim (overené: DP-1 prešiel na 1366 × 768 a po 15 s späť); **Identifikovať** — veľké číslo a meno na každej
obrazovke na 3 s, to isté číslo na pegboarde; **Nočné osvetlenie** — prepínač a sila (Slabé 5500 K, Teplé 4500 K, Silné
3500 K) cez `hyprsunset` a nový `bin/latte-nightlight` (voľba v `~/.config/latteos/nightlight`, obnoví sa pri štarte relácie).

**8B.06** [ ] (Obrazovky) Zvyšok stránky Obrazovka z Windows 11: Nočné osvetlenie **podľa času** (od západu do východu slnka —
`latte-sky` ich pozná) a dlaždica v paneli Pobrežia; **HDR** a **profil farieb** (Hyprland 0.56: `cm`, `bitdepth`; zistiť, či
monitor HDR vie); **Rozšírené nastavenia** (údaje o monitore, VRR); **Grafika** (ktorá karta pre ktorú aplikáciu, pri dvoch GPU).

### 8C. [~] Sklo a materiály
Sklo okien (Hyprglass), materiály šálky.

**8C.01** [x] (Vzhľad, témy a tapety) sklo okien · r. 195–195


**8C.02** [ ] **Posledné dva stupne skla sa správajú inak** (používateľ 26. 10.): pri predposlednom (Najviac) a poslednom
(True Glass) stupni platia pre priehľadnosť iné pravidlá než pri ostatných (True Glass robí okná priehľadné samy
aplikácie LatteOS, iné nie; karty a okná sa líšia). Zjednotiť, aby stupne išli plynulo za sebou; riešiť neskôr s témami (9A).
### 8D. [~] Okno aplikácií LatteOS
Spoločné okno aplikácií: bočný panel zo skla, hladina dole (`apps/common/AppWindow.qml`).
Zdroje: `apps/common/` (AppWindow, Surface, Menu); LATTEOS-GOO §6.3·0

**8D.01** [x] (Okno aplikácií LatteOS (spoločné)) Okno aplikácií LatteOS · r. 117–120
- [x] **Okno aplikácií LatteOS** (rozhodnuté 13. 10. podľa používateľovho V2 a ForkLiftu): `apps/common/AppWindow.qml`
  — bočný panel zo skla od vrchu po spodok, hore lišta s funkciami (šípky, názov, nástroje aplikácie, hľadanie),
  úplne vpravo okenné tlačidlá; kávová hladina je rozhraním k spodnej časti okna, alebo iba tichým pozadím.
  App Manager je v ňom ako streamovacie menu (banner s ďalším nakúkajúcim, rad volieb, plagáty).

**8D.02** [ ] (Okno aplikácií LatteOS (spoločné)) R3·B — GUI pri malom rozlíšení · r. 975–976
- [ ] Dokončiť konkrétne otvorené GUI a interakcie pri malom rozlíšení, vrátane stavov
  načítania/chyby a návratu rizikovej zmeny; hotové základy tém a nastavení neopakovať.

**8D.03** [ ] (Okno aplikácií LatteOS (spoločné)) hladina na spodku okna · r. 1378–1381
[ ] **Hladina na spodku okna aplikácie ako miesto pre dve veci** (používateľ, 14. 10.): (a) **zaujímavé funkcie**
    aplikácie, zvýraznené výraznou ikonou ako Barista v App Manageri; (b) **tooltip**: rady a triky, a popis
    tlačidla, nad ktorým je kurzor. Platí pre každé okno s hladinou (`apps/common/AppWindow.qml`, `Surface.qml`).

---

## 9. [~] centralne nastavenia
Zdroje: `apps/settings.qml`, `apps/settings/`, `bin/latte-settings`; LATTEOS-GOO §6.2·2

**9.01** [~] (Nastavenia) Nastavenia · r. 152–178
[~] **Nastavenia** (13. 10.): `apps/settings.qml`, zoznam stránok `apps/settings/pages.json`, Win+I.
   Rozkladací bočný panel po oblastiach (Softvér · Dáta · Hardvér · Účet · Prostredie · Systém, 29 stránok)
   s bodkou stavu; hľadanie v hlavičke; **LensGoo hľadá aj v nastaveniach** (pod čiarou, `bin/latte-settings`).
   Hotové stránky: **Káva a šálka** (druh kávy = farba goo; šálka = z čoho sú okná: espresso, mokka,
   porcelán — svetlá; sklenená káva), **Pozadie** (obrázky LatteOS a z priečinka Obrázky; živé pozadia
   = filmy z priečinka Videá cez mpvpaper), **Okná** (režim; sklo bočných panelov), **Kvapky**, **O počítači**,
   **Uzamknutie a nečinnosť** (kedy sa zamkne a kedy zhasnú obrazovky), **Napájanie** (profil),
   **Zvuk** (výstupy a vstupy: ktorý sa používa, hlasitosť, stlmenie; cez `pactl`), **Predvolené aplikácie**
   (prehliadač, pošta, súbory, obrázky, video, hudba, text, PDF; cez `xdg-mime`),
   **Obrazovky** (rozlíšenie, obnovovanie, mierka, otočenie, poradie a hlavná obrazovka; zmena sa skúsi
   a bez potvrdenia sa do 15 s vráti; uložené v `~/.config/latteos/monitors`, číta `hyprland.lua`;
   plávajúce okná sa po zmene vrátia celé na obrazovku), **Jazyk a región** (`~/.config/latteos/locale`,
   od ďalšieho prihlásenia), **Dátum a čas** (pásmo a automatický čas cez `timedatectl`), **Klávesnica**
   (rozloženia hneď aj nabudúce, `~/.config/latteos/keyboard`; zoznam skratiek chýba),
   **Výkon a grafika** (stupeň vzhľadu: podľa hardvéru alebo vlastný, `~/.config/latteos/tier`),
   **Štart a režim SAFE** (ako dopadol tento štart; SAFE na ďalší štart cez `latte-boot force-safe`),
   **Úložisko** (disky, veľkosť priečinkov, kôš), **AI** (vypínač: `~/.config/latteos/ai`, `latte-ai`
   potom neponúkne nikoho), **Môj účet** (meno a obrázok cez AccountsService).
   Ostatných 11 stránok je vypísaných ako „ešte nie je“ s odkazom, kde sa to robí zatiaľ (Aplikácie,
   Aktualizácie, Spúšťanie, Sieť → App Manager, Monitor, Správca zariadení; bez náhrady: Zálohovanie,
   Cloud, Bluetooth, Tlačiarne, Heslo, Oznámenia, Prístupnosť).
   Šálka platí aj mimo aplikácií LatteOS (13. 10.): titulky cudzích okien (hyprbars) berú jej farbu
   a aplikáciám sa povie svetlý/tmavý režim (`latte.cup`, gsettings color-scheme). Vlastný súbor tapety
   a obrázka účtu sa vyberá systémovým oknom (portál; `latte-app` nastavuje `QT_QPA_PLATFORMTHEME`).
   Stránka Klávesnica vypisuje skratky: popis má každá priamo v `system/hypr/latte/keys.lua`
   (`hyprctl binds -j`), takže zoznam nemôže zastarať.
   Chýba: šálka v kartách Goo, zmena hesla, Bluetooth (latte-lab ho nemá).

**9.02** [x] (Nastavenia) nastavenia Goo ako karta · r. 188–188

**9.03** [~] (Nastavenia) Nastavenia · r. 490–494
- a. [~] **Nastavenia** (`latteOS settings priklad.png`; 21. 10. hotová domovská stránka ako „Systém a prehľad“ v dvoch stĺpcoch — nákres je úzky, okno nie: karta počítača, režim rozhrania s náhľadmi, sklo ako posuvník so 4 stupňami, káva, obrazovky, úložisko so „Správa oddielov“, karta účtu na boku; päta so stavom systému a **expertný režim** (21. 10.: základné nastavenia a všetko nad ne, prepínač v päte; ROZHODNUTIA)): hlavička s hľadaním, karta „Systém a prehľad zariadenia“
  (počítač, profil, procesor, pamäť, verzia LatteOS), režim rozhrania ako tri karty s náhľadom (tmavý, svetlý,
  podľa slnka), intenzita skla ako posuvník s percentami (dnes štyri stupne), kávová hladina, displej (rozlíšenie,
  obnovovanie, teplota farieb), úložisko s pásom podľa druhu dát a tlačidlom Správa oddielov, účet dole, päta
  so stavom systému a prepnutím na expertný režim.

**9.04** [ ] (Nastavenia) E. Nastavenia › Vzhľad · r. 782–782
- [ ] **Nastavenia › Vzhľad:** nastavenia jednotlivých Goo sú dnes v Nastaveniach › **Kvapky**, nie vo Vzhľade.

**9.05** (pozn.) (Nastavenia) R3·J — cieľ · r. 1114–1117
**Cieľ:** jedno miesto pre nastavenia LatteOS (Goo, výkon, jazyk, účty, AI, tapety) bez konkurenčných
nastavení Noctalie a ostatných prostredí.

**9.06** [x] (Nastavenia) R3·J — základ Nastavení · r. 1118–1118

**9.07** [ ] (Nastavenia) R3·J — zlúčiť nastavenia Noctalie · r. 1119–1119
- [ ] Selektívne zlúčiť vybrané nastavenia Noctalie (návrh v LATTEOS-GOO §4.10) a tapety na jedno miesto.

**9.08** [ ] (Nastavenia) R3·J — jazyky, efekty, výkon · r. 1121–1123
- [ ] Jazyky a preklady, efekty a výkon: dokončiť podľa R3·B; AI a limity podľa R3·G.

**9.09** (pozn.) (Nastavenia) zmena hesla · r. 1336–1337
- **Zmena hesla** (Nastavenia › Heslo a zabezpečenie; AccountsService `SetPassword`, terajšie heslo si pýta
  polkit). Neoverené naostro (okno na heslo je pri obrazovke).

**9.10** [ ] **Výskum: hľadanie v Nastaveniach so skutočnými ovládacími prvkami** (používateľ 27. 10.; inšpirácia
https://github.com/thesysdev/open-intelligent-ui — MIT, Next.js/React, model posiela opis rozhrania v OpenUI Lang
a aplikácia ho vykreslí; kód sa neprenesie, preberá sa princíp). Výsledok hľadania obsahuje živé prepínače,
posúvniky a odkazy na stránky. Príklad: „prečo sa mi po reštarte neobnovia okná?“ → diagram príčin, odkazy na
súvisiace nastavenia (Continuity 6E.02) a prepínače, ktorými to človek vyrieši priamo. **Pravidlo (návrh Clauda):**
AI nevymýšľa ovládacie prvky — smie iba odkázať na skutočné nastavenie podľa ID a vykreslí sa pravý prvok
z Nastavení, ktorý mení skutočnú hodnotu; voľne generuje iba vysvetlenie a diagram. **Bez AI** (2B) hľadanie podľa
kľúčových slov ukazuje tie isté skutočné prepínače, len bez diagramu. Platí aj pre LensShore (6B.12).
Potrebné: register nastavení s ID, názvom, kľúčovými slovami a prekladmi.

**9.11** [ ] **Nastavenie hustoty informácií** (používateľ 27. 10.; pravidlo 24): Kompaktné · Normálne · Vzdušné, ako
v Gmaile alebo Prieskumníku Windows. Mení rozostupy a výšku riadkov, koľko riadkov a podrobností ukáže karta kvapky,
TrayShore a aplikácie LatteOS, a čo z vrstvy 1 sa presunie do vrstvy 2 (alebo naopak). Druhy plochy (6A.05) môžu
mať vlastnú predvolenú hustotu. Platí pre Goo aj aplikácie (Quickshell) rovnako.

### 9A. [~] Vzhľad a témy
Téma (šálka, farby z tapety), Keramika/Hliník/Onyx/Steam, ikony, vizuálne podoby podľa `inspo/`.
Zdroje: `apps/common/Theme.qml`, `bin/latte-wall`, `bin/latte-walls`, `inspo/`, `docs/goo/PRAVIDLA.md`

**9A.01** (pozn.) (Vzhľad, témy a tapety) posúvniky a prepínače podľa Vitreusu · r. 370–370
- **Posúvniky a prepínače podľa Vitreusu** v Pobreží a Nastaveniach (hrubnutie, širšia zóna, zaplavenie farbou).

**9A.02** [ ] (Vzhľad, témy a tapety) Vizuálne podoby podľa inspo/ · r. 487–489
[ ] **Dokončiť vizuálne podoby podľa návrhov v `inspo/`** (používateľ, 21. 10.; nákresy z 20. 10.). Hotové z nich:
    bodkové grafy (`grafy.png` → `DotGraph`), dvojvrstvová kávová hladina (`latteOS settings priklad.png` → `Surface`).
    Farby z témy, nie natvrdo; texty cez preklady; sklo podľa jedného stupňa LatteOS (Nastavenia › Okná › Sklo).

**9A.03** [ ] (Vzhľad, témy a tapety) Témy Keramika, Hliník, Onyx, Steam · r. 507–509
- f. [ ] **Témy Keramika, Hliník, Onyx, Steam** (používateľ, 21. 10.): v `Theme.cups` sú zatiaľ Espresso, Mocha,
  Porcelán a Z tapety; doplniť ich (aj materiál okien podľa PRAVIDLÁ bod 12). Aplikácie berú farby iba z témy
  (DualBrew, LensAI, Nastavenia…), takže sa prefarbia samy — overiť snímkou každú tému.

**9A.04** (pozn.) (Vzhľad, témy a tapety) F. R3·B — shell a vzhľad · r. 840–845
**R3·B — shell a vzhľad:** téma Latte a Úsporná, farby z tapety (r. 274); prvky stupňa Plný, varianty bez shaderov (r. 275–276, 290);
materiál na oknách pri kovových témach (r. 521); Noctalia prekreslí celý povrch pri zmene widgetu (r. 939); animácie panelov na GPU (r. 968);
ovládacie centrum Noctalie — overiť (r. 630); dialóg Otvoriť/Uložiť cez portál v jednotnom vzhľade (r. 590);
vlastné `app_id` a preložiteľné spúšťače (r. 654); slovenský preklad Noctalie a záplaty pleamaru autorom (r. 656, 658); preklady odložené nakoniec (r. 725);
živá tapeta a shaderové prechody (r. 1013–1014; skwd-wall rozhodnutý, R3·J).

**9A.05** (pozn.) (Vzhľad, témy a tapety) R3·B — cieľ · r. 967–970
**Cieľ:** Hyprland, Lua integrácia, Noctalia a Goo spolu tvoria jednu plochu bez konkurenčných
nastavení, duplicitných panelov alebo nekonzistentného správania.

**9A.06** [ ] (Vzhľad, témy a tapety) R3·B — tapety, materiály, sklo · r. 979–980
- [ ] Tapety, materiály, dážď, sklo a animované prechody zavádzať ako voliteľnú vrstvu vzhľadu,
  nie ako požiadavku pre funkčnosť desktopu.

**9A.07** [ ] (Vzhľad, témy a tapety) Vzhľad: téma namiesto kávy · r. 1303–1329
[ ] **Vzhľad: téma namiesto „kávy“** (používateľ, 13. 10. v noci). Vzhľad je vec zvolenej témy a nemusí to byť
    káva; okná sú „šálka“ a tá môže byť širšie spektrum; moderné je brať farby témy **automaticky z tapety**.
    Smer vzhľadu: **prevziať veľa z Vitreusu** (github.com/natepayn3/Vitreus, MIT, postavený na pleamare:
    tekuté sklo, panely vytekajúce z lišty, výber tapiet, kalendár s počasím, ponuka programu v skle shellu).
    Kroky: (a) téma ako jedno miesto pre aplikácie (`Theme.qml`), titulky okien (`latte/bars.lua`) aj Goo;
    (b) `cup = wallpaper`: paleta vypočítaná z tapety pri jej zmene; (c) prejsť Vitreus a vybrať, čo prevziať.
    **Urobené 13. 10. v noci:** sada ikon sa volí v Nastaveniach › Káva a šálka › Ikony (`latte-settings icons`,
    `~/.config/latteos/icons`, číta `latte-app`; predvolená **Yaru**; ponúkne každú nainštalovanú z Yaru, Papirus,
    elementary, Fluent, Mint-Y, Breeze, Adwaita) a ikony na ploche majú aj veľmi veľké a obrovské.
    **Vitreus pozretý 13. 10.** (zdroják stiahnutý, snímky z `tour.webp` a zo štyroch panelov; pohyb okien samotný
    som nevidel, iba panely a výmenu tapety). Čo tam robí dojem okrem skla:
    - *rozloženie:* panel je dlaždice v dlaždici — veľké zaoblené karty, v nich menšie; hlavičky sekcií malými
      verzálkami (VISUALS, SYSTEM, BUILD); jedno veľké číslo ako kotva (čas 6:44, 50 %); omrvinky v hlavičke
      nastavení; vľavo úzky zoznam, vpravo obsah; riadok s tlačidlami na spodku karty;
    - *živosť:* panel vyteká z lišty tekutým krkom a tou istou pružinou sa do nej vracia; nad záložkami
      hľadania sa za kurzorom vlečie svetlá kvapka; riadky prichádzajú postupne; tapeta sa mení rozsypaním do
      štvorčekov a s ňou sa prefarbí celé sklo aj akcent (rad farebných bodiek = akcent, alebo z tapety);
    - *výber tapety:* plást šesťuholníkov zo skla, ten pod kurzorom sa nadvihne a nakloní;
    - *plocha („Desk“):* veľké hodiny, poznámky, časovač ako sklenené predmety, ktoré sa dajú ťahať.
    **13. 10. v noci urobené z návrhu:** (1) dashboard — výsuvný panel Pobrežia je nízky a široký pri spodnom
    okraji: vľavo ovládanie, vpravo čo hrá a schránka; kalendár, počasie a upozornenia ostávajú v ClockGoo
    (rozhodnutie používateľa); (3) farby z tapety pre okná a aplikácie — bod 14. Ostáva (2) a prefarbenie Goo.
    **Návrh pre LatteOS (pôvodný):** (1) výsuvný panel Pobrežia prerobiť na **dashboard pri spodnom
    okraji**: počasie + kalendár + ovládanie (sieť, Bluetooth, Nerušiť, jas, hlasitosť) + prehrávač + upozornenia
    ako dlaždice v jednom skle; (2) dlaždicové rozloženie a malé hlavičky do kariet Goo a do `AppWindow`;
    (3) akcent a tón skla z tapety (bod b); (4) prechod tapety a plást na jej výber (bod 14 namiesto skwd-wall
    alebo vedľa neho).

**9A.08** [~] (Vzhľad, témy a tapety) Dokončenie prvkov prostredia — úvod · r. 1330–1331
[~] **Dokončenie prvkov prostredia** (používateľ, 13.–14. 10.: najprv prvky prostredia, meranie a STRESTEST potom;
    **Prístupnosť sa nerobí teraz, až v Arabice 1+**). Urobené 14. 10. v noci:

**9A.09** (pozn.) (Vzhľad, témy a tapety) okraj okien podľa témy · r. 1335–1335
- **Okraj okien podľa témy** „Podľa tapety“ (`latte/bars.lua` `B.border`).

**9A.10** (pozn.) (Vzhľad, témy a tapety) ostáva z prostredia · r. 1345–1348
**Ostáva z prostredia:** dlaždicové rozloženie a malé hlavičky podľa Vitreusu (karty Goo, `AppWindow`),
náhľady v Parkingu režimu Glance, Súbory (dnes Nautilus), plocha: Späť a „Tento počítač“, skratka na výber
tapety, stránky Nastavení Tlačiarne · Zálohovanie · Cloud, jazyk z prihlásenia do relácie, Barista,
inštalátor so sprievodcom, ChatGoo (Beeper), okno z bubliny QueenGoo.

### 9B. [x] O tomto počítači
Stránka Nastavenia › Systém › O tomto počítači, vrátane grafu vývoja LatteOS.

**9B.01** [x] (Nastavenia) Vývoj LatteOS v O tomto počítači · r. 538–542
[x] **Vývoj LatteOS v Nastavenia › Systém › O tomto počítači** (hotové 21. 10.: `bin/latte-activity` zapíše históriu repa do `build/activity.json` pri `./install --go`, inštaluje sa ako `/usr/share/latteos/activity.json`; graf 53 týždňov so štvorčekmi v farbách témy a nápovedou pri myši, 30 posledných commitov rozbaliteľných — autor, dátum, celá správa, zmenené súbory s +/−. **Rozhodnutie pre vydania:** verejné `arkaysk/latteos` má iba snímky vydaní, preto graf nesie súbor z repa, nie GitHub API; či vydanie smie niesť správy commitov, je na `zverejnit.sh`). (používateľ, 21. 10.): štvorčekový graf aktivity
    (ako na GitHube: týždne v stĺpcoch, dni v riadkoch, sýtosť podľa počtu commitov) — ako pokračuje vývoj projektu;
    pod ním posledné commity, každý rozbaliteľný: dátum, autor, správa celá a čitateľne, zmenené súbory. Zdroj:
    verejné repo LatteOS cez GitHub API (`/stats/commit_activity`, `/commits`), bez siete posledné uložené; na
    vývojárskom stroji aj `git log` miestneho repa. Graf ako `DotGraph` (bodky v štvorcoch), farby z témy.

---

## 10. [~] Nativne aplikacie
su tie dodavane priamo s LatteOS od vydavatelov latteOS

### 10A. [~] DualBrew
Zdroje: `apps/files.qml`, `bin/latte-files`, `apps/common/FileIcons.qml`
suborovy manager na vzor Total Comander

**10A.01** [~] (23. 10. opravené: zvýraznenie výberu ako samostatný obdĺžnik, hover cez HoverHandler; čaká na potvrdenie) najdena chyba-ked je aktivna priehladnot a ked sa klikne na položku/složku. ta sa samozrejme označi, ale pri kliknuti inam, sa zmeni jej priehladnot a je vydiet tapetu za aj ked predtým nebola. nevrati sa to na predchodzi vzhlad až do refresh.

**10A.02** [~] (DualBrew (Súbory)) DualBrew · r. 495–498
- b. [~] **DualBrew** (`latteOS dualbrew.png`; 21. 10. hotové: Dva panely | Jeden panel, čipy jednotiek nad panelom s voľným miestom, súhrn pod panelom, pás tlačidiel medzi panelmi, rad F3–F10, riadok terminálu (Alt+F1), rýchly filter typov; ostáva stĺpec Atribúty (práva), filtre priečinkov nad zoznamom): dvojpanel ako Total Commander (Dvojpanel / 1-panel), jednotky ako
  čipy nad panelom, stĺpce Názov · Veľkosť · Zmenené · Atribúty, tlačidlá medzi panelmi (kopírovať, presunúť,
  porovnať, zrkadliť), rad F3–F10 dole a riadok terminálu (Alt+F1); bočný panel s diskami a pásmi zaplnenia
  (čiastočne hotové 20. 10.), obľúbené priečinky a rýchly filter typov.

**10A.03** [ ] (DualBrew (Súbory)) D. Súbory · r. 691–692
- [ ] **Súbory:** nadviazať na hotové dvojpanely, prenosy, archívy, vyhľadávanie, sieť a cloud;
  uzavrieť otvorené rozšírenia/UX, odolnosť pri chybách a potrebné overenie hardvéru.

**10A.04** (pozn.) (DualBrew (Súbory)) F. R3·C — Súbory a Heidelberg · r. 846–849
**R3·C — Súbory (DualBrew) a Heidelberg:** prostredie nad pôvodným súborovým systémom (r. 565); **plná funkčnosť Total Commandera** (r. 979:
vlastné stĺpce r. 985, skratky a menu r. 1008, pluginy r. 1012); Data Manager v Ruste (r. 782); Flea ako možný základ — odložené (r. 614);
hľadanie v obsahu PDF/DOCX (r. 849); Heidelberg verné docx (r. 792); Strata ako vzor — stĺpcové zobrazenie (Miller), ovládanie klávesnicou, približné hľadanie mien (inspo 13. 10.).

**10A.05** (pozn.) (DualBrew (Súbory)) R3·C — cieľ · r. 985–988
**Cieľ:** Súbory bezpečne a zrozumiteľne spravujú pôvodný Linuxový súborový systém, pripojené
zariadenia, sieťové miesta a cloud bez uzamknutia dát do LatteOS.

**10A.06** [x] (DualBrew (Súbory)) R3·C — základ správcu súborov · r. 989–990

**10A.07** [x] (23. 10. overené na webe: žiadny softvér ani projekt na GitHube sa nevolá DualBrew; najbližšie je kávovar BUNN „Dual BrewWISE“ — iný odbor, iné meno. Meno ostáva) (DualBrew (Súbory)) R3·C — názov DualBrew · r. 991–993
- [ ] **Názov správcu súborov (rozhodnúť):** ak ostane vlastný a obohatený o nápady iných autorov, potrebuje meno.
  Kandidáti autora: Espresso Commander, Tamper, DualBrew. **Vybraný DualBrew (9. 10.)**; pred zavedením skontrolovať kolízie
  s existujúcimi projektmi.

**10A.08** [ ] (DualBrew (Súbory)) R3·C — rozšírenia a ergonómia · r. 995–996
- [ ] Doriešiť otvorené rozšírenia (vlastné stĺpce/pluginy, klávesové skratky a menu) a ergonomické
  medzery podľa používateľských scenárov.

**10A.09** [~] (23. 10.: telefóny a fotoaparáty cez kábel (gvfs mtp, gphoto2, afc) ako druh Telefón medzi diskami, s vysunutím. Ostáva overiť so skutočným telefónom, SMB a odpojením počas kopírovania) (DualBrew (Súbory)) R3·C — úložisko, USB, SMB, cloud · r. 997–998
- [ ] Dokončiť integráciu úložiska, USB, SMB/GVFS, telefónov a cloudových miest; pri odpájaní,
  prerušení siete a nedostatku miesta jasne oznámiť stav a zachovať dáta.

**10A.10** [ ] (DualBrew (Súbory)) R3·C — prerušené operácie · r. 999–1000
- [ ] Overiť bezpečné správanie pri prerušení kopírovania/synchronizácie, chybe zariadenia a
  obnove; zachovať už implementované plány synchronizácie, priebeh a zrušenie operácií.

**10A.11** [ ] (DualBrew (Súbory)) R3·C — veľké súbory a chyby · r. 1001–1002
- [ ] Overiť veľké súbory, archívy, oprávnenia, symlinky, odpojené disky, obmedzený priestor a
  bezpečné správanie pri chybe; zachovať prístup k súborom aj bez LatteOS UI.

**10A.12** (pozn.) (DualBrew (Súbory)) R3·C — cloud ako návrh · r. 1003–1005
Nové cloudové služby sa najprv posudzujú ako návrhy; cloud nesmie byť podmienkou lokálnej práce.

**10A.13** [~] (DualBrew (Súbory)) DualBrew — prvá verzia a disky · r. 1382–1399
[~] **DualBrew, Súbory** (používateľ, 14. 10.). Prvá verzia pre 0.4, písaná načisto:
    **Disky a zariadenia** (používateľ, 21. 10.; hotové v ten deň): pri každom disku v bočnom paneli pás zaplnenia
    a koľko ostáva; nadpis Disky a zariadenia otvorí prehľad (`disks:`) ako KDE Partition Manager — disky, pás oddielov
    podľa veľkosti, nerozdelené miesto, skutočné zaplnenie každého súborového systému (`latte-files disks`).
    Ďalej: vytvoriť a zväčšiť oddiel do nerozdeleného miesta (s heslom správcu), upozornenie pri plnom disku (bod 15).
    `apps/files.qml` + `bin/latte-files` (kopírovanie, presun, odkaz, Kôš, nový priečinok a súbor, premenovanie,
    schránka kompatibilná s plochou a inými správcami, miesta a disky; súbory hýbe `gio`) + spoločné ikony
    súborov `apps/common/FileIcons.qml` (aj pre plochu). Okno LatteOS: vľavo miesta (Domov, Plocha, Dokumenty…,
    Kôš, disky), hore Vyššie · Nový priečinok · Ikony/Podrobnosti · **Dva panely**; cesta ako klikateľné omrvinky;
    výber klikom, Ctrl, Shift; pravý klik = ponuka (Otvoriť, Otvoriť v programe, Otvoriť v druhom paneli,
    Vystrihnúť, Kopírovať, Kopírovať ako cestu, Premenovať, Odstrániť; na prázdnom mieste Zobraziť, Obnoviť,
    Prilepiť, Nový, Otvoriť v termináli). Na hladine dole: počet položiek a výber; pri dvoch paneloch klávesy
    commanderu **F5 Kopírovať · F6 Presunúť · F7 Nový priečinok · F8 Odstrániť**; mená sa pýta tam.
    `latteos-files.desktop` (otvára priečinky; predvolený správca sa volí v Nastaveniach › Predvolené aplikácie).
    Overené naostro: zoznam, dva panely, F5 do druhého panela, F7 s menom, ponuka položky.
    **Chýba oproti v0.3 a Total Commanderu:** karty, ťahanie myšou medzi panelmi a von, rad úloh s priebehom
    (dnes sa kopíruje bez ukazovateľa), archívy, hľadanie, náhľad (F3) a úprava (F4), synchronizácia, sieť
    (FTP/SFTP/SMB) a cloud, obnovenie z Koša, vlastnosti, triedenie podľa stĺpcov, strom, stĺpcové zobrazenie.

**10A.14** (pozn.) (DualBrew (Súbory)) DualBrew · štítky a farby · r. 1400–1403
**Štítky a farby (používateľ, 14. 10.):** v0.3 mal Farbu v ponuke súboru a priečinka, uloženú v
`~/.config/latteos/tags.json` (iba pohľad Súborov, viazaný na cestu). Pre 0.4: štítok do rozšíreného atribútu
`user.xdg.tags` priamo pri súbore (overené na latte-lab: prežije presun aj kópiu so zachovaním atribútov) —
je to konvencia freedesktop, ktorú číta aj Dolphin; mimo Linuxu (Windows, FAT/exFAT, zip, cloud) sa stratí.

**10A.15** (pozn.) (DualBrew (Súbory)) DualBrew · čo mal v0.3 a návrhy · r. 1404–1412
**Čo už v0.3 mal a používateľ k Súborom navrhoval** (`old/docs_zaloha/2026-10-09-roadmap-pred-ciscenim.md`
r. 566–591, 782–804, 982–1016): karty, hotlist, strom, plochý pohľad, rýchly náhľad, Lister F3 (text, hex,
obrázok, médiá), rad úloh s pauzou a overením SHA-256, hromadné premenovanie, porovnanie a synchronizácia
priečinkov, porovnanie súborov, archívy ako priečinky (aj s heslom), hľadanie (obsah, regex, v archívoch),
veľkosti priečinkov, práva a vlastník, odkazy, kontrolné súčty, rozdeliť/spojiť, riadok príkazu, vlastné
tlačidlá, FTP/SFTP/SMB/WebDAV/cloud (rclone, ~/Cloud), Kôš s obnovením, DiskTree (čo zapĺňa priečinok),
zoxide (často používané), Poslať do telefónu (KDE Connect), „Bude to fungovať?“ pri .exe. Nedokončené
nápady: vlastné stĺpce, úprava skratiek a ponúk, pluginy, odkladacia kvapka na súbory (ako Dropover),
značky a synchronizované priečinky so stavom (vzor Spacedrive, Nextcloud).

**10A.16** (pozn.) (DualBrew (Súbory)) DualBrew · medzerník a štruktúra pre človeka · r. 1413–1420
**14. 10. ráno (používateľ):** Medzerník bez výberu = koľko zaberá každý priečinok — v aktívnom paneli čísla
a pruhy, v druhom paneli „Čo zapĺňa …“ zoradené od najväčšieho (dvojklik vojde, Esc alebo Späť zavrie), aj
v ponuke Zobraziť › Koľko zaberá každý priečinok (dnes mapa, `latte-files tree`, plní sa priebežne).
**Štruktúra pre človeka:** predvolene svet používateľa — „Tento počítač“ (priečinky a disky ako dlaždice),
cesta od Tento počítač › Domov/disk, Vyššie z domova vedie na Tento počítač, nie do `/`; systémové priečinky
nie sú po ceste. **Skutočná štruktúra** (bočný panel, Zobraziť) ukáže Linux od `/` vrátane disku `/`.
Overené naostro: meranie (4,9 GB repozitára), panel veľkostí, Esc, Tento počítač.

**10A.17** (pozn.) (DualBrew (Súbory)) DualBrew · ergonómia pre myš · r. 1421–1433
**14. 10. ráno, ergonómia pre myš (používateľ: „výrazne lepšie než konkurencia“):** panel, v ktorom sa pracuje,
je nad kávou (zlatý rám, svetlejší), druhý pod ňou (závoj kávy tmavnúci ku dnu, línia hladiny hore).
Ťahanie súborov myšou: do druhého panela, na priečinok (zlatý rám), von do inej aplikácie a dnu z hocijakej
(na tom istom disku presun, na iný kópia, s Ctrl kópia). **Úlohy na hladine**: kopírovanie a presun s
priebehom v %, Pozastaviť/Pokračovať, Zastaviť (načatý súbor sa zmaže), ďalšie čakajú v rade
(`latte-files job`). Stredné tlačidlo na priečinku = otvoriť v druhom paneli; tlačidlá myši Späť/Dopredu;
dvojklik na prázdne = vyššie; klik na hlavičku stĺpca = triedenie (znova obráti); Ctrl + koliesko = veľkosť
ikon. **Medzerník na súbore** = náhľad v druhom paneli (obrázok, začiatok textu, inak ikona; ide za výberom,
Esc zavrie). Overené naostro: stredné tlačidlo, F5 s priebehom na iný disk (1,5 GB, 77 % na snímke),
pauza, zastavenie s upratovaním, ťahanie do druhého panela (presun), náhľad obrázka, Späť myšou.
Opravené aj na ploche: ťahanie von do aplikácií nikdy nefungovalo (`Drag.active` a položka mimo okna).
**Chýba:** výber obdĺžnikom myšou, náhľad PDF a videa, ťahanie s pravým tlačidlom (ponuka Kopírovať sem…).

**10A.18** (pozn.) (DualBrew (Súbory)) DualBrew · mapa ako DiskTree · r. 1434–1443
**14. 10., mapa ako DiskTree (používateľ):** „Čo zapĺňa…“ už nie je zoznam, ale mapa obdĺžnikov
(squarified treemap, tri úrovne priečinkov, `latte-files tree` = df + zoznam priečinkov + `du -abx -d 3`,
plní sa počas merania). Farba = druh (Kód, Obrázky/hudba/video, Dokumenty, Archívy, Programy a hry, Git,
Vyrovnávacie pamäte a zvyšky, Ostatné; priečinok bez druhu dedí od predka), legenda iba s druhmi, ktoré tu sú,
pruh disku (voľné z celku, červený pod 10 %), dole čo je pod myšou alebo vybrané (veľkosť, podiel, druh;
Dovnútra · Otvoriť · Odstrániť do Koša) a bez výberu „Stojí za pohľad“ (pamäte a zvyšky nad 50 MB).
Dvojklik na priečinok = priblížiť (zmeria tam), Vyššie, Späť. `latte-app files PRIEČINOK sizes` otvorí
rovno mapu. Overené v headless sedení: celý domov 77,8 GB, klik, dvojklik do flatpak, zdedené farby.
Prvé meranie studeného domova trvá ~80 s (du), opakované 2 s. **Chýba oproti DiskTree:** režimy Súbory
(počet) a Vek (posledný zápis), hĺbka a skryté súbory ako voľba, zdanlivá veľkosť.

**10A.19** (pozn.) (DualBrew (Súbory)) DualBrew · zo Strata · r. 1444–1450
**Zo Strata (github.com/lgse/strata, GTK4, 14. 10.) do DualBrew:** Ctrl+Z / Ctrl+Shift+Z vráti poslednú
vratnú operáciu so súbormi; hľadanie Ctrl+K podľa mena v celom domove, výsledky hneď ako prichádzajú (najlepších
100, obnova po 50 ms, upozornenie, keď nie sú úplné); náhľady cudzích formátov v bubblewrap bez siete
(fence už máme z Baristu), text najviac 1 MiB, pri chybe ikona; v úzkom okne má prednosť zoznam, náhľad sa
zmenší a potom skryje; stĺpcové zobrazenie (Miller) ako tretí pohľad; vlastné akcie ako skripty v priečinku
s knižnicou receptov, ktoré sa samy nespustia; označenie disku iba v DualBrew (systém sa nemení); virtuálny
pohľad „Fotky“ na telefóne bez sprievodných súborov; hľadanie v nastaveniach.

**10A.20** (pozn.) (DualBrew (Súbory)) DualBrew · klasický Prieskumník · r. 1451–1463
**14. 10., klasický Prieskumník (používateľ: „DualBrew má vedieť pracovať ako klasický prieskumník, s rôzne
veľkými ikonami“):** tlačidlo a ponuka Zobraziť ako vo Windows — Veľmi veľké (256), Veľké (128), Stredné (64),
Malé ikony, Dlaždice (ikona, meno, druh, veľkosť), Podrobnosti; Ctrl + koliesko plynulo 32–256. Obrázky sú
vlastným náhľadom, priečinok pri veľkých ikonách ukáže dva obrázky, ktoré drží (ako Prieskumník). Výber
**obdĺžnikom** z prázdneho miesta (aj za menom v Podrobnostiach, okolo ikony), Ctrl pridáva. **Ctrl+Z** a
„Vrátiť späť“ v ponuke: `latte-files undo` vráti poslednú operáciu (presun, premenovanie späť; kópia, odkaz,
nový priečinok do Koša; z Koša späť) podľa záznamu `~/.local/state/latteos/files-undo`, spoločného pre všetky
okná. **Ťahanie pravým tlačidlom** → ponuka Kopírovať sem · Presunúť sem · Vytvoriť odkazy sem · Zrušiť.
**Náhľad** (Medzerník aj „Náhľad“ v ponuke súboru): prvá strana PDF (pdftoppm), snímka videa (ffmpegthumbnailer).
Overené v headless sedení: obdĺžnik (5 vybraných), ponuka Zobraziť, Veľké ikony s náhľadom priečinka, Dlaždice,
náhľad videa; undo v skúške presunu, Koša, priečinka, kópie a úlohy. **Neoverené:** ťahanie pravým tlačidlom
(headless nevie ťahať), PDF v okne (príkaz áno), Vrátiť pri vložení (Ctrl+V). **Chýba:** Redo, Kôš na inom disku,
zoznam (List) a Obsah z Prieskumníka, snímky videí v ikonách.

**10A.21** (pozn.) (DualBrew (Súbory)) DualBrew · zariadenia, farby, archívy, fotky · r. 1464–1478
**14. 10., zariadenia, farby, archívy, fotky (používateľ):** bočný panel a Tento počítač ukazujú **všetky
jednotky**: disky, USB, pamäťové karty, DVD mechaniky skutočné aj z obrazu (**.iso › Pripojiť ako DVD
mechaniku** = Daemon Tools, `udisksctl loop-setup`), sieťové miesta (gvfs: SMB, SFTP, FTP, WebDAV; Google Drive
z GNOME Online Accounts) a **cloudy cez rclone** (`~/Cloud/MENO`, pripojí sa pri prvom kliknutí; Pridať cloud ›
Google Drive / OneDrive / Dropbox otvorí prehliadač na prihlásenie, MEGA a ďalšie cez `rclone config` v
termináli; sieťové miesto adresou, heslo pýta gio v termináli). Nepripojené sú bledé, klik ich pripojí, tlačidlo
vysunie (USB aj vypne). Zoznam sa obnovuje každé 4 s. **Farby** súborov a priečinkov (7 farieb, ponuka Farba;
`user.xdg.tags`, vidí aj Dolphin): podfarbený riadok a pásik, bodka pri ikone. **Archívy** ako úlohy na hladine:
Rozbaliť sem / do druhého panela (zip, 7z, tar…, rar cez bsdtar; jedna vec vyjde rovno, viac do priečinka),
Komprimovať › ZIP / 7z; Ctrl+Z vráti. **RAR sa vytvárať nedá** (formát je uzavretý, rar pre Linux je platený).
**Prehliadač fotiek** (Zobraziť › Prehliadač fotiek, ako ACDSee): veľký obrázok, pás náhľadov, koliesko,
šípky a tlačidlá myši idú ďalej/späť, rozlíšenie, veľkosť, dátum, Prezentácia, dvojklik skryje pás; nie editor.
Overené v headless: bočný panel so sekciami, Farba (zápis aj zobrazenie), ponuka Komprimovať, prehliadač fotiek,
balenie a rozbaľovanie aj s Ctrl+Z (skript). **Neoverené:** USB, karta, DVD, ISO (polkit mimo relácie
odmietol), sieť a cloudy (treba účet), zobrazenie pripojených jednotiek.

**10A.22** (pozn.) (DualBrew (Súbory)) DualBrew · hladina a obľúbené · r. 1479–1487
**14. 10., hladina a obľúbené (používateľ):** **pod hladinou informácie o jednej vybranej veci**
(`latte-files about`): priečinok — počet položiek, veľkosť (du najviac 3 s), kedy zmenený; obrázok — rozlíšenie,
fotoaparát, kedy fotené, clona, čas, ISO (EXIF cez exiv2), veľkosť; video — rozlíšenie a dĺžka (ffprobe). V
prehliadači fotiek je zobrazená fotka zároveň vybraná, takže hladina hovorí o nej. **Obľúbené priečinky** v
bočnom paneli (sekcia Obľúbené, „Pridať obľúbený priečinok“ pridá ten, kde som; krížik odoberie; aj v ponuke
priečinka Pridať do / Odobrať z obľúbených) — uložené v záložkách GTK (`~/.config/gtk-3.0/bookmarks`), takže
ich vidí aj okno Otvoriť/Uložiť iných aplikácií. **Opravené:** po každej operácii (obnovenie zoznamu) sa
prerušila väzba priečinka a zoznam potom ostal na starom mieste pri prechode inam.
Overené v headless: informácie o priečinku a o fotke na hladine, pridanie obľúbeného, prechod po operácii.

**10A.23** [x] Tento počítač ako v Nautiluse (yannmasoch/nautilus-my-computer): skupiny Obľúbené priečinky · Systém · V tomto počítači · Sieť s tichým nadpisom, pás zaplnenia na dlaždici disku, aj nepripojené oddiely (klik pripojí). 23. 10.

**10A.24** [x] (23. 10.: v okne užšom ako 1060 px ostanú tlačidlám iba ikony; overené iba v kóde, nie v úzkom okne) Horná lišta sa prispôsobí šírke: v úzkom okne sa tlačidlá zmenšia na samé ikony (s tipom), nič sa nestratí za okrajom.

**10A.25** [x] (23. 10.: tlačidlo jednotky na začiatku cesty s ponukou Tento počítač, jednotky s voľným miestom, / ako skutočná štruktúra; rad čipov zrušený) Jednotky v adrese: namiesto radu čipov „Jednotka: Domov · Celý systém · fedora_data“ jedno tlačidlo na začiatku cesty (ako C:/D: v Prieskumníkovi) — ukazuje jednotku, kde som, a otvorí ponuku všetkých jednotiek s voľným miestom. Uvoľní jeden riadok.

**10A.26** [x] (23. 10.: Jeden/Dva panely je jeden prepínač (zlatý pri dvoch), Nový priečinok z lišty preč, pribudlo ozubené koliesko Nastavení) Horná lišta úspornejšia: Jeden panel / Dva panely ako jedno prepínacie tlačidlo; Nový priečinok preč (je v ponuke pravého tlačidla a F7); Zobraziť ostáva.

**10A.27** [~] (23. 10. hotové: riadok v oboch režimoch, prepínače Príkaz/Hľadať/AI s vlastnou farbou; Hľadať filtruje súbory aj priečinky pri písaní (Ctrl+F), Enter = `latte-files find` (mená, potom obsah; bez skrytých priečinkov), výsledky v paneli, klik ide k súboru; AI = `latte-ai do ÚLOHA --in PRIEČINOK` s vybranými súbormi. Ostáva: náhľad zmien od AI priamo v DualBrew) Riadok dole v oboch režimoch (aj v jednom paneli) s tromi prepínačmi na začiatku, každý mení farbu riadku: **$ Príkaz** (tmavý, ako dnes), **Hľadať** (iná farba; filter v priečinku hneď pri písaní, Enter hľadá aj v podpriečinkoch podľa mena a obsahu — Dolphin Ctrl+F a Ctrl+I), **AI** (svetlejší; úloha pre agenta v tomto priečinku, napr. „premenuj hromadne fotky podľa dátumu“ — cez vrstvu Pomocníkov ako v Omarchy, `latte-ai`, s náhľadom zmien pred vykonaním).

**10A.28** [x] (23. 10. hotové: ponuka pod kolieskom — čo je v bočnom paneli, pohľad, skryté súbory, skutočná štruktúra, klávesy F aj v jednom paneli; pamätá si pohľad, veľkosť ikon, jeden/dva panely (`~/.config/latteos/dualbrew.json`). aj ako celá stránka (koliesko › Všetky nastavenia…): bočný panel, pohľad, stĺpce, správanie — skryté súbory, panel informácií, skutočná štruktúra, overovanie kópií, tlačidlá akcií, klávesy F, dvojklik vyššie) Nastavenia DualBrew (vlastná ponuka, vzor Total Commander): čo je v bočnom paneli (miesta, obľúbené, disky, sieť, filter typov — zapnúť/vypnúť, poradie), predvolený pohľad a triedenie, skryté súbory, skutočná štruktúra, jeden/dva panely pri štarte, stĺpce, potvrdzovanie mazania, správanie dvojkliku, klávesy F. Uložené v `~/.config/latteos/`, každé prostredie svoje.

**10A.29** [x] (23. 10.: Ctrl+L alebo klik na voľné miesto vedľa cesty; ~, relatívna cesta, súbor otvorí priečinok a vyberie ho, smb:// a iné cez gio mount) Písateľná adresa (Ctrl+L alebo klik na voľné miesto v ceste): vložiť `/data/hry`, `~/…` aj `smb://…`, `sftp://…`, Enter ide tam.

**10A.30** [x] (23. 10.: PDF a video v ikonách a dlaždiciach od 48 px, `latte-files thumb` (pdftoppm, ffmpegthumbnailer) do ~/.cache/latteos/thumbs; dokumenty Office ostávajú ikonou) Náhľady v ikonách a dlaždiciach aj pre video, PDF a dokumenty (snímka z videa, prvá strana), nielen obrázky.

**10A.31** [x] (23. 10. hotové: Vlastnosti v ponuke pravého tlačidla a Alt+Enter — kde, veľkosť, položky, časy, vlastník, 9 prepínačov oprávnení (chmod, iba vlastník), Otvára sa v (xdg-mime default), SHA-256 na požiadanie; aj pre viac vybraných — počet, spolu veľkosť, oprávnenia pre všetky (chmod u+x…)) Okno Vlastnosti: veľkosť, dátumy, práva a vlastník so zmenou, „Otvárať vždy v…“, kontrolný súčet (SHA-256).

**10A.32** [x] (23. 10.: F11 alebo koliesko › Panel informácií; vpravo náhľad (obrázok, prvá strana PDF, záber videa, ikona spúšťača) a údaje z `latte-files about`; bez výberu priečinok; zapamätá sa) Panel informácií (ako Dolphin F11): väčší náhľad a údaje o vybranom pri boku panela, zapínateľný.

**10A.33** [x] (23. 10.: koliesko › V bočnom paneli › Strom priečinkov; šípka otvorí, meno ide tam, od Domova alebo od / v skutočnej štruktúre; bočný panel sa posúva) Strom priečinkov v bočnom paneli (Dolphin F7), zapínateľný v Nastaveniach.

**10A.34** [x] (23. 10.: F2 na viacerých alebo Premenovať všetky…; vzor [N] meno, [C] číslo, [D] [T] dátum a čas (EXIF, inak zmena), [E] prípona, nájsť a nahradiť, čísla od; náhľad všetkých mien, chybné červené; `latte-files renames` — jedno Ctrl+Z vráti všetky) Hromadné premenovanie (F2 na viacerých): vzor s číslom, nájsť a nahradiť, dátum z EXIF, náhľad pred vykonaním.

**10A.35** [x] (23. 10.: Num + / Num − vzor (*.jpg; IMG_* — viac cez ;), Num * obráti, aj v ponuke pravého tlačidla › Vybrať) Výber podľa vzoru (`*.jpg`, Num+ / Num−) a obrátenie výberu.

**10A.36** [x] (23. 10.: Nedávne v bočnom paneli (`latte-files recent` z recently-used.xbel), najnovšie hore, čas, klik ide k súboru) Nedávne súbory a priečinky v bočnom paneli (aj „Dnes“, „Včera“) — z `recently-used.xbel`.

**10A.37** [x] (23. 10.: mimo domova v ponuke Upraviť ako správca… (sudoedit v termináli s varovaním) a pri priečinku Terminál tu ako správca…; celé okno nikdy ako správca) Otvoriť ako správca pri systémových súboroch (polkit/pkexec), s jasným varovaním.

**10A.38** [x] (23. 10.: `latte-files git`; v Podrobnostiach „zmenený“/„nový“ za menom, v ikonách bodka, ignorované stlmené) Stav Gitu pri súboroch v repozitári (zmenený, nový, ignorovaný) ako značka pri ikone.

**10A.39** [x] (23. 10.: pravé tlačidlo › Akcie; skripty v ~/.config/latteos/dualbrew/actions s riadkami „# name:“ a „# for:“; recepty LatteOS (zmenšiť obrázky, obrázky do PDF, poslať do telefónu) sa pridajú jedným klikom a samy nič nespustia) Vlastné akcie v ponuke pravého tlačidla (servisné ponuky Dolphinu): skripty v priečinku, napr. Zmenšiť obrázok, Previesť na PDF, Poslať do telefónu (KDE Connect).

**10A.40** [~] (23. 10. hotové: koliesko › Stĺpce v Podrobnostiach — Typ, Veľkosť, Zmenené, Atribúty zapnúť/vypnúť (zapamätá sa). Ostáva: rozmery obrázka, dĺžka videa, interpret, zoskupovanie) Vlastné stĺpce v Podrobnostiach (typ, rozmery obrázka, dĺžka videa, interpret) a zoskupovanie podľa typu alebo dátumu.

**10A.41** [~] (23. 10. hotové: tlačidlo Porovnať medzi panelmi a Shift+F2 — v každom paneli sa vyberie, čo druhá strana nemá alebo má staršie (`latte-files compare`), F5 to skopíruje; jeden vybraný súbor v každom paneli = rozdiel riadok po riadku (diff v termináli). Ostáva: synchronizácia aj podpriečinkov naraz) Porovnanie a synchronizácia priečinkov medzi panelmi, porovnanie dvoch súborov (Total Commander).

**10A.42** [x] (23. 10.: pred kopírovaním a presunom `latte-files clashes`; okno Nechať oboje / Nahradiť (staré do Koša, Ctrl+Z vráti) / Nahradiť staršie / Tieto preskočiť / Zrušiť (LATTE_CONFLICT pre úlohu). Opravené pritom: priečinky sa nedali kopírovať (gio copy nekopíruje rekurzívne) — teraz cp -a / mv -n, aj pri vkladaní) Okno pri zhode mien (Total Commander): Prepísať / Preskočiť / Premenovať / Porovnať / Prepísať staršie, „pre všetky“ — pred kopírovaním a presunom, nie ticho.

**10A.43** [x] (23. 10.: písmená v zozname skočia na prvé meno, ktoré tak začína (aj meno spúšťača); po sekunde sa začína odznova) Rýchle hľadanie písaním v zozname: písmená skočia na prvú zhodu mena (ako Prieskumník a TC).

**10A.44** [~] (23. 10. hotové: dvojklik na zip, 7z, rar, tar… doň vojde ako do priečinka — `latte-files archive` cez archivemount, len na čítanie, cesta ukazuje meno archívu, Vyššie z neho von, kopírovať von ide; s heslom alebo nečitateľný ho otvorí jeho aplikácia; Otestovať archív (7z t). Ostáva: zapisovať do archívu, heslo priamo v DualBrew) Archívy ako priečinky: vojsť do ZIP/7z/tar, kopírovať z neho a do neho, aj s heslom; Test archívu.

**10A.45** [~] (23. 10. hotové: F3 číta súbor priamo v okne — Text (2 MB), Hex (xxd), obrázok; hľadanie v texte (Ctrl+F, Enter ďalší); Esc/F3 zavrie. Ostáva: video a zvuk v Listeri) Lister (F3): vlastný prehliadač textu, hex/binárky, obrázkov a médií v okne, s hľadaním v texte.

**10A.46** [~] (23. 10. hotové: koliesko › Overiť každú kópiu — po skopírovaní sa porovná s originálom (diff -rq); čo sa nepodarilo, povie hladina po úlohe. Ostáva: obmedzenie rýchlosti) Overenie po kopírovaní (SHA-256) a obmedzenie rýchlosti kopírovania ako voľba úlohy.

**10A.47** [~] (23. 10. hotové: v riadku Hľadať tlačidlo s voľbami — väčšie ako 10 MB/100 MB/1 GB, zmenené dnes/týždeň/mesiac/rok, meno ako regulárny výraz; Nájsť rovnaké súbory tu (`latte-files dups`, rovnaký SHA-256, skupiny); výsledky v paneli. Ostáva: atribúty, hľadanie v archívoch, uložené hľadania) Rozšírené hľadanie (k 10A.27): dátum, veľkosť, atribúty, regex, v archívoch, duplikáty, výsledky do panela, uložené hľadania.

**10A.48** [x] (23. 10.: Ctrl+B alebo pravé tlačidlo › Všetky súbory nižšie v jednom zozname (`latte-files flat`, 3000 najviac), Ctrl+B znova zavrie) Plochý pohľad (TC Ctrl+B): všetky súbory zo všetkých podpriečinkov v jednom zozname.

**10A.49** [x] (23. 10.: ↑/↓ v riadku Príkaz idú históriou (50, zapamätá sa), Ctrl+Enter vloží mená vybraných, Ctrl+P celé cesty, správne v úvodzovkách) Príkazový riadok naplno: história (šípka hore), Ctrl+Enter vloží meno vybraného, Ctrl+P cestu.

**10A.50** [x] (23. 10.: Ctrl+U vymení panely, Alt+↓ ukáže, kde bol panel (aj v ponuke pravého tlačidla)) Vymeniť panely (Ctrl+U) a história priečinkov (Alt+↓, ponuka na šípke Späť).

**10A.51** [x] (23. 10.: pravé tlačidlo › Vytvoriť súbor kontrolných súčtov (SHA-256) — NAME.sha256 vedľa súborov (`latte-files sums`); na .sha256/.sha512/.sha1/.md5 › Overiť kontrolné súčty v termináli) Kontrolné súčty pre výber: vytvoriť `.sha256` a overiť existujúci (stiahnuté ISO).

**10A.52** [x] (23. 10.: pravé tlačidlo › Rozdeliť na časti… (MB, predvolene 4000 pre FAT32) a na .000 › Spojiť časti; ako úlohy s priebehom na hladine, Ctrl+Z vráti) Rozdeliť / spojiť súbor na kúsky (napr. na FAT32 kľúč).

**10A.53** [x] (23. 10.: vo Vlastnostiach (aj pre viac vybraných) Zmeniť dátum — vlastný čas alebo Teraz (`latte-files touch`); atribúty pre všetky už v 10A.31) Zmena dátumu (touch) a atribútov pre celý výber.

**10A.54** [x] (23. 10.: stĺpec Typ, klik na hlavičku triedi podľa prípony) Triedenie podľa prípony (stĺpec Typ).

**10A.55** [x] (23. 10.: koliesko › Tlačidlá mojich akcií nad panelmi — každá akcia z 10A.39 ako tlačidlo pre vybrané (stlmené, keď nesedí)) Vlastný panel tlačidiel s vlastnými príkazmi (spustí skript s vybranými súbormi).

**10A.56** [x] (23. 10.: pravé tlačidlo › Vybrať › Zapamätať tento výber / Obnoviť zapamätaný výber (podľa mien, aj v inom priečinku); Kopírovať mená pri viacerých) Uložiť a načítať výber, kopírovať zoznam mien do schránky alebo súboru.

**10A.57** [ ] Pluginy (ako WCX/WLX/WFX/WDX v TC) — neskôr, väčšinu pokryjú vlastné akcie (10A.39).

**10A.58** [x] Spúšťače (.desktop) v priečinku ukazujú svoje meno a obrázok ako na ploche (`latte-desktop entries`), napr. „Aliens versus Predator 2“ namiesto latteos-avp2.desktop. 23. 10.

(Karty ako v Dolphine sa nerobia — používateľ 23. 10.: dva panely stačia.)

**10A.59** [ ] **Režim Jeden panel — iný druh práce než commander** (používateľ 27. 10.): režim Dva panely je Total
Commander; režim Jeden panel slúži na inú prácu (prehliadanie, fotky, dokumenty) a môže byť celý inšpirovaný
**Loafom, Nautilom alebo klasickým Prieskumníkom Windows** — vlastný vzhľad aj ovládanie, nie iba jeden z dvoch panelov.

**10A.60** [ ] **Výskum: Loaf** (používateľ 27. 10.) — https://github.com/m-uvex/loaf-fm (MIT, Rust + Qt6/QML cez cxx-qt
— rovnaký smer ako LatteOS; alfa, 20 hviezd, 3 commity → nie ako základ, ale zdroj kódu a nápadov). Má, čo DualBrew
chýba: archívy (zip aj s heslom, 7z, tar.gz/xz/zst/bz2, cpio), viackrokové Späť / Znova (premenovanie, vytvorenie,
presun, odstránenie), Kôš s obnovením a vysypaním, pri ťahaní ponuka Kopírovať / Presunúť / Prepojiť sem, „Tento
počítač“ so štatistikou diskov a pripojením/odpojením, palety farieb z tapety, pružinové animácie, bočné tlačidlá
myši. Preveriť pre režim Jeden panel (10A.59) a pre chýbajúce veci z 10A.13. Pri prevzatí kódu zápis do `TRETIE-STRANY.md`.

### 10B. [~] LensAI
Zdroje: `bin/latte-ai`, `apps/aicenter.qml`, `system/ai/`, `system/agents/`, `inspo/ai-na-ploche.md`
je centralne zastrešenie všetkych použitelnych AI. Je totalna kopia Omarchy Ai využitia, len s tým že sa použiva namiesto konzoloveho, graficke rozhranie. LensGoo ma jednu z položiek komunikačne okno s Ai. 

**10B.01** [ ] dizajn okna. biela plocha okna je sice identicka s originalom ale navrhujem čiastočnu priehladnost. ta biela na tmavom je priliš ostrá.

**10B.02** [x] (LensAI) režim AI v LensGoo · r. 189–189

**10B.03** (pozn.) (LensAI) e5-sk embeddingy · r. 369–369
- **e5-sk embeddingy** (KInIT): hľadanie podľa významu v LensGoo — súbory, nastavenia, aplikácie („faktúra za plyn“).

**10B.04** [~] (LensAI) AI v LensGoo — úvod · r. 384–393
[~] **AI v LensGoo a Lens AI centrum** (používateľ, 20. 10., na pokyn mimo poradia). Hotové: karta AI s rozhovorom,
    poľom v podobe služby, výberom modelu, spotrebou (limity Claude 5 h a týždňa) a novou reláciou; Lens AI centrum
    (rozhovory všetkých AI pokope, služby a prihlásenie); výber AI pre LensGoo v Nastaveniach › Spúšťač; text
    „Hľadať aplikácie alebo nastavenia…“. 21. 10.: pole s ponukou + (súbor, snímka obrazovky; nástroj číta iba
    priložené), úsilie v čipe modelu (Claude low–max, Codex low–high); Gemini, ChatGPT, Grok a Mistral odpovedajú cez
    oficiálne nástroje s účtami používateľa (overené 21. 10., zápis zakázaný). **Ďalej, podľa VS Code (Copilot: viac AI pod jednou strechou, vlastné kľúče):** (a) vlastné kľúče
    API v Lens AI centre, uložené v kľúčenke systému (nie v súbore), priame volanie API bez agentov — aj Grok
    a Mistral; (b) Grok Build a Mistral Vibe cez účet (nainštaluje používateľ; overiť vypnutie nástrojov);
    (c) bohatšie okno rozhovoru a nastavenia centra; postupné písanie, zastavenie, mikrofón (chýba prevod reči).
    **Rozdelenie (21. 10. v noci, ide sa zhora):**

**10B.05** [x] (LensAI) Omarchy a dots · r. 394–395

**10B.06** [x] (LensAI) mikromodely · r. 396–397

**10B.07** [x] (LensAI) lokálny model · r. 398–401

**10B.08** [x] (LensAI) vlastné kľúče API · r. 402–405
- d. [x] Lens AI centrum › Služby: vlastné kľúče API (kľúčenka systému cez `secret-tool`), priame volanie API
  (Anthropic, OpenAI, Google, xAI, Mistral) popri účtoch.
  Hotové 21. 10.: gnome-keyring (PAM greetd ho odomkne pri prihlásení), vlastné servery s OpenAI API;
  overené proti llama-serveru a oddelenej kľúčenke; skutočné kľúče služieb neoverené (žiadne nie sú).

**10B.09** [x] (LensAI) modely · r. 406–406

**10B.10** [x] (LensAI) okno rozhovoru · r. 407–407

**10B.11** [x] (LensAI) porovnanie · r. 408–408

**10B.12** [x] (LensAI) mikrofón a pokyny · r. 409–412
- h. [x] Mikrofón v LensGoo (whisper.cpp, ak b ukáže, že stačí) a nastavenia rozhovoru (vlastné pokyny, pamäť).
  Mikrofón hotový 21. 10.: whisper.cpp s Vulkanom (large-v3-turbo 8 s, small 3 s na 4 s vety na RX 640),
  `latte-ai listen`; na latte-lab chýba skutočný mikrofón (overené pripravenou nahrávkou). Vlastné pokyny (Lens AI
  centrum › Pokyny) idú s každou otázkou ku každej AI.

**10B.13** [ ] (LensAI) hľadanie podľa významu · r. 413–413
- i. [ ] Hľadanie podľa významu v LensGoo (e5-sk, ROADMAP bod 14) — po b.

**10B.14** [~] (LensAI) LensAI = spoločné API · r. 414–457
- m. [ ] **LensAI = spoločné API + grafická nadstavba** (používateľ, 21. 10.; Omarchy je MIT → prevziať maximum,
  prepísať do LatteOS, autor v `TRETIE-STRANY.md`). LensAI (nové meno Lens AI centra) je jedno API pre všetko AI
  v systéme (`latte-ai`: služby, účty, modely, rozhovory, spotreba, úlohy, skill) a okno nad ním; chat v LensGoo je
  iba rýchly klient toho API. Poradie:
  1. [x] premenovať na LensAI (21. 10.); polia na písanie presne podľa snímok používateľa (21. 10.); ponuky + a čipu podľa snímok — dáva ich `latte-ai providers` (plus, menu, web), LensGoo aj okno LensAI ich iba kreslia; čo LatteOS nevie, otvorí web služby fialovým textom (21. 10.); DeepSeek cez web čaká na `docs/manual-inst.md` (Claude, Gemini, ChatGPT, Grok,
     Mistral, Copilot, DeepSeek); DeepSeek cez kľúč API;
  2. [x] spotreba ako v Omarchy (`omarchy-agent-usage-*`), hotové 21. 10.: Claude (OAuth usage), Grok (billing),
     Copilot (GitHub), ChatGPT (Codex app-server; neoverené, Codex odhlásený — `docs/manual-inst.md`), vlastné
     počítadlo otázok; odpoveď platí 15 min, pri 80 %+ 3 min; LensGoo aj LensAI ju berú z API. Kimi a Fireworks
     vynechané (používateľ ich nepoužíva);
  3. [x] **panel agentov v okne LensAI** (podľa `shell/plugins/agents` z Omarchy), hotové 21. 10.: stránka Agenti
     (`latte-ai agents`) — úvod s otáčajúcim sa riadkom (tokeny týždeň/dnes, najpoužívanejší model, najrušnejší deň,
     otázky dnes; zo záznamov Claude Code), služba po službe s plánom, pásmi limitov a časom obnovenia,
     „Treba sa prihlásiť“; „Urob niečo“ prejde do bodu 5 (potrebuje skill z bodu 4);
  4. [x] **skill LatteOS** (podľa `default/agents/skills/omarchy`), hotové 21. 10.: `system/agents/skills/latteos/SKILL.md`
     (ako je LatteOS postavený, `/usr/share/latteos` iba čítať, `~/.config/latteos`, príkazy `latte-*`, stránky
     Nastavení, sudo/pkexec, snímka pred diskom, `dnf remove --noautoremove`, najprv plán a súhlas, pomoc pri páde
     a v SAFE); `latte-ai skill install|reset|path` — kópia používateľa v `~/.config/latteos/skills/latteos`,
     odkazy v `~/.claude/skills`, `~/.codex/skills`, `~/.agents/skills` (pri štarte relácie); **upraviteľný
     v LensAI › Pokyny** s „Obnoviť pôvodný“; overené: Claude Code skill vidí;
  5. [x] „Urob to za mňa“, hotové 21. 10.: `latte-ai do TASK [AGENT]` otvorí agenta v termináli (foot) so skillom
     LatteOS — Claude Code v plánovacom režime, Codex `-s read-only -a on-request`, Gemini `--approval-mode default`;
     nič sa neschvaľuje samo. LensGoo: 4. ikona v päte karty AI (úloha z poľa; prázdne pole → LensAI › Agenti).
     LensAI › Agenti: pole, voľba agenta (`latte-ai doer`, `~/.config/latteos/agent`), 6 pripravených úloh
     („Urob niečo“ z Omarchy). Overené: terminál s Claude Code sa otvorí; plán na skutočnej ploche neoverený;
  6. [x] **pád → AI** s GuardDogom a **LatteOS SAFE** (podľa `diagnose-crash` z Omarchy), hotové 21. 10.: GuardDog
     sleduje systemd-coredump (každých 30 s), pád zapíše do denníka a ukáže upozornenie „Opýtať sa AI“ · „O tomto
     programe nie“ (stlmenie v `guarddog.json`); `latte-ai crash PID` dá agentovi fakty (coredumpctl, denník okolo,
     čí program), vysvetlí, nič nemení; v SAFE položka „Opýtať sa AI, prečo sa skončila“ (`latte-ai why`), aj v ponuke
     pravého tlačidla. **Okno GuardDog** (`latte-app guarddog`, na pokyn používateľa): Čo drží v chode, Pády
     (Opýtať sa AI, Stlmiť), Denník ako konzola (`latte-guarddog log`). Overené: pád `sleep` zachytený, upozornenie
     po slovensky; agent pri páde na ploche neoverený;
  7. [~] **inštalácia AI v okne LensAI** (používateľ 21. 10.: nie v App Manageri), hotové 21. 10.: LensAI › Služby
     má pri nenainštalovanej službe „Nainštalovať“ — oficiálny nástroj v termináli, pre používateľa bez hesla
     (Claude Code a Grok vlastným inštalátorom, Codex, Gemini, Copilot cez npm do `~/.local`, Mistral Vibe cez uv,
     Ollama z Fedory; chýbajúci npm/uv z Fedory); stránka sa obnovuje každých 10 s. Neoverené naostro (všetko je
     na latte-lab nainštalované). **Nástroje cez mise ako v Omarchy** (21. 10., pravidlo: najprv Omarchy):
     `/etc/mise/conf.d/latteos-tools.toml` — lenivá inštalácia, `auto_update = "4h"`, `mise up` pri aktualizácii.
     **Lokálna AI** (21. 10.): LensAI › Na tomto počítači ako LM Studio — Objavovať (výber LatteOS ako ich Staff
     Picks, hľadanie na Hugging Face s triedením, detail s možnosťami stiahnutia, odhadom gpu/partial/cpu/too-big
     ako lmstudio-js a predvybraným variantom, README), Moje modely, Spúšťanie (hardvér, llama.cpp Vulkan,
     grafická karta); `latte-ai local …`. Neoverené: skutočné stiahnutie modelu a llama.cpp z LensAI.
     Ostáva: aplikácie služieb z Flathubu, DeepSeek po `docs/manual-inst.md`. Diktovanie — **neskôr**. (Viac účtov
     jednej služby s prepnutím pri limite — **neskôr**, používateľ 21. 10.: platí iba jednu službu.)

**10B.15** [ ] (LensAI) odporúčané lokálne modely · r. 458–461
- n. [ ] **Odporúčané lokálne modely** (používateľ, 21. 10.): `system/ai/local-models.json` prejsť a obnoviť **raz za
  mesiac či dva** (nové modely z `lmstudio-community`, veľkosti, popisy; dátum `updated`), príde s aktualizáciou.
  **Vrstva AI s inštaláciou LatteOS** (ak ju používateľ povolí): mise a jeho zoznam nástrojov, llama.cpp, a model
  navrhnutý podľa hardvéru (`latte-ai local recommend`) — krok inštalátora v bode 9.

**10B.16** [ ] (LensAI) rozhovory aj mimo LensAI · r. 462–467
[ ] **rozhovory aj mimo LensAI** (používateľ, 21. 10.: na PC v LensAI, na mobile v aplikácii Claude):
   (a) **import** exportu dát služby (Claude: Nastavenia › Súkromie › Export, ChatGPT: Export údajov, Gemini:
   Google Takeout) do histórie LensAI, iba na čítanie a pokračovanie; (b) **Remote Control** Claude Code
   (oficiálne, výskumná ukážka): rozhovor LensAI ako interaktívna relácia Claude Code, ktorú otvorí aplikácia
   Claude na mobile (Code). Obojsmerná synchronizácia bežných četov a projektov claude.ai **nie**: nemá verejné
   API a podmienky zakazujú automatický prístup mimo kľúča API alebo výslovného povolenia.

**10B.17** [ ] (LensAI) podľa Omarchy · r. 468–476
- l. [ ] **Podľa Omarchy** (preskúmané 21. 10., `inspo/ai-na-ploche.md`), návrhy na výber používateľa:
  (1) **skill LatteOS** pre agentov (`~/.claude/skills`, `~/.codex/skills`, `~/.agents/skills`): ako je LatteOS
  postavený, čo sa smie meniť (`~/.config/latteos`, nie `/usr/share/latteos`), ktoré `latte-*` príkazy použiť,
  pkexec, snímka pred diskom, plánovací režim — základ barličky (k); (2) **„Urob to za mňa“** v LensGoo: úloha pre
  predvoleného agenta v okne terminálu, najprv plán, potom potvrdenie (nie automatické schvaľovanie ako Omarchy);
  (3) **limity bez otázky** ako Omarchy (Claude OAuth usage, Grok billing) — číta token prihlásenia CLI, iba
  so súhlasom; (4) **pád → AI**: GuardDog/whyd ponúkne „Opýtať sa AI“ so zisteniami z core dumpu; (5) **App Manager
  › AI**: Claude desktop, ChatGPT, LM Studio, Ollama; (6) **diktovanie do akejkoľvek aplikácie** (Voxtype, Win+H
  ako vo Windows) popri mikrofóne v LensGoo; (7) viac účtov jedného poskytovateľa a prepnutie pri limite.

**10B.18** [ ] (LensAI) AI ako barlička · r. 477–482
- k. [ ] **AI ako barlička v systéme** (používateľ, 21. 10.: ako v Omarchy; veľa ľudí je v Linuxe stratených):
  po oficiálnom spustení LatteOS bude AI integrovaná do OS a na požiadanie použije systémové nástroje —
  „preformátuj mi `/`, hlási, že je plný, a pridaj mu z rezervy“. Návrh: AI nesiaha na systém sama; navrhne
  plán krokov ako nástroje LatteOS (`latte-files disks`, `latte-network`, Nastavenia…), človek každý zásah
  potvrdí, oprávnenie správcu cez polkit, pred zásahom na disk snímka; čo sa stalo, sa dá prečítať a vrátiť.
  Nástroje teda musia mať aj „robiacu“ časť (zväčšiť oddiel, presmerovať priečinky…), nie iba prehľad.

**10B.19** [x] (LensAI) mikro-agenti · r. 483–486

**10B.20** [ ] (LensAI) Asistent v každom textovom poli · r. 548–556
[ ] **Asistent v každom textovom poli** (používateľ, 21. 10.; vzor: veta v kalendári ClockGoo — pravidlá hneď, čo
    nevedia, prečíta lokálna AI a výsledok sa ukáže na potvrdenie, nič sa nevykoná samo). Jedno spoločné API (`latte-ai`,
    LensAI), pole len povie, čo vie urobiť:
    - **DualBrew, riadok terminálu / hľadania:** veta → príkaz Linuxu alebo hľadanie; hromadné premenovanie a
      usporiadanie súborov („fotky z dovolenky podľa dátumu do priečinkov“) — najprv náhľad zmien, potom vykonať.
    - **Prehrávač hudby:** dohľadanie skladby podľa opisu („tá pomalá s klavírom od…“).
    - **Fotky:** hľadanie fotky podľa opisu (obraz → význam, miestny model; súvisí s hľadaním podľa významu, bod 16 i).
    - Ďalšie polia postupne (Nastavenia, App Manager, LensGoo). Merané 21. 10.: model 4B ~12 s na procesore a
      pri dátumoch sa mýli — čo vedia pravidlá, robia pravidlá; AI iba na zvyšok a vždy s potvrdením.

**10B.21** [x] (LensAI) Pomocníci ako v Omarchy · r. 557–562

**10B.22** [~] (LensAI) B. AI · r. 640–641
- [~] **ZÁKLAD / AI:** `latte-ai` už pripája lokálne, domáce a cloudové modely aj vybrané
  poskytovateľské CLI. Používateľské AI v LensGoo má samostatne známu kvalitatívnu medzeru.

**10B.23** [~] (LensAI) C. GOO / LensGoo a AI · r. 670–671
- [~] **GOO / LensGoo a AI:** základ spúšťača, hľadania a AI existuje; hĺbková kontrola podľa
  používateľa má zamerať predovšetkým kvalitu AI rozhovoru, odpovedí, výberov a chybových stavov.

**10B.24** [ ] (LensAI) D. AI · r. 699–700
- [ ] **AI:** zlepšiť AI v LensGoo; poskytovateľov, limity, súkromie a systémové nástroje dopĺňať
  explicitne a iba s potvrdením používateľa.

**10B.25** (pozn.) (LensAI) F. R3·G — AI · r. 864–866
**R3·G — AI:** `latte-mcp` a zručnosť pre AI (r. 546, 559, 595); limity predplatných v LensGoo (r. 598); Newelle ako jadro (r. 599);
streamovanie odpovede (r. 872); viac poskytovateľov a prihlásenie výberom (r. 873); Ollama na CPU (r. 879); Qwen3-14B-sk (r. 906).

**10B.26** (pozn.) (LensAI) R3·G — cieľ · r. 1068–1071
**Cieľ:** AI je voliteľná schopnosť systému s jasne oddeleným lokálnym/cloudovým spracovaním a
bez nečakaného prístupu k systémovým akciám.

**10B.27** [ ] (LensAI) R3·G — latte-ai a UX · r. 1072–1073
- [ ] Dokončiť `latte-ai` a UX v LensGoo/Nastaveniach: poskytovatelia, prihlasovanie, modely,
  streamovanie, prílohy, hlas, spotreba a limity podľa toho, čo daná služba skutočne poskytuje.

**10B.28** [ ] (LensAI) R3·G — spôsoby pripojenia AI · r. 1077–1078
- [ ] LensGoo: podpora všetkých spôsobov pripojenia AI — oficiálne nástroje účtov, integrovaný Instruct model a
  lokálny server (napr. LM Studio); prehľad spotrebovaných a zostávajúcich tokenov.

**10B.29** [ ] (LensAI) R3·G — kam odchádza požiadavka · r. 1079–1080
- [ ] Zviditeľniť, kam odchádza požiadavka, čo sa posiela a či je odpoveď lokálna alebo cloudová;
  pri cloudových poskytovateľoch rešpektovať súhlas a podmienky služby.

**10B.30** [ ] (LensAI) R3·G — AI s nástrojmi na správu · r. 1081–1083
- [ ] Ak AI dostane nástroje na správu LatteOS, použiť obmedzené rozhranie, náhľad plánovanej
  zmeny, výslovné potvrdenie a auditovateľný výsledok; online webový chat nedostáva systémové
  oprávnenia.

**10B.31** [ ] (LensAI) R3·G — vývojová AI farma a MCP · r. 1084–1087
- [ ] Vývojová AI farma a MCP sú vývojárske nástroje, nie predvolená súčasť používateľskej plochy;
  ich úlohy, tajomstvá a prístup k repozitáru držať oddelene od runtime AI LatteOS.

**10B.32** [ ] **Výskum: DigUp ako motor hľadania podľa významu** (používateľ 27. 10.) — https://github.com/ARahim3/DigUp
(MIT; ~5 300 hviezd, 16.–22. 10. ~1 500 za týždeň). Hľadá v obsahu fotiek a snímok obrazovky, PDF aj skenovaných,
dokumentov (txt, md, rtf, docx, odt, html), nahrávok, videí a kódu; lokálne cez EmbeddingGemma 2 v llama.cpp, jeden
spoločný priestor pre text, obraz, zvuk a video; index v SQLite; Linux beta (.deb, AppImage; Tauri) a príkaz `digup`
(indexovanie, hľadanie). Využitie: LensShore/LensGoo (6B.12), DualBrew (hľadanie v obsahu, 10A.04), Nastavenia (9.10).
Preveriť: beta na Fedore (balík RPM nie je), čítanie textu zo snímok (na macOS cez Apple Vision — na Linuxe zrejme
chýba), nároky modelu podľa stupňov výkonu, veľkosť indexu, ktoré priečinky sa indexujú a vylúčenie súkromných.
**Rozhodnuté 27. 10. (používateľ):** hľadanie podľa obsahu **nie je generatívne**, a preto nespadá pod vypínač AI (2B).
Výstupom DigUp sú iba nájdené súbory, nie odpovede — rovnako ako triedenie fotiek neurónovou sieťou v Google Fotkách.

**10B.33** [ ] **Sledovať: hlasový rozhovor full-duplex (Dessa od Blocku)** (používateľ 27. 10., Reddit r/OpenAI) —
model reč-na-reč, ktorý počúva a hovorí naraz (skáče do reči, prikyvuje „aha“). Ohlásený 23. 10. 2026 ako výskumná
ukážka: **váhy ani licencia nie sú zverejnené**, iba čakací zoznam; beží miestne na MacBooku Pro M4 Max; veľkosť
modelu, jazyky (slovenčina?) ani latencia nie sú uvedené. Dnes sa teda nedá použiť. Pre LatteOS: hlasový režim
LensShore / LensAI („hovor cez podržanie“, 6L.02). Preveriť otvorené alternatívy (Kyutai Moshi) a či niektorá vie
po slovensky. Je to **generatívna AI** → spadá pod vypínač AI (2B).

### 10C. [ ] Heidelberg
je zakladny textovy editor, s neobvyklo širokou ponukou formatou ktore prečíta a upraví

**10C.01** [ ] (Heidelberg) R3·C — Heidelberg · r. 994–994
- [ ] **Heidelberg:** verné formátovanie docx (tabuľky, štýly, hlavičky) a ďalšie otvorené položky z F4 (riadok 792).

### 10D. [~] LatteMonitor
Zdroje: `apps/monitor.qml`, `bin/latte-monitor`, `crates/latte-stats`; LATTEOS-GOO §6.2·1
je monitor prostriedkov presne ako ctrl+alt+del z windows 11(jeho kopia) ale zaroven ponuka presne skopirovanu funkčnost z CpuZ a z HWinfo. Prebera informacie z GuardDog aj Dev a Net manager. spravuje aj výstup pre aplikacie-napr externy dashboard čitajuci vytaženie CPU, RAM, farebnost led na zaklade zvuku, atd.

**10D.01** [ ] zrealizovat funkčnost

**10D.02** [x] (Monitor) Monitor · r. 139–145
[x] **Monitor** (13. 10.): `apps/monitor.qml` + `bin/latte-monitor` (a `latte-stats`). Prehľad (procesor
   s jadrami, pamäť, grafika, sieť a disky — živé obrázky poslednej minúty, najnáročnejšie programy),
   Procesy (aplikácie s oknom, potom pozadie; hľadanie, zoradenie, Ukončiť), Po štarte (čo sa spúšťa samo:
   čo to je, odkiaľ je, koľko pridalo k štartu; vlastné veci sa dajú vypnúť a zasa zapnúť — návrh podľa
   BetterWindowsServices), Senzory. PowerGoo › Monitor, Ctrl+Shift+Esc. Oproti v0.3 chýba: všetky služby
   so štartom a zastavením, detail procesu (priorita, pauza, súbory, spojenia), hardvér ako CPU-Z, test
   výkonu, Digitálna pohoda, strom disku, dlhodobá telemetria („kto žerie“ po dňoch).

**10D.03** [ ] (Monitor) D. Monitor · r. 693–694
- [ ] **Monitor:** nadviazať na existujúce procesy, služby, autoruns a senzory; dokončiť stálu
  telemetriu a pohľad na spotrebu podľa aplikácie v čase, bez nepresných alebo skrytých zberov.

**10D.04** (pozn.) (Monitor) F. R3·D — Monitor · r. 850–852
**R3·D — Monitor:** „kto žerie“ energiu, dáta, RAM, disk po aplikáciách (r. 574); `latte-sysmond`, eBPF (r. 775, 778);
bezpečnostná kontrola balíkov bumblebee (r. 603); Python nástroje — čas štartu (r. 940).

**10D.05** (pozn.) (Monitor) R3·D — cieľ · r. 1006–1009
**Cieľ:** používateľ vie zistiť, čo sa deje so systémom a aplikáciami, a bezpečne konať bez
nepriehľadných privilegovaných služieb.

**10D.06** [x] (Monitor) R3·D — základ Monitora · r. 1010–1011

**10D.07** [ ] (Monitor) R3·D — telemetria · r. 1012–1014
- [ ] Dokončiť stály zber telemetrie (`latte-sysmond`) a dlhodobý pohľad na CPU, RAM, GPU, energiu,
  sieť a disk; odlíšiť živý stav od historického odhadu a primerane uchovávať údaje s možnosťou
  vypnutia zberu.

**10D.08** [ ] (Monitor) R3·D — akcie pre služby · r. 1015–1015
- [ ] Nové akcie pre služby musia zachovať vysvetlenie pôvodu, oprávnení a vratnosť.

**10D.09** [ ] (Monitor) R3·D — Správca úloh, Autoruns, HWiNFO · r. 1016–1017
- [ ] Monitor spája Správcu úloh Windows 11 a Autoruns s obsahovo porovnateľnými údajmi CPU-Z/HWiNFO:
  podrobnosti CPU, dosky, pamäte, grafiky a senzorov v čitateľnej podobe, použiteľné aj pre externé
  displeje a nástroje. BetterWindowsServices je inšpirácia na prieskum (správa služieb), nie prijatá úloha.

**10D.10** [ ] (Monitor) R3·D — inventár a bezpečnostné nástroje · r. 1018–1020
- [ ] Rozhodnúť, ktoré inventárne alebo bezpečnostné schopnosti poskytne existujúci `latte-hw`,
  Monitor, Inšpektor siete a Barista. Nástroje typu osquery, Velociraptor, Zeek či Suricata
  nepridávať ako základné služby bez preukázanej potreby a výslovného modelu súhlasu.
- [~] 23. 10.: hardvérový inventár môže na root-only polia použiť Device Manager spustený na
  požiadanie a autorizovaný polkitom; samotný Monitor ostáva bez root práv. Živá telemetria
  senzorov nevyžaduje privilegovaný démon. Zvyšné schopnosti sa rozhodnú osobitne.

**10D.11** [ ] (Monitor) R3·D — diagnostické záznamy · r. 1021–1024
- [ ] Zjednotiť diagnostické záznamy a export podpory tak, aby používateľ vedel skontrolovať,
  čo export obsahuje; citlivé údaje neodosielať automaticky.

**10D.12** [x] (Monitor) Živý výstup senzorov pre Stream Deck
- [x] 23. 10.: `latte-monitor watch` poskytuje verziovaný JSONL (`schema: 1`, čas vzorky, stabilné
  ID senzorov, názvy, hodnoty, jednotky a zdroje) pre lokálne dashboardy a Stream Deck. Bez siete
  a privilegovaného démona; senzor, ktorý systém nehlási, sa nevymýšľa.

**10D.13** [~] (Monitor) Hardvér ako v CPU-Z/HWiNFO
- [~] 23. 10.: prvý inventár v `latte-monitor hardware` — CPU a frekvenčné politiky, RAM a moduly,
  ak ich EDAC hlási, doska/BIOS z DMI, GPU a dostupné ovládače, využitie, VRAM a frekvencie.
  Každý údaj nesie zdroj a stav dostupnosti; čítanie bez oprávnení, bez sériových čísel.
- [~] 23. 10.: doplnené architektúra a režimy CPU, topológia, cache vrátane geometrie, inštrukčné
  príznaky a frekvenčné údaje z `lscpu`/sysfs; chipsety z PCI, GPU model a PCI revízia/subsystém,
  PCIe rýchlosť/šírka linky, zdieľaná pamäť a stavy jadrových/pamäťových hodín. Chybné generické
  DMI mená sa označia ako nedostupné.
- [x] 23. 10.: dohodnutá hranica oprávnení — bežný Monitor ostane bez root práv; root-only polia,
  napríklad SMBIOS DIMM, môže na požiadanie poskytnúť Device Manager cez polkit. Bez stáleho
  privilegovaného démona a bez sériových čísel.
- [x] 23. 10.: `latte-devices protected-memory` spúšťa cez `pkexec` samostatný read-only helper
  pre SMBIOS Type 17; vráti slot, kapacitu, typ a takty, nikdy sériové číslo. Helper nepodporuje
  argumenty ani iné čítanie. CLI aj voliteľná karta v Správcovi zariadení ho spúšťajú až po kliknutí;
  odmietnutie polkitom sa zobrazí ako stav.
- [~] 23. 10.: požiadavka sa viaže na SSH reláciu, preto karta sama nestačí. Správca zariadení ju
  odovzdá Pleamar agentovi spustenému compositorom v grafickej relácii; ten spustí iba pevne daný
  read-only príkaz a vráti výstup cez Pleamar IPC. Zdroj upravený, čaká na živé overenie po nasadení.
- [ ] Overiť a rozšíriť pokrytie ďalších CPU/GPU vlastností a napojiť root-only inventár na
  Monitor bez toho, aby sa celý Monitor spúšťal ako root. Na latte-lab EDAC nevystavuje DIMM moduly
  a SMBIOS záznamy DIMM sú čitateľné iba ako root.
- [ ] Až potom dokončiť GUI. Má spĺňať 3E — estetické, efektívne a ergonomické: prehľadné skupiny,
  dôležité údaje na prvý pohľad, detaily bez zahltenia a jasný pôvod/dostupnosť každej hodnoty.
  GUI sa zatiaľ nemení; po dokončení zberu overiť, že stránka funguje v okne Monitora.

**10D.14** [ ] (Monitor) Vysvetlenie záťaže a bezpečné kroky
- [ ] Pri vysokej spotrebe vysvetliť, ktorá aplikácia alebo súčasť ju spôsobuje, z akých údajov to
  vyplýva a čo možno bezpečne urobiť; uvádzať neistotu a pôvod merania, neponúkať iba „Ukončiť“.

**10D.15** [ ] (Monitor) História spotreby podľa aplikácie
- [ ] Voliteľná dlhodobá telemetria CPU, RAM, GPU, energie, siete a disku podľa aplikácie; jasný
  súhlas, nastaviteľné uchovávanie a vymazanie, oddelenie meraných údajov od odhadov.

**10D.16** [ ] (Monitor) Výstupy pre dashboardy a zvukové LED
- [ ] Rozšíriť lokálny výstup na výber údajov a bezpečné použitie ďalšími aplikáciami; zvuková
  reaktivita a ovládanie LED sú samostatne zapínateľné, bez automatického odosielania dát.

### 10E. [~] DeviceManager
Zdroje: `apps/devices.qml`, `bin/latte-devices`

**10E.01** [x] (Správca zariadení) Správca zariadení · r. 115–116
- [x] **Správca zariadení** (13. 10.): `apps/devices.qml` + `bin/latte-devices` — prehľad počítača, skupiny
  zariadení, ovládač a stav každého, správa na skopírovanie. Iba číta; čo chýba oproti v0.3: LATTEOS-GOO.md §4.4.

**10E.02** [ ] (Správca zariadení) D. Správca zariadení a HW · r. 695–696
- [ ] **Správca zariadení a HW:** dokončiť overenie kompatibility a reálneho HW, ovládačov,
  tlače/skenerov/telefónov a bezpečnej obnovy po zmene.

**10E.03** [~] (Správca zariadení) F. R3·E — zariadenia a siete · r. 853–859
**R3·E — zariadenia a siete:** skúška s reálnou tlačiarňou, skenerom a telefónom (r. 515); KDE Connect `[~]` (r. 534);
zvuk do DLNA (r. 753); Inšpektor — nové zariadenie, slabé heslo routera (r. 756); Inšpektor — **zariadenia Matter a Thread pasívne** (schválené 13. 10.):
skupina „Inteligentná domácnosť“ z ohlásení mDNS (`_matter._tcp`, `_matterc._udp`, hraničné smerovače `_meshcop._udp`),
výrobca a typ, ak ich zariadenie ohlási, upozornenie na nové zariadenie; bez párovania. Podrobnosti cez párovací kód
(batéria, firmvér, topológia Thread) sú iba návrh, nie úloha (inspo 13. 10., podľa UniFi Network 11); `latte-boot compat` v inštalátore (r. 765);
Device Manager v Ruste (r. 767).

**10E.04** (pozn.) (Správca zariadení) R3·E — cieľ · r. 1025–1028
**Cieľ:** LatteOS sa nainštaluje a funguje na jasne opísanom rozsahu PC, vrátane GPU, zvuku, siete,
obrazoviek, napájania, periférií a obnovy pri probléme s ovládačom.

**10E.05** [x] (Správca zariadení) R3·E — základ detekcie · r. 1029–1030

**10E.06** [ ] (Správca zariadení) R3·E — kompatibilita v inštalátore · r. 1031–1032
- [ ] Doplniť kompatibilitu do inštalátora a overiť hranice odporúčaní na rôznych CPU/GPU,
  Secure Boot, notebookoch a starších PC.

**10E.07** [ ] (Správca zariadení) R3·E — AMD a NVIDIA na fyzickom HW · r. 1033–1034
- [ ] Overiť na fyzickom hardvéri AMD aj NVIDIA grafický stack, Hyprland, Goo, hry, SAFE režim,
  aktualizáciu ovládača a návrat po zlyhaní.

**10E.08** [ ] (Správca zariadení) R3·E — ovládače cez štandardné služby · r. 1035–1037
- [ ] Doriešiť ovládače/zariadenia cez štandardné linuxové služby (udisks2, NetworkManager,
  PipeWire, fwupd a pod.) a zrozumiteľne oddeliť informáciu, odporúčanie a akciu vyžadujúcu
  oprávnenie.

**10E.09** [ ] (Správca zariadení) R3·E — telefóny · r. 1038–1039
- [ ] Telefóny: overiť KDE Connect a USB; scrcpy prípadne ponúknuť ako vedomý voliteľný nástroj,
  nie ako náhradu párovania, prenosu súborov alebo Waydroidu.

**10E.10** [ ] (Správca zariadení) R3·E — rozsah Správcu zariadení · r. 1040–1042
- [ ] Rozsah Správcu zariadení z opisu: identifikovať a rozbehnúť všetok pripojený HW (aj ovládače od Steamu);
  Netmanager spolu s ním spravuje všetky siete, sieťové zariadenia a vzdialené pripojenia — TV, sieťové rádio,
  telefóny cez Bluetooth, Wi-Fi, USB alebo na diaľku. Inšpektor siete (hotový základ, podľa ESET Network Inspector).

**10E.11** [ ] (Správca zariadení) R3·E — rizikové zmeny · r. 1043–1046
- [ ] Všetky rizikové zmeny ovládačov, obrazovky a napájania musia mať potvrdenie, časový limit
  alebo obnovovaciu cestu.

### 10F. [x] GuardDog
Zdroje: `bin/latte-session`, `bin/latte-guarddog`, `apps/guarddog.qml`, `system/systemd`, `system/whyd`, `system/oom`, `system/sessions`

**10F.01** [x] (Relácie a GuardDog) GuardDog · r. 321–328
[~] **GuardDog — strážca súčastí a kto komu patrí** (20. 10., na pokyn používateľa po tom, čo sa zabilo `qs` a zmizli
    ikony aj ponuka plochy). `bin/latte-guarddog` (služba `latte-guarddog.service` v cieli relácie): každých 5 s
    skontroluje scénu Goo, nečinnosť, ikony plochy, tapetu a históriu schránky; čo chýba dvakrát po sebe, to spustí
    znova (najviac 5× za 5 minút, potom pokoj a jedno upozornenie). Stav je v `$XDG_RUNTIME_DIR/latteos/guarddog.json`.
    Rovnaký program povie, komu proces patrí: `linux` (jadro a systém), `latteos` (to, z čoho je LatteOS), `user`
    (programy používateľa); Monitor › Procesy to ukazuje štítkom, filtrom a zoznamom strážených súčastí. Overené:
    zabité ikony sa do ~16 s vrátia. **Ostáva:** Nastavenia › Štart (vypnúť stráženie jednej súčasti), strážiť aj
    skutočné aplikácie používateľa na žiadosť, štítky v Správcovi zariadení, upozornenie pri páde mimo strážených súčastí.

**10F.02** [x] (GuardDog) Nezabiteľnosť (26. 10.): všetky jednotky LatteOS `Restart=always`, `RestartSec=1`, `StartLimitIntervalSec=0`; overené TERM a KILL na GuardDog, Goo, lockscreen, idle, focus — späť do 1–2 s.

**10F.03** [x] (GuardDog) Zamrznutie (26. 10.): GuardDog má `WatchdogSec=30` (STOP → systemd ho zabije a spustí za ~30 s); zastavené a zmrazené jednotky `latte-*` GuardDog rozmrazí do 5 s (`thaw`, v konzole „rozmrazil“). Goo vlastný watchdog nemá (pleamar nehlási systemd) — rozmrazenie stačí na STOP, zaseknutá logika ide cez `goo_alive`.

**10F.04** [x] (GuardDog) Kto stráži stráž: systemd; GuardDog pozorovateľ — zapísané v `docs/goo/ROZHODNUTIA.md` (26. 10.).

**10F.05** [x] (GuardDog) **Vyšší stupeň ochrany:** proces toho istého používateľa vie zabiť čokoľvek iné, čo beží pod ním (aj `systemctl --user stop`, `kill -9` na `systemd --user`). Úplná odolnosť = malá systémová služba pod iným uid/root (`latte-guardd`), ktorú používateľ nezabije, a ktorá obnoví používateľskú reláciu. Rozhodnúť, či to treba (komplexita proti zisku); najprv hotový bod 1 a 2.
  **26. 10. hotové — DogHouse** (`system/libexec/latte-doghouse`, `latte-doghouse.timer` raz za minútu, pod rootom): pre každú
  plochu LatteOS (Hyprland s `LATTE_MODE`) skontroluje GuardDog — zablokovaný, podvrhnutý (vlastný unit alebo drop-in
  používateľa) → `systemctl --user revert` a reštart; zastavený → spustí; mŕtvy celý `systemd --user` → spustí `user@UID`,
  dá mu prostredie relácie (z prostredia Hyprlandu a z `hyprland.lock`) a cieľ relácie. So systemd používateľa hovorí ako
  používateľ (`setpriv`; `systemctl -M user@` zo služby nejde), súbory používateľa nečíta ani nepíše. Čo urobil, je v
  `/var/lib/latteos/doghouse.log` a GuardDog to ukazuje v Denníku aj na Prehľade.

**10F.06** [x] (GuardDog) Skúška (26. 10.): `tests/test_guarddog.sh` na živej relácii (TERM, KILL, STOP, freeze; 15/15), napodobené rozmrazenie a watchdog v `tests/test_bin.py` (v `check.sh`).

**10F.07** [x] (GuardDog) **Používateľ 22. 10.: „GuardDog je extrémne nehotový“.** Ďalšie chýbajúce veci z pôvodného zápisu: vypnúť stráženie jednej súčasti (Nastavenia › Štart), strážiť aj skutočné aplikácie používateľa na žiadosť, štítky `linux/latteos/user` v Správcovi zariadení, upozornenie pri páde mimo strážených súčastí. Doplniť zoznam strážených súčastí, ktoré dnes chýbajú (Pobrežie, desktop, hyprbars…).
  **26. 10.:** vypnutie stráženia jednej súčasti už je (Nastavenia › GuardDog a okno GuardDogu, `latte-guarddog set`).
  Pobrežie je časť scény Goo a ikony plochy sú súčasť „icons“ — strážené; hyprbars je doplnok Hyprlandu, nie proces.
  Pribudlo **okno s heslom (polkit)**: polkit agenta prijme iba z prihlasovacej relácie (overené: z jednotky systemd
  „Passed session and the session the caller is in differs“), preto ho spúšťa Hyprland a GuardDog ho po zabití vráti
  cez `hyprctl eval` (~10 s). Upozornenie pri páde chodí teraz vždy (aj bez AI), AI sa ponúkne iba so zapnutým
  pomocníkom. Štítky `linux/latteos/user` boli myslené pre **Monitor** (Ctrl+Shift+Esc a od 26. 10. aj Ctrl+Alt+Del):
  štítok, filter a zoznam strážených už sú, overené naživo (16 LatteOS, 287 Linux, 21 používateľa).
  **Tvoje programy na žiadosť (26. 10.):** Monitor › Procesy, pravé tlačidlo na programe → „Držať v chode (GuardDog)“
  (`latte-guarddog keep PID` / `keep MENO off`); GuardDog si zapamätá spustenie (pri Flatpaku `flatpak run ID`) a čo
  program je: cestu k súboru a jeho SHA-256. Za strážený program berie iba proces, ktorý ten súbor naozaj spúšťa (pri
  systémovom súbore, ktorý mení iba root, stačí cesta — aktualizácia ho nerozbije); rovnako pomenovaný **dvojník** sa
  nezapočíta, zapíše sa do denníka a ohlási upozornením; zmenený súbor („zmenený“) sa nechá bežať, ale ohlási sa.
  Spúšťa cez Hyprland (v prihlasovacej relácii). Strážený program má v Monitore štít a je medzi
  strážením v GuardDogu aj s prepínačom. Overené naživo s foot: zabitý sa vrátil za 9 s, po vypnutí ostal zatvorený; dvojník `foot` (kópia iného programu) ohlásený a skutočný foot sa aj tak vrátil.

**10F.08** [x] (GuardDog) **Dashboard pre používateľa** (používateľ 26. 10.; 3E: Estetické, Efektívne, Ergonomické). Úvodná
stránka GuardDogu: funkčnosť systému (čo beží, čo stráži, celkový stav jednou vetou), **dni od posledného problému**,
**najčastejšie problémy** (čo padalo, koľkokrát, kedy naposledy). Potrebuje históriu udalostí, nielen dnešný `guarddog.json`.
  **26. 10. hotové:** stránka **Prehľad** (prvá v okne GuardDogu): stav jednou vetou, veľké číslo dní bez problému, pás
  posledných 30 dní vo farbách Monitora (dni pred začiatkom histórie sivé), 5 najčastejších problémov (klik → Pády alebo
  Denník). História je trvalá v `~/.local/state/latteos/guarddog.log` (5000 riadkov); pády, ktoré vyrieši systemd skôr, než
  ich GuardDog uvidí, zapisuje podľa `NRestarts` („spadol, vrátil sa“). `latte-guarddog summary`, skúška v `tests/test_bin.py`.

**10F.09** [x] (GuardDog) **Útok na GuardDog** (používateľ 26. 10.): keď bude GuardDog hotový (10F.02–10F.08), skúšať všetky
spôsoby, ako ho zabiť alebo umlčať (signály, `systemctl --user stop/mask`, zabitie `systemd --user`, zaplnenie disku,
zmazanie stavu, zamrznutie), každý nájdený spôsob opraviť a pridať do skúšky 10F.06.
  **26. 10., prvé kolo:** ustál TERM, KILL, STOP, zmrazenie (`tests/test_guarddog.sh`), zmazanú a pokazenú históriu.
  **Našlo a opravené:** poškodené `~/.config/latteos/guarddog.json` (`"off": 5`, zoznam namiesto objektu, zlý `keep`)
  a nezapisovateľný `$XDG_RUNTIME_DIR/latteos` ho zhodili a padal dokola — nastavenia sa teraz čítajú s kontrolou typov
  (`names_in`, `kept`), každé kolo stráženia prežije vlastnú chybu (zapíše ju a pokračuje); skúška v `tests/test_bin.py`.
  Strážený program sa už nepozná podľa mena, ale podľa súboru a SHA-256 (dvojník sa ohlási).
  **Prešlo a bez roota sa opraviť nedá:** `systemctl --user stop latte-guarddog`, `mask` + zabitie, vlastný drop-in
  v `~/.config/systemd/user/latte-guarddog.service.d/` (podvrhnutý `ExecStart`, vypnutý watchdog), zabitie `systemd --user`
  (to vezme aj Goo a všetky jednotky; neskúšané naostro, odpojilo by reláciu). Všetko robí proces toho istého
  používateľa bez hesla → rieši 10F.05 (malý strážca pod rootom).
  **26. 10., druhé kolo (s DogHouse):** stop, mask (runtime aj trvalý), drop-in, podvrhnutý unit — všetko vrátené pri
  najbližšej kontrole; samotný časovač vrátil zastavený GuardDog za 58 s. **Zabitie `systemd --user`:** Goo, zámok,
  nečinnosť, čas pri obrazovke aj GuardDog späť za 48 s. Ten útok našiel dve skryté chyby, obe opravené: (1) zamknutá
  obrazovka po páde zámku ostala na núdzovej obrazovke Hyprlandu — scéna zámku si pamätala zamknutie, ale `emit` z vlastnej
  logiky nespustí vlastný handler, takže zámok nikdy neprevzala (`goo/lib/login.luau`, teraz priame volanie; overené
  zabitím zámku pri zamknutej obrazovke); (2) obrazovka zhasnutá starým hypridle po jeho reštarte ostala tmavá navždy
  (aj Moonlight sa nepripojil) — `latte-idle` ju pri štarte rozsvieti.

### 10G. [~] NetManager
Zdroje: `bin/latte-network`, `bin/latte-net`, `bin/latte-network`

**10G.01** [x] (Sieť) Správca zariadení: Sieť a Inšpektor · r. 146–151
[x] Správca zariadení má dve časti (13. 10.): **Zariadenia** a **Sieť** — Pripojenie (adresa, router,
   DNS, rýchlosť, zapamätané pripojenia) a **Inšpektor siete** (`bin/latte-network`): polkruhový radar,
   dole tento počítač nad routerom, na vnútornom oblúku zariadenia pripojené teraz, na vonkajšom videné
   predtým; nové zariadenie zlato; zariadeniu sa dá dať meno a druh, alebo ho zabudnúť. Inteligentná
   domácnosť sa pozná pasívne z ohlásení Matter a Thread. Chýba: zoznam namiesto radaru, „Moja sieť“
   a upozornenie na nové zariadenie, pripájanie a VPN (to prvé je v paneli Pobrežia), AirPlay.

**10G.02** [~] (Sieť) Detektor siete — úvod · r. 329–335
[~] **Pokročilý detektor siete** (20. 10., používateľ; predpoklad pre CamGoo s domácimi kamerami). Dnešný inšpektor
    siete v Správcovi zariadení (inšpirácia ESET Smart Security) nájde iba počítač, s ktorým je latte-lab spojený káblom.
    Treba: ARP tabuľka a ping sweep podsiete, mDNS/Bonjour, SSDP/UPnP, NetBIOS, ONVIF WS-Discovery (kamery), výrobca
    podľa MAC (OUI), otvorené porty bežných služieb (554 RTSP, 2020 ONVIF Tapo, 80/443, 22, 445, 9100), rozpoznanie typu
    (kamera, tlačiareň, TV, telefón, router), Matter/Thread pasívne (R3·E); ako ESET „Kontrola siete“ so zoznamom a mapou.
    **Cieľ (používateľ, 21. 10.):** celá sieť, čo je ktoré zariadenie a čo vie (prehrať naň hudbu a video, kamera, prijať
    dáta), slabé miesta a ochrana na pár klikov — pre domáceho správcu, ktorý chce prehľad a riešenie bez príkazov.

**10G.03** [x] (Sieť) Detektor a) hĺbková kontrola · r. 336–340

**10G.04** [x] (Sieť) Detektor b) zoznam popri radare · r. 341–341

**10G.05** [ ] (Sieť) Detektor c) akcie zo schopností · r. 342–343
- c. [ ] Akcie zo schopností: Púšťať naň (DLNA/Cast — prepojiť s MediaGoo), Otvoriť obraz (kamera → CamGoo),
  Pridať tlačiareň (CUPS), Otvoriť stránku nastavení, Pripojiť zdieľaný priečinok (DualBrew).

**10G.06** [x] (Sieť) Detektor d) upozornenie na nové zariadenie · r. 344–345
- d. [x] Upozornenie na nové zariadenie (21. 10.): `latte-network watch` každých 30 min v relácii
  (`latte-netwatch.timer`), preložené upozornenie; neoverené v skutočnej relácii.

**10G.07** [~] (Sieť) Detektor e) správca siete · r. 346–349
- e. [~] Správca siete (21. 10.: Pripojenie › Ochrana (DNS): od routera, Cloudflare, Quad9, AdGuard, Google;
  `latte-network dns`; naostro neprepínané, len suchý beh; firewall: zapnutý, zóna a čo sa smie dnu, `latte-network firewall`):
  Wi-Fi siete a heslá, VPN, DNS s ochranou súkromia, firewall (firewalld), hosťovská sieť
  a blokovanie zariadenia — čo sa dá bez routera, a návod do routera, kde nie.

**10G.08** [ ] (Sieť) Detektor f) vzory · r. 350–353
- f. [ ] Vzory: Sniffnet (kto s kým hovorí, pre NET), ESET Kontrola siete, UniFi (Matter), Fing.
  Správca siete je nástroj **pre správcu domácej siete** (používateľ, 21. 10.: bude ním spravovať svoju sieť):
  Zeek a Suricata nie sú „priťažké“, ale voliteľné nástroje správcu — skôr pôvodné programy so správou
  z LatteOS (nainštalovať, zapnúť, ukázať upozornenia) než vlastná náhrada.

**10G.09** [~] (Sieť) Detektor g) mapa siete · r. 354–358
- g. [~] Mapa siete (používateľ, 21. 10.: ako nástroje z čias Windows XP — switch za switchom). Hotové: pohľad Mapa
  s cestou do internetu (traceroute: router za routerom, poskytovateľ) a zariadeniami tejto siete; spätné DNS
  s limitom 2 s. Ďalej: spravovateľné switche cez SNMP (tabuľka MAC → port, BRIDGE-MIB) a LLDP (lldpd), zariadenia
  pod nimi; bežné switche sa vidieť nedajú.

**10G.10** (pozn.) (Sieť) Sniffnet · r. 372–372
- **Sniffnet** ako vzor pre detektor siete a NET.

### 10H. [~] AppManager
Zdroje: `apps/appmanager.qml`, `bin/latte-apps`, `bin/latte-app`; LATTEOS-GOO §6.3
Spravuje všetky aplikacie, prevažne ako flatback, bubblewrap. Ponuka ako Bazzar 

**10H.01** [x] (App Manager) App Manager · r. 110–112
- [x] **App Manager** (13. 10., na pokyn mimo poradia): `apps/appmanager.qml` + `bin/latte-apps` + `bin/latte-app`;
  obchod Flathub (bannery, police, kategórie, hľadanie, stránka aplikácie), moje aplikácie, aktualizácie,
  miesto pre Baristu. Inštalácia a odstránenie overené naostro. Chýba: LATTEOS-GOO.md §6.3.

**10H.02** [x] (App Manager) prechody bannerov · r. 129–134

**10H.03** (pozn.) (App Manager) polica s FreeTube a Pipeline · r. 373–373
- **App Manager:** polica s FreeTube a Pipeline, Stremio a Mangayomi bez doplnkov vopred.

**10H.04** [~] (App Manager) C. GOO / aplikácie a integrácia · r. 672–674
- [~] **GOO / aplikácie a integrácia:** viacero funkcií je hotových, ale ostávajú reálne testy
  telefónu/tlačiarne/skenera, verejnej inštalácie, skutočného Beepera, výkonnostné a prekladové
  medzery a dokončenie App Managera/Baristu. Podrobnosti sú v F3·G a F4–F8.

**10H.05** [ ] (App Manager) D. App Manager a Barista · r. 697–698
- [ ] **App Manager a Barista:** dokončiť stav úloh, históriu a používateľský tok inštalácie;
  Barista pokračuje podľa fáz v `docs/barista/NAVRH.md`, prvý plný prípad je AVP2.

**10H.06** (pozn.) (App Manager) F. R3·F — App Manager a Barista · r. 860–863
**R3·F — App Manager a Barista:** úlohy na pozadí viditeľné (r. 409); obchod — zvyšok (r. 510), Bazaar a ZimaOS (r. 560);
Barista ako pomocník z kontextovej ponuky okna (r. 596); ProtonDB, Waydroid, OARS detské účty, história úloh (r. 787, 868);
„Vrátiť včerajší systém“ (r. 951).

**10H.07** (pozn.) (App Manager) R3·F — cieľ · r. 1047–1050
**Cieľ:** inštalácia, aktualizácia a odstránenie aplikácií je jednotná, kontrolovateľná a
obnoviteľná naprieč Fedora/RPM, Flatpak, webovými aplikáciami, hrami a podporovanými cudzími balíkmi.

**10H.08** [x] (App Manager) R3·F — základ App Managera · r. 1051–1052

**10H.09** [ ] (App Manager) R3·F — úlohy pre systémové príkazy · r. 1053–1054
- [ ] Doplniť spoločný prehľad úloh aj pre systémové príkazy (dnf, Flatpak, cargo, Waydroid,
  umu), vrátane stavu, logu a výsledku po reštarte.

**10H.10** [ ] (App Manager) R3·F — prerušenie a logy úloh · r. 1057–1058
- [ ] Overiť, že úlohy možno bezpečne prerušiť, logy sú dostupné používateľovi a stav po reštarte
  nezostane falošne „úspešný“.

**10H.11** [ ] (App Manager) R3·F — obchod, bazár a Barista · r. 1059–1063
- [ ] App Manager je obchod, bazár a inštalátor Linuxových aplikácií (Flatpak) a aktualizátor všetkého softvéru
  aj ovládačov HW; Barista je jeho súčasť. Barista po zacielení na súbor alebo priečinok rozpozná typ (jeden či
  viac obrazov CD/DVD, delené archívy, portable priečinok, rozbalený inštalátor, XAPK, DOS) podľa internej
  databázy, ktorú treba vybudovať; spolupracuje s Protonom, experimentmi v tejto oblasti, F-Droid 2 a Lepton.
  Zámer: od malých vecí po veľké — dnes Windows a Android (E).

**10H.12** [ ] (App Manager) R3·F — katalógy a recepty · r. 1064–1067
- [ ] Predvolené katalógy a recepty musia mať overiteľný zdroj, licenciu a kontrolu integrity;
  katalógy, ktoré spúšťajú skripty, sa nesmú považovať za dôveryhodné iba podľa vzhľadu.

**10H.13** [ ] **Heslo pri obnovení metadát** (snímka používateľa 27. 10.): App Manager pýta heslo už pri obnovení
metadát, a to anglickou hláškou polkitu („Authentication is required to update metadata“). Obnovenie katalógu nemá
pýtať heslo (pravidlo polkitu pre PackageKit refresh pre prihláseného používateľa); ostatné požiadavky na heslo
s preloženým textom (pravidlo 4). Pozri aj rozhodnutie o vlastnej karte polkitu (ROZHODNUTIA 23. 10.).

### 10I. [~] Barista
Zdroje: `bin/latte-barista`, `recipes/`, `docs/barista/`
Je sučastou Appmanageru. inštalator a ten kdo sa postara o beh programov z inej platformy.

**10I.01** [~] (Barista) Barista v App Manageri · r. 179–184
- [~] **Barista** v App Manageri: sprievodca v piatich krokoch a recept AVP2 (14. 10.); **vetva B** bez receptu
  (20. 10.): rozpozná Inno, NSIS, InstallShield, MSI, samorozbaľovací archív, zip/rar/7z, priečinok aj samotný
  program, z hlavičky PE rok, bitovosť a grafiku, podľa toho Wine alebo Proton (umu-run v ohrade) a verziu Windows;
  hlavný program nájde sám; po „Fungovalo to? Áno“ zapíše recept používateľa. Overené naostro na priečinku, zipe,
  Inno a NSIS. Chýba (stav v `docs/barista/POSTUP.md` §3): DOSBox, apk, balíky Linuxu, winetricks, mechanika pre
  kontrolu CD, vykonanie návrhov po neúspešnej skúške.

**10I.02** [ ] (Barista) Aplikácie podľa Priority UX · r. 266–266
[ ] **Aplikácie podľa Priority UX** — prvý Barista s AVP2 (`docs/barista/NAVRH.md`).

**10I.03** [x] (Barista) E. Barista · r. 766–769
- [x] **Barista (rozhodnuté 9. 10.; cieľ Arabicy):** zámer je „od malých vecí po veľké“. Dnes **Windows a Android**; výhľad
  ďalšie platformy a emulácie (konzoly, retro, neskôr aj nové) podľa toho, čo bude technicky a právne možné —
  autor sleduje vývoj v komunite (tvrdenia z diskusií, napr. o spätnom inžinierstve PlayStation, sú zatiaľ
  neoverené). Každá nová platforma = samostatný rozhodovací bod (R3·I). README opíše rozsah „dnes + výhľad“.

**10I.04** [~] (Barista) R3·F — Barista · r. 1055–1056
- [~] Barista: analýza a plán bez AI sú hotové; pokračovať inštaláciou a skúškou aplikácie,
  registrom, odinštalovaním a zálohou podľa fáz v `docs/barista/NAVRH.md`.

**10I.05** [~] (Barista) Barista — Windows programy · r. 1349–1377
[~] **Barista — Windows programy** (používateľ, 14. 10.: pripraviť knižnice a pustiť sa do Baristu, prvý prípad AVP2).
    **Zázemie na latte-lab (14. 10.):** už bolo Wine 11.0 (Staging), wine-mono, wine-gecko, wine-dxvk, winetricks,
    cabextract, innoextract, 7zip, icoutils, bubblewrap, dosbox-staging, umu-launcher + runtime (662 MB),
    GE-Proton11-7 v `/opt/latteos/proton`, Steam, gamescope, gamemode, MangoHud, 32-bit Vulkan a Mesa, Bottles
    (Flatpak). Doinštalované: **unshield**, protontricks, lutris, wine-dxvk-d3d8/d3d9/dxgi, xorriso. DirectX 8–11
    rieši DXVK a Wine sám; DirectX 12 má Proton (vkd3d). **.NET, vcredist a staré d3dx9 sa nedávajú do systému,
    ale do prefixu konkrétnej hry** (winetricks, na pokyn receptu) — vopred sa stiahnuť nedajú bez inštalácie.
    Chýba: GE-Proton11-8 (je 11-7), vkd3d-proton ako balík (Fedora ho nemá, je v Protone).
    **`bin/latte-barista` (14. 10.):** `analyze` (typ, SHA-256, recept, verdikt, chýbajúce disky; ďalšie disky
    hľadá vedľa prvého), `install` (číta disky cez 7z, Windows = vlastný prefix, kroky receptu: `unshield` a
    `copy`, ikona, položka v ponuke, `manifest.json`), `run` (bubblewrap: systém len na čítanie, z domova iba
    priečinok hry, bez siete, ak recept nepovie inak), `list`, `remove`. Hry sú v `~/Games/<id>`. Recepty
    `recipes/*.json`.
    **AVP2 overené naostro:** inštalácia z dvoch ISO za 1 min 37 s **bez inštalátora InstallShield** (jeho
    kabinety číta unshield), spustenie v ohrade: prehrali sa úvodné logá (Fox, Sierra) so zvukom. 2,7 GB.
    **Neoverené:** menu a samotná hra (treba myš a klávesnicu pri obrazovke), ukladanie, sieťová hra.
    **Známe:** hra beží 640 × 480 v rohu obrazovky — treba škálovanie (gamescope) alebo rozlíšenie v `autoexec.cfg`.
    **Ostáva:** sprievodca v App Manageri (5 obrazoviek podľa `docs/barista/NAVRH.md`), rozpoznanie bez receptu
    (pravidlá Wine/Proton z v0.3 `latte-instalator`), ďalšie typy zdrojov (archív, exe, msi, apk…), závislosti
    cez winetricks, reťaz pokusov, záloha.
    **Sprievodca (14. 10. v noci):** stránka Barista v App Manageri je sprievodca s piatimi krokmi podľa
    `docs/barista/POSTUP.md` — Čo · Pôjde to (všetko zistené ľudskou rečou, verdikt, povolenie ísť na internet:
    Lutris, alebo pokračovať offline) · Kam a ako (priečinok, ohrada, sieť) · Inštalácia (priebeh; potom Otvoriť
    priečinok · Ukázať log · Spustiť na skúšku · Fungovalo to? Áno/Nie; pri Nie čo hovorí log spustenia) · Hotovo.
    `latte-app appmanager barista ZDROJ…` otvorí sprievodcu rovno so zdrojom. Overené naostro klikaním: kroky 1–4
    s AVP2 vrátane internetu a inštalácie; klik na „Áno“ a krok 5 nie (okno sa pri preinštalovaní LatteOS
    načítalo znova). Wine už pri inštalácii neukazuje vlastné okno (prefix sa robí bez obrazovky, 55 s namiesto
    97 s) a verzia Windows sa naozaj nastaví (predtým `winecfg -v` potichu nič nespravil). Poznámky receptu sú
    po anglicky (recept nemá preklady).

**10I.06** [ ] (Barista) Sledovať nové vrstvy pre cudzie programy (používateľ 26. 10., `inspo/dalsie_inspiracie.md`).
Popri Wine/Protone (Windows) a Leptone (Android) ďalšie dve, obe GPL-3.0 a experimentálne; každá je samostatný
rozhodovací bod podľa 10I.03, zatiaľ iba sledovať:
- **Raven** (github.com/mirkobrombin/raven) — Windows programy bez Wine a bez VM: kód beží na CPU v ohrade,
  systémové volania, súbory, register a okná rieši Raven sám; grafika cez Wayland a Vulkan (DXVK, vkd3d-proton,
  D3D 8–12). Inštalátory NSIS, Inno, MSI; VC++ 2005–2022, .NET 3.5/4.8. Vlastný prefix (C: a register) so
  snímkou pred každým inštalátorom (`--restore-prefix`) — rovnaký nápad ako záloha v Baristovi. Iba príkazový
  riadok, zatiaľ sa len kompiluje zo zdroja.
- **Rosemary** (github.com/microlift/rosemary, aktívne vyvíjaný) — macOS programy na Linuxe: načíta Mach-O,
  Darwin a Apple knižnice (Foundation, AppKit, CoreAudio…) prepísané v Ruste, x86-64 kód prekladá JIT
  (Microlift), knižnice hostiteľa sa premosťujú. Rust 1.99+, SDL 3.4. Pokrytie aplikácií neúplné, tabuľka
  kompatibility zatiaľ nie je; okolo neho vznikajú spúšťače macOS Robloxu (nutmeg, Roseline).
Pre Baristu: rozpoznať `.app`/`.dmg` a povedať človeku, či sa dá skúsiť.

**10I.07** [ ] (Barista) Preskúmať **Eagle** z Bottles (používateľ 26. 10.; Bottles je GPL-3.0). Eagle spozná `.exe`
podľa offline dát z ProtonDB a winetricks a navrhne nastavenia, ktoré pomohli iným — rovnaký nápad ako krok
Analýza v Baristovi. Zistiť: (a) či nastavenia aj sám použije (vyzerá tak), nielen radí; (b) formát a zdroj
offline databázy, podľa čoho spozná program, ako často sa obnovuje; (c) čo z toho prevziať do receptov Baristu.
Možný výsledok: Eagle ako **spustiteľná možnosť popri Baristovi** (druhý názor alebo náhradná cesta).

### 10J. [~] Kalendár
Aplikácia Kalendár a karta ClockGoo (ľavý klik): EDS, udalosti vetou, týždeň.
Zdroje: `apps/calendar.qml`, `bin/latte-cal`, `goo/lang/sk-dates.json`

**10J.01** [ ] (Kalendár) Kalendár — úvod · r. 510–517
- g. [ ] **Kalendár ClockGoo (ľavý klik) a aplikácia Kalendár** (používateľ, 21. 10.: „kalendár, ktorý bude každý OS
  závidieť“, prepojený s ≥10 kalendárovými službami). Návrh na schválenie: https://claude.ai/artifact/JZr5fi8uL3b6FavXCKUcbU
  (mesiac s počasím, meninami a sviatkami, „Ďalej o…“ s Pripojiť sa, deň ako časová os s voľnými oknami, pridanie
  vetou cez lokálnu AI, týždeň s ťahaním myšou, rok ako teplotná mapa v štandardných farbách, Nerušiť počas
  stretnutí, kalendár ako nástroj LensAI). Základ prebratý: **Evolution Data Server + GNOME Online Accounts**
  (+ `evolution-ews`, `gnome-online-accounts-gtk`, všetko vo Fedore) — Google, Microsoft 365/Outlook, Exchange,
  Nextcloud cez OAuth; iCloud, Fastmail, Zoho, Yahoo cez CalDAV; Proton, Tuta, EduPage a odbery cez .ics; Thunderbird
  a miestne cez EDS.

**10J.02** [x] (Kalendár) Kalendár: karta ClockGoo · r. 518–522

**10J.03** [x] (Kalendár) Kalendár: veta a lokálna AI · r. 523–529
- [x] **Veta, ktorej slová nerozumejú → lokálna AI** (21. 10.): pri Pridať, keď pravidlá nenašli deň ani čas alebo
  v názve ostalo slovo času, `latte-cal parse --ai` → `latte-ai quick` (najmenší model nad 2 GB: Qwen3.5 2B vynechával
  dátum, 4B čítal správne, ~12 s na procesore); výsledok sa ukáže v čipoch, pridá sa až ďalším stlačením.
  Používateľ 21. 10.: „zubár koncom mesiaca ráno o deviatej“ dala AI na stredu 28. 10. (správne piatok 30. 10.) →
  dátumy počítajú pravidlá (koniec/začiatok/polovica mesiaca na pracovný deň, posledný piatok v mesiaci, o N dní
  či týždňov, hodiny slovom „o deviatej“, „pol siedmej“, ráno/večer); AI dostane zoznam dní na 6 týždňov. 4B sa
  aj tak mýli (posledný piatok → 20. 11.), premýšľanie trvá minúty — AI ostáva iba na zvyšok, s potvrdením.

**10J.04** [x] (Kalendár) Kalendár: aplikácia · r. 530–535
- [x] **Aplikácia Kalendár** (22. 10., `apps/calendar.qml`, `latte-app calendar`, podľa návrhu „Týždeň“): deň, týždeň a
  mesiac; malý mesiac, moje kalendáre (skryť/ukázať), vyťaženie pol roka v štandardných farbách; v týždni počasie,
  čiara teraz, ťahaním myšou nová udalosť, presun aj predĺženie; vpravo otvorená udalosť a úprava (názov, čas,
  miesto, poznámka, **vlastná farba** = COLOR z iCalendar, ako Evolution) — `latte-cal update`. Karta ClockGoo:
  „V okne“ a klik na udalosť dňa ju otvorí v aplikácii; mesiac ukazuje iba svoje dni. `latte-cal` nečaká 15 s na
  miestny kalendár (0,5 s namiesto 15,5 s).

**10J.05** [ ] (Kalendár) Kalendár: otvorené · r. 536–537
- [ ] Rok ako samostatný pohľad a Agenda; mapa a čas cesty pri udalosti; Nerušiť počas stretnutí; kalendár ako
  nástroj LensAI.

**10J.06** [ ] (Kalendár) **Cieľ (používateľ 22. 10.): funkčnosť aspoň ako Google Kalendár na Androide.** Dizajn ostáva (je dobrý, nemeniť); dopĺňajú sa funkcie. Test 22. 10.: úprava udalosti je len povrchná, s Google Kalendárom sa zatiaľ nedá porovnať. Pri každej funkcii si pozrieť, čo vie Evolution Data Server (`libecal`/iTIP/VALARM/RRULE), aby sa nevymýšľalo.

**10J.07** [ ] (Kalendár) **Udalosti — úprava a tvorba:** celodenné a viacdňové; začiatok/koniec s časovým pásmom (aj dve pásma); názov, miesto (s mapou/čas cesty), popis (formátovaný), prílohy, odkaz na videohovor (Meet/Teams/Zoom), farba udalosti aj kalendára, súkromná/verejná, „zaneprázdnený/voľný“; duplikovať, presunúť do iného kalendára, odstrániť, **Späť** po zmazaní.

**10J.08** [ ] (Kalendár) **Opakovanie (RRULE):** denne, týždenne (vybrané dni), mesačne (deň v mesiaci / n-tý deň v týždni), ročne, vlastné; koniec (dátum / po N opakovaniach); pri úprave **táto / táto a ďalšie / všetky**; výnimky.

**10J.09** [ ] (Kalendár) **Pripomienky:** viac pripomienok na udalosť (minúty/hodiny/dni pred), predvolené pre kalendár, upozornenie cez LatteOS notifikácie aj pri zatvorenej aplikácii, odloženie.

**10J.10** [ ] (Kalendár) **Hostia a pozvánky:** pridať hostí (e-mail), stav odpovede ÁNO/NIE/MOŽNO, práva hostí (upraviť/pozvať ďalších/vidieť zoznam), odpovedať na pozvánku, ukázať voľno/obsadené hostí a **navrhnúť čas** (v EDS cez iTIP/free-busy; podľa účtu — Google, Exchange, CalDAV).

**10J.11** [ ] (Kalendár) **Pohľady:** deň, 3/4 dni, týždeň, mesiac (hotové), **rok**, **Agenda/Plán** (zoznam), prechod klávesnicou aj myšou, „Dnes“, číslo týždňa, vyhľadávanie udalostí (názov, miesto, hostia), tlač.

**10J.12** [ ] (Kalendár) **Kalendáre a účty:** pridať/odobrať účet (Google, Microsoft 365, iCloud, Nextcloud, CalDAV, .ics odber), viac kalendárov, skryť/ukázať (hotové), nový kalendár, zdieľanie, import a export `.ics`, kalendár sviatkov, narodeniny z kontaktov, meniny (hotové).

**10J.13** [ ] (Kalendár) **Čas a plánovanie ako Google:** pracovný čas a miesto práce, **Mimo kancelárie**, **Sústredenie** (Nerušiť), predvolená dĺžka udalosti, týždeň od pondelka/nedele, druhé časové pásmo, **Termíny/Úlohy** (Google Tasks / VTODO), pripomienky ako samostatné veci, „Naplánovať stretnutie“ s voľnými oknami.

**10J.14** [ ] (Kalendár) **Ovládanie myšou ako Google:** ťahanie na vytvorenie (hotové), presun a zmena dĺžky ťahaním (hotové), dvojklik = úprava, pravý klik = ponuka (farba, duplikovať, odstrániť), rýchle pridanie vetou (hotové), klávesové skratky ako doplnok.

**10J.15** [ ] (Kalendár) **Postup:** najprv úprava udalosti (komplet polia) + opakovanie + pripomienky, potom hostia a pozvánky, potom rok/Agenda, nakoniec Úlohy a plánovanie. Každý krok: porovnať s Google Kalendárom na Androide a zapísať, čo ešte chýba.

### 10K. [ ] Hry
Herná relácia: Steam, Proton, umu, gamescope, MangoHud, NVIDIA.
Zdroje: `bin/latte-game`

**10K.01** (pozn.) (Hry) F. R3·I — hry · r. 869–871
**R3·I — hry:** Steam, umu, Proton 11 (r. 883); NVIDIA akmod (r. 892); gamescope, MangoHud, HDR/VRR — čaká na skúšku (r. 898);
Lepton, F-Droid 2 (r. 906–907); SAFE pri zlom ovládači NVIDIA (r. 910).

**10K.02** (pozn.) (Hry) R3·I — cieľ · r. 1104–1106
**Cieľ:** herná relácia a cudzie aplikácie sú integrované bez oslabenia bežného desktopu alebo SAFE.

**10K.03** [ ] (Hry) R3·I — Steam, Proton, umu · r. 1107–1108
- [ ] Dokončiť Steam/Proton/umu a Barista herné scenáre na podporovanom skutočnom GPU; vo VM
  zachovať iba primerané smoke testy.

**10K.04** [ ] (Hry) R3·I — prechod Desktop ↔ Hra · r. 1109–1109
- [ ] Overiť prechod Desktop ↔ Hra, návrat profilu výkonu, zvuku, okien a nastavení po skončení hry.

**10K.05** [ ] (Hry) R3·I — externé technológie · r. 1110–1113
- [ ] Lepton/Android hry, gvisor, scrcpy a ďalšie externé technológie zostávajú samostatnými
  rozhodovacími bodmi; do produktu prejdú iba po teste prínosu, kompatibility, bezpečnosti a údržby.

---

## 11. [~] Bezpečnosť, súkromie a záloha
Zdroje: `bin/latte-net`, `system/libexec/latte-netd`

**11.01** [x] (Bezpečnosť, súkromie a záloha) B. bezpečnosť · r. 635–636

**11.02** (pozn.) (Bezpečnosť, súkromie a záloha) F. R3·H — bezpečnosť · r. 867–868
**R3·H — bezpečnosť:** profily pre Windows aplikácie (r. 812); NET pre jednotlivé hry v Steame a skripty (r. 818).

**11.03** (pozn.) (Bezpečnosť, súkromie a záloha) R3·H — cieľ · r. 1088–1090
**Cieľ:** bezpečnosť je vlastnosťou každej etapy a každej oblasti, nie samostatný doplnok na konci.

**11.04** [x] (Bezpečnosť, súkromie a záloha) R3·H — základ · r. 1091–1092

**11.05** [ ] (Bezpečnosť, súkromie a záloha) R3·H — sieťové profily pre Wine/Proton · r. 1093–1094
- [ ] Doplniť sieťové profily pre Wine/Proton scenáre a podporované skripty; overiť izoláciu
  každej novej cesty spúšťania.

**11.06** [ ] (Bezpečnosť, súkromie a záloha) R3·H — kontrola integrácií · r. 1095–1096
- [ ] Pri integráciách kontrolovať licenciu, pôvod, oprávnenia, aktualizácie, sieťový prístup a
  spôsob uloženia tajomstiev pred ich prijatím do systému.

**11.07** [x] (Bezpečnosť, súkromie a záloha) R3·H — záloha domova · r. 1097–1097

**11.08** [ ] (Bezpečnosť, súkromie a záloha) R3·H — obnova dát · r. 1098–1099
- [ ] Overiť obnovu používateľských dát a profilov v ďalších scenároch; pred ničivou akciou
  ukázať rozsah a cieľ.

**11.09** [ ] (Bezpečnosť, súkromie a záloha) R3·H — bezpečnostné nástroje · r. 1100–1103
- [ ] Voliteľné skeny či bezpečnostné nástroje nesmú sľubovať úplnú ochranu; zobrazovať limity,
  možné falošné poplachy a vyžadovať súhlas so zberom/analýzou dát.

### 11A. NET a sieťové profily
Odstavenie aplikácie od internetu (tlačidlo NET je v 8.01), profily pre Wine/Proton.

---

## 12. [ ] Preklady a jazyk
Všetok text na obrazovke ide cez preklady (pleamar `translations`, QML `i18n.tr()`); prepínanie podľa `LANG`, žiadna slovenčina natvrdo.
Zdroje: `goo/lang/`

**12.01** [ ] (Preklady a jazyk) R3·B — preklady a prístupnosť · r. 977–978
- [ ] Preklady a prístupnosť dokončiť podľa schváleného rozsahu po ustálení funkcií; pripraviť
  testy pre čitateľnosť, kontrast, obmedzenie pohybu a klávesnicové ovládanie.

---

## 13. Prístupnosť
Až v Arabice 1+ (rozhodnuté 13. 10.). Ovládanie Goo z klávesnice (Win+T) už je.
Zdroje: LATTEOS-GOO §6.1

Optimalizácia 
STRESTEST 

---

## 14. [~] Build a vydania
Čistý strom v0.4 Fresh, `FILES`, `./install`, `tests/check.sh`, verejné repo, README, licencie, brány 1.0 Arabica.
Zdroje: `FILES`, `install`, `tests/`, `TRETIE-STRANY.md`, `ZMENY.md`

**14.01** [~] (Build a vydania) Fresh — úvod · r. 28–36
[~] **v0.4 Fresh — čistý strom** (schválené 12. 10.; vetva `v0.4-fresh`, predloha pod značkou `v0.3-archive`).
   Nahrádza body „Upratanie Classicu“, „Premenovanie kvapiek“ a „Čistá inštalácia verejného stromu“. Cieľ: čistá
   Fedora → prihlasovanie Goo + dve relácie, **LatteOS SAFE** (samostatné GUI) a **LatteOS GOO** (engine Goo so všetkými
   kvapkami), k nim zatiaľ ostáva herná relácia **LatteOS Game** (Steam + gamescope; rozhodnuté 12. 10.), bez Noctalie a bez zrušených vecí. Pravidlá pre každý kus, ktorý do Fresh vstúpi: kód, mená príkazov,
   súborov a komentáre po anglicky (komentár iba „prečo“, bez odkazov na staré verzie); text na obrazovke iba cez
   preklady (scény: vstavané `translations` pleamaru 0.3 s faktom `locale`, prepnutie za behu, logika `tr()`; aplikácie
   QML `i18n.tr()`); žiadny kus nemenuje inú aplikáciu priamo (kto čo otvára, vie jedno miesto); scény podľa skillu
   `pleamar` (logika nekreslí a nepozná súradnice), po každej úprave `pleamar --check`. Strata funkcie je prípustná,
   obnoví sa testovaním; zmazané sa vytiahne cez `git show v0.3-archive:cesta`.

**14.02** [x] (Build a vydania) Fresh a) · r. 37–37

**14.03** [x] (Build a vydania) Fresh b) Starý kód do old/ · r. 38–43
- b. [x] **Starý kód do `old/`** (12. 10.): celý strom v0.3 (`session`, `setup`, `crates`, `resources`, `Cargo.*`,
  `docs_zaloha`) je v `old/` bez zmeny obsahu a dá sa z neho ďalej inštalovať (`old/setup/f1/install-session.sh`) —
  na latte-lab ostáva starý LatteOS na porovnanie. Pôvodný `old/` (Classic v GTK) je zmazaný, ostáva pod značkou.
  V koreni ostáva: `docs`, `bughunt`, `inspo`, `ROADMAP.md`, `LATTEOS-GOO.md`, `README.md`, `ZMENY.md`,
  `TRETIE-STRANY.md`, `LICENSE`, `CLAUDE.md`. `old/` je predloha: nemení sa a do Fresh sa z neho nekopíruje, píše sa
  podľa neho nanovo.

**14.04** [~] (Build a vydania) Fresh d) Písať načisto — poradie · r. 50–50
- d. [~] **Písať načisto, po kusoch** — so skillom `pleamar`, podľa `old/`, ale lepšie. Poradie (používateľ 12. 10.):

**14.05** [~] (Build a vydania) FILES · r. 208–210
- e. [~] **Zoznam súborov (`FILES`)** od prvého kusu (založený 12. 10., stráži ho `tests/check.sh`): každý súbor, ktorý LatteOS pridá do systému, má riadok
  „cieľ v systéme ← zdroj v repe“. Inštalátor aj odinštalovanie sa neskôr napíšu nad týmto zoznamom; dovtedy
  sa podľa neho inštaluje ručne. Čo LatteOS v systéme mení (nie pridáva — `/etc/os-release`, greetd), má vlastný oddiel.

**14.06** [~] (Build a vydania) Inštalátor a odinštalovanie · r. 211–225
- f. [~] **Inštalátor a odinštalovanie**: `./install` (13. 10.) nad zoznamom `FILES` — bez prepínača iba vypíše, čo
  chýba a čo by spravil; `sudo ./install --go` postaví (cargo, plugin), skopíruje súbory, nahrádzané odloží ako
  `*.pre-latteos` a spustí kroky z oddielu `[steps]`; `--remove` ich vráti (`[undo]`) a súbory odoberie
  (`--purge` aj to, čo vzniklo počas behu); `--root DIR` inštaluje do priečinka bez krokov (skúška, balíček);
  `--prune` odstráni z vlastných priečinkov LatteOS to, čo ostalo po staršej verzii. `tests/check.sh` pri každej
  kontrole nainštaluje do dočasného priečinka a zasa odoberie.
  **Urobené 13. 10.:** výmena na latte-lab jedným príkazom `sudo ./fresh-install` (snímka snapper, záloha nastavení
  do `/var/backups`, `./install --go --prune`, potom `./migrate-v03 --go` — 80 zvyškov v0.3 mimo vlastných
  priečinkov a balíky Noctalie); ochrana pred nedostatkom pamäte (`system/oom/`) prenesená do Fresh. Po reštarte
  beží 0.4: greetd → `latte-session` → Hyprland → Goo; Sunshine, EDID a repozitáre ostali.
  **Pôvodne ostávalo (s používateľom):** výmena na latte-lab bez preinštalovania Fedory — snímka snapper pred ňou,
  nastavenia používateľa do zálohy, odobratie v0.3 mimo vlastných priečinkov (v0.3 odinštalátor nemá: staré
  jednotky systemd, `/usr/libexec/latteos`, staré príkazy v `/usr/bin`, Noctalia) — a čistá Fedora vo VM
  s voliteľným vzdialeným prístupom (dnes `old/setup/lab/vzdialene.sh`). Až tu sa dokončia zvyšné testy bodu 1.
  Na latte-lab dnes `./install` hlási: chýba balík `NetworkManager-tui`; 552 súborov v0.3 vo vlastných priečinkoch.

**14.07** [ ] (Build a vydania) Fresh → main · r. 226–226
- g. [ ] Fresh → `main`, verzia 0.4.0; verejné vydanie iba na pokyn.

**14.08** (pozn.) (Build a vydania) Rozloženie Fresh · r. 227–229
- Rozloženie Fresh (schválené 12. 10.): `goo/` engine, kvapky, prihlásenie, zámok, SAFE a `lang/` s prekladmi ·
  `apps/` aplikácie QML · `bin/` príkazy · `system/` Hyprland, labwc, greetd, systemd, plymouth · `assets/` tapety,
  písma, textúry · `crates/` Rust · `patches/` záplaty pleamaru · `tests/` kontroly (`tests/check.sh` pred každým commitom) · `FILES`.

**14.09** (pozn.) (Build a vydania) Fedora 45 a oo7 · r. 374–374
- **Fedora 45** (30. 10.) až po prebudovaní COPR; **oo7** ako trezor hesiel (kamery, cloudy).

**14.10** [~] (Build a vydania) C. GOO / verejné vydanie · r. 665–666
- [x] **GOO / verejné vydanie:** príprava a vydanie 0.3.0 „Jihlavanka“ sú zaznamenané ako hotové.
  [ ] Čistú inštaláciu vydaného verejného stromu treba ešte overiť.

**14.11** [ ] (Build a vydania) D. integrácia, kvalita a vydanie · r. 701–703
- [ ] **Integrácia, kvalita a vydanie:** dotiahnuť jednotné GUI, preklady a prístupnosť po ustálení
  funkcií; testovať VM aj reálny AMD/NVIDIA HW, čistú inštaláciu, aktualizáciu, obnovu, výkon a
  regresie pred ďalším vydaním.

**14.12** [ ] (Build a vydania) E. pravopis v opise · r. 785–787
- [ ] Pravopis v opise: Flatpak, bubblewrap, „softvér“; „sf“ = softvér; „blue“ = Fedora Atomic / Universal Blue.

**14.13** (pozn.) (Build a vydania) R6 — cieľ · r. 1153–1156
**Výsledok:** vydaná verzia má reprodukovateľný obsah, známe obmedzenia, dokumentáciu a bezpečnú
cestu k aktualizácii alebo návratu.

**14.14** [ ] (Build a vydania) R6 — definícia LatteOS 1.0 „Arabica“ · r. 1157–1168
- [ ] **Definícia LatteOS 1.0 „Arabica“:** ciele z prezentácie (E) a testy z [bughunt/STRESTEST.md](bughunt/STRESTEST.md)
  spojiť do jedného zoznamu brán (STRESTEST sa plní postupne podľa blízkosti k 1.0); prístupnosť patrí do Arabicy. Marketingové tvrdenia (Barista „čokoľvek“, AI voľba
  v inštalátore, Nervboot) sa nepíšu ako hotové, kým ich brána neoveri.
  **Brány „pre sebe podobných“** (office hours 20. 10.; robia sa až na konci, keď funkcie existujú):
  1. *Aktualizácia nerozbije plochu:* pleamar ako balík (dnes `/usr/bin/pleamar` nevlastní žiadny balík, preložený
     z `~/src`), pluginy (`latte-events`, hyprbars, Hyprglass) sa preložia s každým novým Hyprlandom a až potom sa
     zámok verzie posunie; skúška prechodu na ďalšiu Fedoru (45). **Hneď (20. 10.):** `dnf versionlock` na Hyprland
     (latte-lab aj krok vo `FILES`).
  2. *Inštalácia na cudzí počítač* bez repa a ručného prekladania: balíky LatteOS (vlastné COPR) alebo obraz;
     `latteos-local` (hyprland-latte so záplatou vmwgfx) existuje iba na latte-lab. Posúva „distribúciu balíkov“ z R7 sem.
  3. *Záloha dát používateľa* (domov, nie systém — snapper chráni iba systém): stránka Nastavenia › Zálohovanie.
  4. *Prechod z Windowsu* pri prvom spustení: súbory, záložky a heslá prehliadača.

**14.15** [ ] (Build a vydania) R6 — pred vydaním · r. 1169–1170
- [ ] Pred vydaním uzavrieť rozsah, verziu, zmeny, licencie/tretie strany, inštalačný zdroj,
  kontrolné súčty a skúšku obnovy.

**14.16** [~] (Build a vydania) R6 — README · r. 1171–1171
- [~] Nový dvojjazyčný README (EN/SK) z autorovho opisu je v `setup/verejne/README.md` (9. 10.; zverejní ho `zverejnit.sh` na pokyn). Po premenovaní kvapiek (E) prepísať názvy GooBar → BarGoo, GooPower → PowerGoo; AI voľbu pri inštalácii nesľubovať ako hotovú.

**14.17** [ ] (Build a vydania) R6 — podporovaný hardvér · r. 1172–1173
- [ ] Zaznamenať podporovaný hardvér, známe problémy a postup diagnostiky bez zverejnenia
  súkromných údajov alebo tajomstiev.

**14.18** [ ] (Build a vydania) R6 — po vydaní · r. 1174–1175
- [ ] Po vydaní triediť hlásenia podľa závažnosti, reprodukovať ich, opraviť a overiť regresiu;
  bezpečnostné aktualizácie a obnova majú prednosť pred novými efektmi.

---

## 15. [ ] Inšpirácie a tech radar
Nápady bez rozhodnutia; samostatné úlohy z nich sú pri svojej kategórii. `inspo/`.
Zdroje: `inspo/dalsie_inspiracie.md`, `inspo/LatteOS – technologický radar 2026.md`

**15.01** [ ] (Inšpirácie a tech radar) Z inšpirácií a tech radaru — úvod · r. 366–366
[ ] **Z inšpirácií a tech radaru (20. 10.)** — po bodoch 12 a 13, nič z toho nie je naliehavé:

**15.02** [ ] (Inšpirácie a tech radar) C. GOO / ďalšie rozhodnutia · r. 675–679
- [ ] **GOO / ďalšie rozhodnutia:** nové návrhy z `inspo/` (napr. reakcia kvapiek na hudbu,
  vizuálne prechody, ďalšie cloudové či bezpečnostné nástroje) sú prieskum, kým sa výslovne
  neprijmú; existujúce návrhy a verdikty sú v [inspo/dalsie_inspiracie.md](inspo/dalsie_inspiracie.md).

---

## 16. [~] Pravidlá postupu a brány
Ako sa prechádza od nápadu po vydanie (R0, R1, R4), trvalé priority.
Zdroje: `docs/ARCHITECTURE.md`

**16.01** [~] (Pravidlá postupu a brány) ROADMAP2 — pravidlá práce · r. 575–603
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

**16.02** [x] (Pravidlá postupu a brány) C. rozhodnutie o poradí práce · r. 656–657
- [x] **Rozhodnutie o poradí práce:** najprv dokončiť použiteľné GOO a systémový zážitok; nápady
  z inšpirácie alebo nové externé projekty sa nepridávajú automaticky ako závislosti.

**16.03** [ ] (Pravidlá postupu a brány) Trvalé priority — Priorita UX · r. 800–800
- [ ] **Priorita UX (od 7. 10. 2026):** najprv softvér zo zoznamu záujmov a zvyky z Windowsu; prístupnosť až v Arabice.

**16.04** (pozn.) (Pravidlá postupu a brány) Etapy produktu — úvod · r. 879–884
Nasledujúce etapy opisujú postup od zámeru po vydanie. Sú to brány a výsledky pre celý produkt;
aktuálne hotové, rozhodnuté a otvorené pracovné celky sú zhrnuté v častiach A–D vyššie a ich
technický rozpis ostáva v pôvodných fázach.

**16.05** [~] (Pravidlá postupu a brány) R0 — zámer, používatelia a rozsah · r. 885–897
**Výsledok:** je jasné, pre koho LatteOS je, aký problém rieši, čo je jeho jediná edícia a čo do
produktu nepatrí. Zaznamenajú sa používateľské scenáre, obmedzenia VM a podporovaného hardvéru,
zásady ovládania a priority.

- [x] Smer LatteOS GOO, zrušenie Classicu, zásady Goo a základný cieľ používateľského zážitku sú
  zachytené v existujúcich dokumentoch.
- [ ] Pri nových väčších funkciách doplniť konkrétny scenár a dôvod: čo chce používateľ dosiahnuť,
  ako to dnes urobí a ako spozná, že LatteOS to vyriešil lepšie.
- [ ] Udržiavať jednu aktuálnu hranicu produktu: čo je súčasť systému, čo voliteľná aplikácia /
  integrácia a čo iba externý alebo vývojársky nástroj.

**16.06** [ ] (Pravidlá postupu a brány) R1 — prieskum a technický návrh · r. 898–912
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

**16.07** (pozn.) (Pravidlá postupu a brány) R3 — úvod · r. 931–936
Pracovné prúdy nižšie môžu ísť súbežne, ale každá väčšia funkcia v nich postupuje cez R0/R1, prototyp,
implementáciu, integráciu a overenie. Podnadpisy sú súčasťou jednej produktovej roadmapy, nie oddelené
projekty bez spoločného cieľa.

**16.08** (pozn.) (Pravidlá postupu a brány) R4 — cieľ · r. 1124–1126
**Výsledok:** pracovné prúdy spolu fungujú ako jeden systém, nie iba ako samostatné aplikácie.

**16.09** [ ] (Pravidlá postupu a brány) R4 — celý tok · r. 1127–1128
- [ ] Overiť celý tok: inštalácia → boot → SAFE/NORMAL → prihlásenie → načítanie profilu →
  Goo/Noctalia/Hyprland → aplikácie a zariadenia → odhlásenie → ďalší štart.

**16.10** [ ] (Pravidlá postupu a brány) R4 — jedno miesto pravdy · r. 1129–1130
- [ ] Zjednotiť prenos stavov medzi shellom, systémovými službami a aplikáciami: úlohy, oznámenia,
  nastavenia, témy, profily, povolenia a diagnostika majú jedno miesto pravdy.

**16.11** [ ] (Pravidlá postupu a brány) R4 — pády komponentov · r. 1131–1132
- [ ] Otestovať pády komponentov jednotlivo: engine, shell, kompozitor, služba, aplikácia, úložisko,
  sieť a aktualizácia. Zlyhanie jednej časti nesmie bezdôvodne znefunkčniť celý systém.

**16.12** [ ] (Pravidlá postupu a brány) R4 — UI a backend · r. 1133–1136
- [ ] Doplniť medzery medzi UI a backendom: každá akcia má viditeľný priebeh, výsledok alebo chybu;
  žiadne tiché zlyhanie ani úspech bez vykonanej operácie.

---

## 17. [ ] Optimalizácia
Po dokončení všetkých súčastí, pred STRESTESTOM. Ciele: **zrýchlenie načítania**, **zmenšenie veľkosti na úložisku**, **nižšia náročnosť na hardvér** — vždy **bez obmedzenia výsledku** (vzhľad a funkcie ostávajú). Najprv merať, potom meniť, potom znova merať.
Zdroje: `docs/OPTIMALIZACIA.md`, `tests/screen.sh` (`PLEAMAR_TIMING=1`)

**17.01** [ ] (Optimalizácia) záťaž GooEngine v pokoji · r. 256–265
[ ] **GooEngine:** záťaž v pokoji (12. 10.: 44 % jadra, 6. 10.: 17 %), hĺbková kontrola LensGoo, monitor
   pripojený za behu, 1024 × 768.
   Fresh, merané 12. 10. v `tests/screen.sh` (RX 640, 60 snímok/s, `PLEAMAR_TIMING=1`): scéna s 32 miestami 24 % jadra
   (pravidlá a pružiny 1,5 ms, skladanie 1,2 ms, kreslenie 0,7 ms na snímku), so 16 miestami 17 %; každých 16 miest
   stojí ~7 %, aj prázdnych. Zatvorená karta a prázdne miesta sa už nekreslia (27 → 24 %). Čo by pomohlo najviac:
   `rate:` podľa podmienky (záplata pleamaru — 30 snímok/s, kým kurzor nie je pri kvapkách; `rate` je dnes iba číslo),
   prípadne menej miest.
   **Z Vitreusu, ešte neurobené (13. 10.):** efekty iba počas pohybu — prechodové efekty zapínať podľa vzdialenosti
   pružiny od cieľa, v pokoji nulová cena (materiál a rast karty z Vitreusu sú hotové, ostáva merať; sklo pri
   pokoji dnes nestojí nič, lebo `lens` číta obraz iba pri pohybe).

**17.02** (pozn.) (Optimalizácia) Linux 7.3 a správa VRAM · r. 367–368
- **Linux 7.3 na latte-lab:** RX 550 (Polaris) v Supreme Commanderovi a Quake 3 proti 7.2 (MangoHud); správa VRAM
  (`dmemcg`) ako súčasť automatického škálovania pre karty s 2–4 GB.

**17.03** (pozn.) (Optimalizácia) F. R5 — optimalizácia · r. 872–873
**R5 — optimalizácia:** pamäť — zlúčenie démonov, zatiaľ nie (r. 920); sledovanie poškodenia v kompozitore (r. 935); štart `systemd-analyze` (r. 942).

**17.04** [ ] (Optimalizácia) R5 — opakované merania · r. 1145–1146
- [ ] Opakovať merania CPU/RAM, štartu, odozvy a grafických efektov po zmenách; stanoviť limity
  pre NORMAL a SAFE a regresné porovnanie.

---

## 18. [ ] STRESTEST
Úplne posledný krok: až keď sú všetky súčasti vyvinuté a optimalizované (rozhodnuté 13. 10., potvrdené 22. 10.). Dovtedy sa testuje len práve dokončený kus. `bughunt/STRESTEST.md`, `python3 bughunt/stav.py`.
Zdroje: `bughunt/STRESTEST.md`, `bughunt/stav.py`, `bughunt/najdene-chyby.md`

**18.01** [ ] (STRESTEST) STRESTEST P1 · r. 230–235
[ ] **STRESTEST P1 — Boot a GOO** (001–045, 541–554). Strojovo overiteľné robí Claude, klikanie autor.
   **Odložené (používateľ, 13. 10.): testuje sa, až keď sú dokončené všetky prvky systému** — najprv body 4–12,
   potom sa sem vrátiť. Dovtedy sa test robí iba vtedy, keď overuje práve dokončený kus. Stav z 13. 10.: 27 z 219
   testov P1 má výsledok (zapísané v `bughunt/STRESTEST.md`); z nich na opravu: 031 (hlava BarGoo čnie ~9 px cez
   spodný okraj maximalizovaného okna), 541 (overiť prepínač jazyka a klávesnice na skutočnom prihlásení).
   *Hotovo, keď:* každý z týchto testov má stav a zlyhané majú úlohu.

**18.02** [ ] (STRESTEST) B. NVIDIA a kompatibilita · r. 642–646
- [ ] Reálny hardvér NVIDIA, širšia kompatibilita zariadení, testy čistej inštalácie a dlhodobá
  stabilita ešte nie sú uzavreté brány produktu.

**18.03** [ ] (STRESTEST) Trvalé priority — STRESTEST a optimalizácia · r. 801–806
- [ ] **STRESTEST + optimalizácia + stabilita (O, F5) = jedna dráha k 1.0:** [bughunt/STRESTEST.md](bughunt/STRESTEST.md) je
  dôležitý súbor, ktorý sa **realizuje postupne, ako sa vývoj blíži k 1.0**, spolu s optimalizáciou (najprv merať,
  potom meniť, potom znova merať) a stabilitou. Výsledky meraní a prejdené testy patria do R5.

**18.04** (pozn.) (STRESTEST) R5 — cieľ · r. 1137–1139
**Výsledok:** LatteOS je opakovateľne inštalovateľný a použiteľný v deklarovanom rozsahu.

**18.05** [ ] (STRESTEST) R5 — testovacia matica · r. 1140–1142
- [ ] Udržiavať testovaciu maticu: VM bez GPU (NORMAL aj SAFE), fyzický AMD, fyzický NVIDIA,
  viac monitorov, malé rozlíšenie, pomalší/starší hardvér, Secure Boot, odpojená sieť a slabé
  úložisko.

**18.06** [ ] (STRESTEST) R5 — funkčné testy prúdov · r. 1143–1144
- [ ] Každý pracovný prúd má funkčné testy svojho backendu a používateľské scenáre; integrované
  scenáre kontrolujú spoluprácu medzi systémom, shellom a aplikáciami.

**18.07** [ ] (STRESTEST) R5 — bughunt a ergonómia · r. 1147–1148
- [ ] Vykonať bughunt a ergonomickú skúšku s myšou aj klávesnicou; skontrolovať preklady, kontrast,
  stavové hlásenia, poškodenie/obnovu dát a aktualizáciu.

**18.08** [ ] (STRESTEST) R5 — čistá inštalácia z vydávaného stromu · r. 1149–1152
- [ ] Overiť čistú inštaláciu z presne toho stromu/obrazu, ktorý sa bude vydávať; vývojová VM
  sama osebe nie je dôkazom pripravenosti vydania.

---

## 19. [ ] Neskôr
Veľké smery po stabilnom produkte: mobilná LatteApp, prenos účtu a cloud, pokročilá bezpečnostná analytika.

**19.01** [ ] (Neskôr) D. neskôr · r. 704–707
- [ ] **Neskôr:** Fedora Atomic/bootc, rollback, prenos účtu a ďalšie veľké rozšírenia až po
  uzavretí požadovanej stability a hardvérovej matice.

**19.02** (pozn.) (Neskôr) F. R7 — neskôr · r. 874–875
**R7 — neskôr:** obraz bootc/rpm-ostree (r. 950), Nervboot (r. 714), prenosná relácia a LatteApp (r. 947), distribúcia balíkov (r. 201).

**19.03** [ ] (Neskôr) R6 — prenos účtu a cloud · r. 1176–1180
- [ ] Prenos účtu/relácie a cloudová služba sa rozvíjajú až po stabilnom lokálnom produkte;
  používateľ musí vedieť fungovať bez nich.

**19.04** [ ] (Neskôr) R7 — nervboot, LatteApp · r. 1183–1184
- [ ] Vlastný bootloader podľa nervboot, mobilná LatteApp, pokročilá bezpečnostná analytika a
  ďalšie veľké rozšírenia zostávajú návrhmi, kým neprejdú R0–R1 a nedostanú miesto v etape.

**19.05** [ ] (Neskôr) R7 — pravidlo bez GPU · r. 1185–1187
- [ ] Každé neskoršie rozšírenie zachová základné pravidlo: LatteOS musí zostať použiteľný vo VM
  bez GPU; akcelerácia pridáva efekty, nie nevyhnutnú funkčnosť.

---

## 20. [~] Archív a história
Zrušený Classic, prechod na GOO, tabuľka zložiek Arabica, kandidáti na vyčistenie, prenos zo starej roadmapy. Nie sú to úlohy.
Zdroje: `LatteOS.pdf` (prezentácia)

**20.01** (pozn.) (História a zastarané zápisy) Úvod sekcie „Teraz“ · r. 16–18
Schválené 12. 10. 2026. Pracuje sa **zhora nadol, neskáče sa**; nový nápad ide na koniec tohto zoznamu. Pri práci sa
číta iba táto sekcia, zvyšok roadmapy sa hľadá podľa prúdu (R2, R3·A…). Stav testov: `python3 bughunt/stav.py`.

**20.02** (pozn.) (História a zastarané zápisy) ROADMAP2 — úvod · r. 563–574
**Pridané 9. 10. 2026.** Pôvodná roadmapa je od 9. 10. v snímke
[docs_zaloha/2026-10-09-roadmap-pred-ciscenim.md](docs_zaloha/2026-10-09-roadmap-pred-ciscenim.md) („vyššie“ a
„pôvodné fázy“ v ďalšom texte znamenajú ju) a zachováva doterajší plán aj záznam práce. Táto časť pridáva produktovú postupnosť: LatteOS nie je iba grafické rozhranie Goo,
ale integrovaný systém nad Linuxom — od štartu a relácie cez kompozitor, shell, aplikácie a služby
po hardvérovú podporu, inštaláciu, obnovu a vydanie.

ROADMAP2 zároveň zachytáva **stav a pôvod práce pri prechode z Classicu na GOO** a skladá ho do
postupnosti až po hotový produkt. Je to pracovný podklad na porovnanie so starou roadmapou; nejde
zatiaľ o rozhodnutie, že sa staré položky majú vymazať alebo presunúť. Podrobné pôvodné znenie,
merania a históriu naďalej uchováva roadmapa vyššie; ROADMAP2 ich zhŕňa podľa súčasného produktu.

**20.03** [~] (História a zastarané zápisy) ROADMAP2 — značky pôvodu · r. 604–614
Toto je orientačný súpis k 9. 10. 2026 podľa stavu a dátumov v pôvodnej roadmap. Značky hovoria
o **pôvode a platnosti**, nie o technickom stave:

- **HISTÓRIA / CLASSIC** — vzniklo pre zrušený Classic; už sa to nevyvíja ako samostatná plocha.
- **ZÁKLAD** — vzniklo pred GOO alebo popri ňom, ale stále slúži celej LatteOS a prenáša sa.
- **GOO** — rozhodnutie alebo práca po prechode na jedinú edíciu LatteOS GOO.
- Stav práce je zvlášť označený `[x]` hotové, `[~]` čiastočne/rozpracované, `[ ]` otvorené.

**20.04** [~] (História a zastarané zápisy) A. Classic · r. 615–628
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

**20.05** [~] (História a zastarané zápisy) B. aplikácie (súhrn) · r. 637–639
- [~] **ZÁKLAD / aplikácie:** Súbory, Monitor, Správca zariadení, App Manager, Barista, záloha,
  cloud a synchronizácia majú použiteľné časti; nejde však automaticky o finálnu integráciu
  ani úplné pokrytie. Otvorené pokračovania sú rozdelené podľa produktu v časti D; zoznam zložiek je v časti E.

**20.06** (pozn.) (História a zastarané zápisy) D. úvod · r. 680–683
Toto sú hlavné zostávajúce celky, nie úplný výpis každého nezaškrtnutého políčka. Presný rozsah sa
pri porovnaní v pondelok 12. 10. potvrdí oproti pôvodnej roadmap.

**20.07** [~] (Mapa produktu (tabuľka zložiek)) E. Zložky LatteOS — tabuľka · r. 708–749
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


Prezentácia je cieľ, nie stav: čo z nej ešte neplatí, je zámer Arabicy a treba to v README oddeliť od toho, čo
systém robí dnes. Otvorené body (rozhodnuté sú `[x]`):

**20.08** [~] (História a zastarané zápisy) Kandidáti na vyčistenie · r. 788–799
Tvrdenia, ktoré už neplatia a ostávajú len ako história, na posúdenie pri porovnaní v pondelok 12. 10.:

- [ ] [LATTEOS-GOO.md](LATTEOS-GOO.md) (úvod): „verejná kópia je zastaraná, po dokončení sa zverejní 0.2“ — vydané je
  0.3.0 (6. 10.); „predvolené prihlásenie bude engine Goo, ešte sa prerobí“ — podľa §6.2 je hotové.
- [ ] Pôvodná roadmapa: položky o Classic lište a spúšťači (F3, F3·G — napr. riadky 323–336, 378), „SAFE používa Noctaliu
  s dizajnom Classic“ (riadok 336; nahradené rozhodnutím o SafeGoo, riadok 384), plocha Kvapky (`session/kvapky`).
- [ ] Číslovanie §6.2 v LATTEOS-GOO.md (8, 10, 11, 9) a hlavička „Zmena smeru“ v ROADMAP.md po zmazaní starých dát.
- [ ] Značky `[x]` pri funkciách iba pre Classic označiť `[-]` (zrušené), nie `[x]`.

**20.09** [~] (História a zastarané zápisy) F. prenos zo starej roadmapy — úvod · r. 807–817
Súpis z 9. 10. 2026: stará časť má 112 otvorených (`[ ]`, `[~]`) položiek. Prúdy R3 ich pokrývajú **všeobecne**;
tu sú konkrétne položky, ktoré by sa po zmazaní stratili (číslo = riadok v starej časti, platí do jej zmazania).
Položka je **úloha**, kým nie je označená „návrh“.

**Hotové pred zmazaním (9. 10.):** snímka starej časti je v
[docs_zaloha/2026-10-09-roadmap-pred-ciscenim.md](docs_zaloha/2026-10-09-roadmap-pred-ciscenim.md); rámec, režimy a štart
(r. 14–164) sú v [docs/NAVRH-STARTU.md](docs/NAVRH-STARTU.md); sekcia O s meraniami (r. 912–945) v
[docs/OPTIMALIZACIA.md](docs/OPTIMALIZACIA.md); obe sú odkázané z [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md). Hotové
fázy F0–F2 a merania VM sú v [docs_zaloha/](docs_zaloha/README.md), ostatné `[x]` sú história. Otvorené otázky a „Zadanie 24. 9.“
(r. 955–1015): DMS/Caelestia a COPR sú vyriešené, zvyšok je prenesený nižšie. **Starú časť maže autor sám, keď bude s ROADMAP2 spokojný.** Zmazaná 9. 10.; overené 12. 10.: číslo „r. N“ v tejto roadmape = riadok **N + 3** v snímke.

**20.10** (pozn.) (História a zastarané zápisy) F. na archiváciu · r. 876–878
**Na archiváciu (Classic alebo zrušené):** tvar L panela s lištou (r. 964); Pet Circus a maskoti (r. 974 — mazlíci sú zrušení, r. 471).
