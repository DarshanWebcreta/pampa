
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pampa/core/routes/routes.dart';
import 'package:pampa/core/storage/storage.dart';
import 'package:pampa/core/values/keys.dart';
import 'package:pampa/data/service/di.dart';
import 'package:pampa/features/auth/presentation/login/login_screen.dart';
import 'package:pampa/features/auth/presentation/register/register_screen.dart';
import 'package:pampa/features/auth/presentation/welcome/welcome_screen.dart';
import 'package:pampa/features/categories/presentation/category_list_screen.dart';
import 'package:pampa/features/home/presentation/home_screen.dart';
import 'package:pampa/features/onboarding/presentation/zipcode_screen.dart';
import 'package:pampa/features/services/presentation/provider/service_provider.dart';
import 'package:pampa/features/services/presentation/services_screen.dart';
import 'package:pampa/features/booking/presentation/booking_screen.dart';
import 'package:pampa/features/booking/presentation/provider/booking_provider.dart';
import 'package:pampa/features/my_bookings/presentation/booking_detail_screen.dart';
import 'package:provider/provider.dart';

class AppRouter {

  // ── Auth-gate routes (require a token) ──────────────────────────────────────
  static const _protectedRoutes = {
    RouteNames.zipCode,
    RouteNames.mainScreen,
    RouteNames.services,
    RouteNames.bookingDetail,
  };

  // ── Auth-only routes (logged-in users must leave) ────────────────────────
  static const _publicRoutes = {
    RouteNames.welcome,
    RouteNames.login,
    RouteNames.register,
  };

  static String _afterLoginDestination() {
    final zip = StorageManager.readData(StoreKeys.zipCode) as String?;
    final hasZip = zip != null && zip.isNotEmpty;
    return hasZip ? RouteNames.mainScreen : RouteNames.zipCode;
  }

  static GoRouter router = GoRouter(
    initialLocation: RouteNames.initial,
    redirect: (context, state) {
      final token = StorageManager.readData(StoreKeys.token) as String?;
      final isLoggedIn = token != null && token.isNotEmpty;
      final path = state.matchedLocation;

      // ── Landing: resolve '/' based on auth state ──────────────────────────
      if (path == RouteNames.initial) {
        return isLoggedIn ? _afterLoginDestination() : RouteNames.welcome;
      }

      // ── Not logged in trying to access protected route → welcome ─────────
      if (!isLoggedIn && _protectedRoutes.contains(path)) {
        return RouteNames.welcome;
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
        path: RouteNames.zipCode,
        name: RouteNames.zipCode,
        builder: (context, state) => const ZipCodeScreen(),
      ),

      GoRoute(
        path: RouteNames.mainScreen,
        name: RouteNames.mainScreen,
        builder: (context, state) => const HomeScreen(),
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
          final serviceId = state.extra as int;
          return ChangeNotifierProvider(
            create: (_) => getIt<BookingProvider>(),
            child: BookingScreen(serviceId: serviceId),
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
