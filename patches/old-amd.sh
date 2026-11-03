#!/bin/sh
# patches/old-amd.sh [remove]: Linux 7.3 and Mesa 26.3 for AMD cards of GFX6 to GFX8 (an RX 640 is one), until Fedora 45
# has them itself (ROADMAP 1D.16, docs/instalator/PLAN.md 3.4). install runs it with --old-amd, which the installer's
# window says when it finds such a card. Both locked, as tried on latte-lab:
#   Linux 7.3.1-200.fc45 from Koji (Fedora's own build, not signed: with Secure Boot on it does not start)
#   Mesa 26.3.0-rc3 from archive.mesa3d.org, built here into /opt/mesa-26.3 (radeonsi, RADV) and put first for
#   programs (ld.so.conf.d, the Vulkan ICD); Fedora's Mesa stays as it was beside it
# remove: Mesa goes and Fedora's Vulkan ICD comes back; the kernel stays (dnf removes it like any other).
set -eu
KERNEL=7.3.1-200.fc45
MESA=26.3.0-rc3
MESA_SHA256=3600c01f11439628d0a85de5ed9cb76f297d13e9783cdeecb91aa685055c9942
prefix=/opt/mesa-26.3
icd=/usr/share/vulkan/icd.d/radeon_icd.x86_64.json
kept="$prefix/radeon_icd.x86_64.json.fedora"     # Fedora's own ICD, to come back to
here="$(cd "$(dirname "$0")/.." && pwd)"
work="$here/build/mesa"
owner="${SUDO_USER:-}"; as_user() { if [ -n "$owner" ] && [ "$owner" != root ]; then sudo -u "$owner" "$@"; else "$@"; fi; }

if [ "${1:-}" = remove ]; then
    [ -f "$kept" ] && cp -f "$kept" "$icd"       # before the folder it is kept in goes
    rm -rf "$prefix" /etc/ld.so.conf.d/00-latte-mesa-26.3.conf
    ldconfig
    exit 0
fi

# Linux: Fedora's build of it, the parts a desktop needs
if ! rpm -q "kernel-core-$KERNEL" >/dev/null 2>&1; then
    base="https://kojipkgs.fedoraproject.org/packages/kernel/${KERNEL%%-*}/${KERNEL#*-}/x86_64"
    dnf install -y $(for p in kernel kernel-core kernel-modules kernel-modules-core kernel-modules-extra; do printf '%s/%s-%s.x86_64.rpm ' "$base" "$p" "$KERNEL"; done)
fi

# Mesa: built as the user who asked (its files stay theirs), put in place as root
if [ ! -f "$prefix/lib64/libvulkan_radeon.so" ]; then
    dnf builddep -y mesa                         # what Fedora itself builds Mesa with
    as_user mkdir -p "$work"
    [ -f "$work/mesa-$MESA.tar.xz" ] || as_user curl -fsSL -o "$work/mesa-$MESA.tar.xz" "https://archive.mesa3d.org/mesa-$MESA.tar.xz"
    echo "$MESA_SHA256  $work/mesa-$MESA.tar.xz" | sha256sum -c --quiet
    as_user tar -xf "$work/mesa-$MESA.tar.xz" -C "$work"
    cd "$work/mesa-$MESA"
    as_user meson setup build --buildtype=release --prefix="$prefix" -Dplatforms=x11,wayland \
        -Dgallium-drivers=radeonsi,llvmpipe,softpipe -Dvulkan-drivers=amd -Dgallium-va=disabled \
        -Dglx=dri -Degl=enabled -Dgbm=enabled -Dglvnd=enabled -Dllvm=enabled -Dvideo-codecs=all_free
    as_user ninja -C build
    ninja -C build install
fi
echo "$prefix/lib64" > /etc/ld.so.conf.d/00-latte-mesa-26.3.conf
ldconfig
# Vulkan finds RADV here; Fedora's own ICD is kept to come back to
[ -f "$kept" ] || ! grep -q '"/usr/' "$icd" 2>/dev/null || cp "$icd" "$kept"      # only Fedora's own (its library under /usr)
cp "$prefix/share/vulkan/icd.d/radeon_icd.x86_64.json" "$icd"
