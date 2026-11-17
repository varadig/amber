# Leállítja az Amber helyi szerverét (alapból a 3220-as port; -Port a másikhoz).
param([int]$Port = 3220)
$conn = Get-NetTCPConnection -State Listen -LocalPort $Port -ErrorAction SilentlyContinue
if (-not $conn) { Write-Host "A $Port porton nem fut szerver."; exit 0 }
foreach ($id in ($conn | Select-Object -ExpandProperty OwningProcess -Unique)) {
    $p = Get-Process -Id $id -ErrorAction SilentlyContinue
    if ($p -and $p.ProcessName -match "node") { Stop-Process -Id $id -Force; Write-Host "Leállítva: $($p.ProcessName) ($id), port $Port" -ForegroundColor Green }
    else { Write-Host "A $Port portot nem node tartja (PID $id), nem állítom le." -ForegroundColor Yellow }
}
