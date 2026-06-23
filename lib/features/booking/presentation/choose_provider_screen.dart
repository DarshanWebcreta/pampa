import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:pampa/core/values/app_text_value.dart';
import 'package:pampa/core/values/colors.dart';
import 'package:pampa/core/widgets/text_widget.dart';
import 'package:pampa/features/address/data/models/address_model.dart';
import 'package:pampa/features/address/presentation/provider/address_provider.dart';
import 'package:pampa/features/booking/data/models/provider_model.dart';
import 'package:pampa/features/booking/presentation/booking_review_screen.dart';
import 'package:pampa/features/booking/presentation/provider/booking_provider.dart';
import 'package:pampa/features/my_bookings/presentation/provider/my_bookings_provider.dart';
import 'package:pampa/core/utils/functional_component.dart';

class ChooseProviderScreen extends StatefulWidget {
  final AddressModel address;
  final int? rescheduleBookingId;

  const ChooseProviderScreen({
    super.key,
    required this.address,
    this.rescheduleBookingId,
  });

  @override
  State<ChooseProviderScreen> createState() => _ChooseProviderScreenState();
}

class _ChooseProviderScreenState extends State<ChooseProviderScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bookingProvider = context.read<BookingProvider>();
      bookingProvider.clearPendingBooking();
      bookingProvider.fetchAvailableProviders(
        zipCode: widget.address.zipCode,
      );
    });
  }

  void _openReview(ProviderModel provider) {
    final serviceId = context.read<BookingProvider>().service?.id;
    _openReviewWithServices(provider, serviceId != null ? [serviceId] : []);
  }

  void _openReviewWithServices(ProviderModel provider, List<int> serviceIds) {
    final bookingProvider = context.read<BookingProvider>();
    bookingProvider.selectProvider(provider);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: bookingProvider),
            ChangeNotifierProvider.value(value: context.read<AddressProvider>()),
          ],
          child: BookingReviewScreen(
            address: widget.address,
            serviceIds: serviceIds,
            rescheduleBookingId: widget.rescheduleBookingId,
          ),
        ),
      ),
    );
  }

  Future<void> _handleCancel(BuildContext context) async {
    final myBookingsProvider = context.read<MyBookingsProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text(
          'Are you sure you want to cancel this booking? This action cannot be undone.',
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep Booking'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFf1416c),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    // Show a loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(color: AppColor.authButton),
      ),
    );

    final success = await myBookingsProvider.cancelBooking(widget.rescheduleBookingId!);
    if (!context.mounted) return;

    // Dismiss the loading dialog
    Navigator.of(context).pop();

    if (success) {
      FunctionalComponent.showSnackBar(
        context: context,
        title: 'Booking cancelled successfully.',
        success: true,
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      FunctionalComponent.showSnackBar(
        context: context,
        title: myBookingsProvider.cancelError,
        success: false,
      );
      myBookingsProvider.resetCancelStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingProvider>(
      builder: (context, bookingProvider, _) {
        final service = bookingProvider.service;
        final showCancelButton = widget.rescheduleBookingId != null &&
            bookingProvider.providerFetchStatus == ProviderFetchStatus.success &&
            bookingProvider.providers.isEmpty;

        return Scaffold(
          backgroundColor: const Color(0xFFF7F1F4),
          body: service == null
              ? const SizedBox.shrink()
              : CustomScrollView(
                  slivers: [
                    // ── Sticky gradient header ────────────────────────────────
                    SliverAppBar(
                      pinned: true,
                      expandedHeight: 200,
                      backgroundColor: AppColor.authButton,
                      surfaceTintColor: Colors.transparent,
                      leading: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Material(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: const CircleBorder(),
                          clipBehavior: Clip.antiAlias,
                          child: IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                                color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                      flexibleSpace: FlexibleSpaceBar(
                        collapseMode: CollapseMode.pin,
                        background: _HeaderBanner(
                          address: widget.address,
                          date: bookingProvider.selectedDate,
                          time: bookingProvider.selectedTime ?? '',
                          serviceName: service.serviceName,
                        ),
                      ),
                    ),

                    // ── Provider count subheader ──────────────────────────────
                    if (bookingProvider.providerFetchStatus ==
                        ProviderFetchStatus.success &&
                        bookingProvider.providers.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding:
                              const EdgeInsets.fromLTRB(20, 20, 20, 4),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColor.authButton.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: AppText(
                                  '${bookingProvider.providers.length} available',
                                  fontSize: 12,
                                  fontWeight: FontWeights.semiBold,
                                  color: AppColor.authButton,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: AppText(
                                  'for ${service.serviceName}',
                                  fontSize: 13,
                                  color: AppColor.grey,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // ── Body ─────────────────────────────────────────────────
                    SliverToBoxAdapter(
                      child: _buildBody(bookingProvider),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 32)),
                  ],
                ),
          bottomNavigationBar: showCancelButton
              ? Container(
                  color: const Color(0xFFF7F1F4),
                  padding: EdgeInsets.fromLTRB(
                      20, 12, 20, MediaQuery.of(context).padding.bottom + 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFf1416c)),
                        foregroundColor: const Color(0xFFf1416c),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => _handleCancel(context),
                      child: AppText(
                        'Cancel Booking',
                        fontSize: FontSizes.regular,
                        fontWeight: FontWeights.semiBold,
                        color: const Color(0xFFf1416c),
                      ),
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _buildBody(BookingProvider bookingProvider) {
    switch (bookingProvider.providerFetchStatus) {
      case ProviderFetchStatus.loading:
        return const Padding(
          padding: EdgeInsets.only(top: 80),
          child: Center(
            child: CircularProgressIndicator(color: AppColor.authButton),
          ),
        );
      case ProviderFetchStatus.error:
        return _EmptyState(
          icon: Icons.wifi_off_rounded,
          title: 'Connection issue',
          subtitle: bookingProvider.providerFetchError.isNotEmpty
              ? bookingProvider.providerFetchError
              : 'Failed to load providers.',
          buttonLabel: 'Try again',
          onTap: () => bookingProvider.fetchAvailableProviders(
            zipCode: widget.address.zipCode,
          ),
        );
      case ProviderFetchStatus.success:
        if (bookingProvider.providers.isEmpty) {
          return _EmptyState(
            icon: Icons.person_search_rounded,
            title: 'No providers yet',
            subtitle:
                'No providers are available for this date and time in your area.',
            buttonLabel: 'Choose another time',
            onTap: () => Navigator.of(context).pop(),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: bookingProvider.providers.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final provider = bookingProvider.providers[index];
            final service = bookingProvider.service!;
            return _ProviderCard(
              provider: provider,
              selectedServiceId: service.id,
              onTap: () => _openReview(provider),
            );
          },
        );
      case ProviderFetchStatus.initial:
        return const SizedBox.shrink();
    }
  }
}

// ─── Header banner ────────────────────────────────────────────────────────────

class _HeaderBanner extends StatelessWidget {
  final AddressModel address;
  final DateTime date;
  final String time;
  final String serviceName;

  const _HeaderBanner({
    required this.address,
    required this.date,
    required this.time,
    required this.serviceName,
  });

  static String _formatTime(String t) {
    if (t.isEmpty) return '-';
    try {
      return DateFormat('h:mm a').format(DateFormat('HH:mm').parseStrict(t));
    } catch (_) {
      return t;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('EEE, MMM d').format(date);
    final timeLabel = _formatTime(time);
    final addr =
        '${address.streetAddress}, ${address.city}'
        '${address.state != null ? ', ${address.state}' : ''}'
        ' ${address.zipCode}'
            .trim()
            .replaceAll(RegExp(r'\s+'), ' ')
            .replaceAll(RegExp(r',\s*$'), '');

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF7B2249), AppColor.authButton],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AppText(
                'Choose your provider',
                fontSize: 22,
                fontWeight: FontWeights.bold,
                color: Colors.white,
              ),
              const SizedBox(height: 14),

              // Info chips row
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  _InfoChip(icon: Icons.location_on_outlined, label: addr),
                  _InfoChip(icon: Icons.calendar_today_outlined, label: dateLabel),
                  _InfoChip(icon: Icons.access_time_outlined, label: timeLabel),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white.withValues(alpha: 0.9)),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Provider card ────────────────────────────────────────────────────────────

class _ProviderCard extends StatelessWidget {
  final ProviderModel provider;
  final int selectedServiceId;
  final VoidCallback onTap;

  const _ProviderCard({
    required this.provider,
    required this.selectedServiceId,
    required this.onTap,
  });

  String _formatPrice(double price) {
    if (price == price.truncateToDouble()) return '\$${price.toInt()}';
    return '\$${price.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final service = provider.serviceFor(selectedServiceId);
    final price = service?.priceAsDouble ?? 0.0;
    final duration = service?.formattedDuration ?? '-';
    final deposit = service?.deposit ?? 0.0;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColor.authButton.withValues(alpha: 0.06),
        child: Ink(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFEADDE2)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top: avatar + name + rating ────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProviderAvatar(
                      photoUrl: provider.photoUrl,
                      name: provider.displayName,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            provider.displayName,
                            fontSize: 16,
                            fontWeight: FontWeights.bold,
                            color: AppColor.darkGrey,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 5),
                          // Rating + status
                          Row(
                            children: [
                              const Icon(Icons.star_rounded,
                                  size: 15, color: Color(0xFFFABF35)),
                              const SizedBox(width: 3),
                              AppText(
                                provider.rating.toStringAsFixed(1),
                                fontSize: 13,
                                fontWeight: FontWeights.semiBold,
                                color: AppColor.darkGrey,
                              ),
                              const SizedBox(width: 10),
                              _StatusBadge(status: provider.status),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // Location
                          if ((provider.city ?? '').isNotEmpty)
                            Row(
                              children: [
                                const Icon(Icons.location_on_rounded,
                                    size: 13, color: AppColor.grey),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: AppText(
                                    [provider.city, provider.state]
                                        .where((x) =>
                                            x != null && x.isNotEmpty)
                                        .join(', '),
                                    fontSize: 12,
                                    color: AppColor.grey,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Bio (if available) ─────────────────────────────────
              if ((provider.bio ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: AppText(
                    provider.bio!,
                    fontSize: 12,
                    color: AppColor.grey,
                    maxLines: 2,
                  ),
                ),

              // ── Divider ────────────────────────────────────────────
              const Divider(height: 1, thickness: 1, color: Color(0xFFF3ECF0)),

              // ── Bottom: price + cta ────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Row(
                  children: [
                    // Price block
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          _formatPrice(price),
                          fontSize: 18,
                          fontWeight: FontWeights.bold,
                          color: AppColor.authButton,
                        ),
                        Row(
                          children: [
                            const Icon(Icons.timer_outlined,
                                size: 12, color: AppColor.grey),
                            const SizedBox(width: 3),
                            AppText(
                              duration,
                              fontSize: 12,
                              color: AppColor.grey,
                            ),
                            if (deposit > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                width: 3,
                                height: 3,
                                decoration: const BoxDecoration(
                                    color: AppColor.grey,
                                    shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 8),
                              AppText(
                                '${_formatPrice(deposit)} deposit',
                                fontSize: 12,
                                color: AppColor.grey,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),

                    const Spacer(),

                    // CTA button
                    GestureDetector(
                      onTap: onTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 22, vertical: 11),
                        decoration: BoxDecoration(
                          color: AppColor.authButton,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(
                              color: AppColor.authButton.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Text(
                          'Book Now',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
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

// ─── Provider avatar ──────────────────────────────────────────────────────────

class _ProviderAvatar extends StatelessWidget {
  final String? photoUrl;
  final String name;

  const _ProviderAvatar({required this.photoUrl, required this.name});

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    return parts
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
  }

  @override
  Widget build(BuildContext context) {
    const size = 64.0;
    const radius = 18.0;

    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: CachedNetworkImage(
          imageUrl: photoUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, __) => _avatarFallback(size, radius),
          errorWidget: (_, __, ___) => _avatarFallback(size, radius),
        ),
      );
    }
    return _avatarFallback(size, radius);
  }

  Widget _avatarFallback(double size, double radius) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7B2249), AppColor.authButton],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(radius),
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── Status badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isActive = status.toLowerCase() == 'active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFFE6F9EE)
            : const Color(0xFFFCE8E8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF1F8F4C)
                  : Colors.red.shade600,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isActive
                  ? const Color(0xFF1F8F4C)
                  : Colors.red.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty / error state ──────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onTap;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 60, 28, 28),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColor.authButton.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: AppColor.authButton),
            ),
            const SizedBox(height: 20),
            AppText(
              title,
              fontSize: 18,
              fontWeight: FontWeights.bold,
              color: AppColor.darkGrey,
              align: TextAlign.center,
            ),
            const SizedBox(height: 8),
            AppText(
              subtitle,
              fontSize: 13,
              color: AppColor.grey,
              align: TextAlign.center,
              maxLines: 4,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.authButton,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: onTap,
                child: Text(
                  buttonLabel,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
