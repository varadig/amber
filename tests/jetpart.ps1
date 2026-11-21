# Teszt: a JET CELL alkatrész (Part, icon 9) valódi képesség: felvételkor teli tank, a talajon újratöltődik, az ugrás nyomva tartva repít.
# (A felvehető Cell alkatrész nélkül egy tankot ad; a kettő ikonja azonos.)
param([string]$Base = "http://127.0.0.1:3220/", [string]$Out = "$PSScriptRoot/out")
. "$PSScriptRoot/cdp-lib.ps1"
try {
    Start-Cdp ($Base + "?level=0") $Out
    Start-Sleep -Seconds 9
    Js "(function(){ var p=window.__ps; p.enemies.forEachAlive(function(e){e.kill();}); p.player.flightT=0; return 1; })()" | Out-Null
    "no part, on floor: fuel=" + (Js "window.__ps.player.flightT")
    # az alkatrész felvétele (a pálya egy alkatrészét JET-té tesszük, és a hős felveszi)
    Js "(function(){ var p=window.__ps; var it=p.partItems.members.filter(function(x){return x && x.alive;})[0]; it.icon=9; it.friend=-1; p.onPart(p.player, it); return 1; })()" | Out-Null
    "after pickup: fuel=" + (Js "window.__ps.player.flightT") + " has JET=" + (Js "window.__parts[9]")
    # repülés: ugrás nyomva tartva
    $y0 = Js "Math.round(window.__ps.player.y)"
    Key "keyDown" " " "Space" 32
    Start-Sleep -Seconds 12
    $y1 = Js "Math.round(window.__ps.player.y)"
    $f1 = Js "Math.round(window.__ps.player.flightT*100)/100"
    Key "keyUp" " " "Space" 32
    "flew: y $y0 -> $y1 (rose " + ($y0 - $y1) + " px), fuel left $f1"
    Start-Sleep -Seconds 20
    "landed: onFloor=" + (Js "window.__ps.player.onFloor") + " fuel=" + (Js "window.__ps.player.flightT")
    "ok: " + (($y0 - $y1) -gt 60 -and [double](Js "window.__ps.player.flightT") -ge 4.99)
    "errors: " + ((Js "window.__errors") -join '; ')
} finally { Stop-Cdp }
