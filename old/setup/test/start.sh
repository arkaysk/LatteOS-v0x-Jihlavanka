#!/usr/bin/env bash
# Kontrola štartu LatteOS z denníka (STRESTEST 001, 002, 009, 021, 550): spúšťa sa PO prihlásení, nič nemení.
# Časy sú sekundy od štartu jadra. Použitie: setup/test/start.sh [N]   (N = 0 tento štart, -1 predošlý — na porovnanie)
set -u
b="${1:-0}"
j() { journalctl -b "$b" --no-pager -o short-monotonic "$@" 2>/dev/null; }
t() { awk -F'[][]' 'NR==1{printf "%.0f", $2}'; }                 # čas prvého riadka
greet=$(j -u greetd | grep -m1 'Started greetd' | t)
login=$(j | grep -m1 'Reached target latte-session.target' | t)
noct=$(j | grep 'org.noctalia.SecretAgent.*registered' | awk -F'[][]' -v l="${login:-0}" '$2>=l{printf "%.0f", $2; exit}')

echo "== štart $b: $(j -t latte-boot | grep -m1 'latte-boot:' | sed 's/.*latte-boot: //' | cut -c1-110)"
echo "prihlasovacia obrazovka:  ${greet:-—} s   (12. 10. pred opravou: 99 s)"
echo "čakanie na sieť:          $(systemctl is-enabled NetworkManager-wait-online.service 2>/dev/null), $(j -u NetworkManager-wait-online | grep -cE 'Failed|Finished') záznamov v tomto štarte"
if [ -n "$login" ]; then
    echo "prihlásenie:              $login s"
    # sama nabehne do ~20 s; väčšie číslo = niekto ju spustil ručne
    if [ -n "$noct" ]; then echo "rohová lišta Noctalie:    +$((noct - login)) s po prihlásení"; else echo "rohová lišta Noctalie:    NENABEHLA"; fi
else
    echo "prihlásenie:              v tomto štarte ešte nebolo"
fi
[ "$b" = 0 ] || exit 0
echo "Noctalia teraz beží:      $(pgrep -u "$(id -u)" -fx '(.*/)?noctalia' >/dev/null && echo áno || echo NIE)"
echo "engine Goo:               $(pgrep -u "$(id -u)" -x pleamar >/dev/null && echo beží || echo NEBEŽÍ), $(grep -m1 -o 'first frame.*' "${XDG_STATE_HOME:-$HOME/.local/state}/latteos/kvapky.log" 2>/dev/null)"
echo "režim a počítadlo pádov:  $(latte-boot status 2>/dev/null | grep -E '^(mode|crash_count_now)' | tr '\n' ' ')"
echo "zlyhané služby:           $(systemctl --failed --no-legend --plain 2>/dev/null | awk '{print $1}' | tr '\n' ' ')"
echo "celkový čas štartu:       $(systemd-analyze 2>/dev/null | head -1 | sed 's/.*= //')"
echo "koniec predošlého štartu: $(journalctl -b -1 -n1 --no-pager -o short-iso 2>/dev/null | cut -c1-19)"
echo "posledné pády Hyprlandu:  $(coredumpctl list Hyprland --no-pager 2>/dev/null | awk 'NR>1{print $2"T"$3}' | tail -2 | tr '\n' ' ')"
