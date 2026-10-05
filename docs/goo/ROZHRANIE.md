# LatteOS Goo — Rozhranie

Popis jednotlivých kvapiek a ich správania podľa **Novej architektúry** (rozhodnutie 5. 10. 2026).

*Úplný originál je v [LATTEOS-GOO.md](../../LATTEOS-GOO.md), časť „Nová Architektúra prostredia a rozhranie Goo“.
Staršie rozdelenie (TimeGoo, DaNoGoo, PowerGoo) je v §4 toho istého dokumentu a platí už iba pre scénu plochy
Kvapky, kým ju engine nenahradí.*

Stĺpec **Engine** hovorí, čo z toho už vie engine Goo (`session/goo`); zvyšok je zatiaľ iba v scéne Kvapky.

## Jadro — nedá sa skryť

### GooBar — hlavná lišta a správca okien

- **Hlava** (najväčšia kvapka): ikona režimu okien (páska / nad sebou / dlaždice)
  - Ľavý klik = ďalší režim
  - Koliesko = posun pásky (páska) alebo ďalšie okno (ako Alt+Tab)
  - Ťahanie = presun lišty k inému okraju (pustená uprostred sa vráti)
- **Ikry okien** (strapce po aplikáciách; menšie, aby sa nezamieňali s ostatnými)
  - Vyrastajú z hlavy doprava alebo nadol (`reversed` v Nastaveniach to otočí)
  - Čím viac okien, tým menšie; do výšky sa vrstvia iba okná tej istej aplikácie
  - Okno pri lište → ikry sa stiahnu nižšie
  - Ľavý klik = prepnúť / minimalizovať (v páske bez minimalizácie), pravý = ponuka okna, ťahanie = poradie
  - Minimalizované = menšie, stlmené; **48 miest**, potom zberná guľôčka
- GooBar sa s inými kvapkami spája iba zo strany, kde nevyrastajú ikry
- Lišta sa zmestí po kraj obrazovky a zastaví pred rohovými prvkami
- **Viac monitorov:** každá obrazovka má vlastný GooBar, okná sa dajú prenášať

**Engine:** hlava, ikry a strapce, uhýbanie oknám, klik, ponuka okna, poradie ťahaním, 48 miest.
**Chýba:** presun lišty k inému okraju, `reversed`, vlastný GooBar na každom monitore.

### GooPower — napájanie a monitor systému

- **Ľavý klik** = okno Goo spojené s kvapkou: Nastavenia, Monitor systému, a časť Noctalie — Zamknúť, Odhlásiť,
  Uspať, Reštartovať, Vypnúť
- **Batéria** (notebook): hlavička okna ukazuje percentá a nabíjanie; na kvapke bublinky —
  3 zelené ≥ 60 %, 2 žlté ≥ 30 %, 1 červená < 30 %; pod 10 % pulzuje; pri nabíjaní stúpajú a klesajú
- Na stolnom počítači bez indikátora

**Engine:** ponuka, hlavička s batériou, bublinky, pulz.

### LensGoo — univerzálny spúšťač a lupa

- Kvapka s lupou: vyhľadávač, spúšťač a rozhranie pre AI
- **Režimy** (klik na ikonu režimu, koliesko nad ňou, Tab; pamätá sa v `spustac.json`):
  Aplikácie · Súbory (`fd`) · Web · Terminál (`latte-terminal`) · AI Chat
- **AI** (`latte-ai`): rozhovor v goo bublinách priamo v spúšťači, **nikdy neotvára prehliadač**; bez kľúča API
  cez prihlásené nástroje (Claude Code, Gemini, Codex); bodka rozlišuje lokálny a cloudový model

**Engine:** kvapka s lupou na mieste Štartu, ľavý klik otvorí rýchle spustenie LatteOS.
**Chýba:** okno spúšťača z kvapky s režimami a AI (je v scéne Kvapky, `spustac.py`).

---

## Voliteľné — dajú sa zapnúť a vypnúť v Nastaveniach

### QueenGoo — App Manager a Správca zariadení

- Korunka na vonkajšej strane (tvar sa dá zmeniť v Nastaveniach)
- **Bodky:** červená = zariadenie potrebuje pozornosť, zelená = výpadok siete, modrá = aktualizácie
- **Ľavý klik** = App Manager (pri aktualizáciách rovno na nich), **pravý** = Správca zariadení (pri výpadku na Sieťach)
- Kvapka sa nestáva rohom okna: vypľuje bublinu, ktorá sa nafúkne na okno vedľa nej (1220 × 780)

**Engine:** bodky, oba kliky, okno vedľa kvapky. **Chýba:** korunka, let bubliny.

### ClockGoo — čas, kalendár, upozornenia a pohoda

Spája čas a centrum upozornení (predtým TimeGoo a DaNoGoo).

- **Ľavý klik** = upozornenia: kvapka sa vymrští a nechá visieť hrozno upozornení na lepkavom vlákne (najnovšie
  hore); zavrie klik na kvapku, Esc alebo klik mimo. Farby: výstrahy a systém červeno-kávové, nedôležité kávové,
  aplikácie farbou svojej ikony
- **Pravý klik** = karta času a kalendára na krku z kvapky:
  - digitálna pohoda (čas pred obrazovkou, tri najpoužívanejšie aplikácie, podrobnosti v Monitore)
  - svetové hodiny, stopky, minútka (koliesko), budíky (`casovace.json`, `clock.conf`)
  - kalendár od pondelka, udalosti a úlohy (CalDAV, Google, iCloud cez Noctaliu)
  - počasie Dnes / Zajtra / Týždeň

**Engine:** čas a dátum v kvapke, guľky počtu upozornení, ľavý = zoznam upozornení v ponuke, pravý = pohoda
a nastavenia času. **Chýba:** hrozno na vlákne, karta (stopky, minútka, budíky, kalendár, počasie).

### ChatGoo — Beeper

- Aktívna iba s nainštalovaným alebo bežiacim Beeperom; minimalizovaný Beeper „vtečie“ do kvapky
- Upozornenia Beepera idú z ClockGoo do ChatGoo; správy ako hrozno bublín s odznakom siete
- Pomocník `session/bin/latte-chatgoo`

**Engine:** zatiaľ nič.

---

## Návrhy ďalších kvapiek

ClipGoo (schránka), MediaGoo (prehrávač, MPRIS), PassGoo (heslá), CastGoo (streamovanie obrazovky).

---

## Rohová lišta (Noctalia)

- Iba **pravá časť** Noctalie, natvrdo prilepená v rohu
- Ikony programov na pozadí, sieť, hlasitosť, ovládacie centrum
- Plán: priehľadnosť + goo telo pod ňou

## Nastavenia › Kvapky (Goo)

- Jadro (GooBar, GooPower, LensGoo): iba veľkosť a vrátenie na miesto
- Voliteľné (QueenGoo, ClockGoo): klik na kartu = skryť / ukázať
- **Veľkosť:** 100–220 %, **Vrátiť na miesto**
- **ChatGoo:** kvapka, alebo ikona Beepera v rohovej lište
- **Vlastné kvapky:** názov, ikona, príkaz
- Súbor: `~/.config/latteos/kvapky.json` (číta sa každé 2 s)

---

## Ďalej

- [Pravidlá plochy](PRAVIDLA.md)
- [Engine — report](ENGINE-REPORT.md)
- [Originál v LATTEOS-GOO.md](../../LATTEOS-GOO.md)
