import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import 'package:retrofit/retrofit.dart';
import 'package:pampa/core/values/strings.dart';
import 'package:pampa/core/values/urls.dart';

import 'package:pampa/data/interceptor/interceptor.dart';

part 'apiservice.g.dart';

@RestApi(baseUrl: ApiStrings.baseUrl)
abstract class ApiService {
  factory ApiService(Dio dio) {
    final interceptor = DefaultInterceptor();
    dio.interceptors.add(interceptor);
    if(AppStrings.log) {
      dio.interceptors.add(PrettyDioLogger(requestHeader: true,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          error: true,
          compact: true,
          maxWidth: 90));
    }
    return _ApiService(dio);
  }

  @POST(ApiPath.register)
  Future<dynamic> register(@Body() Map<String, dynamic> body);

  @POST(ApiPath.login)
  Future<dynamic> login(@Body() Map<String, dynamic> body);

  @GET(ApiPath.me)
  Future<dynamic> getUser();

  @POST(ApiPath.logout)
  Future<dynamic> logout();

  /// SERVICES

  @GET(ApiPath.categories)
  Future<dynamic> getCategories();

  @GET(ApiPath.services)
  Future<dynamic> getServices(
      @Query("zip_code") String zipCode,
      @Query("category_id") int categoryId,
      );

  @GET("services/{id}")
  Future<dynamic> serviceDetails(
      @Path("id") int id,
      );

  /// BOOKINGS

  @POST(ApiPath.createBooking)
  Future<dynamic> createBooking(@Body() Map<String, dynamic> body);

  @GET(ApiPath.getAddresses)
  Future<dynamic> getAddresses();

  @POST(ApiPath.storeAddress)
  Future<dynamic> storeAddress(@Body() Map<String, dynamic> body);

  @PUT("customer/addresses/{id}")
  Future<dynamic> updateAddress(
    @Path("id") int id,
    @Body() Map<String, dynamic> body,
  );

  @POST("customer/addresses/{id}/default")
  Future<dynamic> setDefaultAddress(@Path("id") int id);

  @DELETE("customer/addresses/{id}")
  Future<dynamic> deleteAddress(@Path("id") int id);

  @GET(ApiPath.providers)
  Future<dynamic> getProviders();

  @GET("providers/{id}/available-slots")
  Future<dynamic> getAvailableSlots(
    @Path("id") int providerId,
    @Query("date") String date,
    @Query("service_id") int serviceId,
  );

  @GET(ApiPath.bookings)
  Future<dynamic> getBookings();

  @GET("${ApiPath.bookings}/{id}")
  Future<dynamic> bookingDetails(@Path("id") int id);

  @POST("${ApiPath.bookings}/{id}/cancel")
  Future<dynamic> cancelBooking(@Path("id") int id);

  /// PAYMENTS

  @GET(ApiPath.stripeConfig)
  Future<dynamic> stripeConfig();

  @POST(ApiPath.createCheckoutSession)
  Future<dynamic> createCheckoutSession(@Body() Map<String, dynamic> body);

  @GET(ApiPath.pendingPayments)
  Future<dynamic> pendingPayments();

  @POST("${ApiPath.paymentsRetry}/{id}")
  Future<dynamic> retryPayment(@Path("id") int id);

  @POST("${ApiPath.paymentOfBalance}/{booking_id}")
  Future<dynamic> payBalance(@Path("booking_id") int bookingId);

  @GET(ApiPath.paymentHistory)
  Future<dynamic> paymentHistory();

  /// PROVIDER WALLET

  @GET(ApiPath.providerWallet)
  Future<dynamic> providerWallet();

  @GET(ApiPath.walletTransactions)
  Future<dynamic> walletTransactions();

  @GET(ApiPath.providerBankDetails)
  Future<dynamic> bankDetails();

  @POST(ApiPath.payoutRequests)
  Future<dynamic> requestPayout(@Body() Map<String, dynamic> body);
}

