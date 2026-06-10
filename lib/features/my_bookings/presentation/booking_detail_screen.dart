import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pampa/core/routes/routes.dart';
import 'package:pampa/core/values/urls.dart';
import 'package:provider/provider.dart';

import 'package:pampa/core/utils/functional_component.dart';
import 'package:pampa/core/values/colors.dart';
import 'package:pampa/core/values/app_text_value.dart';
import 'package:pampa/core/widgets/text_widget.dart';
import 'package:pampa/features/my_bookings/data/models/my_booking_model.dart';
import 'package:pampa/features/my_bookings/presentation/provider/my_bookings_provider.dart';
import 'package:pampa/features/webview/webview.dart';

// ─── Top-level helpers ────────────────────────────────────────────────────────

String _formatTime(String time) {
  try {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = parts[1];
    final period = hour >= 12 ? 'PM' : 'AM';
    final display = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$display:$minute $period';
  } catch (_) {
    return time;
  }
}

Color _statusColor(String status) {
  switch (status.toLowerCase()) {
    case 'confirmed':
      return const Color(0xFF50cd89);
    case 'pending':
      return const Color(0xFFFFA500);
    case 'completed':
      return const Color(0xFF009ef7);
    case 'cancelled':
      return const Color(0xFFf1416c);
    default:
      return AppColor.grey;
  }
}

Color _statusBgColor(String status) {
  switch (status.toLowerCase()) {
    case 'confirmed':
      return const Color(0xFFe8fff3);
    case 'pending':
      return const Color(0xFFfff0cc);
    case 'completed':
      return const Color(0xFFf1faff);
    case 'cancelled':
      return const Color(0xFFfff5f7);
    default:
      return AppColor.lightGrey;
  }
}

Color _paymentStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'paid':
      return const Color(0xFF50cd89);
    case 'pending':
      return const Color(0xFFFFA500);
    case 'failed':
      return const Color(0xFFf1416c);
    case 'refunded':
      return const Color(0xFF009ef7);
    default:
      return AppColor.grey;
  }
}

Color _paymentStatusBg(String status) {
  switch (status.toLowerCase()) {
    case 'paid':
      return const Color(0xFFe8fff3);
    case 'pending':
      return const Color(0xFFfff0cc);
    case 'failed':
      return const Color(0xFFfff5f7);
    case 'refunded':
      return const Color(0xFFf1faff);
    default:
      return AppColor.lightGrey;
  }
}

class _ServiceImageThumb extends StatelessWidget {
  final String imageUrl;
  final double size;
  final double radius;

  const _ServiceImageThumb({
    required this.imageUrl,
    required this.size,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final trimmed = imageUrl.trim();
    final hasImage = trimmed.isNotEmpty;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColor.authBg,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: hasImage
          ? ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: FunctionalComponent.cachedNetworkImage(
                ApiStrings.imageUrl+trimmed,
                radius: radius,
                fit: BoxFit.cover,
              ),
            )
          : const Icon(
              Icons.spa_rounded,
              color: AppColor.authButton,
              size: 28,
            ),
    );
  }
}

