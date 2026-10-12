# LatteOS GOO — denník rozhodnutí

Rozhodnutia používateľa s dátumom, najnovšie hore. Platné znenie je vždy v [LATTEOS-GOO.md](../../LATTEOS-GOO.md);
tu je, **kedy a prečo** sa čo rozhodlo, a čo bolo zamietnuté. Podrobné pôvodné znenie (s implementačnými poznámkami
z vtedy) je v [docs_zaloha/2026-10-06-latteos-goo-pred-rozdelenim.md](../../docs_zaloha/2026-10-06-latteos-goo-pred-rozdelenim.md).
Nové rozhodnutie: jeden riadok sem (dátum, čo, prečo) a oprava platného znenia v LATTEOS-GOO.md.

## 12. 10. 2026

- **Classic:** je to celé rozhranie spred zapojenia Marey a pleamaru (lišta s tlačidlami, vysúvacie okná App Managera a
  Správcu zariadení s koreňmi v tvare L, voliteľný gif, maznáčik). Ostali z neho iba nápady; kód, ktorý GOO nepoužíva,
  sa uprace (ROADMAP „Teraz“, bod 2).
- **Znak NET** na cudzích oknách a jeho funkcia **ostávajú** — preniesť do GOO. Skúška 12. 10.: `netznak` v GOO beží,
  ale jazýček prekrýva tlačidlá okna (Firefox); treba mu nájsť miesto.
- **Živý náhľad okna:** keď je kurzor nad ikrou bežiacej aplikácie, ukáže sa náhľad ako vo Windows 11. V GOO ešte
  nefunguje — dorobiť.
- **Kapsa sa zahodí.** Správca schránky sa nepreberie, vytvorí sa inak.
- **Poradie práce** je v ROADMAP.md, sekcia „Teraz — poradie práce“; číta sa iba ona.
- **Modely pre farmu:** cieľ sú Gemma 4 a Qwen3 pod 10 GB (rýchlosť a miesto na kontext), porovnávajú sa s Edge0.

## 7. 10. 2026

- **Komunitné obchody:** je ich viac; v App Manageri má ísť pridať vlastný obchod ako v ZimaOS. Hotové: vlastný obchod
  = adresa zoznamu vo formáte Bazaar (`curated.yaml`), aby sa dal použiť každý zoznam iných distribúcií bez prevodu.
- **Tvorca Goo:** namiesto formulára „pridať príkaz“ správca/tvorca kvapiek alebo Barista, ktorý pomôže vytvoriť goo na
  mieru zo základnej ponuky (aplikácia, rýchle spúšťanie aplikácií, zobrazenie údajov) so všetkými spôsobmi ovládania.
  Hotové ako formulár v Nastaveniach › Kvapky nad tými istými súbormi JSON, ktoré engine už čítal (nie druhý formát);
  starý formulár „Vlastné kvapky“ zapisoval do kvapky.json, ktoré engine Goo nečíta — ostáva iba pre Classic
  (prechod myšou, koliesko, ľavý a pravý klik).
- **latte-lab je testovací počítač:** Claude na ňom pracuje voľne; heslo pre sudo je v gitom ignorovanom
  `.claude-local/latte-lab.md`, pokyny v `CLAUDE.md` (oboje mimo verejnej verzie).

- **Teraz používateľský zážitok** („zapoj softvér, ktorý sme sa bavili… zrealizovať funkčnosť všetkých vylepšení GUI,
  nastavení a ergonómie ovládania… aby bol LatteOS skvelý používateľský zážitok, kde všetko intuitívne pôjde a pôjde
  správne a dobre“): prednosť má zapojenie softvéru zo zoznamu záujmov (obnovenie relácie, Bottles, zoxide,
  DiskTree, LocalSend, KDE Connect, RustDesk, Voltage, Bumblebee, nočné svetlo…) a zvyky z Windowsu podľa
  `bughunt/STRESTEST.md` (kategória 4 · Ergonómia). **Prístupnosť až nakoniec alebo vo verzii Arabica.**

