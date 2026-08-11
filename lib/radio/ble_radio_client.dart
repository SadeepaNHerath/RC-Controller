import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../models/ble_connection_state.dart';
import '../models/ble_prep_result.dart';
import '../utils/ble_uuid.dart';
import 'ble_tx_option.dart';
import 'radio_client.dart';
import 'radio_device.dart';
import 'radio_kind.dart';
import 'radio_permissions.dart';

class BleRadioClient extends RadioClient {
  final _devices = <String, RadioDevice>{};
  final _native = <String, BluetoothDevice>{};
  final _devicesController = StreamController<List<RadioDevice>>.broadcast();
  final _connectionStateController =
      StreamController<BleConnectionState>.broadcast();
  final _adapterOnController = StreamController<bool>.broadcast();

  BluetoothDevice? _connectedDevice;
  RadioDevice? _connectedRadio;
  List<BluetoothService> _services = [];
  BluetoothCharacteristic? _writeCharacteristic;
  BleConnectionState _connectionState = BleConnectionState.disconnected;

  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothConnectionState>? _deviceConnectionSub;
  StreamSubscription<BluetoothAdapterState>? _adapterSub;
  Future<void> _writeChain = Future.value();
  bool _intentionalDisconnect = false;

  @override
  RadioKind get kind => RadioKind.ble;

  @override
  bool get isSupported => true;

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
      _connectedDevice != null;

  @override
  bool get hasTxSettings => true;

  @override
  String? get selectedTxId => _writeCharacteristic?.uuid.str;

  @override
  String? get linkLabel {
    final char = _writeCharacteristic;
    if (char == null) return null;
    return shortUuid(char.uuid);
  }

  void startAdapterWatch() {
    if (_adapterSub != null) return;
    try {
      _adapterSub = FlutterBluePlus.adapterState.listen(
        (state) {
          final on = state == BluetoothAdapterState.on;
          if (!_adapterOnController.isClosed) {
            _adapterOnController.add(on);
          }
          if (!on && _connectionState == BleConnectionState.connected) {
            _clearConnection(notify: true);
          }
        },
        onError: (error) {
          debugPrint('Adapter watch error: $error');
          _adapterSub = null;
        },
        cancelOnError: true,
      );
    } catch (error) {
      debugPrint('Adapter watch failed: $error');
    }
  }

  @override
  Future<BlePrepResult> ensureReady() async {
    startAdapterWatch();

    try {
      if (!await FlutterBluePlus.isSupported) {
        return BlePrepResult.unsupported;
      }
    } catch (error) {
      debugPrint('BLE support check failed: $error');
      return BlePrepResult.unsupported;
    }

    if (!await requestRadioPermissions()) {
      return BlePrepResult.permissionDenied;
    }

    return ensureBluetoothAdapterOn();
  }

  @override
  Future<void> startScan(
      {Duration timeout = const Duration(seconds: 12)}) async {
    await stopScan();
    _devices.clear();
    _native.clear();
    _emitDevices();

    _scanSubscription = FlutterBluePlus.onScanResults.listen(
      (results) {
        for (final result in results) {
          if (result.rssi < -95) continue;

          final id = result.device.remoteId.toString();
          _native[id] = result.device;
          _devices[id] = RadioDevice(
            id: id,
            name: _scanName(result, id),
            kind: RadioKind.ble,
            rssi: result.rssi,
          );
        }
        _emitDevices();
      },
      onError: (error) => debugPrint('Scan error: $error'),
    );

    FlutterBluePlus.cancelWhenScanComplete(_scanSubscription!);

    await FlutterBluePlus.startScan(
      timeout: timeout,
      androidUsesFineLocation: false,
      removeIfGone: const Duration(seconds: 6),
    );

    for (final device in FlutterBluePlus.connectedDevices) {
      final id = device.remoteId.toString();
      _native.putIfAbsent(id, () => device);
      _devices.putIfAbsent(
        id,
        () => RadioDevice(
          id: id,
          name: device.platformName.isNotEmpty
              ? device.platformName
              : 'Connected device',
          kind: RadioKind.ble,
        ),
      );
    }
    _emitDevices();
  }

