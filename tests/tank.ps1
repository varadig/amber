# Teszt: a tankos mini-játék többszöri találat után is tovább megy (újraindul, nem fagy le).
param([string]$Base = "http://127.0.0.1:3220/", [string]$Out = "$PSScriptRoot\out")
. "$PSScriptRoot\cdp-lib.ps1"
try {
    Start-Cdp ($Base + "?level=0") $Out
    Start-Sleep -Seconds 14
    $id = Js "window.__ps.terminals.members[0].ID"
    Js "(function(){var p=window.__ps; var id=$id; p.termSolved.remove(id); p.termGame.set(id,3); p.openTerminal(p.terminals.members[0]);})()" | Out-Null
    Start-Sleep -Seconds 2
    for ($i = 1; $i -le 4; $i++) {
        # több lövedék is a levegőben, az egyik a hősre érkezik
        Js "(function(){var s=window.__ps.subState; s.bullets=[{x:0,y:0,d:1,own:false},{x:1,y:0,d:1,own:false},{x:s.px,y:s.py-0.2,d:2,own:false}];})()" | Out-Null
        Start-Sleep -Milliseconds 800
        "hit ${i}: retryT=" + (Js "window.__ps.subState.retryT") + " lives=" + (Js "window.__ps.subState.lives") + " enemies=" + (Js "window.__ps.subState.enemies.length") + " msg=" + (Js "window.__ps.subState.msg.text")
        Start-Sleep -Seconds 2
        "  after: retryT=" + (Js "window.__ps.subState.retryT") + " lives=" + (Js "window.__ps.subState.lives") + " enemies=" + (Js "window.__ps.subState.enemies.length")
    }
    Start-Sleep -Seconds 3
    Js "(function(){window.__ps.subState.enemies=[];})()" | Out-Null
    Start-Sleep -Seconds 9
    "solved=" + (Js "window.__ps.termSolved.h[$id]===true") + " substateClosed=" + (Js "window.__ps.subState==null")
    "errors: " + ((Js "window.__errors") -join '; ')
} finally { Stop-Cdp }
