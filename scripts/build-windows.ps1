# Windows-változat (HashLink, nem kell hozzá C++ fordító: a lime hozza a futtatót): export\hl\bin\Amber.exe (+ dll / hdll / hlboot.dat).
#   powershell -ExecutionPolicy Bypass -File scripts/build-windows.ps1 [-Cheats] [-Run]
#   Release (alap): cheat nélkül, a végén zip: export\Amber-windows-<verzió>.zip (ezt lehet kiadni).
#   -Cheats: fejlesztői build (F9 cheat-menü), NEM készül zip, nem kiadható. Indítás közvetlenül pályára (a böngészős URL-paraméterek megfelelője):
#     export\hl\bin\Amber.exe hlboot.dat level=3 goto=exit parts=all   (az első argumentum a HashLink-nak a bájtkód fájl)
#   -Run: a build után elindítja.
param([switch]$Cheats, [switch]$Run)
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
if (-not $env:HAXEPATH -and (Test-Path "C:\HaxeToolkit\haxe")) { $env:HAXEPATH = "C:\HaxeToolkit\haxe" }
# a futó példány zárolja a fájlokat
Get-Process Amber -ErrorAction SilentlyContinue | Where-Object { $_.Path -like "*export\hl\bin*" } | Stop-Process -ErrorAction SilentlyContinue
$extra = @()
if ($Cheats) { $extra += "-Dcheats" }
$out = & haxelib run lime build hl @extra 2>&1
$errs = $out | Select-String -Pattern "\.hx:[0-9]+|^Error"
if ($errs -or -not (Test-Path "export\hl\bin\hlboot.dat")) { $errs | ForEach-Object { Write-Host $_ -ForegroundColor Red }; exit 1 }
$bin = Join-Path $root "export\hl\bin"
Write-Host "Kész: export\hl\bin\Amber.exe" -ForegroundColor Green
if (-not $Cheats) {
    # a release-be nem kerülhet cheat-kód
    $boot = [System.IO.File]::ReadAllBytes((Join-Path $bin "hlboot.dat"))
    if ([System.Text.Encoding]::ASCII.GetString($boot).Contains("CheatSubState")) { Write-Host "HIBA: a release tartalmazza a CheatSubState-et" -ForegroundColor Red; exit 1 }
    $ver = ([xml](Get-Content (Join-Path $root "Project.xml"))).project.meta.version
    $zip = Join-Path $root "export\Amber-windows-$ver.zip"
    if (Test-Path $zip) { Remove-Item $zip }
    Compress-Archive -Path (Join-Path $bin "*") -DestinationPath $zip
    Write-Host "Zip: $zip ($([math]::Round((Get-Item $zip).Length / 1MB, 1)) MB)" -ForegroundColor Green
} else {
    Write-Host "Fejlesztői (cheat) build: csak belső tesztre, nem kiadható." -ForegroundColor Yellow
}
if ($Run) { Start-Process (Join-Path $bin "Amber.exe") -WorkingDirectory $bin }
