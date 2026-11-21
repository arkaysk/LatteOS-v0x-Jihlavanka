# CEO review LatteOS — 21. 11. 2026

Pohľad zakladateľa na celý projekt (gstack `/plan-ceo-review`, iba čítanie, bez zmien kódu). Plán, ktorý sa posudzuje:
`ROADMAP.md` (zoznam „Poradie práce“, hlavičky kategórií a vzorky 1, 2, 6, 10A, 10B, 14, 18), `README.md`,
`docs/README.md`, `docs/ARCHITECTURE.md`, `docs/lensai/POZIADAVKY.md`, `docs/lensai/AUDIT-2026-11-21.md` (s tvojimi
poznámkami tučným) a história gitu za 30 dní. Vetva `v0.55`, commit `5e91c04c4`.

**Režim: SCOPE REDUCTION** — rozhodol som sám (relácia bez možnosti pýtať sa): plán má 20 kategórií, ~40 podkategórií,
147 otvorených a 69 hotových úloh, a cieľ z 30. 10. („alpha, nepridávať nové funkcie“) sa za tri týždne nesplnil.
Každý návrh na škrtnutie je **iba návrh**: rozhoduješ ty (pozri „Nerozhodnuté“ na konci).

---

## 1. Čo je produkt a pre koho

**Jednou vetou:** LatteOS je linuxová plocha pre ľudí, ktorí odchádzajú z Windowsu 11 — ovládaná myšou, s vlastnou
živou identitou (tekuté kávové kvapky Goo), s hrami a s AI, ktorá je na jednom mieste a dá sa celá vypnúť.

**Pre koho (ako to čítam z README a Priority UX):** človek z Windowsu, často hráč, ktorý nechce terminál, nechce sa
učiť skratky a chce, aby počítač bol jeho (bez telemetrie, reklám, účtu). Druhý, menší okruh: človek, ktorý používa
viac AI služieb naraz a chce ich mať pod jednou strechou (LensAI, agentgram).

**Čo v skutočnosti vzniká — dva produkty v jednom repe:**

| | Produkt A: plocha pre ľudí z Windowsu | Produkt B: AI pracovisko |
|---|---|---|
| Jadro | pleamar-wm, Goo (BarGoo, LensShore, PowerGoo, ClockGoo…), DualBrew, Nastavenia, Barista, inštalátor | LensAI, `latte-ai` (4 285 riadkov), `latte-mcp`, agentgram (fork agentes.chat), ToolHive, lokálne LLM |
| Používateľ | bežný človek z Windowsu | pokročilý používateľ AI, ktorý platí 2–5 predplatných |
| Stav | „0.5 na ceste“, inštalátor nebol prejdený od nuly | najviac práce za posledné 3 týždne, audit: „funkcií veľa, dotiahnutie nie na úrovni Win 11“ |

Produkt B je zaujímavý a v niečom unikátny, ale **človek z Windowsu ho nepotrebuje na to, aby LatteOS začal
používať**. Potrebuje produkt A. To je hlavné napätie celého plánu.

## 2. Čo je najsilnejšie

1. **Identita, ktorú nikto iný nemá.** Goo nie je „ďalší téma pre GNOME“. Kvapky, hladina kávy, prihlásenie s morom
   pri západe slnka — to je dôvod, prečo si niekto LatteOS pozrie na Reddite. Silnejšie ako akákoľvek funkcia.
2. **Disciplína procesu, na jedného človeka výnimočná.** Úlohy s ID, `FILES` (924 riadkov: čo kam ide), denník
   rozhodnutí, preklady cez `sk.plm` + `pleamar --check`, `tests/check.sh`, `TRETIE-STRANY.md`, záplaty pleamaru
   oddelené v `patches/`. Toto je základ, na ktorom sa dá vydávať.
3. **„Preberať, nevymýšľať“ funguje.** Omarchy (AI), LM Studio (lokálne LLM — v audite najlepšie dotiahnutá stránka),
   Total Commander (DualBrew), Raycast (kalkulačka), Chaldea (41 widgetov), ToolHive. Rýchlosť vývoja z toho
   priamo plynie.
4. **pleamar-wm s kurzorom agenta.** Kompozitor, ktorý dáva AI vlastnú myš a klávesnicu a bránu na schválenie, je
   skutočne nový nápad. Toto je jediná vec, kde sa produkt A a B prirodzene stretávajú: „AI ti pomôže na ploche
   a nikdy ti nezoberie myš“.
5. **Poctivosť.** README hovorí otvorene, že kód píše AI a že je to alpha na jednom stroji. Pre komunitu to je plus.

## 3. Čo je rozložené pritenko

