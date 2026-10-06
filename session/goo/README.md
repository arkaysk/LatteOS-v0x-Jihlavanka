# Engine Goo

Spoločný engine pre kvapky LatteOS Goo. Je to rozšírenie pleamar 0.2.6 („DLC“), ktoré používa zdokumentovaný jazyk
0.2 a API logiky. Záplaty Rustu (`resources/patches/`: `pleamar-prazdne-tvary` a `pleamar-pasy-tela` na výkon,
`pleamar-ostre-okraje` na ostré oká) nie sú nutné: bez nich engine funguje, iba pomalšie a s mäkšími okrajmi.

Zatiaľ je oddelený od plochy Kvapky (`session/kvapky`), ktorú má nahradiť a stať sa predvoleným prihlásením. Skúša sa
v relácii **LatteOS Kvapky – engine test** na prihlasovacej obrazovke. Kvapky sú podľa Novej architektúry
(LATTEOS-GOO.md): jadro GooBar, GooPower, LensGoo; voliteľné QueenGoo, ClockGoo (ChatGoo zatiaľ nie je).

**Pravidlá plochy platia aj tu: [LATTEOS-GOO.md](../../LATTEOS-GOO.md) §2 a §3** (pred prácou prečítať).
Engine ich nastavuje všeobecne:
- Kvapky sú vždy káva (pomer vody a mlieka z Baristu) a nemajú tvár.
- Kurzor kvapky **iba priťahuje** a je ich svetlom.
- Klik je iba tam, kde má kvapka funkciu; tlačidlo bez funkcie goo zavibruje (kliky kvapiek shellu: §3.5).
- Všetky kvapky sú drag & drop.
- Všetky sú v jednom goo tele s lištou.

## Prečo engine

V ploche Kvapky má každá kvapka vlastnú kópiu pravidiel: polohu, ťahanie, zoom aj zóny. Tu sú pravidlá napísané
**raz**. Kvapka je iba záznam s číslami (povaha) a voliteľnými háčikmi (správanie).

| Vrstva | Súbor | Čo robí |
|---|---|---|
| scéna | `goo.plm` | fyzika a vstupy myši pre **128 miest** (`repeat`), jedno goo telo s okrajom |
| generátor | `gen.py` | rozpíše telo goo (jazyk nemá `repeat` v `body`), nastaví počet miest `N`, zoznam modulov |
| logika | `lib/engine.luau` | register kvapiek, povahy, háčiky, uloženie polôh, káva, nečinnosť (hra) |
| používateľ | `lib/pouzivatel.luau` + `latte-goo` | kvapky z JSON, za behu (bez reštartu) |
| kvapky | `kvapky/*.luau` | moduly: **GooBar, GooPower, LensGoo, QueenGoo, ClockGoo** (rozmery a rozostupy trojice ako v Kvapkách), počítadlo, hodiny, zvedavka, lepkavá, ťažká, bublinka, kvapôčka |
| príklady | `priklady/*.json` | kvapky používateľa (kalkulačka, systém) |
| Goobar | `lib/goobar.luau` | okná ako kvapky (ikry po aplikáciách, vlastná skupina, menšie, uhýbajú oknám pri lište), pomenovanie okien, ponuka okna, režim okien |

**Kvapky plochy v engine:** `goobar` (hlava + okná), `goopower` (ponuka, batéria), `lensgoo` (lupa, spúšťač) — jadro,
`zaklad = true`, nedajú sa skryť; `queengoo` (guľky, App Manager / Správca zariadení) a `clockgoo` (čas, dátum,
upozornenia) — voliteľné, skrýva ich Nastavenia › Kvapky (`kvapky.json`). Kliky (6. 10., LATTEOS-GOO.md §3.5):

| kvapka | ľavý | pravý |
|---|---|---|
| hlava GooBaru | ďalší režim okien | ukázať plochu (Win+D) |
| ikra okna | prepnúť / minimalizovať | ponuka okna |
| GooPower | karta: profil účtu, Zamknúť · Odhlásiť, napájanie a profil napájania, Nastavenia, Monitor, Uspať · Reštartovať · Vypnúť | pás výkonu (kapsula s CPU, RAM, GPU, VRAM — `latte-sysmon goo`) |
| LensGoo | spúšťač | rýchly zoznam (dlaždice naposledy spustených a obľúbených) |
| ClockGoo | upozornenia a kalendár (dva stĺpce) | čas: prehľad, stopky, minútka, budíky, počasie |
| QueenGoo | App Manager | Správca zariadení | Spoločné: **ponuka Goo** (`E.menu`, karta pri
mieste kliku, podponuky, preklady), **guľky** (`d:gulky(n, farby)`), **ikona aplikácie** (`d:obrazok(meno)`),
**`E.upsert`** (kvapky, ktoré vznikajú za behu, napr. okná, bez preskočenia).

