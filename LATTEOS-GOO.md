# LatteOS GOO (plocha Kvapky)

> **Smer (rozhodnutie používateľa 5. 10. 2026):** doterajšie „gamerdistro“ sa stáva **LatteOS GOO** — jedinou
> edíciou LatteOS. **LatteOS Classic sa ruší.** Hlavná práca je engine Goo (§3.2, `session/goo`); kvapky sú podľa
> „Novej architektúry“ na konci tohto dokumentu. Kód Classic zatiaľ ostáva, kým ho GOO nenahradí aj ako predvolená
> a núdzová relácia; nové funkcie sa preň nerobia. **Predvolené prihlásenie bude nový engine** — prihlasovanie sa
> ešte prerobí. Verejne sa zatiaľ nič nezverejňuje. Vetva `gamerdistro` je od 5. 10. `main` (starý `main` zrušený).

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
   sa navzájom nepoškodzujú (`latte-profil`, oddelené priečinky Noctalie). (5. 10.: Classic je zrušený — pravidlo
   platí ďalej pre čistú Noctaliu, Mareu a cudzie prostredia.)
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

17. **Farebné jadro** (1. 10. večer): od stredu kvapky prechod z farby do prednastavenej (kávy) — farebné jadro goo
   alebo žiara. **Predvolené použitie: druh upozornenia** (farby podľa pravidla 15: červená hardvér, zelená sieť,
   modrá softvér; + jantárová výstraha, svetlo, iné), môže pulzovať.
18. **Vlnky na hladine** (1. 10. večer): okraj okna/obrazovky je hladina. Môže robiť vlnky ako **kameň hodený do vody**
   (dve vlny sa rozbehnú od miesta dopadu a slabnú, kvapky na nich sa nadvihnú) alebo **vibrácie** (chvenie na mieste).
   Napr. okno, ktoré po minimalizácii padne do lišty (pravidlo 14).
19. **Vietor** (1. 10. večer): náhodný smer, nezávislý od ničoho (nie od počasia); občas zavanie aj keď používateľ
   pracuje a kvapky sa trochu vlnia ako obilie vo vetre. **Menšie kvapky sa na okraji vlnia viac než väčšie.**
20. **Naťahovanie za kurzorom od okraja iba po určitú vzdialenosť** (1. 10. večer): dlhý krk-vlák je nepekný —
   kvapka sa odtrhne skôr. **Návrat k okraju (Marea):** keď sa goo vráti k okraju, akoby vnikla pod hladinu a znova
   sa vynorila.
21. **Oká medzi spojmi kvapiek sú pekné** (1. 10. večer), ale **okrajová čiara musí byť ostrá**, nie rozmazaná —
   pekná čiara ohraničenia. Ako vznikajú (vysvetlenie používateľa): jednotlivé bunky dýchajú a mierne sa hýbu;
   nad otvormi je **vlákno, ktoré spája susedné goo — čím bližšie, tým hrubšie, organické a nepravidelné**.
   Ostrosť rieši záplata pleamar `pleamar-ostre-okraje` (vyhladenie hrany podľa skutočnej zmeny vzdialenosti na
   pixel), teda v ploche Kvapky aj v engine bez zmeny scény.

22. **Kvapky sa nikdy úplne neprekryjú** (1. 10. večer): môžu byť pri sebe a zlievať sa, ale keď napr. ťahaním
   pustím jednu na druhú, jedna sa vždy odsunie od druhej. Hlava Goobaru sa s ostatnými kvapkami spája (TimeGoo),
   ikry okien iba s ňou. **Spresnenie 5. 10. (naživo na latte-lab):** kvapky sa nesmú prekrývať ani vtedy, keď je
   kurzor ďaleko, ani pri hre (nečinnosť) — iba sa dotýkajú a zlievajú. **Zvýraznený okraj je spoločný:** kde je
   Goobar zliaty s inou kvapkou, nesmie medzi nimi ostať deliaca čiara obrysu.

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
- **Pokoj (5. 10.):** kým kurzor nie je nablízku, kvapky na lište si **sadnú** — zasunú sa dole k lište a
  **sploštia sa**; zdvihnú a zaguľatia sa až pri kurzore. („Zasunutie pod hladinu môže byť ešte o pár pixelov
  viac“ — prehĺbené 5. 10. večer.)
- **Gravitácia platí na každú kvapku (5. 10.):** kvapka pustená vo voľnom priestore tam **neostane visieť** —
  spadne rovno dole na hladinu, ponorí sa a vynorí, hladina sa zvlní. **Pád má byť pád, nie výstrel** (5. 10.:
  „rýchlosť pádu je príliš veľká… ako keby bola vystrelená k zemi“): z pokoja, s nízkou gravitáciou, plynulo zrýchľuje.
- **Kvapky sa lepia ku každému okraju, nielen k dnu (5. 10.):** pustená pri ľavom, pravom alebo hornom okraji sa
  k nemu prilepí a správa sa tam rovnako ako dole (sadne si, pri kurzore sa od okraja zdvihne na stopke, zlieva sa
  so susedmi na tom okraji).
- **Živý tvor:** kurzor je pre kvapky to, **po čom túžia** — keď sa priblíži, kvapka sa k nemu **nakloní** (venuje
  mu pozornosť); keď je nad ňou, **mierne sa nafúkne a netrpezlivo pulzuje**. Tvár/obsah sa hoverom **nemení**.
- **Svetlo:** pasívne svetlo v ploche (zhora vľavo, odlesky) + **kurzor ako aktívne svetlo** (svetlá škvrna na
  povrchu, odlesk na strane ku kurzoru; pri skle `shine: pointer`).
- **Nesúmernosť:** nič nie je dokonale pravidelné (šum, rôzne veľkosti, cik-cak strapcov).
- **Neprekrývať okná:** kvapky sa pod oknom zmestia do voľného pásu; strapec sa zhromaždí do výšky iba tam, kde
  nad ním nie je okno, inak sa stiahne k okraju.
- **Základ shellu (1. 10.):** **Goobar, QueenGoo a PowerGoo** tvoria spodnú lištu — vychádzajú z goo maskota Marey
  (k4ditano), ktorý bol jeden na všetko; LatteOS má viac **špecializovaných** kvapiek s možnosťou tvoriť ďalšie.
  Tieto tri sa **nedajú skryť** (iba zmeniť veľkosť); skryť sa dá TimeGoo, DaNoGoo a doplnky (ChatGoo, vlastné).

