# Teszt: nincs szÃ­v: a talÃ¡lat az akkut merÃ­ti; kimerÃ¼lt akku = egy Ã©let fogy; 3 halÃ¡l utÃ¡n vÃ©ge (minden elvÃ©sz, Ãºjra az 1. pÃ¡lya); a tÃ¡rsak a LEGS-szinttel erÅ‘sÃ¶dnek.
param([string]$Base = "http://127.0.0.1:3220/", [string]$Out = "$PSScriptRoot\out")
. "$PSScriptRoot\cdp-lib.ps1"
function WaitPlay { for ($k = 0; $k -lt 80; $k++) { Start-Sleep -Milliseconds 500; if ("$(Js 'window.__ps ? window.__ps.mode : -1')" -eq "0") { Start-Sleep -Milliseconds 800; return } } }
try {
    Start-Cdp ($Base + "?level=2") $Out
    Start-Sleep -Seconds 8
    "lives=" + (Js "window.__Parts.lives") + " battery=" + [math]::Round([double](Js "window.__getBatt()"))
    Js "(function(){window.__ps.player.invuln=0; window.__ps.cheatDamage();})()" | Out-Null
    Start-Sleep -Milliseconds 300
    "after hit battery=" + [math]::Round([double](Js "window.__getBatt()")) + " (hitCost=" + [math]::Round([double](Js "window.__Parts.hitCost()")) + ") lives=" + (Js "window.__Parts.lives")
    "boost legs1: run=" + (Js "window.__Parts.runBoost()") + " jump=" + (Js "window.__Parts.jumpBoost()")
    Js "(function(){window.__Parts.add(0); window.__Parts.add(0); window.__Parts.add(0);})()" | Out-Null
    "boost legs: tier=" + (Js "window.__Parts.tier(0)") + " run=" + (Js "window.__Parts.runBoost()") + " jump=" + (Js "window.__Parts.jumpBoost()")
    Js "(function(){window.__setBatt(0.4);})()" | Out-Null
    $n = 0; while ($n -lt 60 -and "$(Js 'window.__ps.mode')" -ne "2") { Start-Sleep -Milliseconds 250; $n++ }
    "battery empty -> mode=" + (Js "window.__ps.mode") + " lives=" + (Js "window.__Parts.lives") + " overlay=" + (Js "window.__ps.overlay.text").Replace("`n", " | ")
    WaitPlay
    "after restart: mode=" + (Js "window.__ps.mode") + " lives=" + (Js "window.__Parts.lives") + " battery=" + [math]::Round([double](Js "window.__getBatt()")) + " legs=" + (Js "window.__Parts.tier(0)")
    for ($i = 0; $i -lt 3; $i++) {
        Js "(function(){window.__ps.cheatKill();})()" | Out-Null
        $n = 0; while ($n -lt 20 -and "$(Js 'window.__ps.mode')" -ne "2") { Start-Sleep -Milliseconds 100; $n++ }
        "death $i : lives=" + (Js "window.__Parts.lives") + " overlay=" + (Js "window.__ps.overlay.text").Replace("`n", " | ")
        WaitPlay
    }
    "final: lives=" + (Js "window.__Parts.lives") + " legs=" + (Js "window.__Parts.tier(0)") + " (game over -> reset)"
    "errors: " + ((Js "window.__errors") -join '; ')
} finally { Stop-Cdp }

