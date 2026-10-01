# Engine Goo

Spoločný engine pre kvapky LatteOS Goo. Je to rozšírenie pleamar („DLC“), ktoré používa zdokumentovaný jazyk 0.2
a API logiky. Jediná záplata Rustu (`pleamar-prazdne-tvary`) je iba na výkon: bez nej engine funguje, ale pomalšie.

Zatiaľ je oddelený od plochy Kvapky (`session/kvapky`). Skúša sa v relácii **LatteOS Kvapky – engine test**
na prihlasovacej obrazovke. Keď sa overí, prejdú naň TimeGoo, PowerGoo, DaNoGoo, QueenGoo a ChatGoo.

**Pravidlá plochy platia aj tu: [LATTEOS-GOO.md](../../LATTEOS-GOO.md) §2 a §3** (pred prácou prečítať).
Engine ich nastavuje všeobecne:
- Kvapky sú vždy káva (pomer vody a mlieka z Baristu) a nemajú tvár.
- Kurzor kvapky **iba priťahuje** a je ich svetlom.
- Kontextový klik je iba tam, kde ho kvapka má.
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
| kvapky | `kvapky/*.luau` | moduly: **TimeGoo, PowerGoo a hlava Goobaru** (rozmery a rozostupy ako v Kvapkách, na porovnanie), počítadlo, hodiny, zvedavka, lepkavá, ťažká, bublinka, kvapôčka |
| príklady | `priklady/*.json` | kvapky používateľa (kalkulačka, systém) |

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
  **Bez háčika nerobia nič** (pravidlo 8). Veľkosť kolieskom iba s `zoom = true`.
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
- skupina: `pri` (id inej kvapky) + `odstup` (px), `vyska` (stred nad okrajom, px), `vznos` 0…2.

Farba nie je: kvapky sú vždy káva.

Neskôr to isté pribudne v Nastaveniach › Kvapky (formulár nad týmto súborom).

## Nová kvapka — programátor (vlastné správanie)

Modul `kvapky/<meno>.luau` vracia definíciu: rovnaké polia ako JSON a k nim **háčiky**.

```lua
return {
    id = "pocitadlo", nazov = "Počítadlo", ikona = "123", druh = "ukazovatel", povaha = "pokojna",
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
