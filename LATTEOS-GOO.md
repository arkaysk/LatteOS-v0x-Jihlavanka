# LatteOS GOO

Spoločný dokument pre používateľa (autora LatteOS) a Clauda: **čo LatteOS GOO je, ako sa má správať a z čoho sa
skladá — tak, ako to platí teraz.** Pred prácou na Goo ho treba prečítať. Keď sa niečo rozhodne, opraví sa tu
platné znenie a rozhodnutie sa s dátumom zapíše do denníka [docs/goo/ROZHODNUTIA.md](docs/goo/ROZHODNUTIA.md)
(aj čo bolo zamietnuté). Plán a otvorené úlohy: [ROADMAP.md](ROADMAP.md) (F3·G). API enginu:
[session/goo/README.md](session/goo/README.md). Znenie pred rozdelením (6. 10. 2026) je v
[docs_zaloha/](docs_zaloha/README.md).

> **Smer:** LatteOS GOO je **jediná edícia** LatteOS (Classic je zrušený, 5. 10. 2026). Na systém sa nasadzuje
> **iba engine Goo** (`session/goo`); pôvodná plocha Kvapky (`session/kvapky`) sa už nenasadzuje (6. 10.).
> Predvolené prihlásenie bude engine Goo — prihlasovanie sa ešte prerobí (§6.2). Verejná kópia `arkaysk/latteos`
> je zastaraná (stav 29. 9., pred GOO); po dokončení enginu Goo sa zverejní **verejná verzia 0.2** iba s GOO.

---

## 1. Čo to je

LatteOS GOO je plocha pre ľudí zvyknutých na **Windows 11**, kde lištu, Štart, hodiny a systémové prvky nahrádzajú
**tekuté kávové kvapky** (goo). Kvapky sa správajú ako **sliz v nízkej gravitácii**: pružia, lepia sa k okraju
obrazovky aj k sebe, naťahujú sa a praskajú, žijú vlastným pohybom a reagujú na kurzor ako živý tvor.

| vrstva | čo robí | kde |
|---|---|---|
| **Hyprland 0.56** (Lua) | okná, režimy okien (páska, dlaždice, plávajúce), animácie, sklo Hyprglass | `session/hypr/` |
| **pleamar 0.2.6** (k4ditano, BSD-3; Rust, SDF, jazyk 0.2, naše záplaty) | kreslí kvapky a karty Goo, logika v Luau | `session/goo/` (engine Goo) |
| **Noctalia 5** | rohová lišta (widgety a doplnky), ovládacie centrum, OSD, zámok, akcie relácie | záplatovaná kópia pre Goo |
| **pomocníci LatteOS** | štart plochy, systémové údaje pre kvapky | `latte-kvapky`, `latte-goo`, `latte-sysmon goo` |

Názvy: **Goo** = celá plocha; **GooBar** = lišta s oknami (hlava + ikry okien); **kvapka** = každý samostatný tekutý
prvok; **karta Goo** = okno, ktoré vyrastie z kvapky (ponuka, spúšťač, karta času…).

---

## 2. Pravidlá (od používateľa — platia vždy)

1. **Myš je prvá, klávesy iba doplnok.** Každá funkcia musí ísť myšou (klik, ťahanie, koliesko). Super = kláves Windows.
2. **Návyky z Windows 11** rozhodujú: všetko je **dole**, klik na okno v lište prepne/minimalizuje, pravý klik na okno
   = ponuka okna, ťahanie ľavým ako vo Windows.
3. **Preberať, nevymýšľať:** najprv hotové riešenie (Noctalia, pleamar, Marea, Linuxové subsystémy), až potom vlastné.
4. **Preložiteľné:** texty v UI po anglicky + preklad (`translations sk` v scéne, `tr()` v logike), nikdy natvrdo po slovensky.
5. **Každé prostredie má svoje nastavenia:** Goo, čistá Noctalia, Marea a cudzie prostredia (Plasma…) sa navzájom
   nepoškodzujú (`latte-profil`, oddelené priečinky Noctalie).
6. **Kvapky sú vždy káva.** Téma LatteOS = šálka (materiál okien); obsah = káva s pomerom **vody a mlieka** (Barista).
   Vodová káva (lungo, americano) je sklo, espresso a mliečne kávy nepriehľadné. Kvapky nemajú vlastné farby —
   farba je iba vo farebnom jadre (17) a guľkách (15).
