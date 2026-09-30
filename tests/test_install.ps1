$ErrorActionPreference = "Stop"
$toolRoot = Split-Path -Parent $PSScriptRoot
$testDir = Join-Path ([System.IO.Path]::GetTempPath()) ("sleep-monitors " + [guid]::NewGuid().ToString())
$originalAppData = $env:APPDATA
$originalOS = $env:OS

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

# Substitute only the Windows COM boundary. Exercise real file generation and
# cleanup in a temporary directory without installing anything on this machine.
function New-Object {
    param([string]$ComObject)
    if ($ComObject -ne "WScript.Shell") { throw "Unexpected COM object: $ComObject" }
    $shell = [pscustomobject]@{}
    $shell | Add-Member ScriptMethod CreateShortcut {
        param($Path)
        $shortcut = [pscustomobject]@{
            Path = $Path
            TargetPath = ""
            Arguments = ""
            WorkingDirectory = ""
            Description = ""
            IconLocation = ""
        }
        $shortcut | Add-Member ScriptMethod Save {
            $this | ConvertTo-Json | Set-Content -LiteralPath $this.Path
        }
        return $shortcut
    }
    return $shell
}

try {
    $env:OS = "Windows_NT"
    $env:APPDATA = Join-Path $testDir "appdata"
    $toolsDir = Join-Path $testDir "tools"
    $programsDir = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs"
    New-Item -ItemType Directory -Path $toolsDir, $programsDir -Force | Out-Null
    $unrelatedPath = Join-Path $toolsDir "another-tool.bat"
    Set-Content -LiteralPath $unrelatedPath -Value "keep me"

    # Installing twice must keep the same launchers and leave other tools alone.
    foreach ($attempt in 1..2) {
        & (Join-Path $toolRoot "install.ps1") -ToolsDir $toolsDir -SkipPathUpdate
        $batPath = Join-Path $toolsDir "sleep-monitors.bat"
        $bat = Get-Content -LiteralPath $batPath -Raw
        Assert-True ($bat.Contains('"' + (Join-Path $toolRoot "sleep-monitors.ps1") + '" %*')) "CLI stub must quote this clone's script and forward arguments."
        Assert-True ($bat -match "powershell -NoProfile -ExecutionPolicy Bypass") "CLI stub must use PowerShell."
        Assert-True (@([System.IO.File]::ReadAllBytes($batPath) | Where-Object { $_ -gt 127 }).Count -eq 0) "BAT stub must be ASCII."
        $bash = Get-Content -LiteralPath (Join-Path $toolsDir "sleep-monitors") -Raw
        Assert-True ($bash.Contains('exec "$SCRIPT_DIR/sleep-monitors.bat" "$@"')) "Git Bash wrapper must forward arguments."

        foreach ($shortcutPath in @((Join-Path $toolsDir "Sleep Monitors.lnk"), (Join-Path $programsDir "Sleep Monitors.lnk"))) {
            $shortcut = Get-Content -LiteralPath $shortcutPath -Raw | ConvertFrom-Json
            Assert-True ($shortcut.TargetPath -eq "wscript.exe") "Shortcuts must use the silent VBS launcher."
            Assert-True ($shortcut.Arguments -eq ('"' + (Join-Path $toolRoot "sleep-monitors.vbs") + '"')) "Shortcut must quote this clone's launcher."
            Assert-True ($shortcut.WorkingDirectory -eq $toolRoot) "Shortcut must work from this clone."
            Assert-True ($shortcut.IconLocation -eq "%SystemRoot%\System32\imageres.dll,109") "Shortcut must retain its Windows icon."
        }
    }

    foreach ($attempt in 1..2) {
        & (Join-Path $toolRoot "uninstall.ps1") -ToolsDir $toolsDir
    }
    foreach ($path in @((Join-Path $toolsDir "sleep-monitors.bat"), (Join-Path $toolsDir "sleep-monitors"), (Join-Path $toolsDir "Sleep Monitors.lnk"), (Join-Path $programsDir "Sleep Monitors.lnk"))) {
        Assert-True (-not (Test-Path -LiteralPath $path)) "Uninstall left an installed artifact: $path"
    }
    Assert-True ((Get-Content -LiteralPath $unrelatedPath -Raw).Trim() -eq "keep me") "Uninstall must leave other tools alone."
    Write-Host "sleep-monitors installer tests passed" -ForegroundColor Green
} finally {
    $env:APPDATA = $originalAppData
    $env:OS = $originalOS
    if (Test-Path -LiteralPath $testDir) { Remove-Item -LiteralPath $testDir -Recurse -Force }
}
