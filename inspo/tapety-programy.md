# Tapety: čo vedia predlohy (28. 10. 2026)

Overené zo stránok projektov, man page mpvpaper, Wallhaven API a `skwd-helm --help` na latte-lab.
Na latte-lab je: skwd-wall-v2 / skwd-paper / skwd-deck / skwd-lens 1.0.0 beta 26, mpvpaper 1.9, swaybg 1.2.2.
Nie je: hyprpaper, awww, wpaperd, waypaper. Netreba ich inštalovať — berú sa z nich nápady (7A, 7A.07, 7A.08).

| Program | Čo vie | Čo preberáme | Pozor |
|---|---|---|---|
| **skwd-wall** (MIT) | 39 prechodov, scény Wallpaper Engine (Vulkan), playlisty ručné aj podľa filtra, rozvrhy (čas, východ slnka, počasie, batéria, pripojené obrazovky), zámok obrazovky pred zmenou, zvuk podľa obrazovky, farby (Matugen, Wallust, Pywal…), Workshop/Wallhaven/YouTube/Bing. `skwd-helm apply PATH -o OUT`, `next/prev -o`, `back/forward` (história), `random --type --tag`, `outputs --json`, `watch`. | Kreslí ďalej on. Schéma = jeho playlist + `apply -o` pre každú obrazovku; prechody, zámok, zvuk. | Podľa README nevie jeden obraz cez viac obrazoviek. Tapeta podľa plochy iba v configu. |
| **mpvpaper** (GPL-3) | Video cez mpv, `ALL` alebo meno výstupu. `-p` pozastaví, keď je skrytý, `-s` zastaví, `-a FULL\|MAX\|ACTIVE` aj pri okne na celú obrazovku / maximalizovanom / aktívnom, `-n SEC` prezentácia videí, IPC socket. | Voľba „Pozastaviť, keď je okno na celú obrazovku“. Záloha bez skwd. | Video cez viac obrazoviek = jeden mpv s `--vf=crop` na každý výstup, navzájom nesynchronizované. Podľa skwd README zaberie veľa pamäte. |
| **wpaperd** (GPL-3) | TOML podľa obrazovky (`default`, `any`, `re:`), `sorting` ascending/descending/random, `queue-size` (neopakovať), `recursive`, `group` (rovnaká náhodná tapeta na skupine), `exec` pri zmene, ~50 gl-transitions, `mode` fit/fit-border-color/center/stretch/tile, `offset`. | Voľby prezentácie (poradie, podpriečinky, neopakovať), „Prispôsobiť s farbou okraja“. | README píše, že Hyprland nepodporuje. |
| **awww** (0.12.1, júl 2026) | Démon, GIF, farba, prechody simple/center/outer/any/random a smery stierania, `--transition-step`, `--transition-fps`. Zámerne bez nových funkcií, video odporúča mpvpaper. | Prechod „z miesta, kam pustíš“ (ako `outer`/`any` so stredom). | Video nevie. |
| **hyprpaper** (BSD-3) | Blok `wallpaper { monitor, path, fit_mode }`, `fit_mode` contain/cover/tile/fill (predvolene cover), prázdny monitor = záloha pre ostatné, `path` smie byť priečinok, IPC. | Mená režimov; „všetky ostatné obrazovky“. | Nič navyše oproti skwd + swaybg. |
| **waypaper** (GPL-3, Python GTK) | Mriežka náhľadov, priečinok, triedenie, podpriečinky, náhodná, prezentácia v minútach (`waypaperd`), Zen režim (iba mriežka), `post_command`, `--monitor` (bez neho všetky), `--list` JSON. | Rozloženie knižnice: mriežka + priečinok + triedenie + Náhodná. | Obrazovka sa vyberá rozbaľovačom — u nás pegboard. |
| **WallRizz** (MIT, QuickJS, terminál) | Téma z tapety + skript pre každú aplikáciu (Kitty, VS Code, Firefox…), zbierky tapiet z GitHub repozitárov. | Zdroj „Zbierky z GitHubu“. Skripty tém aplikácií patria do 9A. | Viac obrazoviek nespomína. |
| **Wallhaven API** | `/api/v1/search`: `q`, `atleast`, `ratios`, `colors`, `sorting` (toplist, random + `seed`), 24 na stranu, 45 dopytov/min, bez kľúča iba SFW. | Pri plachte cez viac obrazoviek hľadať `atleast` = rozmer výberu a jeho pomer. | — |
| **MotionBGS** | ~9 700 živých tapiet, väčšinou 4K, kategórie, sekcia Mobile. | Už je v `latte-walls`. | Bez API, licencia pre tapety neuvedená; stránka sa môže zmeniť. |

## Čo nevie nikto

Jeden obraz alebo video cez viac obrazoviek podľa ich polohy na pegboarde (7A.08). Musí to robiť `latte-wall`:
výrez pre každú obrazovku z polohy plachty a obrazovky (v pixeloch obrazovky, so `scale`), potom `skwd-helm apply výrez -o OUT`
(bez skwd swaybg / mpvpaper s `--vf=crop`).
