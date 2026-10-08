# Vývojové AI prostredie (AI farma) — návrh

8. 10. 2026 · @Arkay + Claude · stav: **návrh**, nič z toho ešte nebeží

**Cieľ:** znížiť náklady na vývoj LatteOS. Týždenný limit predplatného Claude (reset **v pondelok o 15:00**) sa dnes
minie už vo štvrtok, teda približne za 3,5 dňa zo 7. Aby vydržal celý týždeň, treba spotrebu Clauda **zhruba
prepoliť**. Mechanickú prácu preto prevezme lokálny model, Claude ostane na myslenie, plán a kontrolu.

**Východisko (ako sa pracuje dnes):** na hlavnom PC beží VS Code s rozšírením Claude Code, napojený cez Remote-SSH
na latte-lab. Hlavné PC: Windows, 80 GB RAM, RTX 3060 12 GB, používa sa aj na inú prácu. latte-lab: samostatné PC
s vyvíjaným Linuxom, kábel priamo do hlavného PC (hlavné PC `192.168.137.1`, latte-lab `192.168.137.x`, pozri
[setup/lab/README.md](../setup/lab/README.md) §4).

---

## 1. Odpovede na hlavné otázky

**Kde beží Claude Code?** Na **latte-lab**. Pri Remote-SSH sa rozšírenie Claude Code spúšťa na vzdialenom PC, nie
na hlavnom. VS Code na hlavnom PC je iba okno (editor, panel Claude, terminál). Koordinátor tak priamo vidí repo,
kompiluje a skúša Goo na latte-lab.

**Kde beží aplikácia Farma?** V **dvoch častiach**, lebo grafická karta je na hlavnom PC a repo s pracovníkmi na
latte-lab (podrobne §4):

| časť | kde | čo robí |
|---|---|---|
| **Farma Strážca** | hlavné PC (Windows), ikona pri hodinách | sleduje vyťaženie RTX 3060 a programy, ktoré ju potrebujú (hry, strih). Má tlačidlo **▶ / ⏸**. Uvoľní model z LM Studia, keď GPU potrebuješ ty. Stav posiela farme. |
| **LM Studio server** | hlavné PC | počíta model; nahrá ho až pri úlohe |
| **Farma** (služba) | latte-lab | front úloh, spúšťa a pozastavuje pracovníkov, ukladá ich priebeh. Má **webový panel**: úlohy, živý náhľad, čo agent práve robí, diff, tlačidlá Prevziať / Zahodiť / Vrátiť. |
| **Koordinátor** | latte-lab (VS Code + Claude Code) | píše zadania do frontu, kontroluje diffy |

Panel Farmy sa otvorí v prehliadači na hlavnom PC alebo **priamo vo VS Code**. Remote-SSH prepošle port z latte-lab
sám, takže stačí `http://localhost:8781`. Neskôr môže byť panel aj kvapkou v Goo na latte-lab.

**Kde sa zadávajú úlohy?** Stále **v paneli Claude Code vo VS Code**, ako doteraz. Koordinátor (Claude) sám
rozhodne, čo urobí sám a čo pošle farme. Mechanickú časť napíše ako zadanie a pridá do frontu (`farma pridaj
zadanie.md`). Farma ho spustí, **až keď je GPU voľné a farma beží (▶)**. Ty môžeš úlohu pridať aj sám v paneli Farmy.
Podagenti v Claude Code (`.claude/agents`) vedia používať iba modely Claude, preto lokálny model volá Farma ako
samostatný proces.

