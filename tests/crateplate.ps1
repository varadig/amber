# Teszt: a hős ládát fog (G / négyzet), ládával a fején a nyomólapra állva semmi sem történik, a lap mellé lerakott láda lenyomja,
# és a fal Box2D-vel darabokra omlik (Rubble), végleg nyitva marad. 2. pálya (COPPER WELLS). Képek: tests/out/crateplate-N.png
param([string]$Base = "http://127.0.0.1:3220/", [string]$Out = "$PSScriptRoot\out")
. "$PSScriptRoot\cdp-lib.ps1"
function Tap($key, $code, $vk) { Key "keyDown" $key $code $vk; Start-Sleep -Milliseconds 400; Key "keyUp" $key $code $vk; Start-Sleep -Milliseconds 500 }
$gate = "window.__ps.gates.members.filter(function(g){return g.gid==window.__ps.plates.members[0].gid;})[0]"
try {
    Start-Cdp ($Base + "?level=1") $Out
    Start-Sleep -Seconds 12
    Js "(function(){var p=window.__ps; p.bannerT=0; window.__Parts.owned[2]=true; window.__Parts.tiers[2]=5;})()" | Out-Null
    Js "(function(){var p=window.__ps, c=p.crates.members[0]; p.player.x=c.x-p.player.width-2; p.player.y=c.y+16-p.player.height-1; p.player.velocity.set(0,0); p.player.last.x=p.player.x;})()" | Out-Null
    Start-Sleep -Seconds 1
    Tap "g" "KeyG" 71
    "picked up: " + (Js "window.__ps.player.carrying!=null && window.__ps.crates.members[0].carried")
    Js "(function(){var p=window.__ps, pl=p.plates.members[0]; p.player.x=pl.x+2; p.player.y=pl.y+6-p.player.height-1; p.player.velocity.set(0,0); p.player.last.x=p.player.x;})()" | Out-Null
    Start-Sleep -Milliseconds 1500
    "standing on plate (crate on head): pressed=" + (Js "window.__ps.plates.members[0].pressed") + " (want false)"
    Js "(function(){var p=window.__ps, pl=p.plates.members[0]; p.player.x=pl.x-p.player.width-2; p.player.y=pl.y+6-p.player.height-1; p.player.face=1; p.player.velocity.set(0,0); p.player.last.x=p.player.x;})()" | Out-Null
    Start-Sleep -Seconds 1
    Tap "g" "KeyG" 71
    Start-Sleep -Milliseconds 300
    "dropped: carrying=" + (Js "window.__ps.player.carrying!=null") + " pressed=" + (Js "window.__ps.plates.members[0].pressed") + " pieces=" + (Js "window.__ps.rubble.count()")
    Js "(function(){var p=window.__ps, g=$gate; p.player.x=g.x-90; p.player.velocity.set(0,0); p.player.last.x=p.player.x;})()" | Out-Null
    Start-Sleep -Milliseconds 600
    Shot "crateplate-1.png"
    Start-Sleep -Seconds 4
    Shot "crateplate-2.png"
    "wall open: " + (Js "$gate.visible===false")
    # a fejnélküli Edge-ben a játékidő ~6x lassabb: a darabok eltűnését (~1,5-2,5 mp játékidő) a számláló alapján várjuk ki
    $n = 0
    while ($n -lt 30 -and (Js "window.__ps.rubble.count()") -gt 0) { Start-Sleep -Seconds 3; $n++ }
    "pieces left: " + (Js "window.__ps.rubble.count()") + " (want 0: the rubble fades away)"
    # egy repedezett fal is darabokra törik (lövés): ideiglenes blokk a hős előtt
    Js "(function(){var p=window.__ps, b=p.cracked.members.filter(function(c){return c.alive;})[0]; if(!b){ return; } p.breakCracked(b, p.player);})()" | Out-Null
    Start-Sleep -Milliseconds 300
    "cracked wall pieces: " + (Js "window.__ps.rubble.count()")
    "errors: " + ((Js "window.__errors") -join '; ')
} finally { Stop-Cdp }
