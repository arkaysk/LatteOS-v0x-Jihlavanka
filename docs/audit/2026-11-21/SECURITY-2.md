> **Poznámka (21. 11., po správe):** snímka tohto behu vznikla pred opravami S1 (sandbox bez D-Bus, zapečatené a skryté
> cesty), S4 (ACP: `--ignore-scripts`, `--no-build`, povinné sha256, `acp_env`), S5 (krok s druhom, príkazom a cestami),
> S6 (`LATTE_MCP_RUN` pre každý beh), S7 (sandbox projektov z `latte-ai sandbox-args`, nastavenia Claude, Gemini, Codex a
> `.mcp.json` sa nespúšťajú) a S9 (`latte-open` iba http, https, mailto) — commity `bab06722a` až `11bda8878` a fork
> `33380f2e2`+. Tie sú tu ešte vedené ako otvorené. Skenery nebežali (chýba Docker; `podman-docker` je ručný krok).

# Bezpečnostný audit LatteOS, druhé kolo — 21. 11. 2026

**Stav: čiastočný (partial).** Tentoraz `/cso` bežal cez nainštalovaný pomocník
`~/.claude/skills/gstack/bin/gstack-cso-launcher` (gstack-cso 3.0.0, ABI 3). Beh `1795277726166-134f60e5de3cffa8`
v režime daily, rozsah default, limit 600 s (pomocník viac nedovolí), skončil po 253 s. Uložená správa pomocníka je
`~/.gstack/security/cso/e3d7e26211f9b42270a6c0d4/1795277726166-134f60e5de3cffa8/report.md`.

**Žiadny skener nebežal.** Všetky skenery pomocník spúšťa iba v kontajneri Docker a `docker` na latte-lab nie je
(je tam iba `podman`, bez `podman-docker`). Výsledok každého skenera je `not_assessed`.

**Rozsah:** sledované súbory repozitára. `old/` a `inspo/` sú v `.gitignore`, takže do snímky nevošli.
`.claude/settings.local.json` pomocník vynechal. Binárne súbory (obrázky, písma, `.qsb`) zadržal. V 30 textových
súboroch skryl úseky, ktoré vyzerajú ako tajomstvá. Fork agentgramu (`~/src/agentes-chat` @ `abf540cd0`) je mimo
snímky. Opravy v ňom som overil čítaním na hostiteľovi, mimo pomocníka (v tabuľke označené ako *ručne*).

## Skenery

| Skener | Verzia v katalógu | Výsledok | Nálezy | Čo chýba |
|---|---|---|---|---|
| Gitleaks | (obraz `cso-scanners/gitleaks`) | not_assessed | 0 (nebežal) | Docker |
| OSV-Scanner | (obraz `cso-scanners/osv`) | not_assessed | 0 (nebežal) | Docker |
| Semgrep | (obraz `cso-scanners/semgrep`) | not_assessed | 0 (nebežal) | Docker |
| zizmor | 1.30.1 | not_assessed | 0 (nebežal) | Docker; v repe navyše nie je `.github/` (0 workflowov), takže zizmor by nemal čo kontrolovať |
| Trivy | 0.75.0 | not_assessed | 0 (nebežal) | Docker |
| Schemathesis | 4.29.1 | not_assessed | — | Docker a kvalifikovaný runtime profil (Python bez `requirements.txt`) |

**Ako to doplniť (bez sudo to nejde, preto do `docs/manual-inst.md`):**

```
sudo dnf install podman-docker         # /usr/bin/docker nad podmanom
systemctl --user enable --now podman.socket
~/.claude/skills/gstack/bin/gstack-cso-launcher doctor --repo ~/jihlavanka001
~/.claude/skills/gstack/bin/gstack-cso-launcher provision-images --setup-summary   # stiahne obrazy skenerov (sieť)
```

Či pomocník prijme podman cez `podman-docker` ako „trusted docker“, som neoveril. Ak nie, treba `moby-engine`
(`sudo dnf install moby-engine`, `sudo systemctl enable --now docker`, používateľa pridať do skupiny `docker`). Tá
skupina sa ale rovná rootu, preto je podman bezpečnejšia voľba.

**Náhrada za Gitleaks (iba vzory, bez výpisu hodnôt):** `git grep` v HEAD (bez `old/`, `inspo/`) na
`sk-ant-…`, `ghp_…`, `github_pat_…`, `AKIA…`, `xoxb-/xoxp-…` a privátne kľúče našiel jediný súbor,
`docs/audit/2026-11-21/SECURITY.md`. Ten tie vzory iba menuje. `git log --all -G` s prísnejšími vzormi
(dlžka kľúča) označil 16 commitov. Všetky sú v testoch agentgramu, podľa mien súborov ide o testovacie vzorky (pozri
*História* nižšie). `.claude-local/` je v `.gitignore` a podľa rozhodnutia
používateľa v ňom je testovacie heslo. Iba konštatujem, že tam je.

