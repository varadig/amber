# Teszt: a 7. pálya légi szakasza (136..235. oszlop): függőleges mozgó platform viszi a hőst (fel és le is, rázkódás nélkül, végig talajon áll),
# a JET CELL felvétele repülést ad és 5 mp (játékidő) után újratöltődik, a szigeteken / a szakaszban vannak repülő ellenségek.
param([string]$Base = "http://127.0.0.1:3220/", [string]$Out = "$PSScriptRoot/out")
. "$PSScriptRoot/cdp-lib.ps1"
try {
    Start-Cdp ($Base + "?level=6") $Out
    Start-Sleep -Seconds 10
    "width: " + (Js "window.__ps.data.w")
    "flyers in sky: " + (Js "window.__ps.enemies.members.filter(function(e){return e && e.alive && e.x>136*16 && e.x<236*16 && e.kind==1;}).length")
    # a hős a 1. függőleges platformra (a légi szakasz 23. oszlopa), ellenségek nélkül
    Js @"
(function(){
  var p=window.__ps; p.enemies.forEachAlive(function(e){ e.kill(); });
  var m=p.movers.members.filter(function(m){return m && Math.abs(m.x-(136+23)*16)<4;})[0]; window.__m=m;
  p.player.frozen=true; p.player.velocity.set(0,0);
  p.player.reset(m.x+16, m.y-p.player.height-1);
  window.__samples=[];
  return 1;
})()
"@ | Out-Null
    # félidőben a platform lefelé indul (a fejnélküli böngészőben a játékidő lassú: a fázist mi állítjuk át a mintavétel közepén)
    # 6 mp (valós) mintavétel: a talp és a platform teteje közti távolság, irány, talajon áll-e
    for ($i = 0; $i -lt 30; $i++) {
        if ($i -eq 15) { Js "(function(){var m=window.__m; var om=Math.PI*m.range/m.range; m.t=Math.PI/m.omega+0.05; return 1;})()" | Out-Null }
        Start-Sleep -Milliseconds 200
        Js "(function(){var p=window.__ps, m=window.__m; window.__samples.push([Math.round((p.player.y+p.player.height-m.y)*10)/10, m.dy>0?'down':(m.dy<0?'up':'-'), p.player.onFloor?1:0]); return 1;})()" | Out-Null
    }
    $s = Js "JSON.stringify(window.__samples)"
    "samples [feet-top, dir, onFloor]: $s"
    $arr = $s | ConvertFrom-Json
    $bad = @($arr | Where-Object { [math]::Abs($_[0]) -gt 2 }).Count
    $dirs = ($arr | ForEach-Object { $_[1] } | Sort-Object -Unique) -join ","
    "rides (|feet-top|<=2 in all samples): " + ($bad -eq 0) + "  dirs seen: $dirs"
    # JET CELL: felvétel -> repülés, 5 mp múlva újra ott
    $r = Js @"
(function(){
  var p=window.__ps; var c=p.cells.members.filter(function(c){return c && c.alive && c.x>136*16 && c.x<236*16;})[0]; window.__c=c;
  p.player.reset(c.x-1, c.y-4); p.onCell(p.player, c);
  var fuel=p.player.flightT; p.player.reset(c.x-200, c.y-60); p.player.flightT=fuel; // el a cellától (különben azonnal újra felveszi)
  return JSON.stringify({alive:c.alive, fuel:Math.round(p.player.flightT*10)/10});
})()
"@
    "after pickup: $r"
    $n = 0
    while ($n -lt 150 -and -not (Js "window.__c.alive")) { Start-Sleep -Milliseconds 500; $n++ }
    "cell refilled: " + (Js "window.__c.alive") + " (after ~$([math]::Round($n/2,1)) s real time)"
    "errors: " + ((Js "window.__errors") -join '; ')
} finally { Stop-Cdp }
