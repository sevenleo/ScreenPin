#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

if (A_Args.Length && A_Args[1] = "--self-test") {
    StartupWindowDesktops := Map()
    RunRestoreSelfTest()
    ExitApp()
}

;@Ahk2Exe-SetMainIcon icon.ico
;@Ahk2Exe-SetName ScreenPin
;@Ahk2Exe-SetDescription ScreenPin
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
    global hVDA, AppTempDir, WindowDestroyHook, WindowDestroyCallbackPtr
    RestoreStartupWindows()
    if WindowDestroyHook {
        try DllCall("UnhookWinEvent", "Ptr", WindowDestroyHook, "Int")
        WindowDestroyHook := 0
    }
    if WindowDestroyCallbackPtr {
        try CallbackFree(WindowDestroyCallbackPtr)
        WindowDestroyCallbackPtr := 0
    }
    if hVDA
        try DllCall("kernel32.dll\FreeLibrary", "Ptr", hVDA)
    if DirExist(AppTempDir)
        try DirDelete(AppTempDir, true)
}
OnExit(Cleanup)

; =====================================================
; CONFIGURATION
; =====================================================
MaxDesktops := 0    ; Set dynamically
UnpinDelayMs := 300 ; Delay for stability (optional)
ScrollDebounceMs := 1000 ; Throttle wheel-based desktop switches
DoubleTapWindowMs := 250 ; Max gap between ScrollLock taps

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
pGetWindowDesktopId := 0
pGetDesktopNumberById := 0

SelectGui := ""
StartupWindowDesktops := Map()
WindowDestroyHook := 0
WindowDestroyCallbackPtr := 0

; Icon setup (Read from the EXE itself or script icon)
A_IconTip := "ScreenPin - Desktop Per Monitor"

; =====================================================
; TRAY MENU CONFIGURATION
; =====================================================
ConfigureTray() {
    Tray := A_TrayMenu
    Tray.Delete() ; Clear default menu
    Tray.Add("Settings (Change Monitor)", (*) => ShowSelectGui())
    Tray.Add("Restore", (*) => RestoreAndDisablePin())
    Tray.Add() ; Separator
    Tray.Add("Exit", (*) => ExitApp())
    
    Tray.Default := "Settings (Change Monitor)"
    Tray.ClickCount := 1 ; Single click on tray icon triggers the default item
}
ConfigureTray()

