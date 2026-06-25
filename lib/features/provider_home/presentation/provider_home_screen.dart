import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pampa/core/routes/pages.dart';
import 'package:provider/provider.dart';

import 'package:pampa/core/routes/routes.dart';
import 'package:pampa/core/utils/functional_component.dart';
import 'package:pampa/core/values/app_text_value.dart';
import 'package:pampa/core/values/colors.dart';
import 'package:pampa/core/widgets/text_widget.dart';
import 'package:pampa/core/services/push_notification_service.dart';
import 'package:pampa/data/service/di.dart';
import 'package:pampa/features/auth/presentation/provider/auth_provider.dart';
import 'package:pampa/features/provider_home/data/models/provider_dashboard_model.dart';
import 'package:pampa/features/provider_home/presentation/provider/provider_dashboard_provider.dart';
import 'package:pampa/features/provider_home/presentation/provider/provider_bookings_provider.dart';
import 'package:pampa/features/provider_home/presentation/provider/provider_messaging_provider.dart';
import 'package:pampa/features/provider_home/presentation/provider_booking_detail_screen.dart';
import 'package:pampa/features/provider_home/presentation/provider_bookings_tab.dart';
import 'package:pampa/features/provider_home/presentation/provider_conversations_tab.dart';
import 'package:pampa/features/provider_home/presentation/provider_earnings_tab.dart';
import 'package:pampa/features/provider_home/presentation/provider/provider_earnings_provider.dart';
import 'package:pampa/features/provider_home/presentation/provider_profile_tab.dart';
import 'package:pampa/features/provider_home/presentation/provider_settings_screen.dart';
import 'package:pampa/features/provider_home/presentation/unavailability_bottom_sheet.dart';
import 'package:pampa/features/home/presentation/home_screen.dart';

// ─── Tab switcher notifier ────────────────────────────────────────────────────
final providerHomeTabNotifier = ValueNotifier<int>(0);

class ProviderHomeScreen extends StatefulWidget {
  const ProviderHomeScreen({super.key});

  @override
  State<ProviderHomeScreen> createState() => _ProviderHomeScreenState();
}

