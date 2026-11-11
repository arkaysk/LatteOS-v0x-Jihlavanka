# GooEngine 2 — „Živá hladina“

Návrh a pokyny na kódovanie · 11. 11. 2026 · vetva `v0.5-pleamarwm-jihlavanka` · ROADMAP 6.09, 6.21, 6.27–6.30, 1D.27

Tento dokument je zadanie pre reláciu, ktorá bude GooEngine prepisovať. Opisuje, čo je na dnešnom engine zlé,
čím sa to nahradí a v akom poradí. Vzhľad a zásady Goo (`LATTEOS-GOO.md` §2–3) sa nemenia: kvapky sú káva, kurzor
iba priťahuje, karta rastie z ucha, okraj obrazovky je hladina. Mení sa to, **z čoho ten pohyb vzniká**.

**Ako bol návrh overený.** Prečítaný je celý pohybový kód enginu (`goo/parts/drops.plm`, `body.plm`, `shapes.plm`,
`card.plm`, `bubble.plm`, `rows.plm`, `goo/gen.py`, `goo/lib/engine.luau`, `goo/lib/card.luau`), scéna okien
(`system/pleamarwm/wm/session.plm`), referencia jazyka pleamaru a zdrojový kód pleamaru 0.7.10 aj 0.7.27
a pleamar-wm 0.6.9 aj 0.6.15. **Pleamar sa v tejto relácii nepodarilo spustiť**, takže ukážky kódu nižšie sú náčrty:
každú treba prejsť cez `pleamar --check` a zmerať na latte-lab. Čo stojí na správaní prečítanom priamo v zdroji
pleamaru, je označené **[zdroj]**; čo je odhad, je označené **[overiť]**.

---

## 1. Čo je na dnešnom engine zlé

| # | Nález | Kde | Dôsledok |
|---|---|---|---|
| D1 | **Scéna nikdy neodpočíva.** `time` je v 30 výrazoch `drops.plm`, 12 v `shapes.plm`, 19 v `rows.plm`. Podľa referencie: kým scéna menuje `time`, „never rests“. | `drops.plm` r. 199–200, 247–300, 358–364 | Kreslí sa 60 snímok/s, aj keď sa nikto nedotýka myši. Odtiaľ 17–44 % jadra v pokoji (merania 6. 10. a 12. 10.). |
| D2 | **Jedno telo cez celú obrazovku s ~215 tvarmi**, nakreslené dvakrát (sklo + káva v ňom) a tretí raz po kúskoch (jadrá). V pleamare 0.7.10 prejde každý pixel tela všetkými tvarmi. | `body.plm`, `shapes.plm` | Cena na grafickej karte rastie s počtom miest, nie s počtom kvapiek. Neobsadené miesto stojí toľko ako obsadené. |
| D3 | **Fyzika je rozdelená medzi scénu a logiku a obe hádajú to isté.** Pád je vzorec ½·g·t² v scéne, logika si ten istý čas počíta cez `after(sqrt(2·h/g))` a `GRAVITY` je zapísaná na dvoch miestach. | `drops.plm` r. 259–275, `engine.luau` r. 660–695 | Keď sa jedno zmení, druhé sa rozíde: sploštenie a vlna prídu skôr alebo neskôr než dopad. |
| D4 | **Kvapky na seba nepôsobia.** Neprekrývanie počíta logika (`apart()`): prepíše domov a kvapka tam dokĺže. Kvapka nemá hmotnosť ani rýchlosť, ktorú by si niesla. | `engine.luau` r. 135–224 | Hodená kvapka neletí, susedia neuhnú nárazom, veľká a malá sa správajú rovnako. Presne to, čo žiada 6.09. |
| D5 | **Hladina sú štyri pripravené animácie.** Vlna beží pevnou rýchlosťou 420 px/s, neodráža sa, nestretáva sa s inou, o dosky (Shore) sa nezaujíma; „swell“ je osem putujúcich elíps. | `drops.plm` r. 182–200, 250–253 | Nedá sa splniť 6.27 (vlny, kvapky a Shore spolu). Piata vlna naraz zruší prvú. |
| D6 | **Karta má jednu pružinu na otvorenie aj zatvorenie** (`land = 630, 14`, s odskokom). Pri zatváraní odskok vyskočí kapsulou; zakrýva to `card_alive` s časovačom 120 ms. | `card.plm` r. 133–134, `card.luau` r. 96–103 | Artefakty z 6.30. Zatvorenie nemá odskakovať, iba otvorenie. |
| D7 | **Suseda pozná kvapka iba z kópie jeho údajov v zázname** (`left_at`, `right_r`…), teda z jeho domova, nie z miesta, kde práve je. | `drops.plm` r. 73–74, 356–368 | Vlákno a voda mieria na domov suseda. Keď sa sused hýbe, spoj sa odtrhne od tvaru (šev z 6.28). |
| D8 | **Výber „jednej z 32“ je rozpísaný ako `pick(…32 hodnôt…)`** v `picks.plm` a `card.plm`. Jazyk 0.9 má `x[i]`. | `gen.py`, `card.plm` r. 140–151 | Dlhé výrazy, ktoré sa ťažko čítajú a ľahko rozídu. |
| D9 | **Okná žijú v inej scéne s inými číslami.** Sklo má dve sady nastavení (6.29), okná sa nekývu (1D.27), pružiny okien a kvapiek nemajú nič spoločné. | `wm/session.plm` | Okno a kvapka vedľa seba sa hýbu, akoby boli z iného systému. |
| D10 | **Stupeň výkonu rieši logika po kúskoch** (`software` vypne sklo). Scéna nemá jedno číslo, podľa ktorého by ubrala. | `engine.luau` r. 1003–1006 | Efekt sa nedá pridať bez toho, aby zhoršil slabý stroj (6.21). |

D1 a D2 sú výkon, D3–D5 a D7 sú fyzika, D6 sú vyskakovacie karty, D9 sú okná.