; =====================================================
; DLL LOADING
; =====================================================
LoadVDA() {
    global hVDA, pGetDesktopCount, pGoToDesktopNumber, pGetCurrentDesktopNumber, pMoveWindowToDesktopNumber, pGetWindowDesktopId, pGetDesktopNumberById, MaxDesktops, AppTempDir

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
    pGetWindowDesktopId := DllCall("kernel32.dll\GetProcAddress", "Ptr", hVDA, "AStr", "GetWindowDesktopId", "Ptr")
    pGetDesktopNumberById := DllCall("kernel32.dll\GetProcAddress", "Ptr", hVDA, "AStr", "GetDesktopNumberById", "Ptr")

    if (!pGetDesktopCount || !pGoToDesktopNumber || !pGetCurrentDesktopNumber || !pMoveWindowToDesktopNumber || !pGetWindowDesktopId || !pGetDesktopNumberById) {
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
    try SelectGui.Destroy() ; Avoid duplicate windows on repeated tray clicks
    MonitorCount := MonitorGetCount()
    
    ; Layout Settings
    btnWidth := 200
    btnHeight := 40
    spacing := 10
    guiWidth := 300
    
    SelectGui := Gui("+AlwaysOnTop -MinimizeBox -MaximizeBox", "ScreenPin - Configuration")
    SelectGui.OnEvent("Close", (*) => ExitApp())
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

    btnRestore := SelectGui.AddButton("w" btnWidth " h" btnHeight " x" xPos " y+10", "Restore")
    btnRestore.OnEvent("Click", (*) => RestoreAndDisablePin())

    SelectGui.AddText("x0 y+20 h1 w" guiWidth " 0x10") ; Separator Line
    
    SelectGui.SetFont("s8", "Segoe UI")
    SelectGui.AddText("wp Center cGray y+10", "Switch pinned monitor: Ctrl+Win+Delete")
    SelectGui.AddText("wp Center cGray", "Desktop switch: Ctrl+Win+Arrows")
    SelectGui.AddText("wp Center cGray", "Desktop switch: Ctrl+Win+ Mouse4 or Mouse5")
    SelectGui.AddText("wp Center cGray", "Desktop switch: Press scrollLock twice")
    SelectGui.AddText("wp Center cGray", "Advanced hotkey: hold Right Mouse + Mouse4, then WheelDown")
    
    SelectGui.AddText("y+10 h5") ; Bottom margin
    SelectGui.Show("Center")
}

RestoreAndDisablePin(*) {
    global FixedMonitorIndex, Ready, SelectGui
    FixedMonitorIndex := 0
    Ready := true
    RestoreStartupWindows()
    try SelectGui.Destroy()
}

InstallWindowDestroyHook() {
    global WindowDestroyHook, WindowDestroyCallbackPtr
    WindowDestroyCallbackPtr := CallbackCreate(OnTrackedWindowDestroyed, "", 7)
    WindowDestroyHook := DllCall("SetWinEventHook", "UInt", 0x8001, "UInt", 0x8001, "Ptr", 0, "Ptr", WindowDestroyCallbackPtr, "UInt", 0, "UInt", 0, "UInt", 0, "Ptr")
    if !WindowDestroyHook {
        try CallbackFree(WindowDestroyCallbackPtr)
        WindowDestroyCallbackPtr := 0
    }
}

OnTrackedWindowDestroyed(hook, event, hwnd, objectId, childId, threadId, eventTime) {
    global StartupWindowDesktops
    if (objectId = 0 && childId = 0 && StartupWindowDesktops.Has(hwnd))
        StartupWindowDesktops.Delete(hwnd)
}

CaptureStartupWindows() {
    global StartupWindowDesktops, WindowDestroyHook, pGetWindowDesktopId, pGetDesktopNumberById
    if !WindowDestroyHook
        return

    for hwnd in WinGetList() {
        if !DllCall("IsWindow", "Ptr", hwnd, "Int")
            continue
        windowPid := 0
        DllCall("GetWindowThreadProcessId", "Ptr", hwnd, "UInt*", &windowPid, "UInt")
        if !windowPid
            continue
        desktopId := Buffer(16, 0)
        try {
            DllCall(pGetWindowDesktopId, "Ptr", desktopId.Ptr, "Ptr", hwnd, "Ptr")
            if (DllCall(pGetDesktopNumberById, "Ptr", desktopId.Ptr, "Int") < 0)
                continue
            currentPid := 0
            DllCall("GetWindowThreadProcessId", "Ptr", hwnd, "UInt*", &currentPid, "UInt")
            if (currentPid = windowPid && DllCall("IsWindow", "Ptr", hwnd, "Int"))
                StartupWindowDesktops[hwnd] := { DesktopId: desktopId, ProcessId: windowPid }
        } catch {
            ; A window that cannot be identified is not safe to restore.
        }
    }
}

RestoreStartupWindows(*) {
    global StartupWindowDesktops, pGetDesktopNumberById, pMoveWindowToDesktopNumber
    static busy := false
    if (busy || StartupWindowDesktops.Count = 0 || !pGetDesktopNumberById || !pMoveWindowToDesktopNumber)
        return

    busy := true
    try {
        windowsToRestore := StartupWindowDesktops.Clone()
        for hwnd, window in windowsToRestore {
            if !StartupWindowDesktops.Has(hwnd)
                continue
            if !DllCall("IsWindow", "Ptr", hwnd, "Int")
                continue
            windowPid := 0
            DllCall("GetWindowThreadProcessId", "Ptr", hwnd, "UInt*", &windowPid, "UInt")
            if (windowPid != window.ProcessId)
                continue
            try {
                desktopNumber := DllCall(pGetDesktopNumberById, "Ptr", window.DesktopId.Ptr, "Int")
                if (desktopNumber >= 0 && StartupWindowDesktops.Has(hwnd) && DllCall("IsWindow", "Ptr", hwnd, "Int")) {
                    currentPid := 0
                    DllCall("GetWindowThreadProcessId", "Ptr", hwnd, "UInt*", &currentPid, "UInt")
                    if (currentPid = window.ProcessId && DllCall("IsWindow", "Ptr", hwnd, "Int"))
                        DllCall(pMoveWindowToDesktopNumber, "Ptr", hwnd, "Int", desktopNumber, "Int")
                }
            } catch {
                ; Continue restoring other windows if one window fails.
            }
        }
    } finally {
        busy := false
    }
}

RunRestoreSelfTest() {
    global StartupWindowDesktops, pGetDesktopNumberById, pMoveWindowToDesktopNumber
    global FixedMonitorIndex, Ready, SelectGui
    global SelfTestDesktopNumber, SelfTestMoveCount, SelfTestLastHwnd, SelfTestLastDesktop

    FixedMonitorIndex := 1
    Ready := false
    SelectGui := ""
    SelfTestDesktopNumber := -1
    SelfTestMoveCount := 0
    SelfTestLastHwnd := 0
    SelfTestLastDesktop := -1
    pGetDesktopNumberById := CallbackCreate(SelfTestResolveDesktop, "", 1)
    pMoveWindowToDesktopNumber := CallbackCreate(SelfTestMoveWindow, "", 2)
    testWindow := Gui()
    testWindow.Show("Hide")
    untrackedWindow := Gui()
    untrackedWindow.Show("Hide")
    hwnd := testWindow.Hwnd
    desktopId := Buffer(16, 0)
    processId := DllCall("GetCurrentProcessId", "UInt")
    StartupWindowDesktops[hwnd] := { DesktopId: desktopId, ProcessId: processId }

    try {
        RestoreStartupWindows()
        if (SelfTestMoveCount != 0)
            throw Error("A missing original desktop should not move the window.")

        SelfTestDesktopNumber := 2
        RestoreStartupWindows()
        if (SelfTestMoveCount != 1 || SelfTestLastHwnd != hwnd || SelfTestLastDesktop != 2)
            throw Error("A tracked window was not moved to its original desktop.")

        RestoreAndDisablePin()
        if (FixedMonitorIndex != 0 || !Ready || SelfTestMoveCount != 2)
            throw Error("Restore did not disable the fixed monitor and restore again.")

        OnTrackedWindowDestroyed(0, 0x8001, hwnd, 0, 0, 0, 0)
        RestoreStartupWindows()
        if (SelfTestMoveCount != 2)
            throw Error("A destroyed window remained in the restore snapshot.")

        FileAppend("Restore self-test passed.`n", "*")
    } finally {
        desktopCallback := pGetDesktopNumberById
        moveCallback := pMoveWindowToDesktopNumber
        StartupWindowDesktops := Map()
        pGetDesktopNumberById := 0
        pMoveWindowToDesktopNumber := 0
        try CallbackFree(desktopCallback)
        try CallbackFree(moveCallback)
        try untrackedWindow.Destroy()
        try testWindow.Destroy()
    }
}

SelfTestResolveDesktop(desktopIdPtr) {
    global SelfTestDesktopNumber
    return desktopIdPtr ? SelfTestDesktopNumber : -1
}

SelfTestMoveWindow(hwnd, desktopNumber) {
    global SelfTestMoveCount, SelfTestLastHwnd, SelfTestLastDesktop
    SelfTestMoveCount += 1
    SelfTestLastHwnd := hwnd
    SelfTestLastDesktop := desktopNumber
    return 0
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

    ; Re-entrancy guard: rapid hotkeys must not stack blocking COM calls
    static busy := false
    if (busy)
        return
    busy := true
    try {
        if (!Ready || MaxDesktops < 2)
            return

        current := DllCall(pGetCurrentDesktopNumber, "Int")
        target := direction > 0 ? Mod(current + 1, MaxDesktops) : Mod(current - 1 + MaxDesktops, MaxDesktops)

        ; If there's a fixed monitor, move its windows to target BEFORE switching
        if (FixedMonitorIndex > 0) {
            windows := WinGetList()
            for hwnd in windows {
                if IsWindowOnFixedMonitor(hwnd) {
                    ; Skip hung windows: a COM move against one blocks the main thread forever
                    if (DllCall("IsHungAppWindow", "Ptr", hwnd, "Int"))
                        continue
                    ; Move window to target desktop
                    DllCall(pMoveWindowToDesktopNumber, "Ptr", hwnd, "Int", target)
                }
            }
        }

        ; Switch desktop
        DllCall(pGoToDesktopNumber, "Int", target)
    } catch {
        ; A DLL/COM failure must never destabilize the script's main thread
    } finally {
        busy := false
    }
}

HandleWheelDesktop(direction := 1) {
    global ScrollDebounceMs
    static lastTick := 0

    now := A_TickCount
    if (now - lastTick < ScrollDebounceMs)
        return

    lastTick := now
    ToggleDesktop(direction)
}

HandleScrollLockDoubleTap(*) {
    global DoubleTapWindowMs
    static lastTap := 0

    now := A_TickCount
    if (now - lastTap <= DoubleTapWindowMs) {
        lastTap := 0
        ToggleDesktop(1)
        return
    }

    lastTap := now
}

; =====================================================
; INITIALIZATION
; =====================================================
LoadVDA()
InstallWindowDestroyHook()
CaptureStartupWindows()
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

HotIf (*) => GetKeyState("RButton", "P") && GetKeyState("XButton1", "P")
Hotkey "WheelDown", (*) => HandleWheelDesktop(1)
HotIf

Hotkey "~ScrollLock", HandleScrollLockDoubleTap


; Reset
Hotkey "^#Delete",    (*) => Reload()

; =====================================================
; NOTE ON WINDOWS 11 25H2
; =====================================================
; The manual window movement strategy is more robust than "Pinning"
; because it doesn't rely on the persistence of the system's pinning state.