## Overenie opráv od SECURITY.md

| Pôvodne | Oprava | Overené | Stav |
|---|---|---|---|
| S12 `mcp-groups.json` rastie | `group_tokens(…, make=False)` pri kontrole; nové tokeny iba v `/servers` zo zoznamu ToolHive | `bin/latte-mcp:234-251, 490-503, 520-522` (pomocník) | **Opravené** |
| — prázdny token | `len(token) < 16` → `sys.exit`; tokeny skupín `if not want or …` → 401 | `bin/latte-mcp:446-449, 492, 502` (pomocník) | **Opravené** |
| — port vMCP podľa poradia | port sa drží s procesom (`VMCP[group] = (proc, port)`), voľný hľadá iba medzi živými | `bin/latte-mcp:257-271` (pomocník) | **Opravené** |
| — volajúci zdieľaný medzi požiadavkami | `contextvars.ContextVar` na požiadavku, `set`/`reset` okolo `call_tool` | `bin/latte-mcp:63-72, 666-672` (pomocník) | **Opravené** (S6 tým ale neopravené, pozri nižšie) |
| S3 párovanie z cudzej stránky | `latteos:`/`agenteschat:` iba z karty agentgramu, keď `view.url` začína originom nastaveného servera; pred `pair` natívne potvrdenie so serverom | `apps/aicenter/WebTabs.qml:94-107, 164-185` (pomocník) | **Opravené**. Komentár na r. 167 („ponytail: no confirmation yet“) je zastaraný, potvrdenie už je. Zaostrenie `u` (ReferenceError) je tiež opravené (r. 165) |
| S8 POST `latteos/mcp` | `requirePermission(…, "manage_connectors")` | agentgram `connectors-custom.ts:323-333` (*ručne*) | **Čiastočne.** GET (r. 276-299) stačí `read`, ale vracia iba `id, name, what` (bez tokenov, `latteos.ts:86`). Väzba na organizáciu majiteľa počítača (`LATTEOS_OWNER_ORG`) stále chýba: správca hocijakej organizácie na lokálnom serveri si bránu pripojí |
| S7 synchronizácia projektov | priečinok, ktorého `origin` vedie inam, sa nesynchronizuje; v sandboxe `--ro-bind /dev/null` na `.claude/settings.json`, `.claude/settings.local.json`, `.mcp.json` | agentgram `latteos-project-sync.ts:73-78`, `latteos-sandbox.ts:32-36` (*ručne*) | **Čiastočne.** Pozri N1 nižšie |

## Potvrdené nálezy (aktuálny stav), podľa závažnosti

Nálezy H1, M1, M2, M3 sú zapísané v behu pomocníka ako *supported* (statický dôkaz, sekvenčná námietka, nezávislý
recenzent nebol k dispozícii). Ostatné sú pôvodné nálezy, ktoré som v novej snímke iba znova overil.

| ID | Pôvodne | Závažnosť | Kde | Stav |
|---|---|---|---|---|
| H1 | S1 | **Vysoká** | `bin/latte-ai:3076-3083`, `3103` | otvorené, bez zmeny |
| H2 | S2 | **Vysoká** (prostredie latte-lab) | `~/.claude/projects/…/memory/latte-lab-sudo.md` (0644), `.claude-local/latte-lab.md` (0600) | otvorené, súbory sú tam stále |
| M1 | S4 | Stredná | `bin/latte-ai:2841, 2900-2902, 2948, 2961, 2972` | otvorené, bez zmeny |
| M2 | S5 | Stredná | `crates/latte-acp/src/main.rs:84, 131-133` | otvorené, bez zmeny |
| M3 | S9 | Stredná | `bin/latte-open:41` | otvorené, bez zmeny |
| M4 | S6 | Stredná | `bin/latte-mcp:69-72`, `bin/latte-skill:339-355` | otvorené: ContextVar opravil miešanie požiadaviek, nie to, že meno si klient uvádza sám |
| M5 | S7 / N1 | Stredná | agentgram `latteos-sandbox.ts:17, 34-36` | čiastočne opravené |
| M6 | S8 | Stredná (podmienená) | agentgram `packages/engine/src/latteos.ts`, `connectors-custom.ts:276-333` | čiastočne opravené |
| L1 | S10 | Nízka | `goo/lib/lens.luau:2022` | otvorené |
| L2 | S11 | Nízka | `apps/aicenter/ReadmeView.qml:47` (+ CSP r. 24) | otvorené |
| L3 | S13 | Nízka | `bin/latte-ai:925-926` | otvorené |
| L4 | S14 | Nízka | `system/libexec/latte-doghouse:41-44` | otvorené |
| I1 | S15 | Informácia | `bin/latte-ai:2036, 2054` | otvorené |

