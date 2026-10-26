#!/bin/sh
# name: Send to the phone (KDE Connect)
# for: *
# What is chosen goes to the first phone KDE Connect sees; with none paired, nothing happens.
phone="$(kdeconnect-cli -a --id-only 2>/dev/null | head -n1)"
[ -n "$phone" ] || exit 1
for f in "$@"; do
    kdeconnect-cli -d "$phone" --share "$f"
done
