# Patche nad upstreamom

## vmwgfx dmabuf — patch proti čiernej obrazovke vo VM

| Súbor | Cieľ | Overené |
|---|---|---|
| `hyprland-0.56.2-vmwgfx-dmabuf.patch` | Hyprland `src/protocols/LinuxDMABUF.cpp` | `git apply --check` na tagu **v0.56.2**, teda na verzii balíka v COPR `lionheartp/Hyprland` |
| `hyprland-main-vmwgfx-dmabuf.patch` | to isté, vetva `main` | `git apply --check` na `23118f9f7f24` (= `hyprland-git` v COPR); `LOGM` → `LOG` |
| `wlroots-vmwgfx-dmabuf.patch` | wlroots `types/wlr_linux_dmabuf_v1.c` (labwc, SAFE režim) | `git apply --check` na 0.21-dev (`297e01d2d4a7`) |

**Autor:** Pascal-0x90, [hyprwm/Hyprland diskusia #12966](https://github.com/hyprwm/Hyprland/discussions/12966) (31. 8. 2026).
Do upstreamu zatiaľ nie je začlenený. Pôvodný balík opráv
`ClaireDuSoleil/hyprland-vmware-fix` už neexistuje (404).

**Príznak:** Hyprland štartuje, ale ukáže čiernu plochu, prípadne len kurzor. GPU klienti (kitty,
alacritty, Quickshell, tapeta) padnú na prvom snímku s chybou
`invalid arguments for wl_surface.attach`.

**Príčina:** kernelový ovládač `vmwgfx` pri importe dmabuf-u (`vmw_prime_fd_to_handle`) vráti
**TTM** handle namiesto GEM handle. Kompozitor ho potom nevie zavrieť cez `drmCloseBufferHandle`
(EINVAL) a klienta odpojí.

**Oprava:** ak `drmCloseBufferHandle` zlyhá a zariadenie je `vmwgfx`, handle sa uvoľní cez
`DRM_VMW_UNREF_SURFACE`. Na iných ovládačoch sa správanie nemení.

**Týka sa aj VirtualBoxu:** grafický adaptér VMSVGA sa v hosťovi hlási ako `VMware SVGA II
[15ad:0405]` a používa rovnaký ovládač `vmwgfx`. Overené na `latteOSdev`.
Chyba sa prejaví iba pri **zapnutej 3D akcelerácii**. Bez nej Mesa nepoužije ovládač `svga`
a klienti kreslia cez llvmpipe a zdieľanú pamäť.

Doplnkové nastavenia pre VM (nie sú súčasťou patchu, pozri ROADMAP F1):
`cursor { no_hardware_cursors = true }` a pri problémoch `LIBGL_ALWAYS_SOFTWARE=1` pre klientov.

## noctalia-bar-blur-capsules.patch (29. 9. 2026, latte-lab)

Noctalia (5.2, 9287a78) žiada kompozitor (ext-background-effect) o rozmazanie **celého obdĺžnika lišty**,
aj keď je lišta priehľadná (`background_opacity = 0`) a vidieť iba ostrovy → po celej šírke mliečny pás.
Záplata: pri priehľadnej lište rozmaže iba zaoblené obdĺžniky kapsúl a prepočíta ich po každom rozložení.
Vhodná na upstream PR. Použitie: `git apply` v zdroji Noctalie (alebo forku latte-shell), potom
`LATTE_SHELL_SRC=<zdroj> setup/f1/build-latte-shell.sh`.

## pleamar-hyprland-okna-8bit.patch (29. 9. 2026, latte-lab, pleamar 5f9cd54)

Dve opravy pre Kvapky, obe vhodné na upstream:
1. **Zoznam okien na Hyprlande.** Služba `window` cez socket Hyprlandu hlási iba aktívne okno (bez `list`) a príkazy
   `window.*` nepozná. `PLEAMAR_GENERIC=1` to obišlo, no vypne aj `cursor.x/y` (myš mimo scény). Záplata:
   `PLEAMAR_GENERIC=window` (zoznam oddelený čiarkami) pošle cez všeobecné protokoly (wlr-foreign-toplevel) iba to,
   čo menuje; kurzor ostáva z Hyprlandu. `=1` sa správa ako doteraz.
2. **Farby o tón svetlejšie.** RADV ponúka ako prvý nesRGB formát `Rgba16Float`; Hyprland ho berie ako lineárne
   svetlo a zakóduje ešte raz → káva #1c0f09 vyšla ako #5c4333. Záplata uprednostní `Bgra8Unorm`/`Rgba8Unorm`.

3. **Ťahanie aj pravým tlačidlom.** pleamar začína ťahanie (`on drag`) iba ľavým; lišta-kvapka sa má dať presunúť
   ľavým aj pravým (ako panel úloh). Záplata: pravé tlačidlo nad zónou začne to isté ťahanie a jeho pustenie ho
   ukončí (`on release`); `on press right` ostáva, takže scéna rozlíši ľavý klik od pravého.

4. **Ikony podľa mena.** pleamar hľadal iba v `/usr/share/icons` a v domove, bez `XDG_DATA_DIRS` (ikony Flatpaku),
   bez rozloženia Breeze (`apps/48/…`) a bez AdwaitaLegacy → `system-file-manager`, `org.mozilla.firefox` sa
   nenačítali. Záplata: všetky `…/icons` z `XDG_DATA_DIRS`, téma z `PLEAMAR_ICON_THEME`/`QS_ICON_THEME` ako prvá,
   veľkosti oboch zápisov (48x48 aj 48) a kontext `legacy`.

5. **Viac odberateľov služby okien.** `window` (a `workspaces`) cez wlr-foreign-toplevel mala jediné miesto pre
   odberateľa: `service window` v scéne a `sys.watch("window")` v jej logike sú dvaja, druhý prvého vytlačil a scéna
   ostala so starým zoznamom — v lište guľôčky okien, ktoré už neexistovali (nedali sa kliknúť ani zavrieť).
   Záplata: zoznam odberateľov, zmenu dostanú všetci.

Použitie: `git apply` v `resources/upstream/pleamar`, potom `cargo build --release`.

## pleamar-wm-linearny-buffer.patch (pôvodná Marea, setup/lab/marea-povodna.sh)

pleamar-wm (k4ditano) žiada obrazový buffer iba s modifiermi. Na latte-lab (RX 640, GFX8) to radeonsi nevie
(`the card did not make a buffer of 1920×1080: No such file or directory`), obrazovka ostala čierna s textom
terminálu. Záplata: keď alokácia s modifiermi zlyhá, lineárny buffer (Vulkan ho preberá ako modifier 0) — ako
„modifier-less allocation“ v aquamarine (Hyprland). Kandidát na hlásenie autorovi (iba ak to používateľ chce).
