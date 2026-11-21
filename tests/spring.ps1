# Teszt: rugós ugrólap (Tiled `Spring`, `power` csempe): a rálépő irányított robotot ~power csempe magasra dobja
# (a hősnél az ugrás gomb elengedése sem rövidíti), a lap összenyomódik; egy `power: 4` lap fele akkorát dob.
param([string]$Base = "http://127.0.0.1:3220/", [string]$Out = "$PSScriptRoot/out")
. "$PSScriptRoot/cdp-lib.ps1"
try {
    Start-Cdp ($Base + "?level=0") $Out
    Start-Sleep -Seconds 8
    $js = @'
(async function(){
  var m = JSON.parse(await (await fetch('assets/levels/level1.tmj')).text());
  var ids = 9000, G = 5 + 42;
  m.layers.push({id: 99, name:'custom', type:'objectgroup', visible:true, objects:[
    {id: ids++, name:'', x:160, y:288, width:16, height:8, gid:G, visible:true, properties:[]},
    {id: ids++, name:'', x:224, y:288, width:16, height:8, gid:G, visible:true, properties:[{name:'power', type:'int', value:4}]}
  ]});
  window.__LevelLoader.testText.set(0, JSON.stringify(m));
  return 'ok';
})()
'@
    "inject: " + (Js $js)
    Js "(function(){ window.__ps.cheatGoto(0); return 1; })()" | Out-Null
    Start-Sleep -Seconds 8
    "springs: " + (Js "JSON.stringify(window.__ps.springs.members.map(function(s){return [s.x,s.y];}))")
    function Bounce($x) {
        Js "(function(){ var p=window.__ps; p.enemies.forEachAlive(function(e){e.kill();}); p.player.reset($x, 288-p.player.height-6); p.player.velocity.set(0,0); window.__minY=1e9; window.__pressed=false; window.__iv && clearInterval(window.__iv); window.__iv=setInterval(function(){ var f=p.player.y+p.player.height; if (f<window.__minY) window.__minY=f; if (p.springs.members.some(function(s){return s.animation.frameIndex==1;})) window.__pressed=true; }, 5); return 1; })()" | Out-Null
        Start-Sleep -Seconds 12
        $r = Js "JSON.stringify({rise: Math.round(288 - window.__minY), pressed: window.__pressed})"
        Js "(function(){ clearInterval(window.__iv); return 1; })()" | Out-Null
        return $r
    }
    $a = Bounce 162 | ConvertFrom-Json
    "power 8 (default): rise $($a.rise) px, compressed: $($a.pressed)"
    $b = Bounce 226 | ConvertFrom-Json
    "power 4: rise $($b.rise) px"
    "ok: " + ($a.rise -ge 120 -and $a.pressed -and $b.rise -ge 56 -and $b.rise -lt 100)
    "errors: " + ((Js "window.__errors") -join '; ')
} finally { Stop-Cdp }
