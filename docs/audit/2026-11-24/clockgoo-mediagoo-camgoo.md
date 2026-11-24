# Audit: ClockGoo, MediaGoo, CamGoo (24. 11. 2026)

Rozsah: `goo/drops/clockgoo.luau`, `mediagoo.luau`, `camgoo.luau`, `goo/lib/timers.luau`, `goo/lib/card.luau`,
`goo/parts/{calendar,clock,cam,card,rows}.plm`, `bin/latte-{sky,cam,cal,nameday,focus}`, `goo/lang/sk.plm`, snímka
`docs/screenshots/clockgoo.png`. Iba čítanie kódu; `pleamar --check goo/goo.plm` = ok (11 257 vlastností).
Značky: **[overené v kóde]** = vyplýva priamo z kódu; **[podozrenie, treba naživo]** = treba overiť na ploche.
Závažnosť: vysoká / stredná / nízka. Pri každom návrhu je, či je to **oprava pred 0.6** alebo **funkcia po 0.6** (ROADMAP „Poradie práce“: do 0.6 iba opravy).

## Zhrnutie

- **Upozornenia sú najslabšie miesto.** Nová karta ľavého kliku (kalendár, návrh z 21. 10.) schová upozornenia za tlačidlo.
  Chýba v nej Vymazať všetko, Zahodiť, akcie na pravý klik, Nerušiť aj „+N ďalších“. Klik na lístok v rohu pritom otvorí **starú** kartu.
  Pre človeka z Windows 11 je to hlavný rozdiel oproti centru oznámení.
- **Blikanie ClockGoo pri otváraní má konkrétnu príčinu v kóde** (istota stredne vysoká). Pružina `land` pri prvom podkmite
  (p = 0,84, namerané v bughunte) stiahne rám karty na ~59 % šírky (`t³`) a obsah na 68 % krytia, asi na 60–80 ms. Najviac to
  vidno na najširšej karte, teda kalendári.
- **Zatváranie karty už neodskakuje.** Kriticky tlmená pružina `shut` je v kóde od 12. 11. (`911a708`), čiže možnosť 2 je už
  urobená. ROADMAP 6.30 / 10J.22 a bughunt ešte opisujú stav pred touto zmenou. Ak niečo ešte bliká, sú to staré snímky skla (`lens`).
- **Budíky:** zvonia iba ~1,2 s (tri tóny). Budíky 7–10 zvonia, ale nedajú sa uvidieť ani vypnúť. „Najbližší budík“ v Prehľade chýba.
- **Bez siete:** počasie ukazuje kedysi uloženú predpoveď ako „AKTUÁLNE“, bez nej ostane osamotené „°C“. Meniny zmiznú, hoci súbor
  s nimi sa inštaluje.
- **Slovenčina a čitateľnosť:** zlý tvar dátumu („Utorok, 24. November“), chýbajú množné čísla, DOP./POP. pri 24-hodinovom čase.
  Na 1024 × 768 má písmo kalendára ~7–9 px.
- **MediaGoo a CamGoo sú v poriadku, iba drobnosti.** CamGoo ukazuje verejné internetové kamery, nie webkameru počítača.
  Jej predvolené miesto je medzi ClockGoo a TrayShore, kde človek z Windows čaká hodiny.

---

## Dizajn

### Spoločné pre karty na mieru (hodiny, kalendár, kamera)

- **D-01 · stredná · [overené v kóde] · oprava pred 0.6 (veľkosti), funkcia po 0.6 (téma)** — Farby sú natvrdo napísané v hex:
  `#1b120d`, `#f5e8d8`, `#f7c873`, `#21170f` (v `clock.plm`, `calendar.plm`, `cam.plm`). Riadkové karty pritom berú farby z témy
  (`tc/td/tg` v `card.plm:210–216`). Karty na mieru preto nesledujú Baristu: pri latte sú dlaždice stále tmavé ako espresso
  (pravidlo 6 a 11 „farby idú z témy“). `card.plm:208` ich zámerne stmavuje (`card.dk`), takže je to rozhodnutie, ale nezosúladené
  s kávou používateľa.
- **D-02 · stredná · [overené v kóde] · oprava pred 0.6** — Písmo je malé. Kalendár je kreslený v jednotkách × `1,2 × card.z`
  (`calendar.plm:79`), texty majú 6–8,5 jednotky (`calendar.plm:120–142`, `:181–189`).
  - Na 1024 × 768 vychádza `card.z` ≈ 0,9–0,98 (`card.plm:177–178`; `card_min` 700, miesto nad kvapkou ~640 px), čiže
    **6,5 j. ≈ 7–7,7 px, 7,5 j. ≈ 8–9 px**. Karta času je na tom podobne (`clock.plm` 7,5 j. ≈ 8,7–9,4 px).
  - §2 pravidlo 11 sľubuje použiteľnosť od 1024 × 768 a §4.5 „zmestí sa aj na 1024 × 768“. Zmestí sa, ale čítať sa to nedá.
  - Návrh: najmenšie písmo 9 j. (≈ 11 px pri z = 1), alebo spodnú hranicu `card.z` dvíhať podľa písma, nie podľa výšky.
- **D-03 · nízka · [overené v kóde]** — `#8a7666` na `#21170f` (prázdne stavy, `cal_empty`) má kontrast 4,07 : 1, pod AA pre malé
  písmo (4,5). Hlavné texty (`#b8a491` 7,4 : 1, `#f5e8d8` 14,6 : 1) sú v poriadku. Hover dňa v mesiaci je iba 4 % krému
  (`calendar.plm:127`), takmer neviditeľný. Stlačenie nemá v kartách na mieru žiadnu odozvu.
