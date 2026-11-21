# Teszt: minden alkatrész legfeljebb III. szintű; a szintek hatása nő (ugrás); a GPU III. szinten teljes látást, az APU III. szinten tiszta hangot ad.
# (A műhely jelenleg ki van kapcsolva: PlayState.WORKSHOP_ENABLED; a szintek a Parts.add-dal / cheattel emelkednek.)
param([string]$Base = "http://127.0.0.1:3220/", [string]$Out = "$PSScriptRoot\out")
. "$PSScriptRoot\cdp-lib.ps1"
try {
    Start-Cdp ($Base + "?level=0") $Out
    Start-Sleep -Seconds 8
    "max tiers: " + (Js "JSON.stringify([0,1,2,3,4,5,6,7,8,9,13].map(function(i){return window.__Parts.maxTier(i)}))") + " (want all 3)"
    for ($i = 1; $i -le 4; $i++) {
        Js "(function(){var p=window.__ps; for(var k=0;k<14;k++){ if(k<10||k==13) window.__Parts.add(k); } p.player.applyParts();})()" | Out-Null
        Start-Sleep -Milliseconds 500
        "after add x${i}: LEGS tier=" + (Js "window.__Parts.tier(0)") + " reach=" + [math]::Round([double](Js "window.__ps.player.jumpReach()")) + " GPU radius=" + (Js "window.__Parts.visionRadius()") + " APU fx=" + (Js "window.__AudioFx.debug()")
    }
    "errors: " + ((Js "window.__errors") -join '; ')
} finally { Stop-Cdp }
