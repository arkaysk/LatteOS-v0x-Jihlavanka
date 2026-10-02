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

## Pokračovanie: App Manager podľa Bazaaru, Device Manager

**Odpoveď:** Bazaar je zo samostatných obchodov s Flatpakom momentálne najlepší (rýchly, inštalácie ako služba,
kurátorské sekcie, podobné aplikácie, predvolený v Bluefine). Jeho dobré funkcie som prevzal do vlastného App Managera
(ten má navyše Setup Plan, NET, „Bude to fungovať?“, RPM). Pridaná funkcia od používateľa: počas inštalácie
**môže** používateľ zapnúť konzolu a sledovať priebeh (iba na klik).

| Commit | Čo |
|---|---|
| `6135841` | App Manager: úlohy na pozadí (`latte-apps job run/jobs/konzola/zrus`, systemd-run --user, rad, percentá v stavovom riadku, **Zobraziť konzolu**), Podobné aplikácie, Vrátiť predchádzajúcu verziu (+ flatpak mask), blok Bez bezpečnostných opráv (EOL runtime), vek OARS, Tvoja recenzia (ODRS, hviezdičky klikom); Herňa: ProtonDB (tlačidlo, stupeň pri hre; `latte-games proton`) |
| `1909121` | Device Manager (zároveň Net Manager s Inšpektorom siete — nemenené): kontrola HW v skupine Počítač s radou, zdravie batérie (% pôvodnej kapacity, cykly), SMART bez práv správcu cez udisks2 (predtým iba po Monitore so správcom), testy kamery / reproduktorov / mikrofónu / ovládača (pravý klik aj tlačidlá v detaile), **Správa pre podporu** (`latte-devices sprava` → súbor v Súboroch); firmvér ostáva v App Manageri › Aktualizácie (fwupd) — bez duplikácie |

Overiť na latte-lab: inštalácia z App Managera a zatvorenie okna počas nej (musí dobehnúť), Zobraziť konzolu,
Vrátiť verziu (výstup `flatpak remote-info --log`), EOL (formát `flatpak remote-info`), ProtonDB, testy zariadení
(mpv, speaker-test / paplay, pw-record), správa pre podporu.

## Kurátorský výber obchodu

**Odpoveď:** pôvodný „Výber LatteOS“ bol statický zoznam 16 aplikácií v AppManager.qml. Nahradený kurátorským výberom,
ktorý spravujú a priebežne aktualizujú iní — sekcie obchodu **Bazaar** z projektov **Bluefin** (`projectbluefin/common`,
`etc/bazaar/curated.yaml`: Bluefin odporúča, Prehliadače, Médiá, Kancelária, Hry, Nástroje, Vzdelávanie, AI, Vývoj…) a
**Bazzite** (`ublue-os/bazzite`, `bazaar/content.yaml`: Hry, Streamovanie, Hudba, Kancelária, Nástroje). Sťahuje sa
z GitHubu raz denne, detaily z Flathubu; v nadpise je „vybral Bluefin / Bazzite“. Statický výber ostáva iba ako záloha
bez internetu. Blokovací zoznam Bazzite sa nepreberá (je viazaný na ich systém, napr. blokuje Flatpak Steam).
Overené živo v cloude (raw.githubusercontent.com je dostupný): 10 sekcií Bluefin, 5 Bazzite.

## Monitor LatteOS Classic — hodnotenie a postup

**Čo dnes vie** (`session/apps/common/MonitorView.qml`, `data/HardverView.qml`, `data/SenzoryView.qml`, `bin/latte-sysmon`):
Prehľad (grafy CPU, RAM, GPU, disky, sieť, jadrá, teploty) · Procesy (strom, podľa aplikácií so súčtom, aplikácia →
zariadenie: mikrofón/kamera/zvuk/GPU, ukončiť/vynútiť/celú aplikáciu, príkaz, priečinok) · Čas v aplikáciách (Digitálna
pohoda, limity) · Hardvér ako CPU-Z (kódové meno, nm, takty jadier, cache, inštrukcie, doska/BIOS, SPD a sloty so
správcom, disky, správa) · Senzory ako HWiNFO (hwmon, RAPL W, min/max/priemer, grafy, záznam do CSV, pripnúť na lištu,
premenovať/skryť) · Po štarte ako Autoruns (XDG autostart, systemd user/system, časovače, cron, štart relácie, prihlasovacie
skripty, environment.d, moduly jadra; povoliť/zakázať iba používateľské jednotky) · Výstupy telemetrie (JSON pre OLED,
Stream Deck).

**Porovnanie**

| Oblasť | Vzor (Windows) | Linuxové náprotivky | LatteOS Monitor | Chýba |
|---|---|---|---|---|
| Procesy | Správca úloh Win11, Process Explorer / System Informer | Mission Center, Resources, Plasma System Monitor, btop | CPU, RAM, strom, aplikácie, zariadenia — silné | disk I/O, sieť a GPU po procesoch, vlákna, priorita, afinita, pozastaviť, úsporný režim, ukončiť strom, otvorené súbory a spojenia |
| Výkon | karta Výkon (disk aktívny čas a odozva, každá sieťovka, GPU motory a VRAM, zloženie pamäte) | Mission Center (najbližšie Win11), Resources, nvtop | súhrnné grafy | detail po diskoch/sieťovkách/GPU, zloženie pamäte a zram, **NVIDIA chýba úplne** |
| Služby, používatelia | karty Služby, Používatelia | System Monitor (čiastočne), systemctl | — | celé |
| Po štarte | Autoruns (overenie podpisu, skryť Microsoft, VirusTotal, porovnanie, vplyv na štart) | Stacer, GNOME Tweaks (iba aplikácie), systemd-analyze | najširší výpis na Linuxe | overenie (RPM/Flatpak/LatteOS/neznáme), skryť systémové, vplyv na štart, zakázať systémové, porovnanie snímok, ďalšie miesta (ld.so.preload, udev, polkit, sudoers.d, shell rc, Flatpak na pozadí) |
| Hardvér | CPU-Z (CPU, Caches, Mainboard, Memory, SPD, Graphics, Bench) | **CPU-X** (klon CPU-Z), hardinfo2, inxi | CPU, cache, doska, SPD — dobré | karta Grafika (Vulkan/GL, ovládač, VRAM, takty), Bench s porovnaním, napätie a násobič |
| Senzory | HWiNFO (min/max/priemer, záznam, upozornenia, OSD, tray, súhrn) | psensor, CoreCtrl, LACT, lm-sensors | min/max/priemer, CSV, grafy, lišta — dobré | upozornenia pri prahu, NVIDIA, throttling, efektívny takt, ventilátory/napätia (moduly nct6775/it87), OSD v hre |

**Zhodnotenie:** koncepciou je Monitor ďalej než Linuxové náprotivky — žiadny z nich nemá v jednom okne Správcu úloh,
Autoruns, CPU-Z, HWiNFO a digitálnu pohodu. Silné: aplikácie a zariadenia po procesoch, Autoruns, senzory. Slabé:
stĺpce procesov (iba CPU a RAM), karta Výkon v detaile, služby, NVIDIA, a cena: Python spúšťaný každú sekundu.

**Navrhnutý postup** (každá fáza samostatne použiteľná):
1. **Procesy ako Win11** — stĺpce Disk (`/proc/PID/io`), GPU (`/proc/PID/fdinfo` drm-engine, amdgpu/i915/xe), Sieť
   (počet spojení cez `ss`; bajty neskôr eBPF), vlákna, priorita, stav, začiatok; akcie Priorita, Úsporný režim (nice 19
   + ioprio idle + cpu.weight), Pozastaviť/Pokračovať, Ukončiť strom; detail: otvorené súbory a spojenia, prostredie.
