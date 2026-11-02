# LensAI — čo od neho očakávame

Súpis návrhov, inšpirácií a požiadaviek na LensAI z jedného miesta (2. 11. 2026). Zdroje: ROADMAP kategória 10B
(a odkazy z 6B, 7C, 1D), `docs/goo/ROZHODNUTIA.md`, `inspo/ai-na-ploche.md`, rozhovory s používateľom.
Pri každej položke je ID úlohy v ROADMAP; čo nemá ID, je nové.

## 1. Čo LensAI je

- **Jedno API pre všetku AI v systéme** (`latte-ai`: služby, účty, modely, rozhovory, spotreba, úlohy, skill) **a okno nad
  ním** (`apps/aicenter.qml`). LensGoo a LensShore sú iba rýchli klienti toho API (10B.14).
- **Celé AI z Omarchy (MIT), len s grafickým rozhraním namiesto konzoly**; pri inštalácii a aktualizáciách najprv
  pozrieť, ako to rieši Omarchy (10B.14, rozhodnutie 21. 10.).
- **MCP host:** konektory spúšťa LensAI raz a dáva ich všetkým — modelom cez API, lokálnej AI aj oficiálnym CLI
  (rozhodnuté 29. 10., 10B.35).
- **Mimo LensAI zatiaľ:** agenti pleamar-wm v termináli (k4ditano) — alternatíva k LensAI, fungujú nezávisle,
  neprepojené (1D.22).

## 2. Úvodná obrazovka: dashboard (nové)

LensAI sa otvorí **dashboardom**, nie zoznamom rozhovorov.

**Čo na ňom má byť** (návrh z toho, čo už LensAI vie a čo sa plánuje):

| Časť | Odkiaľ |
|---|---|
| Prstene služieb — zostávajúci limit (Claude týždeň, 5 h po kliknutí), predpoveď minutia | 10B.14 bod 2, 10B.35 |
| Agenti: kto pracuje, kto čaká na teba (aj agenti pleamar-wm, keď sa prepoja) | 10B.14 bod 3, 1D.22 |
| Kaviareň: objednávky pri presse, čo čaká pri pulte na schválenie | 10B.36 |
| Lokálna AI: bežiaci model, pamäť, karta, či je PC nečinné | 10B.14 bod 7 |
| Rozhovory: posledné, pokračovať | 10B.04 |
| Rýchle úlohy: „Urob to za mňa“, 6 pripravených úloh | 10B.14 bod 5 |
| Projekty z Obsidianu označené pre Kaviareň | 10B.37 |
| Upozornenia strážcu podmienok (zmena podmienok služby) | 10B.39 |
| Prechod do YOL (Learn, Dnes) | 7C |

