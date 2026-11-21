# Inžiniersky audit LatteOS — 21. 11. 2026

Audit iba číta: v `jihlavanka001` ani v `~/src/agentes-chat` sa nič nezmenilo (žiadny edit, commit ani push).
`tests/check.sh` prešiel celý (Rust, príkazy, scény, FILES, jazyk: „all checks passed“). Spustil sa pod `systemd-run … MemoryMax=3G`.

**Čo repo robí:** LatteOS je linuxová plocha pre ľudí, ktorí prichádzajú z Windowsu. Je postavená na Fedore a pleamar-wm: scény Goo
(`.plm` + `.luau`) kreslia kvapky a lištu, aplikácie v QML (DualBrew, LensAI, Nastavenia…) volajú príkazy `bin/latte-*`
(Python/sh), v Ruste sú fyzika kvapiek, index, Chapolera a ACP klient. Vrstva AI (latte-ai, latte-mcp, latte-skill)
spája agentov s počítačom, a to iba s potvrdením človeka.

**Záťaž, s ktorou počítam:** jeden používateľ na jednom počítači. Naraz však beží veľa procesov: Goo, niekoľko okien QML,
používateľské služby systemd (GuardCorgi, latte-mcp http, agentgram runner) a agenti AI. Preto rozhodujú súbehy medzi procesmi,
súbory, ktoré stále rastú, a vstupy od agentov a webových stránok na 127.0.0.1. Výkon na tisícoch používateľov nerozhoduje.

Pojmy: *súbeh* (race): dva procesy zmenia ten istý súbor naraz a jeden prepíše druhého. *Atomický zápis*: zapísať do
dočasného súboru a potom `mv`/`os.replace`, aby čitateľ nikdy nevidel polovičný súbor.

---

## Musí sa opraviť

### 1. Agent jednej skupiny MCP dostane nástroje inej skupiny (`bin/latte-mcp:238-257`)
- **Čo to je:** `latte-mcp http` púšťa pre každú skupinu ToolHive vlastný vMCP na porte `4500 + poradie skupiny v zozname`.
  Proces si pamätá v `VMCP[group]`, port si nepamätá.
- **Problém:** Poradie sa mení. `toolhive_groups()` vynechá skupinu bez serverov (`:200-201`). Príklad: bežia skupiny `a` (4500)
  a `b` (4501). Používateľ odoberie posledný server zo skupiny `a`. Skupina `b` má teraz poradie 0, teda port 4500. Jej proces
  stále žije, preto sa nový nespustí. Kontrola `/health` na 4500 odpovie, lenže tam beží vMCP skupiny `a`. Agent, ktorý smie
  iba `b`, s tokenom `b` volá nástroje `a`.
- **Oprava:** Uložiť port spolu s procesom (`VMCP[group] = (proc, port)`) a vrátiť ten uložený port. Nový proces dostane voľný
  port, napríklad zo `socket.bind(("127.0.0.1", 0))`. Je to asi 5 riadkov.
- **Ak to vynecháme:** Hranica „každý agent iba svoje servery“ sa potichu prelomí. Agent môže použiť nástroje, ktoré mu
  človek nedal (súbory, GitHub…).

### 2. Ktokoľvek bez tokenu môže donekonečna zväčšovať `mcp-groups.json` (`bin/latte-mcp:463-475`, `:217-232`)
- **Čo to je:** Pri `/mcp/NAME` sa token skupiny hľadá cez `group_tokens([NAME])`. Táto funkcia chýbajúci token **vytvorí
  a zapíše na disk**, a to ešte pred kontrolou autorizácie.
- **Problém:** Každá požiadavka na neznáme meno, aj bez hlavičky Authorization, pridá do súboru nový záznam a celý súbor
  prepíše. Stačí na to akýkoľvek miestny proces, ale aj webová stránka v prehliadači: `fetch("http://127.0.0.1:8791/mcp/x"+i,
  {method:"POST", mode:"no-cors"})` sa na server dostane. Súbor rastie a každý zápis je pomalší (O(n²) na disku). Navyše dve
  požiadavky naraz zapisujú do toho istého `TOKENS + ".new"` a `os.replace` jednej z nich spadne.
