# LatteOS GOO

Spoločný dokument pre používateľa (autora LatteOS) a Clauda: **čo LatteOS GOO je, ako sa má správať a z čoho sa
skladá — tak, ako to platí teraz.** Pred prácou na Goo ho treba prečítať. Keď sa niečo rozhodne, opraví sa tu
platné znenie a rozhodnutie sa s dátumom zapíše do denníka [docs/goo/ROZHODNUTIA.md](docs/goo/ROZHODNUTIA.md)
(aj čo bolo zamietnuté). Plán a otvorené úlohy: [ROADMAP.md](ROADMAP.md) (sekcia „Teraz“). Ako sa píše kvapka:
hlavička [goo/lib/engine.luau](goo/lib/engine.luau).

> **Smer:** LatteOS GOO je **jediná edícia** LatteOS (Classic je zrušený, 5. 10. 2026). Od 12. 10. 2026 sa píše
> načisto vo vetve `v0.4-fresh` (**Fresh**): prihlasovanie Goo, relácie **LatteOS GOO**, **LatteOS SAFE** a zatiaľ
> **LatteOS Game**; bez Noctalie. Tento dokument opisuje, ako sa má GOO správať; **čo z toho Fresh už má, je v §8**,
> ostatné je predloha v `old/` a vráti sa po kusoch.

---

## 1. Čo to je

LatteOS GOO je plocha pre ľudí zvyknutých na **Windows 11**, kde lištu, Štart, hodiny a systémové prvky nahrádzajú
**tekuté kávové kvapky** (goo). Kvapky sa správajú ako **sliz v nízkej gravitácii**: pružia, lepia sa k okraju
obrazovky aj k sebe, naťahujú sa a praskajú, žijú vlastným pohybom a reagujú na kurzor ako živý tvor.

| vrstva | čo robí | kde |
|---|---|---|
| **Hyprland 0.56** (Lua) | okná, režimy okien (páska, dlaždice, plávajúce), animácie | `system/hypr/` |
| **pleamar 0.3.2** (k4ditano, BSD-3; Rust, SDF, jazyk 0.4, naše záplaty v `patches/`) | kreslí kvapky a karty Goo, logika v Luau | `goo/` (engine Goo) |
| **pomocníci LatteOS** | štart, prihlásenie, relácia, údaje pre kvapky | `bin/`, `crates/` |

Rohovú lištu, ovládacie centrum, upozornenia a zámok robila do v0.3 Noctalia 5; vo Fresh ich nahradia služby
pleamaru (`tray`, `network`, `audio`, `bluetooth`, `notifications`, `session`, `polkit`) a kvapky.

Názvy: **Goo** = celá plocha; **BarGoo** = lišta s oknami (hlava + ikry okien; do 12. 10. GooBar, podobne PowerGoo
bol GooPower); **kvapka** = každý samostatný tekutý prvok; **karta Goo** = okno, ktoré vyrastie z kvapky (ponuka, spúšťač, karta času…).

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
    *(Fresh, 13. 10.: sklo okien ide s materiálom kvapiek — Nastavenia Goo › Sklenená káva ho zapne, Káva vypne;
    `system/hypr/latte/glass.lua`, plugin Hyprglass, iba stupne výkonu full a standard. Samostatný vypínač nie je.)*
14. **Okno z kvapky sa rodí z bubliny:** kvapka vypľuje bublinku, tá preletí na miesto okna a nafúkne sa naň;
    **zatvorenie = prasknutie bubliny**; **minimalizácia = okno sa zmenší do kvapky, voľným pádom spadne do BarGoo
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
  BarGoo sa pri pustení uprostred vráti; strapce okien sa od okraja nikdy neodlepia.
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
- **Neprekrývať okná:** ikry BarGoo sa pod oknom stiahnu k okraju do voľného pásu; do výšky sa zhlukujú iba tam,
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
  *(Fresh, 13. 10.: hrajú sa iba kvapky hravej povahy na spodnom okraji — zatiaľ teda vlastné kvapky s
  `"nature": "playful"`; skok je hod s gravitáciou scény (`Drop:jump`), druhy: výskok na mieste, plíženie,
  veľký oblúk, naháňačka. Po prebudení sa všetko vráti na miesto.)*
- **Zdroj nečinnosti (7. 10.):** celý systém, myš aj klávesnica — pomocník relácie (`apps/ponuka.qml`, IdleMonitor,
  ext-idle-notify) pošle po 50 s bez dotyku `sys_idle 1` a pri činnosti `sys_idle 0`; kto píše bez myši, kvapky
  nezaspia, klávesa ich zobudí. Pri prehrávaní videa (inhibítor) sa nečinnosť nehlási. Bez pomocníka platí
  nečinnosť scény (iba myš).
  *(Fresh, 13. 10.: pomocníkom je hypridle — `system/hypr/hypridle.conf` hlási `sys_idle 1/2/3` po 1, 3 a 6 min
  a `sys_idle 0` pri činnosti; inhibítor aj okno na celú obrazovku nečinnosť zastavia.)*

---

## 4. Kvapky (Nová architektúra)

