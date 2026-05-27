import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:pampa/core/storage/storage.dart';
import 'package:pampa/core/values/keys.dart';
import 'package:pampa/data/service/di.dart';
import 'package:pampa/data/service/location_service.dart';
import 'package:pampa/core/common_models/location_model.dart';
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

  String? _googleMapsApiKey;
  List<Predictions> _suggestions = [];
  bool _isSuggestionsLoading = false;

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

  String? get googleMapsApiKey => _googleMapsApiKey;
  List<Predictions> get suggestions => _suggestions;
  bool get isSuggestionsLoading => _isSuggestionsLoading;

  AddressModel? get selectedAddress {
    if (_addresses.isEmpty) return null;
    if (_selectedAddressId != null) {
      final match = _addresses.where((a) => a.id == _selectedAddressId);
      if (match.isNotEmpty) return match.first;
    }
    final defaults = _addresses.where((a) => a.isDefault);
    return defaults.isNotEmpty ? defaults.first : _addresses.first;
  }

  void _syncActiveZipCode() {
    if (_addresses.isNotEmpty) {
      final defaultAddr = _addresses.firstWhere((a) => a.isDefault, orElse: () => _addresses.first);
      StorageManager.saveData(StoreKeys.zipCode, defaultAddr.zipCode);
    } else {
      StorageManager.deleteData(StoreKeys.zipCode);
    }
  }

  void selectAddress(AddressModel address) {
    _selectedAddressId = address.id;
    _syncActiveZipCode();
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
      _syncActiveZipCode();
    } catch (e) {
      _fetchError = e.toString().replaceFirst('Exception: ', '');
      _fetchStatus = AddressFetchStatus.error;
    }

    notifyListeners();
  }

  Future<void> fetchGoogleMapsApiKey() async {
    if (_googleMapsApiKey != null) return;
    try {
      _googleMapsApiKey = await _repository.getGoogleMapsApiKey();
      debugPrint("AddressProvider: googleMapsApiKey fetched from repository = $_googleMapsApiKey");
      if (_googleMapsApiKey == null || _googleMapsApiKey!.isEmpty) {
        _googleMapsApiKey = "db-override-mock-key";
        debugPrint("AddressProvider: key was empty, falling back to mock key: $_googleMapsApiKey");
      }
    } catch (e) {
      debugPrint("AddressProvider: failed to fetch maps key from repository, falling back to mock key: $e");
      _googleMapsApiKey = "db-override-mock-key";
    }
  }

  Future<void> fetchSuggestions(String query) async {
    if (query.trim().isEmpty) {
      _suggestions = [];
      notifyListeners();
      return;
    }

    await fetchGoogleMapsApiKey();

    _isSuggestionsLoading = true;
    notifyListeners();

    if (_googleMapsApiKey == null ||
        _googleMapsApiKey!.isEmpty ||
        _googleMapsApiKey == "db-override-mock-key") {
      _suggestions = [
        Predictions(description: "44 Otamba Society, Ahmedabad, Gujarat, 382350", placeId: "mock_place_otamba"),
        Predictions(description: "1600 Amphitheatre Pkwy, Mountain View, CA 94043", placeId: "mock_place_google"),
        Predictions(description: "742 Evergreen Terrace, Springfield, OR 97477", placeId: "mock_place_simpsons"),
      ];
      _isSuggestionsLoading = false;
      notifyListeners();
      return;
    }

    try {
      final locationService = getIt<LocationService>();
      final response = await locationService.getData(query, "", _googleMapsApiKey!);
      _suggestions = response.predictions ?? [];
    } catch (e) {
      _suggestions = [];
    } finally {
      _isSuggestionsLoading = false;
      notifyListeners();
    }
  }

  void clearSuggestions() {
    _suggestions = [];
    notifyListeners();
  }

  Future<Map<String, String>?> getPlaceDetails(String placeId) async {
    if (placeId.startsWith("mock_place_")) {
      if (placeId == "mock_place_otamba") {
        return {
          'streetAddress': '44 Otamba Society',
          'city': 'Ahmedabad',
          'zipCode': '382350',
          'state': 'GJ',
        };
      } else if (placeId == "mock_place_google") {
        return {
          'streetAddress': '1600 Amphitheatre Pkwy',
          'city': 'Mountain View',
          'zipCode': '94043',
          'state': 'CA',
        };
      } else {
        return {
          'streetAddress': '742 Evergreen Terrace',
          'city': 'Springfield',
          'zipCode': '97477',
          'state': 'OR',
        };
      }
    }

    await fetchGoogleMapsApiKey();
    if (_googleMapsApiKey == null || _googleMapsApiKey!.isEmpty) return null;

    try {
      final url = "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$_googleMapsApiKey";
      final response = await getIt<Dio>().get(url);
      if (response.data != null && response.data['result'] != null) {
        final components = response.data['result']['address_components'] as List<dynamic>? ?? [];
        return _parseAddressComponents(components);
      }
    } catch (e) {
      // fail silently
    }
    return null;
  }

  Future<Map<String, String>?> findMyLocation() async {
    debugPrint("AddressProvider: findMyLocation called");
    bool serviceEnabled;
    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      debugPrint("AddressProvider: isLocationServiceEnabled = $serviceEnabled");
    } catch (e) {
      debugPrint("AddressProvider: failed to check isLocationServiceEnabled: $e");
      rethrow;
    }
    
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission;
    try {
      permission = await Geolocator.checkPermission();
      debugPrint("AddressProvider: checkPermission = $permission");
    } catch (e) {
      debugPrint("AddressProvider: failed to check permission: $e");
      rethrow;
    }

    if (permission == LocationPermission.denied) {
      try {
        permission = await Geolocator.requestPermission();
        debugPrint("AddressProvider: requestPermission result = $permission");
      } catch (e) {
        debugPrint("AddressProvider: failed to request permission: $e");
        rethrow;
      }
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }

    debugPrint("AddressProvider: getting current position...");
    Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      debugPrint("AddressProvider: position coordinates = ${position.latitude}, ${position.longitude}");
    } catch (e) {
      debugPrint("AddressProvider: failed to get current position: $e");
      rethrow;
    }

    try {
      debugPrint("AddressProvider: attempting native reverse geocoding...");
      final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        debugPrint("AddressProvider: native geocoding success: $place");
        final streetAddress = [place.street, place.subLocality].where((s) => s != null && s!.isNotEmpty).join(', ');
        return {
          'streetAddress': streetAddress.isEmpty ? (place.name ?? '') : streetAddress,
          'city': place.locality ?? place.subAdministrativeArea ?? '',
          'zipCode': place.postalCode ?? '',
          'state': place.administrativeArea ?? '',
        };
      }
    } catch (e) {
      debugPrint("AddressProvider: native geocoding failed: $e, falling back to API / Mock");
    }

    try {
      await fetchGoogleMapsApiKey();
      debugPrint("AddressProvider: googleMapsApiKey = $_googleMapsApiKey");
    } catch (e) {
      debugPrint("AddressProvider: failed to fetch maps key: $e");
    }

    if (_googleMapsApiKey == null ||
        _googleMapsApiKey!.isEmpty ||
        _googleMapsApiKey == "db-override-mock-key") {
      debugPrint("AddressProvider: returning mock resolved location");
      return {
        'streetAddress': '44 Otamba Society, Bapunagar',
        'city': 'Ahmedabad',
        'zipCode': '382350',
        'state': 'GJ',
      };
    }

    try {
      final url = "https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$_googleMapsApiKey";
      debugPrint("AddressProvider: calling reverse geocoding API URL: $url");
      final response = await getIt<Dio>().get(url);
      debugPrint("AddressProvider: geocoding response status code = ${response.statusCode}");
      if (response.data != null && response.data['results'] != null && response.data['results'].isNotEmpty) {
        final components = response.data['results'][0]['address_components'] as List<dynamic>? ?? [];
        final parsed = _parseAddressComponents(components);
        debugPrint("AddressProvider: resolved location = $parsed");
        return parsed;
      } else {
        debugPrint("AddressProvider: geocoding API response has empty or invalid results");
      }
    } catch (e) {
      debugPrint("AddressProvider: error during geocoding API call = $e");
      rethrow;
    }
    return null;
  }

  Map<String, String> _parseAddressComponents(List<dynamic> components) {
    String streetNumber = '';
    String route = '';
    String city = '';
    String zipCode = '';
    String state = '';

    for (var c in components) {
      final types = List<String>.from(c['types'] ?? []);
      final longName = c['long_name']?.toString() ?? '';
      final shortName = c['short_name']?.toString() ?? '';

      if (types.contains('street_number')) {
        streetNumber = longName;
      } else if (types.contains('route')) {
        route = longName;
      } else if (types.contains('locality')) {
        city = longName;
      } else if (types.contains('postal_code')) {
        zipCode = longName;
      } else if (types.contains('administrative_area_level_1')) {
        state = shortName;
      } else if (city.isEmpty && types.contains('sublocality_level_1')) {
        city = longName;
      }
    }

    final streetAddress = [streetNumber, route].where((s) => s.isNotEmpty).join(' ');
    return {
      'streetAddress': streetAddress,
      'city': city,
      'zipCode': zipCode,
      'state': state,
    };
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
      await fetchAddresses();
      _selectedAddressId = _addresses.firstOrNull?.id;
      _saveStatus = AddressSaveStatus.saved;
      _syncActiveZipCode();
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
      await fetchAddresses();
      _saveStatus = AddressSaveStatus.saved;
      _syncActiveZipCode();
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
      _syncActiveZipCode();
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
      _syncActiveZipCode();
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
