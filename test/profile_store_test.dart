import 'package:flutter_test/flutter_test.dart';
import 'package:helmrc/commands/rc_commands.dart';
import 'package:helmrc/profiles/builtin_profiles.dart';
import 'package:helmrc/profiles/profile_store.dart';
import 'package:helmrc/radio/radio_kind.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('defaults when nothing is stored', () async {
    final store = ProfileStore();
    expect(await store.loadRadioKind(), RadioKind.ble);
    expect(await store.loadProfileId(), BuiltinProfiles.helmrcId);
    final custom = await store.loadCustomProfile();
    expect(custom.id, BuiltinProfiles.customId);
    expect(custom.editable, isTrue);
  });

  test('saves and loads radio kind and profile id', () async {
    final store = ProfileStore();
    await store.saveRadioKind(RadioKind.classic);
    await store.saveProfileId(BuiltinProfiles.arduinoId);
    expect(await store.loadRadioKind(), RadioKind.classic);
    expect(await store.loadProfileId(), BuiltinProfiles.arduinoId);
  });

  test('unknown radio kind falls back to BLE', () async {
    SharedPreferences.setMockInitialValues({'helmrc.radio_kind': 'infrared'});
    final store = ProfileStore();
    expect(await store.loadRadioKind(), RadioKind.ble);
  });

  test('saves and loads custom profile', () async {
    final store = ProfileStore();
    final custom = BuiltinProfiles.custom(
      wireMap: {RcCommands.forward: 'GO'},
      appendNewline: true,
    );
    await store.saveCustomProfile(custom);
    final loaded = await store.loadCustomProfile();
    expect(loaded.wireMap[RcCommands.forward], 'GO');
    expect(loaded.appendNewline, isTrue);
    expect(loaded.editable, isTrue);
  });

  test('corrupt custom JSON falls back to default custom', () async {
    SharedPreferences.setMockInitialValues({
      'helmrc.custom_profile': '{not-json',
    });
    final store = ProfileStore();
    final loaded = await store.loadCustomProfile();
    expect(loaded.id, BuiltinProfiles.customId);
    expect(loaded.encode(RcCommands.forward), RcCommands.forward);
  });
}