### 3.1 Živé bytosti — správanie pri nečinnosti (zadanie používateľa 1. 10., návrh)
Kvapky sa majú správať ako **živé bytosti**. Dnes: vlastný pohyb aj bez používateľa (dýchanie, drift), reakcia na
blízkosť myši; **kurzor je druhý zdroj gravitácie a svetla**. Pribudne správanie **iba pri nečinnosti** používateľa:
- **Nečinnosť** (myš aj klávesnica; zdroj ext-idle-notify, napr. hypridle → `$XDG_RUNTIME_DIR/latteos/necinnost`):
  stupne **1** po ~1 min (pokojnejšie dýchanie, kvapky „zaspávajú“), **2** po ~3 min (počasie), **3** po ~6 min (hra).
- **Prebudenie okamžite:** pohyb myši alebo kláves — všetko pružinou späť na svoje miesto (krátke „vyrušenie“:
  zachvenie, kvapky sa otočia ku kurzoru).
- **Stupeň 2 — dážď alebo vietor podľa skutočného počasia** (Open-Meteo, už ho máme): **dážď** = drobné goo kvapky
  padajú zhora a dopadajú na spodný okraj → **hladina sa zvlní** (impulzy, ktoré sa šíria ako vlnky z Marey) a s ňou
  **aj pripnuté kvapky** (nadvihnú sa a klesnú s vlnou); **vietor** = pomalé postupné vlny pozdĺž okraja v smere
  vetra, kvapky sa nakláňajú; jasno = pokojná hladina, iba dýchanie. Sila podľa intenzity zrážok / rýchlosti vetra.
- **Stupeň 3 — hra:**
  - **naháňačka:** dve kvapky (napr. QueenGoo a DaNoGoo) sa naháňajú pozdĺž okraja, **zámerne sa zrazia a odrazia**
    (pružný odraz so stlačením — squish, ako pri kliku);
  - **behanie:** kvapka sa odlepí a beží po okraji (ostatné jej uhýbajú a zlievajú sa s ňou pri dotyku);
  - **skákanie:** kvapka preskočí ponad ostatné po oblúku (natiahne sa pri výskoku, sploští pri dopade, vlnky na
    hladine).
  - Po hre sa všetko vráti na svoje miesto; pozícia z Nastavení sa nemení.
- **Kedy nie:** okno na celú obrazovku / hra, uzamknutá obrazovka (`pokoj`), batéria pod 20 % alebo úsporný profil,
  **stupeň Softvér** (llvmpipe: každá snímka ~45 ms CPU) — tam iba stupeň 1 alebo vôbec; počet snímok pri nečinnosti
  obmedzený (napr. 20 fps), aby nečinný počítač nekúril. Vypínač v Nastaveniach › Kvapky („Živé správanie“).
- **Technika (návrh):** jedna funkcia hladiny `vlna(x, t)` (súčet sínusov pre vietor + tlmené impulzy z dopadov)
  posúva `edge` pre každú kvapku podľa jej x; pohyb hry = cieľové body pre pružiny (`prop … ~lively`) z logiky, zrážky
  ako vymenené rýchlosti + `squish`. Robiť naživo na latte-lab (scéna), postupne: nečinnosť → dážď/vietor → hra.

### 3.2 Engine Goo — jedny pravidlá pre všetky kvapky (1. 10., základ hotový, oddelene)

Zadanie používateľa: engine, ktorý zastreší všetky kvapky a nastaví pravidlá všeobecne. Je to rozšírenie pleamar
(„DLC“), ktoré prežije jeho aktualizácie. Programátor aj používateľ môžu kedykoľvek pridať kvapku s vlastným
správaním: reakcie na kurzor, prechod myšou, koliesko, ľavé/pravé/stredné tlačidlo, ťahanie, efekty, gravitáciu,
lepivosť, veľkosť a rezervu na ďalšie efekty.

- Kód: `session/goo` (README.md). Scéna `goo.plm` má **128 miest** (`N` v `gen.py`; Goobar nesie okná ako ikry/hrozno, pri veľkej RAM ich je veľa) cez `repeat`, generátor `gen.py`, logika
  `lib/engine.luau` (register, povahy, predvolené správanie, uloženie, nečinnosť). Kvapky používateľa sú JSON
  (`latte-goo`), kvapky programátorov moduly Luau s háčikmi.
- Iba jazyk pleamar 0.2, bez záplat. Obmedzenie: `repeat` nesmie byť v `body` (telo rozpisuje `gen.py`).
  Lety vnútri `repeat` patria iba svojej kópii, preto sú hodnoty potrebné zvonka pružiny `~0ms` (globálne,
  v tom istom snímku). `sin`/`cos` sú v stupňoch. Veľkosť textu je `číslo × pomer`.
- Relácia **LatteOS Kvapky – engine test** = plocha Kvapky so scénou enginu (`latte-session kvapky-engine`).
- **Spresnenie používateľa (1. 10. večer):**
  - Engine musí dodržať tento dokument (§2, §3).
  - Kurzor kvapky **iba priťahuje, nikdy neodpudzuje**.
  - Pri priblížení kurzora sa kvapky **nadnášajú** (vystúpia od lišty na stopke), približujú sa ku kurzoru
    a susedné sa **prelievajú a spájajú** (ako hrozno pri bubline upozornenia).
  - Kvapky vyskakovacieho okna sa po kliku vznesú a stanú sa tvarom okna. V ploche Kvapky to už funguje dobre,
    do enginu to príde ako druh kvapky.
  - Opravené podľa toho: farby kvapiek preč (pravidlo 6), predvolené pravé, stredné tlačidlo a koliesko preč
    (pravidlo 8), menovka pod kvapkou preč (obsah sa hoverom nemení), stupne nečinnosti 1/3/6 min.
- **Spájanie kvapiek v engine (prevzaté z TimeGoo/PowerGoo/Goobaru):**
  - susedia na lište sa navzájom nadnášajú (30 %) a nakláňajú;
  - spája ich voda pri okraji a goo vlákno;
  - každá má vlastný tok (vystupuje a klesá), sila zliatia sa mení s ním;
  - okraj obrazovky je hladina.
  Porovnanie s pôvodnou trojicou je v `cloud_session_1.md`.
- **Pravidlá 17–21 v engine:**
  - jadro (`d:jadro(farba, sila, pulz)`, JSON `jadro` / `upozornenie`);
  - vlnky (`E.vlnka`, `d:vlnka`, `d:vibruj`, zvonka `pleamar --say goo "emit goo_kamen X"`);
  - vietor (nárazy, smer náhodný, postupná vlna pozdĺž okraja, malé kvapky viac);
  - ponor pri návrate k okraju; odtrhnutie najneskôr po 1,6 polomeru;
  - ostrý okraj (tieň 0, 2, 2).
