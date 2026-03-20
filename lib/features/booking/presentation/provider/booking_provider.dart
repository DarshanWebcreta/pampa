import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pampa/features/booking/data/models/provider_model.dart';
import 'package:pampa/features/booking/data/models/time_slot_model.dart';
import 'package:pampa/features/booking/domain/repositories/booking_repository.dart';
import 'package:pampa/features/services/data/models/service_model.dart';

enum BookingFetchStatus { initial, loading, success, error }

enum BookingSubmitStatus { idle, submitting, submitted, failed }

enum ProviderFetchStatus { initial, loading, success, error }

enum SlotFetchStatus { initial, loading, success, error }

class BookingProvider extends ChangeNotifier {
  final BookingRepository _repository;

  BookingProvider(this._repository);

  // ── Service detail ─────────────────────────────────────────────────────────
  BookingFetchStatus _fetchStatus = BookingFetchStatus.initial;
  ServiceModel? _service;
  String _fetchError = '';

  BookingFetchStatus get fetchStatus => _fetchStatus;
  ServiceModel? get service => _service;
  String get fetchError => _fetchError;

  // ── Providers ──────────────────────────────────────────────────────────────
  ProviderFetchStatus _providerFetchStatus = ProviderFetchStatus.initial;
  List<ProviderModel> _providers = [];
  ProviderModel? _selectedProvider;
  String _providerFetchError = '';

  ProviderFetchStatus get providerFetchStatus => _providerFetchStatus;
  List<ProviderModel> get providers => _providers;
  ProviderModel? get selectedProvider => _selectedProvider;
  String get providerFetchError => _providerFetchError;
  bool get isLoadingProviders =>
      _providerFetchStatus == ProviderFetchStatus.loading;

  // ── Available time slots ───────────────────────────────────────────────────
  SlotFetchStatus _slotFetchStatus = SlotFetchStatus.initial;
  List<TimeSlotModel> _slots = [];
  String _slotFetchError = '';

  SlotFetchStatus get slotFetchStatus => _slotFetchStatus;
  List<TimeSlotModel> get slots => _slots;
  String get slotFetchError => _slotFetchError;
  bool get isLoadingSlots => _slotFetchStatus == SlotFetchStatus.loading;

  // ── Selection state ────────────────────────────────────────────────────────
  DateTime _selectedDate = DateTime.now();
  String? _selectedTime;
  double _tipAmount = 0;

  DateTime get selectedDate => _selectedDate;
  String? get selectedTime => _selectedTime;
  double get tipAmount => _tipAmount;

  bool get canBook =>
      _selectedTime != null &&
      _selectedProvider != null &&
      _fetchStatus == BookingFetchStatus.success &&
      _submitStatus == BookingSubmitStatus.idle;

  // ── Submit state ───────────────────────────────────────────────────────────
  BookingSubmitStatus _submitStatus = BookingSubmitStatus.idle;
  String _submitError = '';
  String _successMessage = '';

  BookingSubmitStatus get submitStatus => _submitStatus;
  String get submitError => _submitError;
  String get successMessage => _successMessage;
  bool get isSubmitting => _submitStatus == BookingSubmitStatus.submitting;

  // ── Fetch service detail ───────────────────────────────────────────────────
  Future<void> fetchServiceDetail(int id) async {
    if (_fetchStatus == BookingFetchStatus.loading) return;

    _fetchStatus = BookingFetchStatus.loading;
    _fetchError = '';
    notifyListeners();

    try {
      _service = await _repository.getServiceDetail(id);
      _fetchStatus = BookingFetchStatus.success;
    } catch (e) {
      _fetchError = e.toString().replaceFirst('Exception: ', '');
      _fetchStatus = BookingFetchStatus.error;
    }

    notifyListeners();
  }