7. **Kvapky nemajú oči** ani žiadnu tvár. Hodiny sú **digitálne**.
8. **Klik iba tam, kde má funkciu.** Ak funkcia kvapky nemá pravý (ľavý) klik, nemá ho ani kvapka; tlačidlo bez
   funkcie goo **zavibruje** („tu nič nie je“). Kliky kvapiek shellu sú v §4.
9. **Vyskakovacie okno vyrastie z kvapky:** kvapka vystúpi od okraja a sedí v **rohu** karty ako **ucho** (so svojím
   obsahom); karta je celá vidieť, pri ktoromkoľvek okraji a v ktoromkoľvek zo 4 rohov (kvapky sa dajú presúvať).
   **Horná hrana karty pri prepínaní záložiek neskáče.** Riadne okná (App Manager, Správca zariadení…) sa nepripájajú
   — rodia sa z bubliny (14).
10. **Goo má vlastný vzhľad ponúk:** z Noctalie a klasického LatteOS sa preberá **funkcia**, nie vzhľad.
11. **Štýl okien Goo:** moderné ikony, písmo, trochu minimalizmu, chytrosť, vkus, užitočnosť. Ikony **Tabler**, písmo
    **Inter**, jemné zaoblenia, akcent témy na výbere; farby idú z témy LatteOS a karta pri uchu **prechádza do kávy**.
    Karty môžu byť väčšie, stále minimalistické a „futuristicky pohyblivé“; **najmenšie rozlíšenie je 1024 × 768**,
    hardvér nie starší než 10 (najviac 15) rokov.
12. **Materiál a priehľadnosť:** prechod z kávy do farby okien; ďaleko od ucha reálna textúra materiálu témy (hliník,
    striebro, tepané zlato); sklenené témy majú perleťové dúhové okraje.
13. **Okná aplikácií: sklo Hyprglass** iba v Goo a pri sklenených témach (okná 86 / 78 %, celá obrazovka a herný
    režim bez skla); vypnutie `~/.config/latteos/bez-skla`.
14. **Okno z kvapky sa rodí z bubliny:** kvapka vypľuje bublinku, tá preletí na miesto okna a nafúkne sa naň;
    **zatvorenie = prasknutie bubliny**; **minimalizácia = okno sa zmenší do kvapky, voľným pádom spadne do GooBaru
    a hladina sa zvlní.**
15. **Farby guliek upozornení:** **červená = hardvér**, **zelená = sieť**, **modrá = softvér** (aktualizácie).
16. **Všetky kvapky sú drag & drop.**
17. **Farebné jadro:** od stredu prechod z farby do kávy — predvolene druh upozornenia (farby podľa 15; + jantárová
    výstraha, svetlo, iné), môže pulzovať.
18. **Vlnky na hladine:** okraj obrazovky je hladina — **kameň hodený do vody** (dve vlny od miesta dopadu, kvapky
    na nich sa nadvihnú) alebo **vibrácia**.
19. **Vietor:** náhodný smer, občas zavanie aj pri práci; kvapky sa vlnia ako obilie, **menšie viac než väčšie**.
20. **Naťahovanie za kurzorom iba po určitú vzdialenosť** (dlhý krk je nepekný — odtrhnutie najneskôr po 1,6
    polomeru); **návrat k okraju ako v Marei**: kvapka vnikne pod hladinu a znova sa vynorí.
21. **Oká medzi spojmi kvapiek sú pekné, ich okraj je ostrá čiara** (nie rozmazaná). Vlákno spája susedné goo —
    čím bližšie, tým hrubšie, organické a nepravidelné.
22. **Kvapky sa nikdy úplne neprekryjú** — ani keď je kurzor ďaleko, ani pri hre; iba sa dotýkajú a zlievajú
    (stredy aspoň 0,95 súčtu polomerov, pri ikrách okien 1,2). Pustená na inú: jedna sa odsunie. **Zvýraznený okraj
    zliatych kvapiek je spoločný** (bez deliacej čiary).

---

## 3. Fyzika a správanie kvapiek

- **Nízka gravitácia, pružnosť:** kvapky pružia, zlievajú sa (jedno goo telo — každá s každou, keď sú blízko),
  dýchajú a pomaly driftujú aj bez myši — **neustály vlastný pohyb, nie útek**.
- **Okraje:** kvapka sa lepí ku **každému okraju** (dole, vľavo, hore, vpravo): pustená do 130 px od okraja sa k nemu
  prilepí a správa sa tam rovnako ako dole. **Nič nevisí vo vzduchu:** pustená vo voľnom priestore **padá** z pokoja
  s nízkou gravitáciou (800 px/s² — pád, nie výstrel), ponorí sa do hladiny, vynorí a hladina sa zvlní.
  GooBar sa pri pustení uprostred vráti; strapce okien sa od okraja nikdy neodlepia.
