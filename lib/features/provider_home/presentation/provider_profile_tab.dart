import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pampa/core/utils/functional_component.dart';
import 'package:pampa/core/values/app_text_value.dart';
import 'package:pampa/core/values/colors.dart';
import 'package:pampa/core/widgets/text_widget.dart';
import 'package:pampa/data/service/di.dart';
import 'package:pampa/features/provider_home/data/models/provider_profile_model.dart';
import 'package:pampa/features/provider_home/presentation/provider/provider_profile_provider.dart';
import 'package:pampa/features/provider_home/presentation/provider_edit_profile_screen.dart';

class ProviderProfileTab extends StatefulWidget {
  const ProviderProfileTab({super.key});

  @override
  State<ProviderProfileTab> createState() => _ProviderProfileTabState();
}

class _ProviderProfileTabState extends State<ProviderProfileTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getIt<ProviderProfileProvider>().fetchProfile();
    });
  }

  void _openEdit(ProviderProfileModel profile) async {
    final prov = getIt<ProviderProfileProvider>();
    final didUpdate = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: prov,
          child: ProviderEditProfileScreen(profile: profile),
        ),
      ),
    );
    if (didUpdate == true && mounted) {
      prov.fetchProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: getIt<ProviderProfileProvider>(),
      child: Consumer<ProviderProfileProvider>(
        builder: (context, prov, _) {
          return ColoredBox(
            color: const Color(0xFFF7F3F5),
            child: Column(
              children: [
                Container(
                  color: AppColor.white,
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 8,
                    left: 20,
                    right: 16,
                    bottom: 12,
                  ),
                  child: Row(
                    children: [
                      AppText(
                        'Profile',
                        fontSize: 20,
                        fontWeight: FontWeights.bold,
                        color: AppColor.darkGrey,
                        align: TextAlign.center,
                      ),
                      // if (prov.profile != null)
                      //   GestureDetector(
                      //     onTap: () => _openEdit(prov.profile!),
                      //     child: Container(
                      //       width: 36,
                      //       height: 36,
                      //       decoration: BoxDecoration(
                      //         color: AppColor.authBg,
                      //         borderRadius: BorderRadius.circular(10),
                      //       ),
                      //       child: const Icon(
                      //         Icons.edit_rounded,
                      //         size: 17,
                      //         color: AppColor.authButton,
                      //       ),
                      //     ),
                      //   ),
                    ],
                  ),
                ),
                Expanded(
                  child: prov.loading
                      ? const Center(child: CircularProgressIndicator())
                      : prov.error.isNotEmpty && prov.profile == null
                          ? _ErrorView(
                              message: prov.error,
                              onRetry: prov.fetchProfile,
                            )
                          : prov.profile != null
                              ? RefreshIndicator(
                                  onRefresh: prov.fetchProfile,
                                  child: _ProfileBody(
                                    profile: prov.profile!,
                                    onEdit: () => _openEdit(prov.profile!),
                                  ),
                                )
                              : const SizedBox.shrink(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  final ProviderProfileModel profile;
  final VoidCallback onEdit;

  const _ProfileBody({required this.profile, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final locationText = _locationText(profile);
    final hoursText = _profileHours(profile);
    final summaryText = (profile.bio ?? '').trim().isNotEmpty
        ? profile.bio!.trim()
        : _fallbackSummary(profile, locationText);
    final statItems = _buildStats(profile);
    final availabilityItems = _availabilityItems(profile.availabilities);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
          decoration: BoxDecoration(
            color: const Color(0xFFF8EFF2),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Avatar(name: profile.name ?? '', photoUrl: profile.photoUrl),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if ((profile.name ?? '').isNotEmpty)
                          Text(
                            profile.name!,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColor.darkGrey,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: AppColor.authButton,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              profile.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColor.darkGrey,
                              ),
                            ),
                            if (profile.totalReviews > 0) ...[
                              const SizedBox(width: 4),
                              Text(
                                '(${profile.totalReviews} reviews)',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColor.grey,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          profile.isOnline ? 'Available now' : 'Currently offline',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: profile.isOnline ? Colors.green : AppColor.grey,
                          ),
                        ),
                        if (locationText.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            locationText,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColor.grey,
                            ),
                          ),
                        ],
                        if (hoursText.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            hoursText,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColor.grey,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: onEdit,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColor.authButton.withValues(alpha: 0.10),
                        ),
                      ),
                      child: const Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: AppColor.authButton,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if ((profile.licensed ?? '').isNotEmpty)
                    _InfoPill(
                      icon: Icons.verified_outlined,
                      text: 'Licensed: ${profile.licensed}',
                    ),
                  if (profile.maxServiceDistance > 0)
                    _InfoPill(
                      icon: Icons.near_me_outlined,
                      text: '${profile.maxServiceDistance} km radius',
                    ),
                  if (profile.zipCodes.isNotEmpty)
                    _InfoPill(
                      icon: Icons.pin_drop_outlined,
                      text: profile.zipCodes.join(', '),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1E3E8)),
          ),
          child: Text(
            summaryText,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF555555),
              height: 1.55,
            ),
          ),
        ),
        if (profile.services.isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF4E5EA),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Services Offered',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColor.darkGrey,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: profile.services
                      .map((service) => _ServiceChip(name: service.name))
                      .toList(),
                ),
              ],
            ),
          ),
        ],
        if (statItems.isNotEmpty) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              for (var i = 0; i < statItems.length; i++) ...[
                Expanded(
                  child: _MetricCard(
                    label: statItems[i].label,
                    value: statItems[i].value,
                  ),
                ),
                if (i != statItems.length - 1) const SizedBox(width: 10),
              ],
            ],
          ),
        ],
        if (availabilityItems.isNotEmpty) ...[
          const SizedBox(height: 18),
          const Text(
            'Availability',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColor.darkGrey,
            ),
          ),
          const SizedBox(height: 10),
          ...availabilityItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AvailabilityCard(label: item.label, value: item.value),
            ),
          ),
        ],
        if (profile.gallery.isNotEmpty) ...[
          const SizedBox(height: 18),
          const Text(
            'Portfolio',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColor.darkGrey,
            ),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              childAspectRatio: 0.92,
            ),
            itemCount: profile.gallery.length,
            itemBuilder: (_, i) {
              final img = profile.gallery[i];
              return GestureDetector(
                onTap: () => _openImageViewer(context, i, profile.gallery),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: FunctionalComponent.cachedNetworkImage(
                    img.url,
                    fit: BoxFit.cover,
                    radius: 12,
                  ),
                ),
              );
            },
          ),
        ],
        if (profile.recentReviews.isNotEmpty) ...[
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: AppColor.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recent Reviews',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColor.darkGrey,
                  ),
                ),
                const SizedBox(height: 4),
                ...profile.recentReviews.asMap().entries.map((entry) {
                  final index = entry.key;
                  final review = entry.value;
                  return Column(
                    children: [
                      if (index > 0)
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColor.lightGrey,
                        ),
                      _ReviewCard(review: review),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: onEdit,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColor.authButton),
              foregroundColor: AppColor.authButton,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Edit Profile',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _openImageViewer(
    BuildContext context,
    int initialIndex,
    List<ProviderGalleryImage> images,
  ) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (context, animation, secondaryAnimation) => _FullscreenGallery(
          urls: images.map((g) => g.url).toList(),
          initialIndex: initialIndex,
        ),
        transitionsBuilder: (context, anim, secondaryAnimation, child) {
          return FadeTransition(opacity: anim, child: child);
        },
      ),
    );
  }
}

