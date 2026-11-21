# Bezpečnostný audit LatteOS — 21. 11. 2026

**Stav: čiastočný (ručná statická kontrola).** Skill `/cso` sa nedal spustiť cez svoj pomocník: chýba
`~/.claude/skills/gstack/bin/gstack-cso-launcher` (gstack bez CSO helpera, výsledok helpera = *not assessed*). Preto
**žiadne skenery** (Gitleaks, OSV, Semgrep, zizmor, Trivy) ani reprodukcie neprebehli. Všetky nálezy pochádzajú
z čítania kódu. Jedna skúška bola iba na čítanie: v bubblewrape s rovnakými prepínačmi ako `latte-ai` sa vypísal
zoznam mien na zbernici (busctl list) a overilo sa, či ide prečítať súbor tokenu. Nič sa nemenilo, nič sa nespustilo
proti živým službám a nič nešlo na sieť.

**Rozsah:** `bin/` (hlavne latte-ai, latte-mcp, latte-skill, latte-open, latte-files, latte-guardcorgi),
`system/` (jednotky, libexec, tmpfiles, udev), `crates/latte-acp`, `crates/latte-boot`, `apps/aicenter*`
(WebTabs, ReadmeView), výber z `goo/lib/lens.luau`, `goo/lib/open.luau`. Vo forku agentgram (`~/src/agentes-chat`
@ 00f2bc1c4) iba časti LatteOS: `packages/engine/src/latteos*.ts`, `net-guard.ts` (výnimka brány),
`apps/server/runner/latteos-*.ts`, trasy LatteOS v `connectors-custom.ts`, `skills.ts`, `machines.ts`.
**Mimo rozsahu / medzery:** zvyšok upstreamu agentgram, závislosti (lockfile, CVE), CI na GitHube, scény
Goo/pleamar okrem uvedených, `old/`, inštalátor (`install`, `fresh-install`) iba letmo.

## Prehľad nálezov

| ID | Závažnosť | Istota | Kde | Dopad |
|---|---|---|---|---|
| S1 | **Vysoká** | vysoká (čiastočne overené) | `bin/latte-ai:3063-3083` | Sandbox agenta sa dá opustiť (zbernica D-Bus, zapisovateľný domov) a vidí všetky tajomstvá |
| S2 | **Vysoká** | vysoká | `~/.claude/…/memory/latte-lab-sudo.md`, `.claude-local/latte-lab.md` | Heslo pre sudo je v čitateľnom súbore, takže každý agent sa môže stať rootom |
| S3 | Stredná (spiaca, po oprave chyby **Vysoká**) | stredná | `apps/aicenter/WebTabs.qml:149-168` | Webová stránka v karte pripojí tento počítač k cudziemu agentgramu bez potvrdenia |
| S4 | Stredná | vysoká | `bin/latte-ai:2841, 2903, 2948, 2961, 2972, 3110` | Agenti z ACP Registry pri inštalácii a cez `env` spúšťajú kód mimo sandboxu |
| S5 | Stredná | vysoká | `crates/latte-acp/src/main.rs:136-141` | Človek povoľuje krok podľa názvu, ktorý si vymyslí sám agent |
| S6 | Stredná | vysoká | `bin/latte-mcp:66-70`, `bin/latte-skill:342-353` | Povolenie na reláciu je viazané na meno, ktoré si klient MCP sám uvedie |
| S7 | Stredná | stredná | agentgram `apps/server/runner/latteos-sandbox.ts:22-31`, `latteos-project-sync.ts` | Sandbox projektu v agentgrame chráni iba priečinky ostatných projektov, nie počítač |
| S8 | Stredná (podmienená) | stredná | agentgram `packages/engine/src/latteos.ts:112-128`, `net-guard.ts:90, 426-434` | Bránu MCP tohto počítača môže pripojiť správca hocijakého pracovného priestoru |
| S9 | Stredná | vysoká | `bin/latte-open:41` | Odkaz z cudzieho README alebo stránky otvorí hocijakú schému cez `xdg-open` |
| S10 | Nízka | stredná | `goo/lib/lens.luau:2023` | Príkaz navrhnutý AI sa pred spustením ukáže skrátený na 60 znakov |
| S11 | Nízka | stredná (nepotvrdené za behu) | `apps/aicenter/ReadmeView.qml:24, 47` | README môže presmerovať zobrazenie karty na cudziu stránku |
| S12 | Nízka | vysoká | `bin/latte-mcp:217-230, 463-477` | Požiadavka bez tokenu zväčšuje `mcp-groups.json` bez obmedzenia |
| S13 | Nízka | vysoká | `bin/latte-ai:922-927` | Lokálny llama-server je bez kľúča |
| S14 | Nízka | stredná | `system/libexec/latte-doghouse:41-44`, `system/systemd/latteos.tmpfiles` | Root zapisuje dočasný súbor v adresári, do ktorého môže zapisovať skupina `latte` (útok symlinkom) |
| S15 | Informácia | — | `bin/latte-ai:2033-2059` | Skilly z ClawHub a skills.sh idú cez `npx -y` bez pevnej verzie a hneď do všetkých agentov |

