# Teszt: Tiled-ben forgatott tárgyak (kapu, láda: rotation 90/180/270) a játékban ott vannak, ahol a Tiled mutatja
# (a forgatás a bal alsó sarok körül megy; a LevelLoader a forgatott befoglaló téglalap bal felső sarkát veszi).
param([string]$Base = "http://127.0.0.1:3220/", [string]$Out = "$PSScriptRoot/out")
. "$PSScriptRoot/cdp-lib.ps1"
try {
    Start-Cdp ($Base + "?level=0") $Out
    Start-Sleep -Seconds 8
    $js = @'
(async function(){
  var m = JSON.parse(await (await fetch('assets/levels/level1.tmj')).text());
  var ids = 9000;
  function ob(gid, x, y, rot, props){ return {id: ids++, name:'', x:x, y:y, width:16, height:16, rotation:rot, gid:gid, visible:true, properties:props||[]}; }
  var gp = [{name:'id', type:'int', value:77}];
  m.layers.push({id: 99, name:'custom', type:'objectgroup', visible:true, objects:[
    ob(5 + 12, 1600, 288, 0, gp), ob(5 + 12, 1700, 288, 90, gp), ob(5 + 12, 1800, 288, 180, gp), ob(5 + 12, 1900, 288, 270, gp),
    ob(5 + 11, 2000, 288, 90), ob(5 + 11, 2100, 288.4, 180)
  ]});
  window.__LevelLoader.testText.set(0, JSON.stringify(m));
  return 'ok';
})()
'@
    "inject: " + (Js $js)
    Js "(function(){ window.__ps.cheatGoto(0); return 1; })()" | Out-Null
    Start-Sleep -Seconds 8
    $g = Js "JSON.stringify(window.__ps.data.gates.filter(function(g){return g.id==77;}).map(function(g){return [Math.round(g.x),Math.round(g.y)];}))"
    $c = Js "JSON.stringify(window.__ps.data.crates.filter(function(c){return c.x>=1950;}).map(function(c){return [Math.round(c.x),Math.round(c.y)];}))"
    "gates: $g"
    "crates: $c"
    # a Tiled-kép bal felső sarka: 0° (x, y-16), 90° (x, y), 180° (x-16, y), 270° (x-16, y-16)
    "gates ok: " + ($g -eq "[[1600,272],[1700,288],[1784,288],[1884,272]]")
    "crates ok: " + ($c -eq "[[2000,288],[2084,288]]")
    # a kép is forog (Sprite.angle), a tükrözés is átjön
    $ga = Js "JSON.stringify(window.__ps.gates.members.filter(function(g){return g && g.gid==77;}).map(function(g){return g.angle;}))"
    $ca = Js "JSON.stringify(window.__ps.crates.members.filter(function(c){return c && c.x>=1950;}).map(function(c){return c.angle;}))"
    "gate angles: $ga  crate angles: $ca"
    "visual rotation ok: " + ($ga -eq "[0,90,180,270]" -and $ca -eq "[90,180]")
    "errors: " + ((Js "window.__errors") -join '; ')
} finally { Stop-Cdp }
