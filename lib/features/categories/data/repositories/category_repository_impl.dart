import 'package:dio/dio.dart';
import 'package:pampa/core/error/exception.dart';
import 'package:pampa/data/service/apiservice.dart';
import 'package:pampa/features/categories/data/models/category_model.dart';
import 'package:pampa/features/categories/domain/repositories/category_repository.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final ApiService _apiService;

  CategoryRepositoryImpl(this._apiService);

  @override
  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await _apiService.getCategories();
      final map = response as Map<String, dynamic>;

      if (map['status'] == true) {
        final list = map['data'] as List<dynamic>;
        return list
            .map((item) => CategoryModel.fromJson(item as Map<String, dynamic>))
            .where((c) => c.isActive)
            .toList();
      }

      throw Exception(map['message'] ?? 'Failed to load categories.');
    } on DioException catch (e) {
      throw Exception(HandleExeption.handleError(e));
    } on Exception {
      rethrow;
    } catch (_) {
      throw Exception('Something went wrong. Please try again.');
    }
  }
}