**Tajomstvá v gite:** v HEAD ani v histórii sa žiadne nenašli (podrobnosti nižšie).

---

## S1 — Sandbox agenta sa dá opustiť a vidí všetky tajomstvá (Vysoká)

**Kde:** `bin/latte-ai:3063-3083` (`SEALED`, `sandbox()`), `bin/latte-ai:3105` (`net = True` vždy),
`bin/latte-ai:3110-3122` (spúšťa sa s celým `os.environ`).

**Čo sa deje:**
- Prepínače sú `--ro-bind / /` a `--bind ~ ~`. Celý domov sa dá čítať aj zapisovať. Iba zoznam `SEALED` je len na
  čítanie, a aj to iba tie cesty, ktoré **už existujú** (`if os.path.exists(p)`). Na latte-lab `~/.config/autostart`
  neexistuje, takže agent si ho môže vytvoriť.
- `$XDG_RUNTIME_DIR` je síce pripojený iba na čítanie, ale ku soketom sa aj tak dá pripojiť. Overené na tomto počítači
  rovnakými prepínačmi: soket `bus` je viditeľný a `busctl --user list` vypíše 138 mien. Agent teda môže cez
  `systemd-run --user …` (StartTransientUnit) spustiť hocičo **mimo sandboxu**. Dosiahne aj sokety Waylandu a pleamar-wm
  (`pleamar-wm --say`, `agent`).
- Domov sa dá zapisovať aj na miestach, ktoré sa neskôr spúšťajú mimo sandboxu:
  - `~/.toolhive/bin/thv` (symlink, ktorý latte-mcp spúšťa ako `THV`)
  - `~/.bun/bin/bun` a `~/src/agentes-chat` (služby agentgram a agentgram-runner)
  - `~/.claude/` (hooky v settings.json) a `~/.agents/skills` (skilly pre všetkých agentov)
  - `~/.local/share/systemd/user`, `~/.config/fish`, `~/.gitconfig`, `~/.bash_logout`
  - `~/.cache/latteos/acp/registry.json` (podvrhnutý register, pozri S4)
  - `~/.local/share/latteos/toolhive-catalog.json`
- Dá sa čítať všetko: `~/.config/latteos/mcp-token` (overené: čitateľný) aj `mcp-groups.json`, `~/.ssh`, kľúčenky,
  `.env` servera agentgram, rozhovory LensAI (`~/.local/state/latteos/ai/chats`), heslo pre sudo (S2).
  Povolenia v `latte-mcp` („Read your conversations“) tak voči agentovi v sandboxe nič neznamenajú, lebo súbory si
  prečíta priamo.
- Agent môže prepisovať aj vlastný záznam a denník (`~/.local/state/latteos/ai/helper`, `journal`), čiže stopy
  v „What changed“.
- Sieť ostáva vždy zapnutá (`net = True`), takže prečítané údaje môže hneď odoslať.

**Scenár:** Agent čítal webovú stránku alebo README s prompt injection, alebo je to agent z registra (S4). Prečíta
`mcp-token` a `~/.ssh/id_*`, cez `systemd-run --user` spustí proces mimo sandboxu, prípadne prepíše
`~/.toolhive/bin/thv`. Pri ďalšom volaní ho spustí `latte-mcp`.

