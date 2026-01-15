# RC Controller

A professional Bluetooth Low Energy (BLE) RC Controller app for IoT devices with 4-arm control system built with Flutter.

## Features

- 🔍 **BLE Device Scanning** - Scan and discover nearby Bluetooth devices
- 📱 **Modern UI** - Clean, professional dark theme interface with tabbed navigation
- 🎮 **Intuitive Controls** - D-pad style control layout with haptic feedback
- 🦾 **4-Arm Control System** - Individual and group control for 4 arms with visual position indicators
- ⚡ **Real-time Commands** - Send commands instantly via BLE
- 🔧 **Configurable** - Select which BLE characteristic to use for communication
- 📝 **Custom Commands** - Send custom text commands to your device
- 🚨 **Emergency Stop** - Quick stop all operations

## Control Tabs

### Movement Tab
Basic directional controls for device movement.

| Button | Command | Description |
|--------|---------|-------------|
| FWD | `F` | Move forward |
| BWD | `B` | Move backward |
| LEFT | `L` | Turn left |
| RIGHT | `R` | Turn right |
| STOP | `S` | Stop movement |
| FAST | `+` | Increase speed |
| SLOW | `-` | Decrease speed |

### Arms Tab
Control system for 4 independent arms with visual position indicators.

#### Group Controls
| Group | Commands | Arms Controlled |
|-------|----------|-----------------|
| Front Arms | `FRONT_UP`, `FRONT_DOWN` | Arms 1 & 2 |
| Back Arms | `BACK_UP`, `BACK_DOWN` | Arms 3 & 4 |

#### Individual Arm Controls
| Arm | Up Command | Down Command | Stop Command |
|-----|------------|--------------|--------------|
| Arm 1 | `ARM1_UP` | `ARM1_DOWN` | `ARM1_STOP` |
| Arm 2 | `ARM2_UP` | `ARM2_DOWN` | `ARM2_STOP` |
| Arm 3 | `ARM3_UP` | `ARM3_DOWN` | `ARM3_STOP` |
| Arm 4 | `ARM4_UP` | `ARM4_DOWN` | `ARM4_STOP` |

**Emergency Stop:** `ALL_STOP` - Stops all arm movements immediately

## Project Structure

```
lib/
├── main.dart                       # App entry point
├── app/
│   └── app.dart                    # MaterialApp configuration
├── theme/
│   └── app_theme.dart              # Dark theme configuration
├── services/
│   └── ble_service.dart            # BLE service singleton
├── screens/
│   ├── home_screen.dart            # Device scanning & selection
│   └── controller_screen.dart      # Tabbed RC control interface
└── widgets/
    ├── widgets.dart                # Barrel export
    ├── control_button.dart         # Movement control buttons
    ├── control_pad.dart            # D-pad layout
    ├── device_card.dart            # Device list item
    ├── connection_status_bar.dart  # Connection info bar
    ├── arm_control_button.dart     # Arm up/down buttons
    ├── arm_position_indicator.dart # Visual arm position display
    └── arms_control_tab.dart       # Arms control interface
```
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
