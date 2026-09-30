# LatteOS Goo (plocha Kvapky)

Spoločný dokument pre používateľa (autora LatteOS) a Clauda: **čo LatteOS Goo je, ako sa má správať a z čoho sa
skladá**. Platí nezávisle od konverzácie. Pred prácou na Goo ho treba prečítať, a keď sa niečo rozhodne,
zapísať ho sem (s dátumom). Technické detaily a zoznam hotových funkcií sú v
[session/kvapky/README.md](session/kvapky/README.md), plán v [ROADMAP.md](ROADMAP.md).

---

## 1. Čo to je

LatteOS Goo (relácia **„LatteOS Kvapky“**) je plocha LatteOS pre ľudí zvyknutých na **Windows 11**, kde lištu,
Štart, hodiny a systémové prvky nahrádzajú **tekuté kávové kvapky**. Kvapky sa správajú ako **sliz v nízkej
gravitácii**: pružia, lepia sa k okraju obrazovky aj k sebe, naťahujú sa a praskajú, žijú vlastným pohybom a
reagujú na kurzor ako živý tvor.

Stojí na:

| vrstva | čo robí | kde |
|---|---|---|
| **Hyprland 0.56** (Lua) | okná, režimy okien (páska, dlaždice, plávajúce), animácie | `session/hypr/` |
| **pleamar 0.2.2** (Rust, SDF, goo) | kreslí všetky kvapky, spúšťač, logika v Luau | `session/kvapky/kvapka.plm`, `kvapka.luau` |
| **Noctalia 5** | ovládacie centrum, panely, widgety a doplnky v rohovej lište, zvuk, sieť, relácia | záplatovaná kópia iba pre Kvapky |
| **latte-kvapky** | štart plochy, konfigurácia Noctalie pre Kvapky, pomocné príkazy | `session/bin/latte-kvapky` |

Názvy: **Goo / Kvapky** = celá plocha; **Goobar** = lišta s oknami (hlava + guľôčky); **kvapka** = každý
samostatný tekutý prvok.

---

## 2. Pravidlá (od používateľa — platia vždy)

1. **Myš je prvá, klávesy iba doplnok.** Každá funkcia musí ísť myšou (klik, ťahanie, koliesko). Super = kláves Windows.
2. **Návyky z Windows 11** rozhodujú: všetko je **dole**, klik na okno v lište prepne/minimalizuje, pravý klik na
   okno = ponuka okna, ťahanie ľavým ako vo Windows. Horná kvapka ako v Marei bola **zamietnutá** (návyk z Windows).
3. **Preberať, nevymýšľať:** najprv hotové riešenie (Noctalia, pleamar, Marea), až potom vlastné.
4. **Preložiteľné:** texty v UI po anglicky + preklad (`translations sk` v scéne, `tr()` v logike), nikdy natvrdo po slovensky.
5. **Každé prostredie má svoje nastavenia:** Goo, klasický LatteOS, pôvodná Noctalia a cudzie prostredia (Plasma…)
   sa navzájom nepoškodzujú (`latte-profil`, oddelené priečinky Noctalie).
6. **Kvapky sú vždy káva.** Téma LatteOS = šálka (materiál okien); obsah = káva s pomerom **vody a mlieka**
   (Barista). Vodová káva (lungo, americano) je sklo, espresso a mliečne kávy nepriehľadné.
7. **Kvapky nemajú oči** (ani žiadnu tvár). Hodiny sú **digitálne** (ručičkové hodiny Marey sa nepreberajú).
8. **Kontextový klik iba tam, kde ho má funkcia.** Ak funkcia kvapky nemá pravý (ľavý) klik, nemá ho ani kvapka.
   Pravý klik v Goobare má zmysel iba na **guľôčkach okien** (ponuka okna, ako vo Windows).
9. **Okno sa zjaví tam, kde je kvapka:** okno/panel z kvapky vyrastie presne nad miestom kvapky na okraji
   (kvapky sa dajú presúvať — musí to platiť kdekoľvek).

---

## 3. Fyzika a správanie kvapiek

- **Nízka gravitácia, pružnosť:** kvapky pružia (pružiny pleamaru), zlievajú sa (smooth-min „goo“), dýchajú a
  pomaly driftujú aj bez myši — **neustály vlastný pohyb, nie útek**; vzájomné pôsobenie iba v blízkosti.
- **Lepia sa k okraju a k sebe.** Lišta sa od okraja **sama nikdy neodlepí** — iba keď ju používateľ ťahá.
  Strapce okien sú príliš ťažké na to, aby sa odlepili.
