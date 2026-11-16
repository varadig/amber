# Teszt: belépés egy épületbe (felszíni ajtó -> belső terem), a belső terem képe, kilépés.
param([string]$Base = "http://127.0.0.1:3220/", [string]$Out = "$PSScriptRoot\out")
. "$PSScriptRoot\cdp-lib.ps1"
function St { Js "JSON.stringify({inside:window.__ps.inside,x:Math.round(window.__ps.player.x),y:Math.round(window.__ps.player.y),tp:window.__ps.teleporting})" }
try {
    Start-Cdp ($Base + "?level=0") $Out
    Start-Sleep -Seconds 8
    "buildings: " + (Js "window.__ps.data.buildings.length")
    Js "(function(){var p=window.__ps; var d=p.bDoors[0].spr; window.__parts[0]=true; p.player.refreshLook(); p.player.reset(d.x+2, d.y); window.__cam.focusOn(p.player.getMidpoint());})()" | Out-Null
    Start-Sleep -Milliseconds 700
    Shot "b_outside.png"
    "before: " + (St)
    Key "keyDown" "ArrowUp" "ArrowUp" 38; Start-Sleep -Milliseconds 80; Key "keyUp" "ArrowUp" "ArrowUp" 38
    Start-Sleep -Milliseconds 3000
    "inside: " + (St)
    Shot "b_inside.png"
    # kilépés a belső ajtón
    Key "keyDown" "ArrowUp" "ArrowUp" 38; Start-Sleep -Milliseconds 80; Key "keyUp" "ArrowUp" "ArrowUp" 38
    Start-Sleep -Milliseconds 3000
    "after exit: " + (St)
    "errors: " + ((Js "window.__errors") -join '; ')
} finally { Stop-Cdp }
