import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  void _openSlider(BuildContext context, int initialIndex) {
    final urls = images
        .map((e) => e.imageUrl ?? '')
        .where((u) => u.isNotEmpty)
        .toList();
    if (urls.isEmpty) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) => _ImageSliderScreen(
          urls: urls,
          initialIndex: initialIndex.clamp(0, urls.length - 1),
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  Widget _thumb(String? url) {
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
    final total = urls.length;

    return Column(
      children: [
        // ── Hero (first image) ──────────────────────────────────────────
        GestureDetector(
          onTap: () => _openSlider(context, 0),
          child: SizedBox(
            width: double.infinity,
            height: 220,
            child: _thumb(urls[0]),
          ),
        ),

        // ── Thumbnails row (2nd and 3rd images) ─────────────────────────
        if (total > 1) ...[
          const SizedBox(height: 2),
          SizedBox(
            height: 130,
            child: Row(
              children: [
                // 2nd image
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openSlider(context, 1),
                    child: _thumb(urls[1]),
                  ),
                ),
                // 3rd image slot
                if (total >= 3) ...[
                  const SizedBox(width: 2),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _openSlider(context, 2),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _thumb(urls[2]),
                          // "+N" overlay when more than 3 images
                          if (total > 3)
                            Container(
                              color: Colors.black.withValues(alpha: 0.52),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '+${total - 3}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 26,
                                        fontWeight: FontWeight.w700,
                                        height: 1,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'more',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.85),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  // No 3rd image — fill with empty
                  const SizedBox(width: 2),
                  Expanded(child: Container(color: AppColor.authBg)),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Full-screen image slider ──────────────────────────────────────────────────

class _ImageSliderScreen extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;

  const _ImageSliderScreen({required this.urls, required this.initialIndex});

  @override
  State<_ImageSliderScreen> createState() => _ImageSliderScreenState();
}

class _ImageSliderScreenState extends State<_ImageSliderScreen> {
  late final PageController _pageController;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  }

  @override
  void dispose() {
    _pageController.dispose();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.urls.length;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── PageView with pinch-zoom ──────────────────────────────────
          PageView.builder(
            controller: _pageController,
            itemCount: total,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) => InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Center(
                child: FunctionalComponent.cachedNetworkImage(
                  widget.urls[i],
                  fit: BoxFit.contain,
                  radius: 0,
                ),
              ),
            ),
          ),

          // ── Top bar ───────────────────────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.65),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Close button
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),

                      // Counter pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Text(
                          '${_current + 1} / $total',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Bottom dot indicators ─────────────────────────────────────
          if (total > 1)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(total > 8 ? 0 : total, (i) {
                        final isActive = i == _current;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: isActive ? 22 : 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ),

          // ── Left / Right arrow hints on sides ─────────────────────────
          if (_current > 0)
            Positioned(
              left: 12,
              top: 0, bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () => _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.chevron_left_rounded,
                        color: Colors.white, size: 22),
                  ),
                ),
              ),
            ),

          if (_current < total - 1)
            Positioned(
              right: 12,
              top: 0, bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () => _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.chevron_right_rounded,
                        color: Colors.white, size: 22),
                  ),
                ),
              ),
            ),
        ],
      ),
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
                borderRadius: BorderRadius.circular(6),
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
