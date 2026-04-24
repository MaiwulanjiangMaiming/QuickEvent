# QuickEvent

A macOS menu bar app for creating calendar events using natural language.

## Features

- **Natural Language Parsing**: Create events by typing naturally (English, Chinese, Arabic, French, Russian, Spanish)
- **Voice Input**: Speak to create events hands-free
- **Calendar Integration**: Directly add events to your macOS Calendar
- **ICS Export**: Export events as .ics files for sharing
- **Multiple Calendars**: Select from all your calendars (writable and read-only)

## Requirements

- macOS 13.0 or later
- Calendar access permission
- Microphone access (for voice input)

## Installation

1. Download `QuickEvent-1.0.0.dmg`
2. Open the DMG file
3. Drag QuickEvent to your Applications folder
4. Launch QuickEvent from Applications

## Usage

1. Click the calendar icon in the menu bar
2. Type or speak your event (e.g., "Tomorrow 3 PM meeting with John, 1 hour")
3. Select the target calendar
4. Click "Add to Calendar" or "Export ICS"

### Keyboard Shortcuts

- `⌘⇧V`: Toggle voice input
- `Enter`: Parse input

## Building from Source

### Using Xcode (Recommended)

```bash
cd QuickEvent
xcodegen generate        # Generate .xcodeproj (requires XcodeGen)
open QuickEvent.xcodeproj
```

Then select the QuickEvent scheme and press ⌘R to run.

### Using Swift Package Manager

```bash
cd QuickEvent
swift build --disable-sandbox
swift run --disable-sandbox
```

### Prerequisites

- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (for Xcode-based builds)
- Swift 5.9+

## Architecture

QuickEvent follows a clean architecture with clear separation of concerns:

- **Protocols/**: Contract definitions for services (EventParsing, CalendarManaging, ICSExporting, VoiceRecognizing)
- **Parsers/**: Modular natural language parsing pipeline (DateParser, TimeParser, DurationParser, etc.)
- **Managers/**: Application managers (WindowManager, StatusBarManager, HotkeyManager, PermissionManager)
- **State/**: Centralized application state (AppState)
- **Services/**: Core services (EventKitManager, ICSGenerator, AppLogger)
- **Views/Shared/**: Reusable UI components

## License

[MIT License](LICENSE)
