# RC Controller

A professional Bluetooth Low Energy (BLE) RC Controller app for IoT devices built with Flutter.

## Features

- 🔍 **BLE Device Scanning** - Scan and discover nearby Bluetooth devices
- 📱 **Modern UI** - Clean, professional dark theme interface
- 🎮 **Intuitive Controls** - D-pad style control layout with haptic feedback
- ⚡ **Real-time Commands** - Send commands instantly via BLE
- 🔧 **Configurable** - Select which BLE characteristic to use for communication
- 📝 **Custom Commands** - Send custom text commands to your device

## Commands

| Button | Command | Description |
|--------|---------|-------------|
| FWD | `F` | Move forward |
| BWD | `B` | Move backward |
| LEFT | `L` | Turn left |
| RIGHT | `R` | Turn right |
| STOP | `S` | Stop movement |
| FAST | `+` | Increase speed |
| SLOW | `-` | Decrease speed |

## Project Structure

```
lib/
├── main.dart                   # App entry point
├── app/
│   └── app.dart                # MaterialApp configuration
├── theme/
│   └── app_theme.dart          # Dark theme configuration
├── services/
│   └── ble_service.dart        # BLE service singleton
├── screens/
│   ├── home_screen.dart        # Device scanning & selection
│   └── controller_screen.dart  # RC control interface
└── widgets/
    ├── widgets.dart            # Barrel export
    ├── control_button.dart
    ├── control_pad.dart
    ├── device_card.dart
    └── connection_status_bar.dart
```

## Setup

### Prerequisites

- Flutter SDK (>=3.3.0)
- Android Studio / Xcode for mobile development

### Android Configuration

Add these permissions to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
```

Ensure `minSdkVersion` is 21 or higher in `android/app/build.gradle`:

```groovy
android {
    defaultConfig {
        minSdkVersion 21
    }
}
```

### iOS Configuration

Add these entries to `ios/Runner/Info.plist`:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>This app needs Bluetooth to communicate with your RC device</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>This app needs Bluetooth to communicate with your RC device</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location access for Bluetooth scanning</string>
```

## Installation

```bash
# Get dependencies
flutter pub get

# Run on connected device
flutter run
```

## Building

```bash
# Build APK for Android
flutter build apk --release

# Build for iOS
flutter build ios --release
```

## Dependencies

- [flutter_blue_plus](https://pub.dev/packages/flutter_blue_plus) - BLE communication
- [permission_handler](https://pub.dev/packages/permission_handler) - Runtime permissions

## License

This project is part of the StairDoc IoT Project.
