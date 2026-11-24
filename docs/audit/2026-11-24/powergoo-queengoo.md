# Audit: PowerGoo, QueenGoo a Ctrl+Alt+Del (24. 11. 2026)

Rozsah: `goo/drops/powergoo.luau`, `goo/parts/strip.plm`, `crates/latte-stats`, `goo/lib/wm.luau` (akcie relácie),
`goo/secure.plm` + `goo/secure.luau` + `bin/latte-secure`, `goo/drops/queengoo.luau`, `bin/latte-apps`, `bin/latte-devices`,
`bin/latte-monitor`, `apps/monitor.qml`, `apps/appmanager.qml`, `apps/devices.qml`. Iba čítanie kódu, `pleamar --check`
(obe scény ok), `latte-stats once`, `latte-devices list`, `/proc/PID/cgroup` a `pkaction`. Na živú plochu som nesiahol.
Merítko: LATTEOS-GOO §2, §3.1, §4.2, §4.4, §6.2·1, §8; PRAVIDLA; ROADMAP 6.37, 6C, 6E, 10D, 10E, 10H; „do 0.6 iba opravy“.

## Zhrnutie

- **Potvrdenie Vypnúť sa nedá prečítať.** Keď je „Vypnúť“ v karte PowerGoo nabité, tlačidlo je celé červené a text na
  ňom tiež červený. Je to jediná poistka pred najničivejšou akciou (vysoká, oprava je na jeden riadok).
- **Odhlásiť, Uspať, Reštartovať a Vypnúť nedávajú žiadnu spätnú väzbu.** Karta sa zavrie a príkaz beží bez callbacku.
  Pod pleamar-wm ho navyše spúšťa sám engine Goo, ktorý je mimo relácie logind (`latte-goo.service`, overené cez cgroup).
  Komentár v `wm.luau` tvrdí opak. Či to prejde bez hesla, rozhodne iba záložná cesta polkitu. Test 036 je stále otvorený.
- **Ctrl+Alt+Del v SAFE nejestvuje,** hoci to sľubujú ROADMAP 6.37 aj hlavička `secure.plm`. labwc túto skratku nemá
  a „Odhlásiť sa“ pod labwc nič nespraví. Z klávesnice sa navyše nedá dostať k Napájaniu, Sieti ani Prístupnosti.
- **Pás výkonu:**
  - GPU na NVIDIA funguje (overené: `latte-stats once` dáva gpu, vram, teplotu).
  - Každú sekundu sa však spúšťa `nvidia-smi` bez časového limitu. Po jednej chybe sa GPU vypne až do ďalšieho zapnutia
    pásu.
  - Pás sa pýta ďalej aj pri zamknutí, v hre a pri skrytom PowerGoo.
  - Ľavý klik na bunku nerobí nič, hoci špecifikácia chce Monitor.
- **QueenGoo:**
  - Guľky sa obnovujú iba raz za 3 h.
  - Skrytá QueenGoo sa pýta ďalej, vrátane `dnf check-update`.
  - Logika chýbajúceho firmvéru (`latte-devices`) pravdepodobne zafarbí dočervena aj funkčné Wi-Fi Intel na notebooku.
    Na hlavnom PC je `faults` = 0.
- **App Manager a Monitor:** Odstrániť, Odinštalovať v Baristovi (zmaže aj uložené hry) a Ukončiť proces fungujú na
  jedno stlačenie, bez potvrdenia.
- **Okrajové prípady sú ošetrené správne:**
  - stolné PC bez batérie (myš Logitech `hidpp_battery_0` sa nepočíta, lebo pleamar vynecháva `scope=Device`);
  - chýbajúci `powerprofilesctl` (riadok sa skryje);
  - počítač bez GPU (iba 2 bunky);
  - dva monitory pri počítaní okien.

---

## Dizajn

Značky: **[kód]** = overené v kóde · **[naživo]** = podozrenie, treba overiť na obrazovke.

### D1 · Nabité „Vypnúť“ je červené na červenom — **vysoká** [kód]
`goo/parts/rows.plm:437, 439–442` a `goo/drops/powergoo.luau:168–169`.
- Tlačidlá relácie majú `per = 2`, takže sa kreslia ako „wide“ tlačidlá.
- Pri `on` dostane podklad `color: red` s krytím `100%`, ikona aj nápis majú `if(it.danger, red, …)`.
- Nápis „Naozaj? (okná: N)“ preto zmizne práve vo chvíli, keď sa používateľ potvrdzuje.

