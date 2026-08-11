import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helmrc/radio/classic_radio_client.dart';
import 'package:helmrc/radio/radio_kind.dart';

void main() {
  test('Classic serial is unavailable on iOS', () {
    final client = ClassicRadioClient();
    if (Platform.isIOS || kIsWeb) {
      expect(client.isSupported, isFalse);
    }
    expect(client.isSupported, !kIsWeb && Platform.isAndroid);
  });

  test('radio kind labels', () {
    expect(RadioKind.ble.label, 'BLE');
    expect(RadioKind.classic.label, 'Classic');
  });
}
