import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pampa/core/utils/functional_component.dart';
import 'package:provider/provider.dart';

import 'package:pampa/core/routes/routes.dart';
import 'package:pampa/core/values/colors.dart';
import 'package:pampa/core/values/app_text_value.dart';
import 'package:pampa/core/widgets/text_widget.dart';
import 'package:pampa/features/my_bookings/data/models/my_booking_model.dart';
import 'package:pampa/features/my_bookings/presentation/provider/my_bookings_provider.dart';

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

// ─── Tab widget ───────────────────────────────────────────────────────────────

class MyBookingsTab extends StatefulWidget {
  const MyBookingsTab({super.key});

  @override
  State<MyBookingsTab> createState() => _MyBookingsTabState();
}

class _MyBookingsTabState extends State<MyBookingsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MyBookingsProvider>().fetchBookings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MyBookingsProvider>(
      builder: (context, provider, _) {
        return RefreshIndicator(
          color: AppColor.authButton,
          onRefresh: () => provider.refresh(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── Header ──────────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FunctionalComponent.customAppBar(title: 'Bookings'),

                      if (provider.status == MyBookingsFetchStatus.success) ...[
                        const SizedBox(height: 4),
                        AppText(
                          '${provider.bookings.length} booking${provider.bookings.length == 1 ? '' : 's'}',
                          fontSize: FontSizes.small,
                          color: AppColor.grey,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // ── Filter chips ─────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _FilterChips(
                  current: provider.filter,
                  onSelect: provider.setFilter,
                ),
              ),

              // ── Content ──────────────────────────────────────────────────
              _buildContent(provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(MyBookingsProvider provider) {
    switch (provider.status) {
      case MyBookingsFetchStatus.loading:
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, __) => const _BookingCardShimmer(),
              childCount: 4,
            ),
          ),
        );

      case MyBookingsFetchStatus.error:
        return SliverFillRemaining(
          child: _ErrorState(
            message: provider.error,
            onRetry: provider.refresh,
          ),
        );

      case MyBookingsFetchStatus.empty:
        return const SliverFillRemaining(
          child: _EmptyState(message: 'You have no bookings yet.'),
        );

      case MyBookingsFetchStatus.initial:
        return const SliverToBoxAdapter(child: SizedBox.shrink());

      case MyBookingsFetchStatus.success:
        final list = provider.bookings;
        if (list.isEmpty) {
          return SliverFillRemaining(
            child: _EmptyState(
              message: 'No ${provider.filter.name} bookings found.',
            ),
          );
        }
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, index) => _BookingCard(booking: list[index]),
              childCount: list.length,
            ),
          ),
        );
    }
  }
}

// ─── Filter chips ─────────────────────────────────────────────────────────────

class _FilterChips extends StatelessWidget {
  final BookingFilter current;
  final void Function(BookingFilter) onSelect;

  const _FilterChips({required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _Chip(
              label: 'All',
              active: current == BookingFilter.all,
              onTap: () => onSelect(BookingFilter.all),
            ),
            const SizedBox(width: 8),
            _Chip(
              label: 'Upcoming',
              active: current == BookingFilter.upcoming,
              onTap: () => onSelect(BookingFilter.upcoming),
            ),
            const SizedBox(width: 8),
            _Chip(
              label: 'Completed',
              active: current == BookingFilter.completed,
              onTap: () => onSelect(BookingFilter.completed),
            ),
            const SizedBox(width: 8),
            _Chip(
              label: 'Cancelled',
              active: current == BookingFilter.cancelled,
              onTap: () => onSelect(BookingFilter.cancelled),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _Chip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColor.authButton : AppColor.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? AppColor.authButton : AppColor.mediumGrey,
          ),
        ),
        child: AppText(
          label,
          fontSize: 12,
          fontWeight: active ? FontWeights.semiBold : FontWeights.regular,
          color: active ? AppColor.white : AppColor.darkGrey,
        ),
      ),
    );
  }
}

// ─── Booking card ─────────────────────────────────────────────────────────────

class _BookingCard extends StatelessWidget {
  final MyBookingModel booking;

  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(booking.status);
    final statusBg = _statusBgColor(booking.status);
    final formattedDate =
        DateFormat('MMM d, yyyy').format(booking.appointmentDate);
    final formattedTime = _formatTime(booking.appointmentTime);

    return GestureDetector(
      onTap: () => context.push(RouteNames.myBookingDetail, extra: booking.id),
      child: Container(
      margin: const EdgeInsets.only(bottom: 14),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: icon + service info + status ──────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Service icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColor.authBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.spa_rounded,
                    color: AppColor.authButton,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),

                // Service name + provider name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        booking.service.serviceName,
                        fontSize: FontSizes.regular,
                        fontWeight: FontWeights.bold,
                        color: AppColor.darkGrey,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.person_rounded,
                              size: 13, color: AppColor.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: AppText(
                              booking.provider.displayName,
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

                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: AppText(
                    booking.status,
                    fontSize: 11,
                    fontWeight: FontWeights.semiBold,
                    color: statusColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColor.lightGrey),
            const SizedBox(height: 12),

            // ── Bottom row: date + time ────────────────────────────────
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 14, color: AppColor.authButton),
                const SizedBox(width: 5),
                AppText(
                  formattedDate,
                  fontSize: 12,
                  color: AppColor.darkGrey,
                  fontWeight: FontWeights.semiBold,
                ),
                const SizedBox(width: 16),
                const Icon(Icons.access_time_rounded,
                    size: 14, color: AppColor.authButton),
                const SizedBox(width: 5),
                AppText(
                  formattedTime,
                  fontSize: 12,
                  color: AppColor.darkGrey,
                  fontWeight: FontWeights.semiBold,
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ── Price + payment status ─────────────────────────────────
            Row(
              children: [
                AppText(
                  '\$${booking.price.toStringAsFixed(2)}',
                  fontSize: FontSizes.medium,
                  fontWeight: FontWeights.bold,
                  color: AppColor.authButton,
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _paymentStatusBg(booking.paymentStatus),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _paymentStatusIcon(booking.paymentStatus),
                        size: 11,
                        color: _paymentStatusColor(booking.paymentStatus),
                      ),
                      const SizedBox(width: 4),
                      AppText(
                        booking.paymentStatus.isEmpty
                            ? 'Unknown'
                            : '${booking.paymentStatus[0].toUpperCase()}${booking.paymentStatus.substring(1)}',
                        fontSize: 11,
                        fontWeight: FontWeights.semiBold,
                        color: _paymentStatusColor(booking.paymentStatus),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
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
    _animation = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
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
      builder: (_, __) => Opacity(
        opacity: _animation.value,
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColor.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _box(56, 56, radius: 12),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _box(160, 14),
                        const SizedBox(height: 8),
                        _box(100, 12),
                      ],
                    ),
                  ),
                  _box(72, 26, radius: 20),
                ],
              ),
              const SizedBox(height: 14),
              _box(double.infinity, 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  _box(120, 12),
                  const SizedBox(width: 16),
                  _box(80, 12),
                  const Spacer(),
                  _box(60, 16),
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
              child: const Icon(Icons.bookmark_border_rounded,
                  size: 36, color: AppColor.authButton),
            ),
            const SizedBox(height: 20),
            AppText(
              'No Bookings',
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
              child: const Icon(Icons.wifi_off_rounded,
                  size: 36, color: AppColor.authButton),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
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
