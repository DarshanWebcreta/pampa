import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pampa/core/utils/functional_component.dart';
import 'package:pampa/core/values/app_text_value.dart';
import 'package:pampa/core/values/colors.dart';
import 'package:pampa/core/widgets/custom_button.dart';
import 'package:pampa/core/widgets/text_field_widget.dart';
import 'package:pampa/core/widgets/text_widget.dart';
import 'package:pampa/features/auth/presentation/provider/auth_provider.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _onChangePassword() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final auth = context.read<AuthProvider>();
    final success = await auth.changePassword(
      oldPassword: _oldPasswordController.text,
      password: _passwordController.text,
      passwordConfirmation: _confirmController.text,
    );

    if (!mounted) return;

    if (success) {
      FunctionalComponent.showSnackBar(
        context: context,
        title: 'Password changed successfully!',
        success: true,
      );
      auth.resetState();
      Navigator.of(context).maybePop();
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
        title: AppText(
          'Change Password',
          fontSize: FontSizes.large,
          fontWeight: FontWeights.bold,
          color: AppColor.darkGrey,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Description ───────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColor.authButton.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 20, color: AppColor.authButton),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AppText(
                        'Enter your current password and choose a new one below.',
                        fontSize: 13,
                        color: AppColor.grey,
                        maxLines: 3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Form ──────────────────────────────────────────────────
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current Password
                    FunctionalComponent.labelWidget('Current Password *'),
                    const SizedBox(height: 8),
                    CustomTextFormField(
                      controller: _oldPasswordController,
                      hintText: 'Enter current password',
                      fillColor: AppColor.white,
                      textInput: TextInputType.visiblePassword,
                      textCapitalization: TextCapitalization.none,
                      focusColor: AppColor.authButton,
                      enableColor: AppColor.mediumGrey,
                      radius: 12,
                      fieldHeight: 14,
                      obscureText: _obscureOld,
                      errorDisplay: true,
                      autovalidate: true,
                      prefix: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(Icons.lock_outline_rounded,
                            color: AppColor.grey, size: 20),
                      ),
                      suffixBtn: GestureDetector(
                        onTap: () =>
                            setState(() => _obscureOld = !_obscureOld),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Icon(
                            _obscureOld
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColor.grey,
                            size: 20,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Current password is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // New Password
                    FunctionalComponent.labelWidget('New Password *'),
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
                      obscureText: _obscureNew,
                      errorDisplay: true,
                      autovalidate: true,
                      prefix: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(Icons.lock_outline_rounded,
                            color: AppColor.grey, size: 20),
                      ),
                      suffixBtn: GestureDetector(
                        onTap: () =>
                            setState(() => _obscureNew = !_obscureNew),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Icon(
                            _obscureNew
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColor.grey,
                            size: 20,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'New password is required';
                        }
                        if (value.length < 8) {
                          return 'Password must be at least 8 characters';
                        }
                        if (value == _oldPasswordController.text) {
                          return 'New password must differ from current';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Confirm Password
                    FunctionalComponent.labelWidget('Confirm New Password *'),
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
                        onTap: () => setState(
                            () => _obscureConfirm = !_obscureConfirm),
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
                    const SizedBox(height: 32),

                    // Submit
                    Consumer<AuthProvider>(
                      builder: (context, auth, _) {
                        return SizedBox(
                          height: 52,
                          width: double.infinity,
                          child: CustomButtonWithText(
                            txt: auth.isLoading
                                ? 'Updating...'
                                : 'Change Password',
                            radius: 14,
                            color: AppColor.authButton,
                            txtColor: AppColor.white,
                            txtSize: 15,
                            weight: FontWeight.w600,
                            callback:
                                auth.isLoading ? null : _onChangePassword,
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
