#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

if (A_Args.Length && A_Args[1] = "--self-test") {
    StartupWindowDesktops := Map()
    SnapshotCaptured := false
    MigrationEpoch := 0
    try {
        RunRestoreSelfTest()
        FileAppend("Restore logic test passed.`n", "*")
        ExitApp(0)
    } catch as err {
        FileAppend("Restore logic test failed: " err.Message "`n", "*")
        ExitApp(1)
    }
}

if (A_Args.Length && A_Args[1] = "--integration-test") {
    try {
        RunRestoreIntegrationTest()
        ExitApp(0)
    } catch as err {
        FileAppend("Restore integration test failed: " err.Message "`n", "*")
        ExitApp(1)
    }
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
    global FixedMonitorIndex, Ready, MigrationEpoch
    FixedMonitorIndex := 0
    Ready := false
    MigrationEpoch += 1
    try {
        restoreResult := RestoreStartupWindows()
        if restoreResult.Failed
            OutputDebug("ScreenPin exit restore: " restoreResult.Restored " restored, " restoreResult.Ignored " ignored, " restoreResult.Failed " failed.")
    } finally {
        if WindowDestroyHook {
            try DllCall("UnhookWinEvent", "Ptr", WindowDestroyHook, "Int")
            WindowDestroyHook := 0
        }
        if WindowDestroyCallbackPtr {
            try CallbackFree(WindowDestroyCallbackPtr)
            WindowDestroyCallbackPtr := 0
        }
        if hVDA {
            try DllCall("kernel32.dll\FreeLibrary", "Ptr", hVDA)
            hVDA := 0
        }
        if DirExist(AppTempDir)
            try DirDelete(AppTempDir, true)
    }
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
MigrationEpoch := 0
SnapshotCaptured := false

; DLL Pointers
pGetDesktopCount := 0
pGoToDesktopNumber := 0
pGetCurrentDesktopNumber := 0
pMoveWindowToDesktopNumber := 0
pGetWindowDesktopId := 0
pGetDesktopNumberById := 0
pGetWindowDesktopNumber := 0

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
    global hVDA, pGetDesktopCount, pGoToDesktopNumber, pGetCurrentDesktopNumber, pMoveWindowToDesktopNumber, pGetWindowDesktopId, pGetDesktopNumberById, pGetWindowDesktopNumber, MaxDesktops, AppTempDir

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
    pGetWindowDesktopNumber := DllCall("kernel32.dll\GetProcAddress", "Ptr", hVDA, "AStr", "GetWindowDesktopNumber", "Ptr")

    if (!pGetDesktopCount || !pGoToDesktopNumber || !pGetCurrentDesktopNumber || !pMoveWindowToDesktopNumber || !pGetWindowDesktopId || !pGetDesktopNumberById || !pGetWindowDesktopNumber) {
        MsgBox "Failed to get function addresses from DLL."
        ExitApp
    }

    MaxDesktops := DllCall(pGetDesktopCount, "Int")
    currentDesktop := DllCall(pGetCurrentDesktopNumber, "Int")
    if (MaxDesktops < 1 || currentDesktop < 0 || currentDesktop >= MaxDesktops) {
        MsgBox "Failed to query the current virtual desktop from the DLL."
        ExitApp
    }
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
        global FixedMonitorIndex, Ready, MigrationEpoch, SelectGui
        FixedMonitorIndex := Integer(RegExReplace(ctrl.Text, "\D"))
        MigrationEpoch += 1
        Ready := true
        SelectGui.Destroy()
    }

    OnNoneClick(*) {
        global SelectGui
        DisablePin()
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
    global FixedMonitorIndex, Ready, SelectGui, MigrationEpoch
    FixedMonitorIndex := 0
    MigrationEpoch += 1
    Ready := true
    restoreResult := RestoreStartupWindows()
    if (restoreResult.Failed || !restoreResult.SnapshotReady)
        ShowRestoreSummary(restoreResult)
    try SelectGui.Destroy()
}

DisablePin(*) {
    global FixedMonitorIndex, Ready, MigrationEpoch
    FixedMonitorIndex := 0
    MigrationEpoch += 1
    Ready := true
}

