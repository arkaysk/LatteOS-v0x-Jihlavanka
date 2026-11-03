# Inštalátor LatteOS — plán a zoznam súčastí

Rozvrh grafického inštalátora pre alpha vydanie (používateľ 3. 11. 2026). Nadväzuje na ROADMAP 2.03 (sprievodca, kroky
Fedory sivé), 2.05 (AI áno/nie), 2.06 (kompaktný inštalátor pre alpha) a 14.20 (verejné alpha). Zdroj súčastí: oddiel
`[needs]` v `FILES` — tento súpis sa z neho skladá a s ním sa aj mení.

## 1. Cesta človeka

1. Nainštaluje **Fedoru 45 Server** (oficiálne vydanú) z jej vlastného inštalátora: jazyk, disky, sieť, účet — to
   všetko robí Fedora.
2. Prihlási sa v textovej konzole a spustí **jeden príkaz** LatteOS (podoba v časti 4).
3. Príkaz doinštaluje minimum na grafiku a otvorí **sprievodcu na celej obrazovke**, ovládaného myšou.
4. Sprievodca ukáže všetky kroky ako pri samostatnej inštalácii. Tie, ktoré už spravila Fedora (jazyk systému, disky,
   sieť, účet), sú **sivé s fajkou a krátkym „urobila Fedora“** — vidno, čo sa stalo, ale nemenia sa. Aktívne sú kroky
   LatteOS.
5. Na konci **inštalácia so zoznamom krokov a posuvníkom 0–100 %**; potom reštart do LatteOS.

## 2. Kroky sprievodcu

| Krok | Stav | Čo sa volí |
|---|---|---|
| Vitaj | aktívny | jazyk sprievodcu (sk, en…), čo LatteOS je, stav alpha, podporovaný hardvér |
| Jazyk a klávesnica systému | sivý (Fedora) | — (zmena neskôr v Nastaveniach) |
| Disky a oddiely | sivý (Fedora) | — ukáže, čo Fedora vytvorila (`/boot`, `/`, `/data`, ak je) |
| Sieť | sivý (Fedora) | — iba stav pripojenia; bez internetu ďalej nejde |
| Účet | sivý (Fedora) | — ukáže používateľov, pre ktorých sa LatteOS nastaví |
| Kontrola počítača | aktívny | grafická karta, RAM, miesto, Secure Boot; čo z toho vyplýva (kernel, Mesa, stupeň výkonu) |
| AI | aktívny | generatívna AI áno / nie (2.05); s ňou lokálny model podľa karty a RAM |
| Súčasti | aktívny | voliteľné balíky po skupinách (časť 3, stĺpec „voliteľné“), predvolene zaškrtnuté odporúčané |
| Vzhľad | aktívny | káva a šálka (odtieň), tapeta |
| Zhrnutie | aktívny | čo sa nainštaluje, odkiaľ (Fedora, COPR, zostavené zo zdroja, Koji), koľko miesta a času |
| Inštalácia | aktívny | zoznam krokov (hotové ✓, práve beží, čaká) + posuvník 0–100 % + podrobný záznam na rozbalenie |
| Hotovo | aktívny | reštart; pri chybe zrozumiteľná správa, záznam a „skúsiť znova“ |

## 3. Čo sa inštaluje

### 3.1 Z repozitárov Fedory (vždy)

- **Relácia a prihlasovanie:** greetd, labwc (relácia SAFE), tuigreet, plymouth (+ two-step, spinner), egl-utils,
  python3, python3-pillow, wireplumber, pulseaudio-utils, libnotify, swaybg, hypridle, wlopm.
- **Aplikácie LatteOS:** quickshell, qt6-qtdeclarative, xdg-desktop-portal-gtk, flatpak (obchod Flathub).
- **Písma a systém:** rsms-inter-fonts, jetbrains-mono-fonts, policycoreutils-python-utils, util-linux-core.
- **Záchrana (SAFE):** foot, less, NetworkManager-tui.
- **Sieť a súbory:** nftables, iproute, fd-find, xdg-utils, xdg-user-dirs.
- **Kalendáre:** evolution-data-server, gnome-online-accounts(-gtk), evolution-ews-core, python3-holidays.
- **Barista (programy Windows):** wine, winetricks, cabextract, unshield, innoextract, 7zip, icoutils, bubblewrap.

### 3.2 Voliteľné (krok „Súčasti“)

