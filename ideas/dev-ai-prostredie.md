# Vývojové AI prostredie (AI farma) — návrh

8. 10. 2026 · @Arkay + Claude · stav: **návrh**, nič z toho ešte nebeží

**Cieľ:** znížiť náklady na vývoj LatteOS. Týždenný limit predplatného Claude (reset **v pondelok o 15:00**) sa dnes
minie už vo štvrtok, teda približne za 3,5 dňa zo 7. Aby vydržal celý týždeň, treba spotrebu Clauda **zhruba
prepoliť**. Mechanickú prácu preto prevezme lokálny model, Claude ostane na myslenie, plán a kontrolu.

---

## 1. Kde sa dnes míňa limit (odhad)

| zdroj spotreby | prečo je drahý | náprava (§5) |
|---|---|---|
| Opus ako predvolený model na všetko | Opus míňa limit najrýchlejšie | Sonnet ako predvolený, Opus iba na plán a ťažké chyby |
| veľké dokumenty v kontexte | `ROADMAP.md` má 90 kB (~25–30 tis. tokenov), `LATTEOS-GOO.md` 34 kB (~10 tis.). Ak sa čítajú celé, platia sa pri každej ďalšej správe | čítať iba potrebnú sekciu (grep) |
| dlhé rozhovory bez `/clear` | každá správa nesie celú doterajšiu históriu | jedna úloha = jeden rozhovor |
| mechanické úlohy robené Claudom | preklady `tr()`, ikony, dokumentácia, opakované úpravy, čítanie logov | lokálny model (§3) |

Najväčší efekt čakám od prvých troch riadkov. Stoja iba zmenu návykov, nič sa neinštaluje.

---

## 2. Rozloženie

```
 HLAVNÉ PC (Windows/Linux, RTX 3060 12 GB)            LATTE-LAB (i7-4820K, 16 GB, RX 550)
 ┌───────────────────────────────────────┐            ┌──────────────────────────────────────┐
 │ VS Code + Claude Code (predplatné)    │──SSH──────▶│ repo ~/jihlavanka001 (hlavná kópia)  │
 │   = KOORDINÁTOR: plán, kontrola, merge │            │                                      │
 │                                       │            │ používateľ `farma` (bez sudo)        │
 │ LM Studio server :1234                │◀──LAN──────│   ~/farma/wt-<úloha>  (git worktree) │
 │   /v1/messages  (Anthropic formát)    │            │   claude-lokal  = Claude Code +      │
 │   /v1/chat/completions (OpenAI)       │            │                   model z LM Studia  │
 └───────────────────────────────────────┘            │   ~/farma/ulohy/*.md (front úloh)    │
                                                      └──────────────────────────────────────┘
```

- **latte-lab nepočíta modely** (RX 550 a 16 GB na to nestačia). Je to dielňa: kópie repa, kompilácia, testy
  a skúšanie Goo na skutočnej ploche.
- **Model beží na hlavnom PC** v LM Studiu a latte-lab ho volá cez sieť.
- **Pracovník = Claude Code napojený na lokálny model.** LM Studio od verzie 0.4.1 má rozhranie vo formáte Anthropic
  (`/v1/messages`), takže na lokálnom modeli beží ten istý Claude Code s tými istými nástrojmi, ktoré poznáš. Žiadny
  nový program sa netreba učiť a **limit predplatného to vôbec nemíňa**.

---

## 3. Model pre LM Studio (RTX 3060 12 GB)

Pre agenta (Claude Code číta súbory, volá nástroje) je dôležitejšie **spoľahlivé volanie nástrojov a dlhý kontext**
(aspoň 32 tis. tokenov) než najvyššie skóre v testoch. Zdroje sa nezhodujú, preto treba vyskúšať **dva až tri
modely** na vlastnej úlohe (§7, krok 3).

