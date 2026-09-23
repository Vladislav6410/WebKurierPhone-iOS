$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$pilotRoot = Split-Path -Parent $PSScriptRoot

function Assert-Pilot($Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
}

$table = Get-Content -Raw -LiteralPath (Join-Path $pilotRoot 'Resources/Localizations/Copilot.strings')
$matches = [regex]::Matches($table, '(?m)^"([^"]+)"\s*=\s*"(?:[^"\\]|\\.)*";\s*$')
$keys = @($matches | ForEach-Object { $_.Groups[1].Value })
Assert-Pilot ($keys.Count -eq (@($keys | Sort-Object -Unique)).Count) 'Duplicate localization keys'
$nonComments = [regex]::Replace($table, '/\*[\s\S]*?\*/', '').Trim()
$remaining = [regex]::Replace($nonComments, '(?m)^"([^"]+)"\s*=\s*"(?:[^"\\]|\\.)*";\s*$', '').Trim()
Assert-Pilot ($remaining.Length -eq 0) 'Malformed Copilot.strings entry'

$sources = @(Get-ChildItem -LiteralPath (Join-Path $pilotRoot 'App/Pilot') -Filter '*.swift')
$sources += @(Get-ChildItem -LiteralPath (Join-Path $pilotRoot 'App/PilotCore') -Filter '*.swift')
foreach ($source in $sources) {
    $content = Get-Content -Raw -LiteralPath $source.FullName
    foreach ($match in [regex]::Matches($content, '"(pilot\.[a-zA-Z0-9.]+)"')) {
        Assert-Pilot ($keys -contains $match.Groups[1].Value) "Missing localization: $($match.Groups[1].Value)"
    }
    Assert-Pilot ($content -notmatch 'https?://|URLSession|api[_-]?key\s*=|gh[pousr]_[A-Za-z0-9]{20}') "Unexpected network URL/client/credential in $($source.Name)"
}

foreach ($index in @('00','01','02','03','04','05','06','07')) {
    foreach ($field in @('title','task')) {
        Assert-Pilot ($keys -contains "pilot.lesson.$index.$field") "Missing lesson $index $field"
    }
}
foreach ($type in @('intro','theory','practice')) {
    Assert-Pilot ($keys -contains "pilot.lesson.type.$type") "Missing lesson type localization: $type"
}
foreach ($status in @('available','current','completed')) {
    Assert-Pilot ($keys -contains "pilot.status.$status") "Missing state localization: $status"
}

$core = Get-Content -Raw -LiteralPath (Join-Path $pilotRoot 'App/PilotCore/PilotCourse.swift')
foreach ($id in @(
    'wk01-l00-intro',
    'wk01-l01-computer-system',
    'wk01-l02-os-input-output',
    'wk01-l03-files-terminal',
    'wk01-l04-hardware-usb',
    'wk01-l05-engineering-method',
    'wk01-l06-practice-device-internals',
    'wk01-l07-practice-telebridge'
)) {
    Assert-Pilot ($core -match [regex]::Escape($id)) "Missing canonical lesson id: $id"
}
Assert-Pilot (([regex]::Matches($core, 'driveFileID: "')).Count -eq 8) 'Expected exactly eight pilot Drive file IDs'

$spec = Get-Content -Raw -LiteralPath (Join-Path $pilotRoot 'project.yml')
foreach ($match in [regex]::Matches($spec, '(?m)^\s+- path: (.+)$')) {
    Assert-Pilot (Test-Path -LiteralPath (Join-Path $pilotRoot $match.Groups[1].Value.Trim())) "Missing target source: $($match.Groups[1].Value)"
}
Assert-Pilot ($spec -match 'PILOT_MVP') 'Pilot compilation flag missing'
Assert-Pilot ($spec -notmatch 'path: App\s*$|path: App/Scenes|path: App/Services\s*$') 'Legacy sources included in pilot target'
Assert-Pilot ($spec -notmatch 'PILOT_PROJECT_SITE_URL') 'Unverified default website URL configured'
Write-Output "PASS: 8-lesson Drive pilot resource/source checks ($($keys.Count) localization keys); Swift not compiled."
