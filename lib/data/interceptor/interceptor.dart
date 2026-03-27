import 'package:dio/dio.dart';
import 'package:pampa/core/storage/storage.dart';
import 'package:pampa/core/values/keys.dart';
import 'package:pampa/core/values/urls.dart';


class DefaultInterceptor extends Interceptor {
  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    // Don't override Content-Type for FormData — Dio sets multipart/form-data
    // with the correct boundary automatically for FormData requests.
    if (options.data is! FormData) {
      options.headers[ApiStrings.contentType] = ApiStrings.applicationXWWW;
    }
    options.headers[ApiStrings.accept] = ApiStrings.applicationJson;

    options.connectTimeout = const Duration(milliseconds: 20000);
    options.sendTimeout = const Duration(milliseconds: 20000);
    options.receiveTimeout = const Duration(milliseconds: 20000);

    String? authToken = StorageManager.readData(StoreKeys.token);
    if (authToken != null && authToken.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $authToken';
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    handler.next(response);
  }

  @override
  void onError(DioException? err, ErrorInterceptorHandler handler) {
    // Get.context!.loaderOverlay.hide();
    // Get.snackbar("Some Error occured",
    //     error!.message ?? '');

    handler.next(err!);
  }
}
