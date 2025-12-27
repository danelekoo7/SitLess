# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SitLess is a Garmin Connect IQ widget that provides gentle move reminders by monitoring steps in a rolling time window. The app runs as a background service on Garmin watches and alerts users when their step count falls below a configured threshold during active hours.

**Language:** Monkey C (Garmin Connect IQ SDK)
**App Type:** Widget with Background Service and Glance View
**Min API Level:** 3.2.0
**Supported Languages:** English, Polish

## Project Documentation

Implementation plan and detailed development notes are located in the parent folder:
- `../AI/implementation-plan.md` - Step-by-step implementation guide with checkpoints

## Development Commands

### Building and Testing
This project uses the Visual Studio Code Connect IQ extension. Use the following commands from the VS Code command palette:

**Build:**
- "Monkey C: Build for Device" - Build for specific device
- "Monkey C: Run" - Run in simulator
- Build configuration: `monkey.jungle`
- Manifest configuration: `manifest.xml`

**Testing:**
- Use Connect IQ simulator for testing
- Test on both MIP (e.g., Fenix) and AMOLED (e.g., Epix/Venu) displays
- Monitor memory usage: File → View memory in simulator
- Check compiled app size - it counts toward device memory limits
- Test different screen resolutions to ensure compatibility

**Editing Configuration:**
- "Monkey C: Edit Application" - Update app attributes in manifest
- "Monkey C: Set Products by Product Category" - Add device categories
- "Monkey C: Edit Products" - Add/remove specific devices
- "Monkey C: Edit Permissions" - Update required permissions
- "Monkey C: Edit Languages" - Configure supported languages

## Architecture

### Core Components

**Application Entry Point** (`source/sitlessApp.mc`)
- Main application class extending `Application.AppBase`
- Manages app lifecycle (onStart, onStop)
- Returns initial view via `getInitialView()`

**Widget View** (`source/sitlessView.mc`)
- Main UI view extending `WatchUi.View`
- Uses XML layout from `resources/layouts/layout.xml`
- Handles onUpdate, onShow, onHide lifecycle

**Implemented Components:**
- `source/SitlessServiceDelegate.mc` - Background service for step monitoring
- `source/StepBuffer.mc` - Rolling window step buffer implementation
- `source/SitlessInputDelegate.mc` - Input handling and settings menu access
- `source/SitlessSettingsMenu.mc` - Settings menu delegates and pickers
- `source/SettingsManager.mc` - Centralized settings access
- `source/AlertManager.mc` - Alert decision logic (checks notifications, active hours, step threshold)
- `resources/settings/settings.xml` - Settings UI definition (properties + settings combined)

**Planned Components** (not yet implemented):
- `source/SitlessGlanceView.mc` - Glance view for quick status

### Resource Structure

```
resources/
├── drawables/    # Graphics and icons
├── layouts/      # XML UI layouts
└── strings/      # Localized strings (EN, PL)
```

Resources are referenced using `Rez.*` namespace (e.g., `Rez.Layouts.MainLayout(dc)`, `Rez.Strings.AppName`)

### Background Service Architecture

The app will use Connect IQ's background service system:
- Service runs periodically (~5 minutes as allowed by platform)
- Maintains in-memory buffer of step counts for rolling window (default: 60 minutes)
- Uses `Application.Storage` for persistence between service invocations
- Checks exclusion conditions before alerting (DND, sleep, activity, off-wrist)

**Background Service Memory Constraints:**
- Background services have memory limits of 32KB or 64KB depending on device
- Approximately 4KB less is actually available (VM overhead)
- Background code gets loaded with main app, reducing main app available memory
- Data returned via `Background.exit()` is limited to ~8KB
- Minimize global variables and AppBase code - they're included in background
- Set a timeout of ~30ms and exit preemptively to avoid Watchdog timer kills

**Storage API:**
- Standard storage: ~6KB total
- New Storage API (SDK 2.4+): up to 100KB total
- Each storage item must be under 8KB
- Use for persisting step buffer data between background invocations

### Settings & Configuration

Settings can be configured in two ways:
- **On the watch:** Long-press UP button in widget to open settings menu
- **Via Garmin Connect Mobile app:** Settings section for the app

