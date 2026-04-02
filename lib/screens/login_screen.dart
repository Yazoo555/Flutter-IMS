import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import '../widgets/labeled_text_field.dart';
import '../widgets/primary_button.dart';
import '../utils/responsive_layout.dart'; // ← new
import 'otp_screen.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.errorColor),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email';
    }
    final email = value.trim();
    if (email.length > 35) {
      return 'Email must not exceed 35 characters (current: ${email.length})';
    }
    if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters (current: ${value.length})';
    }
    if (value.length > 10) {
      return 'Password must not exceed 10 characters (current: ${value.length})';
    }
    return null;
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      await supabase.auth.signInWithOtp(
        email: _emailController.text.trim(),
        shouldCreateUser: false,
      );

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpScreen(
            email: _emailController.text.trim(),
            otpType: OtpType.email,
          ),
        ),
      );
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        // AuthResponsiveLayout shows a two-column layout on desktop,
        // and falls back to the plain form on mobile/tablet.
        child: AuthResponsiveLayout(
          formContent: _buildFormPanel(context),
        ),
      ),
    );
  }

  Widget _buildFormPanel(BuildContext context) {
    return SingleChildScrollView(
      // On desktop the right panel has its own scroll; keep horizontal padding
      // tighter on wide screens via FormConstrainedBox below.
      padding: EdgeInsets.symmetric(
        horizontal: context.isDesktop ? 48 : 24,
      ),
      child: FormConstrainedBox(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: context.isDesktop ? 48 : 20),

              // Hide the app logo on desktop — the brand panel already shows it
              if (!context.isDesktop) ...[
                const AppLogo(),
                const SizedBox(height: 52),
              ] else
                const SizedBox(height: 16),

              const Text('Welcome Back', style: AppTheme.heading1),
              const SizedBox(height: 10),
              const Text(
                'Sign in to manage your inventory.',
                style: AppTheme.bodyMedium,
              ),
              const SizedBox(height: 36),

              LabeledTextField(
                label: 'EMAIL ADDRESS',
                hintText: 'you@example.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                maxLength: 35,
                prefixIcon: const Icon(
                  Icons.mail_outline_rounded,
                  color: AppTheme.textHint,
                  size: 20,
                ),
                validator: _validateEmail,
              ),
              const SizedBox(height: 20),

              LabeledTextField(
                label: 'PASSWORD',
                hintText: 'Enter your password',
                controller: _passwordController,
                isPassword: true,
                maxLength: 10,
                prefixIcon: const Icon(
                  Icons.lock_outline_rounded,
                  color: AppTheme.textHint,
                  size: 20,
                ),
                validator: _validatePassword,
              ),
              const SizedBox(height: 14),

              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ForgotPasswordScreen(),
                    ),
                  ),
                  child: const Text(
                    'Forgot Password?',
                    style: AppTheme.linkText,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              PrimaryButton(
                label: 'Log In',
                onPressed: _handleLogin,
                showArrow: true,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 36),

              const Divider(color: AppTheme.divider, height: 1),
              const SizedBox(height: 24),

              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Don't have an account? ",
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SignupScreen(),
                        ),
                      ),
                      child: const Text('Sign Up', style: AppTheme.linkText),
                    ),
                  ],
                ),
              ),
              SizedBox(height: context.isDesktop ? 48 : 32),
            ],
          ),
        ),
      ),
    );
  }
}