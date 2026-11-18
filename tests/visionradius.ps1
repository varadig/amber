# Teszt: latas-sugar: VISOR nelkul kis tiszta kor a robot korul, szintenkent nagyobb (kepek: tests/out/vision-N.png).
param([string]$Base = "http://127.0.0.1:3220/", [string]$Out = "$PSScriptRoot\out")
. "$PSScriptRoot\cdp-lib.ps1"
try {
    Start-Cdp ($Base + "?level=1") $Out
    Start-Sleep -Seconds 9
    Js "(function(){window.__ps.bannerT=0; window.__ps.player.frozen=true; window.__ps.partItems.forEach(function(x){x.kill();}); if(window.__ps.subState) window.__ps.subState.close();})()" | Out-Null
    foreach ($t in 0,1,3,5) {
        if ($t -eq 0) { Js "(function(){window.__Parts.owned[2]=false; window.__Parts.tiers[2]=0;})()" | Out-Null }
        else { Js "(function(){window.__Parts.owned[2]=true; window.__Parts.tiers[2]=$t;})()" | Out-Null }
        Start-Sleep -Seconds 3
        "tier $t radius=" + (Js "window.__Parts.visionRadius()")
        Shot "vision-$t.png"
    }
    "errors: " + ((Js "window.__errors") -join '; ')
} finally { Stop-Cdp }