| poradie | model | kvantizácia | čo čakať na 12 GB |
|---|---|---|---|
| **1** | **Qwen3-Coder-30B-A3B-Instruct** (MoE, aktívne ~3B) | Q4_K_M | sa do VRAM nezmestí celý. V LM Studiu zapnúť presun expertov MoE do RAM (*offload experts to CPU*). Vďaka malému počtu aktívnych parametrov ostáva rýchly. Ladený priamo na agentové programovanie. **Potrebuje ≥ 32 GB RAM na hlavnom PC.** |
| **2** | **Gemma 4 26B A4B** (MoE, aktívne ~4B) | Q4 | rovnaký postup s presunom expertov (minimum ~17 GB pamäte spolu). Natívne volanie nástrojov, kontext až 256 tis. **Vypnúť „Enable Thinking“** — pri agentovi iba spomaľuje. |
| **3** | **gpt-oss-20b** | MXFP4 (pôvodná) | tesne na hrane 12 GB, časť vrstiev pôjde do RAM. LM Studio ho uvádza priamo v návode pre Claude Code, preto je to najistejší prvý test, že spojenie funguje. |
| záloha | **Qwen2.5-Coder-14B-Instruct** | Q4_K_M (~9 GB) | zmestí sa celý do VRAM, je rýchly a overený. Je však starší a slabší ako agent. Dobrý na krátke úlohy cez Text Bar a `latte-ai`. |

Nastavenia v LM Studiu:

- **Context Length:** 32 768 (ak pamäť dovolí, tak 65 536). Claude Code potrebuje aspoň ~25 tis.
- **Flash Attention:** zapnuté. **KV cache:** Q8, ušetrí VRAM pri dlhom kontexte.
- **GPU Offload:** maximum, ktoré sa zmestí. Pri modeloch MoE zapnúť presun expertov do RAM.
- **Server:** *Serve on Local Network* zapnúť a *Require Authentication* zapnúť (token, lebo server je v sieti).
- **JIT loading / Auto-unload:** zapnúť, aby sa model nahral sám, keď ho farma zavolá.

**Čo lokálnemu modelu dávať:** preklady (`translations sk`, `tr()`), dokumentácia a `ZMENY.md`, opakované úpravy
v mnohých súboroch podľa presného vzoru, návrhy testov, čítanie a zhrnutie logov (Hyprland, engine Goo), skripty
v `setup/`, generovanie ikon a tabuliek, prvé hľadanie príčiny chyby.

**Čo mu nedávať:** architektúra enginu Goo (Rust, SDF, pleamar), ťažké chyby v Luau logike kvapiek, rozhodnutia do
`ROZHODNUTIA.md`, čokoľvek, čo ide na GitHub.

---

## 4. Farma na latte-lab

### 4.1 Prvé nastavenie (jednorazovo)

```bash
# na latte-lab, pod používateľom arkay
sudo useradd -m -s /bin/bash farma           # bez sudo, nevidí ~/.claude-local ani heslá
sudo -u farma git clone ~arkay/jihlavanka001 ~farma/repo    # miestny klon; push na GitHub farma nemá
sudo -u farma npm install -g @anthropic-ai/claude-code      # alebo natívny inštalátor Claude Code
```

`~farma/.bashrc`:

```bash
export LMSTUDIO=http://HLAVNE-PC:1234        # IP hlavného PC
alias claude-lokal='ANTHROPIC_BASE_URL=$LMSTUDIO \
  ANTHROPIC_AUTH_TOKEN=<token z LM Studia> \
  CLAUDE_CODE_ATTRIBUTION_HEADER=0 \
  claude --model qwen3-coder-30b-a3b-instruct'   # presný názov podľa `lms ls`
```

Test spojenia: `curl $LMSTUDIO/v1/models -H "Authorization: Bearer <token>"`.

### 4.2 Front úloh (jednoduchý, v súboroch)