Pri Reštartovať a Odhlásiť (bez `danger`) je zlatý text na `tb2` čitateľný.

### D2 · Potvrdenie stratí názov akcie a pravdepodobne sa nezmestí — **stredná** [kód] + [naživo]
`powergoo.luau:129–132`: v nabitom stave sa nápis zmení na „Naozaj? (okná: 3)“ a slovo „Vypnúť“ zmizne.

V „wide“ tlačidle je pre nápis šírka `w − 72` (`rows.plm:442`). Pri karte 330 px vychádza okolo 80 px, takže
„Naozaj? (okná: 3)“, „Reštartovať“ aj „Núdzový režim“ (14,5 px, polotučné) sa pravdepodobne skrátia.

Windows 11 hovorí čo a prečo („Vypnúť · 3 aplikácie sa zavrú“).

### D3 · Ponuka napájania pre človeka z Windows 11 — **stredná** [kód]
- `powergoo.luau:167–175` dáva akcie do mriežky 2 × 3:
  | ľavý stĺpec | pravý stĺpec |
  |---|---|
  | Vypnúť | Zamknúť |
  | Reštartovať | Odhlásiť |
  | Uspať | Núdzový režim |
- Vo Windows 11 má tlačidlo napájania Uspať · Vypnúť · Reštartovať a pod avatarom sú Zamknúť a Odhlásiť sa. Rozdelenie
  na stĺpce teda sedí. Vypnúť je však hore, kam myš príde ako prvá, a je to jediná nevratná akcia, ktorá sa bez otvorených
  okien vôbec nepýta.
- **„Núdzový režim“** (`:174`) vyzerá ako akcia relácie rovnakej váhy, ale iba otvorí Nastavenia › Štart a režim SAFE.
  Človek z Windows čaká okamžitý reštart do núdzového režimu. Návrh: „Režim SAFE…“ (tri bodky = otvorí okno), alebo ho
  presunúť k dlaždici Nastavenia.
- Špecifikácia §4.2 hovorí „Uspať · Reštartovať · Vypnúť (červené)“, v kóde je `danger` iba Vypnúť. `card.luau:9`
  definuje `danger` ako „nedá sa vrátiť“, a to platí aj o Reštartovať. Rozhodnúť a zosúladiť špecifikáciu s kódom.

### D4 · Dve rôzne pravidlá potvrdzovania — **stredná** [kód]
- PowerGoo sa pýta iba pri otvorených oknách a nie pri Uspať (`powergoo.luau:117–118`).
- Ctrl+Alt+Del sa pri Odhlásiť, Reštartovať a Vypnúť pýta vždy (`secure.luau:35–38`, `:41–49`).

Rovnaká akcia sa teda správa inak podľa toho, odkiaľ prišla. Treba jedno pravidlo.

### D5 · Pás výkonu: názov bunky sa prekrýva s hodnotou — **stredná** [naživo]
`strip.plm:34–36`, `powergoo.luau:29` (R = 22):
- názov je v −0,4R = −8,8 px s veľkosťou 9,5 px;
- hodnota je v +0,07R s veľkosťou 14 px a tučná;
- pri týchto číslach sa prekrývajú zhruba o 1–3 px.

Snímka `docs/screenshots/powergoo-strip.png` (z 30. 10., pred NVIDIA) to ukazuje: „CPU“ a „RAM“ zalieza za číslice.
Názov má navyše iba 9,5 px pri krytí 62 %, čo je pod hranicou čitateľnosti (prístupnosť).

### D6 · Pás na bočnom okraji je príliš úzky — **stredná** [naživo]
`strip.plm:31`: na bočnom okraji je bunka široká `R·2 − 8 = 36 px`.

Hodnota „12,3 G“ pri 14 px tučnom má okolo 45 px. ROADMAP 6C.05 priznáva, že bočný okraj nebol overený.

### D7 · Farby stavu napevno — **nízka** [kód]
`strip.plm:35, 37`: `#f5a524` a `#e5484d` sú napevno, kým karty používajú token témy `red`. Na šálke porcelán
(svetlá) nie je kontrast overený.

### D8 · Guľky batérie používajú význam farieb z pravidla 15 — **nízka** [kód]
`powergoo.luau:208`:
- 3 zelené guľky majú odtieň „network“, 1 červená „hardware“;
- pravidlo 15 hovorí zelená = sieť, červená = HW;
- červená guľka tak na PowerGoo znamená „slabá batéria“ a na QueenGoo „zariadenie“;
- 3 zelené guľky svietia stále, čo je proti pravidlu 24 („normál potichu“).