### H1 — Sandbox agenta: celý domov na zápis, zbernica, sieť (Vysoká)

`sandbox()` stále skladá `--ro-bind / /` … `--bind home home` (`bin/latte-ai:3076-3077`), bez `--tmpfs` na
`$XDG_RUNTIME_DIR`, bez `--unshare-pid`/`--new-session`, a `net = True` (r. 3103). `SEALED` (r. 3064) zakrýva iba
existujúce cesty. **Útočník:** agent ovplyvnený prompt injection alebo agent z registra ACP. **Dopad:**
`systemd-run --user` mimo sandboxu, zápis do `~/.toolhive/bin/thv` (spúšťa ho `latte-mcp`), čítanie `mcp-token`,
`~/.ssh`, hesla z H2. **Oprava:** `--tmpfs ~` a povolené cesty, `--tmpfs "$XDG_RUNTIME_DIR"`,
`--unsetenv DBUS_SESSION_BUS_ADDRESS WAYLAND_DISPLAY PLEAMAR_SOCKETS`, `--unshare-pid --unshare-ipc --new-session`,
sieť iba keď ju služba potrebuje.

### H2 — Heslo pre sudo v čitateľných súboroch (Vysoká, latte-lab)

Poznámka v pamäti má stále práva 0644, `.claude-local/latte-lab.md` 0600. Obsah som nečítal. Spolu s H1 to znamená,
že agent zo sandboxu sa stane rootom. **Oprava:** heslo zmeniť, zo súborov odstrániť a nahradiť úzkym
`/etc/sudoers.d/latte-lab` (NOPASSWD iba pre `latte-guardcorgi manifest`, `install` do `/usr`).

### M1 — Inštalácia agentov ACP spúšťa kód mimo sandboxu (Stredná)

`npm install` bez `--ignore-scripts` (r. 2948), `uv tool install` bez `--no-build` (r. 2961), `env` z registra bez
filtra (r. 2972) ide procesu `latte-acp` na hostiteľovi (r. 2841). Kontrola sha256 (r. 2900-2902) sa preskočí, keď
register sha256 neuvedie a URL nie je release na GitHube (`acp_github_digest` vráti `""`). **Oprava:**
`--ignore-scripts`, `--no-build`, `env` iba zo zoznamu povolených mien a iba cez `bwrap --setenv`, bez sha256
neinštalovať.

### M2 — Povolenie kroku podľa názvu od agenta (Stredná)

`on_receive_request` odovzdá do `ask_person` iba `tool_call.title` (`main.rs:131-133`). `kind`, `rawInput` ani
`locations` sa človeku neukážu (`locations` sa iba zbierajú do zoznamu zmenených súborov, r. 49-57). **Oprava:**
poslať do `latte-skill allow agent` aj `kind`, `rawInput` a `locations`; pri `execute`/`delete` dvojité potvrdenie.

### M3 — `latte-open` otvorí hocijakú schému (Stredná)

`xdg-open url` bez kontroly (`bin/latte-open:41`). Volajú ho stránky z `ReadmeView.qml:47` (odkazy z cudzieho README)
a `WebTabs.qml:190`. **Oprava:** povoliť `http`, `https`, `mailto`; inak otázka s celou adresou.

### M4 — Povolenie na reláciu viazané na meno, ktoré klient sám uvedie (Stredná)

`caller()` stále berie `clientInfo.name` (`bin/latte-mcp:69-72`) a povolenie v `ai-grants.json` je na tom mene
(`latte-skill:339-355`). Oprava z dneška (ContextVar) zabránila iba tomu, aby sa dve súbežné požiadavky pomiešali.
**Oprava:** token pre každé spustenie od `latte-ai do`, alebo `SO_PEERCRED`; cez HTTP token skupiny namiesto mena.

### M5 (N1) — Sandbox projektu v agentgrame: maskovanie iba existujúcich súborov (Stredná, *ručne*)

Nové: `latteos-sandbox.ts:34-36` zakryje `.claude/settings.json`, `.claude/settings.local.json`, `.mcp.json`, ale
(a) iba ak už existujú (`existsSync`), (b) iba v koreni projektu a vo vlastnom podpriečinku, (c) nie
`.gemini/settings.json` (servery MCP s príkazmi), `.codex/config.toml`, ani `CLAUDE.md`/`AGENTS.md` (pokyny pre
agenta). Základ ostáva `--dev-bind / /` (r. 17), takže zvyšok počítača (zbernica, domov) je ako v H1. Kontrola
`origin` (`latteos-project-sync.ts:73-78`) funguje dobre: cudzie repo sa nesynchronizuje ani nepushne.
**Oprava:** rovnaký spevnený sandbox ako v H1; pre Claude Code `--setting-sources user`; maskovať aj `.gemini/`,
`.codex/`, a nie podľa `existsSync`, ale vždy (prázdny tmpfs na `.claude`, `.gemini`, `.codex`).

