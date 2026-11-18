# Teszt: az also info-doboz kicsi, a szoveg "fut" (gepelodik); kepek: tests/out/infobox-N.png
param([string]$Base = "http://127.0.0.1:3220/", [string]$Out = "$PSScriptRoot\out")
. "$PSScriptRoot\cdp-lib.ps1"
try {
    Start-Cdp ($Base + "?level=0") $Out
    Start-Sleep -Milliseconds 1500
    Shot "infobox-0.png"
    Start-Sleep -Milliseconds 700
    Shot "infobox-1.png"
    Start-Sleep -Seconds 4
    Js "(function(){var p=window.__ps; var it=p.partItems.members[0]; it.icon=2; it.friend=-1; p.onPart(p.player, it);})()" | Out-Null
    Start-Sleep -Milliseconds 500
    Shot "infobox-2.png"
    Start-Sleep -Milliseconds 1500
    Shot "infobox-3.png"
    "errors: " + ((Js "window.__errors") -join '; ')
} finally { Stop-Cdp }
