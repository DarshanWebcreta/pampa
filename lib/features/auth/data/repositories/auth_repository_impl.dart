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
    required String type,
  }) async {
    try {
      final response = await _apiService.login({
        'email': email,
        'password': password,
        'type': type,
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
    required String type,
    String? referralCode,
  }) async {
    try {
      final response = await _apiService.register({
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'mobile': mobile,
        'type': type,
        if (referralCode != null && referralCode.isNotEmpty) 'referral_code': referralCode,
      });

      final map = response as Map<String, dynamic>;

      if (map['status'] == true) {
        // Provider registration returns status:true but data:null (pending approval)
        if (map['data'] == null) {
          throw PendingApprovalException(
            map['message'] as String? ?? 'Registration successful. Please wait for admin approval.',
          );
        }
        return AuthResponseModel.fromJson(map['data'] as Map<String, dynamic>);
      }

      throw Exception(map['message'] ?? 'Registration failed. Please try again.');
    } on PendingApprovalException {
      rethrow;
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
  Future<AuthResponseModel> socialLogin({
    required String email,
    required String loginId,
    required String fullName,
    String? photoUrl,
    required String type,
  }) async {
    try {
      final body = <String, dynamic>{
        'email': email,
        'login_id': loginId,
        'login_type': 'google',
        'full_name': fullName,
        'type': type,
        if (photoUrl != null && photoUrl.isNotEmpty) 'photo_url': photoUrl,
      };

      final response = await _apiService.googleLogin(body);

      final map = response as Map<String, dynamic>;

      if (map['status'] == true) {
        return AuthResponseModel.fromJson(map['data'] as Map<String, dynamic>);
      }

      throw Exception(map['message'] ?? 'Social login failed. Please try again.');
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

  @override
  Future<void> forgotPassword({
    required String email,
    required String type,
  }) async {
    try {
      final response = await _apiService.forgotPassword(type, {'email': email});
      final map = response as Map<String, dynamic>;
      if (map['status'] != true) {
        throw Exception(map['message'] ?? 'Failed to send OTP. Please try again.');
      }
    } on DioException catch (e) {
      final msg = _extractServerMessage(e);
      throw Exception(msg ?? HandleExeption.handleError(e));
    } on Exception {
      rethrow;
    } catch (_) {
      throw Exception('Something went wrong. Please try again.');
    }
  }

  @override
  Future<void> verifyOtp({
    required String email,
    required String otp,
    required String type,
  }) async {
    try {
      final response = await _apiService.verifyOtp(type, {
        'email': email,
        'otp': otp,
      });
      final map = response as Map<String, dynamic>;
      if (map['status'] != true) {
        throw Exception(map['message'] ?? 'Invalid or expired OTP.');
      }
    } on DioException catch (e) {
      final msg = _extractServerMessage(e);
      throw Exception(msg ?? HandleExeption.handleError(e));
    } on Exception {
      rethrow;
    } catch (_) {
      throw Exception('Something went wrong. Please try again.');
    }
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String otp,
    required String password,
    required String passwordConfirmation,
    required String type,
  }) async {
    try {
      final response = await _apiService.resetPassword(type, {
        'email': email,
        'otp': otp,
        'password': password,
        'password_confirmation': passwordConfirmation,
      });
      final map = response as Map<String, dynamic>;
      if (map['status'] != true) {
        throw Exception(map['message'] ?? 'Password reset failed. Please try again.');
      }
    } on DioException catch (e) {
      final msg = _extractServerMessage(e);
      throw Exception(msg ?? HandleExeption.handleError(e));
    } on Exception {
      rethrow;
    } catch (_) {
      throw Exception('Something went wrong. Please try again.');
    }
  }

  @override
  Future<void> changePassword({
    required String oldPassword,
    required String password,
    required String passwordConfirmation,
    required String type,
  }) async {
    try {
      final response = await _apiService.changePassword(type, {
        'old_password': oldPassword,
        'password': password,
        'password_confirmation': passwordConfirmation,
      });
      final map = response as Map<String, dynamic>;
      if (map['status'] != true) {
        throw Exception(map['message'] ?? 'Password change failed. Please try again.');
      }
    } on DioException catch (e) {
      final msg = _extractServerMessage(e);
      throw Exception(msg ?? HandleExeption.handleError(e));
    } on Exception {
      rethrow;
    } catch (_) {
      throw Exception('Something went wrong. Please try again.');
    }
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
