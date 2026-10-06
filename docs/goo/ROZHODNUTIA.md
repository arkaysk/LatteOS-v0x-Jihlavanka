# LatteOS GOO — denník rozhodnutí

Rozhodnutia používateľa s dátumom, najnovšie hore. Platné znenie je vždy v [LATTEOS-GOO.md](../../LATTEOS-GOO.md);
tu je, **kedy a prečo** sa čo rozhodlo, a čo bolo zamietnuté. Podrobné pôvodné znenie (s implementačnými poznámkami
z vtedy) je v [docs_zaloha/2026-10-06-latteos-goo-pred-rozdelenim.md](../../docs_zaloha/2026-10-06-latteos-goo-pred-rozdelenim.md).
Nové rozhodnutie: jeden riadok sem (dátum, čo, prečo) a oprava platného znenia v LATTEOS-GOO.md.

## 6. 10. 2026

- **Nasadzuje sa iba engine Goo.** Pôvodná plocha Kvapky (`session/kvapky`) sa na systém už nenasadzuje.
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
| LatteOS Classic | zrušený (5. 10.) |
| nasadzovať pôvodnú plochu Kvapky | nie — iba engine Goo (6. 10.) |