**Oprava:**
1. Domov nevkladať celý. Použiť `--tmpfs ~` a pripojiť iba pracovný priečinok (`--bind work work`) a nevyhnutné
   priečinky CLI na prihlásenie (napr. `~/.claude`, `~/.codex`, `~/.gemini`) **iba na čítanie**. Výnimku pre zápis dať
   iba tam, kde to CLI nutne potrebuje (napr. `~/.claude/projects`).
2. Zakryť `--tmpfs "$XDG_RUNTIME_DIR"` a `--unsetenv DBUS_SESSION_BUS_ADDRESS`, `WAYLAND_DISPLAY`, `PLEAMAR_SOCKETS`.
   Ak treba zbernicu, tak iba cez `xdg-dbus-proxy` s filtrom (ako Flatpak).
3. Pridať `--unshare-pid --unshare-ipc --new-session` (proti TIOCSTI) a `--cap-drop ALL`.
4. Pri `SEALED` zakrývať aj neexistujúce cesty: buď vytvoriť prázdny adresár pred `--ro-bind`, alebo použiť
   `--tmpfs`. Lepšie je ale prejsť na zoznam povolených ciest (bod 1).
5. Sieť zapnúť iba vtedy, keď ju služba agenta naozaj potrebuje. Ideálne cez proxy s povolenými doménami
   (ponytail v kóde to už spomína).

## S2 — Heslo pre sudo je v čitateľnom súbore (Vysoká, prostredie latte-lab)

**Kde:**
- `~/.claude/projects/-home-arkay-jihlavanka001/memory/latte-lab-sudo.md`: práva 0644, podľa `MEMORY.md` obsahuje
  heslo. Obsah som nečítal, iba počet riadkov so slovom „heslo“.
- `/home/arkay/jihlavanka001/.claude-local/latte-lab.md`: práva 0600 (ale tomu istému používateľovi to nebráni).

**Scenár:** Každý proces používateľa, teda agent v sandboxe z S1, CLI spustené cez agentgram-runner (S7) alebo
skill z ClawHubu (S15), si súbor prečíta a spustí `sudo -S`. Agent napadnutý prompt injection sa tak stane rootom.
Poznámka z pamäte sa navyše posiela modelu vždy, keď ju Claude načíta.

**Kontrola gitu:** `.claude-local/` je v `.gitignore`. Hodnoty z `.claude-local/github-models-token` a
`lm-studio-token` som hľadal v celej histórii (`git log -p` cez všetky vetvy a `origin/*`): 0 výskytov. `CLAUDE.md`
bol do 30. 10. sedemkrát commitnutý na `v0.55` (aj na `v0.3`/`v0.4-fresh`), takže je vo verejnej histórii. Obsahuje
iba odkaz, kde heslo je, **nie heslo samotné** (riadky s heslom som skontroloval so skrytými hodnotami).

**Oprava:** Heslo zmeniť a zo súborov odstrániť. Na latte-lab dať namiesto neho úzke pravidlo
`/etc/sudoers.d/latte-lab` s NOPASSWD iba pre potrebné príkazy (`latte-guardcorgi manifest`, `install`, `cp` do
`/usr/...`), alebo pravidlo polkitu. Ak má heslo ostať, tak iba v kľúčenke (secret-tool) a S1 opraviť tak, aby sa
agent ku kľúčenke nedostal.

## S3 — Stránka v karte LensAI pripojí počítač k agentgramu (Stredná, spiaca)

**Kde:** `apps/aicenter/WebTabs.qml:149-168`.

**Čo sa deje:** `onNewWindowRequested` beží pre **každú** kartu (claude.ai, chatgpt, agentgram, ľubovoľný server,
ktorý si používateľ pridal). Adresu `agenteschat://pair?link=KÓD` vezme a spustí
`latte-ai agentgram pair --link KÓD`. Na tomto počítači sa nič nepotvrdzuje. Potvrdzuje ten, kto kód vyrobil, teda
autor stránky. `agentgram_pair` (`bin/latte-ai:2680-2704`) potom zapne runner, ktorý agentom požičia prihlásenia
AI tohto počítača a prístup k súborom.

