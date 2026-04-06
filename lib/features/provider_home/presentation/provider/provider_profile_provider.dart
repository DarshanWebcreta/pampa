import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pampa/data/service/apiservice.dart';
import 'package:pampa/features/provider_home/data/models/provider_profile_model.dart';

class ProviderProfileProvider extends ChangeNotifier {
  final ApiService _api;

  ProviderProfileProvider(this._api);

  ProviderProfileModel? _profile;
  bool _loading = false;
  bool _saving = false;
  bool _galleryLoading = false;
  String _error = '';

  ProviderProfileModel? get profile => _profile;
  bool get loading => _loading;
  bool get saving => _saving;
  bool get galleryLoading => _galleryLoading;
  String get error => _error;

  Future<void> fetchProfile() async {
    if (_loading) return;
    _loading = true;
    _error = '';
    notifyListeners();
    try {
      final res = await _api.getProviderProfile();
      final map = res as Map<String, dynamic>;
      if (map['status'] == true && map['data'] != null) {
        _profile =
            ProviderProfileModel.fromMap(map['data'] as Map<String, dynamic>);
      } else {
        _error = map['message'] as String? ?? 'Failed to load profile';
      }
    } catch (e) {
      _error = 'Failed to load profile. Please try again.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<String?> updateProfile({
    required String bio,
    required String certification,
    required String licensed,
    required String streetAddress,
    required String zipCode,
    required String city,
    required String state,
    required String country,
    required String maxServiceDistance,
    required String perKmCharge,
    required String serviceZipCodes,
  }) async {
    _saving = true;
    notifyListeners();
    try {
      final formData = FormData.fromMap({
        'bio': bio,
        'certification': certification,
        'licensed': licensed,
        'street_address': streetAddress,
        'zip_code': zipCode,
        'city': city,
        'state': state,
        'country': country,
        'max_service_distance': maxServiceDistance,
        'per_km_charge': perKmCharge,
        'service_zip_codes': serviceZipCodes,
      });

      final res = await _api.updateProviderProfile(formData);
      final map = res as Map<String, dynamic>;
      if (map['status'] == true) {
        // refresh
        await fetchProfile();
        return null; // success
      }
      return map['message'] as String? ?? 'Update failed';
    } catch (e) {
      return 'Update failed. Please try again.';
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  Future<String?> uploadGalleryImages(List<File> images) async {
    if (images.isEmpty) return null;
    _galleryLoading = true;
    notifyListeners();
    try {
      final formData = FormData();
      for (final img in images) {
        formData.files.add(MapEntry(
          'images[]',
          await MultipartFile.fromFile(img.path,
              filename: img.path.split('/').last),
        ));
      }
      final res = await _api.uploadProviderGallery(formData);
      final map = res as Map<String, dynamic>;
      if (map['status'] == true) {
        await fetchProfile();
        return null;
      }
      return map['message'] as String? ?? 'Upload failed';
    } catch (e) {
      return 'Upload failed. Please try again.';
    } finally {
      _galleryLoading = false;
      notifyListeners();
    }
  }

  Future<String?> deleteGalleryImage(int imageId) async {
    try {
      final res = await _api.deleteProviderGalleryImage(imageId);
      final map = res as Map<String, dynamic>;
      if (map['status'] == true) {
        if (_profile != null) {
          _profile = _profile!.copyWith(
            gallery: _profile!.gallery.where((g) => g.id != imageId).toList(),
          );
          notifyListeners();
        }
        return null;
      }
      return map['message'] as String? ?? 'Delete failed';
    } catch (e) {
      return 'Delete failed. Please try again.';
    }
  }
}
