import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart'
    show GoogleSignIn, GoogleSignInException, GoogleSignInExceptionCode;
import 'package:pampa/core/error/exception.dart';
import 'package:pampa/core/storage/storage.dart';
import 'package:pampa/core/values/keys.dart';
import 'package:pampa/core/values/urls.dart';
import 'package:pampa/features/auth/data/models/auth_response_model.dart';
import 'package:pampa/features/auth/domain/repositories/auth_repository.dart';

enum AuthStatus { initial, loading, success, pendingApproval, error }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;

  AuthProvider(this._authRepository);

  AuthStatus _status = AuthStatus.initial;
  String _errorMessage = '';
  String _pendingApprovalMessage = '';
  UserModel? _user;
  String _userType = StorageManager.readData(StoreKeys.userType) as String? ?? 'customer';

  AuthStatus get status => _status;
  String get errorMessage => _errorMessage;
  String get pendingApprovalMessage => _pendingApprovalMessage;
  UserModel? get user => _user;
  bool get isLoading => _status == AuthStatus.loading;
  bool get isPendingApproval => _status == AuthStatus.pendingApproval;
  String get userType => _userType;

  void setUserType(String type) {
    _userType = type;
  }

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
        type: _userType,
      );

      StorageManager.saveData(StoreKeys.token, response.accessToken);
      StorageManager.saveData(StoreKeys.userType, _userType);
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
        type: _userType,
      );

      StorageManager.saveData(StoreKeys.token, response.accessToken);
      StorageManager.saveData(StoreKeys.userType, _userType);
      _user = response.user;
      _status = AuthStatus.success;
      _errorMessage = '';
      notifyListeners();
      return true;
    } on PendingApprovalException catch (e) {
      _pendingApprovalMessage = e.message;
      _status = AuthStatus.pendingApproval;
      _errorMessage = '';
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = _cleanMessage(e.toString());
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  /// Sign in with Google.
  /// Calls customer/social-login with Google profile data.
  Future<bool> googleSignIn() async {
    _setLoading();

    try {
      await GoogleSignIn.instance.initialize(
        serverClientId: ApiStrings.googleServerClientId,
      );

      final googleUser = await GoogleSignIn.instance.authenticate();

      final response = await _authRepository.socialLogin(
        email: googleUser.email,
        loginId: googleUser.id,
        fullName: googleUser.displayName ?? googleUser.email.split('@').first,
        photoUrl: googleUser.photoUrl,
        type: _userType,
      );

      StorageManager.saveData(StoreKeys.token, response.accessToken);
      StorageManager.saveData(StoreKeys.userType, _userType);
      _user = response.user;
      _status = AuthStatus.success;
      _errorMessage = '';
      notifyListeners();
      return true;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        _status = AuthStatus.initial;
        notifyListeners();
        return false;
      }
      _errorMessage = e.description ?? 'Google sign in failed.';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
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
    StorageManager.deleteData(StoreKeys.syncedFcmToken);
    StorageManager.deleteData(StoreKeys.userType);
    _user = null;
    _status = AuthStatus.initial;
    _errorMessage = '';
    notifyListeners();
  }

  void resetState() {
    _status = AuthStatus.initial;
    _errorMessage = '';
    _pendingApprovalMessage = '';
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
