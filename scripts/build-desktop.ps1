# Asztali (natív) változat a futtató gép rendszerére, HashLink-kal (C++ fordító nem kell: a lime hozza a futtatót):
#   Windows: export/hl/bin/Amber.exe (+ dll / hdll / hlboot.dat) -> zip: export/Amber-windows-<verzió>.zip
#   macOS:   export/hl/bin/Amber.app                              -> zip: export/Amber-mac-<verzió>.zip (x86-64; Apple Siliconon Rosettával fut)
#   Windows: powershell -ExecutionPolicy Bypass -File scripts/build-desktop.ps1 [-Cheats] [-Run]
#   macOS:   pwsh scripts/build-desktop.ps1 [-Cheats] [-Run]
#   Release (alap): cheat nélkül, a végén zip (ezt lehet kiadni). -Cheats: fejlesztői build (F9 cheat-menü), NEM készül zip, nem kiadható.
#   Cheat-buildben a böngészős URL-paraméterek argumentumként (az első argumentum a HashLink-nak a bájtkód fájl):
#     Windows: export/hl/bin/Amber.exe hlboot.dat level=3 goto=exit parts=all
#     macOS:   export/hl/bin/Amber.app/Contents/MacOS/hl hlboot.dat level=3   (a Contents/MacOS mappából)
#   -Run: a build után elindítja.
#   Rezgés-próba (cheat-build): a kontrollerek kiírása + 3 rezgés: ...Amber.app/Contents/MacOS/Amber rumbletest=1  (Windows: Amber.exe hlboot.dat rumbletest=1)
param([switch]$Cheats, [switch]$Run)
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
. "$PSScriptRoot/common.ps1"
$bin = Join-Path $root "export/hl/bin"
# a futó példány zárolja a fájlokat (Windows) / régi példány maradna (macOS)
if ($OnWindows) { Get-Process Amber -ErrorAction SilentlyContinue | Where-Object { $_.Path -like "*export\hl\bin*" } | Stop-Process -ErrorAction SilentlyContinue }
else { & pkill -f "export/hl/bin/Amber.app/Contents/MacOS/hl" 2>$null | Out-Null }
$extra = @()
if ($Cheats) { $extra += "-Dcheats" }
$out = & haxelib run lime build hl @extra 2>&1
$errs = $out | Select-String -Pattern "\.hx:[0-9]+|^Error"
$boot = if ($OnWindows) { Join-Path $bin "hlboot.dat" } else { Join-Path $bin "Amber.app/Contents/MacOS/hlboot.dat" }
if ($errs -or -not (Test-Path $boot)) { $errs | ForEach-Object { Write-Host $_ -ForegroundColor Red }; exit 1 }
# saját fordítású lime natív könyvtár (native/<platform>/lime.hdll, ha van): a gyári lime.hdll SDL-je nem rezegteti a DualShockot (lásd native/README.md)
$custom = if ($OnWindows) { Join-Path $root "native/windows/lime.hdll" } elseif ($OnMac) { Join-Path $root "native/mac/lime.hdll" } else { "" }
if ($custom -and (Test-Path $custom)) {
    $dst = if ($OnWindows) { Join-Path $bin "lime.hdll" } else { Join-Path $bin "Amber.app/Contents/MacOS/lime.hdll" }
    Copy-Item $custom $dst -Force
    Write-Host "Saját lime.hdll: $custom" -ForegroundColor DarkGray
}
$app = if ($OnWindows) { "export/hl/bin/Amber.exe" } else { "export/hl/bin/Amber.app" }
if ($OnMac) {
    # a Finder / Dock az ikont gyorsítótárazza (az első build még a HaxeFlixel-ikonnal regisztrált): frissítés
    & touch (Join-Path $bin "Amber.app")
    & "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister" -f (Join-Path $bin "Amber.app") 2>$null
}
Write-Host "Kész: $app" -ForegroundColor Green
if (-not $Cheats) {
    # a release-be nem kerülhet cheat-kód
    if ([System.Text.Encoding]::ASCII.GetString([System.IO.File]::ReadAllBytes($boot)).Contains("CheatSubState")) { Write-Host "HIBA: a release tartalmazza a CheatSubState-et" -ForegroundColor Red; exit 1 }
    $ver = ([xml](Get-Content (Join-Path $root "Project.xml"))).project.meta.version
    if ($OnWindows) {
        $zip = Join-Path $root "export/Amber-windows-$ver.zip"
        if (Test-Path $zip) { Remove-Item $zip }
        Compress-Archive -Path (Join-Path $bin "*") -DestinationPath $zip
    } else {
        # a ditto megtartja az .app futtatási jogait és a szimbolikus linkeket (a sima zip / Compress-Archive nem)
        $zip = Join-Path $root "export/Amber-mac-$ver.zip"
        if (Test-Path $zip) { Remove-Item $zip }
        & ditto -c -k --keepParent (Join-Path $bin "Amber.app") $zip
    }
    Write-Host "Zip: $zip ($([math]::Round((Get-Item $zip).Length / 1MB, 1)) MB)" -ForegroundColor Green
} else {
    Write-Host "Fejlesztői (cheat) build: csak belső tesztre, nem kiadható." -ForegroundColor Yellow
}
if ($Run) {
    if ($OnWindows) { Start-Process (Join-Path $bin "Amber.exe") -WorkingDirectory $bin }
    else { & open (Join-Path $bin "Amber.app") }
}
