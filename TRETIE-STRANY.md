# Súčasti tretích strán

Vlastný kód a obsah LatteOS (vrátane tapiet v `assets/wallpapers/`) je pod licenciou MIT — pozri [LICENSE](LICENSE).
LatteOS stojí na cudzích projektoch. Ich zdrojový kód v tomto repozitári nie je; sťahuje ho `resources/fetch.sh`
a inštalátor ich prekladá alebo inštaluje z balíkov. V repozitári sú iba naše záplaty k nim (`resources/patches/`)
— tie sa riadia licenciou projektu, ktorý menia.

| Projekt | Na čo ho LatteOS používa | Licencia |
|---|---|---|
| [pleamar](https://github.com/k4ditano/pleamar) (k4ditano) | kreslenie kvapiek a kariet Goo, jazyk scén `.plm`, logika v Luau | BSD-3-Clause |
| [K4](https://github.com/k4ditano/k4) (k4ditano) | predloha ostrova LensShore (`apps/lensshore.qml`): ostrov, ktorý v pokoji leží pri okraji a pri písaní pruží von, jeho rozbaľovanie a podoba spúšťača | MIT |
| [hypridle](https://github.com/hyprwm/hypridle) | zamknutie a zhasnutie obrazoviek pri nečinnosti | BSD-3-Clause |
| [pleamar-wm](https://github.com/k4ditano/pleamar-wm) (k4ditano) | správca okien; `system/pleamarwm/wm/` je upravená kópia jeho scény | BSD-3-Clause |
| [Vitreus](https://github.com/natepayn3/Vitreus) (natepayn3) | vlna po okraji karty Goo pri otváraní podľa jeho `cardrip.wgsl` (dva hrebene bežia po okraji a doznejú); prenesené správanie, kreslené tvarmi tela karty (`goo/parts/card.plm`, `cardframe.plm`) | MIT |
| [Marea](https://github.com/k4ditano/marea-plm) (k4ditano) | spoločník plochy (guľa s tvárou); celá, bez zmien, v `/usr/share/latteos/marea-plm/`, zapína sa v Nastaveniach › Kvapky › Marea (`bin/latte-marea`) | BSD-3-Clause |
| [skwd-wall](https://github.com/liixini/skwd-wall) | voliteľný samostatný program: výber a kreslenie tapety, prechody, paleta z tapety; LatteOS ho iba volá (`bin/latte-wall`) | GPL-3.0 |
| [whyd](https://github.com/vmaltarello/whyd) | voliteľný samostatný program: prečo sa skončila minulá relácia (SAFE); LatteOS prikladá iba vlastné pravidlá `system/whyd/latteos.toml` | GPL-3.0-or-later |
| [Noctalia](https://github.com/noctalia-dev/noctalia-shell) | rohová lišta, ovládacie centrum, OSD | MIT |
| [Chaldea](https://github.com/Aleph1-9012/Chaldea) | widgety v `apps/widgets/`: vyexportované QML (`frontend/scripts/export.ts`), licencia a poznámky pri každom | widgety 0BSD, písma SIL OFL, aplikácia Apache-2.0 |
| [Quickshell](https://github.com/quickshell-mirror/quickshell) | beh aplikácií LatteOS (QML) | LGPL-3.0 |
| [labwc](https://github.com/labwc/labwc) | režim SAFE a prihlasovacia obrazovka | GPL-2.0 |
| [Tabler Icons](https://github.com/tabler/tabler-icons) | ikony (písmo z Noctalie) | MIT |
| [Lobe Icons](https://github.com/lobehub/lobe-icons) | logá služieb AI v LensGoo a LensAI | MIT |
| [Loaf](https://github.com/m-uvex/loaf-fm) (Musa Murad a prispievatelia) | súvislé zvýraznenie výberu v mriežke DualBrew (`apps/files.qml`, `chosenShape`): prenesený `selectionCanvas` z `qml/FilePane.qml` | MIT |
| [Google Sans Flex](https://fonts.google.com/specimen/Google+Sans+Flex) | písmo pozdravu Gemini | OFL 1.1 |
| [Lora](https://fonts.google.com/specimen/Lora) | písmo pozdravu Claude | OFL 1.1 |

Priložené súbory s vlastnou licenciou:

| Súbor | Pôvod | Licencia |
|---|---|---|
| `assets/fonts/tabler-icons.ttf` | Tabler Icons, písmo ikon 3.34.1 (vetva `v0.4-fresh`) | MIT (`assets/fonts/LICENSE-tabler-icons.txt`) |
| `goo/ai/*.svg` | Lobe Icons, logá služieb AI (vetva `v0.4-fresh`) | MIT (`goo/ai/LICENSE-lobe-icons.txt`) |
| `assets/fonts/GoogleSansFlex.ttf` | Google Sans Flex (vetva `v0.4-fresh`) | OFL 1.1 (`assets/fonts/OFL-GoogleSansFlex.txt`) |
| `assets/fonts/Lora.ttf` | Lora (vetva `v0.4-fresh`) | OFL 1.1 (`assets/fonts/OFL-Lora.txt`) |
| `goo/shaders/sea.wgsl` | [Seascape](https://www.shadertoy.com/view/Ms2SD1) (Alexander Alekseev aka TDM, 2014), prepísaný do WGSL a prefarbený na kávu: hladina v perspektíve na prihlasovaní | CC BY-NC-SA 3.0 (hlavička súboru) |
| `system/sky/stars.tsv` | [Yale Bright Star Catalogue](http://tdc-www.harvard.edu/catalogs/bsc5.html), 5. vydanie (Hoffleit a Warren, NASA ADC), v JSON od [brettonw/YaleBrightStarCatalog](https://github.com/brettonw/YaleBrightStarCatalog) (MIT): hviezdy do 4,5 mag na prihlasovaní | voľné údaje NASA ADC; prevod MIT |
| `session/fonts/Manrope[wght].ttf` | Manrope | SIL OFL 1.1 (`session/fonts/OFL-Manrope.txt`) |
| `session/fonts/Fraunces[…].ttf` | Fraunces | SIL OFL 1.1 (`session/fonts/OFL-Fraunces.txt`) |
| `session/kvapky/textury/hlinik_*.webp`, `striebro_*.webp` | ambientCG Metal009, Metal010 | CC0 1.0 (`session/kvapky/textury/LICENCIA.txt`) |

Prekladová vrstva aplikácií (`session/apps/common/I18n.qml`) je napísaná podľa vzoru
[DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) (MIT).

Zo [Omarchy](https://github.com/omacom/omarchy) (MIT, © David Heinemeier Hansson) LatteOS preberá a prepisuje časti
vrstvy AI: zisťovanie limitov služieb bez otázky (`bin/latte-ai` › `claude_usage`, `grok_usage`, podľa
`bin/omarchy-agent-usage-claude` a `bin/omarchy-agent-usage-grok`) a ďalej panel agentov, skill pre agentov a pomoc
AI pri pádoch (ROADMAP 16m), panel agentov (stránka Agenti), skill pre agentov (`system/agents/skills/latteos`)
a inštaláciu a aktualizáciu nástrojov služieb AI cez mise (`system/mise/latteos-tools.toml` podľa
`etc/mise/conf.d/omarchy-tools.toml`).

## Kalendár (ROADMAP 10J, 6D) — vzory správania, kód sa neprenáša

Správanie editora udalosti (opakovanie, pripomienky, „táto / všetky“, voľno/obsadené, presun medzi kalendármi, Späť po
zmazaní) sa berie z **GNOME Calendar** (GPL-3.0+) a **Evolution** (LGPL-2.1+), obe nad rovnakým Evolution Data Serverom
ako `bin/latte-cal`; rozloženie editora a pohľadov z **Merkuro Calendar** (KDE, GPL-3.0+) a Agenda s úpravou priamo
v zozname z **Event Calendar** (Zren, plasma-applet-eventcalendar, „GPL“ bez verzie, Plasma 5). Nápady na neskôr
(blokovanie času, čas na cestu, rezervačné odkazy): **Morgen** (uzavretý, iba ako vzor funkcií). Z ničoho z toho sa
nekopíruje zdrojový kód, takže licencia LatteOS sa nemení.

## Meniny (system/namedays.json)

Tabuľka menín všetkých krajín (366 dní × 18 krajín) sa raz stiahla z verejného rozhrania **nameday.abalin.net** (`bin/latte-nameday build`,
pomaly, 1 požiadavka za 1,5 s) a dodáva sa so systémom, aby Kalendár nepotreboval sieť. Údaje o menách sú verejné fakty; zdroj a postup
sú tu, aby sa dala tabuľka obnoviť. Ruská položka sa vynecháva (služba tam vracia iba odkaz).

## Capture (ROADMAP 10O.50), ešte nenapísané

Vzor rozhrania a úprav snímok: **Flameshot** (flameshot-org/flameshot, **GPL-3.0**, C++/Qt Widgets) — preberá sa súbor nástrojov a správanie aj kód, ak treba. **Licencia LatteOS nie je definitívna** (zatiaľ MIT): určí sa po dokončení podľa všetkého integrovaného materiálu tretích strán (používateľ 5. 11.).
Motor snímok a nahrávania: **Marea** (`logic/camera.luau`, BSD-3, už v systéme). Rozpoznanie textu: **Tesseract** (Apache-2.0).

## Chapolera: obrazový model

[*SigLIP 2 Base Patch16 224*](https://huggingface.co/google/siglip2-base-patch16-224)
(`google/siglip2-base-patch16-224`) je predvolený obrazovo-textový model prvého kroku triedenia. Váhy nie sú
súčasťou repozitára; stiahli sa do `/data/ai/models/chapolera/siglip2-base-patch16-224/`
z revízie `75de2d55ec2d0b4efc50b3e9ad70dba96a7b2fa2`. Modelová karta uvádza Apache-2.0.
SHA-256 `model.safetensors`: `612923381c76ec5a9bed335d1c48827e3f2e506ac31b044b63b2031fadee6a0b`.
Rust inferencia používa knižnice Candle (MIT alebo Apache-2.0), Hugging Face Tokenizers (Apache-2.0) a
image-rs (MIT alebo Apache-2.0).

## LatteIndex

Crates `latte-index` a `latte-chapolera` používajú `infer` (MIT) na rozpoznávanie signatúr,
`rusqlite` (MIT; SQLite je public domain) a RustCrypto `sha2` (MIT alebo Apache-2.0) na SHA-256.
Závislosti sa používajú ako Cargo balíky; kód z nich sa nekopíruje do LatteOS. Fallback MIME detekcie LatteIndexu
používa systémový príkaz `file`.

Chapolera volá systémové programy ExifTool (Phil Harvey; GPL-1.0-or-later alebo Artistic-1.0-Perl),
FFmpeg `ffprobe` (v tejto Fedora inštalácii GPLv3+) a Poppler `pdfinfo` (balík uvádza GPL/LGPL/MIT
komponenty). Sú to samostatné systémové procesy; ich zdrojový kód sa do LatteOS nekopíruje ani nelinkuje.
Používajú sa iba na čítanie a ak chýbajú, chyba sa zobrazí v stave extrakcie. Zdroje:
[ExifTool](https://exiftool.org/), [ffprobe / FFmpeg licencie](https://ffmpeg.org/legal.html),
[Poppler](https://poppler.freedesktop.org/). Verzie a licencie konkrétneho balíka sa môžu líšiť medzi
inštaláciami; pri distribúcii sa kontroluje konkrétny Fedora build.

- **Ollama** (MIT, github.com/ollama/ollama) — pravidlo odhadu pamäte modelu z hlavičky GGUF (`llm/memory.go`, `fs/ggml` GraphSize), prenesené do `bin/latte-ai` (`estimate`) ako záloha; presný odhad dáva `llama-fit-params` z llama.cpp (MIT), ktorý sa iba spúšťa.


- **GeoNames** (CC BY 4.0, geonames.org, `cities15000`) — mestá s 15 000 a viac obyvateľmi: mená, skratky (SF, NYC), súradnice, časové pásma; `bin/latte-calc` si z nich raz stiahne súbor `~/.cache/latteos/places.tsv`, takže „time in tokyo“ a „diff Paris“ idú bez siete. Autor: GeoNames, uvádza sa pri Kalkulačke.
- **OurAirports** (public domain, ourairports.com) — kódy IATA letísk pre „time in JFK“, ten istý súbor.
- **Open-Meteo** (CC BY 4.0, open-meteo.com, nekomerčné použitie bez kľúča) — predpoveď pre „weather in …“ v `bin/latte-calc` (rovnako ju už používa `bin/latte-sky`); jediná vec Kalkulačky, ktorá potrebuje sieť.
- **Transitous** (transitous.org, MOTIS; komunitná otvorená smerovacia služba verejnej dopravy, iba open-source a nekomerčné použitie, údaje majú vlastné licencie: transitous.org/sources) — spoje v `bin/latte-calc` („from Bratislava to Vienna“); sieť je potrebná. Podmienky a pokrytie: ROADMAP 6B.49.
