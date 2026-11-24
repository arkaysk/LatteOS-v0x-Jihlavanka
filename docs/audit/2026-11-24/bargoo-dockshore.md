# Audit: BarGoo a DockShore (24. 11. 2026)

Rozsah: BarGoo (hlava, ikry a strapce, `goo/drops/bargoo.luau`, `goo/lib/bar.luau`), DockShore (dok pleamar-wm
v `system/pleamarwm/wm/session.plm`, doska v `goo/parts/plates.plm`, napojenie v `goo/lib/engine.luau`), most
`system/pleamarwm/bin/hyprctl`, voľba Správa úloh (`apps/settings.qml`) a bočné scény (`goo/side.plm`).
Čítal som iba kód, na živej ploche som nič nespúšťal (`pleamar --check` goo.plm aj side.plm: ok).

**Pozor, pracovný strom sa počas auditu menil** (iná práca bežala súbežne, nič z toho nie je v commite):
`bar.luau` a `wm.luau` už skrývajú Rozloženie a „Vždy navrchu“ na pleamar-wm (`wm.can`), `hyprctl` a `session.plm`
doplnili `to_desk` / `to_screen` (`latte_to_screen`). Čísla riadkov sú z pracovného stromu 24. 11. popoludní.

## Zhrnutie

- **Minimalizácia do BarGoo (pravidlo 14) a vlna hlavy pre okno, ktoré chce pozornosť, sú od odchodu Hyprlandu
  (1D.12) mŕtve.** Udalosti `win_min`, `win_urgent`, `win_born`, `win_pop` v pleamar-wm nikto nevysiela.
  ROADMAP 6A.01 je pritom `[x]`.
- **Ponuka okna z ikry** mala v commite štyri položky, ktoré nič nerobili (Rozloženie, Vždy navrchu). Pracovný strom
  ich teraz skrýva. Ostáva „Obnoviť“, ktoré iba prepne na okno, a pevné „Plocha 1–4“ proti dynamickým plochám pleamar-wm.
- **Ikry nepoznajú dosky Shore.** Strapce môžu ísť pod LensShore, AppCloud alebo TrayShore prenesený s Alt,
  a pri mnohých aplikáciách sa zmenšia na ~17 px a prekrývajú sa.
- **Pás pre kvapky ide v pleamar-wm vždy dole.** `latte.band(…)` most nepozná, takže BarGoo presunutá k inému
  okraju nemá voľný pás (sľub z LATTEOS-GOO §8).
- **DockShore funguje, ale nie ako lišta Windows 11.** Klik na aktívnu aplikáciu ju neminimalizuje, ponuka je iba
  po anglicky, na mliečnych kávach (Latte) má písmo kontrast 3,7 : 1, nemá viac ako 12 položiek a Win+1…9 ide
  v inom poradí ako ikony.
- **Po novom načítaní scény pleamar-wm** sa voľba BarGoo / DockShore / nič, `win.nomin` a farba kávy doku nepošlú
  znova. Pri BarGoo sa tak môže ukázať aj dok, pri „nič“ sa vrátia tlačidlá Minimalizovať.
- **Viac monitorov:** režim okien hlási iba monitor v bode 0,0, takže bočné hlavy ukazujú režim hlavného monitora.
  Dok a Goo predpokladajú, že hlavný monitor je v pleamar-wm index 0.
- Texty v Nastaveniach a v dokumentoch sú po 23. 11. zastarané („dok iba na voľnom monitore“, „48 miest“,
  `reversed`, ľavý klik na hlavu).

---

## Dizajn

### Overené v kóde

**D1 — Ikry sa zmenšia pod veľkosť terča a prekrývajú sa** · stredná
`goo/lib/bar.luau:218–222`: keď strapce presiahnu miesto po TrayShore, poloha sa stiahne až na 25 % (`f ≥ 0,25`),
ale polomer iba na 50 % (`p.r * max(f, 0.5)`). Najmenšia ikra pod oknom má tak polomer 17 × 0,5 = 8,5 px
(terč 17 px). Stredy sú pritom bližšie, než je súčet polomerov, a to porušuje pravidlo 22 (neprekrývanie).
Odhad pre 1024 × 768 (najmenšie rozlíšenie podľa pravidla 11): hlava na 0,42 (x ≈ 430), miesto po TrayShore
≈ 250 px a každá aplikácia s jedným oknom berie v rade 2 · 24 + 12 = 60 px. Pri 10 aplikáciách vychádza
f ≈ 0,38, polomer 12 px a stredy 23 px od seba, teda ikry sa dotýkajú alebo prekrývajú. Používateľ z Windows 11
je zvyknutý na tlačidlá 40 px a radšej „…“ (pretečenie) než mikroikony.

