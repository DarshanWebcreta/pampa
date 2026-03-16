import 'package:flutter/material.dart';
import 'package:pampa/core/storage/storage.dart';
import 'package:pampa/core/values/keys.dart';
import 'package:pampa/features/auth/data/models/auth_response_model.dart';
import 'package:pampa/features/auth/domain/repositories/auth_repository.dart';

enum AuthStatus { initial, loading, success, error }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;

  AuthProvider(this._authRepository);

  AuthStatus _status = AuthStatus.initial;
  String _errorMessage = '';
  UserModel? _user;

  AuthStatus get status => _status;
  String get errorMessage => _errorMessage;
  UserModel? get user => _user;
  bool get isLoading => _status == AuthStatus.loading;

  /// Login with email and password.
  /// Returns true on success, false on failure.
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading();

    try {
      final response = await _authRepository.login(
        email: email,
        password: password,
      );

      StorageManager.saveData(StoreKeys.token, response.accessToken);
      _user = response.user;
      _status = AuthStatus.success;
      _errorMessage = '';
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _cleanMessage(e.toString());
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  /// Register a new customer account.
  /// Returns true on success, false on failure.
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String mobile,
  }) async {
    _setLoading();

    try {
      final response = await _authRepository.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
        mobile: mobile,
      );

      StorageManager.saveData(StoreKeys.token, response.accessToken);
      _user = response.user;
      _status = AuthStatus.success;
      _errorMessage = '';
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _cleanMessage(e.toString());
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  /// Clears token + user from storage. Call this then navigate to login.
  Future<void> logout() async {
    try {
      // Best-effort server-side logout (ignore errors — token is cleared locally regardless)
      await _authRepository.logout();
    } catch (_) {}

    StorageManager.deleteData(StoreKeys.token);
    StorageManager.deleteData(StoreKeys.zipCode);
    _user = null;
    _status = AuthStatus.initial;
    _errorMessage = '';
    notifyListeners();
  }

  void resetState() {
    _status = AuthStatus.initial;
    _errorMessage = '';
    notifyListeners();
  }

  void _setLoading() {
    _status = AuthStatus.loading;
    _errorMessage = '';
    notifyListeners();
  }

  /// Strips "Exception: " prefix added by Dart's Exception class.
  String _cleanMessage(String raw) {
    if (raw.startsWith('Exception: ')) {
      return raw.replaceFirst('Exception: ', '');
    }
    return raw;
  }
}
