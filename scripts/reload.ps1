# Élő újratöltés kérése a fejlesztői szervertől (scripts/devserver.js): a megadott fajtájú (kind) megnyitott böngésző-példányok újratöltenek.
# A scripts/build.ps1 hívja a build végén; kézzel is futtatható. Fajták: dev (cheat-build), test (teszt-build), release.
# Csak az azonos fajtájú példányok töltenek újra: dev build -> dev játék; release / teszt build nem érinti a dev példányokat.
#   powershell -ExecutionPolicy Bypass -File scripts/reload.ps1 [-Kind dev] [-Port 3220]
param([ValidateSet("dev", "test", "release")][string]$Kind = "dev", [int]$Port = 0)
if ($Port -le 0) { $Port = if ($env:AMBER_PORT) { [int]$env:AMBER_PORT } else { 3220 } }
try {
    $r = Invoke-RestMethod -Method Post -Uri "http://127.0.0.1:$Port/__built?kind=$Kind" -TimeoutSec 2
    if ($r.reloaded -gt 0) { Write-Host "Újratöltés: $($r.reloaded) $Kind példány." -ForegroundColor Cyan }
    else { Write-Host "Nincs megnyitott $Kind példány (nincs mit újratölteni)." -ForegroundColor DarkGray }
} catch {
    Write-Host "A fejlesztői szerver nem érhető el a $Port porton (scripts/play.ps1 indítja): nincs újratöltés." -ForegroundColor DarkGray
}