**Jadro** (nedá sa skryť, iba zmeniť veľkosť): **BarGoo, PowerGoo, LensGoo.** **Voliteľné** (Nastavenia › Kvapky):
**QueenGoo, ClockGoo, ChatGoo.** Predvolene dole: PowerGoo – LensGoo – hlava BarGoo s ikrami, vpravo ClockGoo
a v rohu tvrdé Pobrežie (vo Fresh; do v0.3 rohová lišta Noctalie); QuickGoo (rýchle spúšťanie) vľavo od PowerGoo.

| Goo | Ľavý klik | Pravý klik | Koliesko |
|---|---|---|---|
| **Hlava BarGoo** | ďalší režim okien | ukázať plochu (ako Win+D; druhý klik vráti okná) | ďalšie okno / posun pásky |
| **Ikry okien** (plávajúce okná; inde po postáti myši na hlave) | prepnúť / minimalizovať | ponuka okna | — |
| **PowerGoo** | karta PowerGoo | pás výkonu zap / vyp | veľkosť |
| **LensGoo** | spúšťač (aj kláves Win) | rýchly zoznam aplikácií | veľkosť |
| **ClockGoo** | upozornenia a kalendár | karta času | veľkosť |
| **QuickGoo** | páska s aplikáciami poruke | — | veľkosť |
| **QueenGoo** | App Manager | Správca zariadení | veľkosť |

Stredné tlačidlo nemá žiadna kvapka shellu. Ťahanie ľavým = presun (BarGoo celý k inému okraju, ikry = poradie
aplikácií). Veľkosť hlavy BarGoo je v Nastaveniach › Kvapky.

- **Kvapka uhne oknu** (7. 10.): kvapka na bočnom či hornom okraji nikdy nezakryje titulok okna s tlačidlami —
  dočasne sa odsunie pozdĺž okraja a keď okno odíde, vráti sa (ako goo uhnú pásu PowerGoo).

### 4.1 BarGoo — lišta a správca okien

Na každom ďalšom monitore je vlastný BarGoo s oknami toho monitora (ako panel úloh Windows na druhej obrazovke);
ostatné kvapky sú iba na hlavnom monitore.
- **Hlava** (najväčšia kvapka) ukazuje režim okien: **páska** (ako niri — nič sa neminimalizuje), **dlaždice**,
  **plávajúce** (ako Windows).
- **Kedy sú ikry vonku (rozhodnuté 13. 10.):** iba v režime **plávajúce**. V **páske** a **dlaždiciach** hlava
  ukáže **počet okien**; keď na hlave postojí myš,
  ikry sa dočasne vysunú (aj kvôli oknám na iných plochách) a zasunú sa, keď myš od nich odíde. Či sú vonku,
  určuje jedno miesto v logike (`berries_out()` v `goo/lib/bar.luau`); kreslenie ikier nesmie predpokladať, že sú
  viditeľné — rovnaký prepínač neskôr poslúži režimu Glance (ROADMAP „Teraz“, koniec).
- **Zvuk a žiadosť o pozornosť sú vidieť na samotnom okne** (rozhodnuté 13. 10.): jeho **okraj pulzuje** — bledo
  a pomaly, kým okno hrá zvuk (nie na okne, v ktorom sa práve pracuje), červeno a rýchlo, kým chce pozornosť (až kým
  nie je vpredu). Robí to Hyprland (`system/hypr/latte/windows.lua`); ktoré okná hrajú, mu hovorí scéna. Hlava
  BarGoo sa zavlní iba vtedy, keď také okno nie je na očiach (iná plocha).
- **Ikry okien:** okná ako menšie kvapky s ikonou aplikácie; okná tej istej aplikácie sa zhlukujú do **strapcov**;
  čím viac okien, tým menšie; myš nad strapcom ho rozvinie. Aktívne okno plnšie, minimalizované menšie a stlmené.
  Ikry sa lepia iba ku BarGoo. **48 miest**, nad nimi posledná ikra „Ďalšie okná“ otvorí prehľad.
- Ikry vyrastajú z hlavy na stranu, kde nie sú iné kvapky (nastavenie `reversed` to otočí); BarGoo sa spája s inými
  kvapkami iba z druhej strany. Lišta sa zmestí po kraj a zastaví pred rohovou lištou.
- **Viac monitorov:** každá obrazovka má vlastný BarGoo, okná a ikry sa dajú prenášať. *(Fresh, 13. 10.: na každom ďalšom
  monitore beží vlastná scéna `goo/side.plm` s BarGoo a oknami toho monitora — `latte-goo-side@MONITOR.service`,
  spúšťa a zastavuje ju Hyprland; materiál, živé správanie a kávu jej hovorí hlavná scéna cez `latte-say`.
  Prenášanie ikier medzi monitormi ešte nie je.)*

### 4.2 PowerGoo — účet, napájanie a výkon
- **Karta (ľavý klik):** **profil účtu** — portrét v kruhu (`~/.face`, obrázok prihlasovania LatteOS alebo
  AccountsService), meno a `login@počítač · od HH:MM` (klik = Nastavenia › Môj účet); tlačidlá **Zamknúť · Odhlásiť**.
  **NAPÁJANIE:** batéria s pruhom (notebook) a **profil napájania** Úspora · Vyvážený · Výkon (`powerprofilesctl`;
  bez neho sa riadok neukáže). **Nastavenia**, **Monitor**. Tlačidlá **Uspať · Reštartovať · Vypnúť** (červené).
  Akcie relácie robí Noctalia.