Available settings:
- `notificationsEnabled` - Enable/disable vibration alerts (default: true). When disabled, app works as step tracker only without alerts.
- `minSteps` - Minimum steps per window (default: 50)
- `timeWindow` - Rolling window in minutes (default: 60)
- `startHour` - Active hours start (default: 7)
- `endHour` - Active hours end (default: 21)

Access via `Toybox.Application.Properties`

## Monkey C Coding Conventions

### Language
- **All source code files (*.mc) must be in English** - variable names, function names, comments
- Documentation files (*.md) in the AI/ folder can be in Polish
- User-facing strings in resources/strings/ are localized (EN, PL)

### Naming
- Classes: PascalCase (e.g., `SitlessApp`, `StepMonitorService`)
- Functions: camelCase (e.g., `getStepCount`, `onUpdate`)
- Class fields: camelCase with prefix (e.g., `_stepBuffer`, `mSettings`)
- Constants: SCREAMING_SNAKE_CASE (e.g., `DEFAULT_STEP_GOAL`)

### Type System
- Monkey C is statically typed - always declare types
- Use `as` for type casting and declarations
- Check nullability with `instanceof` or `!= null`
- Use `?` suffix for nullable types (e.g., `var _lastUpdate as Time.Moment?`)

### Key Toybox Modules

**Essential imports:**
- `Toybox.Application` - App lifecycle
- `Toybox.WatchUi` - UI (View, Glance, InputDelegate)
- `Toybox.Background` - Background services
- `Toybox.ActivityMonitor` - Step counts via `ActivityMonitor.getInfo()`
- `Toybox.System` - Device settings (DND, sleep, etc.)
- `Toybox.Attention` - Vibrations and alerts
- `Toybox.Application.Properties` - Settings persistence

**Supporting modules:**
- `Toybox.Time` - Time operations
- `Toybox.Graphics` - Drawing
- `Toybox.Lang` - Core types

## Widget Lifecycle and Performance

### Lifecycle Method Order

Widget lifecycle follows this sequence:
1. `initialize()` - Constructor, called once
2. `onLayout(dc)` - Set up UI layout
3. `onShow()` - View is displayed
4. `onUpdate(dc)` - Redraw the view
5. `onHide()` - View is hidden (may not always be called)

**Important Notes:**
- When switching between widgets/apps, the entire lifecycle runs from scratch
- `onHide()` is NOT called when switching from watchface to widget
- Use `onStop()` in AppBase to save critical state, not just `onHide()`
- Widget is recreated each time it's displayed

### Performance Optimization

**Critical Performance Rule - onUpdate Flag:**
Set a flag in `onShow()` and `onHide()` to control whether `onUpdate()` should execute:
```monkeyc
private var _isVisible as Boolean = false;

function onShow() as Void {
    _isVisible = true;
}

function onHide() as Void {
    _isVisible = false;
}

function onUpdate(dc as Dc) as Void {
    if (!_isVisible) {
        return; // Skip update when widget is not shown
    }
    View.onUpdate(dc);
    // Your drawing code...
}
```

**Why this matters:** `onUpdate()` can be called even when the widget is not visible (e.g., when cycling through widgets). This is the main cause of sluggish performance.

**Drawing Optimization:**
- Pre-calculate values once in `onLayout()`, store in instance variables
- Draw from cached values in `onUpdate()` - avoid calculations during drawing
- Complex graphics (many polygons/texts) can take 700ms to render
- Slow rendering prevents user interaction ("when image is drawn, you cannot navigate")
- Release resources in `onHide()` to reduce memory footprint for other widgets

**UI Update Frequency:**
- Widget `onUpdate()` is called when view needs refresh
- Use `WatchUi.requestUpdate()` sparingly - triggers redraw
- Minimize redraw frequency to save battery

## Alert Exclusion Logic

Do NOT send alerts when:
1. Notifications are disabled: `SettingsManager.getNotificationsEnabled()` returns false
2. Do Not Disturb is enabled: `System.getDeviceSettings().doNotDisturb`
3. Sleep mode is active: `deviceSettings.isSleepModeEnabled` (if available on device)
4. Activity recording in progress: `Activity.getActivityInfo().timerState != TIMER_STATE_OFF`
5. Watch is off-wrist (best effort): `Sensor.getInfo().heartRate == null` - helps avoid alerts while charging

## Memory and Battery Constraints

