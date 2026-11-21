# Teszt: magyar nyelv (Lang / LangText): átváltás, a játék szövegei magyarul (HUD, info-doboz, szünet, pálya vége, műhely),
# a választás megmarad az újratöltés után (FlxSave), és visszaváltás angolra. Kiírja a megjelenített szövegeket (szemmel ellenőrizendő).
# Képek: tests/out/lang-*.png
param([string]$Base = "http://127.0.0.1:3220/", [string]$Out = "$PSScriptRoot\out")
. "$PSScriptRoot\cdp-lib.ps1"
function Tap($key, $code, $vk) { Key "keyDown" $key $code $vk; Start-Sleep -Milliseconds 700; Key "keyUp" $key $code $vk; Start-Sleep -Milliseconds 600 }
$dump = "(function(){var s={}; window.__Lang.live.forEach(function(t){ if(t.visible!==false && t.text && t.text.trim()) s[t.text.replace(/\n/g,' | ')]=1; }); return Object.keys(s).join('\n');})()"
try {
    Start-Cdp ($Base + "?level=1") $Out
    Start-Sleep -Seconds 12
    Js "window.__Lang.set(true)" | Out-Null
    Js "(function(){var p=window.__ps; p.bannerT=4; p.showToast('FOUND: VISOR\nCLEAR SIGHT AROUND YOU', 6);})()" | Out-Null
    Start-Sleep -Seconds 4
    Shot "lang-hud.png"
    "--- HUD:"; Js $dump
    Tap "p" "KeyP" 80
    Shot "lang-pause.png"
    "--- PAUSE:"; Js "window.__ps.overlay.text"
    Tap "p" "KeyP" 80
    Js "(function(){window.__parts[0]=true; window.__parts[2]=true; window.__Parts.atoms=500; window.__ps.levelClear();})()" | Out-Null
    Start-Sleep -Seconds 2
    "--- CLEAR:"; Js "window.__ps.overlay.text"
    Js "(function(){window.__ps.finishLevel();})()" | Out-Null
    Start-Sleep -Seconds 2
    Shot "lang-workshop.png"
    "--- WORKSHOP:"; Js $dump
    # megmarad-e a választás: újratöltés ugyanabban a böngészőben
    Send-Cdp "Page.reload" @{} | Out-Null
    Start-Sleep -Seconds 14
    "remembered after reload: lang=" + (Js "window.__Lang.code")
    "--- workshop rows wrap check (lines > 1 = overlap):"
    Js "(function(){window.__Parts.atoms=500; for(var i=0;i<8;i++){ window.__parts[i]=true; window.__Parts.tiers[i]=1+(i%3); } window.__ps.levelClear();})()" | Out-Null
    Start-Sleep -Seconds 2
    Js "(function(){window.__ps.finishLevel();})()" | Out-Null
    Start-Sleep -Seconds 2
    Shot "lang-workshop2.png"
    Js "(function(){var s=window.__ps.subState; if(!s) return 'no workshop'; return s.lines.map(function(t){return t.textField.numLines+' '+t.text;}).join('\n');})()"
    Js "window.__Lang.set(false)" | Out-Null
    Start-Sleep -Seconds 1
    "back to english: " + (Js "window.__ps.hudScore.text")
    "errors: " + ((Js "window.__errors") -join '; ')
} finally { Stop-Cdp }
