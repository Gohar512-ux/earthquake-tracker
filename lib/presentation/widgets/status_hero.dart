import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/monitor_provider.dart';

class StatusStyle {
  const StatusStyle(this.title, this.subtitle, this.color, this.icon);
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
}

StatusStyle styleFor(MonitorStatus s) {
  switch (s) {
    case MonitorStatus.idle:
      return const StatusStyle(
          'Monitoring is off',
          'Lay the phone flat on a stable surface, then start.',
          AppColors.textDim,
          Icons.sensors_off_rounded);
    case MonitorStatus.waitingForPower:
      return const StatusStyle(
          'Waiting for charger',
          'Plug the phone in - it only arms while charging.',
          AppColors.warning,
          Icons.power_off_rounded);
    case MonitorStatus.calibrating:
      return const StatusStyle(
          'Calibrating noise floor',
          'Keep the phone perfectly still.',
          AppColors.info,
          Icons.tune_rounded);
    case MonitorStatus.armed:
      return const StatusStyle('Armed - listening',
          'Watching for a P-wave onset.', AppColors.primary, Icons.sensors_rounded);
    case MonitorStatus.noisy:
      return const StatusStyle(
          'Too much movement',
          'Set the phone down and leave it alone to re-arm.',
          AppColors.warning,
          Icons.vibration_rounded);
    case MonitorStatus.triggered:
      return const StatusStyle('Vibration detected',
          'Analysing the shape of the signal...', AppColors.danger, Icons.bolt_rounded);
  }
}

class StatusHero extends StatefulWidget {
  const StatusHero({
    super.key,
    required this.status,
    required this.running,
    required this.calibration,
    required this.onToggle,
  });

  final MonitorStatus status;
  final bool running;
  final double calibration;
  final VoidCallback onToggle;

  @override
  State<StatusHero> createState() => _StatusHeroState();
}

class _StatusHeroState extends State<StatusHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final st = styleFor(widget.status);
    final animate = widget.running &&
        (widget.status == MonitorStatus.armed ||
            widget.status == MonitorStatus.triggered);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: st.color.withOpacity(0.35)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [st.color.withOpacity(0.16), AppColors.surface],
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 150,
            height: 150,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (animate)
                  AnimatedBuilder(
                    animation: _pulse,
                    builder: (_, __) {
                      final t = _pulse.value;
                      return Container(
                        width: 90 + 60 * t,
                        height: 90 + 60 * t,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: st.color.withOpacity((1 - t) * 0.5),
                              width: 2),
                        ),
                      );
                    },
                  ),
                if (widget.status == MonitorStatus.calibrating)
                  SizedBox(
                    width: 104,
                    height: 104,
                    child: CircularProgressIndicator(
                      value: widget.calibration.clamp(0.0, 1.0),
                      strokeWidth: 4,
                      color: st.color,
                      backgroundColor: AppColors.border,
                    ),
                  ),
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: st.color.withOpacity(0.18),
                  ),
                  child: Icon(st.icon, size: 42, color: st.color),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(st.title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(st.subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textDim)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: widget.onToggle,
              style: FilledButton.styleFrom(
                backgroundColor:
                    widget.running ? AppColors.surfaceHigh : AppColors.primary,
                foregroundColor:
                    widget.running ? AppColors.textPrimary : Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              icon: Icon(widget.running
                  ? Icons.stop_rounded
                  : Icons.play_arrow_rounded),
              label: Text(widget.running ? 'Stop monitoring' : 'Start monitoring',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
