# Homebrew cask for Masame. Updated by the Release workflow.
#   brew tap moriyama-dev/masame https://github.com/moriyama-dev/masame
#   brew install --cask masame
cask "masame" do
  version "0.3.0"
  sha256 "beefad1a8ccb9e20d705f3db5de3595f71bfeb69596c2cb155ebcb48c878c981"

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
