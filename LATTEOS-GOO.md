# LatteOS Goo (plocha Kvapky)

Spoločný dokument pre používateľa (autora LatteOS) a Clauda: **čo LatteOS Goo je, ako sa má správať a z čoho sa
skladá**. Platí nezávisle od konverzácie. Pred prácou na Goo ho treba prečítať, a keď sa niečo rozhodne,
zapísať ho sem (s dátumom). Technické detaily a zoznam hotových funkcií sú v
[session/kvapky/README.md](session/kvapky/README.md), plán v [ROADMAP.md](ROADMAP.md).

---

## 1. Čo to je

LatteOS Goo (relácia **„LatteOS Kvapky“**) je plocha LatteOS pre ľudí zvyknutých na **Windows 11**, kde lištu,
Štart, hodiny a systémové prvky nahrádzajú **tekuté kávové kvapky**. Kvapky sa správajú ako **sliz v nízkej
gravitácii**: pružia, lepia sa k okraju obrazovky aj k sebe, naťahujú sa a praskajú, žijú vlastným pohybom a
reagujú na kurzor ako živý tvor.

Stojí na:

| vrstva | čo robí | kde |
|---|---|---|
| **Hyprland 0.56** (Lua) | okná, režimy okien (páska, dlaždice, plávajúce), animácie | `session/hypr/` |
| **pleamar 0.2.2** (Rust, SDF, goo) | kreslí všetky kvapky, spúšťač, logika v Luau | `session/kvapky/kvapka.plm`, `kvapka.luau` |
| **Noctalia 5** | ovládacie centrum, panely, widgety a doplnky v rohovej lište, zvuk, sieť, relácia | záplatovaná kópia iba pre Kvapky |
| **latte-kvapky** | štart plochy, konfigurácia Noctalie pre Kvapky, pomocné príkazy | `session/bin/latte-kvapky` |

Názvy: **Goo / Kvapky** = celá plocha; **Goobar** = lišta s oknami (hlava + guľôčky); **kvapka** = každý
samostatný tekutý prvok.

---

## 2. Pravidlá (od používateľa — platia vždy)

1. **Myš je prvá, klávesy iba doplnok.** Každá funkcia musí ísť myšou (klik, ťahanie, koliesko). Super = kláves Windows.
2. **Návyky z Windows 11** rozhodujú: všetko je **dole**, klik na okno v lište prepne/minimalizuje, pravý klik na
   okno = ponuka okna, ťahanie ľavým ako vo Windows. Horná kvapka ako v Marei bola **zamietnutá** (návyk z Windows).
3. **Preberať, nevymýšľať:** najprv hotové riešenie (Noctalia, pleamar, Marea), až potom vlastné.
4. **Preložiteľné:** texty v UI po anglicky + preklad (`translations sk` v scéne, `tr()` v logike), nikdy natvrdo po slovensky.
5. **Každé prostredie má svoje nastavenia:** Goo, klasický LatteOS, pôvodná Noctalia a cudzie prostredia (Plasma…)
   sa navzájom nepoškodzujú (`latte-profil`, oddelené priečinky Noctalie).
6. **Kvapky sú vždy káva.** Téma LatteOS = šálka (materiál okien); obsah = káva s pomerom **vody a mlieka**
   (Barista). Vodová káva (lungo, americano) je sklo, espresso a mliečne kávy nepriehľadné.
7. **Kvapky nemajú oči** (ani žiadnu tvár). Hodiny sú **digitálne** (ručičkové hodiny Marey sa nepreberajú).
8. **Kontextový klik iba tam, kde ho má funkcia.** Ak funkcia kvapky nemá pravý (ľavý) klik, nemá ho ani kvapka.
   Pravý klik v Goobare má zmysel iba na **guľôčkach okien** (ponuka okna, ako vo Windows).
9. **Okno sa zjaví tam, kde je kvapka:** okno/panel z kvapky vyrastie presne nad miestom kvapky na okraji
   (kvapky sa dajú presúvať — musí to platiť kdekoľvek). **Kvapka sa k oknu pripája ROHOM** (1. 10.): vystúpi
   vyššie a okno z nej vyrastie tak, aby bolo **celé vidieť**; keďže sa každá kvapka dá presunúť kamkoľvek
   (**všetky kvapky sú drag & drop**), cieľom pripojenia môže byť **ktorýkoľvek zo 4 rohov okna**.
   Platí pre **vyskakovacie** okná a ponuky (spúšťač, časové menu, PowerGoo, kalendár). **Riadne okná** (App
   Manager, Správca zariadení…) sa nepripájajú — tie rastú z bubliny (pravidlo 14), kvapka ostane na mieste.
