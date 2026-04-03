import 'package:flutter/material.dart';

/// Breakpoints for responsive layout
class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
}

/// Extension for easy breakpoint checks
extension BreakpointContext on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  bool get isMobile => screenWidth < Breakpoints.mobile;
  bool get isTablet =>
      screenWidth >= Breakpoints.mobile && screenWidth < Breakpoints.desktop;
  bool get isDesktop => screenWidth >= Breakpoints.desktop;

  /// Max content width for form pages (keeps forms readable on wide screens)
  double get formMaxWidth {
    if (isMobile) return double.infinity;
    if (isTablet) return 480;
    return 520;
  }
}

/// Wraps auth screens in a responsive two-column layout on desktop.
/// Left panel: decorative branding panel.
/// Right panel: scrollable form content.
/// On mobile/tablet: shows only the form content (original behaviour).
class AuthResponsiveLayout extends StatelessWidget {
  final Widget formContent;

  /// Optional: override the left panel. Defaults to [_DefaultBrandPanel].
  final Widget? leftPanel;

  const AuthResponsiveLayout({
    super.key,
    required this.formContent,
    this.leftPanel,
  });

  @override
  Widget build(BuildContext context) {
    if (context.isDesktop) {
      return _DesktopLayout(
        leftPanel: leftPanel ?? const _DefaultBrandPanel(),
        formContent: formContent,
      );
    }
    // Mobile & tablet: original scrollable form, no decorative panel
    return formContent;
  }
}

// ─── Desktop two-column layout ─────────────────────────────────────────────

class _DesktopLayout extends StatelessWidget {
  final Widget leftPanel;
  final Widget formContent;

  const _DesktopLayout({required this.leftPanel, required this.formContent});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left branding panel — 45% width, fixed
        Expanded(flex: 45, child: leftPanel),
        // Right form panel — 55% width
        Expanded(
          flex: 55,
          child: formContent,
        ),
      ],
    );
  }
}

// ─── Default left branding panel ──────────────────────────────────────────

class _DefaultBrandPanel extends StatelessWidget {
  const _DefaultBrandPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A6B4A), // deep forest green
            Color(0xFF2E9E6E), // mid green (AppTheme.primary-ish)
            Color(0xFF1A5C3E), // darker green base
          ],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Subtle geometric background pattern
          Positioned.fill(child: CustomPaint(painter: _GridPatternPainter())),

          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 56),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo mark
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.25), width: 1.5),
                  ),
                  child: const Icon(Icons.inventory_2_outlined,
                      color: Colors.white, size: 28),
                ),
                const Spacer(),

                // Headline
                const Text(
                  'Manage your\ninventory with\nconfidence.',
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.2,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
'Accurate stock monitoring, low-stock alerts,\nand smooth inventory operations.',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withOpacity(0.75),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 48),

                // Feature pills
                ...[
                  (Icons.bar_chart_rounded, 'Live inventory analytics'),
                  (Icons.notifications_active_outlined, 'Low-stock alerts'),
                  // (Icons.group_outlined, 'Multi-user coMultillaboration'),
                ].map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child:
                              Icon(item.$1, color: Colors.white, size: 18),                  // (Icons.group_outlined, 'Multi-user coMultillaboration'),

                        ),
                        const SizedBox(width: 14),
                        Text(
                          item.$2,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 48),

                // Footer
                Text(
                  '© ${DateTime.now().year} IMS. All rights reserved.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.45),
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

// ─── Subtle dot-grid painter for the brand panel ──────────────────────────

class _GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 1;

    const spacing = 32.0;
    const radius = 1.5;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Centers form content with a max-width constraint on desktop/tablet.
/// Drop this around the inner column in each screen's build method.
class FormConstrainedBox extends StatelessWidget {
  final Widget child;
  const FormConstrainedBox({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: context.formMaxWidth),
        child: child,
      ),
    );
  }
}