# Engine Goo — report pre novú session Claude Code

Stav k 2026-10-02, vetva `gamerdistro`, repo `arkaysk/jihlavanka001`, posledný commit enginu `ad563d0`.
Tento súbor je odovzdávka: čo engine je, kde čo leží, ako sa testuje, aké pasce jazyk má a čo ostáva.
Podrobnosti: `session/goo/README.md` (API a pasce), `LATTEOS-GOO.md` §2 (pravidlá 1–22) a §3.2 (engine),
`cloud_session_1.md` (história rozhodnutí a meraní), `ROADMAP.md`.

## 0. Pravidlá spolupráce (od používateľa)

- Hlavný fokus je **LatteOS Goo** (session „LatteOS Kvapky“: `session/kvapky/kvapka.plm` + `kvapka.luau`).
  Engine je zatiaľ **oddelený test** v session „Kvapky engine test“; Classic ostáva ako alternatíva.
- **Každú odpoveď a každý krok zapisuj do `cloud_session_1.md`** (koreň repa), potom commit a `git push -u origin gamerdistro`.
- Opatrne, nerozbiť hotový dizajn. Ovládanie je primárne myš (ľavé, pravé, koliesko). Terminál je dostupný iba po
  kliknutí na „Zobraziť terminál“.
- Pred úpravou správania kvapiek **prečítaj `LATTEOS-GOO.md`** (raz som to neurobil a porušil pravidlá).
- Inštalátor a Atomic sa nerobia, kým LatteOS nie je hotový. Pozície AI bublín sú zámerné.
- Pleamar a Marea sú od k4ditano, **BSD-3-Clause** (nie MIT): zachovať copyright, bez súhlasu nepoužívať meno na propagáciu.
  O povolenie pred vydaním požiada používateľ sám.

## 1. Čo engine je

Jednotný, rozšíriteľný engine kvapiek nad pleamarom 0.2.6, postavený ako „DLC“: scéna `.plm` + logika Luau + malé
záplaty pleamaru, ktoré sa aplikujú na čistý upstream, takže update pleamaru engine neruší.
Dôvod vzniku: v pôvodnej `kvapka.plm` má každá kvapka vlastné pravidlá. Engine dáva spoločné pravidlá (fyzika,
zlievanie, vstupy, efekty) a kvapka je iba definícia plus háčiky.

- **128 miest.** Goobar nesie okná ako ikry alebo strapce hrozna a na strojoch s veľkou RAM môže byť veľa okien.
- Kvapky pridáva **programátor** (súbor `session/goo/kvapky/*.luau`) aj **používateľ** (JSON cez `latte-goo novy`)
  kedykoľvek, bez reštartu.
- Každá kvapka má vlastné reakcie: hover, scroll, ľavý, pravý a stredný klik, podržanie, ťahanie a pustenie,
  gravitácia, lepivosť, veľkosť, efekty a 4 rezervné kanály `e1–e4`.

## 2. Mapa súborov

