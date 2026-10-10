import 'package:sensors_plus/sensors_plus.dart';

import '../data/models/sample.dart';

/// Thin wrapper around the platform accelerometer.
///
/// Each call to [samples] starts its own clock so timestamps always begin
/// at zero for the subscriber.
class SensorService {
  Stream<Sample> samples(int rateHz) async* {
    final period = Duration(microseconds: 1000000 ~/ rateHz);
    final clock = Stopwatch()..start();
    await for (final e in accelerometerEventStream(samplingPeriod: period)) {
      yield Sample(clock.elapsedMilliseconds, e.x, e.y, e.z);
    }
  }
}