**Dôkaz z gitu (od 30. 10., keď si určil „alpha, nič nové“):** 245 commitov. Z nich ~59 o LensAI/agentgrame/MCP/
skilloch a ~65 o inštalácii/WM/boot. Za posledné 3 týždne sa „lensai“ objavuje v 54 správach commitov, „dualbrew“
v 2, „guardcorgi“ v 3. Nové od 30. 10.: fork agentgramu, ToolHive s Registry Serverom a PostgreSQL, katalóg 818 MCP
serverov, Store (zrušený po dvoch dňoch → ToolHive), Anonymné projekty, 26 druhov projektov, výber pamäte, ACP agenti,
Phosphor ikony. Všetko pekné — ale nič z toho nie je na kritickej ceste k alpha.

**Konkrétne miesta:**

- **Fork agentes.chat.** Upstream má ~10 400 commitov a ~1 600 za posledný týždeň. Udržať „iba pridávajúci“ fork
  kompatibilný s takým tempom je samo o sebe projekt na plný úväzok. Audit ukazuje čierne/biele záblesky a načítanie
  5–12 s — to nie je vec, ktorú vyriešiš pridávaním.
- **Vrstvy AI na sebe:** `latte-ai` + `latte-mcp` + ToolHive (Studio + služba v TrayShore + Registry + PostgreSQL)
  + agentgram + ACP + Basic Memory + lokálny llama.cpp. Audit: skilly na dvoch miestach (73 vs. 2), stránky si
  navzájom odporujú (Grok/Copilot, Claude 50 % vs. 39 %). Každá ďalšia vrstva zvyšuje počet nesúladov.
- **Kategórie, ktoré sú samostatné produkty:** YOL (7C), Kaviareň s čašníčkami (10B.36), 3D dashboard z dioramas,
  Heidelberg (10C), Hry (10K), Kalendár „všetky funkcie Google Kalendára“ (10J), LatteIndex (10N), Chapolera
  (10A.66), Latte-Workfield (10M), LatteCapture (10O), CamGoo (6F), spoje cez Transitous (6B.49), LPnP + DisplayKit
  (10E.14–19, 8B.09–12), Atomic/bootc (1C), Fyzikálne prostredie kvapiek. To je ~15 produktov popri jednom OS.
- **Testovanie odložené úplne na koniec.** `bughunt/stav.py`: P1 29/219, P2 1/296, P3 0/175. Pravidlo „STRESTEST až
  posledný“ dáva zmysel pre veľký záťažový test, ale znamená, že regresie sa dnes zisťujú iba okom.
- **Dokumentácia, ktorá už neplatí.** `docs/ARCHITECTURE.md` a `docs/README.md` opisujú Hyprland, Noctaliu,
  `session/`, `setup/lab/`, vetvu `main` a „licencia zatiaľ nie je“ — README hovorí GPL-3.0-or-later a pleamar-wm.
  Prvý človek zvonka, ktorý otvorí `docs/`, dostane zlú mapu. V koreni repa ležia aj `lensAIplan.md`,
  `lensAIplan2.md`, `__pycache__`.
- **Persona vs. inštalácia.** Sľub „nikdy neotvoríš terminál“ vs. prvý krok „nainštaluj Fedora Server a v textovej
  konzole spusti `curl … | sudo sh`“. Pre alpha OK, ale treba to nazvať pravým menom.

## 4. Čo škrtnúť alebo odložiť (návrh, rozhoduješ ty)

**Odložiť za 0.6 (po alpha), zapísať ako „odložené 21. 11.“ v ich kategóriách:**

| Čo | Prečo teraz nie |
|---|---|
| LPnP + DisplayKit (10E.14–19, 8B.09–12) | **Ide proti tvojmu rozhodnutiu z 19. 11.** („hneď po LensAI“). Navrhujem po alpha: bez testerov nevieš, aké zariadenia ľudia majú. Nerozhodnuté — tvoja voľba. |
| YOL (7C), Kaviareň (10B.36), 3D dashboard (dioramas), Strážca podmienok (10B.39), Vlastná farma (10B.40) | nadstavby nad LensAI, ktorý ešte nie je dotiahnutý |
| Nové funkcie agentgramu (projekty, druhy, pamäť, online synchronizácia 10B.79) | najprv rýchlosť a stabilita; fork pripnúť na jednu verziu upstreamu |
| ToolHive Registry Server + PostgreSQL + katalóg 818 serverov | pre alpha stačí zoznam pripojených konektorov a tlačidlo „Pridať“; katalóg je pre pokročilých |
| CamGoo (6F), spoje (6B.49), kalkulačka nad rámec 6B.48, LatteCapture, Workfield, LatteIndex, Chapolera | každá je malý produkt; LensShore už vie dosť |
| Kalendár „všetky funkcie Google“ (10J) | cieľ je Google; pre Windows človeka stačí, že kalendár účtu funguje |

