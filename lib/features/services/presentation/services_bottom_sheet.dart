import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pampa/core/utils/functional_component.dart';
import 'package:pampa/core/values/app_text_value.dart';
import 'package:pampa/core/values/colors.dart';
import 'package:pampa/core/widgets/text_widget.dart';
import 'package:pampa/data/service/di.dart';
import 'package:pampa/features/services/data/models/service_model.dart';
import 'package:pampa/features/services/presentation/provider/service_provider.dart';

class ServicesBottomSheet extends StatelessWidget {
  final int categoryId;
  final String categoryName;

  const ServicesBottomSheet({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final provider = getIt<ServiceProvider>();
        provider.fetchServices(categoryId: categoryId);
        return provider;
      },
      child: _ServicesSheetContent(categoryName: categoryName),
    );
  }
}

class _ServicesSheetContent extends StatelessWidget {
  final String categoryName;
  const _ServicesSheetContent({required this.categoryName});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 600,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColor.authBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
        children: [
          // ── Handle ────────────────────────────────────────────────────────
          const SizedBox(height: 12),
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

          // ── Header ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      categoryName,
                      fontSize: FontSizes.large,
                      fontWeight: FontWeights.bold,
                      color: AppColor.darkGrey,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 2),
                    AppText(
                      'Select a service to book',
                      fontSize: FontSizes.small,
                      color: AppColor.grey,
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColor.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColor.lightGrey),
                    ),
                    child: const Icon(Icons.close_rounded, size: 16, color: AppColor.darkGrey),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: AppColor.lightGrey),

          // ── Content ───────────────────────────────────────────────────────
          Flexible(
            child: Consumer<ServiceProvider>(
              builder: (context, provider, _) {
                if (provider.status == ServiceStatus.loading) {
                  return const _ServicesShimmer();
                }

                if (provider.status == ServiceStatus.error) {
                  return _ServicesError(
                    message: provider.errorMessage,
                    onRetry: provider.refresh,
                  );
                }

                if (provider.status == ServiceStatus.empty) {
                  return const _ServicesEmpty();
                }

                if (provider.services.isEmpty) {
                  return const SizedBox.shrink();
                }

                return ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  itemCount: provider.services.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: _ServiceSheetTile(service: provider.services[index]),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
        ],
      ),
      ),
    );
  }
}

class _ServiceSheetTile extends StatelessWidget {
  final ServiceModel service;
  const _ServiceSheetTile({required this.service});

  @override
  Widget build(BuildContext context) {
    final imageUrl = service.image.trim();
    final hasImage = imageUrl.isNotEmpty;

    return Material(
      color: AppColor.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
      onTap: () => Navigator.of(context).pop(service.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Image
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColor.authBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: hasImage
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: FunctionalComponent.cachedNetworkImage(imageUrl, radius: 12, fit: BoxFit.cover),
                    )
                  : const Icon(Icons.spa_rounded, color: AppColor.authButton, size: 20),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    service.serviceName,
                    fontSize: FontSizes.regular,
                    fontWeight: FontWeights.semiBold,
                    color: AppColor.darkGrey,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 12, color: AppColor.grey),
                      const SizedBox(width: 4),
                      AppText(service.formattedDuration, fontSize: FontSizes.mini, color: AppColor.grey),
                      if (service.deposit > 0) ...[
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColor.authButton.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: AppText('Deposit', fontSize: 9, fontWeight: FontWeights.semiBold, color: AppColor.authButton),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Price + arrow
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AppText(
                  service.formattedPrice,
                  fontSize: FontSizes.medium,
                  fontWeight: FontWeights.bold,
                  color: AppColor.darkGrey,
                ),
                const SizedBox(height: 2),
                const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColor.grey),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _ServicesShimmer extends StatelessWidget {
  const _ServicesShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(4, (index) => Padding(
          padding: EdgeInsets.only(bottom: index < 3 ? 10 : 0),
          child: Container(
            decoration: BoxDecoration(
              color: AppColor.white,
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: AppColor.lightGrey, borderRadius: BorderRadius.circular(12)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 14, width: 120, decoration: BoxDecoration(color: AppColor.lightGrey, borderRadius: BorderRadius.circular(6))),
                      const SizedBox(height: 6),
                      Container(height: 10, width: 80, decoration: BoxDecoration(color: AppColor.lightGrey, borderRadius: BorderRadius.circular(6))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )),
      ),
    );
  }
}

class _ServicesError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ServicesError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 40, color: AppColor.mediumGrey),
          const SizedBox(height: 14),
          AppText(message, fontSize: FontSizes.small, color: AppColor.grey, align: TextAlign.center, maxLines: 3),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(color: AppColor.authButton, borderRadius: BorderRadius.circular(10)),
              child: AppText('Try Again', fontSize: FontSizes.small, fontWeight: FontWeights.semiBold, color: AppColor.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServicesEmpty extends StatelessWidget {
  const _ServicesEmpty();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 40, color: AppColor.mediumGrey),
          SizedBox(height: 14),
          AppText(
            'No services available',
            fontSize: FontSizes.regular,
            fontWeight: FontWeights.semiBold,
            color: AppColor.grey,
          ),
        ],
      ),
    );
  }
}
