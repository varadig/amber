# Teszt: képességek, fal-kapaszkodás, ajtó-belépés, leszakadó / mozgó platform (képernyőképek: tests/out).
param([string]$Base = "http://127.0.0.1:3220/", [string]$Out = "$PSScriptRoot\out")
. "$PSScriptRoot\cdp-lib.ps1"
function Tp($js) { Js $js | Out-Null }
try {
    # 1. csupasz hős: ugrásmagasság
    Start-Cdp ($Base + "?level=0") $Out
    Start-Sleep -Seconds 8
    $y0 = [double](Js "window.__ps.player.y")
    Key "keyDown" " " "Space" 32
    $minY = $y0
    1..14 | ForEach-Object { Start-Sleep -Milliseconds 25; $y = [double](Js "window.__ps.player.y"); if ($y -lt $minY) { $minY = $y } }
    Key "keyUp" " " "Space" 32
    "naked hop (px): " + [math]::Round($y0 - $minY, 1)
    # 2. az első alkatrész felvétele (LEGS) -> képesség + megjelenés
    Tp "(function(){var p=window.__ps; var it=p.partItems.members[0]; p.player.reset(it.x-4, it.y-4);})()"
    Start-Sleep -Milliseconds 600
    "legs owned: " + (Js "window.__parts[0]") + "  parts found: " + (Js "window.__ps.partsFound")
    Shot "f_legs.png"
    # 3. fal-kapaszkodás: karmok + kút (3. pálya)
    Send-Cdp "Page.navigate" @{ url = ($Base + "?level=2&r=1") } | Out-Null
    Start-Sleep -Seconds 8
    Tp "(function(){window.__parts[0]=true;window.__parts[4]=true;window.__ps.player.refreshLook();})()"
    Tp "(function(){var p=window.__ps; var d=p.data; var c=-1; for(var x=1;x<d.w-3;x++){ if(d.top[x]-d.top[x-1]==6 && d.top[x+1]==d.top[x]){c=x;break;} } window.__wallX=c; p.player.reset((c+1)*16+4,(d.top[c-1]+1)*16); window.__cam.focusOn(p.player.getMidpoint());})()"
    Start-Sleep -Milliseconds 200
    Key "keyDown" "ArrowLeft" "ArrowLeft" 37
    Start-Sleep -Milliseconds 260
    "cling: " + (Js "JSON.stringify({x:window.__ps.player.x,y:window.__ps.player.y,cl:window.__ps.player.clinging})")
    Shot "f_cling.png"
    Key "keyUp" "ArrowLeft" "ArrowLeft" 37
    # 4. ajtó-belépés (minden alkatrész megvan)
    Send-Cdp "Page.navigate" @{ url = ($Base + "?level=0&r=2") } | Out-Null
    Start-Sleep -Seconds 8
    Tp "(function(){var p=window.__ps; for(var i=0;i<p.found.length;i++){p.found[i]=true;} p.partsFound=p.found.length; window.__parts[0]=true; p.player.refreshLook(); var d=p.door; p.player.reset(d.x-10, d.y); window.__cam.focusOn(p.player.getMidpoint());})()"
    Key "keyDown" "ArrowRight" "ArrowRight" 39
    Start-Sleep -Milliseconds 250
    Shot "f_door1.png"
    "door t1: " + (Js "JSON.stringify({x:window.__ps.player.x,y:window.__ps.player.y,a:window.__ps.player.alpha,mode:window.__ps.mode})")
    Start-Sleep -Milliseconds 350
    Key "keyUp" "ArrowRight" "ArrowRight" 39
    Key "keyDown" "e" "KeyE" 69; Start-Sleep -Milliseconds 700; Key "keyUp" "e" "KeyE" 69
    Start-Sleep -Milliseconds 300
    "door t2: " + (Js "JSON.stringify({x:window.__ps.player.x,y:window.__ps.player.y,a:window.__ps.player.alpha,mode:window.__ps.mode})")
    Start-Sleep -Milliseconds 2200
    "door t3: " + (Js "JSON.stringify({a:window.__ps.player.alpha,mode:window.__ps.mode})")
    Shot "f_door2.png"
    "errors: " + ((Js "window.__errors") -join '; ')
} finally { Stop-Cdp }
