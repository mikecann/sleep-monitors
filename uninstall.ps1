[CmdletBinding()]
param(
    [string]$ToolsDir = "C:\dev\tools"
)

$ErrorActionPreference = "Stop"
if ($env:OS -ne "Windows_NT") {
    throw "sleep-monitors can only be uninstalled on Windows."
}

# Remove only our four launchers. PATH, logs and other tools remain intact.
$paths = @(
    (Join-Path $ToolsDir "sleep-monitors.bat"),
    (Join-Path $ToolsDir "sleep-monitors"),
    (Join-Path $ToolsDir "Sleep Monitors.lnk"),
    (Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\Sleep Monitors.lnk")
)
foreach ($path in $paths) {
    if (Test-Path -LiteralPath $path) {
        Remove-Item -LiteralPath $path -Force
        Write-Host "Removed $path" -ForegroundColor Green
    }
}
