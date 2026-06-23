import 'package:flutter/material.dart';
import 'package:pampa/features/my_bookings/data/models/my_booking_model.dart';
import 'package:pampa/features/my_bookings/domain/repositories/my_bookings_repository.dart';

enum MyBookingsFetchStatus { initial, loading, success, empty, error }

enum AppointmentTab { upcoming, past }

enum BookingDetailStatus { initial, loading, success, error }

enum BookingActionStatus { idle, loading, done, failed }

class MyBookingsProvider extends ChangeNotifier {
  final MyBookingsRepository _repository;

  MyBookingsProvider(this._repository);

  // ── List state ────────────────────────────────────────────────────────────────
  MyBookingsFetchStatus _status = MyBookingsFetchStatus.initial;
  List<MyBookingModel> _allBookings = [];
  String _error = '';
  AppointmentTab _activeTab = AppointmentTab.upcoming;

  MyBookingsFetchStatus get status => _status;
  String get error => _error;
  AppointmentTab get activeTab => _activeTab;

  DateTime? _selectedDate;
  DateTime? get selectedDate => _selectedDate;

  List<MyBookingModel> get upcomingBookings {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _allBookings.where((b) {
      // Not completed, not cancelled, and date is today or future
      final isStatusUpcoming = !b.isCompleted && !b.isCancelled;
      final isDateUpcoming = !b.appointmentDate.isBefore(today);
      return isStatusUpcoming && isDateUpcoming;
    }).toList();
  }

  List<MyBookingModel> get pastBookings {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _allBookings.where((b) {
      // Completed, OR date is in the past
      final isStatusPast = b.isCompleted;
      final isDatePast = b.appointmentDate.isBefore(today);
      return isStatusPast || isDatePast;
    }).toList();
  }

  List<MyBookingModel> get bookings {
    var list = _activeTab == AppointmentTab.upcoming ? upcomingBookings : pastBookings;
    
    if (_selectedDate != null) {
      list = list.where((b) =>
        b.appointmentDate.year == _selectedDate!.year &&
        b.appointmentDate.month == _selectedDate!.month &&
        b.appointmentDate.day == _selectedDate!.day
      ).toList();
    }
    
    return list;
  }

  void setSelectedDate(DateTime? date) {
    _selectedDate = date;
    notifyListeners();
  }

  Future<void> fetchBookings() async {
    if (_status == MyBookingsFetchStatus.loading) return;

    _status = MyBookingsFetchStatus.loading;
    _error = '';
    notifyListeners();

    try {
      _allBookings = await _repository.getBookings();
      _status = _allBookings.isEmpty
          ? MyBookingsFetchStatus.empty
          : MyBookingsFetchStatus.success;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _status = MyBookingsFetchStatus.error;
    }

    notifyListeners();
  }

  void setTab(AppointmentTab tab) {
    if (_activeTab == tab) return;
    _activeTab = tab;
    notifyListeners();
  }

  Future<void> refresh() async {
    _status = MyBookingsFetchStatus.initial;
    await fetchBookings();
  }

  // ── Detail state ──────────────────────────────────────────────────────────────
  BookingDetailStatus _detailStatus = BookingDetailStatus.initial;
  MyBookingModel? _detailBooking;
  String _detailError = '';

  BookingActionStatus _cancelStatus = BookingActionStatus.idle;
  String _cancelError = '';

  BookingActionStatus _payStatus = BookingActionStatus.idle;
  String _payError = '';
  int? _activePayTargetId;

  BookingActionStatus _rescheduleStatus = BookingActionStatus.idle;
  String _rescheduleError = '';

  BookingDetailStatus get detailStatus => _detailStatus;
  MyBookingModel? get detailBooking => _detailBooking;
  String get detailError => _detailError;
  BookingActionStatus get cancelStatus => _cancelStatus;
  String get cancelError => _cancelError;
  BookingActionStatus get payStatus => _payStatus;
  String get payError => _payError;
  int? get activePayTargetId => _activePayTargetId;
  BookingActionStatus get rescheduleStatus => _rescheduleStatus;
  String get rescheduleError => _rescheduleError;

