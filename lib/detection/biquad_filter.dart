import 'dart:math' as math;

/// Second-order IIR section (RBJ cookbook), transposed direct form II.
class BiquadFilter {
  BiquadFilter._(this._b0, this._b1, this._b2, this._a1, this._a2);

  final double _b0, _b1, _b2, _a1, _a2;
  double _z1 = 0, _z2 = 0;

  factory BiquadFilter.lowPass(double fs, double fc, {double q = 0.7071}) {
    final w0 = 2 * math.pi * fc / fs;
    final cosW = math.cos(w0);
    final alpha = math.sin(w0) / (2 * q);
    final a0 = 1 + alpha;
    return BiquadFilter._(
      (1 - cosW) / 2 / a0,
      (1 - cosW) / a0,
      (1 - cosW) / 2 / a0,
      -2 * cosW / a0,
      (1 - alpha) / a0,
    );
  }

  factory BiquadFilter.highPass(double fs, double fc, {double q = 0.7071}) {
    final w0 = 2 * math.pi * fc / fs;
    final cosW = math.cos(w0);
    final alpha = math.sin(w0) / (2 * q);
    final a0 = 1 + alpha;
    return BiquadFilter._(
      (1 + cosW) / 2 / a0,
      -(1 + cosW) / a0,
      (1 + cosW) / 2 / a0,
      -2 * cosW / a0,
      (1 - alpha) / a0,
    );
  }

  double process(double x) {
    final y = _b0 * x + _z1;
    _z1 = _b1 * x - _a1 * y + _z2;
    _z2 = _b2 * x - _a2 * y;
    return y;
  }

  void reset() {
    _z1 = 0;
    _z2 = 0;
  }
}