---

## 2. Čo pleamar vie a engine to nepoužíva

Toto sú stavebné kamene celého návrhu. Všetky sú v pleamare 0.7.10, ktorý na latte-lab beží.

1. **Hodiny, ktoré sa dajú zastaviť. [zdroj]** `spin p by výraz` pripočíta každú snímku `výraz · dt`. Keď je výraz 0,
   vlastnosť stojí a **scénu nedrží hore** (`render.rs`, `Behavior::Advance`). `spin life by awake` je teda čas,
   ktorý beží iba vtedy, keď má prečo. To isté `wave p = amplitúda at f`: pod amplitúdou 0,01 scénu nebudí.
2. **Pružina v pokoji nestojí nič. [zdroj]** `Animated::step` sa vráti hneď, keď je vlastnosť v cieli a stojí.
   Pružina sa integruje po 2 ms krokoch, takže znesie aj tuhé nastavenia.
3. **Pružiny sa smú navzájom sledovať, aj do kruhu. [zdroj]** `follow` číta hodnoty iných vlastností z tej istej
   snímky; cykly sa nekontrolujú. Reťaz vlastností, z ktorých každá sleduje priemer susedov, je tlmená vlnová
   rovnica. Z toho je hladina (§5).
4. **Rýchlosť pružiny je čitateľná:** `vel(prop)`. Z nej je tvar za pohybu (§6.4) aj kývanie okna (§9).
5. **Štuchnutie s výrazom:** `impulse prop výraz`. Sila zrážky, dopadu a šplechnutia sa počíta v okamihu udalosti.
6. **Čítanie a zápis podľa miesta:** `x[i]` v jazyku 0.9, aj v pravidle (`h[col] = …`). Kvapka si prečíta, kde
   **práve je** jej sused, a výšku hladiny pod sebou.
7. **Počet snímok podľa stavu:** `rate: 60, 24 while ambient, 8 while asleep`. Krok scény je krok jej najrýchlejšej
   otvorenej plochy.
8. **Shader nad skupinou:** `shader: meno, a, b while podmienka` dostane obsah skupiny cez `inside(s, at)` a smie
   ho pokriviť. V `wm/session.plm` tak už beží `tide`, `rain` a `snow` nad oknom. Rovnako sa urobí kývanie okna.
9. **Knižnica:** `library` + `import "…" as meno`. Tie isté pružiny, konštanty a komponenty načíta scéna Goo aj
   scéna okien.
10. **Čo drží scénu hore, vypíše `PLEAMAR_TIMING=1`** (`alive_by`: „spin life“, „wave …“). Tým sa overuje pokoj.

Čo jazyk **nevie** a návrh to obchádza: tuhosť pružiny je číslo, nie výraz (`spring(k, c)` berie iba čísla), takže
hmotnosť sa nedá vyjadriť frekvenciou pružiny; v `body` nie je `repeat`, takže tvary ďalej píše `gen.py`.

---

## 3. Krok 0 — pleamar 0.7.27 a pleamar-wm 0.6.15

Urobiť **pred** akýmkoľvek prepisom a zmerať samostatne. Dnes je `patches/build-pleamar.sh` na 0.7.10 a 0.6.9.

| Verzia | Čo prináša pre GooEngine |
|---|---|
| 0.7.11–0.7.14 | Živý lom skla odpočíva, kým sa sklo hýbe nad stojacim pozadím; snímka pozadia ide rovno na kartu. |
| **0.7.18** | **Veľké telo sa delí na dlaždice 64 px** a každá meria iba tvary, ktoré do nej siahajú; neviditeľné telo sa nekreslí vôbec. Autor nameral na Vitreuse 17,4 → 4,4 ms na snímku. To je priamo D2. `dome` je šošovka každého tvaru zvlášť. |
| 0.7.19 | Keď `rate:` stúpne, nečaká sa na starý dlhý krok. Potrebné pre §4.2 (prebudenie bez oneskorenia). |
| **0.7.21** | Telo je vlastný úsek kresby a kopíruje sa zo snímky predtým, aj keď sa pred ním niečo zmenilo. |
| 0.7.24 + wm 0.6.15 | Sklo Goo vidí okná pod sebou bez dier (`glass-sees-below`). Týka sa 6.29 a 1D.42. |

Postup: preniesť záplaty z `patches/` (sedem pre pleamar, štyri pre pleamar-wm), `--check` všetkých scén, potom
zmerať `goo.plm` s `PLEAMAR_TIMING=1` v pokoji, pri pohybe myšou a s otvorenou kartou. **Tieto tri čísla sú
východisko**, s ktorým sa porovnáva každý ďalší krok. Ak niektorá záplata nesadne, napísať to a neobchádzať.

---

## 4. Piliere návrhu

### 4.1 Energia namiesto času

Všetko, čo sa hýbe, je **štuchnutie do tlmenej sústavy** alebo **sledovanie niečoho, čo sa hýbe**. Nič nečíta holý
`time`. V `goo/`, `wm/` ani v shaderoch Goo nesmie po prepise ostať `time` mimo jedného miesta: `tests/check.sh`
to má strážiť (`grep` s výnimkou `phys/clock.plm`).

```
// phys/clock.plm — the one clock of the goo. It runs while something is alive and stands still otherwise.
fact stir = 0                      // the logic and the rules raise it; see below
prop awake = 0 ~900ms              // 1 while there is a reason to move, easing out when there is none
follow awake = if(stir > 0 or near_any > 0.01 or card.p > 0.01 or wind_on, 1, 0)
prop life = 0 ~0ms
spin life by awake * pace          // pace: 1 awake, 0.35 ambient; 0 asleep, so the scene rests
```

Všade, kde je dnes `time`, bude `life`. Dych, drift a šum (`noise(life * 0.11 + k * 1.37)`) tak spomalia a zastanú
spolu s hodinami a rozbehnú sa z miesta, kde stáli, bez skoku.

