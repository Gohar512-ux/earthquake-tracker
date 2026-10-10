import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/detector_config.dart';
import '../../providers/settings_provider.dart';
import '../widgets/app_card.dart';
import '../widgets/section_header.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<SettingsProvider>();
    final c = sp.config;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          Text('Detector settings',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          const Text(
            'Changes apply immediately and restart calibration if monitoring is on.',
            style: TextStyle(color: AppColors.textDim),
          ),
          const SectionHeader('Sampling'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Sample rate',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<int>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: 25, label: Text('25 Hz')),
                      ButtonSegment(value: 50, label: Text('50 Hz')),
                      ButtonSegment(value: 100, label: Text('100 Hz')),
                    ],
                    selected: {c.sampleRateHz},
                    onSelectionChanged: (s) =>
                        sp.update(c.copyWith(sampleRateHz: s.first)),
                  ),
                ),
              ],
            ),
          ),
          const SectionHeader('STA / LTA trigger'),
          AppCard(
            child: Column(
              children: [
                _SliderRow(
                  label: 'Short window (STA)',
                  value: c.staSeconds,
                  min: 0.2,
                  max: 2,
                  unit: 's',
                  decimals: 1,
                  onChanged: (v) => sp.update(c.copyWith(staSeconds: v)),
                ),
                _SliderRow(
                  label: 'Long window (LTA)',
                  value: c.ltaSeconds,
                  min: 5,
                  max: 30,
                  unit: 's',
                  decimals: 0,
                  onChanged: (v) => sp.update(c.copyWith(ltaSeconds: v)),
                ),
                _SliderRow(
                  label: 'Trigger ratio',
                  value: c.triggerRatio,
                  min: 2,
                  max: 10,
                  decimals: 1,
                  onChanged: (v) => sp.update(c.copyWith(triggerRatio: v)),
                ),
                _SliderRow(
                  label: 'De-trigger ratio',
                  value: c.detriggerRatio,
                  min: 1,
                  max: 4,
                  decimals: 1,
                  onChanged: (v) => sp.update(c.copyWith(detriggerRatio: v)),
                ),
                _SliderRow(
                  label: 'Minimum amplitude',
                  value: c.minStaAmplitude,
                  min: 0.01,
                  max: 0.3,
                  unit: 'm/s²',
                  decimals: 2,
                  onChanged: (v) => sp.update(c.copyWith(minStaAmplitude: v)),
                ),
              ],
            ),
          ),
          const SectionHeader('Filter band'),
          AppCard(
            child: Column(
              children: [
                _SliderRow(
                  label: 'High-pass',
                  value: c.bandLowHz,
                  min: 0.5,
                  max: 3,
                  unit: 'Hz',
                  decimals: 1,
                  onChanged: (v) => sp.update(c.copyWith(bandLowHz: v)),
                ),
                _SliderRow(
                  label: 'Low-pass',
                  value: c.bandHighHz,
                  min: 4,
                  max: 20,
                  unit: 'Hz',
                  decimals: 0,
                  onChanged: (v) => sp.update(c.copyWith(bandHighHz: v)),
                ),
              ],
            ),
          ),
          const SectionHeader('Arming conditions'),
          AppCard(
            child: Column(
              children: [
                _SliderRow(
                  label: 'Max noise floor',
                  value: c.maxNoiseFloor,
                  min: 0.02,
                  max: 0.4,
                  unit: 'm/s²',
                  decimals: 2,
                  onChanged: (v) => sp.update(c.copyWith(maxNoiseFloor: v)),
                ),
                const Divider(height: 24),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Only arm while charging',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text(
                      'Recommended for overnight use. Disable it for desk testing.',
                      style: TextStyle(color: AppColors.textDim, fontSize: 12)),
                  value: c.requireCharging,
                  onChanged: (v) => sp.update(c.copyWith(requireCharging: v)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => sp.update(DetectorConfig.defaults),
            icon: const Icon(Icons.restart_alt_rounded),
            label: const Text('Reset to defaults'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SectionHeader('About'),
          const AppCard(
            child: Text(
              '${AppConstants.appName} v1.0\n\n${AppConstants.disclaimer}',
              style: TextStyle(color: AppColors.textDim, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.unit = '',
    this.decimals = 1,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final String unit;
  final int decimals;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: Text(label,
                    style: const TextStyle(fontWeight: FontWeight.w600))),
            Text('${value.toStringAsFixed(decimals)} $unit'.trim(),
                style: const TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w700)),
          ],
        ),
        Slider(
          value: value.clamp(min, max).toDouble(),
          min: min,
          max: max,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
