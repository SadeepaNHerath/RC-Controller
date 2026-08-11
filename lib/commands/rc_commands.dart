/// Logical pad actions. Wire bytes come from the selected [DeviceProfile].
class RcCommands {
  RcCommands._();

  static const forward = 'F';
  static const backward = 'B';
  static const left = 'L';
  static const right = 'R';
  static const stop = 'S';
  static const faster = '+';
  static const slower = '-';

  static const frontUp = 'FRONT_UP';
  static const frontDown = 'FRONT_DOWN';
  static const backUp = 'BACK_UP';
  static const backDown = 'BACK_DOWN';

  static const arm1Up = 'ARM1_UP';
  static const arm1Down = 'ARM1_DOWN';
  static const arm1Stop = 'ARM1_STOP';
  static const arm2Up = 'ARM2_UP';
  static const arm2Down = 'ARM2_DOWN';
  static const arm2Stop = 'ARM2_STOP';
  static const arm3Up = 'ARM3_UP';
  static const arm3Down = 'ARM3_DOWN';
  static const arm3Stop = 'ARM3_STOP';
  static const arm4Up = 'ARM4_UP';
  static const arm4Down = 'ARM4_DOWN';
  static const arm4Stop = 'ARM4_STOP';

  static const allStop = 'ALL_STOP';

  /// Motion + arms halt. Send on disconnect, background, and E-stop.
  static const List<String> failSafe = [stop, allStop];

  static const List<String> allLogical = [
    forward,
    backward,
    left,
    right,
    stop,
    faster,
    slower,
    frontUp,
    frontDown,
    backUp,
    backDown,
    arm1Up,
    arm1Down,
    arm1Stop,
    arm2Up,
    arm2Down,
    arm2Stop,
    arm3Up,
    arm3Down,
    arm3Stop,
    arm4Up,
    arm4Down,
    arm4Stop,
    allStop,
  ];

  static List<String> groupReleaseStops(String groupCommand) {
    if (groupCommand.startsWith('FRONT')) {
      return [arm1Stop, arm2Stop];
    }
    if (groupCommand.startsWith('BACK')) {
      return [arm3Stop, arm4Stop];
    }
    return [allStop];
  }
}