- **Pokoj:** kým kurzor nie je nablízku, kvapky si **sadnú** — zasunú sa k hladine a sploštia (obsah ostane vidieť);
  pri kurzore sa zdvihnú a zaguľatia. Pri nečinnosti sadnú hlbšie.
- **Živý tvor:** kurzor je pre kvapky to, **po čom túžia** — **iba priťahuje, nikdy neodpudzuje**. Pri priblížení sa
  kvapka **nadnesie** (vystúpi od okraja na stopke) a nakloní sa k nemu, sused sa pridá (30 %); nad kvapkou sa
  mierne nafúkne a netrpezlivo pulzuje. Obsah sa hoverom nemení — názov a popis sú iba v bubline.
- **Vlákna a voda:** susedné kvapky na okraji (do 2,3 súčtu polomerov) spája voda pri okraji a goo vlákno; vlákno sa
  naťahuje, tenčí a za maximom praskne, pri návrate sa zlepí. Pod vláknom vzniká oko (21).
- **Hladina:** okraj obrazovky je voda — vlnky (18), ponor pri návrate (20), vietor (19).
- **Svetlo:** pasívne zhora vľavo + **kurzor ako aktívne svetlo** (svetlá škvrna a odlesk na strane ku kurzoru).
- **Nesúmernosť:** nič nie je dokonale pravidelné (šum, rôzne veľkosti, cik-cak strapcov).
- **Neprekrývať okná:** ikry GooBaru sa pod oknom stiahnu k okraju do voľného pásu; do výšky sa zhlukujú iba tam,
  kde nad nimi nie je okno.
- **Rohová lišta Noctalie je zakázaná zóna:** má premenlivú šírku; kvapky a ikry sa pred ňou zastavia a ustúpia jej.
- **Veľkosť:** každú kvapku možno nafúknuť alebo vyfúknuť **50–220 %** — kolieskom (ak ho kvapka nepoužíva na iné)
  alebo v Nastaveniach › Kvapky; s ňou rastie text aj ikona a **malé goo ukáže menej detailov**.

### 3.1 Živé bytosti — nečinnosť

- **Nečinnosť** (myš aj klávesnica): stupeň **1** po ~1 min (kvapky „zaspávajú“), **2** po ~3 min (počasie),
  **3** po ~6 min (hra). **Prebudenie okamžite** pohybom myši alebo klávesom — zachvenie a návrat na miesto.
- **Stupeň 2 — dážď alebo vietor podľa skutočného počasia** (Open-Meteo): dážď = drobné goo kvapky dopadajú na spodný
  okraj a zvlnia hladinu aj pripnuté kvapky; vietor (od 30 km/h) = postupné vlny pozdĺž okraja; sneh = vločky;
  jasno = iba dýchanie. Kvapky padajú iba nízko nad hladinou, nie cez okná.
- **Deň a noc na hladine:** svetlo, ktoré sa odráža v kvapkách, a žiara nad horizontom hladiny sa menia podľa
  skutočnej polohy slnka — v noci tlmené studené, cez deň biele, pri svitaní a súmraku teplé oranžové.
- **Stupeň 3 — hra, ako staré Worms:** skoky sú **realistické oblúky** s gravitáciou enginu (nie pružina) a smú byť
  vysoké; pred odrazom sa kvapka prikrčí, pri dopade sploští a hladina sa zvlní. Druhy: **plíženie** (prikrčenie,
  nízky výskok, znova — pár ráz za sebou), veľký skok oblúkom aj ponad ostatné, naháňačka so zrážkou (tá druhá
  odskočí), výskok na mieste. **Občas rýchlejšia hra.** Kam kvapka doskočí, ostatné uhnú; nič sa neprekryje (22);
  potom sa všetko vráti na miesto.
- **Kedy nie:** okno na celú obrazovku / hra, zamknutá obrazovka, batéria pod 20 % alebo úsporný profil, stupeň
  výkonu Softvér (llvmpipe); počet snímok pri nečinnosti obmedzený. Vypínač „Živé správanie“ v Nastaveniach › Kvapky.
  *(V engine sú všetky tri stupne, vypínač aj obmedzenia; počet snímok pri nečinnosti sa ešte neobmedzuje.)*

---

## 4. Kvapky (Nová architektúra)

**Jadro** (nedá sa skryť, iba zmeniť veľkosť): **GooBar, GooPower, LensGoo.** **Voliteľné** (Nastavenia › Kvapky):
**QueenGoo, ClockGoo, ChatGoo.** Predvolene dole: GooPower – LensGoo – hlava GooBaru s ikrami, vpravo ClockGoo
a QueenGoo pred rohovou lištou Noctalie.

