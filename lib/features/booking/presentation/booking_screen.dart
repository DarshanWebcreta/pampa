import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pampa/features/booking/data/models/slot_model.dart';
import 'package:provider/provider.dart';

import 'package:pampa/core/storage/storage.dart';
import 'package:pampa/core/utils/functional_component.dart';
import 'package:pampa/data/service/apiservice.dart';
import 'package:pampa/data/service/di.dart';
import 'package:pampa/core/values/app_text_value.dart';
import 'package:pampa/core/values/colors.dart';
import 'package:pampa/core/values/keys.dart';
import 'package:pampa/core/widgets/text_widget.dart';
import 'package:pampa/features/address/data/models/address_model.dart';
import 'package:pampa/features/address/presentation/provider/address_provider.dart';
import 'package:pampa/features/address/presentation/address_search_screen.dart';
import 'package:pampa/features/booking/data/models/provider_model.dart';
import 'package:pampa/features/booking/presentation/booking_review_screen.dart';
import 'package:pampa/features/booking/presentation/choose_provider_screen.dart';
import 'package:pampa/features/booking/presentation/provider/booking_provider.dart';
import 'package:pampa/features/my_bookings/presentation/provider/my_bookings_provider.dart';

// ─── Icon helper for address name ─────────────────────────────────────────────
IconData _iconForAddress(String name) {
  final lower = name.toLowerCase();
  if (lower.contains('home') || lower.contains('house'))
    return Icons.home_rounded;
  if (lower.contains('work') || lower.contains('office'))
    return Icons.work_rounded;
  return Icons.location_on_rounded;
}

// ─── Main screen ──────────────────────────────────────────────────────────────
class BookingScreen extends StatefulWidget {
  final int serviceId;
  final ProviderModel? preSelectedProvider;
  final List<int> preSelectedServiceIds;
  final int? rescheduleBookingId;
  final int? rescheduleAddressId;
  final bool isBookAgain;

