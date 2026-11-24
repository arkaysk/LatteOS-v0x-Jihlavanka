# Audit 24. 11. 2026 — TrayShore, plocha, kurzor, zámok a prihlásenie, SAFE, druhý monitor, pravidlá enginu

Rozsah: `goo/lib/shore.luau`, `goo/parts/shore.plm`, `goo/parts/shoregrab.plm`, `goo/lib/desk.luau`, `goo/parts/desk.plm`,
`goo/lib/ctx.luau`, `goo/parts/ctx.plm`, `goo/parts/cursor.plm`, `goo/parts/curdrop.plm`, `crates/latte-goo/src/main.rs` (kurzor),
`goo/lockscreen.*`, `goo/login.*`, `goo/login-safe.plm`, `goo/parts/greet.plm`, `goo/parts/lock.plm`, `goo/lib/lock.luau`,
`goo/lib/login.luau`, `goo/safe.*`, `goo/side.*`, `goo/lib/engine.luau` (idle, sklo), `goo/lib/cup.luau`, `system/cups.json`,
`system/gooengine.json`, `goo/lang/sk.plm`, `bin/latte-desktop`, `bin/latte-lock`, `bin/latte-login`.
Proti: LATTEOS-GOO.md, docs/goo/PRAVIDLA.md, ROZHRANIE.md, ROZHODNUTIA.md, GOOENGINE-2.md §7–§9, §13, §14, ROADMAP
(Poradie práce, 6H, 6.32–6.36, 6.50, 7B.05, 9.19, 10b) a bughunt 22.–24. 11.
Kód sa nemenil. `pleamar --check` prešiel pre goo, side, lockscreen, login, login-safe a safe (sk, bez chýbajúceho prekladu).
Čísla riadkov platia pre pracovný strom 24. 11. (vetva v0.55, `goo/lang/sk.plm` s necommitnutými zmenami).

Značky: **[kód]** = overené čítaním kódu · **[naživo]** = podozrenie, treba overiť v relácii ·
**fix pred 0.6** / **funkcia po 0.6** (Poradie práce: do 0.6 iba opravy).

---

## Zhrnutie

1. **TrayShore `refresh()`** prepíše pole hesla Wi-Fi a ponuku programu hlavným panelom pri každej správe služby (`shore.luau:109–113`; vysoká).
2. **Plocha** kreslí ikony za okrajom a nad 128 súborov nič nepovie, no Ctrl+A s Delete ich zahodí. Meno s `\n` podvrhne ikonu s relatívnou cestou (`desk.luau:70–110`, `bin/latte-desktop`).
3. **Kurzor Goo:** spoločný súbor `pleamar-wm-shell-cursor` hlavnej a bočných scén → pri dvoch monitoroch chýbajúci alebo dvojitý kurzor (`main.rs:218`). Mŕtve kľúče v `gooengine.json`, bez veľkosti v Nastaveniach.
4. **Zámok:** nevidno ani nejde prepnúť rozloženie. Meno sa dá prepísať. Záložný zámok a SAFE nehlásia Caps Lock. Na zamknutej obrazovke chýba `agent: no` pri hesle (`login.luau:173`, `greet.plm:328–335`).
5. **Pravidlá:** chýba pravý klik na TrayShore (8, 23), ponuky plochy majú rôzne poradie (23), nečinnosť ignoruje úsporný profil (§3.1). Sklo 0–4 sa rozišlo s UI, ktoré ponúka iba 3↔4 (`settings.qml:893–895`).
6. **Slovenčina** je pokrytá celá. Chyby: dátum „30. október“, „Hlasitosť vypnutý“, tri mená zámku, Kôš/kôš, vykanie v Ctrl+Alt+Del.
7. **Num Lock** je od 23. 11. predvolene zapnutý, takže jeho nápis svieti stále na TrayShore aj na prihlásení (rozhodnutie používateľa). Druhý monitor nemá spúšťač ani hodiny.

---

## 1. Dizajn

### 1.1 TrayShore

| # | Nález | Kde | Prečo vadí | Závažnosť |
|---|---|---|---|---|
| D1 | **Šípka `^` otvára Rýchle nastavenia, nie skryté ikony.** Človek z Windows 11 čaká pod `^` pretečenie ikon programov. Tu sa programy nad 10 stratia (F5) a `^` je dashboard. | `shore.plm:44–48`, `shore.luau:304` | Svalová pamäť z Windows; pravidlo 2 | stredná, funkcia po 0.6 (pretečenie za `^` alebo za ďalšiu `…`) |
| D2 | **Pravý klik chýba** na sieti, batérii, šípke a značke klávesnice, ani nezavibruje. Stlmiť sa dá iba hlasitosť (pravý klik, `s == 1`). ROADMAP 10b chcel na značke klávesnice ponuku (rozloženia, Mapa znakov, Nastavenia › Klávesnica). | `shore.luau:351`, `shore.plm:47, 72–74, 86–87` | Pravidlá 8 a 23 („každý objekt … TrayShore … ju má“) | stredná, fix pred 0.6 (aspoň chvenie a odkaz na Nastavenia) |
| D3 | **Vrstva 2 chýba:** panel nemá odkaz na Nastavenia › Sieť / Zvuk / Bluetooth ani ozubené koliesko „Všetky nastavenia“ ako Rýchle nastavenia vo Windows. | `shore.luau:128–205, 233–291` | Pravidlo 24 (druhý klik = úplný detail) | stredná, fix pred 0.6 (jeden riadok na stránku) |
| D4 | **Batéria:** klik otvorí hlavný panel, ktorý o batérii nič neukazuje (percentá, nabíjanie, profil napájania). Tip je iba „Batéria N %“ bez stavu nabíjania. | `shore.luau:298, 348–350` | Klik bez výsledku, ktorý by bolo vidieť | nízka, fix pred 0.6 (riadok batérie a profilu v paneli) |
| D5 | **CAPS LOCK / NUM LOCK** má písmo 8 px a krytie 55 %, pod ikonami (H−7). Caps Lock je výnimka pre vrstvu 0, ktorá má byť „nahlas“, no je skoro nečitateľná. Num Lock je od 23. 11. predvolene zapnutý (`greeter/labwc/rc.xml:9`, `pleamar-wm-z-numlock.patch`), takže nápis svieti natrvalo. | `shore.plm:90–91` | Pravidlo 24: „normál potichu, výnimka nahlas“, kontrast (WCAG) | stredná. **Rozhodnutie používateľa:** Num Lock ukazovať iba vypnutý (výnimka), Caps Lock väčšie a sýtejšie |
| D6 | **Značka klávesnice nemá tip** (`on hover` chýba). Ostatné znaky ho majú. | `shore.plm:84–87` | Nekonzistentné | nízka, fix pred 0.6 |
| D7 | **Spätná väzba stlačenia** chýba na všetkých tlačidlách dosky: je iba hover (10 % krémová, pri šípke zlatá). Na sieti a batérii nič nerobí koliesko a nič nezavibruje. | `shore.plm:45, 55, 71` | Pravidlá 8 a 25 | nízka, po 0.6 |
| D8 | **Ponuka programu ide do vysokého panela** so „Späť“, ktoré vedie do Rýchlych nastavení. Vo Windows aj KDE je to malá ponuka pri ikone. Pre ToolHive je už iná cesta (`traymenu`, `card.open` pri ukazovateli). | `shore.luau:222–230` vs `363–381` | Dve správania pre to isté | nízka, po 0.6 (jedna cesta: ponuka pri ikone cez `ctx`) |
| D9 | Doska je podľa LATTEOS-GOO §8 „z materiálu šálky (ako titulky okien)“. Kód ju robí telom goo (`plates.plm:8`, `shore.goo`), ako 12. 11. rozhodol používateľ. Dokument zaostal. | LATTEOS-GOO.md §8 (TrayShore) | Rozpor so záväzným textom | nízka, fix dokumentu |