**Škrtnúť z plánu na 1.0 (presunúť do 19 Neskôr):** Heidelberg (10C), Hry ako vlastná kategória (Steam + Proton +
Barista už sú; samostatné „Hry“ je duplicita), Atomic/bootc (1C), Fyzikálne prostredie kvapiek (26).

**Neškrtať:** Goo, BarGoo/LensShore/PowerGoo/ClockGoo, DualBrew, Nastavenia, Barista, GuardCorgi, SAFE, inštalátor,
LensAI v dnešnom rozsahu (s opravami z auditu), lokálne LLM.

## 5. Stávky na najbližší mesiac (21. 11. – 21. 12.)

1. **Vydať 0.5 alpha naozaj.** Brána je jasne zapísaná (14.21): čistá inštalácia od nuly na latte-lab (Fedora 45
   Server → `get` → sprievodca → reštart → Goo), `--remove`, SAFE, a aspoň jedna iná zostava — **hlavné PC s RTX 3060
   a dvoma monitormi** (zároveň prvý test NVIDIA a 1D.01/1D.07). Cieľová skupina sú hráči z Windowsu a väčšina z nich
   má NVIDIA; dnes nie je overená ani jedna. Kým toto nie je, všetko ostatné je stavanie na piesku.
2. **LensAI: stop funkciám, mesiac dotiahnutia.** Desať bodov z auditu (dialóg Nová kategória, záblesky, živé
   hľadanie, Esc, čip modelu, testovacie dáta, nesúlad stránok, nefunkčné MCP, angličtina, priestor) plus tvoje
   „SÚHLASÍM“: jedno miesto pre skilly, šípky aj ťahanie vo Web, vysvetlenie bodiek (vypínateľný tutoriál), ACP na
   vlastnej stránke a „Čítať“, ktoré nič neurobí. Kritérium hotovosti: druhý audit tým istým postupom bez [kritické].
3. **agentgram: rozhodnúť model forku.** Návrh: pripnúť verziu upstreamu, aktualizovať raz za mesiac v jednom kroku
   s testom kompatibility (tvoja podmienka: neforkovaný agentes.chat sa musí vedieť pripojiť). V inštalátore ako
   voliteľná súčasť, nie predvolená. Tým sa jeho riziko oddelí od alpha.
4. **Prvých 10 minút človeka z Windowsu.** Jeden scenár, prejdený od začiatku: prihlásenie → otvoriť prehliadač
   z LensShore → súbor v DualBrew → zmeniť tapetu v Nastaveniach → nainštalovať Steam cez AppManager → hra →
   odhlásiť. Každé zaseknutie = úloha. Toto je skutočný test Produktu A a lepší ukazovateľ pre 0.6 než zoznam kvapiek.
5. **Malý dym-test posúvaný doľava.** Nie STRESTEST, ale ~20 strojových kontrol z P1 (štart relácie, scéna sa načíta,
   kvapky existujú, `latte-ai services` odpovie, aplikácie sa otvoria), pustených headless (labwc + gles2, ako
   v pamäti „Skúšanie scén na grafickej karte“) pri každom commite cez `tests/check.sh`. STRESTEST ostáva posledný.

## 6. Riziká

