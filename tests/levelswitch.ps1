# Mérés: pályaváltáskor (nextLevel) mekkora képkocka-kiesések vannak az új pálya első másodperceiben (rAF-különbségek > 100 ms).
param([string]$Base = "http://127.0.0.1:3220/", [string]$Out = "$PSScriptRoot\out", [int]$Level = 1)
. "$PSScriptRoot\cdp-lib.ps1"
try {
    Start-Cdp ($Base + "?level=$Level") $Out
    Send-Cdp "Page.addScriptToEvaluateOnNewDocument" @{ source = "window.__long=[]; (function(){var last=performance.now(); function f(t){ var d=t-last; if(d>100) window.__long.push([Math.round(t), Math.round(d)]); last=t; requestAnimationFrame(f);} requestAnimationFrame(f);})();" } | Out-Null
    Send-Cdp "Page.navigate" @{ url = ($Base + "?level=$Level&r=" + (Get-Random)) } | Out-Null
    Start-Sleep -Seconds 12
    Js "(function(){window.__long.length=0; window.__marks=[]; window.__t0=performance.now(); window.__ps.nextLevel();})()" | Out-Null
    Start-Sleep -Seconds 6
    "after nextLevel: level now " + (Js "window.__ps.level") + "; stalls >100 ms [t since switch, dt]: " + (Js "JSON.stringify(window.__long.map(function(e){return [e[0]-Math.round(window.__t0), e[1]];}))")
    "marks after switch (ms since nextLevel): " + (Js "JSON.stringify((window.__marks||[]).map(function(m){return [m[0], Math.round(m[1]-(performance.timeOrigin+window.__t0))];}).filter(function(m){return m[1]>-50;}))")
} finally { Stop-Cdp }