Rozpor je už v špecifikácii §4.2, nie iba v kóde. Batériu navyše ukazuje aj TrayShore (`shore.luau:49–52`,
s ikonou podľa úrovne), kým karta PowerGoo má vždy ikonu `battery-3` (`powergoo.luau:156`).

### D9 · Profil účtu v karte — **nízka** [kód]
`powergoo.luau:149, 190`:
- nadpis je prihlasovacie meno (`USER`) a druhý riadok ho opakuje („arkay@host“);
- špecifikácia chce skutočné meno a portrét (`~/.face`);
- riadok má `quiet = true`, takže sa nedá stlačiť, hoci §4.2 hovorí „klik = Nastavenia › Môj účet“.

Stránka `me` v `apps/settings/pages.json` je hotová (`ready`). Riadok karty `profile` vie `icon` ako cestu
(`card.luau:22`), takže portrét je lacný.

### D10 · Ctrl+Alt+Del: odozva a klávesnica — **stredná** [kód]
- **Odozva:** Tlačidlá vpravo dole a položky ponuky napájania nemajú odozvu na prechod myšou ani na stlačenie
  (`secure.plm:115–143`: pevné krytie, žiadne `on enter`). Riadky karty ju majú (cez `sel`).
- **Klávesnica:** Šípky chodia iba po `sel` 0–5 (`:60–61`). Sieť, Prístupnosť ani ponuka Napájanie sa z klávesnice nedajú
  vybrať, pritom hlavička (`:4`) sľubuje šípky, Enter a Esc. Je to záchranná cesta (§6.1: „keď králik prehryzie kábel
  myši“).
- **Esc:** Pri otvorenej ponuke napájania zavrie celú obrazovku (`:59`), nie iba ponuku.
- **Ikona:** Prístupnosť má ikonu `settings` (`secure.luau:55`), správna je `accessible`.
- **Zastarané komentáre:**
  - `secure.plm:3`: „on the left a card“, ale karta je v strede (`:75`).
  - `secure.plm:52–53`: „12 restart, 13 shut down“, ale kód používa 14, 15 a 16.

### D11 · Znenie — **nízka** [kód]
- **Dve znenia jednej akcie:** PowerGoo „Log out“ → „Odhlásiť“, Ctrl+Alt+Del „Sign out“ → „Odhlásiť sa“. Windows 11 SK
  používa „Odhlásiť sa“.
- **Väzba „pre + podstatné meno“:** „Stlačte znova pre odhlásenie / reštart / vypnutie“ je kalk. Lepšie: „Stlačte znova:
  odhlásiť sa“ alebo „Ešte raz = odhlásiť sa“.
- **QueenGoo:** v bubline chýba „sieť je odpojená“ (`queengoo.luau:31–33`), hoci zelenú guľku ukazuje.

### D12 · Nebezpečné akcie v oknách z PowerGoo a QueenGoo bez potvrdenia — **stredná** [kód]
- **Barista › Odinštalovať:** `appmanager.qml:619`, jedno stlačenie. Zmaže celý priečinok vrátane uložených hier
  (`latte-barista:24`).
- **App Manager › Odstrániť:** `appmanager.qml:384, 440`, jedno stlačenie. Údaje v `~/.var/app` ostanú, preto menej
  vážne.
- **Monitor › Ukončiť:** `monitor.qml:81, 139–140`, jedno stlačenie. Posiela TERM ktorémukoľvek procesu vrátane súčastí
  LatteOS. Ak je v zozname `pleamar-wm` alebo `latte-goo`, je to odhlásenie bez opýtania [naživo].

Monitor má pri službách správny vzor: „Zastaviť …? Čo ju používa, prestane fungovať“ (`monitor.qml:283–288`). Rovnaký
patrí k Ukončiť a Odinštalovať.

### D13 · Známe chyby vzhľadu, ktoré ostávajú
- 10E.12: kontrast v Správcovi zariadení.
- 10E.13: angličtina z `latte-boot compat`.
- 10H.13: anglická hláška polkitu pri obnove metadát.

Všetky tri sú opravy pred 0.6 a sú zapísané v ROADMAP. Neopakujem ich.

---

## Funkcie

### PowerGoo: karta a akcie relácie

