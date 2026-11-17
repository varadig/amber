# Teszt: ha az ORB (repülő) az irányított robot, a földi robotok (hős, WHEELIE) nem követik; visszaváltáskor újra követnek.
param([int]$Port = 3231)
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
. "$PSScriptRoot\cdp-lib.ps1"
$node = Join-Path (haxelib libpath lime).Trim() "templates\bin\node\node-windows.exe"
$srv = Start-Process $node -ArgumentList "`"$root\scripts\devserver.js`"", "`"$root\export\html5\bin`"", $Port -PassThru -WindowStyle Hidden
Start-Sleep -Seconds 2
try {
    Start-Cdp "http://127.0.0.1:$Port/?level=3" "$PSScriptRoot\out"
    Start-Sleep -Seconds 8
    Js "(function(){var p=window.__ps; var x=4*16, y=p.data.top[4]*16-12; window.__w=p.spawnCompanion(0,x+30,y); window.__o=p.spawnCompanion(2,x-30,y-20); p.player.reset(x,y-4);})()" | Out-Null
    Start-Sleep -Seconds 1
    Js "window.__ps.setControl(window.__o)" | Out-Null
    Start-Sleep -Milliseconds 500
    "WHEELIE mode with ORB controlled (expect 1 = wait): " + (Js "window.__w.mode")
    "hero followTarget null (expect true): " + (Js "window.__ps.player.followTarget == null")
    Js "window.__ps.setControl(window.__ps.player)" | Out-Null
    Start-Sleep -Milliseconds 500
    "WHEELIE mode with hero controlled (expect 0 = follow): " + (Js "window.__w.mode")
    "ORB mode with hero controlled (expect 0): " + (Js "window.__o.mode")
    "errors: " + ((Js "window.__errors") -join '; ')
} finally {
    try { Stop-Cdp } catch {}
    if ($srv -and -not $srv.HasExited) { Stop-Process -Id $srv.Id -Force }
}
