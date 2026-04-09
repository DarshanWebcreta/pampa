import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:pampa/data/service/apiservice.dart';
import 'package:pampa/features/services/data/models/service_model.dart';

enum ProviderPricingStatus { initial, loading, success, empty, error }

class ServicePricingDraft {
  ServicePricingDraft({
    required this.service,
    required this.price,
    required this.duration,
  });

  final ServiceModel service;
  String price;
  String duration;
}

class ProviderPricingProvider extends ChangeNotifier {
  ProviderPricingProvider(this._api);

  final ApiService _api;

  ProviderPricingStatus _status = ProviderPricingStatus.initial;
  bool _savingGeneralPricing = false;
  String _error = '';
  final Set<int> _updatingServiceIds = <int>{};

  String _perKmCharge = '';
  String _maxServiceDistance = '';
  String _priorityFee = '';
  String _depositRequired = '';

  List<ServicePricingDraft> _services = [];

  ProviderPricingStatus get status => _status;
  bool get savingGeneralPricing => _savingGeneralPricing;
  String get error => _error;
  String get perKmCharge => _perKmCharge;
  String get maxServiceDistance => _maxServiceDistance;
  String get priorityFee => _priorityFee;
  String get depositRequired => _depositRequired;
  List<ServicePricingDraft> get services => _services;
  bool isUpdatingService(int serviceId) =>
      _updatingServiceIds.contains(serviceId);

  Map<String, List<ServicePricingDraft>> get groupedServices {
    final groups = <String, List<ServicePricingDraft>>{};
    for (final draft in _services) {
      final categoryName = draft.service.category?.categoryName;
      final key = categoryName != null && categoryName.trim().isNotEmpty
          ? categoryName
          : 'Other Services';
      groups.putIfAbsent(key, () => []).add(draft);
    }

    final sortedKeys = groups.keys.toList()..sort();
    return {
      for (final key in sortedKeys)
        key: (groups[key]!
          ..sort(
            (a, b) => a.service.serviceName.compareTo(b.service.serviceName),
          )),
    };
  }

  Future<void> initialize({bool forceRefresh = false}) async {
    if (_status == ProviderPricingStatus.loading) return;
    if (!forceRefresh &&
        (_status == ProviderPricingStatus.success ||
            _status == ProviderPricingStatus.empty)) {
      return;
    }
    _status = ProviderPricingStatus.loading;
    _error = '';
    notifyListeners();

    try {
      final settingsResponse = await _api.getProviderSettings();
      final servicesResponse = await _api.getServices(null);

      final settingsMap = settingsResponse as Map<String, dynamic>;
      final settingsData = settingsMap['data'] as Map<String, dynamic>? ?? {};
      final pricingData =
          settingsData['pricing'] as Map<String, dynamic>? ?? {};
      _perKmCharge = _readSettingValue(
        settingsData,
        pricingData,
        'per_km_charge',
      );
      _maxServiceDistance = _readSettingValue(
        settingsData,
        pricingData,
        'max_service_distance',
      );
      _priorityFee = _readSettingValue(
        settingsData,
        pricingData,
        'priority_fee',
      );
      _depositRequired = _readSettingValue(
        settingsData,
        pricingData,
        'deposit_required',
      );

      final servicesMap = servicesResponse as Map<String, dynamic>;
      _services =
          (servicesMap['data'] as List<dynamic>? ?? [])
              .map(
                (item) => ServiceModel.fromJson(item as Map<String, dynamic>),
              )
              .map(
                (service) => ServicePricingDraft(
                  service: service,
                  price: service.price,
                  duration: service.duration > 0 ? '${service.duration}' : '',
                ),
              )
              .toList()
            ..sort((a, b) {
              final categoryCompare = (a.service.category?.categoryName ?? '')
                  .compareTo(b.service.category?.categoryName ?? '');
              if (categoryCompare != 0) return categoryCompare;
              return a.service.serviceName.compareTo(b.service.serviceName);
            });

      _status = _services.isEmpty
          ? ProviderPricingStatus.empty
          : ProviderPricingStatus.success;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _status = ProviderPricingStatus.error;
    }

    notifyListeners();
  }

  void updateGeneralPricing({
    String? perKmCharge,
    String? maxServiceDistance,
    String? priorityFee,
    String? depositRequired,
  }) {
    if (perKmCharge != null) _perKmCharge = perKmCharge;
    if (maxServiceDistance != null) _maxServiceDistance = maxServiceDistance;
    if (priorityFee != null) _priorityFee = priorityFee;
    if (depositRequired != null) _depositRequired = depositRequired;
  }

