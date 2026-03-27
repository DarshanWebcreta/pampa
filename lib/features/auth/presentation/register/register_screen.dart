import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:pampa/core/routes/routes.dart';
import 'package:pampa/core/storage/storage.dart';
import 'package:pampa/core/utils/functional_component.dart';
import 'package:pampa/core/values/keys.dart';
import 'package:pampa/core/values/colors.dart';
import 'package:pampa/core/widgets/text_widget.dart';
import 'package:pampa/core/widgets/text_field_widget.dart';
import 'package:pampa/core/widgets/custom_button.dart';
import 'package:pampa/features/auth/presentation/provider/auth_provider.dart';

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

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
      mobile: _mobileController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      FunctionalComponent.showSnackBar(
        context: context,
        title: 'Registration successful! Welcome aboard.',
        success: true,
      );
      context.go(RouteNames.mainScreen);
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
            CustomTextFormField(
              controller: _mobileController,
              hintText: 'Enter your mobile number',
              fillColor: AppColor.authBg,
              textInput: TextInputType.phone,
              textCapitalization: TextCapitalization.none,
              focusColor: AppColor.authButton,
              enableColor: AppColor.mediumGrey,
              radius: 12,
              fieldHeight: 14,
              errorDisplay: true,
              autovalidate: true,
              inputFormatter: [FilteringTextInputFormatter.digitsOnly],
              prefix: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.phone_outlined, color: AppColor.grey, size: 20),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Mobile number is required';
                }
                if (value.trim().length < 10) {
                  return 'Enter a valid 10-digit mobile number';
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
