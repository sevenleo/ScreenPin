@echo off
REM ================================
REM AutoHotkey v2 – Build Script
REM ================================

REM === CONFIGURAÇÃO ===
set AHK2_EXE="C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"
set AHK2_COMPILER="C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe"

REM Script de entrada (.ahk)
set SRC="D:\GITHUB\ScreenPin\ScreenPin.ahk"

REM Saída (.exe)
set OUT="D:\GITHUB\ScreenPin\releases\ScreenPin.exe"

REM ================================
REM COMPILAÇÃO
REM ================================

%AHK2_COMPILER% ^
  /in %SRC% ^
  /out %OUT% ^
  /bin %AHK2_EXE%

if errorlevel 1 (
    echo.
    echo ❌ ERRO NA COMPILACAO
    pause
    exit /b 1
)

echo.
echo ✅ COMPILACAO CONCLUIDA COM SUCESSO
pause
