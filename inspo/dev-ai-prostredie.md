# Vývojové AI prostredie (AI farma) — návrh

8. 10. 2026 · @Arkay + Claude · stav: **návrh**, nič z toho ešte nebeží

**Cieľ:** znížiť náklady na vývoj LatteOS. Týždenný limit predplatného Claude (reset **v pondelok o 15:00**) sa dnes
minie už vo štvrtok, teda približne za 3,5 dňa zo 7. Aby vydržal celý týždeň, treba spotrebu Clauda **zhruba
prepoliť**. Mechanickú prácu preto prevezme lokálny model, Claude ostane na myslenie, plán a kontrolu.

**Východisko (ako sa pracuje dnes):** na hlavnom PC beží VS Code s rozšírením Claude Code, napojený cez Remote-SSH
na latte-lab. Hlavné PC: Windows 11, 80 GB RAM, RTX 3060 12 GB, používa sa aj na inú prácu. latte-lab: samostatné PC
s vyvíjaným Linuxom, kábel priamo do hlavného PC (hlavné PC `192.168.137.1`, latte-lab `192.168.137.x`, pozri
[setup/lab/README.md](../setup/lab/README.md) §4).

---

## 1. Odpovede na hlavné otázky

**Rozhodnutie (8. 10.):** farmu nebudeme písať od nuly. Základom je **[clodfarm](https://github.com/matank001/clodfarm)**
(MIT, Python, kontajner). Farma sa **spúšťa a pauzuje ručne** tlačidlom v jej paneli, takže netreba žiadnu
vlastnú aplikáciu (§4.3). Pravidlo „preberať, nevymýšľať“.

**Kde beží Claude Code?** Na **latte-lab**. Pri Remote-SSH sa rozšírenie Claude Code spúšťa na vzdialenom PC, nie
na hlavnom. VS Code na hlavnom PC je iba okno. Koordinátor tak priamo vidí repo, kompiluje a skúša Goo na latte-lab.

**Čo kde beží:**

| časť | kde | čo robí |
|---|---|---|
| **LM Studio server** | hlavné PC | počíta lokálny model na RTX 3060; model nahrá až pri úlohe |
| **clodfarm** (kontajner) | latte-lab | front úloh, pracovníci vo vlastných kópiách repa, **webový panel** `:8080` s náhľadom, čo kto robí, a tlačidlom **PAUSE THE FARM / RESUME**, kontrola pred zlúčením, rozvrhy, stráženie limitu Claude |
| **bot „lokal“** v clodfarm | latte-lab → LM Studio | Claude Code na lokálnom modeli; robí mechanické úlohy, **limit predplatného nemíňa** |
| **Koordinátor** | latte-lab (VS Code + Claude Code) | rozhovor s tebou; úlohy posiela farme cez MCP |

**Kde sa zadávajú úlohy?** Stále **v paneli Claude Code vo VS Code**. Claude Code sa na clodfarm pripojí ako server
MCP (`claude mcp add --transport http farm http://localhost:8080/mcp`). Potom mu stačí povedať napríklad „daj farme
preložiť texty Tvorcu Goo, na bota lokal“. Ďalšie cesty:

- **panel clodfarm** v prehliadači alebo vo VS Code (Remote-SSH prepošle port `8080` sám),
- **aplikácia Claude v mobile** (Remote Control): farma je tam ako relácia „[clodfarm]“,
- príkazový riadok `clodfarm spawn …`.

```
 HLAVNÉ PC (Windows)                                  LATTE-LAB (Linux)
 ┌──────────────────────────────────┐  Remote-SSH     ┌────────────────────────────────────────────┐
 │ VS Code — iba okno               │═══════════════▶ │ Claude Code = KOORDINÁTOR (predplatné)     │
 │   + panel farmy (localhost:8080) │                 │      │ MCP: spawn --on lokal               │
 │                                  │                 │      ▼                                     │
 │ panel farmy: [PAUSE] / [RESUME]  │ ─ ručne ───────▶│ clodfarm (kontajner, :8080)                │
 │                                  │                 │   front · worktree · overenie · panel      │
 │                                  │                 │   bot „lokal“ = Claude Code               │
 │ LM Studio server :1234  ◀────────┼── /v1/messages ─│     s ANTHROPIC_BASE_URL na LM Studio      │
 │  RTX 3060 12 GB + 80 GB RAM      │                 │   → výsledok do miestneho repa farmy       │
 └──────────────────────────────────┘                 └────────────────────────────────────────────┘
 mobil: aplikácia Claude ── Remote Control ──▶ clodfarm
```

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

## 4. Farma: clodfarm

### 4.1 Čo clodfarm vie (a prečo ho brať)

Overené z jeho dokumentácie (8. 10. 2026; projekt vznikol 25. 9. 2026, je mladý):

- **Úlohy = podagenti:** `clodfarm spawn "Názov" --prompt "…" --on lokal` spustí `claude -p` vo vlastnom
  `git worktree`. Výsledok sa zlúči do `main` farmy, **iba ak prejde overenie** (`FARM_VERIFY_CMD`). Inak sa
  pracovník obnoví s výpisom chyby a opraví to.
- **Boti = iné modely:** bot je ten istý Claude Code s `ANTHROPIC_BASE_URL` na iného poskytovateľa. Podporuje aj
  „Anthropic-compatible“ adresu, čo LM Studio od 0.4.1 je. Bot berie iba úlohy poslané naň (`--on lokal`), jeho
  podagenti ostávajú na ňom a **nikdy nemíňa limit Claude**.
- **Panel** `http://latte-lab:8080`: kto na čom pracuje, podagenti, nástroje, spotreba. K tomu **Remote Control**
  (ovládanie z aplikácie Claude v mobile), rozvrhy (`schedule`), upozornenia (ntfy), denník udalostí.
- **Stráženie limitu Claude:** číta skutočné percentá 5-hodinového a týždenného limitu, a to za **celý účet vrátane
  tvojej práce vo VS Code**. Keď pracuješ ty, farma uberie.
- **PAUSE THE FARM / RESUME** v paneli (aj `clodfarm pause` / `resume`): zastaví a znova spustí štart nových úloh.
  Pri bežiacej úlohe je **CANCEL**, pri hotovej **RETRY**.
- **MCP:** Claude Code vo VS Code vidí farmu a posiela jej úlohy.

### 4.2 Nastavenie clodfarm pre náš cieľ (šetriť, nie míňať)

clodfarm je od výroby nastavený tak, aby predplatné **vyťažil** (model Opus, do 80 % týždňa). My chceme opak:

| premenná | hodnota | prečo |
|---|---|---|
| `FARM_MODEL` | `sonnet` | ak už farma použije Claude, nech je to lacnejší model |
| `FARM_WEEKLY_TARGET` | napr. `0.20` | Claude vo farme prakticky nepracuje (týždeň míňaš ty vo VS Code), všetko ide na bota |
| `FARM_MAX_WORKERS` | `1` | jedna grafická karta |
| `FARM_REPO_URL` | **miestny** repozitár na latte-lab (napr. `/srv/farma.git`), **nie GitHub** | farma zlučuje do svojho `main` sama; na GitHub ide iba to, čo prevezmeš ty |
| `FARM_VERIFY_CMD` | napr. `cargo check --workspace` | do `main` farmy ide iba kód, ktorý sa preloží |
| `FARM_PERMISSION_MODE` | `bypassPermissions` (predvolené) | v kontajneri je to bezpečné; kontajner vidí iba repo farmy |
| `FARM_NOTIFY_URL` | voliteľne ntfy | správa do mobilu, keď je úloha hotová alebo zlyhala |

Bot pre LM Studio: v paneli **+ ADD AGENT → ADD AGENT WITH API KEY → Anthropic-compatible**, adresa
`http://192.168.137.1:1234` (bez `/v1`), kľúč = token z LM Studia, model napr. `qwen3-coder-30b-a3b-instruct`.
Pri prvom pridaní sa farma spýta modelu na jedno slovo, aby overila spojenie. Voliteľne `--any`, aby bot bral aj
úlohy bez `--on`.

**Prevzatie práce farmy:** v hlavnej kópii repa pridať vzdialený repozitár `farma` (`/srv/farma.git`), pozrieť
`git diff` a zlúčiť do pracovnej vetvy. Kontrolu robí koordinátor (Sonnet) alebo `/ponytail-review`.

### 4.3 Spustenie a pauza — ručne (rozhodnutie 8. 10.)

Farmu zapína a pauzuje používateľ sám. Vlastná aplikácia na sledovanie GPU sa **nerobí**.

| chcem | urobím | čo sa stane |
|---|---|---|
| nechať farmu pracovať (PC nepotrebujem) | panel → *Tasks* → **RESUME** | farma berie úlohy z frontu |
| GPU pre seba, nie súrne | panel → **PAUSE THE FARM** | nové úlohy sa nespustia, rozbehnutá **dobehne** (väčšinou minúty) |
| GPU pre seba hneď (hra, strih) | **PAUSE THE FARM** + pri bežiacej úlohe **CANCEL** | úloha sa zruší bez zlúčenia a dá sa neskôr zopakovať (**RETRY**) |
| uvoľniť aj VRAM a RAM | v LM Studiu *Eject* (alebo nechať *Auto-unload* po ~15 min) | model zmizne z pamäte; pri ďalšej úlohe sa nahrá sám |

Panel je na `http://latte-lab:8080`: v prehliadači na Windows 11, vo VS Code (Remote-SSH prepošle port sám) alebo
v mobile. To isté z príkazového riadka: `clodfarm pause` / `resume` / `cancel ID`.

**Neskôr, ak bude ručné ovládanie otravovať:** malý Strážca pri hodinách na Windows (Python + `pynvml`, ~150 riadkov),
ktorý pri spustení hry sám zavolá `clodfarm pause` a po uvoľnení GPU `resume`. Dnes netreba.

### 4.4 Inštalácia (jednorazovo, latte-lab)

```bash
sudo dnf install -y podman podman-docker podman-compose  # clodfarm počíta s docker; overiť, či stačí podman
git init --bare /srv/farma.git && git -C ~/jihlavanka001 push /srv/farma.git main  # miestny repozitár farmy
git clone https://github.com/matank001/clodfarm ~/clodfarm && cd ~/clodfarm   # pripnúť overenú verziu (tag/commit)
cp .env.example .env    # nastaviť premenné z §4.2
docker compose up -d && docker exec -it clodfarm clodfarm login   # prihlásenie tvojím Claude (odkaz + kód)
claude mcp add --transport http --scope user farm http://localhost:8080/mcp   # koordinátor vo VS Code
```

Kontajner nedostane `~/.claude-local`, kľúče GitHub ani tvoj domov, iba `/srv/farma.git`.

### 4.5 Čo naprogramovať / nastaviť (poradie)

| krok | čo | výsledok |
|---|---|---|
| 1 | clodfarm na latte-lab (§4.4), bot `lokal`, skúšobná úloha | farma beží, úlohy z panela a príkazového riadka |
| 2 | MCP vo VS Code + pravidlo v `CLAUDE.md` („mechanické úlohy → `spawn --on lokal`“) | koordinátor posiela úlohy sám |
| 3 | skript na prevzatie práce z `/srv/farma.git` | jednoduché `git diff` / merge do pracovnej vetvy |

**Záloha:** ak by clodfarm nefungoval (mladý projekt, Docker na Fedore, zmena licencie…), vlastná jednoduchá farma
podľa pôvodného návrhu: front úloh v súboroch, `claude -p --output-format stream-json` vo `git worktree` a webový
panel. Zhruba 500–800 riadkov Pythonu.

### 4.6 Ďalšie inšpirácie na GitHube

| projekt | čo z neho vziať |
|---|---|
| [Dicklesworthstone/claude_code_agent_farm](https://github.com/Dicklesworthstone/claude_code_agent_farm) | sledovanie agentov, automatický `/clear`, obnova zaseknutého agenta |
| [vraj00222/agent-farm](https://github.com/vraj00222/agent-farm) | worktree na úlohu, živý výstup, diff, prevziať/zahodiť (iba macOS) |
| [getpaseo/paseo](https://github.com/getpaseo/paseo) | veľké prostredie s aplikáciou pre Windows a mobil; alternatíva k panelu clodfarm |

### 4.7 Smerovač modelov — lokálny podagent priamo v rozhovore (nápad z claude-ui-mod)

[blockshooter/claude-ui-mod](https://gitlab.com/blockshooter/claude-ui-mod) je doplnok pre **Claude Desktop na
Windows**. Prepisuje súbory aplikácie (`app.asar`). Na náš spôsob práce (rozšírenie vo VS Code cez SSH na latte-lab)
sa **priamo nedá použiť** a pri aktualizácii Claude Desktop sa môže pokaziť. Má však jeden výborný nápad: **smerovač
modelov**.

- Claude Code posiela všetky požiadavky na malý miestny server (smerovač) namiesto priamo do Anthropic.
- Smerovač podľa názvu modelu rozhodne: modely Claude pošle ďalej do Anthropic bez zmeny, model `lokal-…` pošle do
  LM Studia.
- Do zoznamu modelov (`/v1/models`) pridá aj lokálne modely, inak by Claude Code podagenta s cudzím modelom odmietol.
- Výsledok: podagent v `.claude/agents/prekladac.md` s `model: lokal-qwen3-coder` beží **na lokálnom modeli priamo
  v tom istom rozhovore vo VS Code**. Koordinátor (Opus/Sonnet) mu zadá úlohu ako bežnému podagentovi a dostane iba
  krátky výsledok, takže ani kontext koordinátora sa nezapĺňa.

Na Linuxe by smerovač bežal na latte-lab ako malá služba a Claude Code vo VS Code by naň ukazoval cez
`ANTHROPIC_BASE_URL`.

**Treba overiť pred nasadením:**

- **Prihlásenie predplatným cez vlastný smerovač nie je oficiálne podporované** Anthropicom. Funguje to (claude-ui-mod
  to tak robí), ale môže sa to kedykoľvek zmeniť. Pred použitím treba prečítať aktuálne podmienky.
- Existuje hotový smerovač pre Claude Code s Linuxom (napr. projekt *claude-code-router*). Overiť, či vie posielať
  modely Claude ďalej s predplatným a ostatné do LM Studia.

**Vzťah k Farme:** smerovač je na **malé, rýchle úlohy počas rozhovoru** (preklad, súhrn logu, hľadanie). Farma je
na **dlhšie úlohy vo fronte**, spúšťané iba pri voľnom GPU. Podagent cez smerovač by GPU používal aj vtedy, keď ho
potrebuješ ty; pri ručnom ovládaní ho vtedy jednoducho nepoužívaj.

---

## 5. Bezpečnosť

- Pracovníci bežia v **kontajneri clodfarm** ako neprivilegovaný používateľ: bez sudo, bez hesla, bez kľúčov
  GitHub. Vidia iba miestny repozitár farmy `/srv/farma.git`, nie tvoj domov ani `.claude-local`.
- clodfarm drží prihlásenie tvojho Claude v zväzku kontajnera. Panel `:8080` nemá heslo: kto ho vidí, vidí aj
  farmu. Port preto otvoriť iba pre kábel k hlavnému PC (alebo iba `localhost` a prístup cez Remote-SSH).
- Podmienky predplatného: clodfarm používa oficiálny Claude Code (headless, Remote Control). Je určený na **vlastné
  projekty s vlastným prihlásením**. Nezdieľať prihlásenie a neposkytovať farmu iným.
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
9. **Ponytail** ([DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail)): zručnosť (plugin) pre
   Claude Code, ktorá agenta učí písať iba nevyhnutný kód. Najprv využije, čo v repe už je, a nepridáva knižnice ani
   prebytočné vrstvy. Autor uvádza v Claude Code s Opus 5.5 **o 45 % menej tokenov a o 26 % nižšiu cenu** (vlastné
   meranie autora, nezávisle neoverené). Bezpečnosť, kontroly vstupov a testy rizikovej logiky podľa neho nevynecháva.
   Inštalácia: `/plugin marketplace add DietrichGebert/ponytail` a `/plugin install ponytail@ponytail`. Má aj
   `/ponytail-review` na kontrolu diffu, čo sa hodí na kontrolu práce farmy. Verzia `AGENTS.md` sa dá dať aj
   lokálnym pracovníkom. **Skúsiť jeden týždeň** a porovnať v tabuľke §7. Pozor, aby jeho pravidlá neprebili
   pravidlá LatteOS (preložiteľné texty, myš ako prvá).

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
| Ponytail (ak sa potvrdí meranie autora) | stredná |

Cieľ: limit vydrží **do pondelka 15:00**. V pondelok pred resetom zapísať, kedy sa limit minul.

| týždeň | limit minutý v | poznámka |
|---|---|---|
| 5. 10. – 12. 10. | štvrtok | pred farmou |

---

## 8. Postup — prvý deň pri hlavnom PC

1. **Hneď (bez inštalácie):** v Claude Code prepnúť `/model` na Sonnet (alebo `opusplan`), nainštalovať Ponytail
   a začať dodržiavať §6.
2. **LM Studio na hlavnom PC:** aktualizovať na ≥ 0.4.1 a stiahnuť `gpt-oss-20b` a `Qwen3-Coder-30B-A3B-Instruct`.
   Nastaviť server podľa §3 (sieť, token, JIT, auto-unload) a firewall iba pre `192.168.137.0/24`.
3. **Test z latte-lab** (terminál vo VS Code): `curl http://192.168.137.1:1234/v1/models -H "Authorization: Bearer
   <token>"`.
4. **Povedať Claudovi vo VS Code:** „Podľa `inspo/dev-ai-prostredie.md` §4.4 nainštaluj clodfarm na latte-lab, pridaj
   bota lokal a pošli mu skúšobnú úlohu.“ Porovnať 2 modely: rýchlosť (tokeny/s) a či úlohu dotiahli.
5. **Prvá skutočná úloha cez farmu** (napr. preklad textov jednej karty Goo), prevzatie z `/srv/farma.git`.
6. **MCP** s pravidlom v `CLAUDE.md` (§4.5, krok 2); vyskúšať PAUSE / RESUME / CANCEL v paneli (§4.3).
7. Výsledok zapísať do `docs/goo/ROZHODNUTIA.md`, farmu ako úlohu do `ROADMAP.md`.

## 9. Otvorené otázky

- Zoznam programov „GPU potrebujem ja“ (hry, strih, OBS…)?
- Má farma bežať aj cez noc? Hlavné PC by muselo ostať zapnuté s LM Studiom (pred spaním RESUME, ráno PAUSE).
- Pustiť aj Claude vo farme (napr. cez noc pred pondelňajším resetom, `FARM_BURST_HOURS`), aby sa nevyužitý zvyšok
  týždňa nepremárnil?

## Zdroje

- LM Studio + Claude Code (rozhranie `/v1/messages` od 0.4.1): <https://lmstudio.ai/blog/claudecode>,
  <https://www.lmstudio.ai/docs/integrations/claude-code>
- Modely: <https://blog.kilo.ai/p/the-best-local-coding-models-for>,
  <https://atomic.chat/blog/guides/best-local-llms-for-coding>, <https://localaimaster.com/vram/best-coding-llm-12gb-vram>,
  <https://www.layer3labs.io/guides/best-local-llm-for-coding>, <https://lmstudio.ai/harshit2004/gemma-4-26b-a4b>,
  <https://aiproductivity.ai/news/gemma-4-26b-local-coding-no-gpu/>
- Gemini CLI zadarmo: <https://www.tembo.io/blog/gemini-cli-pricing>,
  <https://developers.google.cn/gemini-code-assist/resources/faqs?hl=en>, <https://geminicli.com/docs/quota-and-pricing>
- clodfarm: <https://github.com/matank001/clodfarm> (README, docs/bots.md, docs/budget.md)
- Podobné projekty: <https://github.com/Dicklesworthstone/claude_code_agent_farm>,
  <https://github.com/vraj00222/agent-farm>, <https://github.com/getpaseo/paseo>
- Smerovač modelov: <https://gitlab.com/blockshooter/claude-ui-mod> (docs/agents-and-model-mixing.md)
- Šetrenie tokenov: <https://github.com/DietrichGebert/ponytail>