2. **NVIDIA** — `nvidia-smi --query-gpu` (vyťaženie, VRAM, teplota, takty, výkon W) a procesy na GPU; neskôr NVML.
3. **Výkon** — karty po diskoch (aktívny čas a odozva z `/proc/diskstats`), sieťovkách, GPU (motory, VRAM), zloženie
   pamäte (aplikácie, cache, zram a jeho kompresia).
4. **Služby a Používatelia** — systemd (system aj user): stav, popis, spustiť/zastaviť/reštartovať/povoliť (polkit);
   prihlásení používatelia a ich spotreba.
5. **Po štarte ako Autoruns+** — overenie pôvodu (balík RPM, Flatpak, LatteOS, **neznáme** zvýraznené), „Skryť
   systémové“, vplyv na štart (`systemd-analyze blame`), zakázať aj systémové (polkit), porovnanie s poslednou snímkou
   („pribudlo od…“), nové miesta (ld.so.preload, udev, polkit, sudoers.d, shell rc, Flatpak na pozadí, Hyprland exec-once).
6. **CPU-Z / HWiNFO+** — karta Grafika (vulkaninfo/eglinfo, ovládač, VRAM), Bench (krátky test 1 vlákno / všetky
   s porovnaním s referenčnými CPU), upozornenia senzorov (prah → oznámenie), throttling, efektívny takt, rada na moduly
   ventilátorov/napätí (cez Device Manager).
7. **Architektúra** — `latte-sysmon` do Rustu ako služba `latte-sysmond` (stála telemetria z ROADMAP F4/O): jeden
   proces, socket pre Monitor, lištu, Kvapky a OLED; nižšia cena CPU a pamäte.

## Monitor — vylepšenie (fázy 1–6)

| Commit | Čo |
|---|---|
| `061716e` | **1–2** Procesy ako Správca úloh Win11: stĺpce Disk (`/proc/PID/io`), GPU (fdinfo drm-engine; NVIDIA `nvidia-smi pmon`), Sieť (spojenia cez `ss`), stav, vlákna, priorita; detail procesu (pôvod RPM/Flatpak, PSS, swap, otvorené súbory, spojenia, začiatok); akcie Priorita, Úsporný režim (nice 19 + disk idle), Pozastaviť/Pokračovať, Ukončiť strom (tlačidlá aj pravý klik); **NVIDIA** (vyťaženie, VRAM, teplota, takty, príkon, ventilátor) |
| `58f37bc` | **3** Výkon po zariadeniach: každý disk (aktívny čas, odozva, čítanie/zápis), každá sieťovka, zloženie pamäte (aplikácie, jadro, zdieľaná, vyrovnávacia, voľná) a zram s kompresiou; NVIDIA v Senzoroch |
| `b73eaf9` | **4–5** Stránky **Služby** (systemd systém aj účet: stav klikom, reštart, pri štarte; systémové s heslom správcu) a **Používatelia**; **Autoruns+**: pôvod (balík / Flatpak / LatteOS / tvoje / **neznáme**), vplyv na štart (`systemd-analyze blame`), Skryť systémové, Zapamätať súčasný stav → **NOVÉ** položky, skupina Zabezpečenie (ld.so.preload, sudoers.d, polkit, udev, Hyprland exec), vypnutie systémových služieb |
| `900a424` | **6** Karta **Test výkonu** (7-Zip MIPS porovnateľné s 7-cpu.com, inak zlib; škálovanie, história), Grafika: generácia karty, odporúčaný ovládač, Vulkan, najvyšší stupeň (z `latte-boot compat`), **upozornenia senzorov** (pravý klik › Upozorniť nad hodnotou…, oznámenie), Prehrievanie (počet spomalení) |

Ostáva **7** — `latte-sysmon` do Rustu ako stála služba `latte-sysmond` (nižšia záťaž, telemetria aj bez otvoreného
Monitora). Overiť na latte-lab: stĺpce GPU/Disk (amdgpu fdinfo), Služby a polkit, Autoruns pôvod (`rpm -qf`), Test výkonu
(7-Zip: balík `7zip` alebo `p7zip` vo Fedore — treba doinštalovať), upozornenia.

**Otázka: bude sa Monitor po prepise do Rustu horšie upravovať?** Trochu áno (kompilácia, prísnejší kód, pomalšie
ručné ladenie na latte-lab); výhody: chyby pri kompilácii, testy, výrazne nižšia záťaž. **Rozhodnutie (návrh):**
zmiešaný postup — do Rustu iba neustále bežiaci `stream` (CPU, pamäť, procesy, disky, sieť, senzory); v Pythone
ostáva všetko na klik a často menené (Autoruns, Služby, detail a akcie procesu, Hardvér, Test výkonu, Pohoda,
upozornenia). Rovnaký JSON → okno Monitora sa nemení, návrat na Python jedným riadkom. Až po overení fáz 1–6 na latte-lab.

**Otázka: ako je na tom nový Monitor graficky oproti vzorom?** Hodnotené iba z QML kódu (v cloude sa nedá spustiť).
Obsah na úrovni vzorov; slabšie je vizuálne zvýraznenie nových častí: disky a sieťovky bez grafov (Win11 má zoznam
s mini grafmi + veľký graf), procesy bez sfarbenia buniek podľa záťaže, detail procesu ako stena textu (Process
Explorer má karty), Autoruns+ bez farebných riadkov (Autoruns: ružová/žltá), Test výkonu iba text (CPU-Z: pruhy).
Senzory najbližšie HWiNFO, Služby v poriadku. Návrh: 1 Výkon ako Win11 · 2 heatmapa buniek · 3 detail v kartách ·
4 farebné riadky a ikony pôvodu v Po štarte · 5 pruhy v Teste výkonu. Čaká sa na rozhodnutie / screenshoty.

**Grafické úpravy Monitora** (pred overením na latte-lab; k Monitoru sa vrátime po overení grafiky):
1. nová stránka **Výkon** ako Win11 — vľavo zoznam zariadení (procesor, pamäť, každý disk, každá sieťovka, GPU) s malými
   živými grafmi, vpravo veľký graf vybraného a podrobnosti; zloženie pamäte a zram tu (z Prehľadu presunuté),
2. **sfarbenie buniek** v Procesoch podľa záťaže (CPU, pamäť, disk, GPU) farbou témy,
3. **detail procesu v kartách** Prehľad · Súbory (klik → Súbory) · Sieť,
4. **Po štarte**: celý riadok farebne (neznáme/podozrivé červenkasté, nové farbou témy) a ikona pôvodu,
5. **Test výkonu ako pruhy** (teraz vs. najlepšie meranie) a história ako stĺpcový graf.

## Kombinovaný messenger v Goo

**Otázka: ako nazvať Goo pre kombinovaný messenger (ICQ, FB Messenger, Telegram, Signal…) a dá sa to zjednotiť?**
Mená podľa vzoru (funkcia + Goo): **ChatGoo** (odporúčané), KecGoo, KafeGoo, BubbleGoo. Zjednotenie: **Matrix + mosty
mautrix** (ako Beeper) — Telegram, Signal, Messenger/Instagram, WhatsApp, Discord do jednej schémy (kontakty,
rozhovory, správy, prílohy, reakcie, prečítané); lokálny server (napr. continuwuity) a mosty na PC; upozornenia do
DaNoGoo. Výhrady: **ICQ skončilo v júni 2024**; Telegram (oficiálne API) a Signal (prepojené zariadenie) bez rizika;
Meta služby porušujú ich podmienky (možný zákaz účtu) → upozornenie / webová aplikácia v okne; licencie mostov AGPL.
Postup: 1 ChatGoo s Telegramom a Signalom · 2 Discord a Meta s upozornením · 3 ostatné ako web v okne. Čaká na výber mena.

