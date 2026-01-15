import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

enum ConnectionState { disconnected, connecting, connected, error }

class BleService {
  static final BleService _instance = BleService._internal();
  factory BleService() => _instance;
  BleService._internal();

  final _devicesController =
      StreamController<List<BluetoothDevice>>.broadcast();
  final _connectionStateController =
      StreamController<ConnectionState>.broadcast();

  Stream<List<BluetoothDevice>> get devicesStream => _devicesController.stream;
  Stream<ConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  final List<BluetoothDevice> _devices = [];
  BluetoothDevice? _connectedDevice;
  List<BluetoothService> _services = [];
  BluetoothCharacteristic? _writeCharacteristic;
  StreamSubscription? _scanSubscription;

  BluetoothDevice? get connectedDevice => _connectedDevice;
  List<BluetoothService> get services => _services;
  BluetoothCharacteristic? get writeCharacteristic => _writeCharacteristic;

  Future<bool> requestPermissions() async {
    final locationStatus = await Permission.location.request();
    final bluetoothScan = await Permission.bluetoothScan.request();
    final bluetoothConnect = await Permission.bluetoothConnect.request();

    return locationStatus.isGranted &&
        (bluetoothScan.isGranted || bluetoothScan.isLimited) &&
        (bluetoothConnect.isGranted || bluetoothConnect.isLimited);
  }

  Future<void> startScan() async {
    _devices.clear();
    _devicesController.add(_devices);

    // Wait for Bluetooth adapter to be on
    await FlutterBluePlus.adapterState
        .where((state) => state == BluetoothAdapterState.on)
        .first
        .timeout(const Duration(seconds: 5),
            onTimeout: () => BluetoothAdapterState.off);

    _scanSubscription = FlutterBluePlus.onScanResults.listen(
      (results) {
        for (final result in results) {
          // Filter out unknown devices and weak signals
          final deviceName = result.device.platformName;
          final rssi = result.rssi;

          // Only show devices with names and good signal strength (RSSI > -90)
          final isValidDevice = deviceName.isNotEmpty && rssi > -90;

          if (isValidDevice && !_devices.contains(result.device)) {
            _devices.add(result.device);
            _devicesController.add(List.from(_devices));
          }
        }
      },
      onError: (error) {
        debugPrint('Scan error: $error');
      },
    );

    FlutterBluePlus.cancelWhenScanComplete(_scanSubscription!);

    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 10),
      androidUsesFineLocation: true,
      removeIfGone: const Duration(seconds: 5),
    );

    // Add already connected devices
    for (final device in FlutterBluePlus.connectedDevices) {
      if (!_devices.contains(device)) {
        _devices.add(device);
        _devicesController.add(List.from(_devices));
      }
    }
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    _scanSubscription?.cancel();
  }

  Future<bool> connect(BluetoothDevice device) async {
    try {
      _connectionStateController.add(ConnectionState.connecting);
      await stopScan();

      await device.connect(
        autoConnect: false,
        timeout: const Duration(seconds: 10),
      );

      _connectedDevice = device;
      _services = await device.discoverServices();
      _autoSelectWriteCharacteristic();

      _connectionStateController.add(ConnectionState.connected);
      return true;
    } catch (e) {
      debugPrint('Connection error: $e');
      _connectionStateController.add(ConnectionState.error);
      return false;
    }
  }

  void _autoSelectWriteCharacteristic() {
    for (final service in _services) {
      for (final char in service.characteristics) {
        if (char.properties.write || char.properties.writeWithoutResponse) {
          _writeCharacteristic = char;
          return;
        }
      }
    }
  }

  void setWriteCharacteristic(BluetoothCharacteristic characteristic) {
    _writeCharacteristic = characteristic;
  }

  Future<void> disconnect() async {
    await _connectedDevice?.disconnect();
    _connectedDevice = null;
    _services = [];
    _writeCharacteristic = null;
    _connectionStateController.add(ConnectionState.disconnected);
  }

  Future<bool> sendCommand(String command) async {
    if (_writeCharacteristic == null) return false;

    try {
      final bytes = command.codeUnits;
      await _writeCharacteristic!.write(bytes, withoutResponse: true);
      return true;
    } catch (e) {
      debugPrint('Send command error: $e');
      return false;
    }
  }

  List<BluetoothCharacteristic> getWritableCharacteristics() {
    final List<BluetoothCharacteristic> writable = [];
    for (final service in _services) {
      for (final char in service.characteristics) {
        if (char.properties.write || char.properties.writeWithoutResponse) {
          writable.add(char);
        }
      }
    }
    return writable;
  }

  void dispose() {
    _scanSubscription?.cancel();
    _devicesController.close();
    _connectionStateController.close();
  }
}
