#!/bin/sh
# patches/build-pleamar.sh: pleamar and pleamar-wm with LatteOS's patches (patches/README.md), for install.
# Both go to build/pleamar-src/target/release; built again only when a patch is newer than what was built.
set -eu
here="$(cd "$(dirname "$0")/.." && pwd)"
src="$here/build/pleamar-src"
out="$src/target/release"
newest="$(ls -t "$here"/patches/pleamar-*.patch "$0" | head -1)"      # a patch, or this file (another commit)
[ -x "$out/pleamar" ] && [ -x "$out/pleamar-wm" ] && [ "$out/pleamar-wm" -nt "$newest" ] && [ "$out/pleamar" -nt "$newest" ] && exit 0
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
get pleamar 0fdca2de2b8a6e61da7679c16be54f16fe42d4e9          # v0.7.10
for p in apps-reload right-selection steady-glass windows-and-icons window-carry field-select speed-edges-wheel; do      # speed-edges-wheel last
    git -C "$src/pleamar" apply "$here/patches/pleamar-$p.patch"
done
get pleamar-wm 42c8fee85fbfd8fecd1921a8e1009770e78022d7       # v0.6.9
for p in "$here"/patches/pleamar-wm-*.patch; do git -C "$src/pleamar-wm" apply "$p"; done
# one target for both: pleamar is built once; --locked: the libraries too as their Cargo.lock has them
export CARGO_TARGET_DIR="$src/target"
(cd "$src/pleamar" && cargo build --release --locked)
# (pleamar-wm's lock names the pleamar it was released with; only that entry is made the one beside it)
(cd "$src/pleamar-wm" && cargo update -q -p pleamar && cargo build --release --locked)
