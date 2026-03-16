class AddressModel {
  final int id;
  final int userId;
  final String addressName;
  final String streetAddress;
  final String zipCode;
  final String city;
  final String? state;
  final String country;
  final bool isDefault;

  const AddressModel({
    required this.id,
    required this.userId,
    required this.addressName,
    required this.streetAddress,
    required this.zipCode,
    required this.city,
    this.state,
    required this.country,
    required this.isDefault,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'] as int,
      userId: json['user_id'] as int? ?? 0,
      addressName: json['address_name'] as String? ?? '',
      streetAddress: json['street_address'] as String? ?? '',
      zipCode: json['zip_code'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String?,
      country: json['country'] as String? ?? '',
      isDefault: (json['is_default'] as int? ?? 0) == 1,
    );
  }

  String get displayAddress {
    final parts = [addressName, streetAddress, city].where((p) => p.isNotEmpty);
    return parts.join(', ');
  }
}
