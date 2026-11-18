# Teszt: a shader-hangulatok (Looks): minden hangulatrol kep (tests/out/look-N.png); a valasztas megmarad ujratoltes utan; a TALL lab-nyujtozasa.
param([string]$Base = "http://127.0.0.1:3220/", [string]$Out = "$PSScriptRoot\out")
. "$PSScriptRoot\cdp-lib.ps1"
try {
    Start-Cdp ($Base + "?level=1") $Out
    Start-Sleep -Seconds 9
    Js "(function(){var p=window.__ps; p.bannerT=0; if(p.subState) p.subState.close();})()" | Out-Null
    $n = [int](Js "window.__Looks.LIST.length")
    "looks: $n"
    for ($i = 0; $i -lt $n; $i++) {
        Js "(function(){window.__Looks.set($i);})()" | Out-Null
        Start-Sleep -Milliseconds 700
        Shot "look-$i.png"
    }
    Js "(function(){window.__Looks.set(2);})()" | Out-Null
    Send-Cdp "Page.reload" @{} | Out-Null
    Start-Sleep -Seconds 9
    "after reload current look: " + (Js "window.__Looks.current")
    Js "(function(){window.__Looks.set(0);})()" | Out-Null
    "errors: " + ((Js "window.__errors") -join '; ')
} finally { Stop-Cdp }

