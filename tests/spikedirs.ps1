# Teszt: Tiled-ben forgatott / tükrözött tüskék (LevelLoader "Spike": rotation 90/180/270, gid függőleges tükrözés, `dir` tulajdonság):
# a tüske iránya, a sprite mérete (16x8 / 8x16) és a találati doboz helye; képernyőkép: tests/out/spikedirs.png.
param([string]$Base = "http://127.0.0.1:3220/", [string]$Out = "$PSScriptRoot/out")
. "$PSScriptRoot/cdp-lib.ps1"
try {
    Start-Cdp ($Base + "?level=0") $Out
    Start-Sleep -Seconds 8
    $js = @'
(async function(){
  var m = JSON.parse(await (await fetch('assets/levels/level1.tmj')).text());
  var ids = 9000, G = 5 + 6;
  function sp(x, y, rot, gid, props){ return {id: ids++, name:'', x:x, y:y, width:16, height:8, rotation:rot, gid:gid, visible:true, properties:props||[]}; }
  m.layers.push({id: 99, name:'custom', type:'objectgroup', visible:true, objects:[
    sp(160, 288, 0, G),                 // fel, talajon
    sp(32, 256, 90, G),                 // jobbra (a bal fal oldalán)
    sp(224, 200, 180, G),               // le (forgatva)
    sp(240, 208, 0, G | 0x40000000),    // le (függőleges tükrözés)
    sp(304, 288, 270, G),               // balra
    sp(320, 288, 0, G, [{name:'dir', type:'string', value:'down'}])
  ]});
  window.__LevelLoader.testText.set(0, JSON.stringify(m));
  return 'ok';
})()
'@
    "inject: " + (Js $js)
    Js "(function(){ window.__ps.cheatGoto(0); return 1; })()" | Out-Null
    Start-Sleep -Seconds 8
    $r = Js "JSON.stringify(window.__ps.spikes.members.filter(function(s){return s.x<340 && s.y>190 && s.y<300;}).map(function(s){return [s.ID, Math.round(s.x-s.offset.x), Math.round(s.y-s.offset.y), s.frameWidth, s.frameHeight, s.width, s.height];}))"
    "spikes [dir, x, y, fw, fh, w, h]: $r"
    $a = $r | ConvertFrom-Json
    $want = @(@(0,160,280,16,8), @(1,32,256,8,16), @(2,208,200,16,8), @(2,240,200,16,8), @(3,296,272,8,16), @(2,320,280,16,8))
    $ok = $true
    foreach ($w in $want) { if (-not ($a | Where-Object { $_[0] -eq $w[0] -and $_[1] -eq $w[1] -and $_[2] -eq $w[2] -and $_[3] -eq $w[3] -and $_[4] -eq $w[4] })) { "missing: $($w -join ',')"; $ok = $false } }
    "all orientations: $ok"
    # a mennyezeti tüske alá ugró hős sérül
    Js "(function(){var p=window.__ps; p.player.reset(210, 209); p.player.velocity.set(0,-250); window.__h0=p.player.flickering||0; return 1;})()" | Out-Null
    Start-Sleep -Milliseconds 900
    "hit by ceiling spike: " + (Js "window.__ps.player.invuln>0")
    Js "(function(){var p=window.__ps; p.player.frozen=true; p.player.reset(130, 260); window.__cam.target=null; window.__cam.scroll.set(220-240, 250-135); return 1;})()" | Out-Null
    Start-Sleep -Milliseconds 600
    Shot "spikedirs.png" | Out-Null
    "errors: " + ((Js "window.__errors") -join '; ')
} finally { Stop-Cdp }
