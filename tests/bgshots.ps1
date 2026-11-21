# Képernyőképek mind a 10 pálya hátteréről + a hős képkockasávja (nagyítva) a futás-animáció ellenőrzéséhez.
param([string]$Base = "http://127.0.0.1:3220/", [string]$Out = "$PSScriptRoot\out")
. "$PSScriptRoot\cdp-lib.ps1"
try {
    Start-Cdp ($Base + "?level=0") $Out
    Start-Sleep -Seconds 8
    Shot "bg_0.png"
    foreach ($l in 1..9) {
        Send-Cdp "Page.navigate" @{ url = ($Base + "?level=" + $l + "&r=" + (Get-Random)) } | Out-Null
        Start-Sleep -Seconds 9
        Shot "bg_$l.png"
    }
    "errors: " + ((Js "window.__errors") -join '; ')
} finally { Stop-Cdp }