**D2 — Ikry nerešpektujú úseky dosiek Shore** · stredná
`goo/lib/bar.luau:218` ráta miesto iba z `E.limit(head)`. `goo/lib/engine.luau:81–87` (`limit`) odpočíta TrayShore
iba v rohu (`tray_at < 0`) a `engine.luau:170` vynecháva ikry (`d.v.team ~= 1`) zo zosúvania z blokovaných úsekov.
Pri BarGoo s LensShore (voľby Spúšťač a Správa úloh sú nezávislé, takže je to bežná kombinácia), s AppCloud
alebo s TrayShore prenesenou s Alt môže strapec ležať pod doskou. Nedá sa naň kliknúť a doska ho zakryje.

**D3 — Strapce na inom okraji ako dolnom ignorujú okná** · nízka
`bar.luau:441`: úseky okien (`blocks`) sa rátajú iba pre `head.edge == 0`. Na ľavom, hornom či pravom okraji sa
strapce stavajú do výšky aj pod oknom (LATTEOS-GOO §3 „Neprekrývať okná“).

**D4 — DockShore nemá slovenčinu** · stredná
`system/pleamarwm/wm/session.plm` nemá blok `translations`, hoci jazyk ho pozná (`pleamar-wm --docs reference`
§11.1). Ponuka doku („New window“, „Open“, „Hide“, „Keep on the shore“, „Take off the shore“, „Close windows“,
r. 1653–1661), menovky zón („Workspace {j + 1}“, r. 1522; „A dock menu item“) a náhľady sú iba po anglicky. Ide to
proti pravidlu 4. Navyše „Keep on the shore“ nie je slovník Windows 11 (tam je „Pripnúť na panel úloh“).

**D5 — Kontrast DockShore na mliečnej káve** · stredná
Písmo a bodky doku sú pevne `ink #f5f7f5` a `mint #9ed6bd` na `dkc.plate` (`session.plm:88–95`). Prepočítané
(WCAG): espresso 17,4 : 1 · cappuccino (mlieko 0,55) ≈ 9,5 : 1 · **latte (mlieko 0,85) 3,67 : 1** pre text
(12 px potrebuje 4,5 : 1), **mint 2,41 : 1** a bodka okna (ink 55 %) **2,19 : 1** (prvok UI potrebuje 3 : 1).
Karty Goo to od 6.52 riešia (`card.lite`), dok nie.

**D6 — Doska DockShore na druhom monitore nie je hmota Goo** · nízka
`session.plm:1494–1500`: na monitoroch `s != 0` kreslí dosku sám pleamar-wm (`body` s `dkc.plate` a obrysom).
Nemá hladinu, svetlo kurzora ani materiál skla (`fact.glassy` sa do pleamar-wm neposiela), takže pri sklenenom
materiáli je na hlavnom monitore doska sklo a na druhom nepriehľadná káva. Dok na druhom monitore sa ani nedá
posunúť s Alt (je vždy v strede, `dk.a0`, r. 1391).

**D7 — Hlava pri štarte nemá meno režimu** · nízka
`bar.luau:355`: `if … n == mode then return end`. `mode` začína na 0 (Páska), takže pri štarte v páske sa
`show_mode()` nezavolá a bublina hlavy ostane „BarGoo“ namiesto „Páska“.

**D8 — Koliesko na hlave v Dlaždiciach nič nerobí a ani nezavibruje** · nízka
`bar.luau:369–371`: v režime 1 sa nič nestane. Háčik `wheel` existuje, preto engine nezavibruje (pravidlo 8), a text
v Nastaveniach sľubuje „Wheel: the next window“ (`settings.qml`, `dropInfo.bargoo`).