| Goo | Ľavý klik | Pravý klik | Koliesko |
|---|---|---|---|
| **Hlava GooBaru** | ďalší režim okien | ukázať plochu (ako Win+D; druhý klik vráti okná) | ďalšie okno / posun pásky |
| **Ikry okien** | prepnúť / minimalizovať | ponuka okna | — |
| **GooPower** | karta GooPower | pás výkonu zap / vyp | veľkosť |
| **LensGoo** | spúšťač (aj kláves Win) | rýchly zoznam aplikácií | veľkosť |
| **ClockGoo** | upozornenia a kalendár | karta času | veľkosť |
| **QueenGoo** | App Manager | Správca zariadení | veľkosť |

Stredné tlačidlo nemá žiadna kvapka shellu. Ťahanie ľavým = presun (GooBar celý k inému okraju, ikry = poradie
aplikácií). Veľkosť hlavy GooBaru je v Nastaveniach › Kvapky.

### 4.1 GooBar — lišta a správca okien

Na každom ďalšom monitore je vlastný GooBar s oknami toho monitora (ako panel úloh Windows na druhej obrazovke);
ostatné kvapky sú iba na hlavnom monitore.
- **Hlava** (najväčšia kvapka) ukazuje režim okien: **páska** (ako niri — nič sa neminimalizuje), **dlaždice**,
  **plávajúce** (ako Windows).
- **Ikry okien:** okná ako menšie kvapky s ikonou aplikácie; okná tej istej aplikácie sa zhlukujú do **strapcov**;
  čím viac okien, tým menšie; myš nad strapcom ho rozvinie. Aktívne okno plnšie, minimalizované menšie a stlmené.
  Ikry sa lepia iba ku GooBaru. **48 miest**, nad nimi posledná ikra „Ďalšie okná“ otvorí prehľad.
- Ikry vyrastajú z hlavy na stranu, kde nie sú iné kvapky (nastavenie `reversed` to otočí); GooBar sa spája s inými
  kvapkami iba z druhej strany. Lišta sa zmestí po kraj a zastaví pred rohovou lištou.
- **Viac monitorov:** každá obrazovka má vlastný GooBar, okná a ikry sa dajú prenášať. *(Engine zatiaľ beží iba na
  hlavnom monitore.)*

### 4.2 GooPower — účet, napájanie a výkon
- **Karta (ľavý klik):** **profil účtu** — portrét v kruhu (`~/.face`, obrázok prihlasovania LatteOS alebo
  AccountsService), meno a `login@počítač · od HH:MM` (klik = Nastavenia › Môj účet); tlačidlá **Zamknúť · Odhlásiť**.
  **NAPÁJANIE:** batéria s pruhom (notebook) a **profil napájania** Úspora · Vyvážený · Výkon (`powerprofilesctl`;
  bez neho sa riadok neukáže). **Nastavenia**, **Monitor**. Tlačidlá **Uspať · Reštartovať · Vypnúť** (červené).
  Akcie relácie robí Noctalia.
- **Pás výkonu (pravý klik):** GooPower sa **natiahne pozdĺž okraja do kapsuly** (na voľnú stranu — predvolene od
  LensGoo preč; ikona vypínača ostane na konci pri pôvodnom mieste) a **okolné goo odtlačí**; po vtiahnutí sa
  odtlačené goo vrátia, ak ich medzitým nikto nepresunul. Bunky **CPU · RAM · GPU · VRAM** (názov, hodnota, pruh),
  raz za sekundu z `latte-sysmon goo`. Hodnota je káva, **jantárová nad 80 %**, **červená nad 95 %** alebo pri
  prehriatí (CPU 80 / 90 °C, GPU 85 / 95 °C). Prechod myšou = podrobnosti (takt, teplota, najnáročnejší proces,
  swap), klik = Monitor na tej časti, pravý klik = vtiahnuť. Zapnutý pás ostane aj po ďalšom prihlásení. **FPS
  v páse nie je** — hra na celú obrazovku je nad vrstvou Goo (v hre ostáva prekrytie MangoHud).
- **Batéria na kvapke** (notebook): guľky 3 zelené (≥ 60 %), 2 žlté (≥ 30 %), 1 červená; pod 10 % pulzuje
  červené jadro, pri nabíjaní kvapka dýcha. Na stolnom PC nič.