- **D-04 · stredná · [overené v kóde] · oprava pred 0.6** — Klávesnica (§6.1) v kartách na mieru nefunguje. `card.open({}, …)`
  dostane prázdne riadky a žiadne záložky (`clockgoo.luau:455`, `:785`, `camgoo.luau:67`). ↑↓, Enter a Tab tak nemajú čo vyberať.
  Záložky hodín majú vlastné `clk_tab` a nie sú v `card_next`. Win+T → Enter kartu otvorí, ďalej sa v nej z klávesnice nedá nič
  urobiť (okrem poľa vety v kalendári).
- **D-05 · nízka · [overené v kóde]** — Pravý klik (pravidlo 23) v kartách na mieru takmer nie je. Je iba na poli vety
  (`calendar.plm:220`). Udalosť, upozornenie, budík, kamera ani deň v mesiaci ponuku nemajú.

### ClockGoo

- **D-10 · vysoká · [overené v kóde] · oprava pred 0.6** — **Nezodpovedá to centru oznámení Windows 11 ani §4.5.**
  - Ľavý klik otvorí kalendár (`open_calendar`, `clockgoo.luau:781–788`). Pravý stĺpec v ňom predvolene ukazuje deň
    (`cal.side = 0`, `:783`), upozornenia sú až po stlačení tlačidla „N upozornení“ (`calendar.plm:106–111`).
  - Kvapka pritom ukazuje guľky a zvlní hladinu: človek klikne a upozornenie nevidí.
  - §4.5 opisuje ľavý stĺpec upozornení s ikonou, Zahodiť, akciami na pravý klik, Nerušiť, Vymazať všetko, „+N ďalších“
    a Nastaveniami oznámení. V novej karte z toho nie je nič (`calendar.plm:197–211`, model `calnote` má iba
    `title/body/critical`, `:13`).
  - Spec (§4.5 a §8) sa nezhoduje s kódom.
- **D-11 · stredná · [overené v kóde] · oprava pred 0.6** — Ľavý klik sa ukazuje v dvoch rôznych kartách.
  - Lístok v rohu (`toast_press` → `open_notes`, `clockgoo.luau:837`) a pridanie adresy .ics (`:223`) otvoria **starú** kartu
    v riadkoch (upozornenia + mesiac, `:227–232`).
  - Klik na kvapku a Win+N otvoria novú kartu. Ten istý údaj má teda dva vzhľady a dve správania.
- **D-12 · stredná · [overené v kóde]** — Slovenské tvary:
  - Dátum v Prehľade (`clockgoo.luau:361`) vyjde ako „Utorok, 24. November 2026“. Po slovensky je „utorok 24. novembra 2026“
    (genitív, malé písmená). Mesiace majú iba nominatív (`sk.plm:372`).
  - `tr(WEEKDAYS…):lower()` (`clockgoo.luau:720`) zmenšuje iba ASCII. „Dnes, Štvrtok 26. 11.“ tak ostane s veľkým Š, kým
    „Dnes, pondelok“ má malé p.
  - Chýbajú množné čísla: „1 upozornení“ / „3 upozornení“ (`:685`, `sk.plm:383`), „1 udalostí“ (`:751`, `sk.plm:2618`),
    „o 1 minút“ (`:436`, `sk.plm:259`).
  - Preklady s anglickými veľkými písmenami: „Časovače a Budíky“, „Podrobné Počasie“ (`sk.plm:179–180`).
  - Navyše „Odporúčanie LatteOS: odporúčaná pauza…“ (zdvojené), „Zapni to v Zmeniť rozloženie“.
- **D-13 · nízka · [overené v kóde + snímka]** — Pri 24-hodinovom čase sa ukazuje DOP./POP. (`clockgoo.luau:360`, snímka
  „16:51:24 PM“). V slovenčine je to navyše, odstrániť pri 24 h.
- **D-14 · nízka · [overené na snímke]** — Na záložkách karty času prekrýva text ikonu („Overview“ a „Timers and alarms“ ležia
  na ikone, `clock.plm` ~165–170). Päta „Do not disturb…“ a riadok pohody sú orezané už po anglicky, slovenské texty sú dlhšie.
- **D-15 · stredná · [overené v kóde] · oprava pred 0.6 (predvolené miesto)** — Predvolené poradie na spodnom okraji je
  MediaGoo 0,72 – ClockGoo 0,79 – **CamGoo 0,86** – TrayShore (`mediagoo.luau:43`, `clockgoo.luau:792`, `camgoo.luau:82`).
  Vo Windows 11 sú hodiny úplne vpravo pri oznamovacej oblasti. CamGoo je okrajová kvapka a predvolene by mala byť skrytá
  alebo vľavo od MediaGoo, aby ClockGoo sedela hneď pri TrayShore.
- **D-16 · nízka · [overené v kóde]** — Pri zapnutom Nerušiť zmizne z kvapky dátum (`second_line`, `clockgoo.luau:49–52`).
  Windows nechá dátum a pridá ikonu zvončeka. Lepšie: dátum ostane, Nerušiť sa ukáže guľkou alebo ikonou.
- **D-17 · nízka · [overené v kóde]** — Päta „Režim spánku naplánovaný na 23:00“ (`clockgoo.luau:444`) nič neplánuje:
  `bedtime` sa iba ukladá (`bin/latte-focus:148`), nikto ho nečíta. Text sľubuje funkciu, ktorá nie je.

### MediaGoo

- **D-20 · nízka · [overené v kóde]** — Karta je z bežných riadkov: profil, tlačidlá, posuvník, zoznam prehrávačov
  (`mediagoo.luau:16–38`), bez pätky a bez kávy pod vlnou. Ostatné kvapky majú pätu („…v Nastaveniach“). ROZHODNUTIA r. 354:
  „podoba čaká na používateľa“, preto funkcia po 0.6.
