# Teszt: a cheattel hozzaadott alkatreszek / atomok megmaradnak a cheat-es palyaugras utan.
param([string]$Base = "http://127.0.0.1:3220/", [string]$Out = "$PSScriptRoot\out")
. "$PSScriptRoot\cdp-lib.ps1"
try {
    Start-Cdp ($Base + "?level=0") $Out
    Start-Sleep -Seconds 6
    Js "(function(){var p=window.__ps; p.cheatAllParts(); window.__Parts.atoms=77; p.cheatGoto(2);})()" | Out-Null
    Start-Sleep -Seconds 6
    $n = Js "window.__Parts.owned.filter(function(x){return x;}).length"
    $a = Js "window.__Parts.atoms"
    "parts after goto: $n atoms: $a"
    Js "(function(){window.__ps.cheatPrevLevel();})()" | Out-Null
    Start-Sleep -Seconds 6
    "parts after prev: " + (Js "window.__Parts.owned.filter(function(x){return x;}).length") + " atoms: " + (Js "window.__Parts.atoms")
    "errors: " + ((Js "window.__errors") -join '; ')
} finally { Stop-Cdp }