**F1 · Akcie relácie nič nehlásia a pod pleamar-wm idú mimo relácie logind — vysoká/stredná**
- **[kód]** `wm.luau:99–106`: `run("sh", {"-c", "exec systemctl " .. what})` bez callbacku, Odhlásiť
  `pkill -TERM -x pleamar-wm` tiež bez callbacku. `powergoo.luau:124–126` najprv zavrie kartu a po 200 ms spustí
  príkaz. Keď polkit odmietne, inhibítor zablokuje alebo logind nebeží, nestane sa nič a nič sa ani neukáže.
- **[kód] + živé čítanie:** komentár `wm.luau:104` hovorí „started by the compositor, so logind sees the login session“.
  To platilo pre vetvu Hyprlandu (`hl.exec_cmd`). Pri `ON_PLEAMARWM` príkaz spúšťa engine sám, a ten je v
  `user@1000.service/app.slice/latte-goo.service`, nie v `session-2.scope` (prečítané z `/proc/PID/cgroup`).
  - `pkaction`: `login1.power-off` a `login1.reboot` majú „any“ = `auth_admin_keep`, „active“ = `yes`.
  - `PowerProfiles.switch-profile` má „any“ = `no`.
  - Bez hesla to teda prejde iba vtedy, keď polkit priradí proces k „display“ relácii používateľa (záložná cesta polkitu;
    `loginctl` hlási Display = 2).
- **[naživo]** Overiť Vypnúť, Reštartovať a Úsporu v PowerGoo (ROADMAP 3.x, test 036, je stále otvorený).
- Ctrl+Alt+Del spúšťa kompozitor (`keys.conf:26`), takže je v relácii. Tá istá akcia sa teda môže správať inak.

**F2 · Odhlásenie zabije všetky pleamar-wm používateľa a aplikácie nemajú kedy uložiť — stredná** [kód]
`wm.luau:101`, `secure.luau:36`: `pkill -TERM -x pleamar-wm` bez obmedzenia na reláciu. Zabije aj
`pleamar-wm headless` z `tests/screen.sh` alebo vnorený pleamar-wm. Aplikácie dostanú iba odpojenie od Waylandu.
`systemctl poweroff` pošle SIGTERM bez dialógu „Uložiť?“. Windows sa pýta aplikácií a ukáže „tieto aplikácie
bránia vypnutiu“.

**F3 · `since` je čas štartu scény, nie prihlásenia — nízka** [kód]
`powergoo.luau:19`: `os.date("%H:%M")` sa prečíta pri načítaní modulu. Po páde Goo (GuardCorgi ho spustí znova) alebo po
`reset_places` sa čas vynuluje. Pri prihlásení z predošlého dňa chýba dátum.

**F4 · Úsporný profil nevypína živé správanie — stredná** [kód]
§3.1: „Kedy nie: batéria pod 20 % alebo úsporný profil“. `engine.luau:795–798` sleduje iba batériu (`fact.low_power`).
`power-saver` nie je nikde v `goo/lib`. PowerGoo profil pozná, ale iba po kliku (`powergoo.luau:134–140`) a enginu ho
nepovie.

**F5 · Profil napájania — nízka** [kód]
`powergoo.luau:141–145`:
- `set` nekontroluje výsledok;
- vždy sú tri tlačidlá, hoci `powerprofilesctl list` nemusí mať `performance` (bez ovládača platformy);
- zlyhanie nič nepovie, iba sa po načítaní nezmení „on“.

Bez `power-profiles-daemon` je všetko v poriadku: `run` vráti kód −1, riadok sa skryje (overené v zdroji pleamaru,
`logic_luau.rs:1081`).

**F6 · Mŕtvy kód Hyprlandu — nízka** [kód]
Vetvy `else` vo `wm.luau:101–106` (`hl.dispatch`, `hl.exec_cmd`). Hyprland je odinštalovaný (1D).

### Pás výkonu a latte-stats

**F7 · `nvidia-smi` každú sekundu, bez časového limitu, s trvalou poistkou — stredná** [kód]
- `crates/latte-stats/src/main.rs:73–77`: `.output()` blokuje. Keď sa `nvidia-smi` zasekne (chyba Xid, karta po
  prebudení), zastaví sa celý prúd. latte-stats neskončí, takže ho PowerGoo (`powergoo.luau:81–83`) ani nespustí znova a
  pás zamrzne.
- `:69–83` `WITHOUT`: jedno zlyhanie (napríklad počas prebúdzania) vypne GPU na celý život procesu, teda kým sa pás
  nevypne a nezapne.
- Hlavička `:8–9` stále tvrdí „iba amdgpu“.
- Namerané tu (RTX 3060): `nvidia-smi` 27 ms, `latte-stats once` 280 ms (z toho 250 ms je zámerné čakanie).