- **D-21 · nízka · [overené v kóde]** — V zozname prehrávačov ukazuje ikona play/pause stav, ale vyzerá ako tlačidlo
  (`mediagoo.luau:33–34`). Stlačenie vybraného prehrávača ho „odopne“ (`media.choose ""`), čo nečakať.

### CamGoo

- **D-30 · nízka · [overené v kóde]** — Vzhľad (sklo nad, káva pod, päta do Nastavení) je zosúladený s ClockGoo. Čipy kamier
  sú najviac 6 (`camgoo.luau:37`, `cam.plm:48`). Pri 7. a ďalšej kamere sa šípkami dá prejsť, ale žiadny čip nesvieti.

---

## Funkcie

### ClockGoo — upozornenia

- **F-01 · vysoká · [overené v kóde] · oprava pred 0.6** — V novej karte sa upozornenie nedá zahodiť bez otvorenia aplikácie.
  - Stlačenie spustí `invoke "default"` a potom `dismiss` (`clockgoo.luau:882–885`). Zahodiť, Vymazať všetko ani pravý klik
    s akciami tam nie sú.
  - Zároveň `notifications.keep(true)` (`:836`) vypne samovoľné miznutie, takže upozornenia sa hromadia bez konca.
  - Ukáže sa najviac 6 a „+N ďalších“ chýba (`:755–758`, `calendar.plm:13`).
  - Vyčistiť sa dajú iba cez lístok v rohu → stará karta → Vymazať všetko.
- **F-02 · stredná · [overené v kóde]** — Upozornenie v novej karte nemá ikonu aplikácie (`n.icon`), obrázok (`n.image`, napr.
  fotku odosielateľa) ani čas (`n.time`), hoci ich služba pleamaru dáva (`pleamar --docs logic`, služba `notifications`).
  Nie sú zoskupené podľa aplikácie. Stará karta ikonu mala (`:76`).
- **F-03 · stredná · [overené v kóde] · oprava pred 0.6** — Nerušiť sa v karte ľavého kliku zapnúť nedá. Je iba v päte karty
  času (`clk_dnd`, `:930`) a v Nastaveniach. Windows ho má v centre oznámení.
- **F-04 · nízka · [overené v kóde]** — Lístok v rohu nemá ikonu, akcie ani ✕. Pravý klik ho síce skryje, ale to nikto
  neuhádne (`rows.plm:481–483`). Keď je otvorená karta, lístok sa kreslí, ale stlačiť sa nedá (`active: … and not card_open`).
  Stlačenie lístka nespustí upozornenie, iba otvorí (starú) kartu.
- **F-05 · nízka · [podozrenie, treba naživo]** — Upozornenie bez predvolenej akcie po stlačení iba zmizne (`invoke "default"`
  v `pcall`, potom `dismiss`). Windows by aspoň dal do popredia aplikáciu.
- **F-06 · nízka · [overené v kóde]** — Nerušiť stlmí aj kritické upozornenia: lístok aj zvuk (`fresh and not quiet()`,
  `:823`). Výnimky ako vo Windows (priorita, budíky) nie sú. Budík pritom svoje tóny zahrá aj pri Nerušiť (`ring`, `:591–594`),
  to je správne.
- **Odpovede priamo v upozornení** (inline reply) API pleamaru nemá. Je to funkcia po 0.6 a treba ju najprv u autora pleamaru.

### ClockGoo — kalendár (ľavý klik)

- **F-10 · stredná · [overené v kóde] · oprava pred 0.6** — Zabudnutý starý kód (stará karta) robí dvojitú prácu a delí údaje.
  - `read_linked` (`:37–44`, každých 30 min, `:805–806`) sťahuje tie isté adresy .ics, ktoré `read_events` sťahuje každých
    10 min (`:808–809`). Výsledok `linked` používa iba stará karta.
  - `note_rows`, `month_of`, `day_rows`, `write_down` (`:62–201`) slúžia iba starej karte.
  - V `card.luau:34`, `:401–407` a `rows.plm:145–170` je starý mesiac so 42 zónami (príspevok k ~11 tis. vlastností scény).
  - **Pozor pred zmazaním:** úlohy `kept.tasks` (zápis „! mlieko“) sa ukazujú iba v starej karte. Udalosti zapísané ešte do
    `clock.json` (`kept.events`) nová karta ukáže ako „LatteOS“ (`:619`). Stlačenie ich ale otvorí v aplikácii bez `uid/source`
    (`:875–879`), takže sa nedajú upraviť ani zmazať. Najprv ich presunúť (`latte-cal add`, úlohy do VTODO), až potom mazať.
- **F-11 · stredná · [overené v kóde]** — „Pripomenúť o 5 min“ (`:881`) nepripomenie nič. Udalosť sa iba na 5 min schová
  z „ĎALEJ“ (`cal.snoozed`, iba v pamäti). Pripomienky robí `latte-calwatch` cez VALARM, toto tlačidlo do neho nezapisuje.
  Text klame.
- **F-12 · nízka · [overené v kóde] · oprava pred 0.6** — Koliesko nad mesiacom nič nerobí. §4.5 ho chce, stará karta ho mala
  (`rows.plm:170`), nová nemá `on scroll` (`calendar.plm`).
- **F-13 · nízka · [overené v kóde]** — Mesiac začína vždy pondelkom (`clockgoo.luau:646`). Ignoruje `week_start` z nastavení
  kalendára (`goo/calsettings.luau:28`, aplikácia Kalendár ho berie). Voľné hodiny dňa sú natvrdo 8–20 (`:723`, `:746`),
  `hours/workdays` z nastavení sa neberú.