### 4.3 LensGoo — spúšťač a lupa
- Kvapka s lupou na mieste Štartu. **Ľavý klik alebo kláves Windows** = karta spúšťača; dá sa ovládať aj celá bez
  myši (Tab / Shift+Tab režimy, šípky riadok, Enter, Esc). Režim sa pamätá (`spustac.json`).
- **Režimy:** **Aplikácie** (bez textu obľúbené a nedávne, s textom hľadanie, kalkulačka a prevody, stránky
  Nastavení, rýchle prepnutie do iných režimov; pravý klik = akcie aplikácie) · **Súbory** (domovské priečinky,
  `latte-hladaj`; pravý klik = priečinok so súborom) · **Web** (adresa, vyhľadávače, návrhy) · **Terminál**
  (`latte-terminal`, terminál po príkaze ostane otvorený; nebezpečný príkaz chce druhý Enter; história) · **AI**.
- **AI vždy vnútri, nikdy v prehliadači** (záväzné): rozhovor beží v goo bublinách spúšťača cez `latte-ai`, **bez API
  kľúča** — cez oficiálne nástroje prihlásené účtom používateľa (Claude = `claude -p` so `stream-json`, Gemini =
  `gemini` CLI, ChatGPT = `codex exec`), prípadne Ollama alebo domáci server; prihlásenie raz z Nastavení. Otvorenie
  webu je iba posledná možnosť. Ukazovateľ pri modeli rozlišuje lokálny a cloudový model.
- **Rýchly zoznam (pravý klik):** jednoduché okno s ikonami — naposledy spustené a obľúbené aplikácie ako dlaždice
  (klik spustí), pod nimi Hľadať… (otvorí spúšťač) a App Manager.

### 4.4 QueenGoo — App Manager a Správca zariadení (voliteľná)
- Kvapka s **korunkou** na vonkajšej strane (tvar ostáva kvapka; **tvar korunky bude voliteľný v Nastaveniach** —
  plán). Guľky (15): **červená** = zariadenia, ktoré potrebujú pozornosť (`latte-devices list` › `faults`),
  **zelená** = výpadok siete, **modrá** = čakajúce aktualizácie (`latte-apps updates`).
- **Ľavý klik = App Manager** (pri aktualizáciách rovno na nich), **pravý = Správca zariadení** (pri výpadku siete na
  Sieťach). Sú to riadne okná: kráľovná ostane na mieste a **vypľuje bublinu**, ktorá sa nafúkne na okno vedľa nej
  (14); otvorené okno sa iba ukáže.

### 4.5 ClockGoo — čas, upozornenia, kalendár a pohoda (voliteľná)
- V kvapke veľký digitálny čas, dátum a teplota; bežiaca minútka alebo stopky namiesto dátumu. Guľky počtu
  upozornení — systémové a kritické červeno-kávové, ostatné žlté; nové upozornenie zvlní hladinu.
- **Upozornenia a kalendár (ľavý klik):** jedna karta v **dvoch stĺpcoch** (ako centrum upozornení Windows 11):
  vľavo **upozornenia** (ikona aplikácie, nadpis, telo; klik otvorí, pravý klik akcie a Zahodiť; najviac 5, potom
  „+N ďalších“), **Nerušiť**, **Vymazať všetko**, Nastavenia oznámení; vpravo **mesiac** od pondelka (koliesko,
  šípky), udalosti a úlohy vybraného dňa, pole na nový záznam („10:30 Porada“, „Porada“, „! úloha“) a **Prepojené
  kalendáre** (Google, iCloud, CalDAV, ICS — účty spravuje Noctalia). Zmestí sa aj na 1024 × 768.
- **Karta času (pravý klik):** **Prehľad** (dátum, týždeň, najbližší budík, digitálna pohoda — čas pred obrazovkou
  a tri najpoužívanejšie aplikácie, podrobnosti v Monitore —, svetové hodiny) · **Stopky** (medzičasy) ·
  **Minútka** (dĺžka kolieskom) · **Budíky** · **Počasie** (teraz, dnes, týždeň). Minútka a budíky zvonia aj pri
  zavretej karte. Údaje: `casovace.json`, `clock.conf`, `events.json`, `todo.json`, pohoda z `pohoda.qml`.

### 4.6 ChatGoo — doplnok pre Beeper (voliteľná, plán)
- Iba doplnok, nie vlastný messenger: zastrešuje pôvodný Beeper pre Linux; kvapka sa ukáže, keď je Beeper
  nainštalovaný alebo beží. Nie je nutná — v Nastaveniach voľba „kvapka ChatGoo“ alebo „ikona Beepera v rohovej
  lište“.
