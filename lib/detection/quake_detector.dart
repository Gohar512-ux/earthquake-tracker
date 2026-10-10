import 'dart:collection';
import 'dart:math' as math;

import '../data/models/detector_config.dart';
import '../data/models/sample.dart';
import '../data/models/trigger_event.dart';
import 'biquad_filter.dart';
import 'detector_output.dart';

/// Streaming STA/LTA P-wave trigger with shape-based false-positive rejection.
///
/// Pipeline per sample:
///   raw xyz -> per-axis band-pass (1-10 Hz) -> vector magnitude
///   -> STA / LTA ratio -> trigger / de-trigger -> event classification.
class QuakeDetector {
  QuakeDetector(this.config)
      : _fs = config.sampleRateHz.toDouble(),
        _hp = List.generate(
            3,
            (_) => BiquadFilter.highPass(
                config.sampleRateHz.toDouble(), config.bandLowHz)),
        _lp = List.generate(
            3,
            (_) => BiquadFilter.lowPass(
                config.sampleRateHz.toDouble(), config.bandHighHz)) {
    _warmup = (config.ltaSeconds * _fs).round();
    _cooldownSamples = (2 * _fs).round();
    _alphaSta = 1.0 / (config.staSeconds * _fs);
    _alphaLta = 1.0 / (config.ltaSeconds * _fs);
    _alphaGravSlow = 1.0 / (5.0 * _fs);
    _alphaGravFast = 1.0 / (1.0 * _fs);
  }

  final DetectorConfig config;
  final double _fs;
  final List<BiquadFilter> _hp;
  final List<BiquadFilter> _lp;

  late final int _warmup;
  late final int _cooldownSamples;
  late final double _alphaSta;
  late final double _alphaLta;
  late final double _alphaGravSlow;
  late final double _alphaGravFast;

  static const int _maxEventMs = 60000;

  int _n = 0;
  double _sta = 0;
  double _lta = 0;
  int _cooldown = 0;

  final List<double> _gSlow = [0, 0, 0];
  final List<double> _gFast = [0, 0, 0];

  // Rolling 1 s pre-trigger history (STA lags behind sharp onsets).
  final ListQueue<int> _preT = ListQueue();
  final ListQueue<double> _preM = ListQueue();

  // Active event bookkeeping
  bool _inEvent = false;
  int _startMs = 0;
  double _peakRatio = 0;
  List<double> _baseline = [0, 0, 0];
  final List<int> _evT = [];
  final List<double> _evM = [];

  int get samplesProcessed => _n;

  DetectorOutput process(Sample s) {
    _n++;
    if (_n == 1) {
      // Settle the filters on the first reading so the gravity step does not
      // create a large start-up transient that pollutes the long-term average.
      final first = [s.x, s.y, s.z];
      final settle = (5 * _fs).round();
      for (var axis = 0; axis < 3; axis++) {
        for (var k = 0; k < settle; k++) {
          _lp[axis].process(_hp[axis].process(first[axis]));
        }
      }
      _gSlow
        ..[0] = s.x
        ..[1] = s.y
        ..[2] = s.z;
      _gFast
        ..[0] = s.x
        ..[1] = s.y
        ..[2] = s.z;
    } else {
      final raw = [s.x, s.y, s.z];
      for (var i = 0; i < 3; i++) {
        _gSlow[i] += _alphaGravSlow * (raw[i] - _gSlow[i]);
        _gFast[i] += _alphaGravFast * (raw[i] - _gFast[i]);
      }
    }

    final fx = _lp[0].process(_hp[0].process(s.x));
    final fy = _lp[1].process(_hp[1].process(s.y));
    final fz = _lp[2].process(_hp[2].process(s.z));
    final mag = math.sqrt(fx * fx + fy * fy + fz * fz);

    // Cumulative mean while warming up so the LTA converges quickly.
    final aSta = math.max(_alphaSta, 1.0 / _n);
    final aLta = math.max(_alphaLta, 1.0 / _n);
    _sta += aSta * (mag - _sta);
    if (!_inEvent) {
      _lta += aLta * (mag - _lta); // freeze LTA during an event
    }
    final ratio = _lta > 1e-6 ? _sta / _lta : 0.0;

    final calibrating = _n <= _warmup;
    final calibration = calibrating ? _n / _warmup : 1.0;

    TriggerEvent? finished;
    DetectorState state;

    if (_inEvent) {
      _evT.add(s.tMs);
      _evM.add(mag);
      if (ratio > _peakRatio) _peakRatio = ratio;

      final elapsed = s.tMs - _startMs;
      if (ratio < config.detriggerRatio || elapsed > _maxEventMs) {
        finished = _closeEvent(s.tMs);
        state = DetectorState.armed;
      } else {
        state = DetectorState.triggered;
      }
    } else if (calibrating) {
      _remember(s.tMs, mag);
      state = DetectorState.calibrating;
    } else if (_cooldown > 0) {
      _remember(s.tMs, mag);
      _cooldown--;
      state = DetectorState.armed;
    } else if (_lta > config.maxNoiseFloor) {
      _remember(s.tMs, mag);
      state = DetectorState.noisy;
    } else if (ratio >= config.triggerRatio && _sta >= config.minStaAmplitude) {
      _startEvent(s.tMs, mag, ratio);
      state = DetectorState.triggered;
    } else {
      _remember(s.tMs, mag);
      state = DetectorState.armed;
    }

    return DetectorOutput(
      magnitude: mag,
      sta: _sta,
      lta: _lta,
      ratio: ratio,
      state: state,
      calibration: calibration,
      finished: finished,
    );
  }

