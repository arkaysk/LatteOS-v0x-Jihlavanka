#!/usr/bin/env bash
# tests/screen.sh SECONDS [pleamar options…]
#
# A scene with no screen and no login, on the real graphics card: a labwc that shows nothing, in it the Goo scene
# from goo/. Nothing is installed and the machine's own screen is left alone, so it can run over ssh while someone
# else is logged in. (--scene, as before Hyprland went, is still taken and changes nothing.) The whole session with
# its window manager is pleamar-wm's own: `pleamar-wm headless`.
#
# What comes out, in $OUT (default: a new folder under /tmp, printed at the end):
#   scene.log    what the scene and its logic printed; with `--record a,b` the values frame by frame
#   shot.png     the screen one second before the end; shot-N.png for every N in SHOTS
#   do.log       the output of DO
#
#   SHOTS="3 5"                    screenshots at these seconds
#   DO='foot & sleep 1; …'         shell run inside the session two seconds in
#   SCENE=goo/login.plm            another scene (default goo/goo.plm)
#   SIZE=1920x1080
#   PLEAMAR=build/pleamar-src/target/release/latte-goo   another program for the scene (default: pleamar of PATH)
# The compositor has no mouse; tests/pointer.py is one (it can drag a window):  DO='pointer.py 1920x1080 400,300 down 2,300 up'
# In a scene the mouse and the keys are its own fake ones (pleamar --help):
#   tests/screen.sh 8 --mouse "718,1056@2000 down@2500 up@2600 type:foo@4000 key:Return@6000"
# `pleamar --say goo describe`, in DO, lists what is on the screen by name, and `press "Settings"` (tests/press)
# presses whatever says that:   DO='press PowerGoo; sleep 1; press Settings; sleep 1; pleamar --say goo "get card_open"'
#
# Needs labwc, wlr-randr and grim. What the session saves and sets goes to $OUT (data, state, config),
# not to the user's own.
set -u
repo="$(cd "$(dirname "$0")/.." && pwd)"
[ "${1:-}" = "--scene" ] && shift
secs="${1:?seconds}"; shift
args=""; [ $# -gt 0 ] && args="$(printf '%q ' "$@")"
out="${OUT:-$(mktemp -d /tmp/latte-screen.XXXXXX)}"
size="${SIZE:-1920x1080}"
scene="$(readlink -f "${SCENE:-$repo/goo/goo.plm}")"
mkdir -p "$out/labwc" "$out/data" "$out/state" "$out/share" "$out/config"
# /usr/share/latteos as it will be, from where its parts are in the repository
ln -sfn "$repo/assets/wallpapers" "$out/share/wallpapers"
ln -sfn "$repo/goo" "$out/share/goo"
ln -sfn "$repo/apps" "$out/share/apps"
ln -sfn "$repo/system/ai" "$out/share/ai"; ln -sfn "$repo/system/agents" "$out/share/agents"
ln -sfn "$repo/system/sky" "$out/share/sky"
[ -f "$repo/build/activity.json" ] && ln -sfn "$repo/build/activity.json" "$out/share/activity.json"      # bin/latte-activity write build/activity.json
mkdir -p "$out/fonts"; ln -sfn "$repo/assets/fonts" "$out/fonts/latteos"      # /usr/share/fonts/latteos, beside /usr/share/latteos
rm -f "$out"/shot*.png "$out/scene.log" "$out/do.log"

# What runs inside the session: the scene, the screenshots, DO.
{
    echo "cd $(dirname "$scene")"
    echo "export PATH=\"$repo/bin:$repo/target/release:$repo/tests:\$PATH\" LANG=\"${LANG:-sk_SK.UTF-8}\" PLEAMAR_GENERIC=window XDG_DATA_HOME=$out/data XDG_STATE_HOME=$out/state XDG_CONFIG_HOME=$out/config XDG_CACHE_HOME=$out/cache LATTE_SHARE=$out/share"
    echo "${PLEAMAR:-pleamar} --scene $scene --no-hud --seconds $secs $args > $out/scene.log 2>&1 &"
    for t in ${SHOTS:-}; do echo "(sleep $t; grim $out/shot-$t.png) &"; done
    [ -n "${DO:-}" ] && echo "(sleep 2; $DO) > $out/do.log 2>&1 &"
    echo "(sleep $((secs - 1)); grim $out/shot.png) &"
} > "$out/inside.sh"

{
    # Without a refresh rate the output has none and a scene paints one frame.
    echo "wlr-randr --output HEADLESS-1 --custom-mode ${size}@60Hz 2>/dev/null"
    echo "sh $out/inside.sh"
    echo "(sleep $secs; sleep 0.5; labwc --exit) &"
} > "$out/labwc/autostart"
echo '<?xml version="1.0"?><labwc_config/>' > "$out/labwc/rc.xml"

# A runtime folder of its own: with the user's, `pleamar --say goo` and `press` reach the Goo of whoever is logged
# in (the first scene of a name owns it), and what DO presses is pressed on their desktop. Short, for the sockets.
run="$(mktemp -d /tmp/latte-run.XXXXXX)"; chmod 700 "$run"
XDG_RUNTIME_DIR="$run" WLR_BACKENDS=headless WLR_LIBINPUT_NO_DEVICES=1 WLR_RENDERER=gles2 XDG_CURRENT_DESKTOP=labwc:wlroots \
    timeout $((secs + 15)) labwc -C "$out/labwc" > "$out/labwc.log" 2>&1
rm -rf "$run"
# what went wrong in the logic, if anything did
grep -E "^luau|error|panicked|I don't know" "$out/scene.log" 2>/dev/null | grep -v "^luau   · " | head -20
[ -s "$out/shot.png" ] || { echo "screen.sh: no screenshot; see $out/scene.log and $out/labwc.log"; exit 1; }
echo "$out"