### 1.2 Plocha a kontextová ponuka

| # | Nález | Kde | Prečo vadí | Závažnosť |
|---|---|---|---|---|
| D10 | **Dve ponuky plochy s iným poradím.** `bare_menu` (bez ikon, druhý monitor) ide Súbory · Terminál · Obrazovka · **Tapeta · Prispôsobiť** · Kvapky · Monitor · Všetky nastavenia. `desktop_menu` ide … **Prispôsobiť · Tapeta** · Postaviť niečo · Terminál a nemá Kvapky, Monitor ani Všetky nastavenia. Terminál sa raz otvára cez `open.terminal()`, raz natvrdo cez `foot`. | `desk.luau:191–230` (r. 197–198 vs 224–225, 195 vs 228) | Pravidlo 23: „poradie je pevné“ | stredná, fix pred 0.6 |
| D11 | **Rad ikon hore** (Vystrihnúť · Kopírovať · Premenovať · Odstrániť), ktorý žiada pravidlo 23 a pozná ho Windows 11, ponuka ikony nemá. Chýbajú aj klávesy Menu a Shift+F10. | `desk.luau:250–259`, `desk.plm:64–74` | Pravidlo 23 | stredná. Klávesy fix pred 0.6, rad ikon funkcia po 0.6 |
| D12 | **Podponuka nahradí ponuku** na tom istom mieste (riadok „Späť“). Windows ju vysúva bokom. Šípky vľavo a vpravo nefungujú. | `ctx.luau:44–57`, `ctx.plm:27–29` | Návyk z Windows, klávesnica | nízka, po 0.6 |
| D13 | **Farby sú natvrdo** (`#2c2019`, `#f7c873`, `#4a372b` v `ctx.plm`, `desk.plm`, `lock.plm`) a nie podľa šálky. Pri Porcelain alebo Royal porcelain ostane ponuka espresso. Pravidlo 10 dovoľuje vlastný vzhľad Goo, ale nerozhodlo, či šálku ignorovať. | `ctx.plm:35–56`, `desk.plm:61–84` | Konzistentnosť so šálkou okien | nízka. **Rozhodnutie používateľa** |
| D14 | **Výber ako vo Windows:** chýba Ctrl+klik, Shift+klik, šípky a písanie mena (skok na ikonu). ROADMAP 7B.05 to vedie ako „chýba oproti v0.3“. | `desk.luau:333–339`, `desk.plm:64–74` | Človek z Windows to robí bez rozmýšľania | stredná. Ctrl/Shift+klik fix pred 0.6, ostatné po 0.6 |
| D15 | Prázdny Kôš: „Vysypať Kôš“ ostáva aktívne a pri `trashed == 0` potichu nič nespraví. „Prilepiť“ je aktívne aj pri prázdnej schránke. | `desk.luau:236, 219` | Pravidlo 8 (bez funkcie zavibrovať) | nízka |

### 1.3 Kurzor

| # | Nález | Kde | Prečo vadí | Závažnosť |
|---|---|---|---|---|
| D16 | **Dva kurzory podľa miesta.** Nad ponukami a popupmi programov sa ukáže systémový (záplata `z-popup-cursor`, bughunt 23. 11.: „klasický systémový, nie Goo“), nad DockShore tiež (`cur.on = 0` pri `over_dock`, `main.rs:606`), na prihlásení je kurzor labwc. Šípka tak cestou po ploche mení tvar aj veľkosť. | `main.rs:220, 606` | Konzistentnosť, „hrot je bod kliku“ | stredná. Zmierni ju téma xcursor v štýle Goo (§8.2, bod 1) — po 0.6 |
| D17 | **Veľkosť a prístupnosť:** Nastavenia › Vzhľad › Kurzor ponúkajú iba Klasický/Goo (`settings.qml:874–879`). `cursor.size` z `gooengine.json` v UI nie je a systémový kurzor nemá voľbu veľkosti ani farby (ROADMAP 9.19). Bruško kvapky má polomer 7,6 px × `size`, takže Goo kurzor je menší než predvolená šípka Windows (32 px). | `curdrop.plm:10–13`, `drops.plm:69` | Prístupnosť (zlý zrak, 4K) | stredná. Posuvník veľkosti fix pred 0.6 (jeden kľúč už existuje), téma po 0.6 |
| D18 | **Adaptívna farba z §8.3 nie je.** `mode: "adaptive"` a `lift: "glow"` v `system/gooengine.json` nikto nečíta: `main.rs:264` pozná iba `mode == "off"`. Kurzor má pevné farby (`cursor.plm:47–48`). | `system/gooengine.json` `cursor` | Mŕtva konfigurácia, dokument sľubuje voľbu | nízka. Kľúče opísať ako „pripravované“ alebo zmazať pred 0.6 |
| D19 | **Predvolený kurzor:** pred 0.6 je predvolený Goo kurzor (`cursor.live: true`), hoci je „v prerábaní“ a má rozpory D16 a F14. | `system/gooengine.json`, `settings.qml:876` | Prvý dojem nového používateľa | **Rozhodnutie používateľa** (bughunt 23. 11. to necháva otvorené) |

