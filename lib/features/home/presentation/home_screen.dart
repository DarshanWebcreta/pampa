import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:pampa/core/routes/routes.dart';
import 'package:pampa/core/values/colors.dart';
import 'package:pampa/core/values/app_text_value.dart';
import 'package:pampa/core/widgets/text_widget.dart';
import 'package:pampa/features/categories/data/models/category_model.dart';
import 'package:pampa/features/categories/presentation/provider/category_provider.dart';

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

// ─── Bottom-nav item data ──────────────────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}

const _navItems = [
  _NavItem(icon: Icons.home_outlined,      activeIcon: Icons.home_rounded,          label: 'Home'),
  _NavItem(icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today_rounded, label: 'Calendar'),
  _NavItem(icon: Icons.bookmark_border_rounded, activeIcon: Icons.bookmark_rounded,       label: 'Bookings'),
  _NavItem(icon: Icons.chat_bubble_outline_rounded, activeIcon: Icons.chat_bubble_rounded, label: 'Messages'),
  _NavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded,         label: 'Profile'),
];

// ─── Main shell ───────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().fetchCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.white,
      appBar: _buildAppBar(),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const _ServicesTab(),
          const _PlaceholderTab(icon: Icons.calendar_today_rounded, label: 'Calendar'),
          const _PlaceholderTab(icon: Icons.bookmark_rounded,       label: 'Bookings'),
          const _PlaceholderTab(icon: Icons.chat_bubble_rounded,    label: 'Messages'),
          const _PlaceholderTab(icon: Icons.person_rounded,         label: 'Profile'),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColor.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      title: AppText(
        'Pampa',
        fontSize: FontSizes.large,
        fontWeight: FontWeights.bold,
        color: AppColor.authButton,
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: const Icon(Icons.menu_rounded, color: AppColor.authButton, size: 26),
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
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
              final isActive = _currentIndex == index;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _currentIndex = index),
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
class _ServicesTab extends StatelessWidget {
  const _ServicesTab();

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
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: AppText(
                    'Services',
                    fontSize: FontSizes.extraLarge,
                    fontWeight: FontWeights.bold,
                    color: AppColor.black,
                  ),
                ),
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
    return GestureDetector(
      onTap: () {
        context.push(
          RouteNames.services,
          extra: {'categoryId': category.id, 'categoryName': category.categoryName},
        );
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
              child: Icon(
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
      builder: (_, __) => Opacity(
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

// ─── Placeholder tabs ──────────────────────────────────────────────────────────
class _PlaceholderTab extends StatelessWidget {
  final IconData icon;
  final String label;
  const _PlaceholderTab({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppColor.authBg),
          const SizedBox(height: 12),
          AppText(label, fontSize: FontSizes.medium, color: AppColor.grey),
        ],
      ),
    );
  }
}