- **F-14 · nízka · [overené v kóde]** — V starej karte môžu kolidovať udalosti `cal_pick`. Počúvajú ju `card.luau:339` aj
  `clockgoo.luau:865`. Druhá prepíše `month.cells` rozložením novej karty (bez dní susedných mesiacov), takže klik na sivý deň
  v starej karte môže nič neurobiť. Po zmazaní starej karty zanikne.
- **F-15 · nízka · [overené v kóde] · výkon** — `fill_calendar` volá `events_on` pre každú zo 42 buniek. Každé volanie prejde
  celý `cal.events` (mesiac dozadu až rok dopredu, opakovania rozpísané, môžu to byť tisíce) a triedi. `next_event` to robí
  znova. Spúšťa sa pri každom upozornení, kým je karta otvorená (`:834`). Stačí raz zoskupiť podľa dátumu.

### ClockGoo — karta času, minútka, budíky

- **F-20 · vysoká · [overené v kóde] · oprava pred 0.6** — Budíkov sa dá pridať 10 (`timers.luau:106`), ukáže sa 6
  (`clockgoo.luau:486`, `clock.plm:97`). Budíky 7–10 zvonia každý deň, ale nevidno ich a nedajú sa vypnúť. „Odstrániť vypnuté“
  ich nezmaže, lebo sú zapnuté.
- **F-21 · stredná · [overené v kóde] · oprava pred 0.6** — Zvonenie trvá iba tri tóny po 260 ms (~1,2 s, `clockgoo.luau:593`)
  plus kritické upozornenie. Budík, ktorý má zobudiť alebo pripomenúť, sa ľahko prepočuje. Chýba opakovanie, kým ho človek
  nevypne, a Odložiť. Windows Hodiny zvonia, kým ich človek nezastaví.
- **F-22 · stredná · [overené v kóde]** — „Najbližší budík“ v Prehľade (§4.5) chýba. `timers.next_alarm()` (`timers.luau:123`)
  nikto nevolá, je to mŕtvy kód.
- **F-23 · stredná · [overené v kóde] · oprava pred 0.6** — Kým je karta otvorená, svetové hodiny stoja. `learn_world` sa volá
  iba v `open_clock` (`:450`), tikanie každých 200 ms (`:563–570`) volá len `fill_clock`, ktoré ukazuje časy z poslednej
  odpovede. Po minúte sú o minútu pozadu.
- **F-24 · stredná · [overené v kóde] · oprava pred 0.6** — Karta otvorená z dosky AppCloud (`from_plate`, `:840–841`) „preskočí“
  na kvapku. `from_plate` platí iba počas otvárania. Prepnutie záložky (`clk_tab` → `open_time(d, true)`, `:842`) aj
  `timers.guard` → `open_time` (`:936`) zavolajú `card.open` s `owner = d`. ClockGoo sa zdvihne, stane sa uchom
  (`card.luau:303–307`) a `card_plate` sa vynuluje. To isté pri „Späť“ z adries kalendárov do `open_calendar`. So skrytou
  ClockGoo sa to nestane (ROADMAP 6N.01 to overoval práve tak).
- **F-25 · nízka · [overené v kóde]** — Budíky nemajú meno, dni v týždni ani Odložiť. Minúty sa nastavujú iba po 5 (`:553`).
  Jeden budík sa nedá zmazať (iba vypnúť a „Odstrániť vypnuté“). Ten istý čas sa dá pridať dvakrát. Je to funkcia po 0.6,
  okrem mazania jedného budíka (pravý klik, oprava).
- **F-26 · stredná · [overené v kóde] / [podozrenie, treba naživo]** — Budík počas uspania:
  - Kód: `guard` beží každú 1 s iba pri bdelom PC. Po prebudení zazvoní budík zmeškaný najviac o hodinu (`LATE`,
    `timers.luau:88`, oprava z 23. 11.).
  - Po dlhšom spánku zmizne potichu, bez upozornenia „zmeškaný budík“.
  - Počítač kvôli budíku nezobudí (rtcwake nie je), rovnako ako Windows Hodiny. Karta to ale nehovorí („Budíky zvonia iba pri
    zapnutom počítači“).
- **F-27 · nízka · [podozrenie, treba naživo]** — Pri zmene časového pásma za behu (cesta, `timedatectl`) glibc v bežiacom
  procese nemusí znova načítať `/etc/localtime`.
  - `os.date` v Goo by ostal v starom pásme, kým `learn_abbr` (`date +%Z` v novom procese, `:320`) ukáže nové. Karta by sa
    rozišla.
  - Budíky sú podľa miestneho času procesu.
  - Pri dvojitom štarte s Windowsom (RTC v miestnom čase) môže NTP posunúť čas o 1–2 h dopredu a budík v tom okne preskočiť
    alebo zazvoniť neskoro.
  - Zmena letného času: budík 02:30 v jarnú noc zazvoní 03:30 (`os.time` to normalizuje), to je prijateľné.
- **F-28 · nízka · [overené v kóde] · výkon** — Na záložke Časovače volá tikanie 5× za sekundu aj `fill_clock` (Prehľad, ktorý
  nevidno) a zakaždým prestavia `model.clkw` a `model.clka` (`:565–568`). Mimo karty bežia stále dva časovače po 1 s
  (`:938–944`, `timers.luau:133`). Lacné, nič nekreslia, kým sa nič nemení. Je to v poriadku, len to netreba zhoršovať.
- **F-29 · nízka · [overené v kóde]** — Pri každom otvorení karty času a pri každom prepnutí záložky sa spustia štyri procesy
  (`latte-focus`, `latte-nameday`, `date`, `sh`, `:450–453`). `latte-nameday` sa ešte pýta `latte-sky country` (časový limit
  12 s) a siete.

