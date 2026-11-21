# A generált pályák és a Tiled-erőforrások exportja a levels/ mappába (egyszeri kiindulópont; utána a pályák Tiled-ben szerkeszthetők).
#   powershell -ExecutionPolicy Bypass -File scripts/generate-levels.ps1 [-Force]
# Kimenet: levels/level1..N.tmj, tiles.tsj, objects.tsj, tiles.png, sprites/*.png, amber.tiled-project (a sprite-ok borostyán árnyalattal, hogy a Tiled-ben valós előnézet legyen).
# FIGYELEM: a meglévő .tmj-ket (kézi szerkesztés!) csak -Force-szal írja felül; a tileset/sprite/projekt fájlokat mindig frissíti.
# Működés: teszt-build (a cheats-es LevelExport-tal) -> helyi szerver -> fejnélküli Edge a ?exportlevels=1 címmel -> a window.__levelFiles mentése.
# Végül normál buildet hagy az export/html5/bin mappában (a friss .tmj-ket beágyazva).
param([switch]$Force, [int]$Port = 3049)
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
. "$PSScriptRoot/common.ps1"
$dest = Join-Path $root "levels"
New-Item -ItemType Directory -Force $dest | Out-Null

Write-Host "Teszt-build..." -ForegroundColor Cyan
$o = & haxelib run lime build html5 -Dtest 2>&1
$errs = $o | Select-String -Pattern "\.hx:[0-9]+"
if ($errs) { $errs | ForEach-Object { Write-Host $_ -ForegroundColor Red }; exit 1 }

$srv = Start-DevServer $Port
try {
    . "$root/tests/cdp-lib.ps1"
    Start-Cdp "http://127.0.0.1:$Port/?exportlevels=1" (Join-Path $root "tests/out")
    $n = 0
    for ($i = 0; $i -lt 60 -and $n -eq 0; $i++) { Start-Sleep -Seconds 1; $n = [int](Js "window.__levelFiles ? Object.keys(window.__levelFiles).length : 0") }
    if ($n -eq 0) { throw "Az export nem készült el (window.__levelFiles üres)." }
    Write-Host ("Körút-ellenőrzés (generátor == Tiled-JSON visszaolvasva):`n" + (Js "window.__levelParity")) -ForegroundColor DarkGray
    $names = (Js "Object.keys(window.__levelFiles).join('|')") -split '\|'
    $saved = 0; $kept = 0
    foreach ($name in $names) {
        $path = Join-Path $dest $name
        New-Item -ItemType Directory -Force (Split-Path $path) | Out-Null
        if ($name -like "level*.tmj" -and (Test-Path $path) -and -not $Force) { $kept++; continue }
        $v = Js "window.__levelFiles['$name']"
        if ($name -like "*.png") { [IO.File]::WriteAllBytes($path, [Convert]::FromBase64String($v)) }
        else { [IO.File]::WriteAllText($path, $v, (New-Object System.Text.UTF8Encoding($false))) }
        $saved++
    }
    Write-Host "$saved fájl mentve: $dest" -ForegroundColor Green
    if ($kept -gt 0) { Write-Host "$kept meglévő pálya (.tmj) érintetlen maradt (felülírás: -Force)." -ForegroundColor Yellow }
}
finally {
    try { Stop-Cdp } catch {}
    if ($srv -and -not $srv.HasExited) { Stop-Process -Id $srv.Id -Force }
    & haxelib run lime build html5 2>&1 | Out-Null
}
