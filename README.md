# ![](icons/sleep-monitors.png) sleep-monitors

Turn all your monitors off without putting the PC to sleep

Windows

<!-- media: hero -->
<!-- ![sleep-monitors](docs/hero.png) -->
<!-- /media: hero -->

## What it is

This just turns off all the connected monitors while the PC keeps running. Move
the mouse or press a key and they come back on.

The Start menu shortcut waits 5 seconds before doing it, otherwise the key press
you launched it with wakes them straight back up.

## Get it

Paste this into your AI coding agent (Claude Code, Codex, Cursor...):

> Clone https://github.com/mikecann/sleep-monitors and make it my own. It's one of Mike
> Cann's personal tools, so read the README first, change anything specific to his
> setup to suit mine, then help me get it running.

### Or set it up by hand

You'll need Windows, Git and Windows PowerShell 5.1, which comes with Windows.
There are no API keys, `.env` settings or extra dependencies to install.

```powershell
git clone https://github.com/mikecann/sleep-monitors.git
cd sleep-monitors
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

The installer writes launchers into `C:\dev\tools` and offers to add that folder
to your user PATH if needed. It also creates a **Sleep Monitors** shortcut there
and in the Start Menu. Keep the clone where it is, the launchers point to its files.
If you move it, run the installer again from the new location.

Open a new terminal after installing. For a different launcher folder, pass
`-ToolsDir C:\your\tools`. Use `-SkipPathUpdate` if you manage PATH yourself.

## Using it

Find **Sleep Monitors** in Windows Search to launch it silently. You can also
pin the shortcut in `C:\dev\tools` to the taskbar.

From a terminal:

```powershell
sleep-monitors
sleep-monitors -DelaySeconds 5
sleep-monitors -DelaySeconds 0 -DryRun
```

The command waits 3 seconds by default. `-DelaySeconds` accepts 0 to 60 seconds.
`-DryRun` checks the interop setup and writes a log without turning off displays.

You can run it directly from the clone too:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\sleep-monitors.ps1
```

## Troubleshooting

If the shortcut does nothing, check the log:

```powershell
Get-Content "$env:LOCALAPPDATA\sleep-monitors\sleep-monitors.log" -Tail 20
```

If the monitors wake straight away, wait for the shortcut's 5-second delay before
touching the mouse or keyboard. The script uses Windows' normal monitor power
message, the PC keeps running throughout.

## Uninstalling

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\uninstall.ps1
```

If you installed with `-ToolsDir`, pass the same folder when uninstalling. This
removes the command, Git Bash wrapper and two shortcuts. It leaves your logs,
clone and the shared tools folder and PATH entry in place.

## Development

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests\test_sleep_monitors.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tests\test_install.ps1
```

The tests check the dry run, logging, silent launcher and installation contracts
without sleeping displays. On macOS, run them with `pwsh -NoProfile -File`.
Real monitor sleep and wake-up still need checking on Windows with connected displays.

## Assets

`docs/header.webp` is a generated raster banner for the public site.
`icons/sleep-monitors.png` is the tool's monitor icon.

## More tools

You can find my other tools at [mikerosoft.app](https://mikerosoft.app).

MIT licensed.
