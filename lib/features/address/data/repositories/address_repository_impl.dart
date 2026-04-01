import 'package:dio/dio.dart';
import 'package:pampa/core/error/exception.dart';
import 'package:pampa/data/service/apiservice.dart';
import 'package:pampa/features/address/data/models/address_api_response.dart';
import 'package:pampa/features/address/data/models/address_model.dart';
import 'package:pampa/features/address/domain/repositories/address_repository.dart';

class AddressRepositoryImpl implements AddressRepository {
  final ApiService _apiService;

  AddressRepositoryImpl(this._apiService);

  // ── Parses the common { status, message, data } envelope ──────────────────
  AddressApiResponse _parseResponse(dynamic raw) {
    final map = raw as Map<String, dynamic>;
    return AddressApiResponse.fromJson(map);
  }

  @override
  Future<List<AddressModel>> getAddresses() async {
    try {
      final response = await _apiService.getAddresses();
      final map = response as Map<String, dynamic>;

      if (map['status'] == true) {
        final data = map['data'] as List<dynamic>? ?? [];
        return data
            .map((e) => AddressModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      throw Exception(map['message'] ?? 'Failed to load addresses.');
    } on DioException catch (e) {
      throw Exception(_extractServerMessage(e) ?? HandleExeption.handleError(e));
    } on Exception {
      rethrow;
    }
  }

  @override
  Future<AddressModel> storeAddress({
    required String addressName,
    required String streetAddress,
    required String zipCode,
    required String city,
  }) async {
    try {
      final raw = await _apiService.storeAddress({
        'address_name': addressName,
        'street_address': streetAddress,
        'zip_code': zipCode,
        'city': city,
      });

      final result = _parseResponse(raw);
      if (!result.status) throw Exception(result.message.isNotEmpty ? result.message : 'Failed to save address.');
      if (result.address != null) return result.address!;

      // Fallback: re-fetch to get the server-assigned ID
      final addresses = await getAddresses();
      if (addresses.isNotEmpty) return addresses.first;

      throw Exception('Address saved but could not retrieve ID.');
    } on DioException catch (e) {
      throw Exception(_extractServerMessage(e) ?? HandleExeption.handleError(e));
    } on Exception {
      rethrow;
    }
  }

  @override
  Future<AddressModel> updateAddress({
    required int id,
    required String addressName,
    required String streetAddress,
    required String zipCode,
    required String city,
    required bool isDefault,
  }) async {
    try {
      final raw = await _apiService.updateAddress(id, {
        'address_name': addressName,
        'street_address': streetAddress,
        'zip_code': zipCode,
        'city': city,
        'is_default': isDefault ? 1 : 0,
      });

      final result = _parseResponse(raw);
      if (!result.status) throw Exception(result.message.isNotEmpty ? result.message : 'Failed to update address.');
      // if (result.address != null) return result.address!;

      // Fallback: return updated values if API returns no body
      return AddressModel(
        id: id,
        userId: 0,
        addressName: addressName,
        streetAddress: streetAddress,
        zipCode: zipCode,
        city: city,
        country: '',
        isDefault: isDefault,
      );
    } on DioException catch (e) {
      throw Exception(_extractServerMessage(e) ?? HandleExeption.handleError(e));
    } on Exception {
      rethrow;
    }
  }

  @override
  Future<void> setDefaultAddress(int id) async {
    try {
      final raw = await _apiService.setDefaultAddress(id);
      final result = _parseResponse(raw);
      if (!result.status) throw Exception(result.message.isNotEmpty ? result.message : 'Failed to set default address.');
    } on DioException catch (e) {
      throw Exception(_extractServerMessage(e) ?? HandleExeption.handleError(e));
    } on Exception {
      rethrow;
    }
  }

  @override
  Future<void> deleteAddress(int id) async {
    try {
      final raw = await _apiService.deleteAddress(id);
      final result = _parseResponse(raw);
      if (!result.status) throw Exception(result.message.isNotEmpty ? result.message : 'Failed to delete address.');
    } on DioException catch (e) {
      throw Exception(_extractServerMessage(e) ?? HandleExeption.handleError(e));
    } on Exception {
      rethrow;
    }
  }

  String? _extractServerMessage(DioException e) {
    try {
      final data = e.response?.data;
      if (data == null) return null;
      if (data is Map<String, dynamic>) {
        if (data['message'] != null) return data['message'].toString();
        if (data['errors'] != null && data['errors'] is Map) {
          final errors = data['errors'] as Map<String, dynamic>;
          final first = errors.values.first;
          if (first is List && first.isNotEmpty) return first.first.toString();
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