### 4.2 Štyri stavy energie

| Stav | Kedy | Snímky | Čo beží |
|---|---|---|---|
| **čulý** | kurzor do 260 px od okraja s kvapkami, ťahanie, otvorená karta, letí kvapka, vlní sa hladina | 60 | všetko |
| **pokojný** | 4 s po poslednom z toho | 24 | `life` na 35 %: dych a drift, nič iné |
| **spiaci** | nečinnosť systému ≥ 1 (`sys_idle`), úsporný profil, batéria pod 20 % | 8, a iba kým dobieha pružina | občasný vzdych (§6.6), počasie pri stupni 2 |
| **skrytý** | okno na celú obrazovku, zamknuté, stupeň výkonu Softvér | 0 | nič; `life` stojí |

```
surface { …; rate: 60, 24 while ambient, 8 while asleep }
```

Zásada „neustály vlastný pohyb“ (§3 pravidiel) ostáva: v pokojnom stave kvapky dýchajú, len pomalšie a na 24
snímkach. **Na schválenie používateľom:** či je spomalený dych v pokojnom stave v poriadku. Ak nie, pokojný stav
beží na plných 60 a úspora D1 sa zmenší zhruba na polovicu.

### 4.3 Jedna fyzika, jedna knižnica

Nový priečinok `goo/phys/` s knižnicami, ktoré načíta `goo.plm`, `side.plm`, `lockscreen.plm`, `login.plm` aj
`wm/session.plm`:

| Súbor | Obsah |
|---|---|
| `phys/world.plm` | konštanty sveta: `GRAVITY`, `LEVEL`, `STICK`, odpor vzduchu, pružnosť odrazu; pomenované pružiny (`glide`, `drip`, `grow`, `settle`, `land`, `shut`, `jelly`) |
| `phys/clock.plm` | `life`, `awake`, stavy energie (§4.1–4.2) |
| `phys/surface.plm` | hladina: stĺpce, šírenie, okraje, dosky (§5) |
| `phys/drop.plm` | pohyb jednej kvapky v súradniciach okraja (§6) |
| `phys/joint.plm` | spoje: voda, vlákno, krk, ucho (§7) |
| `phys/popup.plm` | komponent rastu karty z kvapky (§8) |
| `phys/material.plm` | jedno sklo pre Goo aj okná (§10) |
| `phys/shaders/jelly.wgsl`, `splash.wgsl` | kývanie obsahu, svetlo na hrebeni |

`GRAVITY` a ostatné čísla sveta sú **iba tu**. Logika ich nepotrebuje (§4.5).

### 4.4 Stupeň kvality ako jedno číslo

`fact tier` nastaví logika raz z `LATTE_TIER`: 0 softvér/SAFE, 1 úsporný, 2 štandard, 3 plný. Každý efekt má pri
sebe podmienku a jeho vypnutie nesmie zmeniť rozloženie ani čitateľnosť.

| | 0 | 1 | 2 | 3 |
|---|---|---|---|---|
| kvapky, karty, sadnutie a zdvih | bez pružín (`~0ms`) | áno | áno | áno |
| zrážky, hod, tvar z rýchlosti | nie | áno | áno | áno |
| hladina | rovná | 24 stĺpcov | 48 | 64 + svetlo na hrebeni |
| sklo a lom | nie | sklo bez lomu | áno | áno + `dome` |
| kývanie okien | nie | nie | áno | áno |
| častice (šplech, bublina) | nie | polovica | áno | áno |

Počet stĺpcov je počet pri načítaní (`repeat`), nie výraz: `gen.py --columns N` ho zapíše a inštalátor zvolí
podľa stupňa. **[overiť]** či stačí jeden počet (48) a nižší stupeň iba vypne šírenie.

### 4.5 Scéna hlási, logika nehádá

Logika prestane počítať časy. Scéna oznámi, čo sa stalo:

```
event goo_landed ->        // k × 4096 + impact speed (px/s, capped): where it is now is freed.x, freed.y
event goo_torn ->          // a sticky drop let go of home
event goo_joined ->        // k: its thread to the right neighbour formed; goo_parted: it snapped
event goo_bumped ->        // k × 64 + j: k ran into j at more than 120 px/s
```

Z `engine.luau` zmiznú `GRAVITY`, všetky `after(math.sqrt(…))` a publikovanie `left_*`/`right_*`. Ostane register
kvapiek, trvalé rozloženie (kto má kde domov), ukladanie a to, čo kvapka robí po kliknutí.

---

## 5. Hladina (`phys/surface.plm`)

Hladina je rad stĺpcov pozdĺž spodného okraja. Každý stĺpec je pružina, ktorá sleduje priemer svojich susedov
a pritom sa vracia k nule. To je diskrétna tlmená vlnová rovnica: vlna sa šíri, odráža, dve vlny sa preložia
a všetko samo doznie. Nič z toho sa neanimuje ručne.

```
// N columns, Δ = W / (N − 1) px apart. T < 1 pulls each one back to rest; the rest of the pull is its neighbours'.
spring water = 130, 1.6
let T = 0.97
let wall[N]                                   // 1 where a shore's plate lies: the water under it does not move
repeat i in 0..N {
    prop h.$i = 0 ~water                      // height above the level, px; up is positive
    follow h.$i = if(wall[i] > 0.5, 0, T * (h[max(i - 1, 0)] + h[min(i + 1, N - 1)]) / 2 + gust.$i)
}
```

- **Rýchlosť vlny** je Δ · √(k·T/2). Pri N = 48 na šírke 2560 px (Δ ≈ 54) a k = 130 je to ≈ 430 px/s, ako dnes.
  Pri inej šírke obrazovky sa mení Δ, preto `k` voliť z tabuľky podľa šírky tak, aby rýchlosť ostala **[overiť]**.