- **Pravidlo 22 v engine:** stredy dvoch kvapiek ostanú aspoň 0,95 súčtu polomerov od seba (pôvodne 0,72 — veľká
  kvapka vtedy malú skoro celú zakryla; zmenené 5. 10.) (zliatie áno, prekrytie
  nie). Po pustení, pridaní, zmene veľkosti a zmene okien sa jedna plynule odsunie: na lište pozdĺž lišty, voľná od
  druhej. Ustúpi posunuteľná (nie okná Goobaru ani pripnuté TimeGoo a PowerGoo); z dvoch tá, na ktorú pustili.
  Odsúvanie sa reťazí a uloží.
- **Luau `emit` nenesie hodnotu** (iba meno): logika → scéna pre jednu kvapku ide cez počítadlo (fakt + `on change`).
  Skok, stlačenie a ponor predtým trafili iba kvapku na mieste 0; opravené.
- **Goobar a kvapky plochy v engine (1. 10. večer):**
  - **Goobar** (`lib/goobar.luau`) prenesený z Kvapiek: okná ako kvapky s ikonou aplikácie, strapce ako ikry,
    rozvinutie pod myšou, aktívne plnšie, minimalizované stlmené, klik = prepnúť/minimalizovať, pravý = ponuka okna,
    ťahanie = poradie aplikácií, hlava = režim okien, koliesko = páska/ďalšie okno, nad 96 okien „ďalšie okná“.
  - **Ikry okien (spresnenie používateľa 1. 10.):** sú menšie než ostatné kvapky, aby sa s nimi nezamieňali, a lepia sa
    **iba ku Goobaru** — v engine sú vlastná skupina (od 5. 10. v spoločnom tele, pozri nižšie; ikry a ostatné kvapky sa nezlejú),
    slabšie zliatie a takmer žiadnu mláku (bobule s tenkými spojmi). Okná tej istej aplikácie sa zhlukujú do strapca;
    keď by strapec zavadzal otvorenému oknu (okno Hyprlandu je nad ním a siaha k lište), **uhne k okraju** do
    menšieho cik-cak radu pod oknom; keď okno odíde, znova sa zhlukne. Okná nad lištou dáva `latte-goo okna`
    (Hyprland; na skúšky Sway), každých 0,7 s, s hysterézou ako v Kvapkách.
  - **Pomenovanie okien (problém z Kvapiek):** služba `window` dá iba triedu a titulok, bez adresy Hyprlandu.
    Skupina a ikona sa preto hľadajú podľa spúšťača (StartupWMClass, id, koncovka id pre Flatpak, meno).
    Aplikácie LatteOS majú všetky triedu `org.quickshell` → podľa titulku, kým nedostanú vlastné `app_id`.
    Okno sa v Hyprlande hľadá podľa triedy, titulku a poradia.
  - **PowerGoo:** ponuka Goo, batéria guľkami.
  - **QueenGoo:** guľky zariadenia/sieť/aktualizácie, App Manager / Správca zariadení vedľa nej.
  - **DaNoGoo:** dátum, guľky upozornení, zoznam v ponuke.
  - **TimeGoo:** čas, klik = spúšťač LatteOS.
  - Spoločná **ponuka Goo** (karta pri mieste kliku) a **guľky** pre všetky kvapky.
  - **Zatiaľ iba v Kvapkách:** spúšťač Goo, časové menu, karta kalendára a počasia, hrozno upozornení na vlákne,
    let bubliny k oknu (pravidlo 14), okná nad lištou (strapec sa stiahne pod okno).
- **Výkon:** telo goo počíta každý tvar pre každý pixel, aj skrytý. Záplata `pleamar-prazdne-tvary` vyradí tvary
  nulovej veľkosti: v cloude 192 → 21,6 ms na snímku (súčasná scéna Kvapky 62 ms). Bez nej engine funguje, iba
  pomalšie.
- **Overené na latte-lab (5. 10.):** všetky vstupy myšou vrátane stredného tlačidla, podržania a ťahania, ikony,
  ponuky, Goobar s oknami Hyprlandu (ikry, uhýbanie, ponuka okna), upozornenia, nečinnosť. Opravené: ikony
  (`latte-goo ikony`), strácanie ľavého kliku (klik teraz rozhoduje logika z `goo_down`/`goo_up`), ponuka bez
  ikon pri prvom otvorení, bublina cez ponuku. **Výkon:** engine zaťažil RX 640 na 70–77 % (Kvapky 37 %); záplata
  `pleamar-pasy-tela` (pixel počíta iba tvary vo svojom dosahu, obraz rovnaký) to znížila na 35–41 % a záťaž už
  nerastie s počtom kvapiek — „ostrovy“ netreba. Ostáva CPU (asi 1,7× Kvapky). Podrobnosti:
  `docs/goo/ENGINE-REPORT.md` §9–10.
- **Úpravy 5. 10. podľa pozorovaní používateľa na latte-lab:**
  - **jedno goo telo** pre všetko vrátane Goobaru a ikier (druhé telo kreslilo okolo hlavy vlastný obrys aj tam, kde
    bola zliata s TimeGoo); `sk` je už iba skupina — susedia, voda a vlákna v nej; cudzie kvapky drží pravidlo 22
    od ikier ďalej (1,2 súčtu polomerov), aby sa s nimi nezliali;
  - **sadnutie v pokoji** (`sit`): kvapka na lište sa zasunie k hladine (stred ostane aspoň 0,45 polomeru nad ňou,
    aby bolo vidieť obsah) a sploští o 13 %; pri kurzore alebo susedovi sa zdvihne; pri nečinnosti sadne hlbšie.
    Kvapka s prstencom (druh 1) nesadá;
  - **hra pri nečinnosti bez prekrývania:** bežiaca kvapka skočí ponad ostatné, tie jej **uhnú** (reťazovo) a po
    behu sa všetko vráti; pri naháňačke sa iba pritisne (stlačenie oboch) a odrazí späť; dopad sploští a zvlní
    hladinu. Merané 50 s: najmenší rozostup 0,95 súčtu polomerov;
  - **kotva (`pri`) sleduje aktuálnu polohu** kotvy: po potiahnutí hlavy Goobaru idú ikry s ňou, PowerGoo s TimeGoo;
  - **veľkosť 100–220 %** (kolieskom sa dalo zmenšiť na 60 %, obsah potom pretekal).
