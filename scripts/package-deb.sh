#!/usr/bin/env bash
# Build a release and package it as a .deb and a .tar.gz for Linux x64.
#
# Usage: scripts/package-deb.sh [<version>]
# The version defaults to the one in meson.build and must match it.
# Output: dist/masame_<version>_amd64.deb, dist/masame-<version>-linux-x64.tar.gz
# and a .sha256 file next to each.
set -euo pipefail

cd "$(dirname "$0")/.."

meson_version="$(sed -n "s/^ *version : '\([^']*\)'.*/\1/p" meson.build | head -1)"
version="${1:-$meson_version}"
if [[ "$version" != "$meson_version" ]]; then
  echo "version $version does not match meson.build ($meson_version)" >&2
  exit 1
fi

build_dir="build-release"
root="$build_dir/pkgroot"
dist="dist"

rm -rf "$build_dir/meson" "$root"
scripts/build.sh -r -b "$build_dir" -p /usr
DESTDIR="$PWD/$root" meson install -C "$build_dir/meson" --skip-subprojects
strip --strip-unneeded "$root/usr/bin/masame"

# Debian documentation files
docdir="$root/usr/share/doc/masame"
install -d "$docdir"
{
  echo "Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/"
  echo "Upstream-Name: Masame"
  echo "Source: https://github.com/moriyama-dev/masame"
  echo
  echo "Files: *"
  echo "License: MIT and others, see /usr/share/doc/masame/licenses.md"
  echo
  cat LICENSE
} > "$docdir/copyright"
chmod 0644 "$docdir"/*

size_kb="$(du -sk "$root/usr" | cut -f1)"
install -d "$root/DEBIAN"
cat > "$root/DEBIAN/control" <<EOF
Package: masame
Version: $version
Architecture: amd64
Maintainer: Yoshiro Moriyama <7315004+moriyama-dev@users.noreply.github.com>
Installed-Size: $size_kb
Depends: libc6 (>= 2.38), libx11-6, libxext6, libxcursor1, libxi6, libxrandr2, libxkbcommon0, libwayland-client0, libwayland-cursor0, libwayland-egl1, libdbus-1-3
Recommends: fonts-noto-cjk, libdecor-0-0, xdg-desktop-portal | zenity
Section: editors
Priority: optional
Homepage: https://github.com/moriyama-dev/masame
Description: lightweight text editor
 Masame is a lightweight, fast text editor with only the features you need.
 The interface is available in English and Japanese.
EOF
(cd "$root" && find usr -type f -exec md5sum {} + | sort -k2 > DEBIAN/md5sums)

mkdir -p "$dist"
deb="$dist/masame_${version}_amd64.deb"
dpkg-deb --root-owner-group -Zxz --build "$root" "$deb"

# Portable archive: the executable with its data directory next to it
tar_dir="$build_dir/masame-$version"
rm -rf "$tar_dir"
install -d "$tar_dir"
cp "$root/usr/bin/masame" "$tar_dir/"
cp -r "$root/usr/share/masame" "$tar_dir/data"
cp LICENSE licenses/licenses.md "$tar_dir/"
tarball="$dist/masame-$version-linux-x64.tar.gz"
tar -czf "$tarball" -C "$build_dir" "masame-$version"

(cd "$dist" && for f in "$(basename "$deb")" "$(basename "$tarball")"; do sha256sum "$f" > "$f.sha256"; done)
ls -la "$dist"