**Otázka: je Beeper aj pre Linux?** Áno — oficiálne ako AppImage; Flatpak iba neoficiálne komunitné balíky (nie na
Flathube). Beeper je uzavretá aplikácia, správy bežne cez servery Beepera. Odporúčanie: Beeper ako alternatíva
v App Manageri, ChatGoo vlastný na tých istých otvorených mostoch mautrix (lokálne, vzhľad Goo, upozornenia v DaNoGoo).

**Rozhodnutie používateľa: ChatGoo bude iba addon pre pôvodný Beeper (Linux).** Beeper sa po minimalizácii presunie do
kvapky ChatGoo, okolo nej sa zobrazujú správy podľa rovnakých pravidiel ako upozornenia (DaNoGoo). Hotové (`477cb7a`):
zadanie v LATTEOS-GOO.md 4.2c, pomocník `session/bin/latte-chatgoo` (stav / ukaz / skry / prepni / ziskat; Beeper
z PATH, AppImage v ~/Applications, ~/.local/bin, Stiahnuté, alebo Flatpak), inštalácia v install-session.sh, ROADMAP.
Scéna (kvapka, hrozno, presmerovanie upozornení) až naživo na latte-lab — generátor z danogoo.py s predponou `cg.`.

**Nastavenia pre Goo a Classic (zadanie používateľa):** v Goo iba spoločné + **Kvapky (Goo)**, v Classic iba spoločné +
Lišta a systémové menu. Kvapky (Goo): TimeGoo / PowerGoo / DaNoGoo skryť–ukázať, veľkosť, vrátiť na miesto; ChatGoo
ako kvapka alebo ikona Beepera v rohovej lište Noctalie (doplnok, nie nutná); **vlastné kvapky** (ikona, klik, text
z príkazu) ako kvapky widgetov. Súbor `~/.config/latteos/kvapky.json`, logika ho číta každé 2 s. Skrytá kvapka =
veľkosť 0 (scéna: pružina `zt.s/zp.s/zd.s`, `zt.p = max(0, …)`). Goobar a QueenGoo skrytie po úprave ich scény.
Overiť na latte-lab: či po skrytí neostanú drobné zvyšky (guľky počtu DaNoGoo, minibubliny batérie, odlesk Hodín).

**Upresnenie používateľa:** Goobar, QueenGoo a PowerGoo tvoria **základ shellu** (spodnú lištu; z goo maskota Marey,
ktorý bol jeden na všetko — LatteOS má viac špecializovaných s možnosťou tvoriť ďalšie) → **nedajú sa skryť**
(opravené v Nastaveniach aj logike: PowerGoo iba veľkosť). **Živé bytosti:** návrh zapísaný v LATTEOS-GOO.md 3.1 —
iba pri nečinnosti: dážď alebo vietor podľa skutočného počasia (zvlnenie spodnej hrany aj pripnutých kvapiek), hra
(naháňačka so zámernou zrážkou a odrazom, behanie, skákanie ponad ostatné); okamžité prebudenie; nie pri celej
obrazovke, zámku, slabej batérii a v stupni Softvér. Robiť naživo na latte-lab.

## Spoločný engine pre Goo (posúdenie)

**Otázka: ako je teraz napísané celé Goo prostredie, nebolo by jednoduchšie mať engine so všeobecnými pravidlami?**
Áno, dojem je správny. Stav: scéna `kvapka.plm` ~2 870 riadkov, logika `kvapka.luau` ~2 730, k tomu 10 generátorov
(~1 800 riadkov Pythonu), ktoré do scény vkladajú bloky (`// >>> DaNoGoo (danogoo.py)` atď.). Každá kvapka má
vlastnú predponu (`tg.` 41×, `pg.` 28×, `dn.` 93×, `qg.` 50×) a **vlastnú kópiu** polohy, ťahania, prichytenia
k okraju, blízkosti kurzora, zväčšenia a zón. Pomocné funkcie `put`/`once` sú v generátoroch trikrát skopírované,
v logike sú zvlášť `dn_drop` a `free_drop`. Už zjednotené je iba telo (`goo.py`: jedno goo pre všetky kvapky)
a kvapky widgetov (model `wdg` + tabuľka `WIDGETS`, druhy w/tray/custom) — to je hotový vzor enginu.
Príčina: jazyk scény (pleamar) nemá v tele cykly, takže každá kvapka sa musí rozpísať zvlášť.

**Odporúčanie — engine v dvoch vrstvách (bez zásahu do vzhľadu):**
1. **Generátor `entita.py`**: deklaratívna tabuľka kvapiek (predpona, kotva, polomer, správanie: ťahateľná, zväčšiteľná,
   skrývateľná, základ shellu, bobule/upozornenia, nečinnosť) → z jedných pravidiel vytvorí fyziku, polohu,
   prichytenie, blízkosť/svetlo kurzora, zoom, odlesk aj zóny. `volne.py`, `powergoo.py`, `danogoo.py`, `queengoo.py`
   dodajú už len svoj obsah (texty, ikony, bobule). Nová kvapka (ChatGoo) = jeden riadok v tabuľke + obsah.
2. **Register entít v logike** (ako `WIDGETS`): jedna funkcia pre ťahanie/uloženie/zoom/skrytie/vrátenie na miesto
   a **spoločné správanie** (živé bytosti: gravitácia a svetlo kurzora, dážď/vietor, naháňačka, zrážky) — napíše sa
   raz a platí pre všetky kvapky; pravidlá kvapky sú len jej parametre (hmotnosť, pružnosť, povaha).
- Odhad: menej kódu o 30–40 % v scéne a o ~15 % v logike; ChatGoo a živé bytosti sa robia rovno na engine, nie 4× zvlášť.
- Hlbšia možnosť: engine priamo v pleamar (Rust) — nová konštrukcia `entity`/cyklus v tele. Najčistejšie, ale zásah do
  cudzieho jazyka Marey (licencia, aktualizácie) a väčšia práca; až keď vrstva 1–2 ukáže, čo presne chýba.
- Postup: **najprv refaktor na engine (výsledok musí vyzerať pixel po pixeli rovnako), až potom ChatGoo a živé bytosti.**
  Robiť naživo na latte-lab (scénu treba vidieť), po kvapkách: Hodiny → vypínač → DaNoGoo → QueenGoo, s porovnaním
  snímok pred a po. Z cloudu sa scéna nemení bez súhlasu.

**Návrh používateľa: rozšírenie pleamar ako „DLC“, ktoré prežije aktualizáciu pleamar.** Posúdené na aktuálnom
upstreame (pleamar **0.2.6**, `8bb920f`; my máme záplaty na 0.2.3, scéna je ešte `language 0.1`).
- Licencia je **BSD-3-Clause** (nie MIT) — tiež voľná; pri šírení treba ponechať copyright Abela (k4ditano) a jeho
  meno nepoužiť na propagáciu bez súhlasu.
