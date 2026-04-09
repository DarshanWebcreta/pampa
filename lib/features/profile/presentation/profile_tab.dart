import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:pampa/core/routes/routes.dart';
import 'package:pampa/core/utils/functional_component.dart';
import 'package:pampa/core/values/app_text_value.dart';
import 'package:pampa/core/values/colors.dart';
import 'package:pampa/core/widgets/text_widget.dart';
import 'package:pampa/features/address/presentation/saved_addresses_screen.dart';
import 'package:pampa/features/auth/presentation/provider/auth_provider.dart';
import 'package:pampa/features/profile/data/models/customer_profile_model.dart';
import 'package:pampa/features/profile/presentation/beauty_preferences_screen.dart';
import 'package:pampa/features/profile/presentation/notifications_screen.dart';
import 'package:pampa/features/favorites/presentation/favorite_providers_screen.dart';
import 'package:pampa/features/profile/presentation/page_detail_screen.dart';
import 'package:pampa/features/profile/presentation/personal_information_screen.dart';
import 'package:pampa/features/profile/presentation/provider/profile_provider.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileProvider = context.read<ProfileProvider>();
      if (profileProvider.status == ProfileStatus.initial) {
        profileProvider.fetchProfile();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, provider, _) {
        return RefreshIndicator(
          color: AppColor.authButton,
          onRefresh: () => provider.fetchProfile(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              AppText(
                'Profile',
                fontSize: 26,
                fontWeight: FontWeights.bold,
                color: AppColor.darkGrey,
              ),
              const SizedBox(height: 20),
              _HeaderCard(profile: provider.profile),
              const SizedBox(height: 24),
              if (provider.status == ProfileStatus.loading)
                const _LoadingShimmer()
              else if (provider.status == ProfileStatus.error)
                _ErrorBanner(
                  message: provider.errorMessage.isEmpty
                      ? 'Failed to load profile.'
                      : provider.errorMessage,
                  onRetry: provider.refresh,
                )
              else ...[
                _SectionLabel('Account'),
                const SizedBox(height: 8),
                _MenuGroup(items: [
                  _MenuItem(
                    icon: Icons.person_outline_rounded,
                    label: 'Personal Information',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ChangeNotifierProvider.value(
                        value: context.read<ProfileProvider>(),
                        child: const PersonalInformationScreen(),
                      ),
                    )),
                  ),
                  _MenuItem(
                    icon: Icons.location_on_outlined,
                    label: 'Saved Addresses',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const SavedAddressesScreen(),
                    )),
                  ),
                  _MenuItem(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    )),
                  ),
                ]),
                const SizedBox(height: 20),
                _SectionLabel('Beauty Profile'),
                const SizedBox(height: 8),
                _MenuGroup(items: [
                  _MenuItem(
                    icon: Icons.brush_outlined,
                    label: 'Beauty Preferences',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const BeautyPreferencesScreen(),
                    )),
                  ),
                  _MenuItem(
                    icon: Icons.favorite_border_rounded,
                    label: 'Favorite Providers',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const FavoriteProvidersScreen(),
                    )),
                  ),
                ]),
                const SizedBox(height: 20),
                // _SectionLabel('Payments & Rewards'),
                // const SizedBox(height: 8),
                // _MenuGroup(items: [
                //   _MenuItem(
                //     icon: Icons.credit_card_outlined,
                //     label: 'Payment Methods',
                //     onTap: () {},
                //   ),
                //   _MenuItem(
                //     icon: Icons.card_giftcard_rounded,
                //     label: 'Referrals & Credits',
                //     onTap: () {},
                //   ),
                // ]),
                // const SizedBox(height: 20),
                if (provider.pages.isNotEmpty) ...[
                  _SectionLabel('Support'),
                  const SizedBox(height: 8),
                  _MenuGroup(items: provider.pages
                      .map((page) => _MenuItem(
                            label: page.title,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PageDetailScreen(
                                  slug: page.slug,
                                  title: page.title,
                                ),
                              ),
                            ),
                          ))
                      .toList()),
                ],
                const SizedBox(height: 28),
                _SignOutButton(
                  isBusy: _isLoggingOut,
                  onTap: () => _confirmLogout(context),
                ),
                const SizedBox(height: 20),
                Center(
                  child: AppText(
                    'Pampa v1.0.0',
                    fontSize: 11,
                    color: AppColor.mediumGrey,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;
    if (!context.mounted) return;

    setState(() => _isLoggingOut = true);
    await context.read<AuthProvider>().logout();
    if (!context.mounted) return;
    setState(() => _isLoggingOut = false);
    context.go(RouteNames.userType);
  }
}

