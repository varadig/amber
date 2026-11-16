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
    Write-Host "`n[1/9] Képernyőkép + állapot" -ForegroundColor Cyan
    $r = & powershell -NoProfile -ExecutionPolicy Bypass -File "$root\tests\shot.ps1" -Url ($base + "?level=0") -Out $out
    $r | ForEach-Object { Write-Host $_ }
    if (($r -join "`n") -notmatch "state: \{") { $fail++ }
    if (($r -join "`n") -notmatch "errors:\s*$") { $fail++ }

    Write-Host "`n[2/9] Mind az 5 pálya" -ForegroundColor Cyan
    $r = & powershell -NoProfile -ExecutionPolicy Bypass -File "$root\tests\levels.ps1" -Base $base -Out $out
    $r | ForEach-Object { Write-Host $_ }
    if (@($r | Where-Object { $_ -match "^level \d: \{" }).Count -ne 5) { $fail++ }
    if (($r -join "`n") -notmatch "errors:\s*$") { $fail++ }

    Write-Host "`n[3/9] Ugrás-méretek (LEGS-szel)" -ForegroundColor Cyan
    $r = & powershell -NoProfile -ExecutionPolicy Bypass -File "$root\tests\jump.ps1" -Url ($base + "?level=0") -Out $out
    $r | ForEach-Object { Write-Host $_ }
    if (($r -join "`n") -notmatch "tiles: (3\.[5-9]|4\.[0-2])") { Write-Host "Az ugrás-magasság eltér a tervezettől (3,5-4,2 csempe)." -ForegroundColor Yellow; $fail++ }

    Write-Host "`n[4/9] Képességek, alkatrészek, ajtó-belépés" -ForegroundColor Cyan
    $r = & powershell -NoProfile -ExecutionPolicy Bypass -File "$root\tests\features.ps1" -Base $base -Out $out
    $r | ForEach-Object { Write-Host $_ }
    $txt = ($r -join "`n")
    if ($txt -notmatch "legs owned: True") { Write-Host "A LEGS felvétele nem adta vissza a képességet." -ForegroundColor Yellow; $fail++ }
    if ($txt -notmatch "door t3: .*mode.:1") { Write-Host "Az ajtó-belépés nem ért el a pálya-vége állapotig." -ForegroundColor Yellow; $fail++ }
    if ($txt -notmatch "errors:\s*$") { $fail++ }

    Write-Host "`n[5/9] Rejtvény-logika (láda, kulcs, sorrend, áramcella, szerelőasztal, WHEELIE)" -ForegroundColor Cyan
    $r = & powershell -NoProfile -ExecutionPolicy Bypass -File "$root\tests\puzzles.ps1" -Base $base -Out $out
    $r | ForEach-Object { Write-Host $_ }
    $txt = ($r -join "`n")
    foreach ($need in @("crate/plate: pressed=True gateOpen=True", "lock gate open: True", "seq gate open: True", "benchBuilt=True", "lift powered: True")) {
        if ($txt -notmatch [regex]::Escape($need)) { Write-Host "Hiányzik: $need" -ForegroundColor Yellow; $fail++ }
    }
    if ($txt -notmatch "pf.:[1-9]") { Write-Host "A WHEELIE nem vette fel a rács mögötti alkatrészt." -ForegroundColor Yellow; $fail++ }

    Write-Host "`n[6/9] Társak (TALL feje platform, ORB a karnál)" -ForegroundColor Cyan
    $r = & powershell -NoProfile -ExecutionPolicy Bypass -File "$root\tests\companions.ps1" -Base $base -Out $out
    $r | ForEach-Object { Write-Host $_ }
    $txt = ($r -join "`n")
    if ($txt -notmatch "onFloor=True") { $fail++ }
    if ($txt -notmatch "lever flipped: True") { Write-Host "Az ORB nem billentette át a kart." -ForegroundColor Yellow; $fail++ }

    Write-Host "`n[7/9] Ügyes társak (szakadék átugrás, belépés az ajtón)" -ForegroundColor Cyan
    $r = & powershell -NoProfile -ExecutionPolicy Bypass -File "$root\tests\friends.ps1" -Base $base -Out $out -Level 2 -Gap 4
    $r | ForEach-Object { Write-Host $_ }
    $txt = ($r -join "`n")
    if ($txt -notmatch "wheelie: x=\d+ y=2\d\d alive=True") { Write-Host "A WHEELIE nem jutott át a szakadékon." -ForegroundColor Yellow; $fail++ }
    if ($txt -notmatch "tall: +x=\d+ y=\d+ alive=True") { Write-Host "A TALL elveszett." -ForegroundColor Yellow; $fail++ }
    if ($txt -notmatch "door: mode=1 wheelieAlive=False tallAlive=False") { Write-Host "A társak nem mentek be az ajtón." -ForegroundColor Yellow; $fail++ }

    Write-Host "`n[8/9] A barátok is felvesznek és különleges képességeik vannak; a hős követ" -ForegroundColor Cyan
    $r = & powershell -NoProfile -ExecutionPolicy Bypass -File "$root\tests\skills.ps1" -Base $base -Out $out
    $r | ForEach-Object { Write-Host $_ }
    $txt = ($r -join "`n")
    foreach ($need in @("wheelie picked gem: True", "wheelie picked part: True", "wheelie rammed the cracked wall: True", "tall carries crate: True", "tall dropped crate: True", "orb zapped lever: True")) {
        if ($txt -notmatch [regex]::Escape($need)) { Write-Host "Hiányzik: $need" -ForegroundColor Yellow; $fail++ }
    }
    if ($txt -notmatch "hero follows: start gap=\d+ now=(\d|[1-5]\d)\b") { Write-Host "A hős nem követte a kiválasztott robotot." -ForegroundColor Yellow; $fail++ }

    Write-Host "`n[9/9] Házak: terminál mini-játékok (kirakó, sorrend, lámpák, tank)" -ForegroundColor Cyan
    $r = & powershell -NoProfile -ExecutionPolicy Bypass -File "$root\tests\minigames.ps1" -Base $base -Out $out
    $r | ForEach-Object { Write-Host $_ }
    $txt = ($r -join "`n")
    foreach ($g in 0..3) { if ($txt -notmatch "game ${g}: solved=True substateClosed=True") { Write-Host "A(z) $g. mini-játék nem oldódott meg / nem zárult be." -ForegroundColor Yellow; $fail++ } }
    if ($txt -notmatch "gate open: True") { Write-Host "A terminál nem nyitotta ki a kaput." -ForegroundColor Yellow; $fail++ }
}
finally {
    Stop-Process -Id $srv.Id -Force -ErrorAction SilentlyContinue
}
if ($fail -gt 0) { Write-Host "`nHIBA: $fail ellenőrzés nem ment át." -ForegroundColor Red; exit 1 }
Write-Host "`nMinden ellenőrzés rendben. Képernyőképek: tests\out" -ForegroundColor Green
