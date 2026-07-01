import 'package:pampa/features/address/data/models/address_model.dart';

abstract class AddressRepository {
  Future<List<AddressModel>> getAddresses();

  Future<AddressModel> storeAddress({
    required String addressName,
    required String streetAddress,
    required String zipCode,
    required String city,
    required String state,
  });

  Future<AddressModel> updateAddress({
    required int id,
    required String addressName,
    required String streetAddress,
    required String zipCode,
    required String city,
    required String state,
    required bool isDefault,
  });

  Future<void> setDefaultAddress(int id);

  Future<void> deleteAddress(int id);

  Future<String> getGoogleMapsApiKey();

  Future<Map<String, dynamic>> getConfiguration();
}
