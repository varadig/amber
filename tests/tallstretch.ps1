# Teszt: az iranyitott TALL a FEL gombbal megnyujtja magat, elengedeskor visszahuzodik; varo modban megmarad.
param([string]$Base = "http://127.0.0.1:3220/", [string]$Out = "$PSScriptRoot\out", [int]$Level = 0)
. "$PSScriptRoot\cdp-lib.ps1"
try {
    Start-Cdp ($Base + "?level=$Level") $Out
    Start-Sleep -Seconds 8
    Js "(function(){var p=window.__ps; var c=p.spawnCompanion(1, p.player.x+30, p.player.y); window.__c=c; p.setControl(c);})()" | Out-Null
    Start-Sleep -Seconds 2
    "start: h=" + (Js "window.__c.height") + " ext=" + (Js "window.__c.ext") + " ctrl=" + (Js "window.__ps.ctrl===window.__c")
    Key "keyDown" "ArrowUp" "ArrowUp" 38
    Start-Sleep -Milliseconds 1500
    "up held: h=" + (Js "window.__c.height") + " ext=" + (Js "window.__c.ext") + " scaleY=" + [math]::Round([double](Js "window.__c.scale.y"), 2)
    Shot "tallstretch.png"
    Key "keyUp" "ArrowUp" "ArrowUp" 38
    Start-Sleep -Milliseconds 1000
    "released: h=" + (Js "window.__c.height") + " ext=" + (Js "window.__c.ext")
    Key "keyDown" "ArrowUp" "ArrowUp" 38
    Start-Sleep -Milliseconds 1200
    Js "(function(){window.__ps.setControl(window.__ps.player);})()" | Out-Null
    Key "keyUp" "ArrowUp" "ArrowUp" 38
    Start-Sleep -Milliseconds 1500
    "switched away (mode " + (Js "window.__c.mode") + "): ext=" + (Js "window.__c.ext")
    "errors: " + ((Js "window.__errors") -join '; ')
} finally { Stop-Cdp }
