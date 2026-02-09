#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

; =====================================================
; CONFIGURAÇÃO
; =====================================================
MaxDesktops := 0    ; Será definido dinamicamente
UnpinDelayMs := 300 ; Delay para estabilidade (opcional)

; =====================================================
; ESTADO GLOBAL
; =====================================================
FixedMonitorIndex := 0
Ready := false
MonitorCount := 0
hVDA := 0

; Ponteiros da DLL
pGetDesktopCount := 0
pGoToDesktopNumber := 0
pGetCurrentDesktopNumber := 0
pMoveWindowToDesktopNumber := 0
pGetWindowDesktopNumber := 0

SelectGui := ""

; =====================================================
; CARREGAMENTO DA DLL
; =====================================================
LoadVDA() {
    global hVDA, pGetDesktopCount, pGoToDesktopNumber, pGetCurrentDesktopNumber, pMoveWindowToDesktopNumber, pGetWindowDesktopNumber, MaxDesktops

    VDA_PATH := A_ScriptDir . "\VirtualDesktopAccessor.dll"

    if !FileExist(VDA_PATH) {
        MsgBox "VirtualDesktopAccessor.dll não encontrada: " . VDA_PATH
        ExitApp
    }

    hVDA := DllCall("kernel32.dll\LoadLibrary", "Str", VDA_PATH, "Ptr")

    if (!hVDA) {
        MsgBox "Erro ao carregar DLL. Código: " . A_LastError
        ExitApp
    }

    pGetDesktopCount := DllCall("kernel32.dll\GetProcAddress", "Ptr", hVDA, "AStr", "GetDesktopCount", "Ptr")
    pGoToDesktopNumber := DllCall("kernel32.dll\GetProcAddress", "Ptr", hVDA, "AStr", "GoToDesktopNumber", "Ptr")
    pGetCurrentDesktopNumber := DllCall("kernel32.dll\GetProcAddress", "Ptr", hVDA, "AStr", "GetCurrentDesktopNumber", "Ptr")
    pMoveWindowToDesktopNumber := DllCall("kernel32.dll\GetProcAddress", "Ptr", hVDA, "AStr", "MoveWindowToDesktopNumber", "Ptr")
    pGetWindowDesktopNumber := DllCall("kernel32.dll\GetProcAddress", "Ptr", hVDA, "AStr", "GetWindowDesktopNumber", "Ptr")

    if (!pGetDesktopCount || !pGoToDesktopNumber || !pGetCurrentDesktopNumber || !pMoveWindowToDesktopNumber) {
        MsgBox "Falha ao obter endereços das funções na DLL."
        ExitApp
    }

    MaxDesktops := DllCall(pGetDesktopCount, "Int")
}

; =====================================================
; GUI DE SELEÇÃO DO MONITOR FIXO
; =====================================================
ShowSelectGui() {
    global SelectGui, MonitorCount, FixedMonitorIndex, Ready

    MonitorCount := MonitorGetCount()
    
    SelectGui := Gui("+AlwaysOnTop", "Desktop Per Monitor")
    SelectGui.SetFont("s10")

    SelectGui.AddText("w340 Center",
        "Qual monitor deve permanecer FIXO" "`n"
        "durante a troca de desktops?"
    )

    SelectGui.AddText("w340 Center cGray",
        "Configurações > Exibição > Identificar"
    )

    SelectGui.AddText("h12")

    btnWidth := 70
    spacing := 10

    Loop MonitorCount {
        btn := SelectGui.AddButton(
            "w" btnWidth " h35 x" (spacing + (A_Index-1)*(btnWidth+spacing)),
            A_Index
        )
        btn.OnEvent("Click", OnMonitorButtonClick)
    }

    SelectGui.AddText("x10 y+15 h10") ; Spacer

    btnNone := SelectGui.AddButton(
        "w" (btnWidth * 2) " h35 x100",
        "Nenhum"
    )
    btnNone.OnEvent("Click", OnNoneButtonClick)

    SelectGui.Show("AutoSize Center")
}

OnMonitorButtonClick(ctrl, *) {
    global FixedMonitorIndex, Ready, SelectGui
    FixedMonitorIndex := Integer(ctrl.Text)
    Ready := true
    SelectGui.Destroy()
}

OnNoneButtonClick(*) {
    global FixedMonitorIndex, Ready, SelectGui
    FixedMonitorIndex := 0
    Ready := true
    SelectGui.Destroy()
}

; =====================================================
; LÓGICA DE GEOMETRIA DE JANELAS
; =====================================================
IsWindowOnFixedMonitor(hwnd) {
    global FixedMonitorIndex
    if (FixedMonitorIndex = 0)
        return false

    try {
        ; Obter coordenadas do monitor fixo
        MonitorGet(FixedMonitorIndex, &L, &T, &R, &B)
        
        ; Obter posição da janela
        WinGetPos(&X, &Y, &W, &H, hwnd)
        
        ; Calcular ponto central da janela
        midX := X + (W / 2)
        midY := Y + (H / 2)
        
        ; Verificar se o centro está dentro do monitor
        return (midX >= L && midX <= R && midY >= T && midY <= B)
    } catch {
        return false
    }
}

; =====================================================
; DESKTOP TOGGLE (ESTRATÉGIA DE MOVIMENTAÇÃO)
; =====================================================
ToggleDesktop(direction := 1) {
    global Ready, MaxDesktops, pGetCurrentDesktopNumber, pGoToDesktopNumber, pMoveWindowToDesktopNumber, FixedMonitorIndex

    if (!Ready || MaxDesktops < 2)
        return

    current := DllCall(pGetCurrentDesktopNumber, "Int")
    target := direction > 0 ? Mod(current + 1, MaxDesktops) : Mod(current - 1 + MaxDesktops, MaxDesktops)

    ; Se houver monitor fixo, movemos as janelas dele para o target ANTES de mudar
    if (FixedMonitorIndex > 0) {
        windows := WinGetList()
        for hwnd in windows {
            if IsWindowOnFixedMonitor(hwnd) {
                ; Move a janela para o desktop de destino
                DllCall(pMoveWindowToDesktopNumber, "Ptr", hwnd, "Int", target)
            }
        }
    }

    ; Muda o desktop
    DllCall(pGoToDesktopNumber, "Int", target)
}

; =====================================================
; INICIALIZAÇÃO
; =====================================================
LoadVDA()
ShowSelectGui()

; =====================================================
; HOTKEYS
; =====================================================
; Ctrl + Win + Setas (Sobrescrevendo nativo se necessário)
Hotkey "^#Right",     (*) => ToggleDesktop(1)
Hotkey "^#Left",      (*) => ToggleDesktop(-1)
Hotkey "^#Up",        (*) => ToggleDesktop(1)
Hotkey "^#Down",      (*) => ToggleDesktop(-1)

; Mouse Buttons
Hotkey "^#XButton2",  (*) => ToggleDesktop(1)
Hotkey "^#XButton1",  (*) => ToggleDesktop(-1)

; Reset
Hotkey "^#Delete",    (*) => Reload()

; =====================================================
; NOTA SOBRE WINDOWS 11 25H2
; =====================================================
; A estratégia de mover janelas manualmente é mais robusta que o "Pin"
; porque não depende da persistência do estado de pinagem do sistema.
