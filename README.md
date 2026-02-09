========================================================
SCREENPIN – DESKTOP PER MONITOR (WINDOWS 11)
Independent Virtual Desktop Simulation per Monitor
========================================================

📌 OVERVIEW

ScreenPin is a high-performance utility designed to bypass a core limitation of Windows 10/11: the lack of per-monitor virtual desktop isolation. By default, switching virtual desktops affects all connected monitors simultaneously.

ScreenPin implements a seamless simulation where one monitor remains "static" (fixed) while others transition freely. This is achieved through a robust **Instant Window Migration** strategy, making it a professional-grade alternative to unstable "pinning" methods.

--------------------------------------------------------
🎯 CORE STRATEGY: DIRECT WINDOW MIGRATION
--------------------------------------------------------

Unlike traditional solutions that rely on the Windows "Pin Window" feature (which often fails with UWP apps or loses state after OS updates), ScreenPin uses a high-speed migration technique:

1.  **Selection:** The user defines a "Fixed Monitor".
2.  **Detection:** The app monitors native Windows desktop switch events.
3.  **Migration:** Micro-seconds before the desktop transition completes, ScreenPin identifies every window currently visible on the fixed monitor and programmatically moves them to the target virtual desktop.
4.  **Invisibility:** Because the windows are moved to the same geometric coordinates on the new desktop, they appear to have never moved at all.

This approach ensures 100% compatibility with **Win32**, **UWP (Calculators, Settings)**, and **Electron** apps.

--------------------------------------------------------
🧠 KEY TECHNICAL FEATURES (MODEL DESIGN)
--------------------------------------------------------

✔ **Geometric Window Tracking:** Uses geographic screen coordinates (X, Y, Width, Height) instead of simple monitor indices. This ensures precision in complex setups with mixed DPI scaling.
✔ **Silent Dependency Injection:** The core engine (`VirtualDesktopAccessor.dll`) is embedded directly into the executable and managed via a "Self-Cleaning Temp Pattern".
✔ **Event-Driven UI:** A modern, single-column GUI built with AHK v2 that adapts its height dynamically based on the number of detected monitors.
✔ **Zero-Clutter Architecture:** Designed to run as a single file. No installers, no registry changes, and no leftover files in the application folder.

--------------------------------------------------------
🖱️ SYSTEM TRAY & UX PATTERNS
--------------------------------------------------------

ScreenPin follows modern UX standards for background utilities:

- **Single Left-Click:** Instantly re-opens the Configuration GUI. This allows for rapid workflow changes (e.g., swapping which monitor is fixed during a meeting).
- **Right-Click Menu:** A minimalist context menu providing only essential controls (**Settings** and **Exit**).
- **Smart Lifecycle:** If the user closes the initial configuration window without making a selection, the application terminates immediately rather than idling in the tray.
- **Visual Feedback:** Uses a dedicated icon in the tray with a descriptive tooltip for easy identification among system processes.

--------------------------------------------------------
🎮 SUPPORTED HOTKEYS
--------------------------------------------------------

The app extends the native Windows desktop navigation experience:

- **Ctrl + Win + → / ↑**  → Next Desktop (Forward)
- **Ctrl + Win + ← / ↓**  → Previous Desktop (Backward)
- **Ctrl + Win + Mouse4** → Next Desktop
- **Ctrl + Win + Mouse5** → Previous Desktop
- **Ctrl + Win + Delete** → Emergency Reset / Change Fixed Monitor

--------------------------------------------------------
🚀 COMPILATION & BUNDLING (DEVELOPER GUIDE)
--------------------------------------------------------

This project serves as a reference for creating **Single-File Portable AHK v2 Applications**.

### The "FileInstall" Pattern
Since Windows cannot load DLLs directly from RAM, ScreenPin uses the following workflow:
1.  **Embedding:** During compilation, `FileInstall` bakes the DLL and assets into the `.exe`.
2.  **Silent Extraction:** On startup, the app creates a private folder in `%TEMP%\ScreenPin\`.
3.  **Runtime Loading:** The DLL is loaded into the process from this temp path.
4.  **Auto-Cleanup:** An `OnExit` hook ensures that when the app closes, it releases the DLL handle and deletes the temp folder, leaving the user's system clean.

### Compiling with AHK v2
Use the provided `compile.bat`. It is configured to:
- Use the **AutoHotkey v2 64-bit** interpreter as the binary base.
- Embed the high-resolution `icon.ico` into the file resources.
- Output the final binary to the `/releases` folder (automatically ignored by Git).

--------------------------------------------------------
🎨 VISUAL ASSETS
--------------------------------------------------------

The visual identity of ScreenPin relies on professional iconography to ensure it feels like a native system tool. 

**Icons sourced from Flaticon:**
- **Primary App Icon:** [Created by Freepik](https://www.flaticon.com/br/icone-gratis/pin_889668?term=pin&related_id=889668)
- **Secondary Assets:** [Created by uicon](https://www.flaticon.com/br/icone-gratis/pin_5439377?related_id=5439455&origin=search)

*Note: The icon is embedded into the EXE resources, so the `.ico` file is not required for distribution.*

--------------------------------------------------------
🙏 CREDITS
--------------------------------------------------------

### Core Engine
The heavy lifting of Windows COM API interaction is handled by the **VirtualDesktopAccessor.dll**, maintained by **[Ciantic](https://github.com/Ciantic)**.
- **Repository:** [Ciantic/VirtualDesktopAccessor](https://github.com/Ciantic/VirtualDesktopAccessor)

--------------------------------------------------------
🖥️ REQUIREMENTS
--------------------------------------------------------

- **OS:** Windows 11 (Optimized for builds up to 25H2).
- **Runtime:** AutoHotkey v2.0+ (Only required for running the `.ahk` source).
- **Architecture:** 64-bit.

--------------------------------------------------------
📌 CONCLUSION
--------------------------------------------------------

ScreenPin is more than just a utility; it is a demonstration of how to extend Windows functionality with precision and care. By combining low-level DLL calls with high-level AHK scripting and professional UX patterns, it delivers a feature that remains missing from the native OS experience.