| Skupina | Balíky | Predvolene |
|---|---|---|
| Hry | steam, gamescope, gamescope-session(-steam); umu-launcher, protontricks, lutris, gamemode, mangohud, dosbox-staging; wine-dxvk(-d3d8/-d3d9), wine-gecko, wine-mono | áno, ak je karta s Vulkanom |
| AI na tomto počítači | llama.cpp (Vulkan) a model Qwen3.5 2B/4B podľa karty a RAM; whisper.cpp a model reči | iba ak AI = áno |
| Nástroje AI služieb | mise (Claude Code, Codex, Gemini, Grok, Copilot, Vibe, DeepSeek Harness), gnome-keyring, pipewire-utils | iba ak AI = áno |
| Schránka a hľadanie | cliphist, wl-clipboard, zbar, tesseract (+ sk, en), qalculate | áno |
| Emoji a symboly | unicode-emoji, cldr-emoji-annotation, python3-gobject, python3-cairo, Noto Color Emoji, Noto Sans Symbols 2 | áno |
| Súbory (DualBrew) | archivemount, ffmpegthumbnailer, poppler-utils, exiv2, ImageMagick, bsdtar | áno |
| Tapety | mpvpaper (video), ffmpeg(-free), skwd-wall (COPR) | áno, skwd-wall nie |
| Obrazovka | brightnessctl, power-profiles-daemon, gammastep (nočné svetlo), yaru-icon-theme | áno |
| Záchrana | whyd (rpm z jeho vydaní: prečo skončila relácia) | áno |
| Vzdialený prístup | Sunshine (COPR lizardbyte/stable) | nie |

### 3.3 Zostavené zo zdroja (inštalátor ich zostaví sám)

| Súčasť | Verzia | Záplaty | Čas na zostavenie (odhad) |
|---|---|---|---|
| pleamar | 0.7.10 (`94ac94c`) | `patches/pleamar-*.patch` | ~10 min |
| pleamar-wm | 0.6.9 (`42c8fee`) | `patches/pleamar-wm-*.patch` | ~10 min |
| Quickshell s webovým enginom (iba LensAI) | 0.3.2 (`9b0f339`) | `patches/quickshell-webengine.patch` | ~10 min |
| programy LatteOS v Ruste (`crates/`) | z repa | — | ~2 min |

Potrebné na zostavenie (odinštalujú sa po ňom, ak ich človek nemal): cargo/rust, cmake, ninja-build, gcc-c++,
vývojové balíky Qt 6 a Waylandu (zoznam v `FILES`, riadok s qt6-qtwebengine).

### 3.4 Mimo Fedory — podmienené

| Súčasť | Odkiaľ | Kedy | Pozor |
|---|---|---|---|
| **Linux 7.3** | Koji (Fedora) | iba karty AMD GFX6–GFX8 (napr. RX 640) a iba kým Fedora 45 nemá 7.3 v aktualizáciách | z Koji je **nepodpísaný** → pri zapnutom Secure Boot sa nespustí; sprievodca to povie a ponúkne vynechanie |
| **Mesa 26.3** | dnes rc v `/opt/mesa-26.3` | tie isté karty, kým ju Fedora nemá | samostatný priečinok, nemení systémovú Mesu |
| Quickshell 0.3 | COPR `lionheartp/Hyprland` (dnes) | kým Fedora má iba 0.2.1 | cudzí COPR; cieľ: vlastná zostava ako pri LensAI |

Keď Fedora 45 dostane Linux 7.3 a Mesu 26.3 v bežných aktualizáciách, riadky 3.4 odpadnú (1D.16) — sprievodca to
zisťuje sám (`dnf` verzia v repozitári), nič sa nepíše natvrdo.

## 3.5 Ako dlho to trvá (odhad 3. 11., PC ako latte-lab, rýchly internet)

| Časť | Čas | Z čoho |
|---|---|---|
| Balíky Fedory (základ) | 5–8 min | sťahovanie a inštalácia, podľa siete |
| Rust a nástroje na zostavenie | 1–2 min | |
| pleamar + pleamar-wm | ~12,5 min | zmerané 3. 11. na latte-lab |
| Quickshell pre LensAI | ~5 min | zmerané 3. 11. na latte-lab |
| Súbory a nastavenie systému | 1–2 min | |
| **Spolu základ** | **~25–35 min** | |
| + Hry (Steam, Wine, DXVK…) | +5–10 min | |
| + Lokálna AI (model 2–4 GB) | +3–10 min | podľa siete |
| + Linux 7.3 a Mesa (iba GFX6–8) | +3–5 min | |

Na slabšom PC (4 jadrá) sa zostavovanie zhruba zdvojnásobí. Keď bude obraz Universal Blue (časť 6), zostavovanie
odpadne úplne: inštalácia ~5–10 min.

**Vlastný COPR (hotové balíky namiesto zostavovania u človeka): zatiaľ nie** (používateľ 3. 11.) — prednosť má
Linux 7.3 a Mesa 26.3 hneď pri inštalácii. Pred neskorším COPR: nahradiť `goo/shaders/sea.wgsl` (CC BY-NC-SA nie je
slobodná licencia, do COPR nesmie) a založiť ho iba na pokyn (je verejný).

## 3.6 Obrazovka inštalácie (používateľ 3. 11.)