**F8 · Pás sa pýta, aj keď ho nikto nevidí — stredná** [kód]
- `powergoo.luau:78` spúšťa `latte-stats 1` a beží ďalej pri zamknutej obrazovke, pri nečinnosti, v hre na celú
  obrazovku aj pri skrytom PowerGoo (F11).
- Monitor má vlastný `latte-stats 1` (`monitor.qml:29`). Pri otvorenom Monitore aj páse bežia dva procesy a dva
  `nvidia-smi` za sekundu.

**F9 · Výber GPU a prahy teploty — stredná** [naživo]
`main.rs:88–99` vezme prvú kartu, ktorá má `gpu_busy_percent`:
- **AMD APU + NVIDIA:** ukáže APU, nie výkonnú kartu.
- **Intel + NVIDIA (Optimus):** i915 a xe `gpu_busy_percent` nemajú, takže sa každú sekundu volá `nvidia-smi`. Na
  notebooku s RTD3 to pravdepodobne budí dGPU a míňa batériu.
- **APU s 512 MB vyhradenej pamäte:** VRAM je stále nad 80 %, takže bunka bude stále jantárová alebo červená.
- **Pevné prahy CPU 80/90 °C** (`powergoo.luau:46`): Ryzen 7000/9000 aj mobilné Intely bežia pri záťaži 90–95 °C podľa
  návrhu výrobcu, takže v hre bude bunka „kritická“.
- **Teplota Ryzenu:** `k10temp` `temp1` je Tctl, na niektorých Ryzenoch s posunom.

**F10 · Ľavý klik na bunku nič nerobí — stredná** [kód]
`strip.plm:39–42` má iba `on press right` (vtiahnuť pás) a hover.
- §4.2: „klik = Monitor na tej časti“.
- Výhovorka v §8 („Monitor ešte nie je“) je zastaraná: `apps/monitor.qml` existuje.
- Stlačenie sa nezachveje, čo porušuje pravidlo 8.
- V bubline chýba takt, najnáročnejší proces a swap. §8 to priznáva, je to funkcia po 0.6.

**F11 · Skrytý PowerGoo a skrytá QueenGoo pracujú ďalej — stredná** [kód] + [naživo]
`engine.luau:549` volá `start` bez ohľadu na `hidden` a skrytie drop nijako neohlási.
- **PowerGoo:** obnoví pás z `power.json` (`powergoo.luau:193–194`) a pýta sa každú sekundu. `strip.plm:28` kreslí
  bunky iba podľa `strip_on`, nie podľa toho, či vlastník je. **[naživo]** Pravdepodobne ostanú „duchovia“ buniek bez
  kapsuly.
- **QueenGoo:** každé 3 h spúšťa `latte-apps updates` (aj `dnf check-update`, `latte-apps:113`) a `latte-devices`.

**F12 · Pás sa naťahuje dvakrát — nízka** [kód]
`powergoo.luau:89` začína s `cells_of({cpu = 0})`, teda s 2 bunkami. S prvým riadkom s GPU sú 4 a kapsula sa
pretvaruje (`:72–75`).

### Ctrl+Alt+Del (`goo/secure.*`, `bin/latte-secure`)

**F13 · V SAFE nefunguje — vysoká** [kód]
- `system/labwc/rc.xml:8–14` nemá `C-A-Delete`.
- `secure.luau:36` odhlasuje cez `pkill -x pleamar-wm`, čo pod labwc nespraví nič.
- `secure.plm:1–2` a ROADMAP 6.37 („musí fungovať aj v SAFE“) tvrdia opak. labwc vie skončiť cez `labwc --exit`.

**F14 · Dva monitory — stredná** [naživo]
`secure.plm:9–18`: jedna plocha `size: full, full` bez `screens:` stmaví asi iba jeden monitor. Na druhom sa dá ďalej
klikať do okien. Hlavné PC má dva monitory.

**F15 · Sieť vedie na nehotovú stránku — nízka** [kód]
`secure.luau:30` otvára `settings network`, ktorá je v `pages.json` „planned“ s `elsewhere: "devices connection"`.
Má rovno otvoriť `latte-app devices connection`. Prístupnosť je tiež „planned“ (známe zo 6.37).

### QueenGoo, App Manager, Správca zariadení

**F16 · Guľky zastarávajú — stredná** [kód]
`queengoo.luau:37–38`: prvý pohľad po 40 s, potom každé 3 h. Po ľavom kliku príde nový pohľad po 60 s (`:46`), po
pravom kliku do Správcu zariadení nie (`:48`). Pripojenie zariadenia bez ovládača sa ukáže až o 3 h. Opravené zariadenie
ostane červené až 3 h.

