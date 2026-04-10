import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:pampa/core/utils/functional_component.dart';
import 'package:pampa/core/values/app_text_value.dart';
import 'package:pampa/core/values/colors.dart';
import 'package:pampa/core/widgets/text_widget.dart';
import 'package:pampa/data/service/apiservice.dart';
import 'package:pampa/data/service/di.dart';
import 'package:pampa/features/provider_home/data/models/provider_booking_model.dart';
import 'package:pampa/features/provider_home/presentation/provider/provider_messaging_provider.dart';
import 'package:pampa/features/provider_home/presentation/provider_chat_screen.dart';

class ProviderBookingDetailScreen extends StatefulWidget {
  final int bookingId;
  final String? initialStatus;

  const ProviderBookingDetailScreen({
    super.key,
    required this.bookingId,
    this.initialStatus,
  });

  @override
  State<ProviderBookingDetailScreen> createState() =>
      _ProviderBookingDetailScreenState();
}

class _ProviderBookingDetailScreenState
    extends State<ProviderBookingDetailScreen> {
  final _api = getIt<ApiService>();

  ProviderBookingModel? _booking;
  bool _loading = true;
  String _error = '';
  bool _actionLoading = false;
  bool _chatLoading = false;
  bool _didChangeStatus = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final res = await _api.getProviderBookingDetail(widget.bookingId);
      final map = res as Map<String, dynamic>;
      if (map['status'] == true && map['data'] != null) {
        setState(() {
          _booking = ProviderBookingModel.fromJson(
              map['data'] as Map<String, dynamic>);
        });
      } else {
        setState(() => _error = map['message'] as String? ?? 'Failed to load.');
      }
    } catch (_) {
      setState(() => _error = 'Failed to load booking details.');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(String status) async {
    setState(() => _actionLoading = true);
    try {
      final res = await _api.updateProviderBookingStatus(
          widget.bookingId, {'status': status});
      final map = res as Map<String, dynamic>;
      if (map['status'] == true) {
        _didChangeStatus = true;
        FunctionalComponent.showSnackBar(
          context: context,
          title: map['message'] as String? ?? 'Status updated.',
          success: true,
        );
        await _fetch();
      } else {
        FunctionalComponent.showSnackBar(
          context: context,
          title: map['message'] as String? ?? 'Failed to update.',
          success: false,
        );
      }
    } catch (_) {
      FunctionalComponent.showSnackBar(
        context: context,
        title: 'Something went wrong.',
        success: false,
      );
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _cancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmDialog(
        title: 'Decline Booking',
        message: 'Are you sure you want to decline this booking?',
        confirmLabel: 'Decline',
        confirmColor: const Color(0xFFEF4444),
      ),
    );
    if (confirmed != true) return;

    setState(() => _actionLoading = true);
    try {
      final res = await _api.cancelProviderBooking(widget.bookingId);
      final map = res as Map<String, dynamic>;
      FunctionalComponent.showSnackBar(
        context: context,
        title: map['message'] as String? ?? 'Booking cancelled.',
        success: map['status'] == true,
      );
      if (map['status'] == true) {
        _didChangeStatus = true;
        await _fetch();
      }
    } catch (_) {
      FunctionalComponent.showSnackBar(
        context: context,
        title: 'Something went wrong.',
        success: false,
      );
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _openChat() async {
    if (_chatLoading) return;
    final customerId = _booking?.customer.id ?? 0;
    if (customerId <= 0) {
      FunctionalComponent.showSnackBar(
        context: context,
        title: 'Customer id is missing in booking details.',
        success: false,
      );
      return;
    }

    setState(() => _chatLoading = true);
    try {
      final conv = await getIt<ProviderMessagingProvider>().createOrGetConversation(
        customerId: customerId,
        bookingId: widget.bookingId,
      );
      if (!mounted) return;
      if (conv == null) {
        FunctionalComponent.showSnackBar(
          context: context,
          title: 'Could not open chat. Please try again.',
          success: false,
        );
        return;
      }
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: getIt<ProviderMessagingProvider>(),
          child: ProviderChatScreen(
            conversation: conv,
            customerName: _booking?.customer.displayName,
          ),
        ),
      ));
    } catch (e) {
      if (!mounted) return;
      FunctionalComponent.showSnackBar(
        context: context,
        title: 'Could not open chat: ${e.toString().replaceFirst('Exception: ', '')}',
        success: false,
      );
    } finally {
      if (mounted) setState(() => _chatLoading = false);
    }
  }

  Future<void> _callCustomer() async {
    final phone = _booking?.customer.mobile?.trim() ?? '';
    if (phone.isEmpty) {
      FunctionalComponent.showSnackBar(
        context: context,
        title: 'Customer phone number is not available.',
        success: false,
      );
      return;
    }

    final uri = Uri(scheme: 'tel', path: phone);
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && mounted) {
      FunctionalComponent.showSnackBar(
        context: context,
        title: 'Could not open the phone app.',
        success: false,
      );
    }
  }

  void _showStatusChanger() {
    final current = _booking?.status ?? '';
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _StatusPickerSheet(
        currentStatus: current,
        onSelect: (s) {
          Navigator.pop(context);
          _updateStatus(s);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F7),
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 18, color: AppColor.darkGrey),
            onPressed: () => Navigator.of(context).pop(_didChangeStatus),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error.isNotEmpty || _booking == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F7),
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 18, color: AppColor.darkGrey),
            onPressed: () => Navigator.of(context).pop(_didChangeStatus),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: AppColor.grey),
              const SizedBox(height: 12),
              AppText(_error, fontSize: FontSizes.regular, color: AppColor.grey),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _fetch, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final booking = _booking!;
    final isPending = booking.status.toLowerCase() == 'pending';
    final isConfirmed = booking.status.toLowerCase() == 'confirmed';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: AppColor.darkGrey),
          onPressed: () => Navigator.of(context).pop(_didChangeStatus),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              isPending
                  ? 'Booking Request'
                  : booking.services.isNotEmpty
                      ? booking.services.first.serviceName
                      : 'Booking Detail',
              fontSize: 17,
              fontWeight: FontWeights.bold,
              color: AppColor.darkGrey,
            ),
            if (isPending)
              AppText(
                'Respond within 12 hours',
                fontSize: 11,
                color: AppColor.grey,
              ),
          ],
        ),
        titleSpacing: 0,
        actions: [
          // Status changer
          if (!isPending && booking.status.toLowerCase() != 'cancelled' &&
              booking.status.toLowerCase() != 'completed')
            IconButton(
              icon: const Icon(Icons.more_vert_rounded,
                  color: AppColor.darkGrey, size: 22),
              onPressed: _showStatusChanger,
            ),
          // Category pill (if confirmed)
          if (!isPending && booking.services.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AppColor.authButton,
                borderRadius: BorderRadius.circular(20),
              ),
              child: AppText(
                booking.services.first.serviceName.split(' ').first,
                fontSize: 11,
                fontWeight: FontWeights.semiBold,
                color: Colors.white,
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Customer card ──────────────────────────────────────────
            if (isPending)
              _CustomerCardSimple(customer: booking.customer)
            else
              _CustomerCardWithActions(
                customer: booking.customer,
                onCall: _callCustomer,
                onMessage: _openChat,
                canCall: booking.customer.mobile?.trim().isNotEmpty == true,
                chatLoading: _chatLoading,
              ),

            const SizedBox(height: 12),

            // ── Service / Appointment Details ──────────────────────────
            _DetailsCard(booking: booking, isPending: isPending),

            const SizedBox(height: 12),

            // ── Payment ────────────────────────────────────────────────
            _PaymentCard(booking: booking, isConfirmed: isConfirmed),

            const SizedBox(height: 100),
          ],
        ),
      ),

      // ── Bottom action buttons ───────────────────────────────────────
      bottomNavigationBar: _actionLoading
          ? Container(
              height: 100,
              color: Colors.white,
              child: const Center(child: CircularProgressIndicator()),
            )
          : _buildBottomActions(booking, isPending, isConfirmed),
    );
  }

  Widget _buildBottomActions(
      ProviderBookingModel booking, bool isPending, bool isConfirmed) {
    final isCancelled = booking.status.toLowerCase() == 'cancelled';
    final isCompleted = booking.status.toLowerCase() == 'completed';
    final isProcessing = booking.status.toLowerCase() == 'processing';

    if (isCancelled || isCompleted) {
      return Container(
        padding: EdgeInsets.fromLTRB(
            20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
        color: Colors.white,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: isCancelled
                ? const Color(0xFFFEE2E2)
                : const Color(0xFFD1FAE5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: AppText(
              isCancelled ? 'Booking Cancelled' : 'Service Completed',
              fontSize: FontSizes.regular,
              fontWeight: FontWeights.semiBold,
              color: isCancelled
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF10B981),
            ),
          ),
        ),
      );
    }

    final bottomPad = MediaQuery.of(context).padding.bottom + 12;

    if (isPending) {
      return Container(
        color: Colors.white,
        padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPad),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.authButton,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => _updateStatus('Confirmed'),
                child: AppText(
                  'Accept Booking',
                  fontSize: FontSizes.regular,
                  fontWeight: FontWeights.semiBold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                  side: const BorderSide(color: Color(0xFFEF4444)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _cancel,
                child: AppText(
                  'Decline',
                  fontSize: FontSizes.regular,
                  fontWeight: FontWeights.semiBold,
                  color: const Color(0xFFEF4444),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (isConfirmed) {
      return Container(
        color: Colors.white,
        padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPad),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.authButton,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () => _updateStatus('Completed'),
            child: AppText(
              'Mark as Completed',
              fontSize: FontSizes.regular,
              fontWeight: FontWeights.semiBold,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    if (isProcessing) {
      return Container(
        color: Colors.white,
        padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPad),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () => _updateStatus('Completed'),
            child: AppText(
              'Mark as Completed',
              fontSize: FontSizes.regular,
              fontWeight: FontWeights.semiBold,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

// ─── Customer card (Pending) ───────────────────────────────────────────────────

class _CustomerCardSimple extends StatelessWidget {
  final ProviderBookingCustomer customer;
  const _CustomerCardSimple({required this.customer});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _Avatar(name: customer.displayName, photoUrl: customer.profileImage),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  customer.displayName,
                  fontSize: FontSizes.regular,
                  fontWeight: FontWeights.semiBold,
                  color: AppColor.darkGrey,
                ),
                const SizedBox(height: 2),
                AppText(
                  customer.email ?? customer.name,
                  fontSize: 12,
                  color: AppColor.grey,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Customer card (Confirmed) — with Call/Message ────────────────────────────

class _CustomerCardWithActions extends StatelessWidget {
  final ProviderBookingCustomer customer;
  final VoidCallback onCall;
  final VoidCallback onMessage;
  final bool canCall;
  final bool chatLoading;

  const _CustomerCardWithActions({
    required this.customer,
    required this.onCall,
    required this.onMessage,
    this.canCall = true,
    this.chatLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final canMessage = !chatLoading;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColor.authButton.withValues(alpha: 0.3),
          style: BorderStyle.solid,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _Avatar(
                    name: customer.displayName,
                    photoUrl: customer.profileImage),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        customer.displayName,
                        fontSize: FontSizes.regular,
                        fontWeight: FontWeights.semiBold,
                        color: AppColor.darkGrey,
                      ),
                      const SizedBox(height: 2),
                      AppText(
                        customer.mobile?.isNotEmpty == true
                            ? customer.mobile!
                            : customer.email ?? '',
                        fontSize: 12,
                        color: AppColor.grey,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          Row(
            children: [
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: canCall ? onCall : null,
                    child: Opacity(
                      opacity: canCall ? 1 : 0.45,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.phone_rounded,
                                size: 15, color: AppColor.authButton),
                            const SizedBox(width: 6),
                            AppText(
                              'Call',
                              fontSize: FontSizes.regular,
                              fontWeight: FontWeights.semiBold,
                              color: AppColor.authButton,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Container(width: 1, height: 40, color: const Color(0xFFF3F4F6)),
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: canMessage ? onMessage : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      child: chatLoading
                          ? const Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColor.authButton,
                                ),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.chat_bubble_outline_rounded,
                                    size: 15, color: AppColor.authButton),
                                const SizedBox(width: 6),
                                AppText(
                                  'Message',
                                  fontSize: FontSizes.regular,
                                  fontWeight: FontWeights.semiBold,
                                  color: AppColor.authButton,
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Details Card ──────────────────────────────────────────────────────────────

class _DetailsCard extends StatelessWidget {
  final ProviderBookingModel booking;
  final bool isPending;

  const _DetailsCard({required this.booking, required this.isPending});

  @override
  Widget build(BuildContext context) {
    final addr = booking.address;
    final totalDuration = booking.services.fold(0, (s, e) => s + e.duration);
    final durationStr = totalDuration > 0
        ? totalDuration < 60
            ? '$totalDuration minutes'
            : '${totalDuration ~/ 60}hr ${totalDuration % 60 > 0 ? '${totalDuration % 60}min' : ''}'
        : '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.authButton.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppColor.authButton.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppText(
                isPending ? 'Service Details' : 'Appointment Details',
                fontSize: FontSizes.medium,
                fontWeight: FontWeights.bold,
                color: AppColor.darkGrey,
              ),
              const Spacer(),
              if (isPending && booking.services.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColor.authButton,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: AppText(
                    booking.services.first.serviceName.split(' ').first,
                    fontSize: 10,
                    fontWeight: FontWeights.semiBold,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Service name (for pending)
          if (isPending && booking.services.isNotEmpty) ...[
            AppText(
              booking.services.map((s) => s.serviceName).join(', '),
              fontSize: FontSizes.medium,
              fontWeight: FontWeights.semiBold,
              color: AppColor.darkGrey,
            ),
            const SizedBox(height: 10),
          ],

          // Date
          _DetailRow(
            icon: Icons.calendar_today_rounded,
            child: AppText(
              booking.formattedDate,
              fontSize: FontSizes.regular,
              color: AppColor.darkGrey,
            ),
          ),
          const SizedBox(height: 10),

          // Time + duration
          _DetailRow(
            icon: Icons.access_time_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  booking.formattedTime,
                  fontSize: FontSizes.regular,
                  color: AppColor.darkGrey,
                ),
                if (durationStr.isNotEmpty)
                  AppText(durationStr, fontSize: 12, color: AppColor.grey),
              ],
            ),
          ),

          // Address
          if (addr != null && addr.fullAddress.isNotEmpty) ...[
            const SizedBox(height: 10),
            _DetailRow(
              icon: Icons.location_on_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    addr.streetAddress ?? addr.addressName ?? '',
                    fontSize: FontSizes.regular,
                    color: AppColor.darkGrey,
                  ),
                  if (addr.cityLine.isNotEmpty)
                    AppText(addr.cityLine, fontSize: 12, color: AppColor.grey),
                  if (!isPending) ...[
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () async {
                        final q = Uri.encodeComponent(addr.fullAddress);
                        final uri = Uri.parse(
                            'https://www.google.com/maps/search/?api=1&query=$q');
                        if (await canLaunchUrl(uri)) launchUrl(uri);
                      },
                      child: Row(
                        children: [
                          AppText(
                            'Get Directions',
                            fontSize: 12,
                            fontWeight: FontWeights.semiBold,
                            color: AppColor.authButton,
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.arrow_forward_rounded,
                              size: 12, color: AppColor.authButton),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final Widget child;

  const _DetailRow({required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 16, color: AppColor.authButton),
        ),
        const SizedBox(width: 10),
        Expanded(child: child),
      ],
    );
  }
}

// ─── Payment Card ──────────────────────────────────────────────────────────────

class _PaymentCard extends StatelessWidget {
  final ProviderBookingModel booking;
  final bool isConfirmed;

  const _PaymentCard({required this.booking, required this.isConfirmed});

  String _fmt(String v) {
    final d = double.tryParse(v) ?? 0;
    return d == d.truncateToDouble() ? '\$${d.toInt()}' : '\$${d.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final deposit = double.tryParse(booking.depositAmount) ?? 0;
    final balance = double.tryParse(booking.balanceAmount) ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            'Payment',
            fontSize: FontSizes.medium,
            fontWeight: FontWeights.bold,
            color: AppColor.darkGrey,
          ),
          const SizedBox(height: 12),

          // Deposit pill
          if (deposit > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColor.authButton.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded,
                      size: 16, color: AppColor.authButton),
                  const SizedBox(width: 8),
                  AppText(
                    isConfirmed
                        ? 'Deposit Paid: ${_fmt(booking.depositAmount)}'
                        : 'Deposit Collected: ${_fmt(booking.depositAmount)}',
                    fontSize: FontSizes.regular,
                    fontWeight: FontWeights.semiBold,
                    color: AppColor.authButton,
                  ),
                ],
              ),
            ),

          const SizedBox(height: 14),
          _PayRow(label: 'Total Amount', value: _fmt(booking.price)),
          const SizedBox(height: 8),
          if (balance > 0) ...[
            const Divider(color: Color(0xFFF3F4F6)),
            const SizedBox(height: 8),
            _PayRow(
              label: 'Remaining Balance',
              value: _fmt(booking.balanceAmount),
              highlight: true,
            ),
            if (isConfirmed) ...[
              const SizedBox(height: 4),
              AppText(
                'Charged automatically when you mark service complete',
                fontSize: 11,
                color: AppColor.grey,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _PayRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _PayRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText(label, fontSize: FontSizes.regular, color: AppColor.grey),
        AppText(
          value,
          fontSize: FontSizes.regular,
          fontWeight: highlight ? FontWeights.bold : FontWeights.semiBold,
          color: highlight ? AppColor.authButton : AppColor.darkGrey,
        ),
      ],
    );
  }
}

// ─── Status Picker Sheet ───────────────────────────────────────────────────────

class _StatusPickerSheet extends StatelessWidget {
  final String currentStatus;
  final ValueChanged<String> onSelect;

  const _StatusPickerSheet({
    required this.currentStatus,
    required this.onSelect,
  });

  static const _options = [
    _StatusOption('Confirmed', Color(0xFF3B82F6), Color(0xFFEFF6FF)),
    _StatusOption('Processing', Color(0xFFF59E0B), Color(0xFFFEF3C7)),
    _StatusOption('Completed', Color(0xFF10B981), Color(0xFFD1FAE5)),
    _StatusOption('Cancelled', Color(0xFFEF4444), Color(0xFFFEE2E2)),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColor.mediumGrey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          AppText(
            'Change Booking Status',
            fontSize: FontSizes.medium,
            fontWeight: FontWeights.bold,
            color: AppColor.darkGrey,
          ),
          const SizedBox(height: 16),
          ..._options.map((opt) {
            final isCurrent = currentStatus.toLowerCase() == opt.label.toLowerCase();
            return GestureDetector(
              onTap: isCurrent ? null : () => onSelect(opt.label),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isCurrent ? opt.bg : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCurrent ? opt.color : const Color(0xFFF3F4F6),
                    width: isCurrent ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: opt.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppText(
                        opt.label,
                        fontSize: FontSizes.regular,
                        fontWeight: FontWeights.semiBold,
                        color: opt.color,
                      ),
                    ),
                    if (isCurrent)
                      const Icon(Icons.check_rounded, size: 18,
                          color: AppColor.authButton),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _StatusOption {
  final String label;
  final Color color;
  final Color bg;
  const _StatusOption(this.label, this.color, this.bg);
}

// ─── Confirm Dialog ────────────────────────────────────────────────────────────

class _ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final Color confirmColor;

  const _ConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.confirmColor,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: AppText(title,
          fontSize: FontSizes.medium, fontWeight: FontWeights.bold,
          color: AppColor.darkGrey),
      content: AppText(message,
          fontSize: FontSizes.regular, color: AppColor.grey, maxLines: 3),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: AppText('Cancel',
              fontSize: FontSizes.regular, color: AppColor.grey),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: AppText(confirmLabel,
              fontSize: FontSizes.regular,
              fontWeight: FontWeights.semiBold,
              color: confirmColor),
        ),
      ],
    );
  }
}

// ─── Avatar ────────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final double size;

  const _Avatar({required this.name, this.photoUrl, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return ClipOval(
        child: SizedBox(
          width: size,
          height: size,
          child: FunctionalComponent.cachedNetworkImage(
            photoUrl!,
            fit: BoxFit.cover,
            radius: size / 2,
          ),
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColor.authButton.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: size * 0.36,
          fontWeight: FontWeight.w700,
          color: AppColor.authButton,
        ),
      ),
    );
  }
}