### 1.4 Zámok, prihlásenie, SAFE (porovnanie s Windows Hello)

| # | Nález | Kde | Závažnosť |
|---|---|---|---|
| D20 | **Rozloženie klávesnice na zamknutej obrazovke nie je vidieť** (`layouts = {}` pri LOCK). Windows ukazuje „SLK/ENG“ vpravo dole. Kto zamkol s US a heslo píše po slovensky, dostane „Nesprávne heslo“ a nevie prečo. | `login.luau:173` | **vysoká**, fix pred 0.6 |
| D21 | **Meno sa dá na zamknutej obrazovke prepísať** (`input user`, `z_user` aktívne aj pri zámku), no `check()` pri LOCK overí vždy `USER`. Windows meno zamknutého účtu iba ukazuje. | `greet.plm:328, 333`, `login.luau:104–109` | stredná, fix pred 0.6 (pri zámku pole iba na čítanie) |
| D22 | **Num Lock je stále na očiach** ako jantárové upozornenie s kmitaním (`2.5 * sin(time * 70)`), keď je zapnutý. Od 23. 11. je zapnutý vždy. Windows hlási iba Caps Lock. | `greet.plm:344`, `login-safe.plm:134` | stredná. **Rozhodnutie** (ako D5) |
| D23 | **Pod hladinou pred prihlásením** je výpis posledného pádu alebo novinky a vpravo hore poloha s počasím („Gbely“ na `login.png`). Na zamknutej obrazovke tiež. LATTEOS-GOO §6.2 to sám vedie ako otvorenú otázku („čo je bezpečné ukázať“). | `greet.plm:361–365`, `login.luau:61–81` | nízka. **Rozhodnutie** (napríklad pri zámku iba počet, nie text) |
| D24 | **Klávesnica:** Tab prepína iba meno a heslo. Napájanie, jazyk, rozloženie a výber relácie sa ovládajú len myšou, Escape iba zatvára. Windows sa dá prejsť Tabom celý. | `greet.plm:295–356` | nízka, po 0.6 |
| D25 | **`agent: no`** (agent pleamar-wm nesmie stlačiť) má `parts/lock.plm:53, 57` na hesle aj na Odomknúť. V `greet.plm`, ktorý je skutočnou zamknutou obrazovkou, je iba pri Vypnúť (`:306`), nie pri hesle (`:330`) ani pri šípke (`:335`). | `greet.plm:306, 330, 335` | stredná, bezpečnosť. Fix pred 0.6; **[naživo]**, či agent vôbec vidí plochy `kind: lock` |
| D26 | Popisky Uspať, Reštartovať a Vypnúť majú 11,5 px pri krytí 70 % (`greet.plm:301–303`). Ciele sú v poriadku (r = 23 → 46 px). | `greet.plm:301–306` | nízka |
| D27 | **SAFE** je čistý a čitateľný: plochý, `rate: 15`, na každom monitore. Chýba v ňom hlasitosť a tray. Pre záchranný režim je to v poriadku; sieť rieši `latte-safe` › 4 (`nmtui`). | `safe.plm` | — |

### 1.5 Druhý monitor oproti hlavnému

| Čo | Hlavný (`goo.plm`) | Druhý (`side.plm`) | Windows 11 (druhá lišta) |
|---|---|---|---|
| Lišta okien | BarGoo / DockShore | BarGoo, dock pleamar-wm na každom monitore (23. 11.) | áno |
| Spúšťač | LensGoo / LensShore / AppCloud | iba AppCloud (ak je zapnutý) | **tlačidlo Štart áno** |
| Hodiny | ClockGoo | **nie** | áno (od 22H2 predvolene) |
| TrayShore, Caps/Num, rozloženie | áno | nie (spec: „Na ďalších monitoroch TrayShore nie je“) | nie |
| Ikony na ploche | áno | nie, iba `bare_menu` | nie |
| Kurzor Goo, kruh kliku | áno | áno (`side.plm:50`) | — |
| Goo z klávesnice (Win+T) | áno | `keys.plm` je načítaný (`side.plm:46`), no podľa LATTEOS-GOO §6.1 „na vedľajšom monitore režim nie je“ | — |

**D28 (stredná, funkcia po 0.6):** druhý monitor nemá spúšťač ani hodiny. Pre človeka z Windows je to najväčší rozdiel:
na druhej obrazovke musí ísť do Štartu na hlavnú. Najmenší krok je ClockGoo v jednoduchej podobe a LensGoo, ktorý otvorí
spúšťač na hlavnej scéne.
**D29 (nízka):** `side.plm` načítava `launch.plm` a `keys.plm`, ktoré nepoužíva. Scéna má 11 127 vlastností oproti 11 257
hlavnej (`pleamar --check`). Pokoj (`spin tick`) ju zastaví, no načítanie a pamäť zostávajú. Optimalizácia po 0.6.

### 1.6 Pravidlá enginu: sklo, šálky, nečinnosť

- **D30 Sklo 0–4 (stredná, fix pred 0.6, dokumenty):**
  - PRAVIDLA 13 a LATTEOS-GOO bod 13 opisujú päť stupňov („0 bez skla … 4 True Glass“).
  - Nastavenia majú od úpravy iba prepínač „Extreme glass (True Glass)“, ktorý zapíše 3 alebo 4 (`settings.qml:893–895`).
  - Súhrn karty pritom stále píše meno stupňa z piatich (`settings.qml:291, 801`).
  - V Goo sa stupne 1, 2 a 3 líšia iba `ai_glass` (`engine.luau:975`): `panes` je 0 iba pri stupni 0 (`:971`), `true_glass` iba pri 4.
  - **Vedľajší účinok:** predvolený stupeň je 1 (`engine.luau:968`, `Theme.qml` `glassLevel: 1`). Prvé vypnutie True Glass zapíše 3,
    takže sa potichu zmení priehľadnosť bočných panelov (`Theme.pane`, posun `[0, 0.15, 0, -0.15, -0.4]`) aj sklo stránok AI.
  - Stupeň 0 („bez skla“, `panes = 0`) sa z UI zvoliť nedá.
  - Treba rozhodnúť: buď dokumenty prepísať na „sklo áno/nie + True Glass“, alebo vrátiť voľbu 0 a prepínač zapisovať 4 ↔ (predošlý stupeň).
