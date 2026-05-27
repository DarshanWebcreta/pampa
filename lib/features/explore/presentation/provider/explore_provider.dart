import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pampa/features/booking/data/models/provider_model.dart';
import 'package:pampa/features/explore/data/models/explore_model.dart';
import 'package:pampa/features/explore/domain/repositories/explore_repository.dart';
import 'package:pampa/data/service/di.dart';
import 'package:pampa/features/address/presentation/provider/address_provider.dart';

enum ExploreFetchStatus { initial, loading, success, error }

class ExploreProvider extends ChangeNotifier {
  final ExploreRepository _repository;

  ExploreProvider(this._repository);

  ExploreFetchStatus _status = ExploreFetchStatus.initial;
  ExploreResultModel? _result;
  String _error = '';
  String _query = '';
  Timer? _debounce;

  ExploreFetchStatus get status => _status;
  ExploreResultModel? get result => _result;
  String get error => _error;
  String get query => _query;

  Future<void> fetch({
    String? query,
    String? zipCode,
  }) async {
    _query = query ?? '';
    _status = ExploreFetchStatus.loading;
    _error = '';
    notifyListeners();

    try {
      final addressProvider = getIt<AddressProvider>();
      final address = addressProvider.selectedAddress;

      _result = await _repository.explore(
        query: _query.isEmpty ? null : _query,
        zipCode: zipCode ?? address?.zipCode,
      );
      _status = ExploreFetchStatus.success;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _status = ExploreFetchStatus.error;
    }

    notifyListeners();
  }

  void onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      fetch(query: value.trim());
    });
  }

  void clearSearch() {
    _debounce?.cancel();
    fetch(query: null);
  }

  Future<ProviderModel?> fetchProviderDetail(int id) async {
    try {
      return await _repository.getProviderDetail(id);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
