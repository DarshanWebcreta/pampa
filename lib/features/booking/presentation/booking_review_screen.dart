import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:pampa/core/utils/functional_component.dart';
import 'package:pampa/core/values/app_text_value.dart';
import 'package:pampa/core/values/colors.dart';
import 'package:pampa/core/widgets/text_widget.dart';
import 'package:pampa/features/address/data/models/address_model.dart';
import 'package:pampa/features/booking/data/models/provider_model.dart';
import 'package:pampa/features/booking/presentation/provider/booking_provider.dart';
import 'package:pampa/features/home/presentation/home_screen.dart';
import 'package:pampa/features/my_bookings/presentation/provider/my_bookings_provider.dart';
import 'package:pampa/features/webview/webview.dart';

class BookingReviewScreen extends StatefulWidget {
  final AddressModel address;
  final List<int> serviceIds;

  const BookingReviewScreen({
    super.key,
    required this.address,
    this.serviceIds = const [],
  });

  @override
  State<BookingReviewScreen> createState() => _BookingReviewScreenState();
}

class _BookingReviewScreenState extends State<BookingReviewScreen> {
  final _notesController = TextEditingController();
  final _pinterestController = TextEditingController();
  final _picker = ImagePicker();
  XFile? _pickedPhoto;

  @override
  void dispose() {
    _notesController.dispose();
    _pinterestController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (!mounted || image == null) return;
    setState(() => _pickedPhoto = image);
  }

  Future<void> _submit(BuildContext context) async {
    final bookingProvider = context.read<BookingProvider>();
    final service = bookingProvider.service;

    final selectedProvider = bookingProvider.selectedProvider;
    final appointmentTime = bookingProvider.selectedTime;
    if (service == null || selectedProvider == null || appointmentTime == null) {
      return;
    }

    final pinterestLink = _pinterestController.text.trim();
    if (pinterestLink.isNotEmpty) {
      final uri = Uri.tryParse(pinterestLink);
      if (uri == null || (!uri.hasScheme || !uri.hasAuthority)) {
        FunctionalComponent.showSnackBar(
          context: context,
          title: 'Please enter a valid Pinterest link.',
          success: false,
        );
        return;
      }
    }

    final ids = bookingProvider.selectedServiceIds.isNotEmpty
        ? bookingProvider.selectedServiceIds
        : (widget.serviceIds.isNotEmpty ? widget.serviceIds : [service.id]);
    print(ids);
    final success = await bookingProvider.submitBookingDetails(
      serviceIds: ids,
      providerId: selectedProvider.id,
      addressId: widget.address.id,
      appointmentTime: appointmentTime,
      notes: _notesController.text,
      pinterestLink: pinterestLink,
      inspirationPhotoPath: _pickedPhoto?.path,
    );

    if (!context.mounted) return;

    if (!success) {
      FunctionalComponent.showSnackBar(
        context: context,
        title: bookingProvider.submitError,
        success: false,
      );
      bookingProvider.resetSubmit();
      return;
    }

    final paymentLink = bookingProvider.paymentLink;

    if (paymentLink != null && paymentLink.isNotEmpty) {
      // Open Stripe checkout in webview
      final paid = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => CustomWebView(
            checkoutUrl: paymentLink,
            title: 'Complete Payment',
          ),
        ),
      );

      if (!context.mounted) return;

