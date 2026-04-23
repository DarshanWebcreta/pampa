import 'package:flutter/material.dart';
import 'package:pampa/features/address/data/models/address_model.dart';
import 'package:pampa/features/address/domain/repositories/address_repository.dart';

enum AddressFetchStatus { initial, loading, loaded, error }

enum AddressSaveStatus { idle, saving, saved, failed }

enum AddressDeleteStatus { idle, deleting, deleted, failed }

class AddressProvider extends ChangeNotifier {
  final AddressRepository _repository;

  AddressProvider(this._repository);

  AddressFetchStatus _fetchStatus = AddressFetchStatus.initial;
  AddressSaveStatus _saveStatus = AddressSaveStatus.idle;
  AddressDeleteStatus _deleteStatus = AddressDeleteStatus.idle;
  List<AddressModel> _addresses = [];
  int? _selectedAddressId;
  String _fetchError = '';
  String _saveError = '';
  String _deleteError = '';

  AddressFetchStatus get fetchStatus => _fetchStatus;
  AddressSaveStatus get saveStatus => _saveStatus;
  AddressDeleteStatus get deleteStatus => _deleteStatus;
  List<AddressModel> get addresses => _addresses;
  bool get hasAddresses => _addresses.isNotEmpty;
  bool get isLoading => _fetchStatus == AddressFetchStatus.loading;
  bool get isSaving => _saveStatus == AddressSaveStatus.saving;
  bool get isDeleting => _deleteStatus == AddressDeleteStatus.deleting;
  String get fetchError => _fetchError;
  String get saveError => _saveError;
  String get deleteError => _deleteError;

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
      // Instead of manual patching, we fetch to ensure server consistency (sorting, IDs, etc.)
      await fetchAddresses();
      _selectedAddressId = _addresses.firstOrNull?.id;
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

  Future<bool> updateAddress({
    required int id,
    required String addressName,
    required String streetAddress,
    required String zipCode,
    required String city,
    required bool isDefault,
  }) async {
    _saveStatus = AddressSaveStatus.saving;
    _saveError = '';
    notifyListeners();

    try {
      final updated = await _repository.updateAddress(
        id: id,
        addressName: addressName,
        streetAddress: streetAddress,
        zipCode: zipCode,
        city: city,
        isDefault: isDefault,
      );
      // Refreshing from server is safer to ensure all fields are correct
      await fetchAddresses();
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

  Future<bool> setDefaultAddress(int id) async {
    try {
      await _repository.setDefaultAddress(id);
      _addresses = _addresses.map((a) {
        return AddressModel(
          id: a.id,
          userId: a.userId,
          addressName: a.addressName,
          streetAddress: a.streetAddress,
          zipCode: a.zipCode,
          city: a.city,
          state: a.state,
          country: a.country,
          isDefault: a.id == id,
        );
      }).toList();
      _selectedAddressId = id;
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteAddress(int id) async {
    _deleteStatus = AddressDeleteStatus.deleting;
    _deleteError = '';
    notifyListeners();

    try {
      await _repository.deleteAddress(id);
      await fetchAddresses();
      if (_selectedAddressId == id) _selectedAddressId = null;
      _deleteStatus = AddressDeleteStatus.deleted;
      notifyListeners();
      return true;
    } catch (e) {
      _deleteError = e.toString().replaceFirst('Exception: ', '');
      _deleteStatus = AddressDeleteStatus.failed;
      notifyListeners();
      return false;
    }
  }

  void resetDelete() {
    _deleteStatus = AddressDeleteStatus.idle;
    _deleteError = '';
    notifyListeners();
  }

  void clearSession() {
    _fetchStatus = AddressFetchStatus.initial;
    _saveStatus = AddressSaveStatus.idle;
    _deleteStatus = AddressDeleteStatus.idle;
    _addresses = [];
    _selectedAddressId = null;
    _fetchError = '';
    _saveError = '';
    _deleteError = '';
    notifyListeners();
  }
}