### ClockGoo — počasie a meniny

- **F-30 · stredná · [overené v kóde] · oprava pred 0.6** — Bez siete `latte-sky` vráti poslednú uloženú predpoveď bez ohľadu
  na jej vek (`bin/latte-sky:145–147`).
  - Kvapka aj karta ju ukážu ako „AKTUÁLNE“, aj keď je týždeň stará.
  - `fill_calendar` priraďuje `sky.days[i]` k dňom od dnes (`clockgoo.luau:648–651`), pri starej predpovedi teda k zlým dňom.
  - Treba vek v odpovedi (`at_time`) a nad ~3 h písať „naposledy o …“, nad 24 h nič.
- **F-31 · stredná · [overené v kóde] · oprava pred 0.6** — Bez miesta alebo pri prvom štarte bez siete `now = nil`. Prehľad
  potom ukáže prázdny panel s osamoteným „°C“ (`clock.plm:214`, `:415` sa kreslia vždy) a záložka Počasie ostane prázdna
  (`fill_weather` skončí, `clockgoo.luau:502`). Chýba prázdny stav „Počasie nie je k dispozícii · Nastaviť miesto“.
- **F-32 · stredná · [overené v kóde] · oprava pred 0.6** — `latte-nameday` sa pýta iba siete (`bin/latte-nameday:35–46`) a
  pamätá si iba dni, na ktoré sa už pýtal. Inštalovaný súbor `/usr/share/latteos/namedays.json` (`FILES:132`) používa iba
  `latte-cal` (`:448`). Offline preto meniny nie sú. Navyše ignoruje voľbu viacerých krajín (`namedays` v nastaveniach kalendára).

### Blikanie ClockGoo pri otváraní (bughunt 5. 11.) — rozbor

**Najpravdepodobnejšia príčina (istota stredne vysoká, ~65 %) [overené v kóde, súvis treba naživo]:**

1. Otváranie ide po pružine `land = 630, 14` (`card.plm:130`, `card.out`, `:136–141`). Útlm ζ ≈ 0,28, perióda ~0,26 s.
   Bughunt nameral 0,09 → **1,40 → 0,84** → 1,06 → 1,0, čo sa s výpočtom zhoduje.
2. Šírka rámu je `card.ws × (card.t³ + over × 0,6)`, kde `card.t = clamp(card.p, 0, 1)` (`card.plm:228–230`). Pri podkmite
   p = 0,84 je `t³` = **0,59**, rám teda na chvíľu spadne na **~59 % šírky** (pri kalendári na 1080p z ~1300 px na ~770 px).
   Výška `card.q` klesne na 84 %.
3. Celý obsah karty vrátane kalendára a hodín je orezaný rámom (`clip box`, `rows.plm:63`) a má krytie
   `clamp(card.p × 2 − 1) × card.ink` (`rows.plm:58`). Pri 0,84 je to **0,68**.
4. Výsledok trvá okolo dna podkmitu ~60–80 ms (p < 0,9), teda **~2 snímky pri 30 fps**, presne ako v zázname. Pri ClockGoo
   (karta rastie z pravého dolného rohu doľava hore) zmizne ľavá ~40 % karty aj s tmavými dlaždicami a zvyšok má 68 % krytia.
   Na snímkach to vyzerá, že „celá zpriesvitnie a vráti sa“.
5. Prečo je to vidno najmä pri ClockGoo: má najširšie karty (kalendár 912 × z, hodiny 710 × z) s veľkými tmavými plochami.
   Riadkové karty sú úzke a majú svetlý text na skle. Tá istá pružina na strane prekmitu vysvetlila v bughunte svetlý pás pri
   PowerGoo (5. 11.).

**Ďalšie možnosti (menej pravdepodobné):**
- (b) `fill_calendar` beží synchrónne pred prvým snímkom, takže sotva. Ale asynchrónne `read_events` → `fill_calendar`
  (`clockgoo.luau:787`, ak od posledného čítania prešlo > 60 s) vymení model `calcell` (42 položiek) asi o 0,1–1 s neskôr.
  Ak pleamar položky vytvorí nanovo, text môže snímku chýbať. Dlaždice (boxy) by to však nezasiahlo.
- (c) Staré snímky pre sklo (`lens`) od pleamar-wm, ako pri zatváraní. Týka sa to tela, nie obsahu kreslenom nad ním.

**Overenie:** `pleamar --record card.p card.cw` spolu so záznamom `bughunt/zachyt-otvarania-karty.sh`. Ak bliknutie padne
~0,2–0,3 s po kliku na p ≈ 0,84, platí (a).

### Zatváranie karty (ROADMAP 6.30 / 10J.22) — stav

**[overené v kóde]** Odskok pri zatváraní v kóde už **nie je**.
- Od `911a708` (12. 11.) sa karta zatvára vlastnou kriticky tlmenou pružinou: `spring shut = 900, 60`, ζ = 1,0
  (`card.plm:132–141`), a `card.p = card.in`.
- Meranie −0,40 → +0,16 v `bughunt/najdene-chyby.md` (5. 11.) je zo starej jedinej pružiny.
- Stav pred touto zmenou dodnes opisujú ROADMAP 6.30 a 10J.22 („čaká na výber“) aj GOOENGINE-2 D6 (`docs/goo/GOOENGINE-2.md:49`).
  Riadok 912 v tom istom súbore pritom zmenu zapisuje.
- Ak človek ešte vidí kartu „vyskočiť“ po zavretí, podľa bughuntu (`PLEAMAR_NO_LENS=1` → 0 duchov) sú to staré snímky skla.
  Od 23. 11. sa `lens` vypína iba pri Sklo = 0.
