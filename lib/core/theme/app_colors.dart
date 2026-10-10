import 'package:flutter/material.dart';

import '../../data/models/trigger_event.dart';

class AppColors {
  AppColors._();

  static const Color background = Color(0xFF0B0F14);
  static const Color surface = Color(0xFF131A22);
  static const Color surfaceHigh = Color(0xFF1B2430);
  static const Color border = Color(0xFF263241);

  static const Color primary = Color(0xFF3DDC97);
  static const Color info = Color(0xFF4DA3FF);
  static const Color warning = Color(0xFFFFB020);
  static const Color danger = Color(0xFFFF5470);

  static const Color textPrimary = Color(0xFFE8EEF5);
  static const Color textDim = Color(0xFF8A97A6);

  static Color forKind(EventKind kind) {
    switch (kind) {
      case EventKind.seismic:
        return danger;
      case EventKind.impulse:
        return warning;
      case EventKind.sustained:
        return info;
      case EventKind.moved:
        return textDim;
    }
  }
}
