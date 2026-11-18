# Teszt: az ujabb ellenseg (HUNTER) eszreveszi es megtamadja a robotot (riado, majd ruroham), a palyakon minden 2. walkerbol lesz.
param([string]$Base = "http://127.0.0.1:3220/", [string]$Out = "$PSScriptRoot\out", [int]$Level = 1)
. "$PSScriptRoot\cdp-lib.ps1"
try {
    Start-Cdp ($Base + "?level=$Level") $Out
    Start-Sleep -Seconds 8
    Js "(function(){var p=window.__ps; if(p.subState) p.subState.close(); p.bannerT=0;})()" | Out-Null
    "enemies by kind: " + (Js "JSON.stringify(window.__ps.enemies.members.reduce(function(a,e){a[e.kind]=(a[e.kind]||0)+1;return a;},{}))")
    $r = Js "(function(){var p=window.__ps; var h=p.enemies.members.filter(function(e){return e.kind===3;})[0]; if(!h) return 'none'; window.__h=h; p.player.invuln=99; p.player.reset(h.x-90, h.y-4); window.__hx0=h.x; return JSON.stringify({x:h.x,y:h.y});})()"
    "hunter: $r"
    if ($r -eq "none") { return }
    for ($i = 0; $i -lt 10; $i++) {
        Start-Sleep -Milliseconds 400
        "t=$i hState=" + (Js "window.__h.hState") + " hunter x=" + [math]::Round([double](Js "window.__h.x")) + " player x=" + [math]::Round([double](Js "window.__ps.player.x")) + " alive=" + (Js "window.__h.alive")
        if ($i -eq 3) { Shot "hunter.png" }
    }
    "errors: " + ((Js "window.__errors") -join '; ')
} finally { Stop-Cdp }