| Súbor | Obsah |
|---|---|
| `session/goo/goo.plm` (~1740 r.) | scéna: model `goo max 128`, fyzika miesta, telá, menu, tooltip, HUD |
| `session/goo/gen.py` | rozpíše telá pre 128 miest (jazyk nemá `repeat` v `body`), prepíše `max N`/`repeat k in 0..N`, vygeneruje `kvapky/zoznam.luau` |
| `session/goo/goo.luau` | vstup: `engine.start({ moduly, priklady = true, ladenie = true, prva = 0.02, prva_koniec = 0.33 })` |
| `session/goo/lib/engine.luau` | API: register, susedia, publish, pravidlo 22, vlnky, menu, nečinnosť, ukladanie |
| `session/goo/lib/goobar.luau` | port rozloženia Goobaru z `kvapka.luau`: pomenovanie okien, ikry/strapce, uhýbanie oknám |
| `session/goo/lib/pouzivatel.luau` | JSON kvapky používateľa (poll 4 s) |
| `session/goo/kvapky/*.luau` | goobar, timegoo, powergoo, queengoo, danogoo + ukážky (pocitadlo, hodiny, zvedavka, lepkava, tazka, bublinka, kvapocka, kamen, posta) |
| `session/goo/priklady/*.json` | kalkulacka, system (záťaž > 2 → jadro výstraha) |
| `session/bin/latte-goo` | CLI pomocník (viď §6) |
| `session/bin/latte-session` | `kvapky-engine` → `LATTE_VARIANT=kvapky`, `LATTE_KVAPKY_SCENE=$share/goo/goo.plm`, `LATTE_GOO_DIR` |
| `session/wayland-sessions/latteos-goo-engine.desktop` | prihlasovacia session „Kvapky engine test“ |
| `setup/f1/install-session.sh` | build a záplata pleamaru, `--check` scén, inštalácia do `/usr/share/latteos/goo/` |
| `resources/fetch.sh` | pleamar `v0.2.6`, pleamar-wm `v0.2.5`, marea-plm `a589189` do `resources/upstream/` (gitignored) |
| `resources/patches/` | záplaty, viď §3 |
| `docs/goo/*.png` | snímky z cloudu (porovnania, oká, Goobar, uhýbanie, neprekrývanie) |

## 3. Záplaty pleamaru (`resources/patches/`, aplikujú sa po sebe na čistý 0.2.6)

1. `pleamar-hyprland-okna-8bit.patch`: pôvodná záplata LatteOS.
2. `pleamar-prazdne-tvary.patch` (gpu.rs): tvary nulovej veľkosti sa preskočia. Pleamar inak počíta **každý tvar
   tela pre každý pixel**, aj skrytý.
   - 192 skrytých tvarov: 102 → 18 ms.
   - Pôvodná scéna Kvapky: 62 → 24 ms.
3. `pleamar-ostre-okraje.patch` (shape.wgsl): AA podľa skutočného gradientu SDF (`d / |∇d|`) namiesto pevnej šírky.
   Výsledkom sú **ostré obrysy ôk** medzi kvapkami v oboch scénach bez zmeny scén (pravidlo 21).
4. `pleamar-wm-linearny-buffer.patch`: bez zmeny.

`install-session.sh` prebuilduje pleamar, keď verzia nie je 0.2.6 alebo niektorá záplata chýba
(`git apply --reverse --check`).

## 4. Scéna `goo.plm`: ako funguje

**Model `goo` (jedno miesto = jedna kvapka):**
- poloha a fyzika: `on, hx` (zlomok W), `ox` (px), `hy` (px nad dnom), `r, z, rast, grav` (0..1), `dosah, vz`
  (nadnesenie 0..2), `lep, trh, svetlo, tahat`;
- efekty: `fx` (1 dych, 2 kolísanie, 3 tras, 4 obeh, 5 tlkot; 6–9 rezerva), `fa`, `e1–e4`;
- obsah: `druh` (0 ikona, 1 prstenec merača, 2 veľký text alebo hodiny), `hodnota, ikona, text, obr, img, tlm`;
- guľky: `gn, gf, gt` (`gf` je oktálová farba pre každú bodku);
- susedia: `nl, nlh, nlo, nr, nrh, nro, nry, nrr`;
- jadro: `jadro, jf, jp`;
- telo: `sk` (0 hlavné, 1 iba Goobar, 2 obe), `zl` (zliatie), `ml` (mláka).

**Farby:**
- Farba je **kávová** z faktov `voda`/`mlieko` (pravidlo 6). Žiadne farby po kvapkách, iba farebné jadro.
- Dno: `floor = H - 6`.

**Fyzika miesta (za snímok, v scéne):**
- Kurzor **iba priťahuje**. Blízkosť sa počíta iba nad kvapkou. Kvapka sa nadnesie a nakloní ku kurzoru, sused sa
  pridá s váhou 0.3. Nadnesenie je obmedzené výškou kurzora (≥ 0.25 r, ≤ 0.75 r), inak by kurzoru „utiekla“.