- Dôležité zistenie: pleamar 0.2 už **má** to, čo engine potrebuje, cez verejný jazyk (ten sa pri aktualizáciách
  drží, 0.2 číta aj 0.1): **komponenty s parametrami**, `repeat` a `for` nad modelom, **knižnice** (`import … as`),
  **pluginy** (knižnica + vlastný `.luau`, vlastné povolenia, schválenie `pleamar --approve`), v logike `require`,
  a pravidlo **`idle for 14s`** (základ živých bytostí). Jediné obmedzenie: vnútri `body` (goo zliatie) smú byť
  iba tvary — žiadne `repeat` ani komponenty; preto `goo.py` rozpisuje telá.
- **DLC = „Goo“ ako vrstva nad pleamar, nie fork:**
  1. `session/kvapky/goo/goo.plm` — `library Goo`: komponent `Kvapka(id, kotva, polomer, zoom, ťahateľná…)` so
     zónami, textami, pružinami, blízkosťou kurzora, prichytením; Hodiny, vypínač, DaNoGoo, QueenGoo, ChatGoo
     a vlastné kvapky sú jeho kópie s obsahom v slotoch.
  2. `goo/lib/entita.luau` (cez `require`) — register kvapiek: ťahanie, uloženie, zoom, skrytie, vrátenie na miesto,
     správanie pri nečinnosti (gravitácia a svetlo kurzora, dážď/vietor, naháňačka so zrážkou) — raz pre všetky.
  3. Telá v `body` ostávajú generované (jediný generátor `goo.py` z tej istej tabuľky), kým pleamar nedovolí
     `repeat` v `body`. To je **jediná vec do Rustu**: malá záplata + návrh autorovi ako PR (keď dá súhlas).
  4. Pravidlo trvanlivosti: DLC používa iba zdokumentovaný jazyk a API; záplaty Rustu čo najmenšie, inštalácia
     ich skúša `git apply --check` a **bez nich scéna funguje ďalej** (iba bez danej vymoženosti). Pri novej verzii
     pleamar: `run-tests.sh` + načítanie scény (`pleamar --check`) ako brána pred nasadením.
- Poradie: (a) prechod scény na `language 0.2` a pleamar 0.2.6 na latte-lab, (b) knižnica Goo + `entita.luau`
  po jednej kvapke s porovnaním snímok, (c) ChatGoo a živé bytosti už na DLC. Robí sa naživo na latte-lab.

## Engine Goo — základ (oddelene) a najnovšia Marea

**Zadanie:** do resources prebrať najnovšiu Mareu aj pleamar. Vytvoriť základ enginu, zatiaľ oddelene, a pridať
reláciu „Kvapky engine test“ na prihlasovaciu obrazovku. Programátor aj používateľ majú môcť kedykoľvek pridať
kvapku s vlastným správaním: kurzor, prechod myšou, koliesko, ľavé/pravé/stredné tlačidlo, ťahanie, gravitácia,
lepivosť, veľkosť a rezerva na ďalšie efekty.

**Upstream:** pleamar **v0.2.6** (`8bb920f`), pleamar-wm **v0.2.5** (`c213f55`), marea-plm `a589189`. Obe záplaty
LatteOS sedia bez úprav. Verzie sú pripnuté v `resources/fetch.sh`, ktorý pri zmene tagu urobí novú kópiu.
`install-session.sh` preloží pleamar znova, keď nie je 0.2.6, a pred nasadením skontroluje obe scény (`--check`).

**Nová možnosť: pleamar beží aj v cloude.** Preložený so záplatou, `pleamar --check` overí scénu bez obrazovky
a headless Sway (pixman + llvmpipe) ju ukáže naživo: snímky (grim), falošná myš (`--mouse`), záznam hodnôt
(`--record`). Engine som tak overoval naozaj, nielen kontrolou syntaxe.

**Našli sa chyby v súčasnej scéne Kvapky (moje skoršie úpravy):**
1. `kvapka.plm` by sa na latte-lab **vôbec nenačítala**: `dn.r` používal `zd.p` pred jeho deklaráciou a farba
   výstrahy bola `pick()` (pick farby neberie). Opravené (`c21148b`): zoom pred DaNoGoo, farba cez vnorené `if`.
2. `sin`/`cos` sú v pleamar **v stupňoch**. Striedanie stopiek/minútky (4 s) a výstrahy (~12 s) v TimeGoo som písal
   v radiánoch, takže by sa striedali raz za niekoľko minút. Opravené na `time * 45` a `time * 30`.

**Engine (`session/goo`, README.md, LATTEOS-GOO.md 3.2):**
- `goo.plm`: 16 miest. Všetky pravidlá sú napísané raz (`repeat`): poloha s pružinami, gravitácia kurzora
  (+ priťahuje, − odpudzuje), svetlo kurzora, lepivosť (krk a odtrhnutie, neodtrhnutá sa vráti), zliatie
  s lištou, ťažká padne a odrazí sa, veľkosť (koliesko, prechod), efekty dych/kmit/tras/obeh/tlkot. **Rezerva:**
  efekty 6–9, kanály e1–e4 (veľkosť, posun x/y, žiara) a druhy 2–3. Vstupy: ľavé (klik = pustenie bez
  ťahania), pravé, stredné, podržanie, koliesko, prechod, bublina, ťahanie, pustenie. Nečinnosť po 30 s a 2 min.
- `gen.py` rozpisuje telo goo (jazyk nedovolí `repeat` v `body`) a vytvára zoznam modulov.
- `lib/engine.luau`: register, povahy (pokojná, zvedavá, plachá, lepkavá, ťažká, hravá), predvolené správanie
  (koliesko = veľkosť, stredné = domov, pravé = meno), háčiky pre programátora, uloženie polôh, hra pri nečinnosti
  (skoky, túlanie, naháňačka).
- Kvapky používateľa: JSON v `~/.config/latteos/goo/kvapky/`, za behu do 4 s. `latte-goo novy | skontroluj |
  zoznam | akcia | text | stav | ikony`; akcie spusti/aplikacia/otvor/vystup vykoná pomocník, nie logika.
- Príklady: 8 modulov (počítadlo so všetkými vstupmi, hodiny, zvedavka, plachá, lepkavá, ťažká, bublinka,
  kvapôčka) a 2 JSON (kalkulačka, systém).
- Relácia: `latteos-goo-engine.desktop` → `latte-session kvapky-engine` (plocha Kvapky + `LATTE_KVAPKY_SCENE`).

**Overené v cloude:** `--check` ok. Naživo prešli prechod, klik, koliesko, pravé, podržanie, ťahanie lepkavej
s odtrhnutím, hod ťažkej (spadla na lištu), uloženie polôh, hra pri nečinnosti aj prebudenie myšou, a farby,
texty, prstence a bublina. Opravené počas testu:
- pravé po ľavom sa rátalo ako klik → `lp`;
- po podržaní prišiel aj klik;
- farby (telo goo má jednu farbu) → tón ako vrstva;
- veľkosť textu (`číslo × pomer`);
- tenká čiara krku;
- ikony ako znak vs. meno.

**Neoverené (latte-lab):** stredné tlačidlo (falošná myš ho nemá), ikony (v cloude nie je písmo Tabler),
`cursor.x/y` z Hyprlandu, výkon na RX 640.

### Spresnenie: 64+ kvapiek, pravidlá z LATTEOS-GOO.md, nadnesenie

