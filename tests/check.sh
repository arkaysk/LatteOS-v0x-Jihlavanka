#!/usr/bin/env bash
# Everything that can be checked without installing anything. Run it before a commit: tests/check.sh
set -euo pipefail
cd "$(dirname "$0")/.."

echo "== rust"
cargo test --quiet 2>&1 | grep -E '^test result|FAILED|^error' || true
cargo test --quiet >/dev/null 2>&1

echo "== commands"
python3 tests/test_bin.py
python3 tests/test_import.py
python3 tests/test_acp.py
python3 tests/test_local_models.py
python3 tests/test_mcp.py
python3 tests/test_toolhive_catalog.py
python3 tests/test_skill_named.py
python3 tests/test_ai_invite.py
python3 tests/test_devices.py
python3 tests/test_apps_lock.py
sh tests/test_files_winfs.sh
for f in bin/*; do
    case "$(head -1 "$f")" in *python*) python3 -c 'import sys; compile(open(sys.argv[1]).read(), sys.argv[1], "exec")' "$f" ;; *) bash -n "$f" ;; esac
done

for f in get patches/*.sh system/session-env.sh system/libexec/* system/kernel-install/* tests/screen.sh tests/press tests/test_screens.sh tests/test_guardcorgi.sh; do
    case "$(head -1 "$f")" in *python*) python3 -c 'import sys; compile(open(sys.argv[1]).read(), sys.argv[1], "exec")' "$f" ;; *) bash -n "$f" ;; esac
done
# polkit names its actions in lower case (org.freedesktop.udisks2.…): a rule for a name that is not one never
# matches, and nothing says so (24. 11.: NTFS disks still asked for a password)
if command -v pkaction >/dev/null; then
    for id in $(grep -oh '"org\.[a-zA-Z0-9.-]*"' system/polkit/*.rules | tr -d '"'); do
        pkaction --action-id "$id" >/dev/null 2>&1 || { echo "system/polkit: no polkit action $id (pkaction --action-id)"; exit 1; }
    done
fi
# Luau keeps a chunk's locals in at most 200 registers: a file past it does not load at all, and pleamar --check does
# not read Luau (24. 11.: two more locals in goo/lib/lens.luau and LensGoo was gone). Counted at the top level.
python3 - <<'PY'
import glob, re, sys
bad = []
for path in sorted(glob.glob("goo/**/*.luau", recursive=True)):
    n = 0
    for line in open(path, encoding="utf-8"):
        if re.match(r"local\s+function\s+\w+", line):
            n += 1
        else:
            m = re.match(r"local\s+([\w\s,]+?)(=|$)", line)
            if m:
                n += len([x for x in m.group(1).split(",") if x.strip()])
    if n > 198:
        bad.append("%s: %d locals at the top level (Luau loads at most ~198): put new ones in a table" % (path, n))
if bad:
    print("\n".join(bad))
    sys.exit(1)
