# AI na ploche: Omarchy, j5onrf/dots, fursman/Assistant (21. 10. 2026)

Preskúmané pre ROADMAP bod 16 (krok a). Čo z toho LatteOS berie a čo nie.

## Omarchy 4.0

Sám AI nemá. Prestaval shell na jeden dlho bežiaci proces Quickshellu s jednou témou, ovládaný skriptami cez IPC
([Phoronix](https://www.phoronix.com/news/Omarchy-4.0-Released)). LatteOS to robí podobne (Goo je jedna scéna,
`latte-say`, `pleamar --say`), nie je čo meniť.

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
