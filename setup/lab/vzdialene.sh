#!/usr/bin/env bash
# setup/lab/vzdialene.sh — latte-lab na diaľku bez monitora, myši a klávesnice: Sunshine (server na latte-lab)
# + Moonlight (klient na pracovnom PC). Spustiť raz (dá sa znova): sudo setup/lab/vzdialene.sh [používateľ]
#   · Sunshine z oficiálneho COPR autorov (lizardbyte/stable), používateľská služba v každej relácii LatteOS
#     (graphical-session.target — klasická aj Kvapky); snímanie cez Wayland (wlr), aby šla aj virtuálna obrazovka;
#     kódovanie grafickou kartou (VAAPI)
#   · porty Sunshine vo firewalle (iba zóna s LAN káblom k pracovnému PC)
#   · automatické prihlásenie po štarte (greetd initial_session): Sunshine je hneď dostupný; po odhlásení
#     sa ukáže prihlasovacia obrazovka
#   · virtuálna obrazovka bez monitora: robí hyprland.lua (LATTE-VIRT 1920×1080)
# Potom na pracovnom PC: Moonlight (winget install MoonlightGameStreamingProject.Moonlight) → pridať 192.168.137.231
# → PIN zadať na https://192.168.137.231:47990 (pri prvej návšteve si tam vytvoríš meno a heslo správcu).
set -euo pipefail
user="${1:-${SUDO_USER:-arkay}}"
[ "$(id -u)" = 0 ] || { echo "spusti cez sudo"; exit 1; }
id "$user" >/dev/null

echo "== Sunshine (COPR lizardbyte/stable)"
dnf copr enable -y lizardbyte/stable >/dev/null
rpm -q Sunshine >/dev/null || dnf install -y Sunshine
udevadm trigger --subsystem-match=misc --action=change 2>/dev/null || true     # /dev/uinput pre prihláseného (uaccess)

echo "== nastavenie Sunshine pre $user (snímanie cez Wayland, kódovanie VAAPI)"
home="$(getent passwd "$user" | cut -d: -f6)"
conf="$home/.config/sunshine/sunshine.conf"
install -d -o "$user" -g "$user" "$home/.config/sunshine"
if [ ! -f "$conf" ]; then
    cat > "$conf" <<'EOC'
# LatteOS (setup/lab/vzdialene.sh): Hyprland — snímanie cez wlr-screencopy zvládne aj virtuálnu obrazovku
# LATTE-VIRT (KMS vie iba fyzický monitor); kódovanie grafickou kartou
capture = wlr
encoder = vaapi
sunshine_name = latte-lab
EOC
    chown "$user:$user" "$conf"
fi
# zapnutie používateľskej služby = odkaz vo wants (to isté, čo robí `systemctl --user enable`, ale bez bežiacej relácie)
wants="$home/.config/systemd/user/graphical-session.target.wants"
install -d -o "$user" -g "$user" "$home/.config/systemd" "$home/.config/systemd/user" "$wants"
ln -sf /usr/lib/systemd/user/app-dev.lizardbyte.app.Sunshine.service "$wants/app-dev.lizardbyte.app.Sunshine.service"
chown -h "$user:$user" "$wants/app-dev.lizardbyte.app.Sunshine.service"

echo "== firewall (porty Sunshine)"
zone="$(firewall-cmd --get-default-zone)"
for p in 47984/tcp 47989/tcp 47990/tcp 48010/tcp 47998/udp 47999/udp 48000/udp 48002/udp 48010/udp; do
    firewall-cmd -q --permanent --zone="$zone" --add-port="$p"
done
firewall-cmd -q --reload

echo "== automatické prihlásenie ($user) po štarte"
cfg=/etc/greetd/config.toml
if ! grep -q '^\[initial_session\]' "$cfg"; then
    printf '\n# latte-lab na diaľku (setup/lab/vzdialene.sh): po štarte rovno prihlásiť, Sunshine je hneď dostupný;\n# po odhlásení sa ukáže prihlasovacia obrazovka\n[initial_session]\ncommand = "/usr/bin/latte-session"\nuser = "%s"\n' "$user" >> "$cfg"
fi
echo "hotovo — na pracovnom PC: Moonlight → pridať $(hostname -I | awk '{print $1}') → PIN na https://$(hostname -I | awk '{print $1}'):47990"
