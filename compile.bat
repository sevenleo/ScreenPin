@echo off
setlocal
cd /d "%~dp0"

echo [INFO] Closing all AutoHotkey instances...
taskkill /F /IM "AutoHotkey*" /T >nul 2>&1
taskkill /F /IM "ScreenPin.exe" /T >nul 2>&1

:: Paths - Relative to script directory
set "COMPILER=C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe"
set "BIN=C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"
set "IN=ScreenPin.ahk"
set "OUT=releases\ScreenPin.exe"
set "ICON=icon.ico"

echo [INFO] Preparing releases folder...
if not exist "releases" mkdir "releases"

if not exist "%COMPILER%" (
    echo [ERROR] Compiler not found: "%COMPILER%"
    pause
    exit /b 1
)
if not exist "%BIN%" (
    echo [ERROR] Base file not found: "%BIN%"
    pause
    exit /b 1
)
if not exist "%IN%" (
    echo [ERROR] Input script not found: "%IN%"
    pause
    exit /b 1
)
if not exist "%ICON%" (
    echo [ERROR] Icon not found: "%ICON%"
    pause
    exit /b 1
)

echo [INFO] Compiling ScreenPin (V2 Embedding Fix)...
"%COMPILER%" /in "%IN%" /out "%OUT%" /icon "%ICON%" /bin "%BIN%"

if errorlevel 1 (
    echo [ERROR] Compilation failed.
) else (
    echo.
    echo [SUCCESS] ScreenPin.exe created!
    echo.
    echo If it still asks for a .ahk file, please run Ahk2Exe.exe manually
    echo and select AutoHotkey64.exe v2 in the Base File dropdown.
)

pause
