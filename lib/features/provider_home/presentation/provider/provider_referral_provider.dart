import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:pampa/core/error/exception.dart';
import 'package:pampa/data/service/apiservice.dart';
import 'package:pampa/features/provider_home/data/models/provider_referral_model.dart';

enum ReferralStatus { initial, loading, loaded, error }

class ProviderReferralProvider extends ChangeNotifier {
  final ApiService _apiService;

  ProviderReferralProvider(this._apiService);

  ReferralStatus _status = ReferralStatus.initial;
  ReferralStatus get status => _status;

  ProviderReferralModel? _referralData;
  ProviderReferralModel? get referralData => _referralData;

  String _error = '';
  String get error => _error;

  Future<void> fetchReferralStats() async {
    _status = ReferralStatus.loading;
    _error = '';
    notifyListeners();

    try {
      final response = await _apiService.getProviderReferralsStats();
      final map = response as Map<String, dynamic>;

      if (map['status'] == true) {
        final data = map['data'] as Map<String, dynamic>;
        _referralData = ProviderReferralModel.fromJson(data);
        _status = ReferralStatus.loaded;
      } else {
        _error = map['message']?.toString() ?? 'Failed to load referral data.';
        _status = ReferralStatus.error;
      }
    } on DioException catch (e) {
      _error = HandleExeption.handleError(e);
      _status = ReferralStatus.error;
    } catch (e) {
      _error = e.toString();
      _status = ReferralStatus.error;
    }
    notifyListeners();
  }

  void clearSession() {
    _status = ReferralStatus.initial;
    _referralData = null;
    _error = '';
    notifyListeners();
  }
}
