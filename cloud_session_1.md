# Cloud session 1 — LatteOS (vetva gamerdistro)

1. 10. 2026 · Claude Code v cloude (claude.ai/code) · repo `arkaysk/jihlavanka001`, vetva `gamerdistro`

Záznam všetkého, čo sa v tejto relácii robilo, rozhodlo a odpovedalo. Nové kroky sa dopisujú na koniec.
Cloud nemá prístup k latte-lab (súkromná sieť 192.168.137.x), k obrazovke ani k webom ČHMÚ, MeteoAlarm, Flathub,
ODRS a CDN — všetko je overené iba testami a vzorovými dátami v kontajneri; **na latte-lab treba vyskúšať**
(`git pull`, `setup/f1/install-session.sh`, reštart Kvapiek).

## Zásady od používateľa (platia pre ďalšiu prácu)

- **Myš prvá.** Ľavé, pravé tlačidlo a koliesko. Čo sa nedá urobiť myšou, treba prerobiť. Skratky a príkazy ostávajú
  ako doplnok.
- **Terminál nikdy sám od seba.** Používateľ nič nepíše do terminálu, iba meno a heslo na stránke služby.
  Terminál je dostupný iba po kliknutí na **Zobraziť terminál** (pokročilý používateľ, správca).
- **Nerozbiť hotový dizajn** okien a ich náväznosť na Goo. Scénu `session/kvapky/kvapka.plm` meniť iba keď treba
  a opatrne; generované bloky meniť aj v generátoroch (`goo.py`, `volne.py`, `danogoo.py`, `powergoo.py`, `spustac.py`).
- Vývoj hlavne **LatteOS Goo** (z marea-plm / pleamar); **LatteOS Classic** pribaliť ako alternatívu.
- Inštalátor a Atomic až keď bude LatteOS hotový — **zatiaľ nevytvárať**.
- Pozícia bublín v AI rozhovore (vlastné vľavo) je **zámerná**.
- Pred vydaním autor požiada všetky strany o povolenie / oznámi použitie ich kódu (Hyprland, marea…).

## Odpovede a rozhodnutia

**Pripojenie na latte-lab zo cloudu** — nejde: 192.168.137.231 je adresa v domácej sieti, cloud ju nevidí. Riešenie:
Claude Code na vlastnom PC (`claude remote-control`) alebo ručne `git pull` a test.

**Atomic a live USB** (zatiaľ iba plán, nevytvárať):
- základ `ghcr.io/ublue-os/base-main` (Fedora Atomic bez DE, z neho stavia aj Bazzite), z Bazzite prebrať iba HW časti
  (gamescope, Mesa, udev, ovládače, jadro); `dnf remove` z hotového Bazzite s KDE neodporúčané;
- live USB z bootc obrazu cez **Titanoboa** (Universal Blue), inštalácia na disk = `bootc install to-disk`;
- inštalátor = Barista (kontrola HW `latte-boot compat`, disk, jazyk, účet, priebeh).

**AI predplatné mimo webu** — widgety v mobile a rozšírenia VS Code používajú oficiálne nástroje služieb; LatteOS
volá ten istý nástroj (Claude Code, Codex, Gemini CLI, Copilot CLI). Pravidlá služieb: pre vlastné použitie OK;
pred verejnou distribúciou požiadať o súhlas (Anthropic tretím stranám nepovoľuje vstavané prihlásenie claude.ai bez
schválenia) — predvolene kľúč API alebo lokálny model.

**Obchod** — vlastný App Manager ponechať (Setup Plan, NET, „Bude to fungovať?“, RPM), od **Bazaar** prevziať
inštalácie na pozadí ako službu, „Podobné aplikácie“, kurátorské sekcie, svižnosť. Hodnotenia: Flathub hviezdičky
nemá (iba inštalácie a overenie), používateľské hodnotenia a recenzie sú v **ODRS** (GNOME Software, KDE Discover).
Bazaar: ~1 600 hviezdičiek na GitHube, ~36 000 stiahnutí mesačne z Flathubu, predvolený v Bluefine.

## Čo sa urobilo (commity)

