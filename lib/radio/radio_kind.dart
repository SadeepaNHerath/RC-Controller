enum RadioKind { ble, classic }

extension RadioKindX on RadioKind {
  String get label => this == RadioKind.ble ? 'BLE' : 'Classic';
}
