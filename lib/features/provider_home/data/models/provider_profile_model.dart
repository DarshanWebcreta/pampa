class ProviderProfileService {
  final int id;
  final String name;
  final String? imageUrl;
  final String? price;
  final int duration;
  final String? categoryName;

  ProviderProfileService({
    required this.id,
    required this.name,
    this.imageUrl,
    this.price,
    this.duration = 0,
    this.categoryName,
  });

  factory ProviderProfileService.fromMap(Map<String, dynamic> m) =>
      ProviderProfileService(
        id: m['id'] as int? ?? 0,
        name: m['service_name'] as String? ?? m['name'] as String? ?? '',
        imageUrl: m['image_url'] as String?,
        price: m['price'] as String?,
        duration: m['duration'] as int? ?? 0,
        categoryName: (m['category'] as Map<String, dynamic>?)?['category_name']
            as String?,
      );
}

class ProviderGalleryImage {
  final int id;
  final String url;

  ProviderGalleryImage({required this.id, required this.url});

  factory ProviderGalleryImage.fromMap(Map<String, dynamic> m) =>
      ProviderGalleryImage(
        id: m['id'] as int? ?? 0,
        url: m['image_url'] as String? ?? m['url'] as String? ?? '',
      );
}

class ProviderReview {
  final String customerName;
  final String serviceName;
  final double rating;
  final String comment;
  final String date;

  ProviderReview({
    required this.customerName,
    required this.serviceName,
    required this.rating,
    required this.comment,
    required this.date,
  });

  factory ProviderReview.fromMap(Map<String, dynamic> m) => ProviderReview(
        customerName: m['customer_name'] as String? ?? '',
        serviceName: m['service_name'] as String? ?? '',
        rating: (m['rating'] as num?)?.toDouble() ?? 5.0,
        comment: m['comment'] as String? ?? '',
        date: m['date'] as String? ?? '',
      );
}

class ProviderAvailability {
  final String day;
  final bool isOpen;
  final String? startTime;
  final String? endTime;

  ProviderAvailability({
    required this.day,
    required this.isOpen,
    this.startTime,
    this.endTime,
  });

  factory ProviderAvailability.fromMap(Map<String, dynamic> m) =>
      ProviderAvailability(
        day: m['day'] as String? ?? '',
        isOpen: m['is_open'] as bool? ?? false,
        startTime: m['start_time'] as String?,
        endTime: m['end_time'] as String?,
      );
}

class ProviderProfileModel {
  final int id;
  final int userId;
  final String? name;
  final String? bio;
  final String? photoUrl;
  final double rating;
  final bool isOnline;
  final String? status;
  final String? city;
  final String? state;
  final String? country;
  final String? streetAddress;
  final String? zipCode;
  final String? startTime;
  final String? endTime;
  final String? licensed;
  final String? certification;
  final String? email;
  final int maxServiceDistance;
  final String? perKmCharge;
  final String? payoutSchedule;
  final List<String> zipCodes;
  final List<ProviderGalleryImage> gallery;
  final List<ProviderAvailability> availabilities;

  // Optional — returned by future API endpoints
  final int totalReviews;
  final double completionRate;
  final double cancellationRate;
  final List<ProviderProfileService> services;
  final List<ProviderReview> recentReviews;

  ProviderProfileModel({
    required this.id,
    required this.userId,
    this.name,
    this.bio,
    this.photoUrl,
    required this.rating,
    required this.isOnline,
    this.status,
    this.city,
    this.state,
    this.country,
    this.streetAddress,
    this.zipCode,
    this.startTime,
    this.endTime,
    this.licensed,
    this.certification,
    this.email,
    this.maxServiceDistance = 0,
    this.perKmCharge,
    this.payoutSchedule,
    this.zipCodes = const [],
    required this.gallery,
    this.availabilities = const [],
    this.totalReviews = 0,
    this.completionRate = 0,
    this.cancellationRate = 0,
    this.services = const [],
    this.recentReviews = const [],
  });

