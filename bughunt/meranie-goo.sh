#!/bin/sh
# STRESTEST 542/543: Goo and pleamar-wm left alone; every MIN minutes a line of CPU seconds and memory per process.
#   bughunt/meranie-goo.sh OUT HOURS [MIN]    (one line: time, then name cpu_s rss_MB pss_MB for each process)
out=$1; hours=${2:-8}; step=$(( ${3:-1} * 60 )); end=$(( $(date +%s) + hours * 3600 ))
tick=$(getconf CLK_TCK)
while [ "$(date +%s)" -lt "$end" ]; do
    line="$(date +%s)"
    for name in latte-goo pleamar-wm; do
        pid=$(pgrep -o -x "$name") || { line="$line $name - - -"; continue; }
        cpu=$(awk -v t="$tick" '{printf "%.1f", ($14 + $15) / t}' "/proc/$pid/stat")
        rss=$(awk '/^VmRSS/ {printf "%.0f", $2 / 1024}' "/proc/$pid/status")
        pss=$(awk '/^Pss:/ {printf "%.0f", $2 / 1024}' "/proc/$pid/smaps_rollup" 2>/dev/null)
        line="$line $name $cpu $rss ${pss:--}"
    done
    echo "$line" >> "$out"
    sleep "$step"
done