- **Stabilita. [zdroj + výpočet]** Ciele sa prepočítajú raz za snímku, pružiny sa integrujú po 2 ms. Najrýchlejší
  kmit má ω = √(2kT) ≈ 16 rad/s; aj pri 24 snímkach (42 ms) je ω·dt ≈ 0,67, bezpečne pod hranicou 2.
- **Okraje obrazovky** odrážajú: krajný stĺpec berie za chýbajúceho suseda sám seba (`max`/`min` vyššie).
- **Dosky (6.27):** stĺpce pod TrayShore a LensShore majú `wall = 1`. Vlna sa od dosky odrazí sama, lebo jej sused
  stojí. Doska, ktorá sa vysunie alebo zasunie, štuchne dva stĺpce pri svojich koncoch. Jedno pravidlo pre každú
  dosku: logika zapíše `shore.$s.a`, `shore.$s.b` (px) a počítadlo `shore.$s.n`.
- **Šplech:** jedno pravidlo rozdá štuchnutie okolitým stĺpcom zvonovou krivkou.

```
event splash                                  // from the scene itself and from the logic (E.ripple)
fact splash.x = 0                             // px along the bottom edge
fact splash.v = 0                             // px/s into the water: mass × speed, capped
on splash {
    repeat i in 0..N { impulse h.$i -splash.v * exp(-pow((i * DX - splash.x) / 60, 2)) }
}
```

- **Dážď** (nečinnosť 2): `every 250ms..900ms while raining { rain_n = rain_n + 1; splash.x = W * random(rain_n); splash.v = 60; emit splash }`.
- **Vietor:** `gust.$i = gale * 2.2 * sin(life * 70 − i * 23)`, iba keď `gale > 0`; inak je to konštanta 0 a stĺpec
  odpočíva.
- **Kresba:** N − 1 úsečiek s `blend` medzi bodmi `(i·Δ, H − LEVEL − h[i])`, ako prihlasovacia obrazovka
  (`parts/surface.plm`), v tom istom tele ako kvapky. Nahrádza 12 elíps vĺn a 8 elíps „swell“. V pokoji je hladina
  rovná a jej tvary sa neprepočítavajú.
- **Stupeň 3:** nad hladinou skupina `mode: add` so shaderom svetla na hrebeni (vzor `shaders/crest.wgsl`), iba
  `while stirred > 0.01`, kde `stirred` je pomalá pružina za súčtom |h|.

`E.ripple(where, force, kind)` v logike ostáva ako tenká obálka: nastaví `splash.x`, `splash.v`, vyšle `splash`.
Druh „tremble“ je štuchnutie striedavým znamienkom do troch stĺpcov.

**Ostatné tri okraje** hladinu nemajú (dnes tiež nie). Ak ju používateľ bude chcieť, je to ten istý komponent
s iným `N` a osou, iba pri stupni 3.

---

## 6. Kvapka (`phys/drop.plm`)

Kvapka sa ďalej počíta v súradniciach svojho okraja: `t` pozdĺž, `n` od okraja do obrazovky (dnešné `tx/ty/nx/ny`
je dobrý základ a ostáva). Mení sa to, z čoho sa skladá cieľ jej pružín, a čo sa stane, keď stratí kontakt s okrajom.

### 6.1 Hmotnosť

`let m.$k = pow(r0.$k / 26, 2)` — plocha oproti bežnej kvapke. Keďže tuhosť pružiny nemôže byť výraz, hmotnosť
nemení frekvenciu, ale **odozvu na sily**:

| Sila | Účinok delený hmotnosťou |
|---|---|
| vietor, drift, zachvenie | výchylka × 1/√m (dnešné `small`) |
| vlna pod kvapkou | zdvih × 1/√m; veľká kvapka sa na vlne sotva pohne |
| náraz suseda | štuchnutie × m_druhého / (m_k + m_druhého) |
| dopad do hladiny | `splash.v` = m × rýchlosť dopadu |
| príťažlivosť kurzora | bez zmeny (je to túžba, nie sila) |

Povaha „heavy“ z `engine.luau` sa stane násobkom hmotnosti (× 2,5), „playful“ pružnosťou odrazu.

### 6.2 Susedia naživo a mäkké zrážky

Záznam nesie namiesto ôsmich polí `left_*`/`right_*` iba **čísla miest**: `lk`, `rk` (−1: nikto). Kvapka číta, kde
sused práve je (`x[rk]`, `rr[rk]`), nie kde býva.

```
// along the edge, how far the neighbour on the right reaches into this one: positive while they overlap
let over.r.$k = if(goo.$k.rk >= 0, (rr.$k + rr[goo.$k.rk] + GAP) - (pt[goo.$k.rk] - pt.$k), 0)
let over.l.$k = if(goo.$k.lk >= 0, (rr.$k + rr[goo.$k.lk] + GAP) - (pt.$k - pt[goo.$k.lk]), 0)
let shove.$k = max(0, over.l.$k) * share.l.$k - max(0, over.r.$k) * share.r.$k     // share: the other's mass over both
follow pt.$k = home.t.$k + lean.$k + drag.t.$k + shove.$k
```

Pretože obe kvapky čítajú polohu tej druhej, tlačia sa navzájom a pružiny ich rozsadia. Ťahaná alebo hodená
kvapka tak susedov **naozaj odtlačí** a oni sa vrátia. `apart()` v logike ostáva iba na **trvalé** rozloženie:
spustí sa po `goo_landed` a po zmene veľkosti, nie počas pohybu. Zásada 22 (nič sa neprekryje) platí v pokoji
z logiky a za pohybu z pružín.

Keď `vel(pt.$k)` pri prvom dotyku presiahne 120 px/s, scéna vyšle `goo_bumped` a obe kvapky dostanú `impulse sq`
(sploštenie v smere nárazu). Cena: dve čítania podľa miesta na kvapku, vyhodnotí sa iba zvolený prvok **[zdroj]**.

### 6.3 Let: hod, pád, skok

Jeden mechanizmus pre všetky tri. Pri pustení scéna zapíše, odkiaľ a ako rýchlo:

