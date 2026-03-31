import 'package:dio/dio.dart';
import 'package:pampa/core/error/exception.dart';
import 'package:pampa/data/service/apiservice.dart';
import 'package:pampa/features/auth/data/models/auth_response_model.dart';
import 'package:pampa/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiService _apiService;

  AuthRepositoryImpl(this._apiService);

  @override
  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiService.login({
        'email': email,
        'password': password,
      });

      final map = response as Map<String, dynamic>;

      if (map['status'] == true) {
        return AuthResponseModel.fromJson(map['data'] as Map<String, dynamic>);
      }

      throw Exception(map['message'] ?? 'Login failed. Please try again.');
    } on DioException catch (e) {
      final serverMessage = _extractServerMessage(e);
      throw Exception(serverMessage ?? HandleExeption.handleError(e));
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Something went wrong. Please try again.');
    }
  }

  @override
  Future<AuthResponseModel> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String mobile,
  }) async {
    try {
      final response = await _apiService.register({
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'mobile': mobile,
      });

      final map = response as Map<String, dynamic>;

      if (map['status'] == true) {
        return AuthResponseModel.fromJson(map['data'] as Map<String, dynamic>);
      }

      throw Exception(map['message'] ?? 'Registration failed. Please try again.');
    } on DioException catch (e) {
      final serverMessage = _extractServerMessage(e);
      throw Exception(serverMessage ?? HandleExeption.handleError(e));
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Something went wrong. Please try again.');
    }
  }

  @override
  Future<AuthResponseModel> socialLogin({required String email}) async {
    try {
      final response = await _apiService.login({'email': email});

      final map = response as Map<String, dynamic>;

      if (map['status'] == true) {
        return AuthResponseModel.fromJson(map['data'] as Map<String, dynamic>);
      }

      throw Exception(map['message'] ?? 'Login failed. Please try again.');
    } on DioException catch (e) {
      final serverMessage = _extractServerMessage(e);
      throw Exception(serverMessage ?? HandleExeption.handleError(e));
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Something went wrong. Please try again.');
    }
  }

  @override
  Future<AuthResponseModel> socialRegister({
    required String name,
    required String email,
    required String mobile,
  }) async {
    try {
      final response = await _apiService.register({
        'name': name,
        'email': email,
        'mobile': mobile,
      });

      final map = response as Map<String, dynamic>;

      if (map['status'] == true) {
        return AuthResponseModel.fromJson(map['data'] as Map<String, dynamic>);
      }

      throw Exception(map['message'] ?? 'Registration failed. Please try again.');
    } on DioException catch (e) {
      final serverMessage = _extractServerMessage(e);
      throw Exception(serverMessage ?? HandleExeption.handleError(e));
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Something went wrong. Please try again.');
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _apiService.logout();
    } on DioException {
      // Swallow — token will be cleared locally regardless
    } catch (_) {}
  }

  /// Extracts validation or error messages from the server 422/400 response body.
  String? _extractServerMessage(DioException e) {
    try {
      final data = e.response?.data;
      if (data == null) return null;

      if (data is Map<String, dynamic>) {
        if (data['message'] != null) return data['message'].toString();

        // Laravel validation errors: { "errors": { "email": ["..."] } }
        if (data['errors'] != null && data['errors'] is Map) {
          final errors = data['errors'] as Map<String, dynamic>;
          final firstField = errors.values.first;
          if (firstField is List && firstField.isNotEmpty) {
            return firstField.first.toString();
          }
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