**Scenár:** Používateľ má agentgram v režime remote, na cudzom serveri. Prevádzkovateľ servera alebo XSS v jeho obsahu
zavolá `window.open("agenteschat://pair?link=…")` s kódom vlastnej organizácie. Počítač sa pripojí k útočníkovi a ten
cez S7 spúšťa CLI na tomto počítači.

**Prečo len „spiaca“:** Premenná `u` v obsluhe nie je deklarovaná (`if (u.startsWith(…))`, riadok 152), takže obsluha
skončí ReferenceError a **nefunguje nič**: ani prihlasovacie okná (Google/Apple), ani `latte-open`. Je to funkčná chyba
od HEAD~1/~2. Kým sa neopraví, útok nejde. Po oprave (`const u = String(request.requestedUrl)`) ide hneď.

**Oprava:** Pri oprave `u` zároveň:
- spracúvať `latteos://` a `agenteschat://` iba v karte agentgramu (`modelData.startsWith("agentgram")`) a iba vtedy,
  keď `view.url` má origin nastaveného servera (`latte-ai agentgram` → `web`);
- pred `pair` ukázať natívne potvrdenie LensAI so serverom a menom organizácie („Pripojiť tento počítač k …?“).

## S4 — Agenti z ACP Registry spúšťajú kód mimo sandboxu (Stredná)

**Kde:**
- `bin/latte-ai:2948`: `npm install` bez `--ignore-scripts`, teda postinstall beží na hostiteľovi.
- `bin/latte-ai:2961`: `uv tool install` môže stavať balík, build backend tiež beží na hostiteľovi.
- `bin/latte-ai:2972`: `env` z registra sa uloží bez filtra.
- `bin/latte-ai:2841, 3110`: ten `env` dostane neizolovaný proces `latte-acp`.
- `bin/latte-ai:2903`: ak register neuvedie sha256 a GitHub nevráti digest, kontrola sa preskočí (`if want and …`).
- Register sa drží v `~/.cache/latteos/acp/registry.json`, kam môže zapisovať agent zo sandboxu.

**Scenár:**
1. Záznam v registri (alebo podvrhnutý súbor v cache, pozri S1) nastaví `env: {"LD_PRELOAD": "<cesta v archíve>/x.so"}`.
   `latte-acp` je dynamicky linkovaný Rust a `bwrap` na Fedore nie je setuid, takže knižnica sa načíta mimo sandboxu.
2. Balík na npm má postinstall skript, ktorý sa spustí pri „Inštalovať“.

**Oprava:**
- `npm install --ignore-scripts`; pre uv `--no-build` (iba wheel), alebo inštalovať vnútri bwrap so zápisom iba do
  `ACP_HOME/ID`.
- `env` povoliť iba s menami podľa zoznamu (bez `LD_*`, `PATH`, `PYTHON*`, `NODE_OPTIONS`, `BASH_ENV`…) a odovzdať ho
  **iba do sandboxu** (`bwrap --setenv`), nie procesu `latte-acp`.
- Bez sha256 binárku neinštalovať.
- Cache registra presunúť do `SEALED` priečinka, alebo pri každej inštalácii stiahnuť register znova.

## S5 — Povolenie kroku podľa názvu, ktorý si zvolí agent (Stredná)

**Kde:** `crates/latte-acp/src/main.rs:136-141` (`ask_person(&title, …)`).

**Čo sa deje:** LensAI ukáže iba `tool_call.title`. Ten napíše agent, napríklad „Read README.md“, hoci `rawInput` je
`rm -rf ~/Documents`. Druh kroku (`kind`), príkaz ani cesty (`locations`) sa neukážu.

**Oprava:** Do `latte-skill allow agent` posielať `kind`, `rawInput` (príkaz, cesty) a `locations`, a ukázať ich
v LensAI rovnako ako `from → to`. Pre `execute` a `delete` dávať dvojité potvrdenie ako pri „risky“ skilloch.

## S6 — Povolenie na reláciu je viazané na meno, ktoré klient sám uvedie (Stredná)

**Kde:** `bin/latte-mcp:66-70` (`caller()` = `clientInfo.name`) a `bin/latte-skill:342-353` (kľúč `by|ident`
v `ai-grants.json`).

