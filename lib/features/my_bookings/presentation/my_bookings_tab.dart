import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pampa/core/utils/functional_component.dart';
import 'package:pampa/core/values/urls.dart';
import 'package:provider/provider.dart';

import 'package:pampa/core/routes/routes.dart';
import 'package:pampa/core/values/colors.dart';
import 'package:pampa/core/values/app_text_value.dart';
import 'package:pampa/core/widgets/text_widget.dart';
import 'package:pampa/features/home/presentation/home_screen.dart';
import 'package:pampa/features/my_bookings/data/models/my_booking_model.dart';
import 'package:pampa/features/my_bookings/presentation/provider/my_bookings_provider.dart';
import 'package:pampa/features/chat/presentation/chat_screen.dart';
import 'package:pampa/features/webview/webview.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

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

Widget _serviceAvatar(String? photoUrl, String serviceName, double size) {
  final initials = serviceName
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .take(2)
      .map((p) => p[0].toUpperCase())
      .join();

  if (photoUrl != null && photoUrl.trim().isNotEmpty) {
    final trimmed = photoUrl.trim();
    final url = trimmed.startsWith('http://') || trimmed.startsWith('https://')
        ? trimmed
        : (trimmed.startsWith('/')
            ? '${ApiStrings.imageUrl}$trimmed'
            : '${ApiStrings.imageUrl}/$trimmed');

    return ClipOval(
      child: FunctionalComponent.cachedNetworkImage(
        url,
        radius: size / 2,
        fit: BoxFit.cover,
      ),
    );
  }

  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: AppColor.authButton.withValues(alpha: 0.12),
      shape: BoxShape.circle,
    ),
    alignment: Alignment.center,
    child: AppText(
      initials.isEmpty ? '?' : initials,
      fontSize: 14,
      fontWeight: FontWeights.bold,
      color: AppColor.authButton,
    ),
  );
}

// ─── Tab widget ───────────────────────────────────────────────────────────────

class MyBookingsTab extends StatefulWidget {
  const MyBookingsTab({super.key});

  @override
  State<MyBookingsTab> createState() => _MyBookingsTabState();
}

