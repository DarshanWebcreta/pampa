import 'package:dio/dio.dart';
import 'package:pampa/core/error/exception.dart';
import 'package:pampa/data/service/apiservice.dart';
import 'package:pampa/features/services/data/models/service_model.dart';
import 'package:pampa/features/services/domain/repositories/service_repository.dart';

class ServiceRepositoryImpl implements ServiceRepository {
  final ApiService _apiService;

  ServiceRepositoryImpl(this._apiService);

  @override
  Future<List<ServiceModel>> getServices({
    int? categoryId,
  }) async {
    try {
      final response = await _apiService.getServices(categoryId);
      final map = response as Map<String, dynamic>;

      if (map['status'] == true) {
        final list = map['data'] as List<dynamic>;
        return list
            .map((item) => ServiceModel.fromJson(item as Map<String, dynamic>))
            .where((s) => s.isActive)
            .toList();
      }

      throw Exception(map['message'] ?? 'Failed to load services.');
    } on DioException catch (e) {
      throw Exception(HandleExeption.handleError(e));
    } on Exception {
      rethrow;
    } catch (_) {
      throw Exception('Something went wrong. Please try again.');
    }
  }
}
