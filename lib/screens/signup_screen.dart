import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import '../widgets/labeled_text_field.dart';
import '../widgets/primary_button.dart';
import 'otp_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  // bool _isPasswordVisible = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Username validation method
  String? _validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a username';
    }

    final username = value.trim();

    if (username.length < 3) {
      return 'Username must be at least 3 characters';
    }

    if (username.length > 35) {
      return 'Username must not exceed 35 characters';
    }

    if (!RegExp(r'^[a-zA-Z0-9\s_]+$').hasMatch(username)) {
      return 'Username can only contain letters, numbers, spaces, and underscores';
    }

    return null;
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

  // Password validation method
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }

    // Check minimum length (8 characters)
    if (value.length < 8) {
      return 'Password must be at least 8 characters (current: ${value.length})';
    }

    // Check maximum length (10 characters)
    if (value.length > 10) {
      return 'Password must not exceed 10 characters (current: ${value.length})';
    }

    // Check for letters and numbers
    if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)').hasMatch(value)) {
      return 'Password must contain both letters and numbers';
    }

    return null;
  }

  Future<void> _handleSignUp() async {
    // Validate form
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final username = _usernameController.text.trim();

      // Attempt to sign up
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'username': username,
          'created_at': DateTime.now().toIso8601String(),
        },
      );

      // Check if user was created
      if (response.user == null) {
        _showError('Failed to create account. Please try again.');
        return;
      }

      if (!mounted) return;

      // Check if email confirmation is required
      final needsEmailVerification = response.user?.emailConfirmedAt == null;

      if (needsEmailVerification) {
        _showSuccess('Verification code sent to $email');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OtpScreen(email: email, otpType: OtpType.signup),
          ),
        );
      } else {
        _showSuccess('Account created successfully!');
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.popUntil(context, (route) => route.isFirst);
          }
        });
      }
    } on AuthException catch (e) {
      String errorMessage = e.message;
      if (errorMessage.contains('User already registered')) {
        errorMessage =
            'An account with this email already exists. Please login instead.';
      } else if (errorMessage.contains('Password should be at least')) {
        errorMessage = 'Password must be at least 8 characters long.';
      } else if (errorMessage.contains('Password should not be leaked')) {
        errorMessage =
            'This password is too common. Please choose a stronger password.';
      } else if (errorMessage.contains('Email confirmation required')) {
        errorMessage =
            'Please verify your email address. Check your inbox for the confirmation link.';
      }
      _showError(errorMessage);
    } catch (e) {
      debugPrint('Signup error: $e');
      _showError(
        'Unable to create account. Please check your internet connection and try again.',
      );
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
              key: const ValueKey('signup_form'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Row(
                  children: [
                    const AppLogo(),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.close,
                          color: AppTheme.textSecondary,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 44),
                const Text('Create Account', style: AppTheme.heading1),
                const SizedBox(height: 10),
                const Text(
                  'Fill in your details to get started.',
                  style: AppTheme.bodyMedium,
                ),
                const SizedBox(height: 36),

                // Username Field
                LabeledTextField(
                  label: 'USERNAME',
                  hintText: 'Enter your username',
                  controller: _usernameController,
                  maxLength: 35, // Restrict input to 35 characters
                  prefixIcon: const Icon(
                    Icons.person_outline_rounded,
                    color: AppTheme.textHint,
                    size: 20,
                  ),
                  validator: _validateUsername,
                ),
                const SizedBox(height: 20),

                // Email Field
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

                // Password Field with maxLength
                LabeledTextField(
                  label: 'PASSWORD',
                  hintText: 'Create a password',
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

                // Password Requirements Hint (One-liner)
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLighter,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.primaryLight),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Password must be 8-10 characters long and contain both letters and numbers',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Sign Up Button
                PrimaryButton(
                  label: 'Sign Up',
                  onPressed: _handleSignUp,
                  isLoading: _isLoading,
                  showArrow: true,
                ),

                const SizedBox(height: 36),

                // Divider
                const Divider(color: AppTheme.divider, height: 1),
                const SizedBox(height: 24),

                // Login Link
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text('Log In', style: AppTheme.linkText),
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
