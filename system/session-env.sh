# Sourced by latte-greeter and latte-session: what greetd does not hand over to what it starts.

# the system's language
[ -z "${LANG:-}" ] && [ -r /etc/locale.conf ] && { set -a; . /etc/locale.conf; set +a; }

# the system's keyboard layout, as localectl keeps it
xkb() { sed -n "s/.*Option *\"$1\" *\"\([^\"]*\)\".*/\1/p" /etc/X11/xorg.conf.d/00-keyboard.conf 2>/dev/null | head -1; }
export XKB_DEFAULT_LAYOUT="$(xkb XkbLayout)" XKB_DEFAULT_VARIANT="$(xkb XkbVariant)" XKB_DEFAULT_OPTIONS="$(xkb XkbOptions)"
# Two layouts and no way to switch would lock out whoever has the password in the second one.
case "$XKB_DEFAULT_LAYOUT" in *,*) : "${XKB_DEFAULT_OPTIONS:=grp:alt_shift_toggle}" ;; esac

# the mode latte-boot decided; without it, the one that always works
LATTE_MODE=safe LATTE_RENDERER=pixman LATTE_TIER=safe
[ -r "${LATTE_RUN_DIR:-/run/latteos}/session.env" ] && { set -a; . "${LATTE_RUN_DIR:-/run/latteos}/session.env"; set +a; }
export LATTE_MODE LATTE_RENDERER LATTE_TIER
