# MeshTrax - Flutter Client

Open-source Flutter client for MeshCore LoRa mesh networking devices.

## Build Commands

```bash
# Install dependencies
~/flutter/bin/flutter pub get

# Run in debug mode
~/flutter/bin/flutter run

# Build Android APK
~/flutter/bin/flutter build apk

# Build iOS
~/flutter/bin/flutter build ios

# Run static analysis
~/flutter/bin/flutter analyze

# Run tests
~/flutter/bin/flutter test
```

## Project Structure

```
lib/
├── main.dart                    # App entry point, MaterialApp setup with Provider
├── connector/
│   └── meshcore_connector.dart  # BLE communication layer (MeshCoreConnector)
├── screens/
│   ├── scanner_screen.dart      # BLE device scanning (home screen)
│   ├── device_screen.dart       # Connected device hub with navigation
│   ├── chat_screen.dart         # Chat interface (placeholder)
│   ├── contacts_screen.dart     # Contacts list (placeholder)
│   └── settings_screen.dart     # Device info and app settings
└── widgets/
    └── device_tile.dart         # Device list item with signal strength
```

## Architecture

### State Management
- **Provider** with `ChangeNotifier` pattern
- `MeshCoreConnector` is the central state holder for BLE connection
- Screens use `Consumer<MeshCoreConnector>` for reactive UI updates

### Theming
- Material 3 design (`useMaterial3: true`)
- System-based dark/light mode (`ThemeMode.system`)
- Blue color scheme seed

## BLE Protocol

### Nordic UART Service (NUS)
- **Service UUID**: `6e400001-b5a3-f393-e0a9-e50e24dcca9e`
- **RX Characteristic**: `6e400002-b5a3-f393-e0a9-e50e24dcca9e` (Write to device)
- **TX Characteristic**: `6e400003-b5a3-f393-e0a9-e50e24dcca9e` (Notify from device)

### Device Discovery
- Scans for devices with known name prefixes
- Filters by `platformName` or `advertisementData.advName`

### Connection States
```dart
enum MeshCoreConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,
  disconnecting,
}
```

### Frame I/O
- **Send**: `MeshCoreConnector.sendFrame(Uint8List data)`
- **Receive**: `MeshCoreConnector.receivedFrames` stream of `Uint8List`

## Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| flutter_blue_plus | ^2.1.0 | BLE communication |
| provider | ^6.1.5+1 | State management |
| cupertino_icons | ^1.0.8 | iOS-style icons |

## Platform Configuration

### Android (`android/app/src/main/AndroidManifest.xml`)
- `BLUETOOTH`, `BLUETOOTH_ADMIN` (API 30 and below)
- `BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT`, `BLUETOOTH_ADVERTISE` (API 31+)
- `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION` (for BLE scanning)

### iOS (`ios/Runner/Info.plist`)
- `NSBluetoothAlwaysUsageDescription`
- `NSBluetoothPeripheralUsageDescription`

## Coding Conventions

### Code Philosophy
- **Minimal**: Only write code that is necessary. Avoid over-engineering.
- **Organized**: Keep related code together. One responsibility per file.
- **Maintainable**: Favor readability over cleverness. Simple is better.

### Style
- Use `StatelessWidget` with `Consumer` for state-dependent UI
- Use `const` constructors where possible
- Prefix private methods/fields with `_`
- Center app bar titles (`centerTitle: true`)
- **Material widgets only** - no Cupertino or custom widgets
- Handle disconnection gracefully (auto-navigate back to scanner)

### Avoid
- Premature abstractions - don't create helpers until needed in 3+ places
- Unnecessary comments - code should be self-explanatory
- Feature flags or backwards-compatibility shims
- Over-engineered error handling for impossible scenarios

## Key Files

| File | Purpose |
|------|---------|
| `lib/connector/meshcore_connector.dart` | All BLE logic - scanning, connecting, data transfer |
| `lib/screens/scanner_screen.dart` | Entry point UI, device list |
| `lib/main.dart` | App configuration, theme, Provider setup |
| `pubspec.yaml` | Dependencies and project metadata |

## Placeholder Screens

The following screens are implemented as placeholders and need full implementation:
- `chat_screen.dart` - Mesh chat functionality
- `contacts_screen.dart` - Contact management
- `settings_screen.dart` - Radio settings, node identity, location (partially implemented)