InstallWindowDestroyHook() {
    global WindowDestroyHook, WindowDestroyCallbackPtr
    try {
        WindowDestroyCallbackPtr := CallbackCreate(OnTrackedWindowDestroyed, "", 7)
        WindowDestroyHook := DllCall("SetWinEventHook", "UInt", 0x8001, "UInt", 0x8001, "Ptr", 0, "Ptr", WindowDestroyCallbackPtr, "UInt", 0, "UInt", 0, "UInt", 0, "Ptr")
    } catch {
        WindowDestroyHook := 0
    }
    if !WindowDestroyHook {
        try CallbackFree(WindowDestroyCallbackPtr)
        WindowDestroyCallbackPtr := 0
    }
    return WindowDestroyHook != 0
}

OnTrackedWindowDestroyed(hook, event, hwnd, objectId, childId, threadId, eventTime) {
    global StartupWindowDesktops
    if ((objectId & 0xFFFFFFFF) = 0 && (childId & 0xFFFFFFFF) = 0 && StartupWindowDesktops.Has(hwnd))
        StartupWindowDesktops.Delete(hwnd)
}

CaptureStartupWindows() {
    global StartupWindowDesktops, WindowDestroyHook, pGetWindowDesktopId, pGetDesktopNumberById, MaxDesktops, SnapshotCaptured
    if SnapshotCaptured
        return { SnapshotReady: true, Captured: StartupWindowDesktops.Count, Skipped: 0, Failed: 0 }

    StartupWindowDesktops := Map()
    result := { SnapshotReady: false, Captured: 0, Skipped: 0, Failed: 0 }
    if (!WindowDestroyHook || !pGetWindowDesktopId || !pGetDesktopNumberById || MaxDesktops < 1) {
        result.Failed := 1
        return result
    }

    previousDetectHiddenWindows := DetectHiddenWindows(true)
    try {
        for hwnd in WinGetList() {
            if (!DllCall("IsWindow", "Ptr", hwnd, "Int") || !DllCall("IsWindowVisible", "Ptr", hwnd, "Int") || hwnd = A_ScriptHwnd) {
                result.Skipped += 1
                continue
            }

            windowPid := 0
            if !DllCall("GetWindowThreadProcessId", "Ptr", hwnd, "UInt*", &windowPid, "UInt") || !windowPid {
                result.Skipped += 1
                continue
            }

            desktopId := Buffer(16, 0)
            try {
                DllCall(pGetWindowDesktopId, "Ptr", desktopId.Ptr, "Ptr", hwnd, "Ptr")
                desktopNumber := DllCall(pGetDesktopNumberById, "Ptr", desktopId.Ptr, "Int")
                if (desktopNumber < 0 || desktopNumber >= MaxDesktops) {
                    result.Skipped += 1
                    continue
                }

                currentPid := 0
                if (DllCall("IsWindow", "Ptr", hwnd, "Int") && DllCall("GetWindowThreadProcessId", "Ptr", hwnd, "UInt*", &currentPid, "UInt") && currentPid = windowPid)
                    StartupWindowDesktops[hwnd] := { DesktopId: desktopId, ProcessId: windowPid }
                else
                    result.Skipped += 1
            } catch {
                result.Failed += 1
            }
        }
        SnapshotCaptured := true
        result.SnapshotReady := true
        result.Captured := StartupWindowDesktops.Count
    } finally {
        DetectHiddenWindows(previousDetectHiddenWindows)
    }

    OutputDebug("ScreenPin startup snapshot: " result.Captured " captured, " result.Skipped " skipped, " result.Failed " failed.")
    return result
}

