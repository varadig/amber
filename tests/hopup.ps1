# Teszt: a követő társ felugrik egy magasabb egyirányú platformra (és leszakadó platformon átkel), ahová a hős is fel tud.
param([string]$Base = "http://127.0.0.1:3220/", [string]$Out = "$PSScriptRoot\out", [int]$Level = 3)
. "$PSScriptRoot\cdp-lib.ps1"
try {
    Start-Cdp ($Base + "?level=$Level") $Out
    Start-Sleep -Seconds 9
    $f = Js "(function(){var d=window.__ps.data; for(var r=6;r<50;r++){ for(var c=4;c<d.w-4;c++){ if(d.isStandable(c,r) && !d.isSolid(c,r) && d.isStandable(c+1,r) && !d.isSolid(c+1,r)){ for(var h=2;h<=3;h++){ var g=r+h; if(d.isSolid(c,g) && !d.isStandable(c,r+1) && (h<3 || !d.isStandable(c,r+2)) && !d.isSolid(c-1,g-1) && !d.isSolid(c,g-1)){ return JSON.stringify({c:c,r:r,g:g}); } } } } } return 'none';})()"
    "platform: $f"
    if ($f -eq "none") { return }
    $o = $f | ConvertFrom-Json
    $rise = ($o.g - $o.r) * 16
    "rise to platform = $rise px"
    Js "(function(){var p=window.__ps; window.__parts[0]=true; p.player.refreshLook(); var c=p.spawnCompanion(0, $($o.c)*16+4, $($o.g)*16-14); window.__c=c; c.mode=0; p.player.reset($($o.c)*16+20, $($o.r)*16-14);})()" | Out-Null
    for ($i = 0; $i -lt 8; $i++) {
        Start-Sleep -Seconds 1
        "t=$i comp y=" + [math]::Round([double](Js "window.__c.y")) + " feet=" + [math]::Round([double](Js "window.__c.y+window.__c.height")) + " (platform top " + ($o.r * 16) + ", floor " + ($o.g * 16) + ") x=" + [math]::Round([double](Js "window.__c.x"))
    }
    "errors: " + ((Js "window.__errors") -join '; ')
} finally { Stop-Cdp }
