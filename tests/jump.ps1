# Teszt: ugrás-magasság és -távolság mérése (a játékos a talajon áll, jobbra tartva ugrik).
param([string]$Url = "http://127.0.0.1:3220/?level=0", [string]$Out = "$PSScriptRoot\out")
. "$PSScriptRoot\cdp-lib.ps1"
try {
    Start-Cdp $Url $Out
    Start-Sleep -Seconds 5
    # sík talajra állunk (a pálya eleje: 8 oszlop sík)
    Js "(function(){var p=window.__ps; p.player.reset(24, p.data.top[1]*16-14);})()" | Out-Null
    Start-Sleep -Milliseconds 700
    $y0 = [double](Js "window.__ps.player.y"); $x0 = [double](Js "window.__ps.player.x")
    Key "keyDown" "ArrowRight" "ArrowRight" 39
    Start-Sleep -Milliseconds 200
    Key "keyDown" " " "Space" 32
    $minY = $y0; $maxX = $x0
    1..24 | ForEach-Object { Start-Sleep -Milliseconds 30; $y = [double](Js "window.__ps.player.y"); if ($y -lt $minY) { $minY = $y } }
    Key "keyUp" " " "Space" 32
    1..16 | ForEach-Object { Start-Sleep -Milliseconds 40; $y = [double](Js "window.__ps.player.y"); if ($y -lt $minY) { $minY = $y } }
    $x1 = [double](Js "window.__ps.player.x")
    Key "keyUp" "ArrowRight" "ArrowRight" 39
    "jump height (px): " + [math]::Round($y0 - $minY, 1) + "  (tiles: " + [math]::Round(($y0 - $minY) / 16, 2) + ")  x travelled: " + [math]::Round($x1 - $x0, 1)
} finally { Stop-Cdp }
