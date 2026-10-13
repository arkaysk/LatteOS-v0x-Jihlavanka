# Súčasti tretích strán

Vlastný kód a obsah LatteOS (vrátane tapiet v `assets/wallpapers/`) je pod licenciou MIT — pozri [LICENSE](LICENSE).
LatteOS stojí na cudzích projektoch. Ich zdrojový kód v tomto repozitári nie je; sťahuje ho `resources/fetch.sh`
a inštalátor ich prekladá alebo inštaluje z balíkov. V repozitári sú iba naše záplaty k nim (`resources/patches/`)
— tie sa riadia licenciou projektu, ktorý menia.

| Projekt | Na čo ho LatteOS používa | Licencia |
|---|---|---|
| [pleamar](https://github.com/k4ditano/pleamar) (k4ditano) | kreslenie kvapiek a kariet Goo, jazyk scén `.plm`, logika v Luau | BSD-3-Clause |
| [Hyprland](https://github.com/hyprwm/Hyprland) a [hyprland-plugins](https://github.com/hyprwm/hyprland-plugins) (hyprbars) | kompozitor okien, tlačidlá okien | BSD-3-Clause |
| [Hyprglass](https://github.com/hyprnux/hyprglass) | sklo okien | BSD-3-Clause |
| [whyd](https://github.com/vmaltarello/whyd) | voliteľný samostatný program: prečo sa skončila minulá relácia (SAFE); LatteOS prikladá iba vlastné pravidlá `system/whyd/latteos.toml` | GPL-3.0-or-later |
| [Noctalia](https://github.com/noctalia-dev/noctalia-shell) | rohová lišta, ovládacie centrum, OSD | MIT |
| [Quickshell](https://github.com/quickshell-mirror/quickshell) | beh aplikácií LatteOS (QML) | LGPL-3.0 |
| [labwc](https://github.com/labwc/labwc) | režim SAFE a prihlasovacia obrazovka | GPL-2.0 |
| [Tabler Icons](https://github.com/tabler/tabler-icons) | ikony (písmo z Noctalie) | MIT |

Priložené súbory s vlastnou licenciou:

| Súbor | Pôvod | Licencia |
|---|---|---|
| `assets/fonts/tabler-icons.ttf` | Tabler Icons, písmo ikon 3.34.1 (vetva `v0.4-fresh`) | MIT (`assets/fonts/LICENSE-tabler-icons.txt`) |
| `session/fonts/Manrope[wght].ttf` | Manrope | SIL OFL 1.1 (`session/fonts/OFL-Manrope.txt`) |
| `session/fonts/Fraunces[…].ttf` | Fraunces | SIL OFL 1.1 (`session/fonts/OFL-Fraunces.txt`) |
| `session/kvapky/textury/hlinik_*.webp`, `striebro_*.webp` | ambientCG Metal009, Metal010 | CC0 1.0 (`session/kvapky/textury/LICENCIA.txt`) |

Prekladová vrstva aplikácií (`session/apps/common/I18n.qml`) je napísaná podľa vzoru
[DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) (MIT).
