#!/usr/bin/env bash
# Build Masame on Linux.
#
# SDL3 is not packaged on Ubuntu 24.04, so it is downloaded, built and linked
# statically. X11/Wayland libraries are loaded at runtime (SDL_DEPS_SHARED).
#
# Usage: scripts/build.sh [-b <build dir>] [-r] [-p <prefix>] [--portable]
#   -b  build directory (default: build)
#   -r  release build (default: debugoptimized)
#   -p  install prefix (default: /usr)
#   --portable  install data next to the executable (for local testing)
set -euo pipefail

cd "$(dirname "$0")/.."

SDL3_VERSION="3.2.14"
SDL3_SHA256="b7e7dc05011b88c69170fe18935487b2559276955e49113f8c1b6b72c9b79c1f"

build_dir="build"
build_type="debugoptimized"
prefix="/usr"
portable="false"
while [[ $# -gt 0 ]]; do
  case "$1" in
    -b) build_dir="$2"; shift 2;;
    -r) build_type="release"; shift;;
    -p) prefix="$2"; shift 2;;
    --portable) portable="true"; shift;;
    *) echo "unknown option: $1" >&2; exit 1;;
  esac
done

mkdir -p "$build_dir"
sdl_dir="$build_dir/SDL3-$SDL3_VERSION"
sdl_prefix="$(cd "$build_dir" && pwd -P)/sdl3-prefix"

if [[ ! -f "$sdl_prefix/lib/pkgconfig/sdl3.pc" ]]; then
  tarball="$build_dir/SDL3-$SDL3_VERSION.tar.gz"
  if [[ ! -f "$tarball" ]]; then
    curl -fL -o "$tarball" \
      "https://github.com/libsdl-org/SDL/releases/download/release-$SDL3_VERSION/SDL3-$SDL3_VERSION.tar.gz"
  fi
  echo "$SDL3_SHA256  $tarball" | sha256sum -c -
  rm -rf "$sdl_dir"
  tar -xzf "$tarball" -C "$build_dir"
  cmake -S "$sdl_dir" -B "$sdl_dir/build" -GNinja \
    -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_INSTALL_PREFIX="$sdl_prefix" \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DSDL_INSTALL=ON -DSDL_INSTALL_DOCS=OFF -DSDL_DEPS_SHARED=ON \
    -DSDL_DBUS=ON -DSDL_IBUS=ON -DSDL_AUDIO=OFF -DSDL_GPU=OFF -DSDL_RPATH=OFF -DSDL_PIPEWIRE=OFF \
    -DSDL_CAMERA=OFF -DSDL_JOYSTICK=OFF -DSDL_HAPTIC=OFF -DSDL_HIDAPI=OFF -DSDL_DIALOG=ON \
    -DSDL_POWER=OFF -DSDL_SENSOR=OFF -DSDL_VULKAN=OFF -DSDL_LIBUDEV=OFF -DSDL_SHARED=OFF -DSDL_STATIC=ON \
    -DSDL_X11=ON -DSDL_WAYLAND=ON -DSDL_TESTS=OFF -DSDL_EXAMPLES=OFF -DSDL_VENDOR_INFO=masame
  cmake --build "$sdl_dir/build"
  cmake --install "$sdl_dir/build"
fi

meson_dir="$build_dir/meson"
if [[ ! -d "$meson_dir" ]]; then
  meson setup "$meson_dir" \
    --buildtype="$build_type" \
    --prefix="$prefix" \
    --pkg-config-path="$sdl_prefix/lib/pkgconfig" \
    --wrap-mode=forcefallback \
    -Dportable="$portable"
fi
meson compile -C "$meson_dir"