  Future<void> fetchBookingDetail(int id) async {
    _detailStatus = BookingDetailStatus.loading;
    _detailError = '';
    notifyListeners();

    try {
      _detailBooking = await _repository.getBookingDetail(id);
      _detailStatus = BookingDetailStatus.success;
    } catch (e) {
      _detailError = e.toString().replaceFirst('Exception: ', '');
      _detailStatus = BookingDetailStatus.error;
    }

    notifyListeners();
  }

  Future<bool> cancelBooking(int id) async {
    _cancelStatus = BookingActionStatus.loading;
    _cancelError = '';
    notifyListeners();

    try {
      await _repository.cancelBooking(id);
      _cancelStatus = BookingActionStatus.done;
      notifyListeners();
      await fetchBookings();
      return true;
    } catch (e) {
      _cancelError = e.toString().replaceFirst('Exception: ', '');
      _cancelStatus = BookingActionStatus.failed;
      notifyListeners();
      return false;
    }
  }

  Future<String?> payBalance(int bookingId) async {
    _payStatus = BookingActionStatus.loading;
    _payError = '';
    _activePayTargetId = bookingId;
    notifyListeners();

    try {
      final url = await _repository.payBalance(bookingId);
      _payStatus = BookingActionStatus.done;
      notifyListeners();
      return url;
    } catch (e) {
      _payError = e.toString().replaceFirst('Exception: ', '');
      _payStatus = BookingActionStatus.failed;
      notifyListeners();
      return null;
    }
  }

  Future<String?> retryPayment(int paymentId) async {
    _payStatus = BookingActionStatus.loading;
    _payError = '';
    _activePayTargetId = paymentId;
    notifyListeners();

    try {
      final url = await _repository.retryPayment(paymentId);
      _payStatus = BookingActionStatus.done;
      notifyListeners();
      return url;
    } catch (e) {
      _payError = e.toString().replaceFirst('Exception: ', '');
      _payStatus = BookingActionStatus.failed;
      notifyListeners();
      return null;
    }
  }

  Future<bool> rescheduleBooking({
    required int bookingId,
    required String date,
    required String time,
    int? providerId,
  }) async {
    _rescheduleStatus = BookingActionStatus.loading;
    _rescheduleError = '';
    notifyListeners();

    try {
      final success = await _repository.rescheduleBooking(bookingId, date, time, providerId: providerId);
      if (success) {
        _rescheduleStatus = BookingActionStatus.done;
        notifyListeners();
        return true;
      }
      _rescheduleError = 'Failed to reschedule booking.';
      _rescheduleStatus = BookingActionStatus.failed;
      notifyListeners();
      return false;
    } catch (e) {
      _rescheduleError = e.toString().replaceFirst('Exception: ', '');
      _rescheduleStatus = BookingActionStatus.failed;
      notifyListeners();
      return false;
    }
  }

  void resetDetailStatus() {
    _detailStatus = BookingDetailStatus.initial;
    _detailBooking = null;
    notifyListeners();
  }

  void resetCancelStatus() {
    _cancelStatus = BookingActionStatus.idle;
    _cancelError = '';
    notifyListeners();
  }

  void resetPayStatus() {
    _payStatus = BookingActionStatus.idle;
    _payError = '';
    _activePayTargetId = null;
    notifyListeners();
  }

  void clearSession() {
    _status = MyBookingsFetchStatus.initial;
    _allBookings = [];
    _error = '';
    _activeTab = AppointmentTab.upcoming;

    _detailStatus = BookingDetailStatus.initial;
    _detailBooking = null;
    _detailError = '';

    _cancelStatus = BookingActionStatus.idle;
    _cancelError = '';

    _payStatus = BookingActionStatus.idle;
    _payError = '';
    _activePayTargetId = null;

    _rescheduleStatus = BookingActionStatus.idle;
    _rescheduleError = '';
    notifyListeners();
  }
}
