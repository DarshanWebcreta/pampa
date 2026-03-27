import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:pampa/core/routes/routes.dart';
import 'package:pampa/core/storage/storage.dart';
import 'package:pampa/core/utils/functional_component.dart';
import 'package:pampa/core/values/colors.dart';
import 'package:pampa/core/values/keys.dart';
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
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: const BoxDecoration(
        color: AppColor.authBg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColor.authButton,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColor.authButton.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.spa_rounded,
              color: AppColor.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          AppText(
            'Welcome Back',
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppColor.authButton,
          ),
          const SizedBox(height: 6),
          AppText(
            'Sign in to continue',
            fontSize: 14,
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
