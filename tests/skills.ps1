# Teszt: a barátok ugyanolyan fontosak, mint a hős: felvesznek, ugranak, különleges képességük van; a hős követi a kiválasztott robotot.
param([string]$Base = "http://127.0.0.1:3220/", [string]$Out = "$PSScriptRoot\out")
. "$PSScriptRoot\cdp-lib.ps1"
function Load($lvl) { Send-Cdp "Page.navigate" @{ url = ($Base + "?level=" + $lvl + "&r=" + (Get-Random)) } | Out-Null; Start-Sleep -Seconds 9 }
function Tap($key, $code, $vk) { Key "keyDown" $key $code $vk; Start-Sleep -Milliseconds 700; Key "keyUp" $key $code $vk; Start-Sleep -Milliseconds 400 }
try {
    Start-Cdp ($Base + "?level=4") $Out
    Start-Sleep -Seconds 9
    # 1. a WHEELIE gyémántot és alkatrészt vesz fel, turbóval áttöri a repedezett falat (5. pálya)
    Js "(function(){var p=window.__ps; var g=p.gems.members[0]; var w=p.spawnCompanion(0,g.x-2,g.y-2); window.__w=w; p.setControl(w); window.__g0=p.gemsGot;})()" | Out-Null
    Start-Sleep -Seconds 2
    "wheelie picked gem: " + ((Js "window.__ps.gemsGot") -gt (Js "window.__g0"))
    Js "(function(){var p=window.__ps; var it=p.partItems.members[0]; window.__w.reset(it.x-2,it.y-2); window.__pf=p.partsFound;})()" | Out-Null
    Start-Sleep -Seconds 2
    "wheelie picked part: " + ((Js "window.__ps.partsFound") -gt (Js "window.__pf"))
    Js "(function(){var p=window.__ps; var c=p.cracked.members[0]; window.__w.reset(c.x-70,c.y+4); window.__w.face=1;})()" | Out-Null
    Start-Sleep -Seconds 1
    Tap "x" "KeyX" 88
    Start-Sleep -Seconds 4
    "wheelie rammed the cracked wall: " + (Js "window.__ps.cracked.members[0].alive===false")

    # 2. a TALL felemeli a ládát (2. pálya)
    Load 1
    Js "(function(){var p=window.__ps; var cr=p.crates.members[0]; var t=p.spawnCompanion(1,cr.x-8,cr.y-14); window.__t=t; p.setControl(t);})()" | Out-Null
    Start-Sleep -Seconds 2
    Tap "x" "KeyX" 88
    "tall carries crate: " + (Js "window.__t.carrying!=null")
    Start-Sleep -Seconds 3
    Tap "x" "KeyX" 88
    "tall dropped crate: " + (Js "window.__t.carrying==null")

    # 3. az ORB szikrája átbillenti a kart (10. pálya)
    Load 9
    Js "(function(){var p=window.__ps; var l=p.levers.members[0]; var o=p.spawnCompanion(2,l.x-60,l.y-4); window.__o=o; o.face=1; p.setControl(o);})()" | Out-Null
    Start-Sleep -Seconds 2
    Tap "x" "KeyX" 88
    Start-Sleep -Seconds 4
    "orb zapped lever: " + (Js "window.__ps.levers.members[0].flipped")

    # 4. a hős követi a kiválasztott robotot (Q)
    Js "(function(){var p=window.__ps; var h=p.player; var w=p.spawnCompanion(0,h.x+120,h.y); window.__w2=w; p.setControl(w); p.followAll=true; p.applyModes(); window.__d0=Math.abs(h.x-w.x);})()" | Out-Null
    Start-Sleep -Seconds 8
    "hero follows: start gap=" + [math]::Round([double](Js "window.__d0")) + " now=" + [math]::Round([double](Js "Math.abs(window.__ps.player.x-window.__w2.x)"))
    "errors: " + ((Js "window.__errors") -join '; ')
} finally { Stop-Cdp }
