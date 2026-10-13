# Stres test LatteOS GOO — z Jihlavanky do Arabicy

Zoznam testov, ktoré musí systém prejsť, kým sa z verzie **Jihlavanka** stane **Arabica**. Testy sa odfajkujú priamo
v tabuľkách: **stav**, **dátum · stroj** a krátky **výsledok**. Prehľad počtov vypíše `python3 bughunt/stav.py`.

Pôvodný zoznam (7. 10. 2026, 540 testov bez stavu): `docs_zaloha/2026-10-07-strestest-povodny.txt`.

## Ako zapisovať

| stav | význam |
|---|---|
| ⬜ | ešte netestované |
| ✅ | prešlo |
| ⚠️ | prešlo s výhradou (do výsledku: s akou) |
| ❌ | zlyhalo (do výsledku: čo sa stalo + odkaz na snímku alebo záznam) |
| 🔁 | opravené, treba otestovať znova |
| ⏭️ | zatiaľ sa nedá (chýba funkcia alebo hardvér — do výsledku: čo) |

- **Dátum · stroj:** napr. `7. 10. · latte-lab` alebo `7. 10. · VM latteOSdev`; pri ergonómii aj tester (`· W`).
- **Výsledok:** jedna veta, čo sa stalo; pri chybe odkaz na snímku `bughunt/NNN-popis.png` (NNN = číslo testu)
  a po oprave na commit. Ak je k testu viac poznámok, patria do `bughunt/NNN-popis.md`.
- **Opakovanie:** pri novom pokuse sa prepíše stav aj dátum; starý výsledok ostane v histórii gitu.
- **Čísla testov sa nemenia.** Nové testy dostávajú ďalšie voľné čísla aj v pôvodných kategóriách
  (označené *nové*); vyradený test ostane s ⏭️ a dôvodom.

## Priority

| | význam | pre Arabicu |
|---|---|---|
| **P1** | základ bežnej práce — bez neho sa vydať nedá | všetko ✅ alebo ⚠️ |
| **P2** | dôležité, ale chyba nezastaví bežnú prácu | ❌ iba so známou chybou v ROADMAP |
| **P3** | čaká na budúcu časť (F6 bezpečnostný model, iný hardvér) | môže ostať ⏭️ |

*Kurzívou* pri teste: na čom závisí (napr. *po fáze A*, *skutočný HW*) alebo s ktorým testom sa prekrýva
(*= 435*: vyhodnotiť spolu).

## Zmeny oproti pôvodnému zoznamu

- Pridané stĺpce priority, stavu, dátumu a výsledku; nadpis „101 testov“ nahradený skutočným počtom.
- Opravené znenie: 043 (ChatGoo je doplnok pre Beeper, nie AI), 053 (prichytávanie iba v režime plávajúce),
  082–084 (profily ovládania existujú), 337 (FPS nie je v Goo), 369, 426–427 (Bottles).
- Označené prekryvy (katastrofické 251–259 sú výsledkom malware scenárov 196–210; 426/476, 435/481, 436/468)
  a závislosti (rollback dnes cez dnf a snapper, celý obraz po fáze A; model NET vo F6, HDR a vysoké frekvencie len s takým monitorom).
- **Nové testy 541–564** pre Goo: nečinnosť a únik pamäte enginu, pravidlo 22, pás výkonu, 4 okraje, 1024 × 768,
  Win+T, režimy okien, regresie zo snímok v `bughunt/`, preklad, Bottles, herný režim.
- **Nová kategória 4 · Ergonómia (601–726):** objaviteľnosť pre človeka z Windowsu, naučené zvyky, myš,
  klávesnica, gamepad, čitateľnosť, omyly a návrat, scenáre dňa, celkové hodnotenie.

| kategória | testy |
|---|---|
| 1 · Stabilita a GOO | 001–101, 541–560, 564 |
| 2 · Bezpečnosť | 102–271 |
| 3 · Hry a Windows | 272–540, 561–563 |
| 4 · Ergonómia | 601–726 |

## 1 · Stabilita a GOO

### Boot / recovery

| # | test | P | stav | dátum · stroj | výsledok |
|---|---|---|---|---|---|
| 001 | Cold boot z úplne vypnutého PC | P1 | ⚠️ | 12. 10. · latte-lab | po oprave: prihlasovanie po 36 s (predtým 99 s), celý štart 1 min 12 s, žiadna zlyhaná služba; test grafiky stále vyprší (4,3 s) a rozhodne ovládač |
| 002 | Reboot z LatteOS do LatteOS | P1 | ⚠️ | 12. 10. · latte-lab | reštart cez `shutdown -r` prešiel čisto, bez pádu Hyprlandu, GOO nabehlo; tlačidlo Reštartovať v PowerGoo je test 036 |
| 003 | Boot po tvrdom vypnutí počas normálnej prevádzky | P1 | ⬜ | | |
| 004 | Boot po výpadku elektriny | P1 | ⬜ | | |
| 005 | Boot s poškodeným posledným session stavom | P1 | ⬜ | | |
| 006 | Boot po páde compositoru | P1 | ⚠️ | 12. 10. · latte-lab | pád Hyprlandu (ABRT) po 8 min: sám sa spustil znova v tom istom prihlásení, engine aj rohová lišta späť, počítadlo pádov po minúte 0; otvorené okná sa nevrátili |
| 007 | Boot po páde GOO shellu | P1 | ✅ | 13. 10. · latte-lab | `kill -KILL` na engine Goo za behu: `latte-goo.service` ho do 2 s spustila znova (NRestarts 1), počítadlo pádov ostalo 0, SAFE sa neprepol; SIGSEGV scéna prežila (pleamar ho zachytáva) |
| 008 | Boot po páde systémovej služby | P1 | ⬜ | | |
| 009 | Automatický výber NORMAL režimu | P1 | ✅ | 12. 10. · latte-lab | latte-boot: normal · hw · usporny (AMD gfx803, 4 GB), počítadlo pádov 0 |
| 010 | Automatický výber SAFE režimu | P1 | ⚠️ | 12. 10. · latte-lab | druhý pád Hyprlandu do 60 s → SAFE s dôvodom „Hyprland spadol po 20 s“, ponuka latte-safe; núdzové rozhranie pritom bralo ~2 jadrá (pri SAFE zvolenom na prihlásení 3 % celkom) — zistiť rozdiel |
| 011 | Ručné vynútenie SAFE režimu | P1 | ✅ | 12. 10. · latte-lab | SAFE zvolený na prihlasovacej obrazovke (LatteOS SAFE skúška): lišta s textom, hodiny, ponuka latte-safe, terminál |
| 012 | Návrat zo SAFE režimu do NORMAL | P1 | ✅ | 12. 10. · latte-lab | návrat zo SAFE (reset počítadla, odhlásenie) na prihlasovaciu obrazovku; slučka núdzového rozhrania po oprave skončila so SAFE |
| 013 | Boot s neznámym GPU | P2 | ⬜ | | |
| 014 | Boot bez použiteľnej GPU akcelerácie | P2 | ⬜ | | |
| 015 | Boot s dvoma GPU | P2 | ⬜ | | |
| 016 | Boot s odpojeným monitorom | P1 | ⬜ | | |
| 017 | Boot s viacerými monitormi | P1 | ⬜ | | |
| 018 | Boot bez siete | P1 | ⬜ | | |
| 019 | Boot s veľmi pomalou sieťou | P2 | ⬜ | | |
| 020 | Boot po neúspešnom update *(dnes: SAFE › rollback dnf a snímka Btrfs/snapper; celý obraz a automatický návrat po fáze A)* | P2 | ⬜ | | |
| 541 | Prihlasovač LatteOS: prihlásenie, zlé heslo, výber relácie, prepnutie jazyka a klávesnice *(nové)* | P1 | ⬜ | | |

### GOO / desktop

| # | test | P | stav | dátum · stroj | výsledok |
|---|---|---|---|---|---|
| 021 | GOO sa zobrazí vždy po úspešnom prihlásení | P1 | ✅ | 12. 10. · latte-lab | po reštarte engine (prvá snímka 1,4 s), kvapky aj rohová lišta nabehli samy |
| 022 | GOO sa spustí bez grafickej akcelerácie | P1 | ✅ | 12. 10. · latte-lab | núdzové rozhranie `safe.plm` na llvmpipe: lišta, pás výkonu, čas (snímka používateľa); CPU 3 % |
| 023 | GOO sa obnoví po páde | P1 | ✅ | 12. 10. · latte-lab | pred opravou engine po páde nič nevrátilo (plocha bez lišty); po oprave v `latte-kvapky` je späť do 3 s (ABRT), riadne ukončenie sa neobnovuje, najviac 5 obnov za prihlásenie |
| 024 | GooBar reaguje okamžite na myš | P1 | ⬜ | | |
| 025 | GooBar reaguje okamžite na klávesnicu | P1 | ⬜ | | |
| 026 | Goo drop možno presúvať | P1 | ⬜ | | |
| 027 | Goo drop možno meniť veľkosť | P1 | ⬜ | | |
| 028 | Goo drop sa nezasekne mimo obrazovky | P1 | ⬜ | | |
| 029 | Goo drop sa automaticky obnoví po reštarte | P1 | ⬜ | | |
| 030 | Viac dropov sa navzájom správne správa | P1 | ⬜ | | |
| 031 | GooBar nezakrýva maximalizované okná | P1 | ⬜ | | |
| 032 | GooBar nezakrýva fullscreen aplikácie | P1 | ⬜ | | |
| 033 | GooBar správne reaguje na zmenu rozlíšenia | P1 | ⬜ | | |
| 034 | GooBar správne reaguje na zmenu DPI | P1 | ⬜ | | |
| 035 | GooBar funguje na viacerých monitoroch | P1 | ⬜ | | |
| 036 | GooPower funguje v NORMAL aj SAFE režime (karta, pás výkonu, Uspať · Reštartovať · Vypnúť) | P1 | ⚠️ | 12. 10. · latte-lab | Odhlásiť z PowerGoo funguje, v SAFE lišta s vypínačom a pásom výkonu; Reštartovať · Vypnúť idú po oprave priamo cez systemd — klik ešte neoverený |
| 037 | ClockGoo zobrazuje správny čas | P1 | ⬜ | | |
| 038 | ClockGoo zvláda zmenu časového pásma | P1 | ⬜ | | |
| 039 | LensGoo vyhľadá aplikáciu | P1 | ⬜ | | |
| 040 | LensGoo vyhľadá súbor | P1 | ⬜ | | |
| 041 | LensGoo vyhľadá systémové nastavenie | P1 | ⬜ | | |
| 042 | LensGoo zvládne neexistujúci výsledok | P1 | ⬜ | | |
| 043 | ChatGoo bez nainštalovaného Beepera (kvapka sa neukáže alebo ponúkne inštaláciu; ChatGoo nie je AI) | P1 | ⬜ | | |
| 044 | GOO nastavenia prežijú reštart | P1 | ⬜ | | |
| 045 | GOO sa nezrúti pri chybe jedného dropu | P1 | ⬜ | | |
| 542 | Engine Goo v nečinnosti: CPU a RAM pod dohodnutým limitom (10 min, latte-lab) *(nové)* | P1 | ⬜ | | |
| 543 | Engine Goo 8 h bez úniku pamäte (RSS pleamaru a pomocníkov na začiatku a na konci) *(nové)* | P1 | ⬜ | | |
| 544 | Kvapky sa po zväčšení neprekrývajú (pravidlo 22: odstup 0,95 Σr, ikry 1,2) *(nové)* | P1 | ⬜ | | |
| 545 | Pás výkonu (pravý klik GooPower) odtlačí susedov a po vtiahnutí ich vráti na miesto *(nové)* | P1 | ⬜ | | |
| 546 | Kvapky na všetkých štyroch okrajoch: karty sa otvoria dovnútra, nič neujde mimo obrazovky *(nové)* | P1 | ⬜ | | |
| 547 | Rozlíšenie 1024 × 768: všetky karty sa zmestia, texty sa neorežú *(nové)* | P1 | ⬜ | | |
| 548 | Ikry GooBaru: nové okno pribudne, zavreté zmizne, strapce sa rozvinú, „Ďalšie okná“ nad 48 *(nové)* | P1 | ⬜ | | |
| 549 | Win+T: ovládanie Goo z klávesnice, režim skončí sám (klik, voľba, minúta bez klávesu) *(nové)* | P2 | ⬜ | | |
| 550 | Rohová lišta Noctalie a ovládacie centrum sa otvorí nad lištou vpravo *(nové)* | P2 | ⚠️ | 12. 10. · latte-lab | po oprave lišta nabehla sama 8 s po prihlásení; otvorenie ovládacieho centra klikom ešte neoverené |
| 551 | Regresia: artefakty z GooBaru pri zdvihnutí lišty (bughunt/bug artefakty z bargoo…png) *(nové)* | P1 | ⬜ | | |
| 552 | Regresia: bughunt/bug001.png *(nové)* | P1 | ⬜ | | |
| 553 | Prepnutie jazyka sk ↔ en: žiadny nepreložený text v Goo, kartách a aplikáciách LatteOS *(nové)* | P2 | ⬜ | | |
| 554 | AI v LensGoo bez AI backendu / v systéme bez AI: čitateľná správa, nič nevisí *(nové)* | P2 | ⬜ | | |