class _MyBookingsTabState extends State<MyBookingsTab> {
  final Set<String> _expandedDates = {};
  AppointmentTab? _prevTab;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MyBookingsProvider>().fetchBookings();
    });
  }

  Future<void> _pickDate(
    BuildContext context,
    MyBookingsProvider provider,
  ) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: provider.selectedDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColor.authButton,
              onPrimary: AppColor.white,
              onSurface: AppColor.darkGrey,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: AppColor.authButton),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      provider.setSelectedDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MyBookingsProvider>(
      builder: (context, provider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
              child: Row(
                children: [
                  AppText(
                    'Appointments',
                    fontSize: 28,
                    fontWeight: FontWeights.bold,
                    color: AppColor.darkGrey,
                  ),
                  const Spacer(),

                  GestureDetector(
                    onTap: () => _pickDate(context, provider),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: provider.selectedDate != null
                            ? AppColor.authButton
                            : AppColor.lightGrey,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.calendar_month_rounded,
                        color: provider.selectedDate != null
                            ? AppColor.white
                            : AppColor.darkGrey,
                        size: 18,
                      ),
                    ),
                  ),
                  // const SizedBox(width: 12),
                  // GestureDetector(
                  //   onTap: () => homeTabNotifier.value = 1,
                  //   child: Container(
                  //     width: 38,
                  //     height: 38,
                  //     decoration: const BoxDecoration(
                  //       color: AppColor.darkGrey,
                  //       shape: BoxShape.circle,
                  //     ),
                  //     child: const Icon(
                  //       Icons.add,
                  //       color: AppColor.white,
                  //       size: 20,
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),

            if (provider.selectedDate != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    AppText(
                      'Showing bookings for ',
                      fontSize: 13,
                      color: AppColor.grey,
                    ),
                    AppText(
                      DateFormat('MMMM d, yyyy').format(provider.selectedDate!),
                      fontSize: 13,
                      fontWeight: FontWeights.semiBold,
                      color: AppColor.authButton,
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => provider.setSelectedDate(null),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColor.authButton.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 14,
                          color: AppColor.authButton,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // ── Tab switcher ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _TabSwitcher(
                activeTab: provider.activeTab,
                onTabChanged: provider.setTab,
              ),
            ),

            const SizedBox(height: 16),

            // ── Content ──────────────────────────────────────────────────
            Expanded(child: _buildContent(provider)),
          ],
        );
      },
    );
  }

  Widget _buildContent(MyBookingsProvider provider) {
    if (_prevTab != provider.activeTab) {
      _expandedDates.clear();
      _prevTab = provider.activeTab;
    }

    switch (provider.status) {
      case MyBookingsFetchStatus.loading:
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          itemCount: 4,
          itemBuilder: (_, unusedIndex) => const _BookingCardShimmer(),
        );

      case MyBookingsFetchStatus.error:
        return _ErrorState(message: provider.error, onRetry: provider.refresh);

      case MyBookingsFetchStatus.empty:
      case MyBookingsFetchStatus.initial:
        return _EmptyState(
          message: provider.activeTab == AppointmentTab.upcoming
              ? 'No upcoming appointments.'
              : 'No past appointments.',
        );

      case MyBookingsFetchStatus.success:
        final list = provider.bookings;
        if (list.isEmpty) {
          return _EmptyState(
            message: provider.activeTab == AppointmentTab.upcoming
                ? 'No upcoming appointments.'
                : 'No past appointments.',
          );
        }

        // Group bookings by normalized date
        final Map<DateTime, List<MyBookingModel>> grouped = {};
        for (final booking in list) {
          final date = booking.appointmentDate;
          final key = DateTime(date.year, date.month, date.day);
          (grouped[key] ??= []).add(booking);
        }

        // Sort keys depending on the active tab
        final sortedKeys = grouped.keys.toList();
        if (provider.activeTab == AppointmentTab.upcoming) {
          sortedKeys.sort((a, b) => a.compareTo(b));
        } else {
          sortedKeys.sort((a, b) => b.compareTo(a));
        }



        return RefreshIndicator(
          color: AppColor.authButton,
          onRefresh: provider.refresh,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            itemCount: sortedKeys.length,
            itemBuilder: (context, index) {
              final dateKey = sortedKeys[index];
              final dateStr = DateFormat('yyyy-MM-dd').format(dateKey);
              final isExpanded = _expandedDates.contains(dateStr);
              final dayBookings = grouped[dateKey] ?? [];

              return _DateGroupCard(
                dateKey: dateKey,
                bookings: dayBookings,
                isExpanded: isExpanded,
                showBookAgain: provider.activeTab == AppointmentTab.past,
                onToggle: () {
                  setState(() {
                    if (isExpanded) {
                      _expandedDates.remove(dateStr);
                    } else {
                      _expandedDates.add(dateStr);
                    }
                  });
                },
              );
            },
          ),
        );
    }
  }
}

// ─── Tab switcher ─────────────────────────────────────────────────────────────

class _TabSwitcher extends StatelessWidget {
  final AppointmentTab activeTab;
  final void Function(AppointmentTab) onTabChanged;

  const _TabSwitcher({required this.activeTab, required this.onTabChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColor.lightGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _TabItem(
            label: 'Upcoming',
            active: activeTab == AppointmentTab.upcoming,
            onTap: () => onTabChanged(AppointmentTab.upcoming),
          ),
          _TabItem(
            label: 'Past',
            active: activeTab == AppointmentTab.past,
            onTap: () => onTabChanged(AppointmentTab.past),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TabItem({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 0),
          decoration: BoxDecoration(
            color: active ? AppColor.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: AppText(
            label,
            fontSize: 13,
            fontWeight: active ? FontWeights.semiBold : FontWeights.regular,
            color: active ? AppColor.darkGrey : AppColor.grey,
          ),
        ),
      ),
    );
  }
}

// ─── Grouped Date Card ────────────────────────────────────────────────────────

String _formatHeaderDate(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final dateMidnight = DateTime(date.year, date.month, date.day);

  final difference = dateMidnight.difference(today).inDays;
  if (difference == 0) {
    return 'Today, ${DateFormat('MMM d').format(date)}';
  } else if (difference == 1) {
    return 'Tomorrow, ${DateFormat('MMM d').format(date)}';
  } else if (difference == -1) {
    return 'Yesterday, ${DateFormat('MMM d').format(date)}';
  } else {
    return DateFormat('EEEE, MMM d, yyyy').format(date);
  }
}

class _DateGroupCard extends StatelessWidget {
  final DateTime dateKey;
  final List<MyBookingModel> bookings;
  final bool isExpanded;
  final bool showBookAgain;
  final VoidCallback onToggle;

