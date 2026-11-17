# Teszt: ha egy robot belép a kijáratba, a többi (hős + társ) magától követi, és a pálya véget ér.
param([string]$Base = "http://127.0.0.1:3220/", [string]$Out = "$PSScriptRoot\out")
. "$PSScriptRoot\cdp-lib.ps1"
try {
    Start-Cdp ($Base + "?level=3") $Out
    Start-Sleep -Seconds 9
    # a társ az ajtónál (irányított), a hős és egy másik társ távolabb a földön
    Js "(function(){var p=window.__ps; window.__parts[0]=true; p.partsFound=99; p.benchBuilt=true; var d=p.door; var gy=d.y+d.height; var a=p.spawnCompanion(1,d.x-6,gy-30); var b=p.spawnCompanion(0,d.x-90,gy-30); p.player.reset(d.x-60,gy-p.player.height); window.__a=a; window.__b=b; p.setControl(a);})()" | Out-Null
    Start-Sleep -Seconds 1
    for ($i = 0; $i -lt 12; $i++) {
        Start-Sleep -Seconds 1
        "t=$i exiting=" + (Js "window.__ps.exiting") + " heroExited=" + (Js "window.__ps.heroExited") + " mode=" + (Js "window.__ps.mode") + " alive=" + (Js "window.__ps.companions.countLiving()")
    }
    "errors: " + ((Js "window.__errors") -join '; ')
} finally { Stop-Cdp }
