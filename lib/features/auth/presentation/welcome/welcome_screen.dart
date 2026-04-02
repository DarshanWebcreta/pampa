import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:pampa/core/routes/routes.dart';
import 'package:pampa/core/utils/functional_component.dart';
import 'package:pampa/core/values/colors.dart';
import 'package:pampa/core/widgets/text_widget.dart';
import 'package:pampa/features/auth/presentation/provider/auth_provider.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  Future<void> _onGoogleSignIn(BuildContext context) async {
    final provider = context.read<AuthProvider>();
    final success = await provider.googleSignIn();

    if (!context.mounted) return;

    if (success) {
      final dest = provider.userType == 'provider'
          ? RouteNames.providerMainScreen
          : RouteNames.mainScreen;
      context.go(dest);
    } else if (provider.errorMessage.isNotEmpty) {
      FunctionalComponent.showSnackBar(
        context: context,
        title: provider.errorMessage,
        success: false,
      );
      provider.resetState();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.authBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Consumer<AuthProvider>(
            builder: (context, provider, _) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTitle(),
                  const SizedBox(height: 32),
                  _buildButtons(context, provider),
                  const SizedBox(height: 32),
                  _buildSignUp(context),
                  const SizedBox(height: 32),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        AppText(
          'Welcome to Pampa',
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppColor.darkGrey,
          align: TextAlign.center,
        ),
        const SizedBox(height: 10),
        AppText(
          'Beauty & wellness, wherever you are',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColor.grey,
          align: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildButtons(BuildContext context, AuthProvider provider) {
    return Column(
      children: [
        _OutlinedAuthButton(
          icon: const Icon(Icons.email_outlined, size: 20),
          label: 'Continue with Email',
          onTap: provider.isLoading ? null : () => context.push(RouteNames.login),
        ),
        const SizedBox(height: 12),
        _FilledAuthButton(
          icon: const Icon(Icons.apple, color: Colors.white, size: 22),
          label: 'Continue with Apple',
          onTap: provider.isLoading ? null : () => context.push(RouteNames.login),
        ),
        const SizedBox(height: 12),
        _OutlinedAuthButton(
          icon: provider.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColor.authButton,
                  ),
                )
              : const _GoogleLogo(),
          label: 'Continue with Google',
          onTap: provider.isLoading ? null : () => _onGoogleSignIn(context),
        ),
      ],
    );
  }

  Widget _buildSignUp(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AppText(
          "Don't have an account? ",
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: AppColor.primaryColor,
        ),
        GestureDetector(
          onTap: () => context.push(RouteNames.register),
          child: AppText(
            'Sign Up',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColor.authButton,
          ),
        ),
      ],
    );
  }
}

class _OutlinedAuthButton extends StatelessWidget {
  const _OutlinedAuthButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final Widget icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColor.white,
          side: const BorderSide(color: AppColor.mediumGrey, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 10),
            AppText(
              label,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColor.darkGrey,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilledAuthButton extends StatelessWidget {
  const _FilledAuthButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final Widget icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 10),
            AppText(
              label,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColor.white,
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw the four colored arcs
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Red (top-right)
    canvas.drawArc(
      rect,
      -0.52,
      1.57,
      false,
      Paint()
        ..color = const Color(0xFFEA4335)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.22
        ..strokeCap = StrokeCap.butt,
    );

    // Blue (top-left to bottom-left)
    canvas.drawArc(
      rect,
      1.05,
      1.57,
      false,
      Paint()
        ..color = const Color(0xFF4285F4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.22
        ..strokeCap = StrokeCap.butt,
    );

    // Yellow (bottom-left to bottom-right)
    canvas.drawArc(
      rect,
      2.62,
      0.8,
      false,
      Paint()
        ..color = const Color(0xFFFBBC05)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.22
        ..strokeCap = StrokeCap.butt,
    );

    // Green (bottom-right to right)
    canvas.drawArc(
      rect,
      3.42,
      0.77,
      false,
      Paint()
        ..color = const Color(0xFF34A853)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.22
        ..strokeCap = StrokeCap.butt,
    );

    // Draw the white bar for the "G" cutout (horizontal)
    final barPaint = Paint()
      ..color = AppColor.white
      ..strokeWidth = size.width * 0.24
      ..strokeCap = StrokeCap.butt;

    canvas.drawLine(
      Offset(center.dx, center.dy),
      Offset(center.dx + radius, center.dy),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
