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

  Future<ToggleResult> toggleOnline({DateTime? endDate, DateTime? startDate}) async {
    if (_toggleLoading) return ToggleResult(success: false, message: 'Already loading');
    _toggleLoading = true;
    final prev = _dashboard?.isOnline ?? false;
    final targetOnline = !prev;

    // Optimistic update
    if (_dashboard != null) {
      _dashboard = ProviderDashboardModel(
        isOnline: targetOnline,
        offlineMessage: targetOnline ? null : _dashboard!.offlineMessage,
        unavailableFrom: targetOnline ? null : _dashboard!.unavailableFrom,
        unavailableTo: targetOnline ? null : _dashboard!.unavailableTo,
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
      if (endDate != null) {
        body['end_date'] =
            "${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}";
      }
      if (startDate != null) {
        body['start_date'] =
            "${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}";
      }

      final response = await _api.providerToggleOnline(body);
      final map = response as Map<String, dynamic>;
      if (map['status'] == true) {
        final dataMap = map['data'] as Map<String, dynamic>?;
        final newOnline = dataMap?['is_online'] as bool? ?? targetOnline;
        final newOfflineMsg = dataMap?['offline_message'] as String?;
        final newUnavailableFrom = dataMap?['unavailable_from'] as String?;
        final newUnavailableTo = dataMap?['unavailable_to'] as String?;
        if (_dashboard != null) {
          _dashboard = ProviderDashboardModel(
            isOnline: newOnline,
            offlineMessage: newOfflineMsg,
            unavailableFrom: newUnavailableFrom,
            unavailableTo: newUnavailableTo,
            pendingCount: _dashboard!.pendingCount,
            pendingRequests: _dashboard!.pendingRequests,
            upcomingBookings: _dashboard!.upcomingBookings,
            weeklyEarnings: _dashboard!.weeklyEarnings,
            ratingSnapshot: _dashboard!.ratingSnapshot,
            serviceMix: _dashboard!.serviceMix,
          );
        }
        return ToggleResult(
          success: true,
          message: map['message'] as String? ?? 'Status updated successfully.',
        );
      } else {
        // Rollback
        if (_dashboard != null) {
          _dashboard = ProviderDashboardModel(
            isOnline: prev,
            offlineMessage: _dashboard!.offlineMessage,
            unavailableFrom: _dashboard!.unavailableFrom,
            unavailableTo: _dashboard!.unavailableTo,
            pendingCount: _dashboard!.pendingCount,
            pendingRequests: _dashboard!.pendingRequests,
            upcomingBookings: _dashboard!.upcomingBookings,
            weeklyEarnings: _dashboard!.weeklyEarnings,
            ratingSnapshot: _dashboard!.ratingSnapshot,
            serviceMix: _dashboard!.serviceMix,
          );
        }
        return ToggleResult(
          success: false,
          message: map['message'] as String? ?? 'Failed to toggle status.',
        );
      }
    } catch (e) {
      // Rollback
      if (_dashboard != null) {
        _dashboard = ProviderDashboardModel(
          isOnline: prev,
          offlineMessage: _dashboard!.offlineMessage,
          unavailableFrom: _dashboard!.unavailableFrom,
          unavailableTo: _dashboard!.unavailableTo,
          pendingCount: _dashboard!.pendingCount,
          pendingRequests: _dashboard!.pendingRequests,
          upcomingBookings: _dashboard!.upcomingBookings,
          weeklyEarnings: _dashboard!.weeklyEarnings,
          ratingSnapshot: _dashboard!.ratingSnapshot,
          serviceMix: _dashboard!.serviceMix,
        );
      }
      String? firstError;
      if (e is DioException && e.response?.data != null) {
        final resData = e.response!.data;
        if (resData is Map) {
          if (resData['message'] != null) {
            firstError = resData['message'].toString();
          } else if (resData['errors'] != null) {
            final errors = resData['errors'];
            if (errors is Map && errors.isNotEmpty) {
              final val = errors.values.first;
              if (val is List && val.isNotEmpty) {
                firstError = val.first.toString();
              } else {
                firstError = val.toString();
              }
            }
          }
        }
      }
      return ToggleResult(
        success: false,
        message: firstError ?? 'Failed to toggle status. Please try again.',
      );
    } finally {
      _toggleLoading = false;
      notifyListeners();
    }
  }

  Future<ToggleResult> toggleStatus({
    required bool isOnline,
    DateTime? endDate,
    DateTime? startDate,
  }) async {
    if (_toggleLoading) return ToggleResult(success: false, message: 'Already loading');
    _toggleLoading = true;
    final prev = _dashboard?.isOnline ?? false;

    // Optimistic update
    if (_dashboard != null) {
      _dashboard = ProviderDashboardModel(
        isOnline: isOnline,
        offlineMessage: isOnline ? null : _dashboard!.offlineMessage,
        unavailableFrom: isOnline ? null : _dashboard!.unavailableFrom,
        unavailableTo: isOnline ? null : _dashboard!.unavailableTo,
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
      if (endDate != null) {
        body['end_date'] =
            "${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}";
        if (startDate != null) {
          final calculatedDuration = endDate.difference(startDate).inDays + 1;
          body['duration'] = calculatedDuration;
        }
      }
      if (startDate != null) {
        body['start_date'] =
            "${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}";
      }

      final response = await _api.providerToggleStatus(body);
      final map = response as Map<String, dynamic>;
      if (map['status'] == true) {
        final dataMap = map['data'] as Map<String, dynamic>?;
        final returnedOnline = dataMap?['is_online'] as bool? ?? isOnline;
        final newOfflineMsg = dataMap?['offline_message'] as String?;
        final newUnavailableFrom = dataMap?['unavailable_from'] as String?;
        final newUnavailableTo = dataMap?['unavailable_to'] as String?;
        if (_dashboard != null) {
          _dashboard = ProviderDashboardModel(
            isOnline: returnedOnline,
            offlineMessage: newOfflineMsg,
            unavailableFrom: newUnavailableFrom,
            unavailableTo: newUnavailableTo,
            pendingCount: _dashboard!.pendingCount,
            pendingRequests: _dashboard!.pendingRequests,
            upcomingBookings: _dashboard!.upcomingBookings,
            weeklyEarnings: _dashboard!.weeklyEarnings,
            ratingSnapshot: _dashboard!.ratingSnapshot,
            serviceMix: _dashboard!.serviceMix,
          );
        }
        return ToggleResult(
          success: true,
          message: map['message'] as String? ?? 'Status updated successfully.',
        );
      } else {
        // Rollback
        if (_dashboard != null) {
          _dashboard = ProviderDashboardModel(
            isOnline: prev,
            offlineMessage: _dashboard!.offlineMessage,
            unavailableFrom: _dashboard!.unavailableFrom,
            unavailableTo: _dashboard!.unavailableTo,
            pendingCount: _dashboard!.pendingCount,
            pendingRequests: _dashboard!.pendingRequests,
            upcomingBookings: _dashboard!.upcomingBookings,
            weeklyEarnings: _dashboard!.weeklyEarnings,
            ratingSnapshot: _dashboard!.ratingSnapshot,
            serviceMix: _dashboard!.serviceMix,
          );
        }
        return ToggleResult(
          success: false,
          message: map['message'] as String? ?? 'Failed to update status.',
        );
      }
    } catch (e) {
      // Rollback
      if (_dashboard != null) {
        _dashboard = ProviderDashboardModel(
          isOnline: prev,
          offlineMessage: _dashboard!.offlineMessage,
          unavailableFrom: _dashboard!.unavailableFrom,
          unavailableTo: _dashboard!.unavailableTo,
          pendingCount: _dashboard!.pendingCount,
          pendingRequests: _dashboard!.pendingRequests,
          upcomingBookings: _dashboard!.upcomingBookings,
          weeklyEarnings: _dashboard!.weeklyEarnings,
          ratingSnapshot: _dashboard!.ratingSnapshot,
          serviceMix: _dashboard!.serviceMix,
        );
      }
      String? firstError;
      if (e is DioException && e.response?.data != null) {
        final resData = e.response!.data;
        if (resData is Map) {
          if (resData['message'] != null) {
            firstError = resData['message'].toString();
          } else if (resData['errors'] != null) {
            final errors = resData['errors'];
            if (errors is Map && errors.isNotEmpty) {
              final val = errors.values.first;
              if (val is List && val.isNotEmpty) {
                firstError = val.first.toString();
              } else {
                firstError = val.toString();
              }
            }
          }
        }
      }
      return ToggleResult(
        success: false,
        message: firstError ?? 'Failed to update status. Please try again.',
      );
    } finally {
      _toggleLoading = false;
      notifyListeners();
    }
  }

  Future<ToggleResult> cancelOffline() async {
    if (_toggleLoading) return ToggleResult(success: false, message: 'Already loading');
    _toggleLoading = true;
    notifyListeners();

    try {
      final response = await _api.providerCancelOffline();
      final map = response as Map<String, dynamic>;
      if (map['status'] == true) {
        final dataMap = map['data'] as Map<String, dynamic>?;
        final returnedOnline = dataMap?['is_online'] as bool? ?? true;
        final newOfflineMsg = dataMap?['offline_message'] as String?;
        final newUnavailableFrom = dataMap?['unavailable_from'] as String?;
        final newUnavailableTo = dataMap?['unavailable_to'] as String?;
        
        if (_dashboard != null) {
          _dashboard = ProviderDashboardModel(
            isOnline: returnedOnline,
            offlineMessage: newOfflineMsg,
            unavailableFrom: newUnavailableFrom,
            unavailableTo: newUnavailableTo,
            pendingCount: _dashboard!.pendingCount,
            pendingRequests: _dashboard!.pendingRequests,
            upcomingBookings: _dashboard!.upcomingBookings,
            weeklyEarnings: _dashboard!.weeklyEarnings,
            ratingSnapshot: _dashboard!.ratingSnapshot,
            serviceMix: _dashboard!.serviceMix,
          );
        }
        return ToggleResult(
          success: true,
          message: map['message'] as String? ?? 'Status updated successfully.',
        );
      } else {
        return ToggleResult(
          success: false,
          message: map['message'] as String? ?? 'Failed to cancel offline status.',
        );
      }
    } catch (e) {
      String? firstError;
      if (e is DioException && e.response?.data != null) {
        final resData = e.response!.data;
        if (resData is Map) {
          if (resData['message'] != null) {
            firstError = resData['message'].toString();
          } else if (resData['errors'] != null) {
            final errors = resData['errors'];
            if (errors is Map && errors.isNotEmpty) {
              final val = errors.values.first;
              if (val is List && val.isNotEmpty) {
                firstError = val.first.toString();
              } else {
                firstError = val.toString();
              }
            }
          }
        }
      }
      return ToggleResult(
        success: false,
        message: firstError ?? 'Failed to cancel offline status. Please try again.',
      );
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

class ToggleResult {
  final bool success;
  final String message;

  ToggleResult({required this.success, required this.message});
}