  // ── Fetch providers ────────────────────────────────────────────────────────
  Future<void> fetchProviders(String zipCode) async {
    if (_providerFetchStatus == ProviderFetchStatus.loading) return;

    _providerFetchStatus = ProviderFetchStatus.loading;
    _providerFetchError = '';
    notifyListeners();

    try {
      _providers = await _repository.getProviders(zipCode);
      _providerFetchStatus = ProviderFetchStatus.success;
    } catch (e) {
      _providerFetchError = e.toString().replaceFirst('Exception: ', '');
      _providerFetchStatus = ProviderFetchStatus.error;
    }

    notifyListeners();
  }

  // ── Select provider → auto-fetch slots ────────────────────────────────────
  void selectProvider(ProviderModel provider) {
    _selectedProvider = provider;
    _selectedTime = null;
    notifyListeners();
    _fetchSlots();
  }

  // ── Date selection → auto-refetch slots if provider selected ───────────────
  void selectDate(DateTime date) {
    if (date.isBefore(DateTime.now().subtract(const Duration(days: 1)))) return;
    _selectedDate = date;
    _selectedTime = null;
    notifyListeners();
    if (_selectedProvider != null) {
      _fetchSlots();
    }
  }

  void selectTime(String time) {
    _selectedTime = time;
    notifyListeners();
  }

  void selectTip(double amount) {
    _tipAmount = amount;
    notifyListeners();
  }

  // ── Internal: fetch available slots ───────────────────────────────────────
  Future<void> _fetchSlots() async {
    final provider = _selectedProvider;
    final service = _service;
    if (provider == null || service == null) return;

    _slotFetchStatus = SlotFetchStatus.loading;
    _slots = [];
    _selectedTime = null;
    _slotFetchError = '';
    notifyListeners();

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      _slots = await _repository.getAvailableSlots(
        providerId: provider.id,
        date: dateStr,
        serviceId: service.id,
      );
      _slotFetchStatus = SlotFetchStatus.success;
    } catch (e) {
      _slotFetchError = e.toString().replaceFirst('Exception: ', '');
      _slotFetchStatus = SlotFetchStatus.error;
    }

    notifyListeners();
  }

  // ── Create booking ─────────────────────────────────────────────────────────
  Future<bool> confirmBooking() async {
    if (_service == null || _selectedTime == null || _selectedProvider == null) {
      return false;
    }

    _submitStatus = BookingSubmitStatus.submitting;
    _submitError = '';
    notifyListeners();

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      _successMessage = await _repository.createBooking(
        serviceId: _service!.id,
        providerId: _selectedProvider!.id,
        appointmentDate: dateStr,
        appointmentTime: _selectedTime!,
      );

      _submitStatus = BookingSubmitStatus.submitted;
      notifyListeners();
      return true;
    } catch (e) {
      _submitError = e.toString().replaceFirst('Exception: ', '');
      _submitStatus = BookingSubmitStatus.failed;
      notifyListeners();
      return false;
    }
  }

  Future<String?> createCheckoutSessionUrl({
    required int addressId,
    required int providerId,
  }) async {
    final service = _service;
    final time = _selectedTime;
    if (service == null || time == null || _selectedProvider == null) {
      return null;
    }

    _submitStatus = BookingSubmitStatus.submitting;
    _submitError = '';
    notifyListeners();

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final url = await _repository.createCheckoutSession(
        serviceId: service.id,
        price: service.deposit > 0 ? service.deposit : service.priceAsDouble,
        tipAmount: _tipAmount,
        addressId: addressId,
        providerId: providerId,
        appointmentDate: dateStr,
        appointmentTime: time,
      );
      _submitStatus = BookingSubmitStatus.idle;
      notifyListeners();
      return url;
    } catch (e) {
      _submitError = e.toString().replaceFirst('Exception: ', '');
      _submitStatus = BookingSubmitStatus.failed;
      notifyListeners();
      return null;
    }
  }

  void resetSubmit() {
    _submitStatus = BookingSubmitStatus.idle;
    _submitError = '';
    notifyListeners();
  }

  String get formattedSelectedDate =>
      DateFormat('MMMM d, yyyy').format(_selectedDate);

  String get formattedDateForDisplay =>
      DateFormat('EEE, MMM d').format(_selectedDate);
}
