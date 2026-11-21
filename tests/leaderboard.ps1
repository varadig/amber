# Teszt: globális ranglista (Supabase REST) a dev szerver mock-jával: játék vége -> névbeírás (begépelt betűk + Enter) -> beküldés -> a lista
# a friss sorral kiemelve; a címképernyőről csak a lista. Saját szerver a $Port porton (a mock a scripts/devserver.js-ben).
param([int]$Port = 3241, [string]$Dir = "")
$ErrorActionPreference = "Stop"
. "$PSScriptRoot/cdp-lib.ps1"
$srv = Start-DevServer $Port $Dir
try {
    $lb = "lburl=http://127.0.0.1:$Port&lbkey=x"
    Start-Cdp "http://127.0.0.1:$Port/?level=1&$lb" "$PSScriptRoot/out"
    Start-Sleep -Seconds 9
    # játék vége: az utolsó élet elvész (pont kell a beküldéshez)
    Js "(function(){ var p=window.__ps; p.score=4321; window.__Parts.lives=1; p.cheatKill(); return 1; })()" | Out-Null
    $n = 0; while ($n -lt 120 -and "$(Js 'window.__ps.subState ? window.__ps.subState.entering : null')" -ne "true") { Start-Sleep -Milliseconds 500; $n++ }
    "name entry open: " + (Js "window.__ps.subState != null && window.__ps.subState.entering")
    Wait-GameTime 0.3
    foreach ($k in @(@("x", "KeyX", 88), @("y", "KeyY", 89), @("z", "KeyZ", 90))) {
        Key "keyDown" $k[0] $k[1] $k[2]; Wait-GameTime 0.05; Key "keyUp" $k[0] $k[1] $k[2]; Wait-GameTime 0.05
    }
    "typed: " + (Js "window.__ps.subState.letters.map(function(c){return String.fromCharCode(c);}).join('')")
    Key "keyDown" "Enter" "Enter" 13; Wait-GameTime 0.05; Key "keyUp" "Enter" "Enter" 13
    $n = 0; while ($n -lt 60 -and "$(Js 'window.__ps.subState ? window.__ps.subState.entering : null')" -ne "false") { Start-Sleep -Milliseconds 500; $n++ }
    Wait-GameTime 0.3
    $rows = Js "JSON.stringify(window.__ps.subState.rows.filter(function(r){return r[1].text!='';}).map(function(r){return r.map(function(t){return t.text;}).join(' ');}))"
    "list rows: $rows"
    "submitted + listed: " + ($rows -match "XYZ 4321") + "  highlighted: " + (Js "window.__ps.subState.highlight.visible")
    # a mock közvetlenül is
    "mock rows: " + (Invoke-RestMethod "http://127.0.0.1:$Port/rest/v1/amber_scores?limit=10" | ConvertTo-Json -Compress)
    "errors: " + ((Js "window.__errors") -join '; ')
} finally { Stop-Cdp; if ($srv) { Stop-Process -Id $srv.Id -Force -ErrorAction SilentlyContinue } }