```
on release hit.$k while held.$k > 0 {
    fly.x0.$k = x.$k;  fly.y0.$k = y.$k
    fly.vx.$k = clamp(vel(px.$k), -1600, 1600)        // the hand's speed is the throw
    fly.vy.$k = clamp(vel(py.$k), -1600, 1200)
    fly.at.$k = life;  flying.$k = 1
}
let ft.$k = life - fly.at.$k
let fx.$k = fly.x0.$k + fly.vx.$k * (1 - exp(-DRAG * ft.$k)) / DRAG      // the air slows it sideways
let fy.$k = fly.y0.$k + fly.vy.$k * ft.$k + 0.5 * GRAVITY * ft.$k * ft.$k
```

Uzavretý vzorec, nie integrovanie po snímkach: je presný pri 60 aj 24 snímkach a nedriftuje. Let končí prvým
dotykom okraja:

```
let touch.$k = fy.$k > H - LEVEL - rr.$k or fx.$k < STICK or fx.$k > W - STICK or fy.$k < STICK
on change touch.$k while flying.$k > 0 and touch.$k {
    flying.$k = 0
    freed.x = fx.$k;  freed.y = fy.$k
    splash.x = fx.$k;  splash.v = m.$k * min(fly.vy.$k + GRAVITY * ft.$k, 1400);  emit splash
    impulse sq.$k 4 + 0.006 * (fly.vy.$k + GRAVITY * ft.$k)
    emit goo_landed(k)
}
```

Logika na `goo_landed` určí domov (okraj, `at`), zvýši `land` a scéna v tej istej snímke vynuluje posun, ako dnes.
Kvapka pustená z pokoja padá rovno dole (rýchlosť 0), pustená za pohybu letí oblúkom, hodená k bočnému okraju sa
naň prilepí. `Drop:jump(at, speed)` nastaví tie isté fakty (`fly.vx`, `fly.vy` hore). Kvapka, ktorá `returns`
(BarGoo), dostane namiesto letu návrat pružinou. Dopad na dosku (Shore): doska je `wall`, kvapka sa odrazí
(`fly.vy = −e · v`, nový let) a dopadne do goo vedľa — nahrádza dnešné dva vnorené časovače.

Zásada „pád, nie výstrel“: rýchlosť hodu je obmedzená (1600 px/s) a `DRAG` ≈ 1,8 ju rýchlo uberie. **Na
schválenie:** či sa kvapka smie hodiť, alebo má pustená vždy padať rovno dole ako dnes (`fly.vx = 0`).

### 6.4 Tvar z pohybu

Kvapka sa natiahne v smere, ktorým sa hýbe, a zúži naprieč, aby plocha ostala rovnaká:

```
let sp.$k = length(vel(px.$k), vel(py.$k)) + if(flying.$k > 0, length(fly.vx.$k, fly.vy.$k + GRAVITY * ft.$k), 0)
let st.$k = clamp(sp.$k / 1800, 0, 0.32) * tier_on
// ellipse { …; scale: (1 + st) , 1 / (1 + st); rotate: atan2(vy, vx) * 1deg }
```

Padajúca kvapka je slza, dopadnutá placka (`sq`), ťahaná sa nakláňa za rukou. Dnešné `wide.$k` (sploštenie
a sadnutie) ostáva a sčíta sa s tým. **[overiť]** `rotate:` na tvare vnútri `body` (referencia ho uvádza pri každom
tvare).

### 6.5 Jazda na vlne

`rises.$k` dostane namiesto štyroch ručných vĺn výšku hladiny pod sebou, medzi dvoma stĺpcami:

```
let col.$k = clamp(pt.$k / DX, 0, N - 1.001)
let lift.$k = mix(h[floor(col.$k)], h[floor(col.$k) + 1], fract(col.$k)) / sqrt(m.$k)
```

A naopak: kvapka, ktorá sa pri okraji rýchlo pohne (ťahanie popri hladine, dosadnutie, stlačenie), štuchne stĺpec
pod sebou (`on change sign(vel(pt.$k))` s prahom). Kvapky a hladina sú tak jedna sústava v oboch smeroch.

### 6.6 Život

- **Dych a drift** čítajú `life` (§4.1). Vzorce ostávajú.
- **Spiaci stav:** namiesto dychu vzdych. `every 3s..8s while asleep and lively { sigh = sigh + 1 }` a každé miesto
  `on change sigh while floor(random(sigh) * slots) == k { impulse sq.$k 2.5 }`. Jedna kvapka sa nadýchne, scéna
  sekundu kreslí a zaspí.
- **Kurzor:** drahý výpočet blízkosti obaliť `if(hot.e, …, 0)`, kde `hot.e` je „kurzor je do 260 px od okraja e“.
  `if` vyhodnotí iba platnú vetvu **[zdroj]**, takže myš uprostred obrazovky nestojí nič.
- **Neobsadené miesto** nič nepočíta: každý `follow` začína `if(goo.$k.on, …, 0)` a tvary majú polomer 0.

### 6.7 Čo z `drops.plm` ostáva a čo odchádza

| Ostáva | Mení sa | Odchádza |
|---|---|---|
| súradnice okraja, `sit`/`up`/`lean`, zóna a pravidlá myši, kapsula, jadro, guľky | `time` → `life`; susedia cez `lk`/`rk`; `rises` cez `lift`; let cez §6.3 | `ripple` model a `wave.$k`, `swell`, `falls`/`fly`/`cross`, polia `left_*`/`right_*`, `fall`/`fall_h`/`jump_*` v zázname |

---

## 7. Spoje (`phys/joint.plm`)

Vzhľad podľa zásady 21 (ostré oká, vlákno medzi hornými časťami) ostáva. Mení sa, odkiaľ kam spoj vedie.

- **Voda a vlákno** vedú na **živú** polohu suseda (`x[rk]`, `y[rk]`). Keď sa sused zdvihne, nakloní alebo ho
  niekto ťahá, spoj ide s ním.
