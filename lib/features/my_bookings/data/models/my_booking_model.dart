import 'package:pampa/features/booking/data/models/provider_model.dart';

class BookingServiceModel {
  final int id;
  final String serviceName;
  final double price;
  final int duration;

  const BookingServiceModel({
    required this.id,
    required this.serviceName,
    required this.price,
    required this.duration,
  });

  factory BookingServiceModel.fromJson(Map<String, dynamic> json) {
    return BookingServiceModel(
      id: json['id'] as int? ?? 0,
      serviceName: json['service_name'] as String? ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      duration: json['duration'] as int? ?? 0,
    );
  }
}

class MyBookingModel {
  final int id;
  final int serviceId;
  final int providerId;
  final int addressId;
  final DateTime appointmentDate;
  final String appointmentTime;
  final double price;
  final double depositAmount;
  final double balanceAmount;
  final String balancePaymentStatus;
  final String paymentStatus;
  final String status;
  final DateTime createdAt;
  final BookingServiceModel service;
  final ProviderModel provider;

  const MyBookingModel({
    required this.id,
    required this.serviceId,
    required this.providerId,
    required this.addressId,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.price,
    required this.depositAmount,
    required this.balanceAmount,
    required this.balancePaymentStatus,
    required this.paymentStatus,
    required this.status,
    required this.createdAt,
    required this.service,
    required this.provider,
  });

  bool get isUpcoming =>
      status.toLowerCase() == 'confirmed' || status.toLowerCase() == 'pending';
  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isCancelled => status.toLowerCase() == 'cancelled';

  factory MyBookingModel.fromJson(Map<String, dynamic> json) {
    return MyBookingModel(
      id: json['id'] as int,
      serviceId: json['service_id'] as int? ?? 0,
      providerId: json['provider_id'] as int? ?? 0,
      addressId: json['address_id'] as int? ?? 0,
      appointmentDate:
          DateTime.tryParse(json['appointment_date'] as String? ?? '') ??
              DateTime.now(),
      appointmentTime: json['appointment_time'] as String? ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      depositAmount:
          double.tryParse(json['deposit_amount']?.toString() ?? '0') ?? 0,
      balanceAmount:
          double.tryParse(json['balance_amount']?.toString() ?? '0') ?? 0,
      balancePaymentStatus:
          json['balance_payment_status'] as String? ?? '',
      paymentStatus: json['payment_status'] as String? ?? '',
      status: json['status'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
              DateTime.now(),
      service: BookingServiceModel.fromJson(
        json['service'] as Map<String, dynamic>? ?? {},
      ),
      provider: ProviderModel.fromJson(
        json['provider'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}