IconData _paymentStatusIcon(String status) {
  switch (status.toLowerCase()) {
    case 'paid':
      return Icons.check_circle_rounded;
    case 'pending':
      return Icons.hourglass_top_rounded;
    case 'failed':
      return Icons.cancel_rounded;
    case 'refunded':
      return Icons.replay_rounded;
    default:
      return Icons.help_outline_rounded;
  }
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class BookingDetailScreen extends StatefulWidget {
  final int bookingId;

  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MyBookingsProvider>().fetchBookingDetail(widget.bookingId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MyBookingsProvider>(
      builder: (context, provider, _) {
        final booking = provider.detailBooking;

        return Scaffold(
          backgroundColor: const Color(0xFFF8F8F8),
          appBar: AppBar(
            backgroundColor: AppColor.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColor.darkGrey,
                size: 20,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: AppText(
              'Booking Details',
              fontSize: FontSizes.medium,
              fontWeight: FontWeights.bold,
              color: AppColor.authButton,
            ),
            actions: [
              if (booking != null)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColor.authBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: AppText(
                      '#${booking.id}',
                      fontSize: FontSizes.small,
                      fontWeight: FontWeights.semiBold,
                      color: AppColor.authButton,
                    ),
                  ),
                ),
            ],
          ),
          body: _buildBody(context, provider, booking),
          bottomNavigationBar: booking != null
              ? _BottomBar(
                  booking: booking,
                  bookingId: widget.bookingId,
                )
              : null,
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    MyBookingsProvider provider,
    MyBookingModel? booking,
  ) {
    switch (provider.detailStatus) {
      case BookingDetailStatus.loading:
        return const Center(
          child: CircularProgressIndicator(color: AppColor.authButton),
        );

      case BookingDetailStatus.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off_rounded,
                    size: 48, color: AppColor.authButton),
                const SizedBox(height: 16),
                AppText(
                  provider.detailError,
                  fontSize: FontSizes.regular,
                  color: AppColor.grey,
                  align: TextAlign.center,
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () =>
                      provider.fetchBookingDetail(widget.bookingId),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColor.authButton,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: AppText(
                      'Try Again',
                      fontSize: FontSizes.regular,
                      fontWeight: FontWeights.semiBold,
                      color: AppColor.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

      case BookingDetailStatus.initial:
        return const SizedBox.shrink();

      case BookingDetailStatus.success:
        if (booking == null) return const SizedBox.shrink();
        return _BookingDetailContent(booking: booking);
    }
  }
}

// ─── Detail content ───────────────────────────────────────────────────────────

class _BookingDetailContent extends StatelessWidget {
  final MyBookingModel booking;

  const _BookingDetailContent({required this.booking});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (booking.rescheduleBook) ...[
            _RescheduleWarningBanner(booking: booking),
            const SizedBox(height: 16),
          ],
          // Section 1: Status Banner
          _StatusBanner(booking: booking),
          const SizedBox(height: 16),

          // Section 2: Service Details
          _SectionCard(
            headerIcon: Icons.spa_rounded,
            headerLabel: 'Service Details',
            child: _ServiceDetailsContent(booking: booking),
          ),
          const SizedBox(height: 16),

          // Section 3: Provider
          _SectionCard(
            headerIcon: Icons.person_rounded,
            headerLabel: 'Provider',
            child: _ProviderContent(booking: booking),
          ),
          const SizedBox(height: 16),

          // Section 4: Appointment
          _SectionCard(
            headerIcon: Icons.calendar_today_rounded,
            headerLabel: 'Appointment',
            child: _AppointmentContent(booking: booking),
          ),
          const SizedBox(height: 16),

          // Section 5: Payment Summary
          _SectionCard(
            headerIcon: Icons.receipt_rounded,
            headerLabel: 'Payment Summary',
            child: _PaymentSummaryContent(booking: booking),
          ),

          // Section 6: Inspiration & Notes (only if any field is non-null)
          if ((booking.notes?.isNotEmpty ?? false) ||
              (booking.pinterestLink?.isNotEmpty ?? false) ||
              (booking.inspirationPhoto?.isNotEmpty ?? false)) ...
            [
              const SizedBox(height: 16),
              _SectionCard(
                headerIcon: Icons.auto_awesome_rounded,
                headerLabel: 'Inspiration & Notes',
                child: _InspirationContent(booking: booking),
              ),
            ],
        ],
      ),
    );
  }
}

class _RescheduleWarningBanner extends StatelessWidget {
  final MyBookingModel booking;

  const _RescheduleWarningBanner({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFfff4e5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFffe0b2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFe65100),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  'Action Required: Reschedule Needed',
                  fontSize: 13,
                  fontWeight: FontWeights.bold,
                  color: const Color(0xFFe65100),
                ),
                const SizedBox(height: 4),
                AppText(
                  'The provider is unavailable on your selected slot. Please reschedule your appointment.',
                  fontSize: 12,
                  color: const Color(0xFFe65100),
                  maxLines: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Status banner ────────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  final MyBookingModel booking;

  const _StatusBanner({required this.booking});

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Icons.check_circle_rounded;
      case 'pending':
        return Icons.hourglass_top_rounded;
      case 'completed':
        return Icons.task_alt_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(booking.status);
    final bg = _statusBgColor(booking.status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  'Booking Status',
                  fontSize: FontSizes.small,
                  color: AppColor.grey,
                ),
                const SizedBox(height: 4),
                AppText(
                  booking.status.toUpperCase(),
                  fontSize: FontSizes.large,
                  fontWeight: FontWeights.bold,
                  color: color,
                ),
              ],
            ),
          ),
          Icon(_statusIcon(booking.status), size: 36, color: color),
        ],
      ),
    );
  }
}

