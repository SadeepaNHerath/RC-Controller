import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/ble_prep_result.dart';

Future<bool> requestRadioPermissions() async {
  try {
    if (Platform.isIOS || Platform.isMacOS) {
      final bluetooth = await Permission.bluetooth.request();
      return bluetooth.isGranted || bluetooth.isLimited;
    }

    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    bool allowed(Permission permission) {
      final status = statuses[permission];
      return status == PermissionStatus.granted ||
          status == PermissionStatus.limited ||
          status == PermissionStatus.restricted ||
          status == PermissionStatus.provisional;
    }

    // Location is requested for older Android / Classic inquiry, but denying
    // it must not block BLE (neverForLocation) or already-paired Classic.
    return allowed(Permission.bluetoothScan) &&
        allowed(Permission.bluetoothConnect);
  } catch (error) {
    debugPrint('Permission request failed: $error');
    return false;
  }
}

Future<BlePrepResult> ensureBluetoothAdapterOn() async {
  try {
    var adapterState = FlutterBluePlus.adapterStateNow;
    if (adapterState == BluetoothAdapterState.unknown) {
      try {
        adapterState = await FlutterBluePlus.adapterState.first
            .timeout(const Duration(seconds: 3));
      } on TimeoutException {
        adapterState = BluetoothAdapterState.unknown;
      }
    }

    if (adapterState == BluetoothAdapterState.on) {
      return BlePrepResult.ready;
    }
    if (adapterState == BluetoothAdapterState.unavailable) {
      return BlePrepResult.unsupported;
    }

    if (Platform.isAndroid) {
      try {
        await FlutterBluePlus.turnOn();
        await FlutterBluePlus.adapterState
            .where((state) => state == BluetoothAdapterState.on)
            .first
            .timeout(const Duration(seconds: 8));
        return BlePrepResult.ready;
      } catch (_) {
        return BlePrepResult.bluetoothOff;
      }
    }
    return BlePrepResult.bluetoothOff;
  } catch (error) {
    debugPrint('Adapter check failed: $error');
    return BlePrepResult.ready;
  }
}
