enum EventKind { seismic, impulse, sustained, moved }

extension EventKindX on EventKind {
  String get label {
    switch (this) {
      case EventKind.seismic:
        return 'Possible seismic';
      case EventKind.impulse:
        return 'Impulse (bump/drop)';
      case EventKind.sustained:
        return 'Sustained vibration';
      case EventKind.moved:
        return 'Phone moved';
    }
  }

  String get hint {
    switch (this) {
      case EventKind.seismic:
        return 'Sudden onset, lasting more than a second, no tilt change.';
      case EventKind.impulse:
        return 'Very short, sharp spike - typical of a bump or a drop.';
      case EventKind.sustained:
        return 'Slow build-up and long duration - typical of traffic.';
      case EventKind.moved:
        return 'Gravity direction changed - the phone was picked up or tilted.';
    }
  }
}

class TriggerEvent {
  const TriggerEvent({
    required this.startMs,
    required this.durationMs,
    required this.peakAmplitude,
    required this.peakRatio,
    required this.riseMs,
    required this.tiltDegrees,
    required this.kind,
    required this.detectedAt,
  });

  final int startMs;
  final int durationMs;
  final double peakAmplitude;
  final double peakRatio;
  final int riseMs;
  final double tiltDegrees;
  final EventKind kind;
  final DateTime detectedAt;
}
