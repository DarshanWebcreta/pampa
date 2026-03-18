import 'package:flutter/material.dart';
import 'package:pampa/features/profile/data/models/customer_profile_model.dart';
import 'package:pampa/features/profile/domain/repositories/profile_repository.dart';

enum ProfileStatus { initial, loading, success, error }

class ProfileProvider extends ChangeNotifier {
  final ProfileRepository _repository;

  ProfileProvider(this._repository);

  ProfileStatus _status = ProfileStatus.initial;
  CustomerProfileModel? _profile;
  String _errorMessage = '';

  ProfileStatus get status => _status;
  CustomerProfileModel? get profile => _profile;
  String get errorMessage => _errorMessage;
  bool get isLoading => _status == ProfileStatus.loading;

  Future<void> fetchProfile() async {
    if (_status == ProfileStatus.loading) return;

    _status = ProfileStatus.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      _profile = await _repository.getMe();
      _status = ProfileStatus.success;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _status = ProfileStatus.error;
    }

    notifyListeners();
  }

  void refresh() => fetchProfile();
}

