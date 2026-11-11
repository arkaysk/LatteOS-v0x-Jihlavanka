# GooEngine 2 — „Živá hladina“

Návrh a pokyny na kódovanie · 11. 11. 2026, druhé znenie (po rozhodnutiach používateľa z večera 11. 11.)
Vetva `v0.5-pleamarwm-jihlavanka` · ROADMAP 6.09, 6.21, 6.27–6.30, 6M, 1D.25–1D.27

Zadanie pre reláciu, ktorá GooEngine prepíše. Zásady Goo (`LATTEOS-GOO.md` §2–3) platia ďalej: kvapky sú káva,
kurzor iba priťahuje, karta rastie z ucha, okraj obrazovky je hladina. Mení sa, **z čoho pohyb vzniká** (fyzikálne
jadro v Ruste), **ako sa hmota kreslí** (jedna hmota, jeden obrys) a pribúda kurzor ako súčasť Goo.

**Ako bol návrh overený.** Prečítaný je pohybový kód enginu (`goo/parts/*.plm`, `goo/gen.py`,
`goo/lib/engine.luau`, `goo/lib/card.luau`), scéna okien (`system/pleamarwm/wm/session.plm`), referencia jazyka
a zdrojový kód pleamaru 0.7.10 a 0.7.27 a pleamar-wm 0.6.9 a 0.6.15. **Pleamar sa v tejto relácii nepodarilo
preložiť ani spustiť.** Ukážky kódu sú náčrty; každú treba prejsť cez `pleamar --check`, `cargo test` a zmerať na
latte-lab. **[zdroj]** = prečítané v zdroji pleamaru; **[overiť]** = odhad, ktorý musí potvrdiť skúška.

---

## 1. Rozhodnutia používateľa (11. 11.)

| Vec | Rozhodnutie |
|---|---|
| Pokojný stav | spomalený dych na menej snímkach **môže byť** |
| Pustená kvapka | **letí v smere hodu**, podľa fyziky |
| Kývanie okien | **celý obsah okna**, ako wobble na Hyprlande |
| Hladina | **iba dole** |
| Dážď pri nečinnosti na hladine | **zrušený**. Počasie pri nečinnosti preberie dážď a sneh pleamar-wm na oknách (§12) |
| Jadro fyziky | **priamo v Ruste**, nie obchádzky v jazyku scény |
| Kreslenie | **tenký ostrý obrys okolo celej hmoty**, vrátane vlákien a kariet; **nikdy čiara vnútri**. Goo, hladina a karty sú jedna hmota (§7) |
| Kurzor | **súčasť Goo**: kvapka, ktorá sa pri rýchlom pohybe splošťuje a pri spomalení zavlní (§8) |
| Farba kurzora | **adaptívna podľa pozadia**; voľba v Nastaveniach: adaptívny · farba goo s podsvietením alebo vrhaným tieňom · vypnuté (klasický kurzor) (§8.3) |
| Lišta okien | predvolene **BarGoo**; voľby: BarGoo · DockShore · vypnutá (§11.2) |
| Reakcie na kurzor | **silnejšie** |
| Marea (k4ditano) | vzhľad **MareaGoo**, aby zapadla medzi kvapky (§11) |
| Dok pleamar-wm | **DockShore** (§11) |
| Karty a Shore | otváranie a zatváranie **živšie a plynulejšie** (§9) |
| Rozsah | **všetko naraz, zajtra**; hotová verzia, nie pokus |

---

## 2. Čo je na dnešnom engine zlé

| # | Nález | Kde |
|---|---|---|
| D1 | **Scéna nikdy neodpočíva.** `time` je v 30 výrazoch `drops.plm`, 12 v `shapes.plm`, 19 v `rows.plm`; kým scéna `time` menuje, kreslí 60 snímok/s. Odtiaľ 17–44 % jadra v pokoji. | `drops.plm` r. 199–300 |
| D2 | **Jedno telo cez obrazovku s ~215 tvarmi**, kreslené dvakrát. V pleamare 0.7.10 prejde každý pixel všetkými tvarmi; neobsadené miesto stojí ako obsadené. | `body.plm`, `shapes.plm` |
| D3 | **Fyzika je na dvoch miestach.** Pád počíta scéna vzorcom, logika ten istý čas háda cez `after(sqrt(2h/g))`; `GRAVITY` je zapísaná dvakrát. | `drops.plm` r. 259–275, `engine.luau` r. 660–695 |
| D4 | **Kvapky na seba nepôsobia.** Neprekrývanie robí logika prepísaním domova. Kvapka nemá hmotnosť ani rýchlosť. | `engine.luau` r. 135–224 |
| D5 | **Hladina sú štyri pripravené animácie.** Vlna sa neodráža, nestretne s inou, dosky (Shore) nevidí. | `drops.plm` r. 182–253 |
| D6 | **Karta má jednu pružinu s odskokom na oba smery.** Zatváranie vyskočí kapsulou; zakrýva to `card_alive` a časovač. | `card.plm` r. 133, `card.luau` r. 96 |
| D7 | **Suseda pozná kvapka z kópie jeho domova,** nie z miesta, kde práve je. Spoj sa pri pohybe odtrhne od tvaru. | `drops.plm` r. 356–368 |
| D8 | **Karta je iné telo než kvapky.** V rohu, kde sa stretnú, je obrys gule a šev (6.28). | `card.plm` r. 185–205 |
| D9 | **Okná žijú v inej scéne s inými číslami.** Dve sady skla (6.29), žiadne kývanie (1D.27). | `wm/session.plm` |
| D10 | **Stupeň výkonu sa rieši po kúskoch v logike.** Scéna nemá jedno číslo, podľa ktorého ubrať. | `engine.luau` r. 1003 |

---

## 3. Krok 0 — pleamar 0.7.27 a pleamar-wm 0.6.15