// ─── Section card ─────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final IconData headerIcon;
  final String headerLabel;
  final Widget child;

  const _SectionCard({
    required this.headerIcon,
    required this.headerLabel,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(headerIcon, color: AppColor.authButton, size: 18),
              const SizedBox(width: 8),
              AppText(
                headerLabel,
                fontSize: FontSizes.regular,
                fontWeight: FontWeights.bold,
                color: AppColor.darkGrey,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColor.lightGrey),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ─── Service details content ──────────────────────────────────────────────────

class _ServiceDetailsContent extends StatelessWidget {
  final MyBookingModel booking;

  const _ServiceDetailsContent({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _ServiceImageThumb(
          imageUrl: booking.service.image,
          size: 60,
          radius: 12,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                booking.service.serviceName,
                fontSize: FontSizes.medium,
                fontWeight: FontWeights.bold,
                color: AppColor.darkGrey,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.access_time_rounded,
                      size: 13, color: AppColor.grey),
                  const SizedBox(width: 4),
                  AppText(
                    '${booking.service.duration} min',
                    fontSize: FontSizes.small,
                    color: AppColor.grey,
                  ),
                ],
              ),
            ],
          ),
        ),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            AppText(
              '\$${booking.service.price.toStringAsFixed(2)}',
              fontSize: FontSizes.large,
              fontWeight: FontWeights.bold,
              color: AppColor.authButton,
            ),
            AppText(
              'per session',
              fontSize: 11,
              color: AppColor.grey,
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Provider content ─────────────────────────────────────────────────────────

class _ProviderContent extends StatelessWidget {
  final MyBookingModel booking;

  const _ProviderContent({required this.booking});

  @override
  Widget build(BuildContext context) {
    final provider = booking.provider;

    if (provider == null) {
      return AppText(
        'Provider info unavailable',
        fontSize: FontSizes.small,
        color: AppColor.grey,
      );
    }

    final hasLocation = (provider.city != null && provider.city!.isNotEmpty) ||
        (provider.state != null && provider.state!.isNotEmpty);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            color: AppColor.authBg,
            shape: BoxShape.circle,
          ),
          child: ClipOval(
            child: provider.photoUrl != null && provider.photoUrl!.isNotEmpty
                ? Image.network(
                    provider.photoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.person_rounded,
                      color: AppColor.authButton,
                      size: 28,
                    ),
                  )
                : const Icon(
                    Icons.person_rounded,
                    color: AppColor.authButton,
                    size: 28,
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                provider.displayName,
                fontSize: FontSizes.regular,
                fontWeight: FontWeights.bold,
                color: AppColor.darkGrey,
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  for (int i = 0; i < 5; i++)
                    Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: provider.rating > i
                          ? const Color(0xFFFFB800)
                          : AppColor.lightGrey,
                    ),
                  const SizedBox(width: 4),
                  AppText(
                    provider.rating.toStringAsFixed(1),
                    fontSize: 12,
                    color: AppColor.grey,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (hasLocation)
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        size: 13, color: AppColor.grey),
                    const SizedBox(width: 2),
                    AppText(
                      provider.displayLocation,
                      fontSize: 12,
                      color: AppColor.grey,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Appointment content ──────────────────────────────────────────────────────

class _AppointmentContent extends StatelessWidget {
  final MyBookingModel booking;

  const _AppointmentContent({required this.booking});

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        DateFormat('EEEE, MMM d yyyy').format(booking.appointmentDate);
    final formattedTime = _formatTime(booking.appointmentTime);

    return IntrinsicHeight(
      child: Row(
        children: [
          Expanded(
            child: _InfoTile(
              icon: Icons.calendar_today_rounded,
              label: 'Date',
              value: formattedDate,
            ),
          ),
          const VerticalDivider(
            color: AppColor.lightGrey,
            width: 1,
            thickness: 1,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: _InfoTile(
                icon: Icons.access_time_rounded,
                label: 'Time',
                value: formattedTime,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Payment summary content ──────────────────────────────────────────────────

class _PaymentSummaryContent extends StatelessWidget {
  final MyBookingModel booking;

  const _PaymentSummaryContent({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PayRow(
          label: 'Service Price',
          value: '\$${booking.price.toStringAsFixed(2)}',
        ),
        const SizedBox(height: 8),
        _PayRow(
          label: 'Deposit Paid',
          value: '\$${booking.depositAmount}',
        ),
        if (booking.balanceAmount > 0) ...[
          const SizedBox(height: 8),
          _PayRow(
            label: 'Balance Due',
            value: '\$${booking.balanceAmount.toStringAsFixed(2)}',
            valueColor: const Color(0xFFf1416c),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppText(
              'Payment Status',
              fontSize: FontSizes.small,
              color: AppColor.grey,
            ),
            _PaymentBadge(booking.balancePaymentStatus),
          ],
        ),
        if (booking.depositAmount > 0 || booking.balanceAmount > 0) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                'Deposit Status',
                fontSize: FontSizes.small,
                color: AppColor.grey,
              ),
              _PaymentBadge(booking.paymentStatus),
            ],
          ),
        ],
      ],
    );
  }
}

// ─── Bottom bar ───────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final MyBookingModel booking;
  final int bookingId;

  const _BottomBar({
    required this.booking,
    required this.bookingId,
  });

  bool get _showCancel =>
      booking.status.toLowerCase() != 'cancelled' &&
      booking.status.toLowerCase() != 'completed';

  bool get _showPay =>
      booking.status.toLowerCase() == 'confirmed' &&
      booking.paymentStatus.toLowerCase() != 'paid';

  Future<void> _handlePay(BuildContext context) async {
    final provider = context.read<MyBookingsProvider>();
    final url = await provider.payBalance(booking.id);
    if (!context.mounted) return;

    if (url != null) {
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => CustomWebView(
            checkoutUrl: url,
            title: 'Pay Balance',
          ),
        ),
      );

      if (!context.mounted) return;

      if (result == true) {
        await provider.fetchBookingDetail(booking.id);
        await provider.fetchBookings();
        if (!context.mounted) return;
        FunctionalComponent.showSnackBar(
          context: context,
          title: 'Payment successful!',
          success: true,
        );
      }
    } else {
      FunctionalComponent.showSnackBar(
        context: context,
        title: provider.payError,
        success: false,
      );
      provider.resetPayStatus();
    }
  }

  Future<void> _handleCancel(BuildContext context) async {
    final provider = context.read<MyBookingsProvider>();
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

    final success = await provider.cancelBooking(bookingId);
    if (!context.mounted) return;

    if (success) {
      FunctionalComponent.showSnackBar(
        context: context,
        title: 'Booking cancelled successfully.',
        success: true,
      );
      Navigator.of(context).pop();
    } else {
      FunctionalComponent.showSnackBar(
        context: context,
        title: provider.cancelError,
        success: false,
      );
      provider.resetCancelStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MyBookingsProvider>();
    final isPayLoading = provider.payStatus == BookingActionStatus.loading;
    final isCancelLoading =
        provider.cancelStatus == BookingActionStatus.loading;

    if (booking.rescheduleBook) {
      return Container(
        decoration: const BoxDecoration(
          color: AppColor.white,
          border: Border(top: BorderSide(color: AppColor.lightGrey)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.authButton,
                      foregroundColor: AppColor.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      context.push(RouteNames.bookingDetail, extra: {
                        'serviceId': booking.service.id,
                        'preSelectedProvider': booking.provider,
                        'rescheduleBookingId': booking.id,
                        'rescheduleAddressId': booking.addressId,
                      });
                    },
                    child: AppText(
                      'Reschedule',
                      fontSize: FontSizes.regular,
                      fontWeight: FontWeights.semiBold,
                      color: AppColor.white,
                    ),
                  ),
                ),
                if (_showCancel) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFf1416c)),
                        foregroundColor: const Color(0xFFf1416c),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: isCancelLoading
                          ? null
                          : () => _handleCancel(context),
                      child: isCancelLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Color(0xFFf1416c),
                                strokeWidth: 2,
                              ),
                            )
                          : AppText(
                              'Cancel Booking',
                              fontSize: FontSizes.regular,
                              fontWeight: FontWeights.semiBold,
                              color: const Color(0xFFf1416c),
                            ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    if (!_showCancel && !_showPay) return const SizedBox.shrink();

    return Container(
      decoration: const BoxDecoration(
        color: AppColor.white,
        border: Border(top: BorderSide(color: AppColor.lightGrey)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: _showPay && _showCancel
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.authButton,
                          foregroundColor: AppColor.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: isPayLoading
                            ? null
                            : () => _handlePay(context),
                        child: isPayLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: AppColor.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : AppText(
                                'Pay Balance \$${booking.balanceAmount.toStringAsFixed(2)}',
                                fontSize: FontSizes.regular,
                                fontWeight: FontWeights.semiBold,
                                color: AppColor.white,
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFf1416c)),
                          foregroundColor: const Color(0xFFf1416c),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: isCancelLoading
                            ? null
                            : () => _handleCancel(context),
                        child: isCancelLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Color(0xFFf1416c),
                                  strokeWidth: 2,
                                ),
                              )
                            : AppText(
                                'Cancel Booking',
                                fontSize: FontSizes.regular,
                                fontWeight: FontWeights.semiBold,
                                color: const Color(0xFFf1416c),
                              ),
                      ),
                    ),
                  ],
                )
              : _showPay
                  ? SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.authButton,
                          foregroundColor: AppColor.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: isPayLoading
                            ? null
                            : () => _handlePay(context),
                        child: isPayLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: AppColor.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : AppText(
                                'Pay Balance \$${booking.balanceAmount.toStringAsFixed(2)}',
                                fontSize: FontSizes.regular,
                                fontWeight: FontWeights.semiBold,
                                color: AppColor.white,
                              ),
                      ),
                    )
                  : SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFf1416c)),
                          foregroundColor: const Color(0xFFf1416c),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: isCancelLoading
                            ? null
                            : () => _handleCancel(context),
                        child: isCancelLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Color(0xFFf1416c),
                                  strokeWidth: 2,
                                ),
                              )
                            : AppText(
                                'Cancel Booking',
                                fontSize: FontSizes.regular,
                                fontWeight: FontWeights.semiBold,
                                color: const Color(0xFFf1416c),
                              ),
                      ),
                    ),
        ),
      ),
    );
  }
}

