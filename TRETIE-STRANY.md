# Súčasti tretích strán

Vlastný kód a obsah LatteOS (vrátane tapiet v `assets/wallpapers/`) je pod licenciou MIT — pozri [LICENSE](LICENSE).
LatteOS stojí na cudzích projektoch. Ich zdrojový kód v tomto repozitári nie je; sťahuje ho `resources/fetch.sh`
a inštalátor ich prekladá alebo inštaluje z balíkov. V repozitári sú iba naše záplaty k nim (`resources/patches/`)
— tie sa riadia licenciou projektu, ktorý menia.

| Projekt | Na čo ho LatteOS používa | Licencia |
|---|---|---|
| [pleamar](https://github.com/k4ditano/pleamar) (k4ditano) | kreslenie kvapiek a kariet Goo, jazyk scén `.plm`, logika v Luau | BSD-3-Clause |
| [K4](https://github.com/k4ditano/k4) (k4ditano) | predloha ostrova LensShore (`apps/lensshore.qml`): ostrov, ktorý v pokoji leží pri okraji a pri písaní pruží von, jeho rozbaľovanie a podoba spúšťača | MIT |
| [Hyprland](https://github.com/hyprwm/Hyprland) a [hyprland-plugins](https://github.com/hyprwm/hyprland-plugins) (hyprbars) | kompozitor okien, tlačidlá okien | BSD-3-Clause |
| [Hyprglass](https://github.com/hyprnux/hyprglass) | sklo okien | BSD-3-Clause |
| [skwd-wall](https://github.com/liixini/skwd-wall) | voliteľný samostatný program: výber a kreslenie tapety, prechody, paleta z tapety; LatteOS ho iba volá (`bin/latte-wall`) | GPL-3.0 |
| [whyd](https://github.com/vmaltarello/whyd) | voliteľný samostatný program: prečo sa skončila minulá relácia (SAFE); LatteOS prikladá iba vlastné pravidlá `system/whyd/latteos.toml` | GPL-3.0-or-later |
| [Noctalia](https://github.com/noctalia-dev/noctalia-shell) | rohová lišta, ovládacie centrum, OSD | MIT |
| [Quickshell](https://github.com/quickshell-mirror/quickshell) | beh aplikácií LatteOS (QML) | LGPL-3.0 |
| [labwc](https://github.com/labwc/labwc) | režim SAFE a prihlasovacia obrazovka | GPL-2.0 |
| [Tabler Icons](https://github.com/tabler/tabler-icons) | ikony (písmo z Noctalie) | MIT |
| [Lobe Icons](https://github.com/lobehub/lobe-icons) | logá služieb AI v LensGoo a LensAI | MIT |
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
