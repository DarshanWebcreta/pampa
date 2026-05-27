import 'package:pampa/features/services/data/models/service_model.dart';

abstract class ServiceRepository {
  Future<List<ServiceModel>> getServices({
    int? categoryId,
    String? zipCode,
  });
}
