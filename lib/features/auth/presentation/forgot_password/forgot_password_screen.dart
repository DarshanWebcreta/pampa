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

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _onSendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final auth = context.read<AuthProvider>();
    final success = await auth.forgotPassword(
      email: _emailController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      FunctionalComponent.showSnackBar(
        context: context,
        title: 'OTP sent! Check your email.',
        success: true,
      );
      auth.resetState();
      context.push(
        RouteNames.verifyOtp,
        extra: {'email': _emailController.text.trim()},
      );
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
                'Forgot Password?',
                fontSize: 26,
                fontWeight: FontWeights.bold,
                color: AppColor.darkGrey,
              ),
              const SizedBox(height: 8),
              AppText(
                'Enter your email address and we\'ll send you a 6-digit OTP to reset your password.',
                fontSize: FontSizes.regular,
                color: AppColor.grey,
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              // ── Form ──────────────────────────────────────────────────
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      'Email Address',
                      fontSize: 13,
                      fontWeight: FontWeights.semiBold,
                      color: AppColor.darkGrey,
                    ),
                    const SizedBox(height: 8),
                    CustomTextFormField(
                      controller: _emailController,
                      hintText: 'Enter your email',
                      fillColor: AppColor.white,
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
                        child: Icon(Icons.email_outlined,
                            color: AppColor.grey, size: 20),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email is required';
                        }
                        final emailRegex =
                            RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
                        if (!emailRegex.hasMatch(value.trim())) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),
                    Consumer<AuthProvider>(
                      builder: (context, auth, _) {
                        return SizedBox(
                          height: 52,
                          width: double.infinity,
                          child: CustomButtonWithText(
                            txt: auth.isLoading ? 'Sending OTP...' : 'Send OTP',
                            radius: 14,
                            color: AppColor.authButton,
                            txtColor: AppColor.white,
                            txtSize: 15,
                            weight: FontWeight.w600,
                            callback: auth.isLoading ? null : _onSendOtp,
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
