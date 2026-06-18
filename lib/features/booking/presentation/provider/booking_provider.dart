import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pampa/features/booking/data/models/provider_model.dart';
import 'package:pampa/features/booking/data/models/slot_model.dart';
import 'package:pampa/features/booking/domain/repositories/booking_repository.dart';
import 'package:pampa/features/services/data/models/service_model.dart';
import 'package:pampa/core/storage/storage.dart';
import 'package:pampa/core/storage/storage_keys.dart';

enum BookingFetchStatus { initial, loading, success, error }

enum BookingSubmitStatus { idle, submitting, submitted, failed }

enum ProviderFetchStatus { initial, loading, success, error }

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

  // ── Selection state ────────────────────────────────────────────────────────
  DateTime _selectedDate = DateTime.now();
  String? _selectedTime;
  double _tipAmount = 0;

  DateTime get selectedDate => _selectedDate;
  String? get selectedTime => _selectedTime;
  double get tipAmount => _tipAmount;

  // ── Available Slots ────────────────────────────────────────────────────────
  List<SlotModel> _availableSlots = [];
  bool _slotsLoading = false;

  List<SlotModel> get availableSlots => _availableSlots;
  bool get slotsLoading => _slotsLoading;

  // ── Unavailable Dates ──────────────────────────────────────────────────────
  List<String> _unavailableDates = [];
  bool _unavailableDatesLoading = false;

  List<String> get unavailableDates => _unavailableDates;
  bool get unavailableDatesLoading => _unavailableDatesLoading;

  bool get canBook =>
      _selectedTime != null &&
      _selectedProvider != null &&
      _fetchStatus == BookingFetchStatus.success &&
      _submitStatus == BookingSubmitStatus.idle;

  // ── Selected service IDs (multi-select) ───────────────────────────────────
  List<int> _selectedServiceIds = [];
  List<int> get selectedServiceIds => _selectedServiceIds;

  void setSelectedServiceIds(List<int> ids) {
    _selectedServiceIds = List<int>.from(ids);
  }

  // ── Submit state ───────────────────────────────────────────────────────────
  BookingSubmitStatus _submitStatus = BookingSubmitStatus.idle;
  String _submitError = '';
  String _successMessage = '';
  String? _paymentLink;
  int? _lastBookingId;

  BookingSubmitStatus get submitStatus => _submitStatus;
  String get submitError => _submitError;
  String get successMessage => _successMessage;
  String? get paymentLink => _paymentLink;
  int? get lastBookingId => _lastBookingId;
  bool get isSubmitting => _submitStatus == BookingSubmitStatus.submitting;

  // ── Distance & Travel Charge ──────────────────────────────────────────────
  double? _travelFee;
  double? _distanceMiles;
  bool? _withinRange;
  bool _distanceChargeLoading = false;
  String _distanceChargeError = '';

  double? get travelFee => _travelFee;
  double? get distanceMiles => _distanceMiles;
  bool? get withinRange => _withinRange;
  bool get distanceChargeLoading => _distanceChargeLoading;
  String get distanceChargeError => _distanceChargeError;

  Future<void> fetchDistanceCharge({
    required int providerId,
    required String customerZip,
  }) async {
    _distanceChargeLoading = true;
    _distanceChargeError = '';
    _travelFee = null;
    _distanceMiles = null;
    _withinRange = null;
    notifyListeners();

    try {
      final response = await _repository.getDistanceCharge(
        providerId: providerId,
        customerZip: customerZip,
      );
      final map = response as Map<String, dynamic>;
      if (map['status'] == true && map['data'] != null) {
        final data = map['data'] as Map<String, dynamic>;
        
        final distanceRaw = data['distance_miles'];
        _distanceMiles = distanceRaw is num ? distanceRaw.toDouble() : double.tryParse(distanceRaw?.toString() ?? '');
        
        final chargeRaw = data['distance_charge'];
        _travelFee = chargeRaw is num ? chargeRaw.toDouble() : double.tryParse(chargeRaw?.toString() ?? '');
        
        _withinRange = data['within_range'] as bool?;
      } else {
        _distanceChargeError = map['message'] ?? 'Failed to get distance charge';
      }
    } catch (e) {
      _distanceChargeError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _distanceChargeLoading = false;
      notifyListeners();
    }
  }

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
      final serviceId = _service?.id;
      _providers = await _repository.getProviders(zipCode, serviceId: serviceId);
      _providerFetchStatus = ProviderFetchStatus.success;
    } catch (e) {
      _providerFetchError = e.toString().replaceFirst('Exception: ', '');
      _providerFetchStatus = ProviderFetchStatus.error;
    }

    notifyListeners();
  }

  Future<void> fetchAvailableProviders({required String zipCode}) async {
    final service = _service;
    final time = _selectedTime;
    if (service == null || time == null) return;
    if (_providerFetchStatus == ProviderFetchStatus.loading) return;

    _providerFetchStatus = ProviderFetchStatus.loading;
    _providerFetchError = '';
    _providers = [];
    _selectedProvider = null;
    notifyListeners();

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      _providers = await _repository.getAvailableProviders(
        serviceIds: [service.id],
        zipCode: zipCode,
        date: dateStr,
        time: time,
      );
      _providerFetchStatus = ProviderFetchStatus.success;
    } catch (e) {
      _providerFetchError = e.toString().replaceFirst('Exception: ', '');
      _providerFetchStatus = ProviderFetchStatus.error;
    }

    notifyListeners();
  }

  // ── Provider selection ────────────────────────────────────────────────────
  void selectProvider(ProviderModel provider) {
    _selectedProvider = provider;
    notifyListeners();
  }

  // ── Date selection ────────────────────────────────────────────────────────
  void selectDate(DateTime date) {
    if (date.isBefore(DateTime.now().subtract(const Duration(days: 1)))) return;
    _selectedDate = date;
    notifyListeners();
  }

  void selectTime(String time) {
    _selectedTime = time;
    notifyListeners();
  }

  // ── Fetch Slots ───────────────────────────────────────────────────────────
  Future<void> _fetchSlotsInternal(int providerId, int serviceId) async {
    _slotsLoading = true;
    _availableSlots = [];
    _selectedTime = null;
    notifyListeners();

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      _availableSlots = await _repository.getAvailableSlots(
        providerId: providerId,
        date: dateStr,
        serviceId: serviceId,
      );
    } catch (e) {
      // In case of error, slots stay empty
    } finally {
      _slotsLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAvailableSlots(int providerId, {required int serviceId}) async {
    return _fetchSlotsInternal(providerId, serviceId);
  }

  Future<void> fetchUnavailableDates(int providerId, int categoryId) async {
    _unavailableDatesLoading = true;
    _unavailableDates = [];
    notifyListeners();

    try {
      _unavailableDates = await _repository.getUnavailableDates(providerId, categoryId);
    } catch (_) {
      _unavailableDates = [];
    } finally {
      _unavailableDatesLoading = false;
      notifyListeners();
    }
  }

  void generateStaticSlots() {
    _slotsLoading = true;
    _availableSlots = [];
    _selectedTime = null;
    notifyListeners();

    final service = _service;
    if (service == null) {
      _slotsLoading = false;
      notifyListeners();
      return;
    }

    final now = DateTime.now();
    final isToday = _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
    final nowMins = now.hour * 60 + now.minute;

    final staticSlots = <SlotModel>[];
    const int startMins = 9 * 60; // 9 AM
    const int endMins = 22 * 60; // 10 PM

    for (int mins = startMins; mins <= endMins; mins += 30) {
      if (isToday && mins <= nowMins) continue;

      final h = mins ~/ 60;
      final m = mins % 60;
      final startTimeStr = '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

      final endTotalMins = mins + service.duration;
      final eh = endTotalMins ~/ 60;
      final em = endTotalMins % 60;
      final endTimeStr = '${eh.toString().padLeft(2, '0')}:${em.toString().padLeft(2, '0')}';

      staticSlots.add(SlotModel(
        time: startTimeStr,
        endTime: endTimeStr,
        available: true,
      ));
    }


    _availableSlots = staticSlots;
    _slotsLoading = false;
    notifyListeners();
  }

  void selectTip(double amount) {
    _tipAmount = amount;
    notifyListeners();
  }

  // ── Create booking ─────────────────────────────────────────────────────────
  Future<bool> confirmBooking() async {
    final service = _service;
    final selectedTime = _selectedTime;
    final selectedProvider = _selectedProvider;
    if (service == null || selectedTime == null || selectedProvider == null) {
      return false;
    }

    return submitBookingDetails(
      serviceIds: [service.id],
      providerId: selectedProvider.id,
      appointmentTime: selectedTime,
    );
  }

  Future<bool> submitBookingDetails({
    required List<int> serviceIds,
    required int providerId,
    required String appointmentTime,
    int? addressId,
    String? notes,
    String? pinterestLink,
    String? inspirationPhotoPath,
  }) async {
    if (serviceIds.isEmpty) return false;

    _submitStatus = BookingSubmitStatus.submitting;
    _submitError = '';
    notifyListeners();

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final result = await _repository.createBooking(
        serviceIds: serviceIds,
        providerId: providerId,
        addressId: addressId,
        appointmentDate: dateStr,
        appointmentTime: appointmentTime,
        tipAmount: _tipAmount > 0 ? _tipAmount : null,
        notes: notes,
        pinterestLink: pinterestLink,
        inspirationPhotoPath: inspirationPhotoPath,
      );
      _successMessage = result.message;
      _paymentLink = result.paymentLink;
      _lastBookingId = result.bookingId;

      if (_paymentLink != null && _paymentLink!.isNotEmpty) {
        persistPendingBooking();
      }

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
    _paymentLink = null;
    _lastBookingId = null;
    clearPendingBooking();
    notifyListeners();
  }

  // ── Persistence ─────────────────────────────────────────────────────────────
  void persistPendingBooking() {
    if (_lastBookingId != null) {
      StorageManager.saveData(AppStorageKeys.pendingBookingId, _lastBookingId);
    }
    if (_paymentLink != null) {
      StorageManager.saveData(
          AppStorageKeys.pendingPaymentLink, _paymentLink);
    }
  }

  void loadPendingBooking() {
    _lastBookingId = StorageManager.readData(AppStorageKeys.pendingBookingId);
    _paymentLink = StorageManager.readData(AppStorageKeys.pendingPaymentLink);
    if (_lastBookingId != null || _paymentLink != null) {
      _submitStatus = BookingSubmitStatus.submitted;
      notifyListeners();
    }
  }

  void clearPendingBooking() {
    _lastBookingId = null;
    _paymentLink = null;
    _travelFee = null;
    _distanceMiles = null;
    _withinRange = null;
    _distanceChargeLoading = false;
    _distanceChargeError = '';
    if (_submitStatus == BookingSubmitStatus.submitted) {
      _submitStatus = BookingSubmitStatus.idle;
    }
    StorageManager.deleteData(AppStorageKeys.pendingBookingId);
    StorageManager.deleteData(AppStorageKeys.pendingPaymentLink);
    notifyListeners();
  }

  String get formattedSelectedDate =>
      DateFormat('MMMM d, yyyy').format(_selectedDate);

  String get formattedDateForDisplay =>
      DateFormat('EEE, MMM d').format(_selectedDate);

  UnmodifiableListView<ProviderModel> get activeProviders =>
      UnmodifiableListView(_providers.where((p) => p.isActive));
}