- **D31 Šálky (nízka):**
  - `cups.json` je jeden zdroj a mená aj popisy sú preložené (overené skriptom).
  - `cup.luau` číta šálku iba pri štarte (`M.start`), takže okno pleamaru (props) zmenu šálky neuvidí bez reštartu.
  - Mená „Steam“ a „Solo Leveling“ sú cudzie značky (pozri `docs/audit` o licenciách). Mimo rozsahu, iba poznámka.
- **D32 Nečinnosť (stredná, fix pred 0.6):**
  - §3.1 a PRAVIDLÁ: „Kedy nie: … batéria < 20 % alebo úsporný profil“. `engine.luau:911` kontroluje iba `low_battery`
    a `TIER == "software"`, nie profil `power-saver` (ten číta iba `powergoo.luau:135`).
  - Tier `"safe"` sa pri hre neberie do úvahy, hoci `:1148` ho inak berie ako softvér.
  - V `gooengine.json` sú `fps_calm: 24` a `fps_asleep: 8`. Scény ich nečítajú: zo sekcie hardware sa stane fakt `hw.fps_calm`,
    ale žiadna `.plm` ho nepoužíva. Rýchlosť určujú natvrdo napísané `rate:` (napr. `side.plm:15`). LATTEOS-GOO §3.1 to sám
    priznáva („počet snímok pri nečinnosti sa ešte neobmedzuje“).
- **D33 Zámok a nečinnosť:** `engine.luau:916` pred hrou kontroluje `fact.locked`. To je však iba záložný zámok scény Goo.
  Skutočný zámok je samostatná scéna `lockscreen` a Goo sa o ňom dozvie len cez `covered` z pleamar-wm (`drops.plm:167`).
  Hra za zámkom je teda chránená iba cez `covered`. **[naživo]**, či `covered` naozaj platí pri `ext-session-lock`.

### 1.7 Slovenčina (`goo/lang/sk.plm`)

Pokrytie: `check.sh` vyžaduje preklad každého `tr()`/`N()` v Luau a každého textu scény. `pleamar --check` v sk prešiel
a mená a popisy šálok z `cups.json` sú v tabuľke všetky. Chyby sú v gramatike a termínoch:

| # | Nález | Kde | Návrh |
|---|---|---|---|
| L1 | **Dátum v nominatíve:** „Piatok 30. október“ (`date` v sk_SK dáva pri `%B` aj `%OB` nominatív; potvrdené aj na `docs/screenshots/login.png`). Platí pre prihlásenie, zámok aj SAFE. | `sk.plm:23`, `login.luau:99`, `lock.luau` (`show_date`), `safe.luau:44` | Mesiace v genitíve z vlastnej tabuľky (v repe je `goo/lang/sk-dates.json`, no tieto scény ho nepoužívajú), fix pred 0.6 |
| L2 | **Rod:** tip hlasitosti skladá `tr("Volume") .. " " .. tr("off")`, takže vznikne „Hlasitosť vypnutý“. „off“ = „vypnutý“ (`sk.plm:2183`) sa používa aj pri Wi-Fi a Bluetooth. | `shore.luau:297, 132, 165` | Celé vety: „Stlmené“, „Wi-Fi je vypnutá“, fix pred 0.6 |
| L3 | „connected“ = „pripojené“ (`sk.plm:2205`) stojí v jednom zozname vedľa „uložená“ a „zabezpečená“ (sieť). Káblová sieť je tiež „pripojené“. | `shore.luau:135, 141, 172` | Pre siete vlastný text „pripojená“ |
| L4 | **Zámok tromi menami:** „The lock screen“ = „Zamykacia obrazovka“ (`:328`), „Lock screen“ = „Obrazovka uzamknutia“ (`:569`), „Lock screen looks“ = „Vzhľady zámku“. K tomu „Lock position“ = „Uzamknúť polohu“ a „Unlock position“ = „Odomknúť polohu“. Windows SK používa „Uzamknutá obrazovka“. | `sk.plm` | Jeden termín: „Uzamknutá obrazovka“, sloveso „Zamknúť“ |
| L5 | **Kôš:** „Vysypať kôš“ (`:866`) proti „Vysypať Kôš“, „Presunúť do koša“ proti „do Koša“. | `sk.plm` | Kôš ako meno miesta s veľkým K všade |
| L6 | **Odhlásiť:** „Log out“ = „Odhlásiť“ proti „Sign out“ = „Odhlásiť sa“ (`:1933`). „Log in“ = „Prihlásiť“ (`:9`) má byť „Prihlásiť sa“. | `sk.plm:9, 21, 1933` | Zjednotiť na zvratné tvary |
| L7 | **Vykanie** v inak tykajúcom systéme: 7 reťazcov, hlavne Ctrl+Alt+Del („Stlačte znova pre odhlásenie“, „odhláste sa a vyberte“, „Naozaj? Stlačte ešte raz“). „pre + podstatné meno“ je navyše kalk. | `sk.plm:1133, 2970–2973` (+1951, 2725) | „Stlač znova na odhlásenie“ |
| L8 | „Run in console“ = „Spustiť v konzole“ (SAFE) proti „Terminál“ všade inde. | `sk.plm:32` | „Spustiť v termináli“ |
| L9 | „Panel“ (zóna šípky, čítačka obrazovky) je slovo bez obsahu. | `shore.plm:47` | „Rýchle nastavenia“ |
| L10 | **Mimo kontroly `check.sh`:** chybové hlásenia `latte-files` sa na ploche neprekladajú (ROADMAP A5 to vedie ako 0.6) a hlásenia `bin/latte-login` (riadky pádu, novinky) prichádzajú surové. | — | Do 0.6 iba evidovať |

---

## 2. Funkcie (spec proti kódu)

### 2.1 TrayShore

- **F1 — prepisovanie panela (vysoká, [kód], fix pred 0.6).** `shore.luau:109–113`:
  ```lua
  if showing == "networks" then open_networks(true) elseif showing == "devices" then open_devices(true)
  elseif showing == "sound" then open_sound(true) else open_main(true) end
  ```
  - `showing` má aj hodnoty `"password"` (`:120`), `"forget"` (`:152, 179`) a `"menu"` (`:228`). Všetky padnú do `open_main(true)`.
  - Každý `watch` (sieť, Bluetooth, médiá, jas, tray, batéria, zvuk; `:308–342`) volá `refresh()`.
  - Následok: pole hesla Wi-Fi zmizne pri prvom výsledku skenu, ktorý `open_networks` spustil tesne pred ním (`:158`).
  - Ponuka programu (Steam…) zmizne pri prvej zmene médií alebo zvuku.
  - **[naživo]** ako často chodia správy `media` (poloha skladby).
