import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:pampa/core/storage/storage.dart';
import 'package:pampa/core/utils/functional_component.dart';
import 'package:pampa/core/values/app_text_value.dart';
import 'package:pampa/core/values/colors.dart';
import 'package:pampa/core/values/keys.dart';
import 'package:pampa/core/widgets/text_widget.dart';
import 'package:pampa/features/address/data/models/address_model.dart';
import 'package:pampa/features/address/presentation/provider/address_provider.dart';
import 'package:pampa/features/booking/presentation/provider/booking_provider.dart';
import 'package:pampa/features/booking/presentation/booking_review_screen.dart';

// ─── Icon helper for address name ─────────────────────────────────────────────
IconData _iconForAddress(String name) {
  final lower = name.toLowerCase();
  if (lower.contains('home') || lower.contains('house')) return Icons.home_rounded;
  if (lower.contains('work') || lower.contains('office')) return Icons.work_rounded;
  return Icons.location_on_rounded;
}

// ─── Main screen ──────────────────────────────────────────────────────────────
class BookingScreen extends StatefulWidget {
  final int serviceId;
  const BookingScreen({super.key, required this.serviceId});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  int _step = 0; // 0 = address, 1 = date & time
  AddressModel? _selectedAddress;
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);
  String? _selectedTimeDisplay;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final bp = context.read<BookingProvider>();
      final ap = context.read<AddressProvider>();

      bp.fetchServiceDetail(widget.serviceId);
      final savedZip = StorageManager.readData(StoreKeys.zipCode) as String? ?? '';
      bp.fetchProviders(savedZip);
      await ap.fetchAddresses();

      if (!mounted) return;
      if (ap.hasAddresses) {
        final def = ap.addresses.firstWhere(
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

  Future<void> _pickTime(BuildContext context) async {
    final bp = context.read<BookingProvider>();
    final now = DateTime.now();
    final sel = bp.selectedDate;
    final isToday =
        sel.year == now.year && sel.month == now.month && sel.day == now.day;

    final initialTime = isToday
        ? TimeOfDay(hour: now.hour, minute: (now.minute ~/ 15 + 1) * 15 % 60)
        : const TimeOfDay(hour: 9, minute: 0);

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColor.authButton,
            onPrimary: AppColor.white,
            surface: AppColor.white,
            onSurface: AppColor.darkGrey,
          ),
        ),
        child: child!,
      ),
    );

    if (picked == null || !mounted) return;

    if (isToday) {
      final pickedMins = picked.hour * 60 + picked.minute;
      final nowMins = now.hour * 60 + now.minute;
      if (pickedMins <= nowMins) {
        if (!mounted) return;
        // ignore: use_build_context_synchronously
        FunctionalComponent.showSnackBar(
          context: context,
          title: 'Please select a future time for today',
          success: false,
        );
        return;
      }
    }

    final formatted =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    bp.selectTime(formatted);
    final hour = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
    final min = picked.minute.toString().padLeft(2, '0');
    final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
    setState(() => _selectedTimeDisplay = '$hour:$min $period');
  }

  void _onConfirm() {
    final bp = context.read<BookingProvider>();
    if (bp.selectedProvider == null && bp.providers.isNotEmpty) {
      bp.selectProvider(bp.providers.first);
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: bp),
            ChangeNotifierProvider.value(
                value: context.read<AddressProvider>()),
          ],
          child: BookingReviewScreen(address: _selectedAddress!),
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
                    child: CircularProgressIndicator(
                        color: AppColor.authButton)),
              );
            }
            if (provider.fetchStatus == BookingFetchStatus.error) {
              return SafeArea(
                child: _ErrorView(
                  message: provider.fetchError,
                  onRetry: () =>
                      provider.fetchServiceDetail(widget.serviceId),
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
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 20, color: AppColor.darkGrey),
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
                    child: CircularProgressIndicator(
                        color: AppColor.authButton));
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  children: [
                    ...ap.addresses.map((addr) => _AddressTile(
                          address: addr,
                          isSelected: _selectedAddress?.id == addr.id,
                          onTap: () =>
                              setState(() => _selectedAddress = addr),
                        )),
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
                          const Icon(Icons.arrow_back_ios_new_rounded,
                              size: 14, color: AppColor.authButton),
                          const SizedBox(width: 4),
                          AppText('Back',
                              fontSize: FontSizes.small,
                              fontWeight: FontWeights.semiBold,
                              color: AppColor.authButton),
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
                        horizontal: 14, vertical: 8),
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
                  onDateSelected: (date) {
                    provider.selectDate(date);
                    setState(() => _selectedTimeDisplay = null);
                    provider.selectTime('');
                  },
                  onMonthChanged: (delta) => setState(() {
                    _visibleMonth = DateTime(
                        _visibleMonth.year, _visibleMonth.month + delta);
                  }),
                ),
                const SizedBox(height: 24),
                AppText('Select Time',
                    fontSize: FontSizes.medium,
                    fontWeight: FontWeights.bold,
                    color: AppColor.darkGrey),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => _pickTime(context),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColor.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: hasTime
                            ? AppColor.authButton
                            : AppColor.mediumGrey,
                        width: hasTime ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColor.authButton
                                .withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.access_time_rounded,
                              color: AppColor.authButton, size: 18),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: AppText(
                            hasTime
                                ? _selectedTimeDisplay!
                                : 'Tap to select a time',
                            fontSize: FontSizes.regular,
                            fontWeight: hasTime
                                ? FontWeights.semiBold
                                : FontWeights.regular,
                            color: hasTime
                                ? AppColor.darkGrey
                                : AppColor.grey,
                          ),
                        ),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: hasTime
                              ? AppColor.authButton
                              : AppColor.grey,
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        _BottomBar(
          label: 'Continue',
          enabled: hasTime,
          onTap: _onConfirm,
        ),
      ],
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ─── Address tile ─────────────────────────────────────────────────────────────
class _AddressTile extends StatelessWidget {
  final AddressModel address;
  final bool isSelected;
  final VoidCallback onTap;