Dnes je `patches/build-pleamar.sh` na 0.7.10 a 0.6.9. Jazyk sa medzitým nezmenil; zmenil sa výkon.

| Verzia | Čo prináša |
|---|---|
| **0.7.18** | Veľké telo sa delí na dlaždice 64 px, každá meria iba tvary, ktoré do nej siahajú; neviditeľné telo sa nekreslí. Autor nameral 17,4 → 4,4 ms na snímku. Priamo D2 — a podmienka pre jednu hmotu z §7. |
| 0.7.11–0.7.14 | Živý lom skla odpočíva nad stojacim pozadím; snímka pozadia ide rovno na kartu. |
| 0.7.19 | Keď `rate:` stúpne, nečaká sa na starý dlhý krok (prebudenie bez oneskorenia). |
| **0.7.21** | Telo je vlastný úsek kresby a kopíruje sa zo snímky predtým. |
| 0.7.24 + wm 0.6.15 | Sklo Goo vidí okná pod sebou bez dier (6.29, 1D.42). |

Preniesť záplaty z `patches/` (sedem pre pleamar, štyri pre pleamar-wm), `--check` všetkých scén a zmerať
`goo.plm` s `PLEAMAR_TIMING=1` v pokoji, pri pohybe myšou a s otvorenou kartou. **Tieto tri čísla sú východisko.**

---

## 4. Architektúra: tri vrstvy

```
  Luau (goo/lib, goo/drops)      čo kvapka JE a ROBÍ: register, domovy, karty, kliky, ukladanie
        │  domov, veľkosť, povaha, príkazy (skoč, zachvej sa)          ▲ udalosti (dopadla, narazila, praskla)
        ▼                                                              │
  Rust  (crates/goo-phys)        kde hmota JE: polohy, rýchlosti, zrážky, let, hladina, spoje, kurzor
        │  fakty na snímku: g.x.k, g.y.k, g.r.k, g.st.k, g.rot.k, h.i, cur.*, joint.*
        ▼
  Scéna (goo/parts)              ako hmota VYZERÁ: jedno telo, obrys, sklo, tváre, karty, zóny myši
```

### 4.1 Prečo Rust a ako sa pripojí

Jazyk scény nemá hmotnosť (tuhosť pružiny je číslo, nie výraz), nemá zrážky ani cykly. Všetko to ide obísť, ale za
cenu `gen.py`, výrazov po 32 a správania, ktoré sa nedá otestovať. V Ruste je to obyčajný kód s `cargo test`.

Pleamar je **knižnica** (`pleamar::run`, `provide_platform`, `provide_windows`); pleamar-wm je program, ktorý ju
volá **[zdroj]**. Rovnako vznikne program LatteOS:

| Kus | Čo je |
|---|---|
| `crates/goo-phys` | čistá knižnica bez závislostí: svet, krok, udalosti. Nevie nič o pleamare ani o Waylande. Testy v `cargo test`. |
| `crates/latte-goo` | program: `pleamar` ako závislosť + `goo-phys`. Spúšťa `goo.plm` namiesto holého `pleamar --scene`. |
| `patches/pleamar-step-hook.patch` | **nová malá záplata:** `pleamar::provide_step(f)`. Render zavolá `f(dt, &mut zápis_faktov)` raz za snímku pred vyhodnotením scény a z návratovej hodnoty vie, či svet ešte žije (inak scéna zaspí). |

Fakty sa zapisujú priamo v procese (render ich už dnes berie ako `ToRender::Fact(meno, f32)` **[zdroj]**), bez
soketu a bez textu. **Záplatu ponúknuť autorovi pleamaru** — je to to isté, čo `provide_windows` robí pre okná.
Vstupy z logiky (domovy, príkazy) idú tými istými faktami opačným smerom: jadro si ich prečíta v háku.

**[overiť] prvé, čo treba zajtra urobiť:** napísať záplatu a prázdny `latte-goo`, ktorý každú snímku zapíše jeden
fakt, a pozrieť, či sa pohyb kreslí plynule a či scéna zaspí, keď hák vráti „nežije“. Na tom stojí celý návrh.
Ak hák nepôjde, náhradná cesta je vlastnosť scény za každým faktom s krátkou pružinou; to je horšie (o snímku
neskôr) a rozhodne sa až potom.

### 4.2 Zmluva medzi jadrom a scénou

Jadro píše, scéna iba číta. Jadro nekreslí a nepozná farby; scéna nepočíta polohy.

| Fakt | Význam |
|---|---|
| `g.x.k`, `g.y.k` | stred kvapky k, px |
| `g.r.k` | polomer, ako sa má nakresliť (0: miesto je prázdne) |
| `g.st.k`, `g.rot.k` | natiahnutie v smere pohybu (0…0,4) a jeho uhol; plocha sa zachováva |
| `g.sq.k` | sploštenie kolmo na okraj (dopad, stlačenie, sadnutie) |
| `g.tip.k`, `g.tipa.k` | hrot ku kurzoru: dĺžka a uhol (§6.3) |
| `h.i` | výška hladiny v stĺpci i, px |
| `j.on.k`, `j.w.k`, `j.ax/ay/bx/by.k` | vlákno od kvapky k k susedovi: či je, hrúbka, konce |
| `cur.x`, `cur.y`, `cur.st`, `cur.rot`, `cur.wob`, `cur.tailx`, `cur.taily` | kurzor (§8) |
| `stir` | 0…1: koľko energie svet má; z neho stav scény (§14) |

Udalosti z jadra do logiky: `goo_landed(k)`, `goo_bumped(k·64 + j)`, `goo_parted(k)`, `goo_joined(k)`,
`goo_torn(k)`. Z `engine.luau` zmiznú `GRAVITY`, všetky `after(math.sqrt(…))`, `apart()` za pohybu
a publikovanie `left_*`/`right_*`. Rozhranie kvapiek (`drops/*.luau`, `Drop:…`, `E.define`, `kvapky.json`) sa
**nemení**.

