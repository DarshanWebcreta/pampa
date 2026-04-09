import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pampa/core/values/urls.dart';
import 'package:pampa/data/service/apiservice.dart';

enum ProviderCredentialsStatus { initial, loading, success, error }

class ProviderCredentialsProvider extends ChangeNotifier {
  ProviderCredentialsProvider(this._api);

  final ApiService _api;
  final ImagePicker _picker = ImagePicker();

  ProviderCredentialsStatus _status = ProviderCredentialsStatus.initial;
  bool _saving = false;
  String _error = '';

  String _licensed = 'No';
  String _instagram = '';
  String _ssnLast4 = '';
  bool _backgroundConsent = false;

  String? _cosmetologyLicenseUrl;
  List<String> _specialtyCertificationUrls = [];

  XFile? _cosmetologyLicenseFile;
  List<XFile> _specialtyCertificationFiles = [];

  ProviderCredentialsStatus get status => _status;
  bool get saving => _saving;
  String get error => _error;
  String get licensed => _licensed;
  String get instagram => _instagram;
  String get ssnLast4 => _ssnLast4;
  bool get backgroundConsent => _backgroundConsent;
  String? get cosmetologyLicenseUrl => _cosmetologyLicenseUrl;
  List<String> get specialtyCertificationUrls => _specialtyCertificationUrls;
  XFile? get cosmetologyLicenseFile => _cosmetologyLicenseFile;
  List<XFile> get specialtyCertificationFiles => _specialtyCertificationFiles;

  Future<void> initialize({bool forceRefresh = false}) async {
    if (_status == ProviderCredentialsStatus.loading) return;
    if (!forceRefresh && _status == ProviderCredentialsStatus.success) return;
    _status = ProviderCredentialsStatus.loading;
    _error = '';
    notifyListeners();

    try {
      final response = await _api.getProviderSettings();
      final map = response as Map<String, dynamic>;
      final data = map['data'] as Map<String, dynamic>? ?? {};
      final credentials = data['credentials'] as Map<String, dynamic>? ?? {};

      _licensed = (credentials['licensed'] ?? 'No').toString();
      _instagram = (credentials['instagram'] ?? '').toString();
      _ssnLast4 = (credentials['ssn_last_4'] ?? '').toString();
      _backgroundConsent = credentials['background_consent'] == true;
      _cosmetologyLicenseUrl = _resolveUrl(
        credentials['cosmetology_license']?.toString(),
      );
      _specialtyCertificationUrls =
          (credentials['specialty_certifications'] as List<dynamic>? ?? [])
              .map(_extractFileUrl)
              .whereType<String>()
              .toList();

      _cosmetologyLicenseFile = null;
      _specialtyCertificationFiles = [];
      _status = ProviderCredentialsStatus.success;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _status = ProviderCredentialsStatus.error;
    }

    notifyListeners();
  }

  void setLicensed(String value) {
    _licensed = value;
    notifyListeners();
  }

  void setBackgroundConsent(bool value) {
    _backgroundConsent = value;
    notifyListeners();
  }

  void updateInstagram(String value) {
    _instagram = value;
  }

  void updateSsnLast4(String value) {
    _ssnLast4 = value;
  }

  Future<String?> pickCosmetologyLicense() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return null;
    _cosmetologyLicenseFile = file;
    notifyListeners();
    return null;
  }

  Future<String?> pickSpecialtyCertifications() async {
    final files = await _picker.pickMultiImage(imageQuality: 85);
    if (files.isEmpty) return null;
    _specialtyCertificationFiles = files;
    notifyListeners();
    return null;
  }

  Future<String?> save() async {
    _saving = true;
    notifyListeners();

    try {
      final formData = FormData.fromMap({
        'licensed': _licensed,
        if (_instagram.trim().isNotEmpty) 'instagram': _instagram.trim(),
        if (_ssnLast4.trim().isNotEmpty) 'ssn_last_4': _ssnLast4.trim(),
        'background_consent': _backgroundConsent?1:0,
        if (_cosmetologyLicenseFile != null)
          'cosmetology_license': await MultipartFile.fromFile(
            _cosmetologyLicenseFile!.path,
            filename: _cosmetologyLicenseFile!.name,
          ),
        if (_specialtyCertificationFiles.isNotEmpty)
          'specialty_certifications[]': [
            for (final file in _specialtyCertificationFiles)
              await MultipartFile.fromFile(file.path, filename: file.name),
          ],
      });

      final response = await _api.updateProviderCredentials(formData);
      final map = response as Map<String, dynamic>;
      if (map['status'] != true) {
        return map['message'] as String? ?? 'Failed to update credentials.';
      }

      _cosmetologyLicenseFile = null;
      _specialtyCertificationFiles = [];
      _status = ProviderCredentialsStatus.success;
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  String displayNameForLicense() {
    if (_cosmetologyLicenseFile != null) return _cosmetologyLicenseFile!.name;
    if (_cosmetologyLicenseUrl != null && _cosmetologyLicenseUrl!.isNotEmpty) {
      return _basename(_cosmetologyLicenseUrl!);
    }
    return 'Upload license';
  }

  List<String> certificationDisplayNames() {
    if (_specialtyCertificationFiles.isNotEmpty) {
      return _specialtyCertificationFiles.map((file) => file.name).toList();
    }
    return _specialtyCertificationUrls.map(_basename).toList();
  }

  String? _extractFileUrl(dynamic value) {
    if (value is String) return _resolveUrl(value);
    if (value is Map<String, dynamic>) {
      return _resolveUrl(
        value['file']?.toString() ??
            value['url']?.toString() ??
            value['path']?.toString(),
      );
    }
    return null;
  }

  String? _resolveUrl(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    if (trimmed.startsWith('/')) {
      return '${ApiStrings.imageUrl}$trimmed';
    }
    return '${ApiStrings.imageUrl}/$trimmed';
  }

  String _basename(String path) {
    final normalized = path.replaceAll('\\', '/');
    final segments = normalized.split('/');
    return segments.isEmpty ? path : segments.last;
  }
}
