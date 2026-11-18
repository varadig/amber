# Mérés: a pálya betöltése közben mekkora képkocka-kiesések vannak (rAF-különbségek > 150 ms), és az egyes fázisok ideje (window.__marks).
param([string]$Base = "http://127.0.0.1:3220/", [string]$Out = "$PSScriptRoot\out", [int]$Level = 4)
. "$PSScriptRoot\cdp-lib.ps1"
try {
    Start-Cdp ($Base + "?level=$Level") $Out
    Send-Cdp "Page.addScriptToEvaluateOnNewDocument" @{ source = "window.__long=[]; (function(){var last=performance.now(); function f(t){ var d=t-last; if(d>150) window.__long.push([Math.round(t), Math.round(d)]); last=t; requestAnimationFrame(f);} requestAnimationFrame(f);})();" } | Out-Null
    Send-Cdp "Page.navigate" @{ url = ($Base + "?level=$Level&r=" + (Get-Random)) } | Out-Null
    Start-Sleep -Seconds 14
    "frame stalls >150 ms [t, dt]: " + (Js "JSON.stringify(window.__long)")
    $m = Js "JSON.stringify(window.__marks||[])" | ConvertFrom-Json
    $prev = 0
    foreach ($e in $m) { $t = [double]$e[1]; "  " + $e[0] + $(if ($prev -gt 0) { "  (+" + [math]::Round($t - $prev) + " ms)" } else { "" }); $prev = $t }
} finally { Stop-Cdp }
