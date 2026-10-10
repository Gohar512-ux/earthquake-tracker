import '../data/models/trigger_event.dart';

enum DetectorState { calibrating, armed, noisy, triggered }

class DetectorOutput {
  const DetectorOutput({
    required this.magnitude,
    required this.sta,
    required this.lta,
    required this.ratio,
    required this.state,
    required this.calibration,
    this.finished,
  });

  /// Band-passed ground-motion magnitude in m/s².
  final double magnitude;
  final double sta;
  final double lta;
  final double ratio;
  final DetectorState state;

  /// 0..1 while the long-term average is warming up.
  final double calibration;

  /// Set on the sample where an event ends.
  final TriggerEvent? finished;
}
