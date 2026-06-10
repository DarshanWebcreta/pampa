
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pampa/core/routes/routes.dart';
import 'package:pampa/core/storage/storage.dart';
import 'package:pampa/core/values/keys.dart';
import 'package:pampa/data/service/di.dart';
import 'package:pampa/features/auth/presentation/login/login_screen.dart';
import 'package:pampa/features/auth/presentation/register/register_screen.dart';
import 'package:pampa/features/auth/presentation/welcome/welcome_screen.dart';
import 'package:pampa/features/auth/presentation/user_type/user_type_screen.dart';
import 'package:pampa/features/auth/presentation/forgot_password/forgot_password_screen.dart';
import 'package:pampa/features/auth/presentation/verify_otp/verify_otp_screen.dart';
import 'package:pampa/features/auth/presentation/reset_password/reset_password_screen.dart';
import 'package:pampa/features/auth/presentation/change_password/change_password_screen.dart';
import 'package:pampa/features/booking/data/models/provider_model.dart';
import 'package:pampa/features/categories/presentation/category_list_screen.dart';
import 'package:pampa/features/home/presentation/home_screen.dart';
import 'package:pampa/features/services/presentation/provider/service_provider.dart';
import 'package:pampa/features/services/presentation/services_screen.dart';
import 'package:pampa/features/booking/presentation/booking_screen.dart';
import 'package:pampa/features/booking/presentation/provider/booking_provider.dart';
import 'package:pampa/features/my_bookings/presentation/booking_detail_screen.dart';
import 'package:pampa/features/chat/presentation/chat_screen.dart' show BookingChatScreen;
import 'package:pampa/features/provider_home/presentation/provider_home_screen.dart';
import 'package:provider/provider.dart';

class AppRouter {

  // ── Auth-gate routes (require a token) ──────────────────────────────────────
  static const _protectedRoutes = {
    RouteNames.mainScreen,
    RouteNames.providerMainScreen,
    RouteNames.services,
    RouteNames.bookingDetail,
  };

  // ── Auth-only routes (logged-in users must leave) ────────────────────────
  static const _publicRoutes = {
    RouteNames.userType,
    RouteNames.welcome,
    RouteNames.login,
    RouteNames.register,
  };

  static String _afterLoginDestination() {
    final savedType = StorageManager.readData(StoreKeys.userType) as String?;
    return savedType == 'provider'
        ? RouteNames.providerMainScreen
        : RouteNames.mainScreen;
  }

  static final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();
  static final navigatorKey = GlobalKey<NavigatorState>();

  static GoRouter router = GoRouter(
    navigatorKey: navigatorKey,
    observers: [routeObserver],
    initialLocation: RouteNames.initial,
    redirect: (context, state) {
      final token = StorageManager.readData(StoreKeys.token) as String?;
      final isLoggedIn = token != null && token.isNotEmpty;
      final path = state.matchedLocation;

      // ── Landing: resolve '/' based on auth state ──────────────────────────
      if (path == RouteNames.initial) {
        return isLoggedIn ? _afterLoginDestination() : RouteNames.userType;
      }

      // ── Not logged in trying to access protected route → user type ──────
      if (!isLoggedIn && _protectedRoutes.contains(path)) {
        return RouteNames.userType;
      }

      // ── Already logged in trying to visit login/register → skip ahead ─────
      if (isLoggedIn && _publicRoutes.contains(path)) {
        return _afterLoginDestination();
      }

      return null; // no redirect needed
    },
    routes: [

      GoRoute(
        path: RouteNames.initial,
        name: RouteNames.initial,
        builder: (context, state) => const SizedBox.shrink(),
      ),

      GoRoute(
        path: RouteNames.userType,
        name: RouteNames.userType,
        builder: (context, state) => const UserTypeScreen(),
      ),

      GoRoute(
        path: RouteNames.welcome,
        name: RouteNames.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),

      GoRoute(
        path: RouteNames.login,
        name: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),

      GoRoute(
        path: RouteNames.register,
        name: RouteNames.register,
        builder: (context, state) => const RegisterScreen(),
      ),

      GoRoute(
        path: RouteNames.mainScreen,
        name: RouteNames.mainScreen,
        builder: (context, state) => const HomeScreen(),
      ),

      GoRoute(
        path: RouteNames.providerMainScreen,
        name: RouteNames.providerMainScreen,
        builder: (context, state) => const ProviderHomeScreen(),
      ),

      GoRoute(
        path: RouteNames.categoryList,
        name: RouteNames.categoryList,
        builder: (context, state) => const CategoryListScreen(),
      ),

      GoRoute(
        path: RouteNames.services,
        name: RouteNames.services,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          final categoryId = extra['categoryId'] as int;
          final categoryName = extra['categoryName'] as String;
          return ChangeNotifierProvider(
            create: (_) => getIt<ServiceProvider>(),
            child: ServicesScreen(
              categoryId: categoryId,
              categoryName: categoryName,
            ),
          );
        },
      ),

      GoRoute(
        path: RouteNames.bookingDetail,
        name: RouteNames.bookingDetail,
        builder: (context, state) {
          final extra = state.extra;
          int serviceId;
          ProviderModel? preSelectedProvider;
          int? rescheduleBookingId;
          int? rescheduleAddressId;

          if (extra is Map<String, dynamic>) {
            serviceId = extra['serviceId'] as int;
            preSelectedProvider = extra['preSelectedProvider'] as ProviderModel?;
            rescheduleBookingId = extra['rescheduleBookingId'] as int?;
            rescheduleAddressId = extra['rescheduleAddressId'] as int?;
          } else {
            serviceId = extra as int;
          }

          return ChangeNotifierProvider(
            create: (_) => getIt<BookingProvider>(),
            child: BookingScreen(
              serviceId: serviceId,
              preSelectedProvider: preSelectedProvider,
              rescheduleBookingId: rescheduleBookingId,
              rescheduleAddressId: rescheduleAddressId,
            ),
          );
        },
      ),

      GoRoute(
        path: RouteNames.myBookingDetail,
        name: RouteNames.myBookingDetail,
        builder: (context, state) {
          final bookingId = state.extra as int;
          return BookingDetailScreen(bookingId: bookingId);
        },
      ),

      GoRoute(
        path: RouteNames.chat,
        name: RouteNames.chat,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return BookingChatScreen(
            bookingId: extra['bookingId'] as int,
            providerId: extra['providerId'] as int,
            providerName: extra['providerName'] as String,
          );
        },
      ),

      GoRoute(
        path: RouteNames.forgotPassword,
        name: RouteNames.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      GoRoute(
        path: RouteNames.verifyOtp,
        name: RouteNames.verifyOtp,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final email = extra?['email'] as String? ?? '';
          return VerifyOtpScreen(email: email);
        },
      ),

      GoRoute(
        path: RouteNames.resetPassword,
        name: RouteNames.resetPassword,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final email = extra?['email'] as String? ?? '';
          final otp   = extra?['otp']   as String? ?? '';
          return ResetPasswordScreen(email: email, otp: otp);
        },
      ),

      GoRoute(
        path: RouteNames.changePasswordRoute,
        name: RouteNames.changePasswordRoute,
        builder: (context, state) => const ChangePasswordScreen(),
      ),

    ],

    errorBuilder: (context, state) {
      return Scaffold(
        body: Center(
          child: Text('Invalid route: ${state.name}'),
        ),
      );
    },
  );
}