- **Nová architektúra v engine (5. 10.):** kvapky enginu sú `goobar` (GooBar), `goopower` (GooPower, predtým
  PowerGoo; hlavička ponuky s batériou), `lensgoo` (LensGoo — lupa na mieste Štartu, klik = spúšťač), `queengoo`
  a `clockgoo` (ClockGoo = čas + dátum + upozornenia; ľavý = upozornenia, pravý = čas a pohoda). Jadro má
  `zaklad = true` a nedá sa skryť; voliteľné skrýva Nastavenia › Kvapky (`kvapky.json`, engine ho číta každé 2 s:
  `skryte`, `zoom`, `reset`). Uložené polohy starých kvapiek prešli na nové (timegoo → lensgoo, danogoo →
  clockgoo, powergoo → goopower). GooBar má 48 miest pre okná. `latte-spustac` v engine relácii otvára rýchle
  spustenie (predtým volal scénu `kvapka`, ktorá tam nebeží — klik na Štart nerobil nič).
- **Okraje a gravitácia v engine (5. 10. večer):** každá kvapka má svoj okraj (`ed`: 0 dole, 1 vľavo, 2 hore,
  3 vpravo; v definícii `okraj`); scéna počíta nadnesenie, sadnutie, mláku, stopku, vodu a vlákna kolmo a pozdĺž
  neho. Pustenie: do 130 px od ľavého, pravého alebo horného okraja sa prilepí k najbližšiemu, inak spadne dole
  voľným pádom z pokoja (`GRAV` = 800 px/s² v scéne aj logike: z polovice obrazovky ~1,1 s, z výšky 750 px 1,4 s;
  pôvodne ju ťahala pružina a „vystrelila“ ju), pri dopade ponor ~27 px, sploštenie a vlnka. Nič nevisí vo vzduchu — aj uložená alebo zadaná poloha mimo
  okraja si sadne. GooBar (`vratit`) sa pri pustení uprostred vráti, pri inom okraji sa k nemu prenesie aj s ikrami.
  Susedia, pravidlo 22 a kotvy platia v rámci jedného okraja; hra pri nečinnosti iba dole.
- **Jeden monitor (dočasne):** pleamar má pre všetky kópie scény jeden stav a šírku berie z poslednej, takže na
  druhom monitore s iným rozlíšením boli okraje zle (pravý okraj 640 px od skutočného). Engine sa preto spúšťa iba
  na hlavnom monitore (`latte-kvapky`: `--screen`); vlastný GooBar pre každý monitor je otvorená úloha.
- **Vlákna (5. 10. večer, snímka používateľa):** vzdialenosť krajných kvapiek na snímke je **maximum**, za ktorým sa
  vlákno pretrhne (`THREAD_MAX` 2,3 súčtu polomerov, bolo 2,6); krajné sa ťahali príliš tenko — korene sú hrubšie
  (zliatie rastie s natiahnutím), stred ostáva tenký, najmenej 3,4 px.
- **Rohová lišta Noctalie je pre Goo zakázaná zóna (5. 10.):** má premenlivú šírku (pribúdajú widgety a doplnky
  Noctalie). Engine jej obdĺžnik číta každých 0,7 s (`latte-goo okna` › `roh`) a kvapky, ikry GooBaru, pustenie,
  hrozno aj hra sa pred ňou zastavia; keď sa rozšíri, kvapky ustúpia.
- **Hrozno upozornení ClockGoo v engine (5. 10.):** kvapka-kapsula (`kw` polovica rovnej časti, `t2` druhý riadok),
  lepkavé vlákno (`vlx`, `vly0`, `vly1`, `vlw`), zóna `hr_away`. Bobule sú dynamické kvapky (`visi` — jediná
  výnimka z „nič nevisí vo vzduchu“, iba kým je hrozno otvorené). Na bočnom okraji ostáva zoznam v ponuke.
- **QueenGoo má korunku** (`koruna`, pole `nad`: znak na vonkajšej strane kvapky).
- **Karta času ClockGoo v engine (5. 10.):** karta Goo (`E.menu`) dostala čipy záložiek (`opts.chips`), veľký
  riadok (`big`), pruh priebehu (`bar`), koliesko nad riadkom (`wheel`), riadok, ktorý kartu nezavrie (`keep`),
  a živé obnovenie (`opts.keep`, `E.menuId()`). Čas je v `lib/cas.luau` — prevzaté z časového menu Kvapiek, ten
  istý `casovace.json`; čítanie a zvonenie cez `latte-goo cas` / `zvon`. Všetko myšou: dĺžku minútky a čas budíka
  nastaví koliesko alebo klik.
- **Kalendár a počasie v karte ClockGoo (5. 10.):** mriežka mesiaca (`{ grid = true }`, model `kal`, `E.calendar`),
  textové pole (`{ input = true, submit = … }`, Enter odošle) a klávesnica — kým je otvorená karta alebo hrozno,
  patrí im (`keyboard: exclusive while …`), takže **Esc ich zavrie** hneď. Údaje: `latte-goo kalendar`
  (`events.json`, `todo.json` — spoločné s Kvapkami) a `latte-goo pocasie` (Open-Meteo, miesto z `greeter.conf`,
  20 min v pamäti). Riadok `info` = údaj na čítanie (neklikateľný, ale nie vyblednutý ako `off`).
  Pasca: skrytý `input` berie kliky aj tak — keď ho karta nemá, leží mimo nej (inak zhltol kliky na záložky).
- **Karty z kvapiek — požiadavky používateľa (5. 10. večer):**
  - **koliesko kdekoľvek v otvorenej karte prepína záložky** (riadok s vlastným kolieskom — dĺžka minútky, hodina
    budíka — má prednosť);
  - **okno môže byť väčšie**, stále **minimalistické a futuristicky pohyblivé**; ráta sa s hardvérom nie starším
    než 10 (najviac 15) rokov a **rozlíšením nikdy nie nižším než 1024 × 768**. V engine: riadok 44 px, písmo 15,
    šírka o pätinu väčšia; karta vyrastie z ucha, rám plynulo mení veľkosť, riadky nabehnú postupne, zvýraznenie
    riadku a vybraná záložka kĺžu pružinou; riadky, ktoré by sa nezmestili na výšku, sa nepridajú;
  - **LensGoo sa otvára aj klávesom Windows**, aby sa dali zadať príkazy **aj bez myši**; záložky (režimy) prepína
    **Tab**; v engine navyše Shift+Tab, šípky vyberú riadok, Enter potvrdí, Esc zavrie;
  - **po zadaní príkazu ostane konzola otvorená** (za príkazom beží bežný shell).