**Otázky a pripomienky používateľa:**
- Engine iba pre 16 kvapiek? Limit má byť 50 a viac.
- Čítal som súbor LatteGoo? Je v ňom opísané, ako sa kvapky správajú.
- Kurzor kvapky vždy iba priťahuje, nikdy neodpudzuje.
- Pri priblížení sa kvapky nadnášajú, približujú ku kurzoru a prelievajú sa a spájajú (obrázok).
- Kvapky vyskakovacieho okna sa po kliku vznesú a stanú sa tvarom okna; to je v súčasnej verzii dobre.

**Odpoveď:** `LATTEOS-GOO.md` som pred písaním enginu znova nečítal, vychádzal som zo zhrnutia. Chyba, napravená.
Engine porušoval viac pravidiel:
- záporná gravitácia („plachá“);
- vlastné farby kvapiek (pravidlo 6: vždy káva);
- predvolené pravé a stredné tlačidlo a koliesko (pravidlo 8: kontextový klik iba tam, kde ho má funkcia);
- ikona oka (pravidlo 7);
- menovka pod kvapkou (§3: obsah sa hoverom nemení);
- nečinnosť 30 s/2 min namiesto 1/3/6 min (§3.1).

Nadnesenie a prelievanie pri priblížení kurzora engine nemal; na mojich snímkach to preto nebolo.

**Opravené:**
- **64 miest** (`N` v `gen.py`, prepíše aj scénu).
- Kurzor iba priťahuje.
- **Nadnesenie:** kvapka na lište vystúpi kolmo na stopke, ktorá sa naťahuje a tenčí, susedné sa prelievajú
  a spájajú, späť padne s odrazom.
- Nad kvapkou sa mierne nafúkne a netrpezlivo pulzuje. Dych a drift aj bez myši.
- Káva podľa Baristu (`latte-goo kava`, rovnaká tabuľka ako Kvapky); `farba` v JSON je chyba s vysvetlením.
- Vstupy bez háčika nerobia nič. Veľkosť kolieskom iba so `zoom = true` / `"koliesko": "velkost"`.
- Nečinnosť 1/3/6 min; hra iba na stupni 3: naháňačka so zámernou zrážkou a stlačením (`goo_squish`), behanie,
  skákanie; po prebudení sa zachvejú.
- Bublina = názov · popis.

Okno z kvapky (pravidlá 9 a 14) v engine ešte nie je; príde ako druh kvapky.

**Výkon:**
- Pri 64 miestach mal engine v cloude **192 ms** na snímku. Príčina: pleamar počíta každý tvar tela goo pre
  každý pixel a `show: false` ho z tela nevyradí (zmerané: 192 skrytých tvarov 102 ms, žiadne 18 ms).
- Riešenie v jazyku: krk ťahanej kvapky je jeden tvar (`pick(nk, …)`), nie 64; prázdne miesta pod obrazovkou
  (bod nulovej veľkosti cez zliatie vydul hrbček vľavo dole).
- **Záplata `pleamar-prazdne-tvary.patch`:** tvar nulovej veľkosti sa do tela nedá (pleamar to už robil pre
  obdĺžniky). Výsledok **21,6 ms** (súčasná scéna Kvapky 62 ms).
- `install-session.sh` záplatu použije a pleamar preloží, aj keď už je 0.2.6. Vhodná na upstream.
- Bez záplaty engine funguje, iba pomalšie.

**Overené v cloude:**
- `--check` ok.
- Priblíženie kurzora (snímky: nadnesenie na stopkách, mostíky medzi susedmi).
- Test nečinnosti 6,5 min: stupne v 60., 180. a 360. s, hra so zrážkou (stlačenie 0,42), prebudenie myšou,
  priemer **20,8 ms** na snímku.
- Vstupy znova:
  - klik, koliesko, pravé, podržanie bez falošného kliku, ťahanie s odtrhnutím, pád ťažkej;
  - koliesko-veľkosť iba pri kvapkách so `zoom`.

**Chyba nájdená testom:** kurzor pri spodnom okraji zdvihol kvapku nad seba, kvapka mu ušla spod ruky a koliesko,
pravé a podržanie netrafili. Opravené: kvapka sa nadnesie iba po výšku kurzora (naozaj ku kurzoru) a zóna kliku
pokrýva aj stopku.

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

### Porovnanie s TimeGoo a PowerGoo, 128 miest, spájanie kvapiek

**Požiadavka:**
- Pre porovnanie pridať do enginu súčasné PowerGoo a TimeGoo; vidieť, ako sa kvapky spájajú a ovplyvňujú
  (napr. keď je jedna väčšia alebo nadnesená).
- Prečo 64? Goobar (panel úloh) nesie vpravo okná ako ikry/hrozno: ikona s náhľadom, okná toho istého programu
  (Word, SAP…) sa zhlukujú. Pri veľkej RAM môže byť okien veľa → radšej vyšší limit.
- Prelínanie a spájanie zatiaľ nie je také pekné ako v pôvodnej verzii, tam pôsobí prirodzenejšie.

**Ako to robí pôvodná plocha (rozbor `kvapka.plm`):**
1. **Susedia sa ovplyvňujú:** `lift.s = near.s + 0,3 · max(near.p, …)` — kvapka sa nadnesie aj vtedy, keď kurzor
   ide k susedovi; a nakloní sa k nej (`sx += 10 · hh − 9 · hp`).
2. **Voda pod okrajom:** široký pás pod Štartom a vypínačom. Údolie medzi nimi preto nesiaha k okraju a trojica
   pôsobí ako jedna hmota.
3. **Goo vlákna:** vypínač ↔ Hodiny ↔ telo lišty, hrubnú s nadnesením a samy sa tvoria s tokom; po nich tečie
   kvapôčka.
4. **Tok:** `flow`, `flow2` — kvapky v pokoji pomaly vystupujú a klesajú. Sila zliatia
   `link = 10 + 16 · lift + 10 · flow` sa mení, preto sa susedia raz spoja, raz rozdelia.
5. **Okraj obrazovky je hladina:** pod skupinou nie je pás cez celú šírku.

Engine mal iba zliatie a stopku, bez susedov, vody a toku; preto pôsobil stroho.

**Urobené:**
- Engine teraz robí body 1–5 všeobecne pre všetky kvapky:
  - logika nájde susedov na lište podľa polohy (do ~2,6 súčtu polomerov);
  - scéna odhadne ich blízkosť ku kurzoru;
  - voda a vlákno k susedovi vpravo;
  - tok a zliatie ako `link`;
  - okraj ako hladina.
- **TimeGoo, PowerGoo a hlava Goobaru** v engine s rozmermi a rozostupmi z Kvapiek:
  - TimeGoo r 33 (+3), stred 22 px nad okrajom, 92 px vľavo od hlavy, veľký čas + dátum;
  - PowerGoo r 19 (+4), skoro v okraji, vznos ~1,4 r, 66 px vľavo od TimeGoo;
  - koliesko mení veľkosť.
  Nové voľby `pri` + `odstup`, `vyska`, `vznos` do 2.
- **128 miest.** So záplatou prázdne nestoja nič. Engine so 128 miestami a 17 kvapkami: 32–38 ms na snímku
  v cloude (CPU llvmpipe); čítanie scény 0,8 ms.
- Záplata `pleamar-prazdne-tvary` zrýchlila aj **súčasnú plochu Kvapky: 62 → 24 ms** (v cloude).

**Porovnanie** (pôvodná vs. engine; kurzor ďaleko, nad TimeGoo, pri PowerGoo):
`docs/goo/porovnanie-trojica-cloud.png`. Engine je pôvodnej trojici blízko: pri kurzore sa skupina zleje do
jednej hmoty.

