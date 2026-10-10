import '../data/models/detector_config.dart';
import '../data/models/sample.dart';
import '../data/models/trigger_event.dart';
import 'quake_detector.dart';

class AnalysisResult {
  const AnalysisResult({
    required this.series,
    required this.eventPositions,
    required this.events,
    required this.peak,
    required this.durationMs,
  });

  /// Down-sampled magnitude series (max per bucket) for plotting.
  final List<double> series;

  /// X position (index in [series]) for each event start.
  final List<double> eventPositions;
  final List<TriggerEvent> events;
  final double peak;
  final int durationMs;
}

class OfflineAnalyzer {
  OfflineAnalyzer._();

  static const int _targetPoints = 600;

  static AnalysisResult run(List<Sample> samples, DetectorConfig config) {
    if (samples.isEmpty) {
      return const AnalysisResult(
          series: [], eventPositions: [], events: [], peak: 0, durationMs: 0);
    }

    final detector = QuakeDetector(config);
    final mags = <double>[];
    final events = <TriggerEvent>[];

    for (final s in samples) {
      final out = detector.process(s);
      mags.add(out.magnitude);
      if (out.finished != null) events.add(out.finished!);
    }
    final tail = detector.flush(samples.last.tMs);
    if (tail != null) events.add(tail);

    final bucket = (mags.length / _targetPoints).ceil().clamp(1, 1 << 30);
    final series = <double>[];
    var peak = 0.0;
    for (var i = 0; i < mags.length; i += bucket) {
      var m = 0.0;
      final end = (i + bucket < mags.length) ? i + bucket : mags.length;
      for (var j = i; j < end; j++) {
        if (mags[j] > m) m = mags[j];
      }
      if (m > peak) peak = m;
      series.add(m);
    }

    final total = samples.last.tMs <= 0 ? 1 : samples.last.tMs;
    final positions = events
        .map((e) => (e.startMs / total * (series.length - 1)).clamp(
            0.0, (series.length - 1).toDouble()))
        .toList();

    return AnalysisResult(
      series: series,
      eventPositions: positions,
      events: events,
      peak: peak,
      durationMs: samples.last.tMs,
    );
  }
}