- **Ucho a horná hrana okna — pripomienky používateľa (5. 10. neskoro večer):**
  - **ucho ako v starej verzii** (malá bodka pri mieste kliku bola „škaredá“): kvapka, z ktorej okno rastie, vystúpi
    74 px od okraja a sedí v ROHU karty, zliata s ňou, so svojím obsahom (pravidlo 9). V engine `opts.owner`
    (LensGoo, ClockGoo, GooPower); ponuka okna v GooBare má ďalej iba kvapôčku pri mieste kliku;
  - **horná hrana popup okna nesmie skákať** pri prepínaní funkcií a záložiek — platí pre všetky okná Goo. Karta so
    záložkami má pevnú výšku (`opts.height`: spúšťač 600, karta času 690), ostatné sa počas otvorenia iba zväčšujú.
- **Pravidlo 14 v engine (5. 10.):** okno z bubliny (`E.bubble`, prevzaté z `bublina.py`; QueenGoo), prasknutie
  zatvoreného okna z bubliny (`E.pop`) a pád minimalizovaného okna do GooBaru: Hyprland to oznámi hneď
  (`latte.goo_min` v `skratky.lua` → `wm.x/y/w/h` + `win_min`), okno sa zmenší do kvapky a voľným pádom spadne
  k lište, hladina sa zvlní. Okno na inom monitore sa ignoruje (engine beží iba na hlavnom).
- **Okno spúšťača LensGoo v engine (5. 10.):** `lib/spustac.luau` nad kartou Goo — režimy Aplikácie, Súbory, Web,
  Terminál, AI; pomocníci `latte-riadok`, `latte-hladaj`, `latte-ai` a `spustac.json` sú tie isté ako v Kvapkách.
  Karta: ikona aplikácie v riadku (`img`), pravý klik (`right`), odsek v bubline (`para`), písanie (`change`).
- Ďalej: znížiť CPU enginu, potom preniesť okná z kvapiek do enginu (LensGoo spúšťač, karta a hrozno ClockGoo,
  bublina QueenGoo) a ChatGoo (po jednej, snímky pred a po). Živé bytosti z 3.1 (dážď/vietor) a formulár
  v Nastaveniach › Kvapky pribudnú nad enginom.

### 3.3 Prístupnosť — ovládanie Goo z klávesnice (návrh schválený 5. 10., ZATIAĽ NEVYTVORENÉ)

Návrh používateľa, upravený po zhodnotení (používateľ: „beriem tvoje návrhy, spíš to do dokumentu, ale ešte
nevytváraj“). Myš ostáva prvá (pravidlo 1); toto je doplnok pre prácu bez myši a pre ľudí, ktorí myš nepoužívajú.

**Režim sa zapína skratkou a je dočasný** — kým Goo drží klávesnicu, nedá sa písať do aplikácií, preto sa doň vstupuje
a vystupuje sa z neho klávesom Esc.

| Akcia | Kláves | Poznámka |
|---|---|---|
| vstup do Goo | **Win+T** | ako „prejdi na panel úloh“ vo Windows. Pôvodný návrh Win+A je obsadený: v LatteOS aj vo Windows 11 otvára Rýchle nastavenia |
| medzi kvapkami | **← →** | na bočnom okraji **↑ ↓** (s popup oknami nekoliduje — tie sú vtedy zavreté) |
| ľavý klik | **Enter**, **medzerník** | medzerník iba mimo textového poľa (v poli píše medzeru) |
| pravý klik | **Menu** alebo **Shift+F10** | zaužívané klávesy pre kontextovú ponuku |
| v popup okne | **↑ ↓** riadky, **Tab / Shift+Tab** záložky, **Enter** potvrdí | Tab ostáva Tab (v engine už hotové) |
| koliesko | **+** a **−** | veľkosť kvapky, dĺžka minútky, hodina budíka |
| presun kvapky | **Ctrl+šípky**, **Ctrl+Home** vráti na miesto | náhrada ťahania |
| späť | **Esc** zavrie popup, druhý **Esc** opustí režim | |

**Zamietnuté z pôvodného návrhu (a prečo):**
- **AltGr ako ľavý klik** — na slovenskej klávesnici sa cez AltGr píšu znaky @ # { } [ ] € \ |; kolidovalo by to s písaním
  v spúšťači a v poli kalendára, a samotný modifikátor sa spoľahlivo odchytáva iba pri pustení.
- **medzerník ako pravý klik** — medzerník je všade „stlač tlačidlo“ (ľavý klik); kto ovláda počítač klávesnicou, ním
  inštinktívne potvrdí a dostal by ponuku namiesto akcie.

**Viditeľný výber (používateľ 5. 10.):** vybraná kvapka **pulzuje farbou s plynulým prechodom — svetlejšia hnedá**.
Rozdiel je v jase, nie v odtieni, takže stačí aj farboslepému. (Návrh k tomu: vybraná sa zdvihne a ukáže bublinu
s názvom ako pri myši — netreba nový prvok.)

**Ešte treba pri tvorbe doriešiť:** obmedzenie pohybu (pleamar ho vie vypnúť: pružiny doskočia hneď), väčšie písmo
a kontrast, prípadne čítanie názvov nahlas.

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

### 4.2c ChatGoo — addon pre Beeper (zadanie používateľa 1. 10., scéna ešte nie je)
- **ChatGoo je iba addon**, nie vlastný messenger: zastrešuje **pôvodný Beeper pre Linux** (AppImage, prípadne
  neoficiálny Flatpak). Kvapka sa ukáže, keď je Beeper nainštalovaný alebo beží.
- **Minimalizácia Beepera = okno vtečie do kvapky ChatGoo** (namiesto guľôčky na lište); klik na kvapku ho vráti
  (`latte-chatgoo prepni`, mechanika `latte.win.minimize_addr` / `activate`, plocha `special:minimized`).
- **Správy okolo kvapky podľa rovnakých pravidiel ako upozornenia pri DaNoGoo:** upozornenia aplikácie „Beeper“ sa
  presmerujú z DaNoGoo k ChatGoo — guľky počtu, hrozno na lepkavom vlákne, bobule vo farbe (tu: odznak služby/odosielateľ),
  ľavý klik = otvoriť rozhovor (predvolená akcia upozornenia → Beeper otvorí chat), pravý = akcie (ak má), odhodenie
  = zahodiť, bublina novej správy vyteká z ChatGoo. Neprečítané aj z titulku okna (`unread` v `latte-chatgoo stav`).
- **Technika (návrh):** generátor ako `danogoo.py` s vlastnou predponou (`cg.`), aby sa mechanika nekopírovala ručne;
  poloha a presun ťahaním ako DaNoGoo; robiť naživo na latte-lab (scéna sa nedá overiť v cloude).
- Pomocník hotový: `session/bin/latte-chatgoo` (stav, ukaz, skry, prepni, ziskat).

### 4.2d Nastavenia › Kvapky (Goo) — zadanie používateľa 1. 10.
- Nastavenia ukazujú v Goo iba spoločné stránky + **Kvapky (Goo)**; stránka **Lišta a systémové menu** je iba v Classic
  (a naopak) — `only: "goo" | "classic"` v `areasAll` (nastavenia.qml).
