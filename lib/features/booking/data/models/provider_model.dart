import 'package:pampa/core/values/urls.dart';

class ProviderUserModel {
  final int id;
  final String name;
  final String email;
  final String mobile;

  const ProviderUserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.mobile,
  });

  factory ProviderUserModel.fromJson(Map<String, dynamic> json) {
    return ProviderUserModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      mobile: json['mobile'] as String? ?? '',
    );
  }
}

class ProviderModel {
  final int id;
  final int userId;
  final String? photoUrl;
  final String? bio;
  final double rating;
  final String? streetAddress;
  final String? zipCode;
  final String? city;
  final String? state;
  final String status;
  final List<ProviderGalleryImageModel> images;
  final List<ProviderServiceSummaryModel> services;
  final ProviderUserModel user;

  const ProviderModel({
    required this.id,
    required this.userId,
    this.photoUrl,
    this.bio,
    required this.rating,
    this.streetAddress,
    this.zipCode,
    this.city,
    this.state,
    required this.status,
    required this.images,
    required this.services,
    required this.user,
  });

  String get displayName => user.name;

  String get displayLocation {
    final parts = [streetAddress, city, state, zipCode]
        .where((p) => p != null && p.isNotEmpty);
    return parts.isNotEmpty ? parts.join(', ') : 'Location not set';
  }

  ProviderServiceSummaryModel? serviceFor(int serviceId) {
    for (final service in services) {
      if (service.id == serviceId) return service;
    }
    return null;
  }

  bool get isActive => status.toLowerCase() == 'active';

  factory ProviderModel.fromJson(Map<String, dynamic> json) {
    final ratingRaw = json['rating'];
    final rawPhoto = json['photo']?.toString();
    final ratingValue = ratingRaw is int
        ? ratingRaw.toDouble()
        : (ratingRaw is double ? ratingRaw : 0.0);

    return ProviderModel(
      id: json['id'] as int,
      userId: json['user_id'] as int? ?? 0,
      photoUrl: _resolvePhotoUrl(rawPhoto),
      bio: json['bio'] as String?,
      rating: ratingValue,
      streetAddress: json['street_address'] as String?,
      zipCode: json['zip_code'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      status: json['status'] as String? ?? '',
      images: (json['images'] as List<dynamic>? ?? [])
          .map((e) =>
              ProviderGalleryImageModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      services: (json['services'] as List<dynamic>? ?? [])
          .map((e) =>
              ProviderServiceSummaryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      user: ProviderUserModel.fromJson(
          json['user'] as Map<String, dynamic>? ?? {}),
    );
  }

  static String? _resolvePhotoUrl(String? photo) {
    if (photo == null) return null;

    final trimmed = photo.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    if (trimmed.startsWith('/')) {
      return '${ApiStrings.imageUrl}$trimmed';
    }

    return '${ApiStrings.imageUrl}/$trimmed';
  }
}

class ProviderGalleryImageModel {
  final int id;
  final String? imageUrl;

  const ProviderGalleryImageModel({
    required this.id,
    required this.imageUrl,
  });

  factory ProviderGalleryImageModel.fromJson(Map<String, dynamic> json) {
    return ProviderGalleryImageModel(
      id: json['id'] as int? ?? 0,
      imageUrl: json['image_url'] as String? ?? _resolveProviderAsset(json['image']),
    );
  }
}

class ProviderServiceSummaryModel {
  final int id;
  final String serviceName;
  final String price;
  final int duration;
  final double deposit;
  final String? imageUrl;

  const ProviderServiceSummaryModel({
    required this.id,
    required this.serviceName,
    required this.price,
    required this.duration,
    required this.deposit,
    required this.imageUrl,
  });

  double get priceAsDouble => double.tryParse(price) ?? 0.0;

  String get formattedDuration => '$duration min';

  factory ProviderServiceSummaryModel.fromJson(Map<String, dynamic> json) {
    return ProviderServiceSummaryModel(
      id: json['id'] as int? ?? 0,
      serviceName: json['service_name'] as String? ?? '',
      price: json['price']?.toString() ?? '0.00',
      duration: json['duration'] as int? ?? 0,
      deposit: _toDouble(json['deposit']),
      imageUrl:
          json['image_url'] as String? ?? _resolveProviderAsset(json['image']),
    );
  }
}

String? _resolveProviderAsset(dynamic rawPath) {
  final path = rawPath?.toString();
  if (path == null) return null;
  final trimmed = path.trim();
  if (trimmed.isEmpty) return null;
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  if (trimmed.startsWith('/')) {
    return '${ApiStrings.imageUrl}$trimmed';
  }
  return '${ApiStrings.imageUrl}/$trimmed';
}

double _toDouble(dynamic val) {
  if (val == null) return 0.0;
  if (val is num) return val.toDouble();
  return double.tryParse(val.toString()) ?? 0.0;
}
