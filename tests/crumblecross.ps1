# Teszt: a követő társ átkel a leszakadó hídon (ráugrik, és gyorsan átmegy).
param([string]$Base = "http://127.0.0.1:3220/", [string]$Out = "$PSScriptRoot\out", [int]$Level = 1, [int]$Kind = 0)
. "$PSScriptRoot\cdp-lib.ps1"
try {
    Start-Cdp ($Base + "?level=$Level") $Out
    Start-Sleep -Seconds 9
    "crumbles: " + (Js "window.__ps.crumbles.length")
    $o = Js "(function(){var cs=window.__ps.crumbles.members.slice().sort(function(a,b){return a.x-b.x;}); var a=cs[0]; var last=a; for(var i=1;i<cs.length;i++){ if(Math.abs(cs[i].x-last.x-48)<8 && Math.abs(cs[i].y-a.y)<2) last=cs[i]; else break; } return JSON.stringify({x0:a.x,y:a.y,x1:last.x+48});})()" | ConvertFrom-Json
    "bridge: x0=$($o.x0) x1=$($o.x1) y=$($o.y)"
    Js "(function(){var p=window.__ps; window.__parts[0]=true; p.player.refreshLook(); var c=p.spawnCompanion($Kind, $($o.x0)-30, $($o.y)-14); window.__c=c; c.mode=0; p.player.reset($($o.x1)+60, $($o.y)-14);})()" | Out-Null
    for ($i = 0; $i -lt 16; $i++) {
        Start-Sleep -Milliseconds 800
        "t=$i comp x=" + [math]::Round([double](Js "window.__c.x")) + " y=" + [math]::Round([double](Js "window.__c.y")) + " (bridge y=$($o.y), ends at $($o.x1))"
    }
    "errors: " + ((Js "window.__errors") -join '; ')
} finally { Stop-Cdp }
