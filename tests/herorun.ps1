# Képernyőképek a hős futás-animációjáról (nagyított kamera): hero_run_N.png
param([string]$Base = "http://127.0.0.1:3220/", [string]$Out = "$PSScriptRoot\out")
. "$PSScriptRoot\cdp-lib.ps1"
try {
    Start-Cdp ($Base + "?level=0") $Out
    Start-Sleep -Seconds 8
    Js "(function(){var p=window.__ps; window.__parts[0]=true; p.player.refreshLook(); window.__cam.zoom=6;})()" | Out-Null
    Key "keyDown" "ArrowRight" "ArrowRight" 39
    for ($i = 0; $i -lt 8; $i++) { Start-Sleep -Milliseconds 70; Shot "hero_run_$i.png"; "frame " + (Js "window.__ps.player.animation.frameIndex") }
    Key "keyUp" "ArrowRight" "ArrowRight" 39
    "errors: " + ((Js "window.__errors") -join '; ')
} finally { Stop-Cdp }
