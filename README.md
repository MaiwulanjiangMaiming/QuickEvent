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

```bash
cd QuickEvent
swift build -c release --arch arm64 --arch x86_64
```

## License

[MIT License](LICENSE)
