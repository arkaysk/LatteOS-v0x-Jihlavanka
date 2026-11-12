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
    [ -d "$src/$1/.git" ] || git clone -q "https://github.com/k4ditano/$1.git" "$src/$1"
    git -C "$src/$1" fetch -q --tags
    git -C "$src/$1" checkout -q -f "$2"
    git -C "$src/$1" clean -qfd
}
get pleamar dc902feb0ee9058b7db7c2bc2c9d59d9f655fd86          # v0.7.27
for p in apps-reload right-selection steady-glass windows-and-icons window-carry field-select speed-edges-wheel step-hook hollow-body; do      # speed-edges-wheel after the six before it
    git -C "$src/pleamar" apply "$here/patches/pleamar-$p.patch"
done
get pleamar-wm 96f37e486fd90d66d5f68c4b941fd7294dd4553c       # v0.6.15
for p in "$here"/patches/pleamar-wm-*.patch; do git -C "$src/pleamar-wm" apply "$p"; done
# Marea (k4ditano/marea-plm, BSD-3): scenes and scripts only, nothing to build; install copies the tree
get marea-plm d0cad02814f761531cd3a365ac48e549df03f8b0         # 29. 10. 2026
# one target for both: pleamar is built once; --locked: the libraries too as their Cargo.lock has them
export CARGO_TARGET_DIR="$src/target"
(cd "$src/pleamar" && cargo build --release --locked)
# (pleamar-wm's lock names the pleamar it was released with; only that entry is made the one beside it)
(cd "$src/pleamar-wm" && cargo update -q -p pleamar && cargo build --release --locked)
# latte-goo: pleamar as a library with LatteOS's physics stepping inside it (docs/goo/GOOENGINE-2.md §4.1). Outside
# the workspace, since it needs the pleamar fetched above; the same target, so pleamar is not built twice.
(cd "$here/crates/latte-goo" && cargo build --release)
