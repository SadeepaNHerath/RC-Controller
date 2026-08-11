import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/ble_connection_state.dart';
import '../models/ble_prep_result.dart';
import '../profiles/builtin_profiles.dart';
import '../profiles/device_profile.dart';
import '../profiles/profile_store.dart';
import 'ble_radio_client.dart';
import 'ble_tx_option.dart';
import 'classic_radio_client.dart';
import 'radio_client.dart';
import 'radio_device.dart';
import 'radio_kind.dart';
import 'send_result.dart';

class RcLink {
  static final RcLink instance = RcLink._();
  RcLink._();

  final ProfileStore _store = ProfileStore();
  final BleRadioClient _ble = BleRadioClient();
  final ClassicRadioClient _classic = ClassicRadioClient();

  RadioKind _kind = RadioKind.ble;
  DeviceProfile _profile = BuiltinProfiles.helmrc;
  DeviceProfile _custom = BuiltinProfiles.custom();
  final _profileController = StreamController<DeviceProfile>.broadcast();
  final _kindController = StreamController<RadioKind>.broadcast();
  final _devicesBridge = StreamController<List<RadioDevice>>.broadcast();
  final _adapterBridge = StreamController<bool>.broadcast();
  final _connectionBridge =
      StreamController<BleConnectionState>.broadcast();

  StreamSubscription<BleConnectionState>? _bleConnSub;
  StreamSubscription<BleConnectionState>? _classicConnSub;
  StreamSubscription<List<RadioDevice>>? _devicesSub;
  StreamSubscription<bool>? _adapterSub;

  RadioClient get radio => _kind == RadioKind.classic ? _classic : _ble;

  RadioKind get kind => _kind;
  DeviceProfile get profile => _profile;
  bool get classicSupported => !kIsWeb && Platform.isAndroid;
  List<DeviceProfile> get profiles =>
      BuiltinProfiles.all(customProfile: _custom);

  Stream<DeviceProfile> get profileStream => _profileController.stream;
  Stream<RadioKind> get kindStream => _kindController.stream;
  Stream<List<RadioDevice>> get devicesStream => _devicesBridge.stream;
  Stream<BleConnectionState> get connectionStateStream =>
      _connectionBridge.stream;
  Stream<bool> get adapterOnStream => _adapterBridge.stream;

  RadioDevice? get connectedDevice => radio.connectedDevice;
  bool get isConnected => radio.isConnected;
  String? get linkLabel => radio.linkLabel;
  bool get hasTxSettings => radio.hasTxSettings;
  String? get selectedTxId => radio.selectedTxId;

  Future<void> restore() async {
    _bleConnSub ??= _ble.connectionStateStream.listen((state) {
      if (_kind == RadioKind.ble) _connectionBridge.add(state);
    });
    _classicConnSub ??= _classic.connectionStateStream.listen((state) {
      if (_kind == RadioKind.classic) _connectionBridge.add(state);
    });

    _custom = await _store.loadCustomProfile();
    var kind = await _store.loadRadioKind();
    if (kind == RadioKind.classic && !classicSupported) {
      kind = RadioKind.ble;
    }
    _kind = kind;
    _listenToRadio();
    final profileId = await _store.loadProfileId();
    _profile = profiles.firstWhere(
      (item) => item.id == profileId,
      orElse: () => BuiltinProfiles.helmrc,
    );
    _kindController.add(_kind);
    _profileController.add(_profile);
  }

  void _listenToRadio() {
    _devicesSub?.cancel();
    _adapterSub?.cancel();
    _devicesSub = radio.devicesStream.listen(_devicesBridge.add);
    _adapterSub = radio.adapterOnStream.listen(_adapterBridge.add);
  }

  Future<bool> setKind(RadioKind kind) async {
    if (kind == RadioKind.classic && !classicSupported) {
      return false;
    }
    if (kind == _kind) return true;
    await radio.stopScan();
    if (radio.isConnected) {
      await radio.disconnect();
    }
    _kind = kind;
    await _store.saveRadioKind(kind);
    _listenToRadio();
    _kindController.add(kind);
    return true;
  }

  Future<void> setProfile(DeviceProfile profile) async {
    _profile = profile;
    if (profile.editable) {
      _custom = profile;
      await _store.saveCustomProfile(profile);
    }
    await _store.saveProfileId(profile.id);
    _profileController.add(profile);
  }

  Future<BlePrepResult> ensureReady() => radio.ensureReady();

  Future<void> startScan({Duration timeout = const Duration(seconds: 12)}) =>
      radio.startScan(timeout: timeout);

  Future<void> stopScan() => radio.stopScan();

  Future<bool> connect(RadioDevice device) => radio.connect(device);

  Future<void> disconnect({bool sendFailSafe = true}) async {
    if (sendFailSafe && radio.isConnected) {
      await emergencyStop();
    }
    await radio.disconnect();
  }

  Future<SendResult> sendLogical(String logical) async {
    final wire = _profile.encode(logical);
    if (wire == null) return SendResult.skipped;
    final ok = await radio.write(utf8.encode(wire));
    return ok ? SendResult.sent : SendResult.failed;
  }

  Future<SendResult> sendRaw(String text) async {
    if (!_profile.allowRaw) return SendResult.skipped;
    final wire = _profile.encodeRaw(text);
    if (wire.isEmpty) return SendResult.skipped;
    final ok = await radio.write(utf8.encode(wire));
    return ok ? SendResult.sent : SendResult.failed;
  }

  Future<void> emergencyStop() async {
    for (final wire in _profile.encodeFailSafe()) {
      await radio.write(utf8.encode(wire));
    }
  }

  List<BleTxOption> getWritableCharacteristics() =>
      radio.getWritableCharacteristics();

  void setWriteCharacteristic(String id) => radio.setWriteCharacteristic(id);
}
