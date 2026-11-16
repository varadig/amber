# Teszt: rejtvény-logika (láda + nyomólap, kulcs + zárt kapu, sorrend-kapcsolók, áramcella + emelő, szerelőasztal + társ, WHEELIE a rács mögött).
param([string]$Base = "http://127.0.0.1:3220/", [string]$Out = "$PSScriptRoot\out")
. "$PSScriptRoot\cdp-lib.ps1"
function Up { Key "keyDown" "ArrowUp" "ArrowUp" 38; Start-Sleep -Milliseconds 120; Key "keyUp" "ArrowUp" "ArrowUp" 38; Start-Sleep -Milliseconds 900 }
function Load($lvl) { Send-Cdp "Page.navigate" @{ url = ($Base + "?level=" + $lvl + "&r=" + (Get-Random)) } | Out-Null; Start-Sleep -Seconds 9 }
function Tp($x, $y) { Js "(function(){var p=window.__ps; p.player.reset($x,$y); p.player.invuln=5;})()" | Out-Null }
try {
    Start-Cdp ($Base + "?level=0") $Out
    Start-Sleep -Seconds 9
    # 1. láda a résbe -> lap lenyomva, kapu nyitva
    Js "(function(){var p=window.__ps; var pl=p.plates.members[0]; var c=p.crates.members[0]; c.reset(pl.x, pl.y-16);})()" | Out-Null
    Start-Sleep -Seconds 3
    "crate/plate: pressed=" + (Js "window.__ps.plates.members[0].pressed") + " gateOpen=" + (Js "!window.__ps.gates.members[0].visible")

    # 2. kulcs + zárt kapu + sorrend-kapcsolók (2. pálya)
    Load 1
    Js "window.__parts[0]=true; window.__ps.player.refreshLook()" | Out-Null
    Js "(function(){var p=window.__ps; var k=p.keysG.members[0]; p.player.reset(k.x-2,k.y-4);})()" | Out-Null
    Start-Sleep -Seconds 2
    "key held: " + (Js "JSON.stringify(window.__ps.keysHeld.h)")
    Js "(function(){var p=window.__ps; var g=p.gates.members.filter(function(g){return g.locked})[0]; p.player.reset(g.x-14,g.y+60);})()" | Out-Null
    Start-Sleep -Seconds 2
    "lock gate open: " + (Js "window.__ps.gates.members.filter(function(g){return g.locked})[0].visible===false")
    $order = (Js "JSON.stringify(window.__ps.data.seqs.h[window.__ps.data.switches[0].id])") | ConvertFrom-Json
    "seq order: $($order -join ',')"
    foreach ($i in $order) {
        Js "(function(){var p=window.__ps; var s=p.switches.members.filter(function(s){return s.idx==$i})[0]; p.player.reset(s.x-1,s.y-2);})()" | Out-Null
        Start-Sleep -Milliseconds 500
        Up
    }
    $sid = Js "window.__ps.data.switches[0].id"
    "seq gate open: " + (Js "window.__ps.gates.members.filter(function(g){return g.gid==$sid})[0].visible===false")

    # 3. szerelőasztal + társ, áramcella + emelő, WHEELIE a rács mögött (3. pálya)
    Load 2
    Js "(function(){window.__parts[0]=true;window.__parts[4]=true;window.__ps.player.refreshLook(); var p=window.__ps; p.friendFound[0]=3; var b=p.benches.members[0]; p.player.reset(b.x+6,b.y-4);})()" | Out-Null
    Start-Sleep -Seconds 1
    Up
    "companions: " + (Js "window.__ps.companions.length") + " benchBuilt=" + (Js "window.__ps.benchBuilt")
    Js "(function(){var p=window.__ps; var c=p.power? 0:0; var pc=p.powerCells.members[0]; p.player.reset(pc.x-2,pc.y-4);})()" | Out-Null
    Start-Sleep -Seconds 2
    "carry: " + (Js "window.__ps.carryCell")
    Js "(function(){var p=window.__ps; var s=p.sockets.members[0]; p.player.reset(s.x,s.y-8);})()" | Out-Null
    Start-Sleep -Milliseconds 500
    Up
    "lift powered: " + (Js "window.__ps.movers.members.filter(function(m){return m.gid>=0})[0].powered")
    # WHEELIE a rács mögé
    Js "(function(){var p=window.__ps; var g=p.grates.members[0]; p.player.reset(g.x-40,g.y+10); var c=p.companions.members[0]; c.reset(g.x-20,g.y+8); c.command(1,0);})()" | Out-Null
    Start-Sleep -Seconds 6
    "wheelie x vs grate: " + (Js "JSON.stringify({c:Math.round(window.__ps.companions.members[0].x),g:Math.round(window.__ps.grates.members[0].x),plate:window.__ps.plates.members.filter(function(p){return p.pressed}).length})")
    "errors: " + ((Js "window.__errors") -join '; ')
} finally { Stop-Cdp }
