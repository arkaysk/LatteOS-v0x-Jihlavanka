# latte-lab — reálne testovacie PC

28. 9. 2026 · @Arkay

ASUS Rampage IV Gene (X79) · i7-4820K · 16 GB · AMD RX 550 (Polaris, RADV) · WD 500 GB · len kábel.
Po inštalácii stojí pri switchi bez monitora a všetko ide z hlavného PC (SSH, VS Code, Cockpit, Moonlight).

Postup: **ručne** BIOS a Anaconda (~20 min, disk sa delí raz a s ohľadom na Bazzite), potom **jeden príkaz**
cez SSH: `setup/lab/install.sh`.

## 1. BIOS (Del pri štarte)

- Load Optimized Defaults → UEFI boot, SATA **AHCI**.
- **Wait for 'F1' If Error → Disabled** (štart bez klávesnice).
- APM: **Restore AC Power Loss → Power On**, **Power On By PCIE/PCI → Enabled**, **ErP Ready → Disabled**
  (bez toho sieťovka vo vypnutom PC nemá prúd a Wake-on-LAN nejde).
- F10, pri štarte **F8** → USB ako `UEFI: …`. USB kľúč do **čierneho USB 2.0** portu vzadu
  (modré USB 3.0 sú na čipe ASMedia a zavádzanie z nich býva nespoľahlivé; biely ROG Connect nie).

## 2. Disk 500 GB (= 465 GiB) — Fedora, Bazzite, Dáta

| # | Oddiel | Veľkosť | Súborový systém | Kto |
|---|---|---|---|---|
| 1 | EFI Fedora | 1 GiB | FAT32 `/boot/efi` | Fedora |
| 2 | boot Fedora | 2 GiB | ext4 `/boot` | Fedora |
| 3 | Fedora | 120 GiB | Btrfs, subvolúmy `root` → `/`, `home` → `/home` | Fedora |
| 4 | Dáta | 220 GiB | Btrfs `/data` (samostatný oddiel, nie subvolúm oddielu 3) | spoločné |
| — | **voľné** | ~122 GiB | nič | neskôr Bazzite |

- 100 GiB na systém stačí (vývojová VM má celý disk 52 GB). 120 dáva rezervu na snímky Btrfs a Ollama modely;
  **hry, ISO a veľké modely patria na `/data`**, tam ich uvidí Fedora aj Bazzite (Steam knižnica na `/data/steam`).
- V Anaconde: *Installation Destination → Advanced Custom (Blivet-GUI)*. Pri `/data` zvoliť nový oddiel
  (partition), nie subvolúm v Btrfs oddielu Fedory. Zvyšok disku nechať **nerozdelený**.

### Bazzite neskôr: vlastné EFI

Fedora aj Bazzite zapisujú zavádzač do `EFI/fedora/` — pri spoločnom EFI oddiele by Bazzite prepísal zavádzač
Fedory. Bazzite preto dostane **vlastný EFI a boot**. Pred inštaláciou Bazzite ich vytvor z Fedory cez SSH
(disk `sda` over cez `lsblk`):

```
sudo dnf -y install gdisk
sudo sgdisk -n 0:0:+1G -t 0:ef00 -c 0:bazzite-efi \
            -n 0:0:+2G -t 0:8300 -c 0:bazzite-boot \
            -n 0:0:0   -t 0:8300 -c 0:bazzite-root /dev/sda
lsblk -o NAME,SIZE,PARTLABEL /dev/sda
```

V inštalátore Bazzite potom *priradenie prípojných bodov*: `bazzite-efi` → `/boot/efi` (formátovať),
`bazzite-boot` → `/boot`, `bazzite-root` → `/`, `/data` nechať bez zmeny.

Prepínanie systémov bez monitora: oba zápisy v UEFI sa volajú „Fedora“, líšia sa oddielom (`efibootmgr -v`).
Z bežiaceho systému cez SSH: `sudo efibootmgr --bootnext XXXX && sudo reboot` — raz naštartuje druhý systém,
potom sa vráti na predvolený. Wake-on-LAN treba zapnúť v každom systéme zvlášť (`nmcli`, pozri `install.sh`).

## 3. Anaconda

English, klávesnica sk + us, Europe/Bratislava, hostname **latte-lab**, sieť automaticky, root uzamknutý,
používateľ **arkay** (administrátor), softvér predvolený Fedora Server. Po reštarte vytiahnuť USB.

## 4. Sieť: stála adresa

Switch len rozvádza, adresy prideľuje router (optický modem). Tri možnosti, stačí jedna:

1. **Nič nenastavovať:** `install.sh` zapne mDNS, takže z Windowsu funguje `ssh arkay@latte-lab.local`
   aj `https://latte-lab.local:9090`, nech má PC akúkoľvek adresu. Moonlight hľadá PC tiež cez mDNS.
2. **DHCP rezervácia v routeri** (najčistejšie): MAC adresa → stála IP. Platí aj pre Bazzite (rovnaká sieťovka).
3. **Pevná adresa mimo rozsahu DHCP:** v routeri pozrieť rozsah (napr. `.100–.199`), zvoliť adresu mimo neho
   (napr. `.50`) a `setup/lab/install.sh --ip 192.168.1.50/24 --gw 192.168.1.1`. Nastaví sa iba vo Fedore.

## 5. Prvé kroky s monitorom, potom jeden príkaz

Na latte-lab: `ip -4 -br a` (adresa). Z hlavného PC (PowerShell) skopírovať kľúč:

```
type $env:USERPROFILE\.ssh\id_ed25519.pub | ssh arkay@<IP> "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
```

Potom už cez SSH:

```
sudo dnf -y install git
git clone -b gamerdistro https://github.com/arkaysk/jihlavanka001 && cd jihlavanka001
setup/lab/install.sh
```

`install.sh` (opakovateľný, záznam v `~/latte-lab-install.log`):

1. snímka Btrfs pred zmenami (`snapper`),
2. `dnf upgrade`,
3. SSH (heslo sa vypne, iba ak je uložený kľúč), Cockpit, mDNS, firewall,
4. Wake-on-LAN, prípadne pevná adresa,
5. RPM Fusion + VA-API s H.264/HEVC pre AMD (kódovanie pre Sunshine),
6. `setup/f0-install.sh` (balíky; VirtualBox časť sa na reálnom PC preskočí),
7. `setup/f1/install-session.sh` (latte-boot, relácie, greeter, GRUB SAFE, Plymouth),
8. kontrola: ovládač GPU, Vulkan, `latte-boot status` (čakáme `renderer = hw`), adresa.

Grafický štart zapne až `setup/lab/install.sh --enable`, keď kontrola vyjde a SSH aj Cockpit fungujú.
Potom test bez periférií: `sudo poweroff`, odpojiť monitor a klávesnicu, zobudiť Wake-on-LAN, `ssh latte-lab.local`.

## Neskôr (nie je v skripte)

- Dummy zástrčka do DP → Sunshine + Moonlight, automatické prihlásenie cez greetd do `latte-session`.
- `latte-shell` (fork Noctalie) sa postaví, iba ak je zdroj v `~/latte-shell`; inak beží Noctalia z COPR.
- `hyprland-latte` (vmwgfx záplata) na reálnom PC netreba; Hyprland ostáva z COPR `lionheartp/Hyprland`
  a jeho aktualizácie z COPR blokuje `excludepkgs` (pluginy sú postavené proti nainštalovanej verzii).
