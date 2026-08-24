import 'package:flutter_test/flutter_test.dart';
import 'package:helmrc/commands/rc_commands.dart';
import 'package:helmrc/profiles/builtin_profiles.dart';
import 'package:helmrc/profiles/device_profile.dart';

void main() {
  test('HelmRC forward encodes to F', () {
    expect(BuiltinProfiles.helmrc.encode(RcCommands.forward), 'F');
    expect(BuiltinProfiles.helmrc.encode(RcCommands.stop), 'S');
  });

  test('Arduino UART forward encodes to F with newline', () {
    expect(BuiltinProfiles.arduinoUart.encode(RcCommands.forward), 'F\n');
    expect(BuiltinProfiles.arduinoUart.encode(RcCommands.stop), 'S\n');
  });

  test('Numeric maps hobby digits and skips unknown pads', () {
    expect(BuiltinProfiles.numeric.encode(RcCommands.forward), '1\n');
    expect(BuiltinProfiles.numeric.encode(RcCommands.stop), '0\n');
    expect(BuiltinProfiles.numeric.encode(RcCommands.arm1Up), isNull);
  });

  test('Numeric fail-safe is stop only', () {
    expect(BuiltinProfiles.numeric.encodeFailSafe(), ['0\n']);
  });

  test('Arduino UART fail-safe is stop only', () {
    expect(BuiltinProfiles.arduinoUart.encodeFailSafe(), ['S\n']);
  });

  test('HelmRC fail-safe maps stop and all-stop', () {
    expect(
      BuiltinProfiles.helmrc.encodeFailSafe(),
      [RcCommands.stop, RcCommands.allStop],
    );
  });

  test('HelmRC map covers every logical pad', () {
    for (final key in RcCommands.allLogical) {
      expect(
        BuiltinProfiles.helmrc.wireMap.containsKey(key),
        isTrue,
        reason: 'missing $key',
      );
      expect(BuiltinProfiles.helmrc.encode(key), isNotNull);
    }
  });

  test('encodeRaw respects newline flag', () {
    expect(BuiltinProfiles.helmrc.encodeRaw('  go  '), 'go');
    expect(BuiltinProfiles.arduinoUart.encodeRaw('go'), 'go\n');
    expect(BuiltinProfiles.helmrc.encodeRaw('   '), '');
  });

  test('empty mapping is skipped', () {
    const profile = DeviceProfile(
      id: 'empty',
      name: 'Empty',
      wireMap: {RcCommands.forward: ''},
    );
    expect(profile.encode(RcCommands.forward), isNull);
  });

  test('copyWith replaces wire map and newline', () {
    final updated = BuiltinProfiles.helmrc.copyWith(
      appendNewline: true,
      wireMap: {RcCommands.forward: 'X'},
    );
    expect(updated.encode(RcCommands.forward), 'X\n');
    expect(updated.id, BuiltinProfiles.helmrcId);
    expect(BuiltinProfiles.helmrc.appendNewline, isFalse);
  });

  test('JSON round-trip preserves profile', () {
    final custom = BuiltinProfiles.custom(
      wireMap: {RcCommands.forward: 'FWD', RcCommands.stop: 'HALT'},
      appendNewline: true,
    );
    final restored = DeviceProfile.decodeJson(DeviceProfile.encodeJson(custom));
    expect(restored.id, custom.id);
    expect(restored.name, custom.name);
    expect(restored.appendNewline, isTrue);
    expect(restored.editable, isTrue);
    expect(restored.wireMap[RcCommands.forward], 'FWD');
    expect(restored.encode(RcCommands.forward), 'FWD\n');
  });

  test('fromJson coerces non-string wire map values', () {
    final profile = DeviceProfile.fromJson({
      'id': 'n',
      'name': 'N',
      'wireMap': {'F': 1, 'S': true},
    });
    expect(profile.wireMap['F'], '1');
    expect(profile.wireMap['S'], 'true');
  });
}
