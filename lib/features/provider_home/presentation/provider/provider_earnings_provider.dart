import 'package:flutter/foundation.dart';
import 'package:pampa/data/service/apiservice.dart';
import 'package:pampa/features/provider_home/data/models/provider_earnings_model.dart';

class ProviderEarningsProvider extends ChangeNotifier {
  final ApiService _api;

  ProviderEarningsProvider(this._api);

  ProviderEarningsModel? _earnings;
  bool _loading = false;
  String _error = '';

  ProviderEarningsModel? get earnings => _earnings;
  bool get loading => _loading;
  String get error => _error;

  Future<void> fetchEarnings() async {
    if (_loading) return;
    _loading = true;
    _error = '';
    notifyListeners();
    try {
      final res = await _api.getProviderEarnings();
      final map = res as Map<String, dynamic>;
      if (map['status'] == true && map['data'] != null) {
        _earnings =
            ProviderEarningsModel.fromMap(map['data'] as Map<String, dynamic>);
      } else {
        _error = map['message'] as String? ?? 'Failed to load earnings';
      }
    } catch (e) {
      _error = 'Failed to load earnings. Please try again.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void clearSession() {
    _earnings = null;
    _loading = false;
    _error = '';
    notifyListeners();
  }
}
