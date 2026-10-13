#!/usr/bin/env bash
# latte-screens with systemctl replaced by a stand-in that answers from files and writes down what it is told.
set -u
repo="$(cd "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin"
cat > "$tmp/bin/systemctl" <<'SH'
#!/bin/sh
shift                                   # --user
case "$1" in
    -q) [ -f "$T/active" ] ;;           # -q is-active latte-session.target
    show-environment) echo "LATTE_GOO_SCREEN=$(cat "$T/screen" 2>/dev/null)" ;;
    list-units) for n in $(cat "$T/sides" 2>/dev/null); do echo "latte-goo-side@$n.service loaded active running"; done ;;
    *) echo "$*" >> "$T/said" ;;
esac
SH
chmod +x "$tmp/bin/systemctl"
run() { rm -f "$tmp/said"; env PATH="$tmp/bin:$PATH" T="$tmp" "$repo/bin/latte-screens" "$@"; cat "$tmp/said" 2>/dev/null | tr "\n" ";"; }
want() { [ "$1" = "$2" ] || { echo "screens: FAILED: $3: «$1», not «$2»"; exit 1; }; }

want "$(run DP-3 DP-1)" "" "before the session nothing is touched"
want "$(run --start DP-3 DP-1)" "set-environment LATTE_GOO_SCREEN=DP-3;start latte-session.target;start latte-goo-side@DP-1.service;" "the start"
touch "$tmp/active"; echo DP-1 > "$tmp/screen"; echo DP-3 > "$tmp/sides"
want "$(run DP-1)" "stop latte-goo-side@DP-3.service;" "a monitor went"
want "$(run DP-3 DP-1)" "set-environment LATTE_GOO_SCREEN=DP-3;restart latte-goo.service;stop latte-goo-side@DP-3.service;start latte-goo-side@DP-1.service;" "the main monitor is another one"
echo "screens: ok"
