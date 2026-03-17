import 'package:flutter/material.dart';
import 'package:pampa/features/address/data/models/address_model.dart';
import 'package:pampa/features/address/domain/repositories/address_repository.dart';

enum AddressFetchStatus { initial, loading, loaded, error }

enum AddressSaveStatus { idle, saving, saved, failed }

class AddressProvider extends ChangeNotifier {
  final AddressRepository _repository;

  AddressProvider(this._repository);

  AddressFetchStatus _fetchStatus = AddressFetchStatus.initial;
  AddressSaveStatus _saveStatus = AddressSaveStatus.idle;
  List<AddressModel> _addresses = [];
  int? _selectedAddressId;
  String _fetchError = '';
  String _saveError = '';

  AddressFetchStatus get fetchStatus => _fetchStatus;
  AddressSaveStatus get saveStatus => _saveStatus;
  List<AddressModel> get addresses => _addresses;
  bool get hasAddresses => _addresses.isNotEmpty;
  bool get isLoading => _fetchStatus == AddressFetchStatus.loading;
  bool get isSaving => _saveStatus == AddressSaveStatus.saving;
  String get fetchError => _fetchError;
  String get saveError => _saveError;

  AddressModel? get selectedAddress {
    if (_addresses.isEmpty) return null;
    if (_selectedAddressId != null) {
      final match = _addresses.where((a) => a.id == _selectedAddressId);
      if (match.isNotEmpty) return match.first;
    }
    final defaults = _addresses.where((a) => a.isDefault);
    return defaults.isNotEmpty ? defaults.first : _addresses.first;
  }

  void selectAddress(AddressModel address) {
    _selectedAddressId = address.id;
    notifyListeners();
  }

  Future<void> fetchAddresses() async {
    if (_fetchStatus == AddressFetchStatus.loading) return;

    _fetchStatus = AddressFetchStatus.loading;
    _fetchError = '';
    notifyListeners();

    try {
      _addresses = await _repository.getAddresses();
      _fetchStatus = AddressFetchStatus.loaded;
    } catch (e) {
      _fetchError = e.toString().replaceFirst('Exception: ', '');
      _fetchStatus = AddressFetchStatus.error;
    }

    notifyListeners();
  }

  Future<bool> storeAddress({
    required String addressName,
    required String streetAddress,
    required String zipCode,
    required String city,
  }) async {
    _saveStatus = AddressSaveStatus.saving;
    _saveError = '';
    notifyListeners();

    try {
      final newAddress = await _repository.storeAddress(
        addressName: addressName,
        streetAddress: streetAddress,
        zipCode: zipCode,
        city: city,
      );
      _addresses = [newAddress, ..._addresses];
      _selectedAddressId = newAddress.id;
      _saveStatus = AddressSaveStatus.saved;
      notifyListeners();
      return true;
    } catch (e) {
      _saveError = e.toString().replaceFirst('Exception: ', '');
      _saveStatus = AddressSaveStatus.failed;
      notifyListeners();
      return false;
    }
  }

  void resetSave() {
    _saveStatus = AddressSaveStatus.idle;
    _saveError = '';
    notifyListeners();
  }
}
