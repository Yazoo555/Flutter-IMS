import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/app_theme.dart';
import 'models/storage_service.dart';
import 'screens/app_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0B0F19),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const StudentHubApp());
}

class StudentHubApp extends StatefulWidget {
  const StudentHubApp({super.key});

  @override
  State<StudentHubApp> createState() => _StudentHubAppState();
}

class _StudentHubAppState extends State<StudentHubApp> {
  bool _isDark = true;
  final _storage = StorageService();

  @override
  void initState() {
    super.initState();
    _storage.loadDarkMode().then((v) => setState(() => _isDark = v));
  }

  void _toggleTheme() {
    setState(() => _isDark = !_isDark);
    _storage.saveDarkMode(_isDark);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Hub',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _isDark ? ThemeMode.dark : ThemeMode.light,
      home: AppShell(
        isDarkMode: _isDark,
        onToggleTheme: _toggleTheme,
      ),
    );
  }
}