**D9 — Ikra pri pretečení** · nízka
`bar.luau:26`: `ROOM = fact.slots − 8 = 24`, kým LATTEOS-GOO §4.1 píše „48 miest“. V praxi rozhoduje pleamar-wm,
ktorý spravuje najviac 16 okien (`session.plm:67`, `hyprctl` `range(16)`), takže ikra „Ďalšie okná“ sa nikdy
neukáže. Treba opraviť dokument, nie kód.

**D10 — Klávesnica** · nízka
Win+T (`keys.plm`) prejde aj ikry, ale v páske a dlaždiciach sú ikry vonku iba po postáti myši (`M.rest`), takže sa
k nim z klávesnice nedá dostať. Enter na hlave prepne režim. DockShore nemá ovládanie klávesnicou vôbec. Náhrada
je Alt+Tab (`focus_next`, bez prehľadu), Super+Tab a Win+1…9.

### Čo je v poriadku (overené)

- Kliky hlavy zodpovedajú ROZHRANIE/§4: ľavý ďalší režim alebo pri `bar_fixed` vytiahne ikry, pravý ukáže plochu
  a vlnka (`ripple(3)`), koliesko posunie pásku alebo prepne na ďalšie okno. Stredné tlačidlo háčik nemá, takže engine
  zavibruje (pravidlo 8). Ikry: ľavý prepne alebo minimalizuje (`toggle`), pravý otvorí ponuku okna, ťahanie mení
  poradie aplikácií.
- Všetky texty BarGoo (`tr`/`N` v `bar.luau`, `bargoo.luau` vrátane troch viet `about`) majú preklad v
  `goo/lang/sk.plm` (r. 60, 1636, 1878 a ďalšie).
- Farba a materiál: hlava aj ikry sú kvapky enginu (káva, jedno telo, `team` 1/2 sa zlieva iba s lištou). Dosku
  DockShore na hlavnom monitore kreslí telo Goo (`plates.plm:13`), a tá je aj stenou hladiny (`wall.0`).
- Stav okna: vpredu je ikra o 6 % väčšia, odložená je menšia (0,84) a stlmená (`fade`, r. 231–241).

---

## Funkcie

### Overené v kóde

**F1 — Minimalizácia do BarGoo, žiadosť o pozornosť a bublina okna sú mŕtve** · vysoká
`bar.luau:318` (`win_urgent`), `:387` (`win_min`), `:406–421` (`win_born`, `win_pop`) čakajú na udalosti, ktoré
v repe nikto nevysiela. Vysielal ich Hyprland (`system/hypr`, zmazaný v 1D.12, 3. 11.), `session.plm` ich nemá.
Dôsledky:
- pravidlo 14 („minimalizácia = okno spadne do BarGoo a hladina sa zvlní“) neplatí, hoci ROADMAP 6A.01 je `[x]`
  a GOOENGINE-2 r. 917 píše „Okno do BarGoo hádže jadro“,
- hlava sa nezavlní za okno na inej ploche, ktoré chce pozornosť (§4.1). Okraj okna pulzuje (pleamar-wm
  `win.$i.urgent`, `session.plm:2447`), ale okno na inej ploche nikto nevidí. Vo Windows 11 bliká tlačidlo na lište,
- `hyprctl` `clients()` pole `urgent` ani nehlási.

Zvuk funguje (`tell_sound` → `latte.win.sounding` → `snd.N`).

**F2 — Ponuka okna z ikry** · vysoká (v commite), v pracovnom strome rozpracované
- V commite 3480ee8d9 `hyprctl` `emits()` nemal `snap` ani `pin` (a pôvodne ani `to_desk` / `to_screen`), takže
  sedem položiek Rozloženia a „Vždy navrchu“ iba zapísalo „nothing for“ do stderr. To porušuje pravidlo 8.
  Pracovný strom ich na pleamar-wm skrýva (`wm.luau` `M.can`, `bar.luau:118–126`); treba to dokončiť a zapísať.
- `bar.luau:112`: „Obnoviť“ pre okno, ktoré nie je odložené, volá `restore`, a to most mení na `latte_focus`
  (`hyprctl:168`). Zväčšené okno sa teda neobnoví na pôvodnú veľkosť (vo Windows 11 „Obnoviť“ zmenšuje).