10. **Goo má vlastný vzhľad ponúk** (1. 10.): ponuky a okná z kvapiek sa **nepreberajú vizuálne** z klasického
   LatteOS (panely Noctalie). Preberá sa **funkcia** (latte-ai, pohoda, Text Bar, kalendár…), vzhľad je Goo —
   karta z kvapky, tekuté kapsuly, goo bubliny.
11. **Štýl okien Goo** (1. 10., inšpirácia hľadanie Windows 11 a spúšťač Noctalie): **moderné ikony, písma,
   trochu minimalizmu, chytrosť, vkus, užitočnosť.** Farby nie sú cieľ — idú z **témy LatteOS** (farba okien =
   šálka) a karta pri uchu kvapky **prechádza do kávy** (goo). Ikony **Tabler** (písmo Noctalie), písmo **Inter**,
   riadky ako karty (názov + popis), jemné zaoblenia, akcent témy na výbere a okraji poľa.
12. **Materiál a priehľadnosť** (1. 10.): **prechod z kávy do farby okien ostáva**. Na časti karty ďaleko od ucha je
   **reálna textúra materiálu témy** — brúsený hliník, striebro, **tepané zlato** (voľné textúry CC0 z ambientCG,
   tepaný kov vygenerovaný; `session/kvapky/textury.py`). Sklenené témy (Latte, Svetlé sklo, drahokamy, mráz, jantár)
   majú **perleťové dúhové okraje** (pleamar `glass` + `dispersion`). Spúšťač je **čiastočne priehľadný**
   (sklo karty podľa materiálu: sklo 80 %, kov 45 %, klasické témy 0 %).
13. **Okná aplikácií: sklo z Hyprglass** (1. 10., používateľ poslal ukážku „Caelestia + Hyprglass“ z r/unixporn):
   plugin Hyprland `hyprnux/hyprglass` (BSD-3, stavaný na 0.56.2) — lom na okrajoch, dúhová chromatická aberácia,
   matné rozmazanie, odlesk. **Iba plocha Goo a sklenené témy** (`session/hypr/latte/sklo.lua`); okná 93 / 87 %,
   celá obrazovka a herný režim plné a bez skla. Vypnutie `~/.config/latteos/bez-skla`. Okná Goo (spúšťač…) kreslí
   pleamar — sklo a textúry si robí sám; okná aplikácií kreslí Hyprland.
14. **Okno z kvapky sa rodí z bubliny** (1. 10.): kvapka, ktorá otvára samostatné okno (QueenGoo, budúce), ho
   **vypľuje do priestoru ako bublinku**, tá sa zväčší a zmení na klasické okno (posúvateľné, zväčšiteľné,
   minimalizovateľné). **Zatvorenie okna = prasknutie bubliny** (inšpirácia: „Burn My Windows“). **Minimalizácia =
   okno sa zmenší do malej goo kvapky, plynulo padne k ťažisku (lišta dole), žblnkne ako voda a objaví sa v Goobare.**
   Otvorenie hotové 1. 10. (`bublina.py`): kvapka ostane na mieste, vytlačí kvapôčku (zlieva sa s ňou), tá sa
   odtrhne, preletí po oblúku na miesto okna a nafúkne sa na jeho obdĺžnik (z kávy do materiálu okien); logika
   spustí program o 650 ms neskôr a `latte-kvapky okno TITUL X Y W H` povie Hyprlandu (`latte/windows.lua`), aby
   okno postavil presne na bublinu a **bez vlastnej animácie** (`set_prop no_anim`); keď naskočí, bublina zmizne.
   Prasknutie pri zatvorení a pád pri minimalizácii ešte nie sú.
15. **Farby guliek upozornení** (1. 10.): **červená = hardvér** (ako „zariadenie potrebuje pozornosť“ v Správcovi
   zariadení), **zelená = sieť**, **modrá = softvér** (aktualizácie); po otvorení okna je vidieť, čo hlási.
16. **Všetky kvapky sú drag & drop** (1. 10.) — aj Hodiny (TimeGoo) a vypínač (PowerGoo), nielen samostatné kvapky.
   Hodiny a vypínač (hotové 1. 10., `volne.py`): klik bez pohybu = spúšťač / ponuka ako doteraz; potiahnuté (> 8 px)
   idú za kurzorom; pustené ďaleko od lišty sa prilepia k najbližšiemu okraju ako samostatná kvapka (bez vlákien —
   dohoda o spájaní v §3), pustené do 110 px od svojho miesta v lište sa vrátia do nej (prelievanie v trojici).
   Spúšťač, časové menu a ponuka vypínača vyrastú z kvapky, kde práve je. Keď odídu Hodiny, vypínač sa posunie na
   ich miesto. Poloha v `spustac.json` (`timegoo` / `powergoo` = `{ free, side, pos }`).

---

## 3. Fyzika a správanie kvapiek

