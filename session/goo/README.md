# Engine Goo

Spoločný engine pre kvapky LatteOS Goo. Je to rozšírenie pleamar („DLC“), ktoré používa iba zdokumentovaný jazyk 0.2
a API logiky, bez záplat Rustu. Aktualizáciu pleamar preto prežije.

Zatiaľ je oddelený od plochy Kvapky (`session/kvapky`). Skúša sa v relácii **LatteOS Kvapky – engine test**
na prihlasovacej obrazovke. Keď sa overí, prejdú naň TimeGoo, PowerGoo, DaNoGoo, QueenGoo a ChatGoo.

## Prečo engine

V ploche Kvapky má každá kvapka vlastnú kópiu pravidiel: polohu, ťahanie, zoom aj zóny. Tu sú pravidlá napísané
**raz** pre všetky kvapky. Kvapka je iba záznam s číslami (povaha) a voliteľnými háčikmi (správanie).

| Vrstva | Súbor | Čo robí |
|---|---|---|
| scéna | `goo.plm` | fyzika a vstupy myši pre 16 miest (`repeat`): pružiny, gravitácia a svetlo kurzora, lepivosť s odtrhnutím, veľkosť, efekty, zliatie s lištou |
| generátor | `gen.py` | rozpíše telo goo (jazyk zatiaľ nemá `repeat` v `body`) a zoznam modulov |
| logika | `lib/engine.luau` | register kvapiek, povahy, predvolené správanie, uloženie polôh, nečinnosť (hra) |
| používateľ | `lib/pouzivatel.luau` + `latte-goo` | kvapky z JSON, za behu (bez reštartu) |
| kvapky | `kvapky/*.luau` | moduly programátorov (príklady: počítadlo, hodiny, zvedavka, plachá, lepkavá, ťažká, bublinka, kvapôčka) |
| príklady | `priklady/*.json` | kvapky používateľa (kalkulačka, systém) |

## Čo vie každá kvapka

- **Kurzor**: gravitácia (`gravitacia` +1 priťahuje, −1 odpudzuje, v `dosah` px) a svetlo (odlesk na strane kurzora).
- **Prechod myšou**: zväčší sa (`rast`). Po 0,45 s ukáže bublinu (`popis` alebo háčik `popis`).
- **Ľavé tlačidlo** (klik = pustenie bez ťahania), **pravé**, **stredné**, **podržanie** (0,65 s), **koliesko** (hore/dole).
- **Ťahanie**: `lepivost` 0…1 drží kvapku doma. Natiahne sa na krku a odtrhne sa až za `trhanie` px.
  Pustená skôr sa vráti. Pustená pri lište sa k nej prilepí. Ťažká (`hmotnost`) spadne na lištu a odrazí sa.
- **Veľkosť**: koliesko (predvolené, 0,6…2,4). Stredné tlačidlo vráti miesto aj veľkosť (predvolené).
- **Efekty scény**: `dych`, `kmit`, `tras`, `obeh`, `tlkot` (+ `sila`).
- **Rezerva**: efekty 6–9 v scéne sú voľné. Kanály `e1`…`e4` na každej kvapke ovláda logika (s pružinou):
  e1 veľkosť, e2/e3 posun, e4 žiara okraja. Druhy 2–3 (vzhľad) sú tiež voľné.
- **Nečinnosť**: po 30 s sa hravé kvapky (`povaha = "hrava"`) hrajú: skáču, túlajú sa a naháňajú sa. Po 2 min
  častejšie. Pohyb myši ich hneď zastaví a vráti domov.

Povahy (balík čísel): `pokojna`, `zvedava`, `placha`, `lepkava`, `tazka`, `hrava`.
Farby: `kava`, `karamel`, `smotana`, `cokolada`, `visna`, `mata`, `levandula`, `med`.

## Nová kvapka — používateľ (bez programovania)

```sh
latte-goo novy "Moja kvapka"     # vytvorí ~/.config/latteos/goo/kvapky/moja-kvapka.json zo vzoru
latte-goo skontroluj             # povie, čo je v súboroch zle
```

Súbor stačí upraviť a uložiť. Kvapka sa ukáže, zmení alebo zmizne do 4 s, bez reštartu. Príklad:

```json
{
  "id": "kalkulacka", "nazov": "Kalkulačka", "ikona": "calculator", "povaha": "zvedava", "farba": "smotana",
  "popis": "Klik: kalkulačka", "poloha": { "x": 0.3, "y": 0 },
  "text": { "prikaz": "date +%H:%M", "kazdych": 30 },
  "akcie": {
    "klik": { "aplikacia": "org.gnome.Calculator" },
    "pravy": { "vystup": "uptime -p" },
    "stredny": "domov",
    "podrz": { "otvor": "~/Dokumenty" },
    "koliesko": { "hore": { "spusti": "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+" },
                  "dole": { "spusti": "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-" } }
  }
}
```

Akcie: `spusti` (príkaz), `aplikacia` (id .desktop), `otvor` (súbor alebo adresa), `vystup` (výstup príkazu
v bubline), alebo vstavané `domov`, `velkost`, `poskoc`, `nic`. Príkazy vykoná `latte-goo` podľa id kvapky
a mena akcie. Logika scény nikdy nepošle príkaz sama.

Čísla: `velkost` 8–80, `gravitacia` −1…1, `dosah`, `lepivost` 0…1, `trhanie`, `svetlo`, `rast`, `hmotnost` 0…1,
`efekt` + `sila`, `druh` (`ikona` | `ukazovatel` s `hodnota` 0…1), `tahat` (true/false), `poloha`
(`x` = podiel šírky, `y` = px nad lištou).

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
    necinnost = function(d, uroven) end,          -- 0 aktívny, 1 po 30 s, 2 po 2 min
    kazdych = 10000, tik = function(d) … end,
}
```

Metódy kvapky: `d:text`, `d:ikona`, `d:nazov`, `d:hodnota`, `d:efekt(meno, sila)`, `d:rezerva(i, v)`,
`d:velkost(z)`, `d:presun(x, y)`, `d:domov()`, `d:poskoc()`, `d:bublina(text)`, `d:nastav{…}`.
Čo kvapka nemá, robí engine: koliesko mení veľkosť, stredné tlačidlo ju vráti na miesto, pravé ukáže meno.

Po pridaní súboru treba spustiť `python3 gen.py`, ktorý obnoví `kvapky/zoznam.luau`. Pleamar potom logiku znova
načíta sám. Príkazy, ktoré modul spúšťa cez `run`, musia byť v `permissions` v `goo.plm`.

## Nový efekt

- **V scéne** (plynulý, bez logiky): doplniť výraz pre `fx == 6` (rezerva) do `fxs`/`fxw`/`fxx`/`fxy` v `goo.plm`
  a meno do `EFEKTY` v `lib/engine.luau`.
- **V logike** (zriedkavé zmeny): kanály `d:rezerva(1…4, hodnota)`, scéna ich vyhladí pružinou.

## Overenie

```sh
pleamar --check goo.plm                         # jazyk, mená, poradie
pleamar --scene goo.plm --mouse "429,690@1500 down@2000 up@2100 wheel+@3000 right@3400" --record hud
```

Vľavo hore (`ladenie`) je posledná udalosť. Cloud: overené v headless Sway (llvmpipe) falošnou myšou. Stredné
tlačidlo falošná myš pleamar nevie, to treba overiť na latte-lab.
