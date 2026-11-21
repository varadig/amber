# Teszt: (A) az ellenség csak az irányított robotot sebzi, (B) a társ felugrik egy magasabb egyirányú platformra, (C) a társ átkel a leszakadó platformokon.
param([string]$Base = "http://127.0.0.1:3220/", [string]$Out = "$PSScriptRoot\out")
. "$PSScriptRoot\cdp-lib.ps1"
try {
    # --- A: ellenség-sebzés ---
    Start-Cdp ($Base + "?level=1") $Out
    Start-Sleep -Seconds 9
    Js "(function(){var p=window.__ps; window.__parts[0]=true; p.player.refreshLook(); var e=p.enemies.members[0]; var c=p.spawnCompanion(0, e.x, e.y); window.__c=c; c.mode=1; c.invuln=0; p.player.invuln=0; window.__h0=p.player.hearts; p.player.reset(e.x+4, e.y); window.__e=e;})()" | Out-Null
    Start-Sleep -Seconds 3
    "A1 not controlled: companion hearts=" + (Js "window.__c.hearts") + " hero hearts=" + (Js "window.__ps.player.hearts") + " (hero was " + (Js "window.__h0") + ")  ctrl is hero=" + (Js "window.__ps.ctrl===window.__ps.player")
    Js "(function(){var p=window.__ps; var e=window.__e; p.setControl(window.__c); window.__c.reset(e.x, e.y); window.__c.invuln=0;})()" | Out-Null
    Start-Sleep -Seconds 3
    "A2 controlled companion: hearts=" + (Js "window.__c.hearts") + " (was 3)"
    "errors: " + ((Js "window.__errors") -join '; ')
} finally { Stop-Cdp }
