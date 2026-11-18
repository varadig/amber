# Teszt: atom ikon a palyan, ikonok a muhelyben es a cheat-menuben (kepek: tests/out/icons-*.png).
param([string]$Base = "http://127.0.0.1:3220/", [string]$Out = "$PSScriptRoot\out")
. "$PSScriptRoot\cdp-lib.ps1"
try {
    Start-Cdp ($Base + "?level=0") $Out
    Start-Sleep -Seconds 8
    # atom kozel a hoshoz
    Js "(function(){var p=window.__ps; var g=p.gems.members.filter(function(x){return !x.secret;})[0]; p.player.reset(g.x-30, g.y-10);})()" | Out-Null
    Start-Sleep -Milliseconds 800
    Shot "icons-atom.png"
    # muhely
    Js "(function(){var p=window.__ps; p.cheatAllParts(); window.__Parts.atoms=500; p.levelClear();})()" | Out-Null
    Start-Sleep -Seconds 2
    Js "(function(){window.__ps.finishLevel();})()" | Out-Null
    Start-Sleep -Seconds 1
    Shot "icons-workshop.png"
    "errors: " + ((Js "window.__errors") -join '; ')
} finally { Stop-Cdp }