  factory ProviderProfileModel.fromMap(Map<String, dynamic> m) =>
      ProviderProfileModel(
        id: m['id'] as int? ?? 0,
        userId: m['user_id'] as int? ?? 0,
        name: m['name'] as String? ?? _userDisplayName(m),
        bio: m['bio'] as String?,
        photoUrl: m['photo_url'] as String? ??
            (m['user'] as Map<String, dynamic>?)?['profile_image'] as String?,
        rating: (m['rating'] as num?)?.toDouble() ?? 0,
        isOnline: m['is_online'] as bool? ?? false,
        status: m['status'] as String?,
        city: m['city'] as String?,
        state: m['state'] as String?,
        country: m['country'] as String?,
        streetAddress: m['street_address'] as String?,
        zipCode: m['zip_code'] as String?,
        startTime: m['start_time'] as String?,
        endTime: m['end_time'] as String?,
        licensed: m['licensed'] as String?,
        certification: m['certification'] as String?,
        email: (m['user'] as Map<String, dynamic>?)?['email'] as String?,
        maxServiceDistance: m['max_service_distance'] as int? ?? 0,
        perKmCharge: m['per_km_charge'] as String?,
        payoutSchedule: m['payout_schedule'] as String?,
        zipCodes: (m['zip_codes'] as List<dynamic>?)
                ?.map((e) =>
                    (e as Map<String, dynamic>)['zip_code'] as String? ?? '')
                .where((e) => e.isNotEmpty)
                .toList() ??
            [],
        gallery: (m['images'] as List<dynamic>?)
                ?.map((e) => ProviderGalleryImage.fromMap(
                    e as Map<String, dynamic>))
                .toList() ??
            [],
        availabilities: (m['availabilities'] as List<dynamic>?)
                ?.map((e) => ProviderAvailability.fromMap(
                    e as Map<String, dynamic>))
                .toList() ??
            [],
        totalReviews: m['total_reviews'] as int? ?? 0,
        completionRate: (m['completion_rate'] as num?)?.toDouble() ?? 0,
        cancellationRate: (m['cancellation_rate'] as num?)?.toDouble() ?? 0,
        services: (m['services'] as List<dynamic>?)
                ?.map((e) => ProviderProfileService.fromMap(
                    e as Map<String, dynamic>))
                .toList() ??
            [],
        recentReviews: (m['recent_reviews'] as List<dynamic>?)
                ?.map((e) =>
                    ProviderReview.fromMap(e as Map<String, dynamic>))
                .toList() ??
            [],
      );

  ProviderProfileModel copyWith({
    String? name,
    String? bio,
    String? photoUrl,
    List<ProviderGalleryImage>? gallery,
    List<ProviderAvailability>? availabilities,
  }) =>
      ProviderProfileModel(
        id: id,
        userId: userId,
        name: name ?? this.name,
        bio: bio ?? this.bio,
        photoUrl: photoUrl ?? this.photoUrl,
        rating: rating,
        isOnline: isOnline,
        status: status,
        city: city,
        state: state,
        country: country,
        streetAddress: streetAddress,
        zipCode: zipCode,
        startTime: startTime,
        endTime: endTime,
        licensed: licensed,
        certification: certification,
        email: email,
        maxServiceDistance: maxServiceDistance,
        perKmCharge: perKmCharge,
        payoutSchedule: payoutSchedule,
        zipCodes: zipCodes,
        gallery: gallery ?? this.gallery,
        availabilities: availabilities ?? this.availabilities,
        totalReviews: totalReviews,
        completionRate: completionRate,
        cancellationRate: cancellationRate,
        services: services,
        recentReviews: recentReviews,
      );
}

String? _userDisplayName(Map<String, dynamic> map) {
  final user = map['user'] as Map<String, dynamic>?;
  final directName = user?['name'] as String?;
  if (directName != null && directName.trim().isNotEmpty) {
    return directName;
  }

  final parts = [
    user?['first_name'] as String?,
    user?['last_name'] as String?,
  ].whereType<String>().map((part) => part.trim()).where((part) => part.isNotEmpty);

  final fullName = parts.join(' ');
  return fullName.isEmpty ? null : fullName;
}
