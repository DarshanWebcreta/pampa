import 'package:pampa/core/values/urls.dart';

class ExploreCategoryModel {
  final int id;
  final String categoryName;
  final String? icon;

  const ExploreCategoryModel({
    required this.id,
    required this.categoryName,
    this.icon,
  });

  factory ExploreCategoryModel.fromJson(Map<String, dynamic> json) {
    final rawIcon = json['icon']?.toString();
    return ExploreCategoryModel(
      id: json['id'] as int? ?? 0,
      categoryName: json['category_name'] as String? ?? '',
      icon: _resolveUrl(rawIcon),
    );
  }
}

class ExploreProviderModel {
  final int id;
  final String? photoUrl;
  final double rating;
  final String? bio;
  final String? city;
  final String? state;
  final String name;
  final double? distanceMiles;
  final double? travelFee;

  const ExploreProviderModel({
    required this.id,
    this.photoUrl,
    required this.rating,
    this.bio,
    this.city,
    this.state,
    required this.name,
    this.distanceMiles,
    this.travelFee,
  });

  String get displayLocation {
    final parts = [city, state].where((p) => p != null && p!.isNotEmpty);
    return parts.isNotEmpty ? parts.join(', ') : '';
  }

  factory ExploreProviderModel.fromJson(Map<String, dynamic> json) {
    final ratingRaw = json['rating'];
    final rating = ratingRaw is int
        ? ratingRaw.toDouble()
        : (ratingRaw is double ? ratingRaw : 0.0);
    final user = json['user'] as Map<String, dynamic>? ?? {};

    final distanceRaw = json['distance_miles'] ?? json['distance_km'];
    final distanceMiles = distanceRaw is num
        ? distanceRaw.toDouble()
        : double.tryParse(distanceRaw?.toString() ?? '');

    final travelRaw = json['travel_fee'] ?? json['travel_charge'];
    final travelFee = travelRaw is num
        ? travelRaw.toDouble()
        : double.tryParse(travelRaw?.toString() ?? '');

    return ExploreProviderModel(
      id: json['id'] as int? ?? 0,
      photoUrl: json['photo_url'] as String? ?? _resolveUrl(json['photo']?.toString()),
      rating: rating,
      bio: json['bio'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      name: user['name'] as String? ?? json['name'] as String? ?? '',
      distanceMiles: distanceMiles,
      travelFee: travelFee,
    );
  }
}

class ExploreServiceModel {
  final int id;
  final String serviceName;
  final String? imageUrl;
  final double price;
  final int duration;
  final String? categoryName;

  const ExploreServiceModel({
    required this.id,
    required this.serviceName,
    this.imageUrl,
    required this.price,
    required this.duration,
    this.categoryName,
  });

  factory ExploreServiceModel.fromJson(Map<String, dynamic> json) {
    final category = json['category'] as Map<String, dynamic>?;
    return ExploreServiceModel(
      id: json['id'] as int? ?? 0,
      serviceName: json['service_name'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? _resolveUrl(json['image']?.toString()),
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      duration: json['duration'] as int? ?? 0,
      categoryName: category?['category_name'] as String?,
    );
  }
}

class ExploreResultModel {
  final List<ExploreCategoryModel> categories;
  final List<ExploreProviderModel> providers;
  final List<ExploreServiceModel> services;

  const ExploreResultModel({
    required this.categories,
    required this.providers,
    required this.services,
  });

  bool get isEmpty =>
      categories.isEmpty && providers.isEmpty && services.isEmpty;

  factory ExploreResultModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return ExploreResultModel(
      categories: (data['categories'] as List<dynamic>? ?? [])
          .map((e) => ExploreCategoryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      providers: (data['providers'] as List<dynamic>? ?? [])
          .map((e) => ExploreProviderModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      services: (data['services'] as List<dynamic>? ?? [])
          .map((e) => ExploreServiceModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

String? _resolveUrl(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final t = raw.trim();
  if (t.startsWith('http://') || t.startsWith('https://')) return t;
  if (t.startsWith('/')) return '${ApiStrings.imageUrl}$t';
  return '${ApiStrings.imageUrl}/$t';
}
