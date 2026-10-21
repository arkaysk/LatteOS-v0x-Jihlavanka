# AI na ploche: Omarchy, j5onrf/dots, fursman/Assistant (21. 10. 2026)

Preskúmané pre ROADMAP bod 16 (krok a). Čo z toho LatteOS berie a čo nie.

## Omarchy 4.0–4.5 (podrobne, 21. 10.)

Prvý zápis („sám AI nemá“) bol omyl: článok Phoronix o AI nepísal, ale Omarchy je postavené okolo AI agentov.
Zdroje: manuál `manual/sk/17-ai.md`, poznámky k vydaniam 4.0.0–4.5.0-rc1, skripty v `omacom/omarchy` (vetva quattro).

- **Agenti, nie chat.** 14 CLI kódovacích agentov (claude, codex, opencode, agy/Gemini, copilot, crush, grok, kimi, pi,
  omp, ori, hermes, muse, cursor-agent) je vopred pripravených ako lenivé spúšťače mise v `~/.local/bin` (stiahnu sa
  pri prvom použití). Predvolený agent v Setup › Defaults › Agent; Super+Shift+Ctrl+A ho otvorí v termináli;
  `omarchy agent prompt "…"` mu dá úlohu bez dozoru (v režime automatického schvaľovania, od 4.0.1 „auto-review“);
  skratky `a`, `c`, `cx`, `cy`; z domova sa začína v `~/Work`. Vlastné okno chatu nemajú — chat je cez desktopové
  aplikácie (ChatGPT, Claude desktop beta, Grok Bot, Perplexity, Hermes, OpenClaw) v Install › AI.
- **Panel agentov v lište:** každé predplatné s plánom, pásy limitov 5 h a týždňa s časom obnovenia (alebo zostatok
  kreditu), rotujúci riadok (tokeny za týždeň, najpoužívanejší model), „Make something“ (úvodné úlohy pre tému,
  plugin, aplikáciu). Zbiera `omarchy agent usage-update` každých 15 min (pri 80 %+ každé 3 min), zlučuje aj iné
  počítače cez synchronizovaný priečinok. **Limity bez otázky:** Claude z `https://api.anthropic.com/api/oauth/usage`
  s tokenom prihlásenia CLI (`~/.claude/.credentials.json`, hlavička `anthropic-beta: oauth-2025-04-20`, vlastná
  vyrovnávacia pamäť, endpoint rýchlo obmedzuje); Grok z `cli-chat-proxy.grok.com/v1/billing?format=credits` a z
  `grok usage`; tokeny z lokálnych prepisov rozhovorov. Pokryté: Claude, Codex, Grok, Fireworks, Kimi.
- **Viac predplatných** jedného poskytovateľa, prepínanie a automatické prepnutie pri 95 % limitu; kopírovanie
  prihlásení cez SSH.
- **Diagnostika pádov:** sleduje systemd-coredump; upozornenie „Process crashed“ → klik odovzdá pád predvolenému
  agentovi so skillom diagnose-crash (zistí fakty z core dumpu, rozhodne o nahlásení upstream); stlmenie po programoch.
- **Skill Omarchy** (`default/agents/skills/omarchy/SKILL.md`, experimentálny): pre úpravy používateľa (Hyprland,
  lišta, témy, hooky, snímky). Pravidlá: `/usr/share/omarchy` nikdy neupravovať (čítať áno), meniť iba `~/.config`;
  `sudo` v termináli, `pkexec`, keď terminál nie je; najprv plánovací režim; návrat `omarchy reinstall configs`.
  Prepojený symbolickými odkazmi do `~/.claude/skills`, `~/.codex/skills`, `~/.agents/skills`, Pi, Antigravity,
  Hermes. Druhý skill `omarchy-app` na stavbu aplikácií (C++, Qt Quick).
- **Lokálne modely:** LM Studio (odporúčané pre začiatočníkov) a Ollama z Install › AI.
- **Diktovanie** (4.5-rc1): Voxtype a Superwhisper, `omarchy dictation start|stop|toggle`.
- **Téma** sa prenáša do agentov (Claude Code, Pi, OpenCode, Hermes).