- **Minimalizácia Beepera = okno vtečie do kvapky ChatGoo**; klik ho vráti. Upozornenia Beepera idú do ChatGoo
  (guľky, odznak siete; klik otvorí rozhovor, pravý akcie). Pomocník `session/bin/latte-chatgoo` je hotový.
- Bubliny četov pre viac kanálov (Messenger, Telegram, Signal…) — forma sa ešte premyslí; nie ako režim spúšťača.

### 4.7 Vlastné kvapky
- Používateľ si pridá kvapku bez programovania (JSON cez `latte-goo novy`, alebo formulár v Nastaveniach › Kvapky):
  názov, ikona, akcie na kliky, text z príkazu, farebné jadro z príkazu. Správa sa podľa rovnakých pravidiel.
- Programátor pridá kvapku s vlastným správaním ako modul Luau (`session/goo/kvapky/`). Podrobne:
  [session/goo/README.md](session/goo/README.md).

### 4.8 Rohová lišta Noctalie — vpravo dole
- Iba **pravá časť** lišty Noctalie, **natvrdo prilepená** do rohu, šírka podľa počtu widgetov. Obsahuje ikony
  programov na pozadí, sieť, hlasitosť, ovládacie centrum; **ďalšie widgety a komunitné doplnky** Noctalie sa
  pridávajú v jej nastaveniach a bežia natívne. Kliky podľa Noctalie, panely sa otvárajú pri lište.
- Plán: priehľadné pozadie a goo telo z pleamaru pod ňou (vlnenie pri zmene stavu).

### 4.9 Okná (Hyprland)
- Režimy **páska** (nekonečná, ako niri), **dlaždice**, **plávajúce** (ako Windows). Okná neprekrývajú pás kvapiek
  pri okraji (ani maximalizované); celú obrazovku kreslí Hyprland nad vrstvou Goo.

### 4.10 Nastavenia › Kvapky (Goo)
- Jadro: veľkosť a Vrátiť na miesto; voliteľné: aj skryť / ukázať; veľkosť 50–220 %. ChatGoo: kvapka alebo ikona
  v rohovej lište. Vlastné kvapky. Súbor `~/.config/latteos/kvapky.json` (engine ho číta každé 2 s).
- Hlavné nastavenia systému sú **Nastavenia LatteOS**; vybrané položky z nastavení Noctalie sa do nich selektívne
  integrujú (návrh: komunitné doplnky, widgety rohovej lišty, kalendárové účty, filtre a história upozornení, nočné
  svetlo, OSD, horúce rohy, história schránky, rozloženie klávesnice). Tapety zjednotiť na jedno miesto.

### 4.11 Návrhy ďalších kvapiek a vylepšení
- **ClipGoo** (história schránky s pripnutím), **MediaGoo** (práve hrá, ovládanie a hlasitosť cez MPRIS), **PassGoo**
  (keyring a heslá), **CastGoo** (streamovanie obrazovky a médií).
- Z ukážkových kvapiek: prstenec podľa hodnoty (priebeh minútky v ClockGoo, inštalácie v QueenGoo), jadro podľa
  najvážnejšieho upozornenia, vlnky pri systémových udalostiach (dokončené sťahovanie, pripojené zariadenie),
  pripnuté aplikácie ako vlastné kvapky priamo z LensGoo, LensGoo jemne pulzuje, kým AI odpovedá.

---

## 5. Systémový backend

Programy sa nevytvárajú — používajú sa existujúce Linuxové subsystémy a knižnice:

| Oblasť | Použije sa | Nie |
|---|---|---|
| Sieť | **NetworkManager** (jediný správca; iwd iba prípadne ako jeho Wi-Fi backend) | druhý správca vedľa neho |
| Vyhľadávanie | **plocate + fd + ripgrep** (`latte-hladaj`); LocalSearch (Tracker3) iba na metadáta a plný text, keď bude treba | Baloo (ťahá KDE) |
| Súbory v sieti | **GVFS** (+ `gvfs-mtp`, `gvfs-smb`), cloud a FTP/SFTP cez rclone (`latte-siet`) | KIO (KDE) |
| Knižnice | XDG priečinky a záložky Súborov | vlastná vrstva |
| Tlač, skenovanie | CUPS, SANE, simple-scan; tlačiarne v Správcovi zariadení | — |
| Bluetooth | BlueZ (ovládanie cez Noctaliu a službu pleamaru) | — |
| Firewall | firewalld (nad nftables) | — |
| Firmvér | fwupd + LVFS (App Manager › Aktualizácie) | — |
| Dokumenty | poppler (Heidelberg) + hotový prehliadač ako Flatpak (Papers alebo Okular) | Okular ako knižnica |
| Zvuk a médiá | PipeWire, GStreamer, mpv; MediaGoo cez MPRIS | — |
| Podcasty | hotová aplikácia (Kasts, GNOME Podcasts) + MediaGoo | vlastný RSS engine |

