# Közös segédfüggvények a szkriptekhez és a tesztekhez: Windows (Windows PowerShell 5.1 / pwsh) és macOS / Linux (pwsh) alatt is működnek.
# Használat: . "$PSScriptRoot/common.ps1"   (a tests/cdp-lib.ps1 magától betölti)
# Útvonalakban mindig perjelet (/) használj: a Windows is elfogadja, a macOS-en a fordított perjel a .NET-nek és a külső programoknak fájlnév-karakter.

$script:OnWindows = ($PSVersionTable.PSEdition -eq "Desktop") -or $IsWindows
$script:OnMac = [bool]$IsMacOS
# (dot-source-olva is ennek a fájlnak a mappája a $PSScriptRoot: scripts/)
$script:AmberRoot = Split-Path -Parent $PSScriptRoot

# A Haxe-környezet: Windowson a HaxeToolkit (ha a PATH-on nincs), macOS-en a szokásos telepítési helyek (~/.local/bin, Homebrew)
function Set-HaxeEnv {
    if ($script:OnWindows) {
        if (-not $env:HAXEPATH -and (Test-Path "C:/HaxeToolkit/haxe")) { $env:HAXEPATH = "C:\HaxeToolkit\haxe" }
        if (-not $env:NEKO_INSTPATH -and (Test-Path "C:/HaxeToolkit/neko")) { $env:NEKO_INSTPATH = "C:\HaxeToolkit\neko" }
        if (-not (Get-Command haxelib -ErrorAction SilentlyContinue) -and (Test-Path "C:/HaxeToolkit/haxe")) { $env:Path = "C:\HaxeToolkit\haxe;C:\HaxeToolkit\neko;$env:Path" }
    } else {
        foreach ($d in @("$HOME/.local/bin", "$HOME/.local/node/bin", "/opt/homebrew/bin", "/usr/local/bin")) {
            if ((Test-Path $d) -and (($env:PATH -split ":") -notcontains $d)) { $env:PATH = "${d}:$env:PATH" }
        }
    }
}
Set-HaxeEnv

# A PowerShell, amelyik most fut (a gyerek-szkriptek is ezzel indulnak: Windowson powershell.exe / pwsh, macOS-en pwsh)
function Get-PsExe { return (Get-Process -Id $PID).Path }

# Gyerek-szkript futtatása ugyanazzal a PowerShell-lel; a kimenetét (sorok) adja vissza, a $LASTEXITCODE megmarad
function Invoke-Ps([string]$File) {
    $exe = Get-PsExe
    if ($script:OnWindows) { & $exe -NoProfile -ExecutionPolicy Bypass -File $File @args }
    else { & $exe -NoProfile -File $File @args }
}

# Node: a PATH-on lévő, különben a lime-mal érkező (Windows)
function Get-Node {
    $c = Get-Command node -ErrorAction SilentlyContinue
    if ($c) { return $c.Source }
    if ($script:OnWindows) {
        $lime = (& haxelib libpath lime 2>$null)
        if ($lime) {
            $n = Join-Path $lime.Trim() "templates/bin/node/node-windows.exe"
            if (Test-Path $n) { return $n }
        }
    }
    throw "Node nem található (telepítsd: https://nodejs.org)."
}