**Rozdiely, ktoré ostávajú (doladiť naživo na latte-lab):**
- PowerGoo v Kvapkách vystúpi pri kurzore viac.
- V pôvodnej sa medzi kvapkami tvoria „oká“ (vlákna + kvapôčka).
- Hlava Goobaru je tam zaoblený obdĺžnik so strapcom okien, v engine zatiaľ guľa.
- Ikony v cloude chýbajú (písmo Tabler).
- Kvapôčka tečúca po vlákne v engine ešte nie je.

### Nové pravidlá 17–21: jadro, vlnky, vietor, ponor, krk, oká

**Zadanie (LATTEOS-GOO.md §2, pravidlá 17–21):**
- **Jadro:** od stredu prechod do prednastavenej farby (farebné jadro goo alebo žiara); predvolene ako
  druh upozornenia.
- **Vlnky:** okno môže robiť vlnky ako kameň hodený do vody, alebo vibrácie.
- **Vietor:** náhodný smer, nezávislý od ničoho; občas, aj pri práci, sa kvapky trochu vlnia ako obilie.
- **Krk:** naťahovanie za kurzorom od okraja iba po určitú vzdialenosť, dlhý krk-vlák je nepekný.
- **Malé kvapky** sa na okraji vlnia viac než veľké.
- **Návrat (Marea):** okraj je hladina; keď sa goo vráti k okraju, akoby vnikla pod hladinu a vynorila sa.
- **Oká** medzi spojmi sú pekné, ale okrajová čiara má byť ostrá, nie rozmazaná.

**Urobené v engine:**
- **Jadro:** malé vlastné telo s radiálnym prechodom (pleamar ho vie iba v `body`), farby podľa pravidla 15
  (+ výstraha, svetlo, iné), pulz. API: `d:jadro`, JSON `jadro` / `upozornenie`, `latte-goo upozornenie ID`.
  Príklady: Pošta (každých 12 s nová správa; klik prečíta, pravý mení farbu); Počítadlo (od 10 výstraha, pod 0
  hardvér); Systém (zaťaženie nad 2 = výstraha).
- **Hladina:**
  - 4 vlnky naraz; kameň = dva hrebene sa rozbiehajú 420 px a slabnú, kvapky na nich sa nadvihnú;
    vibrácia = chvenie;
  - zvonka `pleamar --say goo "emit goo_kamen X"` (napr. hook Hyprlandu po minimalizácii); príklad Kameň.
  - **Zmerané:** kameň sa pohne prvý, susedia 87 px vedľa o ~120 ms, 260 px vedľa o ~480 ms.
- **Vietor:** nárazy z pomalého šumu, smer náhodný, postupná vlna pozdĺž okraja. Malé kvapky sa vlnia viac (aj tok
  a drift; zmerané 60 s: r 18 rozkmit 3,4 px, r 44 1,4 px).
- **Ponor pri návrate k okraju** (po pustení) + vlnka.
- **Krk:** odtrhnutie najneskôr po 1,6 polomeru.
- **Ostrý okraj:** tieň 0, 2, 2. Oká vznikajú pri spojoch (snímka).
- **Opravená chyba:** pri ťahaní visel od suseda dlhý vlák k starému miestu; ťahaná kvapka už nie je susedom.

**Nájdená chyba pleamar API (moja, nie pleamar):** `emit` v Luau nesie iba meno, hodnotu zahodí. Skok, stlačenie
a ponor z logiky preto trafili vždy iba kvapku na mieste 0, aj v teste hry. Teraz idú cez počítadlá (fakt
+ `on change`); vlnka overená meraním.

**Snímka:** `docs/goo/jadro-vlnky-cloud.png`.

**Plocha Kvapky:** oká tam majú rozmazaný okraj (tieň tela 0, 6, 16). Nezmenil som to, lebo by sa zmenil aj tieň
celej lišty (dizajn) — čaká na súhlas.

### Ostré oká a vlákna medzi kvapkami

**Zadanie:** zostriť okraj ôk v súčasnej ploche Kvapky (pekná čiara ohraničenia). Vysvetlenie používateľa: tvary
vznikajú tým, že bunky dýchajú a mierne sa hýbu. Nad otvormi je vlákno, ktoré spája susedné goo: čím bližšie, tým
hrubšie, organicky a nepravidelne.

**Príčina rozmazania (zmerané, zväčšené oko):** nespôsoboval ju tieň ani lem. Varianty s tesným tieňom a s ostrou
`border` mali oko stále rozmazané, vonkajší obrys bol ostrý vždy. Pleamar vyhladzuje hranu pevnou šírkou 0,75 px,
ako keby sa vzdialenosť od okraja menila o pixel na pixel. V zliatí (smooth min) je stlačená, preto sa hrana oka
rozmaže na niekoľko pixelov.

**Riešenie: záplata `pleamar-ostre-okraje.patch`.** Vzdialenosť sa pred vyhladením vydelí jej skutočnou zmenou na
pixel (`dpdx`/`dpdy`, pleamar ich už počítal pre sklo). Platí pre výplň, `border`, lem aj tieň pod sklom. Hrana sa
iba zostrí, nikdy nerozmaže viac.
- **Plocha Kvapky sa nemenila:** oká sú ostré vďaka záplate (`docs/goo/oka-ostre-kvapky-cloud.png`).
- `install-session.sh` záplatu použije a pleamar preloží. Všetky tri záplaty sedia na čistom pleamar 0.2.6.

**Engine:**
- **Vlákno** spája horné časti susedov.
  - Hrúbka 3–14 px podľa blízkosti (`close` = 1 − medzera / 0,9 súčtu polomerov) × nepravidelnosť
    (vlastný šum 0,65–1,35).
  - Konce sa mierne hýbu. Samo sa tvorí a trhá s tokom a hrubne s nadnesením.
- **Voda** medzi susedmi leží pod hladinou (ako „voda pod okrajom“ v Kvapkách) a mláka je menšia. Predtým zaliala
  medzery a trojica bola plná hmota bez ôk.
- Oká teraz vznikajú medzi TimeGoo a hlavou Goobaru, prichádzajú a miznú s dýchaním, s ostrou čiarou
  (`docs/goo/oka-engine-cloud.png`).

### Je engine plynulejší, celistvejší a lepší než súčasná plocha Kvapky? O koľko? (merané)

**Meranie:** cloud, headless Sway, 1920×1080, softvérové kreslenie (llvmpipe, CPU). Ten istý pleamar so všetkými
tromi záplatami, rovnaká 18 s cesta kurzora po lište, každé meranie 2×.

| scéna | priemer snímky | p99 (zásek) | čítanie scény (CPU) |
|---|---|---|---|
| Kvapky (súčasná, trojica + hlava, bez okien) | 29–31 ms | 45–48 ms | 1,65 ms |
| engine, rovnaká trojica | **20,9 ms** | **32 ms** | **0,77 ms** |
| engine, 6 kvapiek | 30,3 ms | 43 ms | 0,87 ms |
| engine, 12 kvapiek | 54,1 ms | 93 ms | 0,92 ms |
| engine, 17 kvapiek (celý test) | 73–75 ms | 240–309 ms | 0,94 ms |

**Plynulosť:**
- Pri rovnakom obsahu je engine asi o **30 % rýchlejší** (priemer aj zásek) a logika scény stojí **2× menej CPU**.
- **Náklad však rastie s počtom kvapiek lineárne, asi 3,5–4 ms na kvapku.** Všetky kvapky sú v jednom goo tele
  a pleamar počíta každý jeho tvar pre každý pixel celého obdĺžnika, ktorý telo zaberá (pri kvapkách po celej
  šírke takmer celý pás). Pre Goobar s 50+ oknami ako hroznom je to zásadné.
