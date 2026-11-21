# Teszt: az ORB (és a földi társ) magától összeszedi a közeli atomot.
param([string]$Base = "http://127.0.0.1:3220/", [string]$Out = "$PSScriptRoot\out", [int]$Level = 0, [int]$Kind = 2)
. "$PSScriptRoot\cdp-lib.ps1"
try {
    Start-Cdp ($Base + "?level=$Level") $Out
    Start-Sleep -Seconds 9
    $g = Js "(function(){var p=window.__ps; var gs=p.gems.members.filter(function(q){return q.alpha>0.5 && q.y<600;}); var q=gs[5]; return JSON.stringify({x:q.x,y:q.y,i:p.gems.members.indexOf(q)});})()" | ConvertFrom-Json
    "gem at x=$($g.x) y=$($g.y)"
    Js "(function(){var p=window.__ps; window.__parts[0]=true; p.player.refreshLook(); var q=p.gems.members[$($g.i)]; p.player.reset(q.x-110, q.y-20); var o=p.spawnCompanion($Kind, q.x-($(if ($Kind -eq 2) {130} else {60})), q.y-($(if ($Kind -eq 2) {60} else {0}))); o.mode=0; window.__o=o; window.__q=q; window.__gg0=p.gemsGot; p.gems.members.forEach(function(g){ if(g!==q) g.kill(); }); p.batts.members.forEach(function(b){ b.kill(); });})()" | Out-Null
    for ($i = 0; $i -lt 8; $i++) {
        Start-Sleep -Seconds 1
        "t=$i gem alive=" + (Js "window.__q.alive") + " orb x=" + [math]::Round([double](Js "window.__o.x")) + " y=" + [math]::Round([double](Js "window.__o.y")) + " hero x=" + [math]::Round([double](Js "window.__ps.player.x")) + " atoms collected=" + ([int](Js "window.__ps.gemsGot") - [int](Js "window.__gg0"))
    }
    "errors: " + ((Js "window.__errors") -join '; ')
} finally { Stop-Cdp }