      if (paid != true) {
        // User cancelled — stay on the review screen
        FunctionalComponent.showSnackBar(
          context: context,
          title: 'Payment cancelled. Your booking is pending.',
          success: false,
        );
        bookingProvider.resetSubmit();
        return;
      }
    }

    // Payment done (or no payment link) — go to appointments tab
    await context.read<MyBookingsProvider>().fetchBookings();
    if (!context.mounted) return;
    homeTabNotifier.value = 2;
    homeSuccessMessageNotifier.value =
        bookingProvider.successMessage.isEmpty
            ? 'Booking created successfully!'
            : bookingProvider.successMessage;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.authBg,
      appBar: AppBar(
        backgroundColor: AppColor.authBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 90,
        leading: TextButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 14,
            color: AppColor.darkGrey,
          ),
          label: AppText(
            'Back',
            fontSize: FontSizes.small,
            color: AppColor.darkGrey,
          ),
        ),
      ),
      body: Consumer<BookingProvider>(
        builder: (context, bookingProvider, _) {
          final service = bookingProvider.service!;
          final provider = bookingProvider.selectedProvider!;
          final ids = bookingProvider.selectedServiceIds.isNotEmpty
              ? bookingProvider.selectedServiceIds
              : (widget.serviceIds.isNotEmpty ? widget.serviceIds : [service.id]);
          final selectedServices = ids
              .map((id) => provider.serviceFor(id))
              .whereType<ProviderServiceSummaryModel>()
              .toList();
          final providerService = provider.serviceFor(service.id);
          final fullPrice = selectedServices.isNotEmpty
              ? selectedServices.fold(0.0, (sum, s) => sum + s.priceAsDouble)
              : (providerService?.priceAsDouble ?? service.priceAsDouble);
          final duration = selectedServices.isNotEmpty
              ? selectedServices.fold(0, (sum, s) => sum + s.duration)
              : (providerService?.duration ?? service.duration);
          final depositAmount = selectedServices.isNotEmpty
              ? selectedServices.fold(0.0, (sum, s) => sum + s.deposit)
              : (providerService != null && providerService.deposit > 0
                  ? providerService.deposit
                  : service.deposit);
          final priorityFee = service.priorityFee;
          final tip = bookingProvider.tipAmount;
          final todayDue =
              (depositAmount > 0 ? depositAmount : fullPrice) + priorityFee + tip;
          final remainingBalance =
              depositAmount > 0 ? fullPrice - depositAmount : 0.0;
          print(selectedServices.length);
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  'Where Should We Come?',
                  fontSize: 34,
                  fontWeight: FontWeights.bold,
                  color: AppColor.darkGrey,
                  maxLines: 2,
                ),
                const SizedBox(height: 6),
                AppText(
                  'Add your service location and any special details',
                  fontSize: FontSizes.regular,
                  color: AppColor.grey,
                  maxLines: 2,
                ),
                const SizedBox(height: 20),
                _ProviderSummaryCard(
                  providerName: provider.displayName,
                  services: selectedServices.isNotEmpty
                      ? selectedServices
                      : (providerService != null ? [providerService] : []),
                  fallbackServiceName: service.serviceName,
                  providerPhoto: provider.photoUrl,
                  date: bookingProvider.selectedDate,
                  time: bookingProvider.selectedTime ?? '',
                  duration: int.parse(duration.toString()),
                ),
                const SizedBox(height: 18),
                _SectionLabel('Service Address'),
                const SizedBox(height: 8),
                _ReadOnlyField(
                  value: _formatFullAddress(widget.address),
                ),
                const SizedBox(height: 6),
                AppText(
                  provider.displayLocation,
                  fontSize: 12,
                  color: AppColor.grey,
                  maxLines: 2,
                ),
                const SizedBox(height: 18),
                _SectionLabel('Notes (Optional)'),
                const SizedBox(height: 8),
                _InputField(
                  controller: _notesController,
                  hintText: 'Any special requests or details...',
                  maxLines: 5,
                ),
                const SizedBox(height: 18),
                _SectionLabel('Pinterest Link (Optional)'),
                const SizedBox(height: 8),
                _InputField(
                  controller: _pinterestController,
                  hintText: 'https://pinterest.com/pin/...',
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 6),
                AppText(
                  'Share inspiration from Pinterest',
                  fontSize: 12,
                  color: AppColor.grey,
                ),
                const SizedBox(height: 18),
                _SectionLabel('Inspiration Photo (Optional)'),
                const SizedBox(height: 8),
                _ImageUploadBox(
                  pickedPhoto: _pickedPhoto,
                  onTap: _pickImage,
                  onRemove: _pickedPhoto == null
                      ? null
                      : () => setState(() => _pickedPhoto = null),
                ),
                const SizedBox(height: 18),
                _PricingBreakdownCard(
                  selectedServices: selectedServices,
                  servicePrice: fullPrice,
                  depositAmount: depositAmount,
                  priorityFee: priorityFee,
                  tipAmount: tip,
                  amountDueToday: todayDue,
                  remainingBalance: remainingBalance,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.authButton,
                      foregroundColor: AppColor.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: bookingProvider.isSubmitting
                        ? null
                        : () => _submit(context),
                    child: bookingProvider.isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: AppColor.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : AppText(
                            'Submit Booking',
                            color: AppColor.white,
                            fontWeight: FontWeights.semiBold,
                            fontSize: FontSizes.regular,
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static String _formatFullAddress(AddressModel address) {
    final parts = [
      address.streetAddress,
      address.city,
      address.state,
      address.zipCode,
    ].where((part) => part != null && part.trim().isNotEmpty);
    return parts.join(', ');
  }
}

class _ProviderSummaryCard extends StatelessWidget {
  final String providerName;
  final List<ProviderServiceSummaryModel> services;
  final String fallbackServiceName;
  final String? providerPhoto;
  final DateTime date;
  final String time;
  final int duration;

  const _ProviderSummaryCard({
    required this.providerName,
    required this.services,
    required this.fallbackServiceName,
    required this.providerPhoto,
    required this.date,
    required this.time,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    final serviceLabel = services.isEmpty
        ? fallbackServiceName
        : services.map((s) => s.serviceName).join(', ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColor.authButton.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _ProviderAvatar(
                photoUrl: providerPhoto,
                fallbackText: providerName,
                size: 46,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      providerName,
                      fontSize: 13,
                      fontWeight: FontWeights.bold,
                      color: AppColor.darkGrey,
                    ),
                    const SizedBox(height: 2),
                    AppText(
                      serviceLabel,
                      fontSize: 12,
                      color: AppColor.grey,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _MetaRow(
            label: 'Date',
            value: DateFormat('M/d/yyyy').format(date),
          ),
          const SizedBox(height: 10),
          _MetaRow(
            label: 'Time',
            value: _formatTime(time),
          ),
          const SizedBox(height: 10),
          _MetaRow(
            label: 'Duration',
            value: '$duration min',
          ),
        ],
      ),
    );
  }

  static String _formatTime(String time) {
    if (time.isEmpty) return '-';
    try {
      return DateFormat('h:mm a')
          .format(DateFormat('HH:mm').parseStrict(time));
    } catch (_) {
      return time;
    }
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetaRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppText(
          label,
          fontSize: 12,
          color: AppColor.grey,
        ),
        const Spacer(),
        AppText(
          value,
          fontSize: 12,
          color: AppColor.darkGrey,
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return AppText(
      text,
      fontSize: 13,
      fontWeight: FontWeights.semiBold,
      color: AppColor.darkGrey,
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  final String value;

  const _ReadOnlyField({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColor.lightGrey),
      ),
      child: AppText(
        value,
        fontSize: 13,
        color: AppColor.grey,
        maxLines: 3,
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final int maxLines;
  final TextInputType? keyboardType;

  const _InputField({
    required this.controller,
    required this.hintText,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: AppColor.grey,
          fontSize: 13,
        ),
        filled: true,
        fillColor: AppColor.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColor.lightGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColor.lightGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColor.authButton),
        ),
      ),
    );
  }
}

class _ImageUploadBox extends StatelessWidget {
  final XFile? pickedPhoto;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const _ImageUploadBox({
    required this.pickedPhoto,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = pickedPhoto != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        width: double.infinity,
        height: hasPhoto ? 180 : 110,
        decoration: BoxDecoration(
          color: AppColor.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColor.mediumGrey,
            style: BorderStyle.solid,
          ),
        ),
        child: hasPhoto
            ? Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.file(
                        File(pickedPhoto!.path),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 10,
                    top: 10,
                    child: InkWell(
                      onTap: onRemove,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColor.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: AppColor.darkGrey,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.file_upload_outlined,
                    color: AppColor.grey,
                  ),
                  const SizedBox(height: 10),
                  AppText(
                    'Upload a reference photo',
                    fontSize: 13,
                    color: AppColor.grey,
                  ),
                ],
              ),
      ),
    );
  }
}

