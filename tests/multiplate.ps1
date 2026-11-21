# Teszt: több azonos id-jű nyomólap: a fal csak akkor omlik le, ha MINDEGYIKEN láda áll (egy láda kevés; a levett láda felengedi a lapot).
param([string]$Base = "http://127.0.0.1:3220/", [string]$Out = "$PSScriptRoot/out")
. "$PSScriptRoot/cdp-lib.ps1"
try {
    Start-Cdp ($Base + "?level=0") $Out
    Start-Sleep -Seconds 8
    $js = @'
(async function(){
  var m = JSON.parse(await (await fetch('assets/levels/level1.tmj')).text());
  var ids = 9000, F = 5;
  function ob(g, x, y, w, h, props){ return {id: ids++, name:'', x:x, y:y, width:w, height:h, gid:F+g, visible:true, properties:props||[]}; }
  var id = [{name:'id', type:'int', value:91}];
  // a 2. talaj-szakasz (y=288 a talaj teteje a spawn körül): 3 lap, 3 láda, egy kapu
  m.layers.push({id: 99, name:'custom', type:'objectgroup', visible:true, objects:[
    ob(14, 160, 288, 16, 6, id), ob(14, 192, 288, 16, 6, id), ob(14, 224, 288, 16, 6, id),
    ob(11, 96, 288, 16, 16), ob(11, 112, 288, 16, 16), ob(11, 128, 288, 16, 16),
    ob(12, 256, 288, 16, 16, id)
  ]});
  window.__LevelLoader.testText.set(0, JSON.stringify(m));
  return 'ok';
})()
'@
    "inject: " + (Js $js)
    Js "(function(){ window.__ps.cheatGoto(0); return 1; })()" | Out-Null
    Start-Sleep -Seconds 8
    Js "(function(){ var p=window.__ps; p.player.frozen=true; p.player.reset(40, 270); window.__pl=p.plates.members.filter(function(x){return x.gid==91;}); window.__cr=p.crates.members.filter(function(c){return c.x>=90&&c.x<150;}); window.__g=p.gates.members.filter(function(g){return g.gid==91;})[0]; return window.__pl.length+','+window.__cr.length; })()"
    function Put($i, $k) { Js "(function(){ var c=window.__cr[$i], pl=window.__pl[$k]; c.reset(pl.x, pl.y + pl.height - 16); c.velocity.set(0,0); return 1; })()" | Out-Null }
    function State { Js "JSON.stringify({pressed: window.__pl.map(function(p){return p.pressed;}), open: !window.__g.visible, toast: window.__ps.toast.text})" }
    Put 0 0; Start-Sleep -Seconds 2
    $s1 = State; "one crate: $s1"
    Put 1 1; Start-Sleep -Seconds 2
    $s2 = State; "two crates: $s2"
    # a második ládát levesszük: a lapja felenged
    Js "(function(){ var c=window.__cr[1]; c.reset(112, 270); c.velocity.set(0,0); return 1; })()" | Out-Null
    Start-Sleep -Seconds 2
    $s3 = State; "crate removed: $s3"
    Put 1 1; Put 2 2; Start-Sleep -Seconds 2
    $s4 = State; "three crates: $s4"
    $a1 = $s1 | ConvertFrom-Json; $a2 = $s2 | ConvertFrom-Json; $a3 = $s3 | ConvertFrom-Json; $a4 = $s4 | ConvertFrom-Json
    "closed with 1-2 crates: " + (-not $a1.open -and -not $a2.open -and -not $a3.open)
    "plate released when crate removed: " + (-not $a3.pressed[1])
    "open with all 3: " + $a4.open
    "errors: " + ((Js "window.__errors") -join '; ')
} finally { Stop-Cdp }
