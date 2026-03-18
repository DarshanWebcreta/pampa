import 'package:pampa/features/address/data/models/address_model.dart';

class AddressApiResponse {
  final bool status;
  final String message;


  const AddressApiResponse({
    required this.status,
    required this.message,

  });

  factory AddressApiResponse.fromJson(Map<String, dynamic> json) {




    return AddressApiResponse(
      status: json['status'] as bool? ?? false,
      message: json['message'] as String? ?? '',

    );
  }
}
