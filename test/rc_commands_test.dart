import 'package:flutter_test/flutter_test.dart';
import 'package:helmrc/commands/rc_commands.dart';

void main() {
  test('fail-safe commands stop motion and arms', () {
    expect(RcCommands.failSafe, [RcCommands.stop, RcCommands.allStop]);
  });

  test('group release maps to individual arm stops', () {
    expect(
      RcCommands.groupReleaseStops(RcCommands.frontUp),
      [RcCommands.arm1Stop, RcCommands.arm2Stop],
    );
    expect(
      RcCommands.groupReleaseStops(RcCommands.backDown),
      [RcCommands.arm3Stop, RcCommands.arm4Stop],
    );
  });

  test('movement protocol matches firmware', () {
    expect(RcCommands.forward, 'F');
    expect(RcCommands.backward, 'B');
    expect(RcCommands.left, 'L');
    expect(RcCommands.right, 'R');
    expect(RcCommands.stop, 'S');
    expect(RcCommands.faster, '+');
    expect(RcCommands.slower, '-');
  });
}
