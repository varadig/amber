# Teszt: a toronyhoz teleportál, képernyőkép + mozgás-próba (jobbra futás, ugrás).
param([string]$Url = "http://127.0.0.1:3220/?level=0", [string]$Out = "$PSScriptRoot\out")
. "$PSScriptRoot\cdp-lib.ps1"
try {
    Start-Cdp $Url $Out
    Start-Sleep -Seconds 5
    Js "(function(){var p=window.__ps; var k=p.data.key; var col=Math.floor(k.x/16)-6; var y=p.data.top[col]*16-14; p.player.reset(col*16, y); window.__cam.focusOn(p.player.getMidpoint()); })()" | Out-Null
    Start-Sleep -Milliseconds 800
    Shot "tower1.png"
    Key "keyDown" "ArrowRight" "ArrowRight" 39
    Start-Sleep -Milliseconds 400
    Key "keyDown" " " "Space" 32
    Start-Sleep -Milliseconds 350
    "air: " + (Js "JSON.stringify({x:window.__ps.player.x,y:window.__ps.player.y})")
    Key "keyUp" " " "Space" 32
    Start-Sleep -Milliseconds 600
    Key "keyUp" "ArrowRight" "ArrowRight" 39
    "after: " + (Js "JSON.stringify({x:window.__ps.player.x,y:window.__ps.player.y,floor:window.__ps.player.onFloor})")
    Shot "tower2.png"
    "errors: " + ((Js "window.__errors") -join '; ')
} finally { Stop-Cdp }