RestoreStartupWindows(*) {
    global StartupWindowDesktops, pGetDesktopNumberById, pGetWindowDesktopNumber, pMoveWindowToDesktopNumber, SnapshotCaptured
    static busy := false
    result := { SnapshotReady: SnapshotCaptured, Restored: 0, AlreadyAtOrigin: 0, Ignored: 0, Failed: 0 }
    if busy {
        result.Ignored := StartupWindowDesktops.Count
        return result
    }
    if !SnapshotCaptured
        return result
    if (!pGetDesktopNumberById || !pGetWindowDesktopNumber || !pMoveWindowToDesktopNumber) {
        result.Failed := StartupWindowDesktops.Count ? StartupWindowDesktops.Count : 1
        return result
    }

    busy := true
    try {
        windowsToRestore := StartupWindowDesktops.Clone()
        for hwnd, window in windowsToRestore {
            if !StartupWindowDesktops.Has(hwnd) {
                result.Ignored += 1
                continue
            }
            if !DllCall("IsWindow", "Ptr", hwnd, "Int") {
                StartupWindowDesktops.Delete(hwnd)
                result.Ignored += 1
                continue
            }
            windowPid := 0
            DllCall("GetWindowThreadProcessId", "Ptr", hwnd, "UInt*", &windowPid, "UInt")
            if (windowPid != window.ProcessId) {
                StartupWindowDesktops.Delete(hwnd)
                result.Ignored += 1
                continue
            }
            try {
                desktopNumber := DllCall(pGetDesktopNumberById, "Ptr", window.DesktopId.Ptr, "Int")
                if (desktopNumber < 0) {
                    result.Ignored += 1
                    continue
                }
                currentDesktop := DllCall(pGetWindowDesktopNumber, "Ptr", hwnd, "Int")
                if (currentDesktop < 0) {
                    result.Failed += 1
                    continue
                }
                if (currentDesktop = desktopNumber) {
                    result.AlreadyAtOrigin += 1
                    continue
                }
                if DllCall("IsHungAppWindow", "Ptr", hwnd, "Int") {
                    result.Ignored += 1
                    continue
                }

                currentPid := 0
                if (!StartupWindowDesktops.Has(hwnd) || !DllCall("IsWindow", "Ptr", hwnd, "Int") || !DllCall("GetWindowThreadProcessId", "Ptr", hwnd, "UInt*", &currentPid, "UInt") || currentPid != window.ProcessId) {
                    result.Ignored += 1
                    continue
                }
                moveResult := DllCall(pMoveWindowToDesktopNumber, "Ptr", hwnd, "Int", desktopNumber, "Int")
                if (moveResult != 1) {
                    result.Failed += 1
                    continue
                }

                deadline := A_TickCount + 250
                loop {
                    if !DllCall("IsWindow", "Ptr", hwnd, "Int") {
                        if StartupWindowDesktops.Has(hwnd)
                            StartupWindowDesktops.Delete(hwnd)
                        result.Ignored += 1
                        break
                    }
                    currentPid := 0
                    DllCall("GetWindowThreadProcessId", "Ptr", hwnd, "UInt*", &currentPid, "UInt")
                    if (currentPid != window.ProcessId) {
                        StartupWindowDesktops.Delete(hwnd)
                        result.Ignored += 1
                        break
                    }
                    currentDesktop := DllCall(pGetWindowDesktopNumber, "Ptr", hwnd, "Int")
                    if (currentDesktop = desktopNumber) {
                        result.Restored += 1
                        break
                    }
                    if (A_TickCount >= deadline) {
                        result.Failed += 1
                        break
                    }
                    if !StartupWindowDesktops.Has(hwnd) {
                        result.Ignored += 1
                        break
                    }
                    Sleep(50)
                }
            } catch {
                result.Failed += 1
            }
        }
    } finally {
        busy := false
    }
    return result
}

ShowRestoreSummary(result) {
    message := result.SnapshotReady
        ? "Restored: " result.Restored ", already in place: " result.AlreadyAtOrigin ", skipped: " result.Ignored ", failed: " result.Failed "."
        : "The startup window snapshot is unavailable. Restart ScreenPin and try again."
    TrayTip(message, "ScreenPin - Restore")
}

