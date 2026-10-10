import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:quake_watch/data/models/detector_config.dart';
import 'package:quake_watch/data/models/sample.dart';
import 'package:quake_watch/data/models/trigger_event.dart';
import 'package:quake_watch/detection/offline_analyzer.dart';

/// Builds a synthetic recording: quiet noise, then an optional burst.
List<Sample> _synth({
  required int seconds,
  int hz = 50,
  double noise = 0.01,
  double? burstAmp,
  double burstStart = 15,
  double burstLen = 4,
  double burstHz = 4,
}) {
  final rnd = math.Random(42);
  final out = <Sample>[];
  for (var i = 0; i < seconds * hz; i++) {
    final t = i / hz;
    var x = (rnd.nextDouble() - 0.5) * noise;
    var y = (rnd.nextDouble() - 0.5) * noise;
    var z = 9.80665 + (rnd.nextDouble() - 0.5) * noise;
    if (burstAmp != null && t >= burstStart && t < burstStart + burstLen) {
      final env = math.sin(math.pi * (t - burstStart) / burstLen);
      z += burstAmp * env * math.sin(2 * math.pi * burstHz * t);
    }
    out.add(Sample((t * 1000).round(), x, y, z));
  }
  return out;
}

void main() {
  const config = DetectorConfig();

  test('quiet signal produces no triggers', () {
    final r = OfflineAnalyzer.run(_synth(seconds: 40), config);
    expect(r.events, isEmpty);
  });

  test('a multi-second burst triggers once', () {
    final r = OfflineAnalyzer.run(_synth(seconds: 40, burstAmp: 0.5), config);
    expect(r.events.length, 1);
    expect(r.events.first.kind, isNot(EventKind.moved));
    expect(r.events.first.startMs, greaterThan(14000));
  });

  test('empty input is handled', () {
    final r = OfflineAnalyzer.run(const [], config);
    expect(r.events, isEmpty);
    expect(r.series, isEmpty);
  });
}
