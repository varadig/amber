# Teszt: mind az 5 pálya betölt-e hiba nélkül (méret, gyémánt, ellenség); az utolsóról képernyőkép.
param([string]$Base = "http://127.0.0.1:3220/", [string]$Out = "$PSScriptRoot\out")
. "$PSScriptRoot\cdp-lib.ps1"
try {
    Start-Cdp ($Base + "?level=0") $Out
    Start-Sleep -Seconds 4
    foreach ($l in 0..4) {
        Send-Cdp "Page.navigate" @{ url = ($Base + "?level=" + $l + "&r=" + (Get-Random)) } | Out-Null
        Start-Sleep -Seconds 4
        "level ${l}: " + (Js "(function(){var p=window.__ps; if(!p) return 'no ps'; var d=p.data; return JSON.stringify({name:d.name,w:d.w,gems:d.gems.length,enemies:d.enemies.length,spikes:d.spikes.length,cps:d.checkpoints.length,hearts:d.hearts.length,key:d.key!=null})})()")
    }
    Shot "level5.png"
    "errors: " + ((Js "window.__errors") -join '; ')
} finally { Stop-Cdp }
