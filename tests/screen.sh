#!/usr/bin/env bash
# tests/screen.sh [--scene] SECONDS [pleamar options…]
#
# The GOO session with no screen and no login, on the real graphics card: a labwc that shows nothing, in it
# Hyprland with this repository's configuration, in it the Goo scene from goo/. Nothing is installed and the
# machine's own screen is left alone, so it can run over ssh while someone else is logged in.
# With --scene the scene runs straight in labwc, without Hyprland (login.plm and safe.plm need nothing more).
#
# What comes out, in $OUT (default: a new folder under /tmp, printed at the end):
#   scene.log    what the scene and its logic printed; with `--record a,b` the values frame by frame
#   shot.png     the screen one second before the end; shot-N.png for every N in SHOTS
#   do.log       the output of DO
#
#   SHOTS="3 5"                    screenshots at these seconds
#   DO='foot & sleep 1; hyprctl …'  shell run inside the session two seconds in
#   SCENE=goo/login.plm            another scene (default goo/goo.plm)
#   SIZE=1920x1080
# The compositor has no mouse; tests/pointer.py is one (it can drag a window):  DO='pointer.py 1920x1080 400,300 down 2,300 up'
# In a scene the mouse and the keys are its own fake ones (pleamar --help):
#   tests/screen.sh 8 --mouse "718,1056@2000 down@2500 up@2600 type:foo@4000 key:Return@6000"
# `pleamar --say goo describe`, in DO, lists what is on the screen by name, and `press "Settings"` (tests/press)
# presses whatever says that:   DO='press PowerGoo; sleep 1; press Settings; sleep 1; pleamar --say goo "get card_open"'
#
# Needs labwc, wlr-randr, grim and Hyprland. What the session saves and sets goes to $OUT (data, state, config),
# not to the user's own.
set -u
repo="$(cd "$(dirname "$0")/.." && pwd)"
nested=1
[ "${1:-}" = "--scene" ] && { nested=0; shift; }
secs="${1:?seconds}"; shift
args=""; [ $# -gt 0 ] && args="$(printf '%q ' "$@")"
out="${OUT:-$(mktemp -d /tmp/latte-screen.XXXXXX)}"
size="${SIZE:-1920x1080}"
scene="$(readlink -f "${SCENE:-$repo/goo/goo.plm}")"
mkdir -p "$out/labwc" "$out/data" "$out/state" "$out/share" "$out/config"
# /usr/share/latteos as it will be, from where its parts are in the repository
ln -sfn "$repo/system/hypr" "$out/share/hypr"
ln -sfn "$repo/assets/wallpapers" "$out/share/wallpapers"
ln -sfn "$repo/goo" "$out/share/goo"
ln -sfn "$repo/apps" "$out/share/apps"
mkdir -p "$out/fonts"; ln -sfn "$repo/assets/fonts" "$out/fonts/latteos"      # /usr/share/fonts/latteos, beside /usr/share/latteos
# the plugins: this repository's own as it was last built (make -C plugins/latte-events), the title bars and the glass from the system
mkdir -p "$out/plugins"
for p in "$repo/plugins/latte-events/latte-events.so" /usr/lib64/latteos/hyprbars.so /usr/lib64/latteos/hyprglass.so; do [ -f "$p" ] && ln -sfn "$p" "$out/plugins/"; done
rm -f "$out"/shot*.png "$out/scene.log" "$out/do.log"

# What runs inside the session: the scene, the screenshots, DO.
{
    echo "cd $(dirname "$scene")"
    echo "export PATH=\"$repo/bin:$repo/target/release:$repo/tests:\$PATH\" LANG=\"${LANG:-sk_SK.UTF-8}\" PLEAMAR_GENERIC=window XDG_DATA_HOME=$out/data XDG_STATE_HOME=$out/state XDG_CONFIG_HOME=$out/config XDG_CACHE_HOME=$out/cache LATTE_SHARE=$out/share"
    # Under a labwc with no screen Hyprland's nested output never becomes a monitor; one of its own does.
    [ $nested = 1 ] && echo "hyprctl output create headless LATTE-TEST >/dev/null; sleep 0.5"
    echo "pleamar --scene $scene --no-hud --seconds $secs $args > $out/scene.log 2>&1 &"
    for t in ${SHOTS:-}; do echo "(sleep $t; grim $out/shot-$t.png) &"; done
    [ -n "${DO:-}" ] && echo "(sleep 2; $DO) > $out/do.log 2>&1 &"
    echo "(sleep $((secs - 1)); grim $out/shot.png) &"
    [ $nested = 1 ] && echo "(sleep $secs; sleep 0.7; hyprctl eval 'hl.dispatch(hl.dsp.exit())' >/dev/null) &"
} > "$out/inside.sh"

# The repository's Hyprland configuration, minus what belongs to a real login: systemd's target, the crash count.
cat > "$out/hyprland.lua" <<EOF
local real = hl.exec_cmd
hl.exec_cmd = function(cmd)
    if cmd:find("systemctl") or cmd:find("latte%-boot") then return end
    return real(cmd)
end
dofile("$repo/system/hypr/hyprland.lua")
hl.monitor({ output = "", mode = "${size}@60", position = "auto", scale = 1, reserved_area = { top = 0, right = 0, bottom = 54, left = 0 } })
hl.on("hyprland.start", function() real("sh $out/inside.sh") end)
EOF

{
    # Without a refresh rate the output has none and a scene paints one frame.
    echo "wlr-randr --output HEADLESS-1 --custom-mode ${size}@60Hz 2>/dev/null"
    if [ $nested = 1 ]; then
        # LIBSEAT_BACKEND=logind: should the nested backend fail, Hyprland falls back to the real card. Over ssh
        # logind refuses that, where seatd would let it take the screen from whoever is using it.
        echo "PATH=\"$repo/bin:\$PATH\" LIBSEAT_BACKEND=logind LATTE_SHARE=$out/share LATTE_PLUGINS=$out/plugins LATTE_TIER=${LATTE_TIER:-standard} LATTE_RENDERER=hw XDG_CURRENT_DESKTOP=Hyprland XDG_STATE_HOME=$out/state XDG_CONFIG_HOME=$out/config XDG_CACHE_HOME=$out/cache Hyprland -c $out/hyprland.lua > $out/hyprland.log 2>&1 &"
        echo "echo \$! > $out/hyprland.pid"
        echo "(sleep $((secs + 4)); labwc --exit) &"
    else
        echo "sh $out/inside.sh"
        echo "(sleep $secs; sleep 0.5; labwc --exit) &"
    fi
} > "$out/labwc/autostart"
echo '<?xml version="1.0"?><labwc_config/>' > "$out/labwc/rc.xml"

WLR_BACKENDS=headless WLR_LIBINPUT_NO_DEVICES=1 WLR_RENDERER=gles2 XDG_CURRENT_DESKTOP=labwc:wlroots \
    timeout $((secs + 15)) labwc -C "$out/labwc" > "$out/labwc.log" 2>&1
# A Hyprland that outlives its labwc spins at full speed: make sure this one is gone, and what it started.
if [ -s "$out/hyprland.pid" ]; then
    pid="$(cat "$out/hyprland.pid")"
    pkill -P "$pid" 2>/dev/null
    kill "$pid" 2>/dev/null && { sleep 0.5; kill -9 "$pid" 2>/dev/null; }
    rm -f "$out/hyprland.pid"
fi
# what went wrong in the logic, if anything did
grep -E "^luau|error|panicked|I don't know" "$out/scene.log" 2>/dev/null | grep -v "^luau   · " | head -20
[ -s "$out/shot.png" ] || { echo "screen.sh: no screenshot; see $out/scene.log and $out/labwc.log"; exit 1; }
echo "$out"
