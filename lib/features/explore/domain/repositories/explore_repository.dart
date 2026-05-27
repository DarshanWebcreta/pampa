import 'package:pampa/features/booking/data/models/provider_model.dart';
import 'package:pampa/features/explore/data/models/explore_model.dart';

abstract class ExploreRepository {
  Future<ExploreResultModel> explore({
    String? query,
    String? zipCode,
  });
  Future<ProviderModel> getProviderDetail(int id);
}
