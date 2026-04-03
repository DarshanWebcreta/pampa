import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pampa/core/utils/functional_component.dart';
import 'package:pampa/core/values/app_text_value.dart';
import 'package:pampa/core/values/colors.dart';
import 'package:pampa/core/widgets/text_widget.dart';
import 'package:pampa/features/provider_home/data/models/provider_booking_model.dart';
import 'package:pampa/features/provider_home/presentation/provider/provider_bookings_provider.dart';
import 'package:pampa/features/provider_home/presentation/provider_booking_detail_screen.dart';

class ProviderBookingsTab extends StatefulWidget {
  const ProviderBookingsTab({super.key});

  @override
  State<ProviderBookingsTab> createState() => _ProviderBookingsTabState();
}

class _ProviderBookingsTabState extends State<ProviderBookingsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProviderBookingsProvider>().fetch();
    });
  }

  Future<void> _pickDate(BuildContext context, ProviderBookingsProvider prov) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: prov.selectedDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppColor.authButton,
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (!mounted) return;
    if (picked != null) prov.setDate(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProviderBookingsProvider>(
      builder: (context, prov, _) {
        return Column(
          children: [
              // ── App bar ────────────────────────────────────────────────
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
                    Expanded(
                      child: AppText(
                        'Bookings',
                        fontSize: 20,
                        fontWeight: FontWeights.bold,
                        color: AppColor.darkGrey,
                      ),
                    ),
                    // Date filter button
                    GestureDetector(
                      onTap: () => _pickDate(context, prov),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: prov.selectedDate != null
                              ? AppColor.authButton
                              : AppColor.authBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: prov.selectedDate != null
                                ? AppColor.authButton
                                : AppColor.mediumGrey,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 13,
                              color: prov.selectedDate != null
                                  ? Colors.white
                                  : AppColor.grey,
                            ),
                            const SizedBox(width: 5),
                            AppText(
                              prov.selectedDate != null
                                  ? _formatDate(prov.selectedDate!)
                                  : 'Date',
                              fontSize: 12,
                              fontWeight: FontWeights.semiBold,
                              color: prov.selectedDate != null
                                  ? Colors.white
                                  : AppColor.grey,
                            ),
                            if (prov.selectedDate != null) ...[
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: prov.clearDate,
                                child: const Icon(Icons.close_rounded,
                                    size: 13, color: Colors.white),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Status filter chips ────────────────────────────────────
              Container(
                color: AppColor.white,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ProviderBookingsProvider.statuses.map((s) {
                      final isActive = prov.selectedStatus == s;
                      return GestureDetector(
                        onTap: () => prov.setStatus(s),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColor.authButton
                                : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: AppText(
                            s == 'all' ? 'All' : s,
                            fontSize: 13,
                            fontWeight: isActive
                                ? FontWeights.semiBold
                                : FontWeights.regular,
                            color: isActive ? Colors.white : AppColor.grey,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // ── List ───────────────────────────────────────────────────
              Expanded(
                child: prov.loading
                    ? const Center(child: CircularProgressIndicator())
                    : prov.error.isNotEmpty && prov.bookings.isEmpty
                        ? _ErrorView(
                            message: prov.error,
                            onRetry: prov.fetch,
                          )
                        : prov.bookings.isEmpty
                            ? _EmptyView(status: prov.selectedStatus)
                            : RefreshIndicator(
                                onRefresh: prov.fetch,
                                color: AppColor.authButton,
                                child: ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(
                                      16, 12, 16, 24),
                                  itemCount: prov.bookings.length,
                                  itemBuilder: (_, i) => _BookingCard(
                                    booking: prov.bookings[i],
                                  ),
                                ),
                              ),
              ),
            ],
          );
      },
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}';
  }
}

// ─── Booking Card ──────────────────────────────────────────────────────────────

class _BookingCard extends StatelessWidget {
  final ProviderBookingModel booking;

  const _BookingCard({required this.booking});

  static Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'confirmed':
        return const Color(0xFF3B82F6);
      case 'completed':
        return const Color(0xFF10B981);
      case 'cancelled':
        return const Color(0xFFEF4444);
      default:
        return AppColor.grey;
    }
  }

  static Color _statusBg(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFEF3C7);
      case 'confirmed':
        return const Color(0xFFEFF6FF);
      case 'completed':
        return const Color(0xFFD1FAE5);
      case 'cancelled':
        return const Color(0xFFFEE2E2);
      default:
        return AppColor.authBg;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(booking.status);
    final bg = _statusBg(booking.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            final didChange = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => ProviderBookingDetailScreen(
                  bookingId: booking.id,
                  initialStatus: booking.status,
                ),
              ),
            );
            if (didChange == true && context.mounted) {
              context.read<ProviderBookingsProvider>().fetch();
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header row ──────────────────────────────────────────
                Row(
                  children: [
                    _Avatar(
                      name: booking.customer.displayName,
                      photoUrl: booking.customer.profileImage,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            booking.customer.displayName,
                            fontSize: FontSizes.regular,
                            fontWeight: FontWeights.semiBold,
                            color: AppColor.darkGrey,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 2),
                          if (booking.services.isNotEmpty)
                            AppText(
                              booking.services
                                  .map((s) => s.serviceName)
                                  .join(', '),
                              fontSize: 13,
                              color: AppColor.grey,
                              maxLines: 1,
                            ),
                        ],
                      ),
                    ),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: AppText(
                        booking.status,
                        fontSize: 11,
                        fontWeight: FontWeights.semiBold,
                        color: color,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF3F4F6)),
                const SizedBox(height: 12),

                // ── Details row ─────────────────────────────────────────
                Row(
                  children: [
                    _InfoChip(
                      icon: Icons.calendar_today_rounded,
                      label: booking.formattedDate,
                    ),
                    const SizedBox(width: 12),
                    _InfoChip(
                      icon: Icons.access_time_rounded,
                      label: booking.formattedTime,
                    ),
                    const Spacer(),
                    // Price
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        AppText(
                          booking.formattedPrice,
                          fontSize: FontSizes.medium,
                          fontWeight: FontWeights.bold,
                          color: AppColor.darkGrey,
                        ),
                        if (booking.paymentStatus.isNotEmpty)
                          AppText(
                            booking.paymentStatus,
                            fontSize: 10,
                            color: booking.paymentStatus.toLowerCase() == 'paid'
                                ? const Color(0xFF10B981)
                                : AppColor.grey,
                          ),
                      ],
                    ),
                  ],
                ),

                // ── Service duration chips ──────────────────────────────
                if (booking.services.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    children: booking.services.map((s) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColor.authButton.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppText(
                              s.serviceName,
                              fontSize: 11,
                              color: AppColor.authButton,
                              maxLines: 1,
                            ),
                            if (s.formattedDuration.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              AppText(
                                '· ${s.formattedDuration}',
                                fontSize: 11,
                                color: AppColor.authButton
                                    .withValues(alpha: 0.7),
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],

                // ── Notes ──────────────────────────────────────────────
                if (booking.notes != null && booking.notes!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.notes_rounded,
                          size: 13, color: AppColor.grey),
                      const SizedBox(width: 5),
                      Expanded(
                        child: AppText(
                          booking.notes!,
                          fontSize: 12,
                          color: AppColor.grey,
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColor.grey),
        const SizedBox(width: 4),
        AppText(label, fontSize: 12, color: AppColor.grey),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final String? photoUrl;

  const _Avatar({required this.name, this.photoUrl});

  @override
  Widget build(BuildContext context) {
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return ClipOval(
        child: SizedBox(
          width: 44,
          height: 44,
          child: FunctionalComponent.cachedNetworkImage(
            photoUrl!,
            fit: BoxFit.cover,
            radius: 22,
          ),
        ),
      );
    }
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColor.authButton.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColor.authButton,
        ),
      ),
    );
  }
}

// ─── Empty / Error ─────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final String status;
  const _EmptyView({required this.status});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.calendar_month_rounded,
              size: 56, color: AppColor.mediumGrey),
          const SizedBox(height: 16),
          AppText(
            status == 'all'
                ? 'No bookings found'
                : 'No $status bookings',
            fontSize: FontSizes.medium,
            fontWeight: FontWeights.semiBold,
            color: AppColor.grey,
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
            const SizedBox(height: 12),
            AppText(
              message,
              fontSize: FontSizes.regular,
              color: AppColor.grey,
              align: TextAlign.center,
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.authButton,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
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
