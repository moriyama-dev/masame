#!/usr/bin/env bash
# Build a universal (Apple Silicon + Intel) Masame.app and package it as a .dmg.
# Run on an Apple Silicon Mac with Homebrew bash, meson, ninja and cmake.
#
# Usage: scripts/package-macos.sh [<version>]
# Output: dist/masame-<version>-macos-universal.dmg (+ .sha256)
set -euo pipefail

cd "$(dirname "$0")/.."

meson_version="$(sed -n "s/^ *version : '\([^']*\)'.*/\1/p" meson.build | head -1)"
version="${1:-$meson_version}"
if [[ "$version" != "$meson_version" ]]; then
  echo "version $version does not match meson.build ($meson_version)" >&2
  exit 1
fi

build_dir="build-release"
app="$build_dir/Masame.app"
dist="dist"

rm -rf "$build_dir"/meson* "$app"
scripts/build.sh -r -b "$build_dir" -p / --bundle
scripts/build.sh -r -b "$build_dir" -p / --bundle --cross-file resources/cross/macos-x86_64.txt
DESTDIR="$PWD/$app" meson install -C "$build_dir/meson" --skip-subprojects

lipo -create "$build_dir/meson/src/masame" "$build_dir/meson-macos-x86_64/src/masame" \
  -output "$app/Contents/MacOS/masame"
strip -x "$app/Contents/MacOS/masame"
lipo -info "$app/Contents/MacOS/masame"
cp LICENSE "$app/Contents/Resources/"

# Ad-hoc signature (required to run on Apple Silicon; not notarized)
codesign --force --deep --sign - "$app"
codesign --verify --verbose "$app"

mkdir -p "$dist"
dmg_root="$build_dir/dmg"
rm -rf "$dmg_root"
mkdir -p "$dmg_root"
cp -R "$app" "$dmg_root/"
ln -s /Applications "$dmg_root/Applications"
dmg="$dist/masame-$version-macos-universal.dmg"
rm -f "$dmg"
hdiutil create -volname "Masame" -srcfolder "$dmg_root" -ov -format UDZO "$dmg"
(cd "$dist" && shasum -a 256 "$(basename "$dmg")" > "$(basename "$dmg").sha256")
ls -la "$dist"
