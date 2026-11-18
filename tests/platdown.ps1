# Teszt: a követő társ lelép / leugrik egy magas (akár 8-10 csempe) egyirányú platformról a lent álló hős után.
param([string]$Base = "http://127.0.0.1:3220/", [string]$Out = "$PSScriptRoot\out", [int]$Level = 3, [int]$MinH = 2, [int]$HeroOff = 0)
. "$PSScriptRoot\cdp-lib.ps1"
try {
    Start-Cdp ($Base + "?level=$Level") $Out
    Start-Sleep -Seconds 9
    $f = Js "(function(){var d=window.__ps.data; var best=null; for(var r=4;r<44;r++){ for(var c=4;c<d.w-6;c++){ if(d.isStandable(c,r) && !d.isSolid(c,r) && d.isStandable(c+1,r) && !d.isSolid(c+1,r)){ for(var h=$MinH;h<=14;h++){ var g=r+h; if(d.isSolid(c,g)){ var free=true; for(var k=r+1;k<g;k++){ if(d.isStandable(c,k)) free=false; } if(free && !d.isSolid(c,g-1)) { return JSON.stringify({c:c,r:r,g:g}); } break; } } } } } return 'none';})()"
    "platform: $f"
    if ($f -eq "none") { return }
    $o = $f | ConvertFrom-Json
    Js "(function(){var p=window.__ps; window.__parts[0]=true; p.player.refreshLook(); var c=p.spawnCompanion(0, $($o.c)*16+4, $($o.r)*16-14); window.__c=c; c.mode=0; p.player.reset($($o.c)*16+4+$HeroOff, $($o.g)*16-14);})()" | Out-Null
    Start-Sleep -Seconds 8
    $feet = [double](Js "window.__c.y+window.__c.height")
    "drop = " + (($o.g - $o.r) * 16) + " px; companion feet=" + [math]::Round($feet) + " platform top=" + ($o.r * 16) + " ground top=" + ($o.g * 16) + " x=" + [math]::Round([double](Js "window.__c.x")) + $(if ([math]::Abs($feet - $o.g * 16) -lt 4) { "  -> DOWN" } else { "  -> STILL UP" })
    "errors: " + ((Js "window.__errors") -join '; ')
} finally { Stop-Cdp }
