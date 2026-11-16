# Helyi szerver az export/html5/bin mappához (0.0.0.0, így telefonról / másik gépről is elérhető), a böngésző megnyitásával.
#   powershell -ExecutionPolicy Bypass -File scripts/play.ps1 [-Port 3220] [-NoOpen]
param([int]$Port = 3220, [switch]$NoOpen)
$root = Split-Path -Parent $PSScriptRoot
$node = "C:\HaxeToolkit\haxe\lib\lime\8,3,2\templates\bin\node\node-windows.exe"
if (-not (Test-Path $node)) { $c = Get-Command node -ErrorAction SilentlyContinue; if ($c) { $node = $c.Source } else { Write-Host "Nincs Node." -ForegroundColor Red; exit 1 } }
Write-Host "Ezen a gépen: http://localhost:$Port/" -ForegroundColor Cyan
Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike "127.*" -and $_.IPAddress -notlike "169.254.*" } | ForEach-Object { Write-Host "Hálózaton:    http://$($_.IPAddress):$Port/" -ForegroundColor Cyan }
if (-not $NoOpen) { Start-Process "http://localhost:$Port/" }
& $node (Join-Path $PSScriptRoot "devserver.js") (Join-Path $root "export\html5\bin") $Port
