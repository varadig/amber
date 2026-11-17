# A BuildingRoom téglalapok falainak beégetése a Tiled-pályákba (scripts/bake-bunkers.js): a falak a Tiled-ben is látszanak és szerkeszthetők.
#   powershell -ExecutionPolicy Bypass -File scripts/bake-bunkers.ps1
# Tiled-ben nyitott pályánál a Tiled megkérdezi, hogy újratölti-e a módosított fájlt (válaszolj igennel; a nem mentett változásaidat előtte mentsd).
$root = Split-Path -Parent $PSScriptRoot
$node = Join-Path (haxelib libpath lime).Trim() "templates\bin\node\node-windows.exe"
if (-not (Test-Path $node)) { $node = (Get-Command node).Source }
& $node (Join-Path $PSScriptRoot "bake-bunkers.js") (Join-Path $root "levels")
if ($LASTEXITCODE -ne 0) { exit 1 }
Write-Host "Kész. Fordíts újra (Build HTML5), hogy a játék a módosított pályákat használja." -ForegroundColor Green
