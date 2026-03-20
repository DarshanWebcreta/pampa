import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:pampa/core/storage/storage.dart';
import 'package:pampa/core/utils/functional_component.dart';
import 'package:pampa/core/values/app_text_value.dart';
import 'package:pampa/core/values/colors.dart';
import 'package:pampa/core/values/keys.dart';
import 'package:pampa/core/widgets/text_widget.dart';
import 'package:pampa/features/address/presentation/provider/address_provider.dart';
import 'package:pampa/features/booking/data/models/provider_model.dart';
import 'package:pampa/features/booking/presentation/provider/booking_provider.dart';
import 'package:pampa/features/services/data/models/service_model.dart';
import 'package:pampa/features/booking/presentation/booking_review_screen.dart';

// ─── Icon helper ─────────────────────────────────────────────────────────────
IconData _iconForCategory(String name) {
  final lower = name.toLowerCase();
  if (lower.contains('salon') || lower.contains('hair')) return Icons.content_cut_rounded;
  if (lower.contains('nail')) return Icons.colorize_rounded;
  if (lower.contains('makeup') || lower.contains('beauty')) return Icons.brush_rounded;
  if (lower.contains('massage') || lower.contains('spa')) return Icons.self_improvement_rounded;
  if (lower.contains('facial') || lower.contains('skin')) return Icons.face_retouching_natural_rounded;
  return Icons.spa_rounded;
}

class BookingScreen extends StatefulWidget {
  final int serviceId;

