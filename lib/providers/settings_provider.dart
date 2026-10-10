import 'package:flutter/foundation.dart';

import '../data/models/detector_config.dart';
import '../data/repositories/settings_repository.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this._repo) : _config = _repo.load();

  final SettingsRepository _repo;
  DetectorConfig _config;

  DetectorConfig get config => _config;

  Future<void> update(DetectorConfig next) async {
    // Keep the band-pass below the Nyquist frequency.
    final maxHigh = next.sampleRateHz * 0.4;
    var fixed = next;
    if (fixed.bandHighHz > maxHigh) fixed = fixed.copyWith(bandHighHz: maxHigh);
    if (fixed.bandLowHz >= fixed.bandHighHz - 1) {
      fixed = fixed.copyWith(bandLowHz: fixed.bandHighHz - 1);
    }
    if (fixed.detriggerRatio >= fixed.triggerRatio) {
      fixed = fixed.copyWith(detriggerRatio: fixed.triggerRatio - 0.5);
    }
    _config = fixed;
    notifyListeners();
    await _repo.save(fixed);
  }

  Future<void> reset() => update(DetectorConfig.defaults);
}
