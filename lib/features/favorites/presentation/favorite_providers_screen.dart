import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pampa/core/values/app_text_value.dart';
import 'package:pampa/core/values/colors.dart';
import 'package:pampa/core/widgets/text_widget.dart';
import 'package:pampa/data/service/apiservice.dart';
import 'package:pampa/data/service/di.dart';
import 'package:pampa/features/booking/data/models/provider_model.dart';
import 'package:pampa/features/booking/presentation/provider_detail_screen.dart';
import 'package:pampa/features/favorites/presentation/provider/favorites_provider.dart';

// ─── Model ────────────────────────────────────────────────────────────────────

class _FavoriteProviderModel {
  final int id;
  final String name;
  final String? photoUrl;
  final double rating;
  final String? city;
  final String? state;
  final String? bio;

  const _FavoriteProviderModel({
    required this.id,
    required this.name,
    this.photoUrl,
    this.bio,
    required this.rating,
    this.city,
    this.state,
  });

  factory _FavoriteProviderModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? {};
    return _FavoriteProviderModel(
      id: json['id'] as int? ?? 0,
      name: user['name'] as String? ?? json['name'] as String? ?? '',
      photoUrl: json['photo_url'] as String? ?? json['photo'] as String?,
      rating: ((json['rating'] ?? 0) as num).toDouble(),
      city: json['city'] as String?,
      bio: json['bio'] as String?,
      state: json['state'] as String?,
    );
  }

  String get displayLocation {
    final parts = [city, state].where((p) => p != null && p.isNotEmpty).toList();
    return parts.join(', ');
  }
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class FavoriteProvidersScreen extends StatefulWidget {
  const FavoriteProvidersScreen({super.key});

  @override
  State<FavoriteProvidersScreen> createState() => _FavoriteProvidersScreenState();
}

class _FavoriteProvidersScreenState extends State<FavoriteProvidersScreen> {
  final _api = getIt<ApiService>();