Balíky a zapojenie do Správcu zariadení, Súborov a budúcich kvapiek ešte nie sú urobené (ROADMAP).

---

## 6. Schválené návrhy (ešte nevytvorené)

### 6.1 Prístupnosť — ovládanie Goo z klávesnice
Myš ostáva prvá (1); toto je **navigácia pre núdzu bez myši** („keď králik prehryzie kábel myši“), nie presúvanie
kvapiek — rozloženie sa z klávesnice nemení (6. 10.). **Režim sa zapína skratkou a je dočasný** (kým Goo drží
klávesnicu, nedá sa písať do aplikácií).

| Akcia | Kláves | Poznámka |
|---|---|---|
| vstup do Goo | **Win+T** | ako „prejdi na panel úloh“ vo Windows (Win+A otvára Rýchle nastavenia) |
| medzi kvapkami | **← →** | na bočnom okraji **↑ ↓** |
| ľavý klik | **Enter**, **medzerník** | medzerník iba mimo textového poľa |
| pravý klik | **Menu** alebo **Shift+F10** | |
| v karte | **↑ ↓** riadky, **Tab / Shift+Tab** záložky, **Enter** potvrdí | (v karte už hotové) |
| koliesko | **+** a **−** | veľkosť, dĺžka minútky, hodina budíka |
| späť | **Esc** zavrie kartu, druhý **Esc** opustí režim | |

Vybraná kvapka **pulzuje svetlejšou hnedou** (rozdiel v jase, nie v odtieni — stačí aj farboslepému), zdvihne sa
a ukáže bublinu s názvom.

**Stav 6. 10.: vytvorené** v engine Goo (scéna `kb`, `kbk`; logika `kb_*` v `lib/engine.luau`; Win+T v
`latte/skratky.lua`). Ovládanie gamepadom je odložené na neskôr. Šípky chodia po kvapkách dokola po obvode obrazovky, vrátane okien GooBaru. Režim skončí sám
po kliku na okno, po voľbe v karte a po minúte bez klávesu. Ostáva doriešiť: obmedzenie pohybu, väčšie písmo
a kontrast, čítanie názvov nahlas; na vedľajšom monitore režim nie je.

### 6.2 Nový prihlasovač
1. Pri štarte je na obrazovke **šálka** (Plymouth); zo šálky **vyskočí kvapka kávy doprostred obrazovky**.
2. Šálka zmizne, goo sa **odvalí asi 5 cm doľava** a vytvorí **riadok**; objaví sa **meno a heslo**.
3. Rovina sa posunie dole a v **spodných 2/3 obrazovky** je **tekutá hranica** — plocha, ktorá sa z boku správa ako
   **vodná hladina**.
4. **Pod hladinou:** po páde **výpis posledného pádu** (ten istý log aj v Monitore a `latte-boot status`), inak
   **RSS a správy** používateľa. **Viac používateľov sa neukazuje.**
5. Po **minúte bez prihlásenia** sa z hladiny **vynoria ďalšie goo a hrajú sa**; každá nesie inú informáciu (batéria,
   počet upozornení, úlohy v kalendári) a **nie sú klikateľné**. **Čas** je stále veľkým písmom v pravom hornom rohu.
6. Klikať sa dá iba na **ikonu Power** a do **riadku vedľa LoginGoo** (kvapka s ikonou Power); po prihlásení sa
   z LoginGoo stane **GooPower**.

Technika: prihlasovač v pleamare (`kind: lock`, `input … secret`) by dal plynulý prechod LoginGoo → GooPower;
treba rozhodnúť, čo je bezpečné ukázať pred prihlásením (RSS, upozornenia).

7. **Výskok:** kvapka letí zo šálky oblúkom dopredu a do boku, rastie (blíži sa z diaľky) a dvakrát sa odrazí; pri
   klesaní roviny sa riadok pod hladinu **ponorí a vynorí sa nad ňu** ako ostatné goo.
8. **Výber relácie** (vývojárska verzia): na hladine v dosahu riadku sa vynorí ešte jedno goo — LatteOS GOO, Marea,
   Noctalia (čistá), Serpantinum.
