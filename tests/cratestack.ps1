# Teszt: a ládák nem csúszhatnak egymásba (egymás mellett megállnak, egymásra rakhatók), és a hős két egymás melletti ládát nem tud eltolni (egyet igen).
param([string]$Base = "http://127.0.0.1:3220/", [string]$Out = "$PSScriptRoot/out")
. "$PSScriptRoot/cdp-lib.ps1"
try {
    Start-Cdp ($Base + "?level=0") $Out
    Start-Sleep -Seconds 8
    $js = @'
(async function(){
  var m = JSON.parse(await (await fetch('assets/levels/level1.tmj')).text());
  var ids = 9000;
  function cr(x){ return {id: ids++, name:'', x:x, y:288, width:16, height:16, gid:16, visible:true, properties:[]}; }
  // a spawn (x=32) jobbra: két egymás melletti láda (100, 116), arrébb egy magányos (200), és még egy (240) a lökéshez
  m.layers.push({id: 99, name:'custom', type:'objectgroup', visible:true, objects:[cr(100), cr(116), cr(200), cr(240)]});
  window.__LevelLoader.testText.set(0, JSON.stringify(m));
  return 'ok';
})()
'@
    "inject: " + (Js $js)
    Js "(function(){ window.__ps.cheatGoto(0); return 1; })()" | Out-Null
    Start-Sleep -Seconds 8
    Js "(function(){ var p=window.__ps; p.enemies.forEachAlive(function(e){e.kill();}); window.__cr=p.crates.members.filter(function(c){return c.x>=90 && c.x<260;}).sort(function(a,b){return a.x-b.x;}); p.player.reset(70, 288-p.player.height); p.player.velocity.set(0,0); return window.__cr.length; })()"
    function Xs { Js "JSON.stringify(window.__cr.map(function(c){return Math.round(c.x);}))" }
    "start: " + (Xs)
    # 1. a hős jobbra nyomja a két ládát
    Key "keyDown" "ArrowRight" "ArrowRight" 39
    Wait-GameTime 1.2
    Key "keyUp" "ArrowRight" "ArrowRight" 39
    $x1 = Xs | ConvertFrom-Json
    "after pushing the pair: $($x1 -join ',')  hero x=" + (Js "Math.round(window.__ps.player.x)")
    "pair did not move: " + ([math]::Abs($x1[0] - 100) -le 2 -and [math]::Abs($x1[1] - 116) -le 2)
    # 2. a magányos ládát (200) eltolja: a hős a pár mögé, jobbra tőle
    Js "(function(){ var p=window.__ps; p.player.reset(170, 288-p.player.height); p.player.velocity.set(0,0); return 1; })()" | Out-Null
    Key "keyDown" "ArrowRight" "ArrowRight" 39
    Wait-GameTime 2.0
    Key "keyUp" "ArrowRight" "ArrowRight" 39
    $x2 = Xs | ConvertFrom-Json
    "after pushing the single crate: $($x2 -join ',')  hero x=" + (Js "Math.round(window.__ps.player.x)") + " vx=" + (Js "Math.round(window.__ps.player.velocity.x)") + " blocked=" + (Js "window.__ps.crateBehind(window.__cr[2], 1)")
    "single crate moved: " + ($x2[2] -gt 205)
    # 3. a magányos ládát a negyedikhez tolta: nem csúszhatnak egymásba
    "no overlap: " + (Js "(function(){var c=window.__cr; for (var i=0;i<c.length;i++) for (var j=i+1;j<c.length;j++){ var ox=Math.min(c[i].x+16,c[j].x+16)-Math.max(c[i].x,c[j].x), oy=Math.min(c[i].y+16,c[j].y+16)-Math.max(c[i].y,c[j].y); if (ox>1 && oy>1) return false; } return true;})()")
    # 4. egymásra rakás: egy ládát a másik fölé ejtünk: rajta áll
    Js "(function(){ var c=window.__cr[0]; c.reset(window.__cr[1].x, 288-40); c.velocity.set(0,0); return 1; })()" | Out-Null
    Wait-GameTime 0.8
    "stacked: " + (Js "(function(){var a=window.__cr[0], b=window.__cr[1]; return Math.abs((a.y+16)-b.y)<=1.5 && Math.abs(a.x-b.x)<2;})()") + " " + (Js "JSON.stringify(window.__cr.map(function(c){return [Math.round(c.x),Math.round(c.y)];}))")
    # 5. a láda tetején állva jobbra sétál: a láda nem mozdulhat (rajta állva nem tolható)
    Js "(function(){ var p=window.__ps, c=window.__cr[2]; window.__c2x=c.x; p.player.reset(c.x+2, c.y-p.player.height-1); p.player.velocity.set(0,0); return 1; })()" | Out-Null
    Wait-GameTime 0.4
    Key "keyDown" "ArrowLeft" "ArrowLeft" 37
    Wait-GameTime 0.3
    Key "keyUp" "ArrowLeft" "ArrowLeft" 37
    Key "keyDown" "ArrowRight" "ArrowRight" 39
    Wait-GameTime 0.6
    Key "keyUp" "ArrowRight" "ArrowRight" 39
    "crate stays when walked on: " + (Js "Math.abs(window.__cr[2].x - window.__c2x) < 1") + " (dx " + (Js "Math.round(window.__cr[2].x - window.__c2x)") + ")"
    # 6. két egymásra rakott láda (mint egy gödörben): a tetején álló hős felveszi a felsőt (a talpa alattit)
    Js "(function(){ var p=window.__ps, top=window.__cr[0]; p.player.reset(top.x+2, top.y-p.player.height-1); p.player.velocity.set(0,0); return 1; })()" | Out-Null
    Wait-GameTime 0.4
    Key "keyDown" "g" "KeyG" 71
    Wait-GameTime 0.15
    Key "keyUp" "g" "KeyG" 71
    Wait-GameTime 0.1
    "grabbed the crate under the feet: " + (Js "window.__ps.player.carrying === window.__cr[0]")
    "errors: " + ((Js "window.__errors") -join '; ')
} finally { Stop-Cdp }