- **Nízka gravitácia, pružnosť:** kvapky pružia (pružiny pleamaru), zlievajú sa (smooth-min „goo“), dýchajú a
  pomaly driftujú aj bez myši — **neustály vlastný pohyb, nie útek**; vzájomné pôsobenie iba v blízkosti.
- **Lepia sa k okraju a k sebe.** Lišta sa od okraja **sama nikdy neodlepí** — iba keď ju používateľ ťahá.
  Strapce okien sú príliš ťažké na to, aby sa odlepili.
- **Vlákna ako sliz:** keď sa kvapka vzďaľuje (ťahaná guľôčka, Hodiny letiace do ucha), vlákno sa **naťahuje a
  tenčí** a **po určitej dĺžke praskne** (konce sa stiahnu); pri návrate sa znova zlepí.
- **Spájanie vláknami a prelievaním — dohoda 1. 10.:** iba na **vzdialenosti, aké sú medzi vypínačom, Hodinami
  (nezdvihnutými) a lištou** — tam prelievanie funguje výborne. Keď TimeGoo po kliku stúpa, krk sa **naťahuje a
  tenčí, až stratí kontakt** — ostane **iba samotná kvapka, bez výrastku** (pahýle sa stiahnu a zmiznú). **DaNoGoo a kráľovná sa pri otvorení vznesú bez
  základne** (ostrov na okraji sa stiahne, krk sa natiahne a zmizne).
- **Jedny pravidlá pre všetky kvapky (1. 10., výhrada používateľa):** každá kvapka — lišta, Hodiny, vypínač,
  DaNoGoo, kráľovná, widgety, aj voľne položené — je **v jednom goo tele** (`goo.py`: generátory vkladajú svoje tvary
  do tela lišty, body z obrazovky sa prepočítajú do jej súradníc). Preto sa každá s každou zlieva, keď sú blízko
  (vzdialenosť trojice), a všetky majú **to isté svetlo kurzora** (svetlá škvrna tela, odlesk hore vľavo a na
  strane ku kurzoru), sklo, lem a tieň. Nová kvapka = `goo.kvapka(…)` + `goo.odlesk(…)` + `goo.vloz(…)`, nikdy
  vlastné `body` (iba farebné guľky upozornení a okná majú vlastné).
- **Hladina pri okraji** (z Marey): okraj obrazovky je voda — keď kvapka odíde alebo sa vráti, hladina sa prehne a
  po nej sa rozbehnú **dve vlnky**; po prasknutí krku ostane chvíľu **zvyšková kvapka**.
- **Pohyb kolmo na okraj:** kvapka vystúpi **kolmo od okraja**, späť **padne rovno ako pod ťarchou**, s
  prestrelením a odrazom („odkvapne“), zachveje sa.
- **Živý tvor:** kurzor je pre kvapky to, **po čom túžia** — keď sa priblíži, kvapka sa k nemu **nakloní** (venuje
  mu pozornosť); keď je nad ňou, **mierne sa nafúkne a netrpezlivo pulzuje**. Tvár/obsah sa hoverom **nemení**.
- **Svetlo:** pasívne svetlo v ploche (zhora vľavo, odlesky) + **kurzor ako aktívne svetlo** (svetlá škvrna na
  povrchu, odlesk na strane ku kurzoru; pri skle `shine: pointer`).
- **Nesúmernosť:** nič nie je dokonale pravidelné (šum, rôzne veľkosti, cik-cak strapcov).
- **Neprekrývať okná:** kvapky sa pod oknom zmestia do voľného pásu; strapec sa zhromaždí do výšky iba tam, kde
  nad ním nie je okno, inak sa stiahne k okraju.

---

## 4. Časti plochy a ich správanie

### 4.1 Goobar (lišta s oknami) — dole, naľavo od stredu
- **Hlava** (najväčšia kvapka): obraz aktuálneho režimu okien (páska / nad sebou / dlaždice).
  - ľavý klik = ďalší režim okien; koliesko = páska sa posúva (páska) / ďalšie okno (plávajúce)
  - ťahanie ľavým = presun lišty k inému okraju (pustená uprostred steká späť); pravý klik = nič
- **Guľôčky okien** (strapce po aplikáciách ako ikry; čím viac okien, tým menšie):
  - ľavý klik = prepnúť, aktívne minimalizovať (v **páske** sa neminimalizuje — ako niri)
  - pravý klik = ponuka okna pri kurzore; ťahanie = preusporiadanie aplikácií (vlákno ako sliz)
  - minimalizované okno = menšia, stlmená guľôčka; 48 slotov, nad nimi guľôčka „ďalšie okná“ → prehľad
- Šnúra sa vždy zmestí po kraj (a zastaví sa pred rohovou lištou a kvapkami widgetov).

