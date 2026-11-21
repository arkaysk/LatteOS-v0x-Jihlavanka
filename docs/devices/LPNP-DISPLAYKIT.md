# LPnP + DisplayKit — návrh (19. 11. 2026) a jeho kontrola

Úlohy: ROADMAP **10E.14–10E.19** (LPnP, Správca zariadení) a **8B.09–8B.12** (DisplayKit, Obrazovky).
V poradí práce hneď po LensAI (10B). Pôvodný návrh používateľa je nižšie bez zmeny; najprv kontrola, ktorá ho upravuje.

## Kontrola 19. 11. (Claude) — čo platí inak, než návrh predpokladá

1. **Čísla verzií.** V ROADMAP je 0.6 už obsadená (14.21: 0.6 = Fáza 2 Plocha Goo, 0.7 Vzhľad, 0.8/0.9 aplikácie).
   Kroky „0.6.0 … 0.7“ z kap. 7 sa preto volajú **etapy E1–E5**, nie verzie; ktorú verziu LatteOS dostanú, určí fáza, v ktorej sa dokončia.
2. **Nie je ostree.** latte-lab aj inštalátor sú dnes Fedora 45 s `dnf` a snímkami **snapper** (Btrfs); Atomic/bootc je 1C, odložené.
   Návrat po inštalácii ovládača = snímka snapper pred `dnf` (+ položka v GRUB-e zo SAFE, kat. 3/5), nie ostree deployment.
   Adaptér inštalácie navrhnúť tak, aby sa ostree dalo doplniť po 1C. Na latte-lab vždy `dnf … --noautoremove`.
3. **Nie je Hyprland.** Odinštalovaný 2. 11., jediný smer je pleamar-wm. Adaptér kompozitora = **pleamar-wm**
   (binárka obsahuje `zwlr_output_configuration`/`head` = wlr-output-management, `wp_color_manager_v1`,
   `wp_color_representation`, `tearing_control` — či sú naozaj zapnuté a čo vedia, overiť); generický wlr-output-management stačí
   aj pre labwc v SAFE. Adaptér pre Hyprland netreba. Odstavec o Hyprlande 0.55 a Plasme 6.7 je iba inšpirácia UX (neoverené).
4. **Veľa už existuje — rozšíriť, nepísať vedľa:**
   - Správca zariadení: `apps/devices.qml` + `bin/latte-devices` (10E.01; 10E.02, .06–.11 sú presne ciele LPnP) → Device Manager = toto okno.
   - Obrazovky: `bin/latte-screens` (hlavný monitor, `--watch` cez `$PLEAMAR_SOCKETS/desktop`), pegboard v Nastaveniach (8B.04),
     rozlíšenia, Identifikovať, nočné svetlo `bin/latte-nightlight` (8B.05); HDR/profil/VRR (8B.06); **mikrozoom v mm je už 8B.07**;
     ICC + DDC/CI (8B.08); zrkadlenie v pleamar-wm (1D.23); monitory vo Workfielde (10M.05).
   - Na latte-lab už sú `ddcutil` 3.0.2, `fwupd` 2.1.9, `colord` 1.4.8, `hwdata` 0.412.
5. **Najprv prevziať (pravidlo „najprv nájsť“), licencie voči GPL-3.0-or-later LatteOS:**
   CachyOS **chwd** (GPL-3, Rust: detekcia PCI a profily ovládačov — kód sa smie prevziať priamo, autor do `TRETIE-STRANY.md`);
   **kanshi** / **shikane** (MIT: zostavy podľa množiny monitorov — prevziať logiku zhody); **hw-probe** / **LKDDb** (dáta);
   libratbag (MIT), OpenRazer, Solaar, OpenRGB (GPL-2+) iba volať cez D-Bus/CLI/SDK, nespájať do kódu;
   ddcutil (GPL-2+) cez CLI alebo libddcutil; fwupd cez D-Bus. Pred písaním ukázať používateľovi konkrétny zdroj a cestu.
6. **Atlas na začiatok jednoduchšie:** TOML záznamy v repe (`system/lpnp/atlas/`), načítané priamo; SQLite, podpis a bot importu až keď
   záznamov bude veľa (E5). Na verejné repo nič citlivé; bez telemetrie (ako navrhnuté).
7. **„Rampage IV“** v kap. 4 — v repe nie je; testovací stroj je latte-lab (RX 640), hlavné PC má RTX 3060. Kanál Tested = overené na nich.
8. **Prekryv s alpha cieľom:** ROADMAP („Aktuálny cieľ — alpha“) hovorí „nepridávať nové produktové funkcie“. Zaradené po LensAI
   na pokyn používateľa 19. 11.; ak má alpha (2.06, 14.20) prednosť, LPnP ide až po nej.