## Čo robí každá kvapka (spoločné pravidlá)

- **Kurzor ako gravitácia a svetlo:** v dosahu (`dosah` px) ju priťahuje (`gravitacia` 0…1, nikdy neodpudzuje)
  a kvapka sa k nemu nakloní. Svetlá škvrna a odlesk sú na strane ku kurzoru.
- **Nadnesenie:** keď sa kurzor priblíži, kvapka na lište sa nadnesie (`vznos`), vystúpi kolmo od lišty na
  stopke, ktorá sa naťahuje a tenčí. Susedné kvapky sa pri tom prelievajú a spájajú. Keď kurzor odíde, padne
  späť s prestrelením a odrazom.
- **Susedia na lište** (logika ich nájde podľa polohy, do ~2,6 súčtu polomerov), ako vypínač ↔ Hodiny ↔ hlava
  v Kvapkách:
  - keď sa kurzor priblíži k jednej, sused sa nadnesie tiež (o 30 %) a nakloní sa k nej;
  - spája ich **voda pri okraji**: údolie medzi nimi nesiaha k okraju a skupina pôsobí ako jedna hmota;
  - spája ich **goo vlákno** medzi hornými časťami: čím sú bližšie, tým je hrubšie; nepravidelné (vlastný šum
    hrúbky aj koncov), hrubne s nadnesením a samo sa tvorí a trhá s tokom. Pod ním, nad vodou, vznikajú **oká**;
  - voda leží pod hladinou a nad ňu sa dvíha iba zliatím (inak by zaliala oká).
- **Tok:** každá kvapka pomaly vystupuje a klesá vo vlastnom rytme. Sila zliatia (`10 + 16 · nadnesenie +
  10 · tok`, ako `link` v Kvapkách) sa mení s ním, preto sa susedia raz spoja, raz rozdelia.
- **Nad kvapkou:** mierne sa nafúkne a rôsolovito pulzuje (do šírky a do výšky). Obsah sa nemení, názov a popis
  sú iba v bubline. Pri stlačení sa stlačí (squish).
- **Vlastný pohyb aj bez myši:** dych a pomalý drift.
- **Vstupy:** ľavé tlačidlo (klik = pustenie bez ťahania), pravé, stredné, podržanie (0,65 s), koliesko.
  **Bez háčika nerobia nič** (pravidlo 8) — kvapka iba zavibruje. Veľkosť kolieskom má každá kvapka (`zoom`
  predvolene áno, „zväčšovať sa dajú všetky“), ak koliesko nepoužíva na iné; nie okná GooBaru a bobule.
- **Ťahanie (všetky kvapky):**
  - `lepivost` 0…1 drží kvapku doma: natiahne krk a odtrhne sa až za `trhanie` px; pustená skôr sa vráti;
  - pri lište sa k nej prilepí;
  - ťažká (`hmotnost`) spadne na lištu a odrazí sa.
- **Farebné jadro (pravidlo 17):** od stredu prechod z farby do kávy, predvolene upozornenie.
  - Luau: `d:jadro("siet", 1, true)`, `d:jadro()` zhasne.
  - JSON: `"jadro": "softver"` (stále) alebo `"upozornenie": {"prikaz": "…", "kazdych": 30}` — výstup príkazu je
    farba (`hardver`, `siet`, `softver`, `vystraha`, `svetlo`, `ine`), prázdny výstup jadro zhasne; nové
    upozornenie zvlní hladinu.
- **Hladina (pravidlo 18):** okraj obrazovky je voda.
  - Kameň do vody: dve vlny sa rozbehnú od miesta dopadu a slabnú, kvapky na nich sa nadvihnú.
  - Vibrácia: chvenie na mieste.
  - Luau: `d:vlnka(sila)`, `d:vibruj(sila)`, `E.vlnka(x_px, sila, "kamen" | "vibracia")`.
  - Zvonka: `pleamar --say goo "emit goo_kamen 512"` (napr. minimalizované okno padne do lišty).
