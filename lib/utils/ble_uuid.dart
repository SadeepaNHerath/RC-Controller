import 'package:flutter_blue_plus/flutter_blue_plus.dart';

String shortUuid(Guid uuid) {
  final value = uuid.str.toUpperCase();
  if (value.length == 36) {
    return value.split('-').first;
  }
  return value;
}