  const BookingScreen({
    super.key,
    required this.serviceId,
    this.preSelectedProvider,
    this.preSelectedServiceIds = const [],
    this.rescheduleBookingId,
    this.rescheduleAddressId,
    this.isBookAgain = false,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

// Period definition used in the UI
const _periods = [
  {'label': 'Morning', 'from': 9 * 60, 'to': 12 * 60},
  {'label': 'Afternoon', 'from': 12 * 60, 'to': 16 * 60},
  {'label': 'Evening', 'from': 16 * 60, 'to': 22 * 60},
];

class _BookingScreenState extends State<BookingScreen> {
  int _step = 0; // 0 = address, 1 = date & time
  AddressModel? _selectedAddress;
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);
  String? _selectedTimeDisplay;
  String? _selectedPeriod; // 'Morning' | 'Afternoon' | 'Evening'
  bool _changeProviderMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final bp = context.read<BookingProvider>();
      final ap = context.read<AddressProvider>();

      if (bp.service == null && bp.fetchStatus == BookingFetchStatus.loading) {
        await Future.doWhile(() async {
          if (bp.fetchStatus == BookingFetchStatus.loading) {
            await Future.delayed(const Duration(milliseconds: 50));
            return true;
          }
          return false;
        });
      } else if (bp.service == null) {
        await bp.fetchServiceDetail(widget.serviceId);
      }

      final provider = widget.preSelectedProvider;
      if (provider != null && bp.service != null) {
        bp.fetchUnavailableDates(provider.id, bp.service!.categoryId);
      }

      await ap.fetchAddresses();

      if (!mounted) return;
      if (ap.hasAddresses) {
        final def = widget.rescheduleAddressId != null
            ? ap.addresses.firstWhere(
                (a) => a.id == widget.rescheduleAddressId,
                orElse: () => ap.addresses.firstWhere(
                  (a) => a.isDefault,
                  orElse: () => ap.addresses.first,
                ),
              )
            : ap.addresses.firstWhere(
                (a) => a.isDefault,
                orElse: () => ap.addresses.first,
              );
        setState(() => _selectedAddress = def);
      }
    });
  }

  void _goToStep1() {
    if (_selectedAddress == null) return;
    setState(() => _step = 1);
    _loadSlots(context.read<BookingProvider>().selectedDate);
  }

  void _goBack() {
    if (_step > 0) {
      setState(() {
        _step = 0;
        _selectedTimeDisplay = null;
      });
      context.read<BookingProvider>().selectTime('');
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _loadSlots(DateTime date) async {
    setState(() {
      _selectedTimeDisplay = null;
      _selectedPeriod = null;
    });

    final bp = context.read<BookingProvider>();
    final provider = _changeProviderMode ? null : widget.preSelectedProvider;

    if (provider != null) {
      await bp.fetchAvailableSlots(provider.id, serviceId: widget.serviceId);
    } else {
      bp.generateStaticSlots();
    }
  }

  /// Returns slots whose start time falls within [fromMins, toMins)
  List<SlotModel> _slotsForPeriod(
    List<SlotModel> all,
    int fromMins,
    int toMins,
  ) {
    return all.where((s) {
      if (s.time.isEmpty) return false;
      final parts = s.time.split(':');
      final mins = int.parse(parts[0]) * 60 + int.parse(parts[1]);
      return mins >= fromMins && mins < toMins;
    }).toList();
  }

  /// True if the period contains at least one slot
  bool _periodHasSlots(List<SlotModel> all, int fromMins, int toMins) =>
      _slotsForPeriod(all, fromMins, toMins).isNotEmpty;

  void _onConfirm() {
    final bp = context.read<BookingProvider>();
    final preProvider = _changeProviderMode ? null : widget.preSelectedProvider;

    if (preProvider != null) {
      bp.selectProvider(preProvider);
      final ids = bp.selectedServiceIds.isNotEmpty
          ? bp.selectedServiceIds
          : (widget.preSelectedServiceIds.isNotEmpty
                ? widget.preSelectedServiceIds
                : [widget.serviceId]);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: bp),
              ChangeNotifierProvider.value(
                value: context.read<AddressProvider>(),
              ),
            ],
            child: BookingReviewScreen(
              address: _selectedAddress!,
              serviceIds: ids,
              rescheduleBookingId: widget.rescheduleBookingId,
              isBookAgain: widget.isBookAgain,
            ),
          ),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: bp),
            ChangeNotifierProvider.value(
              value: context.read<AddressProvider>(),
            ),
          ],
          child: ChooseProviderScreen(
            address: _selectedAddress!,
            rescheduleBookingId: widget.rescheduleBookingId,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _step > 0) _goBack();
      },
      child: Scaffold(
        backgroundColor: AppColor.authBg,
        body: Consumer<BookingProvider>(
          builder: (context, provider, _) {
            // Step 0 (address) shows immediately — no service data needed
            if (_step == 0) return _buildAddressStep(context);

            // Step 1 (date/time) needs service data
            if (provider.fetchStatus == BookingFetchStatus.loading) {
              return const SafeArea(
                child: Center(
                  child: CircularProgressIndicator(color: AppColor.authButton),
                ),
              );
            }
            if (provider.fetchStatus == BookingFetchStatus.error) {
              return SafeArea(
                child: _ErrorView(
                  message: provider.fetchError,
                  onRetry: () => provider.fetchServiceDetail(widget.serviceId),
                ),
              );
            }
            return _buildDateTimeStep(context, provider);
          },
        ),
      ),
    );
  }

  // ── Step 0: Address ─────────────────────────────────────────────────────────
  Widget _buildAddressStep(BuildContext context) {
    return Column(
      children: [
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _goBack,
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 20,
                    color: AppColor.darkGrey,
                  ),
                ),
                const SizedBox(width: 16),
                AppText(
                  'Select service location',
                  fontSize: FontSizes.large,
                  fontWeight: FontWeights.bold,
                  color: AppColor.darkGrey,
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Align(
            alignment: Alignment.centerLeft,
            child: AppText(
              'Where would you like your service?',
              fontSize: FontSizes.small,
              color: AppColor.grey,
            ),
          ),
        ),
        Expanded(
          child: Consumer<AddressProvider>(
            builder: (_, ap, _) {
              if (ap.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColor.authButton),
                );
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  children: [
                    ...ap.addresses.map(
                      (addr) => _AddressTile(
                        address: addr,
                        isSelected: _selectedAddress?.id == addr.id,
                        onTap: () => setState(() => _selectedAddress = addr),
                      ),
                    ),
                    _AddNewAddressTile(
                      onAdded: (addr) =>
                          setState(() => _selectedAddress = addr),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        _BottomBar(
          label: 'Continue',
          enabled: _selectedAddress != null,
          onTap: _goToStep1,
        ),
      ],
    );
  }

  // ── Step 1: Date & Time ─────────────────────────────────────────────────────
  Widget _buildDateTimeStep(BuildContext context, BookingProvider provider) {
    final service = provider.service;
    final hasPriority = (service?.priorityFee ?? 0) > 0;
    final isToday = _isSameDay(provider.selectedDate, DateTime.now());
    final hasTime = _selectedTimeDisplay != null;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 4),
                    child: GestureDetector(
                      onTap: _goBack,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 14,
                            color: AppColor.authButton,
                          ),
                          const SizedBox(width: 4),
                          AppText(
                            'Back',
                            fontSize: FontSizes.small,
                            fontWeight: FontWeights.semiBold,
                            color: AppColor.authButton,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                AppText(
                  'When would you like us?',
                  fontSize: FontSizes.extraLarge,
                  fontWeight: FontWeights.bold,
                  color: AppColor.darkGrey,
                  maxLines: 2,
                ),
                const SizedBox(height: 6),
                AppText(
                  'Choose your preferred date and time',
                  fontSize: FontSizes.regular,
                  color: AppColor.grey,
                ),
                if (hasPriority) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColor.authButton.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: AppText(
                      'Priority Booking +\$${service!.priorityFee.toStringAsFixed(0)}',
                      fontSize: FontSizes.small,
                      fontWeight: FontWeights.semiBold,
                      color: AppColor.authButton,
                    ),
                  ),
                  if (isToday) ...[
                    const SizedBox(height: 8),
                    AppText(
                      'Same-day bookings include a priority service fee.',
                      fontSize: FontSizes.small,
                      color: AppColor.grey,
                      maxLines: 2,
                    ),
                  ],
                ],
                const SizedBox(height: 24),
                _CalendarCard(
                  visibleMonth: _visibleMonth,
                  selectedDate: provider.selectedDate,
                  unavailableDates: provider.unavailableDates,
                  isRescheduling: widget.rescheduleBookingId != null,
                  onDateSelected: (date) {
                    provider.selectDate(date);
                    _loadSlots(date);
                  },
                  onMonthChanged: (delta) {
                    final today = DateTime.now();
                    final maxDate = today.add(const Duration(days: 90));
                    final minMonth = DateTime(today.year, today.month);
                    final maxMonthLimit = DateTime(maxDate.year, maxDate.month);
                    final targetMonth = DateTime(
                      _visibleMonth.year,
                      _visibleMonth.month + delta,
                    );

                    if ((targetMonth.isAfter(minMonth) ||
                            targetMonth.isAtSameMomentAs(minMonth)) &&
                        (targetMonth.isBefore(maxMonthLimit) ||
                            targetMonth.isAtSameMomentAs(maxMonthLimit))) {
                      setState(() {
                        _visibleMonth = targetMonth;
                      });
                    }
                  },
                ),
                const SizedBox(height: 24),
                AppText(
                  'Select Time',
                  fontSize: FontSizes.medium,
                  fontWeight: FontWeights.bold,
                  color: AppColor.darkGrey,
                ),
                const SizedBox(height: 12),
                if (provider.slotsLoading)
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: List.generate(
                      3,
                      (_) => Container(
                        width: 100,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColor.lightGrey,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  )
                else if (provider.availableSlots.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: AppColor.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: AppText(
                        'No available slots for this date',
                        fontSize: FontSizes.small,
                        color: AppColor.grey,
                      ),
                    ),
                  )
                else ...[
                  // ── Period tabs ──────────────────────────────────
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _periods.map((p) {
                      final label = p['label'] as String;
                      final from = p['from'] as int;
                      final to = p['to'] as int;
                      final active = _periodHasSlots(
                        provider.availableSlots,
                        from,
                        to,
                      );
                      final selected = _selectedPeriod == label;
                      return GestureDetector(
                        onTap: active
                            ? () => setState(() {
                                _selectedPeriod = selected ? null : label;
                                _selectedTimeDisplay = null;
                                provider.selectTime('');
                              })
                            : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColor.authButton
                                : (active
                                      ? AppColor.white
                                      : AppColor.lightGrey.withValues(
                                          alpha: 0.5,
                                        )),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected
                                  ? AppColor.authButton
                                  : (active
                                        ? AppColor.authButton.withValues(
                                            alpha: 0.3,
                                          )
                                        : AppColor.lightGrey),
                              width: selected ? 1.5 : 1,
                            ),
                          ),
                          child: AppText(
                            label,
                            fontSize: FontSizes.small,
                            fontWeight: FontWeights.semiBold,
                            color: selected
                                ? AppColor.white
                                : (active
                                      ? AppColor.darkGrey
                                      : AppColor.grey.withValues(alpha: 0.5)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  // ── Slots for selected period ─────────────────────
                  if (_selectedPeriod != null) ...[
                    const SizedBox(height: 16),
                    Builder(
                      builder: (_) {
                        final p = _periods.firstWhere(
                          (p) => p['label'] == _selectedPeriod,
                        );
                        final filtered = _slotsForPeriod(
                          provider.availableSlots,
                          p['from'] as int,
                          p['to'] as int,
                        );
                        return _TimeSlotGrid(
                          slots: filtered,
                          loading: false,
                          selectedDisplay: _selectedTimeDisplay,
                          onSelect: (i) {
                            final slot = filtered[i];
                            provider.selectTime(slot.time);
                            setState(
                              () => _selectedTimeDisplay = _formatDisplayTime(
                                slot.time,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
        _BottomBar(
          label: 'Continue',
          enabled: hasTime,
          onTap: _onConfirm,
          onChangeProvider:
              (provider.availableSlots.isEmpty &&
                  !provider.slotsLoading &&
                  !_changeProviderMode &&
                  widget.rescheduleBookingId != null)
              ? () {
                  setState(() {
                    _changeProviderMode = true;
                  });
                  _loadSlots(provider.selectedDate);
                }
              : null,
        ),
      ],
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

String _formatDisplayTime(String time24) {
  if (time24.isEmpty) return '';
  try {
    final parts = time24.split(':');
    final h = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    final period = h < 12 ? 'AM' : 'PM';
    final displayH = h % 12 == 0 ? 12 : h % 12;
    final displayM = m.toString().padLeft(2, '0');
    return '$displayH:$displayM $period';
  } catch (_) {
    return time24;
  }
}

String _formatTimeRange(String start24, String end24) {
  if (start24.isEmpty) return '';
  if (end24.isEmpty) return _formatDisplayTime(start24);

  try {
    final startParts = start24.split(':');
    final endParts = end24.split(':');

    final sh = int.parse(startParts[0]);
    final sm = int.parse(startParts[1]);
    final eh = int.parse(endParts[0]);
    final em = int.parse(endParts[1]);

    final period = eh < 12 ? 'AM' : 'PM';

    final displaySH = sh % 12 == 0 ? 12 : sh % 12;
    final displaySM = sm.toString().padLeft(2, '0');
    final displayEH = eh % 12 == 0 ? 12 : eh % 12;
    final displayEM = em.toString().padLeft(2, '0');

    return '$displaySH:$displaySM - $displayEH:$displayEM $period';
  } catch (_) {
    return _formatDisplayTime(start24);
  }
}

// ─── Time slot grid ───────────────────────────────────────────────────────────
class _TimeSlotGrid extends StatelessWidget {
  final List<SlotModel> slots;
  final bool loading;
  final String? selectedDisplay;
  final void Function(int index) onSelect;

  const _TimeSlotGrid({
    required this.slots,
    required this.loading,
    required this.selectedDisplay,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: List.generate(
          8,
          (_) => Container(
            width: 82,
            height: 40,
            decoration: BoxDecoration(
              color: AppColor.lightGrey,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      );
    }

    if (slots.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppColor.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: AppText(
            'No available slots for this date',
            fontSize: FontSizes.small,
            color: AppColor.grey,
          ),
        ),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: List.generate(slots.length, (i) {
        final slot = slots[i];
        final displayLabel = _formatTimeRange(slot.time, slot.endTime);
        final isSelected = _formatDisplayTime(slot.time) == selectedDisplay;
        final isAvailable = slot.available;

        return GestureDetector(
          onTap: isAvailable ? () => onSelect(i) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColor.authButton
                  : (isAvailable
                        ? AppColor.white
                        : AppColor.lightGrey.withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? AppColor.authButton
                    : (isAvailable
                          ? AppColor.authButton.withValues(alpha: 0.25)
                          : AppColor.lightGrey),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: AppText(
              displayLabel,
              fontSize: FontSizes.small,
              fontWeight: isSelected
                  ? FontWeights.semiBold
                  : FontWeights.regular,
              color: isSelected
                  ? AppColor.white
                  : (isAvailable
                        ? AppColor.darkGrey
                        : AppColor.grey.withValues(alpha: 0.6)),
            ),
          ),
        );
      }),
    );
  }
}

// ─── Address tile ─────────────────────────────────────────────────────────────
class _AddressTile extends StatelessWidget {
  final AddressModel address;
  final bool isSelected;
  final VoidCallback onTap;

  const _AddressTile({
    required this.address,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColor.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColor.authButton : AppColor.lightGrey,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColor.authButton.withValues(alpha: 0.1)
                    : AppColor.lightGrey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _iconForAddress(address.addressName),
                size: 20,
                color: isSelected ? AppColor.authButton : AppColor.grey,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: AppText(
                          address.addressName,
                          fontSize: FontSizes.regular,
                          maxLines: 5,
                          fontWeight: FontWeights.semiBold,
                          color: AppColor.darkGrey,
                        ),
                      ),
                      if (address.isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColor.authButton.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: AppText(
                            'Default',
                            fontSize: 10,
                            fontWeight: FontWeights.semiBold,
                            color: AppColor.authButton,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  AppText(
                    '${address.streetAddress}, ${address.city}'
                    '${address.zipCode.isNotEmpty ? ', ${address.zipCode}' : ''}',
                    fontSize: FontSizes.small,
                    color: AppColor.grey,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 10),
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppColor.authButton,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: AppColor.white,
                  size: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Add new address tile ─────────────────────────────────────────────────────
class _AddNewAddressTile extends StatelessWidget {
  final void Function(AddressModel) onAdded;
  const _AddNewAddressTile({required this.onAdded});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showAddSheet(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColor.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColor.lightGrey),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColor.authBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: AppColor.authButton,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  'Add a new address',
                  fontSize: FontSizes.regular,
                  fontWeight: FontWeights.semiBold,
                  color: AppColor.darkGrey,
                ),
                const SizedBox(height: 2),
                AppText(
                  'Add another service location',
                  fontSize: FontSizes.small,
                  color: AppColor.grey,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<AddressProvider>(),
        child: _AddAddressSheet(onSaved: onAdded),
      ),
    );
  }
}

// ─── Bottom bar ───────────────────────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback? onChangeProvider;

  const _BottomBar({
    required this.label,
    required this.enabled,
    required this.onTap,
    this.onChangeProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColor.authBg,
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: enabled
                    ? AppColor.authButton
                    : AppColor.mediumGrey,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: enabled ? onTap : null,
              child: AppText(
                label,
                fontSize: FontSizes.regular,
                fontWeight: FontWeights.semiBold,
                color: AppColor.white,
              ),
            ),
          ),
          if (onChangeProvider != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColor.authButton),
                  foregroundColor: AppColor.authButton,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: onChangeProvider,
                child: AppText(
                  'Change Provider',
                  fontSize: FontSizes.regular,
                  fontWeight: FontWeights.semiBold,
                  color: AppColor.authButton,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Calendar card ────────────────────────────────────────────────────────────
class _CalendarCard extends StatelessWidget {
  final DateTime visibleMonth;
  final DateTime selectedDate;
  final List<String> unavailableDates;
  final void Function(DateTime) onDateSelected;
  final void Function(int delta) onMonthChanged;
  final bool isRescheduling;

  const _CalendarCard({
    required this.visibleMonth,
    required this.selectedDate,
    this.unavailableDates = const [],
    required this.onDateSelected,
    required this.onMonthChanged,
    this.isRescheduling = false,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final maxDate = today.add(const Duration(days: 90));
    final minMonth = DateTime(today.year, today.month);
    final maxMonthLimit = DateTime(maxDate.year, maxDate.month);

    final currentMonth = DateTime(visibleMonth.year, visibleMonth.month);
    final isLeftDisabled =
        currentMonth.isBefore(minMonth) ||
        currentMonth.isAtSameMomentAs(minMonth);
    final isRightDisabled =
        currentMonth.isAfter(maxMonthLimit) ||
        currentMonth.isAtSameMomentAs(maxMonthLimit);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: isLeftDisabled ? null : () => onMonthChanged(-1),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.chevron_left_rounded,
                    color: isLeftDisabled
                        ? AppColor.mediumGrey
                        : AppColor.darkGrey,
                    size: 22,
                  ),
                ),
              ),
              AppText(
                DateFormat('MMMM yyyy').format(visibleMonth),
                fontSize: FontSizes.regular,
                fontWeight: FontWeights.semiBold,
                color: AppColor.darkGrey,
              ),
              GestureDetector(
                onTap: isRightDisabled ? null : () => onMonthChanged(1),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: isRightDisabled
                        ? AppColor.mediumGrey
                        : AppColor.darkGrey,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']
                .map(
                  (d) => Expanded(
                    child: Center(
                      child: AppText(
                        d,
                        fontSize: 11,
                        fontWeight: FontWeights.semiBold,
                        color: AppColor.grey,
                      ),
                    ),
                  ),
                )
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
    final todayMidnight = DateTime(today.year, today.month, today.day);
    final maxDateMidnight = todayMidnight.add(const Duration(days: 90));
    final cells = <Widget>[];

    for (int i = 0; i < startPadding; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (int day = 1; day <= lastDay.day; day++) {
      final date = DateTime(visibleMonth.year, visibleMonth.month, day);
      final isPast = date.isBefore(todayMidnight);
      final isAfterLimit = date.isAfter(maxDateMidnight);

      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final isUnavailable = unavailableDates.contains(dateStr);

      final isDisabled = isPast || isAfterLimit || isUnavailable;
      final isTapEnabled =
          !isPast && !isAfterLimit && (!isUnavailable || isRescheduling);

      final isSelected =
          date.year == selectedDate.year &&
          date.month == selectedDate.month &&
          date.day == selectedDate.day;
      final isToday =
          date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;

      cells.add(
        GestureDetector(
          onTap: isTapEnabled ? () => onDateSelected(date) : null,
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
                fontWeight: isSelected ? FontWeights.bold : FontWeights.regular,
                color: isSelected
                    ? AppColor.white
                    : isDisabled
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

// ─── Add Address Sheet ────────────────────────────────────────────────────────
class _AddAddressSheet extends StatefulWidget {
  final void Function(AddressModel)? onSaved;
  const _AddAddressSheet({this.onSaved});

  @override
  State<_AddAddressSheet> createState() => _AddAddressSheetState();
}

class _AddAddressSheetState extends State<_AddAddressSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _zipCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    final z = StorageManager.readData(StoreKeys.zipCode) as String?;
    if (z != null && z.isNotEmpty) _zipCtrl.text = z;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _streetCtrl.dispose();
    _zipCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    debugPrint("BookingScreen: _useCurrentLocation called");
    setState(() => _isLocating = true);
    try {
      final res = await context.read<AddressProvider>().findMyLocation();
      debugPrint("BookingScreen: findMyLocation result = $res");
      if (res != null) {
        setState(() {
          _streetCtrl.text = res['streetAddress'] ?? '';
          _cityCtrl.text = res['city'] ?? '';
          _zipCtrl.text = res['zipCode'] ?? '';
        });
      }
    } catch (e) {
      debugPrint("BookingScreen: error in _useCurrentLocation = $e");
      if (mounted) {
        FunctionalComponent.showSnackBar(
          context: context,
          title: e.toString().replaceFirst('Exception: ', ''),
          success: false,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }

  Future<void> _selectAddressFromSearch(BuildContext context) async {
    final result = await Navigator.of(context).push<Map<String, String>>(
      MaterialPageRoute(builder: (_) => const AddressSearchScreen()),
    );
    if (result != null && mounted) {
      setState(() {
        _streetCtrl.text = result['streetAddress'] ?? '';
        _cityCtrl.text = result['city'] ?? '';
        _zipCtrl.text = result['zipCode'] ?? '';
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ap = context.read<AddressProvider>();
    final ok = await ap.storeAddress(
      addressName: _nameCtrl.text.trim(),
      streetAddress: _streetCtrl.text.trim(),
      zipCode: _zipCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
    );
    if (!mounted) return;
    if (ok) {
      final addr = ap.addresses.first;
      Navigator.of(context).pop();
      FunctionalComponent.showSnackBar(
        context: context,
        title: 'Address saved!',
        success: true,
      );
      widget.onSaved?.call(addr);
    } else {
      FunctionalComponent.showSnackBar(
        context: context,
        title: ap.saveError,
        success: false,
      );
      ap.resetSave();
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
                child: const Icon(
                  Icons.location_on_rounded,
                  color: AppColor.authButton,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      'Add Your Address',
                      fontSize: FontSizes.medium,
                      fontWeight: FontWeights.bold,
                      color: AppColor.darkGrey,
                    ),
                    AppText(
                      'Required to proceed with booking',
                      fontSize: FontSizes.small,
                      color: AppColor.grey,
                    ),
                  ],
                ),
              ),
              // Find My Location button
              GestureDetector(
                onTap: _isLocating ? null : _useCurrentLocation,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColor.authButton.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _isLocating
                          ? const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                color: AppColor.authButton,
                                strokeWidth: 1.5,
                              ),
                            )
                          : const Icon(
                              Icons.my_location_rounded,
                              color: AppColor.authButton,
                              size: 12,
                            ),
                      const SizedBox(width: 6),
                      AppText(
                        _isLocating ? 'Locating...' : 'Find my location',
                        fontSize: 11,
                        fontWeight: FontWeights.semiBold,
                        color: AppColor.authButton,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Form(
            key: _formKey,
            child: Column(
              children: [
                _Field(
                  ctrl: _nameCtrl,
                  label: 'Address Name',
                  hint: 'e.g. Home, Work',
                  icon: Icons.home_outlined,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                _Field(
                  ctrl: _streetCtrl,
                  label: 'Street Address',
                  hint: 'Tap to search address',
                  icon: Icons.signpost_outlined,
                  readOnly: true,
                  onTap: () => _selectAddressFromSearch(context),
                  suffixIcon: TextButton(
                    onPressed: () => _selectAddressFromSearch(context),
                    child: Text(
                      _streetCtrl.text.isEmpty ? 'Search' : 'Change',
                      style: const TextStyle(
                        color: AppColor.authButton,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _Field(
                        ctrl: _zipCtrl,
                        label: 'ZIP Code',
                        hint: '90210',
                        icon: Icons.pin_drop_outlined,
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _Field(
                        ctrl: _cityCtrl,
                        label: 'City',
                        hint: 'Raleigh',
                        icon: Icons.location_city_outlined,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Consumer<AddressProvider>(
            builder: (_, ap, _) => SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.authButton,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: ap.isSaving ? null : _submit,
                child: ap.isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: AppColor.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : AppText(
                        'Save Address',
                        fontSize: FontSizes.regular,
                        fontWeight: FontWeights.semiBold,
                        color: AppColor.white,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Text field helper ────────────────────────────────────────────────────────
class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String hint;
  final IconData icon;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final void Function(String)? onChanged;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? suffixIcon;

  const _Field({
    required this.ctrl,
    required this.label,
    required this.hint,
    required this.icon,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.readOnly = false,
    this.onTap,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      readOnly: readOnly,
      onTap: onTap,
      style: const TextStyle(fontSize: 14, color: AppColor.darkGrey),
      decoration: InputDecoration(
        label: Text.rich(
          TextSpan(
            text: label,
            children: const [
              TextSpan(
                text: ' *',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: AppColor.grey),
        suffixIcon: suffixIcon,
        labelStyle: const TextStyle(fontSize: 13, color: AppColor.grey),
        hintStyle: const TextStyle(fontSize: 13, color: AppColor.mediumGrey),
        filled: true,
        fillColor: const Color(0xFFF8F8F8),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
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
          borderSide: const BorderSide(color: Colors.red),
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
                color: AppColor.authBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                color: AppColor.authButton,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            AppText(
              'Failed to load',
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
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: AppColor.authButton,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: AppText(
                  'Retry',
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