- `hyprctl:99–100`: `pinned` je vždy `False` a `fullscreen` iba 0 alebo 2. `wm.luau` ráta `maximized = c.fullscreen == 1`,
  takže `maximized` je vždy nepravda a „Maximalizovať“ nie je nikdy zošednuté.
- `bar.luau:105`: „Plocha 1–4“ je pevne, kým plochy pleamar-wm sú dynamické (prázdna mimo poslednej vyschne).
  Čo spraví „Plocha 4“, keď existuje jedna, treba overiť.

**F3 — Pás pre kvapky nejde za lištou** · stredná
`wm.luau` `M.band` posiela `latte.band("left"…)`, ale `hyprctl` to nepozná (`steps is None`, r. 459, výslovný
ponytail 1D.06–09). `session.plm:69` má `let latte.band = 54` pevne dole. BarGoo presunutá k inému okraju
(povolené ťahaním, `bargoo.luau` hlavička) tak nemá voľný pás a okná ju prekryjú. LATTEOS-GOO §8 sľubuje opak.
K tomu `bar.luau:350–353`: pri každom `window_mode` mimo dolného okraja ide nové volanie, čo znamená ďalší
proces Pythonu a riadok „nothing for“.

**F4 — Režim okien vidí iba hlavný monitor** · stredná
`hyprctl:316–317` (`apply_modes`) pošle `emit window_mode` iba za monitor v bode 0,0, a to cez `latte-say`, ktorý
dôjde **všetkým** scénam Goo. Pri vlastnom režime monitora (`own`, Nastavenia › Okná › mapa monitorov) ukazuje
hlava na druhom monitore režim hlavného a podľa neho rozhoduje aj `berries_out()`. Keď žiadny monitor nie je v 0,0
(rozloženie zarovnané inak), neprijme `window_mode` nikto. `bin/latte-screens:11–12` pritom vyberá hlavný monitor
iným pravidlom (skutočný pred virtuálnym, potom 0,0, inak najľavejší).

**F5 — Hlava prechádza aj cez Glance, ktorý je pozastavený** · stredná
`hyprctl:278` `ORDER` obsahuje `glance` a `LAYOUT["glance"]` je to isté ako plávajúce (ponytail 8A). Štvrtý klik na
hlavu ukáže „Glance“, okná sa nezmenia a piaty klik vráti pásku. Pre používateľa je to tlačidlo, ktoré „nič neurobí“.

**F6 — Voľba Správa úloh sa po novom načítaní scény pleamar-wm nepošle znova** · stredná
`engine.luau:985–986`: `wm.taskbar(bar)` sa pošle iba pri zmene hodnoty (`bar_told`), a `wm.coffee` iba pri štarte
Goo a pri `coffee_changed`. Scéna pleamar-wm po novom načítaní začína s `dock.off = 0`, `win.nomin = 0` a
`dkc.water/milk = 0`. Miesto doku sa po oprave 21. 11. dorovná (`dock_wm_at`/`pin`, `engine.luau:1055`), tieto
fakty nie. Pri BarGoo sa tak ukáže aj DockShore (dve lišty), pri „nič“ sa vrátia tlačidlá Minimalizovať a dok
na druhom monitore má farbu espressa namiesto zvolenej kávy.

**F7 — DockShore: klik na aplikáciu vpredu ju neminimalizuje** · stredná
`session.plm:1536`: `dock j on s`. Podľa `pleamar-wm --docs reference` (`dock k`) to dá dopredu ďalšie okno
programu, nie minimalizovanie. Vo Windows 11 klik na aktívnu aplikáciu na lište okno schová. BarGoo to robí
(`toggle`), DockShore nie, takže pri prepnutí BarGoo ↔ DockShore sa svalová pamäť rozíde.

**F8 — Win+1…9 nesedí s poradím ikon** · stredná
`hyprctl:244–262` (`many_windows`, `win.nth`) zoskupí okná podľa triedy v poradí slotov, s ponytailom „poradie,
ktoré používateľ ťahal v lište, tu nie je známe“. Pri DockShore sú pripnuté programy prvé, takže Win+1 otvorí iný
program, než je prvá ikona. Pri BarGoo zase nesedí poradie, ktoré si používateľ poťahal (`order`).

