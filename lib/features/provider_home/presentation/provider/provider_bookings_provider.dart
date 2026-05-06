import 'package:flutter/material.dart';
import 'package:pampa/data/service/apiservice.dart';
import 'package:pampa/features/provider_home/data/models/provider_booking_model.dart';

class ProviderBookingsProvider extends ChangeNotifier {
  final ApiService _api;

  ProviderBookingsProvider(this._api);

  List<ProviderBookingModel> _bookings = [];
  bool _loading = false;
  String _error = '';
  String _selectedStatus = 'all';
  DateTime? _selectedDate;

  List<ProviderBookingModel> get bookings => _bookings;
  bool get loading => _loading;
  String get error => _error;
  String get selectedStatus => _selectedStatus;
  DateTime? get selectedDate => _selectedDate;

  static const statuses = ['all', 'Pending', 'Confirmed', 'Completed', 'Cancelled', 'Past'];

  Future<void> fetch() async {
    _loading = true;
    _error = '';
    notifyListeners();

    try {
      final statusParam = (_selectedStatus == 'all' || _selectedStatus == 'Past') ? null : _selectedStatus;
      final dateParam = _selectedDate != null
          ? '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}'
          : null;

      final response = await _api.getProviderBookings(
        status: statusParam,
        date: dateParam,
      );
      final map = response as Map<String, dynamic>;
      if (map['status'] == true) {
        final list = map['data'] as List<dynamic>? ?? [];
        _bookings = list
            .map((b) => ProviderBookingModel.fromJson(b as Map<String, dynamic>))
            .toList();

        // ── Local Filtering Fallback ──────────────────────────────────
        
        // 1. Handle "Past" custom status
        if (_selectedStatus == 'Past') {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          _bookings = _bookings.where((b) {
            final dt = DateTime.tryParse(b.appointmentDate);
            return dt != null && dt.isBefore(today);
          }).toList();
        } 
        // 2. Handle other specific statuses (safety check)
        else if (_selectedStatus != 'all') {
          _bookings = _bookings.where((b) => 
            b.status.toLowerCase() == _selectedStatus.toLowerCase()
          ).toList();
        }

        // 3. Handle Date filter (safety check)
        if (_selectedDate != null) {
          final ds = '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';
          _bookings = _bookings.where((b) => b.appointmentDate == ds).toList();
        }
      } else {
        _error = map['message'] as String? ?? 'Failed to load bookings.';
      }
    } catch (_) {
      _error = 'Failed to load bookings. Please try again.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Reset filters to defaults (All / no date) and reload.
  Future<void> resetAndFetch() async {
    _selectedStatus = 'all';
    _selectedDate = null;
    notifyListeners();
    await fetch();
  }

  void setStatus(String status) {
    if (_selectedStatus == status) return;
    _selectedStatus = status;
    notifyListeners();
    fetch();
  }

  void setDate(DateTime? date) {
    _selectedDate = date;
    notifyListeners();
    fetch();
  }

  void clearDate() => setDate(null);

  void clearSession() {
    _bookings = [];
    _loading = false;
    _error = '';
    _selectedStatus = 'all';
    _selectedDate = null;
    notifyListeners();
  }
}