- **Vlákna ako sliz:** keď sa kvapka vzďaľuje (ťahaná guľôčka, Hodiny letiace do ucha), vlákno sa **naťahuje a
  tenčí** a **po určitej dĺžke praskne** (konce sa stiahnu); pri návrate sa znova zlepí.
- **Hladina pri okraji** (z Marey): okraj obrazovky je voda — keď kvapka odíde alebo sa vráti, hladina sa prehne a
  po nej sa rozbehnú **dve vlnky**; po prasknutí krku ostane chvíľu **zvyšková kvapka**.
- **Pohyb kolmo na okraj:** kvapka vystúpi **kolmo od okraja**, späť **padne rovno ako pod ťarchou**, s
  prestrelením a odrazom („odkvapne“), zachveje sa.
- **Živý tvor:** kurzor je pre kvapky to, **po čom túžia** — keď sa priblíži, kvapka sa k nemu **nakloní** (venuje
  mu pozornosť); keď je nad ňou, **mierne sa nafúkne a netrpezlivo pulzuje**. Tvár/obsah sa hoverom **nemení**.
- **Svetlo:** pasívne svetlo v ploche (zhora vľavo, odlesky) + **kurzor ako aktívne svetlo** (svetlá škvrna na
  povrchu, odlesk na strane ku kurzoru; pri skle `shine: pointer`).
- **Nesúmernosť:** nič nie je dokonale pravidelné (šum, rôzne veľkosti, cik-cak strapcov).
- **Neprekrývať okná:** kvapky sa pod oknom zmestia do voľného pásu; strapec sa zhromaždí do výšky iba tam, kde
  nad ním nie je okno, inak sa stiahne k okraju.

---

## 4. Časti plochy a ich správanie

### 4.1 Goobar (lišta s oknami) — dole, naľavo od stredu
- **Hlava** (najväčšia kvapka): obraz aktuálneho režimu okien (páska / nad sebou / dlaždice).
  - ľavý klik = ďalší režim okien; koliesko = páska sa posúva (páska) / ďalšie okno (plávajúce)
  - ťahanie ľavým = presun lišty k inému okraju (pustená uprostred steká späť); pravý klik = nič
- **Guľôčky okien** (strapce po aplikáciách ako ikry; čím viac okien, tým menšie):
  - ľavý klik = prepnúť, aktívne minimalizovať (v **páske** sa neminimalizuje — ako niri)
  - pravý klik = ponuka okna pri kurzore; ťahanie = preusporiadanie aplikácií (vlákno ako sliz)
  - minimalizované okno = menšia, stlmená guľôčka; 48 slotov, nad nimi guľôčka „ďalšie okná“ → prehľad
- Šnúra sa vždy zmestí po kraj (a zastaví sa pred rohovou lištou a kvapkami widgetov).

### 4.2 TimeGoo (Hodiny, Štart) — vľavo pri hlave
- Digitálny čas a dátum. (Upozornenia sa presúvajú do DaNoGoo — 1. 10.; dnes ešte kvapôčky na Hodinách.)
- **Ľavý klik alebo kláves Win** = **spúšťač**: kvapka vystúpi kolmo, stane sa **trčiacim uchom v rohu okna**
  (s časom), okno z nej vyrastie. Zatvorenie (klik inde, Esc) = okno sa zloží do ucha, ucho odkvapne domov.
- **Pravý klik** = časové menu (1. 10.): záložka **Čas** z klasického LatteOS (`latteos/time:panel cas`) —
  časové pásma, stopky, minútka, budíky, počasie — a **well-being**.
- **Well-being = existujúca Digitálna pohoda** z klasického LatteOS (`session/apps/pohoda.qml`, inšpirovaná
  Serpantinumom; dáta `~/.local/share/latteos/pohoda/RRRR-MM-DD.json`, podrobnosti v Monitore › Čas v
  aplikáciách). Nič nové sa nevymýšľa: v Kvapkách beží tiež (predtým ju `latte-kvapky` vypínal), v záložke Čas
  je súhrn dneška (čas pred obrazovkou, 3 najpoužívanejšie aplikácie) a tlačidlo „Podrobnosti v Monitore“ (1. 10.).

### 4.2b DaNoGoo (dátum + upozornenia) — samostatná kvapka, dá sa presúvať (návrh 1. 10.)
- **Viditeľný obsah:** dátum a počasie.
- **Guľky počtu upozornení:** systémové výstrahy vlastná **červeno-kávová** guľka (+ číslo, ak ich je viac);
  ostatné jednotne **žlté**, viac guliek podľa počtu.
