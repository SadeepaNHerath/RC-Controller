import 'radio_kind.dart';

class RadioDevice {
  const RadioDevice({
    required this.id,
    required this.name,
    required this.kind,
    this.rssi = 0,
    this.paired = false,
  });

  final String id;
  final String name;
  final RadioKind kind;
  final int rssi;
  final bool paired;
}