// ─── Inspiration & Notes content ─────────────────────────────────────────────

class _InspirationContent extends StatelessWidget {
  final MyBookingModel booking;

  const _InspirationContent({required this.booking});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = (booking.inspirationPhoto ?? '').isNotEmpty;
    final hasLink = (booking.pinterestLink ?? '').isNotEmpty;
    final hasNotes = (booking.notes ?? '').isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Inspiration photo ─────────────────────────────────────────
        if (hasPhoto) ...[
          AppText(
            'Inspiration Photo',
            fontSize: FontSizes.small,
            color: AppColor.grey,
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              PageRouteBuilder(
                opaque: false,
                barrierDismissible: true,
                pageBuilder: (_, _, _) => BookingInspirationViewer(
                  imageUrl: _resolvePhotoUrl(booking.inspirationPhoto ?? ''),
                  tag: 'inspiration_${booking.id}',
                ),
                transitionsBuilder: (_, anim, __, child) =>
                    FadeTransition(opacity: anim, child: child),
              ),
            ),
            child: Hero(
              tag: 'inspiration_${booking.id}',
              child: SizedBox(
                height: 180,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      FunctionalComponent.cachedNetworkImage(
                        _resolvePhotoUrl(booking.inspirationPhoto ?? ''),
                        fit: BoxFit.cover,
                        radius: 14,
                      ),
                      // Tap hint overlay
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.fullscreen_rounded,
                                  size: 13, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                'View full',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (hasLink || hasNotes) const SizedBox(height: 16),
        ],

        // ── Pinterest link ────────────────────────────────────────────
        if (hasLink) ...[
          _InspirationRow(
            icon: Icons.link_rounded,
            iconColor: const Color(0xFFE60023), // Pinterest red
            label: 'Pinterest Link',
            child: GestureDetector(
              onTap: () {
                // Open in webview / launch URL
              },
              child: Text(
                booking.pinterestLink??'',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFFE60023),
                  decoration: TextDecoration.underline,
                  decorationColor: Color(0xFFE60023),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          if (hasNotes) const SizedBox(height: 14),
        ],

        // ── Notes ─────────────────────────────────────────────────────
        if (hasNotes)
          _InspirationRow(
            icon: Icons.sticky_note_2_outlined,
            iconColor: AppColor.authButton,
            label: 'Notes',
            child: Text(
              booking.notes!,
              style: const TextStyle(
                fontSize: 13,
                color: AppColor.darkGrey,
                height: 1.5,
              ),
            ),
          ),
      ],
    );
  }

  static String _resolvePhotoUrl(String path) {
    final t = path.trim();
    if (t.startsWith('http://') || t.startsWith('https://')) return t;
    if (t.startsWith('/')) return '${ApiStrings.imageUrl}$t';
    return '${ApiStrings.imageUrl}/$t';
  }
}

class _InspirationRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final Widget child;