  List<_FavoriteProviderModel> _providers = [];
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final response = await _api.getFavoriteProviders();
      final map = response as Map<String, dynamic>;
      if (map['status'] == true) {
        final list = map['data'] as List<dynamic>;
        setState(() {
          _providers = list
              .map((e) => _FavoriteProviderModel.fromJson(e as Map<String, dynamic>))
              .toList();
          _loading = false;
        });
      } else {
        setState(() {
          _error = map['message']?.toString() ?? 'Failed to load favorites.';
          _loading = false;
        });
      }
    } catch (_) {
      setState(() {
        _error = 'Failed to load favorites.';
        _loading = false;
      });
    }
  }

  Future<void> _openProvider(int providerId) async {
    try {
      final res = await _api.getProviderDetail(providerId);
      final map = res as Map<String, dynamic>;
      final data = map['data'] as Map<String, dynamic>? ?? map;
      final providerModel = ProviderModel.fromJson(data);
      if (!mounted) return;
      final firstServiceId =
          providerModel.services.isNotEmpty ? providerModel.services.first.id : 0;
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ProviderDetailScreen(
          provider: providerModel,
          initialServiceId: firstServiceId,
        ),
      ));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load provider details.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      backgroundColor: AppColor.authBg,
      appBar: AppBar(
        backgroundColor: AppColor.authBg,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: AppColor.darkGrey),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: AppText(

          'Favorite Providers',
          fontSize: FontSizes.medium,
          fontWeight: FontWeights.bold,
          color: AppColor.darkGrey,
        ),
        centerTitle: false,

      ),
      body: _loading
          ? _buildShimmer()
          : _error.isNotEmpty
              ? _buildError()
              : _providers.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      color: AppColor.authButton,
                      onRefresh: _fetch,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                        itemCount: _providers.length,
                        itemBuilder: (_, i) => _ProviderCard(
                          provider: _providers[i],
                          onBookNow: () => _openProvider(_providers[i].id),
                          onUnfavorited: () =>
                              setState(() => _providers.removeAt(i)),
                        ),
                      ),
                    ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite_border_rounded,
              size: 48,
              color: AppColor.authButton.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 14),
            AppText(
              'No favorite providers yet',
              fontSize: FontSizes.regular,
              fontWeight: FontWeights.semiBold,
              color: AppColor.darkGrey,
            ),
            const SizedBox(height: 6),
            AppText(
              'Providers you favorite will appear here.',
              fontSize: FontSizes.small,
              color: AppColor.grey,
              align: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      itemCount: 3,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 130,
        decoration: BoxDecoration(
          color: AppColor.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 40, color: AppColor.authButton),
            const SizedBox(height: 12),
            AppText(
              _error,
              fontSize: FontSizes.small,
              color: AppColor.grey,
              align: TextAlign.center,
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _fetch,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColor.authButton,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: AppText(
                  'Try Again',
                  fontSize: FontSizes.regular,
                  fontWeight: FontWeights.semiBold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Provider card ────────────────────────────────────────────────────────────

class _ProviderCard extends StatefulWidget {
  final _FavoriteProviderModel provider;
  final Future<void> Function() onBookNow;
  final VoidCallback onUnfavorited;

  const _ProviderCard({
    required this.provider,
    required this.onBookNow,
    required this.onUnfavorited,
  });

  @override
  State<_ProviderCard> createState() => _ProviderCardState();
}

class _ProviderCardState extends State<_ProviderCard> {
  bool _bookingLoading = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.provider;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top: photo + info ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Photo
                _Photo(photoUrl: p.photoUrl, name: p.name),
                const SizedBox(width: 14),
                // Info column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 2),
                      AppText(
                        p.name,
                        fontSize: FontSizes.medium,
                        fontWeight: FontWeights.bold,
                        color: AppColor.darkGrey,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 6),
                      // Rating pill
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFB800)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded,
                                    size: 13, color: Color(0xFFFFB800)),
                                const SizedBox(width: 3),
                                AppText(
                                  p.rating.toStringAsFixed(1),
                                  fontSize: 12,
                                  fontWeight: FontWeights.semiBold,
                                  color: const Color(0xFFB8860B),
                                ),
                              ],
                            ),
                          ),
                          if (p.displayLocation.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.location_on_rounded,
                                size: 13, color: AppColor.grey),
                            const SizedBox(width: 2),
                            Flexible(
                              child: AppText(
                                p.displayLocation,
                                fontSize: 12,
                                color: AppColor.grey,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),

                      AppText(
                        p.bio??'',
                        fontSize: 12,
                        color: AppColor.grey,
                        maxLines: 4,
                      ),
                    ],
                  ),
                ),

                // Heart button
                Consumer<FavoritesProvider>(
                  builder: (context, favProvider, _) => GestureDetector(
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          title: const Text('Unselect Provider'),
                          content: const Text(
                              'Do you really want to unselect provider?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text('Cancel',
                                  style: TextStyle(color: AppColor.grey)),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Unselect',
                                  style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        favProvider.toggleFavorite(p.id);
                        widget.onUnfavorited();
                      }
                    },
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        size: 17,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ── Divider ──
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Divider(height: 1, color: Color(0xFFF0F0F0)),
          ),
          // ── Book Now button ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: _bookingLoading
                    ? null
                    : () async {
                        setState(() => _bookingLoading = true);
                        await widget.onBookNow();
                        if (mounted) setState(() => _bookingLoading = false);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.authButton,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      AppColor.authButton.withValues(alpha: 0.6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _bookingLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : AppText(
                        'Book Now',
                        fontSize: FontSizes.regular,
                        fontWeight: FontWeights.semiBold,
                        color: Colors.white,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Photo ────────────────────────────────────────────────────────────────────

class _Photo extends StatelessWidget {
  final String? photoUrl;
  final String name;

  const _Photo({required this.photoUrl, required this.name});

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
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 80,
          height: 80,
          child: Image.network(
            photoUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _placeholder(initials),
          ),
        ),
      );
    }
    return _placeholder(initials);
  }

  Widget _placeholder(String initials) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppColor.authButton.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: AppText(
        initials.isEmpty ? 'P' : initials,
        fontSize: 22,
        fontWeight: FontWeights.bold,
        color: AppColor.authButton,
      ),
    );
  }
}
