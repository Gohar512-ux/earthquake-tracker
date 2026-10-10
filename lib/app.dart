import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/recording_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'presentation/screens/home_shell.dart';
import 'providers/monitor_provider.dart';
import 'providers/recorder_provider.dart';
import 'providers/recordings_provider.dart';
import 'providers/settings_provider.dart';
import 'services/sensor_service.dart';

class QuakeWatchApp extends StatelessWidget {
  const QuakeWatchApp({super.key, required this.prefs});

  final SharedPreferences prefs;

  @override
  Widget build(BuildContext context) {
    final sensor = SensorService();
    final recordingRepo = RecordingRepository();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(SettingsRepository(prefs)),
        ),
        ChangeNotifierProvider(
          create: (_) => RecordingsProvider(recordingRepo),
        ),
        ChangeNotifierProvider(
          create: (ctx) => MonitorProvider(sensor, ctx.read<SettingsProvider>()),
        ),
        ChangeNotifierProvider(
          create: (ctx) => RecorderProvider(
            sensor,
            recordingRepo,
            ctx.read<SettingsProvider>(),
            onSaved: ctx.read<RecordingsProvider>().refresh,
          ),
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.dark,
        home: const HomeShell(),
      ),
    );
  }
}