  @override
  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}
    await _scanSubscription?.cancel();
    _scanSubscription = null;
  }

  String _scanName(ScanResult result, String id) {
    for (final candidate in [
      result.device.platformName,
      result.device.advName,
      result.advertisementData.advName,
    ]) {
      final name = candidate.trim();
      if (name.isNotEmpty) return name;
    }
    final suffix = id.length > 5 ? id.substring(id.length - 5) : id;
    return 'BLE $suffix';
  }

  BluetoothDevice? _nativeFor(RadioDevice device) {
    final cached = _native[device.id];
    if (cached != null) return cached;
    try {
      final fromId = BluetoothDevice.fromId(device.id);
      _native[device.id] = fromId;
      return fromId;
    } catch (error) {
      debugPrint('BLE device lookup failed: $error');
      return null;
    }
  }

  @override
  Future<bool> connect(RadioDevice device) async {
    final native = _nativeFor(device);
    if (native == null) return false;

    _intentionalDisconnect = false;
    _setConnectionState(BleConnectionState.connecting);

    try {
      await stopScan();
      await _deviceConnectionSub?.cancel();

      // Do not request MTU during connect — a failed MTU bump would abort
      // an otherwise good link, and RC commands are well under 20 bytes.
      await native.connect(
        autoConnect: false,
        timeout: const Duration(seconds: 15),
        mtu: null,
      );

      _deviceConnectionSub = native.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected &&
            _connectedDevice?.remoteId == native.remoteId) {
          _onDeviceDisconnected();
        }
      });

      _connectedDevice = native;
      _connectedRadio = device;
      _services = await _discoverServices(native);
      _autoSelectWriteCharacteristic();

      if (_writeCharacteristic == null) {
        await disconnect();
        _setConnectionState(BleConnectionState.error);
        return false;
      }

      _setConnectionState(BleConnectionState.connected);
      return true;
    } catch (error) {
      debugPrint('BLE connection error: $error');
      _clearConnection(notify: false);
      _setConnectionState(BleConnectionState.error);
      return false;
    }
  }

  Future<List<BluetoothService>> _discoverServices(
    BluetoothDevice native,
  ) async {
    Object? lastError;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final services = await native.discoverServices();
        if (services.isNotEmpty) return services;
      } catch (error) {
        lastError = error;
        debugPrint('BLE service discovery failed: $error');
        await Future<void>.delayed(const Duration(milliseconds: 400));
      }
    }
    if (lastError != null) throw lastError;
    return const [];
  }

  void _autoSelectWriteCharacteristic() {
    BluetoothCharacteristic? withResponse;
    for (final service in _services) {
      for (final char in service.characteristics) {
        if (char.properties.writeWithoutResponse) {
          _writeCharacteristic = char;
          return;
        }
        if (char.properties.write && withResponse == null) {
          withResponse = char;
        }
      }
    }
    _writeCharacteristic = withResponse;
  }

  @override
  void setWriteCharacteristic(String id) {
    for (final service in _services) {
      for (final char in service.characteristics) {
        if (char.uuid.str == id) {
          _writeCharacteristic = char;
          return;
        }
      }
    }
  }

  @override
  List<BleTxOption> getWritableCharacteristics() {
    final writable = <BleTxOption>[];
    for (final service in _services) {
      for (final char in service.characteristics) {
        if (char.properties.write || char.properties.writeWithoutResponse) {
          writable.add(
            BleTxOption(
              id: char.uuid.str,
              serviceId: shortUuid(char.serviceUuid),
              label: shortUuid(char.uuid),
              fast: char.properties.writeWithoutResponse,
            ),
          );
        }
      }
    }
    return writable;
  }

  @override
  Future<void> disconnect() async {
    _intentionalDisconnect = true;
    try {
      await _connectedDevice?.disconnect();
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
      debugPrint('BLE write queue error: $error');
      if (!completer.isCompleted) completer.complete(false);
    });
    return completer.future;
  }

  Future<bool> _writeNow(List<int> bytes) async {
    final characteristic = _writeCharacteristic;
    if (characteristic == null || bytes.isEmpty) return false;

    final withoutResponse = characteristic.properties.writeWithoutResponse;
    try {
      await characteristic.write(bytes, withoutResponse: withoutResponse);
      return true;
    } catch (error) {
      debugPrint('BLE write error: $error');
      if (withoutResponse && characteristic.properties.write) {
        try {
          await characteristic.write(bytes, withoutResponse: false);
          return true;
        } catch (fallbackError) {
          debugPrint('BLE write fallback error: $fallbackError');
        }
      }
      return false;
    }
  }

  void _onDeviceDisconnected() {
    if (_intentionalDisconnect) {
      _clearConnection(notify: true);
      return;
    }
    debugPrint('BLE link dropped unexpectedly');
    _clearConnection(notify: true);
  }

  void _clearConnection({required bool notify}) {
    _deviceConnectionSub?.cancel();
    _deviceConnectionSub = null;
    _connectedDevice = null;
    _connectedRadio = null;
    _services = [];
    _writeCharacteristic = null;
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
      ..sort((a, b) => b.rssi.compareTo(a.rssi));
    if (!_devicesController.isClosed) {
      _devicesController.add(list);
    }
  }
}
