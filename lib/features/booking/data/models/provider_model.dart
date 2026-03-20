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
  final String? city;
  final String? state;
  final String status;
  final ProviderUserModel user;

  const ProviderModel({
    required this.id,
    required this.userId,
    this.photoUrl,
    this.bio,
    required this.rating,
    this.city,
    this.state,
    required this.status,
    required this.user,
  });

  String get displayName => user.name;

  String get displayLocation {
    final parts = [city, state].where((p) => p != null && p.isNotEmpty);
    return parts.isNotEmpty ? parts.join(', ') : 'Location not set';
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
      city: json['city'] as String?,
      state: json['state'] as String?,
      status: json['status'] as String? ?? '',
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