10. **Hladina a obloha:** riadok je mierne nad hladinou (ako pás výkonu GooPower), hladina sa mierne vlní; **dážď
   a sneh** podľa počasia vonku (padá, alebo je v predpovedi); nenápadná **silueta slnka alebo mesiaca** tam, kde
   naozaj je (miesto z Nastavení › Prihlasovanie), mesiac v správnej fáze. Obzor je hladina.
11. **Počasie:** v opačnom rohu než hodiny aktuálna teplota a stav tým istým písmom. **LoginGoo** sa spodkom lepí
   k hladine; riadok je pár mm nad ňou. **Účty:** iba predvyplnené meno naposledy prihláseného (dá sa prepísať).
   **Monitory:** scéna je na všetkých. **Pod hladinou** bez pádu: zdroje RSS z Nastavení (aj viac naraz).
9. **Spôsob:** zámok nad **všeobecnou reláciou** (na PC môže byť viac používateľov) — dáta, rozmiestnenie, nastavenia
   a plocha používateľa sa načítajú až po potvrdení prihlásenia.

**Stav 6. 10.:** scéna je hotová (`session/goo/login.plm`, skúška `latte-goo login-skuska`) a je predvoleným
prihlasovaním nových inštalácií: `greeter = "goo"` v `/etc/latteos/boot.toml` (bez grafickej karty, v SAFE alebo po
páde scény nasleduje doterajší prihlasovač; podrobnosti
v [session/goo/README.md](session/goo/README.md) › Prihlásenie). Hladina je v 2/3
výšky obrazovky (rovina „klesne“ zo stredu), pod ňou tretina obrazovky kávy.

### 6.3 Obchod podľa ZimaOS (App Manager)
Vľavo stály panel — hľadanie, Moje aplikácie, **kategórie ako zoznam** (Objavte, Všetko, Médiá, Produktivita,
Domácnosť, Sieť, AI, Financie, Sociálne, Vývojár, Ostatné) a **komunitné obchody** (zdroje tretích strán, napr.
kurátorské výbery Bluefin a Bazzite); vpravo veľký **kolotoč bannerov** (dva naraz, snímka, ikona, názov, slogan),
pod ním **Trending Now** a **New Arrivals** ako veľké karty. Údaje sú (Flathub: snímky, ikony, popisy).

---

## 7. Kde čo je (pre Clauda)

| čo | kde |
|---|---|
| engine Goo: scéna, logika, kvapky, API a pasce jazyka | `session/goo/` — [README](session/goo/README.md) |
| po zmene tela goo alebo počtu miest | `python3 session/goo/gen.py` |
| pomocníci (kvapky, polohy, účet, kalendár, počasie, okná…; údaje pásu výkonu) | `session/bin/latte-goo`, `latte-sysmon goo` |
| štart plochy, Noctalia pre Goo | `session/bin/latte-kvapky` (inú scénu na pokusy cez `LATTE_KVAPKY_SCENE`) |
| relácia, profily prostredí | `session/bin/latte-session` (bez argumentu = LatteOS GOO), `latte-profil` |
| profil používateľa v jednom dokumente | `~/.config/latteos/<účet>@gooconfig.json`, `session/bin/latte-gooconfig` ([README](session/goo/README.md) › Profil) |
| ponuka prihlásenia | LatteOS GOO, Marea, Noctalia (čistá), Serpantinum — `session/wayland-sessions/`, `setup/f1/install-session.sh`, `setup/lab/` |
| Hyprland (režimy okien, pád minimalizovaného okna, rezerva pri okraji, virtuálny monitor) | `session/hypr/hyprland.lua`, `session/hypr/latte/*.lua` |
| záplaty pleamaru / Noctalie / Hyprlandu | `resources/patches/` (README tam) |
| nastavenia používateľa | `~/.config/latteos/` (`kava`, `kvapky.json`, `spustac.json`, `goo/kvapky/*.json`), `~/.local/state/latteos/goo/` (polohy, pás výkonu) |
| aktualizácie u autorov | `latte-upstream -v` |
| nasadenie na latte-lab | `setup/f1/install-session.sh` (`/usr/share/latteos/goo/`); **súbory Hyprlandu atomicky** (`install` do `.nazov.new` + `mv`), inak ich Hyprland načíta napoly vymenené |
| pôvodná plocha Kvapky (už sa nenasadzuje) | `session/kvapky/`; jej dokumentácia v `docs_zaloha/2026-10-01-plocha-kvapky-readme.md` |
| testovací stroj latte-lab | grafika AMD Polaris 12: na karte (podľa fotky) **RX 550**, detektor LatteOS ju hlási ako **RX 640** (OEM označenie toho istého čipu) |
