import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bluetooth_serial_android/bluetooth_serial_android.dart';
import 'package:flutter/foundation.dart';

import '../models/ble_connection_state.dart';
import '../models/ble_prep_result.dart';
import 'radio_client.dart';
import 'radio_device.dart';
import 'radio_kind.dart';
import 'radio_permissions.dart';

class ClassicRadioClient extends RadioClient {
  final _devices = <String, RadioDevice>{};
  final _devicesController = StreamController<List<RadioDevice>>.broadcast();
  final _connectionStateController =
      StreamController<BleConnectionState>.broadcast();
  final _adapterOnController = StreamController<bool>.broadcast();

  RadioDevice? _connectedRadio;
  BleConnectionState _connectionState = BleConnectionState.disconnected;
  Future<void> _writeChain = Future.value();
  bool _intentionalDisconnect = false;

  @override
  RadioKind get kind => RadioKind.classic;

  @override
  bool get isSupported => !kIsWeb && Platform.isAndroid;

  @override
  Stream<List<RadioDevice>> get devicesStream => _devicesController.stream;

  @override
  Stream<BleConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  @override
  Stream<bool> get adapterOnStream => _adapterOnController.stream;

  @override
  RadioDevice? get connectedDevice => _connectedRadio;

  @override
  BleConnectionState get connectionState => _connectionState;

  @override
  bool get isConnected =>
      _connectionState == BleConnectionState.connected &&
      _connectedRadio != null;

  @override
  bool get hasTxSettings => false;

  @override
  String? get linkLabel => isConnected ? 'Serial (SPP)' : null;

  @override
  Future<BlePrepResult> ensureReady() async {
    if (!isSupported) return BlePrepResult.unsupported;
    // Wait for the system dialog. The plugin's ensurePermissions() returns
    // false immediately after showing it, which blocked first-run Classic.
    if (!await requestRadioPermissions()) {
      return BlePrepResult.permissionDenied;
    }
    final adapter = await ensureBluetoothAdapterOn();
    if (adapter != BlePrepResult.ready) return adapter;
    if (!_adapterOnController.isClosed) {
      _adapterOnController.add(true);
    }
    return BlePrepResult.ready;
  }

  @override
  Future<void> startScan(
      {Duration timeout = const Duration(seconds: 12)}) async {
    if (!isSupported) return;
    await stopScan();
    _devices.clear();
    _emitDevices();

    // Nearby Classic inquiry in bluetooth_serial_android 1.1.2 uses an
    // API 33-only Parcelable call and can crash Android 8–12. Paired
    // devices are the reliable HC-05/HC-06 path.
    try {
      final paired = await FlutterBluetoothSerial.getPairedDevices()
          .timeout(timeout);
      for (final device in paired) {
        _upsert(device, paired: true);
      }
      _emitDevices();
    } catch (error) {
      debugPrint('Classic paired list failed: $error');
    }
  }

  void _upsert(Map<String, String> device, {required bool paired}) {
    final id = (device['address'] ?? '').trim();
    if (id.isEmpty) return;
    final existing = _devices[id];
    final name = (device['name'] ?? '').trim();
    _devices[id] = RadioDevice(
      id: id,
      name: name.isNotEmpty ? name : (existing?.name ?? id),
      kind: RadioKind.classic,
      paired: existing?.paired == true || paired,
      rssi: existing?.rssi ?? 0,
    );
  }

  @override
  Future<void> stopScan() async {}

  @override
  Future<bool> connect(RadioDevice device) async {
    if (!isSupported) return false;
    _intentionalDisconnect = false;
    _setConnectionState(BleConnectionState.connecting);
    try {
      await stopScan();
      // Plugin socket.connect() has no native timeout and can hang forever.
      final ok = await FlutterBluetoothSerial.connect(device.id)
          .timeout(const Duration(seconds: 12));
      if (ok) {
        _connectedRadio = device;
        _setConnectionState(BleConnectionState.connected);
        return true;
      }
      _clearConnection(notify: false);
      _setConnectionState(BleConnectionState.error);
      return false;
    } catch (error) {
      debugPrint('Classic connection error: $error');
      try {
        await FlutterBluetoothSerial.disconnect();
      } catch (_) {}
      _clearConnection(notify: false);
      _setConnectionState(BleConnectionState.error);
      return false;
    }
  }

  @override
  Future<void> disconnect() async {
    _intentionalDisconnect = true;
    try {
      if (isSupported) {
        await FlutterBluetoothSerial.disconnect();
      }
    } catch (_) {}
    _clearConnection(notify: true);
  }

  @override
  Future<bool> write(List<int> bytes) {
    final completer = Completer<bool>();
    _writeChain = _writeChain.then((_) async {
      final ok = await _writeNow(bytes);
      if (!completer.isCompleted) completer.complete(ok);
    }).catchError((error) {
      debugPrint('Classic write queue error: $error');
      if (!completer.isCompleted) completer.complete(false);
    });
    return completer.future;
  }

  Future<bool> _writeNow(List<int> bytes) async {
    if (!isConnected || bytes.isEmpty) return false;
    try {
      await FlutterBluetoothSerial.write(
        utf8.decode(bytes, allowMalformed: true),
      );
      return true;
    } catch (error) {
      debugPrint('Classic write error: $error');
      if (!_intentionalDisconnect) {
        _clearConnection(notify: true);
      }
      return false;
    }
  }

  void _clearConnection({required bool notify}) {
    _connectedRadio = null;
    if (notify) {
      _setConnectionState(BleConnectionState.disconnected);
    }
  }

  void _setConnectionState(BleConnectionState state) {
    _connectionState = state;
    if (!_connectionStateController.isClosed) {
      _connectionStateController.add(state);
    }
  }

  void _emitDevices() {
    final list = _devices.values.toList()
      ..sort((a, b) {
        if (a.paired != b.paired) return a.paired ? -1 : 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    if (!_devicesController.isClosed) {
      _devicesController.add(list);
    }
  }
}
