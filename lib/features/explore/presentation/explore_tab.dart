import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:pampa/core/routes/routes.dart';
import 'package:pampa/core/utils/functional_component.dart';
import 'package:pampa/core/values/app_text_value.dart';
import 'package:pampa/core/values/colors.dart';
import 'package:pampa/core/widgets/text_widget.dart';
import 'package:pampa/features/booking/presentation/provider_detail_screen.dart';
import 'package:pampa/features/explore/data/models/explore_model.dart';
import 'package:pampa/features/explore/presentation/provider/explore_provider.dart';

class ExploreTab extends StatefulWidget {
  const ExploreTab({super.key});

  @override
  State<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<ExploreTab> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExploreProvider>().fetch();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _openProvider(BuildContext context, int providerId) async {
    final exploreProvider = context.read<ExploreProvider>();

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColor.authButton),
      ),
    );

    final provider = await exploreProvider.fetchProviderDetail(providerId);

    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // close dialog

    if (provider == null) {
      FunctionalComponent.showSnackBar(
        context: context,
        title: 'Failed to load provider details.',
        success: false,
      );
      return;
    }

    final firstServiceId =
        provider.services.isNotEmpty ? provider.services.first.id : 0;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProviderDetailScreen(
          provider: provider,
          initialServiceId: firstServiceId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExploreProvider>(
      builder: (context, provider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header + Search ─────────────────────────────────────────
            _buildHeader(provider),
            // ── Body ────────────────────────────────────────────────────
            Expanded(child: _buildBody(provider)),
          ],
        );
      },
    );
  }

  Widget _buildHeader(ExploreProvider provider) {
    return Container(
      color: AppColor.authBg,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            'Explore',
            fontSize: 28,
            fontWeight: FontWeights.bold,
            color: AppColor.darkGrey,
          ),
          const SizedBox(height: 14),
          // Search bar
          Container(
            height: 46,
            decoration: BoxDecoration(
              color: AppColor.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => provider.onSearchChanged(v),
              style: const TextStyle(
                fontSize: 14,
                color: AppColor.darkGrey,
              ),
              decoration: InputDecoration(
                hintText: 'Search providers, services...',
                hintStyle: const TextStyle(
                  fontSize: 14,
                  color: AppColor.grey,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColor.grey,
                  size: 20,
                ),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppColor.grey,
                          size: 18,
                        ),
                        onPressed: () {
                          _searchCtrl.clear();
                          provider.clearSearch();
                          setState(() => _selectedCategory = null);
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ExploreProvider provider) {
    if (provider.status == ExploreFetchStatus.loading &&
        provider.result == null) {
      return _buildShimmer();
    }

    if (provider.status == ExploreFetchStatus.error) {
      return _buildError(provider);
    }

    final result = provider.result;
    if (result == null || result.isEmpty) {
      return _buildEmpty();
    }

    return RefreshIndicator(
      color: AppColor.authButton,
      onRefresh: () => provider.fetch(query: _searchCtrl.text.trim()),
      child: ListView(
        controller: _scrollCtrl,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 32),
        children: [
          // ── Category chips ─────────────────────────────────────────────
          if (result.categories.isNotEmpty) ...[
            _buildCategoryChips(result.categories),
            const SizedBox(height: 24),
          ],

          // ── Recommended for You (Providers) ────────────────────────────
          if (result.providers.isNotEmpty) ...[
            _SectionHeader(title: 'Recommended for You', icon: '✨'),
            const SizedBox(height: 12),
            ...result.providers.map((p) => _TappableProviderCard(
                  provider: p,
                  onTap: () => _openProvider(context, p.id),
                )),
            const SizedBox(height: 24),
          ],

          // ── Trending Looks (Categories grid) ───────────────────────────
          if (result.categories.isNotEmpty) ...[
            _SectionHeader(title: 'Trending Looks', icon: '📈'),
            const SizedBox(height: 12),
            _buildCategoryGrid(result.categories),
            const SizedBox(height: 24),
          ],

          // ── Services ───────────────────────────────────────────────────
          if (result.services.isNotEmpty) ...[
            _SectionHeader(title: 'Services', icon: '✂️'),
            const SizedBox(height: 12),
            ...result.services.map((s) => _ServiceCard(service: s)),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryChips(List<ExploreCategoryModel> categories) {
    final provider = context.read<ExploreProvider>();
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = categories[i];
          final isSelected = _selectedCategory == cat.categoryName;
          return GestureDetector(
            onTap: () {
              if (isSelected) {
                // Deselect: clear search
                _searchCtrl.clear();
                provider.clearSearch();
                setState(() => _selectedCategory = null);
              } else {
                _searchCtrl.text = cat.categoryName;
                provider.onSearchChanged(cat.categoryName);
                setState(() => _selectedCategory = cat.categoryName);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColor.authButton : AppColor.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColor.authButton : AppColor.lightGrey,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (cat.icon != null) ...[
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: FunctionalComponent.cachedNetworkImage(
                          cat.icon ?? '',
                          radius: 4,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  AppText(
                    cat.categoryName,
                    fontSize: 12,
                    fontWeight: FontWeights.medium,
                    color: isSelected ? AppColor.white : AppColor.darkGrey,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryGrid(List<ExploreCategoryModel> categories) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: categories.length,
        itemBuilder: (_, i) => _CategoryGridCard(category: categories[i]),
      ),
    );
  }

  Widget _buildError(ExploreProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColor.authBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 32,
                color: AppColor.authButton,
              ),
            ),
            const SizedBox(height: 16),
            AppText(
              provider.error,
              fontSize: FontSizes.small,
              color: AppColor.grey,
              align: TextAlign.center,
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => provider.fetch(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 12),
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

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColor.authBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 32,
              color: AppColor.authButton,
            ),
          ),
          const SizedBox(height: 16),
          AppText(
            'No results found',
            fontSize: FontSizes.medium,
            fontWeight: FontWeights.semiBold,
            color: AppColor.darkGrey,
          ),
          const SizedBox(height: 8),
          AppText(
            'Try a different search term',
            fontSize: FontSizes.small,
            color: AppColor.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      children: [
        const SizedBox(height: 8),
        _ShimmerBox(width: double.infinity, height: 36, radius: 20),
        const SizedBox(height: 24),
        _ShimmerBox(width: 160, height: 18),
        const SizedBox(height: 12),
        for (int i = 0; i < 3; i++) ...[
          _ShimmerBox(width: double.infinity, height: 90, radius: 16),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

// ─── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          AppText(
            '$icon  $title',
            fontSize: FontSizes.medium,
            fontWeight: FontWeights.bold,
            color: AppColor.darkGrey,
          ),
        ],
      ),
    );
  }
}

// ─── Provider card ─────────────────────────────────────────────────────────────

class _TappableProviderCard extends StatelessWidget {
  final ExploreProviderModel provider;
  final VoidCallback onTap;

  const _TappableProviderCard({required this.provider, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          _ProviderAvatar(photoUrl: provider.photoUrl, name: provider.name),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  provider.name,
                  fontSize: FontSizes.regular,
                  fontWeight: FontWeights.bold,
                  color: AppColor.darkGrey,
                  maxLines: 1,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    // Stars
                    ...List.generate(
                      5,
                      (i) => Icon(
                        Icons.star_rounded,
                        size: 13,
                        color: provider.rating > i
                            ? const Color(0xFFFFB800)
                            : AppColor.lightGrey,
                      ),
                    ),
                    const SizedBox(width: 4),
                    AppText(
                      provider.rating.toStringAsFixed(1),
                      fontSize: 12,
                      color: AppColor.grey,
                    ),
                    if (provider.displayLocation.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.location_on_rounded,
                        size: 12,
                        color: AppColor.grey,
                      ),
                      const SizedBox(width: 2),
                      Flexible(
                        child: AppText(
                          provider.displayLocation,
                          fontSize: 12,
                          color: AppColor.grey,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ],
                ),
                if (provider.bio != null && provider.bio!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  AppText(
                    provider.bio!,
                    fontSize: 12,
                    color: AppColor.grey,
                    maxLines: 2,
                  ),
                ],
              ],
            ),
          ),
          // Favourite icon
          const Icon(
            Icons.favorite_border_rounded,
            size: 20,
            color: AppColor.grey,
          ),
        ],
      ),
      ),
    );
  }
}

