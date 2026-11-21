# Teszt: a sikertelen útvonal-lépés tiltólistára kerül; az újratervezés nem ugyanazt az élt választja.
param([string]$Base = "http://127.0.0.1:3220/", [string]$Out = "$PSScriptRoot\out", [int]$Level = 4)
. "$PSScriptRoot\cdp-lib.ps1"
try {
    Start-Cdp ($Base + "?level=$Level") $Out
    Start-Sleep -Seconds 9
    $k = Js "(function(){var cs=window.__ps.cracked.members.filter(function(b){return b.alive;}); var b=cs[0]; return JSON.stringify({x:b.x,y:b.y});})()" | ConvertFrom-Json
    Js "(function(){window.__ps.cracked.members.forEach(function(b){b.kill();});})()" | Out-Null
    Js "(function(){var p=window.__ps; window.__parts[0]=true; p.player.refreshLook(); var c=p.spawnCompanion(0, $($k.x)+70, $($k.y)+4); window.__c=c; c.mode=0; p.player.reset($($k.x)+130, $($k.y)+2);})()" | Out-Null
    $first = $null
    for ($i = 0; $i -lt 30 -and -not $first; $i++) {
        Start-Sleep -Milliseconds 700
        $first = Js "window.__c.route ? JSON.stringify(window.__c.route.slice(0,3)) : ''"
    }
    "first route (first 3 steps): $first"
    "marking the first step as failed ..."
    Js "(function(){window.__c.failStep();})()" | Out-Null
    "badEdges after failure: " + (Js "Object.keys(window.__c.badEdges.h).length")
    Start-Sleep -Seconds 12
    $second = Js "window.__c.route ? JSON.stringify(window.__c.route.slice(0,3)) : ''"
    "route 12 s later: " + $(if ($second) { $second } else { "(none: no alternative, the bad edge is avoided)" })
    "same as the failed first route: " + ($second -eq $first -and $second -ne "")
    "errors: " + ((Js "window.__errors") -join '; ')
} finally { Stop-Cdp }
