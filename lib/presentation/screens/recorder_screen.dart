import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../providers/recorder_provider.dart';
import '../widgets/app_card.dart';
import '../widgets/section_header.dart';

class RecorderScreen extends StatelessWidget {
  const RecorderScreen({super.key, required this.onOpenLibrary});

  final VoidCallback onOpenLibrary;

  @override
  Widget build(BuildContext context) {
    final r = context.watch<RecorderProvider>();
    final locked = r.recording || r.saving;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Text('Sensor recorder',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          const Text(
            'Capture labelled raw accelerometer data. You will tune the detector on these files.',
            style: TextStyle(color: AppColors.textDim),
          ),
          const SizedBox(height: 20),
          _RecordPanel(r: r),
          if (r.lastSaved != null) ...[
            const SizedBox(height: 14),
            AppCard(
              borderColor: AppColors.primary.withOpacity(0.5),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Recording saved',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        Text(
                          '${r.lastSaved!.label} · ${formatDuration(r.lastSaved!.durationMs)} · ${r.lastSaved!.sampleCount} samples',
                          style: const TextStyle(
                              color: AppColors.textDim, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  TextButton(onPressed: onOpenLibrary, child: const Text('Open')),
                  IconButton(
                    onPressed: r.dismissLastSaved,
                    icon: const Icon(Icons.close_rounded, size: 18),
                  ),
                ],
              ),
            ),
          ],
          const SectionHeader('What are you recording?'),
          AbsorbPointer(
            absorbing: locked,
            child: Opacity(
              opacity: locked ? 0.5 : 1,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final l in AppConstants.recordingLabels)
                    ChoiceChip(
                      label: Text(l),
                      selected: r.label == l,
                      onSelected: (_) => r.setLabel(l),
                      showCheckmark: false,
                      selectedColor: AppColors.primary.withOpacity(0.2),
                      backgroundColor: AppColors.surface,
                      side: BorderSide(
                          color: r.label == l
                              ? AppColors.primary
                              : AppColors.border),
                      labelStyle: TextStyle(
                          color: r.label == l
                              ? AppColors.primary
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w600),
                    ),
                ],
              ),
            ),
          ),
          const SectionHeader('Duration'),
          AbsorbPointer(
            absorbing: locked,
            child: Opacity(
              opacity: locked ? 0.5 : 1,
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<int>(
                  showSelectedIcon: false,
                  segments: [
                    for (final d in AppConstants.recordingDurations)
                      ButtonSegment(
                        value: d,
                        label: Text(d == 0
                            ? 'Manual'
                            : d >= 60
                                ? '${d ~/ 60}m'
                                : '${d}s'),
                      ),
                  ],
                  selected: {r.durationSec},
                  onSelectionChanged: (s) => r.setDuration(s.first),
                ),
              ),
            ),
          ),
          const SectionHeader('Note (optional)'),
          TextField(
            enabled: !locked,
            onChanged: r.setNote,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'e.g. Samsung A14, on wooden desk, truck 20 m away',
              hintStyle: const TextStyle(color: AppColors.textDim),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
          const SectionHeader('Suggested data set'),
          const AppCard(
            child: Column(
              children: [
                _Tip(Icons.table_restaurant_rounded,
                    'Table (still): 3 × 5 min - your noise baseline'),
                _Tip(Icons.local_shipping_rounded,
                    'Truck passing: 3 × 60 s near a road'),
                _Tip(Icons.back_hand_rounded,
                    'Tap & drop a cushion: 5 × 30 s each'),
                _Tip(Icons.vibration_rounded,
                    'Shake the table by hand: 5 × 30 s - closest to a quake'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordPanel extends StatelessWidget {
  const _RecordPanel({required this.r});
  final RecorderProvider r;

  @override
  Widget build(BuildContext context) {
    final color = r.recording ? AppColors.danger : AppColors.primary;
    final remaining = r.durationSec > 0
        ? (r.durationSec * 1000 - r.elapsedMs).clamp(0, 1 << 30)
        : null;

    return AppCard(
      borderColor: r.recording ? AppColors.danger.withOpacity(0.5) : null,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        children: [
          Text(
            formatDuration(r.elapsedMs),
            style: const TextStyle(
              fontSize: 54,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            r.recording
                ? (remaining != null
                    ? '${formatDuration(remaining)} remaining · ${r.sampleCount} samples'
                    : '${r.sampleCount} samples')
                : r.saving
                    ? 'Saving...'
                    : 'Ready · ${r.label}',
            style: const TextStyle(color: AppColors.textDim),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: r.recording ? (r.level / 1.5).clamp(0.02, 1.0) : 0,
              minHeight: 8,
              color: color,
              backgroundColor: AppColors.surfaceHigh,
            ),
          ),
          const SizedBox(height: 4),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Live vibration level',
                style: TextStyle(color: AppColors.textDim, fontSize: 11)),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              onPressed: r.saving
                  ? null
                  : () => r.recording ? r.stop() : r.start(),
              style: FilledButton.styleFrom(
                backgroundColor: color,
                foregroundColor: r.recording ? Colors.white : Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
              ),
              icon: Icon(r.recording
                  ? Icons.stop_rounded
                  : Icons.fiber_manual_record_rounded),
              label: Text(r.recording ? 'Stop & save' : 'Start recording',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  const _Tip(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
