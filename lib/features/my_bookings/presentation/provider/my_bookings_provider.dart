import 'package:flutter/material.dart';
import 'package:pampa/features/my_bookings/data/models/my_booking_model.dart';
import 'package:pampa/features/my_bookings/domain/repositories/my_bookings_repository.dart';

enum MyBookingsFetchStatus { initial, loading, success, empty, error }

enum BookingFilter { all, upcoming, completed, cancelled }

enum BookingDetailStatus { initial, loading, success, error }

enum BookingActionStatus { idle, loading, done, failed }

class MyBookingsProvider extends ChangeNotifier {
  final MyBookingsRepository _repository;

  MyBookingsProvider(this._repository);

  // ── List state ────────────────────────────────────────────────────────────────
  MyBookingsFetchStatus _status = MyBookingsFetchStatus.initial;
  List<MyBookingModel> _allBookings = [];
  String _error = '';
  BookingFilter _filter = BookingFilter.all;

  MyBookingsFetchStatus get status => _status;
  String get error => _error;
  BookingFilter get filter => _filter;

  List<MyBookingModel> get bookings {
    switch (_filter) {
      case BookingFilter.all:
        return _allBookings;
      case BookingFilter.upcoming:
        return _allBookings.where((b) => b.isUpcoming).toList();
      case BookingFilter.completed:
        return _allBookings.where((b) => b.isCompleted).toList();
      case BookingFilter.cancelled:
        return _allBookings.where((b) => b.isCancelled).toList();
    }
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

  void setFilter(BookingFilter f) {
    if (_filter == f) return;
    _filter = f;
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

  BookingDetailStatus get detailStatus => _detailStatus;
  MyBookingModel? get detailBooking => _detailBooking;
  String get detailError => _detailError;
  BookingActionStatus get cancelStatus => _cancelStatus;
  String get cancelError => _cancelError;
  BookingActionStatus get payStatus => _payStatus;
  String get payError => _payError;

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
    notifyListeners();
  }
}
