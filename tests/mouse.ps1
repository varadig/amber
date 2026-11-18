# Teszt: bal egerGomb = ugras, jobb egerGomb = loves (a BLASTER-rel).
param([string]$Base = "http://127.0.0.1:3220/", [string]$Out = "$PSScriptRoot\out")
. "$PSScriptRoot\cdp-lib.ps1"
function Click($button, $name) {
    Send-Cdp "Input.dispatchMouseEvent" @{ type = "mousePressed"; x = 500; y = 300; button = $button; buttons = $(if ($button -eq "left") { 1 } else { 2 }); clickCount = 1 } | Out-Null
    Start-Sleep -Milliseconds 120
    Send-Cdp "Input.dispatchMouseEvent" @{ type = "mouseReleased"; x = 500; y = 300; button = $button; buttons = 0; clickCount = 1 } | Out-Null
}
try {
    Start-Cdp ($Base + "?level=0") $Out
    Start-Sleep -Seconds 8
    Js "(function(){var p=window.__ps; if(p.subState) p.subState.close(); p.bannerT=0; window.__parts[0]=true; window.__parts[5]=true; p.player.refreshLook(); p.partItems.forEach(function(x){x.kill();});})()" | Out-Null
    Start-Sleep -Seconds 1
    "y before: " + (Js "window.__ps.player.y") + " onFloor=" + (Js "window.__ps.player.onFloor")
    Click "left"
    Start-Sleep -Milliseconds 250
    "after left click: vy=" + (Js "window.__ps.player.velocity.y") + " y=" + (Js "window.__ps.player.y")
    Start-Sleep -Seconds 2
    "bullets before: " + (Js "window.__ps.bullets.countLiving()")
    Click "right"
    Start-Sleep -Milliseconds 100
    "after right click bullets: " + (Js "window.__ps.bullets.countLiving()")
    "errors: " + ((Js "window.__errors") -join '; ')
} finally { Stop-Cdp }


