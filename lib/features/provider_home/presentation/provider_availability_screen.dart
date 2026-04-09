import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pampa/core/utils/functional_component.dart';
import 'package:pampa/core/values/app_text_value.dart';
import 'package:pampa/core/values/colors.dart';
import 'package:pampa/core/widgets/text_widget.dart';
import 'package:pampa/features/provider_home/presentation/provider/provider_availability_provider.dart';

class ProviderAvailabilityScreen extends StatefulWidget {
  const ProviderAvailabilityScreen({super.key});

  @override
  State<ProviderAvailabilityScreen> createState() =>
      _ProviderAvailabilityScreenState();
}

class _ProviderAvailabilityScreenState
    extends State<ProviderAvailabilityScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProviderAvailabilityProvider>().fetchSettings();
    });
  }

  Future<void> _save() async {
    final provider = context.read<ProviderAvailabilityProvider>();
    final ok = await provider.saveAvailability();
    if (!mounted) return;

    if (ok) {
      FunctionalComponent.showSnackBar(
        context: context,
        title: 'Availability updated successfully.',
        success: true,
      );
      Navigator.of(context).pop();
    } else {
      FunctionalComponent.showSnackBar(
        context: context,
        title: provider.saveError.isNotEmpty
            ? provider.saveError
            : 'Failed to save. Please try again.',
        success: false,
      );
      provider.resetSaveStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProviderAvailabilityProvider>(
      builder: (context, provider, _) {
        final isSaving =
            provider.saveStatus == AvailabilitySaveStatus.loading;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 18, color: AppColor.darkGrey),
            ),
            title: AppText(
              'Availability',
              fontSize: FontSizes.medium,
              fontWeight: FontWeights.bold,
              color: AppColor.darkGrey,
            ),
            centerTitle: false,
          ),
          body: provider.status == AvailabilityStatus.loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColor.authButton))
              : provider.status == AvailabilityStatus.error
                  ? _ErrorBody(
                      message: provider.error,
                      onRetry: provider.fetchSettings,
                    )
                  : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Header ─────────────────────────────────────────
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText(
                                'Set your availability',
                                fontSize: 20,
                                fontWeight: FontWeights.bold,
                                color: AppColor.darkGrey,
                              ),
                              const SizedBox(height: 4),
                              AppText(
                                'Clients can only book during open hours.',
                                fontSize: FontSizes.small,
                                color: AppColor.grey,
                              ),
                             
                            ],
                          ),
                        ),

                        // ── Day list ───────────────────────────────────────
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
                            itemCount: provider.availability.length,
                            separatorBuilder: (_, __) => const Divider(
                              height: 1,
                              thickness: 1,
                              color: Color(0xFFF4EBEE),
                              indent: 20,
                              endIndent: 20,
                            ),
                            itemBuilder: (context, i) => _DayTile(
                              dayIndex: i,
                              provider: provider,
                            ),
                          ),
                        ),

                        // ── Save button ────────────────────────────────────
                        SafeArea(
                          top: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                            child: SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: isSaving ? null : _save,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColor.authButton,
                                  disabledBackgroundColor:
                                      AppColor.authButton.withValues(alpha: 0.6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 0,
                                ),
                                child: isSaving
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation(
                                              AppColor.white),
                                        ),
                                      )
                                    : AppText(
                                        'Save Availability',
                                        fontSize: FontSizes.regular,
                                        fontWeight: FontWeights.semiBold,
                                        color: AppColor.white,
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
        );
      },
    );
  }
}

// ─── Day tile ─────────────────────────────────────────────────────────────────

class _DayTile extends StatelessWidget {
  final int dayIndex;
  final ProviderAvailabilityProvider provider;

  const _DayTile({required this.dayIndex, required this.provider});

