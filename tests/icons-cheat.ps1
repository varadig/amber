# Teszt: ikonok a cheat-menuben (kep: tests/out/icons-cheat.png).
param([string]$Base = "http://127.0.0.1:3220/", [string]$Out = "$PSScriptRoot\out")
. "$PSScriptRoot\cdp-lib.ps1"
try {
    Start-Cdp ($Base + "?level=0") $Out
    Start-Sleep -Seconds 8
    Key "keyDown" "F9" "F9" 120; Start-Sleep -Milliseconds 100; Key "keyUp" "F9" "F9" 120
    Start-Sleep -Milliseconds 800
    "substate: " + (Js "window.__ps.subState ? window.__ps.subState.page : 'none'")
    Js "(function(){window.__ps.subState.buildPage('parts');})()" | Out-Null
    Start-Sleep -Milliseconds 400
    Shot "icons-cheat.png"
    Js "(function(){window.__ps.subState.buildPage('screen');})()" | Out-Null
    Start-Sleep -Milliseconds 400
    Shot "icons-cheat2.png"
    "errors: " + ((Js "window.__errors") -join '; ')
} finally { Stop-Cdp }
