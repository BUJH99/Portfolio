param(
    [string]$ProjectRoot = "",
    [string]$AutomationRoot = $env:FPGA_AUTOMATION_ROOT,
    [decimal]$ClockPeriodNs = 10.000,
    [switch]$RunBuild,
    [switch]$SkipBuild,
    [switch]$Json
)

$ErrorActionPreference = 'Stop'

function Convert-ToNumber {
    param([object]$Value)

    if ($null -eq $Value) { return $null }
    $text = [string]$Value
    if ([string]::IsNullOrWhiteSpace($text)) { return $null }
    $number = 0.0
    if ([double]::TryParse($text, [System.Globalization.NumberStyles]::Float, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$number)) {
        return $number
    }
    return $null
}

function Read-JsonOrNull {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
}

function Get-CheckCount {
    param(
        [string]$Text,
        [string]$Name
    )

    if ([string]::IsNullOrEmpty($Text)) { return $null }
    $pattern = [regex]::Escape($Name) + '\s+\((\d+)\)'
    $match = [regex]::Match($Text, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    if (-not $match.Success) { return $null }
    return [int]$match.Groups[1].Value
}

function Get-UtilCount {
    param(
        [string]$Text,
        [string]$Name
    )

    if ([string]::IsNullOrEmpty($Text)) { return $null }
    $pattern = '\|\s*' + [regex]::Escape($Name) + '\*?\s*\|\s*(\d+)'
    $match = [regex]::Match($Text, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    if (-not $match.Success) { return $null }
    return [int]$match.Groups[1].Value
}

function Invoke-LoggedCommand {
    param(
        [string]$LogPath,
        [scriptblock]$Command
    )

    New-Item -ItemType Directory -Force -Path ([System.IO.Path]::GetDirectoryName($LogPath)) | Out-Null
    & $Command 2>&1 | Tee-Object -FilePath $LogPath | Out-Null
    return $LASTEXITCODE
}

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $ProjectRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
}
$ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path

if ([string]::IsNullOrWhiteSpace($AutomationRoot)) {
    throw 'Specify -AutomationRoot or FPGA_AUTOMATION_ROOT with the cloned FPGA_Auto_Project directory.'
}
$AutomationRoot = (Resolve-Path -LiteralPath $AutomationRoot).Path

$outputDir = Join-Path $ProjectRoot 'output'
$qorDir = Join-Path $outputDir 'qor'
$doctorBat = Join-Path $AutomationRoot 'templates\shared\adapters\bat\toolkit_doctor.bat'
$buildBat = Join-Path $AutomationRoot 'templates\contexts\vivado\adapters\bat\vivado_run_build_flow.bat'
$summaryPath = Join-Path $qorDir 'softmax_qor_summary.json'
$doctorLog = Join-Path $qorDir 'doctor.log'
$buildConsoleLog = Join-Path $qorDir 'vivado_build_console.log'
$vivadoBuildLog = Join-Path $ProjectRoot 'log\vivado_full_build.log'

New-Item -ItemType Directory -Force -Path $qorDir | Out-Null

if (-not (Test-Path -LiteralPath $doctorBat)) {
    throw "Toolkit Doctor not found: $doctorBat"
}

$doctorOutput = & $doctorBat $ProjectRoot '--json' 2>&1
$doctorText = ($doctorOutput | Out-String).Trim()
$doctorText | Set-Content -LiteralPath $doctorLog -Encoding UTF8
$doctorJson = $null
try {
    $jsonStart = $doctorText.IndexOf('{')
    if ($jsonStart -ge 0) {
        $doctorJson = $doctorText.Substring($jsonStart) | ConvertFrom-Json
    }
} catch {
    $doctorJson = $null
}

$buildRc = $null
if ($RunBuild -and -not $SkipBuild) {
    if (-not (Test-Path -LiteralPath $buildBat)) {
        throw "Vivado build flow not found: $buildBat"
    }
    $buildRc = Invoke-LoggedCommand -LogPath $buildConsoleLog -Command {
        & $buildBat $ProjectRoot '--no-pause'
    }
}

$reportDataPath = Join-Path $outputDir 'FINALReport\report_data.json'
$buildSummaryPath = Join-Path $outputDir 'build_summary.json'
$timingSummaryPath = Join-Path $outputDir 'reports\timing_summary.rpt'
$postPlaceUtilPath = Join-Path $outputDir 'reports\post_place_util.rpt'
$reportData = Read-JsonOrNull -Path $reportDataPath
$buildSummary = Read-JsonOrNull -Path $buildSummaryPath
$timingText = ''
if (Test-Path -LiteralPath $timingSummaryPath) {
    $timingText = Get-Content -LiteralPath $timingSummaryPath -Raw
}
$vivadoBuildLogText = ''
if (Test-Path -LiteralPath $vivadoBuildLog) {
    $vivadoBuildLogText = Get-Content -LiteralPath $vivadoBuildLog -Raw
}
$postPlaceUtilText = ''
if (Test-Path -LiteralPath $postPlaceUtilPath) {
    $postPlaceUtilText = Get-Content -LiteralPath $postPlaceUtilPath -Raw
}

$bitstreams = @()
if (Test-Path -LiteralPath $outputDir) {
    $bitstreams = @(Get-ChildItem -LiteralPath $outputDir -Recurse -Filter '*.bit' -File -ErrorAction SilentlyContinue |
        Sort-Object FullName |
        Select-Object -ExpandProperty FullName)
}

$wnsNs = Convert-ToNumber $reportData.timing.wns
$tnsNs = Convert-ToNumber $reportData.timing.tns
$whsNs = Convert-ToNumber $reportData.timing.whs
$thsNs = Convert-ToNumber $reportData.timing.ths
$powerW = Convert-ToNumber $reportData.power.total
$dynamicW = Convert-ToNumber $reportData.power.dynamic
$staticW = Convert-ToNumber $reportData.power.static
$lutUsed = Convert-ToNumber $reportData.utilization.lutsUsed
$ffUsed = Convert-ToNumber $reportData.utilization.regsUsed
$lutPerc = Convert-ToNumber $reportData.utilization.lutsPerc
$ffPerc = Convert-ToNumber $reportData.utilization.regsPerc
$dspUsed = Get-UtilCount -Text $postPlaceUtilText -Name 'DSPs'
$noClock = Get-CheckCount -Text $timingText -Name 'no_clock'
$noInputDelay = Get-CheckCount -Text $timingText -Name 'no_input_delay'
$noOutputDelay = Get-CheckCount -Text $timingText -Name 'no_output_delay'
$unconstrainedInternal = Get-CheckCount -Text $timingText -Name 'unconstrained_internal_endpoints'

$timingPass = ($null -ne $wnsNs -and $null -ne $tnsNs -and $wnsNs -ge 0.0 -and $tnsNs -eq 0.0)
$clockConstrained = ($noClock -eq 0 -and $unconstrainedInternal -eq 0)
$ioConstraintComplete = ($noInputDelay -eq 0 -and $noOutputDelay -eq 0)
$resourcePass = (($null -eq $lutUsed -or $lutUsed -le 2500) -and ($null -eq $ffUsed -or $ffUsed -le 800) -and ($null -eq $dspUsed -or $dspUsed -le 4))
$bitstreamPass = ($bitstreams.Count -gt 0)

$xdcFiles = @()
if (Test-Path -LiteralPath (Join-Path $ProjectRoot 'Constraints')) {
    $xdcFiles = @(Get-ChildItem -LiteralPath (Join-Path $ProjectRoot 'Constraints') -Recurse -Filter '*.xdc' -File |
        Sort-Object FullName |
        ForEach-Object { $_.FullName })
}

$doctorWarnings = @()
if ($doctorJson -and $doctorJson.warnings) {
    $doctorWarnings = @($doctorJson.warnings)
}

$drcErrors = @()
if ($vivadoBuildLogText -match 'DRC NSTD-1') {
    $drcErrors += 'NSTD-1: top-level ports have DEFAULT IOSTANDARD'
}
if ($vivadoBuildLogText -match 'DRC UCIO-1') {
    $drcErrors += 'UCIO-1: top-level ports have no PACKAGE_PIN/LOC constraint'
}
$resolvedTop = $null
if ($doctorJson -and $doctorJson.resolved -and $doctorJson.resolved.top) {
    $resolvedTop = $doctorJson.resolved.top
} elseif ($buildSummary -and $buildSummary.details.topModule) {
    $resolvedTop = $buildSummary.details.topModule
} elseif ($reportData -and $reportData.meta.topModule) {
    $resolvedTop = $reportData.meta.topModule
}

$summary = [ordered]@{
    schemaVersion = 1
    project = [ordered]@{
        name = 'SOFTMAX_ACC'
        root = $ProjectRoot
        automationRoot = $AutomationRoot
        top = $resolvedTop
        part = if ($buildSummary) { $buildSummary.details.partNumber } else { $null }
    }
    inputs = [ordered]@{
        clockPeriodNs = [double]$ClockPeriodNs
        xdcFiles = $xdcFiles
        reportDataPath = $reportDataPath
        buildSummaryPath = $buildSummaryPath
        timingSummaryPath = $timingSummaryPath
        vivadoBuildLog = $vivadoBuildLog
        doctorLog = $doctorLog
        buildConsoleLog = if (Test-Path -LiteralPath $buildConsoleLog) { $buildConsoleLog } else { '' }
    }
    metrics = [ordered]@{
        timing = [ordered]@{
            wnsNs = $wnsNs
            tnsNs = $tnsNs
            whsNs = $whsNs
            thsNs = $thsNs
            totalEndpoints = Convert-ToNumber $reportData.timing.totalEndpoints
        }
        power = [ordered]@{
            totalOnChipW = $powerW
            dynamicW = $dynamicW
            staticW = $staticW
            confidence = $reportData.power.confidence
        }
        utilization = [ordered]@{
            lutUsed = $lutUsed
            lutPercent = $lutPerc
            ffUsed = $ffUsed
            ffPercent = $ffPerc
            dspUsed = $dspUsed
            dspBudget = 4
            lutBudget = 2500
            ffBudget = 800
        }
        constraints = [ordered]@{
            noClock = $noClock
            unconstrainedInternalEndpoints = $unconstrainedInternal
            noInputDelay = $noInputDelay
            noOutputDelay = $noOutputDelay
        }
        artifacts = [ordered]@{
            bitstreamCount = $bitstreams.Count
            bitstreams = $bitstreams
            buildStatus = if ($buildSummary) { $buildSummary.status } else { $null }
            finalReportBuildStatus = $reportData.status.build
            doctorWarnings = $doctorWarnings
            drcErrors = $drcErrors
            buildRc = $buildRc
        }
    }
    gates = [ordered]@{
        internalTiming = [ordered]@{
            pass = $timingPass
            rule = 'WNS >= 0 ns and TNS == 0 ns'
        }
        clockConstraints = [ordered]@{
            pass = $clockConstrained
            rule = 'no_clock == 0 and unconstrained_internal_endpoints == 0'
        }
        ioConstraints = [ordered]@{
            pass = $ioConstraintComplete
            rule = 'no_input_delay == 0 and no_output_delay == 0'
            note = 'Expected to fail until board input/output delay constraints are added.'
        }
        resources = [ordered]@{
            pass = $resourcePass
            rule = 'LUT <= 2500, FF <= 800, and DSP <= 4'
        }
        bitstream = [ordered]@{
            pass = $bitstreamPass
            rule = 'At least one .bit artifact under output/'
            note = 'Requires real board PACKAGE_PIN/LOC and IOSTANDARD constraints; DRC severity is not downgraded.'
        }
    }
}

$summary | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $summaryPath -Encoding UTF8

if ($Json) {
    $summary | ConvertTo-Json -Depth 10
} else {
    Write-Host "SOFTMAX_ACC QoR summary"
    Write-Host "  WNS/TNS       : $wnsNs ns / $tnsNs ns"
    Write-Host "  LUT/FF        : $lutUsed / $ffUsed"
    Write-Host "  DSP           : $dspUsed"
    Write-Host "  Power         : $powerW W ($($reportData.power.confidence))"
    Write-Host "  Bitstreams    : $($bitstreams.Count)"
    Write-Host "  Timing gate   : $($summary.gates.internalTiming.pass)"
    Write-Host "  Clock gate    : $($summary.gates.clockConstraints.pass)"
    Write-Host "  I/O gate      : $($summary.gates.ioConstraints.pass)"
    Write-Host "  Summary JSON  : $summaryPath"
}
