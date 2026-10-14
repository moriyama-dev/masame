#!/usr/bin/env bash
# Build a release for Windows x64 and package it (run in MSYS2 MINGW64).
#
# Usage: scripts/package-windows.sh [<version>]
# Output: dist/masame-<version>-windows-x64.zip, and
# dist/masame-<version>-windows-x64-setup.exe when Inno Setup is installed.
set -euo pipefail

cd "$(dirname "$0")/.."

meson_version="$(sed -n "s/^ *version : '\([^']*\)'.*/\1/p" meson.build | head -1)"
version="${1:-$meson_version}"
if [[ "$version" != "$meson_version" ]]; then
  echo "version $version does not match meson.build ($meson_version)" >&2
  exit 1
fi

build_dir="build-release"
app="$build_dir/Masame"
dist="dist"

rm -rf "$build_dir/meson" "$app"
scripts/build.sh -r -b "$build_dir"
DESTDIR="$PWD/$app" meson install -C "$build_dir/meson" --skip-subprojects
# meson installs the portable layout under the drive-less prefix path
exe="$(find "$app" -name masame.exe | head -1)"
root="$(dirname "$exe")"
if [[ "$root" != "$app" ]]; then
  mv "$root"/* "$app"/
fi
find "$app" -mindepth 1 -maxdepth 1 -type d ! -name data ! -name doc -exec rm -rf {} +
strip "$app/masame.exe"
cp LICENSE "$app/LICENSE.txt"
ls "$app"

mkdir -p "$dist"
zip_name="masame-$version-windows-x64.zip"
(cd "$build_dir" && rm -f "$zip_name" && zip -qr "$zip_name" Masame)
mv "$build_dir/$zip_name" "$dist/"

iscc="/c/Program Files (x86)/Inno Setup 6/ISCC.exe"
if [[ -x "$iscc" ]]; then
  "$iscc" -Q "-DAppVersion=$version" "-DSourceDir=$(cygpath -w "$PWD/$app")" \
    "-DOutputDir=$(cygpath -w "$PWD/$dist")" "-DIconFile=$(cygpath -w "$PWD/resources/icons/icon.ico")" \
    resources/windows/masame.iss
else
  echo "Inno Setup not found: skipping the installer" >&2
fi

(cd "$dist" && for f in masame-"$version"-windows-x64*; do [[ "$f" == *.sha256 ]] || sha256sum "$f" > "$f.sha256"; done)
ls -la "$dist"
