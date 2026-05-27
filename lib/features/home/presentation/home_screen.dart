import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:pampa/core/routes/pages.dart';
import 'package:pampa/core/services/push_notification_service.dart';
import 'package:pampa/core/values/urls.dart';
import 'package:pampa/features/address/presentation/saved_addresses_screen.dart' show SavedAddressesScreen;
import 'package:pampa/features/address/presentation/address_search_screen.dart';
import 'package:pampa/features/explore/presentation/provider/explore_provider.dart';
import 'package:provider/provider.dart';

import 'package:pampa/core/routes/routes.dart';
import 'package:pampa/core/storage/storage.dart';
import 'package:pampa/core/utils/functional_component.dart';
import 'package:pampa/core/values/app_text_value.dart';
import 'package:pampa/core/values/colors.dart';
import 'package:pampa/core/values/keys.dart';
import 'package:pampa/core/widgets/text_widget.dart';
import 'package:pampa/data/service/di.dart';
import 'package:pampa/features/address/data/models/address_model.dart';
import 'package:pampa/features/address/presentation/provider/address_provider.dart';
import 'package:pampa/features/categories/data/models/category_model.dart';
import 'package:pampa/features/categories/presentation/provider/category_provider.dart';
import 'package:pampa/features/my_bookings/data/models/my_booking_model.dart';
import 'package:pampa/features/my_bookings/presentation/my_bookings_tab.dart';
import 'package:pampa/features/my_bookings/presentation/provider/my_bookings_provider.dart';
import 'package:pampa/features/profile/presentation/provider/profile_provider.dart';
import 'package:pampa/features/messaging/presentation/conversations_tab.dart';
import 'package:pampa/features/profile/presentation/profile_tab.dart';
import 'package:pampa/features/explore/presentation/explore_tab.dart';
import 'package:pampa/features/profile/presentation/beauty_preferences_screen.dart';
import 'package:intl/intl.dart';

// ─── Icon mapping for category names ──────────────────────────────────────────
IconData _iconForCategory(String name) {
  final lower = name.toLowerCase();
  if (lower.contains('salon') || lower.contains('hair')) return Icons.content_cut_rounded;
  if (lower.contains('nail')) return Icons.colorize_rounded;
  if (lower.contains('makeup') || lower.contains('beauty')) return Icons.brush_rounded;
  if (lower.contains('massage') || lower.contains('spa')) return Icons.self_improvement_rounded;
  if (lower.contains('facial') || lower.contains('skin')) return Icons.face_retouching_natural_rounded;
  if (lower.contains('brow') || lower.contains('lash')) return Icons.auto_awesome_rounded;
  if (lower.contains('wax')) return Icons.waves_rounded;
  if (lower.contains('yoga') || lower.contains('fitness')) return Icons.fitness_center_rounded;
  return Icons.spa_rounded;
}

// ─── Tab switcher notifier ────────────────────────────────────────────────────
final homeTabNotifier = ValueNotifier<int>(0);
final homeSuccessMessageNotifier = ValueNotifier<String?>(null);

// ─── Bottom-nav item data ──────────────────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}

const _navItems = [
  _NavItem(icon: Icons.home_outlined,               activeIcon: Icons.home_rounded,            label: 'Home'),
  _NavItem(icon: Icons.explore_outlined,            activeIcon: Icons.explore_rounded,         label: 'Explore'),
  _NavItem(icon: Icons.calendar_month_outlined,     activeIcon: Icons.calendar_month_rounded,  label: 'Appointments'),
  _NavItem(icon: Icons.chat_bubble_outline_rounded, activeIcon: Icons.chat_bubble_rounded,     label: 'Messages'),
  _NavItem(icon: Icons.person_outline_rounded,      activeIcon: Icons.person_rounded,          label: 'Profile'),
];