  const BookingScreen({super.key, required this.serviceId});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  late DateTime _visibleMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingProvider>().fetchServiceDetail(widget.serviceId);
      final savedZip = StorageManager.readData(StoreKeys.zipCode) as String?;
      context.read<BookingProvider>().fetchProviders(savedZip?.trim() ?? '');
      _fetchAndCheckAddresses();
    });
  }

  Future<void> _fetchAndCheckAddresses() async {
    final addressProvider = context.read<AddressProvider>();
    await addressProvider.fetchAddresses();
    if (!mounted) return;
    if (!addressProvider.hasAddresses) {
      _showAddAddressSheet();
    }
  }

  void _showAddAddressSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<AddressProvider>(),
        child: const _AddAddressSheet(),
      ),
    );
  }

  void _showProviderSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<BookingProvider>(),
        child: const _ProviderSelectionSheet(),
      ),
    );
  }

  void _onConfirmBooking() {
    final addresses = context.read<AddressProvider>().addresses;
    final selectedAddress = addresses.firstWhere(
      (a) => a.isDefault,
      orElse: () => addresses.first,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MultiProvider(
          providers: [
            ChangeNotifierProvider.value(
                value: context.read<BookingProvider>()),
            ChangeNotifierProvider.value(
                value: context.read<AddressProvider>()),
          ],
          child: BookingReviewScreen(address: selectedAddress),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      // appBar: _buildAppBar(),
      body: Consumer<BookingProvider>(
        builder: (context, provider, _) => _buildBody(provider),
      ),
      bottomNavigationBar: buildBottomBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
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
      title: AppText('Pampa',
          fontSize: FontSizes.medium,
          fontWeight: FontWeights.bold,
          color: AppColor.authButton),
      actions: [
        const Padding(
          padding: EdgeInsets.only(right: 14),
          child: Icon(Icons.calendar_month_outlined,
              color: AppColor.darkGrey, size: 22),
        ),
      ],
    );
  }

  Widget _buildBody(BookingProvider provider) {
    if (provider.fetchStatus == BookingFetchStatus.loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColor.authButton),
      );
    }

    if (provider.fetchStatus == BookingFetchStatus.error) {
      return _ErrorView(
        message: provider.fetchError,
        onRetry: () => provider.fetchServiceDetail(widget.serviceId),
      );
    }

    if (provider.service == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FunctionalComponent.goBackArrow(context: context),
          AppText('Select Date & Time',
              fontSize: FontSizes.large,
              fontWeight: FontWeights.bold,
              color: AppColor.darkGrey),
          const SizedBox(height: 4),
          AppText("Choose when you'd like your appointment",
              fontSize: FontSizes.small,
              color: AppColor.grey),

          const SizedBox(height: 20),

          _ServiceInfoCard(service: provider.service!),
          const SizedBox(height: 12),

          _ProviderCard(
            selectedProvider: provider.selectedProvider,
            isLoading: provider.isLoadingProviders,
            onTap: _showProviderSheet,
          ),
          const SizedBox(height: 12),

          const _LocationCard(),
          const SizedBox(height: 20),

          _CalendarCard(
            visibleMonth: _visibleMonth,
            selectedDate: provider.selectedDate,
            onDateSelected: provider.selectDate,
            onMonthChanged: (delta) {
              setState(() {
                _visibleMonth = DateTime(
                  _visibleMonth.year,
                  _visibleMonth.month + delta,
                );
              });
            },
          ),

          const SizedBox(height: 24),

          AppText('Select Time',
              fontSize: FontSizes.medium,
              fontWeight: FontWeights.bold,
              color: AppColor.darkGrey),
          const SizedBox(height: 14),

          _TimeSlotsSection(
            provider: provider,
            onSelect: provider.selectTime,
          ),

          const SizedBox(height: 24),

          _TipCard(
            tipAmount: provider.tipAmount,
            onSelect: provider.selectTip,
          ),
        ],
      ),
    );
  }


  Widget buildBottomBar() {
    return Consumer<BookingProvider>(
      builder: (context, provider, _) {
        final canBook = provider.canBook;
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
                  backgroundColor:
                      canBook ? AppColor.authButton : AppColor.mediumGrey,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed:
                    (canBook && !provider.isSubmitting) ? _onConfirmBooking : null,
                child: provider.isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: AppColor.white, strokeWidth: 2.5),
                      )
                    : AppText('Review Booking',
                        fontSize: FontSizes.regular,
                        fontWeight: FontWeights.semiBold,
                        color: AppColor.white),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Service info card ────────────────────────────────────────────────────────
class _ServiceInfoCard extends StatelessWidget {
  final ServiceModel service;
  const _ServiceInfoCard({required this.service});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColor.authBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _iconForCategory(
                  service.category?.categoryName ?? service.serviceName),
              color: AppColor.authButton,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(service.serviceName,
                    fontSize: FontSizes.regular,
                    fontWeight: FontWeights.bold,
                    color: AppColor.darkGrey),
                const SizedBox(height: 3),
                AppText(
                  service.category?.categoryName ?? 'Beauty Service',
                  fontSize: 12,
                  color: AppColor.grey,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AppText(service.formattedPrice,
                  fontSize: FontSizes.medium,
                  fontWeight: FontWeights.bold,
                  color: AppColor.authButton),
              AppText(service.formattedDuration,
                  fontSize: 11, color: AppColor.grey),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Provider selection card ──────────────────────────────────────────────────
class _ProviderCard extends StatelessWidget {
  final ProviderModel? selectedProvider;
  final bool isLoading;
  final VoidCallback onTap;

  const _ProviderCard({
    required this.selectedProvider,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
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
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: selectedProvider != null
                    ? AppColor.authBg
                    : AppColor.lightGrey,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.person_rounded,
                color: selectedProvider != null
                    ? AppColor.authButton
                    : AppColor.grey,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: isLoading
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 12,
                          width: 100,
                          decoration: BoxDecoration(
                            color: AppColor.lightGrey,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 10,
                          width: 70,
                          decoration: BoxDecoration(
                            color: AppColor.lightGrey,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ],
                    )
                  : selectedProvider != null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              selectedProvider!.displayName,
                              fontSize: FontSizes.regular,
                              fontWeight: FontWeights.bold,
                              color: AppColor.darkGrey,
                            ),
                            const SizedBox(height: 3),
                            AppText(selectedProvider!.displayLocation,
                                fontSize: 12, color: AppColor.grey),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                const Icon(Icons.star_rounded,
                                    size: 13, color: Colors.amber),
                                const SizedBox(width: 3),
                                AppText(
                                  selectedProvider!.rating.toStringAsFixed(1),
                                  fontSize: 12,
                                  color: AppColor.grey,
                                ),
                              ],
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText('Select a Provider',
                                fontSize: FontSizes.regular,
                                fontWeight: FontWeights.semiBold,
                                color: AppColor.authButton),
                            const SizedBox(height: 3),
                            AppText('Tap to choose your service provider',
                                fontSize: 12, color: AppColor.grey),
                          ],
                        ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColor.grey, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Location card ────────────────────────────────────────────────────────────
class _LocationCard extends StatelessWidget {
  const _LocationCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.location_on_outlined,
                color: AppColor.authButton, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText('Service Location',
                  fontSize: FontSizes.regular,
                  fontWeight: FontWeights.semiBold,
                  color: AppColor.darkGrey),
              const SizedBox(height: 4),
              AppText('Location will be confirmed',
                  fontSize: 12, color: AppColor.grey),
              AppText('upon booking confirmation',
                  fontSize: 12, color: AppColor.grey),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Calendar card ────────────────────────────────────────────────────────────
class _CalendarCard extends StatelessWidget {
  final DateTime visibleMonth;
  final DateTime selectedDate;
  final void Function(DateTime) onDateSelected;
  final void Function(int delta) onMonthChanged;

  const _CalendarCard({
    required this.visibleMonth,
    required this.selectedDate,
    required this.onDateSelected,
    required this.onMonthChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => onMonthChanged(-1),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.chevron_left_rounded,
                      color: AppColor.darkGrey, size: 22),
                ),
              ),
              AppText(
                DateFormat('MMMM yyyy').format(visibleMonth),
                fontSize: FontSizes.regular,
                fontWeight: FontWeights.semiBold,
                color: AppColor.darkGrey,
              ),
              GestureDetector(
                onTap: () => onMonthChanged(1),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.chevron_right_rounded,
                      color: AppColor.darkGrey, size: 22),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']
                .map((d) => Expanded(
                      child: Center(
                        child: AppText(d,
                            fontSize: 11,
                            fontWeight: FontWeights.semiBold,
                            color: AppColor.grey),
                      ),
                    ))
                .toList(),
          ),

          const SizedBox(height: 8),
          _buildDateGrid(),
        ],
      ),
    );
  }

  Widget _buildDateGrid() {
    final firstDay = DateTime(visibleMonth.year, visibleMonth.month, 1);
    final lastDay = DateTime(visibleMonth.year, visibleMonth.month + 1, 0);
    final startPadding = firstDay.weekday % 7;
    final today = DateTime.now();
    final List<Widget> cells = [];

    for (int i = 0; i < startPadding; i++) {
      cells.add(const SizedBox.shrink());
    }

    for (int day = 1; day <= lastDay.day; day++) {
      final date = DateTime(visibleMonth.year, visibleMonth.month, day);
      final isPast =
          date.isBefore(DateTime(today.year, today.month, today.day));
      final isSelected = date.year == selectedDate.year &&
          date.month == selectedDate.month &&
          date.day == selectedDate.day;
      final isToday = date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;

      cells.add(
        GestureDetector(
          onTap: isPast ? null : () => onDateSelected(date),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isSelected ? AppColor.authButton : Colors.transparent,
              shape: BoxShape.circle,
              border: isToday && !isSelected
                  ? Border.all(color: AppColor.authButton, width: 1.5)
                  : null,
            ),
            child: Center(
              child: AppText(
                '$day',
                fontSize: 13,
                fontWeight:
                    isSelected ? FontWeights.bold : FontWeights.regular,
                color: isSelected
                    ? AppColor.white
                    : isPast
                        ? AppColor.mediumGrey
                        : AppColor.darkGrey,
              ),
            ),
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1,
      children: cells,
    );
  }
}