### 4.2 TimeGoo (Hodiny, Štart) — vľavo pri hlave
- Digitálny čas a dátum. (Upozornenia sa presúvajú do DaNoGoo — 1. 10.; dnes ešte kvapôčky na Hodinách.)
- **Ľavý klik alebo kláves Win** = **spúšťač**: kvapka vystúpi kolmo, stane sa **trčiacim uchom v rohu okna**
  (s časom), okno z nej vyrastie. Zatvorenie (klik inde, Esc) = okno sa zloží do ucha, ucho odkvapne domov.
- **Pravý klik** = **časové menu** (1. 10., vzhľad Goo): tá istá karta z ucha ako spúšťač. Hore veľký čas, dátum a
  týždeň; čipy **Prehľad** (Digitálna pohoda s pruhmi aplikácií — klik = podrobnosti v Monitore, svetové hodiny s
  posunom, najbližší budík / minútka) · **Stopky** (štart/pauza, medzičas, vynulovať) · **Minútka** (kruh: koliesko
  nastaví minúty, klik spustí / pozastaví; predvoľby 1–45 min) · **Budíky** (prepínač, odstrániť; nový myšou —
  koliesko nad hodinou a minútou, Pridať) · ⚙ Nastavenia › Dátum a čas.
  Údaje spoločné s klasickým LatteOS (`casovace.json`, `clock.conf`); **minútku a budíky v Goo stráži a zvoní logika
  Kvapiek** (upozornenie + zvuk), aj keď je menu zatvorené.
- **Well-being = existujúca Digitálna pohoda** z klasického LatteOS (`session/apps/pohoda.qml`, inšpirovaná
  Serpantinumom; dáta `~/.local/share/latteos/pohoda/RRRR-MM-DD.json`, podrobnosti v Monitore › Čas v
  aplikáciách). Nič nové sa nevymýšľa: v Kvapkách beží tiež (predtým ju `latte-kvapky` vypínal), v záložke Čas
  je súhrn dneška (čas pred obrazovkou, 3 najpoužívanejšie aplikácie) a tlačidlo „Podrobnosti v Monitore“ (1. 10.).

### 4.2b DaNoGoo (dátum + upozornenia) — samostatná kvapka, dá sa presúvať (hotové 1. 10.)
- **Hotové (1. 10.):** kvapka s dátumom („st 30. 9.“) a počasím (ikona Tabler + teplota), predvolene dole vľavo
  od rohovej lišty; **ťahaním** k inému okraju (poloha v `spustac.json`); guľky počtu (žlté do 5, červeno-kávová
  s číslom); **hrozno** na lepkavom vlákne (6 najnovších, najnovšia najďalej, „Vymazať všetko (N)“); bobuľa vo
  farbe ikony (`latte-kvapky farba`: prevládajúci odtieň ikony → paleta 16 farieb, pamätá sa v
  `~/.cache/latteos/farby-ikon.json`), systémová výstraha červeno-kávová, bez ikony náhradná; ľavý klik = otvoriť,
  pravý = akcie upozornenia (iba ak má), odhodenie nabok = zahodiť; zatvorí klik na kvapku / Esc / klik mimo.
  Bublina nového upozornenia vyteká z DaNoGoo; upozornenia už nie sú na TimeGoo. Generátor `session/kvapky/danogoo.py`.
- **Viditeľný obsah:** dátum a počasie.
- **Guľky počtu upozornení:** systémové výstrahy vlastná **červeno-kávová** guľka (+ číslo, ak ich je viac);
  ostatné jednotne **žlté**, viac guliek podľa počtu.
- **Ľavý klik** = kvapka **vystrelí ako pružina** kolmo od okraja a za sebou nechá **hrozno upozornení** na
  lepkavom vlákne (najnovšie hore). Hrozno prekrýva okná, kým sa klikom na DaNoGoo nevráti dole.
  Bobule = kapsuly (ikona, aplikácia, nadpis); ľavý klik otvorí, pravý iba ak má upozornenie akcie, odhodenie = zahodiť.
  Farby: systémové/varovné červeno-kávové, nedôležité obyčajná káva, aplikácie podľa ikony — **otvorené:**
  čistá farba ikony, alebo káva zafarbená do nej; zatvárať aj Esc / klikom mimo?
- **Pravý klik** = **karta kalendára a počasia** (hotové 1. 10., vzhľad Goo): vyrastie z kvapky (goo krk), mesiac od
  pondelka (šípky, koliesko, Dnes; bodka = udalosť), udalosti a úlohy vybraného dňa (spoločné s klasickým LatteOS:
  `events.json`, `todo.json`), nová udalosť „10:30 Porada“, úloha „! úloha“; pravý klik na udalosť = zmazať, klik na
  úlohu = hotovo. Dole **počasie** (1. 10. presunuté z TimeGoo): miesto, Dnes / Zajtra / Týždeň, predpoveď.
  Prepojené kalendáre (Google, iCloud, CalDAV, ICS) cez Noctaliu — v bode C.
