import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pampa/core/utils/functional_component.dart';
import 'package:pampa/core/values/app_text_value.dart';
import 'package:pampa/core/values/colors.dart';
import 'package:pampa/core/widgets/text_widget.dart';
import 'package:pampa/data/service/di.dart';
import 'package:pampa/features/address/presentation/provider/address_provider.dart';
import 'package:pampa/features/booking/data/models/provider_model.dart';
import 'package:pampa/features/booking/presentation/booking_screen.dart';
import 'package:pampa/features/booking/presentation/provider/booking_provider.dart';

class ProviderDetailScreen extends StatefulWidget {
  final ProviderModel provider;
  final int initialServiceId;
  /// When provided, called on "Continue" (used by ChooseProviderScreen flow).
  /// When null, navigates to BookingScreen independently.
  final void Function(List<int> serviceIds)? onSelectProvider;

  const ProviderDetailScreen({
    super.key,
    required this.provider,
    required this.initialServiceId,
    this.onSelectProvider,
  });

  @override
  State<ProviderDetailScreen> createState() => _ProviderDetailScreenState();
}

class _ProviderDetailScreenState extends State<ProviderDetailScreen> {
  late Set<int> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = {widget.initialServiceId};
  }

  void _toggleService(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        if (_selectedIds.length > 1) _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  double get _totalPrice {
    return widget.provider.services
        .where((s) => _selectedIds.contains(s.id))
        .fold(0.0, (sum, s) => sum + s.priceAsDouble);
  }

  String _fmtPrice(double p) =>
      p == p.truncateToDouble() ? '\$${p.toInt()}' : '\$${p.toStringAsFixed(2)}';

  void _onContinue(BuildContext context) {
    final selectedIds = _selectedIds.toList();
    final callback = widget.onSelectProvider;
    if (callback != null) {
      Navigator.of(context).pop();
      callback(selectedIds);
      return;
    }

    // Standalone flow: navigate to BookingScreen (address → date/time → review)
    final bp = getIt<BookingProvider>();
    bp.fetchServiceDetail(widget.initialServiceId);
    bp.setSelectedServiceIds(selectedIds);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: bp),
            ChangeNotifierProvider.value(
                value: context.read<AddressProvider>()),
          ],
          child: BookingScreen(
            serviceId: widget.initialServiceId,
            preSelectedProvider: widget.provider,
            preSelectedServiceIds: selectedIds,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = _selectedIds.length;
    final total = _totalPrice;

    return Scaffold(
      backgroundColor: AppColor.white,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ── Gallery ───────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _GallerySection(images: widget.provider.images),
              ),

              // ── Provider info ─────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: _ProviderInfoSection(provider: widget.provider),
                ),
              ),

              // ── Services ──────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        'Services',
                        fontSize: FontSizes.large,
                        fontWeight: FontWeights.bold,
                        color: AppColor.darkGrey,
                      ),
                      const SizedBox(height: 4),
                      AppText(
                        'Select the service you\'d like to book',
                        fontSize: FontSizes.regular,
                        color: AppColor.grey,
                      ),
                      const SizedBox(height: 14),
                      ...widget.provider.services.map(
                        (s) => _ServiceItem(
                          service: s,
                          isSelected: _selectedIds.contains(s.id),
                          onTap: () => _toggleService(s.id),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Cancellation Policy ───────────────────────────────────
              if (widget.provider.cancellationPolicy != null &&
                  widget.provider.cancellationPolicy!.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: _CancellationPolicySection(
                      policy: widget.provider.cancellationPolicy!,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 110)),
            ],
          ),

          // ── Back button overlay ────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColor.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      // ── Bottom CTA ─────────────────────────────────────────────────────
      bottomNavigationBar: widget.provider.services.isEmpty
          ? Container(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                MediaQuery.of(context).padding.bottom + 12,
              ),
              decoration: BoxDecoration(
                color: AppColor.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SizedBox(
                height: 52,
                child: Center(
                  child: AppText(
                    'No services available at the moment',
                    fontSize: FontSizes.regular,
                    color: AppColor.grey,
                  ),
                ),
              ),
            )
          : Container(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                MediaQuery.of(context).padding.bottom + 12,
              ),
              decoration: BoxDecoration(
                color: AppColor.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.authButton,
                    foregroundColor: AppColor.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => _onContinue(context),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppText(
                        count == 1
                            ? 'Continue to Book'
                            : 'Continue · $count Services',
                        color: AppColor.white,
                        fontWeight: FontWeights.semiBold,
                        fontSize: FontSizes.regular,
                      ),
                      if (total > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: AppText(
                            _fmtPrice(total),
                            color: AppColor.white,
                            fontWeight: FontWeights.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

// ─── Gallery ──────────────────────────────────────────────────────────────────

class _GallerySection extends StatelessWidget {
  final List<ProviderGalleryImageModel> images;

  const _GallerySection({required this.images});

  Widget _img(String? url) {
    if (url == null || url.isEmpty) {
      return Container(color: AppColor.lightGrey);
    }
    return FunctionalComponent.cachedNetworkImage(url, fit: BoxFit.cover, radius: 0);
  }

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return Container(
        width: double.infinity,
        height: 260,
        color: AppColor.authButton.withValues(alpha: 0.08),
        child: const Icon(Icons.spa_rounded, size: 56, color: AppColor.authButton),
      );
    }

    final urls = images.map((e) => e.imageUrl).toList();

    return Column(
      children: [
        // Large hero — always first image
        SizedBox(
          width: double.infinity,
          height: 210,
          child: _img(urls[0]),
        ),

        // Remaining images in rows of 2
        if (urls.length > 1)
          ...() {
            final rows = <Widget>[];
            for (int i = 1; i < urls.length; i += 2) {
              final left = urls[i];
              final right = i + 1 < urls.length ? urls[i + 1] : null;
              rows.add(
                SizedBox(
                  height: 130,
                  child: Row(
                    children: [
                      Expanded(child: _img(left)),
                      const SizedBox(width: 2),
                      Expanded(
                        child: right != null
                            ? _img(right)
                            : Container(color: AppColor.authBg),
                      ),
                    ],
                  ),
                ),
              );
              if (i + 2 < urls.length) rows.add(const SizedBox(height: 2));
            }
            return rows;
          }(),
      ],
    );
  }
}

// ─── Provider info ────────────────────────────────────────────────────────────

class _ProviderInfoSection extends StatelessWidget {
  final ProviderModel provider;

  const _ProviderInfoSection({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _ProviderAvatar(
              photoUrl: provider.photoUrl,
              displayName: provider.displayName,
              size: 52,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    provider.displayName,
                    fontSize: 20,
                    fontWeight: FontWeights.bold,
                    color: AppColor.darkGrey,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 16, color: AppColor.blue),
                      const SizedBox(width: 4),
                      AppText(
                        provider.rating.toStringAsFixed(1),
                        fontSize: 13,
                        fontWeight: FontWeights.semiBold,
                        color: AppColor.darkGrey,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        if (provider.bio != null && provider.bio!.isNotEmpty) ...[
          const SizedBox(height: 14),
          AppText(
            provider.bio!,
            fontSize: FontSizes.regular,
            color: AppColor.grey,
            maxLines: 8,
          ),
        ],
      ],
    );
  }
}

// ─── Service item ─────────────────────────────────────────────────────────────

class _ServiceItem extends StatelessWidget {
  final ProviderServiceSummaryModel service;
  final bool isSelected;
  final VoidCallback onTap;

  const _ServiceItem({
    required this.service,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final price = service.priceAsDouble;
    final priceStr = price == price.truncateToDouble()
        ? '\$${price.toInt()}'
        : '\$${price.toStringAsFixed(2)}';

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColor.authButton.withValues(alpha: 0.06)
              : AppColor.authBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColor.authButton.withValues(alpha: 0.5)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
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
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          size: 13, color: AppColor.grey),
                      const SizedBox(width: 4),
                      AppText(
                        service.formattedDuration,
                        fontSize: 12,
                        color: AppColor.grey,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            AppText(
              priceStr,
              fontSize: FontSizes.medium,
              fontWeight: FontWeights.bold,
              color: AppColor.darkGrey,
            ),
            const SizedBox(width: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isSelected ? AppColor.authButton : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColor.authButton : AppColor.mediumGrey,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded,
                      size: 14, color: AppColor.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Cancellation Policy ──────────────────────────────────────────────────────

class _CancellationPolicySection extends StatelessWidget {
  final String policy;

  const _CancellationPolicySection({required this.policy});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          'Cancellation Policy',
          fontSize: FontSizes.large,
          fontWeight: FontWeights.bold,
          color: AppColor.darkGrey,
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColor.authBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: AppText(
            policy,
            fontSize: FontSizes.regular,
            color: AppColor.grey,
            maxLines: 20,
          ),
        ),
      ],
    );
  }
}

// ─── Provider avatar ──────────────────────────────────────────────────────────

class _ProviderAvatar extends StatelessWidget {
  final String? photoUrl;
  final String displayName;
  final double size;

  const _ProviderAvatar({
    required this.photoUrl,
    required this.displayName,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final initials = displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();

    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return ClipOval(
        child: SizedBox(
          width: size,
          height: size,
          child: FunctionalComponent.cachedNetworkImage(
            photoUrl!,
            fit: BoxFit.cover,
            radius: size / 2,
          ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColor.authButton.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: AppText(
        initials.isEmpty ? '?' : initials,
        fontSize: 16,
        fontWeight: FontWeights.bold,
        color: AppColor.authButton,
      ),
    );
  }
}
