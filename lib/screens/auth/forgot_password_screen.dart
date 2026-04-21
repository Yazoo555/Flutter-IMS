import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/labeled_text_field.dart';
import '../../widgets/primary_button.dart';
import '../../utils/responsive_layout.dart'; // ← new

enum _ForgotStep { enterEmail, resetPassword, success }

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  _ForgotStep _step = _ForgotStep.enterEmail;

  final _emailFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  final _resetFormKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.errorColor),
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
      return 'Please enter a new password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters (current: ${value.length})';
    }
    if (value.length > 10) {
      return 'Password must not exceed 10 characters (current: ${value.length})';
    }
    if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)').hasMatch(value)) {
      return 'Password must contain both letters and numbers';
    }
    return null;
  }

  Future<void> _handleContinue() async {
    if (!_emailFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final response = await supabase.rpc(
        'send_reset_otp',
        params: {'user_email': email},
      );

      if (response == true) {
        _showSuccess('OTP sent to your email address');
        if (mounted) setState(() => _step = _ForgotStep.resetPassword);
      } else {
        _showError('No account found with this email address.');
      }
    } on PostgrestException catch (e) {
      debugPrint('Send OTP error: $e');
      _showError('Failed to send OTP. Please try again.');
    } catch (e) {
      debugPrint('Send OTP error: $e');
      _showError('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleResetPassword() async {
    if (!_resetFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final otp = _otpController.text.trim();
      final newPassword = _newPasswordController.text;

      final response = await supabase.rpc(
        'reset_password_with_otp',
        params: {
          'user_email': email,
          'user_otp': otp,
          'new_password': newPassword,
        },
      );

      if (response == true) {
        _showSuccess('Password reset successfully!');
        if (mounted) setState(() => _step = _ForgotStep.success);
      } else {
        _showError('Invalid or expired OTP. Please try again.');
        _otpController.clear();
      }
    } on PostgrestException catch (e) {
      debugPrint('Reset password error: $e');
      _showError('Failed to reset password. Please try again.');
    } catch (e) {
      debugPrint('Reset password error: $e');
      _showError('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBg(context),
      body: SafeArea(
        child: AuthResponsiveLayout(
          formContent: _buildFormPanel(context),
        ),
      ),
    );
  }

  Widget _buildFormPanel(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: context.isDesktop ? 48 : 24,
      ),
      child: FormConstrainedBox(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.04, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: _buildCurrentStep(context),
        ),
      ),
    );
  }

  Widget _buildCurrentStep(BuildContext context) {
    switch (_step) {
      case _ForgotStep.enterEmail:
        return _buildEmailStep(context);
      case _ForgotStep.resetPassword:
        return _buildResetStep(context);
      case _ForgotStep.success:
        return _buildSuccessStep(context);
    }
  }

  // ─── Step 1: Enter Email ──────────────────────────────────────────────────

  Widget _buildEmailStep(BuildContext context) {
    return Form(
      key: _emailFormKey,
      child: Column(
        key: const ValueKey('email'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: context.isDesktop ? 48 : 20),
          _buildHeader(context),
          SizedBox(height: context.isDesktop ? 40 : 52),
          _buildStepBadge(1, 2),
          const SizedBox(height: 20),
          Text('Forgot Password?', style: AppTheme.heading1(context)),
          const SizedBox(height: 10),
          Text(
            "Enter your registered email address and we'll send you a one-time password (OTP) to reset your password.",
            style: AppTheme.bodyMedium(context),
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
              color: AppTheme.getTextHint(context),
              size: 20,
            ),
            validator: _validateEmail,
          ),
          const SizedBox(height: 28),
          PrimaryButton(
            label: 'Send OTP',
            onPressed: _handleContinue,
            showArrow: true,
            isLoading: _isLoading,
          ),
          const SizedBox(height: 24),
          Center(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Text('Back to Login', style: AppTheme.linkText(context)),
            ),
          ),
          SizedBox(height: context.isDesktop ? 48 : 32),
        ],
      ),
    );
  }

  // ─── Step 2: Reset Password ───────────────────────────────────────────────

  Widget _buildResetStep(BuildContext context) {
    return Form(
      key: _resetFormKey,
      child: Column(
        key: const ValueKey('reset'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: context.isDesktop ? 48 : 20),
          _buildHeader(context),
          SizedBox(height: context.isDesktop ? 40 : 52),
          _buildStepBadge(2, 2),
          const SizedBox(height: 20),
          Text('Reset Password', style: AppTheme.heading1(context)),
          const SizedBox(height: 10),
          Text(
            'Enter the OTP sent to your email and create a new password.',
            style: AppTheme.bodyMedium(context),
          ),
          const SizedBox(height: 36),

          LabeledTextField(
            label: 'OTP CODE',
            hintText: 'Enter 6-digit code',
            controller: _otpController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            maxLength: 6,
            prefixIcon: const Icon(
              Icons.pin_rounded,
              color: AppTheme.getTextHint(context),
              size: 20,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter the OTP';
              }
              if (value.length != 6) return 'OTP must be 6 digits';
              if (!RegExp(r'^\d+$').hasMatch(value)) {
                return 'OTP must contain only numbers';
              }
              return null;
            },
          ),

          const SizedBox(height: 20),

          // On desktop, show new password + confirm side-by-side
          if (context.isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: LabeledTextField(
                    label: 'NEW PASSWORD',
                    hintText: 'Enter new password',
                    controller: _newPasswordController,
                    isPassword: true,
                    maxLength: 10,
                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                      color: AppTheme.getTextHint(context),
                      size: 20,
                    ),
                    validator: _validatePassword,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: LabeledTextField(
                    label: 'CONFIRM PASSWORD',
                    hintText: 'Re-enter new password',
                    controller: _confirmPasswordController,
                    isPassword: true,
                    maxLength: 10,
                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                      color: AppTheme.getTextHint(context),
                      size: 20,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _newPasswordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            )
          else ...[
            LabeledTextField(
              label: 'NEW PASSWORD',
              hintText: 'Enter new password (8-10 characters)',
              controller: _newPasswordController,
              isPassword: true,
              maxLength: 10,
              prefixIcon: const Icon(
                Icons.lock_outline_rounded,
                color: AppTheme.getTextHint(context),
                size: 20,
              ),
              validator: _validatePassword,
            ),
            const SizedBox(height: 20),
            LabeledTextField(
              label: 'CONFIRM PASSWORD',
              hintText: 'Re-enter new password',
              controller: _confirmPasswordController,
              isPassword: true,
              maxLength: 10,
              prefixIcon: const Icon(
                Icons.lock_outline_rounded,
                color: AppTheme.getTextHint(context),
                size: 20,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your password';
                }
                if (value != _newPasswordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
          ],

          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark 
                ? AppTheme.darkPrimaryLighter 
                : AppTheme.primaryLighter,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark 
                  ? AppTheme.darkPrimaryLight 
                  : AppTheme.primaryLight
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 16, color: AppTheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Password must be 8-10 characters long and contain both letters and numbers',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.getTextSecondary(context),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),
          PrimaryButton(
            label: 'Reset Password',
            onPressed: _handleResetPassword,
            showArrow: true,
            isLoading: _isLoading,
          ),
          SizedBox(height: context.isDesktop ? 48 : 32),
        ],
      ),
    );
  }

  // ─── Step 3: Success ──────────────────────────────────────────────────────

  Widget _buildSuccessStep(BuildContext context) {
    return Column(
      key: const ValueKey('success'),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: context.isDesktop ? 48 : 20),
        _buildHeader(context),
        SizedBox(height: context.isDesktop ? 60 : 80),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark 
              ? AppTheme.darkPrimaryLighter 
              : AppTheme.primaryLighter,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark 
                ? AppTheme.darkPrimaryLight 
                : AppTheme.primaryLight, 
              width: 1
            ),
            boxShadow: context.isDesktop
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 38,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Password Reset!',
                style: AppTheme.heading2(context),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Your password has been updated successfully. You can now log in with your new password.',
                style: AppTheme.bodyMedium(context),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Constrain button width on desktop
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: context.isDesktop ? 280 : double.infinity,
                ),
                child: PrimaryButton(
                  label: 'Back to Login',
                  onPressed: () =>
                      Navigator.popUntil(context, (route) => route.isFirst),
                  showArrow: true,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: context.isDesktop ? 48 : 32),
      ],
    );
  }

  // ─── Shared Widgets ───────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        if (!context.isDesktop) const AppLogo(),
        if (!context.isDesktop) const Spacer(),
        if (_step != _ForgotStep.success)
          GestureDetector(
            onTap: () {
              if (_step == _ForgotStep.enterEmail) {
                Navigator.pop(context);
              } else {
                setState(() {
                  _step = _ForgotStep.values[_step.index - 1];
                });
              }
            },
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppTheme.getTextSecondary(context),
              size: 20,
            ),
          ),
      ],
    );
  }

  Widget _buildStepBadge(int current, int total) {
    return Row(
      children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark 
                ? AppTheme.darkPrimaryLight 
                : AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.linear_scale_rounded,
                size: 14,
                color: AppTheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Step $current of $total',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: current / total,
              backgroundColor: Theme.of(context).brightness == Brightness.dark 
                ? AppTheme.darkPrimaryLight 
                : AppTheme.primaryLight,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppTheme.primary),
              minHeight: 4,
            ),
          ),
        ),
      ],
    );
  }
}