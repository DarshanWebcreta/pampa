import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pampa/core/values/colors.dart';
import 'package:pampa/core/widgets/text_widget.dart';
import 'package:pampa/features/provider_home/presentation/provider/provider_dashboard_provider.dart';

class UnavailabilityBottomSheet extends StatefulWidget {
  final Future<ToggleResult> Function(int duration, DateTime startDate) onConfirm;
  final String title;
  final String description;

  const UnavailabilityBottomSheet({
    super.key,
    required this.onConfirm,
    this.title = 'Set Unavailability',
    this.description =
        'Select when you want to start being unavailable and for how long. You won\'t receive new bookings during this period.',
  });

  @override
  State<UnavailabilityBottomSheet> createState() =>
      _UnavailabilityBottomSheetState();
}

class _UnavailabilityBottomSheetState extends State<UnavailabilityBottomSheet> {
  DateTime _startDate = DateTime.now();
  int _duration = 1;
  bool _isLoading = false;
  String? _errorMsg;

  final List<int> _quickDurations = [1, 3, 7, 14, 30];

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
      });
    }
  }

  void _confirm() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    final result = await widget.onConfirm(_duration, _startDate);

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

          // Duration Section
          const Text(
            'Duration (Days)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColor.darkGrey,
            ),
          ),
          const SizedBox(height: 10),

          // Quick selection chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickDurations.map((d) {
              final isSelected = _duration == d;
              return ChoiceChip(
                label: Text('$d ${d == 1 ? 'Day' : 'Days'}'),
                selected: isSelected,

                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColor.darkGrey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 12,
                ),
                selectedColor: AppColor.authButton,
                checkmarkColor: Colors.white,
                backgroundColor: Colors.grey[100],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? AppColor.authButton : Colors.transparent,
                  ),
                ),
                onSelected: _isLoading
                    ? null
                    : (selected) {
                        if (selected) {
                          setState(() {
                            _duration = d;
                          });
                        }
                      },
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // Custom select dropdown
          DropdownButtonFormField<int>(
            key: ValueKey(_duration),
            initialValue: _duration,
            decoration: InputDecoration(
              labelText: 'Custom Duration',
              labelStyle: const TextStyle(color: AppColor.grey, fontSize: 13),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFF0E4E8)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFF0E4E8)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColor.authButton, width: 1.5),
              ),
            ),
            dropdownColor: Colors.white,
            items: List.generate(30, (index) {
              final val = index + 1;
              return DropdownMenuItem<int>(
                value: val,
                child: Text('$val ${val == 1 ? 'Day' : 'Days'}'),
              );
            }),
            onChanged: _isLoading
                ? null
                : (val) {
                    if (val != null) {
                      setState(() {
                        _duration = val;
                      });
                    }
                  },
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
