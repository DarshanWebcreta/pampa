import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:pampa/core/common_models/device_info.dart';
import 'package:pampa/providers/dummy_provider.dart';
import 'package:pampa/data/service/apiservice.dart';
import 'package:pampa/data/service/location_service.dart';
import 'package:pampa/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:pampa/features/auth/domain/repositories/auth_repository.dart';
import 'package:pampa/features/auth/presentation/provider/auth_provider.dart';
import 'package:pampa/features/categories/data/repositories/category_repository_impl.dart';
import 'package:pampa/features/categories/domain/repositories/category_repository.dart';
import 'package:pampa/features/categories/presentation/provider/category_provider.dart';
import 'package:pampa/features/services/data/repositories/service_repository_impl.dart';
import 'package:pampa/features/services/domain/repositories/service_repository.dart';
import 'package:pampa/features/services/presentation/provider/service_provider.dart';
import 'package:pampa/features/booking/data/repositories/booking_repository_impl.dart';
import 'package:pampa/features/booking/domain/repositories/booking_repository.dart';
import 'package:pampa/features/booking/presentation/provider/booking_provider.dart';
import 'package:pampa/features/address/data/repositories/address_repository_impl.dart';
import 'package:pampa/features/address/domain/repositories/address_repository.dart';
import 'package:pampa/features/address/presentation/provider/address_provider.dart';
import 'package:pampa/features/my_bookings/data/repositories/my_bookings_repository_impl.dart';
import 'package:pampa/features/my_bookings/domain/repositories/my_bookings_repository.dart';
import 'package:pampa/features/my_bookings/presentation/provider/my_bookings_provider.dart';
import 'package:pampa/features/messaging/data/repositories/messaging_repository_impl.dart';
import 'package:pampa/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:pampa/features/messaging/presentation/provider/messaging_provider.dart';
import 'package:pampa/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:pampa/features/profile/domain/repositories/profile_repository.dart';
import 'package:pampa/features/profile/presentation/provider/profile_provider.dart';
import 'package:pampa/features/explore/data/repositories/explore_repository_impl.dart';
import 'package:pampa/features/explore/domain/repositories/explore_repository.dart';
import 'package:pampa/features/explore/presentation/provider/explore_provider.dart';
import 'package:pampa/features/favorites/presentation/provider/favorites_provider.dart';

final getIt = GetIt.instance;

void setup() {
  final dio = Dio();
  getIt.registerLazySingleton<Dio>(() => dio);

  final ApiService apiServices = ApiService(getIt<Dio>());
  final LocationService locationService = LocationService(getIt<Dio>());
  getIt.registerLazySingleton(() => apiServices);
  getIt.registerLazySingleton(() => locationService);

  getIt.registerLazySingleton<DeviceInfoService>(() => DeviceInfoService());

  getIt.registerLazySingleton<DummyProvider>(() => DummyProvider(apiService: getIt()));

  // Auth
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(getIt<ApiService>()),
  );
  getIt.registerLazySingleton<AuthProvider>(
    () => AuthProvider(getIt<AuthRepository>()),
  );

  // Categories
  getIt.registerLazySingleton<CategoryRepository>(
    () => CategoryRepositoryImpl(getIt<ApiService>()),
  );
  getIt.registerLazySingleton<CategoryProvider>(
    () => CategoryProvider(getIt<CategoryRepository>()),
  );

  // Services
  getIt.registerLazySingleton<ServiceRepository>(
    () => ServiceRepositoryImpl(getIt<ApiService>()),
  );
  getIt.registerFactory<ServiceProvider>(
    () => ServiceProvider(getIt<ServiceRepository>()),
  );

  // Booking
  getIt.registerLazySingleton<BookingRepository>(
    () => BookingRepositoryImpl(getIt<ApiService>()),
  );
  getIt.registerFactory<BookingProvider>(
    () => BookingProvider(getIt<BookingRepository>()),
  );

  // Address
  getIt.registerLazySingleton<AddressRepository>(
    () => AddressRepositoryImpl(getIt<ApiService>()),
  );
  getIt.registerLazySingleton<AddressProvider>(
    () => AddressProvider(getIt<AddressRepository>()),
  );

  // My Bookings
  getIt.registerLazySingleton<MyBookingsRepository>(
    () => MyBookingsRepositoryImpl(getIt<ApiService>()),
  );
  getIt.registerLazySingleton<MyBookingsProvider>(
    () => MyBookingsProvider(getIt<MyBookingsRepository>()),
  );

  // Profile
  getIt.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(getIt<ApiService>()),
  );
  getIt.registerLazySingleton<ProfileProvider>(
    () => ProfileProvider(getIt<ProfileRepository>()),
  );

  // Messaging
  getIt.registerLazySingleton<MessagingRepository>(
    () => MessagingRepositoryImpl(getIt<ApiService>()),
  );
  getIt.registerLazySingleton<MessagingProvider>(
    () => MessagingProvider(getIt<MessagingRepository>()),
  );

  // Explore
  getIt.registerLazySingleton<ExploreRepository>(
    () => ExploreRepositoryImpl(getIt<ApiService>()),
  );
  getIt.registerLazySingleton<ExploreProvider>(
    () => ExploreProvider(getIt<ExploreRepository>()),
  );

  // Favorites
  getIt.registerLazySingleton<FavoritesProvider>(
    () => FavoritesProvider(getIt<ApiService>()),
  );
}
