import '../models/ble_connection_state.dart';
import '../models/ble_prep_result.dart';
import 'ble_tx_option.dart';
import 'radio_device.dart';
import 'radio_kind.dart';

abstract class RadioClient {
  RadioKind get kind;
  bool get isSupported;

  Stream<List<RadioDevice>> get devicesStream;
  Stream<BleConnectionState> get connectionStateStream;
  Stream<bool> get adapterOnStream;

  RadioDevice? get connectedDevice;
  BleConnectionState get connectionState;
  bool get isConnected;
  String? get linkLabel;
  bool get hasTxSettings;
  String? get selectedTxId => null;

  Future<BlePrepResult> ensureReady();
  Future<void> startScan({Duration timeout = const Duration(seconds: 12)});
  Future<void> stopScan();
  Future<bool> connect(RadioDevice device);
  Future<void> disconnect();
  Future<bool> write(List<int> bytes);

  List<BleTxOption> getWritableCharacteristics() => const [];
  void setWriteCharacteristic(String id) {}
}