- **Oprava:** V `guarded` tokeny iba čítať, nevytvárať: `want = read_tokens().get(group, "")`, a pri prázdnom `want` hneď
  vrátiť 401. Vytvárať ich len v `/servers`, ktorý je za hlavným tokenom. Dočasný súbor pomenovať s `os.getpid()`.
- **Ak to vynecháme:** Cudzia stránka môže zahltiť disk a spomaliť MCP. Súbor s tajomstvami sa zapisuje z neovereného vstupu.

### 3. Synchronizácia online projektov commitne a pushne do cudzieho gitu (`~/src/agentes-chat/apps/server/runner/latteos-project-sync.ts:67-71, 96-99`)
- **Čo to je:** Runner každých 30 s urobí v priečinku projektu `git add -A`, `commit`, `fetch origin main`, `merge` a `push origin HEAD:main`.
- **Problém:** `git init` a `remote add origin` sa urobia iba vtedy, keď `.git` ešte neexistuje. Ak priečinok už je repozitárom
  používateľa (napríklad klon z GitHubu, ktorý zmenil na online projekt), `origin` ukazuje na GitHub. Runner tam potom každých
  30 s pushne commity „NAME: changes“ so všetkým, čo v priečinku je (aj `.env`), a pri konflikte urobí aj `push --force`
  do `refs/conflicts/…`.
- **Oprava:** Pred `add -A` overiť `git remote get-url origin` = `${base}/${project.id}/git`. Ak sa líši, projekt
  preskočiť a zapísať to do logu. Sú to 2 riadky.
- **Ak to vynecháme:** Súkromný obsah a tajomstvá môžu odísť do verejného repozitára bez toho, aby o tom človek vedel.

### 4. Ctrl+Z v DualBrew a na ploche naraz pokazí denník undo (`bin/latte-files:460-500`)
- **Čo to je:** Undo a redo prepíšu denník takto: `grep -v … > "$from.new"; mv "$from.new" "$from"`. Ostatné príkazy do neho
  pridávajú riadky (`did`, `:96-100`).
- **Problém:** Denník majú spoločný všetky okná aj plocha a nič ho nezamyká. Keď medzi `grep -v` a `mv` niekto dokončí kopírovanie
  a zapíše svoj riadok, `mv` ho zmaže a tento krok sa už nedá vrátiť. Dve undo naraz (dve okná, alebo dvojité Ctrl+Z, ktoré
  `AppWindow.undoDo` spúšťa v cykle) píšu do toho istého `.new`, a tak sa ten istý krok môže vrátiť dvakrát alebo sa môže stratiť.
- **Oprava:** Celé `undo|redo` aj `did` spustiť pod zámkom `flock`. Na začiatok skriptu stačí
  `exec 9>>"$log.lock"; flock 9`, alebo zámok obaliť iba okolo `undo|redo` a okolo `printf >>` v `did`.
- **Ak to vynecháme:** Undo raz za čas vráti niečo iné, než človek čaká, alebo nevráti nič. Pri presunoch súborov tým trpí dôvera.

### 5. Odpoveď AI zmaže, čo sa medzitým v konverzácii zmenilo (`bin/latte-ai:3597-3638`, `keep` `:3577-3581`)
- **Čo to je:** `send` načíta konverzáciu, pridá otázku, potom čaká na odpoveď (aj niekoľko minút) a nakoniec zapíše **celý
  objekt z pamäte** späť do súboru.
- **Problém:** Medzitým môže do tej istej konverzácie písať aj niekto iný (LensGoo a LensAI, `again`, import). Vyhrá posledný
  zápis a správy druhého zmiznú. `keep` používa pevný názov `ID.json.new`, takže pri dvoch zápisoch naraz druhý `os.replace`
  spadne na `FileNotFoundError` a odpoveď sa vôbec neuloží. `forget` počas odpovede navyše konverzáciu „vzkriesi“.
- **Oprava:** V `keep` použiť `".%d.new" % os.getpid()`. Pri poslednom zápise v `send` konverzáciu znova načítať (`load`),
  pridať do nej iba novú odpoveď a súčty `usage`, a ak už neexistuje, nezapisovať ju. Je to asi 6 riadkov.
