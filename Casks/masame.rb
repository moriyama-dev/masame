# Homebrew cask for Masame. Updated by the Release workflow.
#   brew tap moriyama-dev/masame https://github.com/moriyama-dev/masame
#   brew install --cask masame
cask "masame" do
  version "0.2.2"
  sha256 "d33e2454f9cd3625ea0afb29b64664e0ce3bfd1e6769bde9c813d72212f74a33"

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
