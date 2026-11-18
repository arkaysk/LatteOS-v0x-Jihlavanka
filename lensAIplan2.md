vytvorene 18.11.2026
naposledy upravene 18.11.2026

# LensAI — technologický audit formou prieskumu trhu

Ku každej súčasti LensAI: **čo už na trhu existuje a dá sa použiť, integrovať, forknúť alebo z toho čerpať.**
Nadväzuje na `lensAIplan.md` (ten hovorí *ako* to spraviť; tento súbor *čím*). Návrhy, nie rozhodnutia.

Pri každej súčasti sú tri rôzne veci:

- 🟢 **Najlepší hotový projekt** — dá sa použiť takmer priamo (spustiť vedľa LensAI, zavolať jeho CLI alebo API).
- 🔵 **Najlepšia knižnica alebo komponent** — zabuduje sa do LatteOS.
- 🟠 **Najlepšia vlastná implementácia** — nikto to nerobí dosť dobre pre LatteOS, oplatí sa vyvíjať vlastné.

**Verdikt:** PONECHAŤ (súčasné riešenie LensAI je dobré) · NAHRADIŤ · INTEGROVAŤ · SLEDOVAŤ.

**Licencie a LensAI:** LensAI môže mať vlastnú licenciu (používateľ 18. 11.). MIT, Apache-2.0, BSD → dá sa prevziať kód.
GPL/AGPL → prevziať kód iba ak bude tá časť LensAI pod zlučiteľnou licenciou; **samostatný program spustený vedľa**
(MCP server, CLI) licenciu LensAI neovplyvní. „Overiť“ = licenciu som v zdroji nenašiel jednoznačne, pred použitím
pozrieť súbor LICENSE v repe.

Stav trhu: 18. 11. 2026. Hviezdičky a verzie sa menia, rozhodujú licencia a architektúra.

---

## Súhrn

| # | Súčasť | 🟢 Hotový projekt | 🔵 Knižnica / komponent | 🟠 Vlastné | Verdikt |
|---|---|---|---|---|---|
| 1 | WebTabs | Ferdium (inšpirácia) | Qt WebEngine lifecycle | **áno** — uspávanie, profily, bez skriptov | PONECHAŤ + čerpať |
| 2 | Model Router | **llama.cpp router** | llama-swap | tenká politika VRAM/hra | NAHRADIŤ vlastnú správu procesov |
| 3 | Hardware Detection | **llmfit** | llama.cpp `--fit` / `llama-fit-params` | voľná VRAM, stupne LatteOS | INTEGROVAŤ |
| 4 | MCP | swarmclawai/mcp-gateway | MCP Registry API, srt | **latte-mcp ako host s pravidlami** | PONECHAŤ + INTEGROVAŤ lenivé nástroje |
| 5 | ACP | Zed (vzor) | **agent-client-protocol (Rust SDK)** | UI „Čaká na teba“ | INTEGROVAŤ |
| 6 | Skills | **vercel-labs/skills** | špecifikácia agentskills.io | latte-skill ako obchod s kontrolou | PONECHAŤ + INTEGROVAŤ formát |
| 7 | Chat History | memex (inšpirácia) | **SQLite FTS5 + sqlite-vec + e5-sk** | **áno** — index všetkých AI | VLASTNÉ nad knižnicami |
| 8 | Memory | **Basic Memory** | Graphiti (ak treba čas) | — | INTEGROVAŤ |
| 9 | Voice | hyprwhspr / Handy (diktovanie) | **sherpa-onnx + KInIT sk + Silero VAD** | slovenská syntéza reči | INTEGROVAŤ |
| 10 | Agent Chats | agentes.chat / Eigent | ACP conductor, CAMEL | Kaviareň nad ACP | SLEDOVAŤ, rozhodnúť po skúške |
| 11 | AI Comparison | **promptfoo** | — | **slepé porovnanie + osobné poradie** | INTEGROVAŤ + VLASTNÉ |
| 12 | Context | Basic Memory, **Serena** | **AGENTS.md** | projektový profil LatteOS | INTEGROVAŤ |
| 13 | Permissions | — | **sandbox-runtime (srt) / bubblewrap** | **politika LatteOS** | INTEGROVAŤ + VLASTNÉ |
| 14 | AI Usage | **CodexBar CLI** | statusline Claude Code, ccusage | prstene a predpoveď | INTEGROVAŤ |

---

## 1. WebTabs — správa viacerých AI webových služieb

**Dnes v LensAI:** QtWebEngine, profil na službu, nič sa do stránok nevkladá, prednačítanie (~3,3 GB za 7 webov).

| Kandidát | Typ | Technológia | Licencia | Integrácia |
|---|---|---|---|---|
| **Ferdium** (`ferdium/ferdium-app`) | 🟢 hotový | Electron, TypeScript, MobX | Apache-2.0 | inšpirácia (hibernácia) |
| Qt WebEngine `lifecycleState` | 🔵 komponent | C++/QML (Chromium) | LGPL/GPL (Qt) | už použité |
| qutebrowser | inšpirácia | Python + QtWebEngine | GPL-3.0 | lenivé načítanie, zahadzovanie |
| Multi-AI Chat Desktop (`TED-H-com`) | alternatíva | Tauri 2, Rust + TS | MIT | iba inšpirácia (vkladá skripty) |
| Panelize (`Manho/Panelize`) | alternatíva | rozšírenie Chrome MV3 | MIT | iba inšpirácia (odstraňuje XFO/CSP) |

- **Ferdium:** každá služba v izolovanom webview s vlastným úložiskom cookies; automatická hibernácia nepoužívaných
  služieb (predvolene po 5 min), vypnutie hibernácie pre jednotlivú službu, voľba „ostať uspaný po štarte“, ručné
  uspať/zobudiť v ponuke. *Výhoda:* overené na miliónoch hodín. *Nevýhoda:* Electron, „recepty“ vkladajú JS do stránok
  (presne to LensAI nechce), posledná väčšia aktivita v repe 2024.
- **Multi-AI / Panelize:** jedna otázka viacerým webom naraz, ale cez vkladanie skriptov a obchádzanie hlavičiek —
  pre LensAI neprijateľné (10B.35). Užitočné iba nápady UI: rozloženia mriežky (Panelize 22 rozložení), knižnica výziev
  s premennými, export všetkých odpovedí do jedného obrázka.
- 🟠 **Vlastné:** nikto nemá kombináciu Qt/Wayland + žiadne skripty + profil na službu + strážca podmienok. Prevziať
  z Ferdia **stratégie hibernácie** (čas, výnimky na službu, ručné ovládanie) a z Vivaldi Memory Saver **prispôsobenie
  podľa častosti použitia**; implementovať cez Qt `Frozen` → `Discarded`.

**Verdikt: PONECHAŤ** vlastné, čerpať z Ferdia.

---

