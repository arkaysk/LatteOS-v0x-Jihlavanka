# Kvapky — tekutá lišta LatteOS (prototyp)

Koncept: [AUDIT-WIN11.md › Koncept „Kvapky“](../../AUDIT-WIN11.md) (súkromné repo), maketa D na plátne dizajnu.
Beží na [pleamar](https://github.com/k4ditano/pleamar) (BSD-3, Rust + wgpu, SDF, pružiny) **vedľa** Noctalie,
ako samostatná vrstva (layer-shell) nad jej lištou.

## Čo prototyp vie (29. 9. 2026)
- zámerne nesúmerná: hlava s očami je vždy na **ľavom** konci, kvapka rastie doprava s každým oknom (ikona + hrbolček)
- v pokoji vpitá do spodného okraja obrazovky (zlieva sa s ním skoro do roviny)
- **priblíženie**: od štvrtiny výšky obrazovky od nej sa začne vysúvať; kým k nej myš dôjde, je napoly vonku na hrubej
  stopke pod hlavou. Myš sa číta kdekoľvek (`cursor.x/y` z Hyprlandu), žiadna neviditeľná zóna nekradne kliky oknám
- **Hodiny namiesto Štartu** (plocha Kvapky): čas a dátum (deň v týždni cez preklady, `clock.date` je iba po
  anglicky) sú vidieť stále, aj v úzkom páse. **Upozornenia** sú farebné kvapôčky na Hodinách (nízka mätová, bežná
  jantárová, kritická červená); nové do nich spadne a vyleje sa pri nich bublina „aplikácia · nadpis“ na 6 s.
  pleamar je vtedy server upozornení — iba v ploche Kvapky, v klasickej ich má Noctalia
- **dashboard** vyteká z Hodín (klik na Hodiny): veľký čas, dátum, počasie (Open-Meteo, miesto z Nastavení ›
  Prihlasovanie), **hľadanie aplikácií** (úloha Štartu; píše sa hneď, ↑↓ Enter), upozornenia (klik = otvoriť,
  „Vymazať všetko“), pripnuté (`~/.config/latteos/pripnute`, id .desktop po riadkoch). Esc alebo klik mimo zavrie
- **každá kvapka sa dvíha sama** (30. 9., po teste myšou): podľa vzdialenosti kurzora od nej — nad vypínačom
  najvyššie vypínač, sused (Hodiny) trochu, lišta nie; sused sa pridá iba o 30 % (goo ho ťahá)
- **lišta sa od okraja neodlepí sama**: pri myši sa iba vynorí a dnom sa stále dotýka okraja; odlepí ju iba ťahanie
- **kvapka sa stane oknom** (ako v Marei): pri otvorení dashboardu sa kvapka Hodín odlepí od lišty, dopláva do rohu
  dashboardu a karta z nej vyrastie — nič sa neprekrýva, na lište ostane iba mláka; pri zatvorení späť. Rovnako
  vypínač a ponuka Vypnúť
- **lišta je uväznená váhou**: guľôčky pri lište sedia na okraji s meniskom (široká „voda“ pod celou šnúrou),
  strapce z nich rastú hore, ale celý hrozen sa od okraja fyzicky neoddelí — iba ťahaním
- **až 20 okien** v lište (strapce ich zhustia); koliesko nad lištou v plávajúcom režime prepína iba okná na
  ploche, bez minimalizovaných (cez Wayland sa pri tom ukázala celá skrytá plocha `special:minimized` a nové okná
  sa otvárali na nej — vyzerali ako nespustené); LatteOS túto plochu pri prepnutí okna vždy zavrie
- **páska ako v niri** (30. 9.): v páske sa nič neminimalizuje — pri prepnutí do pásky sa minimalizované okná vrátia
  na pásku, tlačidlo – a skratky okno iba pošlú z pohľadu (páska prejde na ďalšie okno), klik na aktívnu guľôčku
  okno vycentruje. Koliesko nad lištou (alebo Super + Shift + koliesko kdekoľvek) pásku plynulo posúva o štvrť
  obrazovky; pohyb okien animuje Hyprland aj pri téme bez efektov (`latte.tape_motion`, nie v hernom režime ani pri
  Prístupnosť › Bez animácií). Dlaždice v páske: okno ťahané za titulok pustené do stredu iného okna sa pridá do
  jeho stĺpca, pustené k jeho okraju (30 %) vytvorí nový stĺpec (Hyprland scrolling layout)
- **minimalizované okná** sú v lište menšie guľôčky so stlmenou ikonou (logika ich zistí z `hyprctl clients`
  každých 700 ms); koliesko ich vynecháva, klik ich vráti
- **rovnaké okná sa nepletú**: guľôčka hľadá okno podľa triedy, titulku a poradia (piaty terminál „~“ je piate
  okno „~“ v Hyprlande) — predtým všetky guľôčky terminálov prepínali to isté, prvé okno
- **obraz režimu v hlave**: cez hlavu kvapky akoby presvitajú okná — páska (pás okolo valca), plávajúce (nad sebou),
  dlaždice; pri prepnutí sa okienka prelejú, myš nad hlavou obraz zvýrazní
- **guľôčky aj v dashboarde a ponuke Vypnúť**: pripnuté aplikácie a rýchle nastavenia sedia v goo guľôčkach spojených
  lepkavým vláknom (myš guľôčku nafúkne a vlákno zhrubne), riadky ponuky Vypnúť sú kapsuly zliate do stĺpca
- **pod oknom využije voľné miesto**: logika zmeria miesto po najnižšie okno (`room`), lišta sa vysunie presne po
  jeho spodok a strapce sa v tom páse rozložia nepravidelne (cik-cak) — bez prekrytia okna
- ponuka okna (pravý klik na guľôčku) pri kurzore: poloha priamo od Hyprlandu (`hyprctl -j cursorpos`)
- **ťahanie guľôčky okna** (drag & drop): ide za myšou na lepkavom vlákne (ťahaním sa tenčí, nepretrhne sa);
  pustená medzi inými presunie svoju aplikáciu na to miesto v lište (poradie si logika pamätá), inde sa pružne
  vráti s vlnou; klik bez ťahania = prepnúť okno (po pustení)
- **lepkavé vlákna** (30. 9., podľa obrázka medu): guľôčka pri lište visí na okraji tenkým vláknom, ostatné v strapci
  na nej — hrozen sa nikdy neoddelí od okraja; okná sú guľôčky vo všetkých režimoch (v Dlaždiciach predtým zmizli)
- **ponuka Vypnúť** vyteká z kvapky vypínača (klik): Zamknúť, Odhlásiť sa, Uspať, Reštartovať, Vypnúť — akcie robí
  Noctalia (`noctalia msg session …`), rovnako ako ponuka LatteOS; klik mimo zavrie
- **ovládacie centrum v dashboarde**: tlačidlá Sieť / Bluetooth / Zvuk prepínajú, klik na ich popis („Sieť ›“) otvorí
  stránku so zoznamom (siete — známa sa pripojí, nová zabezpečená otvorí Wi-Fi v Noctalii kvôli heslu; zariadenia
  Bluetooth — pripojiť/odpojiť; výstupy zvuku — predvolený), „‹“ späť; „Nastavenia“ = Nastavenia LatteOS
- **strapce okien (ikry)**: okná tej istej aplikácie sa zlepia do strapca — prvé pri lište, ďalšie smerom od nej,
  „náhodne“, ale pre každé poradie rovnako; čím viac okien, tým menšie guľôčky (do 72 %). Myš nad strapcom ho
  rozvinie do radu v plnej veľkosti (po odchode sa o 0,5 s zbalí), okno cez celú obrazovku (`tight`) všetko zrovná
  do jedného radu v páse. Rozloženie počíta logika (`model lay`), scéna guľôčky ťahá pružinami. Skupina a ikona =
  aplikácia zo spúšťača (.desktop, služba `apps`): podľa StartupWMClass, id alebo jeho koncovky (Flatpak), aplikácie
  LatteOS (zatiaľ všetky `org.quickshell`) podľa titulku = Name spúšťača
- **tvar ako tekutina v nízkej gravitácii (goo)**: šnúra guľôčok namiesto tuhej kapsuly — hlava vľavo je najväčšia
  guľa, každé okno vlastná guľatá kvapka spojená so susedkami krkom a tenkým vláknom; kvapky pomaly dýchajú a plávajú
  (každá inak), aktívne okno je plnšie, každá guľa má vlastný odlesk; nové/zatvorené okno pošle šnúrou vlnu
- **neprekryje program**: keď ktorékoľvek viditeľné okno na ploche siaha k lište (maximalizované, na celú obrazovku, dlaždice/páska), kvapka
  ostane v páse 64 px aj pri myši (`fact tight`, logika kontroluje aktívne okno každých 0,7 s); celú obrazovku
  (hry, video) Hyprland aj tak kreslí nad vrstvou kvapky
- **pás pre kvapku** v ploche Kvapky: rezerva monitora 54 px + medzera 10 px pri okraji lišty
  (`latte.kvapky_reserve`, hyprland.lua) — rešpektujú ju aj maximalizované okná, ktoré medzery `gaps_out` ignorujú
- **obsah je vždy káva**: téma LatteOS je hrnček (materiál okien — sklo, kov, zlato, krištáľ…), kvapky sú káva
  v ňom. Líši sa len pomer vody a mlieka (`~/.config/latteos/kava`): espresso, ristretto, lungo, americano
  (voda = priesvitná), macchiato, cortado, flat white, cappuccino, latte (mlieko = svetlejšia, ikony tmavé),
  čierna s mliekom. Výber patrí do Baristu: „Akú si dáte kávu a do čoho?“ (hrnček = téma, káva = kvapky)
- **tekutina žije sama**: okolo vypínača a Štartu kvapky pomaly vystupujú z okraja a klesajú, driftujú, mláka pri
  okraji sa rozlieva a sťahuje, vlákna sa samy tvoria a trhajú a po nich tečie kvapôčka; myš to zosilní
- **bez okien guľatá**: kruh vpitý do okraja, zlieva sa s ním plynulo (radiálne); s oknami sa predĺži
- **vlastné menu nemá — presun ťahaním (drag & drop)**: chytiť a ťahať od okraja → stopka sa natiahne a pri 0,9
  praskne, kvapka (guľa) ide za myšou s oneskorením. Pustená do 170 px od **ľubovoľného okraja** sa k nemu prilepí
  (ako presun panela úloh vo Windows; hlava tam, kde bola pustená) a okná uhnú na tej strane. Pustená uprostred
  **skvapalní, stečie** a lišta sa vynorí tam, kde bola. Pustená skôr, než stopka praskne: vráti sa. Klik nerobí nič
- okraj si pamätá `latte-kvapky okraj` (`~/.local/state/latteos/kvapka-okraj`); scéna je celá obrazovka (kliky
  berú iba zóny), kreslí sa v „rámci okraja“ a skupina ho otočí k okraju; ikony a nápis stoja rovno
- stopka: okraj je „voda“ pod obrazovkou roztavená s telom ako v Marei, pod hlavou stĺpik roztavený s oboma koncami
- **objem** bez textúry: svetlo zhora, lem, tieň (keď je vonku) z pleamaru + mäkký odlesk pozdĺž hornej hrany a lesklá
  bodka na hlave. (Latte art shader sme skúsili a vyradili – v histórii: 3bddc26.)
- **bez očí** (29. 9.): žiadna kvapka nemá tvár; hlava ostáva ako hrbolček na ľavom konci (nesúmernosť)
- **kvapky na seba pôsobia**: pri vysúvaní sa nakláňajú k susedovi a spájajú ich goo vlákna (vypínač ↔ Štart ↔
  lišta), roztavené s oboma koncami; odtrhnutá lišta vlákno k Štartu natiahne a pretrhne; myš nad kvapkou ju
  nafúkne a susedov k nej pritiahne; stlačenie prebehne vlnou cez susedov
- **základňa kvapky** (telo a hlava): ľavý klik na hlavu = režim okien (na telo nič — klik vedľa guľôčky prepínal) (plávajúce → dlaždice → páska), koliesko nad
  kvapkou = okná (páska = plynulý posun pásky, plávajúce = ďalšie okno zľava doprava, dokola), ťahanie ľavým aj pravým = presun, pravý klik nič
- **hrbolčeky s oknami** majú vlastné kliky: ľavý = prepnúť na okno, aktívne sa minimalizuje (ako vo Windows;
  minimalizuje LatteOS na special:minimized, Hyprland žiadosť z protokolu ignoruje), pravý = ponuka okna pri
  kurzore; ťahanie z hrbolčeka kvapku nepresúva
- texty po anglicky + `translations sk` (jazyk podľa `LANG`, prepína sa za behu)

## Plocha LatteOS Kvapky (skúšobná relácia)
Klasická lišta a jej pomocníci vypnutí (lišta Noctalie, netznak, kapsavyrez, náhľad, plocha, rýchle nastavenia,
pohoda, maskot, živá tapeta QML) — ostáva **živá tapeta** (latte-tapety, mpvpaper; statický obrázok tiež cez mpvpaper),
**kvapky** (lišta, Hodiny s dashboardom, vypínač), Noctalia bez lišty (nižšie), Kapsa, App Manager a systémové
ponuky (kvapka **vypínač**, Ctrl+Alt+Del).
- **ponuka**: na prihlasovacej obrazovke relácia **LatteOS Kvapky** (`latte-session kvapky` → `LATTE_VARIANT=kvapky`
  → hyprland.lua spustí `latte-kvapky start`; zdravá, keď po 60 s beží pleamar)
- bez odhlásenia: `latte-kvapky skusit` (z klasickej plochy) a `latte-kvapky spat` (späť), `latte-kvapky stav`
- okná nechajú pri okraji lišty 64 px pre kvapku (rezerva monitora, Noctalia si pás vyhradí sama); platí aj po
  reload-e konfigurácie (príznak `$XDG_RUNTIME_DIR/latteos/kvapky` s okrajom)
- Hodiny a vypínač sú kvapky vľavo od hlavy, vpité do okraja, pri myši sa vysunú; neodtrhávajú sa

**Previazanie s Noctaliou (latteGoo):** Noctalia v ploche Kvapky beží ďalej, ale bez lišty, bez tapety a bez servera
upozornení (`latte-kvapky` jej pripraví variant konfigurácie v `$XDG_RUNTIME_DIR/latteos/noctalia-kvapky`: odkazy na
základ + `zz-kvapky.toml`; Noctalia zlúči všetky `*.toml`). Robí to, čo vie: zamknutie (Super+L), Alt+Tab, snímky, OSD
hlasitosti a jasu, klávesy médií, ovládacie centrum (tlačidlo „Viac“ v dashboarde), Nastavenia. Upozornenia sú
kvapôčky (pleamar), tapetu kreslí latte-tapety cez mpvpaper. Super otvára dashboard (latte-spustac to v Kvapkách
presmeruje). Rýchle nastavenia v dashboarde: stav zo služieb pleamaru, prepínanie cez `noctalia msg` (Wi-Fi,
Bluetooth, stlmenie, ovládacie centrum), hlasitosť ťahaním.

**Prekladová vrstva:** texty scény sú po anglicky + `translations sk`, dáta (názvy aplikácií, upozornení) sa
neprekladajú, počasie sú znaky. Dlh: prihlasovacia obrazovka (greeter/shell.qml) má popisy relácií natvrdo po
slovensky — má ich brať z `Comment[jazyk]` súborov relácií; slovenský preklad Noctalie je neúplný (ovládacie
centrum: „Home“, „Nothing Playing“) — doplniť a poslať upstream.

**Kvapka a okno (29. 9.):** s kvapkou sa zlieva iba **jedinečné systémové okno**, ktoré z nej vyteká (hľadanie,
App Manager, Súbory/Hardvér z rohových kvapiek) — ako karta hľadania z kvapky v Marei. Bežné aplikácie (aj Task
Manager) majú klasickú hornú lištu (hyprbars): nepatria systému, kvapka ich neskrýva. Preto žiadna dekorácia
rámu v kompozitore.

## Spustenie (latte-lab)
```
resources/fetch.sh pleamar && (cd resources/upstream/pleamar && git apply ../../patches/pleamar-hyprland-okna-8bit.patch && cargo build --release)
PLEAMAR_GENERIC=window resources/upstream/pleamar/target/release/pleamar --scene session/kvapky/kvapka.plm --no-hud
```
Potrebuje pleamar so záplatou [pleamar-hyprland-okna-8bit.patch](../../resources/patches/pleamar-hyprland-okna-8bit.patch):
`PLEAMAR_GENERIC=window` berie zoznam okien z wlr-foreign-toplevel (socket Hyprlandu hlási iba aktívne okno), kurzor
ostáva z Hyprlandu; a 8-bitová plocha, inak Hyprland všetky tmavé farby zosvetlí.
Po inštalácii novej scény pleamar reštartovať (`pkill -x pleamar; latte-kvapky start`): pri živom načítaní ostane
zoznam okien (model `wins`) zo starej scény, kým sa niečo nezmení.
Kontrola bez spustenia: `pleamar --check session/kvapky/kvapka.plm`. Stopka na skúšku bez myši:
`pleamar --say kvapka "fact probe 75"` (0 = späť na myš), okraj: `"fact side vlavo"`, stečenie: `"fact melting true"`,
dashboard: `"fact dash true"`, hľadanie: `"text query fi"`.
`reserve: -1`: inak by Hyprland plochu posunul nad vyhradený pás lišty Noctalie a „okraj“ by visel 68 px nad
skutočným okrajom.

## Namerané (latte-lab, RX 640, 2560×1080 @ 144 Hz, stupeň Plný, video tapeta)
| | pleamar | Hyprland | GPU | RAM |
|---|---|---|---|---|
| bez kvapky | — | 37 % | ~42 % | — |
| kvapka 144 Hz | 12 % jadra | 38 % | ~37 % | 63 MB |
| kvapka `rate: 60` (predvolené) | 6 % jadra | 38 % | ~41 % | 63 MB |
| + stopka, nové oči, latte art (vyradený) | 7,6 % jadra | — | — | 80 MB |
| bez textúry, kurzor z Hyprlandu (30×/s), 8-bit plocha | 8,8 % jadra | — | — | 65 MB |
| plocha Kvapky, scéna cez celú obrazovku (bez Noctalie) | 8,8 % jadra | 21 % | — | 67 MB |
Prvá snímka ~90 ms od štartu, priemerná snímka 7,3 ms.

## Ďalej
spúšťač a ponuka Vypnúť majú vytiecť z kvapky Štart / vypínač (dnes sa otvoria na svojom starom mieste); sada kvapiek v rohu (hodiny, rýchle nastavenia, Kapsa, Súbory, Hardvér) s panelmi,
ktoré z kvapky vytečú; náhľad okna pri prejdení myšou; farba čierna káva ↔ latte; maskoti Homebrew a drak;
vlastné `app_id` pre aplikácie LatteOS (dnes všetky `org.quickshell` → rovnaká ikona).
