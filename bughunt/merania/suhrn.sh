#!/bin/sh
# bughunt/merania/suhrn.sh FILE: CPU and memory of latte-goo and pleamar-wm by the hour, from bughunt/meranie-goo.sh's lines;
# a counter that goes back (a restart) starts a new stretch
awk '{ if (NR > 1 && ($3 < g || $7 < w)) { print "-- restart at " strftime("%H:%M", $1); t0 = 0 }
       if (!t0 || $1 - t0 >= 3600) { if (t0) printf "%s–%s  latte-goo %5.1f %% CPU, RSS %4d MB   pleamar-wm %5.1f %% CPU, RSS %4d MB\n", strftime("%H:%M", t0), strftime("%H:%M", $1), 100 * ($3 - g0) / ($1 - t0), $4, 100 * ($7 - w0) / ($1 - t0), $8
                                     t0 = $1; g0 = $3; w0 = $7 }
       g = $3; w = $7; last = $0 }
     END { split(last, l, " "); printf "last: %s  latte-goo RSS %d MB, pleamar-wm RSS %d MB\n", strftime("%H:%M", l[1]), l[4], l[8] }' "$1"
