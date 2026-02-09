@echo off
setlocal
cd /d "%~dp0"

echo [INFO] Closing all AutoHotkey instances...
taskkill /F /IM "AutoHotkey*" /T >nul 2>&1
taskkill /F /IM "ScreenPin.exe" /T >nul 2>&1

:: Paths - Exactly as the tutorial Option A
set "COMPILER=C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe"
set "BIN=C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"
set "IN=D:\GITHUB\ScreenPin\ScreenPin.ahk"
set "OUT=D:\GITHUB\ScreenPin\releases\ScreenPin.exe"
set "ICON=D:\GITHUB\ScreenPin\icon.ico"

echo [INFO] Preparing releases folder...
if not exist "releases" mkdir "releases"

echo [INFO] Compiling ScreenPin (V2 Embedding Fix)...
"%COMPILER%" /in "%IN%" /out "%OUT%" /icon "%ICON%" /bin "%BIN%"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo [SUCCESS] ScreenPin.exe created!
    echo.
    echo If it still asks for a .ahk file, please run Ahk2Exe.exe manually 
    echo and select 'AutoHotkey64.exe' (v2) in the 'Base File' dropdown.
) else (
    echo [ERROR] Compilation failed.
)

pause
