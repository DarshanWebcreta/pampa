import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pampa/core/utils/functional_component.dart';
import 'package:provider/provider.dart';

import 'package:pampa/core/routes/routes.dart';
import 'package:pampa/core/values/colors.dart';
import 'package:pampa/core/values/app_text_value.dart';
import 'package:pampa/core/widgets/text_widget.dart';
import 'package:pampa/features/services/data/models/service_model.dart';
import 'package:pampa/features/services/presentation/provider/service_provider.dart';

class ServicesScreen extends StatefulWidget {
  final int categoryId;
  final String categoryName;

  const ServicesScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  late final ServiceProvider _serviceProvider;

  @override
  void initState() {
    super.initState();
    _serviceProvider = context.read<ServiceProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _serviceProvider.fetchServices(categoryId: widget.categoryId);
    });
  }

  @override
  void dispose() {
    // Reset so stale data isn't shown next time
    _serviceProvider.reset();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      // appBar: _buildAppBar(context),
      body: Consumer<ServiceProvider>(
        builder: (context, provider, _) {
          return _buildBody(context, provider);
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColor.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: const Padding(
          padding: EdgeInsets.all(12),
          child: Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColor.darkGrey, size: 20),
        ),
      ),
      centerTitle: true,
      title: AppText(
        'Pampa',
        fontSize: FontSizes.medium,
        fontWeight: FontWeights.bold,
        color: AppColor.authButton,
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Icon(Icons.calendar_month_outlined,
              color: AppColor.darkGrey, size: 24),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, ServiceProvider provider) {
    return RefreshIndicator(
      color: AppColor.authButton,
      onRefresh: () => provider.refresh(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ── Category header ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16,10, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FunctionalComponent.goBackArrow(context: context),

                  AppText(
                    widget.categoryName,
                    fontSize: FontSizes.extraLarge,
                    fontWeight: FontWeights.bold,
                    color: AppColor.darkGrey,
                  ),
                  const SizedBox(height: 4),
                  if (provider.status == ServiceStatus.success)
                    AppText(
                      '${provider.services.length} service${provider.services.length == 1 ? '' : 's'} available',
                      fontSize: FontSizes.small,
                      color: AppColor.grey,
                    ),
                ],
              ),
            ),
          ),

          // ── Filter chips ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _FilterChips(
              provider: provider,
              onSort: (sort) => provider.setSort(sort),
            ),
          ),

          // ── Content ──────────────────────────────────────────────────────
          _buildContent(provider),
        ],
      ),
    );
  }

  Widget _buildContent(ServiceProvider provider) {
    switch (provider.status) {
      case ServiceStatus.loading:
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, __) => const _ServiceCardShimmer(),
              childCount: 4,
            ),
          ),
        );

      case ServiceStatus.error:
        return SliverFillRemaining(
          child: _ErrorState(
            message: provider.errorMessage,
            onRetry: provider.refresh,
          ),
        );

      case ServiceStatus.empty:
        return SliverFillRemaining(
          child: _EmptyState(categoryName: widget.categoryName),
        );

      case ServiceStatus.initial:
        return const SliverToBoxAdapter(child: SizedBox.shrink());

      case ServiceStatus.success:
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _ServiceCard(
                service: provider.services[index],
              ),
              childCount: provider.services.length,
            ),
          ),
        );
    }
  }
}

// ─── Filter chips ─────────────────────────────────────────────────────────────
class _FilterChips extends StatelessWidget {
  final ServiceProvider provider;
  final void Function(ServiceSortType) onSort;

  const _FilterChips({required this.provider, required this.onSort});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          _Chip(
            label: 'Highest Rated',
            active: provider.sortType == ServiceSortType.highestRated,
            onTap: () => onSort(ServiceSortType.highestRated),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'Best Price',
            active: provider.sortType == ServiceSortType.bestPrice,
            onTap: () => onSort(ServiceSortType.bestPrice),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'Nearest',
            active: provider.sortType == ServiceSortType.nearest,
            onTap: () => onSort(ServiceSortType.nearest),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _Chip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColor.authButton : AppColor.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? AppColor.authButton : AppColor.mediumGrey,
          ),
        ),
        child: AppText(
          label,
          fontSize: 12,
          fontWeight: active ? FontWeights.semiBold : FontWeights.regular,
          color: active ? AppColor.white : AppColor.darkGrey,
        ),
      ),
    );
  }
}

