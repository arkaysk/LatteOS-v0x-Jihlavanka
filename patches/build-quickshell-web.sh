#!/bin/sh
# patches/build-quickshell-web.sh: Quickshell with a web engine, for LensAI alone (ROADMAP 10B.35; patches/README.md).
# It goes to build/quickshell-web/build/src/quickshell, which install puts at /usr/lib64/latteos/qs-web. Built again
# only when the patch is newer than what was built.
set -eu
here="$(cd "$(dirname "$0")/.." && pwd)"
src="$here/build/quickshell-web"
patch="$here/patches/quickshell-webengine.patch"
out="$src/build/src/quickshell"
[ -x "$out" ] && [ "$out" -nt "$patch" ] && [ "$out" -nt "$0" ] && exit 0      # the patch, or this file (another commit)
if [ ! -d "$src/.git" ]; then
    mkdir -p "$here/build"
    git clone -q https://github.com/quickshell-mirror/quickshell.git "$src"
fi
cd "$src"
git checkout -q -f 9b0f339b19057f4731bf3b48293307d7ef241671 && git clean -qfd src      # Quickshell 0.3.2, locked for this LatteOS
git apply "$patch"
# without jemalloc: with it, the PR's author and Quickshell's saw a crash at the start
cmake -GNinja -B build -DCMAKE_BUILD_TYPE=RelWithDebInfo -DUSE_JEMALLOC=OFF -DCRASH_HANDLER=OFF -DDISTRIBUTOR="LatteOS (web engine)" >/dev/null
ninja -C build
