# Régi név: a natív asztali build a scripts/build-desktop.ps1 (Windowson .exe, macOS-en .app). Ugyanazok a kapcsolók: [-Cheats] [-Run]
param([switch]$Cheats, [switch]$Run)
& (Join-Path $PSScriptRoot "build-desktop.ps1") -Cheats:$Cheats -Run:$Run
exit $LASTEXITCODE