- **F2 — skenovanie Bluetooth sa nikdy nezastaví (stredná, [kód], fix pred 0.6).** `bluetooth.scan true` (`:185`) nemá pár
  `false`. Zariadenie hľadá ďalej aj po zatvorení panela: batéria a rušenie Wi-Fi na 2,4 GHz.
- **F3 — program bez Activate aj bez ponuky (stredná, [kód], fix pred 0.6).**
  - Activate zlyhá → `open_menu` (`:358`).
  - Keď `tray.menu` zlyhá alebo je prázdne, otvorí sa panel iba so „Späť“ a nadpisom (`:223–229`).
  - Pravidlo 8 žiada chvenie. Kód nevie, či ponuka je, kým sa nespýta. Prázdnu ponuku stačí odhaliť a ukázať chvenie alebo tip „Program nemá ponuku“.
- **F4 — viac ako 10 programov (stredná, [kód]).** `lay_out` zastaví na 10 (`:78`), `model bg max 10` (`shore.plm:9`).
  Jedenásty program nie je vidieť a nie je ani pretečenie (D1).
- **F5 — názov programu v tipe (nízka, [kód]).** `tip_for` (`:299–300`) neodstráni `_status_icon_N` (Electron), hoci `open_menu`
  (`:225`) áno. Tip ukáže „App_status_icon_1“.
- **F6 — dbusmenu (nízka, [kód]).**
  - `menu_rows` neberie ohľad na `visible == false`, ak ho pleamar posiela (**[naživo]**).
  - `gsub("_", "")` zje aj zdvojené `__` (doslovné podčiarknutie).
  - Rádiové voľby sa nelíšia od zaškrtávacích.
- **F7 — sieť bez NetworkManagera alebo bez Wi-Fi (nízka, [kód]).**
  - `net_glyph` pri `online == false` vráti vždy `wifi-off` (`:31`), aj na PC iba s káblom. Ikona `network-off` chýba.
  - Bez NM (pleamar `network` ho potrebuje, `:10`) ukáže „Bez siete“ aj pri funkčnom spojení cez systemd-networkd.
- **F8 — rozloženia klávesnice (stredná, [kód]).**
  - `layout_names` číta `XKB_DEFAULT_LAYOUT` raz a výsledok drží navždy (`:55–62`). Zmena rozložení v Nastaveniach sa ukáže až po reštarte Goo.
  - Pri jednom rozložení znak správne zmizne (`kb = 0`). Pri troch funguje, ak sú všetky v premennej.
  - Ďalšie rozloženie sa vyberá dotykom súboru v `$XDG_RUNTIME_DIR` (`:345`). Je to obchádzka, ktorá nemá vlastnú poznámku `ponytail:`
    (záplata `pleamar-wm-zz-layout.patch`, neskúšaná, bughunt 23. 11.).
  - Fakt `kb_layout` je index skupiny xkb. Ak pleamar-wm poradie skupín zmení, meno sa rozíde (**[naživo]**).
- **F9 — Caps/Num (overené naživo 23. 11.; bez nálezu).** Fakty idú z `wm/session.plm:1302–1306` cez `latte-say`. Na bočnej scéne sú
  deklarované a nepoužité, čo je v poriadku.
- **F10 — TrayShore v Nastaveniach › Kvapky chýba** (nízka, funkcia po 0.6; ROADMAP 6.50, otvorené). Skryť sa dá iba cez `hidden` a vzhľad Minimal
  (`shore.luau:90–93`).
- **F11 — Alt+ťahanie (6.36).** Hotové pozdĺž dolného okraja. `shoregrab.plm:6` má `ponytail:` „z okraja na okraj ešte nie“,
  čo je vedomá skratka (funkcia po 0.6).

### 2.2 Plocha

- **F12 — ikony mimo obrazovky (vysoká, [kód], fix pred 0.6).**
  - `arrange` obmedzuje iba riadky (`desk.luau:70, 91, 97`), stĺpce nikdy.
  - Pri veľkých ikonách (136 px) na 1080p je 8 riadkov, takže 128 súborov potrebuje 16 stĺpcov × 136 = 2176 px > 1920. Pri obrovských to je 32 × 236 px.
  - Ikona položená na 2560 px monitore (`prefs.at`) sa po prechode na menší monitor nakreslí za okrajom (`:91` kontroluje iba `at[2] < rows`).
  - Ikony za okrajom sa nedajú chytiť.
- **F13 — viac než 128 súborov (vysoká, [kód], fix pred 0.6).**
  - `MAX = 128` (`:11`) a `publish` skončí pri 128 (`:51`). Zvyšok sa nekreslí a používateľ sa to nedozvie.
  - `Ctrl+A` (`:365`) však vyberá zo všetkých `shown` a Delete (`:362`) ich presunie do Koša, teda aj tie neviditeľné.
  - Kôš je vratný (Ctrl+Z), preto vysoká, nie kritická.
  - Pri 200 súboroch volá `latte-desktop list` na každý súbor `stat`, `file` a dva `grep` (`bin/latte-desktop:36–48`), spolu asi 800 procesov.
  - Robí to po každej zmene v priečinku (debounce 250 ms, `desk.luau:323–328`). Kopírovanie veľa súborov na plochu tak opakovane zaťaží CPU (**[naživo]**).
- **F14 — meno súboru s novým riadkom alebo tabulátorom (stredná, bezpečnosť, [kód], fix pred 0.6).**
  - `latte-desktop list` píše polia oddelené `\t` a riadky `\n` bez úniku (`bin/latte-desktop:39–48`). `desk.luau:109–112` ich rozdelí.
  - Meno nesmie obsahovať `/`, ale `${f##*/}` reže až pri poslednom skutočnom lomítku.
  - Súbor s menom `x\nDokumenty\tDokumenty\t1\tfolder\t0\t0` (napríklad z rozbaleného archívu) preto pridá riadok
    s **relatívnou** cestou `Dokumenty`, ktorý `desk.luau` vezme ako priečinok.
  - Relatívna cesta sa vyhodnotí v pracovnom priečinku `latte-goo` a `latte-files`. Pri používateľských jednotkách systemd je to
    zrejme `$HOME`, teda ikona ukazuje na `~/Dokumenty` (**[naživo]**).
  - Delete ju potom presunie do Koša, pustené súbory presunie tam a dvojklik ju otvorí.
  - Oprava: oddeľovač `\0` (ako `find -print0`), alebo vynechať mená s riadiacimi znakmi, a v `desk.luau` prijať iba cesty
    začínajúce priečinkom Plocha.