## 2. Model Router — správca lokálnych modelov

**Dnes v LensAI:** `latte-ai` spúšťa jeden `llama-server -m`, zmena modelu = reštart, ručné `-ngl`.

| Kandidát | Typ | Technológia | Licencia | Integrácia |
|---|---|---|---|---|
| **llama.cpp — režim router** (`ggml-org/llama.cpp`) | 🟢 hotový | C++ | MIT | priame použitie |
| **llama-swap** (`mostlygeek/llama-swap`) | 🔵 / 🟢 | Go, jeden binárny súbor | MIT | priame použitie, záloha |
| llmsnap (`napmany/llmsnap`) | alternatíva | Go (fork llama-swap) | MIT | sledovať (spánok/prebudenie) |
| Ollama | alternatíva | Go nad llama.cpp | MIT | nie (vlastný formát modelov) |
| LM Studio | alternatíva | uzavretý | proprietárny | iba inšpirácia UI |

- **llama.cpp router:** modely sa nahrávajú a uvoľňujú na požiadanie bez reštartu servera, každý vo vlastnom procese,
  obmedzenie počtu naraz (LRU), predvoľby v INI, režim spánku. Rovnaký projekt, ktorý LensAI už používa → najmenej
  závislostí.
- **llama-swap:** transparentný proxy server, ktorý prepína modely podľa požiadavky; funguje s **akýmkoľvek** serverom
  s OpenAI API — teda aj s whisper serverom (`/v1/audio/transcriptions`) a generovaním obrázkov (`/v1/images/generations`),
  vie „skupiny“ modelov bežiacich naraz, webové UI a ručné uvoľnenie modelu. *Výhoda oproti routeru:* jeden koncový bod
  pre text, reč aj obrázky. *Nevýhoda:* ďalší proces a konfigurácia navyše.
- 🟠 **Vlastné:** iba **tenká politika** v `latte-ai`: koľko VRAM smie AI vziať, keď beží hra alebo ComfyUI;
  predvoľby Kvalita/Vyvážené/Rýchlosť; ktorý model pre pomocníkov. To nikto iný nevie, lebo nepozná LatteOS.

**Verdikt: NAHRADIŤ** vlastnú správu procesov routerom llama.cpp. **llama-swap** zapojiť, keď sa pridá prepis reči
a obrázky pod jeden koncový bod.

---

## 3. Hardware Detection — detekcia a odporúčanie modelov podľa hardvéru

**Dnes v LensAI:** sysfs + `nvidia-smi`, celková VRAM, odhad z hlavičky GGUF a meranie `llama-fit-params`.

| Kandidát | Typ | Technológia | Licencia | Integrácia |
|---|---|---|---|---|
| **llmfit** (`AlexsJones/llmfit`) | 🟢 hotový | Rust, TUI + CLI (`--json`) | MIT | CLI alebo knižnica |
| Odysseus `services/hwfit/` | inšpirácia | Python | AGPL-3.0 | prepísať nápady |
| llama.cpp `--fit` / `llama-fit-params` | 🔵 komponent | C++ | MIT | už čiastočne použité |
| llm-checker | alternatíva | Node.js | overiť | sledovať (sťahuje a meria cez Ollama) |

- **llmfit:** zistí CPU, RAM, GPU, VRAM a backend (CUDA, ROCm, Metal, SYCL, CPU); hodnotí modely v štyroch smeroch
  (kvalita, rýchlosť, zmestí sa, kontext) podľa účelu; režimy GPU / MoE offload / CPU+GPU / CPU; **plán „čo dokúpiť“**
  a **simulácia hardvéru**; JSON výstup pre skripty. Rust → sedí k `crates/` LatteOS. *Nevýhoda:* vlastný katalóg
  modelov (treba ho dopĺňať o slovenčinu a MTP), odhad pamäte hrubší ako meranie llama.cpp.
- **Odysseus:** najlepšie riešené okrajové prípady — `nvidia-smi` mimo PATH, nezhoda ovládača po aktualizácii,
  rozlíšenie AMD RDNA/CDNA/GCN, hardvér iného PC cez SSH (Windows/Linux/Termux), upozornenie v kontajneri, ručné zadanie,
  tri profily spúšťania s konkrétnymi prepínačmi llama.cpp. AGPL → **prepísať**, nie kopírovať (ak LensAI nebude AGPL).
- 🟠 **Vlastné:** **voľná** VRAM v reálnom čase (hra beží), stupne výkonu LatteOS (`LATTE_TIER`), presné meranie
  `llama-fit-params` ako posledné slovo pred spustením.

**Verdikt: INTEGROVAŤ** llmfit (skóre, katalóg, plán nákupu), **PONECHAŤ** meranie LensAI, prepísať okrajové prípady
z Odysseus.

---

## 4. MCP — host, gateway a discovery

**Dnes v LensAI:** `latte-mcp` dáva jednu sadu konektorov API modelom, lokálnej AI aj CLI; všetky schémy naraz.

| Kandidát | Typ | Technológia | Licencia | Integrácia |
|---|---|---|---|---|
| **swarmclawai/mcp-gateway** (+ `mcp-core`) | 🟢 / 🔵 | Node.js/TypeScript | MIT | prevziať nápad alebo knižnicu |
| Docker MCP Gateway (`docker/mcp-gateway`) | alternatíva | Go | MIT (podľa 2 zdrojov; overiť) | sledovať (vyžaduje Docker) |
| IBM ContextForge | alternatíva | Python | Apache-2.0 | nie (podnikový, ťažký) |
| MetaMCP | alternatíva | TypeScript | overiť | inšpirácia (menné priestory) |
| sparfenyuk/mcp-proxy | 🔵 komponent | Python | MIT (overiť) | stdio ↔ HTTP pre Agent Chats |
| **Oficiálny MCP Registry** (`modelcontextprotocol/registry`) | 🔵 discovery | Go, REST API | API MIT, dáta overiť | čítať katalóg |

- **swarmclawai/mcp-gateway:** lenivé načítanie schém, menné priestory serverov, jediný vstavaný nástroj
  `mcp_tool_search`, voľba `alwaysExpose` na server, profily nástrojov. Knižničná časť `mcp-core` sa dá zabudovať
  bez samostatného procesu.
- **Docker MCP Gateway:** každý server v izolovanom kontajneri s obmedzenou sieťou, tajomstvá injektované pri štarte.
  *Výhoda:* bezpečnosť. *Nevýhoda:* Docker ako závislosť; LatteOS má vlastné kontajnery → izoláciu radšej cez srt (13).
- **MCP Registry:** oficiálny katalóg verejných MCP serverov s REST API a overením vlastníctva mena; stále **preview**
  (možné zmeny). Ideálny zdroj pre „Menu lístok“ konektorov (10B.38).