- Súčasná plocha má rovnaký princíp (48 guľôčok okien v jednom tele), len sa to v cloude bez okien neprejaví.
- Na RX 640 (GPU) budú čísla oveľa nižšie, ale pomer ostane.

**Celistvosť (kód):**
- TimeGoo, PowerGoo a hlava sú v engine 3 súbory, spolu 32 riadkov.
- Jadro enginu má 315 riadkov scény (bez generovaných tvarov) a 647 riadkov logiky a generátora; platí pre všetky
  kvapky (128 miest).
- V Kvapkách má každá kvapka vlastné pravidlá rozložené v scéne (~2 900 riadkov) a v 8 generátoroch. Porovnanie
  celkového počtu riadkov nie je férové (Kvapky majú aj spúšťač, okná, upozornenia), preto ho neuvádzam ako číslo.

**Správanie a vzhľad:**
- Engine má navyše:
  - vlnky, vietor, jadro (upozornenia), ponor (Marea), nadnesenie ku kurzoru;
  - nečinnosť s hrou, pravidlá 8 a 17–21, používateľské kvapky z JSON.
- V Kvapkách je to, čo engine ešte nemá:
  - Goobar so strapcom okien, spúšťač, okná z kvapiek (pravidlá 9, 14);
  - kvapôčka tečúca po vlákne.
- Vzhľad spájania je blízko pôvodného, ale nie 1:1 (posúdiť naživo).

**Záver:** pri rovnakom obsahu áno, o ~30 % plynulejší a celistvejší. Pri mnohých kvapkách zatiaľ nie. Treba
**ostrovy**: susedné kvapky (skupina podľa susedov, ktorú už logika počíta) v samostatnom tele, aby sa každý pixel
počítal iba s tvarmi svojej skupiny. Odhad: náklad prestane rásť s celkovým počtom kvapiek a bude závisieť od
veľkosti najväčšej skupiny (strapec okien jednej aplikácie). Pri 17 kvapkách v 4–5 skupinách zhruba 73 → 25–30 ms.
Je to iba v jazyku, bez ďalšej záplaty. Neurobené, čaká na súhlas.

### Goobar a ostatné kvapky v engine; kto kreslí vyskakovacie okná

**Zadanie:**
- Vytvoriť v engine Goobar: okná toho istého programu sa zhlukujú ako ikry.
- Bol problém s tým, ako Hyprland / systém pomenúva okná — pozrieť pôvodnú verziu a preniesť.
- Preniesť schopnosti ostatných Goo.
- Kto kreslí obsah vyskakovacích okien?

**Pomenovanie okien (z `kvapka.luau`):**
- Služba `window` pleamar (wlr-foreign-toplevel) dá iba triedu (app_id), titulok a vlastné id — **bez adresy
  Hyprlandu**.
- Skupina strapca a ikona sa preto hľadajú v spúšťačoch (služba `apps`): podľa StartupWMClass, id spúšťača,
  **koncovky id** (Flatpak: trieda „firefox“ ↔ id „org.mozilla.firefox“), mena.
- **Všetky aplikácie LatteOS (Quickshell) majú triedu `org.quickshell`** → skupina podľa titulku („Súbory — LatteOS“
  = Name spúšťača); riešením je vlastné `app_id` (ROADMAP).
- Okno sa v Hyprlande hľadá podľa triedy, titulku a poradia (`nth_of`), lebo terminály majú rovnaké titulky.
- Engine to robí rovnako (`lib/goobar.luau`).
- Overené v cloude: 3 okná `foot` (trieda „foot“) sa našli cez koncovku id spúšťača `org.codeberg.dnkl.foot`
  a zlepili sa do strapca s ikonou aplikácie. Bublina ukáže „terminál 1 · Foot“. Okná bez spúšťača (weston) dostanú
  znak okna.

**Goobar v engine** (z `layout()` v Kvapkách):
- Každé okno je kvapka enginu (`E.upsert`, bez preskočenia pri zmene) s ikonou aplikácie.
- Ikry: posuny OFFS/JIT, čím viac okien, tým menšie (do 72 %). Myš nad strapcom ho rozvinie do radu, po 0,5 s sa zbalí.
- Aktívne okno je plnšie, minimalizované (plocha `special:minimized`) menšie a stlmené.
- Klik = `latte.win.toggle_by`. Pravý = ponuka okna (Obnoviť, Minimalizovať, Maximalizovať, Rozloženie ›, Navrchu,
  Na plochu ›, Zavrieť).
- Ťahanie = poradie aplikácií. Šnúra sa zmestí po kraj.
- Hlava = režim okien (klik), koliesko = páska / ďalšie okno.
- Nad 96 okien guľôčka „ďalšie okná“ → prehľad.
- Okná sú susedia na lište, takže medzi nimi je voda, vlákna a oká ako pri iných kvapkách.

**Ostatné kvapky:**
- **PowerGoo:** ponuka Goo (Nastavenia, Monitor | Zamknúť, Odhlásiť, Uspať, Reštartovať, Vypnúť) + batéria guľkami.
- **QueenGoo:** guľky zariadenia (červená) / sieť (zelená) / aktualizácie (modrá), ľavý = App Manager (pri
  aktualizáciách na nich), pravý = Správca zariadení, okno vedľa kráľovnej.
- **DaNoGoo:** dátum, guľky upozornení (systémové červeno-kávové, ostatné žlté, počet), nové upozornenie zvlní
  hladinu, klik = zoznam v ponuke + „Vymazať všetko“.
- **TimeGoo:** čas a dátum, klik = spúšťač LatteOS, pravý = nastavenia času / pohoda.
- **Spoločné:** ponuka Goo (karta z kávy pri mieste kliku, ucho, podponuky), guľky s vlastnou farbou každej,
  ikona aplikácie, slovenské preklady.
- Chyba štartu jednej kvapky už nezhodí ostatné (pcall).

**Zatiaľ iba v Kvapkách:**
- spúšťač Goo (veľký: hľadanie, AI, súbory…), časové menu (stopky, minútka, budíky);
- karta kalendára a počasia, hrozno upozornení na vlákne;
- let bubliny k oknu (pravidlo 14), okná nad lištou (strapec sa stiahne pod okno).

**Kto kreslí vyskakovacie okná (v Kvapkách aj v engine):**
- **pleamar (naša scéna):** všetko Goo — spúšťač, časové menu, kalendár, ponuka vypínača, kontextové ponuky,
  hrozno upozornení, bublina, z ktorej vyrastie okno. Je to vrstva (layer-shell) celej obrazovky; Hyprland ju iba
  zloží s ostatným.
- **Noctalia (Quickshell):** ovládacie centrum a jeho panely (zvuk, sieť, Bluetooth, batéria), OSD, zámok, rohová
  lišta.
- **Hyprland:** riadne okná — App Manager, Nastavenia, Monitor, Správca zariadení, Súbory (aplikácie Quickshell
  v samostatných procesoch). Hyprland ich umiestni (`latte-kvapky okno`), animuje a dá im sklo (Hyprglass).

**Snímky:** `docs/goo/engine-lista-cloud.png`, `engine-ponuka-powergoo-cloud.png`, `engine-goobar-strapec-cloud.png`.

### Goobar: ikry sa lepia iba ku Goobaru a uhýbajú oknám

