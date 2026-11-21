# Teszt: a mélybe zuhant láda visszakerül a kiinduló helyére (PlayState.rescueCrates), üzenettel; a pályán kívülre lökött is.
param([string]$Base = "http://127.0.0.1:3220/", [int]$Level = 1, [string]$Out = "$PSScriptRoot/out")
. "$PSScriptRoot/cdp-lib.ps1"
try {
    Start-Cdp ($Base + "?level=$Level") $Out
    Start-Sleep -Seconds 9
    Js "(function(){window.__ps.player.frozen=true;})()" | Out-Null
    "crates: " + (Js "window.__ps.crates.members.filter(function(c){return c && c.alive;}).length")
    $start = Js "(function(){var c=window.__ps.crates.members.filter(function(c){return c && c.alive;})[0]; window.__cr=c; return JSON.stringify({x:Math.round(c.x), y:Math.round(c.y)});})()"
    "start: $start"
    # a halálsor alá (a mélybe) tesszük, vízszintesen máshová
    Js "(function(){var p=window.__ps, c=window.__cr; c.reset(c.x + 300, (p.data.killRow + 3) * 16); c.velocity.set(0, 0); return 1;})()" | Out-Null
    Start-Sleep -Seconds 2
    $after = Js "JSON.stringify({x:Math.round(window.__cr.x), y:Math.round(window.__cr.y), toast:window.__ps.toast.text})"
    "after fall: $after"
    $s = $start | ConvertFrom-Json; $a = $after | ConvertFrom-Json
    "returned: " + ([math]::Abs($s.x - $a.x) -le 2 -and [math]::Abs($s.y - $a.y) -le 4)
    "toast: " + ($a.toast -match "CRATE")
    # a pálya szélén túl
    Js "(function(){var c=window.__cr; c.reset(-120, c.y); c.velocity.set(0, 0); return 1;})()" | Out-Null
    Start-Sleep -Seconds 2
    $after2 = Js "JSON.stringify({x:Math.round(window.__cr.x), y:Math.round(window.__cr.y)})" | ConvertFrom-Json
    "returned from outside: " + ([math]::Abs($s.x - $after2.x) -le 2 -and [math]::Abs($s.y - $after2.y) -le 4)
    # egy épp a helyén álló láda nem ugrik vissza (nincs téves mentés)
    Js "(function(){var c=window.__cr; c.reset(c.x + 16, c.y); c.velocity.set(0, 0); window.__cx=c.x; return 1;})()" | Out-Null
    Start-Sleep -Seconds 2
    "untouched when safe: " + (Js "Math.abs(window.__cr.x - window.__cx) < 3")
    "errors: " + ((Js "window.__errors") -join '; ')
} finally { Stop-Cdp }
