import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:pampa/core/routes/routes.dart';
import 'package:pampa/core/storage/storage.dart';
import 'package:pampa/core/values/colors.dart';
import 'package:pampa/core/values/app_text_value.dart';
import 'package:pampa/core/values/keys.dart';
import 'package:pampa/core/widgets/custom_button.dart';
import 'package:pampa/core/widgets/text_widget.dart';

class ZipCodeScreen extends StatefulWidget {
  const ZipCodeScreen({super.key});

  @override
  State<ZipCodeScreen> createState() => _ZipCodeScreenState();
}

class _ZipCodeScreenState extends State<ZipCodeScreen> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _submitted = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onFindServices() {
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    StorageManager.saveData(StoreKeys.zipCode, _controller.text.trim());
    context.go(RouteNames.mainScreen);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: AppColor.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              SizedBox(height: size.height * 0.15),

              // ── Headline ────────────────────────────────────────────────
              AppText(
                'Welcome to Pampa',
                fontSize: 30,
                fontWeight: FontWeights.bold,
                color: AppColor.authButton,
                align: TextAlign.center,
                maxLines: 2,
              ),
              const SizedBox(height: 14),
              AppText(
                'Find and book beauty services near you.',
                fontSize: FontSizes.regular,
                fontWeight: FontWeights.regular,
                color: AppColor.grey,
                align: TextAlign.center,
                maxLines: 2,
              ),

              SizedBox(height: size.height * 0.07),

              // ── ZIP input ─────────────────────────────────────────────
              Form(
                key: _formKey,
                child: _ZipField(
                  controller: _controller,
                  submitted: _submitted,
                ),
              ),

              const SizedBox(height: 18),

              // ── CTA button ────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: CustomButtonWithText(
                  txt: 'Find Services',
                  radius: 12,
                  color: AppColor.authButton,
                  txtColor: AppColor.white,
                  txtSize: 15,
                  weight: FontWeights.semiBold,
                  callback: _onFindServices,
                ),
              ),

              const Spacer(),

              // ── Terms ─────────────────────────────────────────────────
              _TermsText(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── ZIP input field ──────────────────────────────────────────────────────────
class _ZipField extends StatelessWidget {
  final TextEditingController controller;
  final bool submitted;

  const _ZipField({required this.controller, required this.submitted});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      textInputAction: TextInputAction.done,
      style: customTextStyle(
        size: FontSizes.regular,
        weight: FontWeights.medium,
        clr: AppColor.darkGrey,
      ),
      autovalidateMode:
          submitted ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
      validator: (val) {
        if (val == null || val.trim().isEmpty) return 'Please enter your ZIP code';
        if (val.trim().length < 4) return 'Enter a valid ZIP code';
        return null;
      },
      decoration: InputDecoration(
        hintText: 'Enter your ZIP code',
        hintStyle: customTextStyle(
          size: FontSizes.regular,
          weight: FontWeights.regular,
          clr: AppColor.grey,
        ),
        filled: true,
        fillColor: AppColor.authBg,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        suffixIcon: const Padding(
          padding: EdgeInsets.only(right: 16),
          child: Icon(Icons.location_on_outlined, color: AppColor.authButton, size: 22),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColor.authButton, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColor.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColor.red, width: 1.5),
        ),
        errorStyle: const TextStyle(fontSize: 11),
      ),
    );
  }
}

// ─── Terms text ───────────────────────────────────────────────────────────────
class _TermsText extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: customTextStyle(
          size: 11,
          weight: FontWeights.regular,
          clr: AppColor.grey,
        ),
        children: [
          const TextSpan(text: 'By continuing, you agree to our '),
          TextSpan(
            text: 'Terms of Service',
            style: customTextStyle(
              size: 11,
              weight: FontWeights.semiBold,
              clr: AppColor.authButton,
            ),
          ),
          const TextSpan(text: ' and '),
          TextSpan(
            text: 'Privacy Policy',
            style: customTextStyle(
              size: 11,
              weight: FontWeights.semiBold,
              clr: AppColor.authButton,
            ),
          ),
        ],
      ),
    );
  }
}