### Window management

| # | test | P | stav | dátum · stroj | výsledok |
|---|---|---|---|---|---|
| 046 | Otvorenie okna | P1 | ⬜ | | |
| 047 | Minimalizovanie okna | P1 | ⬜ | | |
| 048 | Maximalizovanie okna | P1 | ⬜ | | |
| 049 | Obnovenie maximalizovaného okna | P1 | ⬜ | | |
| 050 | Presúvanie okna myšou | P1 | ⬜ | | |
| 051 | Presúvanie okna klávesnicou | P1 | ⬜ | | |
| 052 | Zmena veľkosti okna | P1 | ⬜ | | |
| 053 | Windows-style snapping (režim plávajúce; zóny okien podľa režimu — pozri 564) | P1 | ⬜ | | |
| 054 | Snap na ľavú polovicu | P1 | ⬜ | | |
| 055 | Snap na pravú polovicu | P1 | ⬜ | | |
| 056 | Snap do rohov | P1 | ⬜ | | |
| 057 | Snap medzi monitormi | P1 | ⬜ | | |
| 058 | Alt+Tab / prechod medzi aplikáciami | P1 | ⬜ | | |
| 059 | Overview všetkých okien | P1 | ⬜ | | |
| 060 | Fullscreen aplikácie | P1 | ⬜ | | |
| 061 | Aplikácia bez titulkového rámu | P1 | ⬜ | | |
| 062 | CSD aplikácia | P1 | ⬜ | | |
| 063 | XWayland aplikácia | P2 | ⬜ | | |
| 064 | Wine aplikácia | P2 | ⬜ | | |
| 065 | Aplikácia s atypickým rozlíšením | P2 | ⬜ | | |
| 066 | Aplikácia s vysokým DPI | P2 | ⬜ | | |
| 067 | Viac okien jednej aplikácie | P1 | ⬜ | | |
| 068 | Okná s modal dialogom | P1 | ⬜ | | |
| 069 | Aplikácia nereaguje | P1 | ⬜ | | |
| 070 | Nútené ukončenie zaseknutej aplikácie | P1 | ⬜ | | |
| 555 | Prepnutie režimu okien páska ↔ dlaždice ↔ plávajúce za behu bez straty a skákania okien *(nové)* | P1 | ⬜ | | |
| 556 | Okná (aj maximalizované) neprekrývajú pás kvapiek pri okraji *(nové)* | P1 | ⬜ | | |
| 557 | Ukázať plochu: pravý klik na hlavu GooBaru, Win+D, Win+M, Win+Shift+M *(nové)* | P1 | ⬜ | | |
| 558 | Virtuálne plochy: Win+Ctrl+D, Win+Ctrl+← →, Win+Ctrl+F4 *(nové)* | P2 | ⬜ | | |
| 564 | Tekuté zóny okien podľa režimu (plávajúce zhora, páska šev, dlaždice zaliatie) — keď budú *(nové)* | P2 | ⬜ | | |

### Vstup / ovládanie

| # | test | P | stav | dátum · stroj | výsledok |
|---|---|---|---|---|---|
| 071 | Klávesnica funguje pri prihlasovaní | P1 | ⬜ | | |
| 072 | Klávesnica funguje po suspend/resume | P1 | ⬜ | | |
| 073 | Myš funguje po hotplug | P1 | ⬜ | | |
| 074 | USB klávesnica hotplug | P1 | ⬜ | | |
| 075 | USB myš hotplug | P1 | ⬜ | | |
| 076 | Touchpad gestá | P2 | ⬜ | | |
| 077 | Scroll | P1 | ⬜ | | |
| 078 | Pravé tlačidlo | P1 | ⬜ | | |
| 079 | Middle click | P1 | ⬜ | | |
| 080 | Klávesové skratky bez konfliktov | P1 | ⬜ | | |
| 081 | Zmena klávesových skratiek | P1 | ⬜ | | |
| 082 | Profil ovládania Windows (predvolený; `latte/skratky.lua`) | P1 | ⬜ | | |
| 083 | Profil ovládania Linux | P1 | ⬜ | | |
| 084 | Profil ovládania macOS | P2 | ⬜ | | |
| 085 | Zablokovanie jednej pokazenej skratky bez pádu shellu | P1 | ⬜ | | |

### Systém / hardware

| # | test | P | stav | dátum · stroj | výsledok |
|---|---|---|---|---|---|
| 086 | Pripojenie USB zariadenia | P1 | ⬜ | | |
| 087 | Odpojenie USB zariadenia | P1 | ⬜ | | |
| 088 | Pripojenie externého monitora | P1 | ⬜ | | |
| 089 | Odpojenie externého monitora | P1 | ⬜ | | |
| 090 | Zmena rozlíšenia za behu | P1 | ⬜ | | |
| 091 | Zmena obnovovacej frekvencie | P1 | ⬜ | | |
| 092 | Suspend | P1 | ⬜ | | |
| 093 | Resume | P1 | ⬜ | | |
| 094 | Reštart po suspend/resume *(spolu s 092–093)* | P1 | ⬜ | | |
| 095 | Wi-Fi vypnutie/zapnutie | P1 | ⬜ | | |
| 096 | Ethernet odpojenie/pripojenie | P1 | ⬜ | | |
| 097 | Bluetooth zariadenie connect/disconnect | P1 | ⬜ | | |
| 098 | Audio výstup prepnutie medzi zariadeniami | P1 | ⬜ | | |
| 099 | Mikrofón prepnutie a mute | P1 | ⬜ | | |
| 100 | Vybavenie systému po úplne čistej inštalácii | P1 | ⬜ | | |
| 559 | Telefón cez USB (MTP) sa ukáže v Súboroch a Správcovi zariadení *(nové)* | P2 | ⬜ | | |
| 560 | Tlačiareň a skener: pridanie, tlač skúšobnej strany, sken *(nové)* | P2 | ⬜ | | |

### Release test

| # | test | P | stav | dátum · stroj | výsledok |
|---|---|---|---|---|---|
| 101 | Čistá inštalácia → prvé prihlásenie → sieť → update → inštalácia aplikácie → reštart → bežná práca → hra → suspend/resume → shutdown bez jedinej manuálnej opravy | P1 | ⬜ | | |

## 2 · Bezpečnosť

### Základná izolácia

| # | test | P | stav | dátum · stroj | výsledok |
|---|---|---|---|---|---|
| 102 | Bežná aplikácia nemá automaticky root práva | P1 | ⬜ | | |
| 103 | Aplikácia nemôže zapisovať do systémových adresárov bez povolenia | P1 | ⬜ | | |
| 104 | Aplikácia nemôže meniť systémové nastavenia bez povolenia | P1 | ⬜ | | |
| 105 | Aplikácia nemôže meniť firewall bez povolenia | P2 | ⬜ | | |
| 106 | Aplikácia nemôže meniť sieťové nastavenia bez povolenia | P2 | ⬜ | | |
| 107 | Aplikácia nemôže pristupovať k heslám iných aplikácií | P2 | ⬜ | | |
| 108 | Aplikácia nemôže čítať súbory iného používateľa | P2 | ⬜ | | |
| 109 | Aplikácia nemôže zapisovať do domovského adresára iného používateľa | P2 | ⬜ | | |
| 110 | Aplikácia nemôže pristupovať k systémovým credentialom | P2 | ⬜ | | |
| 111 | Aplikácia nemôže pristupovať k SSH kľúčom bez explicitného povolenia | P2 | ⬜ | | |
| 112 | Aplikácia nemôže pristupovať k browser profilu bez povolenia | P2 | ⬜ | | |
| 113 | Aplikácia nemôže pristupovať ku cookie databázam bez povolenia | P2 | ⬜ | | |
| 114 | Aplikácia nemôže čítať clipboard bez príslušného mechanizmu | P2 | ⬜ | | |
| 115 | Aplikácia nemôže používať mikrofón bez povolenia | P1 | ⬜ | | |
| 116 | Aplikácia nemôže používať kameru bez povolenia | P1 | ⬜ | | |
| 117 | Aplikácia nemôže zachytávať obrazovku bez povolenia | P1 | ⬜ | | |
| 118 | Aplikácia nemôže sledovať klávesnicu globálne bez povolenia | P2 | ⬜ | | |
| 119 | Aplikácia nemôže manipulovať s inými oknami bez povolenia | P2 | ⬜ | | |
| 120 | Aplikácia nemôže injectovať vstup do inej aplikácie | P2 | ⬜ | | |

### Súbory a data

