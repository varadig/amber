# Teszt: mind a 10 zenetéma (rétegenként más hangszer) hibátlanul renderelődik: nincs NaN, a csúcs normalizált,
# és a háttér-renderelés egy képkockás szelete sem akad (step(5) leghosszabb ideje). Kiírja a téma hangszereit is.
param([string]$Base = "http://127.0.0.1:3220/", [string]$Out = "$PSScriptRoot\out")
. "$PSScriptRoot\cdp-lib.ps1"
try {
    Start-Cdp ($Base + "?level=0") $Out
    Start-Sleep -Seconds 10
    foreach ($i in 0..9) {
        $r = Js "(function(){var M=window.__Music; var j=M.start($i); var mx=0, n=0, t0=performance.now(); while(true){ var a=performance.now(); var done=j.step(5); var d=performance.now()-a; if(d>mx) mx=d; n++; if(done) break; } var s=j.result, nan=0, pk=0; for(var k=0;k<s.length;k++){ var v=s[k]; if(v!==v) nan++; else if(Math.abs(v)>pk) pk=Math.abs(v); } return M.describe($i)+' | sec='+(s.length/2/22050).toFixed(1)+' nan='+nan+' peak='+pk.toFixed(2)+' maxStepMs='+mx.toFixed(1)+' steps='+n+' totalMs='+(performance.now()-t0).toFixed(0); })()"
        "theme ${i}: $r"
    }
    "errors: " + ((Js "window.__errors") -join '; ')
} finally { Stop-Cdp }
