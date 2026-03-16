class UserModel {
  final int id;
  final String name;
  final String email;
  final String type;
  final String mobile;
  final String? streetAddress;
  final String? zipCode;
  final String? city;
  final String? state;
  final String? country;
  final String status;
  final int isAdmin;
  final String? emailVerifiedAt;
  final String createdAt;
  final String updatedAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.type,
    required this.mobile,
    this.streetAddress,
    this.zipCode,
    this.city,
    this.state,
    this.country,
    required this.status,
    required this.isAdmin,
    this.emailVerifiedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      type: json['type'] ?? 'customer',
      mobile: json['mobile'] ?? '',
      streetAddress: json['street_address'],
      zipCode: json['zip_code'],
      city: json['city'],
      state: json['state'],
      country: json['country'],
      status: json['status'] ?? 'Active',
      isAdmin: json['is_admin'] ?? 0,
      emailVerifiedAt: json['email_verified_at'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'type': type,
      'mobile': mobile,
      'street_address': streetAddress,
      'zip_code': zipCode,
      'city': city,
      'state': state,
      'country': country,
      'status': status,
      'is_admin': isAdmin,
      'email_verified_at': emailVerifiedAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class AuthResponseModel {
  final String accessToken;
  final String tokenType;
  final UserModel user;

  AuthResponseModel({
    required this.accessToken,
    required this.tokenType,
    required this.user,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      accessToken: json['access_token'] ?? '',
      tokenType: json['token_type'] ?? 'Bearer',
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