- **Farby upozornení** (1. 10., voľba A): **čistá farba ikony aplikácie** (nie káva dofarbená).
- **Hrozno zavrie** klik na DaNoGoo, **Esc aj klik mimo** (1. 10.).

### 4.3 Spúšťač (okno z Hodín) — náčrt používateľa 1. 10.
Karta z ucha TimeGoo, zhora nadol:
- **Pole s ikonou režimu.** Ikona na začiatku poľa mení obsah: **Ai** (prompt), **lupa** (aplikácie), **priečinok**
  (súbory, `fd`), **web** (vyhľadávač), **terminál** (Linux príkaz). Klik na ikonu = z nej vytečie tekutý stĺpec
  režimov; koliesko nad ikonou ich točí; Tab = ďalší (doplnok). Režim si pamätá (`spustac.json`).
- **Obsah režimu:**
  - aplikácie: bez textu obľúbené zvolenej záložky (6 × 3), s textom aplikácie + kvapky widgetov + riadky
    „hľadať v súboroch / na webe / opýtať sa AI“ (prepnú režim, text ostane);
  - súbory: bez textu priečinky domova, s textom `fd` (Enter otvorí, pravý klik = priečinok, v ktorom je);
  - web: riadok pre každý vyhľadávač, predvolený prvý;
  - Linux príkaz: beží v `latte-terminal`; nebezpečné príkazy (zoznam z Text Baru) chcú **druhý Enter**; história;
  - AI: **rozhovor v goo bublinách**, najnovšia navrchu pri poli (používateľ mlieko vľavo, AI káva vpravo,
    chvostík ku poľu); kým AI píše, pulzuje kvapka „• • •“ (klik = zastaviť); koliesko roluje; pravý klik = kopírovať.
- **Riadok režimu** (nad počasím): aplikácie → **záložky** obľúbených + „+“ (pravý klik = premenovať/posunúť/odstrániť);
  AI → **Nastavenia · služba ▾ · model ▾ · Nový rozhovor**; web → vyhľadávač ▾; súbory → Otvoriť Súbory;
  príkaz → Otvoriť terminál, Vymazať históriu. Rozbaľovacie ponuky sa otvárajú nahor.
- **AI = `latte-ai`** z klasického LatteOS (Nastavenia › Softvér › AI): webové čety (odpoveď v prehliadači s
  prihlásením), Ollama, domáci server, cloud s kľúčom (Claude, ChatGPT, Gemini, Mistral). Rozhovor ide ako JSON
  v argumente (`latte-ai chat '[…]'`), chyba sa vráti na stdout a ukáže v bubline.
- ~~Úzky riadok počasia~~ — **počasie je od 1. 10. v DaNoGoo** (náhľad na kvapke, podrobnosti v jej karte);
  riadok čipov je úplne dole a obsah má viac miesta.
- Aplikácie bez textu: **obľúbené ako dlaždice** (6 × 2) a pod nimi **Nedávne** (2 × 2, naposledy spustené), ako vo
  Windows. Vzhľad generuje `session/kvapky/spustac.py` (farby 14 tém, ikony → `ikony.luau`).
- Upozornenia v spúšťači už nie sú (idú do DaNoGoo). Zámerne **nie** katalóg aplikácií ani prepínanie okien (Goobar).

### 4.4 PowerGoo (vypínač) — vľavo od Hodín (hotové 1. 10.)
- Ľavý klik = **okno Goo pripojené rohom** (kvapka vystúpi ako ucho): **Nastavenia**, **Monitor**, pod čiarou
  Zamknúť, Odhlásiť, Uspať, Reštartovať, Vypnúť (ikony Tabler); akcie vypnutia robí Noctalia. Generátor
  `session/kvapky/powergoo.py`.
- **Batéria (notebook):** v hlavičke okna percento a stav; na kvapke **minibublinky** 3 zelené (≥ 60 %), 2 žlté
  (≥ 30 %), 1 červená; pod 10 % netrpezlivo pulzuje, pri nabíjaní stúpajú a klesajú. Na stolnom PC žiadne.

### 4.4b QueenGoo — kráľovná (hotové 1. 10.)
- Kvapka s **korunkou** (zlatá ikona na vonkajšej strane, natočená podľa okraja; tvar ostáva kvapka — tvar koruny
  je k4ditanov). Vnútri ikona aplikácií. Guľky (pravidlo 15): **červená** = zariadenia, ktoré potrebujú pozornosť
  (`latte-devices list` → `faults`), **zelená** = výpadok siete, **modrá** = čakajúce aktualizácie (`latte-apps updates`).
  App Manager sa pri aktualizáciách otvorí rovno na nich, Správca zariadení pri výpadku siete na Sieťach.