- **Vlákno má stav:** `fact tied.$k`. Vznikne, keď sú kvapky bližšie než 0,9 súčtu polomerov, a **praskne**, keď
  sa natiahne nad 2,3 súčtu (`on change`). Pri prasknutí dostanú obe kvapky štuchnutie od seba (spätný ráz), scéna
  vyšle `goo_parted`, a pri stupni ≥ 2 odletí pár kvapôčok (`particles … burst`). Medzitým sa vlákno tenčí podľa
  natiahnutia: `w = w0 / (1 + 1.6 · natiahnutie)`.
- **Krk ťahanej kvapky** (dnes posledný riadok `shapes.plm` s tromi `pick` po 32): cez `x[carried]`. Krk je zvon
  `4·s·(1−s)` po dĺžke, najtenší v strede, a praskne pri `tear`.
- **Ucho karty** je spoj toho istého druhu (§8.3): žiadny zvláštny kód v `card.plm`.

`picks.plm` sa zmenší na pár riadkov alebo zanikne: `own.x` je `x[card_owner]`. **[overiť]** či `x[i]` s meniacim
sa miestom smie byť priamo v `body` (referencia: áno, je to `pick` nad všetkými prvkami).

---

## 8. Vyskakovacie karty (`phys/popup.plm`)

### 8.1 Dve pružiny, dva smery

```
spring land = 630, 14          // opening: a quarter of a second, two bounces one can see
spring shut = 900, 60          // closing: critically damped, about 140 ms, nothing comes back
prop card.p = 0 ~land
on change card_open while card_open     { card.p: 1 ~land }
on change card_open while not card_open { card.p: 0 ~shut }
```

Zatvorenie nikdy neprestrelí pod nulu, takže karta nevyskočí kapsulou. `card_alive` a časovač 120 ms v `card.luau`
sa zrušia: kresba sa riadi `card.p > 0.01`. Rieši 6.30 (časť o zatváraní).

### 8.2 Tri fázy rastu

Jedna hodnota `card.p`, z nej tri krivky, každá s vlastným oknom, aby sa veci diali po sebe a nie naraz:

| Fáza | Rozsah `card.p` | Čo sa deje |
|---|---|---|
| **1 · krk** | 0 – 0,35 | Kvapka vystúpi od okraja, z nej vyrastie guľatý výbežok užší než kvapka. Krk je zvon `4·t·(1−t)`. |
| **2 · rozliatie** | 0,2 – 0,8 | Výbežok sa rozleje do šírky (kubicky) a narovná rohy: polomer rohu z 58 na 18. |
| **3 · usadenie** | 0,7 – 1 + prestrel | Výška dobehne s odskokom; pri prestrele sa karta vydúva aj do šírky (`max(0, p−1) · 0,6`). |

Dnešný `card.plm` má fázy 2 a 3 v jednom výraze; rozdeliť ich na pomenované `let` a ponechať čísla, ktoré
používateľ už schválil (zvon, 0,6, rohy).

### 8.3 Ucho a karta jedno telo (6.28)

- Ucho sa do tela karty kreslí na **živej** polohe a v živom polomere vlastníka (`x[card_owner]`, `rr[card_owner]`),
  nie na domove s rozdielom. Kolíše sa, rastie kolieskom a spoj ide s ním.
- Zliatie (`blend`) ucha s kartou neklesá na 4, keď je karta otvorená, ale ostane na hodnote úmernej polomeru
  ucha (`max(12, 0.45 · ear)`), aby v rohu nebol zárez. Dnes `4 + 120·t·(1−t)` padne pri t = 1 na 4: to je ten šev.
- Farba: prechod kávy do farby panela (`card.pc`, schválené 5. 11.) ostáva.
- Kvapka-vlastník sa počas otvorenej karty **nekreslí v tele kvapiek** (polomer × `1 − card.own.$k`), iba v tele
  karty. Dve telá cez seba dávajú dvojitý obrys a pri skle dvojitý lom.

### 8.4 Obsah

- **Riadky prichádzajú po vlne,** nie naraz: dnešný `reveal` (460 ms, posun 0,1 na riadok) ostáva, ale začne až
  vo fáze 3 (`card.p > 0.7`), nie pri zmene obsahu počas rastu.
- **Hladina v karte** (`velvet`, módy `card.m1`, `card.m3`) je dobrá a ostáva. Pri zatváraní sa módy nesledujú
  (`follow … = if(card_open, card.p, 0)` s pružinou `shut`), aby sa nezakývala prázdna kapsula.
- **Zmena veľkosti otvorenej karty** (iná záložka, viac riadkov): `card.ws`/`card.hs` na pružine `grow` ostávajú;
  horná hrana pri prepínaní záložiek neskáče (zásada 9) — `card_min`/`card_peak` ostávajú.
- **Sklo počas rastu:** `lens hold while card.p > 0.02 and card.p < 0.98` — snímka pozadia sa neberie, kým sa
  karta hýbe. Lom sa prepočíta raz, keď dosadne. **[zdroj]** referencia §8.1.

### 8.5 Bublina okna a prasknutie

`bubble.plm` číta `time` (`blow.at = time`). Prejsť na `life` a `stir` (§4.1): bublina zobudí hodiny na 0,6 s.
Miesto, kde bublina dosadne na okno a kde okno praskne, štuchne hladinu, ak je do 200 px nad ňou.

---

## 9. Okná v pleamar-wm

Scéna okien je iný proces (`system/pleamarwm/wm/session.plm`), takže stav sa nezdieľa. Zdieľa sa **knižnica**
(§4.3) a pár faktov cez `latte-say`. Postup: najprv Goo (kroky 1–6 v §12), potom okná.

### 9.1 Kývanie okna — wobble (1D.27)

