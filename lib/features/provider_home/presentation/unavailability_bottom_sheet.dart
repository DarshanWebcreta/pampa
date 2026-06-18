import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pampa/core/values/colors.dart';
import 'package:pampa/core/widgets/text_widget.dart';
import 'package:pampa/features/provider_home/data/models/provider_dashboard_model.dart';
import 'package:pampa/features/provider_home/presentation/provider/provider_dashboard_provider.dart';

class UnavailabilityBottomSheet extends StatefulWidget {
  final Future<ToggleResult> Function(DateTime endDate, DateTime startDate) onConfirm;
  final String title;
  final String description;
  final List<VacationModel> existingVacations;

  const UnavailabilityBottomSheet({
    super.key,
    required this.onConfirm,
    this.title = 'Set Unavailability',
    this.description =
        'Select when you want to start being unavailable and the end date. You won\'t receive new bookings during this period.',
    this.existingVacations = const [],
  });

  @override
  State<UnavailabilityBottomSheet> createState() =>
      _UnavailabilityBottomSheetState();
}

class _UnavailabilityBottomSheetState extends State<UnavailabilityBottomSheet> {
  late DateTime _startDate;
  late DateTime _endDate;
  bool _isLoading = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _startDate = _firstSelectableDate(today);
    _endDate = _startDate;
  }

  bool _isSelectableDate(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    for (final v in widget.existingVacations) {
      final start = DateTime.tryParse(v.startDate);
      final end = DateTime.tryParse(v.endDate);
      if (start != null && end != null) {
        final startOnly = DateTime(start.year, start.month, start.day);
        final endOnly = DateTime(end.year, end.month, end.day);
        if (dateOnly.isAtSameMomentAs(startOnly) ||
            dateOnly.isAtSameMomentAs(endOnly) ||
            (dateOnly.isAfter(startOnly) && dateOnly.isBefore(endOnly))) {
          return false;
        }
      }
    }
    return true;
  }

  DateTime _firstSelectableDate(DateTime startFrom) {
    DateTime check = startFrom;
    while (!_isSelectableDate(check)) {
      check = check.add(const Duration(days: 1));
    }
    return check;
  }

  bool _hasOverlappingVacation() {
    final s1 = DateTime(_startDate.year, _startDate.month, _startDate.day);
    final e1 = DateTime(_endDate.year, _endDate.month, _endDate.day);

    for (final v in widget.existingVacations) {
      final start = DateTime.tryParse(v.startDate);
      final end = DateTime.tryParse(v.endDate);
      if (start != null && end != null) {
        final s2 = DateTime(start.year, start.month, start.day);
        final e2 = DateTime(end.year, end.month, end.day);

        if (!s1.isAfter(e2) && !e1.isBefore(s2)) {
          return true;
        }
      }
    }
    return false;
  }

  void _checkOverlapRealtime() {
    if (_hasOverlappingVacation()) {
      setState(() {
        _errorMsg = 'Selected date range overlaps with an existing scheduled vacation.';
      });
    } else {
      setState(() {
        _errorMsg = null;
      });
    }
  }

  int get _totalOfflineDays {
    return _endDate.difference(_startDate).inDays + 1;
  }

  Future<void> _selectStartDate() async {
    final initial = _firstSelectableDate(_startDate);
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(minutes: 5)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      selectableDayPredicate: _isSelectableDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColor.authButton,
              onPrimary: Colors.white,
              onSurface: AppColor.darkGrey,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() {
        _startDate = date;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate;
        } else if (_endDate.difference(_startDate).inDays > 29) {
          _endDate = _startDate.add(const Duration(days: 29));
        }
      });
      _checkOverlapRealtime();
    }
  }

  Future<void> _selectEndDate() async {
    final maxEndDate = _startDate.add(const Duration(days: 29));
    DateTime initial = _endDate.isBefore(_startDate) ? _startDate : (_endDate.isAfter(maxEndDate) ? maxEndDate : _endDate);
    initial = _firstSelectableDate(initial);
    if (initial.isAfter(maxEndDate)) {
      initial = _firstSelectableDate(_startDate);
    }

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: _startDate,
      lastDate: maxEndDate,
      selectableDayPredicate: _isSelectableDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColor.authButton,
              onPrimary: Colors.white,
              onSurface: AppColor.darkGrey,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() {
        _endDate = date;
      });
      _checkOverlapRealtime();
    }
  }

  void _confirm() async {
    if (_hasOverlappingVacation()) {
      setState(() {
        _errorMsg = 'Selected date range overlaps with an existing scheduled vacation.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    final result = await widget.onConfirm(_endDate, _startDate);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      if (!result.success) {
        setState(() {
          _errorMsg = result.message;
        });
      } else {
        Navigator.pop(context, result.message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(
        top: 8,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                widget.title,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColor.darkGrey,
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 22),
                onPressed: _isLoading ? null : () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Text(
            widget.description,
            style: const TextStyle(
              fontSize: 13,
              color: AppColor.grey,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // Start Date Selection
          const Text(
            'Start Date',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColor.darkGrey,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _isLoading ? null : _selectStartDate,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFF0E4E8)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_month_outlined,
                        color: AppColor.authButton,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('EEEE, MMMM dd, yyyy').format(_startDate),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColor.darkGrey,
                        ),
                      ),
                    ],
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColor.grey,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // End Date Selection
          const Text(
            'End Date',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColor.darkGrey,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _isLoading ? null : _selectEndDate,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFF0E4E8)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_month_outlined,
                        color: AppColor.authButton,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('EEEE, MMMM dd, yyyy').format(_endDate),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColor.darkGrey,
                        ),
                      ),
                    ],
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColor.grey,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Total Offline Days Summary Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF0E4E8)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColor.authButton.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.date_range_rounded,
                    color: AppColor.authButton,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Offline Days',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColor.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$_totalOfflineDays ${_totalOfflineDays == 1 ? 'Day' : 'Days'}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColor.darkGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Error Message Display
          if (_errorMsg != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[100]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: Colors.red, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMsg!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Actions
          Row(
            spacing: 12,
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFF0E4E8)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: AppColor.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _confirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.authButton,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Confirm',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
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
