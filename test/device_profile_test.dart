import 'package:flutter_test/flutter_test.dart';
import 'package:helmrc/commands/rc_commands.dart';
import 'package:helmrc/profiles/builtin_profiles.dart';

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
}
