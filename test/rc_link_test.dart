import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helmrc/commands/rc_commands.dart';
import 'package:helmrc/profiles/builtin_profiles.dart';
import 'package:helmrc/profiles/profile_store.dart';
import 'package:helmrc/radio/radio_kind.dart';
import 'package:helmrc/radio/rc_link.dart';
import 'package:helmrc/radio/send_result.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await RcLink.instance.restore();
  });

  test('Classic is unsupported off Android, matching iOS', () {
    expect(RcLink.instance.classicSupported, !kIsWeb && Platform.isAndroid);
  });

  test('restore falls back to BLE when Classic is stored but unsupported',
      () async {
    SharedPreferences.setMockInitialValues({
      'helmrc.radio_kind': 'classic',
      'helmrc.profile_id': BuiltinProfiles.numericId,
    });
    await RcLink.instance.restore();
    if (!RcLink.instance.classicSupported) {
      expect(RcLink.instance.kind, RadioKind.ble);
    }
    expect(RcLink.instance.profile.id, BuiltinProfiles.numericId);
  });

  test('setKind(classic) returns false when Classic is unavailable', () async {
    final ok = await RcLink.instance.setKind(RadioKind.classic);
    expect(ok, RcLink.instance.classicSupported);
    if (!RcLink.instance.classicSupported) {
      expect(RcLink.instance.kind, RadioKind.ble);
    }
  });

  test('setKind(ble) is idempotent', () async {
    expect(await RcLink.instance.setKind(RadioKind.ble), isTrue);
    expect(RcLink.instance.kind, RadioKind.ble);
  });

  test('setProfile persists id and custom map', () async {
    final custom = BuiltinProfiles.custom(
      wireMap: {RcCommands.forward: 'X'},
    );
    await RcLink.instance.setProfile(custom);
    expect(RcLink.instance.profile.id, BuiltinProfiles.customId);
    expect(RcLink.instance.profile.encode(RcCommands.forward), 'X');

    final store = ProfileStore();
    expect(await store.loadProfileId(), BuiltinProfiles.customId);
    expect(
      (await store.loadCustomProfile()).encode(RcCommands.forward),
      'X',
    );
  });

  test('sendLogical skips unmapped commands', () async {
    await RcLink.instance.setProfile(BuiltinProfiles.numeric);
    expect(
      await RcLink.instance.sendLogical(RcCommands.arm1Up),
      SendResult.skipped,
    );
  });

  test('sendLogical fails when disconnected', () async {
    await RcLink.instance.setProfile(BuiltinProfiles.helmrc);
    expect(RcLink.instance.isConnected, isFalse);
    expect(
      await RcLink.instance.sendLogical(RcCommands.forward),
      SendResult.failed,
    );
  });

  test('sendRaw skips empty input', () async {
    expect(await RcLink.instance.sendRaw('   '), SendResult.skipped);
  });

  test('unknown stored profile id falls back to HelmRC', () async {
    SharedPreferences.setMockInitialValues({
      'helmrc.profile_id': 'does-not-exist',
    });
    await RcLink.instance.restore();
    expect(RcLink.instance.profile.id, BuiltinProfiles.helmrcId);
  });
}
