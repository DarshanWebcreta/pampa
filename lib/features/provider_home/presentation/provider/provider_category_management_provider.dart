import 'package:flutter/material.dart';
import 'package:pampa/data/service/apiservice.dart';
import 'package:pampa/features/categories/data/models/category_model.dart';

enum ProviderCategoryStatus { initial, loading, success, empty, error }

class ProviderCategoryManagementProvider extends ChangeNotifier {
  ProviderCategoryManagementProvider(this._api);

  final ApiService _api;

  ProviderCategoryStatus _status = ProviderCategoryStatus.initial;
  List<CategoryModel> _categories = [];
  bool _saving = false;
  String _error = '';

  ProviderCategoryStatus get status => _status;
  List<CategoryModel> get categories => _categories;
  bool get saving => _saving;
  String get error => _error;

  Future<void> fetchCategories({bool forceRefresh = false}) async {
    if (_status == ProviderCategoryStatus.loading) return;
    if (!forceRefresh &&
        (_status == ProviderCategoryStatus.success ||
            _status == ProviderCategoryStatus.empty)) {
      return;
    }
    _status = ProviderCategoryStatus.loading;
    _error = '';
    notifyListeners();

    try {
      final response = await _api.getCategories();
      final map = response as Map<String, dynamic>;
      final list =
          (map['data'] as List<dynamic>? ?? [])
              .map(
                (item) => CategoryModel.fromJson(item as Map<String, dynamic>),
              )
              .toList()
            ..sort((a, b) => a.categoryName.compareTo(b.categoryName));
      _categories = list;
      _status = list.isEmpty
          ? ProviderCategoryStatus.empty
          : ProviderCategoryStatus.success;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _status = ProviderCategoryStatus.error;
    }

    notifyListeners();
  }

  Future<String?> createCategory({
    required String categoryName,
    required String status,
  }) async {
    _saving = true;
    notifyListeners();

    try {
      final response = await _api.createCategory({
        'category_name': categoryName,
        'status': status,
      });
      final map = response as Map<String, dynamic>;
      if (map['status'] != true) {
        return map['message'] as String? ?? 'Failed to create category.';
      }

      final data = map['data'] as Map<String, dynamic>? ?? {};
      final category = CategoryModel.fromJson(data);
      _categories = [..._categories, category]
        ..sort((a, b) => a.categoryName.compareTo(b.categoryName));
      _status = ProviderCategoryStatus.success;
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  Future<String?> updateCategory({
    required int id,
    required String categoryName,
    required String status,
  }) async {
    _saving = true;
    notifyListeners();

    try {
      final response = await _api.updateCategory(id, {
        'category_name': categoryName,
        'status': status,
      });
      final map = response as Map<String, dynamic>;
      if (map['status'] != true) {
        return map['message'] as String? ?? 'Failed to update category.';
      }

      final data = map['data'] as Map<String, dynamic>? ?? {};
      final updated = CategoryModel.fromJson(data);
      _categories =
          _categories.map((item) => item.id == id ? updated : item).toList()
            ..sort((a, b) => a.categoryName.compareTo(b.categoryName));
      _status = _categories.isEmpty
          ? ProviderCategoryStatus.empty
          : ProviderCategoryStatus.success;
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    } finally {
      _saving = false;
      notifyListeners();
    }
  }
}