**Scenár:** Používateľ raz povolí „Claude Code: Read your conversations“. Hocijaký iný proces, napríklad agent
v sandboxe, si spustí `latte-mcp` na stdio, v `initialize` sa predstaví `clientInfo.name = "claude-code"` a
`conversations`, `conversation`, `search_chats` aj `ask` dostane bez otázky. Cez HTTP sú všetci agenti agentgramu
jedno meno, takže jedno povolenie platí pre všetkých členov všetkých organizácií.

**Oprava:** Povolenie viazať na identitu, ktorú klient nemôže sfalšovať:
- token pre každé spustenie, ktorý vydá `latte-ai do` (premenná prostredia pre latte-mcp), alebo PID/cgroup rodiča
  cez `SO_PEERCRED` / `/proc`;
- cez HTTP aspoň token skupiny namiesto mena.

V dialógu ukázať, že meno klient uvádza sám.

## S7 — Sandbox projektu v agentgrame chráni iba ostatné projekty (Stredná)

**Kde:** agentgram `apps/server/runner/latteos-sandbox.ts:22-31` (`--dev-bind / /`), `latteos-project-sync.ts:60-100`.

**Čo sa deje:** CLI, ktoré runner spustí podľa správy z agentgramu (v režime remote ide o cudzí server a ďalších
členov), má celý koreňový systém na zápis, sieť, D-Bus a všetko z S1/S2. Komentár „the rest of the computer is as it
was“ to priznáva. Synchronizácia online projektov navyše zapíše do priečinka súbory od ostatných členov, napríklad
`.claude/settings.json` s hookmi alebo `.mcp.json`. CLI ich potom v tom priečinku načíta a spustí.

**Scenár:** Člen zdieľaného online projektu commitne `.claude/settings.json` s hookom `curl … | sh`. Pri ďalšej úlohe
v tom projekte sa hook spustí na počítači používateľa.

**Oprava:**
- Rovnaký spevnený sandbox ako v S1 (domov ako tmpfs, bez zbernice).
- Pri synchronizácii nepreberať `.claude/`, `.mcp.json`, `.gemini/`, `.codex/`, `.git/hooks` (`info/exclude` a
  odmietnuť pri merge), alebo CLI spúšťať s `--setting-sources user` (Claude Code), aby sa nastavenia projektu
  nenačítali.

## S8 — Bránu MCP počítača môže pripojiť správca hocijakého pracovného priestoru (Stredná, podmienená)

**Kde:** agentgram `packages/engine/src/latteos.ts:112-128` (`connectLatteosMcp`), trasa
`apps/server/src/routes/app/connectors-custom.ts:320-333`, výnimka `net-guard.ts:90` a `426-434`.

**Čo sa deje:** Servery ToolHive na tomto počítači (s ich tokenmi a prístupmi) sa ponúkajú **každej** organizácii na
serveri. Nič ich neviaže na majiteľa počítača. Pri lokálnom serveri s jedným používateľom je to v poriadku. Keď na
lokálny server pozve ďalších ľudí alebo vytvorí ďalšie organizácie, ich správcovia pripoja lokálne nástroje MCP
používateľa (súbory, GitHub, …).

**Oprava:** Do `LatteosConfig` pridať organizáciu alebo používateľa majiteľa (`LATTEOS_OWNER_ORG` alebo prvý
spárovaný runner). `connectLatteosMcp` a `GET …/latteos/mcp` povoliť iba tam a iba rolám s `manage_connectors`.

## S9 — `latte-open` otvorí hocijakú schému (Stredná)

**Kde:** `bin/latte-open:41` (`xdg-open url` bez kontroly). Volajú ho tieto nedôveryhodné zdroje:
`ReadmeView.qml:47-48` (odkazy z cudzieho README, `abs()` v riadku 37 nechá `file:`, `steam:`… tak, ako sú),
`WebTabs.qml:167` (stránky v kartách) a návrhy AI v Lens (`open.url`).

**Scenár:** README modelu obsahuje `[Download](file:///…/x.desktop)` alebo `steam://…`, `vscode://…`. Klik spustí
obsluhu schémy bez otázky.

**Oprava:** V `latte-open` povoliť iba `http`, `https`, `mailto`. Ostatné odmietnuť, alebo pred otvorením ukázať
otázku s celou adresou. Rovnaký filter dať do `abs()` v ReadmeView.

