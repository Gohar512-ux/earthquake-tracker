import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../detection/detector_output.dart';
import '../../providers/monitor_provider.dart';
import '../../providers/settings_provider.dart';
import '../widgets/app_card.dart';
import '../widgets/condition_chip.dart';
import '../widgets/empty_state.dart';
import '../widgets/event_tile.dart';
import '../widgets/live_line_chart.dart';
import '../widgets/section_header.dart';
import '../widgets/stat_tile.dart';
import '../widgets/status_hero.dart';

class MonitorScreen extends StatelessWidget {
  const MonitorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final m = context.watch<MonitorProvider>();
    final cfg = context.watch<SettingsProvider>().config;
    final out = m.last;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.public_rounded, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppConstants.appName,
                        style: Theme.of(context).textTheme.headlineSmall),
                    const Text('Phone seismometer',
                        style: TextStyle(color: AppColors.textDim, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          StatusHero(
            status: m.status,
            running: m.running,
            calibration: m.calibration,
            onToggle: () => m.running ? m.stop() : m.start(),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ConditionChip(
                  label: cfg.requireCharging ? 'Charging (required)' : 'Charging',
                  ok: m.charging),
              ConditionChip(
                  label: 'Calibrated',
                  ok: m.running && m.status != MonitorStatus.calibrating),
              ConditionChip(
                  label: 'Phone still',
                  ok: m.running &&
                      m.status != MonitorStatus.noisy &&
                      m.status != MonitorStatus.calibrating),
            ],
          ),
          const SectionHeader('Live signal'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _ChartTitle('Ground motion', 'm/s² · band-passed 1-10 Hz'),
                const SizedBox(height: 10),
                LiveLineChart(
                  values: m.magnitudes,
                  color: AppColors.primary,
                  minMaxY: 0.1,
                ),
                const SizedBox(height: 18),
                _ChartTitle('STA / LTA ratio',
                    'trigger at ${cfg.triggerRatio.toStringAsFixed(1)}'),
                const SizedBox(height: 10),
                LiveLineChart(
                  values: m.ratios,
                  color: AppColors.info,
                  height: 110,
                  minMaxY: cfg.triggerRatio * 1.3,
                  thresholdY: cfg.triggerRatio,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: StatTile(
                      label: 'Motion',
                      value: (out?.magnitude ?? 0).toStringAsFixed(3))),
              const SizedBox(width: 10),
              Expanded(
                  child: StatTile(
                      label: 'STA', value: (out?.sta ?? 0).toStringAsFixed(3))),
              const SizedBox(width: 10),
              Expanded(
                  child: StatTile(
                      label: 'LTA', value: (out?.lta ?? 0).toStringAsFixed(3))),
              const SizedBox(width: 10),
              Expanded(
                child: StatTile(
                  label: 'Ratio',
                  value: (out?.ratio ?? 0).toStringAsFixed(1),
                  color: (out?.state == DetectorState.triggered)
                      ? AppColors.danger
                      : null,
                ),
              ),
            ],
          ),
          SectionHeader(
            'Detected events',
            trailing: m.events.isEmpty
                ? null
                : TextButton(
                    onPressed: m.clearEvents,
                    child: const Text('Clear'),
                  ),
          ),
          if (m.events.isEmpty)
            const AppCard(
              child: SizedBox(
                height: 250,
                child: EmptyState(
                  icon: Icons.waves_rounded,
                  title: 'Nothing detected',
                  message:
                      'Events appear here with their classification. Tap the table gently to test.',
                ),
              ),
            )
          else
            ...m.events.map((e) => EventTile(event: e)),
          const SizedBox(height: 16),
          const _Disclaimer(),
        ],
      ),
    );
  }
}

class _ChartTitle extends StatelessWidget {
  const _ChartTitle(this.title, this.subtitle);
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const Spacer(),
        Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _Disclaimer extends StatelessWidget {
  const _Disclaimer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(AppConstants.disclaimer,
                style: TextStyle(color: AppColors.textDim, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
