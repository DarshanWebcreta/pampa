import 'package:dio/dio.dart';
import 'package:pampa/core/error/exception.dart';
import 'package:pampa/data/service/apiservice.dart';
import 'package:pampa/features/profile/data/models/customer_profile_model.dart';
import 'package:pampa/features/profile/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ApiService _apiService;

  ProfileRepositoryImpl(this._apiService);

  @override
  Future<CustomerProfileModel> getMe() async {
    try {
      final response = await _apiService.getUser();
      final map = response as Map<String, dynamic>;

      if (map['status'] == true) {
        final data = map['data'];
        if (data is Map<String, dynamic>) {
          return CustomerProfileModel.fromJson(data);
        }
        throw Exception('Invalid profile data.');
      }

      throw Exception(map['message'] ?? 'Failed to load profile.');
    } on DioException catch (e) {
      throw Exception(HandleExeption.handleError(e));
    } on Exception {
      rethrow;
    } catch (_) {
      throw Exception('Something went wrong. Please try again.');
    }
  }
}

