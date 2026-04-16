import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:pampa/core/routes/routes.dart';
import 'package:pampa/core/utils/functional_component.dart';
import 'package:pampa/core/values/app_text_value.dart';
import 'package:pampa/core/values/colors.dart';
import 'package:pampa/core/widgets/custom_button.dart';
import 'package:pampa/core/widgets/text_field_widget.dart';
import 'package:pampa/core/widgets/text_widget.dart';
import 'package:pampa/features/auth/presentation/provider/auth_provider.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String otp;

  const ResetPasswordScreen({
    super.key,
    required this.email,
    required this.otp,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _onResetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final auth = context.read<AuthProvider>();
    final success = await auth.resetPassword(
      email: widget.email,
      otp: widget.otp,
      password: _passwordController.text,
      passwordConfirmation: _confirmController.text,
    );

    if (!mounted) return;

    if (success) {
      FunctionalComponent.showSnackBar(
        context: context,
        title: 'Password reset successfully! Please log in.',
        success: true,
      );
      auth.resetState();
      context.go(RouteNames.login);
    } else {
      FunctionalComponent.showSnackBar(
        context: context,
        title: auth.errorMessage,
        success: false,
      );
      auth.resetState();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.authBg,
      appBar: AppBar(
        backgroundColor: AppColor.authBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: AppColor.darkGrey),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Icon ──────────────────────────────────────────────────
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColor.authButton.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.lock_reset_rounded,
                    size: 32, color: AppColor.authButton),
              ),
              const SizedBox(height: 24),

              // ── Title ─────────────────────────────────────────────────
              AppText(
                'New Password',
                fontSize: 26,
                fontWeight: FontWeights.bold,
                color: AppColor.darkGrey,
              ),
              const SizedBox(height: 8),
              AppText(
                'Choose a strong new password for your account.',
                fontSize: FontSizes.regular,
                color: AppColor.grey,
                maxLines: 2,
              ),
              const SizedBox(height: 32),

              // ── Form ──────────────────────────────────────────────────
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // New Password
                    AppText(
                      'New Password',
                      fontSize: 13,
                      fontWeight: FontWeights.semiBold,
                      color: AppColor.darkGrey,
                    ),
                    const SizedBox(height: 8),
                    CustomTextFormField(
                      controller: _passwordController,
                      hintText: 'Enter new password',
                      fillColor: AppColor.white,
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
                        child: Icon(Icons.lock_outline_rounded,
                            color: AppColor.grey, size: 20),
                      ),
                      suffixBtn: GestureDetector(
                        onTap: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
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
                    const SizedBox(height: 20),

                    // Confirm Password
                    AppText(
                      'Confirm Password',
                      fontSize: 13,
                      fontWeight: FontWeights.semiBold,
                      color: AppColor.darkGrey,
                    ),
                    const SizedBox(height: 8),
                    CustomTextFormField(
                      controller: _confirmController,
                      hintText: 'Re-enter new password',
                      fillColor: AppColor.white,
                      textInput: TextInputType.visiblePassword,
                      textCapitalization: TextCapitalization.none,
                      focusColor: AppColor.authButton,
                      enableColor: AppColor.mediumGrey,
                      radius: 12,
                      fieldHeight: 14,
                      obscureText: _obscureConfirm,
                      errorDisplay: true,
                      autovalidate: true,
                      action: TextInputAction.done,
                      prefix: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(Icons.lock_outline_rounded,
                            color: AppColor.grey, size: 20),
                      ),
                      suffixBtn: GestureDetector(
                        onTap: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Icon(
                            _obscureConfirm
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
                    const SizedBox(height: 28),

                    // Submit
                    Consumer<AuthProvider>(
                      builder: (context, auth, _) {
                        return SizedBox(
                          height: 52,
                          width: double.infinity,
                          child: CustomButtonWithText(
                            txt: auth.isLoading
                                ? 'Resetting...'
                                : 'Reset Password',
                            radius: 14,
                            color: AppColor.authButton,
                            txtColor: AppColor.white,
                            txtSize: 15,
                            weight: FontWeight.w600,
                            callback:
                                auth.isLoading ? null : _onResetPassword,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