- **Kvapky ako 3D tekuté kvapky z Figmy („Droplu“), ale v kávových farbách:** priehľadné lesklé telo, odlesk
  zhora, svetlo prechádzajúce kvapkou, drobné bublinky vzduchu, lom toho, čo je za kvapkou. Prostriedky enginu:
  `glass` (lom svetla), odlesky, vlastné shadery. Pokus: tri odtiene (espresso, café crema, latte).
- **Ikony sú vecou prispôsobenia:** v Nastaveniach › Vzhľad › Ikony bude ponuka sád, aj farebných. Návrhy sád:
  Phosphor (duotone, obrys, plné), Tabler (dnešná), Material Symbols, Fluent; farebné Fluent Emoji 3D (MIT),
  animované Noto Animated Emoji (CC BY 4.0). Flaticon nie — jeho licencia nedovoľuje šíriť súbory ikon v otvorenom
  projekte. Porovnanie: <https://claude.ai/artifact/HDM8y4xMjo9ZN1EKKJHJxb>.
- **Nečinnosť podľa celého systému** (myš aj klávesnica): kvapky nezaspia a nehrajú sa, keď niekto píše bez myši.

## 6. 10. 2026

- **Preklady aplikácií až nakoniec** („preklady odlož nakoniec, ešte nemáme definitívne doriešené aplikácie“):
  hromadný prechod textov na `i18n.tr` sa po dvoch dávkach zastavil; pokračuje sa vývojom.

- **Vývoj a vydania:** súkromné repo má jedinú vetvu `main`; verejné repo dostáva v určitých fázach vydanie pod
  označením verzie (značka a vydanie na GitHube). Verejne sa opisuje iba LatteOS GOO — Classic sa ruší a neopisuje;
  GOO síce vychádza z pleamaru a Marey, ale je to už niečo iné. Licencia MIT. Tapety sú vlastné; maskoti patrili
  Classicu a v GOO nie sú. Zatiaľ žiadna reklama na verejné repo, autorovi pleamaru používateľ ešte napíše.

- **ChatGoo nesie pôvodnú ikonu Beepera** („ikonu pre Beeper do goo použi originálnu ikonu“), nie vlastný znak;
  znak bubliny je iba náhrada, keď sa ikona nenájde.

- **Systémový backend zapojený do Správcu zariadení:** tlač bez ovládačov od výrobcov (CUPS, IPP Everywhere /
  AirPrint, USB cez `ipp-usb`), skenovanie cez SANE a simple-scan (vlastný dialóg sa nerobí), telefón na USB cez GVFS.
  CUPS beží iba na požiadanie (`cups.socket`). Pomalé hľadanie v sieti sa pamätá a obnovuje na pozadí, aby zoznam
  zariadení ostal rýchly (LATTEOS-GOO.md §5).
- **Posuvníky sa musia dať pohodlne chytiť myšou:** pás 16 px, jazdec 8 px (pod myšou 12 px) vo všetkých oknách
  aplikácií LatteOS („myš prvá“).

- **Jeden dokument profilu používateľa** („pre každého používateľa existuje napríklad Arkay@gooconfig, kde sú
  používateľské dáta: aké goo sú aktivované a kde sa nachádzajú, aký je skin goo a okien, aké widgety sú v Noctalii,
  aká je tapeta… jeden dokument na rýchle načítanie prostredia“; „ďalší profil, okamžite“): prvá verzia
  `latte-gooconfig` — dokument `~/.config/latteos/<účet>@gooconfig.json` držaný v zhode s nastaveniami oboma smermi.
- **Hra kvapiek ako staré Worms:** skok bol na nastavenú gravitáciu príliš rýchly → realistický oblúk, pokojne aj
  vyššie; občas pohyby ako Worms (pričupenie, výskok = plíženie), občas rýchlejšia hra.
- **Zoznam záujmov nainštalovať** („aplikácie, z ktorých možno vezmeme funkcie, alebo sa rozhodne, či ich použiť alebo
  vytvoriť vlastné — nainštaluj ich“): `setup/lab/zaujmy.sh`, zoznam v ROADMAP F3·G.
