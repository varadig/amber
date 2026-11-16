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
            1 { Js "(function(){var s=window.__ps.subState; s.seq=[0]; s.round=1; s.state=1; s.inPos=0;})()" | Out-Null; Tap "ArrowUp" "ArrowUp" 38 }
            2 { Js "(function(){var s=window.__ps.subState; for(var i=0;i<12;i++) s.matched[i]=true; var a=0,b=0; for(var i=1;i<12;i++){ if(s.faces[i]==s.faces[0]){b=i;} } s.matched[0]=false; s.matched[b]=false; s.refresh(); s.pick(0); s.pick(b);})()" | Out-Null }
            3 { Js "(function(){var s=window.__ps.subState; s.enemies=[];})()" | Out-Null }
        }
        Start-Sleep -Seconds 5
        "game ${g}: solved=" + (Js "window.__ps.termSolved.h[$id]===true") + " substateClosed=" + (Js "window.__ps.subState==null")
    }
    "gate open: " + (Js "window.__ps.gates.members.filter(function(g){return g.gid==$id})[0].visible===false")
    "errors: " + ((Js "window.__errors") -join '; ')
} finally { Stop-Cdp }
