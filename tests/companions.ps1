# Teszt: a TALL feje platform (a hős rááll), az ORB átbillenti a magas kart; képernyőkép a társakról.
param([string]$Base = "http://127.0.0.1:3220/", [string]$Out = "$PSScriptRoot\out")
. "$PSScriptRoot\cdp-lib.ps1"
function Load($lvl) { Send-Cdp "Page.navigate" @{ url = ($Base + "?level=" + $lvl + "&r=" + (Get-Random)) } | Out-Null; Start-Sleep -Seconds 9 }
try {
    Start-Cdp ($Base + "?level=3") $Out
    Start-Sleep -Seconds 9
    # TALL: álló helyzetben a feje platform
    Js "(function(){window.__parts[0]=true;window.__ps.player.refreshLook(); var p=window.__ps; var x=4*16, y=p.data.top[4]*16-30; var c=p.spawnCompanion(1,x,y); window.__tall=c; p.player.reset(x-40,y);})()" | Out-Null
    Start-Sleep -Seconds 2
    Js "window.__tall.mode=1" | Out-Null
    Start-Sleep -Seconds 1
    Js "(function(){var c=window.__tall; window.__ps.player.reset(c.x-1, c.y-60);})()" | Out-Null
    Start-Sleep -Seconds 2
    "tall: top=" + [math]::Round([double](Js "window.__tall.y"),1) + " playerFeet=" + [math]::Round([double](Js "window.__ps.player.y+window.__ps.player.height"),1) + " onFloor=" + (Js "window.__ps.player.onFloor")
    Shot "comp_tall.png"
    # ORB: irányítva felrepül és átbillenti a kart (10. pálya)
    Load 9
    Js "(function(){var p=window.__ps; var l=p.levers.members[0]; var o=p.spawnCompanion(2,l.x+4,l.y+110); p.player.reset(l.x-40,l.y+120); o.x=l.x+4; o.y=l.y+100; p.setControl(o); window.__lev=l;})()" | Out-Null
    Key "keyDown" "ArrowUp" "ArrowUp" 38
    Start-Sleep -Seconds 6
    Key "keyUp" "ArrowUp" "ArrowUp" 38
    "lever flipped: " + (Js "window.__lev.flipped")
    Shot "comp_orb.png"
    "errors: " + ((Js "window.__errors") -join '; ')
} finally { Stop-Cdp }
