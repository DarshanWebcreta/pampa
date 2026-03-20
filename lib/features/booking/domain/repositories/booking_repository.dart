import 'package:pampa/features/booking/data/models/provider_model.dart';
import 'package:pampa/features/booking/data/models/time_slot_model.dart';
import 'package:pampa/features/services/data/models/service_model.dart';

abstract class BookingRepository {
  Future<ServiceModel> getServiceDetail(int id);

  Future<List<ProviderModel>> getProviders(String zipCode);

  Future<List<TimeSlotModel>> getAvailableSlots({
    required int providerId,
    required String date,
    required int serviceId,
  });

  Future<String> createBooking({
    required int serviceId,
    required int providerId,
    required String appointmentDate,
    required String appointmentTime,
  });

  Future<String> createCheckoutSession({
    required int serviceId,
    required num price,
    required num tipAmount,
    required int addressId,
    required int providerId,
    required String appointmentDate,
    required String appointmentTime,
  });
}
