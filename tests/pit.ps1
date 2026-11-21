# Teszt: a 3. pálya kútjába (CLAWS nélkül) beesve a vészlift kiemeli a hőst; + alkatrész-bemutató képernyőképek.
param([string]$Base = "http://127.0.0.1:3220/", [string]$Out = "$PSScriptRoot\out")
. "$PSScriptRoot\cdp-lib.ps1"
try {
    Start-Cdp ($Base + "?level=2") $Out
    Start-Sleep -Seconds 9
    # a kút keresése: oszlop, amelynek teteje legalább 5 csempével mélyebb mindkét szomszédjánál (3 széles)
    $found = Js "(function(){var d=window.__ps.data; function top(c){for(var r=0;r<56;r++){if(d.isSolid(c,r))return r;}return 99;} for(var c=5;c<d.w-5;c++){var t=top(c); if(t<50 && t>10 && top(c-2)<=t-5 && top(c+2)<=t-5 && top(c-1)==t && top(c+1)==t) return JSON.stringify({c:c,t:t});} return 'none';})()"
    "well: $found"
    $w = $found | ConvertFrom-Json
    Js "(function(){var p=window.__ps; window.__parts[0]=true; p.player.refreshLook(); p.player.reset($($w.c)*16+4, ($($w.t)-1)*16-12);})()" | Out-Null
    for ($i = 0; $i -lt 16; $i++) {
        Start-Sleep -Seconds 1
        "t=$i y=" + [math]::Round([double](Js "window.__ps.player.y")) + " pitT=" + [math]::Round([double](Js "window.__ps.pitT"),1) + " rescuing=" + (Js "window.__ps.rescuing")
    }
    Shot "pit_after.png"
    # bemutató-képernyőképek
    foreach ($id in 0, 3, 4, 8) {
        Js "(function(){var p=window.__ps; p.startShowcase($id,1); var s=p.showcase; s.delay=0; s.t=0;})()" | Out-Null
        Start-Sleep -Milliseconds 1700
        Shot "showcase_$id.png"
    }
    "errors: " + ((Js "window.__errors") -join '; ')
} finally { Stop-Cdp }
