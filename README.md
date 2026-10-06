# LatteOS GOO

@Arkay · nový štart 23. 9. 2026 · predtým pracovný názov „gamerdistro“ (vetva `gamerdistro` je od 5. 10. 2026 `main`)

**LatteOS GOO** je linuxová plocha pre ľudí zvyknutých na Windows 11, v ktorej lištu, Štart, hodiny a systémové
prvky nahrádzajú **tekuté kávové kvapky** (goo): pružia, lepia sa k okraju obrazovky aj k sebe, žijú vlastným
pohybom a reagujú na kurzor. Všetko sa ovláda myšou.

## Smer vývoja (rozhodnutie 5. 10. 2026)

- **LatteOS GOO je jediná edícia.** Doterajšie „gamerdistro“ sa ním stáva.
- **LatteOS Classic sa ruší.** Nové funkcie sa preň nerobia; jeho kód (relácia „LatteOS“ s lištou Noctalie) zatiaľ
  v repozitári ostáva a bude sa odstraňovať postupne, keď ho GOO nahradí aj ako predvolená a núdzová relácia.
- **Predvolené prihlásenie bude engine Goo.** Prihlasovanie sa ešte prerobí; dovtedy sa engine spúšťa reláciou
  „LatteOS Kvapky – engine test“.
- **Hlavná práca je engine Goo** (`session/goo`): jedny pravidlá pre všetky kvapky nad
  [pleamarom](https://github.com/k4ditano/pleamar) (k4ditano, BSD-3-Clause). Je na ňom ešte veľa práce — stav
  a otvorené úlohy sú v [docs/goo/ENGINE-REPORT.md](docs/goo/ENGINE-REPORT.md).

## Kvapky (Nová architektúra)

| | Kvapka | Čo robí |
|---|---|---|
| jadro | **GooBar** | hlavná lišta a správca okien — okná ako ikry a strapce po aplikáciách |
| jadro | **GooPower** | účet, relácia, napájanie a profil napájania, batéria, Nastavenia, Monitor; pás výkonu (CPU, RAM, GPU, VRAM) |
| jadro | **LensGoo** | univerzálny spúšťač a lupa: aplikácie, súbory, web, terminál, AI; rýchly zoznam aplikácií |
| voliteľná | **QueenGoo** | App Manager a Správca zariadení |
| voliteľná | **ClockGoo** | upozornenia a kalendár; čas, stopky, minútka, budíky, počasie a digitálna pohoda |
| voliteľná | **ChatGoo** | doplnok pre Beeper (plán) |

Kliky jednotlivých kvapiek sú v [LATTEOS-GOO.md §3.5](LATTEOS-GOO.md). Záväzné pravidlá a správanie:
[LATTEOS-GOO.md](LATTEOS-GOO.md) (pred prácou na kvapkách prečítať), prehľad v [docs/goo/](docs/goo/README.md).

## Stav

- **Plocha Kvapky** (relácia „LatteOS Kvapky“, scéna `session/kvapky/kvapka.plm`) — funkčná plocha so spúšťačom,
  časovým menu, kalendárom, upozorneniami a oknami z kvapiek.
- **Engine Goo** (relácia „LatteOS Kvapky – engine test“, `session/goo`) — overený na reálnom PC (Hyprland,
  AMD RX 640, 5. 10.): fyzika, vstupy myšou, GooBar s oknami, kvapky novej architektúry. Okná z kvapiek sú
  prenesené (5.–6. 10.: spúšťač a rýchly zoznam LensGoo, karta GooPower a pás výkonu, upozornenia s kalendárom
  a karta času ClockGoo, bublina QueenGoo); to, čo pribudlo 6. 10., ešte treba overiť naživo.

## Štruktúra

| Zložka   | Obsah |
|----------|-------|
| `inspo/` | inšpirácia a aktuálna predstava: technologický radar, návrh plochy, obrázky, videá |
| `resources/` | prebraté projekty z radaru (`fetch.sh`), naše [záplaty](resources/patches/README.md), EDID, obrázky maskotov |
| `crates/` | Rust: `latte-hw` (detekcia HW/grafiky), `latte-boot` (výber režimu NORMAL/SAFE, počítadlo pádov) |
| `session/goo/` | **engine Goo**: scéna `goo.plm`, logika `lib/engine.luau`, kvapky `kvapky/*.luau` ([README](session/goo/README.md)) |
| `session/kvapky/` | pôvodná scéna plochy Kvapky (`kvapka.plm`), kým ju engine nenahradí |
| `docs/` | dokumentácia: [index](docs/README.md), [pravidlá Goo](docs/goo/PRAVIDLA.md), [kvapky](docs/goo/ROZHRANIE.md), [stav enginu](docs/goo/ENGINE-REPORT.md) |
| `session/` | štart a relácie: `latte-session`, `latte-greeter`, `latte-safe`, Hyprland/labwc konfigurácia, systemd, GRUB SAFE, Plymouth |
| `setup/` | inštalácia a testy na VM: `f0-install.sh`, `f1/install-session.sh`, merania `f1/RESULTS.md`; reálne PC latte-lab: [`lab/`](setup/lab/README.md) |
| `old/`   | celý predchádzajúci stav repa, len na čítanie; **už sa doň nezapisuje** |

**Toto repo je súkromné** (celá história, `inspo/`, `old/`, ROADMAP). Verejná kópia bez nich je
[arkaysk/latteos](https://github.com/arkaysk/latteos): zverejňuje sa príkazom `setup/verejne/zverejnit.sh`
(čo sa vynecháva: `setup/verejne/vynechat.txt`, verejné README: `setup/verejne/README.md`). Naposledy zverejnené
29. 9. 2026 — ešte pred LatteOS GOO; GOO sa zatiaľ nezverejňuje (LATTEOS-GOO.md, úvod).

Plán vývoja je v [ROADMAP.md](ROADMAP.md). Nový kód a dáta vznikajú iba mimo `old/`.

## Platforma

- **Základ:** klasický **Fedora Server 44** (dnf, nie atomic); Fedora Atomic (bootc, štýl Bazzite / Universal
  Blue), live USB a inštalátor až keď bude LatteOS GOO hotový.
- **Vývoj a testy:** reálny PC `latte-lab` (AMD RX 640, dva monitory) a virtuálny stroj `latteOSdev`.
- **Bez GPU musí systém naštartovať** (núdzový režim SAFE: labwc + pixman); HW akcelerácia pridáva efekty,
  podmienkou štartu nie je.

## Zásady pre engine Goo (poznámky autora)

1. **Oddelenie jadra od renderu (headless core):** logika (stav batérie, zoznam okien, notifikácie, AI požiadavky)
   beží v samostatnom daemone (Python, Go alebo Rust). Quickshell/QML je iba „hlúpa“ vizuálna vrstva, ktorá
   dostáva dáta cez IPC.
2. **Goo API (event bus):** presné rozhranie pre kvapky, napr. `goo.emit("power", "battery_low", 15)`. Všetky
   kvapky (aj prebraté z GitHubu) komunikujú cez tento jednotný most, nie priamym prepojením komponentov, ktoré
   sa pri aktualizácii Noctalie rozbije.
3. **Wrapper pre externé moduly:** prebraný kód sa obalí vlastnou triedou alebo funkciou. Kód Noctalie sa priamo
   neupravuje, ak to nie je nevyhnutné — vždy nadstavba.
4. **Optimalizácia.**
