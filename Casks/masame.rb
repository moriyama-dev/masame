# Homebrew cask for Masame. Updated by the Release workflow.
#   brew tap moriyama-dev/masame https://github.com/moriyama-dev/masame
#   brew install --cask masame
cask "masame" do
  version "0.2.0"
  sha256 "6ccd0faa809c84054f24b0966435d04b5a1a0d6806eec750f7039c673a663228"

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