- Návrat kvapky domov oblúkom (6.34) a jej `squash/tremble` po zavretí (`card.luau:117`) sú zámerný pohyb ucha, nie odskok karty.

### MediaGoo

- **F-40 · stredná · [overené v kóde] / [podozrenie, treba naživo]** — Obal z `https` (Spotify, prehliadače) ide do riadku ako
  `icon` (`mediagoo.luau:11–13`, `:18`). `has_icon` je potom pravda (`card.luau:259`), takže sa náhradná ikona `music` neukáže.
  Pleamar http adresu nechá tak, ako ju prehrávač dal (`pleamar --docs logic`, služba `media`). Ak ju `image` nevie načítať,
  bude na mieste obalu prázdno. Spotify je najčastejší prehrávač.
- **F-41 · nízka · [overené v kóde]** — Funkcie, ktoré pleamar dáva a MediaGoo nepoužíva: poloha a dĺžka skladby, posúvanie
  (`media.seek/step`, `can_seek`). Stlačenie obalu nič nerobí (`quiet = true`), „Otvoriť prehrávač“ chýba. Je to funkcia po 0.6.
- **F-42 · nízka · [overené v kóde]** — Prehrávačov sa ukáže najviac 5 (`:31`), ďalšie bez „+N“. Koliesko na kvapke mení
  hlasitosť bez akejkoľvek odozvy na kvapke (TrayShore ukazuje prstenec, MediaGoo nič).
- **F-43 · nízka · [podozrenie, treba naživo]** — Efekt `beat` beží celý čas, kým hrá hudba (`:60`). Kreslí sa teda nepretržite,
  čo ide proti obmedzeniu snímok pri nečinnosti a je drahé na notebooku. Prehliadače hlásia cez MPRIS každú kartu s videom,
  takže kvapka sa môže často ukazovať a skrývať.
- Ošetrené: prehrávač bez obalu má ikonu `music`, prehrávač bez názvu ukáže meno prehrávača, odchod posledného prehrávača
  zatvorí kartu a skryje kvapku. Hlásenie polohy každú sekundu sa odfiltruje (`:53–57`).

### CamGoo

CamGoo zobrazuje **verejné internetové webkamery** (foto-webcam.eu, vlastné adresy v Nastaveniach), nie `/dev/video`. Prípady
„žiadna webkamera / dve webkamery / kamera sa používa“ sa preto netýkajú. Zodpovedajú im prázdny zoznam, viac kamier a kamera,
ktorá neodpovedá.

- **F-50 · nízka · [overené v kóde]** — Prázdny zoznam sa nedá mať. `cams()` pri prázdnom `cams.json` vráti predvolené kamery
  (`camgoo.luau:25–26`) a Nastavenia tiež (`apps/settings.qml:262`). Vetva „Žiadne webkamery“ (`camgoo.luau:38–40`) je mŕtva.
- **F-51 · nízka · [overené v kóde]** — „snímka z HH:MM“ je čas stiahnutia (`:55`), nie čas, keď kamera snímku urobila.
  Kamera, ktorá sa zasekla a vracia starý obrázok, vyzerá aktuálne.
- **F-52 · nízka · [overené v kóde]** — Pravý klik pri zavretej karte otvorí kartu na tej istej kamere (`:90`), hoci bublina
  aj ROZHRANIE hovoria „ďalšia kamera“.
- **F-53 · nízka · [podozrenie, treba naživo]** — Obrázok je pevne 640 × 360 (`cam.plm:19`, `:31`). Kamera so stranami 4 : 3
  alebo na výšku sa pravdepodobne roztiahne.
- **F-54 · nízka · [overené v kóde]** — V `~/.cache/latteos/cams/` ostávajú snímky kamier, ktoré už v zozname nie sú, navždy
  (2 na kameru, `bin/latte-cam`).
- Ošetrené: časový limit 12 s, najviac 8 MB, iba `image/*`, nová kamera sa načíta znova, pri chybe „Kamera neodpovedala“
  a stará snímka ostane. Obnova každých 60 s beží iba pri otvorenej karte.

### Spec a dokumentácia

- **F-60 · nízka · [overené]** — V tabuľke kvapiek `LATTEOS-GOO.md` §4 chýbajú MediaGoo a CamGoo (sú iba v `docs/goo/ROZHRANIE.md`).
  §4.5 opisuje staré dvojstĺpcové upozornenia, §8 neuvádza CamGoo. ROADMAP 6.30 / 10J.22 a GOOENGINE-2 D6 sú zastarané
  (pozri „Zatváranie karty“).
- **F-61 · nízka** — Na logiku budíkov (`due`, `armed`, `LATE`) nie je test, hoci sa opravovala 23. 11. a ide o čas.
  V `tests/` nič pre `timers.luau` nie je.

---

## Návrh dokončenia

### Pred 0.6 — opravy (poradie podľa dopadu)

**P1 — ClockGoo: upozornenia ako vo Windows 11** (`goo/drops/clockgoo.luau`, `goo/parts/calendar.plm`)
1. `open_calendar`: `cal.side = keep and cal.side or (#notes > 0 and 1 or 0)`. S upozorneniami sa karta otvorí rovno na nich.
2. `calendar.plm`, stĺpec upozornení:
   - v hlavičke „Vymazať všetko“ (`notifications.clear`) a prepínač Nerušiť (`E.set("quiet")`);
   - riadok „+N ďalších“ (`#notes > 6`);
   - `on press right note_hit { emit cal_note_menu(n.index) }` → `ctx.open` s akciami (`n.actions`) a Zahodiť;
   - ikona aplikácie a čas (do modelu `calnote` pridať `icon: image`, `when: text`).
