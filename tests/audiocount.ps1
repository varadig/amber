# Teszt: dupla hangok keresése: a játék hang-naplója (Audio.log) és a szóló hangok (Audio.debug): ugrások, pálya- és szünet-váltás után.
param([string]$Base = "http://127.0.0.1:3220/", [string]$Out = "$PSScriptRoot\out")
. "$PSScriptRoot\cdp-lib.ps1"
try {
    Start-Cdp ($Base + "?level=0") $Out
    Start-Sleep -Seconds 2
    Js "window.__parts[0]=true; window.__ps.player.refreshLook(); window.__Audio.log.length=0" | Out-Null
    "start: " + (Js "window.__Audio.debug()")
    for ($i = 0; $i -lt 6; $i++) {
        Key "keyDown" " " "Space" 32; Start-Sleep -Milliseconds 120; Key "keyUp" " " "Space" 32
        Start-Sleep -Milliseconds 900
    }
    "log after 6 jumps: " + (Js "JSON.stringify(window.__Audio.log.map(function(l){return l.n+'@'+l.t}))")
    "after jumps: " + (Js "window.__Audio.debug()")
    # szünet + folytatás kétszer, pályaváltás
    1..2 | ForEach-Object { Key "keyDown" "p" "KeyP" 80; Start-Sleep -Milliseconds 150; Key "keyUp" "p" "KeyP" 80; Start-Sleep -Milliseconds 500; "paused: " + (Js "window.__Audio.debug()"); Key "keyDown" "p" "KeyP" 80; Start-Sleep -Milliseconds 150; Key "keyUp" "p" "KeyP" 80; Start-Sleep -Milliseconds 500 }
    "after pause cycles: " + (Js "window.__Audio.debug()")
    Js "window.__ps.cheatGoto(1)" | Out-Null
    Start-Sleep -Seconds 5
    "after level change: " + (Js "window.__Audio.debug()")
    Js "window.__ps.cheatGoto(2)" | Out-Null
    Start-Sleep -Seconds 5
    "after level change 2: " + (Js "window.__Audio.debug()")
    # respawn a szünetből (R)
    Key "keyDown" "p" "KeyP" 80; Start-Sleep -Milliseconds 150; Key "keyUp" "p" "KeyP" 80; Start-Sleep -Milliseconds 400
    Js "window.__ps.player.x += 200" | Out-Null
    $x0 = [double](Js "window.__ps.player.x")
    Key "keyDown" "r" "KeyR" 82; Start-Sleep -Milliseconds 100; Key "keyUp" "r" "KeyR" 82; Start-Sleep -Milliseconds 800
    "respawn from pause: paused=" + (Js "window.__ps.paused") + " moved=" + ([double](Js "window.__ps.player.x") -ne $x0)
    "music after respawn: " + (Js "window.__Audio.debug()")
    "errors: " + ((Js "window.__errors") -join '; ')
} finally { Stop-Cdp }
