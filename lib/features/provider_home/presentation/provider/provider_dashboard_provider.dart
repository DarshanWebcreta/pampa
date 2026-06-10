import 'package:dio/dio.dart';
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

  Future<String?> toggleOnline({int? duration, DateTime? startDate}) async {
    if (_toggleLoading) return 'Already loading';
    _toggleLoading = true;
    final prev = _dashboard?.isOnline ?? false;
    final targetOnline = !prev;

    // Optimistic update
    if (_dashboard != null) {
      _dashboard = ProviderDashboardModel(
        isOnline: targetOnline,
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
      final body = <String, dynamic>{};
      if (duration != null) {
        body['duration'] = duration;
      }
      if (startDate != null) {
        body['start_date'] =
            "${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}";
      }

      final response = await _api.providerToggleOnline(body);
      final map = response as Map<String, dynamic>;
      if (map['status'] == true) {
        final newOnline = (map['data'] as Map<String, dynamic>?)?['is_online'] as bool? ?? targetOnline;
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
        return null;
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
        return map['message'] as String? ?? 'Failed to toggle status.';
      }
    } catch (e) {
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
      if (e is DioException && e.response?.data != null) {
        final resData = e.response!.data;
        if (resData is Map) {
          if (resData['message'] != null) {
            return resData['message'].toString();
          } else if (resData['errors'] != null) {
            final errors = resData['errors'];
            if (errors is Map && errors.isNotEmpty) {
              final firstError = errors.values.first;
              if (firstError is List && firstError.isNotEmpty) {
                return firstError.first.toString();
              }
              return firstError.toString();
            }
          }
        }
      }
      return 'Failed to toggle status. Please try again.';
    } finally {
      _toggleLoading = false;
      notifyListeners();
    }
  }

  Future<String?> toggleStatus({
    required bool isOnline,
    int? duration,
    DateTime? startDate,
  }) async {
    if (_toggleLoading) return 'Already loading';
    _toggleLoading = true;
    final prev = _dashboard?.isOnline ?? false;

    // Optimistic update
    if (_dashboard != null) {
      _dashboard = ProviderDashboardModel(
        isOnline: isOnline,
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
      final body = <String, dynamic>{
        'is_online': isOnline,
      };
      if (duration != null) {
        body['duration'] = duration;
      }
      if (startDate != null) {
        body['start_date'] =
            "${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}";
      }

      final response = await _api.providerToggleStatus(body);
      final map = response as Map<String, dynamic>;
      if (map['status'] == true) {
        final returnedOnline = (map['data'] as Map<String, dynamic>?)?['is_online'] as bool? ?? isOnline;
        if (_dashboard != null) {
          _dashboard = ProviderDashboardModel(
            isOnline: returnedOnline,
            pendingCount: _dashboard!.pendingCount,
            pendingRequests: _dashboard!.pendingRequests,
            upcomingBookings: _dashboard!.upcomingBookings,
            weeklyEarnings: _dashboard!.weeklyEarnings,
            ratingSnapshot: _dashboard!.ratingSnapshot,
            serviceMix: _dashboard!.serviceMix,
          );
        }
        return null;
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
        return map['message'] as String? ?? 'Failed to update status';
      }
    } catch (e) {
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
      if (e is DioException && e.response?.data != null) {
        final resData = e.response!.data;
        if (resData is Map) {
          if (resData['message'] != null) {
            return resData['message'].toString();
          } else if (resData['errors'] != null) {
            final errors = resData['errors'];
            if (errors is Map && errors.isNotEmpty) {
              final firstError = errors.values.first;
              if (firstError is List && firstError.isNotEmpty) {
                return firstError.first.toString();
              }
              return firstError.toString();
            }
          }
        }
      }
      return 'Failed to update status. Please try again.';
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