- Tok `fl` (noise) a pružina `pada` (odraz). Gravitácia: ukotvená kvapka sa nakláňa (±0.8 r), voľná sa posúva.
- Lepivosť `mv`. Odtrhnutie pri `min(trh, 1.6·r0)·lep` (pravidlo 20, žiadny dlhý krk).
- Dych a zväčšenie pri hover, efekty `fx`.
- **Vietor (pravidlo 19):** `gust`, náhodný smer `wdir`. Menšie kvapky sa vlnia viac:
  `small = clamp(26/r0, 0.6, 1.8)`.
- **Vlnky (pravidlo 18):** 4 sloty `rpx/rpa/rpk/rpg/rpn`. Kameň vytvorí dva hrebene, ktoré sa rozbiehajú na 420 px;
  vibrácia je chvejúci sa hrb.
- **Ponor (Marea):** kvapka sa pri návrate k okraju ponorí pod hladinu (`dipn`) a vynorí. `sqn` je stlačenie, `hopn` poskok.
- **Vlákno** k susedovi: `th = (3 + 11·close)·irr`, kde `close = 1 − gap/(0.9·(r0+nrr))` a `irr` je noise 0.65–1.35.
  Čím bližšie, tým hrubšie, organicky nepravidelné. Pod vláknom vzniká **oko** (pravidlo 21).
- Voda leží pod hladinou na `floor + wa`, takže nad hladinou sa kvapky spájajú iba zliatím.

**Vstupy (zóna = kvapka + stopka, pri ťahaní celá obrazovka):**
- Stlačenie nastaví `lp` a stlačenie kvapky.
- Pravý a stredný klik.
- Podržanie 650 ms; ruší klik (`lp = 0`).
- Koliesko: `k*2 + up`.
- Ťahanie začína od > 6 px a nastaví `nk = k`.
- Klik je pustenie ľavého bez ťahania.
- Pustenie zapíše `rx` (zlomok) a `ry` (px nad dnom).

**Nečinnosť:** úrovne pri 60/180/360 s, prebudenie zmenou kurzora.

**Telá (kreslenie):**
- **hlavné telo:**
  - gradient pri kurzore, okraj 28 %, `shadow: 0, 2, 2, 28%` a box lišty na y = H;
  - tvary z `gen.py` s podmienkou `sk != 1`;
  - hrebene vlniek;
  - **jeden** globálny krk cez `pick(nk, …)`.
- **telo Goobaru** (`sk >= 1`): bez boxu na celú šírku. Box stál 17 ms, bez neho telo stojí ≈ 4 ms. Ikry sa preto
  lepia iba ku Goobaru, nie k ostatným goo.
- **telo jadra** pre každú kvapku: radiálny gradient od farby jadra do kávy (pravidlo 17, predvolene upozornenie).
- **Nad telami:** odlesky, žiara (`e4`), oblúk merača, ikona aplikácie (`image obr.$k`), 4 guľky, texty
  (`druh 2` používa Inter).

**Ďalšie prvky scény:**
- Menu Goo: model `ctx max 14`, karta s uškom, zóny `ctx_row.$m`/`ctx_away`, udalosti `ctx_pick`/`ctx_close`.
- Tooltip `tip`, ladiaci `hud`.
- Bloky `permissions` (run + services) a `translations sk`.

## 5. Logika: `lib/engine.luau` (API pre programátora)

```lua
local E = require("lib/engine")
E.define({
  id = "moja", r = 24, x = 0.5,            -- alebo pri = "goobar", odstup = -80 (kotva)
  povaha = "zvedava",                      -- pokojna | zvedava | lepkava | tazka | hrava
  grav = 0.3, vznos = 1, rast = 0.08, efekt = 1, druh = 0, ikona = "bell",
  start = function(d) end,
  klik = function(d) d:poskoc() end, pravy = function(d) E.menu({ ... }) end,
  stredny = ..., podrz = ..., koliesko = function(d, smer) end,
  nad = ..., prec = ..., popis = ..., tahanie = ..., pustenie = function(d, x, y) return false end,
  necinnost = function(d, uroven) end, tik = function(d) end, kazdych = 5,
}, "zdroj")
```

