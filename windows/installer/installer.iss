#include "CodeDependencies.iss"

#define BuildOutputFolder "..\..\build\windows\x64\runner\Release"
#define OutputExeName "photobooth.exe"
#define OutputExePath BuildOutputFolder + "\" + OutputExeName
#define OutputExeRawVersion GetVersionNumbersString(OutputExePath)

#define OrganizationName "MomentoBooth"
#define AppName "Photobooth"
#define FullAppName OrganizationName + " " + AppName

#define DeleteLastDigitFromVersion(version) Local[1] = Copy(version, 1, (Local[0] = RPos(".", version)) - 1), version = Local[1]
#define ApplicationVersion DeleteLastDigitFromVersion(OutputExeRawVersion)

[Setup]
AppName={#FullAppName}
AppVersion={#ApplicationVersion}
WizardStyle=modern
DefaultDirName={autopf}\MomentoBooth\Photobooth
DefaultGroupName=MomentoBooth
UninstallDisplayIcon={app}\photobooth.exe
Compression=lzma2
SolidCompression=yes
OutputDir=.
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
DisableWelcomePage=false
UninstallDisplayName={#FullAppName}
OutputBaseFilename=installer

[Files]
Source: {#BuildOutputFolder}\*; DestDir: {app}; Flags: recursesubdirs

[Icons]
Name: {userdesktop}\{#AppName}; Filename: {app}\{#OutputExeName}; IconFilename: {app}\{#OutputExeName}; Tasks: desktopicon
Name: {group}\MomentoBooth; Filename: {app}\{#OutputExeName}

[Tasks]
Name: desktopicon; Description: {cm:CreateDesktopIcon}; GroupDescription: {cm:AdditionalIcons}; Flags: unchecked

[Run]
Filename: {app}\{#OutputExeName}; Description: {cm:LaunchProgram,{#AppName}}; Flags: nowait postinstall skipifsilent

[Code]
function InitializeSetup: Boolean;
begin
  Dependency_AddVC2015To2022;

  Result := True;
end;
