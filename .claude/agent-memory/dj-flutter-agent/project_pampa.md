---
name: pampa_project_structure
description: Core architecture, patterns, and structure of the Pampa Flutter project
type: project
---

## Project: Pampa (Field Sales App)
- Flutter project targeting iOS/Android
- State management: Provider (ChangeNotifier) via get_it DI — NOT BLoC/Cubit despite the repo context from other projects
- Navigation: go_router v17.0.1 with named routes (NavService utility class)
- HTTP: Dio + Retrofit (code-gen via build_runner), with DefaultInterceptor
- Local storage: get_storage (StorageManager static class)
- DI: get_it (setup() in lib/data/service/di.dart)
- Error handling: HandleExeption (Dio-only, no use-case layer yet)
- Architecture: Feature-first leaning, but currently very flat — mostly scaffold/boilerplate stage
- Font: Inter (set globally in AppTheme and customTextStyle)
- Assets: assets/image/ for PNG/webp, assets/svgs/ for SVGs, assets/animations/ for Lottie

## Key Files
- lib/main.dart — app entry point, MultiProvider + GoRouter + GlobalLoaderOverlay
- lib/data/service/di.dart — GetIt setup()
- lib/core/routes/pages.dart — AppRouter (GoRouter config)
- lib/core/routes/routes.dart — RouteNames constants
- lib/core/utils/navigation.dart — NavService (GoRouter wrapper)
- lib/core/storage/storage.dart — StorageManager (get_storage)
- lib/data/interceptor/interceptor.dart — DefaultInterceptor (auth token injection)
- lib/providers/dummy_provider.dart — DummyProvider (ChangeNotifier)

## Known Issues (first review 2026-03-16)
- GoRouter has only 1 route defined (/), all other RouteNames are dead constants
- NavigationMethods enum (navigationenums.dart) is a legacy artifact — superseded by NavAction enum
- DI instantiates services eagerly before registerLazySingleton, breaking lazy init intent
- LocationService adds its own PrettyDioLogger on shared Dio instance (interceptor duplication)
- GetStorage is never initialized (GetStorage.init() missing from main())
- AppStrings has mutable static fields (categoryTitle, bestSeller, etc.) — global mutable state anti-pattern
- Duplicate import block in text_widget.dart (flutter/material.dart + app_colors.dart imported twice)
- Missing assets declaration in pubspec.yaml
- FunctionalComponent.bottomSheet() Cancel/Done callbacks are empty no-ops
- RoundedButton close button in bottomSheet header is a no-op (does not pop)
- totalBillCardForSummary uses double.parse() without guard — throws on non-numeric strings
- CommonNotifier (value_notifier.dart) has a hardcoded Future.delayed — placeholder not removed
- DeviceInfoService uses nullable-but-actually-non-null fields (.model, .version, etc.) incorrectly for newer device_info_plus versions
- AppStrings.log is hardcoded true — logging enabled in production build
- ApiPath.dummy points to non-existent endpoint
- NavAction.replace uses pushReplacementNamed but NavAction.clearStack also uses goNamed (duplicate behavior)
- profile ImageStrings constant points to home.svg (placeholder not updated)
