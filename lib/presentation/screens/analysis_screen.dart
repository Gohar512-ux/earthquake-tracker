import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/detector_config.dart';
import '../../data/models/recording_meta.dart';
import '../../data/repositories/recording_repository.dart';
import '../../detection/offline_analyzer.dart';
import '../../providers/settings_provider.dart';
import '../widgets/app_card.dart';
import '../widgets/event_tile.dart';
import '../widgets/live_line_chart.dart';
import '../widgets/section_header.dart';
import '../widgets/stat_tile.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key, required this.meta});

  final RecordingMeta meta;

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  late final Future<AnalysisResult> _future;
  late final DetectorConfig _config;

  @override
  void initState() {
    super.initState();
    final base = context.read<SettingsProvider>().config;
    final hz = widget.meta.rateHz.round().clamp(10, 200);
    _config = base.copyWith(
      sampleRateHz: hz,
      bandHighHz: base.bandHighHz.clamp(2.0, hz * 0.4).toDouble(),
    );
    _future = _run();
  }

  Future<AnalysisResult> _run() async {
    final samples = await RecordingRepository().load(widget.meta.path);
    return OfflineAnalyzer.run(samples, _config);
  }

  @override
  Widget build(BuildContext context) {
    final meta = widget.meta;
    return Scaffold(
      appBar: AppBar(title: Text(meta.label)),
      body: FutureBuilder<AnalysisResult>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || snap.data == null) {
            return const Center(child: Text('Could not read this recording.'));
          }
          final r = snap.data!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
            children: [
              Text(
                '${formatDateTime(meta.created)} · ${formatDuration(meta.durationMs)} · ${meta.sampleCount} samples',
                style: const TextStyle(color: AppColors.textDim),
              ),
              if (meta.note.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(meta.note,
                    style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
              ],
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Filtered signal',
                            style: Theme.of(context).textTheme.titleMedium),
                        const Spacer(),
                        Text('red = trigger',
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LiveLineChart(
                      values: r.series,
                      color: AppColors.primary,
                      height: 190,
                      minMaxY: 0.1,
                      markerXs: r.eventPositions,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: StatTile(
                      label: 'Triggers',
                      value: '${r.events.length}',
                      color: r.events.isEmpty
                          ? AppColors.primary
                          : AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatTile(
                        label: 'Peak',
                        value: r.peak.toStringAsFixed(3),
                        unit: 'm/s²'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatTile(
                        label: 'Ratio ≥',
                        value: _config.triggerRatio.toStringAsFixed(1)),
                  ),
                ],
              ),
              const SectionHeader('Detections'),
              if (r.events.isEmpty)
                const AppCard(
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: AppColors.primary),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No triggers with the current settings. If this recording should have triggered, lower the STA/LTA threshold in Settings.',
                          style: TextStyle(color: AppColors.textDim),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...r.events.map((e) => EventTile(event: e, showClock: false)),
              const SizedBox(height: 8),
              const Text(
                'Replayed with your current detector settings. Tune them until every "Shake table" recording triggers and every "Table (still)" and "Truck" recording does not.',
                style: TextStyle(color: AppColors.textDim, fontSize: 12),
              ),
            ],
          );
        },
      ),
    );
  }
}
