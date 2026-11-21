# Teszt: egyedi bunkerek Tiled-ben: a BuildingRoom köré fal épül, az ajtók (target) bunkerből bunkerbe visznek (nem csak vissza a főrészre).
param([int]$Port = 3234)
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
. "$PSScriptRoot\cdp-lib.ps1"
$srv = Start-DevServer $Port
Start-Sleep -Seconds 2
try {
    Start-Cdp "http://127.0.0.1:$Port/?level=0" "$PSScriptRoot\out"
    Start-Sleep -Seconds 8
    # a 1. pálya Tiled-szövege + két új bunker (A: x0=30, B: x0=50, y0=30) és ajtók: A1 -> B1, B1 -> A1, A2 (a főrészre) -> B2, ...
    $js = @'
(async function(){
  var t = await (await fetch('assets/levels/level1.tmj')).text();
  var m = JSON.parse(t);
  var ids = 9000;
  function tileObj(cls, x, y, props){ return {id: ids++, name:'', class: cls, x:x, y:y, width: 16, height: 24, gid: 5 + 22, visible:true, properties: Object.keys(props).map(function(k){var v=props[k];return {name:k,type:typeof v==='boolean'?'bool':'int',value:v}})}; }
  function room(id, x0, y0, w, h, extra){ var p=[{name:'id',type:'int',value:id}]; for (var k in (extra||{})) p.push({name:k,type:'bool',value:extra[k]}); return {id: ids++, name:'', class:'BuildingRoom', x:x0*16, y:y0*16, width:w*16, height:h*16, visible:true, properties:p}; }
  var layer = {id: 99, name:'custom', type:'objectgroup', visible:true, objects:[
    room(11, 30, 30, 10, 6), room(12, 50, 30, 10, 6),
    tileObj('BuildingDoor', 32*16, (36*16), {id: 501, target: 502}),
    tileObj('BuildingDoor', 52*16, (36*16), {id: 502, target: 501}),
    tileObj('BuildingDoor', 37*16, (36*16), {id: 503, target: 504}),
    tileObj('BuildingDoor', 57*16, (36*16), {id: 504, target: 503})
  ]};
  m.layers.push(layer);
  window.__LevelLoader.testText.set(0, JSON.stringify(m));
  return 'ok';
})()
'@
    "inject: " + (Js $js)
    Start-Sleep -Seconds 1
    $r = Js "(function(){ window.__ps.cheatGoto(0); return 1; })()"
    Start-Sleep -Seconds 6
    "doors in level: " + (Js "window.__ps.data.doors.length")
    "bunker A floor wall tile (30..39, row 36) bricks: " + (Js "(function(){var d=window.__ps.data; var n=0; for (var x=29;x<=40;x++){ if (d.solid[36*d.w+x]===3) n++; } return n;})()")
    "bunker A interior empty: " + (Js "(function(){var d=window.__ps.data; var n=0; for (var y=30;y<36;y++) for (var x=30;x<40;x++) n+=d.solid[y*d.w+x]; return n===0;})()")
    "rooms: " + (Js "window.__ps.data.buildings.length")
    # a hős az A1 ajtó elé, majd Fel: a B1 ajtó elé kell kerülnie (a másik bunkerben)
    Js "(function(){var p=window.__ps; p.inside = true; p.player.reset(32*16-2, 36*16-14-2); p.player.velocity.set(0,0);})()" | Out-Null
    Start-Sleep -Milliseconds 800
    "pre: " + (Js "(function(){var p=window.__ps; return JSON.stringify({bd:p.bDoors.length, d0:p.bDoors.map(function(d){return [Math.round(d.spr.x),Math.round(d.spr.y),Math.round(d.tx),Math.round(d.ty)]}), hero:[Math.round(p.player.x),Math.round(p.player.y)], ctrl:p.ctrl===p.player, tele:p.teleporting, hint:p.hint.visible})})()")
    Key "keyDown" "ArrowUp" "ArrowUp" 38; Start-Sleep -Milliseconds 700; Key "keyUp" "ArrowUp" "ArrowUp" 38
    Start-Sleep -Seconds 2
    "hero x tile after door (expect ~52 = bunker B): " + (Js "Math.round(window.__ps.player.x/16)")
    "inside flag: " + (Js "window.__ps.inside")
    Shot "bunkers.png"
    "errors: " + ((Js "window.__errors") -join '; ')
} finally {
    try { Stop-Cdp } catch {}
    if ($srv -and -not $srv.HasExited) { Stop-Process -Id $srv.Id -Force }
}