- **Pás výkonu (pravý klik):** PowerGoo sa **natiahne pozdĺž okraja do kapsuly** (na voľnú stranu — predvolene od
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
- **Režimy:** **Aplikácie** (bez textu **mriežka** obľúbených a naposledy spustených, 6 dlaždíc v rade; s textom
  hľadanie, kalkulačka a prevody, stránky Nastavení, prvé tri nájdené súbory, rýchle prepnutie do iných režimov;
  každý výsledok má vpravo **značku zdroja** — Aplikácia / Nastavenia / Súbor / Priečinok / Web; pravý klik = akcie
  aplikácie) · **Súbory** (domovské priečinky,
  `latte-hladaj`; pravý klik = priečinok so súborom) · **Web** (adresa, vyhľadávače, návrhy) · **Terminál**
  (`latte-terminal`, terminál po príkaze ostane otvorený; nebezpečný príkaz chce druhý Enter; história) · **AI**.
- **AI vždy vnútri, nikdy v prehliadači** (záväzné): rozhovor beží v goo bublinách spúšťača cez `latte-ai`, **bez API
  kľúča** — cez oficiálne nástroje prihlásené účtom používateľa (Claude = `claude -p` so `stream-json`, Gemini =
  `gemini` CLI, ChatGPT = `codex exec`), prípadne Ollama alebo domáci server; prihlásenie raz z Nastavení. Otvorenie
  webu je iba posledná možnosť. Ukazovateľ pri modeli rozlišuje lokálny a cloudový model.
  *(Fresh, 13. 10.: režim AI je v LensGoo (Win+C), keď `bin/latte-ai providers` niečo nájde — zatiaľ iba Claude
  (`claude -p`, bez nástrojov, bez osobných nastavení používateľa, rozhovor sa neukladá). Odpoveď príde naraz
  (nie postupne), posledné štyri výmeny idú ako kontext, Kopírovať odpoveď, Nový rozhovor. Chýba: Gemini, ChatGPT,
  Ollama a domáci server (na latte-lab sa nedali vyskúšať), prihlásenie z Nastavení, postupné písanie, prílohy.)*
- **Rýchly zoznam (pravý klik):** jednoduché okno s ikonami — naposledy spustené a obľúbené aplikácie ako dlaždice
  (klik spustí), pod nimi Hľadať… (otvorí spúšťač) a App Manager.

### 4.4 QueenGoo — App Manager a Správca zariadení (voliteľná)
- Kvapka s **korunkou** na vonkajšej strane (tvar ostáva kvapka; **tvar korunky bude voliteľný v Nastaveniach** —
  plán). Guľky (15): **červená** = zariadenia, ktoré potrebujú pozornosť (`latte-devices list` › `faults`),
  **zelená** = výpadok siete, **modrá** = čakajúce aktualizácie (`latte-apps updates`).
- **Ľavý klik = App Manager** (pri aktualizáciách rovno na nich), **pravý = Správca zariadení** (pri výpadku siete na
  Sieťach). Sú to riadne okná: kráľovná ostane na mieste a **vypľuje bublinu**, ktorá sa nafúkne na okno vedľa nej
  (14); otvorené okno sa iba ukáže.

- *(Fresh, 13. 10.: kvapka je — `goo/drops/queengoo.luau`: korunka, červená guľka pri zariadení bez ovládača či
  firmvéru, zelená pri výpadku siete, modrá pri aktualizáciách; ľavý klik otvorí App Manager (pri aktualizáciách
  na nich), pravý Správcu zariadení. Okno sa zatiaľ rodí obyčajne, nie z bubliny.)*
- **Správca zariadení** *(Fresh, 13. 10.; `apps/devices.qml`, `bin/latte-devices`)*: prehľad — meno a model počítača,
  procesor, pamäť, jadro, veľký krúžok „Všetko funguje“ alebo počet zariadení, ktoré potrebujú pozornosť; skupiny
  ako dlaždice (Obrazovky, Grafika, Zvuk, Sieť, Disky, Klávesnice a myši, Kamery, Bluetooth, Tlačiarne, USB,
  Napájanie, Ostatné); v skupine každé zariadenie s ovládačom a stavom (Funguje · Chýba ovládač · Chýba firmvér);
  „Dobre vedieť“ z `latte-boot compat`; Kopírovať správu. Nič nemení — sieť, zvuk a Bluetooth sa nastavujú
  v paneli Pobrežia. Oproti v0.3 chýba: režimy obrazoviek, zvukové karty a profily, tlačiarne a skenery, telefóny,
  firewall, skúšky (kamera, mikrofón, ovládač), oprava chýbajúceho ovládača cez App Manager.

### 4.5 ClockGoo — čas, upozornenia, kalendár a pohoda (voliteľná)
- V kvapke veľký digitálny čas, dátum a teplota; bežiaca minútka alebo stopky namiesto dátumu. Guľky počtu
  upozornení — systémové a kritické červeno-kávové, ostatné žlté; nové upozornenie zvlní hladinu.
- **Upozornenia a kalendár (ľavý klik):** jedna karta v **dvoch stĺpcoch** (ako centrum upozornení Windows 11):
  vľavo **upozornenia** (ikona aplikácie, nadpis, telo; klik otvorí, pravý klik akcie a Zahodiť; najviac 5, potom
  „+N ďalších“), **Nerušiť**, **Vymazať všetko**, Nastavenia oznámení; vpravo **mesiac** od pondelka (koliesko,
  šípky), udalosti a úlohy vybraného dňa, pole na nový záznam („10:30 Porada“, „Porada“, „! úloha“) a **Prepojené
  kalendáre** (Google, iCloud, CalDAV, ICS — účty spravuje Noctalia). Zmestí sa aj na 1024 × 768.
  *(Fresh, 13. 10.: prepojený kalendár je adresa vo formáte iCal (.ics) — dá ju Google, iCloud aj Nextcloud;
  `bin/latte-cal` ich číta pri štarte a každú polhodinu, udalosti sú iba na čítanie. Účty a CalDAV so zápisom nie sú.)*
- **Karta času (pravý klik):** **Prehľad** (dátum, týždeň, najbližší budík, digitálna pohoda — čas pred obrazovkou
  a tri najpoužívanejšie aplikácie, podrobnosti v Monitore —, svetové hodiny) · **Stopky** (medzičasy) ·
  **Minútka** (dĺžka kolieskom) · **Budíky** · **Počasie** (teraz, dnes, týždeň). Minútka a budíky zvonia aj pri
  zavretej karte. Údaje: `casovace.json`, `clock.conf`, `events.json`, `todo.json`, pohoda z `pohoda.qml`.

### 4.6 ChatGoo — doplnok pre Beeper (voliteľná)
- Iba doplnok, nie vlastný messenger: zastrešuje pôvodný Beeper pre Linux; kvapka sa ukáže, keď je Beeper
  nainštalovaný alebo beží. Nie je nutná — v Nastaveniach voľba „kvapka ChatGoo“ alebo „ikona Beepera v rohovej
  lište“.
- **Minimalizácia Beepera = okno vtečie do kvapky ChatGoo**; klik ho vráti. Upozornenia Beepera idú do ChatGoo
  (guľky, odznak siete; klik otvorí rozhovor, pravý akcie). Pomocník `old/session/bin/latte-chatgoo` je hotový (v0.3).
- **Stav (6. 10.):** kvapka je v engine (`kvapky/chatgoo.luau`). Je na ploche, iba keď je Beeper nainštalovaný alebo
  beží; nesie **pôvodnú ikonu Beepera** (zo spúšťača aplikácií). Okno Beepera nemá ikru v BarGoo — ľavý klik na
  kvapku ho ukáže alebo schová, jadro svieti, kým je okno v kvapke. Upozornenia Beepera idú k nej namiesto ClockGoo
  (modré guľky); pravý klik = karta správ (klik otvorí rozhovor, pravý klik na správu = jej akcie, Vymazať všetko).
  Ešte nie je: plynulé „vtečenie“ okna do kvapky (teraz iba vlnka), odznak siete, voľba „ikona v rohovej lište“.
- Bubliny četov pre viac kanálov (Messenger, Telegram, Signal…) — forma sa ešte premyslí; nie ako režim spúšťača.

### 4.7 Vlastné kvapky
- Používateľ si pridá kvapku bez programovania (JSON cez `latte-goo novy`, alebo formulár v Nastaveniach › Kvapky):
  názov, ikona, akcie na kliky, text z príkazu, farebné jadro z príkazu. Správa sa podľa rovnakých pravidiel.
- **Tvorca Goo** (7. 10., Nastavenia › Kvapky): goo z hotových dielov — aplikácia (pôvodná ikona, klik spustí),
  rýchle spúšťanie (skupina aplikácií, klik ukáže kartu s dlaždicami), údaj (procesor, teplota, pamäť, disk, batéria,
  počasie, vlastný príkaz; prstenec podľa hodnoty) — a ovládanie myšou: bublina pri prechode, ľavý, stredný, pravý
  klik, koliesko (veľkosť, hlasitosť, jas, skladba, plochy). Rýchla cesta: LensGoo › pravý klik na aplikáciu ›
  Pripnúť ako kvapku. Pravý klik na vlastné goo: Upraviť v Tvorcovi Goo, Vrátiť na miesto, Odstrániť goo. Nové goo si
  nájde voľné miesto na lište (nie v páse výkonu) a zapamätá si ho ako domov.
- *(Fresh, 13. 10.: `goo/lib/own.luau` — kvapky sú zoznam v `drops.json` v priečinku scény
  (`~/.local/share/pleamar/goo/`), berú sa hneď po uložení: aplikácia (`app`), alebo ikona s príkazom na ľavý
  a stredný klik (`click`, `middle`) a textom z príkazu (`text`, `every`), povaha (`nature`). LensGoo › pravý klik
  na aplikáciu › Pripnúť ako kvapku; pravý klik na vlastnú kvapku: Vrátiť na miesto, Odstrániť kvapku. Skryť sa dá
  v Nastaveniach ako každá voliteľná. Ešte nie je: Tvorca Goo (formulár), údaj s prstencom, farebné jadro z príkazu,
  skupina aplikácií, voľba kolieska.)*
- Programátor pridá kvapku s vlastným správaním ako modul Luau (`goo/drops/`); ako, je v hlavičke
  [goo/lib/engine.luau](goo/lib/engine.luau).

### 4.8 Rohová lišta Noctalie — vpravo dole
*(Fresh, 13. 10.: namiesto nej je vlastné **Pobrežie** — tvrdý roh, popis v §8. Nasledujúce platilo do v0.3.)*
- Iba **pravá časť** lišty Noctalie, **natvrdo prilepená** do rohu, šírka podľa počtu widgetov. Obsahuje ikony
  programov na pozadí, sieť, hlasitosť, ovládacie centrum; **ďalšie widgety a komunitné doplnky** Noctalie sa
  pridávajú v jej nastaveniach a bežia natívne. Kliky podľa Noctalie, panely sa otvárajú pri lište.
- Plán: priehľadné pozadie a goo telo z pleamaru pod ňou (vlnenie pri zmene stavu).

### 4.9 Okná (Hyprland)
- **Prichytenie ťahaním** (Fresh, 13. 10.; plávajúce okná): okno pustené s kurzorom pri hornom okraji sa
  maximalizuje, pri bočnom zaberie polovicu, pri rohu štvrtinu; odtiahnuté z miesta dostane späť svoju veľkosť.
  Kedy bolo okno pustené, hovorí plugin `plugins/latte-events` (Hyprland 0.56 na to udalosť nemá); bez neho sa
  neprichytáva. Pri Win + ťahaní sa prichytí až s prvým pohybom myši po pustení. Náhľad cieľa ešte nie je.
- Režimy **páska** (nekonečná, ako niri), **dlaždice**, **plávajúce** (ako Windows). Štvrtý, **Glance** pre široké
  monitory (Main · Stash · Parking), je rozhodnutý a čaká v poradí: ROADMAP „Teraz“, bod 7. Okná neprekrývajú pás kvapiek
  pri okraji (ani maximalizované); celú obrazovku kreslí Hyprland nad vrstvou Goo.

### 4.10 Nastavenia › Kvapky (Goo)
- Jadro: veľkosť a Vrátiť na miesto; voliteľné: aj skryť / ukázať; veľkosť 50–220 %. ChatGoo: kvapka alebo ikona
  v rohovej lište. Vlastné kvapky. Súbor `~/.config/latteos/kvapky.json` (engine ho číta každé 2 s).
- **Materiál kvapiek** (7. 10.): **Káva** (predvolená) alebo **Sklenená káva** (`material: "sklo"`) — predloha
  „Droplu“ z Figmy v kávových farbách: telo lišty a kvapiek je sklo, cez ktoré presvitá rozmazané pozadie
  (pleamar `glass`, rozmazanie robí Hyprland; svetlo okraja od kurzora), nad ním priesvitná káva (druhé telo
  s tými istými tvarmi, 44 %) a na každej kvapke lesklý odlesk. **Lom pozadia** (`lens`) má našu opravu —
  záplatu `pleamar-sklo-stabilne` (7. 10.): pôvodný pleamar odčítaval iba posledný obraz a pri stále sa hýbucich
  kvapkách v skle na chvíľu ostávali duchovia a zrnité pásy. Vypne ho `sklo_lom: false` v kvapky.json (potom
  pozadie iba rozmazáva Hyprland). Cena na latte-lab (RX 640): engine hlavného monitora ~27 % → ~41 % jedného
  jadra, Hyprland bez zmeny (~16 %); pri obyčajnej káve sklo nestojí nič.
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
| Tlač, skenovanie | CUPS (tlač bez ovládača: IPP Everywhere / AirPrint, USB cez `ipp-usb`), SANE + `sane-airscan`, simple-scan; tlačiarne a skenery v Správcovi zariadení | ovládače od výrobcov, vlastný dialóg skenovania |
| Bluetooth | BlueZ (ovládanie cez Noctaliu a službu pleamaru) | — |
| Firewall | firewalld (nad nftables) | — |
| Firmvér | fwupd + LVFS (App Manager › Aktualizácie) | — |
| Dokumenty | poppler (Heidelberg) + hotový prehliadač ako Flatpak (Papers alebo Okular) | Okular ako knižnica |
| Zvuk a médiá | PipeWire, GStreamer, mpv; MediaGoo cez MPRIS | — |
| Podcasty | hotová aplikácia (Kasts, GNOME Podcasts) + MediaGoo | vlastný RSS engine |

**Stav (6. 10., v0.3):** balíky inštaluje `old/setup/f1/install-session.sh` (`gvfs-mtp`, `gvfs-gphoto2`, `gvfs-afc`, `gvfs-smb`, CUPS,
`ipp-usb`, SANE, `sane-airscan`, simple-scan); CUPS sa spúšťa až pri použití (`cups.socket`). Správca zariadení
(`latte-devices`, `SpravcaZariadeni.qml`) má skupiny:

- **Tlačiarne** — pridané tlačiarne a tie, čo sa našli v sieti a dajú sa pridať jedným tlačidlom; predvolená, skúšobná
  strana, odstránenie. Správca účtu (skupina wheel) to robí bez hesla.
- **Skenery** — nájdené cez SANE (aj sieťové); „Skenovať“ otvorí simple-scan, „Hľadať znova“ hľadá nanovo.
- **Telefóny a fotoaparáty** — zariadenia MTP/PTP na USB; „Pripojiť“ ich pripojí cez GVFS, „Otvoriť v Súboroch“ otvorí
  ich úložisko. Súbory majú v ľavom paneli položku Telefóny a fotoaparáty.

Pomalé hľadanie (sieť, CUPS, SANE) nebrzdí zoznam zariadení: zoznam berie zapamätaný výsledok
(`~/.cache/latteos/zariadenia-*.json`) a obnovuje ho na pozadí. Sieťové disky Windows (SMB) v Súboroch a zapojenie
do budúcich kvapiek ešte nie sú urobené (ROADMAP).

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
`latte/skratky.lua`). Ovládanie gamepadom je odložené na neskôr. Šípky chodia po kvapkách dokola po obvode obrazovky, vrátane okien BarGoo. Režim skončí sám
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
   z LoginGoo stane **PowerGoo**.

