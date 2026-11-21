# Teszt: a követő társ felmászik egy 2 / 3 csempe magas falra / lépcsőfokra (ahová a hős is fel tud ugrani).
param([string]$Base = "http://127.0.0.1:3220/", [string]$Out = "$PSScriptRoot\out", [int]$Level = 0)
. "$PSScriptRoot\cdp-lib.ps1"
function Run($h) {
    $e = Js "(function(){var d=window.__ps.data; function top(c){for(var r=0;r<56;r++){if(d.isSolid(c,r))return r;}return 99;} for(var c=6;c<d.w-8;c++){ var t=top(c); if(t<50 && top(c-1)==t && top(c-2)==t && top(c-3)==t && top(c+1)==t-$h && top(c+2)==t-$h && top(c+3)==t-$h) return JSON.stringify({c:c,t:t}); } return 'none';})()"
    if ($e -eq "none") { "step ${h}: no such step on this level"; return }
    $o = $e | ConvertFrom-Json
    Js "(function(){var p=window.__ps; window.__parts[0]=true; p.player.refreshLook(); if(window.__c){window.__c.kill();} var c=p.spawnCompanion(0, ($($o.c)-2)*16+4, $($o.t)*16-14); window.__c=c; c.mode=0; p.player.reset(($($o.c)+4)*16, ($($o.t)-$h)*16-14);})()" | Out-Null
    Start-Sleep -Seconds 7
    $feet = [double](Js "window.__c.y+window.__c.height")
    "step $h tiles at col $($o.c): companion feet=" + [math]::Round($feet) + " upper top=" + (($o.t - $h) * 16) + " lower top=" + ($o.t * 16) + " x=" + [math]::Round([double](Js "window.__c.x")) + $(if ([math]::Abs($feet - ($o.t - $h) * 16) -lt 3) { "  -> UP" } else { "  -> STUCK" })
}
try {
    Start-Cdp ($Base + "?level=$Level") $Out
    Start-Sleep -Seconds 9
    Run 2
    Run 3
    "errors: " + ((Js "window.__errors") -join '; ')
} finally { Stop-Cdp }
