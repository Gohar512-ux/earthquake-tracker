import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Compact line chart used for live and offline signal plots.
class LiveLineChart extends StatelessWidget {
  const LiveLineChart({
    super.key,
    required this.values,
    required this.color,
    this.height = 140,
    this.minMaxY = 0.2,
    this.thresholdY,
    this.markerXs = const [],
    this.markerColor = AppColors.danger,
  });

  final List<double> values;
  final Color color;
  final double height;

  /// The Y axis never shrinks below this maximum.
  final double minMaxY;
  final double? thresholdY;
  final List<double> markerXs;
  final Color markerColor;

  @override
  Widget build(BuildContext context) {
    if (values.length < 2) {
      return SizedBox(
        height: height,
        child: const Center(
          child: Text('No data yet',
              style: TextStyle(color: AppColors.textDim, fontSize: 12)),
        ),
      );
    }

    var peak = 0.0;
    for (final v in values) {
      if (v > peak) peak = v;
    }
    var maxY = peak * 1.25;
    if (thresholdY != null && thresholdY! * 1.15 > maxY) {
      maxY = thresholdY! * 1.15;
    }
    if (maxY < minMaxY) maxY = minMaxY;

    final spots = <FlSpot>[
      for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i]),
    ];

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (values.length - 1).toDouble(),
          minY: 0,
          maxY: maxY,
          clipData: const FlClipData.all(),
          borderData: FlBorderData(show: false),
          titlesData: const FlTitlesData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: AppColors.border, strokeWidth: 0.6),
          ),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              if (thresholdY != null)
                HorizontalLine(
                  y: thresholdY!,
                  color: AppColors.warning.withOpacity(0.8),
                  strokeWidth: 1,
                  dashArray: [6, 4],
                ),
            ],
            verticalLines: [
              for (final x in markerXs)
                VerticalLine(
                  x: x,
                  color: markerColor.withOpacity(0.85),
                  strokeWidth: 1.5,
                  dashArray: [4, 4],
                ),
            ],
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: false,
              color: color,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData:
                  BarAreaData(show: true, color: color.withOpacity(0.12)),
            ),
          ],
        ),
        duration: Duration.zero,
      ),
    );
  }
}
