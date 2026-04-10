import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:pampa/core/error/exception.dart';
import 'package:pampa/data/service/apiservice.dart';
import 'package:pampa/features/provider_home/data/models/bank_detail_model.dart';

enum BankDetailStatus { initial, loading, loaded, error, saving, saved }

class ProviderBankDetailProvider extends ChangeNotifier {
  final ApiService _apiService;

  ProviderBankDetailProvider(this._apiService);

  BankDetailStatus _status = BankDetailStatus.initial;
  BankDetailStatus get status => _status;

  BankDetailModel? _bankDetail;
  BankDetailModel? get bankDetail => _bankDetail;

  String _error = '';
  String get error => _error;

  Future<void> fetchBankDetails() async {
    _status = BankDetailStatus.loading;
    _error = '';
    notifyListeners();

    try {
      final response = await _apiService.bankDetails();
      final map = response as Map<String, dynamic>;
      
      if (map['status'] == true) {
        final data = map['data'] as Map<String, dynamic>;
        _bankDetail = BankDetailModel.fromJson(data);
        _status = BankDetailStatus.loaded;
      } else {
        _error = map['message']?.toString() ?? 'Failed to load bank details.';
        _status = BankDetailStatus.error;
      }
    } on DioException catch (e) {
      _error = HandleExeption.handleError(e);
      _status = BankDetailStatus.error;
    } catch (e) {
      _error = e.toString();
      _status = BankDetailStatus.error;
    }
    notifyListeners();
  }

  Future<String?> saveBankDetails({
    required String bankName,
    required String accountHolderName,
    required String accountNumber,
    required String routingNumber,
    required String accountType,
  }) async {
    _status = BankDetailStatus.saving;
    notifyListeners();

    try {
      final response = await _apiService.saveBankDetails({
        'bank_name': bankName,
        'account_holder_name': accountHolderName,
        'account_number': accountNumber,
        'routing_number': routingNumber,
        'account_type': accountType,
      });

      final map = response as Map<String, dynamic>;
      if (map['status'] == true) {
        final data = map['data'] as Map<String, dynamic>;
        _bankDetail = BankDetailModel.fromJson(data);
        _status = BankDetailStatus.saved;
        notifyListeners();
        return null; // Success
      } else {
        _status = BankDetailStatus.loaded; // Revert to loaded state
        notifyListeners();
        return map['message']?.toString() ?? 'Failed to save bank details.';
      }
    } on DioException catch (e) {
      _status = BankDetailStatus.loaded;
      notifyListeners();
      return HandleExeption.handleError(e);
    } catch (e) {
      _status = BankDetailStatus.loaded;
      notifyListeners();
      return e.toString();
    }
  }

  void resetSavedStatus() {
    if (_status == BankDetailStatus.saved) {
      _status = BankDetailStatus.loaded;
      notifyListeners();
    }
  }
}