**Registrácia:**
- `E.define`: háčiky bežia v `pcall`, takže chyba jednej kvapky nezhodí ostatné.
- `E.upsert` mení dynamické kvapky bez skokov; ďalej `E.remove`, `E.get`, `E.each`.

**Metódy kvapky:**
- obsah: `d:text`, `ikona`, `nazov`, `hodnota`, `obrazok`, `stlm`, `gulky(n, farby)`;
- efekty a jadro: `efekt`, `rezerva`, `jadro(farba, sila, pulz)`, `vlnka`, `vibruj`;
- pohyb: `velkost`, `presun`, `domov`, `poskoc`, `stlac`;
- ostatné: `bublina`, `nastav`, `px()`.

**Globálne funkcie:**
- `E.vlnka(x_px, sila, "kamen"|"vibracia")`.
- `E.menu(items, sirka)`: položky `label`, `glyph`, `hint`, `on`, `off`, `danger`, `sep`, `sub`, `run`.
- `E.separate(prefer)`.

**Susedia a publikovanie:**
- Susedia sa hľadajú iba v rovnakom tele, pri medzere < 2.6·Σr pri nominálnych 1920 px. Ťahaná kvapka je vylúčená
  (inak by ostalo vlákno k jej starému miestu).
- `publish()` zapisuje `model.goo` dávkovo.

**Pravidlo 22 (`separate()`)** — kvapky sa nikdy úplne neprekryjú:
- minimálna medzera je 0.72·Σr;
- posúva sa kvapka bez kotvy (`pri`), ktorá nie je `dyn` ani ťahaná; ustúpi tá, na ktorú sa pustilo;
- ukotvená kvapka sa posúva po x; reťazovo najviac 10 prechodov; pri tom stlačenie a uloženie.

**Nečinnosť úroveň 3 (kvapky sa hrajú):** naháňačka s nárazom a stlačením, beh, skok. Prebudenie stlačí všetky kvapky.

**Služby cez `latte-goo`:** káva (`latte-goo kava`), mená glyfov (`latte-goo ikony`), uloženie pozícií
(`latte-goo uloz-stav`).

**Pouzivatel.luau (JSON):**
- akcie: `spusti, aplikacia, otvor, vystup, domov, velkost, poskoc, vlnka, vibracia, nic`;
- `koliesko: "velkost"` funguje ako zoom;
- jadro sa nastaví cez `"jadro": "siet"` alebo `"upozornenie": {prikaz, kazdych}`.

### Goobar (`lib/goobar.luau` + `kvapky/goobar.luau`)

**Hlava:**
- `r 44`, `sk = 2`: zlieva sa s ostatnými goo aj s ikrami.
- Klik prepína režim okien; koliesko posúva pásku alebo prepína okná. Režim číta `latte-goo rezim`.

**Pomenovanie okien:**
- wlr-foreign-toplevel dáva iba class, title a id, nie adresu z Hyprlandu.
- `app_of` páruje podľa StartupWMClass, id, konca id (Flatpak, napr. `org.codeberg.dnkl.foot`) alebo mena.
- `org.quickshell` sa skupinuje podľa titulku pred „ — “.
- Konkrétne okno sa adresuje cez `nth_of` a `hyprctl eval latte.win.%s(class, title, nth)`.

**Ikry a strapce:**
- Menšie (R0 22, tesné 17) v **samostatnom tele** (`sk = 1`, `zliatie 0.35`, `mlaka 0.15`).
- Okná tej istej aplikácie tvoria strapec (OFFS/JIT/ZIG). Hover ho rozvinie do radu, zbalí sa po 500 ms.
- Aktívne okno ×1.06, minimalizované ×0.84 a stlmené.
- Nad 96 okien vznikne kvapka „Ďalšie okná“, ktorá otvorí prehľad Noctalie.

**Ovládanie ikier:**
- Klik prepne okno (toggle).
- Pravý klik otvorí ponuku okna cez `latte.okno.*`: obnoviť, minimalizovať, maximalizovať, rozloženie ›, vždy navrchu,
  presunúť na plochu ›, zavrieť.
- Ťahanie preusporiada skupiny.

