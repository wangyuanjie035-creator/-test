param(
    [Parameter(Mandatory = $true)]
    [string]$GodotPath,
    [switch]$SkipGate
)

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$logRoot = Join-Path $projectRoot '.temp'
$outputRoot = Join-Path $projectRoot 'build\windows'
$executable = Join-Path $outputRoot 'LabEngine.exe'
$pack = Join-Path $outputRoot 'LabEngine.pck'
$exportLog = Join-Path $logRoot 'windows-export-console.log'
$godotExportLog = Join-Path $logRoot 'windows-export-godot.log'
$packAuditZip = Join-Path $logRoot 'windows-export-pack-audit.zip'
$packAuditLog = Join-Path $logRoot 'windows-export-pack-audit.log'
$smokeLog = Join-Path $logRoot 'windows-export-smoke.log'

New-Item -ItemType Directory -Force -Path $logRoot, $outputRoot | Out-Null

if (-not $SkipGate) {
    & (Join-Path $PSScriptRoot 'run_lab_gate.ps1') -GodotPath $GodotPath
    if ($LASTEXITCODE -ne 0) {
        throw 'Lab gate failed; Windows export was not attempted.'
    }
}

foreach ($artifact in @($executable, $pack, $packAuditZip)) {
    if (Test-Path -LiteralPath $artifact) {
        Remove-Item -LiteralPath $artifact -Force
    }
}

$previousErrorPreference = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
$exportOutput = & $GodotPath `
    --headless `
    --path $projectRoot `
    --log-file $godotExportLog `
    --export-release 'Windows Desktop' `
    $executable 2>&1
$exportExitCode = $LASTEXITCODE
$ErrorActionPreference = $previousErrorPreference
$exportOutput | Set-Content -Path $exportLog -Encoding utf8
if ($exportExitCode -ne 0) {
    $exportOutput | Write-Host
    throw 'Godot Windows release export failed.'
}

if (-not (Test-Path -LiteralPath $executable) -or -not (Test-Path -LiteralPath $pack)) {
    throw 'Godot reported success but the EXE or PCK artifact is missing.'
}

function Get-BlockingGodotErrors([string[]]$Paths) {
    $matches = Select-String -Path $Paths -Pattern '^(SCRIPT ERROR:|ERROR:|Failed to load (script|resource))'
    return @($matches | Where-Object { $_.Line -notmatch '^ERROR: \.NET Sdk not found\.' })
}

$exportErrors = Get-BlockingGodotErrors -Paths @($exportLog, $godotExportLog)
if ($exportErrors.Count -gt 0) {
    $exportErrors | Write-Host
    throw 'Godot logged a blocking error while exporting the Windows release.'
}

$ErrorActionPreference = 'Continue'
$packAuditOutput = & $GodotPath `
    --headless `
    --path $projectRoot `
    --log-file $packAuditLog `
    --export-pack 'Windows Desktop' `
    $packAuditZip 2>&1
$packAuditExitCode = $LASTEXITCODE
$ErrorActionPreference = $previousErrorPreference
if ($packAuditExitCode -ne 0) {
    $packAuditOutput | Write-Host
    throw 'Godot failed to generate the auditable release ZIP.'
}
$packAuditErrors = Get-BlockingGodotErrors -Paths @($packAuditLog)
if ($packAuditErrors.Count -gt 0) {
    $packAuditErrors | Write-Host
    throw 'Godot logged a blocking error while generating the auditable release ZIP.'
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [IO.Compression.ZipFile]::OpenRead($packAuditZip)
try {
    $packEntries = @($zip.Entries | ForEach-Object { $_.FullName })
}
finally {
    $zip.Dispose()
}
$forbiddenEntryPattern = '^(addons/|tests/|docs/|scripts/(tools|battle|data|overworld|research_chain|run|ui)/|scripts/lab_engine/(tools|shadow)/|data/(bosses|campus|cards|decks|encounters|events|route_node_hints)/|scenes/(battle_test_scene\.tscn|campus_overworld_scene\.tscn|research_chain/))'
$developmentLeaks = @($packEntries | Where-Object { $_ -match $forbiddenEntryPattern })
if ($developmentLeaks.Count -gt 0) {
    $developmentLeaks | Write-Host
    throw 'Development-only or out-of-scope content exists in the release pack.'
}

Set-Content -Path $smokeLog -Value '' -Encoding utf8
& $executable --headless --quit-after 5 --log-file $smokeLog
if ($LASTEXITCODE -ne 0) {
    throw 'Exported Windows build failed its independent startup smoke test.'
}
$runtimeErrors = Select-String -Path $smokeLog -Pattern '(?m)^(SCRIPT ERROR:|ERROR:|Failed to load (script|resource))'
if ($runtimeErrors) {
    $runtimeErrors | Write-Host
    throw 'Exported Windows build logged a runtime error.'
}

$exeSize = (Get-Item -LiteralPath $executable).Length
$packSize = (Get-Item -LiteralPath $pack).Length
Write-Host "LAB_WINDOWS_EXPORT: PASS: entries=$($packEntries.Count) EXE=$exeSize bytes PCK=$packSize bytes"
exit 0
