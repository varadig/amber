# Teljes automata ellenőrzés: teszt-build -> helyi szerver (3221) -> fejnélküli Edge tesztek (képernyőkép + állapot, mind az 5 pálya, ugrásmagasság) -> szerver leállítása.
#   powershell -ExecutionPolicy Bypass -File scripts/test.ps1
# Figyelem: az export\html5\bin mappa teszt-build marad; a kiadáshoz futtasd a scripts/build.ps1-et (vagy a release.ps1-et).
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
$port = 3221
$out = Join-Path $root "tests\out"
New-Item -ItemType Directory -Force $out | Out-Null

& "$PSScriptRoot\build.ps1" -Test
if ($LASTEXITCODE -ne 0) { Write-Host "A teszt-build nem sikerült." -ForegroundColor Red; exit 1 }

$node = "C:\HaxeToolkit\haxe\lib\lime\8,3,2\templates\bin\node\node-windows.exe"
if (-not (Test-Path $node)) { $node = (Get-Command node).Source }
$srv = Start-Process $node -ArgumentList "`"$PSScriptRoot\devserver.js`"", "`"$root\export\html5\bin`"", $port -PassThru -WindowStyle Hidden
Start-Sleep -Seconds 2
$fail = 0
try {
    $base = "http://127.0.0.1:$port/"
    Write-Host "`n[1/3] Képernyőkép + állapot" -ForegroundColor Cyan
    $r = & powershell -NoProfile -ExecutionPolicy Bypass -File "$root\tests\shot.ps1" -Url ($base + "?level=0") -Out $out
    $r | ForEach-Object { Write-Host $_ }
    if (($r -join "`n") -notmatch "state: \{") { $fail++ }
    if (($r -join "`n") -notmatch "errors:\s*$") { $fail++ }

    Write-Host "`n[2/3] Mind az 5 pálya" -ForegroundColor Cyan
    $r = & powershell -NoProfile -ExecutionPolicy Bypass -File "$root\tests\levels.ps1" -Base $base -Out $out
    $r | ForEach-Object { Write-Host $_ }
    if (@($r | Where-Object { $_ -match "^level \d: \{" }).Count -ne 5) { $fail++ }
    if (($r -join "`n") -notmatch "errors:\s*$") { $fail++ }

    Write-Host "`n[3/3] Ugrás-méretek" -ForegroundColor Cyan
    $r = & powershell -NoProfile -ExecutionPolicy Bypass -File "$root\tests\jump.ps1" -Url ($base + "?level=0") -Out $out
    $r | ForEach-Object { Write-Host $_ }
    if (($r -join "`n") -notmatch "tiles: (3\.[5-9]|4\.[0-2])") { Write-Host "Az ugrás-magasság eltér a tervezettől (3,5-4,2 csempe)." -ForegroundColor Yellow; $fail++ }
}
finally {
    Stop-Process -Id $srv.Id -Force -ErrorAction SilentlyContinue
}
if ($fail -gt 0) { Write-Host "`nHIBA: $fail ellenőrzés nem ment át." -ForegroundColor Red; exit 1 }
Write-Host "`nMinden ellenőrzés rendben. Képernyőképek: tests\out" -ForegroundColor Green