**Uhýbanie oknám:**
- `read_blocks` každých 0.7 s z `latte-goo okna`, `free_above`, `need = top·r + r + 56` (+16 hysterézia).
- Keď je nad ikrami otvorené okno Hyprlandu, ikry uhnú k okraju obrazovky.
- `mark_hidden` každé 2 s cez `hyprctl -j clients`.

### Prenesené kvapky

- **TimeGoo** (r 33, kotva goobar −92, hodiny `druh 2`): klik prepne spúšťač, pravý otvorí nastavenie času a pohodu.
- **PowerGoo** (r 19, kotva timegoo −66, vznos 1.8): ponuka Nastavenia, Monitor, Zamknúť, Odhlásiť, Uspať, Reštart a
  Vypnúť (`noctalia msg session …`); guľky ukazujú batériu.
- **QueenGoo** (x 0.86): guľky — červené poruchy, zelené offline, modré aktualizácie. Ľavý klik otvorí App Manager,
  pravý Device Manager, oba cez `latte-kvapky okno`.
- **DaNoGoo** (x 0.79, dátum `druh 2`): guľky upozornení, klik otvorí ich ponuku s „Vymazať všetko“.

## 6. `latte-goo` (CLI)

```
zoznam [--priklady]   novy   skontroluj   akcia ID KLUC   text ID   upozornenie ID
stav   uloz-stav JSON   ikony…   kava   rezim   okna
```

Validácia odmietne `farba` (pravidlo 6) a kontroluje čísla, povahu, efekt, druh, jadro a upozornenie.

## 7. Pasce jazyka pleamar 0.2 a Luau (stálo to čas, platí aj pre `kvapka.plm`)

**Scéna (pleamar):**
- V `body` nie je `repeat`, preto existuje `gen.py`. `gen.py` prepisuje **každé** `repeat k in 0..N`, ďalšie cykly
  musia mať iné meno premennej (menu používa `m`).
- `let` v `repeat` je lokálny pre kópiu. Hodnotu do rovnakého snímku exportuje `prop X.$k = 0 ~0ms` + `follow`.
- `sin`/`cos` berú **stupne**.
- `smooth()` chce konštantné hrany, inak treba ručné t²(3−2t).
- `size:` textu musí začínať číslom (`20 * rs.$k`).
- `pick()` nevie farby, pomôže vnorený `if`. `gradient` existuje iba v `body`.
- Tvary tela sa počítajú pre každý pixel a `show:false` ich neodstráni. Preto nulová veľkosť + záplata prazdne-tvary.

**Logika (Luau):**
- `emit(name)` z logiky **nenesie dáta** (opačný smer `emit ev(k)` áno). Signál pre konkrétnu kvapku sa preto posiela
  počítadlom (fakt + `on change`).
- Luau nemá `goto`. `save` je deklarované dopredu (`local save` … `save = function()`).
- `sys.watch` musí predchádzať `sys.call` tej istej služby, inak padli ďalšie kvapky.
- Logika nepozná rozmer obrazovky: scéna exportuje `fact sw/sh` cez `every 1s while sw != W or sh != H`.
  Na štarte je 0, preto fallback 1920.

**CLI pleamaru:**
- `--mouse` nemá stredné tlačidlo.
- `click@`/`right@` stlačia a pustia v jednom snímku, testy preto používajú `down@ up@`.
- `--say` berie meno scény malými písmenami (`goo`).

## 8. Testovanie v cloude

1. `resources/fetch.sh` a build pleamaru v `resources/upstream/pleamar` so záplatami.
   apt balíky: `libxkbcommon-dev libwayland-dev libfontconfig-dev libdbus-1-dev libpam0g-dev`.
2. `python3 session/goo/gen.py`, potom `pleamar --check session/goo/goo.plm` (aj `session/kvapky/kvapka.plm`).
3. Headless Sway (pixman, llvmpipe), 1920×1080, plávajúce okná, spúšťané cez `setsid -f`. Sway medzi ťahmi umiera,
   skript sa musí vytvoriť znova (bol v `/tmp`). Testovacie okná sú `foot`/`weston-terminal`, snímky `grim`, výrezy
   cez Pillow.