  const _AddressTile(
      {required this.address,
      required this.isSelected,
      required this.onTap});

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
              child: Icon(_iconForAddress(address.addressName),
                  size: 20,
                  color:
                      isSelected ? AppColor.authButton : AppColor.grey),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AppText(address.addressName,
                            fontSize: FontSizes.regular,
                            maxLines: 5,
                            fontWeight: FontWeights.semiBold,
                            color: AppColor.darkGrey),
                      ),
                      if (address.isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColor.authButton
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: AppText('Default',
                              fontSize: 10,
                              fontWeight: FontWeights.semiBold,
                              color: AppColor.authButton),
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
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                    color: AppColor.authButton, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded,
                    color: AppColor.white, size: 14),
              ),
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
                  borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.add_rounded,
                  color: AppColor.authButton, size: 22),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText('Add a new address',
                    fontSize: FontSizes.regular,
                    fontWeight: FontWeights.semiBold,
                    color: AppColor.darkGrey),
                const SizedBox(height: 2),
                AppText('Add another service location',
                    fontSize: FontSizes.small, color: AppColor.grey),
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
  const _BottomBar(
      {required this.label, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColor.authBg,
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).padding.bottom + 16),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor:
                enabled ? AppColor.authButton : AppColor.mediumGrey,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: enabled ? onTap : null,
          child: AppText(label,
              fontSize: FontSizes.regular,
              fontWeight: FontWeights.semiBold,
              color: AppColor.white),
        ),
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
          color: AppColor.white, borderRadius: BorderRadius.circular(16)),
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
              AppText(DateFormat('MMMM yyyy').format(visibleMonth),
                  fontSize: FontSizes.regular,
                  fontWeight: FontWeights.semiBold,
                  color: AppColor.darkGrey),
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
    final cells = <Widget>[];

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

      cells.add(GestureDetector(
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
            child: AppText('$day',
                fontSize: 13,
                fontWeight: isSelected
                    ? FontWeights.bold
                    : FontWeights.regular,
                color: isSelected
                    ? AppColor.white
                    : isPast
                        ? AppColor.mediumGrey
                        : AppColor.darkGrey),
          ),
        ),
      ));
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
      final addr = ap.addresses.last;
      Navigator.of(context).pop();
      FunctionalComponent.showSnackBar(
          context: context,
          title: 'Address saved!',
          success: true);
      widget.onSaved?.call(addr);
    } else {
      FunctionalComponent.showSnackBar(
          context: context, title: ap.saveError, success: false);
      ap.resetSave();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          color: AppColor.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24),
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
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                  color: AppColor.authBg, shape: BoxShape.circle),
              child: const Icon(Icons.location_on_rounded,
                  color: AppColor.authButton, size: 20),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              AppText('Add Your Address',
                  fontSize: FontSizes.medium,
                  fontWeight: FontWeights.bold,
                  color: AppColor.darkGrey),
              AppText('Required to proceed with booking',
                  fontSize: FontSizes.small, color: AppColor.grey),
            ]),
          ]),
          const SizedBox(height: 24),
          Form(
            key: _formKey,
            child: Column(children: [
              _Field(
                  ctrl: _nameCtrl,
                  label: 'Address Name',
                  hint: 'e.g. Home, Work',
                  icon: Icons.home_outlined,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Required'
                      : null),
              const SizedBox(height: 14),
              _Field(
                  ctrl: _streetCtrl,
                  label: 'Street Address',
                  hint: '742 Evergreen Terrace',
                  icon: Icons.signpost_outlined,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Required'
                      : null),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                  child: _Field(
                      ctrl: _zipCtrl,
                      label: 'ZIP Code',
                      hint: '90210',
                      icon: Icons.pin_drop_outlined,
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Required'
                          : null),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Field(
                      ctrl: _cityCtrl,
                      label: 'City',
                      hint: 'Raleigh',
                      icon: Icons.location_city_outlined,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Required'
                          : null),
                ),
              ]),
            ]),
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
                        borderRadius: BorderRadius.circular(14))),
                onPressed: ap.isSaving ? null : _submit,
                child: ap.isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: AppColor.white, strokeWidth: 2.5))
                    : AppText('Save Address',
                        fontSize: FontSizes.regular,
                        fontWeight: FontWeights.semiBold,
                        color: AppColor.white),
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

  const _Field({
    required this.ctrl,
    required this.label,
    required this.hint,
    required this.icon,
    this.validator,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: AppColor.darkGrey),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: AppColor.grey),
        labelStyle: const TextStyle(fontSize: 13, color: AppColor.grey),
        hintStyle:
            const TextStyle(fontSize: 13, color: AppColor.mediumGrey),
        filled: true,
        fillColor: const Color(0xFFF8F8F8),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColor.lightGrey)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColor.lightGrey)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
                color: AppColor.authButton, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: Colors.red, width: 1.5)),
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
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 13),
                decoration: BoxDecoration(
                    color: AppColor.authButton,
                    borderRadius: BorderRadius.circular(10)),
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