### 4.3 Čo ostáva v scéne

Zóny a pravidlá myši, vznášanie nad kvapkou (`hit.hover`), tváre, karty, sklo, obrys. Scéna má vlastné hodiny
`life` (`spin life by awake` — stoja, keď `stir` je 0 **[zdroj]**) pre drobný šum v kresbe; `time` nesmie ostať
nikde v `goo/` ani `wm/` a `tests/check.sh` to stráži. `gen.py` ostáva iba na tvary tela (`body` nepozná `repeat`).

---

## 5. Jadro `goo-phys`

### 5.1 Svet a krok

```rust
pub struct World { pub drops: Vec<Drop>, pub surface: Surface, pub cursor: Cursor, pub joints: Vec<Joint>,
                   pub walls: Vec<Wall>, pub cfg: Config, events: Vec<Event> }
impl World {
    /// Advances by `dt` in fixed steps of 1/240 s (at most 8 a frame). Returns the energy left: 0 is rest.
    pub fn step(&mut self, dt: f32, input: &Input) -> f32;
    pub fn drain_events(&mut self) -> impl Iterator<Item = Event>;
}
```

- **Pevný krok 1/240 s**, polo-implicitný Euler (najprv rýchlosť, potom poloha). Výsledok nezávisí od počtu snímok.
- **Pokoj:** keď je súčet kinetickej energie a vzdialeností od cieľov pod prahom pol sekundy, `step` vráti 0,
  všetko sa dosadí presne do cieľa a hák povie renderu „nežije“. Prebudí ho vstup (myš pri okraji, príkaz, okno).
- **Všetky čísla sveta** (`gravity`, `drag`, `restitution`, tuhosti) sú v `Config` s predvolenými hodnotami
  a dajú sa prepísať z `~/.config/latteos/goo-phys.json` — ladenie bez prekladu.
- **Stupeň 0** (softvér, SAFE): `step` nepočíta nič a píše domovy. Scéna je statická.

### 5.2 Kvapka

Stav: poloha, rýchlosť, polomer, hmotnosť `m = (r/26)²` (× 2,5 pre povahu „heavy“), domov (okraj, miesto, výška),
režim: **sedí** · **drží ju ruka** · **letí**. V režime „sedí“ na ňu pôsobia sily:

| Sila | Vzorec | Poznámka |
|---|---|---|
| domov | `−k·(p − domov) − c·v`, pozdĺž okraja mäkšie (`k = 150`), kolmo tuhšie s prekmitom (`k = 190`, `c = 9`) | dnešné `glide` a `drip` |
| kurzor | §5.3 | iba priťahuje |
| sused | odpudzovanie pri prekryve, §5.4 | |
| hladina | zdvih o výšku stĺpca pod ňou, delený `√m` | veľká sa na vlne sotva pohne |
| vietor | `gale · sin(…)` delené `√m` | iba keď logika povie, že fúka |
| dych, drift | pomalý šum na cieli, nie na sile | stojí s hodinami |

Sadnutie v pokoji, zdvih pri kurzore a „stále“ kvapky (kapsuly) ostávajú ako dnes; sú to posuny cieľa.

### 5.3 Kurzor: silnejšie reakcie

Dnešné čísla (príťažlivosť 0,3, dosah 220 px, zdvih ¾ polomeru) sú opatrné. Nové predvolené hodnoty a tri nové
správania; všetko v `Config`, aby sa dali doladiť pohľadom:

| | Dnes | Nové |
|---|---|---|
| dosah | 220 px | 300 px |
| príťažlivosť | 0,30 | 0,55 |
| zdvih | 0,75 r | 1,1 r |
| náklon | 0,8 r | 1,2 r |
| sused sa pridá | 30 % | 45 % |

1. **Hrot.** Kvapka sa ku kurzoru nenakláňa celá: vytiahne k nemu špičku (`g.tip`), ako kvapka, ktorej sa niečo
   dotýka. Dĺžka najviac 0,6 r; zásada 20 (odtrhnutie do 1,6 r) platí.
2. **Brázda.** Kurzor, ktorý preletí popri kvapkách rýchlo, ich strhne za sebou: štuchnutie v smere pohybu kurzora
   úmerné jeho rýchlosti a blízkosti, delené hmotnosťou. Dokývu sa samy. Pri hladine štuchne aj stĺpce pod sebou.
3. **Dotyk.** Keď je kurzor-kvapka (§8) bližšie než súčet polomerov, vznikne medzi nimi vlákno ako medzi dvoma
   kvapkami: natiahne sa, stenčí a praskne. Stlačenie tlačidla nad kvapkou ju sploští od miesta dotyku.

Kurzor ďalej **iba priťahuje**; brázda je ťah za ním, nie odstrčenie.

### 5.4 Zrážky a neprekrývanie

Kvapky na tom istom okraji sú kruhy (kapsuly úsečky s polomerom). Pri prekryve sa obe posunú od seba v pomere
hmotností a vymenia si časť rýchlosti (`restitution` 0,25; povaha „playful“ 0,6). Náraz nad 120 px/s vyšle
`goo_bumped` a obe sa sploštia v smere nárazu. **Trvalé** rozloženie (kto má kde domov) ostáva logike a spustí sa
po `goo_landed`; za pohybu sa o prekrytie stará jadro. Zásada 22 platí v oboch.

Steny: okraje obrazovky, dosky Shore (TrayShore, LensShore, DockShore) a — v druhom kroku — titulky okien, pred
ktorými dnes kvapka uskakuje (`E.avoid`).

### 5.5 Let: hod, pád, skok

