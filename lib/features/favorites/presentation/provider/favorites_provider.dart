import 'package:flutter/material.dart';
import 'package:pampa/data/service/apiservice.dart';

class FavoritesProvider extends ChangeNotifier {
  final ApiService _apiService;

  FavoritesProvider(this._apiService);

  final Set<int> _favoriteIds = {};
  final Set<int> _pending = {};

  bool isFavorite(int providerId) => _favoriteIds.contains(providerId);

  Future<void> toggleFavorite(int providerId) async {
    if (_pending.contains(providerId)) return;
    _pending.add(providerId);

    final wasFavorite = _favoriteIds.contains(providerId);

    // Optimistic update
    if (wasFavorite) {
      _favoriteIds.remove(providerId);
    } else {
      _favoriteIds.add(providerId);
    }
    notifyListeners();

    try {
      if (wasFavorite) {
        await _apiService.removeFavoriteProvider(providerId);
      } else {
        await _apiService.addFavoriteProvider({'provider_id': providerId.toString()});
      }
    } catch (_) {
      // Revert on failure
      if (wasFavorite) {
        _favoriteIds.add(providerId);
      } else {
        _favoriteIds.remove(providerId);
      }
      notifyListeners();
    } finally {
      _pending.remove(providerId);
    }
  }
}