- **AI — poskytovatelia** (do plánu, ROADMAP F7): výber poskytovateľa z vyskakovacej ponuky (Claude, Gemini, ChatGPT,
  Grok, DeepSeek, Perplexity, Kimi…) pre prihlásenie aj pre API, prihlásenia uložené pre každého zvlášť, prepínanie
  modelu a poskytovateľa aj z vyskakovacieho okna.
- **Optimalizácia enginu až neskôr**, keď pribudne viac funkcií; teraz iba meranie (výsledok v ROADMAP F3·G).
  Výnimka po meraní („dalo by sa nastaviť, aby prepočítaval iba obsadené miesta?“): počet miest podľa potreby
  (32 / 64 / 128) — záťaž v pokoji zo 42 % na 18 % jedného jadra.
- **Nový prihlasovač — začiatok práce** („začnime prihlasovaním“): skúšobná scéna podľa §6.2 (`login.plm`), zatiaľ
  nezapojená. Otvorené: výška hladiny; „správy“ pod hladinou.
- **Prihlásenie = zámok nad všeobecnou reláciou.** Používateľ: „Zámok po automatickom prihlásení. Ale keďže môže byť
  viac používateľov na jednom PC, na pozadí beží všeobecná relácia; samotné dáta, rozmiestnenie, nastavenia, plocha
  atď. sa načítajú až s potvrdením prihlásenia.“ Uskutočnenie: všeobecná relácia je relácia prihlasovača (účet
  `greetd`, nie konkrétny človek) s enginom Goo a scénou prihlásenia; po hesle sa spustí relácia používateľa a jeho
  plocha nadviaže na posledný obraz prihlásenia (LoginGoo → GooPower). Proces kompozitora nemôže zmeniť vlastníka,
  preto sú to dve relácie za sebou s krátkym odovzdaním obrazovky, nie jedna.
- **Kvapka prihlásenia:** zo šálky vyskočí prirodzeným oblúkom dopredu a do boku, plynule rastie (blíži sa z diaľky),
  dva odrazy; pod hladinu sa ponorí a ako ostatné goo sa vynorí nad ňu. Vo vývojárskej verzii sa na hladine v dosahu
  vynorí ešte jedno goo s výberom relácie.
- **Prihlásenie — hladina a obloha:** riadok je mierne NAD hladinou (ako pás výkonu GooPower nad lištou), hladina sa
  mierne vlní; ak vonku prší alebo je to v predpovedi, prší aj pri prihlásení; nenápadná silueta slnka alebo mesiaca
  vychádza a zapadá so skutočným v danom mieste, mesiac v správnej fáze.
- **Prihlásenie — počasie a LoginGoo:** v opačnom rohu než hodiny aktuálne počasie tým istým písmom. LoginGoo je
  o niečo väčšia a spodkom sa lepí k hladine ako kvapky enginu k lište; riadok s menom a heslom je pár mm nad
  hladinou, spojí sa s ním iba najvyššia vlnka.
- **Prihlásenie — obsah a účty:** „správy“ pod hladinou sú zdroje RSS a noviniek, ktoré si používateľ nastaví
  v Nastaveniach (ak nie je výpis pádu). Iné účty sa neukazujú (nie ako Windows 11): iba naposledy prihlásený ako
  **predvyplnené meno**, ktoré sa dá prepísať. Scéna je na **všetkých monitoroch** (jeden môže byť virtuálny).
- **Nasadzuje sa iba engine Goo.** Pôvodná plocha Kvapky (`session/kvapky`) sa na systém už nenasadzuje.
- **Ponuka prihlásenia:** ostáva najnovší **LatteOS GOO** (engine Goo, predvolená relácia `latte-session`) a samostatné
  prostredia **Marea** (treba ju opraviť), **Serpantinum** a **Noctalia (čistá)**. Položky Classic, Kvapky, „engine
  test“, SAFE a Hra z ponuky zmizli: SAFE príde sám pri pádoch alebo z GRUB-u, do hry sa prepína z plochy (`latte-hra`),
  kód Classic ostáva pod `latte-session klasicke`. Kde bude výber prostredia v novom prihlasovači (LATTEOS-GOO.md §6.2),
  je otvorené.
