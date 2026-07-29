param(
    [Parameter(Mandatory = $true)]
    [string]$GodotPath
)

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$logRoot = Join-Path $projectRoot '.temp'
New-Item -ItemType Directory -Force -Path $logRoot | Out-Null
$checks = @(
	@{ Name = 'compile'; Arguments = @('--headless', '--path', $projectRoot, '--log-file', (Join-Path $logRoot 'gate-compile.log'), '--quit') },
	@{ Name = 'unit'; Arguments = @('--headless', '--path', $projectRoot, '--log-file', (Join-Path $logRoot 'gate-unit.log'), '--script', 'res://scripts/tools/run_lab_tests.gd') },
	@{ Name = 'golden'; Arguments = @('--headless', '--path', $projectRoot, '--log-file', (Join-Path $logRoot 'gate-golden.log'), '--script', 'res://scripts/tools/validate_lab_engine.gd') },
	@{ Name = 'scene-smoke'; Arguments = @('--headless', '--path', $projectRoot, '--log-file', (Join-Path $logRoot 'gate-scene-smoke.log'), '--script', 'res://scripts/tools/smoke_lab_main_scene.gd') },
	@{ Name = 'phase12-recorder-smoke'; Arguments = @('--headless', '--path', $projectRoot, '--log-file', (Join-Path $logRoot 'gate-phase12-recorder-smoke.log'), '--script', 'res://scripts/tools/smoke_phase12_blind_recorder.gd') },
	@{ Name = 'layout-smoke'; Arguments = @('--headless', '--path', $projectRoot, '--log-file', (Join-Path $logRoot 'gate-layout-smoke.log'), '--script', 'res://scripts/tools/smoke_lab_responsive_layout.gd') },
	@{ Name = 'stability-smoke'; Arguments = @('--headless', '--path', $projectRoot, '--log-file', (Join-Path $logRoot 'gate-stability-smoke.log'), '--script', 'res://scripts/tools/smoke_lab_stability.gd') },
	@{ Name = 'strategy-diversity'; Arguments = @('--headless', '--path', $projectRoot, '--log-file', (Join-Path $logRoot 'gate-strategy-diversity.log'), '--script', 'res://scripts/tools/audit_lab_strategy_diversity.gd') }
)

$failed = $false
foreach ($check in $checks) {
    # The Mono editor executable can return control to PowerShell before the
    # spawned headless process has fully exited when another editor instance is
    # open.  Waiting on the concrete process prevents gate stages from
    # overlapping and racing on the real profile/settings files.
    $stdoutPath = Join-Path $logRoot "gate-$($check.Name)-stdout.log"
    $stderrPath = Join-Path $logRoot "gate-$($check.Name)-stderr.log"
    $process = Start-Process `
        -FilePath $GodotPath `
        -ArgumentList @($check.Arguments) `
        -WindowStyle Hidden `
        -RedirectStandardOutput $stdoutPath `
        -RedirectStandardError $stderrPath `
        -PassThru
    # Accessing Handle before WaitForExit makes ExitCode available reliably in
    # Windows PowerShell 5.1 when output is redirected.
    $null = $process.Handle
    $process.WaitForExit()
    $exitCode = $process.ExitCode
    $stdoutText = if (Test-Path -LiteralPath $stdoutPath) {
        Get-Content -LiteralPath $stdoutPath -Raw
    }
    else {
        ''
    }
    $stderrText = if (Test-Path -LiteralPath $stderrPath) {
        Get-Content -LiteralPath $stderrPath -Raw
    }
    else {
        ''
    }
    $text = $stdoutText + [Environment]::NewLine + $stderrText
    $godotLogPath = $check.Arguments[4]
    $godotLogText = if (Test-Path -LiteralPath $godotLogPath) {
        Get-Content -LiteralPath $godotLogPath -Raw
    }
    else {
        ''
    }
    $combinedText = $text + [Environment]::NewLine + $godotLogText
    $hasScriptError = $combinedText -match '(?m)^(SCRIPT ERROR:|ERROR:|Failed to load (script|resource))'
    if ($exitCode -ne 0 -or $hasScriptError) {
        Write-Host "LAB_GATE: FAIL: $($check.Name)"
        Write-Host $combinedText
        $failed = $true
    }
    else {
        Write-Host "LAB_GATE: PASS: $($check.Name)"
    }
}

if ($failed) {
    exit 1
}

Write-Host 'LAB_GATE: PASS: all checks'
exit 0
