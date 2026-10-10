import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/detector_config.dart';

class SettingsRepository {
  SettingsRepository(this._prefs);

  static const String _key = 'detector_config_v1';
  final SharedPreferences _prefs;

  DetectorConfig load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return DetectorConfig.defaults;
    try {
      return DetectorConfig.fromMap(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return DetectorConfig.defaults;
    }
  }

  Future<void> save(DetectorConfig config) =>
      _prefs.setString(_key, jsonEncode(config.toMap()));
}
