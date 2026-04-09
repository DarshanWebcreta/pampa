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
  bool _saving = false;
  bool _deleting = false;
  String _error = '';

  ProviderServiceStatus get status => _status;
  List<ServiceModel> get services => _services;
  List<CategoryModel> get categories => _categories;
  bool get saving => _saving;
  bool get deleting => _deleting;
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
    _saving = true;
    notifyListeners();

    try {
      final response = await _api.createService(
        await _buildServiceFormData(
          categoryId: categoryId,
          serviceName: serviceName,
          price: price,
          duration: duration,
          status: status,
          deposit: deposit,
          priorityFee: priorityFee,
          description: description,
          image: image,
        ),
      );
      final map = response as Map<String, dynamic>;
      if (map['status'] != true) {
        return map['message'] as String? ?? 'Failed to create service.';
      }

      final data = map['data'] as Map<String, dynamic>? ?? {};
      final created = ServiceModel.fromJson(data);
      _services = [..._services, created]
        ..sort((a, b) => a.serviceName.compareTo(b.serviceName));
      _status = ProviderServiceStatus.success;
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  Future<String?> updateService({
    required int id,
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
    _saving = true;
    notifyListeners();

    try {
      final response = await _api.updateService(
        id,
        await _buildServiceFormData(
          categoryId: categoryId,
          serviceName: serviceName,
          price: price,
          duration: duration,
          status: status,
          deposit: deposit,
          priorityFee: priorityFee,
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
    final data = <String, dynamic>{
      'category_id': categoryId,
      'service_name': serviceName,
      'price': price,
      'duration': duration,
      'status': status,
      if (deposit != null && deposit.trim().isNotEmpty)
        'deposit': deposit.trim(),
      if (priorityFee != null && priorityFee.trim().isNotEmpty)
        'priority_fee': priorityFee.trim(),
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
}
