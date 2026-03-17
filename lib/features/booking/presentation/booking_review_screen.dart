import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:pampa/core/utils/functional_component.dart';
import 'package:pampa/core/values/app_text_value.dart';
import 'package:pampa/core/values/colors.dart';
import 'package:pampa/core/widgets/text_widget.dart';
import 'package:pampa/features/address/data/models/address_model.dart';
import 'package:pampa/features/booking/presentation/provider/booking_provider.dart';
import 'package:pampa/features/webview/webview.dart';

class BookingReviewScreen extends StatelessWidget {
  final AddressModel address;

  const BookingReviewScreen({super.key, required this.address});

  Future<void> _onPay(BuildContext context) async {
    final provider = context.read<BookingProvider>();

    final url = await provider.createCheckoutSessionUrl(
      addressId: address.id,
      providerId: provider.selectedProvider!.id,
    );

    if (!context.mounted) return;

    if (url == null) {
      FunctionalComponent.showSnackBar(
        context: context,
        title: provider.submitError,
        success: false,
      );
      provider.resetSubmit();
      return;
    }

    final paymentSuccess = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CustomWebView(checkoutUrl: url, title: 'Checkout'),
      ),
    );

    if (!context.mounted) return;
    if (paymentSuccess == true) {
      // Pop back to home / booking list
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: AppColor.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColor.darkGrey, size: 20),
          ),
        ),
        centerTitle: true,
        title: AppText('Review Booking',
            fontSize: FontSizes.medium,
            fontWeight: FontWeights.bold,
            color: AppColor.darkGrey),
      ),
      body: Consumer<BookingProvider>(
        builder: (context, bp, _) {
          final service = bp.service!;
          final provider = bp.selectedProvider!;
          final tip = bp.tipAmount;
          final depositAmt = service.deposit;
          final fullPrice = service.priceAsDouble;
          final hasDeposit = depositAmt > 0;
          final chargedToday = (hasDeposit ? depositAmt : fullPrice) + tip;
          final balanceDue = hasDeposit ? fullPrice - depositAmt : 0.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Confirmation banner ──────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColor.authButton.withValues(alpha: 0.12),
                        AppColor.authButton.withValues(alpha: 0.04),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColor.authButton.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: const BoxDecoration(
                          color: AppColor.authButton,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.receipt_long_rounded,
                            color: AppColor.white, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText('Almost done!',
                                fontSize: FontSizes.regular,
                                fontWeight: FontWeights.bold,
                                color: AppColor.authButton),
                            const SizedBox(height: 2),
                            AppText('Review your booking details before payment.',
                                fontSize: 12,
                                color: AppColor.authButton),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Service ──────────────────────────────────────────────────
                _SectionCard(
                  icon: Icons.spa_rounded,
                  title: 'Service',
                  children: [
                    _DetailRow(
                      label: service.serviceName,
                      value: '\$${fullPrice % 1 == 0 ? fullPrice.toInt() : fullPrice.toStringAsFixed(2)}',
                      valueBold: true,
                    ),
                    if (service.category != null)
                      _DetailRow(
                        label: 'Category',
                        value: service.category!.categoryName,
                      ),
                    _DetailRow(
                      label: 'Duration',
                      value: service.formattedDuration,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ── Provider ─────────────────────────────────────────────────
                _SectionCard(
                  icon: Icons.person_rounded,
                  title: 'Provider',
                  children: [
                    _DetailRow(
                      label: 'Name',
                      value: provider.displayName,
                      valueBold: true,
                    ),
                    _DetailRow(
                      label: 'Location',
                      value: provider.displayLocation,
                    ),
                    _DetailRow(
                      label: 'Rating',
                      value: '${provider.rating.toStringAsFixed(1)} ★',
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ── Appointment ──────────────────────────────────────────────
                _SectionCard(
                  icon: Icons.calendar_today_rounded,
                  title: 'Appointment',
                  children: [
                    _DetailRow(
                      label: 'Date',
                      value: DateFormat('EEEE, MMMM d, yyyy')
                          .format(bp.selectedDate),
                      valueBold: true,
                    ),
                    _DetailRow(
                      label: 'Time',
                      value: bp.selectedTime ?? '-',
                      valueBold: true,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ── Address ──────────────────────────────────────────────────
                _SectionCard(
                  icon: Icons.location_on_rounded,
                  title: 'Service Address',
                  children: [
                    _DetailRow(
                      label: 'Address',
                      value: address.addressName,
                      valueBold: true,
                    ),
                    _DetailRow(
                      label: 'Street',
                      value: address.streetAddress,
                    ),
                    _DetailRow(
                      label: 'City',
                      value:
                          '${address.city}, ${address.zipCode}',
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ── Payment summary ──────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColor.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: AppColor.authBg,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.payments_rounded,
                                color: AppColor.authButton, size: 16),
                          ),
                          const SizedBox(width: 10),
                          AppText('Payment Summary',
                              fontSize: FontSizes.regular,
                              fontWeight: FontWeights.bold,
                              color: AppColor.darkGrey),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Divider(color: Color(0xFFF0F0F0), height: 1),
                      const SizedBox(height: 12),

                      // Service price
                      _PayRow(
                        label: 'Service Price',
                        value: _fmt(fullPrice),
                      ),

                      // Deposit
                      if (hasDeposit) ...[
                        const SizedBox(height: 8),
                        _PayRow(
                          label: 'Deposit (paid today)',
                          value: _fmt(depositAmt),
                          highlight: true,
                        ),
                        const SizedBox(height: 8),
                        _PayRow(
                          label: 'Balance due after service',
                          value: _fmt(balanceDue),
                          muted: true,
                        ),
                      ],

                      // Tip
                      if (tip > 0) ...[
                        const SizedBox(height: 8),
                        _PayRow(
                          label: 'Tip for provider',
                          value: _fmt(tip),
                        ),
                      ],

                      const SizedBox(height: 12),
                      const Divider(color: Color(0xFFF0F0F0), height: 1),
                      const SizedBox(height: 12),

                      // Total today
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AppText(
                            'Charged today',
                            fontSize: FontSizes.regular,
                            fontWeight: FontWeights.bold,
                            color: AppColor.darkGrey,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColor.authButton,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: AppText(
                              _fmt(chargedToday),
                              fontSize: FontSizes.regular,
                              fontWeight: FontWeights.bold,
                              color: AppColor.white,
                            ),
                          ),
                        ],
                      ),

                      if (hasDeposit) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline_rounded,
                                  size: 14, color: Color(0xFFD97706)),
                              const SizedBox(width: 7),
                              Expanded(
                                child: AppText(
                                  'Remaining balance of ${_fmt(balanceDue)} is due after your service is completed.',
                                  fontSize: 11,
                                  color: const Color(0xFF92400E),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Stripe note ──────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_outline_rounded,
                        size: 13, color: AppColor.grey),
                    const SizedBox(width: 5),
                    AppText('Secured by Stripe',
                        fontSize: 12, color: AppColor.grey),
                  ],
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Consumer<BookingProvider>(
        builder: (context, bp, _) {
          final service = bp.service!;
          final depositAmt = service.deposit;
          final fullPrice = service.priceAsDouble;
          final hasDeposit = depositAmt > 0;
          final chargedToday =
              (hasDeposit ? depositAmt : fullPrice) + bp.tipAmount;

          return Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: BoxDecoration(
              color: AppColor.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 52,
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.authButton,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: bp.isSubmitting ? null : () => _onPay(context),
                  child: bp.isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: AppColor.white, strokeWidth: 2.5),
                        )
                      : AppText(
                          hasDeposit
                              ? 'Pay Deposit  ${_fmt(chargedToday)}'
                              : 'Pay Now  ${_fmt(chargedToday)}',
                          fontSize: FontSizes.regular,
                          fontWeight: FontWeights.semiBold,
                          color: AppColor.white,
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static String _fmt(double v) =>
      '\$${v % 1 == 0 ? v.toInt() : v.toStringAsFixed(2)}';
}

// ─── Section card ─────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppColor.authBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColor.authButton, size: 16),
              ),
              const SizedBox(width: 10),
              AppText(title,
                  fontSize: FontSizes.regular,
                  fontWeight: FontWeights.bold,
                  color: AppColor.darkGrey),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFFF0F0F0), height: 1),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

// ─── Detail row ───────────────────────────────────────────────────────────────
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool valueBold;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: AppText(label,
                fontSize: 12, color: AppColor.grey),
          ),
          Expanded(
            child: AppText(
              value,
              fontSize: 13,
              fontWeight: valueBold ? FontWeights.semiBold : FontWeights.regular,
              color: AppColor.darkGrey,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Payment row ──────────────────────────────────────────────────────────────
class _PayRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  final bool muted;

  const _PayRow({
    required this.label,
    required this.value,
    this.highlight = false,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText(
          label,
          fontSize: 13,
          color: muted ? AppColor.grey : AppColor.darkGrey,
        ),
        AppText(
          value,
          fontSize: 13,
          fontWeight: highlight ? FontWeights.semiBold : FontWeights.regular,
          color: highlight ? AppColor.authButton : AppColor.darkGrey,
        ),
      ],
    );
  }
}