- **Ak to vynecháme:** Občas sa stratí otázka alebo odpoveď a nikto si to nevšimne.

---

## Bolo by dobré opraviť

### 6. Zrušené rozbaľovanie nechá skrytý priečinok s GB dát (`bin/latte-files:411-413`)
- **Čo to je:** Archív sa rozbaľuje do skrytého `.NAME.unpacking` a až potom sa presunie na voľné meno.
- **Problém:** Pri TERM (tlačidlo Zrušiť) trap iba zabije `7z`/`bsdtar`, skrytý priečinok však nezmaže. Po zrušení rozbaľovania
  5 GB archívu ostane v priečinku neviditeľných 0 až 5 GB. To isté sa stane pri `job move` na iný disk (`:445`): trap maže
  iba pri `copy`, takže pri presune ostane polovičná kópia v cieli.
- **Oprava:** `trap 'kill "$pid"; rm -rf -- "$to"; exit 1' TERM` v riadku 413. V riadku 445 mazať `$t` aj pri `move`, keď je
  `stat -c %d` zdroja iný ako cieľa (zdroj je vtedy ešte celý).
- **Ak to vynecháme:** Disk sa potichu plní a človek nevie čím.

### 7. Chapolera nevie usporiadať fotky na USB kľúči alebo SD karte (`crates/latte-chapolera/src/asset_store/organize.rs:307-327`)
- **Čo to je:** `move_no_clobber` presúva súbor cez `hard_link` a potom `remove_file`, aby nikdy nič neprepísal.
- **Problém:** FAT32 a exFAT (fotoaparáty, SD karty, väčšina USB kľúčov) hard linky nepodporujú. `hard_link` vráti chybu
  (`EPERM`/`ENOTSUP`), takže každý presun plánu skončí ako „failed“ a usporiadanie nepresunie nič. Na iný disk (`EXDEV`) tiež nie.
- **Oprava:** Pri chybe inej ako `AlreadyExists` urobiť `renameat2(…, RENAME_NOREPLACE)` (crate `nix` alebo `libc`), ktorý
  vfat a exfat podporujú. Ak ani ten nejde, vrátiť chybu ako doteraz. Pribudne jedna vetva `match` a test na tmpfs.
- **Ak to vynecháme:** Funkcia nefunguje práve tam, kde je najviac fotiek.

### 8. Každá správa MCP spustí `thv list` a zablokuje celý server (`bin/latte-mcp:458-475`, `:191-214`)
- **Čo to je:** `guarded` je asynchrónny handler uvicornu. Pri `/mcp/one.X` volá `toolhive_servers()`, pri `/mcp/GROUP`
  volá `vmcp()` → `toolhive_groups()`. Obe funkcie synchronne spúšťajú `thv` (2 procesy, timeout 30 s).
- **Problém:** MCP posiela veľa krátkych požiadaviek (initialize, tools/list, každé volanie nástroja). Každá spustí `thv` a kým
  `thv` beží, event loop stojí, teda stoja aj všetci ostatní agenti a `/local/models`. Ak `thv` visí, server stojí až 30 s.
- **Oprava:** Výsledok `thv list` držať v pamäti napríklad 10 s (slovník s časom) a volať ho cez `await asyncio.to_thread(...)`.
- **Ak to vynecháme:** Agenti v agentgrame sú pomalí a pri viacerých naraz občas vyprší ich timeout.

### 9. `session.log` rastie navždy (`bin/latte-session:18`)
- **Čo to je:** `exec >>"$state/session.log" 2>&1`. Do toho istého súboru potom píšu pleamar-wm a všetko, čo spustí.
- **Problém:** Súbor sa nikdy neotáča. Na latte-lab má po pár týždňoch 3,3 MB a s každou reláciou rastie. Riadky `:167-175`
  ho pri páde čítajú cez `stat`/`tail -c`, čo zatiaľ funguje, ale súbor časom zaberie veľa miesta na disku.