```
~farma/ulohy/
  cakajuce/  2026-10-09-preklad-tvorca-goo.md   ← zadanie píše koordinátor (Claude/ty)
  bezi/
  hotove/    … + vetva farma/<úloha> v ~farma/repo
```

Zadanie má vždy tie isté časti, aby mu malý model rozumel:

```markdown
# Úloha: preklad textov Tvorcu Goo do sk
Súbory: session/goo/… (presné cesty)
Urob: …
Nerob: nemeň logiku, nemeň iné súbory
Hotovo, keď: `cargo build` prejde / súbor X obsahuje …
```

Spustenie jednej úlohy (neskôr skript `setup/lab/farma-uloha.sh`):

```bash
cd ~farma/repo && git worktree add ../wt-$U -b farma/$U main
cd ../wt-$U && claude-lokal -p "$(cat ~/ulohy/bezi/$U.md)" --permission-mode acceptEdits
git add -A && git commit -m "farma: $U"
```

### 4.3 Kontrola a prevzatie

1. Koordinátor (Claude Code na hlavnom PC, model **Sonnet**) si prečíta iba `git diff main..farma/<úloha>`. Malý diff
   je lacný, oveľa lacnejší, ako keby úlohu robil sám.
2. Ak je diff dobrý: `git merge farma/<úloha>` do pracovnej vetvy v hlavnej kópii. Ak nie: krátka poznámka do
   zadania a úloha ide naspäť do `cakajuce/`.
3. Na GitHub pushuje **iba koordinátor a iba na tvoj pokyn** (pravidlo z CLAUDE.md).

### 4.4 Neskôr (ak sa farma osvedčí)

- Skript `farma-uloha.sh` s frontom a viacerými úlohami za sebou (cez noc, keď hlavné PC aj tak beží).
- Nástroj MCP v pláne `latte-mcp`: „zadaj úlohu farme“ a „stav farmy“, aby to Claude Code robil sám bez kopírovania.
- Pracovník v kontajneri podman namiesto samostatného používateľa.

---

## 5. Pravidlá šetrenia predplatného (platia hneď, nič sa neinštaluje)

1. **Predvolený model Sonnet 5.5.** `/model` → Sonnet. Alebo `opusplan`: Opus iba v režime plánovania, potom
   automaticky Sonnet.
2. **Opus 5.5 iba na:** návrh architektúry, ťažké chyby (engine Goo, Hyprland), rozhodnutia, záverečnú kontrolu
   veľkej zmeny.
3. **Haiku 5.5 na prieskum.** Podagenti na hľadanie v kóde a čítanie logov s `model: haiku` v `.claude/agents/*.md`.
4. **Jedna úloha = jeden rozhovor.** Po dokončení `/clear`. Pri dlhej úlohe `/compact` s pokynom, čo si zapamätať.
5. **Nečítať celé veľké dokumenty.** Návrh na úpravu `CLAUDE.md`: „ROADMAP.md nečítať celý — iba sekciu, na ktorej
   sa pracuje (grep podľa F-kódu/nadpisu)“. Rovnako `ROZHODNUTIA.md` čítať iba posledné záznamy.
6. **Nižšia úroveň uvažovania (effort) pri bežnej práci,** vysoká iba pri ťažkom probléme.
7. **Mechanické úlohy na farmu** (§3). Pravidlo palca: ak sa dá zadanie napísať do 10 riadkov s presným „hotovo,
   keď“, ide na farmu.
8. **Sledovať spotrebu:** `/usage` v Claude Code. Rozpočet je ~14 % týždňa na deň. Ak je v stredu nad 50 %, zvyšok
   týždňa iba Sonnet a farma.

**Bezplatné účty u iných firiem** sú iba doplnok, nie základ:

- Gemini CLI s osobným účtom Google podľa viacerých zdrojov **od 18. 6. 2026 prestal fungovať** (prechod na
  Antigravity CLI s oveľa menšou bezplatnou kvótou). Pred použitím overiť aktuálny stav.
