#!/usr/bin/env bash
# Everything that can be checked without installing anything. Run it before a commit: tests/check.sh
set -euo pipefail
cd "$(dirname "$0")/.."

echo "== rust"
cargo test --quiet 2>&1 | grep -E '^test result|FAILED|^error' || true
cargo test --quiet >/dev/null 2>&1

echo "== commands"
python3 tests/test_bin.py
for f in bin/*; do
    case "$(head -1 "$f")" in *python*) python3 -c 'import sys; compile(open(sys.argv[1]).read(), sys.argv[1], "exec")' "$f" ;; *) bash -n "$f" ;; esac
done

for f in system/session-env.sh system/libexec/* system/kernel-install/*; do bash -n "$f"; done
tests/test_session.sh

echo "== scenes"
for s in goo/*.plm; do
    out="$(cd goo && LANG=sk_SK.UTF-8 pleamar --check "$(basename "$s")" 2>&1)" || { echo "$out"; exit 1; }
    echo "$out" | tail -1
    # Slovak is the one translation there is: a text it lacks was forgotten, not left out.
    if echo "$out" | grep -q 'without a translation'; then echo "$out" | grep 'without a translation'; exit 1; fi
done

echo "== icons, FILES, language"
python3 - <<'PY'
import os, re, subprocess, sys
bad = []

# every glyph in goo/lib/icons.luau is the icon its name says
try:
    import logging
    from fontTools.ttLib import TTFont
    logging.disable(logging.WARNING)                # the font's own harmless quirks
    cmap = TTFont("assets/fonts/tabler-icons.ttf").getBestCmap()
    for name, code in re.findall(r'\["([\w-]+)"\] = "\\u\{([0-9A-Fa-f]+)\}"', open("goo/lib/icons.luau").read()):
        if cmap.get(int(code, 16)) != name:
            bad.append("icons.luau: %s is U+%s, which the font calls %s" % (name, code, cmap.get(int(code, 16))))
except ImportError:
    print("   fontTools missing: the icon table was not compared with the font")

# FILES names every file meant for the system, and nothing that is not there
sources = set(re.findall(r"<-\s*(\S+)", "".join(l for l in open("FILES") if not l.startswith("#"))))
for s in sorted(sources):
    if s.startswith("build:"):
        if not os.path.isdir("crates/" + s[6:]): bad.append("FILES: no crate " + s[6:])
    elif not s.startswith("system:") and not os.path.isfile(s):
        bad.append("FILES: no such source " + s)
tracked = subprocess.run(["git", "ls-files", "--cached", "--others", "--exclude-standard", "bin", "goo", "system", "assets"],
                         capture_output=True, text=True).stdout.split("\n")
tools = {"system/plymouth/make-logo.py"}            # they make a file that is listed; they are not installed
for f in filter(None, tracked):
    if f not in sources and f not in tools:
        bad.append("FILES: %s is not listed" % f)

# code is written in English; the user's language lives in goo/lang
slovak = re.compile("[áäčďéíĺľňóôŕšťúýžÁÄČĎÉÍĹĽŇÓÔŔŠŤÚÝŽ]")
code = subprocess.run(["git", "ls-files", "--cached", "--others", "--exclude-standard", "bin", "goo", "system", "crates", "tests", "FILES", "Cargo.toml"],
                      capture_output=True, text=True).stdout.split("\n")
for f in filter(None, code):
    if f.startswith("goo/lang/") or f in ("tests/check.sh", "goo/lib/fold.luau") or f.endswith((".png", ".ttf", ".txt")):   # these two name the letters
        continue
    for n, line in enumerate(open(f, encoding="utf-8", errors="replace"), 1):
        if slovak.search(line):
            bad.append("%s:%d: Slovak in code: %s" % (f, n, line.strip()[:70]))

# what the commands say goes through the same table as the scenes' texts
table = open("goo/lang/sk.plm", encoding="utf-8").read()
for f in ("bin/latte-safe",):
    for text in sorted(set(re.findall(r'\bt "([^"$]+)"', open(f, encoding="utf-8").read()))):
        if '"%s" = ' % text not in table:
            bad.append("%s: no Slovak for «%s»" % (f, text))

print("\n".join(bad) if bad else "   ok")
sys.exit(1 if bad else 0)
PY
echo "all checks passed"
