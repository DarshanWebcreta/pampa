import 'package:flutter/material.dart';
import 'package:pampa/data/service/apiservice.dart';
import 'package:pampa/data/service/di.dart';
import 'package:pampa/features/profile/data/models/customer_profile_model.dart';
import 'package:pampa/features/profile/domain/repositories/profile_repository.dart';

class PageModel {
  final int id;
  final String title;
  final String slug;

  const PageModel({required this.id, required this.title, required this.slug});

  factory PageModel.fromJson(Map<String, dynamic> json) => PageModel(
        id: json['id'] as int? ?? 0,
        title: json['title'] as String? ?? '',
        slug: json['slug'] as String? ?? '',
      );
}

enum ProfileStatus { initial, loading, success, error }

class ProfileProvider extends ChangeNotifier {
  final ProfileRepository _repository;
  final ApiService _api = getIt<ApiService>();

  ProfileProvider(this._repository);

  ProfileStatus _status = ProfileStatus.initial;
  CustomerProfileModel? _profile;
  String _errorMessage = '';
  List<PageModel> _pages = [];

  ProfileStatus get status => _status;
  CustomerProfileModel? get profile => _profile;
  String get errorMessage => _errorMessage;
  bool get isLoading => _status == ProfileStatus.loading;
  List<PageModel> get pages => _pages;

  Future<void> fetchProfile() async {
    if (_status == ProfileStatus.loading) return;

    _status = ProfileStatus.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      // Fetch profile and pages in parallel
      final results = await Future.wait([
        _repository.getMe(),
        _fetchPages(),
      ]);
      _profile = results[0] as CustomerProfileModel;
      _status = ProfileStatus.success;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _status = ProfileStatus.error;
    }

    notifyListeners();
  }

  Future<void> _fetchPages() async {
    try {
      final response = await _api.getPages();
      final map = response as Map<String, dynamic>;
      if (map['status'] == true) {
        _pages = (map['data'] as List<dynamic>)
            .map((e) => PageModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      // Pages failing should not break profile load
    }
  }

  void refresh() => fetchProfile();
}