```
 HLAVNÉ PC (Windows)                                  LATTE-LAB (Linux)
 ┌──────────────────────────────────┐  Remote-SSH     ┌───────────────────────────────────────────┐
 │ VS Code — iba okno               │═══════════════▶ │ Claude Code = KOORDINÁTOR (predplatné)    │
 │   + panel Farmy (localhost:8781) │                 │      │ farma pridaj <zadanie>             │
 │                                  │                 │      ▼                                    │
 │ Farma Strážca  [▶/⏸] ● GPU voľné │ ── stav ──────▶ │ Farma (služba, :8781)                     │
 │   NVML: vyťaženie, VRAM, procesy │ ◀─ ▶/⏸, stav ── │   front · pracovníci · záznam · diffy     │
 │   lms unload pri hre             │                 │      │ spustí, keď GPU voľné a ▶          │
 │                                  │                 │      ▼                                    │
 │ LM Studio server :1234  ◀────────┼──── HTTP ─────── │ pracovník = Claude Code + lokálny model   │
 │  RTX 3060 12 GB + 80 GB RAM      │                 │   v ~farma/wt-<úloha>, vetva farma/<úloha>│
 └──────────────────────────────────┘                 └───────────────────────────────────────────┘
```

Prečo pracovník = Claude Code: LM Studio od verzie 0.4.1 hovorí formátom Anthropic (`/v1/messages`). Pracovník je
preto **ten istý Claude Code** s tými istými nástrojmi (čítanie, úpravy, bash), iba s inou adresou modelu, a **limit
predplatného nemíňa**.

---

## 2. Kde sa dnes míňa limit (odhad)

| zdroj spotreby | prečo je drahý | náprava (§6) |
|---|---|---|
| Opus ako predvolený model na všetko | Opus míňa limit najrýchlejšie | Sonnet ako predvolený, Opus iba na plán a ťažké chyby |
| veľké dokumenty v kontexte | `ROADMAP.md` má 90 kB (~25–30 tis. tokenov), `LATTEOS-GOO.md` 34 kB (~10 tis.). Ak sa čítajú celé, platia sa pri každej ďalšej správe | čítať iba potrebnú sekciu (grep) |
| dlhé rozhovory bez `/clear` | každá správa nesie celú doterajšiu históriu | jedna úloha = jeden rozhovor |
| mechanické úlohy robené Claudom | preklady `tr()`, ikony, dokumentácia, opakované úpravy, čítanie logov | farma (§4) |

---

## 3. Model pre LM Studio (RTX 3060 12 GB + 80 GB RAM)

Vďaka 80 GB RAM sa dajú použiť **modely MoE**. Majú veľa parametrov, ale pri každom slove pracuje iba malá časť
(„experti“). Experti sa držia v RAM, zvyšok na grafickej karte, a model ostáva použiteľne rýchly. Pre agenta je
dôležité **spoľahlivé volanie nástrojov a kontext aspoň 32 tis. tokenov**. Zdroje sa nezhodujú, preto treba
vyskúšať dva až tri modely na vlastnej úlohe (§8, krok 3).

| poradie | model | kvantizácia | pamäť (VRAM + RAM) | poznámka |
|---|---|---|---|---|
| **1** | **Qwen3-Coder-30B-A3B-Instruct** (aktívne ~3B) | Q4_K_M až Q6_K | ~18–25 GB | ladený priamo na agentové programovanie. **Hlavný kandidát.** |
| **2** | **Gemma 4 26B A4B** (aktívne ~4B) | Q4–Q6 | ~17–22 GB | natívne volanie nástrojov, kontext až 256 tis. **Vypnúť „Enable Thinking“.** |
| **3** | **gpt-oss-20b** | MXFP4 | ~13 GB | LM Studio ho uvádza v návode pre Claude Code. Najistejší **prvý test spojenia**. |
| noc | **gpt-oss-120b** (aktívne ~5B) | MXFP4 | ~65 GB | najsilnejší, čo sa zmestí, ale zaberie takmer celú RAM. Iba **na noc alebo keď hlavné PC nič iné nerobí**. |
| záloha | **Qwen2.5-Coder-14B-Instruct** | Q4_K_M | ~9 GB, celý vo VRAM | rýchly a overený, ale slabší agent. Na krátke otázky cez `latte-ai`. |

Nastavenia v LM Studiu:

- **Context Length:** 65 536 (minimum 32 768). **Flash Attention:** zapnuté. **KV cache:** Q8.
- **GPU Offload:** všetky vrstvy. Pri MoE zapnúť **presun váh expertov do RAM** (*offload experts to CPU*).
- **Server:** *Serve on Local Network* zapnuté a ***Require Authentication*** zapnuté (token).
- **Developer → Server:** spúšťať pri štarte Windows ako službu (headless `llmster`/`lms server start`), **JIT
  loading** zapnuté, **Auto-unload** po ~15 min nečinnosti, aby GPU a RAM nebrali miesto inej práci.
