import 'package:shared_preferences/shared_preferences.dart';

import '../radio/radio_kind.dart';
import 'builtin_profiles.dart';
import 'device_profile.dart';

class ProfileStore {
  static const _kindKey = 'helmrc.radio_kind';
  static const _profileKey = 'helmrc.profile_id';
  static const _customKey = 'helmrc.custom_profile';

  Future<RadioKind> loadRadioKind() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kindKey);
    return RadioKind.values.asNameMap()[raw] ?? RadioKind.ble;
  }

  Future<void> saveRadioKind(RadioKind kind) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kindKey, kind.name);
  }

  Future<String> loadProfileId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_profileKey) ?? BuiltinProfiles.helmrcId;
  }

  Future<void> saveProfileId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, id);
  }

  Future<DeviceProfile> loadCustomProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_customKey);
    if (raw == null || raw.isEmpty) return BuiltinProfiles.custom();
    try {
      return DeviceProfile.decodeJson(raw);
    } catch (_) {
      return BuiltinProfiles.custom();
    }
  }

  Future<void> saveCustomProfile(DeviceProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_customKey, DeviceProfile.encodeJson(profile));
  }
}
