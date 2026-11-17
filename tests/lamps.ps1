# Teszt: a Tiled Lamp objektumok megjelennek a belső teremben (képernyőkép: tests/out/lamps.png), és a pályák lámpái betöltődnek.
param([int]$Port = 3236)
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
. "$PSScriptRoot\cdp-lib.ps1"
$node = Join-Path (haxelib libpath lime).Trim() "templates\bin\node\node-windows.exe"
$srv = Start-Process $node -ArgumentList "`"$root\scripts\devserver.js`"", "`"$root\export\html5\bin`"", $Port -PassThru -WindowStyle Hidden
Start-Sleep -Seconds 4
try {
    Start-Cdp "http://127.0.0.1:$Port/?level=0" "$PSScriptRoot\out"
    Start-Sleep -Seconds 6
    "lamps: " + (Js "window.__ps.data.lamps.length")
    "lamp0: " + (Js "JSON.stringify(window.__ps.data.lamps[0])")
    Js "(function(){var b=window.__ps.data.buildings[0];var p=window.__ps.player;window.__ps.inside=true;p.reset(b.x0*16+120,(b.y0+9)*16-14);p.velocity.set(0,0);window.__cam.follow(null);window.__cam.minScrollX=null;window.__cam.maxScrollX=null;window.__cam.minScrollY=null;window.__cam.maxScrollY=null;window.__cam.scroll.set(b.x0*16+120-240,(b.y0+5)*16-135);window.__ps.bannerT=0;})()" | Out-Null
    Start-Sleep -Seconds 4
    Shot "lamps.png"
    "errors: " + ((Js "window.__errors") -join '; ')
} finally {
    try { Stop-Cdp } catch {}
    if ($srv -and -not $srv.HasExited) { Stop-Process -Id $srv.Id -Force }
}
