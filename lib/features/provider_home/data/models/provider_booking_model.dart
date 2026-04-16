class ProviderBookingAddress {
  final int id;
  final String? addressName;
  final String? streetAddress;
  final String? city;
  final String? state;
  final String? country;
  final String? zipCode;

  ProviderBookingAddress({
    required this.id,
    this.addressName,
    this.streetAddress,
    this.city,
    this.state,
    this.country,
    this.zipCode,
  });

  factory ProviderBookingAddress.fromJson(Map<String, dynamic> json) {
    return ProviderBookingAddress(
      id: json['id'] as int? ?? 0,
      addressName: json['address_name'] as String?,
      streetAddress: json['street_address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
      zipCode: json['zip_code'] as String?,
    );
  }

  String get fullAddress {
    final parts = [streetAddress, city, state, country]
        .where((p) => p != null && p.isNotEmpty)
        .toList();
    return parts.join(', ');
  }

  String get cityLine {
    final parts = [city, state, zipCode]
        .where((p) => p != null && p.isNotEmpty)
        .toList();
    return parts.join(', ');
  }
}

class ProviderBookingCustomer {
  final int id;
  final String name;
  final String? profileImage;
  final String? mobile;
  final String? email;

  ProviderBookingCustomer({
    required this.id,
    required this.name,
    this.profileImage,
    this.mobile,
    this.email,
  });

  factory ProviderBookingCustomer.fromJson(Map<String, dynamic> json) {
    return ProviderBookingCustomer(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      profileImage: json['profile_image'] as String?,
      mobile: json['mobile'] as String?,
      email: json['email'] as String?,
    );
  }

  String get displayName {
    if (name.contains('@')) return name.split('@').first;
    return name;
  }
}

class ProviderBookingService {
  final int id;
  final String serviceName;
  final String price;
  final int duration;

  ProviderBookingService({
    required this.id,
    required this.serviceName,
    required this.price,
    required this.duration,
  });

  factory ProviderBookingService.fromJson(Map<String, dynamic> json) {
    final pivot = json['pivot'] as Map<String, dynamic>? ?? {};
    return ProviderBookingService(
      id: json['id'] as int? ?? 0,
      serviceName: json['service_name'] as String? ?? '',
      price: pivot['price'] as String? ?? json['price'] as String? ?? '0.00',
      duration: pivot['duration'] as int? ?? json['duration'] as int? ?? 0,
    );
  }

  String get formattedDuration {
    if (duration <= 0) return '';
    if (duration < 60) return '${duration}min';
    final h = duration ~/ 60;
    final m = duration % 60;
    return m == 0 ? '${h}hr' : '${h}hr ${m}min';
  }
}

class ProviderBookingModel {
  final int id;
  final int providerId;
  final String appointmentDate;
  final String appointmentTime;
  final String price;
  final String tipAmount;
  final String depositAmount;
  final String balanceAmount;
  final String status;
  final String paymentStatus;
  final String? notes;
  final String? pinterestLink;
  final String? inspirationPhoto;
  final String? confirmedAt;
  final ProviderBookingCustomer customer;
  final List<ProviderBookingService> services;
  final ProviderBookingAddress? address;

  ProviderBookingModel({
    required this.id,
    required this.providerId,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.price,
    required this.tipAmount,
    required this.depositAmount,
    required this.balanceAmount,
    required this.status,
    required this.paymentStatus,
    this.notes,
    this.pinterestLink,
    this.inspirationPhoto,
    this.confirmedAt,
    required this.customer,
    required this.services,
    this.address,
  });

  factory ProviderBookingModel.fromJson(Map<String, dynamic> json) {
    final addrJson = json['address'] as Map<String, dynamic>?;
    return ProviderBookingModel(
      id: json['id'] as int? ?? 0,
      providerId: json['provider_id'] as int? ?? 0,
      appointmentDate: json['appointment_date'] as String? ?? '',
      appointmentTime: json['appointment_time'] as String? ?? '',
      price: json['price'] as String? ?? '0.00',
      tipAmount: json['tip_amount'] as String? ?? '0.00',
      depositAmount: json['deposit_amount'] as String? ?? '0.00',
      balanceAmount: json['balance_amount'] as String? ?? '0.00',
      status: json['status'] as String? ?? '',
      paymentStatus: json['payment_status'] as String? ?? '',
      notes: json['notes'] as String?,
      pinterestLink: json['pinterest_link'] as String?,
      inspirationPhoto: json['inspiration_photo'] as String?,
      confirmedAt: json['confirmed_at'] as String?,
      customer: ProviderBookingCustomer.fromJson(
          json['customer'] as Map<String, dynamic>? ?? {}),
      services: (json['services'] as List<dynamic>? ?? [])
          .map((s) => ProviderBookingService.fromJson(s as Map<String, dynamic>))
          .toList(),
      address: addrJson != null ? ProviderBookingAddress.fromJson(addrJson) : null,
    );
  }

  String get formattedDate {
    try {
      final dt = DateTime.parse(appointmentDate);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      final date = DateTime(dt.year, dt.month, dt.day);
      if (date == today) return 'Today';
      if (date == tomorrow) return 'Tomorrow';
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return appointmentDate;
    }
  }

  String get formattedTime {
    try {
      final parts = appointmentTime.split(':');
      int hour = int.parse(parts[0]);
      final min = parts[1];
      final period = hour >= 12 ? 'PM' : 'AM';
      if (hour > 12) hour -= 12;
      if (hour == 0) hour = 12;
      return '$hour:$min $period';
    } catch (_) {
      return appointmentTime;
    }
  }

  double get priceAsDouble => double.tryParse(price) ?? 0;

  String get formattedPrice {
    final p = priceAsDouble;
    return p == p.truncateToDouble() ? '\$${p.toInt()}' : '\$${p.toStringAsFixed(2)}';
  }
}