// ─── Main shell ───────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  late final AddressProvider _addressProvider;
  bool _isRedirecting = false;

  @override
  void initState() {
    super.initState();
    homeSuccessMessageNotifier.addListener(_onSuccessMessage);
    homeTabNotifier.addListener(_onTabChanged);
    _addressProvider = context.read<AddressProvider>();
    _addressProvider.addListener(_onAddressProviderChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshDashboardData();
      getIt<PushNotificationService>().syncTokenWithBackend();
      _addressProvider.fetchGoogleMapsApiKey();
    });
  }

  void _onAddressProviderChanged() {
    if (!mounted) return;
    if (_addressProvider.fetchStatus == AddressFetchStatus.loaded) {
      if (_addressProvider.addresses.isEmpty) {
        _redirectToSavedAddresses();
      } else {
        context.read<ExploreProvider>().fetch();
      }
    }
  }

  void _redirectToSavedAddresses() {
    if (_isRedirecting) return;
    _isRedirecting = true;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SavedAddressesScreen()),
    ).then((_) {
      _isRedirecting = false;
      _onAddressProviderChanged();
    });
  }

  void _onTabChanged() {
    if (homeTabNotifier.value == 0 || homeTabNotifier.value == 2) {
      _refreshDashboardData();
    }
  }

  void _refreshDashboardData() {
    if (!mounted) return;
    context.read<CategoryProvider>().fetchCategories();
    context.read<AddressProvider>().fetchAddresses();
    final profileProvider = context.read<ProfileProvider>();
    if (profileProvider.status == ProfileStatus.initial || profileProvider.profile == null) {
      profileProvider.fetchProfile();
    }
    context.read<MyBookingsProvider>().fetchBookings();
  }

  void _onSuccessMessage() {
    final message = homeSuccessMessageNotifier.value;
    if (!mounted || message == null || message.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showPaymentSuccessDialog(message);
      _refreshDashboardData(); // Refresh on booking success
    });
    homeSuccessMessageNotifier.value = null;
  }

  Future<void> _showExitDialog() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Exit App'),
        content: const Text('Are you sure you want to exit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('No', style: TextStyle(color: AppColor.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Yes', style: TextStyle(color: AppColor.authButton)),
          ),
        ],
      ),
    );
    if (shouldExit == true && mounted) {
      SystemNavigator.pop();
    }
  }

  Future<void> _showPaymentSuccessDialog(String message) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            decoration: BoxDecoration(
              color: AppColor.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: AppColor.authButton.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: AppColor.authButton,
                    size: 44,
                  ),
                ),
                const SizedBox(height: 20),
                AppText(
                  'Booking Created',
                  fontSize: FontSizes.large,
                  fontWeight: FontWeights.bold,
                  color: AppColor.darkGrey,
                  align: TextAlign.center,
                ),
                const SizedBox(height: 8),
                AppText(
                  message.isNotEmpty
                      ? message
                      : 'Your booking has been created successfully. You can track it in Appointments.',
                  fontSize: FontSizes.small,
                  color: AppColor.grey,
                  align: TextAlign.center,
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.authButton,
                      foregroundColor: AppColor.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final modalRoute = ModalRoute.of(context);
    if (modalRoute is PageRoute) {
      AppRouter.routeObserver.subscribe(this, modalRoute);
    }
  }

  @override
  void didPopNext() {
    _refreshDashboardData();
  }

  @override
  void dispose() {
    AppRouter.routeObserver.unsubscribe(this);
    homeSuccessMessageNotifier.removeListener(_onSuccessMessage);
    homeTabNotifier.removeListener(_onTabChanged);
    _addressProvider.removeListener(_onAddressProviderChanged);
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: homeTabNotifier,
      builder: (context, currentIndex, _) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          if (currentIndex != 0) {
            homeTabNotifier.value = 0;
          } else {
            _showExitDialog();
          }
        },
        child: Scaffold(
        backgroundColor: AppColor.authBg,
        body: IndexedStack(
          
          index: currentIndex,
          children: [
            const _HomeTab(),
            const ExploreTab(),
            const MyBookingsTab(),
            const ConversationsTab(),
            const ProfileTab(),
          ],
        ),
        bottomNavigationBar: _buildBottomNav(currentIndex),
        ),
      ),
    );
  }



  Widget _buildBottomNav(int currentIndex) {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.white,
        border: Border(
          top: BorderSide(color: AppColor.lightGrey, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(_navItems.length, (index) {
              final item = _navItems[index];
              final isActive = currentIndex == index;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    final hasAddress = context.read<AddressProvider>().addresses.isNotEmpty;
                    if (!hasAddress && index == 1) {
                      _redirectToSavedAddresses();
                      FunctionalComponent.showSnackBar(
                        context: context,
                        title: 'Please add an address first',
                        success: false,
                      );
                      return;
                    }
                    homeTabNotifier.value = index;
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isActive ? item.activeIcon : item.icon,
                        size: 22,
                        color: isActive ? AppColor.authButton : AppColor.offtab,
                      ),
                      const SizedBox(height: 4),
                      AppText(
                        item.label,
                        fontSize: 10,
                        fontWeight: isActive ? FontWeights.semiBold : FontWeights.regular,
                        color: isActive ? AppColor.authButton : AppColor.offtab,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ─── Services tab ─────────────────────────────────────────────────────────────
class _ServicesTab extends StatefulWidget {

  const _ServicesTab();

  @override
  State<_ServicesTab> createState() => _ServicesTabState();
}

class _ServicesTabState extends State<_ServicesTab> {
  @override
  Widget build(BuildContext context) {

    return Consumer<CategoryProvider>(
      builder: (context, provider, _) {
        return RefreshIndicator(
          color: AppColor.authButton,
          onRefresh: () => provider.fetchCategories(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16,right: 16, top: 16),
                  child: Row(

                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 4,
                        child: Consumer<ProfileProvider>(
                          builder: (context, profileProvider, _) {
                            final name = profileProvider.profile?.name.trim();
                            final hasName = name != null && name.isNotEmpty;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AppText(
                                  'Welcome 👋',
                                  fontSize: 14,
                                  fontWeight: FontWeights.medium,
                                  color: AppColor.grey,
                                  maxLines: 1,
                                ),
                                AppText(
                                  hasName ? name : 'Guest',
                                  fontSize: FontSizes.large,
                                  fontWeight: FontWeights.medium,
                                  color: AppColor.authButton,
                                  maxLines: 1,
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 5,
                        child: _AddressStrip(
                          onTap: () {
                            FunctionalComponent.showAddressPickerSheet(
                              context: context,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              _buildBody(context, provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, CategoryProvider provider) {
    switch (provider.status) {
      case CategoryStatus.loading:
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (_, index) => const _CategoryCardShimmer(),
              childCount: 6,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1,
            ),
          ),
        );

      case CategoryStatus.error:
        return SliverFillRemaining(
          child: _ErrorView(
            message: provider.errorMessage,
            onRetry: () => provider.refresh(),
          ),
        );

      case CategoryStatus.empty:
        return const SliverFillRemaining(
          child: _EmptyView(),
        );

      case CategoryStatus.initial:
        return const SliverToBoxAdapter(child: SizedBox.shrink());

      case CategoryStatus.success:
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _CategoryCard(category: provider.categories[index]),
              childCount: provider.categories.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1,
            ),
          ),
        );
    }
  }
}

// ─── Category card ─────────────────────────────────────────────────────────────
class _CategoryCard extends StatelessWidget {
  final CategoryModel category;
  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    final iconUrl = category.icon?.trim();
    final hasIcon = iconUrl != null && iconUrl.isNotEmpty;

    return GestureDetector(
      onTap: () async {
        await context.push(
          RouteNames.services,
          extra: {'categoryId': category.id, 'categoryName': category.categoryName},
        );
        // Refresh when coming back from services/booking screens
        if (context.mounted) {
          final parentState = context.findAncestorStateOfType<_HomeScreenState>();
          parentState?._refreshDashboardData();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColor.authBg,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColor.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColor.authButton.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: hasIcon
                  ? ClipOval(
                      child: FunctionalComponent.cachedNetworkImage(
                        iconUrl,
                        radius: 32,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Icon(
                      _iconForCategory(category.categoryName),
                      size: 28,
                      color: AppColor.authButton,
                    ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: AppText(
                category.categoryName,
                fontSize: FontSizes.small,
                fontWeight: FontWeights.semiBold,
                color: AppColor.authButton,
                align: TextAlign.center,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shimmer placeholder ───────────────────────────────────────────────────────
class _CategoryCardShimmer extends StatefulWidget {
  const _CategoryCardShimmer();

  @override
  State<_CategoryCardShimmer> createState() => _CategoryCardShimmerState();
}

class _CategoryCardShimmerState extends State<_CategoryCardShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, _) => Opacity(
        opacity: _animation.value,
        child: Container(
          decoration: BoxDecoration(
            color: AppColor.authBg,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppColor.lightGrey,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                height: 12,
                width: 80,
                decoration: BoxDecoration(
                  color: AppColor.lightGrey,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Error view ────────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColor.authBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_off_rounded, size: 36, color: AppColor.authButton),
            ),
            const SizedBox(height: 20),
            AppText(
              'Something went wrong',
              fontSize: FontSizes.medium,
              fontWeight: FontWeights.semiBold,
              color: AppColor.darkGrey,
              align: TextAlign.center,
            ),
            const SizedBox(height: 8),
            AppText(
              message,
              fontSize: FontSizes.small,
              color: AppColor.grey,
              align: TextAlign.center,
              maxLines: 3,
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColor.authButton,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: AppText(
                  'Try Again',
                  fontSize: FontSizes.regular,
                  fontWeight: FontWeights.semiBold,
                  color: AppColor.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty view ────────────────────────────────────────────────────────────────
class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColor.authBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.spa_outlined, size: 36, color: AppColor.authButton),
            ),
            const SizedBox(height: 20),
            AppText(
              'No Services Available',
              fontSize: FontSizes.medium,
              fontWeight: FontWeights.semiBold,
              color: AppColor.darkGrey,
            ),
            const SizedBox(height: 8),
            AppText(
              'Check back soon for available services.',
              fontSize: FontSizes.small,
              color: AppColor.grey,
              align: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Address picker sheet ─────────────────────────────────────────────────────
class AddressPickerSheet extends StatefulWidget {
  const AddressPickerSheet({super.key});

  @override
  State<AddressPickerSheet> createState() => AddressPickerSheetState();
}

class AddressPickerSheetState extends State<AddressPickerSheet> {
  bool _showAddForm = false;
  AddressModel? _editingAddress;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColor.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: _editingAddress != null
            ? _EditAddressForm(
                address: _editingAddress!,
                onBack: () => setState(() => _editingAddress = null),
                onSaved: () => setState(() => _editingAddress = null),
              )
            : _showAddForm
                ? _AddAddressForm(
                    onBack: () => setState(() => _showAddForm = false),
                    onSaved: () => setState(() => _showAddForm = false),
                  )
                : _AddressList(
                    onAddNew: () => setState(() => _showAddForm = true),
                    onEdit: (addr) => setState(() => _editingAddress = addr),
                  ),
      ),
    );
  }
}

// ─── Address list inside sheet ────────────────────────────────────────────────
class _AddressList extends StatelessWidget {
  final VoidCallback onAddNew;
  final void Function(AddressModel) onEdit;
  const _AddressList({required this.onAddNew, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Consumer<AddressProvider>(
      builder: (_, provider, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColor.mediumGrey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                AppText('Your Addresses',
                    fontSize: FontSizes.medium,
                    fontWeight: FontWeights.bold,
                    color: AppColor.darkGrey),
                const Spacer(),
                GestureDetector(
                  onTap: onAddNew,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColor.authBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.add_rounded,
                            color: AppColor.authButton, size: 16),
                        const SizedBox(width: 4),
                        AppText('Add New',
                            fontSize: 12,
                            fontWeight: FontWeights.semiBold,
                            color: AppColor.authButton),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (provider.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: CircularProgressIndicator(color: AppColor.authButton),
                ),
              )
            else if (provider.addresses.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          color: AppColor.authBg,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.location_off_outlined,
                            color: AppColor.authButton, size: 26),
                      ),
                      const SizedBox(height: 12),
                      AppText('No addresses yet',
                          fontSize: FontSizes.regular,
                          fontWeight: FontWeights.semiBold,
                          color: AppColor.darkGrey),
                      const SizedBox(height: 4),
                      AppText('Add an address to get started',
                          fontSize: FontSizes.small, color: AppColor.grey),
                    ],
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.45,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: provider.addresses.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, color: Color(0xFFF0F0F0)),
                  itemBuilder: (_, i) {
                    final addr = provider.addresses[i];
                    final isSelected =
                        provider.selectedAddress?.id == addr.id;
                    return Container(
                      color: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          // ── Tap to select ────────────────────────────
                          GestureDetector(
                            onTap: () {
                              provider.selectAddress(addr);
                              Navigator.of(context).pop();
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              color: Colors.transparent,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColor.authButton
                                      : AppColor.authBg,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.location_on_rounded,
                                  color: isSelected
                                      ? AppColor.white
                                      : AppColor.authButton,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // ── Address info ─────────────────────────────
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                provider.selectAddress(addr);
                                Navigator.of(context).pop();
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: AppText(
                                          addr.addressName,
                                          fontSize: FontSizes.regular,
                                          fontWeight: FontWeights.semiBold,
                                          color: AppColor.darkGrey,
                                        ),
                                      ),
                                      if (addr.isDefault)
                                        Container(
                                          margin: const EdgeInsets.only(left: 6),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColor.authBg,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: AppText('Default',
                                              fontSize: 9,
                                              fontWeight: FontWeights.semiBold,
                                              color: AppColor.authButton),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  AppText(
                                    '${addr.streetAddress}, ${addr.city} ${addr.zipCode}',
                                    fontSize: 12,
                                    color: AppColor.grey,
                                    maxLines: 1,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // ── Selected check ────────────────────────────
                          if (isSelected)
                            Container(
                              width: 24,
                              height: 24,
                              margin: const EdgeInsets.only(right: 4),
                              decoration: const BoxDecoration(
                                color: AppColor.authButton,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check_rounded,
                                  color: AppColor.white, size: 14),
                            ),
                          // ── Actions menu ──────────────────────────────
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert_rounded,
                                size: 20, color: AppColor.grey),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            onSelected: (value) async {
                              if (value == 'default') {
                                final ok =
                                    await provider.setDefaultAddress(addr.id);
                                if (context.mounted) {
                                  FunctionalComponent.showSnackBar(
                                    context: context,
                                    title: ok
                                        ? 'Default address updated'
                                        : provider.saveError,
                                    success: ok,
                                  );
                                }
                              } else if (value == 'edit') {
                                onEdit(addr);
                              } else if (value == 'delete') {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16)),
                                    title: const Text('Delete Address'),
                                    content: Text(
                                        'Remove "${addr.addressName}"?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: const Text('Delete',
                                            style: TextStyle(
                                                color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true && context.mounted) {
                                  final ok = await provider
                                      .deleteAddress(addr.id);
                                  if (context.mounted) {
                                    FunctionalComponent.showSnackBar(
                                      context: context,
                                      title: ok
                                          ? 'Address deleted'
                                          : provider.deleteError,
                                      success: ok,
                                    );
                                    provider.resetDelete();
                                  }
                                }
                              }
                            },
                            itemBuilder: (_) => [
                              if (!addr.isDefault)
                                const PopupMenuItem(
                                  value: 'default',
                                  child: Row(children: [
                                    Icon(Icons.star_outline_rounded,
                                        size: 18),
                                    SizedBox(width: 10),
                                    Text('Set as Default'),
                                  ]),
                                ),
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(children: [
                                  Icon(Icons.edit_outlined, size: 18),
                                  SizedBox(width: 10),
                                  Text('Edit'),
                                ]),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(children: [
                                  Icon(Icons.delete_outline_rounded,
                                      size: 18, color: Colors.red),
                                  SizedBox(width: 10),
                                  Text('Delete',
                                      style: TextStyle(color: Colors.red)),
                                ]),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

// ─── Add address form inside sheet ────────────────────────────────────────────
class _AddAddressForm extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onSaved;
  const _AddAddressForm({required this.onBack, required this.onSaved});

  @override
  State<_AddAddressForm> createState() => _AddAddressFormState();
}

class _AddAddressFormState extends State<_AddAddressForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _zipCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    final savedZip = StorageManager.readData(StoreKeys.zipCode) as String?;
    if (savedZip != null && savedZip.isNotEmpty) _zipCtrl.text = savedZip;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _streetCtrl.dispose();
    _zipCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    debugPrint("HomeScreen: _useCurrentLocation called");
    setState(() => _isLocating = true);
    try {
      final res = await context.read<AddressProvider>().findMyLocation();
      debugPrint("HomeScreen: findMyLocation result = $res");
      if (res != null) {
        setState(() {
          _streetCtrl.text = res['streetAddress'] ?? '';
          _cityCtrl.text = res['city'] ?? '';
          _zipCtrl.text = res['zipCode'] ?? '';
          if (_nameCtrl.text.isEmpty) {
            _nameCtrl.text = 'Home';
          }
        });
      }
    } catch (e) {
      debugPrint("HomeScreen: error in _useCurrentLocation = $e");
      if (mounted) {
        FunctionalComponent.showSnackBar(
          context: context,
          title: e.toString().replaceFirst('Exception: ', ''),
          success: false,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }

  Future<void> _selectAddressFromSearch(BuildContext context) async {
    final result = await Navigator.of(context).push<Map<String, String>>(
      MaterialPageRoute(
        builder: (_) => const AddressSearchScreen(),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _streetCtrl.text = result['streetAddress'] ?? '';
        _cityCtrl.text = result['city'] ?? '';
        _zipCtrl.text = result['zipCode'] ?? '';
        if (_nameCtrl.text.isEmpty) {
          _nameCtrl.text = 'Home';
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<AddressProvider>();
    final success = await provider.storeAddress(
      addressName: _nameCtrl.text.trim(),
      streetAddress: _streetCtrl.text.trim(),
      zipCode: _zipCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
    );
    if (!mounted) return;
    if (success) {
      widget.onSaved();
      FunctionalComponent.showSnackBar(
        context: context,
        title: 'Address saved!',
        success: true,
      );
    } else {
      FunctionalComponent.showSnackBar(
        context: context,
        title: provider.saveError,
        success: false,
      );
      provider.resetSave();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColor.mediumGrey,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            GestureDetector(
              onTap: widget.onBack,
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColor.authBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: AppColor.authButton, size: 14),
              ),
            ),
            const SizedBox(width: 12),
            AppText('Add New Address',
                fontSize: FontSizes.medium,
                fontWeight: FontWeights.bold,
                color: AppColor.darkGrey),
            const Spacer(),
            // Find My Location button
            GestureDetector(
              onTap: _isLocating ? null : _useCurrentLocation,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColor.authButton.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _isLocating
                        ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              color: AppColor.authButton,
                              strokeWidth: 1.5,
                            ),
                          )
                        : const Icon(
                            Icons.my_location_rounded,
                            color: AppColor.authButton,
                            size: 12,
                          ),
                    const SizedBox(width: 6),
                    AppText(
                      _isLocating ? 'Locating...' : 'Find my location',
                      fontSize: 11,
                      fontWeight: FontWeights.semiBold,
                      color: AppColor.authButton,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Form(
          key: _formKey,
          child: Column(
            children: [
              _HomeAddressField(
                controller: _nameCtrl,
                label: 'Address Label',
                hint: 'e.g. Home, Work',
                icon: Icons.home_outlined,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              _HomeAddressField(
                controller: _streetCtrl,
                label: 'Street Address',
                hint: 'Tap to search address',
                icon: Icons.signpost_outlined,
                readOnly: true,
                onTap: () => _selectAddressFromSearch(context),
                suffixIcon: TextButton(
                  onPressed: () => _selectAddressFromSearch(context),
                  child: Text(
                    _streetCtrl.text.isEmpty ? 'Search' : 'Change',
                    style: const TextStyle(
                      color: AppColor.authButton,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _HomeAddressField(
                      controller: _zipCtrl,
                      label: 'ZIP Code',
                      hint: '382350',
                      icon: Icons.pin_drop_outlined,
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _HomeAddressField(
                      controller: _cityCtrl,
                      label: 'City',
                      hint: 'Ahmedabad',
                      icon: Icons.location_city_outlined,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Consumer<AddressProvider>(
          builder: (_, provider, _) {
            return SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.authButton,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: provider.isSaving ? null : _submit,
                child: provider.isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: AppColor.white, strokeWidth: 2.5),
                      )
                    : AppText('Save Address',
                        fontSize: FontSizes.regular,
                        fontWeight: FontWeights.semiBold,
                        color: AppColor.white),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _HomeAddressField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final void Function(String)? onChanged;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? suffixIcon;

  const _HomeAddressField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.readOnly = false,
    this.onTap,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      readOnly: readOnly,
      onTap: onTap,
      style: const TextStyle(fontSize: 14, color: AppColor.darkGrey),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: AppColor.grey),
        suffixIcon: suffixIcon,
        labelStyle: const TextStyle(fontSize: 13, color: AppColor.grey),
        hintStyle: const TextStyle(fontSize: 13, color: AppColor.mediumGrey),
        filled: true,
        fillColor: const Color(0xFFF8F8F8),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColor.lightGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColor.lightGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColor.authButton, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
    );
  }
}

// ─── Address strip in app bar ──────────────────────────────────────────────────
class _AddressStrip extends StatelessWidget {
  final VoidCallback onTap;
  const _AddressStrip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Consumer<AddressProvider>(
      builder: (_, provider, _) {
        final addr = provider.selectedAddress;
        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColor.authBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_rounded,
                    color: AppColor.authButton, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: provider.isLoading
                      ? Container(
                          height: 12,
                          width: 120,
                          decoration: BoxDecoration(
                            color: AppColor.mediumGrey.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        )
                      : addr == null
                          ? AppText('Tap to select an address',
                              fontSize: 12, color: AppColor.grey)
                          : AppText(
                              '${addr.addressName}  ·  ${addr.streetAddress}, ${addr.city}',
                              fontSize: 12,
                              fontWeight: FontWeights.medium,
                              color: AppColor.authButton,
                              maxLines: 1,
                            ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down_rounded,
                    color: AppColor.authButton, size: 18),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Edit address form inside sheet ───────────────────────────────────────────
class _EditAddressForm extends StatefulWidget {
  final AddressModel address;
  final VoidCallback onBack;
  final VoidCallback onSaved;
  const _EditAddressForm(
      {required this.address, required this.onBack, required this.onSaved});

  @override
  State<_EditAddressForm> createState() => _EditAddressFormState();
}

class _EditAddressFormState extends State<_EditAddressForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _streetCtrl;
  late final TextEditingController _zipCtrl;
  late final TextEditingController _cityCtrl;
  late bool _isDefault;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.address.addressName);
    _streetCtrl = TextEditingController(text: widget.address.streetAddress);
    _zipCtrl = TextEditingController(text: widget.address.zipCode);
    _cityCtrl = TextEditingController(text: widget.address.city);
    _isDefault = widget.address.isDefault;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _streetCtrl.dispose();
    _zipCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<AddressProvider>();
    final success = await provider.updateAddress(
      id: widget.address.id,
      addressName: _nameCtrl.text.trim(),
      streetAddress: _streetCtrl.text.trim(),
      zipCode: _zipCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      isDefault: _isDefault,
    );
    if (!mounted) return;
    if (success) {
      widget.onSaved();
      FunctionalComponent.showSnackBar(
        context: context,
        title: 'Address updated!',
        success: true,
      );
    } else {
      FunctionalComponent.showSnackBar(
        context: context,
        title: provider.saveError,
        success: false,
      );
      provider.resetSave();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColor.mediumGrey,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            GestureDetector(
              onTap: widget.onBack,
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColor.authBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: AppColor.authButton, size: 14),
              ),
            ),
            const SizedBox(width: 12),
            AppText('Edit Address',
                fontSize: FontSizes.medium,
                fontWeight: FontWeights.bold,
                color: AppColor.darkGrey),
          ],
        ),
        const SizedBox(height: 20),
        Form(
          key: _formKey,
          child: Column(
            children: [
              _HomeAddressField(
                controller: _nameCtrl,
                label: 'Full Address',
                hint: 'e.g. 44/Otamba Society, Bapunagar',
                icon: Icons.home_outlined,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              _HomeAddressField(
                controller: _streetCtrl,
                label: 'Street / House No.',
                hint: 'e.g. 33',
                icon: Icons.signpost_outlined,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _HomeAddressField(
                      controller: _zipCtrl,
                      label: 'ZIP Code',
                      hint: '382350',
                      icon: Icons.pin_drop_outlined,
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _HomeAddressField(
                      controller: _cityCtrl,
                      label: 'City',
                      hint: 'Ahmedabad',
                      icon: Icons.location_city_outlined,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // ── Set as default toggle ──────────────────────────────────────
        GestureDetector(
          onTap: () => setState(() => _isDefault = !_isDefault),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _isDefault ? AppColor.authBg : const Color(0xFFF8F8F8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isDefault ? AppColor.authButton : AppColor.lightGrey,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isDefault ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: AppColor.authButton,
                  size: 18,
                ),
                const SizedBox(width: 10),
                AppText(
                  'Set as default address',
                  fontSize: FontSizes.small,
                  fontWeight: FontWeights.medium,
                  color: AppColor.darkGrey,
                ),
                const Spacer(),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: _isDefault ? AppColor.authButton : AppColor.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isDefault
                          ? AppColor.authButton
                          : AppColor.mediumGrey,
                    ),
                  ),
                  child: _isDefault
                      ? const Icon(Icons.check_rounded,
                          color: AppColor.white, size: 13)
                      : null,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Consumer<AddressProvider>(
          builder: (_, provider, _) {
            return SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.authButton,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: provider.isSaving ? null : _submit,
                child: provider.isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: AppColor.white, strokeWidth: 2.5),
                      )
                    : AppText('Update Address',
                        fontSize: FontSizes.regular,
                        fontWeight: FontWeights.semiBold,
                        color: AppColor.white),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ─── Home tab ──────────────────────────────────────────────────────────────────
class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.authBg,
      body: RefreshIndicator(
        color: AppColor.authButton,
        onRefresh: () => context.read<MyBookingsProvider>().fetchBookings(),
        child: CustomScrollView(
          
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _HomeHeader()),
            SliverToBoxAdapter(child: _BookNewServiceButton()),
            SliverToBoxAdapter(child: _UpcomingSection()),
            SliverToBoxAdapter(child: _PastServicesSection()),
            SliverToBoxAdapter(child: _QuickLinksSection()),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Row(
          children: [
            Expanded(
              child: Consumer<ProfileProvider>(
                builder: (_, p, _) {
                  final firstName = p.profile?.name.trim().split(' ').first ?? '';
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        'Welcome back${firstName.isNotEmpty ? ', $firstName' : ''}',
                        fontSize: FontSizes.extraLarge,
                        fontWeight: FontWeights.bold,
                        color: AppColor.darkGrey,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 4),
                      AppText(
                        'Beauty & wellness, wherever you are',
                        fontSize: FontSizes.regular,
                        fontWeight: FontWeights.regular,
                        color: AppColor.grey,
                        maxLines: 1,
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => homeTabNotifier.value = 4,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColor.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColor.mediumGrey, width: 1),
                ),
                child: const Icon(Icons.person_outline_rounded, color: AppColor.authButton, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookNewServiceButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: GestureDetector(
        onTap: () {
          final hasAddress = context.read<AddressProvider>().addresses.isNotEmpty;
          if (!hasAddress) {
            final parentState = context.findAncestorStateOfType<_HomeScreenState>();
            if (parentState != null) {
              parentState._redirectToSavedAddresses();
            } else {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SavedAddressesScreen()),
              );
            }
            FunctionalComponent.showSnackBar(
              context: context,
              title: 'Please add an address first',
              success: false,
            );
            return;
          }
          context.push(RouteNames.categoryList);
        },
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: AppColor.authButton,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColor.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add_rounded, color: AppColor.white, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: AppText(
                  'Book a new service',
                  fontSize: FontSizes.regular,
                  fontWeight: FontWeights.semiBold,
                  color: AppColor.white,
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: AppColor.white, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpcomingSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<MyBookingsProvider>(
      builder: (_, provider, _) {
        final upcoming = provider.upcomingBookings
            .where((b) => b.isPending || b.isConfirmed)
            .toList();

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppText(
                    'Upcoming',
                    fontSize: FontSizes.medium,
                    fontWeight: FontWeights.bold,
                    color: AppColor.darkGrey,
                  ),
                  if (upcoming.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColor.authButton.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: AppText(
                        '${upcoming.length} appointment${upcoming.length != 1 ? 's' : ''}',
                        fontSize: FontSizes.mini,
                        fontWeight: FontWeights.semiBold,
                        color: AppColor.authButton,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              if (provider.status == MyBookingsFetchStatus.loading)
                const _HomeBookingShimmer()
              else if (upcoming.isEmpty)
                _HomeEmptyCard(
                  icon: Icons.calendar_today_outlined,
                  message: 'No upcoming appointments',
                  sub: 'Book a service to get started',
                )
              else ...[
                ...upcoming.take(5).map((b) => _UpcomingBookingCard(booking: b)),
                if (upcoming.length >= 5)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: GestureDetector(
                      onTap: () => homeTabNotifier.value = 2,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColor.authButton.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColor.authButton.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AppText(
                              'View All Appointments',
                              fontSize: FontSizes.regular,
                              fontWeight: FontWeights.semiBold,
                              color: AppColor.authButton,
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: AppColor.authButton,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _PastServicesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<MyBookingsProvider>(
      builder: (_, provider, _) {
        final past = provider.pastBookings;

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppText(
                    'Past Services',
                    fontSize: FontSizes.medium,
                    fontWeight: FontWeights.bold,
                    color: AppColor.darkGrey,
                  ),
                  if (past.isNotEmpty)
                    GestureDetector(
                      onTap: () => homeTabNotifier.value = 2,
                      child: AppText(
                        'View all',
                        fontSize: FontSizes.small,
                        fontWeight: FontWeights.semiBold,
                        color: AppColor.authButton,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              if (provider.status == MyBookingsFetchStatus.loading)
                const _HomeBookingShimmer()
              else if (past.isEmpty)
                _HomeEmptyCard(
                  icon: Icons.history_rounded,
                  message: 'No past services',
                  sub: 'Completed bookings will appear here',
                )
              else
                ...past.take(2).map((b) => _PastBookingCard(booking: b)),
            ],
          ),
        );
      },
    );
  }
}

class _QuickLinksSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            'Quick Links',
            fontSize: FontSizes.medium,
            fontWeight: FontWeights.bold,
            color: AppColor.darkGrey,
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: AppColor.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _QuickLinkTile(
                  icon: Icons.person_outline_rounded,
                  label: 'Profile Settings',
                  onTap: () => homeTabNotifier.value = 4,
                ),
                Divider(height: 1, color: AppColor.lightGrey, indent: 56),
                _QuickLinkTile(
                  icon: Icons.tune_rounded,
                  label: 'Preferences',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const BeautyPreferencesScreen(),
                  )),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickLinkTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickLinkTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColor.authButton.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: AppColor.authButton),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: AppText(
                label,
                fontSize: FontSizes.regular,
                fontWeight: FontWeights.medium,
                color: AppColor.darkGrey,
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColor.grey),
          ],
        ),
      ),
    );
  }
}

class _UpcomingBookingCard extends StatelessWidget {
  final MyBookingModel booking;
  const _UpcomingBookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final imageUrl = "${ApiStrings.imageUrl}${booking.service.image.trim()}";
    final hasImage = imageUrl.isNotEmpty;
    final dateStr = DateFormat('yyyy-MM-dd').format(booking.appointmentDate);
    final location = booking.provider?.displayLocation;

    return GestureDetector(
      onTap: () => context.push(RouteNames.myBookingDetail, extra: booking.id),
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 60,
              height: 60,
              child: hasImage
                  ? FunctionalComponent.cachedNetworkImage(imageUrl, radius: 12, fit: BoxFit.cover)
                  : Container(
                      color: AppColor.authBg,
                      child: const Icon(Icons.spa_rounded, color: AppColor.authButton, size: 28),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: AppText(
                        booking.service.serviceName,
                        fontSize: FontSizes.regular,
                        fontWeight: FontWeights.semiBold,
                        color: AppColor.darkGrey,
                        maxLines: 1,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColor.authButton.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: AppText(
                        '\$${booking.price.toStringAsFixed(0)}',
                        fontSize: FontSizes.small,
                        fontWeight: FontWeights.bold,
                        color: AppColor.authButton,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                AppText(
                  'with ${booking.provider?.displayName}',
                  fontSize: FontSizes.small,
                  color: AppColor.grey,
                  maxLines: 1,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 12, color: AppColor.grey),
                    const SizedBox(width: 4),
                    AppText(dateStr, fontSize: FontSizes.mini, color: AppColor.grey),
                    const SizedBox(width: 12),
                    const Icon(Icons.access_time_rounded, size: 12, color: AppColor.grey),
                    const SizedBox(width: 4),
                    AppText(booking.appointmentTime, fontSize: FontSizes.mini, color: AppColor.grey),
                  ],
                ),
                if ([location??[]].isNotEmpty && location != 'Location not set') ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 12, color: AppColor.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: AppText(location??'', fontSize: FontSizes.mini, color: AppColor.grey, maxLines: 1),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ));
  }
}

class _PastBookingCard extends StatelessWidget {
  final MyBookingModel booking;
  const _PastBookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final imageUrl = booking.service.image.trim();
    final hasImage = imageUrl.isNotEmpty;
    final dateStr = DateFormat('yyyy-MM-dd').format(booking.appointmentDate);
    final rating = booking.provider?.rating;

    return GestureDetector(
      onTap: () => context.push(RouteNames.myBookingDetail, extra: booking.id),
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: hasImage
                      ? FunctionalComponent.cachedNetworkImage(imageUrl, radius: 12, fit: BoxFit.cover)
                      : Container(
                          color: AppColor.authBg,
                          child: const Icon(Icons.spa_rounded, color: AppColor.authButton, size: 24),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: AppText(
                            booking.service.serviceName,
                            fontSize: FontSizes.regular,
                            fontWeight: FontWeights.semiBold,
                            color: AppColor.darkGrey,
                            maxLines: 1,
                          ),
                        ),
                        if ((rating??0) > 0) ...[
                          const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                          const SizedBox(width: 2),
                          AppText(
                            (rating??0).toStringAsFixed(0),
                            fontSize: FontSizes.small,
                            fontWeight: FontWeights.semiBold,
                            color: AppColor.darkGrey,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    AppText(booking.provider?.displayName??'', fontSize: FontSizes.small, color: AppColor.grey),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        AppText(dateStr, fontSize: FontSizes.mini, color: AppColor.grey),
                        const SizedBox(width: 8),
                        const Text('•', style: TextStyle(color: AppColor.grey, fontSize: 10)),
                        const SizedBox(width: 8),
                        AppText(booking.appointmentTime, fontSize: FontSizes.mini, color: AppColor.grey),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.push(RouteNames.bookingDetail, extra: booking.serviceId),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColor.mediumGrey),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: AppText('Book Again', fontSize: FontSizes.small, fontWeight: FontWeights.semiBold, color: AppColor.darkGrey),
                ),
              ),
            ],
          ),
        ],
      ),
    ));
  }
}

class _HomeEmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final String sub;
  const _HomeEmptyCard({required this.icon, required this.message, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: AppColor.mediumGrey),
          const SizedBox(height: 10),
          AppText(message, fontSize: FontSizes.regular, fontWeight: FontWeights.semiBold, color: AppColor.grey, align: TextAlign.center),
          const SizedBox(height: 4),
          AppText(sub, fontSize: FontSizes.small, color: AppColor.mediumGrey, align: TextAlign.center, maxLines: 2),
        ],
      ),
    );
  }
}

class _HomeBookingShimmer extends StatelessWidget {
  const _HomeBookingShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

// ─── Placeholder tabs ──────────────────────────────────────────────────────────
class _PlaceholderTab extends StatefulWidget {
  final IconData icon;
  final String label;
  const _PlaceholderTab({required this.icon, required this.label});

  @override
  State<_PlaceholderTab> createState() => _PlaceholderTabState();
}

class _PlaceholderTabState extends State<_PlaceholderTab> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.icon, size: 48, color: AppColor.authBg),
          const SizedBox(height: 12),
          AppText(widget.label, fontSize: FontSizes.medium, color: AppColor.grey),
        ],
      ),
    );
  }
}