// ─── Time slots section (dynamic from API) ────────────────────────────────────
class _TimeSlotsSection extends StatelessWidget {
  final BookingProvider provider;
  final void Function(String) onSelect;

  const _TimeSlotsSection({required this.provider, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    if (provider.selectedProvider == null) {
      return const _SlotHint('Select a provider above to view available time slots.');
    }

    if (provider.slotFetchStatus == SlotFetchStatus.loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: CircularProgressIndicator(color: AppColor.authButton),
        ),
      );
    }

    if (provider.slotFetchStatus == SlotFetchStatus.error) {
      return _SlotHint('Could not load slots: ${provider.slotFetchError}');
    }

    if (provider.slots.isEmpty &&
        provider.slotFetchStatus == SlotFetchStatus.success) {
      return const _SlotHint('No available slots for the selected date.');
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: provider.slots.map((slot) {
        final isSelected = provider.selectedTime == slot.time;
        final isAvailable = slot.available;

        return GestureDetector(
          onTap: isAvailable ? () => onSelect(slot.time) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColor.authButton
                  : isAvailable
                      ? AppColor.white
                      : AppColor.lightGrey,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? AppColor.authButton
                    : isAvailable
                        ? AppColor.lightGrey
                        : AppColor.mediumGrey,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColor.authButton.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: AppText(
              slot.displayTime,
              fontSize: 13,
              fontWeight:
                  isSelected ? FontWeights.semiBold : FontWeights.regular,
              color: isSelected
                  ? AppColor.white
                  : isAvailable
                      ? AppColor.darkGrey
                      : AppColor.mediumGrey,
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Tip card ─────────────────────────────────────────────────────────────────
class _TipCard extends StatefulWidget {
  final double tipAmount;
  final ValueChanged<double> onSelect;

  const _TipCard({required this.tipAmount, required this.onSelect});

  @override
  State<_TipCard> createState() => _TipCardState();
}

class _TipCardState extends State<_TipCard> {
  static const _presets = [0.0, 5.0, 10.0, 15.0, 20.0];
  bool _showCustom = false;
  final _customCtrl = TextEditingController();

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  bool get _isCustomSelected =>
      !_presets.contains(widget.tipAmount) && widget.tipAmount > 0;

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
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColor.authBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.volunteer_activism_rounded,
                    color: AppColor.authButton, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText('Add a Tip',
                        fontSize: FontSizes.regular,
                        fontWeight: FontWeights.bold,
                        color: AppColor.darkGrey),
                    AppText('Show appreciation for your provider',
                        fontSize: 11,
                        color: AppColor.grey),
                  ],
                ),
              ),
              if (widget.tipAmount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColor.authBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: AppText(
                    '\$${widget.tipAmount % 1 == 0 ? widget.tipAmount.toInt() : widget.tipAmount.toStringAsFixed(2)}',
                    fontSize: 13,
                    fontWeight: FontWeights.semiBold,
                    color: AppColor.authButton,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._presets.map((amount) {
                final isSelected =
                    widget.tipAmount == amount && !_isCustomSelected;
                final label = amount == 0 ? 'No Tip' : '\$${amount.toInt()}';
                return GestureDetector(
                  onTap: () {
                    widget.onSelect(amount);
                    if (_showCustom) setState(() => _showCustom = false);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColor.authButton
                          : AppColor.lightGrey,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: AppText(
                      label,
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeights.semiBold
                          : FontWeights.regular,
                      color: isSelected ? AppColor.white : AppColor.darkGrey,
                    ),
                  ),
                );
              }),
              GestureDetector(
                onTap: () => setState(() => _showCustom = !_showCustom),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: _isCustomSelected || _showCustom
                        ? AppColor.authButton
                        : AppColor.lightGrey,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: AppText(
                    'Custom',
                    fontSize: 13,
                    fontWeight: _isCustomSelected || _showCustom
                        ? FontWeights.semiBold
                        : FontWeights.regular,
                    color: _isCustomSelected || _showCustom
                        ? AppColor.white
                        : AppColor.darkGrey,
                  ),
                ),
              ),
            ],
          ),
          if (_showCustom) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _customCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    style: const TextStyle(
                        fontSize: 14, color: AppColor.darkGrey),
                    decoration: InputDecoration(
                      hintText: 'Enter amount',
                      hintStyle: const TextStyle(
                          fontSize: 13, color: AppColor.mediumGrey),
                      prefixText: '\$ ',
                      prefixStyle: const TextStyle(
                          fontSize: 14,
                          color: AppColor.darkGrey,
                          fontWeight: FontWeight.w600),
                      filled: true,
                      fillColor: const Color(0xFFF8F8F8),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: AppColor.lightGrey),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: AppColor.lightGrey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: AppColor.authButton, width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    final val = double.tryParse(_customCtrl.text.trim()) ?? 0;
                    if (val > 0) {
                      widget.onSelect(val);
                      setState(() => _showCustom = false);
                      _customCtrl.clear();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColor.authButton,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: AppText('Apply',
                        fontSize: 13,
                        fontWeight: FontWeights.semiBold,
                        color: AppColor.white),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SlotHint extends StatelessWidget {
  final String message;
  const _SlotHint(this.message);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColor.authBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: AppText(
        message,
        fontSize: FontSizes.small,
        color: AppColor.authButton,
        align: TextAlign.center,
        maxLines: 2,
      ),
    );
  }
}

// ─── Provider Selection Sheet ─────────────────────────────────────────────────
class _ProviderSelectionSheet extends StatelessWidget {
  const _ProviderSelectionSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Consumer<BookingProvider>(
        builder: (_, provider, _) {
          return Column(
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
              const SizedBox(height: 20),

              AppText('Choose Provider',
                  fontSize: FontSizes.medium,
                  fontWeight: FontWeights.bold,
                  color: AppColor.darkGrey),
              const SizedBox(height: 4),
              AppText('Select the professional for your service',
                  fontSize: FontSizes.small,
                  color: AppColor.grey),
              const SizedBox(height: 20),

              if (provider.isLoadingProviders)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: CircularProgressIndicator(color: AppColor.authButton),
                  ),
                )
              else if (provider.providerFetchStatus == ProviderFetchStatus.error)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: AppText(provider.providerFetchError,
                        fontSize: FontSizes.small,
                        color: AppColor.grey,
                        align: TextAlign.center),
                  ),
                )
              else if (provider.providers.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: AppText('No providers available at the moment.',
                        fontSize: FontSizes.small,
                        color: AppColor.grey,
                        align: TextAlign.center),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: provider.providers.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, color: AppColor.lightGrey),
                    itemBuilder: (_, index) {
                      final p = provider.providers[index];
                      final isSelected =
                          provider.selectedProvider?.id == p.id;
                      final photoUrl = p.photoUrl?.trim();
                      final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 6),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColor.authBg
                                : AppColor.lightGrey,
                            shape: BoxShape.circle,
                          ),
                          child: hasPhoto
                              ? ClipOval(
                                  child: FunctionalComponent.cachedNetworkImage(
                                    photoUrl,
                                    radius: 24,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Icon(Icons.person_rounded,
                                  color: isSelected
                                      ? AppColor.authButton
                                      : AppColor.grey,
                                  size: 24),
                        ),
                        title: AppText(p.displayName,
                            fontSize: FontSizes.regular,
                            fontWeight: FontWeights.semiBold,
                            color: AppColor.darkGrey),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 2),
                            AppText(p.displayLocation,
                                fontSize: 12, color: AppColor.grey),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Icon(Icons.star_rounded,
                                    size: 13, color: Colors.amber),
                                const SizedBox(width: 3),
                                AppText(p.rating.toStringAsFixed(1),
                                    fontSize: 12, color: AppColor.grey),
                              ],
                            ),
                          ],
                        ),
                        trailing: isSelected
                            ? Container(
                                width: 28,
                                height: 28,
                                decoration: const BoxDecoration(
                                  color: AppColor.authButton,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check_rounded,
                                    color: AppColor.white, size: 16),
                              )
                            : null,
                        onTap: () {
                          provider.selectProvider(p);
                          Navigator.of(context).pop();
                        },
                      );
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