RunRestoreSelfTest() {
    global StartupWindowDesktops, pGetDesktopNumberById, pMoveWindowToDesktopNumber
    global pGetWindowDesktopNumber, FixedMonitorIndex, Ready, SelectGui, SnapshotCaptured, MigrationEpoch
    global SelfTestDesktopNumber, SelfTestWindowDesktops, SelfTestMoveCount, SelfTestLastHwnd, SelfTestLastDesktop
    global SelfTestFailHwnd, SelfTestWrongTargetHwnd, SelfTestDelayedHwnd, SelfTestUnknownReads, SelfTestMoveReturn

    FixedMonitorIndex := 1
    Ready := false
    SelectGui := ""
    SelfTestDesktopNumber := -1
    SelfTestWindowDesktops := Map()
    SelfTestMoveCount := 0
    SelfTestLastHwnd := 0
    SelfTestLastDesktop := -1
    SelfTestFailHwnd := 0
    SelfTestWrongTargetHwnd := 0
    SelfTestDelayedHwnd := 0
    SelfTestUnknownReads := 0
    SelfTestMoveReturn := 1
    pGetDesktopNumberById := CallbackCreate(SelfTestResolveDesktop, "", 1)
    pMoveWindowToDesktopNumber := CallbackCreate(SelfTestMoveWindow, "", 2)
    pGetWindowDesktopNumber := CallbackCreate(SelfTestGetWindowDesktopNumber, "", 1)
    testWindow := Gui()
    testWindow.Show("Hide")
    secondWindow := Gui()
    secondWindow.Show("Hide")
    untrackedWindow := Gui()
    untrackedWindow.Show("Hide")
    hwnd := testWindow.Hwnd
    secondHwnd := secondWindow.Hwnd
    untrackedHwnd := untrackedWindow.Hwnd
    SelfTestWindowDesktops[hwnd] := 1
    SelfTestWindowDesktops[secondHwnd] := 1
    SelfTestWindowDesktops[untrackedHwnd] := 1
    desktopId := Buffer(16, 0)
    secondDesktopId := Buffer(16, 0)
    processId := DllCall("GetCurrentProcessId", "UInt")
    StartupWindowDesktops[hwnd] := { DesktopId: desktopId, ProcessId: processId }
    StartupWindowDesktops[secondHwnd] := { DesktopId: secondDesktopId, ProcessId: processId }
    SnapshotCaptured := true

    try {
        result := RestoreStartupWindows()
        if (SelfTestMoveCount != 0 || result.Ignored != 2)
            throw Error("A missing original desktop should not move the window.")

        SelfTestDesktopNumber := 2
        SelfTestWrongTargetHwnd := hwnd
        result := RestoreStartupWindows()
        if (result.Failed != 1 || result.Restored != 1 || SelfTestWindowDesktops[hwnd] != 1 || SelfTestWindowDesktops[secondHwnd] != 2)
            throw Error("Restore did not detect a mismatched final desktop and continue to the next window.")
        SelfTestWrongTargetHwnd := 0
        SelfTestWindowDesktops[hwnd] := 1
        SelfTestWindowDesktops[secondHwnd] := 1

        SelfTestFailHwnd := hwnd
        SelfTestMoveReturn := -1
        result := RestoreStartupWindows()
        if (result.Failed != 1 || result.Restored != 1 || SelfTestWindowDesktops[hwnd] != 1 || SelfTestWindowDesktops[secondHwnd] != 2)
            throw Error("A failed DLL move was counted as success or stopped restoration of later windows.")
        SelfTestFailHwnd := 0
        SelfTestMoveReturn := 1

        originalGuidBuffer := StartupWindowDesktops[hwnd].DesktopId.Ptr
        result := RestoreStartupWindows()
        if (result.Restored != 1 || SelfTestWindowDesktops[hwnd] != 2 || StartupWindowDesktops[hwnd].DesktopId.Ptr != originalGuidBuffer)
            throw Error("A tracked window was not restored using the original, retained desktop GUID.")

        SelfTestWindowDesktops[hwnd] := 1
        SelfTestDelayedHwnd := hwnd
        SelfTestUnknownReads := 0
        result := RestoreStartupWindows()
        if (result.Restored != 1 || SelfTestUnknownReads != 0 || SelfTestWindowDesktops[hwnd] != 2)
            throw Error("Restore did not wait for a delayed desktop query to confirm its destination.")
        SelfTestDelayedHwnd := 0

        result := RestoreStartupWindows()
        if (result.AlreadyAtOrigin != 2 || StartupWindowDesktops.Count != 2)
            throw Error("A repeat restore moved a window already at its origin or discarded the snapshot.")

        SelfTestWindowDesktops[hwnd] := 1
        SelfTestWindowDesktops[secondHwnd] := 1
        previousEpoch := MigrationEpoch
        RestoreAndDisablePin()
        if (FixedMonitorIndex != 0 || !Ready || MigrationEpoch <= previousEpoch || SelfTestWindowDesktops[hwnd] != 2 || SelfTestWindowDesktops[secondHwnd] != 2 || StartupWindowDesktops.Count != 2)
            throw Error("Restore did not disable the pin, restore again, and retain the original snapshot.")

        FixedMonitorIndex := 1
        SelfTestWindowDesktops[hwnd] := 1
        SelfTestWindowDesktops[secondHwnd] := 1
        moveCountBeforeNone := SelfTestMoveCount
        previousEpoch := MigrationEpoch
        DisablePin()
        if (FixedMonitorIndex != 0 || !Ready || MigrationEpoch <= previousEpoch || SelfTestMoveCount != moveCountBeforeNone || SelfTestWindowDesktops[hwnd] != 1 || SelfTestWindowDesktops[secondHwnd] != 1 || StartupWindowDesktops.Count != 2)
            throw Error("Selecting None restored windows immediately or changed the original snapshot.")

        SelfTestWindowDesktops[secondHwnd] := 2
        OnTrackedWindowDestroyed(0, 0x8001, hwnd, 0, 0xCF1300000000, 0, 0)
        moveCountBeforeClosedWindow := SelfTestMoveCount
        result := RestoreStartupWindows()
        if (StartupWindowDesktops.Has(hwnd) || SelfTestMoveCount != moveCountBeforeClosedWindow || StartupWindowDesktops.Has(untrackedHwnd))
            throw Error("A destroyed window remained in the restore snapshot.")

    } finally {
        desktopCallback := pGetDesktopNumberById
        moveCallback := pMoveWindowToDesktopNumber
        desktopNumberCallback := pGetWindowDesktopNumber
        StartupWindowDesktops := Map()
        SelfTestWindowDesktops := Map()
        SnapshotCaptured := false
        pGetDesktopNumberById := 0
        pMoveWindowToDesktopNumber := 0
        pGetWindowDesktopNumber := 0
        try CallbackFree(desktopCallback)
        try CallbackFree(moveCallback)
        try CallbackFree(desktopNumberCallback)
        try untrackedWindow.Destroy()
        try secondWindow.Destroy()
        try testWindow.Destroy()
    }
}