- **Marea na dvoch monitoroch** (latte-lab): guľa žila na vedľajšom monitore a relácia s pleamar-wm ostala čierna
  (v nastaveniach autorova tapeta, ktorá na Fedore nie je). `latte-marea` jej doplní domov = hlavný monitor LatteOS
  a platnú tapetu, iba ak chýbajú; `hypr/marea.lua` berie obrazovky z Nastavení LatteOS.
  Relácia s pleamar-wm na RX 640 vôbec neukázala obraz (ovládač nemá rozšírenie, ktoré pleamar pri odovzdaní obrazu
  monitoru žiada) — záplata `resources/patches/pleamar-linearny-dmabuf.patch`.
- **Verejná kópia `arkaysk/latteos` je zastaraná** (29. 9., pred GOO). Classic sa už nevyvíja; po dokončení enginu Goo
  sa zverejní **verejná verzia 0.2** iba s GOO.
- **Kliky jednotlivých goo** (po zhodnotení ergonómie — niektoré goo mali iba ľavý, iné iba pravý klik): hlava
  GooBaru pravý = ukázať plochu; GooPower ľavý = karta (profil účtu s portrétom a údajmi, Zamknúť · Odhlásiť, profil
  napájania, Nastavenia, Monitor, Uspať · Reštartovať · Vypnúť), pravý = pás výkonu (kapsula odtlačí okolné goo);
  LensGoo pravý = rýchly zoznam naposledy spustených aplikácií s ikonami; ClockGoo ľavý = upozornenia a kalendár
  vrátane napojených programov, pravý = ostatné (čas, stopky, minútka, budíky, počasie); karty môžu byť väčšie
  (min. 1024 × 768). **Stredný klik na ikru: nie.** **Zväčšovať sa dajú všetky goo** („každý preferuje svoje potreby“).
- **FPS v páse výkonu nie** — v hre na celú obrazovku je engine Goo potlačený, FPS by nebolo vidieť.
- **Hrozno upozornení už nebude** (nahradila ho karta upozornení a kalendára).
- **Korunka QueenGoo** (voliteľný tvar v Nastaveniach) sa ešte bude robiť — v pláne.
- **Dokumentácia:** platné dokumenty oddelené od záznamov o stave; záznamy, staré merania a staré varianty idú
  s dátumom do `docs_zaloha/` (pred zmazaním alebo závažnou zmenou). `cloud_session_1.md` (jednorazová práca
  v Claude cloud) sa nemaže, je v archíve. LATTEOS-GOO.md rozdelený na platné znenie a tento denník.
- **latte-lab:** karta na fotke je **RX 550**, detektor LatteOS ju hlási ako **RX 640** (ten istý čip Polaris 12).
- **Brainstorming nových nápadov** (večer, po prieskume trendov):
  - prijaté do plánu: odkladacia kvapka na súbory; **dlho nepoužitá kvapka sa postupne zmenšuje** (nie ikry
    GooBaru); zvuková identita (s vypínačom — „väčšina ľudí to vypne“); **podržanie LensGoo = hovor** (pri ikone sa
    pri držaní plynulo ukáže mikrofón); telefón v ClockGoo (KDE Connect); pomoc na diaľku jedným klikom; prechod
    z Windowsu (import, prehľad skratiek); režim sústredenia (zistiť, čo už má Noctalia); vrátiť späť pri zmene
    nastavení ako súčasť okna Nastavení (nie kvapka na okraji); ovládanie Goo **Steam Controllerom** (používateľ
    má prvú verziu); prenos účtu z mobilu na cudzí Goo PC — koniec roadmapy;
  - **AI je voliteľná už pri inštalácii** (voľba „systém bez AI“); `latte-mcp` na vyriešenie;
  - **stavy hladiny** (kľud, vlnenie, príboj, búrka) — na čo ich naviazať, nie je rozhodnuté; pri záťaži nemá
    rozhranie pridávať ďalšie efekty;
  - **tekuté zóny okien: áno, podľa režimu okien** — v plávajúcom (ako Windows) sa pri potiahnutí okna hore ukáže
    zhora druhá hladina a vynoria sa ponuky; páska a dlaždice po vzore niri, Hyprlandu a COSMIC (tekutý šev pri
    vkladaní, zaliatie cieľovej časti); **zatrasenie myšou** = nájdi kurzor: áno; **MCP**: áno (voliteľné);
    **zdroj výsledku v LensGoo**: áno; **pamäť obrazovky: nie**;
  - nie: ťahanie súboru na LensGoo (stačí pravý klik › Otvoriť v); gestá kurzorom (zatras, špirála) — skôr nie;
    prístupnosť zatiaľ iba minimálne.
