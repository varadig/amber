# Teszt: elo ujratoltes. A DEV build oldalat csak dev build tolti ujra; release / teszt build nem.
# Elofeltetel: a fejlesztoi szerver fut (scripts/play.ps1 -NoOpen), az export/html5/bin DEV (build.ps1 -Cheats) buildet tartalmaz.
param([string]$Base = "http://127.0.0.1:3220/", [string]$Out = "$PSScriptRoot\out")
. "$PSScriptRoot\cdp-lib.ps1"
$reload = Join-Path $PSScriptRoot "..\scripts\reload.ps1"
try {
    Start-Cdp $Base $Out
    Start-Sleep -Seconds 6
    "clients: " + (Invoke-RestMethod ($Base + "__clients") | ConvertTo-Json -Compress)
    $id0 = Js "window.__navId"
    foreach ($k in "release", "test") {
        & $reload -Kind $k | Out-Null
        Start-Sleep -Seconds 3
        "after $k build: reloaded=" + ((Js "window.__navId") -ne $id0)
    }
    & $reload -Kind dev | Out-Null
    Start-Sleep -Seconds 6
    "after dev build: reloaded=" + ((Js "window.__navId") -ne $id0)
    "clients after reload: " + (Invoke-RestMethod ($Base + "__clients") | ConvertTo-Json -Compress)
} finally { Stop-Cdp }
