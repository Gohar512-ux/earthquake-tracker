import 'dart:async';
import 'dart:collection';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../core/constants/app_constants.dart';
import '../data/models/sample.dart';
import '../data/models/trigger_event.dart';
import '../detection/detector_output.dart';
import '../detection/quake_detector.dart';
import '../services/sensor_service.dart';
import 'settings_provider.dart';

enum MonitorStatus { idle, waitingForPower, calibrating, armed, noisy, triggered }

class MonitorProvider extends ChangeNotifier {
  MonitorProvider(this._sensor, this._settings) {
    _initBattery();
    _settings.addListener(_onSettingsChanged);
  }

  final SensorService _sensor;
  final SettingsProvider _settings;

  StreamSubscription<Sample>? _sub;
  StreamSubscription<BatteryState>? _batterySub;
  Timer? _uiTimer;
  QuakeDetector? _detector;

  final ListQueue<double> _mag = ListQueue();
  final ListQueue<double> _ratio = ListQueue();
  final List<TriggerEvent> _events = [];

  bool _running = false;
  bool _dirty = false;
  bool _charging = false;
  MonitorStatus _status = MonitorStatus.idle;
  DetectorOutput? _last;
  DateTime? _startedAt;

  bool get running => _running;
  bool get charging => _charging;
  MonitorStatus get status => _status;
  DetectorOutput? get last => _last;
  DateTime? get startedAt => _startedAt;
  List<TriggerEvent> get events => List.unmodifiable(_events);
  List<double> get magnitudes => _mag.toList(growable: false);
  List<double> get ratios => _ratio.toList(growable: false);
  double get calibration => _last?.calibration ?? 0;

  Future<void> start() async {
    if (_running) return;
    _resetBuffers();
    _detector = QuakeDetector(_settings.config);
    _running = true;
    _startedAt = DateTime.now();
    _status = MonitorStatus.calibrating;
    await WakelockPlus.enable();
    _sub = _sensor.samples(_settings.config.sampleRateHz).listen(_onSample);
    _uiTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (_dirty) {
        _dirty = false;
        notifyListeners();
      }
    });
    notifyListeners();
  }

  Future<void> stop() async {
    if (!_running) return;
    _running = false;
    await _sub?.cancel();
    _sub = null;
    _uiTimer?.cancel();
    _uiTimer = null;
    _detector = null;
    _status = MonitorStatus.idle;
    await WakelockPlus.disable();
    notifyListeners();
  }

  void clearEvents() {
    _events.clear();
    notifyListeners();
  }

  void _onSample(Sample s) {
    final cfg = _settings.config;
    if (cfg.requireCharging && !_charging) {
      _status = MonitorStatus.waitingForPower;
      _dirty = true;
      return;
    }

    final out = _detector!.process(s);
    _last = out;
    _push(_mag, out.magnitude);
    _push(_ratio, out.ratio.clamp(0.0, 50.0).toDouble());

    switch (out.state) {
      case DetectorState.calibrating:
        _status = MonitorStatus.calibrating;
      case DetectorState.armed:
        _status = MonitorStatus.armed;
      case DetectorState.noisy:
        _status = MonitorStatus.noisy;
      case DetectorState.triggered:
        _status = MonitorStatus.triggered;
    }

    final ev = out.finished;
    if (ev != null) {
      _events.insert(0, ev);
      if (_events.length > AppConstants.maxEvents) _events.removeLast();
      HapticFeedback.heavyImpact();
    }
    _dirty = true;
  }

  void _push(ListQueue<double> q, double v) {
    q.addLast(v);
    while (q.length > AppConstants.chartWindowSamples) {
      q.removeFirst();
    }
  }

  void _resetBuffers() {
    _mag.clear();
    _ratio.clear();
    _last = null;
  }

  void _onSettingsChanged() {
    if (_running) {
      // Restart the detector with the new parameters.
      _detector = QuakeDetector(_settings.config);
      _resetBuffers();
      _status = MonitorStatus.calibrating;
      _dirty = true;
    }
  }

  Future<void> _initBattery() async {
    final battery = Battery();
    try {
      _setCharging(await battery.batteryState);
    } catch (_) {
      // Battery state is optional.
    }
    _batterySub = battery.onBatteryStateChanged.listen(_setCharging);
  }

  void _setCharging(BatteryState state) {
    final c = state == BatteryState.charging || state == BatteryState.full;
    if (c != _charging) {
      _charging = c;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _batterySub?.cancel();
    _uiTimer?.cancel();
    _settings.removeListener(_onSettingsChanged);
    WakelockPlus.disable();
    super.dispose();
  }
}