**F9 — DockShore: najviac 12 položiek bez pretečenia** · stredná
`session.plm:1487` a ďalšie `repeat j in 0..12`: trinásta aplikácia na doku nie je a jej okná sa z doku nedajú
otvoriť. Pleamar-wm spravuje najviac 16 okien a 4 monitory (`windows win max 16`, `screens: each max 4`). Tieto
stropy nikde v Nastaveniach ani v dokumentoch nie sú.

**F10 — Poradie aplikácií v BarGoo sa po reštarte Goo stratí** · nízka
`bar.luau:46` `order` je iba v pamäti (`M.reorder`, r. 328–343). Po reštarte Goo, novom prihlásení alebo páde je
poradie preč. Pripnuté poradie vo Windows 11 ostáva.

**F11 — Voľba v Nastaveniach zapisuje dvakrát** · nízka
`settings.qml:1134–1136` `choose()` volá `goo.set("taskbar")` a potom `goo.set("hidden")`. Goo číta po každom
zápise (`sys.watch`), takže na chvíľu môže poslať nesprávne `latte.taskbar(…)` (napr. „nič“ s ešte viditeľnou
BarGoo = 0, potom 2). Patrí k Poradiu A.4 (E11, atomické zápisy). Stačí `goo.setMany`.

**F12 — Zastarané texty po 23. 11. (dok na každom monitore v každom režime, commit 1a8a66113)** · nízka
- `settings.qml:1019` „On a tiled monitor there is no dock: Super+W makes it free.“ (už neplatí),
- `settings.qml:1135` „the dock on the edge of a free monitor“, `:999` „The shore of a free monitor…“,
- ROADMAP 6.41 „Dok sa ďalej ukazuje iba pri voľných oknách“,
- komentár v `session.plm` nad dokom („Tiled, there is no shore“), čo je text pôvodného autora.

**F13 — Rozpory v špecifikácii** · nízka (dokumenty)
- Ľavý klik na hlavu: ROZHRANIE a LATTEOS-GOO §4 píšu „ďalší režim“, ROZHODNUTIA r. 406 (27. 10.) ho mení na prehľad
  úloh ako Win+Tab (6A.08, otvorené). Treba zapísať, čo platí do 0.6.
- LATTEOS-GOO §4.1 sľubuje nastavenie `reversed` (smer ikier od hlavy), ktoré v `bar.luau` nie je.
- GOOENGINE-2 §11.2 hovorí, že DockShore sa vysúva podľa §9.4 a voľba je v „Nastavenia › Okná › Lišta okien“.
  Rozhodnutie z 13. 11. (doska sa nevysúva) a kód (Nastavenia › Kvapky › Správa úloh) hovoria inak.
- LATTEOS-GOO §4.1 „48 miest“ proti kódu 24 a proti stropu pleamar-wm 16 okien (D9).

**F14 — Výkon: obnovovanie zoznamu okien** · stredná (výkon; po 0.6)
`bar.luau:473` `every(2000, M.refresh)` v každej scéne Goo (hlavná + jedna na každý ďalší monitor) spustí
`hyprctl --batch "j/clients ; j/activewindow ; j/monitors"`, teda nový proces Pythonu. `hyprctl:135–136`:
`activewindow` volá `clients()` druhýkrát, takže jedno obnovenie urobí 2× `clients()` a 4× `monitors()`. Každé
`clients()` je 16 + 8 · N otázok na socket (každá „čaká na snímku“) plus `describe`. Pri 10 oknách je to rádovo
200 otázok každé 2 s v každej scéne. Bočná scéna navyše ide ďalej, aj keď je BarGoo vypnutá (DockShore / nič)
a scéna nemá čo ukázať. Odmerať (`pleamar --report`) a až potom rozhodnúť.

**F15 — Mŕtvy kód a zvyšky po Hyprlande** · nízka
- `wm.luau:1–3` hlavička odkazuje na `system/hypr/latte/windows.lua`, ktorý už neexistuje,
- `M.can.snap/pin = not ON_PLEAMARWM` (pracovný strom): mimo pleamar-wm už LatteOS GOO nebeží, takže vetva
  s Rozložením je dnes mŕtva (zámerne, kým nebude 1D.06–09),
