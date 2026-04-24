import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:pampa/data/service/apiservice.dart';
import 'package:pampa/features/categories/data/models/category_model.dart';
import 'package:pampa/features/services/data/models/service_model.dart';

enum ProviderServiceStatus { initial, loading, success, empty, error }

class ProviderServiceManagementProvider extends ChangeNotifier {
  ProviderServiceManagementProvider(this._api);

  final ApiService _api;

  ProviderServiceStatus _status = ProviderServiceStatus.initial;
  List<ServiceModel> _services = [];
  List<CategoryModel> _categories = [];
  Set<int> _assignedServiceIds = <int>{};
  bool _saving = false;
  bool _deleting = false;
  bool _assigning = false;
  String _error = '';

  ProviderServiceStatus get status => _status;
  List<ServiceModel> get services => _services;
  List<CategoryModel> get categories => _categories;
  Set<int> get assignedServiceIds => _assignedServiceIds;
  bool get saving => _saving;
  bool get deleting => _deleting;
  bool get assigning => _assigning;
  String get error => _error;

  Future<void> initialize({bool forceRefresh = false}) async {
    if (_status == ProviderServiceStatus.loading) return;
    if (!forceRefresh &&
        (_status == ProviderServiceStatus.success ||
            _status == ProviderServiceStatus.empty)) {
      return;
    }
    _status = ProviderServiceStatus.loading;
    _error = '';
    notifyListeners();

    try {
      final categoriesResponse = await _api.getCategories();
      final categoriesMap = categoriesResponse as Map<String, dynamic>;
      _categories =
          (categoriesMap['data'] as List<dynamic>? ?? [])
              .map(
                (item) => CategoryModel.fromJson(item as Map<String, dynamic>),
              )
              .toList()
            ..sort((a, b) => a.categoryName.compareTo(b.categoryName));

      final servicesResponse = await _api.getServices(null);
      final servicesMap = servicesResponse as Map<String, dynamic>;
      _services =
          (servicesMap['data'] as List<dynamic>? ?? [])
              .map(
                (item) => ServiceModel.fromJson(item as Map<String, dynamic>),
              )
              .toList()
            ..sort((a, b) => a.serviceName.compareTo(b.serviceName));

      final profileResponse = await _api.getProviderProfile();
      final profileMap = profileResponse as Map<String, dynamic>;
      final profileData = profileMap['data'] as Map<String, dynamic>? ?? {};
      final assignedServices =
          (profileData['services'] as List<dynamic>? ?? [])
              .map((item) => (item as Map<String, dynamic>)['id'] as int? ?? 0)
              .where((id) => id > 0)
              .toSet();
      _assignedServiceIds = assignedServices;

      _status = _services.isEmpty
          ? ProviderServiceStatus.empty
          : ProviderServiceStatus.success;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _status = ProviderServiceStatus.error;
    }

    notifyListeners();
  }

  Future<String?> createService({
    required int categoryId,
    required String serviceName,
    required String price,
    required String duration,
    required String status,
    String? deposit,
    String? priorityFee,
    String? description,
    File? image,
  }) async {
    return 'Creating services is disabled. Services are managed by admin.';
  }

  Future<String?> updateService({
    required int id,
    required String price,
    required String duration,
    String? description,
    File? image,
  }) async {
    _saving = true;
    notifyListeners();

    try {
      final response = await _api.updateService(
        id,
        await _buildUpdateServiceFormData(
          price: price,
          duration: duration,
          description: description,
          image: image,
        ),
      );
      final map = response as Map<String, dynamic>;
      if (map['status'] != true) {
        return map['message'] as String? ?? 'Failed to update service.';
      }

      final data = map['data'] as Map<String, dynamic>? ?? {};
       final updated = ServiceModel.fromJson(data);
      _services =
          _services.map((item) => item.id == id ? updated : item).toList()
            ..sort((a, b) => a.serviceName.compareTo(b.serviceName));
      _status = _services.isEmpty
          ? ProviderServiceStatus.empty
          : ProviderServiceStatus.success;
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  Future<String?> deleteService(int id) async {
    _deleting = true;
    notifyListeners();

    try {
      final response = await _api.deleteService(id);
      final map = response as Map<String, dynamic>;
      if (map['status'] != true) {
        return map['message'] as String? ?? 'Failed to delete service.';
      }

      _services = _services.where((item) => item.id != id).toList();
      _status = _services.isEmpty
          ? ProviderServiceStatus.empty
          : ProviderServiceStatus.success;
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    } finally {
      _deleting = false;
      notifyListeners();
    }
  }

  Future<FormData> _buildServiceFormData({
    required String price,
    required String duration,
    String? description,
    File? image,
  }) async {
    final data = <String, dynamic>{
      'price': price,
      'duration': duration,
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
    };

    if (image != null) {
      data['image'] = await MultipartFile.fromFile(
        image.path,
        filename: image.path.split('/').last,
      );
    }

    return FormData.fromMap(data);
  }

  Future<FormData> _buildUpdateServiceFormData({
    required String price,
    required String duration,
    String? description,
    File? image,
  }) async {
    return _buildServiceFormData(
      price: price,
      duration: duration,
      description: description,
      image: image,
    );
  }

  bool isAssigned(int serviceId) => _assignedServiceIds.contains(serviceId);

  Future<String?> assignService(int serviceId) async {
    if (_assigning) return null;
    _assigning = true;
    notifyListeners();
    try {
      final service = _services.firstWhere((s) => s.id == serviceId);
      final response = await _api.assignProviderService(serviceId, {
        'price': service.priceAsDouble,
        'duration': service.duration,
        'description': service.description ?? '',
      });
      final map = response as Map<String, dynamic>;
      if (map['success'] == true || map['status'] == true) {
        _assignedServiceIds = {..._assignedServiceIds, serviceId};
        notifyListeners();
        return null;
      }
      return map['message'] as String? ?? 'Failed to assign service.';
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    } finally {
      _assigning = false;
      notifyListeners();
    }
  }

  Future<String?> unassignService(int serviceId) async {
    if (_assigning) return null;
    _assigning = true;
    notifyListeners();
    try {
      final response = await _api.unassignProviderService(serviceId);
      final map = response as Map<String, dynamic>;
      if (map['success'] == true || map['status'] == true) {
        _assignedServiceIds = {..._assignedServiceIds}..remove(serviceId);
        notifyListeners();
        return null;
      }
      return map['message'] as String? ?? 'Failed to unassign service.';
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    } finally {
      _assigning = false;
      notifyListeners();
    }
  }
}
