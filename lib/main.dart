import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://zinognrruckgcmrxgzro.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inppbm9nbnJydWNrZ2NtcnhnenJvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ2MDY4ODIsImV4cCI6MjA5MDE4Mjg4Mn0.l1fN3dKA_b3QAIIfQrAuSf_h_tRuoElR-9vPSew_aeA',
  );

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const InventoryApp());
}

final supabase = Supabase.instance.client;

class InventoryApp extends StatelessWidget {
  const InventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IMS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: supabase.auth.currentSession != null
          ? const HomeScreen()
          : const LoginScreen(),
    );
  }
}