- **Windows firewall:** port 1234 povoliť iba pre sieťovku s latte-lab (`192.168.137.0/24`), nie do domácej siete.

**Hlavné PC slúži aj na inú prácu.** Počas úlohy farmy je grafická karta vyťažená (hry a strih videa sa spomalia).
Úlohy farmy sa dajú nechať na čas, keď PC nepotrebuješ. Model sa sám uvoľní po nečinnosti.

**Čo dávať farme:** preklady (`translations sk`, `tr()`), dokumentácia a `ZMENY.md`, opakované úpravy podľa
presného vzoru, návrhy testov, zhrnutie logov (Hyprland, engine Goo), skripty v `setup/`, prvé hľadanie príčiny chyby.

**Čo jej nedávať:** architektúra enginu Goo (Rust, SDF, pleamar), ťažké chyby v Luau logike kvapiek, rozhodnutia
do `ROZHODNUTIA.md`, čokoľvek, čo ide na GitHub.

---

## 4. Aplikácia Farma

### 4.1 Farma Strážca (hlavné PC, Windows)

Malý program pri hodinách (Python + `pynvml` + `pystray`; neskôr ho možno prepísať v Tauri, ak bude treba).

**Ikona a ponuka:** ● zelená = farma pracuje · ● žltá = čaká na voľné GPU · ● sivá = pauza. Položky:
**▶ Spustiť / ⏸ Pauza**, *Pauza na 1 h / do rána*, *Otvoriť panel*, *Uvoľniť model teraz*.

**Kedy je GPU „obsadené“** (stačí jedna podmienka):

- beží program zo zoznamu „GPU potrebujem ja“ (napr. `steam`, hry, `obs64`, `Resolve`, `Premiere`) — zoznam sa
  upravuje v nastaveniach;
- farma práve nepočíta a GPU je napriek tomu vyťažené nad ~25 % dlhšie ako 20 s (teda ho používa niečo iné);
- iné programy zaberajú toľko VRAM, že model sa nezmestí.

**Kedy je „voľné“:** nič z toho neplatí aspoň **3 minúty** (aby farma neskákala pri krátkych výkyvoch).

**Čo urobí pri zmene:**

| udalosť | Strážca | Farma na latte-lab |
|---|---|---|
| GPU obsadené / ⏸ | po dokončení rozpísanej odpovede `lms unload --all` (uvoľní VRAM aj RAM) | nové úlohy nespúšťa, bežiacich pracovníkov **zmrazí** (`SIGSTOP`) |
| GPU voľné a ▶ | nič (model sa nahrá sám pri prvej požiadavke) | pracovníkov **rozmrazí** (`SIGCONT`) a pokračuje vo fronte |
| pauza dlhšia ako ~1 h | — | zmrazeného pracovníka ukončí a neskôr ho obnoví (`claude --resume`) v tej istej kópii repa |

Strážca posiela stav farme každých pár sekúnd (`POST http://latte-lab:8781/api/gpu`, s tokenom). Ak Strážca nebeží
(PC vypnuté), farma to berie ako „obsadené“.

### 4.2 Farma (latte-lab, služba `systemd --user`)

Jeden program (Python, ~500–800 riadkov; webový panel v jednom HTML súbore), beží ako používateľ `farma`.

- **Front úloh:** `~farma/ulohy/{cakajuce,bezi,hotove,vratene}/<id>.md`. Pridať sa dá z príkazového riadka
  (`farma pridaj`), z panela alebo neskôr nástrojom MCP.
- **Pracovník:** pre každú úlohu `git worktree` a vetva `farma/<id>`. Spustí sa
  `claude -p --output-format stream-json` s adresou LM Studia. Súčasne beží **jeden, najviac dvaja**, lebo
  grafická karta je iba jedna.
