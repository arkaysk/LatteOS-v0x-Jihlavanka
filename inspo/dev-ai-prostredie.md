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

**Je potrebná aplikácia, ktorá drží spojenie?** Nie. Jediná služba navyše je **server LM Studia na hlavnom PC**
(port 1234), lebo tam je grafická karta. Všetko ostatné je na latte-lab a spúšťa sa až na požiadanie:

| kde | čo | beží stále? |
|---|---|---|
| hlavné PC | VS Code (okno) | keď pracuješ |
| hlavné PC | **LM Studio server** — model sa nahrá do GPU až pri prvej úlohe a po nečinnosti sa uvoľní | áno, ako služba (malý) |
| latte-lab | VS Code Server + **Claude Code = koordinátor** (predplatné) | keď je otvorené VS Code |
| latte-lab | **`farma`** — skript, ktorý spustí pracovníka na jednu úlohu a skončí | iba počas úlohy |
| latte-lab | pracovník = Claude Code napojený na LM Studio (limit predplatného nemíňa) | iba počas úlohy |

**Kde sa zadávajú úlohy?** Stále **v paneli Claude Code vo VS Code**, ako doteraz. Koordinátor (Claude) sám
rozhodne, čo urobí sám a čo pošle farme. Mechanickú časť napíše ako zadanie a spustí `farma` v pozadí. Keď pracovník
skončí, koordinátor si pozrie iba diff a dá ti vedieť. Ty sa nemusíš učiť nový nástroj, iba môžeš povedať
„toto daj farme“.

```
 HLAVNÉ PC (Windows)                               LATTE-LAB (Linux)
 ┌────────────────────────────┐   Remote-SSH       ┌──────────────────────────────────────────┐
 │ VS Code — iba okno         │══════════════════▶ │ VS Code Server                           │
 │                            │                    │  └ Claude Code = KOORDINÁTOR             │
 │                            │                    │     (Opus/Sonnet, predplatné)            │
 │                            │                    │        │ zadanie .md                     │
 │                            │                    │        ▼                                 │
 │ LM Studio server :1234  ◀──┼──── HTTP ──────────│   farma <úloha>   (skript)               │
 │  RTX 3060 12 GB + 80 GB RAM│   192.168.137.1    │     └ Claude Code s lokálnym modelom     │
 │  /v1/messages              │                    │        v ~/farma/wt-<úloha> (worktree)   │
 └────────────────────────────┘                    │        → commit na vetve farma/<úloha>   │
                                                   │        ◀ koordinátor číta git diff        │
                                                   └──────────────────────────────────────────┘
```

Prečo práve takto: LM Studio od verzie 0.4.1 hovorí formátom Anthropic (`/v1/messages`). Pracovník je preto **ten
istý Claude Code** s tými istými nástrojmi (čítanie, úpravy, bash), iba s inou adresou modelu. Podagenti v Claude
Code (`.claude/agents`) vedia používať iba modely Claude, preto lokálny model treba volať cez samostatný proces,
teda cez skript `farma`.

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

## 4. Farma na latte-lab

### 4.1 Prvé nastavenie (jednorazovo)

Pracovník beží pod **samostatným používateľom `farma` bez sudo**. Nevidí `.claude-local/latte-lab.md` (heslo) ani
tvoje kľúče SSH a GitHub. Koordinátor (beží ako `arkay`) ho smie spustiť iba cez jeden presne povolený príkaz:

```bash
sudo useradd -m -s /bin/bash farma
sudo -u farma git clone ~arkay/jihlavanka001 ~farma/repo      # miestny klon, bez prístupu na GitHub
sudo -u farma bash -c 'curl -fsSL https://claude.ai/install.sh | bash'   # Claude Code pre farmu
sudo install -m 755 setup/lab/farma.sh /usr/local/bin/farma-beh
echo 'arkay ALL=(farma) NOPASSWD: /usr/local/bin/farma-beh' | sudo tee /etc/sudoers.d/farma
```

`~farma/.config/farma.env` (čitateľné iba pre `farma`):

```bash
ANTHROPIC_BASE_URL=http://192.168.137.1:1234
ANTHROPIC_AUTH_TOKEN=<token z LM Studia>
CLAUDE_CODE_ATTRIBUTION_HEADER=0
FARMA_MODEL=qwen3-coder-30b-a3b-instruct    # presný názov podľa `lms ls`
```

Test spojenia z latte-lab: `curl http://192.168.137.1:1234/v1/models -H "Authorization: Bearer <token>"`.

### 4.2 Priebeh jednej úlohy

