# Teszt: pálya végén a műhely megnyílik, atomért II. szintre fejleszt; titkos atom (LENS nélkül láthatatlan, 3 atomot ér); társak platform-ugrása.
param([string]$Base = "http://127.0.0.1:3220/", [string]$Out = "$PSScriptRoot\out")
. "$PSScriptRoot\cdp-lib.ps1"
try {
    Start-Cdp ($Base + "?level=0") $Out
    Start-Sleep -Seconds 9
    "secret gems: " + (Js "window.__ps.gems.members.filter(function(g){return g.secret;}).length") + " of " + (Js "window.__ps.gems.length") + "  gemsTotal=" + (Js "window.__ps.gemsTotal")
    Js "(function(){window.__parts[0]=true; window.__Parts.atoms=40; window.__ps.levelClear();})()" | Out-Null
    Start-Sleep -Seconds 2
    "before: tier(LEGS)=" + (Js "window.__Parts.tier(0)") + " atoms=" + (Js "window.__Parts.atoms")
    Js "(function(){window.__ps.finishLevel();})()" | Out-Null
    Start-Sleep -Seconds 2
    "substate: " + (Js "window.__ps.subState && window.__ps.subState.titleS")
    Shot "workshop.png"
    Js "(function(){var s=window.__ps.subState; s.openT=1; s.sel=0; s.jact=true; s.tick(0.016);})()" | Out-Null
    Start-Sleep -Milliseconds 500
    "after: tier(LEGS)=" + (Js "window.__Parts.tier(0)") + " atoms=" + (Js "window.__Parts.atoms")
    "errors: " + ((Js "window.__errors") -join '; ')
} finally { Stop-Cdp }
