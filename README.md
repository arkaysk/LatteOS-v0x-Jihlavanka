# LatteOS — gamerdistro (nový štart)

23. 9. 2026 · @Arkay

Čistá vrstva. Vývoj LatteOS začína odznova.

## Štruktúra

| Zložka   | Obsah |
|----------|-------|
| `inspo/` | inšpirácia a aktuálna predstava: technologický radar, návrh plochy, obrázky, videá |
| `resources/` | prebraté projekty z radaru (`fetch.sh`), naše patche, [MANIFEST](resources/MANIFEST.md) |
| `crates/` | Rust: `latte-hw` (detekcia HW/grafiky), `latte-boot` (výber režimu NORMAL/SAFE, počítadlo pádov) |
| `session/` | štart a relácie: `latte-session`, `latte-greeter`, `latte-safe`, Hyprland/labwc konfigurácia, systemd, GRUB SAFE, Plymouth |
| `setup/` | inštalácia a testy na VM: `f0-install.sh`, `f1/install-session.sh`, merania `f1/RESULTS.md`; reálne PC latte-lab: [`lab/`](setup/lab/README.md) |
| `old/`   | celý predchádzajúci stav repa, len na čítanie; **už sa doň nezapisuje** |

Plán vývoja je v [ROADMAP.md](ROADMAP.md). Nový kód a dáta vznikajú iba mimo `old/`.

## Platforma — fáza 1 (teraz)

- **Základ:** klasický **Fedora Server 44** (dnf, nie atomic)
- **Beh:** virtuálny stroj — Oracle VirtualBox / iný hypervízor
- **Grafika:** **iba softvérové vykresľovanie**, bez 3D akcelerácie
  (Mesa llvmpipe / pixman renderer; žiadne predpoklady na Vulkan/GL HW)

Všetko, čo sa teraz napíše, musí bežať vo VM bez GPU.

## Ďalšie fázy (neskôr)

1. **Fedora Atomic** — prechod z klasického servera na image-based
   (rpm-ostree / bootc, štýl Bazzite / Universal Blue).
2. **Reálny hardvér s 3D grafikou** — keď bude pripravený stroj,
   postupne sa zapne HW akcelerácia: **AMD (ATI)** aj **NVIDIA**.