- `born.luau` / `bubble.plm` (bublina okna) iba čakajú, LATTEOS-GOO §8 to priznáva („v pleamar-wm zatiaľ nie“).

### Okrajové prípady (overené čítaním)

| Prípad | Čo sa stane |
|---|---|
| 0 okien | Hlava bez čísla, `still = false`, sadne si; koliesko nič (bez vibrácie). V poriadku. |
| 17+ okien | pleamar-wm ich viac nespravuje (`max 16`), BarGoo aj DockShore ich nevidia. |
| 13+ aplikácií | BarGoo ich zmenší (D1), DockShore ich neukáže (F9). |
| Minimalizované | Ikra stlmená a menšia; bez pádu do lišty (F1). V páske je v ponuke Minimalizovať zošednuté, ale klik na ikru vpredu okno predsa minimalizuje (`toggle` → `window_minimize`, ktorý v `session.plm:3467` platí v každom režime). |
| Celá obrazovka | `E.busy` (r. 461–465) zastaví počasie; lišta ostáva pod oknom (správne). |
| Dva monitory | Vlastná BarGoo, okná podľa `here`; režim hlavného monitora (F4); dok na každom, Goo nesie iba index 0. |
| Odpojený monitor | `latte-screens` zastaví bočnú scénu a pri zmene hlavného reštartuje Goo; dok `s < screens.count`. |
| Reštart Goo | Režim sa pýta (`wm.tell_mode`), dok sa pýta (`wm.tell_dock`), voľba sa pošle znova (`bar_told = nil`); stratí sa `order` (F10). |
| Reštart scény pleamar-wm | Miesto doku sa dorovná, voľba Správa úloh a káva nie (F6). |
| `hyprctl` zamrzne | `bar.luau` `asked` ostane `true` a lišta sa už neobnoví (r. 425–428, bez časového limitu). Iba podozrenie, nepozorované. |

---

## Návrh dokončenia

Poradie práce: **do 0.6 iba opravy** (ROADMAP „Poradie práce“). Za opravu tu považujem všetko, čo plní už
zapísané pravidlo alebo sľub (§2, §4, §8, rozhodnutia), alebo odstraňuje regresiu. Nové správanie a optimalizácie
idú za 0.6 (podľa A.5 používateľ posúva za 0.6 aj optimalizácie).

### Pred 0.6 — opravy (od najdôležitejšej)

1. **Pád do lišty a pozornosť späť (F1).** V `session.plm` (blok `// LatteOS:`) pri minimalizovaní okna
   `launch "latte-say 'fact win.x …' 'fact win.y …' 'fact win.w …' 'fact win.h …' 'fact win.on {screen}' 'emit win_min'"`
   a pri `win.$i.urgent` → `'text win_wants 0x{slot}' 'emit win_urgent'`. Goo strana je hotová (`bar.luau`).
   ROADMAP 6A.01 prepnúť na `[~]`, kým sa to neoverí. *Súbory:* `system/pleamarwm/wm/session.plm`, `ROADMAP.md`.
2. **Ponuka okna dokončiť (F2).** Zapísať rozpracované `wm.can` (skryté Rozloženie a Vždy navrchu). „Obnoviť“ pre
   zväčšené okno poslať ako `maximize` (prepína), alebo položku ukázať iba pri odloženom okne. Pre „Plochu“
   zobraziť `win.pools` + 1 namiesto pevných 1–4 (most to už vie zistiť, `hyprctl` `to_desk`).
   *Súbory:* `goo/lib/bar.luau`, `goo/lib/wm.luau`, `system/pleamarwm/bin/hyprctl`.
3. **Ikry a dosky Shore (D2, D1).** V `engine.luau` vystaviť „kde sa okraj od tejto drobnosti ďalej končí“
   (najbližší `blocks` úsek za hlavou alebo `limit`) a v `bar.luau:218` ho použiť namiesto `E.limit`. Zmenšovanie
   zastaviť na polomere ~14 px (`f` aj `r` rovnako) a to, čo sa nezmestí, dať do ikry „Ďalšie okná“, ktorá už
   existuje (`rest`). *Súbory:* `goo/lib/engine.luau`, `goo/lib/bar.luau`.
