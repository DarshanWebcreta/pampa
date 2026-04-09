import 'package:flutter/material.dart';
import 'package:pampa/data/service/apiservice.dart';

class TimeSlot {
  String start;
  String end;

  TimeSlot({required this.start, required this.end});

  TimeSlot copyWith({String? start, String? end}) =>
      TimeSlot(start: start ?? this.start, end: end ?? this.end);

  Map<String, dynamic> toJson() => {'start': start, 'end': end};

  bool isSameAs(TimeSlot other) => start == other.start && end == other.end;

  @override
  String toString() => '$start - $end';
}

class DayAvailability {
  final String day;
  bool isOpen;
  List<TimeSlot> slots;

  DayAvailability({
    required this.day,
    required this.isOpen,
    required this.slots,
  });

  Map<String, dynamic> toJson() => {
    'day': day,
    'is_open': isOpen,
    'slots': slots.map((s) => s.toJson()).toList(),
  };
}

enum AvailabilityStatus { initial, loading, success, error }

enum AvailabilitySaveStatus { idle, loading, done, failed }

class ProviderAvailabilityProvider extends ChangeNotifier {
  static const List<String> days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  final ApiService _api;

  ProviderAvailabilityProvider(this._api);

  AvailabilityStatus _status = AvailabilityStatus.initial;
  AvailabilitySaveStatus _saveStatus = AvailabilitySaveStatus.idle;
  String _error = '';
  String _saveError = '';

  // Ordered list of day availability (matches `days` order)
  late List<DayAvailability> _availability = days
      .map((d) => DayAvailability(day: d, isOpen: false, slots: []))
      .toList();

  AvailabilityStatus get status => _status;
  AvailabilitySaveStatus get saveStatus => _saveStatus;
  String get error => _error;
  String get saveError => _saveError;
  List<DayAvailability> get availability => _availability;

  Future<void> fetchSettings({bool forceRefresh = false}) async {
    if (_status == AvailabilityStatus.loading) return;
    if (!forceRefresh && _status == AvailabilityStatus.success) return;
    _status = AvailabilityStatus.loading;
    _error = '';
    notifyListeners();

    try {
      final response = await _api.getProviderSettings();
      final map = response as Map<String, dynamic>;
      if (map['status'] == true) {
        final data = map['data'] as Map<String, dynamic>? ?? {};
        _parseAvailability(data['availability']);
      }
      _status = AvailabilityStatus.success;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _status = AvailabilityStatus.error;
    }
    notifyListeners();
  }

  void _parseAvailability(dynamic raw) {
    if (raw == null) return;

    Map<String, dynamic> map = {};
    if (raw is Map<String, dynamic>) {
      map = raw;
    } else if (raw is List) {
      // API returns list format: [{day: "Monday", is_open:..., slots:[...]}, ...]
      for (final item in raw) {
        if (item is Map<String, dynamic> && item['day'] != null) {
          map[item['day'].toString()] = item;
        }
      }
    }

    _availability = days.map((day) {
      final dayData = map[day];
      if (dayData == null) {
        return DayAvailability(day: day, isOpen: false, slots: []);
      }
      final isOpen = dayData['is_open'] as bool? ?? false;
      final rawSlots = dayData['slots'] as List<dynamic>? ?? [];
      final slots = rawSlots
          .whereType<Map<String, dynamic>>()
          .map(
            (s) => TimeSlot(
              start: s['start']?.toString() ?? '09:00',
              end: s['end']?.toString() ?? '17:00',
            ),
          )
          .toList();
      return DayAvailability(day: day, isOpen: isOpen, slots: slots);
    }).toList();
  }

  // ── Mutations ────────────────────────────────────────────────────────────────

  void toggleDay(int index) {
    final day = _availability[index];
    day.isOpen = !day.isOpen;
    if (day.isOpen && day.slots.isEmpty) {
      day.slots.add(TimeSlot(start: '09:00', end: '17:00'));
    }
    notifyListeners();
  }

  /// Returns error message if duplicate, null if added successfully.
  String? addSlot(int dayIndex) {
    final day = _availability[dayIndex];
    final newSlot = TimeSlot(start: '09:00', end: '17:00');

    if (_isDuplicate(day.slots, newSlot)) {
      return 'Slot 09:00–17:00 already exists. Change the time first.';
    }

    day.slots.add(newSlot);
    notifyListeners();
    return null;
  }

  void removeSlot(int dayIndex, int slotIndex) {
    _availability[dayIndex].slots.removeAt(slotIndex);
    notifyListeners();
  }

  /// Returns error message if the update would create a duplicate, null on success.
  String? updateSlotStart(int dayIndex, int slotIndex, String start) {
    final slots = _availability[dayIndex].slots;
    final updated = slots[slotIndex].copyWith(start: start);
    final others = [...slots]..removeAt(slotIndex);
    if (_isDuplicate(others, updated)) {
      return 'A slot with these times already exists.';
    }
    slots[slotIndex].start = start;
    notifyListeners();
    return null;
  }

  String? updateSlotEnd(int dayIndex, int slotIndex, String end) {
    final slots = _availability[dayIndex].slots;
    final updated = slots[slotIndex].copyWith(end: end);
    final others = [...slots]..removeAt(slotIndex);
    if (_isDuplicate(others, updated)) {
      return 'A slot with these times already exists.';
    }
    slots[slotIndex].end = end;
    notifyListeners();
    return null;
  }

  bool _isDuplicate(List<TimeSlot> existing, TimeSlot candidate) =>
      existing.any((s) => s.isSameAs(candidate));

  // ── Save ────────────────────────────────────────────────────────────────────

  Future<bool> saveAvailability() async {
    _saveStatus = AvailabilitySaveStatus.loading;
    _saveError = '';
    notifyListeners();

    try {
      final payload = {
        'availabilities': _availability.map((d) => d.toJson()).toList(),
      };
      await _api.updateProviderAvailability(payload);
      _saveStatus = AvailabilitySaveStatus.done;
      notifyListeners();
      return true;
    } catch (e) {
      _saveError = e.toString().replaceFirst('Exception: ', '');
      _saveStatus = AvailabilitySaveStatus.failed;
      notifyListeners();
      return false;
    }
  }

  void resetSaveStatus() {
    _saveStatus = AvailabilitySaveStatus.idle;
    _saveError = '';
    notifyListeners();
  }
}
