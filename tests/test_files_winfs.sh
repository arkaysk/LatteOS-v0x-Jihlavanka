#!/bin/sh
# latte-files onto a Windows disk (FAT32, exFAT, NTFS): names fitted as GNOME Files does, a folder with a name the
# disk cannot keep refused whole, links copied as what they point to, a change of case only, undo.
#   tests/test_files_winfs.sh            on a temporary folder, findmnt saying "vfat" (what check.sh runs)
#   tests/test_files_winfs.sh DIR        on a real mounted FAT32/exFAT/NTFS folder (a loop image), nothing faked
set -eu
here="$(cd "$(dirname "$0")/.." && pwd)"; lf="$here/bin/latte-files"
work="$(mktemp -d)"; shm="$(mktemp -d -p /dev/shm)"; trap 'rm -rf -- "$work" "$shm"' EXIT
export XDG_STATE_HOME="$work/state" XDG_DATA_HOME="$work/data" LATTE_UNDO=test
if [ $# -gt 0 ]; then disk="$1/winfs-test"; mkdir -- "$disk"; real=1
else disk="$shm/disk"; mkdir -p "$disk" "$work/bin"; real=0     # another disk than the source, as a USB stick is
    printf '#!/bin/sh\necho vfat\n' > "$work/bin/findmnt"; chmod +x "$work/bin/findmnt"; export PATH="$work/bin:$PATH"; fi
src="$work/src"; mkdir -p "$src/Game/saves"
fail() { echo "FAIL: $*" >&2; exit 1; }

printf 'a' > "$src/a:b?.txt"; printf 'c' > "$src/CON.txt"; printf 't' > "$src/trail. "; printf 'l' > "$src/real.txt"
ln -s real.txt "$src/link.txt"
"$lf" copy "$disk" "$src/a:b?.txt" "$src/CON.txt" "$src/trail. " "$src/link.txt"
for n in "a_b_.txt" "CON_.txt" "trail" "link.txt"; do [ -f "$disk/$n" ] || fail "$n not there: $(ls "$disk")"; done
[ -L "$disk/link.txt" ] && fail "a link kept on a Windows disk"
[ "$(cat "$disk/link.txt")" = l ] || fail "the link's file not copied"

# a folder with a name inside the disk cannot keep: nothing of it arrives, the reason is the last line
printf 's' > "$src/Game/saves/slot:1.dat"
if "$lf" copy "$disk" "$src/Game" 2> "$work/err"; then fail "unfit folder copied"; fi
[ -e "$disk/Game" ] && fail "half a folder left"
[ "$(tail -n1 "$work/err")" = "A name inside cannot be kept on a FAT, exFAT or NTFS disk" ] || fail "reason: $(cat "$work/err")"
"$lf" job copy "$disk" "$src/Game" | grep -qx 'unfit slot:1.dat' || fail "job does not say which name"
rm -- "$src/Game/saves/slot:1.dat"; printf 's' > "$src/Game/saves/slot1.dat"
"$lf" copy "$disk" "$src/Game" && [ -f "$disk/Game/saves/slot1.dat" ] || fail "fitting folder not copied"

# hard and symbolic links inside: each arrives as a file; a move onto the other disk is whole or nothing
for w in move job; do mkdir -p "$src/L$w"; printf 'h' > "$src/L$w/f"; ln "$src/L$w/f" "$src/L$w/hard"; ln -s f "$src/L$w/sym"
    if [ "$w" = job ]; then "$lf" job move "$disk" "$src/L$w" > /dev/null; else "$lf" move "$disk" "$src/L$w"; fi
    [ -e "$src/L$w" ] && fail "$w: original left"
    for n in f hard sym; do [ -f "$disk/L$w/$n" ] && [ ! -L "$disk/L$w/$n" ] || fail "$w: $n: $(ls -l "$disk/L$w")"; done
done

# rename: fitted name; a change of case only (on FAT/exFAT mv alone would do nothing); undo puts it back
"$lf" rename "$disk/a_b_.txt" 'x|y.txt' && [ -f "$disk/x_y.txt" ] || fail "rename not fitted: $(ls "$disk")"
"$lf" rename "$disk/x_y.txt" 'X_Y.txt'
ls "$disk" | grep -qx 'X_Y.txt' || fail "change of case lost: $(ls "$disk")"
"$lf" undo; ls "$disk" | grep -qx 'x_y.txt' || fail "undo of a change of case: $(ls "$disk")"

if [ "$real" = 1 ]; then
    # the disk's own Trash (TOP/.Trash-UID, as gio makes it) and back with undo
    "$lf" trash "$disk/x_y.txt"; [ -e "$disk/x_y.txt" ] && fail "not trashed"
    "$lf" undo; [ -f "$disk/x_y.txt" ] || fail "not restored from the disk's Trash"
    rm -rf -- "$disk"
fi
echo "files on a Windows disk: ok"
