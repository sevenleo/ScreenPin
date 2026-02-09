#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

;@Ahk2Exe-SetMainIcon icon.ico
;@Ahk2Exe-SetName ScreenPin
;@Ahk2Exe-SetDescription Independent Virtual Desktop per Monitor
;@Ahk2Exe-SetVersion 1.0.0

; =====================================================
; DEPENDENCIES & CLEANUP
; =====================================================
; Create a private temp path for this app
AppTempDir := StrReplace(A_Temp, "/", "\") "\ScreenPin"
if !DirExist(AppTempDir)
    DirCreate(AppTempDir)

; Extract DLL to temp folder
FileInstall "VirtualDesktopAccessor.dll", AppTempDir "\VirtualDesktopAccessor.dll", 1

; Ensure DLL is cleaned up when script exits
Cleanup(*) {
    global hVDA
    if hVDA
        DllCall("kernel32.dll\FreeLibrary", "Ptr", hVDA)
    if DirExist(AppTempDir)
        try DirDelete(AppTempDir, true)
}
OnExit(Cleanup)

; =====================================================
; CONFIGURATION
; =====================================================
MaxDesktops := 0    ; Set dynamically
UnpinDelayMs := 300 ; Delay for stability (optional)

; =====================================================
; GLOBAL STATE
; =====================================================
FixedMonitorIndex := 0
Ready := false
MonitorCount := 0
hVDA := 0

; DLL Pointers
pGetDesktopCount := 0
pGoToDesktopNumber := 0
pGetCurrentDesktopNumber := 0
pMoveWindowToDesktopNumber := 0
pGetWindowDesktopNumber := 0

SelectGui := ""

; Icon setup (Read from the EXE itself or script icon)
A_IconTip := "ScreenPin - Desktop Per Monitor"

; =====================================================
; DLL LOADING
; =====================================================
LoadVDA() {
    global hVDA, pGetDesktopCount, pGoToDesktopNumber, pGetCurrentDesktopNumber, pMoveWindowToDesktopNumber, pGetWindowDesktopNumber, MaxDesktops, AppTempDir

    VDA_PATH := AppTempDir "\VirtualDesktopAccessor.dll"

    hVDA := DllCall("kernel32.dll\LoadLibrary", "Str", VDA_PATH, "Ptr")

    if (!hVDA) {
        MsgBox "Error loading DLL from temp: " . VDA_PATH . "`nCode: " . A_LastError
        ExitApp
    }

    pGetDesktopCount := DllCall("kernel32.dll\GetProcAddress", "Ptr", hVDA, "AStr", "GetDesktopCount", "Ptr")
    pGoToDesktopNumber := DllCall("kernel32.dll\GetProcAddress", "Ptr", hVDA, "AStr", "GoToDesktopNumber", "Ptr")
    pGetCurrentDesktopNumber := DllCall("kernel32.dll\GetProcAddress", "Ptr", hVDA, "AStr", "GetCurrentDesktopNumber", "Ptr")
    pMoveWindowToDesktopNumber := DllCall("kernel32.dll\GetProcAddress", "Ptr", hVDA, "AStr", "MoveWindowToDesktopNumber", "Ptr")
    pGetWindowDesktopNumber := DllCall("kernel32.dll\GetProcAddress", "Ptr", hVDA, "AStr", "GetWindowDesktopNumber", "Ptr")

    if (!pGetDesktopCount || !pGoToDesktopNumber || !pGetCurrentDesktopNumber || !pMoveWindowToDesktopNumber) {
        MsgBox "Failed to get function addresses from DLL."
        ExitApp
    }

    MaxDesktops := DllCall(pGetDesktopCount, "Int")
}

; =====================================================
; FIXED MONITOR SELECTION GUI
; =====================================================
ShowSelectGui() {
    global SelectGui, MonitorCount, FixedMonitorIndex, Ready
    MonitorCount := MonitorGetCount()
    
    ; Layout Settings
    btnWidth := 200
    btnHeight := 40
    spacing := 10
    guiWidth := 300
    
    SelectGui := Gui("+AlwaysOnTop -MinimizeBox -MaximizeBox", "ScreenPin - Configuration")
    SelectGui.SetFont("s11 w600", "Segoe UI")
    SelectGui.AddText("w" guiWidth " Center", "CONFIGURATION")
    
    SelectGui.SetFont("s9 w400", "Segoe UI")
    SelectGui.AddText("wp Center cGray", "Choose which monitor stays fixed:")
    SelectGui.AddText("h5") ; Spacer

    ; Horizontal Centering
    xPos := (guiWidth - btnWidth) / 2
    
    OnMonitorClick(ctrl, *) {
        global FixedMonitorIndex, Ready
        FixedMonitorIndex := Integer(RegExReplace(ctrl.Text, "\D"))
        Ready := true
        SelectGui.Destroy()
    }

    OnNoneClick(*) {
        global FixedMonitorIndex, Ready
        FixedMonitorIndex := 0
        Ready := true
        SelectGui.Destroy()
    }

    ; Add monitor buttons in column (Fixed X)
    Loop MonitorCount {
        btn := SelectGui.AddButton("w" btnWidth " h" btnHeight " x" xPos " y+10", "Monitor " A_Index)
        btn.OnEvent("Click", OnMonitorClick)
    }

    ; Add "None" button in the same column
    btnNone := SelectGui.AddButton("w" btnWidth " h" btnHeight " x" xPos " y+10", "None (Windows Default)")
    btnNone.OnEvent("Click", OnNoneClick)

    SelectGui.AddText("x0 y+20 h1 w" guiWidth " 0x10") ; Separator Line
    
    SelectGui.SetFont("s8", "Segoe UI")
    SelectGui.AddText("wp Center cGray y+10", "Switch monitor shortcut: Ctrl+Win+Delete")
    
    SelectGui.AddText("y+10 h5") ; Bottom margin
    SelectGui.Show("Center")
}

; =====================================================
; WINDOW GEOMETRY LOGIC
; =====================================================
IsWindowOnFixedMonitor(hwnd) {
    global FixedMonitorIndex
    if (FixedMonitorIndex = 0)
        return false

    try {
        ; Get fixed monitor coordinates
        MonitorGet(FixedMonitorIndex, &L, &T, &R, &B)
        
        ; Get window position
        WinGetPos(&X, &Y, &W, &H, hwnd)
        
        ; Calculate window center point
        midX := X + (W / 2)
        midY := Y + (H / 2)
        
        ; Check if center is within monitor boundaries
        return (midX >= L && midX <= R && midY >= T && midY <= B)
    } catch {
        return false
    }
}

; =====================================================
; DESKTOP TOGGLE (MIGRATION STRATEGY)
; =====================================================
ToggleDesktop(direction := 1) {
    global Ready, MaxDesktops, pGetCurrentDesktopNumber, pGoToDesktopNumber, pMoveWindowToDesktopNumber, FixedMonitorIndex

    if (!Ready || MaxDesktops < 2)
        return

    current := DllCall(pGetCurrentDesktopNumber, "Int")
    target := direction > 0 ? Mod(current + 1, MaxDesktops) : Mod(current - 1 + MaxDesktops, MaxDesktops)

    ; If there's a fixed monitor, move its windows to target BEFORE switching
    if (FixedMonitorIndex > 0) {
        windows := WinGetList()
        for hwnd in windows {
            if IsWindowOnFixedMonitor(hwnd) {
                ; Move window to target desktop
                DllCall(pMoveWindowToDesktopNumber, "Ptr", hwnd, "Int", target)
            }
        }
    }

    ; Switch desktop
    DllCall(pGoToDesktopNumber, "Int", target)
}

; =====================================================
; INITIALIZATION
; =====================================================
LoadVDA()
ShowSelectGui()

; =====================================================
; HOTKEYS
; =====================================================
; Ctrl + Win + Arrows (Override native if needed)
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
; NOTE ON WINDOWS 11 25H2
; =====================================================
; The manual window movement strategy is more robust than "Pinning"
; because it doesn't rely on the persistence of the system's pinning state.