- **Kvapky (hotové 1. 10.):** TimeGoo, PowerGoo, DaNoGoo — klik na kartu skryje / ukáže (skrytá = veľkosť 0), Veľkosť
  100–220 %, Vrátiť na miesto. Goobar a QueenGoo zatiaľ vždy (skrytie po úprave ich scény). Súbor
  `~/.config/latteos/kvapky.json` (skryte, zoom, reset, chatgoo, vlastne), logika ho číta každé 2 s.
- **ChatGoo nie je nutná:** voľba „Kvapka ChatGoo“ alebo „Bez kvapky — ikona Beepera v rohovej lište Noctalie“.
- **Vlastné kvapky (hotové 1. 10.):** názov, ikona (téma ikon alebo obrázok), príkaz po kliknutí, voliteľný príkaz pre text
  (prvý riadok, 8 znakov, obnova v s); správajú sa ako kvapky widgetov (ťahanie k okraju, pravý klik → nastavenia).

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
- **Rozhovor s AI VŽDY vnútri, nikdy v prehliadači** (1. 10., používateľ, záväzné): keď si vyberiem napr. Claude
  alebo Gemini a napíšem otázku, nesmie sa otvoriť okno prehliadača — celá diskusia beží v bublinách spúšťača.
  A to **bez API kľúča**, s prihlásením cez predplatné, ako to robí rozšírenie Claude Code vo VS Code a ďalšie
  aplikácie: tie spúšťajú oficiálny nástroj príkazového riadka prihlásený účtom používateľa. Teda nový druh
  poskytovateľa v `latte-ai` (namiesto „web“): **Claude** = `claude -p` (Claude Code, prihlásenie Claude účtom,
  výstup `--output-format stream-json` → bubliny po kúskoch), **Gemini** = `gemini` CLI (prihlásenie Google
  účtom), **ChatGPT** = `codex exec` (prihlásenie ChatGPT účtom); prihlásenie raz z Nastavení (otvorí ich vlastné
  prihlasovacie okno), potom už iba vnútri. Režim „web“ (otvorenie stránky) zostane iba ako posledná možnosť.
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
| nasadenie na latte-lab | `sudo install … /usr/share/latteos/kvapky/`, reštart pleamaru; setup skripty v `setup/`. **Súbory Hyprlandu atomicky** (`install` do `.nazov.new` + `mv`): Hyprland ich sleduje a načíta aj napoly vymenené („cannot open … hyprland.lua“) |

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
4. ✅ (1. 10., overené naživo) **Ponuka okna** (pravý klik na guľôčku) vo vzhľade Goo: funkcie z klasickej ponuky
   okna (`latte.okno.*`: Obnoviť, Minimalizovať, Maximalizovať, Rozloženie ›, Vždy navrchu, Presunúť na plochu ›,
   Zavrieť), vzhľad Goo — karta pripojená rohom ku guľôčke, rastie od okraja, pri rohu káva; podponuky sa vnoria
   (‹ Späť). Je to **spoločná ponuka Goo** (`menu()` v logike, kreslí `spustac.py`): ikony, skratky, zaškrtnutie,
   červená položka, oddeľovač — rovnako ju majú widgety, čipy, nedávne, hrozno a kalendár.
5. ✅ (1. 10.) **Hyprglass** naživo (téma Svetlé sklo v Goo): sklo sa **nenačítalo** — `hl.plugin.load` počas
   načítania konfigurácie Hyprglass nenačíta, za behu áno. Oprava v `latte/sklo.lua`: načíta a nastaví sa ešte raz
   po `hyprland.start` a `config.reloaded`; pri téme bez skla sa iba vypne (`enabled = false`, neodpája sa), herný
   režim rešpektuje. Overené po reload-e (lom a dúhový lem na okrajoch okien); studený štart sa overí pri ďalšom
   prihlásení.
   Potom (používateľ: „žiadne okno nemá efekt glass“): pri krytí 93/87 % a plnom pozadí aplikácií sklo nebolo
   vidieť — teraz 86/78 %, hrubší perleťový lem (0,12), silnejší lom a dúha. Studený štart overený (nová relácia
   po páde o 08:03 mala Hyprglass načítaný sám). Pád Hyprlandu o 08:03: skončil „riadne“ a spadol v deštruktore
   zdieľania obrazovky (SIGSEGV pri exit) — príčina ukončenia nezistená (odhlásenie?); sledovať.
6. ✅ (1. 10.) **Slovenský katalóg Noctalie** `session/noctalia/translations/sk.json` (→ `/usr/share/noctalia/assets/
   translations/`, `install-session.sh`): Noctalia bez `sk.json` bežala celá po anglicky a nenačítala ani preklady
   doplnkov. Preložené všetko okrem sekcie Nastavenia (876 z 2987; Nastavenia Noctalie prídu s redizajnom D —
   dávky `sk-*.tsv` + `zluc.py`); chýbajúci kľúč Noctalia berie z angličtiny. Naživo: `language: sk`.

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
- **AI vnútri bez API kľúča** (1. 10., záväzné — pozri 4.3): poskytovatelia cez prihlásené CLI (Claude Code,
  Gemini CLI, Codex) namiesto otvárania prehliadača; streamovaná odpoveď do bublín, zastavenie, nový rozhovor
- AI: úroveň uvažovania („High“ z náčrtu) — `latte-ai` ju zatiaľ nepozná
- **bubliny četov** pre viac kanálov (Messenger, Telegram, Signal, ICQ…) — forma sa ešte premyslí (používateľ);
  nie ako režim spúšťača a **nie spojené s DaNoGoo** (1. 10.)
- materiál aj na oknách aplikácií pri kovových témach (textúra v hlavičke okna — upravený hyprbars)

---

# Nová Architektúra prostredia a rozhranie Goo (LatteOS) 2.10.2026 23:55

> **Rozhodnutie používateľa 5. 10. 2026: „ideme podľa novej architektúry“.** Táto časť je záväzná a kde sa líši od
> §4 vyššie (TimeGoo, DaNoGoo, PowerGoo, „základ shellu“ = Goobar + QueenGoo + PowerGoo), platí ona:
> **jadro = GooBar, GooPower, LensGoo** (nedajú sa skryť), **voliteľné = QueenGoo, ClockGoo, ChatGoo**.
> Pravidlá §2 a fyzika §3 platia ďalej. **Engine Goo je už podľa nej** (`session/goo/kvapky/`: `goobar`,
> `goopower`, `lensgoo`, `queengoo`, `clockgoo`); scéna plochy Kvapky (`kvapka.plm`) ostáva pri starých menách,
> kým ju engine nenahradí. Stav prenosu: `docs/goo/ENGINE-REPORT.md` §11.