PY
# a shader is loaded as built: the built file must be the one its source gives
built="$(mktemp)"
for f in apps/common/shaders/*.frag; do
    qsb-qt6 --glsl "100 es,120,150" -o "$built" "$f" && cmp -s "$built" "$f.qsb" || { echo "$f.qsb is not built from $f: qsb-qt6 --glsl \"100 es,120,150\" -o $f.qsb $f"; exit 1; }
done
rm -f "$built"
# the installer puts every file of FILES where it says, and takes every one off again
stage="$(mktemp -d)"
./install --go --root "$stage" --progress > "$stage.log" 2>&1 || { cat "$stage.log"; echo "install --root failed"; exit 1; }
# the installer's bar: only forward, and to the end
grep '^@percent' "$stage.log" | awk '{print $2}' | python3 -c 'import sys; v = [int(x) for x in sys.stdin]; sys.exit(0 if v and v == sorted(v) and v[-1] == 100 else 1)' \
    || { echo "install --progress: the bar does not go only forward to 100"; exit 1; }
grep -q "could not be found" "$stage.log" && { cat "$stage.log"; exit 1; }
[ -x "$stage/usr/bin/latte-session" ] && [ -x "$stage/usr/libexec/latte-hw-memory" ] &&
    [ -x "$stage/usr/libexec/latte-polkit-agent" ] &&
    [ -f "$stage/usr/share/latteos/goo/goo.plm" ] || { echo "install: the staged tree is not whole"; exit 1; }
./install --remove --purge --root "$stage" > /dev/null
left="$(find "$stage" -type f | head -5)"; [ -z "$left" ] || { echo "install --remove left: $left"; exit 1; }
rm -rf "$stage" "$stage.log"
# the Secure Boot password reads the same on QWERTY and QWERTZ (MokManager), and the firmware of cards a PC has is kept
python3 - <<'PY' || { echo "install: MOK password or the graphics firmware's choice is wrong"; exit 1; }
import importlib.machinery, importlib.util
spec = importlib.util.spec_from_loader("inst", importlib.machinery.SourceFileLoader("inst", "install")); m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
assert all(len(p) == 8 and not set(p) & set("yzlo") and p.isalpha() for p in (m.mok_password() for _ in range(200)))
assert "nvidia" not in m.FIRMWARE and m.FIRMWARE["nouveau"] == "nvidia-gpu-firmware"     # NVIDIA's own driver brings its firmware
PY
for f in install tests/pointer.py tests/fake-player.py; do python3 -c 'import sys; compile(open(sys.argv[1]).read(), sys.argv[1], "exec")' "$f"; done
tests/test_session.sh
tests/test_screens.sh


echo "== scenes"
python3 goo/gen.py --check
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
    elif not s.startswith(("system:", "qsweb:", "pleamar:")) and not os.path.isfile(s):
        bad.append("FILES: no such source " + s)
tracked = subprocess.run(["git", "ls-files", "--cached", "--others", "--exclude-standard", "bin", "goo", "apps", "system", "assets"],
                         capture_output=True, text=True).stdout.split("\n")
tools = {"system/plymouth/make-logo.py", "goo/gen.py", "apps/common/shaders/reveal.frag", "apps/common/shaders/velvet.frag"}      # they make a file that is listed; they are not installed
for f in filter(None, tracked):
    if f not in sources and f not in tools:
        bad.append("FILES: %s is not listed" % f)

# code is written in English; the user's language lives in goo/lang
slovak = re.compile("[áäčďéíĺľňóôŕšťúýžÁÄČĎÉÍĹĽŇÓÔŔŠŤÚÝŽ]")
code = subprocess.run(["git", "ls-files", "--cached", "--others", "--exclude-standard", "bin", "goo", "apps", "system", "crates", "tests", "patches", "FILES", "Cargo.toml"],
                      capture_output=True, text=True).stdout.split("\n")
for f in filter(None, code):
    if f.startswith(("goo/lang/", "apps/widgets/")) or f in ("tests/check.sh", "goo/lib/fold.luau", "system/namedays.json") or f.endswith((".png", ".ttf", ".txt", ".qsb")):   # these two name the letters; the rest are not text
        continue
    for n, line in enumerate(open(f, encoding="utf-8", errors="replace"), 1):
        if f.endswith(".patch") and not line.startswith("+"):                # a patch's context is its author's code, not ours
            continue
        if slovak.search(line) and not (f.endswith(".desktop") and re.match(r"\w+\[\w+\]=", line)):     # Name[sk]= is where a launcher's translation goes
            bad.append("%s:%d: Slovak in code: %s" % (f, n, line.strip()[:70]))

# what the commands and the scenes' logic say goes through the same table as the scenes' texts
table = open("goo/lang/sk.plm", encoding="utf-8").read()
said = {"bin/latte-safe": r'\bt "([^"$]+)"', "bin/latte-ai": r'\bN\("((?:[^"\\]|\\.)+)"\)',
        "bin/latte-guardcorgi": r'\bT\("((?:[^"\\]|\\.)+)"\)'}
for f in filter(None, code):
    if f.endswith(".luau"): said[f] = r'\b(?:tr|N)\("((?:[^"\\]|\\.)+)"\)'      # N marks a text that tr() is given later
    if f.endswith(".qml"): said[f] = r'\b(?:tr|QT_TR_NOOP)\("((?:[^"\\]|\\.)+)"'     # QT_TR_NOOP marks one, in a list
for f, pattern in sorted(said.items()):
    for text in sorted(set(re.findall(pattern, open(f, encoding="utf-8").read()))):
        if '"%s" = ' % text not in table:
            bad.append("%s: no Slovak for «%s»" % (f, text))
# the installer shows ./install's parts (@step) by name
for text in re.findall(r'\("\w+", "([^"]+)", \d+\)', open("install", encoding="utf-8").read()):
    if '"%s" = ' % text not in table:
        bad.append("install: no Slovak for the part «%s»" % text)
# the installer shows FILES's optional notes, without their pointers into the source (apps/installer.qml, same regex)
for note in re.findall(r"^optional:[^#\n]*#[ \t]*(.*)$", open("FILES", encoding="utf-8").read(), re.M):
    note = re.sub(r"\s*\([^)]*[/.][a-z][^)]*\)", "", note.strip())
    if '"%s" = ' % note not in table:
        bad.append("FILES: no Slovak for the component «%s»" % note)

print("\n".join(bad) if bad else "   ok")
sys.exit(1 if bad else 0)
PY
echo "all checks passed"
