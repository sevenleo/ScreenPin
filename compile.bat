@echo off
setlocal
cd /d "%~dp0"

echo [INFO] Closing all AutoHotkey instances...
taskkill /F /IM "AutoHotkey*" /T >nul 2>&1
taskkill /F /IM "ScreenPin.exe" /T >nul 2>&1

rem Resolve AutoHotkey base dir from registry, fallback to default install
set "AHK_DIR="
for /f "tokens=2,*" %%A in ('reg query "HKLM\SOFTWARE\AutoHotkey" /v InstallDir 2^>nul') do set "AHK_DIR=%%B"
if not defined AHK_DIR for /f "tokens=2,*" %%A in ('reg query "HKLM\SOFTWARE\WOW6432Node\AutoHotkey" /v InstallDir 2^>nul') do set "AHK_DIR=%%B"
if not defined AHK_DIR set "AHK_DIR=C:\Program Files\AutoHotkey"
if defined AHK_DIR if "%AHK_DIR:~-1%"=="\" set "AHK_DIR=%AHK_DIR:~0,-1%"

rem ponytail: HKLM-only lookup; per-user installs use the default-path fallback below
set "COMPILER=%AHK_DIR%\Compiler\Ahk2Exe.exe"
set "BIN=%AHK_DIR%\v2\AutoHotkey64.exe"
set "IN=ScreenPin.ahk"
set "OUT=releases\ScreenPin.exe"
set "ICON=icon.ico"

echo [INFO] Using AutoHotkey dir: "%AHK_DIR%"

echo [INFO] Preparing releases folder...
if not exist "releases" mkdir "releases"

if not exist "%COMPILER%" goto :missing_compiler
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
    pause
    exit /b 1
)
echo.
echo [SUCCESS] ScreenPin.exe created!
echo.
echo If it still asks for a .ahk file, please run Ahk2Exe.exe manually
echo and select AutoHotkey64.exe v2 in the Base File dropdown.
pause
exit /b 0

:missing_compiler
echo [ERROR] Compiler not found: "%COMPILER%"
echo [INFO] Opening AutoHotkey dash so you can install Ahk2Exe
echo Please install Ahk2Exe via dash, then run compile.bat again
set "USE_DASH_EXE=%AHK_DIR%\UX\AutoHotkeyUX.exe"
set "USE_DASH_AHK=%AHK_DIR%\UX\ui-dash.ahk"
if not exist "%USE_DASH_EXE%" set "USE_DASH_EXE=C:\Program Files\AutoHotkey\UX\AutoHotkeyUX.exe"
if not exist "%USE_DASH_AHK%" set "USE_DASH_AHK=C:\Program Files\AutoHotkey\UX\ui-dash.ahk"
if not exist "%USE_DASH_EXE%" goto :no_dash
if not exist "%USE_DASH_AHK%" goto :no_dash
start "" "%USE_DASH_EXE%" "%USE_DASH_AHK%"
echo [INFO] Dash opened. Install Ahk2Exe, then run compile.bat again.
pause
exit /b 1

:no_dash
echo [ERROR] Dash not found. Please install AutoHotkey v2 manually from autohotkey.com
echo Then run compile.bat again.
pause
exit /b 1