- **Vietor (pravidlo 19):** občas zavanie, smer je náhodný; postupná vlna pozdĺž okraja, kvapky sa vlnia ako obilie.
  Menšie kvapky sa vlnia viac (aj tok a drift).
- **Návrat k okraju (pravidlo 20, Marea):** kvapka sa ponorí pod hladinu a vynorí, hladina sa zvlní. Odtrhnutie
  najneskôr po 1,6 polomeru (dlhý krk je nepekný).
- **Oká a ostrý okraj (pravidlo 21):** záplata `pleamar-ostre-okraje` vyhladzuje hranu podľa skutočnej zmeny
  vzdialenosti na pixel, preto je okraj ôk ostrá čiara; tieň je tesný (0, 2, 2).
- **Neprekrývanie (pravidlo 22):** kvapky sa môžu zlievať, ale nie úplne prekryť. Stredy ostanú aspoň 0,95 súčtu
  polomerov od seba, inak sa jedna plynule odsunie, aj reťazovo. Ustúpi tá, na ktorú pustili, nikdy okná Goobaru ani
  pripnuté kvapky. `E.separate()` po pustení, pridaní, zmene veľkosti a zmene okien.
- **Okraje a gravitácia:** kvapka sedí na jednom zo štyroch okrajov (`okraj` 0 dole, 1 vľavo, 2 hore, 3 vpravo;
  predvolene dole). Pustená do 130 px od okraja sa k nemu prilepí, inak spadne dole voľným pádom (`GRAV`) — nič
  nevisí vo vzduchu (výnimka `visi`: bobule otvoreného hrozna upozornení). `vratit = true` (GooBar): pri pustení
  uprostred sa vráti. Háčik `pustenie(d, X, Y, okraj)` dostane miesto v px obrazovky; `false` = nepresúvať.
  `d:px()` je poloha pozdĺž okraja kvapky; `E.hiAlong(d)` najďalej, kam smie (rohová lišta Noctalie je zakázaná zóna).
- **Kapsula:** `kw` (polovica rovnej časti, px) a `t2` (druhý riadok) urobia z kvapky kapsulu s ikonou vľavo.
  Rovná časť leží **pozdĺž okraja** kvapky (na bokoch zvisle) a jej dĺžka sa mení pružinou — kvapka sa do kapsuly
  natiahne. `kd` = smer: 0 na obe strany (bobuľa), −1 / +1 iba jedným smerom — ikona ostane na konci pri pôvodnej
  kvapke (pás výkonu GooPower). Pravidlo 22 ráta s celou kapsulou (`E.capOff`): susedia sa odsunú. `fix = true` =
  kvapka si v pokoji nesadá (obsah musí byť celý vidieť).
  `koruna = "crown"` nakreslí znak na vonkajšej strane kvapky.
- **Karta Goo** `E.menu(items, šírka, opts)`: položky `label, glyph, hint, on, off, danger, sep, sub, run` a navyše
  `big` (veľký nadpis), `bar` (pruh 0…1), `keep` (klik kartu nezavrie), `wheel = function(smer)` (koliesko nad
  riadkom). `opts.chips = { { label, glyph, on, run } }` sú záložky hore, `opts.id` meno karty (`E.menuId()`),
  `opts.keep` obnovenie otvorenej karty bez zmeny zvýrazneného riadku (živé údaje).
  Ďalšie položky: `info` (údaj na čítanie), `{ grid = true }` (mriežka kalendára: `model.kal`, `E.calendar(klik, šípky)`),
  `{ input = true, label = nápoveď, submit = function(text) }` (textové pole, Enter odošle). Esc kartu zavrie.
  V riadku ešte: `img` (ikona aplikácie podľa mena), `right = function()` (pravý klik), `para` (odsek v bubline),
  pri poli `change = function(text)` (písanie; `submit` vráti `true`, ak má text v poli ostať). `E.menuAt(d)` položí
  kartu ku kvapke (otvorenie z klávesnice), `E.menuText(v)` číta a nastaví text poľa. Rozmery: zadaná šírka × 1,2,
  riadok 44 px; koliesko v karte prepína záložky, Tab / Shift+Tab tiež, šípky a Enter vyberú riadok bez myši.
  Rozloženie (6. 10.): `t2` druhý riadok pod názvom (telo upozornenia), `hd` nadpis sekcie (malé tučné), `pro`
  profil účtu (portrét `img` v kruhu, meno `label`, údaje `t2`), `{ pills = { … } }` rad tlačidiel vedľa seba
  (každé ako položka; `on` = vybrané, `danger` = červené), `{ tiles = { … }, per = 4 }` dlaždice aplikácií (ikona nad
  názvom); `opts.cols = { šírka1, šírka2 }` karta v dvoch stĺpcoch — položka s `col = 2` (aj mriežka kalendára
  a textové pole) ide do pravého. Najviac 24 riadkov; čo sa nezmestí na výšku (1024 × 768), sa nepridá.
