# Teszt: az épület terminálja (mini-játék) mind a négy játékkal megnyílik, megoldható, és kinyitja a belső terem kapuját; képernyőképek.
param([string]$Base = "http://127.0.0.1:3220/", [string]$Out = "$PSScriptRoot\out")
. "$PSScriptRoot\cdp-lib.ps1"
function Tap($key, $code, $vk) { Key "keyDown" $key $code $vk; Start-Sleep -Milliseconds 700; Key "keyUp" $key $code $vk; Start-Sleep -Milliseconds 500 }
try {
    Start-Cdp ($Base + "?level=0") $Out
    Start-Sleep -Seconds 14
    "terminals: " + (Js "window.__ps.terminals.length")
    $id = Js "window.__ps.terminals.members[0].ID"
    foreach ($g in 0..3) {
        Js "(function(){var p=window.__ps; var id=$id; p.termSolved.remove(id); p.termGame.set(id,$g); p.openTerminal(p.terminals.members[0]);})()" | Out-Null
        Start-Sleep -Seconds 2
        Shot "mini_$g.png"
        switch ($g) {
            0 { Js "(function(){var s=window.__ps.subState; s.tiles=[1,2,3,4,5,6,7,0,8]; s.refresh();})()" | Out-Null; Tap "ArrowLeft" "ArrowLeft" 37 }
            1 { Js "(function(){var s=window.__ps.subState; s.seq=[0]; s.state=1; s.inPos=0;})()" | Out-Null; Tap "ArrowUp" "ArrowUp" 38 }
            2 { Js "(function(){var s=window.__ps.subState; for(var i=0;i<16;i++) s.g[i]=false; s.g[0]=true; s.g[1]=true; s.g[4]=true; s.cx=0; s.cy=0; s.refresh();})()" | Out-Null; Tap " " "Space" 32 }
            3 { Js "(function(){var s=window.__ps.subState; s.enemies=[];})()" | Out-Null }
        }
        Start-Sleep -Seconds 5
        "game ${g}: solved=" + (Js "window.__ps.termSolved.h[$id]===true") + " substateClosed=" + (Js "window.__ps.subState==null")
    }
    "gate open: " + (Js "window.__ps.gates.members.filter(function(g){return g.gid==$id})[0].visible===false")
    "errors: " + ((Js "window.__errors") -join '; ')
} finally { Stop-Cdp }