- **Oprava:** Pred `exec` pridať jeden riadok: `[ "$(stat -c %s "$state/session.log" 2>/dev/null || echo 0)" -gt 5000000 ] && mv -f "$state/session.log" "$state/session.log.1"`.
- **Ak to vynecháme:** Postupne sa míňa miesto na disku a súbor sa ťažko číta pri hľadaní chyby.

### 10. Dve prílohy s rovnakým menom sa navzájom prepíšu (`bin/latte-ai:3607-3614`)
- **Čo to je:** Prílohy sa kopírujú do `ROOM/files/CHAT/` pod svojím základným menom.
- **Problém:** `~/A/report.pdf` a `~/B/report.pdf` v jednej otázke, alebo `report.pdf` v neskoršej otázke tej istej konverzácie,
  sa uložia ako jeden súbor. AI vidí iba posledný, hoci správa uvádza oba, a staršie správy zrazu ukazujú na nový súbor.
- **Oprava:** Vybrať voľné meno, ako to robí `free_name` v latte-files: `name (2).pdf`, kým `os.path.exists`. Sú to 3 riadky.
- **Ak to vynecháme:** AI odpovedá o nesprávnom súbore a človek o tom nevie.

### 11. Goo a aplikácie zapisujú JSON nastavení neatomicky (`goo/lib/desk.luau:41`, `goo/lib/lens.luau:1620`, `:1815`, `apps/aicenter.qml:151`, `apps/settings.qml:117`, `:181`)
- **Čo to je:** Cez `sh -c 'printf "%s" "$2" > "$1"'`. Súbor sa najprv vyprázdni a až potom zapíše.
- **Problém:** Keď počas zápisu vypadne prúd alebo spadne relácia, alebo keď iný proces číta súbor práve v tej chvíli,
  dostane prázdny súbor. `desktop.json` (rozloženie ikon) sa potom načíta ako predvolený a pri ďalšom uložení sa prepíše
  predvolenými hodnotami. Navyše JSON ako argument nesmie byť väčší ako 128 kB (`MAX_ARG_STRLEN`). Pri stovkách ikon na ploche
  zápis zlyhá a nikto sa o tom nedozvie.
- **Oprava:** Jeden spoločný reťazec `'mkdir -p "${1%/*}" && cat > "$1.new" && mv -f "$1.new" "$1"'` s obsahom na stdin
  (ak to `run` v pleamare dovoľuje). Inak aspoň `printf … > "$1.new" && mv`.
- **Ak to vynecháme:** Raz za čas sa stratí rozloženie plochy alebo rýchle odkazy.

### 12. `latte-files` nemá ani jeden test (`bin/latte-files`, 567 riadkov; `tests/` ho nevolá)
- **Čo to je:** Všetky úkony so súbormi v DualBrew a na ploche: kopírovanie, presun, kôš, undo a redo, konflikty mien, rozbaľovanie.
- **Problém:** Je to kód s najvyšším rizikom straty dát v repozitári a žiadny test nezlyhá, keď sa pokazí (napríklad `aim`
  pri `replace`, obnova z koša na inom disku `:466-486`, poradie `tac` pri undo).
- **Oprava:** Jeden test v `tests/test_bin.py`: v `tempfile` s `HOME`/`XDG_*` nasmerovanými tam urobiť kopírovanie s konfliktom
  mena, potom undo a redo a overiť obsah priečinkov. `gio trash` sa dá nahradiť falošným skriptom v `PATH`. Je to asi 30 riadkov.
- **Ak to vynecháme:** Chyby z bodov 4 a 6 a ďalšie podobné sa ukážu až na skutočných dátach.

### 13. Autorizácia HTTP v `latte-mcp` nie je pokrytá testom (`bin/latte-mcp:458-503`; `tests/test_bin.py:274-279` testuje iba `score`)
- **Čo to je:** `guarded` rozhoduje o troch druhoch tokenov (hlavný, skupiny, jeden server) a o smerovaní požiadaviek.
- **Problém:** Body 1 a 2 vznikli práve tu a žiadny test ich nezachytí. Podobná chyba vznikne pri ďalšej úprave ciest
  (`/mcp/one.`, `/servers`, `/local/*`).