  /// Close any open event (used at the end of an offline recording).
  TriggerEvent? flush(int tMs) => _inEvent ? _closeEvent(tMs) : null;

  void _remember(int tMs, double mag) {
    _preT.addLast(tMs);
    _preM.addLast(mag);
    final cap = _fs.round();
    while (_preT.length > cap) {
      _preT.removeFirst();
      _preM.removeFirst();
    }
  }

  void _startEvent(int tMs, double mag, double ratio) {
    _inEvent = true;
    _startMs = tMs;
    _peakRatio = ratio;
    _baseline = List<double>.from(_gSlow);
    _evT
      ..clear()
      ..addAll(_preT)
      ..add(tMs);
    _evM
      ..clear()
      ..addAll(_preM)
      ..add(mag);
    _preT.clear();
    _preM.clear();
  }

  TriggerEvent _closeEvent(int tMs) {
    _inEvent = false;
    _cooldown = _cooldownSamples;

    // Shape analysis on the raw magnitude history of the event.
    var peak = 0.0;
    var peakMs = _startMs;
    for (var i = 0; i < _evM.length; i++) {
      if (_evM[i] > peak) {
        peak = _evM[i];
        peakMs = _evT[i];
      }
    }
    final thr = math.max(config.minStaAmplitude * 0.5, 0.2 * peak);
    var firstMs = _startMs;
    var lastMs = _startMs;
    var foundFirst = false;
    for (var i = 0; i < _evM.length; i++) {
      if (_evM[i] > thr) {
        if (!foundFirst) {
          firstMs = _evT[i];
          foundFirst = true;
        }
        lastMs = _evT[i];
      }
    }
    var halfMs = peakMs;
    for (var i = 0; i < _evM.length; i++) {
      if (_evT[i] >= firstMs && _evM[i] >= 0.5 * peak) {
        halfMs = _evT[i];
        break;
      }
    }

    final active = lastMs - firstMs;
    final rise = halfMs - firstMs;
    final tilt = _angleDeg(_baseline, _gFast);

    final EventKind kind;
    if (tilt > 10) {
      kind = EventKind.moved;
    } else if (active < 1000) {
      kind = EventKind.impulse;
    } else if (rise > 3000) {
      kind = EventKind.sustained;
    } else {
      kind = EventKind.seismic;
    }

    final event = TriggerEvent(
      startMs: firstMs,
      durationMs: active,
      peakAmplitude: peak,
      peakRatio: _peakRatio,
      riseMs: rise,
      tiltDegrees: tilt,
      kind: kind,
      detectedAt: DateTime.now(),
    );
    _evT.clear();
    _evM.clear();
    return event;
  }

  static double _angleDeg(List<double> a, List<double> b) {
    final dot = a[0] * b[0] + a[1] * b[1] + a[2] * b[2];
    final na = math.sqrt(a[0] * a[0] + a[1] * a[1] + a[2] * a[2]);
    final nb = math.sqrt(b[0] * b[0] + b[1] * b[1] + b[2] * b[2]);
    if (na < 1e-6 || nb < 1e-6) return 0;
    final c = (dot / (na * nb)).clamp(-1.0, 1.0);
    return math.acos(c) * 180 / math.pi;
  }
}
