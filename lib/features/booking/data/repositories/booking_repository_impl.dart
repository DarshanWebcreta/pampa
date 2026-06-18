import 'package:dio/dio.dart';
import 'package:pampa/core/error/exception.dart';
import 'package:pampa/data/service/apiservice.dart';
import 'package:pampa/features/booking/data/models/available_slots_response.dart';
import 'package:pampa/features/booking/data/models/provider_model.dart';
import 'package:pampa/features/booking/data/models/slot_model.dart';
import 'package:pampa/features/booking/domain/repositories/booking_repository.dart';
import 'package:pampa/features/services/data/models/service_model.dart';

class BookingRepositoryImpl implements BookingRepository {
  final ApiService _apiService;

  BookingRepositoryImpl(this._apiService);

  @override
  Future<List<SlotModel>> getAvailableSlots({
    required int providerId,
    required String date,
    required int serviceId,
  }) async {
    try {
      final response = await _apiService.getAvailableSlots(
        providerId,
        date,
        serviceId,
      );

      final result = AvailableSlotsResponse.fromJson(response);
      
      // If result is successful, return the slots. 
      // We can also filter for 'available' here if the UI only wants available ones,
      // but the UI might want to show unavailable ones as disabled.
      return result.slots;
    } on DioException catch (e) {
      throw Exception(_extractServerMessage(e) ?? HandleExeption.handleError(e));
    } catch (e) {
      throw Exception(e.toString());
    }
  }

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
  Future<List<ProviderModel>> getProviders(String? zipCode, {int? serviceId}) async {
    try {
      final response = await _apiService.getProviders(zipCode, serviceId);
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
  Future<dynamic> getDistanceCharge({
    required int providerId,
    required String customerZip,
  }) async {
    try {
      final response = await _apiService.getDistanceCharge(providerId, customerZip);
      return response;
    } on DioException catch (e) {
      throw Exception(HandleExeption.handleError(e));
    } on Exception {
      rethrow;
    } catch (_) {
      throw Exception('Something went wrong. Please try again.');
    }
  }

  @override
  Future<List<ProviderModel>> getAvailableProviders({
    required List<int> serviceIds,
    required String zipCode,
    required String date,
    required String time,
  }) async {
    try {
      final response = await _apiService.getAvailableProviders(
        serviceIds,
        zipCode,
        date,
        time,
      );
      final map = response as Map<String, dynamic>;
      if (map['status'] == true) {
        final data = map['data'] as List<dynamic>? ?? [];
        return data
            .map((e) => ProviderModel.fromJson(e as Map<String, dynamic>))
            .where((p) => p.isActive)
            .toList();
      }
      throw Exception(map['message'] ?? 'Failed to load available providers.');
    } on DioException catch (e) {
      throw Exception(HandleExeption.handleError(e));
    } on Exception {
      rethrow;
    } catch (_) {
      throw Exception('Something went wrong. Please try again.');
    }
  }


  @override
  Future<({int? bookingId, String message, String? paymentLink})> createBooking({
    required List<int> serviceIds,
    required int providerId,
    int? addressId,
    required String appointmentDate,
    required String appointmentTime,
    num? tipAmount,
    String? notes,
    String? pinterestLink,
    String? inspirationPhotoPath,
  }) async {
    try {
      final formData = FormData();

      for (int i = 0; i < serviceIds.length; i++) {
        formData.fields.add(
          MapEntry('service_ids[$i]', serviceIds[i].toString()),
        );
      }

      formData.fields.add(MapEntry('provider_id', providerId.toString()));
      formData.fields.add(MapEntry('appointment_date', appointmentDate));
      formData.fields.add(MapEntry('appointment_time', appointmentTime));

      if (addressId != null) {
        formData.fields.add(MapEntry('address_id', addressId.toString()));
      }
      if (tipAmount != null) {
        formData.fields.add(MapEntry('tip_amount', tipAmount.toString()));
      }
      if (notes != null && notes.trim().isNotEmpty) {
        formData.fields.add(MapEntry('notes', notes.trim()));
      }
      if (pinterestLink != null && pinterestLink.trim().isNotEmpty) {
        formData.fields.add(MapEntry('pinterest_link', pinterestLink.trim()));
      }
      if (inspirationPhotoPath != null && inspirationPhotoPath.isNotEmpty) {
        formData.files.add(MapEntry(
          'inspiration_photo',
          await MultipartFile.fromFile(
            inspirationPhotoPath,
            filename: inspirationPhotoPath.split('/').last,
          ),
        ));
      }

      final response = await _apiService.createBooking(formData);

      if (response is! Map<String, dynamic>) {
        throw Exception('Booking failed. Please try again.');
      }
      if (response['status'] == true) {
        final message =
            response['message'] as String? ?? 'Booking successful';
        final data = response['data'];
        int? bookingId;
        String? paymentLink;
        if (data is Map<String, dynamic>) {
          bookingId = data['id'] as int?;
          final link = data['payment_link']?.toString();
          if (link != null && link.isNotEmpty) paymentLink = link;
        }
        return (bookingId: bookingId, message: message, paymentLink: paymentLink);
      }
      final msg = response['message'];
      if (msg is Map || msg is List) {
        final nested = _flattenMessage(msg);
        throw Exception(nested ?? 'Booking failed. Please try again.');
      }
      throw Exception(msg?.toString() ?? 'Booking failed. Please try again.');
    } on DioException catch (e) {
      final serverMessage = _extractServerMessage(e);
      throw Exception(serverMessage ?? HandleExeption.handleError(e));
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception(e.toString());
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

  @override
  Future<List<String>> getUnavailableDates(int providerId) async {
    try {
      final response = await _apiService.getUnavailableDates(providerId);
      final map = response as Map<String, dynamic>;
      if (map['status'] == true && map['data'] != null) {
        final data = map['data'] as Map<String, dynamic>;
        final dates = data['unavailable_dates'] as List<dynamic>? ?? [];
        return dates.map((e) => e.toString()).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(_extractServerMessage(e) ?? HandleExeption.handleError(e));
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  String? _flattenMessage(dynamic msg) {
    try {
      if (msg is Map) {
        final first = msg.values.first;
        if (first is List && first.isNotEmpty) return first.first.toString();
        return first?.toString();
      }
      if (msg is List && msg.isNotEmpty) return msg.first.toString();
      return null;
    } catch (_) {
      return null;
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
