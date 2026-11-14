# Najnovší Raycast ↔ LensShore (vzhľad, funkcie, nastavenia, AI z LensAI)

Úloha 6B.47. Zostavené 14. 11. 2026. Dopĺňa `RAYCAST-PRO.md` (6B.45; ceny a plány tam).
Pravidlo (používateľ 14. 11.): Raycast funkcie používajú **predvolenú AI z LensAI**, žiadny vlastný poskytovateľ;
vzhľad a funkcie čo najbližšie najnovšiemu Raycastu; nastavenia Raycastu = položky v Nastavenia › LensShore.
Značky: **má** · **čiast.** · **chýba**.

## 1. Verzia a zdroje

| Čo | Hodnota | URL |
|---|---|---|
| Raycast pre macOS, najnovšia | **v2.11 (4. 11. 2026)** v zozname vyhľadávača; changelog stránka už ukazuje **v2.12 (13. 11. 2026)** | https://www.raycast.com/changelog |
| Raycast pre Windows | **v2.12 (13. 11. 2026)** | https://www.raycast.com/changelog/windows |
| Raycast pre iOS | v1.5.3 (6. 11. 2026) | https://raycast.com/changelog/ios |
| Manuál | oddiely Basics, Core, Power, AI | https://manual.raycast.com/ , https://manual.raycast.com/new-in-v2 |
| Cenník (otvorený 14. 11.) | Free 0 · Pro 10 $ (500 kr.) · Plus 20 $ (3 000) · Max 50 $ (7 500); Free bez AI | https://www.raycast.com/pricing |