- **Efekty scény:** `dych`, `kmit`, `tras`, `obeh`, `tlkot` (+ `sila`).
- **Rezerva na nedefinované efekty:**
  - efekty 6–9 v scéne sú voľné;
  - kanály `e1`…`e4` na každej kvapke (s pružinou): e1 veľkosť, e2/e3 posun, e4 žiara okraja;
  - druhy vzhľadu 2–3 sú voľné.
- **Nečinnosť (§3.1):**
  - stupeň 1 po 1 min: zaspávajú (menšie nadnesenie);
  - stupeň 2 po 3 min: počasie (rezerva, háčik `necinnost`);
  - stupeň 3 po 6 min: hra hravých kvapiek — naháňačka so zámernou zrážkou a stlačením, behanie, skákanie;
  - prebudenie myšou: zachvejú sa a vrátia na miesto.

Povahy (balík čísel): `pokojna`, `zvedava`, `lepkava`, `tazka`, `hrava`.

## Nová kvapka — používateľ (bez programovania)

```sh
latte-goo novy "Moja kvapka"     # vytvorí ~/.config/latteos/goo/kvapky/moja-kvapka.json zo vzoru
latte-goo skontroluj             # povie, čo je v súboroch zle
```

Súbor stačí upraviť a uložiť. Kvapka sa ukáže, zmení alebo zmizne do 4 s, bez reštartu. Príklad:

```json
{
  "id": "kalkulacka", "nazov": "Kalkulačka", "ikona": "calculator", "povaha": "zvedava",
  "popis": "Klik: kalkulačka", "poloha": { "x": 0.3, "y": 0 },
  "text": { "prikaz": "date +%H:%M", "kazdych": 30 },
  "akcie": {
    "klik": { "aplikacia": "org.gnome.Calculator" },
    "pravy": { "vystup": "uptime -p" },
    "podrz": { "otvor": "~/Dokumenty" },
    "koliesko": "velkost"
  }
}
```

**Akcie:**
- `spusti` — príkaz;
- `aplikacia` — id .desktop;
- `otvor` — súbor alebo adresa;
- `vystup` — výstup príkazu v bubline;
- vstavané `domov`, `velkost`, `poskoc`, `nic`;
- koliesko môže mať aj `{ "hore": akcia, "dole": akcia }`.

Príkazy vykoná `latte-goo` podľa id kvapky a mena akcie. Logika scény nikdy nepošle príkaz sama.

**Čísla a voľby:**
- veľkosť a pohyb: `velkost` 8–80, `gravitacia` 0…1, `vznos` 0…1, `dosah`, `lepivost` 0…1, `trhanie`,
  `svetlo`, `rast`, `hmotnost` 0…1;
- vzhľad: `efekt` + `sila`, `druh` (`ikona` | `ukazovatel` s `hodnota` 0…1);
- ďalšie: `tahat` (true/false), `poloha` (`x` = podiel šírky, `y` = px nad lištou);
- skupina: `pri` (id inej kvapky) + `odstup` (px), `vyska` (stred nad okrajom, px), `vznos` 0…2;
- skupina a zliatie: `sk` (0 ostatné kvapky, 1 ikry Goobaru, 2 hlava Goobaru — patrí do oboch; telo goo je jedno), `zliatie` (sila zliatia so susedmi), `mlaka` (mláka a voda pri okraji 0…1).

Farba nie je: kvapky sú vždy káva.

Neskôr to isté pribudne v Nastaveniach › Kvapky (formulár nad týmto súborom).

## Nová kvapka — programátor (vlastné správanie)

Modul `kvapky/<meno>.luau` vracia definíciu: rovnaké polia ako JSON a k nim **háčiky**.