**F17 · Falošná červená guľka — stredná** [naživo]
- **Firmvér:** `latte-devices:212–215` (`no_firmware`) považuje za chýbajúci firmvér každé „Direct firmware load … failed“.
  `iwlwifi` bežne skúša novšie verzie ucode, zapíše ich zlyhanie a nakoniec načíta staršiu, takže funkčné Wi-Fi dostane
  stav `firmware`. Na mnohých notebookoch Intel tak bude QueenGoo stále červená. Podobne `i915` a voliteľné bloby.
- **USB triedy `ff`:** zariadenie bez ovládača v jadre (`:116–118`) je `no-driver`. Čítačky odtlačkov cez libfprint a
  niektoré RGB alebo AIO ovládače žijú v používateľskom priestore.
- **Overené:** na hlavnom PC je `faults` = 0 (`latte-devices list`). RGB ovládače tam bežia cez `usbhid`. Treba overiť na
  notebooku.

**F18 · Aktualizácie — nízka** [kód] + [naživo]
- `latte-apps:113`: `dnf -q check-update` ako používateľ.
- **[naživo]** dnf5 pravdepodobne sťahuje metadáta všetkých repozitárov do používateľovej cache (stovky MB pri každom
  vypršaní, cache drží 1 h).
- `ponytail:` v `latte-apps:127–128`: systémové Flatpaky sa nekontrolujú, takže modrá guľka o nich nevie (vedomé
  obmedzenie, ostáva).
- 10H.14 (aktualizácie LatteOS namiesto Fedory) je známe.

**F19 · Drobnosti v Monitore — nízka** [kód]
- Docstring `bin/latte-monitor:3–7` a `:23–25` opisuje `watch` dvakrát, rôzne.
- Stránka Hardvér v UI nie je, hoci `latte-monitor hardware` je (10D.13, známe).

### Okrajové prípady (súhrn)

| prípad | stav |
|---|---|
| stolné PC bez batérie | v poriadku: žiadne guľky. pleamar vynecháva `scope=Device` (overené: tu je `hidpp_battery_0`). |
| notebook | guľky a jadro sú v poriadku. Úsporný profil sa neprenáša (F4). Pri Optimus podozrenie na budenie dGPU (F9). |
| bez power-profiles-daemon | v poriadku: riadok sa skryje (`profiles = code == 0`). |
| NVIDIA | funguje cez `nvidia-smi` (overené). Riziká sú zaseknutie a trvalá poistka (F7). |
| AMD | sysfs áno. APU + dGPU vyberie zlú kartu, pamäť APU svieti (F9). |
| bez GPU / Intel | bunky GPU a VRAM chýbajú, pás má 2 bunky. V poriadku. |
| dva monitory | počet okien sa berie zo všetkých (`bar.luau:44, 89`). Ctrl+Alt+Del je asi na jednom (F14). |
| logind nedostupný, polkit odmietne | ticho, bez správy (F1). |
| SAFE | PowerGoo nie je (v poriadku). Ctrl+Alt+Del nie je viazané a odhlásenie nefunguje (F13). |
| skrytá kvapka | pýta sa ďalej, možný duch pása (F11). |

---

## Návrh dokončenia

### Pred 0.6 — opravy (v tomto poradí)

1. **D1 Vypnúť: červené na červenom.** `goo/parts/rows.plm:440, 442`. Pri `it.on and it.danger` dať nápisu a ikone
   svetlú farbu (`#fff8f0` / `tpaper`) alebo podklad držať na 26 % ako pri bežnom `on`. Overiť snímkou cez
   `tests/screen.sh`.
2. **F1 Spätná väzba a cesta akcií relácie.**
   - **Callback:** `goo/lib/wm.luau` `M.machine` a `M.logout` dostanú callback. Pri kóde ≠ 0 PowerGoo
     (`powergoo.luau:115–127`) otvorí kartu znova s riadkom „Nepodarilo sa: …“ (prvý riadok stderr, `errors = true`).
   - **Spúšťanie cez kompozitor:** príkaz spúšťať ako Ctrl+Alt+Del, teda cez pleamar-wm. Napríklad cez náhradu `hyprctl`
     s `launch`, alebo najprv zistiť, či služba pleamaru `session.*` (povolená v `goo.plm:40`) nevie odhlásiť a vypnúť
     sama (pravidlo 3).
   - **Komentár** `wm.luau:104` opraviť.
   - **Naživo:** test 036 a prepnutie profilu.