Dokumentácia konceptu, funkcionality a systémového backendu pre používateľské rozhranie založené na kvapkách (Goo).

---

## 1. Základné systémové kvapky (Core Goo)

Základné kvapky sú pevne integrované do rozhrania a nie je možné ich v nastaveniach deaktivovať.

### GooBar (Hlavná lišta a správca okien)
Nezrušiteľná základná kvapka. Zabezpečuje správu plochy, prepínanie okien a prácu s viacerými monitormi.

* **Správanie a zhlukovanie:**
  * Z hlavnej kvapky smerom doprava alebo nadol (prípadne reverzne podľa nastavenia `reversed` v nastaveniach) vyrastajú vizuálne odlišné menšie kvapky, ktoré reprezentujú otvorené okná.
  * Ak patrí viacero okien rovnakej aplikácii, zhlukujú sa do strapcov (ako ikry alebo hrozno).
  * Kvapky sa nikdy neodpájajú od okraja obrazovky. Do výšky sa vrstvia len vtedy, ak je z jednej aplikácie otvorených viacero okien.
  * Ak sa okno aplikácie dostane do blízkosti lišty, ikry sa automaticky stiahnu nižšie, aby neprekrývali aktívne okno.
  * GooBar sa spája s inými kvapkami výhradne zo strany, kde nevyrastajú ikry okien.
  * **Usporiadanie:** Lišta sa vždy zmestí po kraj obrazovky a zastaví sa pred rohovými prvkami a widgetmi.
  * **Multi-monitor:** Každá obrazovka má vlastný GooBar. Okná aj ikry je možné plynulo prenášať medzi monitorovými plochami.

* **Hlava (Najväčšia kvapka):**
  * Zobrazuje aktuálny režim správcu okien (páska / nad sebou / dlaždice).
  * **Ľavý klik:** Prepnutie na ďalší režim okien.
  * **Koleso myši:** V režime pásky posúva pásku okien; v režime dlaždíc alebo plávajúcich okien prepína medzi oknami (funkcia Alt+Tab).
  * **Ťahanie ľavým tlačidlom:** Presun lišty k inému okraju obrazovky (pri pustení uprostred plochy sa vráti späť k okraju).

* **Guľôčky okien / Ikry (Strapce aplikácií):**
  * S rastúcim počtom okien sa veľkosť ikier automaticky zmenšuje.
  * **Ľavý klik:** Prepnutie na okno alebo jeho minimalizácia (v režime pásky sa okno neminimalizuje).
  * **Pravý klik:** Kontextová ponuka okna pod kurzorom.
  * **Ťahanie:** Reorganizácia aplikácií (vlákno sa správa ako tekutý sliz).
  * **Minimalizované okno:** Menšia a vizuálne stlmená guľôčka. Kapacita je 48 slotov; pri vyššom počte sa zobrazí zberná guľôčka pre prehľad zvyšných okien.

---

### GooPower (Napájanie a systémový monitor)
Základná kvapka pre správu relácie, výkonu a batérie.

* **Interakcia:**
  * **Ľavý klik:** Vystúpi rohožkové okno Goo spojené s kvapkou. Obsahuje *Nastavenia*, *Monitor systému* a sekciu spravovanú službou Noctalia (*Zamknúť*, *Odhlásiť*, *Uspať*, *Reštartovať*, *Vypnúť* s ikonami Tabler).
  * Generátor rozhrania: `session/kvapky/powergoo.py`.

* **Indikácia batérie (Notebooky):**
  * Hlavička okna zobrazuje presné percento a stav nabíjania.
  * Na samotnej kvapke sa zobrazujú mini-bublinky:
    * 3 zelené bublinky: nabitie >= 60 %
    * 2 žlté bublinky: nabitie >= 30 %
    * 1 červená bublinka: nabitie < 30 %
    * Pri poklese pod 10 % kvapka netrpezlivo pulzuje.
    * Pri nabíjaní bublinky animovane stúpajú a klesajú.
  * Na stolných počítačoch je indikátor batérie skrytý.

---

### LensGoo (Univerzálny spúšťač a Lupa)
Nezrušiteľná základná kvapka označená ikonou lupy, ktorá slúži ako vyhľadávač, spúšťač a rozhranie pre AI.

* **Režimy vyhľadávania (Pole s ikonou):**
  * Kliknutím na ikonu režimu vytečie tekutý stĺpec možností. Prepínanie je možné aj kolieskom myši nad ikonou alebo klávesom Tab.
  * Zvolený režim sa ukladá do `spustac.json`.
  * **Aplikácie (Lupa):** Bez textu zobrazuje obľúbené aplikácie (mriežka 6 x 3) a nedávne spustenia (2 x 2). S textom hľadá aplikácie, widgety a ponúka rýchle prepnutie do iných režimov. Podporuje drag-and-drop presun aplikácií priamo do záložiek obľúbených.
  * **Súbory (Priečinok):** Bez textu zobrazuje domovské adresáre. S textom využíva bleskový nástroj `fd` (Enter otvorí súbor, pravý klik otvorí nadradený priečinok).
  * **Web (Web):** Ponúka riadky pre jednotlivé vyhľadávače s predvolenou prvou voľbou.
  * **Terminál (Príkaz):** Spúšťa príkazy v `latte-terminal`. Nebezpečné príkazy vyžadujú potvrdenie druhým stlačením Enter. Obsahuje históriu príkazov.
  * **AI Chat (Prompt):** Konverzácia prebieha priamo vo vnútri spúšťača v goo bublinách.

* **Špecifikácia AI integrácie (`latte-ai`):**
  * **Prísny zákaz otvárania prehliadača:** Všetky konverzácie (Claude, Gemini, ChatGPT, Ollama) bežia výhradne v rozhraní spúšťača bez otvárania webových okien.
  * **Pripojenie bez API kľúča:** Využívajú sa oficiálne CLI nástroje prihlásené používateľským účtom (napr. `claude -p` pre Claude Code so streamovaným výstupom `--output-format stream-json`, `gemini` CLI alebo `codex exec` pre ChatGPT).
  * **Indikácia poskytovateľa:** Vizuálny ukazovateľ vedľa modelu jasne rozlišuje lokálne a cloudové modely (napr. zelená bodka pre lokálnu Ollamu, oranžová pre cloudové rozhranie).
  * Generátor rozhrania: `session/kvapky/spustac.py`.

---

## 2. Rozširujúce systémové kvapky (Optional Goo)

