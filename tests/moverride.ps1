# Teszt: a követő társ mozgó platformra nem sétál rá / le, hanem ugrik (Companion.moverHop): a platform előtt indul, a hős a túloldalon;
# figyeli, hogy a társ leesik-e a mélybe (a platform alá kerül), felugrik-e a platformra, és átér-e a hőshöz. 3. pálya (2 mozgó platform).
param([string]$Base = "http://127.0.0.1:3220/", [string]$Out = "$PSScriptRoot\out", [int]$Level = 2, [int]$Kind = 0, [switch]$Reverse)
# -Reverse: a társ a platform jobb oldalán indul, a hős a bal oldalon
. "$PSScriptRoot\cdp-lib.ps1"
try {
    Start-Cdp ($Base + "?level=$Level") $Out
    Start-Sleep -Seconds 12
    "movers: " + (Js "window.__ps.movers.length")
    Js "(function(){var p=window.__ps; p.bannerT=0; window.__Parts.owned[2]=true; window.__Parts.tiers[2]=5; var m=p.movers.members.filter(function(m){return !m.vertical;})[0]; window.__m=m; var rev=$(if ($Reverse) { 'true' } else { 'false' }); var a=m.ox-34, b=m.ox+m.range+m.width+44; var c=p.spawnCompanion($Kind, rev?b:a, m.oy-30); window.__c=c; c.mode=0; p.player.reset(rev?a:b, m.oy-30); p.player.frozen=true; window.__low=0; window.__rode=false; window.__t0=p.time; })()" | Out-Null
    $m = Js "(function(){var m=window.__m; return 'ox='+m.ox+' oy='+m.oy+' range='+m.range+' w='+m.width;})()"
    "mover: $m"
    for ($i = 0; $i -lt 40; $i++) {
        Start-Sleep -Milliseconds 1500
        $s = Js "(function(){var p=window.__ps,c=window.__c,m=window.__m; var feet=c.y+c.height; if(feet>m.oy+40) window.__low++; if(Math.abs(feet-m.y)<4 && c.x+c.width>m.x && c.x<m.x+m.width) window.__rode=true; var gap=Math.abs(c.x-p.player.x); return 'gt='+(p.time-window.__t0).toFixed(1)+' cx='+Math.round(c.x)+' feet='+Math.round(feet)+' moverX='+Math.round(m.x)+' gap='+Math.round(gap)+' low='+window.__low+' rode='+window.__rode;})()"
        $s
        if ((Js "Math.abs(window.__c.x-window.__ps.player.x)<40")) { break }
    }
    "RESULT: rode=" + (Js "window.__rode") + " fellLowSamples=" + (Js "window.__low") + " reachedHero=" + (Js "Math.abs(window.__c.x-window.__ps.player.x)<40")
    "errors: " + ((Js "window.__errors") -join '; ')
} finally { Stop-Cdp }
