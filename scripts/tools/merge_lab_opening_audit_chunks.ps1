param(
    [Parameter(Mandatory = $true)]
    [string[]]$LogPaths,
    [int]$ExpectedStartSeed = 243000,
    [int]$ExpectedSamples = 500,
    [int]$ExpectedBeamWidth = 512
)

$ErrorActionPreference = 'Stop'

$chunks = @()
$slotTotals = @{}
$totals = @{
    Samples = 0
    CoOffers = 0
    UniqueBest = 0
    Locked = 0
    NearBest = 0
}

foreach ($path in $LogPaths) {
    $text = Get-Content -LiteralPath $path -Raw
    $configMatches = [regex]::Matches(
        $text,
        'OPENING_COUNTERFACTUAL config start_seed=(\d+) samples=(\d+) beam_width=(\d+)'
    )
    $summaryMatches = [regex]::Matches(
        $text,
        'OPENING_COUNTERFACTUAL summary width=(\d+) co_offers=(\d+)/(\d+) experiment_unique_best=(\d+) \([^)]+\) non_experiment_locked=(\d+) \([^)]+\) non_experiment_near_best=(\d+) \([^)]+\) healthy_slots=(\d+)'
    )
    if ($configMatches.Count -ne 1 -or $summaryMatches.Count -ne 1) {
        throw "Incomplete or invalid audit chunk: $path"
    }
    $config = $configMatches[0]
    $summary = $summaryMatches[0]

    $startSeed = [int]$config.Groups[1].Value
    $samples = [int]$config.Groups[2].Value
    $beamWidth = [int]$config.Groups[3].Value
    if ($beamWidth -ne $ExpectedBeamWidth -or [int]$summary.Groups[1].Value -ne $ExpectedBeamWidth) {
        throw "Unexpected beam width in $path"
    }
    if ($samples -le 0 -or $samples -ne [int]$summary.Groups[3].Value) {
        throw "Config/summary sample mismatch in $path"
    }

    $coOffers = [int]$summary.Groups[2].Value
    $uniqueBest = [int]$summary.Groups[4].Value
    $locked = [int]$summary.Groups[5].Value
    $nearBest = [int]$summary.Groups[6].Value
    if (
        $coOffers -lt 0 -or $coOffers -gt $samples -or
        $uniqueBest -lt 0 -or $uniqueBest -gt $coOffers -or
        $locked -lt 0 -or $locked -gt $coOffers -or
        $nearBest -lt 0 -or $nearBest -gt $coOffers
    ) {
        throw "Invalid aggregate count relationship in $path"
    }

    $chunks += [pscustomobject]@{ Start = $startSeed; End = $startSeed + $samples; Path = $path }
    $totals.Samples += $samples
    $totals.CoOffers += $coOffers
    $totals.UniqueBest += $uniqueBest
    $totals.Locked += $locked
    $totals.NearBest += $nearBest

    $slotMatches = [regex]::Matches($text, 'OPENING_COUNTERFACTUAL slot=(\d+) near_best=(\d+)/(\d+)')
    if ($slotMatches.Count -ne 3) {
        throw "Expected exactly three audited slot rows in $path"
    }
    $chunkSlots = @{}
    foreach ($slotMatch in $slotMatches) {
        $slot = [int]$slotMatch.Groups[1].Value
        $near = [int]$slotMatch.Groups[2].Value
        $adapted = [int]$slotMatch.Groups[3].Value
        if (@(0, 2, 3) -notcontains $slot -or $chunkSlots.ContainsKey($slot)) {
            throw "Unexpected or duplicate audited slot $slot in $path"
        }
        if ($near -lt 0 -or $adapted -lt 0 -or $near -gt $adapted -or $adapted -gt $coOffers) {
            throw "Invalid slot count relationship for slot $slot in $path"
        }
        $chunkSlots[$slot] = $true
        if (-not $slotTotals.ContainsKey($slot)) {
            $slotTotals[$slot] = @{ Near = 0; Adapted = 0 }
        }
        $slotTotals[$slot].Near += $near
        $slotTotals[$slot].Adapted += $adapted
    }
}

$ordered = @($chunks | Sort-Object Start)
if (
    $ordered.Count -ne 5 -or
    $totals.Samples -ne $ExpectedSamples -or
    $ordered[0].Start -ne $ExpectedStartSeed
) {
    throw "Unexpected aggregate coverage"
}
foreach ($chunk in $ordered) {
    if ($chunk.End - $chunk.Start -ne 100) {
        throw "Every formal audit chunk must cover exactly 100 seeds"
    }
}
for ($index = 1; $index -lt $ordered.Count; $index++) {
    if ($ordered[$index - 1].End -ne $ordered[$index].Start) {
        throw "Audit chunks overlap or have a gap"
    }
}
if ($ordered[-1].End -ne $ExpectedStartSeed + $ExpectedSamples) {
    throw "Audit chunks do not reach the expected final seed"
}

function Get-Rate([int]$numerator, [int]$denominator) {
    if ($denominator -eq 0) { return 0.0 }
    return 100.0 * $numerator / $denominator
}

$healthySlots = 0
foreach ($slot in @(0, 2, 3)) {
    $entry = $slotTotals[$slot]
    if ($null -eq $entry) { continue }
    $rate = Get-Rate $entry.Near $entry.Adapted
    if ($entry.Adapted -gt 0 -and $rate -ge 10.0) {
        $healthySlots += 1
    }
    "OPENING_COUNTERFACTUAL merged_slot=$slot near_best=$($entry.Near)/$($entry.Adapted) ($([math]::Round($rate, 2))%)"
}

$uniqueRate = Get-Rate $totals.UniqueBest $totals.CoOffers
$lockedRate = Get-Rate $totals.Locked $totals.CoOffers
$nearRate = Get-Rate $totals.NearBest $totals.CoOffers
$structuralLock = $uniqueRate -ge 75.0 -and $lockedRate -ge 80.0
$healthy = $nearRate -ge 20.0 -and $healthySlots -ge 2

"OPENING_COUNTERFACTUAL merged_summary width=$ExpectedBeamWidth co_offers=$($totals.CoOffers)/$($totals.Samples) experiment_unique_best=$($totals.UniqueBest) ($([math]::Round($uniqueRate, 2))%) non_experiment_locked=$($totals.Locked) ($([math]::Round($lockedRate, 2))%) non_experiment_near_best=$($totals.NearBest) ($([math]::Round($nearRate, 2))%) healthy_slots=$healthySlots structural_lock=$structuralLock healthy=$healthy"
