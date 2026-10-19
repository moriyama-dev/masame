#!/usr/bin/env bash
# Build Masame on Linux, Windows (MSYS2 MINGW64) or macOS.
#
# SDL3 is downloaded, built and linked statically. On Linux, X11/Wayland
# libraries are loaded at runtime (SDL_DEPS_SHARED). On macOS, SDL3 is built
# as a universal (arm64 + x86_64) library.
#
# Usage: scripts/build.sh [-b <build dir>] [-r] [-p <prefix>] [--portable]
#                         [--bundle] [--cross-file <file>]
#   -b  build directory (default: build)
#   -r  release build (default: debugoptimized)
#   -p  install prefix (default: /usr)
#   --portable    install data next to the executable (always on Windows)
#   --bundle      macOS: install as Masame.app layout
#   --cross-file  Meson cross file (macOS: build the x86_64 slice)
set -euo pipefail

cd "$(dirname "$0")/.."

SDL3_VERSION="3.2.14"
SDL3_SHA256="b7e7dc05011b88c69170fe18935487b2559276955e49113f8c1b6b72c9b79c1f"

build_dir="build"
build_type="debugoptimized"
prefix="/usr"
portable="false"
bundle="false"
cross_file=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -b) build_dir="$2"; shift 2;;
    -r) build_type="release"; shift;;
    -p) prefix="$2"; shift 2;;
    --portable) portable="true"; shift;;
    --bundle) bundle="true"; shift;;
    --cross-file) cross_file="$2"; shift 2;;
    *) echo "unknown option: $1" >&2; exit 1;;
  esac
done

case "$(uname -s)" in
  Linux*) os="linux";;
  Darwin*) os="macos";;
  MINGW*|MSYS*|CYGWIN*) os="windows";;
  *) echo "unsupported system: $(uname -s)" >&2; exit 1;;
esac

sdl_os_flags=()
case "$os" in
  linux) sdl_os_flags=(-DSDL_DEPS_SHARED=ON -DSDL_DBUS=ON -DSDL_IBUS=ON -DSDL_X11=ON -DSDL_WAYLAND=ON -DSDL_PIPEWIRE=OFF -DSDL_LIBUDEV=OFF);;
  macos) export MACOSX_DEPLOYMENT_TARGET="11.0"
         sdl_os_flags=("-DCMAKE_OSX_ARCHITECTURES=arm64;x86_64" -DCMAKE_OSX_DEPLOYMENT_TARGET=11.0);;
  windows) portable="true";;
esac

mkdir -p "$build_dir"
sdl_dir="$build_dir/SDL3-$SDL3_VERSION"
sdl_prefix="$(cd "$build_dir" && pwd -P)/sdl3-prefix"

# Small fixes to SDL3 itself (resources/<os>/sdl3-*.patch). SDL3 is rebuilt
# whenever this set of patches changes.
sdl_patches=()
for p in resources/"$os"/sdl3-*.patch; do
  [[ -f "$p" ]] && sdl_patches+=("$p")
done
sdl_stamp="$SDL3_VERSION"
if (( ${#sdl_patches[@]} )); then
  sdl_stamp="$sdl_stamp $(cat "${sdl_patches[@]}" | sha256sum | cut -d' ' -f1)"
fi

if [[ ! -f "$sdl_prefix/lib/pkgconfig/sdl3.pc" || "$(cat "$sdl_prefix/.masame-stamp" 2>/dev/null)" != "$sdl_stamp" ]]; then
  tarball="$build_dir/SDL3-$SDL3_VERSION.tar.gz"
  if [[ ! -f "$tarball" ]]; then
    curl -fL -o "$tarball" \
      "https://github.com/libsdl-org/SDL/releases/download/release-$SDL3_VERSION/SDL3-$SDL3_VERSION.tar.gz"
  fi
  echo "$SDL3_SHA256  $tarball" | sha256sum -c -
  rm -rf "$sdl_dir"
  tar -xzf "$tarball" -C "$build_dir"
  for p in "${sdl_patches[@]}"; do
    patch -d "$sdl_dir" -p1 < "$p"
  done
  rm -rf "$sdl_dir/build" "$sdl_prefix"
  cmake -S "$sdl_dir" -B "$sdl_dir/build" -GNinja \
    -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_INSTALL_PREFIX="$sdl_prefix" \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DSDL_INSTALL=ON -DSDL_INSTALL_DOCS=OFF \
    -DSDL_AUDIO=OFF -DSDL_GPU=OFF -DSDL_RPATH=OFF \
    -DSDL_CAMERA=OFF -DSDL_JOYSTICK=OFF -DSDL_HAPTIC=OFF -DSDL_HIDAPI=OFF -DSDL_DIALOG=ON \
    -DSDL_POWER=OFF -DSDL_SENSOR=OFF -DSDL_VULKAN=OFF -DSDL_SHARED=OFF -DSDL_STATIC=ON \
    -DSDL_TESTS=OFF -DSDL_EXAMPLES=OFF -DSDL_VENDOR_INFO=masame "${sdl_os_flags[@]}"
  cmake --build "$sdl_dir/build"
  cmake --install "$sdl_dir/build"
  echo "$sdl_stamp" > "$sdl_prefix/.masame-stamp"
fi

meson_dir="$build_dir/meson"
if [[ -n "$cross_file" ]]; then
  meson_dir="$build_dir/meson-$(basename "$cross_file" .txt)"
fi
if [[ ! -d "$meson_dir" ]]; then
  extra=()
  [[ -n "$cross_file" ]] && extra+=(--cross-file "$cross_file")
  [[ "$os" == "macos" ]] && extra+=(-Dbundle="$bundle")
  # SDL3 is the only dependency taken from outside the Meson wraps
  PKG_CONFIG_PATH="$sdl_prefix/lib/pkgconfig" meson setup "$meson_dir" \
    --buildtype="$build_type" \
    --prefix="$prefix" \
    --pkg-config-path="$sdl_prefix/lib/pkgconfig" \
    --wrap-mode=forcefallback \
    -Dportable="$portable" \
    "${extra[@]}"
fi
meson compile -C "$meson_dir"
