# HelmRC

A Bluetooth RC controller by **KNURDZ Community**. HelmRC drives **BLE UART** cars on Android and iOS, and **Bluetooth Classic serial (SPP)** cars on Android, when the car speaks a selected command profile.

It does **not** claim every branded toy car. Encrypted or proprietary protocols (many store-bought RC toys) will not work. It covers the cars people can actually open: ESP32 BLE UART, Arduino + HC-05/HC-06, and a user-defined serial map.

## Features

- User-selectable **BLE** or **Classic** radio (Classic is Android-only; iOS stays BLE)
- Command profiles: HelmRC, Arduino UART, Numeric, and Custom
- BLE scan, connect, and TX characteristic selection
- Classic paired-first device list and RFCOMM/SPP writes
- Hold-to-move driving with automatic stop on release
- 4-arm individual and group controls (sent only if the profile maps them)
- Emergency stop always visible while connected
- Fail-safe stop on disconnect, back navigation, and app backgrounding
- Portrait lock, keep-awake while controlling, and signal-strength BLE list

## Compatibility

| Radio | Platforms | Typical hardware |
|-------|-----------|------------------|
| BLE UART | Android, iOS | ESP32 Nordic UART / similar GATT TX |
| Classic SPP | Android only | HC-05, HC-06, Arduino Bluetooth serial |

Pick a **car profile** so the pads send bytes the firmware expects. Unmapped buttons are skipped instead of sending HelmRC strings to a car that does not understand them.

## Command profiles

Same pads, different wire bytes:

| Profile | Forward | Notes |
|---------|---------|--------|
| HelmRC | `F` | Current map, no newline |
| Arduino UART | `F\n` | Common HC-05 sketches: `F/B/L/R/S/+/-` plus newline |
| Numeric | `1\n` | Hobby `1/2/3/4/0` sketches |
| Custom | user-defined | Edit each button locally; optional newline |

### HelmRC logical pads

| Button | Logical key | HelmRC bytes |
|--------|-------------|--------------|
| FWD | `F` | `F` while held; `S` on release |
| BWD | `B` | `B` while held; `S` on release |
| LEFT | `L` | `L` while held; `S` on release |
| RIGHT | `R` | `R` while held; `S` on release |
| STOP | `S` | Immediate halt |
| FAST | `+` | Speed up |
| SLOW | `-` | Slow down |

### Arms (HelmRC profile)

| Control | Up | Down | Release |
|---------|----|------|---------|
| Front (1 & 2) | `FRONT_UP` | `FRONT_DOWN` | `ARM1_STOP`, `ARM2_STOP` |
| Back (3 & 4) | `BACK_UP` | `BACK_DOWN` | `ARM3_STOP`, `ARM4_STOP` |
| Arm n | `ARMn_UP` | `ARMn_DOWN` | `ARMn_STOP` |

Emergency stop sends the profile’s fail-safe mapping (`S` then `ALL_STOP` on HelmRC; stop only on Numeric).

## Run

Requires a physical Android or iOS device with Bluetooth. Simulators do not support BLE or Classic well. Classic serial needs Android 8+ (API 26).

```bash
flutter pub get
flutter devices
flutter run
```

## Build

```bash
flutter build apk --release
flutter build ios --release
```

## Project structure

```
lib/
├── main.dart
├── app/
├── theme/app_theme.dart
├── commands/rc_commands.dart
├── profiles/
├── radio/
├── models/
├── screens/
└── widgets/
```

## License

Developed by KNURDZ Community.
