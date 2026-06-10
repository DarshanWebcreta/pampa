import 'package:dio/dio.dart';
import 'package:pampa/core/error/exception.dart';
import 'package:pampa/data/service/apiservice.dart';
import 'package:pampa/features/my_bookings/data/models/my_booking_model.dart';
import 'package:pampa/features/my_bookings/domain/repositories/my_bookings_repository.dart';

class MyBookingsRepositoryImpl implements MyBookingsRepository {
  final ApiService _apiService;

  MyBookingsRepositoryImpl(this._apiService);

  @override
  Future<List<MyBookingModel>> getBookings() async {
    try {
      final response = await _apiService.getBookings();
      final map = response as Map<String, dynamic>;
      if (map['status'] == true) {
        final data = map['data'] as List<dynamic>? ?? [];
        return data
            .map((e) => MyBookingModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw Exception(map['message'] ?? 'Failed to load bookings.');
    } on DioException catch (e) {
      throw Exception(HandleExeption.handleError(e));
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Something went wrong. Please try again.');
    }
  }

  @override
  Future<MyBookingModel> getBookingDetail(int id) async {
    try {
      final response = await _apiService.bookingDetails(id);
      final map = response as Map<String, dynamic>;
      if (map['status'] == true) {
        return MyBookingModel.fromJson(map['data'] as Map<String, dynamic>);
      }
      throw Exception(map['message'] ?? 'Failed to load booking details.');
    } on DioException catch (e) {
      throw Exception(HandleExeption.handleError(e));
    } on Exception {
      rethrow;
    } catch (_) {
      throw Exception('Something went wrong. Please try again.');
    }
  }

  @override
  Future<String> cancelBooking(int id) async {
    try {
      final response = await _apiService.cancelBooking(id);
      final map = response as Map<String, dynamic>;
      if (map['status'] == true) {
        return map['message'] as String? ?? 'Booking cancelled successfully.';
      }
      throw Exception(map['message'] ?? 'Failed to cancel booking.');
    } on DioException catch (e) {
      throw Exception(HandleExeption.handleError(e));
    } on Exception {
      rethrow;
    } catch (_) {
      throw Exception('Something went wrong. Please try again.');
    }
  }

  @override
  Future<String> payBalance(int bookingId) async {
    try {
      final response = await _apiService.payBalance(bookingId);
      final map = response as Map<String, dynamic>;
      if (map['status'] == true) {
        final data = map['data'];
        if (data is Map<String, dynamic>) {
          final url = data['url']?.toString();
          if (url != null && url.isNotEmpty) return url;
        }
        throw Exception('Invalid payment session response.');
      }
      throw Exception(map['message'] ?? 'Failed to create payment session.');
    } on DioException catch (e) {
      throw Exception(HandleExeption.handleError(e));
    } on Exception {
      rethrow;
    } catch (_) {
      throw Exception('Something went wrong. Please try again.');
    }
  }

  @override
  Future<String> retryPayment(int paymentId) async {
    try {
      final response = await _apiService.retryPayment(paymentId);
      final map = response as Map<String, dynamic>;
      if (map['status'] == true) {
        final data = map['data'];
        if (data is Map<String, dynamic>) {
          final url = data['url']?.toString();
          if (url != null && url.isNotEmpty) return url;
        }
        throw Exception('Invalid payment session response.');
      }
      throw Exception(map['message'] ?? 'Failed to create payment session.');
    } on DioException catch (e) {
      throw Exception(HandleExeption.handleError(e));
    } on Exception {
      rethrow;
    } catch (_) {
      throw Exception('Something went wrong. Please try again.');
    }
  }

  @override
  Future<bool> rescheduleBooking(int id, String date, String time) async {
    try {
      final body = {
        'appointment_date': date,
        'appointment_time': time,
      };
      final response = await _apiService.rescheduleBooking(id, body);
      final map = response as Map<String, dynamic>;
      if (map['status'] == true) {
        return true;
      }
      throw Exception(map['message'] ?? 'Failed to reschedule booking.');
    } on DioException catch (e) {
      if (e.response?.data != null) {
        final resData = e.response!.data;
        if (resData is Map && resData['message'] != null) {
          throw Exception(resData['message'].toString());
        }
      }
      throw Exception(HandleExeption.handleError(e));
    } on Exception {
      rethrow;
    } catch (_) {
      throw Exception('Something went wrong. Please try again.');
    }
  }
}
