import 'package:pampa/features/address/data/models/address_model.dart';

abstract class AddressRepository {
  Future<List<AddressModel>> getAddresses();

  Future<AddressModel> storeAddress({
    required String addressName,
    required String streetAddress,
    required String zipCode,
    required String city,
  });
}