class _PricingBreakdownCard extends StatelessWidget {
  final List<ProviderServiceSummaryModel> selectedServices;
  final double servicePrice;
  final double depositAmount;
  final double priorityFee;
  final double tipAmount;
  final double amountDueToday;
  final double remainingBalance;

  const _PricingBreakdownCard({
    required this.selectedServices,
    required this.servicePrice,
    required this.depositAmount,
    required this.priorityFee,
    required this.tipAmount,
    required this.amountDueToday,
    required this.remainingBalance,
  });

  @override
  Widget build(BuildContext context) {
    final showIndividual = selectedServices.length > 1;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.authButton.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            'Pricing Breakdown',
            fontSize: FontSizes.regular,
            fontWeight: FontWeights.bold,
            color: AppColor.darkGrey,
          ),
          const SizedBox(height: 14),
          if (showIndividual) ...[
            // Individual service rows with per-service deposit
            ...selectedServices.expand((s) => [
              _PriceRow(
                label: s.serviceName,
                value: _fmt(s.priceAsDouble),
              ),
              if (s.deposit > 0) ...[
                const SizedBox(height: 4),
                _PriceRow(
                  label: '  Deposit',
                  value: _fmt(s.deposit),
                  secondary: true,
                ),
              ],
              const SizedBox(height: 10),
            ]),
            Divider(color: Colors.black.withValues(alpha: 0.06), height: 1),
            const SizedBox(height: 10),
            _PriceRow(label: 'Subtotal', value: _fmt(servicePrice)),
          ] else ...[
            _PriceRow(label: 'Service Price', value: _fmt(servicePrice)),
          ],
          if (depositAmount > 0) ...[
            const SizedBox(height: 10),
            _PriceRow(
              label: showIndividual ? 'Total Deposit Due Today' : 'Deposit Due Today',
              value: _fmt(depositAmount),
            ),
          ],
          if (priorityFee > 0) ...[
            const SizedBox(height: 10),
            _PriceRow(label: 'Priority Fee', value: _fmt(priorityFee)),
          ],
          if (tipAmount > 0) ...[
            const SizedBox(height: 10),
            _PriceRow(label: 'Tip', value: _fmt(tipAmount)),
          ],
          const SizedBox(height: 12),
          Divider(color: Colors.black.withValues(alpha: 0.08), height: 1),
          const SizedBox(height: 12),
          _PriceRow(
            label: 'Amount Due Today',
            value: _fmt(amountDueToday),
            highlight: true,
          ),
          if (remainingBalance > 0) ...[
            const SizedBox(height: 10),
            _PriceRow(
              label: 'Remaining Balance After Service',
              value: _fmt(remainingBalance),
            ),
          ],
        ],
      ),
    );
  }

  static String _fmt(double value) {
    if (value == value.truncateToDouble()) {
      return '\$${value.toInt()}.00';
    }
    return '\$${value.toStringAsFixed(2)}';
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  final bool secondary;

  const _PriceRow({
    required this.label,
    required this.value,
    this.highlight = false,
    this.secondary = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = highlight ? AppColor.authButton : AppColor.darkGrey;
    final weight = highlight ? FontWeights.bold : FontWeights.medium;
    final fontSize = secondary ? 12.0 : 13.0;
    final labelColor = secondary
        ? AppColor.grey.withValues(alpha: 0.7)
        : (highlight ? AppColor.authButton : AppColor.grey);
    final valueColor = secondary ? AppColor.grey : color;

    return Row(
      children: [
        Expanded(
          child: AppText(
            label,
            fontSize: fontSize,
            color: labelColor,
            maxLines: 2,
          ),
        ),
        AppText(
          value,
          fontSize: fontSize,
          color: valueColor,
          fontWeight: secondary ? FontWeights.regular : weight,
        ),
      ],
    );
  }
}

class _ProviderAvatar extends StatelessWidget {
  final String? photoUrl;
  final String fallbackText;
  final double size;

  const _ProviderAvatar({
    required this.photoUrl,
    required this.fallbackText,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final initials = fallbackText
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    if (photoUrl == null || photoUrl!.isEmpty) {
      return _AvatarFallback(initials: initials, size: size);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        photoUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _AvatarFallback(initials: initials, size: size),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  final String initials;
  final double size;

  const _AvatarFallback({
    required this.initials,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColor.authButton.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: AppText(
        initials.isEmpty ? '?' : initials,
        fontSize: 14,
        fontWeight: FontWeights.bold,
        color: AppColor.authButton,
      ),
    );
  }
}
