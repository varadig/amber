# Teszt: a követés az alapértelmezés; a tétlen robotok (követő és váró) idővel véletlen apróságot csinálnak (state: look / hop / stroll / beep).
param([string]$Base = "http://127.0.0.1:3220/", [string]$Out = "$PSScriptRoot\out")
. "$PSScriptRoot\cdp-lib.ps1"
try {
    Start-Cdp ($Base + "?level=3") $Out
    Start-Sleep -Seconds 10
    "follow default: " + (Js "window.__ps.followAll")
    Js "(function(){var p=window.__ps; var x=4*16, y=p.data.top[4]*16-12; var a=p.spawnCompanion(0,x+30,y); var b=p.spawnCompanion(2,x-30,y-20); window.__a=a; window.__b=b; p.player.reset(x,y-4); window.__seen={};})()" | Out-Null
    "spawn mode: " + (Js "window.__a.mode")
    # 40 mp megfigyelés: a követő WHEELIE és az ORB állapotai
    for ($i = 0; $i -lt 80; $i++) {
        Js "(function(){window.__seen[window.__a.state]=1; window.__seen['orb_'+window.__b.state]=1;})()" | Out-Null
        Start-Sleep -Milliseconds 500
    }
    "states seen: " + (Js "Object.keys(window.__seen).join(',')")
    "idle acts seen: " + (Js "Object.keys(window.__seen).filter(function(k){return /look|hop|stroll|beep/.test(k)}).length")
    # váró állapot is
    Js "window.__a.mode=1; window.__seen={};" | Out-Null
    for ($i = 0; $i -lt 40; $i++) {
        Js "window.__seen[window.__a.state]=1;" | Out-Null
        Start-Sleep -Milliseconds 500
    }
    "wait states seen: " + (Js "Object.keys(window.__seen).join(',')")
    Shot "idle.png"
    "errors: " + ((Js "window.__errors") -join '; ')
} finally { Stop-Cdp }
