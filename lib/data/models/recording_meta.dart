class RecordingMeta {
  const RecordingMeta({
    required this.path,
    required this.name,
    required this.label,
    required this.rateHz,
    required this.created,
    required this.sampleCount,
    required this.durationMs,
    this.note = '',
  });

  final String path;
  final String name;
  final String label;
  final double rateHz;
  final DateTime created;
  final int sampleCount;
  final int durationMs;
  final String note;
}
