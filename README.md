# Masame

**English** | [日本語](#日本語)

Masame is a lightweight, fast text editor for Linux.
It keeps a familiar, minimal interface and leaves out features you do not need.

- Interface languages: English and Japanese (easy to switch)
- No command palette, no build system, no project features (being removed)
- Small native binary (C + Lua, rendered with SDL3)

> Status: early development. There are no releases yet.

## Building

Masame is developed on Ubuntu 24.04.

```sh
sudo apt install build-essential meson ninja-build cmake pkg-config \
  libx11-dev libxext-dev libxrandr-dev libxcursor-dev libxi-dev libxss-dev \
  libxfixes-dev libxtst-dev libxkbcommon-dev libwayland-dev wayland-protocols \
  libdecor-0-dev libegl-dev libgl-dev libdbus-1-dev libibus-1.0-dev

scripts/build.sh
```

`scripts/build.sh` downloads and builds SDL3 (statically linked), then builds
Masame with Meson. FreeType, PCRE2 and Lua are built from the Meson wraps in
`subprojects/`.

To run it without installing:

```sh
scripts/build.sh -b build-portable --portable
DESTDIR="$PWD/build-portable/install" meson install -C build-portable/meson --skip-subprojects
build-portable/install/masame
```

## License

MIT. Masame is based on [Lite XL](https://github.com/lite-xl/lite-xl).
See [LICENSE](LICENSE) and [licenses/licenses.md](licenses/licenses.md).

---

## 日本語

Masame（柾目）は、Linux 向けの軽くて速いテキストエディタです。
なじみのあるシンプルな画面のまま、使わない機能を削っています。
名前の柾目は、まっすぐにそろった木目のことです。

- 表示言語：英語と日本語（簡単に切り替えられます）
- コマンドパレット、ビルド、プロジェクトの機能はありません（削除作業中）
- 小さなネイティブのプログラム（C と Lua、描画は SDL3）

> 状況：開発を始めたところです。まだリリースはありません。

### ビルド

Ubuntu 24.04 で開発しています。必要なパッケージと手順は、上の
[Building](#building) と同じです。

### ライセンス

MIT ライセンスです。Masame は [Lite XL](https://github.com/lite-xl/lite-xl) をもとにしています。