9. Bezpečný displejový režim z čierneho obrazu = skratka v `system/pleamarwm/keys.conf` + `latte-screens`; nezávislá od Goo a od D-Bus služby.
10. Pravidlá frekvencie podľa aplikácie (hra → 165 Hz + VRR) závisia od toho, či pleamar-wm vie meniť režim za behu podľa okna — overiť; inak návrh autorovi do `patches/issues/`.

## Zdroje pre E1 a cesta (20. 11., Claude) — na schválenie, kód zatiaľ žiadny

| Zdroj | Licencia | Čo je | Čo prevziať |
|---|---|---|---|
| [CachyOS chwd](https://github.com/CachyOS/chwd) | GPL-3.0 (smie sa do LatteOS, GPL-3.0-or-later) | Rust, detekcia PCI/USB (`libpci`, `libusb` v repe), profily ovládačov v TOML, aktívny (31. 10.) | **priamo kód** zhody zariadenie ↔ profil (`profile.rs` 32 kB, `data.rs`, `device*.rs`) a **formát profilov**: `class_ids`, `vendor_ids`, `device_ids`/`device_name_pattern`, `priority`, `driver_conflict_group` (= náš Resolver „iba jeden z konfliktných“), `packages`, skripty pred/po inštalácii. Mení sa: balíky `pacman` → `dnf` (Fedora), pribudnú polia LPnP (`level`, `features`, `provider`, `recovery`). |
| [hw-probe](https://github.com/linuxhw/hw-probe) | LGPL-2.1+ alebo BSD-4 | Perl, sonda hardvéru a databáza linux-hardware.org | iba **dáta** (či zariadenie na Linuxe funguje, aký ovládač) ako zdroj pre Atlas; nič neposielať (bez telemetrie) |
| [LKDDb](https://github.com/linuxhw/LKDDb) | GPL-2.0 | databáza ID → modul jadra, posledná zmena 2023 | iba ako doplnkové dáta, nie závislosť |
| [kanshi](https://github.com/emersion/kanshi) / shikane | MIT | zostavy monitorov podľa množiny pripojených | logika zhody zostáv pre DisplayKit (E3), nie E1 |
| `bin/latte-devices` (vlastné) | — | Správca zariadení: `lspci -vmm -k -nn`, USB, vstupy, EDID, nálezy | ostáva UI a čítanie; E1 doň pridá kartu „úroveň funkčnosti + návrh poskytovateľa“ |

**Cesta E1 (návrh):** `crates/latte-lpnp` (Rust) = prevzatý kód chwd na detekciu a zhodu + čítanie Atlasu (`system/lpnp/atlas/*.toml`
vo formáte chwd s poľami LPnP) → príkaz `latte-lpnp scan` vypíše DeviceRecord a najlepší profil s úrovňou (Nefunguje / Základná / Plná);
`bin/latte-devices` ho zavolá a karta zariadenia ukáže návrh. Nič neinštaluje (to je E2). Prvé záznamy Atlasu: GPU AMD/NVIDIA (profily chwd
prevedené na `dnf`), Logitech (Solaar), Razer (OpenRazer), herné ovládače, tlačiarne (CUPS/ipp-usb). Autor chwd do `TRETIE-STRANY.md`.

---

## Pôvodný návrh (používateľ, 19. 11. 2026)

# LatteOS 0.6 – Architektúra: DisplayKit + LPnP

## 1. Zhrnutie

Verzia 0.6 pridáva dve systémové služby a rozširuje dve existujúce UI:

- **latte-displayd** (DisplayKit) – správa displejov: identita monitora, profily zostáv, mierka pri zmiešanom DPI, HDR, ICC, obnovovacia frekvencia/VRR, bezpečné aplikovanie a automatické obnovenie. UI = rozšírený **Pegboard** v Settings.
- **lpnpd** (LPnP – Latte Plug and Play) – „chýbajúca integračná vrstva“: zistí zariadenie, porovná ho s databázou, povie čo funguje len základne, navrhne lepší ovládač/nástroj (OpenRazer, Solaar, libratbag, NVIDIA vetva…), nainštaluje ho s možnosťou návratu a vystaví funkcie zariadenia cez jedno API. UI = **Device Manager**.

Princíp: LatteOS nepíše ovládače. LPnP je **znalostná databáza + resolver + sprostredkovateľ**, ktorý spája to, čo komunita už vytvorila, „pod jednu strechu“.

## 2. Existuje už „Linux UPnP“? (stav november 2026)

Krátko: **nie ako jeden celok.** Existujú kúsky, ktoré pokrývajú vždy len časť obrázku:

| Projekt | Čo robí | Čo mu chýba voči LPnP |
| --- | --- | --- |
| **CachyOS chwd** (Rust, GPL-3, aktívny) | Zistí GPU/sieťovky, nainštaluje overený profil ovládača; nové verzie riešia konflikty pri viacerých GPU rôznych generácií NVIDIA | Viazaný na Arch/pacman, rieši „systémové“ ovládače, nie periférie a ich funkcie |
| **ubuntu-drivers / Mint Driver Manager / Manjaro mhwd** | modalias → odporúčaný balík (hlavne GPU, Wi-Fi, Broadcom) | Distro-špecifické, žiadna mapa funkcií, žiadne UI pre nastavenia zariadenia |
| **linux-hardware.org + hw-probe + LKDDb** | Najväčšia DB (200 000+ konfigurácií od 2014); pre nefunkčné zariadenie navrhne verziu kernelu alebo ovládač tretej strany | Je to web + sonda, nič neinštaluje, nie je integrované do systému |
| **fwupd + LVFS** | Aktualizácie firmvéru, dobre udržiavané | Len firmvér |
| **libratbag/Piper, OpenRazer, Solaar, OpenRGB, ckb-next, xpadneo/xone, input-remapper** | Plná funkčnosť konkrétnych periférií | Každý zvlášť, používateľ musí vedieť, že existujú; Piper má dlhodobo málo maintainerov a nesúlad API verzií s ratbagd |

**Záver:** medzera je reálna. Nikto nerobí mapovanie *zariadenie → najlepší userland nástroj → jeho funkcie v jednom UI*.

Poznámka k názvu: „UPnP“ je obsadený sieťový protokol (Universal Plug and Play). **LPnP** je v poriadku a nezamieňa sa.

## 3. LPnP – vrstvy

1. **Pripojené zariadenie** – USB, Bluetooth, PCIe, sieť, HID, monitory (EDID).
2. **Linux kernel + udev + sysfs** – nemeníme. lpnpd počúva udev (netlink), číta modalias, sysfs, BlueZ D-Bus, DRM/KMS, fwupd D-Bus.
3. **lpnpd** (Rust, systémová služba, D-Bus `org.latteos.Lpnp1`), moduly:
   - **Discovery** – udev udalosti → normalizovaný „DeviceRecord“ (bus, vendor, product, subsystem, aktuálny kernel driver, firmware verzia).
   - **Capability Detection** – čo zariadenie fyzicky vie (z DB) vs. čo je práve dostupné (z načítaného ovládača). Rozdiel = „úroveň funkčnosti“: Nefunguje / Základná / Plná.
   - **Driver Resolver** – vyberie poskytovateľov (provider) z DB, zoradí ich podľa kanála, dôvery a konfliktov.
   - **Feature Mapping** – prekladá funkcie poskytovateľov do spoločného slovníka (`dpi`, `polling_rate`, `rgb`, `battery`, `buttons`, `profiles`, `firmware`…).
   - **Configuration API** – jednotné čítanie/zápis funkcií; pod kapotou volá D-Bus OpenRazer, ratbagd, Solaar, OpenRGB SDK, ddcutil…
   - **Firmware Management** – tenká vrstva nad fwupd, nič vlastné.
   - **Recovery** – snapshoty, zdravotná kontrola po bootovaní, rollback (viď kap. 5).
4. **Compatibility Database (LPnP Atlas)** – samostatne aktualizovaná, podpísaná.
5. **Device Manager** – jedno miesto pre všetky zariadenia a ich funkcie.

### Tok pri pripojení myši Razer

1. udev: nové USB HID zariadenie, vendor Razer → beží `usbhid`, funguje kurzor a tlačidlá.
2. Capability Detection: Atlas hovorí, že model vie DPI, polling, RGB, batériu → stav **Základná funkčnosť**.
3. Resolver: poskytovatelia `openrazer` (plné funkcie) a `libratbag` (časť funkcií); navzájom konfliktné → navrhne jedného.
4. Device Manager zobrazí kartu: „Myš funguje základne. Pre DPI, RGB a batériu odporúčam OpenRazer. [Nainštalovať] [Viac]“.
5. Po súhlase: inštalácia ako nová ostree deployment + služba; Feature Mapping sprístupní posuvník DPI, farby, stav batérie priamo v Device Manageri (nie v cudzej appke). *(Kontrola bod 2: dnes dnf + snapper.)*

Rovnako Logitech → Solaar (HID++), Xbox ovládač → xpadneo/xone, Realtek USB Wi-Fi → out-of-tree modul, monitor → ddcutil (jas, vstup cez DDC/CI).

### Formát záznamu v Atlase (návrh)

```toml
[device]
match = { bus = "usb", vendor = "1532", product = "XXXX" }  # príklad, Razer
class = "mouse"
capabilities = ["dpi", "polling_rate", "rgb", "battery", "buttons"]

[base]
kernel_driver = "usbhid"
provides = ["buttons"]

[[provider]]
id = "openrazer"
kind = "kmod+daemon"
packages = { fedora = "openrazer-meta" }
provides = ["dpi", "polling_rate", "rgb", "battery"]
channel = "stable"
trust = "community"
conflicts = ["libratbag"]
secure_boot = "needs-signed-kmod"

[[provider]]
id = "libratbag"
kind = "daemon"
provides = ["dpi", "buttons"]
channel = "stable"
```

- Zdroj pravdy = git repozitár TOML záznamov; CI ich skompiluje do SQLite a podpíše.
- **Automatický import z upstreamu**: pci.ids/usb.ids (hwdata), zoznamy zariadení libratbag (`data/devices`), OpenRazer, Solaar, OpenRGB, LKDDb, profily chwd, metadáta LVFS. Bot vytvorí návrh záznamu, človek ho len schváli.
- Bez telemetrie. Voliteľné, štandardne vypnuté: anonymné hlásenie „funguje / nefunguje“ ako pri hw-probe.

## 4. Ovládače GPU a „ešte nevydané“ verzie

| Kanál | Obsah | Kto ho dostane |
| --- | --- | --- |
| **Stable** | NVIDIA open kernel moduly aktuálnej vetvy, stabilný kernel a Mesa | Predvolené pre všetkých |
| **Tested** | Novší NVIDIA/Mesa/kernel, ktoré prešli testami na testovacom stroji | Používateľ sa prihlási |
| **Bleeding** | NVIDIA beta, mesa-git, kernel RC | Len výslovný súhlas + varovanie |

- **„Nepodpísané a nevydané“ nikdy automaticky.** Pri zapnutom Secure Boot sa nepodpísaný modul nenačíta; LPnP ponúkne zápis vlastného kľúča (MOK) so sprievodcom, ale Secure Boot nikdy potichu nevypne.
- Proprietárne ovládače LatteOS **neredistribuuje** – inštaluje ich z repozitárov (RPM Fusion / negativo17 / NVIDIA).
- Každá zmena ovládača = návratový bod (návrh: ostree deployment; dnes snímka snapper, kontrola bod 2).
- Pre staré/nepodporované karty („10-ročné GPU aspoň degradovane“): DB pozná aj záložného poskytovateľa – legacy vetvu NVIDIA alebo nouveau/NVK – a vie povedať, čo tým stratíš.

## 5. Recovery – štyri stupne

1. **Rollback nastavení** – každá zmena v Configuration API má snapshot (zlé DPI, zlý RGB profil).
2. **Vypnutie poskytovateľa** – služba stop + blacklist modulu, zariadenie spadne na základný kernel driver.
3. **Systémový rollback** – ak po inštalácii ovládača zlyhá zdravotná kontrola bootu (štýl greenboot: grafika nabehla? compositor žije? sieť?), systém sa sám vráti (ostree, dnes snapper).
4. **Núdzový režim** – labwc „emergency/greeter“ (SAFE, kat. 5) + bezpečný displejový režim (kap. 6).

## 6. DisplayKit (latte-displayd)

### Kde je dnes Linux

- Štandard pre farby a HDR je Wayland protokol **color-management-v1** (wayland-protocols 1.41, február 2025); GNOME od 48, Qt 6.10/6.11, wlroots.
- Hyprland (ICC per monitor, automatické HDR pri fullscreen) a KDE Plasma 6.7 (ICC aj v HDR, zvlášť pre SDR a HDR) — vzor pre UX.

latte-displayd **nerenderuje farby sám** – to robí kompozitor. Jeho úloha je model, profily, pravidlá, bezpečnosť a UI.

### Architektúra

- **Compositor Adapter** – `pleamar-wm`, generický `wlr-output-management-v1` (kontrola bod 3). Adaptér hlási, čo kompozitor vie (HDR, ICC v HDR, VRR…), a Pegboard nepodporované voľby len zošedí.
- **Identita monitora = odtlačok EDID** (výrobca, model, sériové číslo, hash), nie názov konektora.
- **Zostava (Setup)** = množina odtlačkov → kompletné rozloženie; rovnaká množina monitorov → zostava sa obnoví sama (princíp kanshi/shikane). Príklady: „Doma – 2 monitory“, „Doma + TV“, „Notebook sám“.
- **Bezpečné aplikovanie** – po zmene 15 s odpočet „Ponechať / Vrátiť“; každá zostava má „posledný funkčný stav“; skratka na bezpečný režim (natívne rozlíšenie, 60 Hz, SDR, mierka 1) funguje aj z čierneho obrazu.

### Čo zostava ukladá pre každý monitor

```json
{
  "fingerprint": "edid:…",
  "position_mm": [0, 0],
  "mode": { "w": 2560, "h": 1440, "hz": 165 },
  "scale": 1.25,
  "rotation": 0,
  "vrr": "fullscreen",
  "bitdepth": 10,
  "hdr": { "enabled": true, "sdr_brightness_nits": 203, "peak_nits_override": null },
  "icc": { "sdr": "…/monitor-sdr.icc", "hdr": null },
  "night_light": "follow-system",
  "wallpaper": "…"
}
```

### Funkcie

- **Zmiešané DPI** – mierka z fyzickej veľkosti z EDID, frakčná mierka; **mikrozoom** (8B.07) ako vlastnosť Pegboardu; polohy v mm.
- **HDR** – prepínač per monitor, „HDR len pre hry/fullscreen“ vs. „HDR desktop“, jas SDR obsahu v HDR, kalibračný sprievodca (vzory ako Windows HDR Calibration), ručná oprava maximálneho jasu pri zlých EDID.
- **Farebné profily** – import ICC, oddelené ICC pre SDR a HDR (kde to kompozitor vie), ArgyllCMS/DisplayCAL na meranie kolorimetrom; nočné svetlo v tom istom farebnom reťazci.
- **Obnovovacia frekvencia** – predvolene najvyššia, VRR vypnuté/zapnuté/len fullscreen, pravidlá per aplikácia (hra → 165 Hz + VRR, video → násobok 24/25 Hz).
- **Hardvér monitora cez LPnP** – jas a vstup cez DDC/CI (ddcutil), firmvér cez fwupd, v Atlase **quirks** (chybné HDR metadáta v EDID, zlyhanie pri 10 bitoch…).
- **Prepojenie s Workfieldom** – uložené pracovné prostredie si pamätá aj zostavu monitorov a farebnú teplotu (10M.05).

### Pegboard v Nastaveniach – rozšírenie

- Plátno: monitory ako magnetické dlaždice v reálnych rozmeroch; odznaky **HDR · VRR · 165 Hz · ICC · 125 %**.
- Hore výber zostavy (+ „Uložiť ako novú“).
- Klik na monitor → bočný panel so záložkami **Režim · Mierka · Farby · HDR · Hardvér (DDC, firmvér) · Tapeta**.
- Monitory iných zariadení v domácej sieti neskôr ako ďalšie dlaždice so značkou siete (odtlačok `net:<zariadenie>/<výstup>`, 19.06).

## 7. Etapy (v návrhu „0.6.0–0.7“, kontrola bod 1)

1. **E1** – kostra lpnpd: Discovery + Atlas iba na čítanie + Device Manager ukazuje úroveň funkčnosti a návrhy (nič neinštaluje).
2. **E2** – inštalácia poskytovateľov s návratom; prvých ~20 záznamov: NVIDIA, Logitech/Solaar, Razer/OpenRazer, libratbag, Xbox (xpadneo/xone), 8BitDo, Realtek USB Wi-Fi.
3. **E3** – latte-displayd: odtlačky EDID, zostavy, automatické obnovenie, bezpečné aplikovanie, Pegboard v2.
4. **E4** – HDR a ICC cez adaptéry, kalibračný sprievodca, DDC/CI.
5. **E5** – kanál Tested/Bleeding, komunitný feed Atlasu, Configuration API pre všetky funkcie v Device Manageri.

## 8. Riziká

- **Údržba databázy** – automatický import z upstreamu a schvaľovanie človekom.
- **Konflikty poskytovateľov** (OpenRazer vs. libratbag) – Resolver aktivuje vždy iba jedného.
- **Rozdiely kompozitorov** v HDR/ICC – adaptéry a zošedené voľby, nie sľuby v UI.
- **Secure Boot a out-of-tree moduly** – podpisovanie (akmods + MOK) od začiatku.
- **Licencie** – proprietárne ovládače iba inštalovať z ich repozitárov, nikdy nebaliť do obrazu LatteOS.
