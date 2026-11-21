# Teszt: a követő társ átugorja a tüskét; a TALL átkel a leszakadó hídon; az ORB távolabb lebeg a hőstől.
param([string]$Base = "http://127.0.0.1:3220/", [string]$Out = "$PSScriptRoot\out", [int]$Level = 1)
. "$PSScriptRoot\cdp-lib.ps1"
try {
    Start-Cdp ($Base + "?level=$Level") $Out
    Start-Sleep -Seconds 9
    "spikes: " + (Js "window.__ps.spikes.length")
    $s = Js "(function(){var s=window.__ps.spikes.members.filter(function(q){return q.y<700;})[0]; if(!s) return JSON.stringify({x:0,y:0,w:0}); return JSON.stringify({x:s.x,y:s.y,w:s.width});})()" | ConvertFrom-Json
    Js "(function(){var p=window.__ps; window.__parts[0]=true; p.player.refreshLook(); var c=p.spawnCompanion(0, $($s.x)-70, $($s.y)-6); window.__c=c; c.mode=0; window.__minY=1e9; p.player.reset($($s.x)+90, $($s.y)-6);})()" | Out-Null
    for ($i = 0; $i -lt 14; $i++) {
        Start-Sleep -Milliseconds 600
        Js "(function(){var c=window.__c; if(c.y<window.__minY) window.__minY=c.y; return 'comp x='+c.x.toFixed(0)+' y='+c.y.toFixed(0)+' hearts='+c.hearts+' (spike x=$($s.x) y=$($s.y))';})()"
    }
    "highest point y=" + (Js "window.__minY") + " (ground feet~" + ($s.y + 8) + ")"
    # ORB-távolság
    Js "(function(){var p=window.__ps; var o=p.spawnCompanion(2, p.player.x-20, p.player.y-30); window.__o=o; o.mode=0;})()" | Out-Null
    Start-Sleep -Seconds 4
    "orb offset from hero: dx=" + [math]::Round([double](Js "window.__o.x-window.__ps.player.x")) + " dy=" + [math]::Round([double](Js "window.__o.y-window.__ps.player.y"))
    "errors: " + ((Js "window.__errors") -join '; ')
} finally { Stop-Cdp }