- 🟠 **Vlastné:** `latte-mcp` ostáva **host s pravidlami LatteOS** (kto smie čo, vypínač AI, GuardCorgi, záznam volaní,
  Späť). To žiadny gateway nemá.

**Verdikt: PONECHAŤ** latte-mcp, **INTEGROVAŤ** lenivé vyhľadávanie nástrojov (podľa swarmclawai, MIT), katalóg
z MCP Registry, izoláciu serverov cez srt.

---

## 5. ACP — klientská implementácia Agent Client Protocol

**Dnes v LensAI:** agenti v termináli, stav z titulku okna, relácie Claude Code zo záznamov.

| Kandidát | Typ | Technológia | Licencia | Integrácia |
|---|---|---|---|---|
| **`agent-client-protocol`** (`agentclientprotocol/rust-sdk`) | 🔵 knižnica | Rust (tokio) | Apache-2.0 | priamo do `crates/` |
| `acpx` (crate) | 🔵 tenká vrstva | Rust | overiť | spúšťanie agentov + register |
| sacp (Symposium) | alternatíva | Rust | MIT OR Apache-2.0 | sledovať |
| Zed | 🟢 referenčný klient | Rust | GPL (editor) | inšpirácia UI |
| `claude-agent-acp`, `codex-acp` | 🔵 adaptéry | TypeScript | overiť | spúšťať ako procesy |

- **Oficiálne Rust SDK:** obe strany protokolu (klient aj agent), typy pre relácie, výzvy, volania nástrojov a
  **žiadosti o povolenie**; doplnky: `-tokio` (spúšťanie procesov agentov), `-http` (HTTP/SSE, WebSocket),
  `-rmcp` (MCP nástroje), `-conductor` (reťazenie proxy medzi klientom a agentom). Apache-2.0 → voľne použiteľné.
- **Gemini CLI** má ACP vstavané (`--acp`), Claude Code a Codex cez adaptéry.
- 🟠 **Vlastné:** iba UI v QML — „Čaká na teba“ s Povoliť/Odmietnuť, diffy, plán, priebeh.

**Verdikt: INTEGROVAŤ** Rust SDK ako malý démon `latte-acp`; titulky terminálu ostanú iba ako záloha.

---

## 6. Skills — správca a kompatibilita skillov

**Dnes v LensAI:** `latte-skill` = jedno miesto skillov, stránka Skilly.

| Kandidát | Typ | Technológia | Licencia | Integrácia |
|---|---|---|---|---|
| **vercel-labs/skills** (`npx skills`) | 🟢 hotový | Node.js CLI | MIT | backend inštalácie |
| **Špecifikácia Agent Skills** (`agentskills/agentskills`) | 🔵 štandard + validátor | — | Apache-2.0 (kód), CC-BY-4.0 (dokumenty) | povinný formát |
| skills.sh | discovery | web register | — | zdroj katalógu |
| Pluginy Claude Code | alternatíva | — | — | čítať ich skilly (chýba na stránke Skilly) |

- **vercel-labs/skills:** inštaluje skilly z GitHubu, GitLabu, URL alebo miestneho priečinka do správnych priečinkov
  40+ agentov (kopírovaním alebo odkazom), `list`, `use` bez inštalácie, globálne aj pre projekt. *Nevýhoda:*
  závislosť na Node.js a **telemetria** (v dokumentácii CLI je sekcia Telemetry → vypnúť).
- 🟠 **Vlastné:** `latte-skill` ako **obchod s kontrolou** — zdroj, licencia, oprávnenia, kontrola GuardCorgi/CloneGuard
  pred inštaláciou; to `npx skills` nerobí.

**Verdikt: PONECHAŤ** latte-skill ako rozhranie a strážcu, **INTEGROVAŤ** formát Agent Skills a voliteľne
`skills` CLI ako mechanizmus inštalácie.

---

## 7. Chat History — indexovanie rozhovorov

**Dnes v LensAI:** JSON súbor na rozhovor + relácie Claude Code; bez spoločného hľadania.

| Kandidát | Typ | Technológia | Licencia | Integrácia |
|---|---|---|---|---|
| memex (`memex-chats`) | inšpirácia | Python, SQLite + sqlite-vec, MCP | overiť | vzor architektúry |
| doc-memory (`mcarlson/doc-memory`) | alternatíva | TypeScript, SQLite/Postgres | overiť | sledovať |
| **SQLite FTS5** | 🔵 komponent | C | public domain | základ indexu |
| **sqlite-vec** (`asg017/sqlite-vec`) | 🔵 komponent | C rozšírenie SQLite | MIT/Apache (overiť) | vektory v tom istom súbore |
| **e5-sk-small** | 🔵 model | 45 M parametrov | overiť na HF | slovenské vektory |
| tantivy | alternatíva | Rust | MIT | ak by FTS5 nestačil |

- **memex:** indexuje históriu claude.ai aj relácie Claude Code, hybridné hľadanie (vektory + FTS5 BM25 cez Reciprocal
  Rank Fusion), lokálne embeddingy, MCP cez stdio aj vzdialene. Alpha. Presne vzor, ktorý LensAI potrebuje — ale iba
  pre Claude.
- 🟠 **Vlastné:** **áno.** Nikto neindexuje naraz LensAI, Claude Code, Codex, importy ChatGPT/Gemini a Obsidian,
  a nikto nemá slovenské vektory. Postaviť nad FTS5 + sqlite-vec + e5-sk, vystaviť ako nástroj `search_chats` v latte-mcp.

**Verdikt: VLASTNÉ** nad overenými knižnicami, memex ako vzor.

---

## 8. Memory — lokálna AI pamäť

**Dnes v LensAI:** pokyny pre každú AI (`ai-instructions.txt`); trvalá pamäť chýba.

| Kandidát | Typ | Technológia | Licencia | Integrácia |
|---|---|---|---|---|
| **Basic Memory** (`basicmachines-co/basic-memory`) | 🟢 hotový | Python, MCP, SQLite | AGPL-3.0 | MCP server vedľa (licencia OK) |
| Mem0 | alternatíva | Python, vektory + graf | Apache-2.0 | sledovať |
| Letta (MemGPT) | alternatíva | Python, runtime agentov | Apache-2.0 | nie (celý runtime) |
| Graphiti (Zep) | 🔵 knižnica | Python, časový graf | Apache-2.0 | ak treba „čo platilo kedy“ |
| Cognee | alternatíva | Python, graf | Apache-2.0 | sledovať |

- **Basic Memory:** zdroj pravdy sú **Markdown súbory**, ktoré upravuje človek aj AI; lokálny SQLite index a graf
  vzťahov; funguje s Obsidianom; MCP server. Sedí presne k plánu „Obsidian ako lokálny kontext“ (10B.37). AGPL nevadí,
  lebo beží ako samostatný MCP proces.