| # | test | P | stav | dátum · stroj | výsledok |
|---|---|---|---|---|---|
| 121 | Sandboxovaná aplikácia vidí iba povolené súbory | P3 | ⬜ | | |
| 122 | Sandboxovaná aplikácia nemôže obísť file picker | P3 | ⬜ | | |
| 123 | Aplikácia nemôže pristupovať k súboru iba zmenou jeho cesty | P3 | ⬜ | | |
| 124 | Symbolický link nesmie obísť sandbox | P3 | ⬜ | | |
| 125 | Hardlink nesmie obísť sandbox | P3 | ⬜ | | |
| 126 | Aplikácia nemôže uniknúť cez /tmp | P3 | ⬜ | | |
| 127 | Aplikácia nemôže uniknúť cez /proc | P3 | ⬜ | | |
| 128 | Aplikácia nemôže uniknúť cez /sys | P3 | ⬜ | | |
| 129 | Aplikácia nemôže uniknúť cez /dev | P3 | ⬜ | | |
| 130 | Aplikácia nemôže získať citlivé dáta cez environment variables | P3 | ⬜ | | |
| 131 | Aplikácia nemôže čítať command-line argumenty citlivých procesov | P3 | ⬜ | | |
| 132 | Aplikácia nemôže čítať pamäť iného procesu | P3 | ⬜ | | |
| 133 | Aplikácia nemôže pristupovať k DBus službám mimo povoleného rozsahu | P3 | ⬜ | | |
| 134 | Aplikácia nemôže zneužiť file descriptor iného procesu | P3 | ⬜ | | |
| 135 | Odobratie povolenia okamžite zablokuje ďalší prístup | P3 | ⬜ | | |

### Sieť

| # | test | P | stav | dátum · stroj | výsledok |
|---|---|---|---|---|---|
| 136 | Aplikácia bez sieťového povolenia nemá internet *(model NET (F6))* | P1 | ⬜ | | |
| 137 | Aplikácia s povolením iba pre jednu službu nemá prístup inde *(model NET (F6))* | P3 | ⬜ | | |
| 138 | Blokovanie siete funguje aj po reštarte aplikácie | P3 | ⬜ | | |
| 139 | Blokovanie siete funguje aj po reštarte systému | P3 | ⬜ | | |
| 140 | Aplikácia nemôže obísť NET kontrolu cez IPv6 | P3 | ⬜ | | |
| 141 | Aplikácia nemôže obísť NET kontrolu cez localhost | P3 | ⬜ | | |
| 142 | Aplikácia nemôže obísť NET kontrolu cez DNS | P3 | ⬜ | | |
| 143 | Aplikácia nemôže vytvoriť vlastné VPN spojenie bez povolenia | P3 | ⬜ | | |
| 144 | Aplikácia nemôže vytvoriť raw socket bez povolenia | P3 | ⬜ | | |
| 145 | Aplikácia nemôže meniť routing bez povolenia | P3 | ⬜ | | |
| 146 | Aplikácia nemôže meniť DNS bez povolenia | P3 | ⬜ | | |
| 147 | Latte NET správne identifikuje proces vytvárajúci spojenie *(model NET (F6))* | P3 | ⬜ | | |
| 148 | Latte NET zobrazí aktuálne outbound spojenia *(model NET (F6))* | P3 | ⬜ | | |
| 149 | Ukončenie aplikácie ukončí jej povolené spojenia | P3 | ⬜ | | |
| 150 | Zablokovanie aplikácie okamžite preruší jej sieť | P3 | ⬜ | | |
| 151 | DNS leak test | P3 | ⬜ | | |
| 152 | IPv6 leak test | P3 | ⬜ | | |
| 153 | VPN leak test | P3 | ⬜ | | |
| 154 | Sandboxovaná aplikácia nemôže použiť inú aplikáciu ako network proxy bez povolenia | P3 | ⬜ | | |
| 155 | Malicious application nemôže potichu povoliť vlastnú sieť | P3 | ⬜ | | |

### Práva a elevácia

| # | test | P | stav | dátum · stroj | výsledok |
|---|---|---|---|---|---|
| 156 | Žiadosť o administrátorské práva vyvolá správny mechanizmus | P1 | ⬜ | | |
| 157 | Bežná aplikácia nemôže predstierať systémové povolenie | P2 | ⬜ | | |
| 158 | Falošné systémové okno nedokáže získať práva | P2 | ⬜ | | |
| 159 | Aplikácia nemôže manipulovať s autentifikačným UI | P2 | ⬜ | | |
| 160 | Nesprávne heslo nezíska práva | P1 | ⬜ | | |
| 161 | Zrušenie autentifikácie operáciu zastaví | P1 | ⬜ | | |
| 162 | Timeout autentifikácie operáciu zastaví | P1 | ⬜ | | |
| 163 | Jednorazové povolenie sa po operácii skončí | P2 | ⬜ | | |
| 164 | Trvalé povolenie je viditeľné v Settings | P2 | ⬜ | | |
| 165 | Používateľ môže povolenie odobrať | P2 | ⬜ | | |
| 166 | Odobratie povolenia funguje bez reinstallácie aplikácie | P2 | ⬜ | | |
| 167 | Aplikácia nemôže sama sebe udeliť vyššie práva | P2 | ⬜ | | |
| 168 | Root proces nemôže zostať aktívny po skončení potrebnej operácie | P2 | ⬜ | | |
| 169 | Systémové služby používajú minimálne potrebné privilégiá | P2 | ⬜ | | |
| 170 | Latte služby navzájom nemajú zbytočné root oprávnenia | P2 | ⬜ | | |

### Aplikácie

| # | test | P | stav | dátum · stroj | výsledok |
|---|---|---|---|---|---|
| 171 | Inštalácia neznámej aplikácie zobrazí jej zdroj | P2 | ⬜ | | |
| 172 | Používateľ vidí požadované oprávnenia aplikácie | P2 | ⬜ | | |
| 173 | Aplikácia nemôže zmeniť svoje deklarované oprávnenia potichu | P2 | ⬜ | | |
| 174 | Aktualizácia aplikácie nemôže automaticky rozšíriť jej oprávnenia bez kontroly | P2 | ⬜ | | |
| 175 | Odstránenie aplikácie odstráni jej sandbox | P2 | ⬜ | | |
| 176 | Odstránenie aplikácie odstráni jej systémové služby | P2 | ⬜ | | |
| 177 | Odstránenie aplikácie odstráni jej autostart | P2 | ⬜ | | |
| 178 | Odstránenie aplikácie odstráni jej povolenia | P2 | ⬜ | | |
| 179 | Aplikácia spustená z neznámeho zdroja je správne označená | P2 | ⬜ | | |
| 180 | Poškodený package sa neinštaluje | P2 | ⬜ | | |
| 181 | Package s nesprávnym podpisom sa neinštaluje | P2 | ⬜ | | |
| 182 | Manipulovaný package je odmietnutý | P2 | ⬜ | | |
| 183 | Downgrade na nebezpečnú verziu je kontrolovaný | P2 | ⬜ | | |
| 184 | Aplikácia nemôže nahradiť systémový binary | P2 | ⬜ | | |
| 185 | Aplikácia nemôže prepisovať LatteOS komponenty | P2 | ⬜ | | |

### Procesy

| # | test | P | stav | dátum · stroj | výsledok |
|---|---|---|---|---|---|
| 186 | Proces nemôže jednoducho uniknúť zo sandboxu | P3 | ⬜ | | |
| 187 | Proces nemôže vytvoriť privilegovaný child proces | P3 | ⬜ | | |
| 188 | Proces nemôže meniť UID/GID podľa vlastnej potreby | P3 | ⬜ | | |
| 189 | Proces nemôže meniť capabilities bez oprávnenia | P3 | ⬜ | | |
| 190 | Proces nemôže pristupovať k cudzím procesom | P3 | ⬜ | | |
| 191 | Proces nemôže ukončiť kritický systémový proces | P3 | ⬜ | | |
| 192 | Proces nemôže vypnúť bezpečnostnú službu | P3 | ⬜ | | |
| 193 | Proces nemôže manipulovať s audit logom | P3 | ⬜ | | |
| 194 | Proces nemôže odstrániť vlastné bezpečnostné záznamy | P3 | ⬜ | | |
| 195 | Fork bomb nezrúti celý systém | P3 | ⬜ | | |

### Malware scenáre

| # | test | P | stav | dátum · stroj | výsledok |
|---|---|---|---|---|---|
| 196 | Aplikácia sa pokúsi čítať SSH private key | P3 | ⬜ | | |
| 197 | Aplikácia sa pokúsi čítať browser passwords | P3 | ⬜ | | |
| 198 | Aplikácia sa pokúsi čítať browser cookies | P3 | ⬜ | | |
| 199 | Aplikácia sa pokúsi odoslať domovský adresár na internet | P3 | ⬜ | | |
| 200 | Aplikácia sa pokúsi zapnúť mikrofón na pozadí | P3 | ⬜ | | |
| 201 | Aplikácia sa pokúsi zapnúť kameru na pozadí | P3 | ⬜ | | |
| 202 | Aplikácia sa pokúsi zachytiť obrazovku | P3 | ⬜ | | |
| 203 | Aplikácia sa pokúsi sledovať stlačenia kláves | P3 | ⬜ | | |
| 204 | Aplikácia sa pokúsi vytvoriť skrytý autostart | P3 | ⬜ | | |
| 205 | Aplikácia sa pokúsi vytvoriť skrytú systemd službu | P3 | ⬜ | | |
| 206 | Aplikácia sa pokúsi získať root cez nesprávne nastavené práva | P3 | ⬜ | | |
| 207 | Aplikácia sa pokúsi zapisovať mimo sandboxu | P3 | ⬜ | | |
| 208 | Aplikácia sa pokúsi použiť symlink escape | P3 | ⬜ | | |
| 209 | Aplikácia sa pokúsi použiť /proc na získanie citlivých údajov | P3 | ⬜ | | |
| 210 | Aplikácia sa pokúsi obísť sieťové pravidlá | P3 | ⬜ | | |

### GUI security

| # | test | P | stav | dátum · stroj | výsledok |
|---|---|---|---|---|---|
| 211 | Používateľ vždy vie, ktorá aplikácia žiada povolenie | P2 | ⬜ | | |
| 212 | Systémové dialógy nemožno zameniť za dialóg aplikácie | P2 | ⬜ | | |
| 213 | Aplikácia nemôže vytvoriť falošné GOO systémové okno | P2 | ⬜ | | |
| 214 | Aplikácia nemôže vizuálne predstierať systémové oprávnenie | P2 | ⬜ | | |
| 215 | Kritické povolenia majú jasný popis následkov | P2 | ⬜ | | |
| 216 | Zamietnutie povolenia neblokuje celý desktop | P2 | ⬜ | | |
| 217 | Opakované odmietnutie nespôsobuje nekonečný cyklus | P2 | ⬜ | | |
| 218 | Používateľ môže spätne skontrolovať všetky povolenia | P2 | ⬜ | | |
| 219 | Používateľ môže spätne odobrať všetky povolenia | P2 | ⬜ | | |
| 220 | Bezpečnostné upozornenia nie sú spamované pri každom štarte aplikácie | P2 | ⬜ | | |

### Update / supply chain

