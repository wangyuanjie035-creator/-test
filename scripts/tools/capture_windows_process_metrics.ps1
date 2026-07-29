param(
    [Parameter(Mandatory = $true)]
    [int]$ProcessId,
    [int]$Samples = 10,
    [int]$IntervalSeconds = 1
)

$ErrorActionPreference = 'Stop'
if ($Samples -lt 1 -or $IntervalSeconds -lt 1) {
    throw 'Samples and IntervalSeconds must both be positive.'
}

$process = Get-Process -Id $ProcessId -ErrorAction Stop
$gpuSet = Get-Counter -ListSet 'GPU Process Memory' -ErrorAction SilentlyContinue
$gpuPaths = @()
if ($gpuSet) {
    $gpuPaths = @($gpuSet.PathsWithInstances | Where-Object { $_ -match "pid_$($ProcessId)_" })
}

$records = @()
for ($index = 0; $index -lt $Samples; $index++) {
    $process.Refresh()
    $dedicatedGpu = 0.0
    $localGpu = 0.0
    if ($gpuPaths.Count -gt 0) {
        $gpuReading = Get-Counter -Counter $gpuPaths -MaxSamples 1 -ErrorAction SilentlyContinue
        if ($gpuReading) {
            $gpuSamples = $gpuReading.CounterSamples
            $dedicatedGpu = ($gpuSamples | Where-Object { $_.Path -match '\\dedicated usage$' } | Measure-Object CookedValue -Sum).Sum
            $localGpu = ($gpuSamples | Where-Object { $_.Path -match '\\local usage$' } | Measure-Object CookedValue -Sum).Sum
        }
    }
    $records += [pscustomobject]@{
        Timestamp = [DateTimeOffset]::Now.ToString('o')
        WorkingSetBytes = [int64]$process.WorkingSet64
        PrivateBytes = [int64]$process.PrivateMemorySize64
        Handles = [int]$process.HandleCount
        Threads = [int]$process.Threads.Count
        DedicatedGpuBytes = [int64]$dedicatedGpu
        LocalGpuBytes = [int64]$localGpu
    }
    if ($index + 1 -lt $Samples) {
        Start-Sleep -Seconds $IntervalSeconds
    }
}

$summary = [pscustomobject]@{
    ProcessId = $ProcessId
    ProcessName = $process.ProcessName
    Samples = $Samples
    WorkingSetMinBytes = [int64](($records | Measure-Object WorkingSetBytes -Minimum).Minimum)
    WorkingSetMaxBytes = [int64](($records | Measure-Object WorkingSetBytes -Maximum).Maximum)
    PrivateMinBytes = [int64](($records | Measure-Object PrivateBytes -Minimum).Minimum)
    PrivateMaxBytes = [int64](($records | Measure-Object PrivateBytes -Maximum).Maximum)
    DedicatedGpuMaxBytes = [int64](($records | Measure-Object DedicatedGpuBytes -Maximum).Maximum)
    LocalGpuMaxBytes = [int64](($records | Measure-Object LocalGpuBytes -Maximum).Maximum)
    HandleMin = [int](($records | Measure-Object Handles -Minimum).Minimum)
    HandleMax = [int](($records | Measure-Object Handles -Maximum).Maximum)
    ThreadMin = [int](($records | Measure-Object Threads -Minimum).Minimum)
    ThreadMax = [int](($records | Measure-Object Threads -Maximum).Maximum)
}

[pscustomobject]@{ Summary = $summary; Records = $records } | ConvertTo-Json -Depth 5