  void updateServicePrice(int serviceId, String price) {
    final index = _services.indexWhere((item) => item.service.id == serviceId);
    if (index == -1) return;
    if (_services[index].price == price) return;
    _services[index].price = price;
    notifyListeners();
  }

  void updateServiceDuration(int serviceId, String duration) {
    final index = _services.indexWhere((item) => item.service.id == serviceId);
    if (index == -1) return;
    if (_services[index].duration == duration) return;
    _services[index].duration = duration;
    notifyListeners();
  }

  ServicePricingDraft? getDraft(int serviceId) {
    for (final draft in _services) {
      if (draft.service.id == serviceId) return draft;
    }
    return null;
  }

  void resetServiceDraft(int serviceId) {
    final draft = getDraft(serviceId);
    if (draft == null) return;
    draft.price = draft.service.price;
    draft.duration = draft.service.duration > 0
        ? '${draft.service.duration}'
        : '';
    notifyListeners();
  }

  Future<String?> saveGeneralPricing() async {
    _savingGeneralPricing = true;
    notifyListeners();

    try {
      final pricingResponse = await _api.updateProviderPricing({
        if (_perKmCharge.trim().isNotEmpty)
          'per_km_charge': double.parse(_perKmCharge.trim()),
        if (_maxServiceDistance.trim().isNotEmpty)
          'max_service_distance': int.parse(_maxServiceDistance.trim()),
        if (_priorityFee.trim().isNotEmpty)
          'priority_fee': int.parse(_priorityFee.trim()),
        if (_depositRequired.trim().isNotEmpty)
          'deposit_required': int.parse(_depositRequired.trim()),
      });

      final pricingMap = pricingResponse as Map<String, dynamic>;
      if (pricingMap['status'] != true) {
        return pricingMap['message'] as String? ??
            'Failed to update pricing settings.';
      }
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    } finally {
      _savingGeneralPricing = false;
      notifyListeners();
    }
  }

  Future<String?> updateServicePricing({
    required int serviceId,
    required String price,
    required String duration,
  }) async {
    final draft = getDraft(serviceId);
    if (draft == null) return 'Service not found.';

    _updatingServiceIds.add(serviceId);
    notifyListeners();

    try {
      final response = await _api.updateService(
        draft.service.id,
        await _buildUpdatePayload(
          service: draft.service,
          price: price.trim(),
          duration: duration.trim(),
        ),
      );
      final map = response as Map<String, dynamic>;
      if (map['status'] != true) {
        return map['message'] as String? ??
            'Failed to update ${draft.service.serviceName}.';
      }

      // Always refresh services from API after an update so pricing list
      // stays in sync with backend-calculated values.
      final servicesResponse = await _api.getServices(null);
      final servicesMap = servicesResponse as Map<String, dynamic>;
      _services =
          (servicesMap['data'] as List<dynamic>? ?? [])
              .map(
                (item) => ServiceModel.fromJson(item as Map<String, dynamic>),
              )
              .map(
                (service) => ServicePricingDraft(
                  service: service,
                  price: service.price,
                  duration: service.duration > 0 ? '${service.duration}' : '',
                ),
              )
              .toList()
            ..sort((a, b) {
              final categoryCompare = (a.service.category?.categoryName ?? '')
                  .compareTo(b.service.category?.categoryName ?? '');
              if (categoryCompare != 0) return categoryCompare;
              return a.service.serviceName.compareTo(b.service.serviceName);
            });
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    } finally {
      _updatingServiceIds.remove(serviceId);
      notifyListeners();
    }
  }

  Future<FormData> _buildUpdatePayload({
    required ServiceModel service,
    required String price,
    required String duration,
  }) async {
    return FormData.fromMap({
      'category_id': service.categoryId,
      'service_name': service.serviceName,
      'price': price,
      'duration': duration,
      'status': service.status,
      if (service.deposit > 0) 'deposit': service.deposit.toInt(),
      if (service.priorityFee > 0) 'priority_fee': service.priorityFee.toInt(),
      if ((service.description ?? '').trim().isNotEmpty)
        'description': service.description!.trim(),
    });
  }

  String _readSettingValue(
    Map<String, dynamic> root,
    Map<String, dynamic> nested,
    String key,
  ) {
    final nestedValue = nested[key];
    if (nestedValue != null) return nestedValue.toString();
    final rootValue = root[key];
    if (rootValue != null) return rootValue.toString();
    return '';
  }
}
