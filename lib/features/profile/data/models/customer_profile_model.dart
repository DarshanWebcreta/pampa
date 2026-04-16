import 'package:pampa/core/values/urls.dart';
class CustomerProfileModel{
  final int id;
  final String name;
  final String firstName;
  final String lastName;
  final String email;
  final String mobile;
  final String type;
  final String status;
  final String? photoUrl;
  final String? streetAddress;
  final String? zipCode;
  final String? city;
  final String? state;
  final String? country;
  final DateTime? emailVerifiedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CustomerProfileModel({
    required this.id,
    required this.name,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.mobile,
    required this.type,
    required this.status,
    this.photoUrl,
    this.streetAddress,
    this.zipCode,
    this.city,
    this.state,
    this.country,
    this.emailVerifiedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory CustomerProfileModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
      return null;
    }

    final firstName = (json['first_name'] ?? '').toString();
    final lastName = (json['last_name'] ?? '').toString();
    final fullName = (json['name'] ?? '').toString();

    return CustomerProfileModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: fullName.isNotEmpty
          ? fullName
          : [firstName, lastName].where((s) => s.isNotEmpty).join(' '),
      firstName: firstName,
      lastName: lastName,
      email: (json['email'] ?? '').toString(),
      mobile: (json['mobile'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      photoUrl: () {
        final raw = (json['profile_image'] ??      // ← actual API key
                json['profile_image_url'] ??
                json['photo_url'] ??
                json['profile_photo'] ??
                json['photo'] ??
                '')
            .toString()
            .trim();
        if (raw.isEmpty) return null;
        // Relative path → prepend host (e.g. /storage/uploads/users/xxx.jpg)
        if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
        if (raw.startsWith('/')) return '${ApiStrings.imageUrl}$raw';
        return '${ApiStrings.imageUrl}/$raw';
      }(),
      streetAddress: (json['street_address'] ?? '').toString().isEmpty
          ? null
          : json['street_address'].toString(),
      zipCode: (json['zip_code'] ?? '').toString().isEmpty
          ? null
          : json['zip_code'].toString(),
      city: (json['city'] ?? '').toString().isEmpty ? null : json['city'].toString(),
      state: (json['state'] ?? '').toString().isEmpty ? null : json['state'].toString(),
      country: (json['country'] ?? '').toString().isEmpty ? null : json['country'].toString(),
      emailVerifiedAt: parseDate(json['email_verified_at']),
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }

  CustomerProfileModel copyWith({
    String? name,
    String? firstName,
    String? lastName,
    String? email,
    String? mobile,
    String? photoUrl,
    String? streetAddress,
    String? zipCode,
    String? city,
    String? state,
    String? country,
  }) {
    return CustomerProfileModel(
      id: id,
      name: name ?? this.name,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      mobile: mobile ?? this.mobile,
      type: type,
      status: status,
      photoUrl: photoUrl ?? this.photoUrl,
      streetAddress: streetAddress ?? this.streetAddress,
      zipCode: zipCode ?? this.zipCode,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      emailVerifiedAt: emailVerifiedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