class _ProviderHomeScreenState extends State<ProviderHomeScreen> with RouteAware {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    providerHomeTabNotifier.addListener(_onTabNavigated);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAllData();
      getIt<PushNotificationService>().syncTokenWithBackend();
    });
  }

  void _onTabNavigated() {
    if (mounted) {
      final i = providerHomeTabNotifier.value;
      if (i == 1) {
        getIt<ProviderBookingsProvider>().resetAndFetch();
      }
      if (i == 2) {
        getIt<ProviderEarningsProvider>().fetchEarnings();
      }
      if (i == 3) {
        getIt<ProviderMessagingProvider>().refreshConversations();
      }
      setState(() {}); // Tab index managed by ValueListenableBuilder below
    }
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
  void dispose() {
    AppRouter.routeObserver.unsubscribe(this);
    providerHomeTabNotifier.removeListener(_onTabNavigated);
    super.dispose();
  }

  @override
  void didPopNext() {
    _refreshAllData();
  }

  void _refreshAllData() {
    if (!mounted) return;
    // Refresh the currently active tab's data
    getIt<ProviderDashboardProvider>().fetchDashboard();
    getIt<ProviderDashboardProvider>().fetchVacations();
    getIt<ProviderBookingsProvider>().fetch();
    getIt<ProviderEarningsProvider>().fetchEarnings();
    getIt<ProviderMessagingProvider>().refreshConversations();
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

  static const _navItems = [
    _NavItem(icon: Icons.grid_view_rounded, label: 'Home'),
    _NavItem(icon: Icons.calendar_month_rounded, label: 'Booking'),
    _NavItem(icon: Icons.account_balance_wallet_rounded, label: 'Earnings'),
    _NavItem(icon: Icons.chat_bubble_outline_rounded, label: 'Chat'),
    _NavItem(icon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: getIt<ProviderDashboardProvider>()),
        ChangeNotifierProvider.value(value: getIt<ProviderBookingsProvider>()),
        ChangeNotifierProvider.value(value: getIt<ProviderMessagingProvider>()),
        ChangeNotifierProvider.value(value: getIt<ProviderEarningsProvider>()),
      ],
      child: ValueListenableBuilder<int>(
        valueListenable: providerHomeTabNotifier,
        builder: (context, currentIndex, _) => PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            if (currentIndex != 0) {
              providerHomeTabNotifier.value = 0;
            } else {
              _showExitDialog();
            }
          },
          child: Scaffold(
            backgroundColor: const Color(0xFFF5F5F7),
            body: IndexedStack(
              index: currentIndex,
              children: [
                const _DashboardTab(),
                const ProviderBookingsTab(),
                const ProviderEarningsTab(),
                const ProviderConversationsTab(),
                const ProviderProfileTab(),
              ],
            ),
            bottomNavigationBar: _ProviderBottomNav(
              currentIndex: currentIndex,
              items: _navItems,
              onTap: (i) => providerHomeTabNotifier.value = i,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Bottom Nav ───────────────────────────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

class _ProviderBottomNav extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;

  const _ProviderBottomNav({
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(items.length, (i) {
              final item = items[i];
              final isActive = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item.icon,
                        size: 22,
                        color: isActive
                            ? AppColor.authButton
                            : AppColor.grey,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isActive
                              ? AppColor.authButton
                              : AppColor.grey,
                        ),
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

// ─── Dashboard Tab ────────────────────────────────────────────────────────────

class _DashboardTab extends StatefulWidget {
  const _DashboardTab();

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProviderDashboardProvider>().fetchDashboard();
      context.read<ProviderDashboardProvider>().fetchVacations();
    });
  }

  void _showOfflineBottomSheet(
    BuildContext context,
    ProviderDashboardProvider dashProv,
  ) {
    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => UnavailabilityBottomSheet(
        title: 'Go Offline',
        existingVacations: dashProv.vacations,
        onConfirm: (endDate, startDate) async {
          return await dashProv.toggleOnline(
            endDate: endDate,
            startDate: startDate,
          );
        },
      ),
    ).then((message) {
      if (message != null && context.mounted) {
        FunctionalComponent.showSnackBar(
          context: context,
          title: message,
          success: true,
        );
      }
    });
  }

  void _showVacationsBottomSheet(
    BuildContext context,
    ProviderDashboardProvider prov,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (dialogContext) {
        return ChangeNotifierProvider.value(
          value: prov,
          child: _VacationsBottomSheet(
            onAddVacation: () {
              _showOfflineBottomSheet(context, prov);
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProviderDashboardProvider>(
      builder: (context, dashProv, _) {
        return RefreshIndicator(
          onRefresh: () async {
            await dashProv.fetchDashboard();
            await dashProv.fetchVacations();
          },
          color: AppColor.authButton,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── App Bar ───────────────────────────────────────────────────
            SliverAppBar(
              pinned: true,
              backgroundColor: AppColor.white,
              surfaceTintColor: AppColor.white,
              elevation: 0,
              shadowColor: Colors.black.withValues(alpha: 0.06),
              titleSpacing: 20,
              title: AppText(
                'Dashboard',
                fontSize: 20,
                fontWeight: FontWeights.bold,
                color: AppColor.darkGrey,
              ),
              actions: [
                IconButton(
                  icon: const Icon(
                    Icons.settings_outlined,
                    color: AppColor.darkGrey,
                    size: 22,
                  ),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChangeNotifierProvider.value(
                        value: getIt<ProviderDashboardProvider>(),
                        child: const ProviderSettingsScreen(),
                      ),
                    ),
                  ),
                ),
                // IconButton(
                //   icon: const Icon(Icons.notifications_none_rounded,
                //       color: AppColor.darkGrey, size: 24),
                //   onPressed: () {},
                // ),
                GestureDetector(
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        title: const Text('Sign Out'),
                        content: const Text('Are you sure you want to sign out?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text('Cancel',
                                style: TextStyle(color: AppColor.grey)),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Sign Out',
                                style: TextStyle(color: AppColor.authButton)),
                          ),
                        ],
                      ),
                    );
                    if (confirm != true || !context.mounted) return;
                    await context.read<AuthProvider>().logout();
                    // Reset customer home bottom bar selection so the next login is fresh.
                    homeTabNotifier.value = 0;
                    homeSuccessMessageNotifier.value = null;
                    if (context.mounted) context.go(RouteNames.login);
                  },
                  child: Container(
                    width: 34,
                    height: 34,
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: AppColor.authButton.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.logout_rounded,
                        size: 17, color: AppColor.authButton),
                  ),
                ),
              ],
            ),

            if (dashProv.loading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (dashProv.error.isNotEmpty && dashProv.dashboard == null)
              SliverFillRemaining(
                child: _ErrorView(
                  message: dashProv.error,
                  onRetry: () => dashProv.fetchDashboard(),
                ),
              )
            else if (dashProv.dashboard != null) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    children: [
                      // ── Online toggle card ──────────────────────────────
                       // ── Online toggle card ──────────────────────────────
                      _OnlineToggleCard(
                        isOnline: dashProv.isOnline,
                        offlineMessage: (dashProv.dashboard?.unavailableFrom == null || 
                                         dashProv.dashboard!.unavailableFrom!.isEmpty)
                            ? dashProv.dashboard?.offlineMessage 
                            : null, // Only show offlineMessage inside toggle card if there's no vacation scheduled
                        loading: dashProv.toggleLoading,
                        onToggle: () async {
                          if (dashProv.isOnline) {
                            _showOfflineBottomSheet(context, dashProv);
                          } else {
                            final result = await dashProv.toggleOnline();
                            if (!result.success && context.mounted) {
                              FunctionalComponent.showSnackBar(
                                context: context,
                                title: result.message,
                                success: false,
                              );
                            } else if (context.mounted) {
                              FunctionalComponent.showSnackBar(
                                context: context,
                                title: result.message,
                                success: true,
                              );
                            }
                          }
                        },
                      ),

                      // ── Scheduled vacation card ─────────────────────────
                      if (dashProv.vacations.isNotEmpty)
                        _ScheduledOfflineCard(
                          vacations: dashProv.vacations,
                          onTap: () => _showVacationsBottomSheet(context, dashProv),
                        ),
                      const SizedBox(height: 16),

                      // ── Pending Requests ────────────────────────────────
                      _SectionHeader(
                        title: 'Pending Requests',
                        badge: dashProv.dashboard!.pendingCount,
                      ),
                      const SizedBox(height: 10),
                      if (dashProv.dashboard!.pendingRequests.isEmpty)
                        _EmptyCard(label: 'No pending requests')
                      else
                        ...dashProv.dashboard!.pendingRequests
                            .map((b) => _BookingCard(booking: b, isPending: true)),
                      const SizedBox(height: 16),

                      // ── Upcoming Bookings ───────────────────────────────
                      const _SectionHeader(title: 'Upcoming Bookings'),
                      const SizedBox(height: 10),
                      if (dashProv.dashboard!.upcomingBookings.isEmpty)
                        _EmptyCard(label: 'No upcoming bookings')
                      else
                        ...dashProv.dashboard!.upcomingBookings
                            .map((b) => _BookingCard(booking: b, isPending: false)),
                      const SizedBox(height: 16),

                      // ── This Week's Earnings ────────────────────────────
                      _EarningsCard(earnings: dashProv.dashboard!.weeklyEarnings),
                      const SizedBox(height: 16),

                      // ── Rating Snapshot ─────────────────────────────────
                      _RatingCard(snapshot: dashProv.dashboard!.ratingSnapshot),
                      const SizedBox(height: 16),

                      // ── Service Mix ─────────────────────────────────────
                      if (dashProv.dashboard!.serviceMix.isNotEmpty) ...[
                        const _SectionHeader(title: 'Service Mix'),
                        const SizedBox(height: 10),
                        _ServiceMixCard(items: dashProv.dashboard!.serviceMix),
                        const SizedBox(height: 24),
                      ],
                    ],
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

// ─── Online Toggle Card ────────────────────────────────────────────────────────

class _OnlineToggleCard extends StatelessWidget {
  final bool isOnline;
  final String? offlineMessage;
  final bool loading;
  final VoidCallback onToggle;

  const _OnlineToggleCard({
    required this.isOnline,
    this.offlineMessage,
    required this.loading,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isOnline
            ? const Color(0xFFE8F5E9)
            : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOnline
              ? const Color(0xFF4CAF50).withValues(alpha: 0.3)
              : const Color(0xFFFF9800).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: isOnline
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFFF9800),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  isOnline ? 'You\'re Available' : 'You\'re Unavailable',
                  fontSize: FontSizes.regular,
                  fontWeight: FontWeights.semiBold,
                  color: AppColor.darkGrey,
                ),
                AppText(
                  isOnline
                      ? 'Accepting bookings'
                      : 'Not accepting bookings',
                  fontSize: 12,
                  color: AppColor.grey,
                ),
                if (offlineMessage != null && offlineMessage!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Icon(
                          Icons.info_outline_rounded,
                          size: 13,
                          color: isOnline
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFE65100),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: AppText(
                          offlineMessage!,
                          fontSize: 11,
                          color: isOnline
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFFD84315),
                          fontWeight: FontWeights.medium,
                          maxLines: 3,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          loading
              ? const Padding(
                  padding: EdgeInsets.only(top: 3),
                  child: SizedBox(
                    width: 36,
                    height: 22,
                    child: Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                )
              : Switch(
                  value: isOnline,
                  onChanged: (_) => onToggle(),
                  activeThumbColor: const Color(0xFF4CAF50),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
        ],
      ),
    );
  }
}

class _ScheduledOfflineCard extends StatelessWidget {
  final List<VacationModel> vacations;
  final VoidCallback onTap;

  const _ScheduledOfflineCard({
    required this.vacations,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (vacations.isEmpty) return const SizedBox.shrink();
    final firstVacation = vacations.first;
    String formattedRange = '';
    try {
      final fromDate = DateTime.tryParse(firstVacation.startDate);
      final toDate = DateTime.tryParse(firstVacation.endDate);
      final formatter = DateFormat('MMM dd, yyyy');
      if (fromDate != null && toDate != null) {
        formattedRange = '${formatter.format(fromDate)} - ${formatter.format(toDate)}';
      } else if (fromDate != null) {
        formattedRange = 'From ${formatter.format(fromDate)}';
      } else if (toDate != null) {
        formattedRange = 'Until ${formatter.format(toDate)}';
      }
    } catch (_) {
      formattedRange = '${firstVacation.startDate} - ${firstVacation.endDate}';
    }

    if (vacations.length > 1) {
      formattedRange += ' (+${vacations.length - 1} more)';
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColor.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: AppColor.authButton.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColor.authButton.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.beach_access_rounded,
                    color: AppColor.authButton,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        'Scheduled Time Off',
                        fontSize: FontSizes.regular,
                        fontWeight: FontWeights.bold,
                        color: AppColor.darkGrey,
                      ),
                      const SizedBox(height: 2),
                      AppText(
                        formattedRange,
                        fontSize: 12,
                        color: AppColor.grey,
                        fontWeight: FontWeights.medium,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppColor.grey,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VacationsBottomSheet extends StatelessWidget {
  final VoidCallback onAddVacation;

  const _VacationsBottomSheet({
    required this.onAddVacation,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ProviderDashboardProvider>(
      builder: (context, dashProv, _) {
        if (dashProv.vacations.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Navigator.of(context).canPop()) {
              Navigator.pop(context);
            }
          });
          return const SizedBox.shrink();
        }

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: EdgeInsets.only(
            top: 8,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppText(
                    'Scheduled Time Off',
                    fontSize: 18,
                    fontWeight: FontWeights.bold,
                    color: AppColor.darkGrey,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: dashProv.vacations.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, index) {
                    final vacation = dashProv.vacations[index];
                    String rangeStr = '';
                    try {
                      final fromDate = DateTime.tryParse(vacation.startDate);
                      final toDate = DateTime.tryParse(vacation.endDate);
                      final formatter = DateFormat('MMM dd, yyyy');
                      if (fromDate != null && toDate != null) {
                        rangeStr = '${formatter.format(fromDate)} - ${formatter.format(toDate)}';
                      } else {
                        rangeStr = '${vacation.startDate} - ${vacation.endDate}';
                      }
                    } catch (_) {
                      rangeStr = '${vacation.startDate} - ${vacation.endDate}';
                    }

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9F9FA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFF0E4E8),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColor.authButton.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.beach_access_rounded,
                              color: AppColor.authButton,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: AppText(
                              rangeStr,
                              fontSize: 13,
                              fontWeight: FontWeights.medium,
                              color: AppColor.darkGrey,
                            ),
                          ),
                          (dashProv.toggleLoading && dashProv.deletingVacationId == vacation.id)
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.red,
                                  ),
                                )
                              : IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (confirmCtx) => AlertDialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        title: const Text('Delete Vacation'),
                                        content: const Text(
                                            'Are you sure you want to delete this scheduled vacation period?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(confirmCtx, false),
                                            child: Text('Cancel', style: TextStyle(color: AppColor.grey)),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(confirmCtx, true),
                                            child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm != true) return;

                                    final result = await dashProv.deleteVacation(vacation.id);
                                    if (context.mounted) {
                                      FunctionalComponent.showSnackBar(
                                        context: context,
                                        title: result.message,
                                        success: result.success,
                                      );
                                    }
                                  },
                                ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onAddVacation();
                  },
                  icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                  label: const Text(
                    'Add Time Off',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.authButton,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final int? badge;

  const _SectionHeader({
    required this.title,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppText(
          title,
          fontSize: FontSizes.medium,
          fontWeight: FontWeights.bold,
          color: AppColor.darkGrey,
        ),
        if (badge != null && badge! > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: AppColor.authButton,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$badge',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
        const Spacer(),
      ],
    );
  }
}

// ─── Booking Card ──────────────────────────────────────────────────────────────

class _BookingCard extends StatelessWidget {
  final ProviderDashboardBooking booking;
  final bool isPending;

  const _BookingCard({required this.booking, required this.isPending});

  @override
  Widget build(BuildContext context) {
    final isToday = booking.formattedDate == 'Today';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(14),
        border: isToday && !isPending
            ? Border.all(color: AppColor.authButton.withValues(alpha: 0.5), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
            final didChange = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => ProviderBookingDetailScreen(
                  bookingId: booking.id,
                  initialStatus: booking.status,
                ),
              ),
            );
            if (didChange == true && context.mounted) {
              context.read<ProviderDashboardProvider>().fetchDashboard();
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Avatar
                _CustomerAvatar(
                  name: booking.displayName,
                  photoUrl: booking.customer.profileImage,
                ),
                const SizedBox(width: 12),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        booking.displayName,
                        fontSize: FontSizes.regular,
                        fontWeight: FontWeights.semiBold,
                        color: AppColor.darkGrey,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 3),
                      if (booking.services.isNotEmpty)
                        AppText(
                          booking.services.first.serviceName,
                          fontSize: 13,
                          color: AppColor.grey,
                          maxLines: 1,
                        ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          // Service pill
                          if (booking.services.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColor.authButton.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: AppText(
                                booking.services.first.serviceName,
                                fontSize: 10,
                                fontWeight: FontWeights.semiBold,
                                color: AppColor.authButton,
                                maxLines: 1,
                              ),
                            ),
                          const SizedBox(width: 8),
                          const Icon(Icons.calendar_today_rounded,
                              size: 11, color: AppColor.grey),
                          const SizedBox(width: 3),
                          AppText(
                            booking.formattedDate,
                            fontSize: 11,
                            color: AppColor.grey,
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.access_time_rounded,
                              size: 11, color: AppColor.grey),
                          const SizedBox(width: 3),
                          AppText(
                            booking.formattedTime,
                            fontSize: 11,
                            color: AppColor.grey,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Icon(Icons.chevron_right_rounded,
                    color: AppColor.mediumGrey, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomerAvatar extends StatelessWidget {
  final String name;
  final String? photoUrl;

  const _CustomerAvatar({required this.name, this.photoUrl});

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return ClipOval(
        child: SizedBox(
          width: 44,
          height: 44,
          child: FunctionalComponent.cachedNetworkImage(
            photoUrl!,
            fit: BoxFit.cover,
            radius: 22,
          ),
        ),
      );
    }
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColor.authButton.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColor.authButton,
        ),
      ),
    );
  }
}

// ─── Earnings Card ─────────────────────────────────────────────────────────────

class _EarningsCard extends StatelessWidget {
  final WeeklyEarnings earnings;

  const _EarningsCard({required this.earnings});

  @override
  Widget build(BuildContext context) {
    final total = earnings.total;
    final totalStr = total == total.truncateToDouble()
        ? '\$ ${total.toInt()}'
        : '\$ ${total.toStringAsFixed(2)}';

    return GestureDetector(
      onTap: () => providerHomeTabNotifier.value = 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColor.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText(
                  'This Week\'s Earnings',
                  fontSize: FontSizes.medium,
                  fontWeight: FontWeights.bold,
                  color: AppColor.darkGrey,
                ),
                GestureDetector(
                  onTap: () => providerHomeTabNotifier.value = 2,
                  child: AppText(
                    'View All',
                    fontSize: 12,
                    fontWeight: FontWeights.semiBold,
                    color: AppColor.authButton,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              totalStr,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColor.darkGrey,
              ),
            ),
            const SizedBox(height: 4),
            AppText(
              '${earnings.weekStart} — ${earnings.weekEnd}',
              fontSize: 12,
              color: AppColor.grey,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Rating Card ───────────────────────────────────────────────────────────────

class _RatingCard extends StatelessWidget {
  final RatingSnapshot snapshot;

  const _RatingCard({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            'Rating Snapshot',
            fontSize: FontSizes.medium,
            fontWeight: FontWeights.bold,
            color: AppColor.darkGrey,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.star_rounded, color: Color(0xFFFFB300), size: 22),
              const SizedBox(width: 6),
              Text(
                snapshot.rating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColor.darkGrey,
                ),
              ),
              const SizedBox(width: 6),
              AppText(
                '(${snapshot.totalReviews} reviews)',
                fontSize: 13,
                color: AppColor.grey,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: 'Completion Rate',
                  value: '${snapshot.completionRate.toInt()}%',
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: 'Cancellation Rate',
                  value: '${snapshot.cancellationRate.toInt()}%',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(label, fontSize: 12, color: AppColor.grey),
        const SizedBox(height: 3),
        AppText(
          value,
          fontSize: 18,
          fontWeight: FontWeights.bold,
          color: AppColor.darkGrey,
        ),
      ],
    );
  }
}

// ─── Service Mix Card ──────────────────────────────────────────────────────────

class _ServiceMixCard extends StatelessWidget {
  final List<ServiceMixItem> items;

  const _ServiceMixCard({required this.items});

  static const _serviceIcons = [
    Icons.content_cut_rounded,
    Icons.spa_rounded,
    Icons.face_retouching_natural_rounded,
    Icons.brush_rounded,
    Icons.colorize_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          final icon = _serviceIcons[i % _serviceIcons.length];
          return Padding(
            padding: EdgeInsets.only(bottom: i < items.length - 1 ? 14 : 0),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColor.authButton.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 17, color: AppColor.authButton),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppText(
                    item.serviceName,
                    fontSize: FontSizes.regular,
                    color: AppColor.darkGrey,
                    maxLines: 1,
                  ),
                ),
                AppText(
                  '${item.count} ${item.count == 1 ? 'service' : 'services'} this month',
                  fontSize: 12,
                  color: AppColor.grey,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ─── Empty Card ────────────────────────────────────────────────────────────────

class _EmptyCard extends StatelessWidget {
  final String label;

  const _EmptyCard({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: AppText(label, fontSize: FontSizes.regular, color: AppColor.grey),
      ),
    );
  }
}

// ─── Error View ────────────────────────────────────────────────────────────────

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
            const Icon(Icons.wifi_off_rounded, size: 48, color: AppColor.grey),
            const SizedBox(height: 16),
            AppText(
              message,
              fontSize: FontSizes.regular,
              color: AppColor.grey,
              align: TextAlign.center,
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.authButton,
                foregroundColor: AppColor.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