3. **F13 SAFE.**
   - `system/labwc/rc.xml`: `<keybind key="C-A-Delete"><action name="Execute" command="latte-secure"/></keybind>`.
   - `goo/secure.luau:36`: pri `LATTE_MODE=safe` `labwc --exit`, inak terajší príkaz.
   - Skúška v SAFE (ROADMAP 6.37 to aj tak čaká).
4. **D10 Ctrl+Alt+Del z klávesnice a odozva.** `goo/secure.plm`:
   - `sel` 6–8 = Sieť · Prístupnosť · Napájanie;
   - v otvorenej ponuke napájania šípky chodia po `pw0–2`;
   - Esc najprv zavrie ponuku;
   - tlačidlá dostanú odozvu na prechod myšou (krytie podľa `hover`);
   - ikona `accessible`;
   - opraviť komentáre `:3` a `:52–53`.
5. **F15** `goo/secure.luau:30`: Sieť → `app("devices", "connection")`.
6. **F10 Klik na bunku pása.**
   - `goo/parts/strip.plm`: `on press cell_hit.$u { emit strip_open(u) }`.
   - `powergoo.luau`: `on("strip_open", …)` → `open.monitor()` (stránka `overview`).
   - Koliesko nad bunkou: zachvenie.
   - Opraviť vetu v LATTEOS-GOO §8.
7. **F11 Skryté kvapky.**
   - `goo/lib/engine.luau` `E.apply_hidden()` zavolá `def.hidden(d, h)`, keď sa stav zmení.
   - PowerGoo pri skrytí vypne pás potichu, bez zápisu do `power.json`. Pri ukázaní ho obnoví.
   - QueenGoo pri skrytí preskočí `look`.
   - `strip.plm:28`: násobiť aj tým, či vlastník je.
8. **F7, F8 latte-stats.**
   - `crates/latte-stats/src/main.rs`: `nvidia-smi` so stropom okolo 1,5 s (`spawn` + čakanie, potom `kill`). Lepšie je
     jeden dlho bežiaci `nvidia-smi --query-gpu=… --format=csv,noheader,nounits -lms 1000`, ktorého riadky sa iba čítajú.
   - `WITHOUT` nahradiť opakovaním po 60 s.
   - Opraviť hlavičku `:8–9`.
   - Pridať test parsera pre viac riadkov.
   - `powergoo.luau`: pri zamknutí, nečinnosti stupňa 2 a vyššie a pri okne na celú obrazovku `kill` úlohy, po návrate
     znova `watch`. Fakty enginu už existujú (`E.busy`, idle).
9. **F17 Falošné poruchy.**
   - `bin/latte-devices` `no_firmware()`: ovládač, ktorý v tom istom boote firmvér nakoniec načítal, nepočítať. Ak to
     nejde jednoducho, počítať iba keď zariadenie nemá funkčné rozhranie (`/sys/class/net/*` up, `drm` karta).
   - USB `ff` bez ovládača: stav `ok` s poznámkou, nepočítať do `faults`.
   - Prípady pridať do `tests/test_devices.py`.
10. **F16** `queengoo.luau:48`: po pravom kliku `after(60000, look)` ako po ľavom.
11. **D9, F3 Profil.**
    - `powergoo.luau:149`: `run = open.settings("me")`, `quiet` preč.
    - `icon = ~/.face`, ak existuje.
    - Meno z `getent passwd` (5. pole).
    - `since` z `loginctl show-session $XDG_SESSION_ID -p Timestamp`, s dátumom, ak to nie je dnes.
12. **F4 Úsporný profil.** `powergoo.luau` `read_profile` volať aj pri štarte (už je) a po `set` povedať enginu
    `fact.low_power_saver`. `engine.luau:795–798`: `fact.low_power = low_battery or saver`.
13. **D2, D3 Znenie potvrdenia.**
    - Ponechať akciu v nápise: „Vypnúť? (3 okná)“, kľúče v `goo/lang/sk.plm`.
    - Overiť šírku pri 1024 × 768.
    - „Núdzový režim“ → „Režim SAFE…“.
    - Rozhodnúť `danger` pri Reštartovať a podľa toho opraviť LATTEOS-GOO §4.2.
14. **D12 Potvrdenie.** `apps/appmanager.qml:619` (Barista Odinštalovať) a `:384/440` (Odstrániť) na druhé stlačenie
    podľa vzoru služieb v `monitor.qml:283–288`. V Monitore pri Ukončiť pre procesy LatteOS a kompozitora to isté.
