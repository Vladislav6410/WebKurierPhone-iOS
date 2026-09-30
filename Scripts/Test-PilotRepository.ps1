$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$pilotRoot = Split-Path -Parent $PSScriptRoot

function Assert-Pilot($Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
}

# Resource/source integration checks, not substitutes for compiling Swift/XCTest.
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
foreach ($day in 1..3) {
    foreach ($field in @('title', 'task')) {
        Assert-Pilot ($keys -contains "pilot.day.$day.$field") "Missing day $day $field"
    }
}
foreach ($status in @('available', 'current', 'completed')) {
    Assert-Pilot ($keys -contains "pilot.status.$status") "Missing state localization: $status"
}
$spec = Get-Content -Raw -LiteralPath (Join-Path $pilotRoot 'project.yml')
foreach ($match in [regex]::Matches($spec, '(?m)^\s+- path: (.+)$')) {
    Assert-Pilot (Test-Path -LiteralPath (Join-Path $pilotRoot $match.Groups[1].Value.Trim())) "Missing target source: $($match.Groups[1].Value)"
}
Assert-Pilot ($spec -match 'PILOT_MVP') 'Pilot compilation flag missing'
Assert-Pilot ($spec -notmatch 'path: App\s*$|path: App/Scenes|path: App/Services\s*$') 'Legacy sources included in pilot target'
Assert-Pilot ($spec -notmatch 'PILOT_PROJECT_SITE_URL') 'Unverified default website URL configured'
Write-Output "PASS: pilot resource/source checks ($($keys.Count) localization keys); Swift not compiled."
