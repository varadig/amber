# Teszt: a foldi tars nem indul el egy szakadek folott lebego atomert (lootSafe), de a biztonsagos atomert igen.
param([string]$Base = "http://127.0.0.1:3220/", [string]$Out = "$PSScriptRoot\out", [int]$Level = 2)
. "$PSScriptRoot\cdp-lib.ps1"
try {
    Start-Cdp ($Base + "?level=$Level") $Out
    Start-Sleep -Seconds 8
    Js "(function(){var p=window.__ps; window.__g = p.gems.members.filter(function(g){return !g.secret;})[0]; p.gems.forEach(function(g){ if(g!==window.__g) g.kill(); }); p.batts.forEach(function(g){g.kill();}); var sp=p.player; var c=p.spawnCompanion(0, sp.x+20, sp.y); window.__c=c; c.mode=1;})()" | Out-Null
    Start-Sleep -Seconds 2
    $r = Js @"
(function(){
  var p=window.__ps, d=p.data, T=16, c=window.__c;
  var fr=Math.floor((c.y+c.height+2)/T), c0=Math.floor((c.x+c.width/2)/T);
  var pit=-1, ok=-1;
  for (var k=2;k<14;k++){ var col=c0+k; var any=false; for(var j=0;j<14;j++) if(d.isStandable(col,fr+j)) any=true; if(!any && pit<0) pit=col; }
  for (var k=1;k<6;k++){ var col=c0+k; var all=true; for(var m=0;m<=k;m++) if(!d.isStandable(c0+m,fr)) all=false; if(all) ok=col; }
  return JSON.stringify({pit:pit, ok:ok, fr:fr, c0:c0, onFloor:c.isTouching(256)});
})()
"@
    "geometry: $r"
    $o = $r | ConvertFrom-Json
    if ($o.pit -ge 0) {
        $js = "(function(){var g=window.__g,T=16; g.reset($($o.pit)*T+4,($($o.fr)-1)*T); g.alpha=1; var l=window.__c.findLoot(window.__c,null); return 'pit atom -> ' + (l?'CHASE (bad)':'ignored (good)');})()"
        "pit: " + (Js $js)
    } else { "no pit near spawn on this level" }
    if ($o.ok -ge 0) {
        $js = "(function(){var g=window.__g,T=16; g.reset($($o.ok)*T+4,($($o.fr)-1)*T); g.alpha=1; var l=window.__c.findLoot(window.__c,null); return 'safe atom -> ' + (l?'chase (good)':'ignored (bad)');})()"
        "safe: " + (Js $js)
    } else { "no flat ground near spawn" }
    "errors: " + ((Js "window.__errors") -join '; ')
} finally { Stop-Cdp }
