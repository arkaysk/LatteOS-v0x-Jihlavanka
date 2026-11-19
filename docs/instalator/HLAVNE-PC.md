# Inštalácia LatteOS na hlavné PC — kontrola hardvéru (19. 11. 2026)

Zdroj: súpis hardvéru z Windowsu (`HARDWARE-LINUX-MIGRACIA.md`, 19. 11.). Úloha ROADMAP **2.11**. Cesta inštalácie ako
na latte-lab: Fedora 45 Server → `get` → sprievodca (`apps/installer.qml`, `install`).

## Čo LatteOS na tomto PC zvládne samo

| Časť | Ako | Stav |
|---|---|---|
| RTX 3060 (`10DE:2487`, Ampere ≥ 0x1e00) | sprievodca ponúkne ovládač (2.10): RPM Fusion `akmod-nvidia` **615.78.08** pre F45 (overené 19. 11. v repozitári) + CUDA, otvorené moduly; balík sám odstráni `nomodeset` a zakáže `nouveau` aj `nova_core`; modul sa zostaví počas inštalácie | pripravené, **neoverené na skutočnej NVIDIA** |
| Secure Boot | ak je zapnutý: kľúč `kmodgenca` + `mokutil --import`; heslo ukáže sprievodca na konci → **pri prvom štarte byť pri PC** (MokManager: Enroll MOK → Continue → Yes → heslo) | pripravené |
| Bez iGPU (i5-11400F) | Fedora inštalátor a sprievodca bežia na `nouveau` (firmvér GSP z `nvidia-gpu-firmware` ostáva, karta je „nvidia“) | v poriadku |
| Ovládač zlyhá | `latte-session`: pleamar-wm nevidí výstup → **SAFE** (labwc, softvérové kreslenie) | pripravené |
| pleamar-wm na NVIDIA | upstream má kód pre NVIDIA (`GAMMA_LUT` namiesto gamma, issue #37); u nás neoverené (1D.01) | riziko, SAFE ako záchrana |
| Logitech (`046D`) | nová súčasť **solaar** (+ `solaar-udev`), sprievodca ju zaškrtne sám, keď je Logitech pripojený | **pridané 19. 11.** |
| ASUS Aura `0B05`, Corsair `1B1C` (svetlá) | nová súčasť **openrgb** (+ udev pravidlá), zaškrtne sa pri niektorom z nich | **pridané 19. 11.** |
| Razer Cobra `1532:00A3` (DPI, RGB, ako Synapse) | nová súčasť **openrazer-meta + polychromatic** z openSUSE OBS `hardware:razer` (Fedora_45; Cobra je v OpenRazer 3.12.4); modul cez DKMS, pri Secure Boot podpísaný **tým istým kľúčom MOK** ako NVIDIA (`/etc/dkms/framework.conf.d/latteos-mok.conf`); používatelia do `plugdev` | **pridané 19. 11.** |
| NZXT Kraken `1E71:300E` (pumpa, ventilátory, svetlá, ako CAM) | nová súčasť **coolercontrol** z COPR `codifryed/CoolerControl` (fedora-45), služba `coolercontrold` zapnutá | **pridané 19. 11.** |
| Ajazz AKP03E `0300:3002` (ako Ajazz Stream Dock) | nová súčasť **opendeck**: rpm z vydania OpenDeck 2.14.2 + doplnok 4ndv/opendeck-akp03 v0.11.0 (AKP03E rev. 2 = `0300:3002` podporovaný) do `~/.config/me.amankhanna.opendeck/plugins/`; pravidlá udev `system/udev/40-opendeck-akp03.rules` | **pridané 19. 11.** |
| LAN RTL8125, Wi-Fi/BT AX201, zvuk, USB headset, BT slúchadlá | jadro (`r8169`, `iwlwifi`, `btusb`, `snd-usb-audio`), PipeWire, BlueZ | v poriadku; slúchadlá znova spárovať |
| AI | `latte-ai` číta VRAM cez `nvidia-smi`; llama.cpp s Vulkanom beží aj na NVIDIA; 12 GB VRAM a 80 GB RAM unesú väčší model než 4B | v poriadku |
| Hry | Steam a herná relácia sa zaškrtnú (skutočná karta) | v poriadku |

## Čo sprievodca nevyrieši — urobiť ručne (aj v `docs/manual-inst.md`)

- **Acer Z301C 144 Hz:** pleamar-wm bez riadku `monitor` berie režim, ktorý EDID označí ako preferovaný — často 60 Hz.
  Po prihlásení: Nastavenia › Obrazovky › „Snímky za sekundu“ → 144. (Predvolene najvyšší → DisplayKit 8B.09.)
- **Dotyk ViewSonic TD2760:** pleamar-wm dotykové obrazovky **zatiaľ nepodporuje** (README: „Not yet: touch screens“).
  Monitor ako obraz funguje, dotyk nie (iba v SAFE/labwc). ROADMAP 1D.50.
- **Periférie po prvom spustení:** Polychromatic (Razer) — DPI a farby; CoolerControl — krivka pumpy a ventilátorov;
  OpenDeck — klávesy a gombíky docku (profily z Ajazz softvéru sa neprenášajú, nastaviť znova). Logitech C531: čo je k nemu
  spárované, ukáže Solaar.
- **Dátové disky NTFS** sa nepripájajú samy (2.01 nehotové): pripojiť ručne (`ntfs3`), Windows s vypnutým Rýchlym spustením.

## Disky — pozor (rozpor s pamäťou)

Pamäť hovorí „Windows 1 TB NVMe, LatteOS celý 4 TB NVMe, 2 TB dokumenty nikdy neformátovať“. Súpis z 19. 11. ukazuje:

| Disk | Windows | Obsadené |
|---|---|---|
| Samsung 990 EVO Plus **4 TB NVMe** | E: „Quick“ | **~1,84 TB dát** |
| Samsung 980 1 TB NVMe | C: Windows | 836 GB |
| WD Red **4 TB HDD** (SMR) | D: „games“ | ~2,3 TB |
| WD Green **2 TB HDD** (MBR) | H: „Data 2T“ | ~1,7 TB — **nikdy neformátovať** |

Ak má LatteOS dostať celý 4 TB NVMe, **najprv presunúť E:** (1,84 TB) inam — voľné je dosť na D: (1,44 TB) iba čiastočne.
V inštalátore Fedory vybrať **iba** 990 EVO Plus (dva disky 4 TB — NVMe vs. HDD, podľa modelu, nie veľkosti).
Windows ostáva na 980 → štart Windowsu cez ponuku dosky (F8) alebo GRUB; ponuku Aarambh sprievodca zaškrtne iba
pri vypnutom Secure Boot.

## Pred inštaláciou vo Windowse (ako admin)

1. `manage-bde -status` — BitLocker/šifrovanie zariadenia; dátové disky dešifrovať.
2. `Confirm-SecureBootUEFI` — či bude treba MOK.
3. `powercfg /h off` — vypnúť hibernáciu a Rýchle spustenie (inak NTFS iba na čítanie).
4. Záloha `C:\Users\…` (`.claude`, `.ssh`, `.gitconfig`), presun E: ak sa 4 TB NVMe maže.
5. Poznačiť DPI myši, krivky NZXT, profily Ajazz.

## Po inštalácii overiť

`nvidia-smi` · `cat /sys/module/nvidia_drm/parameters/modeset` (Y) · `dkms status` (openrazer installed) · Polychromatic vidí Cobru · CoolerControl vidí Kraken · OpenDeck vidí AKP03E · prihlásenie do LatteOS GOO (nie SAFE) · 144 Hz na
Aceri · Solaar vidí klávesnicu · OpenRGB vidí ASUS/Corsair · zvuk, BT, Wi-Fi, LAN 2,5 G. Výsledok zapísať do 1D.01 a 2.11.