- **Ľavý klik = App Manager**, **pravý = Správca zariadení** — riadne okná, preto (1. 10., používateľ) kráľovná
  **nevyskočí a nestane sa rohom okna**: ostane na mieste a **vypľuje bublinu**, ktorá sa nafúkne na okno vedľa nej
  (pravidlo 14, `bublina.py`); znova klik = okno do popredia. Ťahaním k inému okraju. Generátor `queengoo.py`.
- Naživo overené 1. 10.: bublina z kráľovnej sa nafúkla a App Manager naskočil presne na ňu (1220 × 780).

### 4.5 Rohová lišta Noctalie — vpravo dole
- Iba **pravá časť** lišty Noctalie, **natvrdo prilepená** do rohu, **šírka podľa počtu widgetov**; vpravo sa
  vyduje do bočnej steny, vľavo sa rozleje po spodnom okraji.
- Obsahuje ikony programov na pozadí (Discord…), sieť, hlasitosť, ovládacie centrum; **ďalšie widgety a komunitné
  doplnky** Noctalie sa pridávajú v jej nastaveniach a bežia natívne.
- Kliky widgetov presne podľa Noctalie. Panely sa otvárajú pri lište.
- Plán: priehľadné pozadie + goo telo z pleamaru pod ňou (vlnenie celej lišty pri zmene stavu, pulzovanie).

### 4.6 Samostatné kvapky (widgety, ikony programov)
- Mechanizmus pre **iné veci** (napr. rozbaľovacia ponuka rýchleho spúšťania); predvolene žiadne.
- Visia z okraja, **ťahaním sa presúvajú** k inému okraju (prilepia sa), pustené uprostred stečú (odstránia sa);
  pridať cez spúšťač. Kliky podľa Noctalie; panel sa otvorí pri kvapke.

### 4.7 Okná (Hyprland)
- Režimy: **nekonečná páska** (ako niri: nič sa neminimalizuje, pohyb animovaný aj bez efektov, dlaždice v páske
  ťahaním za titulok), **dlaždice**, **plávajúce** (ako Windows).
- Okná neprekrývajú lištu (vyhradený pás pri okraji), maximalizované tiež.

### 4.8 Mimo plochy
- Prihlasovacia obrazovka latteGoo s výberom relácie; Sunshine beží už pred prihlásením (virtuálny monitor EDID).
- Relácie na pokusy: Noctalia (čistá), **Marea kompletná (pleamar-wm, k4ditano)** — kompletný autorov ekosystém
  (kompozitor pleamar-wm, Marea, jeho portály a profil `~/.config/pleamar`, najnovšie verzie; 1. 10.), Marea
  (Hyprland), Serpantinum — oddelené od LatteOS (`setup/lab/marea-povodna.sh`, `latte-marea`).

---

## 5. Čo bolo zamietnuté (a prečo)

| nápad | rozhodnutie |
|---|---|
| oči na kvapkách, tvár | nie (29. 9.) |
| horná kvapka ako Marea | nie — návyk z Windows: všetko dole (29. 9.) |
| textúry kvapiek, farby podľa témy | nie — kvapky sú vždy káva (voda/mlieko); textúry (zlato, ónyx, kov, ľad) iba ako návrh na neskôr |
| ručičkové hodiny + bočné okienko (Marea) | nie — digitálne hodiny v kvapke (30. 9.) |
| goo guľôčky vnútri dashboardu | nie — nepôsobili dobre (30. 9.) |
| vzhľad ponúk z klasického LatteOS v Goo (záložka Čas) | nie — Goo má vlastný vzhľad ponúk (1. 10.) |
| jedno pole hľadá všetko naraz | nahradené ikonou režimu (náčrt 1. 10.) |
| klik odlepí lištu | nie — odlepí iba ťahanie |
| celý strapec sa fyzicky oddelí od okraja | nie — strapce sú ťažké, drží ich okraj |
| minimalizovanie v páske | nie — ako niri (30. 9.) |
| holý Hyprland a gamescope-session v zozname relácií | skryté — nedá sa z nich odísť myšou |
| kód komunitných doplnkov Noctalie v pleamare | nie — stav doplnku je v Noctalii; namiesto toho rohová lišta Noctalie |
| sieť slizu k vzdialeným objektom (všeobecný sliz, vejár vláken, sliz.py) | nie — neprirodzené; spájanie iba na vzdialenosti trojice vypínač–Hodiny–lišta (1. 10.) |

---

## 6. Kde čo je (pre Clauda)