SelfTestResolveDesktop(desktopIdPtr) {
    global SelfTestDesktopNumber
    return desktopIdPtr ? SelfTestDesktopNumber : -1
}

SelfTestMoveWindow(hwnd, desktopNumber) {
    global SelfTestMoveCount, SelfTestLastHwnd, SelfTestLastDesktop, SelfTestWindowDesktops
    global SelfTestFailHwnd, SelfTestWrongTargetHwnd, SelfTestDelayedHwnd, SelfTestUnknownReads, SelfTestMoveReturn
    SelfTestMoveCount += 1
    SelfTestLastHwnd := hwnd
    SelfTestLastDesktop := desktopNumber
    if (hwnd = SelfTestFailHwnd)
        return SelfTestMoveReturn
    if (hwnd != SelfTestWrongTargetHwnd)
        SelfTestWindowDesktops[hwnd] := desktopNumber
    if (hwnd = SelfTestDelayedHwnd)
        SelfTestUnknownReads := 2
    return 1
}

SelfTestGetWindowDesktopNumber(hwnd) {
    global SelfTestWindowDesktops, SelfTestDelayedHwnd, SelfTestUnknownReads
    if (hwnd = SelfTestDelayedHwnd && SelfTestUnknownReads > 0) {
        SelfTestUnknownReads -= 1
        return -1
    }
    return SelfTestWindowDesktops.Has(hwnd) ? SelfTestWindowDesktops[hwnd] : -1
}