| # | test | P | stav | dátum · stroj | výsledok |
|---|---|---|---|---|---|
| 221 | Systém overí podpis aktualizácie | P1 | ⬜ | | |
| 222 | Poškodený update sa neinštaluje | P1 | ⬜ | | |
| 223 | Prerušený update nenechá systém nebootovateľný | P2 | ⬜ | | |
| 224 | Update môže byť rollbacknutý *(dnes: SAFE › rollback dnf a snímka Btrfs/snapper; celý obraz a automatický návrat po fáze A)* | P2 | ⬜ | | |
| 225 | Rollback zachová používateľské dáta *(dnes: SAFE › rollback dnf a snímka Btrfs/snapper; celý obraz a automatický návrat po fáze A)* | P2 | ⬜ | | |
| 226 | Rollback zachová funkčné nastavenia *(dnes: SAFE › rollback dnf a snímka Btrfs/snapper; celý obraz a automatický návrat po fáze A)* | P2 | ⬜ | | |
| 227 | Rollback odstráni chybný systémový komponent *(dnes: SAFE › rollback dnf a snímka Btrfs/snapper; celý obraz a automatický návrat po fáze A)* | P2 | ⬜ | | |
| 228 | Systém vie zistiť verziu nainštalovaných komponentov | P2 | ⬜ | | |
| 229 | Systém vie zistiť pôvod nainštalovaného komponentu | P2 | ⬜ | | |
| 230 | Neautorizovaný repozitár nemožno pridať bez explicitného potvrdenia | P2 | ⬜ | | |

### Boot / system integrity

| # | test | P | stav | dátum · stroj | výsledok |
|---|---|---|---|---|---|
| 231 | Secure Boot funguje *(skutočný HW)* | P3 | ⬜ | | |
| 232 | Systém správne reaguje na Secure Boot failure *(skutočný HW)* | P3 | ⬜ | | |
| 233 | Nepodpísaný boot komponent je odmietnutý *(skutočný HW)* | P3 | ⬜ | | |
| 234 | Manipulovaný kernel je odmietnutý *(skutočný HW)* | P3 | ⬜ | | |
| 235 | Manipulovaný initramfs je detegovaný | P3 | ⬜ | | |
| 236 | Manipulovaný boot configuration je detegovaný | P3 | ⬜ | | |
| 237 | Recovery režim neobíde bezpečnostný model bez fyzického prístupu | P3 | ⬜ | | |
| 238 | SAFE režim neudeľuje aplikáciám viac práv než NORMAL | P3 | ⬜ | | |
| 239 | Crash recovery neotvorí privilegovaný shell používateľovi | P3 | ⬜ | | |
| 240 | Boot log neobsahuje citlivé údaje | P3 | ⬜ | | |

### Používateľ / privacy

| # | test | P | stav | dátum · stroj | výsledok |
|---|---|---|---|---|---|
| 241 | Heslo sa nezobrazuje v logoch | P1 | ⬜ | | |
| 242 | Token sa nezobrazuje v logoch | P1 | ⬜ | | |
| 243 | API key sa nezobrazuje v logoch | P1 | ⬜ | | |
| 244 | Network credentials sa nezobrazujú v logoch | P2 | ⬜ | | |
| 245 | Clipboard citlivé dáta sa zbytočne neukladajú | P2 | ⬜ | | |
| 246 | Screenshoty bezpečnostných dialógov neobsahujú tajné údaje | P2 | ⬜ | | |
| 247 | Telemetria je vypnutá alebo transparentne deklarovaná | P2 | ⬜ | | |
| 248 | Používateľ vie, aké dáta systém odosiela | P2 | ⬜ | | |
| 249 | LatteOS funguje bez online účtu | P1 | ⬜ | | |
| 250 | Odpojený internet nezníži lokálnu bezpečnosť systému | P2 | ⬜ | | |

### Katastrofické testy

| # | test | P | stav | dátum · stroj | výsledok |
|---|---|---|---|---|---|
| 251 | Úmyselne škodlivá aplikácia nemá root *(výsledok sád 196–210)* | P3 | ⬜ | | |
| 252 | Škodlivá aplikácia nemá prístup k osobným súborom *(výsledok 199)* | P3 | ⬜ | | |
| 253 | Škodlivá aplikácia nemá prístup k heslám *(výsledok 197)* | P3 | ⬜ | | |
| 254 | Škodlivá aplikácia nemá prístup ku kľúčom *(výsledok 196)* | P3 | ⬜ | | |
| 255 | Škodlivá aplikácia nemá prístup ku kamere *(výsledok 201)* | P3 | ⬜ | | |
| 256 | Škodlivá aplikácia nemá prístup k mikrofónu *(výsledok 200)* | P3 | ⬜ | | |
| 257 | Škodlivá aplikácia nemá prístup k obrazovke *(výsledok 202)* | P3 | ⬜ | | |
| 258 | Škodlivá aplikácia nemá voľný internet *(výsledok 210)* | P3 | ⬜ | | |
| 259 | Škodlivá aplikácia nedokáže vytvoriť persistentný autostart *(výsledok 204–205)* | P3 | ⬜ | | |
| 260 | Škodlivá aplikácia nedokáže vypnúť Latte security služby | P3 | ⬜ | | |
| 261 | Po kompromitácii jednej aplikácie zostane zvyšok desktopu izolovaný | P3 | ⬜ | | |
| 262 | Po páde bezpečnostnej služby systém prejde do bezpečného stavu | P3 | ⬜ | | |
| 263 | Po páde NET služby aplikácie automaticky nezískajú unrestricted network access | P3 | ⬜ | | |
| 264 | Po páde App Managera zostane systém použiteľný | P3 | ⬜ | | |
| 265 | Po páde Device Managera zostane systém použiteľný | P3 | ⬜ | | |
| 266 | Po páde GOO zostane možné bezpečne obnoviť session | P3 | ⬜ | | |
| 267 | Po kompromitácii GOO nemožno automaticky získať root | P3 | ⬜ | | |
| 268 | Po kompromitácii bežného používateľa nemožno automaticky získať root | P3 | ⬜ | | |
| 269 | Po reštarte sa bezpečnostné politiky obnovia | P3 | ⬜ | | |
| 270 | Po kompletnom obnovení zo zálohy zostane bezpečnostný model funkčný | P3 | ⬜ | | |

### Finálny security test

| # | test | P | stav | dátum · stroj | výsledok |
|---|---|---|---|---|---|
| 271 | Nainštalovať neznámu aplikáciu → spustiť ju → pokúsiť sa o prístup k súborom → heslám → SSH kľúčom → kamere → mikrofónu → obrazovke → sieti → root právam → persistence → system files a overiť, že LatteOS každý pokus správne zablokuje alebo explicitne autorizuje používateľom. | P3 | ⬜ | | |

## 3 · Hry a Windows

### Gaming základ

| # | test | P | stav | dátum · stroj | výsledok |
|---|---|---|---|---|---|
| 272 | Steam sa nainštaluje cez App Manager | P1 | ⬜ | | |
| 273 | Steam sa spustí bez manuálneho zásahu v termináli | P1 | ⬜ | | |
| 274 | Steam vie aktualizovať sám seba | P1 | ⬜ | | |
| 275 | Steam Library sa správne zobrazí | P1 | ⬜ | | |
| 276 | Hra sa nainštaluje do predvoleného umiestnenia | P1 | ⬜ | | |
| 277 | Hra sa nainštaluje na druhý disk | P1 | ⬜ | | |
| 278 | Hra sa odinštaluje | P1 | ⬜ | | |
| 279 | Hra sa znovu nainštaluje | P1 | ⬜ | | |
| 280 | Hra sa aktualizuje | P1 | ⬜ | | |
| 281 | Hra sa spustí cez launcher | P1 | ⬜ | | |
| 282 | Hra sa spustí priamo z desktopu | P1 | ⬜ | | |
| 283 | Hra sa korektne ukončí | P1 | ⬜ | | |
| 284 | Pád hry nezhodí desktop | P1 | ⬜ | | |
| 285 | Pád hry nezhodí GOO | P1 | ⬜ | | |
| 286 | Pád hry nezhodí compositor | P1 | ⬜ | | |
| 287 | Hra beží bez terminálu | P1 | ⬜ | | |
| 288 | Hra funguje bez manuálneho nastavovania Wine/Proton | P1 | ⬜ | | |
| 289 | Používateľ vie zistiť, prečo sa hra nespustila | P1 | ⬜ | | |
| 290 | App Manager vie zobraziť kompatibilitu hry | P1 | ⬜ | | |
| 562 | Herný režim Win+Shift+G (Steam Big Picture v gamescope) a návrat na plochu *(nové)* | P1 | ⬜ | | |
| 563 | Herňa Win+G: zoznam hier, spustenie, ukončenie *(nové)* | P2 | ⬜ | | |

### Proton

| # | test | P | stav | dátum · stroj | výsledok |
|---|---|---|---|---|---|
| 291 | Steam Proton sa automaticky nainštaluje | P2 | ⬜ | | |
| 292 | Proton Experimental funguje | P2 | ⬜ | | |
| 293 | Stabilná verzia Proton funguje | P2 | ⬜ | | |
| 294 | Používateľ môže zmeniť Proton verziu | P2 | ⬜ | | |
| 295 | Používateľ môže nastaviť Proton pre konkrétnu hru | P2 | ⬜ | | |
| 296 | Používateľ môže obnoviť automatickú voľbu Protonu | P2 | ⬜ | | |
| 297 | Proton prefix sa vytvorí automaticky | P2 | ⬜ | | |
| 298 | Proton prefix sa nepoškodí po update systému | P2 | ⬜ | | |
| 299 | Hra používa správny prefix | P2 | ⬜ | | |
| 300 | Hra dokáže vytvoriť nový prefix | P2 | ⬜ | | |
| 301 | Poškodený prefix nespôsobí pád systému | P2 | ⬜ | | |
| 302 | Hra môže byť spustená v čistom prefixe | P2 | ⬜ | | |
| 303 | DXVK funguje | P2 | ⬜ | | |
| 304 | VKD3D-Proton funguje | P2 | ⬜ | | |
| 305 | OpenGL cez Proton funguje | P2 | ⬜ | | |
| 306 | DirectX 9 hra funguje | P2 | ⬜ | | |
| 307 | DirectX 10 hra funguje | P2 | ⬜ | | |
| 308 | DirectX 11 hra funguje | P2 | ⬜ | | |
| 309 | DirectX 12 hra funguje | P2 | ⬜ | | |
| 310 | Vulkan hra funguje | P2 | ⬜ | | |
| 311 | 32-bit Windows hra funguje | P2 | ⬜ | | |
| 312 | 64-bit Windows hra funguje | P2 | ⬜ | | |
| 313 | Hra s vlastným launcherom funguje | P2 | ⬜ | | |
| 314 | Hra s externým updaterom funguje | P2 | ⬜ | | |
| 315 | Hra s DLC funguje | P2 | ⬜ | | |

### GPU

