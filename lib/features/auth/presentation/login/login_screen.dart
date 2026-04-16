import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pampa/core/values/imagepath.dart';
import 'package:pampa/core/widgets/custom_image.dart';
import 'package:provider/provider.dart';

import 'package:pampa/core/routes/routes.dart';
import 'package:pampa/core/utils/functional_component.dart';
import 'package:pampa/core/values/app_text_value.dart';
import 'package:pampa/core/values/colors.dart';
import 'package:pampa/core/widgets/text_widget.dart';
import 'package:pampa/core/widgets/text_field_widget.dart';
import 'package:pampa/core/widgets/custom_button.dart';
import 'package:pampa/features/auth/presentation/provider/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isAccountInactive(String message) {
    final lower = message.toLowerCase();
    return lower.contains('not active') ||
        lower.contains('admin approval') ||
        lower.contains('activate your account') ||
        lower.contains('pending');
  }

  void _showAccountPendingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: _AccountPendingDialog(
          message: message,
          onOk: () {
            Navigator.of(context).pop();
            context.go(RouteNames.userType);
          },
        ),
      ),
    );
  }

  Future<void> _onGoogleSignIn() async {
    final provider = context.read<AuthProvider>();
    final success = await provider.googleSignIn();
    if (!mounted) return;
    if (success) {
      final dest = provider.userType == 'provider'
          ? RouteNames.providerMainScreen
          : RouteNames.mainScreen;
      context.go(dest);
    } else if (provider.errorMessage.isNotEmpty) {
      if (_isAccountInactive(provider.errorMessage)) {
        _showAccountPendingDialog(provider.errorMessage);
      } else {
        FunctionalComponent.showSnackBar(
          context: context,
          title: provider.errorMessage,
          success: false,
        );
      }
      provider.resetState();
    }
  }

  Future<void> _onLogin() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final provider = context.read<AuthProvider>();
    final success = await provider.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      FunctionalComponent.showSnackBar(
        context: context,
        title: 'Login successful! Welcome back.',
        success: true,
      );
      final dest = provider.userType == 'provider'
          ? RouteNames.providerMainScreen
          : RouteNames.mainScreen;
      context.go(dest);
    } else if (_isAccountInactive(provider.errorMessage)) {
      _showAccountPendingDialog(provider.errorMessage);
    } else {
      FunctionalComponent.showSnackBar(
        context: context,
        title: provider.errorMessage,
        success: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.authBg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(context),
              _buildFormCard(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: const BoxDecoration(
        color: AppColor.authBg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AssetImageView(path: ImageStrings.appDesignLogo,height: 50,),


          // AppText(
          //   'Welcome Back',
          //   fontSize: 26,
          //   fontWeight: FontWeight.w700,
          //   color: AppColor.authButton,
          // ),
           const SizedBox(height: 6),
          AppText(
            'Sign in to continue',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColor.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColor.authButton.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              'Email Address',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColor.darkGrey,
            ),
            const SizedBox(height: 8),
            CustomTextFormField(
              controller: _emailController,
              hintText: 'Enter your email',
              fillColor: AppColor.authBg,
              textInput: TextInputType.emailAddress,
              textCapitalization: TextCapitalization.none,
              focusColor: AppColor.authButton,
              enableColor: AppColor.mediumGrey,
              radius: 12,
              fieldHeight: 14,
              errorDisplay: true,
              autovalidate: true,
              prefix: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.email_outlined, color: AppColor.grey, size: 20),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Email is required';
                }
                final emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
                if (!emailRegex.hasMatch(value.trim())) {
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            AppText(
              'Password',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColor.darkGrey,
            ),
            const SizedBox(height: 8),
            CustomTextFormField(
              controller: _passwordController,
              hintText: 'Enter your password',
              fillColor: AppColor.authBg,
              textInput: TextInputType.visiblePassword,
              textCapitalization: TextCapitalization.none,
              focusColor: AppColor.authButton,
              enableColor: AppColor.mediumGrey,
              radius: 12,
              fieldHeight: 14,
              obscureText: _obscurePassword,
              errorDisplay: true,
              autovalidate: true,
              action: TextInputAction.done,
              prefix: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.lock_outline_rounded, color: AppColor.grey, size: 20),
              ),
              suffixBtn: GestureDetector(
                onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColor.grey,
                    size: 20,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Password is required';
                }
                if (value.length < 8) {
                  return 'Password must be at least 8 characters';
                }
                return null;
              },
            ),

            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => context.push(RouteNames.forgotPassword),
                child: AppText(
                  'Forgot Password?',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColor.authButton,
                ),
              ),
            ),
            const SizedBox(height: 28),
            Consumer<AuthProvider>(
              builder: (context, auth, _) {
                return SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: CustomButtonWithText(
                    txt: auth.isLoading ? 'Signing In...' : 'Sign In',
                    radius: 14,
                    color: AppColor.authButton,
                    txtColor: AppColor.white,
                    txtSize: 15,
                    weight: FontWeight.w600,
                    callback: auth.isLoading ? null : _onLogin,
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            _buildDivider(),
            const SizedBox(height: 20),
            Consumer<AuthProvider>(
              builder: (context, auth, _) {
                return Row(
                  children: [
                    Expanded(
                      child: _SocialButton(
                        icon: const _GoogleLogo(),
                        label: 'Google',
                        onTap: auth.isLoading ? null : _onGoogleSignIn,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SocialButton(
                        icon: const Icon(Icons.apple, size: 20, color: Color(0xFF1C1C1E)),
                        label: 'Apple',
                        onTap: auth.isLoading ? null : () {},
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppText(
                  "Don't have an account? ",
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppColor.grey,
                ),
                GestureDetector(
                  onTap: () => context.push(RouteNames.register),
                  child: AppText(
                    'Sign Up',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColor.authButton,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: AppColor.mediumGrey, thickness: 0.8)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: AppText('OR', fontSize: 12, color: AppColor.grey, fontWeight: FontWeight.w500),
        ),
        Expanded(child: Divider(color: AppColor.mediumGrey, thickness: 0.8)),
      ],
    );
  }
}

// ── Social login button ────────────────────────────────────────────────────────
class _SocialButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback? onTap;

  const _SocialButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColor.white,
          side: const BorderSide(color: AppColor.mediumGrey, width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: EdgeInsets.zero,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 20, height: 20, child: icon),
            const SizedBox(width: 8),
            AppText(
              label,
              fontSize: 13,
              fontWeight: FontWeights.medium,
              color: AppColor.darkGrey,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Google logo painter ────────────────────────────────────────────────────────
class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(painter: _GoogleLogoPainter());
  }
}

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawArc(rect, -0.52, 1.57, false,
        Paint()..color = const Color(0xFFEA4335)..style = PaintingStyle.stroke..strokeWidth = size.width * 0.22..strokeCap = StrokeCap.butt);
    canvas.drawArc(rect, 1.05, 1.57, false,
        Paint()..color = const Color(0xFF4285F4)..style = PaintingStyle.stroke..strokeWidth = size.width * 0.22..strokeCap = StrokeCap.butt);
    canvas.drawArc(rect, 2.62, 0.8, false,
        Paint()..color = const Color(0xFFFBBC05)..style = PaintingStyle.stroke..strokeWidth = size.width * 0.22..strokeCap = StrokeCap.butt);
    canvas.drawArc(rect, 3.42, 0.77, false,
        Paint()..color = const Color(0xFF34A853)..style = PaintingStyle.stroke..strokeWidth = size.width * 0.22..strokeCap = StrokeCap.butt);

    canvas.drawLine(
      Offset(center.dx, center.dy),
      Offset(center.dx + radius, center.dy),
      Paint()..color = AppColor.white..strokeWidth = size.width * 0.24..strokeCap = StrokeCap.butt,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Account Pending Dialog ────────────────────────────────────────────────────

class _AccountPendingDialog extends StatefulWidget {
  final String message;
  final VoidCallback onOk;

  const _AccountPendingDialog({required this.message, required this.onOk});

  @override
  State<_AccountPendingDialog> createState() => _AccountPendingDialogState();
}

class _AccountPendingDialogState extends State<_AccountPendingDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColor.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Icon ─────────────────────────────────────────────────
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(Icons.lock_clock_outlined,
                        size: 40, color: Color(0xFFF59E0B)),
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColor.white, width: 2),
                        ),
                        child: const Icon(Icons.hourglass_top_rounded,
                            size: 11, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Title ─────────────────────────────────────────────────
              AppText(
                'Account Not Active',
                fontSize: FontSizes.large,
                fontWeight: FontWeights.bold,
                color: AppColor.darkGrey,
              ),

              const SizedBox(height: 10),

              // ── Badge ─────────────────────────────────────────────────
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.pending_outlined,
                        size: 13, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 5),
                    AppText(
                      'Awaiting Admin Approval',
                      fontSize: 12,
                      fontWeight: FontWeights.semiBold,
                      color: const Color(0xFFD97706),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ── Message from API ──────────────────────────────────────
              AppText(
                widget.message,
                fontSize: FontSizes.regular,
                color: AppColor.grey,
                maxLines: 5,
              ),

              const SizedBox(height: 24),

              // ── Button ────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.authButton,
                    foregroundColor: AppColor.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: widget.onOk,
                  child: AppText(
                    'Back to Home',
                    fontSize: FontSizes.regular,
                    fontWeight: FontWeights.semiBold,
                    color: AppColor.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
