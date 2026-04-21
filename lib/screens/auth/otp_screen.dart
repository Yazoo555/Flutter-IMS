import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/primary_button.dart';
import '../../utils/responsive_layout.dart'; // ← new
import '../dashboard/home_screen.dart';

class OtpScreen extends StatefulWidget {
  final String email;
  final OtpType otpType;

  const OtpScreen({super.key, required this.email, required this.otpType});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const int _otpLength = 6;
  static const int _resendCooldown = 60;

  final List<TextEditingController> _controllers = List.generate(
    _otpLength,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    _otpLength,
    (_) => FocusNode(),
  );

  bool _isLoading = false;
  int _resendTimer = _resendCooldown;
  bool _canResend = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // ─── Timer ────────────────────────────────────────────────────────────────

  void _startResendTimer() {
    setState(() {
      _resendTimer = _resendCooldown;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_resendTimer > 0) {
          _resendTimer--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  // ─── OTP input helpers ────────────────────────────────────────────────────

  void _onDigitChanged(int index, String value) {
    if (value.length == 1) {
      if (index < _otpLength - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  String get _otp => _controllers.map((c) => c.text).join();
  bool get _isComplete => _otp.length == _otpLength;

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final name = parts[0];
    final visible = name.length > 2 ? name.substring(0, 2) : name[0];
    return '$visible***@${parts[1]}';
  }

  // ─── Supabase: Verify OTP ─────────────────────────────────────────────────

  Future<void> _handleVerify() async {
    if (!_isComplete) {
      _showSnack('Please enter all 6 digits', error: true);
      return;
    }
    setState(() => _isLoading = true);

    try {
      await supabase.auth.verifyOTP(
        email: widget.email,
        token: _otp,
        type: widget.otpType,
      );

      if (!mounted) return;
      _showSnack('Verification successful!');
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } on AuthException catch (e) {
      _showSnack(e.message, error: true);
    } catch (_) {
      _showSnack('Verification failed. Please try again.', error: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Supabase: Resend OTP ─────────────────────────────────────────────────

  Future<void> _handleResend() async {
    if (!_canResend) return;
    for (final c in _controllers) c.clear();
    _focusNodes[0].requestFocus();

    try {
      if (widget.otpType == OtpType.recovery) {
        await supabase.auth.resetPasswordForEmail(widget.email);
      } else {
        await supabase.auth.signInWithOtp(
          email: widget.email,
          shouldCreateUser: widget.otpType == OtpType.signup,
        );
      }
      _startResendTimer();
      _showSnack('A new code has been sent.');
    } on AuthException catch (e) {
      _showSnack(e.message, error: true);
    } catch (_) {
      _showSnack('Failed to resend. Please try again.', error: true);
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  void _showSnack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppTheme.errorColor : AppTheme.primary,
      ),
    );
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: context.isDesktop ? 48 : 20),

            // Header row
            Row(
              children: [
                if (!context.isDesktop) const AppLogo(),
                if (!context.isDesktop) const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppTheme.getTextSecondary(context),
                    size: 20,
                  ),
                ),
              ],
            ),

            SizedBox(height: context.isDesktop ? 40 : 32),

            // OTP Card — centered on desktop, full-width on mobile
            _buildOtpCard(context),

            SizedBox(height: context.isDesktop ? 48 : 32),
          ],
        ),
      ),
    );
  }

  Widget _buildOtpCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        context.isDesktop ? 40 : 24,
        context.isDesktop ? 40 : 32,
        context.isDesktop ? 40 : 24,
        context.isDesktop ? 40 : 32,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
          ? AppTheme.darkPrimaryLighter 
          : AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark 
            ? AppTheme.darkPrimaryLighter 
            : AppTheme.primaryLight, 
          width: 1
        ),
        // Subtle shadow on desktop to lift the card
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
          // Icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark 
                ? AppTheme.darkPrimaryLight 
                : AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: AppTheme.primary,
              size: 30,
            ),
          ),

          const SizedBox(height: 20),
          Text('Verification', style: AppTheme.heading2(context)),
          const SizedBox(height: 10),

          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: AppTheme.bodyMedium(context),
              children: [
                const TextSpan(text: 'Enter the 6-digit code sent to\n'),
                TextSpan(
                  text: _maskEmail(widget.email),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // OTP boxes — fixed max-width so they don't stretch on wide desktop
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: context.isDesktop ? 380 : double.infinity,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final boxWidth = (constraints.maxWidth - (5 * 8)) / 6;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_otpLength, (i) {
                    return Container(
                      width: boxWidth,
                      height: boxWidth * 1.2,
                      margin: EdgeInsets.only(right: i < 5 ? 8 : 0),
                      child: TextFormField(
                        controller: _controllers[i],
                        focusNode: _focusNodes[i],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: Theme.of(context).brightness == Brightness.dark 
                            ? AppTheme.darkInputBackground 
                            : AppTheme.otpBackground,
                          contentPadding: EdgeInsets.zero,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: AppTheme.primary,
                              width: 2,
                            ),
                          ),
                        ),
                        onChanged: (v) => _onDigitChanged(i, v),
                        onTap: () {
                          _controllers[i].selection =
                              TextSelection.fromPosition(
                            TextPosition(
                                offset: _controllers[i].text.length),
                          );
                        },
                      ),
                    );
                  }),
                );
              },
            ),
          ),

          const SizedBox(height: 28),

          // Verify button — constrained width on desktop
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: context.isDesktop ? 320 : double.infinity,
            ),
            child: PrimaryButton(
              label: 'Verify',
              onPressed: _handleVerify,
              showArrow: true,
              isLoading: _isLoading,
            ),
          ),

          const SizedBox(height: 18),

          // Resend
          GestureDetector(
            onTap: _canResend ? _handleResend : null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.refresh_rounded,
                  size: 16,
                  color: _canResend ? AppTheme.primary : AppTheme.getTextHint(context),
                ),
                const SizedBox(width: 6),
                Text(
                  _canResend
                      ? 'Resend Code'
                      : 'Resend in ${_resendTimer}s',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color:
                        _canResend ? AppTheme.primary : AppTheme.getTextHint(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}