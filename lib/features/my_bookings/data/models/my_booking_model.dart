import 'package:pampa/features/booking/data/models/provider_model.dart';

class BookingServiceModel {
  final int id;
  final String serviceName;
  final String image;
  final double price;
  final int duration;

  const BookingServiceModel({
    required this.id,
    required this.serviceName,
    required this.image,
    required this.price,
    required this.duration,
  });

  factory BookingServiceModel.fromJson(Map<String, dynamic> json) {
    return BookingServiceModel(
      id: json['id'] as int? ?? 0,
      image: json['image'] as String? ?? '',
      serviceName: json['service_name'] as String? ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      duration: json['duration'] as int? ?? 0,
    );
  }

  static BookingServiceModel empty() => const BookingServiceModel(
        id: 0,
        serviceName: '',
        image: '',
        price: 0,
        duration: 0,
      );
}

class MyBookingModel {
  final int id;
  final int? serviceId;
  final int? providerId;
  final int? addressId;
  final int? paymentId;
  final DateTime appointmentDate;
  final String appointmentTime;
  final double price;
  final double depositAmount;
  final double balanceAmount;
  final String? tipAmount;
  final String balancePaymentStatus;
  final String paymentStatus;
  final String status;
  final DateTime? createdAt;
  final String? notes;
  final String? pinterestLink;
  final String? inspirationPhoto;
  final BookingServiceModel service;
  final ProviderModel? provider;
  final bool rescheduleBook;
  final String? distanceKm;
  final String? distanceCharge;

  const MyBookingModel({
    required this.id,
    this.serviceId,
    this.providerId,
    this.addressId,
    this.paymentId,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.price,
    required this.depositAmount,
    required this.balanceAmount,
    this.tipAmount,
    required this.balancePaymentStatus,
    required this.paymentStatus,
    required this.status,
    this.createdAt,
    this.notes,
    this.pinterestLink,
    this.inspirationPhoto,
    required this.service,
    this.provider,
    this.rescheduleBook = false,
    this.distanceKm,
    this.distanceCharge,
  });

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isConfirmed => status.toLowerCase() == 'confirmed';
  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isCancelled => status.toLowerCase() == 'cancelled';

  factory MyBookingModel.fromJson(Map<String, dynamic> json) {
    return MyBookingModel(
      id: json['id'] as int? ?? 0,
      serviceId: json['service_id'] as int?,
      providerId: json['provider_id'] as int?,
      addressId: json['address_id'] as int?,
      paymentId: json['payment_id'] as int?,
      tipAmount: json['tip_amount']?.toString(),
      appointmentDate: json['appointment_date'] != null
          ? DateTime.tryParse(json['appointment_date']) ?? DateTime.now()
          : DateTime.now(),
      appointmentTime: json['appointment_time'] as String? ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      depositAmount:
          double.tryParse(json['deposit_amount']?.toString() ?? '0') ?? 0,
      balanceAmount:
          double.tryParse(json['balance_amount']?.toString() ?? '0') ?? 0,
      balancePaymentStatus:
          json['balance_payment_status'] as String? ?? '',
      paymentStatus: json['payment_status'] as String? ?? '',
      status: (json['status'] as String?)?.toLowerCase() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      notes: json['notes'] as String?,
      pinterestLink: json['pinterest_link'] as String?,
      inspirationPhoto: json['inspiration_photo'] as String?,
      service: json['service'] != null
          ? BookingServiceModel.fromJson(json['service'])
          : BookingServiceModel.empty(),
      provider: json['provider'] != null
          ? ProviderModel.fromJson(json['provider'])
          : null,
      rescheduleBook: json['reschedule_book'] as bool? ?? false,
      distanceKm: json['distance_km']?.toString(),
      distanceCharge: json['distance_charge']?.toString(),
    );
  }
}
