import 'package:flutter/material.dart';
import 'package:pampa/features/services/data/models/service_model.dart';
import 'package:pampa/features/services/domain/repositories/service_repository.dart';

enum ServiceStatus { initial, loading, success, empty, error }

enum ServiceSortType { highestRated, bestPrice, nearest }

class ServiceProvider extends ChangeNotifier {
  final ServiceRepository _repository;

  ServiceProvider(this._repository);

  ServiceStatus _status = ServiceStatus.initial;
  List<ServiceModel> _allServices = [];
  List<ServiceModel> _filtered = [];
  String _errorMessage = '';
  ServiceSortType _sortType = ServiceSortType.highestRated;

  // Current fetch params (for retry / refresh)
  String _lastZipCode = '';
  int _lastCategoryId = 0;

  ServiceStatus get status => _status;
  List<ServiceModel> get services => _filtered;
  String get errorMessage => _errorMessage;
  bool get isLoading => _status == ServiceStatus.loading;
  ServiceSortType get sortType => _sortType;

  Future<void> fetchServices({
    required String zipCode,
    required int categoryId,
  }) async {
    if (_status == ServiceStatus.loading) return;

    _lastZipCode = zipCode;
    _lastCategoryId = categoryId;

    _status = ServiceStatus.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      final result = await _repository.getServices(
        zipCode: zipCode,
        categoryId: categoryId,
      );

      _allServices = result;
      _applySort();
      _status = result.isEmpty ? ServiceStatus.empty : ServiceStatus.success;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _status = ServiceStatus.error;
    }

    notifyListeners();
  }

  void setSort(ServiceSortType sort) {
    if (_sortType == sort) return;
    _sortType = sort;
    _applySort();
    notifyListeners();
  }

  Future<void> refresh() => fetchServices(
        zipCode: _lastZipCode,
        categoryId: _lastCategoryId,
      );

  void reset() {
    _allServices = [];
    _filtered = [];
    _status = ServiceStatus.initial;
    _errorMessage = '';
    _sortType = ServiceSortType.highestRated;
    notifyListeners();
  }

  void _applySort() {
    final list = List<ServiceModel>.from(_allServices);
    switch (_sortType) {
      case ServiceSortType.bestPrice:
        list.sort((a, b) => a.priceAsDouble.compareTo(b.priceAsDouble));
        break;
      case ServiceSortType.nearest:
      // No distance data from API — keep original order
      case ServiceSortType.highestRated:
        // No rating data from API — keep original order
        break;
    }
    _filtered = list;
  }
}