  @override
  Widget build(BuildContext context) {
    final day = provider.availability[dayIndex];

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Day row ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                AppText(
                  day.day,
                  fontSize: FontSizes.regular,
                  fontWeight: FontWeights.medium,
                  color: AppColor.darkGrey,
                ),
                const Spacer(),
                Switch.adaptive(
                  value: day.isOpen,
                  onChanged: (_) => provider.toggleDay(dayIndex),
                  activeTrackColor: AppColor.authButton,
                ),
              ],
            ),
          ),

          // ── Slots ────────────────────────────────────────────────────────
          if (day.isOpen) ...[
            ...List.generate(
              day.slots.length,
              (si) => _SlotRow(
                dayIndex: dayIndex,
                slotIndex: si,
                slot: day.slots[si],
                provider: provider,
              ),
            ),

            // Add slot button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: GestureDetector(
                onTap: () {
                  final err = provider.addSlot(dayIndex);
                  if (err != null && context.mounted) {
                    FunctionalComponent.showSnackBar(
                      context: context,
                      title: err,
                      success: false,
                    );
                  }
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: AppColor.authButton.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add_rounded,
                          size: 14, color: AppColor.authButton),
                    ),
                    const SizedBox(width: 6),
                    AppText(
                      'Add time slot',
                      fontSize: FontSizes.small,
                      fontWeight: FontWeights.medium,
                      color: AppColor.authButton,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Time picker bottom sheet ─────────────────────────────────────────────────

int _timeToMinutes(String t) {
  final p = t.split(':');
  return int.parse(p[0]) * 60 + int.parse(p[1]);
}

// All 30-min slots — used only for overlap calculation in _SlotRow
List<String> _allTimeOptions() {
  final list = <String>[];
  for (int h = 0; h < 24; h++) {
    for (final m in [0, 30]) {
      list.add(
          '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}');
    }
  }
  return list;
}

Future<String?> _showTimePicker(
  BuildContext context, {
  required String currentValue,
  required Set<String> disabledTimes,
  String? minAfter,
}) async {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _TimePickerSheet(
      currentValue: currentValue,
      disabledTimes: disabledTimes,
      minAfter: minAfter,
    ),
  );
}

class _TimePickerSheet extends StatefulWidget {
  final String currentValue;
  final Set<String> disabledTimes;
  final String? minAfter;

  const _TimePickerSheet({
    required this.currentValue,
    required this.disabledTimes,
    this.minAfter,
  });

  @override
  State<_TimePickerSheet> createState() => _TimePickerSheetState();
}

class _TimePickerSheetState extends State<_TimePickerSheet> {
  static const List<int> _minutes = [0, 30];

  late int _hour;
  late int _minuteIdx; // 0 → "00", 1 → "30"

  late FixedExtentScrollController _hourCtrl;
  late FixedExtentScrollController _minCtrl;

  @override
  void initState() {
    super.initState();
    final parts = widget.currentValue.split(':');
    _hour = int.tryParse(parts[0]) ?? 0;
    final rawMin = int.tryParse(parts[1]) ?? 0;
    _minuteIdx = rawMin >= 30 ? 1 : 0;

    _hourCtrl = FixedExtentScrollController(initialItem: _hour);
    _minCtrl = FixedExtentScrollController(initialItem: _minuteIdx);
  }

  @override
  void dispose() {
    _hourCtrl.dispose();
    _minCtrl.dispose();
    super.dispose();
  }

  String get _selectedTime =>
      '${_hour.toString().padLeft(2, '0')}:${_minutes[_minuteIdx].toString().padLeft(2, '0')}';

  bool get _isSelectedDisabled {
    final t = _selectedTime;
    if (widget.disabledTimes.contains(t)) return true;
    if (widget.minAfter != null &&
        _timeToMinutes(t) <= _timeToMinutes(widget.minAfter!)) {
      return true;
    }
    return false;
  }

