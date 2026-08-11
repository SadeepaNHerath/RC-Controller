import '../commands/rc_commands.dart';
import 'device_profile.dart';

class BuiltinProfiles {
  BuiltinProfiles._();

  static const helmrcId = 'helmrc';
  static const arduinoId = 'arduino_uart';
  static const numericId = 'numeric';
  static const customId = 'custom';

  static const Map<String, String> helmrcMap = {
    RcCommands.forward: RcCommands.forward,
    RcCommands.backward: RcCommands.backward,
    RcCommands.left: RcCommands.left,
    RcCommands.right: RcCommands.right,
    RcCommands.stop: RcCommands.stop,
    RcCommands.faster: RcCommands.faster,
    RcCommands.slower: RcCommands.slower,
    RcCommands.frontUp: RcCommands.frontUp,
    RcCommands.frontDown: RcCommands.frontDown,
    RcCommands.backUp: RcCommands.backUp,
    RcCommands.backDown: RcCommands.backDown,
    RcCommands.arm1Up: RcCommands.arm1Up,
    RcCommands.arm1Down: RcCommands.arm1Down,
    RcCommands.arm1Stop: RcCommands.arm1Stop,
    RcCommands.arm2Up: RcCommands.arm2Up,
    RcCommands.arm2Down: RcCommands.arm2Down,
    RcCommands.arm2Stop: RcCommands.arm2Stop,
    RcCommands.arm3Up: RcCommands.arm3Up,
    RcCommands.arm3Down: RcCommands.arm3Down,
    RcCommands.arm3Stop: RcCommands.arm3Stop,
    RcCommands.arm4Up: RcCommands.arm4Up,
    RcCommands.arm4Down: RcCommands.arm4Down,
    RcCommands.arm4Stop: RcCommands.arm4Stop,
    RcCommands.allStop: RcCommands.allStop,
  };

  static const helmrc = DeviceProfile(
    id: helmrcId,
    name: 'HelmRC',
    wireMap: helmrcMap,
  );

  static const arduinoUart = DeviceProfile(
    id: arduinoId,
    name: 'Arduino UART',
    appendNewline: true,
    wireMap: {
      RcCommands.forward: 'F',
      RcCommands.backward: 'B',
      RcCommands.left: 'L',
      RcCommands.right: 'R',
      RcCommands.stop: 'S',
      RcCommands.faster: '+',
      RcCommands.slower: '-',
    },
  );

  static const numeric = DeviceProfile(
    id: numericId,
    name: 'Numeric',
    appendNewline: true,
    wireMap: {
      RcCommands.forward: '1',
      RcCommands.backward: '2',
      RcCommands.left: '3',
      RcCommands.right: '4',
      RcCommands.stop: '0',
    },
  );

  static DeviceProfile custom({
    Map<String, String>? wireMap,
    bool appendNewline = false,
  }) {
    return DeviceProfile(
      id: customId,
      name: 'Custom',
      wireMap: wireMap ?? Map<String, String>.from(helmrcMap),
      appendNewline: appendNewline,
      editable: true,
    );
  }

  static List<DeviceProfile> all({DeviceProfile? customProfile}) => [
        helmrc,
        arduinoUart,
        numeric,
        customProfile ?? custom(),
      ];
}
