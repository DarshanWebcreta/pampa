import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:pampa/core/routes/routes.dart';
import 'package:pampa/core/values/app_text_value.dart';
import 'package:pampa/core/values/colors.dart';
import 'package:pampa/core/widgets/text_widget.dart';
import 'package:pampa/features/auth/presentation/provider/auth_provider.dart';

class UserTypeScreen extends StatelessWidget {
  const UserTypeScreen({super.key});

  void _selectType(BuildContext context, String type) {
    context.read<AuthProvider>().setUserType(type);
    context.push(RouteNames.welcome);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.authBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // ── Logo & Branding ──────────────────────────────────────────
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColor.authButton,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColor.authButton.withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.spa_rounded,
                  color: AppColor.white,
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),
              AppText(
                'Welcome to Pampa',
                fontSize: 26,
                fontWeight: FontWeights.bold,
                color: AppColor.darkGrey,
                align: TextAlign.center,
              ),
              const SizedBox(height: 8),
              AppText(
                'Beauty & wellness, wherever you are',
                fontSize: 14,
                color: AppColor.grey,
                align: TextAlign.center,
              ),
              const Spacer(flex: 2),
              // ── "Join as" heading ────────────────────────────────────────
              AppText(
                'How would you like to join?',
                fontSize: 16,
                fontWeight: FontWeights.semiBold,
                color: AppColor.darkGrey,
                align: TextAlign.center,
              ),
              const SizedBox(height: 20),
              // ── Customer Card ────────────────────────────────────────────
              _UserTypeCard(
                icon: Icons.person_outline_rounded,
                title: 'I\'m a Customer',
                subtitle: 'Book beauty & wellness services at your doorstep',
                isFeatured: true,
                badge: null,
                onTap: () => _selectType(context, 'customer'),
              ),
              const SizedBox(height: 14),
              // ── Provider Card ────────────────────────────────────────────
              _UserTypeCard(
                icon: Icons.store_mall_directory_outlined,
                title: 'I\'m a Provider',
                subtitle: 'Offer your beauty & wellness services to clients',
                isFeatured: false,
                badge: null,
                onTap: () => _selectType(context, 'provider'),
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserTypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isFeatured;
  final String? badge;
  final VoidCallback onTap;

  const _UserTypeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isFeatured,
    required this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isFeatured ? AppColor.authButton : AppColor.white,
          borderRadius: BorderRadius.circular(20),
          border: isFeatured
              ? null
              : Border.all(color: AppColor.mediumGrey, width: 1.2),
          boxShadow: isFeatured
              ? [
                  BoxShadow(
                    color: AppColor.authButton.withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          children: [
            // ── Icon container ─────────────────────────────────────────
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: isFeatured
                    ? AppColor.white.withValues(alpha: 0.18)
                    : AppColor.authButton.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                size: 26,
                color: isFeatured ? AppColor.white : AppColor.authButton,
              ),
            ),
            const SizedBox(width: 16),
            // ── Text content ───────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: AppText(
                          title,
                          fontSize: 16,
                          fontWeight: FontWeights.bold,
                          color: isFeatured ? AppColor.white : AppColor.darkGrey,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF9800),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: AppText(
                            badge!,
                            fontSize: 10,
                            fontWeight: FontWeights.semiBold,
                            color: AppColor.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  AppText(
                    subtitle,
                    fontSize: 12,
                    color: isFeatured
                        ? AppColor.white.withValues(alpha: 0.75)
                        : AppColor.grey,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // ── Arrow ──────────────────────────────────────────────────
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: isFeatured
                  ? AppColor.white.withValues(alpha: 0.7)
                  : AppColor.grey,
            ),
          ],
        ),
      ),
    );
  }
}