- **Oprava:** Test, ktorý zavolá `guarded` s falošným `scope`/`send` a overí tri prípady: bez tokenu → 401, cudzí token
  skupiny → 401, prázdny `Bearer ` na neznámu skupinu → 401 a `mcp-groups.json` sa nezmení.
- **Ak to vynecháme:** Bezpečnostná hranica ostáva bez strážcu.

### 14. Funkcia prekladu `T()` je trikrát a pri každom volaní číta celú tabuľku (`bin/latte-ai:187`, `bin/latte-skill:48`, `bin/latte-guardcorgi:57`)
- **Čo to je:** Všetky tri kópie otvoria `goo/lang/sk.plm` (3 345 riadkov) a pre každý text v ňom hľadajú regulárnym výrazom.
- **Problém:** Kópie sa musia meniť spolu (formát `.plm`, záložný jazyk) a už sa líšia (`latte-skill` číta s `encoding="utf-8"`,
  `guardcorgi` cez `read()`). `latte-skill list`/`row` volá `T` pre každý riadok, takže súbor sa prečíta desiatky ráz.
- **Oprava:** Tabuľku načítať raz do slovníka (`functools.lru_cache` na čítanie súboru) a všetky tri skripty zjednotiť na jednu
  verziu. Ak skripty nemajú spoločný modul, aspoň rovnaký kód s cache.
- **Ak to vynecháme:** Malé spomalenie a preklady, ktoré sa medzi nástrojmi líšia.

---

## Pekné mať

### 15. Ak agent ACP ponúka iba „povoliť vždy“, človekovo „áno“ sa zmení na zrušenie (`crates/latte-acp/src/main.rs:136-141`)
- **Čo to je:** Po súhlase v LensAI sa hľadá možnosť `AllowOnce`.
- **Problém:** Agent, ktorý ponúka iba `AllowAlways` a `RejectOnce`, dostane `Cancelled`, hoci človek povolil. Krok sa neurobí
  a nevypíše sa žiadny dôvod.
- **Oprava:** Ak `AllowOnce` chýba, pri „áno“ zobrať `AllowAlways` (rozhodnutie aj tak ostáva na LatteOS, ktoré sa pýta pri každom
  kroku), alebo aspoň vypísať `{"t":"ask","answer":"unsupported"}`.
- **Ak to vynecháme:** Zriedkavé „agent nič neurobil, hoci som povolil“.

Menšie veci som vynechal (asi 6): `pending()` v `latte-skill` môže pri dvoch čitateľoch naraz spadnúť na `os.remove`,
množina `seen` v GuardCorgi rastie s počtom pádov, `project_new` spadne na neplatnom symlinku `CLAUDE.md`, `get` nie je
zabalený vo funkcii pre prípad, že `curl | sh` stiahne iba časť skriptu, a podobne.

---

**Verdikt:** Kód je dobre ošetrený (atomické zápisy, zámky proti prepísaniu, manifest GuardCorgi, latte-netd, testy prechádzajú).
Najprv treba opraviť hranicu AI: body 1, 2 a 3 (latte-mcp a sync agentgramu), potom súbehy v undo a konverzáciách (4, 5).

**Lean:** okolo -40 riadkov (zjednotenie `T()`), nula závislostí. `apps/widgets/` (39 tis. riadkov, šesťkrát rovnaké `NoteStore.qml`
a podobne) je vendorovaný export Chaldey s licenciou pri každom widgete. Je to rozhodnutie, nie nález.

**Nekontrolované:** `system/pleamarwm/wm/session.plm` (5 tis. riadkov) a väčšina scén `goo/parts/*.plm` a `goo/drops/*` (iba grep
na shell a zápisy), veľké QML (`settings.qml`, `files.qml`, `chapolera.qml`, `calendar.qml`) iba grep, `goo-phys`, `latte-index`,
`latte-hw`, `latte-boot`, `latte-props` iba prehľad unwrapov, `install` iba časť, `old/`. V agentgrame iba serverové súbory
s „LatteOS“ (sandbox, project-sync, MCP routy), nie web. Nič sa nespúšťalo proti živej relácii, preto body 1 a 8 sú overené
čítaním kódu, nie skúškou.