- **Hypermoderné nápady** (po prieskume noviniek): prijaté **AirDrop kvapky** cez LocalSend, **hypruse** ako základ
  `latte-mcp`, **vylepšenia App Managera a obchodu** (Bazaar), **synchronizácia zariadení** (Syncthing / any-sync)
  a celé **prostredie Súborov nad pôvodným súborovým systémom** („príjemné prostredie, kde sa dá všetko intuitívne
  spravovať“); bublina odchádzajúceho spojenia na rozhodnutie — prekrýva sa s povolením Flatpaku a tlačidlom NET;
  nie: plátno ako štvrtý režim, bublina „vrátiť späť“ pri zatvorení, Gradia (skôr nie), živé titulky (vec
  videoprehrávača).
- **Ďalšie kolo:** **obnovenie relácie** áno; ikra/kvapka, ktorá hrá zvuk, sa **vlní ako reproduktor** a má vlastnú
  hlasitosť v kontextovej ponuke; **kto žerie energiu, dáta, RAM a disk s priebehom po dňoch** patrí do Monitora;
  prostredie Súborov sa ešte musí doriešiť; nie: koliesko na ikre = hlasitosť, poradie spotreby v karte GooPower,
  Kazeta (skôr nie).
- **Projekty z GitHubu:** áno **Voltage** (webové aplikácie, pôvodný), **DiskTree** (v Monitore aj v Súboroch),
  **Bottles**, **Zoxide** (LensGoo aj Súbory); dialóg súborov cez portál v jednotnom vzhľade s oknami;
  **Flea** odložená — pozrieť na latte-lab, možný fork FleaGoo; zatiaľ nie Distrobox a Toolbx; Omarchy skôr ako
  zdroj nápadov s AI.
- **AI podľa Omarchy:** áno „Prečo to spadlo?“; zručnosť LatteOS pre AI asi áno; pomocník je **Barista**,
  vyvolateľný kontextovou ponukou okna (pravý klik); limity predplatných patria do AI karty v LensGoo (čip spotreby).
- **Newelle** ako možné jadro AI — v systéme nemajú byť dve veci, ale jedna použitá dvakrát (LensGoo + samostatné
  okno); **Bumblebee**: áno, upozornenie na napadnutý balík aj pre bežného používateľa; **deň a noc na hladine**:
  automatický režim mení nočné svetlo, vzhľad okien aj žiaru a odlesky na kvapkách podľa dennej doby.
- Správca súborov bude ako Total Commander s dvoma panelmi, alebo náš fork Total Commandera.
- Ovládacie centrum Noctalie sa otvára **nad rohovou lištou vpravo** (predtým vľavo, zvyšok plochy Kvapky).
- Na zváženie (nerozhodnuté): „Zásady pre engine Goo“ v README (samostatný daemon, Quickshell ako vizuálna vrstva,
  zbernica `goo.emit`) oproti dnešnému enginu (scéna pleamar, logika Luau, pomocník `latte-goo`).

## 5. 10. 2026

- **Smer:** „gamerdistro“ sa stáva **LatteOS GOO**, jedinou edíciou; **LatteOS Classic sa ruší**; vetva
  `gamerdistro` je `main`. **Predvolené prihlásenie bude engine Goo** (prihlasovanie sa prerobí).
- **„Ideme podľa Novej architektúry“** (dokument z 2. 10. 23:55): jadro GooBar, GooPower, LensGoo; voliteľné QueenGoo,
  ClockGoo (TimeGoo + DaNoGoo), ChatGoo.
