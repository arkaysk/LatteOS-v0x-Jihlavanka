#!/bin/sh
# build.sh AARAMBH_TREE: put LatteOS's theme and the mouse patch into a checkout of Aarambh
# (github.com/NarkAgni/aarambh, GPL-3.0; made against d2611d9 of 12. 11. 2026) and build aarambh.efi there
# (ROADMAP 3.11). Needs gnu-efi-devel. Running it twice changes nothing more.
set -eu
tree="${1:?usage: build.sh AARAMBH_TREE}"
here="$(cd "$(dirname "$0")" && pwd)"
# the mouse and touch (mouse.patch): applied once; the theme fills the tiles' places it reads
# and a loader on another partition (other-disk.patch: Windows on its own disk), each applied once
for p in mouse other-disk; do
    git -C "$tree" apply --reverse --check "$here/$p.patch" 2>/dev/null || git -C "$tree" apply "$here/$p.patch"
done
mkdir -p "$tree/src/themes/latteos"
cp "$here/latteos.c" "$tree/src/themes/latteos/latteos.c"
reg="$tree/src/core/theme_registry.c"
grep -q latteos_theme "$reg" || sed -i \
    -e 's/^extern const Theme cinema_theme;/&\nextern const Theme latteos_theme;/' \
    -e 's/^\( *\)&cinema_theme,/&\n\1\&latteos_theme,/' "$reg"
grep -q '&latteos_theme' "$reg" || { echo "build.sh: the theme could not be registered in $reg" >&2; exit 1; }
# the names `aarambh --theme` and scripts/install.sh accept
grep -q '^THEMES=".*latteos' "$tree/hooks/bin/aarambh" || sed -i 's/^THEMES="\(.*\)"/THEMES="\1 latteos"/' "$tree/hooks/bin/aarambh"
make -C "$tree" -j"$(nproc)" >/dev/null
echo "$tree/build/aarambh.efi"