class _ProviderAvatar extends StatelessWidget {
  final String? photoUrl;
  final String name;

  const _ProviderAvatar({required this.photoUrl, required this.name});

  @override
  Widget build(BuildContext context) {
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();

    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return ClipOval(
        child: SizedBox(
          width: 54,
          height: 54,
          child: FunctionalComponent.cachedNetworkImage(
            photoUrl!,
            radius: 27,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: AppColor.authButton.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: AppText(
        initials.isEmpty ? '?' : initials,
        fontSize: 16,
        fontWeight: FontWeights.bold,
        color: AppColor.authButton,
      ),
    );
  }
}

// ─── Category grid card ────────────────────────────────────────────────────────

class _CategoryGridCard extends StatelessWidget {
  final ExploreCategoryModel category;

  const _CategoryGridCard({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            category.icon != null
                ? FunctionalComponent.cachedNetworkImage(
                    category.icon!,
                    radius: 16,
                    fit: BoxFit.cover,
                  )
                : Container(
                    color: AppColor.authButton.withValues(alpha: 0.08),
                    child: const Icon(
                      Icons.spa_rounded,
                      color: AppColor.authButton,
                      size: 40,
                    ),
                  ),
            // Gradient overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.55),
                    ],
                  ),
                ),
              ),
            ),
            // Labels
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText(
                    category.categoryName,
                    fontSize: 13,
                    fontWeight: FontWeights.bold,
                    color: AppColor.white,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Service card ──────────────────────────────────────────────────────────────

class _ServiceCard extends StatelessWidget {
  final ExploreServiceModel service;

  const _ServiceCard({required this.service});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(RouteNames.bookingDetail, extra: service.id),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColor.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 70,
                height: 70,
                child: service.imageUrl != null
                    ? FunctionalComponent.cachedNetworkImage(
                        service.imageUrl!,
                        radius: 12,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: AppColor.authButton.withValues(alpha: 0.08),
                        child: const Icon(
                          Icons.spa_rounded,
                          color: AppColor.authButton,
                          size: 28,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    service.serviceName,
                    fontSize: FontSizes.regular,
                    fontWeight: FontWeights.bold,
                    color: AppColor.darkGrey,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),
                  if (service.categoryName != null)
                    AppText(
                      service.categoryName!,
                      fontSize: 12,
                      color: AppColor.grey,
                      maxLines: 1,
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 12,
                        color: AppColor.grey,
                      ),
                      const SizedBox(width: 4),
                      AppText(
                        '${service.duration} min',
                        fontSize: 12,
                        color: AppColor.grey,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Price
            AppText(
              '\$${service.price.toStringAsFixed(0)}',
              fontSize: FontSizes.regular,
              fontWeight: FontWeights.bold,
              color: AppColor.authButton,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shimmer ───────────────────────────────────────────────────────────────────

class _ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double radius;

  const _ShimmerBox({
    required this.width,
    required this.height,
    this.radius = 8,
  });

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: AppColor.lightGrey,
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        ),
      ),
    );
  }
}