Omarchy je jeden proces Quickshellu s jednou témou a IPC ([Phoronix](https://www.phoronix.com/news/Omarchy-4.0-Released));
LatteOS to robí podobne (Goo je jedna scéna, `latte-say`, `pleamar --say`).

## j5onrf/dots — „mikro-agenti“

[github.com/j5onrf/dots](https://github.com/j5onrf/dots), `omarchy/ai/readme.md`. **Licencia nie je uvedená:** iba
inšpirácia, kód sa nepreberá.

- Lokálny model cez llama.cpp (`llama-cli` v termináli, `llama-server` s webovým rozhraním na porte 8080),
  súbory GGUF; veľký Qwen3.6-35B-A3B (MoE, 3B aktívnych) a malý Qwen3.5-2B na „rýchle jednoduché úlohy“.
- **Mikro-agent = pevná predvoľba modelu:** rýchly režim bez premýšľania (`--reasoning off`, teplota 0,7,
  kontext 8192), premýšľavý režim (rozpočet 2048), a krátky systémový pokyn „Concise and direct. No preamble.“
  Spúšťa sa jednou klávesou (F8) do terminálu.
- Do plochy zapojené slabo: terminál alebo prehliadač, žiadna schránka, snímky ani upozornenia.

**Pre LatteOS:** mikro-agenti áno, ale v LensGoo a v ponuke pravého tlačidla, nie v termináli: malé pevné úlohy
s vlastným pokynom, ktoré zvládne malý model v tomto počítači — zhrnúť schránku alebo označený text, preložiť,
vysvetliť chybu z terminálu, navrhnúť príkaz z vety (režim Príkaz), navrhnúť meno súboru. Každý agent = meno,
ikona, pokyn, odkiaľ berie vstup (schránka, súbor, snímka), kam dá výstup (karta, schránka). Bez nástrojov.

## fursman/Assistant — hlas (MIT)

[github.com/fursman/Assistant](https://github.com/fursman/Assistant). Hlasový asistent pre Hyprland, všetko okrem
modelu na procesore: Silero VAD (reč/ticho), **Moonshine** `medium_streaming` (prepis počas hovorenia, WER 7,8 %;
záloha faster-whisper `small`), smart-turn v3.2 (koniec vety, 8,7 MB), **Pocket TTS** (~100M, prvý zvuk ~0,17 s).
Model: lokálny Qwen (NVIDIA 16 GB), server v sieti, alebo Claude Code. Ťuknutie na Super = hlasový režim.
Ticho po dohovorení ~0,45 s. Python 3.11, ~1,5 GB venv, ~700 MB modely reči.

**Pre LatteOS:** mikrofón v poli LensGoo = prepis reči do poľa (nie hlasový rozhovor). Na latte-lab overiť
whisper.cpp alebo Moonshine na procesore i7-4820K (bez AVX2). Hlasové odpovede (TTS) až neskôr.

## Mikromodely na latte-lab (21. 10. v noci, krok b)

i7-4820K (AVX, **bez AVX2/FMA**), 16 GB RAM, RX 640 4 GB (Vulkan, RADV). llama.cpp b11752 (vydanie s Vulkanom)
v `/data/ai/llama`, modely v `/data/ai/models`. `llama-bench`, 4 vlákna, prompt 256 / generovanie 64 tokenov:

| model (Q4_K_M) | veľkosť | procesor: prompt · generovanie | karta: prompt · generovanie |
|---|---|---|---|
| Qwen3.5-2B | 1,2 GB | 132 · **15,0 t/s** | 97 · 8,5 t/s |
| Qwen3.5-4B | 2,6 GB | 54 · 5,4 t/s | 45 · 6,4 t/s |
| Edge0-8B-A1B (MoE, 1B aktívnych; návrh používateľa) | 4,5 GB | 82 · **21,1 t/s** | 77 · 9,7 t/s |

Na tejto karte (Polaris, bez fp16 a int dot) je procesor rýchlejší pre malé modely; karta má zmysel až pre 4B.

Skúška úloh (`llama-server`, pokyn „Concise and direct. No preamble.“, bez premýšľania):

- **Edge0:** rýchly, ale po slovensky zle a pokyn „odpovedz po anglicky“ nedodržal; príkaz `find` správny, no
  priečinok zamenil za `~/Downloads`; zhrnutie iba skopíroval. Ako mikro-agent zatiaľ nie.
- **Qwen3.5-2B:** slovenčina použiteľná (drobné chyby), angličtina dobrá, príkaz presne, zhrnutie áno; 2–5 s.
  **Predvolený lokálny model** pre mikro-agentov.
- **Qwen3.5-4B:** najlepšia slovenčina a zhrnutie; 5–15 s. Voľba „presnejší“.

## Prevod reči na text na latte-lab (krok h)

whisper.cpp v1.9.5 zostavený zo zdroja (`/data/ai/whisper-src`, Fedora má iba knižnicu bez programu). Skúška vetou
z espeak-ng (robotický hlas, ťažký aj pre človeka; skutočný hlas dopadne lepšie), 4 s:

| model | procesor | karta (Vulkan, zahriata) |
|---|---|---|
| base | 2,3 s, zle | 4,6 s |
| small | 8,1 s | **3,2 s** |
| large-v3-turbo q5 | 44,5 s | **8,0 s**, najlepšie |

Na karte je turbo použiteľné na diktovanie; LatteOS berie turbo s Vulkanom, inak small na procesore.
