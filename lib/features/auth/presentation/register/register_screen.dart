import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:pampa/core/routes/routes.dart';
import 'package:pampa/core/storage/storage.dart';
import 'package:pampa/core/utils/functional_component.dart';
import 'package:pampa/core/values/app_text_value.dart';
import 'package:pampa/core/values/keys.dart';
import 'package:pampa/core/values/colors.dart';
import 'package:pampa/core/widgets/text_widget.dart';
import 'package:pampa/core/widgets/text_field_widget.dart';
import 'package:pampa/core/widgets/custom_button.dart';
import 'package:pampa/features/auth/presentation/provider/auth_provider.dart';
import 'package:pampa/core/widgets/phone_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _referralCodeController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  CountryCode _selectedCountry = kCountryCodes.first; // defaults to US

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _referralCodeController.dispose();
    super.dispose();
  }

  Future<void> _onRegister() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final provider = context.read<AuthProvider>();
    final success = await provider.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      passwordConfirmation: _confirmPasswordController.text,
      mobile: '${_selectedCountry.dial}${_mobileController.text.trim()}',
      referralCode: _referralCodeController.text.trim().isNotEmpty
          ? _referralCodeController.text.trim()
          : null,
    );

    if (!mounted) return;

    if (provider.isPendingApproval) {
      _showPendingApprovalDialog(context, provider.pendingApprovalMessage);
      return;
    }

    if (success) {
      FunctionalComponent.showSnackBar(
        context: context,
        title: 'Registration successful! Welcome aboard.',
        success: true,
      );
      final dest = provider.userType == 'provider'
          ? RouteNames.providerMainScreen
          : RouteNames.mainScreen;
      context.go(dest);
    } else {
      FunctionalComponent.showSnackBar(
        context: context,
        title: provider.errorMessage,
        success: false,
      );
    }
  }

  void _showPendingApprovalDialog(BuildContext ctx, String message) {
    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: _PendingApprovalDialog(
          message: message,
          onOk: () {
            Navigator.of(ctx).pop();
            ctx.go(RouteNames.userType);
          },
        ),
      ),
    );
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
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColor.authButton,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColor.authButton.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.person_add_rounded,
              color: AppColor.white,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          AppText(
            'Create Account',
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColor.authButton,
          ),
          const SizedBox(height: 6),
          AppText(
            'Fill in your details to get started',
            fontSize: 13,
            fontWeight: FontWeight.w400,
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
            _buildLabel('Full Name'),
            const SizedBox(height: 8),
            CustomTextFormField(
              controller: _nameController,
              hintText: 'Enter your full name',
              fillColor: AppColor.authBg,
              textInput: TextInputType.name,
              textCapitalization: TextCapitalization.words,
              focusColor: AppColor.authButton,
              enableColor: AppColor.mediumGrey,
              radius: 12,
              fieldHeight: 14,
              errorDisplay: true,
              autovalidate: true,
              prefix: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.person_outline_rounded, color: AppColor.grey, size: 20),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Full name is required';
                }
                if (value.trim().length < 2) {
                  return 'Name must be at least 2 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            _buildLabel('Email Address'),
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
            const SizedBox(height: 18),
            _buildLabel('Mobile Number'),
            const SizedBox(height: 8),
            PhoneField(
              controller: _mobileController,
              fillColor: AppColor.authBg,
              initialCountry: _selectedCountry,
              onCountryChanged: (c) => setState(() => _selectedCountry = c),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Mobile number is required';
                }
                if (value.trim().length < 6) {
                  return 'Enter a valid phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            _buildLabel('Password'),
            const SizedBox(height: 8),
            CustomTextFormField(
              controller: _passwordController,
              hintText: 'Create a password',
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
            const SizedBox(height: 18),
            _buildLabel('Confirm Password'),
            const SizedBox(height: 8),
            CustomTextFormField(
              controller: _confirmPasswordController,
              hintText: 'Re-enter your password',
              fillColor: AppColor.authBg,
              textInput: TextInputType.visiblePassword,
              textCapitalization: TextCapitalization.none,
              focusColor: AppColor.authButton,
              enableColor: AppColor.mediumGrey,
              radius: 12,
              fieldHeight: 14,
              obscureText: _obscureConfirmPassword,
              errorDisplay: true,
              autovalidate: true,
              action: TextInputAction.done,
              prefix: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.lock_outline_rounded, color: AppColor.grey, size: 20),
              ),
              suffixBtn: GestureDetector(
                onTap: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColor.grey,
                    size: 20,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your password';
                }
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            if (context.read<AuthProvider>().userType == 'provider') ...[
              const SizedBox(height: 18),
              _buildLabel('Referral Code (Optional)'),
              const SizedBox(height: 8),
              CustomTextFormField(
                controller: _referralCodeController,
                hintText: 'Enter referral code (e.g. REF-ABCDEF)',
                fillColor: AppColor.authBg,
                textInput: TextInputType.text,
                textCapitalization: TextCapitalization.characters,
                focusColor: AppColor.authButton,
                enableColor: AppColor.mediumGrey,
                radius: 12,
                fieldHeight: 14,
                errorDisplay: true,
                autovalidate: true,
                prefix: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.card_giftcard_rounded, color: AppColor.grey, size: 20),
                ),
              ),
            ],
            const SizedBox(height: 30),
            Consumer<AuthProvider>(
              builder: (context, auth, _) {
                return SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: CustomButtonWithText(
                    txt: auth.isLoading ? 'Creating Account...' : 'Create Account',
                    radius: 14,
                    color: AppColor.authButton,
                    txtColor: AppColor.white,
                    txtSize: 15,
                    weight: FontWeight.w600,
                    callback: auth.isLoading ? null : _onRegister,
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppText(
                  'Already have an account? ',
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppColor.grey,
                ),
                GestureDetector(
                  onTap: () => context.pop(),
                  child: AppText(
                    'Sign In',
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

  Widget _buildLabel(String label) {
    return AppText(
      label,
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppColor.darkGrey,
    );
  }
}

// ─── Pending Approval Dialog ───────────────────────────────────────────────────

class _PendingApprovalDialog extends StatefulWidget {
  final String message;
  final VoidCallback onOk;

  const _PendingApprovalDialog({required this.message, required this.onOk});

  @override
  State<_PendingApprovalDialog> createState() => _PendingApprovalDialogState();
}

class _PendingApprovalDialogState extends State<_PendingApprovalDialog>
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
              // ── Icon ────────────────────────────────────────────────────
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColor.authButton.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.check_circle_outline_rounded,
                        size: 48, color: AppColor.authButton),
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
                        child: const Icon(Icons.access_time_rounded,
                            size: 12, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Title ────────────────────────────────────────────────────
              AppText(
                'Registration Successful!',
                fontSize: FontSizes.large,
                fontWeight: FontWeights.bold,
                color: AppColor.darkGrey,
              ),

              const SizedBox(height: 10),

              // ── Pill badge ───────────────────────────────────────────────
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
                    const Icon(Icons.hourglass_top_rounded,
                        size: 13, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 5),
                    AppText(
                      'Pending Admin Approval',
                      fontSize: 12,
                      fontWeight: FontWeights.semiBold,
                      color: const Color(0xFFD97706),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ── Message ──────────────────────────────────────────────────
              AppText(
                widget.message,
                fontSize: FontSizes.regular,
                color: AppColor.grey,
                maxLines: 5,
              ),

              const SizedBox(height: 6),

              AppText(
                'You will be notified once your account has been reviewed and approved by the admin.',
                fontSize: 13,
                color: AppColor.grey,
                maxLines: 4,
              ),

              const SizedBox(height: 24),

              // ── Button ───────────────────────────────────────────────────
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