| čo | kde |
|---|---|
| scéna (kreslenie, pružiny, pravidlá, preklady) | `session/kvapky/kvapka.plm` |
| logika (okná, spúšťač, kvapky widgetov, počasie) | `session/kvapky/kvapka.luau` |
| počet guľôčok okien (goo telo nedovolí `repeat`) | `python3 session/kvapky/sloty.py N` + `SLOTS` v logike |
| kvapky widgetov | `python3 session/kvapky/widgety.py N` + `WMAX` v logike |
| jedno goo telo pre všetky kvapky (prepočet súradníc, odlesky) | `session/kvapky/goo.py` (modul generátorov) |
| voľné Hodiny a vypínač (ťahanie, zóny, skrytie v lište) | `python3 session/kvapky/volne.py` (po `spustac.py`, `powergoo.py`) |
| štart plochy, Noctalia pre Kvapky, `uloz`, `panel-poloha`, `roh-sirka`, `okraj` | `session/bin/latte-kvapky` |
| relácia, profily prostredí | `session/bin/latte-session`, `latte-profil` |
| Hyprland (režimy okien, rezerva pri okraji, virtuálny monitor) | `session/hypr/hyprland.lua`, `session/hypr/latte/*.lua` |
| záplaty pleamaru / Noctalie / pleamar-wm | `resources/patches/` (README tam) |
| nastavenia používateľa | `~/.config/latteos/` (kava, spustac.json, kvapky-widgety.json), `~/.local/state/latteos/` (kvapka-okraj, window-mode, kvapky/noctalia) |
| aktualizácie u autorov | `latte-upstream -v` |
| nasadenie na latte-lab | `sudo install … /usr/share/latteos/kvapky/`, reštart pleamaru; setup skripty v `setup/` |

**Skúšanie bez myši a monitora** (`scratchpad/test/t.sh`; scéna sa kopíruje ako `kvapkatest.plm` → soket
`kvapkatest`, **nikdy `pleamar --say kvapka`** — to je živá relácia používateľa, 1. 10. to raz omylom zasiahlo): headless `labwc` (`WLR_BACKENDS=headless`),
tapeta cez `swaybg`, scéna s oddeleným `HOME`; náhradný kurzor `pleamar --say kvapka "fact tcx 700"` / `tcy`,
`fact probe 55` (vysunutie lišty), `emit udalosť hodnota`; snímky `grim`, video `wf-recorder`. **Po teste všetko
zrušiť** (testovací pleamar sa volá rovnako `kvapka` — kolidoval by s reláciou používateľa) a zmazať mŕtve
sokety v `/run/user/1000/pleamar/`.

**Obmedzenia pleamaru**, na ktoré treba myslieť: v `body` nie je `repeat`/`for` (generátory); `let` a `prop` z
`repeat` nevidí `let` mimo neho; text sa vo výrazoch neporovnáva (fakt/bool); elipsa stlačená na nulovú výšku robí
chyby (neaktívne tvary nulovým polomerom); logika nevie zapisovať súbory (`latte-kvapky uloz`). **`show:` na tvare
v `body` tvar neskryje** (iba násobí priehľadnosť, do siluety sa zleje aj tak) — tvar s nulovým polomerom / šírkou
a `blend` nechá bodku či vlásočnicu; skryté tvary lišty preto odchádzajú do stredu hlavy (`hx, mid - 8`).
**Elipsa s nulovým polomerom musí mať sploštenie 1** (`scale: 1, if(aktívna, h / r, 1)`): vzdialenosť elipsy je
`(length(p / scale) - polomer) * min(scale)`, takže pri polomere 0 a sploštení 0,01 je takmer nulová po celej
vodorovnej čiare cez stred — kvapky v okolí sa k nej „lepia“ (krídla na kráľovnej, Hodinách, vypínači, 1. 10.).
`pointer.x` na celoobrazovkovej vrstve klame — `mx`/`my` (Hyprland); počas ťahania zóna cez celú obrazovku
(polomer 4000), inak Hyprland pošle pustenie mimo zóny niekam inam.

---

## 7. Poradie práce (1. 10.: „neskákať, dokončiť rozrobené, potom mechanika Goo a ovládanie myšou“)

Ide sa **po poradí**; nové nápady sa zapíšu na koniec (E), nerozbiehajú sa hneď.

### A. Dokončiť rozrobené
1. ✅ (1. 10.) **Časové menu TimeGoo** vo vzhľade Goo (pravidlá 10–12): karta z ucha ako spúšťač — veľký čas a dátum, čipy
   Prehľad · Stopky · Minútka · Budíky; well-being, časové pásma (`~/.config/latteos/clock.conf`), stopky, minútka,
   budíky zo spoločného `~/.local/share/latteos/casovace.json` (ten istý ako klasický LatteOS). **Minútku a budíky
   musí v Goo strážiť a zvoniť logika Kvapiek** — v klasickom to robí widget hodín na lište Noctalie, ktorý Goo nemá.
