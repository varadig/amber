# Teszt: a követő társ lelép egy (1 csempe) és egy mélyebb (3 csempe) lépcsőről is a lent álló hős után.
param([string]$Base = "http://127.0.0.1:3220/", [string]$Out = "$PSScriptRoot\out", [int]$Level = 1)
. "$PSScriptRoot\cdp-lib.ps1"
function Run($drop, $heroOff) {
    $e = Js "(function(){var d=window.__ps.data; function top(c){for(var r=0;r<56;r++){if(d.isSolid(c,r))return r;}return 99;} for(var c=20;c<d.w-12;c++){ if(top(c)<50 && top(c-1)==top(c) && top(c-2)==top(c) && top(c-3)==top(c) && top(c+1)==top(c)+$drop && top(c+2)==top(c)+$drop && top(c+3)==top(c)+$drop && top(c+4)==top(c)+$drop) return JSON.stringify({c:c,t:top(c)}); } return 'none';})()"
    if ($e -eq "none") { "drop ${drop}: no such edge"; return }
    $o = $e | ConvertFrom-Json
    Js "(function(){var p=window.__ps; window.__parts[0]=true; p.player.refreshLook(); var cc=$($o.c); var t=$($o.t); if(window.__c){window.__c.kill();} var c=p.spawnCompanion(0, (cc-2)*16+4, t*16-14); window.__c=c; c.mode=0; p.player.reset((cc+1)*16+$heroOff, (t+$drop)*16-14);})()" | Out-Null
    Start-Sleep -Seconds 6
    "drop $drop heroOff $heroOff edge col $($o.c): companion y=" + [math]::Round([double](Js "window.__c.y")) + " (upper feet row " + ($o.t * 16) + ", lower " + (($o.t + $drop) * 16) + ") x=" + [math]::Round([double](Js "window.__c.x"))
}
try {
    Start-Cdp ($Base + "?level=$Level") $Out
    Start-Sleep -Seconds 9
    Run 1 40
    Run 3 6
    Run 2 6
    "errors: " + ((Js "window.__errors") -join '; ')
} finally { Stop-Cdp }
