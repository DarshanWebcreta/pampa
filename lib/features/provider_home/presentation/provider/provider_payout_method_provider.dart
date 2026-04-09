import 'package:flutter/material.dart';
import 'package:pampa/data/service/apiservice.dart';
import 'package:pampa/features/provider_home/data/models/provider_payout_request_model.dart';

enum ProviderPayoutStatus { initial, loading, success, empty, error }

class ProviderPayoutMethodProvider extends ChangeNotifier {
  ProviderPayoutMethodProvider(this._api);

  final ApiService _api;

  ProviderPayoutStatus _status = ProviderPayoutStatus.initial;
  bool _loadingMore = false;
  bool _creating = false;
  String _error = '';

  List<ProviderPayoutRequestModel> _requests = [];
  int _currentPage = 1;
  int _lastPage = 1;
  int _total = 0;
  int _perPage = 20;

  ProviderPayoutStatus get status => _status;
  bool get loadingMore => _loadingMore;
  bool get creating => _creating;
  String get error => _error;
  List<ProviderPayoutRequestModel> get requests => _requests;
  int get currentPage => _currentPage;
  int get lastPage => _lastPage;
  int get total => _total;
  int get perPage => _perPage;
  bool get hasMore => _currentPage < _lastPage;

  Future<void> initialize({bool forceRefresh = false}) async {
    if (_status == ProviderPayoutStatus.loading) return;
    if (!forceRefresh &&
        (_status == ProviderPayoutStatus.success ||
            _status == ProviderPayoutStatus.empty)) {
      return;
    }
    await _fetchRequests(page: 1, reset: true);
  }

  Future<void> refresh() => _fetchRequests(page: 1, reset: true);

  Future<void> loadMore() async {
    if (_loadingMore || !hasMore || _status == ProviderPayoutStatus.loading) {
      return;
    }
    await _fetchRequests(page: _currentPage + 1, reset: false);
  }

  Future<String?> createRequest({required String amount, String? notes}) async {
    _creating = true;
    notifyListeners();

    try {
      final response = await _api.createPayoutRequest({
        'amount': double.parse(amount.trim()),
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      });
      final map = response as Map<String, dynamic>;
      if (map['status'] != true) {
        return map['message'] as String? ?? 'Failed to submit payout request.';
      }

      final data = map['data'] as Map<String, dynamic>? ?? {};
      final created = ProviderPayoutRequestModel.fromMap(data);
      _requests = [created, ..._requests];
      _total += 1;
      _status = ProviderPayoutStatus.success;
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    } finally {
      _creating = false;
      notifyListeners();
    }
  }

  Future<void> _fetchRequests({required int page, required bool reset}) async {
    if (reset) {
      _status = ProviderPayoutStatus.loading;
      _error = '';
      notifyListeners();
    } else {
      _loadingMore = true;
      notifyListeners();
    }

    try {
      final response = await _api.getPayoutRequests(
        perPage: _perPage,
        page: page,
      );
      final map = response as Map<String, dynamic>;
      final data = map['data'] as Map<String, dynamic>? ?? {};
      final items = (data['data'] as List<dynamic>? ?? [])
          .map(
            (item) => ProviderPayoutRequestModel.fromMap(
              item as Map<String, dynamic>,
            ),
          )
          .toList();

      _currentPage = data['current_page'] as int? ?? page;
      _lastPage = data['last_page'] as int? ?? _currentPage;
      _total = data['total'] as int? ?? items.length;
      _perPage = data['per_page'] as int? ?? _perPage;

      _requests = reset ? items : [..._requests, ...items];
      _status = _requests.isEmpty
          ? ProviderPayoutStatus.empty
          : ProviderPayoutStatus.success;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _status = ProviderPayoutStatus.error;
    } finally {
      _loadingMore = false;
      notifyListeners();
    }
  }
}
