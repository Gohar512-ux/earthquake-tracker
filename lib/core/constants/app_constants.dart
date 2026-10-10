class AppConstants {
  AppConstants._();

  static const String appName = 'Quake Watch';
  static const int chartWindowSamples = 400;
  static const int maxEvents = 50;
  static const double gravity = 9.80665;

  static const List<String> recordingLabels = [
    'Table (still)',
    'Bed / sofa',
    'Truck passing',
    'Drop / bump',
    'Tap on table',
    'Shake table',
    'Walking nearby',
    'Other',
  ];

  /// 0 means manual stop.
  static const List<int> recordingDurations = [0, 10, 30, 60, 300];

  static const String disclaimer =
      'Experimental research tool. Not an official earthquake warning system. '
      'Never rely on it for safety decisions.';
}