Technika: prihlasovač v pleamare (`kind: lock`, `input … secret`) by dal plynulý prechod LoginGoo → PowerGoo;
treba rozhodnúť, čo je bezpečné ukázať pred prihlásením (RSS, upozornenia).

7. **Výskok:** kvapka letí zo šálky oblúkom dopredu a do boku, rastie (blíži sa z diaľky) a dvakrát sa odrazí; pri
   klesaní roviny sa riadok pod hladinu **ponorí a vynorí sa nad ňu** ako ostatné goo.
8. **Výber relácie** (vývojárska verzia): na hladine v dosahu riadku sa vynorí ešte jedno goo — LatteOS GOO, Marea,
   Noctalia (čistá), Serpantinum.
10. **Hladina a obloha:** riadok je mierne nad hladinou (ako pás výkonu PowerGoo), hladina sa mierne vlní; **dážď
   a sneh** podľa počasia vonku (padá, alebo je v predpovedi); nenápadná **silueta slnka alebo mesiaca** tam, kde
   naozaj je (miesto z Nastavení › Prihlasovanie), mesiac v správnej fáze. Obzor je hladina.
11. **Počasie:** v opačnom rohu než hodiny aktuálna teplota a stav tým istým písmom. **LoginGoo** sa spodkom lepí
   k hladine; riadok je pár mm nad ňou. **Účty:** iba predvyplnené meno naposledy prihláseného (dá sa prepísať).
   **Monitory:** scéna je na všetkých. **Pod hladinou** bez pádu: zdroje RSS z Nastavení (aj viac naraz).
