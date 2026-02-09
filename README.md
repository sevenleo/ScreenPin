# ScreenPin

**Independent Virtual Desktop Simulation per Monitor for Windows 11**

ScreenPin is a high-performance utility designed to bypass a core limitation of the Windows Virtual Desktop system: the lack of per-monitor isolation. By default, switching virtual desktops in Windows affects all connected monitors simultaneously. 

ScreenPin implements a seamless simulation where a selected "Fixed Monitor" remains static while other monitors transition freely between desktops. This is achieved through a robust **Instant Window Migration** strategy, providing a professional-grade alternative to unstable native "pinning" methods.

## 🚀 Key Features

- **Per-Monitor Isolation:** Keep your reference materials, chat apps, or dashboards fixed on one screen while rotating workflows on others.
- **Instant Window Migration:** Move windows across desktops in micro-seconds, maintaining their exact geometric positions for a "zero-flicker" experience.
- **100% Compatibility:** Works seamlessly with Win32, UWP (Calculator, Settings), and Electron-based applications.
- **Portable & Clean:** Single-file architecture. No installers, no registry changes, and a self-cleaning temporary dependency management system.
- **DPI Aware:** Uses geographic coordinate tracking (X, Y) to ensure precision in complex multi-monitor setups with mixed scaling.

---

## 🛠️ Tech Stack

- **Language:** [AutoHotkey v2.0+](https://www.autohotkey.com/)
- **Core Engine:** [VirtualDesktopAccessor.dll](https://github.com/Ciantic/VirtualDesktopAccessor) (C++ / COM API)
- **Target OS:** Windows 11 (Optimized for builds up to 25H2)
- **Architecture:** 64-bit

---

## 🧠 Architecture & Strategy

### The "Migration" vs "Pinning" Pattern
Traditional attempts to fix windows to a monitor often rely on the native Windows "Pin Window" feature. However, pinning is notoriously unstable: it frequently fails with UWP apps, loses state after OS updates, and can be reset by third-party window managers.

**ScreenPin uses a Direct Migration workflow:**
1. **Selection:** The user designates a "Fixed Monitor" via the startup GUI.
2. **Detection:** The app intercepts native desktop switch events.
3. **Migration:** Micro-seconds before the transition completes, ScreenPin identifies all windows on the fixed monitor.
4. **Relocation:** It programmatically moves these windows to the target virtual desktop at the same geometric coordinates.
5. **Invisibility:** To the user, the windows appear to have never moved, effectively staying "pinned" to the physical screen.

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
1. Download the latest release from the [Releases](/releases) folder (if available) or compile it yourself.
2. Run `ScreenPin.exe`.

### First Run
1. Upon launch, a configuration GUI will appear.
2. Select which monitor you wish to keep "Fixed".
3. Click "None" if you want to temporarily disable the pinning behavior.
4. The app will move to the System Tray.

---

## 🎮 Navigation & Hotkeys

ScreenPin extends the native Windows navigation experience with enhanced hotkey support:

| Hotkey | Action |
| :--- | :--- |
| `Ctrl` + `Win` + `→` / `↑` | **Next Desktop** (Forward) |
| `Ctrl` + `Win` + `←` / `↓` | **Previous Desktop** (Backward) |
| `Ctrl` + `Win` + `Mouse4` | **Next Desktop** |
| `Ctrl` + `Win` + `Mouse5` | **Previous Desktop** |
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
├── todo.md                    # Roadmap and bug tracking
└── releases/                  # Compiled binaries (Git ignored)
```

---

## 🏗️ Developer Guide (Compilation)

To bundle ScreenPin into a single portable `.exe`, use the provided `compile.bat`.

### Compilation Workflow
The build script uses `Ahk2Exe` to:
1. Use the **AutoHotkey v2 64-bit** interpreter as the base.
2. Inject `icon.ico` into the executable resources.
3. Compress the binary and embed the DLL via the `FileInstall` pattern.

```batch
:: Run this in a CMD/PowerShell terminal
compile.bat
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