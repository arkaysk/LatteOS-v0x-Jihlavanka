vytvorene 18.11.2026
naposledy upravene 18.11.2026

# LensAI — plán: všetky súčasti a najlepšia cesta ku každej

Tento súbor zoznamuje **všetko, čo LensAI má alebo má mať**, a ku každej časti **návrh najlepšej cesty**, ako dosiahnuť
najlepší výsledok: čo je efektívnejšie, účinnejšie alebo už hotové inde. Sú to **návrhy, nie rozhodnutia**. Rozhoduje
používateľ, rozhodnutia sa zapisujú do `ROADMAP.md` (10B) a `docs/goo/ROZHODNUTIA.md`.

- Zdroje stavu: `docs/lensai/POZIADAVKY.md`, `docs/lensai/ANALYZA.md`, `docs/lensai/NAVRH-MCP.md`, ROADMAP 10B (do 10B.61),
  kód `bin/latte-ai`, `bin/latte-mcp`, `apps/aicenter.qml`, `apps/aicenter/WebTabs.qml` (stav 17. 11.).
- Zdroje návrhov: výskum 18. 11. (porovnanie s Multi-AI Chat Desktop, Panelize, Odysseus a ďalšími projektmi), odkazy
  pri každej časti.
- **Licencia:** LensAI môže mať vlastnú licenciu, nezávislú od LatteOS (používateľ 18. 11.). Kód s licenciou MIT/Apache
  sa dá prevziať priamo. Kód s AGPL (Odysseus, agentes-chat) sa dá prevziať, ak bude LensAI (alebo tá jej časť) pod AGPL,
  inak iba prepísať nápad. Autorov zapísať do `TRETIE-STRANY.md`.

- **Čím to spraviť** (hotové projekty, knižnice, licencie, verdikty) je v `lensAIplan2.md` (audit trhu 18. 11.).

**Stav:** ✅ hotové · 🔶 rozpracované · 📋 plánované · ⏸ pozastavené · 👁 sledovať

---

## Prehľad poradia (návrh)

Čo prinesie najviac za najmenej práce, zhora nadol:

| # | Čo | Prečo prvé | Časť |
|---|---|---|---|
| 1 | llama.cpp v režime router + `--fit` + voľná VRAM | odstráni ručné `-ngl`, reštarty pri zmene modelu, pády pri hre | 4.1, 4.2 |
| 2 | Uspávanie webov v dvoch stupňoch | už schválené 17. 11.; pamäť 3,3 GB → zhruba tretina | 2.1 |
| 3 | Lenivé nástroje v `latte-mcp` (vyhľadanie nástroja) | bez toho lokálny model s malým kontextom nástroje nezvládne | 5.1 |
| 4 | Limity Claude zo statusline Claude Code | presné percentá z oficiálneho zdroja, malá práca | 2.4 |
| 5 | Klient ACP pre agentov | nahradí čítanie titulkov terminálu; povolenia priamo v „Čaká na teba“ | 6.1 |
| 6 | Skilly vo formáte Agent Skills (`.agents/skills/`) | každé CLI ich uvidí bez kopírovania | 5.3 |
| 7 | MTP modely v odporúčaných | ~1,5–2× rýchlejšie odpovede na tom istom PC | 4.1 |
| 8 | Odhad rýchlosti a skóre podľa účelu | používateľ vidí „koľko slov za sekundu“, nie iba „zmestí sa“ | 4.2 |
| 9 | Jeden index rozhovorov (SQLite FTS5 + vektory, e5-sk) | hľadanie v histórii všetkých AI, aj pre AI cez MCP | 3.2, 8.1 |
| 10 | Slovenský Parakeet/Canary namiesto whisper large | rýchlejšie, presnejšie po slovensky, beží na procesore | 7.1 |

---

## 1. Jadro

### 1.1 `latte-ai` — jedno API pre všetku AI ✅
- **Dnes:** príkazový riadok s JSON výstupom (služby, modely, rozhovory, spotreba, lokálna AI, hlas, skilly, relácie).
  LensAI, LensGoo, LensShore a YOL sú iba klienti.
- **Najlepšia cesta:** ponechať. Iba dve zmeny:
  - dlho bežiace časti (lokálny server, index rozhovorov, MCP) ako **jeden démon** s lokálnym socketom namiesto
    spúšťania Pythonu pri každom volaní — každé volanie dnes platí štart interpretera a znovu číta súbory (odmerať, koľko to je);
  - pridať `latte-ai bench` (pamäť webov cez `/proc/PID/smaps_rollup` PSS, čas prvého zobrazenia záložky, tok/s
    lokálneho modelu), aby sa dalo každé zlepšenie z tohto plánu **odmerať**, nie odhadnúť.

