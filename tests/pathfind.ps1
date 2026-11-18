# Teszt: a kamrába / alagútba szorult társ útkeresővel kijut, és eléri a hőst (repedezett fal az úton).
param([string]$Base = "http://127.0.0.1:3220/", [string]$Out = "$PSScriptRoot\out", [int]$Level = 4, [int]$Kind = 0)
. "$PSScriptRoot\cdp-lib.ps1"
try {
    Start-Cdp ($Base + "?level=$Level") $Out
    Start-Sleep -Seconds 9
    "cracked: " + (Js "window.__ps.cracked.length")
    $k = Js "(function(){var cs=window.__ps.cracked.members.filter(function(b){return b.alive;}); var b=cs[0]; return JSON.stringify({x:b.x,y:b.y,n:cs.length});})()" | ConvertFrom-Json
    "cracked block at x=$($k.x) y=$($k.y) (n=$($k.n))"
    Js "(function(){window.__ps.cracked.members.forEach(function(b){b.kill();});})()" | Out-Null
    # a társ a repedezett fal bal oldalán (a kamrában), a hős a jobb oldalán
    Js "(function(){var p=window.__ps; window.__parts[0]=true; p.player.refreshLook(); var c=p.spawnCompanion($Kind, $($k.x)+70, $($k.y)+4); window.__c=c; c.mode=0; p.player.reset($($k.x)+130, $($k.y)+2);})()" | Out-Null
    for ($i = 0; $i -lt 22; $i++) {
        Start-Sleep -Seconds 1
        "t=$i comp x=" + [math]::Round([double](Js "window.__c.x")) + " y=" + [math]::Round([double](Js "window.__c.y")) + " route=" + (Js "window.__c.route==null?'none':(window.__c.routeI+'/'+window.__c.route.length)") + " hero x=" + [math]::Round([double](Js "window.__ps.player.x"))
    }
    "errors: " + ((Js "window.__errors") -join '; ')
} finally { Stop-Cdp }