| # | test | P | stav | dátum · stroj | výsledok |
|---|---|---|---|---|---|
| 316 | AMD GPU funguje | P1 | ⬜ | | |
| 317 | NVIDIA GPU funguje *(skutočný HW s NVIDIA)* | P3 | ⬜ | | |
| 318 | Intel GPU funguje *(skutočný HW s Intel)* | P3 | ⬜ | | |
| 319 | Integrovaná GPU funguje | P2 | ⬜ | | |
| 320 | Dedikovaná GPU funguje | P2 | ⬜ | | |
| 321 | Hybridná grafika funguje *(notebook)* | P3 | ⬜ | | |
| 322 | Hra používa správnu GPU | P2 | ⬜ | | |
| 323 | Prepnutie GPU funguje | P2 | ⬜ | | |
| 324 | GPU driver update nerozbije Steam | P2 | ⬜ | | |
| 325 | GPU driver update nerozbije Proton | P2 | ⬜ | | |
| 326 | Vulkan funguje | P1 | ⬜ | | |
| 327 | Vulkan device je správne identifikované | P2 | ⬜ | | |
| 328 | OpenGL funguje | P2 | ⬜ | | |
| 329 | Shader compilation funguje | P2 | ⬜ | | |
| 330 | Shader cache funguje | P2 | ⬜ | | |
| 331 | Shader cache prežije reštart | P2 | ⬜ | | |
| 332 | Shader cache sa dá vymazať | P2 | ⬜ | | |
| 333 | Chýbajúci Vulkan driver je správne diagnostikovaný | P2 | ⬜ | | |
| 334 | Chýbajúci 32-bit driver je správne diagnostikovaný | P2 | ⬜ | | |
| 335 | GPU chyba nespôsobí nekonečný crash loop | P2 | ⬜ | | |

### Výkon

| # | test | P | stav | dátum · stroj | výsledok |
|---|---|---|---|---|---|
| 336 | Hra dosahuje očakávaný výkon | P2 | ⬜ | | |
| 337 | FPS counter v hre (MangoHud / prekrytie Steamu; v páse výkonu Goo FPS zámerne nie je) | P2 | ⬜ | | |
| 338 | Frame pacing je stabilný | P2 | ⬜ | | |
| 339 | VSync funguje | P2 | ⬜ | | |
| 340 | VRR funguje | P2 | ⬜ | | |
| 341 | 60 Hz funguje | P2 | ⬜ | | |
| 342 | 120 Hz funguje *(monitor s danou frekvenciou)* | P2 | ⬜ | | |
| 343 | 144 Hz funguje *(monitor s danou frekvenciou)* | P3 | ⬜ | | |
| 344 | 165 Hz funguje *(monitor s danou frekvenciou)* | P3 | ⬜ | | |
| 345 | 240 Hz funguje *(monitor s danou frekvenciou)* | P3 | ⬜ | | |
| 346 | Zmena refresh rate počas hrania funguje | P2 | ⬜ | | |
| 347 | Game Mode funguje | P2 | ⬜ | | |
| 348 | Game Mode neobmedzí systémové procesy potrebné pre hru | P2 | ⬜ | | |
| 349 | Game Mode sa po ukončení hry vypne | P2 | ⬜ | | |
| 350 | Game Mode prežije pád hry | P2 | ⬜ | | |
| 351 | CPU governor/power profile sa správne prepne | P2 | ⬜ | | |
| 352 | GPU power profile sa správne prepne | P2 | ⬜ | | |
| 353 | Notebook power mode funguje | P2 | ⬜ | | |
| 354 | Hra nebeží omylom na CPU renderer | P2 | ⬜ | | |
| 355 | Hra nebeží omylom na nesprávnej GPU | P2 | ⬜ | | |

### Display / fullscreen

| # | test | P | stav | dátum · stroj | výsledok |
|---|---|---|---|---|---|
| 356 | Exclusive fullscreen funguje | P1 | ⬜ | | |
| 357 | Borderless fullscreen funguje | P1 | ⬜ | | |
| 358 | Windowed mode funguje | P2 | ⬜ | | |
| 359 | Prepínanie fullscreen/windowed funguje | P2 | ⬜ | | |
| 360 | Alt+Tab z fullscreen hry funguje | P1 | ⬜ | | |
| 361 | Hra sa po Alt+Tab vráti správne | P1 | ⬜ | | |
| 362 | Zmena rozlíšenia hry funguje | P2 | ⬜ | | |
| 363 | Hra s natívnym rozlíšením funguje | P2 | ⬜ | | |
| 364 | Hra s nenatívnym rozlíšením funguje | P2 | ⬜ | | |
| 365 | Ultrawide rozlíšenie funguje | P2 | ⬜ | | |
| 366 | Viac monitorov funguje | P2 | ⬜ | | |
| 367 | Hra sa otvorí na správnom monitore | P2 | ⬜ | | |
| 368 | Presunutie hry na druhý monitor funguje | P2 | ⬜ | | |
| 369 | GOO sa počas fullscreen hry neukazuje a nezaťažuje (engine potlačený) | P2 | ⬜ | | |
| 370 | Overlay sa dá bezpečne aktivovať | P2 | ⬜ | | |
| 371 | HDR funguje *(HDR monitor)* | P3 | ⬜ | | |
| 372 | SDR hra na HDR desktopoch funguje *(HDR monitor)* | P3 | ⬜ | | |
| 373 | HDR hra na HDR displeji funguje *(HDR monitor)* | P3 | ⬜ | | |
| 374 | VRR + fullscreen funguje | P2 | ⬜ | | |
| 375 | VRR + borderless funguje | P2 | ⬜ | | |

### Input

| # | test | P | stav | dátum · stroj | výsledok |
|---|---|---|---|---|---|
| 376 | USB gamepad funguje | P1 | ⬜ | | |
| 377 | Bluetooth gamepad funguje | P2 | ⬜ | | |
| 378 | Xbox controller funguje | P2 | ⬜ | | |
| 379 | PlayStation controller funguje | P2 | ⬜ | | |
| 380 | Generic XInput controller funguje | P2 | ⬜ | | |
| 381 | Controller hotplug funguje | P2 | ⬜ | | |
| 382 | Controller disconnect počas hry nespôsobí pád desktopu | P2 | ⬜ | | |
| 383 | Controller reconnect funguje | P2 | ⬜ | | |
| 384 | Steam Input funguje | P1 | ⬜ | | |
| 385 | Hra bez Steam Input funguje | P2 | ⬜ | | |
| 386 | Rumble funguje | P2 | ⬜ | | |
| 387 | Analógové páčky fungujú | P2 | ⬜ | | |
| 388 | Trigger input funguje | P2 | ⬜ | | |
| 389 | Keyboard + mouse fungujú | P2 | ⬜ | | |
| 390 | Prepnutie medzi controllerom a klávesnicou funguje | P2 | ⬜ | | |

### Audio

| # | test | P | stav | dátum · stroj | výsledok |
|---|---|---|---|---|---|
| 391 | Herný audio výstup funguje | P1 | ⬜ | | |
| 392 | Herný mikrofón funguje | P2 | ⬜ | | |
| 393 | Prepnutie audio zariadenia počas hry funguje | P2 | ⬜ | | |
| 394 | USB headset funguje | P2 | ⬜ | | |
| 395 | Bluetooth headset funguje | P2 | ⬜ | | |
| 396 | HDMI audio funguje | P2 | ⬜ | | |
| 397 | Game audio funguje po suspend/resume | P2 | ⬜ | | |
| 398 | Mikrofón funguje po suspend/resume | P2 | ⬜ | | |
| 399 | Hra nezablokuje systémové audio | P2 | ⬜ | | |
| 400 | Zmena hlasitosti cez GOO funguje počas hry | P1 | ⬜ | | |

### Anti-cheat

| # | test | P | stav | dátum · stroj | výsledok |
|---|---|---|---|---|---|
| 401 | Hra bez anti-cheatu funguje | P3 | ⬜ | | |
| 402 | Hra s Easy Anti-Cheat funguje | P3 | ⬜ | | |
| 403 | Hra s BattlEye funguje | P3 | ⬜ | | |
| 404 | Anti-cheat funguje v podporovanom Proton režime | P3 | ⬜ | | |
| 405 | Anti-cheat failure je jasne oznámený | P3 | ⬜ | | |
| 406 | LatteOS nepredstiera podporu nefungujúceho anti-cheatu | P3 | ⬜ | | |
| 407 | Anti-cheat nemôže vypnúť Latte security model | P3 | ⬜ | | |
| 408 | Anti-cheat nemá automaticky root práva | P3 | ⬜ | | |
| 409 | Anti-cheat nemôže čítať ľubovoľné používateľské dáta | P3 | ⬜ | | |
| 410 | Anti-cheat problém je oddelený od problému desktopu | P3 | ⬜ | | |

### Launchery

| # | test | P | stav | dátum · stroj | výsledok |
|---|---|---|---|---|---|
| 411 | Steam launcher funguje | P3 | ⬜ | | |
| 412 | Epic Games launcher funguje | P3 | ⬜ | | |
| 413 | GOG launcher funguje | P3 | ⬜ | | |
| 414 | Ubisoft Connect funguje | P3 | ⬜ | | |
| 415 | EA launcher funguje | P3 | ⬜ | | |
| 416 | Battle.net funguje | P3 | ⬜ | | |
| 417 | Rockstar launcher funguje | P3 | ⬜ | | |
| 418 | Microsoft launcher funguje tam, kde je kompatibilný | P3 | ⬜ | | |
| 419 | Heroic Games Launcher funguje | P3 | ⬜ | | |
| 420 | Lutris funguje | P3 | ⬜ | | |
| 421 | Non-Steam hra sa dá pridať do Steam | P3 | ⬜ | | |
| 422 | Windows launcher sa dá nainštalovať do Wine prefixu | P3 | ⬜ | | |
| 423 | Launcher a hra používajú správny prefix | P3 | ⬜ | | |
| 424 | Launcher update nerozbije hru | P3 | ⬜ | | |
| 425 | Hra spustená cez launcher sa správne zobrazí v Game Mode | P3 | ⬜ | | |

### Windows aplikácie

| # | test | P | stav | dátum · stroj | výsledok |
|---|---|---|---|---|---|
| 426 | Windows .exe sa dá otvoriť zo Súborov (ponúkne Bottles) | P2 | ⬜ | | |
| 427 | Súbory správne ponúknu kompatibilnú aplikáciu | P2 | ⬜ | | |
| 428 | Používateľ nemusí poznať Wine command | P2 | ⬜ | | |
| 429 | Windows aplikácia sa nainštaluje cez GUI | P2 | ⬜ | | |
| 430 | Windows aplikácia sa odinštaluje cez GUI | P2 | ⬜ | | |
| 431 | Windows aplikácia vytvorí desktop shortcut | P2 | ⬜ | | |
| 432 | Windows aplikácia vytvorí menu entry | P2 | ⬜ | | |
| 433 | Windows aplikácia nastaví file associations | P2 | ⬜ | | |
| 434 | Windows aplikácia môže otvoriť dokument dvojklikom | P2 | ⬜ | | |
| 435 | Windows aplikácia môže otvoriť URL *(= 481)* | P2 | ⬜ | | |
| 436 | Windows aplikácia môže používať clipboard | P2 | ⬜ | | |
| 437 | Windows aplikácia môže používať zvuk | P2 | ⬜ | | |
| 438 | Windows aplikácia môže používať mikrofón | P2 | ⬜ | | |
| 439 | Windows aplikácia môže používať kameru po povolení | P2 | ⬜ | | |
| 440 | Windows aplikácia môže používať USB zariadenie po povolení | P2 | ⬜ | | |
| 561 | Bottles: .exe z webu → ponuka Bottles → inštalácia → ikra a spúšťač bez terminálu *(nové)* | P2 | ⬜ | | |

