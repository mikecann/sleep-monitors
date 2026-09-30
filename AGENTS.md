# Agent guidance for sleep-monitors

This Windows PowerShell tool turns off connected monitors while the PC keeps
running. Source and launchers live at the repo root. `install.ps1` creates
command stubs and shortcuts pointing to this clone.

## Working on the tool

- Keep all source here. `C:\dev\tools` gets generated stubs and shortcuts only.
- Never commit large `.exe` or `.dll` files. If external binaries are added,
  keep them in `C:\dev\tools` and accept `EXEDIR` with a launcher-directory fallback.
- Use test-first development for non-trivial changes. Write or update the
  automated test first, then implement the change until it passes. Extract a
  test seam first if needed.
- When behaviour, logging, startup or another tested contract changes, update
  the expectations and rerun the relevant tests.
- Test before committing. Run both scripts in `tests/`, then smoke-test on
  Windows with PowerShell and `wscript.exe .\sleep-monitors.vbs`. Check exit codes.
  The real launcher sleeps displays, so verify wake-up with keyboard or mouse.
- Use the VBS launcher with window style 0 for Start Menu and taskbar shortcuts.
  Launching PowerShell directly from a shortcut can flash a console window.
- Write `.bat` stubs with `-Encoding ASCII`. Avoid curly quotes and non-ASCII
  punctuation in launcher commands.
- Re-run `install.ps1` when changing installation or moving the clone. Ordinary
  script edits need no reinstall because launchers point to the live source.
- Keep uninstall limited to this tool's launchers. Leave shared PATH entries,
  directories and other tools' launchers alone.
- If dependencies are added, put their checks in a root `deps.ps1` and call it
  from `install.ps1`. Make it self-contained and idempotent, with clear output.
  For large manual downloads, check and explain what is missing instead of
  downloading binaries automatically.

## Checks

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests\test_sleep_monitors.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tests\test_install.ps1
```

On macOS, use `pwsh -NoProfile -File` for the same test scripts. The dry-run test
never calls user32, and installer tests mock Windows shortcut COM calls while
checking real temporary files. CI parses every `.ps1` and runs the tests on Windows.

## Writing

- Use plain, friendly language and first person for Mike's opinions.
- No em dashes or en dashes.
- PR descriptions start with `## Why`, explaining what prompted the change.