Okno je v scéne už dnes vo vlastnej skupine so shaderom (`shader: tide, water while water < 0.999`). Kývanie je
ďalší shader tej istej skupiny, alebo rozšírenie `tide`:

```
// per window: where it is going leads, a loose spring lags behind; the difference is how far it is bent
spring jelly = 240, 11                      // from phys/world.plm: two swings one can see, then still
prop jx.$i = 0 ~jelly
prop jy.$i = 0 ~jelly
follow jx.$i = x                            // the window's own x, y as the layout says
follow jy.$i = y
let bend.x = clamp(x - jx.$i, -90, 90)
let bend.y = clamp(y - jy.$i, -90, 90)
group {
    shader: jelly, bend.x, bend.y, grab.u, grab.v while abs(bend.x) + abs(bend.y) > 0.3
    …title bar, window…
}
```

```wgsl
// phys/shaders/jelly.wgsl — the window as a sheet of jelly held at one point: the further from the hand, the more it lags
fn shade(s: Shader) -> vec4<f32> {
    let grab = vec2<f32>(s.a.z, s.a.w);                    // where it is held, 0…1 of its box
    let far = distance(s.uv, grab);
    let lag = vec2<f32>(s.a.x, s.a.y) * far * far;         // nothing at the hand, most at the far corner
    return inside(s, s.pos + lag);
}
```

- Bod držania (`grab.u`, `grab.v`) je miesto, kde myš okno chytila; pri zmene veľkosti protiľahlý roh.
- **Podmienka `while`** je kľúčová: v pokoji skupina nemá vlastný prechod a okno sa kreslí ako dnes **[zdroj]**.
- Skupina s efektom nesmie byť v inej skupine s efektom. Okno v daždi alebo snehu má už svoj shader: tam sa kývanie
  vynechá, alebo sa `bend` pridá ako ďalšie hodnoty do `rain`/`snow` (majú voľné miesta v `values`).
- Iba stupeň ≥ 2 a nikdy pri okne na celú obrazovku.
- **[overiť]** Okraj: `inside` mimo skupiny je priehľadné, takže ohnutý roh sa oreže o rámec skupiny. Skupine dať
  rezervu (`size` väčšie o 90 px na každú stranu), inak roh pri veľkom ohybe zmizne.

### 9.2 Okno ako teleso

- **Dosadnutie:** pustené okno dostane `impulse` do `jy` úmerné rýchlosti ruky; raz sa prehne a ustáli.
- **Minimalizácia do BarGoo** (zásada 14): scéna okien okno zmenší do kvapky (to robí dnes Goo v `body.plm`,
  `going.*`) a pošle `latte-say 'fact fly.x0 …' 'emit win_min'`. Goo z toho urobí **let podľa §6.3**: kvapka okna
  je kvapka ako každá iná, dopadne, šplechne a splynie s BarGoo. Blok `going.*` v `drops.plm` a `body.plm` zanikne.
- **Okno nad hladinou:** scéna okien pošle Goo, keď spodná hrana okna prejde pásom 54 px nad okrajom
  (`latte.band`) rýchlejšie než 300 px/s: jedno `splash`. Okno ťahané popri hladine ju rozvlní.
- **Kvapky uhýbajú oknu** dnes skokom domova (`E.avoid`). S §6.2 dostane kvapka okno ako tretieho „suseda“
  (obdĺžnik namiesto kruhu) a uhne pružinou. Druhý krok, až keď beží základ.

### 9.3 Spoločné pružiny

`wm/session.plm` má vlastné pružiny okien. Tie, ktoré majú s kvapkami vyzerať rovnako (dosadnutie, otvorenie,
zatvorenie), nahradiť menami z `phys/world.plm`. Scénu upstreamu meniť čo najmenej: každý zásah označiť
`// LatteOS:` ako doteraz, aby sa dala znova zlúčiť s novou verziou.

---

## 10. Sklo a materiál (`phys/material.plm`, 6.29)

Jedna sada faktov pre Goo aj okná, jeden zdroj v Nastaveniach › Okná › Sklo:

| Fakt | Rozsah | Kam ide |
|---|---|---|
| `glass.amount` | 0–1 | `glass:` kvapiek, kariet, okien |
| `glass.frost` | 0–1 (číslo, nie `auto`) | `frost:` |
| `glass.smoke`, `glass.milk` | 0–1 | čitateľnosť svetlého/tmavého písma |
| `glass.bend` | 0–2 | `refraction:`, a `dome:` pri stupni 3 |
| `glass.rainbow` | 0–2,5 | `dispersion:` |
| `glass.ripple` | 0–1 | `ripple:` |

Knižnica dá komponent, ktorý tie vlastnosti nastaví rovnako na tele kvapiek, karte aj podklade okna. Logika Goo
ich pri zmene pošle scéne okien jedným `latte-say`. Pomer vody a mlieka (zásada 6) ostáva tým, čo `glass.amount`
kvapiek určuje; okná majú svoj stupeň.

Úspory lomu, ktoré dnes nie sú zapnuté **[zdroj]**:

```
lens every 50ms + 450ms * (1 - awake)       // calm: two captures a second are enough
lens hold while card.p > 0.02 and card.p < 0.98
```

Pri stupni 1: `lens = image "~/.cache/latteos/wallpaper.png"` — sklo láme iba tapetu a nič nesníma.

---

## 11. Rozpočet a brány

Merať na latte-lab (RX 640, 2560 × 1080) nástrojom z `skill/measuring.md` (`medir`, `PLEAMAR_TIMING=1`), 30 s
na každý stav, s 12 kvapkami a 8 oknami v BarGoo. Východisko je meranie po kroku 0.

