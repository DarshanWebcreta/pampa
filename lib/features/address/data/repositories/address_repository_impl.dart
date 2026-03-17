import 'package:dio/dio.dart';
import 'package:pampa/core/error/exception.dart';
import 'package:pampa/data/service/apiservice.dart';
import 'package:pampa/features/address/data/models/address_model.dart';
import 'package:pampa/features/address/domain/repositories/address_repository.dart';

class AddressRepositoryImpl implements AddressRepository {
  final ApiService _apiService;

  AddressRepositoryImpl(this._apiService);

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
      final msg = _extractServerMessage(e);
      throw Exception(msg ?? HandleExeption.handleError(e));
    } on Exception {
      rethrow;
    } catch (_) {
      throw Exception('Something went wrong. Please try again.');
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
      final response = await _apiService.storeAddress({
        'address_name': addressName,
        'street_address': streetAddress,
        'zip_code': zipCode,
        'city': city,
      });

      final map = response as Map<String, dynamic>;

      if (map['status'] == true) {
        final data = map['data'];
        if (data is Map<String, dynamic>) {
          return AddressModel.fromJson(data);
        }
        // Some APIs return the address directly in data list or top-level
        if (data is List && data.isNotEmpty) {
          return AddressModel.fromJson(data.first as Map<String, dynamic>);
        }
        // Fallback: construct a minimal model from the request body
        return AddressModel(
          id: 0,
          userId: 0,
          addressName: addressName,
          streetAddress: streetAddress,
          zipCode: zipCode,
          city: city,
          country: '',
          isDefault: false,
        );
      }

      throw Exception(map['message'] ?? 'Failed to save address.');
    } on DioException catch (e) {
      final msg = _extractServerMessage(e);
      throw Exception(msg ?? HandleExeption.handleError(e));
    } on Exception {
      rethrow;
    } catch (_) {
      throw Exception('Something went wrong. Please try again.');
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
