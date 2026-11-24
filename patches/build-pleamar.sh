#!/bin/sh
# patches/build-pleamar.sh: pleamar and pleamar-wm with LatteOS's patches (patches/README.md), for install.
# Both go to build/pleamar-src/target/release; built again only when a patch is newer than what was built.
set -eu
here="$(cd "$(dirname "$0")/.." && pwd)"
src="$here/build/pleamar-src"
out="$src/target/release"
newest="$(ls -t "$here"/patches/pleamar-*.patch "$0" "$here"/crates/goo-phys/src/*.rs "$here"/crates/latte-goo/src/*.rs | head -1)"      # a patch, or this file (another commit)
[ -f "$src/marea-plm/marea" ] && [ -x "$out/pleamar" ] && [ -x "$out/pleamar-wm" ] && [ -x "$out/latte-goo" ] && [ "$out/latte-goo" -nt "$newest" ] && [ "$out/pleamar-wm" -nt "$newest" ] && [ "$out/pleamar" -nt "$newest" ] && exit 0
mkdir -p "$src"
# Each locked to one commit, for this LatteOS: what its author releases later comes only when the commit here is
# changed and the patches are seen to fit (a tag can be moved, a commit cannot). pleamar-wm builds against the
# pleamar beside it.
get() {   # get NAME COMMIT
    # a clone that was cut off (power button, a frozen install) leaves a broken .git: it is thrown away and fetched again
    [ -d "$src/$1/.git" ] && ! git -C "$src/$1" fsck --connectivity-only -q >/dev/null 2>&1 && rm -rf "$src/$1"
    for try in 1 2 3; do
        [ -d "$src/$1/.git" ] && break
        rm -rf "$src/$1"; git clone -q "https://github.com/k4ditano/$1.git" "$src/$1" || sleep 5
    done
    git -C "$src/$1" fetch -q --tags
    git -C "$src/$1" checkout -q -f "$2"
    git -C "$src/$1" clean -qfd
}
get pleamar 33b2a81ea5a75a56120680a6aaded9bc4517c0ef          # v0.7.31
for p in apps-reload right-selection steady-glass windows-and-icons window-carry field-select speed-edges-wheel step-hook hollow-body idle-without-surface app-scope; do      # speed-edges-wheel after the six before it
    git -C "$src/pleamar" apply "$here/patches/pleamar-$p.patch"
done
get pleamar-wm a9b803aadf1cbdc065b7db6965fc7540a96903c7       # v0.6.35
for p in "$here"/patches/pleamar-wm-*.patch; do git -C "$src/pleamar-wm" apply "$p"; done
# Marea (k4ditano/marea-plm, BSD-3): scenes and scripts, and two pieces built below; install copies the tree
get marea-plm d0cad02814f761531cd3a365ac48e549df03f8b0         # 29. 10. 2026
# one target for both: pleamar is built once; --locked: the libraries too as their Cargo.lock has them
export CARGO_TARGET_DIR="$src/target"
(cd "$src/pleamar" && cargo build --release --locked)
# (pleamar-wm's lock names the pleamar it was released with; only that entry is made the one beside it)
(cd "$src/pleamar-wm" && cargo update -q -p pleamar && cargo build --release --locked)
# latte-goo: pleamar as a library with LatteOS's physics stepping inside it (docs/goo/GOOENGINE-2.md §4.1). Outside
# the workspace, since it needs the pleamar fetched above; the same target, so pleamar is not built twice.
(cd "$here/crates/latte-goo" && cargo build --release)
# Marea builds these herself in her own folder, which /usr/share does not let her write: Deriva's worker (her
# library: what is dropped on her) and her agent's packages (her chat and Build). Made here, install copies them.
(cd "$src/marea-plm/deriva" && cargo build --release --locked)
if command -v npm > /dev/null; then
    (cd "$src/marea-plm/agent" && npm ci --ignore-scripts --no-audit --no-fund)    # no package runs anything
fi