Pustená kvapka si nesie rýchlosť ruky (obmedzenú na 1600 px/s). V režime „letí“ na ňu pôsobí gravitácia
800 px/s² a odpor vzduchu (`drag` 1,8); domov ani kurzor nie. Let končí **prvým dotykom okraja**: dole dopadne do
hladiny, pri boku alebo hore sa prilepí. Od dosky a od inej kvapky sa odrazí. Pri dopade jadro:

1. štuchne hladinu silou `m · rýchlosť` (§5.6),
2. sploští kvapku úmerne rýchlosti,
3. vyšle `goo_landed(k)`; logika určí domov a jadro kvapku prepne na „sedí“ v tom istom kroku, bez skoku.

`Drop:jump(at, speed)` je ten istý let s danou počiatočnou rýchlosťou; hra pri nečinnosti (stupeň 3) ostáva.
Kvapka, ktorá `returns` (BarGoo), sa vráti pružinou. Zásada „pád, nie výstrel“: strop rýchlosti a odpor.

### 5.6 Hladina — iba dole

Rad stĺpcov pozdĺž spodného okraja (48 pri stupni 2, 64 pri stupni 3, 24 pri stupni 1). Každý stĺpec má výšku
a rýchlosť; ťahá ho späť k nule a k priemeru susedov:

```rust
// per column, per fixed step
let pull = cfg.tension * (h[i - 1] + h[i + 1] - 2.0 * h[i]) - cfg.restore * h[i] - cfg.damp * v[i];
v[i] += pull * dt;  h[i] += v[i] * dt;
```

Tlmená vlnová rovnica: vlna sa šíri (≈ 430 px/s ako dnes), **odráža od okrajov obrazovky a od dosiek** (stĺpce pod
doskou stoja), dve vlny sa preložia a všetko samo doznie. To je 6.27. Dve šíriace kolá na krok (rozostrenie
k susedom) držia hladinu hladkú. Čo hladinu rozvlní: dopad kvapky, brázda kurzora, doska pri vysunutí a zasunutí
(štuchne stĺpce pri svojich koncoch), okno, ktoré sa rýchlo priblíži k spodnému okraju (§10.2), vietor.
**Dážď na hladine nie je** (§12).

Kresba: úsečky medzi bodmi stĺpcov s `blend`, v tej istej hmote ako kvapky (§7). Nahrádza 12 elíps vĺn a 8 elíps
„swell“. Pri stupni 3 svetlo na hrebeni (vzor `shaders/crest.wgsl`), iba kým `stir > 0`.

### 5.7 Spoje

Vlákno medzi susedmi má stav. Vznikne pod 0,9 súčtu polomerov, tenčí sa natiahnutím (`w = w₀ / (1 + 1,6·n)`),
**praskne** nad 2,3 súčtu: obe kvapky dostanú spätný ráz, jadro vyšle `goo_parted`. Konce vedú na **živé** polohy,
takže spoj sa od tvaru neodtrhne (D7). Krk ťahanej kvapky a ucho karty sú spoje toho istého druhu. Voda pri okraji
medzi susedmi je hladina sama (§5.6), nie zvláštny tvar.

### 5.8 Testy jadra (`cargo test -p goo-phys`)

Vlna sa odrazí od steny a doznie · dve kvapky sa po 2 s neprekrývajú · pustená z pokoja padá rovno, hodená letí
oblúkom a končí na okraji · svet dosiahne pokoj (energia 0) do 3 s od posledného vstupu · výsledok pri 24, 60
a 144 snímkach sa líši o menej než 1 px · stupeň 0 nepohne ničím.

---

## 6. Čo z `drops.plm` ostane

| Ostáva | Mení sa | Odchádza |
|---|---|---|
| zóna a pravidlá myši, kapsula, jadro, guľky, tváre | poloha a tvar sa čítajú z `g.*`; `time` → `life` | všetky pružiny polohy, `ripple`, `wave`, `swell`, `falls`/`fly`/`cross`, `going.*`, polia `left_*`/`right_*`, `fall*`/`jump*`, `picks.plm` |

Ťahanie: scéna ďalej hlási `drag.dx/dy`; jadro ich berie ako polohu ruky. `goo_letgo` nesie iba číslo miesta —
kde a ako rýchlo, vie jadro.

---

## 7. Kreslenie: jedna hmota, jeden obrys

**Pravidlo (používateľ 11. 11.):** okolo hmoty je tenký, ostrý, nerozmazaný obrys, ktorý sleduje okraj **celého**
tvaru — kvapiek, vlákien, hladiny aj karty. Vnútri hmoty nie je nikdy čiara, ktorá by niečo oddeľovala. Goo,
hladina a karty tak stále tvoria jeden kus.

Z toho plynie:

1. **Všetko je v jednom `body`:** kvapky, stopky, vlákna, hladina, ucho, **rám karty**, dosky Shore a kurzor.
   Obrys je `border: 1.25, farba` tohto tela **[zdroj: `body` má `border: width, #color`]**; sleduje spojenú
   siluetu, takže kde sa dva tvary zlejú, čiara medzi nimi nie je.
2. **Karta už nie je vlastné telo.** Dnešný rám karty v `card.plm` sa presunie do hmoty. Ucho prestane byť
   kópia kvapky v cudzom tele — je to tá istá kvapka. Tým zaniká šev z 6.28 aj dvojitý obrys.
3. **Farba vnútri sa mení plynule, nie hranou.** Karta je pri uchu káva a ďalej prechádza do farby panela
   (schválené 5. 11.): to robí `gradient` tela a nad ním výplň s mäkkým okrajom (skupina s `mask`), ktorá je celá
   vnútri siluety. Žiadny tvar s vlastným `rim`, tieňom alebo okrajom vnútri hmoty.
4. **Tieň je jeden,** pod celou hmotou, tesný (dnešné `shadow: 0, 2, 2, 28%` pri kvapkách; karta si pýta väčší —
   tieň rastie s `card.p`, ale je to stále tieň toho istého tela).
