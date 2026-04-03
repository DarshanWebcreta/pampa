class ProviderDashboardCustomer {
  final int id;
  final String name;
  final String? profileImage;

  ProviderDashboardCustomer({
    required this.id,
    required this.name,
    this.profileImage,
  });

  factory ProviderDashboardCustomer.fromJson(Map<String, dynamic> json) {
    return ProviderDashboardCustomer(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      profileImage: json['profile_image'] as String?,
    );
  }
}

class ProviderDashboardService {
  final int id;
  final String serviceName;

  ProviderDashboardService({required this.id, required this.serviceName});

  factory ProviderDashboardService.fromJson(Map<String, dynamic> json) {
    return ProviderDashboardService(
      id: json['id'] as int? ?? 0,
      serviceName: json['service_name'] as String? ?? '',
    );
  }
}

class ProviderDashboardBooking {
  final int id;
  final String appointmentDate;
  final String appointmentTime;
  final String price;
  final String status;
  final ProviderDashboardCustomer customer;
  final List<ProviderDashboardService> services;

  ProviderDashboardBooking({
    required this.id,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.price,
    required this.status,
    required this.customer,
    required this.services,
  });

  factory ProviderDashboardBooking.fromJson(Map<String, dynamic> json) {
    return ProviderDashboardBooking(
      id: json['id'] as int? ?? 0,
      appointmentDate: json['appointment_date'] as String? ?? '',
      appointmentTime: json['appointment_time'] as String? ?? '',
      price: json['price'] as String? ?? '0.00',
      status: json['status'] as String? ?? '',
      customer: ProviderDashboardCustomer.fromJson(
          json['customer'] as Map<String, dynamic>? ?? {}),
      services: (json['services'] as List<dynamic>? ?? [])
          .map((s) => ProviderDashboardService.fromJson(
              s as Map<String, dynamic>))
          .toList(),
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
      return '${months[dt.month - 1]} ${dt.day}';
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

  String get displayName {
    final name = customer.name;
    if (name.contains('@')) return name.split('@').first;
    return name;
  }
}

class WeeklyEarnings {
  final double total;
  final String weekStart;
  final String weekEnd;

  WeeklyEarnings({
    required this.total,
    required this.weekStart,
    required this.weekEnd,
  });

  factory WeeklyEarnings.fromJson(Map<String, dynamic> json) {
    return WeeklyEarnings(
      total: (json['total'] as num? ?? 0).toDouble(),
      weekStart: json['week_start'] as String? ?? '',
      weekEnd: json['week_end'] as String? ?? '',
    );
  }
}

class RatingSnapshot {
  final double rating;
  final int totalReviews;
  final double completionRate;
  final double cancellationRate;

  RatingSnapshot({
    required this.rating,
    required this.totalReviews,
    required this.completionRate,
    required this.cancellationRate,
  });

  factory RatingSnapshot.fromJson(Map<String, dynamic> json) {
    return RatingSnapshot(
      rating: (json['rating'] as num? ?? 0).toDouble(),
      totalReviews: json['total_reviews'] as int? ?? 0,
      completionRate: (json['completion_rate'] as num? ?? 0).toDouble(),
      cancellationRate: (json['cancellation_rate'] as num? ?? 0).toDouble(),
    );
  }
}

class ServiceMixItem {
  final int serviceId;
  final String serviceName;
  final int count;

  ServiceMixItem({
    required this.serviceId,
    required this.serviceName,
    required this.count,
  });

  factory ServiceMixItem.fromJson(Map<String, dynamic> json) {
    return ServiceMixItem(
      serviceId: json['service_id'] as int? ?? 0,
      serviceName: json['service_name'] as String? ?? '',
      count: json['count'] as int? ?? 0,
    );
  }
}

class ProviderDashboardModel {
  final bool isOnline;
  final int pendingCount;
  final List<ProviderDashboardBooking> pendingRequests;
  final List<ProviderDashboardBooking> upcomingBookings;
  final WeeklyEarnings weeklyEarnings;
  final RatingSnapshot ratingSnapshot;
  final List<ServiceMixItem> serviceMix;

  ProviderDashboardModel({
    required this.isOnline,
    required this.pendingCount,
    required this.pendingRequests,
    required this.upcomingBookings,
    required this.weeklyEarnings,
    required this.ratingSnapshot,
    required this.serviceMix,
  });

  factory ProviderDashboardModel.fromJson(Map<String, dynamic> json) {
    final pendingMap =
        json['pending_requests'] as Map<String, dynamic>? ?? {};
    return ProviderDashboardModel(
      isOnline: json['is_online'] as bool? ?? false,
      pendingCount: pendingMap['count'] as int? ?? 0,
      pendingRequests: (pendingMap['data'] as List<dynamic>? ?? [])
          .map((b) => ProviderDashboardBooking.fromJson(
              b as Map<String, dynamic>))
          .toList(),
      upcomingBookings:
          (json['upcoming_bookings'] as List<dynamic>? ?? [])
              .map((b) => ProviderDashboardBooking.fromJson(
                  b as Map<String, dynamic>))
              .toList(),
      weeklyEarnings: WeeklyEarnings.fromJson(
          json['this_week_earnings'] as Map<String, dynamic>? ?? {}),
      ratingSnapshot: RatingSnapshot.fromJson(
          json['rating_snapshot'] as Map<String, dynamic>? ?? {}),
      serviceMix: (json['service_mix'] as List<dynamic>? ?? [])
          .map((s) =>
              ServiceMixItem.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}