- **Ľavý klik** = kvapka **vystrelí ako pružina** kolmo od okraja a za sebou nechá **hrozno upozornení** na
  lepkavom vlákne (najnovšie hore). Hrozno prekrýva okná, kým sa klikom na DaNoGoo nevráti dole.
  Bobule = kapsuly (ikona, aplikácia, nadpis); ľavý klik otvorí, pravý iba ak má upozornenie akcie, odhodenie = zahodiť.
  Farby: systémové/varovné červeno-kávové, nedôležité obyčajná káva, aplikácie podľa ikony — **otvorené:**
  čistá farba ikony, alebo káva zafarbená do nej; zatvárať aj Esc / klikom mimo?
- **Pravý klik** = záložka **Kalendár** z klasického LatteOS (`latteos/time:panel kalendar`): mesiac, plánovač
  udalostí, úlohy, prepojené kalendáre (Google, iCloud, CalDAV, ICS cez Noctaliu).

### 4.3 Spúšťač (okno z Hodín)
- **Hľadanie** (jedno pole): aplikácie · súbory (`fd`) · web (predvolený vyhľadávač) · otázka pre **AI** (webové
  čety, ktoré prevezmú otázku z adresy: ChatGPT, Claude, Perplexity, Copilot, Le Chat, Google AI). Vpravo druh riadku.
- **Záložky** s obľúbenými aplikáciami, **pomenované používateľom** (Programy, Hry…); „+“ pridá.
- Pravý klik: aplikácia → pridať do záložky; web → vyhľadávač; AI → ktoré čety; záložka → premenovať/posunúť/odstrániť.
- Bez textu: upozornenia a nápoveda. Zámerne **nie** katalóg aplikácií ani prepínanie okien (to robí Goobar).
- Nastavenia: `~/.config/latteos/spustac.json`.

### 4.4 PowerGoo (vypínač) — vľavo od Hodín
- Ľavý klik = ponuka (Zamknúť, Odhlásiť, Uspať, Reštartovať, Vypnúť) ako kapsuly zliate do stĺpca; akcie robí Noctalia.
- **Batéria (notebook, 1. 10.):** minibublinky zelená → žltá → červená (návrh: aj počtom 3/2/1, pod 10 %
  netrpezlivo pulzuje, pri nabíjaní stúpajú do kvapky); na stolnom PC žiadne.

### 4.5 Rohová lišta Noctalie — vpravo dole
- Iba **pravá časť** lišty Noctalie, **natvrdo prilepená** do rohu, **šírka podľa počtu widgetov**; vpravo sa
  vyduje do bočnej steny, vľavo sa rozleje po spodnom okraji.
- Obsahuje ikony programov na pozadí (Discord…), sieť, hlasitosť, ovládacie centrum; **ďalšie widgety a komunitné
  doplnky** Noctalie sa pridávajú v jej nastaveniach a bežia natívne.
- Kliky widgetov presne podľa Noctalie. Panely sa otvárajú pri lište.
- Plán: priehľadné pozadie + goo telo z pleamaru pod ňou (vlnenie celej lišty pri zmene stavu, pulzovanie).

### 4.6 Samostatné kvapky (widgety, ikony programov)
- Mechanizmus pre **iné veci** (napr. rozbaľovacia ponuka rýchleho spúšťania); predvolene žiadne.
- Visia z okraja, **ťahaním sa presúvajú** k inému okraju (prilepia sa), pustené uprostred stečú (odstránia sa);
  pridať cez spúšťač. Kliky podľa Noctalie; panel sa otvorí pri kvapke.

### 4.7 Okná (Hyprland)
- Režimy: **nekonečná páska** (ako niri: nič sa neminimalizuje, pohyb animovaný aj bez efektov, dlaždice v páske
  ťahaním za titulok), **dlaždice**, **plávajúce** (ako Windows).
- Okná neprekrývajú lištu (vyhradený pás pri okraji), maximalizované tiež.

### 4.8 Mimo plochy
- Prihlasovacia obrazovka latteGoo s výberom relácie; Sunshine beží už pred prihlásením (virtuálny monitor EDID).
- Relácie na pokusy: Noctalia (čistá), Marea (pleamar-wm / Hyprland), Serpantinum — oddelené od LatteOS.

---

## 5. Čo bolo zamietnuté (a prečo)