  const _InspirationRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                label,
                fontSize: 11,
                color: AppColor.grey,
              ),
              const SizedBox(height: 3),
              child,
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Helper widgets ───────────────────────────────────────────────────────────

class _PayRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _PayRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText(
          label,
          fontSize: FontSizes.small,
          color: AppColor.grey,
        ),
        AppText(
          value,
          fontSize: FontSizes.small,
          fontWeight: FontWeights.bold,
          color: valueColor ?? AppColor.darkGrey,
        ),
      ],
    );
  }
}

class _PaymentBadge extends StatelessWidget {
  final String status;

  const _PaymentBadge(this.status);

  @override
  Widget build(BuildContext context) {
    final color = _paymentStatusColor(status);
    final bg = _paymentStatusBg(status);
    final icon = _paymentStatusIcon(status);
    final label = status.isEmpty
        ? 'Unknown'
        : '${status[0].toUpperCase()}${status.substring(1)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          AppText(
            label,
            fontSize: 11,
            fontWeight: FontWeights.semiBold,
            color: color,
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: AppColor.grey),
            const SizedBox(width: 4),
            AppText(
              label,
              fontSize: FontSizes.small,
              color: AppColor.grey,
            ),
          ],
        ),
        const SizedBox(height: 4),
        AppText(
          value,
          fontSize: FontSizes.small,
          fontWeight: FontWeights.semiBold,
          color: AppColor.darkGrey,
        ),
      ],
    );
  }
}

