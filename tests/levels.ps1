# Teszt: mind a 10 pálya betölt-e hiba nélkül (méret, gyémánt, ellenség); az utolsóról képernyőkép.
param([string]$Base = "http://127.0.0.1:3220/", [string]$Out = "$PSScriptRoot\out")
. "$PSScriptRoot\cdp-lib.ps1"
try {
    Start-Cdp ($Base + "?level=0") $Out
    Start-Sleep -Seconds 4
    foreach ($l in 0..9) {
        Send-Cdp "Page.navigate" @{ url = ($Base + "?level=" + $l + "&r=" + (Get-Random)) } | Out-Null
        Start-Sleep -Seconds 4
        "level ${l}: " + (Js "(function(){var p=window.__ps; if(!p) return 'no ps'; var d=p.data; return JSON.stringify({name:d.name,w:d.w,gems:d.gems.length,enemies:d.enemies.length,spikes:d.spikes.length,cps:d.checkpoints.length,hearts:d.hearts.length,parts:d.parts.length,cells:d.cells.length,cracked:d.crackeds.length,gates:d.gates.length,crumbles:d.crumbles.length,movers:d.movers.length,buildings:d.buildings.length,crates:d.crates.length,grates:d.grates.length,levers:d.levers.length,sw:d.switches.length,keys:d.keys.length,socks:d.sockets.length,pcells:d.powerCells.length,benches:d.benches.length,H:d.top.reduce(function(a,b){return b<99?Math.max(a,b):a},0)})})()")
    }
    Shot "level5.png"
    "errors: " + ((Js "window.__errors") -join '; ')
} finally { Stop-Cdp }
