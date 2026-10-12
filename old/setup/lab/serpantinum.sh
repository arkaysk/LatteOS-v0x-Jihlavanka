#!/usr/bin/env bash
# setup/lab/serpantinum.sh — Serpantinum (github.com/ilyamiro/serpantinum, shell v Quickshelli) ako samostatné
# prostredie na pokusy, oddelené od LatteOS (30. 9. 2026). Autorov inštalátor NESPÚŠŤAME: podporuje iba Arch,
# posiela telemetriu, zapne SDDM namiesto greetd (prihlasovacia obrazovka LatteOS by zmizla) a prepíše
# ~/.config/hypr, kitty, cava, fastfetch. Tu:
#   · balíky z Fedory (satty a wl-gammarelay-rs nie sú → cargo do vlastného priečinka, ak pôjdu)
#   · program do ~/.local/share/serpantinum (jeho vlastný priečinok, ako u autora), nastavenia ~/.config/serpantinum
#   · Hyprland pre Serpantinum v ~/.config/serpantinum-hypr (nie ~/.config/hypr); EasyEffects iba v jeho relácii
#     (autor ho zapína natrvalo: `systemctl --user enable` — bežal by aj v LatteOS)
#   · relácia „Serpantinum“ na prihlasovacej obrazovke (latte-serpantinum)
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
S="$HOME/.local/share/serpantinum"
src="$S/zdroj"
echo "== balíky"
sudo dnf install -y -q --skip-unavailable kitty cava zbar pavucontrol alsa-utils wl-clipboard fd-find qt6-qtmultimedia \
    qt6-qt5compat ripgrep cliphist jq socat inotify-tools pamixer brightnessctl ddcutil acpi iw bluez libnotify \
    NetworkManager lm_sensors bc matugen pipewire wireplumber pipewire-pulseaudio pipewire-alsa pulseaudio-libs python3 \
    ImageMagick wget2-wget file git psmisc fastfetch python3-websockets qt6-qtwebsockets grim playerctl \
    xdg-desktop-portal-gtk slurp wmctrl easyeffects nautilus qt5-qtwayland qt5-qtquickcontrols qt5-qtquickcontrols2 \
    qt5-qtgraphicaleffects qt6-qtwayland qt5ct qt6ct gpu-screen-recorder wf-recorder adw-gtk3-theme
echo "== zdroj"
if [ -d "$src/.git" ]; then git -C "$src" pull --ff-only --quiet || echo "nedá sa aktualizovať"
else mkdir -p "$S"; git clone --quiet https://github.com/ilyamiro/serpantinum.git "$src"; fi
echo "serpantinum: $(git -C "$src" log --oneline -1) (verzia $(cat "$src/version.txt"))"
mkdir -p "$S/bin" "$S/src"
cp -r "$src/bin/." "$S/bin/"; cp -r "$src/src/." "$S/src/"
echo "== satty a wl-gammarelay-rs (nie sú vo Fedore)"
sudo dnf install -y -q gtk4-devel libadwaita-devel libepoxy-devel     # satty sa prekladá proti GTK 4
for c in satty wl-gammarelay-rs; do
    command -v "$c" >/dev/null || [ -x "$S/bin/$c" ] || cargo install --locked --quiet --root "$S/cargo" "$c" \
        && { [ -x "$S/cargo/bin/$c" ] && ln -sf "$S/cargo/bin/$c" "$S/bin/$c"; true; } \
        || echo "  $c sa nepreložil — táto funkcia Serpantinumu nepôjde"
done
echo "== nastavenia (iba tie jeho, kitty/cava/fastfetch nechávame tvoje)"
[ -f "$HOME/.config/serpantinum/settings.json" ] || install -Dm644 "$src/config/serpantinum/settings.json" "$HOME/.config/serpantinum/settings.json"
H="$HOME/.config/serpantinum-hypr"
mkdir -p "$H"; cp -r "$src/compositors/hyprland/." "$H/"
# EasyEffects iba počas tejto relácie, nie natrvalo pre všetky prostredia
sed -i 's|hl.exec_cmd("systemctl --user enable --now easyeffects")|hl.exec_cmd("easyeffects --gapplication-service")  -- LatteOS: iba v tejto relácii|' "$H/config/autostart.lua"
echo "== relácia na prihlasovacej obrazovke"
sudo install -m755 "$here/session/bin/latte-serpantinum" /usr/bin/latte-serpantinum
sudo install -Dm644 "$here/session/wayland-sessions/serpantinum.desktop" /usr/share/wayland-sessions/serpantinum.desktop
echo "hotovo"