// ─── Header card ──────────────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  final CustomerProfileModel? profile;

  const _HeaderCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final name = profile?.name.trim() ?? '';
    final email = profile?.email.trim() ?? '';
    final mobile = profile?.mobile.trim() ?? '';
    final initials = _initials(name);
    final photoUrl = profile?.photoUrl;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColor.authButton.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColor.authButton.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            alignment: Alignment.center,
            child: photoUrl != null && photoUrl.isNotEmpty
                ? FunctionalComponent.cachedNetworkImage(
                    photoUrl,
                    radius: 26,
                    fit: BoxFit.cover,
                  )
                : AppText(
                    initials,
                    fontSize: 20,
                    fontWeight: FontWeights.bold,
                    color: AppColor.authButton,
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  name.isEmpty ? 'Your Profile' : name,
                  fontSize: FontSizes.medium,
                  fontWeight: FontWeights.bold,
                  color: AppColor.darkGrey,
                  maxLines: 1,
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  AppText(
                    email,
                    fontSize: FontSizes.small,
                    color: AppColor.grey,
                    maxLines: 1,
                  ),
                ],
                if (mobile.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  AppText(
                    mobile,
                    fontSize: FontSizes.small,
                    color: AppColor.grey,
                    maxLines: 1,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    if (name.trim().isEmpty) return 'U';
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    final first = parts.first[0].toUpperCase();
    final second = parts.length > 1 ? parts[1][0].toUpperCase() : '';
    return '$first$second';
  }
}

// ─── Section label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: AppText(
        text,
        fontSize: FontSizes.small,
        fontWeight: FontWeights.medium,
        color: AppColor.grey,
      ),
    );
  }
}

// ─── Menu group ───────────────────────────────────────────────────────────────

class _MenuGroup extends StatelessWidget {
  final List<_MenuItem> items;
  const _MenuGroup({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          Material(
            color: AppColor.white,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: items[i].onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                child: Row(
                  children: [
                    if (items[i].icon != null) ...[
                      Icon(items[i].icon!, size: 20, color: AppColor.authButton),
                      const SizedBox(width: 14),
                    ],
                    Expanded(
                      child: AppText(
                        items[i].label,
                        fontSize: FontSizes.regular,
                        color: AppColor.darkGrey,
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        size: 20, color: AppColor.mediumGrey),
                  ],
                ),
              ),
            ),
          ),
          if (i < items.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

// ─── Menu item ────────────────────────────────────────────────────────────────

class _MenuItem {
  final IconData? icon;
  final String label;
  final VoidCallback onTap;

  const _MenuItem({
    this.icon,
    required this.label,
    required this.onTap,
  });
}

// ─── Sign out button ──────────────────────────────────────────────────────────

class _SignOutButton extends StatelessWidget {
  final bool isBusy;
  final VoidCallback onTap;

  const _SignOutButton({required this.isBusy, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColor.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isBusy ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isBusy)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColor.authButton),
                )
              else
                Icon(Icons.logout_rounded,
                    size: 20, color: AppColor.authButton),
              const SizedBox(width: 10),
              AppText(
                isBusy ? 'Signing out...' : 'Sign Out',
                fontSize: FontSizes.regular,
                fontWeight: FontWeights.semiBold,
                color: AppColor.authButton,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Loading shimmer ──────────────────────────────────────────────────────────

class _LoadingShimmer extends StatelessWidget {
  const _LoadingShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(3, (i) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: AppColor.lightGrey,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      }),
    );
  }
}

// ─── Error banner ─────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColor.authButton, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: AppText(
              message,
              fontSize: FontSizes.small,
              color: AppColor.grey,
              maxLines: 3,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onRetry,
            child: AppText(
              'Retry',
              fontSize: FontSizes.small,
              fontWeight: FontWeights.semiBold,
              color: AppColor.authButton,
            ),
          ),
        ],
      ),
    );
  }
}
