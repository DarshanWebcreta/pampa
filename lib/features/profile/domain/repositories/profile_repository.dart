import 'package:pampa/features/profile/data/models/customer_profile_model.dart';

abstract class ProfileRepository {
  Future<CustomerProfileModel> getMe();
}