- **Záznam:** z prúdu udalostí Claude Code sa ukladá, čo pracovník robí (číta súbor X, upravuje Y, spúšťa
  `cargo build`, jeho text). Panel to ukazuje naživo.
- **Koniec úlohy:** spustí kontrolu z „Hotovo, keď“, urobí commit a zapíše zhrnutie a štatistiku (čas, tokeny,
  zmenené súbory).

**Webový panel** (`:8781`):

```
┌ Farma ──────────────────────────── GPU: ● voľné (3 %)  Model: qwen3-coder-30b  [⏸ Pauza] ┐
│ Čakajúce (3)        │ Beží: preklad-tvorca-goo  (4 min, 2 140 tok)                       │
│  · ikony-lensgoo    │  12:01 číta session/goo/tvorca.luau                                │
│  · zmeny-okt        │  12:02 upravuje session/goo/translations/sk …                      │
│  · test-hodiny      │  12:04 spúšťa: cargo build -p goo   ✓                              │
│ Hotové (2)          │  ─────────────────────────────────────────────                     │
│  ✓ logy-hyprland    │  [Diff]  [Prevziať do vetvy]  [Vrátiť s poznámkou]  [Zahodiť]       │
└─────────────────────┴────────────────────────────────────────────────────────────────────┘
```

**Prevziať** = merge `farma/<id>` do tvojej pracovnej vetvy v hlavnej kópii (`~arkay/jihlavanka001`). Merge
a push na GitHub robíš ty alebo koordinátor, nie farma.

### 4.3 Koordinátor a farma

- Pravidlo v `CLAUDE.md`: mechanické úlohy (§3) Claude nerobí sám, ale napíše zadanie a dá `farma pridaj`.
- Šablóna zadania (aby mu malý model rozumel):

```markdown
# Úloha: preklad textov Tvorcu Goo do sk
Súbory: session/goo/… (presné cesty)
Urob: …
Nerob: nemeň logiku, nemeň iné súbory, nič nepushuj
Hotovo, keď: `cargo build` prejde / súbor X obsahuje …
```

- Kontrola: koordinátor (Sonnet) číta iba `git diff main..farma/<id>`. Malý diff je lacný.
- Neskôr: nástroj MCP `farma_pridaj / farma_stav / farma_vysledok`, ktorý môže byť súčasťou plánovaného `latte-mcp`.

### 4.4 Inštalácia (jednorazovo)

```bash
# latte-lab
sudo useradd -m -s /bin/bash farma              # bez sudo, nevidí ~/.claude-local ani kľúče GitHub
sudo -u farma git clone ~arkay/jihlavanka001 ~farma/repo
sudo -u farma bash -c 'curl -fsSL https://claude.ai/install.sh | bash'
# ~farma/.config/farma.env: ANTHROPIC_BASE_URL=http://192.168.137.1:1234, ANTHROPIC_AUTH_TOKEN=<token LM Studia>,
#   CLAUDE_CODE_ATTRIBUTION_HEADER=0, FARMA_MODEL=<názov z `lms ls`>, FARMA_TOKEN=<token pre Strážcu>
```

Na hlavnom PC: LM Studio podľa §3 a Strážca (Python + `pip install pynvml pystray`, spúšťaný pri prihlásení).

### 4.5 Čo naprogramovať (poradie)

| krok | súbor | výsledok |
|---|---|---|
| 1 | `setup/lab/farma/farma.py` — front + pracovník + záznam (bez panela) | úlohy idú cez príkazový riadok |
| 2 | `setup/lab/farma/panel.html` + API | náhľad, ▶/⏸, diff, prevziať |
| 3 | `setup/lab/farma/strazca.py` (Windows) | GPU stráženie, uvoľnenie modelu |
| 4 | `setup/lab/farma/instaluj.sh`, služba systemd | farma beží sama aj po reštarte |
| 5 | pravidlo v `CLAUDE.md`, neskôr MCP | koordinátor posiela úlohy sám |

### 4.6 Inšpirácie na GitHube (preberať, nevymýšľať)

Tvoju staršiu inšpiráciu „AI farma“ som v repách `jihlavanka001` ani `latteos` (ani v ich histórii) nenašiel. Ak si
ju dával niekam inam, stačí poslať odkaz. Podobné hotové projekty (8. 10. 2026):