- Codex (bezplatný ChatGPT) a Copilot Free majú malé limity.
- Využitie: **druhý názor** na ťažkú chybu alebo kontrola diffu, keď je Claude vyčerpaný. `latte-ai` ich už vie volať
  cez `predplatne`.

---

## 6. Očakávaný efekt (hrubý odhad, overiť po 2 týždňoch)

| zmena | úspora limitu |
|---|---|
| Sonnet namiesto Opus na bežnú prácu | veľká |
| `/clear` a čítanie iba sekcií dokumentov | stredná až veľká |
| mechanické úlohy na farmu | stredná (podľa toho, koľko sa ich nájde) |
| Haiku na prieskum | malá až stredná |

Cieľ: limit vydrží **do pondelka 15:00**. Merať: v pondelok pred resetom zapísať percento spotreby z `/usage`
do tabuľky nižšie.

| týždeň | minuté v deň | poznámka |
|---|---|---|
| 5. 10. – 12. 10. | štvrtok | pred farmou |

---

## 7. Prvý deň pri hlavnom PC — postup

1. **LM Studio:** aktualizovať na ≥ 0.4.1 a stiahnuť `gpt-oss-20b` a `Qwen3-Coder-30B-A3B-Instruct` (Q4_K_M).
   Nastaviť server podľa §3 a v hlavnom PC povoliť port 1234 vo firewalle iba pre miestnu sieť.
2. **Test na hlavnom PC:** v termináli VS Code pustiť `claude-lokal` (premenné z §4.1, adresa `http://localhost:1234`)
   a zadať jednoduchú úlohu. Overiť, že model volá nástroje (číta a upravuje súbory).
3. **Porovnanie modelov:** jedna skutočná úloha, napr. preklad textov jednej karty Goo, postupne na 2–3 modeloch.
   Zapísať rýchlosť (tokeny/s v LM Studiu) a či to dotiahol bez pomoci.
4. **latte-lab:** používateľ `farma`, Claude Code, alias, test cez `curl` (§4.1).
5. **Prvá úloha cez farmu** podľa §4.2 a kontrola diffu Sonnetom podľa §4.3.
6. **Pravidlá §5:** prepnúť predvolený model na Sonnet, upraviť `CLAUDE.md` (čítanie po sekciách) a pridať podagenta
   Haiku. Výsledok zapísať do `docs/goo/ROZHODNUTIA.md`.

## 8. Otvorené otázky

- Koľko RAM má hlavné PC? Od toho závisí voľba modelu MoE (Qwen3-Coder/Gemma 4 potrebujú ≥ 32 GB spolu).
- Aký systém je na hlavnom PC (Windows/Linux)? Mení to iba firewall a cesty, postup ostáva.
- Má farma bežať aj cez noc? Hlavné PC by muselo ostať zapnuté s nahratým modelom.

## Zdroje

- LM Studio + Claude Code (rozhranie `/v1/messages` od 0.4.1): <https://lmstudio.ai/blog/claudecode>,
  <https://www.lmstudio.ai/docs/integrations/claude-code>
- Modely na 12 GB: <https://blog.kilo.ai/p/the-best-local-coding-models-for>,
  <https://atomic.chat/blog/guides/best-local-llms-for-coding>, <https://localaimaster.com/vram/best-coding-llm-12gb-vram>,
  <https://www.layer3labs.io/guides/best-local-llm-for-coding>, <https://lmstudio.ai/harshit2004/gemma-4-26b-a4b>,
  <https://aiproductivity.ai/news/gemma-4-26b-local-coding-no-gpu/>
- Gemini CLI zadarmo: <https://www.tembo.io/blog/gemini-cli-pricing>,
  <https://developers.google.cn/gemini-code-assist/resources/faqs?hl=en>, <https://geminicli.com/docs/quota-and-pricing>
