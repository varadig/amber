# Helyi szerver az export/html5/bin mappához (0.0.0.0, így telefonról / másik gépről is elérhető), a böngésző megnyitásával.
#   powershell -ExecutionPolicy Bypass -File scripts/play.ps1 [-Port 3220] [-NoOpen]
param([int]$Port = 3220, [switch]$NoOpen)
$root = Split-Path -Parent $PSScriptRoot
. "$PSScriptRoot/common.ps1"
try { $node = Get-Node } catch { Write-Host "Nincs Node." -ForegroundColor Red; exit 1 }
Write-Host "Ezen a gépen: http://localhost:$Port/" -ForegroundColor Cyan
Get-LanAddresses | ForEach-Object { Write-Host "Hálózaton:    http://${_}:$Port/" -ForegroundColor Cyan }
if (-not $NoOpen) { Open-Path "http://localhost:$Port/" }
& $node (Join-Path $PSScriptRoot "devserver.js") (Join-Path $root "export/html5/bin") $Port