- **Mem0/Letta/Graphiti/Cognee:** silnejšie na automatické vyťahovanie faktov a časové vzťahy, ale pamäť je mimo
  čitateľných súborov — horšie pre používateľa, ktorý chce vidieť a upraviť, čo si AI pamätá.

**Verdikt: INTEGROVAŤ** Basic Memory ako MCP server cez latte-mcp, trezor = priečinok Obsidianu; Graphiti **SLEDOVAŤ**.

---

## 9. Voice — slovenský STT, VAD a TTS

**Dnes v LensAI:** whisper.cpp (large-v3-turbo s Vulkanom, inak small).

| Kandidát | Typ | Technológia | Licencia | Integrácia |
|---|---|---|---|---|
| **sherpa-onnx** (`k2-fsa/sherpa-onnx`) | 🔵 knižnica | C++ + Python/C/Go/…, ONNX Runtime | Apache-2.0 | jeden runtime pre STT, VAD, TTS |
| **KInIT Canary 1B v2 sk / Parakeet sk** | 🔵 modely STT | NVIDIA NeMo | CC-BY-4.0 | cez sherpa-onnx |
| BuzzASR Slovak | alternatíva STT | whisper-large-v3 fine-tune | overiť | do whisper.cpp |
| **Silero VAD** | 🔵 VAD | ONNX | MIT | v sherpa-onnx |
| TEN VAD | alternatíva VAD | C/ONNX | Apache-2.0 + extra podmienky | **nie** (podmienky licencie) |
| **Piper — hlas sk_SK Lili** | 🔵 TTS | VITS/ONNX | dáta Lili CC0-1.0; model overiť | cez sherpa-onnx |
| Chatterbox Multilingual | alternatíva TTS | PyTorch | MIT | slovenčinu nemá; komunitný sk fine-tune existuje |
| hyprwhspr, Handy | 🟢 diktovanie | Linux/Wayland | overiť | vzor pre 10B.17 |

- **sherpa-onnx:** jeden runtime na rozpoznávanie reči (aj NeMo transducery a Parakeet), syntézu (Piper, Kokoro,
  Matcha…), VAD (Silero aj TEN), kľúčové slová, identifikáciu hovoriaceho; beží na procesore. Nahradí viac nástrojov naraz.
- **STT slovensky:** KInIT Canary 1B v2 sk 6,37 % chýb slov (základ 14,39 %), Parakeet TDT 0.6B v3 sk 6,62 % (základ
  24,32 %), vo vlastnom teste KInIT.
- **VAD:** Silero má lepšie výsledky na šume a čistú licenciu MIT; TEN VAD je rýchlejší, ale jeho licencia zakazuje
  nasadenia, ktoré konkurujú Agore → pre LatteOS riziko.
- **TTS slovensky:** najslabšie miesto trhu. Piper Lili je jediný použiteľný lokálny slovenský hlas; Chatterbox
  Multilingual (MIT) má 23 jazykov bez slovenčiny, XTTS-v2, F5-TTS a Fish Speech majú nekomerčné licencie.
- 🟠 **Vlastné:** **slovenský hlas LatteOS** — dotrénovať Chatterbox (MIT) na datasete Lili (CC0, ~2 h jedného hlasu)
  alebo na väčšom slovenskom súbore. Komunita už ukázala, že slovenský fine-tune Chatterboxu ide.

**Verdikt: INTEGROVAŤ** sherpa-onnx + KInIT modely + Silero VAD; TTS teraz Piper Lili, **VLASTNÝ** slovenský hlas neskôr.

---

## 10. Agent Chats — viacagentové prostredia

**Dnes v LensAI:** rozhodnutý fork agentes-chat (17. 11.), Kaviareň pozastavená.

| Kandidát | Typ | Technológia | Licencia | Integrácia |
|---|---|---|---|---|
| **agentes.chat** | 🟢 hotový | web (tímový chat), Docker Compose + Postgres | AGPL-3.0 | fork (rozhodnuté) |
| **Eigent** (`eigent-ai/eigent`) | 🟢 alternatíva | Electron + React/TS, FastAPI, CAMEL | Apache-2.0 + doplnkové podmienky | overiť licenciu pred forkom |
| Orca, Emdash, Superset | alternatívy (kód) | desktop, git worktree | overiť | inšpirácia (paralelní agenti) |
| ACP `conductor` | 🔵 komponent | Rust | Apache-2.0 | orchestrácia nad ACP |
| CAMEL | 🔵 knižnica | Python | overiť | iba ak vlastná farma |

- **agentes.chat:** agenti sú členovia pracovného priestoru ako v Slacku; model na agenta (Claude, Codex, Gemini, Grok,
  OpenRouter), MCP nástroje, prehliadač a počítač na agenta, rutiny, pamäť, schvaľovacie brány a rozpočty.
  *Nevýhoda:* Postgres + Docker = ťažké pre desktop.
- **Eigent:** desktopová „pracovná sila“ agentov (vývojár, hľadanie, dokumenty, multimodálny), lokálne modely, MCP,
  človek v slučke. *Pozor:* licencia je Apache-2.0 **s doplnkovými podmienkami**.
- 🟠 **Vlastné:** Kaviareň ako **vizualizácia** nad ACP agentmi + skillmi (`lensAIplan.md` 6.3); orchestrácia cez
  ACP conductor.

**Verdikt: SLEDOVAŤ** — pred forkom spraviť jednu skutočnú úlohu v agentes.chat **aj** v Eigent a porovnať záťaž
(RAM, procesy) a licenciu. Ak ani jeden nesedí, vlastná Kaviareň nad ACP.

---

## 11. AI Comparison — porovnávanie modelov

**Dnes v LensAI:** nástroj `ask`, dve záložky vedľa seba.

| Kandidát | Typ | Technológia | Licencia | Integrácia |
|---|---|---|---|---|
| **promptfoo** (`promptfoo/promptfoo`) | 🟢 hotový | TypeScript/Node CLI + web | MIT | CLI ako backend testov |
| Odysseus Compare | inšpirácia | Python | AGPL-3.0 | slepé porovnanie (nápad) |
| promptside | alternatíva | Node CLI | overiť | rýchle HTML porovnanie |
| Multi-AI Chat / Panelize | iba UI nápady | — | MIT | nie (weby) |

- **promptfoo:** testy v YAML (výzvy, prípady, kontroly), matica výsledkov naprieč modelmi, lokálny webový prehliadač,
  OpenAI/Anthropic/Gemini/Ollama/llama.cpp a čokoľvek s OpenAI API; plne lokálne pod MIT. Hodí sa na **pevné sady úloh**
  („moje slovenské otázky“) pri výbere modelu.
- 🟠 **Vlastné:** **slepé porovnanie v LensAI** (mená skryté, volí používateľ) a z volieb **osobné poradie modelov
  podľa typu úlohy**, ktoré napája úrovne rýchly/bežný/najlepší (10B.39). Toto nikto nerobí pre jedného človeka.