String _locationText(ProviderProfileModel profile) {
  return [profile.city, profile.state, profile.country]
      .whereType<String>()
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .join(', ');
}

String _fallbackSummary(ProviderProfileModel profile, String locationText) {
  final parts = <String>[];
  if (locationText.isNotEmpty) {
    parts.add('Based in $locationText.');
  }
  if (profile.services.isNotEmpty) {
    parts.add(
      'Offers ${profile.services.length} professional service${profile.services.length == 1 ? '' : 's'}.',
    );
  }
  if (profile.maxServiceDistance > 0) {
    parts.add('Travels up to ${profile.maxServiceDistance} km for appointments.');
  }
  final hoursText = _profileHours(profile);
  if (hoursText.isNotEmpty) {
    parts.add('General hours: $hoursText.');
  }
  if (parts.isEmpty) {
    return 'Keep your profile updated so clients can quickly understand your services and availability.';
  }
  return parts.join(' ');
}

String _profileHours(ProviderProfileModel profile) {
  if ((profile.startTime ?? '').isEmpty || (profile.endTime ?? '').isEmpty) {
    return '';
  }
  return '${_formatTime(profile.startTime)} - ${_formatTime(profile.endTime)}';
}

String _formatTime(String? rawTime) {
  if (rawTime == null || rawTime.isEmpty) return '';
  final parts = rawTime.split(':');
  if (parts.length < 2) return rawTime;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return rawTime;
  final hourOfPeriod = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
  final period = hour >= 12 ? 'PM' : 'AM';
  return '$hourOfPeriod:${minute.toString().padLeft(2, '0')} $period';
}