**Vzhľad: [dioramas](https://github.com/blendi-remade/dioramas)** (blendi-remade) — rámec na „filmové“ interaktívne
3D stránky: jeden 3D objekt ako celá stránka a jedno charakteristické gesto (podržať a prasknúť geodu, posvietiť
majákom…). 20 hotových príkladov.

- Technika: three.js, Vite, GSAP, Lenis; jadro `src/core/` (HDR dodatočné efekty: N8AO, bloom, AgX, zrno, vinetácia;
  objemové svetlá, zrkadlenie, plynulé posúvanie, vlastný kurzor). Postup: krátke zadanie v `docs/briefs/` → AI agent
  postaví stránku nad jadrom → kontrola snímkami cez headless GPU (`scripts/review.mjs`). Ten postup sa hodí aj nám.
- Licencia: **kód MIT, vygenerované modely a obrázky CC BY 4.0** (`ASSET-LICENSES.md`) → smie sa prevziať, autor do
  `TRETIE-STRANY.md`.
- 3D modely vyrába cez platené cloudové služby (fal: Nano Banana 2, Meshy 7.1; ~1,20 $ za model) — pre LatteOS buď
  hotové modely z repa (CC BY), alebo vlastné cez Kaviareň (ComfyUI) s povolením používateľa.
- Je to **web, nie dashboard**: robí scény na posúvanie s jedným hrdinom, nie husté údaje. Preberá sa jadro (svetlo,
  efekty, plynulosť) a spôsob práce; karty s údajmi sú naša práca.
- **Kde pobeží:** LensAI je QML (Quickshell) → 3D scéna v QtWebEngine ako pozadie dashboardu, alebo myšlienky
  prenesené do pleamaru (shadery, sklo). Rozhodnúť (otázka v časti 7).
- **Výkon:** príklady sú ladené na 60 fps na stolnej grafike; RX 640 a nižšie stupne výkonu potrebujú tichú, statickú
  podobu (ako ostatné efekty LatteOS podľa `LATTE_TIER`).

## 3. Čo už LensAI vie (hotové)

- Karta AI v LensGoo: rozhovor, pole v podobe služby, výber modelu a úsilia, spotreba, nová relácia, prílohy (súbor,
  snímka obrazovky) (10B.02, 10B.04).
- Služby: Claude, Gemini, ChatGPT, Grok, Mistral, Copilot cez oficiálne nástroje s účtom; vlastné kľúče API v kľúčenke
  systému; vlastné servery s OpenAI API (10B.04, 10B.08).
- Spotreba ako v Omarchy (Claude, Grok, Copilot, ChatGPT) (10B.14 bod 2).
- Stránka Agenti, skill LatteOS (upraviteľný), „Urob to za mňa“ v termináli s plánom a bez automatického schvaľovania
  (10B.14 body 3–5).
- Pád → „Opýtať sa AI“ s GuardDogom a v SAFE (10B.14 bod 6).
- Inštalácia AI nástrojov z okna LensAI, mise; lokálna AI ako LM Studio (Objavovať, Moje modely, Spúšťanie) (10B.14 bod 7).
- Mikrofón (whisper.cpp, Vulkan), vlastné pokyny pre každú AI (10B.12); mikro-agenti a pomocníci ako v Omarchy, každý
  vypínateľný (10B.19, 10B.21).

## 4. Čo od neho ešte chceme

**Služby a účty**
- Záložky služieb „jeden prsteň“: oficiálny web každej AI vo vlastnom webview s vlastným profilom, bez vkladania
  skriptov; pás prsteňov vľavo s originálnymi ikonami (10B.35).
- Aplikácie služieb z Flathubu, DeepSeek (10B.14 bod 7).
- Rozhovory aj mimo LensAI: import exportov (Claude, ChatGPT, Gemini), Remote Control Claude Code do mobilu (10B.16).
- Viac účtov jednej služby s prepnutím pri limite — neskôr (10B.14 bod 7).

**Modely**
- Úrovne rýchly / bežný / najlepší namapované na akýkoľvek model (lokálny, predplatné, API), záloha, opakovanie,
  viac kľúčov (10B.39).
- Odporúčané lokálne modely obnovovať raz za 1–2 mesiace; model navrhnutý podľa hardvéru pri inštalácii (10B.15).

**Rozhovor**
- Dizajn okna: biela plocha čiastočne priehľadná (biela na tmavom je príliš ostrá) (10B.01).
- Postupné písanie odpovede, zastavenie, kvalita odpovedí a chybových stavov (10B.22–24, 10B.27).
- Zviditeľniť, kam ide požiadavka, čo sa posiela, či odpovedá lokálna alebo cloudová AI (10B.29).

**AI v systéme**
- Barlička: „preformátuj mi `/`…“ — AI navrhne plán krokov nástrojmi LatteOS, každý zásah potvrdí človek, polkit,
  snímka pred diskom, dá sa vrátiť; nástroje potrebujú aj „robiacu“ časť (10B.18, 10B.30).
- Asistent v každom textovom poli (DualBrew, hudba, fotky…): pravidlá robia, čo vedia, AI iba zvyšok, vždy
  s potvrdením (10B.20).
- AI pri kurzore: gesto myšou nad označeným textom alebo oblasťou (10B.34).
- Hlas: diktovanie do akejkoľvek aplikácie (Win+H) neskôr; full-duplex rozhovor sledovať (10B.17, 10B.33).

**Hľadanie a znalosti**
- Hľadanie podľa významu (e5-sk) a podľa obsahu cez DigUp — negeneratívne, mimo vypínača AI (10B.03, 10B.13, 10B.32).
- Znalosti o AI ako odkazy na kurzy, nie vlastná pomoc; YOL Learn ich ponúkne (10B.41).

**Konektory a projekty**
- LensAI ako MCP host, katalóg konektorov z MCP Registry (10B.35, 10B.38).
- Obsidian ako projektový manažér a lokálny kontext; Kaviareň vidí iba projekty označené pre ňu (10B.37).

**Kaviareň (hravá časť)**
- Front dlhých úloh, čašníčky = agenti, presso = stanice, pult = schválenie; vymeniteľný vzhľad čašníčok; predvolene
  lokálne, keď je PC nečinné (10B.36).
- Úlohy sú skilly (`SKILL.md`, + `stanice.json`, `skripty/`, `comfy/`); Menu lístok — obchod so skillmi a konektormi
  s kontrolou zdroja, licencie a oprávnení; skilly v základe (Comfy MCP, anthropics/skills s vhodnou licenciou)
  (10B.36, 10B.38).
- Vlastná farma s bránou cez testy (lacný model pracuje, výsledok prejde iba s prejdenou kontrolou) (10B.40).
- Skilly na dorobenie: komiks, videoklip, kniha, tabuľky, výskum, biblia sveta, DnD, hudobné vydanie, výstava,
  storyboard, audiokniha, prekladateľ, video a podcast, herný dizajn (10B.36, 10B.38).

**Strážca podmienok**
- Pri každom poskytovateľovi jeho podmienky a ich odtlačok; pri zmene upozorniť, ukázať rozdiel a prístup, ktorý by ich
  porušil, prerušiť, kým ho používateľ znova nepotvrdí (10B.39).

## 5. Pravidlá, ktoré platia

- **Vypínač AI = generatívna AI.** Hľadanie podľa obsahu (DigUp) pod neho nespadá (rozhodnutie 27. 10.).
- **Nič sa nerobí samo:** plán, náhľad, potvrdenie; pri disku snímka; zásahy čitateľné a vratné (10B.18, 10B.30).
- **Webové záložky a online chat nedostávajú systémové oprávnenia ani MCP.** Výnimka: úroveň 2 LensShore smie aj
  online AI, ničiace a upravujúce akcie po dvojitom potvrdení (10B.30, rozhodnutie 28. 10.).
- **Podmienky služieb sa dodržiavajú:** do webov sa nevkladajú skripty, obsah sa medzi AI neprenáša automaticky;
  synchronizácia bežných četov claude.ai nie (10B.16, 10B.35).
- **Kľúče iba v kľúčenke systému,** nikdy v súbore (rozhodnutie 21. 10.).
- **Predvolene lokálne;** kód a dáta von iba s povolením (10B.36, 10B.40).
- **Vývojová farma a MCP vývojárov sú oddelené** od AI pre používateľa (10B.31).
- **Najprv Omarchy,** potom vlastné (rozhodnutie 21. 10.).

## 6. Prepojenie s YOL

YOL (7C) stojí na LensAI: pole uprostred YOL je LensShore s príkazmi `task · log · open · new · help`, Learn ponúka kurzy
cez DeepTutor a odkazy z 10B.41, widgety YOL plní AI. Preto sa robí najprv LensAI (dashboard a API), potom YOL.

## 7. Otvorené otázky

1. Dashboard: 3D scéna z dioramas ako pozadie v QtWebEngine, alebo iba myšlienky (svetlo, sklo, plynulosť) prenesené
   do pleamaru? A aký objekt má byť „hrdinom“ — šálka kávy, Kaviareň, niečo iné?
2. Ktoré časti dashboardu z časti 2 chceš na prvej obrazovke a ktoré až po posunutí?
3. Agenti pleamar-wm (1D.22): ukázať ich na dashboarde už teraz (iba čítanie), alebo až keď sa prepoja s LensAI?
4. Poradie: najprv dashboard, alebo najprv dokončiť rozhovor a služby (10B.01, 10B.27, 10B.35)?
