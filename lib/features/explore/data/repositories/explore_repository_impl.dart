import 'package:dio/dio.dart';
import 'package:pampa/core/error/exception.dart';
import 'package:pampa/data/service/apiservice.dart';
import 'package:pampa/features/booking/data/models/provider_model.dart';
import 'package:pampa/features/explore/data/models/explore_model.dart';
import 'package:pampa/features/explore/domain/repositories/explore_repository.dart';

class ExploreRepositoryImpl implements ExploreRepository {
  final ApiService _apiService;

  ExploreRepositoryImpl(this._apiService);

  @override
  Future<ExploreResultModel> explore({String? query}) async {
    try {
      final response = await _apiService.explore(query);
      final map = response as Map<String, dynamic>;
      if (map['status'] == true) {
        return ExploreResultModel.fromJson(map);
      }
      throw Exception(map['message'] ?? 'Failed to load explore data.');
    } on DioException catch (e) {
      throw Exception(HandleExeption.handleError(e));
    } on Exception {
      rethrow;
    } catch (_) {
      throw Exception('Something went wrong. Please try again.');
    }
  }

  @override
  Future<ProviderModel> getProviderDetail(int id) async {
    try {
      final response = await _apiService.getProviderDetail(id);
      final map = response as Map<String, dynamic>;
      if (map['status'] == true) {
        return ProviderModel.fromJson(map['data'] as Map<String, dynamic>);
      }
      throw Exception(map['message'] ?? 'Failed to load provider.');
    } on DioException catch (e) {
      throw Exception(HandleExeption.handleError(e));
    } on Exception {
      rethrow;
    } catch (_) {
      throw Exception('Something went wrong. Please try again.');
    }
  }
}
