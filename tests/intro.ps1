# Teszt: a bevezeto negy jelenete (kepek: tests/out/intro-N.png), majd a jatek indul.
param([string]$Base = "http://127.0.0.1:3220/", [string]$Out = "$PSScriptRoot\out")
. "$PSScriptRoot\cdp-lib.ps1"
try {
    Start-Cdp ($Base + "?intro=1&manual=1") $Out
    Start-Sleep -Milliseconds 2500
    Shot "intro-0.png"
    for ($i = 1; $i -le 3; $i++) {
        Key "keyDown" " " "Space" 32; Start-Sleep -Milliseconds 80; Key "keyUp" " " "Space" 32
        Start-Sleep -Milliseconds 2500
        Shot "intro-$i.png"
    }
    Start-Sleep -Seconds 6
    "state after intro: " + (Js "window.__ps ? 'PlayState' : 'not yet'")
    "errors: " + ((Js "window.__errors") -join '; ')
} finally { Stop-Cdp }

