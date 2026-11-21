# Teszt: a cheat-menü a mini-játékból is megnyílik (F9), onnan megoldható a mini-játék azonnal, és a terminálok egyenként feloldhatók.
param([int]$Port = 3232)
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
. "$PSScriptRoot\cdp-lib.ps1"
function Tap($key, $code, $vk) { Key "keyDown" $key $code $vk; Start-Sleep -Milliseconds 600; Key "keyUp" $key $code $vk; Start-Sleep -Milliseconds 400 }
$srv = Start-DevServer $Port
Start-Sleep -Seconds 2
try {
    Start-Cdp "http://127.0.0.1:$Port/?level=1" "$PSScriptRoot\out"
    Start-Sleep -Seconds 10
    Js "window.__ps.cheatMini(0)" | Out-Null
    Start-Sleep -Seconds 2
    "minigame open: " + (Js "window.__ps.subState != null && window.__ps.subState.titleS === 'CIRCUIT REPAIR'")
    Tap "F9" "F9" 120
    "cheat open over minigame: " + (Js "window.__ps.subState.subState != null && window.__ps.subState.subState.mini != null")
    Shot "minicheat_menu.png"
    Tap "Enter" "Enter" 13   # 1. tétel: SOLVE THIS MINI-GAME NOW
    Start-Sleep -Seconds 4
    "minigame closed after solve: " + (Js "window.__ps.subState == null")
    # terminál feloldása a cheat-menüből
    "terminals: " + (Js "window.__ps.cheatTerminalCount()")
    Js "window.__ps.cheatUnlockTerminal(0)" | Out-Null
    "terminal 0 label: " + (Js "window.__ps.cheatTerminalName(0)")
    "errors: " + ((Js "window.__errors") -join '; ')
} finally {
    try { Stop-Cdp } catch {}
    if ($srv -and -not $srv.HasExited) { Stop-Process -Id $srv.Id -Force }
}
