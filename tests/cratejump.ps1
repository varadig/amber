# Teszt: a kovető tars nem tolja a ladat, hanem atugorja.
param([string]$Base = "http://127.0.0.1:3220/", [string]$Out = "$PSScriptRoot\out", [int]$Level = 2, [int]$Kind = 0)
. "$PSScriptRoot\cdp-lib.ps1"
try {
    Start-Cdp ($Base + "?level=$Level") $Out
    Start-Sleep -Seconds 8
    "crates: " + (Js "window.__ps.crates.length")
    $r = Js "(function(){var p=window.__ps; var cr=p.crates.members[0]; if(!cr) return 'none'; window.__cr=cr; window.__x0=cr.x; var c=p.spawnCompanion($Kind, cr.x-70, cr.y-8); window.__c=c; c.mode=0; c.findLoot=null; window.__parts[0]=true; p.player.refreshLook(); p.player.reset(cr.x+70, cr.y-8); return JSON.stringify({x:cr.x,y:cr.y});})()"
    "crate: $r"
    if ($r -eq "none") { return }
    for ($i = 0; $i -lt 10; $i++) {
        Start-Sleep -Milliseconds 700
        "t=$i comp x=" + [math]::Round([double](Js "window.__c.x")) + " y=" + [math]::Round([double](Js "window.__c.y")) + " crate x=" + [math]::Round([double](Js "window.__cr.x")) + " (start " + (Js "window.__x0") + ")"
    }
    "errors: " + ((Js "window.__errors") -join '; ')
} finally { Stop-Cdp }

