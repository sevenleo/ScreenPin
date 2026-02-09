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

✔ **Visual Identity:** Integrated custom icon support for a professional look in the System Tray and Taskbar.

--------------------------------------------------------
🎮 HOTKEYS
--------------------------------------------------------

ScreenPin replaces/extends native Windows shortcuts to ensure fixed monitor logic:

- **Ctrl + Win + → / ↑**  → Next Desktop (Right)
- **Ctrl + Win + ← / ↓**  → Previous Desktop (Left)
- **Ctrl + Win + Mouse4** → Next Desktop
- **Ctrl + Win + Mouse5** → Previous Desktop
- **Ctrl + Win + Delete** → Restart Script (Back to selection screen)

--------------------------------------------------------
🎨 ACKNOWLEDGMENTS (ICONS)
--------------------------------------------------------

The icons used in this project were sourced from **Flaticon**:
- [Pin Icon (Main)](https://www.flaticon.com/br/icone-gratis/pin_889668?term=pin&related_id=889668)
- [Alternative Pin Icon](https://www.flaticon.com/br/icone-gratis/pin_5439377?related_id=5439455&origin=search)

--------------------------------------------------------
🖥️ REQUIREMENTS AND DEPENDENCIES
--------------------------------------------------------

- **AutoHotkey v2.0+**
- **VirtualDesktopAccessor.dll** (Included in the project)
- **Windows 11** (Tested and optimized for latest builds, including 25H2)

The project relies on the `VirtualDesktopAccessor` DLL by **Ciantic**, which provides the necessary bridge to Windows internal Virtual Desktop APIs.

--------------------------------------------------------
⚠️ PERFORMANCE NOTE
--------------------------------------------------------

The script is optimized to perform window migration asynchronously and immediately, minimizing any visual "flicker". For the best experience, it is recommended to disable desktop switch animations in Windows accessibility settings if you seek an instant transition.

--------------------------------------------------------
📌 CONCLUSION
--------------------------------------------------------

ScreenPin delivers the most requested feature by multi-monitor users: the ability to keep a workflow fixed on one screen while exploring different contexts on others. Simple, robust, and essential for advanced productivity.