- Pravidlo 22 spresnené naživo: kvapky sa neprekrývajú ani pri vzdialenom kurzore a pri hre; zvýraznený okraj
  zliatych kvapiek je spoločný (jedno goo telo aj pre GooBar a ikry).
- **Pokoj:** kvapky si pri lište sadnú pod hladinu a sploštia sa („ešte o pár pixelov viac“).
- **Gravitácia platí na každú kvapku:** pustená vo vzduchu spadne — „pád má byť pád, nie výstrel“; kvapky sa lepia
  ku **každému okraju**, nielen k dnu.
- Vlákna: vzdialenosť krajných kvapiek na snímke používateľa je maximum (2,3 súčtu polomerov); korene hrubšie.
- **Rohová lišta Noctalie je zakázaná zóna** (premenlivá šírka).
- Karty z kvapiek: koliesko kdekoľvek v karte prepína záložky; okná môžu byť väčšie, minimalistické a „futuristicky
  pohyblivé“; hardvér najviac 10–15 rokov, rozlíšenie nikdy pod 1024 × 768; **LensGoo aj klávesom Windows**, režimy
  Tab; **po príkaze ostane terminál otvorený**.
- Ucho ako v starej verzii (kvapka v rohu karty — malá bodka pri kliku bola „škaredá“); **horná hrana okna nesmie
  skákať** pri prepínaní záložiek.
- **Prístupnosť z klávesnice** — návrh schválený („beriem tvoje návrhy, spíš to, ale ešte nevytváraj“); zamietnuté
  AltGr ako ľavý klik a medzerník ako pravý klik (pozri nižšie).
- Klik tlačidlom bez funkcie = goo **zavibruje**; **veľkosť 50–220 %** („vyfúknutá môže byť polovičná“), s ňou text,
  ikona a menej detailov v malom goo (predtým 100–220 %).
- Hotové doplnky backendu zhodnotené: použiť existujúce (NetworkManager, plocate/fd/ripgrep, GVFS, CUPS/SANE, BlueZ,
  firewalld, fwupd, poppler + Flatpak prehliadač, GStreamer/PipeWire), nie KDE knižnice.
- **Nový prihlasovač** (šálka, kvapka, hladina, LoginGoo → GooPower) — zadanie, zatiaľ nevytvorené.
- **Obchod podľa ZimaOS** — „aktuálna ponuka je nedostatočná“; zapísané, nevytvorené.

## 1. 10. 2026

- Poradie práce: „neskákať, dokončiť rozrobené, potom mechanika Goo a ovládanie myšou“.
- **Kvapka sa k oknu pripája rohom** (pravidlo 9); **všetky kvapky sú drag & drop** (16); **okno z kvapky sa rodí
  z bubliny**, zatvorenie = prasknutie, minimalizácia = pád do lišty so žblnknutím (14).
- **Goo má vlastný vzhľad ponúk** (10); štýl okien podľa hľadania Windows 11 a spúšťača Noctalie (11); materiál
  a textúry tém, perleťové okraje skla (12); **sklo Hyprglass** na oknách (13, podľa ukážky „Caelestia + Hyprglass“).
- **Farby guliek:** červená hardvér, zelená sieť, modrá softvér (15).
- Večer: farebné jadro (17), vlnky na hladine (18), vietor (19), kratší krk a návrat ako v Marei (20), ostré oká (21),
  neprekrývanie (22).
- Spájanie vláknami iba na vzdialenosti trojice vypínač – Hodiny – lišta (všeobecný sliz k vzdialeným objektom
  zamietnutý ako neprirodzený).
- Základ shellu z goo maskota Marey (k4ditano): viac špecializovaných kvapiek namiesto jednej na všetko.
- **QueenGoo:** ľavý = App Manager, pravý = Správca zariadení; nevyskočí ako roh okna, vypľuje bublinu.
- **Rozhovor s AI vždy vnútri, nikdy v prehliadači, bez API kľúča** (cez prihlásené CLI: Claude Code, Gemini, Codex) —
  záväzné.
