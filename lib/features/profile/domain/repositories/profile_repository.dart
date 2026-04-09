import 'package:dio/dio.dart';
import 'package:pampa/features/profile/data/models/customer_profile_model.dart';

abstract class ProfileRepository {
  Future<CustomerProfileModel> getMe();
  Future<CustomerProfileModel> updateProfile(FormData formData);
}
