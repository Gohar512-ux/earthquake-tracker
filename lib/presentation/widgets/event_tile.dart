import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/trigger_event.dart';
import 'app_card.dart';

class EventTile extends StatelessWidget {
  const EventTile({super.key, required this.event, this.showClock = true});

  final TriggerEvent event;
  final bool showClock;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.forKind(event.kind);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(event.kind.label,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                Text(
                  showClock
                      ? formatTimeOfDay(event.detectedAt)
                      : 't = ${(event.startMs / 1000).toStringAsFixed(1)} s',
                  style: const TextStyle(color: AppColors.textDim, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(event.kind.hint,
                style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Metric('Peak', '${event.peakAmplitude.toStringAsFixed(3)} m/s²'),
                _Metric('STA/LTA', event.peakRatio.toStringAsFixed(1)),
                _Metric('Duration',
                    '${(event.durationMs / 1000).toStringAsFixed(1)} s'),
                _Metric('Rise', '${(event.riseMs / 1000).toStringAsFixed(1)} s'),
                _Metric('Tilt', '${event.tiltDegrees.toStringAsFixed(1)}°'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(10),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 12),
          children: [
            TextSpan(
                text: '$label  ', style: const TextStyle(color: AppColors.textDim)),
            TextSpan(
                text: value,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
