# Changelog

## 1.2.0
-c Portable compile with dash fallback
- `compile.bat` resolves the AutoHotkey install dir from `HKLM\SOFTWARE\AutoHotkey\InstallDir`, falling back to `C:\Program Files\AutoHotkey` when unreadable.
- When `Ahk2Exe` is missing, `compile.bat` opens the AutoHotkey dash (resolved dir first, default path second) and asks to re-run after installing.
- Fixed batch failures: LF-only line endings, parentheses inside `if/else` blocks, fragile `%ERRORLEVEL%` check.
- Executable version set to 1.2.0.