| projekt | čo z neho vziať | prečo nie celý |
|---|---|---|
| [Dicklesworthstone/claude_code_agent_farm](https://github.com/Dicklesworthstone/claude_code_agent_farm) (~900 ★) | sledovanie agentov, automatický `/clear`, obnova zaseknutého agenta, správa o behu | cieli na 20+ agentov s predplatným Claude v tmux, nepozná GPU ani lokálny model |
| [matank001/clodfarm](https://github.com/matank001/clodfarm) | **pauza pri 80 % týždenného limitu Claude**, ovládanie z aplikácie Claude v mobile | ťažký (kontajner, AWS, platby), cieľ je iný |
| [vraj00222/agent-farm](https://github.com/vraj00222/agent-farm) | presne náš postup: worktree na úlohu, živý výstup, diff, prevziať/zahodiť, `--resume` | iba macOS (Electron) |
| [getpaseo/paseo](https://github.com/getpaseo/paseo) (~20 tis. ★) | démon + klienti (Windows, Linux, web, mobil), worktree, diffy, **pluginy** (vedia meniť prostredie agenta) | veľký nástroj popri VS Code; GPU stráženie by bol vlastný plugin. **Alternatíva** ku krokom 2–4, ak by vlastný panel rástol |

Nikto z nich nerobí to hlavné: **spúšťať lokálny model iba vtedy, keď GPU nepotrebuješ ty**. To je vlastná časť
(Strážca). Front a panel sú malé, preto navrhujem vlastnú jednoduchú Farmu. Paseo ber ako zálohu, ak by sme
potrebovali viac (mobil, viac strojov).

---

## 5. Bezpečnosť

- Pracovník = používateľ `farma`: bez sudo, bez hesla, bez kľúčov GitHub. Vidí iba svoj klon repa.
- Na GitHub pushuje **iba koordinátor a iba na tvoj pokyn** (pravidlo z CLAUDE.md).
- LM Studio: token a firewall iba pre kábel k latte-lab.
- Pracovník nedostáva zadania z internetu ani z cudzích súborov. Píše ich iba koordinátor alebo ty.

---

## 6. Pravidlá šetrenia predplatného (platia hneď, nič sa neinštaluje)

1. **Predvolený model Sonnet 5.5.** `/model` → Sonnet. Alebo `opusplan`: Opus iba v režime plánovania, potom
   automaticky Sonnet.
2. **Opus 5.5 iba na:** návrh architektúry, ťažké chyby (engine Goo, Hyprland), rozhodnutia, záverečnú kontrolu
   veľkej zmeny.
3. **Haiku 5.5 na prieskum.** Podagenti na hľadanie v kóde a čítanie logov s `model: haiku` v `.claude/agents/*.md`.
4. **Jedna úloha = jeden rozhovor.** Po dokončení `/clear`. Pri dlhej úlohe `/compact` s pokynom, čo si zapamätať.
5. **Nečítať celé veľké dokumenty.** Návrh na úpravu `CLAUDE.md`: „ROADMAP.md nečítať celý — iba sekciu, na ktorej
   sa pracuje (grep podľa F-kódu/nadpisu)“. `ROZHODNUTIA.md` čítať iba posledné záznamy.
6. **Nižšia úroveň uvažovania (effort) pri bežnej práci,** vysoká iba pri ťažkom probléme.
7. **Mechanické úlohy na farmu.** Pravidlo palca: ak sa dá zadanie napísať do 10 riadkov s presným „Hotovo, keď“,
   ide na farmu.
8. **Sledovať spotrebu:** `/usage` v Claude Code. Rozpočet je ~14 % týždňa na deň. Ak je v stredu nad 50 %, zvyšok
   týždňa iba Sonnet a farma.

**Bezplatné účty u iných firiem** (máš iba bezplatné) sú iba doplnok:

- Gemini CLI s osobným účtom Google podľa viacerých zdrojov **od 18. 6. 2026 prestal fungovať** (prechod na
  Antigravity CLI s oveľa menšou bezplatnou kvótou). Pred použitím overiť.
- Codex (bezplatný ChatGPT) a Copilot Free majú malé limity.
- Využitie: **druhý názor** na ťažkú chybu, keď je Claude vyčerpaný. `latte-ai` ich vie volať cez `predplatne`.

---

## 7. Očakávaný efekt (hrubý odhad, overiť po 2 týždňoch)

| zmena | úspora limitu |
|---|---|
| Sonnet namiesto Opus na bežnú prácu | veľká |
| `/clear` a čítanie iba sekcií dokumentov | stredná až veľká |
| mechanické úlohy na farmu | stredná (podľa toho, koľko sa ich nájde) |
| Haiku na prieskum | malá až stredná |

Cieľ: limit vydrží **do pondelka 15:00**. V pondelok pred resetom zapísať, kedy sa limit minul.

| týždeň | limit minutý v | poznámka |
|---|---|---|
| 5. 10. – 12. 10. | štvrtok | pred farmou |

---

## 8. Postup — prvý deň pri hlavnom PC

1. **Hneď (bez inštalácie):** v Claude Code prepnúť `/model` na Sonnet (alebo `opusplan`) a začať dodržiavať §6.
2. **LM Studio na hlavnom PC:** aktualizovať na ≥ 0.4.1 a stiahnuť `gpt-oss-20b` a `Qwen3-Coder-30B-A3B-Instruct`.
   Nastaviť server podľa §3 (sieť, token, JIT, auto-unload) a firewall iba pre `192.168.137.0/24`.
3. **Test z latte-lab** (terminál vo VS Code): `curl http://192.168.137.1:1234/v1/models -H "Authorization: Bearer
   <token>"` a potom ručne jeden beh Claude Code s premennými z §4.4 na skúšobnú úlohu. Overiť, že model volá
   nástroje. To isté s druhým modelom; zapísať rýchlosť (tokeny/s) a či úlohu dotiahol.
4. **Povedať Claudovi vo VS Code:** „Podľa `inspo/dev-ai-prostredie.md` §4.5 urob krok 1 a 4.“ Najprv farma iba
   z príkazového riadka, potom panel (krok 2) a Strážca (krok 3).
5. **Prvá skutočná úloha cez farmu** (napr. preklad textov jednej karty Goo), kontrola diffu, prevzatie.
6. Výsledok a voľbu modelu zapísať do `docs/goo/ROZHODNUTIA.md`, Farmu ako úlohu do `ROADMAP.md`.

## 9. Otvorené otázky

- Zoznam programov „GPU potrebujem ja“ (hry, strih, OBS…)?
- Má farma bežať aj cez noc? Hlavné PC by muselo ostať zapnuté (Strážca to vie ukázať a v ponuke „do rána“ zapnúť).
- Pridať do panela aj stav týždenného limitu Claude (podľa clodfarm) a pauzu koordinátora pri ~80 %?

## Zdroje

- LM Studio + Claude Code (rozhranie `/v1/messages` od 0.4.1): <https://lmstudio.ai/blog/claudecode>,
  <https://www.lmstudio.ai/docs/integrations/claude-code>
- Modely: <https://blog.kilo.ai/p/the-best-local-coding-models-for>,
  <https://atomic.chat/blog/guides/best-local-llms-for-coding>, <https://localaimaster.com/vram/best-coding-llm-12gb-vram>,
  <https://www.layer3labs.io/guides/best-local-llm-for-coding>, <https://lmstudio.ai/harshit2004/gemma-4-26b-a4b>,
  <https://aiproductivity.ai/news/gemma-4-26b-local-coding-no-gpu/>
- Gemini CLI zadarmo: <https://www.tembo.io/blog/gemini-cli-pricing>,
  <https://developers.google.cn/gemini-code-assist/resources/faqs?hl=en>, <https://geminicli.com/docs/quota-and-pricing>
- Podobné projekty: <https://github.com/Dicklesworthstone/claude_code_agent_farm>,
  <https://github.com/matank001/clodfarm>, <https://github.com/vraj00222/agent-farm>, <https://github.com/getpaseo/paseo>
