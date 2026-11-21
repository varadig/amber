# Fejlesztői környezet ellenőrzése és a függőségek telepítése (rögzített verziók).
# Futtatás: VS Code > Run Task > "Install dependencies (haxelib)", vagy:
#   powershell -ExecutionPolicy Bypass -File scripts/setup.ps1

$ErrorActionPreference = "Stop"

. "$PSScriptRoot/common.ps1"
if (-not (Get-Command haxe -ErrorAction SilentlyContinue)) {
    Write-Host "Haxe nem található (a PATH-on)." -ForegroundColor Red
    if ($OnWindows) { Write-Host "Telepítsd a Haxe 4.3.6-ot (https://haxe.org/download/ vagy: winget install HaxeFoundation.Haxe --version 4.3.6)" }
    else { Write-Host "Telepítsd a Haxe 4.3.6-ot (https://haxe.org/download/ macOS-csomag, vagy Homebrew: brew install haxe)" }
    exit 1
}

$version = (& haxe -version).Trim()
Write-Host "Haxe: $version"
if ($version -ne "4.3.6") {
    Write-Host "Figyelem: a projekt Haxe 4.3.6-tal készült (most: $version)." -ForegroundColor Yellow
}

# haxelib tároló beállítása, ha még nincs
& haxelib config *> $null
if ($LASTEXITCODE -ne 0) {
    $libDir = if ($OnWindows -and (Test-Path "C:/HaxeToolkit/haxe")) { "C:\HaxeToolkit\haxe\lib" } else { Join-Path $HOME "haxelib" }
    New-Item -ItemType Directory -Force $libDir | Out-Null
    & haxelib setup $libDir
}

# A projekt ezekre a verziókra van írva (lásd CLAUDE.md / Project.xml)
$libs = [ordered]@{ "lime" = "8.3.2"; "openfl" = "9.5.2"; "flixel" = "6.2.1"; "box2d" = "1.2.4" }
foreach ($name in $libs.Keys) {
    $ver = $libs[$name]
    Write-Host "haxelib install $name $ver"
    & haxelib install $name $ver --always --quiet
    if ($LASTEXITCODE -ne 0) { throw "Nem sikerült telepíteni: $name $ver" }
    & haxelib set $name $ver --always | Out-Null
}

Write-Host ""
& haxelib list
Write-Host ""
Write-Host "Kész. Futtatás: VS Code > Run Task > 'Run HTML5 (browser)', vagy F5." -ForegroundColor Green