```lua
return {
    id = "pocitadlo", nazov = "Počítadlo", ikona = "number-123", druh = "ukazovatel", povaha = "pokojna",
    start    = function(d) d.n = 0 d:text("0") end,
    klik     = function(d) d.n += 1 d:text(tostring(d.n)) d:hodnota(d.n % 100 / 100) end,
    pravy    = function(d) … end,  stredny = function(d) … end,  podrz = function(d) … end,
    koliesko = function(d, smer) … end,          -- smer +1 hore, −1 dole
    nad = function(d) d:rezerva(4, 1) end,  prec = function(d) d:rezerva(4, 0) end,
    popis    = function(d) return "text bubliny" end,
    tahanie  = function(d) d:efekt("tras", 1) end,
    pustenie = function(d, x, y) return false end,  -- false = nepresúvať (inak engine uloží novú polohu)
    necinnost = function(d, stupen) end,          -- 0 aktívny, 1 po 1 min, 2 po 3 min, 3 po 6 min
    kazdych = 10000, tik = function(d) … end,
}
```

Metódy kvapky:
- upozornenie a hladina: `d:jadro(farba, sila, pulz)`, `d:vlnka(sila)`, `d:vibruj(sila)`, `d:stlac()`;
- obsah: `d:text`, `d:ikona`, `d:nazov`, `d:hodnota`, `d:bublina(text)`;
- vzhľad: `d:efekt(meno, sila)`, `d:rezerva(i, v)`, `d:velkost(z)`;
- poloha: `d:presun(x, y)`, `d:domov()`, `d:poskoc()`;
- všeobecne: `d:nastav{…}`.

Po pridaní súboru treba spustiť `python3 gen.py`, ktorý obnoví `kvapky/zoznam.luau`. Pleamar potom logiku znova
načíta sám. Príkazy, ktoré modul spúšťa cez `run`, musia byť v `permissions` v `goo.plm`.

## Nový efekt

- **V scéne** (plynulý, bez logiky): doplniť výraz pre `fx == 6` (rezerva) do `fxs`/`fxw`/`fxx`/`fxy` v `goo.plm`
  a meno do `EFEKTY` v `lib/engine.luau`.
- **V logike** (zriedkavé zmeny): kanály `d:rezerva(1…4, hodnota)`, scéna ich vyhladí pružinou.

## Ďalej (z pravidiel plochy, zatiaľ nie v engine)

- Okno z kvapky (pravidlá 9 a 14): kvapka vystúpi a pripojí sa k oknu rohom, alebo vypľuje bublinu, ktorá sa
  nafúkne na okno. V ploche Kvapky to funguje; do enginu to príde ako druh kvapky (rezerva 2–3).
- Dážď a vietor podľa počasia (§3.1 stupeň 2), hladina so vlnkami (§3).

## Jazyk pleamar 0.2 — čo treba vedieť

- **`repeat` v `body` nejde.** Telo preto rozpisuje `gen.py`.
- **`let` vnútri `repeat` patrí iba svojej kópii.** Hodnoty potrebné zvonka sú preto pružiny `~0ms`: globálne,
  s tou istou hodnotou v tom istom snímku.
- **`sin` a `cos` sú v stupňoch.**
- **`smooth()` chce stále hranice.** Pre hranice z modelu treba vlastnú krivku t²(3 − 2t).
- **Veľkosť textu sa píše `číslo × pomer`** (`20 * rs.$k`), nie `rr.$k * 0.78`.
- **`pick` neberie farby.** Treba vnorené `if`.
- **`emit` v Luau nenesie hodnotu** (iba meno). Pre jednu kvapku logika zvýši počítadlo (`hopn.k`, `sqn.k`,
  `dipn.k`, `rpn.i`) a scéna zareaguje cez `on change`. Hodnotu nesie iba `emit` zo scény a `pleamar --say`.
- **Radiálny prechod (`gradient`) je iba v `body`.** Jadro kvapky je preto malé vlastné telo.
- **Telo goo počíta každý svoj tvar pre každý pixel** a `show: false` ho nevyradí. Preto existuje záplata
  `pleamar-prazdne-tvary` a krk ťahanej kvapky je jeden tvar (`pick(nk, …)`), nie 64.

## Overenie

```sh
pleamar --check goo.plm                         # jazyk, mená, poradie
pleamar --scene goo.plm --mouse "429,690@1500 down@2000 up@2100 wheel+@3000 right@3400" --record hud
```

Vľavo hore (`ladenie`) je posledná udalosť. V cloude to beží v headless Sway (llvmpipe) s falošnou myšou.
Falošná myš pleamar nevie stredné tlačidlo; `click` a `right` pošlú stlačenie aj pustenie v tom istom snímku,
preto treba `down@… up@…`.