**Zadanie (spresnenie):** Goobar s otvorenými oknami vyzerá v pôvodnej verzii inak.
- Ikry jednotlivých okien sa nemajú zamieňať s ostatnými kvapkami: sú menšie a lepia sa iba ku Goobaru.
- Okná tej istej aplikácie sa zhlukujú do hroznových strapcov.
- Keď by zavadzali otvorenému oknu Hyprlandu nad sebou, uhýbajú k okraju obrazovky.

**Urobené:**
- **Vlastné goo telo Goobaru** (pole `sk`: 0 hlavné, 1 iba Goobar, 2 obe). Ikry sa zlievajú iba s hlavou Goobaru
  a navzájom. Hlava je v oboch telách, takže sa spája aj s TimeGoo.
- Susedia (vlákna, voda) sa hľadajú iba v rámci jedného tela.
- **Menšie ikry:** R0 22, pod oknom 17.
- **Bobule namiesto jednej hmoty:** slabšie zliatie (`zliatie` 0,35) a takmer žiadna mláka (`mlaka` 0,15).
- **Uhýbanie oknám** (z `kvapka.luau` › `free_above`):
  - `latte-goo okna` dá obdĺžniky viditeľných okien (Hyprland: aktuálna plocha zameraného monitora, bez
    minimalizovaných; na skúšky Sway);
  - každých 0,7 s sa prepočítajú na úseky pozdĺž okraja od hlavy;
  - ak nad strapcom nie je voľno na jeho výšku (+ 56 px, hysteréza 16 px), uhne k okraju do menšieho cik-cak radu
    a nenadnáša sa;
  - keď okno odíde, znova sa zhlukne.
- **Výkon:** druhé telo stálo v cloude 17 ms, lebo pás pri okraji ho roztiahol cez celú šírku. Bez pásu
  (okraj robia mláky) stojí ~4 ms.

**Overené v cloude** (Sway, plávajúce okná na známych miestach): okno siaha k lište nad Goobarom → strapec 3 okien
`foot` uhne k okraju; okno sa odsunie → zhlukne sa do hrozna.

**Porovnanie** (`docs/goo/goobar-porovnanie-cloud.png`): pôvodná plocha v cloude neuhne, lebo okná nad lištou
zisťuje iba cez Hyprland; tvar ikier je podobný.

### Pravidlo 22: kvapky sa nikdy úplne neprekryjú

**Zadanie:**
- Hlava Goobaru sa s inými goo spája — áno, v engine je v oboch goo telách (spája sa s TimeGoo), ikry okien iba s ňou.
- Nové pravidlo: goo sa nemôžu úplne prekrývať; vždy sa jedno odsunie od druhého, napr. keď ťahaním pustím jedno
  na druhé.

**Urobené (`lib/engine.luau` › `separate`):**
- Stredy dvoch kvapiek, ktoré sa môžu stretnúť (to isté goo telo), ostanú aspoň 0,72 súčtu polomerov od seba.
  Zlievajú sa, ale neprekryjú.
- Kontrola po pustení, pridaní kvapky, zmene veľkosti a zmene okien Goobaru.
- Ustúpi posunuteľná kvapka: kvapka na lište pozdĺž lišty, voľná smerom od druhej; pri okraji obrazovky na druhú
  stranu. Okná Goobaru (rozloženie) a pripnuté kvapky (TimeGoo, PowerGoo) neustúpia. Z dvoch posunuteľných ustúpi
  tá, na ktorú niečo pustili.
- Odsúvanie sa reťazí (do 10 kôl), odsunutá sa zachveje, nové polohy sa uložia.

**Overené v cloude:** Zvedavka pustená presne na Počítadlo ostala, kde ju pustili (x 0,17). Počítadlo plynule
odplávalo (331 → 369 px) a reťazovo sa odsunuli aj Pošta a Ťažká (`latte-goo stav`). Snímka:
`docs/goo/neprekryvanie-cloud.png`.

### Nápad: hra pre Linux na engine Goo

**Otázka:** dal by sa engine (fyzikou podobný World of Goo, zámerne) použiť ako základ linuxovej hry? Niečo
jednoduché, ale návykovo zábavné.

**Odpoveď:** áno, ale na určitý typ hier.
- **Engine vie:** goo vzhľad (zlievanie, mostíky, oká, svetlo, jadro, vlnky, ponor), pružiny s odrazom, nadnesenie,
  lepivosť a odtrhnutie, gravitáciu kurzora, odsúvanie, ovládanie myšou, logiku v Luau, 128 kvapiek, 60 fps na GPU.
- **Nevie:** skutočnú fyziku sietí guličiek na pružinách s váhou (World of Goo). Pleamar animuje vlastnosti k cieľom
  a logika nebeží každý snímok. Stavebnica mostov by potrebovala fyziku v Ruste alebo iný engine (Godot) s prenesením
  vzhľadu goo.

**Nápady (od najjednoduchšieho):**
1. **Chyť kvapku** (whack-a-goo): kvapky sa vynárajú z hladiny, klikni skôr, než sa ponoria. Jadro určuje body
   (zlatá bonus, červená neklikať). Vlnky, kombá, zrýchľovanie. Takmer všetko už v engine je; môže byť aj easter egg
   Goo pri nečinnosti.
2. **Latte Merge** (ako Suika): kvapky padajú do šálky, rovnaké sa zlejú do väčšej (espresso → cortado → cappuccino →
   latte), prehráš, keď pretečie. Zlievanie je to, čo pleamar kreslí najlepšie. Treba jednoduchú fyziku kruhov
   v Luau (~30 Hz), plynulosť overiť.
3. **Pastier kvapiek** (ako Lemmings): kurzor priťahuje kvapky (už je), preveď ich cez prekážky do šálky.
4. **Odtrhni** (prak): natiahni kvapku od hladiny a pusti; let po oblúku na cieľ, dopad = vlnky.
5. **Stavebnica ako World of Goo:** iba s fyzikou v Ruste alebo v inom engine. Mechanika áno, meno a vzhľad World of
   Goo nie.

**Odporúčanie:** najprv 1 ako ukážku (takmer zadarmo), potom 2 ako skutočnú malú hru (Flatpak, Hry LatteOS); ak Luau
neutiahne plynulosť, malá fyzikálna služba v Ruste. Pleamar je BSD-3 (hra je v poriadku); gamepad pleamar zatiaľ
nevie. Čaká na rozhodnutie používateľa.

### Report o engine pre novú session

**Požiadavka:** „Nie. Len priprav o celom engine čo si spravil, report pre novú session na Claude Code.“

**Odpoveď:** report je v `docs/goo/ENGINE-REPORT.md` a obsahuje:
- pravidlá spolupráce;
- mapu súborov a záplaty pleamaru;
- ako funguje scéna `goo.plm` a API `lib/engine.luau`;
- Goobar a prenesené kvapky;
- príkazy `latte-goo`;
- pasce jazyka;
- postup testovania v cloude a merania;
- čo je a čo nie je overené, otvorené úlohy a zoznam commitov.

Nová session ho má prečítať ako prvý, spolu s `LATTEOS-GOO.md` a `session/goo/README.md`.

**Upresnenie od používateľa:** „Nemyslel som hry, tu nespomínaj. Myslel som engine pre shell.“
Z reportu som odstránil zmienku o hre. Report opisuje iba engine Goo ako základ shellu LatteOS. Ostala v ňom iba
naháňačka kvapiek pri nečinnosti (úroveň 3), lebo je to funkcia shellu.