2. ✅ (1. 10.) **DaNoGoo** (4.2b) — kvapka, hrozno, karta kalendára a počasia: kvapka s dátumom a počasím, guľky počtu upozornení, ľavý klik = pružina + hrozno upozornení
   (farba ikony aplikácie, zavrie klik na DaNoGoo / Esc / klik mimo), pravý klik = kalendár vo vzhľade Goo; kvapôčky
   upozornení z TimeGoo preč.
3. ✅ (1. 10.) **PowerGoo**: batéria (minibublinky), ponuka vo vzhľade Goo + Nastavenia a Monitor.
3b. ✅ (1. 10., naživo overiť umiestnenie okna) **QueenGoo** (rozhodnuté 1. 10.): kvapka s **korunkou** (tvar ostáva kvapka — tvar koruny je k4ditanov);
   **ľavý klik = premení sa na App Manager** (inštalácia programov), **pravý = Device Manager** (Správca zariadení).
   V Goo dnes nie je, kde inštalovať (spúšťač iba spúšťa).
4. **Ponuka okna** (pravý klik na guľôčku) vo vzhľade Goo.
5. **Hyprglass** overiť naživo (sklenená téma v Goo) a doladiť.
6. **Slovenský katalóg Noctalie** (bez neho Noctalia v LatteOS nenačíta slovenské preklady doplnkov) — pred
   integráciami Noctalie (C).

### B. Mechanika Goo a ovládanie myšou
- **okno z kvapky ako bublina, zatvorenie = prasknutie, minimalizácia = pád do Goobaru so žblnknutím** (pravidlo 14)
- ✅ (1. 10., overené naživo virtuálnou myšou) **presúvanie Hodín a vypínača samostatne** (pravidlo 16)
- goo telo pod rohovou lištou; vlnenie a pulzovanie pri udalostiach (upozornenie, zvuk, sťahovanie, zmena widgetu)
- rozbaľovacia ponuka rýchleho spúšťania ako samostatné kvapky
- všetko myšou: prejsť každú funkciu Goo, či ide bez klávesnice (pravidlo 1), vrátane premenovania záložiek,
  zadania budíka, AI (vloženie / diktovanie?)
- úspora výkonu (pleamar ~18 % jadra: prázdne sloty, 30 Hz v pokoji)

### C. Integrácie Noctalie (selektívne)
- čo z Noctalie má Goo prevziať (funkciou, nie vzhľadom — pravidlo 10), napr. kalendárové účty, história a filtre
  upozornení, schránka, nočné svetlo, OSD, doplnky z komunitného obchodu, klávesnicové rozloženie

### D. Rozhodnúť (používateľ, 1. 10.)
- **Nastavenia (rozhodnuté 1. 10.):** hlavné sú **existujúce Nastavenia z klasického LatteOS**, ale potrebujú veľa
  práce — dizajn, funkčnosť, prehľadnosť. Napr. **tapety sú riešené na viacerých miestach → zjednotiť**; v Goo
  nemajú zmysel veci ako GIF pozadia tlačidiel App Managera; **pridať nastavenia pre Noctaliu, pleamar/Mareu** atď.
- **Odkiaľ systémové nastavenia:** preferované sú **Nastavenia LatteOS** (44 stránok); vybrané položky z nastavení
  Noctalie sa **selektívne integrujú do nášho menu**. Návrh na výber: komunitné doplnky (obchod), widgety rohovej
  lišty, kalendárové účty a pripomienky, filtre a história upozornení, nočné svetlo, OSD, horúce rohy, história
  schránky, šablóny farieb aplikácií, rozloženie klávesnice, polkit.
- **Monitor / správca procesov:** kde v Goo (návrh: systémová ponuka ako Win+X — pozri nižšie).
- **Správca súborov:** či a kde má ikonu (Windows má Prieskumníka pripnutého na lište).
- Návrh: **PowerGoo = systémová ponuka ako Win+X vo Windows 11** (Nastavenia, Monitor, Súbory, Terminál, … a pod
  nimi Zamknúť / Odhlásiť / Uspať / Reštartovať / Vypnúť).

### E. Neskôr / nápady
- AI: úroveň uvažovania („High“ z náčrtu) — `latte-ai` ju zatiaľ nepozná
- **bubliny četov** pre viac kanálov (Messenger, Telegram, Signal, ICQ…) — forma sa ešte premyslí (používateľ);
  nie ako režim spúšťača a **nie spojené s DaNoGoo** (1. 10.)
- materiál aj na oknách aplikácií pri kovových témach (textúra v hlavičke okna — upravený hyprbars)