9. **Spôsob:** zámok nad **všeobecnou reláciou** (na PC môže byť viac používateľov) — dáta, rozmiestnenie, nastavenia
   a plocha používateľa sa načítajú až po potvrdení prihlásenia.

**Stav 12. 10. (Fresh):** scéna je napísaná načisto (`goo/login.plm`, logika `goo/lib/login.luau`) a je predvoleným
prihlasovaním nových inštalácií: `greeter = "goo"` v `/etc/latteos/boot.toml` (bez grafickej karty, v SAFE alebo po
páde scény nasleduje doterajší prihlasovač; podrobnosti
v `old/session/goo/README.md` › Prihlásenie). Hladina je v 2/3
výšky obrazovky (rovina „klesne“ zo stredu), pod ňou tretina obrazovky kávy.

### 6.3 Obchod podľa ZimaOS (App Manager)
*(Fresh, 13. 10.: napísaný nanovo — `apps/appmanager.qml` (QML, Quickshell), príkaz `bin/latte-apps`, spúšťač
`bin/latte-app`. Vľavo hľadanie, Objavovať, Moje aplikácie, Aktualizácie, kategórie a **Barista** (miesto pre
špeciálne inštalácie — zatiaľ iba stránka, čo vezme); vpravo dva veľké bannery so snímkou, ktoré sa samy striedajú,
pod nimi police Práve letí, Nové prírastky a Najpoužívanejšie; stránka aplikácie so snímkami, veľkosťou, licenciou;
inštalácia, odstránenie a aktualizácia Flatpakov s priebehom, aktualizácia systému cez heslo správcu. Jedna úloha
naraz, ostatné čakajú v rade. Oproti v0.3 chýba: komunitné obchody, hodnotenia a recenzie, oprávnenia a NET,
ovládače a firmvér, „Bude to fungovať?“, úlohy, ktoré prežijú zatvorenie okna, RPM aplikácie v obchode.)*
Vľavo stály panel — hľadanie, Moje aplikácie, **kategórie ako zoznam** (Objavte, Všetko, Médiá, Produktivita,
Domácnosť, Sieť, AI, Financie, Sociálne, Vývojár, Ostatné) a **komunitné obchody** (zdroje tretích strán, napr.
kurátorské výbery Bluefin a Bazzite); vpravo veľký **kolotoč bannerov** (dva naraz, snímka, ikona, názov, slogan),
pod ním **Trending Now** a **New Arrivals** ako veľké karty. Údaje sú (Flathub: snímky, ikony, popisy).