RunRestoreIntegrationTest() {
    global AppTempDir, hVDA, MaxDesktops, pGetDesktopCount, pGetCurrentDesktopNumber
    global pMoveWindowToDesktopNumber, pGetWindowDesktopNumber, pGetWindowDesktopId, pGetDesktopNumberById
    global StartupWindowDesktops, SnapshotCaptured, WindowDestroyHook, WindowDestroyCallbackPtr

    currentPid := DllCall("GetCurrentProcessId", "UInt")
    testTempDir := A_Temp "\ScreenPin-RestoreTest-" currentPid
    if InStr(StrLower(testTempDir), StrLower(A_Temp "\")) != 1
        throw Error("The integration-test temp directory is outside A_Temp.")
    if DirExist(testTempDir)
        DirDelete(testTempDir, true)
    DirCreate(testTempDir)

    AppTempDir := testTempDir
    hVDA := 0
    pGetDesktopCount := 0
    pGetCurrentDesktopNumber := 0
    pMoveWindowToDesktopNumber := 0
    pGetWindowDesktopNumber := 0
    pGetWindowDesktopId := 0
    pGetDesktopNumberById := 0
    MaxDesktops := 0
    StartupWindowDesktops := Map()
    SnapshotCaptured := false
    WindowDestroyHook := 0
    WindowDestroyCallbackPtr := 0

    testWindows := []
    try {
        FileInstall "VirtualDesktopAccessor.dll", testTempDir "\VirtualDesktopAccessor.dll", 1
        LoadVDA()
        if (MaxDesktops < 2)
            throw Error("Integration test requires at least two virtual desktops.")

        originalDesktop := DllCall(pGetCurrentDesktopNumber, "Int")
        otherDesktop := Mod(originalDesktop + 1, MaxDesktops)
        windowOnOriginalDesktop := Gui(, "ScreenPin restore integration original")
        windowOnOriginalDesktop.Show("NA w220 h80")
        testWindows.Push(windowOnOriginalDesktop)

        windowOnOtherDesktop := Gui(, "ScreenPin restore integration inactive")
        windowOnOtherDesktop.Show("NA w220 h80")
        testWindows.Push(windowOnOtherDesktop)
        if (DllCall(pMoveWindowToDesktopNumber, "Ptr", windowOnOtherDesktop.Hwnd, "Int", otherDesktop, "Int") != 1)
            throw Error("Could not move the disposable integration window to another desktop.")

        closedOriginalWindow := Gui(, "ScreenPin restore integration closed")
        closedOriginalWindow.Show("NA w220 h80")
        testWindows.Push(closedOriginalWindow)

        if !InstallWindowDestroyHook()
            throw Error("Could not install the integration-test destroy hook.")

        captureResult := CaptureStartupWindows()
        if !captureResult.SnapshotReady
            throw Error("Startup window capture did not complete.")
        if (!StartupWindowDesktops.Has(windowOnOriginalDesktop.Hwnd) || !StartupWindowDesktops.Has(windowOnOtherDesktop.Hwnd) || !StartupWindowDesktops.Has(closedOriginalWindow.Hwnd))
            throw Error("Capture did not include every eligible disposable window across both desktops.")

        ; The capture scans the real desktop, but the integration test may restore only its own windows.
        testSnapshot := Map()
        for testWindow in testWindows
            if StartupWindowDesktops.Has(testWindow.Hwnd)
                testSnapshot[testWindow.Hwnd] := StartupWindowDesktops[testWindow.Hwnd]
        if (testSnapshot.Count != testWindows.Length)
            throw Error("The disposable windows were not all in the captured snapshot.")
        StartupWindowDesktops := testSnapshot

        priorHiddenWindowSetting := DetectHiddenWindows(true)
        inactiveWindowWasEnumerated := false
        for hwnd in WinGetList()
            if (hwnd = windowOnOtherDesktop.Hwnd)
                inactiveWindowWasEnumerated := true
        DetectHiddenWindows(priorHiddenWindowSetting)
        if !inactiveWindowWasEnumerated
            throw Error("AutoHotkey did not enumerate the cloaked disposable window.")

        expectedDesktopByHwnd := Map(windowOnOriginalDesktop.Hwnd, originalDesktop, windowOnOtherDesktop.Hwnd, otherDesktop, closedOriginalWindow.Hwnd, originalDesktop)
        for testWindow in testWindows {
            if (DllCall(pGetWindowDesktopNumber, "Ptr", testWindow.Hwnd, "Int") != expectedDesktopByHwnd[testWindow.Hwnd])
                throw Error("The DLL returned an unexpected original desktop for a disposable window.")
        }

        newWindow := Gui(, "ScreenPin restore integration new")
        newWindow.Show("NA w220 h80")
        testWindows.Push(newWindow)
        newWindowDesktop := -1
        deadline := A_TickCount + 250
        while (newWindowDesktop < 0 && A_TickCount < deadline) {
            newWindowDesktop := DllCall(pGetWindowDesktopNumber, "Ptr", newWindow.Hwnd, "Int")
            if (newWindowDesktop < 0)
                Sleep(50)
        }
        if (newWindowDesktop < 0)
            throw Error("The DLL could not identify the desktop for a post-snapshot disposable window.")

        closedHwnd := closedOriginalWindow.Hwnd
        closedOriginalWindow.Destroy()
        Sleep(500)
        if StartupWindowDesktops.Has(closedHwnd)
            throw Error("The destroy hook did not remove a closed original window.")

        for hwnd, window in StartupWindowDesktops {
            targetDesktop := DllCall(pGetDesktopNumberById, "Ptr", window.DesktopId.Ptr, "Int")
            moveToDesktop := targetDesktop = originalDesktop ? otherDesktop : originalDesktop
            if (DllCall(pMoveWindowToDesktopNumber, "Ptr", hwnd, "Int", moveToDesktop, "Int") != 1)
                throw Error("Could not move a tracked disposable window before restore.")
        }

        restoreResult := RestoreStartupWindows()
        if (restoreResult.Failed || restoreResult.Restored != 2)
            throw Error("Restore did not return both live original windows to their origins.")
        if (DllCall(pGetWindowDesktopNumber, "Ptr", windowOnOriginalDesktop.Hwnd, "Int") != originalDesktop || DllCall(pGetWindowDesktopNumber, "Ptr", windowOnOtherDesktop.Hwnd, "Int") != otherDesktop)
            throw Error("A tracked disposable window did not return to its original desktop.")
        if (DllCall(pGetWindowDesktopNumber, "Ptr", newWindow.Hwnd, "Int") != newWindowDesktop || StartupWindowDesktops.Has(newWindow.Hwnd))
            throw Error("Restore moved a disposable window created after the snapshot.")
        if (DllCall(pGetCurrentDesktopNumber, "Int") != originalDesktop)
            throw Error("Restore changed the active virtual desktop.")

        if (DllCall(pMoveWindowToDesktopNumber, "Ptr", windowOnOriginalDesktop.Hwnd, "Int", otherDesktop, "Int") != 1)
            throw Error("Could not move a disposable original for the repeated-restore test.")
        repeatResult := RestoreStartupWindows()
        if (repeatResult.Failed || repeatResult.Restored != 1 || !StartupWindowDesktops.Has(windowOnOriginalDesktop.Hwnd))
            throw Error("A repeated restore did not use and retain the original snapshot.")

        OutputDebug("ScreenPin restore integration passed: inactive capture, move, restore, repeat, closed/new windows and active desktop.")
        FileAppend("Restore integration test passed.`n", "*")
    } finally {
        for testWindow in testWindows
            try testWindow.Destroy()
        StartupWindowDesktops := Map()
        if WindowDestroyHook
            try DllCall("UnhookWinEvent", "Ptr", WindowDestroyHook, "Int")
        if WindowDestroyCallbackPtr
            try CallbackFree(WindowDestroyCallbackPtr)
        if hVDA
            try DllCall("kernel32.dll\FreeLibrary", "Ptr", hVDA)
        if DirExist(testTempDir)
            try DirDelete(testTempDir, true)
    }
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
    global Ready, MaxDesktops, pGetCurrentDesktopNumber, pGoToDesktopNumber, pMoveWindowToDesktopNumber, FixedMonitorIndex, MigrationEpoch

    ; Re-entrancy guard: rapid hotkeys must not stack blocking COM calls
    static busy := false
    if (busy)
        return
    busy := true
    operationEpoch := MigrationEpoch
    try {
        if (!Ready || MaxDesktops < 2)
            return

        current := DllCall(pGetCurrentDesktopNumber, "Int")
        if (current < 0 || current >= MaxDesktops)
            return
        target := direction > 0 ? Mod(current + 1, MaxDesktops) : Mod(current - 1 + MaxDesktops, MaxDesktops)

        ; If there's a fixed monitor, move its windows to target BEFORE switching
        if (FixedMonitorIndex > 0) {
            windows := WinGetList()
            for hwnd in windows {
                if (operationEpoch != MigrationEpoch)
                    return
                if IsWindowOnFixedMonitor(hwnd) {
                    ; Skip hung windows: a COM move against one blocks the main thread forever
                    if (DllCall("IsHungAppWindow", "Ptr", hwnd, "Int"))
                        continue
                    if (operationEpoch != MigrationEpoch)
                        return
                    ; Move window to target desktop
                    DllCall(pMoveWindowToDesktopNumber, "Ptr", hwnd, "Int", target)
                }
            }
        }

        if (operationEpoch != MigrationEpoch)
            return
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
if !InstallWindowDestroyHook() {
    MsgBox "Failed to install the window tracking hook. ScreenPin cannot safely restore startup windows."
    ExitApp
}
snapshotResult := CaptureStartupWindows()
if !snapshotResult.SnapshotReady {
    MsgBox "Failed to capture the startup window snapshot. ScreenPin cannot safely enable pinning."
    ExitApp
}
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
