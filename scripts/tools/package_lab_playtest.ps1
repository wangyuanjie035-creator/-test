param(
    [Parameter(Mandatory = $true)]
    [string]$GodotPath,
    [string]$Version = '0.1.0',
    [switch]$SkipExport
)

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$outputRoot = Join-Path $projectRoot 'build\windows'
$distributionRoot = Join-Path $projectRoot 'dist'
$executable = Join-Path $outputRoot 'LabEngine.exe'
$pack = Join-Path $outputRoot 'LabEngine.pck'
$readme = Join-Path $projectRoot 'docs\playtest\PLAYTEST_README.txt'
$archive = Join-Path $distributionRoot "LabEngine-Playtest-$Version-Windows-x86_64.zip"
$checksum = "$archive.sha256"
$smokeRoot = Join-Path $projectRoot '.temp\playtest-package-smoke'

if (-not $SkipExport) {
    & (Join-Path $PSScriptRoot 'export_lab_windows.ps1') -GodotPath $GodotPath
    if ($LASTEXITCODE -ne 0) {
        throw 'Release export failed; playtest package was not created.'
    }
}

foreach ($required in @($executable, $pack, $readme)) {
    if (-not (Test-Path -LiteralPath $required)) {
        throw "Required package file is missing: $required"
    }
}

New-Item -ItemType Directory -Force -Path $distributionRoot | Out-Null
foreach ($oldArtifact in @($archive, $checksum)) {
    if (Test-Path -LiteralPath $oldArtifact) {
        Remove-Item -LiteralPath $oldArtifact -Force
    }
}

Compress-Archive -LiteralPath @($executable, $pack, $readme) -DestinationPath $archive -CompressionLevel Optimal
$hash = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant()
Set-Content -LiteralPath $checksum -Value "$hash  $([IO.Path]::GetFileName($archive))" -Encoding ascii

$smokeDirectory = Join-Path $smokeRoot ([Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $smokeDirectory | Out-Null
Expand-Archive -LiteralPath $archive -DestinationPath $smokeDirectory
$smokeExecutable = Join-Path $smokeDirectory 'LabEngine.exe'
$smokeLog = Join-Path $smokeDirectory 'clean-start.log'
$smokeProcess = Start-Process -FilePath $smokeExecutable -ArgumentList @(
    '--headless',
    '--quit-after', '5',
    '--log-file', $smokeLog
) -Wait -PassThru -NoNewWindow
if ($smokeProcess.ExitCode -ne 0) {
    throw "Extracted playtest build failed to start cleanly (exit $($smokeProcess.ExitCode))."
}
if (Select-String -LiteralPath $smokeLog -Pattern @('SCRIPT ERROR', 'ERROR:') -SimpleMatch -Quiet) {
    throw "Extracted playtest build reported a Godot error: $smokeLog"
}

Write-Host "LAB_PLAYTEST_PACKAGE: PASS: $archive"
Write-Host "LAB_PLAYTEST_SHA256: $hash"
Write-Host "LAB_PLAYTEST_CLEAN_START: PASS: $smokeDirectory"
exit 0