```
koordinátor (VS Code)                     farma (latte-lab)
1. napíše zadanie  ~/farma-ulohy/<id>.md
2. spustí v pozadí:  farma <id>    ──▶  3. git fetch z hlavnej kópie, worktree farma/<id>
                                        4. Claude Code s lokálnym modelom urobí úlohu,
                                           spustí kontrolu z „Hotovo, keď“
                                        5. commit na vetve farma/<id>, zhrnutie do <id>.vysledok.md
6. dostane oznámenie o konci       ◀──
7. git diff main..farma/<id>  (lacné, iba zmeny)
8. dobré → merge do pracovnej vetvy / zlé → oprava zadania, znova 2.
```

Zadanie má vždy tie isté časti, aby mu malý model rozumel:

```markdown
# Úloha: preklad textov Tvorcu Goo do sk
Súbory: session/goo/… (presné cesty)
Urob: …
Nerob: nemeň logiku, nemeň iné súbory, nič nepushuj
Hotovo, keď: `cargo build` prejde / súbor X obsahuje …
```

Viac úloh naraz: koordinátor môže spustiť niekoľko `farma` v pozadí. LM Studio ich však na jednej grafickej karte
spracuje rad za radom, takže reálne **jedna až dve súčasne**.

### 4.3 Čo treba naprogramovať

| súbor | čo robí | rozsah |
|---|---|---|
| `setup/lab/farma.sh` | worktree, spustenie `claude -p` s `farma.env`, časový limit, commit, súbor s výsledkom | ~80 riadkov bash |
| `setup/lab/farma-instaluj.sh` | používateľ, sudoers, Claude Code pre farmu, šablóna `farma.env` | ~40 riadkov |
| `.claude/agents/` alebo pravidlo v `CLAUDE.md` | kedy a ako má koordinátor posielať úlohy farme, šablóna zadania | text |
| neskôr: nástroj MCP v `latte-mcp` | `farma_zadaj`, `farma_stav`, `farma_vysledok` namiesto bash | až keď sa farma osvedčí |

### 4.4 Práca cez noc (voliteľné)

Ak má farma pracovať aj bez otvoreného VS Code, front `~/farma-ulohy/cakajuce/` prechádza služba `systemd --user` na
latte-lab. Na hlavnom PC musí bežať LM Studio a PC nesmie zaspať. Ráno koordinátor skontroluje vetvy `farma/*`.
Tu sa oplatí aj silnejší `gpt-oss-120b`.

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
3. **Test z latte-lab** (v termináli VS Code): `curl` z §4.1, potom ručne jeden beh Claude Code s premennými
   z `farma.env` na skúšobnú úlohu. Overiť, že model volá nástroje (číta a upravuje súbory). To isté
   s druhým modelom; zapísať rýchlosť (tokeny/s v LM Studiu) a či úlohu dotiahol.
4. **Povedať Claudovi vo VS Code:** „Podľa `inspo/dev-ai-prostredie.md` §4 urob `farma.sh` a `farma-instaluj.sh`.“
   Inštaláciu potom spustí on (heslo pre sudo pozná z `.claude-local`).
5. **Prvá skutočná úloha cez farmu** (napr. preklad textov jednej karty Goo), kontrola diffu, merge.
6. Výsledok a voľbu modelu zapísať do `docs/goo/ROZHODNUTIA.md`, úlohu farmy do `ROADMAP.md`.

## 9. Otvorené otázky

- Má farma bežať aj cez noc (§4.4)? Hlavné PC by muselo ostať zapnuté s LM Studiom.
- Kedy hlavné PC farma nesmie zaťažovať (hry, strih)? Dá sa to riešiť ručne (vypnúť server) alebo časovým oknom.

## Zdroje

- LM Studio + Claude Code (rozhranie `/v1/messages` od 0.4.1): <https://lmstudio.ai/blog/claudecode>,
  <https://www.lmstudio.ai/docs/integrations/claude-code>
- Modely: <https://blog.kilo.ai/p/the-best-local-coding-models-for>,
  <https://atomic.chat/blog/guides/best-local-llms-for-coding>, <https://localaimaster.com/vram/best-coding-llm-12gb-vram>,
  <https://www.layer3labs.io/guides/best-local-llm-for-coding>, <https://lmstudio.ai/harshit2004/gemma-4-26b-a4b>,
  <https://aiproductivity.ai/news/gemma-4-26b-local-coding-no-gpu/>
- Gemini CLI zadarmo: <https://www.tembo.io/blog/gemini-cli-pricing>,
  <https://developers.google.cn/gemini-code-assist/resources/faqs?hl=en>, <https://geminicli.com/docs/quota-and-pricing>
