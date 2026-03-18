class CustomerProfileModel {
  final int id;
  final String name;
  final String email;
  final String mobile;
  final String type;
  final String status;
  final DateTime? emailVerifiedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CustomerProfileModel({
    required this.id,
    required this.name,
    required this.email,
    required this.mobile,
    required this.type,
    required this.status,
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

    return CustomerProfileModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      mobile: (json['mobile'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      emailVerifiedAt: parseDate(json['email_verified_at']),
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }
}

