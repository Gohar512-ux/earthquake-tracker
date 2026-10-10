class DetectorConfig {
  const DetectorConfig({
    this.sampleRateHz = 50,
    this.staSeconds = 0.5,
    this.ltaSeconds = 10,
    this.triggerRatio = 4.0,
    this.detriggerRatio = 1.5,
    this.minStaAmplitude = 0.04,
    this.maxNoiseFloor = 0.08,
    this.bandLowHz = 1.0,
    this.bandHighHz = 10.0,
    this.requireCharging = false,
  });

  final int sampleRateHz;
  final double staSeconds;
  final double ltaSeconds;
  final double triggerRatio;
  final double detriggerRatio;

  /// Ignore triggers whose short-term amplitude (m/s²) is below this.
  final double minStaAmplitude;

  /// Detector disarms when the long-term noise (m/s²) is above this.
  final double maxNoiseFloor;
  final double bandLowHz;
  final double bandHighHz;
  final bool requireCharging;

  static const DetectorConfig defaults = DetectorConfig();

  DetectorConfig copyWith({
    int? sampleRateHz,
    double? staSeconds,
    double? ltaSeconds,
    double? triggerRatio,
    double? detriggerRatio,
    double? minStaAmplitude,
    double? maxNoiseFloor,
    double? bandLowHz,
    double? bandHighHz,
    bool? requireCharging,
  }) {
    return DetectorConfig(
      sampleRateHz: sampleRateHz ?? this.sampleRateHz,
      staSeconds: staSeconds ?? this.staSeconds,
      ltaSeconds: ltaSeconds ?? this.ltaSeconds,
      triggerRatio: triggerRatio ?? this.triggerRatio,
      detriggerRatio: detriggerRatio ?? this.detriggerRatio,
      minStaAmplitude: minStaAmplitude ?? this.minStaAmplitude,
      maxNoiseFloor: maxNoiseFloor ?? this.maxNoiseFloor,
      bandLowHz: bandLowHz ?? this.bandLowHz,
      bandHighHz: bandHighHz ?? this.bandHighHz,
      requireCharging: requireCharging ?? this.requireCharging,
    );
  }

  Map<String, dynamic> toMap() => {
        'sampleRateHz': sampleRateHz,
        'staSeconds': staSeconds,
        'ltaSeconds': ltaSeconds,
        'triggerRatio': triggerRatio,
        'detriggerRatio': detriggerRatio,
        'minStaAmplitude': minStaAmplitude,
        'maxNoiseFloor': maxNoiseFloor,
        'bandLowHz': bandLowHz,
        'bandHighHz': bandHighHz,
        'requireCharging': requireCharging,
      };

  factory DetectorConfig.fromMap(Map<String, dynamic> m) {
    const d = DetectorConfig.defaults;
    double read(String k, double fallback) =>
        (m[k] is num) ? (m[k] as num).toDouble() : fallback;
    return DetectorConfig(
      sampleRateHz: (m['sampleRateHz'] is num)
          ? (m['sampleRateHz'] as num).toInt()
          : d.sampleRateHz,
      staSeconds: read('staSeconds', d.staSeconds),
      ltaSeconds: read('ltaSeconds', d.ltaSeconds),
      triggerRatio: read('triggerRatio', d.triggerRatio),
      detriggerRatio: read('detriggerRatio', d.detriggerRatio),
      minStaAmplitude: read('minStaAmplitude', d.minStaAmplitude),
      maxNoiseFloor: read('maxNoiseFloor', d.maxNoiseFloor),
      bandLowHz: read('bandLowHz', d.bandLowHz),
      bandHighHz: read('bandHighHz', d.bandHighHz),
      requireCharging: m['requireCharging'] == true,
    );
  }
}