### Wine

| # | test | P | stav | dátum · stroj | výsledok |
|---|---|---|---|---|---|
| 441 | Wine prefix sa vytvorí automaticky | P3 | ⬜ | | |
| 442 | Wine prefix má správne architektúry | P3 | ⬜ | | |
| 443 | Wine aplikácia dostane správne Windows environment variables | P3 | ⬜ | | |
| 444 | Wine aplikácia nevidí systémové súbory mimo povoleného priestoru | P3 | ⬜ | | |
| 445 | Wine aplikácia nemá automatický root | P3 | ⬜ | | |
| 446 | Wine aplikácia má sieť iba podľa svojho security profilu | P3 | ⬜ | | |
| 447 | Wine aplikácia môže byť sandboxovaná | P3 | ⬜ | | |
| 448 | Wine aplikácia môže používať GPU | P3 | ⬜ | | |
| 449 | Wine aplikácia môže používať Vulkan | P3 | ⬜ | | |
| 450 | Wine aplikácia môže používať DXVK | P3 | ⬜ | | |
| 451 | Wine aplikácia môže používať VKD3D | P3 | ⬜ | | |
| 452 | Wine aplikácia môže používať DirectInput | P3 | ⬜ | | |
| 453 | Wine aplikácia môže používať XInput | P3 | ⬜ | | |
| 454 | Wine aplikácia môže používať Windows fonts | P3 | ⬜ | | |
| 455 | Wine aplikácia zvládne Windows installer | P3 | ⬜ | | |
| 456 | Wine aplikácia zvládne MSI installer | P3 | ⬜ | | |
| 457 | Wine aplikácia zvládne aktualizáciu | P3 | ⬜ | | |
| 458 | Wine aplikácia sa dá bezpečne odstrániť | P3 | ⬜ | | |
| 459 | Wine prefix sa dá resetovať | P3 | ⬜ | | |
| 460 | Poškodený Wine prefix neovplyvní ostatné aplikácie | P3 | ⬜ | | |

### Windows GUI

| # | test | P | stav | dátum · stroj | výsledok |
|---|---|---|---|---|---|
| 461 | Windows aplikácia má správne DPI | P3 | ⬜ | | |
| 462 | Windows aplikácia má správne fonty | P3 | ⬜ | | |
| 463 | Windows aplikácia má správne menu | P3 | ⬜ | | |
| 464 | Windows aplikácia má správne dialogy | P3 | ⬜ | | |
| 465 | Windows aplikácia má správne context menu | P3 | ⬜ | | |
| 466 | Windows aplikácia správne reaguje na Alt+F4 | P3 | ⬜ | | |
| 467 | Windows aplikácia správne reaguje na Win kláves | P3 | ⬜ | | |
| 468 | Windows aplikácia správne používa clipboard *(= 436)* | P3 | ⬜ | | |
| 469 | Windows aplikácia správne používa drag & drop | P3 | ⬜ | | |
| 470 | Windows aplikácia správne používa file picker | P3 | ⬜ | | |
| 471 | Windows aplikácia správne používa Open/Save dialog | P3 | ⬜ | | |
| 472 | Windows aplikácia funguje na viacerých monitoroch | P3 | ⬜ | | |
| 473 | Windows aplikácia funguje pri zmene DPI | P3 | ⬜ | | |
| 474 | Windows aplikácia funguje po suspend/resume | P3 | ⬜ | | |
| 475 | Windows aplikácia funguje po zmene audio zariadenia | P3 | ⬜ | | |

### Windows files / integration

| # | test | P | stav | dátum · stroj | výsledok |
|---|---|---|---|---|---|
| 476 | .exe asociácia funguje *(= 426)* | P3 | ⬜ | | |
| 477 | .msi asociácia funguje | P3 | ⬜ | | |
| 478 | Windows aplikácia vie otvoriť PDF | P3 | ⬜ | | |
| 479 | Windows aplikácia vie otvoriť obrázok | P3 | ⬜ | | |
| 480 | Windows aplikácia vie otvoriť textový súbor | P3 | ⬜ | | |
| 481 | Windows aplikácia vie otvoriť URL *(= 435)* | P3 | ⬜ | | |
| 482 | Linux aplikácia vie otvoriť súbor vytvorený Windows aplikáciou | P3 | ⬜ | | |
| 483 | Windows aplikácia vie otvoriť súbor vytvorený Linux aplikáciou | P3 | ⬜ | | |
| 484 | Drag & drop medzi Linux a Wine aplikáciou funguje | P3 | ⬜ | | |
| 485 | Clipboard medzi Linux a Wine aplikáciou funguje | P3 | ⬜ | | |
| 486 | Copy/paste textu funguje *(spolu s 485)* | P3 | ⬜ | | |
| 487 | Copy/paste obrázku funguje | P3 | ⬜ | | |
| 488 | Copy/paste súboru funguje | P3 | ⬜ | | |

### Performance / stability

| # | test | P | stav | dátum · stroj | výsledok |
|---|---|---|---|---|---|
| 489 | 1 hodina hrania bez pádu | P1 | ⬜ | | |
| 490 | 4 hodiny hrania bez pádu | P2 | ⬜ | | |
| 491 | 8 hodín hrania bez pádu | P2 | ⬜ | | |
| 492 | 8 hodín Steam klienta bez memory leak problémov | P2 | ⬜ | | |
| 493 | 8 hodín GOO + Steam bez memory leak problémov | P2 | ⬜ | | |
| 494 | 8 hodín Wine aplikácie bez memory leak problémov | P2 | ⬜ | | |
| 495 | Opakované spustenie/ukončenie hry 50× | P2 | ⬜ | | |
| 496 | Opakované spustenie/ukončenie Windows aplikácie 50× | P2 | ⬜ | | |
| 497 | Opakovaný Alt+Tab 100× | P2 | ⬜ | | |
| 498 | Opakovaný fullscreen/windowed 100× | P2 | ⬜ | | |
| 499 | Opakované pripojenie/odpojenie controlleru | P2 | ⬜ | | |
| 500 | Opakované pripojenie/odpojenie headsetu | P2 | ⬜ | | |

### Recovery

| # | test | P | stav | dátum · stroj | výsledok |
|---|---|---|---|---|---|
| 501 | Pád hry obnoví desktop | P1 | ⬜ | | |
| 502 | Pád launcheru nezhodí Steam | P2 | ⬜ | | |
| 503 | Pád Wine procesu nezostane visieť na pozadí | P2 | ⬜ | | |
| 504 | Zaseknutý Wine proces možno ukončiť cez GUI | P2 | ⬜ | | |
| 505 | Zaseknutú hru možno ukončiť cez GOO | P1 | ⬜ | | |
| 506 | Game Mode sa po páde hry vypne | P2 | ⬜ | | |
| 507 | GPU reset nezničí session, ak driver umožní recovery | P2 | ⬜ | | |
| 508 | Po reštarte zostane knižnica hier neporušená | P2 | ⬜ | | |
| 509 | Po páde systému sa Proton prefix nepoškodí | P2 | ⬜ | | |
| 510 | Po páde systému sa Wine prefix nepoškodí | P2 | ⬜ | | |

### Update / compatibility

| # | test | P | stav | dátum · stroj | výsledok |
|---|---|---|---|---|---|
| 511 | Update LatteOS neporuší Steam | P2 | ⬜ | | |
| 512 | Update LatteOS neporuší Proton | P2 | ⬜ | | |
| 513 | Update GPU drivera neporuší Proton | P2 | ⬜ | | |
| 514 | Update Wine runtime neporuší existujúce prefixy | P2 | ⬜ | | |
| 515 | Update Mesa neporuší Vulkan hry | P2 | ⬜ | | |
| 516 | Update kernelu neporuší ovládač GPU | P2 | ⬜ | | |
| 517 | Rollback systému obnoví funkčný gaming stack *(dnes: SAFE › rollback dnf a snímka Btrfs/snapper; celý obraz a automatický návrat po fáze A)* | P2 | ⬜ | | |
| 518 | Staršia hra funguje po update systému | P2 | ⬜ | | |
| 519 | Novšia hra funguje po update systému | P2 | ⬜ | | |
| 520 | App Manager správne upozorní na známu regresiu | P2 | ⬜ | | |

### Automatická diagnostika

| # | test | P | stav | dátum · stroj | výsledok |
|---|---|---|---|---|---|
| 521 | Hra bez Vulkanu zobrazí zrozumiteľnú chybu | P2 | ⬜ | | |
| 522 | Chýbajúci 32-bit driver zobrazí zrozumiteľnú chybu | P2 | ⬜ | | |
| 523 | Chýbajúci Proton runtime zobrazí zrozumiteľnú chybu | P2 | ⬜ | | |
| 524 | Anti-cheat problém zobrazí zrozumiteľnú chybu | P2 | ⬜ | | |
| 525 | Chýbajúci Wine dependency zobrazí zrozumiteľnú chybu | P2 | ⬜ | | |
| 526 | GPU problém zobrazí zrozumiteľnú chybu | P2 | ⬜ | | |
| 527 | Audio problém zobrazí zrozumiteľnú chybu | P2 | ⬜ | | |
| 528 | Controller problém zobrazí zrozumiteľnú chybu | P2 | ⬜ | | |
| 529 | Network problém zobrazí zrozumiteľnú chybu | P2 | ⬜ | | |
| 530 | Používateľ dostane odporúčanie opravy bez potreby terminálu | P2 | ⬜ | | |

### Real world test

| # | test | P | stav | dátum · stroj | výsledok |
|---|---|---|---|---|---|
| 531 | Nainštalovať Steam → nainštalovať Windows hru → spustiť → hrať → použiť controller → Alt+Tab → zmeniť hlasitosť → vrátiť sa do hry → ukončiť → update → reštart → znovu hrať | P1 | ⬜ | | |
| 532 | Nainštalovať Windows aplikáciu → vytvoriť prefix → otvoriť dokument → uložiť dokument → zavrieť → znovu otvoriť → update aplikácie → reštart → pokračovať v práci | P2 | ⬜ | | |
| 533 | Nainštalovať launcher → prihlásiť účet → nainštalovať hru → spustiť anti-cheat → hrať → ukončiť → reštartovať → hrať znovu | P2 | ⬜ | | |
| 534 | Spustiť hru → odpojiť controller → pripojiť controller → Alt+Tab → odpojiť headset → pripojiť headset → zmeniť audio výstup → pokračovať v hre | P2 | ⬜ | | |
| 535 | Spustiť fullscreen hru → prepnúť monitor → zmeniť refresh rate → vrátiť pôvodný monitor → Alt+Tab → pokračovať bez pádu | P2 | ⬜ | | |
| 536 | Spustiť hru → suspend → resume → pokračovať v hre | P2 | ⬜ | | |
| 537 | Spustiť Windows aplikáciu → suspend → resume → pokračovať v práci | P2 | ⬜ | | |
| 538 | Spustiť Steam + GOO + browser + Windows aplikáciu + hru súčasne a overiť, že desktop zostáva stabilný | P1 | ⬜ | | |
| 539 | Spustiť hru s aktívnym NET security systémom a overiť, že herná komunikácia funguje iba podľa povolení | P2 | ⬜ | | |
| 540 | Kompletný gaming test: čistá inštalácia LatteOS → GPU driver → Steam → Proton → controller → hra → launcher → Windows hra → fullscreen → VRR → audio → suspend/resume → update → rollback → druhý štart hier bez terminálu | P2 | ⬜ | | |
## 4 · Ergonómia — človek a ovládanie *(nová kategória)*