| nápad | rozhodnutie |
|---|---|
| oči na kvapkách, tvár | nie (29. 9.) |
| horná kvapka ako Marea | nie — návyk z Windows: všetko dole (29. 9.) |
| textúry kvapiek, farby podľa témy | nie — kvapky sú vždy káva (voda/mlieko); textúry (zlato, ónyx, kov, ľad) iba ako návrh na neskôr |
| ručičkové hodiny + bočné okienko (Marea) | nie — digitálne hodiny v kvapke (30. 9.) |
| goo guľôčky vnútri dashboardu | nie — nepôsobili dobre (30. 9.) |
| klik odlepí lištu | nie — odlepí iba ťahanie |
| celý strapec sa fyzicky oddelí od okraja | nie — strapce sú ťažké, drží ich okraj |
| minimalizovanie v páske | nie — ako niri (30. 9.) |
| holý Hyprland a gamescope-session v zozname relácií | skryté — nedá sa z nich odísť myšou |
| kód komunitných doplnkov Noctalie v pleamare | nie — stav doplnku je v Noctalii; namiesto toho rohová lišta Noctalie |

---

## 6. Kde čo je (pre Clauda)

| čo | kde |
|---|---|
| scéna (kreslenie, pružiny, pravidlá, preklady) | `session/kvapky/kvapka.plm` |
| logika (okná, spúšťač, kvapky widgetov, počasie) | `session/kvapky/kvapka.luau` |
| počet guľôčok okien (goo telo nedovolí `repeat`) | `python3 session/kvapky/sloty.py N` + `SLOTS` v logike |
| kvapky widgetov | `python3 session/kvapky/widgety.py N` + `WMAX` v logike |
| štart plochy, Noctalia pre Kvapky, `uloz`, `panel-poloha`, `roh-sirka`, `okraj` | `session/bin/latte-kvapky` |
| relácia, profily prostredí | `session/bin/latte-session`, `latte-profil` |
| Hyprland (režimy okien, rezerva pri okraji, virtuálny monitor) | `session/hypr/hyprland.lua`, `session/hypr/latte/*.lua` |
| záplaty pleamaru / Noctalie / pleamar-wm | `resources/patches/` (README tam) |
| nastavenia používateľa | `~/.config/latteos/` (kava, spustac.json, kvapky-widgety.json), `~/.local/state/latteos/` (kvapka-okraj, window-mode, kvapky/noctalia) |
| aktualizácie u autorov | `latte-upstream -v` |
| nasadenie na latte-lab | `sudo install … /usr/share/latteos/kvapky/`, reštart pleamaru; setup skripty v `setup/` |

**Skúšanie bez myši a monitora** (keď používateľ nie je prihlásený): headless `labwc` (`WLR_BACKENDS=headless`),
tapeta cez `swaybg`, scéna s oddeleným `HOME`; náhradný kurzor `pleamar --say kvapka "fact tcx 700"` / `tcy`,
`fact probe 55` (vysunutie lišty), `emit udalosť hodnota`; snímky `grim`, video `wf-recorder`. **Po teste všetko
zrušiť** (testovací pleamar sa volá rovnako `kvapka` — kolidoval by s reláciou používateľa) a zmazať mŕtve
sokety v `/run/user/1000/pleamar/`.

**Obmedzenia pleamaru**, na ktoré treba myslieť: v `body` nie je `repeat`/`for` (generátory); `let` a `prop` z
`repeat` nevidí `let` mimo neho; text sa vo výrazoch neporovnáva (fakt/bool); elipsa stlačená na nulovú výšku robí
chyby (neaktívne tvary nulovým polomerom); logika nevie zapisovať súbory (`latte-kvapky uloz`).

---

## 7. Otvorené

- DaNoGoo (4.2b), batéria na PowerGoo — rozhodnuté 1. 10., čaká na farby upozornení a zatváranie
- **Noctalia nemá slovenský katalóg** (`assets/translations/sk.json` nie je ani u autora, je český `cs.json`):
  pri `LANG=sk` prepne na angličtinu a `translations/sk.json` doplnkov nenačíta — nové texty doplnkov LatteOS
  (napr. well-being v záložke Čas) sú preto po anglicky. Riešenie: slovenský katalóg Noctalie (aj pre autora)

- goo telo z pleamaru pod rohovou lištou (vlnenie, pulzovanie pri zmene stavu widgetu)
- rozbaľovacia ponuka rýchleho spúšťania ako samostatné kvapky
- presúvanie Hodín a vypínača samostatne (dnes sa presúvajú s lištou) — čaká na rozhodnutie
- textúry šálky/témy (zlato, podsvietený ónyx, brúsený kov, ľad) — návrhy
- úspora výkonu (pleamar ~18 % jadra: prázdne sloty, 30 Hz v pokoji)
- vlnenie pri zmene stavu widgetu, pulzovanie pri udalostiach (upozornenie, zvuk, sťahovanie)
