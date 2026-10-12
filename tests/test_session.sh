#!/usr/bin/env bash
# The session's guard, with every program it starts replaced by a stand-in. Run: tests/test_session.sh
set -u
repo="$(cd "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
fail() { echo "session: FAILED: $*"; sed 's/^/    /' "$tmp/state/latteos/session.log" 2>/dev/null | tail -8; exit 1; }

mkdir -p "$tmp/bin" "$tmp/share/labwc" "$tmp/share/goo" "$tmp/sys/login"
cp "$repo/system/session-env.sh" "$tmp/share/"
cp "$repo/system/labwc/rc.xml" "$repo/system/labwc/autostart" "$tmp/share/labwc/"
cp -r "$repo/goo/lang" "$tmp/share/goo/"
stand_in() { printf '#!/bin/sh\n%s\n' "$2" > "$tmp/bin/$1"; chmod +x "$tmp/bin/$1"; }
stand_in labwc      'echo "$@" > "$TMP_OUT/labwc"; cp "$2/menu.xml" "$TMP_OUT/menu.xml"'
stand_in latte-boot 'echo "$@" >> "$TMP_OUT/boot"; exit ${BOOT_EXIT:-0}'
stand_in systemctl  ':'
stand_in journalctl ':'
stand_in coredumpctl ':'
ln -s "$repo/bin/latte-safe" "$repo/bin/latte-game" "$tmp/bin/"

session() {   # $1 the mode latte-boot decided, then the arguments of latte-session
    local mode="$1"; shift
    rm -rf "$tmp/out" "$tmp/run" "$tmp/state"; mkdir -p "$tmp/out" "$tmp/run/sys" "$tmp/state"
    printf 'LATTE_MODE=%s\nLATTE_RENDERER=hw\nLATTE_TIER=eco\n' "$mode" > "$tmp/run/sys/session.env"
    printf '[mode]\nreason_id = "no-gpu"\nreason = "no card"\n' > "$tmp/run/sys/mode.toml"
    env PATH="$tmp/bin:$PATH" TMP_OUT="$tmp/out" LATTE_SHARE="$tmp/share" LATTE_RUN_DIR="$tmp/run/sys" LATTE_STATE_DIR="$tmp/sys" \
        XDG_RUNTIME_DIR="$tmp/run" XDG_STATE_HOME="$tmp/state" XDG_CONFIG_HOME="$tmp/config" LANG=sk_SK.UTF-8 \
        timeout 20 "$repo/bin/latte-session" "$@"
}
why() { head -1 "$tmp/run/latteos/safe-reason" 2>/dev/null; }

session normal safe
[ "$(why)" = chosen ] || fail "choosing SAFE at login: '$(why)'"
grep -q -- "-C $tmp/run/latteos/labwc" "$tmp/out/labwc" || fail "labwc was not started with the session's config"
shut_down="$(sed -n 's/.*"Shut down" = "\(.*\)"/\1/p' "$repo/goo/lang/sk.plm")"
grep -q "label=\"$shut_down\"" "$tmp/out/menu.xml" || fail "labwc's menu is not in the user's language"
[ ! -e "$tmp/out/boot" ] || fail "a chosen SAFE must not count as a start of NORMAL"

session safe
[ "$(why)" = no-gpu ] || fail "the mode decided at boot: '$(why)'"
[ "$(sed -n 2p "$tmp/run/latteos/safe-reason")" = "no card" ] || fail "the reason's detail was lost"

BOOT_EXIT=3 session normal
[ "$(why)" = crashes ] || fail "too many crashes: '$(why)'"

session normal
[ "$(why)" = not-installed ] || fail "no desktop installed: '$(why)'"

echo "-- config" > "$tmp/share/hypr.lua"; mkdir -p "$tmp/share/hypr"; mv "$tmp/share/hypr.lua" "$tmp/share/hypr/hyprland.lua"
LATTE_HYPRLAND=false session normal
[ "$(why)" = desktop-crash ] || fail "a crash right after the start: '$(why)'"
grep -q 'Hyprland exit 1' "$tmp/sys/login/last-crash.log" || fail "the crash was not reported for the login screen"
grep -q session-start "$tmp/out/boot" || fail "the start of NORMAL was not counted"
echo "session: ok"
