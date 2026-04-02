import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:pampa/core/routes/routes.dart';
import 'package:pampa/core/values/app_text_value.dart';
import 'package:pampa/core/values/colors.dart';
import 'package:pampa/core/widgets/text_widget.dart';
import 'package:pampa/features/auth/presentation/provider/auth_provider.dart';

/// Placeholder screen shown to provider-type users after login.
/// Replace this with the real provider dashboard when design is ready.
class ProviderHomeScreen extends StatelessWidget {
  const ProviderHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.authBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColor.authButton,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.spa_rounded,
                          color: AppColor.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      AppText(
                        'Pampa Provider',
                        fontSize: 17,
                        fontWeight: FontWeights.bold,
                        color: AppColor.darkGrey,
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout_rounded,
                        color: AppColor.grey, size: 22),
                    onPressed: () async {
                      await context.read<AuthProvider>().logout();
                      if (context.mounted) context.go(RouteNames.userType);
                    },
                  ),
                ],
              ),
            ),

            const Spacer(),

            // ── Coming soon content ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColor.authButton.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.store_mall_directory_rounded,
                      size: 46,
                      color: AppColor.authButton,
                    ),
                  ),
                  const SizedBox(height: 28),
                  AppText(
                    'Provider Dashboard',
                    fontSize: 24,
                    fontWeight: FontWeights.bold,
                    color: AppColor.darkGrey,
                    align: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  AppText(
                    'Your full provider dashboard is coming soon.\nYou\'ll be able to manage bookings, services, and clients from here.',
                    fontSize: 14,
                    color: AppColor.grey,
                    align: TextAlign.center,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 36),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.rocket_launch_rounded,
                            color: Color(0xFFFF9800), size: 18),
                        const SizedBox(width: 8),
                        AppText(
                          'We\'ll notify you when it\'s ready',
                          fontSize: 13,
                          color: const Color(0xFFE65100),
                          fontWeight: FontWeights.medium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),
          ],
        ),
      ),
    );
  }
}
