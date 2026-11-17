#!/bin/sh
# setup-latteos.sh: LatteOS's boot menu (ROADMAP 3.11), run by install as root when the boot menu was chosen.
# Aarambh (github.com/NarkAgni/aarambh, GPL-3.0), locked to one commit, with LatteOS's theme and the mouse (build.sh),
# installed by its own scripts/install.sh: on the EFI partition in EFI/aarambh, first in the firmware's boot order,
# signed through shim when Secure Boot is on, its kernel list kept by its hooks. GRUB and EFI/fedora stay as they are
# (the firmware's next entry); Plymouth stays LatteOS's (--no-plymouth). Then the menu's entries become LatteOS's:
# LatteOS, LatteOS SAFE (latte-bootmenu-safe), and Windows 11: always written, shown at boot only when its loader is on
# an EFI partition of this PC, this one or another disk's (other-disk.patch), so a Windows installed later shows too.
set -eu
here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/../.." && pwd)"
[ -d /sys/firmware/efi ] || { echo "boot menu: this PC starts without UEFI; GRUB stays"; exit 0; }
src="$repo/build/aarambh-src"
user="$(stat -c %U "$repo")"                      # built as whoever owns the tree (root after get, the user in a clone)
as_user() { if [ "$user" != root ]; then runuser -u "$user" -- "$@"; else "$@"; fi; }
[ -d "$src/.git" ] || as_user git clone -q https://github.com/NarkAgni/aarambh.git "$src"
as_user git -C "$src" fetch -q
as_user git -C "$src" checkout -q -f d2611d915a1c6d071a4a73f65d381f570580b230      # 0.1.7, 12. 11. 2026
as_user git -C "$src" clean -qfd
as_user sh "$here/build.sh" "$src" > /dev/null
as_user python3 "$here/make-assets.py" "$src/assets"
bash "$src/scripts/install.sh" --theme latteos --no-plymouth

. /etc/aarambh.env
conf="$ESP_DIR/aarambh.conf"
loader="$(awk -F'|' -v key="$KEY" '/^entry[ \t]/ { k = $5; gsub(/^[ \t]+|[ \t]+$/, "", k); if (k == key) { l = $2; gsub(/^[ \t]+|[ \t]+$/, "", l); print l; exit } }' "$conf")"
[ -n "$loader" ] || { echo "boot menu: Aarambh did not add this system to $conf" >&2; exit 1; }
gold="#e2aa5c"
win='\EFI\Microsoft\Boot\bootmgfw.efi'
{
    echo "entry LatteOS | $loader | logos/latteos.png | backgrounds/latteos.jpg | $KEY | $gold"
    echo "entry LatteOS SAFE | $loader | logos/safe.png | backgrounds/safe.jpg | latteos-safe | $gold"
    echo "entry Windows 11 | $win | logos/windows.png | backgrounds/windows.jpg | windows | $gold"
    # Aarambh's own lines but the entries replaced above (Firmware, Restart, Power Off stay)
    awk -F'|' -v key="$KEY" '/^entry[ \t]/ { k = $5; gsub(/^[ \t]+|[ \t]+$/, "", k); if (k == key || k == "latteos-safe" || k == "windows") next } { print }' "$conf" \
        | sed -e 's/^theme .*/theme latteos/' -e 's/^default .*/default 0/' -e 's/^timeout .*/timeout 5/'
} > "$conf.new"
# the entries go before the first entry line, after the settings
awk 'NR == FNR { if (/^entry LatteOS|^entry Windows 11/) e[++n] = $0; next }
     /^entry LatteOS|^entry Windows 11/ { next }
     /^entry[ \t]/ && !done { for (i = 1; i <= n; i++) print e[i]; done = 1 }
     { print }
     END { if (!done) for (i = 1; i <= n; i++) print e[i] }' "$conf.new" "$conf.new" > "$conf.tmp"
mv -f "$conf.tmp" "$conf"; rm -f "$conf.new"
/usr/libexec/latte-bootmenu-safe
systemctl enable latte-bootmenu-safe.service           # again at each start; after kernel updates, its kernel-install plugin
echo "boot menu: Aarambh with LatteOS's theme, first in the boot order; GRUB stays behind it"
