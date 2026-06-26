import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class VerifyOtpScreen extends StatefulWidget {
  final String email;

  const VerifyOtpScreen({super.key, required this.email});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _onVerify() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final auth = context.read<AuthProvider>();
    final success = await auth.verifyOtp(
      email: widget.email,
      otp: _otpController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      auth.resetState();
      context.push(
        RouteNames.resetPassword,
        extra: {
          'email': widget.email,
          'otp': _otpController.text.trim(),
        },
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

  Future<void> _onResendOtp() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.forgotPassword(email: widget.email);
    if (!mounted) return;
    FunctionalComponent.showSnackBar(
      context: context,
      title: success ? 'OTP resent to ${widget.email}.' : auth.errorMessage,
      success: success,
    );
    if (!success) auth.resetState();
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
                child: const Icon(Icons.mark_email_read_rounded,
                    size: 32, color: AppColor.authButton),
              ),
              const SizedBox(height: 24),

              // ── Title ─────────────────────────────────────────────────
              AppText(
                'Enter OTP',
                fontSize: 26,
                fontWeight: FontWeights.bold,
                color: AppColor.darkGrey,
              ),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: FontSizes.regular,
                    color: AppColor.grey,
                    fontFamily: 'Inter',
                  ),
                  children: [
                    const TextSpan(text: 'We sent a 6-digit code to '),
                    TextSpan(
                      text: widget.email,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColor.darkGrey,
                      ),
                    ),
                    const TextSpan(text: '. Enter it below to continue.'),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              // ── Form ──────────────────────────────────────────────────
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FunctionalComponent.labelWidget('OTP Code *'),
                    const SizedBox(height: 8),
                    CustomTextFormField(
                      controller: _otpController,
                      hintText: '6-digit code',
                      fillColor: AppColor.white,
                      textInput: TextInputType.number,
                      textCapitalization: TextCapitalization.none,
                      focusColor: AppColor.authButton,
                      enableColor: AppColor.mediumGrey,
                      radius: 12,
                      fieldHeight: 14,
                      errorDisplay: true,
                      autovalidate: true,
                      action: TextInputAction.done,
                      inputFormatter: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      prefix: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(Icons.pin_rounded,
                            color: AppColor.grey, size: 20),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'OTP is required';
                        }
                        if (value.trim().length != 6) {
                          return 'OTP must be exactly 6 digits';
                        }
                        return null;
                      },
                    ),

                    // Resend OTP row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AppText(
                          'Didn\'t receive the code?',
                          fontSize: 12,
                          color: AppColor.grey,
                        ),
                        Consumer<AuthProvider>(
                          builder: (_, auth, _) => TextButton(
                            onPressed: auth.isLoading ? null : _onResendOtp,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: AppText(
                              'Resend OTP',
                              fontSize: 12,
                              fontWeight: FontWeights.semiBold,
                              color: AppColor.authButton,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // Verify button
                    Consumer<AuthProvider>(
                      builder: (context, auth, _) {
                        return SizedBox(
                          height: 52,
                          width: double.infinity,
                          child: CustomButtonWithText(
                            txt: auth.isLoading ? 'Verifying...' : 'Verify OTP',
                            radius: 14,
                            color: AppColor.authButton,
                            txtColor: AppColor.white,
                            txtSize: 15,
                            weight: FontWeight.w600,
                            callback: auth.isLoading ? null : _onVerify,
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