  const _DateGroupCard({
    required this.dateKey,
    required this.bookings,
    required this.isExpanded,
    required this.showBookAgain,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final count = bookings.length;
    final dateText = _formatHeaderDate(dateKey);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColor.authButton.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.calendar_month_rounded,
                      color: AppColor.authButton,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          dateText,
                          fontSize: 15,
                          fontWeight: FontWeights.bold,
                          color: AppColor.darkGrey,
                        ),
                        const SizedBox(height: 2),
                        AppText(
                          '$count appointment${count > 1 ? 's' : ''}',
                          fontSize: 11,
                          color: AppColor.grey,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColor.grey,
                  ),
                ],
              ),
            ),
          ),

          // Body Content (Collapsible)
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isExpanded) ...[
                  // Collapsed view: list of titles
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Divider(height: 1, color: Colors.black.withValues(alpha: 0.06)),
                        const SizedBox(height: 8),
                        ...bookings.map((booking) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: AppColor.authButton,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: AppText(
                                      booking.service.serviceName,
                                      fontSize: 13,
                                      fontWeight: FontWeights.medium,
                                      color: AppColor.darkGrey,
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                ] else ...[
                  // Expanded view: list of full appointment details
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Divider(height: 1, color: Colors.black.withValues(alpha: 0.06)),
                        const SizedBox(height: 12),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: bookings.length,
                          padding: EdgeInsets.zero,
                          separatorBuilder: (_, __) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Divider(
                              height: 1,
                              color: Colors.black.withValues(alpha: 0.06),
                            ),
                          ),
                          itemBuilder: (context, i) {
                            final booking = bookings[i];
                            return _DetailedAppointmentRow(
                              booking: booking,
                              showBookAgain: showBookAgain,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailedAppointmentRow extends StatelessWidget {
  final MyBookingModel booking;
  final bool showBookAgain;

  const _DetailedAppointmentRow({
    required this.booking,
    required this.showBookAgain,
  });

  bool get _showRetryPayment =>
      booking.paymentStatus.toLowerCase() == 'pending_payment' &&
      (booking.paymentId ?? 0) > 0;

  Future<void> _handleRetryPayment(BuildContext context) async {
    final paymentId = booking.paymentId;
    if (paymentId == null || paymentId <= 0) return;

    final provider = context.read<MyBookingsProvider>();
    final url = await provider.retryPayment(paymentId);
    if (!context.mounted) return;

    if (url == null || url.isEmpty) {
      FunctionalComponent.showSnackBar(
        context: context,
        title: provider.payError,
        success: false,
      );
      provider.resetPayStatus();
      return;
    }

    final paid = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CustomWebView(checkoutUrl: url, title: 'Retry Payment'),
      ),
    );

    if (!context.mounted) return;

    if (paid == true) {
      await provider.fetchBookings();
      if (!context.mounted) return;
      FunctionalComponent.showSnackBar(
        context: context,
        title: 'Payment successful!',
        success: true,
      );
    } else {
      FunctionalComponent.showSnackBar(
        context: context,
        title: 'Payment cancelled. Your booking is still pending.',
        success: false,
      );
    }

    provider.resetPayStatus();
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat(
      'MMM d, yyyy',
    ).format(booking.appointmentDate);
    final formattedTime = _formatTime(booking.appointmentTime);
    final price = booking.price % 1 == 0
        ? '\$${booking.price.toInt()}'
        : '\$${booking.price.toStringAsFixed(2)}';

    return GestureDetector(
      onTap: () => context.push(RouteNames.myBookingDetail, extra: booking.id),
      child: Container(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 35,
                  width: 35,
                  child: _serviceAvatar(
                    booking.services.isNotEmpty
                        ? booking.services.first.image
                        : booking.service.image,
                    booking.service.serviceName,
                    35.0,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        booking.service.serviceName,
                        fontSize: FontSizes.regular,
                        fontWeight: FontWeights.bold,
                        color: AppColor.darkGrey,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 3),
                      AppText(
                        booking.provider != null
                            ? 'with ${booking.provider!.displayName}'
                            : '',
                        fontSize: 12,
                        color: AppColor.grey,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColor.authBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: AppText(
                    price,
                    fontSize: 13,
                    fontWeight: FontWeights.bold,
                    color: AppColor.darkGrey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 12,
                        color: AppColor.grey,
                      ),
                      const SizedBox(width: 4),
                      AppText(formattedDate, fontSize: 11, color: AppColor.grey),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.access_time_rounded,
                        size: 12,
                        color: AppColor.grey,
                      ),
                      const SizedBox(width: 4),
                      AppText(formattedTime, fontSize: 11, color: AppColor.grey),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_showRetryPayment)
                        Consumer<MyBookingsProvider>(
                          builder: (context, provider, _) {
                            final isLoading =
                                provider.payStatus == BookingActionStatus.loading &&
                                provider.activePayTargetId == booking.paymentId;

                            return GestureDetector(
                              onTap: isLoading
                                  ? null
                                  : () => _handleRetryPayment(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColor.authButton,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                        width: 10,
                                        height: 10,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            AppColor.white,
                                          ),
                                        ),
                                      )
                                    : AppText(
                                        'Retry Payment',
                                        fontSize: 11,
                                        fontWeight: FontWeights.semiBold,
                                        color: AppColor.white,
                                      ),
                              ),
                            );
                          },
                        ),
                      if (_showRetryPayment) const SizedBox(width: 6),
                      if (booking.isConfirmed && booking.providerId != null)
                        GestureDetector(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => BookingChatScreen(
                                bookingId: booking.id,
                                providerId: booking.providerId!,
                                providerName:
                                    booking.provider?.displayName ?? 'Provider',
                              ),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFe8fff3),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 11,
                                  color: Color(0xFF50cd89),
                                ),
                                const SizedBox(width: 3),
                                AppText(
                                    'Chat',
                                    fontSize: 11,
                                    fontWeight: FontWeights.semiBold,
                                    color: const Color(0xFF50cd89),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (booking.rescheduleBook) ...[
                          if (_showRetryPayment ||
                              (booking.isConfirmed && booking.providerId != null))
                            const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () {
                              context.push(
                                RouteNames.bookingDetail,
                                extra: {
                                  'serviceId': booking.service.id,
                                  'preSelectedProvider': booking.provider,
                                  'rescheduleBookingId': booking.id,
                                  'rescheduleAddressId': booking.addressId,
                                },
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFfff4e5),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.edit_calendar_rounded,
                                    size: 11,
                                    color: Color(0xFFe65100),
                                  ),
                                  const SizedBox(width: 3),
                                  AppText(
                                    'Reschedule',
                                    fontSize: 11,
                                    fontWeight: FontWeights.semiBold,
                                    color: const Color(0xFFe65100),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        if (showBookAgain)
                          Row(
                            children: [
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => context.push(
                                  RouteNames.bookingDetail,
                                  extra: {
                                    'serviceId': booking.service.id,
                                    'preSelectedProvider': booking.provider,
                                    'isBookAgain': true,
                                  },
                                ),
                                child: AppText(
                                  'Book Again',
                                  fontSize: 11,
                                  fontWeight: FontWeights.semiBold,
                                  color: AppColor.authButton,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Shimmer ──────────────────────────────────────────────────────────────────

class _BookingCardShimmer extends StatefulWidget {
  const _BookingCardShimmer();

  @override
  State<_BookingCardShimmer> createState() => _BookingCardShimmerState();
}

class _BookingCardShimmerState extends State<_BookingCardShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, unusedChild) => Opacity(
        opacity: _animation.value,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColor.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _box(48, 48, radius: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _box(140, 14),
                        const SizedBox(height: 8),
                        _box(100, 12),
                      ],
                    ),
                  ),
                  _box(52, 30, radius: 8),
                ],
              ),
              const SizedBox(height: 12),
              _box(double.infinity, 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  _box(100, 12),
                  const SizedBox(width: 12),
                  _box(70, 12),
                  const Spacer(),
                  _box(72, 12),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _box(double w, double h, {double radius = 6}) => Container(
    width: w,
    height: h,
    decoration: BoxDecoration(
      color: AppColor.lightGrey,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColor.authBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.calendar_today_outlined,
                size: 34,
                color: AppColor.authButton,
              ),
            ),
            const SizedBox(height: 20),
            AppText(
              'No Appointments',
              fontSize: FontSizes.medium,
              fontWeight: FontWeights.semiBold,
              color: AppColor.darkGrey,
            ),
            const SizedBox(height: 8),
            AppText(
              message,
              fontSize: FontSizes.small,
              color: AppColor.grey,
              align: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Error state ──────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColor.authBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 36,
                color: AppColor.authButton,
              ),
            ),
            const SizedBox(height: 20),
            AppText(
              'Something went wrong',
              fontSize: FontSizes.medium,
              fontWeight: FontWeights.semiBold,
              color: AppColor.darkGrey,
              align: TextAlign.center,
            ),
            const SizedBox(height: 8),
            AppText(
              message,
              fontSize: FontSizes.small,
              color: AppColor.grey,
              align: TextAlign.center,
              maxLines: 3,
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
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
  }
}