### M6 — Bránu MCP pripojí správca ktorejkoľvek organizácie (Stredná, podmienená, *ručne*)

POST už vyžaduje `manage_connectors` (`connectors-custom.ts:333`). Organizácia majiteľa počítača sa ale nikde
nekontroluje (`latteos.ts` nemá `OWNER`). Pri lokálnom serveri s ďalšími organizáciami si ich správcovia pripoja
nástroje MCP tohto počítača. **Oprava:** `LATTEOS_OWNER_ORG` (alebo organizácia prvého spárovaného runnera) a GET aj
POST povoliť iba tam.

### L1–L4, I1

- **L1** `goo/lib/lens.luau:2022`: pri „Really run it?“ stále `s.cmd:sub(1, 60)`. Ukázať celý príkaz.
- **L2** `ReadmeView.qml:47`: odmieta sa iba `LinkClickedNavigation`; formulár ani meta refresh nie. Odmietnuť každú
  navigáciu okrem prvého `loadHtml`, do CSP `form-action 'none'; base-uri 'none'`.
- **L3** `bin/latte-ai:925-926`: llama-server na 127.0.0.1:8790 bez `--api-key-file`.
- **L4** `latte-doghouse:41-44`: `open(LOG + ".tmp", "w")` ako root v adresári skupiny `latte`. Použiť `mkstemp`.
- **I1** `bin/latte-ai:2036, 2054`: `npx -y clawhub` / `npx -y skills` bez pevnej verzie.

## Čo sa zmenilo oproti SECURITY.md

- **Opravené:** S12; prázdny token v `latte-mcp`; port vMCP; súbežní volajúci (contextvars); S3 (párovanie iba z karty
  agentgramu s originom nastaveného servera a s potvrdením na tomto počítači); chyba `u` vo WebTabs.
- **Čiastočne:** S7 (kontrola `origin` a maskovanie troch súborov, sandbox ostáva otvorený), S8 (`manage_connectors`
  áno, väzba na majiteľa nie).
- **Bez zmeny:** S1, S2, S4, S5, S6, S9, S10, S11, S13, S14, S15.
- **Nové:** iba drobnosti k S7 (M5: maskovanie podľa `existsSync`, chýba `.gemini`/`.codex`) a zastaraný komentár
  vo `WebTabs.qml:167`.

## História

Pomocník si z histórie ponechal so záplatami iba 2 najnovšie zo 100 commitov (limit 1 MiB), takže história je
*partial*. Ručný `git log --all -G` s prísnymi vzormi kľúčov (bez výpisu hodnôt) označil 16 commitov. Všetky zhody sú v testoch kódu
agentgramu na inej vetve (`packages/engine/test/*.test.ts`, `packages/adapters/test/*`, `apps/server/test/*`,
`packages/config/src/index.test.ts`, po jednom súbore). Podľa mien súborov ide o falošné kľúče na testovanie
maskovania. Hodnoty som nevypisoval, takže to treba potvrdiť Gitleaksom. Hodnoty tokenov z `.claude-local/` v histórii nie sú (overené
21. 11.). Aby to bolo naisto, treba Gitleaks na celú históriu, keď bude Docker.

## Medzery

- Žiadny skener (Docker). OSV na `Cargo.lock` a `bun.lock` agentgramu, Semgrep a Gitleaks na históriu ostávajú hlavné
  chýbajúce kusy.
- V rámci 600 s som prečítal iba súbory z tabuliek vyššie. Model aplikácie, STRIDE, klasifikácia dát, inštalátor
  (`install`, `fresh-install`), `latte-settings`, `latte-apps` ostali *not_assessed*.
- Reprodukcie a opravy sa neskúšali (režim daily, bez Dockera).
- Fork agentgramu je mimo snímky pomocníka; overený iba ručným čítaním.

## Poradie opráv

1. **H2** (heslo preč) a **H1** (sandbox). Rovnakú funkciu sandboxu použiť v agentgrame (**M5**).
2. **M1**, **M2** (ACP), **M3** (`latte-open`).
3. **M4**, **M6**.
4. L1–L4, I1.
5. Nainštalovať `podman-docker` a spustiť `/cso` znova kvôli skenerom.
