# Teszt: a HUD kiírja a pálya nevét; a szünet-menü keretben nyílik, a játékra szünet-shader kerül (uPause), a sorok között lehet lépni,
# a RESUME folytat, az ESC is; magyarul is. Képek: tests/out/pause-en.png, pause-hu.png
param([string]$Base = "http://127.0.0.1:3220/", [string]$Out = "$PSScriptRoot\out")
. "$PSScriptRoot\cdp-lib.ps1"
function Tap($key, $code, $vk) { Key "keyDown" $key $code $vk; Start-Sleep -Milliseconds 700; Key "keyUp" $key $code $vk; Start-Sleep -Milliseconds 700 }
try {
    Start-Cdp ($Base + "?level=1") $Out
    Start-Sleep -Seconds 12
    "hud level: " + (Js "window.__ps.hudLevel.text")
    Tap "p" "KeyP" 80
    Start-Sleep -Seconds 2
    "paused=" + (Js "window.__ps.paused") + " menu=" + (Js "window.__ps.pauseMenu.visible") + " uPause=" + (Js "window.__ps.pauseMenu && window.__Main_pause()")
    Shot "pause-en.png"
    Tap "ArrowDown" "ArrowDown" 40
    Tap "ArrowDown" "ArrowDown" 40
    "sel after 2x down: " + (Js "window.__ps.pauseMenu.sel")
    Tap "ArrowUp" "ArrowUp" 38
    Tap "ArrowUp" "ArrowUp" 38
    Tap "Enter" "Enter" 13
    Start-Sleep -Seconds 2
    Start-Sleep -Seconds 1
    "after RESUME: paused=" + (Js "window.__ps.paused") + " menu=" + (Js "window.__ps.pauseMenu.visible")
    Js "window.__Lang.set(true)" | Out-Null
    Tap "Escape" "Escape" 27
    Start-Sleep -Seconds 2
    Shot "pause-hu.png"
    "hu hud level: " + (Js "window.__ps.hudLevel.text")
    Tap "Escape" "Escape" 27
    Start-Sleep -Seconds 1
    "after ESC: paused=" + (Js "window.__ps.paused")
    Js "window.__Lang.set(false)" | Out-Null
    "errors: " + ((Js "window.__errors") -join '; ')
} finally { Stop-Cdp }
