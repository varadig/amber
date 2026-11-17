# Teszt: az 1-5. pálya a Tiled-térképből (levels/levelN.tmj) töltődik be, és a számok / elemek megvannak.
param([int]$Port = 3233)
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
. "$PSScriptRoot\cdp-lib.ps1"
$node = Join-Path (haxelib libpath lime).Trim() "templates\bin\node\node-windows.exe"
$srv = Start-Process $node -ArgumentList "`"$root\scripts\devserver.js`"", "`"$root\export\html5\bin`"", $Port -PassThru -WindowStyle Hidden
Start-Sleep -Seconds 2
try {
    for ($lv = 0; $lv -lt 10; $lv++) {
        Start-Cdp "http://127.0.0.1:$Port/?level=$lv" "$PSScriptRoot\out"
        Start-Sleep -Seconds 6
        "level $($lv + 1): " + (Js "(function(){var d=window.__ps.data; return JSON.stringify({tiled:d.fromTiled,name:d.name,w:d.w,gems:d.gems.length,parts:d.parts.length,gates:d.gates.length,terminals:d.terminals.length,buildings:d.buildings.length,spawn:!!d.spawn,door:!!d.door,hero:Math.round(window.__ps.player.x)+','+Math.round(window.__ps.player.y)})})()")
        "  errors: " + ((Js "window.__errors") -join '; ')
        Stop-Cdp
    }
} finally {
    try { Stop-Cdp } catch {}
    if ($srv -and -not $srv.HasExited) { Stop-Process -Id $srv.Id -Force }
}
