# Teszt: a társak átugorják a szakadékot (nem esnek le), és a pálya végén bemennek az ajtón (nem zuhannak le).
param([string]$Base = "http://127.0.0.1:3220/", [string]$Out = "$PSScriptRoot\out", [int]$Level = 2, [int]$Gap = 3)
. "$PSScriptRoot\cdp-lib.ps1"
try {
    Start-Cdp ($Base + "?level=$Level") $Out
    Start-Sleep -Seconds 9
    # mesterséges szakadék: egy sík szakaszon kivájunk $Gap oszlopot, a társ az egyik, a hős a másik oldalon
    $js = @"
(function(){
  var p = window.__ps, d = p.data;
  for (var x = 20; x < d.w - 24; x++) {
    var ok = true;
    for (var k = 0; k < 24; k++) { if (d.top[x + k] != d.top[x]) { ok = false; break; } for (var h = 1; h <= 4; h++) { if (d.solid[(d.top[x] - h) * d.w + x + k] != 0 || d.plats[(d.top[x] - h) * d.w + x + k] != 0) { ok = false; } } if (!ok) break; }
    if (ok) {
      var gx = x + 8;
      for (var c = gx; c < gx + $Gap; c++) {
        for (var r = d.top[x]; r < 56; r++) { p.solidMap.setTile(c, r, 0); d.solid[r * d.w + c] = 0; }
        d.top[c] = 99;
      }
      return JSON.stringify({ a: gx - 1, b: gx + $Gap, ya: d.top[x] });
    }
  }
  return 'none';
})()
"@
    $info = Js $js
    "gap: $info"
    $p = $info | ConvertFrom-Json
    $setup = @"
(function(){
  var p = window.__ps; var a = $($p.a), b = $($p.b), ya = $($p.ya);
  window.__w = p.spawnCompanion(0, (a - 3) * 16, (ya - 1) * 16); window.__w.mode = 0;
  window.__t = p.spawnCompanion(1, (a - 5) * 16, (ya - 2) * 16); window.__t.mode = 0;
  p.player.reset((b + 4) * 16, (ya - 2) * 16); p.player.invuln = 99;
})()
"@
    Js $setup | Out-Null
    Start-Sleep -Seconds 14
    "wheelie: x=" + [math]::Round([double](Js "window.__w.x")) + " y=" + [math]::Round([double](Js "window.__w.y")) + " alive=" + (Js "window.__w.alive") + " (gap ends at px " + ($p.b * 16) + ", ground y " + ($p.ya * 16) + ")"
    "tall:    x=" + [math]::Round([double](Js "window.__t.x")) + " y=" + [math]::Round([double](Js "window.__t.y")) + " alive=" + (Js "window.__t.alive")
    Shot "friends_pit.png"
    # a pálya vége: minden robotnak be kell lépnie az ajtón (Lost Vikings)
    Js "(function(){var p=window.__ps; for(var i=0;i<p.found.length;i++){p.found[i]=true;} p.partsFound=p.found.length; p.benchBuilt=true; var d=p.door; p.player.reset(d.x-12,d.y); window.__cam.focusOn(p.player.getMidpoint()); window.__w.reset(d.x-30,d.y); window.__t.reset(d.x-50,d.y-10); window.__w.mode=1; window.__t.mode=1;})()" | Out-Null
    Start-Sleep -Seconds 1
    "mode before enter: " + (Js "window.__ps.mode")
    Js "window.__ps.robotEnters(window.__ps.player)" | Out-Null
    Start-Sleep -Seconds 1
    "control after hero entered: " + (Js "window.__ps.nameOf(window.__ps.ctrl)") + " mode=" + (Js "window.__ps.mode")
    Js "window.__ps.robotEnters(window.__ps.ctrl)" | Out-Null
    Start-Sleep -Seconds 4
    Js "window.__ps.robotEnters(window.__ps.ctrl)" | Out-Null
    Start-Sleep -Seconds 12
    "door: mode=" + (Js "window.__ps.mode") + " wheelieAlive=" + (Js "window.__w.alive") + " tallAlive=" + (Js "window.__t.alive") + " wheelieY=" + [math]::Round([double](Js "window.__w.y"))
    "errors: " + ((Js "window.__errors") -join '; ')
} finally { Stop-Cdp }