- **ChatGoo** ako doplnok pre Beeper, nie vlastný messenger; nie je nutný (alternatíva: ikona v rohovej lište).
  Bubliny četov pre viac kanálov — forma sa premyslí, nie ako režim spúšťača.
- **Živé bytosti pri nečinnosti** (dážď/vietor podľa počasia, hra) — zadanie.
- **Engine Goo** — zadanie: jedny pravidlá pre všetky kvapky, rozšírenie pleamaru, ktoré prežije jeho aktualizácie;
  kurzor iba priťahuje.
- Nastavenia: hlavné sú Nastavenia LatteOS (potrebujú prácu — tapety zjednotiť), z Noctalie selektívne.
- Farba upozornení: čistá farba ikony aplikácie.

## 30. 9. 2026

- Hodiny sú **digitálne** (ručičkové hodiny Marey nie); goo guľôčky vnútri dashboardu nie; v páske sa nič
  neminimalizuje (ako niri).

## 29. 9. 2026

- Kvapky **nemajú oči ani tvár**; **horná kvapka ako v Marei zamietnutá** — návyk z Windows: všetko dole.

## Zamietnuté (a prečo)

| nápad | rozhodnutie |
|---|---|
| oči na kvapkách, tvár | nie (29. 9.) |
| horná kvapka ako Marea | nie — návyk z Windows: všetko dole (29. 9.) |
| farby kvapiek podľa témy | nie — kvapky sú vždy káva (voda/mlieko); textúry iba na kartách a oknách |
| ručičkové hodiny + bočné okienko (Marea) | nie — digitálne hodiny (30. 9.) |
| goo guľôčky vnútri dashboardu | nie — nepôsobili dobre (30. 9.) |
| vzhľad ponúk z klasického LatteOS v Goo | nie — Goo má vlastný vzhľad ponúk (1. 10.) |
| jedno pole hľadá všetko naraz | nahradené ikonou režimu / záložkami (1. 10.) |
| klik odlepí lištu | nie — odlepí iba ťahanie |
| celý strapec sa fyzicky oddelí od okraja | nie — strapce sú ťažké, drží ich okraj |
| minimalizovanie v páske | nie — ako niri (30. 9.) |
| holý Hyprland a gamescope-session v zozname relácií | skryté — nedá sa z nich odísť myšou |
| kód komunitných doplnkov Noctalie v pleamare | nie — stav doplnku je v Noctalii; namiesto toho rohová lišta Noctalie |
| sieť slizu k vzdialeným objektom | nie — neprirodzené; spájanie iba na vzdialenosti trojice (1. 10.) |
| AltGr ako ľavý klik (prístupnosť) | nie — AltGr píše znaky @ # { } [ ] € \ \| na slovenskej klávesnici (5. 10.) |
| medzerník ako pravý klik (prístupnosť) | nie — medzerník je všade „stlač tlačidlo“ (5. 10.) |
| „ostrovy“ (samostatné telá skupín kvôli výkonu) | netreba — záplata `pleamar-pasy-tela` (5. 10.) |
| FPS v páse výkonu | nie — hra na celú obrazovku je nad vrstvou Goo (6. 10.) |
| hrozno upozornení na lepkavom vlákne | už nie — nahradila ho karta upozornení a kalendára (6. 10.) |
| stredný klik na ikru okna | nie (6. 10.) |
| plátno (nekonečná plocha) ako štvrtý režim | nie (6. 10.) |
| bublina „vrátiť späť“ po zatvorení okna | nie (6. 10.) |
| živé titulky v celom systéme | nie — je to vec videoprehrávača (mpv/VLC + titulky z whisper) (6. 10.) |
| Gradia (úprava snímok obrazovky) | skôr nie (6. 10.) |
| koliesko na ikre = hlasitosť aplikácie | nie — hlasitosť v kontextovej ponuke zvučiacej ikry (6. 10.) |
| spotreba energie v karte GooPower | nie — patrí do Monitora (s priebehom po dňoch) (6. 10.) |
| Kazeta (hry ako kazety) | skôr nie (6. 10.) |
| LatteOS Classic | zrušený (5. 10.) |
| nasadzovať pôvodnú plochu Kvapky | nie — iba engine Goo (6. 10.) |
| SAFE Classic (labwc + shell Noctalie) | nahradí **SafeGoo** — engine Goo bez GPU (labwc + pixman + llvmpipe) so zložkami GooBar, QueenGoo, LensGoo, GooPower, ClockGoo a novou kvapkou SafeGoo v rohu (8. 10.) |
| SafeGoo: statické kvapky (bez pružín, dýchania, naťahovania za kurzorom), jednoduché ako pôvodná Marea | áno — softvérové kreslenie plného `goo.plm` je ~1 s na snímku; vlastná scéna `safe.plm` (8. 10.) |
| SAFE cez engine Goo (SafeGoo z plného Goo) | nie — samostatné núdzové rozhranie `safe.plm` bez engine Goo (8. 10.) |
| Barista inštalácia Windows programov: bez Flatpaku, natívny Wine + `bwrap` | áno — Wine prefix je `C:\`, sandbox `bwrap` (test 8. 10.: domov a zdieľania nevidno, zápis len do priečinka hry) (8. 10.) |
| Inštalačný priečinok hry: `~/Hry/<id>/` s `manifest.json`, `prefix/`, `logs/` | áno — odinštalovanie zmazaním podľa registra, záloha tarom (8. 10.) |
| Zdroj inštalátora (ISO, CD, priečinok) sa len pripája na čítanie, nekopíruje | áno (8. 10.) |
| Neznámy zdroj: sieť počas inštalácie vypnutá, zapnutie len samostatne a viditeľne | áno (8. 10.) |
| Barista: Wine alebo Proton rozhoduje sám, bez AI a bez pomoci používateľa | áno — recepty (vlastné + komunitné: Lutris, umu, winetricks, AppDB, ProtonDB) → pravidlá z PE (rok, API, architektúra) → reťaz pokusov so snímkou prefixu; AI len voliteľne (8. 10.) |
| Základ pre cudzie programy (wine, winetricks, bubblewrap, umu, GE-Proton, Waydroid, 7zip, DOSBox) je v systéme od čistej inštalácie | áno — f0-install.sh (HRY) + setup/f1/hry.sh; Proton v /opt/latteos/proton (8. 10.) |
| v0.4 Fresh: čistý strom vo vetve `v0.4-fresh`, stav pred ním pod značkou `v0.3-archive` | áno — iba prihlasovanie Goo, LatteOS SAFE a LatteOS GOO; strata časti funkcií je prípustná, obnoví sa testovaním (12. 10.) |
| Noctalia v relácii GOO (rohová lišta, Nerušiť, akcie relácie, prehľad okien) | preč vo Fresh — nahradia ju služby pleamaru a stránky z Marey; doplnky Noctalie tým odpadnú, čím padá aj dôvod rohovej lišty z 1. 10. (12. 10.) |
| slovenské mená príkazov, súborov a komentáre v kóde | nie vo Fresh — anglicky; text na obrazovke iba cez `tr()` so spoločným jazykovým súborom (12. 10.) |
| aplikácia menuje inú aplikáciu priamo (napr. Súbory a Monitor → Heidelberg) | nie vo Fresh — kto čo otvára, vie jedno miesto (12. 10.) |
| skill `pleamar` od autora (`pleamar --install-skill`) | áno — nainštalovaný 12. 10.; scény a logika sa píšu podľa neho (logika nekreslí a nepozná súradnice) |
| relácia LatteOS Game (Steam Big Picture v gamescope) v ponuke prihlásenia | ostáva, zatiaľ — aj vo Fresh (12. 10.) |
| Fresh: starý kód | celý strom v0.3 do `old/` ako predloha; kód sa píše načisto so skillom `pleamar`, podľa starého, ale lepšie (12. 10.) |
| Fresh: zoznam súborov `FILES` (čo LatteOS pridal do systému) | áno, od prvého kusu — aby sa dal odinštalovať; inštalátor a odinštalovanie až neskôr (12. 10.) |