## S10 — Príkaz od AI sa pred spustením ukáže skrátený (Nízka)

**Kde:** `goo/lib/lens.luau:2023` (`line2 = s.cmd:sub(1, 60)`, potom „Really run it?“ a `open.shell(s.cmd)`).

**Scenár:** Odpoveď AI ovplyvnená webom navrhne `ls -la` a za ním 60 medzier a `; curl … | sh`. Používateľ dvakrát
potvrdí niečo, čo nevidí celé.

**Oprava:** Pri druhom potvrdení ukázať celý príkaz (aj viac riadkov) a zvýrazniť `; | & $( ) \``. Ak je príkaz
dlhší ako riadok alebo obsahuje znaky nového riadku, varovať.

## S11 — README môže presmerovať zobrazenie karty (Nízka, nepotvrdené za behu)

**Kde:** `apps/aicenter/ReadmeView.qml:24` (CSP) a `:47` (zachytí iba `LinkClickedNavigation`).

**Čo sa deje:** CSP `default-src 'none'` nepokrýva `form-action` ani presmerovanie. `<form action="https://…">` po
kliknutí a pravdepodobne aj `<meta http-equiv="refresh">` vložený cez innerHTML načítajú cudziu stránku priamo do
okna LensAI, kde môže napodobniť prihlásenie. Skripty z README sa nespustia (innerHTML, nonce), to je v poriadku.
`img-src https:` umožňuje sledovacie obrázky (IP adresa), čo je pri kartách z webu prijateľné.

**Oprava:** V `onNavigationRequested` odmietnuť každú navigáciu okrem prvého `loadHtml`. Do CSP pridať
`form-action 'none'; base-uri 'none'`.

## S12 — `mcp-groups.json` rastie z požiadaviek bez tokenu (Nízka)

**Kde:** `bin/latte-mcp:463-477`: `group_tokens([sid])` a `group_tokens([group])` sa volajú **pred** kontrolou
a pre každé meno zapíšu nový token (`217-230`).

**Scenár:** Lokálny proces, alebo webová stránka cez `fetch("http://127.0.0.1:8791/mcp/x"+i)` (Firefox; Chrome to
blokuje cez Private Network Access), pošle tisíce mien. Súbor sa pri každej požiadavke celý číta a prepisuje.

**Oprava:** Pri overovaní tokeny iba čítať. Nový vytvárať iba pre skupiny alebo servery, ktoré vráti
`toolhive_groups()` / `toolhive_servers()` (napr. pri `/servers`).

## S13 — Lokálny llama-server je bez kľúča (Nízka)

**Kde:** `bin/latte-ai:922-927`: `--host 127.0.0.1 --port 8790` bez `--api-key`.

**Scenár:** Hocijaký lokálny proces alebo agent v sandboxe načíta modely a na stroji s 15 GB RAM ho zahltí. Stránka
cez DNS rebinding sa naň tiež dostane, lebo llama-server nekontroluje Host.

**Oprava:** `--api-key-file` so súborom 0600 v `~/.config/latteos` (SEALED) a kľúč odovzdať koncovému bodu agentgramu
(`LATTEOS_LOCAL_LLM_URL` plus kľúč).

## S14 — Root zapisuje dočasný súbor do adresára skupiny `latte` (Nízka)

**Kde:** `system/libexec/latte-doghouse:41-44` (`open(LOG + ".tmp", "w")`, `os.chmod`) a `latteos.tmpfiles`
(`/var/lib/latteos` 2775 root:latte, bez sticky bitu, takže `protected_symlinks` neplatí).

**Scenár:** Člen skupiny `latte` vytvorí symlink `doghouse.log.tmp` → iný súbor, ktorý patrí rootovi. Root ho
prepíše a nastaví mu 0644. `ProtectSystem=strict` a `ReadWritePaths=/var/lib/latteos` obmedzujú dosah iba na tento
adresár (napr. `login/`). `latte-boot` ako root do tohto adresára iba maže (`remove_file` symlinky nenasleduje), ten je
v poriadku.

**Oprava:** `tempfile.mkstemp(dir=…)` (O_EXCL), alebo `os.open(..., O_CREAT|O_EXCL|O_NOFOLLOW)` a `fchmod`. Prípadne
podadresár patriaci iba rootovi pre logy.