4. Pleamar: `--scene … --mouse "x,y@ms down@ up@ right@ wheel+@ out@" --record mena --say goo "emit goo_kamen 900"
   --seconds N --no-hud --no-vsync`.
5. V cloude chýba font Tabler, takže glyfy nie sú vidieť. To je očakávané.

## 9. Merania (cloud, llvmpipe, 1920×1080)

| Scéna | Snímok | p99 | CPU scény |
|---|---|---|---|
| Pôvodné Kvapky (trojica) | 29–31 ms | 45–48 ms | 1.65 ms |
| Engine, rovnaká trojica | 20.9 ms | 32 ms | 0.77 ms |

**Škálovanie enginu:**
- ≈ 3.5–4 ms na kvapku: 6 → 30 ms, 12 → 54 ms, 17 → 73–75 ms.
- S oknami a telom Goobaru ≈ 95 ms (Sway tu kompozituje na CPU).
- Na GPU (RX 640) to ešte nie je zmerané.

**Navrhnuté, čaká na súhlas:** „ostrovy“, čiže samostatné telá pre skupiny susedov, aby cena nerástla lineárne s
počtom všetkých kvapiek.

## 10. Overené a neoverené

**Overené v cloude:**
- Vstupy: všetky okrem stredného tlačidla.
- Fyzika: lepenie a odtrhnutie, pád ťažkej kvapky, uloženie pozícií.
- Nečinnosť: všetky úrovne vrátane naháňačky.
- Efekty: vlnky (šírenie zmerané), jadro, vietor, ponor.
- Goobar: zoskupenie okien foot, rozvinutie strapca, uhnutie pred oknom.
- Ponuka PowerGoo a pravidlo 22 (reťazové odsunutie).

**Treba overiť na latte-lab (Hyprland):**
- vstupy a ikony: stredné tlačidlo, ikony Tabler, `cursor.x/y` z Hyprlandu;
- výkon na RX 640;
- okná: ponuka okna a minimalizovanie (`latte.okno.*`/`hyprctl`), skutočné uhýbanie oknám;
- server upozornení.

## 11. Otvorené úlohy

1. Overenie na latte-lab (§10).
2. Ostrovy pre výkon, ale až po súhlase používateľa.
3. Preniesť zo Kvapiek do enginu:
   - spúšťač Goo;
   - časové menu (stopky, časovač, budíky);
   - kartu kalendára s počasím;
   - hrozno upozornení na vlákne;
   - let bubliny do okna (pravidlo 14);
   - kvapku bežiacu po vlákne.
4. Háčik v Hyprlande: minimalizované okno vyvolá `pleamar --say goo "emit goo_kamen X"`.
5. Formulár Nastavenia › Kvapky nad `latte-goo`.
6. Počasie: dážď a vietor (nečinnosť úroveň 2).
7. Vlastné `app_id` pre aplikácie LatteOS (jednoduchšie párovanie okien).
8. Neskôr presunúť TimeGoo, PowerGoo, DaNoGoo, QueenGoo a ChatGoo v hlavnej session Kvapky na engine.

**Kto kreslí čo:**
- **pleamar** (naša scéna): všetky popupy Goo — ponuky, menu času, kalendár, hrozno upozornení, bublina.
- **Noctalia:** control center, OSD, zámok, rohová lišta.
- **Hyprland:** skutočné okná aplikácií (App Manager, Nastavenia, Monitor, Device Manager, Súbory).

## 12. Commity enginu (najnovšie hore)

- `ad563d0`: pravidlo 22, neprekrývanie.
- `e051ab7`: ikry vo vlastnom tele, menšie, uhýbajú oknám.
- `196eb4d`: Goobar, PowerGoo, QueenGoo, DaNoGoo, TimeGoo, ponuka Goo, guľky.
- `d9b3d7d`: meranie engine verzus Kvapky.
- Staršie (záplaty, jadro, vlnky, vietor, ostré oká, 128 miest): `git log --oneline -- session/goo resources/patches`.
