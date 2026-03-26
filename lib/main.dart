import 'dart:io';

import 'package:flutter/material.dart';


import 'package:loader_overlay/loader_overlay.dart';

import 'package:pampa/core/utils/functional_component.dart';
import 'package:pampa/core/values/colors.dart';

import 'package:toastification/toastification.dart';

import 'package:get_storage/get_storage.dart';
import 'core/routes/pages.dart';
import 'data/service/di.dart';

import 'package:provider/provider.dart';
import 'package:pampa/providers/dummy_provider.dart';
import 'package:pampa/features/auth/presentation/provider/auth_provider.dart';
import 'package:pampa/features/categories/presentation/provider/category_provider.dart';
import 'package:pampa/features/services/presentation/provider/service_provider.dart';
import 'package:pampa/features/address/presentation/provider/address_provider.dart';
import 'package:pampa/features/my_bookings/presentation/provider/my_bookings_provider.dart';
import 'package:pampa/features/messaging/presentation/provider/messaging_provider.dart';
import 'package:pampa/features/profile/presentation/provider/profile_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await GetStorage.init();
  FunctionalComponent.changeStatusBarColor();
  setup();
  runApp(
    const MyApp(),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return  MultiProvider(
        providers: [
        ChangeNotifierProvider(create: (_) => getIt<DummyProvider>()),
        ChangeNotifierProvider(create: (_) => getIt<AuthProvider>()),
        ChangeNotifierProvider(create: (_) => getIt<CategoryProvider>()),
        ChangeNotifierProvider(create: (_) => getIt<AddressProvider>()),
        ChangeNotifierProvider(create: (_) => getIt<MyBookingsProvider>()),
        ChangeNotifierProvider(create: (_) => getIt<ProfileProvider>()),
        ChangeNotifierProvider(create: (_) => getIt<MessagingProvider>()),
    ],
    child:Container(
      color: Platform.isAndroid?AppColor.primaryColor:AppColor.transperent,

      child: SafeArea(
        top:Platform.isAndroid,
        bottom: false,
        child: ToastificationWrapper(

          child: GlobalLoaderOverlay(
            disableBackButton: false,

            overlayWidgetBuilder: (progress) {
              return Center(child: CircularProgressIndicator());
            },
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.noScaling, // No text scaling
              ),
              child: MaterialApp.router(
                debugShowCheckedModeBanner: false,
                routerConfig: AppRouter.router,


                theme: ThemeData(

                  // Set the global scaffold background color here
                  scaffoldBackgroundColor: AppColor.authBg,
                  cardColor: AppColor.white,
                ),

              ),
            ),
          ),
      ),
    )));
  }
}