**Stav 6. 10.: vytvorené** v App Manageri (`session/apps/common/AppManager.qml`, `latte-apps store`): kategórie
a komunitné obchody (Bluefin, Bazzite) ako zoznam v ľavom paneli, kolotoč dvoch bannerov, „Práve letí“ a „Nové
prírastky“ ako veľké karty s tlačidlom Inštalovať. Hľadanie ostalo v hlavičke okna; Domácnosť Flathub ako kategóriu
nemá (AI je hľadanie, Financie a Sociálne sú podkategórie Flathubu).

---

## 7. Kde čo je (pre Clauda) — Fresh

| čo | kde |
|---|---|
| scéna plochy a jej časti | `goo/goo.plm`, `goo/parts/` — `drops` (záznam kvapky, fyzika, myš), `body` (telo goo), `card` + `rows` (karta), `faces` (obsah kvapiek) |
| po zmene počtu miest alebo tvarov tela | `python3 goo/gen.py` (píše `parts/shapes.plm` a `parts/picks.plm`; `--slots N` mení počet miest) |
| engine: register kvapiek, rozloženie, vstupy, nastavenia | `goo/lib/engine.luau` (v hlavičke: ako sa píše kvapka) |
| karta (ponuka, spúšťač, panel) | `goo/lib/card.luau` (v hlavičke: druhy riadkov) |
| kvapky | `goo/drops/*.luau`; okná v lište `goo/lib/bar.luau`, spúšťač `goo/lib/lens.luau` |
| čo scéna žiada od Hyprlandu | `goo/lib/wm.luau` → `hyprctl eval` → `system/hypr/latte/windows.lua` |
| kto čo spúšťa (terminál…) | `goo/lib/open.luau` — jediné miesto, ktoré menuje iný program |
| preklady | `goo/lang/sk.plm` (scény aj `tr()` v logike; `N("…")` označí text, ktorý `tr()` dostane neskôr) |
| Hyprland | `system/hypr/hyprland.lua`, `latte/windows.lua` (režimy, okná, plochy), `latte/keys.lua`, `latte/tiers.lua` |
| relácia, štart enginu | `bin/latte-session`, `system/systemd/latte-goo.service` (patrí k `latte-session.target`) |
| nastavenia a stav používateľa | `~/.local/share/pleamar/goo/`: `places.json` (kde sú kvapky), `settings.json` (materiál, živé správanie, skryté kvapky, veľkosti), `lens.json` (spúšťač); `~/.local/state/latteos/window-mode`; `~/.config/latteos/coffee` |
| čo LatteOS dáva do systému | `FILES` |
| kontroly pred commitom | `tests/check.sh` |
| **skúška celej relácie bez obrazovky**, na skutočnej karte | `tests/screen.sh` (labwc bez výstupu → Hyprland → scéna; snímky, falošná myš, `--record`) |
| záplaty pleamaru | `patches/` (README tam); novinky u autorov `old/session/bin/latte-upstream -v` |
| predloha v0.3 | `old/` (nemení sa); jej engine `old/session/goo/` a jeho README |
| testovací stroj latte-lab | grafika AMD Polaris 12: na karte (podľa fotky) **RX 550**, detektor LatteOS ju hlási ako **RX 640** (OEM označenie toho istého čipu) |