5. **Sklo je jedno.** Hmota má jeden materiál; karta, ktorá chce byť sklenená tabuľa nad vlnou (`card_pane`),
   to dostane prekrytím vnútri siluety, nie vlastným telom.
6. **Obsah** (texty, ikony, riadky, tváre) sa kreslí nad hmotou a nemá obrys.

**[overiť]** dve veci hneď po kroku 0: (a) či obrys tela ostane ostrý pri `glass` a pri zlievaní (`blend`),
(b) koľko stojí hmota s kartou cez pol obrazovky po dlaždicovaní z 0.7.18. Ak (b) nevyjde, náhrada: výplne ako
dnes vo viacerých telách **bez** obrysu a nad nimi jedno telo iba s obrysom zo všetkých tvarov.

Druhý monitor (`side.plm`), zámok a prihlásenie kreslia tým istým pravidlom z tej istej knižnice `goo/phys/`
(`world.plm` konštanty a pružiny kresby, `mass.plm` komponent hmoty, `material.plm` sklo).

---

## 8. GooCursor — kurzor ako kvapka

Predloha: priložené kurzory (šípka a ruka z farby, ktorá steká a odkvapkáva). Kurzor je kvapka kávy s ostrým
hrotom, ktorá má hmotnosť: pri rýchlom pohybe sa sploští a natiahne dozadu, pri zabrzdení sa hmota presunie
dopredu a zavlní, v pokoji dýcha.

### 8.1 Model (v `goo-phys`)

Dve telesá spojené pružinou: **hrot** je presne tam, kde je ukazovateľ (žiadna pružina, žiadne oneskorenie),
**bruško** za ním s hmotnosťou. Z ich vzájomnej polohy a rýchlosti:

| Fakt | Z čoho | Čo kreslí |
|---|---|---|
| `cur.st`, `cur.rot` | rýchlosť hrotu | natiahnutie a smer; pri 2000 px/s je kurzor o 35 % dlhší a užší |
| `cur.tailx/y` | poloha bruška voči hrotu | kam visí zadok kvapky |
| `cur.wob` | pružina za zrýchlením | zavlnenie pri zabrzdení: dva kmity a pokoj |
| kvapôčky | rýchla zmena smeru | odtrhne sa 1–3 kvapôčky (častice), ktoré spadnú do hladiny |

Tvary podľa toho, čo ukazovateľ robí: **šípka** (kvapka s hrotom vľavo hore), **ruka** nad klikateľným (hrot sa
zaguľatí do prsta), **písanie** (zvislá tenká kvapka), **ťahanie** (kvapka sa zovrie). Prechod medzi nimi je
pretečenie, nie výmena obrázka. Farba: káva používateľa s jedným svetlým odleskom; obrys podľa §7.

### 8.2 Kde sa kreslí — a riziko

Systémový kurzor kreslí pleamar-wm na kurzorovej rovine grafickej karty z témy `XCURSOR_THEME` **[zdroj]**; má
nulové oneskorenie. Kurzor kreslený scénou príde o snímku neskôr. Preto dve vrstvy:

1. **Téma kurzora „LatteOS Goo“** (`assets/cursors/`, bežná téma xcursor so šípkou, rukou a ostatnými tvarmi
   v štýle predlohy). Funguje všade — v hrách, nad oknom na celú obrazovku, v SAFE — a je to istý výsledok.
2. **Živý kurzor** v hmote Goo (stupeň ≥ 2): scéna ho kreslí ako kvapku z `cur.*` a systémový sa skryje. Záplata
   `patches/pleamar-wm-cursor-hide.patch`: príkaz `pleamar-wm cursor hide|show` (vnútri už `layers::hide_cursor`
   je **[zdroj]**). Keď Goo nekreslí (celá obrazovka, zámok, pád scény, stupeň < 2), systémový sa vráti — strážca
   v `latte-session` ho ukáže vždy, keď `goo_alive` neodpovie.

**Toto je najrizikovejší kus návrhu.** Ak bude živý kurzor cítiť ako oneskorený (overiť rukou na 60 aj 144 Hz),
ostane téma z bodu 1 a deformáciu dostane iba **stopa** za systémovým kurzorom: bruško a kvapôčky kreslené scénou
pod pevným hrotom z témy. Voľby v Nastaveniach › Kurzor sú v §8.3; živá kvapka je k nim samostatný
prepínač.

### 8.3 Farba a Nastavenia › Kurzor (používateľ 11. 11.)

| Voľba | Čo robí |
|---|---|
| **Adaptívny** (predvolené) | kurzor si farbu volí podľa toho, čo je pod ním: na tmavom pozadí svetlý (krémová káva), na svetlom tmavý (espresso), s plynulým prechodom. Obrys je vždy opačný než výplň, takže ho vidno na čomkoľvek |
| **Farba goo** | káva používateľa ako kvapky. K nej jedno z dvoch: **podsvietenie** (svetlý lem okolo, `glow`) alebo **vrhaný tieň** (tmavý, posunutý) — čo ho oddelí od pozadia |
| **Vypnuté** | klasický systémový kurzor, Goo nič nekreslí a nič neskrýva |

Ako kurzor zistí pozadie: scéna už vie čítať, čo je za ňou (`behind(s, at)` v shaderi, tá istá snímka pozadia ako
pre sklo **[zdroj]**). Kurzor je shader nad kvapkou, ktorý vezme jas pozadia pod hrotom a zmieša podľa neho dve
farby; jas ide cez pomalú pružinu (120 ms), aby kurzor nad textom neblikal. **[overiť]** cenu: snímka pozadia
sa berie najviac raz za 50 ms a iba malý výrez okolo kurzora; kde sa pozadie snímať nedá (stupeň < 2, statická
téma xcursor), adaptívny kurzor je dvojfarebný natrvalo — svetlá výplň s tmavým obrysom, čo je čitateľné všade.
Zápis do `~/.config/latteos/cursor.json` (`mode`: `adaptive` | `goo` | `off`; `lift`: `glow` | `shadow`).

