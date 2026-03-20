import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pampa/core/utils/functional_component.dart';
import 'package:provider/provider.dart';

import 'package:pampa/core/routes/routes.dart';
import 'package:pampa/core/values/app_text_value.dart';
import 'package:pampa/core/values/colors.dart';
import 'package:pampa/core/widgets/custom_button.dart';
import 'package:pampa/core/widgets/text_widget.dart';
import 'package:pampa/features/auth/presentation/provider/auth_provider.dart';
import 'package:pampa/features/profile/data/models/customer_profile_model.dart';
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
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            children: [
              FunctionalComponent.customAppBar(title: 'Profile'),
              SizedBox(height: 16,),
              _HeaderCard(profile: provider.profile),
              const SizedBox(height: 16),
              _buildBody(context, provider),
              const SizedBox(height: 22),
              _LogoutCard(
                isBusy: _isLoggingOut,
                onLogout: () => _confirmLogout(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, ProfileProvider provider) {
    switch (provider.status) {
      case ProfileStatus.initial:
      case ProfileStatus.loading:
        return const _LoadingCard();

      case ProfileStatus.error:
        return _ErrorCard(
          message: provider.errorMessage.isEmpty
              ? 'Failed to load profile.'
              : provider.errorMessage,
          onRetry: provider.refresh,
        );

      case ProfileStatus.success:
        final profile = provider.profile;
        if (profile == null) {
          return _ErrorCard(
            message: 'Profile data not available.',
            onRetry: provider.refresh,
          );
        }
        return _DetailsCard(profile: profile);
    }
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) return;
    if (!context.mounted) return;

    setState(() => _isLoggingOut = true);
    await context.read<AuthProvider>().logout();
    if (!context.mounted) return;
    setState(() => _isLoggingOut = false);
    context.go(RouteNames.login);
  }
}

class _HeaderCard extends StatelessWidget {
  final CustomerProfileModel? profile;

  const _HeaderCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final name = profile?.name.trim();
    final email = profile?.email.trim();
    final initials = _initials(name);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColor.authButton.withValues(alpha: 0.12),
            child: AppText(
              initials,
              fontSize: 18,
              fontWeight: FontWeights.bold,
              color: AppColor.authButton,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  (name == null || name.isEmpty) ? 'Your Profile' : name,
                  fontSize: 18,
                  fontWeight: FontWeights.bold,
                  color: AppColor.black,
                  maxLines: 2,
                ),
                const SizedBox(height: 4),
                AppText(
                  (email == null || email.isEmpty) ? '—' : email,
                  fontSize: 12,
                  fontWeight: FontWeights.regular,
                  color: AppColor.grey,
                  maxLines: 2,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => context.read<ProfileProvider>().refresh(),
            icon: const Icon(Icons.refresh_rounded, color: AppColor.authButton),
          ),
        ],
      ),
    );
  }

  String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return 'U';
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final list = parts.toList();
    if (list.isEmpty) return 'U';
    final first = list.first.characters.first;
    final second = list.length > 1 ? list[1].characters.first : '';
    final result = '$first$second'.toUpperCase();
    return result.isEmpty ? 'U' : result;
  }
}

class _DetailsCard extends StatelessWidget {
  final CustomerProfileModel profile;

  const _DetailsCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final joined = profile.createdAt == null
        ? '—'
        : DateFormat.yMMMd().format(profile.createdAt!.toLocal());

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.lightGrey, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            'Account',
            fontSize: 14,
            fontWeight: FontWeights.semiBold,
            color: AppColor.black,
          ),
          const SizedBox(height: 14),
          _InfoRow(label: 'Name', value: profile.name),
          _InfoRow(label: 'Email', value: profile.email),
          _InfoRow(label: 'Mobile', value: profile.mobile),
          _InfoRow(label: 'Type', value: profile.type),
          _InfoRow(label: 'Status', value: profile.status),
          _InfoRow(label: 'Joined', value: joined),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: AppText(
              label,
              fontSize: 12,
              fontWeight: FontWeights.semiBold,
              color: AppColor.grey,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AppText(
              value.isEmpty ? '—' : value,
              fontSize: 13,
              fontWeight: FontWeights.regular,
              color: AppColor.black,
              maxLines: 3,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.lightGrey, width: 1),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          AppText(
            'Loading profile...',
            fontSize: 13,
            fontWeight: FontWeights.regular,
            color: AppColor.grey,
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.lightGrey, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColor.deepRed),
              const SizedBox(width: 8),
              Expanded(
                child: AppText(
                  message,
                  fontSize: 13,
                  fontWeight: FontWeights.regular,
                  color: AppColor.deepRed,
                  maxLines: 3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 44,
            width: double.infinity,
            child: CustomButtonWithText(
              txt: 'Retry',
              radius: 12,
              color: AppColor.authButton,
              txtColor: AppColor.white,
              txtSize: 14,
              weight: FontWeight.w600,
              callback: onRetry,
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoutCard extends StatelessWidget {
  final bool isBusy;
  final VoidCallback onLogout;

  const _LogoutCard({required this.isBusy, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.lightGrey, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            'Security',
            fontSize: 14,
            fontWeight: FontWeights.semiBold,
            color: AppColor.black,
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 50,
            width: double.infinity,
            child: CustomButtonWithText(
              txt: isBusy ? 'Logging out...' : 'Logout',
              radius: 14,
              color: AppColor.deepRed,
              txtColor: AppColor.white,
              txtSize: 15,
              weight: FontWeight.w600,
              callback: isBusy ? null : onLogout,
            ),
          ),
        ],
      ),
    );
  }
}
