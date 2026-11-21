# CPU-profil a pályaváltás első másodperceiről (legnagyobb önidejű függvények).
param([string]$Base = "http://127.0.0.1:3220/", [string]$Out = "$PSScriptRoot\out", [int]$Level = 1)
. "$PSScriptRoot\cdp-lib.ps1"
try {
    Start-Cdp ($Base + "?level=$Level") $Out
    Start-Sleep -Seconds 12
    Send-Cdp "Profiler.enable" @{} | Out-Null
    Send-Cdp "Profiler.setSamplingInterval" @{ interval = 500 } | Out-Null
    Send-Cdp "Profiler.start" @{} | Out-Null
    Js "window.__ps.nextLevel()" | Out-Null
    Start-Sleep -Milliseconds 1500
    $r = Send-Cdp "Profiler.stop" @{}
    $p = $r.result.profile
    $self = @{}
    $byId = @{}
    foreach ($n in $p.nodes) { $byId[[int]$n.id] = $n }
    for ($i = 0; $i -lt $p.samples.Count; $i++) {
        $id = [int]$p.samples[$i]
        $dt = [double]$p.timeDeltas[$i] / 1000.0
        $n = $byId[$id]
        $name = $n.callFrame.functionName
        if (-not $name) { $name = "(anon)" }
        $key = "$name @ " + ($n.callFrame.url -replace '^.*/', '') + ":" + $n.callFrame.lineNumber
        if ($self.ContainsKey($key)) { $self[$key] += $dt } else { $self[$key] = $dt }
    }
    $self.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 18 | ForEach-Object { "{0,8:N1} ms  {1}" -f $_.Value, $_.Key }
} finally { Stop-Cdp }
