#!/usr/bin/env bash
# setup/lab/zaujmy.sh — „zoznam záujmov“ (ROADMAP F3·G, rozhodnutia 6. 10. 2026): programy, z ktorých možno prevezmeme
# funkcie, alebo sa nad nimi rozhodne, či ich použiť, alebo napísať vlastné. Nainštaluje ich na skúšanie (latte-lab).
# Nič nenastavuje ako predvolené a nič nezapája do LatteOS: iba aby sa dali spustiť a pozrieť.
#   setup/lab/zaujmy.sh              všetko okrem whisper-cpp
#   setup/lab/zaujmy.sh --whisper    aj whisper-cpp (POZOR: na Fedore 44 pritiahne knižnice ROCm, spolu ~570 balíkov, 6 GB)
# Kde čo je:
#   systém (dnf)        zoxide, syncthing, kde-connect, hyprsunset, fuse-libs (AppImage pre Voltage),
#                       libxkbcommon-x11-devel (preklad DiskTree)
#   Flathub (--user)    Newelle, Bazaar, Bottles, LocalSend, RustDesk
#   zo zdroja           ~/.local/bin: disktree, bumblebee, hyprsession, flea, hypruse, voltage
#                       (zdroje resources/upstream/<meno>, preložené veci ~/.local/share/latteos-zaujmy)
set -u
here="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
U="$here/resources/upstream"
P="$HOME/.local/share/latteos-zaujmy"
B="$HOME/.local/bin"
sudo() { if [ -n "${SUDO_ASKPASS:-}" ]; then command sudo -A "$@"; else command sudo "$@"; fi; }
ok() { echo "   ✓ $*"; }
zle() { echo "   ✗ $*"; }
mkdir -p "$P" "$B"

echo "== systémové balíky"
bal="zoxide syncthing kde-connect hyprsunset fuse-libs libxkbcommon-x11-devel"   # posledné: preklad DiskTree
[ "${1:-}" = --whisper ] && bal="$bal whisper-cpp"
chyba=""; for p in $bal; do rpm -q "$p" >/dev/null 2>&1 || chyba="$chyba $p"; done
if [ -n "$chyba" ]; then sudo dnf install -y $chyba >/dev/null 2>&1 && ok "doinštalované:$chyba" || zle "dnf:$chyba"; else ok "už sú: $bal"; fi

echo "== Flathub (pre používateľa, bez roota)"
for a in io.github.qwersyk.Newelle io.github.kolunmi.Bazaar com.usebottles.bottles org.localsend.localsend_app com.rustdesk.RustDesk; do
    if flatpak info --user "$a" >/dev/null 2>&1; then ok "$a"
    else flatpak install --user -y --noninteractive flathub "$a" >/dev/null 2>&1 && ok "$a" || zle "$a"; fi
done

echo "== zdroje"
"$here/resources/fetch.sh" voltage disktree bumblebee flea hypruse hyprsession newelle >/dev/null 2>&1

echo "== disktree (Rust; vlastný make install do ~/.local: program, spúšťač, ikona)"
(cd "$U/disktree" && make install >"$P/disktree.log" 2>&1) && ok "$B/disktree" || zle "disktree — $P/disktree.log"

echo "== bumblebee (Go)"
(cd "$U/bumblebee" && go build -o "$B/bumblebee" ./cmd/bumblebee >"$P/bumblebee.log" 2>&1) && ok "$B/bumblebee" || zle "bumblebee — $P/bumblebee.log"

echo "== hyprsession (Rust)"
cargo install --quiet --root "$P" --path "$U/hyprsession" >"$P/hyprsession.log" 2>&1 && ln -sf "$P/bin/hyprsession" "$B/hyprsession" && ok "$B/hyprsession" || zle "hyprsession — $P/hyprsession.log"

echo "== flea (Rust + Quickshell; BEZ flea --default — predvolený správca súborov ostáva)"
if (cd "$U/flea" && cargo build --release --quiet >"$P/flea.log" 2>&1); then
    printf '#!/bin/sh\n# Flea zo zdroja (setup/lab/zaujmy.sh); rozhranie je v zdrojovom strome\nFLEA_UI="%s/flea/ui" exec "%s/flea/target/release/flea" "$@"\n' "$U" "$U" > "$B/flea"
    chmod +x "$B/flea"; ok "$B/flea (okno: flea --gui)"
else zle "flea — $P/flea.log"; fi

echo "== hypruse (Python; BEZ registrácie do AI nástrojov — dáva agentom ruky na ploche, zapojí sa až vedome)"
if python3 -m venv "$P/hypruse" >"$P/hypruse.log" 2>&1 && "$P/hypruse/bin/pip" install --quiet "$U/hypruse" >>"$P/hypruse.log" 2>&1; then
    ln -sf "$P/hypruse/bin/hypruse" "$B/hypruse"; ok "$B/hypruse"
else zle "hypruse — $P/hypruse.log"; fi

echo "== voltage (Node + Electron: webová stránka ako samostatná aplikácia)"
mkdir -p "$P/voltage" && cp -a "$U/voltage/." "$P/voltage/"
if (cd "$P/voltage" && npm install --no-audit --no-fund >"$P/voltage.log" 2>&1); then
    printf '#!/bin/sh\n# Voltage zo zdroja (setup/lab/zaujmy.sh)\ncd "%s/voltage" && exec npm start -- "$@"\n' "$P" > "$B/voltage"
    chmod +x "$B/voltage"
    mkdir -p "$HOME/.local/share/applications"
    printf '[Desktop Entry]\nType=Application\nName=Voltage\nComment=Web pages as standalone apps\nComment[sk]=Webové stránky ako samostatné aplikácie\nExec=%s/voltage\nIcon=applications-internet\nCategories=Network;\n' "$B" > "$HOME/.local/share/applications/voltage-zaujmy.desktop"
    ok "$B/voltage"
else zle "voltage — $P/voltage.log"; fi

echo "Hotovo. Zoznam a čo s ktorým programom zamýšľame: ROADMAP.md (F3·G), docs/goo/ROZHODNUTIA.md."