- **F15 — „Zobraziť ikony na ploche“ sa nedá vrátiť z plochy (stredná, [kód], fix pred 0.6).**
  - Položka vždy volá `latte-desktop off` (`:213`, `on = true`).
  - Potom `desk_menu` ukáže `bare_menu` (`:310`), ktorá prepínač nemá. Ikony vráti iba Nastavenia › Pozadie.
  - Windows ich vráti tou istou položkou.
- **F16 — posledný rad pod goo (nízka, [naživo]).**
  - `rows` počíta s celou výškou obrazovky (`:70`). Pri malých (78 px) a veľkých (128 px) ikonách na 1080p končí posledný rad na 1026 px, resp. 1036 px.
  - Tam už sedia BarGoo a TrayShore a vrchný povrch Goo môže brať stlačenia.
- **F17 — `latte-desktop status` sa číta iba pri štarte (nízka, [kód]).** Zmenu zvonka hlási `tell` iba scéne `goo`
  (`bin/latte-desktop:30`). Pre bočné scény to nevadí, nemajú ikony.
- **F18 — obrázky ako ikony (nízka, [naživo]).** Pri PNG/JPEG/WebP/GIF je ikonou sám súbor (`latte-desktop:43`). Fotka s 24 Mpx
  sa dekóduje celá pre 52–164 px náhľad. Treba zistiť, či pleamar zmenšuje pri načítaní.
- **F19 — ponytail `desk.luau:57`:** ikony témy (SVG) sa pri ťahaní nesú bez obrázka. Vedomá skratka, po 0.6.
- **F20 — dvojklik:** časovač `every(100)` beží stále (`:329`) iba kvôli rozlíšeniu dvojkliku. Hodiny Luau by stačili. Nízka, po 0.6.
- **F21 — „Otvoriť v termináli“ (nízka, [kód]):** v `desktop_menu` je natvrdo `foot` (`:228`) mimo `open.terminal` (`TERMINAL`
  v `open.luau:9`). Ak `folder == ""` (pred prvým `list`), `cd ""` zlyhá potichu.

### 2.3 Kurzor

- **F22 — spoločný súbor značky (stredná, [kód] + [naživo], fix pred 0.6).**
  - `latte-goo` hlavnej aj každej bočnej scény (`latte-goo-side@.service`, `--scene side.plm`, scéna má `cur.on`) zapisuje
    do jedného `$XDG_RUNTIME_DIR/pleamar-wm-shell-cursor` svoje PID (`main.rs:218–233`).
  - Zapisuje iba vtedy, keď sa zmení jeho vlastný stav. Zmaže iba vlastné PID.
  - Bočná scéna štartuje po hlavnej (`After=latte-goo.service`), takže v súbore zostane jej PID.
  - Keď hlavná scéna nad DockShore prestane kresliť (`over_dock`, `cur.on = 0`), súbor nezmaže, lebo nie je jej. pleamar-wm ďalej
    skrýva svoju šípku, a tak **nad dockom hlavného monitora nie je žiadny kurzor**.
  - Stane sa to pri prvej návšteve docku po každom štarte alebo reštarte bočnej scény. Potom hlavná scéna zapíše svoje PID a ďalšie
    návštevy prebehnú správne. Bočné scény sa však reštartujú pri zmenách monitorov (`Restart=always`), takže sa to opakuje.
  - Keď hlavná scéna spadne a bočná žije, hlavný monitor nemá kurzor. Poistka 3 z §8.0 („keď latte-goo spadne, kurzor sa do sekundy
    vráti“) tak pri dvoch monitoroch neplatí.
  - Keď spadne bočná scéna a v súbore je jej PID, pleamar-wm ukáže svoju šípku. Hlavná scéna pritom kreslí ďalej, takže sú na
    hlavnom monitore **dva kurzory**.
  - Oprava: súbor na monitor (`…-shell-cursor.<monitor>`), alebo zoznam PID, alebo kurzor kreslí iba hlavná scéna.
- **F23 — téma xcursor `assets/cursors` (§8.2 bod 1) neexistuje** ([kód], `ls`). Záchranná vrstva „funguje všade“ teda nie je.
  V hrách, nad celou obrazovkou a v SAFE je téma Fedory. Funkcia po 0.6 (súvisí s prerábaním kurzora).
- **F24 — oneskorenie o jednu snímku** (§8.2 „najrizikovejší kus“) nie je zmerané na 60 ani 144 Hz. **[naživo]**.
- **F25 — Nastavenia:** `latte-settings cursor` zapisuje iba `cursor.live` (`bin/latte-settings:361–380`). `mode`, `size` a `lift`
  z UI nemeniteľné (D17, D18).

### 2.4 Zámok a prihlásenie

- **F26 — rozloženie na zámku (vysoká, [kód]):** pozri D20. Či Win+Space počas `ext-session-lock` funguje, je **[naživo]**.
- **F27 — Caps Lock v záložnom zámku (stredná, [kód], fix pred 0.6).**
  - `parts/lock.plm` (SAFE a Goo bez scény `lockscreen`) nemá `kb_lock` ani upozornenie.
  - Prihlásenie a zámok `greet.plm:344` ho majú, ale berú ho z LED diód (`bin/latte-login` `locks()`, `/sys/class/leds/*::capslock`).
  - Klávesnice bez LED (mnohé bezdrôtové cez prijímač) nič nehlásia. V relácii by išlo použiť `keys.caps` z pleamar-wm,
    ako to robí TrayShore. **[naživo]** na bezdrôtovej klávesnici.
- **F28 — zlé heslo (nízka).**
  - Je tu „Nesprávne heslo“ a „Overujem…“, ale nie počet pokusov a nie hlásenie zamknutého účtu (pam_faillock).
  - `auth.check` je synchrónny a blokuje logiku na dobu oneskorenia PAM (`lock.luau:42`, `login.luau:106`). Renderer beží ďalej.
  - Pri zamknutom účte by používateľ videl „Nesprávne heslo“ donekonečna. **[naživo]**, či je faillock zapnutý.
- **F29 — `lockscreen.plm` beží pri `rate: 60` počas celého zámku** (`:29`): voda, svetlo, kmitanie Caps Lock a po minúte
  hrajúce sa goo. LATTEOS-GOO §8 hovorí „Nothing moves, so a locked machine costs nothing“ (to platí iba pre `parts/lock.plm`).
  Po 15 min sa obrazovka vypne. Či pleamar pri vypnutých výstupoch nekreslí, je **[naživo]**. Nízka až stredná (notebook).
