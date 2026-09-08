import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/app_shell.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const FypCalendarApp());
}

/// FYP Calendar — Cohort 11 • Final Year Project Planner.
class FypCalendarApp extends StatefulWidget {
  const FypCalendarApp({super.key});

  @override
  State<FypCalendarApp> createState() => _FypCalendarAppState();
}

class _FypCalendarAppState extends State<FypCalendarApp> {
  ThemeMode _themeMode = ThemeMode.dark;
  final _storage = StorageService();

  @override
  void initState() {
    super.initState();
    _storage.loadThemeMode().then((mode) {
      if (!mounted) return;
      setState(() => _themeMode = mode);
    });
  }

  void _setThemeMode(ThemeMode mode) {
    setState(() => _themeMode = mode);
    _storage.saveThemeMode(mode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FYP Calendar',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _themeMode,
      home: AppShell(
        themeMode: _themeMode,
        onThemeModeChanged: _setThemeMode,
      ),
    );
  }
}
