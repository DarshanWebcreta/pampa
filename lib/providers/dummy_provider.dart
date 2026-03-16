import 'package:flutter/material.dart';

import 'package:pampa/data/service/apiservice.dart';


class DummyProvider extends ChangeNotifier {
  final ApiService apiService;
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _data;

  DummyProvider({required this.apiService});

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get data => _data;

  // Future<void> fetchData() async {
  //   _isLoading = true;
  //   _errorMessage = null;
  //   notifyListeners();
  //
  //   try {
  //     _data = await apiService.fetchPost();
  //   } catch (e) {
  //     _errorMessage = e.toString();
  //   } finally {
  //     _isLoading = false;
  //     notifyListeners();
  //   }
  // }

  void clearData() {
    _data = null;
    _errorMessage = null;
    notifyListeners();
  }
}
