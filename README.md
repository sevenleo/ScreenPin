========================================================
SCREENPIN – DESKTOP PER MONITOR (WINDOWS 11)
Independent Virtual Desktop Simulation per Monitor
========================================================

📌 OVERVIEW

ScreenPin (formerly Desktop Per Monitor) is an advanced solution to bypass the Windows 11 Virtual Desktop limitation, where switching desktops affects all monitors globally.

Unlike solutions based on window "Pinning" (which can be unstable in recent Windows versions like 25H2), this project uses an **instant window migration** technique.

The result is a seamless simulation where one monitor stays "fixed" while others switch freely between virtual desktops, with no stuck windows or system leftovers.

--------------------------------------------------------
🎯 THE NEW STRATEGY (DIRECT MOVEMENT)
--------------------------------------------------------

The logic has evolved to ensure 100% compatibility and performance:

1.  **Fixed Monitor:** You choose which monitor should keep its windows static.
2.  **Pre-Switch Migration:** In the exact millisecond before switching desktops, the script identifies windows on the fixed monitor and moves them to the target desktop.
3.  **Transparent Transition:** Windows switches desktops, but since the windows on the fixed monitor "are already there", they appear to have never moved.

This approach is much more robust for UWP windows (Calculator, Settings, Terminal) and avoids focus bugs.

--------------------------------------------------------
🧠 TECHNICAL FEATURES
--------------------------------------------------------

✔ **Smart Selection:** Modern Graphical User Interface (GUI) to choose the fixed monitor on startup.
✔ **Geometric Detection:** Uses geographic coordinates (X, Y) to identify windows, ensuring precision even on monitors with different scales (DPI).
✔ **High Compatibility:** Works with traditional Win32 windows and modern apps (UWP).
✔ **No Leftovers:** Does not change Windows registries or leave windows permanently "pinned".

✔ **Visual Identity:** Integrated custom icon support for a professional look. The icon is embedded directly into the executable resources.
✔ **Clean Workspace:** No more clutter. Dependencies are managed silently in the background.

--------------------------------------------------------
🎮 HOTKEYS
--------------------------------------------------------

ScreenPin replaces/extends native Windows shortcuts to ensure fixed monitor logic:

- **Ctrl + Win + → / ↑**  → Next Desktop (Right)
- **Ctrl + Win + ← / ↓**  → Previous Desktop (Left)
- **Ctrl + Win + Mouse4** → Next Desktop
- **Ctrl + Win + Mouse5** → Previous Desktop
- **Ctrl + Win + Delete** → Restart / Change Fixed Monitor

--------------------------------------------------------
🚀 COMPILATION & PORTABILITY
--------------------------------------------------------

ScreenPin is a **Zero-Clutter Portable Application**.

- **Silent Dependency Management:** The required `VirtualDesktopAccessor.dll` is embedded inside the EXE. 
- **Temp Extraction:** When launched, the app silently extracts the DLL to `%TEMP%\ScreenPin\`. 
- **Auto-Cleanup:** Upon closing or restarting the app, it automatically deletes its temporary folder and files, leaving your system exactly as it found it.
- **Single File:** You only need to distribute the `ScreenPin.exe` found in the `releases/` folder.

**To compile the project yourself:**
1. Ensure you have **AutoHotkey v2** installed.
2. Run the `compile.bat` file.
3. The compiler will use `ScreenPin.ahk` as the source and generate the final binary.

--------------------------------------------------------
🙏 CREDITS & ACKNOWLEDGMENTS
--------------------------------------------------------

### Core Engine
This project would not be possible without the **VirtualDesktopAccessor.dll**, a remarkable piece of engineering by **[Ciantic](https://github.com/Ciantic)**. It provides the low-level bridge to Windows' internal Virtual Desktop COM API. 
- **Repository:** [Ciantic/VirtualDesktopAccessor](https://github.com/Ciantic/VirtualDesktopAccessor)

### Visual Assets
The professional iconography for ScreenPin was sourced from **Flaticon**. Special thanks to the designers of:
- **Primary Pin Icon:** [Created by Freepik](https://www.flaticon.com/br/icone-gratis/pin_889668?term=pin&related_id=889668)
- **Secondary Pin Icon:** [Created by uicon](https://www.flaticon.com/br/icone-gratis/pin_5439377?related_id=5439455&origin=search)

We sincerely appreciate the open-source contributors and designers whose work empowers the community to build better tools.

--------------------------------------------------------
🖥️ REQUIREMENTS & STACK
--------------------------------------------------------

- **AutoHotkey v2.0+**
- **VirtualDesktopAccessor.dll** (Pre-bundled)
- **Windows 11** (Optimized for builds up to 25H2)

--------------------------------------------------------
⚠️ PERFORMANCE NOTE
--------------------------------------------------------

The script is optimized to perform window migration asynchronously and immediately, minimizing any visual "flicker". For the best experience, it is recommended to disable desktop switch animations in Windows accessibility settings if you seek an instant transition.

--------------------------------------------------------
📌 CONCLUSION
--------------------------------------------------------

ScreenPin delivers the most requested feature by multi-monitor users: the ability to keep a workflow fixed on one screen while exploring different contexts on others. Simple, robust, and essential for advanced productivity.