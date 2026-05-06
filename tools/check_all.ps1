$ErrorActionPreference = "Stop"
if (Get-Variable PSNativeCommandUseErrorActionPreference -ErrorAction SilentlyContinue) {
    $PSNativeCommandUseErrorActionPreference = $false
}

function Resolve-Godot {
    if ($env:GODOT_BIN -and (Test-Path $env:GODOT_BIN)) {
        return $env:GODOT_BIN
    }

    $command = Get-Command godot -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }

    $candidate = Get-ChildItem -Path "E:\" -Recurse -Filter "Godot*_console.exe" -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -like "*Godot_v4.6*" } |
        Select-Object -First 1
    if ($candidate) {
        return $candidate.FullName
	}

    throw "Godot executable not found. Set GODOT_BIN to Godot_v4.6.2-stable_win64_console.exe."
}

$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$godot = Resolve-Godot

Write-Host "Using Godot: $godot"
$logRoot = Join-Path $projectRoot ".godot"
New-Item -ItemType Directory -Force -Path $logRoot | Out-Null
$previousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = "Continue"
& $godot --headless --log-file (Join-Path $logRoot "validate_project_data.log") --path $projectRoot --script "res://tools/validate_project_data.gd" 2> (Join-Path $logRoot "validate_project_data.stderr.log")
$validateExitCode = $LASTEXITCODE
& $godot --headless --log-file (Join-Path $logRoot "run_state_checks.log") --path $projectRoot --script "res://tools/run_state_checks.gd" 2> (Join-Path $logRoot "run_state_checks.stderr.log")
$stateChecksExitCode = $LASTEXITCODE
& $godot --headless --log-file (Join-Path $logRoot "check_layout_sanity.log") --path $projectRoot --script "res://tools/check_layout_sanity.gd" 2> (Join-Path $logRoot "check_layout_sanity.stderr.log")
$layoutChecksExitCode = $LASTEXITCODE
$startupErrorPath = Join-Path $logRoot "startup_check.stderr.log"
$startupOutput = & $godot --headless --log-file (Join-Path $logRoot "startup_check.log") --path $projectRoot --quit 2> $startupErrorPath
$startupExitCode = $LASTEXITCODE
$ErrorActionPreference = $previousErrorActionPreference
if ($validateExitCode -ne 0) {
    throw "Project data validation failed."
}
if ($stateChecksExitCode -ne 0) {
    throw "State checks failed."
}
if ($layoutChecksExitCode -ne 0) {
    throw "Layout sanity checks failed."
}
$startupOutput = @($startupOutput) + @(Get-Content $startupErrorPath -ErrorAction SilentlyContinue)
$startupOutput = $startupOutput | ForEach-Object { $_.ToString() } | Where-Object {
    $_ -notmatch "Failed to read the root certificate store" -and
    $_ -notmatch "get_system_ca_certificates" -and
    $_ -notmatch "NativeCommandError" -and
    $_ -notmatch "CategoryInfo" -and
    $_ -notmatch "FullyQualifiedErrorId" -and
    $_ -notmatch "tools\\check_all.ps1" -and
    $_ -notmatch "^\+ " -and
    $_ -notmatch "^\s*~+"
}
$startupOutput | ForEach-Object { Write-Host $_ }
if ($startupExitCode -ne 0 -or ($startupOutput -match "SCRIPT ERROR|Parse Error|Compile Error|ERROR:")) {
    throw "Godot startup check failed."
}

Write-Host "All checks passed."
