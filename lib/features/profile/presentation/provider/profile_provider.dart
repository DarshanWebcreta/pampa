import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:pampa/data/service/apiservice.dart';
import 'package:pampa/data/service/di.dart';
import 'package:pampa/features/profile/data/models/customer_profile_model.dart';
import 'package:pampa/features/profile/domain/repositories/profile_repository.dart';

class PageModel {
  final int id;
  final String title;
  final String slug;

  const PageModel({required this.id, required this.title, required this.slug});

  factory PageModel.fromJson(Map<String, dynamic> json) => PageModel(
        id: json['id'] as int? ?? 0,
        title: json['title'] as String? ?? '',
        slug: json['slug'] as String? ?? '',
      );
}

enum ProfileStatus { initial, loading, success, error }

enum ProfileUpdateStatus { idle, loading, done, failed }

class ProfileProvider extends ChangeNotifier {
  final ProfileRepository _repository;
  final ApiService _api = getIt<ApiService>();

  ProfileProvider(this._repository);

  ProfileStatus _status = ProfileStatus.initial;
  CustomerProfileModel? _profile;
  String _errorMessage = '';
  List<PageModel> _pages = [];

  ProfileUpdateStatus _updateStatus = ProfileUpdateStatus.idle;
  String _updateError = '';

  ProfileStatus get status => _status;
  CustomerProfileModel? get profile => _profile;
  String get errorMessage => _errorMessage;
  bool get isLoading => _status == ProfileStatus.loading;
  List<PageModel> get pages => _pages;
  ProfileUpdateStatus get updateStatus => _updateStatus;
  String get updateError => _updateError;

  Future<void> fetchProfile() async {
    if (_status == ProfileStatus.loading) return;

    _status = ProfileStatus.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.getMe(),
        _fetchPages(),
      ]);
      _profile = results[0] as CustomerProfileModel;
      _status = ProfileStatus.success;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _status = ProfileStatus.error;
    }

    notifyListeners();
  }

  Future<bool> updateProfile({
    required String firstName,
    required String lastName,
    required String email,
    required String mobile,
    String? streetAddress,
    String? zipCode,
    String? city,
    String? state,
    String? country,
    File? photo,
  }) async {
    _updateStatus = ProfileUpdateStatus.loading;
    _updateError = '';
    notifyListeners();

    try {
      final fields = <MapEntry<String, MultipartFile>>[];
      final Map<String, String> formFields = {
        'first_name': firstName,
        'last_name': lastName,
        'name': '$firstName $lastName'.trim(),
        'email': email,
        'mobile': mobile,
        if (streetAddress != null && streetAddress.isNotEmpty)
          'street_address': streetAddress,
        if (zipCode != null && zipCode.isNotEmpty) 'zip_code': zipCode,
        if (city != null && city.isNotEmpty) 'city': city,
        if (state != null && state.isNotEmpty) 'state': state,
        if (country != null && country.isNotEmpty) 'country': country,
      };

      if (photo != null) {
        fields.add(MapEntry(
          'profile_image',
          await MultipartFile.fromFile(photo.path,
              filename: photo.path.split('/').last),
        ));
      }

      final formData = FormData.fromMap({
        ...formFields,
        ...Map.fromEntries(fields),
      });

      _profile = await _repository.updateProfile(formData);
      _updateStatus = ProfileUpdateStatus.done;
      notifyListeners();
      return true;
    } catch (e) {
      _updateError = e.toString().replaceFirst('Exception: ', '');
      _updateStatus = ProfileUpdateStatus.failed;
      notifyListeners();
      return false;
    }
  }

  void resetUpdateStatus() {
    _updateStatus = ProfileUpdateStatus.idle;
    _updateError = '';
    notifyListeners();
  }

  Future<void> _fetchPages() async {
    try {
      final response = await _api.getPages();
      final map = response as Map<String, dynamic>;
      if (map['status'] == true) {
        _pages = (map['data'] as List<dynamic>)
            .map((e) => PageModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      // Pages failing should not break profile load
    }
  }

  void refresh() => fetchProfile();
}
