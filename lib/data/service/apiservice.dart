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
    if (AppStrings.log) {
      dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          error: true,
          compact: true,
          maxWidth: 90,
        ),
      );
    }
    return _ApiService(dio);
  }

  @POST(ApiPath.register)
  Future<dynamic> register(@Body() Map<String, dynamic> body);

  @POST(ApiPath.login)
  Future<dynamic> login(@Body() Map<String, dynamic> body);

  @POST(ApiPath.googleLogin)
  Future<dynamic> googleLogin(@Body() Map<String, dynamic> body);

  @GET(ApiPath.me)
  Future<dynamic> getUser();

  @POST(ApiPath.customerProfile)
  @MultiPart()
  Future<dynamic> updateCustomerProfile(@Body() FormData body);

  @POST(ApiPath.logout)
  Future<dynamic> logout();

  /// Password management (type = 'customer' | 'provider')
  @POST("{type}/forgot-password")
  Future<dynamic> forgotPassword(
    @Path("type") String type,
    @Body() Map<String, dynamic> body,
  );

  @POST("{type}/verify-otp")
  Future<dynamic> verifyOtp(
    @Path("type") String type,
    @Body() Map<String, dynamic> body,
  );

  @POST("{type}/reset-password")
  Future<dynamic> resetPassword(
    @Path("type") String type,
    @Body() Map<String, dynamic> body,
  );

  @POST("{type}/change-password")
  Future<dynamic> changePassword(
    @Path("type") String type,
    @Body() Map<String, dynamic> body,
  );

  /// SERVICES

  @GET(ApiPath.categories)
  Future<dynamic> getCategories();

  @GET(ApiPath.services)
  Future<dynamic> getServices(@Query("category_id") int? categoryId);

  @POST(ApiPath.categories)
  @MultiPart()
  Future<dynamic> createCategory(@Body() FormData body);

  @POST("${ApiPath.categories}/{id}")
  @MultiPart()
  Future<dynamic> updateCategory(
    @Path("id") int id,
    @Body() FormData body,
  );

  @POST(ApiPath.services)
  @MultiPart()
  Future<dynamic> createService(@Body() FormData body);

  @POST("${ApiPath.services}/{id}")
  @MultiPart()
  Future<dynamic> updateService(@Path("id") int id, @Body() FormData body);

  @DELETE("${ApiPath.services}/{id}")
  Future<dynamic> deleteService(@Path("id") int id);

  @GET("services/{id}")
  Future<dynamic> serviceDetails(@Path("id") int id);

  /// BOOKINGS

  @POST(ApiPath.createBooking)
  @MultiPart()
  Future<dynamic> createBooking(@Body() FormData body);

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

  @GET("providers/{id}")
  Future<dynamic> getProviderDetail(@Path("id") int id);

  @GET(ApiPath.providers)
  Future<dynamic> getProviders(@Query("zip_code") String zipCode);

  @GET(ApiPath.availableProviders)
  Future<dynamic> getAvailableProviders(
    @Query("service_ids[]") List<int> serviceIds,
    @Query("zip_code") String zipCode,
    @Query("date") String date,
    @Query("time") String time,
  );

  @GET("providers/{id}/available-slots")
  Future<dynamic> getAvailableSlots(
    @Path("id") int providerId,
    @Query("date") String date,
    @Query("service_ids[]") int serviceId,
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

  /// PROVIDER DASHBOARD

  @GET(ApiPath.providerDashboard)
  Future<dynamic> getProviderDashboard();

  @GET(ApiPath.providerProfile)
  Future<dynamic> getProviderProfile();

  @PUT(ApiPath.providerProfileUpdate)
  Future<dynamic> updateProviderProfile(@Body() Map<String, dynamic> body);

  @POST(ApiPath.providerGallery)
  @MultiPart()
  Future<dynamic> uploadProviderGallery(@Body() FormData body);

  @DELETE("providers/gallery/{id}")
  Future<dynamic> deleteProviderGalleryImage(@Path("id") int id);

  @GET(ApiPath.providerEarnings)
  Future<dynamic> getProviderEarnings();

  @GET(ApiPath.providerSettings)
  Future<dynamic> getProviderSettings();

  @POST(ApiPath.providerSettingsAvailability)
  Future<dynamic> updateProviderAvailability(@Body() Map<String, dynamic> body);

  @POST(ApiPath.providerSettingsPricing)
  Future<dynamic> updateProviderPricing(@Body() Map<String, dynamic> body);

  @POST(ApiPath.providerSettingsCredentials)
  @MultiPart()
  Future<dynamic> updateProviderCredentials(@Body() FormData body);

  @POST(ApiPath.providerToggleOnline)
  Future<dynamic> providerToggleOnline();

  @GET(ApiPath.providerBookings)
  Future<dynamic> getProviderBookings({
    @Query("status") String? status,
    @Query("date") String? date,
  });

  @GET("provider/bookings/{id}")
  Future<dynamic> getProviderBookingDetail(@Path("id") int id);

  @POST("provider/bookings/{id}/status")
  Future<dynamic> updateProviderBookingStatus(
    @Path("id") int id,
    @Body() Map<String, dynamic> body,
  );

  @POST("provider/bookings/{id}/cancel")
  Future<dynamic> cancelProviderBooking(@Path("id") int id);

  /// PROVIDER WALLET

  @GET(ApiPath.providerWallet)
  Future<dynamic> providerWallet();

  @GET(ApiPath.walletTransactions)
  Future<dynamic> walletTransactions();

  @GET(ApiPath.providerBankDetails)
  Future<dynamic> bankDetails();

  @POST(ApiPath.providerBankDetails)
  Future<dynamic> saveBankDetails(@Body() Map<String, dynamic> body);

  @GET(ApiPath.payoutRequests)
  Future<dynamic> getPayoutRequests({
    @Query("per_page") int? perPage,
    @Query("page") int? page,
  });

  @POST(ApiPath.payoutRequests)
  Future<dynamic> requestPayout(@Body() Map<String, dynamic> body);

  @POST(ApiPath.payoutRequest)
  Future<dynamic> createPayoutRequest(@Body() Map<String, dynamic> body);

  /// MESSAGING

  @GET(ApiPath.conversations)
  Future<dynamic> getConversations();

  @POST(ApiPath.conversations)
  Future<dynamic> createOrGetConversation(@Body() Map<String, dynamic> body);

  @GET(ApiPath.providerConversations)
  Future<dynamic> getProviderConversations();

  @POST(ApiPath.providerConversations)
  Future<dynamic> createOrGetProviderConversation(
    @Body() Map<String, dynamic> body,
  );

  @GET("messages/conversations/{id}")
  Future<dynamic> getConversationMessages(@Path("id") int id);

  @GET("${ApiPath.providerMessagesConversations}/{id}")
  Future<dynamic> getProviderConversationMessages(@Path("id") int id);

  @POST("messages/conversations/{id}")
  Future<dynamic> sendMessage(
    @Path("id") int id,
    @Body() Map<String, dynamic> body,
  );

  @POST("${ApiPath.providerConversations}/{id}")
  Future<dynamic> sendProviderMessage(
    @Path("id") int id,
    @Body() Map<String, dynamic> body,
  );

  @POST(ApiPath.adminChat)
  Future<dynamic> getAdminChat();

  /// NOTIFICATION PREFERENCES

  @GET(ApiPath.notificationPreferences)
  Future<dynamic> getNotificationPreferences();

  @POST(ApiPath.notificationPreferences)
  Future<dynamic> updateNotificationPreferences(
    @Body() Map<String, dynamic> body,
  );

  @POST(ApiPath.notificationToken)
  Future<dynamic> submitNotificationToken(@Body() Map<String, dynamic> body);

  @GET(ApiPath.beautyPreferences)
  Future<dynamic> getBeautyPreferences();

  /// FAVORITES

  @GET(ApiPath.favoriteProviders)
  Future<dynamic> getFavoriteProviders();

  @POST(ApiPath.favoriteProviders)
  Future<dynamic> addFavoriteProvider(@Body() Map<String, dynamic> body);

  @DELETE("${ApiPath.favoriteProviders}/{provider_id}")
  Future<dynamic> removeFavoriteProvider(@Path("provider_id") int providerId);

  /// PAGES

  @GET(ApiPath.pages)
  Future<dynamic> getPages();

  @GET("${ApiPath.pages}/{slug}")
  Future<dynamic> getPageBySlug(@Path("slug") String slug);

  /// EXPLORE

  @GET(ApiPath.explore)
  Future<dynamic> explore(@Query("query") String? query);
}
