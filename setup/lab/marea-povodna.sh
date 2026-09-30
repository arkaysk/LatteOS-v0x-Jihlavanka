#!/usr/bin/env bash
# setup/lab/marea-povodna.sh — pôvodná Marea (k4ditano: pleamar, pleamar-wm, marea-plm) ako samostatné prostredie
# na pokusy, oddelené od LatteOS (30. 9. 2026). Robí to isté ako autorov install.sh, ale nie do ~/.local/bin
# (tam by prebila /usr/bin/pleamar s úpravami LatteOS pre Kvapky) a bez „skill“ pre AI agentov v ~/.claude.
#   setup/lab/marea-povodna.sh          stiahne alebo aktualizuje, preloží, uloží
# Spúšťa ju latte-marea (relácie „Marea (pleamar-wm)“ a „Marea (Hyprland)“ na prihlasovacej obrazovke).
set -euo pipefail
M="$HOME/.local/share/marea-povodna"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
command -v clang >/dev/null || sudo dnf install -y clang clang-devel
command -v swaybg >/dev/null || sudo dnf install -y swaybg          # tapeta v pleamar-wm
mkdir -p "$M/src" "$M/bin"
for r in pleamar pleamar-wm marea-plm; do
    if [ -d "$M/src/$r/.git" ]; then git -C "$M/src/$r" pull --ff-only --quiet || echo "$r: nedá sa aktualizovať"
    else git clone --quiet "https://github.com/k4ditano/$r.git" "$M/src/$r"; fi
    echo "$r: $(git -C "$M/src/$r" log --oneline -1)"
done
(cd "$M/src/pleamar" && cargo build --release --quiet)
(cd "$M/src/pleamar-wm" && cargo build --release --quiet)
for p in pleamar/target/release/pleamar pleamar-wm/target/release/pleamar-wm; do
    install -m755 "$M/src/$p" "$M/bin/$(basename "$p").new" && mv -f "$M/bin/$(basename "$p").new" "$M/bin/$(basename "$p")"
done
install -m755 "$M/src/pleamar-wm/session.sh" "$M/bin/pleamar-session"
ln -sf "$M/src/marea-plm/marea" "$M/bin/marea"
# relácie na prihlasovacej obrazovke a ich spúšťač
sudo install -m755 "$here/session/bin/latte-marea" /usr/bin/latte-marea
sudo install -Dm644 "$here/session/hypr/marea.lua" /usr/share/latteos/hypr/marea.lua
for v in wm hyprland; do sudo install -Dm644 "$here/session/wayland-sessions/marea-$v.desktop" "/usr/share/wayland-sessions/marea-$v.desktop"; done
echo "hotovo: $("$M/bin/pleamar" --version 2>/dev/null || echo pleamar) v $M"
