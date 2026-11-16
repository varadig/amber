# Fejnélküli Edge-teszt: elindítja a teszt-buildet (-Dtest), vár, képernyőképet készít és kiírja a játékos állapotát.
#   powershell -ExecutionPolicy Bypass -File tests/shot.ps1 -Url http://127.0.0.1:3220/ -Out <mappa>
param([string]$Url = "http://127.0.0.1:3220/", [string]$Out = "$PSScriptRoot\out", [int]$Wait = 6)
. "$PSScriptRoot\cdp-lib.ps1"
try {
    Start-Cdp $Url $Out
    Start-Sleep -Seconds $Wait
    Shot "shot1.png"
    "state: " + (Js "(function(){var p=window.__ps; if(!p) return 'no __ps'; return JSON.stringify({x:p.player.x,y:p.player.y,hearts:p.player.hearts,gems:p.gemsGot+'/'+p.gemsTotal,w:p.data.w,enemies:p.enemies.length})})()")
    "errors: " + ((Js "window.__errors") -join '; ')
} finally { Stop-Cdp }
