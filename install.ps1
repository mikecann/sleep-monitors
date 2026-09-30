[CmdletBinding()]
param(
    [string]$ToolsDir = "C:\dev\tools",
    [switch]$SkipPathUpdate
)

$ErrorActionPreference = "Stop"
if ($env:OS -ne "Windows_NT") {
    throw "sleep-monitors can only be installed on Windows."
}

$RepoDir = $PSScriptRoot
. (Join-Path $RepoDir "install-lib.ps1")
New-Item -ItemType Directory -Path $ToolsDir -Force | Out-Null

# Share the tools directory with other standalone tools without replacing PATH.
if (-not $SkipPathUpdate) {
    $machinePath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    $userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
    if (-not $userPath) { $userPath = "" }
    $onPath = ($machinePath -split ";") + ($userPath -split ";") |
        Where-Object { $_.TrimEnd("\") -ieq $ToolsDir.TrimEnd("\") }
    if (-not $onPath) {
        $answer = Read-Host "Add '$ToolsDir' to your User PATH? [Y/n]"
        if ($answer -eq "" -or $answer -imatch "^y") {
            $newUserPath = ($userPath.TrimEnd(";") + ";$ToolsDir").TrimStart(";")
            [System.Environment]::SetEnvironmentVariable("Path", $newUserPath, "User")
            $env:PATH += ";$ToolsDir"
            Write-Host "Added '$ToolsDir' to User PATH. Open a new terminal to use sleep-monitors." -ForegroundColor Green
        } else {
            Write-Host "Add '$ToolsDir' to PATH manually to use sleep-monitors by name." -ForegroundColor Yellow
        }
    }
}

$sleepMonitorsScriptPath = Join-Path $RepoDir "sleep-monitors.ps1"
Write-BatStub "sleep-monitors" @"
@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "$sleepMonitorsScriptPath" %*
"@ -ToolsDir $ToolsDir

$sleepMonitorsVbsPath = Join-Path $RepoDir "sleep-monitors.vbs"
$startMenuDir = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs"
New-Item -ItemType Directory -Path $startMenuDir -Force | Out-Null
$shortcutPaths = @(
    (Join-Path $ToolsDir "Sleep Monitors.lnk"),
    (Join-Path $startMenuDir "Sleep Monitors.lnk")
)
$shell = New-Object -ComObject WScript.Shell
foreach ($shortcutPath in $shortcutPaths) {
    $shortcut = $shell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = "wscript.exe"
    $shortcut.Arguments = "`"$sleepMonitorsVbsPath`""
    $shortcut.WorkingDirectory = $RepoDir
    $shortcut.Description = "Turn off all monitors until keyboard or mouse input wakes them"
    $shortcut.IconLocation = "%SystemRoot%\System32\imageres.dll,109"
    $shortcut.Save()
    Write-Host "  [lnk]  $shortcutPath" -ForegroundColor Green
}

Write-Host "Installed sleep-monitors. Keep this clone in place; the launchers point to it." -ForegroundColor Green
