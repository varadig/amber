# Diagnosztika: WebGL elérhető-e a fejnélküli Edge-ben, és a kamera szűrői.
param([string]$Url = "http://127.0.0.1:3220/", [string]$Out = "$PSScriptRoot\out")
. "$PSScriptRoot\cdp-lib.ps1"
try {
    Start-Cdp $Url $Out
    Start-Sleep -Seconds 4
    "fresh webgl: " + (Js "(function(){var c=document.createElement('canvas');var g=c.getContext('webgl');return g?('yes '+g.getParameter(g.VERSION)):'no'})()")
    "cam filters: " + (Js "(function(){var p=window.__ps; if(!p) return 'no ps'; var c=p.cameras[0]; return JSON.stringify({n: c.filters? c.filters.length : -1})})()")
} finally { Stop-Cdp }
