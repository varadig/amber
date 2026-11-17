# Teljes kiadás egy lépésben: release (nem teszt) HTML5 build + ellenőrzés + itch.io zip + (opcionálisan) feltöltés.
#   powershell -ExecutionPolicy Bypass -File scripts/release.ps1                (build, zip, publikálás)
#   powershell -ExecutionPolicy Bypass -File scripts/release.ps1 -SkipPublish   (csak build + zip + ellenőrzés)
# A feltöltés beállításai: itch.config.json; bejelentkezés és az első feltöltés teendői: scripts/publish-itch.ps1 és docs/ITCH.md.
param([switch]$SkipPublish)
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
function Step($n, $text) { Write-Host "`n[$n] $text" -ForegroundColor Cyan }
function Fail($text) { Write-Host "HIBA: $text" -ForegroundColor Red; exit 1 }
$total = if ($SkipPublish) { 2 } else { 3 }

Step "1/$total" "Release HTML5 build és csomagolás (scripts/package-itch.ps1)"
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root "scripts\package-itch.ps1")
if ($LASTEXITCODE -ne 0) { Fail "a build vagy a csomagolás nem sikerült." }

Step "2/$total" "A kiadás ellenőrzése"
$bin = Join-Path $root "export\html5\bin"
$js = @(Get-ChildItem $bin -Filter *.js)
if ($js.Count -ne 1) { Fail "pontosan egy .js kell az export\html5\bin mappában (most: $($js.Count))." }
$text = [IO.File]::ReadAllText($js[0].FullName)
foreach ($forbidden in @("window.__ps", "window.__cam", "CheatSubState", "LevelExport")) {
    if ($text.Contains($forbidden)) { Fail "a release build tartalmazza a teszt-kódot: '$forbidden' (-Dtest nélkül kell fordítani)." }
}
$zip = Join-Path $root "dist\amberascent-html5.zip"
if (-not (Test-Path $zip)) { Fail "a zip nem készült el: $zip" }
Add-Type -AssemblyName System.IO.Compression.FileSystem
$z = [IO.Compression.ZipFile]::OpenRead($zip)
try { $names = $z.Entries | ForEach-Object { $_.FullName } } finally { $z.Dispose() }
if ($names -notcontains "index.html") { Fail "az index.html nincs a zip gyökerében." }
Write-Host ("OK: {0} ({1} MB), nincs benne teszt-kód, index.html a gyökérben." -f $zip, [math]::Round((Get-Item $zip).Length / 1MB, 2)) -ForegroundColor Green

if (-not $SkipPublish) {
    Step "3/$total" "Feltöltés itch.io-ra (scripts/publish-itch.ps1 -NoBuild)"
    & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root "scripts\publish-itch.ps1") -NoBuild
    if ($LASTEXITCODE -ne 0) { Fail "a feltöltés nem sikerült." }
}
Write-Host "`nKiadás kész." -ForegroundColor Green
