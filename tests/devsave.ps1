# Teszt: fejlesztői mentés (DevSave): pillanatkép (alkatrész, kapuk, helyzet, atomok), kézi mentés, majd betöltés a pálya újraindításával;
# a betöltött állapot egyezik a mentettel. (A teszt-build nem ment automatikusan: a kézi SAVE NOW-t használja.)
param([string]$Base = "http://127.0.0.1:3220/", [string]$Out = "$PSScriptRoot\out")
. "$PSScriptRoot\cdp-lib.ps1"
$st = "(function(){var p=window.__ps; return JSON.stringify({lvl:window.__ps.constructor.level, px:Math.round(p.player.x), py:Math.round(p.player.y), parts:p.partsFound, atoms:window.__Parts.atoms, gatesOpen:p.gates.members.filter(function(g){return !g.visible;}).length, score:p.score});})()"
try {
    Start-Cdp ($Base + "?level=1") $Out
    Start-Sleep -Seconds 12
    Js "(function(){var p=window.__ps; p.bannerT=0; var it=p.partItems.members.filter(function(x){return x.alive;})[0]; p.onPart(p.player,it); p.cheatOpenGates(); window.__Parts.atoms=77; p.player.reset(p.player.x+200, p.player.y-40);})()" | Out-Null
    Start-Sleep -Seconds 2
    Js "(function(){window.__ps.player.frozen=true;})()" | Out-Null
    $before = Js $st
    "before save: $before"
    Js "(function(){window.__DevSave.saveNow(window.__ps.devSnapshot());})()" | Out-Null
    "saves: " + (Js "window.__DevSave.list().length") + "  first: " + (Js "window.__DevSave.describe(window.__DevSave.list()[0])")
    # valami mást csinálunk, aztán betöltjük
    Js "(function(){window.__Parts.atoms=0; window.__ps.player.reset(40, 200);})()" | Out-Null
    # a fejnélküli böngészőben egy látszólagos kontroller mozgatja a hőst: a betöltés után azonnal (az új PlayState első képkockáiban) olvasunk
    Js "(function(){window.__oldPs=window.__ps; window.__devLoad(window.__DevSave.list()[0]);})()" | Out-Null
    $n = 0
    while ($n -lt 120 -and (Js "window.__ps===window.__oldPs")) { Start-Sleep -Milliseconds 250; $n++ }
    $after = Js $st
    "after load:  $after"
    # (a fizika 1-2 px-t mozdíthat a hősön a betöltés első képkockáiban: tűréssel hasonlítunk)
    $b = $before | ConvertFrom-Json; $a = $after | ConvertFrom-Json
    "match: " + ([math]::Abs($b.px - $a.px) -le 2 -and [math]::Abs($b.py - $a.py) -le 2 -and $b.parts -eq $a.parts -and $b.atoms -eq $a.atoms -and $b.gatesOpen -eq $a.gatesOpen -and $b.score -eq $a.score)
    "errors: " + ((Js "window.__errors") -join '; ')
} finally { Stop-Cdp }
