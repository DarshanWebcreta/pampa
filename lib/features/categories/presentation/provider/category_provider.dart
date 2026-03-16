import 'package:flutter/material.dart';
import 'package:pampa/features/categories/data/models/category_model.dart';
import 'package:pampa/features/categories/domain/repositories/category_repository.dart';

enum CategoryStatus { initial, loading, success, empty, error }

class CategoryProvider extends ChangeNotifier {
  final CategoryRepository _repository;

  CategoryProvider(this._repository);

  CategoryStatus _status = CategoryStatus.initial;
  List<CategoryModel> _categories = [];
  String _errorMessage = '';

  CategoryStatus get status => _status;
  List<CategoryModel> get categories => _categories;
  String get errorMessage => _errorMessage;
  bool get isLoading => _status == CategoryStatus.loading;

  Future<void> fetchCategories() async {
    if (_status == CategoryStatus.loading) return;

    _status = CategoryStatus.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      final result = await _repository.getCategories();
      _categories = result;
      _status = result.isEmpty ? CategoryStatus.empty : CategoryStatus.success;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _status = CategoryStatus.error;
    }

    notifyListeners();
  }

  void refresh() => fetchCategories();
}
