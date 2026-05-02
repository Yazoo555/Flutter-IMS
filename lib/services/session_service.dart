import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../screens/auth/login_screen.dart';
import 'dashboard_service.dart';
import 'inventory_service.dart';
import 'logistics_service.dart';

class SessionService {
  static final SessionService _instance = SessionService._internal();
  factory SessionService() => _instance;
  SessionService._internal();

  StreamSubscription<AuthState>? _authSubscription;
  Timer? _validationTimer;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Initialize the session listener
  void initialize() {
    _authSubscription?.cancel();
    _authSubscription = supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      debugPrint('Auth Event: $event');

      if (event == AuthChangeEvent.signedOut || (event == AuthChangeEvent.tokenRefreshed && session == null)) {
        _handleInvalidSession();
      }
    });

    // Periodically validate session (e.g., every minute)
    _validationTimer?.cancel();
    _validationTimer = Timer.periodic(const Duration(minutes: 1), (_) => validateSession());
  }

  /// Manually trigger a session validation check
  Future<void> validateSession() async {
    if (supabase.auth.currentSession == null) return;

    try {
      // getUser() validates the current JWT with the Supabase server.
      // If the session is invalid or the password was changed elsewhere, this will throw.
      await supabase.auth.getUser();
    } catch (e) {
      debugPrint('Session validation failed: $e');
      // If we get an auth error, handle it
      if (e is AuthException) {
        _handleInvalidSession();
      }
    }
  }

  /// Handle cases where the session becomes invalid (e.g., password changed elsewhere)
  void _handleInvalidSession() {
    debugPrint('Session invalidated. Redirecting to login...');
    _clearLocalData();
    
    // Use navigatorKey to push to login from anywhere
    if (navigatorKey.currentState != null) {
      navigatorKey.currentState!.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  /// Centralized logout logic
  Future<void> logout({bool global = false}) async {
    try {
      if (global) {
        // This invalidates ALL sessions for this user across all devices
        await supabase.auth.signOut(scope: SignOutScope.global);
      } else {
        // Local sign out only
        await supabase.auth.signOut(scope: SignOutScope.local);
      }
    } catch (e) {
      debugPrint('Error during sign out: $e');
    } finally {
      _handleInvalidSession();
    }
  }

  /// Clear all cached data from various services
  void _clearLocalData() {
    // Clear in-memory and disk caches of all services
    DashboardService.clearCache();
    InventoryService.clearCache();
    LogisticsService.clearCache();
  }

  void dispose() {
    _authSubscription?.cancel();
    _validationTimer?.cancel();
  }
}

// Global instance
final sessionService = SessionService();