**Verdikt: INTEGROVAŤ** promptfoo + **VLASTNÉ** slepé porovnanie.

---

## 12. Context — projektový kontext

**Dnes v LensAI:** pokyny pre každú AI; Obsidian plánovaný (10B.37); Workfield/Continuity plánovaný v LatteOS.

| Kandidát | Typ | Technológia | Licencia | Integrácia |
|---|---|---|---|---|
| **AGENTS.md** | 🔵 štandard | Markdown | otvorený štandard (AAIF / Linux Foundation) | súbor v každom projekte |
| **Serena** (`oraios/serena`) | 🟢 hotový | Python, LSP, MCP | MIT | MCP server pre kód |
| Basic Memory | 🟢 hotový | (pozri 8) | AGPL-3.0 | znalosti projektu |
| Obsidian | zdroj | — | uzavretý (súbory otvorené) | priečinok = kontext |

- **AGENTS.md:** „README pre agentov“ v koreni projektu (zostavenie, testy, pravidlá); spravuje ho Agentic AI
  Foundation pod Linux Foundation; číta ho Codex, Copilot, Cursor, Gemini CLI a ďalšie, používa ho 60 000+ repozitárov.
- **Serena:** agent pracuje s kódom po symboloch cez jazykové servery (LSP) namiesto čítania celých súborov a grepu;
  40+ jazykov, MCP server, MIT.
- 🟠 **Vlastné:** **projektový profil LatteOS** = priečinok + `AGENTS.md` + poznámky v Basic Memory + skilly + profil
  MCP nástrojov + Workfield (okná a aplikácie). LensAI pri otvorení projektu nastaví všetko naraz.

**Verdikt: INTEGROVAŤ** AGENTS.md a Serena; **VLASTNÝ** projektový profil.

---

## 13. Permissions — oprávnenia agentov

**Dnes v LensAI:** „Urob to“ s plánom, bez automatického schvaľovania; pravidlá rúk pleamar-wm; dôveryhodné/
nedôveryhodné profily LatteOS.

| Kandidát | Typ | Technológia | Licencia | Integrácia |
|---|---|---|---|---|
| **sandbox-runtime (srt)** (`anthropic-experimental/sandbox-runtime`) | 🔵 komponent | TypeScript CLI + knižnica; Linux bubblewrap | Apache-2.0 | obal pre agentov a MCP servery |
| bubblewrap | 🔵 komponent | C (Flatpak) | LGPL (overiť) | priamo, bez Node.js |
| Landlock | 🔵 jadro Linuxu | LSM | GPL (jadro) | doplnok |
| Docker MCP Gateway | alternatíva | Go | pozri 4 | izolácia v kontajneri |
| ACP `request_permission` | 🔵 protokol | — | Apache-2.0 | kanál pre otázky |

- **srt:** obmedzí súbory a sieť ľubovoľného procesu na úrovni OS bez kontajnera (Linux: bubblewrap + proxy so
  zoznamom povolených domén); vznikol pre Claude Code a vie obaliť agentov, MCP servery aj príkazy. Závislosti na Linuxe:
  bubblewrap, socat, ripgrep. *Pozor:* stav „beta research preview“.
- 🟠 **Vlastné:** **politika LatteOS** — kto je dôveryhodný, čo smie ktorý agent, ktoré priečinky a domény, kedy sa pýtať
  (ACP), záznam pre GuardCorgi a Späť. Vynucovanie zveriť srt/bubblewrap, nepísať vlastný sandbox.

**Verdikt: INTEGROVAŤ** srt (alebo priamo bubblewrap), **VLASTNÁ** politika.

---

## 14. AI Usage — limity a spotreba

**Dnes v LensAI:** spotreba ako v Omarchy (Claude, Grok, Copilot, ChatGPT), prstene.

| Kandidát | Typ | Technológia | Licencia | Integrácia |
|---|---|---|---|---|
| **CodexBar** (`steipete/CodexBar`) | 🟢 hotový | Swift; **Linux CLI** `codexbar` (statické zostavenia, AUR `codexbar-cli`) | MIT | CLI ako zdroj dát |
| Statusline Claude Code | 🔵 oficiálny zdroj | JSON `rate_limits` | — | presné % pre Claude |
| ccusage (`ryoppippi/ccusage`) | 🔵 komponent | Node.js | MIT | lokálna spotreba tokenov |
| TuxMeter (`debba/tuxmeter`) | alternatíva | Tauri, Linux port OpenUsage | MIT | inšpirácia UI |
| caut | alternatíva | Rust | „MIT+Rider“ (neštandardná) | nie bez preverenia |

- **CodexBar:** limity, resety, kredity a útraty desiatok poskytovateľov (Claude, Codex, Gemini, Copilot, Cursor,
  OpenRouter…), bez ukladania hesiel; má Linux CLI a komunitný modul pre Waybar v Omarchy. LensAI ho môže volať ako
  `latte-ai usage` volá Omarchy dnes.
- **Statusline Claude Code:** oficiálne `rate_limits.five_hour` a `seven_day` (`used_percentage`, `resets_at`).
- 🟠 **Vlastné:** prstene, predpoveď („pri tomto tempe minieš týždenný limit vo štvrtok“), upozornenie pred limitom
  a návrh prepnúť na lokálnu AI.

**Verdikt: INTEGROVAŤ** CodexBar CLI + statusline + ccusage; UI a predpoveď **VLASTNÉ**.

---

## Extra: funkcie, na ktoré sa zatiaľ zabudlo

Nájdené pri prieskume u konkurencie; v ROADMAP 10B ich zatiaľ nevidím.

1. **Knižnica výziev s premennými** (`{téma}`, `{jazyk}`) — Panelize to má; v LensAI ako skill alebo riadok LensShore.
2. **Export odpovedí** — viac odpovedí do jedného Markdownu alebo obrázka (Panelize), PDF rozhovoru.
3. **Odovzdanie rozhovoru inej AI** („handoff“) — zhrnutie a kontext cez API/MCP, nie kopírovaním z webu.
4. **Rozpočty a stropy** pre kľúče API na mesiac a na agenta (agentes.chat to má) + upozornenie pred prekročením.
5. **Rutiny agentov** — plánované úlohy („každé ráno zhrň novinky v mojich projektoch“), agentes.chat to má.
6. **Lokálne hľadanie na webe pre lokálne modely** — SearXNG (Odysseus ho má v `config/searxng`), aby lokálna AI
   nemusela ísť do cloudu kvôli aktuálnym faktom.