---

## 8. Čo z toho má Fresh (stav 12. 10. 2026)

**Je** (overené v `tests/screen.sh` na latte-lab — Hyprland bez obrazovky, snímky a falošná myš):

- **Engine:** kvapky na všetkých štyroch okrajoch, jedno telo goo, pokoj a nadnesenie pri kurzore, susedia (voda, vlákno),
  ťahanie a prilepenie k okraju, pád z voľného priestoru, ponor, vlnky a vietor, neprekrývanie (22), farebné jadro,
  guľky, kapsula, veľkosť kolieskom, bublina s názvom, káva podľa `~/.config/latteos/coffee`, materiál sklenená káva,
  deň a noc a počasie pri nečinnosti (`latte-sky`), uloženie polôh.
- **Karta Goo** s uchom: riadky, nadpisy, tlačidlá v rade, dlaždice aplikácií, profil, odsek, pruh, záložky, pole na
  písanie, podponuky, šípky a Enter. Rozmer karty vychádza z rozloženia scény, logika nepočíta súradnice.
- **BarGoo:** hlava s režimom okien (ľavý klik ďalší režim, pravý ukázať plochu, koliesko), ikry okien po aplikáciách
  so strapcami, klik prepne / minimalizuje, pravý klik ponuka okna, ťahaním poradie aplikácií; pás pri okraji lišty
  patrí kvapkám (okná ho neprekryjú, ani keď sa lišta presunie k inému okraju).
- **LensGoo:** spúšťač (kláves Win) v režimoch **Aplikácie** (naposledy spustené ako dlaždice, hľadanie, kalkulačka,
  rýchle prepnutie do súborov a na web), **Súbory** (domovské priečinky, hľadanie podľa mena cez `fd`; pravý klik
  otvorí priečinok), **Web** (adresa alebo vyhľadávač, vlastný sa volí klikom) a **Príkaz** (terminál ostane otvorený,
  nebezpečný príkaz chce druhý Enter); pravý klik rýchly zoznam. Chýba režim AI, prevody jednotiek, stránky
  Nastavení a akcie aplikácie na pravý klik.
- **PowerGoo:** karta — účet, Odhlásiť, batéria, profil napájania, Uspať · Reštartovať · Vypnúť (s otvorenými oknami
  sa najprv spýta); guľky batérie; **pás výkonu** (pravý klik): CPU · RAM · GPU · VRAM z `latte-stats`, farba podľa
  záťaže a teploty, podrobnosti v bubline, susedné goo odtlačí a po vtiahnutí vráti, zapnutý ostane aj po prihlásení.
  Oproti v0.3 v bubline nie je takt, najnáročnejší proces a swap, a klik na bunku nič neotvára (Monitor ešte nie je).
