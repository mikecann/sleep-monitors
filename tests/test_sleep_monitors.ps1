$ErrorActionPreference = "Stop"

$toolRoot = Split-Path -Parent $PSScriptRoot
$scriptPath = Join-Path $toolRoot "sleep-monitors.ps1"
$vbsPath = Join-Path $toolRoot "sleep-monitors.vbs"
$installPath = Join-Path $toolRoot "install.ps1"

if (-not (Test-Path $scriptPath)) {
    throw "Missing sleep-monitors.ps1"
}

if (-not (Test-Path $vbsPath)) {
    throw "Missing sleep-monitors.vbs"
}

# Keep test logs separate from the user's real logs on both Windows and macOS.
$originalLocalAppData = $env:LOCALAPPDATA
$testDir = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString())
$env:LOCALAPPDATA = $testDir
$logPath = Join-Path (Join-Path $testDir "sleep-monitors") "sleep-monitors.log"
$powerShell = (Get-Process -Id $PID).Path

try {

    $output = & $powerShell -NoProfile -ExecutionPolicy Bypass -File $scriptPath -DelaySeconds 0 -DryRun 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Dry run failed with exit code $LASTEXITCODE`n$output"
    }

    $outputText = $output | Out-String
    if ($outputText -notmatch "Dry run") {
        throw "Dry run output did not make it clear that no monitor sleep message was sent.`n$outputText"
    }

    $logText = Get-Content $logPath -Raw
    if ($logText -notmatch "Starting DelaySeconds=0 DryRun=True" -or $logText -notmatch "Dry run complete") {
        throw "Dry run should write a useful log entry.`n$logText"
    }

    $vbsText = Get-Content $vbsPath -Raw
    if ($vbsText -notmatch "WindowStyle Hidden" -or $vbsText -notmatch "sleep-monitors\.ps1" -or $vbsText -notmatch "DelaySeconds 5") {
        throw "VBS launcher should run sleep-monitors.ps1 hidden."
    }

    $installText = Get-Content $installPath -Raw
    if ($installText -notmatch 'Write-BatStub "sleep-monitors"' -or $installText -notmatch "Sleep Monitors\.lnk") {
        throw "install.ps1 should install the sleep-monitors PATH stub and shortcut."
    }

    Write-Host "sleep-monitors tests passed" -ForegroundColor Green
} finally {
    $env:LOCALAPPDATA = $originalLocalAppData
    if (Test-Path $testDir) {
        Remove-Item -LiteralPath $testDir -Recurse -Force
    }
}