- **F30 — rôzne veľké monitory na zámku (nízka, [naživo]).** `lockscreen.plm:27–33` rozloží obrazovku podľa najväčšieho monitora
  a menší vidí jej stred. Čas a počasie v rohoch môžu na menšom monitore chýbať.
  Prihlásenie (`login.plm`, `screens: each max 3`) to robí pre každý monitor zvlášť. Štvrtý monitor na prihlásení nedostane nič.
- **F31 — stav `lock.json` po páde (bez nálezu).** Opätovné zamknutie je ošetrené (`login.luau:231–232`, `lock.luau` `M.start`) a overené 26. 10.
- **F32 — dátum** (stredná, fix pred 0.6; L1).
- **F33 — vypnutie zo zámku (nízka, [kód]).** Uspať, Reštartovať a Vypnúť idú na zamknutej obrazovke priamo cez `systemctl`
  (`login.luau:204`) bez upozornenia na otvorené okná. Windows to pri jednom používateľovi robí tiež, takže skôr rozhodnutie
  než chyba. Polkit rozhodne pri viacerých reláciách.

### 2.5 SAFE

- **F34 — nechránený `sys.watch` (stredná, [kód], fix pred 0.6).** `safe.luau:51` volá `sys.watch("window", …)` bez `pcall`.
  Ostatné služby majú `pcall` (`:71`). Ak služba `window` pod labwc nie je, chyba ukončí zvyšok logiky a riadok aplikácií
  a príkazov nebude fungovať. SAFE je pritom práve pre prípad, keď niečo chýba. **[naživo]**.
- **F35 — okná:** najviac 3 čipy (`safe.luau:55`) a iba kým sa zmestia (`safe.plm:108–110`). Ostatné okná nemajú cestu
  (žiadne „ďalšie“). Nízka.
- **F36 — zámok SAFE** = `parts/lock.plm` (bez Caps Lock, F27; dátum L1). Funguje cez `bin/latte-lock:12–14`.
- **F37 — SAFE bez GPU:** stavaný na softvérové kreslenie (labwc, `rate: 15`, žiadne pružiny). Hláška „Software rendering…“
  (`safe.plm:179`) je preložená. V poriadku.

### 2.6 Druhý monitor

- Ponuka plochy na správnom monitore (`desk.plm:46` `screens: desk_on`) a duchovia AppCloud a docku (`bar_only`) sú podľa
  bughuntu 23. 11. opravené v kóde. Dock je overený naživo. Ponuka plochy a AppCloud ešte **[naživo]**.
- `bare_menu` na druhom monitore volá `latte-app` (`open.settings`, `open.monitor`) a `xdg-open`. `side.plm:19` ich v `run:` má.
  `open.terminal` používa `TERMINAL` (`open.luau`) a `side.plm` povoľuje iba `foot`. Ak je `TERMINAL` iný, položka zlyhá potichu
  (**[naživo]**, nízka).
- Odpojenie monitora: `latte-screens` zastaví bočnú scénu a pri zmene hlavného monitora reštartuje `latte-goo.service`
  (`bin/latte-screens:32–44`). Otvorené karty sa stratia. Prijateľné.

---

## 3. Návrh dokončenia

### 3.1 Opravy pred 0.6 (poradie podľa dopadu)

1. **TrayShore `refresh` (F1)** — `goo/lib/shore.luau`: v `refresh()` pre `showing` ∈ {`password`, `forget`, `menu`} nerobiť nič
   (alebo obnoviť iba hlavičku). Pri `password` nechať pole tak.
   Test: `tests/` s napodobneným `sys.watch` (sieť po `network.scan`) — panel ostane na hesle.
2. **Plocha: neviditeľné a podvrhnuté ikony (F12, F13, F14).**
   - `bin/latte-desktop list`: oddeľovač `\0` alebo vynechať mená s `\n`/`\t`.
   - `goo/lib/desk.luau` `reload`: čítať po `\0`.
   - `arrange`: `cols = floor((sw − 2·EDGE)/cw)`, pozíciu mimo stĺpcov alebo riadkov brať ako voľnú.
   - Nad `MAX` posledná ikona „+N ďalších“, ktorá otvorí priečinok Plocha v DualBrew.
   - `picked()` a Ctrl+A iba z prvých `MAX`.
3. **Zámok: rozloženie a meno (D20, D21, F26).**
   - `goo/lib/login.luau`: pri LOCK naplniť `layouts` z `XKB_DEFAULT_LAYOUT`, `kb_layout` dostať cez `latte-say` (ako TrayShore)
     a klik = `pleamar-wm-layout-next`. Scéna `lockscreen.plm` potrebuje `fact kb_layout`.
   - `goo/parts/greet.plm`: `input user` a `z_user` neaktívne pri zámku (nový fakt `lock_mode`).
4. **`agent: no` na zamknutej obrazovke (D25)** — `goo/parts/greet.plm:330, 335` (heslo, šípka) a pri zámku aj `z_power`.
5. **Kurzor: značka na monitor (F22)** — `crates/latte-goo/src/main.rs` `marker()` + `patches/pleamar-wm-shell-cursor.patch`:
   súbor `pleamar-wm-shell-cursor` s riadkom na každú scénu (PID a monitor), alebo kurzor iba z hlavnej scény.
   Test v `cargo test -p latte-goo`: dve inštancie, jedna nad dockom.
6. **Caps Lock všade (F27, D5)** — `goo/parts/lock.plm` doplniť `kb_lock` + text, `goo/lib/lock.luau` čítať `latte-login locks`
   ako `login.luau`. V `shore.plm:90` Caps Lock väčším písmom (≥ 11 px, krytie ≥ 85 %).
7. **Num Lock „potichu“ (D5, D22)** — rozhodnutie používateľa. Návrh: ukazovať iba **vypnutý** Num Lock (výnimka od nového
   predvoleného stavu). Úprava `shore.plm:91`, `greet.plm:344`, `login-safe.plm:134` (texty `pick`).
8. **Bluetooth scan stop (F2)** — `shore.luau`: `bluetooth.scan false` pri odchode zo stránky `devices` a pri zatvorení panela
   (`card.watch`, `:385`).
9. **Program bez ponuky (F3)** a **tip bez `_status_icon_N` (F5)** — `shore.luau:222–230, 299–300`.
10. **Pravý klik a vrstva 2 na TrayShore (D2, D3, D6)** — `shore.plm`: `on press right` pre sieť, batériu, šípku a klávesnicu,
    `on hover kb_hit`. `shore.luau`: malá ponuka cez `ctx` (Nastavenia › Sieť / Napájanie / Klávesnica, Mapa znakov podľa 10b)
    a riadok „Nastavenia…“ na stránkach panela.