7. **Lokálny „Deep Research“** — viac krokov hľadania a správa (Odysseus).
8. **Kľúčové slovo „Hej, Latte“** — offline rozpoznanie kľúčového slova (sherpa-onnx KWS) pre hlas bez klávesy.
9. **Čítanie odpovedí nahlas** (Piper Lili) a **rozlíšenie hovoriacich** v nahrávke porady (sherpa-onnx speaker ID).
10. **Maskovanie osobných údajov** pred odoslaním do cloudu (mená, e-maily, čísla) — voliteľný filter v latte-ai.
11. **Strážca nových modelov** — upozorní, keď vyjde lepší model pre tento hardvér alebo nová verzia llama.cpp;
    dá sa postaviť na Bean Scout.
12. **Záloha a prenos LensAI** — rozhovory, profily webov, nastavenia a pamäť jedným balíkom (súvisí so Session Managerom).
13. **Kontrola MCP servera pred inštaláciou** v izolácii srt (beh naprázdno, aké súbory a domény chce) — spojenie
    GuardCorgi + CloneGuard + srt.
14. **Osobné poradie modelov** z palcov hore/dole pri odpovediach (súvisí s 11).
15. **Lokálne OCR** pre „AI pri kurzore“ nad obrázkom alebo snímkou obrazovky (napr. Tesseract so slovenčinou).

---

## Zdroje

