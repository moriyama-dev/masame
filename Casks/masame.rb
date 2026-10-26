# Homebrew cask for Masame. Updated by the Release workflow.
#   brew tap moriyama-dev/masame https://github.com/moriyama-dev/masame
#   brew install --cask moriyama-dev/masame/masame
cask "masame" do
  version "0.5.1"
  sha256 "8d8ec435e0fbc43e553b2c8d03a096a3f38cdb29c9dfa261899277111acb2739"

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
