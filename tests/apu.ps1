# Teszt: APU (hang-processzor) alkatrész a 2. pályán; a hangminőség-lánc (AudioFx) az APU szintjéből (nélküle tompa / zajos, V. szinten tiszta);
# az alkatrész-nevek (GPU, CPU, APU); eszköz-súgó a láda mellett, és kikapcsolva nincs. Kép: tests/out/apu-hint.png, apu-showcase.png
param([string]$Base = "http://127.0.0.1:3220/", [string]$Out = "$PSScriptRoot\out")
. "$PSScriptRoot\cdp-lib.ps1"
function Tap($key, $code, $vk) { Key "keyDown" $key $code $vk; Start-Sleep -Milliseconds 500; Key "keyUp" $key $code $vk; Start-Sleep -Milliseconds 500 }
try {
    Start-Cdp ($Base + "?level=1") $Out
    Start-Sleep -Seconds 12
    Tap "ArrowRight" "ArrowRight" 39   # felhasználói esemény: a hangkörnyezet feloldása
    Start-Sleep -Seconds 2
    "parts: " + (Js "window.__ps.data.parts.map(function(p){return p.label+'#'+p.icon;}).join(', ')")
    "audio fx (no APU): " + (Js "window.__AudioFx.debug()")
    Js "(function(){var p=window.__ps; p.bannerT=0; var it=p.partItems.members.filter(function(x){return x.alive && x.icon==13;})[0]; p.player.reset(it.x, it.y-6);})()" | Out-Null
    Start-Sleep -Seconds 3
    "APU picked: tier=" + (Js "window.__Parts.tier(13)") + "  fx: " + (Js "window.__AudioFx.debug()")
    Shot "apu-showcase.png"
    Js "(function(){window.__Parts.tiers[13]=5;})()" | Out-Null
    Start-Sleep -Seconds 2
    "APU V: " + (Js "window.__AudioFx.debug()")
    # eszköz-súgó a láda mellett
    Js "(function(){var p=window.__ps; p.toastT=0; p.toast.visible=false; var c=p.crates.members[0]; p.player.reset(c.x-p.player.width-2, c.y+16-p.player.height-1); p.player.frozen=true;})()" | Out-Null
    Start-Sleep -Seconds 3
    "hint near crate: visible=" + (Js "window.__ps.hint.visible") + " text=" + (Js "window.__ps.hint.text")
    Shot "apu-hint.png"
    Js "window.__Prefs.hints=false" | Out-Null
    Start-Sleep -Seconds 2
    "hint with DEVICE HINTS off: visible=" + (Js "window.__ps.hint.visible")
    Js "window.__Prefs.hints=true" | Out-Null
    "errors: " + ((Js "window.__errors") -join '; ')
} finally { Stop-Cdp }
