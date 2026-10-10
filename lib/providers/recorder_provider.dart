import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../core/constants/app_constants.dart';
import '../data/models/recording_meta.dart';
import '../data/models/sample.dart';
import '../data/repositories/recording_repository.dart';
import '../services/sensor_service.dart';
import 'settings_provider.dart';

class RecorderProvider extends ChangeNotifier {
  RecorderProvider(this._sensor, this._repo, this._settings, {this.onSaved});

  final SensorService _sensor;
  final RecordingRepository _repo;
  final SettingsProvider _settings;
  final VoidCallback? onSaved;

  String label = AppConstants.recordingLabels.first;
  int durationSec = 30;
  String note = '';

  bool _recording = false;
  bool _saving = false;
  int _elapsedMs = 0;
  int _count = 0;
  double _level = 0;
  RecordingMeta? _lastSaved;

  final List<Sample> _buffer = [];
  StreamSubscription<Sample>? _sub;
  Timer? _ticker;
  DateTime? _created;

  bool get recording => _recording;
  bool get saving => _saving;
  int get elapsedMs => _elapsedMs;
  int get sampleCount => _count;
  double get level => _level;
  RecordingMeta? get lastSaved => _lastSaved;

  void setLabel(String v) {
    label = v;
    notifyListeners();
  }

  void setDuration(int v) {
    durationSec = v;
    notifyListeners();
  }

  void setNote(String v) => note = v;

  void dismissLastSaved() {
    _lastSaved = null;
    notifyListeners();
  }

  Future<void> start() async {
    if (_recording) return;
    _buffer.clear();
    _count = 0;
    _elapsedMs = 0;
    _level = 0;
    _created = DateTime.now();
    _recording = true;
    _lastSaved = null;
    await WakelockPlus.enable();

    final clock = Stopwatch()..start();
    _sub = _sensor.samples(_settings.config.sampleRateHz).listen((s) {
      _buffer.add(s);
      _count = _buffer.length;
      final norm = math.sqrt(s.x * s.x + s.y * s.y + s.z * s.z);
      final dev = (norm - AppConstants.gravity).abs();
      _level = _level * 0.8 + dev * 0.2;
    });
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _elapsedMs = clock.elapsedMilliseconds;
      if (durationSec > 0 && _elapsedMs >= durationSec * 1000) {
        stop();
      } else {
        notifyListeners();
      }
    });
    notifyListeners();
  }

  Future<void> stop() async {
    if (!_recording) return;
    _recording = false;
    _saving = true;
    _ticker?.cancel();
    await _sub?.cancel();
    _sub = null;
    await WakelockPlus.disable();
    notifyListeners();

    try {
      if (_buffer.length > 10) {
        _lastSaved = await _repo.save(
          label: label,
          note: note,
          samples: List<Sample>.from(_buffer),
          created: _created ?? DateTime.now(),
        );
        onSaved?.call();
      }
    } finally {
      _buffer.clear();
      _saving = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _sub?.cancel();
    WakelockPlus.disable();
    super.dispose();
  }
}
