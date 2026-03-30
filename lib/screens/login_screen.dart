import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import '../widgets/labeled_text_field.dart';
import '../widgets/primary_button.dart';
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

  // Email validation method with length restriction
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email';
    }

    final email = value.trim();

    // Check email length (max 35 characters)
    if (email.length > 35) {
      return 'Email must not exceed 35 characters (current: ${email.length})';
    }

    // Check email format
    if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      return 'Please enter a valid email';
    }

    return null;
  }

  // Password validation method for login
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }

    // Check minimum length (8 characters)
    if (value.length < 8) {
      return 'Password must be at least 8 characters (current: ${value.length})';
    }

    // Check maximum length (10 characters)
    if (value.length > 10) {
      return 'Password must not exceed 10 characters (current: ${value.length})';
    }

    return null;
  }

  /// Signs the user in with email + password, then sends an OTP for
  /// two-factor-style verification before granting full access.
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      // 1. Verify credentials first (password check)
      await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // 2. Send OTP to the same email for second-step verification
      await supabase.auth.signInWithOtp(
        email: _emailController.text.trim(),
        shouldCreateUser: false, // user already exists
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const AppLogo(),
                const SizedBox(height: 52),
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
                  maxLength: 35, // Restrict input to 35 characters
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
                  maxLength: 10, // Restrict input to 10 characters
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
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
