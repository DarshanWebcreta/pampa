import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:pampa/core/routes/routes.dart';
import 'package:pampa/core/utils/functional_component.dart';
import 'package:pampa/core/values/app_text_value.dart';
import 'package:pampa/core/values/colors.dart';
import 'package:pampa/core/widgets/text_widget.dart';
import 'package:pampa/data/service/di.dart';
import 'package:pampa/features/auth/presentation/provider/auth_provider.dart';
import 'package:pampa/features/profile/presentation/notifications_screen.dart';
import 'package:pampa/features/provider_home/presentation/provider/provider_category_management_provider.dart';
import 'package:pampa/features/provider_home/presentation/provider/provider_credentials_provider.dart';
import 'package:pampa/features/provider_home/presentation/provider/provider_payout_method_provider.dart';
import 'package:pampa/features/provider_home/presentation/provider/provider_pricing_provider.dart';
import 'package:pampa/features/provider_home/presentation/provider/provider_service_management_provider.dart';
import 'package:pampa/features/provider_home/presentation/provider/provider_availability_provider.dart';
import 'package:pampa/features/provider_home/presentation/provider_availability_screen.dart';
import 'package:pampa/features/provider_home/presentation/provider_category_management_screen.dart';
import 'package:pampa/features/provider_home/presentation/provider_credentials_screen.dart';
import 'package:pampa/features/provider_home/presentation/provider_payout_method_screen.dart';
import 'package:pampa/features/provider_home/presentation/provider_pricing_screen.dart';
import 'package:pampa/features/provider_home/presentation/provider_service_management_screen.dart';

class ProviderSettingsScreen extends StatelessWidget {
  const ProviderSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F2F4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: AppText(
          'Settings',
          fontSize: 18,
          fontWeight: FontWeights.bold,
          color: AppColor.darkGrey,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          const _SectionLabel('Account'),
          const SizedBox(height: 8),
          _SettingsGroup(
            items: [
              _SettingsItemData(
                icon: Icons.category_outlined,
                label: 'Category',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider.value(
                      value: getIt<ProviderCategoryManagementProvider>(),
                      child: const ProviderCategoryManagementScreen(),
                    ),
                  ),
                ),
              ),
              _SettingsItemData(
                icon: Icons.design_services_outlined,
                label: 'Service',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider.value(
                      value: getIt<ProviderServiceManagementProvider>(),
                      child: const ProviderServiceManagementScreen(),
                    ),
                  ),
                ),
              ),
              _SettingsItemData(
                icon: Icons.calendar_today_outlined,
                label: 'Availability',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider.value(
                      value: getIt<ProviderAvailabilityProvider>(),
                      child: const ProviderAvailabilityScreen(),
                    ),
                  ),
                ),
              ),
              _SettingsItemData(
                icon: Icons.attach_money_rounded,
                label: 'Pricing',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider.value(
                      value: getIt<ProviderPricingProvider>(),
                      child: const ProviderPricingScreen(),
                    ),
                  ),
                ),
              ),
              _SettingsItemData(
                icon: Icons.verified_user_outlined,
                label: 'Credentials',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider.value(
                      value: getIt<ProviderCredentialsProvider>(),
                      child: const ProviderCredentialsScreen(),
                    ),
                  ),
                ),
              ),
              _SettingsItemData(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Payout Method',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider.value(
                      value: getIt<ProviderPayoutMethodProvider>(),
                      child: const ProviderPayoutMethodScreen(),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const _SectionLabel('Preferences'),
          const SizedBox(height: 8),
          _SettingsGroup(
            items: [
              _SettingsItemData(
                icon: Icons.notifications_none_rounded,
                label: 'Notifications',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const _SectionLabel('Support'),
          const SizedBox(height: 8),
          _SettingsGroup(
            items: [
              _SettingsItemData(
                icon: Icons.help_outline_rounded,
                label: 'Help Center',
                onTap: () => _showComingSoon(
                  context,
                  'Help center content will be added here.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const _SectionLabel('Account Actions'),
          const SizedBox(height: 8),
          _SettingsGroup(
            items: [
              _SettingsItemData(
                icon: Icons.pause_circle_outline_rounded,
                label: 'Temporarily Pause Profile',
                isDestructive: true,
                onTap: () => _showPauseDialog(context),
              ),
              _SettingsItemData(
                icon: Icons.logout_rounded,
                label: 'Sign Out',
                isDestructive: true,
                onTap: () => _confirmLogout(context),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Center(
            child: AppText(
              'Pampa Providers v1.0.0',
              fontSize: 11,
              color: AppColor.grey,
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: AppText('© 2026 Pampa', fontSize: 11, color: AppColor.grey),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String message) {
    FunctionalComponent.showSnackBar(
      context: context,
      title: message,
      success: true,
    );
  }

  Future<void> _showPauseDialog(BuildContext context) async {
    final shouldPause = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Pause Profile'),
        content: const Text(
          'This action is not connected yet. Add the pause profile API here when ready.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Close'),
          ),
        ],
      ),
    );

    if (shouldPause == true && context.mounted) {
      FunctionalComponent.showSnackBar(
        context: context,
        title: 'Profile pause requested.',
        success: true,
      );
    }
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !context.mounted) return;
    await context.read<AuthProvider>().logout();
    if (!context.mounted) return;
    context.go(RouteNames.userType);
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: AppColor.grey,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<_SettingsItemData> items;

  const _SettingsGroup({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0E4E8)),
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          final item = items[index];
          return Column(
            children: [
              _SettingsTile(item: item),
              if (index != items.length - 1)
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFF4EBEE),
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final _SettingsItemData item;

  const _SettingsTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final color = item.isDestructive
        ? const Color(0xFFFF3B5C)
        : AppColor.authButton;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: item.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        child: Row(
          children: [
            Icon(item.icon, size: 19, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: item.isDestructive ? color : AppColor.darkGrey,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: AppColor.grey),
          ],
        ),
      ),
    );
  }
}

class _SettingsItemData {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _SettingsItemData({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });
}
