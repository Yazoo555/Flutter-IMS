import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/home_screen.dart';
import 'services/theme_service.dart';

const supabaseUrl = 'https://zinognrruckgcmrxgzro.supabase.co';
const supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inppbm9nbnJydWNrZ2NtcnhnenJvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ2MDY4ODIsImV4cCI6MjA5MDE4Mjg4Mn0.l1fN3dKA_b3QAIIfQrAuSf_h_tRuoElR-9vPSew_aeA';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  // Load saved theme mode
  final savedThemeMode = await ThemeService.loadThemeMode();
  themeModeNotifier.value = savedThemeMode;

  // Listen for theme changes and save them
  themeModeNotifier.addListener(() {
    ThemeService.saveThemeMode(themeModeNotifier.value);
  });

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const InventoryApp());
}

final supabase = Supabase.instance.client;

/// Global theme-mode notifier — any widget can read or toggle it.
final themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);

class InventoryApp extends StatelessWidget {
  const InventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'IMS',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.theme,
          darkTheme: AppTheme.darkTheme,
          themeMode: mode,
          home: supabase.auth.currentSession != null
              ? const HomeScreen()
              : const LoginScreen(),
        );
      },
    );
  }
}