// ─── Add Address Bottom Sheet ────────────────────────────────────────────────
class _AddAddressSheet extends StatefulWidget {
  const _AddAddressSheet();

  @override
  State<_AddAddressSheet> createState() => _AddAddressSheetState();
}

class _AddAddressSheetState extends State<_AddAddressSheet> {
  final _formKey = GlobalKey<FormState>();
  final _addressNameCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _zipCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final savedZip = StorageManager.readData(StoreKeys.zipCode) as String?;
    if (savedZip != null && savedZip.isNotEmpty) {
      _zipCtrl.text = savedZip;
    }
  }

  @override
  void dispose() {
    _addressNameCtrl.dispose();
    _streetCtrl.dispose();
    _zipCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<AddressProvider>();
    final success = await provider.storeAddress(
      addressName: _addressNameCtrl.text.trim(),
      streetAddress: _streetCtrl.text.trim(),
      zipCode: _zipCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
      FunctionalComponent.showSnackBar(
        context: context,
        title: 'Address saved successfully!',
        success: true,
      );
    } else {
      FunctionalComponent.showSnackBar(
        context: context,
        title: provider.saveError,
        success: false,
      );
      provider.resetSave();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
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
          const SizedBox(height: 20),

          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColor.authBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_on_rounded,
                    color: AppColor.authButton, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText('Add Your Address',
                      fontSize: FontSizes.medium,
                      fontWeight: FontWeights.bold,
                      color: AppColor.darkGrey),
                  AppText('Required to proceed with booking',
                      fontSize: FontSizes.small,
                      color: AppColor.grey),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          Form(
            key: _formKey,
            child: Column(
              children: [
                _AddressField(
                  controller: _addressNameCtrl,
                  label: 'Full Address',
                  hint: 'e.g. 44/Otamba Society, Bapunagar',
                  icon: Icons.home_outlined,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Enter your address'
                      : null,
                ),
                const SizedBox(height: 14),
                _AddressField(
                  controller: _streetCtrl,
                  label: 'Street / House No.',
                  hint: 'e.g. 33',
                  icon: Icons.signpost_outlined,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Enter street address'
                      : null,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _AddressField(
                        controller: _zipCtrl,
                        label: 'ZIP Code',
                        hint: '382350',
                        icon: Icons.pin_drop_outlined,
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Enter ZIP' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _AddressField(
                        controller: _cityCtrl,
                        label: 'City',
                        hint: 'Ahmedabad',
                        icon: Icons.location_city_outlined,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Enter city'
                            : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Consumer<AddressProvider>(
            builder: (_, provider, _) {
              final saving = provider.isSaving;
              return SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.authButton,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: saving ? null : _submit,
                  child: saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: AppColor.white, strokeWidth: 2.5),
                        )
                      : AppText('Save Address',
                          fontSize: FontSizes.regular,
                          fontWeight: FontWeights.semiBold,
                          color: AppColor.white),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Reusable address text field ──────────────────────────────────────────────
class _AddressField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;

  const _AddressField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.validator,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: AppColor.darkGrey),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: AppColor.grey),
        labelStyle: const TextStyle(fontSize: 13, color: AppColor.grey),
        hintStyle: const TextStyle(fontSize: 13, color: AppColor.mediumGrey),
        filled: true,
        fillColor: const Color(0xFFF8F8F8),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColor.lightGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColor.lightGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColor.authButton, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
    );
  }
}

// ─── Error view ───────────────────────────────────────────────────────────────
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
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                  color: AppColor.authBg, shape: BoxShape.circle),
              child: const Icon(Icons.wifi_off_rounded,
                  color: AppColor.authButton, size: 32),
            ),
            const SizedBox(height: 16),
            AppText('Failed to load',
                fontSize: FontSizes.medium,
                fontWeight: FontWeights.semiBold,
                color: AppColor.darkGrey),
            const SizedBox(height: 8),
            AppText(message,
                fontSize: FontSizes.small,
                color: AppColor.grey,
                align: TextAlign.center,
                maxLines: 3),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                decoration: BoxDecoration(
                  color: AppColor.authButton,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: AppText('Retry',
                    fontSize: FontSizes.regular,
                    fontWeight: FontWeights.semiBold,
                    color: AppColor.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