List<_ProfileStatItem> _buildStats(ProviderProfileModel profile) {
  if (profile.completionRate > 0 || profile.cancellationRate > 0) {
    return [
      _ProfileStatItem(
        label: 'Completion Rate',
        value: '${profile.completionRate.toInt()}%',
      ),
      _ProfileStatItem(
        label: 'Cancellation Rate',
        value: '${profile.cancellationRate.toInt()}%',
      ),
    ];
  }

  return [
    _ProfileStatItem(
      label: 'Licensed',
      value: ((profile.licensed ?? '').trim().isEmpty)
          ? 'N/A'
          : profile.licensed!.trim(),
    ),
    _ProfileStatItem(
      label: 'Service Radius',
      value: profile.maxServiceDistance > 0
          ? '${profile.maxServiceDistance} km'
          : 'Not set',
    ),
  ];
}

List<_ProfileStatItem> _availabilityItems(
  List<ProviderAvailability> availabilities,
) {
  final grouped = <String, List<ProviderAvailability>>{};
  for (final availability in availabilities) {
    if (availability.day.isEmpty || !availability.isOpen) continue;
    grouped.putIfAbsent(availability.day, () => []).add(availability);
  }

  return grouped.entries.map((entry) {
    final ranges = entry.value
        .map(
          (slot) => '${_formatTime(slot.startTime)} - ${_formatTime(slot.endTime)}',
        )
        .where((value) => value.trim().isNotEmpty)
        .join('  •  ');
    return _ProfileStatItem(label: entry.key, value: ranges);
  }).toList();
}

class _ProfileStatItem {
  final String label;
  final String value;

  const _ProfileStatItem({required this.label, required this.value});
}

class _Avatar extends StatelessWidget {
  final String name;
  final String? photoUrl;

  const _Avatar({required this.name, this.photoUrl});

  @override
  Widget build(BuildContext context) {
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return ClipOval(
        child: SizedBox(
          width: 64,
          height: 64,
          child: FunctionalComponent.cachedNetworkImage(
            photoUrl!,
            fit: BoxFit.cover,
            radius: 32,
          ),
        ),
      );
    }
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColor.authButton.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColor.authButton,
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColor.authButton),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColor.darkGrey,
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceChip extends StatelessWidget {
  final String name;

  const _ServiceChip({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColor.authButton.withValues(alpha: 0.20),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.spa_rounded, size: 13, color: AppColor.authButton),
          const SizedBox(width: 5),
          Text(
            name,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColor.authButton,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;

  const _MetricCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColor.grey),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColor.darkGrey,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvailabilityCard extends StatelessWidget {
  final String label;
  final String value;

  const _AvailabilityCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 86,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColor.darkGrey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF555555),
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ProviderReview review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.customerName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColor.darkGrey,
                      ),
                    ),
                    Text(
                      review.serviceName,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColor.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (i) {
                  final filled = i < review.rating.round();
                  return Icon(
                    filled ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 14,
                    color: filled
                        ? const Color(0xFFFFB300)
                        : AppColor.mediumGrey,
                  );
                }),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              review.comment,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF555555),
                height: 1.4,
              ),
            ),
          ],
          if (review.date.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              review.date,
              style: const TextStyle(fontSize: 11, color: AppColor.grey),
            ),
          ],
        ],
      ),
    );
  }
}

class _FullscreenGallery extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;

  const _FullscreenGallery({
    required this.urls,
    required this.initialIndex,
  });

  @override
  State<_FullscreenGallery> createState() => _FullscreenGalleryState();
}

class _FullscreenGalleryState extends State<_FullscreenGallery> {
  late final PageController _pageCtrl;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _pageCtrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageCtrl,
            itemCount: widget.urls.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) => InteractiveViewer(
              child: Center(
                child: Image.network(
                  widget.urls[i],
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.broken_image_rounded,
                    color: Colors.white54,
                    size: 48,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Text(
                    '${_current + 1} / ${widget.urls.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: AppColor.grey),
            const SizedBox(height: 16),
            AppText(
              message,
              fontSize: FontSizes.regular,
              color: AppColor.grey,
              align: TextAlign.center,
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.authButton,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