Testuje sa s **ľuďmi**, nie skriptom. Poradie ovládania podľa pravidiel LatteOS: **1. myš**, **2. myš + klávesnica**, **3. gamepad**. Testerov zapisovať do výsledku skratkou: **Z** začiatočník, **W** skúsený z Windowsu, **S** senior, **H** hráč, **L** ľavák. Metóda: tester hovorí nahlas, čo si myslí; pozorovateľ nepomáha.

### 4.1 Objaviteľnosť — nájde to človek z Windowsu bez návodu?

Úloha sa zadá slovami („spusti Kalkulačku“), nie miestom. Do výsledku: **prvé miesto, kam klikol**, čas a počet omylov. Cieľ: do 30 s, najviac 1 omyl.

| # | test | P | stav | dátum · stroj · tester | výsledok |
|---|---|---|---|---|---|
| 601 | Spustiť aplikáciu, ktorá nie je pripnutá — Windows: Štart vľavo dole / kláves Win → LatteOS: LensGoo, kláves Win | P1 | ⬜ | | |
| 602 | Otvoriť Nastavenia — Windows: Štart › ozubené koliesko, Win+I → LatteOS: GooPower › Nastavenia, Win+I, LensGoo | P1 | ⬜ | | |
| 603 | Vypnúť a reštartovať PC — Windows: Štart › Napájanie → LatteOS: GooPower › Vypnúť / Reštartovať | P1 | ⬜ | | |
| 604 | Zamknúť PC, odhlásiť sa — Windows: Štart › účet, Win+L, Ctrl+Alt+Del → LatteOS: GooPower › Zamknúť · Odhlásiť, Win+L | P1 | ⬜ | | |
| 605 | Pripojiť sa na Wi-Fi — Windows: ikona siete vpravo dole → LatteOS: rohová lišta Noctalie vpravo dole | P1 | ⬜ | | |
| 606 | Zmeniť hlasitosť a prepnúť reproduktory ↔ slúchadlá — Windows: ikona reproduktora vpravo dole → LatteOS: rohová lišta | P1 | ⬜ | | |
| 607 | Pozrieť dátum a kalendár — Windows: klik na hodiny vpravo dole → LatteOS: ClockGoo ľavý klik | P1 | ⬜ | | |
| 608 | Otvoriť, prečítať a vymazať upozornenia; zapnúť Nerušiť — Windows: hodiny / Win+N → LatteOS: ClockGoo ľavý klik, Win+N | P1 | ⬜ | | |
| 609 | Otvoriť správcu súborov — Windows: priečinok na paneli, Win+E → LatteOS: Súbory, Win+E | P1 | ⬜ | | |
| 610 | Nájsť súbor podľa časti mena — Windows: hľadanie v Štarte / Prieskumníku → LatteOS: LensGoo › Súbory | P1 | ⬜ | | |
| 611 | Nainštalovať aplikáciu — Windows: Microsoft Store → LatteOS: QueenGoo › App Manager | P1 | ⬜ | | |
| 612 | Odinštalovať aplikáciu — Windows: Nastavenia › Aplikácie → LatteOS: App Manager, pravý klik v LensGoo | P1 | ⬜ | | |
| 613 | Ukončiť zaseknutú aplikáciu — Windows: Ctrl+Shift+Esc, Správca úloh → LatteOS: Ctrl+Shift+Esc, Monitor, ponuka okna | P1 | ⬜ | | |
| 614 | Urobiť snímku obrazovky a časti obrazovky — Windows: PrtSc, Win+Shift+S → LatteOS: PrtSc, Win+Shift+S | P1 | ⬜ | | |
| 615 | Pripnúť aplikáciu, aby bola stále po ruke — Windows: pravý klik na panel › Pripnúť → LatteOS: obľúbené v LensGoo / ikra | P2 | ⬜ | | |
| 616 | Zmeniť tapetu — Windows: pravý klik na plochu › Prispôsobiť → LatteOS: pravý klik na plochu | P2 | ⬜ | | |
| 617 | Zmeniť rozlíšenie a mierku — Windows: pravý klik na plochu › Obrazovka → LatteOS: Nastavenia › Obrazovka | P2 | ⬜ | | |
| 618 | Pripojiť projektor / druhý monitor — Windows: Win+P → LatteOS: Win+P | P2 | ⬜ | | |
| 619 | Bezpečne odpojiť USB kľúč — Windows: ikona v oblasti oznámení → LatteOS: rohová lišta, Súbory | P2 | ⬜ | | |
| 620 | Spárovať Bluetooth slúchadlá — Windows: rohová lišta › Bluetooth → LatteOS: rohová lišta, Správca zariadení | P2 | ⬜ | | |
| 621 | Pridať tlačiareň a vytlačiť — Windows: Nastavenia › Tlačiarne → LatteOS: Správca zariadení | P2 | ⬜ | | |
| 622 | Prepnúť jazyk klávesnice — Windows: SK/EN vpravo dole, Win+Medzerník → LatteOS: rohová lišta, Win+Medzerník | P2 | ⬜ | | |
| 623 | Obnoviť zmazaný súbor — Windows: Kôš na ploche → LatteOS: Súbory › Kôš | P2 | ⬜ | | |
| 624 | Nainštalovať aktualizácie — Windows: Nastavenia › Windows Update → LatteOS: QueenGoo (modrá guľka) › App Manager | P2 | ⬜ | | |
| 625 | História schránky a emoji — Windows: Win+V, Win+. → LatteOS: Win+V, Win+. | P2 | ⬜ | | |
| 626 | Pozrieť zaťaženie PC — Windows: Správca úloh › Výkon → LatteOS: GooPower pravý klik (pás výkonu), Monitor | P2 | ⬜ | | |
| 627 | Nájsť pomoc, keď si nevie rady — Windows: Tipy / Získať pomoc / F1 → LatteOS: Barista, AI v LensGoo | P2 | ⬜ | | |
| 628 | Vrátiť omylom presunutú kvapku na miesto — Windows: — → LatteOS: Nastavenia › Kvapky › Vrátiť na miesto | P2 | ⬜ | | |

### 4.2 Naučené akcie — má každý zvyk z Windowsu obdobu?

Používateľ urobí akciu naslepo, ako je zvyknutý. Do výsledku: **rovnaké** / **iné, ale pochopil** / **nefunguje**. Pri „iné“ zapísať, čo čakal.

| # | test | P | stav | dátum · stroj · tester | výsledok |
|---|---|---|---|---|---|
| 629 | Alt+Tab, Alt+Shift+Tab (držať Alt) — Windows: prepnutie okien → LatteOS: rovnaké | P1 | ⬜ | | |
| 630 | Alt+F4 na okne a na prázdnej ploche — Windows: zavrieť / ponuka Vypnúť → LatteOS: rovnaké | P1 | ⬜ | | |
| 631 | Win+D a klik do pravého dolného rohu — Windows: ukázať plochu → LatteOS: Win+D; pravý klik na hlavu GooBaru — roh? | P1 | ⬜ | | |
| 632 | Win+šípky — Windows: prichytiť / maximalizovať → LatteOS: plávajúce ako Windows, páska a dlaždice = fokus | P1 | ⬜ | | |
| 633 | Dvojklik na titulok okna — Windows: maximalizovať / obnoviť → LatteOS: rovnaké | P1 | ⬜ | | |
| 634 | Potiahnuť okno za titulok k hornému okraju — Windows: maximalizovať (Aero Snap) → LatteOS: zóny podľa režimu | P1 | ⬜ | | |
| 635 | Potiahnuť okno k ľavému / pravému okraju — Windows: polovica obrazovky → LatteOS: plávajúce = polovica | P1 | ⬜ | | |
| 636 | Ťahať okraj a roh okna — Windows: zmena veľkosti → LatteOS: rovnaké vo všetkých režimoch? | P1 | ⬜ | | |
| 637 | Klik na ikonu aktívneho okna na paneli — Windows: minimalizuje → LatteOS: ikra: minimalizuje (páska: nie) | P1 | ⬜ | | |
| 638 | Prechod myšou nad ikonou na paneli — Windows: náhľad okna → LatteOS: ikra / strapec sa rozvinie | P1 | ⬜ | | |
| 639 | Pravý klik na ikonu na paneli — Windows: jump list, Zavrieť okno → LatteOS: ponuka ikry | P1 | ⬜ | | |
| 640 | Stredný klik na ikonu na paneli — Windows: nové okno aplikácie → LatteOS: zámerne nič — zapísať, či to chýba | P2 | ⬜ | | |
| 641 | Win+1…9 — Windows: N-tá aplikácia na paneli → LatteOS: N-té okno na lište | P2 | ⬜ | | |
| 642 | Pravý klik na plochu — Windows: ponuka plochy → LatteOS: ponuka plochy | P1 | ⬜ | | |
| 643 | Ctrl+C / Ctrl+V medzi rôznymi aplikáciami — Windows: kopírovanie → LatteOS: rovnaké | P1 | ⬜ | | |
| 644 | Delete, Shift+Delete, F2, Ctrl+Z v Súboroch — Windows: kôš, natrvalo, premenovať, späť → LatteOS: rovnaké | P1 | ⬜ | | |
| 645 | Ťahanie súboru z Plochy / Súborov do okna — Windows: otvorí / vloží → LatteOS: rovnaké | P2 | ⬜ | | |
| 646 | Ťahanie súboru so Shiftom / Ctrl — Windows: presunúť / kopírovať → LatteOS: rovnaké | P2 | ⬜ | | |
| 647 | Ctrl + koliesko — Windows: zväčšenie obsahu → LatteOS: rovnaké v aplikáciách | P2 | ⬜ | | |
| 648 | Alt+Medzerník — Windows: ponuka okna → LatteOS: ponuka okna | P2 | ⬜ | | |
| 649 | Ctrl+Alt+Del — Windows: bezpečnostná obrazovka → LatteOS: ponuka Zabezpečenie | P2 | ⬜ | | |
| 650 | Win+Tab — Windows: Zobrazenie úloh → LatteOS: prehľad okien | P2 | ⬜ | | |
| 651 | Win+Ctrl+D, Win+Ctrl+← → — Windows: virtuálne plochy → LatteOS: rovnaké | P2 | ⬜ | | |
| 652 | Esc a klik mimo ponuky — Windows: zavrie ponuku → LatteOS: zavrie kartu | P2 | ⬜ | | |
| 653 | Zatrasenie oknom (Aero Shake) — Windows: minimalizuje ostatné → LatteOS: nič — zapísať, či to niekto skúsil | P2 | ⬜ | | |
| 654 | Ikony v oblasti oznámení (Discord, Steam…) — Windows: vpravo dole pri hodinách → LatteOS: rohová lišta | P2 | ⬜ | | |
| 655 | Hodiny vpravo dole — Windows: vpravo dole → LatteOS: ClockGoo — kde ich hľadal? | P2 | ⬜ | | |

