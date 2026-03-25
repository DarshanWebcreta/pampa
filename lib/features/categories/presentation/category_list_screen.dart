import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pampa/core/utils/functional_component.dart';
import 'package:pampa/core/values/app_text_value.dart';
import 'package:pampa/core/values/colors.dart';
import 'package:pampa/core/widgets/text_widget.dart';
import 'package:pampa/features/categories/data/models/category_model.dart';
import 'package:go_router/go_router.dart';
import 'package:pampa/core/routes/routes.dart';
import 'package:pampa/features/categories/presentation/provider/category_provider.dart';
import 'package:pampa/features/services/presentation/services_bottom_sheet.dart';

IconData _iconForCategoryName(String name) {
  final lower = name.toLowerCase();
  if (lower.contains('hair') || lower.contains('salon')) return Icons.content_cut_rounded;
  if (lower.contains('braid')) return Icons.waves_rounded;
  if (lower.contains('nail')) return Icons.colorize_rounded;
  if (lower.contains('makeup') || lower.contains('beauty')) return Icons.brush_rounded;
  if (lower.contains('massage') || lower.contains('spa')) return Icons.self_improvement_rounded;
  if (lower.contains('facial') || lower.contains('skin')) return Icons.face_retouching_natural_rounded;
  if (lower.contains('brow') || lower.contains('lash')) return Icons.auto_awesome_rounded;
  if (lower.contains('wax')) return Icons.blur_on_rounded;
  if (lower.contains('yoga') || lower.contains('fitness')) return Icons.fitness_center_rounded;
  return Icons.spa_rounded;
}

String _descForCategoryName(String name) {
  final lower = name.toLowerCase();
  if (lower.contains('hair') || lower.contains('salon')) return 'Cuts, color, styling & treatments';
  if (lower.contains('braid')) return 'Box braids, cornrows, knotless & more';
  if (lower.contains('nail')) return 'Manicures, pedicures & nail art';
  if (lower.contains('makeup') || lower.contains('beauty')) return 'Full glam, natural looks & more';
  if (lower.contains('massage') || lower.contains('spa')) return 'Relaxation & therapeutic massage';
  if (lower.contains('facial') || lower.contains('skin')) return 'Facials, peels & skin treatments';
  if (lower.contains('brow') || lower.contains('lash')) return 'Brow shaping, tinting & lash lifts';
  if (lower.contains('wax')) return 'Body & facial waxing services';
  return 'Browse available services';
}

class CategoryListScreen extends StatelessWidget {
  const CategoryListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.authBg,
      appBar: AppBar(
        backgroundColor: AppColor.authBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColor.darkGrey, size: 20),
        ),
      ),
      body: Consumer<CategoryProvider>(
        builder: (context, provider, _) {
          return RefreshIndicator(
            color: AppColor.authButton,
            onRefresh: () => provider.fetchCategories(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          'What brings you\njoy today?',
                          fontSize: FontSizes.extraLarge,
                          fontWeight: FontWeights.bold,
                          color: AppColor.darkGrey,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 8),
                        AppText(
                          'Select the service you\'d like to book',
                          fontSize: FontSizes.regular,
                          color: AppColor.grey,
                        ),
                      ],
                    ),
                  ),
                ),
                _buildBody(context, provider),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, CategoryProvider provider) {
    switch (provider.status) {
      case CategoryStatus.loading:
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, __) => const _CategoryListShimmer(),
              childCount: 5,
            ),
          ),
        );

      case CategoryStatus.error:
        return SliverFillRemaining(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off_rounded, size: 48, color: AppColor.mediumGrey),
                  const SizedBox(height: 16),
                  AppText(provider.errorMessage, fontSize: FontSizes.small, color: AppColor.grey, align: TextAlign.center, maxLines: 3),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => provider.refresh(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                      decoration: BoxDecoration(color: AppColor.authButton, borderRadius: BorderRadius.circular(10)),
                      child: AppText('Try Again', fontSize: FontSizes.small, fontWeight: FontWeights.semiBold, color: AppColor.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

      case CategoryStatus.empty:
        return SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.spa_outlined, size: 48, color: AppColor.mediumGrey),
                const SizedBox(height: 16),
                AppText('No categories available', fontSize: FontSizes.regular, fontWeight: FontWeights.semiBold, color: AppColor.grey),
              ],
            ),
          ),
        );

      case CategoryStatus.initial:
        return const SliverToBoxAdapter(child: SizedBox.shrink());

      case CategoryStatus.success:
        final categories = provider.categories;
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: AppColor.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColor.lightGrey, width: 1),
              ),
              child: Column(
                children: List.generate(categories.length, (index) {
                  final category = categories[index];
                  final isLast = index == categories.length - 1;
                  return Column(
                    children: [
                      _CategoryListTile(category: category),
                      if (!isLast) Divider(height: 1, color: AppColor.lightGrey, indent: 72),
                    ],
                  );
                }),
              ),
            ),
          ),
        );
    }
  }
}

class _CategoryListTile extends StatelessWidget {
  final CategoryModel category;
  const _CategoryListTile({required this.category});

  @override
  Widget build(BuildContext context) {
    final iconUrl = category.icon?.trim();
    final hasIcon = iconUrl != null && iconUrl.isNotEmpty;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showServicesSheet(context, category),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColor.authBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: hasIcon
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: FunctionalComponent.cachedNetworkImage(iconUrl, radius: 12, fit: BoxFit.cover),
                    )
                  : Icon(_iconForCategoryName(category.categoryName), size: 22, color: AppColor.authButton),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    category.categoryName,
                    fontSize: FontSizes.regular,
                    fontWeight: FontWeights.semiBold,
                    color: AppColor.darkGrey,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 2),
                  AppText(
                    _descForCategoryName(category.categoryName),
                    fontSize: FontSizes.small,
                    color: AppColor.grey,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColor.grey),
          ],
        ),
      ),
    );
  }

  Future<void> _showServicesSheet(BuildContext context, CategoryModel category) async {
    final serviceId = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ServicesBottomSheet(
        categoryId: category.id,
        categoryName: category.categoryName,
      ),
    );
    if (serviceId != null && context.mounted) {
      context.push(RouteNames.bookingDetail, extra: serviceId);
    }
  }
}

class _CategoryListShimmer extends StatelessWidget {
  const _CategoryListShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      height: 72,
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }
}