| Riziko | Pravdepodobnosť | Dopad | Čo s tým |
|---|---|---|---|
| **Alpha sa stále posúva**, lebo každý týždeň príde nový zaujímavý kus AI | vysoká (stalo sa) | nikto zvonka LatteOS neskúsi; spätná väzba = nula | stávka 1, „zmrazenie funkcií“ do vydania |
| **Jeden stroj, jedna karta (RX 640), RC jadro a Mesa** | istá | inštalátor zlyhá na prvom PC testera | hlavné PC (NVIDIA) pred zverejnením; README presne: čo je overené |
| **Závislosť od jedného autora pleamaru/pleamar-wm** (k4ditano) + vlastné záplaty | stredná | zmena API rozbije Goo aj WM | zamknuté verzie (už v 14.21), `latte-upstream -v` pred prácou, záplaty malé |
| **Fork s 1 600 upstream commitmi týždenne** | vysoká | rozbitá kompatibilita, nekonečné zlučovanie | stávka 3 |
| **Podmienky AI služieb** (webové záložky, čítanie spotreby z prihlásení, Transitous) | stredná | zablokovaný účet používateľa | pravidlá v POZIADAVKY §5 sú dobré; pred alpha prejsť, čo presne sa číta a odkiaľ |
| **Súkromné údaje v snímkach a verejnom repe** (e-mail účtu v Nastaveniach › CLI, audit to spomína) | stredná | únik do verejného GitHubu | pred push kontrolovať `docs/screenshots`, `docs/lensai/audit-*` |
| **Licencia:** `sea.wgsl` je CC BY-NC-SA vo vnútri GPL distribúcie | nízka | nejasnosť pre distribútorov | README to hovorí; zvážiť náhradu pred 1.0 |
| **Pamäť latte-lab (15 GB, dva pády)** | stredná | stratená práca, poškodený stav | pravidlo `systemd-run MemoryMax` platí; LensAI neodporúčať 35B model (audit) |
| **Bus factor 1 + AI, súbežné čaty** | istá | konflikty, rozpracované necommitnuté zmeny (stav 20. 11.: „necommitnuté, nasadené“) | commit na konci každej relácie (na tvoj pokyn), jeden čat = jedna kategória |
| **Zastaralá dokumentácia** | istá | prvý prispievateľ/tester sa stratí | týždeň 1: prepísať ARCHITECTURE a docs/README na pleamar-wm |

## 7. Navrhované poradie práce

```
TÝŽDEŇ 1 (21.–28. 11.)  ALPHA BRÁNA
  ├─ commit rozpracovaného (20. 11. noc) — na tvoj pokyn
  ├─ čistá inštalácia latte-lab od nuly (ROADMAP r. 98) + --remove + SAFE + reštart
  ├─ opraviť iba to, čo inštaláciu zastaví
  └─ docs/ARCHITECTURE.md a docs/README.md podľa skutočnosti (pleamar-wm, GPL-3, v0.55)

TÝŽDEŇ 2 (29. 11.–5. 12.)  LensAI DOTIAHNUTIE
  ├─ 10 bodov auditu + tvoje SÚHLASÍM (jedno miesto skillov, Web ťahanie, bodky, ACP)
  ├─ agentgram: pripnúť upstream, záblesky, dialóg Nová kategória, „Stále bdelá“
  └─ druhý audit LensAI tým istým postupom

TÝŽDEŇ 3 (6.–12. 12.)  DRUHÝ STROJ
  ├─ hlavné PC: RTX 3060, dva monitory (1D.01, 1D.07), NVIDIA ovládač v inštalátore
  ├─ scenár „prvých 10 minút“ na oboch strojoch
  └─ dym-test (~20 kontrol) do tests/check.sh

TÝŽDEŇ 4 (13.–21. 12.)  VYDANIE 0.5
  ├─ 14.20: známe obmedzenia, overený hardvér, ako nahlásiť chybu (šablóna issue)
  ├─ značka v0.5.0 + ZMENY.md (push a zverejnenie iba na tvoj pokyn)
  └─ pozvať 3–5 testerov (Reddit rice komunita, ktorej README ďakuje)

POTOM  0.6 Plocha Goo (Fáza 2, body 5–7) → LPnP/DisplayKit podľa toho, čo testeri majú → Fáza 3…
```

---

## Prehľad podľa sekcií review (strategická hĺbka)

| # | Sekcia | Zistenie |
|---|---|---|
| 1 | Architektúra | Produkt A je čistý (pleamar-wm + Goo + QML aplikácie + `bin/latte-*`). Produkt B má 6+ vrstiev s prekrývajúcimi sa úlohami (skilly v LensAI aj ToolHive, pamäť v agentgrame aj Basic Memory). Implementátor musí dokázať: jeden zdroj pravdy pre stav služby (prihlásenie + spotreba). |
| 2 | Chyby a záchrana | SAFE (labwc) a GuardCorgi „Opýtať sa AI“ sú dobrý záchranný plán. Chýba: čo uvidí človek, keď inštalátor zlyhá v polovici zostavovania pleamaru (30 min build). Implementátor musí dokázať: zrozumiteľná chyba + návrat bez konzoly. |
| 3 | Bezpečnosť | Kľúče v kľúčenke, „nič sa nerobí samo“, webové záložky bez MCP — dobré. Riziko: `curl \| sudo sh`, nepodpísané jadro (Secure Boot vypnúť), agent s „Myš: Všade“. |
| 4 | Dáta a okrajové stavy | Testovacie dáta v skutočných rozhovoroch (audit bod 6) → testy bez vlastného `XDG_DATA_HOME`. |
| 5 | Kvalita kódu | `aicenter.qml` 2 309 riadkov a upravuje ho viac čatov naraz; `latte-ai` 4 285. Kandidáti na rozdelenie až po alpha. |
| 6 | Testy | P1 29/219. Stávka 5. |
| 7 | Výkon | agentgram 5–12 s na stránku; `latte-mcp status` už zrýchlené (8,8 s → 0,06 s). Scéna `goo.plm` ~11 tis. vlastností — 17 Optimalizácia. |
| 8 | Pozorovateľnosť | GuardCorgi hlási pády (ToolHive spadol). Chýba: tester nemá ako jednoducho poslať záznam. Do 14.20: „Zbaliť záznam pre hlásenie chyby“. |
| 9 | Nasadenie | Relácia beží z `/usr`, `FILES`, `install --remove`. Chýba: aktualizácia existujúcej inštalácie u testera (nie iba nová). |
| 10 | Dlhodobá trajektória | Bez vydania sa 1.0 Arabica nedá dosiahnuť: brány 14.14 vyžadujú hardvér, ktorý máš iba ty. Testeri sú cesta k Arabice. |
| 11 | Dizajn/UX | Identita výborná; audit LensAI: priestor 1920 px nevyužitý, tri navigácie vedľa seba (tvoje rozhodnutie: tlačidlo na zbalenie, nie automaticky — prijaté). |

