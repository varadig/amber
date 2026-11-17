# Statikus ellenőrzés a Tiled-pályákon (levels/level*.tmj), böngésző nélkül.
#   powershell -ExecutionPolicy Bypass -File tests/validate-levels.ps1
# Ellenőrzi: JSON, 16 px-es csempe, 56 sor, solid + platforms réteg, Spawn és Door, ismert objektumosztályok, a Part-ok száma, az épületek ajtópárjai, a kapuk azonosítói.
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$known = "Spawn", "Door", "Checkpoint", "Gem", "Heart", "Battery", "Spike", "Cracked", "Crumble", "Grate", "Crate", "Cell", "Gate", "Plate", "Lever", "Switch", "Socket", "Key", "PowerCell", "Bench", "Terminal", "Mover", "Enemy", "Part", "Text", "BuildingRoom", "BuildingDoor", "Decor"
$errors = 0; $warnings = 0
function Err($f, $m) { Write-Host "ERROR  $f : $m" -ForegroundColor Red; $script:errors++ }
function Warn($f, $m) { Write-Host "WARN   $f : $m" -ForegroundColor Yellow; $script:warnings++ }
function Layers($ls) { foreach ($l in $ls) { if ($l.type -eq "group") { Layers $l.layers } else { $l } } }

$files = Get-ChildItem (Join-Path $root "levels") -Filter "level*.tmj"
if (-not $files) { Err "levels" "nincs pályafájl (futtasd: scripts/generate-levels.ps1)"; exit 1 }
foreach ($f in $files) {
    $n = $f.Name
    try { $m = Get-Content $f.FullName -Raw -Encoding UTF8 | ConvertFrom-Json } catch { Err $n "érvénytelen JSON: $($_.Exception.Message)"; continue }
    if ($m.orientation -ne "orthogonal") { Err $n "csak orthogonal támogatott" }
    if ($m.tilewidth -ne 16 -or $m.tileheight -ne 16) { Err $n "a csempe 16x16 kell legyen" }
    if ($m.height -ne 56) { Err $n "a magasság 56 sor kell legyen (most $($m.height))" }
    $layers = @(Layers $m.layers)
    foreach ($ln in "solid", "platforms") {
        $l = $layers | Where-Object { $_.type -eq "tilelayer" -and $_.name -eq $ln }
        if (-not $l) { Err $n "hiányzik a(z) '$ln' csemperéteg" }
        elseif ($l.data -isnot [array]) { Err $n "a(z) '$ln' réteg nem CSV kódolású (Tile Layer Format: CSV)" }
        elseif ($l.data.Count -ne $m.width * $m.height) { Err $n "a(z) '$ln' réteg mérete nem egyezik" }
    }
    $objs = @($layers | Where-Object { $_.type -eq "objectgroup" } | ForEach-Object { $_.objects })
    $cls = @{}
    foreach ($o in $objs) {
        $c = if ($o.class) { $o.class } elseif ($o.type) { $o.type } else { "" }
        if (-not $c) { Warn $n "osztály nélküli objektum (id $($o.id)): állítsd be a Class mezőt"; continue }
        if ($known -notcontains $c) { Warn $n "ismeretlen osztály: $c (id $($o.id))" }
        $cls[$c] = 1 + [int]$cls[$c]
        if ($o.x -lt 0 -or $o.x -gt $m.width * 16 -or $o.y -lt 0 -or $o.y -gt $m.height * 16 + 32) { Warn $n "a pályán kívüli objektum: $c (id $($o.id))" }
    }
    if ($cls["Spawn"] -ne 1) { Err $n "pontosan egy Spawn kell (van: $($cls['Spawn']))" }
    if ($cls["Door"] -ne 1) { Err $n "pontosan egy Door kell (van: $($cls['Door']))" }
    if (-not $cls["Part"]) { Warn $n "nincs Part: nincs mit gyűjteni" }
    # ajtók: azonosító (id) + cél (target), vagy a régi páros (azonos room, inside=true/false)
    $doors = @($objs | Where-Object { ($_.class -eq "BuildingDoor") -or ($_.type -eq "BuildingDoor") })
    $dprops = @{}
    foreach ($d in $doors) { $p = @{}; foreach ($q in $d.properties) { $p[$q.name] = $q.value }; $dprops[$d.id] = $p }
    $ids = @($dprops.Values | Where-Object { $_.id -gt 0 } | ForEach-Object { $_.id })
    foreach ($d in $doors) {
        $p = $dprops[$d.id]
        if ($p.target -gt 0) {
            if ($ids -notcontains $p.target) { Err $n "a(z) $($p.id). BuildingDoor célja ($($p.target)) nem létezik" }
        }
        elseif (-not ($doors | Where-Object { $_.id -ne $d.id -and $dprops[$_.id].room -eq $p.room -and $dprops[$_.id].inside -ne $p.inside })) {
            Err $n "a BuildingDoor (id $($d.id), room $($p.room)) nem visz sehova: adj meg 'target'-et (a célajtó 'id'-ja), vagy párosítsd (azonos 'room', másik 'inside')"
        }
    }
    if ($cls["BuildingRoom"] -and -not $doors.Count) { Warn $n "van BuildingRoom, de nincs BuildingDoor: nem lehet belépni" }
    Write-Host ("OK     {0}: {1}x{2}, {3} objektum" -f $n, $m.width, $m.height, $objs.Count) -ForegroundColor DarkGray
}
Write-Host "`n$errors hiba, $warnings figyelmeztetés" -ForegroundColor $(if ($errors) { "Red" } else { "Green" })
exit $(if ($errors) { 1 } else { 0 })
