; Inno Setup script for the Masame installer.
; Built by scripts/package-windows.sh with /DAppVersion, /DSourceDir,
; /DOutputDir and /DIconFile.

#define AppName "Masame"

[Setup]
AppId={{6B7E3D0C-2F4A-4C8E-9C51-6D1F0E8A3B27}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher=Yoshiro Moriyama
AppPublisherURL=https://github.com/moriyama-dev/masame
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir={#OutputDir}
OutputBaseFilename=masame-{#AppVersion}-windows-x64-setup
SetupIconFile={#IconFile}
UninstallDisplayIcon={app}\masame.exe
LicenseFile={#SourceDir}\LICENSE.txt
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ChangesAssociations=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "japanese"; MessagesFile: "compiler:Languages\Japanese.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "openwith"; Description: "{cm:OpenWithMasame}"; GroupDescription: "{cm:AdditionalIcons}"

[CustomMessages]
english.OpenWithMasame=Add "Open with Masame" to the right-click menu
japanese.OpenWithMasame=右クリックメニューに「Masame で開く」を追加する
english.OpenWithMasameMenu=Open with Masame
japanese.OpenWithMasameMenu=Masame で開く

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{app}\masame.exe"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\masame.exe"; Tasks: desktopicon

[Registry]
Root: HKA; Subkey: "Software\Classes\*\shell\Masame"; ValueType: string; ValueName: ""; ValueData: "{cm:OpenWithMasameMenu}"; Flags: uninsdeletekey; Tasks: openwith
Root: HKA; Subkey: "Software\Classes\*\shell\Masame"; ValueType: string; ValueName: "Icon"; ValueData: "{app}\masame.exe"; Tasks: openwith
Root: HKA; Subkey: "Software\Classes\*\shell\Masame\command"; ValueType: string; ValueName: ""; ValueData: """{app}\masame.exe"" ""%1"""; Tasks: openwith
Root: HKA; Subkey: "Software\Classes\Directory\shell\Masame"; ValueType: string; ValueName: ""; ValueData: "{cm:OpenWithMasameMenu}"; Flags: uninsdeletekey; Tasks: openwith
Root: HKA; Subkey: "Software\Classes\Directory\shell\Masame"; ValueType: string; ValueName: "Icon"; ValueData: "{app}\masame.exe"; Tasks: openwith
Root: HKA; Subkey: "Software\Classes\Directory\shell\Masame\command"; ValueType: string; ValueName: ""; ValueData: """{app}\masame.exe"" ""%1"""; Tasks: openwith

[Run]
Filename: "{app}\masame.exe"; Description: "{cm:LaunchProgram,{#AppName}}"; Flags: nowait postinstall skipifsilent
