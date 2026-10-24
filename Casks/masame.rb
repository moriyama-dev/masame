# Homebrew cask for Masame. Updated by the Release workflow.
#   brew tap moriyama-dev/masame https://github.com/moriyama-dev/masame
#   brew install --cask moriyama-dev/masame/masame
cask "masame" do
  version "0.4.0"
  sha256 "0bc2cb8dc630976a3c0fb8eef86ec455889cf3c6a4ec328a8bacf9d1d9e03a37"

  url "https://github.com/moriyama-dev/masame/releases/download/#{version}/masame-#{version}-macos-universal.dmg"
  name "Masame"
  desc "Lightweight text editor"
  homepage "https://github.com/moriyama-dev/masame"

  depends_on macos: ">= :big_sur"

  app "Masame.app"
  binary "#{appdir}/Masame.app/Contents/MacOS/masame"

  # The app is not notarized: remove the quarantine flag so that it opens
  # without the "cannot be verified" warning.
  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-dr", "com.apple.quarantine", "#{appdir}/Masame.app"]
  end

  zap trash: "~/.config/masame"
end
