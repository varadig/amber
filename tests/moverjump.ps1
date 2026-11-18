# Teszt: a követő társ átugrik egy mozgó platformra, és átkel rajta a hős felé.
param([string]$Base = "http://127.0.0.1:3220/", [string]$Out = "$PSScriptRoot\out", [int]$Level = 2)
. "$PSScriptRoot\cdp-lib.ps1"
try {
    Start-Cdp ($Base + "?level=$Level") $Out
    Start-Sleep -Seconds 9
    "movers: " + (Js "window.__ps.movers.length")
    $m = Js "(function(){var m=window.__ps.movers.members[0]; return JSON.stringify({ox:m.ox,oy:m.oy,range:m.range,w:m.width,v:m.vertical});})()" | ConvertFrom-Json
    "mover: ox=$($m.ox) oy=$($m.oy) range=$($m.range) w=$($m.w) vertical=$($m.v)"
    Js "(function(){var p=window.__ps; window.__parts[0]=true; p.player.refreshLook(); var m=p.movers.members[0]; var c=p.spawnCompanion(0, m.ox-30, m.oy-14); window.__c=c; c.mode=0; p.player.reset(m.ox+m.range+m.width+40, m.oy-14);})()" | Out-Null
    for ($i = 0; $i -lt 11; $i++) {
        Start-Sleep -Seconds 1
        "t=$i comp x=" + [math]::Round([double](Js "window.__c.x")) + " y=" + [math]::Round([double](Js "window.__c.y")) + " mover x=" + [math]::Round([double](Js "window.__ps.movers.members[0].x")) + " vx=" + [math]::Round([double](Js "window.__c.velocity.x")) + " vy=" + [math]::Round([double](Js "window.__c.velocity.y")) + " touch=" + (Js "window.__c.touching") + " stuckT=" + [math]::Round([double](Js "window.__c.stuckT"),1)
    }
    "errors: " + ((Js "window.__errors") -join '; ')
} finally { Stop-Cdp }