  String get _errorLabel {
    if (widget.minAfter != null &&
        _timeToMinutes(_selectedTime) <= _timeToMinutes(widget.minAfter!)) {
      return 'Must be after ${widget.minAfter}';
    }
    if (widget.disabledTimes.contains(_selectedTime)) {
      return 'This time overlaps an existing slot';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final disabled = _isSelectedDisabled;
    final error = _errorLabel;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle ──────────────────────────────────────────────────────
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFDDD0D5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                AppText(
                  'Select Time',
                  fontSize: FontSizes.medium,
                  fontWeight: FontWeights.bold,
                  color: AppColor.darkGrey,
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4EBEE),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded,
                        size: 16, color: AppColor.grey),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Drum roll pickers ────────────────────────────────────────────
          SizedBox(
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Selection highlight
                Center(
                  child: Container(
                    height: 48,
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    decoration: BoxDecoration(
                      color: AppColor.authButton.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: disabled
                            ? const Color(0xFFFF3B5C).withValues(alpha: 0.3)
                            : AppColor.authButton.withValues(alpha: 0.25),
                      ),
                    ),
                  ),
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ── Hour wheel ─────────────────────────────────────────
                    SizedBox(
                      width: 90,
                      child: ListWheelScrollView.useDelegate(
                        controller: _hourCtrl,
                        itemExtent: 48,
                        perspective: 0.003,
                        diameterRatio: 1.5,
                        physics: const FixedExtentScrollPhysics(),
                        onSelectedItemChanged: (i) =>
                            setState(() => _hour = i),
                        childDelegate: ListWheelChildBuilderDelegate(
                          childCount: 24,
                          builder: (ctx, i) {
                            final isCenter = i == _hour;
                            return Center(
                              child: Text(
                                i.toString().padLeft(2, '0'),
                                style: TextStyle(
                                  fontSize: isCenter ? 28 : 20,
                                  fontWeight: isCenter
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  color: isCenter
                                      ? (disabled
                                          ? const Color(0xFFFF3B5C)
                                          : AppColor.authButton)
                                      : AppColor.grey.withValues(alpha: 0.5),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // Colon
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        ':',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: disabled
                              ? const Color(0xFFFF3B5C)
                              : AppColor.darkGrey,
                        ),
                      ),
                    ),

                    // ── Minute wheel ───────────────────────────────────────
                    SizedBox(
                      width: 90,
                      child: ListWheelScrollView.useDelegate(
                        controller: _minCtrl,
                        itemExtent: 48,
                        perspective: 0.003,
                        diameterRatio: 1.5,
                        physics: const FixedExtentScrollPhysics(),
                        onSelectedItemChanged: (i) =>
                            setState(() => _minuteIdx = i),
                        childDelegate: ListWheelChildBuilderDelegate(
                          childCount: _minutes.length,
                          builder: (ctx, i) {
                            final isCenter = i == _minuteIdx;
                            return Center(
                              child: Text(
                                _minutes[i].toString().padLeft(2, '0'),
                                style: TextStyle(
                                  fontSize: isCenter ? 28 : 20,
                                  fontWeight: isCenter
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  color: isCenter
                                      ? (disabled
                                          ? const Color(0xFFFF3B5C)
                                          : AppColor.authButton)
                                      : AppColor.grey.withValues(alpha: 0.5),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Error label ──────────────────────────────────────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: error.isNotEmpty
                ? Padding(
                    key: const ValueKey('err'),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            size: 14, color: Color(0xFFFF3B5C)),
                        const SizedBox(width: 5),
                        Text(
                          error,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFFF3B5C),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox(key: ValueKey('no-err'), height: 24),
          ),

          // ── Confirm button ───────────────────────────────────────────────
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed:
                      disabled ? null : () => Navigator.of(context).pop(_selectedTime),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.authButton,
                    disabledBackgroundColor:
                        const Color(0xFFCCBBC1),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text(
                    disabled ? 'Invalid time' : 'Confirm  $_selectedTime',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Slot row ─────────────────────────────────────────────────────────────────

class _SlotRow extends StatelessWidget {
  final int dayIndex;
  final int slotIndex;
  final TimeSlot slot;
  final ProviderAvailabilityProvider provider;

  const _SlotRow({
    required this.dayIndex,
    required this.slotIndex,
    required this.slot,
    required this.provider,
  });

  List<TimeSlot> get _otherSlots {
    final slots = provider.availability[dayIndex].slots;
    return [
      for (int i = 0; i < slots.length; i++)
        if (i != slotIndex) slots[i],
    ];
  }

  /// Disable any time that falls within an existing slot's range [start, end).
  /// You cannot START a new slot inside another slot.
  Set<String> _disabledStartTimes() {
    final disabled = <String>{};
    for (final other in _otherSlots) {
      final sMin = _timeToMinutes(other.start);
      final eMin = _timeToMinutes(other.end);
      for (final t in _allTimeOptions()) {
        final tMin = _timeToMinutes(t);
        if (tMin >= sMin && tMin < eMin) disabled.add(t);
      }
    }
    return disabled;
  }

  /// Disable:
  ///  1. Times within another slot (start, end].
  ///  2. Times >= the nearest other slot's start that comes after our start
  ///     — prevents our end from leaping over another slot entirely.
  Set<String> _disabledEndTimes() {
    final disabled = <String>{};
    final myStartMin = _timeToMinutes(slot.start);

    for (final other in _otherSlots) {
      final sMin = _timeToMinutes(other.start);
      final eMin = _timeToMinutes(other.end);

      // Block times inside the other slot
      for (final t in _allTimeOptions()) {
        final tMin = _timeToMinutes(t);
        if (tMin > sMin && tMin <= eMin) disabled.add(t);
      }

      // Block times at-or-after the other slot's start when that slot
      // begins after our own start (we'd overlap it).
      if (sMin > myStartMin) {
        for (final t in _allTimeOptions()) {
          if (_timeToMinutes(t) >= sMin) disabled.add(t);
        }
      }
    }
    return disabled;
  }

  Future<void> _pickStart(BuildContext context) async {
    final picked = await _showTimePicker(
      context,
      currentValue: slot.start,
      disabledTimes: _disabledStartTimes(),
    );
    if (picked == null || !context.mounted) return;
    final err = provider.updateSlotStart(dayIndex, slotIndex, picked);
    if (err != null && context.mounted) {
      FunctionalComponent.showSnackBar(
          context: context, title: err, success: false);
    }
  }

  Future<void> _pickEnd(BuildContext context) async {
    final picked = await _showTimePicker(
      context,
      currentValue: slot.end,
      disabledTimes: _disabledEndTimes(),
      minAfter: slot.start,
    );
    if (picked == null || !context.mounted) return;
    final err = provider.updateSlotEnd(dayIndex, slotIndex, picked);
    if (err != null && context.mounted) {
      FunctionalComponent.showSnackBar(
          context: context, title: err, success: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F2F4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF0E4E8)),
        ),
        child: Row(
          children: [
            // Start time
            Expanded(
              child: GestureDetector(
                onTap: () => _pickStart(context),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFF0E4E8)),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.access_time_rounded,
                          size: 12, color: AppColor.authButton),
                      const SizedBox(width: 4),
                      AppText(
                        slot.start,
                        fontSize: FontSizes.regular,
                        fontWeight: FontWeights.semiBold,
                        color: AppColor.darkGrey,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: AppText('to', fontSize: 11, color: AppColor.grey),
            ),

            // End time
            Expanded(
              child: GestureDetector(
                onTap: () => _pickEnd(context),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFF0E4E8)),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.access_time_rounded,
                          size: 12, color: AppColor.authButton),
                      const SizedBox(width: 4),
                      AppText(
                        slot.end,
                        fontSize: FontSizes.regular,
                        fontWeight: FontWeights.semiBold,
                        color: AppColor.darkGrey,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Delete slot
            GestureDetector(
              onTap: () => provider.removeSlot(dayIndex, slotIndex),
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFF0E4E8)),
                ),
                child: const Icon(Icons.close_rounded,
                    size: 16, color: Color(0xFFFF3B5C)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Error body ───────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBody({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 48, color: AppColor.authButton),
            const SizedBox(height: 16),
            AppText(
              message.isNotEmpty ? message : 'Failed to load availability.',
              fontSize: FontSizes.small,
              color: AppColor.grey,
              align: TextAlign.center,
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.authButton,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: AppText(
                'Try Again',
                fontSize: FontSizes.regular,
                fontWeight: FontWeights.semiBold,
                color: AppColor.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
