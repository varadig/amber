# A lime natív könyvtárának (lime.hdll, HashLink) saját fordítása kontroller-rezgéssel (DualShock / DualSense / Switch Pro...).
# Ok: a lime 8.3.2 a beépített SDL-t -DSDL_HIDAPI_DISABLED-del fordítja: a HIDAPI-meghajtók (PS4, PS5, Switch...) nélkül a DualShock
# csak egyszerű joystick, nem rezeg (sem Bluetooth-on, sem USB-n). Ez a szkript a lime forrását ugyanazzal a beállítással fordítja, csak HIDAPI-val.
# Kimenet: native/mac/lime.hdll (Windowson native/windows/lime.hdll); a scripts/build-desktop.ps1 ezt teszi az appba a gyári helyett.
#   macOS:   pwsh scripts/build-lime-native.ps1            (kell: Xcode Command Line Tools, haxelib hxcpp)
#   Windows: powershell -ExecutionPolicy Bypass -File scripts/build-lime-native.ps1   (kell: Visual Studio C++ build tools, haxelib hxcpp)
param([string]$Work = "", [string]$LimeVersion = "8.3.2")
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
. "$PSScriptRoot/common.ps1"
if (-not $Work) { $Work = Join-Path ([IO.Path]::GetTempPath()) "amber-lime-src" }
if (-not (& haxelib list hxcpp 2>$null | Select-String hxcpp)) { & haxelib install hxcpp 4.3.2 --always; if ($LASTEXITCODE -ne 0) { throw "hxcpp telepítése nem sikerült" } }

# 1. a lime forrása a natív almodulokkal (SDL stb.), egyszer
if (-not (Test-Path (Join-Path $Work "project/Build.xml"))) {
    Write-Host "lime $LimeVersion forrás letöltése: $Work" -ForegroundColor Cyan
    & git clone -q --depth 1 --branch $LimeVersion --recurse-submodules --shallow-submodules https://github.com/openfl/lime $Work
    if ($LASTEXITCODE -ne 0) { throw "git clone nem sikerült" }
}
# 2. a HashLink-futtató könyvtárai a linkeléshez (a telepített lime-ból)
$limeLib = (& haxelib libpath lime).Trim()
$plat = if ($OnWindows) { "Windows64" } elseif ($OnMac) { "Mac64" } else { "Linux64" }
New-Item -ItemType Directory -Force (Join-Path $Work "templates/bin/hl") | Out-Null
Copy-Item -Recurse -Force (Join-Path $limeLib "templates/bin/hl/$plat") (Join-Path $Work "templates/bin/hl/")
Copy-Item -Recurse -Force (Join-Path $limeLib "templates/bin/hl/include") (Join-Path $Work "templates/bin/hl/")
# 3. a HIDAPI tiltása csak akkor, ha nincs AMBER_HIDAPI (így a fordításunk HIDAPI-val megy)
$files = Join-Path $Work "project/lib/sdl-files.xml"
$x = Get-Content $files -Raw
if ($x -notmatch 'SDL_HIDAPI_DISABLED" unless="AMBER_HIDAPI"') {
    $x = $x.Replace('<compilerflag value="-DSDL_HIDAPI_DISABLED" />', '<compilerflag value="-DSDL_HIDAPI_DISABLED" unless="AMBER_HIDAPI" />')
    [IO.File]::WriteAllText($files, $x)
}
# 4. fordítás (macOS: ha a Command Line Tools c++ fejléc-mappája hiányos, az SDK-ét tesszük előre)
$flags = if ($OnWindows) { @("-Dwindows", "-DHXCPP_M64", "-Dhashlink", "-DAMBER_HIDAPI") } elseif ($OnMac) { @("-Dmac", "-DHXCPP_CLANG", "-DHXCPP_M64", "-Dhashlink", "-DAMBER_HIDAPI") } else { @("-Dlinux", "-DHXCPP_M64", "-Dhashlink", "-DAMBER_HIDAPI") }
if ($OnMac -and -not $env:CPLUS_INCLUDE_PATH) {
    $sdk = (& xcrun --show-sdk-path).Trim()
    if (-not (Test-Path "/Library/Developer/CommandLineTools/usr/include/c++/v1/string")) { $env:CPLUS_INCLUDE_PATH = "$sdk/usr/include/c++/v1" }
}
Push-Location (Join-Path $Work "project")
try {
    Write-Host "Fordítás ($($flags -join ' '))... (néhány perc)" -ForegroundColor Cyan
    & haxelib run hxcpp Build.xml @flags
    if ($LASTEXITCODE -ne 0) { throw "a lime natív fordítása nem sikerült" }
} finally { Pop-Location }
$built = Join-Path $Work "ndll/$plat/lime.hdll"
$destDir = Join-Path $root $(if ($OnWindows) { "native/windows" } elseif ($OnMac) { "native/mac" } else { "native/linux" })
New-Item -ItemType Directory -Force $destDir | Out-Null
Copy-Item $built (Join-Path $destDir "lime.hdll") -Force
Write-Host "Kész: $(Join-Path $destDir 'lime.hdll') (a scripts/build-desktop.ps1 ezt használja)" -ForegroundColor Green
