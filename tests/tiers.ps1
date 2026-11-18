# Teszt: az alkatreszek szintjei V-ig emelkednek, a hatasuk nol; a muhely minden szintet arul.
param([string]$Base = "http://127.0.0.1:3220/", [string]$Out = "$PSScriptRoot\out")
. "$PSScriptRoot\cdp-lib.ps1"
try {
    Start-Cdp ($Base + "?level=0") $Out
    Start-Sleep -Seconds 8
    Js "(function(){var p=window.__ps; p.cheatAllParts(); window.__Parts.atoms=1000; p.levelClear();})()" | Out-Null
    Start-Sleep -Seconds 2
    for ($i = 0; $i -lt 6; $i++) {
        "tier LEGS=" + (Js "window.__Parts.tier(0)") + " reach=" + [math]::Round([double](Js "window.__ps.player.jumpReach()")) + " BLASTER=" + (Js "window.__Parts.tier(5)") + " atoms=" + (Js "window.__Parts.atoms")
        Js "(function(){window.__ps.finishLevel(); })()" | Out-Null
        Start-Sleep -Milliseconds 800
        if ($i -eq 0) { Shot "workshop-tiers.png" }
        Js "(function(){var s=window.__ps.subState; if(!s||s.sel===undefined) return; s.openT=1; for(var k=0;k<10;k++){ s.sel=k; s.jact=true; s.tick(0.016);} })()" | Out-Null
        Start-Sleep -Milliseconds 300
    }
    "max tiers: " + (Js "JSON.stringify([0,1,2,3,4,5,6,7,8,9].map(function(i){return window.__Parts.tier(i)}))")
    "errors: " + ((Js "window.__errors") -join '; ')
} finally { Stop-Cdp }