// ─── Service card ─────────────────────────────────────────────────────────────
class _ServiceCard extends StatelessWidget {
  final ServiceModel service;

  const _ServiceCard({required this.service});

  @override
  Widget build(BuildContext context) {
    final imageUrl = service.image.trim();
    final hasImage = imageUrl.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: info + price ──────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Service image
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColor.authBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: hasImage
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: FunctionalComponent.cachedNetworkImage(
                            imageUrl,
                            radius: 12,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(
                          Icons.spa_rounded,
                          color: AppColor.authButton,
                          size: 32,
                        ),
                ),
                const SizedBox(width: 14),

                // Name + meta
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        service.serviceName,
                        fontSize: FontSizes.regular,
                        fontWeight: FontWeights.bold,
                        color: AppColor.darkGrey,
                        maxLines: 2,
                      ),
                      if (service.description != null &&
                          service.description!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        AppText(
                          service.description!,
                          fontSize: 11,
                          color: AppColor.grey,
                          maxLines: 2,
                        ),
                      ],
                      const SizedBox(height: 8),
                      // Duration row
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded,
                              size: 14, color: AppColor.grey),
                          const SizedBox(width: 4),
                          AppText(
                            service.formattedDuration,
                            fontSize: 12,
                            color: AppColor.grey,
                          ),
                          if (service.deposit > 0) ...[
                            const SizedBox(width: 12),
                            const Icon(Icons.info_outline_rounded,
                                size: 14, color: AppColor.grey),
                            const SizedBox(width: 4),
                            AppText(
                              'Deposit req.',
                              fontSize: 12,
                              color: AppColor.grey,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Price
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AppText(
                      service.formattedPrice,
                      fontSize: 20,
                      fontWeight: FontWeights.bold,
                      color: AppColor.darkGrey,
                    ),
                    if (service.priorityFee > 0)
                      AppText(
                        '+\$${service.priorityFee.toStringAsFixed(0)} priority',
                        fontSize: 10,
                        color: AppColor.grey,
                      ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── Book Now ──────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.authButton,
                  foregroundColor: AppColor.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  context.push(RouteNames.bookingDetail, extra: service.id);
                },
                child: AppText(
                  'Book Now',
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

// ─── Shimmer ──────────────────────────────────────────────────────────────────
class _ServiceCardShimmer extends StatefulWidget {
  const _ServiceCardShimmer();

  @override
  State<_ServiceCardShimmer> createState() => _ServiceCardShimmerState();
}

class _ServiceCardShimmerState extends State<_ServiceCardShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
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
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColor.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColor.lightGrey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _shimmerBox(140, 14),
                        const SizedBox(height: 8),
                        _shimmerBox(100, 11),
                        const SizedBox(height: 10),
                        _shimmerBox(80, 11),
                      ],
                    ),
                  ),
                  _shimmerBox(48, 20),
                ],
              ),
              const SizedBox(height: 14),
              _shimmerBox(double.infinity, 44, radius: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shimmerBox(double width, double height, {double radius = 6}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColor.lightGrey,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// ─── Error state ──────────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
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
                  color: AppColor.authBg, shape: BoxShape.circle),
              child: const Icon(Icons.wifi_off_rounded,
                  size: 32, color: AppColor.authButton),
            ),
            const SizedBox(height: 16),
            AppText('Something went wrong',
                fontSize: FontSizes.medium,
                fontWeight: FontWeights.semiBold,
                color: AppColor.darkGrey,
                align: TextAlign.center),
            const SizedBox(height: 8),
            AppText(message,
                fontSize: FontSizes.small,
                color: AppColor.grey,
                align: TextAlign.center,
                maxLines: 3),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                decoration: BoxDecoration(
                  color: AppColor.authButton,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: AppText('Try Again',
                    fontSize: FontSizes.regular,
                    fontWeight: FontWeights.semiBold,
                    color: AppColor.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String categoryName;
  const _EmptyState({required this.categoryName});

  @override
  Widget build(BuildContext context) {
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
                  color: AppColor.authBg, shape: BoxShape.circle),
              child: const Icon(Icons.search_off_rounded,
                  size: 32, color: AppColor.authButton),
            ),
            const SizedBox(height: 16),
            AppText('No services found',
                fontSize: FontSizes.medium,
                fontWeight: FontWeights.semiBold,
                color: AppColor.darkGrey),
            const SizedBox(height: 8),
            AppText(
              'No $categoryName services available in your area.',
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
