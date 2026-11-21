# Normál (nem teszt) HTML5 build, majd itch.io-ra feltölthető zip: dist/amber-html5.zip
# Az index.html a zip gyökerébe kerül, ahogy az itch.io elvárja.

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

. "$PSScriptRoot/common.ps1"

# A korábbi (más nevű) build maradék .js fájljai ne kerüljenek a zip-be (pl. a régi Blockbuster.js)
Get-ChildItem (Join-Path $root "export/html5/bin") -Filter *.js -ErrorAction SilentlyContinue | Remove-Item -Force
& haxelib run lime build html5
if ($LASTEXITCODE -ne 0) { throw "A build nem sikerült." }

New-Item -ItemType Directory -Force dist | Out-Null
$zip = Join-Path $root "dist/amber-html5.zip"
# szabványos (perjeles útvonalú) zip: Windowson a beépített tar, macOS-en a zip
New-ZipFromDir (Join-Path $root "export/html5/bin") $zip

Write-Host "Kész: $zip ($([math]::Round((Get-Item $zip).Length / 1MB, 2)) MB)" -ForegroundColor Green
