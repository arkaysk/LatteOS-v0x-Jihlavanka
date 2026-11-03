#!/usr/bin/env bash
# The guard on the real session: every part of the desktop is killed (TERM, KILL), stopped (STOP) and frozen, and must be
# back. It shakes the desktop for a minute, so it is not in check.sh (tests/test_bin.py checks the same without a
# session). Run in a LatteOS session: tests/test_guarddog.sh
set -u
fail=0
pid() { systemctl --user show -p MainPID --value "$1"; }
state() { awk '{print $3}' "/proc/$1/stat" 2>/dev/null; }
back() {   # UNIT OLD-PID SECONDS: a new process runs it within that time
    local t=0
    while [ $t -lt "$3" ]; do
        local now; now="$(pid "$1")"
        [ "$now" != 0 ] && [ "$now" != "$2" ] && systemctl --user is-active --quiet "$1" && return 0
        sleep 1; t=$((t + 1))
    done
    return 1
}
say() { if [ "$1" = 0 ]; then echo "   ok    $2"; else echo "   FAIL  $2"; fail=1; fi; }

systemctl --user is-active --quiet latte-session.target || { echo "guarddog: not in a LatteOS session"; exit 2; }
units="latte-guarddog latte-goo latte-lockscreen latte-idle latte-focus"
for u in $units; do
    for sig in TERM KILL; do
        a="$(pid "$u")"; kill "-$sig" "$a"; back "$u" "$a" 5; say $? "$u $sig"
    done
done
# stopped and frozen: the guard lets them go on (it looks every 5 s)
for u in latte-goo latte-idle latte-focus; do
    a="$(pid "$u")"; kill -STOP "$a"; sleep 8; [ "$(state "$a")" != T ]; say $? "$u STOP"
done
systemctl --user freeze latte-idle; sleep 8
[ "$(systemctl --user show -p FreezerState --value latte-idle)" = running ]; say $? "latte-idle frozen"
# the password dialog is Hyprland's, not systemd's (polkit takes it only from the login session): the guard starts it again
agent='^/usr/bin/pleamar --scene \S*/goo/polkit\.plm'
pkill -KILL -f '^bash /usr/libexec/latte-polkit-agent'; pkill -KILL -f "$agent"; t=0
until pgrep -f "$agent" >/dev/null || [ $t -ge 20 ]; do sleep 1; t=$((t + 1)); done
pgrep -f "$agent" >/dev/null; say $? "polkit agent KILL (${t} s)"
# the guard itself stopped: its watchdog (30 s) has systemd kill it and start it again
a="$(pid latte-guarddog)"; kill -STOP "$a"; back latte-guarddog "$a" 40; say $? "latte-guarddog STOP"
[ $fail = 0 ] && echo "guarddog: ok" || { echo "guarddog: FAILED"; exit 1; }