15. **D5 Geometria pása.** `strip.plm:34–36`: názov na −0,5R, hodnota na +0,18R, alebo R 22 → 24 v `powergoo.luau:29`.
    Názov aspoň 10,5 px. Overiť aj bočný okraj (D6).
16. **Dokumenty a mŕtvy kód.**
    - LATTEOS-GOO §8: GPU nie je iba amdgpu, Monitor existuje.
    - ROADMAP 6.37: SAFE až po bode 3.
    - Docstring `latte-monitor`.
    - Vetvy Hyprlandu vo `wm.luau` (F6).
    - D4 rozhodnúť a zapísať do ROZHODNUTIA.
    - D11 znenie.

### Po 0.6 — funkcie

- **Riadené vypnutie ako vo Windows** (F2): zavrieť okná, počkať, ukázať „tieto aplikácie bránia vypnutiu“ s Vypnúť aj
  tak a Zrušiť.
- **Pás výkonu:**
  - takt, najnáročnejší proces a swap v bubline;
  - výber veličín (6C.03, 6C.04);
  - stránky Monitora po častiach (CPU, GPU), aby klik viedol presne;
  - NVML namiesto `nvidia-smi`, GPU po procesoch (10D.19);
  - výber GPU pri viacerých kartách;
  - prahy teploty z `temp*_crit` / `temp*_max` hwmon (F9).
- **Batéria:** guľky podľa pravidla 24 (pri ≥ 30 % nič) a bez zelenej, ktorá znamená sieť. Najprv treba rozhodnutie a
  zmenu §4.2 (D8). Prípadne Hibernovať.
- **QueenGoo:**
  - sledovanie pripojenia zariadení (udev) namiesto 3 h;
  - tvar korunky (6C.04);
  - Latte-Workfield (6E.02);
  - zrodenie z bubliny na pleamar-wm (1D.08);
  - LPnP (10E.14 a ďalej).
- **Ctrl+Alt+Del:** rozmazanie, všetky monitory (F14, ak naživo potvrdené, môže ísť aj pred 0.6 ako oprava), Prepnúť
  používateľa (greetd), stránky Sieť a Prístupnosť v Nastaveniach.
- **App Manager:**
  - systémové Flatpaky bez hesla;
  - 10H.13, 10H.14;
  - odhad, čo `dnf check-update` stojí (F18): radšej PackageKit alebo cache systému.
- **Monitor:** stránka Hardvér (10D.13), základ z Mission Center (10D.17).

---

## Na overenie naživo

1. PowerGoo › Reštartovať a Vypnúť (test 036): vypne bez hesla? Čo sa stane, keď polkit odmietne? (F1)
2. PowerGoo › Úspora / Výkon: prepne sa profil? `switch-profile` má „any“ = `no`. (F1, F5)
3. Nabité Vypnúť pri otvorených oknách: dá sa prečítať nápis? Skracuje sa „Naozaj? (okná: N)“, „Reštartovať“ a „Núdzový
   režim“ pri 1024 × 768? (D1, D2)
4. Pás výkonu na spodnom a bočnom okraji: prekrýva sa názov s hodnotou, zmestí sa „12,3 G“? (D5, D6)
5. Skryť PowerGoo so zapnutým pásom, odhlásiť sa a prihlásiť: ostanú bunky bez kapsuly? Beží `latte-stats`
   (`pgrep -a latte-stats`)? (F11)
6. Ctrl+Alt+Del na dvoch monitoroch: stmavne aj druhý? Dá sa na ňom klikať? (F14)
7. Ctrl+Alt+Del v SAFE (po oprave 3): skratka, Odhlásiť sa, Vypnúť. (F13)
8. Notebook s Intel Wi-Fi (latte-lab alebo iný): `latte-devices list` → `faults` a stav `iwlwifi`. (F17)
9. Notebook Intel + NVIDIA: zostane dGPU v D3 so zapnutým pásom (`cat /sys/bus/pci/devices/…/power/runtime_status`)? (F9)
10. Monitor › Procesy: je v zozname `pleamar-wm`, `latte-goo` alebo `latte-session` s tlačidlom Ukončiť? (D12)
11. `dnf check-update` ako používateľ: koľko stiahne a kam (`du -sh ~/.cache/libdnf5`). (F18)
12. Ctrl+Alt+Del: odozva tlačidiel vpravo dole na prechod myšou a farby na šálke porcelán. (D7, D10)
