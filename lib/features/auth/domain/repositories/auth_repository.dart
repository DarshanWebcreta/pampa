import 'package:pampa/features/auth/data/models/auth_response_model.dart';

abstract class AuthRepository {
  Future<AuthResponseModel> login({
    required String email,
    required String password,
    required String type,
  });

  Future<AuthResponseModel> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String mobile,
    required String type,
  });

  /// Social login — calls customer/social-login with Google profile data.
  Future<AuthResponseModel> socialLogin({
    required String email,
    required String loginId,
    required String fullName,
    String? photoUrl,
    required String type,
  });

  Future<void> logout();
}