# A fejlesztői szerver (scripts/devserver.js) indítása a háttérben az export/html5/bin mappához; a folyamatot adja vissza
function Start-DevServer([int]$Port, [string]$Dir = "") {
    if (-not $Dir) { $Dir = Join-Path $script:AmberRoot "export/html5/bin" }
    $node = Get-Node
    $argList = @("`"$(Join-Path $script:AmberRoot 'scripts/devserver.js')`"", "`"$Dir`"", "$Port")
    if ($script:OnWindows) { $p = Start-Process $node -ArgumentList $argList -PassThru -WindowStyle Hidden }
    else { $p = Start-Process $node -ArgumentList $argList -PassThru -RedirectStandardOutput "/dev/null" }
    Start-Sleep -Seconds 2
    return $p
}

# Fejnélküli Chromium-böngésző a tesztekhez: AMBER_BROWSER környezeti változó, különben Edge, Chrome, Brave, Chromium
function Get-Browser {
    if ($env:AMBER_BROWSER -and (Test-Path $env:AMBER_BROWSER)) { return $env:AMBER_BROWSER }
    if ($script:OnWindows) {
        $c = @("${env:ProgramFiles(x86)}/Microsoft/Edge/Application/msedge.exe", "$env:ProgramFiles/Microsoft/Edge/Application/msedge.exe",
            "$env:ProgramFiles/Google/Chrome/Application/chrome.exe", "${env:ProgramFiles(x86)}/Google/Chrome/Application/chrome.exe",
            "$env:ProgramFiles/BraveSoftware/Brave-Browser/Application/brave.exe", "$env:LOCALAPPDATA/Google/Chrome/Application/chrome.exe")
    } elseif ($script:OnMac) {
        $c = @()
        foreach ($base in @("/Applications", "$HOME/Applications")) {
            $c += "$base/Microsoft Edge.app/Contents/MacOS/Microsoft Edge", "$base/Google Chrome.app/Contents/MacOS/Google Chrome",
                "$base/Brave Browser.app/Contents/MacOS/Brave Browser", "$base/Chromium.app/Contents/MacOS/Chromium"
        }
    } else {
        $c = @("microsoft-edge", "google-chrome", "chromium", "chromium-browser", "brave-browser") | ForEach-Object { (Get-Command $_ -ErrorAction SilentlyContinue).Source }
    }
    foreach ($p in $c) { if ($p -and (Test-Path $p)) { return $p } }
    throw "Nem található Chromium-alapú böngésző (Edge / Chrome / Brave / Chromium); megadható: AMBER_BROWSER=<útvonal>."
}

# A megadott profilmappát használó böngésző-folyamatok leállítása (a fejnélküli tesztpéldány gyerekfolyamatai is)
function Stop-BrowserProfile([string]$Marker) {
    if ($script:OnWindows) {
        Get-CimInstance Win32_Process -Filter "Name = 'msedge.exe' OR Name = 'chrome.exe' OR Name = 'brave.exe'" -ErrorAction SilentlyContinue |
            Where-Object { $_.CommandLine -like "*$Marker*" } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
    } else {
        & pkill -f -- $Marker 2>$null | Out-Null
    }
}

# URL / fájl megnyitása az alapértelmezett programmal
function Open-Path([string]$Target) {
    if ($script:OnWindows) { Start-Process $Target }
    elseif ($script:OnMac) { & open $Target }
    else { & xdg-open $Target }
}

# A gép IPv4-címei a helyi hálózaton (telefonos teszthez)
function Get-LanAddresses {
    [System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() |
        Where-Object { $_.OperationalStatus -eq "Up" } |
        ForEach-Object { $_.GetIPProperties().UnicastAddresses } |
        Where-Object { $_.Address.AddressFamily -eq "InterNetwork" } |
        ForEach-Object { $_.Address.ToString() } |
        Where-Object { $_ -notlike "127.*" -and $_ -notlike "169.254.*" } | Select-Object -Unique
}

# A porton figyelő folyamatok azonosítói
function Get-ListenPids([int]$Port) {
    if ($script:OnWindows) {
        return @(Get-NetTCPConnection -State Listen -LocalPort $Port -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess -Unique)
    }
    return @((& lsof -nP -ti "tcp:$Port" -sTCP:LISTEN 2>$null) | Where-Object { $_ } | ForEach-Object { [int]$_ } | Select-Object -Unique)
}

# Zip készítése a mappa TARTALMÁBÓL (a fájlok a zip gyökerébe kerülnek, perjeles útvonalakkal)
function New-ZipFromDir([string]$Dir, [string]$Zip) {
    if (Test-Path $Zip) { Remove-Item $Zip -Force }
    if ($script:OnWindows) {
        & "$env:SystemRoot\System32\tar.exe" -a -c -f $Zip -C $Dir *
    } else {
        Push-Location $Dir
        try { & zip -qr -X $Zip . } finally { Pop-Location }
    }
    if ($LASTEXITCODE -ne 0) { throw "A csomagolás nem sikerült: $Zip" }
}