// ─── Full-screen image viewer ─────────────────────────────────────────────────

class BookingInspirationViewer extends StatefulWidget {
  final String imageUrl;
  final String tag;

  const BookingInspirationViewer({
    required this.imageUrl,
    required this.tag,
  });

  @override
  State<BookingInspirationViewer> createState() => BookingInspirationViewerState();
}

class BookingInspirationViewerState extends State<BookingInspirationViewer>
    with SingleTickerProviderStateMixin {
  final _transformCtrl = TransformationController();
  late final AnimationController _dismissCtrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _dismissCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      value: 1.0,
    );
    _opacity = _dismissCtrl;
  }

  @override
  void dispose() {
    _transformCtrl.dispose();
    _dismissCtrl.dispose();
    super.dispose();
  }

  void _close() {
    _dismissCtrl.reverse().then((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  void _onDoubleTap() {
    if (_transformCtrl.value != Matrix4.identity()) {
      _transformCtrl.value = Matrix4.identity();
    } else {
      _transformCtrl.value = Matrix4.identity()..scale(2.5);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: GestureDetector(
        onTap: _close,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            fit: StackFit.expand,
            children: [
              // ── Zoomable image ─────────────────────────────────────
              Center(
                child: GestureDetector(
                  onDoubleTap: _onDoubleTap,
                  child: InteractiveViewer(
                    transformationController: _transformCtrl,
                    minScale: 0.8,
                    maxScale: 5.0,
                    child: Hero(
                      tag: widget.tag,
                      child: FunctionalComponent.cachedNetworkImage(
                        widget.imageUrl,
                        fit: BoxFit.contain,
                        radius: 0,
                      ),
                    ),
                  ),
                ),
              ),

              // ── Close button ───────────────────────────────────────
              Positioned(
                top: MediaQuery.of(context).padding.top + 12,
                right: 16,
                child: GestureDetector(
                  onTap: _close,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),

              // ── Double-tap hint ────────────────────────────────────
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 20,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Double-tap to zoom · Tap anywhere to close',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
