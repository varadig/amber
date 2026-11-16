# Teszt: az F9 cheat-menü megnyílik; alkatrészek, robotok, akku-effekt, minijáték és szintváltás cheatekkel; a menü bezárul.
param([string]$Base = "http://127.0.0.1:3220/", [string]$Out = "$PSScriptRoot\out")
. "$PSScriptRoot\cdp-lib.ps1"
function Tap($key, $code, $vk) { Key "keyDown" $key $code $vk; Start-Sleep -Milliseconds 250; Key "keyUp" $key $code $vk; Start-Sleep -Milliseconds 300 }
try {
    Start-Cdp ($Base + "?level=1") $Out
    Start-Sleep -Seconds 12
    Tap "F9" "F9" 120
    Shot "cheat_main.png"
    "cheat open: " + (Js "window.__ps.subState != null && window.__ps.subState.page === 'main'")
    # PARTS lap: 2. tétel (Down), Enter, majd a 3. tétel kiválasztása
    Tap "ArrowDown" "ArrowDown" 40
    Tap "Enter" "Enter" 13
    "page: " + (Js "window.__ps.subState.page")
    Shot "cheat_parts.png"
    Tap "Enter" "Enter" 13
    "legs given: " + (Js "window.__parts[0]")
    Tap "Escape" "Escape" 27
    "back to main: " + (Js "window.__ps.subState.page === 'main'")
    Tap "Escape" "Escape" 27
    Start-Sleep -Milliseconds 500
    "cheat closed: " + (Js "window.__ps.subState == null")
    # a PlayState cheat-függvényei közvetlenül
    Js "(function(){var p=window.__ps; p.cheatAllParts(); p.cheatCompanion(0); p.cheatCompanion(1); p.cheatCompanion(2); p.cheatBattery(5);})()" | Out-Null
    Start-Sleep -Seconds 4
    "all parts: " + (Js "window.__parts.slice(0,10).every(function(x){return x})")
    "companions: " + (Js "window.__ps.companions.countLiving()")
    Js "window.__ps.cheatShock()" | Out-Null
    Start-Sleep -Milliseconds 200
    Shot "cheat_shock.png"
    Js "(function(){var p=window.__ps; p.cheatGod=true; p.cheatDamage(); })()" | Out-Null
    Start-Sleep -Seconds 1
    "god hearts full: " + (Js "window.__ps.player.hearts == window.__ps.player.maxHearts")
    Js "window.__ps.cheatMini(2)" | Out-Null
    Start-Sleep -Seconds 2
    "mini open: " + (Js "window.__ps.subState != null && window.__ps.subState.titleS === 'POWER GRID'")
    Tap "Escape" "Escape" 27
    Start-Sleep -Seconds 1
    Js "window.__old=window.__ps; window.__ps.cheatGoto(2)" | Out-Null
    Start-Sleep -Seconds 10
    "goto level: " + (Js "window.__ps !== window.__old")
    "errors: " + ((Js "window.__errors") -join '; ')
} finally { Stop-Cdp }
