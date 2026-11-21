# LatteOS GOO

@Arkay · nový štart 23. 9. 2026 · predtým pracovný názov „gamerdistro“

**LatteOS GOO** je linuxová plocha pre ľudí zvyknutých na Windows 11, v ktorej lištu, Štart, hodiny a systémové
prvky nahrádzajú **tekuté kávové kvapky** (goo): pružia, lepia sa k okraju obrazovky aj k sebe, žijú vlastným
pohybom a reagujú na kurzor. Všetko sa ovláda myšou.

<img width="1451" height="823" alt="obrázok" src="https://github.com/user-attachments/assets/1e535e9c-0dca-4e8b-913f-9e024b759f13" />


## Smer vývoja

- **LatteOS GOO je jediná edícia** (5. 10. 2026); LatteOS Classic je zrušený a jeho kód je z repozitára preč.
- **Správca okien je pleamar-wm** (od 2. 11. 2026; Hyprland odinštalovaný, Noctalia sa nepoužíva). Engine Goo beží
  nad [pleamarom](https://github.com/k4ditano/pleamar) (k4ditano, BSD-3-Clause), ako samostatný proces nad oknami.
- **Do verzie 0.6 iba opravy** (21. 11. 2026), žiadne nové funkcie. Poradie práce je na začiatku
  [ROADMAP.md](../ROADMAP.md) („Poradie práce“).

## Kvapky

| | Kvapka | Čo robí |
|---|---|---|
| | **BarGoo** | lišta a správca okien — okná ako ikry a strapce po aplikáciách |
| | **PowerGoo** | účet, relácia, napájanie a profil napájania, batéria, Nastavenia, Monitor; pás výkonu (CPU, RAM, GPU, VRAM) |
| | **LensGoo** | spúšťač a lupa: aplikácie, súbory, web, terminál; rýchly zoznam aplikácií (alebo LensShore) |
| | **QuickGoo** | rýchle spúšťanie: páska s aplikáciami poruke |
| | **QueenGoo** | App Manager a Správca zariadení |
| | **ClockGoo** | upozornenia a kalendár; čas, stopky, minútka, budíky, počasie |
| | **MediaGoo** | práve hrá (MPRIS) |
| | **CamGoo** | webkamery |

Skryť sa dá každá kvapka (14. 11.); jeden spúšťač ostáva vždy. Kliky kvapiek sú v [LATTEOS-GOO.md §4](../LATTEOS-GOO.md),
záväzné pravidlá a správanie v [LATTEOS-GOO.md](../LATTEOS-GOO.md) (pred prácou na kvapkách prečítať), prehľad
v [docs/goo/](goo/README.md).

## Štruktúra

| Zložka   | Obsah |
|----------|-------|
| `goo/` | **engine Goo**: scéna `goo.plm`, časti `parts/`, logika `lib/` (`engine.luau` — v hlavičke ako sa píše kvapka), kvapky `drops/`, preklady `lang/`, prihlásenie, zámok, SAFE |
| `apps/` | aplikácie LatteOS (Quickshell, QML): Nastavenia, LensAI, DualBrew, Monitor, App Manager… |
| `bin/` | pomocníci `latte-*`: relácia, prihlásenie, súbory, sieť, AI… |
| `crates/` | Rust: `latte-hw` (detekcia HW/grafiky), `latte-boot` (NORMAL/SAFE, počítadlo pádov), `latte-goo` a `goo-phys` (fyzika Goo), `latte-index`, `latte-chapolera`… |
| `system/` | súbory do systému: pleamar-wm (`pleamarwm/`), labwc, greetd, systemd, relácie, Plymouth, farby šálok `cups.json` |
| `patches/` | naše [záplaty](../patches/README.md) pleamaru a pleamar-wm; návrhy autorovi v `patches/issues/` |
| `templates/` | šablóny okien ([docs/okna/SABLONY.md](okna/SABLONY.md)) |
| `install`, `get` | inštalácia (README › Installing) |
| `tests/` | `check.sh` pred commitom, `screen.sh` skúška scény bez obrazovky |
| `docs/` | dokumentácia: [index](README.md), [pravidlá Goo](goo/PRAVIDLA.md), [kvapky](goo/ROZHRANIE.md), [rozhodnutia](goo/ROZHODNUTIA.md) |
| `FILES` | každý súbor, ktorý LatteOS pridá do systému (cieľ ← zdroj) |

Strom v0.3 je vo vetve `v0.3` (v aktuálnej vetve už nie je); nový kód vzniká načisto.

**Repozitár je verejný:** [arkaysk/LatteOS-v0x-Jihlavanka](https://github.com/arkaysk/LatteOS-v0x-Jihlavanka),
predvolená vetva **`v0.55`** (do 19. 11. 2026 `v0.5-pleamarwm-jihlavanka`); `v0.4-fresh` ostáva ako cesta späť
k Hyprlandu. Nič citlivé do gitu; commit a push iba na pokyn. Zmeny po verziách: [ZMENY.md](../ZMENY.md).
Licencia: GNU GPL 3.0 alebo novšia ([LICENSE](../LICENSE)), cudzie súčasti v [TRETIE-STRANY.md](../TRETIE-STRANY.md).

Plán vývoja je v [ROADMAP.md](../ROADMAP.md).

## Platforma

- **Základ:** klasický **Fedora Server 45** (dnf, nie atomic); Fedora Atomic (bootc, štýl Bazzite / Universal
  Blue) až pre 1.0.
- **Vývoj a testy:** reálny PC `latte-lab` (AMD RX 640, jeden monitor); karty GFX6–GFX8 potrebujú Linux 7.3 a Mesu 26.3.
- **Bez GPU musí systém naštartovať** (núdzový režim SAFE: labwc + pixman); HW akcelerácia pridáva efekty,
  podmienkou štartu nie je.

## Zásady pre engine Goo (poznámky autora — na zváženie)

*Nerozhodnuté (6. 10.): dnešný engine je scéna pleamaru + logika v Luau + fyzika v Ruste (`latte-goo`), nie samostatný
daemon s Quickshell vrstvou; zvažuje sa, čo z týchto zásad prevziať.*

1. **Oddelenie jadra od renderu (headless core):** logika (stav batérie, zoznam okien, notifikácie, AI požiadavky)
   beží v samostatnom daemone (Python, Go alebo Rust). Quickshell/QML je iba „hlúpa“ vizuálna vrstva, ktorá
   dostáva dáta cez IPC.
2. **Goo API (event bus):** presné rozhranie pre kvapky, napr. `goo.emit("power", "battery_low", 15)`. Všetky
   kvapky (aj prebraté z GitHubu) komunikujú cez tento jednotný most, nie priamym prepojením komponentov, ktoré
   sa pri aktualizácii cudzieho kódu rozbije.
3. **Wrapper pre externé moduly:** prebraný kód sa obalí vlastnou triedou alebo funkciou. Cudzí kód (pleamar,
   pleamar-wm) sa priamo neupravuje, ak to nie je nevyhnutné — vždy nadstavba.
4. **Optimalizácia.**