Raycast 2.0 vyšiel 21. 8. 2026 (podľa RAYCAST-PRO.md; manuál: https://manual.raycast.com/new-in-v2). Čísla 2.5–2.12 sú
týždenné vydania (28. 9. – 13. 11.). Dev docs: https://developers.raycast.com/misc/changelog.

Zmeny v2.5–2.12 (iba čo sa týka nás): v2.12 prerobená Kalkulačka (počasie, lety, miesta, dátum/čas, jednotky; 60× rýchlejšia),
Search Arguments väčšie polia, Auto Dark Mode; v2.11 **Dictate to AI** (reč + kontext aktívnej aplikácie), AI Usage v lište,
Send Element/Window to AI; v2.10 poznámky s obrázkami a GIF, **neobmedzený počet poznámok vo Free**, @ v AI Chate z AI rozšírení;
v2.9 poznámky → AI Chat (⌘J), AI príkazy s „Default“ modelom; v2.8 AI Skills, rýchlejšie hľadanie, Greek v emoji; v2.7 vlastní poskytovatelia
(`providers.yaml`) s nástrojmi; v2.6 model **Auto** (Lightweight / Balanced / Flagship); v2.5 rozšírenia dodávajú vlastné modely,
Ctrl+M diktovanie v Quick AI, hľadanie aplikácií podľa alternatívnych mien.

## 2. Vzhľad (na napodobnenie)

Oficiálne snímky sú na https://www.raycast.com , https://manual.raycast.com/new-in-v2 a v zozname Extensions; do repa
sa nesťahujú (autorské práva). **Manuál nedáva rozmery, farby ani rozloženie riadkov** — čo je nižšie, je z manuálu
(spoľahlivé) alebo označené **[z pamäti / overiť na snímke]**.

| Prvok | Popis |
|---|---|
| Hlavné okno | Plávajúci panel uprostred obrazovky (obrazovka s myšou / s aktívnym oknom / primárna — nastavenie), v2 „Liquid Glass“: priesvitné sklo, jemný okraj, zaoblenie. Veľkosť rozhrania: Default / Large / Larger. Šírka ≈ 750 px, výška rastie podľa výsledkov, max ≈ 8–9 riadkov **[z pamäti]**. |
| Pole hľadania | Jeden riadok hore, vždy zaostrený; zástupný text podľa kontextu; vpravo tag aliasu / Tab „Ask AI“. Argumenty príkazu (max 3) ako malé polia v tom istom riadku (v2.12 väčšie), Ľavá/Pravá medzi nimi. |
| Zoznam (Root Search) | Sekcie s malými nadpismi (Favorites, Suggestions, Results, Commands, Applications, Files, Calendar…). Riadok: ikona 24–28 px vľavo · názov · tlmený podnázov · vpravo „accessories“ (tag aliasu, skratka, dátum, typ „Command“/„Application“). Vybraný riadok = zaoblená svetlá podložka. Prázdne pole: Favorites, naposledy použité súbory, dnešné udalosti kalendára. |
| Lišta akcií (⌘K / Ctrl+K) | Malý panel v pravom dolnom rohu nad pätou; hore pole „Search for actions…“; primárna akcia prvá; pomenované sekcie (Favorites, Configure, Deeplink, Manage); vpravo skratky; podmenu a vložené zobrazenia (nahrávač skratky); deštruktívne akcie červené; Esc späť. Písanie filtruje do jedného plochého zoznamu. |
| Päta (toolbar) | Dolný pás: vľavo logo/ikona rozšírenia, vpravo **primárna akcia** (↵ + názov) a „Actions ⌘K“ **[z pamäti; manuál ju nepopisuje]**. |
| Compact mode | Vidieť iba pole; výsledky sa rozbalia pri písaní alebo ⌘K; po strate zaostrenia sa okno zbalí; „Show Favorites in Compact Mode“ = obľúbené ako ikony. Nastavenie: General › Appearance › Window Mode. |
| Témy | Svetlá/tmavá, „Follow system“, samostatná svetlá a tmavá téma; Theme Studio (pozadie, primárne, podporné farby; URL na themes.ray.so, JSON). Auto Dark Mode (2.10, 2.12 s pauzou po ručnej zmene). Automatické úpravy kontrastu (2.6). |
| Quick AI | V okne hľadania: Tab z poľa → odpoveď streamuje na mieste; bloky kódu s tlačidlom Copy; „Show more“ pri dlhej správe; Add Context / `@`; výber modelu; ↵ vloží odpoveď do predchádzajúcej aplikácie; ⌘J → pokračovať v AI Chate. Kroky: ⌘R znova, ⇧⌘R iným modelom, ⌘N nový, ⌘[ ⌘] posun medzi chatmi, Ctrl+M diktovanie. |
| AI Chat | Samostatné okno: bočný panel (hľadanie, pripnuté, archív, projekty, premenovanie dvojklikom, vetvenie z ľubovoľnej správy), príloha (súbory, poznámky, schránka, karty prehliadača, udalosti, snímky), široké tabuľky, Mermaid, upozornenia po dokončení, Always on Top, zoom. |
| Poznámky | Malé plávajúce okno, jedna poznámka naraz „ako bloček“, prvý riadok = názov v hornej lište, Markdown, `/` menu, Format Bar dole (voliteľná), pripnuté ⌘0–⌘9, ⌘[ ⌘] história, ⌘P zoznam, obrázky/GIF, presúvateľné zoznamy, Recently Deleted. |
| História schránky | Hľadanie + filter ⌘P (Text, Images, Files, Links, Emails, Colors); ↵ vloží, ⌘↵ kopíruje, ⌘E premenovať, ⌘. pripnúť, ⌘X zmazať; „Paste as…“ (plain, RTF, HTML, PNG); manuál nespomína náhľadový panel (pravý panel s náhľadom je v UI dlhodobo **[overiť na snímke]**). |
| Správa okien | Bez vlastného okna: príkazy v hľadaní; mriežka (Toggle Grid Overlay), Create Layout editor (až 8 okien na displej). |
| Mriežky | Emoji & Symbols a Screenshots ako mriežka s nastaviteľným počtom stĺpcov (v2). |

## 3. Najnovšie funkcie (zoskupené)

| Oblasť | Čo Raycast má (stav 11/2026) |
|---|---|
| Hľadanie | Root Search: aplikácie, príkazy, súbory (nový index, filtre, obrázky), udalosti, kontakty, quicklinky, nastavenia, URL; frecency, aliasy, Search Sensitivity, Reset Ranking, fallback príkazy (aj Quick AI), História hľadania (↑), Favorites, hľadanie podľa alternatívnych mien; argumenty príkazov; inline kalkulačka a náhľad farieb; priame výsledky pre systémové nastavenia (2.6). |
| Kalkulačka | Prebudovaná v2.12: výrazy, jednotky, meny, dátum/čas, počasie, lety, miesta; `{calculator}` v úryvkoch. |
| AI: Quick AI | Viď vyššie; fallback pre všetko, čo nie je príkaz; Auto model. |
| AI: AI Chat | Vetvenie, sumarizácia dlhých chatov, projekty, pamäť a profil, agenti (nahradili Presets), Skills, Automations, nástroje (web, obrázky, terminál), MCP, @ mentions, upozornenia, fronta a „steer“ počas streamu. |
| AI: AI Commands | Vlastné príkazy z promptu; `{selection}`, `{argument}`, `@rozšírenie`; model, tvorivosť, úsilie, výstup (otvoriť / nahradiť výber), tagy, zdieľanie; vstavané: Improve Writing, Fix Spelling, Explain Simply, Change Tone, Find Bugs, Summarize/Ask Webpage; **Quick Fix** (dvojité pravé Shift). |
| AI: Screen Awareness | Send Window / Element / Selection / Screenshot to AI. |
| AI: Dictation | Diktovanie do aktívnej aplikácie, filler/interpunkcia, Auto Styling, Styles po aplikáciách, História; **Dictate to AI** (2.11). |
| AI: modely a poskytovatelia | Auto (Lightweight/Balanced/Flagship), Default Models pre Chat / Quick AI / Commands, Manage Models, vlastný kľúč (BYOK), vlastné predplatné (Claude/ChatGPT), lokálne modely, vlastní poskytovatelia, modely z rozšírení. |
| AI Extensions / MCP | Rozšírenia ako nástroje, správa MCP serverov, povolenia nástrojov (Ask / Auto / Always Allow), pravidlá auto-kontroly. |
| Schránka | Viď vyššie + OCR (Fast/Accurate), Paste Sequentially, Disabled Applications, Universal Clipboard, retencia 1 deň–neobmedzene, Ask Clipboard (AI). |
| Úryvky | Kľúčové slová, režimy expanzie (hneď / po oddeľovači), Expand within Words, dynamické placeholdery (`{date}` `{clipboard}` `{cursor}` `{calculator}`), import z TextExpander/aText/Espanso/PhraseExpress, Injection Delay, Disabled Applications. |
| Quicklinks | URL / súbor s argumentmi a dynamickými placeholdermi, aliasy, hotkeys. |
| Správa okien | Polovice, tretiny, štvrtiny, šestiny, Center, Reasonable Size 60 %, Maximize (+Height/Width), Move Up/Down/Left/Right, na ďalší/predošlý displej a priestor, Resize/Move Window s číslami, medzery medzi oknami, vlastné príkazy, vlastné rozloženia (Layouts), deeplinky, Focus Next/Previous App Window. |
| Poznámky | Viď vyššie; 2.10: neobmedzený počet vo Free; nezobrazovať pri zdieľaní obrazovky. |
| Kalendár | Dnešné udalosti v Root Search, My Schedule, pripojenie k hovoru. |
| Súbory | File Search (index, filtre, výnimky pre sieťové disky), súbory v Root Search. |
| Emoji | Emoji & Symbols mriežka, stĺpce, farby pleti, Greek (2.8). |
| Focus | Relácie sústredenia: blokovanie webov/aplikácií, cieľ, časovač. |
| Preklad | Translate (viac jazykov). |
| Rozšírenia | Obchod (tisíce, Free), vlastné (React/TS), Script Commands, Store themes, fork rozšírenia s kópiou nastavení (2.11). |
| Iné | Hyper Key, Auto Quit, Screenshots, System Commands, Cloud Sync (Pro), Import/Export nastavení, Auto Dark Mode, Restart Frontmost App. |

## 4. Mapa na LatteOS

Predvolená AI z LensAI: `latte-ai models` (zoznam modelov všetkých služieb s príznakom `default`; `providers` ich dáva s predvoleným
prvým), `latte-ai model default PROVIDER MODEL`, `latte-ai send CHAT PROVIDER MODEL TEXT [--effort E] [--attach] [--stream]`,
`latte-ai listen start|stop` (whisper.cpp), `latte-ai agent NAME` (summarize, translate, explain, command; berie lokálnu AI a schránku),
`latte-ai usage`, `latte-ai chats/chat`. Predvolene lokálne (POZIADAVKY 10B: „Predvolene lokálne, kód a dáta von iba s povolením“).
Pravidlo pre všetky riadky „AI“: **zavolať `latte-ai` bez pevného poskytovateľa — vziať predvolený z `latte-ai providers`/`models`**;
LensShore nemá vlastný zoznam modelov ani kľúčov.

| Funkcia Raycastu | LatteOS dnes | Ako postaviť | AI z LensAI |
|---|---|---|---|
| Root Search, aliasy, frecency, skryť, pripnúť | **má** (lens.luau: MOST LAUNCHED, FAVOURITES, aliasy) | doplniť Search Sensitivity, Reset Ranking, História hľadania (↑), hľadanie podľa alternatívnych mien (`Keywords=` v .desktop) | — |
| Favorites na prázdnom poli + ⌘↑/↓ preusporiadanie | **čiast.** (FAVOURITES je) | poradie v `kept.fav`, ctx položky Move Up/Down | — |
| Argumenty príkazov (až 3 polia) | **chýba** | polia v riadku poľa (nový komponent card/field v pleamare) | — |
| Fallback príkazy (aj AI) | **čiast.** (riadok „Open in browser“, Search files) | zoznam fallbackov v `lens.json`, prvý = Quick AI | `latte-ai send` predvolený |
| Kalkulačka, jednotky, meny | **čiast.** (qalc + kurzy ECB) | v2.12: dátum/čas cez qalc; počasie/lety/miesta cez Open-Meteo/Nominatim (**[overiť licenciu]**) | — |
| Quick AI (Tab z poľa) | **čiast.** (režim AI, `rows_ai`, konverzácie) | Tab → režim AI s textom; odpoveď na mieste; ↵ vložiť do predošlej aplikácie (`wtype`/`ydotool`); ⌘J → LensAI | `latte-ai send --stream`, model = `default` |
| Výber modelu a úsilia pri otázke | **čiast.** (EFFORTS, provider v lens.luau) | rozbaľovač z `latte-ai models`; Auto Lightweight/Balanced/Flagship = pravidlo nad poradím modelov | `latte-ai models`, `--effort` |
| AI Chat okno (vetvy, projekty, pamäť) | **čiast.** (LensAI, 10B) | neduplikovať: ⌘J otvorí LensAI na tom istom chate; chýba vetvenie a projekty → úloha pre LensAI | `latte-ai chat/chats` |
| AI Commands (vlastné prompty) | **chýba** | súbor `ai-commands.json` (názov, prompt, placeholdery, výstup); riadky v hľadaní; Quick Fix = skratka | `latte-ai send` s `{selection}` zo schránky/výberu |
| Screen Awareness (okno, výber, snímka) | **čiast.** (čipy Označený text, Schránka, Okno vpredu) | pridať Send Window/Element to AI (grim + slurp → `--attach`) | `--attach PATH` |
| Dictation / Dictate to AI | **má** (mikrofón) / **chýba** kontext | `latte-ai listen` + kontext okna vpredu ako príloha | `latte-ai listen`, `send` |
| AI Extensions / MCP | **čiast.** (LensAI hostiteľ MCP) | rozšírenia ako nástroje až po 6B.30 | LensAI MCP |
| Agenti / Skills / Automations | **čiast.** (AGENT_LIST, režim Agents) | prepojiť s LensAI agentmi (10B) | `latte-ai agent`, `do` |
| Schránka (filtre, pripnúť, OCR, QR) | **má** | doplniť Paste Sequentially, Paste as…, Disabled Applications, Ask Clipboard | `latte-ai agent` nad schránkou |
| Úryvky + placeholdery + import | **chýba** | espanso ako motor + `snippets.json`, dynamické `{date}{clipboard}{cursor}{calculator}`; import TextExpander/espanso | AI placeholder `{ai …}` (rozšírenie nad Raycast) |
| Quicklinks | **chýba** | `quicklinks.json` s `{argument}`; riadky v hľadaní, Tab na argument | — |
| Správa okien (príkazy) | **má** (lens.luau 1230–1270, win:*) | doplniť Move to Next Display, Resize/Move Window s číslami, Focus Next/Prev App Window, medzery, Grid overlay | — |
| Vlastné rozloženia okien | **chýba** | pleamar-wm scéna + Workfield (10M) | — |
| Poznámky | **chýba** | plávajúca karta Goo, Markdown, súbor v `~/Notes`; ⌘0–9 pripnuté | `send` na zhrnutie |
| Kalendár (dnešné udalosti) | **chýba** | khal/evolution-data-server alebo ICS; riadky pod poľom | AI „zhrň deň“ |
| File Search | **má** | doplniť filtre typu (obrázky), výnimky pre sieťové disky | — |
| Emoji & Symbols mriežka + stĺpce | **má** | nastaviteľný počet stĺpcov, Greek | — |
| Focus | **chýba** | režim Focus: wlr/Goo „nerušiť“ + blokovanie z `hosts` (iba so súhlasom) | — |
| Preklad | **chýba** | Bergamot offline (6B.29) | `latte-ai agent translate` ako záloha |
| Rozšírenia z obchodu | **chýba** | 6B.30 | — |
| Skriptové príkazy | **chýba** | `~/.config/latteos/scripts/` s hlavičkou `@raycast.*`; Raycast formát priamo | — |
| Compact mode | **chýba** | `kept.compact`: iba pole, výsledky pri písaní; SHORE_H = 684 sa nemení pre ostatné režimy | — |
| Témy / Theme Studio | **čiast.** (témy systému 9A) | LensShore berie farby z témy; Theme Studio až po 9A | — |
| Lišta akcií ⌘K | **má** (ctx.open, 6B.24) | doplniť sekcie, vyhľadávacie pole v paneli, červené deštruktívne | — |
| Päta s primárnou akciou | **čiast.** (päta módu) | päta: ↵ názov akcie + „Actions Ctrl+K“ | — |
| Hotkey nahrávač, Hyper Key | **chýba** | pleamar-wm viazanie kláves; nahrávač v QML | — |
| Import/Export nastavení | **chýba** | export `lens.json` + `snippets/quicklinks/ai-commands` | — |
| Cloud Sync | **chýba** | platená služba LatteOS (RAYCAST-PRO.md) | — |

## 5. Poradie práce (najviac pocitu Raycastu najskôr)

1. **Päta s primárnou akciou + lišta akcií so sekciami a poľom** (jedno miesto, mení vzhľad všetkých režimov).
2. **Quick AI úplne**: Tab z poľa, odpoveď na mieste (stream), model z predvolenej LensAI, ↵ vložiť, ⌘J do LensAI, fallback príkaz.
3. **Compact mode + Favorites na prázdnom poli + História hľadania (↑)**.
4. **Quicklinks + argumenty príkazov** (jedna mechanika polí v riadku).
5. **Úryvky s placeholdermi** (espanso) a import.
6. **AI Commands** (vlastné prompty, Quick Fix) — stavia na bodoch 2, 4, 5.
7. **Poznámky** (plávajúca karta) a **kalendár** pod poľom.
8. **Správa okien**: číselné príkazy, ďalší displej, medzery, Grid overlay; potom vlastné rozloženia (10M).
9. **Screen Awareness** (Send Window/Element to AI) a **Dictate to AI**.
10. **Prekladač**, **Focus**, **Kalkulačka v2.12** (počasie, lety).
11. Skriptové príkazy, potom obchod rozšírení (6B.30), AI Extensions/MCP.
12. Theme Studio, Import/Export, Cloud Sync.

## 6. Položky Nastavenia › LensShore (zrkadlo Raycastu)

Dnes sú v stránke `lensshore` (apps/settings.qml ~1097–1150) časti: Kde leží · Emoji · Hľadanie · Schránka · GIF. Pribudnú
(každá ako `Part`, texty cez `I18n.tr` + `sk.plm`):

| Časť | Položky (podľa Raycastu) |
|---|---|
| Všeobecné | Skratka na otvorenie (nahrávač) · Zobraziť na (obrazovka s myšou / s aktívnym oknom / primárna) · Veľkosť rozhrania (Predvolená / Veľká / Väčšia) · Režim okna (Rozšírený / Kompaktný) · Obľúbené v kompaktnom režime · Vzhľad: podľa systému / vlastná téma · Návrat na koreň po (okamžite … 180 s) · Faviconový poskytovateľ |
| Hľadanie | Citlivosť (nízka/stredná/vysoká) · Súbory a Kontakty v hľadaní · Vymazať históriu hľadania · Záložné príkazy (pridať, poradie) · Obnoviť poradie · Aliasy a skratky (jeden zoznam s filtrom) |
| Klávesnica | Hyper Key · Správanie Esc (späť / zavrieť) · Navigácia Emacs / Vim · Stránkovacie klávesy · Prepnúť zdroj vstupu |
| AI | Zapnúť AI v LensShore · **Predvolený model pre Quick AI / AI príkazy = odkaz na LensAI (nič vlastné)** · Auto: Lightweight / Balanced / Flagship · Nový chat po (5 min) · Odoslať: Ctrl+Enter · História: spoločná / oddelená · Automatické archivovanie · Upozornenia na pozadí · Povolenia nástrojov (Pýtať sa / Auto / Vždy) · Profil a Pamäť (odkaz na LensAI) · Vlastné AI príkazy (zoznam) · Screen Awareness (príkaz, skratka, primárna akcia) · Zobraziť využitie AI v lište |
| Schránka | už je; pridať Rozpoznanie textu (Rýchle/Presné) · Vložiť postupne + časový limit · Zakázané aplikácie · Primárna akcia (Vložiť / Kopírovať) · Uchovávanie (1 deň … neobmedzene) |
| Úryvky | Zapnúť expanziu · Režim expanzie · Oneskorenie vkladania · Zvuk · Zakázané aplikácie · Upozorniť pred zmazaním |
| Rýchle odkazy | Zoznam, import/export |
| Okná | Medzera medzi oknami a okrajom · Ľavá/pravá polovica cyklujú veľkosti alebo obrazovky · Vlastné príkazy a rozloženia |
| Poznámky | Tlačidlo v lište · Esc stráca zaostrenie · Zoom · Skryť pri zdieľaní obrazovky |
| Diktovanie | Jazyk · Auto štýl · História · Mikrofón pre Bluetooth |
| Rozšírenia a skripty | Zoznam príkazov (zapnúť/vypnúť, alias, skratka) · Skriptové príkazy (obnova na pozadí) |
| Pokročilé | Aktivácia okna (presunúť na aktívnu plochu / prepnúť) · Export a import nastavení · Proxy a certifikát · Cloud Sync (neskôr) |
| O programe | Verzia, zoznam zmien, kontrola aktualizácií |

Hľadanie v Nastaveniach (Ctrl+F) a otvorenie položky z LensShore (⇧Ctrl+,) už rieši centrálne Nastavenia; stačí pridať kľúčové slová.

## 7. Čo overiť pred prácou

- Rozmery a farby okna Raycastu z oficiálnych snímok (manuál ich neuvádza); snímku dávať vedľa návrhu v rovnakej mierke.
- `raycast.com/changelog`: či už je v2.12 aj pre macOS (vyhľadávač ukazoval v2.11; samotná stránka v2.12 z 13. 11.).
- Licencie pre počasie/lety/miesta (Open-Meteo CC BY 4.0; Nominatim OSM) pred pridaním do TRETIE-STRANY.md.