Tieto kvapky je možné podľa potrieb používateľa aktivovať alebo deaktivovať v nastaveniach systému.

### QueenGoo (App Manager a Správca zariadení)
Kvapka označená ikonou korunky na vonkajšej strane (tvar koruny je prispôsobiteľný v nastaveniach).

* **Stavová indikácia (Pravidlo 15):**
  * **Červená bodka:** Zariadenie vyžaduje pozornosť (`latte-devices list` -> `faults`).
  * **Zelená bodka:** Výpadok sieťového pripojenia.
  * **Modrá bodka:** Čakajúce systémové a aplikáciové aktualizácie (`latte-apps updates`).

* **Správanie okna (Pravidlo 14):**
  * **Ľavý klik:** Otvorí App Manager (pri aktualizáciách sa otvorí priamo v záložke aktualizácií).
  * **Pravý klik:** Otvorí Správcu zariadení (pri výpadku siete sa otvorí v sekcii Sietí).
  * **Mechanizmus nafúknutia:** Kvapka sa nestáva rohom okna, ale zo svojej pozície vypľuje bublinu (`bublina.py`), ktorá sa plynule nafúkne na plnohodnotné okno vedľa kvapky (rozmer 1220 x 780).
  * Generátor rozhrania: `queengoo.py`.

---

### ClockGoo (Čas, Kalendár, Notifikácie a Well-being)
Kombinovaná kvapka spájajúca časové funkcie a notifikačné centrum (predtým DaNoGoo).

* **Notifikačný systém (Ľavý klik):**
  * Kvapka sa pružinovo vymrští od okraja a zanechá za sebou visieť hrozno upozornení na lepkavom vlákne (najnovšie hore).
  * Upozornenia prekrývajú okná a zatvárajú sa opätovným klikom na kvapku, klávesom Esc alebo kliknutím mimo ich plochy.
  * Farebné rozlíšenie kapsúl:
    * Varovné a systémové: červeno-kávový odtieň.
    * Nedôležité: neutrálny kávový odtieň.
    * Aplikácie: čisto vo farbe ikony danej aplikácie.

* **Karta času a kalendára (Pravý klik):**
  * Z kvapky vyrastie spojovací krk s kartou.
  * **Sekcia digitálnej pohody (Well-being):** Prebratá zo systémovej aplikácie `pohoda.qml` (dáta v `~/.local/share/latteos/pohoda/`). Zobrazuje celkový čas pred obrazovkou, tri najpoužívanejšie aplikácie a tlačidlo pre podrobnosti v Monitore.
  * **Časové nástroje:** Svetové hodiny, stopky (medzičasy), minútka (kruhové nastavenie kolieskom myši) a budíky. Logika časovačov beží na pozadí prostredníctvom `casovace.json` a `clock.conf`.
  * **Kalendár a úlohy:** Týždenný/mesačný prehľad od pondelka, podpora udalostí a todo úloh (`events.json`, `todo.json`) so synchronizáciou cez CalDAV, Google a iCloud (cez modul Noctalia).
  * **Počasie:** Predpoveď na Dnes / Zajtra / Týždeň.

---

### ChatGoo (Integrácia komunikátora Beeper)
Špecializovaný doplnok pre spravovanie správ a správcu Beeper (AppImage / Flatpak).

* **Správanie:**
  * Kvapka je aktívna len pri nainštalovanom alebo spustenom Beeperi.
  * Pri minimalizácii Beepera okno aplikácie "vtečie" priamo do kvapky ChatGoo namiesto štandardnej lišty.
  * Upozornenia smerované pre Beeper sa automaticky odkláňajú z ClockGoo do ChatGoo.
  * Správy vytvárajú hrozno bublín na lepkavom vlákne s farebným odznakom konkrétnej siete (WhatsApp, Signal, Telegram atď.).
  * Pomocný daemon: `session/bin/latte-chatgoo`.

---

## 3. Návrhy nových kvapiek (Backlog & Koncepty)

* **ClipGoo (Správca schránky):** História kopírovania textov, kódu a obrázkov s možnosťou trvalého pripnutia položiek.
* **MediaGoo (Prehrávač médií):** Kvapka na hladine zobrazujúca práve prehrávané médiá (Now Playing), podcasty a rýchle ovládanie hlasitosti/prehrávania cez MPRIS.
* **PassGoo:** Bezpečné grafické rozhranie pre systémový keyring a správu hesiel.
* **CastGoo:** Rýchle streamovanie obrazovky a médií na externé zariadenia (Chromecast, Miracast, AirPlay).

---

## 4. Architektúra systémového backendu

Pre zabezpečenie bleskového chodu a vysokej spandlivosti netreba programy vytvarat, ale použit existujuce, napr definované Linuxové subsystémy a knižnice:

### Sieťová infraštruktúra
* **NetworkManager (`libnm`):** Hlavný štandard pre automatickú správu Wi-Fi, Ethernetu a VPN profilov (WireGuard, OpenVPN).
* **iwd (Intel Wireless Daemon):** Ultraľahký daemon bez vonkajších závislostí pre rýchle bezdrôtové pripojenia.

### Súborový systém a vyhľadávanie
* **Indexovanie:** `Tracker3` / `Baloo` spustené na pozadí pre metadáta a plnotextové indexovanie.
* **Vyhľadávanie:** `fd` (súbory) a `ripgrep` (obsah) v Ruste pre vyhľadávanie v ráde milisekúnd bez nutnosti veľkých databáz.
* **Abstrakcia VFS:** Využitie `GVFS` (GNOME Virtual File System) a `KIO` pre zjednotený prístup k lokálnym diskom (`/home`, `/mnt`), sieťovým úložiskám (SMB, WebDAV) a MTP zariadeniam.
* **Virtualizácia knižníc:** Systémové cesty sa používateľovi prezentujú cez abstraktnú vrstvu do logických knižníc (Dokumenty, Médiá, Projekty).

### Systémové služby a bezpečnosť
* **Tlač a skenovanie:** CUPS a SANE.
* **Bluetooth:** BlueZ stack.
* **Firewall a bezpečnosť:** `nftables` / `firewalld`.
* **Firmware:** `fwupd` v spojení s Linux Vendor Firmware Service (LVFS).

### Dokumenty, Médiá a Podcasty
* **Prehliadače dokumentov:** `Okular` core knižnice pre univerzálne zobrazovanie PDF, EPUB, MOBI, DjVu a Markdown.
* **Zvukový backend:** GStreamer knižnice.
* **Podcastový engine:** RSS parser na pozadí s automatickým sťahovaním nových epizód, správa prehratého času a automatické čistenie starých súborov (napr. po 7 dňoch).
