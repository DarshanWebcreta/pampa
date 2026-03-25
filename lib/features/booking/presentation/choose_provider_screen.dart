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

class ChooseProviderScreen extends StatefulWidget {
  final AddressModel address;

  const ChooseProviderScreen({super.key, required this.address});

  @override
  State<ChooseProviderScreen> createState() => _ChooseProviderScreenState();
}

class _ChooseProviderScreenState extends State<ChooseProviderScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingProvider>().fetchAvailableProviders(
            zipCode: widget.address.zipCode,
          );
    });
  }

  void _openReview(ProviderModel provider) {
    final bookingProvider = context.read<BookingProvider>();
    bookingProvider.selectProvider(provider);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: bookingProvider),
            ChangeNotifierProvider.value(value: context.read<AddressProvider>()),
          ],
          child: BookingReviewScreen(address: widget.address),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.authBg,
      appBar: AppBar(
        backgroundColor: AppColor.authBg,
        scrolledUnderElevation: 0,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColor.darkGrey),
        ),
        title: AppText(
          'Choose your provider',
          fontSize: FontSizes.large,
          fontWeight: FontWeights.bold,
          color: AppColor.darkGrey,
        ),
      ),
      body: Consumer<BookingProvider>(
        builder: (context, bookingProvider, _) {
          final service = bookingProvider.service;
          if (service == null) {
            return const SizedBox.shrink();
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: _BookingSummaryCard(
                  address: widget.address,
                  date: bookingProvider.selectedDate,
                  time: bookingProvider.selectedTime ?? '',
                ),
              ),
              Container(height: 1, color: AppColor.authButton.withValues(alpha: 0.08)),
              Expanded(
                child: Builder(
                  builder: (_) {
                    switch (bookingProvider.providerFetchStatus) {
                      case ProviderFetchStatus.loading:
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColor.authButton,
                          ),
                        );
                      case ProviderFetchStatus.error:
                        return _ProviderStateView(
                          message: bookingProvider.providerFetchError,
                          buttonLabel: 'Try again',
                          onTap: () => bookingProvider.fetchAvailableProviders(
                            zipCode: widget.address.zipCode,
                          ),
                        );
                      case ProviderFetchStatus.success:
                        if (bookingProvider.providers.isEmpty) {
                          return _ProviderStateView(
                            message:
                                'No providers are available for this date and time.',
                            buttonLabel: 'Choose another time',
                            onTap: () => Navigator.of(context).pop(),
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                              child: AppText(
                                '${bookingProvider.providers.length} provider${bookingProvider.providers.length == 1 ? '' : 's'} available for ${service.serviceName}',
                                fontSize: FontSizes.regular,
                                color: AppColor.grey,
                                maxLines: 2,
                              ),
                            ),
                            Expanded(
                              child: ListView.separated(
                                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                                itemCount: bookingProvider.providers.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 16),
                                itemBuilder: (context, index) {
                                  final provider = bookingProvider.providers[index];
                                  return _ProviderCard(
                                    provider: provider,
                                    selectedServiceId: service.id,
                                    onTap: () => _openReview(provider),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      case ProviderFetchStatus.initial:
                        return const SizedBox.shrink();
                    }
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BookingSummaryCard extends StatelessWidget {
  final AddressModel address;
  final DateTime date;
  final String time;

  const _BookingSummaryCard({
    required this.address,
    required this.date,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('MMM d').format(date);
    final parsedTime = _parseTime(time);

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
          _SummaryRow(
            icon: Icons.location_on_outlined,
            label:
                '${address.streetAddress}, ${address.city}, ${address.state ?? ''} ${address.zipCode}'.trim(),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _SummaryRow(
                  icon: Icons.calendar_today_outlined,
                  label: dateLabel,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryRow(
                  icon: Icons.access_time_outlined,
                  label: parsedTime,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _parseTime(String time) {
    if (time.isEmpty) return '-';
    try {
      final parsed = DateFormat('HH:mm').parseStrict(time);
      return DateFormat('h:mm a').format(parsed);
    } catch (_) {
      return time;
    }
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SummaryRow({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColor.authButton),
        const SizedBox(width: 8),
        Expanded(
          child: AppText(
            label.replaceAll(RegExp(r'\s+,|,\s*$'), '').replaceAll('  ', ' '),
            fontSize: FontSizes.regular,
            color: AppColor.darkGrey,
            maxLines: 3,
          ),
        ),
      ],
    );
  }
}

class _ProviderCard extends StatelessWidget {
  final ProviderModel provider;
  final int selectedServiceId;
  final VoidCallback onTap;

  const _ProviderCard({
    required this.provider,
    required this.selectedServiceId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final service = provider.serviceFor(selectedServiceId);
    final price = service?.priceAsDouble ?? 0.0;
    final duration = service?.formattedDuration ?? '-';

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColor.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColor.authButton.withValues(alpha: 0.12)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProviderAvatar(
              photoUrl: provider.photoUrl,
              fallbackText: provider.displayName,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    provider.displayName,
                    fontSize: FontSizes.medium,
                    fontWeight: FontWeights.bold,
                    color: AppColor.darkGrey,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 18, color: AppColor.blue),
                      const SizedBox(width: 4),
                      AppText(
                        provider.rating.toStringAsFixed(1),
                        fontSize: FontSizes.small,
                        fontWeight: FontWeights.semiBold,
                        color: AppColor.darkGrey,
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: AppColor.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AppText(
                          provider.status,
                          fontSize: FontSizes.small,
                          color: AppColor.grey,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      AppText(
                        _formatPrice(price),
                        fontSize:  FontSizes.regular,
                        fontWeight: FontWeights.bold,
                        color: AppColor.authButton,
                      ),
                      const SizedBox(width: 8),
                      AppText(
                        duration,
                        fontSize: FontSizes.small,
                        color: AppColor.grey,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColor.authButton.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(999),
              ),
              child: AppText(
                'Select',
                fontSize: 12,
                color: AppColor.authButton,
                fontWeight: FontWeights.semiBold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(double price) {
    if (price == price.truncateToDouble()) {
      return '\$${price.toInt()}';
    }
    return '\$${price.toStringAsFixed(2)}';
  }
}

class _ProviderAvatar extends StatelessWidget {
  final String? photoUrl;
  final String fallbackText;

  const _ProviderAvatar({
    required this.photoUrl,
    required this.fallbackText,
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
      return _AvatarFallback(initials: initials);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Image.network(
        photoUrl!,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _AvatarFallback(initials: initials),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  final String initials;

  const _AvatarFallback({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 76,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColor.authButton.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: AppText(
        initials.isEmpty ? '?' : initials,
        fontSize: FontSizes.large,
        fontWeight: FontWeights.bold,
        color: AppColor.authButton,
      ),
    );
  }
}

class _ProviderStateView extends StatelessWidget {
  final String message;
  final String buttonLabel;
  final VoidCallback onTap;

  const _ProviderStateView({
    required this.message,
    required this.buttonLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.person_search_rounded,
              size: 48,
              color: AppColor.authButton,
            ),
            const SizedBox(height: 12),
            AppText(
              message,
              fontSize: FontSizes.regular,
              color: AppColor.darkGrey,
              align: TextAlign.center,
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.authButton,
                  foregroundColor: AppColor.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: onTap,
                child: AppText(
                  buttonLabel,
                  color: AppColor.white,
                  fontWeight: FontWeights.semiBold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