4. **Pás za lištou (F3).** Buď (a) most: `latte.band(edge, screen)` → `fact latte.edge.N`, a v `session.plm` šesť
   miest, kde sa odpočítava `latte.band` (r. 571, 1876, 1938, 1956, 2041, 3022, 3194), počítať podľa okraja; alebo
   (b) menšia oprava: na pleamar-wm BarGoo neodlepiť od dolného okraja (`returns` k dolnému) a `M.band` nevolať.
   Odporúčam (a), lebo sľub je v §8. *Súbory:* `hyprctl`, `session.plm` (alebo `bargoo.luau`, `bar.luau`).
5. **Režim pre každý monitor (F4).** `apply_modes` pošle všetkým scénam jeden text, napr.
   `text window_modes "DP-1=0 HDMI-A-1=1"`, a `bar.luau` si z neho vezme svoj monitor (`wm.luau` už pozná `SCREEN`).
   Udalosť `window_mode` nechať pre spätnú kompatibilitu. *Súbory:* `hyprctl`, `goo/lib/bar.luau`,
   `goo/parts/drops.plm` + `goo/side.plm` (deklarácia textu).
6. **Glance z kolotoča hlavy (F5).** `ORDER = ("tape", "tiles", "floating")`, kým nebude 8A. *Súbor:* `hyprctl`.
7. **Voľba Správa úloh po reštarte pleamar-wm (F6).** Do hlásenia doku (`session.plm:1414`) pridať
   `'fact dock_wm_off {dock.off}'` a v `engine.luau` `dock_moved` pri nezhode znova poslať `wm.taskbar(bar_told)`
   a `wm.coffee(water, milk)`. To isté urobí aj ďalší reštart. *Súbory:* `session.plm`, `goo/parts/drops.plm`,
   `goo/lib/engine.luau`.
8. **DockShore po slovensky (D4).** Pridať do `session.plm` `translations sk { … }` (alebo `import` knižnice
   s prekladmi, ak to pleamar-wm dovolí; jazyk 0.1 to overiť cez `pleamar --check`). Pri tom zmeniť „Keep on the
   shore“ na „Pin to DockShore“ / „Pripnúť na DockShore“. *Súbory:* `system/pleamarwm/wm/session.plm`.
9. **DockShore ako lišta Windows 11 (F7).** `on release dockz…` keď má program jedno okno a to je vpredu:
   `minimize` namiesto `dock j on s`. *Súbor:* `session.plm`.
10. **Kontrast DockShore (D5).** `let dkc.lite = dkc.milk > 0.6` a podľa neho tmavé písmo (`#2a1a10`) a tmavšia
    bodka, ako `card.lite` v Goo (6.52). *Súbor:* `session.plm`.
11. **Win+1…9 podľa toho, čo je na obrazovke (F8).** Pri DockShore: v moste udalosť `latte_dock_nth n` →
    v `session.plm` `dock (n − 1) on mon`. Pri BarGoo stačí do 0.6 zapísať obmedzenie (ponytail už je).
    *Súbory:* `hyprctl`, `session.plm`.
12. **Drobnosti (D7, D8, F10, F11, F12).** `show_mode()` pri štarte; v Dlaždiciach koliesko na hlave → `d:shiver()`;
    `order` ukladať do `places.json` alebo do nastavení; `choose()` cez `goo.setMany`; opraviť texty v
    `settings.qml` (r. 999, 1019, 1135) a ich preklady. *Súbory:* `goo/lib/bar.luau`, `goo/drops/bargoo.luau`,
    `apps/settings.qml`, preklady Nastavení.
13. **Dokumenty (F13, D9, F9).** ROZHRANIE + §4: ľavý klik „ďalší režim do 0.6, potom 6A.08“; §4.1 bez
    `reversed` a „48 miest“ → „najviac 16 okien (pleamar-wm)“; GOOENGINE-2 §11.2 podľa rozhodnutia z 13. 11.;
    ROADMAP 6.41 a 1D.25 bez „iba pri voľných oknách“. *Súbory:* `LATTEOS-GOO.md`, `docs/goo/ROZHRANIE.md`,
    `docs/goo/GOOENGINE-2.md`, `ROADMAP.md`.

### Po 0.6 — nové funkcie a optimalizácie

