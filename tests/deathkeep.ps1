# Teszt: elvesztett élet után (kimerült akku) a játék az ellenőrzőponttól folytatódik, és a pályán felvett alkatrészek / atomok megmaradnak
# (ugyanúgy, mint leeséskor); csak a játék vége (az utolsó élet) indít mindent elölről.
param([string]$Base = "http://127.0.0.1:3220/", [string]$Out = "$PSScriptRoot/out")
. "$PSScriptRoot/cdp-lib.ps1"
try {
    Start-Cdp ($Base + "?level=1") $Out
    Start-Sleep -Seconds 9
    # egy alkatrész és egy atom felvétele
    Js "(function(){ var p=window.__ps; var it=p.partItems.members.filter(function(x){return x && x.alive && x.friend<0;})[0]; window.__icon=it.icon; p.onPart(p.player, it); var g=p.gems.members.filter(function(x){return x && x.alive;})[0]; p.player.reset(g.x-2, g.y-4); return 1; })()" | Out-Null
    Start-Sleep -Seconds 2
    $before = Js "JSON.stringify({part: window.__parts[window.__icon], found: window.__ps.partsFound, atoms: window.__Parts.atoms, gems: window.__ps.gemsGot, lives: window.__Parts.lives})"
    "before death: $before"
    # az akku kimerül: egy élet elvész
    Js "(function(){ window.__setBatt(0.2); return 1; })()" | Out-Null
    $n = 0; while ($n -lt 40 -and "$(Js 'window.__ps.mode')" -ne "2") { Start-Sleep -Milliseconds 250; $n++ }
    "died: mode=" + (Js "window.__ps.mode") + " overlay=" + (Js "window.__ps.overlay.text").Replace("`n", " | ")
    $n = 0; while ($n -lt 60 -and "$(Js 'window.__ps.mode')" -ne "0") { Start-Sleep -Milliseconds 500; $n++ }
    $after = Js "JSON.stringify({part: window.__parts[window.__icon], found: window.__ps.partsFound, atoms: window.__Parts.atoms, gems: window.__ps.gemsGot, lives: window.__Parts.lives, batt: Math.round(window.__getBatt()), atRespawn: Math.abs(window.__ps.player.x - window.__ps.respawn.x) < 24, visible: window.__ps.player.visible})"
    "after revive: $after"
    $b = $before | ConvertFrom-Json; $a = $after | ConvertFrom-Json
    "kept items: " + ($a.part -and $a.found -eq $b.found -and $a.atoms -eq $b.atoms -and $a.gems -eq $b.gems)
    "one life lost: " + ($a.lives -eq $b.lives - 1)
    "at checkpoint, battery refilled: " + ($a.atRespawn -and $a.batt -ge 60 -and $a.visible)
    "errors: " + ((Js "window.__errors") -join '; ')
} finally { Stop-Cdp }
