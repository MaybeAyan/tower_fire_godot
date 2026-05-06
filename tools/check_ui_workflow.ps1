$ErrorActionPreference = "Stop"
if (Get-Variable PSNativeCommandUseErrorActionPreference -ErrorAction SilentlyContinue) {
    $PSNativeCommandUseErrorActionPreference = $false
}

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $projectRoot

Write-Host "UI workflow check for: $projectRoot"

$requiredPaths = @(
    "scenes\Main.tscn",
    "scenes\UiPreview.tscn",
    "scenes\ui\BattleHudRoot.tscn",
    "scenes\ui\BattleOverlayRoot.tscn",
    "scenes\ui\ChapterFlowRoot.tscn",
    "scripts\ui\BattleHudRoot.gd",
    "scripts\ui\BattleOverlayRoot.gd",
    "scripts\ui\ChapterFlowRoot.gd",
    "scripts\tools\UiPreview.gd",
    "docs\ui_authoring_workflow.md",
    "assets\ui\glass_tactics_theme.tres"
)

foreach ($relativePath in $requiredPaths) {
    $fullPath = Join-Path $projectRoot $relativePath
    if (-not (Test-Path $fullPath)) {
        throw "Missing required UI workflow artifact: $relativePath"
    }
}

function Test-Port {
    param(
        [string]$HostName,
        [int]$Port
    )

    $test = Test-NetConnection -ComputerName $HostName -Port $Port -WarningAction SilentlyContinue
    [PSCustomObject]@{
        Host = $HostName
        Port = $Port
        Open = [bool]$test.TcpTestSucceeded
    }
}

$ports = @(
    (Test-Port -HostName "localhost" -Port 5301),
    (Test-Port -HostName "localhost" -Port 5302)
)

foreach ($portResult in $ports) {
    $status = if ($portResult.Open) { "open" } else { "closed" }
    Write-Host ("Port {0}:{1} is {2}" -f $portResult.Host, $portResult.Port, $status)
}

Write-Host "Running project checks..."
powershell -ExecutionPolicy Bypass -File (Join-Path $projectRoot "tools\check_all.ps1")

Write-Host "UI workflow check passed."
