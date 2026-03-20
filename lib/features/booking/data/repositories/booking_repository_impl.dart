import 'package:dio/dio.dart';
import 'package:pampa/core/error/exception.dart';
import 'package:pampa/data/service/apiservice.dart';
import 'package:pampa/features/booking/data/models/provider_model.dart';
import 'package:pampa/features/booking/data/models/time_slot_model.dart';
import 'package:pampa/features/booking/domain/repositories/booking_repository.dart';
import 'package:pampa/features/services/data/models/service_model.dart';

class BookingRepositoryImpl implements BookingRepository {
  final ApiService _apiService;

  BookingRepositoryImpl(this._apiService);

  @override
  Future<ServiceModel> getServiceDetail(int id) async {
    try {
      final response = await _apiService.serviceDetails(id);
      final map = response as Map<String, dynamic>;
      if (map['status'] == true) {
        return ServiceModel.fromJson(map['data'] as Map<String, dynamic>);
      }
      throw Exception(map['message'] ?? 'Failed to load service details.');
    } on DioException catch (e) {
      throw Exception(HandleExeption.handleError(e));
    } on Exception {
      rethrow;
    } catch (_) {
      throw Exception('Something went wrong. Please try again.');
    }
  }

  @override
  Future<List<ProviderModel>> getProviders(String zipCode) async {
    try {
      final response = await _apiService.getProviders(zipCode);
      final map = response as Map<String, dynamic>;
      if (map['status'] == true) {
        final data = map['data'] as List<dynamic>? ?? [];
        return data
            .map((e) => ProviderModel.fromJson(e as Map<String, dynamic>))
            .where((p) => p.isActive)
            .toList();
      }
      throw Exception(map['message'] ?? 'Failed to load providers.');
    } on DioException catch (e) {
      throw Exception(HandleExeption.handleError(e));
    } on Exception {
      rethrow;
    } catch (_) {
      throw Exception('Something went wrong. Please try again.');
    }
  }

  @override
  Future<List<TimeSlotModel>> getAvailableSlots({
    required int providerId,
    required String date,
    required int serviceId,
  }) async {
    try {
      final response =
          await _apiService.getAvailableSlots(providerId, date, serviceId);
      final map = response as Map<String, dynamic>;
      if (map['status'] == true) {
        final data = map['data'] as Map<String, dynamic>? ?? {};
        // Prefer available_slots (already filtered), fall back to slots
        final rawSlots = data['available_slots'] as List<dynamic>? ??
            data['slots'] as List<dynamic>? ??
            [];
        return rawSlots
            .map((e) => TimeSlotModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw Exception(map['message'] ?? 'Failed to load time slots.');
    } on DioException catch (e) {
      throw Exception(HandleExeption.handleError(e));
    } on Exception {
      rethrow;
    } catch (_) {
      throw Exception('Something went wrong. Please try again.');
    }
  }

  @override
  Future<String> createBooking({
    required int serviceId,
    required int providerId,
    required String appointmentDate,
    required String appointmentTime,
  }) async {
    try {
      final response = await _apiService.createBooking({
        'service_id': serviceId,
        'provider_id': providerId,
        'appointment_date': appointmentDate,
        'appointment_time': appointmentTime,
      });

      final map = response as Map<String, dynamic>;
      if (map['status'] == true) {
        return map['message'] as String? ?? 'Booking successful';
      }
      throw Exception(map['message'] ?? 'Booking failed. Please try again.');
    } on DioException catch (e) {
      final serverMessage = _extractServerMessage(e);
      throw Exception(serverMessage ?? HandleExeption.handleError(e));
    } on Exception {
      rethrow;
    } catch (_) {
      throw Exception('Something went wrong. Please try again.');
    }
  }

  @override
  Future<String> createCheckoutSession({
    required int serviceId,
    required num price,
    required num tipAmount,
    required int addressId,
    required int providerId,
    required String appointmentDate,
    required String appointmentTime,
  }) async {
    try {
      final response = await _apiService.createCheckoutSession({
        'service_id': serviceId,
        'price': price,
        'tip_amount': tipAmount,
        'address_id': addressId,
        'provider_id': providerId,
        'appointment_date': appointmentDate,
        'appointment_time': appointmentTime,
      });

      final map = response as Map<String, dynamic>;
      if (map['status'] == true) {
        final data = map['data'];
        if (data is Map<String, dynamic>) {
          final url = data['url']?.toString();
          if (url != null && url.isNotEmpty) return url;
        }
        throw Exception('Invalid checkout session response.');
      }

      throw Exception(
          map['message'] ?? 'Failed to create checkout session.');
    } on DioException catch (e) {
      final serverMessage = _extractServerMessage(e);
      throw Exception(serverMessage ?? HandleExeption.handleError(e));
    } on Exception {
      rethrow;
    } catch (_) {
      throw Exception('Something went wrong. Please try again.');
    }
  }

  String? _extractServerMessage(DioException e) {
    try {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        if (data['message'] != null) return data['message'].toString();
        if (data['errors'] is Map) {
          final errors = data['errors'] as Map<String, dynamic>;
          final first = errors.values.first;
          if (first is List && first.isNotEmpty) return first.first.toString();
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