---

## 9. Karty a Shore: živšie otváranie a zatváranie

### 9.1 Dve pružiny, dva smery

```
spring land = 630, 14          // opening: a quarter of a second, two bounces one can see
spring shut = 900, 60          // closing: critically damped, about 140 ms, nothing comes back
on change card_open while card_open     { card.p: 1 ~land }
on change card_open while not card_open { card.p: 0 ~shut }
```

`card_alive` a časovač 120 ms v `card.luau` sa zrušia.

### 9.2 Otvorenie v troch fázach

| Fáza | `card.p` | Čo sa deje |
|---|---|---|
| **1 · nádych** | 0 – 0,15 | kvapka sa pred skokom prikrčí (sploštenie 12 %), hladina pod ňou klesne |
| **2 · výron** | 0,1 – 0,6 | z kvapky vyrazí guľatý výbežok užší než ona; krk je zvon `4·t·(1−t)`; kvapka vystúpi od okraja |
| **3 · rozliatie** | 0,4 – 1 + prestrel | výbežok sa rozleje do šírky, rohy sa narovnajú (58 → 18), výška dobehne s odskokom; pri prestrele sa vydúva aj do šírky |

Počas fázy 3 beží po obryse karty **vlna** (dva hrebene od ucha po oboch stranách, shader podľa `cardrip`
z Vitreusu) a hladina v karte (`velvet`, módy `m1`, `m3`) sa raz zakýve. Riadky prichádzajú po sebe až od
`card.p > 0,7`. Kvapka-ucho po celý čas žije: dýcha, reaguje na kurzor, rastie kolieskom — je to tá istá hmota.

### 9.3 Zatvorenie

Nie prehraté otvorenie odzadu: obsah zhasne prvý (60 ms), karta sa **nasaje** do ucha (šírka sa zúži rýchlejšie
než výška, takže tečie dnu ako do lievika), ucho sa na okamih nafúkne o 10 %, dosadne k okraju a pošle do hladiny
malú vlnu. Bez odskoku späť.

### 9.4 Shore (TrayShore, LensShore, DockShore)

Doska je tvrdá, ale stojí vo vode. Panel dosky sa dnes vysunie ako plech. Nové:

- **Vysunutie:** panel vyjde s prekmitom 4 % (pružina `land`), hladina po oboch koncoch dosky sa nadvihne a vlna
  odbehne; kvapky nablízku sa zhupnú. Obsah po sebe ako v karte.
- **Zasunutie:** kriticky tlmené (`shut`), hladina sa na okamih prepadne tam, kam panel zapadol.
- **LensShore** už je jedno telo so svojím panelom; teraz je to tá istá hmota ako všetko ostatné (§7), s tým
  istým obrysom.
- Doska je pre hladinu stena a pre kvapky prekážka (§5.4, §5.6).

### 9.5 Bublina okna

`bubble.plm` prejde z `time` na `life`. Kde bublina dosadne na okno a kde okno praskne, štuchne hladinu, ak je to
do 200 px nad ňou.

---

## 10. Okná v pleamar-wm

Scéna okien je iný proces, hmota sa teda nezdieľa. Zdieľa sa knižnica `goo/phys/` a pár faktov cez `latte-say`.

### 10.1 Kývanie — celý obsah okna (1D.27)

Okno je v `wm/session.plm` už dnes vo vlastnej skupine so shaderom (`tide`, `rain`, `snow`). Kývanie je štvrtý:
**štyri rohy na pružinách**, každý dobieha svoj cieľ, a shader medzi nimi obsah okna plynule ohne — klasický
wobble, pri ktorom roh ďaleko od ruky mešká najviac.

```
spring jelly = 240, 11                       // goo/phys/world.plm: two swings one can see, then still
repeat c in 0..4 {                           // 0 top left, 1 top right, 2 bottom left, 3 bottom right
    prop jx.$i.$c = 0 ~jelly
    prop jy.$i.$c = 0 ~jelly
    follow jx.$i.$c = x + w * (c == 1 or c == 3)
    follow jy.$i.$c = y + h * (c >= 2)
}
// how far each corner lags behind where it should be, eight numbers: exactly a shader's `values`
group {
    shader: jelly, lag.x.0, lag.y.0, lag.x.1, lag.y.1, lag.x.2, lag.y.2, lag.x.3, lag.y.3 while bent > 0.3
    …title bar, window…
}
```

```wgsl
// goo/phys/shaders/jelly.wgsl — the window as a sheet held by four corners that each lag on a spring
fn shade(s: Shader) -> vec4<f32> {
    let top = mix(s.a.xy, s.a.zw, s.uv.x);
    let bottom = mix(s.b.xy, s.b.zw, s.uv.x);
    return inside(s, s.pos + mix(top, bottom, s.uv.y));
}
```

- Roh pri ruke má tuhšiu pružinu (`~80ms`), takže okno drží pod kurzorom a zvyšok za ním vlaje.
- **`while`** je kľúčové: v pokoji skupina nemá vlastný prechod a okno sa kreslí ako dnes **[zdroj]**.
- Pri pustení dostanú rohy štuchnutie úmerné rýchlosti ruky; okno sa raz prehne a ustáli. Zmena veľkosti kýve
  protiľahlé rohy.
- V daždi a snehu má okno už svoj shader a dva efekty skupiny sa nesmú vnoriť: tam sa kývanie vynechá.
- Stupeň ≥ 2, nikdy okno na celú obrazovku.
- **[overiť]** `inside` mimo skupiny je priehľadné: skupine dať rezervu 90 px okolo, inak sa ohnutý roh oreže.
  Predloha správania: wobble z Hyprlandu 0.57; rediwm (Zig, wlroots) na stránke projektu deformáciu neopisuje,
  pozrieť jeho video a `src/` pri ladení dojmu.

