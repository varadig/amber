# Amber Ascent fordítása (HTML5). Kapcsolók: -Test (teszt-build: egyből a játék indul, window.__ps), -Debug, -Cheats (fejlesztői build cheat-menüvel, a címképernyővel).
#   powershell -ExecutionPolicy Bypass -File scripts/build.ps1 [-Test]
param([switch]$Test, [switch]$Debug, [switch]$Cheats)
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
if (-not $env:HAXEPATH -and (Test-Path "C:\HaxeToolkit\haxe")) { $env:HAXEPATH = "C:\HaxeToolkit\haxe" }
$extra = @()
if ($Test) { $extra += "-Dtest" }
if ($Debug) { $extra += "-debug" }
if ($Cheats) { $extra += "-Dcheats" }
$out = & haxelib run lime build html5 @extra 2>&1
$errs = $out | Select-String -Pattern "\.hx:[0-9]+"
if ($errs) { $errs | ForEach-Object { Write-Host $_ -ForegroundColor Red }; exit 1 }
Write-Host "Kész: export\html5\bin" -ForegroundColor Green