3. `toast_press` (`:837`) a odoslanie adresy .ics (`:223`) presmerovať na `open_calendar(d)`. Pri lístku navyše `cal.side = 1`.
4. Starý kód odstrániť **až po presune údajov**:
   - `kept.events` → `latte-cal add` do miestneho kalendára EDS;
   - `kept.tasks` → VTODO (alebo ukázať úlohy v novej karte);
   - potom zmazať `note_rows`, `month_of`, `day_rows`, `write_down`, `read_linked`, `linked`, `open_notes`;
   - v `card.luau` zmazať `calendar` a `cal_pick/cal_step`, v `card.plm` modely `day/weekday`, v `rows.plm` starý mesiac
     (`:145–170`).
5. `calendar.plm`: `on scroll` nad mesiacom → `cal_go(±1)` (§4.5).
6. „Pripomenúť o 5 min“ (`:881`): buď skutočná pripomienka (`after(300000)` → upozornenie), alebo premenovať na „Skryť na 5 min“.

**P1 — Budíky** (`goo/lib/timers.luau`, `goo/drops/clockgoo.luau`, `goo/parts/clock.plm`)
7. Jedno číslo pre limit budíkov: `alarm_add` nech pustí iba 6 (alebo zvýšiť model `clkal` a rozloženie na 9). Pravý klik na
   budík = Zmazať (`clk_act` 40+).
8. `ring`: zvoniť dokola (napr. každé 2 s najviac 1 min), kým človek nestlačí upozornenie alebo Zastaviť. Akcie upozornenia
   Zastaviť · Odložiť 5 min (`notify-send -A`). Po prebudení po viac ako `LATE` poslať tiché upozornenie „Zmeškaný budík 7:00“.
9. Prehľad: „Najbližší budík“ z `timers.next_alarm()` (§4.5, už napísané, iba nenapojené).
10. Text pod budíkmi: „Budíky zvonia, keď je počítač zapnutý“ (ako Windows).

**P2 — Blikanie pri otváraní** (`goo/parts/card.plm`, `goo/parts/rows.plm`) — pozri tri možnosti nižšie; odporúčaná možnosť 1:
11. `card.plm:228`: `let card.t = if(card_open and card.ink > 0.999, 1, clamp(card.p, 0, 1))`. Po prvom dosiahnutí cieľa
    (~65–70 ms) sa rám už nezúži. Prekmit (`card.over`, výška do 1,08) ostane viditeľný, teda „pristátie“ zostane.
12. `rows.plm:58`: `opacity: if(card_open, card.ink, clamp(card.p * 2 - 1, 0, 1) * card.ink)`. Pri otváraní obsah nebliká.
13. Overiť `--record card.p card.cw` a záznamom snímok. Mení to schválené správanie (ROZHODNUTIA r. 383), preto
    s pokynom používateľa.

**P2 — Bez siete a slovenčina**
14. `bin/latte-sky`: do výsledku `age` (sekundy od stiahnutia). `clockgoo.luau`: nad 3 h „naposledy o HH:MM“, nad 24 h počasie
    neukazovať. `clock.plm:214/415`: „°C“ iba pri `clk_weather > 0` a prázdny stav s odkazom na Nastavenia › Čas a počasie.
15. `bin/latte-nameday`: najprv `/usr/share/latteos/namedays.json` (alebo `system/namedays.json` z repa), sieť iba keď tam nič nie je.
16. Slovenské tvary (`clockgoo.luau`, `goo/lang/sk.plm`):
    - dátum s genitívom mesiaca (nová tabuľka `MONTHS_OF` / `N("of November")`);
    - malé písmená deň a mesiac v sk;
    - `lower()` s tabuľkou ako `upper()`;
    - množné čísla (pomocná `plural(n, one, few, many)` v `lib/`, sk: 1 / 2–4 / 5+);
    - DOP./POP. preč pri 24 h;
    - opraviť „Časovače a budíky“, „Podrobné počasie“, „Odporúčanie…“, „Zapni to v Zmeniť rozloženie“.
17. Písmo: najmenej 9 j. v `calendar.plm` a `clock.plm` (alebo spodná hranica `card.z` podľa písma). Overiť na 1024 × 768.

**P3 — Menšie opravy**
18. `clockgoo.luau`: `from_plate` zmeniť na trvalý stav karty (`plate_card`, nastaviť pri otvorení, zrušiť pri zavretí cez
    `card.watch`) a použiť ho v `open_clock` aj `open_calendar` (F-24).
19. Tikanie karty času: `learn_world()` raz za minútu (F-23). Na záložke Časovače nevolať `fill_clock` 5× za sekundu.
20. `read_events`: každých 30 min a pri otvorení, nie každých 10 min. `fill_calendar` nech raz zoskupí `cal.events` podľa dátumu.
21. Mesiac podľa `week_start` (`latte-cal settings`).
22. Päta „Režim spánku naplánovaný na …“: skryť, kým `bedtime` nič nerobí.
23. Predvolené miesta: CamGoo predvolene skrytá (alebo `at = 0.65`), ClockGoo hneď pri TrayShore.
24. MediaGoo: pri `https` obale dať `icon = ""` (ostane `music`), kým pleamar nevie načítať http obrázok. Podľa výsledku naživo.
25. CamGoo: pravý klik pri zavretej karte = ďalšia kamera a otvoriť; čip vybranej kamery aj nad 6 (posúvať okno čipov);
    pri 7. kamere ukázať, že ďalšie sú v Nastaveniach.