| Commit | Čo |
|---|---|
| `d4ed3b7` | **bug001**: archívy (.zip, .7z, .rar, .tar.*, .iso…) otvárajú Súbory ako priečinok; `latte-app subory SÚBOR` otvorí priečinok s označeným súborom; cesty s medzerami; `session/bin/gnome-software` → App Manager („Nájsť viac v aplikácii Softvér“) |
| `e8849b9` | **Kontrola HW** `latte-hw::compat` + `latte-boot compat [--toml]`: CPU (x86-64-v1…v4), vlákna, RAM, swap, HDD aj pod LVM/LUKS, voľné miesto, UEFI, Secure Boot; generácia GPU podľa PCI ID s ovládačom (AMD TeraScale/GCN1–2 s radou `amdgpu.si_support`/`cik_support`, Polaris, Vega, RDNA; NVIDIA Fermi/Kepler → nouveau+NVK, Maxwell–Pascal → 580xx, Turing+ → 595+; Intel Gen6…Arc); zistenia info/warn/block (kód 0/1/2); stupeň výkonu znižuje generácia karty aj platforma (pod 6 GB RAM najviac Úsporný, ≤2 vlákna Minimálny); `[platform]` v mode.toml; 13 + 10 testov |
| `5aab3c0` | Device Manager: IOAPIC a iné systémové zariadenia dosky (Xeon E5 v2) už nie sú „nepodporované“ |
| `2d9baf6` | **AI v bublinách** (`latte-ai`): poskytovateľ `predplatne` (claude/codex/gemini/copilot), DeepSeek a OpenRouter, efektivita, prílohy (text vložený, obrázky/PDF ako prílohy), `usage` (spotreba, zostatok, limity), `hlas start|stop` (pw-record + whisper.cpp / OpenAI); čipy ⚙ · služba · model · efektivita · 📎 · 🎤 · spotreba |
| `2e1d251` | **Hľadanie súborov** `latte-hladaj` (plocate + fd, bez diakritiky, preklepy, poradie podľa otvárania, filtre `typ:` `.pdf` `>10MB` `dnes` `2024` `v:` `"presné"` `obsah:`, ripgrep v obsahu); AI ponuka podľa firmy; **Ollama ako LM Studio** (modely, ● v pamäti, katalóg podľa RAM, sťahovanie s priebehom, teplota, kontext, uvoľniť pamäť, tok/s) |
| `ffff44e` | **Riadok spúšťača** `latte-riadok`: časté aplikácie podľa dennej doby, akcie .desktop na pravý klik, Nastavenia podľa slov, kalkulačka a prevody (jednotky, °C/°F, meny ECB); web: adresy, skratky `w: yt: m: gm: img: tr: gh: fh:`, návrhy vyhľadávača; Linux príkaz: dopĺňanie ako riadky, „Ukázať výstup tu“, „Čo tento príkaz urobí?“ (AI); oprava duplicitných prekladov |
| `7411a25` | **AI bez terminálu**: Nastavenia › AI › Môj účet — Inštalovať, Prihlásiť sa (na pozadí v pseudoterminále, odklikne úvodné otázky, otvorí prehliadač, kód GitHubu v Nastaveniach), Použiť, Odhlásiť, **Zobraziť terminál** iba na klik; nenastavená služba v spúšťači otvorí Nastavenia › AI; model predplatného oddelený (`cli_model`) |
| `ec28861` | **Goo**: koliesko nad TimeGoo / PowerGoo / DaNoGoo plynulo zväčší kvapku aj obsah (1–2,2, pamätá sa); TimeGoo strieda čas s bežiacou minútkou/stopkami a dátum s počasím (celá hodina, nová predpoveď, výstraha); BarGoo a QueenGoo bez zmeny |
| `a04c291` | AI nástroje predplatných sa inštalujú **pri inštalácii LatteOS** (`latte-ai instaluj-system`, preskočí sa pri „Bez AI“); pri výbere služby iba Prihlásiť sa alebo **Mám kľúč API** |
| `57b9a17` | **Výstrahy ČHMÚ a SHMÚ** `latte-pocasie` (CAP ČHMÚ XOCZ50_OKPR podľa ORP, SHMÚ cez MeteoAlarm Atom, záloha MeteoAlarm CZ; poloha → oblasť cez Nominatim; cache 15 min); v TimeGoo žltá / oranžová / červená, oficiálne majú prednosť |
| `c6fac91` | **App Manager**: hodnotenia a recenzie z ODRS (★ na kartách, dlaždica Hodnotenie a Recenzie v detaile) |

## Nové a zmenené súbory

- `session/bin/`: `gnome-software`, `latte-hladaj`, `latte-riadok`, `latte-pocasie` (nové); `latte-ai`, `latte-apps`,
  `latte-devices` (rozšírené)
- `crates/latte-hw/src/compat.rs` (nové), `crates/latte-boot/src/main.rs`
- `session/kvapky/kvapka.luau` (logika spúšťača a kvapiek), `kvapka.plm` (povolenia, preklady, zväčšenie a obsah
  TimeGoo/PowerGoo/DaNoGoo), generátory `volne.py`, `danogoo.py`, `powergoo.py`, `spustac.py`, `ikony.luau`
- `session/apps/subory.qml`, `nastavenia.qml` (Nastavenia › AI), `common/AppManager.qml`, `latteos-subory.desktop`
- `setup/f0-install.sh` (plocate, fd-find, ripgrep, nodejs-npm), `setup/f1/install-session.sh` (nové nástroje,
  predinštalácia AI, archívy → Súbory)

## Na overenie na latte-lab

1. `git pull` → `setup/f1/install-session.sh` → reštart Kvapiek.
2. Ikony doplnené z pamäti (bolt, paperclip, microphone, player-stop, chart-bar, alert-triangle): ak sú zlé,
   `python3 session/kvapky/spustac.py` ich pregeneruje z písma Noctalie.
3. Spúšťač: čipy AI, ponuka služieb, Na tomto PC (Ollama), hľadanie súborov, riadky režimov, pravé kliky.
4. Nastavenia › AI › Môj účet: Prihlásiť sa pri Claude/Gemini/Copilot — ak sa zasekne, Zobraziť terminál a doplniť
   odpoveď do `LOGIN_ANSWERS` v `latte-ai`. Balík npm `@anthropic-ai/claude-code` pri `instaluj-system`.
5. Koliesko nad Hodinami, vypínačom a DaNoGoo; striedanie so stopkami; výstrahy (názvy oblastí v skutočných feedoch).
6. `latte-boot compat` na latte-lab a starších PC (tabuľky PCI ID).
7. App Manager: hviezdičky a recenzie.

## Otvorené (ROADMAP)

- AI: streamovanie odpovede po riadkoch; Tab na dopĺňanie klávesou (udalosť v scéne)
- Hľadanie v obsahu PDF/DOCX, náhľad obrázkov
- App Manager: inštalácie na pozadí ako služba, Podobné aplikácie, ProtonDB, EOL runtime, vrátenie aktualizácie, OARS, písanie recenzií
- Device Manager: compat v Hardvéri, SMART, batéria, fwupd, testy kamery/mikrofónu/reproduktorov/gamepadu, správa pre podporu
- Výstrahy: ručný výber oblasti v Nastaveniach
- Atomic / live USB / inštalátor — až keď bude LatteOS hotový