- **6A.08 Prehľad úloh z hlavy** (ako Win+Tab, cez všetky monitory, tlačidlá režimu pri každom).
- **Živý náhľad okna nad ikrou** (ROZHODNUTIA r. 78, 1D.25: „prebrať náhľad zo shore aj do BarGoo“). Dok to už má
  (`pv`, 450 ms), takže sa dá požičať jeho kreslenie.
- **Rozloženie (snap) a Vždy navrchu v pleamar-wm** (1D.06–09), potom vrátiť položky ponuky (`wm.can`).
- **Prenášanie ikier medzi monitormi** (6A.07), ťahanie súboru na ikru (okno vpredu, ako vo Windows),
  odznaky na ikrách (počet z `win.dock.*.badge`, ktorý dok už má).
- **DockShore na druhom monitore ako hmota Goo**: bočná scéna dostane dok svojho monitora (`dock_*` podľa indexu),
  kreslí dosku sama a nesie ju s Alt; Goo povie pleamar-wm index hlavného monitora (ponytail `session.plm:1494`).
- **Pretečenie doku nad 12 položiek** („…“ s kartou), rovnako ako ikra „Ďalšie okná“.
- **Výkon (F14):** v `hyprctl` raz `clients()` na jedno volanie (`activewindow` z toho istého zoznamu); bočná scéna
  bez obnovovania pri vypnutej BarGoo; namiesto 2 s pollingu zmeny z `sys.watch("window")` + pomalší záložný polling.
- **Klávesnica (D10):** Win+T vytiahne ikry pri prechode cez hlavu; dok ovládateľný šípkami.
- Nastavenie `reversed` (ak ho používateľ ešte chce), obrázok BarGoo do Nastavení (6.41, dnes chýba
  `apps/settings/drops/bargoo.png`).

---

## Na overenie naživo

1. **Minimalizácia plávajúceho okna:** spadne kvapka do BarGoo? (Podľa kódu nie, F1.) Okno na inej ploche, ktoré
   chce pozornosť (napr. správa v aplikácii): zavlní sa hlava?
2. **`sys.watch("window")` na pleamar-wm:** objaví sa ikra hneď po otvorení okna, alebo až do 2 s (polling)?
3. **BarGoo + LensShore (aj AppCloud, TrayShore prenesená s Alt)** a 6–10 aplikácií v plávajúcom režime: ležia
   strapce pod doskou? Aké malé sú pri 1024 × 768 (D1, D2)?
4. **BarGoo potiahnutá na ľavý / horný okraj:** nechajú jej okná pás? (Podľa kódu nie, F3.)
5. **Dva monitory s rôznym režimom** (mapa monitorov v Nastaveniach): akú ikonu režimu má hlava na druhom
   monitore (F4)? A **hlavný monitor, ktorý nie je index 0** v pleamar-wm (zapojenie káblov naopak): nie je doska doku
   dvakrát na jednom monitore a nahá na druhom (bughunt 22. 11. „DockShore dvojitý“)?
6. **Nové načítanie `session.plm` pri voľbe BarGoo, potom „nič“:** ukáže sa dok, vrátia sa tlačidlá
   Minimalizovať (F6)?
7. **Voľba „nič“:** Win+D, Super+M a Super+Down; dajú sa odložené okná vrátiť? Zahŕňa ich Alt+Tab (`focus_next`)?
8. **Ponuka okna › Presunúť na plochu › Plocha 4**, keď existuje jedna plocha. A „Obnoviť“ pri zväčšenom okne.
9. **DockShore pri pridávaní aplikácií:** dobieha dĺžka dosky Goo za ikonami (1D.25 „o jedno `latte-say`“)?
   Klik na aplikáciu vpredu (F7) a Win+1 pri pripnutých programoch (F8).
10. **DockShore na káve Latte:** čitateľnosť menoviek, ponuky a bodiek (D5); pri sklenenom materiáli hlavný
    proti druhému monitoru (D6).
11. **Pulz okraja okna** (zvuk / pozornosť) **na druhom monitore:** hodiny `edgeclock` sa točia iba pri
    `screen.index == 0` (`session.plm:338`). Ide pulz aj na monitore 1?
12. **Záťaž:** `pleamar --report` s 10 oknami a dvoma monitormi; koľko berie `hyprctl` každé 2 s (F14).
