$ErrorActionPreference = "Stop"

$DT = 0.001
$PHASE1_CAP_DIFF = 500.0 / 0.6  # 833.333...
$PHASE1_CAP_TIME = 100 * [Math]::Log(2)  # 69.3147...

Function CurrentTimeToDistance($targetDistance, $speedBonus, $birdSpeedMult) {
    $mult = $speedBonus * $birdSpeedMult
    $diffNeeded = $targetDistance / $mult
    if ($diffNeeded -le $PHASE1_CAP_DIFF) {
        return 100 * [Math]::Log(1 + $diffNeeded / 833.3333333333334)
    } else {
        $extraDiff = $diffNeeded - $PHASE1_CAP_DIFF
        # d(diff)/dt = 1000/60 = 50/3
        return $PHASE1_CAP_TIME + $extraDiff / (1000.0 / 60.0)
    }
}

Function NewTimeToDistance($targetDistance, $speedBonus, $birdSpeedMult) {
    $mult = $speedBonus * $birdSpeedMult
    $diffNeeded = $targetDistance / $mult
    $diff = 0.0
    $t = 0.0
    while ($diff -lt $diffNeeded) {
        $v = 500 + 725 * (1 - [Math]::Exp(-$diff / 3500.0))
        $diff += $v / 60.0 * $DT
        $t += $DT
    }
    return $t
}

Function FormatTime($seconds) {
    if ($seconds -lt 120) {
        return "$([Math]::Round($seconds))s"
    }
    $m = [Math]::Floor($seconds / 60)
    $s = [Math]::Round($seconds % 60)
    if ($s -eq 0) {
        return "${m}m"
    }
    return "${m}m ${s}s"
}

$scenarios = @(
    @{Name="Hornero"; BirdMult=1.0; SB=1.0; Mode="current"},
    @{Name="Tero"; BirdMult=1.4; SB=1.0; Mode="current"},
    @{Name="Carpintero"; BirdMult=0.9; SB=1.0; Mode="current"},
    @{Name="Hornero max upgrade"; BirdMult=1.0; SB=1.25; Mode="current"},
    @{Name="Tero max upgrade"; BirdMult=1.4; SB=1.25; Mode="current"},
    @{Name="Hornero new"; BirdMult=1.0; SB=1.0; Mode="new"},
    @{Name="Tero new"; BirdMult=1.4; SB=1.0; Mode="new"},
    @{Name="Carpintero new"; BirdMult=0.9; SB=1.0; Mode="new"}
)

$distances = @(500, 1000, 1500, 2000, 2500, 3000, 3500, 4000, 4500, 5000, 6000, 7000, 8000, 9000, 10000)

# Header
$header = "| Distancia | " + ($scenarios.Name -join " | ") + " |"
$sep = "|" + ("---" * ($scenarios.Count + 1)) + "|"

Write-Output $header
Write-Output $sep

foreach ($d in $distances) {
    $cells = @("${d}m")
    foreach ($s in $scenarios) {
        if ($s.Mode -eq "current") {
            $t = CurrentTimeToDistance $d $s.SB $s.BirdMult
        } else {
            $t = NewTimeToDistance $d $s.SB $s.BirdMult
        }
        $cells += (FormatTime $t)
    }
    Write-Output ("| " + ($cells -join " | ") + " |")
}

# Also print raw seconds
Write-Output "`n## Raw seconds`n"
$header2 = "| Distancia | " + ($scenarios.Name -join " | ") + " |"
Write-Output $header2
Write-Output $sep
foreach ($d in $distances) {
    $cells = @("${d}m")
    foreach ($s in $scenarios) {
        if ($s.Mode -eq "current") {
            $t = CurrentTimeToDistance $d $s.SB $s.BirdMult
        } else {
            $t = NewTimeToDistance $d $s.SB $s.BirdMult
        }
        $cells += ("{0:N2}" -f $t)
    }
    Write-Output ("| " + ($cells -join " | ") + " |")
}