### 10.2 Okno a hmota

- **Minimalizácia do BarGoo:** scéna okien okno zmenší do kvapky a povie Goo, kde a ako rýchlo. Jadro z toho
  urobí **let podľa §5.5**: kvapka okna dopadne, šplechne a splynie s BarGoo. Blok `going.*` zaniká.
- **Okno pri hladine:** keď spodná hrana okna prejde pásom 54 px nad okrajom rýchlejšie než 300 px/s, scéna okien
  pošle Goo jedno štuchnutie hladiny na šírku okna.
- **Kvapky a titulok okna:** okno je pre jadro stena (druhý krok, §5.4).
- **Pružiny:** dosadnutie, otvorenie a zatvorenie okna berú mená z `goo/phys/world.plm`. Scénu upstreamu meniť iba
  v blokoch `// LatteOS:`.

---

## 11. MareaGoo a DockShore

### 11.1 MareaGoo (6M, 1D.26)

Marea je vlastná scéna pleamaru (`marea-plm`, BSD-3). Nestane sa súčasťou hmoty (iný proces), ale dostane **skin**,
v ktorom vyzerá ako ďalšia kvapka:

- farby z kávy používateľa (`water`, `milk` → rovnaký `coffee` ako v `drops.plm`) a z `system/cups.json`,
- kreslenie podľa §7: jedno telo, ten istý obrys, ten istý tieň, to isté sklo (`goo/phys/material.plm`),
- pružiny z `goo/phys/world.plm`, aby dosadala a pružila ako kvapky,
- žiadna tvár ani oči, ak ich skin Marey má (zásada 7) **[overiť v `wardrobe/`]**,
- Goo o nej vie ako o stene/susedovi: Marea hlási svoj obdĺžnik (`latte-say`), kvapky jej uhnú a hladina sa od nej
  odrazí, ak sedí na spodnom okraji.

Skin je priečinok v `goo/marea/`; pôvodná Marea sa nemení, iba sa spúšťa s ním.

### 11.2 DockShore (1D.25)

Dok pleamar-wm (autor ho volá *shore*) kreslí `wm/session.plm` (`dk.*`). Ostáva tam — potrebuje okná —, ale:

- vyzerá ako doska LatteOS: farba `shore.goo`, obrys a zaoblenie ako TrayShore a LensShore,
- otvára a zatvára sa podľa §9.4,
- ikony programov sa správajú ako ikry BarGoo: pod kurzorom sa nadvihnú a sused sa pridá (čísla z §5.3),
- Goo dostane jeho rozsah ako ďalšiu stenu (`shore.2.a`, `shore.2.b`): hladina sa odráža, kvapky sa mu vyhnú,
- meno v Nastaveniach: **DockShore**. Nastavenia › Okná › Lišta okien: **BarGoo** (predvolené) · **DockShore** ·
  **vypnutá**. Naraz beží najviac jedna; vypnutá necháva okná iba na prepínanie klávesmi a prehľad.

---

## 12. Počasie pri nečinnosti

Dážď a sneh na hladine sú zrušené (používateľ 11. 11.): z `body.plm` preč tri `particles`, z `drops.plm` fakty
`rain`, `snow`, z `engine.luau` `weather_on/off`. Stupeň nečinnosti 2 namiesto toho **zapne počasie pleamar-wm**:
dážď alebo sneh na oknách (`rain_level`, shadery `rain.wgsl` a `snow.wgsl` v `wm/session.plm`), silou podľa
skutočného počasia z Open-Meteo, ako „intenzívne počasie“ pri nečinnosti. Prebudenie ho vypne. Vietor ostáva
v Goo (vlní hladinu a kýve kvapky). Podmienky „kedy nie“ z §3.1 pravidiel platia.

---

## 13. Sklo a materiál (6.29)

Jedna sada faktov pre Goo, karty, okná, MareaGoo aj DockShore, jeden zdroj v Nastaveniach › Okná › Sklo:
`glass.amount`, `glass.frost` (číslo, nie `auto`), `glass.smoke`, `glass.milk`, `glass.bend` (→ `refraction`,
a `dome` pri stupni 3), `glass.rainbow` (→ `dispersion`), `glass.ripple`. Komponent v `goo/phys/material.plm`
ich nastaví všade rovnako; Goo ich pri zmene pošle scéne okien jedným `latte-say`.

Úspory lomu, ktoré dnes nie sú zapnuté **[zdroj]**:

```
lens every 50ms + 450ms * (1 - awake)
lens hold while card.p > 0.02 and card.p < 0.98
```

Pri stupni 1: `lens = image "~/.cache/latteos/wallpaper.png"` — sklo láme iba tapetu a nič nesníma.

---

## 14. Energia, stupne, rozpočet

| Stav | Kedy | Snímky |
|---|---|---|
| **čulý** | `stir > 0`: kurzor pri okraji, ťahanie, karta, let, vlny | 60 |
| **pokojný** | 4 s potom | 24, dych a drift na 35 % rýchlosti |
| **spiaci** | nečinnosť ≥ 1, úsporný profil, batéria pod 20 % | 8, iba kým dobieha vzdych |
| **skrytý** | celá obrazovka, zámok, stupeň 0 | 0 |

`surface { …; rate: 60, 24 while ambient, 8 while asleep }`. V spiacom stave sa raz za 3–8 s nadýchne jedna
náhodná kvapka; scéna sekundu kreslí a zaspí.

`fact tier` (z `LATTE_TIER`): 0 softvér/SAFE · 1 úsporný · 2 štandard · 3 plný.

| | 0 | 1 | 2 | 3 |
|---|---|---|---|---|
| fyzika jadra | vypnutá | áno | áno | áno |
| hladina | rovná | 24 stĺpcov | 48 | 64 + svetlo |
| sklo a lom | nie | bez lomu | áno | + `dome` |
| kývanie okien, živý kurzor | nie | nie | áno | áno |
| častice | nie | polovica | áno | áno |