- **Posuvník v štýle grafov LatteOS:** rad segmentov ako `DotBar` (`apps/common/DotBar.qml`), **zlatý** (rozhodnuté
  3. 11.); červená iba pri chybe. (`Theme.heat` ostáva grafom záťaže a aktivity, napr. commity na Gite.)
- **Pohyblivá kávová hladina** dole v okne sprievodcu, tá istá ako v oknách aplikácií (`apps/common/Surface.qml`):
  človek vidí prostredie LatteOS ešte pred jeho inštaláciou (používateľ 3. 11.). Sprievodca je postavený na
  `AppWindow` a `apps/common`, nie na vlastnom vzhľade.
- **Prezentácia súčastí LatteOS vedľa**, kým sa inštaluje (inštalácia je dlhá): obrázok a dve vety o jednej súčasti,
  po chvíli ďalšia — Goo a kvapky, LensAI, Barista (programy Windows), DualBrew, herná relácia, režimy okien,
  SAFE a GuardDog. Vľavo zoznam krokov, vpravo prezentácia, dole posuvník a čas, ktorý ostáva.

## 4. Technika

- **Príkaz:** `curl -fsSL <adresa>/get | sudo bash` (adresa po zverejnení, iba na pokyn). Skript: skontroluje
  Fedoru 45, sieť a `sudo`; nainštaluje `git cage quickshell`; stiahne LatteOS do `/opt/latteos/src` a spustí
  sprievodcu.
- **Grafika bez pracovného prostredia:** `cage` (kioskový správca okien z Fedory) priamo z textovej konzoly, v ňom
  sprievodca v Quickshelli na celej obrazovke. Vzhľad z `apps/common` (Theme, I18n, preklady), takže je to už LatteOS.
- **Postup a posuvník:** `./install --go --progress` vypisuje strojové riadky (`step 3/27 Zostavuje sa pleamar`,
  `percent 41`, `log …`); sprievodca z nich kreslí zoznam a posuvník. Váhy krokov podľa trvania (zostavovanie ťažšie
  ako kopírovanie súborov).
- **Bezpečnosť:** nič sa nemení pred „Inštalovať“ v Zhrnutí; pred začiatkom snímka snapper, ak je Btrfs; každý krok
  má návrat (`./install --remove`); záznam do `/var/log/latteos-install.log`.
- **Rozhodnuté (používateľ 3. 11.):** sprievodca beží na tom, čo ponúka hotová Fedora — Quickshell 0.2.1 z jej
  repozitára (nič cudzie ani zostavované pred grafikou); sprievodca sa píše tak, aby na ňom bežal.

## 5. Postup prác

1. ~~`install --progress`~~ (hotové 3. 11.: `@step N/M text`, `@percent P`, kontrola v `tests/check.sh`) a
   ~~zostavenie pleamaru a pleamar-wm inštalátorom~~ (hotové 3. 11.: `patches/build-pleamar.sh`, zamknuté na celé
   commity a `cargo --locked`; na latte-lab 12,5 min). Chýbajúce balíky Fedory
   doinštaluje sám (hotové 3. 11.: `dnf install -y`, časť posuvníka; `--with "…"` = voliteľné, ktoré vybral sprievodca).
   Ostrá skúška `dnf` až na čistej Fedore (na latte-lab nič povinné nechýba).
2. Skript `get` a spustenie `cage` + Quickshell na čistej Fedore 45 Server vo VM.
3. Sprievodca: obrazovky z časti 2, najprv Vitaj → Súčasti → Zhrnutie → Inštalácia.
4. Kontrola počítača (karta, Secure Boot, kernel/Mesa) a podmienené kroky 3.4.
5. Skúška od nuly vo VM, potom na latte-lab (čistá Fedora 45 Server).

## 6. Neskôr: Atomic, všetko v jednom obraze (používateľ 3. 11.)

Ďalšia etapa: **jeden obraz** (Fedora Atomic, obraz `bootc`; rozhodnuté 3. 11.: na základe **Universal Blue**
(`ublue-os`), ako Bazzite a Bluefin — ich základný obraz a šablóna vlastného obrazu `image-template`) s LatteOS, pleamarom, pleamar-wm, Quickshellom a
podmieneným kernelom a Mesou už v ňom — nič sa nezostavuje u človeka. Vtedy **sivé kroky prevezme náš sprievodca**:
jazyk a klávesnica, disky a oddiely (vrátane `/data` a domovských priečinkov z 2.03), sieť a účet budú aktívne
obrazovky LatteOS. Preto sa sprievodca stavia už teraz tak, aby každý krok mal obe podoby: „urobila Fedora“ (sivá,
iba ukáže stav) a vlastnú (aktívna); prepína ich jediný príznak podľa toho, či beží nad hotovou Fedorou, alebo
z obrazu LatteOS. Zostavovanie zo zdroja (3.3) sa vtedy presunie do výroby obrazu, `install --progress` ostáva.