**Error & Rescue mapa (úroveň schopností):**

| Schopnosť | Čo zlyhá | Čo vidí človek dnes | Musí vidieť |
|---|---|---|---|
| Inštalátor | build pleamaru, sieť, Koji jadro | zoznam krokov, posuvník (neoverené do konca) | chybu ľudskými slovami + „Skúsiť znova“ / „Odísť bez zmien“ |
| Štart | grafika, 2× pád relácie | SAFE (labwc) | to isté + čo sa stalo (GuardCorgi) |
| LensAI | služba odhlásená, limit | rozporné stránky | jeden stav na všetkých stránkach |
| agentgram | uspatá záložka, pomalý server | čierna/biela plocha 1–12 s | kostra + logo + krúžok načítania |
| MCP | konektor bez nástrojov | „Momentálne žiadne nástroje“ | dôvod + „Skúsiť znova“ / „Odobrať agentom“ |

**Režim:** SCOPE REDUCTION, rozhodnuté bez otázky (relácia bez používateľa), dôvod v hlavičke. Nezávislý druhý
názor (outside voice) a spec-review subagent sa nespúšťali: úloha bola iba na čítanie a jedno odovzdanie.

**REALITY:** premise-table pass (cieľ alpha 30. 10., ROADMAP.md:89–96) · already-done pass (inštalátor `get` existuje,
README.md:52–76) · surface-check finding (docs/ARCHITECTURE.md:1–181 zastaralé) · binding-decisions finding
(LPnP po LensAI, ROADMAP.md:72 — návrh ide proti, ponechané na teba) · numbers pass (`bughunt/stav.py` 29/219) ·
deferred-asks pass (bez prepojenej issue) · pr-count n/a (bez PR, priamo vetva v0.55).

## GSTACK REVIEW REPORT

| Review | Trigger | Why | Runs | Status | Findings |
|--------|---------|-----|------|--------|----------|
| CEO Review | `/plan-ceo-review` | Scope & strategy | 1 | ISSUES OPEN | mode: SCOPE_REDUCTION, 3 critical gaps |
| Outside Review | — | Independent 2nd opinion | 0 | skipped | no completed external review (spawned read-only run) |
| Eng Review | `/plan-eng-review` | Architecture & tests (required) | 0 | — | — |
| Design Review | `/plan-design-review` | UI/UX gaps | 0 | — | — |
| DX Review | `/plan-devex-review` | Developer experience gaps | 0 | — | — |

- **OUTSIDE COVERAGE:** skipped — spawned read-only run, no external reviewer launched.
- **Critical gaps:** (1) alpha neoverená čistou inštaláciou, (2) NVIDIA ani druhý stroj neoverený, (3) dym-test chýba.
- **VERDICT:** nič CLEAR; eng review required.

**UNRESOLVED DECISIONS:**
- Odložiť LPnP + DisplayKit až za 0.5 alpha (ide proti rozhodnutiu z 19. 11.)?
- Zmraziť nové funkcie LensAI/agentgramu do vydania 0.5?
- agentgram: pripnúť upstream a dať ho do inštalátora ako voliteľnú súčasť?
- Presunúť Heidelberg, Hry (10K), Atomic, Fyzikálne prostredie do 19 Neskôr?
- Odložiť YOL, Kaviareň, 3D dashboard, ToolHive Registry/katalóg, CamGoo, spoje, Kalendár-Google za 0.6?
