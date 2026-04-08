import 'package:pampa/features/my_bookings/data/models/my_booking_model.dart';

abstract class MyBookingsRepository {
  Future<List<MyBookingModel>> getBookings();
  Future<MyBookingModel> getBookingDetail(int id);
  Future<String> cancelBooking(int id);
  Future<String> payBalance(int bookingId);
  Future<String> retryPayment(int paymentId);
}
