import 'package:pampa/features/auth/data/models/auth_response_model.dart';

abstract class AuthRepository {
  Future<AuthResponseModel> login({
    required String email,
    required String password,
  });

  Future<AuthResponseModel> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String mobile,
  });

  /// Social login — email only, no password.
  Future<AuthResponseModel> socialLogin({required String email});

  /// Social register — name + email + mobile, no password.
  Future<AuthResponseModel> socialRegister({
    required String name,
    required String email,
    required String mobile,
  });

  Future<void> logout();
}