### 1.2 Okno LensAI (`apps/aicenter.qml`) ✅ / 🔶
- **Dnes (17. 11.):** zúžiteľný panel s prsteňmi, Prehľad s jedným poľom, Čaká na teba, Teraz beží, Tento počítač,
  Spotreba, Naposledy, Skilly, Konektory, Rozhovory, Agent Chats v okne. Šošovka z Prehľadu odišla.
- **Najlepšia cesta:** zvyšok posudkov zo 17. 11. (jednotná hlavička sekcií, kratšie úvodné vety, model dvakrát v poli).
  „Čaká na teba“ plniť štruktúrovanými žiadosťami cez ACP (6.1), nie z titulkov okien.

### 1.3 Vypínač AI ✅
- **Dnes:** vypne generatívnu AI v LensAI, barličkách, LensGoo a LensShore. Hľadanie podľa obsahu (DigUp) nie.
- **Najlepšia cesta:** ponechať. Pri zapojení routera (4.1) a MCP (5.1) skontrolovať, že vypínač zastaví aj ich.

---

## 2. Služby a účty

### 2.1 Webové záložky služieb („jeden prsteň“) ✅ → uspávanie 🔶
- **Dnes:** QtWebEngine, každá služba vlastný trvalý profil, nič sa do stránok nevkladá, nové správy iba podľa titulku
  a ikony. Weby sa pripravujú v pozadí (ChatGPT 0,6 s po kliknutí). 7 webov + Agent Chats ≈ 3,3 GB (PSS).
- **Porovnanie (18. 11.):** Multi-AI Chat Desktop (Tauri 2) aj Panelize (rozšírenie Chrome) do stránok **vkladajú
  skripty** (selektory poľa a tlačidla, Panelize navyše odstraňuje hlavičky X-Frame-Options a CSP). LensAI to zámerne
  nerobí (10B.35) — je to jej výhoda, nie nedostatok. Pamäť vo všetkých troch berú hlavne skripty webov.
- **Najlepšia cesta — dvojstupňové uspávanie** podľa Qt WebEngine `lifecycleState`:
  1. **Frozen** (zmrazené): skript stojí, procesor 0 %, pamäť ostáva, prebudenie okamžité. Pre záložku, ktorá nie je
     viditeľná pár minút. Qt dovolí zmraziť iba neviditeľnú záložku.
  2. **Discarded** (zahodené): pamäť sa uvoľní, stránka sa pri návrate načíta znova (2–4 s). Pred zahodením uložiť
     obrázok cez `grabToImage` a kým sa prebúdza, ukázať ho.
  3. Pravidlá ako Vivaldi Memory Saver: **zriedka používané skôr, často používané neskôr**; poradie podľa počtu otvorení
     za týždeň. Prvé dve najpoužívanejšie ostávajú živé.
  4. **Nikdy neuspať** záložku, ktorej titulok alebo ikona sa zmenili za posledných ~60 s (služba práve odpovedá —
     zmrazenie by zastavilo spojenie a odpoveď by neprišla), ani záložku, ktorá hrá zvuk (`recentlyAudible`).
  5. Brať do úvahy `recommendedState`, ktorý Qt navrhuje sám.
  - Prednačítanie podľa stupňa výkonu (full všetky, standard prvé tri) ponechať, ale **rovno do Frozen**, nie Active.
  - Pozor (qutebrowser): zahodiť všetky záložky hneď pri štarte spôsobí špičku pamäte a procesora → zahadzovať postupne.
