# Masame

**English** | [日本語](#日本語)

Masame is a lightweight, fast text editor for Linux, Windows and macOS.
It keeps a familiar, minimal interface and leaves out features you do not need.

- Menu bar, side bar, tabs, minimap, multiple cursors, find in files, split views
- Interface in English or Japanese: **Preferences → English / 日本語** (applied immediately)
- System dialogs for Open File, Open Folder and Save As
- No command palette, no build system, no project features
- Small native program (C + Lua, rendered with SDL3)

## Install

### Windows

Windows 10/11 x64. Download `masame-<version>-windows-x64-setup.exe` (installer)
or the `.zip` from [Releases](https://github.com/moriyama-dev/masame/releases).
The program is not code-signed: if SmartScreen warns, choose **More info → Run anyway**.

### macOS

macOS 11 or later, Apple Silicon and Intel. With [Homebrew](https://brew.sh):

```sh
brew tap moriyama-dev/masame https://github.com/moriyama-dev/masame
brew install --cask masame
```

Updates then come with `brew upgrade`. You can also use the `.dmg` from
[Releases](https://github.com/moriyama-dev/masame/releases); the app is not
notarized, so the first time open **System Settings → Privacy & Security** and
choose **Open Anyway**.

### Linux (Ubuntu / Debian)

Linux x64, Ubuntu 24.04 or later.

```sh
sudo install -d -m 0755 /etc/apt/keyrings
curl -fsSL https://moriyama-dev.github.io/masame/masame-archive-keyring.gpg | sudo tee /etc/apt/keyrings/masame-archive-keyring.gpg > /dev/null
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/masame-archive-keyring.gpg] https://moriyama-dev.github.io/masame stable main" | sudo tee /etc/apt/sources.list.d/masame.list > /dev/null
sudo apt update
sudo apt install masame
```

Updates then come with `sudo apt upgrade`. The `.deb` and a portable `.tar.gz`
are also on the [Releases](https://github.com/moriyama-dev/masame/releases) page.

Japanese text is drawn with a system font (Noto Sans CJK on Linux, Yu Gothic or
Meiryo on Windows, Hiragino Sans on macOS). On Linux, if it shows as boxes,
install `fonts-noto-cjk`.

## Settings

**Preferences → Settings** opens `~/.config/masame/init.lua`
(`%USERPROFILE%\.config\masame\init.lua` on Windows). Changes are
applied when you save it. For example:

```lua
local config = require "core.config"
local style = require "core.style"
config.indent_size = 2
config.plugins.minimap.enabled = false
```

## Building

```sh
sudo apt install build-essential meson ninja-build cmake pkg-config \
  libx11-dev libxext-dev libxrandr-dev libxcursor-dev libxi-dev libxss-dev \
  libxfixes-dev libxtst-dev libxkbcommon-dev libwayland-dev wayland-protocols \
  libdecor-0-dev libegl-dev libgl-dev libdbus-1-dev libibus-1.0-dev

scripts/build.sh                 # development build in build/
scripts/package-deb.sh           # release .deb and .tar.gz in dist/
```

`scripts/build.sh` downloads and builds SDL3 (statically linked), then builds
Masame with Meson. FreeType, PCRE2 and Lua are built from the Meson wraps in
`subprojects/`.

To run without installing:

```sh
scripts/build.sh -b build-portable --portable
DESTDIR="$PWD/build-portable/install" meson install -C build-portable/meson --skip-subprojects
build-portable/install/masame
```

Windows builds use MSYS2 (MINGW64) with `scripts/package-windows.sh`, and macOS
builds use `scripts/package-macos.sh` on an Apple Silicon Mac.

Releases are built by GitHub Actions when a version tag (such as `0.1.0`,
matching `meson.build`) is pushed.

## License

MIT. Masame is based on [Lite XL](https://github.com/lite-xl/lite-xl).
See [LICENSE](LICENSE) and [licenses/licenses.md](licenses/licenses.md).

---

## 日本語

Masame（柾目）は、Linux、Windows、Mac で使える、軽くて速いテキストエディタです。
なじみのあるシンプルな画面のまま、使わない機能を削っています。
名前の柾目は、まっすぐにそろった木目のことです。

- メニューバー、サイドバー、タブ、ミニマップ、複数カーソル、フォルダー内の検索、画面の分割
- 表示は英語と日本語を切り替えられます：**設定 → English / 日本語**（すぐに反映されます）
- ファイルを開く／フォルダーを開く／名前を付けて保存は、OS 標準のダイアログを使います
- コマンドパレット、ビルド、プロジェクトの機能はありません
- 小さなネイティブのプログラム（C と Lua、描画は SDL3）

### インストール

- **Windows**（10/11、x64）：[Releases](https://github.com/moriyama-dev/masame/releases) から `masame-<版>-windows-x64-setup.exe`（インストーラー）か `.zip` をダウンロードします。署名がないため SmartScreen の警告が出たら、「詳細情報」→「実行」を選んでください。
- **Mac**（macOS 11 以降、Apple シリコンと Intel）：Homebrew で `brew tap moriyama-dev/masame https://github.com/moriyama-dev/masame` のあと `brew install --cask masame`。更新は `brew upgrade` です。.dmg から入れた場合は、初回だけ「システム設定 → プライバシーとセキュリティ」で「このまま開く」を押してください。
- **Linux**（Ubuntu 24.04 以降、x64）：上の [Linux](#linux-ubuntu--debian) の手順で apt に登録します。更新は `sudo apt upgrade` です。

日本語は OS のフォントで表示します（Linux は Noto Sans CJK、Windows は游ゴシックかメイリオ、Mac はヒラギノ角ゴシック）。Linux で文字が □ になるときは `fonts-noto-cjk` を入れてください。

### 設定

**設定 → 設定ファイル** で `~/.config/masame/init.lua` が開きます。保存すると反映されます。

### ライセンス

MIT ライセンスです。Masame は [Lite XL](https://github.com/lite-xl/lite-xl) をもとにしています。
