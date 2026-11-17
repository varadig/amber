# Teszt: fejlesztői ugrás URL-ből (?level=&goto=&parts=) és a PageDown léptetés.
param([int]$Port = 3238)
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
. "$PSScriptRoot\cdp-lib.ps1"
$node = Join-Path (haxelib libpath lime).Trim() "templates\bin\node\node-windows.exe"
$srv = Start-Process $node -ArgumentList "`"$root\scripts\devserver.js`"", "`"$root\export\html5\bin`"", $Port -PassThru -WindowStyle Hidden
Start-Sleep -Seconds 2
$fail = 0
function Check($name, $cond) { if ($cond) { "OK    $name" } else { "HIBA  $name"; $script:fail++ } }
try {
    foreach ($case in @(
        @{ q = "level=0&goto=building1"; inside = "true" },
        @{ q = "level=0&goto=cp2"; inside = "false" },
        @{ q = "level=0&goto=part2"; inside = "false" },
        @{ q = "level=0&goto=300,200"; inside = "false" }
    )) {
        Start-Cdp "http://127.0.0.1:$Port/?$($case.q)" "$PSScriptRoot\out"
        Start-Sleep -Seconds 6
        $r = Js "(function(){var p=window.__ps;return JSON.stringify({ins:p.inside,x:Math.round(p.player.x),y:Math.round(p.player.y),sx:Math.round(p.data.spawn.x)})})()"
        "$($case.q): $r"
        $o = $r | ConvertFrom-Json
        Check "$($case.q) inside=$($case.inside)" ("$($o.ins)".ToLower() -eq $case.inside)
        Check "$($case.q) a hős nem a kezdőpontnál van" ([math]::Abs($o.x - $o.sx) -gt 20)
        Stop-Cdp
    }
    Start-Cdp "http://127.0.0.1:$Port/?level=3&goto=spawn&parts=prev" "$PSScriptRoot\out"
    Start-Sleep -Seconds 6
    $n = Js "window.__parts.filter(function(v){return v}).length"
    "parts owned at level 4 with parts=prev: $n"
    Check "parts=prev alkatrészeket ad" ([int]$n -ge 3)
    Stop-Cdp
    if ($fail -gt 0) { "HIBA: $fail ellenőrzés nem ment át."; exit 1 } else { "Minden ellenőrzés rendben." }
} finally {
    try { Stop-Cdp } catch {}
    if ($srv -and -not $srv.HasExited) { Stop-Process -Id $srv.Id -Force }
}
