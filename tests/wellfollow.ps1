# Teszt: a társ nem ugrik le a kútba (CLAWS nélkül nem jönne ki), a peremen vár; sima lépcsőre viszont lelép.
param([string]$Base = "http://127.0.0.1:3220/", [string]$Out = "$PSScriptRoot\out")
. "$PSScriptRoot\cdp-lib.ps1"
try {
    Start-Cdp ($Base + "?level=2") $Out
    Start-Sleep -Seconds 9
    $f = Js "(function(){var d=window.__ps.data; function top(c){for(var r=0;r<56;r++){if(d.isSolid(c,r))return r;}return 99;} for(var c=5;c<d.w-5;c++){var t=top(c); if(t<50 && t>10 && top(c-2)<=t-5 && top(c+2)<=t-5 && top(c-1)==t && top(c+1)==t) return JSON.stringify({c:c,t:t,rim:top(c-2)});} return 'none';})()"
    "well: $f"
    $w = $f | ConvertFrom-Json
    Js "(function(){var p=window.__ps; window.__parts[0]=true; p.player.refreshLook(); var c=p.spawnCompanion(0, ($($w.c)-5)*16, $($w.rim)*16-14); window.__c=c; c.mode=0; p.player.reset($($w.c)*16+4, ($($w.t)-1)*16-12);})()" | Out-Null
    for ($i = 0; $i -lt 8; $i++) {
        Start-Sleep -Seconds 1
        "t=$i comp x=" + [math]::Round([double](Js "window.__c.x")) + " y=" + [math]::Round([double](Js "window.__c.y")) + " (rim feet " + ($w.rim * 16) + ", well bottom feet " + ($w.t * 16) + ")  hero y=" + [math]::Round([double](Js "window.__ps.player.y"))
    }
    "errors: " + ((Js "window.__errors") -join '; ')
} finally { Stop-Cdp }
