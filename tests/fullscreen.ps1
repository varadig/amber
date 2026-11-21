# Teszt: teljes képernyő a beállítások menüből (FULLSCREEN sor: jobbra / balra) és az F billentyűvel; a sor állapota követi a böngészőt.
# Kép: tests/out/fullscreen-settings.png
param([string]$Base = "http://127.0.0.1:3220/", [string]$Out = "$PSScriptRoot\out")
. "$PSScriptRoot\cdp-lib.ps1"
function Tap($key, $code, $vk) { Key "keyDown" $key $code $vk; Start-Sleep -Milliseconds 700; Key "keyUp" $key $code $vk; Start-Sleep -Milliseconds 700 }
$fs = "!!document.fullscreenElement"
try {
    Start-Cdp ($Base + "?level=1") $Out
    Start-Sleep -Seconds 12
    # a fejnélküli böngésző nem tud teljes képernyőre váltani: a Fullscreen API-t helyettesítjük (a kérés eljut-e a böngészőhöz, és a sor követi-e)
    Js "(function(){var on=false; window.__fsCalls=0; Object.defineProperty(document,'fullscreenElement',{configurable:true,get:function(){return on?document.documentElement:null;}}); document.documentElement.requestFullscreen=function(){window.__fsCalls++; on=true; return Promise.resolve();}; document.exitFullscreen=function(){window.__fsCalls++; on=false; return Promise.resolve();};})()" | Out-Null
    Tap "p" "KeyP" 80
    Tap "o" "KeyO" 79
    Tap "ArrowDown" "ArrowDown" 40
    Tap "ArrowDown" "ArrowDown" 40
    "row: " + (Js "window.__ps.subState.rows[2].text")
    Tap "ArrowRight" "ArrowRight" 39
    Start-Sleep -Seconds 2
    "after RIGHT in settings: fullscreen=" + (Js $fs) + "  row: " + (Js "window.__ps.subState.rows[2].text")
    Shot "fullscreen-settings.png"
    Tap "ArrowLeft" "ArrowLeft" 37
    Start-Sleep -Seconds 2
    "after LEFT: fullscreen=" + (Js $fs) + "  row: " + (Js "window.__ps.subState.rows[2].text")
    Tap "Escape" "Escape" 27
    Tap "f" "KeyF" 70
    Start-Sleep -Seconds 1
    "after F: fullscreen=" + (Js $fs)
    Tap "f" "KeyF" 70
    Start-Sleep -Seconds 1
    "after F again: fullscreen=" + (Js $fs)
    "errors: " + ((Js "window.__errors") -join '; ')
} finally { Stop-Cdp }
