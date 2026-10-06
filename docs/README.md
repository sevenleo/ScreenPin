# ScreenPin

**Independent Virtual Desktop Simulation per Monitor for Windows 11**

ScreenPin simulates per-monitor isolation by moving windows on a selected monitor before a virtual desktop switch made through ScreenPin's own shortcuts. Windows does not provide a per-monitor virtual desktop switch through this app.

When one of ScreenPin's desktop-switch shortcuts is used, windows on the selected "Fixed Monitor" are moved to the destination desktop before ScreenPin switches desktops.

## 🚀 Key Features

- **Per-Monitor Isolation:** Keep your reference materials, chat apps, or dashboards fixed on one screen while rotating workflows on others.
- **Window Migration:** Move windows on the selected monitor to the destination desktop before switching.
- **Session Restore:** Return windows that were open at startup to their original virtual desktops with **Restore** or when ScreenPin exits normally. Windows opened later are left untouched.
- **Portable & Clean:** Single-file architecture. No installers, no registry changes, and a self-cleaning temporary dependency management system.
- **Monitor Selection:** Uses each window's screen position to determine whether it is on the selected monitor.

---

## 🛠️ Tech Stack

- **Language:** [AutoHotkey v2.0+](https://www.autohotkey.com/)
- **Core Engine:** [VirtualDesktopAccessor.dll](https://github.com/Ciantic/VirtualDesktopAccessor) (Windows virtual desktop interfaces)
- **Target OS:** Windows 11; virtual desktop API support depends on the installed Windows build and bundled DLL.
- **Architecture:** 64-bit

---

## 🧠 Architecture & Strategy

### Migration instead of native pinning
ScreenPin does not use Windows' native "Pin Window" feature. It moves windows when the user switches desktops with ScreenPin's shortcuts.

**ScreenPin uses a shortcut-driven migration workflow:**
1. **Selection:** The user designates a "Fixed Monitor" via the configuration window. ScreenPin gathers visible windows on that monitor from every virtual desktop and moves them to the desktop that is active at selection time. Windows on other monitors stay in place.
2. **Shortcut:** The user switches desktops with one of ScreenPin's configured shortcuts.
3. **Migration:** ScreenPin identifies windows on the fixed monitor and moves them to the destination virtual desktop.
4. **Switch:** ScreenPin switches to that desktop after attempting the migration.

ScreenPin does not intercept desktop switches made through Win+Tab, Windows gestures, or other applications.

### Session Restore
At startup, ScreenPin records the process ID and virtual desktop GUID for eligible visible application windows across all desktops, including minimized windows and windows on inactive desktops. It keeps this original snapshot in memory for the session. When a monitor is selected, the app separately enumerates the windows then present across all desktops and gathers those on the selected monitor; this includes windows opened after ScreenPin started but before monitor selection.

Choose **Restore** from the tray menu or configuration window to disable migration and move still-valid startup windows to their original desktops. Restore leaves the app open and retains the original snapshot, so it can be repeated. Selecting **None (Windows Default)** only disables migration; restoration then happens on normal exit. Windows opened after startup are not added to the restore snapshot and remain where they are when Restore or Exit runs, even if pinning or a shortcut moved them earlier. Closed windows and windows whose original desktop was removed are skipped. ScreenPin reports individual failures and continues with other windows. A crash or forced process termination cannot guarantee restoration.

### Single-File Portable Design
ScreenPin embeds its binary dependencies (`VirtualDesktopAccessor.dll`) directly into the executable. 
- On startup, it extracts the DLL to `%TEMP%\ScreenPin\`.
- It loads the DLL functions into the process memory.
- On exit, it releases the handles and deletes the temporary files, leaving the host system untouched.

---

## 🖱️ Getting Started

### Prerequisites
- **For the Executable:** No prerequisites. Just run `ScreenPin.exe`.
- **For the Script:** [AutoHotkey v2.0+](https://www.autohotkey.com/v2/) installed.

### Installation
1. Download the latest release from the [Releases](/releases) folder (if available) or build it yourself with `compile.bat` (requires AutoHotkey v2).
2. Run `ScreenPin.exe`.

### First Run
1. Upon launch, a configuration GUI will appear.
2. Select which monitor you wish to keep "Fixed". Visible windows on that monitor are gathered from all virtual desktops and moved to the currently active desktop.
3. Click "None" if you want to temporarily disable migration without restoring windows immediately.
4. Click "Restore" to disable migration and immediately return startup windows to their original virtual desktops while keeping ScreenPin open.
5. The app will move to the System Tray.

The tray menu also provides **Restore**, **Settings (Change Monitor)**, and **Exit**. Exit restores the startup windows before closing. Choosing **None** does not restore until the app exits normally.

---

## 🎮 Navigation & Hotkeys

These shortcuts are handled by ScreenPin and only affect desktop changes initiated with them:

| Hotkey | Action |
| :--- | :--- |
| `Ctrl` + `Win` + `→` / `↑` | **Next Desktop** (Forward) |
| `Ctrl` + `Win` + `←` / `↓` | **Previous Desktop** (Backward) |
| `Ctrl` + `Win` + `Mouse4` | **Next Desktop** |
| `Ctrl` + `Win` + `Mouse5` | **Previous Desktop** |
| `Right Mouse` + `Mouse4` + `WheelDown` | **Next Desktop** (debounced) |
| `ScrollLock` (double tap) | **Next Desktop** (mantém função nativa da tecla) |
| `Ctrl` + `Win` + `Delete` | **Emergency Reset** / Change Fixed Monitor |

---

## 📂 Project Structure

```text
D:\GITHUB\ScreenPin\
├── ScreenPin.ahk             # Main application logic (AHK v2)
├── VirtualDesktopAccessor.dll # Core engine for Windows COM interaction
├── compile.bat                # Build script for single-file EXE
├── icon.ico                   # Application icon (embedded during build)
├── README.md                  # Professional documentation
├── CHANGELOG.md               # Release history
├── todo.md                    # Roadmap and bug tracking
└── releases/                  # Compiled binaries (Git ignored)
```

---

## 🔍 Troubleshooting

### DLL Load Errors
If you receive a "Failed to load DLL" message:
1. Ensure you are running on a 64-bit version of Windows.
2. Check if your Antivirus is blocking the `%TEMP%` folder extraction.
3. Try running as Administrator if permissions are restricted.

### Windows 11 Updates
Microsoft frequently changes the internal COM IDs for Virtual Desktops. If ScreenPin stops working after a major Windows Update, a new version of `VirtualDesktopAccessor.dll` may be required. Check the [Ciantic repository](https://github.com/Ciantic/VirtualDesktopAccessor) for updates.

---

## 🙏 Credits

- **Virtual Desktop Access:** The core COM interaction is handled by the excellent work of **[Ciantic](https://github.com/Ciantic)** and the contributors of [VirtualDesktopAccessor](https://github.com/Ciantic/VirtualDesktopAccessor).
- **Icons:** Sourced from [Flaticon](https://www.flaticon.com/) (Freepik & uicon).

---

## 📜 License
This project is open-source. See individual files for specific dependency licenses.
