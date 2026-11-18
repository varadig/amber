# Teszt: VISOR felvetelekor latvanyos kepelesedes (villodzas + elesito fenysav); kepek a tests/out-ba.
param([string]$Base = "http://127.0.0.1:3220/", [string]$Out = "$PSScriptRoot\out")
. "$PSScriptRoot\cdp-lib.ps1"
try {
    Start-Cdp ($Base + "?level=0") $Out
    Start-Sleep -Seconds 8
    Js "(function(){var p=window.__ps; var it=p.partItems.members[0]; it.icon=2; it.friend=-1; p.onPart(p.player, it);})()" | Out-Null
    for ($i = 0; $i -lt 9; $i++) {
        Start-Sleep -Milliseconds 300
        Shot "visorfx$i.png"
    }
    "visor tier: " + (Js "window.__Parts.tier(2)")
    "errors: " + ((Js "window.__errors") -join '; ')
} finally { Stop-Cdp }