26. Dokumentácia:
    - ROADMAP 6.30 / 10J.22: zatváranie hotové (`911a708`), otvorené ostáva otváranie a sklo;
    - GOOENGINE-2 D6 prepísať;
    - LATTEOS-GOO §4: riadky MediaGoo a CamGoo, §4.5 podľa novej karty (alebo naopak doplniť kartu podľa §4.5).
27. Test budíkov: `due/armed` vytiahnuť ako čisté funkcie a pridať skúšku v Luau (alebo prepis v Pythone v `tests/`) pre
    polnoc, zmenu letného času a zmeškanie o 59/61 min.

### Po 0.6 — funkcie

- ClockGoo:
  - 6D.13 / 6N.04: kvapka mení podobu pri minútke (jadro, pulz ku koncu, príboj hladiny pri konci);
  - udalosť o 5 min namiesto času;
  - budíky s menom a dňami v týždni;
  - svetové hodiny ako widget (6D.09) a Prehľad z widgetov (6D.10);
  - zoskupenie upozornení podľa aplikácie a Nastavenia oznámení pre každú aplikáciu;
  - výnimky z Nerušiť (budíky, priorita);
  - presun upozornení do TrayShore (6D.05) treba ešte rozhodnúť.
- Kalendár: 10J.06–10J.24 (Google Kalendár, vrstvy ako kalendar.aktuality.sk) podľa ROADMAP.
- MediaGoo: priebeh a posúvanie skladby, väčší obal, „Otvoriť prehrávač“, pätka, odozva hlasitosti na kvapke, podoba
  (ROZHODNUTIA r. 354).
- CamGoo (6F.01–02): živý obraz (ffmpeg), domáce IP kamery (Tapo/RTSP, heslo v kľúčenke), ONVIF, kamery podľa miesta,
  zobrazenia (dlaždice, páska), koliesko nad obrázkom = ďalšia kamera.

### Odskok karty — tri možnosti a odporúčanie

Zatváranie je vyriešené možnosťou 2 (kritický útlm, od 12. 11.). Stačí to zapísať do ROADMAP a overiť `--record`, že `card.p`
pri zatváraní nejde pod 0. Rovnaké tri možnosti teraz patria **otváraniu**, kde podkmit spôsobuje blikanie:

| Možnosť | Čo urobí | Za | Proti |
|---|---|---|---|
| **1. Skryť podkmit** (prekmit ostane) | po prvom dosiahnutí cieľa rám a obsah neklesnú pod plnú veľkosť a krytie; karta sa iba nafúkne von a vráti (`card.t`, `rows.plm:58`) | jedna–dve riadky; „pristátie“ s prekmitom zostane; blikanie aj zúženie zmiznú pri všetkých kartách | z dvoch odskokov ostane viditeľný jeden (von); treba súhlas, mení r. 383 |
| **2. Kritický útlm aj pri otváraní** | `land` → útlm ~1 (ako `shut`) | najjednoduchšie, žiadny artefakt | karta stratí schválený „živý“ dopad (ROZHODNUTIA r. 383, používateľ chcel dva odskoky) |
| **3. Odraz presunúť na kvapku** | karta sa otvorí kriticky tlmene, „pristátie“ urobí ucho (squash/tremble, vlnka hladiny) | karta je pokojná a čitateľná, živosť nesie goo (pravidlá 17–18) | iný pocit z otvárania, viac práce; rozhodnutie používateľa |

**Odporúčanie: možnosť 1 pred 0.6** (je to oprava chyby, živosť ostane). Možnosť 3 ponúknuť používateľovi ako smer pre
GooEngine 2 (§9) po 0.6.

---

## Na overenie naživo

1. **Blikanie:** `pleamar --record card.p card.cw` + `bughunt/zachyt-otvarania-karty.sh` pri ľavom aj pravom kliku na ClockGoo.
   Padne bliknutie na p ≈ 0,84 (~0,2–0,3 s po kliku)? Potom to isté s úpravou z P2 (bod 11–12).
2. **Zatváranie:** `card.p` pri zatváraní neklesne pod 0. Ak ešte bliká, skúsiť Sklo = 0 (od 23. 11. vypína `lens`) a
   `PLEAMAR_NO_LENS=1`.
3. **Karta z dosky AppCloud** pri viditeľnej ClockGoo: prepnúť záložku. Preskočí karta ku kvapke (F-24)?
4. **Budíky:** pridať 7 budíkov a skontrolovať, či 7. zazvoní, hoci ho nevidno. Ako dlho a ako hlasno zvoní budík pri hlasitosti 30 %?
   Budík počas uspania < 1 h a > 1 h.
5. **Zmena časového pásma za behu** (`timedatectl set-timezone`): hodiny na kvapke, karta času, budík (F-27).
6. **Bez siete** (vypnúť Wi-Fi, nový profil bez `~/.cache/latteos/weather.json`): Prehľad, záložka Počasie, meniny, kalendár.
7. **1024 × 768:** čitateľnosť kalendára a karty času, karta celá na obrazovke, ucho v rohu.
8. **50 upozornení** (`for i in $(seq 50); do notify-send "t$i"; done`): guľky, karta, výkon, ako ich vyčistiť bez otvárania aplikácií.
9. **MediaGoo so Spotify a s Firefoxom** (obal z https), dva prehrávače naraz, YouTube v karte prehliadača (ukazovanie a skrývanie
   kvapky), GPU pri `beat` počas hudby (`pleamar --report`).
10. **CamGoo** s vlastnou kamerou 4 : 3 (roztiahnutie), so 7 kamerami (čipy), s nedostupnou adresou.
11. Text na kvapke ClockGoo (dátum a teplota pod časom) pri 100 % veľkosti kvapky: na snímke vyzerá okolo 7 px.