### 4.3 Myš — prvá voľba

Merať: zásah na prvý raz, čas, počet klikov k cieľu, omylom spustené akcie.

| # | test | P | stav | dátum · stroj · tester | výsledok |
|---|---|---|---|---|---|
| 656 | Každá kvapka má ľavý aj pravý klik a žiadny nevedie do prázdna | P1 | ⬜ | | |
| 657 | Ciele najmenej 32 px; ikry pri 48 oknách sa stále dajú trafiť | P1 | ⬜ | | |
| 658 | Okraj ako nekonečný cieľ: myš narazená do okraja trafí kvapku (Fittsov zákon) — všetky 4 okraje | P1 | ⬜ | | |
| 659 | Rýchly pohyb do rohu: trafí rohovú lištu, nie susednú kvapku | P1 | ⬜ | | |
| 660 | Bežné úlohy najviac na 2 kliky (zapísať počet pre úlohy 601–628) | P1 | ⬜ | | |
| 661 | Klik vs. ťahanie: drobný pohyb pri kliku kvapku nepresunie | P1 | ⬜ | | |
| 662 | Koliesko v okne pri okraji nezmení omylom veľkosť kvapky | P1 | ⬜ | | |
| 663 | Prechod myšou cez kvapky nič neotvára (karta až na klik) | P1 | ⬜ | | |
| 664 | Popis pri prechode myšou: oneskorenie primerané, nezakryje cieľ | P1 | ⬜ | | |
| 665 | Karta a ponuka sa otvorí pri kvapke, zatvorí klikom mimo a Esc | P1 | ⬜ | | |
| 666 | Dvojklik na kvapku nespustí akciu dvakrát | P1 | ⬜ | | |
| 667 | Žiadna funkcia nie je dostupná iba stredným klikom | P1 | ⬜ | | |
| 668 | Ľavák (prehodené tlačidlá): ľavý / pravý klik na kvapkách sedí | P2 | ⬜ | | |
| 669 | Touchpad: ťuk, posúvanie dvoma prstami, pravý klik dvoma prstami, gestá | P2 | ⬜ | | |
| 670 | Myš s vysokou aj nízkou citlivosťou (DPI) | P2 | ⬜ | | |
| 671 | Ťahanie okna k okraju: žiadne nechcené prichytenie, zóny sa dajú zrušiť (Esc / späť) | P2 | ⬜ | | |
| 672 | Pás výkonu: prechod myšou a klik na bunku, pravý klik vtiahne | P2 | ⬜ | | |
| 673 | Zväčšovanie kvapiek kolieskom: plynulé, predvídateľné, hranice 50–220 % | P2 | ⬜ | | |
| 674 | Ťahanie strapca ikier a ikry na iný monitor | P2 | ⬜ | | |
| 675 | Dlhá práca (2 h) len myšou: únava, zbytočné presuny ruky na klávesnicu | P2 | ⬜ | | |

### 4.4 Myš + klávesnica — druhá voľba

| # | test | P | stav | dátum · stroj · tester | výsledok |
|---|---|---|---|---|---|
| 676 | Písanie v poli karty: globálne skratky ho neprerušia, AltGr znaky (@ # { } € \ \|) fungujú | P1 | ⬜ | | |
| 677 | Esc zavrie vždy najvrchnejšiu vec (ponuka → karta → režim) | P1 | ⬜ | | |
| 678 | Fokus je vždy viditeľný (karta, okno, kvapka v režime Win+T) | P1 | ⬜ | | |
| 679 | Tab / Shift+Tab v kartách a dialógoch v logickom poradí | P1 | ⬜ | | |
| 680 | Skratky LatteOS nekolidujú s bežnými aplikáciami (Office, prehliadač, IDE, hry) | P1 | ⬜ | | |
| 681 | Klávesnica bez klávesu Win: všetko ide myšou, Štart cez Ctrl+Esc | P1 | ⬜ | | |
| 682 | Win+T: všetky kvapky dosiahnuteľné, Enter / Menu / + − robia to isté ako myš | P2 | ⬜ | | |
| 683 | Shift / Ctrl + klik pri výbere viacerých položiek (Súbory, App Manager) | P2 | ⬜ | | |
| 684 | Super + ťahanie okna a Super + pravé ťahanie (zmena veľkosti) | P2 | ⬜ | | |
| 685 | Profily ovládania Windows / Linux / macOS: prepnutie a skúška 10 najčastejších skratiek | P2 | ⬜ | | |
| 686 | Zoznam skratiek: dá sa nájsť (podržanie Win — keď bude) | P2 | ⬜ | | |
| 687 | Spúšťač iba z klávesnice: Win → písať → Enter, do 2 s | P2 | ⬜ | | |

### 4.5 Gamepad — tretia voľba

Ovládanie Goo gamepadom je odložené — zapisovať, čo chýba.

| # | test | P | stav | dátum · stroj · tester | výsledok |
|---|---|---|---|---|---|
| 688 | Spustiť herný režim a hru iba gamepadom | P2 | ⬜ | | |
| 689 | Vrátiť sa z hry na plochu gamepadom (tlačidlo Home / Steam) | P2 | ⬜ | | |
| 690 | Gamepad na ploche nehýbe kurzorom ani neklikne omylom | P2 | ⬜ | | |
| 691 | Klávesnica na obrazovke pri zadávaní textu gamepadom | P3 | ⬜ | | |
| 692 | Steam Controller (1. verzia): kurzor, klik, koliesko na ploche | P3 | ⬜ | | |
| 693 | Goo gamepadom (keď bude): pohyb po kvapkách, A = klik, X = pravý klik, B = späť | P3 | ⬜ | | |

### 4.6 Čitateľnosť, odozva a pohyb

| # | test | P | stav | dátum · stroj · tester | výsledok |
|---|---|---|---|---|---|
| 694 | Kontrast textu v kartách aspoň 4,5 : 1 — svetlá, tmavá téma, každý materiál šálky | P1 | ⬜ | | |
| 695 | Odozva: klik → reakcia do 100 ms, karta otvorená do 200 ms | P1 | ⬜ | | |
| 696 | Animácia neblokuje: klik počas animácie sa vykoná | P1 | ⬜ | | |
| 697 | Stav nie iba farbou (batéria, guľky, pás výkonu) — skúška v odtieňoch sivej | P1 | ⬜ | | |
| 698 | Mierka 100 / 125 / 150 %: kvapky, karty a texty sa neorežú | P1 | ⬜ | | |
| 699 | Najmenšie písmo čitateľné z 60 cm | P2 | ⬜ | | |
| 700 | Obmedziť pohyb: nečinné „dýchanie“ kvapiek sa dá stíšiť | P2 | ⬜ | | |
| 701 | Texty zrozumiteľné laikovi (bez „compositor“, „proces“, „session“) | P2 | ⬜ | | |
| 702 | Chybové hlásenie hovorí, čo sa stalo a čo urobiť — bez terminálu | P2 | ⬜ | | |
| 703 | Nebezpečné akcie (Vypnúť pri neuloženej práci, Odhlásiť) sa pýtajú | P2 | ⬜ | | |
| 704 | Deň a noc (keď bude): plynulé, nerušivé, snímky obrazovky bez farebného posunu | P2 | ⬜ | | |

### 4.7 Omyly a návrat

Ako ľahko sa používateľ dostane späť, keď niečo pokazí.

| # | test | P | stav | dátum · stroj · tester | výsledok |
|---|---|---|---|---|---|
| 705 | Kvapku omylom presunie na iné miesto → vráti ju | P1 | ⬜ | | |
| 706 | Kvapku zmenší na minimum → stále ju nájde a zväčší | P1 | ⬜ | | |
| 707 | Kvapku omylom skryje → nájde, ako ju ukázať | P1 | ⬜ | | |
| 708 | Omylom prepne režim okien → vráti ho | P1 | ⬜ | | |
| 709 | Okno ujde mimo obrazovky / na odpojený monitor → dostane ho späť | P1 | ⬜ | | |
| 710 | Zatvorí kartu uprostred písania → text ostal | P2 | ⬜ | | |
| 711 | Zmení nastavenie a nepáči sa mu → vráti späť | P2 | ⬜ | | |
| 712 | Omylom zapne Nerušiť / herný režim → vie, prečo nechodia upozornenia | P2 | ⬜ | | |

### 4.8 Scenáre bežného dňa

Celá úloha bez pomoci, s meraním času. Pozorovateľ zapisuje, kde sa zasekol.

| # | test | P | stav | dátum · stroj · tester | výsledok |
|---|---|---|---|---|---|
| 713 | Ráno: zapnúť → prihlásiť → pošta → kalendár → hudba | P1 | ⬜ | | |
| 714 | Kancelária: príloha z e-mailu → upraviť → uložiť do Dokumentov → vytlačiť → poslať späť | P1 | ⬜ | | |
| 715 | Dve okná vedľa seba (porovnať dokumenty) — v každom režime okien | P1 | ⬜ | | |
| 716 | Videohovor: kamera, mikrofón, slúchadlá, zdieľanie obrazovky | P1 | ⬜ | | |
| 717 | Program z webu (.exe, .flatpak, .rpm): stiahnuť → nainštalovať → spustiť | P1 | ⬜ | | |
| 718 | Fotky z telefónu do PC (kábel, KDE Connect / LocalSend) | P2 | ⬜ | | |
| 719 | Prezentácia na projektore: Win+P, Nerušiť, celá obrazovka | P2 | ⬜ | | |
| 720 | Hra a späť: spustiť hru, Alt+Tab do prehliadača, späť do hry | P2 | ⬜ | | |
| 721 | Večer: uložiť prácu, vypnúť; ráno je všetko tak, ako bolo (obnovenie relácie — keď bude) | P2 | ⬜ | | |

### 4.9 Celkové hodnotenie

| # | test | P | stav | dátum · stroj · tester | výsledok |
|---|---|---|---|---|---|
| 722 | Začiatočník (nikdy nevidel Linux): prvých 15 minút bez pomoci — čo zvládol, kde sa zasekol | P1 | ⬜ | | |
| 723 | Skúsený používateľ Windowsu: 1 pracovný deň — zoznam vecí, ktoré mu chýbali | P1 | ⬜ | | |
| 724 | Senior: 10 základných úloh zo 4.1 | P2 | ⬜ | | |
| 725 | Hráč: celý večer s hrami a Discordom | P2 | ⬜ | | |
| 726 | Dotazník SUS po každej skúške (cieľ ≥ 70) a 3 vety „čo ma najviac potešilo / nahnevalo“ | P1 | ⬜ | | |