- **ClockGoo:** čas a dátum s teplotou na kvapke, guľky upozornení; ľavý klik (Win+N) upozornenia a kalendár v dvoch
  stĺpcoch (akcie upozornenia, Nerušiť, Vymazať všetko; mesiac, udalosti a úlohy dňa, nová udalosť); pravý klik
  (Win+Alt+D) karta času: Prehľad · Stopky · Minútka · Budíky · Počasie. Upozornenia prijíma pleamar (je serverom
  upozornení relácie); minútka a budíky zvonia upozornením a tónom. Oproti v0.3 chýba digitálna pohoda, svetové
  hodiny a prepojené kalendáre (Google, iCloud, CalDAV).
- **MediaGoo** (13. 10., `goo/drops/mediagoo.luau`, služba `media` pleamaru — MPRIS): na ploche je, iba kým beží
  nejaký prehrávač, a kým hrá, tlčie. Ľavý klik = karta (obal, názov, interpret, Predošlá · Prehrať/Pozastaviť ·
  Ďalšia, hlasitosť, pri viacerých prehrávačoch ich zoznam), pravý = prehrať/pozastaviť, koliesko = hlasitosť.
  Overené s napodobeným prehrávačom (`tests/fake-player.py`), nie so skutočným.
- **QuickGoo** (používateľ, 13. 10.; `goo/drops/quickgoo.luau`, `goo/parts/launch.plm`): **rýchle spúšťanie**. Ľavý
  klik kvapku natiahne do pásky s ikonami aplikácií, ktoré má používateľ poruke (najviac 8); klik na ikonu
  aplikáciu spustí a páska sa zasunie, druhý klik na kvapku tiež. Aplikáciu na pásku pridá alebo odoberie LensGoo ›
  pravý klik na aplikáciu, odobrať ju dá aj pravý klik na ikonu. Kým si používateľ nič nevybral, stoja na páske
  naposledy spúšťané aplikácie.
- **Pobrežie** (používateľ, 13. 10.; `goo/parts/shore.plm`, `goo/lib/shore.luau`): **tvrdý roh** vpravo dole, kde
  goo končí — doska z materiálu šálky (ako titulky okien), dlhá podľa obsahu. Kvapky sa k nemu **nelepia**:
  pustená nad ním dopadne na dosku a odskočí do goo, na okraji sa pred ním zastaví a skĺzne mimo. Na ňom zľava:
  **okrúhla šípka**, **programy na pozadí** (klik ako v každom tray, pravý klik ponuka programu), **sieť**,
  **hlasitosť** (koliesko mení, pravý klik stlmí, zmena sa na chvíľu ukáže prstencom), na notebooku **batéria**.
  Šípka (aj Win+A) vysunie **panel až po horný okraj**: Wi-Fi a Bluetooth, hlasitosť a jas, siete, zariadenia,
  výstupy zvuku a **schránka** — čo sa naposledy skopírovalo (uchováva `cliphist`), klik to skopíruje znova.
  Hodiny v ňom nie sú, ostávajú v ClockGoo. Na ďalších monitoroch Pobrežie nie je.
- **Okno s heslom** (polkit): keď program žiada práva správcu, scéna je agentom relácie a pýta heslo kartou.
- **Nastavenia Goo** (PowerGoo › Nastavenia): karta — ktoré kvapky sú na ploche, vrátiť kvapky na miesto, materiál
  (káva / sklenená káva), živé správanie, druh kávy, tapeta, režim okien. Zmena platí hneď. Veľké Nastavenia LatteOS
  (aplikácia) ešte nie sú.
- **Zámok obrazovky** (Win+L, PowerGoo › Zamknúť; `goo/parts/lock.plm`, `goo/lib/lock.luau`): zamyká kompozitor
  (`ext-session-lock`), heslo overí systém; vyzerá ako prihlásenie v pokoji. Keby scéna pri zamknutí spadla, nová
  zamkne znova. Pri nečinnosti (hypridle, `latte-idle.service`) zamkne po 10 min, o pol minúty zhasne obrazovky,
  zamkne aj pred uspaním; film, hra či hovor (inhibítor) a okno na celú obrazovku tomu bránia. Samo sa neuspáva.
- **Goo z klávesnice** (§6.1, Win+T): šípky po kvapkách dokola po obvode, Enter a medzerník ľavý klik, Menu a Shift+F10
  pravý, + a − koliesko, Esc von; vybraná kvapka sa zdvihne, pulzuje a ukáže bublinu; skončí sám po voľbe okna,
  po voľbe v karte a po minúte.
- **Hyprland:** tri režimy okien, minimalizovanie, rozloženia okna, plochy, skratky ako vo Windows; tapeta
  (`~/.config/latteos/wallpaper` alebo tapeta LatteOS, kreslí `swaybg`); okenné tlačidlá – □ ✕ na oknách bez vlastnej
  hlavičky (plugin hyprbars so záplatou, ak je nainštalovaný; pravý klik na titulok = ponuka okna v karte Goo).

**Ešte nie je** (vráti sa po kusoch, poradie v ROADMAP):
ChatGoo (čaká na Beeper), Tvorca Goo (vlastné kvapky už sú: §4.7),
okno z bubliny (14; pád minimalizovaného okna už je), prenášanie ikier medzi monitormi, ďalší poskytovatelia AI,
portrét účtu, účty kalendárov so zápisom (CalDAV),
živé tapety a vlastný obrázok tapety, náhľad cieľa a lišta rozložení pri ťahaní okna, Nastavenia a ostatné aplikácie.