- WebTabs: [Ferdium](https://github.com/ferdium/ferdium-app), [Multi-AI Chat Desktop](https://github.com/TED-H-com/multi-ai-chat-desktop),
  [Panelize](https://panelize.dev/), [Qt WebEngine Lifecycle](https://doc.qt.io/qt/qtwebengine-webenginequick-lifecycle-example.html)
- Router: [llama.cpp server](https://github.com/ggml-org/llama.cpp/tree/master/tools/server), [llama-swap](https://github.com/mostlygeek/llama-swap)
- Hardvér: [llmfit](https://github.com/AlexsJones/llmfit), [Odysseus](https://github.com/odysseus-dev/odysseus)
- MCP: [swarmclawai/mcp-gateway](https://github.com/swarmclawai/mcp-gateway), [MCP Registry](https://github.com/modelcontextprotocol/registry),
  [IBM ContextForge](https://github.com/ibm/mcp-context-forge)
- ACP: [rust-sdk](https://github.com/agentclientprotocol/rust-sdk), [agentclientprotocol.com](https://agentclientprotocol.com/)
- Skills: [vercel-labs/skills](https://github.com/vercel-labs/skills), [agentskills.io](https://agentskills.io/specification)
- História: [memex-chats](https://pypi.org/project/memex-chats/), [sqlite-vec](https://github.com/asg017/sqlite-vec),
  [SkMTEB / e5-sk](https://aclanthology.org/2026.acl-long.2114.pdf)
- Pamäť: [Basic Memory](https://github.com/basicmachines-co/basic-memory)
- Hlas: [sherpa-onnx](https://github.com/k2-fsa/sherpa-onnx), [kinit/canary-1b-v2-sk](https://huggingface.co/kinit/canary-1b-v2-sk),
  [Silero VAD](https://github.com/snakers4/silero-vad), [Lili dataset](https://datacollective.mozillafoundation.org/datasets/cmiup5wqw01hlmf074qy07b80)
- Agenti: [agentes.chat](https://agentes.chat), [Eigent](https://github.com/eigent-ai/eigent)
- Porovnanie: [promptfoo](https://github.com/promptfoo/promptfoo)
- Kontext: [AGENTS.md](https://www.agents.md), [Serena](https://github.com/oraios/serena)
- Oprávnenia: [sandbox-runtime](https://github.com/anthropic-experimental/sandbox-runtime)
- Spotreba: [CodexBar](https://github.com/steipete/CodexBar), [ccusage](https://github.com/ryoppippi/ccusage),
  [Claude Code statusline](https://code.claude.com/docs/en/statusline)

---

## Fork Agent Chats — požiadavky a návrh riešení (18. 11.)

Doplnené 18. 11. podľa rozhovoru s používateľom. Zistenia sú z **kódu agentes.chat** (`github.com/agentes-chat/agentes-chat`,
commit `2be878a` z 18. 11. 2026, AGPL-3.0) a jeho ADR v `docs/adr/`. Návrhy riešení sú návrhy, nie rozhodnutia.

### Požiadavky používateľa

1. **Všetky projekty na jednom mieste**, nie roztrúsené, podobne ako projekty v Claude: projekt = priečinok s viacerými
   četmi, ktoré zdieľajú pamäť.
2. **Kanál = projekt**, pod ním **podkanál = podprojekt**, v podkanáli jednotlivé **čety** (napr. #knihy-magna-moravia
   → ##kniha-1 → postavy, časť 1, kapitola 17, betaread).
3. **Stav projektu** prepínateľný ikonou (aktívny, pozastavený, hotový, archivovaný) a **typ projektu** označený ikonou
   (kód, kreslenie, kniha, 3D, hudba, komiks).
4. **Pamäť vo vrstvách:** globálna (nad všetkým) → pamäť projektu (primárna) → pamäť podprojektu (sekundárna). Platia všetky
   naraz.
5. **Projekty majú skutočné priečinky** so súbormi a artefaktmi, nielen záznam.
6. **Prístup agenta:** agent v ##kniha-1 pracuje v `Kniha1/`, smie siahnuť do nadradeného `MagnaMoravia/` (šablóny,
   worldbuilding), ale nie vyššie.
7. **Projekt má pridelených agentov, ich AI, skilly, schopnosti a povahu**; iné projekty iné napojenia (napr. komiks →
   ComfyUI text2image).
8. **Zámok projektu / súkromný režim:** projekt vylúčený z pamäti a z dosahu iných AI, napr. bez ChatGPT, iba Grok
   a lokálna AI.
9. **Vzdialený človek** sa pripojí na projekt aj s pôvodnou, neforkovanou aplikáciou a pracuje s pridelenými botmi.
10. **Vývoj LatteOS priamo v Agent Chats** bez VS Code, s GitHubom.

### Čo agentes.chat už má (z kódu)

| Oblasť | Stav v agentes.chat | Kde |
|---|---|---|
| Kanály | iba záznam v Postgrese (`channels`: meno, téma, viditeľnosť, `category_id`, `position`, `archived_at`) | `packages/db/src/schema/chat.ts` |
| Skupiny kanálov | **kategórie** v bočnom paneli, **jedna úroveň**, zbaľovanie každý sám; vnorenie nie je | ADR 0080 |
| Čety | vlákna v kanáli | `packages/engine/src/threads.ts` |
| Pamäť | tabuľka `context_items` s rozsahom `thread`, `channel`, `org`, `agent`, `entity`; viditeľnosť sa dedí od kanálov (najprísnejšia); zhrnutia kanálov už vznikajú; povýšenie „Make it the team's“ | `packages/db/src/schema/context.ts`, `context/summaries.ts` |
| Kontext organizácie | text o organizácii ide do systémového pokynu každého agenta pracovného priestoru | `organizations.context` |
| Súbory | Drive v zväzku `files`, bucket S3/MinIO alebo v Postgrese; nie strom priečinkov | `SELF_HOSTING.md` |
| Priečinky agentov | `~/agentes/<workspace>` na agenta, ďalšie povolené na úrovni pracovného priestoru; blokovanie je „pravidlo, nie bariéra“ (agenti bežia pod účtom používateľa) | docs `computers` |
| Práca na kóde | **misie** s vlastným git worktree a vetvou `agentes/<agent>/…`, súbory `.agentes/mission.md`, zlúčenie/nasadenie iba so schválením | ADR 0029, 0044 |
| GitHub | GitHub App = identita pracovného priestoru (bot `<slug>[bot]`, podpis agenta, spoluautor), úzke tokeny na repo, push cez git proxy, agentov počítač token nemá; bez aplikácie účet cez OAuth/token | ADR 0024, 0116, 0156 |
| Výber agenta | @zmienka, inak smerovač (Jev → malý model → plán → pravidlá); agent v kanáli s `autoReply` | docs `who-answers`, `channel_members` |
| Oprávnenia | výnimky na kanál (kto vidí, píše, volá agentov) | ADR 0134 |
| Viac serverov | desktop aj mobil držia pracovné priestory z viacerých serverov naraz | ADR 0154 |
| Ľudia zvonku | „outside collaborators“ — člen bez platenej stoličky; hostia (vidia iba kde ich dajú) sú plánovaní | ADR 0191, 0085 |
| Federácia serverov | **nie je** — dva servery spolu priamo nekomunikujú | — |
| Fórum | odstránené 4. 11. 2026 | ADR 0022 |

### Návrh riešení vo forku

**Zásada kompatibility:** iba **pridané** stĺpce, tabuľky a koncové body; existujúce API sa nemení. Pôvodná aplikácia
potom funguje (podkanály vidí ako plochý zoznam, stav a typ ignoruje) a všetko, čo beží na serveri (pamäť, dedenie,
prístupy), platí aj pre ľudí s pôvodnou aplikáciou.

| # | Požiadavka | Riešenie vo forku | Rozsah |
|---|---|---|---|
| F1 | Podprojekty | `channels.parent_id` (jedna úroveň: projekt → podprojekt); bočný panel odsadí podkanály pod projekt a zbalí ich; kategórie ostávajú ako „police“ (Tvorba, LatteOS, Domov) | malý |
| F2 | Stav | `channels.status` = `active / paused / done / archived` (archived = existujúci `archived_at`); ikona na prepínanie v hlavičke a v bočnom paneli; filter „iba aktívne“ | malý |
| F3 | Typ | `channels.project_type` = `code / drawing / book / 3d / music / comic / other`; ikona pred menom; typ určuje predvolených agentov a konektory (F7) | malý |
| F4 | Vrstvy pamäte | nové rozsahy nad existujúcim `context_items`: načítanie vo vlákne v poradí **vlákno → podprojekt → projekt → organizácia → agent**; pri rozpore (rovnaký `subjectKey`) vyhráva bližšia úroveň; povýšenie „do podprojektu / do projektu / tímu“ rozšírením existujúceho povýšenia; stránka **Pamäť projektu** na kontrolu a mazanie | stredný |
| F5 | Priečinky | `channels.folder` = cesta na počítači (napr. `~/Projekty/MagnaMoravia/Kniha1`); podkanál dedí priečinok rodiča; Drive súbory kanála sa voliteľne zrkadlia do `folder/_drive/`; pamäť projektu sa voliteľne exportuje do `folder/pamat.md`; kódový projekt = repo (misie z neho robia worktree ako dnes); knižný projekt = trezor Obsidianu (wiki už vie import) | stredný |
| F6 | Prístup k priečinkom | agent v podkanáli: **vlastný priečinok čítanie+zápis, priečinok rodiča iba čítanie, súrodenci a všetko vyššie nič**; zmena v rodičovi = návrh na schválenie; vynútiť **sandboxom** (srt / bubblewrap: bind rw podprojekt, ro projekt), nie iba pravidlom | stredný |
| F7 | Agenti a konektory projektu | agenti sú členmi kanála už dnes; doplniť **dedenie** členstva a aplikácií z projektu do podprojektu a **profil konektorov na kanál** (komiks → ComfyUI MCP, kniha → bez obrázkov); povaha a skilly ostávajú pri agentovi (existuje) | malý |
| F8 | Zámok projektu | `channel_locks`: povolené AI (napr. `grok`, `local`), povolení agenti, `memory = separate | none`, sieť (zoznam domén); smerovač a výber modelu agenta odmietnu nepovolenú AI; pamäť zamknutého projektu sa nepovyšuje ani nehľadá zvonku; súbor zámku mimo priečinka projektu; v LensAI rovnaký zámok cez `latte-ai` a `latte-mcp` | stredný |
| F9 | Vzdialený človek | bez zmeny: bežný **člen** na tvojom serveri (na vlastnom serveri nie je žiadny limit ani poplatok) (domáci server dosiahnuteľný zvonku); desktop/mobil drží viac serverov naraz; neskôr hostia (vidia iba pridelené projekty) | žiadny |
| F10 | Vývoj LatteOS | GitHub App na repo `LatteOS-v0x-Jihlavanka`; misie na vlastných vetvách, do `v0.5-pleamarwm-jihlavanka` iba cez schválený pull request; revízia diffov v okne LensAI (alebo Orca); kanály podľa ROADMAP (#lensai, #goo, #system…), vlákno = jedna položka ROADMAP | žiadny / malý |
| F11 | Vlastné v forku (licencia) | meno a logo forku vlastné (ochranné známky agentes.chat), „Based on agentes.chat by AGENTESCHAT, LLC“ v NOTICE, zdroj forku verejný (AGPL), slovenčina, téma LatteOS, prihlásenie miestneho vlastníka bez hesla | — |

### Rozhodnuté 18. 11. (používateľ): online a offline projekty, fork servera aj klienta

| # | Rozhodnutie | Návrh riešenia | Rozsah |
|---|---|---|---|
| F12 | **Fork servera aj klienta.** Klient je zabudovaný v LensAI („všetko v jednom“: jedno prihlásenie, jedna sada skillov a MCP); pôvodné klienty aj servery sa dajú pripojiť | **Klient (LensAI):** zistí, čo server vie (verzia, zoznam funkcií), a čo nevie, skryje → s pôvodným serverom ide základ (kanály, vlákna, agenti). **Server (fork):** iba pridané funkcie F1–F8, pôvodný klient na ňom funguje. **Prihlásenie:** lokálny server cez kľúč vlastníka (`OWNER_KEY`) zo systémového účtu LatteOS; vzdialený raz, token v kľúčenke. **AI účty:** z `latte-ai` (osobné predplatné Claude/ChatGPT iba na serveri, ktorý prevádzkuje používateľ). **Skilly:** jeden priečinok `.agents/skills/`, server ho číta, žiadne kópie. **MCP:** `latte-mcp` jediný zdroj; lokálnemu serveru cez HTTP na 127.0.0.1, vzdialenému cez „počítač“ (agent beží na PC a má `latte-mcp`, kým je PC zapnuté) | veľký |
| F13 | **Dva druhy projektov.** **Offline:** priečinok iba na klientovi (PC), dáta iba tam, nikto zvonku, iba agenti. **Online:** priečinok na serveri aj u klienta, prístup iba pozvaným, dáta na serveri | offline projekt = lokálny server na PC (desktop agentes.chat to už vie, osobný režim ADR 0159); online projekt = domáci server (fork) cez Tailscale; v LensAI oba v jednom zozname s ikonou 🔒 offline / 🌐 online; presun projektu offline → online iba vedome (export → import, s otázkou, čo sa nahrá) | stredný |
| F14 | **Položka Agent Chats v LensAI** so stavom a vypínačom | informačné pole (stav lokálneho servera: beží / zastavený / sťahuje sa, RAM, disk, verzia, pripojené vzdialené servery) a tlačidlo **Zapnúť / Vypnúť** (load / unload ako lokálny model); server sa **nestiahne pri inštalácii LatteOS**, ale až pri prvom zapnutí, s informáciou o mieste a RAM (Postgres, aplikácia, voliteľne vektory ~3 GB); **deaktivované** → v ponuke ostane iba prázdna stránka s opisom Agent Chats a tlačidlom „Zapnúť“ | malý |
| F15 | **Synchronizácia dát online projektov** pri viacerých ľuďoch | agentes.chat **nemá** synchronizáciu súborov medzi počítačmi: má Drive (úložisko servera) a zdieľaný priečinok agentov na jednom počítači (ADR 0115). Preto **domáci git server**: **Forgejo** (GPL-3.0, ľahký, git LFS pre veľké súbory, issues, pull requesty) ako predvolený; alternatívy Gitea (MIT), GitLab CE (ťažký). Text a kód cez git (zlúčenie zmien, rozdiel, návrat), veľké binárne súbory cez git LFS alebo Syncthing. **Pozor:** hlboká integrácia agentes.chat je iba pre **GitHub** (GitHub App, git proxy, PR ako bot); GitLab má MCP konektor; Forgejo treba doplniť vo forku (konektor + misie s remote na Forgejo) alebo použiť obyčajný git remote | stredný |

### Rozhodnuté 18. 11. (používateľ): kde projekt žije a Forgejo vo forku

| # | Rozhodnutie | Návrh riešenia | Rozsah |
|---|---|---|---|
| F16 | **Každý #projekt má určené, kde žije:** 🔒 **offline** (iba PC), 🌐 **online GitHub**, 🏠 **online Forgejo** (domáci server) | `channels.storage` = `offline / github / forgejo` + adresa repa; voľba pri zakladaní projektu a v jeho nastaveniach; ikona pri mene projektu; podprojekt dedí od projektu; zmena miesta iba vedome (presun repa s otázkou, čo sa nahrá). Pravidlo: kód a bežné projekty na GitHub, **NSFW a citlivé na Forgejo** (GitHub zakazuje sexuálne obscénny obsah aj v súkromných repách a blokácia účtu by zasiahla aj LatteOS) | malý |
| F17 | **Forgejo ako alternatíva GitHubu vo forku servera** | na strane **servera**: Forgejo konektor (API kompatibilné s Gitea: repá, issues, pull requesty, komentáre), **misie s remote na Forgejo** (worktree a vetva `agentes/<agent>/…` ako pri GitHube), pull request ako **botový účet Forgejo** s podpisom agenta, push cez git proxy servera s úzkym tokenom (rovnaký model ako GitHub App, ADR 0024/0156); MCP server pre Forgejo overiť, inak vlastné nástroje | stredný |
| F18 | **Klient sa na Forgejo pripojí automaticky** | server v zozname svojich funkcií ohlási „Forgejo na adrese X“; forknutý klient (LensAI) sa prihlási **raz** — jednotné prihlásenie cez OAuth2/OIDC medzi Forgejo a agentes.chat (Forgejo vie byť poskytovateľ OAuth2; overiť smer), token v kľúčenke; pôvodný klient voľbu miesta a pripojenie nevidí, ale výsledky áno (odkazy na pull requesty, správy agentov), lebo práca s Forgejo beží na serveri | malý |

### Ako spolu komunikujú dva rôzne servery agentes.chat

**Priamo nijako — federácia serverov neexistuje.** Možnosti dnes:
1. **Človek, nie server, je most.** Kamarát sa pridá do tvojho pracovného priestoru ako člen alebo outside collaborator
   (ADR 0191). Jeho desktop alebo mobil drží naraz jeho server aj tvoj (ADR 0154), s neprečítanými správami z oboch.
   Pracuje s tvojimi botmi na tvojom serveri.
2. **Agenti sa dajú preniesť kópiou** (import „Bring your agents“: pokyny, skilly, rutiny, pamäť), ale potom žijú
   oddelene.
3. **Most cez MCP:** agentes.chat vystavuje MCP endpoint, cez ktorý ho môžu riadiť iné nástroje. Agent na serveri A
   by mohol mať server B ako konektor (MCP podľa URL, s tokenom) a cez neho klásť otázky agentom B. Funguje to na úrovni
   nástrojov, nie ako zdieľaný kanál.
4. **Fork, neskôr:** „zdieľaný kanál“ medzi dvoma servermi (ako Slack Connect) = zrkadlenie správ jedného kanála cez
   podpísané webhooky alebo cez Matrix. Veľký zásah a mimo kompatibility s originálom → až keď bude naozaj treba.

**Odporúčanie:** jeden server (tvoj domáci) pre tvoje projekty a ľudia sa naň pripájajú. Most cez MCP iba keď chce
spolupracovať niekto s vlastným serverom a vlastnými agentmi.

### Poradie

1. Nainštalovať pôvodný agentes.chat na domáci server, vyskúšať kategórie, misie a GitHub App na LatteOS (bez forku).
2. F1–F3 (podprojekty, stav, typ) — malé a viditeľné.
3. F5–F6 (priečinky + sandbox) — bez nich nemá zmysel pracovať na súboroch.
4. F4 (vrstvy pamäte) a F7 (konektory projektu).
5. F8 (zámok projektu) spolu s rovnakým zámkom v LensAI.
6. Most cez MCP iba podľa potreby.

### Otvorené

- Meno forku.
- Webová aplikácia v okne LensAI, alebo vlastný QML klient nad API forku.
- Či majú podprojekty mať vlastných členov (ľudí), alebo vždy dediť od projektu.
- Či sa Drive súbory majú zrkadliť do priečinka, alebo ostať iba v úložisku servera.
