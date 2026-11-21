# Teszt: a társak / a követő hős újra-megjelenése (lemaradás, elakadás, leesés) biztonságos felületre kerül (PlayState.safeSpot):
# a pálya minden 3. oszlopában a hőst a talajra állítjuk, és ellenőrizzük, hogy a MICRO / TALL helye szilárd talaj mindkét szomszéddal,
# a test elfér, és a régi fix hely (a hős mellett) hány esetben lett volna szakadék fölött. Végül egy valódi leesést is kiprovokálunk.
param([string]$Base = "http://127.0.0.1:3220/", [int]$Level = 5, [string]$Out = "$PSScriptRoot\out")
. "$PSScriptRoot\cdp-lib.ps1"
try {
    Start-Cdp ($Base + "?level=$Level") $Out
    Start-Sleep -Seconds 10
    Js "(function(){var p=window.__ps; p.cheatCompanion(0); p.cheatCompanion(1); p.player.frozen=true;})()" | Out-Null
    Start-Sleep -Seconds 2
    $r = Js @"
(function(){
  var p=window.__ps, d=p.data, T=16, res={tested:0, found:0, bad:0, oldUnsafe:0, none:0, badList:[]};
  var cs=p.companions.members.filter(function(c){return c && c.alive;});
  for (var col=4; col<d.w-4; col+=3) {
    var row=-1; for (var y=2; y<d.killRow; y++) if (d.isStandable(col,y) && !d.isSolid(col,y-1) && !d.isSolid(col,y-2)) { row=y; break; }
    if (row<0) continue;
    p.player.x = col*T + 8 - p.player.width/2; p.player.y = row*T - p.player.height - 1;
    for (var i=0;i<cs.length;i++) {
      var c=cs[i]; res.tested++;
      // régi viselkedés: fix hely a hős mellett (18 px mögötte)
      var oc = Math.floor((p.player.x - 18 + c.width/2)/T); var ground=false;
      for (var k=0;k<3;k++) if (d.isStandable(oc,row+k)) ground=true;
      if (!ground) res.oldUnsafe++;
      var s=p.safeSpot(c, p.player);
      if (!s) { res.none++; continue; }
      res.found++;
      var sc=Math.floor((s.x + c.width/2)/T), sr=Math.floor((s.y + c.height + 2)/T);
      var good = d.isStandable(sc-1,sr) && d.isStandable(sc,sr) && d.isStandable(sc+1,sr) && !d.isSolid(sc,sr-1) && sr < d.killRow + 30;
      if (!good) { res.bad++; if (res.badList.length<8) res.badList.push([col,row,c.kind,sc,sr]); }
    }
  }
  return JSON.stringify(res);
})()
"@
    "spots: $r"
    # valódi leesés: a MICRO a szakadékba kerül, a következő képkockákban biztonságos helyre kell visszakerülnie
    $fall = Js @"
(function(){
  var p=window.__ps, d=p.data;
  var c=p.companions.members.filter(function(c){return c && c.alive && c.kind==0;})[0];
  c.reset(c.x, (d.killRow+4)*16); c.velocity.set(0,0);
  return 'ok';
})()
"@
    Start-Sleep -Seconds 2
    "after fall: " + (Js @"
(function(){
  var p=window.__ps, d=p.data, c=p.companions.members.filter(function(c){return c && c.alive && c.kind==0;})[0];
  var sc=Math.floor((c.x+c.width/2)/16), sr=Math.floor((c.y+c.height+2)/16);
  return JSON.stringify({x:Math.round(c.x), y:Math.round(c.y), onGround:d.isStandable(sc,sr), heroDist:Math.round(Math.abs(c.x-p.player.x))});
})()
"@)
    "errors: " + ((Js "window.__errors") -join '; ')
} finally { Stop-Cdp }
