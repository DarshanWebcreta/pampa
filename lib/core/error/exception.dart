import 'package:dio/dio.dart';

class HandleExeption {
  HandleExeption._();

  static handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return "Please Check Your Network connection";
      case DioExceptionType.sendTimeout:
        return "Plase Try again";
      case DioExceptionType.receiveTimeout:
        return "Please try again";
      case DioExceptionType.badResponse:
        return "Something went wrong";
      case DioExceptionType.connectionError:
        return "Please Check Your Internet connection";
      default:
        return "Something went wrong";
    }
  }
}
