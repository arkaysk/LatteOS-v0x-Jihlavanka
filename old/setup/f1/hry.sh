#!/usr/bin/env bash
# hry.sh — základ pre inštaláciu Windows hier a programov (Barista, docs/barista/NAVRH.md): umu-launcher a GE-Proton.
# Má byť v systéme od začiatku (rozhodnutie 8. 10.). Balíky z Fedory (wine, winetricks, waydroid, bubblewrap…) rieši f0-install.sh.
# Sťahuje sa s kontrolou súčtu (umu RPM: SHA-256 z GitHubu; GE-Proton: sha512 z vydania). Opakovanie je bezpečné (preskočí hotové).
# Proton leží v /opt/latteos/proton: kontajner Steam Linux Runtime (pressure-vessel) nevidí /usr/share, ale /opt áno.
set -euo pipefail
UMU=1.4.4
GE=GE-Proton11-7
cache="${XDG_CACHE_HOME:-$HOME/.cache}/latteos/hry"; mkdir -p "$cache"

# umu-launcher (oficiálny RPM pre aktuálnu Fedoru)
if ! command -v umu-run >/dev/null; then
    fc="fc$(rpm -E %fedora)"
    f="umu-launcher-$UMU.$fc.x86_64.rpm"
    base="https://github.com/Open-Wine-Components/umu-launcher/releases/download/$UMU"
    curl -fL -o "$cache/$f" "$base/$f"
    want=$(curl -fsS "https://api.github.com/repos/Open-Wine-Components/umu-launcher/releases/tags/$UMU" |
        python3 -c "import json,sys; d=json.load(sys.stdin); print(next((a['digest'].split(':')[1] for a in d['assets'] if a['name']=='$f' and a.get('digest')),''))")
    have=$(sha256sum "$cache/$f" | cut -d' ' -f1)
    [ -z "$want" ] || [ "$want" = "$have" ] || { echo "umu-launcher: nesedí SHA-256 (je $have, má byť $want)"; exit 1; }
    sudo dnf -y install "$cache/$f"
else
    echo "umu-run už je: $(umu-run --version 2>&1 | head -1)"
fi

# GE-Proton (Proton s opravami pre hry mimo Steamu)
if [ ! -d "/opt/latteos/proton/$GE-x86_64" ]; then
    base="https://github.com/GloriousEggroll/proton-ge-custom/releases/download/$GE"
    ( cd "$cache" && curl -fL -O "$base/$GE-x86_64.tar.gz" && curl -fL -O "$base/$GE-x86_64.sha512sum" && sha512sum -c "$GE-x86_64.sha512sum" )
    sudo install -d /opt/latteos/proton
    sudo tar -xzf "$cache/$GE-x86_64.tar.gz" -C /opt/latteos/proton
else
    echo "$GE už je v /opt/latteos/proton"
fi
echo "hotovo: umu-run + $GE (PROTONPATH=/opt/latteos/proton/$GE-x86_64, GAMEID=umu-0)"