## S15 — Skilly z registrov idú hneď do všetkých agentov (Informácia)

**Kde:** `bin/latte-ai:2033-2059` (`npx -y clawhub`, `npx -y skills`, bez verzie), symlink do `~/.claude/skills`.

**Riziko:** Skill (SKILL.md a skripty) je kód pre agenta. Na ClawHube sa v roku 2026 objavili kampane so škodlivými
skillmi a filter `nonSuspiciousOnly` je iba ich vlastné hodnotenie. `npx -y` bez verzie spustí najnovší nástroj.

**Oprava:** Nástroje pripnúť (`clawhub@X.Y.Z`, `skills@X.Y.Z`). Pred inštaláciou ukázať SKILL.md a zoznam skriptov.
Inštalovať do jedného agenta, nie hneď do všetkých troch.

---

## Čo je v poriadku (protiváhy, ktoré som overil)

- `latte-mcp` počúva iba na 127.0.0.1. Tokeny sú 0600 (`O_EXCL`) a porovnávajú sa cez `secrets.compare_digest`.
  Cez HTTP sa odoberú nástroje rozhovorov a pamäte (`APART`). `/local/progress` overuje meno modelu.
- `latte-skill`: odpovede človeka a povolenia sú v `$XDG_RUNTIME_DIR`. Agent v sandboxe ich sám priamo nezapíše
  (cez D-Bus z S1 však áno).
- `latte-netd` (root): číta iba súbor, ktorý patrí danému UID, s `O_NOFOLLOW`, a mená cgroup kontroluje regexom.
  Jednotka má `ProtectSystem=strict` a iba dve schopnosti.
- `latte-doghouse` pracuje s používateľovým systemd cez `setpriv` s jeho UID.
- Archívy: `tarfile` s `filter="data"`, zip cez `extract` (bez `..`). sha256 modelov z HF sa kontroluje.
- agentgram: `latteos-skills.ts` drží cesty cez realpath vnútri priečinka. Synchronizácia projektov kontroluje, že
  `project.path` ostane v `projects`. Token ide v hlavičke, nie v `.git/config`. Výnimka v `net-guard` platí iba
  presne pre origin brány.
- V QML sa príkazy shellu odovzdávajú ako pozičné argumenty (`"$1"`), nie skladaním reťazcov (výnimka
  `files.qml:517` berie príponu iba zo zoznamu povolených).
- Tajomstvá v gite: HEAD (okrem `old/`) a verejná vetva `origin/agent-chats` bez zhody na vzory `sk-ant-`, `ghp_`,
  `github_pat_`, `AKIA`, privátne kľúče, `password = "…"`. Hodnoty tokenov z `.claude-local` nie sú v histórii.

## Vedľajšie zistenie (nie bezpečnostné)

- `apps/aicenter/WebTabs.qml:152`: `u` nie je definované, takže v kartách nefunguje nič, čo otvára nové okno
  (prihlásenie Google/Apple, odkazy do prehliadača, „Open folder“). Opraviť spolu s S3.

## Odporúčané poradie opráv

1. **S2** (heslo preč, zmeniť ho) — 10 minút, veľký dosah.
2. **S1** (spevniť sandbox: domov ako tmpfs, bez zbernice a socketov). Rovnakú funkciu použiť aj v agentgrame (**S7**).
3. **S4** a **S5** (inštalácia a povolenia agentov ACP).
4. **S3** spolu s opravou `u`, potom **S6**, **S8**, **S9**.
5. Ostatné (S10–S15) podľa času.

## Medzery a ďalší krok

- Nainštalovať CSO helper gstack (`gstack-cso-launcher`) a spustiť `/cso` znova. Tak sa doplnia skenery
  (Gitleaks na celú históriu, OSV na `Cargo.lock` a `bun.lock` agentgramu, zizmor na workflowy).
- Za behu overiť S11 (meta refresh v QtWebEngine) a po oprave `u` aj S3, v izolovanej relácii.
- Nepreskúmané: `install`/`fresh-install`, `latte-settings` (AccountsService), `latte-apps` (`pkexec dnf`), scény Goo
  okrem Lens, upstream agentgram.