| Stav | Dnes (posledné merania) | Cieľ |
|---|---|---|
| skrytý (celá obrazovka, zámok) | nemerané | **0 snímok**, pod 0,3 % jadra |
| spiaci | 17–44 % jadra (scéna neodpočíva) | pod 1 % jadra |
| pokojný | to isté | pod 4 % jadra |
| čulý, myš nad kvapkami | 24 % jadra pri 32 miestach | pod 12 % jadra, snímka do 3 ms |
| otvorenie karty | nemerané | žiadna snímka nad 16,7 ms |
| rozvlnená hladina, 48 stĺpcov | — | príplatok do 0,5 ms na snímku |
| softvérové kreslenie (stupeň 0) | — | 0 snímok v pokoji, žiadna pružina |

**Brána po každom kroku:** `tests/check.sh`, `pleamar --check` všetkých scén, `gen.py --check`, meranie troch
stavov a porovnanie snímok `tests/screen.sh` s predošlým krokom. Krok, ktorý zhorší pokoj alebo snímku karty, sa
nevracia do vetvy, kým sa nenájde prečo. `PLEAMAR_TIMING=1` musí v spiacom stave vypísať prázdne `alive_by`.

---

## 12. Poradie práce

Každý krok je samostatný commit, ktorý necháva plochu funkčnú. Neskáče sa.

| # | Krok | Hotovo, keď |
|---|---|---|
| 0 | pleamar 0.7.27, pleamar-wm 0.6.15, záplaty, východiskové meranie (§3) | tri čísla zapísané v `docs/OPTIMALIZACIA.md` |
| 1 | `phys/world.plm`, `phys/clock.plm`; `goo.plm` na `language 0.9`; `time` → `life` všade; `rate:` so stavmi; `tier` | v spiacom stave 0 snímok; vzhľad v čulom stave rovnaký ako predtým |
| 2 | karta: pružina `shut`, zrušiť `card_alive`, tri fázy pomenované, ucho naživo (§8.1–8.3) | zatvorenie bez vyskočenia; šev ucha preč pri pohybe aj kolieskom |
| 3 | hladina `phys/surface.plm`, `E.ripple` ako obálka, dosky ako steny, jazda na vlne (§5, §6.5) | kameň sa odrazí od okraja a od TrayShore; dve vlny sa preložia |
| 4 | susedia cez `lk`/`rk`, mäkké zrážky, spoje naživo (§6.2, §7); `picks.plm` zmenšiť | ťahaná kvapka odtlačí suseda; vlákno praskne a zlepí sa |
| 5 | let (§6.3), tvar z pohybu (§6.4), udalosti `goo_landed` a spol.; z `engine.luau` preč časovače a `GRAVITY` | hra pri nečinnosti (Worms) beží na novom lete; `Drop:jump` bez zmeny rozhrania |
| 6 | materiál a úspory lomu (§10); `side.plm`, `lockscreen.plm`, `login.plm` na tú istú knižnicu | jedny posuvníky skla; druhý monitor sa správa rovnako |
| 7 | okná: `jelly.wgsl`, spoločné pružiny, minimalizácia ako let, šplech od okna (§9) | okno sa pri ťahaní kýve a v pokoji nestojí nič navyše |
| 8 | dokumenty: `LATTEOS-GOO.md` §3, `docs/goo/PRAVIDLA.md`, `ROZHODNUTIA.md`, ROADMAP 6.09, 6.27–6.30, 1D.27 | — |

Rozhranie kvapiek (`drops/*.luau`, `Drop:…`, `E.define`, `E.upsert`, `kvapky.json`) sa **nemení**. Menia sa iba
vnútornosti `engine.luau` a záznam `goo` v scéne. Po každom kroku `gen.py` a kontrola, že súbory, ktoré píše,
sedia.

---

## 13. Riziká

| Riziko | Čo s ním |
|---|---|
| Kruhové `follow` medzi stĺpcami alebo kvapkami sa rozkmitá | Tuhosť držať pod hranicou z §5; pri prvom spustení `--record h.0,h.24` a pozrieť, či doznie. Poistka: `clamp` na cieli. |
| `x[i]` s meniacim sa miestom je drahšie, než sa zdá (pick nad 32 prvkami na každom čítaní) | Zmerať po kroku 4. Ak áno, vrátiť sa pri vlákne k údajom v zázname a `x[i]` nechať iba na zrážku. |
| `rate:` 24 pri pokojnom stave vyzerá trhane | Skúsiť 30; ak ani to, pokojný stav na 60 a rozhodne používateľ (§4.2). |
| Kývanie okna oreže rohy alebo rozmaže text | Rezerva okolo skupiny; ohyb obmedzený na 90 px; text sa počas ohybu vzorkuje lineárne — krátky ohyb to znesie. Ak nie, kývať iba rám a tieň, nie obsah. |
| Scéna okien sa po zásahoch ťažko zlučuje s upstreamom | Zásahy iba v označených blokoch `// LatteOS:`; shader a pružiny v knižnici mimo `session.plm`. |
| Hod kvapky skončí mimo obrazovky pri viacerých monitoroch | Let sa počíta v súradniciach svojej scény a končí na jej okraji; prechod na druhý monitor nie je súčasťou. |
| Tuhosť pružiny nie je výraz, hmotnosť je iba napodobená | Stačí na dojem (§6.1). Ak nie, návrh autorovi pleamaru: `spring(k, c)` s výrazmi → `patches/issues/`. |

---

## 14. Otázky na používateľa pred kódovaním

1. **Pokojný stav:** spomalený dych na 24 snímkach, alebo plný pohyb stále (§4.2)?
2. **Hod kvapky:** smie pustená kvapka letieť v smere ruky, alebo vždy padá rovno dole (§6.3)?
3. **Kývanie okien:** celý obsah okna, alebo iba rám a tieň (§9.1)?
4. **Hladina na ostatných okrajoch:** iba dole ako dnes, alebo pri stupni 3 všade (§5)?
5. **Poradie:** kroky 0–2 opravujú výkon a karty a nepridávajú nič nové; kroky 3–7 sú nová funkcia. ROADMAP od
   30. 10. hovorí „nepridávať nové produktové funkcie“ pred alpha vydaním. Robiť teraz všetko, alebo iba 0–2?
