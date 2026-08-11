import 'dart:convert';

import '../commands/rc_commands.dart';

class DeviceProfile {
  const DeviceProfile({
    required this.id,
    required this.name,
    required this.wireMap,
    this.appendNewline = false,
    this.allowRaw = true,
    this.editable = false,
  });

  final String id;
  final String name;
  final Map<String, String> wireMap;
  final bool appendNewline;
  final bool allowRaw;
  final bool editable;

  String? encode(String logical) {
    final mapped = wireMap[logical];
    if (mapped == null || mapped.isEmpty) return null;
    return appendNewline ? '$mapped\n' : mapped;
  }

  String encodeRaw(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return '';
    return appendNewline ? '$trimmed\n' : trimmed;
  }

  List<String> encodeFailSafe() {
    return [
      for (final logical in RcCommands.failSafe)
        if (encode(logical) != null) encode(logical)!,
    ];
  }

  DeviceProfile copyWith({
    String? id,
    String? name,
    Map<String, String>? wireMap,
    bool? appendNewline,
    bool? allowRaw,
    bool? editable,
  }) {
    return DeviceProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      wireMap: wireMap ?? Map<String, String>.from(this.wireMap),
      appendNewline: appendNewline ?? this.appendNewline,
      allowRaw: allowRaw ?? this.allowRaw,
      editable: editable ?? this.editable,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'wireMap': wireMap,
        'appendNewline': appendNewline,
        'allowRaw': allowRaw,
        'editable': editable,
      };

  factory DeviceProfile.fromJson(Map<String, dynamic> json) {
    return DeviceProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      wireMap: {
        for (final entry in (json['wireMap'] as Map).entries)
          '${entry.key}': '${entry.value}',
      },
      appendNewline: json['appendNewline'] as bool? ?? false,
      allowRaw: json['allowRaw'] as bool? ?? true,
      editable: json['editable'] as bool? ?? false,
    );
  }

  static String encodeJson(DeviceProfile profile) => jsonEncode(profile.toJson());

  static DeviceProfile decodeJson(String source) =>
      DeviceProfile.fromJson(jsonDecode(source) as Map<String, dynamic>);
}
