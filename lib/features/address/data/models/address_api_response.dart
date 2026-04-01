import 'package:pampa/features/address/data/models/address_model.dart';

class AddressApiResponse {
  final bool status;
  final String message;
  final AddressModel? address;

  const AddressApiResponse({
    required this.status,
    required this.message,
    this.address,
  });

  factory AddressApiResponse.fromJson(Map<String, dynamic> json) {
    AddressModel? address;
    final data = json['data'];
    if (data is Map<String, dynamic>) {
      try {
        address = AddressModel.fromJson(data);
      } catch (_) {}
    }

    return AddressApiResponse(
      status: json['status'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      address: address,
    );
  }
}