**Memory Limits:**
- Device memory varies widely: 16-128KB depending on model
- Example: Fenix 5 has 92KB for watch faces, 28KB for data fields
- Compiled app size (code + resources + fonts + strings) counts toward limit
- Apps exceeding memory limits will be closed by the system
- Monitor memory in simulator: File → View memory
- Check `System.getSystemStats().usedMemory` and `.freeMemory` at runtime
- Consider dynamic caching based on available memory

**Memory Management Best Practices:**
- Avoid large arrays and objects
- Pre-calculate and cache values instead of recalculating
- Release resources in `onHide()` and `onStop()`
- Avoid lengthy copy-pasted code - increases compiled size
- Load resources (images, fonts) only during initialization
- For web requests: JSON → Dictionary conversion doubles memory usage temporarily
- Store large data in `Application.Storage` instead of keeping in memory

**Battery Optimization:**
- Minimize UI update frequency
- Use `WatchUi.requestUpdate()` only when necessary
- Keep background service execution fast (<30ms) and lightweight
- Avoid complex calculations during drawing
- Reduce polygon and text rendering complexity

**Screen Compatibility:**
- Use relative positioning (percentages, not fixed pixels)
- Test on both MIP (Memory-in-Pixel) and AMOLED displays
- Implement AMOLED burn-in protection:
  - Dark backgrounds
  - Avoid static elements in same position
  - Use dark theme as default

## UI Requirements

**Glance View:**
- Simple progress display for current rolling window
- Show step count and goal at a glance
- Minimal design for quick reference

**Widget View:**
- Full visualization with progress bar or circular indicator
- Display current steps in window vs. goal
- Show time until next check or alert status
- Snooze functionality (delay next alert by 10 minutes)

**Input Handling:**
- Design for button-only input (no touch assumed)
- Use `WatchUi.InputDelegate` for handling button presses
- Support physical buttons on all device types

**Visual Design:**
- Dark theme by default (battery-friendly, AMOLED-safe)
- High contrast for MIP display readability
- Minimal graphics to reduce memory and rendering time

## Required Permissions

The manifest.xml must include:
```xml
<iq:permissions>
    <iq:uses-permission id="Background"/>
    <iq:uses-permission id="Sensor"/>
</iq:permissions>
```

**Why these permissions:**
- `Background` - Allows periodic background service for step monitoring
- `Sensor` - Required for off-wrist detection via HR sensor (used to avoid alerts while charging)

**Note:** `ActivityMonitor` API does not require any special permissions - it's available directly as part of the Connect IQ API. The `FitContributor` permission is only needed for *writing* data to FIT files, not for reading step counts.

## Device Support

The app targets 100+ Garmin devices including Fenix, Forerunner, Epix, Venu, Instinct, MARQ, and Edge series. Full device list is in `manifest.xml`.

## Error Handling

**General Practices:**
- Always null-check before accessing objects
- Use `instanceof` or `!= null` checks for nullable types
- Wrap I/O operations in try/catch blocks
- Log errors with `System.println()` for debugging (visible in simulator)
- Gracefully handle API unavailability on older devices

**Common Scenarios:**
```monkeyc
// Null checking
var info = ActivityMonitor.getInfo();
if (info != null && info.steps != null) {
    var steps = info.steps;
}

// Try/catch for storage
try {
    Storage.setValue("key", data);
} catch (e) {
    System.println("Storage error: " + e.getErrorMessage());
}

// API availability check
if (Toybox has :ActivityMonitor) {
    // Use ActivityMonitor API
}
```

**Background Service Error Handling:**
- Monitor execution time to avoid Watchdog timeout
- Exit gracefully if approaching 30ms limit
- Handle null data from previous invocations
- Validate stored data before using

## Reference Documentation

**Official Resources:**
- API Documentation: https://developer.garmin.com/connect-iq/api-docs/
- Programmer's Guide: https://developer.garmin.com/connect-iq/programmers-guide/
- Core Topics: https://developer.garmin.com/connect-iq/core-topics/
- User Experience Guidelines: https://developer.garmin.com/connect-iq/user-experience-guidelines/

**Key Topics to Reference:**
- Background Services: Core Topics → Backgrounding
- Glance Views: Core Topics → Glances
- Memory Management: Programmer's Guide → Memory
- Storage API: API Docs → Toybox.Application.Storage
