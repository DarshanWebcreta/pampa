import 'package:dio/dio.dart';

import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:retrofit/error_logger.dart';
import 'package:retrofit/http.dart';
import 'package:pampa/core/common_models/location_model.dart';
import 'package:pampa/core/values/urls.dart';

part 'location_service.g.dart';

@RestApi(baseUrl: ApiStrings.locationApiURL)
abstract class LocationService {

  factory LocationService(Dio dio){
    dio.interceptors.add(PrettyDioLogger(requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: true,
        maxWidth: 90));

    return _LocationService(dio);


  }

  @GET("")
  Future<LocationModel> getData(
      @Query("input") String input,
      @Query("components") String components,
      @Query("key") String key,
      );
}


