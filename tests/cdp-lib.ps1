# Minimális Chrome DevTools Protocol kliens a fejnélküli Edge vezérléséhez (Node nélkül).
# Használat: . "$PSScriptRoot\cdp-lib.ps1"; Start-Cdp <url> <kimeneti-mappa>; Js "<kifejezés>"; ... ; Stop-Cdp
# A játékot teszt-buildben (`haxelib run lime build html5 -Dtest`) kell kiszolgálni, pl. az 3000-es porton.

$script:CdpWs = $null
$script:CdpProc = $null
$script:CdpOut = $null
$script:CdpId = 0

function Start-Cdp([string]$Url, [string]$OutDir) {
    $script:CdpOut = $OutDir
    New-Item -ItemType Directory -Force $OutDir | Out-Null
    $edge = "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
    if (-not (Test-Path $edge)) { $edge = "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe" }
    if (-not (Test-Path $edge)) { throw "Az Edge nem található." }
    $profile = Join-Path $OutDir "edge-cdp"
    $script:CdpProc = Start-Process $edge -ArgumentList "--headless=new", "--remote-debugging-port=9334", "--window-size=1024,640", "--hide-scrollbars", "--use-gl=angle", "--use-angle=swiftshader", "--enable-unsafe-swiftshader", "--ignore-gpu-blocklist", "--enable-webgl", "--user-data-dir=$profile", "about:blank" -PassThru
    Start-Sleep -Seconds 3
    $page = (Invoke-RestMethod "http://127.0.0.1:9334/json") | Where-Object { $_.type -eq "page" } | Select-Object -First 1
    $script:CdpWs = New-Object System.Net.WebSockets.ClientWebSocket
    $script:CdpWs.Options.KeepAliveInterval = [TimeSpan]::FromSeconds(30)
    $script:CdpWs.ConnectAsync([Uri]$page.webSocketDebuggerUrl, [Threading.CancellationToken]::None).Wait()
    Send-Cdp "Page.enable" @{} | Out-Null
    Send-Cdp "Network.enable" @{} | Out-Null
    Send-Cdp "Network.setCacheDisabled" @{ cacheDisabled = $true } | Out-Null
    # JS-hibák gyűjtése: window.__errors
    Send-Cdp "Page.addScriptToEvaluateOnNewDocument" @{ source = "window.__navId = Math.random(); window.__errors = []; window.addEventListener('error', e => window.__errors.push(String(e.message)));" } | Out-Null
    Send-Cdp "Page.navigate" @{ url = $Url } | Out-Null
}

function Stop-Cdp {
    if ($script:CdpWs) { $script:CdpWs.Dispose() }
    if ($script:CdpProc) { Stop-Process -Id $script:CdpProc.Id -Force -ErrorAction SilentlyContinue }
    # Csak a saját (külön profilos) headless példány folyamatai
    Get-CimInstance Win32_Process -Filter "Name = 'msedge.exe'" | Where-Object { $_.CommandLine -like "*edge-cdp*" } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
}

# Oldal-váltás után megvárja, hogy az ÚJ oldalon a játék (PlayState) kész legyen (nagy pályáknál a fix várakozás kevés volt: ingadozó tesztek)
function Wait-Game($prev) {
    for ($i = 0; $i -lt 100; $i++) {
        Start-Sleep -Milliseconds 400
        try {
            $r = Send-Cdp "Runtime.evaluate" @{ expression = "(window.__navId && window.__navId !== $prev && window.__ps && window.__ps.player && window.__ps.data) ? 1 : 0"; returnByValue = $true }
            if ($r.result.result.value -eq 1) { Start-Sleep -Milliseconds 800; return }
        } catch {}
    }
}

function Send-Cdp($method, $params) {
    if ($method -eq "Page.navigate" -and -not $script:CdpWaiting) {
        $script:CdpWaiting = $true
        try {
            $pv = $null
            try { $rr = Send-Cdp "Runtime.evaluate" @{ expression = "window.__navId || 0"; returnByValue = $true }; $pv = $rr.result.result.value } catch {}
            if ($null -eq $pv) { $pv = 0 }
            $res = Send-Cdp $method $params
            Wait-Game $pv
            return $res
        } finally { $script:CdpWaiting = $false }
    }
    $script:CdpId++
    $id = $script:CdpId
    $json = @{ id = $id; method = $method; params = $params } | ConvertTo-Json -Depth 10 -Compress
    $bytes = [Text.Encoding]::UTF8.GetBytes($json)
    $script:CdpWs.SendAsync([ArraySegment[byte]]$bytes, [System.Net.WebSockets.WebSocketMessageType]::Text, $true, [Threading.CancellationToken]::None).Wait()
    while ($true) {
        $ms = New-Object IO.MemoryStream
        do {
            $buf = New-Object byte[] 65536
            $r = $script:CdpWs.ReceiveAsync([ArraySegment[byte]]$buf, [Threading.CancellationToken]::None).Result
            $ms.Write($buf, 0, $r.Count)
        } while (-not $r.EndOfMessage)
        $msg = [Text.Encoding]::UTF8.GetString($ms.ToArray()) | ConvertFrom-Json
        if ($msg.id -eq $id) { return $msg }
    }
}

# JS kiértékelése; az eredményt PowerShell-objektumként adja vissza, kivétel esetén hibát dob
function Js($expr) {
    $r = Send-Cdp "Runtime.evaluate" @{ expression = $expr; returnByValue = $true; awaitPromise = $true }
    if ($r.result.exceptionDetails) { throw ("JS kivétel: " + ($r.result.exceptionDetails | ConvertTo-Json -Depth 5 -Compress)) }
    return $r.result.result.value
}

function Key($type, $key, $code, $vk) {
    Send-Cdp "Input.dispatchKeyEvent" @{ type = $type; key = $key; code = $code; windowsVirtualKeyCode = $vk; nativeVirtualKeyCode = $vk } | Out-Null
}

function Shot($name) {
    $r = Send-Cdp "Page.captureScreenshot" @{ format = "png" }
    [IO.File]::WriteAllBytes((Join-Path $script:CdpOut $name), [Convert]::FromBase64String($r.result.data))
}