- **Prvý krok:** časovač v `WebTabs.qml` + počítadlo použitia v `~/.local/state/latteos/ai/tabs.json`, odmerať `latte-ai bench web`.
- Zdroje: [Qt WebEngine Lifecycle Example](https://doc.qt.io/qt/qtwebengine-webenginequick-lifecycle-example.html),
  [Vivaldi Memory Saver](https://help.vivaldi.com/desktop/tabs/memory-saver),
  [qutebrowser PR 5370](https://github.com/qutebrowser/qutebrowser/pull/5370).

### 2.2 Oficiálne CLI služieb s účtom ✅ → ACP
- **Dnes:** Claude Code, Codex, Gemini CLI, Grok, Mistral Vibe, Copilot CLI spúšťané s účtom používateľa; výstup sa číta
  z ich vlastných formátov, stav z titulku terminálu.
- **Najlepšia cesta:** pripojiť ich cez **Agent Client Protocol** (časť 6.1) — jeden kód pre všetky. Gemini CLI to vie
  sám (`gemini --acp`), Claude Code a Codex cez adaptéry `claude-agent-acp` a `codex-acp`. Vlastné čítanie výstupov
  nechať ako zálohu pre CLI bez ACP.

### 2.3 Kľúče API a vlastné servery ✅ → úrovne modelov 📋 (10B.39)
- **Dnes:** kľúče v kľúčenke systému, vlastné servery s OpenAI API, nástroj `ask` (otázka inej AI).
- **Najlepšia cesta pre úrovne rýchly / bežný / najlepší:**
  - Spraviť ich **v `latte-ai`** (malá tabuľka: úroveň → zoznam modelov v poradí, opakovanie, ďalší kľúč), nie cez
    LiteLLM Proxy — ten je ďalší Python server a pre jedného používateľa je zbytočne ťažký. Konfiguráciu písať
    v rovnakom tvare ako LiteLLM `model_list` + `fallbacks`, aby sa dal neskôr zapojiť, ak by bol treba.
  - **Nikdy tichý prechod z lokálneho modelu do cloudu.** Cloud je samostatná úroveň a prechod naň ukáže LensAI
    (pravidlo „predvolene lokálne“).
- Zdroje: [LiteLLM router s lokálnym LLM](https://bestllmfor.com/guides/litellm-router-local-llm/).

### 2.4 Spotreba a prstene ✅ → presné limity Claude 📋
- **Dnes:** spotreba ako v Omarchy (Claude, Grok, Copilot, ChatGPT); prsteň Claude = týždeň, po kliknutí 5 h.
- **Najlepšia cesta pre Claude:** Claude Code posiela svojmu príkazu statusline JSON s `rate_limits.five_hour` a
  `rate_limits.seven_day` (`used_percentage`, `resets_at`). LensAI zaregistruje malý príkaz `latte-ai statusline`
  v `~/.claude/settings.json` (ak používateľ žiadny nemá, inak ho obalí), ktorý tieto hodnoty zapíše do súboru
  a vypíše pôvodný riadok. Okná môžu chýbať — prsteň vtedy ukáže posledný známy stav s časom.
  Neoficiálne koncové body s OAuth tokenom nepoužiť (krehké a mimo podmienok).
- Zdroj: [Claude Code statusline](https://code.claude.com/docs/en/statusline).

### 2.5 Viac účtov jednej služby 📋 (neskôr)
- **Najlepšia cesta:** web = profil na účet (`lensai-claude-2`), CLI = vlastný priečinok nastavení na účet (premenné
  prostredia, ktoré CLI na to majú, napr. `CLAUDE_CONFIG_DIR`, `CODEX_HOME` — overiť pri každom CLI). Prepnutie pri
  limite iba s potvrdením, lebo niektoré podmienky viac účtov na obchádzanie limitov zakazujú → zapojiť do 2.6.

### 2.6 Strážca podmienok 📋 (10B.39)
- **Dnes:** návrh: pri každom poskytovateľovi jeho podmienky a odtlačok; pri zmene upozorniť a prerušiť dotknutý prístup.
- **Najlepšia cesta:** nesťahovať podmienky sám. **Open Terms Archive** už sleduje podmienky generatívnych AI služieb
  (kolekcia GenAI), roboty ich sťahujú viackrát denne a verzie sú verejne v gite (`OpenTermsArchive/GenAI-versions`,
  deklarácie v `GenAI-declarations`). LensAI si raz denne stiahne iba zmeny pre služby, ktoré používateľ má, a ukáže rozdiel.
  Chýbajúce služby (napr. Mistral, Copilot CLI) pridať ako deklaráciu do ich projektu — pomôže to aj iným.
  AI potom zhrnie rozdiel po slovensky a označí, či sa týka spôsobu, akým ju LensAI používa.
- Zdroje: [Open Terms Archive](https://opentermsarchive.org/en), [GenAI declarations](https://github.com/OpenTermsArchive/GenAI-declarations).

### 2.7 Aplikácie služieb z Flathubu, DeepSeek, ďalšie služby 📋
- **Najlepšia cesta:** DeepSeek, Qwen, Kimi, Perplexity najprv ako web záložka + kľúč API (žiadne vlastné CLI netreba).
  Flathub balíky iba ak sú oficiálne od výrobcu.

---

## 3. Rozhovory

### 3.1 Vlastné okno rozhovoru ✅
- **Dnes:** pre lokálnu AI, kľúče a CLI; prílohy (PDF ako text, obrázok ako obrázok), postupné písanie, Späť/Znova.
- **Najlepšia cesta:** „Kam ide otázka“ (10B.29) ukazovať vždy pri poli (lokálne / cloud / meno modelu), ešte pred
  odoslaním. Interaktívne prvky v odpovedi (výber, súčet) až po ACP, lebo agenti ich posielajú štruktúrovane.

### 3.2 História: všetky rozhovory na jednom mieste ✅ → jeden index 📋
- **Dnes:** JSON súbor na rozhovor v `~/.local/state/latteos/ai/chats/`, k tomu relácie Claude Code (iba čítanie).
- **Najlepšia cesta:** súbory nechať ako zdroj pravdy a postaviť nad nimi **jeden index v SQLite**:
  - **FTS5** (hľadanie slov, mená, presné výrazy) + **sqlite-vec** (hľadanie podľa významu), výsledky spojené cez
    Reciprocal Rank Fusion. Jeden súbor, bez servera, bez cloudu.
  - Vektory z **e5-sk-small** (8.1) — malý, slovenský, beží na procesore.
  - Indexovať: rozhovory LensAI, relácie Claude Code, importy (3.3), poznámky z Obsidianu (8.2).
  - Vystaviť ako nástroj `latte-mcp` **`search_chats`** → každá AI (aj cez CLI) vidí históriu ostatných bez
    prenášania obsahu medzi webmi. Presne takto to robí napr. memex (claude.ai + Claude Code).
- Zdroje: [memex-chats](https://pypi.org/project/memex-chats/), [sqlite-vec](https://github.com/asg017/sqlite-vec).

### 3.3 Import exportov (Claude, ChatGPT, Gemini) 📋 (10B.16)
- **Najlepšia cesta:** oficiálny export (ZIP od služby) → prevodník do formátu rozhovorov LensAI → index 3.2.
  Iba čítanie, označené pôvodom (`--from claude-export`). Žiadna synchronizácia četov claude.ai (podmienky).

### 3.4 Jedna otázka viacerým AI, porovnanie 🔶
- **Dnes:** nástroj `ask`; webové záložky vedľa seba (dve naraz).
- **Najlepšia cesta:** režim **Porovnať** iba cez API a lokálne modely: jedna otázka 2–4 modelom, odpovede vedľa seba,
  voliteľne **naslepo** (mená skryté, používateľ vyberie lepšiu, ako Compare v Odysseus). Výsledky volieb uložiť —
  časom ukážu, ktorý model používateľovi sedí na ktorý typ úlohy (vstup pre úrovne 2.3).
  Debaty a „okrúhly stôl“ ako v Multi-AI Chat Desktop robiť cez agentov (6.2), nie cez weby.

---

## 4. Lokálna AI

### 4.1 Runtime (llama.cpp) ✅ → router, `--fit`, MTP 📋
- **Dnes:** `llama-server` s jedným modelom (`-m`), ručné `-ngl`, kontext, vlákna; spúšťa a zastavuje ho `latte-ai`;
  zmena modelu = reštart. Zostavenie s Vulkanom. Odhad pamäte cez `llama-fit-params` a hlavičku GGUF.
- **Najlepšia cesta:**
  1. **Režim router** (`llama-server` bez `-m`): modely z priečinka (`--models-dir`), predvoľby v INI
     (`--models-preset`), `--models-max 1` (najviac jeden model naraz, starší sa uvoľní), každý model vo vlastnom
     procese (pád jedného nezhodí server), režim spánku. `latte-ai` prestane spravovať procesy sám.
     Predvoľby INI sú presne miesto pre tri nastavenia **Kvalita / Vyvážené / Rýchlosť** (z Odysseus).
  2. **`--fit`** (v nových zostaveniach predvolene zapnuté) rozdelí model medzi kartu a RAM sám, aj experty MoE;
     `--fit-target` = koľko MiB nechať voľných. LensAI nastaví `--fit-target` podľa toho, čo beží (hra, ComfyUI) →
     ručné `-ngl` a `--n-cpu-moe` netreba. `llama-fit-params` ostáva na odhad pred stiahnutím.
  3. **MTP** (multi-token prediction, v llama.cpp od 16. 5. 2026, `--spec-type mtp`): modely s MTP hlavami
     (Qwen3.6, Gemma 4) odpovedajú ~1,5–2× rýchlejšie bez druhého modelu v pamäti. V zozname odporúčaných
     uprednostniť MTP varianty GGUF a zapnúť MTP automaticky, keď ho súbor má.
  4. **Opakované použitie cache:** pokyny používateľa (`ai-instructions.txt`) a systémový text dávať vždy na začiatok
     v rovnakom tvare → llama.cpp nemusí prvú časť počítať znova (prvé slovo odpovede príde skôr).
  5. **Vulkan ostáva správna voľba** aj pre staré AMD (Polaris/RX 570: ROCm ich už nepodporuje, Vulkan dáva 3–4×
     viac než procesor). Fedora Atomic má novú Mesu, ktorá zrýchľuje RADV — výhoda pre LatteOS.
- Zdroje: [README servera llama.cpp (router, presety, spánok)](https://github.com/ggml-org/llama.cpp/tree/master/tools/server),
  [`--fit-target` (issue 18390)](https://github.com/ggml-org/llama.cpp/issues/18390),
  [MTP PR 22673](https://github.com/ggml-org/llama.cpp/pull/22673),
  [Vulkan na RX 580](https://dev.to/aivisionslab/running-local-ai-on-an-amd-rx-580-in-2026-the-complete-vulkan-guide-52a5).

### 4.2 Hardvér a výber modelu ✅ → presnejšie a s rýchlosťou 📋
- **Dnes:** procesor + AVX2, RAM z `/proc/meminfo`, karty z `/sys/class/drm/card[0-9]`, VRAM z `mem_info_vram_total`
  (AMD) alebo `nvidia-smi`; „zmestí sa“ = gpu / partial / cpu / too-big; ponúkne prvý vhodný zo zoznamu.
- **Najlepšia cesta:**
  1. **Voľná VRAM, nie celková.** Hra alebo ComfyUI berú VRAM; model sa má rozhodovať podľa toho, čo je voľné teraz
     (`mem_info_vram_used` pri AMD, `memory.used` pri NVIDIA). Pre LatteOS ako herný systém je to dôležité.
  2. **Jeden zdroj pravdy = runtime sám:** zariadenia a ich pamäť tak, ako ich vidí llama.cpp (`--list-devices`
     zostavenia s Vulkanom vidí AMD, NVIDIA aj Intel rovnako). Sysfs iba ako záloha. Overiť výstup na vlastnom zostavení.
  3. Opraviť drobnosti: `card[0-9]` → `card*` (desiata karta a viac), `nvidia-smi` hľadať aj mimo PATH, a keď hlási
     nezhodu ovládača („aktualizované bez reštartu“ — po rpm-ostree bežné), povedať to, nie „žiadna karta“ (Odysseus).
  4. **Odhad rýchlosti:** priepustnosť pamäte karty ÷ veľkosť aktívnych váh × ~0,55; pri čiastočnom presune na
     procesor zmiešať s priepustnosťou RAM (Odysseus). Ukázať „~25 slov/s“ pri každom modeli.
  5. **Skóre podľa účelu** (rozhovor, kód, uvažovanie, obrázky): kvalita + rýchlosť + rezerva + kontext s rôznymi
     váhami. Hotové v **llmfit** (Rust, MIT, `llmfit recommend --json`) — zvážiť použiť ho priamo ako knižnicu alebo
     CLI; je v Ruste ako zvyšok LatteOS. Má aj **simuláciu hardvéru** a **plán „čo dokúpiť“** (o koľko VRAM/RAM viac
     pre lepší model) — hodí sa do Baristu a pri plánovaní nákupu karty.
  6. **Hardvér iných počítačov cez SSH** (Odysseus): domáci server (ZimaOS) alebo druhý PC → LensAI vie povedať,
     kde model pobeží najlepšie.
  7. **Ručné zadanie hardvéru** a upozornenie, keď kontajner kartu nevidí (Odysseus) — pre kontajnery LatteOS.
  - Odhad pamäte LensAI (hlavička GGUF + meranie `llama-fit-params`) je presnejší ako vzorce Odysseus a llmfit → ponechať.
- Zdroje: [Odysseus `services/hwfit/`](https://github.com/odysseus-dev/odysseus), [llmfit](https://github.com/AlexsJones/llmfit).

### 4.3 Objavovať a sťahovať modely ✅
- **Dnes:** vyhľadávanie GGUF na Hugging Face ako v LM Studio, kontrola odtlačku, pokračovanie sťahovania.
- **Najlepšia cesta:** pridať filter „s MTP“ a „s nástrojmi“; zoznam odporúčaných obnovovať raz za 1–2 mesiace (10B.15)
  poloautomaticky: skript navrhne zmeny podľa skóre z 4.2, človek potvrdí.

### 4.4 Malé modely pre pomocníkov a mikro-agentov ✅
- **Dnes:** pomocníci (zhrnúť, preložiť, vysvetliť, príkaz) idú na lokálny model, inak Claude Haiku.
- **Najlepšia cesta:** v routeri (4.1) predvoľba s malým modelom, ktorá ostáva načítaná vedľa hlavného iba ak je
  pamäť; inak sa načíta na požiadanie. Úloha pomocníka nikdy nevyhodí z pamäte veľký model, na ktorom práve beží rozhovor.

---

## 5. Nástroje, konektory, skilly

### 5.1 `latte-mcp` — LensAI ako MCP host ✅ → lenivé nástroje 📋
- **Dnes:** jedna sada konektorov pre modely cez API, lokálnu AI a CLI; nástroje pre AI, ktorá žiadne nemá (10B.43).
- **Problém:** každá schéma nástroja stojí tokeny. 100 nástrojov ≈ 15 000 tokenov ešte pred otázkou; lokálny model
  s kontextom 8 000 to nezvládne vôbec.
- **Najlepšia cesta (vzor „MCP gateway“):**
  1. AI dostane iba **3–4 meta-nástroje**: zoznam serverov, hľadanie nástroja podľa slov (BM25), opis nástroja,
     zavolanie. Konkrétne schémy až keď ich hľadá (~400 tokenov namiesto ~15 000).
  2. **Kurátorské profily** namiesto „všetko všetkým“: Domácnosť, Súbory, Kód, Tvorba — profil podľa úlohy alebo
     úrovne modelu. Vybrané nástroje (`alwaysExpose`) sú vidieť hneď.
  3. Servery štartovať **až pri prvom volaní** a uspať po nečinnosti.
  4. **Záznam každého volania** (kto, čo, výsledok, rozhodnutie pravidla) — podklad pre GuardCorgi a pre Späť.
  5. Pre API Anthropic použiť ich vlastné `defer_loading` + tool search; pre ostatných meta-nástroje.
- Zdroje: [vzor MCP gateway (Arcade)](https://blog.arcade.dev/mcp-gateway-pattern),
  [mcp-gateway (swarmclawai, MIT)](https://github.com/swarmclawai/mcp-gateway).

### 5.2 Katalóg konektorov z MCP Registry 📋 (10B.38)
- **Najlepšia cesta:** čítať oficiálny MCP Registry, ku každému konektoru ukázať zdroj, licenciu, oprávnenia; stdio
  servery (ComfyUI, Blender, Krita) vystaviť cez HTTP iba na 127.0.0.1 (`mcp-proxy`), keď ich potrebuje Agent Chats.
  Pred inštaláciou kontrola cez GuardCorgi/CloneGuard (rozhodnuté 17. 11.).

### 5.3 Skilly (`latte-skill`) ✅ → formát Agent Skills 📋
- **Dnes:** `latte-skill` je jediné miesto skillov, LensShore z neho kreslí riadky, stránka Skilly ich ukazuje.
- **Najlepšia cesta:** držať sa otvoreného štandardu **Agent Skills** (agentskills.io, od 18. 12. 2025, ~40 klientov:
  Claude Code, Codex, Gemini CLI, Copilot, Mistral Vibe…):
  - priečinok so `SKILL.md` (meno + opis v hlavičke, potom pokyny) + `scripts/`, `references/`, `assets/`;
  - ukladať do spoločnej cesty **`.agents/skills/`** (a odkazom do `.claude/skills/`), aby ich každé CLI videlo bez kopírovania;
  - **postupné odkrývanie:** lokálnemu modelu dávať iba meno a opis, celý text až keď ho vyberie — šetrí kontext;
  - kontrola validátorom zo špecifikácie pred uložením.
  - Skilly Kaviarne (`stanice.json`, `comfy/`) zostanú doplnkové súbory v tom istom priečinku.
- Zdroj: [špecifikácia Agent Skills](https://agentskills.io/specification).

---

## 6. Agenti

### 6.1 „Urob to“, agenti v termináli, „Čaká na teba“ ✅ → klient ACP 📋
- **Dnes:** „Urob to“ odovzdá príkazy agentovi v termináli (najprv plán); stav agenta z titulku terminálu
  (`working` / `waiting`); relácie Claude Code zo záznamov iba na čítanie.
- **Najlepšia cesta: LensAI ako klient Agent Client Protocol (ACP).** ACP je otvorený protokol (Zed, JSON-RPC cez
  stdio), ako LSP pre agentov. Používa ho Zed, JetBrains, Neovim, Emacs aj Microsoft Terminal.
  - Gemini CLI má ACP vstavané, Claude Code a Codex cez adaptéry (`claude-agent-acp`, `codex-acp`), ďalej OpenCode,
    Qwen Code, Copilot CLI, Goose a desiatky ďalších.
  - LensAI dostane štruktúrovane: plán, kroky, **žiadosti o povolenie** (Povoliť/Odmietnuť rovno v „Čaká na teba“),
    zmeny súborov ako diff, koniec práce. Žiadne čítanie titulkov.
  - Pri založení relácie ACP odovzdá **MCP servery** → `latte-mcp` dostane každý agent automaticky. To rieši bod CEO
    zo 17. 11. „jedna sada konektorov a skillov pre všetky AI“ (tlačidlo „Dať všetkým AI“).
  - Terminál ostáva ako voľba („Ukázať terminál“), nie ako jediný spôsob.
  - Hotové klientske knižnice existujú aj v Ruste (napr. `gate4agent`: pipe, PTY, ACP).
- Zdroje: [ACP (Zed)](https://zed.dev/acp), [agent-client-protocol](https://github.com/agentclientprotocol/agent-client-protocol).

### 6.2 Agent Chats (vlastný fork agentes-chat) 🔶
- **Dnes:** rozhodnuté 17. 11.: fork s vlastným menom, prihlásenie bez hesla, téma LatteOS, slovenčina; LensAI mu dá
  skilly, MCP, kľúče a lokálny model cez jeho API.
- **Najlepšia cesta:** najprv ACP (6.1), potom **jedna skutočná viacagentová úloha** v pôvodnom agentes-chat (bod CEO
  zo 17. 11.). Až potom fork, a iba ak 6.1 + skilly nepokryjú, čo treba. Na paralelnú prácu na kóde (každý agent vo
  vlastnom git worktree) existujú hotové otvorené aplikácie (Orca, Emdash, Superset) — tie zdroj nápadov, nie náhrada,
  lebo tvorivé úlohy (komiks, video) nerobia.

### 6.3 Kaviareň (farma) ⏸ (zastavená 17. 11.)
- **Najlepšia cesta po obnovení:** nestavať vlastný orchestrátor. Kaviareň = **vizualizácia** nad tým, čo už bude:
  úlohy = skilly (5.3), čašníčky = agenti cez ACP (6.1), presso = predvoľby routera a ComfyUI, pult = „Čaká na teba“.
  Brána cez testy (10B.40) = skill s `scripts/check`, ktorý musí prejsť pred odovzdaním.

### 6.4 Barlička — zásahy do systému s potvrdením 📋 (10B.18, 10B.30)
- **Najlepšia cesta:** každý zásah je nástroj `latte-mcp` s opisom „čo urobí“ a „ako sa vráti“; potvrdenie ide ako
  žiadosť o povolenie ACP (6.1); pred zásahom do disku snímka (rpm-ostree / btrfs); záznam do histórie Späť (`LATTE_UNDO`).

### 6.5 Agenti pleamar-wm (myš a klávesnica agenta) ✅
- **Najlepšia cesta:** ponechať pravidlá (`latte-ai hands`). Zobrazovať ich v „Teraz beží“ ako ostatných agentov,
  keď sa prepoja (1D.22).

### 6.6 Pád programu → „Opýtať sa AI“ ✅
- **Najlepšia cesta:** ponechať; ak beží router, použiť malý model (4.4), aby výpis pádu neopustil počítač.

---

## 7. Hlas

### 7.1 Mikrofón (prepis reči) ✅ → slovenské modely 📋
- **Dnes:** whisper.cpp, s Vulkanom large-v3-turbo, inak small na procesore.
- **Najlepšia cesta:** vyskúšať **slovenské dotrénované modely KInIT** (CC-BY-4.0): Canary 1B v2 sk má vo vlastnom teste
  KInIT 6,37 % chýb slov (základný model 14,39 %), Parakeet TDT 0.6B v3 sk 6,62 % (základný 24,32 %). Parakeet je
  menší a výrazne rýchlejší ako Whisper a beží aj na procesore (ONNX) → karta ostane voľná pre model alebo hru.
  KInIT má aj slovenské verzie Whispera (tiny až large), ktoré by šli rovno do whisper.cpp po prevode.
  Postup: odmerať na vlastných nahrávkach (rovnaká veta, čas a chyby), whisper ponechať ako zálohu pre iné jazyky.
- Zdroj: [kinit/canary-1b-v2-sk](https://huggingface.co/kinit/canary-1b-v2-sk).

### 7.2 Diktovanie do akejkoľvek aplikácie (ako Win+H) 📋 (10B.17)
- **Najlepšia cesta:** neprogramovať nanovo. Overené vzory pre Wayland/Hyprland: **hyprwhspr** (Omarchy, režimy
  prepnúť / držať / auto), **Handy** (navrhnutý na forkovanie), **voxtype**, **whisrs** (Rust). LensAI má už `latte-ai listen`;
  chýba iba klávesová skratka cez pleamar-wm a vloženie textu do okna (`wtype`). Voliteľne vyčistenie textu malým
  lokálnym modelom (4.4).
- Zdroje: [hyprwhspr](https://github.com/goodroot/hyprwhspr), [Handy](https://github.com/cjpais/Handy).

### 7.3 Rozhovor hlasom (full-duplex) 👁
- **Najlepšia cesta:** sledovať. Moshi (Kyutai) je plne duplexný, ale slovenčinu nevie. Pre LatteOS je reálnejší vzor
  **Unmute**: prepis reči + ľubovoľný textový model + syntéza reči, s prerušovaním. Teda 7.1 + router + slovenská
  syntéza reči, keď bude dosť dobrá.

---

## 8. Hľadanie a znalosti

### 8.1 Hľadanie podľa významu (e5-sk) 📋 (10B.03, 10B.13, 10B.32)
- **Najlepšia cesta:** modely **e5-sk-small (45 M parametrov) a e5-sk-large (365 M)** z práce SkMTEB (KInIT, TUKE, UK;
  ACL 2026) — upravené Multilingual E5 pre slovenčinu, menšie až o 62 % a porovnateľné s platenými API. Small na
  procesore pre index rozhovorov a súborov, large voliteľne pri stupni full. Mimo vypínača AI (nie je generatívne).
- Zdroj: [SkMTEB (ACL 2026)](https://aclanthology.org/2026.acl-long.2114.pdf).

### 8.2 Obsidian ako lokálny kontext a správca projektov 📋 (10B.37)
- **Najlepšia cesta:** trezor Obsidianu je obyčajný priečinok Markdownu → indexovať ho priamo do 3.2 a sprístupniť cez
  `latte-mcp` (čítanie; zápis iba do označených projektov). Žiadny plugin Obsidianu netreba. Projekt pre agentov =
  poznámka so značkou (napr. `#kaviaren`).

---

## 9. AI v systéme

### 9.1 Asistent v každom textovom poli 📋 (10B.20) a AI pri kurzore 📋 (10B.34)
- **Najlepšia cesta:** jedna skratka nad označeným textom (výber Waylandu cez `wl-paste --primary`) → malé pole
  LensShore pri kurzore s pomocníkmi (4.4) → návrh → vloženie až po potvrdení. Najprv pravidlá (preklep, formát),
  AI iba na zvyšok — ako je zapísané v 10B.20.

### 9.2 Prepojenie s YOL 📋 (7C)
- **Najlepšia cesta:** YOL ostáva klient `latte-ai`; nič vlastné pre AI. Learn ponúka odkazy (10B.41).

---

## 10. Ako merať, či cesta pomohla

Každú zmenu z tohto plánu odmerať pred a po (`latte-ai bench`, časť 1.1) na rovnakom stroji:

| Čo | Ako | Dnes (17. 11.) |
|---|---|---|
| Pamäť webov | PSS všetkých procesov QtWebEngine | ~3,3 GB (7 webov + Agent Chats) |
| Otvorenie záložky | od kliknutia po prvé vykreslenie | ChatGPT 0,6 s (prednačítaný) |
| Lokálny model | tok/s a čas do prvého slova na pevnej otázke | — |
| Kontext s nástrojmi | tokeny schém pred otázkou | — |
| Prepis reči | čas a chyby na 3 pevných slovenských nahrávkach | — |