11. **Ponuka plochy (D10, D11 klávesy, F15, F21)** — `desk.luau`:
    - jedna pevná postupnosť položiek pre obe ponuky (iba View/Sort/New navyše pri ikonách),
    - v `bare_menu` položka „Zobraziť ikony na ploche“ (`latte-desktop on`),
    - terminál cez `open.terminal` s priečinkom.
    - `desk.plm`: `on key Menu` a `Shift+F10` → `desk_menu`/`dk_menu`.
12. **Ctrl+klik a Shift+klik na ploche (D14)** — `desk.plm` `on press dk_hit` s modifikátorom (ak ho pleamar zóne dáva),
    `desk.luau` `dk_press` prepína a rozširuje výber.
13. **Nečinnosť a úsporný profil (D32)** — `goo/lib/engine.luau:911`: `powerprofilesctl get` (alebo služba) == `power-saver` → bez hry.
    Tier `safe` ako `software`.
14. **Sklo (D30)** — rozhodnúť a zosúladiť `docs/goo/PRAVIDLA.md` 13, LATTEOS-GOO 13 a `apps/settings.qml:291, 801, 893–895`.
    Prepínač nech pri vypnutí vráti predošlý stupeň, nie natvrdo 3.
15. **SAFE `pcall` (F34)** — `goo/safe.luau:51`.
16. **Slovenčina (L1–L9)** — `goo/lang/sk.plm` a `goo/lib/shore.luau:297` (celé vety namiesto skladania).
    Dátum: v `login.luau`, `lock.luau` a `safe.luau` nahradiť `date %B` mesiacom z tabuľky v genitíve
    (jedna funkcia v `goo/lib/`, údaje zo `sk-dates.json`).
17. **Mŕtve kľúče (D18, D32)** — `system/gooengine.json`: `cursor.mode`, `cursor.lift`, `hardware.fps_calm`, `fps_asleep`
    označiť v `docs/goo/GOOENGINE-2.md` ako nezapojené, alebo odstrániť.
18. **Dokumenty** — LATTEOS-GOO §8 TrayShore (doska je telo goo, D9), §8.2 GOOENGINE-2 (téma `assets/cursors` neexistuje, F23).

### 3.2 Funkcie po 0.6

- **TrayShore:** pretečenie skrytých ikon (D1, F4), upozornenia a dashboard s widgetmi (6H.02, 6H.03, 6H.05), Kofeín (6H.04),
  príboj o dosku (6H.06), ponuka programu ako malá ponuka pri ikone (D8), riadok batérie a profilu v paneli (D4),
  TrayShore v Nastaveniach › Kvapky (6.50).
- **Plocha:** rad ikon v ponuke (pravidlo 23), podponuka vysúvaná bokom (D12), šípky a písanie mena, ponuka pri ťahaní pravým
  (Kopírovať / Presunúť / Odkaz), obrázok témy pri ťahaní (ponytail `desk.luau:57`), rýchlejší `latte-desktop list`
  (jeden `file --mime-type` na všetky súbory naraz), farby podľa šálky (D13, ak sa rozhodne).
- **Kurzor (prerábanie s elasticitou):** téma xcursor „LatteOS Goo“ v `assets/cursors` (§8.2 bod 1), adaptívna farba (§8.3),
  veľkosť a farba aj pre systémový kurzor (9.19), jeden vzhľad kurzora nad popupmi a dockom (D16), meranie oneskorenia (F24).
- **Zámok a prihlásenie:** ovládanie Tabom (D24), počet pokusov a hlásenie faillock (F28), 0 snímok pri zámku v pokoji (F29),
  rozloženie podľa každého monitora (F30), čo ukazovať pred prihlásením (D23).
- **Druhý monitor:** hodiny a spúšťač (D28), prenášanie ikier ťahaním medzi monitormi (§8 „Ešte nie je“), odľahčenie
  `side.plm` (D29), Shore z okraja na okraj (ponytail `shoregrab.plm:6`).
- **Engine:** obmedzenie snímok pri nečinnosti z `gooengine.json` (`hw.fps_calm`, `hw.fps_asleep` do `rate:`).

---

## 4. Na overenie naživo

1. Heslo Wi-Fi: otvoriť Sieť › chránená sieť a písať 10 s. Zmizne pole (F1)? Totéž s ponukou Steam pri hrajúcej hudbe.
2. Dva monitory + DockShore: prejsť myšou nad dock hlavného monitora. Je vidieť kurzor (F22)? `systemctl --user kill latte-goo`
   pri živej bočnej scéne: je na hlavnom monitore kurzor?
3. Zámok s rozložením US, heslo s diakritikou: dá sa prepnúť (Win+Space) počas zámku (F26)?
4. Bezdrôtová klávesnica bez LED: ukáže prihlásenie alebo zámok Caps Lock (F27)?
5. Plocha: 200 súborov, veľké ikony, 1080p (F12, F13). Súbor s `\n` v mene na ploche (F14; iba v skúšobnom účte).
   Malé ikony: dá sa kliknúť na posledný rad pod BarGoo (F16)?
6. `media` watch: ako často chodí správa počas prehrávania (rozsah F1)?
7. Je `covered` pravda počas `ext-session-lock`? Nehrajú sa kvapky za zámkom (D33)?
8. `lockscreen` pri vypnutých obrazovkách: kreslí pleamar ďalej 60 snímok (F29)? Pozrieť `pleamar` CPU/GPU.
9. Zámok na 1366×768 + 2560×1440: sú čas a počasie na menšom monitore (F30)?
10. SAFE: beží riadok aplikácií, keď služba `window` nie je (F34)?
11. Vidí agent pleamar-wm (`pleamar-wm agent`) pole hesla na zamknutej obrazovke (D25)? Overiť iba čítaním stromu, nič nepísať.
12. Ponuka plochy a AppCloud na druhom monitore po nasadení 23. 11. Terminál z `bare_menu` na druhom monitore (`TERMINAL` ≠ foot).
13. Faillock: po 3 a 10 zlých heslách — čo uvidí používateľ (F28)?
14. Goo kurzor na 144 Hz: cítiť oneskorenie hrotu (F24)?
15. `docs/screenshots/desktop.png` je z 30. 10. (ešte QML plocha a stará lišta): pre README nasnímať aktuálnu plochu Goo.
