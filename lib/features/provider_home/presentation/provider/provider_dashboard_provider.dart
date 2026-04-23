import 'package:flutter/material.dart';
import 'package:pampa/data/service/apiservice.dart';
import 'package:pampa/features/provider_home/data/models/provider_dashboard_model.dart';

class ProviderDashboardProvider extends ChangeNotifier {
  final ApiService _api;

  ProviderDashboardProvider(this._api);

  ProviderDashboardModel? _dashboard;
  bool _loading = false;
  bool _toggleLoading = false;
  String _error = '';

  ProviderDashboardModel? get dashboard => _dashboard;
  bool get loading => _loading;
  bool get toggleLoading => _toggleLoading;
  String get error => _error;
  bool get isOnline => _dashboard?.isOnline ?? false;

  Future<void> fetchDashboard() async {
    _loading = true;
    _error = '';
    notifyListeners();

    try {
      final response = await _api.getProviderDashboard();
      final map = response as Map<String, dynamic>;
      if (map['status'] == true && map['data'] != null) {
        _dashboard = ProviderDashboardModel.fromJson(
            map['data'] as Map<String, dynamic>);
      } else {
        _error = map['message'] as String? ?? 'Failed to load dashboard.';
      }
    } catch (e) {
      _error = 'Failed to load dashboard. Please try again.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> toggleOnline() async {
    if (_toggleLoading) return;
    _toggleLoading = true;
    final prev = _dashboard?.isOnline ?? false;

    // Optimistic update
    if (_dashboard != null) {
      _dashboard = ProviderDashboardModel(
        isOnline: !prev,
        pendingCount: _dashboard!.pendingCount,
        pendingRequests: _dashboard!.pendingRequests,
        upcomingBookings: _dashboard!.upcomingBookings,
        weeklyEarnings: _dashboard!.weeklyEarnings,
        ratingSnapshot: _dashboard!.ratingSnapshot,
        serviceMix: _dashboard!.serviceMix,
      );
    }
    notifyListeners();

    try {
      final response = await _api.providerToggleOnline();
      final map = response as Map<String, dynamic>;
      if (map['status'] == true && map['data'] != null) {
        final newOnline = (map['data'] as Map<String, dynamic>)['is_online'] as bool? ?? !prev;
        if (_dashboard != null) {
          _dashboard = ProviderDashboardModel(
            isOnline: newOnline,
            pendingCount: _dashboard!.pendingCount,
            pendingRequests: _dashboard!.pendingRequests,
            upcomingBookings: _dashboard!.upcomingBookings,
            weeklyEarnings: _dashboard!.weeklyEarnings,
            ratingSnapshot: _dashboard!.ratingSnapshot,
            serviceMix: _dashboard!.serviceMix,
          );
        }
      } else {
        // Rollback
        if (_dashboard != null) {
          _dashboard = ProviderDashboardModel(
            isOnline: prev,
            pendingCount: _dashboard!.pendingCount,
            pendingRequests: _dashboard!.pendingRequests,
            upcomingBookings: _dashboard!.upcomingBookings,
            weeklyEarnings: _dashboard!.weeklyEarnings,
            ratingSnapshot: _dashboard!.ratingSnapshot,
            serviceMix: _dashboard!.serviceMix,
          );
        }
      }
    } catch (_) {
      // Rollback
      if (_dashboard != null) {
        _dashboard = ProviderDashboardModel(
          isOnline: prev,
          pendingCount: _dashboard!.pendingCount,
          pendingRequests: _dashboard!.pendingRequests,
          upcomingBookings: _dashboard!.upcomingBookings,
          weeklyEarnings: _dashboard!.weeklyEarnings,
          ratingSnapshot: _dashboard!.ratingSnapshot,
          serviceMix: _dashboard!.serviceMix,
        );
      }
    } finally {
      _toggleLoading = false;
      notifyListeners();
    }
  }

  void clearSession() {
    _dashboard = null;
    _loading = false;
    _toggleLoading = false;
    _error = '';
    notifyListeners();
  }
}
