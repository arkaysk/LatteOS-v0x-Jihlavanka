# LatteOS GOO

**English** · [Slovensky](#slovensky)

A Linux system for people coming from Windows 11. The desktop is built from **liquid coffee droplets** ("goo")
instead of a taskbar and Start menu. Everything works with the mouse; keyboard shortcuts are only a bonus.

> **Status: early development.** The system changes daily, settings are not stable and things can break.
> Install it on a test machine only, never on the computer you work on.

## What LatteOS is

- **Mouse first.** No function is reachable only by keyboard or shortcut. Everything is clickable, and the
  environment stays as close to Windows habits as possible, even though it looks different.
- **Safer by design.** Most apps run as Flatpak or inside bubblewrap. A **NET** button cuts any app off the
  internet instantly.
- **Made for PC games**, like Bazzite, CachyOS or SteamOS. **Barista** (see below) prepares non-Linux software
  and games for you: install, unpack, set up.
- **AI is optional.** AI features are meant to be switched on or off by you; the installer is planned to ask
  at the very start, and you can change it any time in Settings.
- Built on **Fedora Server 44** today; an Atomic (bootc) image in the style of Bazzite may follow later.

## What is on the desktop

The desktop is **GooEngine**, based on [pleamar](https://github.com/k4ditano/pleamar): coffee droplets in low
gravity that stick to the screen edge and to each other, are drawn towards the cursor and react even when you
are away. The bottom edge is a coffee surface that ripples when droplets land.

| Droplet | Left click | Right click |
|---|---|---|
| **GooBar** — taskbar | head: next window mode (endless strip, tiles, floating) · window droplet: switch or minimise | head: show desktop · window droplet: window menu |
| **GooPower** — account and power | card with account, power and performance | performance strip (CPU, RAM, GPU, VRAM) |
| **LensGoo** — launcher (also the Win key) | apps, files, web, terminal, AI | quick list of apps |
| **ClockGoo** — time | notifications and calendar | clock, stopwatch, alarms, weather |
| **QueenGoo** — system management | App Manager with the store | Device Manager |
| **ChatGoo** — Beeper companion | show or hide Beeper | messages |

GooBar, GooPower and LensGoo are always present; the others can be turned off in Settings › Droplets.
Droplets can be dragged with the mouse and resized with the wheel. You can also create your own droplets
without programming. Without a mouse: **Win** opens the launcher, **Win+T** selects droplets with arrow
keys, **Win+L** locks the screen.

## System parts

- **Hyprland** draws windows and effects; **Noctalia** provides the bottom-right corner bar (tray, network,
  volume, control centre) and its widgets.
- **Login screen** — a coffee cup, a droplet that jumps out and turns into the login field on a coffee surface;
  after login it settles in place of GooPower. You can also switch to another installed desktop.
- **SAFE mode** — a minimal maintenance desktop that runs without graphics acceleration and carries tools to find
  out what broke. It starts automatically when graphics fail or the session crashes twice in a row.
- **Settings** — logical categories; the droplets have their own page, plus effects, performance, languages
  and wallpapers.
- **DualBrew** (Files) — dual-pane file manager with tabs, queued operations, archives, search, sync, network and cloud
  places.
- **Heidelberg** — document editor (Markdown, docx, odt, PDF).
- **Monitor** — a task manager combined with an autoruns viewer and hardware sensors (think Windows 11 Task
  Manager, Autoruns, HWiNFO and CPU-Z in one).
- **Device Manager** — identifies and sets up connected hardware (printers, scanners, phones, drivers) together
  with the network manager and a **Network Inspector** that shows what is around you on the network.
- **App Manager** — store and installer for Linux apps (Flatpak, Fedora packages) and updater for software and
  firmware. **Barista** is part of it: point it at a file or folder (disc images, archives, a portable folder, an
  installer, DOS) and it works out how to run it. Today it targets Windows software and games, with Android and
  more emulation planned.

## Vision: LatteOS 1.0 "Arabica"

Everything above is what exists today, in early form. The goal for **1.0 "Arabica"** is a finished system:
mouse first (every function reachable by mouse, keyboard only a bonus), every app a click away, Barista running software from small things to
big (today Windows, later Android and further emulation), a one-click choice in the installer whether to use AI
at all, a custom boot menu (Nervboot) with dual boot, and an Atomic image. These are goals, not promises;
progress is tracked in the roadmap.

## Requirements

- **Fedora 44 Server** (classic, not Atomic), clean install.
- An **AMD** graphics card (Mesa; tested on RX 550 and RX 640). NVIDIA and virtual machines are not verified
  with the Goo desktop yet.
- At least 4 GB RAM, ~20 GB disk, internet.

## Installation

The full procedure for a real computer (BIOS, disk, network, remote access) is in
[setup/lab/README.md](setup/lab/README.md). After installing Fedora:

```
sudo dnf -y install git
git clone https://github.com/arkaysk/latteos && cd latteos
setup/lab/install.sh            # everything except the graphical start
setup/lab/install.sh --enable   # once the final check passes: turns on the LatteOS login screen
```

A Btrfs snapshot is taken first, so system files can be restored (`snapper`). On the login screen choose the
**LatteOS GOO** session. To install a specific version, run `git checkout v0.3.0` before the installer.

## Safe start

At every boot `latte-boot` detects the graphics and picks a mode:

| Mode | When | What runs |
|---|---|---|
| NORMAL | graphics work | the LatteOS GOO desktop |
| SAFE | graphics fail, or the session crashed twice in a row | simple desktop without effects and a rescue menu |

GRUB always has a **LatteOS SAFE** entry for manual rescue. Check the state with `latte-boot status`.

## Versions

Every release has its own version and a `vX.Y.Z` tag; changes are listed in [ZMENY.md](ZMENY.md) (Slovak).
Development happens elsewhere and is moved here in stages, so there is one commit per release.

## Layout

| Folder | Contents |
|---|---|
| `session/goo/` | GooEngine: desktop scene, droplets and their logic — [how to write your own droplet](docs/goo/ROZHRANIE.md) |
| `session/` | session, login, Hyprland configuration, apps, themes — [overview](session/README.md) |
| `crates/` | Rust: `latte-hw` (graphics detection), `latte-boot` (mode selection, crash counter) |
| `setup/` | install scripts and tests |
| `resources/` | our patches to third-party projects; `fetch.sh` downloads their sources |
| `docs/` | architecture and droplet rules |

## What LatteOS GOO builds on

Droplets are drawn by [pleamar](https://github.com/k4ditano/pleamar) by k4ditano, and its Marea desktop was the
first inspiration. LatteOS GOO grew out of them but is now a separate desktop with its own droplet engine,
its own apps and its own way of control. Hyprland manages windows; Noctalia supplies the corner bar. The full
list of third-party components and licences is in [TRETIE-STRANY.md](TRETIE-STRANY.md).

## Bugs and contributions

Found a bug? Open an [Issue](https://github.com/arkaysk/latteos/issues) and attach `latte-boot status`,
`journalctl -b -e` and what you were doing. Screenshots help.

## Licence

[MIT](LICENSE). Third-party components have their own licences — [TRETIE-STRANY.md](TRETIE-STRANY.md).

---

<a id="slovensky"></a>

# LatteOS GOO — Slovensky

[English](#latteos-goo) · **Slovensky**

Linuxový systém pre ľudí zvyknutých na Windows 11. Plochu tvoria **tekuté kávové kvapky** (goo) namiesto lišty a
ponuky Štart. Všetko sa ovláda myšou, klávesové skratky sú iba doplnok.

> **Stav: skorý vývoj.** Systém sa mení každý deň, nastavenia nie sú stabilné a veci sa môžu pokaziť.
> Inštaluj iba na testovací počítač, nie na počítač, na ktorom pracuješ.

## Čo LatteOS je

- **Myš je prvá.** Žiadna funkcia nie je dosiahnuteľná len klávesnicou alebo skratkou. Všetko sa dá kliknúť a
  prostredie je, hoci vyzerá inak, čo najpodobnejšie zvykom z Windowsu.
- **Bezpečnejší už návrhom.** Väčšina aplikácií beží ako Flatpak alebo v bubblewrape. Tlačidlo **NET** okamžite
  odpojí ľubovoľnú aplikáciu od internetu.
- **Pre hry na PC**, ako Bazzite, CachyOS či SteamOS. **Barista** (nižšie) pripraví nelinuxový softvér a hry:
  inštaláciu, rozbalenie, nastavenie.
- **AI je voliteľná.** Zapnúť alebo vypnúť ju má byť na tebe; inštalátor sa na to má opýtať hneď na začiatku
  (zatiaľ je to plán) a zmeniť sa to dá kedykoľvek v Nastaveniach.
- Dnes stojí na **Fedora Server 44**; neskôr môže prísť obraz Atomic (bootc) podľa vzoru Bazzite.

## Čo je na ploche

Plocha je **GooEngine** nad [pleamarom](https://github.com/k4ditano/pleamar): kvapky kávy v nízkej gravitácii, ktoré
sa lepia k okraju obrazovky aj k sebe, kurzor ich priťahuje a reagujú aj na tvoju neprítomnosť. Spodný okraj je
kávová hladina, ktorá sa zvlní, keď na ňu kvapky dopadnú.

| Kvapka | Ľavý klik | Pravý klik |
|---|---|---|
| **GooBar** — lišta s oknami | hlava: ďalší režim okien (nekonečná páska, dlaždice, plávajúce) · ikra: prepnúť alebo minimalizovať okno | hlava: ukázať plochu · ikra: ponuka okna |
| **GooPower** — účet a napájanie | karta účtu, napájania a výkonu | pás výkonu (CPU, RAM, GPU, VRAM) |
| **LensGoo** — spúšťač (aj kláves Win) | aplikácie, súbory, web, terminál, AI | rýchly zoznam aplikácií |
| **ClockGoo** — čas | upozornenia a kalendár | čas, stopky, budíky, počasie |
| **QueenGoo** — správa systému | App Manager s obchodom | Správca zariadení |
| **ChatGoo** — doplnok pre Beeper | ukázať alebo schovať Beeper | správy |

GooBar, GooPower a LensGoo sú na ploche vždy; ostatné kvapky sa dajú vypnúť v Nastaveniach › Kvapky.
Kvapky sa dajú ťahať myšou a kolieskom zväčšovať. Vlastné kvapky si vytvoríš bez programovania. Bez myši:
**Win** otvorí spúšťač, **Win+T** zapne výber kvapiek šípkami, **Win+L** zamkne obrazovku.

## Súčasti systému

- **Hyprland** kreslí okná a efekty; **Noctalia** dodáva rohovú lištu vpravo dole (ikony na pozadí, sieť,
  hlasitosť, ovládacie centrum) a jej widgety.
- **Prihlasovanie** — šálka kávy, kvapka, ktorá z nej vyskočí a na kávovej hladine sa zmení na prihlasovacie
  políčko; po prihlásení sa usadí na miesto GooPower. Dá sa prepnúť aj do iného nainštalovaného prostredia.
- **Režim SAFE** — minimálna záchranná plocha bez grafickej akcelerácie so sadou nástrojov na zistenie, čo sa
  pokazilo. Spustí sa sám, keď grafika zlyhá alebo relácia dvakrát za sebou spadne.
- **Nastavenia** — logické kategórie; kvapky majú vlastnú stránku, ďalej efekty, výkon, jazyky a tapety.
- **DualBrew** (Súbory) — dvojpanelový správca s kartami, frontom operácií, archívmi, hľadaním, synchronizáciou, sieťovými
  a cloudovými miestami.
- **Heidelberg** — editor dokumentov (Markdown, docx, odt, PDF).
- **Monitor** — správca úloh spojený s prehľadom automatického štartu a senzormi hardvéru (ako Správca úloh
  Windows 11, Autoruns, HWiNFO a CPU-Z v jednom).
- **Správca zariadení** — rozpozná a nastaví pripojený hardvér (tlačiarne, skenery, telefóny, ovládače), spolu
  so správcom sietí a **Inšpektorom siete**, ktorý ukáže, čo je okolo teba v sieti.
- **App Manager** — obchod a inštalátor Linuxových aplikácií (Flatpak, balíky Fedory) a aktualizátor softvéru
  aj firmvéru. Jeho súčasťou je **Barista**: zacieľ ju na súbor alebo priečinok (obraz disku, archív, portable
  priečinok, inštalátor, DOS) a zistí, ako ho spustiť. Dnes cieli na windowsový softvér a hry, Android a ďalšia
  emulácia sú v pláne.

## Vízia: LatteOS 1.0 „Arabica“

Všetko vyššie je stav dnes, v skorej podobe. Cieľom verzie **1.0 „Arabica“** je hotový systém: myš je prvá (všetko
dosiahnuteľné myšou, klávesnica je doplnok), každá aplikácia na klik, Barista spúšťajúca softvér od malých vecí po veľké (dnes
Windows, neskôr Android a ďalšia emulácia), voľba v inštalátore, či AI vôbec používať, vlastná ponuka štartu
(Nervboot) s dualbootom a obraz Atomic. Sú to ciele, nie sľuby; postup sleduje roadmapa.

## Čo potrebuješ

- **Fedora 44 Server** (klasická, nie Atomic), čistá inštalácia.
- Grafickú kartu **AMD** (Mesa; overené na RX 550 a RX 640). NVIDIA a virtuálny stroj nie sú s plochou Goo overené.
- Aspoň 4 GB RAM, ~20 GB miesta, internet.

## Inštalácia

Celý postup pre reálny počítač (BIOS, disk, sieť, vzdialený prístup) je v
[setup/lab/README.md](setup/lab/README.md). Po inštalácii Fedory stačí:

```
sudo dnf -y install git
git clone https://github.com/arkaysk/latteos && cd latteos
setup/lab/install.sh            # všetko okrem grafického štartu
setup/lab/install.sh --enable   # keď kontrola na konci vyjde: zapne prihlasovaciu obrazovku LatteOS
```

Pred zmenami sa urobí snímka Btrfs, takže systémové súbory sa dajú vrátiť (`snapper`).
Na prihlasovacej obrazovke vyber reláciu **LatteOS GOO**.
Konkrétnu verziu nainštaluješ jej značkou, napríklad `git checkout v0.3.0` pred spustením inštalátora.

## Bezpečný štart

Pri každom štarte `latte-boot` zistí grafiku a vyberie režim:

| Režim | Kedy | Čo beží |
|---|---|---|
| NORMAL | grafika funguje | plocha LatteOS GOO |
| SAFE | grafika nefunguje, alebo relácia dvakrát za sebou spadla | jednoduchá plocha bez efektov so záchrannou ponukou |

V GRUB-e sú vždy položky **LatteOS SAFE** na ručnú záchranu. Stav zistíš príkazom `latte-boot status`.

## Verzie

Každé zverejnenie má vlastnú verziu a značku `vX.Y.Z`; čo sa zmenilo, je v [ZMENY.md](ZMENY.md).
Vývoj prebieha inde a sem sa presúva po fázach, preto je tu jeden commit na vydanie.

## Štruktúra

| Priečinok | Obsah |
|---|---|
| `session/goo/` | GooEngine: scéna plochy, kvapky a ich logika — [ako napísať vlastnú kvapku](docs/goo/ROZHRANIE.md) |
| `session/` | relácia, prihlásenie, nastavenie Hyprlandu, aplikácie, témy — [prehľad](session/README.md) |
| `crates/` | Rust: `latte-hw` (zistenie grafiky), `latte-boot` (výber režimu, počítadlo pádov) |
| `setup/` | inštalačné skripty a testy |
| `resources/` | naše záplaty cudzích projektov; `fetch.sh` stiahne ich zdroje |
| `docs/` | architektúra a pravidlá kvapiek |

## Z čoho LatteOS GOO vychádza

Kvapky kreslí [pleamar](https://github.com/k4ditano/pleamar) od k4ditano a prvým vzorom bola jeho plocha Marea.
LatteOS GOO z nich vyšiel, dnes je to však samostatná plocha s vlastným enginom kvapiek, vlastnými aplikáciami
a vlastným spôsobom ovládania. Okná spravuje Hyprland, rohovú lištu dodáva Noctalia.
Úplný zoznam cudzích súčastí a ich licencií je v [TRETIE-STRANY.md](TRETIE-STRANY.md).

## Chyby a príspevky

Našiel si chybu? Otvor [Issue](https://github.com/arkaysk/latteos/issues) a pripoj
`latte-boot status`, `journalctl -b -e` a čo si robil. Snímky obrazovky pomáhajú.

## Licencia

[MIT](LICENSE). Súčasti tretích strán majú vlastné licencie — [TRETIE-STRANY.md](TRETIE-STRANY.md).