Rozpočet na latte-lab (RX 640, 2560 × 1080, 12 kvapiek, 8 okien v BarGoo, 30 s na stav):

| Stav | Dnes | Cieľ |
|---|---|---|
| skrytý | nemerané | 0 snímok, pod 0,3 % jadra |
| spiaci | 17–44 % jadra | pod 1 % |
| pokojný | to isté | pod 4 % |
| čulý | 24 % pri 32 miestach | pod 12 %, snímka do 3 ms |
| otvorenie karty | nemerané | žiadna snímka nad 16,7 ms |
| krok jadra (32 kvapiek, 64 stĺpcov, 8 podkrokov) | — | pod 0,1 ms |

`PLEAMAR_TIMING=1` musí v spiacom stave vypísať prázdne `alive_by`.

---

## 15. Poradie práce — všetko v jednom behu

Rozhodnuté je urobiť všetko naraz. Aj tak ide o commity po sebe, z ktorých každý necháva plochu funkčnú; keď sa
niečo pokazí, je jasné kde. Pred začiatkom značka `v0.5-pred-gooengine2`.

| # | Krok | Hotovo, keď |
|---|---|---|
| 0 | pleamar 0.7.27, pleamar-wm 0.6.15, záplaty, východiskové meranie | tri čísla v `docs/OPTIMALIZACIA.md` |
| 1 | **hák a kostra:** `pleamar-step-hook.patch`, `crates/goo-phys` (prázdny svet), `crates/latte-goo`, relácia spúšťa `latte-goo` | jeden fakt z Rustu hýbe tvarom plynule; scéna zaspí, keď svet stojí |
| 2 | **jadro:** kvapky, kurzor (§5.2–5.3), zrážky, let, hladina, spoje, testy | `cargo test -p goo-phys` zelené |
| 3 | **scéna na jadre:** `drops.plm` číta `g.*`, `time` preč, `rate:` so stavmi, `tier`; z `engine.luau` preč časovače, `GRAVITY`, susedia | plocha sa správa ako predtým plus zrážky a hod; v spiacom stave 0 snímok |
| 4 | **jedna hmota a obrys** (§7): karta, Shore a hladina do tela kvapiek | žiadna čiara vnútri; šev ucha preč |
| 5 | **karty a Shore** (§9): pružiny, fázy, nasatie, vlna po obryse | zatvorenie bez vyskočenia |
| 6 | **kurzor** (§8): téma xcursor, potom živá kvapka a záplata na skrytie | téma funguje všade; živý kurzor za vypínačom |
| 7 | **okná** (§10): `jelly.wgsl`, minimalizácia ako let, šplech od okna, spoločné pružiny | okno sa kýve a v pokoji nestojí nič navyše |
| 8 | **MareaGoo, DockShore, počasie, sklo** (§11–13); `side.plm`, zámok a prihlásenie na tú istú knižnicu | jedny posuvníky skla; dosky sú steny |
| 9 | meranie proti rozpočtu, `FILES`, `TRETIE-STRANY.md` (shader z Vitreusu), `LATTEOS-GOO.md` §3, `PRAVIDLA.md`, `ROZHODNUTIA.md`, ROADMAP | — |

Po každom kroku: `tests/check.sh`, `pleamar --check` všetkých scén, `gen.py --check`, `cargo test`, snímky
`tests/screen.sh`.

**Otvorene o rozsahu:** je to prepis jadra plochy, nový program v Ruste, tri nové záplaty a zásah do scény okien.
Za jeden deň sa to dá napísať; overiť rukou na latte-lab (kurzor, kývanie, dojem z kvapiek) sa to za ten istý deň
celé nedá. Kroky 0–5 sú základ, bez ktorého plocha nefunguje; 6–8 sa dajú zapnúť vypínačom neskôr bez toho, aby
niečo chýbalo. Ak čas nevyjde, zastaviť po 5 a zvyšok dokončiť ďalší deň — nie skracovať overenie.

---

## 16. Riziká

| Riziko | Čo s ním |
|---|---|
| Hák do renderu nejde tak jednoducho, alebo fakty z neho kreslia o snímku neskôr | Overuje krok 1, pred všetkým ostatným. Náhrada v §4.1. |
| Autor pleamaru vydáva denne; štvrtá záplata do `render.rs` sa bude rozchádzať | Záplata do 50 riadkov na jednom mieste; hneď ju ponúknuť autorovi. |
| Jedna hmota s kartou je drahá alebo obrys pri skle nie je ostrý | Overiť po kroku 0; náhrada v §7. |
| Živý kurzor mešká za rukou | Téma xcursor je základ a funguje vždy; živá kvapka je voliteľná (§8.2). |
| Pád `latte-goo` nechá skrytý systémový kurzor | Strážca v `latte-session` ho ukáže, keď `goo_alive` neodpovie. |
| Kývanie oreže rohy alebo rozmaže text | Rezerva okolo skupiny, ohyb najviac 90 px. Ak text trpí: kratší dokmit (`jelly = 320, 16`). |
| Silnejšie reakcie na kurzor rušia pri práci | Všetky čísla v `goo-phys.json`; posuvník „Živosť“ v Nastaveniach › Kvapky násobí dosah a príťažlivosť. |
| Scéna okien sa po zásahoch ťažko zlučuje s upstreamom | Zásahy iba v blokoch `// LatteOS:`; shader a pružiny v knižnici. |

---

## 17. Čo ešte treba od používateľa

Farba kurzora a lišta okien sú rozhodnuté (§1). Ostáva: po kroku 3 a po kroku 6 pozrieť plochu rukou — dojem zo
silnejších reakcií a z kurzora sa nedá zmerať.
